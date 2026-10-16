// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit obFCLProcessWindowsProbe;

{$mode objfpc}{$H+}

interface

uses obNXTestContext;

procedure RunWindowsProbe(AId: Integer; const ADirectory: string;
  AContext: TNXTestContext);
procedure RunWindowsServiceFixture;
procedure SaveWindowsArguments(const AFileName: string);

implementation

uses
  Classes, SysUtils, Windows, Process, FPSimpleService;

type
  TDelayedServiceThread = class(TFPServiceThread)
  protected
    procedure RunService; override;
  end;

function QueryProcessHandleCount(AProcess: THandle; out ACount: DWORD): BOOL;
  stdcall; external 'kernel32.dll' name 'GetProcessHandleCount';

procedure WriteMarker(const AName: string);
var
  lFile: TFileStream;
begin
  lFile:=TFileStream.Create(IncludeTrailingPathDelimiter(ParamStr(3))+AName,fmCreate);
  lFile.Free;
end;

procedure TDelayedServiceThread.RunService;
begin
  // The service worker isolates its blocking work from the SCM control path.
  WriteMarker('worker-started');
  while not Terminated do
    Sleep(10);
  Sleep(400);
  WriteMarker('worker-finished');
end;

procedure RunWindowsServiceFixture;
begin
  FPSimpleService.Application.Name:=ParamStr(2);
  FPSimpleService.Application.Title:=ParamStr(2);
  FPSimpleService.Application.ServiceClass:=TDelayedServiceThread;
  FPSimpleService.Application.Initialize;
  FPSimpleService.Application.Run;
end;

procedure WaitForService(AService: SC_HANDLE; AState: DWORD);
var
  lStatus: TServiceStatus;
  lStart: QWord;
begin
  lStart:=GetTickCount64;
  repeat
    if not QueryServiceStatus(AService,lStatus) then
      RaiseLastOSError;
    if lStatus.dwCurrentState=AState then
      Exit;
    if GetTickCount64-lStart>=3000 then
      raise Exception.CreateFmt('Service did not reach state %d; current state %d.',
        [AState,lStatus.dwCurrentState]);
    Sleep(10);
  until False;
end;

procedure ProbeService(const ADirectory: string; AContext: TNXTestContext);
var
  lManager, lService: SC_HANDLE;
  lStatus: TServiceStatus;
  lName, lCommand: UnicodeString;
  lStart: QWord;
begin
  lManager:=OpenSCManagerW(nil,nil,SC_MANAGER_CREATE_SERVICE);
  if lManager=0 then
  begin
    if GetLastError=ERROR_ACCESS_DENIED then
      AContext.Skip('Windows service test requires permission to create a temporary service.');
    RaiseLastOSError;
  end;
  try
    lName:='NexusFCLProcess'+IntToStr(GetCurrentProcessId);
    lCommand:='"'+ParamStr(0)+'" --service-fixture '+lName+' "'+ADirectory+'" -r';
    lService:=CreateServiceW(lManager,PWideChar(lName),PWideChar(lName),
      SERVICE_ALL_ACCESS,SERVICE_WIN32_OWN_PROCESS,SERVICE_DEMAND_START,
      SERVICE_ERROR_NORMAL,PWideChar(lCommand),nil,nil,nil,nil,nil);
    if lService=0 then
    begin
      if GetLastError=ERROR_ACCESS_DENIED then
        AContext.Skip('Windows service test requires permission to create a temporary service.');
      RaiseLastOSError;
    end;
    try
      if not StartServiceW(lService,0,nil) then
        RaiseLastOSError;
      WaitForService(lService,SERVICE_RUNNING);
      lStart:=GetTickCount64;
      while not FileExists(IncludeTrailingPathDelimiter(ADirectory)+'worker-started') do
      begin
        if GetTickCount64-lStart>=2000 then
          AContext.Fail('Service worker did not start.');
        Sleep(10);
      end;
      if not ControlService(lService,SERVICE_CONTROL_STOP,lStatus) then
        RaiseLastOSError;
      WaitForService(lService,SERVICE_STOPPED);
      AContext.AssertTrue(
        FileExists(IncludeTrailingPathDelimiter(ADirectory)+'worker-finished'),
        'SCM reported SERVICE_STOPPED before worker cleanup completed.');
    finally
      // Cleanup runs for assertions as well as successful service executions.
      try
        if QueryServiceStatus(lService,lStatus) and
          (lStatus.dwCurrentState<>SERVICE_STOPPED) then
        begin
          ControlService(lService,SERVICE_CONTROL_STOP,lStatus);
          WaitForService(lService,SERVICE_STOPPED);
        end;
      finally
        DeleteService(lService);
        CloseServiceHandle(lService);
      end;
    end;
  finally
    CloseServiceHandle(lManager);
  end;
end;

procedure SaveWindowsArguments(const AFileName: string);
var
  lArguments: TStringList;
  lIndex: Integer;
begin
  lArguments:=TStringList.Create;
  try
    for lIndex:=4 to ParamCount do
      lArguments.Add(ParamStr(lIndex));
    lArguments.SaveToFile(AFileName);
  finally
    lArguments.Free;
  end;
end;

procedure ProbeArguments(const ADirectory: string; AContext: TNXTestContext);
const
  cArguments: array[0..6] of string = ('', 'tab'+#9+'value', 'a"b',
    'space value', 'C:\space path\', 'slash\"quote', 'plain');
var
  lProcess: TProcess;
  lArguments: TStringList;
  lFileName: string;
  lIndex: Integer;
begin
  lFileName:=IncludeTrailingPathDelimiter(ADirectory)+'arguments.txt';
  lProcess:=TProcess.Create(nil);
  lArguments:=TStringList.Create;
  try
    lProcess.Executable:=ParamStr(0);
    lProcess.Parameters.Add('--child');
    lProcess.Parameters.Add('arguments');
    lProcess.Parameters.Add(lFileName);
    for lIndex:=Low(cArguments) to High(cArguments) do
      lProcess.Parameters.Add(cArguments[lIndex]);
    lProcess.Execute;
    AContext.AssertTrue(lProcess.WaitOnExit(2000),'Argument fixture did not exit.');
    AContext.AssertEquals(0,lProcess.ExitCode);
    lArguments.LoadFromFile(lFileName);
    AContext.AssertEquals(Length(cArguments),lArguments.Count,'Argument count changed.');
    for lIndex:=Low(cArguments) to High(cArguments) do
      AContext.AssertEquals(cArguments[lIndex],lArguments[lIndex],
        'Argument '+IntToStr(lIndex)+' changed.');
  finally
    if lProcess.Running then
    begin
      lProcess.Terminate(1);
      lProcess.WaitOnExit;
    end;
    lArguments.Free;
    lProcess.Free;
  end;
end;

procedure ProbeHandleReuse(AContext: TNXTestContext);
var
  lProcess: TProcess;
  lBefore, lAfter: DWORD;
  lIndex: Integer;
begin
  lProcess:=TProcess.Create(nil);
  try
    lProcess.Executable:=ParamStr(0);
    lProcess.Parameters.Add('--child');
    lProcess.Parameters.Add('sleep');
    lProcess.Parameters.Add('0');
    // Warm up one execution so the retained current pair is in both counts.
    lProcess.Execute;
    AContext.AssertTrue(lProcess.WaitOnExit(2000));
    if not QueryProcessHandleCount(GetCurrentProcess,lBefore) then
      RaiseLastOSError;
    for lIndex:=1 to 32 do
    begin
      lProcess.Execute;
      AContext.AssertTrue(lProcess.WaitOnExit(2000));
      AContext.AssertEquals(0,lProcess.ExitCode);
    end;
    if not QueryProcessHandleCount(GetCurrentProcess,lAfter) then
      RaiseLastOSError;
    AContext.AssertTrue(lAfter<=lBefore,
      Format('Reusing TProcess grew the handle count from %d to %d.',[lBefore,lAfter]));
  finally
    if lProcess.Running then
    begin
      lProcess.Terminate(1);
      lProcess.WaitOnExit;
    end;
    lProcess.Free;
  end;
end;

procedure RunWindowsProbe(AId: Integer; const ADirectory: string;
  AContext: TNXTestContext);
begin
  case AId of
    7: ProbeService(ADirectory,AContext);
    8: ProbeArguments(ADirectory,AContext);
    9: ProbeHandleReuse(AContext);
  else
    AContext.Fail('Unknown Windows probe.');
  end;
end;

end.

// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit tsFCLProcessTests;

{$mode objfpc}{$H+}

interface

uses obNXTestRegistry;

procedure RegisterFCLProcessTests(ARegistry: TNXTestRegistry);

implementation

uses
  Classes, SysUtils, Process, {$IFDEF UNIX}BaseUnix,{$ENDIF}
  obNXTestContext, obNXTestSuite;

procedure RemoveProbeDirectory(const ADirectory: string);
var
  lSearch: TSearchRec;
  lPath: string;
begin
  if FindFirst(IncludeTrailingPathDelimiter(ADirectory) + '*', faAnyFile,
    lSearch) = 0 then
  try
    repeat
      if (lSearch.Name = '.') or (lSearch.Name = '..') then
        Continue;
      lPath := IncludeTrailingPathDelimiter(ADirectory) + lSearch.Name;
      if (lSearch.Attr and faDirectory) <> 0 then
        RemoveProbeDirectory(lPath)
      else
        DeleteFile(lPath);
    until FindNext(lSearch) <> 0;
  finally
    FindClose(lSearch);
  end;
  RemoveDir(ADirectory);
end;

procedure RunProbe(AContext: TNXTestContext; AId: Integer);
var
  lDirectory, lFixture, lResultPath: string;
  lProcess: TProcess;
  lResult: TStringList;
  lFinished: Boolean;
  lTimeout: Integer;
begin
  lFixture := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'FCLProcessFixture' + {$IFDEF MSWINDOWS}'.exe'{$ELSE}''{$ENDIF};
  AContext.AssertTrue(FileExists(lFixture), 'Missing fixture: ' + lFixture);
  lDirectory := GetTempFileName(GetTempDir(False), 'fclp');
  DeleteFile(lDirectory);
  ForceDirectories(lDirectory);
  lResultPath := IncludeTrailingPathDelimiter(lDirectory) + 'result.txt';
  lProcess := TProcess.Create(nil);
  lResult := TStringList.Create;
  try
    lProcess.Executable := lFixture;
    lProcess.Parameters.Add('--probe');
    lProcess.Parameters.Add(IntToStr(AId));
    lProcess.Parameters.Add(lResultPath);
    lProcess.Parameters.Add(lDirectory);
    lTimeout:=10000;
    if AId in [7,9] then
      lTimeout:=30000;
    lProcess.Execute;
    lFinished := lProcess.WaitOnExit(lTimeout);
    {$IFDEF UNIX}
    // The probe creates its own session; descendants stay in its process group.
    fpKill(-lProcess.ProcessID, SIGKILL);
    if not lFinished then
    begin
      fpKill(lProcess.ProcessID, SIGKILL);
      lProcess.WaitOnExit;
    end;
    {$ELSE}
    if not lFinished then
    begin
      lProcess.Terminate(1);
      lProcess.WaitOnExit;
    end;
    {$ENDIF}
    AContext.AssertTrue(lFinished,
      Format('Probe exceeded its %d-second deadline.',[lTimeout div 1000]));
    AContext.AssertTrue(FileExists(lResultPath),
      'Probe exited without a result; process status ' + IntToStr(lProcess.ExitStatus));
    lResult.LoadFromFile(lResultPath);
    AContext.AssertTrue(lResult.Count > 0, 'Probe produced an empty result.');
    if lResult[0] = 'skipped' then
      AContext.Skip(Trim(Copy(lResult.Text, Length(lResult[0]) + 1, MaxInt)));
    AContext.AssertEquals('passed', lResult[0], Trim(lResult.Text));
  finally
    lResult.Free;
    lProcess.Free;
    {$IFDEF UNIX}
    DeleteFile(GetTempDir(True) + 'nexus-fclp-' + ExtractFileName(lDirectory) + '-frames');
    DeleteFile(GetTempDir(True) + 'nexus-fclp-' + ExtractFileName(lDirectory) + '-idle');
    DeleteFile(GetTempDir(True) + 'nexus-fclp-' + ExtractFileName(lDirectory) + '-silent');
    {$ENDIF}
    RemoveProbeDirectory(lDirectory);
  end;
end;

procedure Test01(AContext: TNXTestContext); begin RunProbe(AContext, 1); end;
procedure Test02(AContext: TNXTestContext); begin RunProbe(AContext, 2); end;
procedure Test03(AContext: TNXTestContext); begin RunProbe(AContext, 3); end;
procedure Test04(AContext: TNXTestContext); begin RunProbe(AContext, 4); end;
procedure Test05(AContext: TNXTestContext); begin RunProbe(AContext, 5); end;
procedure Test06(AContext: TNXTestContext); begin RunProbe(AContext, 6); end;
procedure Test07(AContext: TNXTestContext); begin RunProbe(AContext, 7); end;
procedure Test08(AContext: TNXTestContext); begin RunProbe(AContext, 8); end;
procedure Test09(AContext: TNXTestContext); begin RunProbe(AContext, 9); end;
procedure Test10(AContext: TNXTestContext); begin RunProbe(AContext, 10); end;
procedure Test11(AContext: TNXTestContext); begin RunProbe(AContext, 11); end;
procedure Test12(AContext: TNXTestContext); begin RunProbe(AContext, 12); end;
procedure Test13(AContext: TNXTestContext); begin RunProbe(AContext, 13); end;
procedure Test14(AContext: TNXTestContext); begin RunProbe(AContext, 14); end;

procedure RegisterFCLProcessTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCLProcess.Review');
  lSuite.AddTest('01InactiveProcessSignals', @Test01);
  lSuite.AddTest('02IntegerWireWidths', @Test02);
  lSuite.AddTest('03PipelineOwnership', @Test03);
  lSuite.AddTest('04CloseInputDeliversEOF', @Test04);
  lSuite.AddTest('05CopySelectedPipe', @Test05);
  lSuite.AddTest('06ConcurrentFIFOFrames', @Test06);
  lSuite.AddTest('07WindowsServiceShutdown', @Test07);
  lSuite.AddTest('08WindowsArgumentBoundaries', @Test08);
  lSuite.AddTest('09WindowsProcessHandleReuse', @Test09);
  lSuite.AddTest('10CallbackHandleAcquisition', @Test10);
  lSuite.AddTest('11InfiniteWaitShutdown', @Test11);
  lSuite.AddTest('12DiscardNewOwnership', @Test12);
  lSuite.AddTest('13SyncTimeoutOwnership', @Test13);
  lSuite.AddTest('14TimeoutAcrossSecondBoundary', @Test14);
end;

end.

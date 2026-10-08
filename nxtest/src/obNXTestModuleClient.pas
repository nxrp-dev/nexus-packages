(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTestModuleClient;

{$mode objfpc}{$H+}

interface

uses
  DynLibs,
  SysUtils,
  obNXTestRPCValues;

type
  ENXTestModuleClient = class(Exception);

  TNXTestInitFunc = function: Integer; cdecl;
  TNXTestReleaseProc = procedure; cdecl;
  TNXTestExecuteCommandFunc = function(ARequest: PAnsiChar;
    var AResultId: Integer; var AResultSize: Integer): Integer; cdecl;
  TNXTestReadResultFunc = function(AResultId: Integer; ABuffer: PAnsiChar;
    ABufferSize: Integer; var ABytesWritten: Integer): Integer; cdecl;

  TNXTestModuleClient = class
  private
    FExecuteCommand: TNXTestExecuteCommandFunc;
    FHandle: TLibHandle;
    FInitialized: Boolean;
    FLibraryName: string;
    FReadResult: TNXTestReadResultFunc;
    FRelease: TNXTestReleaseProc;

    function BuildRequest(AId: Integer; const AMethod: string;
      const AParamName: string = ''; const AParamValue: string = ''): string;
    function ExecuteRequest(const ARequest: string): string;
    function ReadResponse(AResultId, AResultSize: Integer): string;
    procedure RequireLoaded;
    function UnwrapResultJSON(const AResponse: string): string;
  public
    destructor Destroy; override;

    procedure LoadModule(const ALibraryName: string);
    procedure UnloadModule;

    function ListTests: TNXTestRegistryValue;
    function RunAll: TNXTestRunAllResultValue;
    function RunSuite(const ASuiteName: string): TNXTestRunSuiteResultValue;
    function RunTest(const ATestId: string): TNXTestResultValue;

    property LibraryName: string read FLibraryName;
  end;

implementation

uses
  fpjson,
  jsonparser,
  obNXJSONRPCMessages,
  tpNXTest;

destructor TNXTestModuleClient.Destroy;
begin
  UnloadModule;
  inherited Destroy;
end;

function TNXTestModuleClient.BuildRequest(AId: Integer; const AMethod: string;
  const AParamName: string; const AParamValue: string): string;
var
  lParams: TJSONObject;
  lRequest: TJSONObject;
begin
  lRequest := TJSONObject.Create;
  try
    lRequest.Add('jsonrpc', TNXJSONRPC.Version);
    lRequest.Add('id', AId);
    lRequest.Add('method', AMethod);

    if AParamName <> '' then
    begin
      lParams := TJSONObject.Create;
      lParams.Add(AParamName, AParamValue);
      lRequest.Add('params', lParams);
    end;

    Result := lRequest.AsJSON;
  finally
    lRequest.Free;
  end;
end;

function TNXTestModuleClient.ExecuteRequest(const ARequest: string): string;
var
  lResultId: Integer;
  lResultSize: Integer;
  lStatus: Integer;
begin
  RequireLoaded;

  lResultId := 0;
  lResultSize := 0;
  lStatus := FExecuteCommand(PAnsiChar(ARequest), lResultId, lResultSize);
  if lStatus <> cNXTestSuccess then
    raise ENXTestModuleClient.CreateFmt(
      'NXTest_ExecuteCommand failed. Status=%d', [lStatus]);

  Result := ReadResponse(lResultId, lResultSize);
end;

procedure TNXTestModuleClient.LoadModule(const ALibraryName: string);
var
  lInit: TNXTestInitFunc;
  lStatus: Integer;
begin
  UnloadModule;

  if Trim(ALibraryName) = '' then
    raise ENXTestModuleClient.Create('Test module path cannot be empty.');

  FHandle := LoadLibrary(ALibraryName);
  if FHandle = 0 then
    raise ENXTestModuleClient.Create('Unable to load test module: ' +
      ALibraryName);

  try
    Pointer(lInit) := GetProcedureAddress(FHandle, 'NXTest_Init');
    Pointer(FRelease) := GetProcedureAddress(FHandle, 'NXTest_Release');
    Pointer(FExecuteCommand) := GetProcedureAddress(FHandle,
      'NXTest_ExecuteCommand');
    Pointer(FReadResult) := GetProcedureAddress(FHandle, 'NXTest_ReadResult');

    if (not Assigned(lInit)) or (not Assigned(FRelease)) or
      (not Assigned(FExecuteCommand)) or (not Assigned(FReadResult)) then
      raise ENXTestModuleClient.Create(
        'The test module does not expose the required NXTest functions.');

    lStatus := lInit();
    if lStatus <> cNXTestSuccess then
      raise ENXTestModuleClient.CreateFmt('NXTest_Init failed. Status=%d',
        [lStatus]);

    FInitialized := True;
    FLibraryName := ALibraryName;
  except
    UnloadModule;
    raise;
  end;
end;

function TNXTestModuleClient.ListTests: TNXTestRegistryValue;
var
  lResultJSON: string;
  lJSON: TJSONData;
begin
  Result := TNXTestRegistryValue.Create;
  lJSON := nil;
  try
    try
      lResultJSON := UnwrapResultJSON(ExecuteRequest(
        BuildRequest(1, cNXTestMethodListTests)));
      lJSON := GetJSON(lResultJSON);
      Result.FromJSONData(lJSON);
    except
      Result.Free;
      raise;
    end;
  finally
    lJSON.Free;
  end;
end;

function TNXTestModuleClient.ReadResponse(AResultId, AResultSize: Integer): string;
var
  lBuffer: PAnsiChar;
  lBytesWritten: Integer;
  lStatus: Integer;
begin
  if AResultSize <= 0 then
    raise ENXTestModuleClient.CreateFmt(
      'NXTest_ExecuteCommand returned invalid result size. ResultSize=%d',
      [AResultSize]);

  GetMem(lBuffer, AResultSize);
  try
    lBytesWritten := 0;
    lStatus := FReadResult(AResultId, lBuffer, AResultSize, lBytesWritten);
    if lStatus <> cNXTestSuccess then
      raise ENXTestModuleClient.CreateFmt(
        'NXTest_ReadResult failed. Status=%d BytesWritten=%d',
        [lStatus, lBytesWritten]);

    if lBytesWritten <> AResultSize then
      raise ENXTestModuleClient.CreateFmt(
        'NXTest_ReadResult returned unexpected size. Expected=%d Actual=%d',
        [AResultSize, lBytesWritten]);

    Result := StrPas(lBuffer);
  finally
    FreeMem(lBuffer);
  end;
end;

procedure TNXTestModuleClient.RequireLoaded;
begin
  if (FHandle = 0) or (not FInitialized) or (not Assigned(FExecuteCommand)) or
    (not Assigned(FReadResult)) then
    raise ENXTestModuleClient.Create('No NXTest module is loaded.');
end;

function TNXTestModuleClient.RunAll: TNXTestRunAllResultValue;
var
  lResultJSON: string;
  lJSON: TJSONData;
begin
  Result := TNXTestRunAllResultValue.Create;
  lJSON := nil;
  try
    try
      lResultJSON := UnwrapResultJSON(ExecuteRequest(
        BuildRequest(2, cNXTestMethodRunAll)));
      lJSON := GetJSON(lResultJSON);
      Result.FromJSONData(lJSON);
    except
      Result.Free;
      raise;
    end;
  finally
    lJSON.Free;
  end;
end;

function TNXTestModuleClient.RunSuite(
  const ASuiteName: string): TNXTestRunSuiteResultValue;
var
  lResultJSON: string;
  lJSON: TJSONData;
begin
  Result := TNXTestRunSuiteResultValue.Create;
  lJSON := nil;
  try
    try
      lResultJSON := UnwrapResultJSON(ExecuteRequest(
        BuildRequest(3, cNXTestMethodRunSuite, 'suite', ASuiteName)));
      lJSON := GetJSON(lResultJSON);
      Result.FromJSONData(lJSON);
    except
      Result.Free;
      raise;
    end;
  finally
    lJSON.Free;
  end;
end;

function TNXTestModuleClient.RunTest(const ATestId: string): TNXTestResultValue;
var
  lResultJSON: string;
  lJSON: TJSONData;
begin
  Result := TNXTestResultValue.Create;
  lJSON := nil;
  try
    try
      lResultJSON := UnwrapResultJSON(ExecuteRequest(
        BuildRequest(4, cNXTestMethodRunTest, 'test', ATestId)));
      lJSON := GetJSON(lResultJSON);
      Result.FromJSONData(lJSON);
    except
      Result.Free;
      raise;
    end;
  finally
    lJSON.Free;
  end;
end;

procedure TNXTestModuleClient.UnloadModule;
begin
  if FInitialized and Assigned(FRelease) then
    FRelease();

  FInitialized := False;
  FExecuteCommand := nil;
  FReadResult := nil;
  FRelease := nil;
  FLibraryName := '';

  if FHandle <> 0 then
  begin
    UnloadLibrary(FHandle);
    FHandle := 0;
  end;
end;

function TNXTestModuleClient.UnwrapResultJSON(const AResponse: string): string;
var
  lError: TJSONObject;
  lJSON: TJSONData;
  lResponse: TJSONObject;
  lResult: TJSONData;
begin
  lJSON := nil;
  try
    lJSON := GetJSON(AResponse);
    if not (lJSON is TJSONObject) then
      raise ENXTestModuleClient.Create('NXTest response is not a JSON object.');

    lResponse := TJSONObject(lJSON);
    lResult := lResponse.Find('result');
    if Assigned(lResult) then
      Exit(lResult.AsJSON);

    lResult := lResponse.Find('error');
    if lResult is TJSONObject then
    begin
      lError := TJSONObject(lResult);
      lResult := lError.Find('message');
      if Assigned(lResult) then
        raise ENXTestModuleClient.Create(lResult.AsString);
    end;

    raise ENXTestModuleClient.Create('NXTest response did not contain result.');
  finally
    lJSON.Free;
  end;
end;

end.

(*
  Copyright (c) 2026 Kevin Collins.
  
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  
  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.
  
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTestModule;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, tpNXTest, obNXTestRegistry, obNXTestCommandProcessor,
  obNXTestResultStore, obNXTestRunner;

type
  TNXTestRegistryProc = procedure(ARegistry: TNXTestRegistry);

  TNXTestModule = class
  private
    class var FCurrent: TNXTestModule;
  private
    FRegistry: TNXTestRegistry;
    FProcessor: TNXTestCommandProcessor;
    FResults: TNXTestResultStore;
    function GetRunner: TNXTestRunner;
  public
    constructor Create(ARegisterTests: TNXTestRegistryProc);
    destructor Destroy; override;

    function ExecuteCommand(ARequest: PAnsiChar; var AResultId: Integer; var AResultSize: Integer): Integer;
    function ReadResult(AResultId: Integer; ABuffer: PAnsiChar; ABufferSize: Integer; var ABytesWritten: Integer): Integer;

    property Registry: TNXTestRegistry read FRegistry;
    property Runner: TNXTestRunner read GetRunner;

    class function Current: TNXTestModule; static;
  end;

implementation

constructor TNXTestModule.Create(ARegisterTests: TNXTestRegistryProc);
begin
  inherited Create;
  FCurrent := Self;
  FRegistry := TNXTestRegistry.Create;
  try
    if Assigned(ARegisterTests) then
      ARegisterTests(FRegistry);
    FProcessor := TNXTestCommandProcessor.Create(FRegistry);
    FResults := TNXTestResultStore.Create;
  except
    if FCurrent = Self then
      FCurrent := nil;

    FreeAndNil(FResults);
    FreeAndNil(FProcessor);
    FreeAndNil(FRegistry);
    raise;
  end;
end;

destructor TNXTestModule.Destroy;
begin
  if FCurrent = Self then
    FCurrent := nil;

  FreeAndNil(FResults);
  FreeAndNil(FProcessor);
  FreeAndNil(FRegistry);
  inherited Destroy;
end;

function TNXTestModule.GetRunner: TNXTestRunner;
begin
  if Assigned(FProcessor) then
    Result := FProcessor.Runner
  else
    Result := nil;
end;

class function TNXTestModule.Current: TNXTestModule;
begin
  Result := FCurrent;
end;

function TNXTestModule.ExecuteCommand(ARequest: PAnsiChar; var AResultId: Integer; var AResultSize: Integer): Integer;
var
  lResponse: string;
begin
  AResultId := 0;
  AResultSize := 0;

  if ARequest = nil then
    Exit(cNXTestErrorInvalidRequest);

  if (not Assigned(FProcessor)) or (not Assigned(FResults)) then
    Exit(cNXTestErrorNotInitialized);

  lResponse := FProcessor.ExecuteCommand(StrPas(ARequest));
  Result := FResults.Store(lResponse, AResultId, AResultSize);
end;

function TNXTestModule.ReadResult(AResultId: Integer; ABuffer: PAnsiChar; ABufferSize: Integer; var ABytesWritten: Integer): Integer;
begin
  ABytesWritten := 0;

  if not Assigned(FResults) then
    Exit(cNXTestErrorNotInitialized);

  Result := FResults.Read(AResultId, ABuffer, ABufferSize, ABytesWritten);
end;

end.

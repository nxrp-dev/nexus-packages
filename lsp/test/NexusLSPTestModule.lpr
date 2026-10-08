(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

library NexusLSPTestModule;

{$mode objfpc}{$H+}

uses
  SysUtils,
  tpNXTest,
  obNXTestModule,
  obNXTestRegistry,
  obNXTestRPCRequests,
  tsNXLSPProtocolObjectTests,
  tsNXLSPSharedTests;

var
  gModule: TNXTestModule = nil;

procedure RegisterTests(ARegistry: TNXTestRegistry);
begin
  RegisterNXLSPProtocolObjectTests(ARegistry);
  RegisterNXLSPSharedTests(ARegistry);
end;

function NXTest_Init: Integer; cdecl;
begin
  if Assigned(gModule) then
    Exit(cNXTestSuccess);

  try
    gModule := TNXTestModule.Create(@RegisterTests);
    Result := cNXTestSuccess;
  except
    on E: Exception do
    begin
      FreeAndNil(gModule);
      Result := cNXTestErrorInternal;
    end;
  end;
end;

procedure NXTest_Release; cdecl;
begin
  FreeAndNil(gModule);
end;

function NXTest_ExecuteCommand(ARequest: PAnsiChar; var AResultId: Integer;
  var AResultSize: Integer): Integer; cdecl;
begin
  AResultId := 0;
  AResultSize := 0;
  if not Assigned(gModule) then
    Exit(cNXTestErrorNotInitialized);
  Result := gModule.ExecuteCommand(ARequest, AResultId, AResultSize);
end;

function NXTest_ReadResult(AResultId: Integer; ABuffer: PAnsiChar;
  ABufferSize: Integer; var ABytesWritten: Integer): Integer; cdecl;
begin
  ABytesWritten := 0;
  if not Assigned(gModule) then
    Exit(cNXTestErrorNotInitialized);
  Result := gModule.ReadResult(AResultId, ABuffer, ABufferSize, ABytesWritten);
end;

exports
  NXTest_Init,
  NXTest_Release,
  NXTest_ExecuteCommand,
  NXTest_ReadResult;

begin
end.

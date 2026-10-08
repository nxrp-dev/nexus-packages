(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

library NexusUITestModule;

{$mode objfpc}{$H+}

uses
  SysUtils,
  tpNXTest,
  obNXTestModule,
  obNXTestRPCRequests,
  tsNXUIAllTests;

var
  gModule: TNXTestModule = nil;

function NXTest_Init: Integer; cdecl;
begin
  if Assigned(gModule) then
    Exit(cNXTestSuccess);

  try
    gModule := TNXTestModule.Create(@RegisterNXUITests);
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
  try
    FreeAndNil(gModule);
  except
    on E: Exception do
    begin
    end;
  end;
end;

function NXTest_ExecuteCommand(ARequest: PAnsiChar; var AResultId: Integer;
  var AResultSize: Integer): Integer; cdecl;
begin
  AResultId := 0;
  AResultSize := 0;

  try
    if not Assigned(gModule) then
      Exit(cNXTestErrorNotInitialized);

    Result := gModule.ExecuteCommand(ARequest, AResultId, AResultSize);
  except
    on E: Exception do
      Result := cNXTestErrorInternal;
  end;
end;

function NXTest_ReadResult(AResultId: Integer; ABuffer: PAnsiChar;
  ABufferSize: Integer; var ABytesWritten: Integer): Integer; cdecl;
begin
  ABytesWritten := 0;

  try
    if not Assigned(gModule) then
      Exit(cNXTestErrorNotInitialized);

    Result := gModule.ReadResult(AResultId, ABuffer, ABufferSize,
      ABytesWritten);
  except
    on E: Exception do
      Result := cNXTestErrorInternal;
  end;
end;

exports
  NXTest_Init,
  NXTest_Release,
  NXTest_ExecuteCommand,
  NXTest_ReadResult;

begin
end.

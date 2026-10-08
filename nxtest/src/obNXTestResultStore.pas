(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTestResultStore;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, tpNXTest;

type
  TNXStoredCommandResult = class
  private
    FResultId: Integer;
    FResponse: string;
  public
    constructor Create(AResultId: Integer; const AResponse: string);

    property ResultId: Integer read FResultId;
    property Response: string read FResponse;
  end;

  TNXTestResultStore = class
  private
    FResults: TList;
    FNextResultId: Integer;
    function FindResultIndex(AResultId: Integer): Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    function Store(const AResponse: string; var AResultId: Integer; var AResultSize: Integer): Integer;
    function Read(AResultId: Integer; ABuffer: PAnsiChar; ABufferSize: Integer; var ABytesWritten: Integer): Integer;
  end;

implementation

constructor TNXStoredCommandResult.Create(AResultId: Integer; const AResponse: string);
begin
  inherited Create;
  FResultId := AResultId;
  FResponse := AResponse;
end;

constructor TNXTestResultStore.Create;
begin
  inherited Create;
  FResults := TList.Create;
  FNextResultId := 1;
end;

destructor TNXTestResultStore.Destroy;
begin
  Clear;
  FResults.Free;
  inherited Destroy;
end;

procedure TNXTestResultStore.Clear;
var
  lIndex: Integer;
begin
  for lIndex := 0 to FResults.Count - 1 do
    TObject(FResults[lIndex]).Free;
  FResults.Clear;
  FNextResultId := 1;
end;

function TNXTestResultStore.FindResultIndex(AResultId: Integer): Integer;
var
  lIndex: Integer;
begin
  Result := -1;

  for lIndex := 0 to FResults.Count - 1 do
  begin
    if TNXStoredCommandResult(FResults[lIndex]).ResultId = AResultId then
      Exit(lIndex);
  end;
end;

function TNXTestResultStore.Store(const AResponse: string; var AResultId: Integer; var AResultSize: Integer): Integer;
var
  lStoredResult: TNXStoredCommandResult;
begin
  AResultId := FNextResultId;
  Inc(FNextResultId);

  lStoredResult := TNXStoredCommandResult.Create(AResultId, AResponse);
  FResults.Add(lStoredResult);

  AResultSize := Length(AResponse) + 1;
  Result := cNXTestSuccess;
end;

function TNXTestResultStore.Read(AResultId: Integer; ABuffer: PAnsiChar; ABufferSize: Integer; var ABytesWritten: Integer): Integer;
var
  lIndex: Integer;
  lStoredResult: TNXStoredCommandResult;
  lRequiredSize: Integer;
begin
  ABytesWritten := 0;

  if ABuffer = nil then
    Exit(cNXTestErrorInvalidArgument);

  lIndex := FindResultIndex(AResultId);
  if lIndex < 0 then
    Exit(cNXTestErrorUnknownResult);

  lStoredResult := TNXStoredCommandResult(FResults[lIndex]);
  lRequiredSize := Length(lStoredResult.Response) + 1;

  if ABufferSize < lRequiredSize then
  begin
    ABytesWritten := lRequiredSize;
    Exit(cNXTestErrorBufferTooSmall);
  end;

  StrPCopy(ABuffer, lStoredResult.Response);
  ABytesWritten := lRequiredSize;

  FResults.Delete(lIndex);
  lStoredResult.Free;

  Result := cNXTestSuccess;
end;

end.

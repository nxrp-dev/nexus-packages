(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTorrentService;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, obNXTorrentMetaInfo, obNXTorrentSession;

type
  TNXTorrentService = class
  private
    FSessions: TList;
    function GetCount: Integer;
    function GetSession(AIndex: Integer): TNXTorrentSession;
  public
    constructor Create;
    destructor Destroy; override;

    function AddMetaInfo(AMetaInfo: TNXTorrentMetaInfo;
      const ARootPath: string): TNXTorrentSession;
    function FindByInfoHashHex(const AInfoHashHex: string): TNXTorrentSession;
    procedure Remove(const AInfoHashHex: string);

    property Count: Integer read GetCount;
    property Sessions[AIndex: Integer]: TNXTorrentSession read GetSession;
  end;

implementation

constructor TNXTorrentService.Create;
begin
  inherited Create;
  FSessions := TList.Create;
end;

destructor TNXTorrentService.Destroy;
var
  lIndex: Integer;
begin
  for lIndex := 0 to FSessions.Count - 1 do
    TObject(FSessions[lIndex]).Free;
  FSessions.Free;
  inherited Destroy;
end;

function TNXTorrentService.GetCount: Integer;
begin
  Result := FSessions.Count;
end;

function TNXTorrentService.GetSession(AIndex: Integer): TNXTorrentSession;
begin
  Result := TNXTorrentSession(FSessions[AIndex]);
end;

function TNXTorrentService.AddMetaInfo(AMetaInfo: TNXTorrentMetaInfo;
  const ARootPath: string): TNXTorrentSession;
begin
  Result := TNXTorrentSession.Create(AMetaInfo, ARootPath);
  FSessions.Add(Result);
end;

function TNXTorrentService.FindByInfoHashHex(
  const AInfoHashHex: string): TNXTorrentSession;
var
  lIndex: Integer;
begin
  Result := nil;
  for lIndex := 0 to Count - 1 do
    if SameText(Sessions[lIndex].MetaInfo.InfoHashHex, AInfoHashHex) then
      Exit(Sessions[lIndex]);
end;

procedure TNXTorrentService.Remove(const AInfoHashHex: string);
var
  lSession: TNXTorrentSession;
begin
  lSession := FindByInfoHashHex(AInfoHashHex);
  if Assigned(lSession) then
  begin
    FSessions.Remove(lSession);
    lSession.Free;
  end;
end;

end.

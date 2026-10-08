(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTorrentPieceMap;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, tpNXTorrent, obNXTorrentMetaInfo;

type
  TNXTorrentPieceInfo = record
    Index: Integer;
    Offset: Int64;
    Length: Integer;
    Hash: TNXTorrentHash;
  end;

  TNXTorrentPieceMap = class
  private
    FMetaInfo: TNXTorrentMetaInfo;
    FOwnsMetaInfo: Boolean;
    function GetPieceCount: Integer;
  public
    constructor Create(AMetaInfo: TNXTorrentMetaInfo; AOwnsMetaInfo: Boolean = False);
    destructor Destroy; override;

    function PieceInfo(AIndex: Integer): TNXTorrentPieceInfo;
    function TotalLength: Int64;
    function PieceIndexForOffset(AOffset: Int64): Integer;
    function PieceOffset(AIndex: Integer): Int64;
    function PieceLength(AIndex: Integer): Integer;

    property MetaInfo: TNXTorrentMetaInfo read FMetaInfo;
    property PieceCount: Integer read GetPieceCount;
  end;

implementation

constructor TNXTorrentPieceMap.Create(AMetaInfo: TNXTorrentMetaInfo;
  AOwnsMetaInfo: Boolean);
begin
  inherited Create;
  if not Assigned(AMetaInfo) then
    raise EArgumentNilException.Create('AMetaInfo');
  FMetaInfo := AMetaInfo;
  FOwnsMetaInfo := AOwnsMetaInfo;
end;

destructor TNXTorrentPieceMap.Destroy;
begin
  if FOwnsMetaInfo then
    FMetaInfo.Free;
  inherited Destroy;
end;

function TNXTorrentPieceMap.GetPieceCount: Integer;
begin
  Result := FMetaInfo.PieceCount;
end;

function TNXTorrentPieceMap.TotalLength: Int64;
begin
  Result := FMetaInfo.Files.TotalLength;
end;

function TNXTorrentPieceMap.PieceOffset(AIndex: Integer): Int64;
begin
  if (AIndex < 0) or (AIndex >= PieceCount) then
    raise ERangeError.Create('Torrent piece index is out of range.');
  Result := Int64(AIndex) * FMetaInfo.PieceLength;
end;

function TNXTorrentPieceMap.PieceLength(AIndex: Integer): Integer;
var
  lRemaining: Int64;
begin
  lRemaining := TotalLength - PieceOffset(AIndex);
  if lRemaining <= 0 then
    raise ERangeError.Create('Torrent piece index is out of range.');
  if lRemaining > FMetaInfo.PieceLength then
    Result := FMetaInfo.PieceLength
  else
    Result := lRemaining;
end;

function TNXTorrentPieceMap.PieceInfo(AIndex: Integer): TNXTorrentPieceInfo;
begin
  Result.Index := AIndex;
  Result.Offset := PieceOffset(AIndex);
  Result.Length := PieceLength(AIndex);
  Result.Hash := FMetaInfo.PieceHash(AIndex);
end;

function TNXTorrentPieceMap.PieceIndexForOffset(AOffset: Int64): Integer;
begin
  if (AOffset < 0) or (AOffset >= TotalLength) then
    raise ERangeError.Create('Torrent offset is out of range.');
  Result := AOffset div FMetaInfo.PieceLength;
end;

end.

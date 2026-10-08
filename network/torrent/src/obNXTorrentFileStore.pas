(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTorrentFileStore;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sha1, tpNXTorrent, obNXTorrentPieceMap;

type
  ENXTorrentFileStoreError = class(Exception);

  TNXTorrentFileStore = class
  private
    FPieceMap: TNXTorrentPieceMap;
    FRootPath: string;
    FStates: array of TNXTorrentPieceState;
    function AbsoluteFileName(const ARelativePath: string): string;
    procedure EnsurePieceIndex(AIndex: Integer);
    procedure EnsureRoot;
    function NormalizeTorrentRelativePath(const APath: string): string;
    procedure ReadRange(AOffset: Int64; ALength: Integer; AStream: TStream);
    procedure WriteRange(AOffset: Int64; AData: TStream);
  public
    constructor Create(APieceMap: TNXTorrentPieceMap; const ARootPath: string);
    destructor Destroy; override;

    procedure PrepareFiles;
    procedure WriteBlock(APieceIndex, ABlockOffset: Integer; const AData: string);
    function ReadBlock(APieceIndex, ABlockOffset, ALength: Integer): string;
    function ReadPiece(APieceIndex: Integer): string;
    function VerifyPiece(APieceIndex: Integer): Boolean;
    function VerifiedCount: Integer;

    property PieceMap: TNXTorrentPieceMap read FPieceMap;
    property RootPath: string read FRootPath;
  end;

implementation

constructor TNXTorrentFileStore.Create(APieceMap: TNXTorrentPieceMap;
  const ARootPath: string);
begin
  inherited Create;
  if not Assigned(APieceMap) then
    raise EArgumentNilException.Create('APieceMap');
  FPieceMap := APieceMap;
  FRootPath := IncludeTrailingPathDelimiter(ARootPath);
  SetLength(FStates, FPieceMap.PieceCount);
end;

destructor TNXTorrentFileStore.Destroy;
begin
  inherited Destroy;
end;

procedure TNXTorrentFileStore.EnsurePieceIndex(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FPieceMap.PieceCount) then
    raise ERangeError.Create('Torrent piece index is out of range.');
end;

function TNXTorrentFileStore.AbsoluteFileName(
  const ARelativePath: string): string;
var
  lRoot: string;
begin
  lRoot := IncludeTrailingPathDelimiter(ExpandFileName(FRootPath));
  Result := ExpandFileName(lRoot + NormalizeTorrentRelativePath(ARelativePath));
  if CompareText(Copy(Result, 1, Length(lRoot)), lRoot) <> 0 then
    raise ENXTorrentFileStoreError.Create('Torrent file path escapes store root.');
end;

function TNXTorrentFileStore.NormalizeTorrentRelativePath(
  const APath: string): string;
var
  lIndex: Integer;
  lPart: string;
  lParts: TStringList;

  function IsWindowsDriveQualified(const AValue: string): Boolean;
  begin
    Result := (Length(AValue) >= 2) and (AValue[2] = ':') and
      (AValue[1] in ['A'..'Z', 'a'..'z']);
  end;

  procedure AddPart;
  begin
    if lPart = '' then
      raise ENXTorrentFileStoreError.Create('Torrent file path contains an empty segment.');
    if (lPart = '.') or (lPart = '..') then
      raise ENXTorrentFileStoreError.Create('Torrent file path contains an unsafe segment.');
    if Pos(':', lPart) > 0 then
      raise ENXTorrentFileStoreError.Create('Torrent file path segment cannot contain a colon.');
    lParts.Add(lPart);
    lPart := '';
  end;

begin
  if APath = '' then
    raise ENXTorrentFileStoreError.Create('Torrent file path cannot be empty.');
  if (ExtractFileDrive(APath) <> '') or IsWindowsDriveQualified(APath) then
    raise ENXTorrentFileStoreError.Create('Torrent file path cannot be drive-qualified.');
  if APath[1] in ['\', '/'] then
    raise ENXTorrentFileStoreError.Create('Torrent file path cannot be absolute.');

  lParts := TStringList.Create;
  try
    lPart := '';
    for lIndex := 1 to Length(APath) do
    begin
      if APath[lIndex] in ['\', '/'] then
        AddPart
      else
        lPart := lPart + APath[lIndex];
    end;
    AddPart;

    Result := '';
    for lIndex := 0 to lParts.Count - 1 do
    begin
      if Result <> '' then
        Result := Result + DirectorySeparator;
      Result := Result + lParts[lIndex];
    end;
  finally
    lParts.Free;
  end;
end;

procedure TNXTorrentFileStore.EnsureRoot;
begin
  ForceDirectories(FRootPath);
end;

procedure TNXTorrentFileStore.PrepareFiles;
var
  lIndex: Integer;
  lFileName: string;
  lStream: TFileStream;
begin
  EnsureRoot;
  for lIndex := 0 to FPieceMap.MetaInfo.Files.Count - 1 do
  begin
    lFileName := AbsoluteFileName(FPieceMap.MetaInfo.Files[lIndex].Path);
    ForceDirectories(ExtractFileDir(lFileName));
    if not FileExists(lFileName) then
    begin
      lStream := TFileStream.Create(lFileName, fmCreate);
      try
        lStream.Size := FPieceMap.MetaInfo.Files[lIndex].Length;
      finally
        lStream.Free;
      end;
    end;
  end;
end;

procedure TNXTorrentFileStore.WriteRange(AOffset: Int64; AData: TStream);
var
  lFileIndex: Integer;
  lFileStart: Int64;
  lFileEnd: Int64;
  lWriteOffset: Int64;
  lChunk: Int64;
  lFileName: string;
  lStream: TFileStream;
begin
  lFileStart := 0;
  for lFileIndex := 0 to FPieceMap.MetaInfo.Files.Count - 1 do
  begin
    lFileEnd := lFileStart + FPieceMap.MetaInfo.Files[lFileIndex].Length;
    if (AOffset < lFileEnd) and (AData.Position < AData.Size) then
    begin
      lWriteOffset := AOffset - lFileStart;
      if lWriteOffset < 0 then
        lWriteOffset := 0;
      lChunk := lFileEnd - (lFileStart + lWriteOffset);
      if lChunk > AData.Size - AData.Position then
        lChunk := AData.Size - AData.Position;
      lFileName := AbsoluteFileName(FPieceMap.MetaInfo.Files[lFileIndex].Path);
      lStream := TFileStream.Create(lFileName, fmOpenReadWrite or fmShareDenyWrite);
      try
        lStream.Position := lWriteOffset;
        lStream.CopyFrom(AData, lChunk);
      finally
        lStream.Free;
      end;
      Inc(AOffset, lChunk);
    end;
    lFileStart := lFileEnd;
  end;
end;

procedure TNXTorrentFileStore.ReadRange(AOffset: Int64; ALength: Integer;
  AStream: TStream);
var
  lFileIndex: Integer;
  lFileStart: Int64;
  lFileEnd: Int64;
  lReadOffset: Int64;
  lChunk: Int64;
  lFileName: string;
  lStream: TFileStream;
begin
  lFileStart := 0;
  for lFileIndex := 0 to FPieceMap.MetaInfo.Files.Count - 1 do
  begin
    lFileEnd := lFileStart + FPieceMap.MetaInfo.Files[lFileIndex].Length;
    if (AOffset < lFileEnd) and (ALength > 0) then
    begin
      lReadOffset := AOffset - lFileStart;
      if lReadOffset < 0 then
        lReadOffset := 0;
      lChunk := lFileEnd - (lFileStart + lReadOffset);
      if lChunk > ALength then
        lChunk := ALength;
      lFileName := AbsoluteFileName(FPieceMap.MetaInfo.Files[lFileIndex].Path);
      lStream := TFileStream.Create(lFileName, fmOpenRead or fmShareDenyNone);
      try
        lStream.Position := lReadOffset;
        AStream.CopyFrom(lStream, lChunk);
      finally
        lStream.Free;
      end;
      Inc(AOffset, lChunk);
      Dec(ALength, lChunk);
    end;
    lFileStart := lFileEnd;
  end;
end;

procedure TNXTorrentFileStore.WriteBlock(APieceIndex, ABlockOffset: Integer;
  const AData: string);
var
  lPiece: TNXTorrentPieceInfo;
  lStream: TStringStream;
begin
  EnsurePieceIndex(APieceIndex);
  lPiece := FPieceMap.PieceInfo(APieceIndex);
  if Length(AData) <= 0 then
    raise ERangeError.Create('Torrent block data cannot be empty.');
  if (ABlockOffset < 0) or
    (Int64(ABlockOffset) + Int64(Length(AData)) > lPiece.Length) then
    raise ERangeError.Create('Torrent block range is out of piece bounds.');
  PrepareFiles;
  lStream := TStringStream.Create(AData);
  try
    WriteRange(lPiece.Offset + ABlockOffset, lStream);
  finally
    lStream.Free;
  end;
  FStates[APieceIndex] := tpsPartial;
end;

function TNXTorrentFileStore.ReadBlock(APieceIndex, ABlockOffset,
  ALength: Integer): string;
var
  lPiece: TNXTorrentPieceInfo;
  lStream: TStringStream;
begin
  EnsurePieceIndex(APieceIndex);
  lPiece := FPieceMap.PieceInfo(APieceIndex);
  if ALength <= 0 then
    raise ERangeError.Create('Torrent block read length must be greater than zero.');
  if (ABlockOffset < 0) or (Int64(ABlockOffset) + Int64(ALength) > lPiece.Length) then
    raise ERangeError.Create('Torrent block range is out of piece bounds.');
  lStream := TStringStream.Create('');
  try
    ReadRange(lPiece.Offset + ABlockOffset, ALength, lStream);
    Result := lStream.DataString;
  finally
    lStream.Free;
  end;
end;

function TNXTorrentFileStore.ReadPiece(APieceIndex: Integer): string;
begin
  EnsurePieceIndex(APieceIndex);
  Result := ReadBlock(APieceIndex, 0, FPieceMap.PieceLength(APieceIndex));
end;

function TNXTorrentFileStore.VerifyPiece(APieceIndex: Integer): Boolean;
var
  lData: string;
  lDigest: TSHA1Digest;
  lHash: TNXTorrentHash;
begin
  EnsurePieceIndex(APieceIndex);
  lData := ReadPiece(APieceIndex);
  lDigest := SHA1String(lData);
  Move(lDigest[0], lHash[0], SizeOf(lHash));
  Result := NXTorrentHashEquals(lHash, FPieceMap.MetaInfo.PieceHash(APieceIndex));
  if Result then
    FStates[APieceIndex] := tpsVerified
  else
    FStates[APieceIndex] := tpsPartial;
end;

function TNXTorrentFileStore.VerifiedCount: Integer;
var
  lIndex: Integer;
begin
  Result := 0;
  for lIndex := 0 to Length(FStates) - 1 do
    if FStates[lIndex] = tpsVerified then
      Inc(Result);
end;

end.

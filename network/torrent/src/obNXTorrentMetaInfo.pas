(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTorrentMetaInfo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sha1, tpNXTorrent, obNXBEncode;

type
  ENXTorrentMetaInfoError = class(Exception);

  TNXTorrentFileList = class
  private
    FItems: array of TNXTorrentFileInfo;
    function GetCount: Integer;
    function GetItem(AIndex: Integer): TNXTorrentFileInfo;
  public
    procedure Clear;
    procedure Add(const APath: string; ALength: Int64);
    function TotalLength: Int64;

    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TNXTorrentFileInfo read GetItem; default;
  end;

  TNXTorrentMetaInfo = class
  private
    FAnnounce: string;
    FComment: string;
    FCreatedBy: string;
    FCreationDate: Int64;
    FFiles: TNXTorrentFileList;
    FInfoDictionary: TNXBEncodeDictionary;
    FName: string;
    FPieceLength: Integer;
    FPieces: string;
    function GetInfoHash: TNXTorrentHash;
    function GetInfoHashHex: string;
    procedure LoadFilesFromInfo(AInfo: TNXBEncodeDictionary);
    procedure LoadPiecesFromInfo(AInfo: TNXBEncodeDictionary);
  public
    constructor Create;
    destructor Destroy; override;

    class function LoadFromBEncodedString(const AText: string): TNXTorrentMetaInfo;
    class function CreateSingleFile(const AAnnounce, AName: string; ALength: Int64;
      APieceLength: Integer; const APieceHashes: string): TNXTorrentMetaInfo;

    function AsBEncodedString: string;
    function BuildInfoDictionary: TNXBEncodeDictionary;
    function PieceCount: Integer;
    function PieceHash(AIndex: Integer): TNXTorrentHash;
    function IsMultiFile: Boolean;

    property Announce: string read FAnnounce write FAnnounce;
    property Comment: string read FComment write FComment;
    property CreatedBy: string read FCreatedBy write FCreatedBy;
    property CreationDate: Int64 read FCreationDate write FCreationDate;
    property Files: TNXTorrentFileList read FFiles;
    property InfoHash: TNXTorrentHash read GetInfoHash;
    property InfoHashHex: string read GetInfoHashHex;
    property Name: string read FName write FName;
    property PieceLength: Integer read FPieceLength write FPieceLength;
    property Pieces: string read FPieces write FPieces;
  end;

implementation

function TNXTorrentFileList.GetCount: Integer;
begin
  Result := Length(FItems);
end;

function TNXTorrentFileList.GetItem(AIndex: Integer): TNXTorrentFileInfo;
begin
  Result := FItems[AIndex];
end;

procedure TNXTorrentFileList.Clear;
begin
  SetLength(FItems, 0);
end;

procedure TNXTorrentFileList.Add(const APath: string; ALength: Int64);
var
  lIndex: Integer;
begin
  if ALength < 0 then
    raise ENXTorrentMetaInfoError.Create('Torrent file length cannot be negative.');
  lIndex := Length(FItems);
  SetLength(FItems, lIndex + 1);
  FItems[lIndex].Path := APath;
  FItems[lIndex].Length := ALength;
end;

function TNXTorrentFileList.TotalLength: Int64;
var
  lIndex: Integer;
begin
  Result := 0;
  for lIndex := 0 to Count - 1 do
    Inc(Result, FItems[lIndex].Length);
end;

constructor TNXTorrentMetaInfo.Create;
begin
  inherited Create;
  FFiles := TNXTorrentFileList.Create;
  FCreationDate := 0;
end;

destructor TNXTorrentMetaInfo.Destroy;
begin
  FInfoDictionary.Free;
  FFiles.Free;
  inherited Destroy;
end;

class function TNXTorrentMetaInfo.CreateSingleFile(const AAnnounce,
  AName: string; ALength: Int64; APieceLength: Integer;
  const APieceHashes: string): TNXTorrentMetaInfo;
begin
  Result := TNXTorrentMetaInfo.Create;
  try
    Result.Announce := AAnnounce;
    Result.Name := AName;
    Result.PieceLength := APieceLength;
    Result.Pieces := APieceHashes;
    Result.Files.Add(AName, ALength);
  except
    Result.Free;
    raise;
  end;
end;

procedure TNXTorrentMetaInfo.LoadPiecesFromInfo(AInfo: TNXBEncodeDictionary);
begin
  FName := AInfo.RequireBytes('name');
  FPieceLength := AInfo.RequireInteger('piece length');
  FPieces := AInfo.RequireBytes('pieces');

  if FName = '' then
    raise ENXTorrentMetaInfoError.Create('Torrent name cannot be empty.');
  if FPieceLength <= 0 then
    raise ENXTorrentMetaInfoError.Create('Torrent piece length must be positive.');
  if Length(FPieces) mod 20 <> 0 then
    raise ENXTorrentMetaInfoError.Create('Torrent pieces field is not a hash list.');
end;

procedure TNXTorrentMetaInfo.LoadFilesFromInfo(AInfo: TNXBEncodeDictionary);
var
  lFiles: TNXBEncodeList;
  lFile: TNXBEncodeDictionary;
  lPath: TNXBEncodeList;
  lIndex: Integer;
  lPartIndex: Integer;
  lPathText: string;
begin
  FFiles.Clear;
  lFiles := AInfo.FindList('files');
  if Assigned(lFiles) then
  begin
    if lFiles.Count = 0 then
      raise ENXTorrentMetaInfoError.Create('Torrent multi-file list cannot be empty.');
    for lIndex := 0 to lFiles.Count - 1 do
    begin
      if not (lFiles[lIndex] is TNXBEncodeDictionary) then
        raise ENXTorrentMetaInfoError.Create('Torrent file entry is not a dictionary.');
      lFile := TNXBEncodeDictionary(lFiles[lIndex]);
      lPath := lFile.FindList('path');
      if not Assigned(lPath) then
        raise ENXTorrentMetaInfoError.Create('Torrent multi-file entry is missing path.');
      if lPath.Count = 0 then
        raise ENXTorrentMetaInfoError.Create('Torrent multi-file path cannot be empty.');
      lPathText := '';
      for lPartIndex := 0 to lPath.Count - 1 do
      begin
        if not (lPath[lPartIndex] is TNXBEncodeBytes) then
          raise ENXTorrentMetaInfoError.Create('Torrent path part is not text.');
        if TNXBEncodeBytes(lPath[lPartIndex]).Value = '' then
          raise ENXTorrentMetaInfoError.Create('Torrent path part cannot be empty.');
        if lPathText <> '' then
          lPathText := lPathText + DirectorySeparator;
        lPathText := lPathText + TNXBEncodeBytes(lPath[lPartIndex]).Value;
      end;
      FFiles.Add(lPathText, lFile.RequireInteger('length'));
    end;
  end
  else
    FFiles.Add(FName, AInfo.RequireInteger('length'));
end;

class function TNXTorrentMetaInfo.LoadFromBEncodedString(
  const AText: string): TNXTorrentMetaInfo;
var
  lRoot: TNXBEncodeDictionary;
  lInfo: TNXBEncodeDictionary;
  lValue: TNXBEncodeValue;
begin
  lRoot := TNXBEncodeCodec.DecodeDictionary(AText);
  try
    Result := TNXTorrentMetaInfo.Create;
    try
      Result.Announce := lRoot.RequireBytes('announce');
      lValue := lRoot.Find('comment');
      if lValue is TNXBEncodeBytes then
        Result.Comment := TNXBEncodeBytes(lValue).Value;
      lValue := lRoot.Find('created by');
      if lValue is TNXBEncodeBytes then
        Result.CreatedBy := TNXBEncodeBytes(lValue).Value;
      lValue := lRoot.Find('creation date');
      if lValue is TNXBEncodeInteger then
        Result.CreationDate := TNXBEncodeInteger(lValue).Value;

      lInfo := lRoot.RequireDictionary('info');
      Result.LoadPiecesFromInfo(lInfo);
      Result.LoadFilesFromInfo(lInfo);
      Result.FInfoDictionary := TNXBEncodeDictionary(lInfo.Clone);
    except
      Result.Free;
      raise;
    end;
  finally
    lRoot.Free;
  end;
end;

function TNXTorrentMetaInfo.BuildInfoDictionary: TNXBEncodeDictionary;
var
  lFiles: TNXBEncodeList;
  lFile: TNXBEncodeDictionary;
  lPath: TNXBEncodeList;
  lParts: TStringList;
  lIndex: Integer;
  lPartIndex: Integer;
begin
  Result := TNXBEncodeDictionary.Create;
  try
    if FFiles.Count = 1 then
      Result.Add('length', TNXBEncodeInteger.Create(FFiles[0].Length));
    if FFiles.Count > 1 then
    begin
      lFiles := TNXBEncodeList.Create;
      Result.Add('files', lFiles);
      for lIndex := 0 to FFiles.Count - 1 do
      begin
        lFile := TNXBEncodeDictionary.Create;
        lFiles.Add(lFile);
        lFile.Add('length', TNXBEncodeInteger.Create(FFiles[lIndex].Length));
        lPath := TNXBEncodeList.Create;
        lFile.Add('path', lPath);
        lParts := TStringList.Create;
        try
          ExtractStrings(['/', '\'], [], PChar(FFiles[lIndex].Path), lParts);
          for lPartIndex := 0 to lParts.Count - 1 do
            lPath.Add(TNXBEncodeBytes.Create(lParts[lPartIndex]));
        finally
          lParts.Free;
        end;
      end;
    end;
    Result.Add('name', TNXBEncodeBytes.Create(FName));
    Result.Add('piece length', TNXBEncodeInteger.Create(FPieceLength));
    Result.Add('pieces', TNXBEncodeBytes.Create(FPieces));
  except
    Result.Free;
    raise;
  end;
end;

function TNXTorrentMetaInfo.AsBEncodedString: string;
var
  lRoot: TNXBEncodeDictionary;
  lInfo: TNXBEncodeDictionary;
begin
  lRoot := TNXBEncodeDictionary.Create;
  try
    lRoot.Add('announce', TNXBEncodeBytes.Create(FAnnounce));
    if FComment <> '' then
      lRoot.Add('comment', TNXBEncodeBytes.Create(FComment));
    if FCreatedBy <> '' then
      lRoot.Add('created by', TNXBEncodeBytes.Create(FCreatedBy));
    if FCreationDate > 0 then
      lRoot.Add('creation date', TNXBEncodeInteger.Create(FCreationDate));
    lInfo := BuildInfoDictionary;
    lRoot.Add('info', lInfo);
    Result := lRoot.AsBEncodedString;
  finally
    lRoot.Free;
  end;
end;

function TNXTorrentMetaInfo.GetInfoHash: TNXTorrentHash;
var
  lText: string;
  lDigest: TSHA1Digest;
  lInfo: TNXBEncodeDictionary;
begin
  if Assigned(FInfoDictionary) then
    lText := FInfoDictionary.AsBEncodedString
  else
  begin
    lInfo := BuildInfoDictionary;
    try
      lText := lInfo.AsBEncodedString;
    finally
      lInfo.Free;
    end;
  end;

  lDigest := SHA1String(lText);
  Move(lDigest[0], Result[0], SizeOf(Result));
end;

function TNXTorrentMetaInfo.GetInfoHashHex: string;
begin
  Result := NXTorrentHashToHex(InfoHash);
end;

function TNXTorrentMetaInfo.PieceCount: Integer;
begin
  Result := Length(FPieces) div 20;
end;

function TNXTorrentMetaInfo.PieceHash(AIndex: Integer): TNXTorrentHash;
begin
  if (AIndex < 0) or (AIndex >= PieceCount) then
    raise ERangeError.Create('Torrent piece index is out of range.');
  Move(FPieces[(AIndex * 20) + 1], Result[0], 20);
end;

function TNXTorrentMetaInfo.IsMultiFile: Boolean;
begin
  Result := FFiles.Count > 1;
end;

end.

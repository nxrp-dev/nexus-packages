(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tpNXTorrent;

{$mode objfpc}{$H+}

interface

type
  TNXTorrentHash = array[0..19] of Byte;

  TNXTorrentFileInfo = record
    Path: string;
    Length: Int64;
  end;

  TNXTorrentPieceState = (
    tpsMissing,
    tpsPartial,
    tpsVerified
  );

  TNXTorrentSessionState = (
    tssStopped,
    tssRunning,
    tssPaused,
    tssComplete,
    tssError
  );

  TNXTorrentTrackerEvent = (
    tteNone,
    tteStarted,
    tteStopped,
    tteCompleted
  );

  TNXTorrentPeerMessageKind = (
    tpmKeepAlive,
    tpmChoke,
    tpmUnchoke,
    tpmInterested,
    tpmNotInterested,
    tpmHave,
    tpmBitfield,
    tpmRequest,
    tpmPiece,
    tpmCancel,
    tpmPort,
    tpmExtension
  );

function NXTorrentHashToHex(const AHash: TNXTorrentHash): string;
function NXTorrentHexToHash(const AHex: string): TNXTorrentHash;
function NXTorrentHashEquals(const ALeft, ARight: TNXTorrentHash): Boolean;
function NXTorrentEmptyHash: TNXTorrentHash;
function NXTorrentBytesToHex(const ABytes: string): string;
function NXTorrentURLQueryEscape(const AValue: string): string;

implementation

uses
  SysUtils;

const
  cHexDigits = '0123456789abcdef';

function NXTorrentHashToHex(const AHash: TNXTorrentHash): string;
var
  lIndex: Integer;
begin
  SetLength(Result, 40);
  for lIndex := 0 to 19 do
  begin
    Result[(lIndex * 2) + 1] := cHexDigits[(AHash[lIndex] shr 4) + 1];
    Result[(lIndex * 2) + 2] := cHexDigits[(AHash[lIndex] and $0f) + 1];
  end;
end;

function NXHexValue(AChar: Char): Byte;
begin
  case AChar of
    '0'..'9':
      Result := Ord(AChar) - Ord('0');
    'a'..'f':
      Result := Ord(AChar) - Ord('a') + 10;
    'A'..'F':
      Result := Ord(AChar) - Ord('A') + 10;
  else
    raise EConvertError.CreateFmt('Invalid hex digit "%s".', [AChar]);
  end;
end;

function NXTorrentHexToHash(const AHex: string): TNXTorrentHash;
var
  lIndex: Integer;
begin
  if Length(AHex) <> 40 then
    raise EConvertError.Create('Torrent hash hex text must be 40 characters.');

  for lIndex := 0 to 19 do
    Result[lIndex] := (NXHexValue(AHex[(lIndex * 2) + 1]) shl 4) or
      NXHexValue(AHex[(lIndex * 2) + 2]);
end;

function NXTorrentHashEquals(const ALeft, ARight: TNXTorrentHash): Boolean;
var
  lIndex: Integer;
begin
  Result := True;
  for lIndex := 0 to 19 do
    Result := Result and (ALeft[lIndex] = ARight[lIndex]);
end;

function NXTorrentEmptyHash: TNXTorrentHash;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function NXTorrentBytesToHex(const ABytes: string): string;
var
  lIndex: Integer;
  lValue: Byte;
begin
  SetLength(Result, Length(ABytes) * 2);
  for lIndex := 1 to Length(ABytes) do
  begin
    lValue := Ord(ABytes[lIndex]);
    Result[(lIndex * 2) - 1] := cHexDigits[(lValue shr 4) + 1];
    Result[lIndex * 2] := cHexDigits[(lValue and $0f) + 1];
  end;
end;

function NXTorrentURLQueryEscape(const AValue: string): string;
var
  lIndex: Integer;
  lByte: Byte;
begin
  Result := '';
  for lIndex := 1 to Length(AValue) do
  begin
    lByte := Ord(AValue[lIndex]);
    if (AValue[lIndex] in ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.', '~']) then
      Result := Result + AValue[lIndex]
    else
      Result := Result + '%' + cHexDigits[(lByte shr 4) + 1] +
        cHexDigits[(lByte and $0f) + 1];
  end;
end;

end.

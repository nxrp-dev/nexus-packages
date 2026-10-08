(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTorrentPeerProtocol;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, tpNXTorrent;

type
  ENXTorrentPeerProtocolError = class(Exception);

  TNXTorrentPeerMessage = class
  private
    FBlock: string;
    FIndex: Integer;
    FKind: TNXTorrentPeerMessageKind;
    FLength: Integer;
    FOffset: Integer;
    FPayload: string;
  public
    constructor Create(AKind: TNXTorrentPeerMessageKind);

    function Encode: string;

    property Block: string read FBlock write FBlock;
    property Index: Integer read FIndex write FIndex;
    property Kind: TNXTorrentPeerMessageKind read FKind;
    property Length: Integer read FLength write FLength;
    property Offset: Integer read FOffset write FOffset;
    property Payload: string read FPayload write FPayload;
  end;

  TNXTorrentHandshake = class
  private
    FInfoHash: TNXTorrentHash;
    FPeerId: string;
    FReserved: string;
  public
    constructor Create;

    function Encode: string;
    class function Decode(const AData: string): TNXTorrentHandshake;

    property InfoHash: TNXTorrentHash read FInfoHash write FInfoHash;
    property PeerId: string read FPeerId write FPeerId;
    property Reserved: string read FReserved write FReserved;
  end;

  TNXTorrentPeerMessageCodec = class
  public
    class function Decode(const AData: string; out ABytesUsed: Integer): TNXTorrentPeerMessage;
  end;

implementation

function NXReadUInt32(const AData: string; APosition: Integer): Cardinal;
begin
  Result := (Cardinal(Ord(AData[APosition])) shl 24) or
    (Cardinal(Ord(AData[APosition + 1])) shl 16) or
    (Cardinal(Ord(AData[APosition + 2])) shl 8) or
    Cardinal(Ord(AData[APosition + 3]));
end;

function NXReadUInt16(const AData: string; APosition: Integer): Word;
begin
  Result := (Word(Ord(AData[APosition])) shl 8) or
    Word(Ord(AData[APosition + 1]));
end;

function NXWriteUInt32(AValue: Cardinal): string;
begin
  SetLength(Result, 4);
  Result[1] := Chr((AValue shr 24) and $ff);
  Result[2] := Chr((AValue shr 16) and $ff);
  Result[3] := Chr((AValue shr 8) and $ff);
  Result[4] := Chr(AValue and $ff);
end;

function NXWriteUInt16(AValue: Word): string;
begin
  SetLength(Result, 2);
  Result[1] := Chr((AValue shr 8) and $ff);
  Result[2] := Chr(AValue and $ff);
end;

procedure NXRequireNonNegative(AValue: Integer; const AName: string);
begin
  if AValue < 0 then
    raise ENXTorrentPeerProtocolError.CreateFmt('%s cannot be negative.',
      [AName]);
end;

procedure NXRequirePositive(AValue: Integer; const AName: string);
begin
  if AValue <= 0 then
    raise ENXTorrentPeerProtocolError.CreateFmt('%s must be greater than zero.',
      [AName]);
end;

procedure NXRequireRequestBounds(AIndex, AOffset, ALength: Integer);
begin
  NXRequireNonNegative(AIndex, 'Piece index');
  NXRequireNonNegative(AOffset, 'Piece begin offset');
  NXRequirePositive(ALength, 'Request length');
  if Int64(AOffset) + Int64(ALength) > High(Integer) then
    raise ENXTorrentPeerProtocolError.Create('Request begin plus length overflows integer range.');
end;

procedure NXRequirePayloadLength(AId: Byte; AActual, AExpected: Cardinal;
  const AName: string);
begin
  if AActual <> AExpected then
    raise ENXTorrentPeerProtocolError.CreateFmt(
      'Invalid %s peer message length for id %d. Expected %d, got %d.',
      [AName, AId, AExpected, AActual]);
end;

procedure NXRequireMinPayloadLength(AId: Byte; AActual, AMinimum: Cardinal;
  const AName: string);
begin
  if AActual < AMinimum then
    raise ENXTorrentPeerProtocolError.CreateFmt(
      'Invalid %s peer message length for id %d. Expected at least %d, got %d.',
      [AName, AId, AMinimum, AActual]);
end;

constructor TNXTorrentPeerMessage.Create(AKind: TNXTorrentPeerMessageKind);
begin
  inherited Create;
  FKind := AKind;
end;

function TNXTorrentPeerMessage.Encode: string;
var
  lPayload: string;
begin
  case FKind of
    tpmKeepAlive:
      Exit(#0#0#0#0);
    tpmChoke:
      lPayload := #0;
    tpmUnchoke:
      lPayload := #1;
    tpmInterested:
      lPayload := #2;
    tpmNotInterested:
      lPayload := #3;
    tpmHave:
      begin
        NXRequireNonNegative(FIndex, 'Piece index');
        lPayload := #4 + NXWriteUInt32(FIndex);
      end;
    tpmBitfield:
      lPayload := #5 + FPayload;
    tpmRequest:
      begin
        NXRequireRequestBounds(FIndex, FOffset, FLength);
        lPayload := #6 + NXWriteUInt32(FIndex) + NXWriteUInt32(FOffset) +
          NXWriteUInt32(FLength);
      end;
    tpmPiece:
      begin
        NXRequireNonNegative(FIndex, 'Piece index');
        NXRequireNonNegative(FOffset, 'Piece begin offset');
        lPayload := #7 + NXWriteUInt32(FIndex) + NXWriteUInt32(FOffset) + FBlock;
      end;
    tpmCancel:
      begin
        NXRequireRequestBounds(FIndex, FOffset, FLength);
        lPayload := #8 + NXWriteUInt32(FIndex) + NXWriteUInt32(FOffset) +
          NXWriteUInt32(FLength);
      end;
    tpmPort:
      begin
        if (FOffset < 0) or (FOffset > 65535) then
          raise ENXTorrentPeerProtocolError.Create('Peer listen port must be in UInt16 range.');
        lPayload := #9 + NXWriteUInt16(FOffset);
      end;
    tpmExtension:
      lPayload := #20 + FPayload;
  end;
  Result := NXWriteUInt32(System.Length(lPayload)) + lPayload;
end;

constructor TNXTorrentHandshake.Create;
begin
  inherited Create;
  FReserved := #0#0#0#0#0#0#0#0;
end;

function TNXTorrentHandshake.Encode: string;
var
  lIndex: Integer;
begin
  if System.Length(FPeerId) <> 20 then
    raise ENXTorrentPeerProtocolError.Create('BitTorrent peer id must be 20 bytes.');
  if System.Length(FReserved) <> 8 then
    raise ENXTorrentPeerProtocolError.Create('BitTorrent reserved field must be 8 bytes.');
  SetLength(Result, 68);
  Result := Chr(19) + 'BitTorrent protocol' + FReserved;
  for lIndex := 0 to 19 do
    Result := Result + Chr(FInfoHash[lIndex]);
  Result := Result + FPeerId;
end;

class function TNXTorrentHandshake.Decode(
  const AData: string): TNXTorrentHandshake;
begin
  if System.Length(AData) < 68 then
    raise ENXTorrentPeerProtocolError.Create('Incomplete BitTorrent handshake.');
  if (Ord(AData[1]) <> 19) or (Copy(AData, 2, 19) <> 'BitTorrent protocol') then
    raise ENXTorrentPeerProtocolError.Create('Invalid BitTorrent handshake.');
  Result := TNXTorrentHandshake.Create;
  try
    Result.Reserved := Copy(AData, 21, 8);
    Move(AData[29], Result.FInfoHash[0], 20);
    Result.PeerId := Copy(AData, 49, 20);
  except
    Result.Free;
    raise;
  end;
end;

class function TNXTorrentPeerMessageCodec.Decode(const AData: string;
  out ABytesUsed: Integer): TNXTorrentPeerMessage;
var
  lLength: Cardinal;
  lId: Byte;
  lAvailable: Integer;
begin
  Result := nil;
  ABytesUsed := 0;
  if System.Length(AData) < 4 then
    Exit;
  lLength := NXReadUInt32(AData, 1);
  if lLength > Cardinal(High(Integer) - 4) then
    raise ENXTorrentPeerProtocolError.CreateFmt(
      'Peer message length %d exceeds supported integer range.', [lLength]);
  lAvailable := System.Length(AData) - 4;
  if lAvailable < Integer(lLength) then
  begin
    if System.Length(AData) > 4 then
      raise ENXTorrentPeerProtocolError.CreateFmt(
        'Incomplete peer message. Expected %d payload bytes, got %d.',
        [lLength, lAvailable]);
    Exit;
  end;
  ABytesUsed := 4 + Integer(lLength);
  if lLength = 0 then
    Exit(TNXTorrentPeerMessage.Create(tpmKeepAlive));
  lId := Ord(AData[5]);
  case lId of
    0:
      begin
        NXRequirePayloadLength(lId, lLength, 1, 'choke');
        Result := TNXTorrentPeerMessage.Create(tpmChoke);
      end;
    1:
      begin
        NXRequirePayloadLength(lId, lLength, 1, 'unchoke');
        Result := TNXTorrentPeerMessage.Create(tpmUnchoke);
      end;
    2:
      begin
        NXRequirePayloadLength(lId, lLength, 1, 'interested');
        Result := TNXTorrentPeerMessage.Create(tpmInterested);
      end;
    3:
      begin
        NXRequirePayloadLength(lId, lLength, 1, 'not interested');
        Result := TNXTorrentPeerMessage.Create(tpmNotInterested);
      end;
    4:
      begin
        NXRequirePayloadLength(lId, lLength, 5, 'have');
        Result := TNXTorrentPeerMessage.Create(tpmHave);
        Result.Index := NXReadUInt32(AData, 6);
      end;
    5:
      begin
        NXRequireMinPayloadLength(lId, lLength, 1, 'bitfield');
        Result := TNXTorrentPeerMessage.Create(tpmBitfield);
        Result.Payload := Copy(AData, 6, lLength - 1);
      end;
    6:
      begin
        NXRequirePayloadLength(lId, lLength, 13, 'request');
        Result := TNXTorrentPeerMessage.Create(tpmRequest);
        Result.Index := NXReadUInt32(AData, 6);
        Result.Offset := NXReadUInt32(AData, 10);
        Result.Length := NXReadUInt32(AData, 14);
        NXRequireRequestBounds(Result.Index, Result.Offset, Result.Length);
      end;
    7:
      begin
        NXRequireMinPayloadLength(lId, lLength, 9, 'piece');
        Result := TNXTorrentPeerMessage.Create(tpmPiece);
        Result.Index := NXReadUInt32(AData, 6);
        Result.Offset := NXReadUInt32(AData, 10);
        Result.Block := Copy(AData, 14, lLength - 9);
      end;
    8:
      begin
        NXRequirePayloadLength(lId, lLength, 13, 'cancel');
        Result := TNXTorrentPeerMessage.Create(tpmCancel);
        Result.Index := NXReadUInt32(AData, 6);
        Result.Offset := NXReadUInt32(AData, 10);
        Result.Length := NXReadUInt32(AData, 14);
        NXRequireRequestBounds(Result.Index, Result.Offset, Result.Length);
      end;
    9:
      begin
        NXRequirePayloadLength(lId, lLength, 3, 'port');
        Result := TNXTorrentPeerMessage.Create(tpmPort);
        Result.Offset := NXReadUInt16(AData, 6);
      end;
    20:
      begin
        NXRequireMinPayloadLength(lId, lLength, 1, 'extension');
        Result := TNXTorrentPeerMessage.Create(tpmExtension);
        Result.Payload := Copy(AData, 6, lLength - 1);
      end;
  else
    raise ENXTorrentPeerProtocolError.CreateFmt('Unsupported peer message id %d.',
      [lId]);
  end;
end;

end.

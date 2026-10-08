(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTorrentPeer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, tpNXTorrent, obNXTorrentPeerProtocol;

type
  TNXTorrentPeer = class
  private
    FAmChoked: Boolean;
    FAmInterested: Boolean;
    FPeerChoked: Boolean;
    FPeerId: string;
    FPeerInterested: Boolean;
    FPieces: array of Boolean;
    function GetPieceCount: Integer;
    function GetPieceAvailable(AIndex: Integer): Boolean;
    procedure SetPieceAvailable(AIndex: Integer; AValue: Boolean);
  public
    constructor Create(const APeerId: string; APieceCount: Integer);

    procedure ApplyHandshake(AHandshake: TNXTorrentHandshake);
    procedure ApplyMessage(AMessage: TNXTorrentPeerMessage);
    procedure LoadBitfield(const ABitfield: string);
    function HasPiece(AIndex: Integer): Boolean;
    function CompletePieceCount: Integer;

    property AmChoked: Boolean read FAmChoked write FAmChoked;
    property AmInterested: Boolean read FAmInterested write FAmInterested;
    property PeerChoked: Boolean read FPeerChoked write FPeerChoked;
    property PeerId: string read FPeerId;
    property PeerInterested: Boolean read FPeerInterested write FPeerInterested;
    property PieceAvailable[AIndex: Integer]: Boolean read GetPieceAvailable
      write SetPieceAvailable;
    property PieceCount: Integer read GetPieceCount;
  end;

implementation

constructor TNXTorrentPeer.Create(const APeerId: string; APieceCount: Integer);
begin
  inherited Create;
  if APieceCount < 0 then
    raise ERangeError.Create('Torrent peer piece count cannot be negative.');
  FPeerId := APeerId;
  FAmChoked := True;
  FPeerChoked := True;
  SetLength(FPieces, APieceCount);
end;

function TNXTorrentPeer.GetPieceCount: Integer;
begin
  Result := Length(FPieces);
end;

function TNXTorrentPeer.GetPieceAvailable(AIndex: Integer): Boolean;
begin
  if (AIndex < 0) or (AIndex >= PieceCount) then
    raise ERangeError.Create('Torrent peer piece index is out of range.');
  Result := FPieces[AIndex];
end;

procedure TNXTorrentPeer.SetPieceAvailable(AIndex: Integer; AValue: Boolean);
begin
  if (AIndex < 0) or (AIndex >= PieceCount) then
    raise ERangeError.Create('Torrent peer piece index is out of range.');
  FPieces[AIndex] := AValue;
end;

procedure TNXTorrentPeer.ApplyHandshake(AHandshake: TNXTorrentHandshake);
begin
  if not Assigned(AHandshake) then
    raise EArgumentNilException.Create('AHandshake');
  FPeerId := AHandshake.PeerId;
end;

procedure TNXTorrentPeer.LoadBitfield(const ABitfield: string);
var
  lPieceIndex: Integer;
  lByteIndex: Integer;
  lBitIndex: Integer;
begin
  for lPieceIndex := 0 to PieceCount - 1 do
  begin
    lByteIndex := lPieceIndex div 8;
    lBitIndex := 7 - (lPieceIndex mod 8);
    if lByteIndex < Length(ABitfield) then
      FPieces[lPieceIndex] := (Ord(ABitfield[lByteIndex + 1]) and
        (1 shl lBitIndex)) <> 0
    else
      FPieces[lPieceIndex] := False;
  end;
end;

procedure TNXTorrentPeer.ApplyMessage(AMessage: TNXTorrentPeerMessage);
begin
  if not Assigned(AMessage) then
    raise EArgumentNilException.Create('AMessage');

  case AMessage.Kind of
    tpmChoke:
      FAmChoked := True;
    tpmUnchoke:
      FAmChoked := False;
    tpmInterested:
      FPeerInterested := True;
    tpmNotInterested:
      FPeerInterested := False;
    tpmHave:
      PieceAvailable[AMessage.Index] := True;
    tpmBitfield:
      LoadBitfield(AMessage.Payload);
  end;
end;

function TNXTorrentPeer.HasPiece(AIndex: Integer): Boolean;
begin
  Result := PieceAvailable[AIndex];
end;

function TNXTorrentPeer.CompletePieceCount: Integer;
var
  lIndex: Integer;
begin
  Result := 0;
  for lIndex := 0 to PieceCount - 1 do
    if FPieces[lIndex] then
      Inc(Result);
end;

end.

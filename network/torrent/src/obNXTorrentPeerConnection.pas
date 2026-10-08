(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTorrentPeerConnection;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, blcksock, synsock, tpNXTorrent, obNXTorrentPeerProtocol;

type
  ENXTorrentPeerConnectionError = class(Exception);

const
  NXTorrentMaxPeerMessageBytes = 2 * 1024 * 1024;

type
  TNXTorrentPeerConnection = class
  private
    FHost: string;
    FPort: Integer;
    FSocket: TTCPBlockSocket;
    FTimeout: Integer;
    FOwnsSocket: Boolean;
    function SocketError: string;
    function ReadExact(ALength: Integer): string;
    procedure WriteExact(const AData: string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure AttachAcceptedSocket(ASocket: TSocket);
    procedure Close;
    procedure Connect(const AHost: string; APort: Integer);
    function IsConnected: Boolean;
    function ReceiveHandshake: TNXTorrentHandshake;
    function ReceiveMessage: TNXTorrentPeerMessage;
    procedure SendHandshake(AHandshake: TNXTorrentHandshake);
    procedure SendMessage(AMessage: TNXTorrentPeerMessage);
    class procedure ValidatePeerMessageLength(ALength: Cardinal); static;

    property Host: string read FHost;
    property Port: Integer read FPort;
    property Timeout: Integer read FTimeout write FTimeout;
  end;

  TNXTorrentPeerListener = class
  private
    FHost: string;
    FListener: TTCPBlockSocket;
    FPort: Integer;
    FTimeout: Integer;
    function SocketError: string;
  public
    constructor Create;
    destructor Destroy; override;

    function Accept: TNXTorrentPeerConnection;
    procedure Close;
    procedure Open(const AHost: string; APort: Integer);

    property Host: string read FHost;
    property Port: Integer read FPort;
    property Timeout: Integer read FTimeout write FTimeout;
  end;

implementation

constructor TNXTorrentPeerConnection.Create;
begin
  inherited Create;
  FTimeout := 30000;
  FOwnsSocket := True;
  FSocket := TTCPBlockSocket.Create;
end;

destructor TNXTorrentPeerConnection.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TNXTorrentPeerConnection.SocketError: string;
begin
  if not Assigned(FSocket) then
    Exit('socket not assigned');
  Result := Format('%d: %s', [FSocket.LastError, FSocket.LastErrorDesc]);
end;

procedure TNXTorrentPeerConnection.Close;
begin
  if FOwnsSocket then
    FreeAndNil(FSocket)
  else
    FSocket := nil;
end;

procedure TNXTorrentPeerConnection.Connect(const AHost: string; APort: Integer);
begin
  if not Assigned(FSocket) then
    FSocket := TTCPBlockSocket.Create;
  FHost := AHost;
  FPort := APort;
  FSocket.Connect(AHost, IntToStr(APort));
  if FSocket.LastError <> 0 then
    raise ENXTorrentPeerConnectionError.CreateFmt(
      'Unable to connect to peer %s:%d. %s', [AHost, APort, SocketError]);
end;

procedure TNXTorrentPeerConnection.AttachAcceptedSocket(ASocket: TSocket);
begin
  Close;
  FOwnsSocket := True;
  FSocket := TTCPBlockSocket.Create;
  FSocket.Socket := ASocket;
  FSocket.GetSinRemote;
  FHost := FSocket.GetRemoteSinIP;
  FPort := FSocket.GetRemoteSinPort;
end;

function TNXTorrentPeerConnection.IsConnected: Boolean;
begin
  Result := Assigned(FSocket) and (FSocket.Socket <> INVALID_SOCKET);
end;

function TNXTorrentPeerConnection.ReadExact(ALength: Integer): string;
begin
  Result := FSocket.RecvBufferStr(ALength, FTimeout);
  if (FSocket.LastError <> 0) or (Length(Result) <> ALength) then
    raise ENXTorrentPeerConnectionError.CreateFmt(
      'Unable to read %d bytes from peer. %s', [ALength, SocketError]);
end;

class procedure TNXTorrentPeerConnection.ValidatePeerMessageLength(
  ALength: Cardinal);
begin
  if ALength > NXTorrentMaxPeerMessageBytes then
    raise ENXTorrentPeerConnectionError.CreateFmt(
      'Peer message length %d exceeds maximum %d.',
      [ALength, NXTorrentMaxPeerMessageBytes]);
end;

procedure TNXTorrentPeerConnection.WriteExact(const AData: string);
begin
  FSocket.SendString(AnsiString(AData));
  if FSocket.LastError <> 0 then
    raise ENXTorrentPeerConnectionError.CreateFmt('Unable to write to peer. %s',
      [SocketError]);
end;

function TNXTorrentPeerConnection.ReceiveHandshake: TNXTorrentHandshake;
begin
  Result := TNXTorrentHandshake.Decode(ReadExact(68));
end;

procedure TNXTorrentPeerConnection.SendHandshake(AHandshake: TNXTorrentHandshake);
begin
  if not Assigned(AHandshake) then
    raise EArgumentNilException.Create('AHandshake');
  WriteExact(AHandshake.Encode);
end;

function TNXTorrentPeerConnection.ReceiveMessage: TNXTorrentPeerMessage;
var
  lPrefix: string;
  lLength: Cardinal;
  lPacket: string;
  lUsed: Integer;
begin
  lPrefix := ReadExact(4);
  lLength := (Cardinal(Ord(lPrefix[1])) shl 24) or
    (Cardinal(Ord(lPrefix[2])) shl 16) or
    (Cardinal(Ord(lPrefix[3])) shl 8) or Cardinal(Ord(lPrefix[4]));
  ValidatePeerMessageLength(lLength);
  lPacket := lPrefix;
  if lLength > 0 then
    lPacket := lPacket + ReadExact(lLength);
  Result := TNXTorrentPeerMessageCodec.Decode(lPacket, lUsed);
  if not Assigned(Result) then
    raise ENXTorrentPeerConnectionError.Create('Incomplete peer message read.');
end;

procedure TNXTorrentPeerConnection.SendMessage(AMessage: TNXTorrentPeerMessage);
begin
  if not Assigned(AMessage) then
    raise EArgumentNilException.Create('AMessage');
  WriteExact(AMessage.Encode);
end;

constructor TNXTorrentPeerListener.Create;
begin
  inherited Create;
  FTimeout := 30000;
end;

destructor TNXTorrentPeerListener.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TNXTorrentPeerListener.SocketError: string;
begin
  if not Assigned(FListener) then
    Exit('listener not assigned');
  Result := Format('%d: %s', [FListener.LastError, FListener.LastErrorDesc]);
end;

procedure TNXTorrentPeerListener.Open(const AHost: string; APort: Integer);
begin
  Close;
  FHost := AHost;
  FPort := APort;
  FListener := TTCPBlockSocket.Create;
  FListener.EnableReuse(True);
  FListener.Bind(AHost, IntToStr(APort));
  if FListener.LastError <> 0 then
    raise ENXTorrentPeerConnectionError.CreateFmt(
      'Unable to bind torrent peer listener on %s:%d. %s',
      [AHost, APort, SocketError]);
  FListener.Listen;
  if FListener.LastError <> 0 then
    raise ENXTorrentPeerConnectionError.CreateFmt(
      'Unable to listen for torrent peers on %s:%d. %s',
      [AHost, APort, SocketError]);
end;

procedure TNXTorrentPeerListener.Close;
begin
  FreeAndNil(FListener);
end;

function TNXTorrentPeerListener.Accept: TNXTorrentPeerConnection;
var
  lSocket: TSocket;
begin
  if not Assigned(FListener) then
    raise ENXTorrentPeerConnectionError.Create('Torrent peer listener is not open.');
  lSocket := FListener.Accept;
  if (FListener.LastError <> 0) or (lSocket = INVALID_SOCKET) then
    raise ENXTorrentPeerConnectionError.CreateFmt(
      'Unable to accept torrent peer. %s', [SocketError]);
  Result := TNXTorrentPeerConnection.Create;
  try
    Result.Timeout := FTimeout;
    Result.AttachAcceptedSocket(lSocket);
  except
    Result.Free;
    raise;
  end;
end;

end.

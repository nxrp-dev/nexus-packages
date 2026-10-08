(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPTransport;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, blcksock, synsock, ssl_openssl3, obNXXMPPError,
  tpNXXMPPTypes;

type
  TNXXMPPTransport = class
  private
    FSocket: TTCPBlockSocket;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Close;
    procedure Connect(const AHost: string; APort: Word; ATimeoutMS: Integer);
    procedure Interrupt;
    function Receive(ATimeoutMS: Integer): RawByteString;
    procedure Secure(const AServiceIdentity, ACAFile: string);
    procedure Send(const AValue: RawByteString);
    property Socket: TTCPBlockSocket read FSocket;
  end;

implementation

constructor TNXXMPPTransport.Create;
begin
  inherited Create;
  FSocket := TTCPBlockSocket.Create;
end;

destructor TNXXMPPTransport.Destroy;
begin
  Close;
  FSocket.Free;
  inherited Destroy;
end;

procedure TNXXMPPTransport.Connect(const AHost: string; APort: Word;
  ATimeoutMS: Integer);
begin
  FSocket.ConnectionTimeout := ATimeoutMS;
  FSocket.Connect(AHost, IntToStr(APort));
  if FSocket.LastError <> 0 then
    raise ENXXMPPError.Create(xesConnection, 'connect-failed',
      'The XMPP TCP connection failed: ' + FSocket.LastErrorDesc, True);
end;

procedure TNXXMPPTransport.Secure(const AServiceIdentity, ACAFile: string);
begin
  if (ACAFile = '') or not FileExists(ACAFile) then
    raise ENXXMPPError.Create(xesTLS, 'missing-ca-file',
      'A readable CA bundle is required before TLS starts.');
  if not (FSocket.SSL is TSSLOpenSSL3) then
    raise ENXXMPPError.Create(xesTLS, 'openssl-provider-not-selected',
      'Synapse did not select the OpenSSL 3 TLS provider.');
  FSocket.SSL.VerifyCert := True;
  FSocket.SSL.CertCAFile := ACAFile;
  FSocket.SSL.SNIHost := AServiceIdentity;
  FSocket.SSL.SSLType := LT_TLSv1_2;
  FSocket.SSLDoConnect;
  if (FSocket.LastError <> 0) or not FSocket.SSL.SSLEnabled then
    raise ENXXMPPError.Create(xesTLS, 'tls-failed',
      'The verified TLS connection failed: ' + FSocket.GetErrorDescEx);
end;

procedure TNXXMPPTransport.Send(const AValue: RawByteString);
begin
  FSocket.SendString(AnsiString(AValue));
  if FSocket.LastError <> 0 then
    raise ENXXMPPError.Create(xesConnection, 'send-failed',
      'The XMPP socket write failed: ' + FSocket.LastErrorDesc, True);
end;

function TNXXMPPTransport.Receive(ATimeoutMS: Integer): RawByteString;
begin
  Result := RawByteString(FSocket.RecvPacket(ATimeoutMS));
  if (Result = '') and (FSocket.LastError <> 0) and
    (FSocket.LastError <> WSAETIMEDOUT) and
    (FSocket.LastError <> WSAEWOULDBLOCK) then
    raise ENXXMPPError.Create(xesConnection, 'receive-failed',
      'The XMPP socket read failed: ' + FSocket.LastErrorDesc, True);
end;

procedure TNXXMPPTransport.Interrupt;
begin
  if Assigned(FSocket) and (FSocket.Socket <> INVALID_SOCKET) then
    synsock.Shutdown(FSocket.Socket, 2);
end;

procedure TNXXMPPTransport.Close;
begin
  if Assigned(FSocket) and (FSocket.Socket <> INVALID_SOCKET) then
  begin
    if FSocket.SSL.SSLEnabled then
      FSocket.SSLDoShutdown;
    FSocket.CloseSocket;
  end;
end;

end.

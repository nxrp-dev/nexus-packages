(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXLSTcpIPTransport;

{$mode objfpc}{$H+}

interface

uses
  tpNXLS,
  obNXLSTransport,
  blcksock;

type
  TNXLSTcpIPTransport = class(TNXLSTransport)
  private
    FHost: string;
    FPort: Word;
    FOpen: Boolean;
    FListener: TTCPBlockSocket;
    FClient: TTCPBlockSocket;
    procedure AcceptClient;
    function GetSocketError(const ASocket: TTCPBlockSocket): string;
  protected
    function ReadLine(out ALine: string): Boolean; override;
    function ReadContent(const ALength: Integer; out AContent: string): Boolean; override;
    procedure WriteContent(const AContent: string); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    class function GetFactoryName: string; override;
    procedure Open; override;
    procedure Close; override;
    function IsOpen: Boolean; override;
    function ReadMessage(out AMessage: string): Boolean; override;
    property Host: string read FHost;
    property Port: Word read FPort;
  end;

implementation

uses
  SysUtils,
  synsock,
  obNXClassFactory,
  obNXCommandLine,
  obNXLSLogger;

function GetCommandLinePort: Word;
var
  lValue: Integer;
begin
  lValue := StrToIntDef(TNXCommandLine.GetValueDefault('port', '2087'), 2087);

  if (lValue < 1) or (lValue > 65535) then
    raise ENXLSException.CreateFmt('Invalid TCP/IP port "%d".', [lValue]);

  Result := lValue;
end;

constructor TNXLSTcpIPTransport.Create;
begin
  inherited Create;
  FHost := TNXCommandLine.GetValueDefault('host', '127.0.0.1');
  FPort := GetCommandLinePort;
end;

destructor TNXLSTcpIPTransport.Destroy;
begin
  Close;
  inherited Destroy;
end;

class function TNXLSTcpIPTransport.GetFactoryName: string;
begin
  Result := 'tcpip';
end;

function TNXLSTcpIPTransport.GetSocketError(const ASocket: TTCPBlockSocket): string;
begin
  if ASocket = nil then
    Exit('socket has not been assigned');

  Result := Format('%d: %s', [ASocket.LastError, ASocket.LastErrorDesc]);
end;

procedure TNXLSTcpIPTransport.AcceptClient;
var
  lAcceptedSocket: TSocket;
begin
  if FListener = nil then
    raise ENXLSException.Create('TCP/IP transport listener has not been opened.');

  lAcceptedSocket := FListener.Accept;

  if (FListener.LastError <> 0) or (lAcceptedSocket = INVALID_SOCKET) then
    raise ENXLSException.CreateFmt('Unable to accept TCP/IP transport connection on %s:%d. %s', [FHost, FPort, GetSocketError(FListener)]);

  FClient := TTCPBlockSocket.Create;
  FClient.Socket := lAcceptedSocket;
  FClient.GetSinRemote;
  TNXLSLogger.Info(Format('TCP/IP transport accepted connection from %s:%s.', [FClient.GetRemoteSinIP, IntToStr(FClient.GetRemoteSinPort)]));
end;

procedure TNXLSTcpIPTransport.Open;
begin
  if FOpen then
    Exit;

  FListener := TTCPBlockSocket.Create;
  FListener.EnableReuse(True);
  FListener.Bind(FHost, IntToStr(FPort));

  if FListener.LastError <> 0 then
    raise ENXLSException.CreateFmt('Unable to bind TCP/IP transport to %s:%d. %s', [FHost, FPort, GetSocketError(FListener)]);

  FListener.Listen;

  if FListener.LastError <> 0 then
    raise ENXLSException.CreateFmt('Unable to listen on TCP/IP transport %s:%d. %s', [FHost, FPort, GetSocketError(FListener)]);

  FOpen := True;
  TNXLSLogger.Info(Format('TCP/IP transport listening on %s:%d.', [FHost, FPort]));
end;

procedure TNXLSTcpIPTransport.Close;
begin
  FreeAndNil(FClient);
  FreeAndNil(FListener);
  FOpen := False;
end;

function TNXLSTcpIPTransport.IsOpen: Boolean;
begin
  Result := FOpen;
end;

function TNXLSTcpIPTransport.ReadLine(out ALine: string): Boolean;
begin
  ALine := '';

  if FClient = nil then
    AcceptClient;

  ALine := string(FClient.RecvString(-1));

  if FClient.LastError <> 0 then
  begin
    FreeAndNil(FClient);
    Exit(False);
  end;

  Result := True;
end;

function TNXLSTcpIPTransport.ReadContent(const ALength: Integer; out AContent: string): Boolean;
var
  lContent: AnsiString;
begin
  lContent := FClient.RecvBufferStr(ALength, -1);

  if FClient.LastError <> 0 then
  begin
    FreeAndNil(FClient);
    Exit(False);
  end;

  if Length(lContent) <> ALength then
    raise ENXLSException.Create('Unexpected end of TCP/IP input while reading message content.');

  AContent := string(lContent);
  Result := True;
end;

function TNXLSTcpIPTransport.ReadMessage(out AMessage: string): Boolean;
begin
  while IsOpen do
  begin
    try
      Result := inherited ReadMessage(AMessage);
      if Result then
        Exit;

      FreeAndNil(FClient);
    except
      on E: ENXLSException do
      begin
        if FClient = nil then
          raise;

        TNXLSLogger.Error('Closing malformed TCP/IP client. ' + E.Message);
        FreeAndNil(FClient);
      end;
    end;
  end;

  Result := False;
end;

procedure TNXLSTcpIPTransport.WriteContent(const AContent: string);
begin
  if FClient = nil then
    raise ENXLSException.Create('Cannot write to a closed TCP/IP transport.');

  FClient.SendString(AnsiString(AContent));

  if FClient.LastError <> 0 then
    raise ENXLSException.CreateFmt('Unable to write TCP/IP message. %s', [GetSocketError(FClient)]);
end;

initialization
  TNXClassFactory.RegisterClass(TNXLSTcpIPTransport);

end.

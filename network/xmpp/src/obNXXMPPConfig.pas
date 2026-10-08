(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPConfig;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, obNXXMPPError, obNXXMPPJID, tpNXXMPPTypes,
  utNXXMPPASCII;

type
  TNXXMPPClientConfig = class
  private
    FAllowPlain: Boolean;
    FCAFile: string;
    FCommandCapacity: Integer;
    FConnectionTimeoutMS: Integer;
    FDirectTLS: Boolean;
    FEndpointHost: string;
    FEndpointPort: Word;
    FJID: UTF8String;
    FPassword: UTF8String;
    FPendingIQCapacity: Integer;
    FReconnectAttempts: Integer;
    FReconnectDelayMS: Cardinal;
    FResource: UTF8String;
    FCapabilityCacheCapacity: Integer;
    FCapabilityCacheTTLMS: Cardinal;
    FMAMConcurrentCapacity: Integer;
    FMAMMaximumBytes: QWord;
    FMAMMaximumPageSize: Integer;
    FMAMMaximumResults: Integer;
    FMUCHistoryCapacity: Integer;
    FMUCOccupantCapacity: Integer;
    FMUCRoomCapacity: Integer;
    FMUCSelfPingTimeoutMS: Cardinal;
    FReceiptCapacity: Integer;
    FReceiptTimeoutMS: Cardinal;
    FReplyFallbackMaximumCharacters: Integer;
    FForwardingMaximumDepth: Integer;
  public
    constructor Create;
    function Clone: TNXXMPPClientConfig;
    procedure Validate;
    property AllowPlain: Boolean read FAllowPlain write FAllowPlain;
    property CAFile: string read FCAFile write FCAFile;
    property CommandCapacity: Integer read FCommandCapacity
      write FCommandCapacity;
    property ConnectionTimeoutMS: Integer read FConnectionTimeoutMS
      write FConnectionTimeoutMS;
    property DirectTLS: Boolean read FDirectTLS write FDirectTLS;
    property EndpointHost: string read FEndpointHost write FEndpointHost;
    property EndpointPort: Word read FEndpointPort write FEndpointPort;
    property JID: UTF8String read FJID write FJID;
    property Password: UTF8String read FPassword write FPassword;
    property PendingIQCapacity: Integer read FPendingIQCapacity
      write FPendingIQCapacity;
    property ReconnectAttempts: Integer read FReconnectAttempts
      write FReconnectAttempts;
    property ReconnectDelayMS: Cardinal read FReconnectDelayMS
      write FReconnectDelayMS;
    property Resource: UTF8String read FResource write FResource;
    property CapabilityCacheCapacity: Integer read FCapabilityCacheCapacity
      write FCapabilityCacheCapacity;
    property CapabilityCacheTTLMS: Cardinal read FCapabilityCacheTTLMS
      write FCapabilityCacheTTLMS;
    property MAMConcurrentCapacity: Integer read FMAMConcurrentCapacity
      write FMAMConcurrentCapacity;
    property MAMMaximumBytes: QWord read FMAMMaximumBytes
      write FMAMMaximumBytes;
    property MAMMaximumPageSize: Integer read FMAMMaximumPageSize
      write FMAMMaximumPageSize;
    property MAMMaximumResults: Integer read FMAMMaximumResults
      write FMAMMaximumResults;
    property MUCHistoryCapacity: Integer read FMUCHistoryCapacity
      write FMUCHistoryCapacity;
    property MUCOccupantCapacity: Integer read FMUCOccupantCapacity
      write FMUCOccupantCapacity;
    property MUCRoomCapacity: Integer read FMUCRoomCapacity
      write FMUCRoomCapacity;
    property MUCSelfPingTimeoutMS: Cardinal read FMUCSelfPingTimeoutMS
      write FMUCSelfPingTimeoutMS;
    property ReceiptCapacity: Integer read FReceiptCapacity
      write FReceiptCapacity;
    property ReceiptTimeoutMS: Cardinal read FReceiptTimeoutMS
      write FReceiptTimeoutMS;
    property ReplyFallbackMaximumCharacters: Integer
      read FReplyFallbackMaximumCharacters
      write FReplyFallbackMaximumCharacters;
    property ForwardingMaximumDepth: Integer read FForwardingMaximumDepth
      write FForwardingMaximumDepth;
  end;

implementation

constructor TNXXMPPClientConfig.Create;
begin
  inherited Create;
  FCommandCapacity := cNXXMPPDefaultCommandCapacity;
  FPendingIQCapacity := cNXXMPPDefaultPendingIQCapacity;
  FConnectionTimeoutMS := cNXXMPPDefaultTimeoutMS;
  FReconnectAttempts := 3;
  FReconnectDelayMS := 1000;
  FCapabilityCacheCapacity := 128;
  FCapabilityCacheTTLMS := 3600000;
  FMAMConcurrentCapacity := 8;
  FMAMMaximumBytes := 4 * 1024 * 1024;
  FMAMMaximumPageSize := 100;
  FMAMMaximumResults := 1000;
  FMUCHistoryCapacity := 100;
  FMUCOccupantCapacity := 512;
  FMUCRoomCapacity := 32;
  FMUCSelfPingTimeoutMS := 10000;
  FReceiptCapacity := 256;
  FReceiptTimeoutMS := 300000;
  FReplyFallbackMaximumCharacters := 4096;
  FForwardingMaximumDepth := 1;
end;

function TNXXMPPClientConfig.Clone: TNXXMPPClientConfig;
begin
  Result := TNXXMPPClientConfig.Create;
  Result.FAllowPlain := FAllowPlain;
  Result.FCAFile := FCAFile;
  Result.FCommandCapacity := FCommandCapacity;
  Result.FConnectionTimeoutMS := FConnectionTimeoutMS;
  Result.FDirectTLS := FDirectTLS;
  Result.FEndpointHost := FEndpointHost;
  Result.FEndpointPort := FEndpointPort;
  Result.FJID := FJID;
  Result.FPassword := FPassword;
  Result.FPendingIQCapacity := FPendingIQCapacity;
  Result.FReconnectAttempts := FReconnectAttempts;
  Result.FReconnectDelayMS := FReconnectDelayMS;
  Result.FResource := FResource;
  Result.FCapabilityCacheCapacity := FCapabilityCacheCapacity;
  Result.FCapabilityCacheTTLMS := FCapabilityCacheTTLMS;
  Result.FMAMConcurrentCapacity := FMAMConcurrentCapacity;
  Result.FMAMMaximumBytes := FMAMMaximumBytes;
  Result.FMAMMaximumPageSize := FMAMMaximumPageSize;
  Result.FMAMMaximumResults := FMAMMaximumResults;
  Result.FMUCHistoryCapacity := FMUCHistoryCapacity;
  Result.FMUCOccupantCapacity := FMUCOccupantCapacity;
  Result.FMUCRoomCapacity := FMUCRoomCapacity;
  Result.FMUCSelfPingTimeoutMS := FMUCSelfPingTimeoutMS;
  Result.FReceiptCapacity := FReceiptCapacity;
  Result.FReceiptTimeoutMS := FReceiptTimeoutMS;
  Result.FReplyFallbackMaximumCharacters := FReplyFallbackMaximumCharacters;
  Result.FForwardingMaximumDepth := FForwardingMaximumDepth;
end;

procedure TNXXMPPClientConfig.Validate;
var
  lJID: TNXXMPPJID;
begin
  lJID := TNXXMPPJID.Create(FJID);
  lJID.Free;
  if (FResource <> '') and not NXXMPPIsASCIIText(FResource) then
    raise ENXXMPPError.Create(xesConfiguration, 'invalid-resource',
      'The XMPP resource must contain printable ASCII characters only.');
  if FPassword = '' then
    raise ENXXMPPError.Create(xesConfiguration, 'missing-password',
      'An XMPP account password is required.');
  if not NXXMPPIsASCIIText(FPassword) then
    raise ENXXMPPError.Create(xesConfiguration, 'invalid-password',
      'The XMPP account password must contain printable ASCII characters only.');
  if (FCAFile = '') or not FileExists(FCAFile) then
    raise ENXXMPPError.Create(xesConfiguration, 'missing-ca-file',
      'A readable OpenSSL CA bundle is required.');
  if (FEndpointHost = '') <> (FEndpointPort = 0) then
    raise ENXXMPPError.Create(xesConfiguration, 'incomplete-endpoint',
      'An endpoint override requires both host and port.');
  if (FCommandCapacity < 1) or (FPendingIQCapacity < 1) or
    (FConnectionTimeoutMS < 1) or
    (FReconnectAttempts < 0) or (FCapabilityCacheCapacity < 1) or
    (FCapabilityCacheTTLMS < 1) or (FMAMConcurrentCapacity < 1) or
    (FMAMMaximumBytes < 1) or (FMAMMaximumPageSize < 1) or
    (FMAMMaximumResults < 1) or (FMUCHistoryCapacity < 0) or
    (FMUCOccupantCapacity < 1) or (FMUCRoomCapacity < 1) or
    (FMUCSelfPingTimeoutMS < 1) or (FReceiptCapacity < 1) or
    (FReceiptTimeoutMS < 1) or (FReplyFallbackMaximumCharacters < 0) or
    (FForwardingMaximumDepth < 1) then
    raise ENXXMPPError.Create(xesConfiguration, 'invalid-client-limit',
      'XMPP capacities and timeouts must be positive, with explicitly ' +
      'optional limits allowed to be zero.');
end;

end.

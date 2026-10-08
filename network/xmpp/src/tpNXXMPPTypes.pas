(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tpNXXMPPTypes;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils;

const
  cNXXMPPDefaultCommandCapacity = 256;
  cNXXMPPDefaultPendingIQCapacity = 128;
  cNXXMPPDefaultMaxStanzaBytes = 1024 * 1024;
  cNXXMPPDefaultMaxNestingDepth = 64;
  cNXXMPPDefaultTimeoutMS = 30000;

type
  TNXXMPPConnectionState = (
    xcsDisconnected,
    xcsResolving,
    xcsConnecting,
    xcsSecuring,
    xcsAuthenticating,
    xcsBinding,
    xcsOnline,
    xcsResuming,
    xcsClosing,
    xcsFailed
  );

  TNXXMPPErrorStage = (
    xesConfiguration,
    xesResolution,
    xesConnection,
    xesTLS,
    xesStream,
    xesAuthentication,
    xesBinding,
    xesProtocol,
    xesShutdown
  );

  TNXXMPPStanzaKind = (xskUnknown, xskMessage, xskPresence, xskIQ);
  TNXXMPPIQType = (xitUnknown, xitGet, xitSet, xitResult, xitError);
  TNXXMPPTransportSecurity = (xtsStartTLS, xtsDirectTLS);
  TNXXMPPReplayPolicy = (xrpNever, xrpStreamManaged);
  TNXXMPPModuleLifecycle = (xmlTemporaryLoss, xmlStreamResumed,
    xmlNewSession, xmlPermanentLoss, xmlFinalDisconnect);

  TNXXMPPEndpoint = record
    Host: string;
    Port: Word;
    Priority: Word;
    Weight: Word;
    Security: TNXXMPPTransportSecurity;
  end;

  TNXXMPPEndpointArray = array of TNXXMPPEndpoint;

function NXXMPPConnectionStateName(AState: TNXXMPPConnectionState): string;
function NXXMPPStateTransitionAllowed(AFrom,
  ATo: TNXXMPPConnectionState): Boolean;
function NXXMPPIQTypeFromString(const AValue: string): TNXXMPPIQType;
function NXXMPPIQTypeName(AValue: TNXXMPPIQType): string;

implementation

function NXXMPPConnectionStateName(AState: TNXXMPPConnectionState): string;
begin
  case AState of
    xcsDisconnected: Result := 'disconnected';
    xcsResolving: Result := 'resolving';
    xcsConnecting: Result := 'connecting';
    xcsSecuring: Result := 'securing';
    xcsAuthenticating: Result := 'authenticating';
    xcsBinding: Result := 'binding';
    xcsOnline: Result := 'online';
    xcsResuming: Result := 'resuming';
    xcsClosing: Result := 'closing';
    xcsFailed: Result := 'failed';
  end;
end;

function NXXMPPStateTransitionAllowed(AFrom,
  ATo: TNXXMPPConnectionState): Boolean;
begin
  if ATo = xcsFailed then
    Exit(AFrom <> xcsFailed);
  case AFrom of
    xcsDisconnected:
      Result := ATo in [xcsResolving, xcsConnecting, xcsClosing];
    xcsResolving:
      Result := ATo in [xcsConnecting, xcsClosing];
    xcsConnecting:
      Result := ATo in [xcsConnecting, xcsSecuring, xcsAuthenticating,
        xcsResuming, xcsClosing];
    xcsSecuring:
      Result := ATo in [xcsConnecting, xcsAuthenticating, xcsResuming,
        xcsClosing];
    xcsAuthenticating:
      Result := ATo in [xcsBinding, xcsResuming, xcsClosing];
    xcsBinding:
      Result := ATo in [xcsOnline, xcsResuming, xcsClosing];
    xcsOnline:
      Result := ATo in [xcsResuming, xcsClosing];
    xcsResuming:
      Result := ATo in [xcsOnline, xcsConnecting, xcsClosing];
    xcsClosing:
      Result := ATo = xcsDisconnected;
    xcsFailed:
      Result := False;
  end;
end;

function NXXMPPIQTypeFromString(const AValue: string): TNXXMPPIQType;
begin
  if AValue = 'get' then
    Result := xitGet
  else if AValue = 'set' then
    Result := xitSet
  else if AValue = 'result' then
    Result := xitResult
  else if AValue = 'error' then
    Result := xitError
  else
    Result := xitUnknown;
end;

function NXXMPPIQTypeName(AValue: TNXXMPPIQType): string;
begin
  case AValue of
    xitGet: Result := 'get';
    xitSet: Result := 'set';
    xitResult: Result := 'result';
    xitError: Result := 'error';
  else
    Result := '';
  end;
end;

end.

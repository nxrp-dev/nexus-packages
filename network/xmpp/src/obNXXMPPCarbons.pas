(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPCarbons;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, DOM, obNXXMPPConfig, obNXXMPPDispatcher, obNXXMPPForwarding,
  obNXXMPPMessage, obNXXMPPModule, obNXXMPPStanza, tpNXXMPPMessageTypes,
  tpNXXMPPTypes, utNXXMPPDOM;

type
  TNXXMPPCarbonsState = (xcsCarbonsDisabled, xcsCarbonsEnabling,
    xcsCarbonsEnabled, xcsCarbonsDisabling, xcsCarbonsUnknown,
    xcsCarbonsFailed);
  TNXXMPPCarbonEvent = procedure(ASender: TObject; ASent: Boolean;
    const ADelay: TNXXMPPDelay; AMessage: TNXXMPPMessage) of object;
  TNXXMPPCarbonsStateEvent = procedure(ASender: TObject;
    AState: TNXXMPPCarbonsState) of object;
  TNXXMPPCarbonDiagnosticEvent = procedure(ASender: TObject;
    const ACondition, ADetail: UTF8String) of object;

  TNXXMPPCarbonsModule = class(TNXXMPPModule)
  private
    FDesiredEnabled: Boolean;
    FMaximumForwardingDepth: Integer;
    FOnCarbon: TNXXMPPCarbonEvent;
    FOnDiagnostic: TNXXMPPCarbonDiagnosticEvent;
    FOnState: TNXXMPPCarbonsStateEvent;
    FOwnBareJID: UTF8String;
    FState: TNXXMPPCarbonsState;
    FServerSupportVerified: Boolean;
    FServerSupportsCarbons: Boolean;
    procedure CompleteDisable(AStanza: TNXXMPPStanza;
      const AError: UTF8String);
    procedure CompleteEnable(AStanza: TNXXMPPStanza;
      const AError: UTF8String);
    procedure SetState(AState: TNXXMPPCarbonsState);
  public
    constructor Create(const AOwnBareJID: UTF8String);
    procedure AddFeatures(AFeatures: TStrings); override;
    procedure Configure(AConfig: TNXXMPPClientConfig); override;
    function Disable: Boolean;
    function Enable(AFreshAttempt: Boolean = False): Boolean;
    procedure SetServerSupport(ASupported: Boolean);
    procedure Lifecycle(ALifecycle: TNXXMPPModuleLifecycle); override;
    procedure PumpLifecycle(ALifecycle: TNXXMPPModuleLifecycle); override;
    procedure PumpStanza(AStanza: TNXXMPPStanza); override;
    procedure RegisterHandlers(ADispatcher: TNXXMPPDispatcher); override;
    property OnCarbon: TNXXMPPCarbonEvent read FOnCarbon write FOnCarbon;
    property OnDiagnostic: TNXXMPPCarbonDiagnosticEvent read FOnDiagnostic
      write FOnDiagnostic;
    property OnState: TNXXMPPCarbonsStateEvent read FOnState write FOnState;
    property State: TNXXMPPCarbonsState read FState;
  end;

implementation

function NXXMPPBareJID(const AJID: UTF8String): UTF8String;
var
  lSeparator: Integer;
begin
  lSeparator := Pos('/', AJID);
  if lSeparator > 0 then
    Result := Copy(AJID, 1, lSeparator - 1)
  else
    Result := AJID;
end;

procedure TNXXMPPCarbonsModule.AddFeatures(AFeatures: TStrings);
begin
  AFeatures.Add('urn:xmpp:carbons:2');
end;

constructor TNXXMPPCarbonsModule.Create(const AOwnBareJID: UTF8String);
begin
  inherited Create;
  FOwnBareJID := AOwnBareJID;
  FState := xcsCarbonsDisabled;
  FMaximumForwardingDepth := 1;
end;

procedure TNXXMPPCarbonsModule.Configure(AConfig: TNXXMPPClientConfig);
begin
  FMaximumForwardingDepth := AConfig.ForwardingMaximumDepth;
end;

procedure TNXXMPPCarbonsModule.RegisterHandlers(
  ADispatcher: TNXXMPPDispatcher);
begin
end;

procedure TNXXMPPCarbonsModule.SetState(AState: TNXXMPPCarbonsState);
begin
  FState := AState;
  if Assigned(FOnState) then
    FOnState(Self, AState);
end;

procedure TNXXMPPCarbonsModule.SetServerSupport(ASupported: Boolean);
begin
  FServerSupportVerified := True;
  FServerSupportsCarbons := ASupported;
end;

function TNXXMPPCarbonsModule.Enable(AFreshAttempt: Boolean): Boolean;
begin
  if not AFreshAttempt and (not FServerSupportVerified or
    not FServerSupportsCarbons) then
  begin
    SetState(xcsCarbonsFailed);
    Exit(False);
  end;
  FDesiredEnabled := True;
  SetState(xcsCarbonsEnabling);
  Result := SubmitIQ(xitSet, '', '',
    '<enable xmlns=''urn:xmpp:carbons:2''/>', @CompleteEnable);
  if not Result then
    SetState(xcsCarbonsFailed);
end;

function TNXXMPPCarbonsModule.Disable: Boolean;
begin
  FDesiredEnabled := False;
  SetState(xcsCarbonsDisabling);
  Result := SubmitIQ(xitSet, '', '',
    '<disable xmlns=''urn:xmpp:carbons:2''/>', @CompleteDisable);
  if not Result then
    SetState(xcsCarbonsFailed);
end;

procedure TNXXMPPCarbonsModule.CompleteEnable(AStanza: TNXXMPPStanza;
  const AError: UTF8String);
begin
  if (AError = '') and Assigned(AStanza) and
    (AStanza.IQType = xitResult) then
    SetState(xcsCarbonsEnabled)
  else
    SetState(xcsCarbonsFailed);
end;

procedure TNXXMPPCarbonsModule.CompleteDisable(AStanza: TNXXMPPStanza;
  const AError: UTF8String);
begin
  if (AError = '') and Assigned(AStanza) and
    (AStanza.IQType = xitResult) then
    SetState(xcsCarbonsDisabled)
  else
    SetState(xcsCarbonsFailed);
end;

procedure TNXXMPPCarbonsModule.Lifecycle(ALifecycle: TNXXMPPModuleLifecycle);
begin
  case ALifecycle of
    xmlTemporaryLoss: if FState = xcsCarbonsEnabled then
      FState := xcsCarbonsUnknown;
    xmlStreamResumed: if FDesiredEnabled and
      (FState = xcsCarbonsUnknown) then FState := xcsCarbonsEnabled;
    xmlNewSession: if FDesiredEnabled then
      begin
        FState := xcsCarbonsEnabling;
        if not SubmitIQ(xitSet, '', '',
          '<enable xmlns=''urn:xmpp:carbons:2''/>', @CompleteEnable) then
          FState := xcsCarbonsFailed;
      end
      else
        FState := xcsCarbonsDisabled;
    xmlPermanentLoss, xmlFinalDisconnect: FState := xcsCarbonsDisabled;
  end;
end;

procedure TNXXMPPCarbonsModule.PumpLifecycle(
  ALifecycle: TNXXMPPModuleLifecycle);
begin
  if Assigned(FOnState) then
    FOnState(Self, FState);
end;

procedure TNXXMPPCarbonsModule.PumpStanza(AStanza: TNXXMPPStanza);
var
  lContext: TNXXMPPMessageDeliveryContext;
  lForwarded: TNXXMPPForwarded;
  lForwardedElement: TDOMElement;
  lForwardedCount: Integer;
  lChild: TDOMElement;
  lSent: Boolean;
  lWrapper: TDOMElement;
begin
  if not Assigned(AStanza) or (AStanza.Kind <> xskMessage) then
    Exit;
  if (AStanza.FromJID <> '') and (AStanza.FromJID <> FOwnBareJID) then
  begin
    if Assigned(FOnDiagnostic) then
      FOnDiagnostic(Self, 'carbon-authority',
        'The outer Carbon sender is not the local bare JID.');
    Exit;
  end;
  lSent := True;
  lWrapper := NXXMPPFindChild(AStanza.Root, 'urn:xmpp:carbons:2', 'sent');
  if Assigned(lWrapper) and Assigned(NXXMPPFindChild(AStanza.Root,
    'urn:xmpp:carbons:2', 'received')) then
  begin
    if Assigned(FOnDiagnostic) then
      FOnDiagnostic(Self, 'carbon-wrapper',
        'A Carbon message contains both sent and received wrappers.');
    Exit;
  end;
  if not Assigned(lWrapper) then
  begin
    lSent := False;
    lWrapper := NXXMPPFindChild(AStanza.Root, 'urn:xmpp:carbons:2',
      'received');
  end;
  if not Assigned(lWrapper) then
    Exit;
  lForwardedElement := nil;
  lForwardedCount := 0;
  lChild := NXXMPPFirstChildElement(lWrapper);
  while Assigned(lChild) do
  begin
    if NXXMPPElementMatches(lChild, 'urn:xmpp:forward:0', 'forwarded') then
    begin
      Inc(lForwardedCount);
      lForwardedElement := lChild;
    end;
    lChild := NXXMPPNextSiblingElement(lChild);
  end;
  if lForwardedCount <> 1 then
  begin
    if Assigned(FOnDiagnostic) then
      FOnDiagnostic(Self, 'carbon-forward-count',
        'A Carbon wrapper must contain exactly one forwarded stanza.');
    Exit;
  end;
  if lSent then
    lContext := xmdcCarbonSent
  else
    lContext := xmdcCarbonReceived;
  lForwarded := TNXXMPPForwarding.Decode(lForwardedElement, lContext,
    FMaximumForwardingDepth);
  try
    if not lForwarded.Valid then
    begin
      if Assigned(FOnDiagnostic) then
        FOnDiagnostic(Self, 'carbon-forward-invalid',
          lForwarded.ValidationError);
      Exit;
    end;
    if (lSent and (NXXMPPBareJID(lForwarded.Message.FromJID) <>
      FOwnBareJID)) or (not lSent and
      (NXXMPPBareJID(lForwarded.Message.ToJID) <> FOwnBareJID)) then
    begin
      if Assigned(FOnDiagnostic) then
        FOnDiagnostic(Self, 'carbon-direction-authority',
          'The forwarded message address does not match Carbon direction.');
      Exit;
    end;
    if Assigned(FOnCarbon) then
      FOnCarbon(Self, lSent, lForwarded.Delay, lForwarded.Message);
  finally
    lForwarded.Free;
  end;
end;

end.

(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPModule;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, obNXXMPPCommand, obNXXMPPConfig, obNXXMPPDispatcher, obNXXMPPError,
  obNXXMPPRequestManager, obNXXMPPStanza, tpNXXMPPTypes;

type
  TNXXMPPModuleSender = procedure(const AXML: UTF8String;
    AReplayable: Boolean) of object;
  TNXXMPPModuleSubmitter = function(AModule: TObject;
    AOperation: TNXXMPPModuleOperation): Boolean of object;
  TNXXMPPModuleIQSubmitter = function(AType: TNXXMPPIQType;
    const AToJID, AExpectedFrom, APayload: UTF8String;
    AHandler: TNXXMPPIQCompletionHandler; ATimeoutMS: Cardinal): Boolean
    of object;

  TNXXMPPModule = class
  private
    FSender: TNXXMPPModuleSender;
    FSubmitter: TNXXMPPModuleSubmitter;
    FIQSubmitter: TNXXMPPModuleIQSubmitter;
  protected
    procedure Send(const AXML: UTF8String;
      AReplayPolicy: TNXXMPPReplayPolicy = xrpNever);
    function Submit(AOperation: TNXXMPPModuleOperation): Boolean;
    function SubmitIQ(AType: TNXXMPPIQType; const AToJID, AExpectedFrom,
      APayload: UTF8String; AHandler: TNXXMPPIQCompletionHandler;
      ATimeoutMS: Cardinal = cNXXMPPDefaultTimeoutMS): Boolean;
  public
    procedure AddFeatures(AFeatures: TStrings); virtual;
    procedure Configure(AConfig: TNXXMPPClientConfig); virtual;
    procedure Lifecycle(ALifecycle: TNXXMPPModuleLifecycle); virtual;
    procedure ProcessCommand(AOperation: TNXXMPPModuleOperation); virtual;
    procedure PumpStanza(AStanza: TNXXMPPStanza); virtual;
    procedure PumpLifecycle(ALifecycle: TNXXMPPModuleLifecycle); virtual;
    procedure RegisterHandlers(ADispatcher: TNXXMPPDispatcher); virtual; abstract;
    property Sender: TNXXMPPModuleSender read FSender write FSender;
    property Submitter: TNXXMPPModuleSubmitter read FSubmitter write FSubmitter;
    property IQSubmitter: TNXXMPPModuleIQSubmitter read FIQSubmitter
      write FIQSubmitter;
  end;

implementation

procedure TNXXMPPModule.AddFeatures(AFeatures: TStrings);
begin
end;

procedure TNXXMPPModule.Configure(AConfig: TNXXMPPClientConfig);
begin
end;

procedure TNXXMPPModule.PumpStanza(AStanza: TNXXMPPStanza);
begin
end;

procedure TNXXMPPModule.PumpLifecycle(ALifecycle: TNXXMPPModuleLifecycle);
begin
end;

procedure TNXXMPPModule.Lifecycle(ALifecycle: TNXXMPPModuleLifecycle);
begin
end;

procedure TNXXMPPModule.ProcessCommand(AOperation: TNXXMPPModuleOperation);
begin
  raise ENXXMPPError.Create(xesProtocol, 'unsupported-module-command',
    'The XMPP module does not support this command.');
end;

procedure TNXXMPPModule.Send(const AXML: UTF8String;
  AReplayPolicy: TNXXMPPReplayPolicy);
begin
  if not Assigned(FSender) then
    raise ENXXMPPError.Create(xesProtocol, 'module-not-connected',
      'The XMPP module is not connected to a stanza sender.');
  FSender(AXML, AReplayPolicy = xrpStreamManaged);
end;

function TNXXMPPModule.Submit(AOperation: TNXXMPPModuleOperation): Boolean;
begin
  if not Assigned(AOperation) then
    Exit(False);
  if not Assigned(FSubmitter) then
  begin
    AOperation.Free;
    Exit(False);
  end;
  Result := FSubmitter(Self, AOperation);
end;

function TNXXMPPModule.SubmitIQ(AType: TNXXMPPIQType; const AToJID,
  AExpectedFrom, APayload: UTF8String; AHandler: TNXXMPPIQCompletionHandler;
  ATimeoutMS: Cardinal): Boolean;
begin
  Result := Assigned(FIQSubmitter) and FIQSubmitter(AType, AToJID,
    AExpectedFrom, APayload, AHandler, ATimeoutMS);
end;

end.

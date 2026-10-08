(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPCommand;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, obNXXMPPRequestManager, tpNXXMPPTypes;

type
  TNXXMPPModuleOperation = class
  end;

  TNXXMPPCommandKind = (xckRawXML, xckIQ, xckModule, xckDisconnect);

  TNXXMPPCommand = class
  private
    FExpectedFrom: UTF8String;
    FHandler: TNXXMPPIQCompletionHandler;
    FIQType: TNXXMPPIQType;
    FKind: TNXXMPPCommandKind;
    FModule: TObject;
    FModuleOperation: TNXXMPPModuleOperation;
    FPayload: UTF8String;
    FReplayPolicy: TNXXMPPReplayPolicy;
    FTimeoutMS: Cardinal;
    FToJID: UTF8String;
    FXML: UTF8String;
  public
    class function CreateRaw(const AXML: UTF8String;
      AReplayPolicy: TNXXMPPReplayPolicy): TNXXMPPCommand;
    class function CreateIQ(AType: TNXXMPPIQType; const AToJID,
      AExpectedFrom, APayload: UTF8String; ATimeoutMS: Cardinal;
      AHandler: TNXXMPPIQCompletionHandler): TNXXMPPCommand;
    class function CreateModule(AModule: TObject;
      AOperation: TNXXMPPModuleOperation): TNXXMPPCommand;
    class function CreateDisconnect: TNXXMPPCommand;
    destructor Destroy; override;
    property ExpectedFrom: UTF8String read FExpectedFrom;
    property Handler: TNXXMPPIQCompletionHandler read FHandler;
    property IQType: TNXXMPPIQType read FIQType;
    property Kind: TNXXMPPCommandKind read FKind;
    property Module: TObject read FModule;
    property ModuleOperation: TNXXMPPModuleOperation read FModuleOperation;
    property Payload: UTF8String read FPayload;
    property TimeoutMS: Cardinal read FTimeoutMS;
    property ToJID: UTF8String read FToJID;
    property ReplayPolicy: TNXXMPPReplayPolicy read FReplayPolicy;
    property XML: UTF8String read FXML;
  end;

implementation

class function TNXXMPPCommand.CreateRaw(const AXML: UTF8String;
  AReplayPolicy: TNXXMPPReplayPolicy): TNXXMPPCommand;
begin
  Result := TNXXMPPCommand.Create;
  Result.FKind := xckRawXML;
  Result.FXML := AXML;
  Result.FReplayPolicy := AReplayPolicy;
end;

class function TNXXMPPCommand.CreateIQ(AType: TNXXMPPIQType;
  const AToJID, AExpectedFrom, APayload: UTF8String; ATimeoutMS: Cardinal;
  AHandler: TNXXMPPIQCompletionHandler): TNXXMPPCommand;
begin
  Result := TNXXMPPCommand.Create;
  Result.FKind := xckIQ;
  Result.FIQType := AType;
  Result.FToJID := AToJID;
  Result.FExpectedFrom := AExpectedFrom;
  Result.FPayload := APayload;
  Result.FTimeoutMS := ATimeoutMS;
  Result.FHandler := AHandler;
end;

class function TNXXMPPCommand.CreateModule(AModule: TObject;
  AOperation: TNXXMPPModuleOperation): TNXXMPPCommand;
begin
  Result := TNXXMPPCommand.Create;
  Result.FKind := xckModule;
  Result.FModule := AModule;
  Result.FModuleOperation := AOperation;
end;

class function TNXXMPPCommand.CreateDisconnect: TNXXMPPCommand;
begin
  Result := TNXXMPPCommand.Create;
  Result.FKind := xckDisconnect;
end;

destructor TNXXMPPCommand.Destroy;
begin
  FModuleOperation.Free;
  inherited Destroy;
end;

end.

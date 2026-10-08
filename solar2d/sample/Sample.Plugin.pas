(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit Sample.Plugin;

{$mode objfpc}{$H+}

interface

uses
  Solar2D.Plugin;

type
  TAddLink = function(A, B: Integer): Integer of object;
  TGreetingLink = function(const AWho: string): string of object;
  TResetLink = procedure of object;
  TPulseLink = procedure(AValue: Integer) of object;
  TBroadcastLink = procedure(AValue: Integer) of object;

  TSamplePlugin = class(TSolarPlugin)
  private
    FAdd: TAddLink;
    FBroadcast: TBroadcastLink;
    FGreeting: TGreetingLink;
    FName: string;
    FPulse: TPulseLink;
    FReset: TResetLink;
    FVolume: Double;
    function LinkAdd(A, B: Integer): Integer;
    procedure LinkBroadcast(AValue: Integer);
    function LinkGreeting(const AWho: string): string;
    procedure LinkPulse(AValue: Integer);
    procedure LinkReset;
  protected
    procedure HandleEvent(AEvent: TSolarEvent); override;
  public
    constructor Create; override;
  published
    property Add: TAddLink read FAdd;
    property Broadcast: TBroadcastLink read FBroadcast;
    property Greeting: TGreetingLink read FGreeting;
    property Name: string read FName write FName;
    property Pulse: TPulseLink read FPulse;
    property Reset: TResetLink read FReset;
    property Volume: Double read FVolume write FVolume;
  end;

implementation

constructor TSamplePlugin.Create;
begin
  inherited Create;
  FAdd := @LinkAdd;
  FBroadcast := @LinkBroadcast;
  FGreeting := @LinkGreeting;
  FPulse := @LinkPulse;
  FReset := @LinkReset;
  LinkReset;
end;

function TSamplePlugin.LinkAdd(A, B: Integer): Integer;
begin
  Result := A + B;
end;

function TSamplePlugin.LinkGreeting(const AWho: string): string;
begin
  Result := 'Hello, ' + AWho + ' from Pascal';
end;

procedure TSamplePlugin.LinkReset;
begin
  FName := '';
  FVolume := 1.0;
end;

procedure TSamplePlugin.LinkPulse(AValue: Integer);
begin
  DispatchEvent(
    'pulse',
    [
      SolarEventField('value', AValue),
      SolarEventField('message', 'Pulse from Pascal')
    ]
  );
end;

procedure TSamplePlugin.LinkBroadcast(AValue: Integer);
begin
  DispatchRuntimeEvent(
    'samplePulse',
    [SolarEventField('value', AValue)]
  );
end;

procedure TSamplePlugin.HandleEvent(AEvent: TSolarEvent);
begin
  inherited HandleEvent(AEvent);
  if AEvent.Name = 'setVolume' then
    FVolume := AEvent.GetNumber('value', FVolume);
end;

end.

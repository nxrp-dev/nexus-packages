(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

program TestPublishedRTTI;

{$mode objfpc}{$H+}

uses
  Classes,
  SysUtils,
  TypInfo,
  Rtti
{$if not (defined(CPUX86_64) and defined(WIN64)) or defined(NX_TEST_FFI_MANAGER)}
  , ffi.manager
{$endif};

type
  TAddLink = function(A, B: Integer): Integer of object;
  TMultiplyLink = function(A, B: Double): Double of object;
  TEchoLink = function(const AValue: AnsiString): AnsiString of object;

  TProbe = class(TPersistent)
  private
    FAdd: TAddLink;
    FMultiply: TMultiplyLink;
    FEcho: TEchoLink;
    FName: string;
    FOnChanged: TNotifyEvent;
    function LinkAdd(A, B: Integer): Integer;
    function LinkMultiply(A, B: Double): Double;
    function LinkEcho(const AValue: AnsiString): AnsiString;
    procedure DoOnChanged(ASender: TObject);
  public
    constructor Create;
    function Hidden(AValue: Integer): Integer;
  published
    property Add: TAddLink read FAdd;
    property Multiply: TMultiplyLink read FMultiply;
    property Echo: TEchoLink read FEcho;
    property Name: string read FName write FName;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

constructor TProbe.Create;
begin
  inherited Create;
  FAdd := @LinkAdd;
  FMultiply := @LinkMultiply;
  FEcho := @LinkEcho;
end;

function TProbe.Hidden(AValue: Integer): Integer;
begin
  Result := AValue;
end;

function TProbe.LinkAdd(A, B: Integer): Integer;
begin
  Result := A + B;
end;

function TProbe.LinkMultiply(A, B: Double): Double;
begin
  Result := A * B;
end;

function TProbe.LinkEcho(const AValue: AnsiString): AnsiString;
begin
  Result := AValue;
end;

procedure TProbe.DoOnChanged(ASender: TObject);
begin
end;

var
  Obj: TProbe;
  Context: TRttiContext;
  RttiType: TRttiType;
  Prop: TRttiProperty;
  MethodType: TRttiMethodType;
  Args: TValueArray;
  BoundMethod: TMethod;
  Callable: TValue;
  Value: TValue;

begin
  Obj := TProbe.Create;
  Context := TRttiContext.Create;
  try
    RttiType := Context.GetType(Obj.ClassInfo);

    Prop := RttiType.GetProperty('Add');
    if Prop = nil then
      raise Exception.Create('Published Add link property RTTI missing');
    if not (Prop.PropertyType is TRttiMethodType) then
      raise Exception.Create('Published Add link does not expose method-type RTTI');
    if not Prop.IsReadable then
      raise Exception.Create('Published Add link must be readable');
    if Prop.IsWritable then
      raise Exception.Create('Published Add link must be read-only');

    SetLength(Args, 2);
    Args[0] := TValue.FromOrdinal(TypeInfo(Integer), 20);
    Args[1] := TValue.FromOrdinal(TypeInfo(Integer), 22);
    MethodType := TRttiMethodType(Prop.PropertyType);
    BoundMethod := GetMethodProp(Obj, PPropInfo(Prop.Handle));
    TValue.Make(@BoundMethod, MethodType.Handle, Callable);
    Value := MethodType.Invoke(Callable, Args);
    if Value.AsOrdinal <> 42 then
      raise Exception.Create('RTTI method-property invoke failed');

    Prop := RttiType.GetProperty('Multiply');
    if Prop = nil then
      raise Exception.Create('Published Multiply link property RTTI missing');
    MethodType := TRttiMethodType(Prop.PropertyType);
    BoundMethod := GetMethodProp(Obj, PPropInfo(Prop.Handle));
    TValue.Make(@BoundMethod, MethodType.Handle, Callable);
    Args[0] := TValue.specialize From<Double>(2.5);
    Args[1] := TValue.specialize From<Double>(4.0);
    Value := MethodType.Invoke(Callable, Args);
    if Abs(Value.AsExtended - 10.0) > 0.00001 then
      raise Exception.Create('RTTI floating-point link invoke failed');

    Prop := RttiType.GetProperty('Echo');
    if Prop = nil then
      raise Exception.Create('Published Echo link property RTTI missing');
    MethodType := TRttiMethodType(Prop.PropertyType);
    BoundMethod := GetMethodProp(Obj, PPropInfo(Prop.Handle));
    TValue.Make(@BoundMethod, MethodType.Handle, Callable);
    SetLength(Args, 1);
    Args[0] := TValue.specialize From<AnsiString>('Nexus');
    Value := MethodType.Invoke(Callable, Args);
    if Value.AsAnsiString <> 'Nexus' then
      raise Exception.Create('RTTI managed-string link invoke failed');

    Prop := RttiType.GetProperty('Name');
    if Prop = nil then
      raise Exception.Create('Published Name property RTTI missing');

    Value := TValue.specialize From<string>('Nexus');
    Prop.SetValue(Obj, Value);
    if Obj.Name <> 'Nexus' then
      raise Exception.Create('RTTI property set failed');

    Obj.OnChanged := @Obj.DoOnChanged;
    Prop := RttiType.GetProperty('OnChanged');
    if Prop = nil then
      raise Exception.Create('Published OnChanged event property RTTI missing');
    if not (Prop.PropertyType is TRttiMethodType) then
      raise Exception.Create('Published OnChanged event does not expose method-type RTTI');
    if not Prop.IsWritable then
      raise Exception.Create('Published events must remain writable');

    WriteLn('RTTI bridge prerequisite test passed');
  finally
    Context.Free;
    Obj.Free;
  end;
end.

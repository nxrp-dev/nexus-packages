(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit Lua.Plugin;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  TypInfo,
  Rtti,
  Lua51;

type
  ELuaPlugin = class(Exception);

  TLuaPlugin = class;
  TLuaPluginClass = class of TLuaPlugin;

  TLuaPlugin = class(TPersistent)
  private
    FLuaState: Plua_State;
    FRttiContext: TRttiContext;
    FRttiType: TRttiType;
    FLinks: TStringList;
    FProperties: TStringList;
    procedure BuildPublishedMemberCache;
    function FindPublishedLink(const AName: string): TRttiProperty;
    function FindPublishedProperty(const AName: string): TRttiProperty;
    class function DoLuaNew(L: Plua_State): Integer; cdecl; static;
    class function DoLuaIndex(L: Plua_State): Integer; cdecl; static;
    class function DoLuaNewIndex(L: Plua_State): Integer; cdecl; static;
    class function DoLuaLinkDispatch(L: Plua_State): Integer; cdecl; static;
    class function DoLuaDestroy(L: Plua_State): Integer; cdecl; static;
    class function LuaIndex(L: Plua_State): Integer; cdecl; static;
    class function LuaNewIndex(L: Plua_State): Integer; cdecl; static;
    class function LuaLinkDispatch(L: Plua_State): Integer; cdecl; static;
    class function LuaDestroy(L: Plua_State): Integer; cdecl; static;
    class procedure EnsureMetatable(L: Plua_State); static;
  protected
    function ResolveLuaState(L: Plua_State): Plua_State; virtual;
    procedure PushLuaObject(L: Plua_State); virtual;
    procedure LuaObjectPushed(L: Plua_State; AIndex: Integer); virtual;
    procedure LuaObjectDestroying(L: Plua_State; AIndex: Integer); virtual;
    function TryPushLuaMember(L: Plua_State; const AName: UTF8String): Boolean; virtual;
    function LuaToValue(L: Plua_State; AIndex: Integer; ARttiType: TRttiType): TValue; virtual;
    procedure ValueToLua(L: Plua_State; const AValue: TValue); virtual;

    class function CheckObject(L: Plua_State; AIndex: Integer): TLuaPlugin; static;
    class function BoundObject(L: Plua_State): TLuaPlugin; static;
    class function BoundArgumentBase(L: Plua_State): Integer; static;
    class procedure PushBoundClosure(L: Plua_State; AObjectIndex: Integer; ACallback: lua_CFunction); static;
    class function LuaString(L: Plua_State; AIndex: Integer): UTF8String; static;
    class function LuaTypeName(L: Plua_State; AIndex: Integer): string; static;
    class procedure RequireType(L: Plua_State; AIndex, AType: Integer; const AWhat: string); static;
    class procedure RaiseBridgeError(const AMessage: string); static;
    class function CaptureLuaCallback(L: Plua_State; ACallback: lua_CFunction): Integer; static;
    class function RunLuaCallback(L: Plua_State; ACallback: lua_CFunction): Integer; static;

    property LuaState: Plua_State read FLuaState;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    class function LuaNew(L: Plua_State): Integer; cdecl; static;
  end;

implementation

{$if not (defined(CPUX86_64) and defined(WIN64))}
uses
  ffi.manager;
{$endif}

type
  PLuaObjectSlot = ^TLuaObjectSlot;
  TLuaObjectSlot = record
    Instance: TLuaPlugin;
  end;

const
  CObjectMetatable: PChar = 'Nexus.Lua.Plugin.Object';
  CLuaCallbackError = -1;

constructor TLuaPlugin.Create;
begin
  inherited Create;

  FLinks := TStringList.Create;
  FLinks.Sorted := True;
  FLinks.CaseSensitive := True;
  FLinks.Duplicates := dupIgnore;

  FProperties := TStringList.Create;
  FProperties.Sorted := True;
  FProperties.CaseSensitive := True;
  FProperties.Duplicates := dupIgnore;

  FRttiContext := TRttiContext.Create;
  FRttiType := FRttiContext.GetType(ClassInfo);
  BuildPublishedMemberCache;
end;

destructor TLuaPlugin.Destroy;
begin
  FreeAndNil(FProperties);
  FreeAndNil(FLinks);
  FRttiType := nil;
  FRttiContext.Free;
  inherited Destroy;
end;

procedure TLuaPlugin.BuildPublishedMemberCache;
var
  lProperty: TRttiProperty;
  lProperties: specialize TArray<TRttiProperty>;
  lIndex: Integer;
begin
  if not Assigned(FRttiType) then
    Exit;

  lProperties := FRttiType.GetProperties;
  for lIndex := 0 to High(lProperties) do
  begin
    lProperty := lProperties[lIndex];
    if lProperty.Visibility <> mvPublished then
      Continue;

    if lProperty.PropertyType is TRttiMethodType then
    begin
      if lProperty.IsReadable and not lProperty.IsWritable then
        FLinks.AddObject(lProperty.Name, lProperty);
    end
    else
      FProperties.AddObject(lProperty.Name, lProperty);
  end;
end;

function TLuaPlugin.FindPublishedLink(const AName: string): TRttiProperty;
var
  lIndex: Integer;
begin
  Result := nil;
  lIndex := FLinks.IndexOf(AName);
  if lIndex >= 0 then
    Result := TRttiProperty(FLinks.Objects[lIndex]);
end;

function TLuaPlugin.FindPublishedProperty(const AName: string): TRttiProperty;
var
  Index: Integer;
begin
  Result := nil;
  Index := FProperties.IndexOf(AName);
  if Index >= 0 then
    Result := TRttiProperty(FProperties.Objects[Index]);
end;

function TLuaPlugin.ResolveLuaState(L: Plua_State): Plua_State;
begin
  Result := L;
end;

procedure TLuaPlugin.LuaObjectPushed(L: Plua_State; AIndex: Integer);
begin
end;

procedure TLuaPlugin.LuaObjectDestroying(L: Plua_State; AIndex: Integer);
begin
end;

function TLuaPlugin.TryPushLuaMember(L: Plua_State; const AName: UTF8String): Boolean;
begin
  Result := False;
end;

class function TLuaPlugin.LuaString(L: Plua_State; AIndex: Integer): UTF8String;
var
  Len: SizeUInt;
  P: PChar;
begin
  Len := 0;
  P := lua_tolstring(L, AIndex, @Len);
  if P = nil then
    Exit('');
  SetString(Result, P, Len);
end;

class function TLuaPlugin.LuaTypeName(L: Plua_State; AIndex: Integer): string;
var
  P: PChar;
begin
  P := lua_typename(L, lua_type(L, AIndex));
  if Assigned(P) then
    Result := string(P)
  else
    Result := 'unknown';
end;

class procedure TLuaPlugin.RequireType(
  L: Plua_State;
  AIndex,
  AType: Integer;
  const AWhat: string
);
begin
  if lua_type(L, AIndex) <> AType then
    RaiseBridgeError(
      Format('%s must be %s, got %s', [AWhat, string(lua_typename(L, AType)), LuaTypeName(L, AIndex)])
    );
end;

class procedure TLuaPlugin.RaiseBridgeError(const AMessage: string);
begin
  raise ELuaPlugin.Create(AMessage);
end;

class function TLuaPlugin.CaptureLuaCallback(
  L: Plua_State;
  ACallback: lua_CFunction
): Integer;
var
  lMessage: UTF8String;
begin
  try
    Result := ACallback(L);
  except
    on lException: Exception do
    begin
      lMessage := UTF8Encode(lException.Message);
      lua_pushlstring(L, PChar(lMessage), Length(lMessage));
      Result := CLuaCallbackError;
    end;
  end;

end;

class function TLuaPlugin.RunLuaCallback(
  L: Plua_State;
  ACallback: lua_CFunction
): Integer;
begin
  Result := CaptureLuaCallback(L, ACallback);
  if Result = CLuaCallbackError then
    Result := lua_error(L);
end;

class procedure TLuaPlugin.EnsureMetatable(L: Plua_State);
var
  MetatableName: UTF8String;
begin
  if luaL_newmetatable(L, CObjectMetatable) <> 0 then
  begin
    lua_pushcfunction(L, @LuaIndex);
    lua_setfield(L, -2, '__index');

    lua_pushcfunction(L, @LuaNewIndex);
    lua_setfield(L, -2, '__newindex');

    lua_pushcfunction(L, @LuaDestroy);
    lua_setfield(L, -2, '__gc');

    MetatableName := 'Nexus Lua object';
    lua_pushlstring(L, PChar(MetatableName), Length(MetatableName));
    lua_setfield(L, -2, '__metatable');
  end;
  lua_pop(L, 1);
end;

procedure TLuaPlugin.PushLuaObject(L: Plua_State);
var
  Slot: PLuaObjectSlot;
begin
  EnsureMetatable(L);
  Slot := PLuaObjectSlot(lua_newuserdata(L, SizeOf(TLuaObjectSlot)));
  Slot^.Instance := nil;
  luaL_getmetatable(L, CObjectMetatable);
  lua_setmetatable(L, -2);
  Slot^.Instance := Self;
  try
    LuaObjectPushed(L, -1);
  except
    Slot^.Instance := nil;
    raise;
  end;
end;

class function TLuaPlugin.CheckObject(L: Plua_State; AIndex: Integer): TLuaPlugin;
var
  Slot: PLuaObjectSlot;
begin
  Slot := PLuaObjectSlot(luaL_checkudata(L, AIndex, CObjectMetatable));
  if (Slot = nil) or (Slot^.Instance = nil) then
    RaiseBridgeError('Pascal object has already been destroyed');
  Result := Slot^.Instance;
end;

class function TLuaPlugin.BoundObject(L: Plua_State): TLuaPlugin;
begin
  Result := CheckObject(L, lua_upvalueindex(1));
end;

class function TLuaPlugin.BoundArgumentBase(L: Plua_State): Integer;
begin
  if (lua_gettop(L) > 0) and
    (lua_rawequal(L, 1, lua_upvalueindex(1)) <> 0) then
    Result := 2
  else
    Result := 1;
end;

class procedure TLuaPlugin.PushBoundClosure(
  L: Plua_State;
  AObjectIndex: Integer;
  ACallback: lua_CFunction
);
begin
  lua_pushvalue(L, AObjectIndex);
  lua_pushcclosure(L, ACallback, 1);
end;

class function TLuaPlugin.LuaNew(L: Plua_State): Integer; cdecl;
begin
  Result := RunLuaCallback(L, @DoLuaNew);
end;

class function TLuaPlugin.DoLuaNew(L: Plua_State): Integer; cdecl;
var
  PluginClass: TLuaPluginClass;
  Obj: TLuaPlugin;
begin
  Result := 0;
  Obj := nil;
  try
    PluginClass := TLuaPluginClass(lua_touserdata(L, lua_upvalueindex(1)));
    if PluginClass = nil then
      RaiseBridgeError('Lua plugin class context is missing');

    Obj := PluginClass.Create;
    Obj.FLuaState := Obj.ResolveLuaState(L);
    if Obj.FLuaState = nil then
      Obj.FLuaState := L;
    Obj.PushLuaObject(L);
    Obj := nil;
    Result := 1;
  except
    Obj.Free;
    raise;
  end;
end;

class function TLuaPlugin.LuaIndex(L: Plua_State): Integer; cdecl;
begin
  Result := RunLuaCallback(L, @DoLuaIndex);
end;

class function TLuaPlugin.DoLuaIndex(L: Plua_State): Integer; cdecl;
var
  Obj: TLuaPlugin;
  Name: UTF8String;
  Prop: TRttiProperty;
  Link: TRttiProperty;
begin
  Result := 0;
  Obj := CheckObject(L, 1);
  if lua_type(L, 2) <> LUA_TSTRING then
  begin
    lua_pushnil(L);
    Exit(1);
  end;

  Name := LuaString(L, 2);

  if Obj.TryPushLuaMember(L, Name) then
    Exit(1);

  Prop := Obj.FindPublishedProperty(string(Name));
  if Assigned(Prop) then
  begin
    if not Prop.IsReadable then
      RaiseBridgeError('Property "' + string(Name) + '" is write-only');
    Obj.ValueToLua(L, Prop.GetValue(Obj));
    Exit(1);
  end;

  Link := Obj.FindPublishedLink(string(Name));
  if Assigned(Link) then
  begin
    lua_pushvalue(L, 1);
    lua_pushlstring(L, PChar(Name), Length(Name));
    lua_pushcclosure(L, @LuaLinkDispatch, 2);
    Exit(1);
  end;

  lua_pushnil(L);
  Result := 1;
end;

class function TLuaPlugin.LuaNewIndex(L: Plua_State): Integer; cdecl;
begin
  Result := RunLuaCallback(L, @DoLuaNewIndex);
end;

class function TLuaPlugin.DoLuaNewIndex(L: Plua_State): Integer; cdecl;
var
  Obj: TLuaPlugin;
  Name: UTF8String;
  Prop: TRttiProperty;
  Value: TValue;
begin
  Result := 0;
  Obj := CheckObject(L, 1);
  RequireType(L, 2, LUA_TSTRING, 'Property name');
  Name := LuaString(L, 2);

  Prop := Obj.FindPublishedProperty(string(Name));
  if not Assigned(Prop) then
    RaiseBridgeError('Unknown published property "' + string(Name) + '"');
  if not Prop.IsWritable then
    RaiseBridgeError('Property "' + string(Name) + '" is read-only');

  Value := Obj.LuaToValue(L, 3, Prop.PropertyType);
  Prop.SetValue(Obj, Value);
end;

class function TLuaPlugin.LuaLinkDispatch(L: Plua_State): Integer; cdecl;
begin
  Result := RunLuaCallback(L, @DoLuaLinkDispatch);
end;

class function TLuaPlugin.DoLuaLinkDispatch(L: Plua_State): Integer; cdecl;
var
  Obj: TLuaPlugin;
  lLinkName: UTF8String;
  lLink: TRttiProperty;
  lLinkType: TRttiMethodType;
  lBoundLink: TMethod;
  lCallable: TValue;
  Params: specialize TArray<TRttiParameter>;
  Args: TValueArray;
  ReturnValue: TValue;
  I: Integer;
  ArgBase: Integer;
  ArgCount: Integer;
begin
  Result := 0;
  Obj := CheckObject(L, lua_upvalueindex(1));
  lLinkName := LuaString(L, lua_upvalueindex(2));
  lLink := Obj.FindPublishedLink(string(lLinkName));
  if not Assigned(lLink) then
    RaiseBridgeError('Unknown published link "' + string(lLinkName) + '"');

  lLinkType := TRttiMethodType(lLink.PropertyType);
  lBoundLink := GetMethodProp(Obj, PPropInfo(lLink.Handle));
  if not Assigned(lBoundLink.Code) then
    RaiseBridgeError('Published link "' + string(lLinkName) + '" is not assigned');
  TValue.Make(@lBoundLink, lLinkType.Handle, lCallable);

  Params := lLinkType.GetParameters;
  ArgBase := BoundArgumentBase(L);
  ArgCount := lua_gettop(L) - ArgBase + 1;
  if ArgCount < 0 then
    ArgCount := 0;

  if ArgCount <> Length(Params) then
    RaiseBridgeError(
      Format(
        'Link "%s" expects %d argument(s), got %d',
        [string(lLinkName), Length(Params), ArgCount]
      )
    );

  SetLength(Args, Length(Params));
  for I := 0 to High(Params) do
  begin
    if (pfVar in Params[I].Flags) or (pfOut in Params[I].Flags) or
      (pfConstRef in Params[I].Flags) then
      RaiseBridgeError(
        Format(
          'Link "%s" parameter "%s" uses var/out/constref, which the Lua bridge does not support',
          [string(lLinkName), Params[I].Name]
        )
      );
    Args[I] := Obj.LuaToValue(L, ArgBase + I, Params[I].ParamType);
  end;

  ReturnValue := lLinkType.Invoke(lCallable, Args);
  if Assigned(lLinkType.ReturnType) then
  begin
    Obj.ValueToLua(L, ReturnValue);
    Result := 1;
  end;
end;

class function TLuaPlugin.LuaDestroy(L: Plua_State): Integer; cdecl;
begin
  Result := RunLuaCallback(L, @DoLuaDestroy);
end;

class function TLuaPlugin.DoLuaDestroy(L: Plua_State): Integer; cdecl;
var
  Slot: PLuaObjectSlot;
  Obj: TLuaPlugin;
begin
  Result := 0;
  Slot := PLuaObjectSlot(lua_touserdata(L, 1));
  if (Slot = nil) or (Slot^.Instance = nil) then
    Exit;

  Obj := Slot^.Instance;
  Slot^.Instance := nil;
  try
    Obj.LuaObjectDestroying(L, 1);
  finally
    Obj.Free;
  end;
end;

function TLuaPlugin.LuaToValue(
  L: Plua_State;
  AIndex: Integer;
  ARttiType: TRttiType
): TValue;
var
  Ordinal: Int64;
  EnumOrdinal: Int64;
  S: UTF8String;
  A: AnsiString;
  U: UnicodeString;
  W: WideString;
  SS: ShortString;
  FSingle: Single;
  FDouble: Double;
  FExtended: Extended;
  FCurrency: Currency;
  FComp: Comp;
  BoolValue: Boolean;
  Ch: Char;
  WCh: WideChar;
begin
  if not Assigned(ARttiType) then
    RaiseBridgeError('Parameter type RTTI is unavailable');

  case ARttiType.TypeKind of
    tkBool:
      begin
        RequireType(L, AIndex, LUA_TBOOLEAN, 'Boolean value');
        BoolValue := lua_toboolean(L, AIndex) <> 0;
        Result := TValue.FromOrdinal(ARttiType.Handle, Ord(BoolValue));
      end;

    tkInteger, tkInt64, tkQWord:
      begin
        RequireType(L, AIndex, LUA_TNUMBER, 'Numeric value');
        Ordinal := lua_tointeger(L, AIndex);
        Result := TValue.FromOrdinal(ARttiType.Handle, Ordinal);
      end;

    tkEnumeration:
      begin
        if lua_type(L, AIndex) = LUA_TSTRING then
        begin
          S := LuaString(L, AIndex);
          EnumOrdinal := GetEnumValue(ARttiType.Handle, string(S));
          if EnumOrdinal < 0 then
            RaiseBridgeError(
              Format('Unknown %s value "%s"', [ARttiType.Name, string(S)])
            );
          Result := TValue.FromOrdinal(ARttiType.Handle, EnumOrdinal);
        end
        else
        begin
          RequireType(L, AIndex, LUA_TNUMBER, 'Enumeration value');
          Result := TValue.FromOrdinal(ARttiType.Handle, lua_tointeger(L, AIndex));
        end;
      end;

    tkChar, tkUChar:
      begin
        RequireType(L, AIndex, LUA_TSTRING, 'Character value');
        S := LuaString(L, AIndex);
        if Length(S) <> 1 then
          RaiseBridgeError('Character value must contain exactly one byte');
        Ch := Char(S[1]);
        Result := TValue.FromOrdinal(ARttiType.Handle, Ord(Ch));
      end;

    tkWChar:
      begin
        RequireType(L, AIndex, LUA_TSTRING, 'Wide character value');
        U := UTF8Decode(LuaString(L, AIndex));
        if Length(U) <> 1 then
          RaiseBridgeError('Wide character value must contain exactly one character');
        WCh := WideChar(U[1]);
        Result := TValue.FromOrdinal(ARttiType.Handle, Ord(WCh));
      end;

    tkFloat:
      begin
        RequireType(L, AIndex, LUA_TNUMBER, 'Floating-point value');
        case TRttiFloatType(ARttiType).FloatType of
          ftSingle:
            begin
              FSingle := lua_tonumber(L, AIndex);
              TValue.Make(@FSingle, ARttiType.Handle, Result);
            end;
          ftDouble:
            begin
              FDouble := lua_tonumber(L, AIndex);
              TValue.Make(@FDouble, ARttiType.Handle, Result);
            end;
          ftExtended:
            begin
              FExtended := lua_tonumber(L, AIndex);
              TValue.Make(@FExtended, ARttiType.Handle, Result);
            end;
          ftCurr:
            begin
              FCurrency := lua_tonumber(L, AIndex);
              TValue.Make(@FCurrency, ARttiType.Handle, Result);
            end;
          ftComp:
            begin
              FComp := Trunc(lua_tonumber(L, AIndex));
              TValue.Make(@FComp, ARttiType.Handle, Result);
            end;
        else
          RaiseBridgeError('Unsupported floating-point type "' + ARttiType.Name + '"');
        end;
      end;

    tkSString:
      begin
        RequireType(L, AIndex, LUA_TSTRING, 'String value');
        SS := ShortString(LuaString(L, AIndex));
        TValue.Make(@SS, ARttiType.Handle, Result);
      end;

    tkAString, tkLString:
      begin
        RequireType(L, AIndex, LUA_TSTRING, 'String value');
        S := LuaString(L, AIndex);
        A := AnsiString(S);
        TValue.Make(@A, ARttiType.Handle, Result);
      end;

    tkUString:
      begin
        RequireType(L, AIndex, LUA_TSTRING, 'String value');
        S := LuaString(L, AIndex);
        U := UTF8Decode(S);
        TValue.Make(@U, ARttiType.Handle, Result);
      end;

    tkWString:
      begin
        RequireType(L, AIndex, LUA_TSTRING, 'String value');
        S := LuaString(L, AIndex);
        W := WideString(UTF8Decode(S));
        TValue.Make(@W, ARttiType.Handle, Result);
      end;

  else
    RaiseBridgeError(
      Format(
        'Unsupported Pascal parameter type "%s" (%s)',
        [ARttiType.Name, GetEnumName(TypeInfo(TTypeKind), Ord(ARttiType.TypeKind))]
      )
    );
  end;
end;

procedure TLuaPlugin.ValueToLua(L: Plua_State; const AValue: TValue);
var
  S: UTF8String;
  U: UnicodeString;
begin
  if AValue.IsEmpty then
  begin
    lua_pushnil(L);
    Exit;
  end;

  case AValue.Kind of
    tkInteger:
      lua_pushinteger(L, AValue.AsOrdinal);

    tkChar, tkUChar:
      begin
        SetLength(S, 1);
        S[1] := AnsiChar(AValue.AsOrdinal);
        lua_pushlstring(L, PChar(S), Length(S));
      end;

    tkWChar:
      begin
        U := UnicodeString(WideChar(AValue.AsOrdinal));
        S := UTF8Encode(U);
        lua_pushlstring(L, PChar(S), Length(S));
      end;

    tkInt64:
      lua_pushnumber(L, AValue.AsInt64);

    tkQWord:
      lua_pushnumber(L, AValue.AsUInt64);

    tkEnumeration:
      begin
        S := UTF8String(GetEnumName(AValue.TypeInfo, AValue.AsOrdinal));
        lua_pushlstring(L, PChar(S), Length(S));
      end;

    tkBool:
      lua_pushboolean(L, Ord(AValue.AsBoolean));

    tkFloat:
      lua_pushnumber(L, AValue.AsExtended);

    tkSString, tkAString, tkLString:
      begin
        S := UTF8String(AValue.AsAnsiString);
        lua_pushlstring(L, PChar(S), Length(S));
      end;

    tkUString:
      begin
        S := UTF8Encode(AValue.AsUnicodeString);
        lua_pushlstring(L, PChar(S), Length(S));
      end;

    tkWString:
      begin
        S := UTF8Encode(UnicodeString(AValue.AsString));
        lua_pushlstring(L, PChar(S), Length(S));
      end;

  else
    RaiseBridgeError(
      Format(
        'Unsupported Pascal return/property type "%s"',
        [GetEnumName(TypeInfo(TTypeKind), Ord(AValue.Kind))]
      )
    );
  end;
end;

end.

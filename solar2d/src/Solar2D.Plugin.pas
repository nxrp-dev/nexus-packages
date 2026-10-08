(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit Solar2D.Plugin;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Rtti,
  Lua51,
  Lua.Plugin,
  Solar2D.Corona;

type
  ESolarPlugin = class(ELuaPlugin);

  TSolarEventField = record
    Name: UTF8String;
    Value: TValue;
  end;

  TSolarEvent = class
  private
    FLuaState: Plua_State;
    FIndex: Integer;
    FName: UTF8String;
    constructor Create(L: Plua_State; AIndex: Integer);
    function FieldType(const AName: string): Integer;
    procedure RequireFieldType(const AName: string; AType: Integer);
  public
    function HasField(const AName: string): Boolean;
    function GetString(const AName: string; const ADefault: UTF8String = ''): UTF8String;
    function GetInteger(const AName: string; ADefault: Int64 = 0): Int64;
    function GetNumber(const AName: string; ADefault: Double = 0.0): Double;
    function GetBoolean(const AName: string; ADefault: Boolean = False): Boolean;
    property Name: UTF8String read FName;
  end;

  TSolarPlugin = class;
  TSolarPluginClass = class of TSolarPlugin;

  TSolarPlugin = class(TLuaPlugin)
  private
    FListeners: TList;
    FDispatchDepth: Integer;
    class function DoLuaAddEventListener(L: Plua_State): Integer; cdecl; static;
    class function DoLuaRemoveEventListener(L: Plua_State): Integer; cdecl; static;
    class function DoLuaDispatchEvent(L: Plua_State): Integer; cdecl; static;
    class function LuaAddEventListener(L: Plua_State): Integer; cdecl; static;
    class function LuaRemoveEventListener(L: Plua_State): Integer; cdecl; static;
    class function LuaDispatchEvent(L: Plua_State): Integer; cdecl; static;
    function AddLuaEventListener(
      L: Plua_State;
      const AEventName: UTF8String;
      AListenerIndex: Integer
    ): Boolean;
    function RemoveLuaEventListener(
      L: Plua_State;
      const AEventName: UTF8String;
      AListenerIndex: Integer
    ): Boolean;
    procedure CleanupInactiveListeners;
    procedure ClearListeners;
    procedure PushEventFields(L: Plua_State; const AFields: array of TSolarEventField);
    procedure DispatchLuaEventTable(
      L: Plua_State;
      AEventIndex: Integer;
      const AEventName: UTF8String
    );
  protected
    function ResolveLuaState(L: Plua_State): Plua_State; override;
    function TryPushLuaMember(L: Plua_State; const AName: UTF8String): Boolean; override;
    procedure HandleEvent(AEvent: TSolarEvent); virtual;

    procedure DispatchEvent(const AEventName: UTF8String); overload;
    procedure DispatchEvent(
      const AEventName: UTF8String;
      const AFields: array of TSolarEventField
    ); overload;
    procedure DispatchRuntimeEvent(const AEventName: UTF8String); overload;
    procedure DispatchRuntimeEvent(
      const AEventName: UTF8String;
      const AFields: array of TSolarEventField
    ); overload;
  public
    constructor Create; override;
    destructor Destroy; override;

    class function OpenLibrary(
      L: Plua_State;
      const ALibraryName: UTF8String;
      const APublisherId: UTF8String;
      AVersion: Integer;
      ARevision: Integer;
      APluginClass: TSolarPluginClass
    ): Integer;
  end;

function SolarEventField(const AName: string; AValue: Integer): TSolarEventField; overload;
function SolarEventField(const AName: string; AValue: Int64): TSolarEventField; overload;
function SolarEventField(const AName: string; AValue: Double): TSolarEventField; overload;
function SolarEventField(const AName: string; AValue: Boolean): TSolarEventField; overload;
function SolarEventField(const AName, AValue: string): TSolarEventField; overload;

implementation

function LuaReadString(L: Plua_State; AIndex: Integer): UTF8String;
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

type
  TSolarEventListener = class
  public
    EventName: UTF8String;
    Ref: CoronaLuaRef;
    Active: Boolean;
  end;

function SolarEventField(const AName: string; AValue: Integer): TSolarEventField;
begin
  Result.Name := UTF8String(AName);
  Result.Value := TValue.specialize From<Integer>(AValue);
end;

function SolarEventField(const AName: string; AValue: Int64): TSolarEventField;
begin
  Result.Name := UTF8String(AName);
  Result.Value := TValue.specialize From<Int64>(AValue);
end;

function SolarEventField(const AName: string; AValue: Double): TSolarEventField;
begin
  Result.Name := UTF8String(AName);
  Result.Value := TValue.specialize From<Double>(AValue);
end;

function SolarEventField(const AName: string; AValue: Boolean): TSolarEventField;
begin
  Result.Name := UTF8String(AName);
  Result.Value := TValue.specialize From<Boolean>(AValue);
end;

function SolarEventField(const AName, AValue: string): TSolarEventField;
begin
  Result.Name := UTF8String(AName);
  Result.Value := TValue.specialize From<string>(AValue);
end;

constructor TSolarEvent.Create(L: Plua_State; AIndex: Integer);
begin
  inherited Create;
  FLuaState := L;
  FIndex := lua_absindex(L, AIndex);
  lua_getfield(L, FIndex, 'name');
  if lua_type(L, -1) = LUA_TSTRING then
    FName := LuaReadString(L, -1)
  else
    FName := '';
  lua_pop(L, 1);
end;

function TSolarEvent.FieldType(const AName: string): Integer;
begin
  lua_getfield(FLuaState, FIndex, PChar(UTF8String(AName)));
  Result := lua_type(FLuaState, -1);
  lua_pop(FLuaState, 1);
end;

procedure TSolarEvent.RequireFieldType(const AName: string; AType: Integer);
var
  ActualType: Integer;
  ExpectedName: PChar;
  ActualName: PChar;
begin
  ActualType := FieldType(AName);
  if ActualType = AType then
    Exit;

  ExpectedName := lua_typename(FLuaState, AType);
  ActualName := lua_typename(FLuaState, ActualType);
  raise ESolarPlugin.CreateFmt(
    'Event "%s" field "%s" must be %s, got %s',
    [string(FName), AName, string(ExpectedName), string(ActualName)]
  );
end;

function TSolarEvent.HasField(const AName: string): Boolean;
begin
  Result := FieldType(AName) <> LUA_TNIL;
end;

function TSolarEvent.GetString(
  const AName: string;
  const ADefault: UTF8String
): UTF8String;
begin
  if not HasField(AName) then
    Exit(ADefault);
  RequireFieldType(AName, LUA_TSTRING);
  lua_getfield(FLuaState, FIndex, PChar(UTF8String(AName)));
  Result := LuaReadString(FLuaState, -1);
  lua_pop(FLuaState, 1);
end;

function TSolarEvent.GetInteger(const AName: string; ADefault: Int64): Int64;
begin
  if not HasField(AName) then
    Exit(ADefault);
  RequireFieldType(AName, LUA_TNUMBER);
  lua_getfield(FLuaState, FIndex, PChar(UTF8String(AName)));
  Result := lua_tointeger(FLuaState, -1);
  lua_pop(FLuaState, 1);
end;

function TSolarEvent.GetNumber(const AName: string; ADefault: Double): Double;
begin
  if not HasField(AName) then
    Exit(ADefault);
  RequireFieldType(AName, LUA_TNUMBER);
  lua_getfield(FLuaState, FIndex, PChar(UTF8String(AName)));
  Result := lua_tonumber(FLuaState, -1);
  lua_pop(FLuaState, 1);
end;

function TSolarEvent.GetBoolean(const AName: string; ADefault: Boolean): Boolean;
begin
  if not HasField(AName) then
    Exit(ADefault);
  RequireFieldType(AName, LUA_TBOOLEAN);
  lua_getfield(FLuaState, FIndex, PChar(UTF8String(AName)));
  Result := lua_toboolean(FLuaState, -1) <> 0;
  lua_pop(FLuaState, 1);
end;

constructor TSolarPlugin.Create;
begin
  inherited Create;
  FListeners := TList.Create;
end;

destructor TSolarPlugin.Destroy;
begin
  ClearListeners;
  FreeAndNil(FListeners);
  inherited Destroy;
end;

function TSolarPlugin.ResolveLuaState(L: Plua_State): Plua_State;
begin
  Result := CoronaLuaGetCoronaThread(L);
  if Result = nil then
    Result := inherited ResolveLuaState(L);
end;

function TSolarPlugin.TryPushLuaMember(
  L: Plua_State;
  const AName: UTF8String
): Boolean;
begin
  Result := True;
  if AName = 'addEventListener' then
    PushBoundClosure(L, 1, @LuaAddEventListener)
  else if AName = 'removeEventListener' then
    PushBoundClosure(L, 1, @LuaRemoveEventListener)
  else if AName = 'dispatchEvent' then
    PushBoundClosure(L, 1, @LuaDispatchEvent)
  else
    Result := inherited TryPushLuaMember(L, AName);
end;

procedure TSolarPlugin.HandleEvent(AEvent: TSolarEvent);
begin
end;

function TSolarPlugin.AddLuaEventListener(
  L: Plua_State;
  const AEventName: UTF8String;
  AListenerIndex: Integer
): Boolean;
var
  I: Integer;
  Listener: TSolarEventListener;
begin
  Result := False;
  if (AEventName = '') or
    (CoronaLuaIsListener(L, AListenerIndex, PChar(AEventName)) = 0) then
    Exit;

  for I := 0 to FListeners.Count - 1 do
  begin
    Listener := TSolarEventListener(FListeners[I]);
    if Listener.Active and (Listener.EventName = AEventName) and
      (CoronaLuaEqualRef(L, Listener.Ref, AListenerIndex) <> 0) then
      Exit(True);
  end;

  Listener := TSolarEventListener.Create;
  Listener.EventName := AEventName;
  Listener.Ref := CoronaLuaNewRef(L, AListenerIndex);
  Listener.Active := Assigned(Listener.Ref);
  if not Listener.Active then
  begin
    Listener.Free;
    Exit;
  end;

  FListeners.Add(Listener);
  Result := True;
end;

function TSolarPlugin.RemoveLuaEventListener(
  L: Plua_State;
  const AEventName: UTF8String;
  AListenerIndex: Integer
): Boolean;
var
  I: Integer;
  Listener: TSolarEventListener;
begin
  Result := False;
  for I := 0 to FListeners.Count - 1 do
  begin
    Listener := TSolarEventListener(FListeners[I]);
    if not Listener.Active or (Listener.EventName <> AEventName) then
      Continue;
    if CoronaLuaEqualRef(L, Listener.Ref, AListenerIndex) = 0 then
      Continue;

    Listener.Active := False;
    Result := True;
    Break;
  end;

  if (FDispatchDepth = 0) and Result then
    CleanupInactiveListeners;
end;

procedure TSolarPlugin.CleanupInactiveListeners;
var
  I: Integer;
  Listener: TSolarEventListener;
begin
  if FDispatchDepth <> 0 then
    Exit;

  for I := FListeners.Count - 1 downto 0 do
  begin
    Listener := TSolarEventListener(FListeners[I]);
    if Listener.Active then
      Continue;
    if Assigned(Listener.Ref) and Assigned(LuaState) then
    begin
      CoronaLuaDeleteRef(LuaState, Listener.Ref);
      Listener.Ref := nil;
    end;
    FListeners.Delete(I);
    Listener.Free;
  end;
end;

procedure TSolarPlugin.ClearListeners;
var
  I: Integer;
  Listener: TSolarEventListener;
begin
  if not Assigned(FListeners) then
    Exit;

  for I := FListeners.Count - 1 downto 0 do
  begin
    Listener := TSolarEventListener(FListeners[I]);
    Listener.Active := False;
    if Assigned(Listener.Ref) and Assigned(LuaState) then
    begin
      CoronaLuaDeleteRef(LuaState, Listener.Ref);
      Listener.Ref := nil;
    end;
    FListeners.Delete(I);
    Listener.Free;
  end;
end;

procedure TSolarPlugin.PushEventFields(
  L: Plua_State;
  const AFields: array of TSolarEventField
);
var
  I: Integer;
begin
  for I := 0 to High(AFields) do
  begin
    if AFields[I].Name = '' then
      raise ESolarPlugin.Create('Solar2D event field name cannot be empty');
    ValueToLua(L, AFields[I].Value);
    lua_setfield(L, -2, PChar(AFields[I].Name));
  end;
end;

procedure TSolarPlugin.DispatchLuaEventTable(
  L: Plua_State;
  AEventIndex: Integer;
  const AEventName: UTF8String
);
var
  AbsoluteEventIndex: Integer;
  I: Integer;
  ListenerLimit: Integer;
  Listener: TSolarEventListener;
begin
  AbsoluteEventIndex := lua_absindex(L, AEventIndex);
  ListenerLimit := FListeners.Count;
  Inc(FDispatchDepth);
  try
    for I := 0 to ListenerLimit - 1 do
    begin
      Listener := TSolarEventListener(FListeners[I]);
      if not Listener.Active or (Listener.EventName <> AEventName) then
        Continue;
      lua_pushvalue(L, AbsoluteEventIndex);
      CoronaLuaDispatchEvent(L, Listener.Ref, 0);
    end;
  finally
    Dec(FDispatchDepth);
    if FDispatchDepth = 0 then
      CleanupInactiveListeners;
  end;
end;

class function TSolarPlugin.LuaAddEventListener(L: Plua_State): Integer; cdecl;
begin
  Result := RunLuaCallback(L, @DoLuaAddEventListener);
end;

class function TSolarPlugin.DoLuaAddEventListener(L: Plua_State): Integer; cdecl;
var
  Obj: TSolarPlugin;
  ArgBase: Integer;
  EventName: UTF8String;
begin
  Result := 0;
  Obj := TSolarPlugin(BoundObject(L));
  ArgBase := BoundArgumentBase(L);
  if lua_gettop(L) - ArgBase + 1 <> 2 then
    RaiseBridgeError('addEventListener expects eventName and listener');
  RequireType(L, ArgBase, LUA_TSTRING, 'Event name');
  EventName := LuaString(L, ArgBase);
  lua_pushboolean(
    L,
    Ord(Obj.AddLuaEventListener(L, EventName, ArgBase + 1))
  );
  Result := 1;
end;

class function TSolarPlugin.LuaRemoveEventListener(L: Plua_State): Integer; cdecl;
begin
  Result := RunLuaCallback(L, @DoLuaRemoveEventListener);
end;

class function TSolarPlugin.DoLuaRemoveEventListener(L: Plua_State): Integer; cdecl;
var
  Obj: TSolarPlugin;
  ArgBase: Integer;
  EventName: UTF8String;
begin
  Result := 0;
  Obj := TSolarPlugin(BoundObject(L));
  ArgBase := BoundArgumentBase(L);
  if lua_gettop(L) - ArgBase + 1 <> 2 then
    RaiseBridgeError('removeEventListener expects eventName and listener');
  RequireType(L, ArgBase, LUA_TSTRING, 'Event name');
  EventName := LuaString(L, ArgBase);
  lua_pushboolean(
    L,
    Ord(Obj.RemoveLuaEventListener(L, EventName, ArgBase + 1))
  );
  Result := 1;
end;

class function TSolarPlugin.LuaDispatchEvent(L: Plua_State): Integer; cdecl;
begin
  Result := RunLuaCallback(L, @DoLuaDispatchEvent);
end;

class function TSolarPlugin.DoLuaDispatchEvent(L: Plua_State): Integer; cdecl;
var
  Obj: TSolarPlugin;
  ArgBase: Integer;
  EventIndex: Integer;
  EventName: UTF8String;
  EventObject: TSolarEvent;
begin
  Result := 0;
  EventObject := nil;
  Obj := TSolarPlugin(BoundObject(L));
  ArgBase := BoundArgumentBase(L);
  if lua_gettop(L) - ArgBase + 1 <> 1 then
    RaiseBridgeError('dispatchEvent expects one event table');
  RequireType(L, ArgBase, LUA_TTABLE, 'Event');
  EventIndex := lua_absindex(L, ArgBase);

  lua_getfield(L, EventIndex, 'name');
  if lua_type(L, -1) <> LUA_TSTRING then
  begin
    lua_pop(L, 1);
    RaiseBridgeError('Event table must contain a string name field');
  end;
  EventName := LuaString(L, -1);
  lua_pop(L, 1);
  if EventName = '' then
    RaiseBridgeError('Event name cannot be empty');

  lua_getfield(L, EventIndex, 'target');
  if lua_isnil(L, -1) then
  begin
    lua_pop(L, 1);
    lua_pushvalue(L, lua_upvalueindex(1));
    lua_setfield(L, EventIndex, 'target');
  end
  else
    lua_pop(L, 1);

  EventObject := TSolarEvent.Create(L, EventIndex);
  try
    Obj.HandleEvent(EventObject);
  finally
    FreeAndNil(EventObject);
  end;

  Obj.DispatchLuaEventTable(L, EventIndex, EventName);
end;

procedure TSolarPlugin.DispatchEvent(const AEventName: UTF8String);
begin
  DispatchEvent(AEventName, []);
end;

procedure TSolarPlugin.DispatchEvent(
  const AEventName: UTF8String;
  const AFields: array of TSolarEventField
);
var
  EventIndex: Integer;
begin
  if AEventName = '' then
    raise ESolarPlugin.Create('Solar2D event name cannot be empty');
  if not Assigned(LuaState) then
    raise ESolarPlugin.Create('Solar2D plugin is not bound to a Lua state');

  CoronaLuaNewEvent(LuaState, PChar(AEventName));
  EventIndex := lua_gettop(LuaState);
  try
    PushEventFields(LuaState, AFields);
    DispatchLuaEventTable(LuaState, EventIndex, AEventName);
  finally
    lua_settop(LuaState, EventIndex - 1);
  end;
end;

procedure TSolarPlugin.DispatchRuntimeEvent(const AEventName: UTF8String);
begin
  DispatchRuntimeEvent(AEventName, []);
end;

procedure TSolarPlugin.DispatchRuntimeEvent(
  const AEventName: UTF8String;
  const AFields: array of TSolarEventField
);
begin
  if AEventName = '' then
    raise ESolarPlugin.Create('Solar2D runtime event name cannot be empty');
  if not Assigned(LuaState) then
    raise ESolarPlugin.Create('Solar2D plugin is not bound to a Lua state');

  CoronaLuaNewEvent(LuaState, PChar(AEventName));
  PushEventFields(LuaState, AFields);
  CoronaLuaDispatchRuntimeEvent(LuaState, 0);
end;

class function TSolarPlugin.OpenLibrary(
  L: Plua_State;
  const ALibraryName: UTF8String;
  const APublisherId: UTF8String;
  AVersion: Integer;
  ARevision: Integer;
  APluginClass: TSolarPluginClass
): Integer;
var
  Functions: array[0..1] of luaL_Reg;
begin
  if not Assigned(APluginClass) then
    RaiseBridgeError('Solar2D plugin class is required');

  Functions[0].name := 'new';
  Functions[0].func := @TLuaPlugin.LuaNew;
  Functions[1].name := nil;
  Functions[1].func := nil;

  Result := CoronaLibraryNew(
    L,
    PChar(ALibraryName),
    PChar(APublisherId),
    AVersion,
    ARevision,
    @Functions[0],
    Pointer(APluginClass)
  );
end;

end.

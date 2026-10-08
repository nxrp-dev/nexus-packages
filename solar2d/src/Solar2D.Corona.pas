(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit Solar2D.Corona;

{$mode objfpc}{$H+}

interface

uses
  Lua51;

type
  CoronaLuaRef = Pointer;

function CoronaLibraryNew(
  L: Plua_State;
  LibName: PChar;
  PublisherId: PChar;
  Version: Integer;
  Revision: Integer;
  LibFuncs: PluaL_Reg;
  Context: Pointer
): Integer; cdecl; external name 'CoronaLibraryNew';

function CoronaLuaGetCoronaThread(L: Plua_State): Plua_State; cdecl; external name 'CoronaLuaGetCoronaThread';
function CoronaLuaGetContext(L: Plua_State): Pointer; cdecl; external name 'CoronaLuaGetContext';
procedure CoronaLuaInitializeContext(L: Plua_State; Context: Pointer; MetatableName: PChar); cdecl; external name 'CoronaLuaInitializeContext';

function CoronaLuaNewRef(L: Plua_State; Index: Integer): CoronaLuaRef; cdecl; external name 'CoronaLuaNewRef';
procedure CoronaLuaDeleteRef(L: Plua_State; Ref: CoronaLuaRef); cdecl; external name 'CoronaLuaDeleteRef';
function CoronaLuaEqualRef(L: Plua_State; Ref: CoronaLuaRef; Index: Integer): Integer; cdecl; external name 'CoronaLuaEqualRef';

procedure CoronaLuaNewEvent(L: Plua_State; EventName: PChar); cdecl; external name 'CoronaLuaNewEvent';
procedure CoronaLuaDispatchEvent(L: Plua_State; ListenerRef: CoronaLuaRef; NResults: Integer); cdecl; external name 'CoronaLuaDispatchEvent';
procedure CoronaLuaDispatchRuntimeEvent(L: Plua_State; NResults: Integer); cdecl; external name 'CoronaLuaDispatchRuntimeEvent';
function CoronaLuaIsListener(L: Plua_State; Index: Integer; EventName: PChar): Integer; cdecl; external name 'CoronaLuaIsListener';
procedure CoronaLuaPushRuntime(L: Plua_State); cdecl; external name 'CoronaLuaPushRuntime';

procedure CoronaLuaNewGCMetatable(L: Plua_State; Name: PChar; GC: lua_CFunction); cdecl; external name 'CoronaLuaNewGCMetatable';
procedure CoronaLuaNewMetatable(L: Plua_State; Name: PChar; VTable: PluaL_Reg); cdecl; external name 'CoronaLuaNewMetatable';
procedure CoronaLuaInitializeGCMetatable(L: Plua_State; Name: PChar; GC: lua_CFunction); cdecl; external name 'CoronaLuaInitializeGCMetatable';
procedure CoronaLuaInitializeMetatable(L: Plua_State; Name: PChar; VTable: PluaL_Reg); cdecl; external name 'CoronaLuaInitializeMetatable';
procedure CoronaLuaPushUserdata(L: Plua_State; Ud: Pointer; MetatableName: PChar); cdecl; external name 'CoronaLuaPushUserdata';
function CoronaLuaToUserdata(L: Plua_State; Index: Integer): Pointer; cdecl; external name 'CoronaLuaToUserdata';
function CoronaLuaCheckUserdata(L: Plua_State; Index: Integer; MetatableName: PChar): Pointer; cdecl; external name 'CoronaLuaCheckUserdata';

function CoronaLuaDoCall(L: Plua_State; NArg, NResults: Integer): Integer; cdecl; external name 'CoronaLuaDoCall';

implementation

end.

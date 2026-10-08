(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit Lua51;

{$mode objfpc}{$H+}
{$PACKRECORDS C}

interface

uses
  ctypes;

type
  Plua_State = Pointer;
  lua_Integer = PtrInt;
  lua_Number = Double;
  lua_CFunction = function(L: Plua_State): Integer; cdecl;
  lua_Reader = function(L: Plua_State; AUData: Pointer; ASize: PSizeUInt): PChar; cdecl;
  lua_Writer = function(L: Plua_State; AP: Pointer; ASize: SizeUInt; AUData: Pointer): Integer; cdecl;
  lua_Alloc = function(AUData, APtr: Pointer; AOldSize, ANewSize: SizeUInt): Pointer; cdecl;

  Plua_Debug = ^lua_Debug;
  lua_Hook = procedure(L: Plua_State; ARecord: Plua_Debug); cdecl;
  lua_Debug = record
    event: Integer;
    name: PChar;
    namewhat: PChar;
    what: PChar;
    source: PChar;
    currentline: Integer;
    nups: Integer;
    linedefined: Integer;
    lastlinedefined: Integer;
    short_src: array[0..59] of AnsiChar;
    i_ci: Integer;
  end;

  PluaL_Reg = ^luaL_Reg;
  luaL_Reg = record
    name: PChar;
    func: lua_CFunction;
  end;

const
  LUA_VERSION = 'Lua 5.1';
  LUA_RELEASE = 'Lua 5.1.5';
  LUA_VERSION_NUM = 501;
  LUA_SIGNATURE = #27'Lua';
  LUA_MULTRET = -1;

  LUA_STATUS_YIELD = 1;
  LUA_ERRRUN = 2;
  LUA_ERRSYNTAX = 3;
  LUA_ERRMEM = 4;
  LUA_ERRERR = 5;
  LUA_ERRFILE = LUA_ERRERR + 1;

  LUA_TNONE = -1;
  LUA_TNIL = 0;
  LUA_TBOOLEAN = 1;
  LUA_TLIGHTUSERDATA = 2;
  LUA_TNUMBER = 3;
  LUA_TSTRING = 4;
  LUA_TTABLE = 5;
  LUA_TFUNCTION = 6;
  LUA_TUSERDATA = 7;
  LUA_TTHREAD = 8;
  LUA_MINSTACK = 20;

  LUA_REGISTRYINDEX = -10000;
  LUA_ENVIRONINDEX = -10001;
  LUA_GLOBALSINDEX = -10002;

  LUA_GCSTOP = 0;
  LUA_GCRESTART = 1;
  LUA_GCCOLLECT = 2;
  LUA_GCCOUNT = 3;
  LUA_GCCOUNTB = 4;
  LUA_GCSTEP = 5;
  LUA_GCSETPAUSE = 6;
  LUA_GCSETSTEPMUL = 7;

  LUA_HOOKCALL = 0;
  LUA_HOOKRET = 1;
  LUA_HOOKLINE = 2;
  LUA_HOOKCOUNT = 3;
  LUA_HOOKTAILRET = 4;
  LUA_MASKCALL = 1 shl LUA_HOOKCALL;
  LUA_MASKRET = 1 shl LUA_HOOKRET;
  LUA_MASKLINE = 1 shl LUA_HOOKLINE;
  LUA_MASKCOUNT = 1 shl LUA_HOOKCOUNT;
  LUA_IDSIZE = 60;

  LUA_NOREF = -2;
  LUA_REFNIL = -1;

  LUA_FILEHANDLE = 'FILE*';
  LUA_COLIBNAME = 'coroutine';
  LUA_TABLIBNAME = 'table';
  LUA_IOLIBNAME = 'io';
  LUA_OSLIBNAME = 'os';
  LUA_STRLIBNAME = 'string';
  LUA_MATHLIBNAME = 'math';
  LUA_DBLIBNAME = 'debug';
  LUA_LOADLIBNAME = 'package';

  // Lua 5.1 defines this as the target C library's BUFSIZ.
  {$IFDEF MSWINDOWS}
  LUAL_BUFFERSIZE = 512;
  {$ELSE}
    {$IFDEF DARWIN}
  LUAL_BUFFERSIZE = 1024;
    {$ELSE}
  LUAL_BUFFERSIZE = 8192;
    {$ENDIF}
  {$ENDIF}

type
  PluaL_Buffer = ^luaL_Buffer;
  luaL_Buffer = record
    p: PChar;
    lvl: Integer;
    L: Plua_State;
    buffer: array[0..LUAL_BUFFERSIZE - 1] of AnsiChar;
  end;

function lua_upvalueindex(I: Integer): Integer; inline;
function lua_absindex(L: Plua_State; Index: Integer): Integer; inline;

function lua_newstate(AAlloc: lua_Alloc; AUData: Pointer): Plua_State; cdecl; external name 'lua_newstate';
procedure lua_close(L: Plua_State); cdecl; external name 'lua_close';
function lua_newthread(L: Plua_State): Plua_State; cdecl; external name 'lua_newthread';
function lua_atpanic(L: Plua_State; AFunction: lua_CFunction): lua_CFunction; cdecl; external name 'lua_atpanic';

function lua_gettop(L: Plua_State): Integer; cdecl; external name 'lua_gettop';
procedure lua_settop(L: Plua_State; Idx: Integer); cdecl; external name 'lua_settop';
procedure lua_remove(L: Plua_State; AIndex: Integer); cdecl; external name 'lua_remove';
procedure lua_insert(L: Plua_State; AIndex: Integer); cdecl; external name 'lua_insert';
procedure lua_replace(L: Plua_State; AIndex: Integer); cdecl; external name 'lua_replace';
function lua_checkstack(L: Plua_State; ASize: Integer): Integer; cdecl; external name 'lua_checkstack';
procedure lua_xmove(AFrom, ATo: Plua_State; ACount: Integer); cdecl; external name 'lua_xmove';

function lua_isnumber(L: Plua_State; AIndex: Integer): Integer; cdecl; external name 'lua_isnumber';
function lua_isstring(L: Plua_State; AIndex: Integer): Integer; cdecl; external name 'lua_isstring';
function lua_iscfunction(L: Plua_State; AIndex: Integer): Integer; cdecl; external name 'lua_iscfunction';
function lua_isuserdata(L: Plua_State; AIndex: Integer): Integer; cdecl; external name 'lua_isuserdata';
function lua_type(L: Plua_State; Idx: Integer): Integer; cdecl; external name 'lua_type';
function lua_typename(L: Plua_State; Tp: Integer): PChar; cdecl; external name 'lua_typename';
function lua_equal(L: Plua_State; AIndex1, AIndex2: Integer): Integer; cdecl; external name 'lua_equal';
function lua_toboolean(L: Plua_State; Idx: Integer): Integer; cdecl; external name 'lua_toboolean';
function lua_lessthan(L: Plua_State; AIndex1, AIndex2: Integer): Integer; cdecl; external name 'lua_lessthan';
function lua_tointeger(L: Plua_State; Idx: Integer): lua_Integer; cdecl; external name 'lua_tointeger';
function lua_tonumber(L: Plua_State; Idx: Integer): lua_Number; cdecl; external name 'lua_tonumber';
function lua_tolstring(L: Plua_State; Idx: Integer; Len: PSizeUInt): PChar; cdecl; external name 'lua_tolstring';
function lua_objlen(L: Plua_State; AIndex: Integer): SizeUInt; cdecl; external name 'lua_objlen';
function lua_tocfunction(L: Plua_State; AIndex: Integer): lua_CFunction; cdecl; external name 'lua_tocfunction';
function lua_touserdata(L: Plua_State; Idx: Integer): Pointer; cdecl; external name 'lua_touserdata';
function lua_tothread(L: Plua_State; AIndex: Integer): Plua_State; cdecl; external name 'lua_tothread';
function lua_topointer(L: Plua_State; AIndex: Integer): Pointer; cdecl; external name 'lua_topointer';

procedure lua_pushnil(L: Plua_State); cdecl; external name 'lua_pushnil';
procedure lua_pushboolean(L: Plua_State; B: Integer); cdecl; external name 'lua_pushboolean';
procedure lua_pushinteger(L: Plua_State; N: lua_Integer); cdecl; external name 'lua_pushinteger';
procedure lua_pushnumber(L: Plua_State; N: lua_Number); cdecl; external name 'lua_pushnumber';
procedure lua_pushlstring(L: Plua_State; S: PChar; Len: SizeUInt); cdecl; external name 'lua_pushlstring';
procedure lua_pushstring(L: Plua_State; AString: PChar); cdecl; external name 'lua_pushstring';
function lua_pushvfstring(L: Plua_State; AFormat: PChar; AArgs: Pointer): PChar; cdecl; external name 'lua_pushvfstring';
function lua_pushfstring(L: Plua_State; AFormat: PChar): PChar; cdecl; varargs; external name 'lua_pushfstring';
procedure lua_pushlightuserdata(L: Plua_State; P: Pointer); cdecl; external name 'lua_pushlightuserdata';
procedure lua_pushcclosure(L: Plua_State; Fn: lua_CFunction; N: Integer); cdecl; external name 'lua_pushcclosure';
procedure lua_pushvalue(L: Plua_State; Idx: Integer); cdecl; external name 'lua_pushvalue';
function lua_pushthread(L: Plua_State): Integer; cdecl; external name 'lua_pushthread';

function lua_newuserdata(L: Plua_State; Size: SizeUInt): Pointer; cdecl; external name 'lua_newuserdata';
function lua_getmetatable(L: Plua_State; ObjIndex: Integer): Integer; cdecl; external name 'lua_getmetatable';
function lua_setmetatable(L: Plua_State; ObjIndex: Integer): Integer; cdecl; external name 'lua_setmetatable';
procedure lua_getfenv(L: Plua_State; AIndex: Integer); cdecl; external name 'lua_getfenv';
function lua_setfenv(L: Plua_State; AIndex: Integer): Integer; cdecl; external name 'lua_setfenv';

procedure lua_gettable(L: Plua_State; AIndex: Integer); cdecl; external name 'lua_gettable';
procedure lua_getfield(L: Plua_State; Idx: Integer; K: PChar); cdecl; external name 'lua_getfield';
procedure lua_rawget(L: Plua_State; AIndex: Integer); cdecl; external name 'lua_rawget';
procedure lua_setfield(L: Plua_State; Idx: Integer; K: PChar); cdecl; external name 'lua_setfield';
procedure lua_settable(L: Plua_State; AIndex: Integer); cdecl; external name 'lua_settable';
procedure lua_rawset(L: Plua_State; AIndex: Integer); cdecl; external name 'lua_rawset';
procedure lua_rawgeti(L: Plua_State; Idx, N: Integer); cdecl; external name 'lua_rawgeti';
procedure lua_rawseti(L: Plua_State; Idx, N: Integer); cdecl; external name 'lua_rawseti';
procedure lua_createtable(L: Plua_State; AArraySize, ARecordSize: Integer); cdecl; external name 'lua_createtable';
function lua_rawequal(L: Plua_State; Idx1, Idx2: Integer): Integer; cdecl; external name 'lua_rawequal';

function lua_error(L: Plua_State): Integer; cdecl; external name 'lua_error';
procedure lua_call(L: Plua_State; AArgs, AResults: Integer); cdecl; external name 'lua_call';
function lua_pcall(L: Plua_State; NArgs, NResults, ErrFunc: Integer): Integer; cdecl; external name 'lua_pcall';
function lua_cpcall(L: Plua_State; AFunction: lua_CFunction; AUData: Pointer): Integer; cdecl; external name 'lua_cpcall';
function lua_load(L: Plua_State; AReader: lua_Reader; AUData: Pointer; AChunkName: PChar): Integer; cdecl; external name 'lua_load';
function lua_dump(L: Plua_State; AWriter: lua_Writer; AUData: Pointer): Integer; cdecl; external name 'lua_dump';
function lua_yield(L: Plua_State; AResults: Integer): Integer; cdecl; external name 'lua_yield';
function lua_resume(L: Plua_State; AArgs: Integer): Integer; cdecl; external name 'lua_resume';
function lua_status(L: Plua_State): Integer; cdecl; external name 'lua_status';
function lua_gc(L: Plua_State; AOperation, AData: Integer): Integer; cdecl; external name 'lua_gc';
function lua_next(L: Plua_State; AIndex: Integer): Integer; cdecl; external name 'lua_next';
procedure lua_concat(L: Plua_State; ACount: Integer); cdecl; external name 'lua_concat';
function lua_getallocf(L: Plua_State; AUData: PPointer): lua_Alloc; cdecl; external name 'lua_getallocf';
procedure lua_setallocf(L: Plua_State; AAlloc: lua_Alloc; AUData: Pointer); cdecl; external name 'lua_setallocf';
procedure lua_setlevel(AFrom, ATo: Plua_State); cdecl; external name 'lua_setlevel';

function lua_getstack(L: Plua_State; ALevel: Integer; ARecord: Plua_Debug): Integer; cdecl; external name 'lua_getstack';
function lua_getinfo(L: Plua_State; AWhat: PChar; ARecord: Plua_Debug): Integer; cdecl; external name 'lua_getinfo';
function lua_getlocal(L: Plua_State; ARecord: Plua_Debug; ANumber: Integer): PChar; cdecl; external name 'lua_getlocal';
function lua_setlocal(L: Plua_State; ARecord: Plua_Debug; ANumber: Integer): PChar; cdecl; external name 'lua_setlocal';
function lua_getupvalue(L: Plua_State; AFunction, ANumber: Integer): PChar; cdecl; external name 'lua_getupvalue';
function lua_setupvalue(L: Plua_State; AFunction, ANumber: Integer): PChar; cdecl; external name 'lua_setupvalue';
function lua_sethook(L: Plua_State; AHook: lua_Hook; AMask, ACount: Integer): Integer; cdecl; external name 'lua_sethook';
function lua_gethook(L: Plua_State): lua_Hook; cdecl; external name 'lua_gethook';
function lua_gethookmask(L: Plua_State): Integer; cdecl; external name 'lua_gethookmask';
function lua_gethookcount(L: Plua_State): Integer; cdecl; external name 'lua_gethookcount';

function luaL_newmetatable(L: Plua_State; TName: PChar): Integer; cdecl; external name 'luaL_newmetatable';
function luaL_checkudata(L: Plua_State; Ud: Integer; TName: PChar): Pointer; cdecl; external name 'luaL_checkudata';
function luaL_ref(L: Plua_State; T: Integer): Integer; cdecl; external name 'luaL_ref';
procedure luaL_unref(L: Plua_State; T, Ref: Integer); cdecl; external name 'luaL_unref';
procedure luaL_openlib(L: Plua_State; ALibraryName: PChar; AFunctions: PluaL_Reg; AUpvalues: Integer); cdecl; external name 'luaL_openlib';
procedure luaL_register(L: Plua_State; ALibraryName: PChar; AFunctions: PluaL_Reg); cdecl; external name 'luaL_register';
function luaL_getmetafield(L: Plua_State; AIndex: Integer; AName: PChar): Integer; cdecl; external name 'luaL_getmetafield';
function luaL_callmeta(L: Plua_State; AIndex: Integer; AName: PChar): Integer; cdecl; external name 'luaL_callmeta';
function luaL_typerror(L: Plua_State; AArg: Integer; ATypeName: PChar): Integer; cdecl; external name 'luaL_typerror';
function luaL_argerror(L: Plua_State; AArg: Integer; AMessage: PChar): Integer; cdecl; external name 'luaL_argerror';
function luaL_checklstring(L: Plua_State; AArg: Integer; ALen: PSizeUInt): PChar; cdecl; external name 'luaL_checklstring';
function luaL_optlstring(L: Plua_State; AArg: Integer; ADefault: PChar; ALen: PSizeUInt): PChar; cdecl; external name 'luaL_optlstring';
function luaL_checknumber(L: Plua_State; AArg: Integer): lua_Number; cdecl; external name 'luaL_checknumber';
function luaL_optnumber(L: Plua_State; AArg: Integer; ADefault: lua_Number): lua_Number; cdecl; external name 'luaL_optnumber';
function luaL_checkinteger(L: Plua_State; AArg: Integer): lua_Integer; cdecl; external name 'luaL_checkinteger';
function luaL_optinteger(L: Plua_State; AArg: Integer; ADefault: lua_Integer): lua_Integer; cdecl; external name 'luaL_optinteger';
procedure luaL_checkstack(L: Plua_State; ASize: Integer; AMessage: PChar); cdecl; external name 'luaL_checkstack';
procedure luaL_checktype(L: Plua_State; AArg, AType: Integer); cdecl; external name 'luaL_checktype';
procedure luaL_checkany(L: Plua_State; AArg: Integer); cdecl; external name 'luaL_checkany';
procedure luaL_where(L: Plua_State; ALevel: Integer); cdecl; external name 'luaL_where';
function luaL_error(L: Plua_State; AFormat: PChar): Integer; cdecl; varargs; external name 'luaL_error';
function luaL_checkoption(L: Plua_State; AArg: Integer; ADefault: PChar; AOptions: PPChar): Integer; cdecl; external name 'luaL_checkoption';
function luaL_loadfile(L: Plua_State; AFileName: PChar): Integer; cdecl; external name 'luaL_loadfile';
function luaL_loadbuffer(L: Plua_State; ABuffer: PChar; ASize: SizeUInt; AName: PChar): Integer; cdecl; external name 'luaL_loadbuffer';
function luaL_loadstring(L: Plua_State; ASource: PChar): Integer; cdecl; external name 'luaL_loadstring';
function luaL_newstate: Plua_State; cdecl; external name 'luaL_newstate';
function luaL_gsub(L: Plua_State; ASource, APattern, AReplacement: PChar): PChar; cdecl; external name 'luaL_gsub';
function luaL_findtable(L: Plua_State; AIndex: Integer; AName: PChar; ASizeHint: Integer): PChar; cdecl; external name 'luaL_findtable';
procedure luaL_buffinit(L: Plua_State; ABuffer: PluaL_Buffer); cdecl; external name 'luaL_buffinit';
function luaL_prepbuffer(ABuffer: PluaL_Buffer): PChar; cdecl; external name 'luaL_prepbuffer';
procedure luaL_addlstring(ABuffer: PluaL_Buffer; AString: PChar; ALen: SizeUInt); cdecl; external name 'luaL_addlstring';
procedure luaL_addstring(ABuffer: PluaL_Buffer; AString: PChar); cdecl; external name 'luaL_addstring';
procedure luaL_addvalue(ABuffer: PluaL_Buffer); cdecl; external name 'luaL_addvalue';
procedure luaL_pushresult(ABuffer: PluaL_Buffer); cdecl; external name 'luaL_pushresult';

function luaopen_base(L: Plua_State): Integer; cdecl; external name 'luaopen_base';
function luaopen_table(L: Plua_State): Integer; cdecl; external name 'luaopen_table';
function luaopen_io(L: Plua_State): Integer; cdecl; external name 'luaopen_io';
function luaopen_os(L: Plua_State): Integer; cdecl; external name 'luaopen_os';
function luaopen_string(L: Plua_State): Integer; cdecl; external name 'luaopen_string';
function luaopen_math(L: Plua_State): Integer; cdecl; external name 'luaopen_math';
function luaopen_debug(L: Plua_State): Integer; cdecl; external name 'luaopen_debug';
function luaopen_package(L: Plua_State): Integer; cdecl; external name 'luaopen_package';
procedure luaL_openlibs(L: Plua_State); cdecl; external name 'luaL_openlibs';
procedure luaL_getmetatable(L: Plua_State; TName: PChar); inline;

procedure lua_pop(L: Plua_State; N: Integer); inline;
procedure lua_pushcfunction(L: Plua_State; Fn: lua_CFunction); inline;
function lua_isnil(L: Plua_State; Index: Integer): Boolean; inline;
function lua_istable(L: Plua_State; Index: Integer): Boolean; inline;
function lua_isfunction(L: Plua_State; Index: Integer): Boolean; inline;
procedure lua_newtable(L: Plua_State); inline;
procedure lua_register(L: Plua_State; AName: PChar; AFunction: lua_CFunction); inline;
function lua_strlen(L: Plua_State; AIndex: Integer): SizeUInt; inline;
function lua_isboolean(L: Plua_State; AIndex: Integer): Boolean; inline;
function lua_isthread(L: Plua_State; AIndex: Integer): Boolean; inline;
function lua_islightuserdata(L: Plua_State; AIndex: Integer): Boolean; inline;
function lua_isnone(L: Plua_State; AIndex: Integer): Boolean; inline;
function lua_isnoneornil(L: Plua_State; AIndex: Integer): Boolean; inline;
procedure lua_getglobal(L: Plua_State; AName: PChar); inline;
procedure lua_setglobal(L: Plua_State; AName: PChar); inline;
function lua_tostring(L: Plua_State; AIndex: Integer): PChar; inline;
procedure lua_getregistry(L: Plua_State); inline;
function lua_getgccount(L: Plua_State): Integer; inline;
procedure luaI_openlib(L: Plua_State; ALibraryName: PChar; AFunctions: PluaL_Reg; AUpvalues: Integer); inline;
function lua_open: Plua_State; inline;
procedure lua_pushliteral(L: Plua_State; const AText: RawByteString); inline;
procedure luaL_argcheck(L: Plua_State; ACondition: Boolean; AArg: Integer; AMessage: PChar); inline;
function luaL_checkstring(L: Plua_State; AArg: Integer): PChar; inline;
function luaL_optstring(L: Plua_State; AArg: Integer; ADefault: PChar): PChar; inline;
function luaL_checkint(L: Plua_State; AArg: Integer): Integer; inline;
function luaL_optint(L: Plua_State; AArg, ADefault: Integer): Integer; inline;
function luaL_checklong(L: Plua_State; AArg: Integer): CLong; inline;
function luaL_optlong(L: Plua_State; AArg: Integer; ADefault: CLong): CLong; inline;
function luaL_typename(L: Plua_State; AIndex: Integer): PChar; inline;
function luaL_dofile(L: Plua_State; AFileName: PChar): Integer; inline;
function luaL_dostring(L: Plua_State; ASource: PChar): Integer; inline;
procedure luaL_addsize(ABuffer: PluaL_Buffer; ASize: SizeUInt); inline;
procedure luaL_addchar(ABuffer: PluaL_Buffer; AChar: AnsiChar); inline;
procedure luaL_putchar(ABuffer: PluaL_Buffer; AChar: AnsiChar); inline;
function luaL_getn(L: Plua_State; AIndex: Integer): Integer; inline;
procedure luaL_setn(L: Plua_State; AIndex, ACount: Integer); inline;
function lua_ref(L: Plua_State; ALock: Boolean): Integer; inline;
procedure lua_unref(L: Plua_State; ARef: Integer); inline;
procedure lua_getref(L: Plua_State; ARef: Integer); inline;

implementation

function lua_upvalueindex(I: Integer): Integer; inline;
begin
  Result := LUA_GLOBALSINDEX - I;
end;

function lua_absindex(L: Plua_State; Index: Integer): Integer; inline;
begin
  if (Index > 0) or (Index <= LUA_REGISTRYINDEX) then
    Result := Index
  else
    Result := lua_gettop(L) + Index + 1;
end;

procedure lua_pop(L: Plua_State; N: Integer); inline;
begin
  lua_settop(L, -N - 1);
end;

procedure lua_pushcfunction(L: Plua_State; Fn: lua_CFunction); inline;
begin
  lua_pushcclosure(L, Fn, 0);
end;

procedure luaL_getmetatable(L: Plua_State; TName: PChar); inline;
begin
  lua_getfield(L, LUA_REGISTRYINDEX, TName);
end;

function lua_isnil(L: Plua_State; Index: Integer): Boolean; inline;
begin
  Result := lua_type(L, Index) = LUA_TNIL;
end;

function lua_istable(L: Plua_State; Index: Integer): Boolean; inline;
begin
  Result := lua_type(L, Index) = LUA_TTABLE;
end;

function lua_isfunction(L: Plua_State; Index: Integer): Boolean; inline;
begin
  Result := lua_type(L, Index) = LUA_TFUNCTION;
end;

procedure lua_newtable(L: Plua_State); inline;
begin
  lua_createtable(L, 0, 0);
end;

procedure lua_register(L: Plua_State; AName: PChar; AFunction: lua_CFunction); inline;
begin
  lua_pushcfunction(L, AFunction);
  lua_setglobal(L, AName);
end;

function lua_strlen(L: Plua_State; AIndex: Integer): SizeUInt; inline;
begin
  Result := lua_objlen(L, AIndex);
end;

function lua_isboolean(L: Plua_State; AIndex: Integer): Boolean; inline;
begin
  Result := lua_type(L, AIndex) = LUA_TBOOLEAN;
end;

function lua_isthread(L: Plua_State; AIndex: Integer): Boolean; inline;
begin
  Result := lua_type(L, AIndex) = LUA_TTHREAD;
end;

function lua_islightuserdata(L: Plua_State; AIndex: Integer): Boolean; inline;
begin
  Result := lua_type(L, AIndex) = LUA_TLIGHTUSERDATA;
end;

function lua_isnone(L: Plua_State; AIndex: Integer): Boolean; inline;
begin
  Result := lua_type(L, AIndex) = LUA_TNONE;
end;

function lua_isnoneornil(L: Plua_State; AIndex: Integer): Boolean; inline;
begin
  Result := lua_type(L, AIndex) <= LUA_TNIL;
end;

procedure lua_getglobal(L: Plua_State; AName: PChar); inline;
begin
  lua_getfield(L, LUA_GLOBALSINDEX, AName);
end;

procedure lua_setglobal(L: Plua_State; AName: PChar); inline;
begin
  lua_setfield(L, LUA_GLOBALSINDEX, AName);
end;

function lua_tostring(L: Plua_State; AIndex: Integer): PChar; inline;
begin
  Result := lua_tolstring(L, AIndex, nil);
end;

procedure lua_getregistry(L: Plua_State); inline;
begin
  lua_pushvalue(L, LUA_REGISTRYINDEX);
end;

function lua_getgccount(L: Plua_State): Integer; inline;
begin
  Result := lua_gc(L, LUA_GCCOUNT, 0);
end;

procedure luaI_openlib(L: Plua_State; ALibraryName: PChar; AFunctions: PluaL_Reg; AUpvalues: Integer); inline;
begin
  luaL_openlib(L, ALibraryName, AFunctions, AUpvalues);
end;

function lua_open: Plua_State; inline;
begin
  Result := luaL_newstate;
end;

procedure lua_pushliteral(L: Plua_State; const AText: RawByteString); inline;
begin
  lua_pushlstring(L, PChar(AText), Length(AText));
end;

procedure luaL_argcheck(L: Plua_State; ACondition: Boolean; AArg: Integer; AMessage: PChar); inline;
begin
  if not ACondition then
    luaL_argerror(L, AArg, AMessage);
end;

function luaL_checkstring(L: Plua_State; AArg: Integer): PChar; inline;
begin
  Result := luaL_checklstring(L, AArg, nil);
end;

function luaL_optstring(L: Plua_State; AArg: Integer; ADefault: PChar): PChar; inline;
begin
  Result := luaL_optlstring(L, AArg, ADefault, nil);
end;

function luaL_checkint(L: Plua_State; AArg: Integer): Integer; inline;
begin
  Result := Integer(luaL_checkinteger(L, AArg));
end;

function luaL_optint(L: Plua_State; AArg, ADefault: Integer): Integer; inline;
begin
  Result := Integer(luaL_optinteger(L, AArg, ADefault));
end;

function luaL_checklong(L: Plua_State; AArg: Integer): CLong; inline;
begin
  Result := CLong(luaL_checkinteger(L, AArg));
end;

function luaL_optlong(L: Plua_State; AArg: Integer; ADefault: CLong): CLong; inline;
begin
  Result := CLong(luaL_optinteger(L, AArg, ADefault));
end;

function luaL_typename(L: Plua_State; AIndex: Integer): PChar; inline;
begin
  Result := lua_typename(L, lua_type(L, AIndex));
end;

function luaL_dofile(L: Plua_State; AFileName: PChar): Integer; inline;
begin
  Result := luaL_loadfile(L, AFileName);
  if Result = 0 then
    Result := lua_pcall(L, 0, LUA_MULTRET, 0);
end;

function luaL_dostring(L: Plua_State; ASource: PChar): Integer; inline;
begin
  Result := luaL_loadstring(L, ASource);
  if Result = 0 then
    Result := lua_pcall(L, 0, LUA_MULTRET, 0);
end;

procedure luaL_addsize(ABuffer: PluaL_Buffer; ASize: SizeUInt); inline;
begin
  Inc(ABuffer^.p, ASize);
end;

procedure luaL_addchar(ABuffer: PluaL_Buffer; AChar: AnsiChar); inline;
begin
  if PtrUInt(ABuffer^.p) >= PtrUInt(@ABuffer^.buffer[0]) + LUAL_BUFFERSIZE then
    luaL_prepbuffer(ABuffer);
  ABuffer^.p^ := AChar;
  Inc(ABuffer^.p);
end;

procedure luaL_putchar(ABuffer: PluaL_Buffer; AChar: AnsiChar); inline;
begin
  luaL_addchar(ABuffer, AChar);
end;

function luaL_getn(L: Plua_State; AIndex: Integer): Integer; inline;
begin
  Result := Integer(lua_objlen(L, AIndex));
end;

procedure luaL_setn(L: Plua_State; AIndex, ACount: Integer); inline;
begin
  // Lua 5.1's default luaL_setn macro is a no-op.
end;

function lua_ref(L: Plua_State; ALock: Boolean): Integer; inline;
begin
  if not ALock then
  begin
    lua_pushstring(L, 'unlocked references are obsolete');
    Result := lua_error(L);
  end
  else
    Result := luaL_ref(L, LUA_REGISTRYINDEX);
end;

procedure lua_unref(L: Plua_State; ARef: Integer); inline;
begin
  luaL_unref(L, LUA_REGISTRYINDEX, ARef);
end;

procedure lua_getref(L: Plua_State; ARef: Integer); inline;
begin
  lua_rawgeti(L, LUA_REGISTRYINDEX, ARef);
end;

end.

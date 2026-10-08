(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXLuaRender;

{$mode objfpc}{$H+}

interface

uses Classes, TypInfo, fpg_main, Lua51, obNXRender, obNXLuaCanvas;

type
  // Cached readable scalar properties. Tables are snapshots, never userdata.
  TNXLuaStateSchema = class
  private
    FObjectClass: TClass;
    FProperties: array of PPropInfo;
  public
    constructor Create(AClass: TClass);
    procedure Push(ALua: Plua_State; AObject: TPersistent);
    property ObjectClass: TClass read FObjectClass;
  end;

  TNXLuaRenderer = class(TNXRenderer)
  private
    FLua: Plua_State;
    FFunctionRef: Integer;
    FFunctionName: string;
    FCanvas: TNXLuaCanvas;
    FCanvasRef: Integer;
    FSchemas: TList;
    FResources: TNXRenderResources;
    FResourceSchema: TNXLuaStateSchema;
    FFunctionResolutionCount: Integer;
    function SchemaFor(AClass: TClass): TNXLuaStateSchema;
    procedure Draw(ACanvas: TfpgCanvas; AState: TNexusControlState;
      ASchema: TNXLuaStateSchema; const ARenderName: string);
  protected
    function GetSchemaCount: Integer;
    function Bind(AState: TNexusControlState): TNXRenderSubscription; override;
  public
    // Borrows VM and canvas; takes ownership of AResources, including on failure.
    constructor Create(ALua: Plua_State; const AFunctionName: string;
      AStateClass: TPersistentClass; ACanvas: TNXLuaCanvas;
      ACanvasRef: Integer; AResources: TNXRenderResources = nil);
    destructor Destroy; override;
    property FunctionResolutionCount: Integer read FFunctionResolutionCount;
    property SchemaCount: Integer read GetSchemaCount;
  end;

implementation

uses SysUtils, Math;

type
  TNXLuaRenderSubscription = class(TNXRenderSubscription)
  private
    FRenderer: TNXLuaRenderer;
    FState: TNexusControlState;
    FSchema: TNXLuaStateSchema;
  protected
    procedure DoRender(ACanvas: TfpgCanvas); override;
    procedure Invalidate; override;
  public
    constructor Create(ARenderer: TNXLuaRenderer; AState: TNexusControlState;
      ASchema: TNXLuaStateSchema);
  end;

constructor TNXLuaStateSchema.Create(AClass: TClass);
var
  lProperties: PPropList;
  lCount, lIndex: Integer;
  lProperty: PPropInfo;
begin
  inherited Create;
  FObjectClass := AClass;
  lCount := GetPropList(AClass, lProperties);
  try
    SetLength(FProperties, lCount);
    for lIndex := 0 to lCount - 1 do
    begin
      lProperty := lProperties^[lIndex];
      if (lProperty^.GetProc = nil) or
        not (lProperty^.PropType^.Kind in [tkInteger, tkBool, tkEnumeration,
          tkFloat, tkSString, tkAString, tkLString, tkWString, tkUString]) then
        raise Exception.CreateFmt('Unsupported or unreadable Lua state property %s.%s (%s).',
          [AClass.ClassName, lProperty^.Name,
           GetEnumName(TypeInfo(TTypeKind), Ord(lProperty^.PropType^.Kind))]);
      if (lProperty^.PropType^.Kind = tkFloat) and
        not (GetTypeData(lProperty^.PropType)^.FloatType in [ftSingle, ftDouble]) then
        raise Exception.CreateFmt('Lua state property %s.%s must use Single or Double.',
          [AClass.ClassName, lProperty^.Name]);
      FProperties[lIndex] := lProperty;
    end;
  finally
    FreeMem(lProperties);
  end;
end;

procedure TNXLuaStateSchema.Push(ALua: Plua_State; AObject: TPersistent);
var
  lIndex: Integer;
  lProperty: PPropInfo;
  lText: UTF8String;
begin
  lua_createtable(ALua, 0, Length(FProperties));
  for lIndex := 0 to High(FProperties) do
  begin
    lProperty := FProperties[lIndex];
    case lProperty^.PropType^.Kind of
      tkInteger:
        if GetTypeData(lProperty^.PropType)^.OrdType = otULong then
          // FPC 3.2.2 GetOrdProp sign-extends unsigned 32-bit properties.
          lua_pushnumber(ALua, LongWord(GetOrdProp(AObject, lProperty)))
        else
          lua_pushnumber(ALua, GetOrdProp(AObject, lProperty));
      tkBool: lua_pushboolean(ALua, Ord(GetOrdProp(AObject, lProperty) <> 0));
      tkFloat: lua_pushnumber(ALua, GetFloatProp(AObject, lProperty));
      else
      begin
        case lProperty^.PropType^.Kind of
          tkEnumeration:
            lText := UTF8String(GetEnumName(lProperty^.PropType, GetOrdProp(AObject, lProperty)));
          tkWString: lText := UTF8Encode(GetWideStrProp(AObject, lProperty));
          tkUString: lText := UTF8Encode(GetUnicodeStrProp(AObject, lProperty));
          else lText := UTF8String(GetStrProp(AObject, lProperty));
        end;
        lua_pushlstring(ALua, PChar(lText), Length(lText));
      end;
    end;
    lua_setfield(ALua, -2, PChar(string(lProperty^.Name)));
  end;
end;

constructor TNXLuaRenderSubscription.Create(ARenderer: TNXLuaRenderer;
  AState: TNexusControlState; ASchema: TNXLuaStateSchema);
begin
  inherited Create;
  FRenderer := ARenderer;
  FState := AState;
  FSchema := ASchema;
end;

procedure TNXLuaRenderSubscription.DoRender(ACanvas: TfpgCanvas);
begin
  FRenderer.Draw(ACanvas, FState, FSchema, Name);
end;

procedure TNXLuaRenderSubscription.Invalidate;
begin
  FRenderer := nil;
  FState := nil;
  FSchema := nil;
  inherited Invalidate;
end;

constructor TNXLuaRenderer.Create(ALua: Plua_State;
  const AFunctionName: string; AStateClass: TPersistentClass;
  ACanvas: TNXLuaCanvas; ACanvasRef: Integer; AResources: TNXRenderResources);
var
  lTop: Integer;
  lMask: TFPUExceptionMask;
begin
  FFunctionRef := LUA_NOREF;
  FResources := AResources;
  inherited Create(AStateClass);
  if (ALua = nil) or (ACanvas = nil) then
    raise Exception.Create('Lua renderer requires a live VM and canvas bridge.');
  FLua := ALua;
  FCanvas := ACanvas;
  FCanvasRef := ACanvasRef;
  FFunctionName := AFunctionName;
  FSchemas := TList.Create;
  lTop := lua_gettop(FLua);
  lMask := GetExceptionMask;
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide,
    exOverflow, exUnderflow, exPrecision]);
  try
    Inc(FFunctionResolutionCount);
    lua_getglobal(FLua, PChar(AFunctionName));
    if not lua_isfunction(FLua, -1) then
      raise Exception.CreateFmt('Lua renderer function "%s" is missing or not callable.', [AFunctionName]);
    FFunctionRef := luaL_ref(FLua, LUA_REGISTRYINDEX);
    if FResources <> nil then
      FResourceSchema := SchemaFor(FResources.ClassType);
  finally
    lua_settop(FLua, lTop);
    SetExceptionMask(lMask);
  end;
end;

destructor TNXLuaRenderer.Destroy;
var
  lIndex: Integer;
begin
  if (FLua <> nil) and (FFunctionRef <> LUA_NOREF) then
    luaL_unref(FLua, LUA_REGISTRYINDEX, FFunctionRef);
  if FSchemas <> nil then
    for lIndex := 0 to FSchemas.Count - 1 do
      TObject(FSchemas[lIndex]).Free;
  FSchemas.Free;
  FResources.Free;
  inherited Destroy;
end;

function TNXLuaRenderer.GetSchemaCount: Integer;
begin
  Result := FSchemas.Count;
end;

function TNXLuaRenderer.SchemaFor(AClass: TClass): TNXLuaStateSchema;
var
  lIndex: Integer;
begin
  for lIndex := 0 to FSchemas.Count - 1 do
  begin
    Result := TNXLuaStateSchema(FSchemas[lIndex]);
    if Result.ObjectClass = AClass then
      Exit;
  end;
  Result := TNXLuaStateSchema.Create(AClass);
  try
    FSchemas.Add(Result);
  except
    Result.Free;
    raise;
  end;
end;

function TNXLuaRenderer.Bind(AState: TNexusControlState): TNXRenderSubscription;
begin
  Result := TNXLuaRenderSubscription.Create(Self, AState, SchemaFor(AState.ClassType));
end;

procedure TNXLuaRenderer.Draw(ACanvas: TfpgCanvas; AState: TNexusControlState;
  ASchema: TNXLuaStateSchema; const ARenderName: string);
var
  lTop: Integer;
  lMask: TFPUExceptionMask;
begin
  lTop := lua_gettop(FLua);
  lMask := GetExceptionMask;
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide,
    exOverflow, exUnderflow, exPrecision]);
  try
    FCanvas.AttachCanvas(ACanvas);
    lua_rawgeti(FLua, LUA_REGISTRYINDEX, FFunctionRef);
    lua_rawgeti(FLua, LUA_REGISTRYINDEX, FCanvasRef);
    ASchema.Push(FLua, AState);
    if FResources = nil then
      lua_pushnil(FLua)
    else
    begin
      FResources.Prepare(ARenderName, AState);
      FResourceSchema.Push(FLua, FResources);
    end;
    if lua_pcall(FLua, 3, 0, 0) <> 0 then
      raise Exception.CreateFmt('Lua renderer "%s" failed: %s',
        [FFunctionName, string(lua_tostring(FLua, -1))]);
  finally
    FCanvas.AttachCanvas(nil);
    lua_settop(FLua, lTop);
    SetExceptionMask(lMask);
  end;
end;

end.

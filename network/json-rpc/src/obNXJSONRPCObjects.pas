(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXJSONRPCObjects;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  TypInfo,
  fpjson,
  obNXJSONValues;

type
  TNXJSONRPCValue = TNXJSONValue;
  TNXJSONRPCValueClass = TNXJSONValueClass;
  TNXJSONRPCValueClassArray = array of TNXJSONRPCValueClass;

  TNXJSONRPCString = class(TNXJSONString)
  end;

  TNXJSONRPCBoolean = class(TNXJSONBoolean)
  end;

  TNXJSONRPCInteger = class(TNXJSONInteger)
  end;

  TNXJSONRPCUnknown = class(TNXJSONRPCValue)
  end;

  TNXJSONRPCArrayParams = class(TNXJSONArray)
  end;

  TNXJSONRPCObjectParams = class(TNXJSONObject)
  end;

  TNXJSONRPCPositionalParams = class(TNXJSONArray)
  protected
    procedure AutoCreateJSONProperties; virtual;
    procedure ClearJSONProperties; virtual;
    procedure FreeJSONProperties; virtual;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Clear; override;
    function ToJSONData: TJSONData; override;
    procedure FromJSONData(AData: TJSONData); override;
  end;

  TNXJSONRPCVariant = class(TNXJSONRPCValue)
  private
    FValue: TNXJSONRPCValue;
    function GetIntegerValue: Int64;
    function GetIsInteger: Boolean;
    function GetStringValue: UTF8String;
    procedure SetValue(AValue: TNXJSONRPCValue);
  protected
    class function ValueClassForJSON(AData: TJSONData): TNXJSONRPCValueClass; virtual;
    class function SupportsValueClass(AClass: TNXJSONRPCValueClass): Boolean; virtual;
    class function SupportedValueClasses: TNXJSONRPCValueClassArray; virtual;
  public
    destructor Destroy; override;
    procedure Clear; override;
    function ToJSONData: TJSONData; override;
    procedure FromJSONData(AData: TJSONData); override;
    function AsString: UTF8String; override;
    function AsInteger: Integer; override;
    function AsInt64: Int64; override;
    procedure SetIntegerValue(const AValue: Int64);
    procedure SetStringValue(const AValue: UTF8String);
    property IntegerValue: Int64 read GetIntegerValue write SetIntegerValue;
    property IsInteger: Boolean read GetIsInteger;
    property StringValue: UTF8String read GetStringValue write SetStringValue;
    property Value: TNXJSONRPCValue read FValue write SetValue;
  end;

  TNXJSONRPCID = class(TNXJSONRPCVariant)
  public
    constructor Create; override;
  end;

implementation

function GetPropInfoType(APropInfo: PPropInfo): PTypeInfo;
begin
  Result := APropInfo^.PropType;
end;

function IsJSONValueClass(AClass: TClass): Boolean;
begin
  Result := (AClass <> nil) and AClass.InheritsFrom(TNXJSONValue);
end;

procedure AutoCreateJSONProperties(AInstance: TObject);
var
  lList: PPropList;
  lCount: Integer;
  lIdx: Integer;
  lPropInfo: PPropInfo;
  lTypeInfo: PTypeInfo;
  lClass: TClass;
begin
  lCount := GetPropList(PTypeInfo(AInstance.ClassInfo), [tkClass], nil);
  if lCount <= 0 then
    Exit;

  GetMem(lList, lCount * SizeOf(Pointer));
  try
    GetPropList(PTypeInfo(AInstance.ClassInfo), [tkClass], lList);

    for lIdx := 0 to lCount - 1 do
    begin
      lPropInfo := lList^[lIdx];
      if GetObjectProp(AInstance, lPropInfo) <> nil then
        Continue;

      lTypeInfo := GetPropInfoType(lPropInfo);
      if lTypeInfo = nil then
        Continue;

      lClass := GetTypeData(lTypeInfo)^.ClassType;
      if not IsJSONValueClass(lClass) then
        Continue;

      SetObjectProp(AInstance, lPropInfo, TNXJSONValueClass(lClass).Create);
    end;
  finally
    FreeMem(lList);
  end;
end;

procedure ClearJSONProperties(AInstance: TObject);
var
  lList: PPropList;
  lCount: Integer;
  lIdx: Integer;
  lValue: TObject;
begin
  lCount := GetPropList(PTypeInfo(AInstance.ClassInfo), [tkClass], nil);
  if lCount <= 0 then
    Exit;

  GetMem(lList, lCount * SizeOf(Pointer));
  try
    GetPropList(PTypeInfo(AInstance.ClassInfo), [tkClass], lList);

    for lIdx := 0 to lCount - 1 do
    begin
      lValue := GetObjectProp(AInstance, lList^[lIdx]);
      if lValue is TNXJSONValue then
        TNXJSONValue(lValue).Clear;
    end;
  finally
    FreeMem(lList);
  end;
end;

procedure FreeJSONProperties(AInstance: TObject);
var
  lList: PPropList;
  lCount: Integer;
  lIdx: Integer;
  lValue: TObject;
begin
  lCount := GetPropList(PTypeInfo(AInstance.ClassInfo), [tkClass], nil);
  if lCount <= 0 then
    Exit;

  GetMem(lList, lCount * SizeOf(Pointer));
  try
    GetPropList(PTypeInfo(AInstance.ClassInfo), [tkClass], lList);

    for lIdx := 0 to lCount - 1 do
    begin
      lValue := GetObjectProp(AInstance, lList^[lIdx]);
      if lValue is TNXJSONValue then
      begin
        SetObjectProp(AInstance, lList^[lIdx], nil);
        lValue.Free;
      end;
    end;
  finally
    FreeMem(lList);
  end;
end;

constructor TNXJSONRPCPositionalParams.Create;
begin
  inherited Create;
  AutoCreateJSONProperties;
end;

destructor TNXJSONRPCPositionalParams.Destroy;
begin
  FreeJSONProperties;
  inherited Destroy;
end;

procedure TNXJSONRPCPositionalParams.AutoCreateJSONProperties;
begin
  obNXJSONRPCObjects.AutoCreateJSONProperties(Self);
end;

procedure TNXJSONRPCPositionalParams.ClearJSONProperties;
begin
  obNXJSONRPCObjects.ClearJSONProperties(Self);
end;

procedure TNXJSONRPCPositionalParams.FreeJSONProperties;
begin
  obNXJSONRPCObjects.FreeJSONProperties(Self);
end;

procedure TNXJSONRPCPositionalParams.Clear;
begin
  inherited Clear;
  ClearJSONProperties;
end;

function TNXJSONRPCPositionalParams.ToJSONData: TJSONData;
var
  lArray: TJSONArray;
  lList: PPropList;
  lCount: Integer;
  lIdx: Integer;
  lValue: TObject;
  lJSONValue: TNXJSONValue;
begin
  lArray := TJSONArray.Create;
  try
    lCount := GetPropList(PTypeInfo(Self.ClassInfo), [tkClass], nil);
    if lCount > 0 then
    begin
      GetMem(lList, lCount * SizeOf(Pointer));
      try
        GetPropList(PTypeInfo(Self.ClassInfo), [tkClass], lList);
        for lIdx := 0 to lCount - 1 do
        begin
          lValue := GetObjectProp(Self, lList^[lIdx]);
          if not (lValue is TNXJSONValue) then
            Continue;

          lJSONValue := TNXJSONValue(lValue);
          if lJSONValue.Assigned then
            lArray.Add(lJSONValue.ToJSONData)
          else
            lArray.Add(TJSONNull.Create);
        end;
      finally
        FreeMem(lList);
      end;
    end;

    Result := lArray;
  except
    lArray.Free;
    raise;
  end;
end;

procedure TNXJSONRPCPositionalParams.FromJSONData(AData: TJSONData);
var
  lArray: TJSONArray;
  lList: PPropList;
  lCount: Integer;
  lIdx: Integer;
  lValue: TObject;
begin
  if HandleNullFromJSONData(AData) then
    Exit;

  if AData.JSONType <> jtArray then
    raise ENXJSON.Create('Expected JSON-RPC positional params array.');

  Clear;

  SetNotNull;
  lArray := TJSONArray(AData);
  lCount := GetPropList(PTypeInfo(Self.ClassInfo), [tkClass], nil);
  if lCount > 0 then
  begin
    GetMem(lList, lCount * SizeOf(Pointer));
    try
      GetPropList(PTypeInfo(Self.ClassInfo), [tkClass], lList);
      if lArray.Count > lCount then
        raise ENXJSON.CreateFmt('Too many positional params for %s.', [ClassName]);

      for lIdx := 0 to lArray.Count - 1 do
      begin
        lValue := GetObjectProp(Self, lList^[lIdx]);
        if lValue is TNXJSONValue then
          TNXJSONValue(lValue).FromJSONData(lArray.Items[lIdx]);
      end;
    finally
      FreeMem(lList);
    end;
  end
  else if lArray.Count > 0 then
    raise ENXJSON.CreateFmt('No positional params are defined for %s.', [ClassName]);

  Assigned := True;
  SetJSONType(nxjtArray);
end;

destructor TNXJSONRPCVariant.Destroy;
begin
  FreeAndNil(FValue);
  inherited Destroy;
end;

procedure TNXJSONRPCVariant.Clear;
begin
  FreeAndNil(FValue);
  inherited Clear;
end;

function TNXJSONRPCVariant.ToJSONData: TJSONData;
begin
  if IsNull then
    Exit(TJSONNull.Create);

  if FValue = nil then
    raise ENXJSON.Create('JSON-RPC variant value is not assigned.');

  Result := FValue.ToJSONData;
end;

procedure TNXJSONRPCVariant.FromJSONData(AData: TJSONData);
var
  lClass: TNXJSONRPCValueClass;
  lValue: TNXJSONRPCValue;
begin
  if HandleNullFromJSONData(AData) then
    Exit;

  lClass := ValueClassForJSON(AData);
  if lClass = nil then
    raise ENXJSON.Create('JSON-RPC variant does not support this JSON value.');

  lValue := lClass.Create;
  try
    lValue.FromJSONData(AData);
    SetValue(lValue);
    lValue := nil;
  finally
    lValue.Free;
  end;
end;

class function TNXJSONRPCVariant.ValueClassForJSON(AData: TJSONData): TNXJSONRPCValueClass;
var
  lClass: TNXJSONRPCValueClass;
begin
  if AData = nil then
    lClass := TNXJSONRPCValue
  else
    case AData.JSONType of
      jtNull:
        lClass := TNXJSONNull;
      jtString:
        lClass := TNXJSONString;
      jtNumber:
        if Pos('.', AData.AsJSON) > 0 then
          lClass := TNXJSONFloat
        else
          lClass := TNXJSONInteger;
      jtBoolean:
        lClass := TNXJSONBoolean;
      jtArray:
        lClass := TNXJSONArray;
      jtObject:
        lClass := TNXJSONObject;
    else
      lClass := TNXJSONRPCValue;
    end;

  if SupportsValueClass(lClass) then
    Result := lClass
  else
    Result := nil;
end;

class function TNXJSONRPCVariant.SupportsValueClass(AClass: TNXJSONRPCValueClass): Boolean;
var
  lClasses: TNXJSONRPCValueClassArray;
  lIdx: Integer;
begin
  Result := False;
  if AClass = nil then
    Exit;

  lClasses := SupportedValueClasses;
  for lIdx := Low(lClasses) to High(lClasses) do
    if (lClasses[lIdx] <> nil) and AClass.InheritsFrom(lClasses[lIdx]) then
      Exit(True);
end;

class function TNXJSONRPCVariant.SupportedValueClasses: TNXJSONRPCValueClassArray;
begin
  Result := nil;
  SetLength(Result, 2);
  Result[0] := TNXJSONString;
  Result[1] := TNXJSONInteger;
end;

function TNXJSONRPCVariant.AsString: UTF8String;
begin
  if IsNull then
    raise ENXJSON.Create('JSON value is null.');

  if FValue = nil then
    Result := ''
  else
    Result := FValue.AsString;
end;

function TNXJSONRPCVariant.AsInteger: Integer;
begin
  Result := Integer(AsInt64);
end;

function TNXJSONRPCVariant.AsInt64: Int64;
begin
  if IsNull then
    raise ENXJSON.Create('JSON value is null.');

  if FValue = nil then
    raise ENXJSON.Create('JSON-RPC variant value is not assigned.');

  Result := FValue.AsInt64;
end;

function TNXJSONRPCVariant.GetIntegerValue: Int64;
begin
  Result := AsInt64;
end;

function TNXJSONRPCVariant.GetIsInteger: Boolean;
begin
  Result := FValue is TNXJSONInteger;
end;

function TNXJSONRPCVariant.GetStringValue: UTF8String;
begin
  Result := AsString;
end;

procedure TNXJSONRPCVariant.SetValue(AValue: TNXJSONRPCValue);
begin
  if AValue = nil then
  begin
    Clear;
    Exit;
  end;

  if not SupportsValueClass(TNXJSONRPCValueClass(AValue.ClassType)) then
    raise ENXJSON.CreateFmt('%s does not support %s.', [ClassName, AValue.ClassName]);

  FreeAndNil(FValue);
  FValue := AValue;
  SetNotNull;
  Assigned := True;
  SetJSONType(FValue.JSONType);
end;

procedure TNXJSONRPCVariant.SetIntegerValue(const AValue: Int64);
var
  lValue: TNXJSONInteger;
begin
  lValue := TNXJSONInteger.Create;
  try
    lValue.Value := AValue;
    SetValue(lValue);
    lValue := nil;
  finally
    lValue.Free;
  end;
end;

procedure TNXJSONRPCVariant.SetStringValue(const AValue: UTF8String);
var
  lValue: TNXJSONString;
begin
  lValue := TNXJSONString.Create;
  try
    lValue.Value := AValue;
    SetValue(lValue);
    lValue := nil;
  finally
    lValue.Free;
  end;
end;

constructor TNXJSONRPCID.Create;
begin
  inherited Create;
  AcceptsNull := True;
end;

end.

(*
  Copyright (c) 2026 Kevin Collins.
  
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  
  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.
  
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXJSONValues;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  TypInfo,
  Contnrs,
  fpjson,
  obNXClassFactory;

type
  ENXJSON = class(Exception);

  TNXJSONType = (
    nxjtUnassigned,
    nxjtNull,
    nxjtString,
    nxjtInteger,
    nxjtFloat,
    nxjtBoolean,
    nxjtObject,
    nxjtArray,
    nxjtRaw
  );

  TNXJSONValue = class;
  TNXJSONValueClass = class of TNXJSONValue;
  TNXJSONObject = class;
  TNXJSONObjectClass = class of TNXJSONObject;

  TNXJSONValue = class(TNXFactoryObject)
  private
    FAssigned: Boolean;
    FAcceptsNull: Boolean;
    FIsNull: Boolean;
    FJSONType: TNXJSONType;
    FRaw: TJSONData;
  protected
    function HandleNullFromJSONData(AData: TJSONData): Boolean;
    procedure SetAssigned(const AValue: Boolean);
    procedure SetJSONType(const AValue: TNXJSONType);
    procedure SetNotNull;
    procedure SetRaw(AValue: TJSONData);
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure Clear; virtual;
    procedure Assign(Source: TPersistent); override;

    class function JSONTypeForData(AData: TJSONData): TNXJSONType;
    function ToJSONData: TJSONData; virtual;
    procedure FromJSONData(AData: TJSONData); virtual;

    function AsString: UTF8String; virtual;
    function AsInteger: Integer; virtual;
    function AsInt64: Int64; virtual;
    function AsFloat: Double; virtual;
    function AsBoolean: Boolean; virtual;
    function AsObject: TNXJSONObject; virtual;
    procedure SetNull;

    property Assigned: Boolean read FAssigned write SetAssigned;
    property AcceptsNull: Boolean read FAcceptsNull write FAcceptsNull;
    property IsNull: Boolean read FIsNull;
    property JSONType: TNXJSONType read FJSONType;
  end;

  TNXJSONNull = class(TNXJSONValue)
  public
    constructor Create; override;
    function ToJSONData: TJSONData; override;
    procedure FromJSONData(AData: TJSONData); override;
  end;

  TNXJSONString = class(TNXJSONValue)
  private
    FValue: UTF8String;
  public
    constructor Create; override;
    procedure Clear; override;
    function ToJSONData: TJSONData; override;
    procedure FromJSONData(AData: TJSONData); override;
    function AsString: UTF8String; override;
    procedure SetValue(const AValue: UTF8String);
    property Value: UTF8String read FValue write SetValue;
  end;

  TNXJSONInteger = class(TNXJSONValue)
  private
    FValue: Int64;
  public
    constructor Create; override;
    procedure Clear; override;
    function ToJSONData: TJSONData; override;
    procedure FromJSONData(AData: TJSONData); override;
    function AsInteger: Integer; override;
    function AsInt64: Int64; override;
    procedure SetValue(const AValue: Int64);
    property Value: Int64 read FValue write SetValue;
  end;

  TNXJSONFloat = class(TNXJSONValue)
  private
    FValue: Double;
  public
    constructor Create; override;
    procedure Clear; override;
    function ToJSONData: TJSONData; override;
    procedure FromJSONData(AData: TJSONData); override;
    function AsFloat: Double; override;
    procedure SetValue(const AValue: Double);
    property Value: Double read FValue write SetValue;
  end;

  TNXJSONBoolean = class(TNXJSONValue)
  private
    FValue: Boolean;
  public
    constructor Create; override;
    procedure Clear; override;
    function ToJSONData: TJSONData; override;
    procedure FromJSONData(AData: TJSONData); override;
    function AsBoolean: Boolean; override;
    procedure SetValue(const AValue: Boolean);
    property Value: Boolean read FValue write SetValue;
  end;

  TNXJSONArray = class(TNXJSONValue)
  private
    FItems: TObjectList;
    function GetCount: Integer;
    function GetItem(const AIndex: Integer): TNXJSONValue;
  protected
    function CreateItemForJSON(AData: TJSONData): TNXJSONValue; virtual;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Clear; override;

    class function ItemClass: TNXJSONValueClass; virtual;

    function Add(AItem: TNXJSONValue): TNXJSONValue;
    function AddString(const AValue: UTF8String): TNXJSONString;
    function AddInteger(const AValue: Int64): TNXJSONInteger;
    function AddFloat(const AValue: Double): TNXJSONFloat;
    function AddBoolean(const AValue: Boolean): TNXJSONBoolean;
    function AddObject(AObjectClass: TNXJSONObjectClass): TNXJSONObject;

    function ToJSONData: TJSONData; override;
    procedure FromJSONData(AData: TJSONData); override;

    property Count: Integer read GetCount;
    property Items[const AIndex: Integer]: TNXJSONValue read GetItem; default;
  end;

  TNXJSONObject = class(TNXJSONValue)
  private
    function GetJSONProperty(const AName: string): TNXJSONValue;
  protected
    procedure AutoCreateJSONProperties; virtual;
    procedure ClearJSONProperties; virtual;
    procedure FreeJSONProperties; virtual;
    class function JSONValueClassForData(AData: TJSONData): TNXJSONValueClass;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Clear; override;

    function ToJSONData: TJSONData; override;
    procedure FromJSONData(AData: TJSONData); override;
    function AsObject: TNXJSONObject; override;

    function HasValue(const AName: string): Boolean;
    function ValueByName(const AName: string): TNXJSONValue;
  end;

implementation

function GetPropInfoType(APropInfo: PPropInfo): PTypeInfo;
begin
  Result := APropInfo^.PropType;
end;

function GetPropInfoName(APropInfo: PPropInfo): string;
begin
  Result := APropInfo^.Name;
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

function HasAssignedJSONProperties(AInstance: TObject): Boolean;
var
  lList: PPropList;
  lCount: Integer;
  lIdx: Integer;
  lValue: TObject;
begin
  Result := False;
  lCount := GetPropList(PTypeInfo(AInstance.ClassInfo), [tkClass], nil);
  if lCount <= 0 then
    Exit;

  GetMem(lList, lCount * SizeOf(Pointer));
  try
    GetPropList(PTypeInfo(AInstance.ClassInfo), [tkClass], lList);

    for lIdx := 0 to lCount - 1 do
    begin
      lValue := GetObjectProp(AInstance, lList^[lIdx]);
      if not (lValue is TNXJSONValue) then
        Continue;

      if TNXJSONValue(lValue).Assigned then
        Exit(True);

      if (lValue is TNXJSONObject) and HasAssignedJSONProperties(lValue) then
        Exit(True);
    end;
  finally
    FreeMem(lList);
  end;
end;

constructor TNXJSONValue.Create;
begin
  inherited Create;
  FJSONType := nxjtUnassigned;
end;

destructor TNXJSONValue.Destroy;
begin
  FreeAndNil(FRaw);
  inherited Destroy;
end;

procedure TNXJSONValue.SetAssigned(const AValue: Boolean);
begin
  FAssigned := AValue;
end;

procedure TNXJSONValue.SetJSONType(const AValue: TNXJSONType);
begin
  FJSONType := AValue;
end;

procedure TNXJSONValue.SetRaw(AValue: TJSONData);
begin
  FreeAndNil(FRaw);
  FRaw := AValue;
  FAssigned := FRaw <> nil;

  if FRaw = nil then
    FJSONType := nxjtUnassigned
  else
    FJSONType := JSONTypeForData(FRaw);
end;

procedure TNXJSONValue.Clear;
begin
  FreeAndNil(FRaw);
  FIsNull := False;
  FAssigned := False;
  FJSONType := nxjtUnassigned;
end;

procedure TNXJSONValue.Assign(Source: TPersistent);
var
  lJSON: TJSONData;
begin
  if Source is TNXJSONValue then
  begin
    lJSON := TNXJSONValue(Source).ToJSONData;
    try
      FromJSONData(lJSON);
    finally
      lJSON.Free;
    end;
  end
  else
    inherited Assign(Source);
end;

class function TNXJSONValue.JSONTypeForData(AData: TJSONData): TNXJSONType;
begin
  if AData = nil then
    Exit(nxjtUnassigned);

  case AData.JSONType of
    jtNull:
      Result := nxjtNull;
    jtString:
      Result := nxjtString;
    jtNumber:
      if Pos('.', AData.AsJSON) > 0 then
        Result := nxjtFloat
      else
        Result := nxjtInteger;
    jtBoolean:
      Result := nxjtBoolean;
    jtArray:
      Result := nxjtArray;
    jtObject:
      Result := nxjtObject;
  else
    Result := nxjtRaw;
  end;
end;

function TNXJSONValue.ToJSONData: TJSONData;
begin
  if FIsNull then
    Result := TJSONNull.Create
  else if FRaw <> nil then
    Result := FRaw.Clone
  else
    Result := TJSONNull.Create;
end;

procedure TNXJSONValue.FromJSONData(AData: TJSONData);
begin
  if HandleNullFromJSONData(AData) then
    Exit;

  if AData = nil then
    SetRaw(nil)
  else
  begin
    SetNotNull;
    SetRaw(AData.Clone);
  end;
end;

function TNXJSONValue.AsString: UTF8String;
begin
  if FRaw = nil then
    Result := ''
  else
    Result := FRaw.AsString;
end;

function TNXJSONValue.AsInteger: Integer;
begin
  Result := Integer(AsInt64);
end;

function TNXJSONValue.AsInt64: Int64;
begin
  if FRaw = nil then
    Result := 0
  else
    Result := FRaw.AsInteger;
end;

function TNXJSONValue.AsFloat: Double;
begin
  if FRaw = nil then
    Result := 0
  else
    Result := FRaw.AsFloat;
end;

function TNXJSONValue.AsBoolean: Boolean;
begin
  if FRaw = nil then
    Result := False
  else
    Result := FRaw.AsBoolean;
end;

function TNXJSONValue.AsObject: TNXJSONObject;
begin
  Result := nil;
end;

function TNXJSONValue.HandleNullFromJSONData(AData: TJSONData): Boolean;
begin
  Result := (AData = nil) or (AData.JSONType = jtNull);
  if not Result then
    Exit;

  SetNull;
end;

procedure TNXJSONValue.SetNotNull;
begin
  FIsNull := False;
end;

procedure TNXJSONValue.SetNull;
begin
  if not FAcceptsNull then
    raise ENXJSON.Create('JSON null is not allowed here.');

  Clear;
  FIsNull := True;
  FAssigned := True;
  FJSONType := nxjtNull;
end;

constructor TNXJSONNull.Create;
begin
  inherited Create;
  FJSONType := nxjtNull;
  FAssigned := True;
end;

function TNXJSONNull.ToJSONData: TJSONData;
begin
  Result := TJSONNull.Create;
end;

procedure TNXJSONNull.FromJSONData(AData: TJSONData);
begin
  if (AData <> nil) and (AData.JSONType <> jtNull) then
    raise ENXJSON.Create('Expected JSON null.');

  FAssigned := True;
  FJSONType := nxjtNull;
end;

constructor TNXJSONString.Create;
begin
  inherited Create;
  FJSONType := nxjtString;
end;

procedure TNXJSONString.Clear;
begin
  inherited Clear;
  FJSONType := nxjtString;
  FValue := '';
end;

function TNXJSONString.ToJSONData: TJSONData;
begin
  if IsNull then
    Result := TJSONNull.Create
  else
    Result := TJSONString.Create(FValue);
end;

procedure TNXJSONString.FromJSONData(AData: TJSONData);
begin
  if HandleNullFromJSONData(AData) then
    Exit;

  if AData.JSONType <> jtString then
    raise ENXJSON.Create('Expected JSON string.');

  SetNotNull;
  FValue := AData.AsString;
  FAssigned := True;
  FJSONType := nxjtString;
end;

function TNXJSONString.AsString: UTF8String;
begin
  Result := FValue;
end;

procedure TNXJSONString.SetValue(const AValue: UTF8String);
begin
  FValue := AValue;
  SetNotNull;
  FAssigned := True;
  FJSONType := nxjtString;
end;

constructor TNXJSONInteger.Create;
begin
  inherited Create;
  FJSONType := nxjtInteger;
end;

procedure TNXJSONInteger.Clear;
begin
  inherited Clear;
  FJSONType := nxjtInteger;
  FValue := 0;
end;

function TNXJSONInteger.ToJSONData: TJSONData;
begin
  if IsNull then
    Result := TJSONNull.Create
  else
    Result := TJSONIntegerNumber.Create(FValue);
end;

procedure TNXJSONInteger.FromJSONData(AData: TJSONData);
begin
  if HandleNullFromJSONData(AData) then
    Exit;

  if AData.JSONType <> jtNumber then
    raise ENXJSON.Create('Expected JSON integer.');

  SetNotNull;
  FValue := AData.AsInteger;
  FAssigned := True;
  FJSONType := nxjtInteger;
end;

function TNXJSONInteger.AsInteger: Integer;
begin
  Result := Integer(FValue);
end;

function TNXJSONInteger.AsInt64: Int64;
begin
  Result := FValue;
end;

procedure TNXJSONInteger.SetValue(const AValue: Int64);
begin
  FValue := AValue;
  SetNotNull;
  FAssigned := True;
  FJSONType := nxjtInteger;
end;

constructor TNXJSONFloat.Create;
begin
  inherited Create;
  FJSONType := nxjtFloat;
end;

procedure TNXJSONFloat.Clear;
begin
  inherited Clear;
  FJSONType := nxjtFloat;
  FValue := 0;
end;

function TNXJSONFloat.ToJSONData: TJSONData;
begin
  if IsNull then
    Result := TJSONNull.Create
  else
    Result := TJSONFloatNumber.Create(FValue);
end;

procedure TNXJSONFloat.FromJSONData(AData: TJSONData);
begin
  if HandleNullFromJSONData(AData) then
    Exit;

  if AData.JSONType <> jtNumber then
    raise ENXJSON.Create('Expected JSON float.');

  SetNotNull;
  FValue := AData.AsFloat;
  FAssigned := True;
  FJSONType := nxjtFloat;
end;

function TNXJSONFloat.AsFloat: Double;
begin
  Result := FValue;
end;

procedure TNXJSONFloat.SetValue(const AValue: Double);
begin
  FValue := AValue;
  SetNotNull;
  FAssigned := True;
  FJSONType := nxjtFloat;
end;

constructor TNXJSONBoolean.Create;
begin
  inherited Create;
  FJSONType := nxjtBoolean;
end;

procedure TNXJSONBoolean.Clear;
begin
  inherited Clear;
  FJSONType := nxjtBoolean;
  FValue := False;
end;

function TNXJSONBoolean.ToJSONData: TJSONData;
begin
  if IsNull then
    Result := TJSONNull.Create
  else
    Result := TJSONBoolean.Create(FValue);
end;

procedure TNXJSONBoolean.FromJSONData(AData: TJSONData);
begin
  if HandleNullFromJSONData(AData) then
    Exit;

  if AData.JSONType <> jtBoolean then
    raise ENXJSON.Create('Expected JSON boolean.');

  SetNotNull;
  FValue := AData.AsBoolean;
  FAssigned := True;
  FJSONType := nxjtBoolean;
end;

function TNXJSONBoolean.AsBoolean: Boolean;
begin
  Result := FValue;
end;

procedure TNXJSONBoolean.SetValue(const AValue: Boolean);
begin
  FValue := AValue;
  SetNotNull;
  FAssigned := True;
  FJSONType := nxjtBoolean;
end;

constructor TNXJSONArray.Create;
begin
  inherited Create;
  FJSONType := nxjtArray;
  FItems := TObjectList.Create(True);
end;

destructor TNXJSONArray.Destroy;
begin
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TNXJSONArray.Clear;
begin
  inherited Clear;
  FItems.Clear;
  FAssigned := False;
  FJSONType := nxjtArray;
end;

class function TNXJSONArray.ItemClass: TNXJSONValueClass;
begin
  Result := TNXJSONValue;
end;

function TNXJSONArray.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TNXJSONArray.GetItem(const AIndex: Integer): TNXJSONValue;
begin
  Result := TNXJSONValue(FItems[AIndex]);
end;

function TNXJSONArray.Add(AItem: TNXJSONValue): TNXJSONValue;
begin
  if AItem = nil then
    raise ENXJSON.Create('Cannot add nil JSON array item.');

  FItems.Add(AItem);
  FAssigned := True;
  Result := AItem;
end;

function TNXJSONArray.AddString(const AValue: UTF8String): TNXJSONString;
begin
  Result := TNXJSONString(Add(TNXJSONString.Create));
  Result.Value := AValue;
end;

function TNXJSONArray.AddInteger(const AValue: Int64): TNXJSONInteger;
begin
  Result := TNXJSONInteger(Add(TNXJSONInteger.Create));
  Result.Value := AValue;
end;

function TNXJSONArray.AddFloat(const AValue: Double): TNXJSONFloat;
begin
  Result := TNXJSONFloat(Add(TNXJSONFloat.Create));
  Result.Value := AValue;
end;

function TNXJSONArray.AddBoolean(const AValue: Boolean): TNXJSONBoolean;
begin
  Result := TNXJSONBoolean(Add(TNXJSONBoolean.Create));
  Result.Value := AValue;
end;

function TNXJSONArray.AddObject(AObjectClass: TNXJSONObjectClass): TNXJSONObject;
begin
  if AObjectClass = nil then
    raise ENXJSON.Create('Cannot add nil JSON object class.');

  Result := TNXJSONObject(Add(AObjectClass.Create));
  Result.Assigned := True;
end;

function TNXJSONArray.CreateItemForJSON(AData: TJSONData): TNXJSONValue;
var
  lClass: TNXJSONValueClass;
begin
  lClass := ItemClass;

  if lClass = TNXJSONValue then
    lClass := TNXJSONObject.JSONValueClassForData(AData);

  Result := lClass.Create;
  Result.FromJSONData(AData);
end;

function TNXJSONArray.ToJSONData: TJSONData;
var
  lArray: TJSONArray;
  lIdx: Integer;
begin
  if IsNull then
    Exit(TJSONNull.Create);

  lArray := TJSONArray.Create;
  try
    for lIdx := 0 to FItems.Count - 1 do
      lArray.Add(TNXJSONValue(FItems[lIdx]).ToJSONData);

    Result := lArray;
  except
    lArray.Free;
    raise;
  end;
end;

procedure TNXJSONArray.FromJSONData(AData: TJSONData);
var
  lArray: TJSONArray;
  lIdx: Integer;
begin
  if HandleNullFromJSONData(AData) then
    Exit;

  if AData.JSONType <> jtArray then
    raise ENXJSON.Create('Expected JSON array.');

  Clear;

  SetNotNull;
  lArray := TJSONArray(AData);
  for lIdx := 0 to lArray.Count - 1 do
    Add(CreateItemForJSON(lArray.Items[lIdx]));

  FAssigned := True;
  FJSONType := nxjtArray;
end;

constructor TNXJSONObject.Create;
begin
  inherited Create;
  FJSONType := nxjtObject;
  AutoCreateJSONProperties;
end;

destructor TNXJSONObject.Destroy;
begin
  FreeJSONProperties;
  inherited Destroy;
end;

procedure TNXJSONObject.Clear;
begin
  inherited Clear;
  ClearJSONProperties;
  FAssigned := False;
  FJSONType := nxjtObject;
end;

class function TNXJSONObject.JSONValueClassForData(AData: TJSONData): TNXJSONValueClass;
begin
  if AData = nil then
    Exit(TNXJSONValue);

  case AData.JSONType of
    jtNull:
      Result := TNXJSONNull;
    jtString:
      Result := TNXJSONString;
    jtNumber:
      if Pos('.', AData.AsJSON) > 0 then
        Result := TNXJSONFloat
      else
        Result := TNXJSONInteger;
    jtBoolean:
      Result := TNXJSONBoolean;
    jtArray:
      Result := TNXJSONArray;
    jtObject:
      Result := TNXJSONValue;
  else
    Result := TNXJSONValue;
  end;
end;

procedure TNXJSONObject.AutoCreateJSONProperties;
begin
  obNXJSONValues.AutoCreateJSONProperties(Self);
end;

procedure TNXJSONObject.ClearJSONProperties;
begin
  obNXJSONValues.ClearJSONProperties(Self);
end;

procedure TNXJSONObject.FreeJSONProperties;
begin
  obNXJSONValues.FreeJSONProperties(Self);
end;

function TNXJSONObject.GetJSONProperty(const AName: string): TNXJSONValue;
var
  lPropInfo: PPropInfo;
  lValue: TObject;
begin
  Result := nil;
  lPropInfo := GetPropInfo(Self, AName);
  if lPropInfo = nil then
    Exit;

  lValue := GetObjectProp(Self, lPropInfo);
  if lValue is TNXJSONValue then
    Result := TNXJSONValue(lValue);
end;

function TNXJSONObject.ToJSONData: TJSONData;
var
  lObject: TJSONObject;
  lList: PPropList;
  lCount: Integer;
  lIdx: Integer;
  lPropInfo: PPropInfo;
  lValue: TObject;
  lJSONValue: TNXJSONValue;
begin
  if IsNull then
    Exit(TJSONNull.Create);

  lObject := TJSONObject.Create;
  try
    lCount := GetPropList(PTypeInfo(Self.ClassInfo), [tkClass], nil);
    if lCount > 0 then
    begin
      GetMem(lList, lCount * SizeOf(Pointer));
      try
        GetPropList(PTypeInfo(Self.ClassInfo), [tkClass], lList);

        for lIdx := 0 to lCount - 1 do
        begin
          lPropInfo := lList^[lIdx];
          lValue := GetObjectProp(Self, lPropInfo);
          if not (lValue is TNXJSONValue) then
            Continue;

          lJSONValue := TNXJSONValue(lValue);
          if (not lJSONValue.Assigned) and
            ((not (lJSONValue is TNXJSONObject)) or
             (not HasAssignedJSONProperties(lJSONValue))) then
            Continue;

          lObject.Add(GetPropInfoName(lPropInfo), lJSONValue.ToJSONData);
        end;
      finally
        FreeMem(lList);
      end;
    end;

    Result := lObject;
  except
    lObject.Free;
    raise;
  end;
end;

procedure TNXJSONObject.FromJSONData(AData: TJSONData);
var
  lSource: TJSONObject;
  lIdx: Integer;
  lName: string;
  lPropValue: TNXJSONValue;
  lPropInfo: PPropInfo;
  lClass: TClass;
  lTypeInfo: PTypeInfo;
begin
  if HandleNullFromJSONData(AData) then
    Exit;

  if AData.JSONType <> jtObject then
    raise ENXJSON.Create('Expected JSON object.');

  Clear;

  SetNotNull;
  lSource := TJSONObject(AData);
  for lIdx := 0 to lSource.Count - 1 do
  begin
    lName := lSource.Names[lIdx];
    lPropValue := GetJSONProperty(lName);

    if lPropValue = nil then
    begin
      lPropInfo := GetPropInfo(Self, lName);
      if lPropInfo <> nil then
      begin
        lTypeInfo := GetPropInfoType(lPropInfo);
        if lTypeInfo <> nil then
        begin
          lClass := GetTypeData(lTypeInfo)^.ClassType;
          if IsJSONValueClass(lClass) then
          begin
            lPropValue := TNXJSONValueClass(lClass).Create;
            SetObjectProp(Self, lPropInfo, lPropValue);
          end;
        end;
      end;
    end;

    if lPropValue <> nil then
    begin
      if lPropValue.ClassType = TNXJSONValue then
      begin
        lPropInfo := GetPropInfo(Self, lName);
        if lPropInfo <> nil then
        begin
          SetObjectProp(Self, lPropInfo, nil);
          lPropValue.Free;
          lPropValue := JSONValueClassForData(lSource.Items[lIdx]).Create;
          SetObjectProp(Self, lPropInfo, lPropValue);
        end;
      end;

      lPropValue.FromJSONData(lSource.Items[lIdx]);
    end;
  end;

  FAssigned := True;
  FJSONType := nxjtObject;
end;

function TNXJSONObject.AsObject: TNXJSONObject;
begin
  Result := Self;
end;

function TNXJSONObject.HasValue(const AName: string): Boolean;
var
  lValue: TNXJSONValue;
begin
  lValue := GetJSONProperty(AName);
  Result := (lValue <> nil) and lValue.Assigned;
end;

function TNXJSONObject.ValueByName(const AName: string): TNXJSONValue;
begin
  Result := GetJSONProperty(AName);
  if Result = nil then
    raise ENXJSON.CreateFmt('JSON property "%s" does not exist on %s.', [AName, ClassName]);
end;

end.

(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXPersist;

{$mode objfpc}{$H+}
{$TYPEINFO ON}

interface

uses
  Classes,
  SysUtils,
  TypInfo,
  fpjson;

type
  TNXPersistObject = class;
  TNXPersistBinary = class;
  TNXPersistList = class;

  TNXPersistClass = class of TNXPersistObject;

  TNXPersistPropertyIterator = procedure(APropertyType: TTypeKind;
    APropInfo: PPropInfo; AUserData: Pointer) of object;
  TNXPersistPropertyValueIterator = procedure(APropertyType: TTypeKind;
    APropInfo: PPropInfo; APropValue: Variant; AUserData: Pointer) of object;

  TNXPersistObjectEvent = procedure(AObject: TNXPersistObject) of object;
  TNXPersistListStreamEvent = procedure(AObject: TNXPersistObject;
    ACurrentIndex, AItemCount: Integer) of object;

  TNXPersistObject = class(TPersistent)
  private
    FName: string;
    FOnStream: TNXPersistListStreamEvent;
    FOwnerList: TNXPersistList;
    FStoreReadOnlyProperties: Boolean;

    class function Registry: TStringList;
    class function ResolveClass(const AName: string): TNXPersistClass;
    procedure SetJSON(const AValue: string);
  protected
    function GetJSON: string; virtual;
    function GetName: string; virtual;
    procedure SetName(const AValue: string); virtual;

    class function IsPropFiltered(AFilterList: TStrings;
      const APropName: string): Boolean;

    procedure DoStreamList(AObject: TNXPersistObject; ACurrentIndex,
      AItemCount: Integer); virtual;
    procedure StreamFromJSONObject(AObject: TJSONObject); virtual;
    function StreamToJSONObject: TJSONObject; virtual;
  public
    constructor Create; reintroduce; virtual;
    destructor Destroy; override;

    class function PersistAlias: string; virtual;
    class procedure RegisterPersistClass(AClass: TNXPersistClass;
      const AAlias: string = '');
    class function CreateObjectFromName(const AName: string): TNXPersistObject;
    class function CreateObjectFromJSON(const AJSON: string): TNXPersistObject;

    function CloneSelf: TNXPersistObject;
    function Equals(ATargetObject: TNXPersistObject): Boolean; reintroduce; virtual;
    function GetFriendlyPropName(const APropName: string): string; virtual;
    function GetPropValue(const APropName: string): Variant; overload;
    procedure SetPropValue(const APropName: string; AValue: Variant);

    procedure AssignTo(ADestination: TPersistent); override;
    procedure CopyFrom(ASource: TPersistent); virtual;
    procedure CopyTo(ADestination: TPersistent); virtual;

    class procedure IterateProperties(ATypes: TTypeKinds;
      AIterator: TNXPersistPropertyIterator; AUserData: Pointer); overload;
    class procedure IterateProperties(ATypes: TTypeKinds;
      AIterator: TNXPersistPropertyIterator; AFilterList: TStrings;
      AUserData: Pointer); overload;
    procedure IteratePropValues(ATypes: TTypeKinds;
      AIterator: TNXPersistPropertyValueIterator; AUserData: Pointer); overload;
    procedure IteratePropValues(ATypes: TTypeKinds;
      AIterator: TNXPersistPropertyValueIterator; AFilterList: TStrings;
      AUserData: Pointer); overload;

    procedure LoadFromJSONFile(const AFileName: string); virtual;
    procedure SaveToJSONFile(const AFileName: string); virtual;

    property JSON: string read GetJSON write SetJSON;
    property OnStream: TNXPersistListStreamEvent read FOnStream write FOnStream;
    property OwnerList: TNXPersistList read FOwnerList write FOwnerList;
    property StoreReadOnlyProperties: Boolean read FStoreReadOnlyProperties
      write FStoreReadOnlyProperties;
  published
    property Name: string read GetName write SetName;
  end;

  TNXPersistBinary = class(TNXPersistObject)
  private
    FData: TMemoryStream;
    FEncoding: string;

    class procedure CopyStream(AInput, AOutput: TStream);
    function GetData: string;
    function GetSize: Int64;
    procedure SetData(const AValue: string);
    procedure SetEncoding(const AValue: string);
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure Clear;
    function IsEmpty: Boolean;
    procedure LoadFromStream(AStream: TStream);
    procedure SaveToStream(AStream: TStream);

    property Size: Int64 read GetSize;
  published
    property Data: string read GetData write SetData;
    property Encoding: string read FEncoding write SetEncoding;
  end;

  TNXPersistList = class(TNXPersistObject)
  private
    FItemClass: TNXPersistClass;
    FObjects: TList;
    FOnChange: TNotifyEvent;
    FOnDeleteObject: TNXPersistObjectEvent;
    FOnNewObject: TNXPersistObjectEvent;
    FOwnsObjects: Boolean;

    function GetCapacity: Integer;
    function GetCount: Integer;
    function GetItem(AIndex: Integer): TNXPersistObject;
    procedure SetCapacity(AValue: Integer);
    procedure SetCount(AValue: Integer);
    procedure SetItem(AIndex: Integer; AValue: TNXPersistObject);
  protected
    function AddObject(AClass: TNXPersistClass;
      const ADefaultName: string): TNXPersistObject;
    procedure DoChange; virtual;
    procedure DoDeleteObject(AObject: TNXPersistObject); virtual;
    procedure DoNewObject(AObject: TNXPersistObject); virtual;
    function GetItemAlias: string; virtual;
    function GetItemClass: TNXPersistClass; virtual;
    function GetUniqueName(const AName: string): string;
    function InternalAdd(AObject: TNXPersistObject): Integer; virtual;
    function InternalGetObject(const AName: string): TNXPersistObject; virtual;
    procedure InternalSetObject(const AName: string;
      AObject: TNXPersistObject); virtual;
    procedure SetItemClass(AValue: TNXPersistClass); virtual;
    procedure StreamFromJSONObject(AObject: TJSONObject); override;
    function StreamToJSONObject: TJSONObject; override;
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure Clear; virtual;
    function Add(AObject: TNXPersistObject): Integer;
    function Expand: TNXPersistList;
    function Extract(AObject: TNXPersistObject): TNXPersistObject;
    function First: TNXPersistObject;
    function IndexOf(AName: string): Integer; overload;
    function IndexOf(AObject: TNXPersistObject): Integer; overload;
    procedure Insert(AIndex: Integer; AObject: TNXPersistObject); overload;
    procedure Insert(AName: string; AObject: TNXPersistObject); overload;
    function Last: TNXPersistObject;
    function LocateByName(const AName: string;
      ACaseSensitive: Boolean = False; APartialFind: Boolean = True;
      AStartIdx: Integer = 0): Integer;
    procedure Move(ACurrentIndex, ANewIndex: Integer);
    function New: TNXPersistObject;
    procedure Pack;
    procedure Delete(AIndex: Integer); overload;
    procedure Delete(AObject: TNXPersistObject); overload;
    procedure Union(ASource: TNXPersistList);

    procedure AssignTo(ADestination: TPersistent); override;
    procedure CopyTo(ADestination: TPersistent); override;

    property Capacity: Integer read GetCapacity write SetCapacity;
    property Count: Integer read GetCount write SetCount;
    property ItemClass: TNXPersistClass read GetItemClass write SetItemClass;
    property Items[AIndex: Integer]: TNXPersistObject read GetItem write SetItem;
      default;
    property OwnsObjects: Boolean read FOwnsObjects write FOwnsObjects;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnDeleteObject: TNXPersistObjectEvent read FOnDeleteObject
      write FOnDeleteObject;
    property OnNewObject: TNXPersistObjectEvent read FOnNewObject
      write FOnNewObject;
  end;

implementation

uses
  base64,
  Variants,
  jsonparser;

const
  cPersistClass = 'Class';
  cPersistItems = 'Items';
  cPersistBinaryEncoding = 'base64';

var
  uPersistRegistry: TStringList = nil;

function JSONFind(AObject: TJSONObject; const AName: string): TJSONData;
var
  lIndex: Integer;
begin
  Result := nil;

  for lIndex := 0 to AObject.Count - 1 do
    if SameText(AObject.Names[lIndex], AName) then
    begin
      Result := AObject.Items[lIndex];
      Exit;
    end;
end;

function JSONAsString(AData: TJSONData): string;
begin
  Result := '';
  if Assigned(AData) then
    Result := AData.AsString;
end;

function JSONAsObject(AData: TJSONData): TJSONObject;
begin
  Result := nil;
  if AData is TJSONObject then
    Result := TJSONObject(AData);
end;

function JSONAsArray(AData: TJSONData): TJSONArray;
begin
  Result := nil;
  if AData is TJSONArray then
    Result := TJSONArray(AData);
end;

function ParseJSONData(const AJSON: string): TJSONData;
var
  lParser: TJSONParser;
begin
  lParser := TJSONParser.Create(AJSON, []);
  try
    Result := lParser.Parse;
  finally
    lParser.Free;
  end;
end;

function IsStoredObjectProperty(AObject: TObject; APropInfo: PPropInfo): Boolean;
var
  lObject: TObject;
begin
  Result := False;
  if APropInfo^.PropType^.Kind <> tkClass then
    Exit;

  lObject := GetObjectProp(AObject, APropInfo);
  Result := (lObject is TNXPersistObject) or (lObject is TStrings);
end;

procedure AddJSONValue(AObject: TJSONObject; const AName: string;
  AValue: TJSONData);
begin
  if AObject.IndexOfName(AName) >= 0 then
    AObject.Delete(AObject.IndexOfName(AName));
  AObject.Add(AName, AValue);
end;

{ TNXPersistObject }

constructor TNXPersistObject.Create;
begin
  inherited Create;
end;

destructor TNXPersistObject.Destroy;
begin
  inherited Destroy;
end;

procedure TNXPersistObject.AssignTo(ADestination: TPersistent);
var
  lDestination: TNXPersistObject;
begin
  if ADestination is Self.ClassType then
  begin
    lDestination := TNXPersistObject(ADestination);
    lDestination.JSON := JSON;
  end
  else
    inherited AssignTo(ADestination);
end;

function TNXPersistObject.CloneSelf: TNXPersistObject;
begin
  Result := CreateObjectFromName(PersistAlias);
  Result.Assign(Self);
end;

procedure TNXPersistObject.CopyFrom(ASource: TPersistent);
begin
  if ASource is ClassType then
    TNXPersistObject(ASource).CopyTo(Self);
end;

procedure TNXPersistObject.CopyTo(ADestination: TPersistent);
begin
  AssignTo(ADestination);
end;

class function TNXPersistObject.CreateObjectFromJSON(
  const AJSON: string): TNXPersistObject;
var
  lData: TJSONData;
  lObject: TJSONObject;
  lPersistClass: string;
begin
  lData := ParseJSONData(AJSON);
  try
    lObject := JSONAsObject(lData);
    if not Assigned(lObject) then
      raise Exception.Create('JSON root must be an object');

    lPersistClass := JSONAsString(JSONFind(lObject, cPersistClass));
    Result := CreateObjectFromName(lPersistClass);
    Result.StreamFromJSONObject(lObject);
  finally
    lData.Free;
  end;
end;

class function TNXPersistObject.CreateObjectFromName(
  const AName: string): TNXPersistObject;
var
  lClass: TNXPersistClass;
begin
  lClass := ResolveClass(AName);
  if not Assigned(lClass) then
    raise Exception.Create('Unknown persist class: ' + AName);

  Result := lClass.Create;
end;

procedure TNXPersistObject.DoStreamList(AObject: TNXPersistObject;
  ACurrentIndex, AItemCount: Integer);
begin
  if Assigned(FOnStream) then
    FOnStream(AObject, ACurrentIndex, AItemCount);
end;

function TNXPersistObject.Equals(ATargetObject: TNXPersistObject): Boolean;
begin
  Result := Assigned(ATargetObject) and (JSON = ATargetObject.JSON);
end;

function TNXPersistObject.GetFriendlyPropName(const APropName: string): string;
begin
  Result := APropName;
end;

function TNXPersistObject.GetJSON: string;
var
  lObject: TJSONObject;
begin
  lObject := StreamToJSONObject;
  try
    Result := lObject.FormatJSON;
  finally
    lObject.Free;
  end;
end;

function TNXPersistObject.GetName: string;
begin
  Result := FName;
end;

function TNXPersistObject.GetPropValue(const APropName: string): Variant;
begin
  Result := TypInfo.GetPropValue(Self, APropName);
end;

class procedure TNXPersistObject.IterateProperties(ATypes: TTypeKinds;
  AIterator: TNXPersistPropertyIterator; AUserData: Pointer);
begin
  IterateProperties(ATypes, AIterator, nil, AUserData);
end;

class procedure TNXPersistObject.IterateProperties(ATypes: TTypeKinds;
  AIterator: TNXPersistPropertyIterator; AFilterList: TStrings;
  AUserData: Pointer);
var
  lPropCount: Integer;
  lPropIndex: Integer;
  lPropList: TPropList;
  lPropInfo: PPropInfo;
begin
  lPropCount := GetPropList(ClassInfo, ATypes, @lPropList, False);
  for lPropIndex := 0 to lPropCount - 1 do
  begin
    lPropInfo := lPropList[lPropIndex];
    if not IsPropFiltered(AFilterList, lPropInfo^.Name) then
      AIterator(lPropInfo^.PropType^.Kind, lPropInfo, AUserData);
  end;
end;

procedure TNXPersistObject.IteratePropValues(ATypes: TTypeKinds;
  AIterator: TNXPersistPropertyValueIterator; AUserData: Pointer);
begin
  IteratePropValues(ATypes, AIterator, nil, AUserData);
end;

procedure TNXPersistObject.IteratePropValues(ATypes: TTypeKinds;
  AIterator: TNXPersistPropertyValueIterator; AFilterList: TStrings;
  AUserData: Pointer);
var
  lPropCount: Integer;
  lPropIndex: Integer;
  lPropList: TPropList;
  lPropInfo: PPropInfo;
begin
  lPropCount := GetPropList(ClassInfo, ATypes, @lPropList, False);
  for lPropIndex := 0 to lPropCount - 1 do
  begin
    lPropInfo := lPropList[lPropIndex];
    if not IsPropFiltered(AFilterList, lPropInfo^.Name) then
      AIterator(lPropInfo^.PropType^.Kind, lPropInfo,
        GetPropValue(lPropInfo^.Name), AUserData);
  end;
end;

class function TNXPersistObject.IsPropFiltered(AFilterList: TStrings;
  const APropName: string): Boolean;
begin
  Result := Assigned(AFilterList) and (AFilterList.IndexOf(APropName) > -1);
end;

procedure TNXPersistObject.LoadFromJSONFile(const AFileName: string);
var
  lFile: TStringList;
begin
  lFile := TStringList.Create;
  try
    lFile.LoadFromFile(AFileName);
    JSON := lFile.Text;
  finally
    lFile.Free;
  end;
end;

class function TNXPersistObject.PersistAlias: string;
begin
  Result := ClassName;
end;

class procedure TNXPersistObject.RegisterPersistClass(AClass: TNXPersistClass;
  const AAlias: string);
var
  lAlias: string;
begin
  if not Assigned(AClass) then
    raise Exception.Create('Cannot register nil persist class');

  RegisterClass(AClass);

  lAlias := AAlias;
  if lAlias = '' then
    lAlias := AClass.PersistAlias;

  if Registry.IndexOfName(lAlias) >= 0 then
    Registry.Delete(Registry.IndexOfName(lAlias));

  Registry.Values[lAlias] := AClass.ClassName;
end;

class function TNXPersistObject.Registry: TStringList;
begin
  if not Assigned(uPersistRegistry) then
  begin
    uPersistRegistry := TStringList.Create;
    uPersistRegistry.CaseSensitive := False;
    uPersistRegistry.Duplicates := dupError;
  end;

  Result := uPersistRegistry;
end;

class function TNXPersistObject.ResolveClass(
  const AName: string): TNXPersistClass;
var
  lClassName: string;
  lClass: TPersistentClass;
begin
  Result := nil;
  if AName = '' then
    Exit;

  lClassName := Registry.Values[AName];
  if lClassName = '' then
    lClassName := AName;

  lClass := GetClass(lClassName);
  if Assigned(lClass) and lClass.InheritsFrom(TNXPersistObject) then
    Result := TNXPersistClass(lClass);
end;

procedure TNXPersistObject.SaveToJSONFile(const AFileName: string);
var
  lFile: TStringList;
begin
  lFile := TStringList.Create;
  try
    lFile.Text := JSON;
    lFile.SaveToFile(AFileName);
  finally
    lFile.Free;
  end;
end;

procedure TNXPersistObject.SetJSON(const AValue: string);
var
  lData: TJSONData;
  lObject: TJSONObject;
begin
  lData := ParseJSONData(AValue);
  try
    lObject := JSONAsObject(lData);
    if not Assigned(lObject) then
      raise Exception.Create('JSON root must be an object');

    StreamFromJSONObject(lObject);
  finally
    lData.Free;
  end;
end;

procedure TNXPersistObject.SetName(const AValue: string);
begin
  FName := AValue;
end;

procedure TNXPersistObject.SetPropValue(const APropName: string;
  AValue: Variant);
begin
  TypInfo.SetPropValue(Self, APropName, AValue);
end;

procedure TNXPersistObject.StreamFromJSONObject(AObject: TJSONObject);
var
  lClass: TNXPersistClass;
  lClassName: string;
  lData: TJSONData;
  lIndex: Integer;
  lObject: TObject;
  lObjectData: TJSONObject;
  lPropertyClass: TClass;
  lPropCount: Integer;
  lPropInfo: PPropInfo;
  lPropList: TPropList;
begin
  lPropCount := GetPropList(ClassInfo, tkAny, @lPropList, False);
  for lIndex := 0 to lPropCount - 1 do
  begin
    lPropInfo := lPropList[lIndex];
    lData := JSONFind(AObject, lPropInfo^.Name);
    if not Assigned(lData) then
      Continue;

    case lPropInfo^.PropType^.Kind of
      tkBool:
        SetOrdProp(Self, lPropInfo, Ord(lData.AsBoolean));
      tkClass:
        begin
          lObject := GetObjectProp(Self, lPropInfo);
          if lObject is TNXPersistObject then
            TNXPersistObject(lObject).StreamFromJSONObject(JSONAsObject(lData))
          else if (lObject = nil) and (lData is TJSONObject) and
            Assigned(lPropInfo^.SetProc) then
          begin
            lObjectData := TJSONObject(lData);
            lClassName := JSONAsString(JSONFind(lObjectData, cPersistClass));
            lClass := ResolveClass(lClassName);
            lPropertyClass := GetTypeData(lPropInfo^.PropType)^.ClassType;
            if not Assigned(lClass) then
              raise Exception.Create('Unknown persist class [' + lClassName +
                '] for property [' + lPropInfo^.Name + '] on [' +
                ClassName + ']');
            if not lClass.InheritsFrom(lPropertyClass) then
              raise Exception.Create('Persist class [' + lClass.ClassName +
                '] is not valid for property [' + lPropInfo^.Name + '] on [' +
                ClassName + ']');

            lObject := lClass.Create;
            try
              TNXPersistObject(lObject).StreamFromJSONObject(lObjectData);
              SetObjectProp(Self, lPropInfo, lObject);
            except
              lObject.Free;
              raise;
            end;
          end
          else if (lObject = nil) and (lData is TJSONObject) then
            raise Exception.Create('Cannot construct read-only nil property [' +
              lPropInfo^.Name + '] on [' + ClassName + ']')
          else if lObject is TStrings then
            TStrings(lObject).Text := lData.AsString;
        end;
      tkSet:
        SetSetProp(Self, lPropInfo, lData.AsString);
      else
        SetPropValue(lPropInfo^.Name, lData.AsString);
    end;
  end;
end;

function TNXPersistObject.StreamToJSONObject: TJSONObject;
var
  lObject: TObject;
  lPropCount: Integer;
  lPropIndex: Integer;
  lPropInfo: PPropInfo;
  lPropList: TPropList;
  lValueOrd: Int64;
begin
  Result := TJSONObject.Create;
  Result.Add(cPersistClass, PersistAlias);

  lPropCount := GetPropList(ClassInfo, tkAny, @lPropList, False);
  for lPropIndex := 0 to lPropCount - 1 do
  begin
    lPropInfo := lPropList[lPropIndex];
    if (not Assigned(lPropInfo^.SetProc)) and (not StoreReadOnlyProperties) then
      Continue;

    case lPropInfo^.PropType^.Kind of
      tkBool:
        Result.Add(lPropInfo^.Name, GetOrdProp(Self, lPropInfo) <> 0);
      tkClass:
        begin
          if not IsStoredObjectProperty(Self, lPropInfo) then
            Continue;

          lObject := GetObjectProp(Self, lPropInfo);
          if lObject is TNXPersistObject then
            AddJSONValue(Result, lPropInfo^.Name,
              TNXPersistObject(lObject).StreamToJSONObject)
          else if (lObject is TStrings) and (TStrings(lObject).Count > 0) then
            Result.Add(lPropInfo^.Name, TStrings(lObject).Text);
        end;
      tkInteger, tkInt64:
        begin
          lValueOrd := GetOrdProp(Self, lPropInfo);
          if lPropInfo^.Default <> lValueOrd then
            Result.Add(lPropInfo^.Name, lValueOrd);
        end;
      tkEnumeration:
        begin
          lValueOrd := GetOrdProp(Self, lPropInfo);
          if lPropInfo^.Default <> lValueOrd then
            Result.Add(lPropInfo^.Name, GetEnumProp(Self, lPropInfo));
        end;
      tkSet:
        Result.Add(lPropInfo^.Name, GetSetProp(Self, lPropInfo, False));
      tkString, tkLString, tkAString, tkWString, tkUString:
        if GetStrProp(Self, lPropInfo) <> '' then
          Result.Add(lPropInfo^.Name, GetStrProp(Self, lPropInfo));
      else
        Result.Add(lPropInfo^.Name, VarToStr(GetPropValue(lPropInfo^.Name)));
    end;
  end;
end;

{ TNXPersistBinary }

class procedure TNXPersistBinary.CopyStream(AInput, AOutput: TStream);
var
  lBuffer: array[0..8191] of Byte;
  lCount: LongInt;
begin
  repeat
    lCount := AInput.Read(lBuffer[0], SizeOf(lBuffer));
    if lCount > 0 then
      AOutput.WriteBuffer(lBuffer[0], lCount);
  until lCount = 0;
end;

constructor TNXPersistBinary.Create;
begin
  inherited Create;
  FData := TMemoryStream.Create;
  FEncoding := cPersistBinaryEncoding;
end;

destructor TNXPersistBinary.Destroy;
begin
  FreeAndNil(FData);
  inherited Destroy;
end;

procedure TNXPersistBinary.Clear;
begin
  FData.Clear;
end;

function TNXPersistBinary.GetData: string;
var
  lEncoder: TBase64EncodingStream;
  lOutput: TStringStream;
  lPosition: Int64;
begin
  Result := '';
  if FData.Size = 0 then
    Exit;

  lPosition := FData.Position;
  lOutput := TStringStream.Create('');
  try
    lEncoder := TBase64EncodingStream.Create(lOutput);
    try
      FData.Position := 0;
      CopyStream(FData, lEncoder);
    finally
      lEncoder.Free;
    end;
    Result := lOutput.DataString;
  finally
    FData.Position := lPosition;
    lOutput.Free;
  end;
end;

function TNXPersistBinary.GetSize: Int64;
begin
  Result := FData.Size;
end;

function TNXPersistBinary.IsEmpty: Boolean;
begin
  Result := FData.Size = 0;
end;

procedure TNXPersistBinary.LoadFromStream(AStream: TStream);
begin
  if not Assigned(AStream) then
    raise Exception.Create('Cannot load binary data from nil stream');

  if AStream.Size < AStream.Position then
    raise Exception.Create('Stream position is beyond stream size');

  FData.Clear;
  FData.CopyFrom(AStream, AStream.Size - AStream.Position);
  FData.Position := 0;
  FEncoding := cPersistBinaryEncoding;
end;

procedure TNXPersistBinary.SaveToStream(AStream: TStream);
begin
  if not Assigned(AStream) then
    raise Exception.Create('Cannot save binary data to nil stream');
  if not SameText(FEncoding, cPersistBinaryEncoding) then
    raise Exception.Create('Unsupported binary encoding: ' + FEncoding);

  FData.Position := 0;
  AStream.CopyFrom(FData, FData.Size);
  FData.Position := 0;
end;

procedure TNXPersistBinary.SetData(const AValue: string);
var
  lDecoder: TBase64DecodingStream;
  lInput: TStringStream;
begin
  FData.Clear;
  if AValue = '' then
    Exit;

  lInput := TStringStream.Create(AValue);
  try
    lDecoder := TBase64DecodingStream.Create(lInput, bdmStrict);
    try
      CopyStream(lDecoder, FData);
      FData.Position := 0;
    finally
      lDecoder.Free;
    end;
  finally
    lInput.Free;
  end;
end;

procedure TNXPersistBinary.SetEncoding(const AValue: string);
begin
  if (AValue <> '') and (not SameText(AValue, cPersistBinaryEncoding)) then
    raise Exception.Create('Unsupported binary encoding: ' + AValue);

  FEncoding := cPersistBinaryEncoding;
end;

{ TNXPersistList }

constructor TNXPersistList.Create;
begin
  inherited Create;

  FObjects := TList.Create;
  FItemClass := TNXPersistObject;
  FOwnsObjects := True;
end;

destructor TNXPersistList.Destroy;
begin
  Clear;
  FreeAndNil(FObjects);
  inherited Destroy;
end;

function TNXPersistList.Add(AObject: TNXPersistObject): Integer;
begin
  Result := InternalAdd(AObject);
  DoChange;
end;

function TNXPersistList.AddObject(AClass: TNXPersistClass;
  const ADefaultName: string): TNXPersistObject;
begin
  Result := AClass.Create;
  Result.OwnerList := Self;
  Result.Name := GetUniqueName(ADefaultName);
  FObjects.Add(Result);
end;

procedure TNXPersistList.AssignTo(ADestination: TPersistent);
var
  lDestination: TNXPersistList;
begin
  if ADestination is ClassType then
  begin
    lDestination := TNXPersistList(ADestination);
    lDestination.JSON := JSON;
  end
  else
    inherited AssignTo(ADestination);
end;

procedure TNXPersistList.Clear;
var
  lIndex: Integer;
begin
  if OwnsObjects then
    for lIndex := 0 to FObjects.Count - 1 do
      TObject(FObjects[lIndex]).Free;

  FObjects.Clear;
  DoChange;
end;

procedure TNXPersistList.CopyTo(ADestination: TPersistent);
var
  lDestination: TNXPersistList;
  lIndex: Integer;
begin
  if ADestination is ClassType then
  begin
    lDestination := TNXPersistList(ADestination);
    for lIndex := 0 to Count - 1 do
      lDestination.Add(Items[lIndex].CloneSelf);
  end
  else
    inherited CopyTo(ADestination);
end;

procedure TNXPersistList.Delete(AIndex: Integer);
var
  lObject: TNXPersistObject;
begin
  lObject := Items[AIndex];
  DoDeleteObject(lObject);
  FObjects.Delete(AIndex);
  if OwnsObjects then
    lObject.Free;
  DoChange;
end;

procedure TNXPersistList.Delete(AObject: TNXPersistObject);
var
  lIndex: Integer;
begin
  lIndex := IndexOf(AObject);
  if lIndex >= 0 then
    Delete(lIndex);
end;

procedure TNXPersistList.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TNXPersistList.DoDeleteObject(AObject: TNXPersistObject);
begin
  if Assigned(FOnDeleteObject) then
    FOnDeleteObject(AObject);
end;

procedure TNXPersistList.DoNewObject(AObject: TNXPersistObject);
begin
  if Assigned(FOnNewObject) then
    FOnNewObject(AObject);
end;

function TNXPersistList.Expand: TNXPersistList;
begin
  FObjects.Capacity := FObjects.Count + 4;
  Result := Self;
end;

function TNXPersistList.Extract(AObject: TNXPersistObject): TNXPersistObject;
var
  lIndex: Integer;
begin
  lIndex := IndexOf(AObject);
  if lIndex < 0 then
    Exit(nil);

  Result := AObject;
  DoDeleteObject(Result);
  FObjects.Delete(lIndex);
  Result.OwnerList := nil;
  DoChange;
end;

function TNXPersistList.First: TNXPersistObject;
begin
  if Count = 0 then
    Result := nil
  else
    Result := Items[0];
end;

function TNXPersistList.GetCapacity: Integer;
begin
  Result := FObjects.Capacity;
end;

function TNXPersistList.GetCount: Integer;
begin
  Result := FObjects.Count;
end;

function TNXPersistList.GetItem(AIndex: Integer): TNXPersistObject;
begin
  Result := TNXPersistObject(FObjects[AIndex]);
end;

function TNXPersistList.GetItemAlias: string;
begin
  Result := ItemClass.PersistAlias;
end;

function TNXPersistList.GetItemClass: TNXPersistClass;
begin
  Result := FItemClass;
end;

function TNXPersistList.GetUniqueName(const AName: string): string;
var
  lPostfix: Integer;
begin
  lPostfix := 1;
  if IndexOf(AName) = -1 then
    Result := AName
  else
  begin
    while IndexOf(AName + IntToStr(lPostfix)) > -1 do
      Inc(lPostfix);
    Result := AName + IntToStr(lPostfix);
  end;
end;

function TNXPersistList.IndexOf(AName: string): Integer;
var
  lIndex: Integer;
begin
  Result := -1;
  for lIndex := 0 to Count - 1 do
    if Items[lIndex].Name = AName then
    begin
      Result := lIndex;
      Exit;
    end;
end;

function TNXPersistList.IndexOf(AObject: TNXPersistObject): Integer;
begin
  Result := FObjects.IndexOf(AObject);
end;

function TNXPersistList.InternalAdd(AObject: TNXPersistObject): Integer;
begin
  if not Assigned(AObject) then
    raise Exception.Create('Cannot add nil persist object');

  Result := FObjects.Add(AObject);
  AObject.OwnerList := Self;
  DoNewObject(AObject);
end;

function TNXPersistList.InternalGetObject(
  const AName: string): TNXPersistObject;
var
  lIndex: Integer;
begin
  lIndex := IndexOf(AName);
  if lIndex < 0 then
    Result := nil
  else
    Result := Items[lIndex];
end;

procedure TNXPersistList.InternalSetObject(const AName: string;
  AObject: TNXPersistObject);
var
  lIndex: Integer;
begin
  lIndex := IndexOf(AName);
  AObject.Name := AName;
  AObject.OwnerList := Self;

  if lIndex >= 0 then
  begin
    if OwnsObjects then
      Items[lIndex].Free;
    FObjects[lIndex] := AObject;
  end
  else
    FObjects.Add(AObject);
end;

procedure TNXPersistList.Insert(AIndex: Integer; AObject: TNXPersistObject);
begin
  FObjects.Insert(AIndex, AObject);
  AObject.OwnerList := Self;
  DoNewObject(AObject);
  DoChange;
end;

procedure TNXPersistList.Insert(AName: string; AObject: TNXPersistObject);
begin
  AObject.Name := AName;
  Add(AObject);
end;

function TNXPersistList.Last: TNXPersistObject;
begin
  if Count = 0 then
    Result := nil
  else
    Result := Items[Count - 1];
end;

function TNXPersistList.LocateByName(const AName: string;
  ACaseSensitive: Boolean; APartialFind: Boolean; AStartIdx: Integer): Integer;
var
  lCompareName: string;
  lIndex: Integer;
  lName: string;
begin
  Result := -1;

  if ACaseSensitive then
    lName := AName
  else
    lName := UpperCase(AName);

  for lIndex := AStartIdx to Count - 1 do
  begin
    if ACaseSensitive then
      lCompareName := Items[lIndex].Name
    else
      lCompareName := UpperCase(Items[lIndex].Name);

    if APartialFind then
    begin
      if Pos(lName, lCompareName) = 1 then
        Exit(lIndex);
    end
    else if lName = lCompareName then
      Exit(lIndex);
  end;
end;

procedure TNXPersistList.Move(ACurrentIndex, ANewIndex: Integer);
begin
  FObjects.Move(ACurrentIndex, ANewIndex);
  DoChange;
end;

function TNXPersistList.New: TNXPersistObject;
begin
  if ItemClass = TNXPersistObject then
    raise Exception.Create(ClassName + '.ItemClass must be assigned before New');

  Result := ItemClass.Create;
  Add(Result);
end;

procedure TNXPersistList.Pack;
begin
  FObjects.Pack;
end;

procedure TNXPersistList.SetCapacity(AValue: Integer);
begin
  FObjects.Capacity := AValue;
end;

procedure TNXPersistList.SetCount(AValue: Integer);
begin
  while Count > AValue do
    Delete(Count - 1);

  while Count < AValue do
    New;

  DoChange;
end;

procedure TNXPersistList.SetItem(AIndex: Integer; AValue: TNXPersistObject);
begin
  if OwnsObjects then
    Items[AIndex].Free;
  FObjects[AIndex] := AValue;
  AValue.OwnerList := Self;
  DoChange;
end;

procedure TNXPersistList.SetItemClass(AValue: TNXPersistClass);
begin
  FItemClass := AValue;
end;

procedure TNXPersistList.StreamFromJSONObject(AObject: TJSONObject);
var
  lArray: TJSONArray;
  lData: TJSONData;
  lIndex: Integer;
  lItem: TNXPersistObject;
  lItemObject: TJSONObject;
  lPersistClass: string;
begin
  inherited StreamFromJSONObject(AObject);

  Clear;
  lArray := JSONAsArray(JSONFind(AObject, cPersistItems));
  if not Assigned(lArray) then
    Exit;

  for lIndex := 0 to lArray.Count - 1 do
  begin
    lData := lArray.Items[lIndex];
    lItemObject := JSONAsObject(lData);
    if not Assigned(lItemObject) then
      Continue;

    lPersistClass := JSONAsString(JSONFind(lItemObject, cPersistClass));
    if lPersistClass = '' then
      lPersistClass := GetItemAlias;

    lItem := CreateObjectFromName(lPersistClass);
    lItem.StreamFromJSONObject(lItemObject);
    InternalAdd(lItem);
    DoStreamList(lItem, lIndex, lArray.Count);
  end;
  DoChange;
end;

function TNXPersistList.StreamToJSONObject: TJSONObject;
var
  lArray: TJSONArray;
  lIndex: Integer;
begin
  Result := inherited StreamToJSONObject;

  lArray := TJSONArray.Create;
  AddJSONValue(Result, cPersistItems, lArray);
  for lIndex := 0 to Count - 1 do
  begin
    lArray.Add(Items[lIndex].StreamToJSONObject);
    DoStreamList(Items[lIndex], lIndex, Count);
  end;
end;

procedure TNXPersistList.Union(ASource: TNXPersistList);
var
  lDestinationIndex: Integer;
  lSourceIndex: Integer;
begin
  for lSourceIndex := 0 to ASource.Count - 1 do
  begin
    lDestinationIndex := LocateByName(ASource[lSourceIndex].Name);
    if lDestinationIndex > -1 then
    begin
      if (Items[lDestinationIndex] is TNXPersistList) and
        (ASource[lSourceIndex] is TNXPersistList) then
        TNXPersistList(Items[lDestinationIndex]).Union(
          TNXPersistList(ASource[lSourceIndex]))
      else
        InternalSetObject(ASource[lSourceIndex].Name,
          ASource[lSourceIndex].CloneSelf);
    end
    else
      InternalSetObject(ASource[lSourceIndex].Name,
        ASource[lSourceIndex].CloneSelf);
  end;

  DoChange;
end;

initialization
  TNXPersistObject.RegisterPersistClass(TNXPersistObject);
  TNXPersistObject.RegisterPersistClass(TNXPersistBinary);
  TNXPersistObject.RegisterPersistClass(TNXPersistList);

finalization
  FreeAndNil(uPersistRegistry);

end.

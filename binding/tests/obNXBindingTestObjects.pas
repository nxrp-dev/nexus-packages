(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXBindingTestObjects;

{$mode objfpc}{$H+}{$interfaces corba}

interface

uses SysUtils, tpNXBinding, obNXBindingSubscriptions;

type
  TTestObservable = class(TObject, INXBindingObservable)
  private
    FSubscriptions: TNXBindingSubscriptions;
  public
    constructor Create;
    destructor Destroy; override;
    function Subscribe(AObserver: INXBindingObserver): QWord;
    procedure Unsubscribe(AToken: QWord);
    procedure Emit(AKind: TNXBindingEventKind);
    procedure Close;
  end;

  TTestValue = class(TTestObservable, INXBindingValue)
  private
    FValue: TNXBindingValue;
    FDescriptor: TNXBindingDescriptor;
  public
    constructor Create(const AValue: TNXBindingValue);
    function GetDescriptor: TNXBindingDescriptor; virtual;
    function TryRead(out AValue: TNXBindingValue): TNXBindingResult; virtual;
    procedure SetValue(const AValue: TNXBindingValue);
    procedure SetReadable(AValue: Boolean);
    property Value: TNXBindingValue read FValue;
  end;

  TTestTarget = class(TTestValue, INXBindingWritableValue)
  private
    FWritable, FReject, FNormalize: Boolean;
    FWrites: Integer;
  public
    constructor Create(const AValue: TNXBindingValue);
    function GetWritable: Boolean; virtual;
    function TryWrite(const AValue: TNXBindingValue): TNXBindingResult; virtual;
    procedure SetWritable(AValue: Boolean);
    property Reject: Boolean read FReject write FReject;
    property Normalize: Boolean read FNormalize write FNormalize;
    property Writes: Integer read FWrites;
  end;

  TTestFacadeValue = class(TTestTarget)
  private
    FBacking: TTestTarget;
  public
    function GetDescriptor: TNXBindingDescriptor; override;
    function TryRead(out AValue: TNXBindingValue): TNXBindingResult; override;
    function GetWritable: Boolean; override;
    function TryWrite(const AValue: TNXBindingValue): TNXBindingResult; override;
    property Backing: TTestTarget read FBacking write FBacking;
  end;

  TTestScalarSource = class(TTestObservable, INXItemSource, INXBindingItem)
  private
    FEndpoint: TTestValue;
  public
    constructor Create(const AValue: TNXBindingValue; AReadOnly: Boolean = False);
    destructor Destroy; override;
    function GetCurrent: INXBindingItem;
    function ResolveValue(const AMember: UTF8String; out AValue: TObject): TNXBindingResult;
    function First: TNXBindingResult;
    function Prior: TNXBindingResult;
    function Next: TNXBindingResult;
    function Last: TNXBindingResult;
    property Endpoint: TTestValue read FEndpoint;
  end;

  TTestItem = class(TObject, INXBindingItem)
  private
    FName, FNumber: TTestTarget;
    FHidden: Boolean;
  public
    constructor Create(const AName: UTF8String; ANumber: Int64);
    constructor CreateEndpoints(AName, ANumber: TTestTarget);
    destructor Destroy; override;
    function ResolveValue(const AMember: UTF8String; out AValue: TObject): TNXBindingResult;
    property NameValue: TTestTarget read FName;
    property NumberValue: TTestTarget read FNumber;
    property Hidden: Boolean read FHidden write FHidden;
  end;

  TTestSource = class(TTestObservable, INXItemSource)
  private
    FItems: array of TTestItem;
    FSelected: Integer;
    FFacade: TTestItem;
    FNameProxy, FNumberProxy: TTestFacadeValue;
    FNavigationCalls: Integer;
    FNotifying: Boolean;
    FFailNavigation: Boolean;
    procedure UpdateFacade;
  protected
    function MoveTo(AIndex: Integer): TNXBindingResult; virtual;
  public
    constructor Create(AFacade: Boolean = True; AEmpty: Boolean = False);
    destructor Destroy; override;
    function GetCurrent: INXBindingItem;
    function First: TNXBindingResult;
    function Prior: TNXBindingResult;
    function Next: TNXBindingResult;
    function Last: TNXBindingResult;
    function CurrentData: TTestItem;
    procedure DataChanged;
    procedure RemoveCurrent;
    property NavigationCalls: Integer read FNavigationCalls;
    property FailNavigation: Boolean read FFailNavigation write FFailNavigation;
  end;

  TTestListSource = class(TTestSource)
  public
    constructor Create;
  end;

  TTestEditableSource = class(TTestSource, INXBindingEditSession)
  private
    FEditing: Boolean;
    FOriginalName, FOriginalNumber: TNXBindingValue;
    FFailCommit, FFailCancel: Boolean;
  protected
    function MoveTo(AIndex: Integer): TNXBindingResult; override;
  public
    function GetDirty: Boolean;
    function BeginEdit: TNXBindingResult;
    function Commit: TNXBindingResult;
    function Cancel: TNXBindingResult;
    property FailCommit: Boolean read FFailCommit write FFailCommit;
    property FailCancel: Boolean read FFailCancel write FFailCancel;
  end;

  TTestConverter = class(TObject, INXBindingConverter)
  private
    FRaise: Boolean;
  public
    function Convert(const AValue: TNXBindingValue;
      const ADestination: TNXBindingDescriptor; ADirection: TNXBindingDirection;
      out AConverted: TNXBindingValue): TNXBindingResult;
    property RaiseError: Boolean read FRaise write FRaise;
  end;

  TTestValidator = class(TObject, INXBindingValidator)
  public
    function Validate(AItem: INXBindingItem; const AMember: UTF8String;
      const AValue: TNXBindingValue): TNXBindingResult;
  end;

  TTestObserverAction = procedure(ASubject: TObject;
    const AEvent: TNXBindingEvent) of object;
  TTestObserver = class(TObject, INXBindingObserver)
  private
    FEvents: array of TNXBindingEventKind;
    FAction: TTestObserverAction;
  public
    procedure Changed(ASubject: TObject; const AEvent: TNXBindingEvent);
    function Count(AKind: TNXBindingEventKind): Integer;
    function EventAt(AIndex: Integer): TNXBindingEventKind;
    procedure Clear;
    property Action: TTestObserverAction read FAction write FAction;
  end;

implementation

constructor TTestScalarSource.Create(const AValue: TNXBindingValue; AReadOnly: Boolean);
begin
  inherited Create;
  if AReadOnly then FEndpoint := TTestValue.Create(AValue)
  else FEndpoint := TTestTarget.Create(AValue);
end;

destructor TTestScalarSource.Destroy;
begin
  try
    Close;
  finally
    FEndpoint.Free;
    inherited Destroy;
  end;
end;

function TTestScalarSource.GetCurrent: INXBindingItem;
begin
  Result := Self;
end;

function TTestScalarSource.ResolveValue(const AMember: UTF8String;
  out AValue: TObject): TNXBindingResult;
begin
  AValue := FEndpoint;
  Result := TNXBindingResult.Make(bcSuccess);
end;

function TTestScalarSource.First: TNXBindingResult;
begin Result := TNXBindingResult.Make(bcNoMovement); end;

function TTestScalarSource.Prior: TNXBindingResult;
begin Result := TNXBindingResult.Make(bcNoMovement); end;

function TTestScalarSource.Next: TNXBindingResult;
begin Result := TNXBindingResult.Make(bcNoMovement); end;

function TTestScalarSource.Last: TNXBindingResult;
begin Result := TNXBindingResult.Make(bcNoMovement); end;

constructor TTestObservable.Create;
begin
  inherited Create;
  FSubscriptions := TNXBindingSubscriptions.Create;
end;

destructor TTestObservable.Destroy;
begin
  try
    Close;
  finally
    FSubscriptions.Free;
    inherited Destroy;
  end;
end;

function TTestObservable.Subscribe(AObserver: INXBindingObserver): QWord;
begin
  Result := FSubscriptions.Subscribe(AObserver);
end;

procedure TTestObservable.Unsubscribe(AToken: QWord);
begin
  FSubscriptions.Unsubscribe(AToken);
end;

procedure TTestObservable.Emit(AKind: TNXBindingEventKind);
begin
  FSubscriptions.Notify(Self, AKind);
end;

procedure TTestObservable.Close;
begin
  Emit(beClosing);
end;

constructor TTestValue.Create(const AValue: TNXBindingValue);
begin
  inherited Create;
  FValue := AValue;
  FDescriptor.Kind := AValue.Kind;
  FDescriptor.Readable := True;
  FDescriptor.AcceptsNull := True;
  FDescriptor.AcceptsUnset := True;
end;

function TTestValue.GetDescriptor: TNXBindingDescriptor;
begin
  Result := FDescriptor;
end;

function TTestValue.TryRead(out AValue: TNXBindingValue): TNXBindingResult;
begin
  AValue := Default(TNXBindingValue);
  if not FDescriptor.Readable then Exit(TNXBindingResult.Make(bcUnavailable));
  AValue := FValue;
  Result := TNXBindingResult.Make(bcSuccess);
end;

procedure TTestValue.SetValue(const AValue: TNXBindingValue);
begin
  if FValue.SameValue(AValue) then Exit;
  FValue := AValue;
  Emit(beValueChanged);
end;

procedure TTestValue.SetReadable(AValue: Boolean);
begin
  FDescriptor.Readable := AValue;
  Emit(beStateChanged);
end;

constructor TTestTarget.Create(const AValue: TNXBindingValue);
begin
  inherited Create(AValue);
  FWritable := True;
end;

function TTestTarget.GetWritable: Boolean;
begin
  Result := FWritable;
end;

function TTestTarget.TryWrite(const AValue: TNXBindingValue): TNXBindingResult;
var
  lValue: TNXBindingValue;
begin
  Inc(FWrites);
  if not FWritable then Exit(TNXBindingResult.Make(bcReadOnly));
  if FReject then Exit(TNXBindingResult.Make(bcRejected));
  Result := GetDescriptor.Check(AValue);
  if not Result.Succeeded then Exit;
  lValue := AValue;
  if FNormalize and (lValue.Kind = bkString) and (lValue.Presence = bpValue) then
    lValue.StringValue := Trim(lValue.StringValue);
  SetValue(lValue);
end;

procedure TTestTarget.SetWritable(AValue: Boolean);
begin
  FWritable := AValue;
  Emit(beStateChanged);
end;

function TTestFacadeValue.GetDescriptor: TNXBindingDescriptor;
begin
  if FBacking = nil then Exit(inherited GetDescriptor);
  Result := FBacking.GetDescriptor;
end;

function TTestFacadeValue.TryRead(out AValue: TNXBindingValue): TNXBindingResult;
begin
  AValue := Default(TNXBindingValue);
  if FBacking = nil then Exit(TNXBindingResult.Make(bcUnavailable));
  Result := FBacking.TryRead(AValue);
end;

function TTestFacadeValue.GetWritable: Boolean;
begin
  Result := (FBacking <> nil) and FBacking.GetWritable;
end;

function TTestFacadeValue.TryWrite(const AValue: TNXBindingValue): TNXBindingResult;
var
  lBefore, lAfter: TNXBindingValue;
begin
  if FBacking = nil then Exit(TNXBindingResult.Make(bcUnavailable));
  FBacking.TryRead(lBefore);
  Result := FBacking.TryWrite(AValue);
  FBacking.TryRead(lAfter);
  if not lBefore.SameValue(lAfter) then Emit(beValueChanged);
end;

constructor TTestItem.Create(const AName: UTF8String; ANumber: Int64);
begin
  inherited Create;
  FName := TTestTarget.Create(TNXBindingValue.FromString(AName));
  FNumber := TTestTarget.Create(TNXBindingValue.FromInteger(ANumber));
end;

constructor TTestItem.CreateEndpoints(AName, ANumber: TTestTarget);
begin
  inherited Create;
  FName := AName;
  FNumber := ANumber;
end;

destructor TTestItem.Destroy;
begin
  FName.Free;
  FNumber.Free;
  inherited Destroy;
end;

function TTestItem.ResolveValue(const AMember: UTF8String;
  out AValue: TObject): TNXBindingResult;
begin
  AValue := nil;
  if not FHidden then
    if AMember = 'Name' then AValue := FName
    else if AMember = 'Number' then AValue := FNumber;
  if AValue = nil then Result := TNXBindingResult.Make(bcUnavailable)
  else Result := TNXBindingResult.Make(bcSuccess);
end;

constructor TTestSource.Create(AFacade: Boolean; AEmpty: Boolean);
begin
  inherited Create;
  FSelected := -1;
  if not AEmpty then
  begin
    SetLength(FItems, 2);
    FItems[0] := TTestItem.Create('Alice', 10);
    FItems[1] := TTestItem.Create('Bob', 20);
    FSelected := 0;
  end;
  if AFacade then
  begin
    FNameProxy := TTestFacadeValue.Create(TNXBindingValue.FromString(''));
    FNumberProxy := TTestFacadeValue.Create(TNXBindingValue.FromInteger(0));
    FFacade := TTestItem.CreateEndpoints(FNameProxy, FNumberProxy);
    UpdateFacade;
  end;
end;

destructor TTestSource.Destroy;
var
  lIndex: Integer;
begin
  try
    Close;
  finally
    FFacade.Free;
    for lIndex := 0 to High(FItems) do FItems[lIndex].Free;
    inherited Destroy;
  end;
end;

function TTestSource.CurrentData: TTestItem;
begin
  Result := nil;
  if (FSelected >= 0) and (FSelected < Length(FItems)) then Result := FItems[FSelected];
end;

procedure TTestSource.UpdateFacade;
begin
  if FFacade = nil then Exit;
  if CurrentData = nil then
  begin
    FNameProxy.Backing := nil;
    FNumberProxy.Backing := nil;
  end
  else
  begin
    FNameProxy.Backing := CurrentData.NameValue;
    FNumberProxy.Backing := CurrentData.NumberValue;
  end;
end;

function TTestSource.GetCurrent: INXBindingItem;
begin
  Result := nil;
  if CurrentData = nil then Exit;
  if FFacade <> nil then Result := FFacade else Result := CurrentData;
end;

function TTestSource.MoveTo(AIndex: Integer): TNXBindingResult;
begin
  if FNotifying then Exit(TNXBindingResult.Make(bcBusy));
  Inc(FNavigationCalls);
  if FFailNavigation then Exit(TNXBindingResult.Make(bcRejected));
  if (AIndex < 0) or (AIndex >= Length(FItems)) or (AIndex = FSelected) then
    Exit(TNXBindingResult.Make(bcNoMovement));
  FSelected := AIndex;
  UpdateFacade;
  FNotifying := True;
  try
    Emit(beCurrentChanged);
  finally
    FNotifying := False;
  end;
  Result := TNXBindingResult.Make(bcSuccess);
end;

function TTestSource.First: TNXBindingResult;
begin
  Result := MoveTo(0);
end;

function TTestSource.Prior: TNXBindingResult;
begin
  Result := MoveTo(FSelected - 1);
end;

function TTestSource.Next: TNXBindingResult;
begin
  Result := MoveTo(FSelected + 1);
end;

function TTestSource.Last: TNXBindingResult;
begin
  Result := MoveTo(High(FItems));
end;

procedure TTestSource.DataChanged;
begin
  Emit(beDataChanged);
end;

procedure TTestSource.RemoveCurrent;
var
  lOld: TTestItem;
  lIndex: Integer;
begin
  lOld := CurrentData;
  if lOld = nil then Exit;
  for lIndex := FSelected to High(FItems) - 1 do FItems[lIndex] := FItems[lIndex + 1];
  SetLength(FItems, Length(FItems) - 1);
  if FSelected >= Length(FItems) then FSelected := High(FItems);
  UpdateFacade;
  try
    Emit(beCurrentChanged);
  finally
    lOld.Free;
  end;
end;

constructor TTestListSource.Create;
begin
  inherited Create(False);
end;

function TTestEditableSource.MoveTo(AIndex: Integer): TNXBindingResult;
begin
  Result := inherited MoveTo(AIndex);
  if Result.Code = bcSuccess then FEditing := False;
end;

function TTestEditableSource.GetDirty: Boolean;
begin
  Result := FEditing and (CurrentData <> nil) and
    (not FOriginalName.SameValue(CurrentData.NameValue.Value) or
     not FOriginalNumber.SameValue(CurrentData.NumberValue.Value));
end;

function TTestEditableSource.BeginEdit: TNXBindingResult;
begin
  if CurrentData = nil then Exit(TNXBindingResult.Make(bcUnavailable));
  if not FEditing then
  begin
    FOriginalName := CurrentData.NameValue.Value;
    FOriginalNumber := CurrentData.NumberValue.Value;
    FEditing := True;
  end;
  Result := TNXBindingResult.Make(bcSuccess);
end;

function TTestEditableSource.Commit: TNXBindingResult;
begin
  if FFailCommit then Exit(TNXBindingResult.Make(bcRejected));
  FEditing := False;
  Emit(beStateChanged);
  Result := TNXBindingResult.Make(bcSuccess);
end;

function TTestEditableSource.Cancel: TNXBindingResult;
begin
  if FFailCancel then Exit(TNXBindingResult.Make(bcRejected));
  if FEditing and (CurrentData <> nil) then
  begin
    CurrentData.NameValue.SetValue(FOriginalName);
    CurrentData.NumberValue.SetValue(FOriginalNumber);
  end;
  FEditing := False;
  DataChanged;
  Result := TNXBindingResult.Make(bcSuccess);
end;

function TTestConverter.Convert(const AValue: TNXBindingValue;
  const ADestination: TNXBindingDescriptor; ADirection: TNXBindingDirection;
  out AConverted: TNXBindingValue): TNXBindingResult;
var
  lInteger: Int64;
begin
  if FRaise then raise Exception.Create('Test converter failure');
  AConverted := AValue;
  if AValue.Presence <> bpValue then
    AConverted.Kind := ADestination.Kind
  else if (AValue.Kind = bkInt64) and (ADestination.Kind = bkString) then
    AConverted := TNXBindingValue.FromString(IntToStr(AValue.IntegerValue))
  else if (AValue.Kind = bkString) and (ADestination.Kind = bkInt64) then
  begin
    if AValue.StringValue = '-' then Exit(TNXBindingResult.Make(bcIncomplete));
    if not TryStrToInt64(AValue.StringValue, lInteger) then
      Exit(TNXBindingResult.Make(bcConversionFailed));
    AConverted := TNXBindingValue.FromInteger(lInteger);
  end;
  Result := ADestination.Check(AConverted);
end;

function TTestValidator.Validate(AItem: INXBindingItem; const AMember: UTF8String;
  const AValue: TNXBindingValue): TNXBindingResult;
begin
  if (AValue.Kind = bkInt64) and (AValue.IntegerValue < 0) then
    Result := TNXBindingResult.Make(bcValidationFailed)
  else Result := TNXBindingResult.Make(bcSuccess);
end;

procedure TTestObserver.Changed(ASubject: TObject;
  const AEvent: TNXBindingEvent);
begin
  SetLength(FEvents, Length(FEvents) + 1);
  FEvents[High(FEvents)] := AEvent.Kind;
  if Assigned(FAction) then FAction(ASubject, AEvent);
end;

function TTestObserver.Count(AKind: TNXBindingEventKind): Integer;
var
  lKind: TNXBindingEventKind;
begin
  Result := 0;
  for lKind in FEvents do if lKind = AKind then Inc(Result);
end;

procedure TTestObserver.Clear;
begin
  SetLength(FEvents, 0);
end;

function TTestObserver.EventAt(AIndex: Integer): TNXBindingEventKind;
begin
  Result := FEvents[AIndex];
end;

end.

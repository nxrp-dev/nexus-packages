(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tpNXBinding;

{$mode objfpc}{$H+}{$interfaces corba}{$modeswitch advancedrecords}

interface

uses SysUtils;

type
  TNXBindingKind = (bkBoolean, bkInt64, bkDouble, bkString, bkDateTime, bkCurrency);
  TNXBindingPresence = (bpUnset, bpNull, bpValue);
  TNXBindingValue = record
    Kind: TNXBindingKind;
    Presence: TNXBindingPresence;
    BooleanValue: Boolean;
    IntegerValue: Int64;
    DoubleValue: Double;
    StringValue: UTF8String;
    DateTimeValue: TDateTime;
    CurrencyValue: Currency;
    class function Empty(AKind: TNXBindingKind;
      APresence: TNXBindingPresence): TNXBindingValue; static;
    class function FromBoolean(AValue: Boolean): TNXBindingValue; static;
    class function FromInteger(AValue: Int64): TNXBindingValue; static;
    class function FromDouble(AValue: Double): TNXBindingValue; static;
    class function FromString(const AValue: UTF8String): TNXBindingValue; static;
    class function FromDateTime(AValue: TDateTime): TNXBindingValue; static;
    class function FromCurrency(AValue: Currency): TNXBindingValue; static;
    function SameValue(const AOther: TNXBindingValue): Boolean;
  end;

  TNXBindingCode = (bcSuccess, bcNoMovement, bcUnavailable, bcReadOnly,
    bcWrongKind, bcConversionFailed, bcIncomplete, bcValidationFailed,
    bcRejected, bcUnsupported, bcBusy, bcSourceChanged, bcPendingEdits,
    bcInvalidHandle, bcAmbiguousProposal);
  TNXBindingResult = record
    Code: TNXBindingCode;
    MessageText: string;
    Binding: QWord;
    class function Make(ACode: TNXBindingCode;
      const AMessage: string = ''): TNXBindingResult; static;
    function Succeeded: Boolean;
  end;

  TNXBindingDescriptor = record
    Kind: TNXBindingKind;
    Readable: Boolean;
    AcceptsNull: Boolean;
    AcceptsUnset: Boolean;
    function Check(const AValue: TNXBindingValue): TNXBindingResult;
  end;
  TNXBindingMode = (bmOneWay, bmTwoWay);
  TNXBindingTrigger = (btOnChange, btExplicit);
  TNXBindingDirection = (bdToTarget, bdToSource);
  TNXBindingEventKind = (beValueChanged, beStateChanged, beCurrentChanged,
    beDataChanged, beBindingChanged, beClosing);
  TNXBindingEvent = record
    Kind: TNXBindingEventKind;
    Binding: QWord;
  end;
  TNXBindingState = record
    Available: Boolean;
    Pending: Boolean;
    Orphaned: Boolean;
    SourceChanged: Boolean;
    PendingValue: TNXBindingValue;
    SourceValue: TNXBindingValue;
    LastResult: TNXBindingResult;
  end;

  INXBindingObservable = interface;
  INXBindingObserver = interface ['INXBindingObserver']
    procedure Changed(ASubject: TObject; const AEvent: TNXBindingEvent);
  end;
  INXBindingObservable = interface ['INXBindingObservable']
    function Subscribe(AObserver: INXBindingObserver): QWord;
    procedure Unsubscribe(AToken: QWord);
  end;
  INXBindingWritableValue = interface ['INXBindingWritableValue']
    function GetWritable: Boolean;
    function TryWrite(const AValue: TNXBindingValue): TNXBindingResult;
  end;
  INXBindingValue = interface(INXBindingObservable) ['INXBindingValue']
    function GetDescriptor: TNXBindingDescriptor;
    function TryRead(out AValue: TNXBindingValue): TNXBindingResult;
  end;
  INXBindingItem = interface ['INXBindingItem']
    function ResolveValue(const AMember: UTF8String;
      out AValue: TObject): TNXBindingResult;
  end;
  INXBindingEditSession = interface(INXBindingObservable) ['INXBindingEditSession']
    function GetDirty: Boolean;
    function BeginEdit: TNXBindingResult;
    function Commit: TNXBindingResult;
    function Cancel: TNXBindingResult;
  end;
  INXItemSource = interface(INXBindingObservable) ['INXItemSource']
    function GetCurrent: INXBindingItem;
    function First: TNXBindingResult;
    function Prior: TNXBindingResult;
    function Next: TNXBindingResult;
    function Last: TNXBindingResult;
  end;
  INXBindingConverter = interface ['INXBindingConverter']
    function Convert(const AValue: TNXBindingValue;
      const ADestination: TNXBindingDescriptor; ADirection: TNXBindingDirection;
      out AConverted: TNXBindingValue): TNXBindingResult;
  end;
  INXBindingValidator = interface ['INXBindingValidator']
    function Validate(AItem: INXBindingItem; const AMember: UTF8String;
      const AValue: TNXBindingValue): TNXBindingResult;
  end;
  INXBindingSource = interface(INXBindingObservable) ['INXBindingSource']
    function Attach(ASource: TObject): TNXBindingResult;
    function GetCurrent: INXBindingItem;
    function First: TNXBindingResult;
    function Prior: TNXBindingResult;
    function Next: TNXBindingResult;
    function Last: TNXBindingResult;
    function Bind(const AMember: UTF8String; ATarget: TObject;
      AMode: TNXBindingMode; ATrigger: TNXBindingTrigger;
      out ABinding: QWord; AConverter: INXBindingConverter = nil;
      AValidator: INXBindingValidator = nil): TNXBindingResult;
    function Remove(ABinding: QWord): TNXBindingResult;
    function GetState(ABinding: QWord; out AState: TNXBindingState): TNXBindingResult;
    function Refresh: TNXBindingResult;
    function Submit(ABinding: QWord): TNXBindingResult;
    function SubmitAll: TNXBindingResult;
    function CancelPending(ABinding: QWord): TNXBindingResult;
    function Rebase(ABinding: QWord): TNXBindingResult;
    function CommitEdit: TNXBindingResult;
    function CancelEdit: TNXBindingResult;
    function GetDirty: Boolean;
  end;

implementation

class function TNXBindingValue.Empty(AKind: TNXBindingKind;
  APresence: TNXBindingPresence): TNXBindingValue;
begin
  Result := Default(TNXBindingValue);
  Result.Kind := AKind;
  Result.Presence := APresence;
end;

class function TNXBindingValue.FromBoolean(AValue: Boolean): TNXBindingValue;
begin
  Result := Empty(bkBoolean, bpValue);
  Result.BooleanValue := AValue;
end;

class function TNXBindingValue.FromInteger(AValue: Int64): TNXBindingValue;
begin
  Result := Empty(bkInt64, bpValue);
  Result.IntegerValue := AValue;
end;

class function TNXBindingValue.FromDouble(AValue: Double): TNXBindingValue;
begin
  Result := Empty(bkDouble, bpValue);
  Result.DoubleValue := AValue;
end;

class function TNXBindingValue.FromString(const AValue: UTF8String): TNXBindingValue;
begin
  Result := Empty(bkString, bpValue);
  Result.StringValue := AValue;
end;

class function TNXBindingValue.FromDateTime(AValue: TDateTime): TNXBindingValue;
begin
  Result := Empty(bkDateTime, bpValue);
  Result.DateTimeValue := AValue;
end;

class function TNXBindingValue.FromCurrency(AValue: Currency): TNXBindingValue;
begin
  Result := Empty(bkCurrency, bpValue);
  Result.CurrencyValue := AValue;
end;

function TNXBindingValue.SameValue(const AOther: TNXBindingValue): Boolean;
begin
  Result := (Kind = AOther.Kind) and (Presence = AOther.Presence);
  if not Result or (Presence <> bpValue) then Exit;
  case Kind of
    bkBoolean: Result := BooleanValue = AOther.BooleanValue;
    bkInt64: Result := IntegerValue = AOther.IntegerValue;
    bkDouble: Result := DoubleValue = AOther.DoubleValue;
    bkString: Result := StringValue = AOther.StringValue;
    bkDateTime: Result := DateTimeValue = AOther.DateTimeValue;
    bkCurrency: Result := CurrencyValue = AOther.CurrencyValue;
  end;
end;

class function TNXBindingResult.Make(ACode: TNXBindingCode;
  const AMessage: string): TNXBindingResult;
begin
  Result.Code := ACode;
  Result.MessageText := AMessage;
  Result.Binding := 0;
end;

function TNXBindingResult.Succeeded: Boolean;
begin
  Result := Code in [bcSuccess, bcNoMovement];
end;

function TNXBindingDescriptor.Check(const AValue: TNXBindingValue): TNXBindingResult;
begin
  if Kind <> AValue.Kind then
    Exit(TNXBindingResult.Make(bcWrongKind));
  if ((AValue.Presence = bpNull) and not AcceptsNull) or
    ((AValue.Presence = bpUnset) and not AcceptsUnset) then
    Exit(TNXBindingResult.Make(bcRejected, 'Value presence is not accepted.'));
  Result := TNXBindingResult.Make(bcSuccess);
end;

end.

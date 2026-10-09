(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tsNXBindingContracts;

{$mode objfpc}{$H+}{$interfaces corba}

interface

uses obNXTestRegistry, obNXTestContext;

procedure RegisterBindingContracts(ARegistry: TNXTestRegistry);
procedure CheckEndpoint(AContext: TNXTestContext; AEndpoint: TObject);

implementation

uses SysUtils, tpNXBinding, obNXBindingTestObjects, obNXBindingSource;

procedure ScalarRoundTrips(AContext: TNXTestContext);
var
  lKind: TNXBindingKind;
  lPresence: TNXBindingPresence;
  lValue: TNXBindingValue;
  lSource: TTestScalarSource;
  lTarget: TTestTarget;
  lBinding: TNXBindingSource;
  lHandle: QWord;
begin
  for lKind := Low(TNXBindingKind) to High(TNXBindingKind) do
  begin
    case lKind of
      bkBoolean: lValue := TNXBindingValue.FromBoolean(True);
      bkInt64: lValue := TNXBindingValue.FromInteger(High(Int64));
      bkDouble: lValue := TNXBindingValue.FromDouble(1.25);
      bkString: lValue := TNXBindingValue.FromString('Unicode: ' + #$C3#$A9);
      bkDateTime: lValue := TNXBindingValue.FromDateTime(EncodeDate(2026, 9, 14) + 0.5);
      bkCurrency: lValue := TNXBindingValue.FromCurrency(-123456.7891);
    end;
    lSource := TTestScalarSource.Create(lValue);
    lTarget := TTestTarget.Create(TNXBindingValue.Empty(lKind, bpUnset));
    lBinding := TNXBindingSource.Create;
    try
      lBinding.Attach(lSource);
      AContext.AssertTrue(lBinding.Bind('Value', lTarget, bmTwoWay, btExplicit, lHandle).Succeeded);
      AContext.AssertTrue(lValue.SameValue(lTarget.Value));
      for lPresence := bpUnset to bpNull do
      begin
        lTarget.SetValue(TNXBindingValue.Empty(lKind, lPresence));
        AContext.AssertTrue(lBinding.Submit(lHandle).Succeeded);
        AContext.AssertTrue(lSource.Endpoint.Value.SameValue(lTarget.Value));
      end;
      lTarget.SetValue(lValue);
      AContext.AssertTrue(lBinding.Submit(lHandle).Succeeded);
      AContext.AssertTrue(lSource.Endpoint.Value.SameValue(lValue));
    finally
      lBinding.Free;
      lTarget.Free;
      lSource.Free;
    end;
  end;
end;

procedure ReadOnlyAndWrongKind(AContext: TNXTestContext);
var
  lSource: TTestScalarSource;
  lTarget: TTestTarget;
  lBinding: TNXBindingSource;
  lHandle: QWord;
begin
  lSource := TTestScalarSource.Create(TNXBindingValue.FromInteger(10), True);
  lTarget := TTestTarget.Create(TNXBindingValue.FromString('old'));
  lBinding := TNXBindingSource.Create;
  try
    lBinding.Attach(lSource);
    AContext.AssertEquals(Ord(bcWrongKind), Ord(lBinding.Bind('Value', lTarget,
      bmTwoWay, btExplicit, lHandle).Code));
    lBinding.Remove(lHandle);
    FreeAndNil(lTarget);
    lTarget := TTestTarget.Create(TNXBindingValue.FromInteger(0));
    AContext.AssertTrue(lBinding.Bind('Value', lTarget, bmTwoWay, btExplicit, lHandle).Succeeded);
    lTarget.SetValue(TNXBindingValue.FromInteger(20));
    AContext.AssertEquals(Ord(bcReadOnly), Ord(lBinding.Submit(lHandle).Code));
    AContext.AssertTrue(lSource.Endpoint.Value.IntegerValue = 10);
  finally
    lBinding.Free;
    lTarget.Free;
    lSource.Free;
  end;
end;

procedure CheckEndpoint(AContext: TNXTestContext; AEndpoint: TObject);
var
  lValue: INXBindingValue;
  lWriter: INXBindingWritableValue;
  lBefore, lAfter: TNXBindingValue;
begin
  AContext.AssertTrue(Supports(AEndpoint, INXBindingValue, lValue));
  AContext.AssertTrue(lValue.TryRead(lBefore).Succeeded);
  if Supports(AEndpoint, INXBindingWritableValue, lWriter) then
  begin
    AContext.AssertTrue(lWriter.TryWrite(lBefore).Succeeded);
    lValue.TryRead(lAfter);
    AContext.AssertTrue(lBefore.SameValue(lAfter));
  end;
end;

procedure Capabilities(AContext: TNXTestContext);
var
  lReadOnly: TTestValue;
  lTarget: TTestTarget;
  lReadable: INXBindingValue;
  lWriter: INXBindingWritableValue;
begin
  lReadOnly := TTestValue.Create(TNXBindingValue.FromString('read only'));
  lTarget := TTestTarget.Create(TNXBindingValue.FromString('writable'));
  try
    AContext.AssertTrue(lReadOnly is INXBindingValue);
    lReadable := lReadOnly as INXBindingValue;
    AContext.AssertTrue(lReadable.GetDescriptor.Readable);
    AContext.AssertFalse(Supports(lReadOnly, INXBindingWritableValue, lWriter));
    AContext.AssertTrue(Supports(lTarget, INXBindingWritableValue, lWriter));
    CheckEndpoint(AContext, lReadOnly);
    CheckEndpoint(AContext, lTarget);
    lReadable := nil;
    lWriter := nil;
    { Dropping borrowed interfaces must leave the owned objects usable. }
    AContext.AssertTrue(lTarget.TryWrite(TNXBindingValue.FromString('alive')).Succeeded);
    AContext.AssertTrue(lReadOnly.GetDescriptor.Readable);
  finally
    lTarget.Free;
    lReadOnly.Free;
  end;
end;

procedure ValueKinds(AContext: TNXTestContext);
var
  lValue: TNXBindingValue;
begin
  lValue := TNXBindingValue.FromString('');
  AContext.AssertFalse(lValue.SameValue(TNXBindingValue.Empty(bkString, bpNull)));
  AContext.AssertFalse(lValue.SameValue(TNXBindingValue.Empty(bkString, bpUnset)));
  lValue := TNXBindingValue.FromCurrency(-12.3456);
  AContext.AssertTrue(lValue.CurrencyValue = Currency(-12.3456));
  AContext.AssertFalse(lValue.SameValue(TNXBindingValue.FromDouble(-12.3456)));
end;

procedure RegisterBindingContracts(ARegistry: TNXTestRegistry);
begin
  ARegistry.AddSuite('Binding.Contracts').AddTest('ValueKinds', @ValueKinds);
  ARegistry.AddSuite('Binding.Contracts').AddTest('Capabilities', @Capabilities);
  ARegistry.AddSuite('Binding.Contracts').AddTest('ScalarRoundTrips', @ScalarRoundTrips);
  ARegistry.AddSuite('Binding.Contracts').AddTest('ReadOnlyAndWrongKind', @ReadOnlyAndWrongKind);
end;

end.

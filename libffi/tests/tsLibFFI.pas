// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit tsLibFFI;
{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$packset 1}

interface

uses obNXTestRegistry;
procedure RegisterLibFFITests(ARegistry: TNXTestRegistry);

implementation

uses
  SysUtils, TypInfo, Rtti, ffi, ffi.manager,
  obNXTestContext, obNXTestSuite;

type
  TAddFunction = function(AFirst, ASecond: LongInt): LongInt; cdecl;
  TStringFunction = function(AValue: LongInt): AnsiString; cdecl;
  TInner = record
    Value: LongInt;
  end;
  TAggregate = record
    Items: array[0..1] of TInner;
  end;
  TLargeSet = set of 0..95;
  TRecordFunction = function(AValue: TAggregate): LongInt; cdecl;
  TSetField = record
    Prefix: QWord;
    Bits: TLargeSet;
  end;
  TShortStringField = record
    Text: string[7];
    Value: Double;
  end;
  TShortStringRecordFunction = function(AValue: TShortStringField): Double; cdecl;

function Add(AFirst, ASecond: LongInt): LongInt; cdecl;
begin
  Result := AFirst + ASecond;
end;

function NoArgText: AnsiString; cdecl;
begin
  Result := 'Nexus';
end;

function SumRecord(AValue: TAggregate): LongInt; cdecl;
begin
  Result := AValue.Items[0].Value + AValue.Items[1].Value;
end;

function CountSet(AValue: TLargeSet): LongInt; cdecl;
var
  lBit: Integer;
begin
  Result := 0;
  for lBit := 0 to 95 do
    if lBit in AValue then Inc(Result);
end;

function ReturnSet: TLargeSet; cdecl;
begin
  Result := [0, 5, 95];
end;

function ReadSetField(AValue: TSetField): LongInt; cdecl;
begin
  Result := AValue.Prefix + CountSet(AValue.Bits);
end;

function ReadShortStringField(AValue: TShortStringField): Double; cdecl;
begin
  Result := Length(AValue.Text) + AValue.Value;
end;

function ReturnShortStringField: TShortStringField; cdecl;
begin
  Result.Text := 'Nexus';
  Result.Value := 5.5;
end;

procedure ShortStringRecordHandler(const AArgs: specialize TArray<Pointer>;
  AResult: Pointer; AContext: Pointer);
type
  PShortStringField = ^TShortStringField;
begin
  PDouble(AResult)^ := ReadShortStringField(PShortStringField(AArgs[0])^);
end;

procedure AddHandler(const AArgs: specialize TArray<Pointer>; AResult: Pointer;
  AContext: Pointer);
begin
  if (Length(AArgs) <> 2) or (AArgs[0] = nil) or (AArgs[1] = nil) then
    PLongInt(AResult)^ := -1
  else
    PLongInt(AResult)^ := PLongInt(AArgs[0])^ + PLongInt(AArgs[1])^;
end;

procedure StringHandler(const AArgs: specialize TArray<Pointer>; AResult: Pointer;
  AContext: Pointer);
begin
  PAnsiString(AResult)^ := 'Nexus ' + IntToStr(PLongInt(AArgs[0])^);
end;

procedure RecordHandler(const AArgs: specialize TArray<Pointer>; AResult: Pointer;
  AContext: Pointer);
type
  PAggregate = ^TAggregate;
begin
  PLongInt(AResult)^ := SumRecord(PAggregate(AArgs[0])^);
end;

procedure TestNumericInvoke(AContext: TNXTestContext);
var
  lManager: TFunctionCallManager;
  lArgs: TFunctionCallParameterArray;
  lFirst, lSecond, lResult: LongInt;
begin
  GetFunctionCallManager(ccCdecl, lManager);
  lFirst := 20; lSecond := 22; lResult := 0;
  SetLength(lArgs, 2);
  lArgs[0].Info.ParamType := TypeInfo(LongInt);
  lArgs[0].ValueRef := @lFirst;
  lArgs[1].Info.ParamType := TypeInfo(LongInt);
  lArgs[1].ValueRef := @lSecond;
  lManager.Invoke(@Add, lArgs, ccCdecl, TypeInfo(LongInt), @lResult, [fcfStatic]);
  AContext.AssertEquals(42, lResult);
end;

procedure TestNarrowResult(AContext: TNXTestContext);
var
  lManager: TFunctionCallManager;
  lArgs: TFunctionCallParameterArray;
  lFirst, lSecond: LongInt;
  lOutput: packed record
    Value: LongInt;
    Guard: LongWord;
  end;
begin
  GetFunctionCallManager(ccCdecl, lManager);
  lFirst := 20; lSecond := 22;
  lOutput.Value := 0; lOutput.Guard := $12345678;
  SetLength(lArgs, 2);
  lArgs[0].Info.ParamType := TypeInfo(LongInt);
  lArgs[0].ValueRef := @lFirst;
  lArgs[1].Info.ParamType := TypeInfo(LongInt);
  lArgs[1].ValueRef := @lSecond;
  lManager.Invoke(@Add, lArgs, ccCdecl, TypeInfo(LongInt), @lOutput.Value, [fcfStatic]);
  AContext.AssertEquals(42, lOutput.Value);
  AContext.AssertEquals($12345678, lOutput.Guard, 'Invocation must write only the declared result storage');
end;

procedure TestCallbackArguments(AContext: TNXTestContext);
var
  lArgs: array[0..1] of TFunctionCallParameterInfo;
  lCallback: TFunctionCallCallback;
  lFunction: TAddFunction;
begin
  FillChar(lArgs, SizeOf(lArgs), 0);
  lArgs[0].ParamType := TypeInfo(LongInt);
  lArgs[1].ParamType := TypeInfo(LongInt);
  lCallback := CreateCallbackProc(@AddHandler, ccCdecl, lArgs, TypeInfo(LongInt), [fcfStatic], nil);
  try
    lFunction := TAddFunction(lCallback.CodeAddress);
    AContext.AssertEquals(42, lFunction(20, 22));
  finally
    lCallback.Free;
  end;
end;

procedure TestManagedCallback(AContext: TNXTestContext);
var
  lArgs: array[0..0] of TFunctionCallParameterInfo;
  lCallback: TFunctionCallCallback;
  lFunction: TStringFunction;
begin
  FillChar(lArgs, SizeOf(lArgs), 0);
  lArgs[0].ParamType := TypeInfo(LongInt);
  lCallback := CreateCallbackProc(@StringHandler, ccCdecl, lArgs, TypeInfo(AnsiString), [fcfStatic], nil);
  try
    lFunction := TStringFunction(lCallback.CodeAddress);
    AContext.AssertEquals('Nexus 42', lFunction(42));
  finally
    lCallback.Free;
  end;
end;

procedure TestNoArgManagedResult(AContext: TNXTestContext);
var
  lManager: TFunctionCallManager;
  lResult: AnsiString;
begin
  GetFunctionCallManager(ccCdecl, lManager);
  lManager.Invoke(@NoArgText, [], ccCdecl, TypeInfo(AnsiString), @lResult, [fcfStatic]);
  AContext.AssertEquals('Nexus', lResult);
end;

procedure TestInvokeOwnership(AContext: TNXTestContext);
var
  lManager: TFunctionCallManager;
  lArgs: TFunctionCallParameterArray;
  lRecord: TAggregate;
  lResult: ffi_arg;
  lIndex: LongInt;
  lBefore, lAfter: QWord;
begin
  lResult := 0;
  GetFunctionCallManager(ccCdecl, lManager);
  lRecord.Items[0].Value := 20; lRecord.Items[1].Value := 22;
  SetLength(lArgs, 1);
  lArgs[0].Info.ParamType := TypeInfo(TAggregate);
  lArgs[0].ValueRef := @lRecord;
  for lIndex := 1 to 16 do
    lManager.Invoke(@SumRecord, lArgs, ccCdecl, TypeInfo(LongInt), @lResult, [fcfStatic]);
  lBefore := GetFPCHeapStatus.CurrHeapUsed;
  for lIndex := 1 to 1000 do
    lManager.Invoke(@SumRecord, lArgs, ccCdecl, TypeInfo(LongInt), @lResult, [fcfStatic]);
  lAfter := GetFPCHeapStatus.CurrHeapUsed;
  AContext.AssertEquals(42, lResult, 'Aggregate invocation returned ' + IntToStr(lResult));
  AContext.AssertTrue(lAfter <= lBefore + 128,
    'Repeated aggregate invocation grew the Pascal heap by ' + IntToStr(Int64(lAfter) - Int64(lBefore)));
end;

procedure TestCallbackOwnership(AContext: TNXTestContext);
var
  lArgs: array[0..0] of TFunctionCallParameterInfo;
  lCallback: TFunctionCallCallback;
  lFunction: TRecordFunction;
  lRecord: TAggregate;
  lIndex, lResult: LongInt;
  lBefore, lAfter: QWord;
begin
  FillChar(lArgs, SizeOf(lArgs), 0);
  lArgs[0].ParamType := TypeInfo(TAggregate);
  lRecord.Items[0].Value := 20; lRecord.Items[1].Value := 22;
  lCallback := CreateCallbackProc(@RecordHandler, ccCdecl, lArgs, TypeInfo(LongInt), [fcfStatic], nil);
  lCallback.Free;
  lBefore := GetFPCHeapStatus.CurrHeapUsed;
  for lIndex := 1 to 500 do
  begin
    lCallback := CreateCallbackProc(@RecordHandler, ccCdecl, lArgs, TypeInfo(LongInt), [fcfStatic], nil);
    try
      lFunction := TRecordFunction(lCallback.CodeAddress);
      lResult := lFunction(lRecord);
    finally
      lCallback.Free;
    end;
  end;
  lAfter := GetFPCHeapStatus.CurrHeapUsed;
  AContext.AssertEquals(42, lResult, 'Aggregate invocation returned ' + IntToStr(lResult));
  AContext.AssertTrue(lAfter <= lBefore + 128,
    'Repeated aggregate callbacks grew the Pascal heap by ' + IntToStr(Int64(lAfter) - Int64(lBefore)));
end;

procedure TestLargeSetInvoke(AContext: TNXTestContext);
var
  lManager: TFunctionCallManager;
  lArgs: TFunctionCallParameterArray;
  lSet: TLargeSet;
  lResult: ffi_arg;
  lIndex: LongInt;
  lBefore, lAfter: QWord;
begin
  AContext.AssertTrue(SizeOf(TLargeSet) > 4);
  lResult := 0;
  GetFunctionCallManager(ccCdecl, lManager);
  lSet := [0, 5, 95];
  SetLength(lArgs, 1);
  lArgs[0].Info.ParamType := TypeInfo(TLargeSet);
  lArgs[0].ValueRef := @lSet;
  for lIndex := 1 to 16 do
    lManager.Invoke(@CountSet, lArgs, ccCdecl, TypeInfo(LongInt), @lResult, [fcfStatic]);
  lBefore := GetFPCHeapStatus.CurrHeapUsed;
  for lIndex := 1 to 1000 do
    lManager.Invoke(@CountSet, lArgs, ccCdecl, TypeInfo(LongInt), @lResult, [fcfStatic]);
  lAfter := GetFPCHeapStatus.CurrHeapUsed;
  AContext.AssertEquals(3, lResult, 'Set invocation returned ' + IntToStr(lResult));
  AContext.AssertTrue(lAfter <= lBefore + 128,
    'Repeated set invocation grew the Pascal heap by ' + IntToStr(Int64(lAfter) - Int64(lBefore)));
end;

procedure TestLargeSetResult(AContext: TNXTestContext);
var
  lManager: TFunctionCallManager;
  lResult: TLargeSet;
begin
  GetFunctionCallManager(ccCdecl, lManager);
  lResult := [];
  lManager.Invoke(@ReturnSet, [], ccCdecl, TypeInfo(TLargeSet), @lResult, [fcfStatic]);
  AContext.AssertTrue(lResult = [0, 5, 95]);
end;

procedure TestSetField(AContext: TNXTestContext);
var
  lManager: TFunctionCallManager;
  lArgs: TFunctionCallParameterArray;
  lRecord: TSetField;
  lResult: ffi_arg;
begin
  GetFunctionCallManager(ccCdecl, lManager);
  lRecord.Prefix := 200; lRecord.Bits := [0, 5, 95]; lResult := 0;
  SetLength(lArgs, 1);
  lArgs[0].Info.ParamType := TypeInfo(TSetField);
  lArgs[0].ValueRef := @lRecord;
  lManager.Invoke(@ReadSetField, lArgs, ccCdecl, TypeInfo(LongInt), @lResult, [fcfStatic]);
  AContext.AssertEquals(203, lResult);
end;

procedure TestShortStringField(AContext: TNXTestContext);
var
  lManager: TFunctionCallManager;
  lArgs: TFunctionCallParameterArray;
  lRecord: TShortStringField;
  lResult: Double;
begin
  GetFunctionCallManager(ccCdecl, lManager);
  lRecord.Text := 'Nexus';
  lRecord.Value := 5.5;
  lResult := 0;
  SetLength(lArgs, 1);
  lArgs[0].Info.ParamType := TypeInfo(TShortStringField);
  lArgs[0].ValueRef := @lRecord;
  lManager.Invoke(@ReadShortStringField, lArgs, ccCdecl, TypeInfo(Double), @lResult, [fcfStatic]);
  AContext.AssertTrue(Abs(lResult - 10.5) < 0.00001,
    'Shortstring fields must preserve the ABI classification of following fields');
end;

procedure TestShortStringRecordCallback(AContext: TNXTestContext);
var
  lArgs: array[0..0] of TFunctionCallParameterInfo;
  lCallback: TFunctionCallCallback;
  lFunction: TShortStringRecordFunction;
  lRecord: TShortStringField;
begin
  FillChar(lArgs, SizeOf(lArgs), 0);
  lArgs[0].ParamType := TypeInfo(TShortStringField);
  lRecord.Text := 'Nexus';
  lRecord.Value := 5.5;
  lCallback := CreateCallbackProc(@ShortStringRecordHandler, ccCdecl, lArgs,
    TypeInfo(Double), [fcfStatic], nil);
  try
    lFunction := TShortStringRecordFunction(lCallback.CodeAddress);
    AContext.AssertTrue(Abs(lFunction(lRecord) - 10.5) < 0.00001);
  finally
    lCallback.Free;
  end;
end;

procedure TestShortStringRecordResult(AContext: TNXTestContext);
var
  lManager: TFunctionCallManager;
  lResult: TShortStringField;
begin
  GetFunctionCallManager(ccCdecl, lManager);
  lResult.Text := '';
  lResult.Value := 0;
  lManager.Invoke(@ReturnShortStringField, [], ccCdecl,
    TypeInfo(TShortStringField), @lResult, [fcfStatic]);
  AContext.AssertEquals('Nexus', lResult.Text);
  AContext.AssertTrue(Abs(lResult.Value - 5.5) < 0.00001);
end;

procedure RegisterLibFFITests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('LibFFI');
  lSuite.AddTest('NumericInvoke', @TestNumericInvoke);
  lSuite.AddTest('NarrowResult', @TestNarrowResult);
  lSuite.AddTest('CallbackArguments', @TestCallbackArguments);
  lSuite.AddTest('ManagedCallback', @TestManagedCallback);
  lSuite.AddTest('NoArgManagedResult', @TestNoArgManagedResult);
  lSuite.AddTest('InvokeOwnership', @TestInvokeOwnership);
  lSuite.AddTest('CallbackOwnership', @TestCallbackOwnership);
  lSuite.AddTest('LargeSetInvoke', @TestLargeSetInvoke);
  lSuite.AddTest('LargeSetResult', @TestLargeSetResult);
  lSuite.AddTest('SetField', @TestSetField);
  lSuite.AddTest('ShortStringField', @TestShortStringField);
  lSuite.AddTest('ShortStringRecordCallback', @TestShortStringRecordCallback);
  lSuite.AddTest('ShortStringRecordResult', @TestShortStringRecordResult);
end;
end.

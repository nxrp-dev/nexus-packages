unit tcmig_layoututil;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpg_mig_layoututil, fpg_mig_resizeconstraint, fpg_mig_boundsize,
  fpg_mig_unitvalue;

type
  { Test TfpgMigLayoutUtil }
  TTestLayoutUtil = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    procedure TestCalculateSerial_EqualPreferred;
    procedure TestCalculateSerial_GrowSingleComponent;
    procedure TestCalculateSerial_GrowMultipleWithPriority;
    procedure TestCalculateSerial_ShrinkSingleComponent;
    procedure TestCalculateSerial_ShrinkMultipleWithPriority;
    procedure TestCalculateSerial_ExactFit;
    procedure TestCalculateSerial_MinMaxConstraints;
    procedure TestCalculateSerial_NoResizeConstraints;
    procedure TestSum_PartialArray;
    procedure TestSum_FullArray;
    procedure TestSum_EmptyArray;
    procedure TestClamp_Float;
    procedure TestClamp_Integer;
    procedure TestRoundSizes;
    procedure TestGetSizeSafe_ValidSize;
    procedure TestGetSizeSafe_NotSet;
    procedure TestGetIndexSafe_ValidIndex;
    procedure TestGetIndexSafe_OutOfBounds;
    procedure TestGetIndexSafe_EmptyArray;
    procedure TestDerive_AllNewValues;
    procedure TestDerive_PartialNewValues;
    procedure TestDerive_NilBase;
    procedure TestObjectEquals_BothNil;
    procedure TestObjectEquals_OneNil;
    procedure TestObjectEquals_BothSame;
    procedure TestObjectEquals_Different;
  end;

procedure RegistertcmiglayoututilTests(ARegistry: TNXTestRegistry);

implementation



{ TTestLayoutUtil }

procedure TTestLayoutUtil.TestCalculateSerial_EqualPreferred;
var
  sizes: TfpgMigSizeArrayArray;
  resConstr: TfpgMigResizeConstraintArray;
  defPush: TfpgMigFloatArray;
  result: TfpgMigIntegerArray;
begin
  // Three components, each wants 100, space is 300 - perfect fit
  SetLength(sizes, 3);
  sizes[0][SIZE_MIN] := 50;
  sizes[0][SIZE_PREF] := 100;
  sizes[0][SIZE_MAX] := 200;
  sizes[1][SIZE_MIN] := 50;
  sizes[1][SIZE_PREF] := 100;
  sizes[1][SIZE_MAX] := 200;
  sizes[2][SIZE_MIN] := 50;
  sizes[2][SIZE_PREF] := 100;
  sizes[2][SIZE_MAX] := 200;

  SetLength(resConstr, 0);  // No resize constraints
  SetLength(defPush, 0);

  result := TfpgMigLayoutUtil.CalculateSerial(sizes, resConstr, defPush, SIZE_PREF, 300);

  TestContext.AssertTrue((100)=(result[0]), 'Component 0 size');
  TestContext.AssertTrue((100)=(result[1]), 'Component 1 size');
  TestContext.AssertTrue((100)=(result[2]), 'Component 2 size');
end;

procedure TTestLayoutUtil.TestCalculateSerial_GrowSingleComponent;
var
  sizes: TfpgMigSizeArrayArray;
  resConstr: TfpgMigResizeConstraintArray;
  defPush: TfpgMigFloatArray;
  result: TfpgMigIntegerArray;
  rc: TfpgMigResizeConstraint;
begin
  // One component wants 100, space is 150, can grow
  SetLength(sizes, 1);
  sizes[0][SIZE_MIN] := 50;
  sizes[0][SIZE_PREF] := 100;
  sizes[0][SIZE_MAX] := 200;

  SetLength(resConstr, 1);
  rc := TfpgMigResizeConstraint.Create;
  rc.Grow := 100.0;
  rc.GrowPrio := 100;
  resConstr[0] := rc;

  SetLength(defPush, 0);

  result := TfpgMigLayoutUtil.CalculateSerial(sizes, resConstr, defPush, SIZE_PREF, 150);

  TestContext.AssertTrue((150)=(result[0]), 'Component grew to fill space');

  // Cleanup
  rc.Free;
end;

procedure TTestLayoutUtil.TestCalculateSerial_GrowMultipleWithPriority;
var
  sizes: TfpgMigSizeArrayArray;
  resConstr: TfpgMigResizeConstraintArray;
  defPush: TfpgMigFloatArray;
  result: TfpgMigIntegerArray;
  rc1, rc2: TfpgMigResizeConstraint;
  total: Integer;
begin
  // Two components, equal grow weight, need to share extra space
  SetLength(sizes, 2);
  sizes[0][SIZE_MIN] := 50;
  sizes[0][SIZE_PREF] := 100;
  sizes[0][SIZE_MAX] := 200;
  sizes[1][SIZE_MIN] := 50;
  sizes[1][SIZE_PREF] := 100;
  sizes[1][SIZE_MAX] := 200;

  SetLength(resConstr, 2);
  rc1 := TfpgMigResizeConstraint.Create;
  rc1.Grow := 50.0;  // Equal weight
  rc1.GrowPrio := 100;
  resConstr[0] := rc1;

  rc2 := TfpgMigResizeConstraint.Create;
  rc2.Grow := 50.0;  // Equal weight
  rc2.GrowPrio := 100;
  resConstr[1] := rc2;

  SetLength(defPush, 0);

  result := TfpgMigLayoutUtil.CalculateSerial(sizes, resConstr, defPush, SIZE_PREF, 250);

  // Each should get 25 pixels extra (total 250 = 200 + 50 extra)
  TestContext.AssertTrue((125)=(result[0]), 'Component 0 size');
  TestContext.AssertTrue((125)=(result[1]), 'Component 1 size');

  total := result[0] + result[1];
  TestContext.AssertTrue((250)=(total), 'Total size matches bounds');

  // Cleanup
  rc1.Free;
  rc2.Free;
end;

procedure TTestLayoutUtil.TestCalculateSerial_ShrinkSingleComponent;
var
  sizes: TfpgMigSizeArrayArray;
  resConstr: TfpgMigResizeConstraintArray;
  defPush: TfpgMigFloatArray;
  result: TfpgMigIntegerArray;
  rc: TfpgMigResizeConstraint;
begin
  // One component wants 100, space is 75, can shrink
  SetLength(sizes, 1);
  sizes[0][SIZE_MIN] := 50;
  sizes[0][SIZE_PREF] := 100;
  sizes[0][SIZE_MAX] := 200;

  SetLength(resConstr, 1);
  rc := TfpgMigResizeConstraint.Create;
  rc.Shrink := 100.0;
  rc.ShrinkPrio := 100;
  resConstr[0] := rc;

  SetLength(defPush, 0);

  result := TfpgMigLayoutUtil.CalculateSerial(sizes, resConstr, defPush, SIZE_PREF, 75);

  TestContext.AssertTrue((75)=(result[0]), 'Component shrank to available space');

  // Cleanup
  rc.Free;
end;

procedure TTestLayoutUtil.TestCalculateSerial_ShrinkMultipleWithPriority;
var
  sizes: TfpgMigSizeArrayArray;
  resConstr: TfpgMigResizeConstraintArray;
  defPush: TfpgMigFloatArray;
  result: TfpgMigIntegerArray;
  rc1, rc2: TfpgMigResizeConstraint;
  total: Integer;
begin
  // Two components, equal shrink weight, need to share space reduction
  SetLength(sizes, 2);
  sizes[0][SIZE_MIN] := 50;
  sizes[0][SIZE_PREF] := 100;
  sizes[0][SIZE_MAX] := 200;
  sizes[1][SIZE_MIN] := 50;
  sizes[1][SIZE_PREF] := 100;
  sizes[1][SIZE_MAX] := 200;

  SetLength(resConstr, 2);
  rc1 := TfpgMigResizeConstraint.Create;
  rc1.Shrink := 50.0;  // Equal weight
  rc1.ShrinkPrio := 100;
  resConstr[0] := rc1;

  rc2 := TfpgMigResizeConstraint.Create;
  rc2.Shrink := 50.0;  // Equal weight
  rc2.ShrinkPrio := 100;
  resConstr[1] := rc2;

  SetLength(defPush, 0);

  result := TfpgMigLayoutUtil.CalculateSerial(sizes, resConstr, defPush, SIZE_PREF, 150);

  // Each should shrink by 25 pixels (total 150 = 200 - 50)
  TestContext.AssertTrue((75)=(result[0]), 'Component 0 size');
  TestContext.AssertTrue((75)=(result[1]), 'Component 1 size');

  total := result[0] + result[1];
  TestContext.AssertTrue((150)=(total), 'Total size matches bounds');

  // Cleanup
  rc1.Free;
  rc2.Free;
end;

procedure TTestLayoutUtil.TestCalculateSerial_ExactFit;
var
  sizes: TfpgMigSizeArrayArray;
  resConstr: TfpgMigResizeConstraintArray;
  defPush: TfpgMigFloatArray;
  result: TfpgMigIntegerArray;
begin
  // Space exactly matches preferred sizes
  SetLength(sizes, 2);
  sizes[0][SIZE_MIN] := 50;
  sizes[0][SIZE_PREF] := 100;
  sizes[0][SIZE_MAX] := 200;
  sizes[1][SIZE_MIN] := 50;
  sizes[1][SIZE_PREF] := 100;
  sizes[1][SIZE_MAX] := 200;

  SetLength(resConstr, 0);
  SetLength(defPush, 0);

  result := TfpgMigLayoutUtil.CalculateSerial(sizes, resConstr, defPush, SIZE_PREF, 200);

  TestContext.AssertTrue((100)=(result[0]), 'Component 0 size');
  TestContext.AssertTrue((100)=(result[1]), 'Component 1 size');
end;

procedure TTestLayoutUtil.TestCalculateSerial_MinMaxConstraints;
var
  sizes: TfpgMigSizeArrayArray;
  resConstr: TfpgMigResizeConstraintArray;
  defPush: TfpgMigFloatArray;
  result: TfpgMigIntegerArray;
  rc: TfpgMigResizeConstraint;
begin
  // Component wants to grow but hits max constraint
  SetLength(sizes, 1);
  sizes[0][SIZE_MIN] := 50;
  sizes[0][SIZE_PREF] := 100;
  sizes[0][SIZE_MAX] := 150;  // Max is 150

  SetLength(resConstr, 1);
  rc := TfpgMigResizeConstraint.Create;
  rc.Grow := 100.0;
  rc.GrowPrio := 100;
  resConstr[0] := rc;

  SetLength(defPush, 0);

  result := TfpgMigLayoutUtil.CalculateSerial(sizes, resConstr, defPush, SIZE_PREF, 200);

  // Should be clamped to max of 150
  TestContext.AssertTrue((150)=(result[0]), 'Component clamped to max');

  // Cleanup
  rc.Free;
end;

procedure TTestLayoutUtil.TestCalculateSerial_NoResizeConstraints;
var
  sizes: TfpgMigSizeArrayArray;
  resConstr: TfpgMigResizeConstraintArray;
  defPush: TfpgMigFloatArray;
  result: TfpgMigIntegerArray;
begin
  // No resize constraints, should stay at preferred
  SetLength(sizes, 2);
  sizes[0][SIZE_MIN] := 50;
  sizes[0][SIZE_PREF] := 100;
  sizes[0][SIZE_MAX] := 200;
  sizes[1][SIZE_MIN] := 50;
  sizes[1][SIZE_PREF] := 100;
  sizes[1][SIZE_MAX] := 200;

  SetLength(resConstr, 0);  // Empty array
  SetLength(defPush, 0);

  result := TfpgMigLayoutUtil.CalculateSerial(sizes, resConstr, defPush, SIZE_PREF, 250);

  // Without resize constraints, components don't grow
  TestContext.AssertTrue((100)=(result[0]), 'Component 0 stays at preferred');
  TestContext.AssertTrue((100)=(result[1]), 'Component 1 stays at preferred');
end;

procedure TTestLayoutUtil.TestSum_PartialArray;
var
  arr: TfpgMigIntegerArray;
  result: Integer;
begin
  SetLength(arr, 5);
  arr[0] := 10;
  arr[1] := 20;
  arr[2] := 30;
  arr[3] := 40;
  arr[4] := 50;

  result := TfpgMigLayoutUtil.Sum(arr, 1, 3);  // Sum arr[1..3]
  TestContext.AssertTrue((90)=(result), 'Partial sum');  // 20 + 30 + 40
end;

procedure TTestLayoutUtil.TestSum_FullArray;
var
  arr: TfpgMigIntegerArray;
  result: Integer;
begin
  SetLength(arr, 3);
  arr[0] := 10;
  arr[1] := 20;
  arr[2] := 30;

  result := TfpgMigLayoutUtil.Sum(arr);
  TestContext.AssertTrue((60)=(result), 'Full array sum');
end;

procedure TTestLayoutUtil.TestSum_EmptyArray;
var
  arr: TfpgMigIntegerArray;
  result: Integer;
begin
  SetLength(arr, 0);
  result := TfpgMigLayoutUtil.Sum(arr);
  TestContext.AssertTrue((0)=(result), 'Empty array sum');
end;

procedure TTestLayoutUtil.TestClamp_Float;
var
  result: Single;
begin
  result := TfpgMigLayoutUtil.Clamp(50.0, 0.0, 100.0);
  TestContext.AssertTrue(Abs((50.0)-(result))<=(0.001), 'Within range');

  result := TfpgMigLayoutUtil.Clamp(-10.0, 0.0, 100.0);
  TestContext.AssertTrue(Abs((0.0)-(result))<=(0.001), 'Below min');

  result := TfpgMigLayoutUtil.Clamp(150.0, 0.0, 100.0);
  TestContext.AssertTrue(Abs((100.0)-(result))<=(0.001), 'Above max');
end;

procedure TTestLayoutUtil.TestClamp_Integer;
var
  result: Integer;
begin
  result := TfpgMigLayoutUtil.Clamp(50, 0, 100);
  TestContext.AssertTrue((50)=(result), 'Within range');

  result := TfpgMigLayoutUtil.Clamp(-10, 0, 100);
  TestContext.AssertTrue((0)=(result), 'Below min');

  result := TfpgMigLayoutUtil.Clamp(150, 0, 100);
  TestContext.AssertTrue((100)=(result), 'Above max');
end;

procedure TTestLayoutUtil.TestRoundSizes;
var
  floatArr: TfpgMigFloatArray;
  result: TfpgMigIntegerArray;
begin
  SetLength(floatArr, 4);
  floatArr[0] := 10.4;
  floatArr[1] := 20.5;
  floatArr[2] := 30.6;
  floatArr[3] := 40.2;

  result := TfpgMigLayoutUtil.RoundSizes(floatArr);

  TestContext.AssertTrue((4)=(Length(result)), 'Count matches');
  TestContext.AssertTrue((10)=(result[0]), 'Round 10.4');
  TestContext.AssertTrue((20)=(result[1]), 'Round 20.5');  // FPC uses banker's rounding: 20.5 -> 20 (nearest even)
  TestContext.AssertTrue((31)=(result[2]), 'Round 30.6');
  TestContext.AssertTrue((40)=(result[3]), 'Round 40.2');
end;

procedure TTestLayoutUtil.TestGetSizeSafe_ValidSize;
var
  sizeArr: TfpgMigSizeArray;
  result: Integer;
begin
  sizeArr[SIZE_MIN] := 50;
  sizeArr[SIZE_PREF] := 100;
  sizeArr[SIZE_MAX] := 200;

  result := TfpgMigLayoutUtil.GetSizeSafe(sizeArr, SIZE_PREF);
  TestContext.AssertTrue((100)=(result), 'Get preferred size');
end;

procedure TTestLayoutUtil.TestGetSizeSafe_NotSet;
var
  sizeArr: TfpgMigSizeArray;
  result: Integer;
begin
  sizeArr[SIZE_MIN] := NOT_SET;
  sizeArr[SIZE_PREF] := NOT_SET;
  sizeArr[SIZE_MAX] := NOT_SET;

  result := TfpgMigLayoutUtil.GetSizeSafe(sizeArr, SIZE_PREF);
  TestContext.AssertTrue((0)=(result), 'NOT_SET returns 0');
end;



procedure TTestLayoutUtil.TestGetIndexSafe_ValidIndex;
var
  arr: TfpgMigResizeConstraintArray;
  rc1, rc2: TfpgMigResizeConstraint;
  result: TfpgMigResizeConstraint;
begin
  SetLength(arr, 2);
  rc1 := TfpgMigResizeConstraint.Create;
  rc2 := TfpgMigResizeConstraint.Create;
  arr[0] := rc1;
  arr[1] := rc2;

  result := TfpgMigLayoutUtil.GetIndexSafe(arr, 0);
  TestContext.AssertTrue(result = rc1, 'Returns correct element');

  result := TfpgMigLayoutUtil.GetIndexSafe(arr, 1);
  TestContext.AssertTrue(result = rc2, 'Returns correct element');

  // Cleanup
  rc1.Free;
  rc2.Free;
end;

procedure TTestLayoutUtil.TestGetIndexSafe_OutOfBounds;
var
  arr: TfpgMigResizeConstraintArray;
  rc: TfpgMigResizeConstraint;
  result: TfpgMigResizeConstraint;
begin
  SetLength(arr, 2);
  rc := TfpgMigResizeConstraint.Create;
  arr[0] := rc;
  arr[1] := rc;

  // Out of bounds returns last element
  result := TfpgMigLayoutUtil.GetIndexSafe(arr, 5);
  TestContext.AssertTrue(result = rc, 'Returns last element for out of bounds');

  // Cleanup
  rc.Free;
end;

procedure TTestLayoutUtil.TestGetIndexSafe_EmptyArray;
var
  arr: TfpgMigResizeConstraintArray;
  result: TfpgMigResizeConstraint;
begin
  SetLength(arr, 0);
  result := TfpgMigLayoutUtil.GetIndexSafe(arr, 0);
  TestContext.AssertTrue(result = nil, 'Returns nil for empty array');
end;

procedure TTestLayoutUtil.TestDerive_AllNewValues;
var
  base: TfpgMigBoundSize;
  newMin1, newPref1, newMax1: TfpgMigUnitValue;
  newMin, newPref, newMax: TfpgMigUnitValue;
  result: TfpgMigBoundSize;
begin
  newMin1 := TfpgMigUnitValue.Create(50);
  newPref1 := TfpgMigUnitValue.Create(100);
  newMax1 := TfpgMigUnitValue.Create(200);
  try
     base := TfpgMigBoundSize.Create(newMin1, newPref1, newMax1);
  finally
    newMin1.Free;
    newPref1.Free;
    newMax1.Free;
  end;

  newMin := TfpgMigUnitValue.Create(60);
  newPref := TfpgMigUnitValue.Create(110);
  newMax := TfpgMigUnitValue.Create(210);
  try
     result := TfpgMigLayoutUtil.Derive(base, newMin, newPref, newMax);
  finally
    newMin.Free;
    newPref.Free;
    newMax.Free;
  end;
  TestContext.AssertTrue((60)=(result.Min.Value), 'New min value');
  TestContext.AssertTrue((110)=(result.Preferred.Value), 'New pref value');
  TestContext.AssertTrue((210)=(result.Max.Value), 'New max value');

  // Cleanup - BoundSize clones UnitValues, so we must free originals
  base.Free;
  result.Free;
end;

procedure TTestLayoutUtil.TestDerive_PartialNewValues;
var
  base: TfpgMigBoundSize;
  newPref: TfpgMigUnitValue;
  result: TfpgMigBoundSize;
begin
  base := TfpgMigBoundSize.Create(
    TfpgMigUnitValue.Create(50),
    TfpgMigUnitValue.Create(100),
    TfpgMigUnitValue.Create(200)
  );

  newPref := TfpgMigUnitValue.Create(120);

  result := TfpgMigLayoutUtil.Derive(base, nil, newPref, nil);

  TestContext.AssertTrue((50)=(result.Min.Value), 'Keep base min');
  TestContext.AssertTrue((120)=(result.Preferred.Value), 'Use new pref');
  TestContext.AssertTrue((200)=(result.Max.Value), 'Keep base max');

  // Cleanup - BoundSize clones UnitValues, so we must free originals
  newPref.Free;
  base.Free;
  result.Free;
end;

procedure TTestLayoutUtil.TestDerive_NilBase;
var
  newMin, newPref, newMax: TfpgMigUnitValue;
  result: TfpgMigBoundSize;
begin
  newMin := TfpgMigUnitValue.Create(60);
  newPref := TfpgMigUnitValue.Create(110);
  newMax := TfpgMigUnitValue.Create(210);

  result := TfpgMigLayoutUtil.Derive(nil, newMin, newPref, newMax);

  TestContext.AssertTrue((60)=(result.Min.Value), 'New min value');
  TestContext.AssertTrue((110)=(result.Preferred.Value), 'New pref value');
  TestContext.AssertTrue((210)=(result.Max.Value), 'New max value');

  // Cleanup - BoundSize clones UnitValues, so we must free originals
  newMin.Free;
  newPref.Free;
  newMax.Free;
  result.Free;
end;

procedure TTestLayoutUtil.TestObjectEquals_BothNil;
begin
  TestContext.AssertTrue(TfpgMigLayoutUtil.ObjectEquals(nil, nil), 'Both nil are equal');
end;

procedure TTestLayoutUtil.TestObjectEquals_OneNil;
var
  obj: TObject;
begin
  obj := TObject.Create;
  try
    TestContext.AssertTrue(not (TfpgMigLayoutUtil.ObjectEquals(obj, nil)), 'One nil not equal');
    TestContext.AssertTrue(not (TfpgMigLayoutUtil.ObjectEquals(nil, obj)), 'One nil not equal (reversed)');
  finally
    obj.Free;
  end;
end;

procedure TTestLayoutUtil.TestObjectEquals_BothSame;
var
  obj: TObject;
begin
  obj := TObject.Create;
  try
    TestContext.AssertTrue(TfpgMigLayoutUtil.ObjectEquals(obj, obj), 'Same object equals');
  finally
    obj.Free;
  end;
end;

procedure TTestLayoutUtil.TestObjectEquals_Different;
var
  obj1, obj2: TObject;
begin
  obj1 := TObject.Create;
  obj2 := TObject.Create;
  try
    TestContext.AssertTrue(not (TfpgMigLayoutUtil.ObjectEquals(obj1, obj2)), 'Different objects not equal');
  finally
    obj1.Free;
    obj2.Free;
  end;
end;


constructor TTestLayoutUtil.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestLayoutUtilTestCalculateSerial_EqualPreferred(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestCalculateSerial_EqualPreferred');
  try
    lFixture.TestCalculateSerial_EqualPreferred;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestCalculateSerial_GrowSingleComponent(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestCalculateSerial_GrowSingleComponent');
  try
    lFixture.TestCalculateSerial_GrowSingleComponent;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestCalculateSerial_GrowMultipleWithPriority(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestCalculateSerial_GrowMultipleWithPriority');
  try
    lFixture.TestCalculateSerial_GrowMultipleWithPriority;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestCalculateSerial_ShrinkSingleComponent(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestCalculateSerial_ShrinkSingleComponent');
  try
    lFixture.TestCalculateSerial_ShrinkSingleComponent;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestCalculateSerial_ShrinkMultipleWithPriority(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestCalculateSerial_ShrinkMultipleWithPriority');
  try
    lFixture.TestCalculateSerial_ShrinkMultipleWithPriority;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestCalculateSerial_ExactFit(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestCalculateSerial_ExactFit');
  try
    lFixture.TestCalculateSerial_ExactFit;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestCalculateSerial_MinMaxConstraints(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestCalculateSerial_MinMaxConstraints');
  try
    lFixture.TestCalculateSerial_MinMaxConstraints;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestCalculateSerial_NoResizeConstraints(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestCalculateSerial_NoResizeConstraints');
  try
    lFixture.TestCalculateSerial_NoResizeConstraints;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestSum_PartialArray(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestSum_PartialArray');
  try
    lFixture.TestSum_PartialArray;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestSum_FullArray(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestSum_FullArray');
  try
    lFixture.TestSum_FullArray;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestSum_EmptyArray(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestSum_EmptyArray');
  try
    lFixture.TestSum_EmptyArray;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestClamp_Float(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestClamp_Float');
  try
    lFixture.TestClamp_Float;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestClamp_Integer(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestClamp_Integer');
  try
    lFixture.TestClamp_Integer;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestRoundSizes(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestRoundSizes');
  try
    lFixture.TestRoundSizes;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestGetSizeSafe_ValidSize(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestGetSizeSafe_ValidSize');
  try
    lFixture.TestGetSizeSafe_ValidSize;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestGetSizeSafe_NotSet(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestGetSizeSafe_NotSet');
  try
    lFixture.TestGetSizeSafe_NotSet;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestGetIndexSafe_ValidIndex(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestGetIndexSafe_ValidIndex');
  try
    lFixture.TestGetIndexSafe_ValidIndex;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestGetIndexSafe_OutOfBounds(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestGetIndexSafe_OutOfBounds');
  try
    lFixture.TestGetIndexSafe_OutOfBounds;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestGetIndexSafe_EmptyArray(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestGetIndexSafe_EmptyArray');
  try
    lFixture.TestGetIndexSafe_EmptyArray;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestDerive_AllNewValues(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestDerive_AllNewValues');
  try
    lFixture.TestDerive_AllNewValues;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestDerive_PartialNewValues(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestDerive_PartialNewValues');
  try
    lFixture.TestDerive_PartialNewValues;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestDerive_NilBase(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestDerive_NilBase');
  try
    lFixture.TestDerive_NilBase;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestObjectEquals_BothNil(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestObjectEquals_BothNil');
  try
    lFixture.TestObjectEquals_BothNil;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestObjectEquals_OneNil(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestObjectEquals_OneNil');
  try
    lFixture.TestObjectEquals_OneNil;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestObjectEquals_BothSame(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestObjectEquals_BothSame');
  try
    lFixture.TestObjectEquals_BothSame;
  finally lFixture.Free; end;
end;

procedure RunTTestLayoutUtilTestObjectEquals_Different(AContext: TNXTestContext);
var lFixture: TTestLayoutUtil;
begin
  lFixture:=TTestLayoutUtil.Create(AContext, 'TestObjectEquals_Different');
  try
    lFixture.TestObjectEquals_Different;
  finally lFixture.Free; end;
end;

procedure RegistertcmiglayoututilTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcmig_layoututil.TTestLayoutUtil');
  lSuite.AddTest('TestCalculateSerial_EqualPreferred', @RunTTestLayoutUtilTestCalculateSerial_EqualPreferred);
  lSuite.AddTest('TestCalculateSerial_GrowSingleComponent', @RunTTestLayoutUtilTestCalculateSerial_GrowSingleComponent);
  lSuite.AddTest('TestCalculateSerial_GrowMultipleWithPriority', @RunTTestLayoutUtilTestCalculateSerial_GrowMultipleWithPriority);
  lSuite.AddTest('TestCalculateSerial_ShrinkSingleComponent', @RunTTestLayoutUtilTestCalculateSerial_ShrinkSingleComponent);
  lSuite.AddTest('TestCalculateSerial_ShrinkMultipleWithPriority', @RunTTestLayoutUtilTestCalculateSerial_ShrinkMultipleWithPriority);
  lSuite.AddTest('TestCalculateSerial_ExactFit', @RunTTestLayoutUtilTestCalculateSerial_ExactFit);
  lSuite.AddTest('TestCalculateSerial_MinMaxConstraints', @RunTTestLayoutUtilTestCalculateSerial_MinMaxConstraints);
  lSuite.AddTest('TestCalculateSerial_NoResizeConstraints', @RunTTestLayoutUtilTestCalculateSerial_NoResizeConstraints);
  lSuite.AddTest('TestSum_PartialArray', @RunTTestLayoutUtilTestSum_PartialArray);
  lSuite.AddTest('TestSum_FullArray', @RunTTestLayoutUtilTestSum_FullArray);
  lSuite.AddTest('TestSum_EmptyArray', @RunTTestLayoutUtilTestSum_EmptyArray);
  lSuite.AddTest('TestClamp_Float', @RunTTestLayoutUtilTestClamp_Float);
  lSuite.AddTest('TestClamp_Integer', @RunTTestLayoutUtilTestClamp_Integer);
  lSuite.AddTest('TestRoundSizes', @RunTTestLayoutUtilTestRoundSizes);
  lSuite.AddTest('TestGetSizeSafe_ValidSize', @RunTTestLayoutUtilTestGetSizeSafe_ValidSize);
  lSuite.AddTest('TestGetSizeSafe_NotSet', @RunTTestLayoutUtilTestGetSizeSafe_NotSet);
  lSuite.AddTest('TestGetIndexSafe_ValidIndex', @RunTTestLayoutUtilTestGetIndexSafe_ValidIndex);
  lSuite.AddTest('TestGetIndexSafe_OutOfBounds', @RunTTestLayoutUtilTestGetIndexSafe_OutOfBounds);
  lSuite.AddTest('TestGetIndexSafe_EmptyArray', @RunTTestLayoutUtilTestGetIndexSafe_EmptyArray);
  lSuite.AddTest('TestDerive_AllNewValues', @RunTTestLayoutUtilTestDerive_AllNewValues);
  lSuite.AddTest('TestDerive_PartialNewValues', @RunTTestLayoutUtilTestDerive_PartialNewValues);
  lSuite.AddTest('TestDerive_NilBase', @RunTTestLayoutUtilTestDerive_NilBase);
  lSuite.AddTest('TestObjectEquals_BothNil', @RunTTestLayoutUtilTestObjectEquals_BothNil);
  lSuite.AddTest('TestObjectEquals_OneNil', @RunTTestLayoutUtilTestObjectEquals_OneNil);
  lSuite.AddTest('TestObjectEquals_BothSame', @RunTTestLayoutUtilTestObjectEquals_BothSame);
  lSuite.AddTest('TestObjectEquals_Different', @RunTTestLayoutUtilTestObjectEquals_Different);
end;

end.

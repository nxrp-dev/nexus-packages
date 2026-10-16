unit tcmig_dimconstraint;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpg_mig_dimconstraint, fpg_mig_unitvalue, fpg_mig_boundsize;

type
  TTestMigDimConstraint = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  public
    procedure TestCreate;
    procedure TestGrowPriority;
    procedure TestGrowWeight;
    procedure TestShrinkPriority;
    procedure TestShrinkWeight;
    procedure TestAlign;
    procedure TestAlignOrDefault_Columns;
    procedure TestAlignOrDefault_RowsWithFill;
    procedure TestSize;
    procedure TestSizeWithLinked;
    procedure TestGapBefore;
    procedure TestGapAfter;
    procedure TestSizeGroup;
    procedure TestEndGroup;
    procedure TestFill;
    procedure TestNoGrid;
  end;

procedure RegistertcmigdimconstraintTests(ARegistry: TNXTestRegistry);

implementation

{ TTestMigDimConstraint }

procedure TTestMigDimConstraint.TestCreate;
var
  dc: TfpgMigDimConstraint;
begin
  dc := TfpgMigDimConstraint.Create;
  try
    FContext.AssertTrue((100)=(dc.GetGrowPriority), 'Default grow priority should be 100');
    FContext.AssertTrue(not (dc.HasGrowWeight), 'Should not have grow weight by default');
    FContext.AssertTrue((100)=(dc.GetShrinkPriority), 'Default shrink priority should be 100');
    FContext.AssertTrue(dc.HasShrinkWeight, 'Should have shrink weight by default');
    FContext.AssertTrue(Abs((100.0)-(dc.GetShrinkWeight))<=(0.001), 'Default shrink weight should be 100');
    FContext.AssertTrue(not (dc.IsFill), 'Fill should be false by default');
    FContext.AssertTrue(not (dc.IsNoGrid), 'NoGrid should be false by default');
  finally
    dc.Free;
  end;
end;

procedure TTestMigDimConstraint.TestGrowPriority;
var
  dc: TfpgMigDimConstraint;
begin
  dc := TfpgMigDimConstraint.Create;
  try
    dc.SetGrowPriority(200);
    FContext.AssertTrue((200)=(dc.GetGrowPriority), 'Grow priority should be 200');
  finally
    dc.Free;
  end;
end;

procedure TTestMigDimConstraint.TestGrowWeight;
var
  dc: TfpgMigDimConstraint;
begin
  dc := TfpgMigDimConstraint.Create;
  try
    FContext.AssertTrue(not (dc.HasGrowWeight), 'Should not have grow weight initially');

    dc.SetGrowWeight(1.5);
    FContext.AssertTrue(dc.HasGrowWeight, 'Should have grow weight after setting');
    FContext.AssertTrue(Abs((1.5)-(dc.GetGrowWeight))<=(0.001), 'Grow weight should be 1.5');

    dc.ClearGrowWeight;
    FContext.AssertTrue(not (dc.HasGrowWeight), 'Should not have grow weight after clearing');
  finally
    dc.Free;
  end;
end;

procedure TTestMigDimConstraint.TestShrinkPriority;
var
  dc: TfpgMigDimConstraint;
begin
  dc := TfpgMigDimConstraint.Create;
  try
    dc.SetShrinkPriority(50);
    FContext.AssertTrue((50)=(dc.GetShrinkPriority), 'Shrink priority should be 50');
  finally
    dc.Free;
  end;
end;

procedure TTestMigDimConstraint.TestShrinkWeight;
var
  dc: TfpgMigDimConstraint;
begin
  dc := TfpgMigDimConstraint.Create;
  try
    FContext.AssertTrue(dc.HasShrinkWeight, 'Should have shrink weight initially');
    FContext.AssertTrue(Abs((100.0)-(dc.GetShrinkWeight))<=(0.001), 'Default shrink weight');

    dc.SetShrinkWeight(0.5);
    FContext.AssertTrue(Abs((0.5)-(dc.GetShrinkWeight))<=(0.001), 'Shrink weight should be 0.5');

    dc.ClearShrinkWeight;
    FContext.AssertTrue(not (dc.HasShrinkWeight), 'Should not have shrink weight after clearing');
  finally
    dc.Free;
  end;
end;

procedure TTestMigDimConstraint.TestAlign;
var
  dc: TfpgMigDimConstraint;
  uv: TfpgMigUnitValue;
begin
  dc := TfpgMigDimConstraint.Create;
  uv := TfpgMigUnitValue.Create(10, utPixel, '10px');
  try
    FContext.AssertTrue((dc.GetAlign)=nil, 'Align should be nil by default');

    dc.SetAlign(uv);
    FContext.AssertTrue((uv)=(dc.GetAlign), 'Align should be set value');
  finally
    uv.Free;
    dc.Free;
  end;
end;

procedure TTestMigDimConstraint.TestAlignOrDefault_Columns;
var
  dc: TfpgMigDimConstraint;
  align: TfpgMigUnitValue;
begin
  dc := TfpgMigDimConstraint.Create;
  try
    align := dc.GetAlignOrDefault(True);  // True = columns
    FContext.AssertTrue((UnitValueLeading)=(align), 'Column default alignment should be LEADING');
  finally
    dc.Free;
  end;
end;

procedure TTestMigDimConstraint.TestAlignOrDefault_RowsWithFill;
var
  dc: TfpgMigDimConstraint;
  align: TfpgMigUnitValue;
begin
  dc := TfpgMigDimConstraint.Create;
  try
    dc.SetFill(True);
    align := dc.GetAlignOrDefault(False);  // False = rows
    FContext.AssertTrue((UnitValueCenter)=(align), 'Row alignment with fill should be CENTER');
  finally
    dc.Free;
  end;
end;

procedure TTestMigDimConstraint.TestSize;
var
  dc: TfpgMigDimConstraint;
  bs: TfpgMigBoundSize;
  uv: TfpgMigUnitValue;
begin
  dc := TfpgMigDimConstraint.Create;
  uv := TfpgMigUnitValue.Create(100, utPixel, '100px');
  bs := TfpgMigBoundSize.Create(uv, uv, nil); // bs clones uv
  uv.Free; // Original uv is no longer needed

  try
    FContext.AssertTrue((BoundSizeNullSize)=(dc.GetSize), 'Default size should be NULL_SIZE');

    dc.SetSize(bs); // dc takes ownership of bs
    FContext.AssertTrue((bs)=(dc.GetSize), 'Size should be set value');
  finally
    dc.Free;  // This will free bs and the cloned uv
  end;
end;

procedure TTestMigDimConstraint.TestSizeWithLinked;
var
  dc: TfpgMigDimConstraint;
  bs: TfpgMigBoundSize;
  uv: TfpgMigUnitValue;
  exceptionRaised: Boolean;
begin
  dc := TfpgMigDimConstraint.Create;
  uv := TfpgMigUnitValue.Create(0, utLinkW, 'button1.w');
  bs := TfpgMigBoundSize.Create(uv, nil, nil);
  try
    exceptionRaised := False;
    try
      dc.SetSize(bs);
    except
      on E: Exception do
        exceptionRaised := True;
    end;
    FContext.AssertTrue(exceptionRaised, 'Should raise exception for linked size');
    // Since SetSize raised exception, bs was not transferred to dc
    // so test still owns it
  finally
    bs.Free;  // Still owned by test since SetSize failed
    uv.Free;
    dc.Free;
  end;
end;

procedure TTestMigDimConstraint.TestGapBefore;
var
  dc: TfpgMigDimConstraint;
  gap: TfpgMigBoundSize;
  uv: TfpgMigUnitValue;
begin
  dc := TfpgMigDimConstraint.Create;
  uv := TfpgMigUnitValue.Create(10, utPixel, '10px');
  gap := TfpgMigBoundSize.Create(uv, uv, nil);
  uv.Free; // Original uv is no longer needed

  try
    FContext.AssertTrue(not (dc.HasGapBefore), 'Should not have gap before initially');
    FContext.AssertTrue(not (dc.IsGapBeforePush), 'Should not be push gap initially');

    dc.SetGapBefore(gap); // dc takes ownership of gap
    FContext.AssertTrue(dc.HasGapBefore, 'Should have gap before after setting');
    FContext.AssertTrue((gap)=(dc.GetGapBefore), 'Gap before should be set value');
  finally
    dc.Free;  // This will free gap and the cloned uv
  end;
end;

procedure TTestMigDimConstraint.TestGapAfter;
var
  dc: TfpgMigDimConstraint;
  gap: TfpgMigBoundSize;
  uv: TfpgMigUnitValue;
begin
  dc := TfpgMigDimConstraint.Create;
  uv := TfpgMigUnitValue.Create(10, utPixel, '10px');
  gap := TfpgMigBoundSize.Create(uv, uv, nil, True);  // True = gap push
  uv.Free; // Original uv is no longer needed

  try
    FContext.AssertTrue(not (dc.HasGapAfter), 'Should not have gap after initially');

    dc.SetGapAfter(gap); // dc takes ownership of gap
    FContext.AssertTrue(dc.HasGapAfter, 'Should have gap after after setting');
    FContext.AssertTrue(dc.IsGapAfterPush, 'Should be push gap');
    FContext.AssertTrue((gap)=(dc.GetGapAfter), 'Gap after should be set value');
  finally
    dc.Free;  // This will free gap and the cloned uv
  end;
end;

procedure TTestMigDimConstraint.TestSizeGroup;
var
  dc: TfpgMigDimConstraint;
begin
  dc := TfpgMigDimConstraint.Create;
  try
    FContext.AssertTrue(('')=(dc.GetSizeGroup), 'Size group should be empty by default');

    dc.SetSizeGroup('group1');
    FContext.AssertTrue(('group1')=(dc.GetSizeGroup), 'Size group should be "group1"');
  finally
    dc.Free;
  end;
end;

procedure TTestMigDimConstraint.TestEndGroup;
var
  dc: TfpgMigDimConstraint;
begin
  dc := TfpgMigDimConstraint.Create;
  try
    FContext.AssertTrue(('')=(dc.GetEndGroup), 'End group should be empty by default');

    dc.SetEndGroup('endgroup1');
    FContext.AssertTrue(('endgroup1')=(dc.GetEndGroup), 'End group should be "endgroup1"');
  finally
    dc.Free;
  end;
end;

procedure TTestMigDimConstraint.TestFill;
var
  dc: TfpgMigDimConstraint;
begin
  dc := TfpgMigDimConstraint.Create;
  try
    FContext.AssertTrue(not (dc.IsFill), 'Fill should be false by default');

    dc.SetFill(True);
    FContext.AssertTrue(dc.IsFill, 'Fill should be true after setting');
  finally
    dc.Free;
  end;
end;

procedure TTestMigDimConstraint.TestNoGrid;
var
  dc: TfpgMigDimConstraint;
begin
  dc := TfpgMigDimConstraint.Create;
  try
    FContext.AssertTrue(not (dc.IsNoGrid), 'NoGrid should be false by default');

    dc.SetNoGrid(True);
    FContext.AssertTrue(dc.IsNoGrid, 'NoGrid should be true after setting');
  finally
    dc.Free;
  end;
end;


procedure RunTTestMigDimConstraintTestCreate(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreate';
    lFixture.TestCreate;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestGrowPriority(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGrowPriority';
    lFixture.TestGrowPriority;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestGrowWeight(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGrowWeight';
    lFixture.TestGrowWeight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestShrinkPriority(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestShrinkPriority';
    lFixture.TestShrinkPriority;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestShrinkWeight(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestShrinkWeight';
    lFixture.TestShrinkWeight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestAlign(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAlign';
    lFixture.TestAlign;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestAlignOrDefault_Columns(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAlignOrDefault_Columns';
    lFixture.TestAlignOrDefault_Columns;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestAlignOrDefault_RowsWithFill(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAlignOrDefault_RowsWithFill';
    lFixture.TestAlignOrDefault_RowsWithFill;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestSize(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSize';
    lFixture.TestSize;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestSizeWithLinked(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSizeWithLinked';
    lFixture.TestSizeWithLinked;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestGapBefore(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGapBefore';
    lFixture.TestGapBefore;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestGapAfter(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGapAfter';
    lFixture.TestGapAfter;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestSizeGroup(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSizeGroup';
    lFixture.TestSizeGroup;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestEndGroup(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEndGroup';
    lFixture.TestEndGroup;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestFill(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFill';
    lFixture.TestFill;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestNoGrid(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNoGrid';
    lFixture.TestNoGrid;
  finally lFixture.Free; end;
end;

procedure RegistertcmigdimconstraintTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcmig_dimconstraint.TTestMigDimConstraint');
  lSuite.AddTest('TestCreate', @RunTTestMigDimConstraintTestCreate);
  lSuite.AddTest('TestGrowPriority', @RunTTestMigDimConstraintTestGrowPriority);
  lSuite.AddTest('TestGrowWeight', @RunTTestMigDimConstraintTestGrowWeight);
  lSuite.AddTest('TestShrinkPriority', @RunTTestMigDimConstraintTestShrinkPriority);
  lSuite.AddTest('TestShrinkWeight', @RunTTestMigDimConstraintTestShrinkWeight);
  lSuite.AddTest('TestAlign', @RunTTestMigDimConstraintTestAlign);
  lSuite.AddTest('TestAlignOrDefault_Columns', @RunTTestMigDimConstraintTestAlignOrDefault_Columns);
  lSuite.AddTest('TestAlignOrDefault_RowsWithFill', @RunTTestMigDimConstraintTestAlignOrDefault_RowsWithFill);
  lSuite.AddTest('TestSize', @RunTTestMigDimConstraintTestSize);
  lSuite.AddTest('TestSizeWithLinked', @RunTTestMigDimConstraintTestSizeWithLinked);
  lSuite.AddTest('TestGapBefore', @RunTTestMigDimConstraintTestGapBefore);
  lSuite.AddTest('TestGapAfter', @RunTTestMigDimConstraintTestGapAfter);
  lSuite.AddTest('TestSizeGroup', @RunTTestMigDimConstraintTestSizeGroup);
  lSuite.AddTest('TestEndGroup', @RunTTestMigDimConstraintTestEndGroup);
  lSuite.AddTest('TestFill', @RunTTestMigDimConstraintTestFill);
  lSuite.AddTest('TestNoGrid', @RunTTestMigDimConstraintTestNoGrid);
end;

end.

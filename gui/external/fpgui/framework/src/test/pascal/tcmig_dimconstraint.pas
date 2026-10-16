unit tcmig_dimconstraint;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpg_mig_dimconstraint, fpg_mig_unitvalue, fpg_mig_boundsize;

type
  TTestMigDimConstraint = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
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
    TestContext.AssertTrue((100)=(dc.GetGrowPriority), 'Default grow priority should be 100');
    TestContext.AssertTrue(not (dc.HasGrowWeight), 'Should not have grow weight by default');
    TestContext.AssertTrue((100)=(dc.GetShrinkPriority), 'Default shrink priority should be 100');
    TestContext.AssertTrue(dc.HasShrinkWeight, 'Should have shrink weight by default');
    TestContext.AssertTrue(Abs((100.0)-(dc.GetShrinkWeight))<=(0.001), 'Default shrink weight should be 100');
    TestContext.AssertTrue(not (dc.IsFill), 'Fill should be false by default');
    TestContext.AssertTrue(not (dc.IsNoGrid), 'NoGrid should be false by default');
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
    TestContext.AssertTrue((200)=(dc.GetGrowPriority), 'Grow priority should be 200');
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
    TestContext.AssertTrue(not (dc.HasGrowWeight), 'Should not have grow weight initially');

    dc.SetGrowWeight(1.5);
    TestContext.AssertTrue(dc.HasGrowWeight, 'Should have grow weight after setting');
    TestContext.AssertTrue(Abs((1.5)-(dc.GetGrowWeight))<=(0.001), 'Grow weight should be 1.5');

    dc.ClearGrowWeight;
    TestContext.AssertTrue(not (dc.HasGrowWeight), 'Should not have grow weight after clearing');
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
    TestContext.AssertTrue((50)=(dc.GetShrinkPriority), 'Shrink priority should be 50');
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
    TestContext.AssertTrue(dc.HasShrinkWeight, 'Should have shrink weight initially');
    TestContext.AssertTrue(Abs((100.0)-(dc.GetShrinkWeight))<=(0.001), 'Default shrink weight');

    dc.SetShrinkWeight(0.5);
    TestContext.AssertTrue(Abs((0.5)-(dc.GetShrinkWeight))<=(0.001), 'Shrink weight should be 0.5');

    dc.ClearShrinkWeight;
    TestContext.AssertTrue(not (dc.HasShrinkWeight), 'Should not have shrink weight after clearing');
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
    TestContext.AssertTrue((dc.GetAlign)=nil, 'Align should be nil by default');

    dc.SetAlign(uv);
    TestContext.AssertTrue((uv)=(dc.GetAlign), 'Align should be set value');
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
    TestContext.AssertTrue((UnitValueLeading)=(align), 'Column default alignment should be LEADING');
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
    TestContext.AssertTrue((UnitValueCenter)=(align), 'Row alignment with fill should be CENTER');
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
    TestContext.AssertTrue((BoundSizeNullSize)=(dc.GetSize), 'Default size should be NULL_SIZE');

    dc.SetSize(bs); // dc takes ownership of bs
    TestContext.AssertTrue((bs)=(dc.GetSize), 'Size should be set value');
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
    TestContext.AssertTrue(exceptionRaised, 'Should raise exception for linked size');
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
    TestContext.AssertTrue(not (dc.HasGapBefore), 'Should not have gap before initially');
    TestContext.AssertTrue(not (dc.IsGapBeforePush), 'Should not be push gap initially');

    dc.SetGapBefore(gap); // dc takes ownership of gap
    TestContext.AssertTrue(dc.HasGapBefore, 'Should have gap before after setting');
    TestContext.AssertTrue((gap)=(dc.GetGapBefore), 'Gap before should be set value');
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
    TestContext.AssertTrue(not (dc.HasGapAfter), 'Should not have gap after initially');

    dc.SetGapAfter(gap); // dc takes ownership of gap
    TestContext.AssertTrue(dc.HasGapAfter, 'Should have gap after after setting');
    TestContext.AssertTrue(dc.IsGapAfterPush, 'Should be push gap');
    TestContext.AssertTrue((gap)=(dc.GetGapAfter), 'Gap after should be set value');
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
    TestContext.AssertTrue(('')=(dc.GetSizeGroup), 'Size group should be empty by default');

    dc.SetSizeGroup('group1');
    TestContext.AssertTrue(('group1')=(dc.GetSizeGroup), 'Size group should be "group1"');
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
    TestContext.AssertTrue(('')=(dc.GetEndGroup), 'End group should be empty by default');

    dc.SetEndGroup('endgroup1');
    TestContext.AssertTrue(('endgroup1')=(dc.GetEndGroup), 'End group should be "endgroup1"');
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
    TestContext.AssertTrue(not (dc.IsFill), 'Fill should be false by default');

    dc.SetFill(True);
    TestContext.AssertTrue(dc.IsFill, 'Fill should be true after setting');
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
    TestContext.AssertTrue(not (dc.IsNoGrid), 'NoGrid should be false by default');

    dc.SetNoGrid(True);
    TestContext.AssertTrue(dc.IsNoGrid, 'NoGrid should be true after setting');
  finally
    dc.Free;
  end;
end;


constructor TTestMigDimConstraint.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestMigDimConstraintTestCreate(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create(AContext, 'TestCreate');
  try
    lFixture.TestCreate;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestGrowPriority(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create(AContext, 'TestGrowPriority');
  try
    lFixture.TestGrowPriority;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestGrowWeight(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create(AContext, 'TestGrowWeight');
  try
    lFixture.TestGrowWeight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestShrinkPriority(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create(AContext, 'TestShrinkPriority');
  try
    lFixture.TestShrinkPriority;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestShrinkWeight(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create(AContext, 'TestShrinkWeight');
  try
    lFixture.TestShrinkWeight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestAlign(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create(AContext, 'TestAlign');
  try
    lFixture.TestAlign;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestAlignOrDefault_Columns(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create(AContext, 'TestAlignOrDefault_Columns');
  try
    lFixture.TestAlignOrDefault_Columns;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestAlignOrDefault_RowsWithFill(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create(AContext, 'TestAlignOrDefault_RowsWithFill');
  try
    lFixture.TestAlignOrDefault_RowsWithFill;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestSize(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create(AContext, 'TestSize');
  try
    lFixture.TestSize;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestSizeWithLinked(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create(AContext, 'TestSizeWithLinked');
  try
    lFixture.TestSizeWithLinked;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestGapBefore(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create(AContext, 'TestGapBefore');
  try
    lFixture.TestGapBefore;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestGapAfter(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create(AContext, 'TestGapAfter');
  try
    lFixture.TestGapAfter;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestSizeGroup(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create(AContext, 'TestSizeGroup');
  try
    lFixture.TestSizeGroup;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestEndGroup(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create(AContext, 'TestEndGroup');
  try
    lFixture.TestEndGroup;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestFill(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create(AContext, 'TestFill');
  try
    lFixture.TestFill;
  finally lFixture.Free; end;
end;

procedure RunTTestMigDimConstraintTestNoGrid(AContext: TNXTestContext);
var lFixture: TTestMigDimConstraint;
begin
  lFixture:=TTestMigDimConstraint.Create(AContext, 'TestNoGrid');
  try
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

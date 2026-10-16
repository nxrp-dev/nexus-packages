unit tcmig_ac;

{
  Unit tests for TfpgMigAC (Axis Constraints)
}

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpg_mig_ac, fpg_mig_dimconstraint, fpg_mig_boundsize, fpg_mig_unitvalue;

type
  { Local type alias for test readability }
  TfpgMigDimConstraintArray = fpg_mig_ac.TfpgMigDimConstraintArray;

type
  TTestMigAC = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  public
    { Basic creation and structure }
    procedure TestCreate;
    procedure TestGetCount;
    procedure TestCount;
    procedure TestIndex;

    { NoGrid property }
    procedure TestNoGrid_Current;
    procedure TestNoGrid_Specific;

    { Fill property }
    procedure TestFill_Current;
    procedure TestFill_Specific;

    { Size group }
    procedure TestSizeGroup_Empty;
    procedure TestSizeGroup_Named;
    procedure TestSizeGroup_Specific;

    { Gap methods }
    procedure TestGap_Default;
    procedure TestGap_MoveToNext;

    { Align methods }
    procedure TestAlign_Current;
    procedure TestAlign_Specific;

    { Grow priority }
    procedure TestGrowPrio_Current;
    procedure TestGrowPrio_Specific;

    { Grow weight }
    procedure TestGrow_Default;
    procedure TestGrow_Weight;
    procedure TestGrow_Specific;

    { Shrink priority }
    procedure TestShrinkPrio_Current;
    procedure TestShrinkPrio_Specific;

    { Shrink weight }
    procedure TestShrink_Default;
    procedure TestShrink_Weight;
    procedure TestShrink_Specific;

    { Fluent API chaining }
    procedure TestFluentChaining;

    { Get/Set constraints }
    procedure TestGetConstraints;
    procedure TestSetConstraints;
  end;

procedure RegistertcmigacTests(ARegistry: TNXTestRegistry);

implementation

{ TTestMigAC }

procedure TTestMigAC.TestCreate;
var
  ac: TfpgMigAC;
begin
  ac := TfpgMigAC.Create;
  try
    FContext.AssertTrue((1)=(ac.GetCount), 'Should start with 1 constraint');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestGetCount;
var
  ac: TfpgMigAC;
begin
  ac := TfpgMigAC.Create;
  try
    FContext.AssertTrue((1)=(ac.GetCount), 'Initial count should be 1');

    ac.Index(2);
    FContext.AssertTrue((3)=(ac.GetCount), 'Count should be 3 after Index(2)');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestCount;
var
  ac: TfpgMigAC;
begin
  ac := TfpgMigAC.Create;
  try
    ac.Count(5);
    FContext.AssertTrue((6)=(ac.GetCount), 'Count should be 6 after Count(5)');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestIndex;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.Index(2).Fill;
    constraints := ac.GetConstraints;

    FContext.AssertTrue((3)=(Length(constraints)), 'Should have 3 constraints');
    FContext.AssertTrue(constraints[2].IsFill, 'Index 2 should be filled');
    FContext.AssertTrue(not (constraints[0].IsFill), 'Index 0 should not be filled');
    FContext.AssertTrue(not (constraints[1].IsFill), 'Index 1 should not be filled');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestNoGrid_Current;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.NoGrid;
    constraints := ac.GetConstraints;

    FContext.AssertTrue(constraints[0].IsNoGrid, 'Current (0) should have NoGrid');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestNoGrid_Specific;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.NoGrid(2);
    constraints := ac.GetConstraints;

    FContext.AssertTrue((3)=(Length(constraints)), 'Should have 3 constraints');
    FContext.AssertTrue(constraints[2].IsNoGrid, 'Index 2 should have NoGrid');
    FContext.AssertTrue(not (constraints[0].IsNoGrid), 'Index 0 should not have NoGrid');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestFill_Current;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.Fill;
    constraints := ac.GetConstraints;

    FContext.AssertTrue(constraints[0].IsFill, 'Current (0) should be filled');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestFill_Specific;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.Fill(1);
    constraints := ac.GetConstraints;

    FContext.AssertTrue((2)=(Length(constraints)), 'Should have 2 constraints');
    FContext.AssertTrue(constraints[1].IsFill, 'Index 1 should be filled');
    FContext.AssertTrue(not (constraints[0].IsFill), 'Index 0 should not be filled');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestSizeGroup_Empty;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.SizeGroup;
    constraints := ac.GetConstraints;

    FContext.AssertTrue(('')=(constraints[0].GetSizeGroup), 'Size group should be empty string');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestSizeGroup_Named;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.SizeGroup('group1');
    constraints := ac.GetConstraints;

    FContext.AssertTrue(('group1')=(constraints[0].GetSizeGroup), 'Size group should be "group1"');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestSizeGroup_Specific;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.SizeGroup('mygroup', 2);
    constraints := ac.GetConstraints;

    FContext.AssertTrue(('mygroup')=(constraints[2].GetSizeGroup), 'Index 2 size group should be "mygroup"');
    FContext.AssertTrue(('')=(constraints[0].GetSizeGroup), 'Index 0 size group should be empty');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestGap_Default;
var
  ac: TfpgMigAC;
begin
  ac := TfpgMigAC.Create;
  try
    ac.Gap;
    FContext.AssertTrue((2)=(ac.GetCount), 'Gap should create constraint at new index');

    ac.Gap;
    FContext.AssertTrue((3)=(ac.GetCount), 'Second gap should create constraint at index 2');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestGap_MoveToNext;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.Fill.Gap.Fill;  // Fill index 0, gap, then fill index 1
    constraints := ac.GetConstraints;

    FContext.AssertTrue((2)=(Length(constraints)), 'Should have 2 constraints');
    FContext.AssertTrue(constraints[0].IsFill, 'Index 0 should be filled');
    FContext.AssertTrue(constraints[1].IsFill, 'Index 1 should be filled');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestAlign_Current;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
  align: TfpgMigUnitValue;
begin
  ac := TfpgMigAC.Create;
  try
    ac.Align('center');
    constraints := ac.GetConstraints;

    align := constraints[0].GetAlign;
    FContext.AssertTrue((align)<>nil, 'Alignment should be set');
    FContext.AssertTrue((UnitValueCenter)=(align), 'Should be center alignment');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestAlign_Specific;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.Align('center', 1);
    constraints := ac.GetConstraints;

    FContext.AssertTrue((constraints[1].GetAlign)<>nil, 'Index 1 alignment should be set');
    FContext.AssertTrue((constraints[0].GetAlign)=nil, 'Index 0 alignment should be nil');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestGrowPrio_Current;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.GrowPrio(200);
    constraints := ac.GetConstraints;

    FContext.AssertTrue((200)=(constraints[0].GetGrowPriority), 'Grow priority should be 200');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestGrowPrio_Specific;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.GrowPrio(150, 1);
    constraints := ac.GetConstraints;

    FContext.AssertTrue((150)=(constraints[1].GetGrowPriority), 'Index 1 grow priority should be 150');
    FContext.AssertTrue((100)=(constraints[0].GetGrowPriority), 'Index 0 should have default grow priority');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestGrow_Default;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.Grow;
    constraints := ac.GetConstraints;

    FContext.AssertTrue(constraints[0].HasGrowWeight, 'Should have grow weight');
    FContext.AssertTrue(Abs((100.0)-(constraints[0].GetGrowWeight))<=(0.01), 'Default grow weight should be 100');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestGrow_Weight;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.Grow(50.5);
    constraints := ac.GetConstraints;

    FContext.AssertTrue(constraints[0].HasGrowWeight, 'Should have grow weight');
    FContext.AssertTrue(Abs((50.5)-(constraints[0].GetGrowWeight))<=(0.01), 'Grow weight should be 50.5');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestGrow_Specific;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.Grow(75.0, 2);
    constraints := ac.GetConstraints;

    FContext.AssertTrue(constraints[2].HasGrowWeight, 'Index 2 should have grow weight');
    FContext.AssertTrue(Abs((75.0)-(constraints[2].GetGrowWeight))<=(0.01), 'Index 2 grow weight should be 75');
    FContext.AssertTrue(not (constraints[0].HasGrowWeight), 'Index 0 should not have grow weight');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestShrinkPrio_Current;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.ShrinkPrio(50);
    constraints := ac.GetConstraints;

    FContext.AssertTrue((50)=(constraints[0].GetShrinkPriority), 'Shrink priority should be 50');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestShrinkPrio_Specific;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.ShrinkPrio(75, 1);
    constraints := ac.GetConstraints;

    FContext.AssertTrue((75)=(constraints[1].GetShrinkPriority), 'Index 1 shrink priority should be 75');
    FContext.AssertTrue((100)=(constraints[0].GetShrinkPriority), 'Index 0 should have default shrink priority');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestShrink_Default;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.Shrink;
    constraints := ac.GetConstraints;

    FContext.AssertTrue(constraints[0].HasShrinkWeight, 'Should have shrink weight');
    FContext.AssertTrue(Abs((100.0)-(constraints[0].GetShrinkWeight))<=(0.01), 'Shrink weight should be 100');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestShrink_Weight;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.Shrink(25.5);
    constraints := ac.GetConstraints;

    FContext.AssertTrue(constraints[0].HasShrinkWeight, 'Should have shrink weight');
    FContext.AssertTrue(Abs((25.5)-(constraints[0].GetShrinkWeight))<=(0.01), 'Shrink weight should be 25.5');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestShrink_Specific;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.Shrink(80.0, 1);
    constraints := ac.GetConstraints;

    FContext.AssertTrue(constraints[1].HasShrinkWeight, 'Index 1 should have shrink weight');
    FContext.AssertTrue(Abs((80.0)-(constraints[1].GetShrinkWeight))<=(0.01), 'Index 1 shrink weight should be 80');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestFluentChaining;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    // Chain multiple operations: fill index 0, gap, grow index 1, gap, nogrid index 2
    ac.Fill.Gap.Grow.Gap.NoGrid;
    constraints := ac.GetConstraints;

    FContext.AssertTrue((3)=(Length(constraints)), 'Should have 3 constraints');
    FContext.AssertTrue(constraints[0].IsFill, 'Index 0 should be filled');
    FContext.AssertTrue(constraints[1].HasGrowWeight, 'Index 1 should have grow weight');
    FContext.AssertTrue(constraints[2].IsNoGrid, 'Index 2 should have NoGrid');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestGetConstraints;
var
  ac: TfpgMigAC;
  constraints: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  try
    ac.Index(2);
    constraints := ac.GetConstraints;

    FContext.AssertTrue((3)=(Length(constraints)), 'Should return 3 constraints');
    FContext.AssertTrue((constraints[0])<>nil, 'All constraints should be non-nil');
    FContext.AssertTrue((constraints[1])<>nil, 'All constraints should be non-nil');
    FContext.AssertTrue((constraints[2])<>nil, 'All constraints should be non-nil');
  finally
    ac.Free;
  end;
end;

procedure TTestMigAC.TestSetConstraints;
var
  ac: TfpgMigAC;
  newConstraints: TfpgMigDimConstraintArray;
  dc1, dc2: TfpgMigDimConstraint;
  result: TfpgMigDimConstraintArray;
begin
  ac := TfpgMigAC.Create;
  dc1 := TfpgMigDimConstraint.Create;
  dc2 := TfpgMigDimConstraint.Create;
  try
    dc1.SetFill(True);
    dc2.SetNoGrid(True);

    SetLength(newConstraints, 2);
    newConstraints[0] := dc1;
    newConstraints[1] := dc2;

    ac.SetConstraints(newConstraints);
    result := ac.GetConstraints;

    FContext.AssertTrue((2)=(Length(result)), 'Should have 2 constraints');
    FContext.AssertTrue(result[0].IsFill, 'First constraint should be filled');
    FContext.AssertTrue(result[1].IsNoGrid, 'Second constraint should have NoGrid');
  finally
    ac.Free;
    // Note: ac owns the constraints now, so don't free dc1, dc2
  end;
end;


procedure RunTTestMigACTestCreate(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreate';
    lFixture.TestCreate;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestGetCount(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGetCount';
    lFixture.TestGetCount;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestCount(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCount';
    lFixture.TestCount;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestIndex(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIndex';
    lFixture.TestIndex;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestNoGrid_Current(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNoGrid_Current';
    lFixture.TestNoGrid_Current;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestNoGrid_Specific(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNoGrid_Specific';
    lFixture.TestNoGrid_Specific;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestFill_Current(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFill_Current';
    lFixture.TestFill_Current;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestFill_Specific(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFill_Specific';
    lFixture.TestFill_Specific;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestSizeGroup_Empty(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSizeGroup_Empty';
    lFixture.TestSizeGroup_Empty;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestSizeGroup_Named(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSizeGroup_Named';
    lFixture.TestSizeGroup_Named;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestSizeGroup_Specific(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSizeGroup_Specific';
    lFixture.TestSizeGroup_Specific;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestGap_Default(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGap_Default';
    lFixture.TestGap_Default;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestGap_MoveToNext(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGap_MoveToNext';
    lFixture.TestGap_MoveToNext;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestAlign_Current(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAlign_Current';
    lFixture.TestAlign_Current;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestAlign_Specific(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAlign_Specific';
    lFixture.TestAlign_Specific;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestGrowPrio_Current(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGrowPrio_Current';
    lFixture.TestGrowPrio_Current;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestGrowPrio_Specific(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGrowPrio_Specific';
    lFixture.TestGrowPrio_Specific;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestGrow_Default(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGrow_Default';
    lFixture.TestGrow_Default;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestGrow_Weight(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGrow_Weight';
    lFixture.TestGrow_Weight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestGrow_Specific(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGrow_Specific';
    lFixture.TestGrow_Specific;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestShrinkPrio_Current(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestShrinkPrio_Current';
    lFixture.TestShrinkPrio_Current;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestShrinkPrio_Specific(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestShrinkPrio_Specific';
    lFixture.TestShrinkPrio_Specific;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestShrink_Default(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestShrink_Default';
    lFixture.TestShrink_Default;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestShrink_Weight(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestShrink_Weight';
    lFixture.TestShrink_Weight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestShrink_Specific(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestShrink_Specific';
    lFixture.TestShrink_Specific;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestFluentChaining(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFluentChaining';
    lFixture.TestFluentChaining;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestGetConstraints(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGetConstraints';
    lFixture.TestGetConstraints;
  finally lFixture.Free; end;
end;

procedure RunTTestMigACTestSetConstraints(AContext: TNXTestContext);
var lFixture: TTestMigAC;
begin
  lFixture:=TTestMigAC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSetConstraints';
    lFixture.TestSetConstraints;
  finally lFixture.Free; end;
end;

procedure RegistertcmigacTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcmig_ac.TTestMigAC');
  lSuite.AddTest('TestCreate', @RunTTestMigACTestCreate);
  lSuite.AddTest('TestGetCount', @RunTTestMigACTestGetCount);
  lSuite.AddTest('TestCount', @RunTTestMigACTestCount);
  lSuite.AddTest('TestIndex', @RunTTestMigACTestIndex);
  lSuite.AddTest('TestNoGrid_Current', @RunTTestMigACTestNoGrid_Current);
  lSuite.AddTest('TestNoGrid_Specific', @RunTTestMigACTestNoGrid_Specific);
  lSuite.AddTest('TestFill_Current', @RunTTestMigACTestFill_Current);
  lSuite.AddTest('TestFill_Specific', @RunTTestMigACTestFill_Specific);
  lSuite.AddTest('TestSizeGroup_Empty', @RunTTestMigACTestSizeGroup_Empty);
  lSuite.AddTest('TestSizeGroup_Named', @RunTTestMigACTestSizeGroup_Named);
  lSuite.AddTest('TestSizeGroup_Specific', @RunTTestMigACTestSizeGroup_Specific);
  lSuite.AddTest('TestGap_Default', @RunTTestMigACTestGap_Default);
  lSuite.AddTest('TestGap_MoveToNext', @RunTTestMigACTestGap_MoveToNext);
  lSuite.AddTest('TestAlign_Current', @RunTTestMigACTestAlign_Current);
  lSuite.AddTest('TestAlign_Specific', @RunTTestMigACTestAlign_Specific);
  lSuite.AddTest('TestGrowPrio_Current', @RunTTestMigACTestGrowPrio_Current);
  lSuite.AddTest('TestGrowPrio_Specific', @RunTTestMigACTestGrowPrio_Specific);
  lSuite.AddTest('TestGrow_Default', @RunTTestMigACTestGrow_Default);
  lSuite.AddTest('TestGrow_Weight', @RunTTestMigACTestGrow_Weight);
  lSuite.AddTest('TestGrow_Specific', @RunTTestMigACTestGrow_Specific);
  lSuite.AddTest('TestShrinkPrio_Current', @RunTTestMigACTestShrinkPrio_Current);
  lSuite.AddTest('TestShrinkPrio_Specific', @RunTTestMigACTestShrinkPrio_Specific);
  lSuite.AddTest('TestShrink_Default', @RunTTestMigACTestShrink_Default);
  lSuite.AddTest('TestShrink_Weight', @RunTTestMigACTestShrink_Weight);
  lSuite.AddTest('TestShrink_Specific', @RunTTestMigACTestShrink_Specific);
  lSuite.AddTest('TestFluentChaining', @RunTTestMigACTestFluentChaining);
  lSuite.AddTest('TestGetConstraints', @RunTTestMigACTestGetConstraints);
  lSuite.AddTest('TestSetConstraints', @RunTTestMigACTestSetConstraints);
end;

end.

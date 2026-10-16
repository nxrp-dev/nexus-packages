unit tcmig_cc;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpg_mig_cc, fpg_mig_boundsize, fpg_mig_unitvalue, fpg_mig_dimconstraint;

type
  { Test cases for TfpgMigCC }
  TTestMigCC = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    { Basic creation and initialization }
    procedure TestCreate;
    procedure TestDefaultValues;

    { Dimension constraints - Width }
    procedure TestSizeGroupX;
    procedure TestEndGroupX;
    procedure TestMinWidth;
    procedure TestWidth;
    procedure TestMaxWidth;
    procedure TestGapX;
    procedure TestAlignX;
    procedure TestGrowPrioX;
    procedure TestGrowX_Default;
    procedure TestGrowX_Weight;
    procedure TestShrinkPrioX;
    procedure TestShrinkX;

    { Dimension constraints - Height }
    procedure TestSizeGroupY;
    procedure TestEndGroupY;
    procedure TestMinHeight;
    procedure TestHeight;
    procedure TestMaxHeight;
    procedure TestGapY;
    procedure TestAlignY;
    procedure TestGrowPrioY;
    procedure TestGrowY_Default;
    procedure TestGrowY_Weight;
    procedure TestShrinkPrioY;
    procedure TestShrinkY;

    { Dimension constraints - Both }
    procedure TestSizeGroup_Both;
    procedure TestEndGroup_Both;
    procedure TestGrow_Both;
    procedure TestGrow_BothDefault;
    procedure TestGrowPrio_Both;
    procedure TestShrink_Both;
    procedure TestShrink_BothDefault;
    procedure TestShrinkPrio_Both;

    { Gap methods }
    procedure TestGapBefore;
    procedure TestGapAfter;
    procedure TestGapTop;
    procedure TestGapBottom;
    procedure TestGapLeft;
    procedure TestGapRight;
    procedure TestGap_FourSides;

    { Cell and Spanning }
    procedure TestCell_TwoArgs;
    procedure TestCell_FourArgs;
    procedure TestSpan_TwoArgs;
    procedure TestSpan_NoArgs;
    procedure TestSpanX_WithArg;
    procedure TestSpanX_NoArg;
    procedure TestSpanY_WithArg;
    procedure TestSpanY_NoArg;

    { Flow and Wrapping }
    procedure TestFlowX;
    procedure TestFlowY;
    procedure TestSkip_WithArg;
    procedure TestSkip_NoArg;
    procedure TestSplit_WithArg;
    procedure TestSplit_NoArg;
    procedure TestWrap_NoArg;
    procedure TestNewline_NoArg;

    { Docking }
    procedure TestDockNorth;
    procedure TestDockWest;
    procedure TestDockSouth;
    procedure TestDockEast;

    { Positioning }
    procedure TestX;
    procedure TestY;
    procedure TestX2;
    procedure TestY2;

    { Miscellaneous }
    procedure TestHideMode;
    procedure TestId;
    procedure TestTag;
    procedure TestExternal_NoArg;
    procedure TestExternal_WithArg;
    procedure TestPush_NoArg;
    procedure TestPush_WithArgs;
    procedure TestPushX_NoArg;
    procedure TestPushX_WithArg;
    procedure TestPushY_NoArg;
    procedure TestPushY_WithArg;

    { Fluent API Chaining }
    procedure TestFluentChaining_Dimensions;
    procedure TestFluentChaining_Mixed;
  end;

procedure RegistertcmigccTests(ARegistry: TNXTestRegistry);

implementation

uses
  Math;

{ TTestMigCC }

procedure TTestMigCC.TestCreate;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    TestContext.AssertTrue((cc)<>nil, 'CC should be created');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestDefaultValues;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    TestContext.AssertTrue((-1)=(cc.Dock), 'Dock should be -1');
    TestContext.AssertTrue((0)=(cc.IsFlowX), 'FlowX should be 0 (nil)');
    TestContext.AssertTrue((0)=(cc.SkipCells), 'Skip should be 0');
    TestContext.AssertTrue((1)=(cc.SplitParts), 'Split should be 1');
    TestContext.AssertTrue((1)=(cc.CellSpanX), 'SpanX should be 1');
    TestContext.AssertTrue((1)=(cc.CellSpanY), 'SpanY should be 1');
    TestContext.AssertTrue((-1)=(cc.CellX), 'CellX should be -1');
    TestContext.AssertTrue((0)=(cc.CellY), 'CellY should be 0');
    TestContext.AssertTrue(('')=(cc.TagValue), 'Tag should be empty');
    TestContext.AssertTrue(('')=(cc.IdValue), 'Id should be empty');
    TestContext.AssertTrue((-1)=(cc.HideModeValue), 'HideMode should be -1');
    TestContext.AssertTrue(cc.IsBoundsInGrid, 'BoundsInGrid should be true');
    TestContext.AssertTrue(not (cc.IsExternal), 'External should be false');
    TestContext.AssertTrue(IsNaN(cc.PushWeightX), 'PushX should be NaN (null)');
    TestContext.AssertTrue(IsNaN(cc.PushWeightY), 'PushY should be NaN (null)');
    TestContext.AssertTrue((cc.Horizontal)<>nil, 'Horizontal should be initialized');
    TestContext.AssertTrue((cc.Vertical)<>nil, 'Vertical should be initialized');
  finally
    cc.Free;
  end;
end;

{ Dimension Constraints - Width }

procedure TTestMigCC.TestSizeGroupX;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.SizeGroupX('group1');
    TestContext.AssertTrue(('group1')=(cc.Horizontal.GetSizeGroup), 'SizeGroup should be set');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestEndGroupX;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.EndGroupX('group2');
    TestContext.AssertTrue(('group2')=(cc.Horizontal.GetEndGroup), 'EndGroup should be set');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestMinWidth;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.MinWidth('100px');
    TestContext.AssertTrue((cc.Horizontal.GetSize)<>nil, 'Size should be set');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestWidth;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    try
      cc.Width('100px');
      TestContext.Fail('Should raise exception - parser not implemented');
    except
      on E: Exception do
        ; // Expected
    end;
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestMaxWidth;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.MaxWidth('200px');
    TestContext.AssertTrue((cc.Horizontal.GetSize)<>nil, 'Size should be set');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestGapX;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    try
      cc.GapX('10px', '20px');
      TestContext.Fail('Should raise exception - parser not implemented');
    except
      on E: Exception do
        ; // Expected
    end;
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestAlignX;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.AlignX('center');
    TestContext.AssertTrue((cc.Horizontal.GetAlign)<>nil, 'AlignX should be set');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestGrowPrioX;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.GrowPrioX(50);
    TestContext.AssertTrue((50)=(cc.Horizontal.GetGrowPriority), 'GrowPriority should be 50');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestGrowX_Default;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.GrowX;
    TestContext.AssertTrue((100)=(cc.Horizontal.GetGrowPriority), 'GrowPriority should be 100');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestGrowX_Weight;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.GrowX(0.5);
    TestContext.AssertTrue(Abs((0.5)-(cc.Horizontal.GetGrowWeight))<=(0.001), 'Grow weight should be 0.5');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestShrinkPrioX;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.ShrinkPrioX(75);
    TestContext.AssertTrue((75)=(cc.Horizontal.GetShrinkPriority), 'ShrinkPriority should be 75');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestShrinkX;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.ShrinkX(0.3);
    TestContext.AssertTrue(Abs((0.3)-(cc.Horizontal.GetShrinkWeight))<=(0.001), 'Shrink weight should be 0.3');
  finally
    cc.Free;
  end;
end;

{ Dimension Constraints - Height }

procedure TTestMigCC.TestSizeGroupY;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.SizeGroupY('group3');
    TestContext.AssertTrue(('group3')=(cc.Vertical.GetSizeGroup), 'SizeGroup should be set');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestEndGroupY;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.EndGroupY('group4');
    TestContext.AssertTrue(('group4')=(cc.Vertical.GetEndGroup), 'EndGroup should be set');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestMinHeight;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.MinHeight('50px');
    TestContext.AssertTrue((cc.Vertical.GetSize)<>nil, 'Size should be set');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestHeight;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    try
      cc.Height('100px');
      TestContext.Fail('Should raise exception - parser not implemented');
    except
      on E: Exception do
        ; // Expected
    end;
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestMaxHeight;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.MaxHeight('150px');
    TestContext.AssertTrue((cc.Vertical.GetSize)<>nil, 'Size should be set');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestGapY;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    try
      cc.GapY('5px', '10px');
      TestContext.Fail('Should raise exception - parser not implemented');
    except
      on E: Exception do
        ; // Expected
    end;
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestAlignY;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.AlignY('top');
    TestContext.AssertTrue((cc.Vertical.GetAlign)<>nil, 'AlignY should be set');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestGrowPrioY;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.GrowPrioY(60);
    TestContext.AssertTrue((60)=(cc.Vertical.GetGrowPriority), 'GrowPriority should be 60');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestGrowY_Default;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.GrowY;
    TestContext.AssertTrue((100)=(cc.Vertical.GetGrowPriority), 'GrowPriority should be 100');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestGrowY_Weight;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.GrowY(0.7);
    TestContext.AssertTrue(Abs((0.7)-(cc.Vertical.GetGrowWeight))<=(0.001), 'Grow weight should be 0.7');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestShrinkPrioY;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.ShrinkPrioY(80);
    TestContext.AssertTrue((80)=(cc.Vertical.GetShrinkPriority), 'ShrinkPriority should be 80');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestShrinkY;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.ShrinkY(0.4);
    TestContext.AssertTrue(Abs((0.4)-(cc.Vertical.GetShrinkWeight))<=(0.001), 'Shrink weight should be 0.4');
  finally
    cc.Free;
  end;
end;

{ Dimension Constraints - Both }

procedure TTestMigCC.TestSizeGroup_Both;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.SizeGroup('groupX', 'groupY');
    TestContext.AssertTrue(('groupX')=(cc.Horizontal.GetSizeGroup), 'SizeGroupX should be set');
    TestContext.AssertTrue(('groupY')=(cc.Vertical.GetSizeGroup), 'SizeGroupY should be set');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestEndGroup_Both;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.EndGroup('endX', 'endY');
    TestContext.AssertTrue(('endX')=(cc.Horizontal.GetEndGroup), 'EndGroupX should be set');
    TestContext.AssertTrue(('endY')=(cc.Vertical.GetEndGroup), 'EndGroupY should be set');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestGrow_Both;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Grow(0.6, 0.8);
    TestContext.AssertTrue(Abs((0.6)-(cc.Horizontal.GetGrowWeight))<=(0.001), 'Horizontal grow weight should be 0.6');
    TestContext.AssertTrue(Abs((0.8)-(cc.Vertical.GetGrowWeight))<=(0.001), 'Vertical grow weight should be 0.8');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestGrow_BothDefault;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Grow;
    TestContext.AssertTrue((100)=(cc.Horizontal.GetGrowPriority), 'Horizontal grow priority should be 100');
    TestContext.AssertTrue((100)=(cc.Vertical.GetGrowPriority), 'Vertical grow priority should be 100');
    { .Grow must also set default grow weights, matching the behaviour of .GrowX and .GrowY }
    TestContext.AssertTrue(Abs((100.0)-(cc.Horizontal.GetGrowWeight))<=(0.001), 'Horizontal grow weight should be 100.0');
    TestContext.AssertTrue(Abs((100.0)-(cc.Vertical.GetGrowWeight))<=(0.001), 'Vertical grow weight should be 100.0');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestGrowPrio_Both;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.GrowPrio(40, 60);
    TestContext.AssertTrue((40)=(cc.Horizontal.GetGrowPriority), 'Horizontal grow priority should be 40');
    TestContext.AssertTrue((60)=(cc.Vertical.GetGrowPriority), 'Vertical grow priority should be 60');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestShrink_Both;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Shrink(0.2, 0.3);
    TestContext.AssertTrue(Abs((0.2)-(cc.Horizontal.GetShrinkWeight))<=(0.001), 'Horizontal shrink weight should be 0.2');
    TestContext.AssertTrue(Abs((0.3)-(cc.Vertical.GetShrinkWeight))<=(0.001), 'Vertical shrink weight should be 0.3');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestShrink_BothDefault;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Shrink;
    TestContext.AssertTrue((100)=(cc.Horizontal.GetShrinkPriority), 'Horizontal shrink priority should be 100');
    TestContext.AssertTrue((100)=(cc.Vertical.GetShrinkPriority), 'Vertical shrink priority should be 100');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestShrinkPrio_Both;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.ShrinkPrio(30, 50);
    TestContext.AssertTrue((30)=(cc.Horizontal.GetShrinkPriority), 'Horizontal shrink priority should be 30');
    TestContext.AssertTrue((50)=(cc.Vertical.GetShrinkPriority), 'Vertical shrink priority should be 50');
  finally
    cc.Free;
  end;
end;

{ Gap Methods }

procedure TTestMigCC.TestGapBefore;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    try
      cc.GapBefore('10px');
      TestContext.Fail('Should raise exception - parser not implemented');
    except
      on E: Exception do
        ; // Expected
    end;
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestGapAfter;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    try
      cc.GapAfter('15px');
      TestContext.Fail('Should raise exception - parser not implemented');
    except
      on E: Exception do
        ; // Expected
    end;
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestGapTop;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    try
      cc.GapTop('5px');
      TestContext.Fail('Should raise exception - parser not implemented');
    except
      on E: Exception do
        ; // Expected
    end;
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestGapBottom;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    try
      cc.GapBottom('8px');
      TestContext.Fail('Should raise exception - parser not implemented');
    except
      on E: Exception do
        ; // Expected
    end;
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestGapLeft;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    try
      cc.GapLeft('12px');
      TestContext.Fail('Should raise exception - parser not implemented');
    except
      on E: Exception do
        ; // Expected
    end;
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestGapRight;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    try
      cc.GapRight('18px');
      TestContext.Fail('Should raise exception - parser not implemented');
    except
      on E: Exception do
        ; // Expected
    end;
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestGap_FourSides;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    try
      cc.Gap('10px', '15px', '5px', '8px');
      TestContext.Fail('Should raise exception - parser not implemented');
    except
      on E: Exception do
        ; // Expected
    end;
  finally
    cc.Free;
  end;
end;

{ Cell and Spanning }

procedure TTestMigCC.TestCell_TwoArgs;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Cell(2, 3);
    TestContext.AssertTrue((2)=(cc.CellX), 'CellX should be 2');
    TestContext.AssertTrue((3)=(cc.CellY), 'CellY should be 3');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestCell_FourArgs;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Cell(1, 2, 3, 4);
    TestContext.AssertTrue((1)=(cc.CellX), 'CellX should be 1');
    TestContext.AssertTrue((2)=(cc.CellY), 'CellY should be 2');
    TestContext.AssertTrue((3)=(cc.CellSpanX), 'SpanX should be 3');
    TestContext.AssertTrue((4)=(cc.CellSpanY), 'SpanY should be 4');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestSpan_TwoArgs;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Span(2, 3);
    TestContext.AssertTrue((2)=(cc.CellSpanX), 'SpanX should be 2');
    TestContext.AssertTrue((3)=(cc.CellSpanY), 'SpanY should be 3');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestSpan_NoArgs;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Span;
    TestContext.AssertTrue((2147471302)=(cc.CellSpanX), 'SpanX should be INF_SIZE');
    TestContext.AssertTrue((1)=(cc.CellSpanY), 'SpanY should be 1');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestSpanX_WithArg;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.SpanX(5);
    TestContext.AssertTrue((5)=(cc.CellSpanX), 'SpanX should be 5');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestSpanX_NoArg;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.SpanX;
    TestContext.AssertTrue((2147471302)=(cc.CellSpanX), 'SpanX should be INF_SIZE');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestSpanY_WithArg;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.SpanY(4);
    TestContext.AssertTrue((4)=(cc.CellSpanY), 'SpanY should be 4');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestSpanY_NoArg;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.SpanY;
    TestContext.AssertTrue((2147471302)=(cc.CellSpanY), 'SpanY should be INF_SIZE');
  finally
    cc.Free;
  end;
end;

{ Flow and Wrapping }

procedure TTestMigCC.TestFlowX;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.FlowX;
    TestContext.AssertTrue((2)=(cc.IsFlowX), 'FlowX should be 2 (true)');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestFlowY;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.FlowY;
    TestContext.AssertTrue((1)=(cc.IsFlowX), 'FlowX should be 1 (false)');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestSkip_WithArg;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Skip(3);
    TestContext.AssertTrue((3)=(cc.SkipCells), 'Skip should be 3');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestSkip_NoArg;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Skip;
    TestContext.AssertTrue((1)=(cc.SkipCells), 'Skip should be 1');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestSplit_WithArg;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Split(4);
    TestContext.AssertTrue((4)=(cc.SplitParts), 'Split should be 4');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestSplit_NoArg;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Split;
    TestContext.AssertTrue((2147471302)=(cc.SplitParts), 'Split should be INF_SIZE');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestWrap_NoArg;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Wrap;
    TestContext.AssertTrue((cc.WrapGap)<>nil, 'Wrap should be set');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestNewline_NoArg;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Newline;
    TestContext.AssertTrue((cc.NewlineGap)<>nil, 'Newline should be set');
  finally
    cc.Free;
  end;
end;

{ Docking }

procedure TTestMigCC.TestDockNorth;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.DockNorth;
    TestContext.AssertTrue((0)=(cc.Dock), 'Dock should be 0 (north)');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestDockWest;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.DockWest;
    TestContext.AssertTrue((1)=(cc.Dock), 'Dock should be 1 (west)');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestDockSouth;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.DockSouth;
    TestContext.AssertTrue((2)=(cc.Dock), 'Dock should be 2 (south)');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestDockEast;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.DockEast;
    TestContext.AssertTrue((3)=(cc.Dock), 'Dock should be 3 (east)');
  finally
    cc.Free;
  end;
end;

{ Positioning }

procedure TTestMigCC.TestX;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.X('100px');
    // Position array is not accessible via properties, just test no exception
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestY;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Y('50px');
    // Position array is not accessible via properties, just test no exception
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestX2;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.X2('200px');
    // Position array is not accessible via properties, just test no exception
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestY2;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Y2('150px');
    // Position array is not accessible via properties, just test no exception
  finally
    cc.Free;
  end;
end;

{ Miscellaneous }

procedure TTestMigCC.TestHideMode;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.HideMode(2);
    TestContext.AssertTrue((2)=(cc.HideModeValue), 'HideMode should be 2');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestId;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Id('button1');
    TestContext.AssertTrue(('button1')=(cc.IdValue), 'Id should be "button1"');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestTag;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Tag('group1');
    TestContext.AssertTrue(('group1')=(cc.TagValue), 'Tag should be "group1"');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestExternal_NoArg;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.External;
    TestContext.AssertTrue(cc.IsExternal, 'External should be true');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestExternal_WithArg;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.External(False);
    TestContext.AssertTrue(not (cc.IsExternal), 'External should be false');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestPush_NoArg;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Push;
    TestContext.AssertTrue(Abs((100.0)-(cc.PushWeightX))<=(0.001), 'PushX should be 100.0');
    TestContext.AssertTrue(Abs((100.0)-(cc.PushWeightY))<=(0.001), 'PushY should be 100.0');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestPush_WithArgs;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Push(50.0, 75.0);
    TestContext.AssertTrue(Abs((50.0)-(cc.PushWeightX))<=(0.001), 'PushX should be 50.0');
    TestContext.AssertTrue(Abs((75.0)-(cc.PushWeightY))<=(0.001), 'PushY should be 75.0');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestPushX_NoArg;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.PushX;
    TestContext.AssertTrue(Abs((100.0)-(cc.PushWeightX))<=(0.001), 'PushX should be 100.0');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestPushX_WithArg;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.PushX(60.0);
    TestContext.AssertTrue(Abs((60.0)-(cc.PushWeightX))<=(0.001), 'PushX should be 60.0');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestPushY_NoArg;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.PushY;
    TestContext.AssertTrue(Abs((100.0)-(cc.PushWeightY))<=(0.001), 'PushY should be 100.0');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestPushY_WithArg;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.PushY(80.0);
    TestContext.AssertTrue(Abs((80.0)-(cc.PushWeightY))<=(0.001), 'PushY should be 80.0');
  finally
    cc.Free;
  end;
end;

{ Fluent API Chaining }

procedure TTestMigCC.TestFluentChaining_Dimensions;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.GrowX(0.5).GrowY(0.7).ShrinkX(0.3).ShrinkY(0.4);

    TestContext.AssertTrue(Abs((0.5)-(cc.Horizontal.GetGrowWeight))<=(0.001), 'Horizontal grow weight should be 0.5');
    TestContext.AssertTrue(Abs((0.7)-(cc.Vertical.GetGrowWeight))<=(0.001), 'Vertical grow weight should be 0.7');
    TestContext.AssertTrue(Abs((0.3)-(cc.Horizontal.GetShrinkWeight))<=(0.001), 'Horizontal shrink weight should be 0.3');
    TestContext.AssertTrue(Abs((0.4)-(cc.Vertical.GetShrinkWeight))<=(0.001), 'Vertical shrink weight should be 0.4');
  finally
    cc.Free;
  end;
end;

procedure TTestMigCC.TestFluentChaining_Mixed;
var
  cc: TfpgMigCC;
begin
  cc := TfpgMigCC.Create;
  try
    cc.Cell(2, 3).Span(2, 1).Grow.Push(50.0, 75.0).Tag('test').Id('widget1');

    TestContext.AssertTrue((2)=(cc.CellX), 'CellX should be 2');
    TestContext.AssertTrue((3)=(cc.CellY), 'CellY should be 3');
    TestContext.AssertTrue((2)=(cc.CellSpanX), 'SpanX should be 2');
    TestContext.AssertTrue((1)=(cc.CellSpanY), 'SpanY should be 1');
    TestContext.AssertTrue((100)=(cc.Horizontal.GetGrowPriority), 'Horizontal grow priority should be 100');
    TestContext.AssertTrue((100)=(cc.Vertical.GetGrowPriority), 'Vertical grow priority should be 100');
    TestContext.AssertTrue(Abs((50.0)-(cc.PushWeightX))<=(0.001), 'PushX should be 50.0');
    TestContext.AssertTrue(Abs((75.0)-(cc.PushWeightY))<=(0.001), 'PushY should be 75.0');
    TestContext.AssertTrue(('test')=(cc.TagValue), 'Tag should be "test"');
    TestContext.AssertTrue(('widget1')=(cc.IdValue), 'Id should be "widget1"');
  finally
    cc.Free;
  end;
end;


constructor TTestMigCC.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestMigCCTestCreate(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestCreate');
  try
    lFixture.TestCreate;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestDefaultValues(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestDefaultValues');
  try
    lFixture.TestDefaultValues;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSizeGroupX(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestSizeGroupX');
  try
    lFixture.TestSizeGroupX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestEndGroupX(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestEndGroupX');
  try
    lFixture.TestEndGroupX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestMinWidth(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestMinWidth');
  try
    lFixture.TestMinWidth;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestWidth(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestWidth');
  try
    lFixture.TestWidth;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestMaxWidth(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestMaxWidth');
  try
    lFixture.TestMaxWidth;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGapX(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestGapX');
  try
    lFixture.TestGapX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestAlignX(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestAlignX');
  try
    lFixture.TestAlignX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGrowPrioX(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestGrowPrioX');
  try
    lFixture.TestGrowPrioX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGrowX_Default(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestGrowX_Default');
  try
    lFixture.TestGrowX_Default;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGrowX_Weight(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestGrowX_Weight');
  try
    lFixture.TestGrowX_Weight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestShrinkPrioX(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestShrinkPrioX');
  try
    lFixture.TestShrinkPrioX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestShrinkX(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestShrinkX');
  try
    lFixture.TestShrinkX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSizeGroupY(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestSizeGroupY');
  try
    lFixture.TestSizeGroupY;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestEndGroupY(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestEndGroupY');
  try
    lFixture.TestEndGroupY;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestMinHeight(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestMinHeight');
  try
    lFixture.TestMinHeight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestHeight(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestHeight');
  try
    lFixture.TestHeight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestMaxHeight(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestMaxHeight');
  try
    lFixture.TestMaxHeight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGapY(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestGapY');
  try
    lFixture.TestGapY;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestAlignY(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestAlignY');
  try
    lFixture.TestAlignY;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGrowPrioY(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestGrowPrioY');
  try
    lFixture.TestGrowPrioY;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGrowY_Default(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestGrowY_Default');
  try
    lFixture.TestGrowY_Default;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGrowY_Weight(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestGrowY_Weight');
  try
    lFixture.TestGrowY_Weight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestShrinkPrioY(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestShrinkPrioY');
  try
    lFixture.TestShrinkPrioY;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestShrinkY(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestShrinkY');
  try
    lFixture.TestShrinkY;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSizeGroup_Both(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestSizeGroup_Both');
  try
    lFixture.TestSizeGroup_Both;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestEndGroup_Both(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestEndGroup_Both');
  try
    lFixture.TestEndGroup_Both;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGrow_Both(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestGrow_Both');
  try
    lFixture.TestGrow_Both;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGrow_BothDefault(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestGrow_BothDefault');
  try
    lFixture.TestGrow_BothDefault;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGrowPrio_Both(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestGrowPrio_Both');
  try
    lFixture.TestGrowPrio_Both;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestShrink_Both(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestShrink_Both');
  try
    lFixture.TestShrink_Both;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestShrink_BothDefault(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestShrink_BothDefault');
  try
    lFixture.TestShrink_BothDefault;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestShrinkPrio_Both(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestShrinkPrio_Both');
  try
    lFixture.TestShrinkPrio_Both;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGapBefore(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestGapBefore');
  try
    lFixture.TestGapBefore;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGapAfter(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestGapAfter');
  try
    lFixture.TestGapAfter;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGapTop(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestGapTop');
  try
    lFixture.TestGapTop;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGapBottom(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestGapBottom');
  try
    lFixture.TestGapBottom;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGapLeft(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestGapLeft');
  try
    lFixture.TestGapLeft;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGapRight(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestGapRight');
  try
    lFixture.TestGapRight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGap_FourSides(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestGap_FourSides');
  try
    lFixture.TestGap_FourSides;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestCell_TwoArgs(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestCell_TwoArgs');
  try
    lFixture.TestCell_TwoArgs;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestCell_FourArgs(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestCell_FourArgs');
  try
    lFixture.TestCell_FourArgs;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSpan_TwoArgs(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestSpan_TwoArgs');
  try
    lFixture.TestSpan_TwoArgs;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSpan_NoArgs(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestSpan_NoArgs');
  try
    lFixture.TestSpan_NoArgs;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSpanX_WithArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestSpanX_WithArg');
  try
    lFixture.TestSpanX_WithArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSpanX_NoArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestSpanX_NoArg');
  try
    lFixture.TestSpanX_NoArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSpanY_WithArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestSpanY_WithArg');
  try
    lFixture.TestSpanY_WithArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSpanY_NoArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestSpanY_NoArg');
  try
    lFixture.TestSpanY_NoArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestFlowX(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestFlowX');
  try
    lFixture.TestFlowX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestFlowY(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestFlowY');
  try
    lFixture.TestFlowY;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSkip_WithArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestSkip_WithArg');
  try
    lFixture.TestSkip_WithArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSkip_NoArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestSkip_NoArg');
  try
    lFixture.TestSkip_NoArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSplit_WithArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestSplit_WithArg');
  try
    lFixture.TestSplit_WithArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSplit_NoArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestSplit_NoArg');
  try
    lFixture.TestSplit_NoArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestWrap_NoArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestWrap_NoArg');
  try
    lFixture.TestWrap_NoArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestNewline_NoArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestNewline_NoArg');
  try
    lFixture.TestNewline_NoArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestDockNorth(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestDockNorth');
  try
    lFixture.TestDockNorth;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestDockWest(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestDockWest');
  try
    lFixture.TestDockWest;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestDockSouth(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestDockSouth');
  try
    lFixture.TestDockSouth;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestDockEast(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestDockEast');
  try
    lFixture.TestDockEast;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestX(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestX');
  try
    lFixture.TestX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestY(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestY');
  try
    lFixture.TestY;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestX2(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestX2');
  try
    lFixture.TestX2;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestY2(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestY2');
  try
    lFixture.TestY2;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestHideMode(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestHideMode');
  try
    lFixture.TestHideMode;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestId(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestId');
  try
    lFixture.TestId;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestTag(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestTag');
  try
    lFixture.TestTag;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestExternal_NoArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestExternal_NoArg');
  try
    lFixture.TestExternal_NoArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestExternal_WithArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestExternal_WithArg');
  try
    lFixture.TestExternal_WithArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestPush_NoArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestPush_NoArg');
  try
    lFixture.TestPush_NoArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestPush_WithArgs(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestPush_WithArgs');
  try
    lFixture.TestPush_WithArgs;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestPushX_NoArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestPushX_NoArg');
  try
    lFixture.TestPushX_NoArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestPushX_WithArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestPushX_WithArg');
  try
    lFixture.TestPushX_WithArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestPushY_NoArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestPushY_NoArg');
  try
    lFixture.TestPushY_NoArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestPushY_WithArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestPushY_WithArg');
  try
    lFixture.TestPushY_WithArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestFluentChaining_Dimensions(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestFluentChaining_Dimensions');
  try
    lFixture.TestFluentChaining_Dimensions;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestFluentChaining_Mixed(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create(AContext, 'TestFluentChaining_Mixed');
  try
    lFixture.TestFluentChaining_Mixed;
  finally lFixture.Free; end;
end;

procedure RegistertcmigccTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcmig_cc.TTestMigCC');
  lSuite.AddTest('TestCreate', @RunTTestMigCCTestCreate);
  lSuite.AddTest('TestDefaultValues', @RunTTestMigCCTestDefaultValues);
  lSuite.AddTest('TestSizeGroupX', @RunTTestMigCCTestSizeGroupX);
  lSuite.AddTest('TestEndGroupX', @RunTTestMigCCTestEndGroupX);
  lSuite.AddTest('TestMinWidth', @RunTTestMigCCTestMinWidth);
  lSuite.AddTest('TestWidth', @RunTTestMigCCTestWidth);
  lSuite.AddTest('TestMaxWidth', @RunTTestMigCCTestMaxWidth);
  lSuite.AddTest('TestGapX', @RunTTestMigCCTestGapX);
  lSuite.AddTest('TestAlignX', @RunTTestMigCCTestAlignX);
  lSuite.AddTest('TestGrowPrioX', @RunTTestMigCCTestGrowPrioX);
  lSuite.AddTest('TestGrowX_Default', @RunTTestMigCCTestGrowX_Default);
  lSuite.AddTest('TestGrowX_Weight', @RunTTestMigCCTestGrowX_Weight);
  lSuite.AddTest('TestShrinkPrioX', @RunTTestMigCCTestShrinkPrioX);
  lSuite.AddTest('TestShrinkX', @RunTTestMigCCTestShrinkX);
  lSuite.AddTest('TestSizeGroupY', @RunTTestMigCCTestSizeGroupY);
  lSuite.AddTest('TestEndGroupY', @RunTTestMigCCTestEndGroupY);
  lSuite.AddTest('TestMinHeight', @RunTTestMigCCTestMinHeight);
  lSuite.AddTest('TestHeight', @RunTTestMigCCTestHeight);
  lSuite.AddTest('TestMaxHeight', @RunTTestMigCCTestMaxHeight);
  lSuite.AddTest('TestGapY', @RunTTestMigCCTestGapY);
  lSuite.AddTest('TestAlignY', @RunTTestMigCCTestAlignY);
  lSuite.AddTest('TestGrowPrioY', @RunTTestMigCCTestGrowPrioY);
  lSuite.AddTest('TestGrowY_Default', @RunTTestMigCCTestGrowY_Default);
  lSuite.AddTest('TestGrowY_Weight', @RunTTestMigCCTestGrowY_Weight);
  lSuite.AddTest('TestShrinkPrioY', @RunTTestMigCCTestShrinkPrioY);
  lSuite.AddTest('TestShrinkY', @RunTTestMigCCTestShrinkY);
  lSuite.AddTest('TestSizeGroup_Both', @RunTTestMigCCTestSizeGroup_Both);
  lSuite.AddTest('TestEndGroup_Both', @RunTTestMigCCTestEndGroup_Both);
  lSuite.AddTest('TestGrow_Both', @RunTTestMigCCTestGrow_Both);
  lSuite.AddTest('TestGrow_BothDefault', @RunTTestMigCCTestGrow_BothDefault);
  lSuite.AddTest('TestGrowPrio_Both', @RunTTestMigCCTestGrowPrio_Both);
  lSuite.AddTest('TestShrink_Both', @RunTTestMigCCTestShrink_Both);
  lSuite.AddTest('TestShrink_BothDefault', @RunTTestMigCCTestShrink_BothDefault);
  lSuite.AddTest('TestShrinkPrio_Both', @RunTTestMigCCTestShrinkPrio_Both);
  lSuite.AddTest('TestGapBefore', @RunTTestMigCCTestGapBefore);
  lSuite.AddTest('TestGapAfter', @RunTTestMigCCTestGapAfter);
  lSuite.AddTest('TestGapTop', @RunTTestMigCCTestGapTop);
  lSuite.AddTest('TestGapBottom', @RunTTestMigCCTestGapBottom);
  lSuite.AddTest('TestGapLeft', @RunTTestMigCCTestGapLeft);
  lSuite.AddTest('TestGapRight', @RunTTestMigCCTestGapRight);
  lSuite.AddTest('TestGap_FourSides', @RunTTestMigCCTestGap_FourSides);
  lSuite.AddTest('TestCell_TwoArgs', @RunTTestMigCCTestCell_TwoArgs);
  lSuite.AddTest('TestCell_FourArgs', @RunTTestMigCCTestCell_FourArgs);
  lSuite.AddTest('TestSpan_TwoArgs', @RunTTestMigCCTestSpan_TwoArgs);
  lSuite.AddTest('TestSpan_NoArgs', @RunTTestMigCCTestSpan_NoArgs);
  lSuite.AddTest('TestSpanX_WithArg', @RunTTestMigCCTestSpanX_WithArg);
  lSuite.AddTest('TestSpanX_NoArg', @RunTTestMigCCTestSpanX_NoArg);
  lSuite.AddTest('TestSpanY_WithArg', @RunTTestMigCCTestSpanY_WithArg);
  lSuite.AddTest('TestSpanY_NoArg', @RunTTestMigCCTestSpanY_NoArg);
  lSuite.AddTest('TestFlowX', @RunTTestMigCCTestFlowX);
  lSuite.AddTest('TestFlowY', @RunTTestMigCCTestFlowY);
  lSuite.AddTest('TestSkip_WithArg', @RunTTestMigCCTestSkip_WithArg);
  lSuite.AddTest('TestSkip_NoArg', @RunTTestMigCCTestSkip_NoArg);
  lSuite.AddTest('TestSplit_WithArg', @RunTTestMigCCTestSplit_WithArg);
  lSuite.AddTest('TestSplit_NoArg', @RunTTestMigCCTestSplit_NoArg);
  lSuite.AddTest('TestWrap_NoArg', @RunTTestMigCCTestWrap_NoArg);
  lSuite.AddTest('TestNewline_NoArg', @RunTTestMigCCTestNewline_NoArg);
  lSuite.AddTest('TestDockNorth', @RunTTestMigCCTestDockNorth);
  lSuite.AddTest('TestDockWest', @RunTTestMigCCTestDockWest);
  lSuite.AddTest('TestDockSouth', @RunTTestMigCCTestDockSouth);
  lSuite.AddTest('TestDockEast', @RunTTestMigCCTestDockEast);
  lSuite.AddTest('TestX', @RunTTestMigCCTestX);
  lSuite.AddTest('TestY', @RunTTestMigCCTestY);
  lSuite.AddTest('TestX2', @RunTTestMigCCTestX2);
  lSuite.AddTest('TestY2', @RunTTestMigCCTestY2);
  lSuite.AddTest('TestHideMode', @RunTTestMigCCTestHideMode);
  lSuite.AddTest('TestId', @RunTTestMigCCTestId);
  lSuite.AddTest('TestTag', @RunTTestMigCCTestTag);
  lSuite.AddTest('TestExternal_NoArg', @RunTTestMigCCTestExternal_NoArg);
  lSuite.AddTest('TestExternal_WithArg', @RunTTestMigCCTestExternal_WithArg);
  lSuite.AddTest('TestPush_NoArg', @RunTTestMigCCTestPush_NoArg);
  lSuite.AddTest('TestPush_WithArgs', @RunTTestMigCCTestPush_WithArgs);
  lSuite.AddTest('TestPushX_NoArg', @RunTTestMigCCTestPushX_NoArg);
  lSuite.AddTest('TestPushX_WithArg', @RunTTestMigCCTestPushX_WithArg);
  lSuite.AddTest('TestPushY_NoArg', @RunTTestMigCCTestPushY_NoArg);
  lSuite.AddTest('TestPushY_WithArg', @RunTTestMigCCTestPushY_WithArg);
  lSuite.AddTest('TestFluentChaining_Dimensions', @RunTTestMigCCTestFluentChaining_Dimensions);
  lSuite.AddTest('TestFluentChaining_Mixed', @RunTTestMigCCTestFluentChaining_Mixed);
end;

end.

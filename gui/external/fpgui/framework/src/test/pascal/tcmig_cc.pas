unit tcmig_cc;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpg_mig_cc, fpg_mig_boundsize, fpg_mig_unitvalue, fpg_mig_dimconstraint;

type
  { Test cases for TfpgMigCC }
  TTestMigCC = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
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
    FContext.AssertTrue((cc)<>nil, 'CC should be created');
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
    FContext.AssertTrue((-1)=(cc.Dock), 'Dock should be -1');
    FContext.AssertTrue((0)=(cc.IsFlowX), 'FlowX should be 0 (nil)');
    FContext.AssertTrue((0)=(cc.SkipCells), 'Skip should be 0');
    FContext.AssertTrue((1)=(cc.SplitParts), 'Split should be 1');
    FContext.AssertTrue((1)=(cc.CellSpanX), 'SpanX should be 1');
    FContext.AssertTrue((1)=(cc.CellSpanY), 'SpanY should be 1');
    FContext.AssertTrue((-1)=(cc.CellX), 'CellX should be -1');
    FContext.AssertTrue((0)=(cc.CellY), 'CellY should be 0');
    FContext.AssertTrue(('')=(cc.TagValue), 'Tag should be empty');
    FContext.AssertTrue(('')=(cc.IdValue), 'Id should be empty');
    FContext.AssertTrue((-1)=(cc.HideModeValue), 'HideMode should be -1');
    FContext.AssertTrue(cc.IsBoundsInGrid, 'BoundsInGrid should be true');
    FContext.AssertTrue(not (cc.IsExternal), 'External should be false');
    FContext.AssertTrue(IsNaN(cc.PushWeightX), 'PushX should be NaN (null)');
    FContext.AssertTrue(IsNaN(cc.PushWeightY), 'PushY should be NaN (null)');
    FContext.AssertTrue((cc.Horizontal)<>nil, 'Horizontal should be initialized');
    FContext.AssertTrue((cc.Vertical)<>nil, 'Vertical should be initialized');
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
    FContext.AssertTrue(('group1')=(cc.Horizontal.GetSizeGroup), 'SizeGroup should be set');
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
    FContext.AssertTrue(('group2')=(cc.Horizontal.GetEndGroup), 'EndGroup should be set');
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
    FContext.AssertTrue((cc.Horizontal.GetSize)<>nil, 'Size should be set');
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
      FContext.Fail('Should raise exception - parser not implemented');
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
    FContext.AssertTrue((cc.Horizontal.GetSize)<>nil, 'Size should be set');
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
      FContext.Fail('Should raise exception - parser not implemented');
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
    FContext.AssertTrue((cc.Horizontal.GetAlign)<>nil, 'AlignX should be set');
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
    FContext.AssertTrue((50)=(cc.Horizontal.GetGrowPriority), 'GrowPriority should be 50');
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
    FContext.AssertTrue((100)=(cc.Horizontal.GetGrowPriority), 'GrowPriority should be 100');
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
    FContext.AssertTrue(Abs((0.5)-(cc.Horizontal.GetGrowWeight))<=(0.001), 'Grow weight should be 0.5');
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
    FContext.AssertTrue((75)=(cc.Horizontal.GetShrinkPriority), 'ShrinkPriority should be 75');
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
    FContext.AssertTrue(Abs((0.3)-(cc.Horizontal.GetShrinkWeight))<=(0.001), 'Shrink weight should be 0.3');
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
    FContext.AssertTrue(('group3')=(cc.Vertical.GetSizeGroup), 'SizeGroup should be set');
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
    FContext.AssertTrue(('group4')=(cc.Vertical.GetEndGroup), 'EndGroup should be set');
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
    FContext.AssertTrue((cc.Vertical.GetSize)<>nil, 'Size should be set');
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
      FContext.Fail('Should raise exception - parser not implemented');
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
    FContext.AssertTrue((cc.Vertical.GetSize)<>nil, 'Size should be set');
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
      FContext.Fail('Should raise exception - parser not implemented');
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
    FContext.AssertTrue((cc.Vertical.GetAlign)<>nil, 'AlignY should be set');
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
    FContext.AssertTrue((60)=(cc.Vertical.GetGrowPriority), 'GrowPriority should be 60');
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
    FContext.AssertTrue((100)=(cc.Vertical.GetGrowPriority), 'GrowPriority should be 100');
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
    FContext.AssertTrue(Abs((0.7)-(cc.Vertical.GetGrowWeight))<=(0.001), 'Grow weight should be 0.7');
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
    FContext.AssertTrue((80)=(cc.Vertical.GetShrinkPriority), 'ShrinkPriority should be 80');
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
    FContext.AssertTrue(Abs((0.4)-(cc.Vertical.GetShrinkWeight))<=(0.001), 'Shrink weight should be 0.4');
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
    FContext.AssertTrue(('groupX')=(cc.Horizontal.GetSizeGroup), 'SizeGroupX should be set');
    FContext.AssertTrue(('groupY')=(cc.Vertical.GetSizeGroup), 'SizeGroupY should be set');
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
    FContext.AssertTrue(('endX')=(cc.Horizontal.GetEndGroup), 'EndGroupX should be set');
    FContext.AssertTrue(('endY')=(cc.Vertical.GetEndGroup), 'EndGroupY should be set');
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
    FContext.AssertTrue(Abs((0.6)-(cc.Horizontal.GetGrowWeight))<=(0.001), 'Horizontal grow weight should be 0.6');
    FContext.AssertTrue(Abs((0.8)-(cc.Vertical.GetGrowWeight))<=(0.001), 'Vertical grow weight should be 0.8');
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
    FContext.AssertTrue((100)=(cc.Horizontal.GetGrowPriority), 'Horizontal grow priority should be 100');
    FContext.AssertTrue((100)=(cc.Vertical.GetGrowPriority), 'Vertical grow priority should be 100');
    { .Grow must also set default grow weights, matching the behaviour of .GrowX and .GrowY }
    FContext.AssertTrue(Abs((100.0)-(cc.Horizontal.GetGrowWeight))<=(0.001), 'Horizontal grow weight should be 100.0');
    FContext.AssertTrue(Abs((100.0)-(cc.Vertical.GetGrowWeight))<=(0.001), 'Vertical grow weight should be 100.0');
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
    FContext.AssertTrue((40)=(cc.Horizontal.GetGrowPriority), 'Horizontal grow priority should be 40');
    FContext.AssertTrue((60)=(cc.Vertical.GetGrowPriority), 'Vertical grow priority should be 60');
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
    FContext.AssertTrue(Abs((0.2)-(cc.Horizontal.GetShrinkWeight))<=(0.001), 'Horizontal shrink weight should be 0.2');
    FContext.AssertTrue(Abs((0.3)-(cc.Vertical.GetShrinkWeight))<=(0.001), 'Vertical shrink weight should be 0.3');
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
    FContext.AssertTrue((100)=(cc.Horizontal.GetShrinkPriority), 'Horizontal shrink priority should be 100');
    FContext.AssertTrue((100)=(cc.Vertical.GetShrinkPriority), 'Vertical shrink priority should be 100');
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
    FContext.AssertTrue((30)=(cc.Horizontal.GetShrinkPriority), 'Horizontal shrink priority should be 30');
    FContext.AssertTrue((50)=(cc.Vertical.GetShrinkPriority), 'Vertical shrink priority should be 50');
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
      FContext.Fail('Should raise exception - parser not implemented');
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
      FContext.Fail('Should raise exception - parser not implemented');
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
      FContext.Fail('Should raise exception - parser not implemented');
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
      FContext.Fail('Should raise exception - parser not implemented');
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
      FContext.Fail('Should raise exception - parser not implemented');
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
      FContext.Fail('Should raise exception - parser not implemented');
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
      FContext.Fail('Should raise exception - parser not implemented');
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
    FContext.AssertTrue((2)=(cc.CellX), 'CellX should be 2');
    FContext.AssertTrue((3)=(cc.CellY), 'CellY should be 3');
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
    FContext.AssertTrue((1)=(cc.CellX), 'CellX should be 1');
    FContext.AssertTrue((2)=(cc.CellY), 'CellY should be 2');
    FContext.AssertTrue((3)=(cc.CellSpanX), 'SpanX should be 3');
    FContext.AssertTrue((4)=(cc.CellSpanY), 'SpanY should be 4');
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
    FContext.AssertTrue((2)=(cc.CellSpanX), 'SpanX should be 2');
    FContext.AssertTrue((3)=(cc.CellSpanY), 'SpanY should be 3');
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
    FContext.AssertTrue((2147471302)=(cc.CellSpanX), 'SpanX should be INF_SIZE');
    FContext.AssertTrue((1)=(cc.CellSpanY), 'SpanY should be 1');
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
    FContext.AssertTrue((5)=(cc.CellSpanX), 'SpanX should be 5');
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
    FContext.AssertTrue((2147471302)=(cc.CellSpanX), 'SpanX should be INF_SIZE');
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
    FContext.AssertTrue((4)=(cc.CellSpanY), 'SpanY should be 4');
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
    FContext.AssertTrue((2147471302)=(cc.CellSpanY), 'SpanY should be INF_SIZE');
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
    FContext.AssertTrue((2)=(cc.IsFlowX), 'FlowX should be 2 (true)');
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
    FContext.AssertTrue((1)=(cc.IsFlowX), 'FlowX should be 1 (false)');
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
    FContext.AssertTrue((3)=(cc.SkipCells), 'Skip should be 3');
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
    FContext.AssertTrue((1)=(cc.SkipCells), 'Skip should be 1');
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
    FContext.AssertTrue((4)=(cc.SplitParts), 'Split should be 4');
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
    FContext.AssertTrue((2147471302)=(cc.SplitParts), 'Split should be INF_SIZE');
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
    FContext.AssertTrue((cc.WrapGap)<>nil, 'Wrap should be set');
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
    FContext.AssertTrue((cc.NewlineGap)<>nil, 'Newline should be set');
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
    FContext.AssertTrue((0)=(cc.Dock), 'Dock should be 0 (north)');
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
    FContext.AssertTrue((1)=(cc.Dock), 'Dock should be 1 (west)');
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
    FContext.AssertTrue((2)=(cc.Dock), 'Dock should be 2 (south)');
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
    FContext.AssertTrue((3)=(cc.Dock), 'Dock should be 3 (east)');
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
    FContext.AssertTrue((2)=(cc.HideModeValue), 'HideMode should be 2');
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
    FContext.AssertTrue(('button1')=(cc.IdValue), 'Id should be "button1"');
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
    FContext.AssertTrue(('group1')=(cc.TagValue), 'Tag should be "group1"');
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
    FContext.AssertTrue(cc.IsExternal, 'External should be true');
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
    FContext.AssertTrue(not (cc.IsExternal), 'External should be false');
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
    FContext.AssertTrue(Abs((100.0)-(cc.PushWeightX))<=(0.001), 'PushX should be 100.0');
    FContext.AssertTrue(Abs((100.0)-(cc.PushWeightY))<=(0.001), 'PushY should be 100.0');
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
    FContext.AssertTrue(Abs((50.0)-(cc.PushWeightX))<=(0.001), 'PushX should be 50.0');
    FContext.AssertTrue(Abs((75.0)-(cc.PushWeightY))<=(0.001), 'PushY should be 75.0');
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
    FContext.AssertTrue(Abs((100.0)-(cc.PushWeightX))<=(0.001), 'PushX should be 100.0');
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
    FContext.AssertTrue(Abs((60.0)-(cc.PushWeightX))<=(0.001), 'PushX should be 60.0');
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
    FContext.AssertTrue(Abs((100.0)-(cc.PushWeightY))<=(0.001), 'PushY should be 100.0');
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
    FContext.AssertTrue(Abs((80.0)-(cc.PushWeightY))<=(0.001), 'PushY should be 80.0');
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

    FContext.AssertTrue(Abs((0.5)-(cc.Horizontal.GetGrowWeight))<=(0.001), 'Horizontal grow weight should be 0.5');
    FContext.AssertTrue(Abs((0.7)-(cc.Vertical.GetGrowWeight))<=(0.001), 'Vertical grow weight should be 0.7');
    FContext.AssertTrue(Abs((0.3)-(cc.Horizontal.GetShrinkWeight))<=(0.001), 'Horizontal shrink weight should be 0.3');
    FContext.AssertTrue(Abs((0.4)-(cc.Vertical.GetShrinkWeight))<=(0.001), 'Vertical shrink weight should be 0.4');
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

    FContext.AssertTrue((2)=(cc.CellX), 'CellX should be 2');
    FContext.AssertTrue((3)=(cc.CellY), 'CellY should be 3');
    FContext.AssertTrue((2)=(cc.CellSpanX), 'SpanX should be 2');
    FContext.AssertTrue((1)=(cc.CellSpanY), 'SpanY should be 1');
    FContext.AssertTrue((100)=(cc.Horizontal.GetGrowPriority), 'Horizontal grow priority should be 100');
    FContext.AssertTrue((100)=(cc.Vertical.GetGrowPriority), 'Vertical grow priority should be 100');
    FContext.AssertTrue(Abs((50.0)-(cc.PushWeightX))<=(0.001), 'PushX should be 50.0');
    FContext.AssertTrue(Abs((75.0)-(cc.PushWeightY))<=(0.001), 'PushY should be 75.0');
    FContext.AssertTrue(('test')=(cc.TagValue), 'Tag should be "test"');
    FContext.AssertTrue(('widget1')=(cc.IdValue), 'Id should be "widget1"');
  finally
    cc.Free;
  end;
end;


procedure RunTTestMigCCTestCreate(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreate';
    lFixture.TestCreate;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestDefaultValues(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDefaultValues';
    lFixture.TestDefaultValues;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSizeGroupX(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSizeGroupX';
    lFixture.TestSizeGroupX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestEndGroupX(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEndGroupX';
    lFixture.TestEndGroupX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestMinWidth(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMinWidth';
    lFixture.TestMinWidth;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestWidth(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestWidth';
    lFixture.TestWidth;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestMaxWidth(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMaxWidth';
    lFixture.TestMaxWidth;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGapX(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGapX';
    lFixture.TestGapX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestAlignX(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAlignX';
    lFixture.TestAlignX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGrowPrioX(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGrowPrioX';
    lFixture.TestGrowPrioX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGrowX_Default(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGrowX_Default';
    lFixture.TestGrowX_Default;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGrowX_Weight(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGrowX_Weight';
    lFixture.TestGrowX_Weight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestShrinkPrioX(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestShrinkPrioX';
    lFixture.TestShrinkPrioX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestShrinkX(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestShrinkX';
    lFixture.TestShrinkX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSizeGroupY(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSizeGroupY';
    lFixture.TestSizeGroupY;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestEndGroupY(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEndGroupY';
    lFixture.TestEndGroupY;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestMinHeight(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMinHeight';
    lFixture.TestMinHeight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestHeight(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestHeight';
    lFixture.TestHeight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestMaxHeight(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMaxHeight';
    lFixture.TestMaxHeight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGapY(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGapY';
    lFixture.TestGapY;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestAlignY(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAlignY';
    lFixture.TestAlignY;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGrowPrioY(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGrowPrioY';
    lFixture.TestGrowPrioY;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGrowY_Default(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGrowY_Default';
    lFixture.TestGrowY_Default;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGrowY_Weight(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGrowY_Weight';
    lFixture.TestGrowY_Weight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestShrinkPrioY(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestShrinkPrioY';
    lFixture.TestShrinkPrioY;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestShrinkY(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestShrinkY';
    lFixture.TestShrinkY;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSizeGroup_Both(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSizeGroup_Both';
    lFixture.TestSizeGroup_Both;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestEndGroup_Both(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEndGroup_Both';
    lFixture.TestEndGroup_Both;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGrow_Both(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGrow_Both';
    lFixture.TestGrow_Both;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGrow_BothDefault(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGrow_BothDefault';
    lFixture.TestGrow_BothDefault;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGrowPrio_Both(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGrowPrio_Both';
    lFixture.TestGrowPrio_Both;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestShrink_Both(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestShrink_Both';
    lFixture.TestShrink_Both;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestShrink_BothDefault(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestShrink_BothDefault';
    lFixture.TestShrink_BothDefault;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestShrinkPrio_Both(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestShrinkPrio_Both';
    lFixture.TestShrinkPrio_Both;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGapBefore(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGapBefore';
    lFixture.TestGapBefore;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGapAfter(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGapAfter';
    lFixture.TestGapAfter;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGapTop(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGapTop';
    lFixture.TestGapTop;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGapBottom(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGapBottom';
    lFixture.TestGapBottom;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGapLeft(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGapLeft';
    lFixture.TestGapLeft;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGapRight(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGapRight';
    lFixture.TestGapRight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestGap_FourSides(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGap_FourSides';
    lFixture.TestGap_FourSides;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestCell_TwoArgs(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCell_TwoArgs';
    lFixture.TestCell_TwoArgs;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestCell_FourArgs(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCell_FourArgs';
    lFixture.TestCell_FourArgs;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSpan_TwoArgs(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSpan_TwoArgs';
    lFixture.TestSpan_TwoArgs;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSpan_NoArgs(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSpan_NoArgs';
    lFixture.TestSpan_NoArgs;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSpanX_WithArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSpanX_WithArg';
    lFixture.TestSpanX_WithArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSpanX_NoArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSpanX_NoArg';
    lFixture.TestSpanX_NoArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSpanY_WithArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSpanY_WithArg';
    lFixture.TestSpanY_WithArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSpanY_NoArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSpanY_NoArg';
    lFixture.TestSpanY_NoArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestFlowX(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFlowX';
    lFixture.TestFlowX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestFlowY(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFlowY';
    lFixture.TestFlowY;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSkip_WithArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSkip_WithArg';
    lFixture.TestSkip_WithArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSkip_NoArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSkip_NoArg';
    lFixture.TestSkip_NoArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSplit_WithArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSplit_WithArg';
    lFixture.TestSplit_WithArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestSplit_NoArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSplit_NoArg';
    lFixture.TestSplit_NoArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestWrap_NoArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestWrap_NoArg';
    lFixture.TestWrap_NoArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestNewline_NoArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNewline_NoArg';
    lFixture.TestNewline_NoArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestDockNorth(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDockNorth';
    lFixture.TestDockNorth;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestDockWest(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDockWest';
    lFixture.TestDockWest;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestDockSouth(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDockSouth';
    lFixture.TestDockSouth;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestDockEast(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDockEast';
    lFixture.TestDockEast;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestX(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestX';
    lFixture.TestX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestY(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestY';
    lFixture.TestY;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestX2(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestX2';
    lFixture.TestX2;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestY2(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestY2';
    lFixture.TestY2;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestHideMode(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestHideMode';
    lFixture.TestHideMode;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestId(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestId';
    lFixture.TestId;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestTag(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestTag';
    lFixture.TestTag;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestExternal_NoArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExternal_NoArg';
    lFixture.TestExternal_NoArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestExternal_WithArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExternal_WithArg';
    lFixture.TestExternal_WithArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestPush_NoArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestPush_NoArg';
    lFixture.TestPush_NoArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestPush_WithArgs(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestPush_WithArgs';
    lFixture.TestPush_WithArgs;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestPushX_NoArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestPushX_NoArg';
    lFixture.TestPushX_NoArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestPushX_WithArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestPushX_WithArg';
    lFixture.TestPushX_WithArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestPushY_NoArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestPushY_NoArg';
    lFixture.TestPushY_NoArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestPushY_WithArg(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestPushY_WithArg';
    lFixture.TestPushY_WithArg;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestFluentChaining_Dimensions(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFluentChaining_Dimensions';
    lFixture.TestFluentChaining_Dimensions;
  finally lFixture.Free; end;
end;

procedure RunTTestMigCCTestFluentChaining_Mixed(AContext: TNXTestContext);
var lFixture: TTestMigCC;
begin
  lFixture:=TTestMigCC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFluentChaining_Mixed';
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

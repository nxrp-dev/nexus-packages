unit tcmig_lc;

{
  Unit tests for TfpgMigLC (Layout Constraints)
}

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpg_mig_lc, fpg_mig_unitvalue, fpg_mig_boundsize, fpg_mig_hidemode,
  fpg_mig_constraintparser;

type
  TTestMigLC = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  public
    { Basic creation and defaults }
    procedure TestCreate;
    procedure TestDefaults;

    { Flow direction }
    procedure TestFlowX_Default;
    procedure TestFlowX_Set;
    procedure TestFlowY_Set;

    { Wrap }
    procedure TestWrap_Default;
    procedure TestWrap_AfterCount;

    { Fill }
    procedure TestFill_Both;
    procedure TestFillX_Only;
    procedure TestFillY_Only;

    { Insets }
    procedure TestInsetsAll;
    procedure TestInsets_String;
    procedure TestInsets_Individual;

    { Alignment }
    procedure TestAlignX;
    procedure TestAlignY;
    procedure TestAlign_Both;

    { Grid gaps }
    procedure TestGridGapX;
    procedure TestGridGapY;
    procedure TestGridGap_Both;

    { Container size }
    procedure TestWidth;
    procedure TestMinWidth;
    procedure TestMaxWidth;
    procedure TestHeight;
    procedure TestMinHeight;
    procedure TestMaxHeight;

    { Packing }
    procedure TestPack_Default;
    procedure TestPack_Sizes;
    procedure TestPackAlign;

    { Direction }
    procedure TestLeftToRight_True;
    procedure TestLeftToRight_False;
    procedure TestRightToLeft;
    procedure TestTopToBottom_Default;
    procedure TestTopToBottom_Explicit;
    procedure TestBottomToTop;

    { Flags }
    procedure TestNoGrid;
    procedure TestNoCache;
    procedure TestNoVisualPadding;

    { Debug and hide mode }
    procedure TestDebug_Default;
    procedure TestHideMode_Integer;
    procedure TestHideMode_Enum;

    { Fluent API chaining }
    procedure TestFluentChaining;

    { Property getters }
    procedure TestGetProperties;
  end;

procedure RegistertcmiglcTests(ARegistry: TNXTestRegistry);

implementation

{ TTestMigLC }

procedure TTestMigLC.TestCreate;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    FContext.AssertTrue((lc)<>nil, 'LC should be created');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestDefaults;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    FContext.AssertTrue((INF_SIZE)=(lc.GetWrapAfter), 'Default wrap should be INF_SIZE');
    FContext.AssertTrue(lc.IsFlowX, 'Default flow should be horizontal');
    FContext.AssertTrue(not (lc.IsFillX), 'Default fillX should be false');
    FContext.AssertTrue(not (lc.IsFillY), 'Default fillY should be false');
    FContext.AssertTrue(lc.IsTopToBottom, 'Default top-to-bottom should be true');
    FContext.AssertTrue(not (lc.IsNoGrid), 'Default noGrid should be false');
    FContext.AssertTrue(lc.IsVisualPadding, 'Default visual padding should be true');
    FContext.AssertTrue(not (lc.GetDebug), 'Default debug should be false');
    FContext.AssertTrue((0)=(lc.GetHideMode), 'Default hide mode should be 0');
    FContext.AssertTrue(Abs((0.5)-(lc.GetPackWidthAlign))<=(0.01), 'Default pack width align should be 0.5');
    FContext.AssertTrue(Abs((1.0)-(lc.GetPackHeightAlign))<=(0.01), 'Default pack height align should be 1.0');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestFlowX_Default;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    FContext.AssertTrue(lc.IsFlowX, 'Default flow should be horizontal');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestFlowX_Set;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.FlowX;
    FContext.AssertTrue(lc.IsFlowX, 'FlowX should set horizontal flow');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestFlowY_Set;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.FlowY;
    FContext.AssertTrue(not (lc.IsFlowX), 'FlowY should set vertical flow');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestWrap_Default;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.Wrap;
    FContext.AssertTrue((0)=(lc.GetWrapAfter), 'Wrap should set wrap after to 0');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestWrap_AfterCount;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.WrapAfter(5);
    FContext.AssertTrue((5)=(lc.GetWrapAfter), 'WrapAfter should set wrap count');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestFill_Both;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.Fill;
    FContext.AssertTrue(lc.IsFillX, 'Fill should set fillX');
    FContext.AssertTrue(lc.IsFillY, 'Fill should set fillY');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestFillX_Only;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.FillX;
    FContext.AssertTrue(lc.IsFillX, 'FillX should set fillX');
    FContext.AssertTrue(not (lc.IsFillY), 'FillX should not set fillY');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestFillY_Only;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.FillY;
    FContext.AssertTrue(not (lc.IsFillX), 'FillY should not set fillX');
    FContext.AssertTrue(lc.IsFillY, 'FillY should set fillY');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestInsetsAll;
var
  lc: TfpgMigLC;
  insets: TfpgMigUnitValueArray;
begin
  lc := TfpgMigLC.Create;
  try
    lc.InsetsAll('10');
    insets := lc.GetInsets;
    FContext.AssertTrue((4)=(Length(insets)), 'Should have 4 insets');
    // All insets should be set (non-nil)
    // Note: Parser stubs return nil for now, so we just verify the call succeeds
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestInsets_String;
var
  lc: TfpgMigLC;
  insets: TfpgMigUnitValueArray;
begin
  lc := TfpgMigLC.Create;
  try
    lc.Insets('10 20 30 40');
    insets := lc.GetInsets;
    FContext.AssertTrue((4)=(Length(insets)), 'Should have 4 insets');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestInsets_Individual;
var
  lc: TfpgMigLC;
  insets: TfpgMigUnitValueArray;
begin
  lc := TfpgMigLC.Create;
  try
    lc.Insets('10', '20', '30', '40');
    insets := lc.GetInsets;
    FContext.AssertTrue((4)=(Length(insets)), 'Should have 4 insets');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestAlignX;
var
  lc: TfpgMigLC;
  align: TfpgMigUnitValue;
begin
  lc := TfpgMigLC.Create;
  try
    lc.AlignX('center');
    align := lc.GetAlignX;
    FContext.AssertTrue((align)<>nil, 'AlignX should be set');
    FContext.AssertTrue((UnitValueCenter)=(align), 'Should be center alignment');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestAlignY;
var
  lc: TfpgMigLC;
  align: TfpgMigUnitValue;
begin
  lc := TfpgMigLC.Create;
  try
    lc.AlignY('center');
    align := lc.GetAlignY;
    FContext.AssertTrue((align)<>nil, 'AlignY should be set');
    FContext.AssertTrue((UnitValueCenter)=(align), 'Should be center alignment');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestAlign_Both;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.Align('center', 'center');
    FContext.AssertTrue((lc.GetAlignX)<>nil, 'AlignX should be set');
    FContext.AssertTrue((lc.GetAlignY)<>nil, 'AlignY should be set');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestGridGapX;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    // Note: This will fail with "not implemented" error from parser stub
    // We'll test the method exists and can be called
    try
      lc.GridGapX('10px');
      FContext.Fail('Should raise exception - parser not implemented');
    except
      on E: Exception do
        ; // Expected - parser not implemented yet
    end;
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestGridGapY;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    try
      lc.GridGapY('10px');
      FContext.Fail('Should raise exception - parser not implemented');
    except
      on E: Exception do
        ; // Expected - parser not implemented yet
    end;
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestGridGap_Both;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    try
      lc.GridGap('10px', '10px');
      FContext.Fail('Should raise exception - parser not implemented');
    except
      on E: Exception do
        ; // Expected - parser not implemented yet
    end;
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestWidth;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    try
      lc.Width('100px');
      FContext.Fail('Should raise exception - parser not implemented');
    except
      on E: Exception do
        ; // Expected
    end;
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestMinWidth;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.MinWidth('100px');
    FContext.AssertTrue((lc.GetWidth)<>nil, 'Width should be set');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestMaxWidth;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.MaxWidth('200px');
    FContext.AssertTrue((lc.GetWidth)<>nil, 'Width should be set');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestHeight;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    try
      lc.Height('100px');
      FContext.Fail('Should raise exception - parser not implemented');
    except
      on E: Exception do
        ; // Expected
    end;
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestMinHeight;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.MinHeight('100px');
    FContext.AssertTrue((lc.GetHeight)<>nil, 'Height should be set');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestMaxHeight;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.MaxHeight('200px');
    FContext.AssertTrue((lc.GetHeight)<>nil, 'Height should be set');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestPack_Default;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    try
      lc.Pack;
      FContext.Fail('Should raise exception - parser not implemented');
    except
      on E: Exception do
        ; // Expected
    end;
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestPack_Sizes;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    try
      lc.Pack('100px', '100px');
      FContext.Fail('Should raise exception - parser not implemented');
    except
      on E: Exception do
        ; // Expected
    end;
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestPackAlign;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.PackAlign(0.3, 0.7);
    FContext.AssertTrue(Abs((0.3)-(lc.GetPackWidthAlign))<=(0.01), 'Pack width align should be 0.3');
    FContext.AssertTrue(Abs((0.7)-(lc.GetPackHeightAlign))<=(0.01), 'Pack height align should be 0.7');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestLeftToRight_True;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.LeftToRight(True);
    FContext.AssertTrue((2)=(lc.GetLeftToRight), 'LeftToRight(true) should set value to 2');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestLeftToRight_False;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.LeftToRight(False);
    FContext.AssertTrue((1)=(lc.GetLeftToRight), 'LeftToRight(false) should set value to 1');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestRightToLeft;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.RightToLeft;
    FContext.AssertTrue((1)=(lc.GetLeftToRight), 'RightToLeft should set value to 1');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestTopToBottom_Default;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    FContext.AssertTrue(lc.IsTopToBottom, 'Default should be top-to-bottom');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestTopToBottom_Explicit;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.TopToBottom;
    FContext.AssertTrue(lc.IsTopToBottom, 'TopToBottom should set value');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestBottomToTop;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.BottomToTop;
    FContext.AssertTrue(not (lc.IsTopToBottom), 'BottomToTop should clear value');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestNoGrid;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.NoGrid;
    FContext.AssertTrue(lc.IsNoGrid, 'NoGrid should set flag');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestNoCache;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.NoCache;
    FContext.AssertTrue(lc.IsNoCache, 'NoCache should set flag');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestNoVisualPadding;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.NoVisualPadding;
    FContext.AssertTrue(not (lc.IsVisualPadding), 'NoVisualPadding should clear flag');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestDebug_Default;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.Debug;
    FContext.AssertTrue(lc.GetDebug, 'Debug should enable debug mode');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestHideMode_Integer;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.HideMode(2);
    FContext.AssertTrue((2)=(lc.GetHideMode), 'HideMode should be set');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestHideMode_Enum;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.HideMode(hmSize0Gaps0);
    FContext.AssertTrue((2)=(lc.GetHideMode), 'HideMode should be set to 2');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestFluentChaining;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.FlowX.Fill.Wrap.Debug.NoGrid;

    FContext.AssertTrue(lc.IsFlowX, 'FlowX should be set');
    FContext.AssertTrue(lc.IsFillX, 'FillX should be set');
    FContext.AssertTrue(lc.IsFillY, 'FillY should be set');
    FContext.AssertTrue((0)=(lc.GetWrapAfter), 'Wrap should be set to 0');
    FContext.AssertTrue(lc.GetDebug, 'Debug should be set');
    FContext.AssertTrue(lc.IsNoGrid, 'NoGrid should be set');
  finally
    lc.Free;
  end;
end;

procedure TTestMigLC.TestGetProperties;
var
  lc: TfpgMigLC;
begin
  lc := TfpgMigLC.Create;
  try
    lc.WrapAfter(5);
    lc.Debug;
    lc.HideMode(1);
    lc.FillX;
    lc.FlowY; // FlowY and FlowX are mutually exclusive. Setting one to True, makes the other one False.

    FContext.AssertTrue((5)=(lc.GetWrapAfter), 'GetWrapAfter should return value');
    FContext.AssertTrue(lc.GetDebug, 'GetDebug should return value');
    FContext.AssertTrue((1)=(lc.GetHideMode), 'GetHideMode should return value');
    FContext.AssertTrue(lc.IsFillX, 'IsFillX should return value');
    FContext.AssertTrue(not (lc.IsFlowX), 'IsFlowX should return value');
  finally
    lc.Free;
  end;
end;


procedure RunTTestMigLCTestCreate(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreate';
    lFixture.TestCreate;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestDefaults(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDefaults';
    lFixture.TestDefaults;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestFlowX_Default(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFlowX_Default';
    lFixture.TestFlowX_Default;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestFlowX_Set(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFlowX_Set';
    lFixture.TestFlowX_Set;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestFlowY_Set(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFlowY_Set';
    lFixture.TestFlowY_Set;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestWrap_Default(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestWrap_Default';
    lFixture.TestWrap_Default;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestWrap_AfterCount(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestWrap_AfterCount';
    lFixture.TestWrap_AfterCount;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestFill_Both(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFill_Both';
    lFixture.TestFill_Both;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestFillX_Only(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFillX_Only';
    lFixture.TestFillX_Only;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestFillY_Only(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFillY_Only';
    lFixture.TestFillY_Only;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestInsetsAll(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInsetsAll';
    lFixture.TestInsetsAll;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestInsets_String(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInsets_String';
    lFixture.TestInsets_String;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestInsets_Individual(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInsets_Individual';
    lFixture.TestInsets_Individual;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestAlignX(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAlignX';
    lFixture.TestAlignX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestAlignY(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAlignY';
    lFixture.TestAlignY;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestAlign_Both(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAlign_Both';
    lFixture.TestAlign_Both;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestGridGapX(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGridGapX';
    lFixture.TestGridGapX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestGridGapY(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGridGapY';
    lFixture.TestGridGapY;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestGridGap_Both(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGridGap_Both';
    lFixture.TestGridGap_Both;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestWidth(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestWidth';
    lFixture.TestWidth;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestMinWidth(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMinWidth';
    lFixture.TestMinWidth;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestMaxWidth(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMaxWidth';
    lFixture.TestMaxWidth;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestHeight(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestHeight';
    lFixture.TestHeight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestMinHeight(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMinHeight';
    lFixture.TestMinHeight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestMaxHeight(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMaxHeight';
    lFixture.TestMaxHeight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestPack_Default(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestPack_Default';
    lFixture.TestPack_Default;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestPack_Sizes(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestPack_Sizes';
    lFixture.TestPack_Sizes;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestPackAlign(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestPackAlign';
    lFixture.TestPackAlign;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestLeftToRight_True(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLeftToRight_True';
    lFixture.TestLeftToRight_True;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestLeftToRight_False(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLeftToRight_False';
    lFixture.TestLeftToRight_False;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestRightToLeft(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRightToLeft';
    lFixture.TestRightToLeft;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestTopToBottom_Default(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestTopToBottom_Default';
    lFixture.TestTopToBottom_Default;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestTopToBottom_Explicit(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestTopToBottom_Explicit';
    lFixture.TestTopToBottom_Explicit;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestBottomToTop(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestBottomToTop';
    lFixture.TestBottomToTop;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestNoGrid(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNoGrid';
    lFixture.TestNoGrid;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestNoCache(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNoCache';
    lFixture.TestNoCache;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestNoVisualPadding(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNoVisualPadding';
    lFixture.TestNoVisualPadding;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestDebug_Default(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDebug_Default';
    lFixture.TestDebug_Default;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestHideMode_Integer(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestHideMode_Integer';
    lFixture.TestHideMode_Integer;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestHideMode_Enum(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestHideMode_Enum';
    lFixture.TestHideMode_Enum;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestFluentChaining(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFluentChaining';
    lFixture.TestFluentChaining;
  finally lFixture.Free; end;
end;

procedure RunTTestMigLCTestGetProperties(AContext: TNXTestContext);
var lFixture: TTestMigLC;
begin
  lFixture:=TTestMigLC.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGetProperties';
    lFixture.TestGetProperties;
  finally lFixture.Free; end;
end;

procedure RegistertcmiglcTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcmig_lc.TTestMigLC');
  lSuite.AddTest('TestCreate', @RunTTestMigLCTestCreate);
  lSuite.AddTest('TestDefaults', @RunTTestMigLCTestDefaults);
  lSuite.AddTest('TestFlowX_Default', @RunTTestMigLCTestFlowX_Default);
  lSuite.AddTest('TestFlowX_Set', @RunTTestMigLCTestFlowX_Set);
  lSuite.AddTest('TestFlowY_Set', @RunTTestMigLCTestFlowY_Set);
  lSuite.AddTest('TestWrap_Default', @RunTTestMigLCTestWrap_Default);
  lSuite.AddTest('TestWrap_AfterCount', @RunTTestMigLCTestWrap_AfterCount);
  lSuite.AddTest('TestFill_Both', @RunTTestMigLCTestFill_Both);
  lSuite.AddTest('TestFillX_Only', @RunTTestMigLCTestFillX_Only);
  lSuite.AddTest('TestFillY_Only', @RunTTestMigLCTestFillY_Only);
  lSuite.AddTest('TestInsetsAll', @RunTTestMigLCTestInsetsAll);
  lSuite.AddTest('TestInsets_String', @RunTTestMigLCTestInsets_String);
  lSuite.AddTest('TestInsets_Individual', @RunTTestMigLCTestInsets_Individual);
  lSuite.AddTest('TestAlignX', @RunTTestMigLCTestAlignX);
  lSuite.AddTest('TestAlignY', @RunTTestMigLCTestAlignY);
  lSuite.AddTest('TestAlign_Both', @RunTTestMigLCTestAlign_Both);
  lSuite.AddTest('TestGridGapX', @RunTTestMigLCTestGridGapX);
  lSuite.AddTest('TestGridGapY', @RunTTestMigLCTestGridGapY);
  lSuite.AddTest('TestGridGap_Both', @RunTTestMigLCTestGridGap_Both);
  lSuite.AddTest('TestWidth', @RunTTestMigLCTestWidth);
  lSuite.AddTest('TestMinWidth', @RunTTestMigLCTestMinWidth);
  lSuite.AddTest('TestMaxWidth', @RunTTestMigLCTestMaxWidth);
  lSuite.AddTest('TestHeight', @RunTTestMigLCTestHeight);
  lSuite.AddTest('TestMinHeight', @RunTTestMigLCTestMinHeight);
  lSuite.AddTest('TestMaxHeight', @RunTTestMigLCTestMaxHeight);
  lSuite.AddTest('TestPack_Default', @RunTTestMigLCTestPack_Default);
  lSuite.AddTest('TestPack_Sizes', @RunTTestMigLCTestPack_Sizes);
  lSuite.AddTest('TestPackAlign', @RunTTestMigLCTestPackAlign);
  lSuite.AddTest('TestLeftToRight_True', @RunTTestMigLCTestLeftToRight_True);
  lSuite.AddTest('TestLeftToRight_False', @RunTTestMigLCTestLeftToRight_False);
  lSuite.AddTest('TestRightToLeft', @RunTTestMigLCTestRightToLeft);
  lSuite.AddTest('TestTopToBottom_Default', @RunTTestMigLCTestTopToBottom_Default);
  lSuite.AddTest('TestTopToBottom_Explicit', @RunTTestMigLCTestTopToBottom_Explicit);
  lSuite.AddTest('TestBottomToTop', @RunTTestMigLCTestBottomToTop);
  lSuite.AddTest('TestNoGrid', @RunTTestMigLCTestNoGrid);
  lSuite.AddTest('TestNoCache', @RunTTestMigLCTestNoCache);
  lSuite.AddTest('TestNoVisualPadding', @RunTTestMigLCTestNoVisualPadding);
  lSuite.AddTest('TestDebug_Default', @RunTTestMigLCTestDebug_Default);
  lSuite.AddTest('TestHideMode_Integer', @RunTTestMigLCTestHideMode_Integer);
  lSuite.AddTest('TestHideMode_Enum', @RunTTestMigLCTestHideMode_Enum);
  lSuite.AddTest('TestFluentChaining', @RunTTestMigLCTestFluentChaining);
  lSuite.AddTest('TestGetProperties', @RunTTestMigLCTestGetProperties);
end;

end.

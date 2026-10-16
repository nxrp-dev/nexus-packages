{
  Tests for per-column stretch weights on TfpgBaseGrid descendants.

  Stretch weights let columns share the grid's spare client width
  proportionally. A weight of 0 keeps a column at its set width.
}
unit tcgridstretch;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  fpg_base,
  fpg_main,
  fpg_basegrid,
  fpg_scrollbar,
  fpg_customgrid,
  fpg_grid;

type

  TTestGridStretch = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FGrid: TfpgStringGrid;
    procedure SetupColumns(ACount: integer; AWidth: integer);
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestColumnStretchDefaultsToZero;
    procedure TestColumnMinWidthDefault;
    procedure TestNoStretchLeavesWidthsAlone;
    procedure TestSingleStretchColumnAbsorbsSlack;
    procedure TestFixedColumnsKeepTheirWidth;
    procedure TestWeightsDistributeProportionally;
    procedure TestEqualWeightsSplitEvenly;
    procedure TestRemainderGoesToLastStretchColumn;
    procedure TestShrinkRespectsMinWidth;
    procedure TestStretchGrowsFromBelowMinWidth;
    procedure TestHasStretchColumns;
  end;

procedure RegisterTests;

procedure RegistertcgridstretchTests(ARegistry: TNXTestRegistry);

implementation

procedure RegisterTests;
begin
  
end;

{ TTestGridStretch }

procedure TTestGridStretch.SetUp;
begin
  
  FGrid := TfpgStringGrid.Create(nil);
  FGrid.ScrollBarStyle := ssNone;
end;

procedure TTestGridStretch.TearDown;
begin
  FreeAndNil(FGrid);
  
end;

procedure TTestGridStretch.SetupColumns(ACount: integer; AWidth: integer);
var
  i: integer;
begin
  for i := 1 to ACount do
    FGrid.AddColumn(Format('Col%d', [i]), AWidth);
end;

procedure TTestGridStretch.TestColumnStretchDefaultsToZero;
begin
  SetupColumns(2, 50);
  FContext.AssertTrue((0)=(FGrid.ColumnStretch[0]), 'Column 0 stretch default');
  FContext.AssertTrue((0)=(FGrid.ColumnStretch[1]), 'Column 1 stretch default');
end;

procedure TTestGridStretch.TestColumnMinWidthDefault;
begin
  SetupColumns(1, 50);
  FContext.AssertTrue((8)=(FGrid.ColumnMinWidth[0]), 'Column MinWidth default');
end;

procedure TTestGridStretch.TestNoStretchLeavesWidthsAlone;
begin
  SetupColumns(2, 50);
  FGrid.DistributeStretchWidths(400);
  FContext.AssertTrue((50)=(FGrid.ColumnWidth[0]), 'Column 0 unchanged');
  FContext.AssertTrue((50)=(FGrid.ColumnWidth[1]), 'Column 1 unchanged');
end;

procedure TTestGridStretch.TestSingleStretchColumnAbsorbsSlack;
begin
  SetupColumns(2, 50);
  FGrid.ColumnStretch[1] := 1;
  FGrid.DistributeStretchWidths(300);
  FContext.AssertTrue((50)=(FGrid.ColumnWidth[0]), 'Fixed column keeps width');
  FContext.AssertTrue((250)=(FGrid.ColumnWidth[1]), 'Stretch column absorbs the rest');
end;

procedure TTestGridStretch.TestFixedColumnsKeepTheirWidth;
begin
  SetupColumns(3, 40);
  FGrid.ColumnWidth[0] := 60;
  FGrid.ColumnWidth[1] := 70;
  FGrid.ColumnStretch[2] := 1;
  FGrid.DistributeStretchWidths(300);
  FContext.AssertTrue((60)=(FGrid.ColumnWidth[0]), 'Column 0 fixed');
  FContext.AssertTrue((70)=(FGrid.ColumnWidth[1]), 'Column 1 fixed');
  FContext.AssertTrue((170)=(FGrid.ColumnWidth[2]), 'Column 2 takes 300-60-70');
end;

procedure TTestGridStretch.TestWeightsDistributeProportionally;
begin
  SetupColumns(2, 10);
  FGrid.ColumnStretch[0] := 2;
  FGrid.ColumnStretch[1] := 1;
  FGrid.DistributeStretchWidths(300);
  { 300 shared 2:1 }
  FContext.AssertTrue((200)=(FGrid.ColumnWidth[0]), 'Weight 2 gets two thirds');
  FContext.AssertTrue((100)=(FGrid.ColumnWidth[1]), 'Weight 1 gets one third');
end;

procedure TTestGridStretch.TestEqualWeightsSplitEvenly;
begin
  SetupColumns(2, 10);
  FGrid.ColumnStretch[0] := 1;
  FGrid.ColumnStretch[1] := 1;
  FGrid.DistributeStretchWidths(400);
  FContext.AssertTrue((200)=(FGrid.ColumnWidth[0]), 'Even split, column 0');
  FContext.AssertTrue((200)=(FGrid.ColumnWidth[1]), 'Even split, column 1');
end;

procedure TTestGridStretch.TestRemainderGoesToLastStretchColumn;
begin
  SetupColumns(3, 10);
  FGrid.ColumnStretch[0] := 1;
  FGrid.ColumnStretch[1] := 1;
  FGrid.ColumnStretch[2] := 1;
  { 100 / 3 = 33 remainder 1 }
  FGrid.DistributeStretchWidths(100);
  FContext.AssertTrue((33)=(FGrid.ColumnWidth[0]), 'Column 0 base share');
  FContext.AssertTrue((33)=(FGrid.ColumnWidth[1]), 'Column 1 base share');
  FContext.AssertTrue((34)=(FGrid.ColumnWidth[2]), 'Last stretch column takes remainder');
  FContext.AssertTrue((100)=(FGrid.ColumnWidth[0] + FGrid.ColumnWidth[1] + FGrid.ColumnWidth[2]), 'Widths sum exactly to available width');
end;

procedure TTestGridStretch.TestShrinkRespectsMinWidth;
begin
  SetupColumns(2, 10);
  FGrid.ColumnMinWidth[0] := 50;
  FGrid.ColumnMinWidth[1] := 50;
  FGrid.ColumnStretch[0] := 1;
  FGrid.ColumnStretch[1] := 1;
  FGrid.DistributeStretchWidths(80);
  FContext.AssertTrue((50)=(FGrid.ColumnWidth[0]), 'Column 0 clamped at MinWidth');
  FContext.AssertTrue((50)=(FGrid.ColumnWidth[1]), 'Column 1 clamped at MinWidth');
end;

procedure TTestGridStretch.TestStretchGrowsFromBelowMinWidth;
begin
  SetupColumns(1, 10);
  FGrid.ColumnMinWidth[0] := 20;
  FGrid.ColumnStretch[0] := 1;
  FGrid.DistributeStretchWidths(200);
  FContext.AssertTrue((200)=(FGrid.ColumnWidth[0]), 'MinWidth is a floor, not a cap');
end;

procedure TTestGridStretch.TestHasStretchColumns;
begin
  SetupColumns(2, 50);
  FContext.AssertTrue(not (FGrid.HasStretchColumns), 'No weights set');
  FGrid.ColumnStretch[1] := 1;
  FContext.AssertTrue(FGrid.HasStretchColumns, 'Weight set on column 1');
  FGrid.ColumnStretch[1] := 0;
  FContext.AssertTrue(not (FGrid.HasStretchColumns), 'Weight cleared again');
end;

procedure RunTTestGridStretchTestColumnStretchDefaultsToZero(AContext: TNXTestContext);
var lFixture: TTestGridStretch;
begin
  lFixture:=TTestGridStretch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestColumnStretchDefaultsToZero';
    lFixture.SetUp;
    try lFixture.TestColumnStretchDefaultsToZero; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGridStretchTestColumnMinWidthDefault(AContext: TNXTestContext);
var lFixture: TTestGridStretch;
begin
  lFixture:=TTestGridStretch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestColumnMinWidthDefault';
    lFixture.SetUp;
    try lFixture.TestColumnMinWidthDefault; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGridStretchTestNoStretchLeavesWidthsAlone(AContext: TNXTestContext);
var lFixture: TTestGridStretch;
begin
  lFixture:=TTestGridStretch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNoStretchLeavesWidthsAlone';
    lFixture.SetUp;
    try lFixture.TestNoStretchLeavesWidthsAlone; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGridStretchTestSingleStretchColumnAbsorbsSlack(AContext: TNXTestContext);
var lFixture: TTestGridStretch;
begin
  lFixture:=TTestGridStretch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSingleStretchColumnAbsorbsSlack';
    lFixture.SetUp;
    try lFixture.TestSingleStretchColumnAbsorbsSlack; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGridStretchTestFixedColumnsKeepTheirWidth(AContext: TNXTestContext);
var lFixture: TTestGridStretch;
begin
  lFixture:=TTestGridStretch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFixedColumnsKeepTheirWidth';
    lFixture.SetUp;
    try lFixture.TestFixedColumnsKeepTheirWidth; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGridStretchTestWeightsDistributeProportionally(AContext: TNXTestContext);
var lFixture: TTestGridStretch;
begin
  lFixture:=TTestGridStretch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestWeightsDistributeProportionally';
    lFixture.SetUp;
    try lFixture.TestWeightsDistributeProportionally; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGridStretchTestEqualWeightsSplitEvenly(AContext: TNXTestContext);
var lFixture: TTestGridStretch;
begin
  lFixture:=TTestGridStretch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEqualWeightsSplitEvenly';
    lFixture.SetUp;
    try lFixture.TestEqualWeightsSplitEvenly; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGridStretchTestRemainderGoesToLastStretchColumn(AContext: TNXTestContext);
var lFixture: TTestGridStretch;
begin
  lFixture:=TTestGridStretch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRemainderGoesToLastStretchColumn';
    lFixture.SetUp;
    try lFixture.TestRemainderGoesToLastStretchColumn; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGridStretchTestShrinkRespectsMinWidth(AContext: TNXTestContext);
var lFixture: TTestGridStretch;
begin
  lFixture:=TTestGridStretch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestShrinkRespectsMinWidth';
    lFixture.SetUp;
    try lFixture.TestShrinkRespectsMinWidth; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGridStretchTestStretchGrowsFromBelowMinWidth(AContext: TNXTestContext);
var lFixture: TTestGridStretch;
begin
  lFixture:=TTestGridStretch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestStretchGrowsFromBelowMinWidth';
    lFixture.SetUp;
    try lFixture.TestStretchGrowsFromBelowMinWidth; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGridStretchTestHasStretchColumns(AContext: TNXTestContext);
var lFixture: TTestGridStretch;
begin
  lFixture:=TTestGridStretch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestHasStretchColumns';
    lFixture.SetUp;
    try lFixture.TestHasStretchColumns; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegistertcgridstretchTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcgridstretch.TTestGridStretch');
  lSuite.AddTest('TestColumnStretchDefaultsToZero', @RunTTestGridStretchTestColumnStretchDefaultsToZero);
  lSuite.AddTest('TestColumnMinWidthDefault', @RunTTestGridStretchTestColumnMinWidthDefault);
  lSuite.AddTest('TestNoStretchLeavesWidthsAlone', @RunTTestGridStretchTestNoStretchLeavesWidthsAlone);
  lSuite.AddTest('TestSingleStretchColumnAbsorbsSlack', @RunTTestGridStretchTestSingleStretchColumnAbsorbsSlack);
  lSuite.AddTest('TestFixedColumnsKeepTheirWidth', @RunTTestGridStretchTestFixedColumnsKeepTheirWidth);
  lSuite.AddTest('TestWeightsDistributeProportionally', @RunTTestGridStretchTestWeightsDistributeProportionally);
  lSuite.AddTest('TestEqualWeightsSplitEvenly', @RunTTestGridStretchTestEqualWeightsSplitEvenly);
  lSuite.AddTest('TestRemainderGoesToLastStretchColumn', @RunTTestGridStretchTestRemainderGoesToLastStretchColumn);
  lSuite.AddTest('TestShrinkRespectsMinWidth', @RunTTestGridStretchTestShrinkRespectsMinWidth);
  lSuite.AddTest('TestStretchGrowsFromBelowMinWidth', @RunTTestGridStretchTestStretchGrowsFromBelowMinWidth);
  lSuite.AddTest('TestHasStretchColumns', @RunTTestGridStretchTestHasStretchColumns);
end;


initialization
  RegisterTests;

end.

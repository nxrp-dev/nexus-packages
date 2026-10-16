unit tcborderlayout;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpg_base, fpg_main, fpg_widget, fpg_panel, fpg_button,
  fpg_layouttypes, fpg_borderlayout;

type

  TTestBorderLayout = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    procedure TestLayout;
    procedure TestGaps;
    procedure TestPreferredSize;
    procedure TestMinimumSize;
  end;

procedure RegistertcborderlayoutTests(ARegistry: TNXTestRegistry);

implementation

uses
  fpg_layoutmanager;

{ TTestBorderLayout }

procedure TTestBorderLayout.TestLayout;
var
  container: TfpgWidget;
  lm: TfpgBorderLayoutManager;
  wNorth, wSouth, wEast, wWest, wCenter: TfpgWidget;
  c: TfpgBorderLayoutConstraint;
begin
  container := TfpgWidget.Create(nil);
  container.Name := 'container';
  container.Width := 200;
  container.Height := 200;
  lm := TfpgBorderLayoutManager.Create;
  container.LayoutManager := lm;

  wNorth := TfpgWidget.Create(container);
  wNorth.Name := 'north';
  wNorth.PreferredSize := fpgSize(200, 20);
  c := TfpgBorderLayoutConstraint.Create;
  c.Region := blrNorth;
  lm.AddLayoutComponent(wNorth, c);

  wSouth := TfpgWidget.Create(container);
  wSouth.Name := 'south';
  wSouth.PreferredSize := fpgSize(200, 20);
  c := TfpgBorderLayoutConstraint.Create;
  c.Region := blrSouth;
  lm.AddLayoutComponent(wSouth, c);

  wEast := TfpgWidget.Create(container);
  wEast.Name := 'east';
  wEast.PreferredSize := fpgSize(20, 160);
  c := TfpgBorderLayoutConstraint.Create;
  c.Region := blrEast;
  lm.AddLayoutComponent(wEast, c);

  wWest := TfpgWidget.Create(container);
  wWest.Name := 'west';
  wWest.PreferredSize := fpgSize(20, 160);
  c := TfpgBorderLayoutConstraint.Create;
  c.Region := blrWest;
  lm.AddLayoutComponent(wWest, c);

  wCenter := TfpgWidget.Create(container);
  wCenter.Name := 'center';
  c := TfpgBorderLayoutConstraint.Create;
  c.Region := blrCenter;
  lm.AddLayoutComponent(wCenter, c);

  container.Realign;

  TestContext.AssertTrue((0)=(wNorth.Top), 'wNorth.Top');
  TestContext.AssertTrue((0)=(wNorth.Left), 'wNorth.Left');
  TestContext.AssertTrue((200)=(wNorth.ActualWidth), 'wNorth.ActualWidth');
  TestContext.AssertTrue((20)=(wNorth.ActualHeight), 'wNorth.ActualHeight');

  TestContext.AssertTrue((180)=(wSouth.Top), 'wSouth.Top');
  TestContext.AssertTrue((0)=(wSouth.Left), 'wSouth.Left');
  TestContext.AssertTrue((200)=(wSouth.ActualWidth), 'wSouth.ActualWidth');
  TestContext.AssertTrue((20)=(wSouth.ActualHeight), 'wSouth.ActualHeight');

  TestContext.AssertTrue((20)=(wWest.Top), 'wWest.Top');
  TestContext.AssertTrue((0)=(wWest.Left), 'wWest.Left');
  TestContext.AssertTrue((20)=(wWest.ActualWidth), 'wWest.ActualWidth');
  TestContext.AssertTrue((160)=(wWest.ActualHeight), 'wWest.ActualHeight');

  TestContext.AssertTrue((20)=(wEast.Top), 'wEast.Top');
  TestContext.AssertTrue((180)=(wEast.Left), 'wEast.Left');
  TestContext.AssertTrue((20)=(wEast.ActualWidth), 'wEast.ActualWidth');
  TestContext.AssertTrue((160)=(wEast.ActualHeight), 'wEast.ActualHeight');

  TestContext.AssertTrue((20)=(wCenter.Top), 'wCenter.Top');
  TestContext.AssertTrue((20)=(wCenter.Left), 'wCenter.Left');
  TestContext.AssertTrue((160)=(wCenter.ActualWidth), 'wCenter.ActualWidth');
  TestContext.AssertTrue((160)=(wCenter.ActualHeight), 'wCenter.ActualHeight');

  container.Free;
end;

procedure TTestBorderLayout.TestGaps;
var
  container: TfpgPanel;
  lm: ILayoutManager;
  wNorth, wSouth, wWest: TfpgButton;
  c: TfpgBorderLayoutConstraint;
begin
  container := TfpgPanel.Create(nil);
  container.Name := 'container';
  container.Width := 200;
  container.Height := 200;
  lm := TfpgBorderLayoutManager.Create(5, 10);
  container.LayoutManager := lm;

  wNorth := TfpgButton.Create(container);
  wNorth.Name := 'north';
  wNorth.PreferredSize := fpgSize(200, 20);
  c := TfpgBorderLayoutConstraint.Create;
  c.Region := blrNorth;
  lm.AddLayoutComponent(wNorth, c);

  wSouth := TfpgButton.Create(container);
  wSouth.Name := 'south';
  wSouth.PreferredSize := fpgSize(200, 20);
  c := TfpgBorderLayoutConstraint.Create;
  c.Region := blrSouth;
  lm.AddLayoutComponent(wSouth, c);

  wWest := TfpgButton.Create(container);
  wWest.Name := 'west';
  wWest.PreferredSize := fpgSize(20, 160);
  c := TfpgBorderLayoutConstraint.Create;
  c.Region := blrWest;
  lm.AddLayoutComponent(wWest, c);

  container.Realign;

  TestContext.AssertTrue((12)=(wNorth.Top), 'wNorth.Top with gap');
  TestContext.AssertTrue((42)=(wWest.Top), 'wWest.Top with gap');
  TestContext.AssertTrue((168)=(wSouth.Top), 'wSouth.Top with gap');
  TestContext.AssertTrue((7)=(wWest.Left), 'wWest.Left with gap');

  container.Free;
end;

procedure TTestBorderLayout.TestPreferredSize;
var
  container: TfpgWidget;
  lm: ILayoutManager;
  wNorth, wCenter: TfpgWidget;
  c: TfpgBorderLayoutConstraint;
  pref: TfpgSize;
begin
  container := TfpgWidget.Create(nil);
  lm := TfpgBorderLayoutManager.Create;
  container.LayoutManager := lm;

  wNorth := TfpgWidget.Create(container);
  wNorth.PreferredSize := fpgSize(100, 20);
  c := TfpgBorderLayoutConstraint.Create;
  c.Region := blrNorth;
  lm.AddLayoutComponent(wNorth, c);

  wCenter := TfpgWidget.Create(container);
  wCenter.PreferredSize := fpgSize(50, 50);
  c := TfpgBorderLayoutConstraint.Create;
  c.Region := blrCenter;
  lm.AddLayoutComponent(wCenter, c);

  pref := lm.GetPreferredSize(container);

  TestContext.AssertTrue((100)=(pref.W), 'PreferredWidth');
  TestContext.AssertTrue((70)=(pref.H), 'PreferredHeight');

  container.Free;
end;

procedure TTestBorderLayout.TestMinimumSize;
var
  container: TfpgWidget;
  lm: ILayoutManager;
  wNorth, wCenter: TfpgWidget;
  c: TfpgBorderLayoutConstraint;
  min: TfpgSize;
begin
  container := TfpgWidget.Create(nil);
  lm := TfpgBorderLayoutManager.Create;
  container.LayoutManager := lm;

  wNorth := TfpgWidget.Create(container);
  wNorth.MinWidth := 80;
  wNorth.MinHeight := 15;
  c := TfpgBorderLayoutConstraint.Create;
  c.Region := blrNorth;
  lm.AddLayoutComponent(wNorth, c);

  wCenter := TfpgWidget.Create(container);
  wCenter.MinWidth := 40;
  wCenter.MinHeight := 40;
  c := TfpgBorderLayoutConstraint.Create;
  c.Region := blrCenter;
  lm.AddLayoutComponent(wCenter, c);

  min := lm.GetMinimumSize(container);

  TestContext.AssertTrue((80)=(min.W), 'MinimumWidth');
  TestContext.AssertTrue((55)=(min.H), 'MinimumHeight');

  container.Free;
end;

constructor TTestBorderLayout.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestBorderLayoutTestLayout(AContext: TNXTestContext);
var lFixture: TTestBorderLayout;
begin
  lFixture:=TTestBorderLayout.Create(AContext, 'TestLayout');
  try
    lFixture.TestLayout;
  finally lFixture.Free; end;
end;

procedure RunTTestBorderLayoutTestGaps(AContext: TNXTestContext);
var lFixture: TTestBorderLayout;
begin
  lFixture:=TTestBorderLayout.Create(AContext, 'TestGaps');
  try
    lFixture.TestGaps;
  finally lFixture.Free; end;
end;

procedure RunTTestBorderLayoutTestPreferredSize(AContext: TNXTestContext);
var lFixture: TTestBorderLayout;
begin
  lFixture:=TTestBorderLayout.Create(AContext, 'TestPreferredSize');
  try
    lFixture.TestPreferredSize;
  finally lFixture.Free; end;
end;

procedure RunTTestBorderLayoutTestMinimumSize(AContext: TNXTestContext);
var lFixture: TTestBorderLayout;
begin
  lFixture:=TTestBorderLayout.Create(AContext, 'TestMinimumSize');
  try
    lFixture.TestMinimumSize;
  finally lFixture.Free; end;
end;

procedure RegistertcborderlayoutTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcborderlayout.TTestBorderLayout');
  lSuite.AddTest('TestLayout', @RunTTestBorderLayoutTestLayout);
  lSuite.AddTest('TestGaps', @RunTTestBorderLayoutTestGaps);
  lSuite.AddTest('TestPreferredSize', @RunTTestBorderLayoutTestPreferredSize);
  lSuite.AddTest('TestMinimumSize', @RunTTestBorderLayoutTestMinimumSize);
end;


end.

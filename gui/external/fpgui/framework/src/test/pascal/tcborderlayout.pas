unit tcborderlayout;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpg_base, fpg_main, fpg_widget, fpg_panel, fpg_button,
  fpg_layouttypes, fpg_borderlayout;

type

  TTestBorderLayout = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  public
    procedure TestLayout;
    procedure TestGaps;
    procedure TestPreferredSize;
    procedure TestMinimumSize;
  end;

procedure RegisterTests;

procedure RegistertcborderlayoutTests(ARegistry: TNXTestRegistry);

implementation

uses
  fpg_layoutmanager;

procedure RegisterTests;
begin
  
end;

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

  FContext.AssertTrue((0)=(wNorth.Top), 'wNorth.Top');
  FContext.AssertTrue((0)=(wNorth.Left), 'wNorth.Left');
  FContext.AssertTrue((200)=(wNorth.ActualWidth), 'wNorth.ActualWidth');
  FContext.AssertTrue((20)=(wNorth.ActualHeight), 'wNorth.ActualHeight');

  FContext.AssertTrue((180)=(wSouth.Top), 'wSouth.Top');
  FContext.AssertTrue((0)=(wSouth.Left), 'wSouth.Left');
  FContext.AssertTrue((200)=(wSouth.ActualWidth), 'wSouth.ActualWidth');
  FContext.AssertTrue((20)=(wSouth.ActualHeight), 'wSouth.ActualHeight');

  FContext.AssertTrue((20)=(wWest.Top), 'wWest.Top');
  FContext.AssertTrue((0)=(wWest.Left), 'wWest.Left');
  FContext.AssertTrue((20)=(wWest.ActualWidth), 'wWest.ActualWidth');
  FContext.AssertTrue((160)=(wWest.ActualHeight), 'wWest.ActualHeight');

  FContext.AssertTrue((20)=(wEast.Top), 'wEast.Top');
  FContext.AssertTrue((180)=(wEast.Left), 'wEast.Left');
  FContext.AssertTrue((20)=(wEast.ActualWidth), 'wEast.ActualWidth');
  FContext.AssertTrue((160)=(wEast.ActualHeight), 'wEast.ActualHeight');

  FContext.AssertTrue((20)=(wCenter.Top), 'wCenter.Top');
  FContext.AssertTrue((20)=(wCenter.Left), 'wCenter.Left');
  FContext.AssertTrue((160)=(wCenter.ActualWidth), 'wCenter.ActualWidth');
  FContext.AssertTrue((160)=(wCenter.ActualHeight), 'wCenter.ActualHeight');

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

  FContext.AssertTrue((12)=(wNorth.Top), 'wNorth.Top with gap');
  FContext.AssertTrue((42)=(wWest.Top), 'wWest.Top with gap');
  FContext.AssertTrue((168)=(wSouth.Top), 'wSouth.Top with gap');
  FContext.AssertTrue((7)=(wWest.Left), 'wWest.Left with gap');

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

  FContext.AssertTrue((100)=(pref.W), 'PreferredWidth');
  FContext.AssertTrue((70)=(pref.H), 'PreferredHeight');

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

  FContext.AssertTrue((80)=(min.W), 'MinimumWidth');
  FContext.AssertTrue((55)=(min.H), 'MinimumHeight');

  container.Free;
end;

procedure RunTTestBorderLayoutTestLayout(AContext: TNXTestContext);
var lFixture: TTestBorderLayout;
begin
  lFixture:=TTestBorderLayout.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLayout';
    lFixture.TestLayout;
  finally lFixture.Free; end;
end;

procedure RunTTestBorderLayoutTestGaps(AContext: TNXTestContext);
var lFixture: TTestBorderLayout;
begin
  lFixture:=TTestBorderLayout.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestGaps';
    lFixture.TestGaps;
  finally lFixture.Free; end;
end;

procedure RunTTestBorderLayoutTestPreferredSize(AContext: TNXTestContext);
var lFixture: TTestBorderLayout;
begin
  lFixture:=TTestBorderLayout.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestPreferredSize';
    lFixture.TestPreferredSize;
  finally lFixture.Free; end;
end;

procedure RunTTestBorderLayoutTestMinimumSize(AContext: TNXTestContext);
var lFixture: TTestBorderLayout;
begin
  lFixture:=TTestBorderLayout.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMinimumSize';
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


initialization
  RegisterTests;

end.

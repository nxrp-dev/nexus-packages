unit tcfpgbase;

{$mode objfpc}{$h+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  //TestFramework,
  fpg_base,
  fpg_widget;

type

  TTestFPGRect = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    procedure CheckEqualsRect(const expected, actual: TfpgRect; const ErrorMsg: string= '');
  public
    procedure TestSetRect;
    procedure TestClear;
    procedure TestIsUnassigned;
    procedure TestIsRectEmpty;
    procedure TestBottom;
    procedure TestRight;
    procedure TestSetBottom;
    procedure TestUnionRect_Old_vs_New;
    procedure TestUnionRect;
    procedure TestInclusiveBoundaries;
    procedure TestPixelCoverage;
  end;

  TTestFPGWidget = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    procedure TestWidgetInclusiveBoundaries;
    procedure TestWidgetPixelCoverage;
    procedure TestWidgetAlignment;
  end;


procedure RegistertcfpgbaseTests(ARegistry: TNXTestRegistry);

implementation

uses
  fpg_main
  ;


{ TTestFPGRect }

procedure TTestFPGRect.CheckEqualsRect(const expected: TfpgRect;
               const actual: TfpgRect; const ErrorMsg: string = '');
begin
  TestContext.AssertTrue((Expected.Left)=(Actual.Left), ErrorMsg + ': Left');
  TestContext.AssertTrue((Expected.Top)=(Actual.Top), ErrorMsg + ': Top');
  TestContext.AssertTrue((Expected.Width)=(Actual.Width), ErrorMsg + ': Width');
  TestContext.AssertTrue((Expected.Height)=(Actual.Height), ErrorMsg + ': Height');
end;

procedure TTestFPGRect.TestSetRect;
var
  r1: TfpgRect;
begin
  r1.SetRect(10, 20, 30, 40);
  TestContext.AssertTrue((10)=(r1.Left), 'Failed on 1');
  TestContext.AssertTrue((20)=(r1.Top), 'Failed on 2');
  TestContext.AssertTrue((30)=(r1.Width), 'Failed on 3');
  TestContext.AssertTrue((40)=(r1.Height), 'Failed on 4');
end;

procedure TTestFPGRect.TestClear;
var
  r1: TfpgRect;
begin
  r1.SetRect(10, 20, 30, 40);
  r1.Clear;
  TestContext.AssertTrue((0)=(r1.Left), 'Failed on 1');
  TestContext.AssertTrue((0)=(r1.Top), 'Failed on 2');
  TestContext.AssertTrue((0)=(r1.Width), 'Failed on 3');
  TestContext.AssertTrue((0)=(r1.Height), 'Failed on 4');
end;

procedure TTestFPGRect.TestIsUnassigned;
var
  r1: TfpgRect;
begin
  r1.SetRect(10, 20, 30, 40);
  r1.Clear;
  TestContext.AssertTrue((0)=(r1.Left), 'Failed on 1');
  TestContext.AssertTrue((0)=(r1.Top), 'Failed on 2');
  TestContext.AssertTrue((0)=(r1.Width), 'Failed on 3');
  TestContext.AssertTrue((0)=(r1.Height), 'Failed on 4');
  TestContext.AssertTrue((true)=(r1.IsUnassigned), 'Failed on 5');
  r1.Clear;
  r1.Left := 1;
  TestContext.AssertTrue((false)=(r1.IsUnassigned), 'Failed on 6');
  r1.Clear;
  r1.Top := 1;
  TestContext.AssertTrue((false)=(r1.IsUnassigned), 'Failed on 7');
  r1.Clear;
  r1.Width := 1;
  TestContext.AssertTrue((false)=(r1.IsUnassigned), 'Failed on 8');
  r1.Clear;
  r1.Height := 1;
  TestContext.AssertTrue((false)=(r1.IsUnassigned), 'Failed on 9');
end;

procedure TTestFPGRect.TestIsRectEmpty;
var
  r1: TfpgRect;
begin
  r1.Clear;
  TestContext.AssertTrue((true)=(r1.IsRectEmpty), 'Failed on 1');
  r1.Clear;
  r1.Left := 1;
  TestContext.AssertTrue((true)=(r1.IsRectEmpty), 'Failed on 2');
  r1.Clear;
  r1.Top := 1;
  TestContext.AssertTrue((true)=(r1.IsRectEmpty), 'Failed on 3');
  r1.Clear;
  r1.Width := 1;
  // a rect with no height is not a rectangle
  TestContext.AssertTrue((true)=(r1.IsRectEmpty), 'Failed on 4');
  r1.Clear;
  r1.Height := 1;
  // a rect with no width is not a rectangle
  TestContext.AssertTrue((true)=(r1.IsRectEmpty), 'Failed on 5');
  r1.Clear;
  r1.Width := 1;
  r1.Height := 1;
  TestContext.AssertTrue((false)=(r1.IsRectEmpty), 'Failed on 6');
end;

{ See the TfpgRect API documentation for more details, if you don't understand. }
procedure TTestFPGRect.TestBottom;
var
  r1: TfpgRect;
begin
  r1.SetRect(10, 20, 30, 40);
  TestContext.AssertTrue((59)=(r1.Bottom), 'Failed on 1');
  r1.SetRect(0, 0, 1, 1);
  TestContext.AssertTrue((0)=(r1.Bottom), 'Failed on 2');
  r1.SetRect(0, 0, 2, 2);
  TestContext.AssertTrue((1)=(r1.Bottom), 'Failed on 3');
end;

{ See the TfpgRect API documentation for more details, if you don't understand. }
procedure TTestFPGRect.TestRight;
var
  r1: TfpgRect;
begin
  r1.SetRect(10, 20, 30, 40);
  TestContext.AssertTrue((39)=(r1.Right), 'Failed on 1');
  r1.SetRect(0, 0, 1, 1);
  TestContext.AssertTrue((0)=(r1.Right), 'Failed on 2');
  r1.SetRect(0, 0, 2, 2);
  TestContext.AssertTrue((1)=(r1.Right), 'Failed on 3');
end;

procedure TTestFPGRect.TestSetBottom;
var
  r1: TfpgRect;
begin
  r1.SetRect(0, 0, 0, 0);
  r1.SetBottom(5);
  TestContext.AssertTrue((5)=(r1.Bottom), 'Failed on 1');
  TestContext.AssertTrue((6)=(r1.Height), 'Failed on 2');
end;

procedure TTestFPGRect.TestUnionRect_Old_vs_New;
var
  r1, r2: TfpgRect;
  lResult: TfpgRect;
  lRef: TfpgRect;
begin
  r1.SetRect(10, 10, 50, 50);
  r2.SetRect(20, 20, 50, 50);
  r1.UnionRect(lResult, r2);
  lRef.SetRect(10, 10, 60, 60);
  CheckEqualsRect(lRef, lResult, 'Failed on 1');

  r1.UnionRect(lResult, r2);
  CheckEqualsRect(lRef, lResult, 'Failed on 2');
end;

procedure TTestFPGRect.TestUnionRect;
var
  r1, r2: TfpgRect;
  lRef: TfpgRect;
begin
  r1.SetRect(10, 10, 50, 50);
  r2.SetRect(20, 20, 50, 50);
  lRef.SetRect(10, 10, 60, 60);
  r1.UnionRect(r1, r2);
  CheckEqualsRect(lRef, r1, 'Failed on 1');
end;

procedure TTestFPGRect.TestInclusiveBoundaries;
var
  r: TfpgRect;
begin
  // fpGUI uses inclusive boundaries: Right = Left + Width - 1, Bottom = Top + Height - 1
  // This means a rect at (0,0) with size (200,200) occupies pixels [0,199] x [0,199]

  r.SetRect(0, 0, 200, 200);
  TestContext.AssertTrue((199)=(r.Right), 'Right should be Left + Width - 1');
  TestContext.AssertTrue((199)=(r.Bottom), 'Bottom should be Top + Height - 1');

  r.SetRect(10, 20, 50, 30);
  TestContext.AssertTrue((59)=(r.Right), 'Right = 10 + 50 - 1 = 59');
  TestContext.AssertTrue((49)=(r.Bottom), 'Bottom = 20 + 30 - 1 = 49');

  // Edge case: 1x1 rectangle
  r.SetRect(5, 5, 1, 1);
  TestContext.AssertTrue((5)=(r.Right), 'A 1x1 rect at (5,5) has Right=5');
  TestContext.AssertTrue((5)=(r.Bottom), 'A 1x1 rect at (5,5) has Bottom=5');
end;

procedure TTestFPGRect.TestPixelCoverage;
var
  r: TfpgRect;
  pixelCount: Integer;
begin
  // A rect should cover exactly Width * Height pixels

  r.SetRect(10, 20, 50, 30);
  // Horizontal coverage: pixels [10..59] = 50 pixels
  pixelCount := r.Right - r.Left + 1;
  TestContext.AssertTrue((50)=(pixelCount), 'Horizontal pixel count should equal Width');

  // Vertical coverage: pixels [20..49] = 30 pixels
  pixelCount := r.Bottom - r.Top + 1;
  TestContext.AssertTrue((30)=(pixelCount), 'Vertical pixel count should equal Height');

  // Total coverage
  pixelCount := (r.Right - r.Left + 1) * (r.Bottom - r.Top + 1);
  TestContext.AssertTrue((1500)=(pixelCount), 'Total pixels = Width * Height = 50 * 30 = 1500');
end;

{ TTestFPGWidget }

procedure TTestFPGWidget.TestWidgetInclusiveBoundaries;
var
  w: TfpgWidget;
begin
  fpgApplication.Initialize;

  w := TfpgWidget.Create(nil);
  try
    // Widget boundaries should follow the same inclusive rules as TfpgRect
    w.Width := 200;
    w.Height := 200;
    TestContext.AssertTrue((199)=(w.Right), 'Widget.Right should be Left + Width - 1');
    TestContext.AssertTrue((199)=(w.Bottom), 'Widget.Bottom should be Top + Height - 1');

    w.Left := 10;
    w.Top := 20;
    w.Width := 50;
    w.Height := 30;
    TestContext.AssertTrue((59)=(w.Right), 'Widget.Right = 10 + 50 - 1 = 59');
    TestContext.AssertTrue((49)=(w.Bottom), 'Widget.Bottom = 20 + 30 - 1 = 49');
  finally
    w.Free;
  end;
end;

procedure TTestFPGWidget.TestWidgetPixelCoverage;
var
  w: TfpgWidget;
  pixelCount: Integer;
begin
  fpgApplication.Initialize;

  w := TfpgWidget.Create(nil);
  try
    w.Width := 50;
    w.Height := 30;

    // Widget should occupy exactly Width * Height pixels with inclusive boundaries
    pixelCount := (w.Right - w.Left + 1) * (w.Bottom - w.Top + 1);
    TestContext.AssertTrue((1500)=(pixelCount), 'Widget should occupy Width * Height pixels');
  finally
    w.Free;
  end;
end;

procedure TTestFPGWidget.TestWidgetAlignment;
var
  container, widget: TfpgWidget;
begin
  fpgApplication.Initialize;

  container := TfpgWidget.Create(nil);
  try
    container.Width := 200;
    container.Height := 200;

    widget := TfpgWidget.Create(container);
    try
      // Test right-bottom alignment with inclusive boundaries
      // Container: [0, 199] x [0, 199]
      // 6px insets: usable area [6, 193] x [6, 193]
      // Widget 50x20 right-aligned: should end at pixel 193
      //   widget.Right = 193
      //   widget.Left = 193 - 50 + 1 = 144

      widget.Left := 144;
      widget.Top := 174;
      widget.Width := 50;
      widget.Height := 20;

      TestContext.AssertTrue((193)=(widget.Right), 'Widget right edge at container.Right - 6');
      TestContext.AssertTrue((193)=(widget.Bottom), 'Widget bottom edge at container.Bottom - 6');
      TestContext.AssertTrue((144)=(widget.Left), 'Widget.Left = (container.Right - 6) - Width + 1');
      TestContext.AssertTrue((174)=(widget.Top), 'Widget.Top = (container.Bottom - 6) - Height + 1');
    finally
      widget.Free;
    end;
  finally
    container.Free;
  end;
end;

constructor TTestFPGRect.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

constructor TTestFPGWidget.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestFPGRectTestSetRect(AContext: TNXTestContext);
var lFixture: TTestFPGRect;
begin
  lFixture:=TTestFPGRect.Create(AContext, 'TestSetRect');
  try
    lFixture.TestSetRect;
  finally lFixture.Free; end;
end;

procedure RunTTestFPGRectTestClear(AContext: TNXTestContext);
var lFixture: TTestFPGRect;
begin
  lFixture:=TTestFPGRect.Create(AContext, 'TestClear');
  try
    lFixture.TestClear;
  finally lFixture.Free; end;
end;

procedure RunTTestFPGRectTestIsUnassigned(AContext: TNXTestContext);
var lFixture: TTestFPGRect;
begin
  lFixture:=TTestFPGRect.Create(AContext, 'TestIsUnassigned');
  try
    lFixture.TestIsUnassigned;
  finally lFixture.Free; end;
end;

procedure RunTTestFPGRectTestIsRectEmpty(AContext: TNXTestContext);
var lFixture: TTestFPGRect;
begin
  lFixture:=TTestFPGRect.Create(AContext, 'TestIsRectEmpty');
  try
    lFixture.TestIsRectEmpty;
  finally lFixture.Free; end;
end;

procedure RunTTestFPGRectTestBottom(AContext: TNXTestContext);
var lFixture: TTestFPGRect;
begin
  lFixture:=TTestFPGRect.Create(AContext, 'TestBottom');
  try
    lFixture.TestBottom;
  finally lFixture.Free; end;
end;

procedure RunTTestFPGRectTestRight(AContext: TNXTestContext);
var lFixture: TTestFPGRect;
begin
  lFixture:=TTestFPGRect.Create(AContext, 'TestRight');
  try
    lFixture.TestRight;
  finally lFixture.Free; end;
end;

procedure RunTTestFPGRectTestSetBottom(AContext: TNXTestContext);
var lFixture: TTestFPGRect;
begin
  lFixture:=TTestFPGRect.Create(AContext, 'TestSetBottom');
  try
    lFixture.TestSetBottom;
  finally lFixture.Free; end;
end;

procedure RunTTestFPGRectTestUnionRect_Old_vs_New(AContext: TNXTestContext);
var lFixture: TTestFPGRect;
begin
  lFixture:=TTestFPGRect.Create(AContext, 'TestUnionRect_Old_vs_New');
  try
    lFixture.TestUnionRect_Old_vs_New;
  finally lFixture.Free; end;
end;

procedure RunTTestFPGRectTestUnionRect(AContext: TNXTestContext);
var lFixture: TTestFPGRect;
begin
  lFixture:=TTestFPGRect.Create(AContext, 'TestUnionRect');
  try
    lFixture.TestUnionRect;
  finally lFixture.Free; end;
end;

procedure RunTTestFPGRectTestInclusiveBoundaries(AContext: TNXTestContext);
var lFixture: TTestFPGRect;
begin
  lFixture:=TTestFPGRect.Create(AContext, 'TestInclusiveBoundaries');
  try
    lFixture.TestInclusiveBoundaries;
  finally lFixture.Free; end;
end;

procedure RunTTestFPGRectTestPixelCoverage(AContext: TNXTestContext);
var lFixture: TTestFPGRect;
begin
  lFixture:=TTestFPGRect.Create(AContext, 'TestPixelCoverage');
  try
    lFixture.TestPixelCoverage;
  finally lFixture.Free; end;
end;

procedure RunTTestFPGWidgetTestWidgetInclusiveBoundaries(AContext: TNXTestContext);
var lFixture: TTestFPGWidget;
begin
  lFixture:=TTestFPGWidget.Create(AContext, 'TestWidgetInclusiveBoundaries');
  try
    lFixture.TestWidgetInclusiveBoundaries;
  finally lFixture.Free; end;
end;

procedure RunTTestFPGWidgetTestWidgetPixelCoverage(AContext: TNXTestContext);
var lFixture: TTestFPGWidget;
begin
  lFixture:=TTestFPGWidget.Create(AContext, 'TestWidgetPixelCoverage');
  try
    lFixture.TestWidgetPixelCoverage;
  finally lFixture.Free; end;
end;

procedure RunTTestFPGWidgetTestWidgetAlignment(AContext: TNXTestContext);
var lFixture: TTestFPGWidget;
begin
  lFixture:=TTestFPGWidget.Create(AContext, 'TestWidgetAlignment');
  try
    lFixture.TestWidgetAlignment;
  finally lFixture.Free; end;
end;

procedure RegistertcfpgbaseTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcfpgbase.TTestFPGRect');
  lSuite.AddTest('TestSetRect', @RunTTestFPGRectTestSetRect);
  lSuite.AddTest('TestClear', @RunTTestFPGRectTestClear);
  lSuite.AddTest('TestIsUnassigned', @RunTTestFPGRectTestIsUnassigned);
  lSuite.AddTest('TestIsRectEmpty', @RunTTestFPGRectTestIsRectEmpty);
  lSuite.AddTest('TestBottom', @RunTTestFPGRectTestBottom);
  lSuite.AddTest('TestRight', @RunTTestFPGRectTestRight);
  lSuite.AddTest('TestSetBottom', @RunTTestFPGRectTestSetBottom);
  lSuite.AddTest('TestUnionRect_Old_vs_New', @RunTTestFPGRectTestUnionRect_Old_vs_New);
  lSuite.AddTest('TestUnionRect', @RunTTestFPGRectTestUnionRect);
  lSuite.AddTest('TestInclusiveBoundaries', @RunTTestFPGRectTestInclusiveBoundaries);
  lSuite.AddTest('TestPixelCoverage', @RunTTestFPGRectTestPixelCoverage);
  lSuite:=ARegistry.AddSuite('tcfpgbase.TTestFPGWidget');
  lSuite.AddTest('TestWidgetInclusiveBoundaries', @RunTTestFPGWidgetTestWidgetInclusiveBoundaries);
  lSuite.AddTest('TestWidgetPixelCoverage', @RunTTestFPGWidgetTestWidgetPixelCoverage);
  lSuite.AddTest('TestWidgetAlignment', @RunTTestFPGWidgetTestWidgetAlignment);
end;



end.

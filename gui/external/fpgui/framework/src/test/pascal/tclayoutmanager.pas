unit tclayoutmanager;

{$mode objfpc}{$h+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  fpg_base,
  fpg_main,
  fpg_widget,
  fpg_layouttypes,
  fpg_layoutmanager;

type
  TDummyLayoutManager = class(TfpgBaseLayoutManager)
  protected
    procedure DoLayout(AContainer: TfpgWidgetBase); override;
    function DoGetPreferredSize(AContainer: TfpgWidgetBase): TfpgSize; override;
  end;

  TTestLayoutManager = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    procedure TestAssignLayoutManager;
  end;

procedure RegistertclayoutmanagerTests(ARegistry: TNXTestRegistry);

implementation

{ TDummyLayoutManager }

procedure TDummyLayoutManager.DoLayout(AContainer: TfpgWidgetBase);
begin
end;

function TDummyLayoutManager.DoGetPreferredSize(AContainer: TfpgWidgetBase): TfpgSize;
begin
  Result.SetSize(100, 100);
end;

{ TTestLayoutManager }

procedure TTestLayoutManager.TestAssignLayoutManager;
var
  widget: TfpgWidget;
  lm: ILayoutManager;
begin
  widget := TfpgWidget.Create(nil);
  try
    lm := TDummyLayoutManager.Create as ILayoutManager;
    widget.LayoutManager := lm;
    TestContext.AssertTrue(Assigned(widget.LayoutManager), 'LayoutManager should be assigned');
    TestContext.AssertTrue(widget.LayoutManager = lm, 'Assigned LayoutManager should be the same instance');
  finally
    widget.Free;
  end;
end;

constructor TTestLayoutManager.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestLayoutManagerTestAssignLayoutManager(AContext: TNXTestContext);
var lFixture: TTestLayoutManager;
begin
  lFixture:=TTestLayoutManager.Create(AContext, 'TestAssignLayoutManager');
  try
    lFixture.TestAssignLayoutManager;
  finally lFixture.Free; end;
end;

procedure RegistertclayoutmanagerTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tclayoutmanager.TTestLayoutManager');
  lSuite.AddTest('TestAssignLayoutManager', @RunTTestLayoutManagerTestAssignLayoutManager);
end;


end.

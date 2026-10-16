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
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  public
    procedure TestAssignLayoutManager;
  end;

procedure RegisterTests;

procedure RegistertclayoutmanagerTests(ARegistry: TNXTestRegistry);

implementation

procedure RegisterTests;
begin
  
end;

{ TDummyLayoutManager }

procedure TDummyLayoutManager.DoLayout(AContainer: TfpgWidgetBase);
begin
  // Do nothing
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
    FContext.AssertTrue(Assigned(widget.LayoutManager), 'LayoutManager should be assigned');
    FContext.AssertTrue(widget.LayoutManager = lm, 'Assigned LayoutManager should be the same instance');
  finally
    widget.Free;
  end;
end;

procedure RunTTestLayoutManagerTestAssignLayoutManager(AContext: TNXTestContext);
var lFixture: TTestLayoutManager;
begin
  lFixture:=TTestLayoutManager.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAssignLayoutManager';
    lFixture.TestAssignLayoutManager;
  finally lFixture.Free; end;
end;

procedure RegistertclayoutmanagerTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tclayoutmanager.TTestLayoutManager');
  lSuite.AddTest('TestAssignLayoutManager', @RunTTestLayoutManagerTestAssignLayoutManager);
end;


initialization
  RegisterTests;

end.

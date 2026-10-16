unit tcmig_resizeconstraint;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, Math,
  fpg_mig_resizeconstraint;

type
  TTestMigResizeConstraint = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    procedure TestDefaultConstructor;
    procedure TestParameterizedConstructor;
  end;

procedure RegistertcmigresizeconstraintTests(ARegistry: TNXTestRegistry);

implementation

{ TTestMigResizeConstraint }

procedure TTestMigResizeConstraint.TestDefaultConstructor;
var
  rc: TfpgMigResizeConstraint;
begin
  rc := TfpgMigResizeConstraint.Create;
  try
    TestContext.AssertTrue(IsNaN(rc.Grow), 'Default Grow should be NaN');
    TestContext.AssertTrue((100)=(rc.GrowPrio), 'Default GrowPrio should be 100');
    TestContext.AssertTrue(Abs((100.0)-(rc.Shrink))<=(0.001), 'Default Shrink should be 100.0');
    TestContext.AssertTrue((100)=(rc.ShrinkPrio), 'Default ShrinkPrio should be 100');
  finally
    rc.Free;
  end;
end;

procedure TTestMigResizeConstraint.TestParameterizedConstructor;
var
  rc: TfpgMigResizeConstraint;
  nanFloat: Single;
begin
  nanFloat := NaN;
  rc := TfpgMigResizeConstraint.Create(50, 50.0, 150, nanFloat);
  try
    TestContext.AssertTrue(IsNaN(rc.Grow), 'Grow should be NaN');
    TestContext.AssertTrue((150)=(rc.GrowPrio), 'GrowPrio should be 150');
    TestContext.AssertTrue(Abs((50.0)-(rc.Shrink))<=(0.001), 'Shrink should be 50.0');
    TestContext.AssertTrue((50)=(rc.ShrinkPrio), 'ShrinkPrio should be 50');
  finally
    rc.Free;
  end;
end;


constructor TTestMigResizeConstraint.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestMigResizeConstraintTestDefaultConstructor(AContext: TNXTestContext);
var lFixture: TTestMigResizeConstraint;
begin
  lFixture:=TTestMigResizeConstraint.Create(AContext, 'TestDefaultConstructor');
  try
    lFixture.TestDefaultConstructor;
  finally lFixture.Free; end;
end;

procedure RunTTestMigResizeConstraintTestParameterizedConstructor(AContext: TNXTestContext);
var lFixture: TTestMigResizeConstraint;
begin
  lFixture:=TTestMigResizeConstraint.Create(AContext, 'TestParameterizedConstructor');
  try
    lFixture.TestParameterizedConstructor;
  finally lFixture.Free; end;
end;

procedure RegistertcmigresizeconstraintTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcmig_resizeconstraint.TTestMigResizeConstraint');
  lSuite.AddTest('TestDefaultConstructor', @RunTTestMigResizeConstraintTestDefaultConstructor);
  lSuite.AddTest('TestParameterizedConstructor', @RunTTestMigResizeConstraintTestParameterizedConstructor);
end;

end.

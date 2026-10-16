unit tcmig_resizeconstraint;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, Math,
  fpg_mig_resizeconstraint;

type
  TTestMigResizeConstraint = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
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
    FContext.AssertTrue(IsNaN(rc.Grow), 'Default Grow should be NaN');
    FContext.AssertTrue((100)=(rc.GrowPrio), 'Default GrowPrio should be 100');
    FContext.AssertTrue(Abs((100.0)-(rc.Shrink))<=(0.001), 'Default Shrink should be 100.0');
    FContext.AssertTrue((100)=(rc.ShrinkPrio), 'Default ShrinkPrio should be 100');
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
    FContext.AssertTrue(IsNaN(rc.Grow), 'Grow should be NaN');
    FContext.AssertTrue((150)=(rc.GrowPrio), 'GrowPrio should be 150');
    FContext.AssertTrue(Abs((50.0)-(rc.Shrink))<=(0.001), 'Shrink should be 50.0');
    FContext.AssertTrue((50)=(rc.ShrinkPrio), 'ShrinkPrio should be 50');
  finally
    rc.Free;
  end;
end;


procedure RunTTestMigResizeConstraintTestDefaultConstructor(AContext: TNXTestContext);
var lFixture: TTestMigResizeConstraint;
begin
  lFixture:=TTestMigResizeConstraint.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDefaultConstructor';
    lFixture.TestDefaultConstructor;
  finally lFixture.Free; end;
end;

procedure RunTTestMigResizeConstraintTestParameterizedConstructor(AContext: TNXTestContext);
var lFixture: TTestMigResizeConstraint;
begin
  lFixture:=TTestMigResizeConstraint.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParameterizedConstructor';
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

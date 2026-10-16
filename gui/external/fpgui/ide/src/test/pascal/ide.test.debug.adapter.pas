{
    fpGUI IDE - Debug Adapter Tests

    Tests for TIDEDebugAdapter state machine transitions.
}
unit ide.test.debug.adapter;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  ide.debug.adapter;

type

  { TTestDebugAdapterState }

  TTestDebugAdapterState = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  public
    procedure TestInitialStateIsIdle;
    procedure TestStartSessionWithInvalidBinary;
    procedure TestEndSessionResetsState;
    procedure TestRunRequiresStartingOrPaused;
    procedure TestContinueRequiresPaused;
    procedure TestStepRequiresPaused;
  end;

procedure RegisteridetestdebugadapterTests(ARegistry: TNXTestRegistry);

implementation

{ TTestDebugAdapterState }

procedure TTestDebugAdapterState.TestInitialStateIsIdle;
var
  adapter: TIDEDebugAdapter;
begin
  adapter := TIDEDebugAdapter.Create;
  try
    FContext.AssertTrue(adapter.State = idsIdle, 'initial state should be idsIdle');
    FContext.AssertTrue(adapter.Engine = nil, 'engine should be nil before session');
  finally
    adapter.Free;
  end;
end;

procedure TTestDebugAdapterState.TestStartSessionWithInvalidBinary;
var
  adapter: TIDEDebugAdapter;
  ok: Boolean;
begin
  adapter := TIDEDebugAdapter.Create;
  try
    ok := adapter.StartSession('/nonexistent/binary');
    FContext.AssertTrue(not (ok), 'should fail for nonexistent binary');
    FContext.AssertTrue(adapter.State = idsIdle, 'state should remain idle');
    FContext.AssertTrue(adapter.Engine = nil, 'engine should be nil after failed start');
  finally
    adapter.Free;
  end;
end;

procedure TTestDebugAdapterState.TestEndSessionResetsState;
var
  adapter: TIDEDebugAdapter;
begin
  adapter := TIDEDebugAdapter.Create;
  try
    { Even without a session, EndSession should not crash }
    adapter.EndSession;
    FContext.AssertTrue(adapter.State = idsIdle, 'state should be idle after EndSession');
  finally
    adapter.Free;
  end;
end;

procedure TTestDebugAdapterState.TestRunRequiresStartingOrPaused;
var
  adapter: TIDEDebugAdapter;
begin
  adapter := TIDEDebugAdapter.Create;
  try
    { Run from idle should be a no-op (no crash) }
    adapter.Run;
    FContext.AssertTrue(adapter.State = idsIdle, 'state should remain idle');
  finally
    adapter.Free;
  end;
end;

procedure TTestDebugAdapterState.TestContinueRequiresPaused;
var
  adapter: TIDEDebugAdapter;
begin
  adapter := TIDEDebugAdapter.Create;
  try
    adapter.Continue;
    FContext.AssertTrue(adapter.State = idsIdle, 'state should remain idle');
  finally
    adapter.Free;
  end;
end;

procedure TTestDebugAdapterState.TestStepRequiresPaused;
var
  adapter: TIDEDebugAdapter;
begin
  adapter := TIDEDebugAdapter.Create;
  try
    adapter.StepInto;
    FContext.AssertTrue(adapter.State = idsIdle, 'state should remain idle after StepInto');
    adapter.StepOver;
    FContext.AssertTrue(adapter.State = idsIdle, 'state should remain idle after StepOver');
    adapter.StepLine;
    FContext.AssertTrue(adapter.State = idsIdle, 'state should remain idle after StepLine');
  finally
    adapter.Free;
  end;
end;



procedure RunTTestDebugAdapterStateTestInitialStateIsIdle(AContext: TNXTestContext);
var lFixture: TTestDebugAdapterState;
begin
  lFixture:=TTestDebugAdapterState.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInitialStateIsIdle';
    lFixture.TestInitialStateIsIdle;
  finally lFixture.Free; end;
end;

procedure RunTTestDebugAdapterStateTestStartSessionWithInvalidBinary(AContext: TNXTestContext);
var lFixture: TTestDebugAdapterState;
begin
  lFixture:=TTestDebugAdapterState.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestStartSessionWithInvalidBinary';
    lFixture.TestStartSessionWithInvalidBinary;
  finally lFixture.Free; end;
end;

procedure RunTTestDebugAdapterStateTestEndSessionResetsState(AContext: TNXTestContext);
var lFixture: TTestDebugAdapterState;
begin
  lFixture:=TTestDebugAdapterState.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEndSessionResetsState';
    lFixture.TestEndSessionResetsState;
  finally lFixture.Free; end;
end;

procedure RunTTestDebugAdapterStateTestRunRequiresStartingOrPaused(AContext: TNXTestContext);
var lFixture: TTestDebugAdapterState;
begin
  lFixture:=TTestDebugAdapterState.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRunRequiresStartingOrPaused';
    lFixture.TestRunRequiresStartingOrPaused;
  finally lFixture.Free; end;
end;

procedure RunTTestDebugAdapterStateTestContinueRequiresPaused(AContext: TNXTestContext);
var lFixture: TTestDebugAdapterState;
begin
  lFixture:=TTestDebugAdapterState.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestContinueRequiresPaused';
    lFixture.TestContinueRequiresPaused;
  finally lFixture.Free; end;
end;

procedure RunTTestDebugAdapterStateTestStepRequiresPaused(AContext: TNXTestContext);
var lFixture: TTestDebugAdapterState;
begin
  lFixture:=TTestDebugAdapterState.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestStepRequiresPaused';
    lFixture.TestStepRequiresPaused;
  finally lFixture.Free; end;
end;

procedure RegisteridetestdebugadapterTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.debug.adapter.TTestDebugAdapterState');
  lSuite.AddTest('TestInitialStateIsIdle', @RunTTestDebugAdapterStateTestInitialStateIsIdle);
  lSuite.AddTest('TestStartSessionWithInvalidBinary', @RunTTestDebugAdapterStateTestStartSessionWithInvalidBinary);
  lSuite.AddTest('TestEndSessionResetsState', @RunTTestDebugAdapterStateTestEndSessionResetsState);
  lSuite.AddTest('TestRunRequiresStartingOrPaused', @RunTTestDebugAdapterStateTestRunRequiresStartingOrPaused);
  lSuite.AddTest('TestContinueRequiresPaused', @RunTTestDebugAdapterStateTestContinueRequiresPaused);
  lSuite.AddTest('TestStepRequiresPaused', @RunTTestDebugAdapterStateTestStepRequiresPaused);
end;

end.

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
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
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
    TestContext.AssertTrue(adapter.State = idsIdle, 'initial state should be idsIdle');
    TestContext.AssertTrue(adapter.Engine = nil, 'engine should be nil before session');
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
    TestContext.AssertTrue(not (ok), 'should fail for nonexistent binary');
    TestContext.AssertTrue(adapter.State = idsIdle, 'state should remain idle');
    TestContext.AssertTrue(adapter.Engine = nil, 'engine should be nil after failed start');
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
    TestContext.AssertTrue(adapter.State = idsIdle, 'state should be idle after EndSession');
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
    TestContext.AssertTrue(adapter.State = idsIdle, 'state should remain idle');
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
    TestContext.AssertTrue(adapter.State = idsIdle, 'state should remain idle');
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
    TestContext.AssertTrue(adapter.State = idsIdle, 'state should remain idle after StepInto');
    adapter.StepOver;
    TestContext.AssertTrue(adapter.State = idsIdle, 'state should remain idle after StepOver');
    adapter.StepLine;
    TestContext.AssertTrue(adapter.State = idsIdle, 'state should remain idle after StepLine');
  finally
    adapter.Free;
  end;
end;



constructor TTestDebugAdapterState.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestDebugAdapterStateTestInitialStateIsIdle(AContext: TNXTestContext);
var lFixture: TTestDebugAdapterState;
begin
  lFixture:=TTestDebugAdapterState.Create(AContext, 'TestInitialStateIsIdle');
  try
    lFixture.TestInitialStateIsIdle;
  finally lFixture.Free; end;
end;

procedure RunTTestDebugAdapterStateTestStartSessionWithInvalidBinary(AContext: TNXTestContext);
var lFixture: TTestDebugAdapterState;
begin
  lFixture:=TTestDebugAdapterState.Create(AContext, 'TestStartSessionWithInvalidBinary');
  try
    lFixture.TestStartSessionWithInvalidBinary;
  finally lFixture.Free; end;
end;

procedure RunTTestDebugAdapterStateTestEndSessionResetsState(AContext: TNXTestContext);
var lFixture: TTestDebugAdapterState;
begin
  lFixture:=TTestDebugAdapterState.Create(AContext, 'TestEndSessionResetsState');
  try
    lFixture.TestEndSessionResetsState;
  finally lFixture.Free; end;
end;

procedure RunTTestDebugAdapterStateTestRunRequiresStartingOrPaused(AContext: TNXTestContext);
var lFixture: TTestDebugAdapterState;
begin
  lFixture:=TTestDebugAdapterState.Create(AContext, 'TestRunRequiresStartingOrPaused');
  try
    lFixture.TestRunRequiresStartingOrPaused;
  finally lFixture.Free; end;
end;

procedure RunTTestDebugAdapterStateTestContinueRequiresPaused(AContext: TNXTestContext);
var lFixture: TTestDebugAdapterState;
begin
  lFixture:=TTestDebugAdapterState.Create(AContext, 'TestContinueRequiresPaused');
  try
    lFixture.TestContinueRequiresPaused;
  finally lFixture.Free; end;
end;

procedure RunTTestDebugAdapterStateTestStepRequiresPaused(AContext: TNXTestContext);
var lFixture: TTestDebugAdapterState;
begin
  lFixture:=TTestDebugAdapterState.Create(AContext, 'TestStepRequiresPaused');
  try
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

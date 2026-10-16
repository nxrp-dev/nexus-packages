unit tctimer;

{$mode objfpc}{$h+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  fpg_base,
  fpg_main;

type

  TTestFPGTimer = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FSelfDestructTimer: TfpgTimer;
    FCallbackFired: Boolean;
    procedure SelfDestructCallback(Sender: TObject);
  public
    procedure TestResetAllTimers_WithNilEntry;
    procedure TestCheckTimers_TimerSelfDestruct;
  end;


procedure RegisterTests;


procedure RegistertctimerTests(ARegistry: TNXTestRegistry);

implementation


procedure RegisterTests;
begin
  
end;


{ TTestFPGTimer }

procedure TTestFPGTimer.SelfDestructCallback(Sender: TObject);
begin
  FCallbackFired := True;
  // Timer destroys itself during its own callback
  FSelfDestructTimer.Free;
  FSelfDestructTimer := nil;
end;

procedure TTestFPGTimer.TestResetAllTimers_WithNilEntry;
var
  t: TfpgTimer;
begin
  // Create a timer, then destroy it. The destructor sets fpgTimers[i] := nil
  // rather than removing the entry. fpgResetAllTimers must handle nil entries
  // without crashing.
  t := TfpgTimer.Create(1000);
  t.Free;

  // This should not raise an access violation
  fpgResetAllTimers;
end;

procedure TTestFPGTimer.TestCheckTimers_TimerSelfDestruct;
begin
  // Create a timer whose callback frees the timer itself.
  // After the callback, fpgCheckTimers must not access the freed object.
  FCallbackFired := False;
  FSelfDestructTimer := TfpgTimer.Create(1);
  FSelfDestructTimer.OnTimer := @SelfDestructCallback;
  FSelfDestructTimer.Enabled := True;

  // Wait long enough for the timer to be past due
  Sleep(50);

  // This should not raise an access violation
  fpgCheckTimers;

  FContext.AssertTrue(FCallbackFired, 'Timer callback should have fired');
end;

procedure RunTTestFPGTimerTestResetAllTimers_WithNilEntry(AContext: TNXTestContext);
var lFixture: TTestFPGTimer;
begin
  lFixture:=TTestFPGTimer.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestResetAllTimers_WithNilEntry';
    lFixture.TestResetAllTimers_WithNilEntry;
  finally lFixture.Free; end;
end;

procedure RunTTestFPGTimerTestCheckTimers_TimerSelfDestruct(AContext: TNXTestContext);
var lFixture: TTestFPGTimer;
begin
  lFixture:=TTestFPGTimer.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCheckTimers_TimerSelfDestruct';
    lFixture.TestCheckTimers_TimerSelfDestruct;
  finally lFixture.Free; end;
end;

procedure RegistertctimerTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tctimer.TTestFPGTimer');
  lSuite.AddTest('TestResetAllTimers_WithNilEntry', @RunTTestFPGTimerTestResetAllTimers_WithNilEntry);
  lSuite.AddTest('TestCheckTimers_TimerSelfDestruct', @RunTTestFPGTimerTestCheckTimers_TimerSelfDestruct);
end;


initialization
  RegisterTests;

end.

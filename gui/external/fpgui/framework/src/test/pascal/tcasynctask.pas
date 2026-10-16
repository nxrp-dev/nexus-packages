unit tcasynctask;

{$mode objfpc}{$h+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  fpg_base,
  fpg_main,
  fpg_async;

type

  { Test async task that sums numbers and publishes progress }
  TTestSumTask = class(TfpgAsyncTask)
  private
    FFrom: Integer;
    FTo: Integer;
    FResult: Integer;
  protected
    procedure Execute; override;
  public
    ProgressLines: TStringList;
    CompleteCalled: Boolean;
    ErrorMessage: string;
    procedure OnProgress(const ALine: string); override;
    procedure OnComplete; override;
    procedure OnError(const AMessage: string); override;
    constructor Create(AFrom, ATo: Integer);
    destructor Destroy; override;
    property SumResult: Integer read FResult;
  end;

  { Test async task that raises an exception }
  TTestFailingTask = class(TfpgAsyncTask)
  protected
    procedure Execute; override;
  public
    CompleteCalled: Boolean;
    ErrorMessage: string;
    procedure OnComplete; override;
    procedure OnError(const AMessage: string); override;
    constructor Create;
  end;

  { TTestAsyncTask }

  TTestAsyncTask = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  public
    { Synchronous path }
    procedure TestRunSynchronous_ExecutesAndCompletes;
    procedure TestRunSynchronous_PublishProgressDelivered;
    procedure TestRunSynchronous_ErrorCallsOnError;
    { Threaded path via Start }
    procedure TestStart_CompleteFiredOnMainThread;
    procedure TestStart_ProgressDeliveredViaThread;
    procedure TestStart_ErrorFiredOnMainThread;
  end;

  { TTestInvokeLater }

  TTestInvokeLater = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  public
    procedure TestInvokeLater_ExecutesOnMainThread;
  end;


procedure RegisterTests;


procedure RegistertcasynctaskTests(ARegistry: TNXTestRegistry);

implementation


procedure RegisterTests;
begin
  
  
end;


{ TTestSumTask }

constructor TTestSumTask.Create(AFrom, ATo: Integer);
begin
  inherited Create;
  FFrom := AFrom;
  FTo := ATo;
  FResult := 0;
  ProgressLines := TStringList.Create;
  CompleteCalled := False;
  ErrorMessage := '';
end;

destructor TTestSumTask.Destroy;
begin
  ProgressLines.Free;
  inherited Destroy;
end;

procedure TTestSumTask.Execute;
var
  i: Integer;
begin
  FResult := 0;
  for i := FFrom to FTo do
  begin
    FResult := FResult + i;
    if (i mod 10) = 0 then
      PublishProgress('Sum at ' + IntToStr(i) + ' = ' + IntToStr(FResult));
  end;
end;

procedure TTestSumTask.OnProgress(const ALine: string);
begin
  ProgressLines.Add(ALine);
end;

procedure TTestSumTask.OnComplete;
begin
  CompleteCalled := True;
end;

procedure TTestSumTask.OnError(const AMessage: string);
begin
  ErrorMessage := AMessage;
end;


{ TTestFailingTask }

constructor TTestFailingTask.Create;
begin
  inherited Create;
  CompleteCalled := False;
  ErrorMessage := '';
end;

procedure TTestFailingTask.Execute;
begin
  raise Exception.Create('deliberate test failure');
end;

procedure TTestFailingTask.OnComplete;
begin
  CompleteCalled := True;
end;

procedure TTestFailingTask.OnError(const AMessage: string);
begin
  ErrorMessage := AMessage;
end;


{ TTestAsyncTask — synchronous path }

procedure TTestAsyncTask.TestRunSynchronous_ExecutesAndCompletes;
var
  task: TTestSumTask;
begin
  task := TTestSumTask.Create(1, 100);
  try
    task.RunSynchronous;
    FContext.AssertTrue(task.CompleteCalled, 'OnComplete should have been called');
    FContext.AssertTrue((5050)=(task.SumResult), 'Sum 1..100 = 5050');
    FContext.AssertTrue(('')=(task.ErrorMessage), 'No errors');
  finally
    task.Free;
  end;
end;

procedure TTestAsyncTask.TestRunSynchronous_PublishProgressDelivered;
var
  task: TTestSumTask;
begin
  task := TTestSumTask.Create(1, 50);
  try
    task.RunSynchronous;
    FContext.AssertTrue((5)=(task.ProgressLines.Count), 'Should have 5 progress lines');
    FContext.AssertTrue(Pos('10', task.ProgressLines[0]) > 0, 'First progress line should mention 10');
  finally
    task.Free;
  end;
end;

procedure TTestAsyncTask.TestRunSynchronous_ErrorCallsOnError;
var
  task: TTestFailingTask;
begin
  task := TTestFailingTask.Create;
  try
    task.RunSynchronous;
    FContext.AssertTrue(not (task.CompleteCalled), 'OnComplete should NOT be called on error');
    FContext.AssertTrue(Pos('deliberate test failure', task.ErrorMessage) > 0, 'OnError should have the exception message');
  finally
    task.Free;
  end;
end;

{ TTestAsyncTask — threaded path via Start }

procedure TTestAsyncTask.TestStart_CompleteFiredOnMainThread;
var
  task: TTestSumTask;
  waited: Integer;
begin
  task := TTestSumTask.Create(1, 100);
  try
    task.Start;
    { Poll CheckSynchronize to process the OnTerminate callback.
      The wake channel ensures CheckSynchronize fires promptly. }
    waited := 0;
    while (not task.CompleteCalled) and (waited < 2000) do
    begin
      CheckSynchronize(10);
      Sleep(10);
      Inc(waited, 10);
    end;
    FContext.AssertTrue(task.CompleteCalled, 'OnComplete should fire via Start path');
    FContext.AssertTrue((5050)=(task.SumResult), 'Sum 1..100 = 5050 via threaded path');
  finally
    task.Free;
  end;
end;

procedure TTestAsyncTask.TestStart_ProgressDeliveredViaThread;
var
  task: TTestSumTask;
  waited: Integer;
begin
  task := TTestSumTask.Create(1, 50);
  try
    task.Start;
    waited := 0;
    while (not task.CompleteCalled) and (waited < 2000) do
    begin
      CheckSynchronize(10);
      Sleep(10);
      Inc(waited, 10);
    end;
    FContext.AssertTrue(task.CompleteCalled, 'Task should have completed');
    FContext.AssertTrue((5)=(task.ProgressLines.Count), 'Should have 5 progress lines via thread');
  finally
    task.Free;
  end;
end;

procedure TTestAsyncTask.TestStart_ErrorFiredOnMainThread;
var
  task: TTestFailingTask;
  waited: Integer;
begin
  task := TTestFailingTask.Create;
  try
    task.Start;
    waited := 0;
    while (task.ErrorMessage = '') and (not task.CompleteCalled) and (waited < 2000) do
    begin
      CheckSynchronize(10);
      Sleep(10);
      Inc(waited, 10);
    end;
    FContext.AssertTrue(not (task.CompleteCalled), 'OnComplete should NOT fire on error via Start');
    FContext.AssertTrue(Pos('deliberate test failure', task.ErrorMessage) > 0, 'OnError should fire via Start path');
  finally
    task.Free;
  end;
end;


{ TTestInvokeLater }

var
  GInvokeResult: Integer;

procedure SetInvokeResult;
begin
  GInvokeResult := 42;
end;

procedure TTestInvokeLater.TestInvokeLater_ExecutesOnMainThread;
begin
  GInvokeResult := 0;
  fpgInvokeLater(@SetInvokeResult);
  { Since we're on the main thread, process pending messages to
    trigger the invoke }
  fpgApplication.ProcessMessages;
  FContext.AssertTrue((42)=(GInvokeResult), 'fpgInvokeLater should have executed the proc');
end;

procedure RunTTestAsyncTaskTestRunSynchronous_ExecutesAndCompletes(AContext: TNXTestContext);
var lFixture: TTestAsyncTask;
begin
  lFixture:=TTestAsyncTask.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRunSynchronous_ExecutesAndCompletes';
    lFixture.TestRunSynchronous_ExecutesAndCompletes;
  finally lFixture.Free; end;
end;

procedure RunTTestAsyncTaskTestRunSynchronous_PublishProgressDelivered(AContext: TNXTestContext);
var lFixture: TTestAsyncTask;
begin
  lFixture:=TTestAsyncTask.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRunSynchronous_PublishProgressDelivered';
    lFixture.TestRunSynchronous_PublishProgressDelivered;
  finally lFixture.Free; end;
end;

procedure RunTTestAsyncTaskTestRunSynchronous_ErrorCallsOnError(AContext: TNXTestContext);
var lFixture: TTestAsyncTask;
begin
  lFixture:=TTestAsyncTask.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRunSynchronous_ErrorCallsOnError';
    lFixture.TestRunSynchronous_ErrorCallsOnError;
  finally lFixture.Free; end;
end;

procedure RunTTestAsyncTaskTestStart_CompleteFiredOnMainThread(AContext: TNXTestContext);
var lFixture: TTestAsyncTask;
begin
  lFixture:=TTestAsyncTask.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestStart_CompleteFiredOnMainThread';
    lFixture.TestStart_CompleteFiredOnMainThread;
  finally lFixture.Free; end;
end;

procedure RunTTestAsyncTaskTestStart_ProgressDeliveredViaThread(AContext: TNXTestContext);
var lFixture: TTestAsyncTask;
begin
  lFixture:=TTestAsyncTask.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestStart_ProgressDeliveredViaThread';
    lFixture.TestStart_ProgressDeliveredViaThread;
  finally lFixture.Free; end;
end;

procedure RunTTestAsyncTaskTestStart_ErrorFiredOnMainThread(AContext: TNXTestContext);
var lFixture: TTestAsyncTask;
begin
  lFixture:=TTestAsyncTask.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestStart_ErrorFiredOnMainThread';
    lFixture.TestStart_ErrorFiredOnMainThread;
  finally lFixture.Free; end;
end;

procedure RunTTestInvokeLaterTestInvokeLater_ExecutesOnMainThread(AContext: TNXTestContext);
var lFixture: TTestInvokeLater;
begin
  lFixture:=TTestInvokeLater.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInvokeLater_ExecutesOnMainThread';
    lFixture.TestInvokeLater_ExecutesOnMainThread;
  finally lFixture.Free; end;
end;

procedure RegistertcasynctaskTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcasynctask.TTestAsyncTask');
  lSuite.AddTest('TestRunSynchronous_ExecutesAndCompletes', @RunTTestAsyncTaskTestRunSynchronous_ExecutesAndCompletes);
  lSuite.AddTest('TestRunSynchronous_PublishProgressDelivered', @RunTTestAsyncTaskTestRunSynchronous_PublishProgressDelivered);
  lSuite.AddTest('TestRunSynchronous_ErrorCallsOnError', @RunTTestAsyncTaskTestRunSynchronous_ErrorCallsOnError);
  lSuite.AddTest('TestStart_CompleteFiredOnMainThread', @RunTTestAsyncTaskTestStart_CompleteFiredOnMainThread);
  lSuite.AddTest('TestStart_ProgressDeliveredViaThread', @RunTTestAsyncTaskTestStart_ProgressDeliveredViaThread);
  lSuite.AddTest('TestStart_ErrorFiredOnMainThread', @RunTTestAsyncTaskTestStart_ErrorFiredOnMainThread);
  lSuite:=ARegistry.AddSuite('tcasynctask.TTestInvokeLater');
  lSuite.AddTest('TestInvokeLater_ExecutesOnMainThread', @RunTTestInvokeLaterTestInvokeLater_ExecutesOnMainThread);
end;



initialization
  RegisterTests;

end.

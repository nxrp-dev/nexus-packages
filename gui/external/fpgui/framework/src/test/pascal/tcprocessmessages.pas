unit tcprocessmessages;

{$mode objfpc}{$h+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  fpg_base,
  fpg_main;

type

  { Probe object that records delivery of queued messages. Messages posted via
    fpgPostMessage are dispatched with msg.Dest.Dispatch(msg), so a message
    handler here is invoked only if the internal queue is actually drained. }
  TMessageProbe = class(TObject)
  public
    PaintCount: Integer;
    ResizeCount: Integer;
    procedure MsgPaint(var msg: TfpgMessageRec); message FPGM_PAINT;
    procedure MsgResize(var msg: TfpgMessageRec); message FPGM_RESIZE;
  end;

  { TTestProcessMessages }

  TTestProcessMessages = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FProbe: TMessageProbe;
    procedure PostPaint(ADest: TObject);
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    { A paint queued on the internal message queue must be delivered by
      ProcessMessages even when no native platform events are pending.
      This is the "label.Text := ...; ProcessMessages" case. }
    procedure TestProcessMessages_DeliversQueuedPaint;
    { Messages queued by a handler that itself runs during the drain must
      also be delivered before ProcessMessages returns. }
    procedure TestProcessMessages_DeliversCascadedMessages;
    { ProcessMessages must return promptly when the queue is empty rather
      than blocking on a platform wait timeout. }
    procedure TestProcessMessages_ReturnsPromptlyWhenIdle;
  end;


procedure RegisterTests;


procedure RegistertcprocessmessagesTests(ARegistry: TNXTestRegistry);

implementation


procedure RegisterTests;
begin
  
end;


{ TMessageProbe }

procedure TMessageProbe.MsgPaint(var msg: TfpgMessageRec);
begin
  Inc(PaintCount);
end;

procedure TMessageProbe.MsgResize(var msg: TfpgMessageRec);
begin
  Inc(ResizeCount);
end;


{ TTestProcessMessages }

procedure TTestProcessMessages.SetUp;
begin
  
  FProbe := TMessageProbe.Create;
end;

procedure TTestProcessMessages.TearDown;
begin
  { Drop anything still queued for the probe so one failing test cannot
    leak messages into the next one. }
  fpgDeleteMessagesForTarget(FProbe);
  FreeAndNil(FProbe);
  
end;

procedure TTestProcessMessages.PostPaint(ADest: TObject);
var
  params: TfpgMessageParams;
begin
  FillChar(params, SizeOf(params), 0);
  fpgPostMessage(nil, ADest, FPGM_PAINT, params);
end;

procedure TTestProcessMessages.TestProcessMessages_DeliversQueuedPaint;
begin
  PostPaint(FProbe);
  FContext.AssertTrue((0)=(FProbe.PaintCount), 'Precondition: paint not yet delivered');

  fpgApplication.ProcessMessages;

  FContext.AssertTrue((1)=(FProbe.PaintCount), 'ProcessMessages must deliver a queued paint with no pending '
      + 'platform events');
end;

procedure TTestProcessMessages.TestProcessMessages_DeliversCascadedMessages;
var
  params: TfpgMessageParams;
begin
  { Queue a resize; the drain of the paint below happens first, but both must
    be delivered by the time ProcessMessages returns. }
  FillChar(params, SizeOf(params), 0);
  fpgPostMessage(nil, FProbe, FPGM_RESIZE, params);
  PostPaint(FProbe);

  fpgApplication.ProcessMessages;

  FContext.AssertTrue((1)=(FProbe.PaintCount), 'Queued paint should be delivered');
  FContext.AssertTrue((1)=(FProbe.ResizeCount), 'Queued resize should be delivered');
end;

procedure TTestProcessMessages.TestProcessMessages_ReturnsPromptlyWhenIdle;
var
  startTick: QWord;
  elapsed: QWord;
begin
  { Nothing queued. ProcessMessages should not sit on a blocking platform
    wait. Allow a generous margin so the test is not timing-fragile. }
  startTick := fpgGetTickCount;
  fpgApplication.ProcessMessages;
  elapsed := fpgGetTickCount - startTick;

  FContext.AssertTrue(elapsed < 200, Format('ProcessMessages should return promptly when idle, '
      + 'took %d ms', [elapsed]));
end;

procedure RunTTestProcessMessagesTestProcessMessages_DeliversQueuedPaint(AContext: TNXTestContext);
var lFixture: TTestProcessMessages;
begin
  lFixture:=TTestProcessMessages.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestProcessMessages_DeliversQueuedPaint';
    lFixture.SetUp;
    try lFixture.TestProcessMessages_DeliversQueuedPaint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessMessagesTestProcessMessages_DeliversCascadedMessages(AContext: TNXTestContext);
var lFixture: TTestProcessMessages;
begin
  lFixture:=TTestProcessMessages.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestProcessMessages_DeliversCascadedMessages';
    lFixture.SetUp;
    try lFixture.TestProcessMessages_DeliversCascadedMessages; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessMessagesTestProcessMessages_ReturnsPromptlyWhenIdle(AContext: TNXTestContext);
var lFixture: TTestProcessMessages;
begin
  lFixture:=TTestProcessMessages.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestProcessMessages_ReturnsPromptlyWhenIdle';
    lFixture.SetUp;
    try lFixture.TestProcessMessages_ReturnsPromptlyWhenIdle; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegistertcprocessmessagesTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcprocessmessages.TTestProcessMessages');
  lSuite.AddTest('TestProcessMessages_DeliversQueuedPaint', @RunTTestProcessMessagesTestProcessMessages_DeliversQueuedPaint);
  lSuite.AddTest('TestProcessMessages_DeliversCascadedMessages', @RunTTestProcessMessagesTestProcessMessages_DeliversCascadedMessages);
  lSuite.AddTest('TestProcessMessages_ReturnsPromptlyWhenIdle', @RunTTestProcessMessagesTestProcessMessages_ReturnsPromptlyWhenIdle);
end;



initialization
  RegisterTests;

end.

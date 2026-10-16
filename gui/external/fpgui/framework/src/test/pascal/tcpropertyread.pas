unit tcpropertyread;

{$mode objfpc}{$h+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  ctypes;

type

  { The chunked property reader in fpg_x11 cannot be exercised without a live
    X server, but the arithmetic it depends on can. These tests pin down the
    two conversions that made the original code truncate:

      - XGetWindowProperty reports 'count' in units of the property format
        (8/16/32), not in bytes;
      - its read offset is counted in 32-bit words, not in bytes.

    Getting either wrong silently drops or duplicates data, which is exactly
    the failure being fixed, so the rules are worth locking down. }

  TTestPropertyArithmetic = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    procedure TestFormatToBytes_Format8IsOneByte;
    procedure TestFormatToBytes_Format16IsTwoBytes;
    procedure TestFormatToBytes_Format32IsLongSized;
    procedure TestWordOffset_RoundsUpPartialWord;
    procedure TestWordOffset_ExactWordBoundary;
  end;

  { The read loop must terminate on every reply a peer can produce. An earlier
    version looped while 'remaining' was non-zero without requiring that each
    pass actually consumed bytes, so a format of 0 (property absent) meant it
    span forever on the GUI thread - which froze the whole X session, not just
    the application. These pin the termination rule. }

  TTestReadLoopTermination = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    procedure TestTerminates_WhenFormatIsZero;
    procedure TestTerminates_WhenFormatIsUnknown;
    procedure TestTerminates_WhenNoBytesConsumedDespiteRemaining;
    procedure TestContinues_WhileBytesAreBeingConsumed;
  end;


procedure RegistertcpropertyreadTests(ARegistry: TNXTestRegistry);

implementation

{ Mirrors the format -> bytes conversion in ReadWholeProperty. }
function FormatToBytes(AFormat: Integer; ACount: QWord): QWord;
begin
  case AFormat of
    8:  Result := ACount;
    16: Result := ACount * 2;
    32: Result := ACount * SizeOf(culong);
  else
    Result := 0;
  end;
end;

{ Mirrors the byte -> 32-bit-word offset conversion in ReadWholeProperty. }
function BytesToWordOffset(ABytes: QWord): QWord;
begin
  Result := (ABytes + 3) div 4;
end;


{ Mirrors ReadWholeProperty's decision for a single pass: given what the server
  reported, does the loop continue? It may only continue when the pass consumed
  something, otherwise it would spin without making progress. }
function LoopContinues(AFormat: Integer; ACount, ARemaining: QWord): Boolean;
var
  bytes: QWord;
begin
  if AFormat = 0 then
    Exit(False); // property absent / fully consumed
  bytes := FormatToBytes(AFormat, ACount);
  if bytes = 0 then
    Exit(False); // unknown format, or nothing consumed - must not spin
  Result := ARemaining > 0;
end;


procedure TTestPropertyArithmetic.TestFormatToBytes_Format8IsOneByte;
begin
  TestContext.AssertTrue((QWord(24000))=(FormatToBytes(8, 24000)), 'format 8: count is already a byte count');
end;

procedure TTestPropertyArithmetic.TestFormatToBytes_Format16IsTwoBytes;
begin
  TestContext.AssertTrue((QWord(200))=(FormatToBytes(16, 100)), 'format 16: each item is 2 bytes');
end;

procedure TTestPropertyArithmetic.TestFormatToBytes_Format32IsLongSized;
begin
  { X11 hands 32-bit properties back as C longs, so this is 8 bytes per item
    on LP64 and 4 on 32-bit. Assert against SizeOf rather than a literal. }
  TestContext.AssertTrue((QWord(100 * SizeOf(culong)))=(FormatToBytes(32, 100)), 'format 32: each item is one C long');
end;

procedure TTestPropertyArithmetic.TestWordOffset_RoundsUpPartialWord;
begin
  { 4001 bytes occupies 1001 words; truncating to 1000 would re-read the
    trailing partial word and duplicate bytes. }
  TestContext.AssertTrue((QWord(1001))=(BytesToWordOffset(4001)), 'partial trailing word must round up');
end;

procedure TTestPropertyArithmetic.TestWordOffset_ExactWordBoundary;
begin
  TestContext.AssertTrue((QWord(1000))=(BytesToWordOffset(4000)), 'exact multiple must not round up');
end;


{ TTestReadLoopTermination }

procedure TTestReadLoopTermination.TestTerminates_WhenFormatIsZero;
begin
  { Format 0 means the property does not exist. The server may still report
    bytes remaining; looping on that is what caused the freeze. }
  TestContext.AssertTrue(not (LoopContinues(0, 0, 5000)), 'format 0 must end the loop even with bytes remaining');
end;

procedure TTestReadLoopTermination.TestTerminates_WhenFormatIsUnknown;
begin
  TestContext.AssertTrue(not (LoopContinues(7, 100, 5000)), 'an uninterpretable format must end the loop');
end;

procedure TTestReadLoopTermination.TestTerminates_WhenNoBytesConsumedDespiteRemaining;
begin
  { A peer reporting "more to come" while handing back nothing must not keep
    us looping. }
  TestContext.AssertTrue(not (LoopContinues(8, 0, 5000)), 'no progress must end the loop');
end;

procedure TTestReadLoopTermination.TestContinues_WhileBytesAreBeingConsumed;
begin
  { The normal large-transfer case must still iterate. }
  TestContext.AssertTrue(LoopContinues(8, 65536, 200000), 'a productive pass with data remaining should continue');
  TestContext.AssertTrue(not (LoopContinues(8, 65536, 0)), 'a productive pass with nothing remaining should stop');
end;

constructor TTestPropertyArithmetic.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

constructor TTestReadLoopTermination.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestPropertyArithmeticTestFormatToBytes_Format8IsOneByte(AContext: TNXTestContext);
var lFixture: TTestPropertyArithmetic;
begin
  lFixture:=TTestPropertyArithmetic.Create(AContext, 'TestFormatToBytes_Format8IsOneByte');
  try
    lFixture.TestFormatToBytes_Format8IsOneByte;
  finally lFixture.Free; end;
end;

procedure RunTTestPropertyArithmeticTestFormatToBytes_Format16IsTwoBytes(AContext: TNXTestContext);
var lFixture: TTestPropertyArithmetic;
begin
  lFixture:=TTestPropertyArithmetic.Create(AContext, 'TestFormatToBytes_Format16IsTwoBytes');
  try
    lFixture.TestFormatToBytes_Format16IsTwoBytes;
  finally lFixture.Free; end;
end;

procedure RunTTestPropertyArithmeticTestFormatToBytes_Format32IsLongSized(AContext: TNXTestContext);
var lFixture: TTestPropertyArithmetic;
begin
  lFixture:=TTestPropertyArithmetic.Create(AContext, 'TestFormatToBytes_Format32IsLongSized');
  try
    lFixture.TestFormatToBytes_Format32IsLongSized;
  finally lFixture.Free; end;
end;

procedure RunTTestPropertyArithmeticTestWordOffset_RoundsUpPartialWord(AContext: TNXTestContext);
var lFixture: TTestPropertyArithmetic;
begin
  lFixture:=TTestPropertyArithmetic.Create(AContext, 'TestWordOffset_RoundsUpPartialWord');
  try
    lFixture.TestWordOffset_RoundsUpPartialWord;
  finally lFixture.Free; end;
end;

procedure RunTTestPropertyArithmeticTestWordOffset_ExactWordBoundary(AContext: TNXTestContext);
var lFixture: TTestPropertyArithmetic;
begin
  lFixture:=TTestPropertyArithmetic.Create(AContext, 'TestWordOffset_ExactWordBoundary');
  try
    lFixture.TestWordOffset_ExactWordBoundary;
  finally lFixture.Free; end;
end;

procedure RunTTestReadLoopTerminationTestTerminates_WhenFormatIsZero(AContext: TNXTestContext);
var lFixture: TTestReadLoopTermination;
begin
  lFixture:=TTestReadLoopTermination.Create(AContext, 'TestTerminates_WhenFormatIsZero');
  try
    lFixture.TestTerminates_WhenFormatIsZero;
  finally lFixture.Free; end;
end;

procedure RunTTestReadLoopTerminationTestTerminates_WhenFormatIsUnknown(AContext: TNXTestContext);
var lFixture: TTestReadLoopTermination;
begin
  lFixture:=TTestReadLoopTermination.Create(AContext, 'TestTerminates_WhenFormatIsUnknown');
  try
    lFixture.TestTerminates_WhenFormatIsUnknown;
  finally lFixture.Free; end;
end;

procedure RunTTestReadLoopTerminationTestTerminates_WhenNoBytesConsumedDespiteRemaining(AContext: TNXTestContext);
var lFixture: TTestReadLoopTermination;
begin
  lFixture:=TTestReadLoopTermination.Create(AContext, 'TestTerminates_WhenNoBytesConsumedDespiteRemaining');
  try
    lFixture.TestTerminates_WhenNoBytesConsumedDespiteRemaining;
  finally lFixture.Free; end;
end;

procedure RunTTestReadLoopTerminationTestContinues_WhileBytesAreBeingConsumed(AContext: TNXTestContext);
var lFixture: TTestReadLoopTermination;
begin
  lFixture:=TTestReadLoopTermination.Create(AContext, 'TestContinues_WhileBytesAreBeingConsumed');
  try
    lFixture.TestContinues_WhileBytesAreBeingConsumed;
  finally lFixture.Free; end;
end;

procedure RegistertcpropertyreadTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcpropertyread.TTestPropertyArithmetic');
  lSuite.AddTest('TestFormatToBytes_Format8IsOneByte', @RunTTestPropertyArithmeticTestFormatToBytes_Format8IsOneByte);
  lSuite.AddTest('TestFormatToBytes_Format16IsTwoBytes', @RunTTestPropertyArithmeticTestFormatToBytes_Format16IsTwoBytes);
  lSuite.AddTest('TestFormatToBytes_Format32IsLongSized', @RunTTestPropertyArithmeticTestFormatToBytes_Format32IsLongSized);
  lSuite.AddTest('TestWordOffset_RoundsUpPartialWord', @RunTTestPropertyArithmeticTestWordOffset_RoundsUpPartialWord);
  lSuite.AddTest('TestWordOffset_ExactWordBoundary', @RunTTestPropertyArithmeticTestWordOffset_ExactWordBoundary);
  lSuite:=ARegistry.AddSuite('tcpropertyread.TTestReadLoopTermination');
  lSuite.AddTest('TestTerminates_WhenFormatIsZero', @RunTTestReadLoopTerminationTestTerminates_WhenFormatIsZero);
  lSuite.AddTest('TestTerminates_WhenFormatIsUnknown', @RunTTestReadLoopTerminationTestTerminates_WhenFormatIsUnknown);
  lSuite.AddTest('TestTerminates_WhenNoBytesConsumedDespiteRemaining', @RunTTestReadLoopTerminationTestTerminates_WhenNoBytesConsumedDespiteRemaining);
  lSuite.AddTest('TestContinues_WhileBytesAreBeingConsumed', @RunTTestReadLoopTerminationTestContinues_WhileBytesAreBeingConsumed);
end;



end.

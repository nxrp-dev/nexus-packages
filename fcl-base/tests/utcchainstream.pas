unit utcchainstream;

{$mode ObjFPC}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, chainstream;

Type

  { TTestChainStream }

  TTestChainStream = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FStreams : Array of TStream;
    FStream: TChainedStream;
    procedure ClearStreams;
  Public
    Function CreateStream(aOffset,aCount : Word) : TStream;
    Procedure CreateChainedStream(Sizes : Array of Word; aOffset : Word = 0);
    Procedure Setup; virtual;
    Procedure TearDown; virtual;
    Property Stream : TChainedStream Read FStream;
  public
    Procedure TestEmpty;
    Procedure TestCreateStream;
    Procedure TestCreateStreams;
    Procedure TestCreateStreams2;
    Procedure TestOneStreamRead;
    Procedure TestTwoStreamsRead;
    Procedure TestTwoStreamsReadCrossBuffer;
    Procedure TestTwoStreamsWrite;
    Procedure TestTwoStreamsWriteCrossBuffer;
    Procedure TestStreamsSeekFromEnd1;
    Procedure TestStreamsSeekFromEnd2;
    Procedure TestStreamsSeekFromBeginning1;
    Procedure TestStreamsSeekFromBeginning2;
    Procedure TestStreamsSeekFromCurrent1;
    Procedure TestStreamsSeekFromCurrent2;
  end;

procedure RegisterutcchainstreamTests(ARegistry: TNXTestRegistry);

implementation

{ TTestChainStream }

function TTestChainStream.CreateStream(aOffset, aCount: Word): TStream;

Var
  I : integer;

begin
  Result:=TMemoryStream.Create;
  For I:=0 to aCount-1 do
    begin
    Result.WriteBuffer(aOffset,SizeOf(Word));
    Inc(aOffset);
    end;
  Result.Position:=0;
end;

procedure TTestChainStream.CreateChainedStream(Sizes: array of Word; aOffset : Word = 0);

Var
  I : integer;
  aSize : Word;

begin
  TestContext.AssertTrue(Length(Sizes)>0, 'Must have at least one stream size');
  ClearStreams;
  SetLength(FStreams,Length(Sizes));

  For I:=0 to Length(FStreams)-1 do
    begin
    aSize:=Sizes[i];
    FStreams[i]:=CreateStream(aOffset,aSize);
    Inc(aOffset,aSize);
    end;
  FStream:=TChainedStream.Create(FStreams,False);
end;

procedure TTestChainStream.Setup;
begin
end;

procedure TTestChainStream.ClearStreams;

var
  I : Integer;

begin
  if Assigned(FStream) then
    begin
    if FStream.OwnsStreams then
      FStreams:=[];
    FStream.Free;
    end;
  For I:=0 to Length(FStreams)-1 do
    FStreams[i].Free;
end;

procedure TTestChainStream.TearDown;
begin
  ClearStreams;

end;

procedure TTestChainStream.TestEmpty;
begin
  TestContext.AssertTrue((FStream)=nil, 'No stream');
  TestContext.AssertTrue((0)=(Length(FStreams)), 'No streams');
end;

procedure TTestChainStream.TestCreateStream;

var
  S : TStream;
  I,W : Word;

begin
  S:=CreateStream(10,3);
  try
    TestContext.AssertTrue((0)=(S.Position), 'Stream position');
    TestContext.AssertTrue((6)=(S.Size), 'Stream size');
    For I:=10 to 12 do
      begin
      S.ReadBuffer(W,SizeOf(Word));
      TestContext.AssertTrue((I)=(W), 'Correct byte read');
      end;
  finally
    S.Free;
  end;
end;

procedure TTestChainStream.TestCreateStreams;

begin
  CreateChainedStream([10]);
  TestContext.AssertTrue((1)=(Length(FStreams)), 'Correct stream count');
  TestContext.AssertTrue((1)=(Stream.StreamCount), 'Count');
  TestContext.AssertTrue((FStreams[0])=(Stream.Streams[0]), 'Stream');
  TestContext.AssertTrue((20)=(Stream.Size), 'Total size');
end;

procedure TTestChainStream.TestCreateStreams2;
begin
  CreateChainedStream([10,10]);
  TestContext.AssertTrue((2)=(Length(FStreams)), 'Correct stream count');
  TestContext.AssertTrue((2)=(Stream.StreamCount), 'Count');
  TestContext.AssertTrue((FStreams[0])=(Stream.Streams[0]), 'Stream 0');
  TestContext.AssertTrue((FStreams[1])=(Stream.Streams[1]), 'Stream 1');
  TestContext.AssertTrue((40)=(Stream.Size), 'Total size');
end;

procedure TTestChainStream.TestOneStreamRead;

Var
  I : Integer;
  W : Word;

begin
  CreateChainedStream([10]);
  For I:=0 to 9 do
    begin
    Stream.ReadBuffer(W,SizeOf(W));
    TestContext.AssertTrue((I)=(W), 'Correct bytes read')
    end;
end;

procedure TTestChainStream.TestTwoStreamsRead;

Var
  I : Integer;
  W : Word;

begin
  CreateChainedStream([10,10]);
  For I:=0 to 19 do
    begin
    Stream.ReadBuffer(W,SizeOf(W));
    TestContext.AssertTrue((I)=(W), 'Correct bytes read')
    end;
end;

procedure TTestChainStream.TestTwoStreamsReadCrossBuffer;
Var
  I : Integer;
  W : Array of Word;

begin
  SetLength(W,20);
  CreateChainedStream([10,10]);
  Stream.ReadBuffer(W[0],Length(W)*SizeOf(Word));
  For I:=0 to 19 do
    begin
    TestContext.AssertTrue((I)=(W[i]), 'Correct bytes read')
    end;
end;

procedure TTestChainStream.TestTwoStreamsWrite;
var lValue: Word; lRejected: Boolean;
begin
  CreateChainedStream([10,10]);
  lRejected:=False;
  lValue:=$FFFF;
  try Stream.WriteBuffer(lValue,SizeOf(lValue));
  except on lError: EStreamError do lRejected:=True; end;
  TestContext.AssertTrue(lRejected,'Aggregate streams reject writes');
  TestContext.AssertEquals(0,Integer(Stream.Position),'Rejected write moved the stream');
  Stream.ReadBuffer(lValue,SizeOf(lValue));
  TestContext.AssertEquals(0,lValue,'Rejected write changed the data');
end;

procedure TTestChainStream.TestTwoStreamsWriteCrossBuffer;
var lValue: Word; lRejected: Boolean;
begin
  CreateChainedStream([10,10]);
  Stream.Position:=18;
  lRejected:=False;
  lValue:=$FFFF;
  try Stream.WriteBuffer(lValue,SizeOf(lValue));
  except on lError: EStreamError do lRejected:=True; end;
  TestContext.AssertTrue(lRejected,'Aggregate streams reject writes');
  TestContext.AssertEquals(18,Integer(Stream.Position),'Rejected write moved the stream');
  Stream.ReadBuffer(lValue,SizeOf(lValue));
  TestContext.AssertEquals(9,lValue,'Rejected write changed the data');
end;

procedure TTestChainStream.TestStreamsSeekFromEnd1;

Var
  W : Word;

begin
  CreateChainedStream([10,10]);
  TestContext.AssertTrue((38)=(Stream.Seek(-2,soEnd)), 'Seek');
  Stream.ReadBuffer(W,SizeOf(Word));
  TestContext.AssertTrue((19)=(W), 'Correct read');
  TestContext.AssertTrue((20)=(Stream.Seek(-20,soEnd)), 'Seek 2');
  Stream.ReadBuffer(W,SizeOf(Word));
  TestContext.AssertTrue((10)=(W), 'Correct read 2');
  TestContext.AssertTrue((18)=(Stream.Seek(-22,soEnd)), 'Seek 3');
  Stream.ReadBuffer(W,SizeOf(Word));
  TestContext.AssertTrue((9)=(W), 'Correct read 2');
end;

procedure TTestChainStream.TestStreamsSeekFromEnd2;

Var
  W : Word;

begin
  CreateChainedStream([10,10,10]);
  TestContext.AssertTrue((0)=(Stream.Seek(-60,soEnd)), 'Seek');
  Stream.ReadBuffer(W,SizeOf(Word));
  TestContext.AssertTrue((0)=(W), 'Correct read ');
  TestContext.AssertTrue((30)=(Stream.Seek(-30,soEnd)), 'Seek');
  Stream.ReadBuffer(W,SizeOf(Word));
  TestContext.AssertTrue((15)=(W), 'Correct read ');
end;

procedure TTestChainStream.TestStreamsSeekFromBeginning1;

Var
  W : Word;

begin
  CreateChainedStream([10,10]);
  TestContext.AssertTrue((38)=(Stream.Seek(38,soBeginning)), 'Seek');
  Stream.ReadBuffer(W,SizeOf(Word));
  TestContext.AssertTrue((19)=(W), 'Correct read');
  TestContext.AssertTrue((20)=(Stream.Seek(20,soBeginning)), 'Seek 2');
  Stream.ReadBuffer(W,SizeOf(Word));
  TestContext.AssertTrue((10)=(W), 'Correct read 2');
  TestContext.AssertTrue((18)=(Stream.Seek(18,soBeginning)), 'Seek 3');
  Stream.ReadBuffer(W,SizeOf(Word));
  TestContext.AssertTrue((9)=(W), 'Correct read 2');
end;

procedure TTestChainStream.TestStreamsSeekFromBeginning2;

Var
  W : Word;

begin
  CreateChainedStream([10,10,10]);
  TestContext.AssertTrue((0)=(Stream.Seek(0,soBeginning)), 'Seek');
  Stream.ReadBuffer(W,SizeOf(Word));
  TestContext.AssertTrue((0)=(W), 'Correct read ');
  TestContext.AssertTrue((30)=(Stream.Seek(30,soBeginning)), 'Seek');
  Stream.ReadBuffer(W,SizeOf(Word));
  TestContext.AssertTrue((15)=(W), 'Correct read ');
  TestContext.AssertTrue((50)=(Stream.Seek(50,soBeginning)), 'Seek');
  Stream.ReadBuffer(W,SizeOf(Word));
  TestContext.AssertTrue((25)=(W), 'Correct read ');
end;

procedure TTestChainStream.TestStreamsSeekFromCurrent1;
Var
  W : Word;

begin
  CreateChainedStream([10,10]);
  TestContext.AssertTrue((4)=(Stream.Seek(4,soCurrent)), 'Seek');
  Stream.ReadBuffer(W,SizeOf(Word));
  TestContext.AssertTrue((2)=(W), 'Correct read 1');
  TestContext.AssertTrue((6)=(Stream.Position), 'Position after read 1');
  TestContext.AssertTrue((26)=(Stream.Seek(20,soCurrent)), 'Seek 2');
  Stream.ReadBuffer(W,SizeOf(Word));
  TestContext.AssertTrue((13)=(W), 'Correct read 2');
  TestContext.AssertTrue((28)=(Stream.Position), 'Position after read 2');
  TestContext.AssertTrue((32)=(Stream.Seek(4,soCurrent)), 'Seek 3');
  Stream.ReadBuffer(W,SizeOf(Word));
  TestContext.AssertTrue((16)=(W), 'Correct read 3');
  TestContext.AssertTrue((34)=(Stream.Position), 'Position after read 2');
end;

procedure TTestChainStream.TestStreamsSeekFromCurrent2;
Var
  W : Word;
  I : Integer;

begin
  CreateChainedStream([10,10]);
  For I:=1 to 15 do
    Stream.ReadBuffer(W,SizeOf(Word));
  TestContext.AssertTrue((30)=(Stream.Position), 'Position after reading data');
  TestContext.AssertTrue((26)=(Stream.Seek(-4,soCurrent)), 'Seek');
  Stream.ReadBuffer(W,SizeOf(Word));
  TestContext.AssertTrue((13)=(W), 'Correct read 1');
  TestContext.AssertTrue((28)=(Stream.Position), 'Position after read 1');
  TestContext.AssertTrue((8)=(Stream.Seek(-20,soCurrent)), 'Seek 2');
  Stream.ReadBuffer(W,SizeOf(Word));
  TestContext.AssertTrue((4)=(W), 'Correct read 2');
  TestContext.AssertTrue((10)=(Stream.Position), 'Position after read 2');
  TestContext.AssertTrue((6)=(Stream.Seek(-4,soCurrent)), 'Seek 3');
  Stream.ReadBuffer(W,SizeOf(Word));
  TestContext.AssertTrue((3)=(W), 'Correct read 3');
  TestContext.AssertTrue((8)=(Stream.Position), 'Position after read 2');
end;

constructor TTestChainStream.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestChainStreamTestEmpty(AContext: TNXTestContext);
var lFixture: TTestChainStream;
begin
  lFixture:=TTestChainStream.Create(AContext, 'TestEmpty');
  try
    lFixture.SetUp;
    try lFixture.TestEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestChainStreamTestCreateStream(AContext: TNXTestContext);
var lFixture: TTestChainStream;
begin
  lFixture:=TTestChainStream.Create(AContext, 'TestCreateStream');
  try
    lFixture.SetUp;
    try lFixture.TestCreateStream; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestChainStreamTestCreateStreams(AContext: TNXTestContext);
var lFixture: TTestChainStream;
begin
  lFixture:=TTestChainStream.Create(AContext, 'TestCreateStreams');
  try
    lFixture.SetUp;
    try lFixture.TestCreateStreams; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestChainStreamTestCreateStreams2(AContext: TNXTestContext);
var lFixture: TTestChainStream;
begin
  lFixture:=TTestChainStream.Create(AContext, 'TestCreateStreams2');
  try
    lFixture.SetUp;
    try lFixture.TestCreateStreams2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestChainStreamTestOneStreamRead(AContext: TNXTestContext);
var lFixture: TTestChainStream;
begin
  lFixture:=TTestChainStream.Create(AContext, 'TestOneStreamRead');
  try
    lFixture.SetUp;
    try lFixture.TestOneStreamRead; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestChainStreamTestTwoStreamsRead(AContext: TNXTestContext);
var lFixture: TTestChainStream;
begin
  lFixture:=TTestChainStream.Create(AContext, 'TestTwoStreamsRead');
  try
    lFixture.SetUp;
    try lFixture.TestTwoStreamsRead; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestChainStreamTestTwoStreamsReadCrossBuffer(AContext: TNXTestContext);
var lFixture: TTestChainStream;
begin
  lFixture:=TTestChainStream.Create(AContext, 'TestTwoStreamsReadCrossBuffer');
  try
    lFixture.SetUp;
    try lFixture.TestTwoStreamsReadCrossBuffer; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestChainStreamTestTwoStreamsWrite(AContext: TNXTestContext);
var lFixture: TTestChainStream;
begin
  lFixture:=TTestChainStream.Create(AContext, 'TestTwoStreamsWrite');
  try
    lFixture.SetUp;
    try lFixture.TestTwoStreamsWrite; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestChainStreamTestTwoStreamsWriteCrossBuffer(AContext: TNXTestContext);
var lFixture: TTestChainStream;
begin
  lFixture:=TTestChainStream.Create(AContext, 'TestTwoStreamsWriteCrossBuffer');
  try
    lFixture.SetUp;
    try lFixture.TestTwoStreamsWriteCrossBuffer; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestChainStreamTestStreamsSeekFromEnd1(AContext: TNXTestContext);
var lFixture: TTestChainStream;
begin
  lFixture:=TTestChainStream.Create(AContext, 'TestStreamsSeekFromEnd1');
  try
    lFixture.SetUp;
    try lFixture.TestStreamsSeekFromEnd1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestChainStreamTestStreamsSeekFromEnd2(AContext: TNXTestContext);
var lFixture: TTestChainStream;
begin
  lFixture:=TTestChainStream.Create(AContext, 'TestStreamsSeekFromEnd2');
  try
    lFixture.SetUp;
    try lFixture.TestStreamsSeekFromEnd2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestChainStreamTestStreamsSeekFromBeginning1(AContext: TNXTestContext);
var lFixture: TTestChainStream;
begin
  lFixture:=TTestChainStream.Create(AContext, 'TestStreamsSeekFromBeginning1');
  try
    lFixture.SetUp;
    try lFixture.TestStreamsSeekFromBeginning1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestChainStreamTestStreamsSeekFromBeginning2(AContext: TNXTestContext);
var lFixture: TTestChainStream;
begin
  lFixture:=TTestChainStream.Create(AContext, 'TestStreamsSeekFromBeginning2');
  try
    lFixture.SetUp;
    try lFixture.TestStreamsSeekFromBeginning2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestChainStreamTestStreamsSeekFromCurrent1(AContext: TNXTestContext);
var lFixture: TTestChainStream;
begin
  lFixture:=TTestChainStream.Create(AContext, 'TestStreamsSeekFromCurrent1');
  try
    lFixture.SetUp;
    try lFixture.TestStreamsSeekFromCurrent1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestChainStreamTestStreamsSeekFromCurrent2(AContext: TNXTestContext);
var lFixture: TTestChainStream;
begin
  lFixture:=TTestChainStream.Create(AContext, 'TestStreamsSeekFromCurrent2');
  try
    lFixture.SetUp;
    try lFixture.TestStreamsSeekFromCurrent2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegisterutcchainstreamTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('FCL.Streams.Chained');
  lSuite.AddTest('TestEmpty', @RunTTestChainStreamTestEmpty, 'streams');
  lSuite.AddTest('TestCreateStream', @RunTTestChainStreamTestCreateStream, 'streams');
  lSuite.AddTest('TestCreateStreams', @RunTTestChainStreamTestCreateStreams, 'streams');
  lSuite.AddTest('TestCreateStreams2', @RunTTestChainStreamTestCreateStreams2, 'streams');
  lSuite.AddTest('TestOneStreamRead', @RunTTestChainStreamTestOneStreamRead, 'streams');
  lSuite.AddTest('TestTwoStreamsRead', @RunTTestChainStreamTestTwoStreamsRead, 'streams');
  lSuite.AddTest('TestTwoStreamsReadCrossBuffer', @RunTTestChainStreamTestTwoStreamsReadCrossBuffer, 'streams');
  lSuite.AddTest('TestTwoStreamsWrite', @RunTTestChainStreamTestTwoStreamsWrite, 'streams');
  lSuite.AddTest('TestTwoStreamsWriteCrossBuffer', @RunTTestChainStreamTestTwoStreamsWriteCrossBuffer, 'streams');
  lSuite.AddTest('TestStreamsSeekFromEnd1', @RunTTestChainStreamTestStreamsSeekFromEnd1, 'streams');
  lSuite.AddTest('TestStreamsSeekFromEnd2', @RunTTestChainStreamTestStreamsSeekFromEnd2, 'streams');
  lSuite.AddTest('TestStreamsSeekFromBeginning1', @RunTTestChainStreamTestStreamsSeekFromBeginning1, 'streams');
  lSuite.AddTest('TestStreamsSeekFromBeginning2', @RunTTestChainStreamTestStreamsSeekFromBeginning2, 'streams');
  lSuite.AddTest('TestStreamsSeekFromCurrent1', @RunTTestChainStreamTestStreamsSeekFromCurrent1, 'streams');
  lSuite.AddTest('TestStreamsSeekFromCurrent2', @RunTTestChainStreamTestStreamsSeekFromCurrent2, 'streams');
end;

end.

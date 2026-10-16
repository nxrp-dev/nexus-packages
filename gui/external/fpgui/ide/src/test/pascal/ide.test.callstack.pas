{
    fpGUI IDE - Call Stack Panel Logic Tests

    Tests for the pure-logic functions in ide.callstack:
      - ParseCallStackFrame
      - ParseCallStack
      - CallStackFrameDisplay
}
unit ide.test.callstack;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils,
  ide.callstack;

type

  { TTestParseCallStackFrame }

  TTestParseCallStackFrame = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    procedure AssertFrame(const AText: string;
        AExpectedIndex: Integer;
        const AExpectedFunc, AExpectedFile: string;
        AExpectedLine: Integer;
        AExpectedHasSource: Boolean);
  public
    { Empty / degenerate input }
    procedure TestEmptyString;
    procedure TestNoHash;
    procedure TestHashOnly;

    { Full format: #N FuncName at file.pas:line (0xADDR) }
    procedure TestFrame0WithSource;
    procedure TestFrame1WithSource;
    procedure TestHighFrameIndex;
    procedure TestLongAddress;

    { Function known, no source: #N FuncName (0xADDR) }
    procedure TestFrameNoSource;
    procedure TestFrameUnknown;

    { Edge cases }
    procedure TestFuncNameWithSpaces;
    procedure TestFileNameWithColon;    { e.g. Windows path C:\foo.pas }
  end;

  { TTestParseCallStack }

  TTestParseCallStack = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    procedure TestEmptyArray;
    procedure TestSingleFrame;
    procedure TestMultipleFrames;
    procedure TestFrameCountMatchesInput;
  end;

  { TTestCallStackFrameDisplay }

  TTestCallStackFrameDisplay = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    function MakeFrame(AIndex: Integer; const AFunc, AFile: string;
        ALine: Integer; AAddr: QWord): TCallStackFrame;
  public
    procedure TestDisplayWithSource;
    procedure TestDisplayAddressOnly;
    procedure TestDisplayUnknownNoAddress;
    procedure TestDisplayZeroAddress;
    procedure TestDisplayHighFrameIndex;
  end;

procedure RegisteridetestcallstackTests(ARegistry: TNXTestRegistry);

implementation

{ ---------------------------------------------------------------------------
  TTestParseCallStackFrame
  --------------------------------------------------------------------------- }

procedure TTestParseCallStackFrame.AssertFrame(const AText: string;
    AExpectedIndex: Integer;
    const AExpectedFunc, AExpectedFile: string;
    AExpectedLine: Integer;
    AExpectedHasSource: Boolean);
var
  F: TCallStackFrame;
begin
  F := ParseCallStackFrame(AText);
  TestContext.AssertTrue((AExpectedIndex)=(F.Index), 'Index');
  TestContext.AssertTrue((AExpectedFunc)=(F.FuncName), 'FuncName');
  TestContext.AssertTrue((AExpectedFile)=(F.FileName), 'FileName');
  TestContext.AssertTrue((AExpectedLine)=(F.LineNumber), 'LineNumber');
  TestContext.AssertTrue((AExpectedHasSource)=(F.HasSource), 'HasSource');
end;

procedure TTestParseCallStackFrame.TestEmptyString;
var
  F: TCallStackFrame;
begin
  F := ParseCallStackFrame('');
  TestContext.AssertTrue(('')=(F.FuncName), 'FuncName on empty');
  TestContext.AssertTrue((0)=(F.Index), 'Index on empty');
  TestContext.AssertTrue(not (F.HasSource), 'HasSource on empty');
end;

procedure TTestParseCallStackFrame.TestNoHash;
var
  F: TCallStackFrame;
begin
  F := ParseCallStackFrame('0 MyProc (0x0000000000000001)');
  { No leading '#' — falls back to AText as FuncName }
  TestContext.AssertTrue(not (F.HasSource), 'HasSource');
end;

procedure TTestParseCallStackFrame.TestHashOnly;
var
  F: TCallStackFrame;
begin
  F := ParseCallStackFrame('#');
  TestContext.AssertTrue(not (F.HasSource), 'HasSource');
end;

procedure TTestParseCallStackFrame.TestFrame0WithSource;
begin
  AssertFrame(
    '#0 MyProc at myfile.pas:42 (0x00007F1234ABCDEF)',
    0, 'MyProc', 'myfile.pas', 42, True
  );
end;

procedure TTestParseCallStackFrame.TestFrame1WithSource;
begin
  AssertFrame(
    '#1 CallerProc at caller.pas:30 (0x00007F0000001234)',
    1, 'CallerProc', 'caller.pas', 30, True
  );
end;

procedure TTestParseCallStackFrame.TestHighFrameIndex;
begin
  AssertFrame(
    '#15 DeepProc at deep.pas:1 (0x0000000000000001)',
    15, 'DeepProc', 'deep.pas', 1, True
  );
end;

procedure TTestParseCallStackFrame.TestLongAddress;
var
  F: TCallStackFrame;
begin
  F := ParseCallStackFrame('#0 MyProc at foo.pas:10 (0x00007FFFFFFFFFFF)');
  TestContext.AssertTrue((QWord($00007FFFFFFFFFFF))=(F.Address), 'Address');
end;

procedure TTestParseCallStackFrame.TestFrameNoSource;
begin
  AssertFrame(
    '#2 LibProc (0x00007F9900000000)',
    2, 'LibProc', '', 0, False
  );
end;

procedure TTestParseCallStackFrame.TestFrameUnknown;
begin
  AssertFrame(
    '#3 <unknown> (0x00007F1122334455)',
    3, '<unknown>', '', 0, False
  );
end;

procedure TTestParseCallStackFrame.TestFuncNameWithSpaces;
begin
  { FPC-generated names can contain spaces in some edge cases;
    the ' at ' separator must still be found correctly. }
  AssertFrame(
    '#0 TMyClass.MyProc at myunit.pas:100 (0x0000000000000001)',
    0, 'TMyClass.MyProc', 'myunit.pas', 100, True
  );
end;

procedure TTestParseCallStackFrame.TestFileNameWithColon;
var
  F: TCallStackFrame;
begin
  { On Windows paths contain 'C:\' — the last ':' must be used to split. }
  F := ParseCallStackFrame('#0 WinProc at C:\src\win.pas:55 (0x0000000000000001)');
  TestContext.AssertTrue(('C:\src\win.pas')=(F.FileName), 'FileName');
  TestContext.AssertTrue((55)=(F.LineNumber), 'LineNumber');
  TestContext.AssertTrue(F.HasSource, 'HasSource');
end;

{ ---------------------------------------------------------------------------
  TTestParseCallStack
  --------------------------------------------------------------------------- }

procedure TTestParseCallStack.TestEmptyArray;
var
  Frames: TCallStackFrameArray;
begin
  Frames := ParseCallStack([]);
  TestContext.AssertTrue((0)=(Length(Frames)), 'Empty array length');
end;

procedure TTestParseCallStack.TestSingleFrame;
var
  Frames: TCallStackFrameArray;
begin
  Frames := ParseCallStack(['#0 MyProc at foo.pas:1 (0x0000000000000001)']);
  TestContext.AssertTrue((1)=(Length(Frames)), 'Length');
  TestContext.AssertTrue(('MyProc')=(Frames[0].FuncName), 'FuncName');
end;

procedure TTestParseCallStack.TestMultipleFrames;
var
  Frames: TCallStackFrameArray;
begin
  Frames := ParseCallStack([
    '#0 Inner at a.pas:10 (0x0000000000000001)',
    '#1 Middle at b.pas:20 (0x0000000000000002)',
    '#2 Outer at c.pas:30 (0x0000000000000003)'
  ]);
  TestContext.AssertTrue((3)=(Length(Frames)), 'Length');
  TestContext.AssertTrue(('Inner')=(Frames[0].FuncName), 'Frame 0 func');
  TestContext.AssertTrue(('Middle')=(Frames[1].FuncName), 'Frame 1 func');
  TestContext.AssertTrue(('Outer')=(Frames[2].FuncName), 'Frame 2 func');
  TestContext.AssertTrue((30)=(Frames[2].LineNumber), 'Frame 2 line');
end;

procedure TTestParseCallStack.TestFrameCountMatchesInput;
var
  Frames: TCallStackFrameArray;
begin
  Frames := ParseCallStack([
    '#0 A (0x0000000000000001)',
    '#1 B (0x0000000000000002)',
    '#2 C (0x0000000000000003)',
    '#3 D (0x0000000000000004)',
    '#4 E (0x0000000000000005)'
  ]);
  TestContext.AssertTrue((5)=(Length(Frames)), 'Count');
end;

{ ---------------------------------------------------------------------------
  TTestCallStackFrameDisplay
  --------------------------------------------------------------------------- }

function TTestCallStackFrameDisplay.MakeFrame(AIndex: Integer;
    const AFunc, AFile: string; ALine: Integer; AAddr: QWord): TCallStackFrame;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Index      := AIndex;
  Result.FuncName   := AFunc;
  Result.FileName   := AFile;
  Result.LineNumber := ALine;
  Result.Address    := AAddr;
  Result.HasSource  := (AFile <> '') and (ALine > 0);
end;

procedure TTestCallStackFrameDisplay.TestDisplayWithSource;
var
  F: TCallStackFrame;
begin
  F := MakeFrame(0, 'MyProc', 'myfile.pas', 42, QWord($00007F1234ABCDEF));
  TestContext.AssertTrue(('#0  MyProc  (myfile.pas:42)')=(CallStackFrameDisplay(F)), '');
end;

procedure TTestCallStackFrameDisplay.TestDisplayAddressOnly;
var
  F: TCallStackFrame;
begin
  F := MakeFrame(2, 'LibProc', '', 0, QWord($00007F9900000000));
  TestContext.AssertTrue(('#2  LibProc  (0x00007F9900000000)')=(CallStackFrameDisplay(F)), '');
end;

procedure TTestCallStackFrameDisplay.TestDisplayUnknownNoAddress;
var
  F: TCallStackFrame;
begin
  { Address = 0 and no source — display just index and name }
  F := MakeFrame(5, '<unknown>', '', 0, 0);
  TestContext.AssertTrue(('#5  <unknown>')=(CallStackFrameDisplay(F)), '');
end;

procedure TTestCallStackFrameDisplay.TestDisplayZeroAddress;
var
  F: TCallStackFrame;
begin
  { A frame with HasSource=False and Address=0 shows no location suffix }
  F := MakeFrame(1, 'SomeFunc', '', 0, 0);
  TestContext.AssertTrue(('#1  SomeFunc')=(CallStackFrameDisplay(F)), '');
end;

procedure TTestCallStackFrameDisplay.TestDisplayHighFrameIndex;
var
  F: TCallStackFrame;
begin
  F := MakeFrame(15, 'DeepProc', 'deep.pas', 1, QWord($0000000000000001));
  TestContext.AssertTrue(('#15  DeepProc  (deep.pas:1)')=(CallStackFrameDisplay(F)), '');
end;


constructor TTestParseCallStackFrame.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

constructor TTestParseCallStack.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

constructor TTestCallStackFrameDisplay.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestParseCallStackFrameTestEmptyString(AContext: TNXTestContext);
var lFixture: TTestParseCallStackFrame;
begin
  lFixture:=TTestParseCallStackFrame.Create(AContext, 'TestEmptyString');
  try
    lFixture.TestEmptyString;
  finally lFixture.Free; end;
end;

procedure RunTTestParseCallStackFrameTestNoHash(AContext: TNXTestContext);
var lFixture: TTestParseCallStackFrame;
begin
  lFixture:=TTestParseCallStackFrame.Create(AContext, 'TestNoHash');
  try
    lFixture.TestNoHash;
  finally lFixture.Free; end;
end;

procedure RunTTestParseCallStackFrameTestHashOnly(AContext: TNXTestContext);
var lFixture: TTestParseCallStackFrame;
begin
  lFixture:=TTestParseCallStackFrame.Create(AContext, 'TestHashOnly');
  try
    lFixture.TestHashOnly;
  finally lFixture.Free; end;
end;

procedure RunTTestParseCallStackFrameTestFrame0WithSource(AContext: TNXTestContext);
var lFixture: TTestParseCallStackFrame;
begin
  lFixture:=TTestParseCallStackFrame.Create(AContext, 'TestFrame0WithSource');
  try
    lFixture.TestFrame0WithSource;
  finally lFixture.Free; end;
end;

procedure RunTTestParseCallStackFrameTestFrame1WithSource(AContext: TNXTestContext);
var lFixture: TTestParseCallStackFrame;
begin
  lFixture:=TTestParseCallStackFrame.Create(AContext, 'TestFrame1WithSource');
  try
    lFixture.TestFrame1WithSource;
  finally lFixture.Free; end;
end;

procedure RunTTestParseCallStackFrameTestHighFrameIndex(AContext: TNXTestContext);
var lFixture: TTestParseCallStackFrame;
begin
  lFixture:=TTestParseCallStackFrame.Create(AContext, 'TestHighFrameIndex');
  try
    lFixture.TestHighFrameIndex;
  finally lFixture.Free; end;
end;

procedure RunTTestParseCallStackFrameTestLongAddress(AContext: TNXTestContext);
var lFixture: TTestParseCallStackFrame;
begin
  lFixture:=TTestParseCallStackFrame.Create(AContext, 'TestLongAddress');
  try
    lFixture.TestLongAddress;
  finally lFixture.Free; end;
end;

procedure RunTTestParseCallStackFrameTestFrameNoSource(AContext: TNXTestContext);
var lFixture: TTestParseCallStackFrame;
begin
  lFixture:=TTestParseCallStackFrame.Create(AContext, 'TestFrameNoSource');
  try
    lFixture.TestFrameNoSource;
  finally lFixture.Free; end;
end;

procedure RunTTestParseCallStackFrameTestFrameUnknown(AContext: TNXTestContext);
var lFixture: TTestParseCallStackFrame;
begin
  lFixture:=TTestParseCallStackFrame.Create(AContext, 'TestFrameUnknown');
  try
    lFixture.TestFrameUnknown;
  finally lFixture.Free; end;
end;

procedure RunTTestParseCallStackFrameTestFuncNameWithSpaces(AContext: TNXTestContext);
var lFixture: TTestParseCallStackFrame;
begin
  lFixture:=TTestParseCallStackFrame.Create(AContext, 'TestFuncNameWithSpaces');
  try
    lFixture.TestFuncNameWithSpaces;
  finally lFixture.Free; end;
end;

procedure RunTTestParseCallStackFrameTestFileNameWithColon(AContext: TNXTestContext);
var lFixture: TTestParseCallStackFrame;
begin
  lFixture:=TTestParseCallStackFrame.Create(AContext, 'TestFileNameWithColon');
  try
    lFixture.TestFileNameWithColon;
  finally lFixture.Free; end;
end;

procedure RunTTestParseCallStackTestEmptyArray(AContext: TNXTestContext);
var lFixture: TTestParseCallStack;
begin
  lFixture:=TTestParseCallStack.Create(AContext, 'TestEmptyArray');
  try
    lFixture.TestEmptyArray;
  finally lFixture.Free; end;
end;

procedure RunTTestParseCallStackTestSingleFrame(AContext: TNXTestContext);
var lFixture: TTestParseCallStack;
begin
  lFixture:=TTestParseCallStack.Create(AContext, 'TestSingleFrame');
  try
    lFixture.TestSingleFrame;
  finally lFixture.Free; end;
end;

procedure RunTTestParseCallStackTestMultipleFrames(AContext: TNXTestContext);
var lFixture: TTestParseCallStack;
begin
  lFixture:=TTestParseCallStack.Create(AContext, 'TestMultipleFrames');
  try
    lFixture.TestMultipleFrames;
  finally lFixture.Free; end;
end;

procedure RunTTestParseCallStackTestFrameCountMatchesInput(AContext: TNXTestContext);
var lFixture: TTestParseCallStack;
begin
  lFixture:=TTestParseCallStack.Create(AContext, 'TestFrameCountMatchesInput');
  try
    lFixture.TestFrameCountMatchesInput;
  finally lFixture.Free; end;
end;

procedure RunTTestCallStackFrameDisplayTestDisplayWithSource(AContext: TNXTestContext);
var lFixture: TTestCallStackFrameDisplay;
begin
  lFixture:=TTestCallStackFrameDisplay.Create(AContext, 'TestDisplayWithSource');
  try
    lFixture.TestDisplayWithSource;
  finally lFixture.Free; end;
end;

procedure RunTTestCallStackFrameDisplayTestDisplayAddressOnly(AContext: TNXTestContext);
var lFixture: TTestCallStackFrameDisplay;
begin
  lFixture:=TTestCallStackFrameDisplay.Create(AContext, 'TestDisplayAddressOnly');
  try
    lFixture.TestDisplayAddressOnly;
  finally lFixture.Free; end;
end;

procedure RunTTestCallStackFrameDisplayTestDisplayUnknownNoAddress(AContext: TNXTestContext);
var lFixture: TTestCallStackFrameDisplay;
begin
  lFixture:=TTestCallStackFrameDisplay.Create(AContext, 'TestDisplayUnknownNoAddress');
  try
    lFixture.TestDisplayUnknownNoAddress;
  finally lFixture.Free; end;
end;

procedure RunTTestCallStackFrameDisplayTestDisplayZeroAddress(AContext: TNXTestContext);
var lFixture: TTestCallStackFrameDisplay;
begin
  lFixture:=TTestCallStackFrameDisplay.Create(AContext, 'TestDisplayZeroAddress');
  try
    lFixture.TestDisplayZeroAddress;
  finally lFixture.Free; end;
end;

procedure RunTTestCallStackFrameDisplayTestDisplayHighFrameIndex(AContext: TNXTestContext);
var lFixture: TTestCallStackFrameDisplay;
begin
  lFixture:=TTestCallStackFrameDisplay.Create(AContext, 'TestDisplayHighFrameIndex');
  try
    lFixture.TestDisplayHighFrameIndex;
  finally lFixture.Free; end;
end;

procedure RegisteridetestcallstackTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.callstack.TTestParseCallStackFrame');
  lSuite.AddTest('TestEmptyString', @RunTTestParseCallStackFrameTestEmptyString);
  lSuite.AddTest('TestNoHash', @RunTTestParseCallStackFrameTestNoHash);
  lSuite.AddTest('TestHashOnly', @RunTTestParseCallStackFrameTestHashOnly);
  lSuite.AddTest('TestFrame0WithSource', @RunTTestParseCallStackFrameTestFrame0WithSource);
  lSuite.AddTest('TestFrame1WithSource', @RunTTestParseCallStackFrameTestFrame1WithSource);
  lSuite.AddTest('TestHighFrameIndex', @RunTTestParseCallStackFrameTestHighFrameIndex);
  lSuite.AddTest('TestLongAddress', @RunTTestParseCallStackFrameTestLongAddress);
  lSuite.AddTest('TestFrameNoSource', @RunTTestParseCallStackFrameTestFrameNoSource);
  lSuite.AddTest('TestFrameUnknown', @RunTTestParseCallStackFrameTestFrameUnknown);
  lSuite.AddTest('TestFuncNameWithSpaces', @RunTTestParseCallStackFrameTestFuncNameWithSpaces);
  lSuite.AddTest('TestFileNameWithColon', @RunTTestParseCallStackFrameTestFileNameWithColon);
  lSuite:=ARegistry.AddSuite('ide.test.callstack.TTestParseCallStack');
  lSuite.AddTest('TestEmptyArray', @RunTTestParseCallStackTestEmptyArray);
  lSuite.AddTest('TestSingleFrame', @RunTTestParseCallStackTestSingleFrame);
  lSuite.AddTest('TestMultipleFrames', @RunTTestParseCallStackTestMultipleFrames);
  lSuite.AddTest('TestFrameCountMatchesInput', @RunTTestParseCallStackTestFrameCountMatchesInput);
  lSuite:=ARegistry.AddSuite('ide.test.callstack.TTestCallStackFrameDisplay');
  lSuite.AddTest('TestDisplayWithSource', @RunTTestCallStackFrameDisplayTestDisplayWithSource);
  lSuite.AddTest('TestDisplayAddressOnly', @RunTTestCallStackFrameDisplayTestDisplayAddressOnly);
  lSuite.AddTest('TestDisplayUnknownNoAddress', @RunTTestCallStackFrameDisplayTestDisplayUnknownNoAddress);
  lSuite.AddTest('TestDisplayZeroAddress', @RunTTestCallStackFrameDisplayTestDisplayZeroAddress);
  lSuite.AddTest('TestDisplayHighFrameIndex', @RunTTestCallStackFrameDisplayTestDisplayHighFrameIndex);
end;

end.

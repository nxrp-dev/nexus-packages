unit utcprocess;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, pipes, process;

type

  { TTestProcess }

  TTestProcess= class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FProc: TProcess;
    FProc2: TProcess;
    FProc3: TProcess;
    procedure AssertFileContent(const aFileName, aContent: String);
    procedure AssertFileContent(const aFileName: String; aContent: array of string);
    procedure AssertGenOutLines(const S: String; aCount: integer);
    procedure AssertGenOutLinesFile(const aFileName : string; aCount : Integer);
    procedure CreateInputLinesFile(const aFileName : string; aCount : Integer);
    function GetHelper(const aHelper: string): String;
    function GetTestFile(const aName: string): String;
    function ReadProcessOutput(aProc: TProcess; ReadStdErr : Boolean = False): string;
    procedure WaitForFile(const aFileName: String);
  protected
    procedure CheckHelper(const aHelper : string);
    procedure SetUp; virtual;
    procedure TearDown; virtual;
    property Proc : TProcess read FProc;
    property Proc2 : TProcess read FProc2;
    property Proc3 : TProcess read FProc3;
  public
    procedure TestHookUp;
    procedure TestSimple;
    procedure TestSimpleParam;
    Procedure TestExitStatus;
    Procedure TestWaitFor;
    Procedure TestOptionWaitOnExit;
    Procedure TestTerminate;
    Procedure TestPipes;
    Procedure TestWritePipes;
    Procedure TestStdErr;
    Procedure TestStdErrToOutput;
    Procedure TestInputFile;
    Procedure TestOutputFile;
    Procedure TestStdErrFile;
    Procedure TestStdErrToStdOut;
    Procedure TestInputNull;
    Procedure TestOutputFileExistingAppend;
    Procedure TestOutputFileExistingTruncate;
    Procedure TestOutputFileExistingAtStart;
    Procedure TestPipeOut;
    Procedure TestPipeOutToFile;
    Procedure TestPipeInOutToFile;
    Procedure TestPipeRestart;
  end;

procedure RegisterutcprocessTests(ARegistry: TNXTestRegistry);

implementation

uses dateutils;

const
  dotouch = 'tdotouch';
  docat = 'tdocat';
  doexit = 'tdoexit';
  genout = 't_genout';
  fntouch = 'touch.txt';
  fntestoutput = 'output.txt';
  fntestinput = 'input.txt';

var
  TestDir : String;
  TmpDir : String;

procedure TTestProcess.AssertFileContent(const aFileName,aContent : String);
begin
  AssertFileContent(aFileName,[aContent]);
end;

procedure TTestProcess.AssertFileContent(const aFileName : String; aContent : Array of string);

var
  L : TStrings;
  I : integer;

begin
  L:=TStringList.Create;
  try
    L.LoadFromFile(aFileName);
    TestContext.AssertTrue((Length(aContent))=(L.Count), 'Line count');
    for I:=0 to L.Count-1 do
      TestContext.AssertTrue((aContent[I])=(L[i]), 'Line '+Inttostr(i)+'content');
  finally
    L.Free;
  end;

end;

Procedure TTestProcess.WaitForFile(const aFileName : String);

var
  aCount : Integer;
  FN : String;
  Exists : boolean;

begin
  FN:=aFileName;
  aCount:=0;
  Repeat
    Sleep(20);
    Inc(aCount);
    Exists:=FileExists(FN);
  Until (aCount>=50) or Exists;
  TestContext.AssertTrue(Exists, 'File did not appear: '+FN);
  Sleep(20);
end;

procedure TTestProcess.TestHookUp;



  procedure AssertNoFile(const FN :string);
  begin
    TestContext.AssertTrue(not (FileExists(FN)), 'File '+FN+' does not exist');
  end;

begin
  TestContext.AssertTrue((Proc)<>nil, 'Have process 1');
  TestContext.AssertTrue((Proc2)<>nil, 'Have process 2');
  TestContext.AssertTrue((Proc3)<>nil, 'Have process 3');
  AssertNoFile(fntouch);
  AssertNoFile(GetTestFile(fnTouch));
  AssertNoFile(GetTestFile(fntestoutput));
end;

procedure TTestProcess.TestSimple;

begin
  Proc.Executable:=GetHelper(dotouch);
  Proc.Execute;
  TestContext.AssertTrue((Proc.Input)=nil, 'no input stream');
  TestContext.AssertTrue((Proc.Output)=nil, 'no output stream');
  TestContext.AssertTrue((Proc.Stderr)=nil, 'no error stream');
  WaitForFile(fntouch);
  AssertFileContent(fntouch,fntouch);
end;

procedure TTestProcess.TestSimpleParam;

var
  FN : String;
begin
  FN:=GetTestFile(fntouch);
  Proc.Executable:=GetHelper(dotouch);
  Proc.Parameters.Add(FN);
  Proc.Execute;
  WaitForFile(FN);
  AssertFileContent(FN,FN);
end;

procedure TTestProcess.TestExitStatus;
// Test that halt(23) results in 23...
begin
  Proc.Executable:=GetHelper(doexit);
  Proc.Parameters.Add('23');
  Proc.Execute;
  Proc.WaitOnExit;
  TestContext.AssertTrue((23)=(Proc.ExitStatus), 'Exit code');
end;

procedure TTestProcess.TestWaitFor;

var
  N : TDateTime;
  ms : Int64;

begin
  Proc.Executable:=GetHelper(doexit);
  Proc.Parameters.Add('0');
  Proc.Parameters.Add('1000');
  N:=Now;
  Proc.Execute;
  Proc.WaitOnExit;
  ms:=MilliSecondsBetween(Now,N);
  TestContext.AssertTrue((0)=(Proc.ExitStatus), 'Exit code');
  TestContext.AssertTrue(ms>900, 'Wait time');

end;

procedure TTestProcess.TestOptionWaitOnExit;
var
  N : TDateTime;
  ms : Int64;

begin
  Proc.Executable:=GetHelper(doexit);
  Proc.Parameters.Add('0');
  Proc.Parameters.Add('1000');
  N:=Now;
  Proc.Options:=Proc.Options+[poWaitOnExit];
  Proc.Execute;
  ms:=MilliSecondsBetween(Now,N);
  TestContext.AssertTrue((0)=(Proc.ExitStatus), 'Exit code');
  TestContext.AssertTrue(ms>900, 'Wait time');
end;

procedure TTestProcess.TestTerminate;

var
  N : TDateTime;
  ms : Int64;

begin
  Proc.Executable:=GetHelper(doexit);
  Proc.Parameters.Add('0');
  Proc.Parameters.Add('2000');
  N:=Now;
  Proc.Execute;
  Sleep(500);
  Proc.Terminate(23);
  ms:=MilliSecondsBetween(Now,N);
  TestContext.AssertTrue(ms<1000, 'Process exits at once');
{$IFDEF UNIX}
  // Also check Kill if term will not work
  TestContext.AssertTrue((15=Proc.ExitStatus) or (9=Proc.ExitStatus), 'Exit status');
{$ENDIF}
{$IFDEF WINDOWS}
  // Check exit status provided to terminate.
  TestContext.AssertTrue((23=Proc.ExitCode), 'Exit status');
{$ENDIF}
end;

procedure TTestProcess.AssertGenOutLines(const S : String; aCount : integer);

var
  L : TStrings;
  I : Integer;

begin
  sleep(100);
//  Writeln('Testing >>',S,'<<');
  L:=TStringList.Create;
  try
    L.Text:=S;
    TestContext.AssertTrue((aCount)=(L.Count), 'Count');
    For I:=1 to aCount do
      TestContext.AssertTrue(('Line '+IntToStr(I))=(L[I-1]), 'Content Line '+IntToStr(I));
  finally
    L.Free;
  end;
end;

procedure TTestProcess.AssertGenOutLinesFile(const aFileName: string; aCount: Integer);
var
  L : TStrings;
  I : Integer;

begin
  sleep(100);
  // Writeln('Testing file >>',aFileName,'<<');
  L:=TStringList.Create;
  try
    L.LoadFromFile(aFileName);
    TestContext.AssertTrue((aCount)=(L.Count), 'Count');
    For I:=1 to aCount do
      TestContext.AssertTrue(('Line '+IntToStr(I))=(L[I-1]), 'Content Line '+IntToStr(I));
  finally
    L.Free;
  end;
end;

procedure TTestProcess.CreateInputLinesFile(const aFileName: string; aCount: Integer);
var
  L : TStrings;
  I : Integer;

begin
  // Writeln('Creating Test file >>',aFileName,'<<');
  L:=TStringList.Create;
  try
    For I:=1 to aCount do
      L.Add('Line '+IntToStr(I));
    L.SaveToFile(aFileName);
  finally
    L.Free;
  end;
end;

function TTestProcess.ReadProcessOutput(aProc: TProcess; ReadStdErr: Boolean): string;

var
  aRead,aLen: Integer;
  S : String;
  St : TInputPipeStream;
begin
  aRead:=0;
  aLen:=0;
  S:='';
  Sleep(100);
  if ReadStdErr then
    st:=aProc.StdErr
  else
    st:=aProc.Output;
  TestContext.AssertTrue((St)<>nil, 'Have stream to read output from');
  TestContext.AssertTrue(aProc.ReadInputStream(St,aRead,aLen,S,100), 'Read input');
  SetLength(S,aRead);
//  Writeln('>>>',S,'<<<');
  Result:=S;
end;

procedure TTestProcess.TestPipes;

var
  S : String;

begin
  Proc.Executable:=GetHelper(genout);
  Proc.Options:=[poUsePipes];
  Proc.Execute;
  TestContext.AssertTrue((Proc.Input)<>nil, 'input stream');
  TestContext.AssertTrue((Proc.Output)<>nil, 'output stream');
  TestContext.AssertTrue((Proc.Stderr)<>nil, 'error stream');
  S:=ReadProcessOutput(Proc);
  AssertGenOutLines(S,3);
end;

procedure TTestProcess.TestWritePipes;
var
  Sin,Sout : String;

begin
  Proc.Executable:=GetHelper(docat);
  Proc.Options:=[poUsePipes];
  Proc.Execute;
  // Note: this test will only work for small amounts of data, less than pipe buffer size.
  Sin:='this is some text'+sLineBreak+'And some more text'+sLineBreak;
  Proc.Input.Write(Sin[1],Length(Sin));
  Proc.CloseInput;
  SOut:=ReadProcessOutput(Proc);
  TestContext.AssertTrue((SIn)=(Sout), 'Out equals in');
end;

procedure TTestProcess.TestStdErr;
var
  S : String;

begin
  Proc.Executable:=GetHelper(genout);
  Proc.Parameters.Add('-3');
  Proc.Options:=[poUsePipes];
  Proc.Execute;
  S:=ReadProcessOutput(Proc,true);
  AssertGenOutLines(S,3);
end;

procedure TTestProcess.TestStdErrToOutput;
var
  S : String;

begin
  Proc.Executable:=GetHelper(genout);
  Proc.Parameters.Add('-3');
  Proc.Options:=[poUsePipes,poStderrToOutPut];
  Proc.Execute;
  S:=ReadProcessOutput(Proc);
  AssertGenOutLines(S,3);
end;

procedure TTestProcess.TestInputFile;

var
  S : String;

begin
  CreateInputLinesFile(GetTestFile(fntestinput),3);
  Proc.Executable:=GetHelper(docat);
  Proc.InputDescriptor.FileName:=GetTestFile(fntestinput);
  TestContext.AssertTrue(Proc.InputDescriptor.IOType=iotFile, 'Descriptor IOType');
  Proc.OutputDescriptor.IOType:=iotPipe;
  Proc.Execute;
  TestContext.AssertTrue((Proc.Input)=nil, 'input stream');
  TestContext.AssertTrue((Proc.Output)<>nil, 'output stream');
  TestContext.AssertTrue((Proc.Stderr)=nil, 'error stream');
  S:=ReadProcessOutput(Proc);
  AssertGenOutLines(S,3);
end;

procedure TTestProcess.TestOutputFile;

begin
  Proc.Executable:=GetHelper(genout);
  Proc.OutputDescriptor.FileName:=GetTestFile(fntestoutput);
  Proc.Execute;
  AssertGenOutLinesFile(GetTestFile(fntestoutput),3);
end;

procedure TTestProcess.TestStdErrFile;
begin
  Proc.Executable:=GetHelper(genout);
  Proc.Parameters.Add('-3');
  Proc.ErrorDescriptor.FileName:=GetTestFile(fntestoutput);
  Proc.Execute;
  AssertGenOutLinesFile(GetTestFile(fntestoutput),3);
end;

procedure TTestProcess.TestStdErrToStdOut;
begin
  Proc.Executable:=GetHelper(genout);
  Proc.Options:=Proc.Options+[poStderrToOutPut];
  Proc.Parameters.Add('-3');
  Proc.OutputDescriptor.FileName:=GetTestFile(fntestoutput);
  Proc.Execute;
  AssertGenOutLinesFile(GetTestFile(fntestoutput),3);
end;

procedure TTestProcess.TestInputNull;

var
  B : TBytes;

begin
  Proc.Executable:=GetHelper(docat);
  Proc.InputDescriptor.IOType:=iotNull;
  Proc.OutputDescriptor.FileName:=GetTestFile(fntestoutput);
  Proc.Execute;
  Sleep(100);
  B:=Sysutils.GetFileContents(GetTestFile(fntestoutput));
  TestContext.AssertTrue((0)=(Length(B)), 'Empty file');
end;

procedure TTestProcess.TestOutputFileExistingAppend;
// Check that we actually append
begin
  CreateInputLinesFile(GetTestFile(fntestoutput),3);
  Proc.Executable:=GetHelper(genout);
  Proc.Parameters.add('3');
  Proc.Parameters.add('3');
  Proc.OutputDescriptor.FileName:=GetTestFile(fntestoutput);
  Proc.OutputDescriptor.FileWriteMode:=fwmAppend;
  Proc.Execute;
  AssertGenOutLinesFile(GetTestFile(fntestoutput),6);

end;

procedure TTestProcess.TestOutputFileExistingTruncate;
// Check that we actually rewrite
begin
  CreateInputLinesFile(GetTestFile(fntestoutput),6);
  AssertGenOutLinesFile(GetTestFile(fntestoutput),6);
  Proc.Executable:=GetHelper(genout);
  Proc.OutputDescriptor.FileName:=GetTestFile(fntestoutput);
  Proc.OutputDescriptor.FileWriteMode:=fwmTruncate;
  Proc.Execute;
  AssertGenOutLinesFile(GetTestFile(fntestoutput),3);
end;

procedure TTestProcess.TestOutputFileExistingAtStart;
// Check that we actually write at start of file...
// Write file with 6 lines (1-6), overwrite files with first 3 lines 7-9
// Result has 7 - 8 - 9 - 4 - 5 -6

var
  L : TStrings;
  I : Integer;
begin
  CreateInputLinesFile(GetTestFile(fntestoutput),6);
  Proc.Executable:=GetHelper(genout);
  Proc.Parameters.add('3');
  Proc.Parameters.add('6'); // Offset 6, so first output line is 7
  Proc.OutputDescriptor.FileName:=GetTestFile(fntestoutput);
  Proc.OutputDescriptor.FileWriteMode:=fwmAtStart;
  Proc.Execute;
  sleep(100);
  // Writeln('Testing file >>',aFileName,'<<');
  L:=TStringList.Create;
  try
    L.LoadFromFile(GetTestFile(fntestoutput));
    TestContext.AssertTrue((6)=(L.Count), 'Count');
    For I:=1 to 3 do
      TestContext.AssertTrue(('Line '+IntToStr(I+6))=(L[I-1]), 'Content Line '+IntToStr(I));
    For I:=4 to 6 do
      TestContext.AssertTrue(('Line '+IntToStr(I))=(L[I-1]), 'Content Line '+IntToStr(I));
  finally
    L.Free;
  end;

end;

procedure TTestProcess.TestPipeOut;
{ Simulate
  genout | docat
  we read output of docat.
}
var
  S : String;

begin
  Proc.Executable:=GetHelper(genout);
  Proc2.Executable:=GetHelper(docat);
  Proc2.OutputDescriptor.IOType:=iotPipe;
  Proc.OutputDescriptor.Process:=Proc2;
  TestContext.AssertTrue(Proc2.InputDescriptor.IOType=iotPipe, 'Proc2 input is pipe');
  Proc2.Execute;
  Proc.execute;
  S:=ReadProcessOutput(Proc2);
  AssertGenOutLines(S,3);
end;

procedure TTestProcess.TestPipeOutToFile;

{ Simulate
  genout | docat > file
  we read output from file
}
var
  S : String;

begin
  Proc.Executable:=GetHelper(genout);
  Proc2.Executable:=GetHelper(docat);
  Proc2.OutputDescriptor.FileName:=GetTestFile(fntestoutput);
  Proc.OutputDescriptor.Process:=Proc2;
  TestContext.AssertTrue(Proc2.InputDescriptor.IOType=iotPipe, 'Proc2 input is pipe');
  Proc2.Execute;
  Proc.execute;
  AssertGenOutLinesFile(GetTestFile(fntestoutput),3);
end;

procedure TTestProcess.TestPipeInOutToFile;
{ Simulate
  docat <input | docat > file
  we read output from file
}
var
  S : String;

begin
  CreateInputLinesFile(GetTestFile(fntestinput),3);
  Proc.Executable:=GetHelper(docat);
  Proc.InputDescriptor.FileName:=GetTestFile(fntestinput);
  Proc2.Executable:=GetHelper(docat);
  Proc2.OutputDescriptor.FileName:=GetTestFile(fntestoutput);
  Proc.OutputDescriptor.Process:=Proc2;
  TestContext.AssertTrue(Proc2.InputDescriptor.IOType=iotPipe, 'Proc2 input is pipe');
  Proc2.Execute;
  Proc.execute;
  AssertGenOutLinesFile(GetTestFile(fntestoutput),3);
end;

procedure TTestProcess.TestPipeRestart;
begin
end;

function TTestProcess.GetTestFile(const aName: string) : String;

begin
  if TmpDir='' then
    TmpDir:=GetTempDir(False);
  Result:=IncludeTrailingPathDelimiter(TmpDir)+aName;
end;

function TTestProcess.GetHelper(const aHelper: string) : String;
begin
  if TestDir='' then
    TestDir:=ExtractFilePath(ParamStr(0));
  Result:=IncludeTrailingPathDelimiter(TestDir)+aHelper;
  {$IFDEF WINDOWS}
  Result:=Result+'.exe';
  {$ENDIF}
end;

procedure TTestProcess.CheckHelper(const aHelper: string);
var
  F : String;
begin
  F:=GetHelper(aHelper);
  TestContext.AssertTrue(FileExists(F), 'No helper '+F+' please compile '+aHelper+'.pas');
end;

procedure TTestProcess.SetUp;
begin
  FProc:=TProcess.Create(Nil);
  FProc2:=TProcess.Create(Nil);
  FProc3:=TProcess.Create(Nil);
  // CheckHelper(dols);
  CheckHelper(genout);
  CheckHelper(docat);
  CheckHelper(dotouch);
  CheckHelper(doexit);
  DeleteFile(fntouch);
  DeleteFile(GetTestFile(fntouch));
  DeleteFile(GetTestFile(fntestoutput));
end;

procedure TTestProcess.TearDown;
begin
  FreeAndNil(FProc);
end;


constructor TTestProcess.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestProcessTestHookUp(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestHookUp');
  try
    lFixture.SetUp;
    try lFixture.TestHookUp; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestSimple(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestSimple');
  try
    lFixture.SetUp;
    try lFixture.TestSimple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestSimpleParam(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestSimpleParam');
  try
    lFixture.SetUp;
    try lFixture.TestSimpleParam; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestExitStatus(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestExitStatus');
  try
    lFixture.SetUp;
    try lFixture.TestExitStatus; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestWaitFor(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestWaitFor');
  try
    lFixture.SetUp;
    try lFixture.TestWaitFor; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestOptionWaitOnExit(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestOptionWaitOnExit');
  try
    lFixture.SetUp;
    try lFixture.TestOptionWaitOnExit; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestTerminate(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestTerminate');
  try
    lFixture.SetUp;
    try lFixture.TestTerminate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestPipes(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestPipes');
  try
    lFixture.SetUp;
    try lFixture.TestPipes; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestWritePipes(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestWritePipes');
  try
    lFixture.SetUp;
    try lFixture.TestWritePipes; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestStdErr(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestStdErr');
  try
    lFixture.SetUp;
    try lFixture.TestStdErr; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestStdErrToOutput(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestStdErrToOutput');
  try
    lFixture.SetUp;
    try lFixture.TestStdErrToOutput; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestInputFile(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestInputFile');
  try
    lFixture.SetUp;
    try lFixture.TestInputFile; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestOutputFile(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestOutputFile');
  try
    lFixture.SetUp;
    try lFixture.TestOutputFile; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestStdErrFile(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestStdErrFile');
  try
    lFixture.SetUp;
    try lFixture.TestStdErrFile; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestStdErrToStdOut(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestStdErrToStdOut');
  try
    lFixture.SetUp;
    try lFixture.TestStdErrToStdOut; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestInputNull(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestInputNull');
  try
    lFixture.SetUp;
    try lFixture.TestInputNull; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestOutputFileExistingAppend(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestOutputFileExistingAppend');
  try
    lFixture.SetUp;
    try lFixture.TestOutputFileExistingAppend; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestOutputFileExistingTruncate(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestOutputFileExistingTruncate');
  try
    lFixture.SetUp;
    try lFixture.TestOutputFileExistingTruncate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestOutputFileExistingAtStart(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestOutputFileExistingAtStart');
  try
    lFixture.SetUp;
    try lFixture.TestOutputFileExistingAtStart; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestPipeOut(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestPipeOut');
  try
    lFixture.SetUp;
    try lFixture.TestPipeOut; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestPipeOutToFile(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestPipeOutToFile');
  try
    lFixture.SetUp;
    try lFixture.TestPipeOutToFile; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestPipeInOutToFile(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestPipeInOutToFile');
  try
    lFixture.SetUp;
    try lFixture.TestPipeInOutToFile; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcessTestPipeRestart(AContext: TNXTestContext);
var lFixture: TTestProcess;
begin
  lFixture:=TTestProcess.Create(AContext, 'TestPipeRestart');
  try
    lFixture.SetUp;
    try lFixture.TestPipeRestart; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegisterutcprocessTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('utcprocess.TTestProcess');
  lSuite.AddTest('TestHookUp', @RunTTestProcessTestHookUp);
  lSuite.AddTest('TestSimple', @RunTTestProcessTestSimple);
  lSuite.AddTest('TestSimpleParam', @RunTTestProcessTestSimpleParam);
  lSuite.AddTest('TestExitStatus', @RunTTestProcessTestExitStatus);
  lSuite.AddTest('TestWaitFor', @RunTTestProcessTestWaitFor);
  lSuite.AddTest('TestOptionWaitOnExit', @RunTTestProcessTestOptionWaitOnExit);
  lSuite.AddTest('TestTerminate', @RunTTestProcessTestTerminate);
  lSuite.AddTest('TestPipes', @RunTTestProcessTestPipes);
  lSuite.AddTest('TestWritePipes', @RunTTestProcessTestWritePipes);
  lSuite.AddTest('TestStdErr', @RunTTestProcessTestStdErr);
  lSuite.AddTest('TestStdErrToOutput', @RunTTestProcessTestStdErrToOutput);
  lSuite.AddTest('TestInputFile', @RunTTestProcessTestInputFile);
  lSuite.AddTest('TestOutputFile', @RunTTestProcessTestOutputFile);
  lSuite.AddTest('TestStdErrFile', @RunTTestProcessTestStdErrFile);
  lSuite.AddTest('TestStdErrToStdOut', @RunTTestProcessTestStdErrToStdOut);
  lSuite.AddTest('TestInputNull', @RunTTestProcessTestInputNull);
  lSuite.AddTest('TestOutputFileExistingAppend', @RunTTestProcessTestOutputFileExistingAppend);
  lSuite.AddTest('TestOutputFileExistingTruncate', @RunTTestProcessTestOutputFileExistingTruncate);
  lSuite.AddTest('TestOutputFileExistingAtStart', @RunTTestProcessTestOutputFileExistingAtStart);
  lSuite.AddTest('TestPipeOut', @RunTTestProcessTestPipeOut);
  lSuite.AddTest('TestPipeOutToFile', @RunTTestProcessTestPipeOutToFile);
  lSuite.AddTest('TestPipeInOutToFile', @RunTTestProcessTestPipeInOutToFile);
  lSuite.AddTest('TestPipeRestart', @RunTTestProcessTestPipeRestart);
end;

end.

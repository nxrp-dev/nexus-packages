unit regtcxmlreg;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, xmlreg;

Type

  { TTestXMLRegistry }

  TTestXMLRegistry = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FXMLReg: TXmlRegistry;
  Protected
    Procedure Setup; virtual;
    Procedure TearDown; virtual;
    Property XMLReg : TXmlRegistry Read FXMLReg;
  public
    Procedure TestReadBufDataDWord;
    Procedure TestReadBufDataString;
    Procedure TestReadBufDataBinary;
  end;


procedure RegisterregtcxmlregTests(ARegistry: TNXTestRegistry);

implementation

{ TTestXMLRegistry }

procedure TTestXMLRegistry.Setup;
begin

  DeleteFile('test.xml');
  FXMLReg:=TXmlRegistry.Create('test.xml');
end;

procedure TTestXMLRegistry.TearDown;
begin
  FreeAndNil(FXMLReg);
  DeleteFile('test.xml');

end;

procedure TTestXMLRegistry.TestReadBufDataDWord;

Var
  C : Cardinal;
  I : Smallint;
  DS : Integer;
  dt : TDataType;

begin
  XMLReg.SetKey('a',True);
  C:=123456;
  XMLReg.SetValueData('b',dtDWORD,C,SizeOf(C));
  XMLReg.Flush;
  DS:=SizeOf(SmallInt);
  TestContext.AssertTrue((False)=(XMLReg.GetValueData('b',dt,I,ds)), 'Cannot read, buffer size too small');
  TestContext.AssertTrue(dt=dtDWord, 'Correct data type reported');
  TestContext.AssertTrue((SizeOf(C))=(DS), 'Correct data buffer size reported');

end;

procedure TTestXMLRegistry.TestReadBufDataString;

Var
  S1,S2 : String;
  DS : Integer;
  dt : TDataType;

begin
  XMLReg.SetKey('a',True);
  S1:=StringOfChar('*',100);
  XMLReg.SetValueData('b',dtString,S1[1],Length(S1));
  XMLReg.Flush;
  DS:=SizeOf(S1) div 2;
  S2:=StringOfChar('*',DS);
  TestContext.AssertTrue((False)=(XMLReg.GetValueData('b',dt,S2[1],ds)), 'Cannot read, buffer size too small');
  TestContext.AssertTrue(dt=dtString, 'Correct data type reported');
  TestContext.AssertTrue((Length(S1))=(DS), 'Correct data buffer size reported');
end;

procedure TTestXMLRegistry.TestReadBufDataBinary;
Var
  S1,S2 : Array of byte;
  I : Smallint;
  DS : Integer;
  dt : TDataType;

begin
  XMLReg.SetKey('a',True);
  SetLength(S1,100);
  For I:=0 to 99 do
    S1[I]:=i;
  XMLReg.SetValueData('b',dtBinary,S1[0],Length(S1));
  XMLReg.Flush;
  DS:=Length(S1) div 4;
  SetLength(S2,DS);
  For I:=0 to DS-1 do
    S2[I]:=i;
  TestContext.AssertTrue((False)=(XMLReg.GetValueData('b',dt,S2[0],DS)), 'Cannot read, buffer size too small');
  TestContext.AssertTrue(dt=dtBinary, 'Correct data type reported');
  TestContext.AssertTrue((Length(S1))=(DS), 'Correct data buffer size reported');
end;


constructor TTestXMLRegistry.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestXMLRegistryTestReadBufDataDWord(AContext: TNXTestContext);
var lFixture: TTestXMLRegistry;
begin
  lFixture:=TTestXMLRegistry.Create(AContext, 'TestReadBufDataDWord');
  try
    lFixture.SetUp;
    try lFixture.TestReadBufDataDWord; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestXMLRegistryTestReadBufDataString(AContext: TNXTestContext);
var lFixture: TTestXMLRegistry;
begin
  lFixture:=TTestXMLRegistry.Create(AContext, 'TestReadBufDataString');
  try
    lFixture.SetUp;
    try lFixture.TestReadBufDataString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestXMLRegistryTestReadBufDataBinary(AContext: TNXTestContext);
var lFixture: TTestXMLRegistry;
begin
  lFixture:=TTestXMLRegistry.Create(AContext, 'TestReadBufDataBinary');
  try
    lFixture.SetUp;
    try lFixture.TestReadBufDataBinary; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegisterregtcxmlregTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('regtcxmlreg.TTestXMLRegistry');
  lSuite.AddTest('TestReadBufDataDWord', @RunTTestXMLRegistryTestReadBufDataDWord);
  lSuite.AddTest('TestReadBufDataString', @RunTTestXMLRegistryTestReadBufDataString);
  lSuite.AddTest('TestReadBufDataBinary', @RunTTestXMLRegistryTestReadBufDataBinary);
end;

end.

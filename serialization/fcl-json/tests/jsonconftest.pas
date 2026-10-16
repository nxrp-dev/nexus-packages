unit jsonconftest;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, jsonconf;

type

  { TTestJSONConfig }

  TTestJSONConfig= class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  Private
    procedure AssertStrings(Msg: String; L: TStrings;
      const Values: array of string);
    Function CreateConf(AFileName : String) : TJSONCOnfig;
    Procedure DeleteConf(C : TJSONConfig; DeleteConfFile : Boolean = true);
  public
    procedure TestDataTypes;
    procedure TestSubNodes;
    procedure TestEnumSubkeys;
    procedure TestEnumValues;
    procedure TestClear;
    procedure TestKey;
    procedure TestStrings;
    procedure TestUnicodeStrings;
    procedure TestUnicodeStrings2;
  end;

procedure RegisterjsonconftestTests(ARegistry: TNXTestRegistry);

implementation

function TTestJSONConfig.CreateConf(AFileName: String): TJSONCOnfig;
begin
  Result:=TJSONConfig.Create(Nil);
  Result.FileName:=AFileName;
end;

procedure TTestJSONConfig.DeleteConf(C: TJSONConfig; DeleteConfFile: Boolean);

Var
  FN : String;

begin
  If DeleteConfFile then
    FN:=C.FileName;
  FreeAndNil(C);
  If DeleteConfFile then
    DeleteFile(FN);
end;

procedure TTestJSONConfig.TestDataTypes;

Const
  A = Integer(1);
  B = 'A string';
  C = 1.23;
  D = True;
  E = Int64($FFFFFFFFFFFFF);

Var
  Co : TJSONCOnfig;

begin
  Co:=CreateConf('test.json');
  try
    Co.SetValue('a',a);
    TestContext.AssertTrue((a)=(Co.GetValue('a',0)), 'Integer read/Write');
    Co.SetValue('b',b);
    TestContext.AssertTrue((b)=(Co.GetValue('b','')), 'String read/Write');
    Co.SetValue('c',C);
    TestContext.AssertTrue(Abs((c)-(Co.GetValue('c',0.0)))<=(0.01), 'Float read/Write');
    Co.SetValue('d',d);
    TestContext.AssertTrue((d)=(Co.GetValue('d',False)), 'Boolean read/Write');
    Co.SetValue('e',E);
    TestContext.AssertTrue((e)=(Co.GetValue('e',Int64(0))), 'Int64 read/Write');
    Co.Flush;
  finally
    DeleteConf(Co,True);
  end;
end;

procedure TTestJSONConfig.TestSubNodes;

Var
  C : TJSONCOnfig;

begin
  C:=CreateConf('test.json');
  try
    C.SetValue('a',1);
    TestContext.AssertTrue((1)=(C.GetValue('a',0)), 'Read at root');
    C.SetValue('b/a',2);
    TestContext.AssertTrue((2)=(C.GetValue('b/a',2)), 'Read at root');
    C.SetValue('b/c/a',3);
    TestContext.AssertTrue((3)=(C.GetValue('b/c/a',3)), 'Read at root');
  finally
    DeleteConf(C,True);
  end;
end;

procedure TTestJSONConfig.TestEnumSubkeys;
Var
  C : TJSONCOnfig;
  L : TStringList;

begin
  C:=CreateConf('test.json');
  try
    C.SetValue('/a',1);
    C.SetValue('/b/a',2);
    C.SetValue('/b/b',2);
    C.SetValue('/c/a',3);
    C.SetValue('/c/b/a',4);
    C.SetValue('/c/c/a',4);
    C.SetValue('/c/d/d',4);
    L:=TStringList.Create;
    try
      C.EnumSubKeys('/',L);
      If (L.Count<>2) then
        TestContext.Fail('EnumSubkeys count');
      If (L[0]<>'b') then
        TestContext.Fail('EnumSubkeys first element');
      If (L[1]<>'c') then
        TestContext.Fail('EnumSubkeys second element');
    finally
      L.Free;
    end;
  finally
    DeleteConf(C,True);
  end;
end;

procedure TTestJSONConfig.TestEnumValues;
Var
  C : TJSONCOnfig;
  L : TStringList;

begin
  C:=CreateConf('test.json');
  try
    C.SetValue('/a',1);
    C.SetValue('/b/a',2);
    C.SetValue('/b/b',2);
    C.SetValue('/c/a',3);
    C.SetValue('/c/b/a',4);
    C.SetValue('/c/c/a',4);
    C.SetValue('/c/d/d',4);
    L:=TStringList.Create;
    try
      C.EnumValues('/',L);
      If (L.Count<>1) then
        TestContext.Fail('EnumValues count');
      If (L[0]<>'a') then
        TestContext.Fail('EnumValues first element');
      L.Clear;
      C.EnumValues('/b',L);
      If (L.Count<>2) then
        TestContext.Fail('EnumValues subkey count');
      If (L[0]<>'a') then
        TestContext.Fail('EnumValues subkey first element');
      If (L[1]<>'b') then
        TestContext.Fail('EnumValues subkey second element');
    finally
      L.Free;
    end;
  finally
    DeleteConf(C,True);
  end;
end;

procedure TTestJSONConfig.TestClear;

Var
  C : TJSONCOnfig;

begin
  C:=CreateConf('test.json');
  try
    C.SetValue('a',1);
    C.Flush;
    C.DeleteValue('a');
    TestContext.AssertTrue((True)=(C.Modified), 'Modified set');
    TestContext.AssertTrue((0)=(C.GetValue('a',0)), 'Delete value');
    C.SetValue('b/a',1);
    C.SetValue('b/c',2);
    C.DeleteValue('b/a');
    TestContext.AssertTrue((0)=(C.GetValue('a',0)), 'Delete value in subkey');
    TestContext.AssertTrue((2)=(C.GetValue('b/c',0)), 'Delete value only clears deleted value');
    C.SetValue('b/a',1);
    C.Flush;
    C.DeletePath('b');
    TestContext.AssertTrue((True)=(C.Modified), 'Modified set');
    TestContext.AssertTrue((0)=(C.GetValue('b/a',0)), 'Delete path');
    TestContext.AssertTrue((0)=(C.GetValue('b/c',0)), 'Delete path deletes all values');
    C.Clear;
    TestContext.AssertTrue((0)=(C.GetValue('/a',0)), 'Clear');
  finally
    DeleteConf(C,True);
  end;
end;

procedure TTestJSONConfig.TestKey;

Var
  C : TJSONCOnfig;
  L : TStrings;

begin
  C:=CreateConf('test.json');
  try
    C.SetValue('a',1);
    C.SetValue('b/a',2);
    C.SetValue('b/b',2);
    C.SetValue('b/c/a',3);
    C.SetValue('b/c/b',3);
    C.OpenKey('/b',False);
    TestContext.AssertTrue((2)=(C.GetValue('a',0)), 'Read relative to key a');
    TestContext.AssertTrue((2)=(C.GetValue('b',0)), 'Read relative to key b');
    TestContext.AssertTrue((3)=(C.GetValue('c/a',0)), 'Read in subkey relative to key a');
    TestContext.AssertTrue((3)=(C.GetValue('c/b',0)), 'Read in subkey relative to key b');
    TestContext.AssertTrue((1)=(C.GetValue('/a',0)), 'Read absolute, disregarding key');
    TestContext.AssertTrue((2)=(C.GetValue('/b/a',0)), 'Read absolute in subkey, disregarding key');
    TestContext.AssertTrue((3)=(C.GetValue('/b/c/a',0)), 'Read absolute in subkeys, disregarding key');
    C.CloseKey;
    TestContext.AssertTrue((1)=(C.GetValue('a',0)), 'Closekey');
    C.OpenKey('b',False);
    C.OpenKey('c',False);
    TestContext.AssertTrue((3)=(C.GetValue('a',0)), 'Open relative key');
    C.ResetKey;
    TestContext.AssertTrue((1)=(C.GetValue('a',0)), 'ResetKey');
    C.Clear;
    L:=TStringList.Create;
    try
      C.EnumSubKeys('/',L);
      If (L.Count<>0) then
        TestContext.Fail('clear failed');
      C.OpenKey('/a/b/c/d',true);
      C.EnumSubKeys('/a',L);
      If (L.Count<>1) then
        TestContext.Fail('Open key with allowcreate, level 1');
      If (L[0]<>'b') then
        TestContext.Fail('Open key with allowcreate, level 1');
      L.Clear;
      C.EnumSubKeys('/a/b',L);
      If (L.Count<>1) then
        TestContext.Fail('Open key with allowcreate, level 2');
      If (L[0]<>'c') then
        TestContext.Fail('Open key with allowcreate, level 2');
      L.Clear;
      C.EnumSubKeys('/a/b/c',L);
      If (L.Count<>1) then
        TestContext.Fail('Open key with allowcreate, level 3');
      If (L[0]<>'d') then
        TestContext.Fail('Open key with allowcreate, level 3');
    finally
      L.Free;
    end;
  finally
    DeleteConf(C,True);
  end;
end;

procedure TTestJSONConfig.AssertStrings(Msg: String; L: TStrings;
  const Values: array of string);

Var
  I : Integer;
begin
  Msg:=Msg+': ';
  TestContext.AssertTrue((L)<>nil, Msg+'Have strings');
  TestContext.AssertTrue((Length(Values))=(L.Count), Msg+'Correct element count');
  For I:=0 to L.Count-1 do
    TestContext.AssertTrue((Values[i])=(l[i]), Msg+'element '+IntToStr(i));
end;

procedure TTestJSONConfig.TestStrings;

Var
  C : TJSONCOnfig;
  L,LD : TStrings;

begin
  L:=Nil;
  LD:=Nil;
  C:=CreateConf('test.json');
  try
    L:=TStringList.Create;
    LD:=TStringList.Create;
    L.Add('abc');
    C.GetValue('list',L,'');
    AssertStrings('Clear, no default.',L,[]);
    C.GetValue('list',L,'text');
    AssertStrings('Use default.',L,['text']);
    L.Clear;
    L.Add('abc');
    L.Add('def');
    C.SetValue('a',L);
    C.GetValue('a',LD,'');
    AssertStrings('List',LD,['abc','def']);
    L.Clear;
    L.Add('abc=1');
    L.Add('def=2');
    C.SetValue('a',L,True);
    LD.Clear;
    C.GetValue('a',LD,'');
    AssertStrings('List',LD,['abc=1','def=2']);
    C.SetValue('a','abc');
    C.GetValue('a',L,'');
    AssertStrings('String',L,['abc']);
    C.SetValue('a','a'#1#2);
    C.GetValue('a',L,'');
    AssertStrings('String',L,['a'#1#2]);
    C.SetValue('a',Integer(1));
    C.GetValue('a',L,'');
    AssertStrings('integer',L,['1']);
    C.SetValue('a',True);
    C.GetValue('a',L,'');
    AssertStrings('integer',L,['true']);
    C.SetValue('a',Int64(1));
    C.GetValue('a',L,'');
    AssertStrings('int64',L,['1']);
  finally
    L.Free;
    DeleteConf(C,True);
  end;
end;

procedure TTestJSONConfig.TestUnicodeStrings;

Const
  utf8str = 'Größe ÄÜÖ ㎰ す 가';
  utf8path = 'Größe/す가';

Var
  Co : TJSONCOnfig;


begin
  Co:=CreateConf('test.json');
  try
    Co.SetValue('a',utf8str);
    Co.SetValue(utf8path,'something');
    Co.Flush;
  finally
    co.Free;
  end;
  Co:=CreateConf('test.json');
  try
    TestContext.AssertTrue((utf8str)=(utf8encode(Co.GetValue('a',''))), 'UTF8 string read/Write');
    TestContext.AssertTrue(('something')=(Co.GetValue(utf8path,'something')), 'UTF8 path read/Write');
  finally
    DeleteConf(Co,True);
  end;
end;

procedure TTestJSONConfig.TestUnicodeStrings2;

Const
  utf8str = 'Größe ÄÜÖ ㎰ す 가';
  utf8path = 'Größe/す가';

Var
  Co : TJSONCOnfig;


begin
  Co:=CreateConf('test.json');
  try
    Co.SetValue('/проверка',utf8str);
    Co.SetValue(utf8path,'something');
    Co.Flush;
  finally
    co.Free;
  end;
  Co:=CreateConf('test.json');
  try
    TestContext.AssertTrue((utf8str)=(utf8encode(Co.GetValue('/проверка',''))), 'UTF8 string read/Write');
    TestContext.AssertTrue(('something')=(Co.GetValue(utf8path,'something')), 'UTF8 path read/Write');
  finally
    DeleteConf(Co,True);
  end;
end;



constructor TTestJSONConfig.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestJSONConfigTestDataTypes(AContext: TNXTestContext);
var lFixture: TTestJSONConfig;
begin
  lFixture:=TTestJSONConfig.Create(AContext, 'TestDataTypes');
  try
    lFixture.TestDataTypes;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConfigTestSubNodes(AContext: TNXTestContext);
var lFixture: TTestJSONConfig;
begin
  lFixture:=TTestJSONConfig.Create(AContext, 'TestSubNodes');
  try
    lFixture.TestSubNodes;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConfigTestEnumSubkeys(AContext: TNXTestContext);
var lFixture: TTestJSONConfig;
begin
  lFixture:=TTestJSONConfig.Create(AContext, 'TestEnumSubkeys');
  try
    lFixture.TestEnumSubkeys;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConfigTestEnumValues(AContext: TNXTestContext);
var lFixture: TTestJSONConfig;
begin
  lFixture:=TTestJSONConfig.Create(AContext, 'TestEnumValues');
  try
    lFixture.TestEnumValues;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConfigTestClear(AContext: TNXTestContext);
var lFixture: TTestJSONConfig;
begin
  lFixture:=TTestJSONConfig.Create(AContext, 'TestClear');
  try
    lFixture.TestClear;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConfigTestKey(AContext: TNXTestContext);
var lFixture: TTestJSONConfig;
begin
  lFixture:=TTestJSONConfig.Create(AContext, 'TestKey');
  try
    lFixture.TestKey;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConfigTestStrings(AContext: TNXTestContext);
var lFixture: TTestJSONConfig;
begin
  lFixture:=TTestJSONConfig.Create(AContext, 'TestStrings');
  try
    lFixture.TestStrings;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConfigTestUnicodeStrings(AContext: TNXTestContext);
var lFixture: TTestJSONConfig;
begin
  lFixture:=TTestJSONConfig.Create(AContext, 'TestUnicodeStrings');
  try
    lFixture.TestUnicodeStrings;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConfigTestUnicodeStrings2(AContext: TNXTestContext);
var lFixture: TTestJSONConfig;
begin
  lFixture:=TTestJSONConfig.Create(AContext, 'TestUnicodeStrings2');
  try
    lFixture.TestUnicodeStrings2;
  finally lFixture.Free; end;
end;

procedure RegisterjsonconftestTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('jsonconftest.TTestJSONConfig');
  lSuite.AddTest('TestDataTypes', @RunTTestJSONConfigTestDataTypes);
  lSuite.AddTest('TestSubNodes', @RunTTestJSONConfigTestSubNodes);
  lSuite.AddTest('TestEnumSubkeys', @RunTTestJSONConfigTestEnumSubkeys);
  lSuite.AddTest('TestEnumValues', @RunTTestJSONConfigTestEnumValues);
  lSuite.AddTest('TestClear', @RunTTestJSONConfigTestClear);
  lSuite.AddTest('TestKey', @RunTTestJSONConfigTestKey);
  lSuite.AddTest('TestStrings', @RunTTestJSONConfigTestStrings);
  lSuite.AddTest('TestUnicodeStrings', @RunTTestJSONConfigTestUnicodeStrings);
  lSuite.AddTest('TestUnicodeStrings2', @RunTTestJSONConfigTestUnicodeStrings2);
end;

end.

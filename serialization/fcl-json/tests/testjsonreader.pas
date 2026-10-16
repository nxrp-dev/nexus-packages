unit testjsonreader;

{$mode objfpc}
{$codepage UTF8}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpjson,jsonscanner,jsonreader, testjsondata;

Const
  DefaultOpts = [joUTF8,joStrict];

type

  { TMyJSONReader }

  TMyJSONReader = Class(TBaseJSONReader)
  Private
    FList : TStrings;
    function GetList: TStrings;
    procedure Push(const aType : String; const AValue: String='');
  protected
    procedure BooleanValue(const AValue: Boolean); override;
    procedure EndArray; override;
    procedure EndObject; override;
    procedure FloatValue(const AValue: Double); override;
    procedure Int64Value(const AValue: int64); override;
    procedure IntegerValue(const AValue: integer); override;
    procedure KeyValue(const AKey: TJSONStringType); override;
    procedure NullValue; override;
    procedure NumberValue(const AValue: TJSONStringType); override;
    procedure QWordValue(const AValue: QWord); override;
    procedure StartArray; override;
    procedure StartObject; override;
    procedure StringValue(const AValue: TJSONStringType); override;
  Public
    destructor Destroy; override;
    Property List : TStrings Read GetList;
  end;

  { TBaseTestReader }

  TBaseTestReader = class(TTestJSON)
  private
    FOptions : TJSONOptions;
    procedure CallNoHandlerStream;
    procedure DoTestFloat(F: TJSONFloat); overload;
    procedure DoTestFloat(F: TJSONFloat; S: String); overload;
    procedure DoTestString(S: TJSONStringType; AValue: TJSONStringType='');
    procedure DoTrailingCommaErrorArray;
    procedure DoTrailingCommaErrorObject;
  Protected
    procedure DoTestError(S: String; Options : TJSONOptions = DefaultOpts); virtual; abstract;
    Procedure TestRead(aJSON : String; AResult : Array of TJSONStringType); virtual; abstract;
  public
    procedure TestEmpty;
    procedure TestNull;
    procedure TestTrue;
    procedure TestFalse;
    procedure TestFloat;
    procedure TestFloatError;
    procedure TestInteger;
    procedure TestInt64;
    procedure TestString;
    procedure TestArray;
    procedure TestObject;
    procedure TestObjectError;
    procedure TestObjectKeyIdentifier;
    procedure TestObjectKeyIdentifierStrict;
    procedure TestTrailingComma;
    procedure TestTrailingCommaErrorArray;
    procedure TestTrailingCommaErrorObject;
    procedure TestMixed;
    Procedure TestComment;
    procedure TestErrors;
    procedure TestGarbageOK;
    procedure TestGarbageFail;
  end;

  { TTestReader }

  TTestReader = Class(TBaseTestReader)
  Private
    FReader: TMyJSONReader;
  Protected
    Procedure Teardown; virtual;
  Public
    procedure DoTestError(S: String; Options : TJSONOptions = DefaultOpts); override;
    Procedure TestRead(aJSON : String; AResult : Array of TJSONStringType); override;
    Property Reader : TMyJSONReader Read FReader;
  end;

  { TJSONConsumer }

  TJSONConsumer = Class(TInterfacedObject,IJSONConsumer)
  Private
    FList : TStrings;
    procedure Push(const aType : String; const AValue: String='');
  protected
    procedure BooleanValue(const AValue: Boolean);
    procedure EndArray;
    procedure EndObject;
    procedure FloatValue(const AValue: Double);
    procedure Int64Value(const AValue: int64);
    procedure IntegerValue(const AValue: integer);
    procedure KeyName(const AKey: TJSONStringType);
    procedure NullValue;
    procedure NumberValue(const AValue: TJSONStringType);
    procedure QWordValue(const AValue: QWord);
    procedure StartArray;
    procedure StartObject;
    procedure StringValue(const AValue: TJSONStringType);
  Public
    Constructor Create(AList : TStrings);
    Property List : TStrings Read FList;
  end;

  { TTestJSONConsumerReader }

  TTestJSONConsumerReader = Class(TBaseTestReader)
  Private
    FList : TStrings;
    FReader: TJSONConsumerReader;
  Protected
    Procedure Teardown; virtual;
  Public
    procedure DoTestError(S: String; Options : TJSONOptions = DefaultOpts); override;
    Procedure TestRead(aJSON : String; AResult : Array of TJSONStringType); override;
    Property Reader : TJSONConsumerReader Read FReader;
  end;

  { TTestJSONEventReader }

  TTestJSONEventReader = Class(TBaseTestReader)
  Private
    FList : TStrings;
    FReader: TJSONEventReader;
  Protected
    procedure Push(const aType : String; const AValue: String='');
    procedure BooleanValue(Sender: TObject; const AValue: Boolean);
    procedure EndArray(Sender: TObject);
    procedure EndObject(Sender: TObject);
    procedure FloatValue(Sender: TObject; const AValue: Double);
    procedure Int64Value(Sender: TObject; const AValue: int64);
    procedure IntegerValue(Sender: TObject; const AValue: integer);
    procedure KeyValue(Sender: TObject; const AKey: TJSONStringType);
    procedure NullValue(Sender: TObject);
    procedure NumberValue(Sender: TObject; const AValue: TJSONStringType);
    procedure QWordValue(Sender: TObject; const AValue: QWord);
    procedure StartArray(Sender: TObject);
    procedure StartObject(Sender: TObject);
    procedure StringValue(Sender: TObject; const AValue: TJSONStringType);
    Procedure HookupEvents(AReader: TJSONEventReader);
    Procedure Teardown; virtual;
  Public
    procedure DoTestError(S: String; Options : TJSONOptions = DefaultOpts); override;
    Procedure TestRead(aJSON : String; AResult : Array of TJSONStringType); override;
    Property Reader : TJSONEventReader Read FReader;
  end;


procedure RegistertestjsonreaderTests(ARegistry: TNXTestRegistry);

implementation


{ TMyJSONReader }

function TMyJSONReader.GetList: TStrings;
begin
  If FList=Nil then
    FList:=TStringList.Create;
  Result:=Flist;
end;

procedure TMyJSONReader.Push(const aType : String; const AValue : String = '');

begin
  if AValue<>'' then
    List.Add(aType+':'+AValue)
  else
    List.Add(aType);
end;

procedure TMyJSONReader.BooleanValue(const AValue: Boolean);
begin
  Push('boolean',BoolToStr(AValue));
end;

procedure TMyJSONReader.EndArray;
begin
  Push('ea');
end;

procedure TMyJSONReader.EndObject;
begin
  Push('eo');
end;

procedure TMyJSONReader.FloatValue(const AValue: Double);
begin
  List.Add('float:'+formatFloat('##.##',AVAlue));
end;

procedure TMyJSONReader.Int64Value(const AValue: int64);
begin
  Push('int64',IntToStr(aValue));
end;

procedure TMyJSONReader.IntegerValue(const AValue: integer);
begin
  Push('integer',IntToStr(aValue));
end;

procedure TMyJSONReader.KeyValue(const AKey: TJSONStringType);
begin
  Push('key',akey);
end;

procedure TMyJSONReader.NullValue;
begin
  Push('null');
end;

procedure TMyJSONReader.NumberValue(const AValue: TJSONStringType);
begin
  Push('number',aValue);
end;

procedure TMyJSONReader.QWordValue(const AValue: QWord);
begin
  Push('qword',IntToStr(AValue));
end;

procedure TMyJSONReader.StartArray;
begin
  Push('sa');
end;

procedure TMyJSONReader.StartObject;
begin
  Push('so');
end;

procedure TMyJSONReader.StringValue(const AValue: TJSONStringType);
var
  s: TJSONStringType;
begin
  s:='string:'+AValue;
  List.Add(s);
end;

destructor TMyJSONReader.Destroy;
begin
  FreeAndNil(Flist);
  inherited Destroy;
end;

procedure TBaseTestReader.TestEmpty;

begin
  TestRead('',[]);
end;

procedure TBaseTestReader.TestInteger;


begin
  TestRead('1',['number:1','integer:1']);
end;

procedure TBaseTestReader.TestInt64;

begin
  TestRead('123456789012345',['number:123456789012345','int64:123456789012345']);
end;

procedure TBaseTestReader.TestNull;


begin
  TestRead('null',['null']);
end;

procedure TBaseTestReader.TestTrue;

begin
  TestRead('true',['boolean:'+BoolToStr(true)]);
end;

procedure TBaseTestReader.TestFalse;

begin
  TestRead('false',['boolean:'+BoolToStr(false)]);
end;

procedure TBaseTestReader.TestFloat;


begin
  DoTestFloat(1.2);
  DoTestFloat(-1.2);
  DoTestFloat(0);
  DoTestFloat(1.2e1);
  DoTestFloat(-1.2e1);
  DoTestFloat(0);
  DoTestFloat(1.2,'1.2');
  DoTestFloat(-1.2,'-1.2');
  DoTestFloat(0,'0.0');
end;

procedure TBaseTestReader.TestFloatError;
begin
  DoTestError('.12',[joStrict]);
  DoTestError('.12E',[]);
  DoTestError('0.12E+',[]);
  DoTestError('.12E+-1',[]);
end;

procedure TBaseTestReader.TestString;

const
  GlowingStar = #$F0#$9F#$8C#$9F;
  Chinese = #$95e8#$88ab#$8111#$5b50#$6324#$574f#$4e86;
  Chinese4b = #$95e8#$d867#$de3d#$88ab#$8111#$5b50#$6324#$574f#$4e86;

begin
  DoTestString('A string');
  DoTestString('');
  DoTestString('\"','"');
  DoTestString('a\"','a"');
  DoTestString('a\\','a\');
  DoTestString('C:\\Windows','C:\Windows');
  DoTestString('\u00f8','ø'); // this is ø
  DoTestString('\u00f8\"','ø"'); // this is ø"
  DoTestString('\ud83c\udf1f',GlowingStar);
  DoTestString('\u0041\u0042','AB');   //issue #0038622
  DoTestString('\u0041\u0042\u0043','ABC');
  DoTestString('\u0041\u0042\u0043\u0044','ABCD');
  DoTestString('\u95e8\u88ab\u8111\u5b50\u6324\u574f\u4e86',Utf8Encode(Chinese));
  DoTestString('\u95e8\ud867\ude3d\u88ab\u8111\u5b50\u6324\u574f\u4e86',Utf8Encode(Chinese4b));
end;


procedure TBaseTestReader.TestArray;

Var
  S1,S2,S3 : String;

begin
  TestRead('[]',['sa','ea']);
  TestRead('[null]',['sa','null','ea']);
  TestRead('[true]',['sa','boolean:'+BoolToStr(true),'ea']);
  TestRead('[false]',['sa','boolean:'+BoolToStr(false),'ea']);
  TestRead('[1]',['sa','number:1','integer:1','ea']);
  TestRead('[1, 2]',['sa','number:1','integer:1','number:2','integer:2','ea']);
  TestRead('[1, 2, 3]',['sa','number:1','integer:1','number:2','integer:2','number:3','integer:3','ea']);
  TestRead('[1234567890123456]',['sa','number:1234567890123456','int64:1234567890123456','ea']);
  TestRead('[1234567890123456, 2234567890123456]',
    ['sa','number:1234567890123456','int64:1234567890123456','number:2234567890123456','int64:2234567890123456','ea']);
  TestRead('[1234567890123456, 2234567890123456, 3234567890123456]',
    ['sa','number:1234567890123456','int64:1234567890123456','number:2234567890123456','int64:2234567890123456',
     'number:3234567890123456','int64:3234567890123456','ea']);
  Str(12/10,S1);
  Delete(S1,1,1);
  Str(34/10,S2);
  Delete(S2,1,1);
  Str(34/10,S3);
  Delete(S3,1,1);
  TestRead('['+S1+']',['sa','number:'+s1,'float:'+formatfloat('##.##',12/10),'ea']);
  {
  TestRead('['+S1+', '+S2+']',2,true);
  TestRead('['+S1+', '+S2+', '+S3+']',3,true);
  TestRead('["A string"]',1);
  TestRead('["A string", "Another string"]',2);
  TestRead('["A string", "Another string", "Yet another string"]',3);
  TestRead('[null, false]',2);
  TestRead('[true, false]',2);
  TestRead('[null, 1]',2);
  TestRead('[1, "A string"]',2);
  TestRead('[1, []]',2);
  TestRead('[1, [1, 2]]',2);}
end;

procedure TBaseTestReader.TestTrailingComma;
begin
  FOptions:=[joIgnoreTrailingComma];
  TestRead('[1, 2, ]',['sa','number:1','integer:1','number:2','integer:2','ea']);
  TestRead('{ "a" : 1, }',['so','key:a', 'number:1','integer:1','eo']);
end;

procedure TBaseTestReader.TestTrailingCommaErrorArray;
begin
  TestContext.AssertRaises(EJSONParser, @DoTrailingCommaErrorArray, 'Need joIgnoreTrailingComma in options to allow trailing comma') ;
end;

procedure TBaseTestReader.TestTrailingCommaErrorObject;
begin
  TestContext.AssertRaises(EJSONParser, @DoTrailingCommaErrorObject, 'Need joIgnoreTrailingComma in options to allow trailing comma');
end;

procedure TBaseTestReader.DoTrailingCommaErrorArray;
begin
  TestRead('[1, 2, ]',['sa','number:1','integer:1','number:2','integer:2','ea']);
end;

procedure TBaseTestReader.DoTrailingCommaErrorObject;
begin
  TestRead('{ "a" : 1, }',['so','key:a', 'number:1','integer:1','eo']);
end;


procedure TBaseTestReader.TestMixed;

begin
  TestRead('[1, {}]',['sa','number:1','integer:1','so','eo','ea']);
  TestRead('[1, { "a" : 1 }]',['sa','number:1','integer:1','so','key:a','number:1','integer:1','eo','ea']);
  TestRead('[1, { "a" : 1 }, 1]',['sa','number:1','integer:1','so','key:a','number:1','integer:1','eo','number:1','integer:1','ea']);
  TestRead('{ "a" : [1, 2] }',['so','key:a','sa','number:1','integer:1','number:2','integer:2','ea','eo']);
  TestRead('{ "a" : [1, 2], "B" : { "c" : "d" } }',
    ['so','key:a','sa','number:1','integer:1','number:2','integer:2','ea','key:B','so','key:c','string:d','eo','eo']);
end;

procedure TBaseTestReader.TestComment;
begin
  FOptions:=[joComments];
  TestRead('/* */ [1, {}]',['sa','number:1','integer:1','so','eo','ea']);
  TestRead('//'+sLineBreak+' [1, {}]',['sa','number:1','integer:1','so','eo','ea']);
  TestRead('/* '+sLineBreak+' */ [1, {}]',['sa','number:1','integer:1','so','eo','ea']);
  TestRead('/*'+sLineBreak+'*/ [1, {}]',['sa','number:1','integer:1','so','eo','ea']);
  TestRead('/*'+sLineBreak+'*'+sLineBreak+'*/ [1, {}]',['sa','number:1','integer:1','so','eo','ea']);
  TestRead('/**'+sLineBreak+'**'+sLineBreak+'**/ [1, {}]',['sa','number:1','integer:1','so','eo','ea']);
  TestRead('/* */ [1, {}]',['sa','number:1','integer:1','so','eo','ea']);
  TestRead('[1, {}]//',['sa','number:1','integer:1','so','eo','ea']);
  TestRead('[1, {}]/* '+sLineBreak+' */',['sa','number:1','integer:1','so','eo','ea']);
  TestRead('[1, {}]/* '+sLineBreak+' */ ',['sa','number:1','integer:1','so','eo','ea']);
  TestRead('[1, {}]/* '+sLineBreak+'*'+sLineBreak+'*/ ',['sa','number:1','integer:1','so','eo','ea']);
  TestRead('[1, {}]/**'+sLineBreak+'**'+sLineBreak+'**/ ',['sa','number:1','integer:1','so','eo','ea']);
end;

procedure TBaseTestReader.TestObject;
begin
  TestRead('{}',['so','eo']);
  TestRead('{ "a" : 1 }',['so','key:a','number:1','integer:1','eo']);
  TestRead('{ "a" : 1, "B" : "String" }',['so','key:a','number:1','integer:1','key:B','string:String','eo']);
  TestRead('{ "a" : 1, "B" : {} }',['so','key:a','number:1','integer:1','key:B','so','eo','eo']);
  TestRead('{ "a" : 1, "B" : { "c" : "d" } }',['so','key:a','number:1','integer:1','key:B','so','key:c','string:d','eo','eo']);
end;

procedure TBaseTestReader.TestObjectError;
begin
  DoTestError('{ "name" : value }',[joUTF8]);
end;

procedure TBaseTestReader.TestObjectKeyIdentifier;
begin
  FOptions:=[joUTF8];
  TestRead('{ a : 1 }',['so','key:a','number:1','integer:1','eo']);
  TestRead('{ "a" : 1, b : 2 }',['so','key:a','number:1','integer:1','key:b','number:2','integer:2','eo']);
end;

procedure TBaseTestReader.TestObjectKeyIdentifierStrict;
begin
  DoTestError('{ a : 1 }');
  DoTestError('{ "a" : 1, b : 2 }');
end;


procedure TBaseTestReader.TestErrors;

begin

  DoTestError('a');
  DoTestError('"b');
  DoTestError('1Tru');

  DoTestError('b"');
  DoTestError('{"a" : }');
  DoTestError('{"a" : ""');
  DoTestError('{"a : ""');

  DoTestError('[1,]');
  DoTestError('[,]');
  DoTestError('[,,]');
  DoTestError('[1,,]');

end;

procedure TBaseTestReader.TestGarbageOK;
begin
  TestRead('"a"sss',['string:a']);
  TestRead('[null]xxx',['sa','null','ea']);
end;

procedure TBaseTestReader.TestGarbageFail;
begin
  DoTestError('"a"sss',[joStrict]);
  DoTestError('[null]aaa',[joStrict]);
end;


procedure TBaseTestReader.CallNoHandlerStream;

Var
  S : TStringStream;

begin
  S:=TstringStream.Create('1');
  try
    GetJSON(S,True).Free;
  finally
    S.Free;
  end;
end;

procedure TBaseTestReader.DoTestString(S: TJSONStringType; AValue : TJSONStringType = '');
begin
  if AValue='' then
    AValue:=S;
  FOptions:=[joUTF8];
  TestRead('"'+S+'"',['string:'+AValue]);
end;

procedure TBaseTestReader.DoTestFloat(F : TJSONFloat);

Var
  S : String;

begin
  Str(F,S);
  DoTestFloat(F,S);
end;

procedure TBaseTestReader.DoTestFloat(F : TJSONFloat; S : String);

begin
  TestRead(S,['number:'+trim(S),'float:'+formatfloat('##.##',F)]);
end;

procedure TTestReader.Teardown;
begin
  FreeAndNil(FReader);

end;

procedure TTestReader.TestRead(aJSON: String; AResult: array of TJSONStringType);

Var
  I : Integer;

begin
  FreeAndNil(FReader);
  FReader:=TMyJSONReader.Create(aJSON,Foptions);
  TMyJSONReader(FReader).DoExecute;
  TestContext.AssertTrue((Length(AResult))=(FReader.List.Count), aJSON+': Number of events');
  For I:=0 to Length(AResult)-1 do
    TestContext.AssertTrue((AResult[i])=(FReader.List[I]), aJSON+': Event number '+IntToStr(I));
end;

procedure TTestReader.DoTestError(S : String; Options : TJSONOptions = DefaultOpts);

Var
  P:TMyJSONReader;
  ParseOK : Boolean;

begin
  ParseOK:=False;
  P:=TMyJSONReader.Create(S,FOptions);
  P.OPtions:=Options;
  Try
    Try
      P.DoExecute;
      ParseOk:=True;
    Finally
      FreeAndNil(P);
    end;
  except
    ParseOk:=False;
  end;
  If ParseOK then
    TestContext.Fail('Parse of JSON string "'+S+'" should fail, but succeeded');
end;


{ TJSONConsumer }

procedure TJSONConsumer.Push(const aType : String; const AValue : String = '');

begin
  if AValue<>'' then
    List.Add(aType+':'+AValue)
  else
    List.Add(aType);
end;

procedure TJSONConsumer.BooleanValue(const AValue: Boolean);
begin
  Push('boolean',BoolToStr(AValue));
end;

procedure TJSONConsumer.EndArray;
begin
  Push('ea');
end;

procedure TJSONConsumer.EndObject;
begin
  Push('eo');
end;

procedure TJSONConsumer.FloatValue(const AValue: Double);
begin
  List.Add('float:'+formatFloat('##.##',AVAlue));
end;

procedure TJSONConsumer.Int64Value(const AValue: int64);
begin
  Push('int64',IntToStr(aValue));
end;

procedure TJSONConsumer.IntegerValue(const AValue: integer);
begin
  Push('integer',IntToStr(aValue));
end;

procedure TJSONConsumer.KeyName(const AKey: TJSONStringType);
begin
  Push('key',akey);
end;

procedure TJSONConsumer.NullValue;
begin
  Push('null');
end;

procedure TJSONConsumer.NumberValue(const AValue: TJSONStringType);
begin
  Push('number',aValue);
end;

procedure TJSONConsumer.QWordValue(const AValue: QWord);
begin
  Push('qword',IntToStr(AValue));
end;

procedure TJSONConsumer.StartArray;
begin
  Push('sa');
end;

procedure TJSONConsumer.StartObject;
begin
  Push('so');
end;

procedure TJSONConsumer.StringValue(const AValue: TJSONStringType);
var
  s: TJSONStringType;
begin
  s:='string:'+AValue;
  List.Add(s);
end;

constructor TJSONConsumer.Create(AList: TStrings);
begin
  FList:=AList;
end;

procedure TTestJSONConsumerReader.TestRead(aJSON: String; AResult: array of TJSONStringType);

Var
  I : Integer;

begin
  FreeAndNil(FReader);
  FreeAndNil(Flist);
  FList:=TStringList.Create;
  FReader:=TJSONConsumerReader.Create(aJSON,Foptions);
  FReader.Consumer:=TJSONConsumer.Create(FList);
  TJSONConsumerReader(FReader).Execute;
  TestContext.AssertTrue((Length(AResult))=(FList.Count), aJSON+': Number of events');
  For I:=0 to Length(AResult)-1 do
    TestContext.AssertTrue((AResult[i])=(FList[I]), aJSON+': Event number '+IntToStr(I));
end;

procedure TTestJSONConsumerReader.Teardown;
begin
  FreeAndNil(FReader);
  FreeAndNil(FList);

end;

procedure TTestJSONConsumerReader.DoTestError(S : String; Options : TJSONOptions = DefaultOpts);

Var
  P:TJSONConsumerReader;
  ParseOK : Boolean;

begin
  ParseOK:=False;
  FreeAndNil(FReader);
  FreeAndNil(Flist);
  FList:=TStringList.Create;
  P:=TJSONConsumerReader.Create(S,Options);
  P.Consumer:=TJSONConsumer.Create(FList);
  P.OPtions:=Options;
  Try
    Try
      P.Execute;
      ParseOk:=True;
    Finally
      FreeAndNil(P);
    end;
  except
    ParseOk:=False;
  end;
  If ParseOK then
    TestContext.Fail('Parse of JSON string "'+S+'" should fail, but succeeded');
end;

{ TTestJSONEventReader }

procedure TTestJSONEventReader.Teardown;
begin
  FreeAndNil(Freader);
  FreeAndNil(Flist);

end;

procedure TTestJSONEventReader.DoTestError(S: String; Options: TJSONOptions);

Var
  P:TJSONEventReader;
  ParseOK : Boolean;

begin
  ParseOK:=False;
  FreeAndNil(FReader);
  FreeAndNil(Flist);
  FList:=TStringList.Create;
  P:=TJSONEventReader.Create(S,Options);
  HookupEvents(P);
  P.OPtions:=Options;
  Try
    Try
      P.Execute;
      ParseOk:=True;
    Finally
      FreeAndNil(P);
    end;
  except
    ParseOk:=False;
  end;
  If ParseOK then
    TestContext.Fail('Parse of JSON string "'+S+'" should fail, but succeeded');
end;

procedure TTestJSONEventReader.TestRead(aJSON: String; AResult: array of TJSONStringType);

Var
  I : Integer;

begin
  FreeAndNil(FReader);
  FreeAndNil(Flist);
  FList:=TStringList.Create;
  FReader:=TJSONEventReader.Create(aJSON,Foptions);
  HookupEvents(FReader);
  FReader.Execute;
  TestContext.AssertTrue((Length(AResult))=(FList.Count), aJSON+': Number of events');
  For I:=0 to Length(AResult)-1 do
    TestContext.AssertTrue((AResult[i])=(FList[I]), aJSON+': Event number '+IntToStr(I));
end;

procedure TTestJSONEventReader.Push(const aType: String; const AValue: String);
begin
  if AValue<>'' then
    FList.Add(aType+':'+AValue)
  else
    FList.Add(aType);
end;

procedure TTestJSONEventReader.BooleanValue(Sender: TObject; const AValue: Boolean);
begin
  Push('boolean',BoolToStr(AValue));
end;

procedure TTestJSONEventReader.EndArray(Sender: TObject);
begin
  Push('ea');
end;

procedure TTestJSONEventReader.EndObject(Sender: TObject);
begin
  Push('eo');
end;

procedure TTestJSONEventReader.FloatValue(Sender: TObject; const AValue: Double);
begin
  FList.Add('float:'+formatFloat('##.##',AVAlue));
end;

procedure TTestJSONEventReader.Int64Value(Sender: TObject; const AValue: int64);
begin
  Push('int64',IntToStr(aValue));
end;

procedure TTestJSONEventReader.IntegerValue(Sender: TObject; const AValue: integer);
begin
  Push('integer',IntToStr(aValue));
end;

procedure TTestJSONEventReader.KeyValue(Sender: TObject; const AKey: TJSONStringType);
begin
  Push('key',akey);
end;

procedure TTestJSONEventReader.NullValue(Sender: TObject);
begin
  Push('null');
end;

procedure TTestJSONEventReader.NumberValue(Sender: TObject; const AValue: TJSONStringType);
begin
  Push('number',aValue);
end;

procedure TTestJSONEventReader.QWordValue(Sender: TObject; const AValue: QWord);
begin
  Push('qword',IntToStr(AValue));
end;

procedure TTestJSONEventReader.StartArray(Sender: TObject);
begin
  Push('sa');
end;

procedure TTestJSONEventReader.StartObject(Sender: TObject);
begin
  Push('so');
end;

procedure TTestJSONEventReader.StringValue(Sender: TObject; const AValue: TJSONStringType);
var
  s: TJSONStringType;
begin
  s:='string:'+AValue;
  FList.Add(s);
end;

procedure TTestJSONEventReader.HookupEvents(AReader: TJSONEventReader);
begin
  With Areader do
    begin
    OnNullValue:=@NullValue;
    OnBooleanValue:=@BooleanValue;
    OnNumberValue:=@NumberValue;
    OnFloatValue:=@FloatValue;
    OnIntegerValue:=@IntegerValue;
    OnInt64Value:=@Int64Value;
    OnQWordValue:=@QWordValue;
    OnStringValue:=@StringValue;
    OnKeyName:=@KeyValue;
    OnStartObject:=@StartObject;
    OnEndObject:=@EndObject;
    OnStartArray:=@StartArray;
    OnEndArray:=@EndArray;
    end;
end;


procedure RunTTestReaderTestEmpty(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestEmpty');
  try
    lFixture.SetUp;
    try lFixture.TestEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestNull(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestNull');
  try
    lFixture.SetUp;
    try lFixture.TestNull; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestTrue(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestTrue');
  try
    lFixture.SetUp;
    try lFixture.TestTrue; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestFalse(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestFalse');
  try
    lFixture.SetUp;
    try lFixture.TestFalse; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestFloat(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestFloat');
  try
    lFixture.SetUp;
    try lFixture.TestFloat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestFloatError(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestFloatError');
  try
    lFixture.SetUp;
    try lFixture.TestFloatError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestInteger(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestInteger');
  try
    lFixture.SetUp;
    try lFixture.TestInteger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestInt64(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestInt64');
  try
    lFixture.SetUp;
    try lFixture.TestInt64; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestString(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestString');
  try
    lFixture.SetUp;
    try lFixture.TestString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestArray(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestArray');
  try
    lFixture.SetUp;
    try lFixture.TestArray; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestObject(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestObject');
  try
    lFixture.SetUp;
    try lFixture.TestObject; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestObjectError(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestObjectError');
  try
    lFixture.SetUp;
    try lFixture.TestObjectError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestObjectKeyIdentifier(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestObjectKeyIdentifier');
  try
    lFixture.SetUp;
    try lFixture.TestObjectKeyIdentifier; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestObjectKeyIdentifierStrict(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestObjectKeyIdentifierStrict');
  try
    lFixture.SetUp;
    try lFixture.TestObjectKeyIdentifierStrict; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestTrailingComma(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestTrailingComma');
  try
    lFixture.SetUp;
    try lFixture.TestTrailingComma; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestTrailingCommaErrorArray(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestTrailingCommaErrorArray');
  try
    lFixture.SetUp;
    try lFixture.TestTrailingCommaErrorArray; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestTrailingCommaErrorObject(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestTrailingCommaErrorObject');
  try
    lFixture.SetUp;
    try lFixture.TestTrailingCommaErrorObject; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestMixed(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestMixed');
  try
    lFixture.SetUp;
    try lFixture.TestMixed; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestComment(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestComment');
  try
    lFixture.SetUp;
    try lFixture.TestComment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestErrors(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestErrors');
  try
    lFixture.SetUp;
    try lFixture.TestErrors; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestGarbageOK(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestGarbageOK');
  try
    lFixture.SetUp;
    try lFixture.TestGarbageOK; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestReaderTestGarbageFail(AContext: TNXTestContext);
var lFixture: TTestReader;
begin
  lFixture:=TTestReader.Create(AContext, 'TestGarbageFail');
  try
    lFixture.SetUp;
    try lFixture.TestGarbageFail; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestEmpty(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestEmpty');
  try
    lFixture.SetUp;
    try lFixture.TestEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestNull(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestNull');
  try
    lFixture.SetUp;
    try lFixture.TestNull; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestTrue(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestTrue');
  try
    lFixture.SetUp;
    try lFixture.TestTrue; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestFalse(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestFalse');
  try
    lFixture.SetUp;
    try lFixture.TestFalse; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestFloat(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestFloat');
  try
    lFixture.SetUp;
    try lFixture.TestFloat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestFloatError(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestFloatError');
  try
    lFixture.SetUp;
    try lFixture.TestFloatError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestInteger(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestInteger');
  try
    lFixture.SetUp;
    try lFixture.TestInteger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestInt64(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestInt64');
  try
    lFixture.SetUp;
    try lFixture.TestInt64; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestString(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestString');
  try
    lFixture.SetUp;
    try lFixture.TestString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestArray(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestArray');
  try
    lFixture.SetUp;
    try lFixture.TestArray; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestObject(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestObject');
  try
    lFixture.SetUp;
    try lFixture.TestObject; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestObjectError(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestObjectError');
  try
    lFixture.SetUp;
    try lFixture.TestObjectError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestObjectKeyIdentifier(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestObjectKeyIdentifier');
  try
    lFixture.SetUp;
    try lFixture.TestObjectKeyIdentifier; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestObjectKeyIdentifierStrict(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestObjectKeyIdentifierStrict');
  try
    lFixture.SetUp;
    try lFixture.TestObjectKeyIdentifierStrict; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestTrailingComma(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestTrailingComma');
  try
    lFixture.SetUp;
    try lFixture.TestTrailingComma; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestTrailingCommaErrorArray(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestTrailingCommaErrorArray');
  try
    lFixture.SetUp;
    try lFixture.TestTrailingCommaErrorArray; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestTrailingCommaErrorObject(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestTrailingCommaErrorObject');
  try
    lFixture.SetUp;
    try lFixture.TestTrailingCommaErrorObject; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestMixed(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestMixed');
  try
    lFixture.SetUp;
    try lFixture.TestMixed; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestComment(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestComment');
  try
    lFixture.SetUp;
    try lFixture.TestComment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestErrors(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestErrors');
  try
    lFixture.SetUp;
    try lFixture.TestErrors; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestGarbageOK(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestGarbageOK');
  try
    lFixture.SetUp;
    try lFixture.TestGarbageOK; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONConsumerReaderTestGarbageFail(AContext: TNXTestContext);
var lFixture: TTestJSONConsumerReader;
begin
  lFixture:=TTestJSONConsumerReader.Create(AContext, 'TestGarbageFail');
  try
    lFixture.SetUp;
    try lFixture.TestGarbageFail; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestEmpty(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestEmpty');
  try
    lFixture.SetUp;
    try lFixture.TestEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestNull(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestNull');
  try
    lFixture.SetUp;
    try lFixture.TestNull; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestTrue(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestTrue');
  try
    lFixture.SetUp;
    try lFixture.TestTrue; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestFalse(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestFalse');
  try
    lFixture.SetUp;
    try lFixture.TestFalse; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestFloat(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestFloat');
  try
    lFixture.SetUp;
    try lFixture.TestFloat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestFloatError(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestFloatError');
  try
    lFixture.SetUp;
    try lFixture.TestFloatError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestInteger(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestInteger');
  try
    lFixture.SetUp;
    try lFixture.TestInteger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestInt64(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestInt64');
  try
    lFixture.SetUp;
    try lFixture.TestInt64; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestString(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestString');
  try
    lFixture.SetUp;
    try lFixture.TestString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestArray(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestArray');
  try
    lFixture.SetUp;
    try lFixture.TestArray; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestObject(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestObject');
  try
    lFixture.SetUp;
    try lFixture.TestObject; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestObjectError(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestObjectError');
  try
    lFixture.SetUp;
    try lFixture.TestObjectError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestObjectKeyIdentifier(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestObjectKeyIdentifier');
  try
    lFixture.SetUp;
    try lFixture.TestObjectKeyIdentifier; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestObjectKeyIdentifierStrict(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestObjectKeyIdentifierStrict');
  try
    lFixture.SetUp;
    try lFixture.TestObjectKeyIdentifierStrict; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestTrailingComma(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestTrailingComma');
  try
    lFixture.SetUp;
    try lFixture.TestTrailingComma; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestTrailingCommaErrorArray(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestTrailingCommaErrorArray');
  try
    lFixture.SetUp;
    try lFixture.TestTrailingCommaErrorArray; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestTrailingCommaErrorObject(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestTrailingCommaErrorObject');
  try
    lFixture.SetUp;
    try lFixture.TestTrailingCommaErrorObject; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestMixed(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestMixed');
  try
    lFixture.SetUp;
    try lFixture.TestMixed; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestComment(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestComment');
  try
    lFixture.SetUp;
    try lFixture.TestComment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestErrors(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestErrors');
  try
    lFixture.SetUp;
    try lFixture.TestErrors; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestGarbageOK(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestGarbageOK');
  try
    lFixture.SetUp;
    try lFixture.TestGarbageOK; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONEventReaderTestGarbageFail(AContext: TNXTestContext);
var lFixture: TTestJSONEventReader;
begin
  lFixture:=TTestJSONEventReader.Create(AContext, 'TestGarbageFail');
  try
    lFixture.SetUp;
    try lFixture.TestGarbageFail; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegistertestjsonreaderTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('testjsonreader.TTestReader');
  lSuite.AddTest('TestEmpty', @RunTTestReaderTestEmpty);
  lSuite.AddTest('TestNull', @RunTTestReaderTestNull);
  lSuite.AddTest('TestTrue', @RunTTestReaderTestTrue);
  lSuite.AddTest('TestFalse', @RunTTestReaderTestFalse);
  lSuite.AddTest('TestFloat', @RunTTestReaderTestFloat);
  lSuite.AddTest('TestFloatError', @RunTTestReaderTestFloatError);
  lSuite.AddTest('TestInteger', @RunTTestReaderTestInteger);
  lSuite.AddTest('TestInt64', @RunTTestReaderTestInt64);
  lSuite.AddTest('TestString', @RunTTestReaderTestString);
  lSuite.AddTest('TestArray', @RunTTestReaderTestArray);
  lSuite.AddTest('TestObject', @RunTTestReaderTestObject);
  lSuite.AddTest('TestObjectError', @RunTTestReaderTestObjectError);
  lSuite.AddTest('TestObjectKeyIdentifier', @RunTTestReaderTestObjectKeyIdentifier);
  lSuite.AddTest('TestObjectKeyIdentifierStrict', @RunTTestReaderTestObjectKeyIdentifierStrict);
  lSuite.AddTest('TestTrailingComma', @RunTTestReaderTestTrailingComma);
  lSuite.AddTest('TestTrailingCommaErrorArray', @RunTTestReaderTestTrailingCommaErrorArray);
  lSuite.AddTest('TestTrailingCommaErrorObject', @RunTTestReaderTestTrailingCommaErrorObject);
  lSuite.AddTest('TestMixed', @RunTTestReaderTestMixed);
  lSuite.AddTest('TestComment', @RunTTestReaderTestComment);
  lSuite.AddTest('TestErrors', @RunTTestReaderTestErrors);
  lSuite.AddTest('TestGarbageOK', @RunTTestReaderTestGarbageOK);
  lSuite.AddTest('TestGarbageFail', @RunTTestReaderTestGarbageFail);
  lSuite:=ARegistry.AddSuite('testjsonreader.TTestJSONConsumerReader');
  lSuite.AddTest('TestEmpty', @RunTTestJSONConsumerReaderTestEmpty);
  lSuite.AddTest('TestNull', @RunTTestJSONConsumerReaderTestNull);
  lSuite.AddTest('TestTrue', @RunTTestJSONConsumerReaderTestTrue);
  lSuite.AddTest('TestFalse', @RunTTestJSONConsumerReaderTestFalse);
  lSuite.AddTest('TestFloat', @RunTTestJSONConsumerReaderTestFloat);
  lSuite.AddTest('TestFloatError', @RunTTestJSONConsumerReaderTestFloatError);
  lSuite.AddTest('TestInteger', @RunTTestJSONConsumerReaderTestInteger);
  lSuite.AddTest('TestInt64', @RunTTestJSONConsumerReaderTestInt64);
  lSuite.AddTest('TestString', @RunTTestJSONConsumerReaderTestString);
  lSuite.AddTest('TestArray', @RunTTestJSONConsumerReaderTestArray);
  lSuite.AddTest('TestObject', @RunTTestJSONConsumerReaderTestObject);
  lSuite.AddTest('TestObjectError', @RunTTestJSONConsumerReaderTestObjectError);
  lSuite.AddTest('TestObjectKeyIdentifier', @RunTTestJSONConsumerReaderTestObjectKeyIdentifier);
  lSuite.AddTest('TestObjectKeyIdentifierStrict', @RunTTestJSONConsumerReaderTestObjectKeyIdentifierStrict);
  lSuite.AddTest('TestTrailingComma', @RunTTestJSONConsumerReaderTestTrailingComma);
  lSuite.AddTest('TestTrailingCommaErrorArray', @RunTTestJSONConsumerReaderTestTrailingCommaErrorArray);
  lSuite.AddTest('TestTrailingCommaErrorObject', @RunTTestJSONConsumerReaderTestTrailingCommaErrorObject);
  lSuite.AddTest('TestMixed', @RunTTestJSONConsumerReaderTestMixed);
  lSuite.AddTest('TestComment', @RunTTestJSONConsumerReaderTestComment);
  lSuite.AddTest('TestErrors', @RunTTestJSONConsumerReaderTestErrors);
  lSuite.AddTest('TestGarbageOK', @RunTTestJSONConsumerReaderTestGarbageOK);
  lSuite.AddTest('TestGarbageFail', @RunTTestJSONConsumerReaderTestGarbageFail);
  lSuite:=ARegistry.AddSuite('testjsonreader.TTestJSONEventReader');
  lSuite.AddTest('TestEmpty', @RunTTestJSONEventReaderTestEmpty);
  lSuite.AddTest('TestNull', @RunTTestJSONEventReaderTestNull);
  lSuite.AddTest('TestTrue', @RunTTestJSONEventReaderTestTrue);
  lSuite.AddTest('TestFalse', @RunTTestJSONEventReaderTestFalse);
  lSuite.AddTest('TestFloat', @RunTTestJSONEventReaderTestFloat);
  lSuite.AddTest('TestFloatError', @RunTTestJSONEventReaderTestFloatError);
  lSuite.AddTest('TestInteger', @RunTTestJSONEventReaderTestInteger);
  lSuite.AddTest('TestInt64', @RunTTestJSONEventReaderTestInt64);
  lSuite.AddTest('TestString', @RunTTestJSONEventReaderTestString);
  lSuite.AddTest('TestArray', @RunTTestJSONEventReaderTestArray);
  lSuite.AddTest('TestObject', @RunTTestJSONEventReaderTestObject);
  lSuite.AddTest('TestObjectError', @RunTTestJSONEventReaderTestObjectError);
  lSuite.AddTest('TestObjectKeyIdentifier', @RunTTestJSONEventReaderTestObjectKeyIdentifier);
  lSuite.AddTest('TestObjectKeyIdentifierStrict', @RunTTestJSONEventReaderTestObjectKeyIdentifierStrict);
  lSuite.AddTest('TestTrailingComma', @RunTTestJSONEventReaderTestTrailingComma);
  lSuite.AddTest('TestTrailingCommaErrorArray', @RunTTestJSONEventReaderTestTrailingCommaErrorArray);
  lSuite.AddTest('TestTrailingCommaErrorObject', @RunTTestJSONEventReaderTestTrailingCommaErrorObject);
  lSuite.AddTest('TestMixed', @RunTTestJSONEventReaderTestMixed);
  lSuite.AddTest('TestComment', @RunTTestJSONEventReaderTestComment);
  lSuite.AddTest('TestErrors', @RunTTestJSONEventReaderTestErrors);
  lSuite.AddTest('TestGarbageOK', @RunTTestJSONEventReaderTestGarbageOK);
  lSuite.AddTest('TestGarbageFail', @RunTTestJSONEventReaderTestGarbageFail);
end;

end.

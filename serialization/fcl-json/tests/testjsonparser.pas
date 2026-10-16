{
    This file is part of the Free Component Library

    JSON FPCUNit test for parser
    Copyright (c) 2007 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
{$mode objfpc}
{$h+}
{$codepage UTF8}

unit testjsonparser;

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpjson,
  jsonscanner,jsonParser,testjsondata;

Const
  DefaultOpts = [joUTF8,joStrict];

type

  { TTestParser }

  TTestParser = class(TTestJSON)
  private
    FOptions : TJSONOptions;
    procedure CallNoHandlerStream;
    procedure DoDuplicate;
    procedure DoTestError(S: String; Options : TJSONOptions = DefaultOpts);
    procedure DoTestFloat(F: TJSONFloat); overload;
    procedure DoTestFloat(F: TJSONFloat; S: String); overload;
    procedure DoTestObject(S: String; const ElNames: array of String; DoJSONTest : Boolean = True);
    procedure DoTestString(S : String; AResult : String);
    procedure DoTestString(S : String);
    procedure DoTestArray(S: String; ACount: Integer; IgnoreJSON: Boolean=False);
    Procedure DoTestClass(S : String; AClass : TJSONDataClass);
    procedure CallNoHandler;
    procedure DoTrailingCommaErrorArray;
    procedure DoTrailingCommaErrorObject;
  Protected
    Procedure Setup; override;
  public
    procedure TestEmpty;
    procedure TestNull;
    procedure TestTrue;
    procedure TestFalse;
    procedure TestFloat;
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
    Procedure TestClasses;
    Procedure TestHandler;
    Procedure TestNoHandlerError;
    Procedure TestHandlerResult;
    Procedure TestEmptyLine;
    Procedure TestStartEmptyLine;
    Procedure TestObjectEmptyLine;
    Procedure TestCommentLine;
    Procedure TestFirstLineComment;
    Procedure TestMultiLineComment;
    Procedure TestIgnoreDuplicates;
    Procedure TestNoIgnoreDuplicates;
  end;

procedure RegistertestjsonparserTests(ARegistry: TNXTestRegistry);

implementation

procedure TTestParser.TestEmpty;

Var
  P : TJSONParser;
  J : TJSONData;

begin
  P:=TJSONParser.Create('',[joUTF8]);
  Try
    J:=P.Parse;
    If (J<>Nil) then
      FContext.Fail('Empty returns Nil');
  Finally
    FreeAndNil(J);
    FreeAndNil(P);
  end;
end;

procedure TTestParser.TestInteger;

Var
  P : TJSONParser;
  J : TJSONData;

begin
  P:=TJSONParser.Create('1',[joUTF8]);
  Try
    J:=P.Parse;
    If (J=Nil) then
      FContext.Fail('Parse of 1 fails');
    TestJSONType(J,jtNumber);
    TestAsInteger(J,1);
  Finally
    FreeAndNil(J);
    FreeAndNil(P);
  end;
end;

procedure TTestParser.TestInt64;

Var
  P : TJSONParser;
  J : TJSONData;

begin
  P:=TJSONParser.Create('123456789012345',[joUTF8]);
  Try
    J:=P.Parse;
    If (J=Nil) then
      FContext.Fail('Parse of 123456789012345 fails');
    TestJSONType(J,jtNumber);
    TestAsInt64(J,123456789012345);
  Finally
    FreeAndNil(J);
    FreeAndNil(P);
  end;
end;

procedure TTestParser.TestNull;

Var
  P : TJSONParser;
  J : TJSONData;

begin
  P:=TJSONParser.Create('null',[joUTF8]);
  Try
    J:=P.Parse;
    If (J=Nil) then
      FContext.Fail('Parse of null fails');
    TestJSONType(J,jtNull);
  Finally
    FreeAndNil(J);
    FreeAndNil(P);
  end;
end;

procedure TTestParser.TestTrue;

Var
  P : TJSONParser;
  J : TJSONData;

begin
  P:=TJSONParser.Create('true',[joUTF8]);
  Try
    J:=P.Parse;
    If (J=Nil) then
      FContext.Fail('Parse of True fails');
    TestJSONType(J,jtBoolean);
    TestAsBoolean(J,True);
  Finally
    FreeAndNil(J);
    FreeAndNil(P);
  end;
end;

procedure TTestParser.TestFalse;

Var
  P : TJSONParser;
  J : TJSONData;

begin
  P:=TJSONParser.Create('false',[joUTF8]);
  Try
    J:=P.Parse;
    If (J=Nil) then
      FContext.Fail('Parse of False fails');
    TestJSONType(J,jtBoolean);
    TestAsBoolean(J,False);
  Finally
    FreeAndNil(J);
    FreeAndNil(P);
  end;
end;

procedure TTestParser.TestFloat;


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

procedure TTestParser.TestString;

Const
  // Glowing star in UTF8
  GlowingStar = #$F0#$9F#$8C#$9F;

begin
  DoTestString('A string');
  DoTestString('');
  DoTestString('\"');
  DoTestString('\u00f8','ø'); // this is ø
  DoTestString('\u00f8\"','ø"'); // this is ø"
//  Writeln(GlowingStar);
  DoTestString('\ud83c\udf1f',GlowingStar);
end;


procedure TTestParser.TestArray;

Var
  S1,S2,S3 : String;

begin
  DoTestArray('[]',0);
  DoTestArray('[null]',1);
  DoTestArray('[true]',1);
  DoTestArray('[false]',1);
  DoTestArray('[1]',1);
  DoTestArray('[1, 2]',2);
  DoTestArray('[1, 2, 3]',3);
  DoTestArray('[1234567890123456]',1);
  DoTestArray('[1234567890123456, 2234567890123456]',2);
  DoTestArray('[1234567890123456, 2234567890123456, 3234567890123456]',3);
  Str(12/10,S1);
  Delete(S1,1,1);
  Str(34/10,S2);
  Delete(S2,1,1);
  Str(34/10,S3);
  Delete(S3,1,1);
  DoTestArray('['+S1+']',1,true);
  DoTestArray('['+S1+', '+S2+']',2,true);
  DoTestArray('['+S1+', '+S2+', '+S3+']',3,true);
  DoTestArray('["A string"]',1);
  DoTestArray('["A string", "Another string"]',2);
  DoTestArray('["A string", "Another string", "Yet another string"]',3);
  DoTestArray('[null, false]',2);
  DoTestArray('[true, false]',2);
  DoTestArray('[null, 1]',2);
  DoTestArray('[1, "A string"]',2);
  DoTestArray('[1, []]',2);
  DoTestArray('[1, [1, 2]]',2);
end;

procedure TTestParser.TestTrailingComma;
begin
  FOptions:=[joIgnoreTrailingComma];
  DoTestArray('[1, 2,]',2,True);
  DoTestObject('{ "a" : 1, }',['a'],False);
end;

procedure TTestParser.TestTrailingCommaErrorArray;
begin
  FContext.AssertRaises(EJSONParser, @DoTrailingCommaErrorArray, 'Need joIgnoreTrailingComma in options to allow trailing comma') ;
end;

procedure TTestParser.TestTrailingCommaErrorObject;
begin
  FContext.AssertRaises(EJSONParser, @DoTrailingCommaErrorObject, 'Need joIgnoreTrailingComma in options to allow trailing comma');
end;

procedure TTestParser.DoTrailingCommaErrorArray;
begin
  DoTestArray('[1, 2,]',2,True);
end;

procedure TTestParser.DoTrailingCommaErrorObject;
begin
  DoTestObject('{ "a" : 1, }',['a'],False);
end;

procedure TTestParser.TestMixed;

Const

  SAddr ='{ "addressbook": { "name": "Mary Lebow", '+
         '  "address": {'+
         '      "street": "5 Main Street",'+LineEnding+
         '        "city": "San Diego, CA",'+LineEnding+
         '        "zip": 91912'+LineEnding+
         '    },'+LineEnding+
         '    "phoneNumbers": [  '+LineEnding+
         '        "619 332-3452",'+LineEnding+
         '        "664 223-4667"'+LineEnding+
         '    ]'+LineEnding+
         ' }'+LineEnding+
         '}';

begin
  DoTestArray('[1, {}]',2);
  DoTestArray('[1, { "a" : 1 }]',2);
  DoTestArray('[1, { "a" : 1 }, 1]',3);
  DoTestObject('{ "a" : [1, 2] }',['a']);
  DoTestObject('{ "a" : [1, 2], "B" : { "c" : "d" } }',['a','B']);
  DoTestObject(SAddr,['addressbook'],False);
end;

procedure TTestParser.TestComment;
begin
  FOptions:=[joComments];
  DoTestArray('/* */ [1, {}]',2,True);
  DoTestArray('//'+sLineBreak+'[1, { "a" : 1 }]',2,True);
  DoTestArray('/* '+sLineBreak+' */ [1, {}]',2,True);
  DoTestArray('/*'+sLineBreak+'*/ [1, {}]',2,True);
  DoTestArray('/*'+sLineBreak+'*/ [1, {}]',2,True);
  DoTestArray('/*'+sLineBreak+'*'+sLineBreak+'*/ [1, {}]',2,True);
  DoTestArray('/**'+sLineBreak+'**'+sLineBreak+'**/ [1, {}]',2,True);
  DoTestArray('/* */ [1, {}]',2,True);
  DoTestArray('[1, { "a" : 1 }]//'+sLineBreak,2,True);
  DoTestArray('[1, {}]/* '+sLineBreak+' */ ',2,True);
  DoTestArray('[1, {}]/*'+sLineBreak+'*/ ',2,True);
  DoTestArray('[1, {}]/*'+sLineBreak+'*/ ',2,True);
  DoTestArray('[1, {}]/*'+sLineBreak+'*'+sLineBreak+'*/ ',2,True);
  DoTestArray(' [1, {}]/**'+sLineBreak+'**'+sLineBreak+'**/',2,True);
end;

procedure TTestParser.TestObject;
begin
  DoTestObject('{}',[]);
  DoTestObject('{ "a" : 1 }',['a']);
  DoTestObject('{ "a" : 1, "B" : "String" }',['a','B']);
  DoTestObject('{ "a" : 1, "B" : {} }',['a','B']);
  DoTestObject('{ "a" : 1, "B" : { "c" : "d" } }',['a','B']);
end;

procedure TTestParser.TestObjectError;
begin
  DoTestError('{ "name" : value }',[joUTF8]);
end;

procedure TTestParser.TestObjectKeyIdentifier;
begin
  FOptions:=[joUTF8];
  DoTestObject('{ a : 1 }',['a'],False);
  DoTestObject('{ "a" : 1, b : 2 }',['a','b'],False);
end;

procedure TTestParser.TestObjectKeyIdentifierStrict;
begin
  DoTestError('{ a : 1 }');
  DoTestError('{ "a" : 1, b : 2 }');
end;


procedure TTestParser.DoTestObject(S: String; const ElNames: array of String;
  DoJSONTest: Boolean);

Var
  P : TJSONParser;
  J : TJSONData;
  O : TJSONObject;
  I : Integer;

begin
  J:=Nil;
  P:=TJSONParser.Create(S,[joUTF8]);
  Try
    P.Options:=FOptions;
    J:=P.Parse;
    If (J=Nil) then
      FContext.Fail('Parse of object "'+S+'" fails');
    TestJSONType(J,jtObject);
    TestItemCount(J,High(ElNames)-Low(ElNames)+1);
    O:=TJSONObject(J);
    For I:=Low(ElNames) to High(ElNames) do
      FContext.AssertTrue((ElNames[i])=(O.Names[I-Low(ElNames)]), Format('Element %d name',[I-Low(Elnames)]));
    If DoJSONTest then
      self.TestJSON(J,S);
  Finally
    FreeAndNil(J);
    FreeAndNil(P);
  end;
end;


procedure TTestParser.DoTestArray(S : String; ACount : Integer; IgnoreJSON : Boolean = False);

Var
  P : TJSONParser;
  J : TJSONData;

begin
  J:=Nil;
  P:=TJSONParser.Create(S,[joComments]);
  Try
    P.Options:=FOptions;
    J:=P.Parse;
    If (J=Nil) then
      FContext.Fail('Parse of array "'+S+'" fails');
    TestJSONType(J,jtArray);
    TestItemCount(J,ACount);
    if not IgnoreJSON then
      TestJSON(J,S);
  Finally
    FreeAndNil(J);
    FreeAndNil(P);
  end;
end;

procedure TTestParser.DoTestClass(S: String; AClass: TJSONDataClass);

Var
  P : TJSONParser;
  D : TJSONData;

begin
  P:=TJSONParser.Create(S,[joUTF8]);
  try
    D:=P.Parse;
    try
      FContext.AssertTrue((AClass)=(D.ClassType), 'Correct class for '+S+' : ');
    finally
      D.Free
    end;
  finally
    P.Free;
  end;
end;

procedure TTestParser.TestErrors;

begin

  DoTestError('1Tru');
  DoTestError('a');
  DoTestError('"b');

  DoTestError('b"');
  DoTestError('{"a" : }');
  DoTestError('{"a" : ""');
  DoTestError('{"a : ""');

  DoTestError('[1,]');
  DoTestError('[,]');
  DoTestError('[,,]');
  DoTestError('[1,,]');

end;

procedure TTestParser.TestClasses;
begin
  SetMyInstanceTypes;
  DoTestClass('null',TMyNull);
  DoTestClass('true',TMyBoolean);
  DoTestClass('1',TMyInteger);
  DoTestClass('1.2',TMyFloat);
  DoTestClass('123456789012345',TMyInt64);
  DoTestClass('"tata"',TMyString);
  DoTestClass('{}',TMyObject);
  DoTestClass('[]',TMyArray);
end;

procedure TTestParser.CallNoHandler;

begin
  GetJSON('1',True).Free;
end;

procedure TTestParser.Setup;
begin
  inherited Setup;
  FOptions:=[];
end;

procedure TTestParser.CallNoHandlerStream;

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

procedure TTestParser.TestHandler;
begin
  FContext.AssertTrue((GetJSONParserHandler)<>nil, 'Handler installed');
end;

procedure TTestParser.TestNoHandlerError;

Var
  H : TJSONParserHandler;
  HS : TJSONStringParserHandler;

begin
  H:=GetJSONParserHandler;
  HS:=GetJSONStringParserHandler;
  try
    FContext.AssertTrue((H)=(SetJSONParserHandler(Nil)), 'SetJSONParserHandler returns previous handler');
    FContext.AssertTrue((HS)=(SetJSONStringParserHandler(Nil)), 'SetJSONStringParserHandler returns previous handler');
    FContext.AssertRaises(EJSON, @CallNoHandler, 'No handler raises exception');
    FContext.AssertRaises(EJSON, @CallNoHandlerStream, 'No handler raises exception');
  finally
    SetJSONParserHandler(H);
    SetJSONStringParserHandler(HS);
  end;
end;

procedure TTestParser.TestHandlerResult;

Var
  D : TJSONData;

begin
  D:=GetJSON('"123"');
  try
    FContext.AssertTrue(('123')=(D.AsString), 'Have correct string');
  finally
    D.Free;
  end;
end;

procedure TTestParser.TestEmptyLine;
// Bug report 36037
Const MyJSON =
'  {'+sLineBreak+
'  "pylib__linux" : "libpython3.7m.so.1.0",'+sLineBreak+
'  "ui_toolbar_theme": "default_24x24",'+sLineBreak+
'  "ui_toolbar_show" : true,'+sLineBreak+
'  "font_name__linux" : "DejaVu Sans Mono",'+sLineBreak+
'  "font_size__linux" : 10,'+sLineBreak+
'    "ui_listbox_fuzzy": false,'+sLineBreak+
'    "ui_max_size_lexer": 5,'+sLineBreak+
'    "find_separate_form": false,'+sLineBreak+sLineBreak+
'}';
  var
    J : TJSONData;
begin
  With TJSONParser.Create(MyJSON,[joUTF8,joIgnoreTrailingComma]) do
  Try
    J:=Parse;
    J.Free;
  Finally
    Free;
  end;
end;

procedure TTestParser.TestStartEmptyLine;

// Bug ID 37352: case 1

const
  ENDLINE = #$0d#$0a;

Const
  MyJSON = ENDLINE+
    '{'+ENDLINE+
      '"version":100,'+ENDLINE+
//      '//comment'+ENDLINE+
      '"value":200'+ENDLINE+
    '}'+ENDLINE;

var
  J : TJSONData;

begin
  With TJSONParser.Create(MyJSON,[joComments]) do
    Try
      J:=Parse;
      J.Free;
    Finally
      Free;
    end;
end;

procedure TTestParser.TestObjectEmptyLine;

// Bug ID 37352: case 2

const
  ENDLINE = #$0d#$0a;


Const
  MyJSON = '{'+ENDLINE+
        ''+ENDLINE+
        '"version":100, //comment'+ENDLINE+
        '"value":200'+ENDLINE+
      '}'+ENDLINE;
var
  J : TJSONData;

begin
  With TJSONParser.Create(MyJSON,[joComments]) do
    Try
      J:=Parse;
      J.Free;
    Finally
      Free;
    end;
end;

procedure TTestParser.TestCommentLine;

// Bug ID 37352: case 3

const
  ENDLINE = #$0d#$0a;


Const
  MyJSON =
        ENDLINE+
            '{'+ENDLINE+
              '"version":100, //comment'+ENDLINE+
              '"value":200'+ENDLINE+
            '}'+ENDLINE;

var
  J : TJSONData;

begin
  With TJSONParser.Create(MyJSON,[joComments]) do
    Try
      J:=Parse;
      J.Free;
    Finally
      Free;
    end;
end;

procedure TTestParser.TestFirstLineComment;

// New case
const
  ENDLINE = #$0d#$0a;


Const
  MyJSON =
        '//comment1'+ENDLINE+
              '{'+ENDLINE+
              '"version":100, //comment2'+ENDLINE+
              '"value":200'+ENDLINE+
            '}'+ENDLINE;

var
  J : TJSONData;

begin
  With TJSONParser.Create(MyJSON,[joComments]) do
    Try
      J:=Parse;
      J.Free;
    Finally
      Free;
    end;

end;

procedure TTestParser.TestMultiLineComment;

// Issue  37367

const
  ENDLINE = #$0d#$0a;


Const
  MyJSON =
        '/* long comment'+ENDLINE+
        ''+ENDLINE+
        '  error'+ENDLINE+
        '*/'+ENDLINE+
        '{'+ENDLINE+
        '  "version":100, //coment2 without comment2 works well '+ENDLINE+
        '  "valor":200   /*comment 3'+ENDLINE+
        '    line 2'+ENDLINE+
        '   */'+ENDLINE+
        '}'+ENDLINE;

var
  J : TJSONData;

begin
  With TJSONParser.Create(MyJSON,[joComments]) do
    Try
      J:=Parse;
      J.Free;
    Finally
      Free;
    end;
end;

procedure TTestParser.TestIgnoreDuplicates;

Const
  MyJSON =
        '{ "a":100, "b": 20, "a":300} ';

var
  J : TJSONData;

begin
  With TJSONParser.Create(MyJSON,[joIgnoreDuplicates]) do
    Try
      J:=Parse;
      FContext.AssertTrue((TJSONObject)=(J.ClassType), 'Correct class');
      FContext.AssertTrue((100)=(TJSONObject(J).Get('a',0)), 'Correct value');
      J.Free;
    Finally
      Free;
    end;
end;

procedure TTestParser.DoDuplicate;

Const
  MyJSON =
        '{ "a":100, "b": 20, "a":300} ';

var
  J : TJSONData;

begin
  With TJSONParser.Create(MyJSON,[]) do
    Try
      J:=Parse;
      J.Free;
    Finally
      Free;
    end;
end;

procedure TTestParser.TestNoIgnoreDuplicates;

begin
  FContext.AssertRaises(EJSON, @DoDuplicate, 'No duplicates allowed');
end;

procedure TTestParser.DoTestError(S : String; Options : TJSONOptions = DefaultOpts);

Var
  P : TJSONParser;
  J : TJSONData;
  ParseOK : Boolean;
  N : String;

begin
  ParseOK:=False;
  P:=TJSONParser.Create(S,[joUTF8]);
  P.OPtions:=Options;
  J:=Nil;
  Try
    Try
      Repeat
        FreeAndNil(J);
        J:=P.Parse;
        ParseOK:=True;
        If (J<>Nil) then
          N:=J.ClassName;
      Until (J=Nil)
    Finally
      FreeAndNil(J);
      FreeAndNil(P);
    end;
  except
    ParseOk:=False;
  end;
  If ParseOK then
    FContext.Fail('Parse of JSON string "'+S+'" should fail, but returned '+N);
end;

procedure TTestParser.DoTestString(S: String);

begin
  DoTestString(S,JSONStringToString(S));
end;

procedure TTestParser.DoTestString(S: String; AResult : String);

Var
  P : TJSONParser;
  J : TJSONData;

begin
  P:=TJSONParser.Create('"'+S+'"',[joUTF8]);
  Try
    J:=P.Parse;
    If (J=Nil) then
      FContext.Fail('Parse of string "'+S+'" fails');
    TestJSONType(J,jtString);
    TestAsString(J,aResult);
    if Pos('\u',S)=0 then
      TestJSON(J,'"'+S+'"');
  Finally
    FreeAndNil(J);
    FreeAndNil(P);
  end;
end;

procedure TTestParser.DoTestFloat(F : TJSONFloat);

Var
  S : String;

begin
  Str(F,S);
  DoTestFloat(F,S);
end;

procedure TTestParser.DoTestFloat(F : TJSONFloat; S : String);

Var
  P : TJSONParser;
  J : TJSONData;

begin
  P:=TJSONParser.Create(S,[joUTF8]);
  Try
    J:=P.Parse;
    If (J=Nil) then
      FContext.Fail('Parse of float '+S+' fails');
    TestJSONType(J,jtNumber);
    TestAsFloat(J,F);
  Finally
    FreeAndNil(J);
    FreeAndNil(P);
  end;
end;



procedure RunTTestParserTestEmpty(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmpty';
    lFixture.SetUp;
    lFixture.TestEmpty;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestNull(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNull';
    lFixture.SetUp;
    lFixture.TestNull;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestTrue(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestTrue';
    lFixture.SetUp;
    lFixture.TestTrue;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestFalse(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFalse';
    lFixture.SetUp;
    lFixture.TestFalse;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestFloat(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFloat';
    lFixture.SetUp;
    lFixture.TestFloat;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestInteger(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInteger';
    lFixture.SetUp;
    lFixture.TestInteger;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestInt64(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInt64';
    lFixture.SetUp;
    lFixture.TestInt64;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestString(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestString';
    lFixture.SetUp;
    lFixture.TestString;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestArray(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestArray';
    lFixture.SetUp;
    lFixture.TestArray;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestObject(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestObject';
    lFixture.SetUp;
    lFixture.TestObject;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestObjectError(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestObjectError';
    lFixture.SetUp;
    lFixture.TestObjectError;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestObjectKeyIdentifier(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestObjectKeyIdentifier';
    lFixture.SetUp;
    lFixture.TestObjectKeyIdentifier;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestObjectKeyIdentifierStrict(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestObjectKeyIdentifierStrict';
    lFixture.SetUp;
    lFixture.TestObjectKeyIdentifierStrict;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestTrailingComma(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestTrailingComma';
    lFixture.SetUp;
    lFixture.TestTrailingComma;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestTrailingCommaErrorArray(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestTrailingCommaErrorArray';
    lFixture.SetUp;
    lFixture.TestTrailingCommaErrorArray;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestTrailingCommaErrorObject(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestTrailingCommaErrorObject';
    lFixture.SetUp;
    lFixture.TestTrailingCommaErrorObject;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestMixed(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMixed';
    lFixture.SetUp;
    lFixture.TestMixed;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestComment(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestComment';
    lFixture.SetUp;
    lFixture.TestComment;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestErrors(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestErrors';
    lFixture.SetUp;
    lFixture.TestErrors;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestClasses(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClasses';
    lFixture.SetUp;
    lFixture.TestClasses;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestHandler(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestHandler';
    lFixture.SetUp;
    lFixture.TestHandler;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestNoHandlerError(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNoHandlerError';
    lFixture.SetUp;
    lFixture.TestNoHandlerError;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestHandlerResult(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestHandlerResult';
    lFixture.SetUp;
    lFixture.TestHandlerResult;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestEmptyLine(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmptyLine';
    lFixture.SetUp;
    lFixture.TestEmptyLine;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestStartEmptyLine(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestStartEmptyLine';
    lFixture.SetUp;
    lFixture.TestStartEmptyLine;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestObjectEmptyLine(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestObjectEmptyLine';
    lFixture.SetUp;
    lFixture.TestObjectEmptyLine;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestCommentLine(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCommentLine';
    lFixture.SetUp;
    lFixture.TestCommentLine;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestFirstLineComment(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFirstLineComment';
    lFixture.SetUp;
    lFixture.TestFirstLineComment;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestMultiLineComment(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMultiLineComment';
    lFixture.SetUp;
    lFixture.TestMultiLineComment;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestIgnoreDuplicates(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIgnoreDuplicates';
    lFixture.SetUp;
    lFixture.TestIgnoreDuplicates;
  finally lFixture.Free; end;
end;

procedure RunTTestParserTestNoIgnoreDuplicates(AContext: TNXTestContext);
var lFixture: TTestParser;
begin
  lFixture:=TTestParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNoIgnoreDuplicates';
    lFixture.SetUp;
    lFixture.TestNoIgnoreDuplicates;
  finally lFixture.Free; end;
end;

procedure RegistertestjsonparserTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('testjsonparser.TTestParser');
  lSuite.AddTest('TestEmpty', @RunTTestParserTestEmpty);
  lSuite.AddTest('TestNull', @RunTTestParserTestNull);
  lSuite.AddTest('TestTrue', @RunTTestParserTestTrue);
  lSuite.AddTest('TestFalse', @RunTTestParserTestFalse);
  lSuite.AddTest('TestFloat', @RunTTestParserTestFloat);
  lSuite.AddTest('TestInteger', @RunTTestParserTestInteger);
  lSuite.AddTest('TestInt64', @RunTTestParserTestInt64);
  lSuite.AddTest('TestString', @RunTTestParserTestString);
  lSuite.AddTest('TestArray', @RunTTestParserTestArray);
  lSuite.AddTest('TestObject', @RunTTestParserTestObject);
  lSuite.AddTest('TestObjectError', @RunTTestParserTestObjectError);
  lSuite.AddTest('TestObjectKeyIdentifier', @RunTTestParserTestObjectKeyIdentifier);
  lSuite.AddTest('TestObjectKeyIdentifierStrict', @RunTTestParserTestObjectKeyIdentifierStrict);
  lSuite.AddTest('TestTrailingComma', @RunTTestParserTestTrailingComma);
  lSuite.AddTest('TestTrailingCommaErrorArray', @RunTTestParserTestTrailingCommaErrorArray);
  lSuite.AddTest('TestTrailingCommaErrorObject', @RunTTestParserTestTrailingCommaErrorObject);
  lSuite.AddTest('TestMixed', @RunTTestParserTestMixed);
  lSuite.AddTest('TestComment', @RunTTestParserTestComment);
  lSuite.AddTest('TestErrors', @RunTTestParserTestErrors);
  lSuite.AddTest('TestClasses', @RunTTestParserTestClasses);
  lSuite.AddTest('TestHandler', @RunTTestParserTestHandler);
  lSuite.AddTest('TestNoHandlerError', @RunTTestParserTestNoHandlerError);
  lSuite.AddTest('TestHandlerResult', @RunTTestParserTestHandlerResult);
  lSuite.AddTest('TestEmptyLine', @RunTTestParserTestEmptyLine);
  lSuite.AddTest('TestStartEmptyLine', @RunTTestParserTestStartEmptyLine);
  lSuite.AddTest('TestObjectEmptyLine', @RunTTestParserTestObjectEmptyLine);
  lSuite.AddTest('TestCommentLine', @RunTTestParserTestCommentLine);
  lSuite.AddTest('TestFirstLineComment', @RunTTestParserTestFirstLineComment);
  lSuite.AddTest('TestMultiLineComment', @RunTTestParserTestMultiLineComment);
  lSuite.AddTest('TestIgnoreDuplicates', @RunTTestParserTestIgnoreDuplicates);
  lSuite.AddTest('TestNoIgnoreDuplicates', @RunTTestParserTestNoIgnoreDuplicates);
end;

end.

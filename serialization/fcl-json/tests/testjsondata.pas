{
    This file is part of the Free Component Library

    JSON FPCUNit test for data structures
    Copyright (c) 2007 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
{$mode objfpc}
{$h+}
{$codepage utf8}
unit testjsondata;

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpjson;

type
   TMyNull     = Class(TJSONNull);
   TMyInteger  = Class(TJSONIntegerNumber);
   TMyInt64    = Class(TJSONInt64Number);
   TMyQWord    = Class(TJSONQWordNumber);
   TMyFloat    = Class(TJSONFloatNumber);
   TMyString   = Class(TJSONString);
   TMyBoolean  = Class(TJSONBoolean);
   TMyArray    = Class(TJSONArray);
   TMyObject   = Class(TJSONObject);

  { TTestJSONString }

  TTestJSONString = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  Private
    Procedure TestTo(Const Src,Dest : String; Strict : Boolean = False);
    Procedure TestFrom(Const Src,Dest : String);
  public
    Procedure TestJSONStringToString;
    Procedure TestStringToJSONString;
  end;

  { TTestJSON }

  TTestJSON = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
  Protected
    procedure SetDefaultInstanceTypes;
    procedure SetMyInstanceTypes;
    Procedure SetUp; virtual;
    Procedure TestItemCount(J : TJSONData;Expected : Integer);
    Procedure TestJSONType(J : TJSONData;Expected : TJSONType);
    Procedure TestJSON(J : TJSONData;Expected : TJSONStringType);
    Procedure TestIsNull(J : TJSONData;Expected : Boolean);
    Procedure TestAsBoolean(J : TJSONData;Expected : Boolean; ExpectError : boolean = False);
    Procedure TestAsInteger(J : TJSONData; Expected : Integer; ExpectError : boolean = False);
    Procedure TestAsInt64(J : TJSONData; Expected : Int64; ExpectError : boolean = False);
    Procedure TestAsQWord(J : TJSONData; Expected : QWord; ExpectError : boolean = False);
    Procedure TestAsString(J : TJSONData; Expected : String; ExpectError : boolean = False);
    Procedure TestAsFloat(J : TJSONData; Expected : TJSONFloat; ExpectError : boolean = False);
  end;

  { TTestNull }

  TTestNull = class(TTestJSON)
  public
    procedure TestNull;
    Procedure TestClone;
    Procedure TestMyClone;
    Procedure TestFormat;
  end;

  { TTestBoolean }

  TTestBoolean = class(TTestJSON)
  public
    procedure TestTrue;
    procedure TestFalse;
    Procedure TestClone;
    Procedure TestMyClone;
    Procedure TestFormat;
  end;

  { TTestInteger }

  TTestInteger = class(TTestJSON)
  Private
    Procedure DoTest(I : Integer);
  public
    procedure TestPositive;
    procedure TestNegative;
    procedure TestZero;
    Procedure TestClone;
    Procedure TestMyClone;
    Procedure TestFormat;
  end;

  { TTestInt64 }

  TTestInt64 = class(TTestJSON)
  Private
    Procedure DoTest(I : Int64);
  public
    procedure TestPositive;
    procedure TestNegative;
    procedure TestZero;
    Procedure TestClone;
    Procedure TestMyClone;
    Procedure TestFormat;
  end;

  { TTestQword }

  TTestQword = class(TTestJSON)
  Private
    Procedure DoTest(Q : QWord);
  public
    procedure TestPositive;
    procedure TestZero;
    Procedure TestClone;
    Procedure TestMyClone;
    Procedure TestFormat;
  end;

  { TTestFloat }

  TTestFloat = class(TTestJSON)
  Private
    Procedure DoTest(F : TJSONFloat);
  public
    procedure TestPositive;
    procedure TestNegative;
    procedure TestZero;
    Procedure TestClone;
    Procedure TestMyClone;
    Procedure TestFormat;
  end;

  { TTestString }

  TTestString = class(TTestJSON)
  private
    procedure DoTestFloat(F: TJSOnFloat; S: String; OK: Boolean);
  public
    procedure TestString;
    procedure TestControlString;
    procedure TestSolidus;
    procedure TestInteger;
    procedure TestNegativeInteger;
    procedure TestFloat;
    procedure TestNegativeFloat;
    Procedure TestBooleanTrue;
    Procedure TestBooleanFalse;
    Procedure TestClone;
    Procedure TestMyClone;
    Procedure TestFormat;
  end;

  { TTestArray }

  TTestArray = class(TTestJSON)
  private
    procedure TestAddBoolean(B : Boolean);
    procedure TestInsertBoolean(B : Boolean);
  public
    Procedure TestCreate;
    Procedure TestCreateString;
    Procedure TestCreatePchar;
    procedure TestCreateStrings;
    procedure TestCreateStringsCompressed;
    procedure TestCreateInteger;
    procedure TestCreateInt64;
    procedure TestCreateFloat;
    procedure TestCreateBoolean;
    procedure TestCreateObject;
    procedure TestCreateJSONString;
    procedure TestCreateJSONStringSpecialChars;
    procedure TestCreateJSONObject;
    procedure TestCreateNilPointer;
    procedure TestCreatePointer;
    procedure TestAddInteger;
    procedure TestAddInt64;
    procedure TestAddFloat;
    procedure TestAddBooleanTrue;
    procedure TestAddBooleanFalse;
    procedure TestAddString;
    procedure TestAddNull;
    procedure TestAddObject;
    procedure TestAddArray;
    procedure TestInsertInteger;
    procedure TestInsertInt64;
    procedure TestInsertFloat;
    procedure TestInsertBooleanTrue;
    procedure TestInsertBooleanFalse;
    procedure TestInsertString;
    procedure TestInsertNull;
    procedure TestInsertObject;
    procedure TestInsertArray;
    procedure TestMove;
    procedure TestExchange;
    procedure TestDelete;
    procedure TestRemove;
    Procedure TestClone;
    Procedure TestMyClone;
    Procedure TestFormat;
    Procedure TestFormatNil;
  end;

  { TTestObject }

  TTestObject = class(TTestJSON)
  private
    FJ: TJSONObject;
    procedure AppendA;
  protected
    Procedure Setup; override;
    Procedure TearDown; override;
    procedure TestAddBoolean(B : Boolean);
    Procedure TestAccessError;
    Property J : TJSONObject Read FJ;
  public
    Procedure TestCreate;
    Procedure TestCreateString;
    Procedure TestCreateStringUnquoted;
    Procedure TestCreatePchar;
    Procedure TestCreatePcharUnquoted;
    procedure TestCreateStrings;
    procedure TestCreateStringsCompressed;
    procedure TestCreateStringsCompressedUnquoted;
    procedure TestCreateInteger;
    procedure TestCreateIntegerUnquoted;
    procedure TestCreateInt64;
    procedure TestCreateInt64Unquoted;
    procedure TestCreateQWord;
    procedure TestCreateQWordUnquoted;
    procedure TestCreateFloat;
    procedure TestCreateFloatUnquoted;
    procedure TestCreateBoolean;
    procedure TestCreateBooleanUnquoted;
    procedure TestCreateObject;
    procedure TestCreateJSONUnicodeString;
    procedure TestCreateJSONWideString;
    procedure TestCreateJSONString;
    procedure TestCreateJSONStringUnquoted;
    procedure TestCreateJSONObject;
    procedure TestCreateJSONObjectUnquoted;
    procedure TestCreateNilPointer;
    procedure TestCreatePointer;
    procedure TestAddInteger;
    procedure TestAddInt64;
    procedure TestAddFloat;
    procedure TestAddBooleanTrue;
    procedure TestAddBooleanFalse;
    procedure TestAddString;
    procedure TestAddNull;
    procedure TestAddObject;
    procedure TestAddArray;
    procedure TestDelete;
    procedure TestRemove;
    procedure TestClone;
    procedure TestMyClone;
    procedure TestExtract;
    Procedure TestNonExistingAccessError;
    Procedure TestFormat;
    Procedure TestFormatNil;
    Procedure TestFormatForceLF;
    Procedure TestFind;
    Procedure TestIfFind;
    Procedure TestDuplicate;
  end;

  { TTestJSONPath }

  TTestJSONPath = class(TTestJSON)
  private
    FData: TJSONData;
  Protected
    Procedure TearDown; override;
    Property Data : TJSONData read FData Write FData;
  public
    Procedure TestNullEmpty;
    Procedure TestNullGet;
    Procedure TestNullNonExisting;
    Procedure TestNullNotEmpty;
    Procedure TestBooleanEmpty;
    Procedure TestBooleanNotEmpty;
    Procedure TestIntegerEmpty;
    Procedure TestIntegerNotEmpty;
    Procedure TestInt64Empty;
    Procedure TestInt64NotEmpty;
    Procedure TestFloatEmpty;
    Procedure TestFloatNotEmpty;
    Procedure TestStringEmpty;
    Procedure TestStringNotEmpty;
    Procedure TestArrayEmpty;
    Procedure TestArrayNotIndex;
    Procedure TestArrayIncompleteIndex;
    Procedure TestArrayNonNumericalIndex;
    Procedure TestArrayOutOfRangeIndex;
    Procedure TestArrayCorrectIndex;
    Procedure TestArrayRecursiveArray;
    Procedure TestArrayRecursiveObject;
    Procedure TestObjectEmpty;
    Procedure TestObjectDots;
    Procedure TestObjectExisting;
    Procedure TestObjectNonExisting;
    Procedure TestObjectTrailingDot;
    Procedure TestObjectRecursiveArray;
    Procedure TestObjectRecursiveObject;
    Procedure TestDeepRecursive;
  end;

  { TTestFactory }

  TTestFactory = class(TTestJSON)
  Private
    FType : TJSONInstanceType;
    FClass : TJSONDataClass;
    FData: TJSONData;
  Protected
    Procedure DoSet;
    Procedure TearDown; override;
    Procedure AssertElement0(AClass : TJSONDataClass);
    Procedure AssertElementA(AClass : TJSONDataClass);
    Property Data : TJSONData read FData Write FData;
  public
    Procedure TestSet;
    Procedure TestSetInvalid;
    Procedure CreateNull;
    Procedure CreateInteger;
    Procedure CreateInt64;
    Procedure CreateFloat;
    Procedure CreateBoolean;
    Procedure CreateString;
    Procedure CreateArray;
    Procedure CreateObject;
    Procedure ArrayAddNull;
    Procedure ArrayAddInteger;
    Procedure ArrayAddInt64;
    Procedure ArrayAddFloat;
    Procedure ArrayAddBoolean;
    Procedure ArrayAddString;
    Procedure ArrayCreateNull;
    Procedure ArrayCreateInteger;
    Procedure ArrayCreateInt64;
    Procedure ArrayCreateFloat;
    Procedure ArrayCreateBoolean;
    Procedure ArrayCreateString;
    Procedure ObjectAddNull;
    Procedure ObjectAddInteger;
    Procedure ObjectAddInt64;
    Procedure ObjectAddFloat;
    Procedure ObjectAddBoolean;
    Procedure ObjectAddString;
    Procedure ObjectCreateNull;
    Procedure ObjectCreateInteger;
    Procedure ObjectCreateInt64;
    Procedure ObjectCreateFloat;
    Procedure ObjectCreateBoolean;
    Procedure ObjectCreateString;
  end;

  { TTestIterator }

  TTestIterator = class(TTestJSON)
  private
    FData: TJSONData;
  Protected
    Procedure TearDown; override;
    Procedure TestSingle;
    Procedure TestLoop(ACount : Integer);
    Property Data : TJSONData Read FData Write FData;
  public
    Procedure TestNull;
    Procedure TestInteger;
    Procedure TestInt64;
    Procedure TestFloat;
    Procedure TestBoolean;
    Procedure TestString;
    Procedure TestArray;
    Procedure TestObject;
  end;


procedure RegistertestjsondataTests(ARegistry: TNXTestRegistry);

implementation

{ TTestIterator }

procedure TTestIterator.TearDown;
begin
  FreeAndNil(FData);
  inherited TearDown;
end;

procedure TTestIterator.TestSingle;

Var
  F : TJSONEnum;
  C : Integer;

begin
  C:=0;
  For F in Data do
   begin
   Inc(C);
   If C>1 then
     FContext.Fail(Data.ClassName+' loops more than once');
   FContext.AssertTrue(('')=(F.Key), Data.ClassName+' has empty key');
   FContext.AssertTrue((0)=(F.KeyNum), Data.ClassName+' has empty numerical key');
   FContext.AssertTrue((Data)=(F.Value), Data.ClassName+' returns data');
   end;
  If C<1 then
    FContext.Fail(Data.ClassName+' Loops not even once');
end;

procedure TTestIterator.TestLoop(ACount: Integer);
Var
  F : TJSONEnum;
  C : Integer;

begin
  C:=0;
  For F in Data do
   begin
   FContext.AssertTrue((IntToStr(C))=(F.Key), Data.ClassName+' has correct string key');
   FContext.AssertTrue((C)=(F.KeyNum), Data.ClassName+' has correct numerical key');
   FContext.AssertTrue((Data.Items[C])=(F.Value), Data.ClassName+' returns correct data');
   Inc(C);
   end;
  FContext.AssertTrue((ACount)=(C), Data.ClassName+' correct loop count');
end;

procedure TTestIterator.TestNull;
begin
  Data:=TJSONNull.Create;
  TestSingle;
end;

procedure TTestIterator.TestInteger;
begin
  Data:=TJSONIntegerNumber.Create(1);
  TestSingle;
end;

procedure TTestIterator.TestInt64;
begin
  Data:=TJSONInt64Number.Create(1);
  TestSingle;
end;

procedure TTestIterator.TestFloat;
begin
  Data:=TJSONFloatNumber.Create(1.2);
  TestSingle;
end;

procedure TTestIterator.TestBoolean;
begin
  Data:=TJSONBoolean.Create(True);
  TestSingle;
end;

procedure TTestIterator.TestString;
begin
  Data:=TJSONString.Create('Data');
  TestSingle;
end;

procedure TTestIterator.TestArray;
begin
  Data:=TJSONArray.Create([1,2,3]);
  TestLoop(3);
end;

procedure TTestIterator.TestObject;
begin
  Data:=TJSONObject.Create(['0',1,'1',2,'2',3]);
  TestLoop(3);
end;

{ TTestFactory }

procedure TTestFactory.DoSet;
begin
  SetJSONInstanceType(FType,FClass);
end;

procedure TTestFactory.TearDown;
begin
  FreeAndNil(FData);
  inherited TearDown;
end;

procedure TTestFactory.AssertElement0(AClass: TJSONDataClass);
begin
  FContext.AssertTrue((TMyArray)=(Data.ClassType), 'Correct class');
  FContext.AssertTrue((1)=(Data.Count), 'Have 1 element');
  FContext.AssertTrue((AClass)=((Data as TJSONArray)[0].ClassType), 'Correct class');
end;

procedure TTestFactory.AssertElementA(AClass: TJSONDataClass);
begin
  FContext.AssertTrue((TMyObject)=(Data.ClassType), 'Correct class');
  FContext.AssertTrue((0)=(TMyObject(Data).IndexOfName('a')), 'Have element a');
  FContext.AssertTrue((AClass)=((Data as TJSONObject).Elements['a'].ClassType), 'Correct class');
end;

procedure TTestFactory.TestSet;
begin
  SetMyInstanceTypes;
  FContext.AssertTrue((TJSONData)=(GetJSONInstanceType(jitUnknown)), 'Correct type for unknown');
  FContext.AssertTrue((TMyInteger)=(GetJSONInstanceType(jitNumberInteger)), 'Correct type for integer');
  FContext.AssertTrue((TMyInt64)=(GetJSONInstanceType(jitNumberInt64)), 'Correct type for int64');
  FContext.AssertTrue((TMyFloat)=(GetJSONInstanceType(jitNumberFloat)), 'Correct type for float');
  FContext.AssertTrue((TMyBoolean)=(GetJSONInstanceType(jitBoolean)), 'Correct type for boolean');
  FContext.AssertTrue((TMyNull)=(GetJSONInstanceType(jitNUll)), 'Correct type for null');
  FContext.AssertTrue((TMyString)=(GetJSONInstanceType(jitString)), 'Correct type for String');
  FContext.AssertTrue((TMyArray)=(GetJSONInstanceType(jitArray)), 'Correct type for Array');
  FContext.AssertTrue((TMyObject)=(GetJSONInstanceType(jitObject)), 'Correct type for Object');
end;

procedure TTestFactory.TestSetInvalid;

Const
  MyJSONInstanceTypes :
    Array [TJSONInstanceType] of TJSONDataClass = (TJSONData, TMyInteger,
    TMyInt64,TMyQWord,TMyFloat, TMyString, TMyBoolean, TMyNull, TMyArray,
    TMyObject);

Var
  Ti : TJSONInstanceType;

begin
  For ti:=Succ(Low(TJSONInstanceType)) to High(TJSONInstanceType) do
    begin
    FType:=Ti;
    FClass:=MyJSONInstanceTypes[Pred(ti)];
    FContext.AssertRaises(EJSON, @DoSet, 'Set '+FClass.ClassName);
    end;
  FType:=jitString;
  FClass:=Nil;
  FContext.AssertRaises(EJSON, @DoSet, 'Set Nil');
end;

procedure TTestFactory.CreateNull;
begin
  SetMyInstanceTypes;
  Data:=CreateJSON;
  FContext.AssertTrue((TMyNull)=(Data.ClassType), 'Correct class');
end;

procedure TTestFactory.CreateInteger;
begin
  SetMyInstanceTypes;
  Data:=CreateJSON(1);
  FContext.AssertTrue((TMyInteger)=(Data.ClassType), 'Correct class');
end;

procedure TTestFactory.CreateInt64;
begin
  SetMyInstanceTypes;
  Data:=CreateJSON(Int64(1));
  FContext.AssertTrue((TMyInt64)=(Data.ClassType), 'Correct class');
end;

procedure TTestFactory.CreateFloat;
begin
  SetMyInstanceTypes;
  Data:=CreateJSON(1.2);
  FContext.AssertTrue((TMyFloat)=(Data.ClassType), 'Correct class');
end;

procedure TTestFactory.CreateBoolean;
begin
  SetMyInstanceTypes;
  Data:=CreateJSON(True);
  FContext.AssertTrue((TMyBoolean)=(Data.ClassType), 'Correct class');
end;

procedure TTestFactory.CreateString;
begin
  SetMyInstanceTypes;
  Data:=CreateJSON('True');
  FContext.AssertTrue((TMyString)=(Data.ClassType), 'Correct class');
end;

procedure TTestFactory.CreateArray;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONArray(['True']);
  FContext.AssertTrue((TMyArray)=(Data.ClassType), 'Correct class');
end;

procedure TTestFactory.CreateObject;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONObject(['a','True']);
  FContext.AssertTrue((TMyObject)=(Data.ClassType), 'Correct class');
end;

procedure TTestFactory.ArrayAddNull;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONArray([]);
  TJSONArray(Data).Add();
  AssertElement0(TMyNull);
end;

procedure TTestFactory.ArrayAddInteger;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONArray([]);
  TJSONArray(Data).Add(1);
  AssertElement0(TMyInteger);
end;

procedure TTestFactory.ArrayAddInt64;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONArray([]);
  TJSONArray(Data).Add(Int64(1));
  AssertElement0(TMyInt64);
end;

procedure TTestFactory.ArrayAddFloat;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONArray([]);
  TJSONArray(Data).Add(1.2);
  AssertElement0(TMyFloat);
end;

procedure TTestFactory.ArrayAddBoolean;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONArray([]);
  TJSONArray(Data).Add(True);
  AssertElement0(TMyBoolean);
end;

procedure TTestFactory.ArrayAddString;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONArray([]);
  TJSONArray(Data).Add('True');
  AssertElement0(TMyString);
end;

procedure TTestFactory.ArrayCreateNull;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONArray([Nil]);
  AssertElement0(TMyNull);
end;

procedure TTestFactory.ArrayCreateInteger;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONArray([1]);
  AssertElement0(TMyInteger);
end;

procedure TTestFactory.ArrayCreateInt64;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONArray([int64(1)]);
  AssertElement0(TMyInt64);
end;

procedure TTestFactory.ArrayCreateFloat;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONArray([1.2]);
  AssertElement0(TMyFloat);
end;

procedure TTestFactory.ArrayCreateBoolean;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONArray([True]);
  AssertElement0(TMyBoolean);
end;

procedure TTestFactory.ArrayCreateString;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONArray(['true']);
  AssertElement0(TMyString);
end;

procedure TTestFactory.ObjectAddNull;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONObject([]);
  TJSONObject(Data).Add('a');
  AssertElementA(TMyNull);
end;

procedure TTestFactory.ObjectAddInteger;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONObject([]);
  TJSONObject(Data).Add('a',1);
  AssertElementA(TMyInteger);
end;

procedure TTestFactory.ObjectAddInt64;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONObject([]);
  TJSONObject(Data).Add('a',Int64(1));
  AssertElementA(TMyInt64);
end;

procedure TTestFactory.ObjectAddFloat;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONObject([]);
  TJSONObject(Data).Add('a',1.2);
  AssertElementA(TMyFloat);
end;

procedure TTestFactory.ObjectAddBoolean;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONObject([]);
  TJSONObject(Data).Add('a',True);
  AssertElementA(TMyBoolean);
end;

procedure TTestFactory.ObjectAddString;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONObject([]);
  TJSONObject(Data).Add('a','True');
  AssertElementA(TMyString);
end;

procedure TTestFactory.ObjectCreateNull;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONObject(['a',Nil]);
  AssertElementA(TMyNull);
end;

procedure TTestFactory.ObjectCreateInteger;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONObject(['a',1]);
  AssertElementA(TMyInteger);
end;

procedure TTestFactory.ObjectCreateInt64;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONObject(['a',int64(1)]);
  AssertElementA(TMyInt64);
end;

procedure TTestFactory.ObjectCreateFloat;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONObject(['a',1.2]);
  AssertElementA(TMyFloat);
end;

procedure TTestFactory.ObjectCreateBoolean;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONObject(['a',True]);
  AssertElementA(TMyBoolean);
end;

procedure TTestFactory.ObjectCreateString;
begin
  SetMyInstanceTypes;
  Data:=CreateJSONObject(['a','true']);
  AssertElementA(TMyString);
end;

{ TTestJSONPath }

procedure TTestJSONPath.TearDown;
begin
  FreeAndNil(FData);
  inherited TearDown;
end;

procedure TTestJSONPath.TestNullEmpty;
begin
  Data:=TJSONNull.Create;
  FContext.AssertTrue((Data)=(Data.FIndPath('')), 'Empty on NULL returns object itself');
end;

procedure TTestJSONPath.TestNullGet;
begin
  Data:=TJSONNull.Create;
  FContext.AssertTrue((Data)=(Data.GetPath('')), 'Empty get on NULL returns object itself');
end;

procedure TTestJSONPath.TestNullNonExisting;

Var
  Msg : String;

begin
  Data:=TJSONNull.Create;
  try
    Data.GetPath('a.b.c');
    Msg:='No exception raised'
  except
    on E : Exception do
      begin
      If Not (E is EJSON) then
        Msg:='Wrong exception class. Got '+E.ClassName+' instead of EJSON'
      else
        If E.Message<>'Path "a.b.c" invalid: element "a.b.c" not found.' then
          Msg:='Wrong exception message, expected: "Path "a.b.c" invalid: element "a.b.c" not found.", actual: "'+E.Message+'"';
      end;
  end;
  If (Msg<>'') then
    FContext.Fail(Msg);
end;

procedure TTestJSONPath.TestNullNotEmpty;
begin
  Data:=TJSONNull.Create;
  FContext.AssertTrue((Data.FindPath('a'))=nil, 'Not empty on NULL returns nil');
end;

procedure TTestJSONPath.TestBooleanEmpty;
begin
  Data:=TJSONBoolean.Create(true);
  FContext.AssertTrue((Data)=(Data.FIndPath('')), 'Empty on Boolean returns object itself');
end;

procedure TTestJSONPath.TestBooleanNotEmpty;
begin
  Data:=TJSONBoolean.Create(True);
  FContext.AssertTrue((Data.FindPath('a'))=nil, 'Not empty on Boolean returns nil');
end;

procedure TTestJSONPath.TestIntegerEmpty;
begin
  Data:=TJSONIntegerNumber.Create(1);
  FContext.AssertTrue((Data)=(Data.FIndPath('')), 'Empty on integer returns object itself');
end;

procedure TTestJSONPath.TestIntegerNotEmpty;
begin
  Data:=TJSONIntegerNumber.Create(1);
  FContext.AssertTrue((Data.FIndPath('a'))=nil, 'Not Empty on integer returns object itself');
end;

procedure TTestJSONPath.TestInt64Empty;
begin
  Data:=TJSONInt64Number.Create(1);
  FContext.AssertTrue((Data)=(Data.FIndPath('')), 'Empty on Int64 returns object itself');
end;

procedure TTestJSONPath.TestInt64NotEmpty;
begin
  Data:=TJSONInt64Number.Create(1);
  FContext.AssertTrue((Data.FIndPath('a'))=nil, 'Not Empty on Int64 returns object itself');
end;

procedure TTestJSONPath.TestFloatEmpty;
begin
  Data:=TJSONFloatNumber.Create(1);
  FContext.AssertTrue((Data)=(Data.FIndPath('')), 'Empty on Float returns object itself');
end;

procedure TTestJSONPath.TestFloatNotEmpty;
begin
  Data:=TJSONFloatNumber.Create(1);
  FContext.AssertTrue((Data.FIndPath('a'))=nil, 'Not Empty on Float returns object itself');
end;

procedure TTestJSONPath.TestStringEmpty;
begin
  Data:=TJSONString.Create('1');
  FContext.AssertTrue((Data)=(Data.FIndPath('')), 'Empty on String returns object itself');
end;

procedure TTestJSONPath.TestStringNotEmpty;
begin
  Data:=TJSONString.Create('1');
  FContext.AssertTrue((Data.FIndPath('a'))=nil, 'Not Empty on String returns object itself');
end;

procedure TTestJSONPath.TestArrayEmpty;
begin
  Data:=TJSONArray.Create([1,2,3]);
  FContext.AssertTrue((Data)=(Data.FIndPath('')), 'Empty on array returns object itself');
end;

procedure TTestJSONPath.TestArrayNotIndex;
begin
  Data:=TJSONArray.Create([1,2,3]);
  FContext.AssertTrue((Data.FindPath('oo'))=nil, 'Not index indication on array returns object itself');
end;

procedure TTestJSONPath.TestArrayIncompleteIndex;
begin
  Data:=TJSONArray.Create([1,2,3]);
  FContext.AssertTrue((Data.FindPath('[1'))=nil, 'Not complete index indication on array returns object itself');
  FContext.AssertTrue((Data.FindPath('['))=nil, 'Not complete index indication on array returns object itself');
end;

procedure TTestJSONPath.TestArrayNonNumericalIndex;
begin
  Data:=TJSONArray.Create([1,2,3]);
  FContext.AssertTrue((Data.FindPath('[a]'))=nil, 'Not complete index indication on array returns object itself');
end;

procedure TTestJSONPath.TestArrayOutOfRangeIndex;
begin
  Data:=TJSONArray.Create([1,2,3]);
  FContext.AssertTrue((Data.FindPath('[-1]'))=nil, 'Not complete index indication on array returns object itself');
  FContext.AssertTrue((Data.FindPath('[3]'))=nil, 'Not complete index indication on array returns object itself');
end;

procedure TTestJSONPath.TestArrayCorrectIndex;
begin
  Data:=TJSONArray.Create([1,2,3]);
  FContext.AssertTrue((Data.Items[0])=(Data.FindPath('[0]')), 'Index 0 on array returns item 0');
  FContext.AssertTrue((Data.Items[1])=(Data.FindPath('[1]')), 'Index 1 on array returns item 1');
  FContext.AssertTrue((Data.Items[2])=(Data.FindPath('[2]')), 'Index 2 on array returns item 2');
end;

procedure TTestJSONPath.TestArrayRecursiveArray;

Var
  A : TJSONArray;

begin
  A:=TJSONArray.Create([1,2,3]);
  Data:=TJSONArray.Create([A,1,2,3]);
  FContext.AssertTrue((A.Items[0])=(Data.FindPath('[0][0]')), 'Index [0][0] on array returns item 0');
  FContext.AssertTrue((A.Items[1])=(Data.FindPath('[0][1]')), 'Index [0][1] on array returns item 1');
  FContext.AssertTrue((A.Items[2])=(Data.FindPath('[0][2]')), 'Index [0][2] on array returns item 2');
end;

procedure TTestJSONPath.TestArrayRecursiveObject;

Var
  A : TJSONObject;

begin
  A:=TJSONObject.Create(['a',1,'b',2,'c',3]);
  Data:=TJSONArray.Create([A,1,2,3]);
  FContext.AssertTrue((A.Elements['a'])=(Data.FindPath('[0]a')), '[0]a on array returns element a of item 0');
  FContext.AssertTrue((A.Elements['b'])=(Data.FindPath('[0]b')), '[0]b on array returns element b of item 0');
  FContext.AssertTrue((A.Elements['c'])=(Data.FindPath('[0]c')), '[0]c on array returns element c of item 0');
  FContext.AssertTrue((A.Elements['a'])=(Data.FindPath('[0].a')), '[0].a on array returns element a of item 0');
  FContext.AssertTrue((A.Elements['b'])=(Data.FindPath('[0].b')), '[0].b on array returns element b of item 0');
  FContext.AssertTrue((A.Elements['c'])=(Data.FindPath('[0].c')), '[0].c on array returns element c of item 0');
end;

procedure TTestJSONPath.TestObjectEmpty;
begin
  Data:=TJSONObject.Create(['a',1,'b',2,'c',3]);
  FContext.AssertTrue((Data)=(Data.FindPath('')), 'Empty on object returns object');
end;

procedure TTestJSONPath.TestObjectDots;
begin
  Data:=TJSONObject.Create(['a',1,'b',2,'c',3]);
  FContext.AssertTrue((Data)=(Data.FindPath('.')), 'Dot on object returns object');
  FContext.AssertTrue((Data)=(Data.FindPath('..')), '2 Dots on object returns object');
  FContext.AssertTrue((Data)=(Data.FindPath('...')), '3 Dots on object returns object');
end;

procedure TTestJSONPath.TestObjectExisting;
begin
  Data:=TJSONObject.Create(['a',1,'b',2,'c',3]);
  FContext.AssertTrue((TJSONObject(Data).Elements['a'])=(Data.FindPath('a')), 'a on object returns element a');
  FContext.AssertTrue((TJSONObject(Data).Elements['a'])=(Data.FindPath('.a')), '.a on object returns element a');
  FContext.AssertTrue((TJSONObject(Data).Elements['a'])=(Data.FindPath('..a')), '..a on object returns element a');
end;

procedure TTestJSONPath.TestObjectNonExisting;
begin
  Data:=TJSONObject.Create(['a',1,'b',2,'c',3]);
  FContext.AssertTrue((Data.FindPath('d'))=nil, 'd on object returns nil');
end;

procedure TTestJSONPath.TestObjectTrailingDot;
begin
  Data:=TJSONObject.Create(['a',1,'b',2,'c',3]);
  FContext.AssertTrue((Data.FindPath('a.'))=nil, 'a. on object returns nil');
end;

procedure TTestJSONPath.TestObjectRecursiveArray;

Var
  A : TJSONArray;

begin
  A:=TJSONArray.Create([1,2,3]);
  Data:=TJSONObject.Create(['a',A,'b',2,'c',3]);
  FContext.AssertTrue((A.Items[0])=(Data.FindPath('a[0]')), 'a[0] returns item 0 of array a');
end;

procedure TTestJSONPath.TestObjectRecursiveObject;
Var
  O : TJSONObject;
  D : TJSONData;
begin
  D :=TJSONIntegerNumber.Create(1);
  O:=TJSONObject.Create(['b',D]);
  Data:=TJSONObject.Create(['a',O]);
  FContext.AssertTrue((D)=(Data.FindPath('a.b')), 'a.b returns correct data ');
  FContext.AssertTrue((D)=(Data.FindPath('a..b')), 'a..b returns correct data ');
end;

procedure TTestJSONPath.TestDeepRecursive;
Var
  A : TJSONArray;
  D : TJSONData;
begin
  D :=TJSONIntegerNumber.Create(1);
  A:=TJSONArray.Create([0,'string',TJSONObject.Create(['b',D])]);
  Data:=TJSONObject.Create(['a',TJSONObject.Create(['c',A])]);
  FContext.AssertTrue((D)=(Data.FindPath('a.c[2].b')), 'a.c[2].b returns correct data ');
  FContext.AssertTrue((D)=(Data.FindPath('a.c[2]b')), 'a.c[2]b returns correct data ');
  FContext.AssertTrue((Data.FindPath('a.c[2]d'))=nil, 'a.c[2]d returns nil ');
end;

{ TTestJSON }

Const
  DefJSONInstanceTypes :
    Array [TJSONInstanceType] of TJSONDataClass = (TJSONData, TJSONIntegerNumber,
    TJSONInt64Number,TJSONQWordNumber,TJSONFloatNumber, TJSONString, TJSONBoolean,
    TJSONNull, TJSONArray, TJSONObject);

Const
  MyJSONInstanceTypes :
    Array [TJSONInstanceType] of TJSONDataClass = (TJSONData, TMyInteger,
    TMyInt64, TMyQWord,TMyFloat, TMyString, TMyBoolean, TMyNull, TMyArray,
    TMyObject);

procedure TTestJSON.SetDefaultInstanceTypes;

Var
  Ti : TJSONInstanceType;

begin
  For ti:=Low(TJSONInstanceType) to High(TJSONInstanceType) do
   SetJSONInstanceType(Ti,DefJSONInstanceTypes[ti]);
end;

procedure TTestJSON.SetMyInstanceTypes;

Var
  Ti : TJSONInstanceType;

begin
  For ti:=Low(TJSONInstanceType) to High(TJSONInstanceType) do
    FContext.AssertTrue((DefJSONInstanceTypes[ti])=(SetJSONInstanceType(Ti,MyJSONInstanceTypes[ti])), 'Previous value is returned by SetJSONInstanceType');
end;

Procedure TTestJSON.SetUp;


begin
  
  SetDefaultInstanceTypes;
  TJSONData.CompressedJSON:=False;
  TJSONObject.UnquotedMemberNames:=False;
end;

Procedure TTestJSON.TestItemCount(J: TJSONData; Expected: Integer);
begin
  FContext.AssertTrue((Expected)=(J.Count), J.ClassName+'.ItemCount');
end;

Procedure TTestJSON.TestJSONType(J: TJSONData; Expected: TJSONType);
begin
  FContext.AssertTrue((Ord(Expected))=(Ord(J.JSONType)), J.ClassName+'.JSONType');
end;

Procedure TTestJSON.TestJSON(J: TJSONData; Expected: TJSONStringType);
begin
  FContext.AssertTrue((Expected)=(J.AsJSON), J.ClassName+'.AsJSON');
end;

Procedure TTestJSON.TestIsNull(J: TJSONData; Expected: Boolean);
begin
  FContext.AssertTrue((Expected)=(J.IsNull), J.ClassName+'.IsNull');
end;

Procedure TTestJSON.TestAsBoolean(J: TJSONData; Expected: Boolean;
  ExpectError: boolean);

Var
  B : Boolean;
  AssignOK : Boolean;
  Msg : String;

begin
  AssignOK:=False;
  Try
    B:=J.AsBoolean;
    AssignOK:=True;
    If Not ExpectError then
      FContext.AssertTrue((Expected)=(B), J.Classname+'.AsBoolean');
  except
    On E : Exception do
      begin
      AssignOK:=False;
      Msg:=E.Message;
      end;
  end;
  If ExpectError then
    begin
    If AssignOK then
      FContext.Fail(J.ClassName+'.AsBoolean must raise error');
    end
  else
    begin
    If not AssignOK then
      FContext.Fail(J.ClassName+'.AsBoolean raised unexpected exception: '+Msg)
    end;
end;

Procedure TTestJSON.TestAsInteger(J: TJSONData; Expected: Integer;
  ExpectError: boolean);

Var
  I : Integer;
  AssignOK : Boolean;
  Msg : String;

begin
  AssignOK:=False;
  Try
    I:=J.AsInteger;
    AssignOK:=True;
    If Not ExpectError then
      FContext.AssertTrue((Expected)=(I), J.Classname+'.AsInteger');
  except
    On E : Exception do
      begin
      AssignOK:=False;
      Msg:=E.Message;
      end;
  end;
  If ExpectError then
    begin
    If AssignOK then
      FContext.Fail(J.ClassName+'.AsInteger must raise error');
    end
  else
    begin
    If not AssignOK then
      FContext.Fail(J.ClassName+'.AsInteger raised unexpected exception: '+Msg)
    end;
end;

Procedure TTestJSON.TestAsInt64(J: TJSONData; Expected: Int64;
  ExpectError: boolean);

Var
  I : Int64;
  AssignOK : Boolean;
  Msg : String;

begin
  AssignOK:=False;
  Try
    I:=J.AsInt64;
    AssignOK:=True;
    If Not ExpectError then
      FContext.AssertTrue((Expected)=(I), J.Classname+'.AsInt64');
  except
    On E : Exception do
      begin
      AssignOK:=False;
      Msg:=E.Message;
      end;
  end;
  If ExpectError then
    begin
    If AssignOK then
      FContext.Fail(J.ClassName+'.AsInt64 must raise error');
    end
  else
    begin
    If not AssignOK then
      FContext.Fail(J.ClassName+'.AsInt64 raised unexpected exception: '+Msg)
    end;
end;

Procedure TTestJSON.TestAsQWord(J: TJSONData; Expected: QWord;
  ExpectError: boolean);
Var
  Q : QWord;
  AssignOK : Boolean;
  Msg : String;

begin
  AssignOK:=False;
  Try
    Q:=J.AsQWord;
    AssignOK:=True;
    If Not ExpectError then
      FContext.AssertTrue((IntToStr(Expected))=(IntToStr(Q)), J.Classname+'.AsQWord');
  except
    On E : Exception do
      begin
      AssignOK:=False;
      Msg:=E.Message;
      end;
  end;
  If ExpectError then
    begin
    If AssignOK then
      FContext.Fail(J.ClassName+'.AsQWord must raise error');
    end
  else
    begin
    If not AssignOK then
      FContext.Fail(J.ClassName+'.AsInt64 raised unexpected exception: '+Msg)
    end;
end;

Procedure TTestJSON.TestAsString(J: TJSONData; Expected: String;
  ExpectError: boolean);

Var
  S : String;
  AssignOK : Boolean;
  Msg : String;

begin
  AssignOK:=False;
  Try
    S:=J.AsString;
    AssignOK:=True;
    If Not ExpectError then
      FContext.AssertTrue((Expected)=(S), J.Classname+'.AsString');
  except
    On E : Exception do
      begin
      AssignOK:=False;
      Msg:=E.Message;
      end;
  end;
  If ExpectError then
    begin
    If AssignOK then
      FContext.Fail(J.ClassName+'.AsString must raise error');
    end
  else
    begin
    If not AssignOK then
      FContext.Fail(J.ClassName+'.AsString raised unexpected exception: '+Msg)
    end;
end;

Procedure TTestJSON.TestAsFloat(J: TJSONData; Expected: TJSONFloat;
  ExpectError: boolean);

Var
  F : TJSONFloat;
  AssignOK : Boolean;
  Msg : String;

begin
  AssignOK:=False;
  Try
    F:=J.AsFloat;
    AssignOK:=True;
    If Not ExpectError then
      FContext.AssertTrue((Expected)=(F), J.Classname+'.AsFloat');
  except
    On E : Exception do
      begin
      AssignOK:=False;
      Msg:=E.Message;
      end;
  end;
  If ExpectError then
    begin
    If AssignOK then
      FContext.Fail(J.ClassName+'.AsFloat must raise error');
    end
  else
    begin
    If not AssignOK then
      FContext.Fail(J.ClassName+'.AsFloat raised unexpected exception: '+Msg)
    end;
end;

{ TTestBoolean }

procedure TTestBoolean.TestTrue;

Var
  J : TJSONBoolean;

begin
  J:=TJSONBoolean.Create(True);
  try
    TestJSONType(J,jtBoolean);
    TestItemCount(J,0);
    TestJSON(J,'true');
    TestIsNull(J,False);
    TestAsBoolean(J,True);
    TestAsInteger(J,1);
    TestAsInt64(J,1);
    TestAsQword(J,1);
    TestAsString(J,BoolToStr(True,'true','false'));
    TestAsFloat(J,1.0);
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestBoolean.TestFalse;

Var
  J : TJSONBoolean;

begin
  J:=TJSONBoolean.Create(False);
  try
    TestJSONType(J,jtBoolean);
    TestItemCount(J,0);
    TestJSON(J,'false');
    TestIsNull(J,False);
    TestAsBoolean(J,False);
    TestAsInteger(J,0);
    TestAsInt64(J,0);
    TestAsQWord(J,0);
    TestAsString(J,BoolToStr(False,'true','false'));
    TestAsFloat(J,0.0);
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestBoolean.TestClone;

Var
  B : TJSONBoolean;
  D : TJSONData;

begin
  B:=TJSONBoolean.Create(true);
  try
    D:=B.Clone;
    try
     TestJSONType(D,jtBoolean);
     TestAsBoolean(D,true);
    finally
      D.Free;
    end;
  finally
    FreeAndNil(B);
  end;
end;

procedure TTestBoolean.TestMyClone;
Var
  B : TMyBoolean;
  D : TJSONData;

begin
  B:=TMyBoolean.Create(true);
  try
    D:=B.Clone;
    try
     TestJSONType(D,jtBoolean);
     FContext.AssertTrue((TMyBoolean)=(D.ClassType), 'Correct class');
     TestAsBoolean(D,true);
    finally
      D.Free;
    end;
  finally
    FreeAndNil(B);
  end;
end;

procedure TTestBoolean.TestFormat;

Var
  B : TJSONBoolean;

begin
  B:=TJSONBoolean.Create(true);
  try
    FContext.AssertTrue((B.asJSON)=(B.FormatJSON), 'FormatJSON same as asJSON');
  finally
    B.Free;
  end;
end;



{ TTestNull }

procedure TTestNull.TestNull;

Var
  J : TJSONNull;

begin
  J:=TJSONNull.Create;
  try
    TestJSONType(J,jtNull);
    TestItemCount(J,0);
    TestJSON(J,'null');
    TestIsNull(J,True);
    TestAsBoolean(J,False,True);
    TestAsInteger(J,0,true);
    TestAsInt64(J,0,true);
    TestAsQWord(J,0,true);
    TestAsString(J,BoolToStr(False),true);
    TestAsFloat(J,0.0,true);
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestNull.TestClone;

Var
  J : TJSONNull;
  D : TJSONData;

begin
  J:=TJSONNull.Create;
  try
    D:=J.Clone;
    try
      TestIsNull(D,True);
    finally
      D.Free;
    end;
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestNull.TestMyClone;
Var
  J : TMyNull;
  D : TJSONData;

begin
  J:=TMyNull.Create;
  try
    D:=J.Clone;
    try
      TestIsNull(D,True);
      FContext.AssertTrue((TMyNull)=(D.ClassType), 'Correct class');
    finally
      D.Free;
    end;
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestNull.TestFormat;
Var
  J : TJSONNull;
begin
  J:=TJSONNull.Create;
  try
    FContext.AssertTrue((J.asJSON)=(J.FormatJSON), 'FormatJSON same as asJSON');
  finally
    J.Free;
  end;
end;


{ TTestString }

procedure TTestString.TestString;

Const
  S = 'A string';

Var
  J : TJSONString;

begin
  J:=TJSONString.Create(S);
  try
    TestJSONType(J,jtString);
    TestItemCount(J,0);
    TestJSON(J,'"'+S+'"');
    TestIsNull(J,False);
    TestAsBoolean(J,False,True);
    TestAsInteger(J,0,true);
    TestAsInt64(J,0,true);
    TestAsQWord(J,0,true);
    TestAsString(J,S);
    TestAsFloat(J,0.0,true);
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestString.TestControlString;
Var
  J : TJSONString;
  I : Integer;
  T : String;

begin
  J:=TJSONString.Create('');
  try
    For I:=0 to 31 do
      begin
      J.AsString:='-->'+AnsiChar(I)+'<--';
      Case I of
       8  : T:='\b';
       9  : T:='\t';
       10 : T:='\n';
       12 : T:='\f';
       13 : T:='\r';
      else
        T:='\u'+HexStr(I,4);
      end;
      FContext.AssertTrue(('"-->'+T+'<--"')=(J.AsJSON), 'Control AnsiChar');
      end;
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestString.TestSolidus;
Var
  J : TJSONString;

begin
  J:=TJSONString.Create('');
  try
    J.AsString:='http://www.json.org/';
    TJSONString.StrictEscaping:=True;
    TestJSON(J,'"http:\/\/www.json.org\/"');
    TJSONString.StrictEscaping:=False;
    TestJSON(J,'"http://www.json.org/"');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestString.TestInteger;

Const
  S = '1';

Var
  J : TJSONString;

begin
  J:=TJSONString.Create(S);
  try
    TestJSONType(J,jtString);
    TestItemCount(J,0);
    TestJSON(J,'"'+S+'"');
    TestIsNull(J,False);
    TestAsBoolean(J,True,False);
    TestAsInteger(J,1,False);
    TestAsInt64(J,1,False);
    TestAsQWord(J,1,False);
    TestAsString(J,S);
    TestAsFloat(J,1.0,False);
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestString.TestNegativeInteger;

Const
  S = '-1';

Var
  J : TJSONString;

begin
  J:=TJSONString.Create(S);
  try
    TestJSONType(J,jtString);
    TestItemCount(J,0);
    TestJSON(J,'"'+S+'"');
    TestIsNull(J,False);
    TestAsBoolean(J,True,False);
    TestAsInteger(J,-1,False);
    TestAsInt64(J,-1,False);
    TestAsQWord(J,QWord(-1),True);
    TestAsString(J,S);
    TestAsFloat(J,-1.0,False);
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestString.TestFloat;

begin
  DoTestFloat(1.0,'1.0',True);
  DoTestFloat(1.0,'1',True);
  DoTestFloat(1.0,'1e0',True);
  DoTestFloat(1.2,'1.2',True);
  DoTestFloat(12.0,'1.2e1',True);
end;

procedure TTestString.TestNegativeFloat;
begin
  DoTestFloat(-1.0,'-1.0',True);
  DoTestFloat(-1.0,'-1',True);
  DoTestFloat(-1.0,'-1e0',True);
  DoTestFloat(-1.2,'-1.2',True);
  DoTestFloat(-12.0,'-1.2e1',True);
end;

procedure TTestString.TestBooleanTrue;

Const
  S = 'true';

Var
  J : TJSONString;

begin
  J:=TJSONString.Create(S);
  try
    TestJSONType(J,jtString);
    TestItemCount(J,0);
    TestJSON(J,'"'+S+'"');
    TestIsNull(J,False);
    TestAsBoolean(J,True,False);
    TestAsInteger(J,-1,True);
    TestAsInt64(J,-1,True);
    TestAsQWord(J,QWord(-1),True);
    TestAsString(J,S);
    TestAsFloat(J,-1.0,True);
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestString.TestBooleanFalse;

Const
  S = 'false';

Var
  J : TJSONString;

begin
  J:=TJSONString.Create(S);
  try
    TestJSONType(J,jtString);
    TestItemCount(J,0);
    TestJSON(J,'"'+S+'"');
    TestIsNull(J,False);
    TestAsBoolean(J,False,False);
    TestAsInteger(J,0,True);
    TestAsInt64(J,0,True);
    TestAsQWord(J,0,True);
    TestAsString(J,S);
    TestAsFloat(J,0,True);
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestString.TestClone;

Var
  S : TJSONString;
  D : TJSONData;

begin
  S:=TJSONString.Create('aloha');
  try
    D:=S.Clone;
    try
     TestJSONType(D,jtString);
     TestAsString(D,'aloha');
    finally
      D.Free;
    end;
  finally
    FreeAndNil(S);
  end;
end;

procedure TTestString.TestMyClone;
Var
  S : TMyString;
  D : TJSONData;

begin
  S:=TMyString.Create('aloha');
  try
    D:=S.Clone;
    try
      FContext.AssertTrue((TMyString)=(D.ClassType), 'Correct class');
     TestJSONType(D,jtString);
     TestAsString(D,'aloha');
    finally
      D.Free;
    end;
  finally
    FreeAndNil(S);
  end;
end;

procedure TTestString.TestFormat;
Var
  S : TJSONString;

begin
  S:=TJSONString.Create('aloha');
  try
    FContext.AssertTrue((S.AsJSON)=(S.FormatJSOn), 'FormatJSON equals JSON');
  finally
    FreeAndNil(S);
  end;
end;

procedure TTestString.DoTestFloat(F : TJSOnFloat;S : String; OK : Boolean);

Var
  J : TJSONString;

begin
  J:=TJSONString.Create(S);
  try
    TestJSONType(J,jtString);
    TestItemCount(J,0);
    TestJSON(J,'"'+S+'"');
    TestIsNull(J,False);
    TestAsBoolean(J,(F<>0),Not OK);
    TestAsInteger(J,Round(F),(Pos('.',S)<>0) or (Pos('E',UpperCase(S))<>0));
    TestAsInt64(J,Round(F),(Pos('.',S)<>0) or (Pos('E',UpperCase(S))<>0));
    if F>0 then
      TestAsQword(J,Round(F),(Pos('.',S)<>0) or (Pos('E',UpperCase(S))<>0));
    TestAsString(J,S);
    TestAsFloat(J,F,Not OK);
  finally
    FreeAndNil(J);
  end;
end;


{ TTestInteger }

procedure TTestInteger.DoTest(I: Integer);

Var
  J : TJSONIntegerNumber;

begin
  J:=TJSONIntegerNumber.Create(I);
  try
    TestJSONType(J,jtNumber);
    TestItemCount(J,0);
    FContext.AssertTrue((ord(ntInteger))=(Ord(J.NumberType)), 'Numbertype is ntInteger');
    TestJSON(J,IntToStr(i));
    TestIsNull(J,False);
    TestAsBoolean(J,(I<>0));
    TestAsInteger(J,I);
    TestAsInt64(J,I);
{$push}
{$R-}
{$Q-}
    TestAsQword(J,I);
{$pop}
    TestAsString(J,IntToStr(I));
    TestAsFloat(J,I);
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestInteger.TestPositive;

begin
  DoTest(1);
end;

procedure TTestInteger.TestNegative;
begin
  DoTest(-1);
end;

procedure TTestInteger.TestZero;
begin
  DoTest(0);
end;

procedure TTestInteger.TestClone;

Var
  I : TJSONIntegerNumber;
  D : TJSONData;

begin
  I:=TJSONIntegerNumber.Create(99);
  try
    D:=I.Clone;
    try
     TestJSONType(D,jtNumber);
     TestAsInteger(D,99);
    finally
      D.Free;
    end;
  finally
    FreeAndNil(I);
  end;

end;

procedure TTestInteger.TestMyClone;
Var
  I : TMyInteger;
  D : TJSONData;

begin
  I:=TMyInteger.Create(99);
  try
    D:=I.Clone;
    try
     FContext.AssertTrue((TMyInteger)=(D.ClassType), 'Correct class');
     TestJSONType(D,jtNumber);
     TestAsInteger(D,99);
    finally
      D.Free;
    end;
  finally
    FreeAndNil(I);
  end;
end;

procedure TTestInteger.TestFormat;

Var
  I : TJSONIntegerNumber;

begin
  I:=TJSONIntegerNumber.Create(99);
  try
    FContext.AssertTrue((I.AsJSON)=(I.FormatJSON), 'FormatJSON equal to JSON');
  finally
    FreeAndNil(I);
  end;
end;

{ TTestInt64 }

procedure TTestInt64.DoTest(I: Int64);

Var
  J : TJSONInt64Number;

begin
  J:=TJSONInt64Number.Create(I);
  try
    TestJSONType(J,jtNumber);
    TestItemCount(J,0);
    FContext.AssertTrue((ord(ntInt64))=(Ord(J.NumberType)), 'Numbertype is ntInt64');
    TestJSON(J,IntToStr(i));
    TestIsNull(J,False);
    TestAsBoolean(J,(I<>0));
    TestAsInteger(J,I);
    TestAsInt64(J,I);
{$push}
{$R-}
{$Q-}
    TestAsQword(J,I);
{$pop}
    TestAsString(J,IntToStr(I));
    TestAsFloat(J,I);
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestInt64.TestPositive;

begin
  DoTest(1);
end;

procedure TTestInt64.TestNegative;
begin
  DoTest(-1);
end;

procedure TTestInt64.TestZero;
begin
  DoTest(0);
end;

procedure TTestInt64.TestClone;

Var
  I : TJSONInt64Number;
  D : TJSONData;

begin
  I:=TJSONInt64Number.Create(99);
  try
    D:=I.Clone;
    try
     TestJSONType(D,jtNumber);
     FContext.AssertTrue((ord(ntInt64))=(Ord(TJSONInt64Number(D).NumberType)), 'Numbertype is ntInt64');
     TestAsInteger(D,99);
    finally
      D.Free;
    end;
  finally
    FreeAndNil(I);
  end;

end;

procedure TTestInt64.TestMyClone;
Var
  I : TMyInt64;
  D : TJSONData;

begin
  I:=TMyInt64.Create(99);
  try
    D:=I.Clone;
    try
      FContext.AssertTrue((TMyInt64)=(D.ClassType), 'Correct class');
     TestJSONType(D,jtNumber);
     FContext.AssertTrue((ord(ntInt64))=(Ord(TMyInt64(D).NumberType)), 'Numbertype is ntInt64');
     TestAsInteger(D,99);
    finally
      D.Free;
    end;
  finally
    FreeAndNil(I);
  end;
end;

procedure TTestInt64.TestFormat;
Var
  I : TJSONInt64Number;

begin
  I:=TJSONInt64Number.Create(99);
  try
    FContext.AssertTrue((I.AsJSON)=(I.FormatJSON), 'FormatJSON equal to JSON');
  finally
    FreeAndNil(I);
  end;
end;

{ TTestQWord }

procedure TTestQWord.DoTest(Q: QWord);

Var
  J : TJSONQWordNumber;

begin
  J:=TJSONQWordNumber.Create(Q);
  try
    TestJSONType(J,jtNumber);
    TestItemCount(J,0);
    FContext.AssertTrue((ord(ntQWord))=(Ord(J.NumberType)), 'Numbertype is ntQWord');
    TestJSON(J,IntToStr(Q));
    TestIsNull(J,False);
    TestAsBoolean(J,(Q<>0));
    TestAsInteger(J,Q);
    TestAsInt64(J,Q);
    TestAsQword(J,Q);
    TestAsString(J,IntToStr(Q));
    TestAsFloat(J,Q);
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestQWord.TestPositive;

begin
  DoTest(1);
end;


procedure TTestQWord.TestZero;
begin
  DoTest(0);
end;

procedure TTestQWord.TestClone;

Var
  I : TJSONQWordNumber;
  D : TJSONData;

begin
  I:=TJSONQWordNumber.Create(99);
  try
    D:=I.Clone;
    try
     TestJSONType(D,jtNumber);
     FContext.AssertTrue((ord(ntQWord))=(Ord(TJSONQWordNumber(D).NumberType)), 'Numbertype is ntQWord');
     TestAsInteger(D,99);
    finally
      D.Free;
    end;
  finally
    FreeAndNil(I);
  end;

end;

procedure TTestQWord.TestMyClone;
Var
  I : TMyQWord;
  D : TJSONData;

begin
  I:=TMyQWord.Create(99);
  try
    D:=I.Clone;
    try
      FContext.AssertTrue((TMyQWord)=(D.ClassType), 'Correct class');
     TestJSONType(D,jtNumber);
     FContext.AssertTrue((ord(ntQWord))=(Ord(TMyQWord(D).NumberType)), 'Numbertype is ntQWord');
     TestAsInteger(D,99);
    finally
      D.Free;
    end;
  finally
    FreeAndNil(I);
  end;
end;

procedure TTestQWord.TestFormat;
Var
  I : TJSONQWordNumber;

begin
  I:=TJSONQWordNumber.Create(99);
  try
    FContext.AssertTrue((I.AsJSON)=(I.FormatJSON), 'FormatJSON equal to JSON');
  finally
    FreeAndNil(I);
  end;
end;

{ TTestFloat }

procedure TTestFloat.DoTest(F: TJSONFloat);

Var
  J : TJSONFloatNumber;
  S : String;

begin
  Str(F,S);
  If S[1]=' ' then
    Delete(S,1,1);
  J:=TJSONFloatNumber.Create(F);
  try
    TestJSONType(J,jtNumber);
    TestItemCount(J,0);
    FContext.AssertTrue((ord(ntFloat))=(Ord(J.NumberType)), 'Numbertype is ntFloat');
    TestJSON(J,S);
    TestIsNull(J,False);
    TestAsBoolean(J,(F<>0));
{$push}
{$R-}
{$Q-}
    TestAsInteger(J,Round(F));
    TestAsInt64(J,Round(F));
    TestAsQword(J,Round(F));
{$pop}
    TestAsString(J,S);
    TestAsFloat(J,F);
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestFloat.TestPositive;
begin
  DoTest(1.0);
  DoTest(1.2);
  DoTest(1.2e1);
  DoTest(1.2e-1);
  DoTest(1.2e10);
  DoTest(1.2e-10);
end;

procedure TTestFloat.TestNegative;
begin
  DoTest(-1.0);
  DoTest(-1.2);
  DoTest(-1.2e1);
  DoTest(-1.2e-1);
  DoTest(-1.2e10);
  DoTest(-1.2e-10);
end;

procedure TTestFloat.TestZero;
begin
  DoTest(0.0);
end;

procedure TTestFloat.TestClone;

Var
  F : TJSONFloatNumber;
  D : TJSONData;

begin
  F:=TJSONFloatNumber.Create(1.23);
  try
    D:=F.Clone;
    try
     TestJSONType(D,jtNumber);
     FContext.AssertTrue((ord(ntFloat))=(Ord(TJSONFloatNumber(D).NumberType)), 'Numbertype is ntFloat');
     TestAsFloat(D,1.23);
    finally
      D.Free;
    end;
  finally
    FreeAndNil(F);
  end;

end;

procedure TTestFloat.TestMyClone;

Var
  F : TMyFloat;
  D : TJSONData;

begin
  F:=TMyFloat.Create(1.23);
  try
    D:=F.Clone;
    try
     FContext.AssertTrue((TMyFloat)=(D.ClassType), 'Correct class');
     TestJSONType(D,jtNumber);
     FContext.AssertTrue((ord(ntFloat))=(Ord(TMyFloat(D).NumberType)), 'Numbertype is ntFloat');
     TestAsFloat(D,1.23);
    finally
      D.Free;
    end;
  finally
    FreeAndNil(F);
  end;
end;

procedure TTestFloat.TestFormat;

Var
  F : TJSONFloatNumber;


begin
  F:=TJSONFloatNumber.Create(1.23);
  try
    FContext.AssertTrue((F.AsJSON)=(F.FormatJSON), 'FormatJSON equals asJSON');
    FContext.AssertTrue(('1.23')=(F.FormatJSON([foFormatFloat])), 'Formatjson with float formatting');
  finally
    FreeAndNil(F);
  end;
end;

{ TTestArray }

procedure TTestArray.TestCreate;

Var
  J : TJSONArray;

begin
  J:=TJSonArray.Create;
  try
    TestJSONType(J,jtArray);
    TestItemCount(J,0);
    TestJSON(J,'[]');
    TestIsNull(J,False);
    TestAsBoolean(J,False,True);
    TestAsInteger(J,1,True);
    TestAsInt64(J,1,True);
    TestAsQWord(J,1,True);
    TestAsString(J,'',True);
    TestAsFloat(J,0.0,True);
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestCreateString;

Const
  S = 'A string';

Var
  J : TJSONArray;

begin
  J:=TJSonArray.Create([S]);
  try
    TestJSONType(J,jtArray);
    TestItemCount(J,1);
    TestJSONType(J[0],jtString);
    TestJSON(J,'["'+S+'"]');
    TestIsNull(J,False);
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestCreatePchar;

Const
  S = 'A string';

Var
  J : TJSONArray;

begin
  J:=TJSonArray.Create([PAnsiChar(S)]);
  try
    TestJSONType(J,jtArray);
    TestItemCount(J,1);
    TestJSONType(J[0],jtString);
    TestJSON(J,'["'+S+'"]');
    TestIsNull(J,False);
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestCreateStrings;

Const
  S = 'A string';
  T = 'B string';

Var
  J : TJSONArray;

begin
  J:=TJSONArray.Create([S,T]);
  try
    TestJSONType(J,jtArray);
    TestItemCount(J,2);
    TestJSONType(J[0],jtString);
    TestJSONType(J[1],jtString);
    TestJSON(J,'["'+S+'", "'+T+'"]');
    TestIsNull(J,False);
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestCreateStringsCompressed;
Const
  S = 'A string';
  T = 'B string';

Var
  J : TJSONArray;

begin
  TJSONData.CompressedJSON:=True;
  J:=TJSONArray.Create([S,T]);
  try
    TestJSONType(J,jtArray);
    TestItemCount(J,2);
    TestJSONType(J[0],jtString);
    TestJSONType(J[1],jtString);
    TestJSON(J,'["'+S+'","'+T+'"]');
    TestIsNull(J,False);
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestCreateInteger;

Const
  S = 3;

Var
  J : TJSONArray;

begin
  J:=TJSonArray.Create([S]);
  try
    TestJSONType(J,jtArray);
    TestItemCount(J,1);
    TestJSONType(J[0],jtNumber);
    TestJSON(J,'[3]');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestCreateFloat;

Const
  S : double = 1.2;

Var
  J : TJSONArray;
  r : String;

begin
  J:=TJSonArray.Create([S]);
  try
    TestJSONType(J,jtArray);
    TestItemCount(J,1);
    TestJSONType(J[0],jtNumber);
    Str(S,R);
    Delete(R,1,1);
    TestJSON(J,'['+R+']');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestCreateInt64;

Const
  S : Int64 = $FFFFFFFFFFFFF;

Var
  J : TJSONArray;

begin
  J:=TJSonArray.Create([S]);
  try
    TestJSONType(J,jtArray);
    TestItemCount(J,1);
    TestJSONType(J[0],jtNumber);
    TestJSON(J,'['+IntToStr(S)+']');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestCreateBoolean;

Const
  S = True;

Var
  J : TJSONArray;

begin
  J:=TJSonArray.Create([S]);
  try
    TestJSONType(J,jtArray);
    TestItemCount(J,1);
    TestJSONType(J[0],jtBoolean);
    TestJSON(J,'[true]');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestCreateJSONObject;

Var
  J : TJSONArray;

begin
  J:=TJSonArray.Create([TJSONObject.Create]);
  try
    TestItemCount(J,1);
    TestJSONType(J[0],jtObject);
    TestJSON(J,'[{}]');
  finally
    FreeAndNil(J);
  end;
end;
procedure TTestArray.TestCreateJSONString;

Const
  S = 'A string';

Var
  J : TJSONArray;

begin
  J:=TJSonArray.Create([TJSONString.Create(S)]);
  try
    TestItemCount(J,1);
    TestJSONType(J[0],jtString);
    TestJSON(J,'["'+S+'"]');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestCreateJSONStringSpecialChars;
const
  S: array[0..7] of string = (
    'A'#1,
    'B'#9,
    'C'#10,
    'D'#12,
    'E'#13,
    'F'#10#13,
    'G"Foo"',
    'H\J');
Var
  J : TJSONArray;
  i: Integer;

begin
  J:=TJSonArray.Create;
  try
    for i:=0 to high(S) do
      J.Add(S[i]);
    TestItemCount(J,length(S));
    for i:=0 to high(S) do
      begin
      TestJSONType(J[i],jtString);
      end;
    TestJSON(J,'["A\u0001", "B\t", "C\n", "D\f", "E\r", "F\n\r", "G\"Foo\"", "H\\J"]');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestCreateObject;

Var
  J : TJSONArray;
  O : TObject;

begin
  J:=Nil;
  try
    Try
      O:=TObject.Create;
      J:=TJSONArray.Create([O]);
      FContext.Fail('Array constructor accepts only TJSONData');
    finally
      FreeAndNil(J);
      FreeAndNil(O);
    end;
  except
    // Should be OK.
  end;
end;

procedure TTestArray.TestCreateNilPointer;

Var
  J : TJSONArray;
  P : Pointer;

begin
  J:=Nil;
  P:=Nil;
  Try
    J:=TJSONArray.Create([P]);
    TestJSONType(J[0],jtNull);
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestCreatePointer;

Var
  J : TJSONArray;
  P : Pointer;

begin
  J:=Nil;
  P:=@Self;
  try
    Try
      J:=TJSONArray.Create([P]);
      FContext.Fail('Array constructor accepts only NIL pointers');
    finally
      FreeAndNil(J);
    end;
  except
    // Should be OK.
  end;
end;

procedure TTestArray.TestAddInteger;

Var
  J : TJSONArray;

begin
  J:=TJSonArray.Create;
  try
    J.Add(Integer(0));
    TestItemCount(J,1);
    TestJSONType(J[0],jtNumber);
    FContext.AssertTrue((J[0].ClassType)=(TJSONIntegerNumber), 'J[0] is TJSONIntegerNumber');
    FContext.AssertTrue((ord(J.Types[0]))=(Ord(jtNumber)), 'j.Types[0]=jtNumber');
    FContext.AssertTrue((0)=(J.integers[0]), 'J.Integers[0]=0');
    TestAsInteger(J[0],0);
    TestAsInt64(J[0],0);
    TestAsQword(J[0],0);
    TestJSON(J,'[0]');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestAddInt64;

Var
  J : TJSONArray;

begin
  J:=TJSonArray.Create;
  try
    J.Add(Int64(0));
    TestItemCount(J,1);
    TestJSONType(J[0],jtNumber);
    FContext.AssertTrue((J[0].ClassType)=(TJSONInt64Number), 'J[0] is TJSONInt64Number');
    FContext.AssertTrue((ord(J.Types[0]))=(Ord(jtNumber)), 'j.Types[0]=jtNumber');
    FContext.AssertTrue((0)=(J.Int64s[0]), 'J.Int64s[0]=0');
    TestAsInteger(J[0],0);
    TestAsInt64(J[0],0);
    TestAsQword(J[0],0);
    TestJSON(J,'[0]');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestAddFloat;

Var
  J : TJSONArray;
  S : String;
  F : TJSONFloat;
begin
  F:=1.2;
  J:=TJSonArray.Create;
  try
    J.Add(F);
    TestItemCount(J,1);
    TestJSONType(J[0],jtNumber);
    FContext.AssertTrue((TJSONfloatNumber)=(J[0].ClassType), 'J[0] is TJSONFloatNumber');
    FContext.AssertTrue((Ord(jtNumber))=(ord(J.Types[0])), 'j.Types[0]=jtNumber');
    FContext.AssertTrue((F)=(J.Floats[0]), 'J.Floats[0]='+FloatToStr(F));
    TestAsFloat(J[0],F);
    Str(F,S);
    Delete(S,1,1);
    TestJSON(J,'['+S+']');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestAddBoolean(B : Boolean);

Var
  J : TJSONArray;

begin
  B:=True;
  J:=TJSonArray.Create;
  try
    J.Add(B);
    TestItemCount(J,1);
    TestJSONType(J[0],jtBoolean);
    FContext.AssertTrue((TJSONBoolean)=(J[0].ClassType), 'J[0] is TJSONBoolean');
    TestAsBoolean(J[0],B);
    FContext.AssertTrue((B)=(J.Booleans[0]), 'J.Booleans[0]='+BoolToStr(B)+'"');
    If B then
      TestJSON(J,'[true]')
    else
      TestJSON(J,'[false]');
  finally
    FreeAndNil(J);
  end;

end;

procedure TTestArray.TestInsertBoolean(B: Boolean);
Var
  J : TJSONArray;

begin
  B:=True;
  J:=TJSonArray.Create;
  try
    J.Add(Not B);
    J.Insert(0,B);
    TestItemCount(J,2);
    TestJSONType(J[0],jtBoolean);
    FContext.AssertTrue((TJSONBoolean)=(J[0].ClassType), 'J[0] is TJSONBoolean');
    TestAsBoolean(J[0],B);
    FContext.AssertTrue((B)=(J.Booleans[0]), 'J.Booleans[0]='+BoolToStr(B)+'"');
    If B then
      TestJSON(J,'[true, false]')
    else
      TestJSON(J,'[false, true]');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestAddBooleanTrue;

begin
  TestAddBoolean(True);
end;

procedure TTestArray.TestAddBooleanFalse;

begin
  TestAddBoolean(False);
end;

procedure TTestArray.TestAddString;

Var
  J : TJSONArray;
  S : String;

begin
  S:='A string';
  J:=TJSonArray.Create;
  try
    J.Add(S);
    TestItemCount(J,1);
    TestJSONType(J[0],jtString);
    FContext.AssertTrue((TJSONString)=(J[0].ClassType), 'J[0] is TJSONString');
    TestAsString(J[0],S);
    FContext.AssertTrue((S)=(J.Strings[0]), 'J.Strings[0]="'+S+'"');
    TestJSON(J,'["'+StringToJSONString(S)+'"]');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestAddNull;

Var
  J : TJSONArray;

begin
  J:=TJSonArray.Create;
  try
    J.Add;
    TestItemCount(J,1);
    TestJSONType(J[0],jtNull);
    FContext.AssertTrue((TJSONNull)=(J[0].ClassType), 'J[0] is TJSONNull');
    FContext.AssertTrue((True)=(J.Nulls[0]), 'J.Nulls[0]=True');
    TestIsNull(J[0],true);
    TestJSON(J,'[null]');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestAddArray;

Var
  J,J2 : TJSONArray;

begin
  J:=TJSonArray.Create;
  try
    J2:=TJSonArray.Create;
    J2.Add(0);
    J2.Add(1);
    J.Add(J2);
    TestItemCount(J,1);
    TestJSONType(J[0],jtArray);
    FContext.AssertTrue((TJSONArray)=(J[0].ClassType), 'J[0] is TJSONArray');
    FContext.AssertTrue((TJSONArray)=(J.Arrays[0].ClassType), 'J.Arrays[0] is TJSONArray');
    TestAsInteger(J.Arrays[0][0],0);
    TestAsInteger(J.Arrays[0][1],1);
    TestAsInt64(J.Arrays[0][0],0);
    TestAsInt64(J.Arrays[0][1],1);
    TestAsQword(J.Arrays[0][0],0);
    TestAsQword(J.Arrays[0][1],1);
    TestJSON(J,'[[0, 1]]');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestInsertInteger;
Var
  J : TJSONArray;

begin
  J:=TJSonArray.Create;
  try
    J.Add(Integer(1));
    J.Insert(0,Integer(0));
    TestItemCount(J,2);
    TestJSONType(J[0],jtNumber);
    FContext.AssertTrue((J[0].ClassType)=(TJSONIntegerNumber), 'J[0] is TJSONIntegerNumber');
    FContext.AssertTrue((ord(J.Types[0]))=(Ord(jtNumber)), 'j.Types[0]=jtNumber');
    FContext.AssertTrue((0)=(J.integers[0]), 'J.Integers[0]=0');
    TestAsInteger(J[0],0);
    TestAsInt64(J[0],0);
    TestAsQword(J[0],0);
    TestJSON(J,'[0, 1]');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestInsertInt64;
Var
  J : TJSONArray;

begin
  J:=TJSonArray.Create;
  try
    J.Add(Int64(1));
    J.Insert(0,Int64(0));
    TestItemCount(J,2);
    TestJSONType(J[0],jtNumber);
    FContext.AssertTrue((J[0].ClassType)=(TJSONInt64Number), 'J[0] is TJSONInt64Number');
    FContext.AssertTrue((ord(J.Types[0]))=(Ord(jtNumber)), 'j.Types[0]=jtNumber');
    FContext.AssertTrue((0)=(J.Int64s[0]), 'J.Int64s[0]=0');
    TestAsInteger(J[0],0);
    TestAsInt64(J[0],0);
    TestAsQword(J[0],0);
    TestJSON(J,'[0, 1]');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestInsertFloat;
Var
  J : TJSONArray;
  S,S2 : String;
  F : TJSONFloat;
begin
  F:=1.2;
  J:=TJSonArray.Create;
  try
    J.Add(2.3);
    J.Insert(0,F);
    TestItemCount(J,2);
    TestJSONType(J[0],jtNumber);
    FContext.AssertTrue((TJSONfloatNumber)=(J[0].ClassType), 'J[0] is TJSONFloatNumber');
    FContext.AssertTrue((Ord(jtNumber))=(ord(J.Types[0])), 'j.Types[0]=jtNumber');
    FContext.AssertTrue((F)=(J.Floats[0]), 'J.Floats[0]='+FloatToStr(F));
    TestAsFloat(J[0],F);
    Str(F,S);
    Delete(S,1,1);
    F:=2.3;
    Str(F,S2);
    Delete(S2,1,1);
    TestJSON(J,'['+S+', '+S2+']');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestInsertBooleanTrue;
begin
  TestInsertBoolean(True);
end;

procedure TTestArray.TestInsertBooleanFalse;
begin
  TestInsertBoolean(False);
end;

procedure TTestArray.TestInsertString;

Var
  J : TJSONArray;
  S : String;

begin
  S:='A string';
  J:=TJSonArray.Create;
  try
    J.Add('Another string');
    J.Insert(0,S);
    TestItemCount(J,2);
    TestJSONType(J[0],jtString);
    FContext.AssertTrue((TJSONString)=(J[0].ClassType), 'J[0] is TJSONString');
    TestAsString(J[0],S);
    FContext.AssertTrue((S)=(J.Strings[0]), 'J.Strings[0]="'+S+'"');
    TestJSON(J,'["'+StringToJSONString(S)+'", "Another string"]');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestInsertNull;
Var
  J : TJSONArray;

begin
  J:=TJSonArray.Create;
  try
    J.Add(123);
    J.Insert(0);
    TestItemCount(J,2);
    TestJSONType(J[0],jtNull);
    FContext.AssertTrue((TJSONNull)=(J[0].ClassType), 'J[0] is TJSONNull');
    FContext.AssertTrue((True)=(J.Nulls[0]), 'J.Nulls[0]=True');
    TestIsNull(J[0],true);
    TestJSON(J,'[null, 123]');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestInsertObject;
Const
  A = 'a';
  B = 'b';

Var
  J : TJSONArray;
  J2 : TJSONObject;

begin
  J:=TJSonArray.Create;
  try
    J.Add('A string');
    J2:=TJSonObject.Create;
    J2.Add(A,0);
    J2.Add(B,1);
    J.Insert(0,J2);
    TestItemCount(J,2);
    TestJSONType(J[0],jtObject);
    FContext.AssertTrue((TJSONObject)=(J[0].ClassType), 'J[0] is TJSONObject');
    FContext.AssertTrue((TJSONObject)=(J.Objects[0].ClassType), 'J.Objects[0] is TJSONObject');
    TestAsInteger(J.Objects[0][A],0);
    TestAsInteger(J.Objects[0][B],1);
    TestAsInt64(J.Objects[0][A],0);
    TestAsInt64(J.Objects[0][B],1);
    TestAsQword(J.Objects[0][A],0);
    TestAsQword(J.Objects[0][B],1);
    TestJSON(J,'[{ "a" : 0, "b" : 1 }, "A string"]');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestInsertArray;
Var
  J,J2 : TJSONArray;

begin
  J:=TJSonArray.Create;
  try
    J.Add('Something nice');
    J2:=TJSonArray.Create;
    J2.Add(0);
    J2.Add(1);
    J.Insert(0,J2);
    TestItemCount(J,2);
    TestJSONType(J[0],jtArray);
    FContext.AssertTrue((TJSONArray)=(J[0].ClassType), 'J[0] is TJSONArray');
    FContext.AssertTrue((TJSONArray)=(J.Arrays[0].ClassType), 'J.Arrays[0] is TJSONArray');
    TestAsInteger(J.Arrays[0][0],0);
    TestAsInteger(J.Arrays[0][1],1);
    TestAsInt64(J.Arrays[0][0],0);
    TestAsInt64(J.Arrays[0][1],1);
    TestAsQWord(J.Arrays[0][0],0);
    TestAsQWord(J.Arrays[0][1],1);
    TestJSON(J,'[[0, 1], "Something nice"]');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestMove;
Var
  J : TJSONArray;

begin
  J:=TJSonArray.Create;
  try
    J.Add('First string');
    J.Add('Second string');
    J.Add('Third string');
    J.Move(2,1);
    TestItemCount(J,3);
    FContext.AssertTrue((TJSONString)=(J[1].ClassType), 'J[2] is TJSONString');
    FContext.AssertTrue((TJSONString)=(J[2].ClassType), 'J[1] is TJSONString');
    TestAsString(J[1],'Third string');
    TestAsString(J[2],'Second string');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestExchange;
Var
  J : TJSONArray;

begin
  J:=TJSonArray.Create;
  try
    J.Add('First string');
    J.Add('Second string');
    J.Add('Third string');
    J.Exchange(2,0);
    TestItemCount(J,3);
    FContext.AssertTrue((TJSONString)=(J[0].ClassType), 'J[2] is TJSONString');
    FContext.AssertTrue((TJSONString)=(J[2].ClassType), 'J[1] is TJSONString');
    TestAsString(J[0],'Third string');
    TestAsString(J[2],'First string');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestAddObject;

Const
  A = 'a';
  B = 'b';

Var
  J : TJSONArray;
  J2 : TJSONObject;

begin
  J:=TJSonArray.Create;
  try
    J2:=TJSonObject.Create;
    J2.Add(A,0);
    J2.Add(B,1);
    J.Add(J2);
    TestItemCount(J,1);
    TestJSONType(J[0],jtObject);
    FContext.AssertTrue((TJSONObject)=(J[0].ClassType), 'J[0] is TJSONObject');
    FContext.AssertTrue((TJSONObject)=(J.Objects[0].ClassType), 'J.Objects[0] is TJSONObject');
    TestAsInteger(J.Objects[0][A],0);
    TestAsInteger(J.Objects[0][B],1);
    TestAsInt64(J.Objects[0][A],0);
    TestAsInt64(J.Objects[0][B],1);
    TestAsQword(J.Objects[0][A],0);
    TestAsQword(J.Objects[0][B],1);
    TestJSON(J,'[{ "a" : 0, "b" : 1 }]');
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestDelete;

Var
  J : TJSONArray;

begin
  J:=TJSonArray.Create;
  try
    J.Add(0);
    J.Add(1);
    TestItemCount(J,2);
    TestJSONType(J[0],jtNumber);
    TestJSONType(J[1],jtNumber);
    TestJSON(J,'[0, 1]');
    J.Delete(1);
    TestItemCount(J,1);
    J.Delete(0);
    TestItemCount(J,0);
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestRemove;

Var
  J : TJSONArray;
  I : TJSONData;

begin
  J:=TJSonArray.Create;
  try
    J.Add(0);
    J.Add(1);
    J.Add(2);
    TestItemCount(J,3);
    TestJSONType(J[0],jtNumber);
    TestJSONType(J[1],jtNumber);
    TestJSONType(J[2],jtNumber);
    TestJSON(J,'[0, 1, 2]');
    I:=J[1];
    J.Remove(I);
    TestItemCount(J,2);
    TestAsInteger(J[0],0);
    TestAsInteger(J[1],2);
    TestAsInt64(J[0],0);
    TestAsInt64(J[1],2);
    TestAsQWord(J[0],0);
    TestAsQWord(J[1],2);
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestClone;

Var
  J,J2 : TJSONArray;
  D : TJSONData;

begin
  J:=TJSonArray.Create;
  try
    J.Add(1);
    J.Add('aloha');
    D:=J.Clone;
    try
      TestJSONType(D,jtArray);
      J2:=TJSonArray(D);
      TestItemCount(J2,2);
      TestJSONType(J2[0],jtNumber);
      TestJSONType(J2[1],jtString);
      TestAsInteger(J2[0],1);
      TestAsString(J2[1],'aloha');
    finally
      D.Free;
    end;
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestMyClone;
Var
  J : TMyArray;
  D : TJSONData;

begin
  J:=TMyArray.Create;
  try
    J.Add(1);
    J.Add('aloha');
    D:=J.Clone;
    try
      TestJSONType(D,jtArray);
      FContext.AssertTrue((TMyArray)=(D.ClassType), 'Correct class');
    finally
      D.Free;
    end;
  finally
    FreeAndNil(J);
  end;
end;

procedure TTestArray.TestFormat;
Var
  J : TJSONArray;

begin
  J:=TJSonArray.Create;
  try
    J.Add(0);
    J.Add(1);
    J.Add(2);
    TestItemCount(J,3);
    TestJSONType(J[0],jtNumber);
    TestJSONType(J[1],jtNumber);
    TestJSONType(J[2],jtNumber);
    TestJSON(J,'[0, 1, 2]');
    FContext.AssertTrue((J.AsJSON)=(J.FormatJSON([foSingleLineArray],1)), 'FormatJSON, single line');
    FContext.AssertTrue(('['+sLinebreak+'  0,'+sLinebreak+'  1,'+sLinebreak+'  2'+sLinebreak+']')=(J.FormatJSON()), 'FormatJSON, default');
    FContext.AssertTrue(('['+sLinebreak+#9'0,'+sLinebreak+#9'1,'+sLinebreak+#9'2'+sLinebreak+']')=(J.FormatJSON([foUseTabChar],1)), 'FormatJSON, use tab');
    J.Add(TJSONObject.Create(['x',1,'y',2]));
    FContext.AssertTrue(('['+sLinebreak+#9'0,'+sLinebreak+#9'1,'+sLinebreak+#9'2,'+sLinebreak+#9'{'+sLineBreak+#9#9'"x" : 1,'+sLineBreak+#9#9'"y" : 2'+sLinebreak+#9'}'+sLineBreak+']')=(J.FormatJSON([foUseTabChar],1)), 'FormatJSON, use tab indentsize 1');
  finally
    J.Free
  end;
end;

procedure TTestArray.TestFormatNil;

Var
  J : TJSONArray;

begin
  J:=TJSonArray.Create;
  try
    J.Add(1);
    J.Add(TJSONObject(Nil));
    TestJSON(J,'[1, null]');
    FContext.AssertTrue((J.AsJSON)=(J.FormatJSON([foSingleLineArray],1)), 'FormatJSON, single line');
  finally
    J.Free;
  end;
end;

{ TTestObject }

procedure TTestObject.TestCreate;

begin
  TestJSONType(J,jtObject);
  TestItemCount(J,0);
  TestJSON(J,'{}');
  TestIsNull(J,False);
  TestAsBoolean(J,False,True);
  TestAsInteger(J,1,True);
  TestAsInt64(J,1,True);
  TestAsQword(J,1,True);
  TestAsString(J,'',True);
  TestAsFloat(J,0.0,True);
end;

procedure TTestObject.TestAddInteger;

Const
  A = 'a';

begin
  J.Add(A,Integer(0));
  TestItemCount(J,1);
  TestJSONType(J[A],jtNumber);
  FContext.AssertTrue((J[A].ClassType)=(TJSONIntegerNumber), 'J[''a''] is TJSONIntegerNumber');
  FContext.AssertTrue((ord(J.Types[A]))=(Ord(jtNumber)), 'j.Types[''a'']=jtNumber');
  FContext.AssertTrue((0)=(J.integers[A]), 'J.Integers[''a'']=0');
  TestAsInteger(J[A],0);
  TestAsInt64(J[A],0);
  TestAsQword(J[A],0);
  TestJSON(J,'{ "'+A+'" : 0 }');
end;

procedure TTestObject.TestAddInt64;

Const
  A = 'a';

begin
  J.Add(A,Int64(0));
  TestItemCount(J,1);
  TestJSONType(J[A],jtNumber);
  FContext.AssertTrue((J[A].ClassType)=(TJSONInt64Number), 'J[''a''] is TJSONInt64Number');
  FContext.AssertTrue((ord(J.Types[A]))=(Ord(jtNumber)), 'j.Types[''a'']=jtNumber');
  FContext.AssertTrue((0)=(J.Int64s[A]), 'J.Int64s[''a'']=0');
  TestAsInteger(J[A],0);
  TestAsInt64(J[A],0);
  TestAsQword(J[A],0);
  TestJSON(J,'{ "'+A+'" : 0 }');
end;

procedure TTestObject.TestAddFloat;

Const
  A = 'a';

Var
  S : String;
  F : TJSONFloat;
begin
  F:=1.2;
  J.Add(A,F);
  TestItemCount(J,1);
  TestJSONType(J[A],jtNumber);
  FContext.AssertTrue((TJSONfloatNumber)=(J[a].ClassType), 'J[''a''] is TJSONFloatNumber');
  FContext.AssertTrue((Ord(jtNumber))=(ord(J.Types[a])), 'j.Types[''a'']=jtNumber');
  FContext.AssertTrue((F)=(J.Floats[a]), 'J.Floats[''a'']='+FloatToStr(F));
  TestAsFloat(J[A],F);
  Str(F,S);
  TestJSON(J,'{ "'+a+'" :'+S+' }');
end;

procedure TTestObject.Setup;
begin
  inherited Setup;
  FJ:=TJSONObject.Create;
end;

procedure TTestObject.TearDown;
begin
  FreeAndNil(FJ);
  inherited TearDown;
end;

procedure TTestObject.TestAddBoolean(B : Boolean);

Const
  A = 'a';

begin
  B:=True;
  J.Add(A,B);
  TestItemCount(J,1);
  TestJSONType(J[A],jtBoolean);
  FContext.AssertTrue((TJSONBoolean)=(J[a].ClassType), 'J[''a''] is TJSONBoolean');
  TestAsBoolean(J[a],B);
  FContext.AssertTrue((B)=(J.Booleans[a]), 'J.Booleans[''a'']='+BoolToStr(B)+'"');
  If B then
    TestJSON(J,'{ "'+a+'" : true }')
  else
    TestJSON(J,'{ "'+a+'" : false }');
end;

procedure TTestObject.TestAccessError;

begin
  J.Strings['NonExist'];
end;

procedure TTestObject.TestAddBooleanTrue;

begin
  TestAddBoolean(True);
end;

procedure TTestObject.TestAddBooleanFalse;

begin
  TestAddBoolean(False);
end;

procedure TTestObject.TestAddString;

Const
  A = 'a';

Var
  S : String;

begin
  S:='A string';
    J.Add(A,S);
    TestItemCount(J,1);
    TestJSONType(J[a],jtString);
    FContext.AssertTrue((TJSONString)=(J[A].ClassType), 'J[''a''] is TJSONString');
    TestAsString(J[a],S);
    FContext.AssertTrue((S)=(J.Strings[A]), 'J.Strings[''a'']="'+S+'"');
    TestJSON(J,'{ "'+a+'" : "'+StringToJSONString(S)+'" }');
end;

procedure TTestObject.TestAddNull;

Const
  A = 'a';

begin
  J.Add(a);
  TestItemCount(J,1);
  TestJSONType(J[a],jtNull);
  FContext.AssertTrue((TJSONNull)=(J[A].ClassType), 'J[''a''] is TJSONNull');
  FContext.AssertTrue((True)=(J.Nulls[A]), 'J.Nulls[''a'']=True');
  TestIsNull(J[a],true);
  TestJSON(J,'{ "'+a+'" : null }');
end;

procedure TTestObject.TestAddObject;

Const
  A = 'a';
  B = 'b';
  C = 'c';

Var
  J2 : TJSONObject;

begin
  J2:=TJSonObject.Create;
  J2.Add(B,0);
  J2.Add(C,1);
  J.Add(A,J2);
  TestItemCount(J,1);
  TestJSONType(J[A],jtObject);
  FContext.AssertTrue((TJSONObject)=(J[A].ClassType), 'J[''a''] is TJSONObject');
  FContext.AssertTrue((TJSONObject)=(J.Objects[A].ClassType), 'J.Objects[''a''] is TJSONObject');
  TestAsInteger(J.Objects[A][B],0);
  TestAsInteger(J.Objects[A][C],1);
  TestAsInt64(J.Objects[A][B],0);
  TestAsInt64(J.Objects[A][C],1);
  TestAsQword(J.Objects[A][B],0);
  TestAsQword(J.Objects[A][C],1);
  TestJSON(J,'{ "a" : { "b" : 0, "c" : 1 } }');
end;

procedure TTestObject.TestAddArray;

Const
  A = 'a';

Var
  J2 : TJSONArray;

begin
  J2:=TJSonArray.Create;
  J2.Add(0);
  J2.Add(1);
  J.Add(A,J2);
  TestItemCount(J,1);
  TestJSONType(J[A],jtArray);
  FContext.AssertTrue((TJSONArray)=(J[A].ClassType), 'J[''a''] is TJSONArray');
  FContext.AssertTrue((TJSONArray)=(J.Arrays[A].ClassType), 'J.Arrays[0] is TJSONArray');
  TestAsInteger(J.Arrays[A][0],0);
  TestAsInteger(J.Arrays[A][1],1);
  TestAsInt64(J.Arrays[A][0],0);
  TestAsInt64(J.Arrays[A][1],1);
  TestAsQword(J.Arrays[A][0],0);
  TestAsQword(J.Arrays[A][1],1);
  TestJSON(J,'{ "a" : [0, 1] }');
end;

procedure TTestObject.TestDelete;

Const
  A = 'a';
  B = 'b';

begin
  J.Add(A,0);
  J.Add(B,1);
  TestItemCount(J,2);
  TestJSONType(J[A],jtNumber);
  TestJSONType(J[A],jtNumber);
  TestJSON(J,'{ "a" : 0, "b" : 1 }');
  J.Delete(1);
  TestItemCount(J,1);
  J.Delete(0);
  TestItemCount(J,0);
end;

procedure TTestObject.TestRemove;

Const
  A = 'a';
  B = 'b';
  C = 'c';

Var
  I : TJSONData;

begin
  J.Add(A,1);
  J.Add(B,2);
  J.Add(C,3);
  TestItemCount(J,3);
  TestJSONType(J[A],jtNumber);
  TestJSONType(J[B],jtNumber);
  TestJSONType(J[C],jtNumber);
  TestJSON(J,'{ "a" : 1, "b" : 2, "c" : 3 }');
  I:=J[b];
  J.Remove(I);
  TestItemCount(J,2);
  TestAsInteger(J[a],1);
  TestAsInteger(J[c],3);
  TestAsInt64(J[a],1);
  TestAsInt64(J[c],3);
  TestAsQword(J[a],1);
  TestAsQword(J[c],3);
end;

procedure TTestObject.TestClone;

Var
  J2 : TJSONObject;
  D : TJSONData;

begin
  J.Add('p1',1);
  J.Add('p2','aloha');
  D:=J.Clone;
  try
    TestJSONType(D,jtObject);
    J2:=TJSonObject(D);
    TestItemCount(J2,2);
    TestJSONType(J2['p1'],jtNumber);
    TestJSONType(J2['p2'],jtString);
    TestAsInteger(J2['p1'],1);
    TestAsString(J2['p2'],'aloha');
  finally
    D.Free;
  end;
end;

procedure TTestObject.TestMyClone;

Var
  D : TJSONData;
  O : TMyObject;

begin
  D:=Nil;
  O:=TMyObject.Create;
  try
    O.Add('p1',1);
    O.Add('p2','aloha');
    D:=O.Clone;
    TestJSONType(D,jtObject);
    FContext.AssertTrue((TMYObject)=(D.ClassType), 'Correct class');
  finally
    D.Free;
    O.Free;
  end;
end;

procedure TTestObject.TestExtract;

Const
  A = 'a';
  B = 'b';

Var
  JA,JB : TJSONData;
  E : TJSONData;

begin
  J.Add(A,0);
  J.Add(B,1);
  TestItemCount(J,2);
  JA:=J[A];
  JB:=J[B];
  TestJSONType(JA,jtNumber);
  TestJSONType(JB,jtNumber);
  TestJSON(J,'{ "a" : 0, "b" : 1 }');
  E:=J.Extract(1);
  FContext.AssertTrue((JB)=(E), 'Extracted JA');
  E.Free;
  TestItemCount(J,1);
  E:=J.Extract(0);
  FContext.AssertTrue((JA)=(E), 'Extracted JB');
  E.Free;
  TestItemCount(J,0);
end;

procedure TTestObject.TestNonExistingAccessError;
begin
  FContext.AssertRaises(EJSON, @TestAccessError, '');
end;

procedure TTestObject.TestFormat;

Var
  O : TJSONObject;

begin
  O:=TJSONObject.Create(['x',1,'y',2]);
  try
    TestJSON(O,'{ "x" : 1, "y" : 2 }');
    FContext.AssertTrue((O.AsJSON)=(O.FormatJSON([foSingleLineObject])), 'Format equals JSON');
    FContext.AssertTrue(('{"x":1,"y":2}')=(O.FormatJSON([foSingleLineObject,foSkipWhiteSpace])), 'Format using SkipWhiteSpace');
    FContext.AssertTrue(('{"x": 1,"y": 2}')=(O.FormatJSON([foSingleLineObject,foSkipWhiteSpace,foSkipWhiteSpaceOnlyLeading])), 'Format using SkipWhiteSpace,foSkipWhiteSpaceOnlyLeading');
    FContext.AssertTrue(('{x:1,y:2}')=(O.FormatJSON([foSingleLineObject,foSkipWhiteSpace,foDoNotQuoteMembers])), 'Format using SkipWhiteSpace,unquotednames');
    FContext.AssertTrue(('{'+sLineBreak+'  "x" : 1,'+sLineBreak+'  "y" : 2'+sLineBreak+'}')=(O.FormatJSON([])), 'Format []');
    FContext.AssertTrue(('{'+sLineBreak+'  x : 1,'+sLineBreak+'  y : 2'+sLineBreak+'}')=(O.FormatJSON([foDoNotQuoteMembers])), 'Format [foDoNotQuoteMembers]');
    FContext.AssertTrue(('{'+sLineBreak+#9'x : 1,'+sLineBreak+#9'y : 2'+sLineBreak+'}')=(O.FormatJSON([foUseTabChar,foDoNotQuoteMembers],1)), 'Format [foUseTabChar,foDoNotQuoteMembers]');
    O.Add('s',TJSONObject.Create(['w',10,'h',20]));
    FContext.AssertTrue(('{'+sLineBreak+#9'x : 1,'+sLineBreak+#9'y : 2,'+sLineBreak+#9's : {'+sLineBreak+#9#9'w : 10,'+sLineBreak+#9#9'h : 20'+sLineBreak+#9'}'+sLineBreak+'}')=(O.FormatJSON([foUseTabChar,foDoNotQuoteMembers],1)), 'Format [foUseTabChar,foDoNotQuoteMembers] 2');
  finally
    O.Free;
  end;
end;

procedure TTestObject.TestFormatNil;

begin
  J.Add('a',1);
  J.Add('b',TJSONObject(Nil));
  TestJSON(J,'{ "a" : 1, "b" : null }');
  FContext.AssertTrue((J.AsJSON)=(J.FormatJSON([foSingleLineObject],1)), 'FormatJSON, single line');
end;

procedure TTestObject.TestFormatForceLF;
Var
  O : TJSONObject;
begin
  if sLineBreak=#10 then
    FContext.Skip('Not relevant when linebreak is LF');
  O:=TJSONObject.Create(['x',1,'y',2]);
  try
    TestJSON(O,'{ "x" : 1, "y" : 2 }');
    FContext.AssertTrue(('{'+#10+'  "x" : 1,'+#10+'  "y" : 2'+#10+'}')=(O.FormatJSON([foForceLF])), 'FormatJSON, forced LF');
  finally
    O.Free;
  end;
end;

procedure TTestObject.TestFind;

Const
  A = 'A';
  S = 'A string';
  B = 'a';
  S2 = 'Another string';
  C = 'c';
  S3 = 'Yet Another string';

begin
  J.Add(A,S);
  J.Add(B,S2);
  J.Add(C,S3);
  TestJSONType(J,jtObject);
  TestIsNull(J,False);
  TestItemCount(J,3);
  TestJSONType(J[A],jtString);
  TestJSONType(J[B],jtString);
  TestJSON(J,'{ "A" : "'+S+'", "a" : "'+S2+'", "c" : "'+S3+'" }');
  FContext.AssertTrue((-1)=(J.IndexOfName('D')), 'Nonexisting, case sensitive');
  FContext.AssertTrue((-1)=(J.IndexOfName('D',True)), 'Nonexisting, case insensitive');
  FContext.AssertTrue((0)=(J.IndexOfName(A)), '1 Existing , case sensitive');
  FContext.AssertTrue((0)=(J.IndexOfName(A,true)), '2 Existing exact match, case insensitive');
  FContext.AssertTrue((1)=(J.IndexOfName(B)), '3 Existing , case sensitive');
  FContext.AssertTrue((1)=(J.IndexOfName(B,true)), '4 Existing exact match, case insensitive');
  FContext.AssertTrue((2)=(J.IndexOfName(C)), '5 Existing , case sensitive again');
  FContext.AssertTrue((2)=(J.IndexOfName(Uppercase(C),true)), '6 Existing case-insensitive match, case insensitive');
end;

procedure TTestObject.TestIfFind;
Var
  B: TJSONBoolean;
  S: TJSONString;
  N: TJSONNumber;
  D: TJSONData;
begin
  J.Add('s', 'astring');
  J.Add('b', true);
  J.Add('n', 1);
  TestJSONType(J,jtObject);
  TestIsNull(J,False);
  TestItemCount(J,3);
  FContext.AssertTrue((true)=(j.Find('b', B)), 'boolean found');
  FContext.AssertTrue((true)=(j.Find('s', S)), 'string found');
  FContext.AssertTrue((true)=(j.Find('n', N)), 'number found');
  FContext.AssertTrue((true)=(j.Find('s', D)), 'data found');
end;

procedure TTestObject.AppendA;

begin
  J.Add('A','S')
end;

procedure TTestObject.TestDuplicate;

begin
  J.Add('A',TJSONObject.Create);
  FContext.AssertRaises(EJSON, @AppendA, '');
end;


procedure TTestObject.TestCreateString;

Const
  A = 'A';
  S = 'A string';

begin
  J.Add(A,S);
  TestJSONType(J,jtObject);
  TestItemCount(J,1);
  TestJSONType(J[A],jtString);
  TestJSON(J,'{ "A" : "'+S+'" }');
  TestIsNull(J,False);
end;

procedure TTestObject.TestCreateStringUnquoted;

Const
  A = 'A';
  S = 'A string';

begin
  TJSONObject.UnquotedMemberNames:=True;
  J.Add(A,S);
  TestJSONType(J,jtObject);
  TestItemCount(J,1);
  TestJSONType(J[A],jtString);
  TestJSON(J,'{ A : "'+S+'" }');
  TestIsNull(J,False);
end;

procedure TTestObject.TestCreatePchar;

Const
  A = 'A';
  S = 'A string';

Var
  O : TJSONObject;

begin
  O:=TJSONObject.Create([A,PAnsiChar(S)]);
  try
    TestJSONType(O,jtObject);
    TestItemCount(O,1);
    TestJSONType(O[A],jtString);
    TestJSON(O,'{ "A" : "'+S+'" }');
    TestIsNull(O,False);
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreatePcharUnquoted;

Const
  A = 'A';
  S = 'A string';

Var
  O : TJSONObject;

begin
  TJSONObject.UnQuotedMemberNames:=True;
  O:=TJSONObject.Create([A,PAnsiChar(S)]);
  try
    TestJSONType(O,jtObject);
    TestItemCount(O,1);
    TestJSONType(O[A],jtString);
    TestJSON(O,'{ A : "'+S+'" }');
    TestIsNull(O,False);
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreateStrings;

Const
  A = 'A';
  B = 'B';
  S = 'A string';
  T = 'B string';

Var
  O : TJSONObject;

begin
  O:=TJSONObject.Create([A,S,B,T]);
  try
    TestJSONType(O,jtObject);
    TestItemCount(O,2);
    TestJSONType(O[A],jtString);
    TestJSONType(O[B],jtString);
    TestJSON(O,'{ "A" : "'+S+'", "B" : "'+T+'" }');
    TestIsNull(O,False);
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreateStringsCompressed;

Const
  A = 'A';
  B = 'B';
  S = 'A string';
  T = 'B string';

Var
  O : TJSONObject;

begin
  TJSONData.CompressedJSON:=True;
  O:=TJSONObject.Create([A,S,B,T]);
  try
    TestJSONType(O,jtObject);
    TestItemCount(O,2);
    TestJSONType(O[A],jtString);
    TestJSONType(O[B],jtString);
    TestJSON(O,'{"A":"'+S+'","B":"'+T+'"}');
    TestIsNull(O,False);
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreateStringsCompressedUnquoted;

Const
  A = 'A';
  B = 'B';
  S = 'A string';
  T = 'B string';

Var
  O : TJSONObject;

begin
  TJSONData.CompressedJSON:=True;
  TJSONObject.UnQuotedMemberNames:=True;
  O:=TJSONObject.Create([A,S,B,T]);
  try
    TestJSONType(O,jtObject);
    TestItemCount(O,2);
    TestJSONType(O[A],jtString);
    TestJSONType(O[B],jtString);
    TestJSON(O,'{A:"'+S+'",B:"'+T+'"}');
    TestIsNull(O,False);
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreateInteger;

Const
  A = 'A';
  S = 3;

Var
  O : TJSONObject;

begin
  O:=TJSONObject.Create([A,S]);
  try
    TestJSONType(O,jtObject);
    TestItemCount(O,1);
    TestJSONType(O[A],jtNumber);
    TestJSON(O,'{ "A" : 3 }');
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreateIntegerUnquoted;
Const
  A = 'A';
  S = 3;

Var
  O : TJSONObject;

begin
  TJSONObject.UnQuotedMemberNames:=True;
  O:=TJSONObject.Create([A,S]);
  try
    TestJSONType(O,jtObject);
    TestItemCount(O,1);
    TestJSONType(O[A],jtNumber);
    TestJSON(O,'{ A : 3 }');
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreateFloat;

Const
  A = 'A';
  S : double = 1.2;

Var
  O : TJSONObject;
  r : String;

begin
  O:=TJSONObject.Create([A,S]);
  try
    TestJSONType(O,jtObject);
    TestItemCount(O,1);
    TestJSONType(O[A],jtNumber);
    Str(S,R);
    TestJSON(O,'{ "A" :'+R+' }');
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreateFloatUnquoted;
Const
  A = 'A';
  S : double = 1.2;

Var
  O : TJSONObject;
  r : String;

begin
  TJSONObject.UnQuotedMemberNames:=True;
  O:=TJSONObject.Create([A,S]);
  try
    TestJSONType(O,jtObject);
    TestItemCount(O,1);
    TestJSONType(O[A],jtNumber);
    Str(S,R);
    TestJSON(O,'{ A :'+R+' }');
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreateInt64;

Const
  A = 'A';
  S : Int64 = $FFFFFFFFFFFFF;

Var
  O : TJSONObject;

begin
  O:=TJSONObject.Create([A,S]);
  try
    TestJSONType(O,jtObject);
    TestItemCount(O,1);
    TestJSONType(O[A],jtNumber);
    TestJSON(O,'{ "A" : '+IntToStr(S)+' }');
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreateInt64Unquoted;
Const
  A = 'A';
  S : Int64 = $FFFFFFFFFFFFF;

Var
  O : TJSONObject;

begin
  TJSONObject.UnQuotedMemberNames:=True;
  O:=TJSONObject.Create([A,S]);
  try
    TestJSONType(O,jtObject);
    TestItemCount(O,1);
    TestJSONType(O[A],jtNumber);
    TestJSON(O,'{ A : '+IntToStr(S)+' }');
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreateQWord;
Const
  A = 'A';
  S : QWord = $FFFFFFFFFFFFF;

Var
  O : TJSONObject;

begin
  O:=TJSONObject.Create([A,S]);
  try
    TestJSONType(O,jtObject);
    TestItemCount(O,1);
    TestJSONType(O[A],jtNumber);
    TestJSON(O,'{ "A" : '+IntToStr(S)+' }');
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreateQWordUnquoted;
Const
  A = 'A';
  S : QWord = $FFFFFFFFFFFFF;

Var
  O : TJSONObject;

begin
  TJSONObject.UnQuotedMemberNames:=True;
  O:=TJSONObject.Create([A,S]);
  try
    TestJSONType(O,jtObject);
    TestItemCount(O,1);
    TestJSONType(O[A],jtNumber);
    TestJSON(O,'{ A : '+IntToStr(S)+' }');
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreateBoolean;

Const
  A = 'A';
  S = True;

Var
  O : TJSONObject;

begin
  O:=TJSONObject.Create([A,S]);
  try
    TestJSONType(O,jtObject);
    TestItemCount(O,1);
    TestJSONType(O[A],jtBoolean);
    TestJSON(O,'{ "A" : true }');
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreateBooleanUnquoted;
Const
  A = 'A';
  S = True;

Var
  O : TJSONObject;

begin
  TJSONObject.UnQuotedMemberNames:=True;
  O:=TJSONObject.Create([A,S]);
  try
    TestJSONType(O,jtObject);
    TestItemCount(O,1);
    TestJSONType(O[A],jtBoolean);
    TestJSON(O,'{ A : true }');
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreateJSONObject;

Const
  A = 'A';

Var
  O : TJSONObject;

begin
  O:=TJSONObject.Create([A,TJSONObject.Create]);
  try
    TestItemCount(O,1);
    TestJSONType(O[A],jtObject);
    TestJSON(O,'{ "A" : {} }');
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreateJSONObjectUnquoted;
Const
  A = 'A';

Var
  O : TJSONObject;

begin
  TJSONObject.UnQuotedMemberNames:=True;
  O:=TJSONObject.Create([A,TJSONObject.Create]);
  try
    TestItemCount(O,1);
    TestJSONType(O[A],jtObject);
    TestJSON(O,'{ A : {} }');
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreateJSONString;

Const
  A = 'A';
  S = 'A string';

Var
  O : TJSONObject;

begin
  O:=TJSONObject.Create([A,TJSONString.Create(S)]);
  try
    TestItemCount(O,1);
    TestJSONType(O[A],jtString);
    TestJSON(O,'{ "A" : "'+S+'" }');
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreateJSONStringUnquoted;

Const
  A = 'A';
  S = 'A string';

Var
  O : TJSONObject;

begin
  TJSONObject.UnQuotedMemberNames:=True;
  O:=TJSONObject.Create([A,TJSONString.Create(S)]);
  try
    TestItemCount(O,1);
    TestJSONType(O[A],jtString);
    TestJSON(O,'{ A : "'+S+'" }');
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreateObject;

Const
  A = 'A';

Var
  O : TJSONObject;
  OO : TObject;

begin
  O:=Nil;
  try
    Try
      OO:=TObject.Create;
      O:=TJSONObject.Create([A,OO]);
      FContext.Fail('Array constructor accepts only TJSONData');
    finally
      FreeAndNil(O);
      FreeAndNil(OO);
    end;
  except
    // Should be OK.
  end;
end;

procedure TTestObject.TestCreateJSONUnicodeString;
Const
  A = 'A';
  S : Unicodestring = 'A string';

Var
  O : TJSONObject;

begin
  O:=TJSONObject.Create([A,S]);
  try
    TestItemCount(O,1);
    TestJSONType(O[A],jtString);
    TestJSON(O,'{ "A" : "'+UTF8Encode(S)+'" }');
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreateJSONWideString;
Const
  A = 'A';
  W : WideString = 'A string';

Var
  O : TJSONObject;

begin
  O:=TJSONObject.Create([A,W]);
  try
    TestItemCount(O,1);
    TestJSONType(O[A],jtString);
    TestJSON(O,'{ "A" : "'+UTF8Encode(W)+'" }');
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreateNilPointer;

Const
  A = 'A';

Var
  O : TJSONObject;
  P : Pointer;

begin
  O:=Nil;
  P:=Nil;
  Try
    O:=TJSONObject.Create([A,P]);
    TestJSONType(O[A],jtNull);
  finally
    FreeAndNil(O);
  end;
end;

procedure TTestObject.TestCreatePointer;

Const
  A = 'A';

Var
  O : TJSONObject;
  P : Pointer;

begin
  O:=Nil;
  P:=@Self;
  try
    Try
      O:=TJSONObject.Create([A,P]);
      FContext.Fail('Array constructor accepts only NIL pointers');
    finally
      FreeAndNil(O);
    end;
  except
    // Should be OK.
  end;
end;

{ TTestJSONString }

procedure TTestJSONString.TestTo(const Src, Dest: String; Strict : Boolean = False);

Var
  S : String;

begin
  S:='StringToJSONString('''+Src+''')='''+Dest+'''';
  FContext.AssertTrue((Dest)=(StringToJSONString(Src,Strict)), S);
end;

procedure TTestJSONString.TestFrom(const Src, Dest: String);

Var
  S : String;

begin
  S:='JSONStringToString('''+Src+''')='''+Dest+'''';
  Flush(output);
  FContext.AssertTrue((Dest)=(JSONStringToString(Src)), S);
end;

procedure TTestJSONString.TestJSONStringToString;

Const
  // Glowing star in UTF8
  GlowingStar = #$F0#$9F#$8C#$9F;
  Chinese = #$95e8#$88ab#$8111#$5b50#$6324#$574f#$4e86;
  Chinese4b = #$95e8#$d867#$de3d#$88ab#$8111#$5b50#$6324#$574f#$4e86;

begin
  TestFrom('','');
  TestFrom('A','A');
  TestFrom('AB','AB');
  TestFrom('ABC','ABC');
  TestFrom('\\','\');
  TestFrom('\/','/');
  TestFrom('\"','"');
  TestFrom('\b',#8);
  TestFrom('\t',#9);
  TestFrom('\n',#10);
  TestFrom('\f',#12);
  TestFrom('\r',#13);
  TestFrom('\bBC',#8'BC');
  TestFrom('\tBC',#9'BC');
  TestFrom('\nBC',#10'BC');
  TestFrom('\fBC',#12'BC');
  TestFrom('\rBC',#13'BC');
  TestFrom('A\b','A'#8);
  TestFrom('A\t','A'#9);
  TestFrom('A\n','A'#10);
  TestFrom('A\f','A'#12);
  TestFrom('A\r','A'#13);
  TestFrom('A\bBC','A'#8'BC');
  TestFrom('A\tBC','A'#9'BC');
  TestFrom('A\nBC','A'#10'BC');
  TestFrom('A\fBC','A'#12'BC');
  TestFrom('A\rBC','A'#13'BC');
  TestFrom('\\\\','\\');
  TestFrom('\/\/','//');
  TestFrom('\"\"','""');
  TestFrom('\b\b',#8#8);
  TestFrom('\t\t',#9#9);
  TestFrom('\n\n',#10#10);
  TestFrom('\f\f',#12#12);
  TestFrom('\r\r',#13#13);
  TestFrom('\u00f8','ø'); // this is ø
  TestFrom('\u00f8\"','ø"'); // this is ø"
  TestFrom('\ud83c\udf1f',GlowingStar);
  TestFrom('\u0041\u0042','AB');   //issue #0038622
  TestFrom('\u0041\u0042\u0043','ABC');
  TestFrom('\u0041\u0042\u0043\u0044','ABCD');
  TestFrom('\u95e8\u88ab\u8111\u5b50\u6324\u574f\u4e86',Utf8Encode(Chinese));
  TestFrom('\u95e8\ud867\ude3d\u88ab\u8111\u5b50\u6324\u574f\u4e86',Utf8Encode(Chinese4b));
end;

procedure TTestJSONString.TestStringToJSONString;
begin
  TestTo('','');
  TestTo('A','A');
  TestTo('AB','AB');
  TestTo('ABC','ABC');
  TestTo('\','\\');
  TestTo('/','/');
  TestTo('/','\/',True);
  TestTo('"','\"');
  TestTo(#8,'\b');
  TestTo(#9,'\t');
  TestTo(#10,'\n');
  TestTo(#12,'\f');
  TestTo(#13,'\r');
  TestTo(#8'BC','\bBC');
  TestTo(#9'BC','\tBC');
  TestTo(#10'BC','\nBC');
  TestTo(#12'BC','\fBC');
  TestTo(#13'BC','\rBC');
  TestTo('A'#8,'A\b');
  TestTo('A'#9,'A\t');
  TestTo('A'#10,'A\n');
  TestTo('A'#12,'A\f');
  TestTo('A'#13,'A\r');
  TestTo('A'#8'BC','A\bBC');
  TestTo('A'#9'BC','A\tBC');
  TestTo('A'#10'BC','A\nBC');
  TestTo('A'#12'BC','A\fBC');
  TestTo('A'#13'BC','A\rBC');
  TestTo('\\','\\\\');
  TestTo('//','//');
  TestTo('//','\/\/',true);
  TestTo('""','\"\"');
  TestTo(#8#8,'\b\b');
  TestTo(#9#9,'\t\t');
  TestTo(#10#10,'\n\n');
  TestTo(#12#12,'\f\f');
  TestTo(#13#13,'\r\r');
  TestTo(#0#1#2#3#4#5#6#7#11,'\u0000\u0001\u0002\u0003\u0004\u0005\u0006\u0007\u000B');
  TestTo(#14#15#16#17#18#19,'\u000E\u000F\u0010\u0011\u0012\u0013');
  TestTo(#20#29#30#31#32,'\u0014\u001D\u001E\u001F ');
end;


procedure RunTTestJSONStringTestJSONStringToString(AContext: TNXTestContext);
var lFixture: TTestJSONString;
begin
  lFixture:=TTestJSONString.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestJSONStringToString';
    lFixture.TestJSONStringToString;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStringTestStringToJSONString(AContext: TNXTestContext);
var lFixture: TTestJSONString;
begin
  lFixture:=TTestJSONString.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestStringToJSONString';
    lFixture.TestStringToJSONString;
  finally lFixture.Free; end;
end;

procedure RunTTestNullTestNull(AContext: TNXTestContext);
var lFixture: TTestNull;
begin
  lFixture:=TTestNull.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNull';
    lFixture.SetUp;
    lFixture.TestNull;
  finally lFixture.Free; end;
end;

procedure RunTTestNullTestClone(AContext: TNXTestContext);
var lFixture: TTestNull;
begin
  lFixture:=TTestNull.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClone';
    lFixture.SetUp;
    lFixture.TestClone;
  finally lFixture.Free; end;
end;

procedure RunTTestNullTestMyClone(AContext: TNXTestContext);
var lFixture: TTestNull;
begin
  lFixture:=TTestNull.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMyClone';
    lFixture.SetUp;
    lFixture.TestMyClone;
  finally lFixture.Free; end;
end;

procedure RunTTestNullTestFormat(AContext: TNXTestContext);
var lFixture: TTestNull;
begin
  lFixture:=TTestNull.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFormat';
    lFixture.SetUp;
    lFixture.TestFormat;
  finally lFixture.Free; end;
end;

procedure RunTTestBooleanTestTrue(AContext: TNXTestContext);
var lFixture: TTestBoolean;
begin
  lFixture:=TTestBoolean.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestTrue';
    lFixture.SetUp;
    lFixture.TestTrue;
  finally lFixture.Free; end;
end;

procedure RunTTestBooleanTestFalse(AContext: TNXTestContext);
var lFixture: TTestBoolean;
begin
  lFixture:=TTestBoolean.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFalse';
    lFixture.SetUp;
    lFixture.TestFalse;
  finally lFixture.Free; end;
end;

procedure RunTTestBooleanTestClone(AContext: TNXTestContext);
var lFixture: TTestBoolean;
begin
  lFixture:=TTestBoolean.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClone';
    lFixture.SetUp;
    lFixture.TestClone;
  finally lFixture.Free; end;
end;

procedure RunTTestBooleanTestMyClone(AContext: TNXTestContext);
var lFixture: TTestBoolean;
begin
  lFixture:=TTestBoolean.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMyClone';
    lFixture.SetUp;
    lFixture.TestMyClone;
  finally lFixture.Free; end;
end;

procedure RunTTestBooleanTestFormat(AContext: TNXTestContext);
var lFixture: TTestBoolean;
begin
  lFixture:=TTestBoolean.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFormat';
    lFixture.SetUp;
    lFixture.TestFormat;
  finally lFixture.Free; end;
end;

procedure RunTTestIntegerTestPositive(AContext: TNXTestContext);
var lFixture: TTestInteger;
begin
  lFixture:=TTestInteger.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestPositive';
    lFixture.SetUp;
    lFixture.TestPositive;
  finally lFixture.Free; end;
end;

procedure RunTTestIntegerTestNegative(AContext: TNXTestContext);
var lFixture: TTestInteger;
begin
  lFixture:=TTestInteger.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNegative';
    lFixture.SetUp;
    lFixture.TestNegative;
  finally lFixture.Free; end;
end;

procedure RunTTestIntegerTestZero(AContext: TNXTestContext);
var lFixture: TTestInteger;
begin
  lFixture:=TTestInteger.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestZero';
    lFixture.SetUp;
    lFixture.TestZero;
  finally lFixture.Free; end;
end;

procedure RunTTestIntegerTestClone(AContext: TNXTestContext);
var lFixture: TTestInteger;
begin
  lFixture:=TTestInteger.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClone';
    lFixture.SetUp;
    lFixture.TestClone;
  finally lFixture.Free; end;
end;

procedure RunTTestIntegerTestMyClone(AContext: TNXTestContext);
var lFixture: TTestInteger;
begin
  lFixture:=TTestInteger.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMyClone';
    lFixture.SetUp;
    lFixture.TestMyClone;
  finally lFixture.Free; end;
end;

procedure RunTTestIntegerTestFormat(AContext: TNXTestContext);
var lFixture: TTestInteger;
begin
  lFixture:=TTestInteger.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFormat';
    lFixture.SetUp;
    lFixture.TestFormat;
  finally lFixture.Free; end;
end;

procedure RunTTestInt64TestPositive(AContext: TNXTestContext);
var lFixture: TTestInt64;
begin
  lFixture:=TTestInt64.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestPositive';
    lFixture.SetUp;
    lFixture.TestPositive;
  finally lFixture.Free; end;
end;

procedure RunTTestInt64TestNegative(AContext: TNXTestContext);
var lFixture: TTestInt64;
begin
  lFixture:=TTestInt64.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNegative';
    lFixture.SetUp;
    lFixture.TestNegative;
  finally lFixture.Free; end;
end;

procedure RunTTestInt64TestZero(AContext: TNXTestContext);
var lFixture: TTestInt64;
begin
  lFixture:=TTestInt64.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestZero';
    lFixture.SetUp;
    lFixture.TestZero;
  finally lFixture.Free; end;
end;

procedure RunTTestInt64TestClone(AContext: TNXTestContext);
var lFixture: TTestInt64;
begin
  lFixture:=TTestInt64.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClone';
    lFixture.SetUp;
    lFixture.TestClone;
  finally lFixture.Free; end;
end;

procedure RunTTestInt64TestMyClone(AContext: TNXTestContext);
var lFixture: TTestInt64;
begin
  lFixture:=TTestInt64.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMyClone';
    lFixture.SetUp;
    lFixture.TestMyClone;
  finally lFixture.Free; end;
end;

procedure RunTTestInt64TestFormat(AContext: TNXTestContext);
var lFixture: TTestInt64;
begin
  lFixture:=TTestInt64.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFormat';
    lFixture.SetUp;
    lFixture.TestFormat;
  finally lFixture.Free; end;
end;

procedure RunTTestQwordTestPositive(AContext: TNXTestContext);
var lFixture: TTestQword;
begin
  lFixture:=TTestQword.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestPositive';
    lFixture.SetUp;
    lFixture.TestPositive;
  finally lFixture.Free; end;
end;

procedure RunTTestQwordTestZero(AContext: TNXTestContext);
var lFixture: TTestQword;
begin
  lFixture:=TTestQword.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestZero';
    lFixture.SetUp;
    lFixture.TestZero;
  finally lFixture.Free; end;
end;

procedure RunTTestQwordTestClone(AContext: TNXTestContext);
var lFixture: TTestQword;
begin
  lFixture:=TTestQword.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClone';
    lFixture.SetUp;
    lFixture.TestClone;
  finally lFixture.Free; end;
end;

procedure RunTTestQwordTestMyClone(AContext: TNXTestContext);
var lFixture: TTestQword;
begin
  lFixture:=TTestQword.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMyClone';
    lFixture.SetUp;
    lFixture.TestMyClone;
  finally lFixture.Free; end;
end;

procedure RunTTestQwordTestFormat(AContext: TNXTestContext);
var lFixture: TTestQword;
begin
  lFixture:=TTestQword.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFormat';
    lFixture.SetUp;
    lFixture.TestFormat;
  finally lFixture.Free; end;
end;

procedure RunTTestFloatTestPositive(AContext: TNXTestContext);
var lFixture: TTestFloat;
begin
  lFixture:=TTestFloat.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestPositive';
    lFixture.SetUp;
    lFixture.TestPositive;
  finally lFixture.Free; end;
end;

procedure RunTTestFloatTestNegative(AContext: TNXTestContext);
var lFixture: TTestFloat;
begin
  lFixture:=TTestFloat.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNegative';
    lFixture.SetUp;
    lFixture.TestNegative;
  finally lFixture.Free; end;
end;

procedure RunTTestFloatTestZero(AContext: TNXTestContext);
var lFixture: TTestFloat;
begin
  lFixture:=TTestFloat.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestZero';
    lFixture.SetUp;
    lFixture.TestZero;
  finally lFixture.Free; end;
end;

procedure RunTTestFloatTestClone(AContext: TNXTestContext);
var lFixture: TTestFloat;
begin
  lFixture:=TTestFloat.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClone';
    lFixture.SetUp;
    lFixture.TestClone;
  finally lFixture.Free; end;
end;

procedure RunTTestFloatTestMyClone(AContext: TNXTestContext);
var lFixture: TTestFloat;
begin
  lFixture:=TTestFloat.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMyClone';
    lFixture.SetUp;
    lFixture.TestMyClone;
  finally lFixture.Free; end;
end;

procedure RunTTestFloatTestFormat(AContext: TNXTestContext);
var lFixture: TTestFloat;
begin
  lFixture:=TTestFloat.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFormat';
    lFixture.SetUp;
    lFixture.TestFormat;
  finally lFixture.Free; end;
end;

procedure RunTTestStringTestString(AContext: TNXTestContext);
var lFixture: TTestString;
begin
  lFixture:=TTestString.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestString';
    lFixture.SetUp;
    lFixture.TestString;
  finally lFixture.Free; end;
end;

procedure RunTTestStringTestControlString(AContext: TNXTestContext);
var lFixture: TTestString;
begin
  lFixture:=TTestString.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestControlString';
    lFixture.SetUp;
    lFixture.TestControlString;
  finally lFixture.Free; end;
end;

procedure RunTTestStringTestSolidus(AContext: TNXTestContext);
var lFixture: TTestString;
begin
  lFixture:=TTestString.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSolidus';
    lFixture.SetUp;
    lFixture.TestSolidus;
  finally lFixture.Free; end;
end;

procedure RunTTestStringTestInteger(AContext: TNXTestContext);
var lFixture: TTestString;
begin
  lFixture:=TTestString.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInteger';
    lFixture.SetUp;
    lFixture.TestInteger;
  finally lFixture.Free; end;
end;

procedure RunTTestStringTestNegativeInteger(AContext: TNXTestContext);
var lFixture: TTestString;
begin
  lFixture:=TTestString.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNegativeInteger';
    lFixture.SetUp;
    lFixture.TestNegativeInteger;
  finally lFixture.Free; end;
end;

procedure RunTTestStringTestFloat(AContext: TNXTestContext);
var lFixture: TTestString;
begin
  lFixture:=TTestString.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFloat';
    lFixture.SetUp;
    lFixture.TestFloat;
  finally lFixture.Free; end;
end;

procedure RunTTestStringTestNegativeFloat(AContext: TNXTestContext);
var lFixture: TTestString;
begin
  lFixture:=TTestString.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNegativeFloat';
    lFixture.SetUp;
    lFixture.TestNegativeFloat;
  finally lFixture.Free; end;
end;

procedure RunTTestStringTestBooleanTrue(AContext: TNXTestContext);
var lFixture: TTestString;
begin
  lFixture:=TTestString.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestBooleanTrue';
    lFixture.SetUp;
    lFixture.TestBooleanTrue;
  finally lFixture.Free; end;
end;

procedure RunTTestStringTestBooleanFalse(AContext: TNXTestContext);
var lFixture: TTestString;
begin
  lFixture:=TTestString.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestBooleanFalse';
    lFixture.SetUp;
    lFixture.TestBooleanFalse;
  finally lFixture.Free; end;
end;

procedure RunTTestStringTestClone(AContext: TNXTestContext);
var lFixture: TTestString;
begin
  lFixture:=TTestString.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClone';
    lFixture.SetUp;
    lFixture.TestClone;
  finally lFixture.Free; end;
end;

procedure RunTTestStringTestMyClone(AContext: TNXTestContext);
var lFixture: TTestString;
begin
  lFixture:=TTestString.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMyClone';
    lFixture.SetUp;
    lFixture.TestMyClone;
  finally lFixture.Free; end;
end;

procedure RunTTestStringTestFormat(AContext: TNXTestContext);
var lFixture: TTestString;
begin
  lFixture:=TTestString.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFormat';
    lFixture.SetUp;
    lFixture.TestFormat;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestCreate(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreate';
    lFixture.SetUp;
    lFixture.TestCreate;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestCreateString(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateString';
    lFixture.SetUp;
    lFixture.TestCreateString;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestCreatePchar(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreatePchar';
    lFixture.SetUp;
    lFixture.TestCreatePchar;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestCreateStrings(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateStrings';
    lFixture.SetUp;
    lFixture.TestCreateStrings;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestCreateStringsCompressed(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateStringsCompressed';
    lFixture.SetUp;
    lFixture.TestCreateStringsCompressed;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestCreateInteger(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateInteger';
    lFixture.SetUp;
    lFixture.TestCreateInteger;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestCreateInt64(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateInt64';
    lFixture.SetUp;
    lFixture.TestCreateInt64;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestCreateFloat(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateFloat';
    lFixture.SetUp;
    lFixture.TestCreateFloat;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestCreateBoolean(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateBoolean';
    lFixture.SetUp;
    lFixture.TestCreateBoolean;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestCreateObject(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateObject';
    lFixture.SetUp;
    lFixture.TestCreateObject;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestCreateJSONString(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateJSONString';
    lFixture.SetUp;
    lFixture.TestCreateJSONString;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestCreateJSONStringSpecialChars(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateJSONStringSpecialChars';
    lFixture.SetUp;
    lFixture.TestCreateJSONStringSpecialChars;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestCreateJSONObject(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateJSONObject';
    lFixture.SetUp;
    lFixture.TestCreateJSONObject;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestCreateNilPointer(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateNilPointer';
    lFixture.SetUp;
    lFixture.TestCreateNilPointer;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestCreatePointer(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreatePointer';
    lFixture.SetUp;
    lFixture.TestCreatePointer;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestAddInteger(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddInteger';
    lFixture.SetUp;
    lFixture.TestAddInteger;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestAddInt64(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddInt64';
    lFixture.SetUp;
    lFixture.TestAddInt64;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestAddFloat(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddFloat';
    lFixture.SetUp;
    lFixture.TestAddFloat;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestAddBooleanTrue(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddBooleanTrue';
    lFixture.SetUp;
    lFixture.TestAddBooleanTrue;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestAddBooleanFalse(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddBooleanFalse';
    lFixture.SetUp;
    lFixture.TestAddBooleanFalse;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestAddString(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddString';
    lFixture.SetUp;
    lFixture.TestAddString;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestAddNull(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddNull';
    lFixture.SetUp;
    lFixture.TestAddNull;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestAddObject(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddObject';
    lFixture.SetUp;
    lFixture.TestAddObject;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestAddArray(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddArray';
    lFixture.SetUp;
    lFixture.TestAddArray;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestInsertInteger(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInsertInteger';
    lFixture.SetUp;
    lFixture.TestInsertInteger;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestInsertInt64(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInsertInt64';
    lFixture.SetUp;
    lFixture.TestInsertInt64;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestInsertFloat(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInsertFloat';
    lFixture.SetUp;
    lFixture.TestInsertFloat;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestInsertBooleanTrue(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInsertBooleanTrue';
    lFixture.SetUp;
    lFixture.TestInsertBooleanTrue;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestInsertBooleanFalse(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInsertBooleanFalse';
    lFixture.SetUp;
    lFixture.TestInsertBooleanFalse;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestInsertString(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInsertString';
    lFixture.SetUp;
    lFixture.TestInsertString;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestInsertNull(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInsertNull';
    lFixture.SetUp;
    lFixture.TestInsertNull;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestInsertObject(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInsertObject';
    lFixture.SetUp;
    lFixture.TestInsertObject;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestInsertArray(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInsertArray';
    lFixture.SetUp;
    lFixture.TestInsertArray;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestMove(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMove';
    lFixture.SetUp;
    lFixture.TestMove;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestExchange(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExchange';
    lFixture.SetUp;
    lFixture.TestExchange;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestDelete(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDelete';
    lFixture.SetUp;
    lFixture.TestDelete;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestRemove(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRemove';
    lFixture.SetUp;
    lFixture.TestRemove;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestClone(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClone';
    lFixture.SetUp;
    lFixture.TestClone;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestMyClone(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMyClone';
    lFixture.SetUp;
    lFixture.TestMyClone;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestFormat(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFormat';
    lFixture.SetUp;
    lFixture.TestFormat;
  finally lFixture.Free; end;
end;

procedure RunTTestArrayTestFormatNil(AContext: TNXTestContext);
var lFixture: TTestArray;
begin
  lFixture:=TTestArray.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFormatNil';
    lFixture.SetUp;
    lFixture.TestFormatNil;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreate(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreate';
    lFixture.SetUp;
    try lFixture.TestCreate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateString(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateString';
    lFixture.SetUp;
    try lFixture.TestCreateString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateStringUnquoted(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateStringUnquoted';
    lFixture.SetUp;
    try lFixture.TestCreateStringUnquoted; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreatePchar(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreatePchar';
    lFixture.SetUp;
    try lFixture.TestCreatePchar; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreatePcharUnquoted(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreatePcharUnquoted';
    lFixture.SetUp;
    try lFixture.TestCreatePcharUnquoted; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateStrings(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateStrings';
    lFixture.SetUp;
    try lFixture.TestCreateStrings; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateStringsCompressed(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateStringsCompressed';
    lFixture.SetUp;
    try lFixture.TestCreateStringsCompressed; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateStringsCompressedUnquoted(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateStringsCompressedUnquoted';
    lFixture.SetUp;
    try lFixture.TestCreateStringsCompressedUnquoted; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateInteger(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateInteger';
    lFixture.SetUp;
    try lFixture.TestCreateInteger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateIntegerUnquoted(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateIntegerUnquoted';
    lFixture.SetUp;
    try lFixture.TestCreateIntegerUnquoted; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateInt64(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateInt64';
    lFixture.SetUp;
    try lFixture.TestCreateInt64; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateInt64Unquoted(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateInt64Unquoted';
    lFixture.SetUp;
    try lFixture.TestCreateInt64Unquoted; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateQWord(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateQWord';
    lFixture.SetUp;
    try lFixture.TestCreateQWord; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateQWordUnquoted(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateQWordUnquoted';
    lFixture.SetUp;
    try lFixture.TestCreateQWordUnquoted; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateFloat(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateFloat';
    lFixture.SetUp;
    try lFixture.TestCreateFloat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateFloatUnquoted(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateFloatUnquoted';
    lFixture.SetUp;
    try lFixture.TestCreateFloatUnquoted; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateBoolean(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateBoolean';
    lFixture.SetUp;
    try lFixture.TestCreateBoolean; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateBooleanUnquoted(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateBooleanUnquoted';
    lFixture.SetUp;
    try lFixture.TestCreateBooleanUnquoted; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateObject(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateObject';
    lFixture.SetUp;
    try lFixture.TestCreateObject; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateJSONUnicodeString(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateJSONUnicodeString';
    lFixture.SetUp;
    try lFixture.TestCreateJSONUnicodeString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateJSONWideString(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateJSONWideString';
    lFixture.SetUp;
    try lFixture.TestCreateJSONWideString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateJSONString(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateJSONString';
    lFixture.SetUp;
    try lFixture.TestCreateJSONString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateJSONStringUnquoted(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateJSONStringUnquoted';
    lFixture.SetUp;
    try lFixture.TestCreateJSONStringUnquoted; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateJSONObject(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateJSONObject';
    lFixture.SetUp;
    try lFixture.TestCreateJSONObject; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateJSONObjectUnquoted(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateJSONObjectUnquoted';
    lFixture.SetUp;
    try lFixture.TestCreateJSONObjectUnquoted; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreateNilPointer(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateNilPointer';
    lFixture.SetUp;
    try lFixture.TestCreateNilPointer; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestCreatePointer(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreatePointer';
    lFixture.SetUp;
    try lFixture.TestCreatePointer; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestAddInteger(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddInteger';
    lFixture.SetUp;
    try lFixture.TestAddInteger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestAddInt64(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddInt64';
    lFixture.SetUp;
    try lFixture.TestAddInt64; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestAddFloat(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddFloat';
    lFixture.SetUp;
    try lFixture.TestAddFloat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestAddBooleanTrue(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddBooleanTrue';
    lFixture.SetUp;
    try lFixture.TestAddBooleanTrue; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestAddBooleanFalse(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddBooleanFalse';
    lFixture.SetUp;
    try lFixture.TestAddBooleanFalse; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestAddString(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddString';
    lFixture.SetUp;
    try lFixture.TestAddString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestAddNull(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddNull';
    lFixture.SetUp;
    try lFixture.TestAddNull; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestAddObject(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddObject';
    lFixture.SetUp;
    try lFixture.TestAddObject; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestAddArray(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddArray';
    lFixture.SetUp;
    try lFixture.TestAddArray; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestDelete(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDelete';
    lFixture.SetUp;
    try lFixture.TestDelete; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestRemove(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRemove';
    lFixture.SetUp;
    try lFixture.TestRemove; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestClone(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestClone';
    lFixture.SetUp;
    try lFixture.TestClone; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestMyClone(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMyClone';
    lFixture.SetUp;
    try lFixture.TestMyClone; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestExtract(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestExtract';
    lFixture.SetUp;
    try lFixture.TestExtract; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestNonExistingAccessError(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNonExistingAccessError';
    lFixture.SetUp;
    try lFixture.TestNonExistingAccessError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestFormat(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFormat';
    lFixture.SetUp;
    try lFixture.TestFormat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestFormatNil(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFormatNil';
    lFixture.SetUp;
    try lFixture.TestFormatNil; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestFormatForceLF(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFormatForceLF';
    lFixture.SetUp;
    try lFixture.TestFormatForceLF; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestFind(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFind';
    lFixture.SetUp;
    try lFixture.TestFind; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestIfFind(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIfFind';
    lFixture.SetUp;
    try lFixture.TestIfFind; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestObjectTestDuplicate(AContext: TNXTestContext);
var lFixture: TTestObject;
begin
  lFixture:=TTestObject.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDuplicate';
    lFixture.SetUp;
    try lFixture.TestDuplicate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestNullEmpty(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNullEmpty';
    lFixture.SetUp;
    try lFixture.TestNullEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestNullGet(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNullGet';
    lFixture.SetUp;
    try lFixture.TestNullGet; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestNullNonExisting(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNullNonExisting';
    lFixture.SetUp;
    try lFixture.TestNullNonExisting; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestNullNotEmpty(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNullNotEmpty';
    lFixture.SetUp;
    try lFixture.TestNullNotEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestBooleanEmpty(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestBooleanEmpty';
    lFixture.SetUp;
    try lFixture.TestBooleanEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestBooleanNotEmpty(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestBooleanNotEmpty';
    lFixture.SetUp;
    try lFixture.TestBooleanNotEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestIntegerEmpty(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIntegerEmpty';
    lFixture.SetUp;
    try lFixture.TestIntegerEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestIntegerNotEmpty(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIntegerNotEmpty';
    lFixture.SetUp;
    try lFixture.TestIntegerNotEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestInt64Empty(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInt64Empty';
    lFixture.SetUp;
    try lFixture.TestInt64Empty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestInt64NotEmpty(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInt64NotEmpty';
    lFixture.SetUp;
    try lFixture.TestInt64NotEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestFloatEmpty(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFloatEmpty';
    lFixture.SetUp;
    try lFixture.TestFloatEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestFloatNotEmpty(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFloatNotEmpty';
    lFixture.SetUp;
    try lFixture.TestFloatNotEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestStringEmpty(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestStringEmpty';
    lFixture.SetUp;
    try lFixture.TestStringEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestStringNotEmpty(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestStringNotEmpty';
    lFixture.SetUp;
    try lFixture.TestStringNotEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestArrayEmpty(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestArrayEmpty';
    lFixture.SetUp;
    try lFixture.TestArrayEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestArrayNotIndex(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestArrayNotIndex';
    lFixture.SetUp;
    try lFixture.TestArrayNotIndex; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestArrayIncompleteIndex(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestArrayIncompleteIndex';
    lFixture.SetUp;
    try lFixture.TestArrayIncompleteIndex; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestArrayNonNumericalIndex(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestArrayNonNumericalIndex';
    lFixture.SetUp;
    try lFixture.TestArrayNonNumericalIndex; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestArrayOutOfRangeIndex(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestArrayOutOfRangeIndex';
    lFixture.SetUp;
    try lFixture.TestArrayOutOfRangeIndex; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestArrayCorrectIndex(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestArrayCorrectIndex';
    lFixture.SetUp;
    try lFixture.TestArrayCorrectIndex; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestArrayRecursiveArray(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestArrayRecursiveArray';
    lFixture.SetUp;
    try lFixture.TestArrayRecursiveArray; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestArrayRecursiveObject(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestArrayRecursiveObject';
    lFixture.SetUp;
    try lFixture.TestArrayRecursiveObject; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestObjectEmpty(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestObjectEmpty';
    lFixture.SetUp;
    try lFixture.TestObjectEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestObjectDots(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestObjectDots';
    lFixture.SetUp;
    try lFixture.TestObjectDots; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestObjectExisting(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestObjectExisting';
    lFixture.SetUp;
    try lFixture.TestObjectExisting; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestObjectNonExisting(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestObjectNonExisting';
    lFixture.SetUp;
    try lFixture.TestObjectNonExisting; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestObjectTrailingDot(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestObjectTrailingDot';
    lFixture.SetUp;
    try lFixture.TestObjectTrailingDot; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestObjectRecursiveArray(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestObjectRecursiveArray';
    lFixture.SetUp;
    try lFixture.TestObjectRecursiveArray; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestObjectRecursiveObject(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestObjectRecursiveObject';
    lFixture.SetUp;
    try lFixture.TestObjectRecursiveObject; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONPathTestDeepRecursive(AContext: TNXTestContext);
var lFixture: TTestJSONPath;
begin
  lFixture:=TTestJSONPath.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDeepRecursive';
    lFixture.SetUp;
    try lFixture.TestDeepRecursive; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryTestSet(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSet';
    lFixture.SetUp;
    try lFixture.TestSet; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryTestSetInvalid(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSetInvalid';
    lFixture.SetUp;
    try lFixture.TestSetInvalid; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryCreateNull(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='CreateNull';
    lFixture.SetUp;
    try lFixture.CreateNull; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryCreateInteger(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='CreateInteger';
    lFixture.SetUp;
    try lFixture.CreateInteger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryCreateInt64(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='CreateInt64';
    lFixture.SetUp;
    try lFixture.CreateInt64; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryCreateFloat(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='CreateFloat';
    lFixture.SetUp;
    try lFixture.CreateFloat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryCreateBoolean(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='CreateBoolean';
    lFixture.SetUp;
    try lFixture.CreateBoolean; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryCreateString(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='CreateString';
    lFixture.SetUp;
    try lFixture.CreateString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryCreateArray(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='CreateArray';
    lFixture.SetUp;
    try lFixture.CreateArray; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryCreateObject(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='CreateObject';
    lFixture.SetUp;
    try lFixture.CreateObject; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryArrayAddNull(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ArrayAddNull';
    lFixture.SetUp;
    try lFixture.ArrayAddNull; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryArrayAddInteger(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ArrayAddInteger';
    lFixture.SetUp;
    try lFixture.ArrayAddInteger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryArrayAddInt64(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ArrayAddInt64';
    lFixture.SetUp;
    try lFixture.ArrayAddInt64; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryArrayAddFloat(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ArrayAddFloat';
    lFixture.SetUp;
    try lFixture.ArrayAddFloat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryArrayAddBoolean(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ArrayAddBoolean';
    lFixture.SetUp;
    try lFixture.ArrayAddBoolean; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryArrayAddString(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ArrayAddString';
    lFixture.SetUp;
    try lFixture.ArrayAddString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryArrayCreateNull(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ArrayCreateNull';
    lFixture.SetUp;
    try lFixture.ArrayCreateNull; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryArrayCreateInteger(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ArrayCreateInteger';
    lFixture.SetUp;
    try lFixture.ArrayCreateInteger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryArrayCreateInt64(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ArrayCreateInt64';
    lFixture.SetUp;
    try lFixture.ArrayCreateInt64; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryArrayCreateFloat(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ArrayCreateFloat';
    lFixture.SetUp;
    try lFixture.ArrayCreateFloat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryArrayCreateBoolean(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ArrayCreateBoolean';
    lFixture.SetUp;
    try lFixture.ArrayCreateBoolean; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryArrayCreateString(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ArrayCreateString';
    lFixture.SetUp;
    try lFixture.ArrayCreateString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryObjectAddNull(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ObjectAddNull';
    lFixture.SetUp;
    try lFixture.ObjectAddNull; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryObjectAddInteger(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ObjectAddInteger';
    lFixture.SetUp;
    try lFixture.ObjectAddInteger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryObjectAddInt64(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ObjectAddInt64';
    lFixture.SetUp;
    try lFixture.ObjectAddInt64; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryObjectAddFloat(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ObjectAddFloat';
    lFixture.SetUp;
    try lFixture.ObjectAddFloat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryObjectAddBoolean(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ObjectAddBoolean';
    lFixture.SetUp;
    try lFixture.ObjectAddBoolean; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryObjectAddString(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ObjectAddString';
    lFixture.SetUp;
    try lFixture.ObjectAddString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryObjectCreateNull(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ObjectCreateNull';
    lFixture.SetUp;
    try lFixture.ObjectCreateNull; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryObjectCreateInteger(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ObjectCreateInteger';
    lFixture.SetUp;
    try lFixture.ObjectCreateInteger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryObjectCreateInt64(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ObjectCreateInt64';
    lFixture.SetUp;
    try lFixture.ObjectCreateInt64; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryObjectCreateFloat(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ObjectCreateFloat';
    lFixture.SetUp;
    try lFixture.ObjectCreateFloat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryObjectCreateBoolean(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ObjectCreateBoolean';
    lFixture.SetUp;
    try lFixture.ObjectCreateBoolean; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFactoryObjectCreateString(AContext: TNXTestContext);
var lFixture: TTestFactory;
begin
  lFixture:=TTestFactory.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='ObjectCreateString';
    lFixture.SetUp;
    try lFixture.ObjectCreateString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIteratorTestNull(AContext: TNXTestContext);
var lFixture: TTestIterator;
begin
  lFixture:=TTestIterator.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNull';
    lFixture.SetUp;
    try lFixture.TestNull; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIteratorTestInteger(AContext: TNXTestContext);
var lFixture: TTestIterator;
begin
  lFixture:=TTestIterator.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInteger';
    lFixture.SetUp;
    try lFixture.TestInteger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIteratorTestInt64(AContext: TNXTestContext);
var lFixture: TTestIterator;
begin
  lFixture:=TTestIterator.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInt64';
    lFixture.SetUp;
    try lFixture.TestInt64; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIteratorTestFloat(AContext: TNXTestContext);
var lFixture: TTestIterator;
begin
  lFixture:=TTestIterator.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFloat';
    lFixture.SetUp;
    try lFixture.TestFloat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIteratorTestBoolean(AContext: TNXTestContext);
var lFixture: TTestIterator;
begin
  lFixture:=TTestIterator.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestBoolean';
    lFixture.SetUp;
    try lFixture.TestBoolean; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIteratorTestString(AContext: TNXTestContext);
var lFixture: TTestIterator;
begin
  lFixture:=TTestIterator.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestString';
    lFixture.SetUp;
    try lFixture.TestString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIteratorTestArray(AContext: TNXTestContext);
var lFixture: TTestIterator;
begin
  lFixture:=TTestIterator.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestArray';
    lFixture.SetUp;
    try lFixture.TestArray; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIteratorTestObject(AContext: TNXTestContext);
var lFixture: TTestIterator;
begin
  lFixture:=TTestIterator.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestObject';
    lFixture.SetUp;
    try lFixture.TestObject; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegistertestjsondataTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('testjsondata.TTestJSONString');
  lSuite.AddTest('TestJSONStringToString', @RunTTestJSONStringTestJSONStringToString);
  lSuite.AddTest('TestStringToJSONString', @RunTTestJSONStringTestStringToJSONString);
  lSuite:=ARegistry.AddSuite('testjsondata.TTestNull');
  lSuite.AddTest('TestNull', @RunTTestNullTestNull);
  lSuite.AddTest('TestClone', @RunTTestNullTestClone);
  lSuite.AddTest('TestMyClone', @RunTTestNullTestMyClone);
  lSuite.AddTest('TestFormat', @RunTTestNullTestFormat);
  lSuite:=ARegistry.AddSuite('testjsondata.TTestBoolean');
  lSuite.AddTest('TestTrue', @RunTTestBooleanTestTrue);
  lSuite.AddTest('TestFalse', @RunTTestBooleanTestFalse);
  lSuite.AddTest('TestClone', @RunTTestBooleanTestClone);
  lSuite.AddTest('TestMyClone', @RunTTestBooleanTestMyClone);
  lSuite.AddTest('TestFormat', @RunTTestBooleanTestFormat);
  lSuite:=ARegistry.AddSuite('testjsondata.TTestInteger');
  lSuite.AddTest('TestPositive', @RunTTestIntegerTestPositive);
  lSuite.AddTest('TestNegative', @RunTTestIntegerTestNegative);
  lSuite.AddTest('TestZero', @RunTTestIntegerTestZero);
  lSuite.AddTest('TestClone', @RunTTestIntegerTestClone);
  lSuite.AddTest('TestMyClone', @RunTTestIntegerTestMyClone);
  lSuite.AddTest('TestFormat', @RunTTestIntegerTestFormat);
  lSuite:=ARegistry.AddSuite('testjsondata.TTestInt64');
  lSuite.AddTest('TestPositive', @RunTTestInt64TestPositive);
  lSuite.AddTest('TestNegative', @RunTTestInt64TestNegative);
  lSuite.AddTest('TestZero', @RunTTestInt64TestZero);
  lSuite.AddTest('TestClone', @RunTTestInt64TestClone);
  lSuite.AddTest('TestMyClone', @RunTTestInt64TestMyClone);
  lSuite.AddTest('TestFormat', @RunTTestInt64TestFormat);
  lSuite:=ARegistry.AddSuite('testjsondata.TTestQword');
  lSuite.AddTest('TestPositive', @RunTTestQwordTestPositive);
  lSuite.AddTest('TestZero', @RunTTestQwordTestZero);
  lSuite.AddTest('TestClone', @RunTTestQwordTestClone);
  lSuite.AddTest('TestMyClone', @RunTTestQwordTestMyClone);
  lSuite.AddTest('TestFormat', @RunTTestQwordTestFormat);
  lSuite:=ARegistry.AddSuite('testjsondata.TTestFloat');
  lSuite.AddTest('TestPositive', @RunTTestFloatTestPositive);
  lSuite.AddTest('TestNegative', @RunTTestFloatTestNegative);
  lSuite.AddTest('TestZero', @RunTTestFloatTestZero);
  lSuite.AddTest('TestClone', @RunTTestFloatTestClone);
  lSuite.AddTest('TestMyClone', @RunTTestFloatTestMyClone);
  lSuite.AddTest('TestFormat', @RunTTestFloatTestFormat);
  lSuite:=ARegistry.AddSuite('testjsondata.TTestString');
  lSuite.AddTest('TestString', @RunTTestStringTestString);
  lSuite.AddTest('TestControlString', @RunTTestStringTestControlString);
  lSuite.AddTest('TestSolidus', @RunTTestStringTestSolidus);
  lSuite.AddTest('TestInteger', @RunTTestStringTestInteger);
  lSuite.AddTest('TestNegativeInteger', @RunTTestStringTestNegativeInteger);
  lSuite.AddTest('TestFloat', @RunTTestStringTestFloat);
  lSuite.AddTest('TestNegativeFloat', @RunTTestStringTestNegativeFloat);
  lSuite.AddTest('TestBooleanTrue', @RunTTestStringTestBooleanTrue);
  lSuite.AddTest('TestBooleanFalse', @RunTTestStringTestBooleanFalse);
  lSuite.AddTest('TestClone', @RunTTestStringTestClone);
  lSuite.AddTest('TestMyClone', @RunTTestStringTestMyClone);
  lSuite.AddTest('TestFormat', @RunTTestStringTestFormat);
  lSuite:=ARegistry.AddSuite('testjsondata.TTestArray');
  lSuite.AddTest('TestCreate', @RunTTestArrayTestCreate);
  lSuite.AddTest('TestCreateString', @RunTTestArrayTestCreateString);
  lSuite.AddTest('TestCreatePchar', @RunTTestArrayTestCreatePchar);
  lSuite.AddTest('TestCreateStrings', @RunTTestArrayTestCreateStrings);
  lSuite.AddTest('TestCreateStringsCompressed', @RunTTestArrayTestCreateStringsCompressed);
  lSuite.AddTest('TestCreateInteger', @RunTTestArrayTestCreateInteger);
  lSuite.AddTest('TestCreateInt64', @RunTTestArrayTestCreateInt64);
  lSuite.AddTest('TestCreateFloat', @RunTTestArrayTestCreateFloat);
  lSuite.AddTest('TestCreateBoolean', @RunTTestArrayTestCreateBoolean);
  lSuite.AddTest('TestCreateObject', @RunTTestArrayTestCreateObject);
  lSuite.AddTest('TestCreateJSONString', @RunTTestArrayTestCreateJSONString);
  lSuite.AddTest('TestCreateJSONStringSpecialChars', @RunTTestArrayTestCreateJSONStringSpecialChars);
  lSuite.AddTest('TestCreateJSONObject', @RunTTestArrayTestCreateJSONObject);
  lSuite.AddTest('TestCreateNilPointer', @RunTTestArrayTestCreateNilPointer);
  lSuite.AddTest('TestCreatePointer', @RunTTestArrayTestCreatePointer);
  lSuite.AddTest('TestAddInteger', @RunTTestArrayTestAddInteger);
  lSuite.AddTest('TestAddInt64', @RunTTestArrayTestAddInt64);
  lSuite.AddTest('TestAddFloat', @RunTTestArrayTestAddFloat);
  lSuite.AddTest('TestAddBooleanTrue', @RunTTestArrayTestAddBooleanTrue);
  lSuite.AddTest('TestAddBooleanFalse', @RunTTestArrayTestAddBooleanFalse);
  lSuite.AddTest('TestAddString', @RunTTestArrayTestAddString);
  lSuite.AddTest('TestAddNull', @RunTTestArrayTestAddNull);
  lSuite.AddTest('TestAddObject', @RunTTestArrayTestAddObject);
  lSuite.AddTest('TestAddArray', @RunTTestArrayTestAddArray);
  lSuite.AddTest('TestInsertInteger', @RunTTestArrayTestInsertInteger);
  lSuite.AddTest('TestInsertInt64', @RunTTestArrayTestInsertInt64);
  lSuite.AddTest('TestInsertFloat', @RunTTestArrayTestInsertFloat);
  lSuite.AddTest('TestInsertBooleanTrue', @RunTTestArrayTestInsertBooleanTrue);
  lSuite.AddTest('TestInsertBooleanFalse', @RunTTestArrayTestInsertBooleanFalse);
  lSuite.AddTest('TestInsertString', @RunTTestArrayTestInsertString);
  lSuite.AddTest('TestInsertNull', @RunTTestArrayTestInsertNull);
  lSuite.AddTest('TestInsertObject', @RunTTestArrayTestInsertObject);
  lSuite.AddTest('TestInsertArray', @RunTTestArrayTestInsertArray);
  lSuite.AddTest('TestMove', @RunTTestArrayTestMove);
  lSuite.AddTest('TestExchange', @RunTTestArrayTestExchange);
  lSuite.AddTest('TestDelete', @RunTTestArrayTestDelete);
  lSuite.AddTest('TestRemove', @RunTTestArrayTestRemove);
  lSuite.AddTest('TestClone', @RunTTestArrayTestClone);
  lSuite.AddTest('TestMyClone', @RunTTestArrayTestMyClone);
  lSuite.AddTest('TestFormat', @RunTTestArrayTestFormat);
  lSuite.AddTest('TestFormatNil', @RunTTestArrayTestFormatNil);
  lSuite:=ARegistry.AddSuite('testjsondata.TTestObject');
  lSuite.AddTest('TestCreate', @RunTTestObjectTestCreate);
  lSuite.AddTest('TestCreateString', @RunTTestObjectTestCreateString);
  lSuite.AddTest('TestCreateStringUnquoted', @RunTTestObjectTestCreateStringUnquoted);
  lSuite.AddTest('TestCreatePchar', @RunTTestObjectTestCreatePchar);
  lSuite.AddTest('TestCreatePcharUnquoted', @RunTTestObjectTestCreatePcharUnquoted);
  lSuite.AddTest('TestCreateStrings', @RunTTestObjectTestCreateStrings);
  lSuite.AddTest('TestCreateStringsCompressed', @RunTTestObjectTestCreateStringsCompressed);
  lSuite.AddTest('TestCreateStringsCompressedUnquoted', @RunTTestObjectTestCreateStringsCompressedUnquoted);
  lSuite.AddTest('TestCreateInteger', @RunTTestObjectTestCreateInteger);
  lSuite.AddTest('TestCreateIntegerUnquoted', @RunTTestObjectTestCreateIntegerUnquoted);
  lSuite.AddTest('TestCreateInt64', @RunTTestObjectTestCreateInt64);
  lSuite.AddTest('TestCreateInt64Unquoted', @RunTTestObjectTestCreateInt64Unquoted);
  lSuite.AddTest('TestCreateQWord', @RunTTestObjectTestCreateQWord);
  lSuite.AddTest('TestCreateQWordUnquoted', @RunTTestObjectTestCreateQWordUnquoted);
  lSuite.AddTest('TestCreateFloat', @RunTTestObjectTestCreateFloat);
  lSuite.AddTest('TestCreateFloatUnquoted', @RunTTestObjectTestCreateFloatUnquoted);
  lSuite.AddTest('TestCreateBoolean', @RunTTestObjectTestCreateBoolean);
  lSuite.AddTest('TestCreateBooleanUnquoted', @RunTTestObjectTestCreateBooleanUnquoted);
  lSuite.AddTest('TestCreateObject', @RunTTestObjectTestCreateObject);
  lSuite.AddTest('TestCreateJSONUnicodeString', @RunTTestObjectTestCreateJSONUnicodeString);
  lSuite.AddTest('TestCreateJSONWideString', @RunTTestObjectTestCreateJSONWideString);
  lSuite.AddTest('TestCreateJSONString', @RunTTestObjectTestCreateJSONString);
  lSuite.AddTest('TestCreateJSONStringUnquoted', @RunTTestObjectTestCreateJSONStringUnquoted);
  lSuite.AddTest('TestCreateJSONObject', @RunTTestObjectTestCreateJSONObject);
  lSuite.AddTest('TestCreateJSONObjectUnquoted', @RunTTestObjectTestCreateJSONObjectUnquoted);
  lSuite.AddTest('TestCreateNilPointer', @RunTTestObjectTestCreateNilPointer);
  lSuite.AddTest('TestCreatePointer', @RunTTestObjectTestCreatePointer);
  lSuite.AddTest('TestAddInteger', @RunTTestObjectTestAddInteger);
  lSuite.AddTest('TestAddInt64', @RunTTestObjectTestAddInt64);
  lSuite.AddTest('TestAddFloat', @RunTTestObjectTestAddFloat);
  lSuite.AddTest('TestAddBooleanTrue', @RunTTestObjectTestAddBooleanTrue);
  lSuite.AddTest('TestAddBooleanFalse', @RunTTestObjectTestAddBooleanFalse);
  lSuite.AddTest('TestAddString', @RunTTestObjectTestAddString);
  lSuite.AddTest('TestAddNull', @RunTTestObjectTestAddNull);
  lSuite.AddTest('TestAddObject', @RunTTestObjectTestAddObject);
  lSuite.AddTest('TestAddArray', @RunTTestObjectTestAddArray);
  lSuite.AddTest('TestDelete', @RunTTestObjectTestDelete);
  lSuite.AddTest('TestRemove', @RunTTestObjectTestRemove);
  lSuite.AddTest('TestClone', @RunTTestObjectTestClone);
  lSuite.AddTest('TestMyClone', @RunTTestObjectTestMyClone);
  lSuite.AddTest('TestExtract', @RunTTestObjectTestExtract);
  lSuite.AddTest('TestNonExistingAccessError', @RunTTestObjectTestNonExistingAccessError);
  lSuite.AddTest('TestFormat', @RunTTestObjectTestFormat);
  lSuite.AddTest('TestFormatNil', @RunTTestObjectTestFormatNil);
  lSuite.AddTest('TestFormatForceLF', @RunTTestObjectTestFormatForceLF);
  lSuite.AddTest('TestFind', @RunTTestObjectTestFind);
  lSuite.AddTest('TestIfFind', @RunTTestObjectTestIfFind);
  lSuite.AddTest('TestDuplicate', @RunTTestObjectTestDuplicate);
  lSuite:=ARegistry.AddSuite('testjsondata.TTestJSONPath');
  lSuite.AddTest('TestNullEmpty', @RunTTestJSONPathTestNullEmpty);
  lSuite.AddTest('TestNullGet', @RunTTestJSONPathTestNullGet);
  lSuite.AddTest('TestNullNonExisting', @RunTTestJSONPathTestNullNonExisting);
  lSuite.AddTest('TestNullNotEmpty', @RunTTestJSONPathTestNullNotEmpty);
  lSuite.AddTest('TestBooleanEmpty', @RunTTestJSONPathTestBooleanEmpty);
  lSuite.AddTest('TestBooleanNotEmpty', @RunTTestJSONPathTestBooleanNotEmpty);
  lSuite.AddTest('TestIntegerEmpty', @RunTTestJSONPathTestIntegerEmpty);
  lSuite.AddTest('TestIntegerNotEmpty', @RunTTestJSONPathTestIntegerNotEmpty);
  lSuite.AddTest('TestInt64Empty', @RunTTestJSONPathTestInt64Empty);
  lSuite.AddTest('TestInt64NotEmpty', @RunTTestJSONPathTestInt64NotEmpty);
  lSuite.AddTest('TestFloatEmpty', @RunTTestJSONPathTestFloatEmpty);
  lSuite.AddTest('TestFloatNotEmpty', @RunTTestJSONPathTestFloatNotEmpty);
  lSuite.AddTest('TestStringEmpty', @RunTTestJSONPathTestStringEmpty);
  lSuite.AddTest('TestStringNotEmpty', @RunTTestJSONPathTestStringNotEmpty);
  lSuite.AddTest('TestArrayEmpty', @RunTTestJSONPathTestArrayEmpty);
  lSuite.AddTest('TestArrayNotIndex', @RunTTestJSONPathTestArrayNotIndex);
  lSuite.AddTest('TestArrayIncompleteIndex', @RunTTestJSONPathTestArrayIncompleteIndex);
  lSuite.AddTest('TestArrayNonNumericalIndex', @RunTTestJSONPathTestArrayNonNumericalIndex);
  lSuite.AddTest('TestArrayOutOfRangeIndex', @RunTTestJSONPathTestArrayOutOfRangeIndex);
  lSuite.AddTest('TestArrayCorrectIndex', @RunTTestJSONPathTestArrayCorrectIndex);
  lSuite.AddTest('TestArrayRecursiveArray', @RunTTestJSONPathTestArrayRecursiveArray);
  lSuite.AddTest('TestArrayRecursiveObject', @RunTTestJSONPathTestArrayRecursiveObject);
  lSuite.AddTest('TestObjectEmpty', @RunTTestJSONPathTestObjectEmpty);
  lSuite.AddTest('TestObjectDots', @RunTTestJSONPathTestObjectDots);
  lSuite.AddTest('TestObjectExisting', @RunTTestJSONPathTestObjectExisting);
  lSuite.AddTest('TestObjectNonExisting', @RunTTestJSONPathTestObjectNonExisting);
  lSuite.AddTest('TestObjectTrailingDot', @RunTTestJSONPathTestObjectTrailingDot);
  lSuite.AddTest('TestObjectRecursiveArray', @RunTTestJSONPathTestObjectRecursiveArray);
  lSuite.AddTest('TestObjectRecursiveObject', @RunTTestJSONPathTestObjectRecursiveObject);
  lSuite.AddTest('TestDeepRecursive', @RunTTestJSONPathTestDeepRecursive);
  lSuite:=ARegistry.AddSuite('testjsondata.TTestFactory');
  lSuite.AddTest('TestSet', @RunTTestFactoryTestSet);
  lSuite.AddTest('TestSetInvalid', @RunTTestFactoryTestSetInvalid);
  lSuite.AddTest('CreateNull', @RunTTestFactoryCreateNull);
  lSuite.AddTest('CreateInteger', @RunTTestFactoryCreateInteger);
  lSuite.AddTest('CreateInt64', @RunTTestFactoryCreateInt64);
  lSuite.AddTest('CreateFloat', @RunTTestFactoryCreateFloat);
  lSuite.AddTest('CreateBoolean', @RunTTestFactoryCreateBoolean);
  lSuite.AddTest('CreateString', @RunTTestFactoryCreateString);
  lSuite.AddTest('CreateArray', @RunTTestFactoryCreateArray);
  lSuite.AddTest('CreateObject', @RunTTestFactoryCreateObject);
  lSuite.AddTest('ArrayAddNull', @RunTTestFactoryArrayAddNull);
  lSuite.AddTest('ArrayAddInteger', @RunTTestFactoryArrayAddInteger);
  lSuite.AddTest('ArrayAddInt64', @RunTTestFactoryArrayAddInt64);
  lSuite.AddTest('ArrayAddFloat', @RunTTestFactoryArrayAddFloat);
  lSuite.AddTest('ArrayAddBoolean', @RunTTestFactoryArrayAddBoolean);
  lSuite.AddTest('ArrayAddString', @RunTTestFactoryArrayAddString);
  lSuite.AddTest('ArrayCreateNull', @RunTTestFactoryArrayCreateNull);
  lSuite.AddTest('ArrayCreateInteger', @RunTTestFactoryArrayCreateInteger);
  lSuite.AddTest('ArrayCreateInt64', @RunTTestFactoryArrayCreateInt64);
  lSuite.AddTest('ArrayCreateFloat', @RunTTestFactoryArrayCreateFloat);
  lSuite.AddTest('ArrayCreateBoolean', @RunTTestFactoryArrayCreateBoolean);
  lSuite.AddTest('ArrayCreateString', @RunTTestFactoryArrayCreateString);
  lSuite.AddTest('ObjectAddNull', @RunTTestFactoryObjectAddNull);
  lSuite.AddTest('ObjectAddInteger', @RunTTestFactoryObjectAddInteger);
  lSuite.AddTest('ObjectAddInt64', @RunTTestFactoryObjectAddInt64);
  lSuite.AddTest('ObjectAddFloat', @RunTTestFactoryObjectAddFloat);
  lSuite.AddTest('ObjectAddBoolean', @RunTTestFactoryObjectAddBoolean);
  lSuite.AddTest('ObjectAddString', @RunTTestFactoryObjectAddString);
  lSuite.AddTest('ObjectCreateNull', @RunTTestFactoryObjectCreateNull);
  lSuite.AddTest('ObjectCreateInteger', @RunTTestFactoryObjectCreateInteger);
  lSuite.AddTest('ObjectCreateInt64', @RunTTestFactoryObjectCreateInt64);
  lSuite.AddTest('ObjectCreateFloat', @RunTTestFactoryObjectCreateFloat);
  lSuite.AddTest('ObjectCreateBoolean', @RunTTestFactoryObjectCreateBoolean);
  lSuite.AddTest('ObjectCreateString', @RunTTestFactoryObjectCreateString);
  lSuite:=ARegistry.AddSuite('testjsondata.TTestIterator');
  lSuite.AddTest('TestNull', @RunTTestIteratorTestNull);
  lSuite.AddTest('TestInteger', @RunTTestIteratorTestInteger);
  lSuite.AddTest('TestInt64', @RunTTestIteratorTestInt64);
  lSuite.AddTest('TestFloat', @RunTTestIteratorTestFloat);
  lSuite.AddTest('TestBoolean', @RunTTestIteratorTestBoolean);
  lSuite.AddTest('TestString', @RunTTestIteratorTestString);
  lSuite.AddTest('TestArray', @RunTTestIteratorTestArray);
  lSuite.AddTest('TestObject', @RunTTestIteratorTestObject);
end;

end.

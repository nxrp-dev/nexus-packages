unit testjsonrtti;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, typinfo, fpjson,
  dateutils, testcomps, testjsondata, fpjsonrtti;

type

  { TTestJSONStreamer }

  TTestJSONStreamer = class(TTestJSON)
  private
    FRJ : TJSONStreamer;
    FSR : TJSONObject;
    FToFree : TObject;
    FCalled : Boolean;
    procedure DoStreamProperty1(Sender: TObject; AObject: TObject; Info: PPropInfo; var Res: TJSONData);
  protected
    procedure SetUp; override;
    procedure TearDown; virtual;
    
    Procedure AssertPropCount(ACount : Integer);
    Function  AssertProperty(APropName : String; AType : TJSONType) : TJSONData;
    Procedure AssertProp(APropName : String; AValue : Boolean);
    Procedure AssertProp(APropName : String; AValue : Integer);
    procedure AssertProp(APropName : String; AValue: String);
    procedure AssertProp(APropName : String; AValue: TJSONFloat);
    procedure AssertProp(APropName : String; AValue : Array of String);
    procedure AssertProp(APropName : String; AValue : Array of Integer);
    function CreateVariantComp : TVariantComponent;
    procedure AssertNullProp(APropName : String);
    Function AssertObjectProp(APropName : String) : TJSONObject;
    Function AssertArrayProp(APropName : String) : TJSONArray;
    Function StreamObject(AObject : TObject) : TJSONObject;
    Property RJ : TJSONStreamer read FRJ;
    Property SR : TJSONObject Read FSR Write FSR;
  public
    procedure TestNil;
    procedure TestEmpty;
    procedure TestEmptyComponent;
    procedure TestWriteBoolean;
    procedure TestWriteInteger;
    procedure TestWriteString;
    procedure TestWriteFloat;
    procedure TestWriteFloat2;
    procedure TestWriteFloat3;
    procedure TestWriteFloat4;
    procedure TestWriteFloat5;
    procedure TestEnum1;
    procedure TestEnum2;
    Procedure TestSet1;
    Procedure TestSet2;
    Procedure TestSet3;
    Procedure TestSet4;
    Procedure TestObjectNil;
    Procedure TestComponentProp1;
    Procedure TestComponentProp2;
    Procedure TestCollectionProp1;
    Procedure TestCollectionProp2;
    Procedure TestPersistentProp1;
    Procedure TestStringsProp1;
    Procedure TestStringsProp2;
    procedure TestStringsProp3;
    procedure TestStringsProp4;
    procedure TestStringsArray;
    procedure TestStringsObject;
    procedure TestStringsStream1;
    procedure TestStringsStream2;
    procedure TestStringsStream3;
    procedure TestStringsStream4;
    procedure TestStringsStream5;
    procedure TestCollectionStream;
    procedure TestCollectionStream2;
    procedure TestOnStreamProperty;
    Procedure TestDateTimeProp;
    Procedure TestDateTimePropDefaultString;
    Procedure TestDateTimePropDefaultStringTime;
    Procedure TestDateTimeProp2;
    Procedure TestDateTimeProp3;
    procedure TestDateTimeProp4;
    procedure TestDateTimeProp5;
    procedure TestDateTimeProp6;
    procedure TestDateTimeProp7;
    Procedure TestQwordProp;

    Procedure TestVariantShortint;
    Procedure TestVariantbyte;
    Procedure TestVariantword;
    Procedure TestVariantsmallint;
    Procedure TestVariantinteger;
    Procedure TestVariantlongword;
    Procedure TestVariantint64;
    Procedure TestVariantqword;
    Procedure TestVariantsingle;
    Procedure TestVariantdouble;
    Procedure TestVariantCurrency;
    Procedure TestVariantolestr;
    Procedure TestVariantboolean;
    Procedure TestVariantDate;
    procedure TestVariantDate2;
    Procedure TestVariantArray;
    Procedure TestMultipleProps;
    Procedure TestObjectToJSONString;
    Procedure TestStringsToJSONString;
    Procedure TestCollectionToJSONString;
    procedure TestTListToJSONString;
    Procedure TestChildren;
    Procedure TestChildren2;
    Procedure TestLowercase;
  end;

  { TTestJSONDeStreamer }

  TTestJSONDeStreamer = class(TTestJSON)
  private
    FDS : TJSONDeStreamer;
    FJD : TJSONData;
    FToFree : TObject;
    procedure DeStream(JSON: TJSONStringType; AObject: TObject);
    procedure DeStream(JSON: TJSONObject; AObject: TObject);
    procedure DoDateTimeFormat;
    Procedure DoNullError;
  protected
    procedure SetUp; override;
    procedure TearDown; virtual;
    Procedure AssertVarType(Msg : String; AVarType : TVarType; Const Variant : Variant);
    Property DS : TJSONDeStreamer Read FDS;
    Property JD : TJSONData Read FJD Write FJD;
    Property Tofree : TObject Read FToFree Write FToFree;
  public
    Procedure TestVariantInteger;
    Procedure TestVariantFloat;
    Procedure TestVariantInt64;
    Procedure TestVariantBoolean;
    Procedure TestVariantNull;
    Procedure TestVariantString;
    Procedure TestVariantArray;
    procedure TestEmpty;
    procedure TestNullError;
    procedure TestNull;
    procedure TestBoolean;
    procedure TestInteger;
    procedure TestIntegerCaseInsensitive;
    procedure TestIntegerCaseSensitive;
    procedure TestString;
    procedure TestFloat;
    procedure TestFloat2;
    procedure TestFloat3;
    procedure TestFloat4;
    procedure TestFloat5;
    procedure TestDateTime;
    procedure TestDateTimeFormat;
    procedure TestEnum1;
    procedure TestEnum2;
    Procedure TestSet1;
    Procedure TestSet2;
    Procedure TestSet3;
    Procedure TestSet4;
    Procedure TestVariantProp;
    procedure TestCollection;
    procedure TestCollection2;
    procedure TestCollection3;
    procedure TestCollection4;
    procedure TestCollection5;
    procedure TestCollection6;
    procedure TestCollectionProp;
    procedure TestCollectionProp2;
    procedure TestStrings;
    procedure TestStrings2;
    procedure TestStrings3;
  end;

procedure RegistertestjsonrttiTests(ARegistry: TNXTestRegistry);

implementation

uses variants;

{ TTestJSONDeStreamer }

procedure TTestJSONDeStreamer.SetUp;
begin
  inherited SetUp;
  FDS:=TJSONDeStreamer.Create(Nil)
end;

procedure TTestJSONDeStreamer.TearDown;
begin
  FreeAndNil(FDS);
  FreeAndNil(FJD);
  FreeAndNil(FToFree);

end;

procedure TTestJSONDeStreamer.AssertVarType(Msg: String; AVarType: TVarType;
  const Variant: Variant);
begin
  TestContext.AssertTrue((VarTypeAsText(AVarType))=(VarTypeAsText(VarType(Variant))), Msg);
end;

procedure TTestJSONDeStreamer.TestVariantInteger;

Var
  V : Variant;

begin
  JD:=TJSOnIntegerNumber.Create(12);
  V:=DS.JSONToVariant(JD);
  AssertVarType('Integer data',varInteger,V);
  TestContext.AssertTrue((12)=(V), 'Integer value');
end;

procedure TTestJSONDeStreamer.TestVariantFloat;
Var
  V : Variant;

begin
  JD:=TJSOnFloatNumber.Create(1.2);
  V:=DS.JSONToVariant(JD);
  AssertVarType('Double data',varDouble,V);
  TestContext.AssertTrue((1.2)=(V), 'Float value');
end;

procedure TTestJSONDeStreamer.TestVariantInt64;
Var
  V : Variant;

begin
  JD:=TJSONInt64Number.Create(123);
  V:=DS.JSONToVariant(JD);
  AssertVarType('Int64 data',varInt64,V);
  TestContext.AssertTrue((123)=(V), 'Int64 value');
end;

procedure TTestJSONDeStreamer.TestVariantBoolean;
Var
  V : Variant;

begin
  JD:=TJSONBoolean.Create(True);
  V:=DS.JSONToVariant(JD);
  AssertVarType('Boolean data',varBoolean,V);
  TestContext.AssertTrue((True)=(V), 'Boolean value');
end;

procedure TTestJSONDeStreamer.TestVariantNull;
Var
  V : Variant;

begin
  JD:=TJSONNull.Create();
  V:=DS.JSONToVariant(JD);
  AssertVarType('Null data',varNull,V);
end;

procedure TTestJSONDeStreamer.TestVariantString;
Var
  V : Variant;
  S : String;

begin
  JD:=TJSONString.Create('A string');
  V:=DS.JSONToVariant(JD);
  AssertVarType('String data',varOleStr,V);
  S:=V;
  TestContext.AssertTrue(('A string')=(S), 'String data');
end;

procedure TTestJSONDeStreamer.TestVariantArray;
Var
  V : Variant;
begin
  JD:=TJSONArray.Create([1,2,3]);
  V:=DS.JSONToVariant(JD);
  TestContext.AssertTrue((true)=(VarIsArray(V)), 'Variant is array');
  TestContext.AssertTrue((0)=(VarArrayLowBound(V,1)), 'Lower bound is zero ');
  TestContext.AssertTrue((2)=(VarArrayHighBound(V,1)), 'Higher bound is count-1 ');
  TestContext.AssertTrue((1)=(V[0]), 'Element 0 value correct ');
  TestContext.AssertTrue((2)=(V[1]), 'Element 1 value correct ');
  TestContext.AssertTrue((3)=(V[2]), 'Element 2 value correct ');
end;

procedure TTestJSONDeStreamer.TestEmpty;
begin
  FTofree:=TComponent.Create(Nil);
  DS.JSONToObject('{}',FTofree);
  TestContext.AssertTrue(('')=(TComponent(FToFree).Name), 'Empty name');
  TestContext.AssertTrue((0)=(TComponent(FToFree).Tag), 'Empty Tag');
end;

procedure TTestJSONDeStreamer.TestNullError;

begin
  TestContext.AssertRaises(EJSON, @DoNullError, 'Null error');
end;

procedure TTestJSONDeStreamer.TestNull;
Var
  B : TBooleanComponent;

begin
  B:=TBooleanComponent.Create(Nil);
  DS.Options:=DS.Options+[jdoIgnoreNulls];
  DeStream('{ "BooleanProp" : null }',B);
  TestContext.AssertTrue((False)=(B.BooleanProp), 'Correct boolean value');
end;

procedure TTestJSONDeStreamer.DeStream(JSON : TJSONStringType; AObject : TObject);

begin
  FToFree:=AObject;
  DS.JSONToObject(JSON,FTofree);
end;

procedure TTestJSONDeStreamer.DeStream(JSON: TJSONObject; AObject: TObject);
begin
  FToFree:=AObject;
  JD:=JSON;
  DS.JSONToObject(JSON,FTofree);
end;

procedure TTestJSONDeStreamer.TestBoolean;

Var
  B : TBooleanComponent;

begin
  B:=TBooleanComponent.Create(Nil);
  DeStream('{ "BooleanProp" : true }',B);
  TestContext.AssertTrue((true)=(B.BooleanProp), 'Correct boolean value');
end;

procedure TTestJSONDeStreamer.TestInteger;

Var
  B : TIntegerComponent;

begin
  B:=TIntegerComponent.Create(Nil);
  DeStream('{ "IntProp" : 22 }',B);
  TestContext.AssertTrue((22)=(B.IntProp), 'Correct integer value');
end;

procedure TTestJSONDeStreamer.TestIntegerCaseInsensitive;

Var
  B : TIntegerComponent;

begin
  DS.Options:=DS.Options+[jdoCaseInsensitive];
  B:=TIntegerComponent.Create(Nil);
  DeStream('{ "intprop" : 22 }',B);
  TestContext.AssertTrue((22)=(B.IntProp), 'Correct integer value');
end;

procedure TTestJSONDeStreamer.TestIntegerCaseSensitive;

Var
  B : TIntegerComponent;

begin
  DS.Options:=DS.Options;
  B:=TIntegerComponent.Create(Nil);
  B.IntProp:=0;
  DeStream('{ "intprop" : 22 }',B);
  TestContext.AssertTrue((0)=(B.IntProp), 'Correct integer value not reas');
end;

procedure TTestJSONDeStreamer.TestString;

Var
  B : TStringComponent;

begin
  B:=TStringComponent.Create(Nil);
  DeStream('{ "StringProp" : "A nice string"}',B);
  TestContext.AssertTrue(('A nice string')=(B.StringProp), 'Correct string value');
end;

procedure TTestJSONDeStreamer.TestFloat;

Var
  B : TSingleComponent;

begin
  B:=TSingleComponent.Create(Nil);
  DeStream('{ "SingleProp" : 2.34 }',B);
  TestContext.AssertTrue((Single(2.34))=(B.SingleProp), 'Correct single value');
end;

procedure TTestJSONDeStreamer.TestFloat2;

Var
  B : TDoubleComponent;

begin
  B:=TDoubleComponent.Create(Nil);
  DeStream('{ "DoubleProp" : 3.45 }',B);
  TestContext.AssertTrue((Double(3.45))=(B.DoubleProp), 'Correct Double value');
end;

procedure TTestJSONDeStreamer.TestFloat3;
Var
  B : TExtendedComponent;

begin
  B:=TExtendedComponent.Create(Nil);
  DeStream('{ "ExtendedProp" : 4.56 }',B);
  TestContext.AssertTrue(Abs(4.56-B.ExtendedProp)<=1e-12, 'Correct extended value');
end;

procedure TTestJSONDeStreamer.TestFloat4;

Var
  B : TCompComponent;

begin
  B:=TCompComponent.Create(Nil);
  DeStream('{ "CompProp" : 5.67 }',B);
  TestContext.AssertTrue((round(5.67))=(B.CompProp), 'Correct comp value');
end;

procedure TTestJSONDeStreamer.TestFloat5;
Var
  B : TCurrencyComponent;

begin
  B:=TCurrencyComponent.Create(Nil);
  DeStream('{ "CurrencyProp" : 5.67 }',B);
  TestContext.AssertTrue((5.67)=(B.CurrencyProp), 'Correct string value');
end;

procedure TTestJSONDeStreamer.TestDateTime;

Var
  E : TDateTimeComponent;
  D : TDateTime;

begin
  E:=TDateTimeComponent.Create(Nil);
  D:= RecodeMillisecond(Now,0);
  DeStream('{"DateTimeProp" : "'+FormatDateTime(RFC3339DateTimeFormat,D)+'"}',E);
  TestContext.AssertTrue((D)=(E.DateTimeProp), 'Correct value');
end;

procedure TTestJSONDeStreamer.DoDateTimeFormat;

begin
  DeStream('{"DateTimeProp" : "'+DateTimeToStr(RecodeMillisecond(Now,0))+'"}',FToFree);
end;

procedure TTestJSONDeStreamer.DoNullError;
Var
  B : TBooleanComponent;

begin
  B:=TBooleanComponent.Create(Nil);
  Destream('{ "BooleanProp" : null }',B);
end;

procedure TTestJSONDeStreamer.TestDateTimeFormat;

Const
  ISO8601 = 'yyyymmdd"T"hhnnss';

Var
  E : TDateTimeComponent;
  D : TDateTime;

begin
  E:=TDateTimeComponent.Create(Nil);
  D:=RecodeMillisecond(Now,0);
  DS.DateTimeFormat:=ISO8601;
  DeStream('{"DateTimeProp" : "'+FormatDateTime(Iso8601,D)+'"}',E);
  TestContext.AssertTrue((D)=(E.DateTimeProp), 'Correct value');
  TestContext.AssertRaises(EConvertError, @DoDateTimeFormat, 'Error if  string does not correspond to specified format');
end;

procedure TTestJSONDeStreamer.TestEnum1;

Var
  E : TEnumcomponent;

begin
  E:=TEnumComponent.Create(Nil);
  DeStream('{ "Dice" : 2 }',E);
  TestContext.AssertTrue((2)=(Ord(E.Dice)), 'Correct value');
end;

procedure TTestJSONDeStreamer.TestEnum2;

Var
  E : TEnumcomponent;

begin
  E:=TEnumComponent.Create(Nil);
  DeStream('{ "Dice" : "three" }',E);
  TestContext.AssertTrue((GetEnumName(TypeInfo(TDice),Ord(Three)))=(GetEnumName(TypeInfo(TDice),Ord(E.Dice))), 'Correct value');
end;

procedure TTestJSONDeStreamer.TestSet1;

Var
  T : TSetComponent;

begin
  T:=TSetComponent.Create(Nil);
  DeStream('{ "Throw" : "one,two" }',T);
  If not (T.Throw=[one,two]) then
    TestContext.Fail('Correct value for throw');
end;

procedure TTestJSONDeStreamer.TestSet2;

Var
  T : TSetComponent;

begin
  T:=TSetComponent.Create(Nil);
  DeStream('{ "Throw" : "[one,two]" }',T);
  If not (T.Throw=[one,two]) then
    TestContext.Fail('Correct value for throw');
end;

procedure TTestJSONDeStreamer.TestSet3;

Var
  T : TSetComponent;

begin
  T:=TSetComponent.Create(Nil);
  DeStream('{ "Throw" : [ "one", "two"] }',T);
  If not (T.Throw=[one,two]) then
    TestContext.Fail('Correct value for throw');
end;

procedure TTestJSONDeStreamer.TestSet4;

Var
  T : TSetComponent;

begin
  T:=TSetComponent.Create(Nil);
  DeStream('{ "Throw" : [ 0 , 1 ] }',T);
  If not (T.Throw=[one,two]) then
    TestContext.Fail('Correct value for throw');
end;

procedure TTestJSONDeStreamer.TestVariantProp;
Var
  V : TVariantComponent;
  S : String;

begin
  V:=TVariantComponent.Create(Nil);
  DeStream('{ "VariantProp" : "A string" }',V);
  S:=V.VariantProp;
  TestContext.AssertTrue(('A string')=(S), 'Variant property value');
end;

procedure TTestJSONDeStreamer.TestCollection;

Var
  C : TTestCollection;

begin
  C:=TTestCollection.Create;
  DeStream('[ { "StrProp" : "one" }, { "StrProp" : "two" } ]',C);
  TestContext.AssertTrue((2)=(C.Count), 'Item count');
  TestContext.AssertTrue((TTestItem)=(C.Items[0].ClassType), 'Class item 0');
  TestContext.AssertTrue((TTestItem)=(C.Items[1].ClassType), 'Class item 1');
  TestContext.AssertTrue(('one')=(TTestItem(C.Items[0]).StrProp), 'Class item 0');
  TestContext.AssertTrue(('two')=(TTestItem(C.Items[1]).StrProp), 'Class item 1');
end;

procedure TTestJSONDeStreamer.TestCollection2;

Var
  C : TTestCollection;

begin
  C:=TTestCollection.Create;
  DeStream('{ "Items" : [ { "StrProp" : "one" }, { "StrProp" : "two" } ] }',C);
  TestContext.AssertTrue((2)=(C.Count), 'Item count');
  TestContext.AssertTrue((TTestItem)=(C.Items[0].ClassType), 'Class item 0');
  TestContext.AssertTrue((TTestItem)=(C.Items[1].ClassType), 'Class item 1');
  TestContext.AssertTrue(('one')=(TTestItem(C.Items[0]).StrProp), 'Class item 0');
  TestContext.AssertTrue(('two')=(TTestItem(C.Items[1]).StrProp), 'Class item 1');
end;

procedure TTestJSONDeStreamer.TestCollection3;

Var
  C : TTestCollection;

begin
  C:=TTestCollection.Create;
  FTofree:=C;
  DS.JSONToCollection('{ "Items" : [ { "StrProp" : "one" }, { "StrProp" : "two" } ] }',C);
  TestContext.AssertTrue((2)=(C.Count), 'Item count');
  TestContext.AssertTrue((TTestItem)=(C.Items[0].ClassType), 'Class item 0');
  TestContext.AssertTrue((TTestItem)=(C.Items[1].ClassType), 'Class item 1');
  TestContext.AssertTrue(('one')=(TTestItem(C.Items[0]).StrProp), 'Class item 0');
  TestContext.AssertTrue(('two')=(TTestItem(C.Items[1]).StrProp), 'Class item 1');
end;

procedure TTestJSONDeStreamer.TestCollection4;

Var
  C : TTestCollection;

begin
  C:=TTestCollection.Create;
  FTofree:=C;
  DS.JSONToCollection('[ { "StrProp" : "one" }, { "StrProp" : "two" } ]',C);
  TestContext.AssertTrue((2)=(C.Count), 'Item count');
  TestContext.AssertTrue((TTestItem)=(C.Items[0].ClassType), 'Class item 0');
  TestContext.AssertTrue((TTestItem)=(C.Items[1].ClassType), 'Class item 1');
  TestContext.AssertTrue(('one')=(TTestItem(C.Items[0]).StrProp), 'Class item 0');
  TestContext.AssertTrue(('two')=(TTestItem(C.Items[1]).StrProp), 'Class item 1');
end;

procedure TTestJSONDeStreamer.TestCollection5;

Var
  C : TTestCollection;

begin
  C:=TTestCollection.Create;
  FTofree:=C;
  JD:=TJSONArray.Create([TJSONObject.Create(['StrProp','one']),TJSONObject.Create(['StrProp','two'])]);
  DS.JSONToCollection(JD,C);
  TestContext.AssertTrue((2)=(C.Count), 'Item count');
  TestContext.AssertTrue((TTestItem)=(C.Items[0].ClassType), 'Class item 0');
  TestContext.AssertTrue((TTestItem)=(C.Items[1].ClassType), 'Class item 1');
  TestContext.AssertTrue(('one')=(TTestItem(C.Items[0]).StrProp), 'Class item 0');
  TestContext.AssertTrue(('two')=(TTestItem(C.Items[1]).StrProp), 'Class item 1');
end;

procedure TTestJSONDeStreamer.TestCollection6;
Var
  C : TTestCollection;

begin
  C:=TTestCollection.Create;
  FTofree:=C;
  JD:=TJSONObject.Create(['Items',TJSONArray.Create([TJSONObject.Create(['StrProp','one']),TJSONObject.Create(['StrProp','two'])])]);
  DS.JSONToCollection(JD,C);
  TestContext.AssertTrue((2)=(C.Count), 'Item count');
  TestContext.AssertTrue((TTestItem)=(C.Items[0].ClassType), 'Class item 0');
  TestContext.AssertTrue((TTestItem)=(C.Items[1].ClassType), 'Class item 1');
  TestContext.AssertTrue(('one')=(TTestItem(C.Items[0]).StrProp), 'Class item 0');
  TestContext.AssertTrue(('two')=(TTestItem(C.Items[1]).StrProp), 'Class item 1');
end;

procedure TTestJSONDeStreamer.TestCollectionProp;

Var
  C : TCollection;

begin
  JD:=TJSONObject.Create(['Coll',TJSONArray.Create([TJSONObject.Create(['StrProp','one']),TJSONObject.Create(['StrProp','two'])])]);
  DeStream(JD as TJSONObject,TCollectionComponent.Create(Nil));
  C:=TCollectionComponent(ToFree).Coll;
  TestContext.AssertTrue((2)=(C.Count), 'Item count');
  TestContext.AssertTrue((TTestItem)=(C.Items[0].ClassType), 'Class item 0');
  TestContext.AssertTrue((TTestItem)=(C.Items[1].ClassType), 'Class item 1');
  TestContext.AssertTrue(('one')=(TTestItem(C.Items[0]).StrProp), 'Class item 0');
  TestContext.AssertTrue(('two')=(TTestItem(C.Items[1]).StrProp), 'Class item 1');
end;

procedure TTestJSONDeStreamer.TestCollectionProp2;

Var
  C : TCollection;

begin

  DeStream('{ "Coll" : [ { "StrProp" : "one" }, { "StrProp" : "two" } ]}',TCollectionComponent.Create(Nil));
  C:=TCollectionComponent(ToFree).Coll;
  TestContext.AssertTrue((2)=(C.Count), 'Item count');
  TestContext.AssertTrue((TTestItem)=(C.Items[0].ClassType), 'Class item 0');
  TestContext.AssertTrue((TTestItem)=(C.Items[1].ClassType), 'Class item 1');
  TestContext.AssertTrue(('one')=(TTestItem(C.Items[0]).StrProp), 'Class item 0');
  TestContext.AssertTrue(('two')=(TTestItem(C.Items[1]).StrProp), 'Class item 1');
end;

procedure TTestJSONDeStreamer.TestStrings;

Var
  S : TStrings;

begin
  S:=TStringList.Create;
  FTofree:=S;
  DS.JSONToStrings('[ "one" , "two" ]',S);
  TestContext.AssertTrue((2)=(S.Count), 'Item count');
  TestContext.AssertTrue(('one')=(S[0]), 'First item');
  TestContext.AssertTrue(('two')=(S[1]), 'First item');
end;

procedure TTestJSONDeStreamer.TestStrings2;

Var
  S : TStrings;

begin
  S:=TStringList.Create;
  FTofree:=S;
  DS.JSONToStrings('{ "Strings" : [ "one" , "two" ] }',S);
  TestContext.AssertTrue((2)=(S.Count), 'Item count');
  TestContext.AssertTrue(('one')=(S[0]), 'First item');
  TestContext.AssertTrue(('two')=(S[1]), 'First item');
end;

procedure TTestJSONDeStreamer.TestStrings3;
Var
  S : TStrings;

begin
  S:=TStringList.Create;
  FTofree:=S;
  DS.JSONToStrings('{ "Strings" : [ "one" , "two" ] }',S);
  TestContext.AssertTrue((2)=(S.Count), 'Item count');
  TestContext.AssertTrue(('one')=(S[0]), 'First item');
  TestContext.AssertTrue(('two')=(S[1]), 'First item');
end;

{ TTestJSONStreamer }

function TTestJSONStreamer.StreamObject(AObject: TObject): TJSONObject;
begin
  FToFree:=AObject;
  FSR:=FRJ.ObjectToJSON(AObject);
  Result:=FSR;
end;

procedure TTestJSONStreamer.DoStreamProperty1(Sender: TObject; AObject: TObject;
  Info: PPropInfo; var Res: TJSONData);
begin
  If (info^.name<>'IntProp') and (info^.name<>'Name') and (info^.name<>'Tag') then
    TestContext.Fail('Wrong property');
  If (info^.name='IntProp') then
    FreeAndNil(Res);
  FCalled:=true;
end;

procedure TTestJSONStreamer.SetUp;
begin
  Inherited;
  FRJ:=TJSONStreamer.Create(Nil);
end;

procedure TTestJSONStreamer.TearDown;
begin
  FreeAndNil(FSR);
  FreeAndNil(FRJ);
  FreeAndNil(FToFree);

end;



procedure TTestJSONStreamer.AssertPropCount(ACount: Integer);
begin
  TestContext.AssertTrue((FSR)<>nil, 'Result of streaming available');
  If FToFree is TComponent then
    ACount:=ACount+2; // Tag + Name
  // Writeln(FSR.ASJSON);
  TestContext.AssertTrue((ACount)=(FSR.Count), 'Property count correct');
end;

function TTestJSONStreamer.AssertProperty(APropName: String; AType: TJSONType
  ): TJSONData;

Var
  i : Integer;

begin
  I:=FSR.IndexOfName(APropName);
  If (I=-1) then
    TestContext.Fail('No property "'+APropName+'" available');
  Result:=FSR.Items[i];
  TestContext.AssertTrue((GetEnumName(TypeInfo(TJSONType),Ord(AType)))=(GetEnumName(TypeInfo(TJSONType),Ord(Result.JSONType))), 'Property "'+APropName+'" has correct type');
end;

procedure TTestJSONStreamer.AssertProp(APropName: String; AValue: Boolean);
begin
  TestContext.AssertTrue((FSR)<>nil, 'Result of streaming available');
  TestContext.AssertTrue((TJSONObject)=(FSR.ClassType), 'Result of streaming is TJSONObject');
  TestContext.AssertTrue((AValue)=(AssertProperty(APropName,jtBoolean).AsBoolean), 'Correct value');
end;

procedure TTestJSONStreamer.AssertProp(APropName: String; AValue: Integer);
begin
  TestContext.AssertTrue((FSR)<>nil, 'Result of streaming available');
  TestContext.AssertTrue((TJSONObject)=(FSR.ClassType), 'Result of streaming is TJSONObject');
  TestContext.AssertTrue((AValue)=(AssertProperty(APropName,jtNumber).AsInteger), 'Correct value');
end;

procedure TTestJSONStreamer.AssertProp(APropName: String; AValue: String);
begin
  TestContext.AssertTrue((FSR)<>nil, 'Result of streaming available');
  TestContext.AssertTrue((TJSONObject)=(FSR.ClassType), 'Result of streaming is TJSONObject');
  TestContext.AssertTrue((AValue)=(AssertProperty(APropName,jtString).AsString), 'Correct value');
end;

procedure TTestJSONStreamer.AssertProp(APropName: String; AValue: TJSONFloat);
begin
  TestContext.AssertTrue((FSR)<>nil, 'Result of streaming available');
  TestContext.AssertTrue((TJSONObject)=(FSR.ClassType), 'Result of streaming is TJSONObject');
  TestContext.AssertTrue(Abs(AValue-AssertProperty(APropName,jtNumber).AsFloat)<=1e-6, 'Correct value');
end;

procedure TTestJSONStreamer.AssertProp(APropName: String; AValue: array of String
  );
Var
  a : TJSONArray;
  i : integer;

begin
  a:=AssertArrayProp(APropName);
  TestContext.AssertTrue((Length(AValue))=(A.Count), 'Correct count ');
  For I:=Low(AValue) to High(Avalue) do
    begin
    TestContext.AssertTrue((jtString)=(A.Types[i]), 'Array element type');
    TestContext.AssertTrue((AValue[i])=(A.strings[i]), 'Array value');
    end;
end;

procedure TTestJSONStreamer.AssertProp(APropName: String; AValue: array of Integer
  );
Var
  a : TJSONArray;
  i : integer;

begin
  a:=AssertArrayProp(APropName);
  For I:=Low(AValue) to High(Avalue) do
    begin
    TestContext.AssertTrue((jtNumber)=(A.Types[i]), 'Array element type');
    TestContext.AssertTrue((AValue[i])=(A.Integers[i]), 'Array value');
    end;
end;

function TTestJSONStreamer.CreateVariantComp: TVariantComponent;
begin
  Result:=TVariantComponent.Create(Nil);
  FTofree:=Result;
end;

procedure TTestJSONStreamer.AssertNullProp(APropName: String);
begin
  AssertProperty(APropName,jtNull);
end;

function TTestJSONStreamer.AssertObjectProp(APropName: String): TJSONObject;
begin
  Result:=AssertProperty(APropName,jtObject) as TJSONObject;
end;

function TTestJSONStreamer.AssertArrayProp(APropName: String): TJSONArray;
begin
  Result:=AssertProperty(APropName,jtArray) as TJSONArray;
end;

procedure TTestJSONStreamer.TestNil;
begin
  TestContext.AssertTrue((StreamObject(Nil))=nil, 'Nil returns nil');
end;

procedure TTestJSONStreamer.TestEmpty;
begin
  StreamObject(TemptyPersistent.Create);
  AssertPropCount(0);
end;

procedure TTestJSONStreamer.TestEmptyComponent;
begin
  StreamObject(TComponent.Create(nil));
  AssertPropCount(0);
end;

procedure TTestJSONStreamer.TestWriteBoolean;

begin
  StreamObject(TBooleanComponent.Create(nil));
  AssertPropCount(1);
  AssertProp('BooleanProp',False);
end;

procedure TTestJSONStreamer.TestWriteInteger;
begin
  StreamObject(TIntegerComponent.Create(Nil));
  AssertPropCount(1);
  AssertProp('IntProp',3);
end;

procedure TTestJSONStreamer.TestWriteString;
begin
  StreamObject(TStringComponent.Create(Nil));
  AssertPropCount(1);
  AssertProp('StringProp','A string');
end;

procedure TTestJSONStreamer.TestWriteFloat;
begin
  StreamObject(TSingleComponent.Create(Nil));
  AssertPropCount(1);
  AssertProp('SingleProp',1.23);
end;

procedure TTestJSONStreamer.TestWriteFloat2;
begin
  StreamObject(TDoubleComponent.Create(Nil));
  AssertPropCount(1);
  AssertProp('DoubleProp',2.34);
end;

procedure TTestJSONStreamer.TestWriteFloat3;
begin
  StreamObject(TExtendedComponent.Create(Nil));
  AssertPropCount(1);
  AssertProp('ExtendedProp',3.45);
end;

procedure TTestJSONStreamer.TestWriteFloat4;
begin
  StreamObject(TCompComponent.Create(Nil));
  AssertPropCount(1);
  AssertProp('CompProp',5);
end;

procedure TTestJSONStreamer.TestWriteFloat5;
begin
  StreamObject(TCurrencyComponent.Create(Nil));
  AssertPropCount(1);
  AssertProp('CurrencyProp',5.67);
end;

procedure TTestJSONStreamer.TestEnum1;
begin
  StreamObject(TEnumComponent3.Create(Nil));
  AssertPropCount(1);
  AssertProp('Dice',GetEnumName(TypeInfo(TDice),Ord(three)));
end;

procedure TTestJSONStreamer.TestEnum2;
begin
  RJ.Options:=[jsoEnumeratedAsInteger];
  StreamObject(TEnumComponent3.Create(Nil));
  AssertProp('Dice',Ord(three));
end;

procedure TTestJSONStreamer.TestSet1;
begin
  StreamObject(TSetComponent.Create(Nil));
  AssertPropCount(1);
  AssertProp('Throw',['two','five']);
end;

procedure TTestJSONStreamer.TestSet2;
begin
  RJ.Options:=[jsoSetAsString];
  StreamObject(TSetComponent.Create(Nil));
  AssertPropCount(1);
  AssertProp('Throw','two,five');
end;

procedure TTestJSONStreamer.TestSet3;
begin
  RJ.Options:=[jsoSetAsString,jsoSetBrackets];
  StreamObject(TSetComponent.Create(Nil));
  AssertPropCount(1);
  AssertProp('Throw','[two,five]');
end;

procedure TTestJSONStreamer.TestSet4;
begin
  RJ.Options:=[jsoSetEnumeratedAsInteger];
  StreamObject(TSetComponent.Create(Nil));
  AssertPropCount(1);
  AssertProp('Throw',[Ord(two),Ord(five)]);
end;

procedure TTestJSONStreamer.TestObjectNil;

Var
  P : TOwnedComponent;

begin
  P:=TOwnedComponent.Create(Nil);
  P.CompProp.Free;
  P.CompProp:=Nil;
  StreamObject(P);
  AssertPropCount(1);
  AssertNullProp('CompProp');
end;

procedure TTestJSONStreamer.TestComponentProp1;
begin
  StreamObject(TOwnedComponent.Create(Nil));
  AssertPropCount(1);
  AssertProp('CompProp','SubComponent');
end;

procedure TTestJSONStreamer.TestComponentProp2;

Var
  C : TOwnedComponent;
  F : TJSONObject;

begin
  RJ.Options:=[jsoComponentsInline];
  C:=TOwnedComponent.Create(Nil);
  StreamObject(C);
  AssertPropCount(1);
  F:=SR;
  try
    SR:=AssertObjectProp('CompProp');
    AssertPropCount(1);
    AssertProp('Name','SubComponent');
    Assertprop('Tag',0);
    AssertProp('IntProp',3);
  finally
    SR:=F;
  end;
end;

procedure TTestJSONStreamer.TestCollectionProp1;

Var
  C : TCollectionComponent;
  F : TJSONObject;
  A : TJSONArray;

begin
  C:=TCollectionComponent2.Create(Nil);
  StreamObject(C);
  AssertPropCount(1);
  F:=SR;
  try
    A:=AssertArrayProp('Coll');
    TestContext.AssertTrue((3)=(A.Count), 'Collection item cound');
    TestContext.AssertTrue((jtObject)=(A.Types[0]), 'Item 0 is object');
    SR:=A.Objects[0];
    FToFree:=SR;
    AssertPropCount(1);
    AssertProp('StrProp','First');
    TestContext.AssertTrue((jtObject)=(A.Types[1]), 'Item 1 is object');
    SR:=A.Objects[1];
    FToFree:=SR;
    AssertPropCount(1);
    AssertProp('StrProp','Second');
    TestContext.AssertTrue((jtObject)=(A.Types[2]), 'Item 2 is object');
    SR:=A.Objects[2];
    FToFree:=SR;
    AssertPropCount(1);
    AssertProp('StrProp','Third');
  finally
    SR:=F;
    FToFree:=C;
  end;
end;

procedure TTestJSONStreamer.TestCollectionProp2;

Var
  C : TCollectionComponent;
  A : TJSONArray;

begin
  C:=TCollectionComponent.Create(Nil);
  StreamObject(C);
  AssertPropCount (1);
  A:=AssertArrayProp('Coll');
  TestContext.AssertTrue((0)=(A.Count), 'Collection item count');
end;

procedure TTestJSONStreamer.TestPersistentProp1;

var
  P : TPersistentComponent;
  F : TJSONObject;

begin
  P:=TPersistentComponent.Create(Nil);
  StreamObject(P);
  AssertPropCount(1);
  F:=SR;
  try
    SR:=AssertObjectProp('Persist');
    FToFree:=P.Persist;
    AssertPropCount(2);
    AssertProp('AString','A persistent string');
    AssertProp('AInteger',3);
  finally
    FToFree:=P;
    SR:=F;
  end;
end;

procedure TTestJSONStreamer.TestStringsProp1;

begin
  RJ.Options:=[jsoTstringsAsArray];
  StreamObject(TStringsCOmponent.Create(Nil));
  AssertPropCount(1);
  AssertProp('StringsProp',['One','Two','Three']);
end;

procedure TTestJSONStreamer.TestStringsProp2;

begin
  StreamObject(TStringsCOmponent.Create(Nil));
  AssertPropCount(1);
  AssertProp('StringsProp','One'+sLineBreak+'Two'+sLineBreak+'Three'+sLineBreak);
end;

procedure TTestJSONStreamer.TestStringsProp3;

Var
  O : TJSONObject;
  S : TStringsComponent;

begin
  S:=TStringsCOmponent.Create(Nil);
  RJ.Options:=[jsoTstringsAsObject];
  StreamObject(S);
  AssertPropCount(1);
  O:=SR;
  SR:=AssertObjectprop('StringsProp');
  FTofree:=Nil;
  try
    AssertNullProp('One');
    AssertNullProp('Two');
    AssertNullProp('Three');
  finally
    SR:=o;
    FToFree:=S;
  end;
end;

procedure TTestJSONStreamer.TestStringsProp4;

Var
  O,SP : TJSONObject;
  S : TStringsComponent;

begin
  S:=TStringsCOmponent.Create(Nil);
  S.StringsProp.Objects[0]:=TEmptyPersistent.Create;
  S.StringsProp.Objects[1]:=TEmptyPersistent.Create;
  S.StringsProp.Objects[2]:=TEmptyPersistent.Create;
  try
    RJ.Options:=[jsoTstringsAsObject];
    StreamObject(S);
    AssertPropCount(1);
    O:=SR;
    SP:=AssertObjectprop('StringsProp');
    SR:=SP;
    FTofree:=Nil;
    try
      SR:=AssertObjectProp('One');
      AssertPropCount(0);
      SR:=SP;
      SR:=AssertObjectProp('Two');
      AssertPropCount(0);
      SR:=SP;
      SR:=AssertObjectProp('Three');
      AssertPropCount(0);
    finally
      SR:=o;
      FToFree:=S;
    end;
  finally
    S.StringsProp.Objects[0].Free;
    S.StringsProp.Objects[1].Free;
    S.StringsProp.Objects[2].Free;
  end;
end;

procedure TTestJSONStreamer.TestStringsArray;

Var
  O : TJSONArray;
  S : TStringList;

begin
  S:=TStringList.create;
  try
    S.Add('one');
    O:=RJ.StreamTStringsArray(S);
    try
      TestContext.AssertTrue((1)=(O.Count), 'one element');
      TestContext.AssertTrue((jtString)=(O.Types[0]), 'string type');
      TestContext.AssertTrue(('one')=(O.Strings[0]), 'string value');
    finally
      FreeAndNil(O);
    end;
  finally
    S.Free;
  end;
end;

procedure TTestJSONStreamer.TestStringsObject;

Var
  O : TJSONObject;
  S : TStringList;

begin
  S:=TStringList.create;
  try
    S.AddObject('one',TEmptyPersistent.Create);
    O:=RJ.StreamTStringsObject(S);
    try
      TestContext.AssertTrue((1)=(O.Count), 'one element');
      TestContext.AssertTrue((0)=(O.IndexOfName('one')), 'Have property');
      TestContext.AssertTrue((jtObject)=(O.Types['one']), 'string type');
      TestContext.AssertTrue(('one')=(O.Names[0]), 'string value');
    finally
      FreeAndNil(O);
    end;
  finally
    S.Objects[0].FRee;
    S.Free;
  end;
end;

procedure TTestJSONStreamer.TestStringsStream1;

Var
  D: TJSONData;
  O : TJSONArray;
  S : TStringList;

begin
  S:=TStringList.create;
  try
    S.Add('one');
    RJ.Options:=[jsoTstringsAsArray];
    D:=RJ.StreamTStrings(S);
    try
      TestContext.AssertTrue((jtArray)=(D.JSONType), 'Correct type');
      O:=D as TJSONArray;
      TestContext.AssertTrue((1)=(O.Count), 'one element');
      TestContext.AssertTrue((jtString)=(O.Types[0]), 'string type');
      TestContext.AssertTrue(('one')=(O.Strings[0]), 'string value');
    finally
      FreeAndNil(O);
    end;
  finally
    S.Free;
  end;
end;

procedure TTestJSONStreamer.TestStringsStream2;

Var
  D : TJSONData;
  O : TJSONObject;
  S : TStringList;

begin
  S:=TStringList.create;
  try
    S.AddObject('one',TEmptyPersistent.Create);
    RJ.Options:=[jsoTstringsAsObject];
    D:=RJ.StreamTstrings(S);
    try
      TestContext.AssertTrue((jtObject)=(D.JSONType), 'Correct type');
      O:=D as TJSONObject;
      TestContext.AssertTrue((1)=(O.Count), 'one element');
      TestContext.AssertTrue((0)=(O.IndexOfName('one')), 'Have property');
      TestContext.AssertTrue((jtObject)=(O.Types['one']), 'string type');
      TestContext.AssertTrue(('one')=(O.Names[0]), 'string value');
    finally
      SR:=O;
    end;
  finally
    S.Objects[0].FRee;
    S.Free;
  end;
end;

procedure TTestJSONStreamer.TestStringsStream3;
Var
  O : TJSONObject;
  S : TStringList;

begin
  S:=TStringList.create;
  try
    S.AddObject('one',TEmptyPersistent.Create);
    RJ.Options:=[jsoTstringsAsObject];
    SR:=RJ.ObjectToJSON(S);
    O:=AssertObjectProp('Strings');
    TestContext.AssertTrue((1)=(O.Count), 'one element');
    TestContext.AssertTrue((0)=(O.IndexOfName('one')), 'Have property');
    TestContext.AssertTrue((jtObject)=(O.Types['one']), 'string type');
    TestContext.AssertTrue(('one')=(O.Names[0]), 'string value');
  finally
    S.Objects[0].FRee;
    S.Free;
  end;
end;

procedure TTestJSONStreamer.TestStringsStream4;
Var
  S : TStringList;

begin
  S:=TStringList.create;
  try
    S.AddObject('one',TEmptyPersistent.Create);
    SR:=RJ.ObjectToJSON(S);
    AssertProp('Strings','one'+sLinebreak);
  finally
    S.Objects[0].FRee;
    S.Free;
  end;
end;

procedure TTestJSONStreamer.TestStringsStream5;
Var
  D : TJSONData;
  S : TStringList;

begin
  S:=TStringList.create;
  try
    S.AddObject('one',TEmptyPersistent.Create);
    D:=RJ.StreamTstrings(S);
    try
      TestContext.AssertTrue((jtString)=(D.JSONType), 'String data');
      TestContext.AssertTrue(('one'+sLineBreak)=(D.AsString), 'String value');
    finally
      D.free;
    end;
  finally
    S.Objects[0].FRee;
    S.Free;
  end;
end;

procedure TTestJSONStreamer.TestCollectionStream;

Var
  C : TTestCollection;
  A : TJSONArray;

begin
  C:=TTestCollection.Create;
  FToFree:=C;
  TTestItem(C.Add).StrProp:='One';
  TTestItem(C.Add).StrProp:='Two';
  A:=RJ.StreamCollection(C);
  try
    TestContext.AssertTrue((A)<>nil, 'Have result');
    TestContext.AssertTrue((2)=(A.Count), '2 items');
    TestContext.AssertTrue((jtObject)=(A.Types[0]), 'Type item 0,');
    TestContext.AssertTrue((jtObject)=(A.Types[1]), 'Type item 1,');
    SR:=A.Objects[0];
    AssertPropCount(1);
    AssertProp('StrProp','One');
    SR:=A.Objects[1];
    AssertPropCount(1);
    AssertProp('StrProp','Two');
    SR:=Nil;
  finally
    FreeAndNil(A);
  end;
end;

procedure TTestJSONStreamer.TestCollectionStream2;

Var
  C : TTestCollection;
  A : TJSONArray;
  o : TJSONObject;

begin
  C:=TTestCollection.Create;
  TTestItem(C.Add).StrProp:='One';
  TTestItem(C.Add).StrProp:='Two';
  FToFree:=C;
  StreamObject(C);
  O:=SR;
  try
    A:=AssertProperty('Items',jtArray) as TJSONArray;
    TestContext.AssertTrue((A)<>nil, 'Have result');
    TestContext.AssertTrue((2)=(A.Count), '2 items');
    TestContext.AssertTrue((jtObject)=(A.Types[0]), 'Type item 0,');
    TestContext.AssertTrue((jtObject)=(A.Types[1]), 'Type item 1,');
    SR:=A.Objects[0];
    AssertPropCount(1);
    AssertProp('StrProp','One');
    SR:=A.Objects[1];
    AssertPropCount(1);
    AssertProp('StrProp','Two');
    SR:=Nil;
  finally
    SR:=O;
  end;
end;

procedure TTestJSONStreamer.TestOnStreamProperty;
begin
  RJ.OnStreamProperty:=@DoStreamProperty1;
  StreamObject(TIntegerComponent.Create(Nil));
  AssertPropCount(0);
end;

procedure TTestJSONStreamer.TestDateTimeProp;

Var
  D : Double;
begin
  StreamObject(TDateTimeComponent.Create(Nil));
  D:=EncodeDate(1996,8,1);
  AssertPropCount(1);
  AssertProp('DateTimeProp',D);
end;

procedure TTestJSONStreamer.TestDateTimePropDefaultString;

Var
  D : Double;
begin
  RJ.Options:=[jsoDateTimeAsString];
  StreamObject(TDateTimeComponent.Create(Nil));
  D:=EncodeDate(1996,8,1);
  AssertPropCount(1);
  AssertProp('DateTimeProp',FormatDateTime(RFC3339DateTimeFormat,D));
end;

procedure TTestJSONStreamer.TestDateTimePropDefaultStringTime;
Var
  D : Double;
begin
  RJ.Options:=[jsoDateTimeAsString];
  StreamObject(TDateTimeComponent3.Create(Nil));
  D:=EncodeDate(1996,8,1)+EncodeTime(23,20,0,0);
  AssertPropCount(1);
  AssertProp('DateTimeProp',FormatDateTime(RFC3339DateTimeFormat,D));
end;

procedure TTestJSONStreamer.TestDateTimeProp2;
Var
  D : Double;
begin
  StreamObject(TDateTimeComponent2.Create(Nil));
  D:=EncodeTime(23,20,0,0);
  AssertPropCount(1);
  AssertProp('DateTimeProp',D);
end;

procedure TTestJSONStreamer.TestDateTimeProp3;
Var
  D : Double;
begin
  StreamObject(TDateTimeComponent3.Create(Nil));
  D:=EncodeDate(1996,8,1)+EncodeTime(23,20,0,0);
  AssertPropCount(1);
  AssertProp('DateTimeProp',D);
end;

procedure TTestJSONStreamer.TestDateTimeProp4;

begin
  RJ.Options:=[jsoDateTimeAsString,jsoLegacyDateTime];
  StreamObject(TDateTimeComponent.Create(Nil));
  AssertPropCount(1);
  AssertProp('DateTimeProp',DateToStr(EncodeDate(1996,8,1)));
end;

procedure TTestJSONStreamer.TestDateTimeProp5;

begin
  RJ.Options:=[jsoDateTimeAsString,jsoLegacyDateTime];
  StreamObject(TDateTimeComponent2.Create(Nil));
  AssertPropCount(1);
  AssertProp('DateTimeProp',TimeToStr(EncodeTime(23,20,0,0)));
end;

procedure TTestJSONStreamer.TestDateTimeProp6;

begin
  RJ.Options:=[jsoDateTimeAsString,jsoLegacyDateTime];
  StreamObject(TDateTimeComponent3.Create(Nil));
  AssertPropCount(1);
  AssertProp('DateTimeProp',DateTimeToStr(EncodeDate(1996,8,1)+EncodeTime(23,20,0,0)));
end;

procedure TTestJSONStreamer.TestDateTimeProp7;
begin
  RJ.Options:=[jsoDateTimeAsString];
  RJ.DateTimeFormat:='hh:nn';
  StreamObject(TDateTimeComponent3.Create(Nil));
  AssertPropCount(1);
  AssertProp('DateTimeProp',FormatDateTime('hh:nn',EncodeDate(1996,8,1)+EncodeTime(23,20,0,0)));
end;

procedure TTestJSONStreamer.TestQwordProp;
var
  D : TJSONObject;
  V : TJSONData;
  Obj : TQWordObj;
begin
  Obj := TQWordObj.Create;
  Obj.Value := High(QWord);
  D:=StreamObject(Obj);
  V := D.Find('Value');
  TestContext.AssertTrue(('TJSONQWordNumber')=(V.ClassName), 'Max QWord type');
  TestContext.AssertTrue((High(QWord))=(V.AsQWord), 'Max QWord');
end;

procedure TTestJSONStreamer.TestVariantShortint;

Var
  i : ShortInt;
  C : TVariantComponent;

begin
  i:=3;
  C:=CreateVariantComp;
  C.VariantProp:=i;
  TestContext.AssertTrue((VarTypeAsText(varshortint))=(VarTypeAsText(VarType(C.VariantProp))), 'Variant type');
  StreamObject(FTofree);
  AssertPropCount(1);
  AssertProp('VariantProp',3);
end;

procedure TTestJSONStreamer.TestVariantbyte;
Var
  i : Byte;
  C : TVariantComponent;

begin
  i:=3;
  C:=CreateVariantComp;
  C.VariantProp:=i;
  TestContext.AssertTrue((VarTypeAsText(varByte))=(VarTypeAsText(VarType(C.VariantProp))), 'Variant type');
  StreamObject(FTofree);
  AssertPropCount(1);
  AssertProp('VariantProp',3);
end;

procedure TTestJSONStreamer.TestVariantword;

Var
  i : Word;
  C : TVariantComponent;

begin
  i:=3;
  C:=CreateVariantComp;
  C.VariantProp:=i;
  TestContext.AssertTrue((VarTypeAsText(varWord))=(VarTypeAsText(VarType(C.VariantProp))), 'Variant type');
  StreamObject(FTofree);
  AssertPropCount(1);
  AssertProp('VariantProp',3);
end;

procedure TTestJSONStreamer.TestVariantsmallint;

Var
  i : Smallint;
  C : TVariantComponent;

begin
  i:=3;
  C:=CreateVariantComp;
  C.VariantProp:=i;
  TestContext.AssertTrue((VarTypeAsText(varSmallint))=(VarTypeAsText(VarType(C.VariantProp))), 'Variant type');
  StreamObject(FTofree);
  AssertPropCount(1);
  AssertProp('VariantProp',3);
end;

procedure TTestJSONStreamer.TestVariantinteger;
Var
  i : Integer;
  C : TVariantComponent;

begin
  i:=3;
  C:=CreateVariantComp;
  C.VariantProp:=i;
  TestContext.AssertTrue((VarTypeAsText(varInteger))=(VarTypeAsText(VarType(C.VariantProp))), 'Variant type');
  StreamObject(FTofree);
  AssertPropCount(1);
  AssertProp('VariantProp',3);
end;

procedure TTestJSONStreamer.TestVariantlongword;

Var
  i : Cardinal;
  C : TVariantComponent;

begin
  i:=3;
  C:=CreateVariantComp;
  C.VariantProp:=i;
  TestContext.AssertTrue((VarTypeAsText(varLongword))=(VarTypeAsText(VarType(C.VariantProp))), 'Variant type');
  StreamObject(FTofree);
  AssertPropCount(1);
  AssertProp('VariantProp',3);
end;

procedure TTestJSONStreamer.TestVariantint64;
Var
  i : Int64;
  C : TVariantComponent;

begin
  i:=3;
  C:=CreateVariantComp;
  C.VariantProp:=i;
  TestContext.AssertTrue((VarTypeAsText(varInt64))=(VarTypeAsText(VarType(C.VariantProp))), 'Variant type');
  StreamObject(FTofree);
  AssertPropCount(1);
  AssertProp('VariantProp',3);
end;

procedure TTestJSONStreamer.TestVariantqword;
Var
  i : QWord;
  C : TVariantComponent;

begin
  i:=3;
  C:=CreateVariantComp;
  C.VariantProp:=i;
  TestContext.AssertTrue((VarTypeAsText(varQWord))=(VarTypeAsText(VarType(C.VariantProp))), 'Variant type');
  StreamObject(FTofree);
  AssertPropCount(1);
  AssertProp('VariantProp',3);
end;

procedure TTestJSONStreamer.TestVariantsingle;
Var
  i : Single;
  C : TVariantComponent;

begin
  i:=3.14;
  C:=CreateVariantComp;
  C.VariantProp:=VarAsType(3.14,varSingle);
  TestContext.AssertTrue((VarTypeAsText(varSingle))=(VarTypeAsText(VarType(C.VariantProp))), 'Variant type');
  StreamObject(FTofree);
  AssertPropCount(1);
  AssertProp('VariantProp',i);
end;

procedure TTestJSONStreamer.TestVariantdouble;

Var
  i : Double;
  C : TVariantComponent;

begin
  i:=3.14;
  C:=CreateVariantComp;
  C.VariantProp:=i;
  TestContext.AssertTrue((VarTypeAsText(varDouble))=(VarTypeAsText(VarType(C.VariantProp))), 'Variant type');
  StreamObject(FTofree);
  AssertPropCount(1);
  AssertProp('VariantProp',3.14);
end;

procedure TTestJSONStreamer.TestVariantCurrency;
Var
  i : Currency;
  C : TVariantComponent;

begin
  i:=3.14;
  C:=CreateVariantComp;
  C.VariantProp:=i;
  TestContext.AssertTrue((VarTypeAsText(varCurrency))=(VarTypeAsText(VarType(C.VariantProp))), 'Variant type');
  StreamObject(FTofree);
  AssertPropCount(1);
  AssertProp('VariantProp',3.14);
end;

procedure TTestJSONStreamer.TestVariantolestr;

Var
  i : String;
  C : TVariantComponent;

begin
  i:='3.14';
  C:=CreateVariantComp;
  C.VariantProp:=VarAsType(i,varOleStr);
  TestContext.AssertTrue((VarTypeAsText(varOleStr))=(VarTypeAsText(VarType(C.VariantProp))), 'Variant type');
  StreamObject(FTofree);
  AssertPropCount(1);
  AssertProp('VariantProp','3.14');
end;

procedure TTestJSONStreamer.TestVariantboolean;
Var
  i : Boolean;
  C : TVariantComponent;

begin
  i:=True;
  C:=CreateVariantComp;
  C.VariantProp:=i;
  TestContext.AssertTrue((VarTypeAsText(varBoolean))=(VarTypeAsText(VarType(C.VariantProp))), 'Variant type');
  StreamObject(FTofree);
  AssertPropCount(1);
  AssertProp('VariantProp',True);
end;

procedure TTestJSONStreamer.TestVariantDate;

Var
  i : TDateTime;
  C : TVariantComponent;

begin
  i:=EncodeDate(2010,12,23);
  C:=CreateVariantComp;
  C.VariantProp:=i;
  TestContext.AssertTrue((VarTypeAsText(varDate))=(VarTypeAsText(VarType(C.VariantProp))), 'Variant type');
  StreamObject(FTofree);
  AssertPropCount(1);
  AssertProp('VariantProp',EncodeDate(2010,12,23));
end;

procedure TTestJSONStreamer.TestVariantDate2;

Var
  i : TDateTime;
  C : TVariantComponent;

begin
  RJ.Options:=[jsoDateTimeAsString,jsoLegacyDateTime];
  i:=EncodeDate(2010,12,23);
  C:=CreateVariantComp;
  C.VariantProp:=i;
  TestContext.AssertTrue((VarTypeAsText(varDate))=(VarTypeAsText(VarType(C.VariantProp))), 'Variant type');
  StreamObject(FTofree);
  AssertPropCount(1);
  AssertProp('VariantProp',DateToStr(EncodeDate(2010,12,23)));
end;

procedure TTestJSONStreamer.TestVariantArray;
Var
  i : Integer;
  V : Variant;
  C : TVariantComponent;
  A : TJSONArray;

begin
  V:=VarArrayCreate([1,10],varInteger);
  For I:=1 to 10 do
    V[i]:=11-I;
  C:=CreateVariantComp;
  C.VariantProp:=V;
  StreamObject(FTofree);
  AssertPropCount(1);
  A:=AssertProperty('VariantProp',jtArray) as TJSONArray;
  TestContext.AssertTrue((10)=(A.Count), '10 elements in array');
  For I:=1 to 10 do
    begin
    TestContext.AssertTrue((jtNumber)=(A.Types[i-1]), 'Type of element');
    TestContext.AssertTrue((11-i)=(A.Integers[i-1]), 'Value of element');
    end;
end;

procedure TTestJSONStreamer.TestMultipleProps;
begin
  StreamObject(TMultipleComponent.Create(Nil));
  AssertPropCount(5);
  AssertProp('IntProp',1);
  Assertprop('StringProp','A String');
  AssertProp('CurrencyProp',2.3);
  AssertProp('Throw',['three','four']);
  AssertProp('Dice','two');
end;

procedure TTestJSONStreamer.TestObjectToJSONString;
begin
  StreamObject(TIntegerComponent.Create(Nil));
  TestContext.AssertTrue((SR.AsJSON)=(RJ.ObjectToJSONString(FToFree)), 'Correct stream');
end;

procedure TTestJSONStreamer.TestStringsToJSONString;
Var
  S : TStrings;
begin
  S:=TStringList.Create;
  try
    S.Add('one');
    S.Add('two');
    S.Add('three');
    TestContext.AssertTrue(('["one", "two", "three"]')=(RJ.StringsToJSON(S)), 'StringsToJSONString');
    TestContext.AssertTrue(('{ "one" : null, "two" : null, "three" : null }')=(RJ.StringsToJSON(S,True)), 'StringsToJSONString');
  finally
    FreeAndNil(S);
  end;
end;

procedure TTestJSONStreamer.TestTListToJSONString ;


Var
  C : TList;
  D : TJSONData;
  P : Pointer;

  Function Add : TTestItem;

  begin
    Result:=TTestItem.Create(Nil);
    C.Add(Result);
  end;

begin
  RJ.Options:=RJ.Options + [jsoStreamTList];
  C:=TList.Create;
  try
    Add.StrProp:='one';
    Add.StrProp:='two';
    Add.StrProp:='three';
    D:=RJ.StreamTList(C);
    TestContext.AssertTrue(('[{ "StrProp" : "one" }, { "StrProp" : "two" }, { "StrProp" : "three" }]')=(D.AsJSON), 'StreamTlist');
  finally
    D.Free;
    For P in C do
      TObject(P).Free;
    FreeAndNil(C);
  end;
end;

procedure TTestJSONStreamer.TestCollectionToJSONString;

Var
  C : TTestCollection;

begin
  C:=TTestCollection.Create;
  try
    (C.Add as TTestItem).StrProp:='one';
    (C.Add as TTestItem).StrProp:='two';
    (C.Add as TTestItem).StrProp:='three';
    TestContext.AssertTrue(('[{ "StrProp" : "one" }, { "StrProp" : "two" }, { "StrProp" : "three" }]')=(RJ.CollectionToJSON(C)), 'CollectionToJSON');
  finally
    FreeAndNil(C);
  end;
end;

procedure TTestJSONStreamer.TestChildren;

Var
  C : TChildrenComponent;

begin
  C:=TChildrenComponent.Create(Nil);
  TComponent.Create(C).Name:='Child1';
  TComponent.Create(C).Name:='Child2';
  StreamObject(C);
  If SR.IndexOfName('Children')<>-1 then
    TestContext.Fail('Children streamed with default options');

end;

procedure TTestJSONStreamer.TestChildren2;
Var
  C : TChildrenComponent;
  A : TJSONArray;
  O : TJSONObject;

begin
  C:=TChildrenComponent.Create(Nil);
  TComponent.Create(C).Name:='Child1';
  TComponent.Create(C).Name:='Child2';
  RJ.Options:=[jsoStreamChildren];
  StreamObject(C);
  AssertPropCount(1);
  A:=AssertProperty('Children',jtArray) as TJSONArray;
  O:=SR;
  try
    TestContext.AssertTrue((2)=(A.Count), '2 Elements in array');
    TestContext.AssertTrue((jtObject)=(A.Types[0]), 'First in array is object');
    TestContext.AssertTrue((jtObject)=(A.Types[1]), 'Second in array is object');
    SR:=A.Objects[0];
    AssertProp('Name','Child1');
    SR:=A.Objects[1];
    AssertProp('Name','Child2');
  finally
    SR:=O;
  end;
end;

procedure TTestJSONStreamer.TestLowercase;
begin
  RJ.Options:=RJ.Options+[jsoLowerPropertyNames];
  StreamObject(TBooleanComponent.Create(nil));
  AssertPropCount(1);
  AssertProp('booleanprop',False);
end;


procedure RunTTestJSONStreamerTestNil(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestNil');
  try
    lFixture.SetUp;
    try lFixture.TestNil; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestEmpty(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestEmpty');
  try
    lFixture.SetUp;
    try lFixture.TestEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestEmptyComponent(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestEmptyComponent');
  try
    lFixture.SetUp;
    try lFixture.TestEmptyComponent; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestWriteBoolean(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestWriteBoolean');
  try
    lFixture.SetUp;
    try lFixture.TestWriteBoolean; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestWriteInteger(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestWriteInteger');
  try
    lFixture.SetUp;
    try lFixture.TestWriteInteger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestWriteString(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestWriteString');
  try
    lFixture.SetUp;
    try lFixture.TestWriteString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestWriteFloat(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestWriteFloat');
  try
    lFixture.SetUp;
    try lFixture.TestWriteFloat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestWriteFloat2(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestWriteFloat2');
  try
    lFixture.SetUp;
    try lFixture.TestWriteFloat2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestWriteFloat3(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestWriteFloat3');
  try
    lFixture.SetUp;
    try lFixture.TestWriteFloat3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestWriteFloat4(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestWriteFloat4');
  try
    lFixture.SetUp;
    try lFixture.TestWriteFloat4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestWriteFloat5(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestWriteFloat5');
  try
    lFixture.SetUp;
    try lFixture.TestWriteFloat5; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestEnum1(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestEnum1');
  try
    lFixture.SetUp;
    try lFixture.TestEnum1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestEnum2(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestEnum2');
  try
    lFixture.SetUp;
    try lFixture.TestEnum2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestSet1(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestSet1');
  try
    lFixture.SetUp;
    try lFixture.TestSet1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestSet2(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestSet2');
  try
    lFixture.SetUp;
    try lFixture.TestSet2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestSet3(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestSet3');
  try
    lFixture.SetUp;
    try lFixture.TestSet3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestSet4(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestSet4');
  try
    lFixture.SetUp;
    try lFixture.TestSet4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestObjectNil(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestObjectNil');
  try
    lFixture.SetUp;
    try lFixture.TestObjectNil; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestComponentProp1(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestComponentProp1');
  try
    lFixture.SetUp;
    try lFixture.TestComponentProp1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestComponentProp2(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestComponentProp2');
  try
    lFixture.SetUp;
    try lFixture.TestComponentProp2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestCollectionProp1(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestCollectionProp1');
  try
    lFixture.SetUp;
    try lFixture.TestCollectionProp1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestCollectionProp2(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestCollectionProp2');
  try
    lFixture.SetUp;
    try lFixture.TestCollectionProp2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestPersistentProp1(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestPersistentProp1');
  try
    lFixture.SetUp;
    try lFixture.TestPersistentProp1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestStringsProp1(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestStringsProp1');
  try
    lFixture.SetUp;
    try lFixture.TestStringsProp1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestStringsProp2(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestStringsProp2');
  try
    lFixture.SetUp;
    try lFixture.TestStringsProp2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestStringsProp3(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestStringsProp3');
  try
    lFixture.SetUp;
    try lFixture.TestStringsProp3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestStringsProp4(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestStringsProp4');
  try
    lFixture.SetUp;
    try lFixture.TestStringsProp4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestStringsArray(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestStringsArray');
  try
    lFixture.SetUp;
    try lFixture.TestStringsArray; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestStringsObject(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestStringsObject');
  try
    lFixture.SetUp;
    try lFixture.TestStringsObject; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestStringsStream1(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestStringsStream1');
  try
    lFixture.SetUp;
    try lFixture.TestStringsStream1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestStringsStream2(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestStringsStream2');
  try
    lFixture.SetUp;
    try lFixture.TestStringsStream2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestStringsStream3(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestStringsStream3');
  try
    lFixture.SetUp;
    try lFixture.TestStringsStream3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestStringsStream4(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestStringsStream4');
  try
    lFixture.SetUp;
    try lFixture.TestStringsStream4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestStringsStream5(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestStringsStream5');
  try
    lFixture.SetUp;
    try lFixture.TestStringsStream5; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestCollectionStream(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestCollectionStream');
  try
    lFixture.SetUp;
    try lFixture.TestCollectionStream; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestCollectionStream2(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestCollectionStream2');
  try
    lFixture.SetUp;
    try lFixture.TestCollectionStream2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestOnStreamProperty(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestOnStreamProperty');
  try
    lFixture.SetUp;
    try lFixture.TestOnStreamProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestDateTimeProp(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestDateTimeProp');
  try
    lFixture.SetUp;
    try lFixture.TestDateTimeProp; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestDateTimePropDefaultString(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestDateTimePropDefaultString');
  try
    lFixture.SetUp;
    try lFixture.TestDateTimePropDefaultString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestDateTimePropDefaultStringTime(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestDateTimePropDefaultStringTime');
  try
    lFixture.SetUp;
    try lFixture.TestDateTimePropDefaultStringTime; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestDateTimeProp2(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestDateTimeProp2');
  try
    lFixture.SetUp;
    try lFixture.TestDateTimeProp2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestDateTimeProp3(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestDateTimeProp3');
  try
    lFixture.SetUp;
    try lFixture.TestDateTimeProp3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestDateTimeProp4(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestDateTimeProp4');
  try
    lFixture.SetUp;
    try lFixture.TestDateTimeProp4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestDateTimeProp5(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestDateTimeProp5');
  try
    lFixture.SetUp;
    try lFixture.TestDateTimeProp5; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestDateTimeProp6(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestDateTimeProp6');
  try
    lFixture.SetUp;
    try lFixture.TestDateTimeProp6; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestDateTimeProp7(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestDateTimeProp7');
  try
    lFixture.SetUp;
    try lFixture.TestDateTimeProp7; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestQwordProp(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestQwordProp');
  try
    lFixture.SetUp;
    try lFixture.TestQwordProp; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestVariantShortint(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestVariantShortint');
  try
    lFixture.SetUp;
    try lFixture.TestVariantShortint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestVariantbyte(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestVariantbyte');
  try
    lFixture.SetUp;
    try lFixture.TestVariantbyte; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestVariantword(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestVariantword');
  try
    lFixture.SetUp;
    try lFixture.TestVariantword; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestVariantsmallint(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestVariantsmallint');
  try
    lFixture.SetUp;
    try lFixture.TestVariantsmallint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestVariantinteger(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestVariantinteger');
  try
    lFixture.SetUp;
    try lFixture.TestVariantinteger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestVariantlongword(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestVariantlongword');
  try
    lFixture.SetUp;
    try lFixture.TestVariantlongword; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestVariantint64(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestVariantint64');
  try
    lFixture.SetUp;
    try lFixture.TestVariantint64; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestVariantqword(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestVariantqword');
  try
    lFixture.SetUp;
    try lFixture.TestVariantqword; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestVariantsingle(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestVariantsingle');
  try
    lFixture.SetUp;
    try lFixture.TestVariantsingle; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestVariantdouble(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestVariantdouble');
  try
    lFixture.SetUp;
    try lFixture.TestVariantdouble; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestVariantCurrency(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestVariantCurrency');
  try
    lFixture.SetUp;
    try lFixture.TestVariantCurrency; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestVariantolestr(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestVariantolestr');
  try
    lFixture.SetUp;
    try lFixture.TestVariantolestr; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestVariantboolean(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestVariantboolean');
  try
    lFixture.SetUp;
    try lFixture.TestVariantboolean; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestVariantDate(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestVariantDate');
  try
    lFixture.SetUp;
    try lFixture.TestVariantDate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestVariantDate2(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestVariantDate2');
  try
    lFixture.SetUp;
    try lFixture.TestVariantDate2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestVariantArray(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestVariantArray');
  try
    lFixture.SetUp;
    try lFixture.TestVariantArray; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestMultipleProps(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestMultipleProps');
  try
    lFixture.SetUp;
    try lFixture.TestMultipleProps; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestObjectToJSONString(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestObjectToJSONString');
  try
    lFixture.SetUp;
    try lFixture.TestObjectToJSONString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestStringsToJSONString(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestStringsToJSONString');
  try
    lFixture.SetUp;
    try lFixture.TestStringsToJSONString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestCollectionToJSONString(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestCollectionToJSONString');
  try
    lFixture.SetUp;
    try lFixture.TestCollectionToJSONString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestTListToJSONString(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestTListToJSONString');
  try
    lFixture.SetUp;
    try lFixture.TestTListToJSONString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestChildren(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestChildren');
  try
    lFixture.SetUp;
    try lFixture.TestChildren; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestChildren2(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestChildren2');
  try
    lFixture.SetUp;
    try lFixture.TestChildren2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONStreamerTestLowercase(AContext: TNXTestContext);
var lFixture: TTestJSONStreamer;
begin
  lFixture:=TTestJSONStreamer.Create(AContext, 'TestLowercase');
  try
    lFixture.SetUp;
    try lFixture.TestLowercase; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestVariantInteger(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestVariantInteger');
  try
    lFixture.SetUp;
    try lFixture.TestVariantInteger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestVariantFloat(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestVariantFloat');
  try
    lFixture.SetUp;
    try lFixture.TestVariantFloat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestVariantInt64(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestVariantInt64');
  try
    lFixture.SetUp;
    try lFixture.TestVariantInt64; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestVariantBoolean(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestVariantBoolean');
  try
    lFixture.SetUp;
    try lFixture.TestVariantBoolean; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestVariantNull(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestVariantNull');
  try
    lFixture.SetUp;
    try lFixture.TestVariantNull; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestVariantString(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestVariantString');
  try
    lFixture.SetUp;
    try lFixture.TestVariantString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestVariantArray(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestVariantArray');
  try
    lFixture.SetUp;
    try lFixture.TestVariantArray; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestEmpty(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestEmpty');
  try
    lFixture.SetUp;
    try lFixture.TestEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestNullError(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestNullError');
  try
    lFixture.SetUp;
    try lFixture.TestNullError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestNull(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestNull');
  try
    lFixture.SetUp;
    try lFixture.TestNull; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestBoolean(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestBoolean');
  try
    lFixture.SetUp;
    try lFixture.TestBoolean; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestInteger(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestInteger');
  try
    lFixture.SetUp;
    try lFixture.TestInteger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestIntegerCaseInsensitive(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestIntegerCaseInsensitive');
  try
    lFixture.SetUp;
    try lFixture.TestIntegerCaseInsensitive; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestIntegerCaseSensitive(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestIntegerCaseSensitive');
  try
    lFixture.SetUp;
    try lFixture.TestIntegerCaseSensitive; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestString(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestString');
  try
    lFixture.SetUp;
    try lFixture.TestString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestFloat(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestFloat');
  try
    lFixture.SetUp;
    try lFixture.TestFloat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestFloat2(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestFloat2');
  try
    lFixture.SetUp;
    try lFixture.TestFloat2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestFloat3(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestFloat3');
  try
    lFixture.SetUp;
    try lFixture.TestFloat3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestFloat4(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestFloat4');
  try
    lFixture.SetUp;
    try lFixture.TestFloat4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestFloat5(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestFloat5');
  try
    lFixture.SetUp;
    try lFixture.TestFloat5; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestDateTime(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestDateTime');
  try
    lFixture.SetUp;
    try lFixture.TestDateTime; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestDateTimeFormat(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestDateTimeFormat');
  try
    lFixture.SetUp;
    try lFixture.TestDateTimeFormat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestEnum1(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestEnum1');
  try
    lFixture.SetUp;
    try lFixture.TestEnum1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestEnum2(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestEnum2');
  try
    lFixture.SetUp;
    try lFixture.TestEnum2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestSet1(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestSet1');
  try
    lFixture.SetUp;
    try lFixture.TestSet1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestSet2(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestSet2');
  try
    lFixture.SetUp;
    try lFixture.TestSet2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestSet3(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestSet3');
  try
    lFixture.SetUp;
    try lFixture.TestSet3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestSet4(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestSet4');
  try
    lFixture.SetUp;
    try lFixture.TestSet4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestVariantProp(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestVariantProp');
  try
    lFixture.SetUp;
    try lFixture.TestVariantProp; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestCollection(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestCollection');
  try
    lFixture.SetUp;
    try lFixture.TestCollection; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestCollection2(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestCollection2');
  try
    lFixture.SetUp;
    try lFixture.TestCollection2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestCollection3(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestCollection3');
  try
    lFixture.SetUp;
    try lFixture.TestCollection3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestCollection4(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestCollection4');
  try
    lFixture.SetUp;
    try lFixture.TestCollection4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestCollection5(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestCollection5');
  try
    lFixture.SetUp;
    try lFixture.TestCollection5; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestCollection6(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestCollection6');
  try
    lFixture.SetUp;
    try lFixture.TestCollection6; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestCollectionProp(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestCollectionProp');
  try
    lFixture.SetUp;
    try lFixture.TestCollectionProp; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestCollectionProp2(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestCollectionProp2');
  try
    lFixture.SetUp;
    try lFixture.TestCollectionProp2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestStrings(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestStrings');
  try
    lFixture.SetUp;
    try lFixture.TestStrings; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestStrings2(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestStrings2');
  try
    lFixture.SetUp;
    try lFixture.TestStrings2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestJSONDeStreamerTestStrings3(AContext: TNXTestContext);
var lFixture: TTestJSONDeStreamer;
begin
  lFixture:=TTestJSONDeStreamer.Create(AContext, 'TestStrings3');
  try
    lFixture.SetUp;
    try lFixture.TestStrings3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegistertestjsonrttiTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('testjsonrtti.TTestJSONStreamer');
  lSuite.AddTest('TestNil', @RunTTestJSONStreamerTestNil);
  lSuite.AddTest('TestEmpty', @RunTTestJSONStreamerTestEmpty);
  lSuite.AddTest('TestEmptyComponent', @RunTTestJSONStreamerTestEmptyComponent);
  lSuite.AddTest('TestWriteBoolean', @RunTTestJSONStreamerTestWriteBoolean);
  lSuite.AddTest('TestWriteInteger', @RunTTestJSONStreamerTestWriteInteger);
  lSuite.AddTest('TestWriteString', @RunTTestJSONStreamerTestWriteString);
  lSuite.AddTest('TestWriteFloat', @RunTTestJSONStreamerTestWriteFloat);
  lSuite.AddTest('TestWriteFloat2', @RunTTestJSONStreamerTestWriteFloat2);
  lSuite.AddTest('TestWriteFloat3', @RunTTestJSONStreamerTestWriteFloat3);
  lSuite.AddTest('TestWriteFloat4', @RunTTestJSONStreamerTestWriteFloat4);
  lSuite.AddTest('TestWriteFloat5', @RunTTestJSONStreamerTestWriteFloat5);
  lSuite.AddTest('TestEnum1', @RunTTestJSONStreamerTestEnum1);
  lSuite.AddTest('TestEnum2', @RunTTestJSONStreamerTestEnum2);
  lSuite.AddTest('TestSet1', @RunTTestJSONStreamerTestSet1);
  lSuite.AddTest('TestSet2', @RunTTestJSONStreamerTestSet2);
  lSuite.AddTest('TestSet3', @RunTTestJSONStreamerTestSet3);
  lSuite.AddTest('TestSet4', @RunTTestJSONStreamerTestSet4);
  lSuite.AddTest('TestObjectNil', @RunTTestJSONStreamerTestObjectNil);
  lSuite.AddTest('TestComponentProp1', @RunTTestJSONStreamerTestComponentProp1);
  lSuite.AddTest('TestComponentProp2', @RunTTestJSONStreamerTestComponentProp2);
  lSuite.AddTest('TestCollectionProp1', @RunTTestJSONStreamerTestCollectionProp1);
  lSuite.AddTest('TestCollectionProp2', @RunTTestJSONStreamerTestCollectionProp2);
  lSuite.AddTest('TestPersistentProp1', @RunTTestJSONStreamerTestPersistentProp1);
  lSuite.AddTest('TestStringsProp1', @RunTTestJSONStreamerTestStringsProp1);
  lSuite.AddTest('TestStringsProp2', @RunTTestJSONStreamerTestStringsProp2);
  lSuite.AddTest('TestStringsProp3', @RunTTestJSONStreamerTestStringsProp3);
  lSuite.AddTest('TestStringsProp4', @RunTTestJSONStreamerTestStringsProp4);
  lSuite.AddTest('TestStringsArray', @RunTTestJSONStreamerTestStringsArray);
  lSuite.AddTest('TestStringsObject', @RunTTestJSONStreamerTestStringsObject);
  lSuite.AddTest('TestStringsStream1', @RunTTestJSONStreamerTestStringsStream1);
  lSuite.AddTest('TestStringsStream2', @RunTTestJSONStreamerTestStringsStream2);
  lSuite.AddTest('TestStringsStream3', @RunTTestJSONStreamerTestStringsStream3);
  lSuite.AddTest('TestStringsStream4', @RunTTestJSONStreamerTestStringsStream4);
  lSuite.AddTest('TestStringsStream5', @RunTTestJSONStreamerTestStringsStream5);
  lSuite.AddTest('TestCollectionStream', @RunTTestJSONStreamerTestCollectionStream);
  lSuite.AddTest('TestCollectionStream2', @RunTTestJSONStreamerTestCollectionStream2);
  lSuite.AddTest('TestOnStreamProperty', @RunTTestJSONStreamerTestOnStreamProperty);
  lSuite.AddTest('TestDateTimeProp', @RunTTestJSONStreamerTestDateTimeProp);
  lSuite.AddTest('TestDateTimePropDefaultString', @RunTTestJSONStreamerTestDateTimePropDefaultString);
  lSuite.AddTest('TestDateTimePropDefaultStringTime', @RunTTestJSONStreamerTestDateTimePropDefaultStringTime);
  lSuite.AddTest('TestDateTimeProp2', @RunTTestJSONStreamerTestDateTimeProp2);
  lSuite.AddTest('TestDateTimeProp3', @RunTTestJSONStreamerTestDateTimeProp3);
  lSuite.AddTest('TestDateTimeProp4', @RunTTestJSONStreamerTestDateTimeProp4);
  lSuite.AddTest('TestDateTimeProp5', @RunTTestJSONStreamerTestDateTimeProp5);
  lSuite.AddTest('TestDateTimeProp6', @RunTTestJSONStreamerTestDateTimeProp6);
  lSuite.AddTest('TestDateTimeProp7', @RunTTestJSONStreamerTestDateTimeProp7);
  lSuite.AddTest('TestQwordProp', @RunTTestJSONStreamerTestQwordProp);
  lSuite.AddTest('TestVariantShortint', @RunTTestJSONStreamerTestVariantShortint);
  lSuite.AddTest('TestVariantbyte', @RunTTestJSONStreamerTestVariantbyte);
  lSuite.AddTest('TestVariantword', @RunTTestJSONStreamerTestVariantword);
  lSuite.AddTest('TestVariantsmallint', @RunTTestJSONStreamerTestVariantsmallint);
  lSuite.AddTest('TestVariantinteger', @RunTTestJSONStreamerTestVariantinteger);
  lSuite.AddTest('TestVariantlongword', @RunTTestJSONStreamerTestVariantlongword);
  lSuite.AddTest('TestVariantint64', @RunTTestJSONStreamerTestVariantint64);
  lSuite.AddTest('TestVariantqword', @RunTTestJSONStreamerTestVariantqword);
  lSuite.AddTest('TestVariantsingle', @RunTTestJSONStreamerTestVariantsingle);
  lSuite.AddTest('TestVariantdouble', @RunTTestJSONStreamerTestVariantdouble);
  lSuite.AddTest('TestVariantCurrency', @RunTTestJSONStreamerTestVariantCurrency);
  lSuite.AddTest('TestVariantolestr', @RunTTestJSONStreamerTestVariantolestr);
  lSuite.AddTest('TestVariantboolean', @RunTTestJSONStreamerTestVariantboolean);
  lSuite.AddTest('TestVariantDate', @RunTTestJSONStreamerTestVariantDate);
  lSuite.AddTest('TestVariantDate2', @RunTTestJSONStreamerTestVariantDate2);
  lSuite.AddTest('TestVariantArray', @RunTTestJSONStreamerTestVariantArray);
  lSuite.AddTest('TestMultipleProps', @RunTTestJSONStreamerTestMultipleProps);
  lSuite.AddTest('TestObjectToJSONString', @RunTTestJSONStreamerTestObjectToJSONString);
  lSuite.AddTest('TestStringsToJSONString', @RunTTestJSONStreamerTestStringsToJSONString);
  lSuite.AddTest('TestCollectionToJSONString', @RunTTestJSONStreamerTestCollectionToJSONString);
  lSuite.AddTest('TestTListToJSONString', @RunTTestJSONStreamerTestTListToJSONString);
  lSuite.AddTest('TestChildren', @RunTTestJSONStreamerTestChildren);
  lSuite.AddTest('TestChildren2', @RunTTestJSONStreamerTestChildren2);
  lSuite.AddTest('TestLowercase', @RunTTestJSONStreamerTestLowercase);
  lSuite:=ARegistry.AddSuite('testjsonrtti.TTestJSONDeStreamer');
  lSuite.AddTest('TestVariantInteger', @RunTTestJSONDeStreamerTestVariantInteger);
  lSuite.AddTest('TestVariantFloat', @RunTTestJSONDeStreamerTestVariantFloat);
  lSuite.AddTest('TestVariantInt64', @RunTTestJSONDeStreamerTestVariantInt64);
  lSuite.AddTest('TestVariantBoolean', @RunTTestJSONDeStreamerTestVariantBoolean);
  lSuite.AddTest('TestVariantNull', @RunTTestJSONDeStreamerTestVariantNull);
  lSuite.AddTest('TestVariantString', @RunTTestJSONDeStreamerTestVariantString);
  lSuite.AddTest('TestVariantArray', @RunTTestJSONDeStreamerTestVariantArray);
  lSuite.AddTest('TestEmpty', @RunTTestJSONDeStreamerTestEmpty);
  lSuite.AddTest('TestNullError', @RunTTestJSONDeStreamerTestNullError);
  lSuite.AddTest('TestNull', @RunTTestJSONDeStreamerTestNull);
  lSuite.AddTest('TestBoolean', @RunTTestJSONDeStreamerTestBoolean);
  lSuite.AddTest('TestInteger', @RunTTestJSONDeStreamerTestInteger);
  lSuite.AddTest('TestIntegerCaseInsensitive', @RunTTestJSONDeStreamerTestIntegerCaseInsensitive);
  lSuite.AddTest('TestIntegerCaseSensitive', @RunTTestJSONDeStreamerTestIntegerCaseSensitive);
  lSuite.AddTest('TestString', @RunTTestJSONDeStreamerTestString);
  lSuite.AddTest('TestFloat', @RunTTestJSONDeStreamerTestFloat);
  lSuite.AddTest('TestFloat2', @RunTTestJSONDeStreamerTestFloat2);
  lSuite.AddTest('TestFloat3', @RunTTestJSONDeStreamerTestFloat3);
  lSuite.AddTest('TestFloat4', @RunTTestJSONDeStreamerTestFloat4);
  lSuite.AddTest('TestFloat5', @RunTTestJSONDeStreamerTestFloat5);
  lSuite.AddTest('TestDateTime', @RunTTestJSONDeStreamerTestDateTime);
  lSuite.AddTest('TestDateTimeFormat', @RunTTestJSONDeStreamerTestDateTimeFormat);
  lSuite.AddTest('TestEnum1', @RunTTestJSONDeStreamerTestEnum1);
  lSuite.AddTest('TestEnum2', @RunTTestJSONDeStreamerTestEnum2);
  lSuite.AddTest('TestSet1', @RunTTestJSONDeStreamerTestSet1);
  lSuite.AddTest('TestSet2', @RunTTestJSONDeStreamerTestSet2);
  lSuite.AddTest('TestSet3', @RunTTestJSONDeStreamerTestSet3);
  lSuite.AddTest('TestSet4', @RunTTestJSONDeStreamerTestSet4);
  lSuite.AddTest('TestVariantProp', @RunTTestJSONDeStreamerTestVariantProp);
  lSuite.AddTest('TestCollection', @RunTTestJSONDeStreamerTestCollection);
  lSuite.AddTest('TestCollection2', @RunTTestJSONDeStreamerTestCollection2);
  lSuite.AddTest('TestCollection3', @RunTTestJSONDeStreamerTestCollection3);
  lSuite.AddTest('TestCollection4', @RunTTestJSONDeStreamerTestCollection4);
  lSuite.AddTest('TestCollection5', @RunTTestJSONDeStreamerTestCollection5);
  lSuite.AddTest('TestCollection6', @RunTTestJSONDeStreamerTestCollection6);
  lSuite.AddTest('TestCollectionProp', @RunTTestJSONDeStreamerTestCollectionProp);
  lSuite.AddTest('TestCollectionProp2', @RunTTestJSONDeStreamerTestCollectionProp2);
  lSuite.AddTest('TestStrings', @RunTTestJSONDeStreamerTestStrings);
  lSuite.AddTest('TestStrings2', @RunTTestJSONDeStreamerTestStrings2);
  lSuite.AddTest('TestStrings3', @RunTTestJSONDeStreamerTestStrings3);
end;

end.

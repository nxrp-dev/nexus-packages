unit tcjsontocode;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpjsontopas;

type

  { TTestGenCode }

  TTestGenCode= class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FPos : Integer;
    FGen: TJSONToPascal;
    procedure AssertDelphiLoadArray(AElementType, AJSONtype: String);
    procedure AssertDelphiPropertyAssignmentLoop;
    procedure AssertDestructorImplementation(AClassName: String; ObjectFields: array of string);
    procedure AssertLine(Msg: String; AExpected: String);
    procedure GenCode(AJSON: String);
    class function GetDataName(IsDelphi: Boolean): string;
    function NextLine: String;
    function Pos(const What, Where: String): Integer;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
    procedure AssertArrayCreator(const ArrayTypeName, AElementType: String; IsDelphi: Boolean=False);
    procedure AssertArraySaver(const ArrayTypeName, AElementType: String; IsDelphi: Boolean=False);
    procedure AssertArrayCreatorImplementation(const ArrayTypeName, AElementType: String; AObjectName: String=''; IsDelphi: Boolean=False);
    procedure AssertArraySaverImplementation(const ArrayTypeName, AElementType: String; AObjectName: String=''; IsDelphi: Boolean=False);
    procedure AssertLoadArray(AElementType, AJSONtype: String; IsDelphi : Boolean = False);
    procedure AssertSaveArray(AElementType, AJSONtype: String; IsDelphi: Boolean = False);
    procedure AssertPropertyAssignmentLoop;
    procedure AssertType;
    procedure AssertClassComment(const Msg, AName: String);
    procedure AssertLoadConstructorDeclaration(AType: String);
    procedure AssertLoaderDeclaration(AType: String);
    procedure AssertSaverDeclaration;
    procedure AssertLoaderImplementationEnd(IsDelphi : Boolean = False);
    procedure AssertLoadConstructorImplementationStart(Const ATypeName, ADataName: String);
    procedure AssertLoaderImplementationStart(Const ATypeName, ADataName: String; IsDelphi : Boolean = False);
    procedure AssertSaverImplementationStart(Const ATypeName: String; IsDelphi : Boolean = False);
    procedure AssertArrayLoaderImplementationStart(Const ATypeName, ADataName, ArrayName, ArrayTypeName, ArrayElementType : String; IsDelphi : Boolean = False);
    procedure AssertObjectLoaderImplementationStart(Const ATypeName, ADataName, ArrayName, ArrayTypeName, ArrayElementType : String; IsDelphi : Boolean = False);
    Procedure AssertUnitHeader;
    Procedure AssertBegin;
    Procedure AssertEnd(Const Msg : String = '');
    Procedure AssertUnitEnd;
    Procedure AssertImplementation;
    procedure AssertProperty(const AName, AType: String; Setter : Boolean = False);
    procedure AssertSetter(const AName, AType: String);
    Procedure AssertClassHeader(Const AName : String; AParentName : String);
    Procedure AssertSetterImplementation(Const AClassType,AName,AType : String; IsObject : Boolean = False);
    Procedure AssertVisibility(Const AVisibility : String);
    Procedure AssertDestructor;
    Procedure AssertField(Const AName,AType : String; Prefix : String = '');
    Procedure AssertArrayType(Const AName,AItemType : String);
    Procedure AssertPropertyMap(Const APath,ATypeName,APropertyName,AParentTypeName : String);
    Property Gen : TJSONToPascal Read FGen;
  public
    procedure TestEmpty;
    Procedure TestSimple;
    Procedure TestClassName;
    Procedure TestParentClassName;
    Procedure TestIntegerProperty;
    Procedure Test2IntegersProperty;
    Procedure TestBooleanProperty;
    Procedure TestStringProperty;
    Procedure TestFloatProperty;
    Procedure TestInt64Property;
    Procedure TestPropertySetter;
    Procedure TestObjectProperty;
    Procedure TestObjectPropertySetter;
    Procedure TestObjectPropertySuffix;
    Procedure TestObjectPropertySkip;
    Procedure TestObjectPropertyRecurse;
    Procedure TestObjectPropertyRecurseSuffix;
    Procedure TestObjectPropertyRecurseSkip;
    Procedure TestObjectPropertyRecurseSkipB;
    Procedure TestStringArrayProperty;
    Procedure TestIntegerArrayProperty;
    Procedure TestBooleanArrayProperty;
    Procedure TestFloatArrayProperty;
    Procedure TestInt64ArrayProperty;
    Procedure TestStringArrayPropertySuffix;

    Procedure TestLoadIntegerProperty;
    Procedure TestLoad2IntegersProperty;
    Procedure TestLoadIntegerWithErrorProperty;
    Procedure TestLoadIntegerCaseInsensitiveProperty;
    Procedure TestLoadStringProperty;
    Procedure TestLoadBooleanProperty;
    Procedure TestLoadInt64Property;
    Procedure TestLoadFloatProperty;
    Procedure TestLoadObjectProperty;
    Procedure TestLoadStringArrayProperty;
    Procedure TestLoadBooleanArrayProperty;
    Procedure TestLoadIntegerArrayProperty;
    Procedure TestLoadInt64ArrayProperty;
    Procedure TestLoadFloatArrayProperty;

    Procedure TestLoadDelphiIntegerProperty;
    Procedure TestLoadDelphi2IntegersProperty;
    Procedure TestLoadDelphiIntegerWithErrorProperty;
    Procedure TestLoadDelphiIntegerCaseInsensitiveProperty;
    Procedure TestLoadDelphiStringProperty;
    Procedure TestLoadDelphiBooleanProperty;
    Procedure TestLoadDelphiInt64Property;
    Procedure TestLoadDelphiFloatProperty;
    procedure TestLoadDelphiObjectProperty;
    Procedure TestLoadDelphiStringArrayProperty;
    Procedure TestLoadDelphiBooleanArrayProperty;
    Procedure TestLoadDelphiIntegerArrayProperty;
    Procedure TestLoadDelphiInt64ArrayProperty;
    Procedure TestLoadDelphiFloatArrayProperty;

    Procedure TestSaveIntegerProperty;
    Procedure TestSave2IntegersProperty;
    Procedure TestSaveStringProperty;
    Procedure TestSaveBooleanProperty;
    Procedure TestSaveInt64Property;
    Procedure TestSaveFloatProperty;
    Procedure TestSaveObjectProperty;
    Procedure TestSaveStringArrayProperty;
    Procedure TestSaveBooleanArrayProperty;
    Procedure TestSaveIntegerArrayProperty;
    Procedure TestSaveInt64ArrayProperty;
    Procedure TestSaveFloatArrayProperty;

    Procedure TestSaveDelphiIntegerProperty;
    Procedure TestSaveDelphi2IntegersProperty;
    Procedure TestSaveDelphiStringProperty;
    Procedure TestSaveDelphiBooleanProperty;
    Procedure TestSaveDelphiInt64Property;
    Procedure TestSaveDelphiFloatProperty;
    Procedure TestSaveDelphiObjectProperty;
    Procedure TestSaveDelphiStringArrayProperty;
    Procedure TestSaveDelphiBooleanArrayProperty;
    Procedure TestSaveDelphiIntegerArrayProperty;
    Procedure TestSaveDelphiInt64ArrayProperty;
    Procedure TestSaveDelphiFloatArrayProperty;

  end;

Var
  TestUnitDir : String;

procedure RegistertcjsontocodeTests(ARegistry: TNXTestRegistry);

implementation

procedure TTestGenCode.SetUp;
begin
  FGen:=TJSONToPascal.Create(Nil);
end;

procedure TTestGenCode.TearDown;
begin
  FreeAndNil(FGen)
end;

function TTestGenCode.NextLine: String;

begin
  Result:='';
  While (Result='') do
    begin
    Inc(FPos);
    TestContext.AssertTrue(FPos<FGen.Code.Count, 'In scope');
    Result:=Trim(FGen.Code[FPos]);
    end;
end;

procedure TTestGenCode.AssertUnitHeader;

Var
  S: String;

begin
  S:=NextLine;
  TestContext.AssertTrue(Pos('unit ',S)=1, 'Have unit');
  S:=NextLine;
  TestContext.AssertTrue(Pos('interface',S)=1, 'Have interface');
  S:=NextLine;
  TestContext.AssertTrue(Pos('uses ',S)=1, 'Have uses');
  S:=NextLine;
  TestContext.AssertTrue(Pos('Type',S)=1, 'Type line');
end;

procedure TTestGenCode.AssertBegin;
begin
  TestContext.AssertTrue(pos('begin',nextline)>0, 'Have begin');
end;

procedure TTestGenCode.AssertEnd(const Msg: String);
begin
  TestContext.AssertTrue(pos('end;',nextline)>0, 'Have end:'+Msg);
end;

procedure TTestGenCode.AssertUnitEnd;
begin
  TestContext.AssertTrue(pos('end.',nextline)>0, 'Have end.');
end;

procedure TTestGenCode.AssertImplementation;
begin
  TestContext.AssertTrue(CompareText(NextLine,'implementation')=0, 'Have implementation');
end;

function TTestGenCode.Pos(const What, Where: String): Integer;

begin
  Result:=system.Pos(lowercase(what),lowercase(where));
end;

procedure TTestGenCode.AssertClassComment(const Msg,AName: String);

Var
  S : String;

begin
  S:=NextLine;
  TestContext.AssertTrue(Pos('{ --',S)>0, Msg+' ('+AName+'): Class header comment start');
  S:=NextLine;
  TestContext.AssertTrue(Pos(AName,S)>0, Msg+' ('+AName+'): Class header comment class nam');
  S:=NextLine;
  TestContext.AssertTrue(Pos('}',S)>0, Msg+' ('+AName+'): Class header comment end');
end;

procedure TTestGenCode.AssertClassHeader(const AName: String; AParentName: String);

Var
  P : Integer;
  S : String;

begin
  AssertClassComment('Class declarationheader for '+AName,AName);
  S:=NextLine;
  P:=Pos(AName+' = class(',S);
  TestContext.AssertTrue(P>0, 'class type ');
  P:=Pos(AParentName+')',S);
  TestContext.AssertTrue(P>0, 'Class parent type ');
  AssertVisibility('private');
end;

procedure TTestGenCode.AssertSetterImplementation(const AClassType, AName,
  AType: String; IsObject: Boolean);

Var
  S,PS : String;
  P : Integer;

begin
  S:=NextLine;
  PS:='Procedure '+AClassType+'.Set'+Aname+'(AValue';
  TestContext.AssertTrue(Pos(PS,S)>0, 'Have declaration start');
  Delete(S,1,Length(PS));
  P:=Pos(':',S);
  TestContext.AssertTrue(p>0, 'Have colon');
  Delete(S,1,P);
  TestContext.AssertTrue(Pos(AType,S)>0, 'Have type');
  TestContext.AssertTrue(Pos(');',S)>0, 'Have );');
  TestContext.AssertTrue(S[Length(S)]=';', 'Terminated on semicolon');
  AssertBegin;
  TestContext.AssertTrue(Pos('if ('+Gen.FieldPrefix+AName+'=AValue) then exit;',NextLine)>0, 'Have change check');
  if IsObject then
    TestContext.AssertTrue(Pos('FreeAndNil('+Gen.FieldPrefix+AName+');',NextLine)>0, 'Have free of previous value');
  TestContext.AssertTrue(Pos(Gen.FieldPrefix+AName+':=AValue;',NextLine)>0, 'Have Assignment');
  AssertEnd;
end;

procedure TTestGenCode.AssertVisibility(const AVisibility: String);

begin
  TestContext.AssertTrue(Pos(AVisibility,NextLine)>0, 'Have visibility section '+AVisibility);
end;

procedure TTestGenCode.AssertDestructor;
begin
  TestContext.AssertTrue(Pos('Destructor Destroy; override;',NextLine)>0, 'Have destructor declaration');
end;


procedure TTestGenCode.AssertDestructorImplementation(AClassName: String;
  ObjectFields: array of string);

Var
  F : String;

begin
  TestContext.AssertTrue(Pos(Format('Destructor %s.Destroy;',[AClassName]),NextLine)>0, 'Have destructor implementation');
  AssertBegin;
  For F in ObjectFields do
    TestContext.AssertTrue(Pos('FreeAndNil(F'+F+');',NextLine)>0, 'Have destructor for F'+F);
  TestContext.AssertTrue(Pos('Inherited;',NextLine)>0, 'Have inherited call'+F);
  AssertEnd;
end;

procedure TTestGenCode.AssertField(const AName, AType: String; Prefix : String = '');

Var
  F,S : String;
  P : Integer;

begin
  F:=Prefix;
  if F='' then
    F:='F';
  S:=NextLine;
  TestContext.AssertTrue(Pos(F+AName,S)=1, 'Field Name');
  P:=Pos(':',S);
  TestContext.AssertTrue(P>Length(F+AName), 'Colon after field name');
  TestContext.AssertTrue(Pos(AType,S)>P, 'Field type after colon');
  TestContext.AssertTrue(S[Length(S)]=';', 'Terminated on semicolon');
end;

procedure TTestGenCode.AssertSetter(const AName, AType: String);

Var
  N,S,PD : String;
  P,p2 : Integer;

begin
  S:=NextLine;
  N:='Setter declaration for '+AName+' : ';
  PD:='Procedure Set'+AName;
  TestContext.AssertTrue(Pos(PD,S)=1, N+'Setter name');
  P:=Pos('(',S);
  TestContext.AssertTrue(P>Length(PD), N+'( after parameter name');
  P:=Pos(':',S);
  TestContext.AssertTrue(P>Length(PD), N+'Colon after parameter name');
  Delete(S,1,P);
  P2:=Pos(AType,S);
  TestContext.AssertTrue(P2>0, N+'Field type after colon '+AType+' : '+S);
  P:=Pos(');',S);
  TestContext.AssertTrue(P>P2, N+'); type after parameter type');
  P2:=Pos('virtual',S);
  TestContext.AssertTrue(P2>P, N+'virtual after ); ');
  TestContext.AssertTrue(S[Length(S)]=';', N+'Terminated on semicolon');
end;

procedure TTestGenCode.AssertArrayType(const AName, AItemType: String);

Var
  P,p2 : Integer;
  S : String;

begin
  S:=NextLine;
  TestContext.AssertTrue(Pos(AName,S)=1, 'Type Name');
  P:=Pos('=',S);
  TestContext.AssertTrue(P>Pos(AName,S), 'Equal token after type Name');
  P2:=Pos('Array of',S);
  TestContext.AssertTrue(P2>P, 'Array of after Equal token after type Name');
  P:=Pos(AItemType,S);
  TestContext.AssertTrue(P>P2, 'Item type name after array of');
  TestContext.AssertTrue(S[Length(S)]=';', 'Terminated on semicolon');
end;

procedure TTestGenCode.AssertPropertyMap(const APath, ATypeName, APropertyName,
  AParentTypeName: String);

Var
  M : TPropertyMapItem;

begin
  M:=Gen.PropertyMap.FindPath(APath);
  TestContext.AssertTrue((M)<>nil, 'Have property map "'+APath+'"');
  TestContext.AssertTrue((ATypeName)=(M.TypeName), 'Have type name ');
  TestContext.AssertTrue((APropertyName)=(M.PropertyName), 'Have property name ');
  TestContext.AssertTrue((AParentTypeName)=(M.ParentTypeName), 'Have parent type name ');
end;

procedure TTestGenCode.AssertProperty(const AName, AType: String; Setter : Boolean = False);

Var
  S : String;
  P,P2 : Integer;

begin
  S:=NextLine;
  TestContext.AssertTrue(Pos('Property '+AName,S)=1, 'Property Name');
  P:=Pos(':',S);
  TestContext.AssertTrue(P>Length('Property '+AName), 'Colon after property name');
  P2:=Pos(AType,S);
  TestContext.AssertTrue(P2>P, 'Field type after colon');
  P:=pos(' read ',S);
  TestContext.AssertTrue(P>P2, 'Read specifier after type ');
  P2:=Pos('F'+AName,S);
  TestContext.AssertTrue(P2>P, 'Field name for read specifier');
  P:=pos(' write ',S);
  TestContext.AssertTrue(P>P2, 'Write specifier after type ');
  if Setter Then
    P2:=Pos('write Set'+AName,S)
  else
    P2:=Pos('write F'+AName,S);
  TestContext.AssertTrue(P2>P, 'Field name for write specifier');

  TestContext.AssertTrue(S[Length(S)]=';', 'Terminated on semicolon');
end;


procedure TTestGenCode.GenCode(AJSON : String);

Var
  F : Text;

begin
  Gen.JSON:=AJSON;
  Gen.DestUnitName:='u'+CaseName;
  Gen.Execute;
  if (TestUnitDir<>'') then
    begin
    Assign(F,IncludeTrailingPathDelimiter(TestUnitDir)+Gen.DestUnitName+'.pas');
    Rewrite(F);
    Writeln(F,'// ',Self.CaseName);
    Writeln(F,Gen.Code.Text);
    Close(F);
    Assign(F,IncludeTrailingPathDelimiter(TestUnitDir)+Gen.DestUnitName+'.json');
    Rewrite(F);
    Writeln(F,AJSON);
    Close(F);
    end
  else
    begin
    Writeln('// ',Self.CaseName);
    Writeln('(* JSON: '+AJSON+' *)');
    Writeln(Gen.Code.Text);
    end;

  FPos:=-1;
end;

procedure TTestGenCode.TestEmpty;
begin
  TestContext.AssertTrue((Gen)<>nil, 'Have generator');
  TestContext.AssertTrue((Gen.PropertyMap)<>nil, 'Generator property map exists');
  TestContext.AssertTrue((Gen.Code)<>nil, 'Generator property code exists');
  TestContext.AssertTrue((Gen.JSONData)=nil, 'Generator JSON empty');
  TestContext.AssertTrue((Gen.JSONStream)=nil, 'Generator JSON stream empty');
  TestContext.AssertTrue(('')=(Gen.JSON), 'Generator JSON empty');
  TestContext.AssertTrue((0)=(Gen.PropertyMap.Count), 'Generator property map empty');
end;

procedure TTestGenCode.TestSimple;
begin
  GenCode('{}');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertVisibility('public');
  AssertEnd;
  AssertPropertyMap('','TMyObject','','TObject');
end;

procedure TTestGenCode.TestClassName;
begin
  Gen.PropertyMap.AddPath('','TSomeObject');
  GenCode('{}');
  AssertUnitHeader;
  AssertClassHeader('TSomeObject','TObject');
  AssertVisibility('public');
  AssertEnd;
  AssertPropertyMap('','TSomeObject','','TObject');
end;

procedure TTestGenCode.TestParentClassName;
begin
  Gen.PropertyMap.AddPath('','TSomeObject');
  Gen.DefaultParentName:='TMyObject';
  GenCode('{}');
  AssertUnitHeader;
  AssertClassHeader('TSomeObject','TMyObject');
  AssertVisibility('public');
  AssertEnd;
  AssertPropertyMap('','TSomeObject','','TMyObject');
end;

procedure TTestGenCode.TestIntegerProperty;
begin
  GenCode('{ "a" : 1 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','integer');
  AssertVisibility('public');
  AssertProperty('a','integer');
  AssertEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Integer','a','');
end;

procedure TTestGenCode.Test2IntegersProperty;
begin
  GenCode('{ "a" : 1, "b" : 2 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','integer');
  AssertField('b','integer');
  AssertVisibility('public');
  AssertProperty('a','integer');
  AssertProperty('b','integer');
  AssertEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Integer','a','');
  AssertPropertyMap('b','Integer','b','');
end;

procedure TTestGenCode.TestBooleanProperty;
begin
  GenCode('{ "a" : true }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','boolean');
  AssertVisibility('public');
  AssertProperty('a','boolean');
  AssertEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Boolean','a','');
end;

procedure TTestGenCode.TestStringProperty;
begin
  GenCode('{ "a" : "abce" }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','string');
  AssertVisibility('public');
  AssertProperty('a','string');
  AssertEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','String','a','');
end;

procedure TTestGenCode.TestFloatProperty;
begin
  GenCode('{ "a" : 1.1 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','double');
  AssertVisibility('public');
  AssertProperty('a','double');
  AssertEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Double','a','');
end;

procedure TTestGenCode.TestInt64Property;
begin
  GenCode('{ "a" : 1234567890123 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','int64');
  AssertVisibility('public');
  AssertProperty('a','int64');
  AssertEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Int64','a','');
end;

procedure TTestGenCode.TestPropertySetter;
begin
  Gen.Options:=[jpoUseSetter];
  GenCode('{ "a" : 1234567890123 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','int64');
  AssertVisibility('protected');
  AssertSetter('A','int64');
  AssertVisibility('public');
  AssertProperty('a','int64',True);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertSetterImplementation('TMyObject','a','int64');
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Int64','a','');
end;

procedure TTestGenCode.TestObjectProperty;
begin
  GenCode('{ "a" : {} }');
  AssertUnitHeader;
  AssertClassHeader('TA','TObject');
  AssertVisibility('public');
  AssertEnd;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Ta');
  AssertVisibility('public');
  AssertDestructor;
  AssertProperty('a','Ta');
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Comment for class TA','Ta');
  AssertClassComment('Comment for class TMyObject','TMyObject');
  AssertDestructorImplementation('TMyObject',['a']);
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Ta','a','TObject');
end;

procedure TTestGenCode.TestObjectPropertySetter;
begin
  Gen.Options:=[jpoUseSetter];
  GenCode('{ "a" : {} }');
  AssertUnitHeader;
  AssertClassHeader('TA','TObject');
  AssertVisibility('protected');
  AssertVisibility('public');
  AssertEnd;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Ta');
  AssertVisibility('protected');
  AssertSetter('a','Ta');
  AssertVisibility('Public');
  AssertDestructor;
  AssertProperty('a','Ta',True);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Comment for class TA','Ta');
  AssertClassComment('Comment for class TMyObject','TMyObject');
  AssertDestructorImplementation('TMyObject',['a']);
  AssertSetterImplementation('TMyObject','a','Ta',True);
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Ta','a','TObject');
end;

procedure TTestGenCode.TestObjectPropertySuffix;
begin
  Gen.PropertyTypeSuffix:='Type';
  GenCode('{ "a" : {} }');
  AssertUnitHeader;
  AssertClassHeader('TAType','TObject');
  AssertVisibility('public');
  AssertEnd;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','TaType');
  AssertVisibility('public');
  AssertDestructor;
  AssertProperty('a','TaType');
  AssertEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','TaType','a','TObject');
end;

procedure TTestGenCode.TestObjectPropertySkip;
begin
  Gen.PropertyTypeSuffix:='Type';
  Gen.PropertyMap.AddPath('a','me').SkipType:=true;
  GenCode('{ "a" : {} }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','me');
  AssertVisibility('public');
  AssertDestructor;
  AssertProperty('a','me');
  AssertEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','me','a','');
end;

procedure TTestGenCode.TestObjectPropertyRecurse;
begin
  GenCode('{ "a" : { "b" : {} } }');
  AssertUnitHeader;
  AssertClassHeader('TAB','TObject');
  AssertVisibility('public');
  AssertEnd;
  AssertClassHeader('TA','TObject');
  AssertField('b','TaB');
  AssertVisibility('public');
  AssertDestructor;
  AssertProperty('b','TaB');
  AssertEnd;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Ta');
  AssertVisibility('public');
  AssertDestructor;
  AssertProperty('a','Ta');
  AssertEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Ta','a','TObject');
  AssertPropertyMap('a.b','Tab','b','TObject');
end;

procedure TTestGenCode.TestObjectPropertyRecurseSuffix;
begin
  Gen.PropertyTypeSuffix:='Type';
  GenCode('{ "a" : { "b" : {} } }');
  AssertUnitHeader;
  AssertClassHeader('TABType','TObject');
  AssertVisibility('public');
  AssertEnd;
  AssertClassHeader('TAType','TObject');
  AssertField('b','TaBType');
  AssertVisibility('public');
  AssertDestructor;
  AssertProperty('b','TaBType');
  AssertEnd;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','TaType');
  AssertVisibility('public');
  AssertDestructor;
  AssertProperty('a','TaType');
  AssertEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','TaType','a','TObject');
  AssertPropertyMap('a.b','TabType','b','TObject');
end;

procedure TTestGenCode.TestObjectPropertyRecurseSkip;
begin
  Gen.PropertyMap.AddPath('a','me').SkipType:=true;
  GenCode('{ "a" : { "b" : {} } }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','me');
  AssertVisibility('public');
  AssertDestructor;
  AssertProperty('a','me');
  AssertEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','me','a','');
end;

procedure TTestGenCode.TestObjectPropertyRecurseSkipB;
begin
  Gen.PropertyMap.AddPath('a.b','me').SkipType:=true;
  GenCode('{ "a" : { "b" : {} } }');
  AssertUnitHeader;
  AssertClassHeader('TA','TObject');
  AssertField('b','me');
  AssertVisibility('public');
  AssertDestructor;
  AssertProperty('b','me');
  AssertEnd;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Ta');
  AssertVisibility('public');
  AssertDestructor;
  AssertProperty('a','Ta');
  AssertEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Ta','a','TObject');
  AssertPropertyMap('a.b','me','b','');
end;

procedure TTestGenCode.TestStringArrayProperty;
begin
  GenCode('{ "a" : [ "" ] }');
  AssertUnitHeader;
  AssertArrayType('Ta','string');
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Ta');
  AssertVisibility('public');
  AssertProperty('a','Ta');
  AssertEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Ta','a','');
  AssertPropertyMap('a[0]','String','','');
end;

procedure TTestGenCode.TestIntegerArrayProperty;
begin
  GenCode('{ "a" : [ 1 ] }');
  AssertUnitHeader;
  AssertArrayType('Ta','integer');
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Ta');
  AssertVisibility('public');
  AssertProperty('a','Ta');
  AssertEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Ta','a','');
  AssertPropertyMap('a[0]','Integer','','');
end;

procedure TTestGenCode.TestBooleanArrayProperty;
begin
  GenCode('{ "a" : [ true ] }');
  AssertUnitHeader;
  AssertArrayType('Ta','Boolean');
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Ta');
  AssertVisibility('public');
  AssertProperty('a','Ta');
  AssertEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Ta','a','');
  AssertPropertyMap('a[0]','Boolean','','');
end;

procedure TTestGenCode.TestFloatArrayProperty;
begin
  GenCode('{ "a" : [ 1.2 ] }');
  AssertUnitHeader;
  AssertArrayType('Ta','Double');
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Ta');
  AssertVisibility('public');
  AssertProperty('a','Ta');
  AssertEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Ta','a','');
  AssertPropertyMap('a[0]','Double','','');
end;

procedure TTestGenCode.TestInt64ArrayProperty;
begin
  GenCode('{ "a" : [ 1234567890123 ] }');
  AssertUnitHeader;
  AssertArrayType('Ta','Int64');
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Ta');
  AssertVisibility('public');
  AssertProperty('a','Ta');
  AssertEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Ta','a','');
  AssertPropertyMap('a[0]','Int64','','');
end;

procedure TTestGenCode.TestStringArrayPropertySuffix;
begin
  Gen.PropertyTypeSuffix:='Type';
  GenCode('{ "a" : [ "" ] }');
  AssertUnitHeader;
  AssertArrayType('TaType','string');
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','TaType');
  AssertVisibility('public');
  AssertProperty('a','TaType');
  AssertEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','TaType','a','');
  AssertPropertyMap('a[0]','String','','');
end;

procedure TTestGenCode.AssertLoadConstructorDeclaration(AType: String);

Var
  S : String;

begin
  S:=NextLine;
  TestContext.AssertTrue(Pos('Constructor CreateFromJSON(AJSON : '+AType+'); virtual;',S)>0, 'Load Constructor declaration in '+S);
end;

procedure TTestGenCode.AssertLoaderDeclaration(AType : String);

Var
  S : String;

begin
  S:=NextLine;
  TestContext.AssertTrue(Pos('Procedure LoadFromJSON(AJSON : '+AType+'); virtual;',S)>0, 'LoadFromJSON declaration in '+S);
end;

procedure TTestGenCode.AssertSaverDeclaration;

Var
  S : String;

begin
  S:=NextLine;
  TestContext.AssertTrue(Pos('Function SaveToJSON : TJSONObject;',S)>0, 'SaveToJSON function declaration in '+S);
  S:=NextLine;
  TestContext.AssertTrue(Pos('Procedure SaveToJSON(AJSON : TJSONObject)',S)>0, 'SaveToJSON procedure declaration in '+S);
end;

procedure TTestGenCode.AssertLoaderImplementationEnd(IsDelphi : Boolean = False);

begin
  if Not IsDelphi then
    AssertEnd('Case');// Case
  AssertEnd('for');// For
  AssertEnd('procedure');// Routine
end;

procedure TTestGenCode.AssertArrayLoaderImplementationStart(const ATypeName,
  ADataName, ArrayName, ArrayTypeName, ArrayElementType: String; IsDelphi : Boolean = False);

Var
  S : String;
begin
  S:=NextLine;
  TestContext.AssertTrue(Pos('Procedure '+ATypeName+'.LoadFromJSON(AJSON : '+ADataName+');',S)>0, 'Have loader start: '+ATypeName+','+ADataName);
  if isDelphi then
    AssertDelphiPropertyAssignmentLoop
  else
    AssertPropertyAssignmentLoop;
end;

procedure TTestGenCode.AssertPropertyAssignmentLoop;

begin
  TestContext.AssertTrue(Pos('var',NextLine)>0, 'Have var');
  TestContext.AssertTrue(Pos('E : TJSONEnum;',NextLine)>0, 'Have P enum');
  AssertBegin;
  TestContext.AssertTrue(Pos('For E in AJSON do',NextLine)>0, 'Have E for enum');
  AssertBegin;
  if (jpoLoadCaseInsensitive in Gen.Options) then
    TestContext.AssertTrue(Pos('case LowerCase(E.key) of',NextLine)>0, 'Have E for enum')
  else
    TestContext.AssertTrue(Pos('case E.key of',NextLine)>0, 'Have E for enum');
end;

procedure TTestGenCode.AssertDelphiPropertyAssignmentLoop;

Var
  S : String;

begin
  TestContext.AssertTrue(Pos('var',NextLine)>0, 'Have var');
  TestContext.AssertTrue(Pos('P : TJSONPair;',NextLine)>0, 'Have pair');
  TestContext.AssertTrue(Pos('O : TJSONObject;',NextLine)>0, 'Have obj');
  TestContext.AssertTrue(Pos('PN : String;',NextLine)>0, 'Have Propertyname var');
  AssertBegin;
  S:=NextLine;
  TestContext.AssertTrue(Pos('not (AJSON is TJSONObject)',S)>0, 'Have JSONObject check in '+S);
  if jpoUnknownLoadPropsError in gen.Options then
    TestContext.AssertTrue(Pos('Raise EJSONException',NextLine)>0, 'Have raise statement');
  TestContext.AssertTrue(Pos('O:=AJSON as TJSONObject',NextLine)>0, 'Have typecast');
  TestContext.AssertTrue(Pos('For P in O do',NextLine)>0, 'Have P for enum');
  AssertBegin;
  if jpoLoadCaseInsensitive in Gen.Options then
    TestContext.AssertTrue(Pos('PN:=LowerCase(P.JSONString.Value)',NextLine)>0, 'Have case insensitive propertyname assign')
  else
    TestContext.AssertTrue(Pos('PN:=P.JSONString.Value',NextLine)>0, 'Have propertyname assign');
end;

procedure TTestGenCode.AssertObjectLoaderImplementationStart(const ATypeName,
  ADataName, ArrayName, ArrayTypeName, ArrayElementType: String; IsDelphi : Boolean = False);
Var
  S : String;
begin
  S:=NextLine;
  TestContext.AssertTrue(Pos('Procedure '+ATypeName+'.LoadFromJSON(AJSON : '+ADataName+');',S)>0, 'Have loader start: '+ATypeName+','+ADataName);
  if isDelphi then
    AssertDelphiPropertyAssignmentLoop
  else
    AssertPropertyAssignmentLoop;
end;

procedure TTestGenCode.AssertSaverImplementationStart(const ATypeName: String;
  IsDelphi: Boolean);

Var
  S,N : String;

begin
  N:='SaveToJSONFunction '+ATypeName+' : ';
  S:=NextLine;
  TestContext.AssertTrue(Pos('Function  '+ATypeName+'.SaveToJSON : TJSONObject;',S)>0, N+'header');
  AssertBegin;
  TestContext.AssertTrue(Pos('Result:=TJSONObject.Create',NextLine)>0, N+'Create');
  TestContext.AssertTrue(Pos('Try',NextLine)>0, N+'Try');
  TestContext.AssertTrue(Pos('SaveToJSON(Result);',NextLine)>0, N+'Save');
  TestContext.AssertTrue(Pos('except',NextLine)>0, N+'except');
  TestContext.AssertTrue(Pos('FreeAndNil(Result);',NextLine)>0, N+'FreeAndNil');
  TestContext.AssertTrue(Pos('Raise;',NextLine)>0, N+'Reraise');
  TestContext.AssertTrue(Pos('End;',NextLine)>0, N+'end;');
  TestContext.AssertTrue(Pos('End;',NextLine)>0, N+'end;');
  TestContext.AssertTrue(Pos('Procedure '+ATypeName+'.SaveToJSON(AJSON : TJSONObject);',NextLine)>0, N+'proc header');
  AssertBegin;
end;


procedure TTestGenCode.AssertLoaderImplementationStart(const ATypeName,
  ADataName: String; IsDelphi : Boolean = False);

begin
  TestContext.AssertTrue(Pos('Procedure '+ATypeName+'.LoadFromJSON(AJSON : '+ADataName+');',NextLine)>0, '');
  if isDelphi then
    AssertDelphiPropertyAssignmentLoop
  else
    AssertPropertyAssignmentLoop;
end;

procedure TTestGenCode.AssertLoadConstructorImplementationStart(const ATypeName,
  ADataName: String);

begin
  TestContext.AssertTrue(Pos('Constructor '+ATypeName+'.CreateFromJSON(AJSON : '+ADataName+');',NextLine)>0, 'Have constructor call');
  AssertBegin;
  TestContext.AssertTrue(Pos('create();',NextLine)>0, 'Call create constructor');
  TestContext.AssertTrue(Pos('LoadFromJSON(AJSON);',NextLine)>0, 'Call LoadFromJSON');
  AssertEnd;
end;

procedure TTestGenCode.TestLoadIntegerProperty;
begin
  Gen.Options:=[jpoGenerateLoad];
  GenCode('{ "a" : 1234 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','integer');
  AssertVisibility('public');
  AssertLoadConstructorDeclaration('TJSONData');
  AssertLoaderDeclaration('TJSONData');
  AssertProperty('a','integer',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertLoadConstructorImplementationStart('TMyObject','TJSONData');
  AssertLoaderImplementationStart('TMyObject','TJSONData');
  TestContext.AssertTrue(Pos('''a'':',NextLine)>0, 'Have "a" integer property case');
  TestContext.AssertTrue(Pos('a:=E.Value.AsInteger;',NextLine)>0, 'Have "a" integer property set');
  AssertLoaderImplementationEnd;
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Integer','a','');
end;

procedure TTestGenCode.TestLoad2IntegersProperty;
begin
  Gen.Options:=[jpoGenerateLoad];
  GenCode('{ "a" : 1234, "b" : 5678 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','integer');
  AssertField('b','integer');
  AssertVisibility('public');
  AssertLoadConstructorDeclaration('TJSONData');
  AssertLoaderDeclaration('TJSONData');
  AssertProperty('a','integer',False);
  AssertProperty('b','integer',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertLoadConstructorImplementationStart('TMyObject','TJSONData');
  AssertLoaderImplementationStart('TMyObject','TJSONData');
  TestContext.AssertTrue(Pos('''a'':',NextLine)>0, 'Have "a" integer property case');
  TestContext.AssertTrue(Pos('a:=E.Value.AsInteger;',NextLine)>0, 'Have "a" integer property set');
  TestContext.AssertTrue(Pos('''b'':',NextLine)>0, 'Have "b" integer property case');
  TestContext.AssertTrue(Pos('b:=E.Value.AsInteger;',NextLine)>0, 'Have "b" integer property set');
  AssertLoaderImplementationEnd;
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Integer','a','');
  AssertPropertyMap('b','Integer','b','');
end;

procedure TTestGenCode.TestLoadIntegerWithErrorProperty;
begin
  Gen.Options:=[jpoGenerateLoad,jpoUnknownLoadPropsError];
  GenCode('{ "a" : 1234, "b" : 5678 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','integer');
  AssertField('b','integer');
  AssertVisibility('public');
  AssertLoadConstructorDeclaration('TJSONData');
  AssertLoaderDeclaration('TJSONData');
  AssertProperty('a','integer',False);
  AssertProperty('b','integer',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertLoadConstructorImplementationStart('TMyObject','TJSONData');
  AssertLoaderImplementationStart('TMyObject','TJSONData');
  TestContext.AssertTrue(Pos('''a'':',NextLine)>0, 'Have "a" integer property case');
  TestContext.AssertTrue(Pos('a:=E.Value.AsInteger;',NextLine)>0, 'Have "a" integer property set');
  TestContext.AssertTrue(Pos('''b'':',NextLine)>0, 'Have "b" integer property case');
  TestContext.AssertTrue(Pos('b:=E.Value.AsInteger;',NextLine)>0, 'Have "b" integer property set');
  TestContext.AssertTrue(Pos('else',NextLine)>0, 'Have case else');
  TestContext.AssertTrue(Pos('Raise EJSON.CreateFmt',NextLine)>0, 'Have raise statement');
  AssertLoaderImplementationEnd;
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Integer','a','');
  AssertPropertyMap('b','Integer','b','');
end;

procedure TTestGenCode.TestLoadIntegerCaseInsensitiveProperty;
begin
  Gen.Options:=[jpoGenerateLoad,jpoLoadCaseInsensitive];
  GenCode('{ "A" : 1234 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('A','integer');
  AssertVisibility('public');
  AssertLoadConstructorDeclaration('TJSONData');
  AssertLoaderDeclaration('TJSONData');
  AssertProperty('A','integer',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertLoadConstructorImplementationStart('TMyObject','TJSONData');
  AssertLoaderImplementationStart('TMyObject','TJSONData',False);
  TestContext.AssertTrue(Pos('''a'':',NextLine)>0, 'Have "a" integer property case');
  TestContext.AssertTrue(Pos('A:=E.Value.AsInteger;',NextLine)>0, 'Have "a" integer property set');
  AssertLoaderImplementationEnd;
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('A','Integer','A','');
end;

procedure TTestGenCode.TestLoadStringProperty;
begin
  Gen.Options:=[jpoGenerateLoad];
  GenCode('{ "a" : "1234" }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','string');
  AssertVisibility('public');
  AssertLoadConstructorDeclaration('TJSONData');
  AssertLoaderDeclaration('TJSONData');
  AssertProperty('a','string',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertLoadConstructorImplementationStart('TMyObject','TJSONData');
  AssertLoaderImplementationStart('TMyObject','TJSONData');
  TestContext.AssertTrue(Pos('''a'':',NextLine)>0, 'Have "a" string property case');
  TestContext.AssertTrue(Pos('a:=E.Value.AsString;',NextLine)>0, 'Have "a" string property set');
  AssertLoaderImplementationEnd;
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','String','a','');
end;

procedure TTestGenCode.TestLoadBooleanProperty;
begin
  Gen.Options:=[jpoGenerateLoad];
  GenCode('{ "a" : true }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','boolean');
  AssertVisibility('public');
  AssertLoadConstructorDeclaration('TJSONData');
  AssertLoaderDeclaration('TJSONData');
  AssertProperty('a','boolean',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertLoadConstructorImplementationStart('TMyObject','TJSONData');
  AssertLoaderImplementationStart('TMyObject','TJSONData');
  TestContext.AssertTrue(Pos('''a'':',NextLine)>0, 'Have "a" boolean property case');
  TestContext.AssertTrue(Pos('a:=E.Value.AsBoolean;',NextLine)>0, 'Have "a" boolean property set');
  AssertLoaderImplementationEnd;
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Boolean','a','');
end;

procedure TTestGenCode.TestLoadInt64Property;
begin
  Gen.Options:=[jpoGenerateLoad];
  GenCode('{ "a" : 1234567890123 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Int64');
  AssertVisibility('public');
  AssertLoadConstructorDeclaration('TJSONData');
  AssertLoaderDeclaration('TJSONData');
  AssertProperty('a','Int64',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertLoadConstructorImplementationStart('TMyObject','TJSONData');
  AssertLoaderImplementationStart('TMyObject','TJSONData');
  TestContext.AssertTrue(Pos('''a'':',NextLine)>0, 'Have "a" Int64 property case');
  TestContext.AssertTrue(Pos('a:=E.Value.AsInt64;',NextLine)>0, 'Have "a" Int64 property set');
  AssertLoaderImplementationEnd;
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Int64','a','');
end;

procedure TTestGenCode.TestLoadFloatProperty;
begin
  Gen.Options:=[jpoGenerateLoad];
  GenCode('{ "a" : 1.1 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Double');
  AssertVisibility('public');
  AssertLoadConstructorDeclaration('TJSONData');
  AssertLoaderDeclaration('TJSONData');
  AssertProperty('a','Double',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertLoadConstructorImplementationStart('TMyObject','TJSONData');
  AssertLoaderImplementationStart('TMyObject','TJSONData');
  TestContext.AssertTrue(Pos('''a'':',NextLine)>0, 'Have "a" Double property case');
  TestContext.AssertTrue(Pos('a:=E.Value.AsFloat;',NextLine)>0, 'Have "a" Double property set');
  AssertLoaderImplementationEnd;
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Double','a','');
end;

procedure TTestGenCode.TestLoadObjectProperty;
begin
  Gen.Options:=[jpoGenerateLoad];
  GenCode('{ "a" : { "b" : "abc" } }');
  AssertUnitHeader;
  AssertClassHeader('Ta','TObject');
  AssertField('b','String');
  AssertVisibility('public');
  AssertLoadConstructorDeclaration('TJSONData');
  AssertLoaderDeclaration('TJSONData');
  AssertProperty('b','String',False);
  AssertEnd;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Ta');
  AssertVisibility('public');
  AssertDestructor;
  AssertLoadConstructorDeclaration('TJSONData');
  AssertLoaderDeclaration('TJSONData');
  AssertProperty('a','ta',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','Ta');
  AssertLoadConstructorImplementationStart('Ta','TJSONData');
  AssertLoaderImplementationStart('Ta','TJSONData');
  TestContext.AssertTrue(Pos('''b'':',NextLine)>0, 'Have "b" string property case');
  TestContext.AssertTrue(Pos('b:=E.Value.AsString;',NextLine)>0, 'Have "b" string property set');
  AssertLoaderImplementationEnd;
  AssertClassComment('Object Implementation','TMyObject');
  AssertDestructorImplementation('TMyObject',['a']);
  AssertLoadConstructorImplementationStart('TMyObject','TJSONData');
  AssertObjectLoaderImplementationStart('TMyObject','TJSONData','a','Ta','');
  TestContext.AssertTrue(Pos('''a'':',NextLine)>0, 'Have "a" object property case');
  TestContext.AssertTrue(Pos('a:=ta.CreateFromJSON(E.Value);',NextLine)>0, 'Have "a" object create createfromjson');
  AssertLoaderImplementationEnd;
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Ta','a','TObject');
end;

procedure TTestGenCode.AssertArrayCreator(const ArrayTypeName,
  AElementType: String; IsDelphi: Boolean);

Var
  S : String;

begin
  S:=NextLine;
  TestContext.AssertTrue(Pos('Function Create'+ArrayTypeName+'(AJSON : '+GetDataName(IsDelphi)+') : '+ArrayTypeName,S)>0, 'Have array creator in '+S);
end;

procedure TTestGenCode.AssertArraySaver(const ArrayTypeName,
  AElementType: String; IsDelphi: Boolean);

Var
  E,S : String;

begin
  S:=NextLine;
  E:='Procedure Save'+ArrayTypeName+'ToJSON(AnArray : '+ArrayTypeName+'; AJSONArray : TJSONArray);';
  TestContext.AssertTrue(Pos(E,S)>0, 'Have proc array saver in '+S);
  S:=NextLine;
  E:='Function Save'+ArrayTypeName+'ToJSON(AnArray : '+ArrayTypeName+') : TJSONArray;';
  TestContext.AssertTrue(Pos(E,S)>0, 'Have func array saver in '+S);
end;

procedure TTestGenCode.AssertArrayCreatorImplementation(const ArrayTypeName,
  AElementType: String; AObjectName: String; IsDelphi: Boolean);

Var
  S,E,AN : String;

begin
  S:=NextLine;
  E:='Function Create'+ARrayTypeName+'(AJSON : '+GetDataName(IsDelphi)+') : '+ArrayTypeName;
  TestContext.AssertTrue(Pos(E,S)>0, 'Have array creator header '+S+'Expected : '+E);
  TestContext.AssertTrue(Pos('var',NextLine)>0, 'Have var');
  TestContext.AssertTrue(Pos('I : Integer;',NextLine)>0, 'Have loop var');
  if IsDelphi then
    begin
    TestContext.AssertTrue(Pos('A : TJSONArray;',NextLine)>0, 'Have Array var');
    AN:='A'
    end
  else
    AN:='AJSON';
  AssertBegin;
  if IsDelphi then
    TestContext.AssertTrue(Pos('A:=AJSON as TJSONArray;',NextLine)>0, 'Have Array assignnment');
  TestContext.AssertTrue(Pos('SetLength(Result,'+AN+'.Count);',NextLine)>0, 'Have array setlength ');
  TestContext.AssertTrue(Pos('for i:=0 to '+AN+'.Count-1 do',NextLine)>0, 'Have loop ');
  if AObjectName='' then
    begin
    if IsDelphi then
      TestContext.AssertTrue(Pos('Result[i]:='+AN+'.Items[i].GetValue<'+AElementType+'>;',NextLine)>0, 'Have element assignment : '+AElementType)
    else
      TestContext.AssertTrue(Pos('Result[i]:='+AN+'.Items[i].'+AElementType+';',NextLine)>0, 'Have element assignment : '+AElementType)
    end
  else
    TestContext.AssertTrue(Pos('Result[i]:='+AObjectName+'.CreateFromJSON('+AN+'.Items[i]);',NextLine)>0, 'Have element assignment : '+AElementType);
  AssertEnd;
end;

procedure TTestGenCode.AssertLine(Msg : String; AExpected : String);

Var
  N,DMsg : String;

begin
  N:=NextLine;
  DMsg:=Msg+', Expected: "'+AExpected+'", Actual: "'+N+'"';
  TestContext.AssertTrue(Pos(AExpected,N)>0, Dmsg);
end;

procedure TTestGenCode.AssertArraySaverImplementation(const ArrayTypeName,
  AElementType: String; AObjectName: String; IsDelphi: Boolean);
Var
  N,S,E,AN : String;

begin
  N:=ArrayTypeName+'Saver : ';
  S:=NextLine;
  E:='Function Save'+ArrayTypeName+'ToJSON(AnArray : '+ArrayTypeName+') : TJSONArray;';
  TestContext.AssertTrue(Pos(E,S)>0, N+'header');
  AssertBegin;
  TestContext.AssertTrue(Pos('Result:=TJSONArray.Create',NextLine)>0, N+'Create');
  TestContext.AssertTrue(Pos('Try',NextLine)>0, N+'Try');
  S:=NextLine;
  E:='Save'+ArrayTypeName+'ToJSON(AnArray,Result);';
  TestContext.AssertTrue(Pos(E,S)>0, N+'Save');
  TestContext.AssertTrue(Pos('except',NextLine)>0, N+'except');
  TestContext.AssertTrue(Pos('FreeAndNil(Result);',NextLine)>0, N+'FreeAndNil');
  TestContext.AssertTrue(Pos('Raise;',NextLine)>0, N+'Reraise');
  TestContext.AssertTrue(Pos('End;',NextLine)>0, N+'end;');
  TestContext.AssertTrue(Pos('End;',NextLine)>0, N+'end;');
  S:=NextLine;
  E:='Procedure Save'+ArrayTypeName+'ToJSON(AnArray : '+ArrayTypeName+'; AJSONArray : TJSONArray);';
  TestContext.AssertTrue(Pos(E,S)>0, 'Have array saver header '+S+'Expected : '+E);
  TestContext.AssertTrue(Pos('var',NextLine)>0, 'Have var');
  TestContext.AssertTrue(Pos('I : Integer;',NextLine)>0, 'Have loop var');
  AssertBegin;
  TestContext.AssertTrue(Pos('for i:=0 to Length(AnArray)-1 do',NextLine)>0, 'Have loop ');
  if AObjectName='' then
    AssertLine('Have element assignment : '+AElementType,'AJSONArray.Add(AnArray[i]);')
{  else if AObjectName='' then
    AssertLine('Have element assignment : '+AElementType,'AJSONArray.Add('+AN+'[i]);')}
  else
     TestContext.AssertTrue(Pos('AJSONArray.Add(AnArray[i].SaveToJSON);',NextLine)>0, 'Have element assignment : '+AElementType);
  AssertEnd;
end;

procedure TTestGenCode.AssertType;

begin
  TestContext.AssertTrue(Pos('Type',NextLine)>0, 'Have Type keyword');
end;

procedure TTestGenCode.AssertDelphiLoadArray(AElementType, AJSONtype : String);

begin
  AssertUnitHeader;
  AssertArrayType('Ta',AElementType);
  AssertArrayCreator('Ta',AElementType,true);
  AssertType;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Ta');
  AssertVisibility('public');
  AssertLoadConstructorDeclaration('TJSONValue');
  AssertLoaderDeclaration('TJSONValue');
  AssertProperty('a','ta',False);
  AssertEnd;
  AssertImplementation;
  AssertArrayCreatorImplementation('Ta',AJSONType,'',True);
  AssertClassComment('Object Implementation','TMyObject');
  AssertLoadConstructorImplementationStart('TMyObject','TJSONValue');
  AssertArrayLoaderImplementationStart('TMyObject','TJSONValue','a','Ta',AJSONType);
  TestContext.AssertTrue(Pos('If (PN=''a'') then',NextLine)>0, 'Have "a" property if');
  TestContext.AssertTrue(Pos('a:=CreateTa(P.Value);',NextLine)>0, 'Have "a" property set with createarray');
  AssertLoaderImplementationEnd;
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Ta','a','');
end;

class function TTestGenCode.GetDataName(IsDelphi: Boolean): string;

begin
  if IsDelphi then
    Result:='TJSONValue'
  else
    Result:='TJSONData';
end;

procedure TTestGenCode.AssertLoadArray(AElementType, AJSONtype: String;
  IsDelphi: Boolean = False);

Var
  DN : String;

begin
  AssertUnitHeader;
  DN:=GetDataName(IsDelphi);
  AssertArrayType('Ta',AElementType);
  AssertArrayCreator('Ta',AElementType,IsDelphi);
  AssertType;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Ta');
  AssertVisibility('public');
  AssertLoadConstructorDeclaration(DN);
  AssertLoaderDeclaration(DN);
  AssertProperty('a','ta',False);
  AssertEnd;
  AssertImplementation;
  AssertArrayCreatorImplementation('Ta',AJSONType,'',IsDelphi);
  AssertClassComment('Object Implementation','TMyObject');
  AssertLoadConstructorImplementationStart('TMyObject',DN);
  AssertArrayLoaderImplementationStart('TMyObject',DN,'a','Ta',AJSONType,isDelphi);
  if IsDelphi then
    begin
    TestContext.AssertTrue(Pos('If (PN=''a'') then',NextLine)>0, 'Have "a" property if');
    TestContext.AssertTrue(Pos('a:=CreateTa(P.JSONValue);',NextLine)>0, 'Have "a" property set with createarray');
    end
  else
    begin
    TestContext.AssertTrue(Pos('''a'':',NextLine)>0, 'Have "a" array property case');
    TestContext.AssertTrue(Pos('a:=CreateTa(E.Value);',NextLine)>0, 'Have "a" property set with createarray');
    end;
  AssertLoaderImplementationEnd(IsDelphi);
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Ta','a','');
end;

procedure TTestGenCode.AssertSaveArray(AElementType, AJSONtype: String; IsDelphi: Boolean = False);
begin
  AssertUnitHeader;
  AssertArrayType('Ta',AElementType);
  AssertArraySaver('Ta',AElementType,IsDelphi);
  AssertType;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Ta');
  AssertVisibility('public');
  AssertSaverDeclaration;
  AssertProperty('a','ta',False);
  AssertEnd;
  AssertImplementation;
  AssertArraySaverImplementation('Ta',AJSONType,'',IsDelphi);
  AssertClassComment('Object Implementation','TMyObject');
  AssertSaverImplementationStart('TMyObject');
  if IsDelphi then
    TestContext.AssertTrue(Pos('AJSON.AddPair(''a'',SaveTaToJSON(a));',NextLine)>0, 'Array save statement')
  else
    TestContext.AssertTrue(Pos('AJSON.Add(''a'',SaveTaToJSON(a));',NextLine)>0, 'Array save statement');
  AssertEnd('Saver');
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Ta','a','');
end;

procedure TTestGenCode.TestLoadStringArrayProperty;
begin
  Gen.Options:=[jpoGenerateLoad];
  GenCode('{ "a" : [ "abc" ] }');
  AssertLoadArray('string','AsString');
end;

procedure TTestGenCode.TestLoadBooleanArrayProperty;
begin
  Gen.Options:=[jpoGenerateLoad];
  GenCode('{ "a" : [ true ] }');
  AssertLoadArray('boolean','AsBoolean');
end;

procedure TTestGenCode.TestLoadIntegerArrayProperty;
begin
  Gen.Options:=[jpoGenerateLoad];
  GenCode('{ "a" : [ 123 ] }');
  AssertLoadArray('Integer','AsInteger');
end;

procedure TTestGenCode.TestLoadInt64ArrayProperty;
begin
  Gen.Options:=[jpoGenerateLoad];
  GenCode('{ "a" : [ 1234567890123 ] }');
  AssertLoadArray('Int64','AsInt64');
end;

procedure TTestGenCode.TestLoadFloatArrayProperty;
begin
  Gen.Options:=[jpoGenerateLoad];
  GenCode('{ "a" : [ 12.34 ] }');
  AssertLoadArray('Double','AsFloat');
end;

procedure TTestGenCode.TestLoadDelphiIntegerProperty;

begin
  Gen.Options:=[jpoGenerateLoad,jpoDelphiJSON];
  GenCode('{ "a" : 1234 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','integer');
  AssertVisibility('public');
  AssertLoadConstructorDeclaration('TJSONValue');
  AssertLoaderDeclaration('TJSONValue');
  AssertProperty('a','integer',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertLoadConstructorImplementationStart('TMyObject','TJSONValue');
  AssertLoaderImplementationStart('TMyObject','TJSONValue',True);
  TestContext.AssertTrue(Pos('If (PN=''a'') then',NextLine)>0, 'Have "a" integer property case ');
  TestContext.AssertTrue(Pos('a:=P.JSONValue.GetValue<Integer>;',NextLine)>0, 'Have "a" integer property set');
  AssertLoaderImplementationEnd(True);
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Integer','a','');
end;

procedure TTestGenCode.TestLoadDelphi2IntegersProperty;

Var
  S : String;

begin
  Gen.Options:=[jpoGenerateLoad,jpoDelphiJSON];
  GenCode('{ "a" : 1234, "b" : 5678 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','integer');
  AssertField('b','integer');
  AssertVisibility('public');
  AssertLoadConstructorDeclaration('TJSONValue');
  AssertLoaderDeclaration('TJSONValue');
  AssertProperty('a','integer',False);
  AssertProperty('b','integer',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertLoadConstructorImplementationStart('TMyObject','TJSONValue');
  AssertLoaderImplementationStart('TMyObject','TJSONValue',True);
  TestContext.AssertTrue(Pos('If (PN=''a'') then',NextLine)>0, 'Have "a" integer property case ');
  S:=NextLine;
  TestContext.AssertTrue(Pos('a:=P.JSONValue.GetValue<Integer>',S)>0, 'Have "a" integer property set');
  TestContext.AssertTrue(Pos(';',S)=0, 'Have no semicolon');
  TestContext.AssertTrue(Pos('Else If (PN=''b'') then',NextLine)>0, 'Have else  "b" integer property case ');
  TestContext.AssertTrue(Pos('b:=P.JSONValue.GetValue<Integer>;',NextLine)>0, 'Have "b" integer property set');
  AssertLoaderImplementationEnd(True);
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Integer','a','');
  AssertPropertyMap('b','Integer','b','');
end;

procedure TTestGenCode.TestLoadDelphiIntegerWithErrorProperty;

Var
  S : String;

begin
  Gen.Options:=[jpoGenerateLoad,jpoDelphiJSON,jpoUnknownLoadPropsError];
  GenCode('{ "a" : 1234, "b" : 5678 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','integer');
  AssertField('b','integer');
  AssertVisibility('public');
  AssertLoadConstructorDeclaration('TJSONValue');
  AssertLoaderDeclaration('TJSONValue');
  AssertProperty('a','integer',False);
  AssertProperty('b','integer',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertLoadConstructorImplementationStart('TMyObject','TJSONValue');
  AssertLoaderImplementationStart('TMyObject','TJSONValue',True);
  TestContext.AssertTrue(Pos('If (PN=''a'') then',NextLine)>0, 'Have "a" integer property case ');
  S:=NextLine;
  TestContext.AssertTrue(Pos('a:=P.JSONValue.GetValue<Integer>',S)>0, 'Have "a" integer property set');
  TestContext.AssertTrue(Pos(';',S)=0, 'Have no semicolon for a');
  TestContext.AssertTrue(Pos('If (PN=''b'') then',NextLine)>0, 'Have "b" integer property case ');
  S:=NextLine;
  TestContext.AssertTrue(Pos('b:=P.JSONValue.GetValue<Integer>',S)>0, 'Have "b" integer property set');
  TestContext.AssertTrue(Pos(';',S)=0, 'Have no semicolon for b');
  TestContext.AssertTrue(Pos('else',NextLine)>0, 'Have case else');
  TestContext.AssertTrue(Pos('Raise EJSONException.CreateFmt',NextLine)>0, 'Have raise statement');
  AssertLoaderImplementationEnd(True);
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Integer','a','');
  AssertPropertyMap('b','Integer','b','');
end;

procedure TTestGenCode.TestLoadDelphiIntegerCaseInsensitiveProperty;
begin
  Gen.Options:=[jpoGenerateLoad,jpoDelphiJSON,jpoLoadCaseInsensitive];
  GenCode('{ "A" : 1234 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('A','integer');
  AssertVisibility('public');
  AssertLoadConstructorDeclaration('TJSONValue');
  AssertLoaderDeclaration('TJSONValue');
  AssertProperty('A','integer',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertLoadConstructorImplementationStart('TMyObject','TJSONValue');
  AssertLoaderImplementationStart('TMyObject','TJSONValue',True);
  TestContext.AssertTrue(Pos('If (PN=''a'') then',NextLine)>0, 'Have "a" integer property case');
  TestContext.AssertTrue(Pos('A:=P.JSONValue.GetValue<Integer>;',NextLine)>0, 'Have "A" integer property set');
  AssertLoaderImplementationEnd(True);
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('A','Integer','A','');
end;

procedure TTestGenCode.TestLoadDelphiStringProperty;
begin
  Gen.Options:=[jpoGenerateLoad,jpoDelphiJSON];
  GenCode('{ "a" : "1234" }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','String');
  AssertVisibility('public');
  AssertLoadConstructorDeclaration('TJSONValue');
  AssertLoaderDeclaration('TJSONValue');
  AssertProperty('a','string',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertLoadConstructorImplementationStart('TMyObject','TJSONValue');
  AssertLoaderImplementationStart('TMyObject','TJSONValue',True);
  TestContext.AssertTrue(Pos('If (PN=''a'') then',NextLine)>0, 'Have "a" integer property case');
  TestContext.AssertTrue(Pos('a:=P.JSONValue.GetValue<String>;',NextLine)>0, 'Have "a" integer property set');
  AssertLoaderImplementationEnd(True);
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','String','a','');
end;

procedure TTestGenCode.TestLoadDelphiBooleanProperty;
begin
  Gen.Options:=[jpoGenerateLoad,jpoDelphiJSON];
  GenCode('{ "a" : true }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','boolean');
  AssertVisibility('public');
  AssertLoadConstructorDeclaration('TJSONValue');
  AssertLoaderDeclaration('TJSONValue');
  AssertProperty('a','boolean',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertLoadConstructorImplementationStart('TMyObject','TJSONValue');
  AssertLoaderImplementationStart('TMyObject','TJSONValue',True);
  TestContext.AssertTrue(Pos('If (PN=''a'') then',NextLine)>0, 'Have "a" integer property case');
  TestContext.AssertTrue(Pos('a:=P.JSONValue.GetValue<Boolean>;',NextLine)>0, 'Have "a" integer property set');
  AssertLoaderImplementationEnd(True);
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Boolean','a','');
end;

procedure TTestGenCode.TestLoadDelphiInt64Property;
begin
  Gen.Options:=[jpoGenerateLoad,jpoDelphiJSON];
  GenCode('{ "a" : 1234567890123 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Int64');
  AssertVisibility('public');
  AssertLoadConstructorDeclaration('TJSONValue');
  AssertLoaderDeclaration('TJSONValue');
  AssertProperty('a','Int64',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertLoadConstructorImplementationStart('TMyObject','TJSONValue');
  AssertLoaderImplementationStart('TMyObject','TJSONValue',True);
  TestContext.AssertTrue(Pos('If (PN=''a'') then',NextLine)>0, 'Have "a" integer property case');
  TestContext.AssertTrue(Pos('a:=P.JSONValue.GetValue<Int64>;',NextLine)>0, 'Have "a" integer property set');
  AssertLoaderImplementationEnd(True);
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Int64','a','');
end;

procedure TTestGenCode.TestLoadDelphiFloatProperty;
begin
  Gen.Options:=[jpoGenerateLoad,jpoDelphiJSON];
  GenCode('{ "a" : 1.1 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Double');
  AssertVisibility('public');
  AssertLoadConstructorDeclaration('TJSONValue');
  AssertLoaderDeclaration('TJSONValue');
  AssertProperty('a','Double',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertLoadConstructorImplementationStart('TMyObject','TJSONValue');
  AssertLoaderImplementationStart('TMyObject','TJSONValue',True);
  TestContext.AssertTrue(Pos('If (PN=''a'') then',NextLine)>0, 'Have "a" integer property case');
  TestContext.AssertTrue(Pos('a:=P.JSONValue.GetValue<Double>;',NextLine)>0, 'Have "a" integer property set');
  AssertLoaderImplementationEnd(True);
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Double','a','');
end;

procedure TTestGenCode.TestLoadDelphiObjectProperty;
begin
  Gen.Options:=[jpoGenerateLoad,jpoDelphiJSON];
  GenCode('{ "a" : { "b" : "abc" } }');
  AssertUnitHeader;
  AssertClassHeader('Ta','TObject');
  AssertField('b','String');
  AssertVisibility('public');
  AssertLoadConstructorDeclaration('TJSONValue');
  AssertLoaderDeclaration('TJSONValue');
  AssertProperty('b','String',False);
  AssertEnd;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Ta');
  AssertVisibility('public');
  AssertDestructor;
  AssertLoadConstructorDeclaration('TJSONValue');
  AssertLoaderDeclaration('TJSONValue');
  AssertProperty('a','ta',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','Ta');
  AssertLoadConstructorImplementationStart('Ta','TJSONValue');
  AssertLoaderImplementationStart('Ta','TJSONValue',True);
  TestContext.AssertTrue(Pos('If (PN=''b'') then',NextLine)>0, 'Have "b" string property case');
  TestContext.AssertTrue(Pos('b:=P.JSONValue.GetValue<String>;',NextLine)>0, 'Have "b" string property set');
  AssertLoaderImplementationEnd(True);
  AssertClassComment('Object Implementation','TMyObject');
  AssertDestructorImplementation('TMyObject',['a']);
  AssertLoadConstructorImplementationStart('TMyObject','TJSONValue');
  AssertObjectLoaderImplementationStart('TMyObject','TJSONValue','a','Ta','',True);
  TestContext.AssertTrue(Pos('If (PN=''a'') then',NextLine)>0, 'Have "a" object property case');
  TestContext.AssertTrue(Pos('a:=ta.CreateFromJSON(P.JSONValue);',NextLine)>0, 'Have "a" object create createfromjson');
  AssertLoaderImplementationEnd(True);
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Ta','a','TObject');
end;

procedure TTestGenCode.TestSaveIntegerProperty;
begin
  Gen.Options:=[jpoGenerateSave];
  GenCode('{ "a" : 1234 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','integer');
  AssertVisibility('public');
  AssertSaverDeclaration;
  AssertProperty('a','integer',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertSaverImplementationStart('TMyObject');
  TestContext.AssertTrue(Pos('AJSON.Add(''a'',a);',NextLine)>0, 'Have "a" integer property save');
  TestContext.AssertTrue(Pos('end;',NextLine)>0, 'end');
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Integer','a','');
end;

procedure TTestGenCode.TestSave2IntegersProperty;
begin
  Gen.Options:=[jpoGenerateSave];
  GenCode('{ "a" : 1234, "b" : 5678 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','integer');
  AssertField('b','integer');
  AssertVisibility('public');
  AssertSaverDeclaration;
  AssertProperty('a','integer',False);
  AssertProperty('b','integer',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertSaverImplementationStart('TMyObject');
  TestContext.AssertTrue(Pos('AJSON.Add(''a'',a);',NextLine)>0, 'Have "a" integer property save');
  TestContext.AssertTrue(Pos('AJSON.Add(''b'',b);',NextLine)>0, 'Have "b" integer property save');
  TestContext.AssertTrue(Pos('end;',NextLine)>0, 'end');
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Integer','a','');
  AssertPropertyMap('b','Integer','b','');
end;

procedure TTestGenCode.TestSaveStringProperty;
begin
  Gen.Options:=[jpoGenerateSave];
  GenCode('{ "a" : "1234" }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','string');
  AssertVisibility('public');
  AssertSaverDeclaration;
  AssertProperty('a','string',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertSaverImplementationStart('TMyObject');
  TestContext.AssertTrue(Pos('AJSON.Add(''a'',a);',NextLine)>0, 'Have "a" integer property save');
  TestContext.AssertTrue(Pos('end;',NextLine)>0, 'end');
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','String','a','');
end;

procedure TTestGenCode.TestSaveBooleanProperty;
begin
  Gen.Options:=[jpoGenerateSave];
  GenCode('{ "a" : true }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Boolean');
  AssertVisibility('public');
  AssertSaverDeclaration;
  AssertProperty('a','Boolean',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertSaverImplementationStart('TMyObject');
  TestContext.AssertTrue(Pos('AJSON.Add(''a'',a);',NextLine)>0, 'Have "a" boolean property save');
  TestContext.AssertTrue(Pos('end;',NextLine)>0, 'end');
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Boolean','a','');
end;

procedure TTestGenCode.TestSaveInt64Property;
begin
  Gen.Options:=[jpoGenerateSave];
  GenCode('{ "a" : 1234567890123 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Int64');
  AssertVisibility('public');
  AssertSaverDeclaration;
  AssertProperty('a','Int64',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertSaverImplementationStart('TMyObject');
  TestContext.AssertTrue(Pos('AJSON.Add(''a'',a);',NextLine)>0, 'Have "a" int64 property save');
  TestContext.AssertTrue(Pos('end;',NextLine)>0, 'end');
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Int64','a','');
end;

procedure TTestGenCode.TestSaveFloatProperty;
begin
  Gen.Options:=[jpoGenerateSave];
  GenCode('{ "a" : 1.2 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','double');
  AssertVisibility('public');
  AssertSaverDeclaration;
  AssertProperty('a','double',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertSaverImplementationStart('TMyObject');
  TestContext.AssertTrue(Pos('AJSON.Add(''a'',a);',NextLine)>0, 'Have "a" integer property save');
  TestContext.AssertTrue(Pos('end;',NextLine)>0, 'end');
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Double','a','');

end;

procedure TTestGenCode.TestSaveObjectProperty;
begin
  Gen.Options:=[jpoGenerateSave];
  GenCode('{ "a" : { "b" : "abc" } }');
  AssertUnitHeader;
  AssertClassHeader('Ta','TObject');
  AssertField('b','String');
  AssertVisibility('public');
  AssertSaverDeclaration;
  AssertProperty('b','String',False);
  AssertEnd;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Ta');
  AssertVisibility('public');
  AssertDestructor;
  AssertSaverDeclaration;
  AssertProperty('a','ta',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','Ta');
  AssertSaverImplementationStart('Ta');
  TestContext.AssertTrue(Pos('AJSON.Add(''b'',b);',NextLine)>0, 'Have "b" property save');
  AssertEnd;
  AssertClassComment('Object Implementation','TMyObject');
  AssertDestructorImplementation('TMyObject',['a']);
  AssertSaverImplementationStart('TMyObject');
  TestContext.AssertTrue(Pos('if Assigned(a) then',NextLine)>0, 'Have check for assigned object property save');
  TestContext.AssertTrue(Pos('AJSON.Add(''a'',a.SaveToJSON);',NextLine)>0, 'Have "a" object property save');
  AssertEnd;
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Ta','a','TObject');
end;

procedure TTestGenCode.TestSaveStringArrayProperty;
begin
  Gen.Options:=[jpoGenerateSave];
  GenCode('{ "a" : [ "abc" ] }');
  AssertSaveArray('string','');
end;

procedure TTestGenCode.TestSaveBooleanArrayProperty;
begin
  Gen.Options:=[jpoGenerateSave];
  GenCode('{ "a" : [ true ] }');
  AssertSaveArray('boolean','');
end;

procedure TTestGenCode.TestSaveIntegerArrayProperty;
begin
  Gen.Options:=[jpoGenerateSave];
  GenCode('{ "a" : [ 123 ] }');
  AssertSaveArray('Integer','');
end;

procedure TTestGenCode.TestSaveInt64ArrayProperty;
begin
  Gen.Options:=[jpoGenerateSave];
  GenCode('{ "a" : [ 1234567890123 ] }');
  AssertSaveArray('Int64','');
end;

procedure TTestGenCode.TestSaveFloatArrayProperty;
begin
  Gen.Options:=[jpoGenerateSave];
  GenCode('{ "a" : [ 1.23] }');
  AssertSaveArray('Double','');
end;

procedure TTestGenCode.TestSaveDelphiIntegerProperty;
begin
  Gen.Options:=[jpoGenerateSave,jpoDelphiJSON];
  GenCode('{ "a" : 1234 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','integer');
  AssertVisibility('public');
  AssertSaverDeclaration;
  AssertProperty('a','integer',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertSaverImplementationStart('TMyObject');
  TestContext.AssertTrue(Pos('AJSON.AddPair(''a'',TJSONNumber.Create(a));',NextLine)>0, 'Have "a" integer property save');
  TestContext.AssertTrue(Pos('end;',NextLine)>0, 'end');
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Integer','a','');
end;

procedure TTestGenCode.TestSaveDelphi2IntegersProperty;
begin
  Gen.Options:=[jpoGenerateSave,jpoDelphiJSON];
  GenCode('{ "a" : 1234, "b" : 5678 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','integer');
  AssertField('b','integer');
  AssertVisibility('public');
  AssertSaverDeclaration;
  AssertProperty('a','integer',False);
  AssertProperty('b','integer',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertSaverImplementationStart('TMyObject');
  TestContext.AssertTrue(Pos('AJSON.AddPair(''a'',TJSONNumber.Create(a));',NextLine)>0, 'Have "a" integer property save');
  TestContext.AssertTrue(Pos('AJSON.AddPair(''b'',TJSONNumber.Create(b));',NextLine)>0, 'Have "b" integer property save');
  TestContext.AssertTrue(Pos('end;',NextLine)>0, 'end');
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Integer','a','');
  AssertPropertyMap('b','Integer','b','');
end;

procedure TTestGenCode.TestSaveDelphiStringProperty;
begin
  Gen.Options:=[jpoGenerateSave,jpoDelphiJSON];
  GenCode('{ "a" : "1234" }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','string');
  AssertVisibility('public');
  AssertSaverDeclaration;
  AssertProperty('a','string',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertSaverImplementationStart('TMyObject');
  TestContext.AssertTrue(Pos('AJSON.AddPair(''a'',TJSONString.Create(a));',NextLine)>0, 'Have "a" string property save');
  TestContext.AssertTrue(Pos('end;',NextLine)>0, 'end');
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','String','a','');
end;

procedure TTestGenCode.TestSaveDelphiBooleanProperty;
begin
  Gen.Options:=[jpoGenerateSave,jpoDelphiJSON];
  GenCode('{ "a" : true }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Boolean');
  AssertVisibility('public');
  AssertSaverDeclaration;
  AssertProperty('a','Boolean',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertSaverImplementationStart('TMyObject');
  TestContext.AssertTrue(Pos('AJSON.AddPair(''a'',TJSONBoolean.Create(a));',NextLine)>0, 'Have "a" Boolean property save');
  TestContext.AssertTrue(Pos('end;',NextLine)>0, 'end');
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Boolean','a','');
end;

procedure TTestGenCode.TestSaveDelphiInt64Property;
begin
  Gen.Options:=[jpoGenerateSave,jpoDelphiJSON];
  GenCode('{ "a" : 1234567890123 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Int64');
  AssertVisibility('public');
  AssertSaverDeclaration;
  AssertProperty('a','Int64',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertSaverImplementationStart('TMyObject');
  TestContext.AssertTrue(Pos('AJSON.AddPair(''a'',TJSONNumber.Create(a));',NextLine)>0, 'Have "a" int64 property save');
  TestContext.AssertTrue(Pos('end;',NextLine)>0, 'end');
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Int64','a','');
end;

procedure TTestGenCode.TestSaveDelphiFloatProperty;
Var
  S : String;
begin
  Gen.Options:=[jpoGenerateSave,jpoDelphiJSON];
  GenCode('{ "a" : 1.2 }');
  AssertUnitHeader;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','double');
  AssertVisibility('public');
  AssertSaverDeclaration;
  AssertProperty('a','double',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','TMyObject');
  AssertSaverImplementationStart('TMyObject');
  S:=NextLine;
  TestContext.AssertTrue(Pos('AJSON.AddPair(''a'',TJSONNumber.Create(a));',S)>0, 'Have "a" float property save');
  TestContext.AssertTrue(Pos('end;',NextLine)>0, 'end');
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Double','a','');
end;

procedure TTestGenCode.TestSaveDelphiObjectProperty;
Var
  S : String;
begin
  Gen.Options:=[jpoGenerateSave,jpoDelphiJSON];
  GenCode('{ "a" : { "b" : "abc" } }');
  AssertUnitHeader;
  AssertClassHeader('Ta','TObject');
  AssertField('b','String');
  AssertVisibility('public');
  AssertSaverDeclaration;
  AssertProperty('b','String',False);
  AssertEnd;
  AssertClassHeader('TMyObject','TObject');
  AssertField('a','Ta');
  AssertVisibility('public');
  AssertDestructor;
  AssertSaverDeclaration;
  AssertProperty('a','ta',False);
  AssertEnd;
  AssertImplementation;
  AssertClassComment('Object Implementation','Ta');
  AssertSaverImplementationStart('Ta');
  TestContext.AssertTrue(Pos('AJSON.AddPair(''b'',TJSONString.Create(b));',NextLine)>0, 'Have "b" string property save');
  AssertEnd;
  AssertClassComment('Object Implementation','TMyObject');
  AssertDestructorImplementation('TMyObject',['a']);
  AssertSaverImplementationStart('TMyObject');
  TestContext.AssertTrue(Pos('if Assigned(a) then',NextLine)>0, 'Have check for assigned object property save');
  S:=NextLine;
  TestContext.AssertTrue(Pos('AJSON.AddPair(''a'',a.SaveToJSON);',S)>0, 'Have "a" object property save');
  AssertEnd;
  AssertUnitEnd;
  AssertPropertyMap('','TMyObject','','TObject');
  AssertPropertyMap('a','Ta','a','TObject');
end;

procedure TTestGenCode.TestSaveDelphiStringArrayProperty;
begin
  Gen.Options:=[jpoGenerateSave,jpoDelphiJSON];
  GenCode('{ "a" : [ "abc" ] }');
  AssertSaveArray('string','',True);
end;

procedure TTestGenCode.TestSaveDelphiBooleanArrayProperty;
begin
  Gen.Options:=[jpoGenerateSave,jpoDelphiJSON];
  GenCode('{ "a" : [ true ] }');
  AssertSaveArray('boolean','',True);
end;

procedure TTestGenCode.TestSaveDelphiIntegerArrayProperty;
begin
  Gen.Options:=[jpoGenerateSave,jpoDelphiJSON];
  GenCode('{ "a" : [ 123 ] }');
  AssertSaveArray('Integer','',True);
end;

procedure TTestGenCode.TestSaveDelphiInt64ArrayProperty;
begin
  Gen.Options:=[jpoGenerateSave,jpoDelphiJSON];
  GenCode('{ "a" : [ 1234567890123 ] }');
  AssertSaveArray('Int64','',True);
end;

procedure TTestGenCode.TestSaveDelphiFloatArrayProperty;
begin
  Gen.Options:=[jpoGenerateSave,jpoDelphiJSON];
  GenCode('{ "a" : [ 1.23] }');
  AssertSaveArray('Double','',True);
end;

procedure TTestGenCode.TestLoadDelphiStringArrayProperty;
begin
  Gen.Options:=[jpoGenerateLoad, jpoDelphiJSON];
  GenCode('{ "a" : [ "abc" ] }');
  AssertLoadArray('string','String',True);
end;

procedure TTestGenCode.TestLoadDelphiBooleanArrayProperty;
begin
  Gen.Options:=[jpoGenerateLoad, jpoDelphiJSON];
  GenCode('{ "a" : [ true ] }');
  AssertLoadArray('boolean','Boolean',True);
end;

procedure TTestGenCode.TestLoadDelphiIntegerArrayProperty;
begin
  Gen.Options:=[jpoGenerateLoad, jpoDelphiJSON];
  GenCode('{ "a" : [ 12 ] }');
  AssertLoadArray('integer','Integer',True);
end;

procedure TTestGenCode.TestLoadDelphiInt64ArrayProperty;
begin
  Gen.Options:=[jpoGenerateLoad, jpoDelphiJSON];
  GenCode('{ "a" : [ 1234567890123 ] }');
  AssertLoadArray('int64','Int64',True);
end;

procedure TTestGenCode.TestLoadDelphiFloatArrayProperty;
begin
  Gen.Options:=[jpoGenerateLoad, jpoDelphiJSON];
  GenCode('{ "a" : [ 1.1 ] }');
  AssertLoadArray('double','Double',True);
end;



constructor TTestGenCode.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestGenCodeTestEmpty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestEmpty');
  try
    lFixture.SetUp;
    try lFixture.TestEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSimple(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSimple');
  try
    lFixture.SetUp;
    try lFixture.TestSimple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestClassName(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestClassName');
  try
    lFixture.SetUp;
    try lFixture.TestClassName; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestParentClassName(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestParentClassName');
  try
    lFixture.SetUp;
    try lFixture.TestParentClassName; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestIntegerProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestIntegerProperty');
  try
    lFixture.SetUp;
    try lFixture.TestIntegerProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTest2IntegersProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'Test2IntegersProperty');
  try
    lFixture.SetUp;
    try lFixture.Test2IntegersProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestBooleanProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestBooleanProperty');
  try
    lFixture.SetUp;
    try lFixture.TestBooleanProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestStringProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestStringProperty');
  try
    lFixture.SetUp;
    try lFixture.TestStringProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestFloatProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestFloatProperty');
  try
    lFixture.SetUp;
    try lFixture.TestFloatProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestInt64Property(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestInt64Property');
  try
    lFixture.SetUp;
    try lFixture.TestInt64Property; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestPropertySetter(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestPropertySetter');
  try
    lFixture.SetUp;
    try lFixture.TestPropertySetter; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestObjectProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestObjectProperty');
  try
    lFixture.SetUp;
    try lFixture.TestObjectProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestObjectPropertySetter(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestObjectPropertySetter');
  try
    lFixture.SetUp;
    try lFixture.TestObjectPropertySetter; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestObjectPropertySuffix(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestObjectPropertySuffix');
  try
    lFixture.SetUp;
    try lFixture.TestObjectPropertySuffix; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestObjectPropertySkip(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestObjectPropertySkip');
  try
    lFixture.SetUp;
    try lFixture.TestObjectPropertySkip; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestObjectPropertyRecurse(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestObjectPropertyRecurse');
  try
    lFixture.SetUp;
    try lFixture.TestObjectPropertyRecurse; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestObjectPropertyRecurseSuffix(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestObjectPropertyRecurseSuffix');
  try
    lFixture.SetUp;
    try lFixture.TestObjectPropertyRecurseSuffix; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestObjectPropertyRecurseSkip(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestObjectPropertyRecurseSkip');
  try
    lFixture.SetUp;
    try lFixture.TestObjectPropertyRecurseSkip; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestObjectPropertyRecurseSkipB(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestObjectPropertyRecurseSkipB');
  try
    lFixture.SetUp;
    try lFixture.TestObjectPropertyRecurseSkipB; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestStringArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestStringArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestStringArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestIntegerArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestIntegerArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestIntegerArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestBooleanArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestBooleanArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestBooleanArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestFloatArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestFloatArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestFloatArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestInt64ArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestInt64ArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestInt64ArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestStringArrayPropertySuffix(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestStringArrayPropertySuffix');
  try
    lFixture.SetUp;
    try lFixture.TestStringArrayPropertySuffix; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadIntegerProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadIntegerProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadIntegerProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoad2IntegersProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoad2IntegersProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoad2IntegersProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadIntegerWithErrorProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadIntegerWithErrorProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadIntegerWithErrorProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadIntegerCaseInsensitiveProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadIntegerCaseInsensitiveProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadIntegerCaseInsensitiveProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadStringProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadStringProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadStringProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadBooleanProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadBooleanProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadBooleanProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadInt64Property(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadInt64Property');
  try
    lFixture.SetUp;
    try lFixture.TestLoadInt64Property; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadFloatProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadFloatProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadFloatProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadObjectProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadObjectProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadObjectProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadStringArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadStringArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadStringArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadBooleanArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadBooleanArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadBooleanArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadIntegerArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadIntegerArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadIntegerArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadInt64ArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadInt64ArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadInt64ArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadFloatArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadFloatArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadFloatArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadDelphiIntegerProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadDelphiIntegerProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadDelphiIntegerProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadDelphi2IntegersProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadDelphi2IntegersProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadDelphi2IntegersProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadDelphiIntegerWithErrorProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadDelphiIntegerWithErrorProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadDelphiIntegerWithErrorProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadDelphiIntegerCaseInsensitiveProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadDelphiIntegerCaseInsensitiveProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadDelphiIntegerCaseInsensitiveProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadDelphiStringProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadDelphiStringProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadDelphiStringProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadDelphiBooleanProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadDelphiBooleanProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadDelphiBooleanProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadDelphiInt64Property(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadDelphiInt64Property');
  try
    lFixture.SetUp;
    try lFixture.TestLoadDelphiInt64Property; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadDelphiFloatProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadDelphiFloatProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadDelphiFloatProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadDelphiObjectProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadDelphiObjectProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadDelphiObjectProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadDelphiStringArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadDelphiStringArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadDelphiStringArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadDelphiBooleanArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadDelphiBooleanArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadDelphiBooleanArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadDelphiIntegerArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadDelphiIntegerArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadDelphiIntegerArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadDelphiInt64ArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadDelphiInt64ArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadDelphiInt64ArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestLoadDelphiFloatArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestLoadDelphiFloatArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestLoadDelphiFloatArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveIntegerProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveIntegerProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveIntegerProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSave2IntegersProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSave2IntegersProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSave2IntegersProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveStringProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveStringProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveStringProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveBooleanProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveBooleanProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveBooleanProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveInt64Property(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveInt64Property');
  try
    lFixture.SetUp;
    try lFixture.TestSaveInt64Property; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveFloatProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveFloatProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveFloatProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveObjectProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveObjectProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveObjectProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveStringArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveStringArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveStringArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveBooleanArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveBooleanArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveBooleanArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveIntegerArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveIntegerArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveIntegerArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveInt64ArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveInt64ArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveInt64ArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveFloatArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveFloatArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveFloatArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveDelphiIntegerProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveDelphiIntegerProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveDelphiIntegerProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveDelphi2IntegersProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveDelphi2IntegersProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveDelphi2IntegersProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveDelphiStringProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveDelphiStringProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveDelphiStringProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveDelphiBooleanProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveDelphiBooleanProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveDelphiBooleanProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveDelphiInt64Property(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveDelphiInt64Property');
  try
    lFixture.SetUp;
    try lFixture.TestSaveDelphiInt64Property; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveDelphiFloatProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveDelphiFloatProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveDelphiFloatProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveDelphiObjectProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveDelphiObjectProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveDelphiObjectProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveDelphiStringArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveDelphiStringArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveDelphiStringArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveDelphiBooleanArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveDelphiBooleanArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveDelphiBooleanArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveDelphiIntegerArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveDelphiIntegerArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveDelphiIntegerArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveDelphiInt64ArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveDelphiInt64ArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveDelphiInt64ArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGenCodeTestSaveDelphiFloatArrayProperty(AContext: TNXTestContext);
var lFixture: TTestGenCode;
begin
  lFixture:=TTestGenCode.Create(AContext, 'TestSaveDelphiFloatArrayProperty');
  try
    lFixture.SetUp;
    try lFixture.TestSaveDelphiFloatArrayProperty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegistertcjsontocodeTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcjsontocode.TTestGenCode');
  lSuite.AddTest('TestEmpty', @RunTTestGenCodeTestEmpty);
  lSuite.AddTest('TestSimple', @RunTTestGenCodeTestSimple);
  lSuite.AddTest('TestClassName', @RunTTestGenCodeTestClassName);
  lSuite.AddTest('TestParentClassName', @RunTTestGenCodeTestParentClassName);
  lSuite.AddTest('TestIntegerProperty', @RunTTestGenCodeTestIntegerProperty);
  lSuite.AddTest('Test2IntegersProperty', @RunTTestGenCodeTest2IntegersProperty);
  lSuite.AddTest('TestBooleanProperty', @RunTTestGenCodeTestBooleanProperty);
  lSuite.AddTest('TestStringProperty', @RunTTestGenCodeTestStringProperty);
  lSuite.AddTest('TestFloatProperty', @RunTTestGenCodeTestFloatProperty);
  lSuite.AddTest('TestInt64Property', @RunTTestGenCodeTestInt64Property);
  lSuite.AddTest('TestPropertySetter', @RunTTestGenCodeTestPropertySetter);
  lSuite.AddTest('TestObjectProperty', @RunTTestGenCodeTestObjectProperty);
  lSuite.AddTest('TestObjectPropertySetter', @RunTTestGenCodeTestObjectPropertySetter);
  lSuite.AddTest('TestObjectPropertySuffix', @RunTTestGenCodeTestObjectPropertySuffix);
  lSuite.AddTest('TestObjectPropertySkip', @RunTTestGenCodeTestObjectPropertySkip);
  lSuite.AddTest('TestObjectPropertyRecurse', @RunTTestGenCodeTestObjectPropertyRecurse);
  lSuite.AddTest('TestObjectPropertyRecurseSuffix', @RunTTestGenCodeTestObjectPropertyRecurseSuffix);
  lSuite.AddTest('TestObjectPropertyRecurseSkip', @RunTTestGenCodeTestObjectPropertyRecurseSkip);
  lSuite.AddTest('TestObjectPropertyRecurseSkipB', @RunTTestGenCodeTestObjectPropertyRecurseSkipB);
  lSuite.AddTest('TestStringArrayProperty', @RunTTestGenCodeTestStringArrayProperty);
  lSuite.AddTest('TestIntegerArrayProperty', @RunTTestGenCodeTestIntegerArrayProperty);
  lSuite.AddTest('TestBooleanArrayProperty', @RunTTestGenCodeTestBooleanArrayProperty);
  lSuite.AddTest('TestFloatArrayProperty', @RunTTestGenCodeTestFloatArrayProperty);
  lSuite.AddTest('TestInt64ArrayProperty', @RunTTestGenCodeTestInt64ArrayProperty);
  lSuite.AddTest('TestStringArrayPropertySuffix', @RunTTestGenCodeTestStringArrayPropertySuffix);
  lSuite.AddTest('TestLoadIntegerProperty', @RunTTestGenCodeTestLoadIntegerProperty);
  lSuite.AddTest('TestLoad2IntegersProperty', @RunTTestGenCodeTestLoad2IntegersProperty);
  lSuite.AddTest('TestLoadIntegerWithErrorProperty', @RunTTestGenCodeTestLoadIntegerWithErrorProperty);
  lSuite.AddTest('TestLoadIntegerCaseInsensitiveProperty', @RunTTestGenCodeTestLoadIntegerCaseInsensitiveProperty);
  lSuite.AddTest('TestLoadStringProperty', @RunTTestGenCodeTestLoadStringProperty);
  lSuite.AddTest('TestLoadBooleanProperty', @RunTTestGenCodeTestLoadBooleanProperty);
  lSuite.AddTest('TestLoadInt64Property', @RunTTestGenCodeTestLoadInt64Property);
  lSuite.AddTest('TestLoadFloatProperty', @RunTTestGenCodeTestLoadFloatProperty);
  lSuite.AddTest('TestLoadObjectProperty', @RunTTestGenCodeTestLoadObjectProperty);
  lSuite.AddTest('TestLoadStringArrayProperty', @RunTTestGenCodeTestLoadStringArrayProperty);
  lSuite.AddTest('TestLoadBooleanArrayProperty', @RunTTestGenCodeTestLoadBooleanArrayProperty);
  lSuite.AddTest('TestLoadIntegerArrayProperty', @RunTTestGenCodeTestLoadIntegerArrayProperty);
  lSuite.AddTest('TestLoadInt64ArrayProperty', @RunTTestGenCodeTestLoadInt64ArrayProperty);
  lSuite.AddTest('TestLoadFloatArrayProperty', @RunTTestGenCodeTestLoadFloatArrayProperty);
  lSuite.AddTest('TestLoadDelphiIntegerProperty', @RunTTestGenCodeTestLoadDelphiIntegerProperty);
  lSuite.AddTest('TestLoadDelphi2IntegersProperty', @RunTTestGenCodeTestLoadDelphi2IntegersProperty);
  lSuite.AddTest('TestLoadDelphiIntegerWithErrorProperty', @RunTTestGenCodeTestLoadDelphiIntegerWithErrorProperty);
  lSuite.AddTest('TestLoadDelphiIntegerCaseInsensitiveProperty', @RunTTestGenCodeTestLoadDelphiIntegerCaseInsensitiveProperty);
  lSuite.AddTest('TestLoadDelphiStringProperty', @RunTTestGenCodeTestLoadDelphiStringProperty);
  lSuite.AddTest('TestLoadDelphiBooleanProperty', @RunTTestGenCodeTestLoadDelphiBooleanProperty);
  lSuite.AddTest('TestLoadDelphiInt64Property', @RunTTestGenCodeTestLoadDelphiInt64Property);
  lSuite.AddTest('TestLoadDelphiFloatProperty', @RunTTestGenCodeTestLoadDelphiFloatProperty);
  lSuite.AddTest('TestLoadDelphiObjectProperty', @RunTTestGenCodeTestLoadDelphiObjectProperty);
  lSuite.AddTest('TestLoadDelphiStringArrayProperty', @RunTTestGenCodeTestLoadDelphiStringArrayProperty);
  lSuite.AddTest('TestLoadDelphiBooleanArrayProperty', @RunTTestGenCodeTestLoadDelphiBooleanArrayProperty);
  lSuite.AddTest('TestLoadDelphiIntegerArrayProperty', @RunTTestGenCodeTestLoadDelphiIntegerArrayProperty);
  lSuite.AddTest('TestLoadDelphiInt64ArrayProperty', @RunTTestGenCodeTestLoadDelphiInt64ArrayProperty);
  lSuite.AddTest('TestLoadDelphiFloatArrayProperty', @RunTTestGenCodeTestLoadDelphiFloatArrayProperty);
  lSuite.AddTest('TestSaveIntegerProperty', @RunTTestGenCodeTestSaveIntegerProperty);
  lSuite.AddTest('TestSave2IntegersProperty', @RunTTestGenCodeTestSave2IntegersProperty);
  lSuite.AddTest('TestSaveStringProperty', @RunTTestGenCodeTestSaveStringProperty);
  lSuite.AddTest('TestSaveBooleanProperty', @RunTTestGenCodeTestSaveBooleanProperty);
  lSuite.AddTest('TestSaveInt64Property', @RunTTestGenCodeTestSaveInt64Property);
  lSuite.AddTest('TestSaveFloatProperty', @RunTTestGenCodeTestSaveFloatProperty);
  lSuite.AddTest('TestSaveObjectProperty', @RunTTestGenCodeTestSaveObjectProperty);
  lSuite.AddTest('TestSaveStringArrayProperty', @RunTTestGenCodeTestSaveStringArrayProperty);
  lSuite.AddTest('TestSaveBooleanArrayProperty', @RunTTestGenCodeTestSaveBooleanArrayProperty);
  lSuite.AddTest('TestSaveIntegerArrayProperty', @RunTTestGenCodeTestSaveIntegerArrayProperty);
  lSuite.AddTest('TestSaveInt64ArrayProperty', @RunTTestGenCodeTestSaveInt64ArrayProperty);
  lSuite.AddTest('TestSaveFloatArrayProperty', @RunTTestGenCodeTestSaveFloatArrayProperty);
  lSuite.AddTest('TestSaveDelphiIntegerProperty', @RunTTestGenCodeTestSaveDelphiIntegerProperty);
  lSuite.AddTest('TestSaveDelphi2IntegersProperty', @RunTTestGenCodeTestSaveDelphi2IntegersProperty);
  lSuite.AddTest('TestSaveDelphiStringProperty', @RunTTestGenCodeTestSaveDelphiStringProperty);
  lSuite.AddTest('TestSaveDelphiBooleanProperty', @RunTTestGenCodeTestSaveDelphiBooleanProperty);
  lSuite.AddTest('TestSaveDelphiInt64Property', @RunTTestGenCodeTestSaveDelphiInt64Property);
  lSuite.AddTest('TestSaveDelphiFloatProperty', @RunTTestGenCodeTestSaveDelphiFloatProperty);
  lSuite.AddTest('TestSaveDelphiObjectProperty', @RunTTestGenCodeTestSaveDelphiObjectProperty);
  lSuite.AddTest('TestSaveDelphiStringArrayProperty', @RunTTestGenCodeTestSaveDelphiStringArrayProperty);
  lSuite.AddTest('TestSaveDelphiBooleanArrayProperty', @RunTTestGenCodeTestSaveDelphiBooleanArrayProperty);
  lSuite.AddTest('TestSaveDelphiIntegerArrayProperty', @RunTTestGenCodeTestSaveDelphiIntegerArrayProperty);
  lSuite.AddTest('TestSaveDelphiInt64ArrayProperty', @RunTTestGenCodeTestSaveDelphiInt64ArrayProperty);
  lSuite.AddTest('TestSaveDelphiFloatArrayProperty', @RunTTestGenCodeTestSaveDelphiFloatArrayProperty);
end;

end.

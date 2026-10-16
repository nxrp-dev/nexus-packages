unit tcjsonini;

{$mode objfpc}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpjson, inifiles, jsonini;

Type

  { TJSONIniTest }

  TJSONIniTest = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FFileContent: TJSONData;
    Fini: TJSONIniFile;
    FStrings: TStrings;
    FTestFile: String;
    procedure AssertValue(const aSection, Akey, avalue: string);
    procedure CreateIni;
    function GetIni: TJSONIniFile;
    function GetO: TJSONObject;
  Protected
    procedure HaveFile;
    Procedure ReLoad;
    procedure NoFileYet;
    procedure RemoveFile;
    Procedure Setup; virtual;
    Procedure TearDown; virtual;
    Procedure ReadFile;
    Procedure WriteFile;
    Procedure SampleFile;
    Property TestFile : String Read FTestFile;
    Property FileContent : TJSONData Read FFileContent Write FFileContent;
    Property ObjFileContent : TJSONObject Read GetO;
    Property Ini : TJSONIniFile Read GetIni;
    Property Strings : TStrings Read FStrings;
  public
    Procedure TestEmpty;
    Procedure TestReadEmpty;
    Procedure TestReadEmptyValue;
    Procedure TestReadEmptyObject;
    Procedure TestRead1EmptySection;
    Procedure TestReadSections;
    procedure TestReadSection;
    procedure TestReadSectionValues;
    Procedure TestReadString;
    Procedure TestReadInteger;
    Procedure TestReadInt64;
    Procedure TestReadFloat;
    Procedure TestReadBoolean;
    Procedure TestReadDate;
    Procedure TestReadTime;
    Procedure TestReadDateTime;
    Procedure TestEraseSection;
    Procedure TestEraseSectionCaseMismatch;
    Procedure TestDeleteKey;
    Procedure TestDeleteKeySectionCaseMismatch;
    Procedure TestDeleteKeyKeyCaseMismatch;
    Procedure TestWriteString;
    Procedure TestWriteInteger;

    Procedure TestWriteDate;
    Procedure TestWriteDateTime;
    Procedure TestWriteTime;
    Procedure TestConvertIni;
    Procedure TestConvertIniString;
  end;

procedure RegistertcjsoniniTests(ARegistry: TNXTestRegistry);

implementation

{ TJSONIniTest }

function TJSONIniTest.GetIni: TJSONIniFile;
begin
  If FIni=Nil then
    begin
    Fini:=TJSONIniFile.Create(TestFile);
    end;
  Result:=FIni;
end;

function TJSONIniTest.GetO: TJSONObject;
begin
  Result:=FFileContent as TJSONObject;
end;

procedure TJSONIniTest.Setup;
begin

  FTestFile:=CaseName+'.json';
  If FileExists(FTestFile) then
    DeleteFile(FTestFile);
  FStrings:=TStringList.Create;
  // Do nothing
end;

procedure TJSONIniTest.TearDown;
begin
  If FileExists(FTestFile) then
    DeleteFile(FTestFile);
  FreeAndNil(FFileContent);
  FreeAndNil(FIni);
  FreeAndNil(FStrings);

end;

procedure TJSONIniTest.ReadFile;

Var
  F : TFileStream;

begin
  FreeAndNil(FFileContent);
  TestContext.AssertTrue(FileExists(TestFile), 'Test File '+TestFile+' exists.');
  F:=TFileStream.Create(TestFile,fmOpenRead or fmShareDenyWrite);
  try
    FileContent:=GetJSON(F);
  finally
    F.Free;
  end;
end;

procedure TJSONIniTest.WriteFile;

Var
  F : TFileStream;
  S : TJSONStringType;

begin
  F:=TFileStream.Create(TestFile,fmCreate);
  try
    S:=FFileContent.AsJSON;
    F.WriteBuffer(S[1],Length(S));
  finally
    F.Free;
  end;
end;

procedure TJSONIniTest.SampleFile;

begin
  FileContent:=TJSONObject.Create([
    'a',TJSONObject.Create([
      'i',1,
      'i6',TJSONInt64Number.Create(Maxint*2),
      'f',1.2,
      's','test',
      'si','1',
      'si6',IntToStr(int64(MaxInt*2)),
      'sf','1.2',
      'dt','2001-05-06T23:24:25.678',
      'id',Round(EncodeDate(2001,05,06)),
      'fd',EncodeDate(2001,05,06),
      't','0000-00-00T12:13:14.567',
      'ft',Frac(EncodeTime(12,13,14,567)),
      'fdt',EncodeDate(2001,05,06)+EncodeTime(23,24,25,678),
      'd','2001-05-06',
      'b',true,
      'n',Nil,
      'o',TJSONObject.Create
    ]),
    'B',TJSONObject.Create([
      'I',1,
      'F',1.2,
      'S','test',
      'SI','1',
      'SF','1.2',
      'DT','2001-05-06T23:24:25.678',
      'T','0000-00-00T12:13:14.567',
      'D','2001-05-06',
      'B',true,
      'N',Nil,
      'O',TJSONObject.Create
    ]),
    'NO','not'
  ]);
  WriteFile;
end;

procedure TJSONIniTest.TestEmpty;
begin
  TestContext.AssertTrue(not (FileExists(testfile)), 'No test file');
  TestContext.AssertTrue((Fini)=nil, 'No ini');
  TestContext.AssertTrue((FFileContent)=nil, 'No file content');
  TestContext.AssertTrue((Strings)<>nil, 'Have strings');
  TestContext.AssertTrue((0)=(Strings.Count), 'Have empty strings');
end;

procedure TJSONIniTest.TestReadEmpty;
begin
  Ini.ReadSections(Strings);
  TestContext.AssertTrue((0)=(Strings.Count), 'No sections');
end;

procedure TJSONIniTest.TestReadEmptyValue;
begin
  FileContent:=TJSONString.Create('me');
  WriteFile;
  Ini.ReadSections(Strings);
  TestContext.AssertTrue((0)=(Strings.Count), 'No sections');
end;

procedure TJSONIniTest.TestReadEmptyObject;
begin
  FileContent:=TJSONObject.Create();
  WriteFile;
  Ini.ReadSections(Strings);
  TestContext.AssertTrue((0)=(Strings.Count), 'No sections');
end;

procedure TJSONIniTest.TestRead1EmptySection;
begin
  FileContent:=TJSONObject.Create(['empty',TJSONOBject.Create]);
  WriteFile;
  Ini.ReadSections(Strings);
  TestContext.AssertTrue((1)=(Strings.Count), '1 sections');
  TestContext.AssertTrue(('empty')=(Strings[0]), 'Section name');
end;

procedure TJSONIniTest.TestReadSections;
begin
  SampleFile;
  Ini.ReadSections(Strings);
  TestContext.AssertTrue((2)=(Strings.Count), '2 sections');
  TestContext.AssertTrue(('a')=(Strings[0]), 'Section name 0');
  TestContext.AssertTrue(('B')=(Strings[1]), 'Section name 1');
end;

procedure TJSONIniTest.TestReadSection;
begin
  SampleFile;
  Ini.ReadSection('a',Strings);
  // Only valid values are reported
  TestContext.AssertTrue(((FileContent as TJSONObject).Objects['a'].Count-2)=(Strings.Count), 'value count');
  TestContext.AssertTrue(('i,i6,f,s,si,si6,sf,dt,id,fd,t,ft,fdt,d,b')=(Strings.CommaText), 'value names');
end;

procedure TJSONIniTest.TestReadSectionValues;

Var
  D : TJSONEnum;

begin
  SampleFile;
  Ini.ReadSectionValues('a',Strings,[]);
  // Only valid values are reported
  TestContext.AssertTrue(((FileContent as TJSONObject).Objects['a'].Count-2)=(Strings.Count), 'value count');
  for D in (FileContent as TJSONObject).Objects['a'] do
    if D.Value.JSONType in ActualValueJSONTypes then
      TestContext.AssertTrue((D.Value.AsString)=(Strings.Values[D.Key]), 'value '+D.key);
  Strings.Clear;
  Ini.ReadSectionValues('a',Strings);
  // All valid values are reported
  TestContext.AssertTrue(((FileContent as TJSONObject).Objects['a'].Count)=(Strings.Count), 'value count');
end;

procedure TJSONIniTest.TestReadString;
begin
  SampleFile;
  TestContext.AssertTrue(('test')=(Ini.ReadString('a','s','nono')), 'Value, case OK');
  TestContext.AssertTrue(('test')=(Ini.ReadString('a','S','nono')), 'Value, key case not OK');
  TestContext.AssertTrue(('test')=(Ini.ReadString('A','s','nono')), 'Value, section case not OK');
  TestContext.AssertTrue(('nono')=(Ini.ReadString('C','s','nono')), 'Value, section not exist');
  TestContext.AssertTrue(('nono')=(Ini.ReadString('a','Z','nono')), 'Value, key not exist');
  TestContext.AssertTrue(('1')=(Ini.ReadString('a','i','nono')), 'Value, key not string');
  TestContext.AssertTrue(('nono')=(Ini.ReadString('a','o','nono')), 'Value, key not valid value');
end;

procedure TJSONIniTest.TestReadInteger;

begin
  SampleFile;
  TestContext.AssertTrue((1)=(Ini.ReadInteger('a','i',2)), 'Value, case OK');
  TestContext.AssertTrue((1)=(Ini.ReadInteger('a','I',2)), 'Value, key case not OK');
  TestContext.AssertTrue((1)=(Ini.ReadInteger('A','i',2)), 'Value, section case not OK');
  TestContext.AssertTrue((2)=(Ini.ReadInteger('C','i',2)), 'Value, section not exist');
  TestContext.AssertTrue((2)=(Ini.ReadInteger('a','Z',2)), 'Value, key not exist');
  TestContext.AssertTrue((2)=(Ini.ReadInteger('a','s',2)), 'Value, key not integer');
  TestContext.AssertTrue((1)=(Ini.ReadInteger('a','si',2)), 'Value, key not integer, but convertable to integer');
end;

procedure TJSONIniTest.TestReadInt64;
Var
  I6 : Int64;
begin
  I6:=MaxInt*2;
  SampleFile;
  TestContext.AssertTrue((i6)=(Ini.ReadInt64('a','i6',2)), 'Value, case OK');
  TestContext.AssertTrue((i6)=(Ini.ReadInt64('a','I6',2)), 'Value, key case not OK');
  TestContext.AssertTrue((i6)=(Ini.ReadInt64('A','i6',2)), 'Value, section case not OK');
  TestContext.AssertTrue((2)=(Ini.ReadInt64('C','i',2)), 'Value, section not exist');
  TestContext.AssertTrue((2)=(Ini.ReadInt64('a','Z',2)), 'Value, key not exist');
  TestContext.AssertTrue((2)=(Ini.ReadInt64('a','s',2)), 'Value, key not integer');
  TestContext.AssertTrue((I6)=(Ini.ReadInt64('a','si6',2)), 'Value, key not integer, but convertable to int64');
end;

procedure TJSONIniTest.TestReadFloat;
begin
  SampleFile;
  TestContext.AssertTrue(Abs(1.2-Ini.ReadFloat('a','f',2.3))<=1e-12, 'Value, case OK');
  TestContext.AssertTrue(Abs(1.2-Ini.ReadFloat('a','F',2.3))<=1e-12, 'Value, key case not OK');
  TestContext.AssertTrue(Abs(1.2-Ini.ReadFloat('A','f',2.3))<=1e-12, 'Value, section case not OK');
  TestContext.AssertTrue(Abs(2.3-Ini.ReadFloat('C','f',2.3))<=1e-12, 'Value, section not exist');
  TestContext.AssertTrue(Abs(2.3-Ini.ReadFloat('a','Z',2.3))<=1e-12, 'Value, key not exist');
  TestContext.AssertTrue(Abs(2.3-Ini.ReadFloat('a','s',2.3))<=1e-12, 'Value, key not float');
  TestContext.AssertTrue(Abs(1.2-Ini.ReadFloat('a','sf',2.3))<=1e-12, 'Value, key not float, but convertable to float');
end;

procedure TJSONIniTest.TestReadBoolean;
begin
  SampleFile;
  TestContext.AssertTrue((True)=(Ini.ReadBool('a','b',False)), 'Value, case OK');
  TestContext.AssertTrue((True)=(Ini.ReadBool('a','B',False)), 'Value, key case not OK');
  TestContext.AssertTrue((True)=(Ini.ReadBool('A','b',False)), 'Value, section case not OK');
  TestContext.AssertTrue((True)=(Ini.ReadBool('C','b',True)), 'Value, section not exist');
  TestContext.AssertTrue((True)=(Ini.ReadBool('a','Z',True)), 'Value, key not exist');
  TestContext.AssertTrue((True)=(Ini.ReadBool('a','i',false)), 'Value, key not bool but integer');
end;

procedure TJSONIniTest.TestReadDate;

Var
  D,DD : TDateTime;

begin
  D:=EncodeDate(2001,05,06);
  DD:=EncodeDate(1999,11,12);
  SampleFile;
  TestContext.AssertTrue((D)=(Ini.ReadDate('a','d',DD)), 'Value, case OK');
  TestContext.AssertTrue((D)=(Ini.ReadDate('a','D',DD)), 'Value, key case not OK');
  TestContext.AssertTrue((D)=(Ini.ReadDate('A','d',DD)), 'Value, section case not OK');
  TestContext.AssertTrue((DD)=(Ini.ReadDate('C','d',DD)), 'Value, section not exist');
  TestContext.AssertTrue((D)=(Ini.ReadDate('a','id',DD)), 'Value, date as integer');
  TestContext.AssertTrue((D)=(Ini.ReadDate('a','fd',DD)), 'Value, date as float');
end;

procedure TJSONIniTest.TestReadTime;

Var
  T,DT : TDateTime;

begin
  T:=EncodeTime(12,13,14,567);
  DT:=EncodeTime(1,2,3,4);
  SampleFile;
  TestContext.AssertTrue(Abs(T-Ini.ReadTime('a','t',DT))<=(0.5/86400000), 'Value, case OK');
  TestContext.AssertTrue(Abs(T-Ini.ReadTime('a','T',DT))<=(0.5/86400000), 'Value, key case not OK');
  TestContext.AssertTrue(Abs(T-Ini.ReadTime('A','t',DT))<=(0.5/86400000), 'Value, section case not OK');
  TestContext.AssertTrue(Abs(DT-Ini.ReadTime('C','t',DT))<=(0.5/86400000), 'Value, section not exist');
  TestContext.AssertTrue(Abs(T-Ini.ReadTime('a','ft',DT))<=(0.5/86400000), 'Value, key exist as float');
end;

procedure TJSONIniTest.TestReadDateTime;
Var
  DT,DDT : TDateTime;

begin
  DT:=EncodeDate(2001,05,06)+EncodeTime(23,24,25,678);
  DDT:=EncodeDate(1999,11,12)+EncodeTime(1,2,3,4);
  SampleFile;
  TestContext.AssertTrue(Abs(DT-Ini.ReadDateTime('a','dt',DDT))<=(0.5/86400000), 'Value, case OK');
  TestContext.AssertTrue(Abs(DT-Ini.ReadDateTime('a','DT',DDT))<=(0.5/86400000), 'Value, key case not OK');
  TestContext.AssertTrue(Abs(DT-Ini.ReadDateTime('A','dt',DDT))<=(0.5/86400000), 'Value, section case not OK');
  TestContext.AssertTrue(Abs(DDT-Ini.ReadDateTime('C','dt',DDT))<=(0.5/86400000), 'Value, section not exist');
  TestContext.AssertTrue(Abs(DT-Ini.ReadDateTime('a','fdt',DDT))<=(0.5/86400000), 'Value, key exist as float');
end;

procedure TJSONIniTest.TestEraseSection;
begin
  SampleFile;
  Ini.EraseSection('B');
  Ini.UpdateFile;
  ReadFile;
  TestContext.AssertTrue((-1)=(ObjFileContent.IndexOfName('B')), 'No more section');
end;

procedure TJSONIniTest.TestEraseSectionCaseMismatch;
begin
  SampleFile;
  Ini.EraseSection('b');
  Ini.UpdateFile;
  ReadFile;
  TestContext.AssertTrue((-1)=(ObjFileContent.IndexOfName('B')), 'No more section');
end;

procedure TJSONIniTest.TestDeleteKey;
begin
  SampleFile;
  Ini.DeleteKey('a','i');
  Ini.UpdateFile;
  ReadFile;
  TestContext.AssertTrue((-1)=(ObjFileContent.Objects['a'].IndexOfName('i')), 'No more key');
end;

procedure TJSONIniTest.TestDeleteKeySectionCaseMismatch;
begin
  SampleFile;
  Ini.DeleteKey('A','i');
  Ini.UpdateFile;
  ReadFile;
  TestContext.AssertTrue((-1)=(ObjFileContent.Objects['a'].IndexOfName('i')), 'No more key');
end;

procedure TJSONIniTest.TestDeleteKeyKeyCaseMismatch;
begin
  SampleFile;
  Ini.DeleteKey('a','I');
  Ini.UpdateFile;
  ReadFile;
  TestContext.AssertTrue((-1)=(ObjFileContent.Objects['a'].IndexOfName('i')), 'No more key');
end;

procedure TJSONIniTest.AssertValue(const aSection,Akey,avalue : string);

Var
  D : TJSONData;

begin
  ini.UpdateFile;
  ReadFile;
  D:=ObjFileContent.FindPath(asection+'.'+akey);
  TestContext.AssertTrue((D)<>nil, 'Have value at '+asection+'.'+akey);
  TestContext.AssertTrue((AValue)=(D.AsString), 'Correct value at '+asection+'.'+akey);
end;

procedure TJSONIniTest.NoFileYet;

begin
  TestContext.AssertTrue(not (FileExists(TestFile)), 'File not exist yet');
end;

procedure TJSONIniTest.HaveFile;

begin
  TestContext.AssertTrue(FileExists(TestFile), 'Test file exists');
end;

procedure TJSONIniTest.ReLoad;
begin
  FreeAndNil(Fini);
  TestContext.AssertTrue((Ini)<>nil, '');
end;

procedure TJSONIniTest.RemoveFile;
begin
  if FileExists(TestFile) then
    TestContext.AssertTrue(DeleteFile(TestFile), 'Deleted file');
end;

procedure TJSONIniTest.TestWriteString;
begin
  Ini.WriteString('a','i','string');
  NoFileYet;
  AssertValue('a','i','string');
  Ini.CacheUpdates:=False;
  Ini.WriteString('a','i','string2');
  HaveFile;
  AssertValue('a','i','string2');
  Reload;
  TestContext.AssertTrue(('string2')=(Ini.ReadString('a','i','')), 'Can read value');
end;

procedure TJSONIniTest.TestWriteInteger;
begin
  Ini.Writeinteger('a','i',2);
  NoFileYet;
  AssertValue('a','i','2');
  Ini.CacheUpdates:=False;
  Ini.WriteInteger('a','i',3);
  HaveFile;
  AssertValue('a','i','3');
  Reload;
  TestContext.AssertTrue((3)=(Ini.ReadInteger('a','i',0)), 'Can read value');
end;

procedure TJSONIniTest.TestWriteDate;
Var
  D : TDateTime;
begin
  D:=EncodeDate(2001,2,3);
  Ini.WriteDate('a','i',D);
  NoFileYet;
  AssertValue('a','i','2001-02-03T00:00:00.000');
  Ini.CacheUpdates:=False;
  Ini.WriteDate('a','i',D+1);
  HaveFile;
  AssertValue('a','i','2001-02-04T00:00:00.000');
  Reload;
  TestContext.AssertTrue((D+1)=(Ini.ReadDate('a','i',0)), 'Can read value');
end;

procedure TJSONIniTest.TestWriteDateTime;

Var
  D : TDateTime;

begin
  D:=EncodeDate(2001,2,3)+EncodeTime(12,13,14,567);
  Ini.WriteDateTime('a','i',D);
  NoFileYet;
  AssertValue('a','i','2001-02-03T12:13:14.567');
  Ini.CacheUpdates:=False;
  Ini.WriteDateTime('a','i',D+1);
  HaveFile;
  AssertValue('a','i','2001-02-04T12:13:14.567');
  Reload;
  TestContext.AssertTrue((D+1)=(Ini.ReadDateTime('a','i',0)), 'Can read value');
end;

procedure TJSONIniTest.TestWriteTime;

Var
  D,D2 : TDateTime;

begin
  D:=EncodeTime(12,13,14,567);
  D2:=EncodeTime(13,14,15,678);
  Ini.WriteTime('a','i',D);
  NoFileYet;
  AssertValue('a','i','0000-00-00T12:13:14.567');
  Ini.CacheUpdates:=False;
  Ini.WriteTime('a','i',D2);
  HaveFile;
  AssertValue('a','i','0000-00-00T13:14:15.678');
  Reload;
  TestContext.AssertTrue(Abs(D2-Ini.ReadTime('a','i',0))<=(0.5/86400000), 'Can read value');
end;

procedure TJSONIniTest.CreateIni;

Var
  M : TMemIniFile;
  D,DT,T : TDateTime;

begin
  D:=EncodeDate(2001,2,3);
  T:=EncodeTime(12,13,14,567);
  DT:=D+T;
  if FileExists(CaseName+'.ini') then
    DeleteFile(CaseName+'.ini');
  M:=TMemIniFile.Create(CaseName+'.ini');
  try
    M.WriteString('a','s','c');
    M.WriteInteger('a','i',2);
    M.WriteBool('a','b',True);
    M.WriteInt64('a','i6',Maxint*2);
    M.WriteDate('a','d',D);
    M.WriteTime('a','t',T);
    M.WriteDateTime('a','dt',DT);
    M.WriteFloat('a','f',1.23);
    M.UpdateFile;
  finally
    M.Free;
  end;
end;

procedure TJSONIniTest.TestConvertIni;

Var
  D,DT,T : TDateTime;

begin
  D:=EncodeDate(2001,2,3);
  T:=EncodeTime(12,13,14,567);
  DT:=D+T;
  CreateIni;
  TJSONIniFile.ConvertIni(CaseName+'.ini',TestFile,False);
  TestContext.AssertTrue(('c')=(Ini.ReadString('a','s','')), 'String');
  TestContext.AssertTrue((2)=(Ini.ReadInteger('a','i',1)), 'Integer');
  TestContext.AssertTrue((True)=(Ini.ReadBool('a','b',False)), 'Bool');
  TestContext.AssertTrue((Int64(Maxint*2))=(Ini.ReadInt64('a','i6',Maxint*2)), 'Int64');
  TestContext.AssertTrue((D)=(Ini.ReadDate('a','d',0)), 'Date');
  TestContext.AssertTrue(Abs(StrToTime(TimeToStr(T))-Ini.ReadTime('a','t',0))<=(0.5/86400000), 'Time');
  TestContext.AssertTrue(Abs(StrToDateTime(DateTimeToStr(DT))-Ini.ReadDateTime('a','dt',0))<=(0.5/86400000), 'DateTime');
  TestContext.AssertTrue(Abs(1.23-Ini.ReadFloat('a','f',0))<=1e-12, 'Float');
  if FileExists(CaseName+'.ini') then
    DeleteFile(CaseName+'.ini');
end;

procedure TJSONIniTest.TestConvertIniString;
Var
  D,DT,T : TDateTime;

begin
  D:=EncodeDate(2001,2,3);
  T:=EncodeTime(12,13,14,567);
  DT:=D+T;
  CreateIni;
  TJSONIniFile.ConvertIni(CaseName+'.ini',TestFile,True);
  TestContext.AssertTrue(('c')=(Ini.ReadString('a','s','')), 'String');
  TestContext.AssertTrue((2)=(Ini.ReadInteger('a','i',1)), 'Integer');
  TestContext.AssertTrue((True)=(Ini.ReadBool('a','b',False)), 'Bool');
  TestContext.AssertTrue((Int64(Maxint*2))=(Ini.ReadInt64('a','i6',Maxint*2)), 'Int64');
  TestContext.AssertTrue((DateToStr(D))=(Ini.ReadString('a','d','')), 'Date');
  TestContext.AssertTrue((TimeToStr(T))=(Ini.ReadString('a','t','')), 'Time');
  TestContext.AssertTrue((DateTimeToStr(DT))=(Ini.ReadString('a','dt','')), 'DateTime');
  TestContext.AssertTrue(Abs(1.23-Ini.ReadFloat('a','f',0))<=1e-12, 'Float');
  if FileExists(CaseName+'.ini') then
    DeleteFile(CaseName+'.ini');
end;


constructor TJSONIniTest.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTJSONIniTestTestEmpty(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestEmpty');
  try
    lFixture.SetUp;
    try lFixture.TestEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadEmpty(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestReadEmpty');
  try
    lFixture.SetUp;
    try lFixture.TestReadEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadEmptyValue(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestReadEmptyValue');
  try
    lFixture.SetUp;
    try lFixture.TestReadEmptyValue; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadEmptyObject(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestReadEmptyObject');
  try
    lFixture.SetUp;
    try lFixture.TestReadEmptyObject; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestRead1EmptySection(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestRead1EmptySection');
  try
    lFixture.SetUp;
    try lFixture.TestRead1EmptySection; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadSections(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestReadSections');
  try
    lFixture.SetUp;
    try lFixture.TestReadSections; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadSection(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestReadSection');
  try
    lFixture.SetUp;
    try lFixture.TestReadSection; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadSectionValues(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestReadSectionValues');
  try
    lFixture.SetUp;
    try lFixture.TestReadSectionValues; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadString(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestReadString');
  try
    lFixture.SetUp;
    try lFixture.TestReadString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadInteger(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestReadInteger');
  try
    lFixture.SetUp;
    try lFixture.TestReadInteger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadInt64(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestReadInt64');
  try
    lFixture.SetUp;
    try lFixture.TestReadInt64; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadFloat(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestReadFloat');
  try
    lFixture.SetUp;
    try lFixture.TestReadFloat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadBoolean(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestReadBoolean');
  try
    lFixture.SetUp;
    try lFixture.TestReadBoolean; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadDate(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestReadDate');
  try
    lFixture.SetUp;
    try lFixture.TestReadDate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadTime(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestReadTime');
  try
    lFixture.SetUp;
    try lFixture.TestReadTime; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadDateTime(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestReadDateTime');
  try
    lFixture.SetUp;
    try lFixture.TestReadDateTime; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestEraseSection(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestEraseSection');
  try
    lFixture.SetUp;
    try lFixture.TestEraseSection; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestEraseSectionCaseMismatch(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestEraseSectionCaseMismatch');
  try
    lFixture.SetUp;
    try lFixture.TestEraseSectionCaseMismatch; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestDeleteKey(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestDeleteKey');
  try
    lFixture.SetUp;
    try lFixture.TestDeleteKey; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestDeleteKeySectionCaseMismatch(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestDeleteKeySectionCaseMismatch');
  try
    lFixture.SetUp;
    try lFixture.TestDeleteKeySectionCaseMismatch; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestDeleteKeyKeyCaseMismatch(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestDeleteKeyKeyCaseMismatch');
  try
    lFixture.SetUp;
    try lFixture.TestDeleteKeyKeyCaseMismatch; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestWriteString(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestWriteString');
  try
    lFixture.SetUp;
    try lFixture.TestWriteString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestWriteInteger(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestWriteInteger');
  try
    lFixture.SetUp;
    try lFixture.TestWriteInteger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestWriteDate(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestWriteDate');
  try
    lFixture.SetUp;
    try lFixture.TestWriteDate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestWriteDateTime(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestWriteDateTime');
  try
    lFixture.SetUp;
    try lFixture.TestWriteDateTime; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestWriteTime(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestWriteTime');
  try
    lFixture.SetUp;
    try lFixture.TestWriteTime; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestConvertIni(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestConvertIni');
  try
    lFixture.SetUp;
    try lFixture.TestConvertIni; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestConvertIniString(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create(AContext, 'TestConvertIniString');
  try
    lFixture.SetUp;
    try lFixture.TestConvertIniString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegistertcjsoniniTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcjsonini.TJSONIniTest');
  lSuite.AddTest('TestEmpty', @RunTJSONIniTestTestEmpty);
  lSuite.AddTest('TestReadEmpty', @RunTJSONIniTestTestReadEmpty);
  lSuite.AddTest('TestReadEmptyValue', @RunTJSONIniTestTestReadEmptyValue);
  lSuite.AddTest('TestReadEmptyObject', @RunTJSONIniTestTestReadEmptyObject);
  lSuite.AddTest('TestRead1EmptySection', @RunTJSONIniTestTestRead1EmptySection);
  lSuite.AddTest('TestReadSections', @RunTJSONIniTestTestReadSections);
  lSuite.AddTest('TestReadSection', @RunTJSONIniTestTestReadSection);
  lSuite.AddTest('TestReadSectionValues', @RunTJSONIniTestTestReadSectionValues);
  lSuite.AddTest('TestReadString', @RunTJSONIniTestTestReadString);
  lSuite.AddTest('TestReadInteger', @RunTJSONIniTestTestReadInteger);
  lSuite.AddTest('TestReadInt64', @RunTJSONIniTestTestReadInt64);
  lSuite.AddTest('TestReadFloat', @RunTJSONIniTestTestReadFloat);
  lSuite.AddTest('TestReadBoolean', @RunTJSONIniTestTestReadBoolean);
  lSuite.AddTest('TestReadDate', @RunTJSONIniTestTestReadDate);
  lSuite.AddTest('TestReadTime', @RunTJSONIniTestTestReadTime);
  lSuite.AddTest('TestReadDateTime', @RunTJSONIniTestTestReadDateTime);
  lSuite.AddTest('TestEraseSection', @RunTJSONIniTestTestEraseSection);
  lSuite.AddTest('TestEraseSectionCaseMismatch', @RunTJSONIniTestTestEraseSectionCaseMismatch);
  lSuite.AddTest('TestDeleteKey', @RunTJSONIniTestTestDeleteKey);
  lSuite.AddTest('TestDeleteKeySectionCaseMismatch', @RunTJSONIniTestTestDeleteKeySectionCaseMismatch);
  lSuite.AddTest('TestDeleteKeyKeyCaseMismatch', @RunTJSONIniTestTestDeleteKeyKeyCaseMismatch);
  lSuite.AddTest('TestWriteString', @RunTJSONIniTestTestWriteString);
  lSuite.AddTest('TestWriteInteger', @RunTJSONIniTestTestWriteInteger);
  lSuite.AddTest('TestWriteDate', @RunTJSONIniTestTestWriteDate);
  lSuite.AddTest('TestWriteDateTime', @RunTJSONIniTestTestWriteDateTime);
  lSuite.AddTest('TestWriteTime', @RunTJSONIniTestTestWriteTime);
  lSuite.AddTest('TestConvertIni', @RunTJSONIniTestTestConvertIni);
  lSuite.AddTest('TestConvertIniString', @RunTJSONIniTestTestConvertIniString);
end;

end.

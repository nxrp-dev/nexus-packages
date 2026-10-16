unit tcjsonini;

{$mode objfpc}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpjson, inifiles, jsonini;

Type

  { TJSONIniTest }

  TJSONIniTest = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
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
  Inherited;
  FTestFile:=FCaseName+'.json';
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
  Inherited;
end;

procedure TJSONIniTest.ReadFile;

Var
  F : TFileStream;

begin
  FreeAndNil(FFileContent);
  FContext.AssertTrue(FileExists(TestFile), 'Test File '+TestFile+' exists.');
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
  FContext.AssertTrue(not (FileExists(testfile)), 'No test file');
  FContext.AssertTrue((Fini)=nil, 'No ini');
  FContext.AssertTrue((FFileContent)=nil, 'No file content');
  FContext.AssertTrue((Strings)<>nil, 'Have strings');
  FContext.AssertTrue((0)=(Strings.Count), 'Have empty strings');
end;

procedure TJSONIniTest.TestReadEmpty;
begin
  Ini.ReadSections(Strings);
  FContext.AssertTrue((0)=(Strings.Count), 'No sections');
end;

procedure TJSONIniTest.TestReadEmptyValue;
begin
  FileContent:=TJSONString.Create('me');
  WriteFile;
  Ini.ReadSections(Strings);
  FContext.AssertTrue((0)=(Strings.Count), 'No sections');
end;

procedure TJSONIniTest.TestReadEmptyObject;
begin
  FileContent:=TJSONObject.Create();
  WriteFile;
  Ini.ReadSections(Strings);
  FContext.AssertTrue((0)=(Strings.Count), 'No sections');
end;

procedure TJSONIniTest.TestRead1EmptySection;
begin
  FileContent:=TJSONObject.Create(['empty',TJSONOBject.Create]);
  WriteFile;
  Ini.ReadSections(Strings);
  FContext.AssertTrue((1)=(Strings.Count), '1 sections');
  FContext.AssertTrue(('empty')=(Strings[0]), 'Section name');
end;

procedure TJSONIniTest.TestReadSections;
begin
  SampleFile;
  Ini.ReadSections(Strings);
  FContext.AssertTrue((2)=(Strings.Count), '2 sections');
  FContext.AssertTrue(('a')=(Strings[0]), 'Section name 0');
  FContext.AssertTrue(('B')=(Strings[1]), 'Section name 1');
end;

procedure TJSONIniTest.TestReadSection;
begin
  SampleFile;
  Ini.ReadSection('a',Strings);
  // Only valid values are reported
  FContext.AssertTrue(((FileContent as TJSONObject).Objects['a'].Count-2)=(Strings.Count), 'value count');
  FContext.AssertTrue(('i,i6,f,s,si,si6,sf,dt,id,fd,t,ft,fdt,d,b')=(Strings.CommaText), 'value names');
end;

procedure TJSONIniTest.TestReadSectionValues;

Var
  D : TJSONEnum;

begin
  SampleFile;
  Ini.ReadSectionValues('a',Strings,[]);
  // Only valid values are reported
  FContext.AssertTrue(((FileContent as TJSONObject).Objects['a'].Count-2)=(Strings.Count), 'value count');
  for D in (FileContent as TJSONObject).Objects['a'] do
    if D.Value.JSONType in ActualValueJSONTypes then
      FContext.AssertTrue((D.Value.AsString)=(Strings.Values[D.Key]), 'value '+D.key);
  Strings.Clear;
  Ini.ReadSectionValues('a',Strings);
  // All valid values are reported
  FContext.AssertTrue(((FileContent as TJSONObject).Objects['a'].Count)=(Strings.Count), 'value count');
end;

procedure TJSONIniTest.TestReadString;
begin
  SampleFile;
  FContext.AssertTrue(('test')=(Ini.ReadString('a','s','nono')), 'Value, case OK');
  FContext.AssertTrue(('test')=(Ini.ReadString('a','S','nono')), 'Value, key case not OK');
  FContext.AssertTrue(('test')=(Ini.ReadString('A','s','nono')), 'Value, section case not OK');
  FContext.AssertTrue(('nono')=(Ini.ReadString('C','s','nono')), 'Value, section not exist');
  FContext.AssertTrue(('nono')=(Ini.ReadString('a','Z','nono')), 'Value, key not exist');
  FContext.AssertTrue(('1')=(Ini.ReadString('a','i','nono')), 'Value, key not string');
  FContext.AssertTrue(('nono')=(Ini.ReadString('a','o','nono')), 'Value, key not valid value');
end;

procedure TJSONIniTest.TestReadInteger;

begin
  SampleFile;
  FContext.AssertTrue((1)=(Ini.ReadInteger('a','i',2)), 'Value, case OK');
  FContext.AssertTrue((1)=(Ini.ReadInteger('a','I',2)), 'Value, key case not OK');
  FContext.AssertTrue((1)=(Ini.ReadInteger('A','i',2)), 'Value, section case not OK');
  FContext.AssertTrue((2)=(Ini.ReadInteger('C','i',2)), 'Value, section not exist');
  FContext.AssertTrue((2)=(Ini.ReadInteger('a','Z',2)), 'Value, key not exist');
  FContext.AssertTrue((2)=(Ini.ReadInteger('a','s',2)), 'Value, key not integer');
  FContext.AssertTrue((1)=(Ini.ReadInteger('a','si',2)), 'Value, key not integer, but convertable to integer');
end;

procedure TJSONIniTest.TestReadInt64;
Var
  I6 : Int64;
begin
  I6:=MaxInt*2;
  SampleFile;
  FContext.AssertTrue((i6)=(Ini.ReadInt64('a','i6',2)), 'Value, case OK');
  FContext.AssertTrue((i6)=(Ini.ReadInt64('a','I6',2)), 'Value, key case not OK');
  FContext.AssertTrue((i6)=(Ini.ReadInt64('A','i6',2)), 'Value, section case not OK');
  FContext.AssertTrue((2)=(Ini.ReadInt64('C','i',2)), 'Value, section not exist');
  FContext.AssertTrue((2)=(Ini.ReadInt64('a','Z',2)), 'Value, key not exist');
  FContext.AssertTrue((2)=(Ini.ReadInt64('a','s',2)), 'Value, key not integer');
  FContext.AssertTrue((I6)=(Ini.ReadInt64('a','si6',2)), 'Value, key not integer, but convertable to int64');
end;

procedure TJSONIniTest.TestReadFloat;
begin
  SampleFile;
  FContext.AssertTrue((1.2)=(Ini.ReadFloat('a','f',2.3)), 'Value, case OK');
  FContext.AssertTrue((1.2)=(Ini.ReadFloat('a','F',2.3)), 'Value, key case not OK');
  FContext.AssertTrue((1.2)=(Ini.ReadFloat('A','f',2.3)), 'Value, section case not OK');
  FContext.AssertTrue((2.3)=(Ini.ReadFloat('C','f',2.3)), 'Value, section not exist');
  FContext.AssertTrue((2.3)=(Ini.ReadFloat('a','Z',2.3)), 'Value, key not exist');
  FContext.AssertTrue((2.3)=(Ini.ReadFloat('a','s',2.3)), 'Value, key not float');
  FContext.AssertTrue((1.2)=(Ini.ReadFloat('a','sf',2.3)), 'Value, key not float, but convertable to float');
end;

procedure TJSONIniTest.TestReadBoolean;
begin
  SampleFile;
  FContext.AssertTrue((True)=(Ini.ReadBool('a','b',False)), 'Value, case OK');
  FContext.AssertTrue((True)=(Ini.ReadBool('a','B',False)), 'Value, key case not OK');
  FContext.AssertTrue((True)=(Ini.ReadBool('A','b',False)), 'Value, section case not OK');
  FContext.AssertTrue((True)=(Ini.ReadBool('C','b',True)), 'Value, section not exist');
  FContext.AssertTrue((True)=(Ini.ReadBool('a','Z',True)), 'Value, key not exist');
  FContext.AssertTrue((True)=(Ini.ReadBool('a','i',false)), 'Value, key not bool but integer');
end;

procedure TJSONIniTest.TestReadDate;

Var
  D,DD : TDateTime;

begin
  D:=EncodeDate(2001,05,06);
  DD:=EncodeDate(1999,11,12);
  SampleFile;
  FContext.AssertTrue((D)=(Ini.ReadDate('a','d',DD)), 'Value, case OK');
  FContext.AssertTrue((D)=(Ini.ReadDate('a','D',DD)), 'Value, key case not OK');
  FContext.AssertTrue((D)=(Ini.ReadDate('A','d',DD)), 'Value, section case not OK');
  FContext.AssertTrue((DD)=(Ini.ReadDate('C','d',DD)), 'Value, section not exist');
  FContext.AssertTrue((D)=(Ini.ReadDate('a','id',DD)), 'Value, date as integer');
  FContext.AssertTrue((D)=(Ini.ReadDate('a','fd',DD)), 'Value, date as float');
end;

procedure TJSONIniTest.TestReadTime;

Var
  T,DT : TDateTime;

begin
  T:=EncodeTime(12,13,14,567);
  DT:=EncodeTime(1,2,3,4);
  SampleFile;
  FContext.AssertTrue((T)=(Ini.ReadTime('a','t',DT)), 'Value, case OK');
  FContext.AssertTrue((T)=(Ini.ReadTime('a','T',DT)), 'Value, key case not OK');
  FContext.AssertTrue((T)=(Ini.ReadTime('A','t',DT)), 'Value, section case not OK');
  FContext.AssertTrue((DT)=(Ini.ReadTime('C','t',DT)), 'Value, section not exist');
  FContext.AssertTrue((T)=(Ini.ReadTime('a','ft',DT)), 'Value, key exist as float');
end;

procedure TJSONIniTest.TestReadDateTime;
Var
  DT,DDT : TDateTime;

begin
  DT:=EncodeDate(2001,05,06)+EncodeTime(23,24,25,678);
  DDT:=EncodeDate(1999,11,12)+EncodeTime(1,2,3,4);
  SampleFile;
  FContext.AssertTrue((DT)=(Ini.ReadDateTime('a','dt',DDT)), 'Value, case OK');
  FContext.AssertTrue((DT)=(Ini.ReadDateTime('a','DT',DDT)), 'Value, key case not OK');
  FContext.AssertTrue((DT)=(Ini.ReadDateTime('A','dt',DDT)), 'Value, section case not OK');
  FContext.AssertTrue((DDT)=(Ini.ReadDateTime('C','dt',DDT)), 'Value, section not exist');
  FContext.AssertTrue((DT)=(Ini.ReadDateTime('a','fdt',DDT)), 'Value, key exist as float');
end;

procedure TJSONIniTest.TestEraseSection;
begin
  SampleFile;
  Ini.EraseSection('B');
  Ini.UpdateFile;
  ReadFile;
  FContext.AssertTrue((-1)=(ObjFileContent.IndexOfName('B')), 'No more section');
end;

procedure TJSONIniTest.TestEraseSectionCaseMismatch;
begin
  SampleFile;
  Ini.EraseSection('b');
  Ini.UpdateFile;
  ReadFile;
  FContext.AssertTrue((-1)=(ObjFileContent.IndexOfName('B')), 'No more section');
end;

procedure TJSONIniTest.TestDeleteKey;
begin
  SampleFile;
  Ini.DeleteKey('a','i');
  Ini.UpdateFile;
  ReadFile;
  FContext.AssertTrue((-1)=(ObjFileContent.Objects['a'].IndexOfName('i')), 'No more key');
end;

procedure TJSONIniTest.TestDeleteKeySectionCaseMismatch;
begin
  SampleFile;
  Ini.DeleteKey('A','i');
  Ini.UpdateFile;
  ReadFile;
  FContext.AssertTrue((-1)=(ObjFileContent.Objects['a'].IndexOfName('i')), 'No more key');
end;

procedure TJSONIniTest.TestDeleteKeyKeyCaseMismatch;
begin
  SampleFile;
  Ini.DeleteKey('a','I');
  Ini.UpdateFile;
  ReadFile;
  FContext.AssertTrue((-1)=(ObjFileContent.Objects['a'].IndexOfName('i')), 'No more key');
end;

procedure TJSONIniTest.AssertValue(const aSection,Akey,avalue : string);

Var
  D : TJSONData;

begin
  ini.UpdateFile;
  ReadFile;
  D:=ObjFileContent.FindPath(asection+'.'+akey);
  FContext.AssertTrue((D)<>nil, 'Have value at '+asection+'.'+akey);
  FContext.AssertTrue((AValue)=(D.AsString), 'Correct value at '+asection+'.'+akey);
end;

procedure TJSONIniTest.NoFileYet;

begin
  FContext.AssertTrue(not (FileExists(TestFile)), 'File not exist yet');
end;

procedure TJSONIniTest.HaveFile;

begin
  FContext.AssertTrue(FileExists(TestFile), 'Test file exists');
end;

procedure TJSONIniTest.ReLoad;
begin
  FreeAndNil(Fini);
  FContext.AssertTrue((Ini)<>nil, '');
end;

procedure TJSONIniTest.RemoveFile;
begin
  if FileExists(TestFile) then
    FContext.AssertTrue(DeleteFile(TestFile), 'Deleted file');
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
  FContext.AssertTrue(('string2')=(Ini.ReadString('a','i','')), 'Can read value');
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
  FContext.AssertTrue((3)=(Ini.ReadInteger('a','i',0)), 'Can read value');
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
  FContext.AssertTrue((D+1)=(Ini.ReadDate('a','i',0)), 'Can read value');
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
  FContext.AssertTrue((D+1)=(Ini.ReadDateTime('a','i',0)), 'Can read value');
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
  FContext.AssertTrue((D2)=(Ini.ReadTime('a','i',0)), 'Can read value');
end;

procedure TJSONIniTest.CreateIni;

Var
  M : TMemIniFile;
  D,DT,T : TDateTime;

begin
  D:=EncodeDate(2001,2,3);
  T:=EncodeTime(12,13,14,567);
  DT:=D+T;
  if FileExists(FCaseName+'.ini') then
    DeleteFile(FCaseName+'.ini');
  M:=TMemIniFile.Create(FCaseName+'.ini');
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
  TJSONIniFile.ConvertIni(FCaseName+'.ini',TestFile,False);
  FContext.AssertTrue(('c')=(Ini.ReadString('a','s','')), 'String');
  FContext.AssertTrue((2)=(Ini.ReadInteger('a','i',1)), 'Integer');
  FContext.AssertTrue((True)=(Ini.ReadBool('a','b',False)), 'Bool');
  FContext.AssertTrue((Int64(Maxint*2))=(Ini.ReadInt64('a','i6',Maxint*2)), 'Int64');
  FContext.AssertTrue((D)=(Ini.ReadDate('a','d',0)), 'Date');
  FContext.AssertTrue((T)=(Ini.ReadTime('a','t',0)), 'Time');
  FContext.AssertTrue((DT)=(Ini.ReadDateTime('a','dt',0)), 'DateTime');
  FContext.AssertTrue((1.23)=(Ini.ReadFloat('a','f',0)), 'Float');
  if FileExists(FCaseName+'.ini') then
    DeleteFile(FCaseName+'.ini');
end;

procedure TJSONIniTest.TestConvertIniString;
Var
  D,DT,T : TDateTime;

begin
  D:=EncodeDate(2001,2,3);
  T:=EncodeTime(12,13,14,567);
  DT:=D+T;
  CreateIni;
  TJSONIniFile.ConvertIni(FCaseName+'.ini',TestFile,True);
  FContext.AssertTrue(('c')=(Ini.ReadString('a','s','')), 'String');
  FContext.AssertTrue((2)=(Ini.ReadInteger('a','i',1)), 'Integer');
  FContext.AssertTrue((True)=(Ini.ReadBool('a','b',False)), 'Bool');
  FContext.AssertTrue((Int64(Maxint*2))=(Ini.ReadInt64('a','i6',Maxint*2)), 'Int64');
  FContext.AssertTrue((DateToStr(D))=(Ini.ReadString('a','d','')), 'Date');
  FContext.AssertTrue((TimeToStr(T))=(Ini.ReadString('a','t','')), 'Time');
  FContext.AssertTrue((DateTimeToStr(DT))=(Ini.ReadString('a','dt','')), 'DateTime');
  FContext.AssertTrue((1.23)=(Ini.ReadFloat('a','f',0)), 'Float');
  if FileExists(FCaseName+'.ini') then
    DeleteFile(FCaseName+'.ini');
end;


procedure RunTJSONIniTestTestEmpty(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmpty';
    lFixture.SetUp;
    try lFixture.TestEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadEmpty(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestReadEmpty';
    lFixture.SetUp;
    try lFixture.TestReadEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadEmptyValue(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestReadEmptyValue';
    lFixture.SetUp;
    try lFixture.TestReadEmptyValue; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadEmptyObject(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestReadEmptyObject';
    lFixture.SetUp;
    try lFixture.TestReadEmptyObject; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestRead1EmptySection(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRead1EmptySection';
    lFixture.SetUp;
    try lFixture.TestRead1EmptySection; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadSections(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestReadSections';
    lFixture.SetUp;
    try lFixture.TestReadSections; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadSection(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestReadSection';
    lFixture.SetUp;
    try lFixture.TestReadSection; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadSectionValues(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestReadSectionValues';
    lFixture.SetUp;
    try lFixture.TestReadSectionValues; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadString(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestReadString';
    lFixture.SetUp;
    try lFixture.TestReadString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadInteger(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestReadInteger';
    lFixture.SetUp;
    try lFixture.TestReadInteger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadInt64(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestReadInt64';
    lFixture.SetUp;
    try lFixture.TestReadInt64; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadFloat(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestReadFloat';
    lFixture.SetUp;
    try lFixture.TestReadFloat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadBoolean(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestReadBoolean';
    lFixture.SetUp;
    try lFixture.TestReadBoolean; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadDate(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestReadDate';
    lFixture.SetUp;
    try lFixture.TestReadDate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadTime(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestReadTime';
    lFixture.SetUp;
    try lFixture.TestReadTime; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestReadDateTime(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestReadDateTime';
    lFixture.SetUp;
    try lFixture.TestReadDateTime; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestEraseSection(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEraseSection';
    lFixture.SetUp;
    try lFixture.TestEraseSection; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestEraseSectionCaseMismatch(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEraseSectionCaseMismatch';
    lFixture.SetUp;
    try lFixture.TestEraseSectionCaseMismatch; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestDeleteKey(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDeleteKey';
    lFixture.SetUp;
    try lFixture.TestDeleteKey; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestDeleteKeySectionCaseMismatch(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDeleteKeySectionCaseMismatch';
    lFixture.SetUp;
    try lFixture.TestDeleteKeySectionCaseMismatch; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestDeleteKeyKeyCaseMismatch(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDeleteKeyKeyCaseMismatch';
    lFixture.SetUp;
    try lFixture.TestDeleteKeyKeyCaseMismatch; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestWriteString(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestWriteString';
    lFixture.SetUp;
    try lFixture.TestWriteString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestWriteInteger(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestWriteInteger';
    lFixture.SetUp;
    try lFixture.TestWriteInteger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestWriteDate(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestWriteDate';
    lFixture.SetUp;
    try lFixture.TestWriteDate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestWriteDateTime(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestWriteDateTime';
    lFixture.SetUp;
    try lFixture.TestWriteDateTime; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestWriteTime(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestWriteTime';
    lFixture.SetUp;
    try lFixture.TestWriteTime; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestConvertIni(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestConvertIni';
    lFixture.SetUp;
    try lFixture.TestConvertIni; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTJSONIniTestTestConvertIniString(AContext: TNXTestContext);
var lFixture: TJSONIniTest;
begin
  lFixture:=TJSONIniTest.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestConvertIniString';
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

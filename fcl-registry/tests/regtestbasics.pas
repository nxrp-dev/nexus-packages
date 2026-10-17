unit RegTestBasics;

{$IFDEF FPC}
  {$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils;

type

  { TTestBasics }

  TTestBasics = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    procedure DeleteUserXmlFile;
  protected
  public
    procedure TestSimpleWinRegistry;
    procedure TestDoubleWrite;
    procedure bug16395;
    procedure TestStringList;
    Procedure TestInt64;
    Procedure TestDeleteSubkey;
  end;

procedure RegisterRegTestBasicsTests(ARegistry: TNXTestRegistry);

implementation

uses
  registry;

{ TTestBasics }

procedure TTestBasics.DeleteUserXmlFile;
{$ifndef windows}
var
  fn: string;
{$endif}
begin
{$ifdef windows}
  with TRegistry.Create do
    try
      DeleteKey('FirstNode');
    finally
      Free;
    end;
{$else}
  {$ifdef XMLRegfile_in_CurDir}
  FN := IncludeTrailingPathDelimiter(GetCurrentDir) + 'reg.xml';
  {$else}
  FN:=includetrailingpathdelimiter(GetAppConfigDir(False))+'reg.xml';
  {$endif}
  if FileExists(FN) then
    TestContext.AssertTrue(DeleteFile(FN), '');
{$endif}
end;

procedure TTestBasics.TestSimpleWinRegistry;
var
  Registry : TRegistry;
begin
  Registry := TRegistry.Create(KEY_READ);
  Registry.RootKey:=HKEY_LOCAL_MACHINE;

  // use a hopefully non existing key
  TestContext.AssertTrue(not (Registry.KeyExists('FPC1234')), '');
{$ifdef windows}
  TestContext.AssertTrue(Registry.KeyExists('SOFTWARE'), '');
{$endif}

  Registry.Free;
end;

procedure TTestBasics.TestDoubleWrite;
begin
  DeleteUserXmlFile;
  with TRegistry.Create do
    try
      OpenKey('FirstNode', true);
      WriteString('LAYOUT', '');
      CloseKey;
    finally
      Free;
    end;
  with TRegistry.Create do
    try
      OpenKey('FirstNode', true);
      WriteString('LAYOUT', '');
      CloseKey;
    finally
      Free;
    end;
  DeleteUserXmlFile;
end;

procedure TTestBasics.bug16395;
var
  r: TRegistry;
  s,t: string;
begin
  DeleteUserXmlFile;

  r := TRegistry.Create;
  try
    r.RootKey := HKEY_CURRENT_USER;
    r.OpenKey('FirstNode', true);
    r.WriteString('string1', '');
    r.CloseKey;
  finally
    r.Free;
  end;

  // verify that empty value can be changed to non-empty one
  r := TRegistry.Create;
  try
    r.RootKey := HKEY_CURRENT_USER;
    r.OpenKey('FirstNode',false);
    s := r.ReadString('string1');
    TestContext.AssertTrue(('')=(s), 'Failed to read back an empty string');
    r.WriteString('string1', 'string_value_1');
    r.CloseKey;
  finally
    r.Free;
  end;

  // verify that non-empty value can be changed to empty one
  r := TRegistry.Create;
  try
    r.RootKey := HKEY_CURRENT_USER;
    r.OpenKey('FirstNode',false);
    s := r.ReadString('string1');
    TestContext.AssertTrue(('string_value_1')=(s), 'Failed changing empty string value to non-empty one');

    r.WriteString('string1', '');
    r.CloseKey;
  finally
    r.Free;
  end;

  r := TRegistry.Create;
  try
    r.RootKey := HKEY_CURRENT_USER;
    r.OpenKey('FirstNode',false);
    s := r.ReadString('string1');
    TestContext.AssertTrue(('')=(s), 'Failed changing non-empty string value to empty one');
    r.CloseKey;
  finally
    r.Free;
  end;

  r := TRegistry.Create;
  try
    r.RootKey := HKEY_CURRENT_USER;
    r.OpenKey('LongNode',true);
    t:=StringOfChar('*',4000);
    r.WriteString('LongString',T);
    s := r.ReadString('LongString');
    TestContext.AssertTrue((t)=(s), 'Writing long string works OK');
    r.CloseKey;
  finally
    r.Free;
  end;

  DeleteUserXmlFile;
end;

Procedure TTestBasics.TestStringList;

Var
  SL : TStringList;
  I : Integer;

begin
  With TRegistry.Create do
    try
      RootKey:=HKEY_CURRENT_USER;
      OpenKey('Software/Test',True);
      SL:=TstringList.Create;
      For I:=0 to 10 do
        SL.Add(IntToStr(I));
      WriteStringList('me',SL);
      SL.Clear;
      ReadStringList('me',SL);
      For I:=0 to 10 do
        TestContext.AssertTrue((IntToStr(I))=(SL[I]), 'String '+IntToStr(i));
    finally
      Free;
    end;
end;


procedure TTestBasics.TestInt64;



Var
  Def,I64 : Int64;

begin
  def:=MaxInt*1024;
  With TRegistry.Create do
    try
      RootKey:=HKEY_CURRENT_USER;
      OpenKey('Software/Test',True);
      WriteInt64('you',Def);
      I64:=ReadInt64('you');
      TestContext.AssertTrue((Def)=(I64), 'Value written and read');
    finally
      Free;
    end;
end;

procedure TTestBasics.TestDeleteSubKey;

const
  BugID = 'Bug35132';
  Base = 'Software\' + BugID;
  One = 'One';
  OneFull = Base + '\' + One;
  Two = 'Two';
  TwoFull = OneFull + '\' + Two;


procedure CleanUp(AssertionFailed: Boolean);
var
  R: TRegistry;
  B: Boolean;
begin
  R := TRegistry.Create(KEY_ALL_ACCESS);
  try
  R.RootKey := HKEY_CURRENT_USER;
  if R.KeyExists(TwoFull) then
  begin
    B := R. DeleteKey(TwoFull);
    if B then B := R.DeleteKey(OneFull);
    if B then B := R.DeleteKey(Base);
    TestContext.AssertTrue(B, 'cleanup OK');
  end;
  finally
    R.Free;
  end;
end;

var
  R: TRegistry;
  B: Boolean;
begin
  R := TRegistry.Create(KEY_ALL_ACCESS);
  try
    R.RootKey := HKEY_CURRENT_USER;

    B := R.OpenKey(Base, True);
    TestContext.AssertTrue(B, format('OpenKey(''%s'') failed.',[Base]));

    B := R.OpenKey('One',True);
    TestContext.AssertTrue(B, format('OpenKey(''%s'') failed.',[OneFull]));

    B := R.OpenKey('Two',True);
    TestContext.AssertTrue(B, format('OpenKey(''%s'') failed.',[TwoFull]));

    R.CloseKey;

    B := R.KeyExists(TwoFull);
    TestContext.AssertTrue(B, format('KeyExists(''%s'') failed.',[TwoFull]));

    R.CloseKey;
    B := R.OpenKey(Base,False);
    TestContext.AssertTrue(B, format('OpenKey(''%s'') failed.',[Base]));

    B := R.DeleteKey('One');
    TestContext.AssertTrue(B, format('DeleteKey(''%s'') should have succeeded, but it failed.',[OneFull]));
  finally
    R.Free;
    CleanUp(ExceptObject <> nil);
  end;
end;



constructor TTestBasics.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestBasicsTestSimpleWinRegistry(AContext: TNXTestContext);
var lFixture: TTestBasics;
begin
  lFixture:=TTestBasics.Create(AContext, 'TestSimpleWinRegistry');
  try
    lFixture.TestSimpleWinRegistry;
  finally lFixture.Free; end;
end;

procedure RunTTestBasicsTestDoubleWrite(AContext: TNXTestContext);
var lFixture: TTestBasics;
begin
  lFixture:=TTestBasics.Create(AContext, 'TestDoubleWrite');
  try
    lFixture.TestDoubleWrite;
  finally lFixture.Free; end;
end;

procedure RunTTestBasicsbug16395(AContext: TNXTestContext);
var lFixture: TTestBasics;
begin
  lFixture:=TTestBasics.Create(AContext, 'bug16395');
  try
    lFixture.bug16395;
  finally lFixture.Free; end;
end;

procedure RunTTestBasicsTestStringList(AContext: TNXTestContext);
var lFixture: TTestBasics;
begin
  lFixture:=TTestBasics.Create(AContext, 'TestStringList');
  try
    lFixture.TestStringList;
  finally lFixture.Free; end;
end;

procedure RunTTestBasicsTestInt64(AContext: TNXTestContext);
var lFixture: TTestBasics;
begin
  lFixture:=TTestBasics.Create(AContext, 'TestInt64');
  try
    lFixture.TestInt64;
  finally lFixture.Free; end;
end;

procedure RunTTestBasicsTestDeleteSubkey(AContext: TNXTestContext);
var lFixture: TTestBasics;
begin
  lFixture:=TTestBasics.Create(AContext, 'TestDeleteSubkey');
  try
    lFixture.TestDeleteSubkey;
  finally lFixture.Free; end;
end;

procedure RegisterRegTestBasicsTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('RegTestBasics.TTestBasics');
  lSuite.AddTest('TestSimpleWinRegistry', @RunTTestBasicsTestSimpleWinRegistry);
  lSuite.AddTest('TestDoubleWrite', @RunTTestBasicsTestDoubleWrite);
  lSuite.AddTest('bug16395', @RunTTestBasicsbug16395);
  lSuite.AddTest('TestStringList', @RunTTestBasicsTestStringList);
  lSuite.AddTest('TestInt64', @RunTTestBasicsTestInt64);
  lSuite.AddTest('TestDeleteSubkey', @RunTTestBasicsTestDeleteSubkey);
end;

end.

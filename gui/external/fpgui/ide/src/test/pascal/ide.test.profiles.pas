{
    fpGUI IDE - Profile Management Tests

    Tests for pure functions in ide.profiles: profile toggling and
    display text generation.
}
unit ide.test.profiles;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  ide.profiles;

type

  { TTestToggleProfileInList }

  TTestToggleProfileInList = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    procedure TestAddProfile;
    procedure TestRemoveProfile;
    procedure TestToggleTwiceRestores;
  end;

  { TTestProfilesDisplayText }

  TTestProfilesDisplayText = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    procedure TestEmptyList;
    procedure TestSingleProfile;
    procedure TestMultipleProfiles;
  end;

procedure RegisteridetestprofilesTests(ARegistry: TNXTestRegistry);

implementation

{ TTestToggleProfileInList }

procedure TTestToggleProfileInList.TestAddProfile;
var
  list: TStringList;
begin
  list := TStringList.Create;
  try
    ToggleProfileInList(list, 'unix');
    TestContext.AssertTrue((1)=(list.Count), 'should have one item');
    TestContext.AssertTrue(('unix')=(list[0]), 'should contain unix');
  finally
    list.Free;
  end;
end;

procedure TTestToggleProfileInList.TestRemoveProfile;
var
  list: TStringList;
begin
  list := TStringList.Create;
  try
    list.Add('unix');
    list.Add('debug');
    ToggleProfileInList(list, 'unix');
    TestContext.AssertTrue((1)=(list.Count), 'should have one item');
    TestContext.AssertTrue(('debug')=(list[0]), 'remaining should be debug');
  finally
    list.Free;
  end;
end;

procedure TTestToggleProfileInList.TestToggleTwiceRestores;
var
  list: TStringList;
begin
  list := TStringList.Create;
  try
    ToggleProfileInList(list, 'agg');
    ToggleProfileInList(list, 'agg');
    TestContext.AssertTrue((0)=(list.Count), 'toggling twice should leave list empty');
  finally
    list.Free;
  end;
end;

{ TTestProfilesDisplayText }

procedure TTestProfilesDisplayText.TestEmptyList;
var
  list: TStringList;
begin
  list := TStringList.Create;
  try
    TestContext.AssertTrue(('(no profiles)')=(ProfilesDisplayText(list)), 'empty list should show placeholder');
  finally
    list.Free;
  end;
end;

procedure TTestProfilesDisplayText.TestSingleProfile;
var
  list: TStringList;
begin
  list := TStringList.Create;
  try
    list.Add('unix');
    TestContext.AssertTrue(('unix')=(ProfilesDisplayText(list)), 'single profile');
  finally
    list.Free;
  end;
end;

procedure TTestProfilesDisplayText.TestMultipleProfiles;
var
  list: TStringList;
begin
  list := TStringList.Create;
  try
    list.Add('unix');
    list.Add('debug');
    TestContext.AssertTrue(('unix,debug')=(ProfilesDisplayText(list)), 'multiple profiles');
  finally
    list.Free;
  end;
end;


constructor TTestToggleProfileInList.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

constructor TTestProfilesDisplayText.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestToggleProfileInListTestAddProfile(AContext: TNXTestContext);
var lFixture: TTestToggleProfileInList;
begin
  lFixture:=TTestToggleProfileInList.Create(AContext, 'TestAddProfile');
  try
    lFixture.TestAddProfile;
  finally lFixture.Free; end;
end;

procedure RunTTestToggleProfileInListTestRemoveProfile(AContext: TNXTestContext);
var lFixture: TTestToggleProfileInList;
begin
  lFixture:=TTestToggleProfileInList.Create(AContext, 'TestRemoveProfile');
  try
    lFixture.TestRemoveProfile;
  finally lFixture.Free; end;
end;

procedure RunTTestToggleProfileInListTestToggleTwiceRestores(AContext: TNXTestContext);
var lFixture: TTestToggleProfileInList;
begin
  lFixture:=TTestToggleProfileInList.Create(AContext, 'TestToggleTwiceRestores');
  try
    lFixture.TestToggleTwiceRestores;
  finally lFixture.Free; end;
end;

procedure RunTTestProfilesDisplayTextTestEmptyList(AContext: TNXTestContext);
var lFixture: TTestProfilesDisplayText;
begin
  lFixture:=TTestProfilesDisplayText.Create(AContext, 'TestEmptyList');
  try
    lFixture.TestEmptyList;
  finally lFixture.Free; end;
end;

procedure RunTTestProfilesDisplayTextTestSingleProfile(AContext: TNXTestContext);
var lFixture: TTestProfilesDisplayText;
begin
  lFixture:=TTestProfilesDisplayText.Create(AContext, 'TestSingleProfile');
  try
    lFixture.TestSingleProfile;
  finally lFixture.Free; end;
end;

procedure RunTTestProfilesDisplayTextTestMultipleProfiles(AContext: TNXTestContext);
var lFixture: TTestProfilesDisplayText;
begin
  lFixture:=TTestProfilesDisplayText.Create(AContext, 'TestMultipleProfiles');
  try
    lFixture.TestMultipleProfiles;
  finally lFixture.Free; end;
end;

procedure RegisteridetestprofilesTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.profiles.TTestToggleProfileInList');
  lSuite.AddTest('TestAddProfile', @RunTTestToggleProfileInListTestAddProfile);
  lSuite.AddTest('TestRemoveProfile', @RunTTestToggleProfileInListTestRemoveProfile);
  lSuite.AddTest('TestToggleTwiceRestores', @RunTTestToggleProfileInListTestToggleTwiceRestores);
  lSuite:=ARegistry.AddSuite('ide.test.profiles.TTestProfilesDisplayText');
  lSuite.AddTest('TestEmptyList', @RunTTestProfilesDisplayTextTestEmptyList);
  lSuite.AddTest('TestSingleProfile', @RunTTestProfilesDisplayTextTestSingleProfile);
  lSuite.AddTest('TestMultipleProfiles', @RunTTestProfilesDisplayTextTestMultipleProfiles);
end;

end.

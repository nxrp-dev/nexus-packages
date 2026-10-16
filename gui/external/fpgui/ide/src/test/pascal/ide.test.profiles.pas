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
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  public
    procedure TestAddProfile;
    procedure TestRemoveProfile;
    procedure TestToggleTwiceRestores;
  end;

  { TTestProfilesDisplayText }

  TTestProfilesDisplayText = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
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
    FContext.AssertTrue((1)=(list.Count), 'should have one item');
    FContext.AssertTrue(('unix')=(list[0]), 'should contain unix');
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
    FContext.AssertTrue((1)=(list.Count), 'should have one item');
    FContext.AssertTrue(('debug')=(list[0]), 'remaining should be debug');
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
    FContext.AssertTrue((0)=(list.Count), 'toggling twice should leave list empty');
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
    FContext.AssertTrue(('(no profiles)')=(ProfilesDisplayText(list)), 'empty list should show placeholder');
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
    FContext.AssertTrue(('unix')=(ProfilesDisplayText(list)), 'single profile');
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
    FContext.AssertTrue(('unix,debug')=(ProfilesDisplayText(list)), 'multiple profiles');
  finally
    list.Free;
  end;
end;


procedure RunTTestToggleProfileInListTestAddProfile(AContext: TNXTestContext);
var lFixture: TTestToggleProfileInList;
begin
  lFixture:=TTestToggleProfileInList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAddProfile';
    lFixture.TestAddProfile;
  finally lFixture.Free; end;
end;

procedure RunTTestToggleProfileInListTestRemoveProfile(AContext: TNXTestContext);
var lFixture: TTestToggleProfileInList;
begin
  lFixture:=TTestToggleProfileInList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestRemoveProfile';
    lFixture.TestRemoveProfile;
  finally lFixture.Free; end;
end;

procedure RunTTestToggleProfileInListTestToggleTwiceRestores(AContext: TNXTestContext);
var lFixture: TTestToggleProfileInList;
begin
  lFixture:=TTestToggleProfileInList.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestToggleTwiceRestores';
    lFixture.TestToggleTwiceRestores;
  finally lFixture.Free; end;
end;

procedure RunTTestProfilesDisplayTextTestEmptyList(AContext: TNXTestContext);
var lFixture: TTestProfilesDisplayText;
begin
  lFixture:=TTestProfilesDisplayText.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmptyList';
    lFixture.TestEmptyList;
  finally lFixture.Free; end;
end;

procedure RunTTestProfilesDisplayTextTestSingleProfile(AContext: TNXTestContext);
var lFixture: TTestProfilesDisplayText;
begin
  lFixture:=TTestProfilesDisplayText.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSingleProfile';
    lFixture.TestSingleProfile;
  finally lFixture.Free; end;
end;

procedure RunTTestProfilesDisplayTextTestMultipleProfiles(AContext: TNXTestContext);
var lFixture: TTestProfilesDisplayText;
begin
  lFixture:=TTestProfilesDisplayText.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMultipleProfiles';
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

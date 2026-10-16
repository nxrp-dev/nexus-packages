{
    fpGUI IDE - Editor Theme Tests

    Tests for TEditorTheme loading, saving, and built-in themes.
}
unit ide.test.editortheme;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  fpg_base,
  ide.highlighter,
  ide.editor.theme;

type

  { TTestEditorTheme }

  TTestEditorTheme = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    { Built-in themes }
    procedure TestDefaultThemeHasName;
    procedure TestDarkThemeHasName;
    procedure TestSolarizedDarkThemeHasName;
    procedure TestSolarizedLightThemeHasName;

    { Theme structure }
    procedure TestDefaultThemeBackground;
    procedure TestDefaultThemeKeywordStyle;
    procedure TestDefaultThemeCommentStyle;
    procedure TestDarkThemeBackground;

    { Category name mapping }
    procedure TestCategoryToName;
    procedure TestNameToCategory;
    procedure TestNameToCategoryInvalid;

    { INI round-trip }
    procedure TestSaveAndLoadRoundTrip;

    { INI loading from built-in files }
    procedure TestLoadDefaultINI;
    procedure TestLoadDarkINI;
    procedure TestLoadSolarizedDarkINI;
    procedure TestLoadSolarizedLightINI;

    { Style flags }
    procedure TestBoldStyleFlag;
    procedure TestItalicStyleFlag;

    { Colour format }
    procedure TestTokenBackgroundDefault;
  end;


procedure RegisteridetesteditorthemeTests(ARegistry: TNXTestRegistry);

implementation

uses
  IniFiles;

const
  { pasbuild copies resources to ide/target/ alongside the TestRunner binary }
  cThemeDir = 'editor-themes/';


{ TTestEditorTheme }

procedure TTestEditorTheme.TestDefaultThemeHasName;
var
  t: TEditorTheme;
begin
  t := DefaultTheme;
  TestContext.AssertTrue(('Default')=(t.Name), '');
end;

procedure TTestEditorTheme.TestDarkThemeHasName;
var
  t: TEditorTheme;
begin
  t := DarkTheme;
  TestContext.AssertTrue(('Dark')=(t.Name), '');
end;

procedure TTestEditorTheme.TestSolarizedDarkThemeHasName;
var
  t: TEditorTheme;
begin
  t := SolarizedDarkTheme;
  TestContext.AssertTrue(('Solarized Dark')=(t.Name), '');
end;

procedure TTestEditorTheme.TestSolarizedLightThemeHasName;
var
  t: TEditorTheme;
begin
  t := SolarizedLightTheme;
  TestContext.AssertTrue(('Solarized Light')=(t.Name), '');
end;

procedure TTestEditorTheme.TestDefaultThemeBackground;
var
  t: TEditorTheme;
begin
  t := DefaultTheme;
  TestContext.AssertTrue((Integer(clWhite))=(Integer(t.Chrome.Background)), 'white background');
end;

procedure TTestEditorTheme.TestDefaultThemeKeywordStyle;
var
  t: TEditorTheme;
begin
  t := DefaultTheme;
  TestContext.AssertTrue(tsfBold in t.TokenStyles[hcKeyword1].Style, 'keyword1 bold');
end;

procedure TTestEditorTheme.TestDefaultThemeCommentStyle;
var
  t: TEditorTheme;
begin
  t := DefaultTheme;
  TestContext.AssertTrue(tsfItalic in t.TokenStyles[hcComment1].Style, 'comment1 italic');
end;

procedure TTestEditorTheme.TestDarkThemeBackground;
var
  t: TEditorTheme;
begin
  t := DarkTheme;
  { Dark theme background should NOT be white }
  TestContext.AssertTrue(t.Chrome.Background <> clWhite, 'dark bg not white');
end;

procedure TTestEditorTheme.TestCategoryToName;
begin
  TestContext.AssertTrue(('Keyword1')=(CategoryToName(hcKeyword1)), '');
  TestContext.AssertTrue(('Comment1')=(CategoryToName(hcComment1)), '');
  TestContext.AssertTrue(('String1')=(CategoryToName(hcString1)), '');
  TestContext.AssertTrue(('Number')=(CategoryToName(hcNumber)), '');
  TestContext.AssertTrue(('Invalid')=(CategoryToName(hcInvalid)), '');
end;

procedure TTestEditorTheme.TestNameToCategory;
var
  cat: THighlightCategory;
begin
  TestContext.AssertTrue(NameToCategory('Keyword1', cat), 'find Keyword1');
  TestContext.AssertTrue(cat = hcKeyword1, 'is hcKeyword1');
  TestContext.AssertTrue(NameToCategory('Comment2', cat), 'find Comment2');
  TestContext.AssertTrue(cat = hcComment2, 'is hcComment2');
end;

procedure TTestEditorTheme.TestNameToCategoryInvalid;
var
  cat: THighlightCategory;
begin
  TestContext.AssertTrue(not (NameToCategory('NonExistent', cat)), 'unknown name');
end;

procedure TTestEditorTheme.TestSaveAndLoadRoundTrip;
var
  orig, loaded: TEditorTheme;
  fn: string;
begin
  fn := GetTempFileName('/tmp/', 'theme_test_');
  fn := fn + '.ini';
  try
    orig := DarkTheme;
    SaveThemeToINI(orig, fn);
    loaded := LoadThemeFromINI(fn);
    TestContext.AssertTrue((orig.Name)=(loaded.Name), 'name');
    TestContext.AssertTrue((Integer(orig.Chrome.Background))=(Integer(loaded.Chrome.Background)), 'bg');
    TestContext.AssertTrue((Integer(orig.Chrome.Foreground))=(Integer(loaded.Chrome.Foreground)), 'fg');
    TestContext.AssertTrue((Integer(orig.TokenStyles[hcKeyword1].Foreground))=(Integer(loaded.TokenStyles[hcKeyword1].Foreground)), 'kw1 fg');
    TestContext.AssertTrue(tsfBold in loaded.TokenStyles[hcKeyword1].Style, 'kw1 bold');
    TestContext.AssertTrue(tsfItalic in loaded.TokenStyles[hcComment1].Style, 'comment italic');
  finally
    if FileExists(fn) then
      DeleteFile(fn);
  end;
end;

procedure TTestEditorTheme.TestLoadDefaultINI;
var
  t: TEditorTheme;
  fn: string;
begin
  fn := cThemeDir + 'default.ini';
  if not FileExists(fn) then
  begin
    TestContext.Fail('Theme file not found: ' + fn);
    Exit;
  end;
  t := LoadThemeFromINI(fn);
  TestContext.AssertTrue(('Default')=(t.Name), '');
  TestContext.AssertTrue((Integer(clWhite))=(Integer(t.Chrome.Background)), 'bg white');
end;

procedure TTestEditorTheme.TestLoadDarkINI;
var
  t: TEditorTheme;
  fn: string;
begin
  fn := cThemeDir + 'dark.ini';
  if not FileExists(fn) then
  begin
    TestContext.Fail('Theme file not found: ' + fn);
    Exit;
  end;
  t := LoadThemeFromINI(fn);
  TestContext.AssertTrue(('Dark')=(t.Name), '');
end;

procedure TTestEditorTheme.TestLoadSolarizedDarkINI;
var
  t: TEditorTheme;
  fn: string;
begin
  fn := cThemeDir + 'solarized-dark.ini';
  if not FileExists(fn) then
  begin
    TestContext.Fail('Theme file not found: ' + fn);
    Exit;
  end;
  t := LoadThemeFromINI(fn);
  TestContext.AssertTrue(('Solarized Dark')=(t.Name), '');
end;

procedure TTestEditorTheme.TestLoadSolarizedLightINI;
var
  t: TEditorTheme;
  fn: string;
begin
  fn := cThemeDir + 'solarized-light.ini';
  if not FileExists(fn) then
  begin
    TestContext.Fail('Theme file not found: ' + fn);
    Exit;
  end;
  t := LoadThemeFromINI(fn);
  TestContext.AssertTrue(('Solarized Light')=(t.Name), '');
end;

procedure TTestEditorTheme.TestBoldStyleFlag;
var
  t: TEditorTheme;
begin
  t := DefaultTheme;
  TestContext.AssertTrue(tsfBold in t.TokenStyles[hcKeyword1].Style, 'keyword1 has bold');
  TestContext.AssertTrue(not (tsfItalic in t.TokenStyles[hcKeyword1].Style), 'keyword1 not italic');
end;

procedure TTestEditorTheme.TestItalicStyleFlag;
var
  t: TEditorTheme;
begin
  t := DefaultTheme;
  TestContext.AssertTrue(tsfItalic in t.TokenStyles[hcComment1].Style, 'comment1 has italic');
  TestContext.AssertTrue(not (tsfBold in t.TokenStyles[hcComment1].Style), 'comment1 not bold');
end;

procedure TTestEditorTheme.TestTokenBackgroundDefault;
var
  t: TEditorTheme;
begin
  { Token backgrounds should default to clNone (use editor background) }
  t := DefaultTheme;
  TestContext.AssertTrue((Integer(clNone))=(Integer(t.TokenStyles[hcIdentifier].Background)), 'identifier bg is clNone');
end;


constructor TTestEditorTheme.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestEditorThemeTestDefaultThemeHasName(AContext: TNXTestContext);
var lFixture: TTestEditorTheme;
begin
  lFixture:=TTestEditorTheme.Create(AContext, 'TestDefaultThemeHasName');
  try
    lFixture.TestDefaultThemeHasName;
  finally lFixture.Free; end;
end;

procedure RunTTestEditorThemeTestDarkThemeHasName(AContext: TNXTestContext);
var lFixture: TTestEditorTheme;
begin
  lFixture:=TTestEditorTheme.Create(AContext, 'TestDarkThemeHasName');
  try
    lFixture.TestDarkThemeHasName;
  finally lFixture.Free; end;
end;

procedure RunTTestEditorThemeTestSolarizedDarkThemeHasName(AContext: TNXTestContext);
var lFixture: TTestEditorTheme;
begin
  lFixture:=TTestEditorTheme.Create(AContext, 'TestSolarizedDarkThemeHasName');
  try
    lFixture.TestSolarizedDarkThemeHasName;
  finally lFixture.Free; end;
end;

procedure RunTTestEditorThemeTestSolarizedLightThemeHasName(AContext: TNXTestContext);
var lFixture: TTestEditorTheme;
begin
  lFixture:=TTestEditorTheme.Create(AContext, 'TestSolarizedLightThemeHasName');
  try
    lFixture.TestSolarizedLightThemeHasName;
  finally lFixture.Free; end;
end;

procedure RunTTestEditorThemeTestDefaultThemeBackground(AContext: TNXTestContext);
var lFixture: TTestEditorTheme;
begin
  lFixture:=TTestEditorTheme.Create(AContext, 'TestDefaultThemeBackground');
  try
    lFixture.TestDefaultThemeBackground;
  finally lFixture.Free; end;
end;

procedure RunTTestEditorThemeTestDefaultThemeKeywordStyle(AContext: TNXTestContext);
var lFixture: TTestEditorTheme;
begin
  lFixture:=TTestEditorTheme.Create(AContext, 'TestDefaultThemeKeywordStyle');
  try
    lFixture.TestDefaultThemeKeywordStyle;
  finally lFixture.Free; end;
end;

procedure RunTTestEditorThemeTestDefaultThemeCommentStyle(AContext: TNXTestContext);
var lFixture: TTestEditorTheme;
begin
  lFixture:=TTestEditorTheme.Create(AContext, 'TestDefaultThemeCommentStyle');
  try
    lFixture.TestDefaultThemeCommentStyle;
  finally lFixture.Free; end;
end;

procedure RunTTestEditorThemeTestDarkThemeBackground(AContext: TNXTestContext);
var lFixture: TTestEditorTheme;
begin
  lFixture:=TTestEditorTheme.Create(AContext, 'TestDarkThemeBackground');
  try
    lFixture.TestDarkThemeBackground;
  finally lFixture.Free; end;
end;

procedure RunTTestEditorThemeTestCategoryToName(AContext: TNXTestContext);
var lFixture: TTestEditorTheme;
begin
  lFixture:=TTestEditorTheme.Create(AContext, 'TestCategoryToName');
  try
    lFixture.TestCategoryToName;
  finally lFixture.Free; end;
end;

procedure RunTTestEditorThemeTestNameToCategory(AContext: TNXTestContext);
var lFixture: TTestEditorTheme;
begin
  lFixture:=TTestEditorTheme.Create(AContext, 'TestNameToCategory');
  try
    lFixture.TestNameToCategory;
  finally lFixture.Free; end;
end;

procedure RunTTestEditorThemeTestNameToCategoryInvalid(AContext: TNXTestContext);
var lFixture: TTestEditorTheme;
begin
  lFixture:=TTestEditorTheme.Create(AContext, 'TestNameToCategoryInvalid');
  try
    lFixture.TestNameToCategoryInvalid;
  finally lFixture.Free; end;
end;

procedure RunTTestEditorThemeTestSaveAndLoadRoundTrip(AContext: TNXTestContext);
var lFixture: TTestEditorTheme;
begin
  lFixture:=TTestEditorTheme.Create(AContext, 'TestSaveAndLoadRoundTrip');
  try
    lFixture.TestSaveAndLoadRoundTrip;
  finally lFixture.Free; end;
end;

procedure RunTTestEditorThemeTestLoadDefaultINI(AContext: TNXTestContext);
var lFixture: TTestEditorTheme;
begin
  lFixture:=TTestEditorTheme.Create(AContext, 'TestLoadDefaultINI');
  try
    lFixture.TestLoadDefaultINI;
  finally lFixture.Free; end;
end;

procedure RunTTestEditorThemeTestLoadDarkINI(AContext: TNXTestContext);
var lFixture: TTestEditorTheme;
begin
  lFixture:=TTestEditorTheme.Create(AContext, 'TestLoadDarkINI');
  try
    lFixture.TestLoadDarkINI;
  finally lFixture.Free; end;
end;

procedure RunTTestEditorThemeTestLoadSolarizedDarkINI(AContext: TNXTestContext);
var lFixture: TTestEditorTheme;
begin
  lFixture:=TTestEditorTheme.Create(AContext, 'TestLoadSolarizedDarkINI');
  try
    lFixture.TestLoadSolarizedDarkINI;
  finally lFixture.Free; end;
end;

procedure RunTTestEditorThemeTestLoadSolarizedLightINI(AContext: TNXTestContext);
var lFixture: TTestEditorTheme;
begin
  lFixture:=TTestEditorTheme.Create(AContext, 'TestLoadSolarizedLightINI');
  try
    lFixture.TestLoadSolarizedLightINI;
  finally lFixture.Free; end;
end;

procedure RunTTestEditorThemeTestBoldStyleFlag(AContext: TNXTestContext);
var lFixture: TTestEditorTheme;
begin
  lFixture:=TTestEditorTheme.Create(AContext, 'TestBoldStyleFlag');
  try
    lFixture.TestBoldStyleFlag;
  finally lFixture.Free; end;
end;

procedure RunTTestEditorThemeTestItalicStyleFlag(AContext: TNXTestContext);
var lFixture: TTestEditorTheme;
begin
  lFixture:=TTestEditorTheme.Create(AContext, 'TestItalicStyleFlag');
  try
    lFixture.TestItalicStyleFlag;
  finally lFixture.Free; end;
end;

procedure RunTTestEditorThemeTestTokenBackgroundDefault(AContext: TNXTestContext);
var lFixture: TTestEditorTheme;
begin
  lFixture:=TTestEditorTheme.Create(AContext, 'TestTokenBackgroundDefault');
  try
    lFixture.TestTokenBackgroundDefault;
  finally lFixture.Free; end;
end;

procedure RegisteridetesteditorthemeTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.editortheme.TTestEditorTheme');
  lSuite.AddTest('TestDefaultThemeHasName', @RunTTestEditorThemeTestDefaultThemeHasName);
  lSuite.AddTest('TestDarkThemeHasName', @RunTTestEditorThemeTestDarkThemeHasName);
  lSuite.AddTest('TestSolarizedDarkThemeHasName', @RunTTestEditorThemeTestSolarizedDarkThemeHasName);
  lSuite.AddTest('TestSolarizedLightThemeHasName', @RunTTestEditorThemeTestSolarizedLightThemeHasName);
  lSuite.AddTest('TestDefaultThemeBackground', @RunTTestEditorThemeTestDefaultThemeBackground);
  lSuite.AddTest('TestDefaultThemeKeywordStyle', @RunTTestEditorThemeTestDefaultThemeKeywordStyle);
  lSuite.AddTest('TestDefaultThemeCommentStyle', @RunTTestEditorThemeTestDefaultThemeCommentStyle);
  lSuite.AddTest('TestDarkThemeBackground', @RunTTestEditorThemeTestDarkThemeBackground);
  lSuite.AddTest('TestCategoryToName', @RunTTestEditorThemeTestCategoryToName);
  lSuite.AddTest('TestNameToCategory', @RunTTestEditorThemeTestNameToCategory);
  lSuite.AddTest('TestNameToCategoryInvalid', @RunTTestEditorThemeTestNameToCategoryInvalid);
  lSuite.AddTest('TestSaveAndLoadRoundTrip', @RunTTestEditorThemeTestSaveAndLoadRoundTrip);
  lSuite.AddTest('TestLoadDefaultINI', @RunTTestEditorThemeTestLoadDefaultINI);
  lSuite.AddTest('TestLoadDarkINI', @RunTTestEditorThemeTestLoadDarkINI);
  lSuite.AddTest('TestLoadSolarizedDarkINI', @RunTTestEditorThemeTestLoadSolarizedDarkINI);
  lSuite.AddTest('TestLoadSolarizedLightINI', @RunTTestEditorThemeTestLoadSolarizedLightINI);
  lSuite.AddTest('TestBoldStyleFlag', @RunTTestEditorThemeTestBoldStyleFlag);
  lSuite.AddTest('TestItalicStyleFlag', @RunTTestEditorThemeTestItalicStyleFlag);
  lSuite.AddTest('TestTokenBackgroundDefault', @RunTTestEditorThemeTestTokenBackgroundDefault);
end;

end.

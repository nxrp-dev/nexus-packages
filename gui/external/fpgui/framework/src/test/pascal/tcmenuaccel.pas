{
  Regression tests for TfpgMenuBar Alt+<letter> accelerator handling.

  The original code detected the Alt modifier by formatting the keystroke to
  text and sniffing the result:

      s := KeycodeToText(keycode, shiftstate);
      if (length(s) = 5) and (copy(s, 1, 4) = 'Alt+') then

  That has two defects:

    1. 'Alt+' is the resourcestring rsKeyAlt, so the hardcoded literal stops
       matching under any translation that localises it.
    2. The length test assumes the accelerator is a single-byte character, so
       a multi-byte (UTF-8) accelerator such as 'Ü' never matches.

  It rejected Ctrl+Alt+S only as a side effect of the length check rather than
  by testing the modifiers, so the intent was not expressed anywhere.

  Scope note: these tests characterise the current behaviour rather than prove
  the fix. Both defects above are latent - no shipped translation overrides
  rsKeyAlt yet, and KeycodeToText only ever yields single-byte ASCII for the
  keycodes a menubar sees - so neither is reachable through HandleKeyPress
  today, and the old code passes these tests too. They exist to pin the
  behaviour so a future regression is caught. Opening a menu needs a realised
  window, so the positive cases assert the item lookup instead of driving
  DoSelect.
}
unit tcmenuaccel;

{$mode objfpc}{$h+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  fpg_base,
  fpg_form,
  fpg_menu,
  fpg_stringutils;

type

  TTestMenuBarAccel = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FForm: TfpgForm;
    FMenuBar: TfpgMenuBar;
    FFileMenu: TfpgPopupMenu;
    FClickCount: integer;
    procedure   ItemClicked(Sender: TObject);
    function    SendKey(const AKey: word; const AShiftState: TShiftState): boolean;
  protected
    procedure   SetUp; virtual;
    procedure   TearDown; virtual;
  public
    procedure TestAltAccelIsRecognised;
    procedure TestAltAccelIsCaseInsensitive;
    procedure TestMultiByteAccelIsRecognised;
    procedure TestCtrlAltDoesNotOpenMenu;
    procedure TestShiftAltDoesNotOpenMenu;
    procedure TestNoModifierDoesNotOpenMenu;
    procedure TestWrongLetterDoesNotOpenMenu;
    procedure TestDisabledItemDoesNotOpenMenu;
  end;


procedure RegistertcmenuaccelTests(ARegistry: TNXTestRegistry);

implementation

uses
  fpg_main,
  fpg_popupwindow;

type
  TfpgMenuBarFriend = class(TfpgMenuBar);


{ TTestMenuBarAccel }

procedure TTestMenuBarAccel.SetUp;
begin
  if not fpgApplication.IsInitialized then
    fpgApplication.Initialize;
  FClickCount := 0;
  FForm := TfpgForm.Create(nil);
  FMenuBar := TfpgMenuBar.Create(FForm);
  FFileMenu := TfpgPopupMenu.Create(FForm);
  FFileMenu.AddMenuItem('&Open', '', @ItemClicked);
  FMenuBar.AddMenuItem('&File', nil).SubMenu := FFileMenu;
  { the menubar only collects its visible items when realised, and these tests
    never show the form, so populate the visible-item list explicitly }
  TfpgMenuBarFriend(FMenuBar).PrepareToShow;
end;

procedure TTestMenuBarAccel.TearDown;
begin
  { A successful accelerator opens the submenu via ShowAt, which registers it
    in the global popup list. Freeing the form without closing it would leave
    a dangling entry there and crash whichever test ran next. }
  ClosePopups;
  FForm.Free;   { owns the menubar and popup }
end;

procedure TTestMenuBarAccel.ItemClicked(Sender: TObject);
begin
  Inc(FClickCount);
end;

function TTestMenuBarAccel.SendKey(const AKey: word; const AShiftState: TShiftState): boolean;
var
  consumed: boolean;
  key: word;
  ss: TShiftState;
begin
  consumed := False;
  key := AKey;
  ss := AShiftState;
  TfpgMenuBarFriend(FMenuBar).HandleKeyPress(key, ss, consumed);
  Result := consumed;
end;

{ Opening a menu needs a realised window (DoSelect touches Parent and shows a
  popup), which a unit test has no display for. So the positive cases assert
  the two things that actually decide whether an accelerator fires: the
  modifier test, and the item lookup. }

procedure TTestMenuBarAccel.TestAltAccelIsRecognised;
begin
  TestContext.AssertTrue(fpgIsAccelShiftState([ssAlt]), 'plain Alt must be accepted');
  TestContext.AssertTrue((0)=(TfpgMenuBarFriend(FMenuBar).SearchItemByAccel('F')), 'Alt+F should resolve to the ''&File'' item at index 0');
end;

procedure TTestMenuBarAccel.TestAltAccelIsCaseInsensitive;
begin
  { the item declares '&File', so a lowercase 'f' must match it too }
  TestContext.AssertTrue((0)=(TfpgMenuBarFriend(FMenuBar).SearchItemByAccel('f')), '');
end;

procedure TTestMenuBarAccel.TestMultiByteAccelIsRecognised;
begin
  { the old 'length(s) = 5' test could never match a multi-byte accelerator }
  FMenuBar.MenuItem(0).Text := '&Über';
  TestContext.AssertTrue((0)=(TfpgMenuBarFriend(FMenuBar).SearchItemByAccel('Ü')), 'a UTF-8 accelerator character must resolve');
end;

procedure TTestMenuBarAccel.TestCtrlAltDoesNotOpenMenu;
begin
  { Ctrl+Alt+F is a distinct combination and must not open the File menu }
  TestContext.AssertTrue(not (SendKey(keyF, [ssCtrl, ssAlt])), 'Ctrl+Alt+F must not be consumed');
end;

procedure TTestMenuBarAccel.TestShiftAltDoesNotOpenMenu;
begin
  TestContext.AssertTrue(not (SendKey(keyF, [ssShift, ssAlt])), 'Shift+Alt+F must not be consumed');
end;

procedure TTestMenuBarAccel.TestNoModifierDoesNotOpenMenu;
begin
  { a bare 'F' keypress must not open the menu }
  TestContext.AssertTrue(not (SendKey(keyF, [])), 'plain F must not be consumed');
end;

procedure TTestMenuBarAccel.TestWrongLetterDoesNotOpenMenu;
begin
  TestContext.AssertTrue(not (SendKey(keyQ, [ssAlt])), 'Alt+Q matches no menu item');
end;

procedure TTestMenuBarAccel.TestDisabledItemDoesNotOpenMenu;
begin
  FMenuBar.MenuItem(0).Enabled := False;
  TestContext.AssertTrue(not (SendKey(keyF, [ssAlt])), 'a disabled menu must not respond');
end;

constructor TTestMenuBarAccel.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestMenuBarAccelTestAltAccelIsRecognised(AContext: TNXTestContext);
var lFixture: TTestMenuBarAccel;
begin
  lFixture:=TTestMenuBarAccel.Create(AContext, 'TestAltAccelIsRecognised');
  try
    lFixture.SetUp;
    try lFixture.TestAltAccelIsRecognised; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMenuBarAccelTestAltAccelIsCaseInsensitive(AContext: TNXTestContext);
var lFixture: TTestMenuBarAccel;
begin
  lFixture:=TTestMenuBarAccel.Create(AContext, 'TestAltAccelIsCaseInsensitive');
  try
    lFixture.SetUp;
    try lFixture.TestAltAccelIsCaseInsensitive; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMenuBarAccelTestMultiByteAccelIsRecognised(AContext: TNXTestContext);
var lFixture: TTestMenuBarAccel;
begin
  lFixture:=TTestMenuBarAccel.Create(AContext, 'TestMultiByteAccelIsRecognised');
  try
    lFixture.SetUp;
    try lFixture.TestMultiByteAccelIsRecognised; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMenuBarAccelTestCtrlAltDoesNotOpenMenu(AContext: TNXTestContext);
var lFixture: TTestMenuBarAccel;
begin
  lFixture:=TTestMenuBarAccel.Create(AContext, 'TestCtrlAltDoesNotOpenMenu');
  try
    lFixture.SetUp;
    try lFixture.TestCtrlAltDoesNotOpenMenu; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMenuBarAccelTestShiftAltDoesNotOpenMenu(AContext: TNXTestContext);
var lFixture: TTestMenuBarAccel;
begin
  lFixture:=TTestMenuBarAccel.Create(AContext, 'TestShiftAltDoesNotOpenMenu');
  try
    lFixture.SetUp;
    try lFixture.TestShiftAltDoesNotOpenMenu; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMenuBarAccelTestNoModifierDoesNotOpenMenu(AContext: TNXTestContext);
var lFixture: TTestMenuBarAccel;
begin
  lFixture:=TTestMenuBarAccel.Create(AContext, 'TestNoModifierDoesNotOpenMenu');
  try
    lFixture.SetUp;
    try lFixture.TestNoModifierDoesNotOpenMenu; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMenuBarAccelTestWrongLetterDoesNotOpenMenu(AContext: TNXTestContext);
var lFixture: TTestMenuBarAccel;
begin
  lFixture:=TTestMenuBarAccel.Create(AContext, 'TestWrongLetterDoesNotOpenMenu');
  try
    lFixture.SetUp;
    try lFixture.TestWrongLetterDoesNotOpenMenu; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMenuBarAccelTestDisabledItemDoesNotOpenMenu(AContext: TNXTestContext);
var lFixture: TTestMenuBarAccel;
begin
  lFixture:=TTestMenuBarAccel.Create(AContext, 'TestDisabledItemDoesNotOpenMenu');
  try
    lFixture.SetUp;
    try lFixture.TestDisabledItemDoesNotOpenMenu; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegistertcmenuaccelTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcmenuaccel.TTestMenuBarAccel');
  lSuite.AddTest('TestAltAccelIsRecognised', @RunTTestMenuBarAccelTestAltAccelIsRecognised);
  lSuite.AddTest('TestAltAccelIsCaseInsensitive', @RunTTestMenuBarAccelTestAltAccelIsCaseInsensitive);
  lSuite.AddTest('TestMultiByteAccelIsRecognised', @RunTTestMenuBarAccelTestMultiByteAccelIsRecognised);
  lSuite.AddTest('TestCtrlAltDoesNotOpenMenu', @RunTTestMenuBarAccelTestCtrlAltDoesNotOpenMenu);
  lSuite.AddTest('TestShiftAltDoesNotOpenMenu', @RunTTestMenuBarAccelTestShiftAltDoesNotOpenMenu);
  lSuite.AddTest('TestNoModifierDoesNotOpenMenu', @RunTTestMenuBarAccelTestNoModifierDoesNotOpenMenu);
  lSuite.AddTest('TestWrongLetterDoesNotOpenMenu', @RunTTestMenuBarAccelTestWrongLetterDoesNotOpenMenu);
  lSuite.AddTest('TestDisabledItemDoesNotOpenMenu', @RunTTestMenuBarAccelTestDisabledItemDoesNotOpenMenu);
end;



end.

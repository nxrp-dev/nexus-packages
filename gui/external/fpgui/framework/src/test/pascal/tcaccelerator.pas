{
  Tests for the &-prefixed accelerator (mnemonic) support.

  Covers the pure parsing helpers in fpg_stringutils, and the Alt-exclusivity
  rule used when dispatching accelerators, so that Ctrl+Alt+S or Shift+Alt+S
  never trigger an Alt+S accelerator.
}
unit tcaccelerator;

{$mode objfpc}{$h+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  fpg_base,
  fpg_widget,
  fpg_form,
  fpg_button,
  fpg_checkbox,
  fpg_label,
  fpg_edit,
  fpg_panel,
  fpg_stringutils;

type

  TTestAccelParsing = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  public
    procedure TestNoAccelReturnsEmpty;
    procedure TestSimpleAccel;
    procedure TestAccelNotFirstChar;
    procedure TestEscapedAmpersandIsNotAnAccel;
    procedure TestEscapedAmpersandFollowedByRealAccel;
    procedure TestTrailingAmpersandIsIgnored;
    procedure TestAccelIsCaseInsensitiveOnMatch;
    procedure TestUTF8Accel;
    procedure TestStripNoAccel;
    procedure TestStripSimpleAccel;
    procedure TestStripEscapedAmpersand;
    procedure TestStripEscapedAndRealAccel;
    procedure TestStripTrailingAmpersand;
    procedure TestStripUTF8;
    procedure TestAccelPosNone;
    procedure TestAccelPosFirst;
    procedure TestAccelPosMidWord;
    procedure TestAccelPosAfterEscapedAmpersand;
    procedure TestAccelPosUTF8;
  end;

  TTestAccelShiftState = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  public
    procedure TestPlainAltMatches;
    procedure TestCtrlAltDoesNotMatch;
    procedure TestShiftAltDoesNotMatch;
    procedure TestCtrlShiftAltDoesNotMatch;
    procedure TestNoModifierDoesNotMatch;
    procedure TestCtrlAloneDoesNotMatch;
    procedure TestAltPlusUnrelatedModifierStillMatches;
  end;

  { End-to-end dispatch through TfpgWidget.DoKeyShortcut }
  TTestAccelDispatch = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FForm: TfpgForm;
    FButton: TfpgButton;
    FClickCount: integer;
    procedure   ButtonClicked(Sender: TObject);
    { drives the same entry point the real key handling uses }
    function    SendKey(const AKey: word; const AShiftState: TShiftState): boolean;
  protected
    procedure   SetUp; virtual;
    procedure   TearDown; virtual;
  public
    procedure TestAltAccelFiresButton;
    procedure TestAltAccelIsCaseInsensitive;
    procedure TestCtrlAltDoesNotFireButton;
    procedure TestShiftAltDoesNotFireButton;
    procedure TestNoModifierDoesNotFireButton;
    procedure TestWrongLetterDoesNotFire;
    procedure TestDisabledButtonDoesNotFire;
    procedure TestButtonWithoutAccelDoesNotFire;
    procedure TestNestedButtonInPanelFires;
    procedure TestCheckBoxAccelToggles;
  end;

  { TfpgLabel.FocusWidget - an accelerator on a label focuses another widget }
  TTestLabelFocusWidget = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FForm: TfpgForm;
    FLabel: TfpgLabel;
    FEdit: TfpgEdit;
    function    SendKey(const AKey: word; const AShiftState: TShiftState): boolean;
  protected
    procedure   SetUp; virtual;
    procedure   TearDown; virtual;
  public
    procedure TestAccelFocusesFocusWidget;
    procedure TestNoFocusWidgetMeansNoAccelerator;
    procedure TestCtrlAltDoesNotFocus;
    procedure TestWrongLetterDoesNotFocus;
    procedure TestDisabledTargetIsNotFocused;
    procedure TestFreeingTargetClearsFocusWidget;
    procedure TestLabelWithoutAmpersandHasNoAccelerator;
  end;


procedure RegisterTests;


procedure RegistertcacceleratorTests(ARegistry: TNXTestRegistry);

implementation

uses
  fpg_main;


procedure RegisterTests;
begin
  
  
  
  
end;

type
  { DoKeyShortcut is protected, so reach it the usual friend-class way }
  TfpgWidgetFriend = class(TfpgWidget);


{ TTestAccelParsing }

procedure TTestAccelParsing.TestNoAccelReturnsEmpty;
begin
  FContext.AssertTrue(('')=(fpgExtractAccelChar('Scan')), '');
end;

procedure TTestAccelParsing.TestSimpleAccel;
begin
  FContext.AssertTrue(('S')=(fpgExtractAccelChar('&Scan')), '');
end;

procedure TTestAccelParsing.TestAccelNotFirstChar;
begin
  { the marked character is returned verbatim, case included }
  FContext.AssertTrue(('c')=(fpgExtractAccelChar('S&can')), '');
end;

procedure TTestAccelParsing.TestEscapedAmpersandIsNotAnAccel;
begin
  { '&&' is a literal ampersand, so there is no accelerator here }
  FContext.AssertTrue(('')=(fpgExtractAccelChar('Black && White')), '');
end;

procedure TTestAccelParsing.TestEscapedAmpersandFollowedByRealAccel;
begin
  FContext.AssertTrue(('W')=(fpgExtractAccelChar('Black && &White')), '');
end;

procedure TTestAccelParsing.TestTrailingAmpersandIsIgnored;
begin
  { a lone trailing '&' has no character after it }
  FContext.AssertTrue(('')=(fpgExtractAccelChar('Scan&')), '');
end;

procedure TTestAccelParsing.TestAccelIsCaseInsensitiveOnMatch;
begin
  { the helper returns the char as-is; matching is done case-insensitively
    by the caller, so a lowercase accel must be preserved verbatim here }
  FContext.AssertTrue(('s')=(fpgExtractAccelChar('&scan')), '');
end;

procedure TTestAccelParsing.TestUTF8Accel;
begin
  { a multi-byte accelerator character must come back whole }
  FContext.AssertTrue(('ü')=(fpgExtractAccelChar('&überprüfen')), '');
end;

procedure TTestAccelParsing.TestStripNoAccel;
begin
  FContext.AssertTrue(('Scan')=(fpgStripAccelChars('Scan')), '');
end;

procedure TTestAccelParsing.TestStripSimpleAccel;
begin
  FContext.AssertTrue(('Scan')=(fpgStripAccelChars('&Scan')), '');
end;

procedure TTestAccelParsing.TestStripEscapedAmpersand;
begin
  FContext.AssertTrue(('Black & White')=(fpgStripAccelChars('Black && White')), '');
end;

procedure TTestAccelParsing.TestStripEscapedAndRealAccel;
begin
  FContext.AssertTrue(('Black & White')=(fpgStripAccelChars('Black && &White')), '');
end;

procedure TTestAccelParsing.TestStripTrailingAmpersand;
begin
  FContext.AssertTrue(('Scan')=(fpgStripAccelChars('Scan&')), '');
end;

procedure TTestAccelParsing.TestStripUTF8;
begin
  FContext.AssertTrue(('überprüfen')=(fpgStripAccelChars('&überprüfen')), '');
end;

procedure TTestAccelParsing.TestAccelPosNone;
begin
  FContext.AssertTrue((0)=(fpgAccelCharPos('Scan')), '');
end;

procedure TTestAccelParsing.TestAccelPosFirst;
begin
  FContext.AssertTrue((1)=(fpgAccelCharPos('&Scan')), '');
end;

procedure TTestAccelParsing.TestAccelPosMidWord;
begin
  { 'S&can' strips to 'Scan', where 'c' is the 2nd character }
  FContext.AssertTrue((2)=(fpgAccelCharPos('S&can')), '');
end;

procedure TTestAccelParsing.TestAccelPosAfterEscapedAmpersand;
begin
  { 'Black && &White' strips to 'Black & White', where 'W' is the 9th char }
  FContext.AssertTrue((9)=(fpgAccelCharPos('Black && &White')), '');
end;

procedure TTestAccelParsing.TestAccelPosUTF8;
begin
  { position is in characters, not bytes - 'S&ürnamè' strips to 'Sürnamè' }
  FContext.AssertTrue((2)=(fpgAccelCharPos('S&ürnamè')), '');
end;


{ TTestAccelShiftState }

procedure TTestAccelShiftState.TestPlainAltMatches;
begin
  FContext.AssertTrue(fpgIsAccelShiftState([ssAlt]), '');
end;

procedure TTestAccelShiftState.TestCtrlAltDoesNotMatch;
begin
  { Ctrl+Alt+S must never fire an Alt+S accelerator }
  FContext.AssertTrue(not (fpgIsAccelShiftState([ssCtrl, ssAlt])), '');
end;

procedure TTestAccelShiftState.TestShiftAltDoesNotMatch;
begin
  FContext.AssertTrue(not (fpgIsAccelShiftState([ssShift, ssAlt])), '');
end;

procedure TTestAccelShiftState.TestCtrlShiftAltDoesNotMatch;
begin
  FContext.AssertTrue(not (fpgIsAccelShiftState([ssCtrl, ssShift, ssAlt])), '');
end;

procedure TTestAccelShiftState.TestNoModifierDoesNotMatch;
begin
  FContext.AssertTrue(not (fpgIsAccelShiftState([])), '');
end;

procedure TTestAccelShiftState.TestCtrlAloneDoesNotMatch;
begin
  FContext.AssertTrue(not (fpgIsAccelShiftState([ssCtrl])), '');
end;

procedure TTestAccelShiftState.TestAltPlusUnrelatedModifierStillMatches;
begin
  { only Shift/Alt/Ctrl take part in the test - a stray mouse-button state
    in the set must not stop a legitimate accelerator from firing }
  FContext.AssertTrue(fpgIsAccelShiftState([ssAlt, ssLeft]), '');
end;


{ TTestAccelDispatch }

procedure TTestAccelDispatch.SetUp;
begin
  if not fpgApplication.IsInitialized then
    fpgApplication.Initialize;
  FClickCount := 0;
  FForm := TfpgForm.Create(nil);
  FButton := TfpgButton.Create(FForm);
  FButton.Text := '&Scan';
  FButton.OnClick := @ButtonClicked;
end;

procedure TTestAccelDispatch.TearDown;
begin
  FForm.Free;   { owns FButton }
end;

procedure TTestAccelDispatch.ButtonClicked(Sender: TObject);
begin
  Inc(FClickCount);
end;

function TTestAccelDispatch.SendKey(const AKey: word; const AShiftState: TShiftState): boolean;
var
  consumed: boolean;
begin
  consumed := False;
  { AOrigin is nil so that no widget is excluded from the walk }
  TfpgWidgetFriend(FForm).DoKeyShortcut(nil, AKey, AShiftState, consumed);
  Result := consumed;
end;

procedure TTestAccelDispatch.TestAltAccelFiresButton;
begin
  FContext.AssertTrue(SendKey(keyS, [ssAlt]), 'Alt+S should be consumed');
  FContext.AssertTrue((1)=(FClickCount), '');
end;

procedure TTestAccelDispatch.TestAltAccelIsCaseInsensitive;
begin
  { '&scan' declares a lowercase accelerator, but Alt+S must still fire it }
  FButton.Text := '&scan';
  FContext.AssertTrue(SendKey(keyS, [ssAlt]), '');
  FContext.AssertTrue((1)=(FClickCount), '');
end;

procedure TTestAccelDispatch.TestCtrlAltDoesNotFireButton;
begin
  { the regression this guards: Ctrl+Alt+S must not trigger Alt+S }
  FContext.AssertTrue(not (SendKey(keyS, [ssCtrl, ssAlt])), 'Ctrl+Alt+S must not be consumed');
  FContext.AssertTrue((0)=(FClickCount), '');
end;

procedure TTestAccelDispatch.TestShiftAltDoesNotFireButton;
begin
  FContext.AssertTrue(not (SendKey(keyS, [ssShift, ssAlt])), '');
  FContext.AssertTrue((0)=(FClickCount), '');
end;

procedure TTestAccelDispatch.TestNoModifierDoesNotFireButton;
begin
  { a bare 'S' keypress must not activate the button }
  FContext.AssertTrue(not (SendKey(keyS, [])), '');
  FContext.AssertTrue((0)=(FClickCount), '');
end;

procedure TTestAccelDispatch.TestWrongLetterDoesNotFire;
begin
  FContext.AssertTrue(not (SendKey(keyQ, [ssAlt])), '');
  FContext.AssertTrue((0)=(FClickCount), '');
end;

procedure TTestAccelDispatch.TestDisabledButtonDoesNotFire;
begin
  FButton.Enabled := False;
  FContext.AssertTrue(not (SendKey(keyS, [ssAlt])), '');
  FContext.AssertTrue((0)=(FClickCount), '');
end;

procedure TTestAccelDispatch.TestButtonWithoutAccelDoesNotFire;
begin
  FButton.Text := 'Scan';
  FContext.AssertTrue(not (SendKey(keyS, [ssAlt])), '');
  FContext.AssertTrue((0)=(FClickCount), '');
end;

procedure TTestAccelDispatch.TestNestedButtonInPanelFires;
var
  pnl: TfpgPanel;
  btn: TfpgButton;
begin
  { a button nested inside a container must still be reachable }
  FButton.Text := 'Plain';
  pnl := TfpgPanel.Create(FForm);
  btn := TfpgButton.Create(pnl);
  btn.Text := '&Deep';
  btn.OnClick := @ButtonClicked;
  FContext.AssertTrue(SendKey(keyD, [ssAlt]), 'nested Alt+D should be consumed');
  FContext.AssertTrue((1)=(FClickCount), '');
end;

procedure TTestAccelDispatch.TestCheckBoxAccelToggles;
var
  cb: TfpgCheckBox;
begin
  FButton.Text := 'Plain';
  cb := TfpgCheckBox.Create(FForm);
  cb.Text := '&Verbose';
  FContext.AssertTrue(not (cb.Checked), 'precondition: unchecked');
  FContext.AssertTrue(SendKey(keyV, [ssAlt]), 'Alt+V should be consumed');
  FContext.AssertTrue(cb.Checked, 'checkbox should have toggled on');
  FContext.AssertTrue(SendKey(keyV, [ssAlt]), '');
  FContext.AssertTrue(not (cb.Checked), 'checkbox should have toggled back off');
end;


{ TTestLabelFocusWidget }

procedure TTestLabelFocusWidget.SetUp;
begin
  if not fpgApplication.IsInitialized then
    fpgApplication.Initialize;
  FForm := TfpgForm.Create(nil);
  FLabel := TfpgLabel.Create(FForm);
  FLabel.Text := '&Name:';
  FEdit := TfpgEdit.Create(FForm);
  FLabel.FocusWidget := FEdit;
end;

procedure TTestLabelFocusWidget.TearDown;
begin
  FForm.Free;   { owns the label and edit }
end;

function TTestLabelFocusWidget.SendKey(const AKey: word; const AShiftState: TShiftState): boolean;
var
  consumed: boolean;
begin
  consumed := False;
  TfpgWidgetFriend(FForm).DoKeyShortcut(nil, AKey, AShiftState, consumed);
  Result := consumed;
end;

procedure TTestLabelFocusWidget.TestAccelFocusesFocusWidget;
begin
  FContext.AssertTrue(not (FEdit.Focused), 'precondition: edit not focused');
  FContext.AssertTrue(SendKey(keyN, [ssAlt]), 'Alt+N should be consumed');
  FContext.AssertTrue(FEdit.Focused, 'the edit should have received focus');
end;

procedure TTestLabelFocusWidget.TestNoFocusWidgetMeansNoAccelerator;
begin
  { a label with no FocusWidget has nothing to activate, so it must not
    swallow the keystroke - something else on the form may want it }
  FLabel.FocusWidget := nil;
  FContext.AssertTrue(not (SendKey(keyN, [ssAlt])), 'Alt+N must not be consumed');
  FContext.AssertTrue(not (FEdit.Focused), '');
end;

procedure TTestLabelFocusWidget.TestCtrlAltDoesNotFocus;
begin
  FContext.AssertTrue(not (SendKey(keyN, [ssCtrl, ssAlt])), 'Ctrl+Alt+N must not be consumed');
  FContext.AssertTrue(not (FEdit.Focused), '');
end;

procedure TTestLabelFocusWidget.TestWrongLetterDoesNotFocus;
begin
  FContext.AssertTrue(not (SendKey(keyQ, [ssAlt])), '');
  FContext.AssertTrue(not (FEdit.Focused), '');
end;

procedure TTestLabelFocusWidget.TestDisabledTargetIsNotFocused;
begin
  { no point focusing a widget the user cannot interact with }
  FEdit.Enabled := False;
  FContext.AssertTrue(not (SendKey(keyN, [ssAlt])), 'Alt+N must not be consumed');
  FContext.AssertTrue(not (FEdit.Focused), '');
end;

procedure TTestLabelFocusWidget.TestFreeingTargetClearsFocusWidget;
var
  otherForm: TfpgForm;
  otherEdit: TfpgEdit;
begin
  { Use a target owned by a DIFFERENT form. Sharing the label's owner would
    notify it anyway through ownership, masking a missing FreeNotification;
    with a separate owner the label is only told if it explicitly asked. }
  { A second form, rather than an unowned widget: freeing an unowned TfpgEdit
    crashes inside fpGUI itself, independently of FocusWidget. A different
    owner is enough - ownership notification only reaches the label's own
    owner, so this still fails without FreeNotification. }
  otherForm := TfpgForm.Create(nil);
  otherEdit := TfpgEdit.Create(otherForm);
  FLabel.FocusWidget := otherEdit;
  FContext.AssertTrue((otherEdit)=(FLabel.FocusWidget), 'precondition: target assigned');

  otherForm.Free;

  FContext.AssertTrue((FLabel.FocusWidget)=nil, 'FocusWidget should have been nilled');
  { and the now-targetless label must not claim the accelerator }
  FContext.AssertTrue(not (SendKey(keyN, [ssAlt])), '');
end;

procedure TTestLabelFocusWidget.TestLabelWithoutAmpersandHasNoAccelerator;
begin
  FLabel.Text := 'Name:';
  FContext.AssertTrue(not (SendKey(keyN, [ssAlt])), '');
  FContext.AssertTrue(not (FEdit.Focused), '');
end;

procedure RunTTestAccelParsingTestNoAccelReturnsEmpty(AContext: TNXTestContext);
var lFixture: TTestAccelParsing;
begin
  lFixture:=TTestAccelParsing.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNoAccelReturnsEmpty';
    lFixture.TestNoAccelReturnsEmpty;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelParsingTestSimpleAccel(AContext: TNXTestContext);
var lFixture: TTestAccelParsing;
begin
  lFixture:=TTestAccelParsing.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSimpleAccel';
    lFixture.TestSimpleAccel;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelParsingTestAccelNotFirstChar(AContext: TNXTestContext);
var lFixture: TTestAccelParsing;
begin
  lFixture:=TTestAccelParsing.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAccelNotFirstChar';
    lFixture.TestAccelNotFirstChar;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelParsingTestEscapedAmpersandIsNotAnAccel(AContext: TNXTestContext);
var lFixture: TTestAccelParsing;
begin
  lFixture:=TTestAccelParsing.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEscapedAmpersandIsNotAnAccel';
    lFixture.TestEscapedAmpersandIsNotAnAccel;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelParsingTestEscapedAmpersandFollowedByRealAccel(AContext: TNXTestContext);
var lFixture: TTestAccelParsing;
begin
  lFixture:=TTestAccelParsing.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEscapedAmpersandFollowedByRealAccel';
    lFixture.TestEscapedAmpersandFollowedByRealAccel;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelParsingTestTrailingAmpersandIsIgnored(AContext: TNXTestContext);
var lFixture: TTestAccelParsing;
begin
  lFixture:=TTestAccelParsing.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestTrailingAmpersandIsIgnored';
    lFixture.TestTrailingAmpersandIsIgnored;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelParsingTestAccelIsCaseInsensitiveOnMatch(AContext: TNXTestContext);
var lFixture: TTestAccelParsing;
begin
  lFixture:=TTestAccelParsing.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAccelIsCaseInsensitiveOnMatch';
    lFixture.TestAccelIsCaseInsensitiveOnMatch;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelParsingTestUTF8Accel(AContext: TNXTestContext);
var lFixture: TTestAccelParsing;
begin
  lFixture:=TTestAccelParsing.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestUTF8Accel';
    lFixture.TestUTF8Accel;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelParsingTestStripNoAccel(AContext: TNXTestContext);
var lFixture: TTestAccelParsing;
begin
  lFixture:=TTestAccelParsing.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestStripNoAccel';
    lFixture.TestStripNoAccel;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelParsingTestStripSimpleAccel(AContext: TNXTestContext);
var lFixture: TTestAccelParsing;
begin
  lFixture:=TTestAccelParsing.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestStripSimpleAccel';
    lFixture.TestStripSimpleAccel;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelParsingTestStripEscapedAmpersand(AContext: TNXTestContext);
var lFixture: TTestAccelParsing;
begin
  lFixture:=TTestAccelParsing.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestStripEscapedAmpersand';
    lFixture.TestStripEscapedAmpersand;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelParsingTestStripEscapedAndRealAccel(AContext: TNXTestContext);
var lFixture: TTestAccelParsing;
begin
  lFixture:=TTestAccelParsing.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestStripEscapedAndRealAccel';
    lFixture.TestStripEscapedAndRealAccel;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelParsingTestStripTrailingAmpersand(AContext: TNXTestContext);
var lFixture: TTestAccelParsing;
begin
  lFixture:=TTestAccelParsing.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestStripTrailingAmpersand';
    lFixture.TestStripTrailingAmpersand;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelParsingTestStripUTF8(AContext: TNXTestContext);
var lFixture: TTestAccelParsing;
begin
  lFixture:=TTestAccelParsing.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestStripUTF8';
    lFixture.TestStripUTF8;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelParsingTestAccelPosNone(AContext: TNXTestContext);
var lFixture: TTestAccelParsing;
begin
  lFixture:=TTestAccelParsing.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAccelPosNone';
    lFixture.TestAccelPosNone;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelParsingTestAccelPosFirst(AContext: TNXTestContext);
var lFixture: TTestAccelParsing;
begin
  lFixture:=TTestAccelParsing.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAccelPosFirst';
    lFixture.TestAccelPosFirst;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelParsingTestAccelPosMidWord(AContext: TNXTestContext);
var lFixture: TTestAccelParsing;
begin
  lFixture:=TTestAccelParsing.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAccelPosMidWord';
    lFixture.TestAccelPosMidWord;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelParsingTestAccelPosAfterEscapedAmpersand(AContext: TNXTestContext);
var lFixture: TTestAccelParsing;
begin
  lFixture:=TTestAccelParsing.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAccelPosAfterEscapedAmpersand';
    lFixture.TestAccelPosAfterEscapedAmpersand;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelParsingTestAccelPosUTF8(AContext: TNXTestContext);
var lFixture: TTestAccelParsing;
begin
  lFixture:=TTestAccelParsing.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAccelPosUTF8';
    lFixture.TestAccelPosUTF8;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelShiftStateTestPlainAltMatches(AContext: TNXTestContext);
var lFixture: TTestAccelShiftState;
begin
  lFixture:=TTestAccelShiftState.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestPlainAltMatches';
    lFixture.TestPlainAltMatches;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelShiftStateTestCtrlAltDoesNotMatch(AContext: TNXTestContext);
var lFixture: TTestAccelShiftState;
begin
  lFixture:=TTestAccelShiftState.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCtrlAltDoesNotMatch';
    lFixture.TestCtrlAltDoesNotMatch;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelShiftStateTestShiftAltDoesNotMatch(AContext: TNXTestContext);
var lFixture: TTestAccelShiftState;
begin
  lFixture:=TTestAccelShiftState.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestShiftAltDoesNotMatch';
    lFixture.TestShiftAltDoesNotMatch;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelShiftStateTestCtrlShiftAltDoesNotMatch(AContext: TNXTestContext);
var lFixture: TTestAccelShiftState;
begin
  lFixture:=TTestAccelShiftState.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCtrlShiftAltDoesNotMatch';
    lFixture.TestCtrlShiftAltDoesNotMatch;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelShiftStateTestNoModifierDoesNotMatch(AContext: TNXTestContext);
var lFixture: TTestAccelShiftState;
begin
  lFixture:=TTestAccelShiftState.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNoModifierDoesNotMatch';
    lFixture.TestNoModifierDoesNotMatch;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelShiftStateTestCtrlAloneDoesNotMatch(AContext: TNXTestContext);
var lFixture: TTestAccelShiftState;
begin
  lFixture:=TTestAccelShiftState.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCtrlAloneDoesNotMatch';
    lFixture.TestCtrlAloneDoesNotMatch;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelShiftStateTestAltPlusUnrelatedModifierStillMatches(AContext: TNXTestContext);
var lFixture: TTestAccelShiftState;
begin
  lFixture:=TTestAccelShiftState.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAltPlusUnrelatedModifierStillMatches';
    lFixture.TestAltPlusUnrelatedModifierStillMatches;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelDispatchTestAltAccelFiresButton(AContext: TNXTestContext);
var lFixture: TTestAccelDispatch;
begin
  lFixture:=TTestAccelDispatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAltAccelFiresButton';
    lFixture.SetUp;
    try lFixture.TestAltAccelFiresButton; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelDispatchTestAltAccelIsCaseInsensitive(AContext: TNXTestContext);
var lFixture: TTestAccelDispatch;
begin
  lFixture:=TTestAccelDispatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAltAccelIsCaseInsensitive';
    lFixture.SetUp;
    try lFixture.TestAltAccelIsCaseInsensitive; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelDispatchTestCtrlAltDoesNotFireButton(AContext: TNXTestContext);
var lFixture: TTestAccelDispatch;
begin
  lFixture:=TTestAccelDispatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCtrlAltDoesNotFireButton';
    lFixture.SetUp;
    try lFixture.TestCtrlAltDoesNotFireButton; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelDispatchTestShiftAltDoesNotFireButton(AContext: TNXTestContext);
var lFixture: TTestAccelDispatch;
begin
  lFixture:=TTestAccelDispatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestShiftAltDoesNotFireButton';
    lFixture.SetUp;
    try lFixture.TestShiftAltDoesNotFireButton; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelDispatchTestNoModifierDoesNotFireButton(AContext: TNXTestContext);
var lFixture: TTestAccelDispatch;
begin
  lFixture:=TTestAccelDispatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNoModifierDoesNotFireButton';
    lFixture.SetUp;
    try lFixture.TestNoModifierDoesNotFireButton; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelDispatchTestWrongLetterDoesNotFire(AContext: TNXTestContext);
var lFixture: TTestAccelDispatch;
begin
  lFixture:=TTestAccelDispatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestWrongLetterDoesNotFire';
    lFixture.SetUp;
    try lFixture.TestWrongLetterDoesNotFire; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelDispatchTestDisabledButtonDoesNotFire(AContext: TNXTestContext);
var lFixture: TTestAccelDispatch;
begin
  lFixture:=TTestAccelDispatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDisabledButtonDoesNotFire';
    lFixture.SetUp;
    try lFixture.TestDisabledButtonDoesNotFire; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelDispatchTestButtonWithoutAccelDoesNotFire(AContext: TNXTestContext);
var lFixture: TTestAccelDispatch;
begin
  lFixture:=TTestAccelDispatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestButtonWithoutAccelDoesNotFire';
    lFixture.SetUp;
    try lFixture.TestButtonWithoutAccelDoesNotFire; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelDispatchTestNestedButtonInPanelFires(AContext: TNXTestContext);
var lFixture: TTestAccelDispatch;
begin
  lFixture:=TTestAccelDispatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNestedButtonInPanelFires';
    lFixture.SetUp;
    try lFixture.TestNestedButtonInPanelFires; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestAccelDispatchTestCheckBoxAccelToggles(AContext: TNXTestContext);
var lFixture: TTestAccelDispatch;
begin
  lFixture:=TTestAccelDispatch.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCheckBoxAccelToggles';
    lFixture.SetUp;
    try lFixture.TestCheckBoxAccelToggles; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestLabelFocusWidgetTestAccelFocusesFocusWidget(AContext: TNXTestContext);
var lFixture: TTestLabelFocusWidget;
begin
  lFixture:=TTestLabelFocusWidget.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAccelFocusesFocusWidget';
    lFixture.SetUp;
    try lFixture.TestAccelFocusesFocusWidget; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestLabelFocusWidgetTestNoFocusWidgetMeansNoAccelerator(AContext: TNXTestContext);
var lFixture: TTestLabelFocusWidget;
begin
  lFixture:=TTestLabelFocusWidget.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNoFocusWidgetMeansNoAccelerator';
    lFixture.SetUp;
    try lFixture.TestNoFocusWidgetMeansNoAccelerator; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestLabelFocusWidgetTestCtrlAltDoesNotFocus(AContext: TNXTestContext);
var lFixture: TTestLabelFocusWidget;
begin
  lFixture:=TTestLabelFocusWidget.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCtrlAltDoesNotFocus';
    lFixture.SetUp;
    try lFixture.TestCtrlAltDoesNotFocus; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestLabelFocusWidgetTestWrongLetterDoesNotFocus(AContext: TNXTestContext);
var lFixture: TTestLabelFocusWidget;
begin
  lFixture:=TTestLabelFocusWidget.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestWrongLetterDoesNotFocus';
    lFixture.SetUp;
    try lFixture.TestWrongLetterDoesNotFocus; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestLabelFocusWidgetTestDisabledTargetIsNotFocused(AContext: TNXTestContext);
var lFixture: TTestLabelFocusWidget;
begin
  lFixture:=TTestLabelFocusWidget.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDisabledTargetIsNotFocused';
    lFixture.SetUp;
    try lFixture.TestDisabledTargetIsNotFocused; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestLabelFocusWidgetTestFreeingTargetClearsFocusWidget(AContext: TNXTestContext);
var lFixture: TTestLabelFocusWidget;
begin
  lFixture:=TTestLabelFocusWidget.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestFreeingTargetClearsFocusWidget';
    lFixture.SetUp;
    try lFixture.TestFreeingTargetClearsFocusWidget; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestLabelFocusWidgetTestLabelWithoutAmpersandHasNoAccelerator(AContext: TNXTestContext);
var lFixture: TTestLabelFocusWidget;
begin
  lFixture:=TTestLabelFocusWidget.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLabelWithoutAmpersandHasNoAccelerator';
    lFixture.SetUp;
    try lFixture.TestLabelWithoutAmpersandHasNoAccelerator; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegistertcacceleratorTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcaccelerator.TTestAccelParsing');
  lSuite.AddTest('TestNoAccelReturnsEmpty', @RunTTestAccelParsingTestNoAccelReturnsEmpty);
  lSuite.AddTest('TestSimpleAccel', @RunTTestAccelParsingTestSimpleAccel);
  lSuite.AddTest('TestAccelNotFirstChar', @RunTTestAccelParsingTestAccelNotFirstChar);
  lSuite.AddTest('TestEscapedAmpersandIsNotAnAccel', @RunTTestAccelParsingTestEscapedAmpersandIsNotAnAccel);
  lSuite.AddTest('TestEscapedAmpersandFollowedByRealAccel', @RunTTestAccelParsingTestEscapedAmpersandFollowedByRealAccel);
  lSuite.AddTest('TestTrailingAmpersandIsIgnored', @RunTTestAccelParsingTestTrailingAmpersandIsIgnored);
  lSuite.AddTest('TestAccelIsCaseInsensitiveOnMatch', @RunTTestAccelParsingTestAccelIsCaseInsensitiveOnMatch);
  lSuite.AddTest('TestUTF8Accel', @RunTTestAccelParsingTestUTF8Accel);
  lSuite.AddTest('TestStripNoAccel', @RunTTestAccelParsingTestStripNoAccel);
  lSuite.AddTest('TestStripSimpleAccel', @RunTTestAccelParsingTestStripSimpleAccel);
  lSuite.AddTest('TestStripEscapedAmpersand', @RunTTestAccelParsingTestStripEscapedAmpersand);
  lSuite.AddTest('TestStripEscapedAndRealAccel', @RunTTestAccelParsingTestStripEscapedAndRealAccel);
  lSuite.AddTest('TestStripTrailingAmpersand', @RunTTestAccelParsingTestStripTrailingAmpersand);
  lSuite.AddTest('TestStripUTF8', @RunTTestAccelParsingTestStripUTF8);
  lSuite.AddTest('TestAccelPosNone', @RunTTestAccelParsingTestAccelPosNone);
  lSuite.AddTest('TestAccelPosFirst', @RunTTestAccelParsingTestAccelPosFirst);
  lSuite.AddTest('TestAccelPosMidWord', @RunTTestAccelParsingTestAccelPosMidWord);
  lSuite.AddTest('TestAccelPosAfterEscapedAmpersand', @RunTTestAccelParsingTestAccelPosAfterEscapedAmpersand);
  lSuite.AddTest('TestAccelPosUTF8', @RunTTestAccelParsingTestAccelPosUTF8);
  lSuite:=ARegistry.AddSuite('tcaccelerator.TTestAccelShiftState');
  lSuite.AddTest('TestPlainAltMatches', @RunTTestAccelShiftStateTestPlainAltMatches);
  lSuite.AddTest('TestCtrlAltDoesNotMatch', @RunTTestAccelShiftStateTestCtrlAltDoesNotMatch);
  lSuite.AddTest('TestShiftAltDoesNotMatch', @RunTTestAccelShiftStateTestShiftAltDoesNotMatch);
  lSuite.AddTest('TestCtrlShiftAltDoesNotMatch', @RunTTestAccelShiftStateTestCtrlShiftAltDoesNotMatch);
  lSuite.AddTest('TestNoModifierDoesNotMatch', @RunTTestAccelShiftStateTestNoModifierDoesNotMatch);
  lSuite.AddTest('TestCtrlAloneDoesNotMatch', @RunTTestAccelShiftStateTestCtrlAloneDoesNotMatch);
  lSuite.AddTest('TestAltPlusUnrelatedModifierStillMatches', @RunTTestAccelShiftStateTestAltPlusUnrelatedModifierStillMatches);
  lSuite:=ARegistry.AddSuite('tcaccelerator.TTestAccelDispatch');
  lSuite.AddTest('TestAltAccelFiresButton', @RunTTestAccelDispatchTestAltAccelFiresButton);
  lSuite.AddTest('TestAltAccelIsCaseInsensitive', @RunTTestAccelDispatchTestAltAccelIsCaseInsensitive);
  lSuite.AddTest('TestCtrlAltDoesNotFireButton', @RunTTestAccelDispatchTestCtrlAltDoesNotFireButton);
  lSuite.AddTest('TestShiftAltDoesNotFireButton', @RunTTestAccelDispatchTestShiftAltDoesNotFireButton);
  lSuite.AddTest('TestNoModifierDoesNotFireButton', @RunTTestAccelDispatchTestNoModifierDoesNotFireButton);
  lSuite.AddTest('TestWrongLetterDoesNotFire', @RunTTestAccelDispatchTestWrongLetterDoesNotFire);
  lSuite.AddTest('TestDisabledButtonDoesNotFire', @RunTTestAccelDispatchTestDisabledButtonDoesNotFire);
  lSuite.AddTest('TestButtonWithoutAccelDoesNotFire', @RunTTestAccelDispatchTestButtonWithoutAccelDoesNotFire);
  lSuite.AddTest('TestNestedButtonInPanelFires', @RunTTestAccelDispatchTestNestedButtonInPanelFires);
  lSuite.AddTest('TestCheckBoxAccelToggles', @RunTTestAccelDispatchTestCheckBoxAccelToggles);
  lSuite:=ARegistry.AddSuite('tcaccelerator.TTestLabelFocusWidget');
  lSuite.AddTest('TestAccelFocusesFocusWidget', @RunTTestLabelFocusWidgetTestAccelFocusesFocusWidget);
  lSuite.AddTest('TestNoFocusWidgetMeansNoAccelerator', @RunTTestLabelFocusWidgetTestNoFocusWidgetMeansNoAccelerator);
  lSuite.AddTest('TestCtrlAltDoesNotFocus', @RunTTestLabelFocusWidgetTestCtrlAltDoesNotFocus);
  lSuite.AddTest('TestWrongLetterDoesNotFocus', @RunTTestLabelFocusWidgetTestWrongLetterDoesNotFocus);
  lSuite.AddTest('TestDisabledTargetIsNotFocused', @RunTTestLabelFocusWidgetTestDisabledTargetIsNotFocused);
  lSuite.AddTest('TestFreeingTargetClearsFocusWidget', @RunTTestLabelFocusWidgetTestFreeingTargetClearsFocusWidget);
  lSuite.AddTest('TestLabelWithoutAmpersandHasNoAccelerator', @RunTTestLabelFocusWidgetTestLabelWithoutAmpersandHasNoAccelerator);
end;



initialization
  RegisterTests;

end.

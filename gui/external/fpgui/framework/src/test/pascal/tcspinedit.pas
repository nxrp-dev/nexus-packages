unit tcspinedit;

{$mode objfpc}{$H+}

{ Regression tests for TfpgSpinEdit / TfpgSpinEditFloat value handling when
  edit focus is lost or Enter is pressed (GitHub issue #149).

  Bugs in the original EditExit behaviour:
  - Empty text set the value to 0 even when 0 was outside MinValue..MaxValue.
  - Out-of-range text silently reverted to the previous value instead of
    clamping to the nearest bound (inconsistent with the Up/Down key
    behaviour, which does clamp).
  - A lone '-' in the edit raised EConvertError via StrToInt.
  - OnChange never fired from EditExit, even when the value changed.
}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, fpg_spinedit, fpg_edit;

type
  TTestSpinEditExit = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FSpin: TfpgSpinEdit;
    FChangeCount: integer;
    procedure ChangeHandler(Sender: TObject);
    function InnerEdit: TfpgEditInteger;
    procedure TypeTextAndExit(const AText: string);
    procedure TypeTextAndPressEnter(const AText: string);
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    { In-range typed text is accepted as the new value. }
    procedure TestInRangeValueAccepted;
    { Empty text must clamp into the range, not blindly become 0. }
    procedure TestEmptyTextClampsIntoRange;
    { Empty text becomes 0 when 0 lies within the range. }
    procedure TestEmptyTextBecomesZeroWhenZeroInRange;
    { Text above MaxValue clamps to MaxValue instead of reverting. }
    procedure TestValueAboveMaxClampsToMax;
    { Text below MinValue clamps to MinValue instead of reverting. }
    procedure TestValueBelowMinClampsToMin;
    { Empty text in a negative-only range clamps to the nearest bound. }
    procedure TestEmptyTextNegativeOnlyRangeClampsToMax;
    { OnChange fires once when the value is clamped to a bound. }
    procedure TestOnChangeFiresWhenValueClamped;
    { OnChange fires when an in-range edit changes the value. }
    procedure TestOnChangeFiresWhenInRangeValueChanges;
    { OnChange must not fire when the value did not change. }
    procedure TestNoOnChangeWhenValueUnchanged;
    { A lone minus sign must not raise EConvertError. }
    procedure TestLoneMinusSignDoesNotRaise;
    { The Enter key path must clamp the same way as focus loss. }
    procedure TestEnterKeyClampsToMax;
  end;

  TTestSpinEditFloatExit = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FSpin: TfpgSpinEditFloat;
    FChangeCount: integer;
    procedure ChangeHandler(Sender: TObject);
    function InnerEdit: TfpgEditFloat;
    procedure TypeTextAndExit(const AText: string);
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    { In-range typed text is accepted as the new value. }
    procedure TestInRangeValueAccepted;
    { Empty text must clamp into the range, not blindly become 0. }
    procedure TestEmptyTextClampsIntoRange;
    { Text above MaxValue clamps to MaxValue instead of reverting. }
    procedure TestValueAboveMaxClampsToMax;
    { Text below MinValue clamps to MinValue instead of reverting. }
    procedure TestValueBelowMinClampsToMin;
    { OnChange fires once when the value is clamped to a bound. }
    procedure TestOnChangeFiresWhenValueClamped;
  end;

procedure RegistertcspineditTests(ARegistry: TNXTestRegistry);

implementation

uses
  Classes, fpg_base, fpg_main;

type
  { grants test access to the protected EditExit/EditKeyPress handlers }
  TSpinEditAccess = class(TfpgSpinEdit);
  TSpinEditFloatAccess = class(TfpgSpinEditFloat);


{ TTestSpinEditExit }

procedure TTestSpinEditExit.SetUp;
begin
  if not fpgApplication.IsInitialized then
    fpgApplication.Initialize;
  FSpin := TfpgSpinEdit.Create(nil);
  FChangeCount := 0;
end;

procedure TTestSpinEditExit.TearDown;
begin
  FSpin.Free;
end;

procedure TTestSpinEditExit.ChangeHandler(Sender: TObject);
begin
  Inc(FChangeCount);
end;

function TTestSpinEditExit.InnerEdit: TfpgEditInteger;
var
  i: integer;
begin
  Result := nil;
  for i := 0 to FSpin.ComponentCount-1 do
    if FSpin.Components[i] is TfpgEditInteger then
    begin
      Result := TfpgEditInteger(FSpin.Components[i]);
      Exit;
    end;
  FContext.Fail('TfpgSpinEdit has no internal TfpgEditInteger');
end;

procedure TTestSpinEditExit.TypeTextAndExit(const AText: string);
begin
  InnerEdit.Text := AText;
  TSpinEditAccess(FSpin).EditExit(nil);
end;

procedure TTestSpinEditExit.TypeTextAndPressEnter(const AText: string);
var
  keycode: word;
  shift: TShiftState;
  consumed: Boolean;
begin
  InnerEdit.Text := AText;
  keycode := keyReturn;
  shift := [];
  consumed := False;
  TSpinEditAccess(FSpin).EditKeyPress(nil, keycode, shift, consumed);
end;

procedure TTestSpinEditExit.TestInRangeValueAccepted;
begin
  TypeTextAndExit('42');
  FContext.AssertTrue((42)=(FSpin.Value), 'value');
end;

procedure TTestSpinEditExit.TestEmptyTextClampsIntoRange;
begin
  FSpin.MinValue := 10;
  TypeTextAndExit('');
  FContext.AssertTrue((10)=(FSpin.Value), 'value');
  FContext.AssertTrue(('10')=(InnerEdit.Text), 'edit text');
end;

procedure TTestSpinEditExit.TestEmptyTextBecomesZeroWhenZeroInRange;
begin
  FSpin.Value := 50;
  TypeTextAndExit('');
  FContext.AssertTrue((0)=(FSpin.Value), 'value');
end;

procedure TTestSpinEditExit.TestValueAboveMaxClampsToMax;
begin
  FSpin.Value := 50;
  TypeTextAndExit('150');
  FContext.AssertTrue((100)=(FSpin.Value), 'value');
  FContext.AssertTrue(('100')=(InnerEdit.Text), 'edit text');
end;

procedure TTestSpinEditExit.TestValueBelowMinClampsToMin;
begin
  FSpin.MinValue := 10;
  FSpin.Value := 50;
  TypeTextAndExit('5');
  FContext.AssertTrue((10)=(FSpin.Value), 'value');
end;

procedure TTestSpinEditExit.TestEmptyTextNegativeOnlyRangeClampsToMax;
begin
  FSpin.MinValue := -20;
  FSpin.MaxValue := -5;
  TypeTextAndExit('');
  FContext.AssertTrue((-5)=(FSpin.Value), 'value');
end;

procedure TTestSpinEditExit.TestOnChangeFiresWhenValueClamped;
begin
  FSpin.Value := 50;
  FSpin.OnChange := @ChangeHandler;
  TypeTextAndExit('150');
  FContext.AssertTrue((1)=(FChangeCount), 'change count');
end;

procedure TTestSpinEditExit.TestOnChangeFiresWhenInRangeValueChanges;
begin
  FSpin.Value := 50;
  FSpin.OnChange := @ChangeHandler;
  TypeTextAndExit('60');
  FContext.AssertTrue((1)=(FChangeCount), 'change count');
end;

procedure TTestSpinEditExit.TestNoOnChangeWhenValueUnchanged;
begin
  FSpin.Value := 42;
  FSpin.OnChange := @ChangeHandler;
  TypeTextAndExit('42');
  FContext.AssertTrue((0)=(FChangeCount), 'change count');
  FContext.AssertTrue((42)=(FSpin.Value), 'value');
end;

procedure TTestSpinEditExit.TestLoneMinusSignDoesNotRaise;
begin
  FSpin.Value := 50;
  TypeTextAndExit('-');
  { a lone '-' parses as 0, which lies inside the default 0..100 range }
  FContext.AssertTrue((0)=(FSpin.Value), 'value');
end;

procedure TTestSpinEditExit.TestEnterKeyClampsToMax;
begin
  FSpin.Value := 50;
  TypeTextAndPressEnter('150');
  FContext.AssertTrue((100)=(FSpin.Value), 'value');
end;


{ TTestSpinEditFloatExit }

procedure TTestSpinEditFloatExit.SetUp;
begin
  if not fpgApplication.IsInitialized then
    fpgApplication.Initialize;
  FSpin := TfpgSpinEditFloat.Create(nil);
  FSpin.MaxValue := 100;
  FChangeCount := 0;
end;

procedure TTestSpinEditFloatExit.TearDown;
begin
  FSpin.Free;
end;

procedure TTestSpinEditFloatExit.ChangeHandler(Sender: TObject);
begin
  Inc(FChangeCount);
end;

function TTestSpinEditFloatExit.InnerEdit: TfpgEditFloat;
var
  i: integer;
begin
  Result := nil;
  for i := 0 to FSpin.ComponentCount-1 do
    if FSpin.Components[i] is TfpgEditFloat then
    begin
      Result := TfpgEditFloat(FSpin.Components[i]);
      Exit;
    end;
  FContext.Fail('TfpgSpinEditFloat has no internal TfpgEditFloat');
end;

procedure TTestSpinEditFloatExit.TypeTextAndExit(const AText: string);
begin
  InnerEdit.Text := AText;
  TSpinEditFloatAccess(FSpin).EditExit(nil);
end;

procedure TTestSpinEditFloatExit.TestInRangeValueAccepted;
begin
  TypeTextAndExit('42');
  FContext.AssertTrue(Abs((42.0)-(FSpin.Value))<=(0.001), 'value');
end;

procedure TTestSpinEditFloatExit.TestEmptyTextClampsIntoRange;
begin
  FSpin.MinValue := 10;
  TypeTextAndExit('');
  FContext.AssertTrue(Abs((10.0)-(FSpin.Value))<=(0.001), 'value');
end;

procedure TTestSpinEditFloatExit.TestValueAboveMaxClampsToMax;
begin
  FSpin.Value := 50;
  TypeTextAndExit('150');
  FContext.AssertTrue(Abs((100.0)-(FSpin.Value))<=(0.001), 'value');
end;

procedure TTestSpinEditFloatExit.TestValueBelowMinClampsToMin;
begin
  FSpin.MinValue := 10;
  FSpin.Value := 50;
  TypeTextAndExit('5');
  FContext.AssertTrue(Abs((10.0)-(FSpin.Value))<=(0.001), 'value');
end;

procedure TTestSpinEditFloatExit.TestOnChangeFiresWhenValueClamped;
begin
  FSpin.Value := 50;
  FSpin.OnChange := @ChangeHandler;
  TypeTextAndExit('150');
  FContext.AssertTrue((1)=(FChangeCount), 'change count');
end;



procedure RunTTestSpinEditExitTestInRangeValueAccepted(AContext: TNXTestContext);
var lFixture: TTestSpinEditExit;
begin
  lFixture:=TTestSpinEditExit.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInRangeValueAccepted';
    lFixture.SetUp;
    try lFixture.TestInRangeValueAccepted; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSpinEditExitTestEmptyTextClampsIntoRange(AContext: TNXTestContext);
var lFixture: TTestSpinEditExit;
begin
  lFixture:=TTestSpinEditExit.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmptyTextClampsIntoRange';
    lFixture.SetUp;
    try lFixture.TestEmptyTextClampsIntoRange; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSpinEditExitTestEmptyTextBecomesZeroWhenZeroInRange(AContext: TNXTestContext);
var lFixture: TTestSpinEditExit;
begin
  lFixture:=TTestSpinEditExit.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmptyTextBecomesZeroWhenZeroInRange';
    lFixture.SetUp;
    try lFixture.TestEmptyTextBecomesZeroWhenZeroInRange; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSpinEditExitTestValueAboveMaxClampsToMax(AContext: TNXTestContext);
var lFixture: TTestSpinEditExit;
begin
  lFixture:=TTestSpinEditExit.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestValueAboveMaxClampsToMax';
    lFixture.SetUp;
    try lFixture.TestValueAboveMaxClampsToMax; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSpinEditExitTestValueBelowMinClampsToMin(AContext: TNXTestContext);
var lFixture: TTestSpinEditExit;
begin
  lFixture:=TTestSpinEditExit.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestValueBelowMinClampsToMin';
    lFixture.SetUp;
    try lFixture.TestValueBelowMinClampsToMin; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSpinEditExitTestEmptyTextNegativeOnlyRangeClampsToMax(AContext: TNXTestContext);
var lFixture: TTestSpinEditExit;
begin
  lFixture:=TTestSpinEditExit.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmptyTextNegativeOnlyRangeClampsToMax';
    lFixture.SetUp;
    try lFixture.TestEmptyTextNegativeOnlyRangeClampsToMax; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSpinEditExitTestOnChangeFiresWhenValueClamped(AContext: TNXTestContext);
var lFixture: TTestSpinEditExit;
begin
  lFixture:=TTestSpinEditExit.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestOnChangeFiresWhenValueClamped';
    lFixture.SetUp;
    try lFixture.TestOnChangeFiresWhenValueClamped; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSpinEditExitTestOnChangeFiresWhenInRangeValueChanges(AContext: TNXTestContext);
var lFixture: TTestSpinEditExit;
begin
  lFixture:=TTestSpinEditExit.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestOnChangeFiresWhenInRangeValueChanges';
    lFixture.SetUp;
    try lFixture.TestOnChangeFiresWhenInRangeValueChanges; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSpinEditExitTestNoOnChangeWhenValueUnchanged(AContext: TNXTestContext);
var lFixture: TTestSpinEditExit;
begin
  lFixture:=TTestSpinEditExit.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNoOnChangeWhenValueUnchanged';
    lFixture.SetUp;
    try lFixture.TestNoOnChangeWhenValueUnchanged; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSpinEditExitTestLoneMinusSignDoesNotRaise(AContext: TNXTestContext);
var lFixture: TTestSpinEditExit;
begin
  lFixture:=TTestSpinEditExit.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLoneMinusSignDoesNotRaise';
    lFixture.SetUp;
    try lFixture.TestLoneMinusSignDoesNotRaise; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSpinEditExitTestEnterKeyClampsToMax(AContext: TNXTestContext);
var lFixture: TTestSpinEditExit;
begin
  lFixture:=TTestSpinEditExit.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEnterKeyClampsToMax';
    lFixture.SetUp;
    try lFixture.TestEnterKeyClampsToMax; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSpinEditFloatExitTestInRangeValueAccepted(AContext: TNXTestContext);
var lFixture: TTestSpinEditFloatExit;
begin
  lFixture:=TTestSpinEditFloatExit.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestInRangeValueAccepted';
    lFixture.SetUp;
    try lFixture.TestInRangeValueAccepted; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSpinEditFloatExitTestEmptyTextClampsIntoRange(AContext: TNXTestContext);
var lFixture: TTestSpinEditFloatExit;
begin
  lFixture:=TTestSpinEditFloatExit.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmptyTextClampsIntoRange';
    lFixture.SetUp;
    try lFixture.TestEmptyTextClampsIntoRange; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSpinEditFloatExitTestValueAboveMaxClampsToMax(AContext: TNXTestContext);
var lFixture: TTestSpinEditFloatExit;
begin
  lFixture:=TTestSpinEditFloatExit.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestValueAboveMaxClampsToMax';
    lFixture.SetUp;
    try lFixture.TestValueAboveMaxClampsToMax; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSpinEditFloatExitTestValueBelowMinClampsToMin(AContext: TNXTestContext);
var lFixture: TTestSpinEditFloatExit;
begin
  lFixture:=TTestSpinEditFloatExit.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestValueBelowMinClampsToMin';
    lFixture.SetUp;
    try lFixture.TestValueBelowMinClampsToMin; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSpinEditFloatExitTestOnChangeFiresWhenValueClamped(AContext: TNXTestContext);
var lFixture: TTestSpinEditFloatExit;
begin
  lFixture:=TTestSpinEditFloatExit.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestOnChangeFiresWhenValueClamped';
    lFixture.SetUp;
    try lFixture.TestOnChangeFiresWhenValueClamped; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegistertcspineditTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcspinedit.TTestSpinEditExit');
  lSuite.AddTest('TestInRangeValueAccepted', @RunTTestSpinEditExitTestInRangeValueAccepted);
  lSuite.AddTest('TestEmptyTextClampsIntoRange', @RunTTestSpinEditExitTestEmptyTextClampsIntoRange);
  lSuite.AddTest('TestEmptyTextBecomesZeroWhenZeroInRange', @RunTTestSpinEditExitTestEmptyTextBecomesZeroWhenZeroInRange);
  lSuite.AddTest('TestValueAboveMaxClampsToMax', @RunTTestSpinEditExitTestValueAboveMaxClampsToMax);
  lSuite.AddTest('TestValueBelowMinClampsToMin', @RunTTestSpinEditExitTestValueBelowMinClampsToMin);
  lSuite.AddTest('TestEmptyTextNegativeOnlyRangeClampsToMax', @RunTTestSpinEditExitTestEmptyTextNegativeOnlyRangeClampsToMax);
  lSuite.AddTest('TestOnChangeFiresWhenValueClamped', @RunTTestSpinEditExitTestOnChangeFiresWhenValueClamped);
  lSuite.AddTest('TestOnChangeFiresWhenInRangeValueChanges', @RunTTestSpinEditExitTestOnChangeFiresWhenInRangeValueChanges);
  lSuite.AddTest('TestNoOnChangeWhenValueUnchanged', @RunTTestSpinEditExitTestNoOnChangeWhenValueUnchanged);
  lSuite.AddTest('TestLoneMinusSignDoesNotRaise', @RunTTestSpinEditExitTestLoneMinusSignDoesNotRaise);
  lSuite.AddTest('TestEnterKeyClampsToMax', @RunTTestSpinEditExitTestEnterKeyClampsToMax);
  lSuite:=ARegistry.AddSuite('tcspinedit.TTestSpinEditFloatExit');
  lSuite.AddTest('TestInRangeValueAccepted', @RunTTestSpinEditFloatExitTestInRangeValueAccepted);
  lSuite.AddTest('TestEmptyTextClampsIntoRange', @RunTTestSpinEditFloatExitTestEmptyTextClampsIntoRange);
  lSuite.AddTest('TestValueAboveMaxClampsToMax', @RunTTestSpinEditFloatExitTestValueAboveMaxClampsToMax);
  lSuite.AddTest('TestValueBelowMinClampsToMin', @RunTTestSpinEditFloatExitTestValueBelowMinClampsToMin);
  lSuite.AddTest('TestOnChangeFiresWhenValueClamped', @RunTTestSpinEditFloatExitTestOnChangeFiresWhenValueClamped);
end;

end.

unit tcmig_platformdefaults;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpg_mig_unitvalue, fpg_mig_boundsize, fpg_mig_platformdefaults;

type
  TTestMigPlatformDefaults = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    procedure TestGetCurrentPlatform;
    procedure TestSetPlatform_Windows;
    procedure TestSetPlatform_MacOSX;
    procedure TestSetPlatform_Gnome;
    procedure TestLogicalPixelBase_Default;
    procedure TestLogicalPixelBase_SetValid;
    procedure TestLogicalPixelBase_SetInvalid;
    procedure TestBaseDPI_Default;
    procedure TestBaseDPI_SetCustom;
    procedure TestScaleFactors_Default;
    procedure TestScaleFactors_SetCustom;
    procedure TestDefaultUnits;
    procedure TestRelatedGaps;
    procedure TestUnrelatedGaps;
    procedure TestGridCellGaps;
    procedure TestButtonWidth;
    procedure TestButtonPadding;
    procedure TestModCount;
  end;

procedure RegistertcmigplatformdefaultsTests(ARegistry: TNXTestRegistry);

implementation

{ TTestMigPlatformDefaults }

procedure TTestMigPlatformDefaults.TestGetCurrentPlatform;
var
  platform: Integer;
begin
  platform := TfpgMigPlatformDefaults.GetCurrentPlatform;

  {$IFDEF MSWINDOWS}
  TestContext.AssertTrue((PLATFORM_WINDOWS)=(platform), 'Platform should be Windows');
  {$ELSE}
    {$IFDEF DARWIN}
    TestContext.AssertTrue((PLATFORM_MAC_OSX)=(platform), 'Platform should be Mac OSX');
    {$ELSE}
    TestContext.AssertTrue((PLATFORM_GNOME)=(platform), 'Platform should be Gnome');
    {$ENDIF}
  {$ENDIF}
end;

procedure TTestMigPlatformDefaults.TestSetPlatform_Windows;
var
  relX, relY: TfpgMigBoundSize;
begin
  TfpgMigPlatformDefaults.SetPlatform(PLATFORM_WINDOWS);

  relX := TfpgMigPlatformDefaults.GetRelatedGapX;
  relY := TfpgMigPlatformDefaults.GetRelatedGapY;

  TestContext.AssertTrue((relX)<>nil, 'Related gap X should be set for Windows');
  TestContext.AssertTrue((relY)<>nil, 'Related gap Y should be set for Windows');
  TestContext.AssertTrue((relX.Min)<>nil, 'Related gap X min should be set');
  TestContext.AssertTrue((relY.Min)<>nil, 'Related gap Y min should be set');

  // Windows uses 7lpx/7lpy for related gaps
  TestContext.AssertTrue(Abs((7.0)-(relX.Min.Value))<=(0.001), 'Related gap X value should be 7');
  TestContext.AssertTrue(Abs((7.0)-(relY.Min.Value))<=(0.001), 'Related gap Y value should be 7');
end;

procedure TTestMigPlatformDefaults.TestSetPlatform_MacOSX;
var
  unrelX, unrelY: TfpgMigBoundSize;
begin
  TfpgMigPlatformDefaults.SetPlatform(PLATFORM_MAC_OSX);

  unrelX := TfpgMigPlatformDefaults.GetUnrelatedGapX;
  unrelY := TfpgMigPlatformDefaults.GetUnrelatedGapY;

  TestContext.AssertTrue((unrelX)<>nil, 'Unrelated gap X should be set for Mac');
  TestContext.AssertTrue((unrelY)<>nil, 'Unrelated gap Y should be set for Mac');

  // Mac uses 12lpx/12lpy for unrelated gaps
  TestContext.AssertTrue(Abs((12.0)-(unrelX.Min.Value))<=(0.001), 'Unrelated gap X value should be 12');
  TestContext.AssertTrue(Abs((12.0)-(unrelY.Min.Value))<=(0.001), 'Unrelated gap Y value should be 12');
end;

procedure TTestMigPlatformDefaults.TestSetPlatform_Gnome;
var
  relX, cellX: TfpgMigBoundSize;
begin
  TfpgMigPlatformDefaults.SetPlatform(PLATFORM_GNOME);

  relX := TfpgMigPlatformDefaults.GetRelatedGapX;
  cellX := TfpgMigPlatformDefaults.GetDefaultHGap;

  TestContext.AssertTrue((relX)<>nil, 'Related gap X should be set for Gnome');
  TestContext.AssertTrue((cellX)<>nil, 'Grid cell gap X should be set for Gnome');

  // Gnome uses 6lpx for related and grid cell gaps
  TestContext.AssertTrue(Abs((6.0)-(relX.Min.Value))<=(0.001), 'Related gap X value should be 6');
  TestContext.AssertTrue(Abs((6.0)-(cellX.Min.Value))<=(0.001), 'Grid cell gap X value should be 6');
end;

procedure TTestMigPlatformDefaults.TestLogicalPixelBase_Default;
var
  base: Integer;
begin
  base := TfpgMigPlatformDefaults.GetLogicalPixelBase;
  TestContext.AssertTrue((BASE_SCALE_FACTOR)=(base), 'Default logical pixel base should be BASE_SCALE_FACTOR');
end;

procedure TTestMigPlatformDefaults.TestLogicalPixelBase_SetValid;
begin
  TfpgMigPlatformDefaults.SetLogicalPixelBase(BASE_FONT_SIZE);
  TestContext.AssertTrue((BASE_FONT_SIZE)=(TfpgMigPlatformDefaults.GetLogicalPixelBase), 'Logical pixel base should be BASE_FONT_SIZE');

  TfpgMigPlatformDefaults.SetLogicalPixelBase(BASE_REAL_PIXEL);
  TestContext.AssertTrue((BASE_REAL_PIXEL)=(TfpgMigPlatformDefaults.GetLogicalPixelBase), 'Logical pixel base should be BASE_REAL_PIXEL');

  // Reset to default
  TfpgMigPlatformDefaults.SetLogicalPixelBase(BASE_SCALE_FACTOR);
end;

procedure TTestMigPlatformDefaults.TestLogicalPixelBase_SetInvalid;
var
  exceptionRaised: Boolean;
begin
  exceptionRaised := False;
  try
    TfpgMigPlatformDefaults.SetLogicalPixelBase(999);
  except
    on E: Exception do
      exceptionRaised := True;
  end;
  TestContext.AssertTrue(exceptionRaised, 'Should raise exception for invalid base');
end;

procedure TTestMigPlatformDefaults.TestBaseDPI_Default;
var
  dpi: Integer;
begin
  dpi := TfpgMigPlatformDefaults.GetBaseDPI;
  TestContext.AssertTrue((96)=(dpi), 'Default DPI should be 96');
end;

procedure TTestMigPlatformDefaults.TestBaseDPI_SetCustom;
begin
  TfpgMigPlatformDefaults.SetBaseDPI(120);
  TestContext.AssertTrue((120)=(TfpgMigPlatformDefaults.GetBaseDPI), 'DPI should be 120');

  // Reset to default
  TfpgMigPlatformDefaults.SetBaseDPI(96);
end;

procedure TTestMigPlatformDefaults.TestScaleFactors_Default;
var
  horScale, verScale: Single;
begin
  horScale := TfpgMigPlatformDefaults.GetHorizontalScaleFactor;
  verScale := TfpgMigPlatformDefaults.GetVerticalScaleFactor;

  TestContext.AssertTrue(Abs((1.0)-(horScale))<=(0.001), 'Default horizontal scale should be 1.0');
  TestContext.AssertTrue(Abs((1.0)-(verScale))<=(0.001), 'Default vertical scale should be 1.0');
end;

procedure TTestMigPlatformDefaults.TestScaleFactors_SetCustom;
begin
  TfpgMigPlatformDefaults.SetHorizontalScaleFactor(1.5);
  TfpgMigPlatformDefaults.SetVerticalScaleFactor(2.0);

  TestContext.AssertTrue(Abs((1.5)-(TfpgMigPlatformDefaults.GetHorizontalScaleFactor))<=(0.001), 'Horizontal scale should be 1.5');
  TestContext.AssertTrue(Abs((2.0)-(TfpgMigPlatformDefaults.GetVerticalScaleFactor))<=(0.001), 'Vertical scale should be 2.0');

  // Reset to default
  TfpgMigPlatformDefaults.SetHorizontalScaleFactor(1.0);
  TfpgMigPlatformDefaults.SetVerticalScaleFactor(1.0);
end;

procedure TTestMigPlatformDefaults.TestDefaultUnits;
var
  horUnit, verUnit: Integer;
begin
  horUnit := TfpgMigPlatformDefaults.GetDefaultHorizontalUnit;
  verUnit := TfpgMigPlatformDefaults.GetDefaultVerticalUnit;

  TestContext.AssertTrue((Ord(utLPX))=(horUnit), 'Default horizontal unit should be LPX');
  TestContext.AssertTrue((Ord(utLPY))=(verUnit), 'Default vertical unit should be LPY');
end;

procedure TTestMigPlatformDefaults.TestRelatedGaps;
var
  uv: TfpgMigUnitValue;
  gapX, gapY: TfpgMigBoundSize;
begin
  uv := TfpgMigUnitValue.Create(5, utPixel, '5px');
  try
    TfpgMigPlatformDefaults.SetRelatedGap(uv, uv);

    gapX := TfpgMigPlatformDefaults.GetRelatedGapX;
    gapY := TfpgMigPlatformDefaults.GetRelatedGapY;

    TestContext.AssertTrue((gapX)<>nil, 'Related gap X should not be nil');
    TestContext.AssertTrue((gapY)<>nil, 'Related gap Y should not be nil');
    TestContext.AssertTrue(gapX.Min.ContentEquals(uv), 'Related gap X min should have same content');
    TestContext.AssertTrue(gapY.Min.ContentEquals(uv), 'Related gap Y min should have same content');
  finally
    uv.Free;
  end;

  // Reset to platform defaults
  TfpgMigPlatformDefaults.SetPlatform(TfpgMigPlatformDefaults.GetCurrentPlatform);
end;

procedure TTestMigPlatformDefaults.TestUnrelatedGaps;
var
  uv: TfpgMigUnitValue;
  gapX, gapY: TfpgMigBoundSize;
begin
  uv := TfpgMigUnitValue.Create(10, utPixel, '10px');
  try
    TfpgMigPlatformDefaults.SetUnrelatedGap(uv, uv);

    gapX := TfpgMigPlatformDefaults.GetUnrelatedGapX;
    gapY := TfpgMigPlatformDefaults.GetUnrelatedGapY;

    TestContext.AssertTrue((gapX)<>nil, 'Unrelated gap X should not be nil');
    TestContext.AssertTrue((gapY)<>nil, 'Unrelated gap Y should not be nil');
    TestContext.AssertTrue(gapX.Min.ContentEquals(uv), 'Unrelated gap X min should have same content');
    TestContext.AssertTrue(gapY.Min.ContentEquals(uv), 'Unrelated gap Y min should have same content');
  finally
    uv.Free;
  end;

  // Reset to platform defaults
  TfpgMigPlatformDefaults.SetPlatform(TfpgMigPlatformDefaults.GetCurrentPlatform);
end;

procedure TTestMigPlatformDefaults.TestGridCellGaps;
var
  uv: TfpgMigUnitValue;
  gapX, gapY: TfpgMigBoundSize;
begin
  uv := TfpgMigUnitValue.Create(8, utPixel, '8px');
  try
    TfpgMigPlatformDefaults.SetGridCellGap(uv, uv);

    gapX := TfpgMigPlatformDefaults.GetDefaultHGap;
    gapY := TfpgMigPlatformDefaults.GetDefaultVGap;

    TestContext.AssertTrue((gapX)<>nil, 'Grid cell gap X should not be nil');
    TestContext.AssertTrue((gapY)<>nil, 'Grid cell gap Y should not be nil');
    TestContext.AssertTrue(gapX.Min.ContentEquals(uv), 'Grid cell gap X min should have same content');
    TestContext.AssertTrue(gapY.Min.ContentEquals(uv), 'Grid cell gap Y min should have same content');
  finally
    uv.Free;
  end;

  // Reset to platform defaults
  TfpgMigPlatformDefaults.SetPlatform(TfpgMigPlatformDefaults.GetCurrentPlatform);
end;

procedure TTestMigPlatformDefaults.TestButtonWidth;
var
  uv: TfpgMigUnitValue;
  width: TfpgMigUnitValue;
begin
  uv := TfpgMigUnitValue.Create(100, utPixel, '100px');
  try
    TfpgMigPlatformDefaults.SetMinimumButtonWidth(uv);

    width := TfpgMigPlatformDefaults.GetMinimumButtonWidth;
    TestContext.AssertTrue(width.ContentEquals(uv), 'Button width should have same content');
  finally
    uv.Free;
  end;

  // Reset to platform defaults
  TfpgMigPlatformDefaults.SetPlatform(TfpgMigPlatformDefaults.GetCurrentPlatform);
end;

procedure TTestMigPlatformDefaults.TestButtonPadding;
var
  uv: TfpgMigUnitValue;
  padding: TfpgMigUnitValue;
begin
  uv := TfpgMigUnitValue.Create(4, utPixel, '4px');
  try
    TfpgMigPlatformDefaults.SetMinimumButtonPadding(uv);

    padding := TfpgMigPlatformDefaults.GetMinimumButtonPadding;
    TestContext.AssertTrue(padding.ContentEquals(uv), 'Button padding should have same content');
  finally
    uv.Free;
  end;

  // Reset to nil (default has no padding)
  TfpgMigPlatformDefaults.SetMinimumButtonPadding(nil);
end;

procedure TTestMigPlatformDefaults.TestModCount;
var
  count1, count2: Integer;
begin
  count1 := TfpgMigPlatformDefaults.GetModCount;

  // Changing a setting should increment mod count
  TfpgMigPlatformDefaults.SetBaseDPI(120);
  count2 := TfpgMigPlatformDefaults.GetModCount;

  TestContext.AssertTrue(count2 > count1, 'ModCount should increment after change');

  // Reset
  TfpgMigPlatformDefaults.SetBaseDPI(96);
end;


constructor TTestMigPlatformDefaults.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestMigPlatformDefaultsTestGetCurrentPlatform(AContext: TNXTestContext);
var lFixture: TTestMigPlatformDefaults;
begin
  lFixture:=TTestMigPlatformDefaults.Create(AContext, 'TestGetCurrentPlatform');
  try
    lFixture.TestGetCurrentPlatform;
  finally lFixture.Free; end;
end;

procedure RunTTestMigPlatformDefaultsTestSetPlatform_Windows(AContext: TNXTestContext);
var lFixture: TTestMigPlatformDefaults;
begin
  lFixture:=TTestMigPlatformDefaults.Create(AContext, 'TestSetPlatform_Windows');
  try
    lFixture.TestSetPlatform_Windows;
  finally lFixture.Free; end;
end;

procedure RunTTestMigPlatformDefaultsTestSetPlatform_MacOSX(AContext: TNXTestContext);
var lFixture: TTestMigPlatformDefaults;
begin
  lFixture:=TTestMigPlatformDefaults.Create(AContext, 'TestSetPlatform_MacOSX');
  try
    lFixture.TestSetPlatform_MacOSX;
  finally lFixture.Free; end;
end;

procedure RunTTestMigPlatformDefaultsTestSetPlatform_Gnome(AContext: TNXTestContext);
var lFixture: TTestMigPlatformDefaults;
begin
  lFixture:=TTestMigPlatformDefaults.Create(AContext, 'TestSetPlatform_Gnome');
  try
    lFixture.TestSetPlatform_Gnome;
  finally lFixture.Free; end;
end;

procedure RunTTestMigPlatformDefaultsTestLogicalPixelBase_Default(AContext: TNXTestContext);
var lFixture: TTestMigPlatformDefaults;
begin
  lFixture:=TTestMigPlatformDefaults.Create(AContext, 'TestLogicalPixelBase_Default');
  try
    lFixture.TestLogicalPixelBase_Default;
  finally lFixture.Free; end;
end;

procedure RunTTestMigPlatformDefaultsTestLogicalPixelBase_SetValid(AContext: TNXTestContext);
var lFixture: TTestMigPlatformDefaults;
begin
  lFixture:=TTestMigPlatformDefaults.Create(AContext, 'TestLogicalPixelBase_SetValid');
  try
    lFixture.TestLogicalPixelBase_SetValid;
  finally lFixture.Free; end;
end;

procedure RunTTestMigPlatformDefaultsTestLogicalPixelBase_SetInvalid(AContext: TNXTestContext);
var lFixture: TTestMigPlatformDefaults;
begin
  lFixture:=TTestMigPlatformDefaults.Create(AContext, 'TestLogicalPixelBase_SetInvalid');
  try
    lFixture.TestLogicalPixelBase_SetInvalid;
  finally lFixture.Free; end;
end;

procedure RunTTestMigPlatformDefaultsTestBaseDPI_Default(AContext: TNXTestContext);
var lFixture: TTestMigPlatformDefaults;
begin
  lFixture:=TTestMigPlatformDefaults.Create(AContext, 'TestBaseDPI_Default');
  try
    lFixture.TestBaseDPI_Default;
  finally lFixture.Free; end;
end;

procedure RunTTestMigPlatformDefaultsTestBaseDPI_SetCustom(AContext: TNXTestContext);
var lFixture: TTestMigPlatformDefaults;
begin
  lFixture:=TTestMigPlatformDefaults.Create(AContext, 'TestBaseDPI_SetCustom');
  try
    lFixture.TestBaseDPI_SetCustom;
  finally lFixture.Free; end;
end;

procedure RunTTestMigPlatformDefaultsTestScaleFactors_Default(AContext: TNXTestContext);
var lFixture: TTestMigPlatformDefaults;
begin
  lFixture:=TTestMigPlatformDefaults.Create(AContext, 'TestScaleFactors_Default');
  try
    lFixture.TestScaleFactors_Default;
  finally lFixture.Free; end;
end;

procedure RunTTestMigPlatformDefaultsTestScaleFactors_SetCustom(AContext: TNXTestContext);
var lFixture: TTestMigPlatformDefaults;
begin
  lFixture:=TTestMigPlatformDefaults.Create(AContext, 'TestScaleFactors_SetCustom');
  try
    lFixture.TestScaleFactors_SetCustom;
  finally lFixture.Free; end;
end;

procedure RunTTestMigPlatformDefaultsTestDefaultUnits(AContext: TNXTestContext);
var lFixture: TTestMigPlatformDefaults;
begin
  lFixture:=TTestMigPlatformDefaults.Create(AContext, 'TestDefaultUnits');
  try
    lFixture.TestDefaultUnits;
  finally lFixture.Free; end;
end;

procedure RunTTestMigPlatformDefaultsTestRelatedGaps(AContext: TNXTestContext);
var lFixture: TTestMigPlatformDefaults;
begin
  lFixture:=TTestMigPlatformDefaults.Create(AContext, 'TestRelatedGaps');
  try
    lFixture.TestRelatedGaps;
  finally lFixture.Free; end;
end;

procedure RunTTestMigPlatformDefaultsTestUnrelatedGaps(AContext: TNXTestContext);
var lFixture: TTestMigPlatformDefaults;
begin
  lFixture:=TTestMigPlatformDefaults.Create(AContext, 'TestUnrelatedGaps');
  try
    lFixture.TestUnrelatedGaps;
  finally lFixture.Free; end;
end;

procedure RunTTestMigPlatformDefaultsTestGridCellGaps(AContext: TNXTestContext);
var lFixture: TTestMigPlatformDefaults;
begin
  lFixture:=TTestMigPlatformDefaults.Create(AContext, 'TestGridCellGaps');
  try
    lFixture.TestGridCellGaps;
  finally lFixture.Free; end;
end;

procedure RunTTestMigPlatformDefaultsTestButtonWidth(AContext: TNXTestContext);
var lFixture: TTestMigPlatformDefaults;
begin
  lFixture:=TTestMigPlatformDefaults.Create(AContext, 'TestButtonWidth');
  try
    lFixture.TestButtonWidth;
  finally lFixture.Free; end;
end;

procedure RunTTestMigPlatformDefaultsTestButtonPadding(AContext: TNXTestContext);
var lFixture: TTestMigPlatformDefaults;
begin
  lFixture:=TTestMigPlatformDefaults.Create(AContext, 'TestButtonPadding');
  try
    lFixture.TestButtonPadding;
  finally lFixture.Free; end;
end;

procedure RunTTestMigPlatformDefaultsTestModCount(AContext: TNXTestContext);
var lFixture: TTestMigPlatformDefaults;
begin
  lFixture:=TTestMigPlatformDefaults.Create(AContext, 'TestModCount');
  try
    lFixture.TestModCount;
  finally lFixture.Free; end;
end;

procedure RegistertcmigplatformdefaultsTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcmig_platformdefaults.TTestMigPlatformDefaults');
  lSuite.AddTest('TestGetCurrentPlatform', @RunTTestMigPlatformDefaultsTestGetCurrentPlatform);
  lSuite.AddTest('TestSetPlatform_Windows', @RunTTestMigPlatformDefaultsTestSetPlatform_Windows);
  lSuite.AddTest('TestSetPlatform_MacOSX', @RunTTestMigPlatformDefaultsTestSetPlatform_MacOSX);
  lSuite.AddTest('TestSetPlatform_Gnome', @RunTTestMigPlatformDefaultsTestSetPlatform_Gnome);
  lSuite.AddTest('TestLogicalPixelBase_Default', @RunTTestMigPlatformDefaultsTestLogicalPixelBase_Default);
  lSuite.AddTest('TestLogicalPixelBase_SetValid', @RunTTestMigPlatformDefaultsTestLogicalPixelBase_SetValid);
  lSuite.AddTest('TestLogicalPixelBase_SetInvalid', @RunTTestMigPlatformDefaultsTestLogicalPixelBase_SetInvalid);
  lSuite.AddTest('TestBaseDPI_Default', @RunTTestMigPlatformDefaultsTestBaseDPI_Default);
  lSuite.AddTest('TestBaseDPI_SetCustom', @RunTTestMigPlatformDefaultsTestBaseDPI_SetCustom);
  lSuite.AddTest('TestScaleFactors_Default', @RunTTestMigPlatformDefaultsTestScaleFactors_Default);
  lSuite.AddTest('TestScaleFactors_SetCustom', @RunTTestMigPlatformDefaultsTestScaleFactors_SetCustom);
  lSuite.AddTest('TestDefaultUnits', @RunTTestMigPlatformDefaultsTestDefaultUnits);
  lSuite.AddTest('TestRelatedGaps', @RunTTestMigPlatformDefaultsTestRelatedGaps);
  lSuite.AddTest('TestUnrelatedGaps', @RunTTestMigPlatformDefaultsTestUnrelatedGaps);
  lSuite.AddTest('TestGridCellGaps', @RunTTestMigPlatformDefaultsTestGridCellGaps);
  lSuite.AddTest('TestButtonWidth', @RunTTestMigPlatformDefaultsTestButtonWidth);
  lSuite.AddTest('TestButtonPadding', @RunTTestMigPlatformDefaultsTestButtonPadding);
  lSuite.AddTest('TestModCount', @RunTTestMigPlatformDefaultsTestModCount);
end;

end.

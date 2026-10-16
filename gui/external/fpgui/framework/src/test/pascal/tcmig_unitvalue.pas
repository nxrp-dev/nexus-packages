unit tcmig_unitvalue;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpg_mig_unitvalue;

type
  TTestMigUnitValue = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  public
    procedure TestCreateSimplePixel;
    procedure TestCreateWithUnit;
    procedure TestParseUnitType_Pixels;
    procedure TestParseUnitType_Millimeters;
    procedure TestParseUnitType_Centimeters;
    procedure TestParseUnitType_Inches;
    procedure TestParseUnitType_Points;
    procedure TestParseUnitType_Percent;
    procedure TestParseUnitType_LogicalPixels;
    procedure TestParseUnitType_ScreenPercent;
    procedure TestParseUnitType_MinMaxPref;
    procedure TestParseUnitType_Button;
    procedure TestParseUnitType_Label;
    procedure TestParseUnitType_Link;
    procedure TestParseUnitType_Invalid;
    procedure TestIsAbsolute_TrueForPixels;
    procedure TestIsAbsolute_TrueForPhysicalUnits;
    procedure TestIsAbsolute_FalseForPercent;
    procedure TestIsAbsolute_FalseForMinMaxPref;
    procedure TestIsLinked_FalseForSimpleUnit;
    procedure TestIsLinked_TrueForLinkUnit;
    procedure TestConstantValues;
    // Operation tests - NEW
    procedure TestOperation_Add;
    procedure TestOperation_Sub;
    procedure TestOperation_Mul;
    procedure TestOperation_Div;
    procedure TestOperation_Min;
    procedure TestOperation_Max;
    procedure TestOperation_Mid;
    procedure TestOperation_MaxPixelAndPercent;
  end;

procedure RegistertcmigunitvalueTests(ARegistry: TNXTestRegistry);

implementation

{ TTestMigUnitValue }

procedure TTestMigUnitValue.TestCreateSimplePixel;
var
  uv: TfpgMigUnitValue;
begin
  uv := TfpgMigUnitValue.Create(10.0);
  try
    FContext.AssertTrue(Abs((10.0)-(uv.Value))<=(0.001), 'Value should be 10');
    FContext.AssertTrue((Ord(utPixel))=(Ord(uv.UnitType)), 'Unit should be pixel');
    FContext.AssertTrue((Ord(opStatic))=(Ord(uv.Operation)), 'Operation should be static');
    FContext.AssertTrue(uv.IsHorizontal, 'Should be horizontal');
  finally
    uv.Free;
  end;
end;

procedure TTestMigUnitValue.TestCreateWithUnit;
var
  uv: TfpgMigUnitValue;
begin
  uv := TfpgMigUnitValue.Create(5.0, utMM, '5mm');
  try
    FContext.AssertTrue(Abs((5.0)-(uv.Value))<=(0.001), 'Value should be 5');
    FContext.AssertTrue((Ord(utMM))=(Ord(uv.UnitType)), 'Unit should be millimeters');
  finally
    uv.Free;
  end;
end;

procedure TTestMigUnitValue.TestParseUnitType_Pixels;
var
  ut: TfpgMigUnitType;
begin
  ut := ParseUnitType('px');
  FContext.AssertTrue((Ord(utPixel))=(Ord(ut)), 'px should parse as pixel');
end;

procedure TTestMigUnitValue.TestParseUnitType_Millimeters;
var
  ut: TfpgMigUnitType;
begin
  ut := ParseUnitType('mm');
  FContext.AssertTrue((Ord(utMM))=(Ord(ut)), 'mm should parse as millimeters');
end;

procedure TTestMigUnitValue.TestParseUnitType_Centimeters;
var
  ut: TfpgMigUnitType;
begin
  ut := ParseUnitType('cm');
  FContext.AssertTrue((Ord(utCM))=(Ord(ut)), 'cm should parse as centimeters');
end;

procedure TTestMigUnitValue.TestParseUnitType_Inches;
var
  ut: TfpgMigUnitType;
begin
  ut := ParseUnitType('in');
  FContext.AssertTrue((Ord(utInch))=(Ord(ut)), 'in should parse as inches');
end;

procedure TTestMigUnitValue.TestParseUnitType_Points;
var
  ut: TfpgMigUnitType;
begin
  ut := ParseUnitType('pt');
  FContext.AssertTrue((Ord(utPT))=(Ord(ut)), 'pt should parse as points');
end;

procedure TTestMigUnitValue.TestParseUnitType_Percent;
var
  ut: TfpgMigUnitType;
begin
  ut := ParseUnitType('%');
  FContext.AssertTrue((Ord(utPercent))=(Ord(ut)), '% should parse as percent');
end;

procedure TTestMigUnitValue.TestParseUnitType_LogicalPixels;
var
  ut: TfpgMigUnitType;
begin
  ut := ParseUnitType('lpx');
  FContext.AssertTrue((Ord(utLPX))=(Ord(ut)), 'lpx should parse as logical horizontal pixels');

  ut := ParseUnitType('lpy');
  FContext.AssertTrue((Ord(utLPY))=(Ord(ut)), 'lpy should parse as logical vertical pixels');
end;

procedure TTestMigUnitValue.TestParseUnitType_ScreenPercent;
var
  ut: TfpgMigUnitType;
begin
  ut := ParseUnitType('spx');
  FContext.AssertTrue((Ord(utSPX))=(Ord(ut)), 'spx should parse as screen percent width');

  ut := ParseUnitType('spy');
  FContext.AssertTrue((Ord(utSPY))=(Ord(ut)), 'spy should parse as screen percent height');
end;

procedure TTestMigUnitValue.TestParseUnitType_MinMaxPref;
var
  ut: TfpgMigUnitType;
begin
  ut := ParseUnitType('min');
  FContext.AssertTrue((Ord(utMinSize))=(Ord(ut)), 'min should parse as minimum');

  ut := ParseUnitType('minimum');
  FContext.AssertTrue((Ord(utMinSize))=(Ord(ut)), 'minimum should parse as minimum');

  ut := ParseUnitType('p');
  FContext.AssertTrue((Ord(utPrefSize))=(Ord(ut)), 'p should parse as preferred');

  ut := ParseUnitType('pref');
  FContext.AssertTrue((Ord(utPrefSize))=(Ord(ut)), 'pref should parse as preferred');

  ut := ParseUnitType('max');
  FContext.AssertTrue((Ord(utMaxSize))=(Ord(ut)), 'max should parse as maximum');

  ut := ParseUnitType('maximum');
  FContext.AssertTrue((Ord(utMaxSize))=(Ord(ut)), 'maximum should parse as maximum');
end;

procedure TTestMigUnitValue.TestParseUnitType_Button;
var
  ut: TfpgMigUnitType;
begin
  ut := ParseUnitType('button');
  FContext.AssertTrue((Ord(utButton))=(Ord(ut)), 'button should parse as button');
end;

procedure TTestMigUnitValue.TestParseUnitType_Label;
var
  ut: TfpgMigUnitType;
begin
  ut := ParseUnitType('label');
  FContext.AssertTrue((Ord(utLabelAlign))=(Ord(ut)), 'label should parse as label align');
end;

procedure TTestMigUnitValue.TestParseUnitType_Link;
var
  uv: TfpgMigUnitValue;
begin
  // Test link syntax: componentId.property
  uv := TfpgMigUnitValue.Create(0, 'btn1.width', True, opStatic, 'btn1.width');
  try
    FContext.AssertTrue((Ord(utLinkW))=(Ord(uv.UnitType)), 'Should parse as link to width');
    FContext.AssertTrue(('btn1')=(uv.LinkTargetId), 'LinkTargetId should be btn1');
  finally
    uv.Free;
  end;

  uv := TfpgMigUnitValue.Create(0, 'panel.height', False, opStatic, 'panel.height');
  try
    FContext.AssertTrue((Ord(utLinkH))=(Ord(uv.UnitType)), 'Should parse as link to height');
    FContext.AssertTrue(('panel')=(uv.LinkTargetId), 'LinkTargetId should be panel');
  finally
    uv.Free;
  end;

  uv := TfpgMigUnitValue.Create(0, 'other.x', True, opStatic, 'other.x');
  try
    FContext.AssertTrue((Ord(utLinkX))=(Ord(uv.UnitType)), 'Should parse as link to x');
  finally
    uv.Free;
  end;

  uv := TfpgMigUnitValue.Create(0, 'other.y', False, opStatic, 'other.y');
  try
    FContext.AssertTrue((Ord(utLinkY))=(Ord(uv.UnitType)), 'Should parse as link to y');
  finally
    uv.Free;
  end;
end;

procedure TTestMigUnitValue.TestParseUnitType_Invalid;
var
  exceptionRaised: Boolean;
begin
  exceptionRaised := False;
  try
    ParseUnitType('invalid');
  except
    on E: Exception do
      exceptionRaised := True;
  end;
  FContext.AssertTrue(exceptionRaised, 'Should raise exception for invalid unit string');
end;

procedure TTestMigUnitValue.TestIsAbsolute_TrueForPixels;
var
  uv: TfpgMigUnitValue;
begin
  uv := TfpgMigUnitValue.Create(10.0);
  try
    FContext.AssertTrue(uv.IsAbsolute, 'Pixels should be absolute');
  finally
    uv.Free;
  end;
end;

procedure TTestMigUnitValue.TestIsAbsolute_TrueForPhysicalUnits;
var
  uv: TfpgMigUnitValue;
begin
  // Test mm
  uv := TfpgMigUnitValue.Create(10.0, utMM, '10mm');
  try
    FContext.AssertTrue(uv.IsAbsolute, 'Millimeters should be absolute');
  finally
    uv.Free;
  end;

  // Test cm
  uv := TfpgMigUnitValue.Create(2.0, utCM, '2cm');
  try
    FContext.AssertTrue(uv.IsAbsolute, 'Centimeters should be absolute');
  finally
    uv.Free;
  end;

  // Test inches
  uv := TfpgMigUnitValue.Create(1.0, utInch, '1in');
  try
    FContext.AssertTrue(uv.IsAbsolute, 'Inches should be absolute');
  finally
    uv.Free;
  end;

  // Test points
  uv := TfpgMigUnitValue.Create(72.0, utPT, '72pt');
  try
    FContext.AssertTrue(uv.IsAbsolute, 'Points should be absolute');
  finally
    uv.Free;
  end;

  // Test logical pixels
  uv := TfpgMigUnitValue.Create(10.0, utLPX, '10lpx');
  try
    FContext.AssertTrue(uv.IsAbsolute, 'Logical pixels should be absolute');
  finally
    uv.Free;
  end;
end;

procedure TTestMigUnitValue.TestIsAbsolute_FalseForPercent;
var
  uv: TfpgMigUnitValue;
begin
  uv := TfpgMigUnitValue.Create(50.0, utPercent, '50%');
  try
    FContext.AssertTrue(not (uv.IsAbsolute), 'Percent should not be absolute');
  finally
    uv.Free;
  end;
end;

procedure TTestMigUnitValue.TestIsAbsolute_FalseForMinMaxPref;
var
  uv: TfpgMigUnitValue;
begin
  uv := TfpgMigUnitValue.Create(0, utMinSize, 'min');
  try
    FContext.AssertTrue(not (uv.IsAbsolute), 'MinSize should not be absolute');
  finally
    uv.Free;
  end;

  uv := TfpgMigUnitValue.Create(0, utPrefSize, 'pref');
  try
    FContext.AssertTrue(not (uv.IsAbsolute), 'PrefSize should not be absolute');
  finally
    uv.Free;
  end;

  uv := TfpgMigUnitValue.Create(0, utMaxSize, 'max');
  try
    FContext.AssertTrue(not (uv.IsAbsolute), 'MaxSize should not be absolute');
  finally
    uv.Free;
  end;
end;

procedure TTestMigUnitValue.TestIsLinked_FalseForSimpleUnit;
var
  uv: TfpgMigUnitValue;
begin
  uv := TfpgMigUnitValue.Create(10.0);
  try
    FContext.AssertTrue(not (uv.IsLinked), 'Simple pixel unit should not be linked');
  finally
    uv.Free;
  end;
end;

procedure TTestMigUnitValue.TestIsLinked_TrueForLinkUnit;
var
  uv: TfpgMigUnitValue;
begin
  uv := TfpgMigUnitValue.Create(0, 'button1.width', True, opStatic, 'button1.width');
  try
    FContext.AssertTrue(uv.IsLinked, 'Link unit should be linked');
    FContext.AssertTrue(('button1')=(uv.LinkTargetId), 'Link target should be button1');
  finally
    uv.Free;
  end;
end;

procedure TTestMigUnitValue.TestConstantValues;
var
  zero, inf: TfpgMigUnitValue;
begin
  zero := UnitValueZero;
  FContext.AssertTrue((zero)<>nil, 'UnitValueZero should not be nil');
  FContext.AssertTrue(Abs((0.0)-(zero.Value))<=(0.001), 'UnitValueZero value should be 0');
  FContext.AssertTrue((Ord(utPixel))=(Ord(zero.UnitType)), 'UnitValueZero unit should be pixel');

  inf := UnitValueInf;
  FContext.AssertTrue((inf)<>nil, 'UnitValueInf should not be nil');
  FContext.AssertTrue(inf.Value > 1000000, 'UnitValueInf value should be large');
  FContext.AssertTrue((Ord(utPixel))=(Ord(inf.UnitType)), 'UnitValueInf unit should be pixel');
end;

procedure TTestMigUnitValue.TestOperation_Add;
var
  uv1, uv2, result: TfpgMigUnitValue;
  pixels: Single;
begin
  // Create 100px + 50px = 150px
  uv1 := TfpgMigUnitValue.Create(100.0);
  uv2 := TfpgMigUnitValue.Create(50.0);
  result := TfpgMigUnitValue.CreateOper(True, opAdd, uv1, uv2, '100px+50px');
  try
    pixels := result.GetPixels(0, nil, nil);
    FContext.AssertTrue(Abs((150.0)-(pixels))<=(0.001), '100px + 50px should equal 150px');
  finally
    result.Free;
  end;
end;

procedure TTestMigUnitValue.TestOperation_Sub;
var
  uv1, uv2, result: TfpgMigUnitValue;
  pixels: Single;
begin
  // Create 100px - 30px = 70px
  uv1 := TfpgMigUnitValue.Create(100.0);
  uv2 := TfpgMigUnitValue.Create(30.0);
  result := TfpgMigUnitValue.CreateOper(True, opSub, uv1, uv2, '100px-30px');
  try
    pixels := result.GetPixels(0, nil, nil);
    FContext.AssertTrue(Abs((70.0)-(pixels))<=(0.001), '100px - 30px should equal 70px');
  finally
    result.Free;
  end;
end;

procedure TTestMigUnitValue.TestOperation_Mul;
var
  uv1, uv2, result: TfpgMigUnitValue;
  pixels: Single;
begin
  // Create 10px * 5 = 50px
  uv1 := TfpgMigUnitValue.Create(10.0);
  uv2 := TfpgMigUnitValue.Create(5.0);
  result := TfpgMigUnitValue.CreateOper(True, opMul, uv1, uv2, '10px*5');
  try
    pixels := result.GetPixels(0, nil, nil);
    FContext.AssertTrue(Abs((50.0)-(pixels))<=(0.001), '10px * 5 should equal 50px');
  finally
    result.Free;
  end;
end;

procedure TTestMigUnitValue.TestOperation_Div;
var
  uv1, uv2, result: TfpgMigUnitValue;
  pixels: Single;
begin
  // Create 100px / 4 = 25px
  uv1 := TfpgMigUnitValue.Create(100.0);
  uv2 := TfpgMigUnitValue.Create(4.0);
  result := TfpgMigUnitValue.CreateOper(True, opDiv, uv1, uv2, '100px/4');
  try
    pixels := result.GetPixels(0, nil, nil);
    FContext.AssertTrue(Abs((25.0)-(pixels))<=(0.001), '100px / 4 should equal 25px');
  finally
    result.Free;
  end;
end;

procedure TTestMigUnitValue.TestOperation_Min;
var
  uv1, uv2, result: TfpgMigUnitValue;
  pixels: Single;
begin
  // Create min(150px, 100px) = 100px
  uv1 := TfpgMigUnitValue.Create(150.0);
  uv2 := TfpgMigUnitValue.Create(100.0);
  result := TfpgMigUnitValue.CreateOper(True, opMin, uv1, uv2, 'min(150px,100px)');
  try
    pixels := result.GetPixels(0, nil, nil);
    FContext.AssertTrue(Abs((100.0)-(pixels))<=(0.001), 'min(150px, 100px) should equal 100px');
  finally
    result.Free;
  end;
end;

procedure TTestMigUnitValue.TestOperation_Max;
var
  uv1, uv2, result: TfpgMigUnitValue;
  pixels: Single;
begin
  // Create max(150px, 100px) = 150px
  uv1 := TfpgMigUnitValue.Create(150.0);
  uv2 := TfpgMigUnitValue.Create(100.0);
  result := TfpgMigUnitValue.CreateOper(True, opMax, uv1, uv2, 'max(150px,100px)');
  try
    pixels := result.GetPixels(0, nil, nil);
    FContext.AssertTrue(Abs((150.0)-(pixels))<=(0.001), 'max(150px, 100px) should equal 150px');
  finally
    result.Free;
  end;
end;

procedure TTestMigUnitValue.TestOperation_Mid;
var
  uv1, uv2, result: TfpgMigUnitValue;
  pixels: Single;
begin
  // Create mid(100px, 200px) = 150px
  uv1 := TfpgMigUnitValue.Create(100.0);
  uv2 := TfpgMigUnitValue.Create(200.0);
  result := TfpgMigUnitValue.CreateOper(True, opMid, uv1, uv2, 'mid(100px,200px)');
  try
    pixels := result.GetPixels(0, nil, nil);
    FContext.AssertTrue(Abs((150.0)-(pixels))<=(0.001), 'mid(100px, 200px) should equal 150px');
  finally
    result.Free;
  end;
end;

procedure TTestMigUnitValue.TestOperation_MaxPixelAndPercent;
var
  uv1, uv2, result: TfpgMigUnitValue;
  pixels: Single;
begin
  // Create max(150px, 30%) with refValue=1000px
  // 30% of 1000 = 300px, so max should be 300px
  uv1 := TfpgMigUnitValue.Create(150.0);
  uv2 := TfpgMigUnitValue.Create(30.0, utPercent, '30%');
  result := TfpgMigUnitValue.CreateOper(True, opMax, uv1, uv2, 'max(150px,30%)');
  try
    pixels := result.GetPixels(1000.0, nil, nil);
    FContext.AssertTrue(Abs((300.0)-(pixels))<=(0.001), 'max(150px, 30%) with ref=1000 should equal 300px');
  finally
    result.Free;
  end;

  // Test with smaller refValue where 150px wins
  // 30% of 400 = 120px, so max should be 150px
  uv1 := TfpgMigUnitValue.Create(150.0);
  uv2 := TfpgMigUnitValue.Create(30.0, utPercent, '30%');
  result := TfpgMigUnitValue.CreateOper(True, opMax, uv1, uv2, 'max(150px,30%)');
  try
    pixels := result.GetPixels(400.0, nil, nil);
    FContext.AssertTrue(Abs((150.0)-(pixels))<=(0.001), 'max(150px, 30%) with ref=400 should equal 150px');
  finally
    result.Free;
  end;
end;


procedure RunTTestMigUnitValueTestCreateSimplePixel(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateSimplePixel';
    lFixture.TestCreateSimplePixel;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestCreateWithUnit(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestCreateWithUnit';
    lFixture.TestCreateWithUnit;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestParseUnitType_Pixels(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitType_Pixels';
    lFixture.TestParseUnitType_Pixels;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestParseUnitType_Millimeters(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitType_Millimeters';
    lFixture.TestParseUnitType_Millimeters;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestParseUnitType_Centimeters(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitType_Centimeters';
    lFixture.TestParseUnitType_Centimeters;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestParseUnitType_Inches(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitType_Inches';
    lFixture.TestParseUnitType_Inches;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestParseUnitType_Points(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitType_Points';
    lFixture.TestParseUnitType_Points;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestParseUnitType_Percent(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitType_Percent';
    lFixture.TestParseUnitType_Percent;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestParseUnitType_LogicalPixels(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitType_LogicalPixels';
    lFixture.TestParseUnitType_LogicalPixels;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestParseUnitType_ScreenPercent(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitType_ScreenPercent';
    lFixture.TestParseUnitType_ScreenPercent;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestParseUnitType_MinMaxPref(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitType_MinMaxPref';
    lFixture.TestParseUnitType_MinMaxPref;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestParseUnitType_Button(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitType_Button';
    lFixture.TestParseUnitType_Button;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestParseUnitType_Label(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitType_Label';
    lFixture.TestParseUnitType_Label;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestParseUnitType_Link(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitType_Link';
    lFixture.TestParseUnitType_Link;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestParseUnitType_Invalid(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitType_Invalid';
    lFixture.TestParseUnitType_Invalid;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestIsAbsolute_TrueForPixels(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIsAbsolute_TrueForPixels';
    lFixture.TestIsAbsolute_TrueForPixels;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestIsAbsolute_TrueForPhysicalUnits(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIsAbsolute_TrueForPhysicalUnits';
    lFixture.TestIsAbsolute_TrueForPhysicalUnits;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestIsAbsolute_FalseForPercent(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIsAbsolute_FalseForPercent';
    lFixture.TestIsAbsolute_FalseForPercent;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestIsAbsolute_FalseForMinMaxPref(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIsAbsolute_FalseForMinMaxPref';
    lFixture.TestIsAbsolute_FalseForMinMaxPref;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestIsLinked_FalseForSimpleUnit(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIsLinked_FalseForSimpleUnit';
    lFixture.TestIsLinked_FalseForSimpleUnit;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestIsLinked_TrueForLinkUnit(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIsLinked_TrueForLinkUnit';
    lFixture.TestIsLinked_TrueForLinkUnit;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestConstantValues(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestConstantValues';
    lFixture.TestConstantValues;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestOperation_Add(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestOperation_Add';
    lFixture.TestOperation_Add;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestOperation_Sub(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestOperation_Sub';
    lFixture.TestOperation_Sub;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestOperation_Mul(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestOperation_Mul';
    lFixture.TestOperation_Mul;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestOperation_Div(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestOperation_Div';
    lFixture.TestOperation_Div;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestOperation_Min(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestOperation_Min';
    lFixture.TestOperation_Min;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestOperation_Max(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestOperation_Max';
    lFixture.TestOperation_Max;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestOperation_Mid(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestOperation_Mid';
    lFixture.TestOperation_Mid;
  finally lFixture.Free; end;
end;

procedure RunTTestMigUnitValueTestOperation_MaxPixelAndPercent(AContext: TNXTestContext);
var lFixture: TTestMigUnitValue;
begin
  lFixture:=TTestMigUnitValue.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestOperation_MaxPixelAndPercent';
    lFixture.TestOperation_MaxPixelAndPercent;
  finally lFixture.Free; end;
end;

procedure RegistertcmigunitvalueTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcmig_unitvalue.TTestMigUnitValue');
  lSuite.AddTest('TestCreateSimplePixel', @RunTTestMigUnitValueTestCreateSimplePixel);
  lSuite.AddTest('TestCreateWithUnit', @RunTTestMigUnitValueTestCreateWithUnit);
  lSuite.AddTest('TestParseUnitType_Pixels', @RunTTestMigUnitValueTestParseUnitType_Pixels);
  lSuite.AddTest('TestParseUnitType_Millimeters', @RunTTestMigUnitValueTestParseUnitType_Millimeters);
  lSuite.AddTest('TestParseUnitType_Centimeters', @RunTTestMigUnitValueTestParseUnitType_Centimeters);
  lSuite.AddTest('TestParseUnitType_Inches', @RunTTestMigUnitValueTestParseUnitType_Inches);
  lSuite.AddTest('TestParseUnitType_Points', @RunTTestMigUnitValueTestParseUnitType_Points);
  lSuite.AddTest('TestParseUnitType_Percent', @RunTTestMigUnitValueTestParseUnitType_Percent);
  lSuite.AddTest('TestParseUnitType_LogicalPixels', @RunTTestMigUnitValueTestParseUnitType_LogicalPixels);
  lSuite.AddTest('TestParseUnitType_ScreenPercent', @RunTTestMigUnitValueTestParseUnitType_ScreenPercent);
  lSuite.AddTest('TestParseUnitType_MinMaxPref', @RunTTestMigUnitValueTestParseUnitType_MinMaxPref);
  lSuite.AddTest('TestParseUnitType_Button', @RunTTestMigUnitValueTestParseUnitType_Button);
  lSuite.AddTest('TestParseUnitType_Label', @RunTTestMigUnitValueTestParseUnitType_Label);
  lSuite.AddTest('TestParseUnitType_Link', @RunTTestMigUnitValueTestParseUnitType_Link);
  lSuite.AddTest('TestParseUnitType_Invalid', @RunTTestMigUnitValueTestParseUnitType_Invalid);
  lSuite.AddTest('TestIsAbsolute_TrueForPixels', @RunTTestMigUnitValueTestIsAbsolute_TrueForPixels);
  lSuite.AddTest('TestIsAbsolute_TrueForPhysicalUnits', @RunTTestMigUnitValueTestIsAbsolute_TrueForPhysicalUnits);
  lSuite.AddTest('TestIsAbsolute_FalseForPercent', @RunTTestMigUnitValueTestIsAbsolute_FalseForPercent);
  lSuite.AddTest('TestIsAbsolute_FalseForMinMaxPref', @RunTTestMigUnitValueTestIsAbsolute_FalseForMinMaxPref);
  lSuite.AddTest('TestIsLinked_FalseForSimpleUnit', @RunTTestMigUnitValueTestIsLinked_FalseForSimpleUnit);
  lSuite.AddTest('TestIsLinked_TrueForLinkUnit', @RunTTestMigUnitValueTestIsLinked_TrueForLinkUnit);
  lSuite.AddTest('TestConstantValues', @RunTTestMigUnitValueTestConstantValues);
  lSuite.AddTest('TestOperation_Add', @RunTTestMigUnitValueTestOperation_Add);
  lSuite.AddTest('TestOperation_Sub', @RunTTestMigUnitValueTestOperation_Sub);
  lSuite.AddTest('TestOperation_Mul', @RunTTestMigUnitValueTestOperation_Mul);
  lSuite.AddTest('TestOperation_Div', @RunTTestMigUnitValueTestOperation_Div);
  lSuite.AddTest('TestOperation_Min', @RunTTestMigUnitValueTestOperation_Min);
  lSuite.AddTest('TestOperation_Max', @RunTTestMigUnitValueTestOperation_Max);
  lSuite.AddTest('TestOperation_Mid', @RunTTestMigUnitValueTestOperation_Mid);
  lSuite.AddTest('TestOperation_MaxPixelAndPercent', @RunTTestMigUnitValueTestOperation_MaxPixelAndPercent);
end;

end.

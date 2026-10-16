unit tcmig_boundsize;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpg_mig_unitvalue, fpg_mig_boundsize;

type
  TTestMigBoundSize = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FUV10px: TfpgMigUnitValue;
    FUV20px: TfpgMigUnitValue;
    FUV30px: TfpgMigUnitValue;
    FUVPercent: TfpgMigUnitValue;
    FUVLink: TfpgMigUnitValue;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestCreateWithSingleValue;
    procedure TestCreateWithThreeValues;
    procedure TestCreateWithGapPush;
    procedure TestIsUnset_TrueWhenAllNil;
    procedure TestIsUnset_FalseWhenMinSet;
    procedure TestIsUnset_FalseWhenPrefSet;
    procedure TestIsUnset_FalseWhenMaxSet;
    procedure TestIsUnset_FalseWhenGapPushSet;
    procedure TestIsUnset_TrueForZeroPixelConstant;
    procedure TestIsLinked_FalseWhenNoLinks;
    procedure TestIsLinked_TrueWhenMinLinked;
    procedure TestIsLinked_TrueWhenPrefLinked;
    procedure TestIsLinked_TrueWhenMaxLinked;
    procedure TestIsAbsolute_TrueWhenAllAbsolute;
    procedure TestIsAbsolute_TrueWhenAllNil;
    procedure TestIsAbsolute_FalseWhenMinRelative;
    procedure TestIsAbsolute_FalseWhenPrefRelative;
    procedure TestIsAbsolute_FalseWhenMaxRelative;
    procedure TestConstantValues;
    procedure TestPropertyAccess;
  end;

procedure RegistertcmigboundsizeTests(ARegistry: TNXTestRegistry);

implementation

{ TTestMigBoundSize }

procedure TTestMigBoundSize.SetUp;
begin
  
  FUV10px := TfpgMigUnitValue.Create(10, utPixel, '10px');
  FUV20px := TfpgMigUnitValue.Create(20, utPixel, '20px');
  FUV30px := TfpgMigUnitValue.Create(30, utPixel, '30px');
  FUVPercent := TfpgMigUnitValue.Create(50, utPercent, '50%');
  FUVLink := TfpgMigUnitValue.Create(0, 'btn1.width', True, opStatic, 'btn1.width');
end;

procedure TTestMigBoundSize.TearDown;
begin
  FUVLink.Free;
  FUVPercent.Free;
  FUV30px.Free;
  FUV20px.Free;
  FUV10px.Free;
  
end;

procedure TTestMigBoundSize.TestCreateWithSingleValue;
var
  bs: TfpgMigBoundSize;
begin
  bs := TfpgMigBoundSize.Create(FUV10px);
  try
    TestContext.AssertTrue(bs.Min.ContentEquals(FUV10px), 'Min should have same content as input');
    TestContext.AssertTrue(bs.Preferred.ContentEquals(FUV10px), 'Pref should have same content as input');
    TestContext.AssertTrue(bs.Max.ContentEquals(FUV10px), 'Max should have same content as input');
    TestContext.AssertTrue(not (bs.GapPush), 'GapPush should be false');
  finally
    bs.Free;
  end;
end;

procedure TTestMigBoundSize.TestCreateWithThreeValues;
var
  bs: TfpgMigBoundSize;
begin
  bs := TfpgMigBoundSize.Create(FUV10px, FUV20px, FUV30px);
  try
    TestContext.AssertTrue(bs.Min.ContentEquals(FUV10px), 'Min should be 10px');
    TestContext.AssertTrue(bs.Preferred.ContentEquals(FUV20px), 'Pref should be 20px');
    TestContext.AssertTrue(bs.Max.ContentEquals(FUV30px), 'Max should be 30px');
    TestContext.AssertTrue(not (bs.GapPush), 'GapPush should be false');
  finally
    bs.Free;
  end;
end;

procedure TTestMigBoundSize.TestCreateWithGapPush;
var
  bs: TfpgMigBoundSize;
begin
  bs := TfpgMigBoundSize.Create(FUV10px, FUV20px, FUV30px, True);
  try
    TestContext.AssertTrue(bs.Min.ContentEquals(FUV10px), 'Min should be 10px');
    TestContext.AssertTrue(bs.Preferred.ContentEquals(FUV20px), 'Pref should be 20px');
    TestContext.AssertTrue(bs.Max.ContentEquals(FUV30px), 'Max should be 30px');
    TestContext.AssertTrue(bs.GapPush, 'GapPush should be true');
  finally
    bs.Free;
  end;
end;

procedure TTestMigBoundSize.TestIsUnset_TrueWhenAllNil;
var
  bs: TfpgMigBoundSize;
begin
  bs := TfpgMigBoundSize.Create(nil, nil, nil);
  try
    TestContext.AssertTrue(bs.IsUnset, 'Should be unset when all values are nil');
  finally
    bs.Free;
  end;
end;

procedure TTestMigBoundSize.TestIsUnset_FalseWhenMinSet;
var
  bs: TfpgMigBoundSize;
begin
  bs := TfpgMigBoundSize.Create(FUV10px, nil, nil);
  try
    TestContext.AssertTrue(not (bs.IsUnset), 'Should not be unset when min is set');
  finally
    bs.Free;
  end;
end;

procedure TTestMigBoundSize.TestIsUnset_FalseWhenPrefSet;
var
  bs: TfpgMigBoundSize;
begin
  bs := TfpgMigBoundSize.Create(nil, FUV20px, nil);
  try
    TestContext.AssertTrue(not (bs.IsUnset), 'Should not be unset when pref is set');
  finally
    bs.Free;
  end;
end;

procedure TTestMigBoundSize.TestIsUnset_FalseWhenMaxSet;
var
  bs: TfpgMigBoundSize;
begin
  bs := TfpgMigBoundSize.Create(nil, nil, FUV30px);
  try
    TestContext.AssertTrue(not (bs.IsUnset), 'Should not be unset when max is set');
  finally
    bs.Free;
  end;
end;

procedure TTestMigBoundSize.TestIsUnset_FalseWhenGapPushSet;
var
  bs: TfpgMigBoundSize;
begin
  bs := TfpgMigBoundSize.Create(nil, nil, nil, True);
  try
    TestContext.AssertTrue(not (bs.IsUnset), 'Should not be unset when gapPush is true');
  finally
    bs.Free;
  end;
end;

procedure TTestMigBoundSize.TestIsUnset_TrueForZeroPixelConstant;
var
  bs: TfpgMigBoundSize;
begin
  bs := BoundSizeZeroPixel;
  TestContext.AssertTrue(bs.IsUnset, 'ZERO_PIXEL constant should report as unset');
end;

procedure TTestMigBoundSize.TestIsLinked_FalseWhenNoLinks;
var
  bs: TfpgMigBoundSize;
begin
  bs := TfpgMigBoundSize.Create(FUV10px, FUV20px, FUV30px);
  try
    TestContext.AssertTrue(not (bs.IsLinked), 'Should not be linked when no links present');
  finally
    bs.Free;
  end;
end;

procedure TTestMigBoundSize.TestIsLinked_TrueWhenMinLinked;
var
  bs: TfpgMigBoundSize;
begin
  bs := TfpgMigBoundSize.Create(FUVLink, FUV20px, FUV30px);
  try
    TestContext.AssertTrue(bs.IsLinked, 'Should be linked when min contains link');
  finally
    bs.Free;
  end;
end;

procedure TTestMigBoundSize.TestIsLinked_TrueWhenPrefLinked;
var
  bs: TfpgMigBoundSize;
begin
  bs := TfpgMigBoundSize.Create(FUV10px, FUVLink, FUV30px);
  try
    TestContext.AssertTrue(bs.IsLinked, 'Should be linked when pref contains link');
  finally
    bs.Free;
  end;
end;

procedure TTestMigBoundSize.TestIsLinked_TrueWhenMaxLinked;
var
  bs: TfpgMigBoundSize;
begin
  bs := TfpgMigBoundSize.Create(FUV10px, FUV20px, FUVLink);
  try
    TestContext.AssertTrue(bs.IsLinked, 'Should be linked when max contains link');
  finally
    bs.Free;
  end;
end;

procedure TTestMigBoundSize.TestIsAbsolute_TrueWhenAllAbsolute;
var
  bs: TfpgMigBoundSize;
begin
  bs := TfpgMigBoundSize.Create(FUV10px, FUV20px, FUV30px);
  try
    TestContext.AssertTrue(bs.IsAbsolute, 'Should be absolute when all values are absolute');
  finally
    bs.Free;
  end;
end;

procedure TTestMigBoundSize.TestIsAbsolute_TrueWhenAllNil;
var
  bs: TfpgMigBoundSize;
begin
  bs := TfpgMigBoundSize.Create(nil, nil, nil);
  try
    TestContext.AssertTrue(bs.IsAbsolute, 'Should be absolute when all values are nil');
  finally
    bs.Free;
  end;
end;

procedure TTestMigBoundSize.TestIsAbsolute_FalseWhenMinRelative;
var
  bs: TfpgMigBoundSize;
begin
  bs := TfpgMigBoundSize.Create(FUVPercent, FUV20px, FUV30px);
  try
    TestContext.AssertTrue(not (bs.IsAbsolute), 'Should not be absolute when min is relative');
  finally
    bs.Free;
  end;
end;

procedure TTestMigBoundSize.TestIsAbsolute_FalseWhenPrefRelative;
var
  bs: TfpgMigBoundSize;
begin
  bs := TfpgMigBoundSize.Create(FUV10px, FUVPercent, FUV30px);
  try
    TestContext.AssertTrue(not (bs.IsAbsolute), 'Should not be absolute when pref is relative');
  finally
    bs.Free;
  end;
end;

procedure TTestMigBoundSize.TestIsAbsolute_FalseWhenMaxRelative;
var
  bs: TfpgMigBoundSize;
begin
  bs := TfpgMigBoundSize.Create(FUV10px, FUV20px, FUVPercent);
  try
    TestContext.AssertTrue(not (bs.IsAbsolute), 'Should not be absolute when max is relative');
  finally
    bs.Free;
  end;
end;

procedure TTestMigBoundSize.TestConstantValues;
var
  nullSize, zeroPixel: TfpgMigBoundSize;
begin
  nullSize := BoundSizeNullSize;
  TestContext.AssertTrue((nullSize)<>nil, 'NULL_SIZE should not be nil');
  TestContext.AssertTrue(nullSize.IsUnset, 'NULL_SIZE should be unset');
  TestContext.AssertTrue((nullSize.Min)=nil, 'NULL_SIZE min should be nil');
  TestContext.AssertTrue((nullSize.Preferred)=nil, 'NULL_SIZE pref should be nil');
  TestContext.AssertTrue((nullSize.Max)=nil, 'NULL_SIZE max should be nil');

  zeroPixel := BoundSizeZeroPixel;
  TestContext.AssertTrue((zeroPixel)<>nil, 'ZERO_PIXEL should not be nil');
  TestContext.AssertTrue((zeroPixel.Min)<>nil, 'ZERO_PIXEL should have min');
  TestContext.AssertTrue((zeroPixel.Preferred)<>nil, 'ZERO_PIXEL should have pref');
  TestContext.AssertTrue((zeroPixel.Max)<>nil, 'ZERO_PIXEL should have max');
  // Check values are equal (all zero pixels), not pointer equality
  TestContext.AssertTrue((0.0)=(zeroPixel.Min.Value), 'ZERO_PIXEL min should be 0');
  TestContext.AssertTrue((0.0)=(zeroPixel.Preferred.Value), 'ZERO_PIXEL pref should be 0');
  TestContext.AssertTrue((0.0)=(zeroPixel.Max.Value), 'ZERO_PIXEL max should be 0');
  TestContext.AssertTrue((Ord(utPixel))=(Ord(zeroPixel.Min.UnitType)), 'ZERO_PIXEL min should be pixel');
  TestContext.AssertTrue((Ord(utPixel))=(Ord(zeroPixel.Preferred.UnitType)), 'ZERO_PIXEL pref should be pixel');
  TestContext.AssertTrue((Ord(utPixel))=(Ord(zeroPixel.Max.UnitType)), 'ZERO_PIXEL max should be pixel');
end;

procedure TTestMigBoundSize.TestPropertyAccess;
var
  bs: TfpgMigBoundSize;
begin
  bs := TfpgMigBoundSize.Create(FUV10px, FUV20px, FUV30px, True);
  try
    TestContext.AssertTrue(bs.Min.ContentEquals(FUV10px), 'Min property should return correct value');
    TestContext.AssertTrue(bs.Preferred.ContentEquals(FUV20px), 'Preferred property should return correct value');
    TestContext.AssertTrue(bs.Max.ContentEquals(FUV30px), 'Max property should return correct value');
    TestContext.AssertTrue(bs.GapPush, 'GapPush property should return true');
  finally
    bs.Free;
  end;
end;


constructor TTestMigBoundSize.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestMigBoundSizeTestCreateWithSingleValue(AContext: TNXTestContext);
var lFixture: TTestMigBoundSize;
begin
  lFixture:=TTestMigBoundSize.Create(AContext, 'TestCreateWithSingleValue');
  try
    lFixture.SetUp;
    try lFixture.TestCreateWithSingleValue; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigBoundSizeTestCreateWithThreeValues(AContext: TNXTestContext);
var lFixture: TTestMigBoundSize;
begin
  lFixture:=TTestMigBoundSize.Create(AContext, 'TestCreateWithThreeValues');
  try
    lFixture.SetUp;
    try lFixture.TestCreateWithThreeValues; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigBoundSizeTestCreateWithGapPush(AContext: TNXTestContext);
var lFixture: TTestMigBoundSize;
begin
  lFixture:=TTestMigBoundSize.Create(AContext, 'TestCreateWithGapPush');
  try
    lFixture.SetUp;
    try lFixture.TestCreateWithGapPush; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigBoundSizeTestIsUnset_TrueWhenAllNil(AContext: TNXTestContext);
var lFixture: TTestMigBoundSize;
begin
  lFixture:=TTestMigBoundSize.Create(AContext, 'TestIsUnset_TrueWhenAllNil');
  try
    lFixture.SetUp;
    try lFixture.TestIsUnset_TrueWhenAllNil; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigBoundSizeTestIsUnset_FalseWhenMinSet(AContext: TNXTestContext);
var lFixture: TTestMigBoundSize;
begin
  lFixture:=TTestMigBoundSize.Create(AContext, 'TestIsUnset_FalseWhenMinSet');
  try
    lFixture.SetUp;
    try lFixture.TestIsUnset_FalseWhenMinSet; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigBoundSizeTestIsUnset_FalseWhenPrefSet(AContext: TNXTestContext);
var lFixture: TTestMigBoundSize;
begin
  lFixture:=TTestMigBoundSize.Create(AContext, 'TestIsUnset_FalseWhenPrefSet');
  try
    lFixture.SetUp;
    try lFixture.TestIsUnset_FalseWhenPrefSet; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigBoundSizeTestIsUnset_FalseWhenMaxSet(AContext: TNXTestContext);
var lFixture: TTestMigBoundSize;
begin
  lFixture:=TTestMigBoundSize.Create(AContext, 'TestIsUnset_FalseWhenMaxSet');
  try
    lFixture.SetUp;
    try lFixture.TestIsUnset_FalseWhenMaxSet; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigBoundSizeTestIsUnset_FalseWhenGapPushSet(AContext: TNXTestContext);
var lFixture: TTestMigBoundSize;
begin
  lFixture:=TTestMigBoundSize.Create(AContext, 'TestIsUnset_FalseWhenGapPushSet');
  try
    lFixture.SetUp;
    try lFixture.TestIsUnset_FalseWhenGapPushSet; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigBoundSizeTestIsUnset_TrueForZeroPixelConstant(AContext: TNXTestContext);
var lFixture: TTestMigBoundSize;
begin
  lFixture:=TTestMigBoundSize.Create(AContext, 'TestIsUnset_TrueForZeroPixelConstant');
  try
    lFixture.SetUp;
    try lFixture.TestIsUnset_TrueForZeroPixelConstant; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigBoundSizeTestIsLinked_FalseWhenNoLinks(AContext: TNXTestContext);
var lFixture: TTestMigBoundSize;
begin
  lFixture:=TTestMigBoundSize.Create(AContext, 'TestIsLinked_FalseWhenNoLinks');
  try
    lFixture.SetUp;
    try lFixture.TestIsLinked_FalseWhenNoLinks; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigBoundSizeTestIsLinked_TrueWhenMinLinked(AContext: TNXTestContext);
var lFixture: TTestMigBoundSize;
begin
  lFixture:=TTestMigBoundSize.Create(AContext, 'TestIsLinked_TrueWhenMinLinked');
  try
    lFixture.SetUp;
    try lFixture.TestIsLinked_TrueWhenMinLinked; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigBoundSizeTestIsLinked_TrueWhenPrefLinked(AContext: TNXTestContext);
var lFixture: TTestMigBoundSize;
begin
  lFixture:=TTestMigBoundSize.Create(AContext, 'TestIsLinked_TrueWhenPrefLinked');
  try
    lFixture.SetUp;
    try lFixture.TestIsLinked_TrueWhenPrefLinked; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigBoundSizeTestIsLinked_TrueWhenMaxLinked(AContext: TNXTestContext);
var lFixture: TTestMigBoundSize;
begin
  lFixture:=TTestMigBoundSize.Create(AContext, 'TestIsLinked_TrueWhenMaxLinked');
  try
    lFixture.SetUp;
    try lFixture.TestIsLinked_TrueWhenMaxLinked; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigBoundSizeTestIsAbsolute_TrueWhenAllAbsolute(AContext: TNXTestContext);
var lFixture: TTestMigBoundSize;
begin
  lFixture:=TTestMigBoundSize.Create(AContext, 'TestIsAbsolute_TrueWhenAllAbsolute');
  try
    lFixture.SetUp;
    try lFixture.TestIsAbsolute_TrueWhenAllAbsolute; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigBoundSizeTestIsAbsolute_TrueWhenAllNil(AContext: TNXTestContext);
var lFixture: TTestMigBoundSize;
begin
  lFixture:=TTestMigBoundSize.Create(AContext, 'TestIsAbsolute_TrueWhenAllNil');
  try
    lFixture.SetUp;
    try lFixture.TestIsAbsolute_TrueWhenAllNil; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigBoundSizeTestIsAbsolute_FalseWhenMinRelative(AContext: TNXTestContext);
var lFixture: TTestMigBoundSize;
begin
  lFixture:=TTestMigBoundSize.Create(AContext, 'TestIsAbsolute_FalseWhenMinRelative');
  try
    lFixture.SetUp;
    try lFixture.TestIsAbsolute_FalseWhenMinRelative; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigBoundSizeTestIsAbsolute_FalseWhenPrefRelative(AContext: TNXTestContext);
var lFixture: TTestMigBoundSize;
begin
  lFixture:=TTestMigBoundSize.Create(AContext, 'TestIsAbsolute_FalseWhenPrefRelative');
  try
    lFixture.SetUp;
    try lFixture.TestIsAbsolute_FalseWhenPrefRelative; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigBoundSizeTestIsAbsolute_FalseWhenMaxRelative(AContext: TNXTestContext);
var lFixture: TTestMigBoundSize;
begin
  lFixture:=TTestMigBoundSize.Create(AContext, 'TestIsAbsolute_FalseWhenMaxRelative');
  try
    lFixture.SetUp;
    try lFixture.TestIsAbsolute_FalseWhenMaxRelative; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigBoundSizeTestConstantValues(AContext: TNXTestContext);
var lFixture: TTestMigBoundSize;
begin
  lFixture:=TTestMigBoundSize.Create(AContext, 'TestConstantValues');
  try
    lFixture.SetUp;
    try lFixture.TestConstantValues; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestMigBoundSizeTestPropertyAccess(AContext: TNXTestContext);
var lFixture: TTestMigBoundSize;
begin
  lFixture:=TTestMigBoundSize.Create(AContext, 'TestPropertyAccess');
  try
    lFixture.SetUp;
    try lFixture.TestPropertyAccess; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegistertcmigboundsizeTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcmig_boundsize.TTestMigBoundSize');
  lSuite.AddTest('TestCreateWithSingleValue', @RunTTestMigBoundSizeTestCreateWithSingleValue);
  lSuite.AddTest('TestCreateWithThreeValues', @RunTTestMigBoundSizeTestCreateWithThreeValues);
  lSuite.AddTest('TestCreateWithGapPush', @RunTTestMigBoundSizeTestCreateWithGapPush);
  lSuite.AddTest('TestIsUnset_TrueWhenAllNil', @RunTTestMigBoundSizeTestIsUnset_TrueWhenAllNil);
  lSuite.AddTest('TestIsUnset_FalseWhenMinSet', @RunTTestMigBoundSizeTestIsUnset_FalseWhenMinSet);
  lSuite.AddTest('TestIsUnset_FalseWhenPrefSet', @RunTTestMigBoundSizeTestIsUnset_FalseWhenPrefSet);
  lSuite.AddTest('TestIsUnset_FalseWhenMaxSet', @RunTTestMigBoundSizeTestIsUnset_FalseWhenMaxSet);
  lSuite.AddTest('TestIsUnset_FalseWhenGapPushSet', @RunTTestMigBoundSizeTestIsUnset_FalseWhenGapPushSet);
  lSuite.AddTest('TestIsUnset_TrueForZeroPixelConstant', @RunTTestMigBoundSizeTestIsUnset_TrueForZeroPixelConstant);
  lSuite.AddTest('TestIsLinked_FalseWhenNoLinks', @RunTTestMigBoundSizeTestIsLinked_FalseWhenNoLinks);
  lSuite.AddTest('TestIsLinked_TrueWhenMinLinked', @RunTTestMigBoundSizeTestIsLinked_TrueWhenMinLinked);
  lSuite.AddTest('TestIsLinked_TrueWhenPrefLinked', @RunTTestMigBoundSizeTestIsLinked_TrueWhenPrefLinked);
  lSuite.AddTest('TestIsLinked_TrueWhenMaxLinked', @RunTTestMigBoundSizeTestIsLinked_TrueWhenMaxLinked);
  lSuite.AddTest('TestIsAbsolute_TrueWhenAllAbsolute', @RunTTestMigBoundSizeTestIsAbsolute_TrueWhenAllAbsolute);
  lSuite.AddTest('TestIsAbsolute_TrueWhenAllNil', @RunTTestMigBoundSizeTestIsAbsolute_TrueWhenAllNil);
  lSuite.AddTest('TestIsAbsolute_FalseWhenMinRelative', @RunTTestMigBoundSizeTestIsAbsolute_FalseWhenMinRelative);
  lSuite.AddTest('TestIsAbsolute_FalseWhenPrefRelative', @RunTTestMigBoundSizeTestIsAbsolute_FalseWhenPrefRelative);
  lSuite.AddTest('TestIsAbsolute_FalseWhenMaxRelative', @RunTTestMigBoundSizeTestIsAbsolute_FalseWhenMaxRelative);
  lSuite.AddTest('TestConstantValues', @RunTTestMigBoundSizeTestConstantValues);
  lSuite.AddTest('TestPropertyAccess', @RunTTestMigBoundSizeTestPropertyAccess);
end;

end.

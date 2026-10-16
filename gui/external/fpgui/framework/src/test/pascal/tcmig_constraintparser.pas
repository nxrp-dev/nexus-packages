unit tcmig_constraintparser;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpg_mig_constraintparser, fpg_mig_unitvalue, fpg_mig_boundsize;

type
  TTestMigConstraintParser = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  public
    // ParseUnitValue tests
    procedure TestParseUnitValue_SimplePixels;
    procedure TestParseUnitValue_Percent;
    procedure TestParseUnitValue_Millimeters;
    procedure TestParseUnitValue_LogicalPixels;
    procedure TestParseUnitValue_MinSize;
    procedure TestParseUnitValue_PrefSize;
    procedure TestParseUnitValue_MaxSize;
    procedure TestParseUnitValue_AlignLeft;
    procedure TestParseUnitValue_AlignCenter;
    procedure TestParseUnitValue_AlignRight;
    procedure TestParseUnitValue_AlignTop;
    procedure TestParseUnitValue_AlignBottom;
    procedure TestParseUnitValue_WithAddition;
    procedure TestParseUnitValue_WithSubtraction;
    procedure TestParseUnitValue_MinOperation;
    procedure TestParseUnitValue_MaxOperation;
    procedure TestParseUnitValue_MidOperation;

    // ParseBoundSize tests
    procedure TestParseBoundSize_SimpleValue;
    procedure TestParseBoundSize_MinPrefMax;
    procedure TestParseBoundSize_PrefOnly;
    procedure TestParseBoundSize_MinPref;
    procedure TestParseBoundSize_PrefMax;
    procedure TestParseBoundSize_Null;
    procedure TestParseBoundSize_Push;

    // ParseInsets tests
    procedure TestParseInsets_SingleValue;
    procedure TestParseInsets_FourValues;
    procedure TestParseInsets_TwoValues;
    procedure TestParseInsets_Null;

    // Note: Helper functions (ToTrimmedTokens, GetNumTextParts, GetOper) are
    // private procedure RegistertcmigconstraintparserTests(ARegistry: TNXTestRegistry);

implementation details and are tested indirectly through the
    // main parsing functions above
  end;

implementation

{ TTestMigConstraintParser }

// ============================================================================
// ParseUnitValue tests
// ============================================================================

procedure TTestMigConstraintParser.TestParseUnitValue_SimplePixels;
var
  uv: TfpgMigUnitValue;
begin
  uv := ParseUnitValue('10px', True);
  try
    FContext.AssertTrue((uv)<>nil, 'Result should not be nil');
    FContext.AssertTrue(Abs((10.0)-(uv.Value))<=(0.001), 'Value should be 10');
    FContext.AssertTrue((Ord(utPixel))=(Ord(uv.UnitType)), 'Unit should be pixel');
  finally
    uv.Free;
  end;
end;

procedure TTestMigConstraintParser.TestParseUnitValue_Percent;
var
  uv: TfpgMigUnitValue;
begin
  uv := ParseUnitValue('50%', True);
  try
    FContext.AssertTrue((uv)<>nil, 'Result should not be nil');
    FContext.AssertTrue(Abs((50.0)-(uv.Value))<=(0.001), 'Value should be 50');
    FContext.AssertTrue((Ord(utPercent))=(Ord(uv.UnitType)), 'Unit should be percent');
  finally
    uv.Free;
  end;
end;

procedure TTestMigConstraintParser.TestParseUnitValue_Millimeters;
var
  uv: TfpgMigUnitValue;
begin
  uv := ParseUnitValue('5mm', True);
  try
    FContext.AssertTrue((uv)<>nil, 'Result should not be nil');
    FContext.AssertTrue(Abs((5.0)-(uv.Value))<=(0.001), 'Value should be 5');
    FContext.AssertTrue((Ord(utMM))=(Ord(uv.UnitType)), 'Unit should be mm');
  finally
    uv.Free;
  end;
end;

procedure TTestMigConstraintParser.TestParseUnitValue_LogicalPixels;
var
  uv: TfpgMigUnitValue;
begin
  uv := ParseUnitValue('12lpx', True);
  try
    FContext.AssertTrue((uv)<>nil, 'Result should not be nil');
    FContext.AssertTrue(Abs((12.0)-(uv.Value))<=(0.001), 'Value should be 12');
    FContext.AssertTrue((Ord(utLPX))=(Ord(uv.UnitType)), 'Unit should be lpx');
  finally
    uv.Free;
  end;
end;

procedure TTestMigConstraintParser.TestParseUnitValue_MinSize;
var
  uv: TfpgMigUnitValue;
begin
  uv := ParseUnitValue('min', True);
  try
    FContext.AssertTrue((uv)<>nil, 'Result should not be nil');
    FContext.AssertTrue((Ord(utMinSize))=(Ord(uv.UnitType)), 'Unit should be minimum');
  finally
    uv.Free;
  end;
end;

procedure TTestMigConstraintParser.TestParseUnitValue_PrefSize;
var
  uv: TfpgMigUnitValue;
begin
  uv := ParseUnitValue('pref', True);
  try
    FContext.AssertTrue((uv)<>nil, 'Result should not be nil');
    FContext.AssertTrue((Ord(utPrefSize))=(Ord(uv.UnitType)), 'Unit should be preferred');
  finally
    uv.Free;
  end;
end;

procedure TTestMigConstraintParser.TestParseUnitValue_MaxSize;
var
  uv: TfpgMigUnitValue;
begin
  uv := ParseUnitValue('max', True);
  try
    FContext.AssertTrue((uv)<>nil, 'Result should not be nil');
    FContext.AssertTrue((Ord(utMaxSize))=(Ord(uv.UnitType)), 'Unit should be maximum');
  finally
    uv.Free;
  end;
end;

procedure TTestMigConstraintParser.TestParseUnitValue_AlignLeft;
var
  uv: TfpgMigUnitValue;
begin
  uv := ParseUnitValueOrAlign('left', True);
  // Do NOT free uv - ParseUnitValueOrAlign returns singleton UnitValue constants
  FContext.AssertTrue((uv)<>nil, 'Result should not be nil');
  FContext.AssertTrue(Abs((0.0)-(uv.Value))<=(0.001), 'Value should be 0');
  FContext.AssertTrue((Ord(utPercent))=(Ord(uv.UnitType)), 'Unit should be percent');
end;

procedure TTestMigConstraintParser.TestParseUnitValue_AlignCenter;
var
  uv: TfpgMigUnitValue;
begin
  uv := ParseUnitValueOrAlign('center', True);
  // Do NOT free uv - ParseUnitValueOrAlign returns singleton UnitValue constants
  FContext.AssertTrue((uv)<>nil, 'Result should not be nil');
  FContext.AssertTrue(Abs((50.0)-(uv.Value))<=(0.001), 'Value should be 50');
  FContext.AssertTrue((Ord(utPercent))=(Ord(uv.UnitType)), 'Unit should be percent');
end;

procedure TTestMigConstraintParser.TestParseUnitValue_AlignRight;
var
  uv: TfpgMigUnitValue;
begin
  uv := ParseUnitValueOrAlign('right', True);
  // Do NOT free uv - ParseUnitValueOrAlign returns singleton UnitValue constants
  FContext.AssertTrue((uv)<>nil, 'Result should not be nil');
  FContext.AssertTrue(Abs((100.0)-(uv.Value))<=(0.001), 'Value should be 100');
  FContext.AssertTrue((Ord(utPercent))=(Ord(uv.UnitType)), 'Unit should be percent');
end;

procedure TTestMigConstraintParser.TestParseUnitValue_AlignTop;
var
  uv: TfpgMigUnitValue;
begin
  uv := ParseUnitValueOrAlign('top', False);
  // Do NOT free uv - ParseUnitValueOrAlign returns singleton UnitValue constants
  FContext.AssertTrue((uv)<>nil, 'Result should not be nil');
  FContext.AssertTrue(Abs((0.0)-(uv.Value))<=(0.001), 'Value should be 0');
  FContext.AssertTrue((Ord(utPercent))=(Ord(uv.UnitType)), 'Unit should be percent');
end;

procedure TTestMigConstraintParser.TestParseUnitValue_AlignBottom;
var
  uv: TfpgMigUnitValue;
begin
  uv := ParseUnitValueOrAlign('bottom', False);
  // Do NOT free uv - ParseUnitValueOrAlign returns singleton UnitValue constants
  FContext.AssertTrue((uv)<>nil, 'Result should not be nil');
  FContext.AssertTrue(Abs((100.0)-(uv.Value))<=(0.001), 'Value should be 100');
  FContext.AssertTrue((Ord(utPercent))=(Ord(uv.UnitType)), 'Unit should be percent');
end;

procedure TTestMigConstraintParser.TestParseUnitValue_WithAddition;
var
  uv: TfpgMigUnitValue;
begin
  uv := ParseUnitValue('10px+5px', True);
  try
    FContext.AssertTrue((uv)<>nil, 'Result should not be nil');
    FContext.AssertTrue((Ord(opAdd))=(Ord(uv.Operation)), 'Operation should be add');
  finally
    uv.Free;
  end;
end;

procedure TTestMigConstraintParser.TestParseUnitValue_WithSubtraction;
var
  uv: TfpgMigUnitValue;
begin
  uv := ParseUnitValue('100%-10px', True);
  try
    FContext.AssertTrue((uv)<>nil, 'Result should not be nil');
    FContext.AssertTrue((Ord(opSub))=(Ord(uv.Operation)), 'Operation should be subtract');
  finally
    uv.Free;
  end;
end;

procedure TTestMigConstraintParser.TestParseUnitValue_MinOperation;
var
  uv: TfpgMigUnitValue;
begin
  uv := ParseUnitValue('min(10px,20px)', True);
  try
    FContext.AssertTrue((uv)<>nil, 'Result should not be nil');
    FContext.AssertTrue((Ord(opMin))=(Ord(uv.Operation)), 'Operation should be min');
  finally
    uv.Free;
  end;
end;

procedure TTestMigConstraintParser.TestParseUnitValue_MaxOperation;
var
  uv: TfpgMigUnitValue;
begin
  uv := ParseUnitValue('max(10px,20px)', True);
  try
    FContext.AssertTrue((uv)<>nil, 'Result should not be nil');
    FContext.AssertTrue((Ord(opMax))=(Ord(uv.Operation)), 'Operation should be max');
  finally
    uv.Free;
  end;
end;

procedure TTestMigConstraintParser.TestParseUnitValue_MidOperation;
var
  uv: TfpgMigUnitValue;
begin
  uv := ParseUnitValue('mid(10px,20px)', True);
  try
    FContext.AssertTrue((uv)<>nil, 'Result should not be nil');
    FContext.AssertTrue((Ord(opMid))=(Ord(uv.Operation)), 'Operation should be mid');
  finally
    uv.Free;
  end;
end;

// ============================================================================
// ParseBoundSize tests
// ============================================================================

procedure TTestMigConstraintParser.TestParseBoundSize_SimpleValue;
var
  bs: TfpgMigBoundSize;
begin
  bs := ParseBoundSize('100px', False, True);
  try
    FContext.AssertTrue((bs)<>nil, 'Result should not be nil');
    // For non-gap single value: only preferred is set (Java v11 behavior)
    FContext.AssertTrue((bs.Min)=nil, 'Min should be nil for non-gap');
    FContext.AssertTrue((bs.Preferred)<>nil, 'Preferred should not be nil');
    FContext.AssertTrue((bs.Max)=nil, 'Max should be nil for non-gap');
    FContext.AssertTrue(Abs((100.0)-(bs.Preferred.Value))<=(0.001), 'Preferred value should be 100');
  finally
    bs.Free;
  end;
end;

procedure TTestMigConstraintParser.TestParseBoundSize_MinPrefMax;
var
  bs: TfpgMigBoundSize;
begin
  bs := ParseBoundSize('10px:100px:200px', False, True);
  try
    FContext.AssertTrue((bs)<>nil, 'Result should not be nil');
    FContext.AssertTrue((bs.Min)<>nil, 'Min should not be nil');
    FContext.AssertTrue((bs.Preferred)<>nil, 'Preferred should not be nil');
    FContext.AssertTrue((bs.Max)<>nil, 'Max should not be nil');
    FContext.AssertTrue(Abs((10.0)-(bs.Min.Value))<=(0.001), 'Min value should be 10');
    FContext.AssertTrue(Abs((100.0)-(bs.Preferred.Value))<=(0.001), 'Preferred value should be 100');
    FContext.AssertTrue(Abs((200.0)-(bs.Max.Value))<=(0.001), 'Max value should be 200');
  finally
    bs.Free;
  end;
end;

procedure TTestMigConstraintParser.TestParseBoundSize_PrefOnly;
var
  bs: TfpgMigBoundSize;
begin
  // "::100px" means min=empty, pref=empty, max=100px (max-only constraint)
  bs := ParseBoundSize('::100px', False, True);
  try
    FContext.AssertTrue((bs)<>nil, 'Result should not be nil');
    FContext.AssertTrue((bs.Min)=nil, 'Min should be nil');
    FContext.AssertTrue((bs.Preferred)=nil, 'Preferred should be nil');
    FContext.AssertTrue((bs.Max)<>nil, 'Max should not be nil');
    FContext.AssertTrue(Abs((100.0)-(bs.Max.Value))<=(0.001), 'Max value should be 100');
  finally
    bs.Free;
  end;
end;

procedure TTestMigConstraintParser.TestParseBoundSize_MinPref;
var
  bs: TfpgMigBoundSize;
begin
  bs := ParseBoundSize('10px:100px:', False, True);
  try
    FContext.AssertTrue((bs)<>nil, 'Result should not be nil');
    FContext.AssertTrue((bs.Min)<>nil, 'Min should not be nil');
    FContext.AssertTrue((bs.Preferred)<>nil, 'Preferred should not be nil');
    FContext.AssertTrue(Abs((10.0)-(bs.Min.Value))<=(0.001), 'Min value should be 10');
    FContext.AssertTrue(Abs((100.0)-(bs.Preferred.Value))<=(0.001), 'Preferred value should be 100');
  finally
    bs.Free;
  end;
end;

procedure TTestMigConstraintParser.TestParseBoundSize_PrefMax;
var
  bs: TfpgMigBoundSize;
begin
  bs := ParseBoundSize(':100px:200px', False, True);
  try
    FContext.AssertTrue((bs)<>nil, 'Result should not be nil');
    FContext.AssertTrue((bs.Preferred)<>nil, 'Preferred should not be nil');
    FContext.AssertTrue((bs.Max)<>nil, 'Max should not be nil');
    FContext.AssertTrue(Abs((100.0)-(bs.Preferred.Value))<=(0.001), 'Preferred value should be 100');
    FContext.AssertTrue(Abs((200.0)-(bs.Max.Value))<=(0.001), 'Max value should be 200');
  finally
    bs.Free;
  end;
end;

procedure TTestMigConstraintParser.TestParseBoundSize_Null;
var
  bs: TfpgMigBoundSize;
begin
  bs := ParseBoundSize('null', False, True);
  FContext.AssertTrue((bs)=nil, 'null should return nil');

  bs := ParseBoundSize('n', False, True);
  FContext.AssertTrue((bs)=nil, 'n should return nil');
end;

procedure TTestMigConstraintParser.TestParseBoundSize_Push;
var
  bs: TfpgMigBoundSize;
begin
  bs := ParseBoundSize('10px:push', False, True);
  try
    FContext.AssertTrue((bs)<>nil, 'Result should not be nil');
    FContext.AssertTrue(bs.GapPush, 'Should have gap push');
  finally
    bs.Free;
  end;
end;

// ============================================================================
// ParseInsets tests
// ============================================================================

procedure TTestMigConstraintParser.TestParseInsets_SingleValue;
var
  insets: TfpgMigUnitValueArray;
  i: Integer;
begin
  insets := ParseInsets('10px', True);
  try
    FContext.AssertTrue((4)=(Length(insets)), 'Should have 4 values');
    FContext.AssertTrue((insets[0])<>nil, 'Top should not be nil');
    FContext.AssertTrue((insets[1])<>nil, 'Right should not be nil');
    FContext.AssertTrue((insets[2])<>nil, 'Bottom should not be nil');
    FContext.AssertTrue((insets[3])<>nil, 'Left should not be nil');
    FContext.AssertTrue(Abs((10.0)-(insets[0].Value))<=(0.001), 'All values should be 10');
    FContext.AssertTrue(Abs((10.0)-(insets[1].Value))<=(0.001), 'All values should be 10');
    FContext.AssertTrue(Abs((10.0)-(insets[2].Value))<=(0.001), 'All values should be 10');
    FContext.AssertTrue(Abs((10.0)-(insets[3].Value))<=(0.001), 'All values should be 10');
  finally
    for i := 0 to High(insets) do
      insets[i].Free;
  end;
end;

procedure TTestMigConstraintParser.TestParseInsets_FourValues;
var
  insets: TfpgMigUnitValueArray;
  i: Integer;
begin
  insets := ParseInsets('10px 20px 30px 40px', True);
  try
    FContext.AssertTrue((4)=(Length(insets)), 'Should have 4 values');
    FContext.AssertTrue((insets[0])<>nil, 'Top should not be nil');
    FContext.AssertTrue((insets[1])<>nil, 'Right should not be nil');
    FContext.AssertTrue((insets[2])<>nil, 'Bottom should not be nil');
    FContext.AssertTrue((insets[3])<>nil, 'Left should not be nil');
    FContext.AssertTrue(Abs((10.0)-(insets[0].Value))<=(0.001), 'Top should be 10');
    FContext.AssertTrue(Abs((20.0)-(insets[1].Value))<=(0.001), 'Right should be 20');
    FContext.AssertTrue(Abs((30.0)-(insets[2].Value))<=(0.001), 'Bottom should be 30');
    FContext.AssertTrue(Abs((40.0)-(insets[3].Value))<=(0.001), 'Left should be 40');
  finally
    for i := 0 to High(insets) do
      insets[i].Free;
  end;
end;

procedure TTestMigConstraintParser.TestParseInsets_TwoValues;
var
  insets: TfpgMigUnitValueArray;
  i: Integer;
begin
  insets := ParseInsets('10px 20px', True);
  try
    FContext.AssertTrue((4)=(Length(insets)), 'Should have 4 values');
    // Two values: uses last value for remaining (Java v11 behavior)
    // Order: top, right, bottom, left (0,1,2,3)
    FContext.AssertTrue(Abs((10.0)-(insets[0].Value))<=(0.001), 'Top should be 10');
    FContext.AssertTrue(Abs((20.0)-(insets[1].Value))<=(0.001), 'Right should be 20');
    FContext.AssertTrue(Abs((20.0)-(insets[2].Value))<=(0.001), 'Bottom should be 20 (uses last)');
    FContext.AssertTrue(Abs((20.0)-(insets[3].Value))<=(0.001), 'Left should be 20 (uses last)');
  finally
    for i := 0 to High(insets) do
      insets[i].Free;
  end;
end;

procedure TTestMigConstraintParser.TestParseInsets_Null;
var
  insets: TfpgMigUnitValueArray;
begin
  // In Java v11, "null" string in insets returns platform defaults, not empty array
  // parseUnitValue("null") returns nil, which triggers platform default fallback
  insets := ParseInsets('null', True);
  FContext.AssertTrue((4)=(Length(insets)), 'null should return platform defaults (4 values)');
  FContext.AssertTrue((insets[0])<>nil, 'All insets should be set');
  FContext.AssertTrue((insets[1])<>nil, 'All insets should be set');
  FContext.AssertTrue((insets[2])<>nil, 'All insets should be set');
  FContext.AssertTrue((insets[3])<>nil, 'All insets should be set');

  insets := ParseInsets('n', True);
  FContext.AssertTrue((4)=(Length(insets)), 'n should return platform defaults (4 values)');
end;


procedure RunTTestMigConstraintParserTestParseUnitValue_SimplePixels(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitValue_SimplePixels';
    lFixture.TestParseUnitValue_SimplePixels;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseUnitValue_Percent(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitValue_Percent';
    lFixture.TestParseUnitValue_Percent;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseUnitValue_Millimeters(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitValue_Millimeters';
    lFixture.TestParseUnitValue_Millimeters;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseUnitValue_LogicalPixels(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitValue_LogicalPixels';
    lFixture.TestParseUnitValue_LogicalPixels;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseUnitValue_MinSize(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitValue_MinSize';
    lFixture.TestParseUnitValue_MinSize;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseUnitValue_PrefSize(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitValue_PrefSize';
    lFixture.TestParseUnitValue_PrefSize;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseUnitValue_MaxSize(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitValue_MaxSize';
    lFixture.TestParseUnitValue_MaxSize;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseUnitValue_AlignLeft(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitValue_AlignLeft';
    lFixture.TestParseUnitValue_AlignLeft;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseUnitValue_AlignCenter(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitValue_AlignCenter';
    lFixture.TestParseUnitValue_AlignCenter;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseUnitValue_AlignRight(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitValue_AlignRight';
    lFixture.TestParseUnitValue_AlignRight;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseUnitValue_AlignTop(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitValue_AlignTop';
    lFixture.TestParseUnitValue_AlignTop;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseUnitValue_AlignBottom(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitValue_AlignBottom';
    lFixture.TestParseUnitValue_AlignBottom;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseUnitValue_WithAddition(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitValue_WithAddition';
    lFixture.TestParseUnitValue_WithAddition;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseUnitValue_WithSubtraction(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitValue_WithSubtraction';
    lFixture.TestParseUnitValue_WithSubtraction;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseUnitValue_MinOperation(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitValue_MinOperation';
    lFixture.TestParseUnitValue_MinOperation;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseUnitValue_MaxOperation(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitValue_MaxOperation';
    lFixture.TestParseUnitValue_MaxOperation;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseUnitValue_MidOperation(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseUnitValue_MidOperation';
    lFixture.TestParseUnitValue_MidOperation;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseBoundSize_SimpleValue(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseBoundSize_SimpleValue';
    lFixture.TestParseBoundSize_SimpleValue;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseBoundSize_MinPrefMax(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseBoundSize_MinPrefMax';
    lFixture.TestParseBoundSize_MinPrefMax;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseBoundSize_PrefOnly(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseBoundSize_PrefOnly';
    lFixture.TestParseBoundSize_PrefOnly;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseBoundSize_MinPref(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseBoundSize_MinPref';
    lFixture.TestParseBoundSize_MinPref;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseBoundSize_PrefMax(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseBoundSize_PrefMax';
    lFixture.TestParseBoundSize_PrefMax;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseBoundSize_Null(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseBoundSize_Null';
    lFixture.TestParseBoundSize_Null;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseBoundSize_Push(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseBoundSize_Push';
    lFixture.TestParseBoundSize_Push;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseInsets_SingleValue(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseInsets_SingleValue';
    lFixture.TestParseInsets_SingleValue;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseInsets_FourValues(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseInsets_FourValues';
    lFixture.TestParseInsets_FourValues;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseInsets_TwoValues(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseInsets_TwoValues';
    lFixture.TestParseInsets_TwoValues;
  finally lFixture.Free; end;
end;

procedure RunTTestMigConstraintParserTestParseInsets_Null(AContext: TNXTestContext);
var lFixture: TTestMigConstraintParser;
begin
  lFixture:=TTestMigConstraintParser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestParseInsets_Null';
    lFixture.TestParseInsets_Null;
  finally lFixture.Free; end;
end;

procedure RegistertcmigconstraintparserTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcmig_constraintparser.TTestMigConstraintParser');
  lSuite.AddTest('TestParseUnitValue_SimplePixels', @RunTTestMigConstraintParserTestParseUnitValue_SimplePixels);
  lSuite.AddTest('TestParseUnitValue_Percent', @RunTTestMigConstraintParserTestParseUnitValue_Percent);
  lSuite.AddTest('TestParseUnitValue_Millimeters', @RunTTestMigConstraintParserTestParseUnitValue_Millimeters);
  lSuite.AddTest('TestParseUnitValue_LogicalPixels', @RunTTestMigConstraintParserTestParseUnitValue_LogicalPixels);
  lSuite.AddTest('TestParseUnitValue_MinSize', @RunTTestMigConstraintParserTestParseUnitValue_MinSize);
  lSuite.AddTest('TestParseUnitValue_PrefSize', @RunTTestMigConstraintParserTestParseUnitValue_PrefSize);
  lSuite.AddTest('TestParseUnitValue_MaxSize', @RunTTestMigConstraintParserTestParseUnitValue_MaxSize);
  lSuite.AddTest('TestParseUnitValue_AlignLeft', @RunTTestMigConstraintParserTestParseUnitValue_AlignLeft);
  lSuite.AddTest('TestParseUnitValue_AlignCenter', @RunTTestMigConstraintParserTestParseUnitValue_AlignCenter);
  lSuite.AddTest('TestParseUnitValue_AlignRight', @RunTTestMigConstraintParserTestParseUnitValue_AlignRight);
  lSuite.AddTest('TestParseUnitValue_AlignTop', @RunTTestMigConstraintParserTestParseUnitValue_AlignTop);
  lSuite.AddTest('TestParseUnitValue_AlignBottom', @RunTTestMigConstraintParserTestParseUnitValue_AlignBottom);
  lSuite.AddTest('TestParseUnitValue_WithAddition', @RunTTestMigConstraintParserTestParseUnitValue_WithAddition);
  lSuite.AddTest('TestParseUnitValue_WithSubtraction', @RunTTestMigConstraintParserTestParseUnitValue_WithSubtraction);
  lSuite.AddTest('TestParseUnitValue_MinOperation', @RunTTestMigConstraintParserTestParseUnitValue_MinOperation);
  lSuite.AddTest('TestParseUnitValue_MaxOperation', @RunTTestMigConstraintParserTestParseUnitValue_MaxOperation);
  lSuite.AddTest('TestParseUnitValue_MidOperation', @RunTTestMigConstraintParserTestParseUnitValue_MidOperation);
  lSuite.AddTest('TestParseBoundSize_SimpleValue', @RunTTestMigConstraintParserTestParseBoundSize_SimpleValue);
  lSuite.AddTest('TestParseBoundSize_MinPrefMax', @RunTTestMigConstraintParserTestParseBoundSize_MinPrefMax);
  lSuite.AddTest('TestParseBoundSize_PrefOnly', @RunTTestMigConstraintParserTestParseBoundSize_PrefOnly);
  lSuite.AddTest('TestParseBoundSize_MinPref', @RunTTestMigConstraintParserTestParseBoundSize_MinPref);
  lSuite.AddTest('TestParseBoundSize_PrefMax', @RunTTestMigConstraintParserTestParseBoundSize_PrefMax);
  lSuite.AddTest('TestParseBoundSize_Null', @RunTTestMigConstraintParserTestParseBoundSize_Null);
  lSuite.AddTest('TestParseBoundSize_Push', @RunTTestMigConstraintParserTestParseBoundSize_Push);
  lSuite.AddTest('TestParseInsets_SingleValue', @RunTTestMigConstraintParserTestParseInsets_SingleValue);
  lSuite.AddTest('TestParseInsets_FourValues', @RunTTestMigConstraintParserTestParseInsets_FourValues);
  lSuite.AddTest('TestParseInsets_TwoValues', @RunTTestMigConstraintParserTestParseInsets_TwoValues);
  lSuite.AddTest('TestParseInsets_Null', @RunTTestMigConstraintParserTestParseInsets_Null);
end;

end.

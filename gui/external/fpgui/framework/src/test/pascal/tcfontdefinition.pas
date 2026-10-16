unit tcfontdefinition;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  fpg_base;

type
  { Test suite for TfpgFontDefinition parsing and normalization }
  TTestFontDefinition = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    { Basic parsing tests }
    procedure TestParseSimpleDescriptor;
    procedure TestParseBoldDescriptor;
    procedure TestParseItalicDescriptor;
    procedure TestParseBoldItalicDescriptor;
    procedure TestParseUnderlineDescriptor;
    procedure TestParseMultipleAttributes;

    { Normalization tests }
    procedure TestNormalizationUpperCase;
    procedure TestNormalizationLowerCase;
    procedure TestNormalizationMixedCase;
    procedure TestNormalizationAttributeOrder;

    { Edge cases }
    procedure TestEmptyDescriptor;
    procedure TestDescriptorWithoutSize;
    procedure TestDescriptorWithSpaces;
    procedure TestDescriptorWithDuplicateAttributes;

    { Property access tests }
    procedure TestFaceNameExtraction;
    procedure TestSizeExtraction;
    procedure TestAttributeFlags;
  end;

procedure RegistertcfontdefinitionTests(ARegistry: TNXTestRegistry);

implementation

{ TTestFontDefinition }

procedure TTestFontDefinition.TestParseSimpleDescriptor;
var
  fontDef: TfpgFontDefinition;
begin
  fontDef := TfpgFontDefinition.Create('Arial-12');
  try
    TestContext.AssertTrue(('Arial')=(fontDef.FaceName), 'Face name should be Arial');
    TestContext.AssertTrue((12)=(fontDef.Size), 'Size should be 12');
    TestContext.AssertTrue(not (fpgFontBold in fontDef.Attributes), 'Should not be bold');
    TestContext.AssertTrue(not (fpgFontItalic in fontDef.Attributes), 'Should not be italic');
    TestContext.AssertTrue(not (fpgFontUnderline in fontDef.Attributes), 'Should not be underline');
  finally
    fontDef.Free;
  end;
end;

procedure TTestFontDefinition.TestParseBoldDescriptor;
var
  fontDef: TfpgFontDefinition;
begin
  fontDef := TfpgFontDefinition.Create('Arial-12:bold');
  try
    TestContext.AssertTrue(('Arial')=(fontDef.FaceName), '');
    TestContext.AssertTrue((12)=(fontDef.Size), '');
    TestContext.AssertTrue(fpgFontBold in fontDef.Attributes, 'Should be bold');
    TestContext.AssertTrue(not (fpgFontItalic in fontDef.Attributes), 'Should not be italic');
  finally
    fontDef.Free;
  end;
end;

procedure TTestFontDefinition.TestParseItalicDescriptor;
var
  fontDef: TfpgFontDefinition;
begin
  fontDef := TfpgFontDefinition.Create('Arial-12:italic');
  try
    TestContext.AssertTrue(not (fpgFontBold in fontDef.Attributes), 'Should not be bold');
    TestContext.AssertTrue(fpgFontItalic in fontDef.Attributes, 'Should be italic');
  finally
    fontDef.Free;
  end;
end;

procedure TTestFontDefinition.TestParseBoldItalicDescriptor;
var
  fontDef: TfpgFontDefinition;
begin
  fontDef := TfpgFontDefinition.Create('Arial-12:bold:italic');
  try
    TestContext.AssertTrue(fpgFontBold in fontDef.Attributes, 'Should be bold');
    TestContext.AssertTrue(fpgFontItalic in fontDef.Attributes, 'Should be italic');
  finally
    fontDef.Free;
  end;
end;

procedure TTestFontDefinition.TestParseUnderlineDescriptor;
var
  fontDef: TfpgFontDefinition;
begin
  fontDef := TfpgFontDefinition.Create('Arial-12:underline');
  try
    TestContext.AssertTrue(fpgFontUnderline in fontDef.Attributes, 'Should be underline');
  finally
    fontDef.Free;
  end;
end;

procedure TTestFontDefinition.TestParseMultipleAttributes;
var
  fontDef: TfpgFontDefinition;
begin
  fontDef := TfpgFontDefinition.Create('Liberation Sans-14:bold:italic:underline');
  try
    TestContext.AssertTrue(('Liberation Sans')=(fontDef.FaceName), '');
    TestContext.AssertTrue((14)=(fontDef.Size), '');
    TestContext.AssertTrue(fpgFontBold in fontDef.Attributes, 'Should be bold');
    TestContext.AssertTrue(fpgFontItalic in fontDef.Attributes, 'Should be italic');
    TestContext.AssertTrue(fpgFontUnderline in fontDef.Attributes, 'Should be underline');
  finally
    fontDef.Free;
  end;
end;

procedure TTestFontDefinition.TestNormalizationUpperCase;
var
  fontDef1, fontDef2: TfpgFontDefinition;
begin
  fontDef1 := TfpgFontDefinition.Create('Arial-12:bold');
  fontDef2 := TfpgFontDefinition.Create('ARIAL-12:BOLD');
  try
    TestContext.AssertTrue((fontDef1.FontDesc)=(fontDef2.FontDesc), 'Normalized descriptors should be identical');
  finally
    fontDef1.Free;
    fontDef2.Free;
  end;
end;

procedure TTestFontDefinition.TestNormalizationLowerCase;
var
  fontDef1, fontDef2: TfpgFontDefinition;
begin
  fontDef1 := TfpgFontDefinition.Create('Arial-12:bold');
  fontDef2 := TfpgFontDefinition.Create('arial-12:bold');
  try
    TestContext.AssertTrue((fontDef1.FontDesc)=(fontDef2.FontDesc), 'Normalized descriptors should be identical');
  finally
    fontDef1.Free;
    fontDef2.Free;
  end;
end;

procedure TTestFontDefinition.TestNormalizationMixedCase;
var
  fontDef1, fontDef2: TfpgFontDefinition;
begin
  fontDef1 := TfpgFontDefinition.Create('Liberation Sans-12:bold:italic');
  fontDef2 := TfpgFontDefinition.Create('Liberation SANS-12:BOLD:italic');
  try
    TestContext.AssertTrue((fontDef1.FontDesc)=(fontDef2.FontDesc), 'Mixed case should normalize to same descriptor');
  finally
    fontDef1.Free;
    fontDef2.Free;
  end;
end;

procedure TTestFontDefinition.TestNormalizationAttributeOrder;
var
  fontDef1, fontDef2: TfpgFontDefinition;
begin
  fontDef1 := TfpgFontDefinition.Create('Arial-12:bold:italic');
  fontDef2 := TfpgFontDefinition.Create('Arial-12:italic:bold');
  try
    TestContext.AssertTrue((fontDef1.FontDesc)=(fontDef2.FontDesc), 'Attribute order should normalize to canonical form');
  finally
    fontDef1.Free;
    fontDef2.Free;
  end;
end;

procedure TTestFontDefinition.TestEmptyDescriptor;
var
  fontDef: TfpgFontDefinition;
begin
  { Empty descriptor should use defaults }
  fontDef := TfpgFontDefinition.Create('');
  try
    TestContext.AssertTrue(fontDef.FaceName <> '', 'Should have default face name');
    TestContext.AssertTrue(fontDef.Size > 0, 'Should have default size');
  finally
    fontDef.Free;
  end;
end;

procedure TTestFontDefinition.TestDescriptorWithoutSize;
var
  fontDef: TfpgFontDefinition;
begin
  { Descriptor without size should use default }
  fontDef := TfpgFontDefinition.Create('Arial');
  try
    TestContext.AssertTrue(('Arial')=(fontDef.FaceName), '');
    TestContext.AssertTrue(fontDef.Size > 0, 'Should have default size');
  finally
    fontDef.Free;
  end;
end;

procedure TTestFontDefinition.TestDescriptorWithSpaces;
var
  fontDef: TfpgFontDefinition;
begin
  { Font names with spaces should be handled correctly }
  fontDef := TfpgFontDefinition.Create('Liberation Sans-12:bold');
  try
    TestContext.AssertTrue(('Liberation Sans')=(fontDef.FaceName), 'Face name with spaces should be preserved');
    TestContext.AssertTrue((12)=(fontDef.Size), '');
    TestContext.AssertTrue(fpgFontBold in fontDef.Attributes, 'Should be bold');
  finally
    fontDef.Free;
  end;
end;

procedure TTestFontDefinition.TestDescriptorWithDuplicateAttributes;
var
  fontDef: TfpgFontDefinition;
begin
  { Duplicate attributes should be deduplicated }
  fontDef := TfpgFontDefinition.Create('Arial-12:bold:bold:italic');
  try
    TestContext.AssertTrue(fpgFontBold in fontDef.Attributes, 'Should be bold');
    TestContext.AssertTrue(fpgFontItalic in fontDef.Attributes, 'Should be italic');
    { Normalized descriptor should not have duplicates }
    TestContext.AssertTrue(Pos(':bold:bold:', fontDef.FontDesc) = 0, 'Normalized descriptor should not contain duplicate :bold:');
  finally
    fontDef.Free;
  end;
end;

procedure TTestFontDefinition.TestFaceNameExtraction;
var
  fontDef: TfpgFontDefinition;
begin
  fontDef := TfpgFontDefinition.Create('Courier New-10:bold');
  try
    TestContext.AssertTrue(('Courier New')=(fontDef.FaceName), 'Should extract face name with spaces correctly');
  finally
    fontDef.Free;
  end;
end;

procedure TTestFontDefinition.TestSizeExtraction;
var
  fontDef: TfpgFontDefinition;
begin
  fontDef := TfpgFontDefinition.Create('Arial-18');
  try
    TestContext.AssertTrue((18)=(fontDef.Size), 'Should extract size correctly');
  finally
    fontDef.Free;
  end;
end;

procedure TTestFontDefinition.TestAttributeFlags;
var
  fontDef: TfpgFontDefinition;
begin
  fontDef := TfpgFontDefinition.Create('Arial-12:bold:italic:underline');
  try
    TestContext.AssertTrue(fpgFontBold in fontDef.Attributes, 'Bold flag should be set');
    TestContext.AssertTrue(fpgFontItalic in fontDef.Attributes, 'Italic flag should be set');
    TestContext.AssertTrue(fpgFontUnderline in fontDef.Attributes, 'Underline flag should be set');
  finally
    fontDef.Free;
  end;
end;

constructor TTestFontDefinition.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestFontDefinitionTestParseSimpleDescriptor(AContext: TNXTestContext);
var lFixture: TTestFontDefinition;
begin
  lFixture:=TTestFontDefinition.Create(AContext, 'TestParseSimpleDescriptor');
  try
    lFixture.TestParseSimpleDescriptor;
  finally lFixture.Free; end;
end;

procedure RunTTestFontDefinitionTestParseBoldDescriptor(AContext: TNXTestContext);
var lFixture: TTestFontDefinition;
begin
  lFixture:=TTestFontDefinition.Create(AContext, 'TestParseBoldDescriptor');
  try
    lFixture.TestParseBoldDescriptor;
  finally lFixture.Free; end;
end;

procedure RunTTestFontDefinitionTestParseItalicDescriptor(AContext: TNXTestContext);
var lFixture: TTestFontDefinition;
begin
  lFixture:=TTestFontDefinition.Create(AContext, 'TestParseItalicDescriptor');
  try
    lFixture.TestParseItalicDescriptor;
  finally lFixture.Free; end;
end;

procedure RunTTestFontDefinitionTestParseBoldItalicDescriptor(AContext: TNXTestContext);
var lFixture: TTestFontDefinition;
begin
  lFixture:=TTestFontDefinition.Create(AContext, 'TestParseBoldItalicDescriptor');
  try
    lFixture.TestParseBoldItalicDescriptor;
  finally lFixture.Free; end;
end;

procedure RunTTestFontDefinitionTestParseUnderlineDescriptor(AContext: TNXTestContext);
var lFixture: TTestFontDefinition;
begin
  lFixture:=TTestFontDefinition.Create(AContext, 'TestParseUnderlineDescriptor');
  try
    lFixture.TestParseUnderlineDescriptor;
  finally lFixture.Free; end;
end;

procedure RunTTestFontDefinitionTestParseMultipleAttributes(AContext: TNXTestContext);
var lFixture: TTestFontDefinition;
begin
  lFixture:=TTestFontDefinition.Create(AContext, 'TestParseMultipleAttributes');
  try
    lFixture.TestParseMultipleAttributes;
  finally lFixture.Free; end;
end;

procedure RunTTestFontDefinitionTestNormalizationUpperCase(AContext: TNXTestContext);
var lFixture: TTestFontDefinition;
begin
  lFixture:=TTestFontDefinition.Create(AContext, 'TestNormalizationUpperCase');
  try
    lFixture.TestNormalizationUpperCase;
  finally lFixture.Free; end;
end;

procedure RunTTestFontDefinitionTestNormalizationLowerCase(AContext: TNXTestContext);
var lFixture: TTestFontDefinition;
begin
  lFixture:=TTestFontDefinition.Create(AContext, 'TestNormalizationLowerCase');
  try
    lFixture.TestNormalizationLowerCase;
  finally lFixture.Free; end;
end;

procedure RunTTestFontDefinitionTestNormalizationMixedCase(AContext: TNXTestContext);
var lFixture: TTestFontDefinition;
begin
  lFixture:=TTestFontDefinition.Create(AContext, 'TestNormalizationMixedCase');
  try
    lFixture.TestNormalizationMixedCase;
  finally lFixture.Free; end;
end;

procedure RunTTestFontDefinitionTestNormalizationAttributeOrder(AContext: TNXTestContext);
var lFixture: TTestFontDefinition;
begin
  lFixture:=TTestFontDefinition.Create(AContext, 'TestNormalizationAttributeOrder');
  try
    lFixture.TestNormalizationAttributeOrder;
  finally lFixture.Free; end;
end;

procedure RunTTestFontDefinitionTestEmptyDescriptor(AContext: TNXTestContext);
var lFixture: TTestFontDefinition;
begin
  lFixture:=TTestFontDefinition.Create(AContext, 'TestEmptyDescriptor');
  try
    lFixture.TestEmptyDescriptor;
  finally lFixture.Free; end;
end;

procedure RunTTestFontDefinitionTestDescriptorWithoutSize(AContext: TNXTestContext);
var lFixture: TTestFontDefinition;
begin
  lFixture:=TTestFontDefinition.Create(AContext, 'TestDescriptorWithoutSize');
  try
    lFixture.TestDescriptorWithoutSize;
  finally lFixture.Free; end;
end;

procedure RunTTestFontDefinitionTestDescriptorWithSpaces(AContext: TNXTestContext);
var lFixture: TTestFontDefinition;
begin
  lFixture:=TTestFontDefinition.Create(AContext, 'TestDescriptorWithSpaces');
  try
    lFixture.TestDescriptorWithSpaces;
  finally lFixture.Free; end;
end;

procedure RunTTestFontDefinitionTestDescriptorWithDuplicateAttributes(AContext: TNXTestContext);
var lFixture: TTestFontDefinition;
begin
  lFixture:=TTestFontDefinition.Create(AContext, 'TestDescriptorWithDuplicateAttributes');
  try
    lFixture.TestDescriptorWithDuplicateAttributes;
  finally lFixture.Free; end;
end;

procedure RunTTestFontDefinitionTestFaceNameExtraction(AContext: TNXTestContext);
var lFixture: TTestFontDefinition;
begin
  lFixture:=TTestFontDefinition.Create(AContext, 'TestFaceNameExtraction');
  try
    lFixture.TestFaceNameExtraction;
  finally lFixture.Free; end;
end;

procedure RunTTestFontDefinitionTestSizeExtraction(AContext: TNXTestContext);
var lFixture: TTestFontDefinition;
begin
  lFixture:=TTestFontDefinition.Create(AContext, 'TestSizeExtraction');
  try
    lFixture.TestSizeExtraction;
  finally lFixture.Free; end;
end;

procedure RunTTestFontDefinitionTestAttributeFlags(AContext: TNXTestContext);
var lFixture: TTestFontDefinition;
begin
  lFixture:=TTestFontDefinition.Create(AContext, 'TestAttributeFlags');
  try
    lFixture.TestAttributeFlags;
  finally lFixture.Free; end;
end;

procedure RegistertcfontdefinitionTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcfontdefinition.TTestFontDefinition');
  lSuite.AddTest('TestParseSimpleDescriptor', @RunTTestFontDefinitionTestParseSimpleDescriptor);
  lSuite.AddTest('TestParseBoldDescriptor', @RunTTestFontDefinitionTestParseBoldDescriptor);
  lSuite.AddTest('TestParseItalicDescriptor', @RunTTestFontDefinitionTestParseItalicDescriptor);
  lSuite.AddTest('TestParseBoldItalicDescriptor', @RunTTestFontDefinitionTestParseBoldItalicDescriptor);
  lSuite.AddTest('TestParseUnderlineDescriptor', @RunTTestFontDefinitionTestParseUnderlineDescriptor);
  lSuite.AddTest('TestParseMultipleAttributes', @RunTTestFontDefinitionTestParseMultipleAttributes);
  lSuite.AddTest('TestNormalizationUpperCase', @RunTTestFontDefinitionTestNormalizationUpperCase);
  lSuite.AddTest('TestNormalizationLowerCase', @RunTTestFontDefinitionTestNormalizationLowerCase);
  lSuite.AddTest('TestNormalizationMixedCase', @RunTTestFontDefinitionTestNormalizationMixedCase);
  lSuite.AddTest('TestNormalizationAttributeOrder', @RunTTestFontDefinitionTestNormalizationAttributeOrder);
  lSuite.AddTest('TestEmptyDescriptor', @RunTTestFontDefinitionTestEmptyDescriptor);
  lSuite.AddTest('TestDescriptorWithoutSize', @RunTTestFontDefinitionTestDescriptorWithoutSize);
  lSuite.AddTest('TestDescriptorWithSpaces', @RunTTestFontDefinitionTestDescriptorWithSpaces);
  lSuite.AddTest('TestDescriptorWithDuplicateAttributes', @RunTTestFontDefinitionTestDescriptorWithDuplicateAttributes);
  lSuite.AddTest('TestFaceNameExtraction', @RunTTestFontDefinitionTestFaceNameExtraction);
  lSuite.AddTest('TestSizeExtraction', @RunTTestFontDefinitionTestSizeExtraction);
  lSuite.AddTest('TestAttributeFlags', @RunTTestFontDefinitionTestAttributeFlags);
end;


end.

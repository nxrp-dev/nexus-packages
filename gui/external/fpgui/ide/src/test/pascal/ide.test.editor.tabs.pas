{
    fpGUI IDE - Editor Tab Tests

    Tests for pure functions in ide.editor.tabs: highlight kind detection
    from file extensions.
}
unit ide.test.editor.tabs;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  ide.editor.tabs;

type

  { TTestHighlightKindForExtension }

  TTestHighlightKindForExtension = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  public
    procedure TestPascalExtensions;
    procedure TestPatchExtensions;
    procedure TestINIExtensions;
    procedure TestXMLExtensions;
    procedure TestUnknownExtension;
    procedure TestEmptyExtension;
  end;

procedure RegisteridetesteditortabsTests(ARegistry: TNXTestRegistry);

implementation

procedure TTestHighlightKindForExtension.TestPascalExtensions;
begin
  TestContext.AssertTrue(HighlightKindForExtension('.pas') = hkPascal, '.pas');
  TestContext.AssertTrue(HighlightKindForExtension('.pp') = hkPascal, '.pp');
  TestContext.AssertTrue(HighlightKindForExtension('.inc') = hkPascal, '.inc');
  TestContext.AssertTrue(HighlightKindForExtension('.lpr') = hkPascal, '.lpr');
  TestContext.AssertTrue(HighlightKindForExtension('.dpr') = hkPascal, '.dpr');
end;

procedure TTestHighlightKindForExtension.TestPatchExtensions;
begin
  TestContext.AssertTrue(HighlightKindForExtension('.patch') = hkPatch, '.patch');
  TestContext.AssertTrue(HighlightKindForExtension('.diff') = hkPatch, '.diff');
end;

procedure TTestHighlightKindForExtension.TestINIExtensions;
begin
  TestContext.AssertTrue(HighlightKindForExtension('.ini') = hkINI, '.ini');
  TestContext.AssertTrue(HighlightKindForExtension('.cfg') = hkINI, '.cfg');
  TestContext.AssertTrue(HighlightKindForExtension('.conf') = hkINI, '.conf');
end;

procedure TTestHighlightKindForExtension.TestXMLExtensions;
begin
  TestContext.AssertTrue(HighlightKindForExtension('.xml') = hkXML, '.xml');
  TestContext.AssertTrue(HighlightKindForExtension('.html') = hkXML, '.html');
  TestContext.AssertTrue(HighlightKindForExtension('.htm') = hkXML, '.htm');
  TestContext.AssertTrue(HighlightKindForExtension('.xhtml') = hkXML, '.xhtml');
  TestContext.AssertTrue(HighlightKindForExtension('.svg') = hkXML, '.svg');
  TestContext.AssertTrue(HighlightKindForExtension('.xsd') = hkXML, '.xsd');
  TestContext.AssertTrue(HighlightKindForExtension('.xsl') = hkXML, '.xsl');
  TestContext.AssertTrue(HighlightKindForExtension('.xslt') = hkXML, '.xslt');
  TestContext.AssertTrue(HighlightKindForExtension('.lpi') = hkXML, '.lpi');
  TestContext.AssertTrue(HighlightKindForExtension('.lpk') = hkXML, '.lpk');
end;

procedure TTestHighlightKindForExtension.TestUnknownExtension;
begin
  TestContext.AssertTrue(HighlightKindForExtension('.txt') = hkNone, '.txt');
  TestContext.AssertTrue(HighlightKindForExtension('.md') = hkNone, '.md');
  TestContext.AssertTrue(HighlightKindForExtension('.log') = hkNone, '.log');
end;

procedure TTestHighlightKindForExtension.TestEmptyExtension;
begin
  TestContext.AssertTrue(HighlightKindForExtension('') = hkNone, 'empty');
end;


constructor TTestHighlightKindForExtension.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestHighlightKindForExtensionTestPascalExtensions(AContext: TNXTestContext);
var lFixture: TTestHighlightKindForExtension;
begin
  lFixture:=TTestHighlightKindForExtension.Create(AContext, 'TestPascalExtensions');
  try
    lFixture.TestPascalExtensions;
  finally lFixture.Free; end;
end;

procedure RunTTestHighlightKindForExtensionTestPatchExtensions(AContext: TNXTestContext);
var lFixture: TTestHighlightKindForExtension;
begin
  lFixture:=TTestHighlightKindForExtension.Create(AContext, 'TestPatchExtensions');
  try
    lFixture.TestPatchExtensions;
  finally lFixture.Free; end;
end;

procedure RunTTestHighlightKindForExtensionTestINIExtensions(AContext: TNXTestContext);
var lFixture: TTestHighlightKindForExtension;
begin
  lFixture:=TTestHighlightKindForExtension.Create(AContext, 'TestINIExtensions');
  try
    lFixture.TestINIExtensions;
  finally lFixture.Free; end;
end;

procedure RunTTestHighlightKindForExtensionTestXMLExtensions(AContext: TNXTestContext);
var lFixture: TTestHighlightKindForExtension;
begin
  lFixture:=TTestHighlightKindForExtension.Create(AContext, 'TestXMLExtensions');
  try
    lFixture.TestXMLExtensions;
  finally lFixture.Free; end;
end;

procedure RunTTestHighlightKindForExtensionTestUnknownExtension(AContext: TNXTestContext);
var lFixture: TTestHighlightKindForExtension;
begin
  lFixture:=TTestHighlightKindForExtension.Create(AContext, 'TestUnknownExtension');
  try
    lFixture.TestUnknownExtension;
  finally lFixture.Free; end;
end;

procedure RunTTestHighlightKindForExtensionTestEmptyExtension(AContext: TNXTestContext);
var lFixture: TTestHighlightKindForExtension;
begin
  lFixture:=TTestHighlightKindForExtension.Create(AContext, 'TestEmptyExtension');
  try
    lFixture.TestEmptyExtension;
  finally lFixture.Free; end;
end;

procedure RegisteridetesteditortabsTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.editor.tabs.TTestHighlightKindForExtension');
  lSuite.AddTest('TestPascalExtensions', @RunTTestHighlightKindForExtensionTestPascalExtensions);
  lSuite.AddTest('TestPatchExtensions', @RunTTestHighlightKindForExtensionTestPatchExtensions);
  lSuite.AddTest('TestINIExtensions', @RunTTestHighlightKindForExtensionTestINIExtensions);
  lSuite.AddTest('TestXMLExtensions', @RunTTestHighlightKindForExtensionTestXMLExtensions);
  lSuite.AddTest('TestUnknownExtension', @RunTTestHighlightKindForExtensionTestUnknownExtension);
  lSuite.AddTest('TestEmptyExtension', @RunTTestHighlightKindForExtensionTestEmptyExtension);
end;

end.

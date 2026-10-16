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
  protected
    FContext: TNXTestContext;
    FCaseName: string;
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
  FContext.AssertTrue(HighlightKindForExtension('.pas') = hkPascal, '.pas');
  FContext.AssertTrue(HighlightKindForExtension('.pp') = hkPascal, '.pp');
  FContext.AssertTrue(HighlightKindForExtension('.inc') = hkPascal, '.inc');
  FContext.AssertTrue(HighlightKindForExtension('.lpr') = hkPascal, '.lpr');
  FContext.AssertTrue(HighlightKindForExtension('.dpr') = hkPascal, '.dpr');
end;

procedure TTestHighlightKindForExtension.TestPatchExtensions;
begin
  FContext.AssertTrue(HighlightKindForExtension('.patch') = hkPatch, '.patch');
  FContext.AssertTrue(HighlightKindForExtension('.diff') = hkPatch, '.diff');
end;

procedure TTestHighlightKindForExtension.TestINIExtensions;
begin
  FContext.AssertTrue(HighlightKindForExtension('.ini') = hkINI, '.ini');
  FContext.AssertTrue(HighlightKindForExtension('.cfg') = hkINI, '.cfg');
  FContext.AssertTrue(HighlightKindForExtension('.conf') = hkINI, '.conf');
end;

procedure TTestHighlightKindForExtension.TestXMLExtensions;
begin
  FContext.AssertTrue(HighlightKindForExtension('.xml') = hkXML, '.xml');
  FContext.AssertTrue(HighlightKindForExtension('.html') = hkXML, '.html');
  FContext.AssertTrue(HighlightKindForExtension('.htm') = hkXML, '.htm');
  FContext.AssertTrue(HighlightKindForExtension('.xhtml') = hkXML, '.xhtml');
  FContext.AssertTrue(HighlightKindForExtension('.svg') = hkXML, '.svg');
  FContext.AssertTrue(HighlightKindForExtension('.xsd') = hkXML, '.xsd');
  FContext.AssertTrue(HighlightKindForExtension('.xsl') = hkXML, '.xsl');
  FContext.AssertTrue(HighlightKindForExtension('.xslt') = hkXML, '.xslt');
  FContext.AssertTrue(HighlightKindForExtension('.lpi') = hkXML, '.lpi');
  FContext.AssertTrue(HighlightKindForExtension('.lpk') = hkXML, '.lpk');
end;

procedure TTestHighlightKindForExtension.TestUnknownExtension;
begin
  FContext.AssertTrue(HighlightKindForExtension('.txt') = hkNone, '.txt');
  FContext.AssertTrue(HighlightKindForExtension('.md') = hkNone, '.md');
  FContext.AssertTrue(HighlightKindForExtension('.log') = hkNone, '.log');
end;

procedure TTestHighlightKindForExtension.TestEmptyExtension;
begin
  FContext.AssertTrue(HighlightKindForExtension('') = hkNone, 'empty');
end;


procedure RunTTestHighlightKindForExtensionTestPascalExtensions(AContext: TNXTestContext);
var lFixture: TTestHighlightKindForExtension;
begin
  lFixture:=TTestHighlightKindForExtension.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestPascalExtensions';
    lFixture.TestPascalExtensions;
  finally lFixture.Free; end;
end;

procedure RunTTestHighlightKindForExtensionTestPatchExtensions(AContext: TNXTestContext);
var lFixture: TTestHighlightKindForExtension;
begin
  lFixture:=TTestHighlightKindForExtension.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestPatchExtensions';
    lFixture.TestPatchExtensions;
  finally lFixture.Free; end;
end;

procedure RunTTestHighlightKindForExtensionTestINIExtensions(AContext: TNXTestContext);
var lFixture: TTestHighlightKindForExtension;
begin
  lFixture:=TTestHighlightKindForExtension.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestINIExtensions';
    lFixture.TestINIExtensions;
  finally lFixture.Free; end;
end;

procedure RunTTestHighlightKindForExtensionTestXMLExtensions(AContext: TNXTestContext);
var lFixture: TTestHighlightKindForExtension;
begin
  lFixture:=TTestHighlightKindForExtension.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestXMLExtensions';
    lFixture.TestXMLExtensions;
  finally lFixture.Free; end;
end;

procedure RunTTestHighlightKindForExtensionTestUnknownExtension(AContext: TNXTestContext);
var lFixture: TTestHighlightKindForExtension;
begin
  lFixture:=TTestHighlightKindForExtension.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestUnknownExtension';
    lFixture.TestUnknownExtension;
  finally lFixture.Free; end;
end;

procedure RunTTestHighlightKindForExtensionTestEmptyExtension(AContext: TNXTestContext);
var lFixture: TTestHighlightKindForExtension;
begin
  lFixture:=TTestHighlightKindForExtension.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmptyExtension';
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

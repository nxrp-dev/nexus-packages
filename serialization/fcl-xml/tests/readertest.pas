{**********************************************************************

    This file is part of the Free Component Library (FCL)

    Test cases for TXMLReader class and its descendants
    Copyright (c) 2012 by Sergei Gorelkin, sergei_gorelkin@mail.ru

    Using tests from Mono test suite, written by
      Jason Diamond (jason@injektilo.org)
      Martin Willemoes Hansen (mwh@sysrq.dk)
      (C) 2001, 2002 Jason Diamond  http://injektilo.org/

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
unit readertest;
{$mode objfpc}{$h+}

interface

uses obNXTestRegistry;

procedure RegisterreadertestTests(ARegistry: TNXTestRegistry);

implementation

uses
  obNXTestContext, obNXTestSuite, sysutils, xmlutils, readerunit, XmlReader;

type
  TXMLReaderTest = class(TXMLReaderTestBase)
  public
    procedure TestInitialState(r: TXMLReader);
    procedure TestReadEmptySource(r: TXMLReader);
    procedure TestRead(r: TXMLReader);
    procedure TestReadAttributeValue(r: TXMLReader);
    procedure TestReadAttributeValue2(r: TXMLReader);
    procedure TestDTDProperties(r: TXMLReader);
    procedure TestReadStringFromElement(r: TXMLReader);
    procedure TestEmptyElement(r: TXMLReader);
    procedure TestNestedEmptyTag(r: TXMLReader);
    procedure TestNestedText(r: TXMLReader);
    procedure TestEmptyElementWithAttributes(r: TXMLReader);
    procedure TestPIBeforeRoot(r: TXMLReader);
    procedure TestCommentBeforeRoot(r: TXMLReader);
    procedure TestCDATA(r: TXMLReader);
    procedure TestChildElementInNamespace(r: TXMLReader);
    procedure TestMoveToElementFromAttribute(r: TXMLReader);
    procedure TestMoveToElementFromElement(r: TXMLReader);
    procedure TestMoveToNextAttribute(r: TXMLReader);
    procedure TestResolveEntity(r: TXMLReader);
    procedure TestLineInfo(r: TXMLReader);
  public
    procedure InitialState;
    procedure ReadEmptySource;
    procedure Read;
    procedure ReadAttributeValue;
    procedure ReadAttributeValue2;
    procedure DTDProperties;
    procedure ReadStringFromElement;
    procedure EmptyElement;
    procedure NestedEmptyTag;
    procedure NestedText;
    procedure EmptyElementWithAttributes;
    procedure PIBeforeRoot;
    procedure CommentBeforeRoot;
    procedure CDATA;
    procedure ChildElementInNamespace;
    procedure MoveToElementFromAttribute;
    procedure MoveToElementFromElement;
    procedure MoveToNextAttribute;
    procedure ResolveEntity;
    procedure LineInfo;
  end;

const
  xml1 = '<root attr1=''value1''><child /></root>';
  xml2 = '<root><foo/><bar>test.</bar></root>';
  xml3 = '<root>  test of <b>mixed</b> string.<![CDATA[ cdata string.]]></root>';


procedure TXMLReaderTest.TestInitialState(r: TXMLReader);
begin
  TestContext.AssertTrue((0)=(r.Depth), 'Depth');
  TestContext.AssertTrue((False)=(r.EOF), 'EOF');
  TestContext.AssertTrue((False)=(r.HasValue), 'HasValue');
  AssertEqualsW('LocalName', '', r.LocalName);
  TestContext.AssertTrue((ntNone)=(r.NodeType), 'NodeType');
  TestContext.AssertTrue((rsInitial)=(r.ReadState), 'ReadState');
end;

procedure TXMLReaderTest.InitialState;
begin
  DoTest(xml1, @TestInitialState);
end;

// TODO: this should fail only when conformancelevel=document
procedure TXMLReaderTest.TestReadEmptySource(r: TXMLReader);
begin
  try
    r.Read;
    TestContext.Fail('Read empty source succeeded');
  except
  end;
end;

procedure TXMLReaderTest.ReadEmptySource;
begin
  DoTest('', @TestReadEmptySource);
end;

procedure TXMLReaderTest.TestRead(r: TXMLReader);
begin
  r.Read;
  TestContext.AssertTrue((ntElement)=(r.NodeType), '<root>.NodeType');
  AssertEqualsW('<root>.Name', 'root', r.Name);
  TestContext.AssertTrue((rsInteractive)=(r.ReadState), '<root>.ReadState');
  TestContext.AssertTrue((0)=(r.Depth), '<root>.Depth');

  // move to 'child'
  r.Read;
  TestContext.AssertTrue((1)=(r.Depth), '<child/>.Depth');
  TestContext.AssertTrue((ntElement)=(r.NodeType), '<child/>.NodeType');
  AssertEqualsW('<child/>.Name', 'child', r.Name);

  { this differs from .net; we don't support EmptyElement }
  r.Read;
  TestContext.AssertTrue((1)=(r.Depth), '<child/>.EndDepth');
  TestContext.AssertTrue((ntEndElement)=(r.NodeType), '<child/>.EndNodeType');
  AssertEqualsW('<child/>.EndName', 'child', r.Name);

  r.Read;
  TestContext.AssertTrue((0)=(r.Depth), '</root>.Depth');
  TestContext.AssertTrue((ntEndElement)=(r.NodeType), '</root>.NodeType');
  AssertEqualsW('</root>.Name', 'root', r.Name);

  r.Read;
  TestContext.AssertTrue(r.EOF, 'end.EOF');
  TestContext.AssertTrue((ntNone)=(r.NodeType), 'end.NodeType');
end;

procedure TXMLReaderTest.Read;
begin
  DoTest(xml1, @TestRead);
end;

procedure TXMLReaderTest.TestReadAttributeValue(r: TXMLReader);
begin
  r.Read;       // root
  TestContext.AssertTrue(r.MoveToFirstAttribute, '#1');
  AssertNodeValues('#2', r,
    ntAttribute,
    1, 'attr', '', 'attr', '', 'value', true, 1, true);
  TestContext.AssertTrue(r.ReadAttributeValue, '#3');
  AssertNodeValues('#4', r,
    ntText,
    2, '', '', '', '', 'value', true, 1, true);
  TestContext.AssertTrue(r.MoveToElement, '#5');
  AssertNodeValues('#6', r,
    ntElement,
    0, 'root', '', 'root', '', '', false, 1, true);
end;

procedure TXMLReaderTest.ReadAttributeValue;
begin
  DoTest('<root attr="value"/>', @TestReadAttributeValue);
end;

procedure TXMLReaderTest.TestReadAttributeValue2(r: TXMLReader);
begin
  r.Read;       // DTD
  r.Read;       // root
  TestContext.AssertTrue(r.MoveToFirstAttribute, '#1');
  AssertNodeValues('#2', r,
    ntAttribute,
    1, 'attr', '', 'attr', '', 'ax1y1x1b', true, 1, true);
  TestContext.AssertTrue(r.ReadAttributeValue, '#3');
  AssertNodeValues('#4', r,
    ntText, 2,
    '', '', '', '', 'a', true, 1, true);

  TestContext.AssertTrue(r.ReadAttributeValue, '#5');
  AssertNodeValues('#6', r,
    ntEntityReference, 2,
    'e1','','e1','', '', false, 1, true);

  r.ResolveEntity;
  TestContext.AssertTrue((2)=(r.Depth), '#6a');
  TestContext.AssertTrue((ntEntityReference)=(r.nodeType), '#6b');

  TestContext.AssertTrue(r.ReadAttributeValue, '#6c');
  AssertNodeValues('#6d', r,
    ntEntityReference, 3,
    'e2', '', 'e2', '', '', false, 1, true);

  // Don't resolve it and advance to 'y1' textnode
  TestContext.AssertTrue(r.ReadAttributeValue, '#6e');
  AssertNodeValues('#6f', r,
    ntText, 3,
    '', '', '', '', 'y1', true, 1, true);

  TestContext.AssertTrue(r.ReadAttributeValue, '#6g');
  AssertNodeValues('#6h', r,
    ntEntityReference, 3,
    'e2', '', 'e2', '', '', false, 1, true);

  r.ResolveEntity;

  TestContext.AssertTrue(r.ReadAttributeValue, '#6i');
  AssertNodeValues('#6j', r,
    ntText, 4,
    '','','','','x1', true, 1, true);

  TestContext.AssertTrue(r.ReadAttributeValue, '#6k');
  AssertNodeValues('#6l', r,
    ntEndEntity, 3,
    'e2','','e2','', '', false, 1, true);

  TestContext.AssertTrue(r.ReadAttributeValue, '#7');
  AssertNodeValues('#8', r,
    ntEndEntity, 2,
    'e1','','e1','', '', false, 1, true);

  TestContext.AssertTrue(r.ReadAttributeValue, '#9');

  AssertNodeValues('#10', r,
    ntText, 2,
    '', '', '', '', 'b', true, 1, true);
  TestContext.AssertTrue(not (r.ReadAttributeValue), '#11');

  TestContext.AssertTrue(r.MoveToElement, '#12');
  AssertNodeValues('#13', r,
    ntElement, 0,
    'root', '', 'root', '', '', false, 1, true);

end;

procedure TXMLReaderTest.ReadAttributeValue2;
const
  xml = '<!DOCTYPE root ['+
        '<!ELEMENT root ANY>'+
        '<!ENTITY e2 "x1">'+
        '<!ENTITY e1 "&e2;y1&e2;">]>'+
        '<root attr="a&e1;b"/>';
begin
  DoTest(xml, @TestReadAttributeValue2);
end;

procedure TXMLReaderTest.TestDTDProperties(r: TXMLReader);
begin
  r.Read;
  AssertNodeValues('#DTD',r,
    ntDocumentType, 0,
    'root', '', 'root', '', '<!ELEMENT root ANY><!ENTITY e2 "x1"><!ENTITY e1 "&e2;y1&e2;">', True, 0, False);
  r.Read;
  AssertNodeValues('#root',r,
    ntElement, 0,
    'root','', 'root', '', '', False,
    1, True);
end;

procedure TXMLReaderTest.DTDProperties;
const
  xml = '<!DOCTYPE root ['+
        '<!ELEMENT root ANY>'+
        '<!ENTITY e2 "x1">'+
        '<!ENTITY e1 "&e2;y1&e2;">]>'+
        '<root attr="a&e1;b"/>';
begin
  DoTest(xml, @TestDTDProperties);
end;

procedure TXMLReaderTest.TestReadStringFromElement(r: TXMLReader);
var
  s: XMLString;
begin
  r.Read;
  s := r.ReadString;
  AssertEqualsW('readString.1.ret_val', '  test of ', s);
  AssertEqualsW('readString.1.Name', 'b', r.Name);
  s := r.ReadString;
  AssertEqualsW('readString.2.ret_val', 'mixed', s);
  TestContext.AssertTrue((ntEndElement)=(r.NodeType), 'readString.2.nodeType');
  s := r.ReadString; // does not advance
  AssertEqualsW('readString.3.ret_val', '',s);
  TestContext.AssertTrue((ntEndElement)=(r.NodeType), 'readString.3.nodeType');
  r.Read;
  TestContext.AssertTrue((ntText)=(r.NodeType), 'readString.4.nodeType');
  AssertEqualsW('readString.4.Value', ' string.', r.Value);
  s := r.ReadString;
  AssertEqualsW('readString.5.ret_val', ' string. cdata string.', s);
  TestContext.AssertTrue((ntEndElement)=(r.NodeType), 'readString.5.nodeType');
end;

procedure TXMLReaderTest.ReadStringFromElement;
begin
  DoTest(xml3, @TestReadStringFromElement);
end;

procedure TXMLReaderTest.TestEmptyElement(r: TXMLReader);
begin
  AssertStartDocument(r);
  AssertNode('#1', r, ntElement, 0,
    'foo', '', 'foo', '', // name, prefix, localname, nsuri
    '', 0);
  AssertNode('#2', r, ntEndElement, 0,
    'foo', '', 'foo', '',
    '', 0);
  AssertEndDocument(r);
end;

procedure TXMLReaderTest.EmptyElement;
begin
  DoTest('<foo/>', @TestEmptyElement);
end;

procedure TXMLReaderTest.TestNestedEmptyTag(r: TXMLReader);
begin
  AssertStartDocument(r);
  AssertNode('#1', r,
    ntElement, 0,
    'foo', '', 'foo', '',
    '', 0);
  AssertNode('#2', r,
    ntElement, 1,
    'bar', '', 'bar', '',
    '', 0);
  AssertNode('#3', r,
    ntEndElement, 1,
    'bar', '', 'bar', '',
    '', 0);
  AssertNode('#4', r,
    ntEndElement, 0,
    'foo', '', 'foo', '',
    '', 0);
  AssertEndDocument(r);
end;

procedure TXMLReaderTest.NestedEmptyTag;
begin
  DoTest('<foo><bar/></foo>', @TestNestedEmptyTag);
end;

procedure TXMLReaderTest.TestNestedText(r: TXMLReader);
begin
  AssertStartDocument(r);
  AssertNode('#1', r,
    ntElement, 0,
    'foo', '', 'foo', '',
    '', 0);
  AssertNode('#2', r,
    ntText, 1,
    '', '', '', '',
    'bar', 0);
  AssertNode('#3', r,
    ntEndElement, 0,
    'foo', '', 'foo', '',
    '', 0);
  AssertEndDocument(r);
end;

procedure TXMLReaderTest.NestedText;
begin
  DoTest('<foo>bar</foo>', @TestNestedText);
end;

procedure TXMLReaderTest.TestEmptyElementWithAttributes(r: TXMLReader);
begin
  AssertStartDocument(r);
  AssertNode('#1', r,
    ntElement, 0,
    'foo', '', 'foo', '',
    '', 4);
  AssertAttribute(r,
    'bar', '', 'bar', '',
    'baz');
  AssertAttribute(r,
    'quux', '', 'quux', '',
    'quuux');
  AssertAttribute(r,                    // non-existing attribute
    'notexist', '', 'notexist', '',
    '');
  AssertAttribute(r,                    // non-existing prefixed attribute
    'x:bar', 'x', 'bar', 'urn:xfoo',
    '');
  AssertAttribute(r,
    'x:foo', 'x', 'foo', 'urn:xfoo',
    'x-foo');
  AssertNode('#2', r,
    ntEndElement, 0,
    'foo', '', 'foo', '',
    '', 0);
  AssertEndDocument(r);
end;

procedure TXMLReaderTest.EmptyElementWithAttributes;
begin
  DoTest('<foo bar="baz" quux=''quuux'' x:foo=''x-foo'' xmlns:x = ''urn:xfoo'' />',
    @TestEmptyElementWithAttributes);
end;

procedure TXMLReaderTest.TestPIBeforeRoot(r: TXMLReader);
begin
  AssertStartDocument(r);
  AssertNode('#1', r,
    ntProcessingInstruction, 0,
    'foo', '', 'foo', '',
    'bar', 0);
  AssertNode('#2', r,
    ntElement, 0,
    'baz', '', 'baz', '',
    '', 0);
  AssertNode('#3', r,
    ntEndElement, 0,
    'baz', '', 'baz', '',
    '', 0);
  AssertEndDocument(r);
end;

procedure TXMLReaderTest.PIBeforeRoot;
begin
  DoTest('<?foo bar?><baz/>', @TestPIBeforeRoot);
end;

procedure TXMLReaderTest.TestCommentBeforeRoot(r: TXMLReader);
begin
  AssertStartDocument(r);
  AssertNode('#1', r,
    ntComment, 0,
    '','','','',
    'foo', 0);
  AssertNode('#2', r,
    ntElement, 0,
    'bar', '', 'bar', '',
    '', 0);
  AssertNode('#3', r,
    ntEndElement, 0,
    'bar', '', 'bar', '',
    '', 0);
  AssertEndDocument(r);
end;

procedure TXMLReaderTest.CommentBeforeRoot;
begin
  DoTest('<!--foo--><bar/>', @TestCommentBeforeRoot);
end;

procedure TXMLReaderTest.TestCDATA(r: TXMLReader);
begin
  AssertStartDocument(r);
  AssertNode('#1', r,
   ntElement, 0,
   'foo', '', 'foo', '',
   '', 0);
  AssertNode('#2', r,
    ntCDATA, 1,
    '','','','',
    '<>&', 0);
  AssertNode('#3', r,
    ntEndElement, 0,
    'foo', '', 'foo', '',
    '',0);
  AssertEndDocument(r);
end;

procedure TXMLReaderTest.CDATA;
begin
  DoTest('<foo><![CDATA[<>&]]></foo>', @TestCDATA);
end;

procedure TXMLReaderTest.ChildElementInNamespace;
begin
  DoTest('<foo:bar xmlns:foo=''http://foo/''><baz:quux xmlns:baz=''http://baz/'' /></foo:bar>', @TestChildElementInNamespace);
end;

procedure TXMLReaderTest.TestChildElementInNamespace(r: TXMLReader);
begin
  AssertStartDocument(r);

  AssertNode('#1', r,
    ntElement, 0,
    'foo:bar', 'foo', 'bar', 'http://foo/',
    '', 1);

  AssertAttribute(r,
    'xmlns:foo', 'xmlns', 'foo', 'http://www.w3.org/2000/xmlns/',
    'http://foo/');

  AssertEqualsW('http://foo/', r.LookupNamespace('foo'));

  AssertNode('#2', r,
    ntElement, 1,
    'baz:quux', 'baz', 'quux', 'http://baz/',
    '', 1);

  AssertAttribute(r,
    'xmlns:baz', 'xmlns', 'baz', 'http://www.w3.org/2000/xmlns/',
    'http://baz/');

  AssertEqualsW('http://foo/', r.LookupNamespace ('foo'));
  AssertEqualsW('http://baz/', r.LookupNamespace ('baz'));

  AssertNode('#3', r,
    ntEndElement, 1,
    'baz:quux', 'baz', 'quux', 'http://baz/',
    '', 0);

  AssertNode('#4', r,
    ntEndElement, 0,
    'foo:bar', 'foo', 'bar', 'http://foo/',
    '', 0);

  AssertEqualsW('http://foo/', r.LookupNamespace('foo'));
  TestContext.AssertTrue(r.LookupNamespace('baz')='', '');

  AssertEndDocument(r);
end;

procedure TXMLReaderTest.TestMoveToElementFromAttribute(r: TXMLReader);
begin
  TestContext.AssertTrue(r.Read, '');
  TestContext.AssertTrue((ntElement)=(r.NodeType), '');
  TestContext.AssertTrue(r.MoveToFirstAttribute, '');
  TestContext.AssertTrue((ntAttribute)=(r.NodeType), '');
  TestContext.AssertTrue(r.MoveToElement, '');
  TestContext.AssertTrue((ntElement)=(r.NodeType), '');
end;

procedure TXMLReaderTest.MoveToElementFromAttribute;
begin
  DoTest('<foo bar="baz" />', @TestMoveToElementFromAttribute);
end;

procedure TXMLReaderTest.TestMoveToElementFromElement(r: TXMLReader);
begin
  TestContext.AssertTrue(r.Read, '');
  TestContext.AssertTrue((ntElement)=(r.NodeType), '');
  TestContext.AssertTrue(not (r.MoveToElement), '');
  TestContext.AssertTrue((ntElement)=(r.NodeType), '');
end;

procedure TXMLReaderTest.MoveToElementFromElement;
begin
  DoTest('<foo bar="baz" />', @TestMoveToElementFromElement);
end;

// TODO: moveToFirstAttribute_negative
//       moveToNextAttribute_negative

procedure TXMLReaderTest.TestMoveToNextAttribute(r: TXMLReader);
begin
  AssertStartDocument(r);
  AssertNode('#1', r,
    ntElement, 0,
    'foo', '', 'foo', '',
    '', 2);
  AssertAttribute(r,
    'bar', '', 'bar', '',
    'baz');
  AssertAttribute(r,
    'quux', '', 'quux', '',
    'quuux');
  TestContext.AssertTrue(r.MoveToNextAttribute, '');
  AssertEqualsW('bar', r.Name);
  AssertEqualsW('baz', r.Value);
  TestContext.AssertTrue(r.MoveToNextAttribute, '');
  AssertEqualsW('quux', r.Name);
  AssertEqualsW('quuux', r.Value);
  TestContext.AssertTrue(not (r.MoveToNextAttribute), '');
  TestContext.AssertTrue(r.MoveToElement, '');
  AssertNodeValues('#1', r,
    ntElement, 0,
    'foo','','foo','',
    '', False, 2, True);
  AssertNode('#2', r,
    ntEndElement, 0,
    'foo','','foo','',
    '', 0);
  AssertEndDocument(r);
end;

procedure TXMLReaderTest.MoveToNextAttribute;
begin
  DoTest('<foo bar="baz" quux=''quuux''/>', @TestMoveToNextAttribute);
end;

procedure TXMLReaderTest.TestResolveEntity(r: TXMLReader);
begin
  r.Read;       // DTD
  r.Read;       // root
  r.Read;       // &ent;
  TestContext.AssertTrue((ntEntityReference)=(r.NodeType), '#1');
  TestContext.AssertTrue((1)=(r.Depth), '#2');
  r.ResolveEntity;
  // stays on entity reference
  TestContext.AssertTrue((ntEntityReference)=(r.NodeType), '#3');
  TestContext.AssertTrue((1)=(r.Depth), '#3a');
  r.Read;
  // now advances to replacement text
  TestContext.AssertTrue((ntText)=(r.NodeType), '#4');
  TestContext.AssertTrue((2)=(r.Depth), '#5');
  AssertEqualsW('#6', 'entity string', r.Value);
  r.Read;
  TestContext.AssertTrue((ntEndEntity)=(r.NodeType), '#7');
  TestContext.AssertTrue((1)=(r.Depth), '#8');
  AssertEqualsW('#9', '', r.Value);

  r.Read;     // &ent2;
  TestContext.AssertTrue((ntEntityReference)=(r.NodeType), '#10');
  TestContext.AssertTrue((1)=(r.Depth), '#11');
  r.ResolveEntity;
  // stays on entity reference
  TestContext.AssertTrue((ntEntityReference)=(r.NodeType), '#12');
  TestContext.AssertTrue((1)=(r.Depth), '#12a');
  // now advances to element node
  r.Read;
  TestContext.AssertTrue((ntElement)=(r.NodeType), '#13');
  TestContext.AssertTrue((2)=(r.Depth), '#14');
end;

procedure TXMLReaderTest.ResolveEntity;
const
  xml='<!DOCTYPE root [<!ELEMENT root (#PCDATA|foo)*>'+
      '<!ENTITY ent "entity string">'+
      '<!ENTITY ent2 "<foo/><foo/>">]>'+
      '<root>&ent;&ent2;</root>';
begin
  DoTest(xml, @TestResolveEntity);
end;

procedure TXMLReaderTest.TestLineInfo(r: TXMLReader);
var
  aux: IXmlLineInfo;
begin
  if not Supports(r, IXmlLineInfo, aux) then
    Exit;
  TestContext.AssertTrue((0)=(aux.LineNumber), '#1a');
  TestContext.AssertTrue((0)=(aux.LinePosition), '#1b');
  r.MoveToContent;
  TestContext.AssertTrue((1)=(aux.LineNumber), '#2a');
  TestContext.AssertTrue((2)=(aux.LinePosition), '#2b');
  r.Read;
  TestContext.AssertTrue((1)=(aux.LineNumber), '#3a');
  TestContext.AssertTrue((7)=(aux.LinePosition), '#3b');
  r.Read;
  r.Read;
//  r.ReadOuterXml;
  TestContext.AssertTrue((1)=(aux.LineNumber), '#4a');
  TestContext.AssertTrue((22)=(aux.LinePosition), '#4b');
  r.Read;
  r.Read;
//  r.ReadInnerXml;
  TestContext.AssertTrue((1)=(aux.LineNumber), '#5a');
  TestContext.AssertTrue((34)=(aux.LinePosition), '#5b');
  r.Read;     { now at EOF }
  TestContext.AssertTrue((1)=(aux.LineNumber), '#6a');
  TestContext.AssertTrue((38)=(aux.LinePosition), '#6b');
  r.Close;
  TestContext.AssertTrue((0)=(aux.LineNumber), '#7a');
  TestContext.AssertTrue((0)=(aux.LinePosition), '#7b');
end;

procedure TXMLReaderTest.LineInfo;
begin
  DoTest('<all><hello></hello><bug></bug></all>', @TestLineInfo);
end;


procedure RunTXMLReaderTestInitialState(AContext: TNXTestContext);
var lFixture: TXMLReaderTest;
begin
  lFixture:=TXMLReaderTest.Create(AContext, 'InitialState');
  try
    lFixture.InitialState;
  finally lFixture.Free; end;
end;

procedure RunTXMLReaderTestReadEmptySource(AContext: TNXTestContext);
var lFixture: TXMLReaderTest;
begin
  lFixture:=TXMLReaderTest.Create(AContext, 'ReadEmptySource');
  try
    lFixture.ReadEmptySource;
  finally lFixture.Free; end;
end;

procedure RunTXMLReaderTestRead(AContext: TNXTestContext);
var lFixture: TXMLReaderTest;
begin
  lFixture:=TXMLReaderTest.Create(AContext, 'Read');
  try
    lFixture.Read;
  finally lFixture.Free; end;
end;

procedure RunTXMLReaderTestReadAttributeValue(AContext: TNXTestContext);
var lFixture: TXMLReaderTest;
begin
  lFixture:=TXMLReaderTest.Create(AContext, 'ReadAttributeValue');
  try
    lFixture.ReadAttributeValue;
  finally lFixture.Free; end;
end;

procedure RunTXMLReaderTestReadAttributeValue2(AContext: TNXTestContext);
var lFixture: TXMLReaderTest;
begin
  lFixture:=TXMLReaderTest.Create(AContext, 'ReadAttributeValue2');
  try
    lFixture.ReadAttributeValue2;
  finally lFixture.Free; end;
end;

procedure RunTXMLReaderTestDTDProperties(AContext: TNXTestContext);
var lFixture: TXMLReaderTest;
begin
  lFixture:=TXMLReaderTest.Create(AContext, 'DTDProperties');
  try
    lFixture.DTDProperties;
  finally lFixture.Free; end;
end;

procedure RunTXMLReaderTestReadStringFromElement(AContext: TNXTestContext);
var lFixture: TXMLReaderTest;
begin
  lFixture:=TXMLReaderTest.Create(AContext, 'ReadStringFromElement');
  try
    lFixture.ReadStringFromElement;
  finally lFixture.Free; end;
end;

procedure RunTXMLReaderTestEmptyElement(AContext: TNXTestContext);
var lFixture: TXMLReaderTest;
begin
  lFixture:=TXMLReaderTest.Create(AContext, 'EmptyElement');
  try
    lFixture.EmptyElement;
  finally lFixture.Free; end;
end;

procedure RunTXMLReaderTestNestedEmptyTag(AContext: TNXTestContext);
var lFixture: TXMLReaderTest;
begin
  lFixture:=TXMLReaderTest.Create(AContext, 'NestedEmptyTag');
  try
    lFixture.NestedEmptyTag;
  finally lFixture.Free; end;
end;

procedure RunTXMLReaderTestNestedText(AContext: TNXTestContext);
var lFixture: TXMLReaderTest;
begin
  lFixture:=TXMLReaderTest.Create(AContext, 'NestedText');
  try
    lFixture.NestedText;
  finally lFixture.Free; end;
end;

procedure RunTXMLReaderTestEmptyElementWithAttributes(AContext: TNXTestContext);
var lFixture: TXMLReaderTest;
begin
  lFixture:=TXMLReaderTest.Create(AContext, 'EmptyElementWithAttributes');
  try
    lFixture.EmptyElementWithAttributes;
  finally lFixture.Free; end;
end;

procedure RunTXMLReaderTestPIBeforeRoot(AContext: TNXTestContext);
var lFixture: TXMLReaderTest;
begin
  lFixture:=TXMLReaderTest.Create(AContext, 'PIBeforeRoot');
  try
    lFixture.PIBeforeRoot;
  finally lFixture.Free; end;
end;

procedure RunTXMLReaderTestCommentBeforeRoot(AContext: TNXTestContext);
var lFixture: TXMLReaderTest;
begin
  lFixture:=TXMLReaderTest.Create(AContext, 'CommentBeforeRoot');
  try
    lFixture.CommentBeforeRoot;
  finally lFixture.Free; end;
end;

procedure RunTXMLReaderTestCDATA(AContext: TNXTestContext);
var lFixture: TXMLReaderTest;
begin
  lFixture:=TXMLReaderTest.Create(AContext, 'CDATA');
  try
    lFixture.CDATA;
  finally lFixture.Free; end;
end;

procedure RunTXMLReaderTestChildElementInNamespace(AContext: TNXTestContext);
var lFixture: TXMLReaderTest;
begin
  lFixture:=TXMLReaderTest.Create(AContext, 'ChildElementInNamespace');
  try
    lFixture.ChildElementInNamespace;
  finally lFixture.Free; end;
end;

procedure RunTXMLReaderTestMoveToElementFromAttribute(AContext: TNXTestContext);
var lFixture: TXMLReaderTest;
begin
  lFixture:=TXMLReaderTest.Create(AContext, 'MoveToElementFromAttribute');
  try
    lFixture.MoveToElementFromAttribute;
  finally lFixture.Free; end;
end;

procedure RunTXMLReaderTestMoveToElementFromElement(AContext: TNXTestContext);
var lFixture: TXMLReaderTest;
begin
  lFixture:=TXMLReaderTest.Create(AContext, 'MoveToElementFromElement');
  try
    lFixture.MoveToElementFromElement;
  finally lFixture.Free; end;
end;

procedure RunTXMLReaderTestMoveToNextAttribute(AContext: TNXTestContext);
var lFixture: TXMLReaderTest;
begin
  lFixture:=TXMLReaderTest.Create(AContext, 'MoveToNextAttribute');
  try
    lFixture.MoveToNextAttribute;
  finally lFixture.Free; end;
end;

procedure RunTXMLReaderTestResolveEntity(AContext: TNXTestContext);
var lFixture: TXMLReaderTest;
begin
  lFixture:=TXMLReaderTest.Create(AContext, 'ResolveEntity');
  try
    lFixture.ResolveEntity;
  finally lFixture.Free; end;
end;

procedure RunTXMLReaderTestLineInfo(AContext: TNXTestContext);
var lFixture: TXMLReaderTest;
begin
  lFixture:=TXMLReaderTest.Create(AContext, 'LineInfo');
  try
    lFixture.LineInfo;
  finally lFixture.Free; end;
end;

procedure RegisterreadertestTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('readertest.TXMLReaderTest');
  lSuite.AddTest('InitialState', @RunTXMLReaderTestInitialState);
  lSuite.AddTest('ReadEmptySource', @RunTXMLReaderTestReadEmptySource);
  lSuite.AddTest('Read', @RunTXMLReaderTestRead);
  lSuite.AddTest('ReadAttributeValue', @RunTXMLReaderTestReadAttributeValue);
  lSuite.AddTest('ReadAttributeValue2', @RunTXMLReaderTestReadAttributeValue2);
  lSuite.AddTest('DTDProperties', @RunTXMLReaderTestDTDProperties);
  lSuite.AddTest('ReadStringFromElement', @RunTXMLReaderTestReadStringFromElement);
  lSuite.AddTest('EmptyElement', @RunTXMLReaderTestEmptyElement);
  lSuite.AddTest('NestedEmptyTag', @RunTXMLReaderTestNestedEmptyTag);
  lSuite.AddTest('NestedText', @RunTXMLReaderTestNestedText);
  lSuite.AddTest('EmptyElementWithAttributes', @RunTXMLReaderTestEmptyElementWithAttributes);
  lSuite.AddTest('PIBeforeRoot', @RunTXMLReaderTestPIBeforeRoot);
  lSuite.AddTest('CommentBeforeRoot', @RunTXMLReaderTestCommentBeforeRoot);
  lSuite.AddTest('CDATA', @RunTXMLReaderTestCDATA);
  lSuite.AddTest('ChildElementInNamespace', @RunTXMLReaderTestChildElementInNamespace);
  lSuite.AddTest('MoveToElementFromAttribute', @RunTXMLReaderTestMoveToElementFromAttribute);
  lSuite.AddTest('MoveToElementFromElement', @RunTXMLReaderTestMoveToElementFromElement);
  lSuite.AddTest('MoveToNextAttribute', @RunTXMLReaderTestMoveToNextAttribute);
  lSuite.AddTest('ResolveEntity', @RunTXMLReaderTestResolveEntity);
  lSuite.AddTest('LineInfo', @RunTXMLReaderTestLineInfo);
end;

end.

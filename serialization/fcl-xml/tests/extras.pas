{**********************************************************************

    This file is part of the Free Component Library (FCL)

    DOM Test cases which are missing from w3.org test suite
    Copyright (c) 2008 by Sergei Gorelkin, sergei_gorelkin@mail.ru

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
unit extras;
{$mode objfpc}{$H+}
interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, SysUtils, Classes, DOM, xmlread, xmlwrite, domunit;

procedure RegisterextrasTests(ARegistry: TNXTestRegistry);

implementation

type
  TDOMTestExtra = class(TDOMTestBase)
  public
    procedure attr_ownership01;
    procedure attr_ownership02;
    procedure attr_ownership03;
    procedure attr_ownership04;
    procedure attr_ownership05;
    procedure replacesamechild;
    procedure insertbeforefirst;
    procedure nsFixup1;
    procedure nsFixup2;
    procedure nsFixup3;
  end;

{ TDOMTestExtra }

// verify that an attribute created by Element.SetAttribute()
// has its OwnerElement assigned properly
procedure TDOMTestExtra.attr_ownership01;
var
  doc: TDOMDocument;
  el: TDOMElement;
  attr: TDOMAttr;
  attrOwner: TDOMElement;
begin
  LoadStringData(doc, '<doc/>');
  el := doc.CreateElement('element1');
  el.SetAttribute('newAttr', 'newValue');
  attr := el.GetAttributeNode('newAttr');
  FContext.AssertTrue((attr)<>nil, 'attribute');
  attrOwner := attr.OwnerElement;
  FContext.AssertTrue((el)=(attrOwner), 'ownerElement');
  FContext.AssertTrue(attr.Specified, 'specified');
end;

// verify that an attribute created by Element.SetAttributeNS()
// has its OwnerElement assigned properly
procedure TDOMTestExtra.attr_ownership02;
var
  doc: TDOMDocument;
  el: TDOMElement;
  attr: TDOMAttr;
  attrOwner: TDOMElement;
begin
  LoadStringData(doc, '<doc/>');
  el := doc.CreateElement('element1');
  el.SetAttributeNS('http://www.freepascal.org', 'fpc:newAttr', 'newValue');
  attr := el.GetAttributeNodeNS('http://www.freepascal.org', 'newAttr');
  FContext.AssertTrue((attr)<>nil, 'attribute');
  attrOwner := attr.OwnerElement;
  FContext.AssertTrue((el)=(attrOwner), 'ownerElement');
  FContext.AssertTrue(attr.Specified, 'specified');
end;

// verify that NamedNodeMap.SetNamedItem() resets OwnerElement
// of the attribute being replaced
procedure TDOMTestExtra.attr_ownership03;
var
  doc: TDOMDocument;
  el: TDOMElement;
  attr, attr2: TDOMAttr;
  retNode: TDOMNode;
begin
  LoadStringData(doc, '<doc/>');
  el := doc.CreateElement('element1');
  attr := doc.CreateAttribute('newAttr');
  el.SetAttributeNode(attr);
  FContext.AssertTrue((el)=(attr.OwnerElement), 'ownerElement_before');
  attr2 := doc.CreateAttribute('newAttr');
  retNode := el.Attributes.SetNamedItem(attr2);
  FContext.AssertTrue((attr)=(retNode), 'retNode');
  FContext.AssertTrue((attr.OwnerElement)=nil, 'ownerElement_after');
  FContext.AssertTrue((el)=(attr2.OwnerElement), 'ownerElement2');
end;

// verify that NamedNodeMap.SetNamedItemNS() resets OwnerElement
// of the attribute being replaced
procedure TDOMTestExtra.attr_ownership04;
var
  doc: TDOMDocument;
  el: TDOMElement;
  attr, attr2: TDOMAttr;
  retNode: TDOMNode;
begin
  LoadStringData(doc, '<doc/>');
  el := doc.CreateElement('element1');
  attr := doc.CreateAttributeNS('http://www.freepascal.org', 'fpc:newAttr');
  el.SetAttributeNodeNS(attr);
  FContext.AssertTrue((el)=(attr.OwnerElement), 'ownerElement_before');
  attr2 := doc.CreateAttributeNS('http://www.freepascal.org', 'fpc:newAttr');
  retNode := el.Attributes.SetNamedItemNS(attr2);
  FContext.AssertTrue((attr)=(retNode), 'retNode');
  FContext.AssertTrue((attr.OwnerElement)=nil, 'ownerElement_after');
  FContext.AssertTrue((el)=(attr2.OwnerElement), 'ownerElement2');
end;


// verify that Element.removeAttributeNode() resets ownerElement
// of the attribute being removed
procedure TDOMTestExtra.attr_ownership05;
var
  doc: TDOMDocument;
  el: TDOMElement;
  attr: TDOMAttr;
begin
  LoadStringData(doc, '<doc/>');
  el := doc.CreateElement('element1');
  attr := doc.CreateAttributeNS('http://www.freepascal.org', 'fpc:newAttr');
  el.SetAttributeNodeNS(attr);
  FContext.AssertTrue((el)=(attr.OwnerElement), 'ownerElement_before');
  el.RemoveAttributeNode(attr);
  FContext.AssertTrue((attr.ownerElement)=nil, 'ownerElement_after');
end;

// verify that replacing a node by itself does not remove it from the tree
// (specs say this is implementation-dependent, but guess that means either
//  no-op or raising an exception, not removal).
procedure TDOMTestExtra.replacesamechild;
var
  doc: TDOMDocument;
  root, el, prev, next: TDOMNode;
begin
  LoadStringData(doc, '<root><child1/><child2/><child3/></root>');
  root := doc.DocumentElement;
  el := root.ChildNodes[1];
  prev := el.PreviousSibling;
  next := el.NextSibling;
  AssertEqualsW('prev_name_before', 'child1', prev.NodeName);
  AssertEqualsW('next_name_before', 'child3', next.NodeName);
  root.replaceChild(el, el);
  prev := el.PreviousSibling;
  next := el.NextSibling;
  FContext.AssertTrue((prev)<>nil, 'prev_after');
  FContext.AssertTrue((next)<>nil, 'prev_after');
  AssertEqualsW('prev_name_after', 'child1', prev.NodeName);
  AssertEqualsW('next_name_after', 'child3', next.NodeName);
end;

// verify that inserting a node before the first child sets
// both refnode.previoussibling and newnode.nextsibling properties
procedure TDOMTestExtra.insertbeforefirst;
var
  doc: TDOMDocument;
  root, refchild, newchild: TDOMNode;
begin
  LoadStringData(doc, '<root><child1/><child2/><child3/></root>');
  root := doc.DocumentElement;
  refchild := root.FirstChild;
  newchild := doc.CreateElement('new');
  root.insertbefore(newchild, refchild);
  FContext.AssertTrue((refchild.previoussibling)=(newchild), 'prev');
  FContext.AssertTrue((newchild.nextsibling)=(refchild), 'next');
  FContext.AssertTrue((root.firstchild)=(newchild), 'child');
end;

const
  nsURI1 = 'http://www.example.com/ns1';
  nsURI2 = 'http://www.example.com/ns2';

// verify the namespace fixup with two nested elements
// (same localName, different nsURI, and no prefixes)
procedure TDOMTestExtra.nsFixup1;
var
  domImpl: TDOMImplementation;
  origDoc: TDOMDocument;
  parsedDoc: TDOMDocument;
  docElem: TDOMElement;
  el: TDOMElement;
  stream: TStringStream;
  list: TDOMNodeList;
begin
  FParser.Options.Namespaces := True;
  domImpl := GetImplementation;
  origDoc := domImpl.createDocument(nsURI1, 'test', nil);
  GC(origDoc);
  docElem := origDoc.documentElement;
  el := origDoc.CreateElementNS(nsURI2, 'test');
  docElem.AppendChild(el);

  stream := TStringStream.Create('');
  GC(stream);
  writeXML(origDoc, stream);
  LoadStringData(parsedDoc, stream.DataString);

  docElem := parsedDoc.documentElement;
  assertEqualsW('docElemLocalName', 'test', docElem.localName);
  assertEqualsW('docElemNS', nsURI1, docElem.namespaceURI);

  list := docElem.GetElementsByTagNameNS(nsURI2, '*');
  FContext.AssertTrue((1)=(list.Length), 'ns2_elementCount');
  el := TDOMElement(list[0]);
  assertEqualsW('ns2_nodeName', 'test', el.nodeName);
end;

// verify the namespace fixup with two nested elements
// (same localName, different nsURI, different prefixes)
procedure TDOMTestExtra.nsFixup2;
var
  domImpl: TDOMImplementation;
  origDoc: TDOMDocument;
  parsedDoc: TDOMDocument;
  docElem: TDOMElement;
  el: TDOMElement;
  stream: TStringStream;
  list: TDOMNodeList;
begin
  FParser.Options.Namespaces := True;
  domImpl := GetImplementation;
  origDoc := domImpl.createDocument(nsURI1, 'a:test', nil);
  GC(origDoc);
  docElem := origDoc.documentElement;
  el := origDoc.CreateElementNS(nsURI2, 'b:test');
  docElem.AppendChild(el);

  stream := TStringStream.Create('');
  GC(stream);
  writeXML(origDoc, stream);
  LoadStringData(parsedDoc, stream.DataString);

  docElem := parsedDoc.documentElement;
  assertEqualsW('docElemLocalName', 'test', docElem.localName);
  assertEqualsW('docElemNS', nsURI1, docElem.namespaceURI);

  list := docElem.GetElementsByTagNameNS(nsURI2, '*');
  FContext.AssertTrue((1)=(list.Length), 'ns2_elementCount');
  el := TDOMElement(list[0]);
  assertEqualsW('ns2_nodeName', 'b:test', el.nodeName);
end;

// verify the namespace fixup with two nested elements and an attribute
// attribute's prefix must change to that of document element
procedure TDOMTestExtra.nsFixup3;
var
  domImpl: TDOMImplementation;
  origDoc: TDOMDocument;
  parsedDoc: TDOMDocument;
  docElem: TDOMElement;
  el: TDOMElement;
  stream: TStringStream;
  list: TDOMNodeList;
  attr: TDOMAttr;
begin
  FParser.Options.Namespaces := True;
  domImpl := GetImplementation;
  origDoc := domImpl.createDocument(nsURI1, 'a:test', nil);
  GC(origDoc);
  docElem := origDoc.documentElement;
  el := origDoc.CreateElementNS(nsURI2, 'b:test');
  docElem.AppendChild(el);
  el.SetAttributeNS(nsURI1, 'test:attr', 'test value');

  stream := TStringStream.Create('');
  GC(stream);
  writeXML(origDoc, stream);
  LoadStringData(parsedDoc, stream.DataString);

  docElem := parsedDoc.documentElement;
  assertEqualsW('docElemLocalName', 'test', docElem.localName);
  assertEqualsW('docElemNS', nsURI1, docElem.namespaceURI);

  list := docElem.GetElementsByTagNameNS(nsURI2, '*');
  FContext.AssertTrue((1)=(list.Length), 'ns2_elementCount');
  el := TDOMElement(list[0]);
  attr := el.GetAttributeNodeNS(nsURI1, 'attr');
  assertEqualsW('attr_nodeName', 'a:attr', attr.nodeName);
end;



procedure RunTDOMTestExtraattr_ownership01(AContext: TNXTestContext);
var lFixture: TDOMTestExtra;
begin
  lFixture:=TDOMTestExtra.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='attr_ownership01';
    lFixture.SetUp;
    try lFixture.attr_ownership01; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTDOMTestExtraattr_ownership02(AContext: TNXTestContext);
var lFixture: TDOMTestExtra;
begin
  lFixture:=TDOMTestExtra.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='attr_ownership02';
    lFixture.SetUp;
    try lFixture.attr_ownership02; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTDOMTestExtraattr_ownership03(AContext: TNXTestContext);
var lFixture: TDOMTestExtra;
begin
  lFixture:=TDOMTestExtra.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='attr_ownership03';
    lFixture.SetUp;
    try lFixture.attr_ownership03; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTDOMTestExtraattr_ownership04(AContext: TNXTestContext);
var lFixture: TDOMTestExtra;
begin
  lFixture:=TDOMTestExtra.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='attr_ownership04';
    lFixture.SetUp;
    try lFixture.attr_ownership04; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTDOMTestExtraattr_ownership05(AContext: TNXTestContext);
var lFixture: TDOMTestExtra;
begin
  lFixture:=TDOMTestExtra.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='attr_ownership05';
    lFixture.SetUp;
    try lFixture.attr_ownership05; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTDOMTestExtrareplacesamechild(AContext: TNXTestContext);
var lFixture: TDOMTestExtra;
begin
  lFixture:=TDOMTestExtra.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='replacesamechild';
    lFixture.SetUp;
    try lFixture.replacesamechild; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTDOMTestExtrainsertbeforefirst(AContext: TNXTestContext);
var lFixture: TDOMTestExtra;
begin
  lFixture:=TDOMTestExtra.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='insertbeforefirst';
    lFixture.SetUp;
    try lFixture.insertbeforefirst; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTDOMTestExtransFixup1(AContext: TNXTestContext);
var lFixture: TDOMTestExtra;
begin
  lFixture:=TDOMTestExtra.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='nsFixup1';
    lFixture.SetUp;
    try lFixture.nsFixup1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTDOMTestExtransFixup2(AContext: TNXTestContext);
var lFixture: TDOMTestExtra;
begin
  lFixture:=TDOMTestExtra.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='nsFixup2';
    lFixture.SetUp;
    try lFixture.nsFixup2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTDOMTestExtransFixup3(AContext: TNXTestContext);
var lFixture: TDOMTestExtra;
begin
  lFixture:=TDOMTestExtra.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='nsFixup3';
    lFixture.SetUp;
    try lFixture.nsFixup3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegisterextrasTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('extras.TDOMTestExtra');
  lSuite.AddTest('attr_ownership01', @RunTDOMTestExtraattr_ownership01);
  lSuite.AddTest('attr_ownership02', @RunTDOMTestExtraattr_ownership02);
  lSuite.AddTest('attr_ownership03', @RunTDOMTestExtraattr_ownership03);
  lSuite.AddTest('attr_ownership04', @RunTDOMTestExtraattr_ownership04);
  lSuite.AddTest('attr_ownership05', @RunTDOMTestExtraattr_ownership05);
  lSuite.AddTest('replacesamechild', @RunTDOMTestExtrareplacesamechild);
  lSuite.AddTest('insertbeforefirst', @RunTDOMTestExtrainsertbeforefirst);
  lSuite.AddTest('nsFixup1', @RunTDOMTestExtransFixup1);
  lSuite.AddTest('nsFixup2', @RunTDOMTestExtransFixup2);
  lSuite.AddTest('nsFixup3', @RunTDOMTestExtransFixup3);
end;

end.

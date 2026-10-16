{**********************************************************************

    This file is part of the Free Component Library (FCL)

    fpcunit extensions for testing TXmlReader class
    Copyright (c) 2008 by Sergei Gorelkin, sergei_gorelkin@mail.ru

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit readerunit;
{$mode objfpc}{$h+}

interface

uses obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, xmlutils, XmlReader;

type
  TTestMethod = procedure(reader: TXMLReader) of object;

  TXMLReaderTestBase = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    procedure AssertStartDocument(r: TXMLReader);
    procedure AssertEndDocument(r: TXMLReader);
    procedure AssertNode(const id: string;
      r: TXMLReader; nodeType: TXMLNodeType;
      depth: Integer;
      const Name, Prefix, LocalName, nsURI, Value: XMLString;
      attrCount: Integer);
    procedure AssertNodeValues(id: string;
      r: TXmlReader;
      nodeType: TXmlNodeType;
      depth: Integer;
      const name, prefix, localName, nsURI, value: XMLString;
      hasValue: Boolean;
      attrCount: Integer;
      hasAttributes: Boolean);
    procedure AssertAttribute(r: TXMLReader;
      const Name, Prefix, LocalName, nsURI, Value: XMLString);
    procedure AssertEquals(const id: string; exp, act: TXMLReadState); overload;
    procedure AssertEquals(exp, act: TXMLReadState); overload;
    procedure AssertEquals(const id: string; exp, act: TXMLNodeType); overload;
    procedure AssertEqualsW(const id: string; const exp, act: XMLString); overload;
    procedure AssertEqualsW(const exp, act: XMLString); overload;
    procedure AssertEquals(exp, act: TXMLNodeType); overload;
    procedure AssertNull(const id: string; const ws: XMLString); overload;
    procedure DoTest(const XmlData: string; method: TTestMethod);
  end;

procedure RegisterreaderunitTests(ARegistry: TNXTestRegistry);

implementation

uses
  xmltextreader;

procedure TXMLReaderTestBase.AssertStartDocument(r: TXMLReader);
begin
  FContext.AssertTrue((r.ReadState)=(rsInitial), '');
  FContext.AssertTrue((r.NodeType)=(ntNone), '');
  FContext.AssertTrue((r.Depth)=(0), '');
  FContext.AssertTrue(not (r.EOF), '');
end;

procedure TXMLReaderTestBase.AssertEndDocument(r: TXMLReader);
begin
  FContext.AssertTrue(not (r.Read), 'could read');
  FContext.AssertTrue((ntNone)=(r.NodeType), 'NodeType is not ntNone');
  FContext.AssertTrue((0)=(r.Depth), 'Depth is not 0');
  FContext.AssertTrue((rsEndOfFile)=(r.ReadState), 'ReadState is not rsEndOfFile');
  FContext.AssertTrue(r.EOF, 'not EOF');
  r.Close;
  FContext.AssertTrue((rsClosed)=(r.ReadState), 'ReadState is not rsClosed');
end;

procedure TXMLReaderTestBase.AssertNode(const id: string;
  r: TXMLReader; nodeType: TXMLNodeType;
  depth: Integer;
  const Name, Prefix, LocalName, nsURI, Value: XMLString;
  attrCount: Integer);
begin
  FContext.AssertTrue(r.Read, id+' Read() return value');
  FContext.AssertTrue((r.ReadState)=(rsInteractive), id+' ReadState');
  FContext.AssertTrue(not (r.EOF), id+' not EOF');
  AssertNodeValues(id, r,  nodeType, depth,
    Name, Prefix, localName,
    nsURI, Value, r.HasValue,
    attrCount, attrCount > 0);
end;

procedure TXMLReaderTestBase.AssertNodeValues(id: string;
  r: TXmlReader;
  nodeType: TXmlNodeType;
  depth: Integer;
  const name, prefix, localName, nsURI, value: XMLString;
  hasValue: Boolean;
  attrCount: Integer;
  hasAttributes: Boolean);
begin
  id := id + '(' + r.ClassName + ')';
  FContext.AssertTrue((nodeType)=(r.NodeType), id+': NodeType');
  AssertEqualsW(id+': name', name, r.Name);

  AssertEqualsW(id+': prefix', prefix, r.Prefix);
  AssertEqualsW(id+': localName', localName, r.LocalName);
  AssertEqualsW(id+': namespaceURI', nsURI, r.NamespaceURI);
  FContext.AssertTrue((depth)=(r.Depth), id+': Depth');
  FContext.AssertTrue((hasValue)=(r.HasValue), id+': hasValue');
  AssertEqualsW(id+': Value', value, r.Value);
// TODO:  AssertEquals(id+': hasAttributes', hasAttributes, r.HasAttributes);
  FContext.AssertTrue((attrCount)=(r.AttributeCount), id+': attributeCount');
end;

procedure TXMLReaderTestBase.AssertAttribute(r: TXMLReader; const Name, Prefix,
  LocalName, nsURI, Value: XMLString);
begin
  AssertEqualsW('value2', value, r.GetAttribute(name));

  if nsURI <> '' then
  begin
    AssertEqualsW('value3', value, r.GetAttribute(LocalName, nsURI));
  end;
end;

procedure TXMLReaderTestBase.DoTest(const XmlData: string; method: TTestMethod);
var
  xtr: TXmlReader;
  settings: TXMLReaderSettings;
  inp: TXMLInputSource;
begin
  settings := TXMLReaderSettings.Create;
  try
    settings.PreserveWhiteSpace := True;
    settings.Namespaces := True;
    inp := TXMLInputSource.Create(XmlData);
    try
      xtr := TXmlTextReader.Create(inp,settings);
      try
        method(xtr);
      finally
        xtr.Free;
      end;
    finally
      inp.Free;
    end;
  finally
    settings.Free;
  end;
  // here other TXMLReader descendants may be tested the same way...
end;

procedure TXMLReaderTestBase.AssertEquals(const id: string; exp, act: TXMLReadState);
begin
  if exp <> act then
    FContext.Fail(id);
end;

procedure TXMLReaderTestBase.AssertEquals(exp, act: TXMLReadState);
begin
  FContext.AssertTrue((exp)=(act), '');
end;

procedure TXMLReaderTestBase.AssertEqualsW(const id: string; const exp, act: XMLString);
begin
  FContext.AssertTrue(exp = act, id + ComparisonMsg(exp, act));
end;

procedure TXMLReaderTestBase.AssertEqualsW(const exp, act: XMLString);
begin
  AssertEqualsW('', exp, act);
end;

procedure TXMLReaderTestBase.AssertEquals(const id: string; exp, act: TXMLNodeType);
var
  exps,acts: string;
begin
  if exp <> act then
  begin
    Str(exp, exps);
    Str(act, acts);
    FContext.Fail(id+ComparisonMsg(exps,acts));
  end;
end;

procedure TXMLReaderTestBase.AssertEquals(exp, act: TXMLNodeType);
begin
  FContext.AssertTrue((exp)=(act), '');
end;

procedure TXMLReaderTestBase.assertNull(const id: string; const ws: XMLString);
begin
  if ws <> '' then
    FContext.Fail(id);
end;


procedure RegisterreaderunitTests(ARegistry: TNXTestRegistry);
begin
end;

end.

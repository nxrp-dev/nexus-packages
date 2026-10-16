// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit obFCLXMLProbe;

{$mode objfpc}{$H+}

interface

uses obNXTestContext;

procedure RunFCLXMLProbe(AId: Integer; const ADirectory: string;
  AContext: TNXTestContext);

implementation

uses
  Classes, SysUtils, Math, DOM, XMLRead, XMLWrite, HTMWrite, XMLConf, XMLCfg,
  XPath, XMLStreaming, {$IFDEF UNIX}XMLIConv,{$ENDIF} XMLUtils;

type
  TShortWriteStream = class(TMemoryStream)
  public
    function Write(const ABuffer; ACount: LongInt): LongInt; override;
  end;

function TShortWriteStream.Write(const ABuffer; ACount: LongInt): LongInt;
begin
  if ACount>0 then
    Result:=inherited Write(ABuffer,ACount-1)
  else
    Result:=0;
end;

procedure SaveBytes(const AFileName, AData: string);
var
  lStream: TStringStream;
begin
  lStream:=TStringStream.Create(AData);
  try
    lStream.SaveToFile(AFileName);
  finally
    lStream.Free;
  end;
end;

function LoadDocument(const AData: string): TXMLDocument;
var
  lStream: TStringStream;
begin
  Result:=nil;
  lStream:=TStringStream.Create(AData);
  try
    ReadXMLFile(Result,lStream);
  finally
    lStream.Free;
  end;
end;

procedure Probe01(const ADirectory: string; AContext: TNXTestContext);
var
  lConfig: XMLConf.TXMLConfig;
  lLegacy: XMLCfg.TXMLConfig;
  lFileName: string;
begin
  lFileName:=IncludeTrailingPathDelimiter(ADirectory)+'clear.xml';
  SaveBytes(lFileName,'<CONFIG old="42"><group value="1"/></CONFIG>');
  lConfig:=XMLConf.TXMLConfig.Create(nil);
  try
    lConfig.Filename:=lFileName;
    lConfig.Clear;
    AContext.AssertTrue(lConfig.Modified,'Clear did not mark the configuration dirty.');
    lConfig.Flush;
    lConfig.Filename:='';
    lConfig.Filename:=lFileName;
    AContext.AssertEquals(-1,lConfig.GetValue('old',-1),'Clear was not saved.');
    lConfig.OpenKey('group');
    lConfig.SetValue('value',1);
    lConfig.Clear;
    lConfig.SetValue('value',2);
    AContext.AssertEquals(2,lConfig.GetValue('/group/value',0),'Clear retained a detached current key.');
  finally
    lConfig.Free;
  end;
  lLegacy:=XMLCfg.TXMLConfig.Create(nil);
  try
    lLegacy.Filename:=lFileName;
    lLegacy.Clear;
    AContext.AssertTrue(lLegacy.Modified,'Deprecated XMLCfg.Clear also failed to mark dirty.');
  finally
    lLegacy.Free;
  end;
end;

procedure Probe02(const ADirectory: string; AContext: TNXTestContext);
var
  lConfig: XMLConf.TXMLConfig;
  lStream: TStringStream;
  lFileName: string;
begin
  lConfig:=XMLConf.TXMLConfig.Create(nil);
  lStream:=TStringStream.Create('<CONFIG><group value="42"/></CONFIG>');
  try
    lConfig.OpenKey('group');
    lConfig.SetValue('value',1);
    lConfig.LoadFromStream(lStream);
    AContext.AssertEquals(42,lConfig.GetValue('value',0),'Stream reload retained the old current key.');
    lFileName:=IncludeTrailingPathDelimiter(ADirectory)+'second.xml';
    SaveBytes(lFileName,'<CONFIG><group value="73"/></CONFIG>');
    lConfig.Filename:=lFileName;
    AContext.AssertEquals(73,lConfig.GetValue('value',0),'Filename change retained the old current key.');
    lConfig.SetValue('value',74);
    lConfig.Flush;
    lConfig.LoadFromFile(lFileName);
    AContext.AssertEquals(74,lConfig.GetValue('value',0));
  finally
    lStream.Free;
    lConfig.Free;
  end;
end;

procedure Probe03(const ADirectory: string; AContext: TNXTestContext);
const
  cInputs: array[0..1] of string = ('<CONFIG><broken>', '<WRONG/>');
var
  lConfig: XMLConf.TXMLConfig;
  lStream: TStringStream;
  lInput, lFileName: string;
  lRejected: Boolean;
begin
  lConfig:=XMLConf.TXMLConfig.Create(nil);
  try
    lConfig.SetValue('value',42);
    for lInput in cInputs do
    begin
      lStream:=TStringStream.Create(lInput);
      try
        lRejected:=False;
        try lConfig.LoadFromStream(lStream);
        except on E: Exception do lRejected:=(E is EXMLReadError) or (E is XMLConf.EXMLConfigError); end;
        AContext.AssertTrue(lRejected,'Invalid configuration stream was accepted.');
        AContext.AssertEquals(42,lConfig.GetValue('value',0),'Failed load destroyed the active values.');
        AContext.AssertTrue(lConfig.Modified,'Failed load cleared dirty state.');
      finally
        lStream.Free;
      end;
      lFileName:=IncludeTrailingPathDelimiter(ADirectory)+'invalid.xml';
      SaveBytes(lFileName,lInput);
      lRejected:=False;
      try lConfig.LoadFromFile(lFileName);
      except on E: Exception do lRejected:=(E is EXMLReadError) or (E is XMLConf.EXMLConfigError); end;
      AContext.AssertTrue(lRejected,'Invalid configuration file was accepted.');
      AContext.AssertEquals(42,lConfig.GetValue('value',0));
      AContext.AssertEquals('',lConfig.Filename,'Failed load changed the backing filename.');
    end;
    SaveBytes(IncludeTrailingPathDelimiter(ADirectory)+'values.dtd',
      '<!ELEMENT CONFIG EMPTY><!ATTLIST CONFIG value CDATA "77">');
    lFileName:=IncludeTrailingPathDelimiter(ADirectory)+'relative.xml';
    SaveBytes(lFileName,'<!DOCTYPE CONFIG SYSTEM "values.dtd"><CONFIG/>');
    lConfig.LoadFromFile(lFileName);
    AContext.AssertEquals(77,lConfig.GetValue('value',0),
      'File loading lost its base URI for relative external declarations.');
  finally
    lConfig.Free;
  end;
end;

procedure Probe04(AContext: TNXTestContext);
var
  lConfig: XMLConf.TXMLConfig;
  lLegacy: XMLCfg.TXMLConfig;
begin
  lConfig:=XMLConf.TXMLConfig.Create(nil);
  try
    lConfig.SetValue('root',42);
    lConfig.SetValue('group/child',13);
    lConfig.RootName:='SETTINGS';
    AContext.AssertEquals(42,lConfig.GetValue('root',0),'Root rename lost root-level values.');
    AContext.AssertEquals(13,lConfig.GetValue('group/child',0));
  finally lConfig.Free; end;
  lLegacy:=XMLCfg.TXMLConfig.Create(nil);
  try
    lLegacy.SetValue('root',42);
    lLegacy.SetValue('group/child',13);
    lLegacy.RootName:='SETTINGS';
    AContext.AssertEquals(42,lLegacy.GetValue('root',0));
    AContext.AssertEquals(13,lLegacy.GetValue('group/child',0));
  finally lLegacy.Free; end;
end;

procedure AssertXPathNumber(const AExpression: DOMString; AExpected: Extended;
  AContext: TNXTestContext);
var
  lValue: TXPathVariable;
begin
  lValue:=EvaluateXPathExpression(AExpression,nil);
  try
    if IsNan(AExpected) then
      AContext.AssertTrue(IsNan(lValue.AsNumber),'Expected NaN for '+UTF8Encode(AExpression))
    else
      AContext.AssertTrue(lValue.AsNumber=AExpected,
        UTF8Encode(AExpression)+' returned '+FloatToStr(lValue.AsNumber));
  finally lValue.Release; end;
end;

procedure Probe05(AContext: TNXTestContext);
begin
  AssertXPathNumber('5.5 mod 2',1.5,AContext);
  AssertXPathNumber('-5.5 mod 2',-1.5,AContext);
  AssertXPathNumber('5.5 mod -2',1.5,AContext);
  AssertXPathNumber('1 mod 0.5',0,AContext);
  AssertXPathNumber('1 mod 0',NaN,AContext);
  AssertXPathNumber('(1 div 0) mod 2',NaN,AContext);
  AssertXPathNumber('2 mod (1 div 0)',2,AContext);
  AssertXPathNumber('number("bad") mod 2',NaN,AContext);
end;

procedure Probe06(AContext: TNXTestContext);
begin
  AssertXPathNumber('floor(1 div 0)',Infinity,AContext);
  AssertXPathNumber('ceiling(-1 div 0)',-Infinity,AContext);
  AssertXPathNumber('floor(100000000000000000000)',1.0e20,AContext);
  AssertXPathNumber('ceiling(-100000000000000000000)',-1.0e20,AContext);
  AssertXPathNumber('round(100000000000000000000)',1.0e20,AContext);
  AssertXPathNumber('round(-0.5)',0,AContext);
  AssertXPathNumber('1 div round(-0.1)',-Infinity,AContext);
  AssertXPathNumber('1 div ceiling(-0.1)',-Infinity,AContext);
  AssertXPathNumber('1 div floor(-0)',-Infinity,AContext);
  AssertXPathNumber('round(-5.5)',-5,AContext);
  AssertXPathNumber('round(5.5)',6,AContext);
  AssertXPathNumber('floor(number("bad"))',NaN,AContext);
end;

procedure Probe07(AContext: TNXTestContext);
var
  lValue: TXPathVariable;
begin
  lValue:=EvaluateXPathExpression('boolean(0.0000000000000000000000000000000000000001)',nil);
  try AContext.AssertTrue(lValue.AsBoolean,'A nonzero XPath number became false.');
  finally lValue.Release; end;
  lValue:=EvaluateXPathExpression('0.0000000000000000000000000000000000000001 = 0',nil);
  try AContext.AssertFalse(lValue.AsBoolean,'Distinct XPath numbers compared equal.');
  finally lValue.Release; end;
end;

procedure Probe08(AContext: TNXTestContext);
var
  lDoc: TXMLDocument;
  lElement: TDOMElement;
  lAttribute: TDOMAttr;
begin
  lDoc:=TXMLDocument.Create;
  try
    lElement:=lDoc.CreateElementNS('urn:test','p:root');
    lDoc.AppendChild(lElement);
    lElement.Prefix:='';
    AContext.AssertEquals('root',UTF8Encode(lElement.NodeName));
    AContext.AssertEquals('',UTF8Encode(lElement.Prefix));
    lElement.Prefix:='new';
    AContext.AssertEquals('new:root',UTF8Encode(lElement.NodeName));
    lElement.SetAttribute('a','1');
    lElement.SetAttribute('m','2');
    lElement.SetAttributeNS('urn:test','p:value','3');
    lAttribute:=lElement.GetAttributeNodeNS('urn:test','value');
    lAttribute.Prefix:='b';
    AContext.AssertTrue(lElement.GetAttributeNode('b:value')=lAttribute,
      'Renamed attribute is missing from its qualified-name lookup.');
    AContext.AssertTrue(lElement.GetAttributeNode('p:value')=nil);
    lAttribute.Prefix:='';
    AContext.AssertTrue(lElement.GetAttributeNode('value')=lAttribute);
  finally lDoc.Free; end;
end;

procedure Probe09(AContext: TNXTestContext);
var
  lDoc: TXMLDocument;
  lStream: TShortWriteStream;
  lLong, lHTML, lRejected: Boolean;
begin
  for lHTML in [False,True] do
  for lLong in [False,True] do
  begin
    lDoc:=LoadDocument('<root/>');
    lStream:=TShortWriteStream.Create;
    try
      if lLong then
        lDoc.DocumentElement.AppendChild(lDoc.CreateTextNode(StringOfChar('x',12000)))
      else
        lDoc.DocumentElement.AppendChild(lDoc.CreateTextNode('text'));
      lRejected:=False;
      try
        if lHTML then WriteHTMLFile(lDoc,lStream) else WriteXMLFile(lDoc,lStream);
      except on E: EWriteError do lRejected:=True; end;
      AContext.AssertTrue(lRejected,'A short output write reported success.');
    finally lStream.Free; lDoc.Free; end;
  end;
end;

procedure Probe10(AContext: TNXTestContext);
{$IFDEF UNIX}
const
  cEncodings: array[0..1] of string = ('windows-1252','UTF-8');
var
  lParser: TDOMParser;
  lSource: TXMLInputSource;
  lDoc: TXMLDocument;
  lEncoding: string;
  lRejected: Boolean;
begin
  for lEncoding in cEncodings do
  begin
    lParser:=TDOMParser.Create;
    lParser.Options.MaxChars:=64;
    lSource:=TXMLInputSource.Create(AnsiString('<?xml version="1.0" encoding="'+lEncoding+'"?><root>'+StringOfChar('x',3000)+'</root>'));
    lDoc:=nil;
    try
      lRejected:=False;
      try lParser.Parse(lSource,lDoc);
      except on E: EXMLReadError do lRejected:=True; end;
      AContext.AssertTrue(lRejected,lEncoding+' bypassed the character limit.');
    finally lDoc.Free; lSource.Free; lParser.Free; end;
  end;
  lParser:=TDOMParser.Create;
  lSource:=TXMLInputSource.Create(AnsiString('<?xml version="1.0" encoding="windows-1252"?><root>'+
    StringOfChar('x',3000)+#$E9+'</root>'));
  lDoc:=nil;
  try
    lParser.Parse(lSource,lDoc);
    AContext.AssertEquals(StringOfChar('x',3000)+#$C3#$A9,
      UTF8Encode(lDoc.DocumentElement.TextContent),
      'The iconv adapter truncated a valid multibuffer document.');
  finally lDoc.Free; lSource.Free; lParser.Free; end;
end;
{$ELSE}
begin
  AContext.Skip('The iconv adapter is Unix-specific.');
end;
{$ENDIF}

procedure Probe11(AContext: TNXTestContext);
var
  lDoc: TXMLDocument;
  lWriter: TXMLObjectWriter;
  lIndex: Integer;
  lRejected: Boolean;
  lByte: Byte;
  lBefore, lAfter: PtrUInt;
begin
  lByte:=42;
  lBefore:=GetFPCHeapStatus.CurrHeapUsed;
  for lIndex:=0 to 11 do
  begin
    lDoc:=TXMLDocument.Create;
    lWriter:=TXMLObjectWriter.Create(lDoc);
    try
      lWriter.BeginProperty('value');
      lRejected:=False;
      try
        case lIndex of
          0: lWriter.WriteBoolean(True);
          1: lWriter.WriteFloat(1.25);
          2: lWriter.WriteSingle(1.25);
          3: lWriter.WriteCurrency(1.25);
          4: lWriter.WriteDate(123.5);
          5: lWriter.WriteBinary(lByte,1);
          6: lWriter.Write(lByte,1);
          7: lWriter.WriteSet(1,nil);
          8: lWriter.BeginList;
          9: lWriter.BeginCollection;
          10: lWriter.WriteSignature;
          11: lWriter.WriteUInt64(High(QWord));
        end;
      except on E: EWriteError do lRejected:=True; end;
      AContext.AssertTrue(lRejected,'Unsupported XML object write silently succeeded or stayed abstract.');
      // Deliberately leave the property open to verify exception cleanup.
    finally lWriter.Free; lDoc.Free; end;
  end;
  lAfter:=GetFPCHeapStatus.CurrHeapUsed;
  AContext.AssertTrue(lAfter<=lBefore+2048,'Object-writer stack leaked after failed writes.');
end;

procedure Probe12(AContext: TNXTestContext);
var
  lDoc: TXMLDocument;
  lValue: TXPathVariable;
  lRejected: Boolean;
begin
  lDoc:=LoadDocument('<root xmlns:p="urn:test"/>');
  lValue:=nil;
  try
    lRejected:=False;
    try lValue:=EvaluateXPathExpression('namespace::*',lDoc.DocumentElement);
    except on E: EXPathEvaluationError do lRejected:=True; end;
    AContext.AssertTrue(lRejected,'The unsupported namespace axis silently returned an empty result.');
  finally lValue.Free; lDoc.Free; end;
end;

procedure Probe13(AContext: TNXTestContext);
const
  cXML = '<!DOCTYPE root [<!ELEMENT root (item*)><!ELEMENT item EMPTY>'+
    '<!ATTLIST item id ID #REQUIRED>]><root><item id="c"/></root>';
var
  lValidate: Boolean;
  lParser: TDOMParser;
  lSource: TXMLInputSource;
  lDoc: TXMLDocument;
  lValue: TXPathVariable;
begin
  for lValidate in [False,True] do
  begin
    lParser:=TDOMParser.Create;
    lParser.Options.Validate:=lValidate;
    lSource:=TXMLInputSource.Create(AnsiString(cXML));
    lDoc:=nil;
    try
      lParser.Parse(lSource,lDoc);
      AContext.AssertTrue(lDoc.GetElementById('c')<>nil,'DTD-declared ID identity was lost.');
      lValue:=EvaluateXPathExpression('id("c")/@id',lDoc.DocumentElement);
      try AContext.AssertEquals('c',UTF8Encode(lValue.AsText));
      finally lValue.Release; end;
    finally lDoc.Free; lSource.Free; lParser.Free; end;
  end;
end;

procedure Probe14(AContext: TNXTestContext);
var
  lParser: TDOMParser;
  lSource: TXMLInputSource;
  lDoc: TXMLDocument;
  lValue: TXPathVariable;
begin
  lParser:=TDOMParser.Create;
  lParser.Options.Namespaces:=True;
  lSource:=TXMLInputSource.Create(AnsiString('<root xmlns="urn:test"><item/></root>'));
  lDoc:=nil;
  try
    lParser.Parse(lSource,lDoc);
    lValue:=EvaluateXPathExpression('count(item)',lDoc.DocumentElement);
    try
      AContext.AssertTrue(lValue.AsNumber=0,'Unprefixed XPath names matched a nonempty namespace.');
    finally lValue.Release; end;
  finally lDoc.Free; lSource.Free; lParser.Free; end;
end;

procedure RunFCLXMLProbe(AId: Integer; const ADirectory: string;
  AContext: TNXTestContext);
begin
  case AId of
    1: Probe01(ADirectory,AContext);
    2: Probe02(ADirectory,AContext);
    3: Probe03(ADirectory,AContext);
    4: Probe04(AContext);
    5: Probe05(AContext);
    6: Probe06(AContext);
    7: Probe07(AContext);
    8: Probe08(AContext);
    9: Probe09(AContext);
    10: Probe10(AContext);
    11: Probe11(AContext);
    12: Probe12(AContext);
    13: Probe13(AContext);
    14: Probe14(AContext);
  else
    AContext.Fail('Unknown FCL XML probe.');
  end;
end;

end.

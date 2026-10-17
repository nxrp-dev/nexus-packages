// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program FCLRegistryFixture;
{$mode objfpc}{$H+}
uses {$ifdef UNIX}cwstring,{$endif} Classes, SysUtils, Registry, XmlReg;
type
  TProbeRegistry = class(TRegistry)
  public
    procedure WriteEmptyMultiString;
  end;

procedure Require(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then raise Exception.Create(AMessage);
end;

procedure WriteFile(const AFileName, AText: string);
var
  lFile: TFileStream;
begin
  lFile := TFileStream.Create(AFileName, fmCreate);
  try
    if AText <> '' then lFile.WriteBuffer(AText[1], Length(AText));
  finally lFile.Free; end;
end;

function NewXMLRegistry: TXmlRegistry;
begin
  DeleteFile('fixture.xml');
  Result := TXmlRegistry.Create('fixture.xml');
  Result.AutoFlush := False;
  Require(Result.SetKey('/active', True), 'Could not select XML test key');
end;

procedure Navigation(const AOperation: string);
var
  lRegistry: TXmlRegistry;
  lValue: Cardinal;
  lCurrent: UnicodeString;
begin
  lRegistry := NewXMLRegistry;
  try
    lValue := 42;
    lCurrent := lRegistry.CurrentKey;
    case AOperation of
      'probe': Require(lRegistry.KeyExists('/active'), 'Existing absolute key was not found');
      'create': Require(lRegistry.CreateKey('/other'), 'Could not create absolute key');
      'failed-open': Require(not lRegistry.SetKey('/missing', False), 'Missing key unexpectedly opened');
      'delete-control':
      begin
        Require(lRegistry.DeleteKey('/active'), 'Could not delete selected key');
        Require(not lRegistry.SetValueData('v', dtDWORD, lValue, SizeOf(lValue)),
          'Write succeeded through a deleted key');
        Exit;
      end;
    end;
    Require(lRegistry.CurrentKey = lCurrent, 'Operation changed the selected path');
    Require(lRegistry.SetValueData('v', dtDWORD, lValue, SizeOf(lValue)), 'Operation lost selected element');
  finally lRegistry.Free; end;
end;

procedure Metadata(const AKind: string);
var
  lRegistry: TXmlRegistry;
  lBinary: array[0..2] of Byte;
  lMulti: array[0..2] of WideChar;
  lNumber: QWord;
  lInfo: TDataInfo;
  lKeyInfo: TKeyInfo;
  lExpected: Integer;
begin
  lRegistry := NewXMLRegistry;
  try
    lNumber := 123456789;
    lBinary[0] := 1; lBinary[1] := 2; lBinary[2] := 3;
    lMulti[0] := 'x'; lMulti[1] := #0; lMulti[2] := 'y';
    case AKind of
      'binary': begin lExpected := SizeOf(lBinary); Require(lRegistry.SetValueData('v', dtBinary, lBinary, lExpected), 'Write failed'); end;
      'multi': begin lExpected := SizeOf(lMulti); Require(lRegistry.SetValueDataUnicode('v', dtStrings, lMulti, lExpected), 'Write failed'); end;
    else
      lExpected := SizeOf(lNumber);
      Require(lRegistry.SetValueData('v', dtQWord, lNumber, lExpected), 'Write failed');
    end;
    if AKind = 'maximum' then
    begin
      Require(lRegistry.GetKeyInfo(lKeyInfo), 'Key metadata failed');
      Require(lKeyInfo.DataLen = lExpected, 'Maximum data length is not the stored byte count');
    end
    else
    begin
      lInfo := Default(TDataInfo);
      lInfo.DataSize := -1;
      Require(lRegistry.GetValueInfo('v', lInfo, True), 'Value metadata failed');
      Require(lInfo.DataSize = lExpected, 'Value metadata has the wrong byte count');
    end;
  finally lRegistry.Free; end;
end;

procedure KeyTimestamp;
var
  lRegistry: TXmlRegistry;
  lInfo: TKeyInfo;
  lExpected: TDateTime;
begin
  lRegistry := NewXMLRegistry;
  try
    lRegistry.Flush;
    Require(FileAge('fixture.xml', lExpected), 'Could not read fixture timestamp');
    Require(lRegistry.GetKeyInfo(lInfo), 'Key metadata failed');
    Require(Abs(lInfo.FTime - lExpected) < 1 / SecsPerDay, 'Key timestamp is not a TDateTime');
  finally lRegistry.Free; end;
end;

procedure BoundedString(AUnicode: Boolean);
var
  lRegistry: TXmlRegistry;
  lANSI: array[0..3] of AnsiChar;
  lWide: array[0..3] of WideChar;
  lData: array[0..15] of Byte;
  lSize: Integer;
  lType: TDataType;
begin
  lRegistry := NewXMLRegistry;
  try
    lANSI[0] := 'a'; lANSI[1] := 'b'; lANSI[2] := 'X'; lANSI[3] := #0;
    lWide[0] := 'a'; lWide[1] := 'b'; lWide[2] := 'X'; lWide[3] := #0;
    lSize := SizeOf(lData);
    if AUnicode then
    begin
      Require(lRegistry.SetValueDataUnicode('v', dtString, lWide, 2*SizeOf(WideChar)), 'Unicode write failed');
      Require(lRegistry.GetValueDataUnicode('v', lType, lData, lSize), 'Unicode read failed');
      Require(lSize = 2*SizeOf(WideChar), 'Unicode writer read past DataSize');
    end
    else
    begin
      Require(lRegistry.SetValueData('v', dtString, lANSI, 2), 'ANSI write failed');
      Require(lRegistry.GetValueData('v', lType, lData, lSize), 'ANSI read failed');
      Require(lSize = 2, 'ANSI writer read past DataSize');
    end;
  finally lRegistry.Free; end;
end;

procedure MalformedValue(const AType, AText: string; ACheckMetadata: Boolean);
var
  lRegistry: TXmlRegistry;
  lData: array[0..7] of Byte;
  lType: TDataType;
  lSize: Integer;
  lInfo: TDataInfo;
begin
  WriteFile('malformed.xml', '<XMLReg><Key Name="HKEY_CURRENT_USER"><Key Name="active">' +
    '<Value Name="v" Type="' + AType + '">' + AText + '</Value></Key></Key></XMLReg>');
  lRegistry := TXmlRegistry.Create('malformed.xml');
  try
    lRegistry.AutoFlush := False;
    Require(lRegistry.SetKey('/active', False), 'Could not select malformed fixture');
    lSize := SizeOf(lData);
    Require(not lRegistry.GetValueData('v', lType, lData, lSize), 'Malformed value was reported as a successful read');
    if ACheckMetadata then
      Require(not lRegistry.GetValueInfo('v', lInfo), 'Invalid type was reported as valid metadata');
  finally lRegistry.Free; end;
end;

procedure IniSection(const AKind: string);
var
  lRegistry: TRegIniFile;
  lCurrent: UnicodeString;
begin
  lRegistry := TRegIniFile.Create('ReviewBase');
  try
    lCurrent := lRegistry.CurrentPath;
    case AKind of
      'date': lRegistry.WriteDate('section', 'v', EncodeDate(2026, 10, 17));
      'datetime': lRegistry.WriteDateTime('section', 'v', EncodeDate(2026, 10, 17) + 0.5);
      'time': lRegistry.WriteTime('section', 'v', 0.5);
      'float': lRegistry.WriteFloat('section', 'v', 1.25);
    end;
    Require(lRegistry.CurrentKey <> 0, 'Typed write closed the base key');
    Require(lRegistry.CurrentPath = lCurrent, 'Typed write lost the base path');
    lRegistry.WriteString('other', 'check', 'kept');
    Require(lRegistry.ReadString('other', 'check', '') = 'kept', 'Following section access failed');
  finally lRegistry.Free; end;
end;

procedure TProbeRegistry.WriteEmptyMultiString;
var
  lTerminators: array[0..1] of WideChar;
begin
  lTerminators[0] := #0;
  lTerminators[1] := #0;
  PutData('v', @lTerminators[0], SizeOf(lTerminators), rdMultiString);
end;

procedure EmptyMultiString;
var
  lRegistry: TProbeRegistry;
  lValues: Registry.TUnicodeStringArray;
begin
  lRegistry := TProbeRegistry.Create;
  try
    Require(lRegistry.OpenKey('empty', True), 'Could not open empty-list test key');
    lRegistry.WriteEmptyMultiString;
    lValues := lRegistry.ReadStringArray(UnicodeString('v'));
    Require(Length(lValues) = 0, 'Empty multistring returned values');
  finally lRegistry.Free; end;
end;

procedure UnsupportedRemote;
var
  lRegistry: TRegistry;
begin
  lRegistry := TRegistry.Create;
  try
    Require(not lRegistry.RegistryConnect('\\NexusReviewUnavailable'), 'XML backend claimed a remote connection');
  finally lRegistry.Free; end;
end;

procedure InvalidXML(AReload: Boolean);
var
  lRegistry: TXmlRegistry;
  lRejected: Boolean;
  lValue, lRead: Cardinal;
  lType: TDataType;
  lSize: Integer;
begin
  lRegistry := nil;
  try
    if AReload then
    begin
      lRegistry := NewXMLRegistry;
      lValue := 7;
      Require(lRegistry.SetValueData('v', dtDWORD, lValue, SizeOf(lValue)), 'Could not prepare reload state');
      lRegistry.Flush;
    end;
    WriteFile('fixture.xml', '<XMLReg><broken');
    lRejected := False;
    try
      if AReload then lRegistry.Load
      else lRegistry := TXmlRegistry.Create('fixture.xml');
    except
      on Exception do lRejected := True;
    end;
    Require(lRejected, 'Malformed XML was silently replaced with an empty registry');
    if AReload then
    begin
      lSize := SizeOf(lRead);
      Require(lRegistry.GetValueData('v', lType, lRead, lSize), 'Failed reload lost current data');
      Require(lRead = lValue, 'Failed reload changed current data');
    end;
  finally lRegistry.Free; end;
end;

begin
  try
    case ParamStr(1) of
      'key-probe': Navigation('probe');
      'key-create': Navigation('create');
      'key-failed-open': Navigation('failed-open');
      'delete-selected-control': Navigation('delete-control');
      'size-binary': Metadata('binary');
      'size-multi': Metadata('multi');
      'size-qword': Metadata('qword');
      'size-maximum': Metadata('maximum');
      'key-timestamp': KeyTimestamp;
      'bounded-ansi': BoundedString(False);
      'bounded-unicode': BoundedString(True);
      'invalid-hex': MalformedValue('3', '0G', False);
      'odd-hex': MalformedValue('3', 'A', False);
      'negative-type': MalformedValue('-1', '1', True);
      'large-type': MalformedValue('99', '1', True);
      'nonnumeric-type': MalformedValue('bad', '1', True);
      'ini-date': IniSection('date');
      'ini-datetime': IniSection('datetime');
      'ini-time': IniSection('time');
      'ini-float': IniSection('float');
      'empty-multi': EmptyMultiString;
      'unsupported-remote': UnsupportedRemote;
      'malformed-load': InvalidXML(False);
      'failed-reload': InvalidXML(True);
    else raise Exception.Create('Unknown registry regression');
    end;
    WriteLn('PASS');
  except
    on lError: Exception do begin WriteLn(lError.ClassName, ': ', lError.Message); Halt(1); end;
  end;
end.

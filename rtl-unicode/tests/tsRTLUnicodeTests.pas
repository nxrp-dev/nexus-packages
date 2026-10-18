// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit tsRTLUnicodeTests;
{$mode objfpc}
interface
uses obNXTestRegistry;
procedure RegisterRTLUnicodeTests(ARegistry: TNXTestRegistry);
implementation
uses
  Classes, SysUtils, Charset, UnicodeData, fpwidestring, UTF8Utils,
  graphemebreakproperty, eastasianwidth, utNXCollationData,
  obNXTestContext, obNXTestSuite;

type
  TUnicodeClusters = array of UnicodeString;

function CodePointText(ACodePoint: Cardinal): UnicodeString;
begin
  if ACodePoint <= $FFFF then
    Result := UnicodeChar(ACodePoint)
  else
  begin
    SetLength(Result, 2);
    FromUCS4(ACodePoint, Result[1], Result[2]);
  end;
end;

procedure AssertBytes(AContext: TNXTestContext; const AExpected, AActual: AnsiString);
var
  lIndex: Integer;
begin
  AContext.AssertEquals(Length(AExpected), Length(AActual), 'Byte length');
  for lIndex := 1 to Length(AExpected) do
    AContext.AssertEquals(Ord(AExpected[lIndex]), Ord(AActual[lIndex]),
      'Byte ' + IntToStr(lIndex));
end;

procedure TestImportPolicy(AContext: TNXTestContext);
begin
  AContext.AssertEquals(1252, DefaultSystemCodePage, 'Import preserves conversion policy');
  AContext.AssertEquals(1252, DefaultRTLFileSystemCodePage, 'Import preserves filesystem policy');
end;

procedure TestActivation(AContext: TNXTestContext);
begin
  AContext.AssertTrue(FindCollation('DUCET') <> nil);
  AContext.AssertTrue(FindCollation('ROOT') = FindCollation('DUCET'));
  AContext.AssertTrue(SetActiveCollation('ru'), 'Select an already registered locale');
  AContext.AssertFalse(SetActiveCollation('nx-missing-collation'), 'Unknown selection fails');
  AContext.AssertEquals(Ord('r'), GetActiveCollation^.CollationName[0], 'Failed selection preserves the locale');
  AContext.AssertTrue(SetActiveCollation('DUCET'));
  AContext.AssertTrue(GetActiveCollation <> nil);
  AContext.AssertEquals(0, UnicodeCompareStr(UnicodeString(#$00E9),
    UnicodeString('e' + #$0301)), 'Canonical-equivalent text');
end;

procedure TestTextTypes(AContext: TNXTestContext);
var
  lDefault: string;
  lUnicode: UnicodeString;
  lWide: WideString;
begin
  lDefault := 'a';
  {$ifdef FPC_UNICODESTRINGS}
  AContext.AssertEquals(2, SizeOf(lDefault[1]));
  {$else}
  AContext.AssertEquals(1, SizeOf(lDefault[1]));
  {$endif}
  lUnicode := CodePointText($1F600);
  lWide := lUnicode;
  AContext.AssertEquals(2, Length(lWide));
  AContext.AssertTrue(UnicodeString(lWide) = lUnicode);
end;

procedure TestUTF8Encode(AContext: TNXTestContext);
begin
  AssertBytes(AContext, #0, UTF8Utils.UnicodeToUTF8(0));
  AssertBytes(AContext, #$C2#$80, UTF8Utils.UnicodeToUTF8($80));
  AssertBytes(AContext, #$DF#$BF, UTF8Utils.UnicodeToUTF8($7FF));
  AssertBytes(AContext, #$E0#$A0#$80, UTF8Utils.UnicodeToUTF8($800));
  AssertBytes(AContext, #$F0#$9F#$98#$80, UTF8Utils.UnicodeToUTF8($1F600));
end;

procedure TestReplaceEqual(AContext: TNXTestContext);
begin
  AssertBytes(AContext, 'Xb', UTF8StringReplace('ab', 'a', 'X', []));
end;

procedure TestReplaceGrow(AContext: TNXTestContext);
begin
  AssertBytes(AContext, 'XYbXY', UTF8StringReplace('aba', 'a', 'XY', [rfReplaceAll]));
end;

procedure TestReplaceShrink(AContext: TNXTestContext);
begin
  AssertBytes(AContext, 'XX', UTF8StringReplace('abab', 'ab', 'X', [rfReplaceAll]));
end;

procedure TestUTF8RoundTrip(AContext: TNXTestContext);
var
  lText: UnicodeString;
  lBytes: AnsiString;
begin
  lText := UnicodeString('a' + #0 + #$00E9) + CodePointText($1F600);
  lBytes := UTF16ToUTF8(lText);
  AssertBytes(AContext, 'a' + #0 + #$C3#$A9#$F0#$9F#$98#$80, lBytes);
  AContext.AssertTrue(UTF8ToUTF16(lBytes) = lText);
  AssertBytes(AContext, '', UTF16ToUTF8(''));
  AContext.AssertTrue(UTF8ToUTF16('') = '');
end;

procedure TestUTF8Case(AContext: TNXTestContext);
begin
  AssertBytes(AContext, #$C3#$A9, UTF8LowerCase(#$C3#$89));
  AssertBytes(AContext, #$C3#$89, UTF8UpperCase(#$C3#$A9));
  AssertBytes(AContext, 'b' + #$C3#$A9 + 'a', UTF8ReverseString('a' + #$C3#$A9 + 'b'));
end;

procedure TestSystemConversions(AContext: TNXTestContext);
var
  lOriginal: TSystemCodePage;
begin
  lOriginal := DefaultSystemCodePage;
  try
    SetMultiByteConversionCodePage(1252);
    AContext.AssertTrue(NeedRTLAnsi, 'Current code-page policy, independent of locale');
    AssertBytes(AContext, #$E9, UTF8ToSys(#$C3#$A9));
    AssertBytes(AContext, #$C3#$A9, SysToUTF8(#$E9));
    SetMultiByteConversionCodePage(CP_UTF8);
    AContext.AssertFalse(NeedRTLAnsi, 'Observe a subsequent policy change');
    AssertBytes(AContext, #$C3#$A9, UTF8ToSys(#$C3#$A9));
  finally
    SetMultiByteConversionCodePage(lOriginal);
  end;
end;

procedure TestInheritedLimits(AContext: TNXTestContext);
var
  lDerived: TUCA_DataBook;
  lBase: PUCA_DataBook;
begin
  lBase := FindCollation('DUCET');
  lDerived := Default(TUCA_DataBook);
  PrepareCollation(@lDerived, 'DUCET', []);
  AContext.AssertEquals(lBase^.VariableLowLimit, lDerived.VariableLowLimit, 'Inherited low');
  AContext.AssertEquals(lBase^.VariableHighLimit, lDerived.VariableHighLimit, 'Inherited high');
end;

procedure TestLocales(AContext: TNXTestContext);
const
  cNames: array[0..7] of string = ('de', 'es', 'fr_ca', 'ja', 'ko', 'ru', 'sv', 'zh');
var
  lIndex: Integer;
  lLocale: PUCA_DataBook;
  lCopy: TUCA_DataBook;
begin
  for lIndex := Low(cNames) to High(cNames) do
  begin
    lLocale := FindCollation(UnicodeString(cNames[lIndex]));
    AContext.AssertTrue(lLocale <> nil, cNames[lIndex]);
    AContext.AssertTrue(CompareSortKey(ComputeSortKey(UnicodeString('a'), lLocale),
      ComputeSortKey(UnicodeString('b'), lLocale)) < 0, cNames[lIndex]);
  end;
  lCopy := FindCollation('ru')^;
  lCopy.VariableWeight := TUCA_VariableKind.ucaShifted;
  lCopy.ComparisonStrength := 3;
  AContext.AssertEquals(0, CompareSortKey(ComputeSortKey(UnicodeString('ab'), @lCopy),
    ComputeSortKey(UnicodeString('a-b'), @lCopy)), 'Inherited shifted punctuation');
end;

procedure CheckCodePage(AContext: TNXTestContext; ACodePage: Word;
  const ABytes: RawByteString; ACodePoint: Cardinal);
var
  lBytes: RawByteString;
  lUnicode: UnicodeString;
  lWide: WideString;
  lMap: PUnicodeMap;
begin
  lMap := GetMap(ACodePage);
  AContext.AssertTrue(lMap <> nil, IntToStr(ACodePage));
  lBytes := ABytes;
  SetCodePage(lBytes, ACodePage, False);
  lUnicode := UnicodeString(lBytes);
  lWide := WideString(lBytes);
  AContext.AssertTrue(lUnicode = CodePointText(ACodePoint), 'Unicode conversion');
  AContext.AssertTrue(UnicodeString(lWide) = lUnicode, 'Explicit WideString conversion');
  AssertBytes(AContext, AnsiString(ABytes), GetASCII(ACodePoint, lMap));
end;

procedure TestCodePages(AContext: TNXTestContext);
begin
  CheckCodePage(AContext, 895, 'A', $41);
  CheckCodePage(AContext, 932, #$82#$A0, $3042);
  CheckCodePage(AContext, 936, #$D6#$D0, $4E2D);
  CheckCodePage(AContext, 949, #$B0#$A1, $AC00);
  CheckCodePage(AContext, 950, #$A4#$A4, $4E2D);
end;

procedure CheckClusters(AContext: TNXTestContext; const AText: UnicodeString;
  AExpected: Integer);
var
  lEnumerator: TUnicodeStringExtendedGraphemeClustersEnumerator;
  lCount: Integer;
  lJoined: UnicodeString;
begin
  lEnumerator := TUnicodeStringExtendedGraphemeClustersEnumerator.Create(AText);
  try
    lCount := 0;
    lJoined := '';
    while lEnumerator.MoveNext do
    begin
      Inc(lCount);
      lJoined := lJoined + lEnumerator.Current;
    end;
    AContext.AssertEquals(AExpected, lCount, 'Grapheme count');
    AContext.AssertTrue(lJoined = AText, 'Every code unit retained');
  finally
    lEnumerator.Free;
  end;
end;

procedure TestGraphemeBasic(AContext: TNXTestContext);
begin
  CheckClusters(AContext, '', 0);
  CheckClusters(AContext, UnicodeString('e' + #$0301), 1);
  CheckClusters(AContext, #13#10, 1);
  CheckClusters(AContext, UnicodeString(#$1100#$1161#$11A8), 1);
  CheckClusters(AContext, CodePointText($1F1FA) + CodePointText($1F1F8) +
    CodePointText($1F1E8) + CodePointText($1F1E6), 2);
end;

procedure TestEmojiZWJ(AContext: TNXTestContext);
begin
  CheckClusters(AContext, CodePointText($1F469) + UnicodeString(#$200D) +
    CodePointText($1F4BB), 1);
end;

procedure TestIndicConjunct(AContext: TNXTestContext);
begin
  CheckClusters(AContext, UnicodeString(#$0915#$094D#$0915), 1);
end;

function FixtureText(const AName: string): UnicodeString;
var
  lStream: TMemoryStream;
  lBytes: AnsiString;
begin
  lStream := TMemoryStream.Create;
  try
    LoadCollationData(lStream, ExtractFilePath(ParamStr(0)) + 'Unicode17.zip', AName);
    SetString(lBytes, PAnsiChar(lStream.Memory), lStream.Size);
    Result := UTF8ToUTF16(lBytes);
  finally
    lStream.Free;
  end;
end;

function NextDataLine(const AText: UnicodeString; var APosition: Integer;
  out ALine: UnicodeString): Boolean;
var
  lStart, lComment: Integer;
begin
  Result := APosition <= Length(AText);
  if not Result then Exit;
  lStart := APosition;
  while (APosition <= Length(AText)) and (AText[APosition] <> #10) do Inc(APosition);
  ALine := Copy(AText, lStart, APosition - lStart);
  Inc(APosition);
  lComment := Pos(UnicodeString('#'), ALine);
  if lComment > 0 then SetLength(ALine, lComment - 1);
end;

function ReadCodePoint(const ALine: UnicodeString; var APosition: Integer): UnicodeString;
var
  lStart: Integer;
begin
  lStart := APosition;
  while (APosition <= Length(ALine)) and
    (Ord(ALine[APosition]) in [Ord('0')..Ord('9'), Ord('A')..Ord('F')]) do
    Inc(APosition);
  Result := CodePointText(StrToInt('$' + string(Copy(ALine, lStart, APosition - lStart))));
end;

procedure TestGraphemeConformance(AContext: TNXTestContext);
var
  lText, lLine, lInput, lCluster: UnicodeString;
  lPosition, lIndex, lCount, lRows: Integer;
  lExpected: TUnicodeClusters;
  lEnumerator: TUnicodeStringExtendedGraphemeClustersEnumerator;
begin
  lText := FixtureText('GraphemeBreakTest.txt');
  lPosition := 1;
  lRows := 0;
  while NextDataLine(lText, lPosition, lLine) do
  begin
    SetLength(lExpected, 0);
    lInput := '';
    lCluster := '';
    lIndex := 1;
    while lIndex <= Length(lLine) do
      if (lLine[lIndex] = UnicodeChar($00F7)) and (lCluster <> '') then
      begin
        SetLength(lExpected, Length(lExpected) + 1);
        lExpected[High(lExpected)] := lCluster;
        lCluster := '';
        Inc(lIndex);
      end
      else if Ord(lLine[lIndex]) in [Ord('0')..Ord('9'), Ord('A')..Ord('F')] then
        lCluster := lCluster + ReadCodePoint(lLine, lIndex)
      else Inc(lIndex);
    if Length(lExpected) = 0 then Continue;
    Inc(lRows);
    for lIndex := 0 to High(lExpected) do lInput := lInput + lExpected[lIndex];
    lEnumerator := TUnicodeStringExtendedGraphemeClustersEnumerator.Create(lInput);
    try
      lCount := 0;
      while lEnumerator.MoveNext do
      begin
        AContext.AssertTrue(lCount < Length(lExpected), 'Extra cluster at row ' + IntToStr(lRows));
        AContext.AssertTrue(lEnumerator.Current = lExpected[lCount], 'Cluster at row ' + IntToStr(lRows));
        Inc(lCount);
      end;
      AContext.AssertEquals(Length(lExpected), lCount, 'Row ' + IntToStr(lRows));
    finally lEnumerator.Free; end;
  end;
  AContext.AssertEquals(766, lRows, 'Complete version-matched fixture');
end;

procedure TestNormalizationConformance(AContext: TNXTestContext);
var
  lText, lLine: UnicodeString;
  lFields: array[0..4] of UnicodeString;
  lPosition, lIndex, lField, lRows: Integer;
begin
  lText := FixtureText('NormalizationTest.txt');
  lPosition := 1;
  lRows := 0;
  while NextDataLine(lText, lPosition, lLine) do
  begin
    if (lLine = '') or (lLine[1] = '@') then Continue;
    for lField := 0 to 4 do lFields[lField] := '';
    lField := 0;
    lIndex := 1;
    while (lIndex <= Length(lLine)) and (lField < 5) do
      if lLine[lIndex] = ';' then begin Inc(lField); Inc(lIndex); end
      else if Ord(lLine[lIndex]) in [Ord('0')..Ord('9'), Ord('A')..Ord('F')] then
        lFields[lField] := lFields[lField] + ReadCodePoint(lLine, lIndex)
      else Inc(lIndex);
    if lField < 5 then Continue;
    Inc(lRows);
    for lField := 0 to 2 do
      AContext.AssertTrue(NormalizeNFD(lFields[lField]) = lFields[2], 'NFD row ' + IntToStr(lRows));
    for lField := 3 to 4 do
      AContext.AssertTrue(NormalizeNFD(lFields[lField]) = lFields[4], 'NFD compatibility row ' + IntToStr(lRows));
  end;
  AContext.AssertEquals(20034, lRows, 'Complete version-matched fixture');
end;

procedure TestWidth(AContext: TNXTestContext);
begin
  AContext.AssertTrue(GetEastAsianWidth($41) = eawNa);
  AContext.AssertTrue(GetEastAsianWidth($4E2D) = eawW);
  AContext.AssertTrue(GetEastAsianWidth($FF21) = eawF);
  AContext.AssertTrue(GetEastAsianWidth($FF76) = eawH);
end;

procedure RegisterRTLUnicodeTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('RTLUnicode');
  lSuite.AddTest('ImportPolicy', @TestImportPolicy);
  lSuite.AddTest('Activation', @TestActivation);
  lSuite.AddTest('TextTypes', @TestTextTypes);
  lSuite.AddTest('UTF8Encode', @TestUTF8Encode);
  lSuite.AddTest('ReplaceEqual', @TestReplaceEqual);
  lSuite.AddTest('ReplaceGrow', @TestReplaceGrow);
  lSuite.AddTest('ReplaceShrink', @TestReplaceShrink);
  lSuite.AddTest('UTF8RoundTrip', @TestUTF8RoundTrip);
  lSuite.AddTest('UTF8Case', @TestUTF8Case);
  lSuite.AddTest('SystemConversions', @TestSystemConversions);
  lSuite.AddTest('InheritedLimits', @TestInheritedLimits);
  lSuite.AddTest('Locales', @TestLocales);
  lSuite.AddTest('CodePages', @TestCodePages);
  lSuite.AddTest('GraphemeBasic', @TestGraphemeBasic);
  lSuite.AddTest('EmojiZWJ', @TestEmojiZWJ);
  lSuite.AddTest('IndicConjunct', @TestIndicConjunct);
  lSuite.AddTest('GraphemeConformance', @TestGraphemeConformance);
  lSuite.AddTest('NormalizationConformance', @TestNormalizationConformance);
  lSuite.AddTest('Width', @TestWidth);
end;
end.

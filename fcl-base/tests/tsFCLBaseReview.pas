// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit tsFCLBaseReview;
{$mode objfpc}{$H+}
interface
uses obNXTestRegistry;
procedure RegisterFCLBaseReviewTests(ARegistry: TNXTestRegistry);
implementation
uses Classes, SysUtils, TypInfo, NullStream, CacheCls, Ascii85, URIParser,
  BufStream, WFormat, Base64, RttiUtils, FPObserver, Contnrs, GetText,
  obNXTestCase, obNXTestSuite, obNXTestContext;

{$I ascii85-vectors.inc}

function HexBytes(const AHex: string): RawByteString;
var lIndex: Integer;
begin
  SetLength(Result, Length(AHex) div 2);
  for lIndex := 1 to Length(Result) do
    Result[lIndex] := AnsiChar(StrToInt('$' + Copy(AHex, lIndex * 2 - 1, 2)));
end;

function Encode85(const AData: RawByteString; AWidth: Integer = 72): string;
var lOutput: TStringStream; lEncoder: TASCII85EncoderStream;
begin
  lOutput := TStringStream.Create('');
  try
    lEncoder := TASCII85EncoderStream.Create(lOutput, AWidth, False);
    try
      if AData <> '' then lEncoder.WriteBuffer(AData[1], Length(AData));
    finally
      lEncoder.Free;
    end;
    Result := lOutput.DataString;
  finally
    lOutput.Free;
  end;
end;

function Decode85(const AText: string): RawByteString;
var lInput: TStringStream; lDecoder: TASCII85DecoderStream;
  lBuffer: array[0..2047] of Byte; lCount, lOldLength: Integer;
begin
  Result := '';
  lInput := TStringStream.Create(AText);
  try
    lDecoder := TASCII85DecoderStream.Create(lInput);
    try
      repeat
        lCount := lDecoder.Read(lBuffer, SizeOf(lBuffer));
        lOldLength := Length(Result);
        SetLength(Result, lOldLength + lCount);
        if lCount > 0 then Move(lBuffer, Result[lOldLength + 1], lCount);
      until lCount = 0;
    finally
      lDecoder.Free;
    end;
  finally
    lInput.Free;
  end;
end;

procedure NullWriteCount(AContext: TNXTestContext);
var lStream: TNullStream; lData: LongWord;
begin
  lData := $12345678;
  lStream := TNullStream.Create;
  try
    AContext.AssertEquals(SizeOf(lData), lStream.Write(lData, SizeOf(lData)), 'Written byte count');
    AContext.AssertEquals(Int64(SizeOf(lData)), lStream.Size, 'Discarded data still advances size');
  finally lStream.Free; end;
end;

procedure NullSeekReturn(AContext: TNXTestContext);
var lStream: TNullStream;
begin
  lStream := TNullStream.Create;
  try
    lStream.Size := 20;
    AContext.AssertEquals(Int64(7), lStream.Seek(Int64(7), soBeginning), 'Seek returns new position');
    AContext.AssertEquals(Int64(9), lStream.Seek(Int64(2), soCurrent), 'Relative seek result');
    AContext.AssertEquals(Int64(9), lStream.Position, 'Position agrees with seek result');
  finally lStream.Free; end;
end;

procedure NullSeekEnd(AContext: TNXTestContext);
var lStream: TNullStream;
begin
  lStream := TNullStream.Create;
  try
    lStream.Size := 20;
    lStream.Seek(Int64(-3), soEnd);
    AContext.AssertEquals(Int64(17), lStream.Position, 'Negative end-relative offset');
  finally lStream.Free; end;
end;

procedure NullReadControl(AContext: TNXTestContext);
var lStream: TNullStream; lData: array[0..7] of Byte; lIndex: Integer;
begin
  lStream := TNullStream.Create;
  try
    lStream.Size := 5;
    FillChar(lData, SizeOf(lData), $CC);
    AContext.AssertEquals(5, lStream.Read(lData, SizeOf(lData)));
    for lIndex := 0 to 4 do AContext.AssertEquals(0, lData[lIndex]);
    AContext.AssertEquals($CC, lData[5], 'Do not overwrite beyond returned count');
    AContext.AssertEquals(0, lStream.Read(lData, 1), 'EOF');
  finally lStream.Free; end;
end;

procedure CheckCacheLinks(AContext: TNXTestContext; ACache: TCache);
var lSlot, lPrevious: PCacheSlot; lIndex, lVisited, lFound: Integer;
begin
  if ACache.SlotCount = 0 then
  begin
    AContext.AssertTrue(ACache.MRUSlot = nil, 'Empty MRU');
    AContext.AssertTrue(ACache.LRUSlot = nil, 'Empty LRU');
    Exit;
  end;
  lSlot := ACache.MRUSlot;
  lPrevious := nil;
  for lVisited := 0 to ACache.SlotCount - 1 do
  begin
    lFound := -1;
    for lIndex := 0 to ACache.SlotCount - 1 do
      if lSlot = ACache.Slots[lIndex] then lFound := lIndex;
    AContext.AssertTrue(lFound >= 0, 'Every link points into the current slot allocation');
    AContext.AssertTrue(lSlot^.Prev = lPrevious, 'Consistent reverse link');
    AContext.AssertEquals(lFound, lSlot^.Index, 'Stable slot index');
    lPrevious := lSlot;
    lSlot := lSlot^.Next;
  end;
  AContext.AssertTrue(lSlot = nil, 'No linked-list cycle');
  AContext.AssertTrue(lPrevious = ACache.LRUSlot, 'LRU is the final live slot');
end;

procedure CacheGrow(AContext: TNXTestContext);
var lCache: TCache; lData: Integer;
begin
  lCache := TCache.Create(3);
  try
    lCache.Data[0] := @lData;
    lCache.SlotCount := 2048;
    CheckCacheLinks(AContext, lCache);
    AContext.AssertEquals(0, lCache.MRUSlot^.Index, 'Growth preserves the MRU');
    AContext.AssertTrue(lCache.Data[0] = @lData, 'Growth preserves slot data');
  finally lCache.Free; end;
end;

procedure CacheShrink(AContext: TNXTestContext);
var lCache: TCache; lData: Integer;
begin
  lCache := TCache.Create(2048);
  try
    lCache.Data[0] := @lData;
    lCache.SlotCount := 2;
    CheckCacheLinks(AContext, lCache);
    AContext.AssertTrue(lCache.Data[0] = @lData, 'Shrink preserves surviving slot data');
  finally lCache.Free; end;
end;

procedure CacheZero(AContext: TNXTestContext);
var lCache: TCache;
begin
  lCache := TCache.Create(3);
  try
    lCache.SlotCount := 0;
    CheckCacheLinks(AContext, lCache);
  finally lCache.Free; end;
end;

procedure CacheGrowEmpty(AContext: TNXTestContext);
var lCache: TCache;
begin
  lCache := TCache.Create(0);
  try
    lCache.SlotCount := 4;
    CheckCacheLinks(AContext, lCache);
    lCache.SlotCount := 0;
    lCache.SlotCount := 2;
    CheckCacheLinks(AContext, lCache);
  finally lCache.Free; end;
end;

procedure ASCII85EncodeVectors(AContext: TNXTestContext);
var lIndex: Integer;
begin
  for lIndex := Low(cASCII85Vectors) to High(cASCII85Vectors) do
    AContext.AssertEquals(cASCII85Vectors[lIndex].Encoded,
      Encode85(HexBytes(cASCII85Vectors[lIndex].Hex)), 'Independent vector ' + IntToStr(lIndex));
end;

procedure ASCII85Wrap(AContext: TNXTestContext);
var lEncoded, lDigits: string; lLines: TStringList; lIndex: Integer;
begin
  lEncoded := Encode85('abcdefghijkl', 1);
  lLines := TStringList.Create;
  try
    lLines.Text := lEncoded;
    lDigits := '';
    for lIndex := 0 to lLines.Count - 1 do
    begin
      AContext.AssertTrue(Length(lLines[lIndex]) <= 1, 'Requested line width');
      lDigits := lDigits + lLines[lIndex];
    end;
    AContext.AssertEquals('@:E_WAS,RgBkhF"', lDigits, 'Wrapping retains all encoded digits');
  finally lLines.Free; end;
end;

procedure ASCII85DecodeVectors(AContext: TNXTestContext);
var lIndex: Integer;
begin
  for lIndex := Low(cASCII85Vectors) to High(cASCII85Vectors) do
    AContext.AssertEquals(string(HexBytes(cASCII85Vectors[lIndex].Hex)),
      string(Decode85(cASCII85Vectors[lIndex].Encoded)), 'Independent vector ' + IntToStr(lIndex));
end;

procedure ASCII85RingCapacity(AContext: TNXTestContext);
var lRing: TASCII85RingBuffer; lInput, lOutput: array[0..1023] of Byte;
begin
  FillChar(lInput, SizeOf(lInput), $5A);
  lRing := TASCII85RingBuffer.Create;
  try
    lRing.Write(lInput, SizeOf(lInput));
    AContext.AssertEquals(1024, lRing.FillCount, 'Full is a legitimate buffer state');
    AContext.AssertEquals(1024, lRing.Read(lOutput, SizeOf(lOutput)));
    AContext.AssertTrue(CompareMem(@lInput, @lOutput, SizeOf(lInput)), 'Full-buffer contents');
  finally lRing.Free; end;
end;

procedure URIEncoding(AContext: TNXTestContext);
begin
  AContext.AssertEquals('file:///tmp/a%20b%25c', FilenameToURI('/tmp/a b%c'));
end;

procedure URIRoundtrip(AContext: TNXTestContext);
var lFilename: string;
begin
  AContext.AssertTrue(URIToFilename(FilenameToURI('/tmp/a b%c'), lFilename));
  AContext.AssertEquals('/tmp/a b%c', lFilename);
end;

procedure URIMalformedEscapes(AContext: TNXTestContext);
const cInvalid: array[0..3] of string = ('%', '%2', '%GG', '%2Z');
var lIndex: Integer; lRaised: Boolean; lURI: TURI;
begin
  for lIndex := Low(cInvalid) to High(cInvalid) do
  begin
    lRaised := False;
    try
      lURI := ParseURI('file:///tmp/' + cInvalid[lIndex]);
    except
      on EConvertError do lRaised := True;
    end;
    AContext.AssertTrue(lRaised, 'Malformed percent escape is rejected: ' + cInvalid[lIndex]);
  end;
end;

procedure BufferedSparseGap(AContext: TNXTestContext);
var lFilename: string; lFile: TFileStream; lStream: TBufferedFileStream;
  lData: array[0..20] of Byte; lIndex: Integer;
begin
  lFilename := GetTempFileName(GetTempDir(False), 'fcb');
  try
    FillChar(lData, SizeOf(lData), $A5);
    lFile := TFileStream.Create(lFilename, fmCreate);
    try lFile.WriteBuffer(lData, 16); finally lFile.Free; end;
    lStream := TBufferedFileStream.Create(lFilename, fmOpenReadWrite);
    try
      lStream.InitializeCache(16, 1);
      lStream.ReadBuffer(lData, 16);
      lStream.Position := 20;
      lStream.WriteByte($5A);
      lStream.Flush;
    finally lStream.Free; end;
    lFile := TFileStream.Create(lFilename, fmOpenRead);
    try lFile.ReadBuffer(lData, SizeOf(lData)); finally lFile.Free; end;
    for lIndex := 0 to 15 do AContext.AssertEquals($A5, lData[lIndex]);
    for lIndex := 16 to 19 do AContext.AssertEquals(0, lData[lIndex], 'Sparse file gap is zero');
    AContext.AssertEquals($5A, lData[20]);
  finally DeleteFile(lFilename); end;
end;

procedure EmptyFormatting(AContext: TNXTestContext);
var lOutput: TStringStream; lWriter: TFormattingWriter;
begin
  lOutput := TStringStream.Create('');
  try
    lWriter := TFormattingWriter.Create(lOutput);
    try lWriter.Write(''); finally lWriter.Free; end;
    AContext.AssertEquals('', lOutput.DataString);
  finally lOutput.Free; end;
end;

type
  TDefinitionWriter = class(TFormattingWriter)
  public
    procedure DefinitionItem(const AName, AText: string); override;
  end;

procedure TDefinitionWriter.DefinitionItem(const AName, AText: string);
begin
  DumpLn('[' + AName + ']=' + AText);
end;

procedure DefinitionTerms(AContext: TNXTestContext);
var lOutput: TStringStream; lWriter: TDefinitionWriter; lList: TStringList;
begin
  lOutput := TStringStream.Create('');
  lWriter := TDefinitionWriter.Create(lOutput);
  lList := TStringList.Create;
  try
    lList.Add('first=value');
    lList.Add('unnamed');
    lWriter.WriteList(ltDefinition, lList);
    AContext.AssertEquals('[first]=value' + LineEnding + '[]=unnamed' + LineEnding, lOutput.DataString);
  finally lList.Free; lWriter.Free; lOutput.Free; end;
end;

procedure Base64MIMESize(AContext: TNXTestContext);
var lInput: TStringStream; lDecoder: TBase64DecodingStream; lData: array[0..3] of Byte;
begin
  lInput := TStringStream.Create('Zg==' + StringOfChar('A', 2048));
  lDecoder := TBase64DecodingStream.Create(lInput, bdmMIME);
  try
    AContext.AssertEquals(Int64(1), lDecoder.Size, 'First padding marker ends MIME data');
    AContext.AssertEquals(Int64(0), lInput.Position, 'Size query preserves source position');
    AContext.AssertEquals(1, lDecoder.Read(lData, SizeOf(lData)));
    AContext.AssertEquals(Ord('f'), lData[0]);
  finally lDecoder.Free; lInput.Free; end;
end;

procedure Base64Control(AContext: TNXTestContext);
begin
  AContext.AssertEquals('Zm9vYmFy', EncodeStringBase64('foobar'));
  AContext.AssertEquals('foobar', DecodeStringBase64('Zm9vYmFy', True));
end;

type
  TPublishedStrings = class(TPersistent)
  private
    FItems: TStrings;
  public
    constructor Create;
    destructor Destroy; override;
  published
    property Items: TStrings read FItems;
  end;
  TStorageValues = class
  private
    FValues: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    function ReadValue(const ASection, AItem, ADefault: string): string;
    procedure WriteValue(const ASection, AItem, AValue: string);
  end;

constructor TPublishedStrings.Create;
begin inherited Create; FItems := TStringList.Create; end;
destructor TPublishedStrings.Destroy;
begin FItems.Free; inherited Destroy; end;
constructor TStorageValues.Create;
begin inherited Create; FValues := TStringList.Create; end;
destructor TStorageValues.Destroy;
begin FValues.Free; inherited Destroy; end;
function TStorageValues.ReadValue(const ASection, AItem, ADefault: string): string;
var lIndex: Integer;
begin
  lIndex := FValues.IndexOfName(ASection + '|' + AItem);
  if lIndex < 0 then Result := ADefault else Result := FValues.ValueFromIndex[lIndex];
end;
procedure TStorageValues.WriteValue(const ASection, AItem, AValue: string);
begin FValues.Values[ASection + '|' + AItem] := AValue; end;

procedure StoredStrings(AContext: TNXTestContext; AEmpty: Boolean);
var lObject: TPublishedStrings; lStorage: TPropsStorage; lValues: TStorageValues;
begin
  lObject := TPublishedStrings.Create;
  lStorage := TPropsStorage.Create;
  lValues := TStorageValues.Create;
  try
    lStorage.AObject := lObject;
    lStorage.Section := 'Settings';
    lStorage.Options := [psoAlwaysStoreStringsCount];
    lStorage.OnReadString := @lValues.ReadValue;
    lStorage.OnWriteString := @lValues.WriteValue;
    if not AEmpty then lObject.Items.Add('saved');
    lStorage.StoreAnyProperty(GetPropInfo(lObject, 'Items'));
    lObject.Items.Clear;
    lObject.Items.Add('stale');
    lStorage.LoadAnyProperty(GetPropInfo(lObject, 'Items'));
    if AEmpty then AContext.AssertEquals(0, lObject.Items.Count, 'Explicit stored zero clears stale items')
    else AContext.AssertEquals('saved', lObject.Items[0], 'Nonempty list is restored');
  finally lValues.Free; lStorage.Free; lObject.Free; end;
end;

procedure StoredEmptyStrings(AContext: TNXTestContext);
begin StoredStrings(AContext, True); end;
procedure StoredNonemptyStrings(AContext: TNXTestContext);
begin StoredStrings(AContext, False); end;

procedure ValueListClear(AContext: TNXTestContext);
var lMediator: TBaseMediator; lList: TObjectList;
begin
  lMediator := TBaseMediator.Create(nil);
  lList := TObjectList.Create(False);
  try
    lMediator.ValueList := lList;
    lMediator.ValueList := nil;
    AContext.AssertTrue(lMediator.ValueList = nil, 'Detached value list');
  finally lList.Free; lMediator.Free; end;
end;

procedure ValueListReplace(AContext: TNXTestContext);
var lMediator: TBaseMediator; lFirst, lSecond: TObjectList;
begin
  lMediator := TBaseMediator.Create(nil);
  lFirst := TObjectList.Create(False);
  lSecond := TObjectList.Create(False);
  try
    lMediator.ValueList := lFirst;
    lMediator.ValueList := lSecond;
    AContext.AssertTrue(lMediator.ValueList = lSecond, 'Replacement value list');
    lFirst.Clear;
  finally lFirst.Free; lSecond.Free; lMediator.Free; end;
end;

function MakeMO(AEmpty, AHashed: Boolean): TMemoryStream;
var lHeader: TMOFileHeader; lOriginal, lTranslation: TMOStringInfo;
  lHashTable: array[0..2] of LongWord;
const cOriginal: RawByteString = 'hello'#0; cTranslation: RawByteString = 'bonjour'#0;
begin
  Result := TMemoryStream.Create;
  FillChar(lHeader, SizeOf(lHeader), 0);
  lHeader.magic := MOFileHeaderMagic;
  lHeader.OrigTabOffset := SizeOf(lHeader);
  lHeader.TransTabOffset := lHeader.OrigTabOffset;
  lHeader.HashTabOffset := lHeader.OrigTabOffset;
  if not AEmpty then
  begin
    lHeader.nstrings := 1;
    Inc(lHeader.TransTabOffset, SizeOf(lOriginal));
    lHeader.HashTabOffset := lHeader.TransTabOffset + SizeOf(lTranslation);
    if AHashed then lHeader.HashTabSize := 3;
    lOriginal.length := Length(cOriginal) - 1;
    lOriginal.offset := lHeader.HashTabOffset + lHeader.HashTabSize * SizeOf(LongWord);
    lTranslation.length := Length(cTranslation) - 1;
    lTranslation.offset := lOriginal.offset + Length(cOriginal);
  end;
  Result.WriteBuffer(lHeader, SizeOf(lHeader));
  if not AEmpty then
  begin
    Result.WriteBuffer(lOriginal, SizeOf(lOriginal));
    Result.WriteBuffer(lTranslation, SizeOf(lTranslation));
    if AHashed then
    begin
      FillChar(lHashTable, SizeOf(lHashTable), 0);
      lHashTable[Hash('hello') mod 3] := 1;
      Result.WriteBuffer(lHashTable, SizeOf(lHashTable));
    end;
    Result.WriteBuffer(cOriginal[1], Length(cOriginal));
    Result.WriteBuffer(cTranslation[1], Length(cTranslation));
  end;
  Result.Position := 0;
end;

procedure Catalog(AContext: TNXTestContext; AEmpty, AHashed: Boolean);
var lInput: TMemoryStream; lCatalog: TMOFile;
begin
  lInput := MakeMO(AEmpty, AHashed);
  try
    lCatalog := TMOFile.Create(lInput);
    try
      if AEmpty then AContext.AssertEquals('', string(lCatalog.Translate('hello')))
      else AContext.AssertEquals('bonjour', string(lCatalog.Translate('hello')));
      AContext.AssertEquals('', string(lCatalog.Translate('missing')), 'Missing translation');
    finally lCatalog.Free; end;
  finally lInput.Free; end;
end;
procedure HashlessCatalog(AContext: TNXTestContext);
begin Catalog(AContext, False, False); end;
procedure EmptyCatalog(AContext: TNXTestContext);
begin Catalog(AContext, True, False); end;
procedure HashedCatalog(AContext: TNXTestContext);
begin Catalog(AContext, False, True); end;

procedure RegisterFCLBaseReviewTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
  procedure Add(const AName: string; AProcedure: TNXTestProcedure; const ACategory: string);
  begin
    if (ParamCount = 0) or SameText(ParamStr(1), AName) then
      lSuite.AddTest(AName, AProcedure, ACategory);
  end;
begin
  lSuite := ARegistry.AddSuite('FCL.Base.Review');
  Add('NullWriteCount', @NullWriteCount, 'FCLB-001');
  Add('NullSeekReturn', @NullSeekReturn, 'FCLB-002');
  Add('NullSeekEnd', @NullSeekEnd, 'FCLB-002');
  Add('NullReadControl', @NullReadControl, 'control');
  Add('CacheGrow', @CacheGrow, 'FCLB-003');
  Add('CacheShrink', @CacheShrink, 'FCLB-003');
  Add('CacheZero', @CacheZero, 'FCLB-003');
  Add('CacheGrowEmpty', @CacheGrowEmpty, 'FCLB-003');
  Add('ASCII85EncodeVectors', @ASCII85EncodeVectors, 'FCLB-004');
  Add('ASCII85Wrap', @ASCII85Wrap, 'FCLB-005');
  Add('ASCII85DecodeVectors', @ASCII85DecodeVectors, 'control');
  Add('ASCII85RingCapacity', @ASCII85RingCapacity, 'FCLB-007');
  Add('URIEncoding', @URIEncoding, 'control');
  Add('URIRoundtrip', @URIRoundtrip, 'control');
  Add('URIMalformedEscapes', @URIMalformedEscapes, 'FCLB-009');
  Add('BufferedSparseGap', @BufferedSparseGap, 'FCLB-010');
  Add('EmptyFormatting', @EmptyFormatting, 'FCLB-011');
  Add('DefinitionTerms', @DefinitionTerms, 'FCLB-012');
  Add('Base64MIMESize', @Base64MIMESize, 'FCLB-013');
  Add('Base64Control', @Base64Control, 'control');
  Add('StoredEmptyStrings', @StoredEmptyStrings, 'FCLB-014');
  Add('StoredNonemptyStrings', @StoredNonemptyStrings, 'control');
  Add('ValueListClear', @ValueListClear, 'FCLB-015');
  Add('ValueListReplace', @ValueListReplace, 'FCLB-015');
  Add('HashlessCatalog', @HashlessCatalog, 'FCLB-016');
  Add('EmptyCatalog', @EmptyCatalog, 'FCLB-016');
  Add('HashedCatalog', @HashedCatalog, 'control');
end;
end.

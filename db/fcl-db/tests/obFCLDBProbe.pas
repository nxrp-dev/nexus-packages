// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit obFCLDBProbe;
{$mode objfpc}{$H+}{$codepage utf8}
interface
uses obNXTestContext;
procedure RunFCLDBProbe(AId: Integer; const ADirectory: string; AContext: TNXTestContext);
implementation
uses Classes, SysUtils, Variants, DateUtils, DB, BufDataset, MemDS,
  FPJSON, JSONParser, FPJSONDataset, FPDBExport, FPSimpleJSONExport,
  FPCSVExport, FPFixedExport, FPSQLExport, FieldMap, SQLDBPool;
type
  TTestFieldMap = class(TFieldMap)
  public
    procedure InitFields; override;
  end;
  TOpenObserver = class
  private FCount: Integer;
  public
    procedure Opened(ADataset: TDataSet);
    property Count: Integer read FCount;
  end;
  TShortHeaderStream = class(TMemoryStream)
  private FFirst: Boolean;
  public
    constructor Create;
    function Write(const ABuffer; ACount: LongInt): LongInt; override;
  end;
  TZeroReadStream = class(TMemoryStream)
  public
    function Read(var ABuffer; ACount: LongInt): LongInt; override;
  end;

procedure TTestFieldMap.InitFields;
begin
end;
procedure TOpenObserver.Opened(ADataset: TDataSet);
begin
  Inc(FCount);
end;
constructor TShortHeaderStream.Create;
begin
  inherited Create;
  FFirst:=True;
end;
function TShortHeaderStream.Write(const ABuffer; ACount: LongInt): LongInt;
begin
  if FFirst and (ACount>0) then
  begin Dec(ACount); FFirst:=False; end;
  Result:=inherited Write(ABuffer,ACount);
end;
function TZeroReadStream.Read(var ABuffer; ACount: LongInt): LongInt;
begin
  if ACount>0 then FillChar(ABuffer,ACount,0);
  Result:=0;
end;

function NewMem(AType: TFieldType; ASize: Integer = 0): TMemDataset;
begin
  Result:=TMemDataset.Create(nil);
  Result.FieldDefs.Add('value',AType,ASize);
  Result.CreateTable; Result.Open;
end;
function NewJSON(AType: TFieldType; ASize: Integer = 0): TJSONDataset;
begin
  Result:=TJSONDataset.Create(nil);
  Result.OwnsData:=True;
  Result.FieldDefs.Add('value',AType,ASize);
  Result.Rows:=TJSONArray.Create;
end;
procedure AddJSON(AData: TJSONDataset; AValue: TJSONData);
var lRow: TJSONObject;
begin
  lRow:=TJSONObject.Create;
  lRow.Add('value',AValue);
  AData.Rows.Add(lRow);
end;
function ExportText(AExporter: TCustomFileExporter; AData: TDataSet): RawByteString;
var lStream: TStringStream;
begin
  lStream:=TStringStream.Create('');
  try
    AExporter.FileName:='fixture-output';
    AExporter.Dataset:=AData;
    AExporter.FromCurrent:=False;
    AExporter.ExportToStream(lStream);
    Result:=lStream.DataString;
  finally lStream.Free; end;
end;

procedure ProbeJSONExport(AId: Integer; AContext: TNXTestContext);
var
  lData: TMemDataset;
  lExporter: TSimpleJSONExporter;
  lJSON: TJSONData;
  lText: RawByteString;
  lRowFormat,lColumnFormat: Integer;
begin
  lData:=NewMem(ftString,100); lExporter:=TSimpleJSONExporter.Create(nil);
  try
    if AId=1 then
    begin
      lData.AppendRecord(['first']); lData.AppendRecord(['second']);
      for lRowFormat:=0 to 1 do
        for lColumnFormat:=0 to 1 do
        begin
          lExporter.FormatSettings.RowFormat:=TJSONRowFormat(lRowFormat);
          lExporter.FormatSettings.ColumnFormat:=TJSONColumnFormat(lColumnFormat);
          lText:=ExportText(lExporter,lData); lJSON:=GetJSON(lText);
          try AContext.AssertEquals(2,lJSON.Count,'Exported rows');
          finally lJSON.Free; end;
        end;
      lData.First;
      while not lData.IsEmpty do lData.Delete;
      lText:=ExportText(lExporter,lData); lJSON:=GetJSON(lText);
      try AContext.AssertEquals(0,lJSON.Count); finally lJSON.Free; end;
    end
    else
    begin
      lData.AppendRecord(['a'+#1+'b']);
      lExporter.ExportFields.AddField('value').ExportedName:='quoted"name';
      lExporter.FormatSettings.RowFormat:=rfObject;
      lExporter.FormatSettings.RowElementName:='row"';
      lText:=ExportText(lExporter,lData);
      AContext.AssertTrue(Pos('\u0001',lText)>0,'JSON control byte was not escaped');
      AContext.AssertTrue(Pos('quoted\"name',lText)>0,'JSON column name was not escaped');
      AContext.AssertTrue(Pos('row\"1',lText)>0,'JSON row name was not escaped');
      lJSON:=GetJSON(lText);
      try AContext.AssertEquals('a'+#1+'b',lJSON.Items[0].Items[0].AsString);
      finally lJSON.Free; end;
    end;
  finally lExporter.Free; lData.Free; end;
end;

procedure ProbeIntegerExport(AContext: TNXTestContext);
var lData: TMemDataset; lExporter: TCSVExporter; lText: RawByteString;
begin
  lData:=NewMem(ftLargeInt); lExporter:=TCSVExporter.Create(nil);
  try
    lData.Append; lData.Fields[0].AsLargeInt:=High(Int64); lData.Post;
    lExporter.FormatSettings.IntegerFormat:='%d';
    lText:=ExportText(lExporter,lData);
    AContext.AssertTrue(Pos(IntToStr(High(Int64)),lText)>0,'Int64 value narrowed during export');
  finally lExporter.Free; lData.Free; end;
end;

procedure ProbeCSVAssignment(AContext: TNXTestContext);
var lSource,lTarget: TCSVFormatSettings;
begin
  lSource:=TCSVFormatSettings.Create(False); lTarget:=TCSVFormatSettings.Create(False);
  try
    lSource.IgnoreOuterWhitespace:=True; lTarget.Assign(lSource);
    AContext.AssertTrue(lTarget.IgnoreOuterWhitespace,'Assign lost IgnoreOuterWhitespace');
  finally lTarget.Free; lSource.Free; end;
end;

procedure ProbeFieldMap(AContext: TNXTestContext);
var lData: TMemDataset; lMap: TTestFieldMap; lObserver: TOpenObserver;
begin
  lData:=NewMem(ftInteger); lObserver:=TOpenObserver.Create;
  try
    lData.Close; lData.AfterOpen:=@lObserver.Opened;
    lMap:=TTestFieldMap.Create(lData,True);
    try lData.Open; AContext.AssertEquals(1,lObserver.Count);
    finally lMap.Free; end;
    AContext.AssertTrue(TMethod(lData.AfterOpen).Data=Pointer(lObserver),
      'Freed field map remains registered as AfterOpen');
    lData.Close; lData.Open; AContext.AssertEquals(2,lObserver.Count);
    // A replacement callback must not be overwritten by map destruction.
    lMap:=TTestFieldMap.Create(lData,True);
    lData.AfterOpen:=nil; lMap.Free;
    AContext.AssertFalse(Assigned(lData.AfterOpen));
  finally lData.Free; lObserver.Free; end;
end;

procedure ProbeJSONComparisons(AContext: TNXTestContext);
var lData: TJSONDataset; lDate: TDateTime; lExpected: Double;
begin
  lData:=NewJSON(ftFloat);
  try
    AddJSON(lData,TJSONFloatNumber.Create(1.1)); AddJSON(lData,TJSONFloatNumber.Create(1.2));
    lData.Open;
    AContext.AssertTrue(lData.Locate('value',1.2,[]));
    lExpected:=1.2;
    AContext.AssertTrue(lData.Fields[0].AsFloat=lExpected,'Fractional comparison selected a different value');
  finally lData.Free; end;
  lData:=NewJSON(ftLargeInt);
  try
    AddJSON(lData,TJSONInt64Number.Create(0)); AddJSON(lData,TJSONInt64Number.Create(Int64(4294967296)));
    lData.Open;
    AContext.AssertTrue(lData.Locate('value',Int64(4294967296),[]));
    AContext.AssertEquals('4294967296',IntToStr(lData.Fields[0].AsLargeInt));
  finally lData.Free; end;
  lData:=NewJSON(ftDateTime);
  try
    AddJSON(lData,TJSONString.Create('2026-01-01 00:00:00'));
    AddJSON(lData,TJSONString.Create('2026-01-01 06:00:00'));
    lData.Open;
    TJSONDateTimeField(lData.Fields[0]).DateTimeFormat:='yyyy-mm-dd hh:nn:ss';
    lDate:=EncodeDate(2026,1,1)+EncodeTime(6,0,0,0);
    AContext.AssertTrue(lData.Locate('value',VarFromDateTime(lDate),[]));
    AContext.AssertTrue(lData.Fields[0].AsDateTime=lDate,'Date comparison rounded away the time');
  finally lData.Free; end;
end;

procedure ProbeJSONLocate(AContext: TNXTestContext);
var lData: TJSONDataset;
begin
  lData:=NewJSON(ftInteger);
  try
    AddJSON(lData,TJSONIntegerNumber.Create(10)); AddJSON(lData,TJSONIntegerNumber.Create(20));
    lData.Open; lData.Last;
    AContext.AssertTrue(lData.Locate('value',10,[]),'Locate missed a preceding row');
    AContext.AssertEquals(10,lData.Fields[0].AsInteger);
    AContext.AssertFalse(lData.Locate('value',30,[]));
  finally lData.Free; end;
end;

procedure ProbeJSONBookmarks(AContext: TNXTestContext);
var lData: TJSONDataset; lFirst,lSecond,lDuplicate: TBookmark;
begin
  lData:=NewJSON(ftInteger);
  try
    AddJSON(lData,TJSONIntegerNumber.Create(10)); AddJSON(lData,TJSONIntegerNumber.Create(20));
    lData.Open; lFirst:=lData.GetBookmark; lDuplicate:=lData.GetBookmark;
    lData.Next; lSecond:=lData.GetBookmark;
    try
      AContext.AssertTrue(lData.BookmarkValid(lFirst),'A captured bookmark is invalid');
      AContext.AssertEquals(0,lData.CompareBookmarks(lFirst,lDuplicate),'Same row bookmarks differ');
      AContext.AssertTrue(lData.CompareBookmarks(lFirst,lSecond)<0,'Bookmark order is reversed');
      AContext.AssertFalse(lData.BookmarkValid(nil));
      lData.GotoBookmark(lFirst); lData.Delete;
      AContext.AssertFalse(lData.BookmarkValid(lFirst),'Deleted row bookmark remains valid');
      AContext.AssertTrue(lData.BookmarkValid(lSecond));
    finally lData.FreeBookmark(lSecond); lData.FreeBookmark(lDuplicate); lData.FreeBookmark(lFirst); end;
  finally lData.Free; end;
end;

procedure ProbeComparerItems(AContext: TNXTestContext);
var lData: TJSONDataset; lComparer: TRecordComparer;
begin
  lData:=NewJSON(ftInteger);
  try
    AddJSON(lData,TJSONIntegerNumber.Create(10)); lData.Open;
    lComparer:=TRecordComparer.Create(lData,'value',10,[]);
    try AContext.AssertTrue(Assigned(lComparer.Items[0]),'Missing comparer');
    finally lComparer.Free; end;
  finally lData.Free; end;
end;

procedure ProbeJSONBuffers(AContext: TNXTestContext);
var
  lData: TJSONDataset;
  lBuffer: array[0..63] of Byte;
  lIndex,lSize: Integer;
  lWide: UnicodeString;
begin
  lData:=NewJSON(ftString,3);
  try
    AddJSON(lData,TJSONString.Create('abcdefgh')); lData.Open;
    FillChar(lBuffer,SizeOf(lBuffer),$A5); lSize:=lData.Fields[0].DataSize;
    lData.GetFieldData(lData.Fields[0],@lBuffer,True);
    for lIndex:=lSize to High(lBuffer) do
      AContext.AssertEquals($A5,lBuffer[lIndex],'String exceeded its declared field buffer');
    AContext.AssertEquals(0,lBuffer[lSize-1],'Missing string terminator');
  finally lData.Free; end;
  lData:=NewJSON(ftWideString,3);
  try
    AddJSON(lData,TJSONString.Create('é')); lData.Open;
    FillChar(lBuffer,SizeOf(lBuffer),$A5);
    lData.GetFieldData(lData.Fields[0],@lBuffer,True);
    AContext.AssertEquals(0,lBuffer[2]); AContext.AssertEquals(0,lBuffer[3],'Wide terminator is incomplete');
    lData.Edit; lWide:='é'; lData.Fields[0].AsWideString:=lWide; lData.Post;
    AContext.AssertEquals(UTF8Encode(lWide),lData.Rows[0].FindPath('value').AsString,'Wide string stored NUL padding');
  finally lData.Free; end;
  lData:=NewJSON(ftSmallint);
  try
    AddJSON(lData,TJSONIntegerNumber.Create(-12)); lData.Open;
    FillChar(lBuffer,SizeOf(lBuffer),$A5); lSize:=lData.Fields[0].DataSize;
    lData.GetFieldData(lData.Fields[0],@lBuffer,True);
    for lIndex:=lSize to High(lBuffer) do
      AContext.AssertEquals($A5,lBuffer[lIndex],'Smallint exceeded its field buffer');
    AContext.AssertEquals(-12,lData.Fields[0].AsInteger);
    lData.Edit; lData.Fields[0].AsInteger:=-13; lData.Post;
    AContext.AssertEquals(-13,lData.Rows[0].FindPath('value').AsInteger);
  finally lData.Free; end;
end;

procedure ProbeWordBuffer(AContext: TNXTestContext);
var lData: TJSONDataset; lBuffer: array[0..7] of Byte; lIndex: Integer;
begin
  lData:=NewJSON(ftWord);
  try
    AddJSON(lData,TJSONIntegerNumber.Create(65500)); lData.Open;
    FillChar(lBuffer,SizeOf(lBuffer),$A5);
    lData.GetFieldData(lData.Fields[0],@lBuffer,True);
    for lIndex:=lData.Fields[0].DataSize to High(lBuffer) do
      AContext.AssertEquals($A5,lBuffer[lIndex],'Word exceeded its field buffer');
    AContext.AssertEquals(65500,lData.Fields[0].AsInteger);
    lData.Edit; lData.Fields[0].AsInteger:=65501; lData.Post;
    AContext.AssertEquals(65501,lData.Rows[0].FindPath('value').AsInteger);
  finally lData.Free; end;
end;

procedure ProbeMissingLookup(AContext: TNXTestContext);
var lData: TJSONDataset; lValue: Variant;
begin
  lData:=NewJSON(ftInteger);
  try
    AddJSON(lData,TJSONIntegerNumber.Create(10)); lData.Open;
    lValue:=lData.Lookup('value',99,'value');
    AContext.AssertTrue(VarIsNull(lValue),'Missing Lookup returned a non-null value');
    lValue:=lData.Lookup('value',10,'value'); AContext.AssertEquals(10,Integer(lValue));
    AContext.AssertEquals(10,lData.Fields[0].AsInteger,'Lookup moved the cursor');
  finally lData.Free; end;
end;

procedure CheckBlob(AData: TDataSet; AContext: TNXTestContext);
var lStream: TStream; lBuffer: array[0..5] of AnsiChar; lData: RawByteString;
begin
  lStream:=AData.CreateBlobStream(AData.Fields[0],bmWrite);
  try
    lData:='abcdef'; lStream.WriteBuffer(lData[1],Length(lData));
    lStream.Position:=2; lData:='XY'; lStream.WriteBuffer(lData[1],2);
    AContext.AssertEquals(6,Integer(lStream.Size),'Overwrite changed blob size');
    lStream.Position:=0; lStream.ReadBuffer(lBuffer,SizeOf(lBuffer));
    SetString(lData,PAnsiChar(@lBuffer),SizeOf(lBuffer));
    AContext.AssertEquals('abXYef',lData,'Overwrite damaged the untouched suffix');
    lStream.Position:=8; lData:='Z'; lStream.WriteBuffer(lData[1],1);
    AContext.AssertEquals(9,Integer(lStream.Size),'Gap extension has the wrong size');
    lStream.Position:=6; lStream.ReadBuffer(lBuffer,3);
    AContext.AssertEquals(0,Ord(lBuffer[0])); AContext.AssertEquals(0,Ord(lBuffer[1]));
    AContext.AssertEquals(Ord('Z'),Ord(lBuffer[2]));
    lStream.Position:=20;
    AContext.AssertEquals(0,lStream.Read(lBuffer,1),'Read past EOF did not return zero');
  finally lStream.Free; end;
  AData.Post;
end;

procedure ProbeBufferedBlob(AContext: TNXTestContext);
var lData: TBufDataset;
begin
  lData:=TBufDataset.Create(nil);
  try
    lData.FieldDefs.Add('value',ftBlob); lData.CreateDataset;
    lData.Append; CheckBlob(lData,AContext);
  finally lData.Free; end;
end;

procedure ProbeBlobStreams(AContext: TNXTestContext);
var lData: TMemDataset;
begin
  lData:=NewMem(ftBlob);
  try lData.Append; CheckBlob(lData,AContext); finally lData.Free; end;
  ProbeBufferedBlob(AContext);
end;

procedure ProbePoolOwner(AContext: TNXTestContext);
var lOwner: TComponent; lPool: TSQLDBConnectionPool;
begin
  lOwner:=TComponent.Create(nil); lPool:=TSQLDBConnectionPool.Create(lOwner);
  try
    AContext.AssertTrue(lPool.Owner=lOwner,'Pool ignored its component owner');
    AContext.AssertEquals(1,lOwner.ComponentCount);
  finally
    if lPool.Owner=nil then lPool.Free;
    lOwner.Free;
  end;
end;

procedure ProbeBinaryTransfers(AContext: TNXTestContext);
var
  lData: TBufDataset; lStream: TShortHeaderStream;
  lEmpty: TZeroReadStream; lReader: TFpcBinaryDatapacketHandler;
  lRejected: Boolean; lOrder: Integer; lSignature: RawByteString;
begin
  lData:=TBufDataset.Create(nil); lStream:=TShortHeaderStream.Create;
  try
    lData.FieldDefs.Add('value',ftInteger); lData.CreateDataset;
    lData.AppendRecord([12]); lRejected:=False;
    try lData.SaveToStream(lStream,dfBinary);
    except on lError: EWriteError do lRejected:=True; end;
    if not lRejected then
    begin
      lStream.Position:=0; SetLength(lSignature,13);
      lStream.ReadBuffer(lSignature[1],13);
      AContext.AssertEquals('BinBufDataSet',lSignature,'Partial write silently damaged the packet signature');
    end;
    lEmpty:=TZeroReadStream.Create;
    lReader:=TFpcBinaryDatapacketHandler.Create(lData,lEmpty);
    try
      lRejected:=False;
      try lReader.GetRecordRowState(lOrder);
      except on lError: EReadError do lRejected:=True; end;
      AContext.AssertTrue(lRejected,'Missing binary packet row state was accepted');
    finally lReader.Free; lEmpty.Free; end;
  finally lStream.Free; lData.Free; end;
end;

procedure ProbeSQLNull(AContext: TNXTestContext);
var lData: TMemDataset; lExporter: TSQLExporter; lText: RawByteString;
begin
  lData:=NewMem(ftString,20); lExporter:=TSQLExporter.Create(nil);
  try
    lData.Append; lData.Post;
    lExporter.FormatSettings.TableName:='items';
    lText:=ExportText(lExporter,lData);
    AContext.AssertTrue(Pos('VALUES (NULL)',UpperCase(lText))>0,'SQL NULL became an empty string');
  finally lExporter.Free; lData.Free; end;
end;

procedure ProbeUTF16(AContext: TNXTestContext);
var lData: TMemDataset; lExporter: TFixedLengthExporter; lText: RawByteString;
  lExpected: UnicodeString; lBytes: TBytes; lIndex: Integer;
begin
  lData:=NewMem(ftString,3); lExporter:=TFixedLengthExporter.Create(nil);
  try
    lData.AppendRecord(['ABC']); lData.AppendRecord(['DEF']);
    lExporter.FormatSettings.CharMode:=cmUTF16;
    lExporter.FormatSettings.HeaderRow:=True;
    lExporter.Dataset:=lData;
    lExporter.BuildDefaultFieldMap(lExporter.ExportFields);
    lExporter.ExportFields[0].ExportedName:='éx';
    lText:=ExportText(lExporter,lData);
    AContext.AssertTrue(Length(lText)>1,'Missing UTF16 data');
    AContext.AssertEquals($FF,Byte(lText[1]),'Missing UTF16LE BOM');
    AContext.AssertEquals($FE,Byte(lText[2]));
    lExpected:='éx '+UnicodeString(LineEnding)+'ABC'+UnicodeString(LineEnding)+'DEF'+UnicodeString(LineEnding);
    lBytes:=TEncoding.Unicode.GetBytes(lExpected);
    AContext.AssertEquals(Length(lBytes)+2,Length(lText));
    for lIndex:=0 to High(lBytes) do
      AContext.AssertEquals(lBytes[lIndex],Byte(lText[lIndex+3]),'UTF16 payload mismatch');
  finally lExporter.Free; lData.Free; end;
end;

procedure RunFCLDBProbe(AId: Integer; const ADirectory: string; AContext: TNXTestContext);
begin
  case AId of
    1,2: ProbeJSONExport(AId,AContext);
    3: ProbeIntegerExport(AContext);
    4: ProbeCSVAssignment(AContext);
    5: ProbeFieldMap(AContext);
    6: ProbeJSONComparisons(AContext);
    7: ProbeJSONLocate(AContext);
    8: ProbeJSONBookmarks(AContext);
    9: ProbeComparerItems(AContext);
    10: begin ProbeJSONBuffers(AContext); ProbeWordBuffer(AContext); end;
    11: ProbeMissingLookup(AContext);
    12: ProbeBlobStreams(AContext);
    // Isolate the second implementation for supplemental original-source proof.
    112: ProbeBufferedBlob(AContext);
    13: ProbePoolOwner(AContext);
    14: ProbeBinaryTransfers(AContext);
    15: ProbeSQLNull(AContext);
    16: ProbeUTF16(AContext);
  else raise Exception.Create('Unknown FCL DB probe'); end;
end;
end.

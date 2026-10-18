// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit tsFCLRes;
{$mode objfpc}{$H+}

interface

uses obNXTestRegistry;

procedure RegisterFCLResTests(ARegistry: TNXTestRegistry);

implementation

uses
  Classes, SysUtils, obNXTestContext, obNXTestSuite,
  Resource, ResReader, ResDataStream, StrTable, FileInfo, VersionResource,
  VersionTypes, BitmapResource, GroupCursorResource, IcoCurTypes,
  MachOReader, MachOTypes, MachOConsts;

procedure WriteWord(AStream: TStream; AValue: Word);
begin
  AValue := NtoLE(AValue);
  AStream.WriteBuffer(AValue, 2);
end;

procedure WriteDWord(AStream: TStream; AValue: LongWord);
begin
  AValue := NtoLE(AValue);
  AStream.WriteBuffer(AValue, 4);
end;

procedure AlignStream(AStream: TStream);
var
  lByte: Byte;
begin
  lByte := 0;
  while AStream.Position mod 4 <> 0 do AStream.WriteBuffer(lByte, 1);
end;

procedure WriteRecord(AStream: TStream; AType, AName: Word; AData: TStream);
begin
  if AData = nil then WriteDWord(AStream, 0)
  else WriteDWord(AStream, AData.Size);
  WriteDWord(AStream, 32);
  WriteWord(AStream, $FFFF); WriteWord(AStream, AType);
  WriteWord(AStream, $FFFF); WriteWord(AStream, AName);
  WriteDWord(AStream, 0); WriteWord(AStream, 0); WriteWord(AStream, 0);
  WriteDWord(AStream, 0); WriteDWord(AStream, 0);
  if AData <> nil then
  begin
    AData.Position := 0;
    if AData.Size > 0 then AStream.CopyFrom(AData, AData.Size);
  end;
  AlignStream(AStream);
end;

function ResourceFile(AType: Word; AData: TStream): TMemoryStream;
begin
  Result := TMemoryStream.Create;
  WriteRecord(Result, 0, 0, nil);
  WriteRecord(Result, AType, 1, AData);
  Result.Position := 0;
end;

function VersionFile(AStrings: Boolean): string;
const
  cVersion: TFileProductVersion = (1, 2, 3, 4);
var
  lVersion: TVersionResource;
  lTable: TVersionStringTable;
  lFile: TMemoryStream;
  lGuid: TGUID;
begin
  CreateGUID(lGuid);
  Result := GetTempDir + 'nxres-' + GUIDToString(lGuid) + '.res';
  lVersion := TVersionResource.Create;
  try
    lVersion.FixedInfo.FileVersion := cVersion;
    if AStrings then
    begin
      lTable := TVersionStringTable.Create('040904E4');
      lTable.Add('ProductName', 'Nexus');
      lTable.Add('FileDescription', 'Resource test');
      lVersion.StringFileInfo.Add(lTable);
    end;
    lVersion.UpdateRawData;
    lFile := ResourceFile(RT_VERSION, lVersion.RawData);
    try
      lFile.SaveToFile(Result);
    finally
      lFile.Free;
    end;
  finally
    lVersion.Free;
  end;
end;

procedure TestVersionQuad(AContext: TNXTestContext);
var
  lQuad: TVersionQuad;
begin
  AContext.AssertTrue(TryStrToVersionQuad('0.1.65535.4', lQuad));
  AContext.AssertEquals(65535, lQuad[3]);
  AContext.AssertEquals('0.1.65535.4', VersionQuadToStr(lQuad));
  AContext.AssertTrue(NewerVersion('2.0.0.0', '1.65535.0.0'));
end;

procedure TestInvalidVersionQuad(AContext: TNXTestContext);
const
  cInvalid: array[0..9] of string = ('1.2.bad.4', '1.2.3.', '1.2.3.4.5',
    '1.2.-2.4', '1.2.65536.4', '1.2.3', '1..3.4', '1.2.$FF.4',
    '1.2. 3.4', '1.2.999999999999999999999.4');
var
  lText: string;
  lQuad: TVersionQuad;
begin
  for lText in cInvalid do
    AContext.AssertFalse(TryStrToVersionQuad(lText, lQuad), lText);
end;

procedure TestVersionStrings(AContext: TNXTestContext);
var
  lInfo: TFileVersionInfo;
  lFileName: string;
begin
  lFileName := VersionFile(True);
  lInfo := TFileVersionInfo.Create(nil);
  try
    lInfo.FileName := lFileName;
    lInfo.ReadFileInfo;
    AContext.AssertEquals('Nexus', lInfo.VersionStrings.Values['ProductName']);
    AContext.AssertEquals(2, lInfo.VersionStrings.Count);
  finally
    lInfo.Free;
    DeleteFile(lFileName);
  end;
end;

procedure TestVersionRefresh(AContext: TNXTestContext);
var
  lInfo: TFileVersionInfo;
  lFileName: string;
begin
  lFileName := VersionFile(True);
  lInfo := TFileVersionInfo.Create(nil);
  try
    lInfo.FileName := lFileName;
    lInfo.ReadFileInfo;
    lInfo.ReadFileInfo;
    AContext.AssertEquals(2, lInfo.VersionStrings.Count);
    lInfo.Filter.Add('ProductName');
    AContext.AssertEquals(1, lInfo.VersionStrings.Count);
    AContext.AssertEquals('Nexus', lInfo.VersionStrings.Values['ProductName']);
  finally
    lInfo.Free;
    DeleteFile(lFileName);
  end;
end;

procedure TestFixedOnlyVersion(AContext: TNXTestContext);
var
  lInfo: TFileVersionInfo;
  lFileName: string;
begin
  lFileName := VersionFile(False);
  lInfo := TFileVersionInfo.Create(nil);
  try
    lInfo.FileName := lFileName;
    lInfo.ReadFileInfo;
    AContext.AssertEquals(0, lInfo.VersionStrings.Count);
    lInfo.Enabled := False;
    lInfo.Translation := '041104E4';
    lInfo.TranslationOnly := True;
    try
      lInfo.ReadFileInfo;
    except
      on EVersionInfo do Exit;
    end;
    AContext.Fail('An explicitly required absent translation must be reported');
  finally
    lInfo.Free;
    DeleteFile(lFileName);
  end;
end;

procedure TestObjectStringAppend(AContext: TNXTestContext);
var
  lTable: TObjectStringTable;
  lFirst, lSecond, lThird: LongWord;
begin
  lTable := TObjectStringTable.Create(nil, 0);
  try
    lFirst := lTable.Add('first');
    lSecond := lTable.Add('second');
    AContext.AssertEquals('first', lTable.Get(lFirst));
    lThird := lTable.Add('third');
    AContext.AssertEquals('second', lTable.Get(lSecond));
    AContext.AssertEquals('third', lTable.Get(lThird));
  finally
    lTable.Free;
  end;
end;

procedure TestMissingRemove(AContext: TNXTestContext);
var
  lResources: TResources;
  lType, lName: TResourceDesc;
  lIndex: Integer;
begin
  lResources := TResources.Create;
  lType := TResourceDesc.Create(RT_RCDATA);
  lName := TResourceDesc.Create(7);
  try
    for lIndex := 0 to 1 do
    begin
      try
        if lIndex = 0 then lResources.Remove(lType, lName)
        else lResources.Remove(lType, lName, 1033);
      except
        on EResourceNotFoundException do Continue;
      end;
      AContext.Fail('Missing resource removal must report EResourceNotFoundException');
    end;
  finally
    lName.Free;
    lType.Free;
    lResources.Free;
  end;
end;

var
  gProbeDestroyed: Integer;
  gProbeError: Boolean;

type
  TProbeReader = class(TAbstractResourceReader)
  protected
    function GetExtensions: string; override;
    function GetDescription: string; override;
    procedure Load(AResources: TResources; AStream: TStream); override;
    function CheckMagic(AStream: TStream): Boolean; override;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;

constructor TProbeReader.Create;
begin
end;

destructor TProbeReader.Destroy;
begin
  Inc(gProbeDestroyed);
  inherited;
end;

function TProbeReader.GetExtensions: string;
begin
  Result := '.nxprobe';
end;

function TProbeReader.GetDescription: string;
begin
  Result := 'Reader lifecycle regression';
end;

procedure TProbeReader.Load(AResources: TResources; AStream: TStream);
begin
end;

function TProbeReader.CheckMagic(AStream: TStream): Boolean;
begin
  AStream.Position := AStream.Size;
  if gProbeError then raise EInvalidOperation.Create('Probe failure');
  raise EReadError.Create('Short probe');
  Result := False;
end;

procedure TestProbeCleanup(AContext: TNXTestContext);
var
  lStream: TMemoryStream;
  lReader: TAbstractResourceReader;
begin
  lStream := TMemoryStream.Create;
  try
    WriteDWord(lStream, 0);
    lStream.Position := 1;
    gProbeDestroyed := 0;
    gProbeError := True;
    try
      lReader := TResources.FindReader(lStream, '.nxprobe');
      lReader.Free;
      AContext.Fail('The probe exception must propagate');
    except
      on EInvalidOperation do ;
    end;
    AContext.AssertEquals(1, lStream.Position, 'Probe must restore the input cursor');
    AContext.AssertEquals(1, gProbeDestroyed, 'Probe reader must be freed');
  finally
    gProbeError := False;
    lStream.Free;
  end;
end;

procedure TestShortProbe(AContext: TNXTestContext);
var
  lStream: TMemoryStream;
  lReader: TAbstractResourceReader;
begin
  lStream := TMemoryStream.Create;
  try
    WriteWord(lStream, 0);
    lStream.Position := 1;
    try
      lReader := TResources.FindReader(lStream);
      lReader.Free;
    except
      on EResourceReaderNotFoundException do
      begin
        AContext.AssertEquals(1, lStream.Position);
        Exit;
      end;
    end;
    AContext.Fail('Unknown short input must have no reader');
  finally
    lStream.Free;
  end;
end;

procedure CheckDetach(AContext: TNXTestContext; AMove: Boolean);
var
  lSource, lDestination: TResources;
  lInput, lData: TMemoryStream;
  lResource: TAbstractResource;
  lFileName: string;
  lByte: Byte;
begin
  lFileName := VersionFile(False);
  lData := TMemoryStream.Create;
  lSource := TResources.Create;
  lDestination := TResources.Create;
  lResource := nil;
  try
    lByte := 42;
    lData.WriteBuffer(lByte, 1);
    lInput := ResourceFile(RT_RCDATA, lData);
    try lInput.SaveToFile(lFileName); finally lInput.Free; end;
    lSource.LoadFromFile(lFileName);
    if AMove then
    begin
      lDestination.MoveFrom(lSource);
      lResource := lDestination[0];
    end
    else lResource := lSource.Remove(0);
    FreeAndNil(lSource);
    lResource.RawData.Position := 0;
    lResource.RawData.ReadBuffer(lByte, 1);
    AContext.AssertEquals(42, lByte);
  finally
    if not AMove then lResource.Free;
    lDestination.Free;
    lSource.Free;
    lData.Free;
    DeleteFile(lFileName);
  end;
end;

procedure TestRemoveLifetime(AContext: TNXTestContext);
begin
  CheckDetach(AContext, False);
end;

procedure TestMoveLifetime(AContext: TNXTestContext);
begin
  CheckDetach(AContext, True);
end;

procedure TestUnpaddedPayload(AContext: TNXTestContext);
var
  lData, lFile: TMemoryStream;
  lReader: TResResourceReader;
  lResources: TResources;
  lByte: Byte;
begin
  lData := TMemoryStream.Create;
  lResources := TResources.Create;
  lReader := TResResourceReader.Create;
  try
    lByte := 42;
    lData.WriteBuffer(lByte, 1);
    lFile := ResourceFile(RT_RCDATA, lData);
    try
      lFile.Size := lFile.Size - 3; // No following resource requires padding.
      lFile.Position := 0;
      lResources.LoadFromStream(lFile, lReader);
      AContext.AssertEquals(1, lResources.Count);
      lResources[0].RawData.ReadBuffer(lByte, 1);
      AContext.AssertEquals(42, lByte);
    finally
      lResources.Clear;
      lFile.Free;
    end;
  finally
    lReader.Free;
    lResources.Free;
    lData.Free;
  end;
end;

procedure CheckInvalidRES(AContext: TNXTestContext; AKind: Integer);
var
  lStream, lData: TMemoryStream;
  lResources: TResources;
  lReader: TResResourceReader;
begin
  lData := TMemoryStream.Create;
  lReader := TResResourceReader.Create;
  lResources := TResources.Create;
  WriteDWord(lData, 1234);
  lStream := ResourceFile(RT_RCDATA, lData);
  try
    case AKind of
      0: lStream.Size := lStream.Size - 1;
      1: begin lStream.Position := lStream.Size; WriteWord(lStream, 1); end;
      2: begin lStream.Position := 36; WriteDWord(lStream, 8); end;
    end;
    lStream.Position := 0;
    try
      lResources.LoadFromStream(lStream, lReader);
    except
      on EResourceReaderException do Exit;
    end;
    AContext.Fail('Malformed RES must fail during loading');
  finally
    lResources.Free;
    lReader.Free;
    lStream.Free;
    lData.Free;
  end;
end;

procedure TestTruncatedPayload(AContext: TNXTestContext);
begin CheckInvalidRES(AContext, 0); end;
procedure TestPartialHeader(AContext: TNXTestContext);
begin CheckInvalidRES(AContext, 1); end;
procedure TestHeaderBounds(AContext: TNXTestContext);
begin CheckInvalidRES(AContext, 2); end;

procedure TestTranslations(AContext: TNXTestContext);
var
  lOriginal, lLoaded: TVersionResource;
  lTranslation: TVerTranslationInfo;
begin
  lOriginal := TVersionResource.Create;
  lLoaded := TVersionResource.Create;
  try
    lTranslation.language := $409; lTranslation.codepage := 1252;
    lOriginal.VarFileInfo.Add(lTranslation);
    lTranslation.language := $411; lTranslation.codepage := 932;
    lOriginal.VarFileInfo.Add(lTranslation);
    lOriginal.UpdateRawData;
    lOriginal.RawData.Position := 0;
    lLoaded.RawData.CopyFrom(lOriginal.RawData, lOriginal.RawData.Size);
    AContext.AssertEquals(2, lLoaded.VarFileInfo.Count);
    AContext.AssertEquals($411, lLoaded.VarFileInfo[1].language);
    AContext.AssertEquals(932, lLoaded.VarFileInfo[1].codepage);
  finally
    lLoaded.Free;
    lOriginal.Free;
  end;
end;

procedure CheckInvalidVersion(AContext: TNXTestContext; ASignature: Boolean);
var
  lOriginal, lLoaded: TVersionResource;
begin
  lOriginal := TVersionResource.Create;
  lLoaded := TVersionResource.Create;
  try
    lOriginal.FixedInfo.FileFlags := 0;
    lOriginal.UpdateRawData;
    lOriginal.RawData.Position := 0;
    lLoaded.RawData.CopyFrom(lOriginal.RawData, lOriginal.RawData.Size);
    if ASignature then
    begin
      lLoaded.RawData.Position := 40;
      WriteDWord(lLoaded.RawData, 0);
    end
    else
    begin
      lLoaded.RawData.Position := 0;
      WriteWord(lLoaded.RawData, 6);
    end;
    try
      if lLoaded.FixedInfo.FileFlags = 0 then ;
    except
      on EResourceException do Exit;
    end;
    AContext.Fail('Invalid version block must be rejected');
  finally
    lLoaded.Free;
    lOriginal.Free;
  end;
end;

procedure TestVersionSignature(AContext: TNXTestContext);
begin CheckInvalidVersion(AContext, True); end;
procedure TestVersionLength(AContext: TNXTestContext);
begin CheckInvalidVersion(AContext, False); end;

type
  TMachOProbe = class(TMachOResourceReader)
  public
    function Recognize(AStream: TStream): Boolean;
  end;

function TMachOProbe.Recognize(AStream: TStream): Boolean;
begin
  Result := CheckMagic(AStream);
end;

procedure TestFatSelection(AContext: TNXTestContext);
var
  lStream: TMemoryStream;
  lHeader: TMachFatHdr;
  lArch: TMachFarArch;
  lMach: TMachHdr;
  lSubType: TMachOSubMachineType;
  lReader: TMachOProbe;
begin
  lSubType.fX64SubType := msmx64_haswell;
  lReader := TMachOProbe.Create(mmtx86_64, lSubType);
  lStream := TMemoryStream.Create;
  try
    lHeader.magic := FAT_MAGIC;
    lHeader.nfatarch := 2;
    lStream.WriteBuffer(lHeader, SizeOf(lHeader));
    FillChar(lArch, SizeOf(lArch), 0);
    lArch.cputype := CPU_TYPE_X86_64;
    lArch.cpusubtype := CPU_SUBTYPE_X86_64_H;
    lArch.offset := 64; lArch.size := 32;
    lStream.WriteBuffer(lArch, SizeOf(lArch));
    lArch.cpusubtype := CPU_SUBTYPE_X86_64_ALL;
    lArch.offset := 96;
    lStream.WriteBuffer(lArch, SizeOf(lArch));
    lStream.Size := 128;
    FillChar(lMach, SizeOf(lMach), 0);
    lMach.magic := MH_MAGIC_64;
    lMach.cputype := CPU_TYPE_X86_64;
    lMach.cpusubtype := CPU_SUBTYPE_X86_64_H;
    lStream.Position := 64; lStream.WriteBuffer(lMach, SizeOf(lMach));
    lMach.cpusubtype := CPU_SUBTYPE_X86_64_ALL;
    lStream.Position := 96; lStream.WriteBuffer(lMach, SizeOf(lMach));
    lStream.Position := 0;
    AContext.AssertTrue(lReader.Recognize(lStream));
    AContext.AssertTrue(lReader.SubMachineType.fX64SubType = msmx64_haswell,
      'Exact subtype must win over the later generic slice');
  finally
    lStream.Free;
    lReader.Free;
  end;
end;

type
  TShortFatTableStream = class(TMemoryStream)
  public
    function Read(var ABuffer; ACount: LongInt): LongInt; override;
  end;

function TShortFatTableStream.Read(var ABuffer; ACount: LongInt): LongInt;
begin
  // A TStream.Read implementation may return fewer bytes than requested.
  if (Position = 8) and (ACount = 2 * SizeOf(TMachFarArch)) then
    ACount := SizeOf(TMachFarArch);
  Result := inherited Read(ABuffer, ACount);
end;

procedure TestFatShortRead(AContext: TNXTestContext);
var
  lStream: TShortFatTableStream;
  lReader: TMachOProbe;
  lArch: TMachFarArch;
  lMach: TMachHdr;
  lSubType: TMachOSubMachineType;
begin
  lStream := TShortFatTableStream.Create;
  lSubType.fX64SubType := msmx64_haswell;
  lReader := TMachOProbe.Create(mmtx86_64, lSubType);
  try
    WriteDWord(lStream, FAT_MAGIC);
    WriteDWord(lStream, 2);
    FillChar(lArch, SizeOf(lArch), 0);
    lArch.cputype := CPU_TYPE_X86_64;
    lArch.cpusubtype := CPU_SUBTYPE_X86_64_ALL;
    lArch.offset := 64; lArch.size := 32;
    lStream.WriteBuffer(lArch, SizeOf(lArch));
    lArch.offset := 96;
    lArch.cpusubtype := CPU_SUBTYPE_X86_64_H;
    lStream.WriteBuffer(lArch, SizeOf(lArch));
    lStream.Size := 128;
    FillChar(lMach, SizeOf(lMach), 0);
    lMach.magic := MH_MAGIC_64;
    lMach.cputype := CPU_TYPE_X86_64;
    lMach.cpusubtype := CPU_SUBTYPE_X86_64_ALL;
    lStream.Position := 64;
    lStream.WriteBuffer(lMach, SizeOf(lMach));
    lMach.cpusubtype := CPU_SUBTYPE_X86_64_H;
    lStream.Position := 96;
    lStream.WriteBuffer(lMach, SizeOf(lMach));
    lStream.Position := 0;
    AContext.AssertTrue(lReader.Recognize(lStream));
    AContext.AssertTrue(lReader.SubMachineType.fX64SubType = msmx64_haswell,
      'Short reads must not silently discard later architecture entries');
  finally
    lReader.Free;
    lStream.Free;
  end;
end;

procedure TestFatEmpty(AContext: TNXTestContext);
var
  lStream: TMemoryStream;
  lReader: TMachOProbe;
begin
  lStream := TMemoryStream.Create;
  lReader := TMachOProbe.Create;
  try
    WriteDWord(lStream, FAT_MAGIC);
    WriteDWord(lStream, 0);
    lStream.Position := 0;
    try
      lReader.Recognize(lStream);
    except
      on EResourceReaderException do Exit;
    end;
    AContext.Fail('An empty architecture table must be rejected');
  finally
    lReader.Free;
    lStream.Free;
  end;
end;

procedure TestCursor256(AContext: TNXTestContext);
var
  lCursor: TGroupCursorResource;
  lHeader: TNewHeader;
  lEntry: TCurCursorDir;
  lResourceEntry: TResCursorDir;
begin
  lCursor := TGroupCursorResource.Create;
  try
    lHeader.reserved := 0; lHeader.restype := 2; lHeader.rescount := 1;
    FillChar(lEntry, SizeOf(lEntry), 0);
    lEntry.curoffset := SizeOf(lHeader) + SizeOf(lEntry);
    lEntry.bytesincur := 4;
    lCursor.ItemData.Size := 0;
    lCursor.ItemData.WriteBuffer(lHeader, SizeOf(lHeader));
    lCursor.ItemData.WriteBuffer(lEntry, SizeOf(lEntry));
    WriteDWord(lCursor.ItemData, 1234);
    lCursor.UpdateRawData;
    lCursor.RawData.Position := SizeOf(lHeader);
    lCursor.RawData.ReadBuffer(lResourceEntry, SizeOf(lResourceEntry));
    AContext.AssertEquals(256, lResourceEntry.width);
    AContext.AssertEquals(512, lResourceEntry.height);
    lCursor.ItemData.Position := SizeOf(lHeader);
    lCursor.ItemData.ReadBuffer(lEntry, SizeOf(lEntry));
    AContext.AssertEquals(0, lEntry.width);
    AContext.AssertEquals(0, lEntry.height);
  finally
    lCursor.Free;
  end;
end;

procedure TestBitmapMasks(AContext: TNXTestContext);
var
  lBitmap: TBitmapResource;
  lOffset: LongWord;
begin
  lBitmap := TBitmapResource.Create;
  try
    lBitmap.RawData.Size := 112;
    lBitmap.RawData.Position := 0; WriteDWord(lBitmap.RawData, 108);
    lBitmap.RawData.Position := 14; WriteWord(lBitmap.RawData, 32);
    WriteDWord(lBitmap.RawData, 3);
    lBitmap.RawData.Position := 32; WriteDWord(lBitmap.RawData, 0);
    lBitmap.BitmapData.Position := 10;
    lBitmap.BitmapData.ReadBuffer(lOffset, 4);
    AContext.AssertEquals(122, LEtoN(lOffset));
  finally
    lBitmap.Free;
  end;
end;

procedure RegisterFCLResTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  TResources.RegisterReader('.nxprobe', TProbeReader);
  lSuite := ARegistry.AddSuite('FCLRes');
  lSuite.AddTest('VersionQuad', @TestVersionQuad);
  lSuite.AddTest('InvalidVersionQuad', @TestInvalidVersionQuad);
  lSuite.AddTest('VersionStrings', @TestVersionStrings);
  lSuite.AddTest('VersionRefresh', @TestVersionRefresh);
  lSuite.AddTest('FixedOnlyVersion', @TestFixedOnlyVersion);
  lSuite.AddTest('ObjectStringAppend', @TestObjectStringAppend);
  lSuite.AddTest('MissingRemove', @TestMissingRemove);
  lSuite.AddTest('ProbeCleanup', @TestProbeCleanup);
  lSuite.AddTest('ShortProbe', @TestShortProbe);
  lSuite.AddTest('RemoveLifetime', @TestRemoveLifetime);
  lSuite.AddTest('MoveLifetime', @TestMoveLifetime);
  lSuite.AddTest('UnpaddedPayload', @TestUnpaddedPayload);
  lSuite.AddTest('TruncatedPayload', @TestTruncatedPayload);
  lSuite.AddTest('PartialHeader', @TestPartialHeader);
  lSuite.AddTest('HeaderBounds', @TestHeaderBounds);
  lSuite.AddTest('Translations', @TestTranslations);
  lSuite.AddTest('VersionSignature', @TestVersionSignature);
  lSuite.AddTest('VersionLength', @TestVersionLength);
  lSuite.AddTest('FatSelection', @TestFatSelection);
  lSuite.AddTest('FatShortRead', @TestFatShortRead);
  lSuite.AddTest('FatEmpty', @TestFatEmpty);
  lSuite.AddTest('Cursor256', @TestCursor256);
  lSuite.AddTest('BitmapMasks', @TestBitmapMasks);
end;
end.

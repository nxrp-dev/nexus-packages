{
    This file is part of the Free Pascal run time library.
    Copyright (c) 2008 by Giulio Bernardi

    Version information resource type

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{$IFNDEF FPC_DOTTEDUNITS}
unit versionresource;
{$ENDIF FPC_DOTTEDUNITS}

{$MODE OBJFPC}

interface

{$IFDEF FPC_DOTTEDUNITS}
uses
  System.SysUtils, System.Classes, System.Resources.Resource, System.Resources.VersionTypes;
{$ELSE FPC_DOTTEDUNITS}
uses
  SysUtils, Classes, resource, versiontypes;
{$ENDIF FPC_DOTTEDUNITS}

type
  TVerBlockHeader = packed record
    length    : word;
    vallength : word;
    valtype   : word;
    key       : string;
  end;

type

  { TVersionResource }

  TVersionResource = class(TAbstractResource)
  private
    fType : TResourceDesc;
    fName : TResourceDesc;
    fFixedInfo : TVersionFixedInfo;
    fStringFileInfo : TVersionStringFileInfo;
    fVarFileInfo : TVersionVarFileInfo;
    function SwapVersion(const aData : qword) : qword;
    procedure AlignDWordReading;
    procedure AlignDWordWriting;
    function GetFileInfo : TVersionStringFileInfo;
    function GetFixedInfo : TVersionFixedInfo;
    function GetVarInfo : TVersionVarFileInfo;
    procedure CheckDataLoaded;
    procedure LoadData;
    procedure LoadFixedInfos;
    function ReadBlockHeader(out aBlock : TVerBlockHeader) : integer;
    function ReadStringFileInfo(AToRead: Integer): Integer;
    function ReadVarFileInfo(AToRead: Integer): Integer;
    function ReadStringTable(AToRead: Integer; AName: string): Integer;
    function ReadWideString(AToRead: Integer = -1): string;
    procedure WriteFixedBlockLength(const position : int64);
    procedure WriteData;
    procedure WriteFixedInfos;
    procedure WriteStringFileInfo;
    procedure WriteStringTable(aTable : TVersionStringTable);
    procedure WriteStringEntry(const aKey, aValue : string);
    procedure WriteVarFileInfo;
    procedure WriteVarEntry(aEntry : TVerTranslationInfo);
    procedure WriteWideString(const aString : string);
  protected
    function GetType : TResourceDesc; override;
    function GetName : TResourceDesc; override;
    function ChangeDescTypeAllowed(aDesc : TResourceDesc) : boolean; override;
    function ChangeDescValueAllowed(aDesc : TResourceDesc) : boolean; override;
    procedure NotifyResourcesLoaded; override;
  public
    constructor Create; override;
    constructor Create(aType,aName : TResourceDesc); override;
    destructor Destroy; override;
    procedure UpdateRawData; override;
    property FixedInfo : TVersionFixedInfo read GetFixedInfo;
    property StringFileInfo : TVersionStringFileInfo read GetFileInfo;
    property VarFileInfo : TVersionVarFileInfo read GetVarInfo;
  end;


implementation

{$IFDEF FPC_DOTTEDUNITS}
uses
  System.Resources.Factory;
{$ELSE FPC_DOTTEDUNITS}
uses
  resfactory;
{$ENDIF FPC_DOTTEDUNITS}

type
  TVSFixedFileInfo = packed record
    signature : longword;
    verMinor  : word;
    verMajor  : word;
    FileVersion : qword;
    ProductVersion : qword;
    FileFlagsMask : longword;
    FileFlags     : longword;
    FileOS        : longword;
    FileType      : longword;
    FileSubType   : longword;
    FileDate      : qword;
  end;


{ TVersionResource }

function TVersionResource.SwapVersion(const aData: qword): qword;
begin
  Result:=Swap(longword(hi(aData)));
  Result:=Result shl 32;
  Result:=Result or Swap(longword(lo(aData)));
end;

procedure TVersionResource.AlignDWordReading;
var toskip : integer;
begin
  toskip:=4-(RawData.Position mod 4);
  if toskip<>4 then RawData.Seek(toskip,soFromCurrent);
end;

procedure TVersionResource.AlignDWordWriting;
var topad : integer;
    lw : longword;
begin
  lw:=0;
  topad:=4-(RawData.Position mod 4);
  if topad<>4 then RawData.WriteBuffer(lw,topad);
end;

function TVersionResource.GetFileInfo: TVersionStringFileInfo;
begin
  CheckDataLoaded;
  Result:=fStringFileInfo;
end;

function TVersionResource.GetFixedInfo: TVersionFixedInfo;
begin
  CheckDataLoaded;
  Result:=fFixedInfo;
end;

function TVersionResource.GetVarInfo: TVersionVarFileInfo;
begin
  CheckDataLoaded;
  Result:=fVarFileInfo;
end;

procedure TVersionResource.CheckDataLoaded;
begin
  if fFixedInfo<>nil then exit;
  //if we have no data stream, create empty structures
  if RawData.Size=0 then
  begin
    fFixedInfo:=TVersionFixedInfo.Create;
    fStringFileInfo:=TVersionStringFileInfo.Create;
    fVarFileInfo:=TVersionVarFileInfo.Create;
  end
  else LoadData;
end;

procedure TVersionResource.LoadData;
var
  lBlock: TVerBlockHeader;
  lRootEnd, lStart, lEnd: Int64;
  lHeaderSize: Integer;
begin
  RawData.Position := 0;
  ReadBlockHeader(lBlock);
  lRootEnd := lBlock.length;
  if (lBlock.key <> 'VS_VERSION_INFO') or (lBlock.valtype <> 0) or
    (lBlock.vallength <> SizeOf(TVSFixedFileInfo)) or
    (lRootEnd - RawData.Position < SizeOf(TVSFixedFileInfo)) then
    raise EResourceReaderException.Create('Invalid version information root');
  try
    LoadFixedInfos;
    fStringFileInfo := TVersionStringFileInfo.Create;
    fVarFileInfo := TVersionVarFileInfo.Create;
    AlignDWordReading;
    while RawData.Position < lRootEnd do
    begin
      lStart := RawData.Position;
      lHeaderSize := ReadBlockHeader(lBlock);
      lEnd := lStart + lBlock.length;
      if (lEnd > lRootEnd) or (lHeaderSize > lBlock.length) then
        raise EResourceReaderException.Create('Invalid version child length');
      if lBlock.key = 'StringFileInfo' then
        ReadStringFileInfo(lEnd - RawData.Position)
      else if lBlock.key = 'VarFileInfo' then
        ReadVarFileInfo(lEnd - RawData.Position);
      RawData.Position := lEnd;
      AlignDWordReading;
    end;
  except
    FreeAndNil(fFixedInfo);
    FreeAndNil(fStringFileInfo);
    FreeAndNil(fVarFileInfo);
    raise;
  end;
end;

procedure TVersionResource.LoadFixedInfos;
var infodata : TVSFixedFileInfo;
begin
  RawData.ReadBuffer(infodata,sizeof(infodata));
  infodata.FileVersion:=SwapVersion(infodata.FileVersion);
  infodata.ProductVersion:=SwapVersion(infodata.ProductVersion);
  infodata.FileDate:=Swap(infodata.FileDate);             //MSLW is stored first...
  if infodata.signature <> $FEEF04BD then
    raise EResourceReaderException.Create('Invalid fixed version signature');
  fFixedInfo:=TVersionFixedInfo.Create;
  fFixedInfo.FileVersion:=TFileProductVersion(infodata.FileVersion);
  fFixedInfo.ProductVersion:=TFileProductVersion(infodata.ProductVersion);
  fFixedInfo.FileFlagsMask:=infodata.FileFlagsMask;
  fFixedInfo.FileFlags:=infodata.FileFlags;
  fFixedInfo.FileOS:=infodata.FileOS;
  fFixedInfo.FileType:=infodata.FileType;
  fFixedInfo.FileSubType:=infodata.FileSubType;
  fFixedInfo.FileDate:=infodata.FileDate;
end;

function TVersionResource.ReadBlockHeader(out ABlock: TVerBlockHeader): Integer;
var
  lStart: Int64;
begin
  lStart := RawData.Position;
  if RawData.Size - lStart < 6 then
    raise EResourceReaderException.Create('Incomplete version block header');
  RawData.ReadBuffer(ABlock, 6);
  ABlock.length := LEtoN(ABlock.length);
  ABlock.vallength := LEtoN(ABlock.vallength);
  ABlock.valtype := LEtoN(ABlock.valtype);
  if (ABlock.length < 6) or (ABlock.length > RawData.Size - lStart) then
    raise EResourceReaderException.Create('Invalid version block length');
  ABlock.key := ReadWideString((ABlock.length - 6) div 2);
  AlignDWordReading;
  Result := RawData.Position - lStart;
end;

function TVersionResource.ReadStringFileInfo(AToRead: Integer): Integer;
var
  lBlock: TVerBlockHeader;
  lStart, lBlockStart, lEnd, lBlockEnd: Int64;
begin
  lStart := RawData.Position;
  lEnd := lStart + AToRead;
  while RawData.Position < lEnd do
  begin
    lBlockStart := RawData.Position;
    ReadBlockHeader(lBlock);
    lBlockEnd := lBlockStart + lBlock.length;
    if (lBlockEnd > lEnd) or (lBlockEnd < RawData.Position) then
      raise EResourceReaderException.Create('Invalid version string table length');
    ReadStringTable(lBlockEnd - RawData.Position, lBlock.key);
    RawData.Position := lBlockEnd;
    AlignDWordReading;
  end;
  Result := RawData.Position - lStart;
end;

function TVersionResource.ReadVarFileInfo(AToRead: Integer): Integer;
var
  lBlock: TVerBlockHeader;
  lTranslation: TVerTranslationInfo;
  lStart, lBlockStart, lEnd, lBlockEnd: Int64;
  lIndex: Integer;
begin
  lStart := RawData.Position;
  lEnd := lStart + AToRead;
  while RawData.Position < lEnd do
  begin
    lBlockStart := RawData.Position;
    ReadBlockHeader(lBlock);
    lBlockEnd := lBlockStart + lBlock.length;
    if (lBlockEnd > lEnd) or (lBlock.vallength > lBlockEnd - RawData.Position) then
      raise EResourceReaderException.Create('Invalid version translation length');
    if (lBlock.valtype = 0) and (lBlock.key = 'Translation') then
    begin
      if lBlock.vallength mod SizeOf(lTranslation) <> 0 then
        raise EResourceReaderException.Create('Incomplete version translation');
      for lIndex := 1 to lBlock.vallength div SizeOf(lTranslation) do
      begin
        RawData.ReadBuffer(lTranslation, SizeOf(lTranslation));
        lTranslation.language := LEtoN(lTranslation.language);
        lTranslation.codepage := LEtoN(lTranslation.codepage);
        fVarFileInfo.Add(lTranslation);
      end;
    end;
    RawData.Position := lBlockEnd;
    AlignDWordReading;
  end;
  Result := RawData.Position - lStart;
end;

function TVersionResource.ReadStringTable(AToRead: Integer; AName: string): Integer;
var
  lTable: TVersionStringTable;
  lBlock: TVerBlockHeader;
  lValue: string;
  lStart, lEnd, lBlockStart, lBlockEnd: Int64;
begin
  lStart := RawData.Position;
  lEnd := lStart + AToRead;
  lTable := TVersionStringTable.Create(AName);
  fStringFileInfo.Add(lTable);
  while RawData.Position < lEnd do
  begin
    lBlockStart := RawData.Position;
    ReadBlockHeader(lBlock);
    lBlockEnd := lBlockStart + lBlock.length;
    if (lBlockEnd > lEnd) or (lBlock.valtype <> 1) or
      (Int64(lBlock.vallength) * 2 > lBlockEnd - RawData.Position) then
      raise EResourceReaderException.Create('Invalid version string length');
    lValue := ReadWideString(lBlock.vallength);
    lTable.Add(lBlock.key, lValue);
    RawData.Position := lBlockEnd;
    AlignDWordReading;
  end;
  Result := RawData.Position - lStart;
end;

function TVersionResource.ReadWideString(AToRead: Integer): string;
var
  lWord: Word;
  lText: WideString;
begin
  if AToRead = 0 then Exit('');
  if AToRead < 0 then AToRead := (RawData.Size - RawData.Position) div 2;
  lText := '';
  while AToRead > 0 do
  begin
    if RawData.Size - RawData.Position < 2 then Break;
    RawData.ReadBuffer(lWord, 2);
    lWord := LEtoN(lWord);
    if lWord = 0 then Exit(lText);
    lText := lText + WideChar(lWord);
    Dec(AToRead);
  end;
  raise EResourceReaderException.Create('Unterminated version string');
end;

procedure TVersionResource.WriteFixedBlockLength(const position: int64);
var after : int64;
    len : word;
begin
  after:=RawData.Position;
  len:=after-position;
  RawData.Position:=position;
  RawData.WriteBuffer(len,2);
  RawData.Position:=after;
end;

procedure TVersionResource.WriteData;
var block : TVerBlockHeader;
begin
  RawData.Size:=0;
  RawData.Position:=0;

  block.length:=0;
  block.vallength:=$34;
  block.valtype:=0;
  block.key:='VS_VERSION_INFO';

  RawData.WriteBuffer(block,6);
  WriteWideString(block.key);
  AlignDWordWriting;

  WriteFixedInfos;
  AlignDWordWriting;

  if fStringFileInfo.Count>0 then WriteStringFileInfo;
  if fVarFileInfo.Count>0 then WriteVarFileInfo;

  WriteFixedBlockLength(0);
end;

procedure TVersionResource.WriteFixedInfos;
var infodata : TVSFixedFileInfo;
begin
  infodata.signature:=$FEEF04BD;
  infodata.verMinor:=0;
  infodata.verMajor:=1;
  infodata.FileVersion:=qword(fFixedInfo.FileVersion);
  infodata.ProductVersion:=qword(fFixedInfo.ProductVersion);
  infodata.FileFlagsMask:=fFixedInfo.FileFlagsMask;
  infodata.FileFlags:=fFixedInfo.FileFlags;
  infodata.FileOS:=fFixedInfo.FileOS;
  infodata.FileType:=fFixedInfo.FileType;
  infodata.FileSubType:=fFixedInfo.FileSubType;
  infodata.FileDate:=fFixedInfo.FileDate;
  infodata.FileVersion:=SwapVersion(infodata.FileVersion);
  infodata.ProductVersion:=SwapVersion(infodata.ProductVersion);
  infodata.FileDate:=Swap(infodata.FileDate);             //MSLW is stored first...
  RawData.WriteBuffer(infodata,sizeof(infodata));
end;

procedure TVersionResource.WriteStringFileInfo;
var block : TVerBlockHeader;
    i : integer;
    before : int64;
begin
  before:=RawData.Position;
  block.length:=0;
  block.vallength:=0;
  block.valtype:=1;
  block.key:='StringFileInfo';
  RawData.WriteBuffer(block,6);
  WriteWideString(block.key);
  AlignDWordWriting;

  for i:=0 to fStringFileInfo.Count-1 do
    WriteStringTable(fStringFileInfo[i]);

  WriteFixedBlockLength(before);
end;

procedure TVersionResource.WriteStringTable(aTable: TVersionStringTable);
var block : TVerBlockHeader;
    i : integer;
    before : int64;
begin
  before:=RawData.Position;
  block.length:=0;
  block.vallength:=0;
  block.valtype:=1;
  block.key:=aTable.Name;
  RawData.WriteBuffer(block,6);
  WriteWideString(block.key);
  AlignDWordWriting;

  for i:=0 to aTable.Count-1 do
    WriteStringEntry(aTable.Keys[i],aTable.ValuesByIndex[i]);

  WriteFixedBlockLength(before);
end;

procedure TVersionResource.WriteStringEntry(const aKey, aValue: string);
var block : TVerBlockHeader;
    before: int64;
begin
  before:=RawData.Position;
  block.length:=0;
  block.vallength:=length(WideString(aValue))+1;
  block.valtype:=1;
  block.key:=aKey;
  RawData.WriteBuffer(block,6);
  WriteWideString(block.key);
  AlignDWordWriting;
  WriteWideString(aValue);
  AlignDWordWriting;

  WriteFixedBlockLength(before);
end;

procedure TVersionResource.WriteVarFileInfo;
var block : TVerBlockHeader;
    i : integer;
    before : int64;
begin
  before:=RawData.Position;
  block.length:=0;
  block.vallength:=0;
  block.valtype:=1;
  block.key:='VarFileInfo';
  RawData.WriteBuffer(block,6);
  WriteWideString(block.key);
  AlignDWordWriting;

  for i:=0 to fVarFileInfo.Count-1 do
    WriteVarEntry(fVarFileInfo[i]);

  WriteFixedBlockLength(before);
end;

procedure TVersionResource.WriteVarEntry(aEntry: TVerTranslationInfo);
var block : TVerBlockHeader;
    before: int64;
begin
  before:=RawData.Position;
  block.length:=0;
  block.vallength:=4;
  block.valtype:=0;
  block.key:='Translation';
  RawData.WriteBuffer(block,6);
  WriteWideString(block.key);
  AlignDWordWriting;
  RawData.WriteBuffer(aEntry,sizeof(aEntry));
  WriteFixedBlockLength(before);
end;

procedure TVersionResource.WriteWideString(const aString: string);
var ws : widestring;
    w : word;
    i : integer;
    isnulterminate : boolean;
begin
  ws:=aString;
  for i:=1 to length(ws) do
  begin
    w:=word(ws[i]);
    RawData.WriteBuffer(w,2);
  end;
  w:=length(ws);

  isnulterminate:=(w>0) and (ws[w]=#0);
  if not isnulterminate then
    begin
      w:=0;
      RawData.WriteBuffer(w,2);
    end;
end;

function TVersionResource.GetType: TResourceDesc;
begin
  Result:=fType;
end;

function TVersionResource.GetName: TResourceDesc;
begin
  Result:=fName;
end;

function TVersionResource.ChangeDescTypeAllowed(aDesc: TResourceDesc): boolean;
begin
  Result:=false;
end;

function TVersionResource.ChangeDescValueAllowed(aDesc: TResourceDesc
  ): boolean;
begin
  Result:=false;
end;

procedure TVersionResource.NotifyResourcesLoaded;
begin
end;

constructor TVersionResource.Create;
begin
  inherited Create;
  fType:=TResourceDesc.Create(RT_VERSION);
  fName:=TResourceDesc.Create(1);
  SetDescOwner(fType);
  SetDescOwner(fName);
  fFixedInfo:=nil;
  fStringFileInfo:=nil;
  fVarFileInfo:=nil;
end;

constructor TVersionResource.Create(aType, aName: TResourceDesc);
begin
  Create;
end;

destructor TVersionResource.Destroy;
begin
  fType.Free;
  fName.Free;
  if fFixedInfo<>nil then fFixedInfo.Free;
  if fStringFileInfo<>nil then fStringFileInfo.Free;
  if fVarFileInfo<>nil then fVarFileInfo.Free;
  inherited Destroy;
end;

procedure TVersionResource.UpdateRawData;
begin
  if fFixedInfo=nil then exit;
  WriteData;
  FreeAndNil(fFixedInfo);
  FreeAndNil(fStringFileInfo);
  FreeAndNil(fVarFileInfo);
end;

initialization
  TResourceFactory.RegisterResourceClass(RT_VERSION,TVersionResource);

end.

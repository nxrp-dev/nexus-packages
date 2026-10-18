{
    This file is part of the Free Pascal run time library.
    Copyright (c) 2008 by Giulio Bernardi

    Resource reader for .res files

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{$IFNDEF FPC_DOTTEDUNITS}
unit resreader;
{$ENDIF FPC_DOTTEDUNITS}

{$MODE OBJFPC} {$H+}

interface

{$IFDEF FPC_DOTTEDUNITS}
uses
  System.Classes, System.SysUtils, System.Resources.Resource;
{$ELSE FPC_DOTTEDUNITS}
uses
  Classes, SysUtils, resource;
{$ENDIF FPC_DOTTEDUNITS}

type

  { TResResourceReader }

  TResResourceReader = class (TAbstractResourceReader)
  private
    fExtensions : string;
    fDescription : string;
    dummyType : TResourceDesc;
    dummyName : TResourceDesc;
    procedure AlignDword(aStream : TStream);
    function ReadResourceHeader(aStream : TStream) : TAbstractResource;
    function ReadUnicodeString(AStream: TStream; AMaxSize: Integer; out ACount: Integer): WideString;
    function ReadNameID(AStream: TStream; ADesc: TResourceDesc; AMaxSize: Integer): Integer;
  protected
    function GetExtensions : string; override;
    function GetDescription : string; override;
    procedure Load(aResources : TResources; aStream : TStream); override;
    function CheckMagic(aStream : TStream) : boolean; override;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;


implementation

{$IFDEF FPC_DOTTEDUNITS}
uses System.Resources.DataStream, System.Resources.Factory;
{$ELSE FPC_DOTTEDUNITS}
uses resdatastream, resfactory;
{$ENDIF FPC_DOTTEDUNITS}

//This exception is raised when end of stream is detected and expected,
//that is, before reading a new resource header. It's not an error.
type
  EResourceReaderEOSReachedException = class (EResourceReaderException);


{ TResResourceReader }

procedure TResResourceReader.AlignDword(aStream: TStream);
var toskip : integer;
begin
  toskip:=4-(aStream.Position mod 4);
  if toskip<>4 then aStream.Seek(toskip,soFromCurrent);
end;

function TResResourceReader.ReadResourceHeader(AStream: TStream): TAbstractResource;
var
  lDataSize, lHeaderSize, lDataVersion, lVersion, lCharacteristics: LongWord;
  lMemoryFlags, lLanguageID: Word;
  lHeaderStart, lHeaderEnd, lDataOffset: Int64;
  lRawData: TResourceDataStream;
begin
  Result := nil;
  if AStream.Position >= AStream.Size then Exit;
  lHeaderStart := AStream.Position;
  if AStream.Size - lHeaderStart < 8 then
    raise EResourceReaderUnexpectedEndOfStreamException.Create('Incomplete RES header');
  try
    AStream.ReadBuffer(lDataSize, 4);
    AStream.ReadBuffer(lHeaderSize, 4);
    lDataSize := LEtoN(lDataSize);
    lHeaderSize := LEtoN(lHeaderSize);
    if (lHeaderSize < 28) or (lHeaderSize mod 4 <> 0) or
      (lHeaderSize > AStream.Size - lHeaderStart) then
      raise EResourceReaderException.Create('Invalid RES header size');
    lHeaderEnd := lHeaderStart + lHeaderSize;
    ReadNameID(AStream, dummyType, lHeaderEnd - AStream.Position - 18);
    ReadNameID(AStream, dummyName, lHeaderEnd - AStream.Position - 16);
    AlignDWord(AStream);
    if AStream.Position > lHeaderEnd - 16 then
      raise EResourceReaderException.Create('RES identifiers exceed the header');
    AStream.ReadBuffer(lDataVersion, 4);
    AStream.ReadBuffer(lMemoryFlags, 2);
    AStream.ReadBuffer(lLanguageID, 2);
    AStream.ReadBuffer(lVersion, 4);
    AStream.ReadBuffer(lCharacteristics, 4);
    AStream.Position := lHeaderEnd;
    lDataOffset := AStream.Position;
    if lDataSize > AStream.Size - lDataOffset then
      raise EResourceReaderUnexpectedEndOfStreamException.Create('Incomplete RES payload');
    Result := TResourceFactory.CreateResource(dummyType, dummyName);
    SetDataSize(Result, lDataSize);
    SetHeaderSize(Result, lHeaderSize);
    Result.DataVersion := LEtoN(lDataVersion);
    Result.MemoryFlags := LEtoN(lMemoryFlags);
    Result.LangID := LEtoN(lLanguageID);
    Result.Version := LEtoN(lVersion);
    Result.Characteristics := LEtoN(lCharacteristics);
    SetDataOffset(Result, lDataOffset);
    lRawData := TResourceDataStream.Create(AStream, Result, lDataSize, TCachedResourceDataStream);
    SetRawData(Result, lRawData);
    AStream.Position := lDataOffset + lDataSize;
    AlignDWord(AStream);
  except
    on EReadError do
      raise EResourceReaderUnexpectedEndOfStreamException.Create('');
  end;
end;

function TResResourceReader.ReadUnicodeString(AStream: TStream; AMaxSize: Integer;
  out ACount: Integer): WideString;
var
  lWord: Word;
begin
  Result := '';
  ACount := 0;
  while AMaxSize >= 2 do
  begin
    AStream.ReadBuffer(lWord, 2);
    lWord := LEtoN(lWord);
    Inc(ACount, 2);
    Dec(AMaxSize, 2);
    if lWord = 0 then Exit;
    Result := Result + WideChar(lWord);
  end;
  raise EResourceReaderException.Create('Unterminated RES identifier');
end;

function TResResourceReader.ReadNameID(AStream: TStream; ADesc: TResourceDesc;
  AMaxSize: Integer): Integer;
var
  lWord: Word;
  lText: WideString;
begin
  if AMaxSize < 2 then
    raise EResourceReaderException.Create('RES identifier exceeds the header');
  AStream.ReadBuffer(lWord, 2);
  lWord := LEtoN(lWord);
  if lWord = $FFFF then
  begin
    if AMaxSize < 4 then
      raise EResourceReaderException.Create('RES ordinal exceeds the header');
    AStream.ReadBuffer(lWord, 2);
    ADesc.ID := LEtoN(lWord);
    Result := 4;
  end
  else if lWord = 0 then
  begin
    ADesc.Name := '';
    Result := 2;
  end
  else
  begin
    lText := WideChar(lWord) + ReadUnicodeString(AStream, AMaxSize - 2, Result);
    ADesc.Name := lText;
    Inc(Result, 2);
  end;
end;

function TResResourceReader.GetExtensions: string;
begin
  Result:=fExtensions;
end;

function TResResourceReader.GetDescription: string;
begin
  Result:=fDescription;
end;

procedure TResResourceReader.Load(aResources: TResources; aStream: TStream);
var aRes : TAbstractResource;
begin
  if not CheckMagic(aStream) then
    raise EResourceReaderWrongFormatException.Create('');
  Repeat
    aRes:=ReadResourceHeader(aStream);
    if (aRes<>Nil) then
      try
        aResources.Add(aRes);
      except
        on e : EResourceDuplicateException do
        begin
          aRes.Free;
          raise;
        end;
      end;
  Until (aRes=Nil);
end;

function TResResourceReader.CheckMagic(aStream: TStream): boolean;
var lw : longword;
begin
  Result:=false;
  aStream.ReadBuffer(lw,4); if lw<>0 then exit; //datasize = 0
  aStream.ReadBuffer(lw,4);
  if lw<>$20 then exit;                         //headersize = $20
  aStream.ReadBuffer(lw,4);
  if lw<>$FFFF then exit;                       //type = $0000FFFF
  aStream.ReadBuffer(lw,4);
  if lw<>$FFFF then exit;                       //name = $0000FFFF
  aStream.ReadBuffer(lw,4); if lw<>0 then exit; //dataversion = 0
  aStream.ReadBuffer(lw,4); if lw<>0 then exit; //memflags,langid = 0
  aStream.ReadBuffer(lw,4); if lw<>0 then exit; //version = 0
  aStream.ReadBuffer(lw,4); if lw<>0 then exit; //characteristics = 0
  Result:=true;
end;

constructor TResResourceReader.Create;
begin
  fExtensions:='.res';
  fDescription:='.res resource reader';
  dummyType:=TResourceDesc.Create;
  dummyName:=TResourceDesc.Create;
end;

destructor TResResourceReader.Destroy;
begin
  dummyType.Free;
  dummyName.Free;
end;

initialization
  TResources.RegisterReader('.res',TResResourceReader);

end.

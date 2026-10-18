{
    This file is part of the Free Pascal run time library.
    Copyright (c) 2008 by Giulio Bernardi

    Resource reader for Mach-O files

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{$IFNDEF FPC_DOTTEDUNITS}
unit machoreader;
{$ENDIF FPC_DOTTEDUNITS}

{$MODE OBJFPC} {$H+}

interface

{$IFDEF FPC_DOTTEDUNITS}
uses
  System.Classes, System.SysUtils, System.Resources.Resource, System.Resources.Macho.Types;
{$ELSE FPC_DOTTEDUNITS}
uses
  Classes, SysUtils, resource, machotypes;
{$ENDIF FPC_DOTTEDUNITS}

type

  { TMachOResourceReader }

  TMachOResourceReader = class (TAbstractResourceReader)
  private
    fDescription: string;
    fExtensions: string;
    fEndianess : integer;
    fOppositeEndianess : boolean;
    fMachineType : TMachOMachineType;
    fSubMachineType : TMachoSubMachineType;
    fBits : integer;
    fHeader : TMachHdr;
    procedure SetDefaultTarget;
    function ReadMachOHeader(aStream : TStream) : boolean;
  protected
    function GetExtensions : string; override;
    function GetDescription : string; override;
    procedure Load(aResources : TResources; aStream : TStream); override;
    function CheckMagic(aStream : TStream) : boolean; override;

    function FindBestFatArchOffset(AStream: TStream; ASwitchEndian: Boolean; AFatHeader: TMachFatHdr): Int64;
  public
    constructor Create; override; overload;
    constructor Create(AMachineType: TMachOMachineType; ASubMachineType: TMachoSubMachineType);
    destructor Destroy; override;
    property MachineType : TMachOMachineType read fMachineType;
    property SubMachineType : TMachOSubMachineType read fSubMachineType;
  end;

implementation

{$IFDEF FPC_DOTTEDUNITS}
uses System.CTypes, System.Resources.Macho.Consts, System.Resources.Factory, System.Resources.Tree, System.Resources.DataStream, System.Resources.Types;
{$ELSE FPC_DOTTEDUNITS}
uses ctypes, machoconsts, resfactory, resourcetree, resdatastream, fpcrestypes;
{$ENDIF FPC_DOTTEDUNITS}

type

  { TAbstractMachOSubReader }

  TAbstractMachOSubReader = class
  private
  protected
    fHeader : TMachHdr;
    fOppositeEndianess : boolean;
    fSegType : longword;
    fRoot : TRootResTreeNode;
    fParent : TMachOResourceReader;
    function ReadString(aStream : TStream; aPos : longword) : string;
    procedure ReadNode(aStream : TStream; aParent : TResourceTreeNode;
      aResources : TResources; named : boolean); virtual; abstract;
    procedure ReadResData(aStream : TStream; aNode : TResourceTreeNode;
      aResources : TResources; datasize : longword);
    procedure LoadResources(aResources : TResources; aStream : TStream);
    procedure Load(aResources : TResources; aStream : TStream); virtual; abstract;
  public
    constructor Create(aParent : TMachOResourceReader; const aHeader : TMachHdr;
      const aOppositeEndianess : boolean); virtual;
    destructor Destroy; override;
  end;

(*
Almost all differences in 32 and 64 bit mach-o files lie in record sizes.
Generics don't work with record types, so use macros to do this task
(uglier, but should be the same)
*)

{$MACRO ON}

//Define TMachO32SubReader

{$DEFINE _TMachOSubReader_:=TMachO32SubReader}
{$DEFINE _TSection_:=TSection32}
{$DEFINE _TResHdr_:=TResHdr32}
{$DEFINE _TResInfoNode_:=TResInfoNode32}
{$DEFINE _TSegmentCommand_:=TSegmentCommand32}
{$INCLUDE machosubreader.inc}

//Define TMachO64SubReader

{$DEFINE _TMachOSubReader_:=TMachO64SubReader}
{$DEFINE _TSection_:=TSection64}
{$DEFINE _TResHdr_:=TResHdr64}
{$DEFINE _TResInfoNode_:=TResInfoNode64}
{$DEFINE _TSegmentCommand_:=TSegmentCommand64}
{$INCLUDE machosubreader.inc}

//Clean all this stuff...
{$UNDEF _TMachOSubReader_}
{$UNDEF _TSection_}
{$UNDEF _TResHdr_}
{$UNDEF _TResInfoNode_}
{$UNDEF _TSegmentCommand_}

{ TAbstractMachOSubReader }

function TAbstractMachOSubReader.ReadString(aStream: TStream; aPos: longword
  ): string;
var oldpos : int64;
    c : AnsiChar;
    maxleft : int64;
begin
  Result:='';
  oldpos:=aStream.Position;
  aStream.Position:=aPos;
  aStream.ReadBuffer(c,1);
  maxleft:=aStream.Size-aStream.Position;
  while (c<>#0) and (maxleft>=0) do
  begin
    Result:=Result+c;
    aStream.ReadBuffer(c,1);
    dec(maxleft);
  end;
  aStream.Position:=oldpos;
end;

procedure TAbstractMachOSubReader.ReadResData(aStream: TStream;
  aNode: TResourceTreeNode; aResources: TResources; datasize: longword);
var aRes : TAbstractResource;
    RawData : TResourceDataStream;
begin
  aRes:=aNode.CreateResource;
  if aRes=nil then
    raise EResourceDuplicateException.CreateFmt(SResDuplicate,[
      aNode.Data._Type.Name,aNode.Data.Name.Name,aNode.Data.LangID]);
  fParent.SetDataSize(aRes,datasize);
  fParent.SetDataOffset(aRes,aStream.Position);
  RawData:=TResourceDataStream.Create(aStream,aRes,aRes.DataSize,TCachedResourceDataStream);
  fParent.SetRawData(aRes,RawData);
  fParent.AddNoTree(aResources,aRes);
end;

procedure TAbstractMachOSubReader.LoadResources(aResources: TResources;
  aStream: TStream);
begin
  fRoot:=TRootResTreeNode(fParent.GetTree(aResources));
  ReadNode(aStream,nil,aResources,false);
end;

constructor TAbstractMachOSubReader.Create(aParent: TMachOResourceReader;
  const aHeader: TMachHdr; const aOppositeEndianess: boolean);
begin
  fParent:=aParent;
  fHeader:=aHeader;
  fOppositeEndianess:=aOppositeEndianess;
  fRoot:=nil;
end;

destructor TAbstractMachOSubReader.Destroy;
begin

end;

{ TMachOResourceReader }

procedure TMachOResourceReader.SetDefaultTarget;
begin
  {$INCLUDE machodefaulttarget.inc}
end;

function TMachOResourceReader.ReadMachOHeader(aStream: TStream): boolean;
var
  fatArchOffset: int64;
  tmp : longword;
  magic: cuint32;
  fathdr: TMachFatHdr;
begin
  Result:=false;

  try
    aStream.ReadBuffer(magic,sizeof(magic));
  except
    on e : EReadError do exit;
  end;

  case magic of
    FAT_MAGIC,
    FAT_CIGAM:
      begin
        fathdr.magic:=magic;
        try
          aStream.ReadBuffer((pbyte(@fathdr)+sizeof(magic))^,sizeof(fathdr)-sizeof(magic));
        except
          on e : EReadError do exit;
        end;

        fatArchOffset:=FindBestFatArchOffset(aStream,fathdr.magic=FAT_CIGAM,fathdr);
        if fatArchOffset=-1 then
          exit;
        aStream.Seek(fatArchOffset,soBeginning);

        try
          aStream.ReadBuffer(magic,sizeof(magic));
        except
          on e : EReadError do exit;
        end;
      end;
    end;

  fheader.magic:=magic;
  try
    aStream.ReadBuffer((pbyte(@fHeader)+sizeof(magic))^,sizeof(fheader)-sizeof(magic));
  except
    on e : EReadError do exit;
  end;

  case fHeader.magic of
    MH_MAGIC    : begin fBits:=MACH_32BIT; fOppositeEndianess:=false; end;
    MH_MAGIC_64 : begin fBits:=MACH_64BIT; fOppositeEndianess:=false; end;
    MH_CIGAM    : begin fBits:=MACH_32BIT; fOppositeEndianess:=true; end;
    MH_CIGAM_64 : begin fBits:=MACH_64BIT; fOppositeEndianess:=true; end
    else
      exit;
  end;

  if fOppositeEndianess then
    fEndianess:=MACH_BIG_ENDIAN
  else
    fEndianess:=MACH_LITTLE_ENDIAN;

  if fOppositeEndianess then
    begin
      fHeader.magic:=SwapEndian(fHeader.magic);
      fHeader.cputype:=SwapEndian(fHeader.cputype);
      fHeader.cpusubtype:=SwapEndian(fHeader.cpusubtype);
      fHeader.filetype:=SwapEndian(fHeader.filetype);
      fHeader.ncmds:=SwapEndian(fHeader.ncmds);
      fHeader.sizeofcmds:=SwapEndian(fHeader.sizeofcmds);
      fHeader.flags:=SwapEndian(fHeader.flags);
    end;

  if not MachOMachineTypesToPas(fHeader.cpuType,fheader.cpusubtype,fMachineType,fSubMachineType) then
    exit;

  //64-bit mach-o files have 4 bytes of padding after the header
  if fBits=MACH_64BIT then
    try
      aStream.ReadBuffer(tmp,sizeof(tmp));
    except
      on e : EReadError do exit;
    end;

  Result:=true;
end;

function TMachOResourceReader.GetExtensions: string;
begin
  Result:=fExtensions;
end;

function TMachOResourceReader.GetDescription: string;
begin
  Result:=fDescription;
end;

procedure TMachOResourceReader.Load(aResources: TResources; aStream: TStream);
var subreader : TAbstractMachOSubReader;
begin
  if not ReadMachOHeader(aStream) then
    raise EResourceReaderWrongFormatException.Create('');

  case fBits of
    MACH_32BIT : subreader:=TMachO32SubReader.Create(self,fHeader,fOppositeEndianess);
    MACH_64BIT : subreader:=TMachO64SubReader.Create(self,fHeader,fOppositeEndianess);
  end;
  try
    try
      subreader.Load(aResources,aStream);
    except
      on e : EReadError do
        raise EResourceReaderUnexpectedEndOfStreamException.Create('');
    end;
  finally
    subreader.Free;
  end;
end;

function TMachOResourceReader.CheckMagic(aStream: TStream): boolean;
begin
  Result:=ReadMachOHeader(aStream);
end;

function TMachOResourceReader.FindBestFatArchOffset(AStream : TStream; ASwitchEndian: boolean; AFatHeader: TMachFatHdr): int64;
var
  lArchitectures: array of TMachFarArch;
  lMachine: TMachOMachineType;
  lSubtype: TMachoSubMachineType;
  lIndex: cuint32;
  lBestCompatibility, lCompatibility: TMachOSubMachineTypeCompatible;
begin
  result:=-1;
  if ASwitchEndian then
    begin
      AFatHeader.magic:=SwapEndian(AFatHeader.magic);
      AFatHeader.nfatarch:=SwapEndian(AFatHeader.nfatarch);
    end;
  if (AFatHeader.nfatarch = 0) or
    (QWord(AFatHeader.nfatarch) > QWord(AStream.Size - AStream.Position) div SizeOf(TMachFarArch)) then
    raise EResourceReaderUnexpectedEndOfStreamException.Create('Truncated Mach-O architecture table');
  setlength(lArchitectures,AFatHeader.nfatarch);
  try
    AStream.ReadBuffer(lArchitectures[0], AFatHeader.nfatarch * sizeof(lArchitectures[0]));
  except
    on lError : EReadError do
      raise EResourceReaderUnexpectedEndOfStreamException.Create('');
  end;
  lBestCompatibility:=smc_incompatible;
  for lIndex:=0 to AFatHeader.nfatarch-1 do
    begin
      if ASwitchEndian then
        begin
          lArchitectures[lIndex].cputype:=swapendian(lArchitectures[lIndex].cputype);
          lArchitectures[lIndex].cpusubtype:=swapendian(lArchitectures[lIndex].cpusubtype);
          lArchitectures[lIndex].offset:=swapendian(lArchitectures[lIndex].offset);
          lArchitectures[lIndex].size:=swapendian(lArchitectures[lIndex].size);
          lArchitectures[lIndex].align:=swapendian(lArchitectures[lIndex].align);
        end;
      if not MachOMachineTypesToPas(lArchitectures[lIndex].cputype,lArchitectures[lIndex].cpusubtype,lMachine,lSubtype) then
        continue;
      if lMachine<>fMachineType then
        continue;
      lCompatibility:=MachOSubMachineTypesEqual(lMachine,fSubMachineType,lSubtype);
      if lCompatibility>lBestCompatibility then
      begin
        if (QWord(lArchitectures[lIndex].offset) > QWord(AStream.Size)) or
          (QWord(lArchitectures[lIndex].size) > QWord(AStream.Size) - lArchitectures[lIndex].offset) then
          raise EResourceReaderUnexpectedEndOfStreamException.Create('Mach-O slice lies outside the file');
        lBestCompatibility := lCompatibility;
        Result := lArchitectures[lIndex].offset;
      end;
    end;
end;

constructor TMachOResourceReader.Create;
begin
  fExtensions:='.o .or';
  fDescription:='Mach-O resource reader';
  SetDefaultTarget;
end;

constructor TMachOResourceReader.Create(AMachineType: TMachOMachineType; ASubMachineType: TMachoSubMachineType);
  begin
    Create;
    fMachineType:=AMachineType;
    fSubMachineType:=ASubMachineType;
  end;

destructor TMachOResourceReader.Destroy;
begin

end;

initialization
  TResources.RegisterReader('.o',TMachOResourceReader);
  TResources.RegisterReader('.or',TMachOResourceReader);
  TResources.RegisterReader('',TMachOResourceReader);

end.

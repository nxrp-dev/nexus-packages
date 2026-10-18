{
    This file is part of the Free Pascal run time library.
    Copyright (c) 2008 by Giulio Bernardi

    Resource reader for ELF files

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

type

(*
  generic TElfRelocTable<_TPElfRela_,_TElfRela_,_TElfSectHdr_,_Tword_> = class
  ...
  TElf32RelocTable = specialize TElfRelocTable<PElf32Rela,TElf32Rela,
                                               TElf32SectHdr,longword>;
  TElf64RelocTable = specialize TElfRelocTable<PElf64Rela,TElf64Rela,
                                               TElf64SectHdr,qword>;
*)

  _TElfRelocTable_= class
  private
    fList : _TPElfRela_;
    fCount : integer;
  protected
  public
    constructor Create(aStream : TStream; const aSectHdr : _TElfSectHdr_;
      const aOppositeEndianess : boolean; aRelativeType : cardinal = 0);
    destructor Destroy; override;
    function Get(aOffset : _Tword_) : _Tword_;
    function TryGet(aOffset : _Tword_; out aValue : _Tword_) : boolean;
  end;

(*
  generic TElfSubReader<_TElfHdr_,_TElfSectHdr_,_TResHdr_,_TResInfoNode_> = class
  ...
  TElf32SubReader = specialize TElfSubReader<TElf32Hdr,TElf32SectHdr,TResHdr32,
    TResInfoNode32>;
  TElf64SubReader = specialize TElfSubReader<TElf64Hdr,TElf64SectHdr,TResHdr64,
    TResInfoNode64>;
*)

  { _TElfSubReader_ }

  _TElfSubReader_ = class(TAbstractElfSubReader)
  private
    fElfHdr : _TElfHdr_;
    fSectHeaders : array of _TElfSectHdr_;
    fResHdr : _TResHdr_;
    fRelocations : _TElfRelocTable_;
    fDynamicRelocations : _TElfRelocTable_;
    procedure ReadElfHeader(aStream : TStream);
    procedure ReadSectionHeaders(aStream : TStream);
    procedure ReadStringTable(aStream : TStream);
    procedure ReadRelocations(aStream : TStream);
    procedure ReadDynamicRelocations(aStream : TStream);
    procedure ReadResHeader(aStream : TStream);
    function PointerValue(aOffset, aStoredValue : _Tword_) : _Tword_;
  protected
    function FindSection(const aName : string) : integer; override;
    procedure Load(aResources : TResources; aStream : TStream); override;
    procedure ReadNode(aStream : TStream; aParent : TResourceTreeNode;
      aResources : TResources; named : boolean); override;
  public
  end;


constructor _TElfRelocTable_.Create(aStream : TStream;
  const aSectHdr : _TElfSectHdr_; const aOppositeEndianess : boolean;
  aRelativeType : cardinal);
var
  i, total, readCount : integer;
  remaining : SizeInt;
  buffer : PByte;
  relocType : cardinal;
  symbolIndex : qword;

  procedure Sort(left, right : integer);
  var
    lowIndex, highIndex : integer;
    pivot : _Tword_;
    temporary : _TElfRela_;
  begin
    lowIndex:=left;
    highIndex:=right;
    pivot:=fList[left+(right-left) div 2].Offset;
    repeat
      while fList[lowIndex].Offset<pivot do inc(lowIndex);
      while fList[highIndex].Offset>pivot do dec(highIndex);
      if lowIndex<=highIndex then
      begin
        temporary:=fList[lowIndex];
        fList[lowIndex]:=fList[highIndex];
        fList[highIndex]:=temporary;
        inc(lowIndex);
        dec(highIndex);
      end;
    until lowIndex>highIndex;
    if left<highIndex then Sort(left,highIndex);
    if lowIndex<right then Sort(lowIndex,right);
  end;

begin
  if (aSectHdr.size mod sizeof(_TElfRela_)<>0) or
     (qword(aSectHdr.size)>qword(High(SizeInt))) or
     (aSectHdr.size div sizeof(_TElfRela_)>qword(High(integer))) then
    raise EElfResourceReaderException.Create('Invalid ELF relocation section size');
  if (qword(aSectHdr.offset)>qword(aStream.Size)) or
     (qword(aSectHdr.size)>qword(aStream.Size)-qword(aSectHdr.offset)) then
    raise EElfResourceReaderException.Create('ELF relocation section lies outside the file');
  aStream.Position:=aSectHdr.offset;
  fList:=GetMem(aSectHdr.size);
  fCount:=aSectHdr.size div sizeof(_TElfRela_);
  remaining:=aSectHdr.size;
  buffer:=PByte(fList);
  while remaining<>0 do
  begin
    readCount:=65536;
    if remaining<readCount then readCount:=remaining;
    aStream.ReadBuffer(buffer^,readCount);
    inc(buffer,readCount);
    dec(remaining,readCount);
  end;
  if aOppositeEndianess then
    for i:=0 to fCount-1 do
    begin
      fList[i].Offset:=SwapEndian(fList[i].Offset);
      fList[i].Info:=SwapEndian(fList[i].Info);
      fList[i].addend:=SwapEndian(fList[i].addend);
    end;
  if aRelativeType<>0 then
  begin
    { Dynamic relocation offsets are virtual addresses. Only symbol-free
      RELATIVE entries provide pointers without loading or binding the image.
      Their on-disk slot may be zero: the loader uses the explicit addend. }
    total:=fCount;
    fCount:=0;
    for i:=0 to total-1 do
    begin
      if sizeof(_Tword_)=8 then
      begin
        relocType:=qword(fList[i].Info) and $FFFFFFFF;
        symbolIndex:=qword(fList[i].Info) shr 32;
      end
      else
      begin
        relocType:=fList[i].Info and $FF;
        symbolIndex:=fList[i].Info shr 8;
      end;
      if relocType<>aRelativeType then continue;
      if symbolIndex<>0 then
        raise EElfResourceReaderException.Create('ELF relative relocation has a symbol index');
      fList[fCount]:=fList[i];
      inc(fCount);
    end;
    { .rela.dyn can group relocation kinds rather than sorting all offsets. }
    if fCount>1 then Sort(0,fCount-1);
    for i:=1 to fCount-1 do
      if fList[i-1].Offset=fList[i].Offset then
        raise EElfResourceReaderException.Create('Duplicate ELF relative relocation offset');
  end;
end;

destructor _TElfRelocTable_.Destroy;
begin
  FreeMem(fList);
end;

function _TElfRelocTable_.Get(aOffset : _Tword_) : _Tword_;
begin
  if not TryGet(aOffset,Result) then Result:=0;
end;

function _TElfRelocTable_.TryGet(aOffset : _Tword_; out aValue : _Tword_) : boolean;
var l,r,pivot : integer;
begin
  Result:=false;
  aValue:=0;
  if fCount=0 then exit;
  l:=0; r:=fCount-1;
  while l<=r do
  begin
    pivot:=(l+r) div 2;
    if fList[pivot].Offset<aOffset then l:=pivot+1
    else if fList[pivot].Offset>aOffset then r:=pivot-1
    else
    begin
      aValue:=fList[pivot].Addend;
      Result:=true;
      exit;
    end;
  end;
end;


procedure _TElfSubReader_.ReadElfHeader(aStream: TStream);
begin
  aStream.ReadBuffer(fElfHdr,sizeof(fElfHdr));
  if fOppositeEndianess then
  begin
    fElfHdr._Type:=SwapEndian(fElfHdr._Type);
    fElfHdr.Machine:=SwapEndian(fElfHdr.Machine);
    fElfHdr.Version:=SwapEndian(fElfHdr.Version);
    fElfHdr.Entry:=SwapEndian(fElfHdr.Entry);
    fElfHdr.ProgHdrOffset:=SwapEndian(fElfHdr.ProgHdrOffset);
    fElfHdr.SectHdrOffset:=SwapEndian(fElfHdr.SectHdrOffset);
    fElfHdr.Flags:=SwapEndian(fElfHdr.Flags);
    fElfHdr.HdrSize:=SwapEndian(fElfHdr.HdrSize);
    fElfHdr.ProgHdrEntrySize:=SwapEndian(fElfHdr.ProgHdrEntrySize);
    fElfHdr.ProgHdrNum:=SwapEndian(fElfHdr.ProgHdrNum);
    fElfHdr.SectHdrEntrySize:=SwapEndian(fElfHdr.SectHdrEntrySize);
    fElfHdr.SectHdrNum:=SwapEndian(fElfHdr.SectHdrNum);
    fElfHdr.NameTableIndex:=SwapEndian(fElfHdr.NameTableIndex);
  end;
  fMachineType:=fElfHdr.Machine;
  if fElfHdr.Version<>EV_CURRENT then
    raise EElfResourceReaderUnknownVersionException.Create('');
  if fElfHdr.SectHdrNum=0 then
    raise EElfResourceReaderNoSectionsException.Create('');
  fNeedsReloc:=(fElfHdr._Type = ET_REL);
  if fNeedsReloc then
    case fElfHdr.Machine of
      EM_386    : fNeedsReloc:=false;
      EM_PPC    : ;
      EM_ARM    : fNeedsReloc:=false;
      EM_68K    : ;
      EM_SPARC  : ;
      EM_X86_64 : ;
      EM_PPC64  : ;
      EM_ALPHA  : ;
      EM_IA_64  : ;
    end;
end;

procedure _TElfSubReader_.ReadSectionHeaders(aStream: TStream);
var i : integer;
    delta : integer;
begin
  setlength(fSectHeaders,fElfHdr.SectHdrNum);
  delta:=fElfHdr.SectHdrEntrySize-sizeof(_TElfSectHdr_);
  aStream.Position:=fElfHdr.SectHdrOffset;
  for i:=0 to fElfHdr.SectHdrNum-1 do
  begin
    aStream.ReadBuffer(fSectHeaders[i],sizeof(fSectHeaders[i]));
    if delta>0 then aStream.Seek(delta,soFromCurrent);
    if fOppositeEndianess then
    begin
      fSectHeaders[i].NameIdx:=SwapEndian(fSectHeaders[i].NameIdx);
      fSectHeaders[i]._Type:=SwapEndian(fSectHeaders[i]._Type);
      fSectHeaders[i].Flags:=SwapEndian(fSectHeaders[i].Flags);
      fSectHeaders[i].Address:=SwapEndian(fSectHeaders[i].Address);
      fSectHeaders[i].Offset:=SwapEndian(fSectHeaders[i].Offset);
      fSectHeaders[i].Size:=SwapEndian(fSectHeaders[i].Size);
      fSectHeaders[i].Link:=SwapEndian(fSectHeaders[i].Link);
      fSectHeaders[i].Info:=SwapEndian(fSectHeaders[i].Info);
      fSectHeaders[i].AddrAlign:=SwapEndian(fSectHeaders[i].AddrAlign);
      fSectHeaders[i].EntSize:=SwapEndian(fSectHeaders[i].EntSize);
    end;
  end;
end;

procedure _TElfSubReader_.ReadStringTable(aStream: TStream);
begin
  if ((fElfHdr.NameTableIndex<=0) or
      (fElfHdr.NameTableIndex>=fElfHdr.SectHdrNum)) then
    raise EElfResourceReaderNoStringTableException.Create('');
  aStream.Position:=fSectHeaders[fElfHdr.NameTableIndex].Offset;
  fStringTable:=TObjectStringTable.Create(aStream,fSectHeaders[fElfHdr.NameTableIndex].Size);
end;

function _TElfSubReader_.FindSection(const aName : string) : integer;
var i : integer;
    sectname : string;
begin
  for i:=1 to fElfHdr.SectHdrNum-1 do
  begin
    sectname:=fStringTable.Get(fSectHeaders[i].NameIdx);
    if sectname=aName then
    begin
      Result:=i;
      exit;
    end;
  end;
  Result:=-1;
end;

procedure _TElfSubReader_.ReadRelocations(aStream : TStream);
begin
  fRelocations:=_TElfRelocTable_.Create(aStream,fSectHeaders[fRelSectIdx],fOppositeEndianess);
end;

procedure _TElfSubReader_.ReadDynamicRelocations(aStream : TStream);
var
  index : integer;
  relativeType : cardinal;
begin
  if (fElfHdr._Type<>ET_DYN) or (sizeof(_Tword_)<>8) then exit;
  case fMachineType of
    EM_X86_64: relativeType:=R_X86_64_RELATIVE;
    EM_AARCH64: relativeType:=R_AARCH64_RELATIVE;
    else exit;
  end;
  index:=FindSection('.rela.dyn');
  if index<>-1 then
  begin
    if (fSectHeaders[index]._Type<>SHT_RELA) or
       (fSectHeaders[index].EntSize<>sizeof(_TElfRela_)) then
      raise EElfResourceReaderException.Create('Invalid ELF dynamic relocation section');
    fDynamicRelocations:=_TElfRelocTable_.Create(aStream,fSectHeaders[index],
      fOppositeEndianess,relativeType);
  end;
end;

function _TElfSubReader_.PointerValue(aOffset, aStoredValue : _Tword_) : _Tword_;
begin
  if fNeedsReloc then
    Result:=fRelocations.Get(aOffset)
  else if Assigned(fDynamicRelocations) then
  begin
    { Interpret the relative addend at load base zero for offline metadata. }
    if not fDynamicRelocations.TryGet(fSectHeaders[fSectIdx].address+aOffset,Result) then
      Result:=aStoredValue;
  end
  else
    Result:=aStoredValue;
end;

procedure _TElfSubReader_.ReadResHeader(aStream: TStream);
begin
  aStream.Position:=fSectHeaders[fSectIdx].offset;
  aStream.ReadBuffer(fResHdr,sizeof(fResHdr));
  if fOppositeEndianess then
  begin
    fResHdr.rootptr:=SwapEndian(fResHdr.rootptr);
    fResHdr.count:=SwapEndian(fResHdr.count);
  end;
  fResHdr.rootptr:=PointerValue(0,fResHdr.rootptr);
  aStream.Position:=fSectHeaders[fSectIdx].offset+fResHdr.rootptr-fSectHeaders[fSectIdx].address;
end;

procedure _TElfSubReader_.ReadNode(aStream : TStream; aParent : TResourceTreeNode;
      aResources : TResources; named : boolean);
var infonode : _TResInfoNode_;
    aNode : TResourceTreeNode;
    i : integer;
    oldpos : int64;
    baseofs : _Tword_;
begin
  baseofs:=aStream.Position-fSectHeaders[fSectIdx].offset;
  aStream.ReadBuffer(infonode,sizeof(infonode));
  oldpos:=aStream.Position;
  if fOppositeEndianess then
  begin
    infonode.nameid:=SwapEndian(infonode.nameid);
    infonode.ncount:=SwapEndian(infonode.ncount);
    infonode.idcountsize:=SwapEndian(infonode.idcountsize);
    infonode.subptr:=SwapEndian(infonode.subptr);
  end;
  if named then infonode.nameid:=PointerValue(baseofs,infonode.nameid);
  infonode.subptr:=PointerValue(baseofs+(sizeof(_Tword_)+sizeof(longword)*2),infonode.subptr);
  if aParent=nil then aNode:=fRoot
  else
  begin
    if named then dummyDesc.Name:=ReadString(aStream,
      fSectHeaders[fSectIdx].offset+infonode.nameid-fSectHeaders[fSectIdx].address)
    else dummyDesc.ID:=infonode.nameid;
    aNode:=aParent.CreateSubNode(dummyDesc);
  end;
  aStream.Position:=fSectHeaders[fSectIdx].offset+infonode.subptr-fSectHeaders[fSectIdx].address;
  if aNode.IsLeaf then
    ReadResData(aStream,aNode,aResources,infonode.idcountsize)
  else
  begin
    for i:=1 to infonode.ncount do
      ReadNode(aStream,aNode,aResources,true);
    for i:=1 to infonode.idcountsize do
      ReadNode(aStream,aNode,aResources,false);
  end;
  aStream.Position:=oldpos;
end;

procedure _TElfSubReader_.Load(aResources: TResources; aStream: TStream);
begin
  ReadElfHeader(aStream);
  ReadSectionHeaders(aStream);
  ReadStringTable(aStream);
  if not FindResSection then exit;
  try
    if fNeedsReloc then ReadRelocations(aStream)
    else ReadDynamicRelocations(aStream);
    ReadResHeader(aStream);
    if fResHdr.count=0 then exit; //no resources in this file
    LoadResources(aResources,aStream);
  finally
    if fNeedsReloc then
      FreeAndNil(fRelocations);
    FreeAndNil(fDynamicRelocations);
  end;
end;


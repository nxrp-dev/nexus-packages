{*****************************************************************************}
{
    This file is part of the Free Pascal's "Free Components Library".
    Copyright (c) 2003 by Mazen NEIFER of the Free Pascal development team

    BMP writer implementation.

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
}
{*****************************************************************************}

{ - 22/11/2007 Modified by Laurent Jacques for support all format }

{$mode objfpc}
{$h+}

{$IFNDEF FPC_DOTTEDUNITS}
unit FPReadTGA;
{$ENDIF FPC_DOTTEDUNITS}

interface

{$IFDEF FPC_DOTTEDUNITS}
uses FpImage, System.Classes, System.SysUtils, FpImage.Common.Targa;
{$ELSE FPC_DOTTEDUNITS}
uses FpImage, classes, sysutils, targacmn;
{$ENDIF FPC_DOTTEDUNITS}

const
  TARGA_EMPTY_IMAGE = 0;
  TARGA_INDEXED_IMAGE = 1;
  TARGA_TRUECOLOR_IMAGE = 2;
  TARGA_GRAY_IMAGE = 3;

type

  { TFPReaderTarga }

  TFPReaderTarga = class (TFPCustomImageReader)
  Private
    Procedure FreeBuffers;       // Free (and nil) buffers.
  protected
    Header         : TTargaHeader;
    AlphaBits      : Byte;
    Identification : ShortString;
    Compressed,
    BottomUp       : Boolean;
    BytesPerPixel  : Byte;
    FPalette       : PFPColor;
    FScanLine      : PByte;
    FLineSize      : Integer;
    FPaletteSize   : Integer;
    FBlockCount    : Integer;
    FPixelCount    : Integer;
    FLastPixel     : Packed Array[0..3] of byte;
    // AnalyzeHeader will allocate the needed buffers.
    Procedure AnalyzeHeader(Img : TFPCustomImage);
    procedure CreateGrayPalette;
    Procedure ReadPalette(AStream : TStream);
    procedure ReadScanLine(Row : Integer; Stream : TStream); virtual;
    procedure WriteScanLine(Row : Integer; Img : TFPCustomImage); virtual;
    // required by TFPCustomImageReader
    procedure InternalRead  (Stream:TStream; Img:TFPCustomImage); override;
    function  InternalCheck (Stream:TStream) : boolean; override;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;

Implementation

Constructor TFPReaderTarga.Create;

begin
  inherited Create;
end;

Destructor TFPReaderTarga.Destroy;

begin
  FreeBuffers;
  Inherited;
end;

Procedure TFPReaderTarga.FreeBuffers;

begin
  If (FScanLine<>Nil) then
    begin
    FreeMem(FScanLine);
    FScanLine:=Nil;
    end;
  If (FPalette<>Nil) then
    begin
    FreeMem(FPalette);
    FPalette:=Nil;
    end;
end;

Procedure TFPReaderTarga.AnalyzeHeader(Img : TFPCustomImage);

begin
  With Header do
    begin
    if not (ImgType in [1,2,3,9,10,11]) or
      (ToWord(Width)=0) or (ToWord(Height)=0) or
      not (MapType in [0,1]) or (Flags and $C0<>0) then
      raise FPImageException.Create('Invalid Targa header');
    case ImgType of
      1,9: if (PixelSize<>8) or (MapType<>1) or
        not (MapEntrySize in [16,24,32]) or (ToWord(MapLength)=0) then
          raise FPImageException.Create('Unsupported Targa color map');
      2,10: if not (PixelSize in [16,24,32]) or (MapType<>0) then
          raise FPImageException.Create('Unsupported Targa truecolor depth');
      3,11: if not (PixelSize in [8,16]) or (MapType<>0) then
          raise FPImageException.Create('Unsupported Targa grayscale depth');
    end;
    BottomUp:=(Flags and $20) <>0;
    AlphaBits := Flags and $0F;
    BytesPerPixel:=PixelSize;
    Compressed:=ImgType>8;
    If Compressed then
      ImgType:=ImgType-8;
    FLineSize:=(BytesPerPixel div 8)*ToWord(Width);
    GetMem(FScanLine,FLineSize);

    if ImgType = TARGA_GRAY_IMAGE then
      FPaletteSize:=SizeOf(TFPColor)*256
    else
      FPaletteSize:=SizeOf(TFPColor)*ToWord(MapLength);
    GetMem(FPalette,FPaletteSize);
    Img.Width:=ToWord(Width);
    Img.Height:=ToWord(Height);
    end;
end;

Procedure TFPReaderTarga.CreateGrayPalette;

Var
  I : Integer;

Begin
  For I:=0 To 255 Do
  Begin
    With FPalette[I] do
      begin
      Red:=I*257;
      Green:=I*257;
      Blue:=I*257;
      Alpha:=AlphaOpaque;
      end;
  end;
End;

function Targa16Color(AValue: Word; AAlphaBits: Byte): TFPColor;
begin
  Result.Red:=((AValue shr 10) and 31)*65535 div 31;
  Result.Green:=((AValue shr 5) and 31)*65535 div 31;
  Result.Blue:=(AValue and 31)*65535 div 31;
  Result.Alpha:=AlphaOpaque;
  if (AAlphaBits=1) and (AValue and $8000=0) then
    Result.Alpha:=AlphaTransparent;
end;

procedure TFPReaderTarga.ReadPalette(AStream: TStream);
var
  lEntry: TBGRAEntry;
  lWord: TWordRec;
  lIndex: Integer;
begin
  for lIndex:=0 to ToWord(Header.MapLength)-1 do
    if Header.MapEntrySize=16 then
    begin
      AStream.ReadBuffer(lWord,SizeOf(lWord));
      FPalette[lIndex]:=Targa16Color(ToWord(lWord),AlphaBits);
    end
    else
    begin
      lEntry.Alpha:=255;
      AStream.ReadBuffer(lEntry,(Header.MapEntrySize div 8));
      FPalette[lIndex].Red:=lEntry.Red*257;
      FPalette[lIndex].Green:=lEntry.Green*257;
      FPalette[lIndex].Blue:=lEntry.Blue*257;
      FPalette[lIndex].Alpha:=AlphaOpaque;
      if (Header.MapEntrySize=32) and (AlphaBits=8) then
        FPalette[lIndex].Alpha:=lEntry.Alpha*257;
    end;
end;

Procedure TFPReaderTarga.InternalRead  (Stream:TStream; Img:TFPCustomImage);

var
  H,Row : Integer;

begin
  FreeBuffers;
  FBlockCount:=0;
  FPixelCount:=0;
  Stream.ReadBuffer(Header,SizeOf(Header));
  try
  AnalyzeHeader(Img);
  If Header.IdLen>0 then
    begin
    SetLength(Identification,Header.IDLen);
    Stream.ReadBuffer(Identification[1],Header.Idlen);
    If Length(Identification)<>0 then
      Img.Extra[KeyIdentification]:=Identification;
    end;

  If Header.MapType<>0 then
    ReadPalette(Stream);
  if Header.ImgType = TARGA_GRAY_IMAGE then
    CreateGrayPalette;

  H:=Img.height;
  If BottomUp then
    For Row:=0 to H-1 do
      begin
      ReadScanLine(Row,Stream);
      WriteScanLine(Row,Img);
      end
  else
    For Row:=H-1 downto 0 do
      begin
      ReadScanLine(Row,Stream);
      WriteScanLine(Row,Img);
      end;
  finally
    FreeBuffers;
  end;
end;

Procedure TFPReaderTarga.ReadScanLine(Row : Integer; Stream : TStream);

Var
  P : PByte;
  B : Byte;
  I,J : Integer;

begin
  If Not Compressed then
    Stream.ReadBuffer(FScanLine^,FLineSize)
  else
    begin
    P:=FScanLine;
    For I:=0 to ToWord(Header.Width)-1 do
      begin
      If (FPixelCount>0) then
        Dec(FPixelCount)
      else
        begin
        Dec(FBlockCount);
        If (FBlockCount<0) then
          begin
          Stream.ReadBuffer(B,1);
          If (B and $80)<>0 then
            begin
            FPixelCount:=B and $7F;
            FblockCount:=0;
            end
          else
            FBlockCount:=B and $7F
          end;
        Stream.ReadBuffer(FlastPixel,BytesPerPixel shr 3);
        end;
      For J:=0 to (BytesPerPixel shr 3)-1 do
        begin
        P[0]:=FLastPixel[j];
        Inc(P);
        end;
      end;
    end;
end;

Procedure TFPReaderTarga.WriteScanLine(Row : Integer; Img : TFPCustomImage);

Var
  Col : Integer;
  C   : TFPColor;
  W   : Word;
  P   : PByte;

  function ImageColumn(AColumn: Integer): Integer;
  begin
    if Header.Flags and $10<>0 then
      Result:=Img.Width-1-AColumn
    else
      Result:=AColumn;
  end;

begin
  C.Alpha:=AlphaOpaque;
  P:=FScanLine;
  Case Header.ImgType of
    TARGA_INDEXED_IMAGE
      : for Col:=0 to Img.width-1 do
        begin
          if (P[Col]<ToWord(Header.MapStart)) or
            (Integer(P[Col])-ToWord(Header.MapStart)>=ToWord(Header.MapLength)) then
            raise FPImageException.Create('Targa palette index out of range');
          Img.Colors[ImageColumn(Col),Row]:=FPalette[P[Col]-ToWord(Header.MapStart)];
        end;
    TARGA_TRUECOLOR_IMAGE
      : for Col:=0 to Img.Width-1 do
          begin
          // Fill C depending on number of pixels.
          case BytesPerPixel of
          8,16 : begin
                 W:=P[0];
                 inc(P);
                 W:=W or (P[0] shl 8);
                 C:=Targa16Color(W,AlphaBits);
                end;
          24,32 : With C do
                  begin
                  Blue:=P[0] or (P[0] shl 8);
                  Inc(P);
                  Green:=P[0] or (P[0] shl 8);
                  Inc(P);
                  Red:=P[0] or (P[0] shl 8);
                  If bytesPerPixel=32 then
                    begin
                    Inc(P);
                    Alpha:=AlphaOpaque;
                    if AlphaBits=8 then
                      Alpha:=P[0]*257;
                    end;
                  end;
          end; // Case BytesPerPixel;
          Img[ImageColumn(Col),Row]:=C;
          Inc(P);
          end;
    TARGA_GRAY_IMAGE
      :  case BytesPerPixel of
           8 : for Col:=0 to Img.width-1 do
                 Img.Colors[ImageColumn(Col),Row]:=FPalette[P[Col]];
          16 : for Col:=0 to Img.width-1 do
               begin
                 With C do
                 begin
                   Blue:=FPalette[P^].blue;
                   Green:=FPalette[P^].green;
                   Red:=FPalette[P^].red;
                   Inc(P);
                   Alpha:=AlphaOpaque;
                   if AlphaBits=8 then
                     Alpha:=P[0]*257;
                   Inc(P);
                 end;
               Img[ImageColumn(Col),Row]:=C;
               end;
         end;
  end;
end;

function  TFPReaderTarga.InternalCheck (Stream:TStream) : boolean;

var
  hdr: TTargaHeader;
  oldPos: Int64;
  n: Integer;

begin
  Result:=False;
  if Stream = nil then
    exit;
  oldPos := Stream.Position;
  try
    n := SizeOf(hdr);
    Result:=(Stream.Read(hdr, n)=n)
            and (hdr.ImgType in [1, 2, 3, 9, 10, 11])
            and (hdr.PixelSize in [8, 16, 24, 32]);
  finally
    Stream.Position := oldPos;
  end;
end;


initialization
  ImageHandlers.RegisterImageReader ('TARGA Format', 'tga', TFPReaderTarga);
end.

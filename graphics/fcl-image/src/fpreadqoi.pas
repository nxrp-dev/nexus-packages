{
    This file is part of the Free Pascal run time library.
    Copyright (c) 2022 by the Free Pascal development team

    QOI reader implementation

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
{$mode objfpc}{$h+}
{$IFNDEF FPC_DOTTEDUNITS}
unit FPReadQoi;
{$ENDIF FPC_DOTTEDUNITS}

interface

{$IFDEF FPC_DOTTEDUNITS}
uses FpImage, System.Classes, System.SysUtils, FpImage.Common.QOI;
{$ELSE FPC_DOTTEDUNITS}
uses FpImage, classes, sysutils, QoiComn;
{$ENDIF FPC_DOTTEDUNITS}

type
  TFPReaderQoi = class (TFPCustomImageReader)
    Private
      QoiHeader : TQoiHeader;  // The header as read from the stream.
      function getUseAlpha:boolean;
    protected
      // required by TFPCustomImageReader
      procedure InternalRead  (AStream:TStream; AImage:TFPCustomImage); override;
      function  InternalCheck (Stream:TStream) : boolean; override;
    public
      constructor Create; override;
      property UseAlpha : boolean read getUseAlpha;
  end;

implementation


function RGBAToFPColor(Const RGBA: TQoiPixel) : TFPcolor;

begin
  with Result, RGBA do
    begin
    Red   :=(R shl 8) or R;
    Green :=(G shl 8) or G;
    Blue  :=(B shl 8) or B;
    Alpha :=(A shl 8) or A;
    end;
end;


Constructor TFPReaderQoi.create;

begin
  inherited create;
end;

function TFPReaderQoi.getUseAlpha:boolean;
begin
     result := (QoiHeader.channels=qoChannelRGBA);
end;

function  TFPReaderQoi.InternalCheck (Stream:TStream) : boolean;
// NOTE: Does not rewind the stream!
var

  n: Int64;
begin
  Result:=False;
  if Stream=nil then
    exit;
  n:=SizeOf(TQoiHeader);
  Result:=Stream.Read(QoiHeader,n)=n;
  if Result then
    begin
   {$IFDEF ENDIAN_LITTLE}
    QoiHeader.width:=SwapEndian(QoiHeader.width);
    QoiHeader.height:=SwapEndian(QoiHeader.height);
   {$ENDIF}
    Result := (QoiHeader.magic = 'qoif'); // Just check magic number
    end;
end;

// InternalCheck has consumed the header; decode bounded chunks from this position.
procedure TFPReaderQoi.InternalRead(AStream: TStream; AImage: TFPCustomImage);
const
  cEndMarker: array[0..7] of Byte = (0,0,0,0,0,0,0,1);
var
  lPixel: TQoiPixel;
  lIndex: array[0..63] of TQoiPixel;
  lMarker: array[0..7] of Byte;
  lTag, lNext: Byte;
  lGreen, lRun, lX, lY, lI: Integer;
  lRemaining: QWord;
begin
  lRemaining:=QWord(QoiHeader.Width)*QoiHeader.Height;
  if (QoiHeader.Width=0) or (QoiHeader.Height=0) or
    (QoiHeader.Width>High(Integer)) or (QoiHeader.Height>High(Integer)) or
    (lRemaining>QWord(High(SizeInt)) div SizeOf(TFPColor)) or
    not (QoiHeader.Channels in [3,4]) or (QoiHeader.ColorSpace>1) then
    raise FPImageException.Create('Invalid QOI header');
  if (AStream.Size-AStream.Position<8) or
    (lRemaining>QWord(AStream.Size-AStream.Position-8)*62) then
    raise FPImageException.Create('Incomplete QOI image');
  AImage.SetSize(QoiHeader.Width,QoiHeader.Height);
  FillChar(lIndex,SizeOf(lIndex),0);
  FillChar(lPixel,SizeOf(lPixel),0);
  lPixel.A:=255;
  lX:=0; lY:=0;
  while lRemaining>0 do
  begin
    AStream.ReadBuffer(lTag,1);
    lRun:=1;
    case lTag of
      $FE: begin
        AStream.ReadBuffer(lPixel.R,1);
        AStream.ReadBuffer(lPixel.G,1);
        AStream.ReadBuffer(lPixel.B,1);
      end;
      $FF: AStream.ReadBuffer(lPixel,SizeOf(lPixel));
    else
      case lTag shr 6 of
        0: lPixel:=lIndex[lTag and 63];
        1: begin
          lPixel.R:=(Integer(lPixel.R)+((lTag shr 4) and 3)-2) and $FF;
          lPixel.G:=(Integer(lPixel.G)+((lTag shr 2) and 3)-2) and $FF;
          lPixel.B:=(Integer(lPixel.B)+(lTag and 3)-2) and $FF;
        end;
        2: begin
          AStream.ReadBuffer(lNext,1);
          lGreen:=(lTag and 63)-32;
          lPixel.R:=(Integer(lPixel.R)+lGreen+(lNext shr 4)-8) and $FF;
          lPixel.G:=(Integer(lPixel.G)+lGreen) and $FF;
          lPixel.B:=(Integer(lPixel.B)+lGreen+(lNext and 15)-8) and $FF;
        end;
        3: lRun:=(lTag and 63)+1;
      end;
    end;
    if QWord(lRun)>lRemaining then
      raise FPImageException.Create('QOI run exceeds image dimensions');
    lIndex[QoiPixelIndex(lPixel)]:=lPixel;
    for lI:=1 to lRun do
    begin
      AImage[lX,lY]:=RGBAToFPColor(lPixel);
      Inc(lX);
      if lX=AImage.Width then begin lX:=0; Inc(lY); end;
    end;
    Dec(lRemaining,lRun);
  end;
  AStream.ReadBuffer(lMarker,SizeOf(lMarker));
  if not CompareMem(@lMarker,@cEndMarker,SizeOf(lMarker)) then
    raise FPImageException.Create('Invalid QOI end marker');
end;

initialization
  ImageHandlers.RegisterImageReader ('QOI Format', 'qoi', TFPReaderQoi);
end.


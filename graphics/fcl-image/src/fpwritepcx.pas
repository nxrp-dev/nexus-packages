{ Copyright (C) 2007 Laurent Jacques

  This library is free software; you can redistribute it and/or modify it
  under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 2 of the License, or (at your
  option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
  for more details.

  You should have received a copy of the GNU Library General Public License
  along with this library; if not, write to the Free Software Foundation,
  Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

  Save in format 24 bits compressed or not

  2023-07  - Massimo Magnano
           - added Resolution support
}

{$IFNDEF FPC_DOTTEDUNITS}
unit FPWritePCX;
{$ENDIF FPC_DOTTEDUNITS}

{$mode objfpc}{$H+}

interface

{$IFDEF FPC_DOTTEDUNITS}
uses FpImage, System.Classes, System.SysUtils;
{$ELSE FPC_DOTTEDUNITS}
uses FpImage, Classes, SysUtils;
{$ENDIF FPC_DOTTEDUNITS}

type

  TFPWriterPCX = class(TFPCustomImageWriter)
  private
    FCompressed: boolean;
  protected
    function SaveHeader(Stream: TStream; Img: TFPCustomImage): boolean; virtual;
    procedure InternalWrite(Stream: TStream; Img: TFPCustomImage); override;
    procedure writeline(Stream: TStream; buffer: PByte; bytes: integer);
  public
    property Compressed: boolean Read FCompressed Write FCompressed;
  end;

implementation

{$IFDEF FPC_DOTTEDUNITS}
uses FpImage.Common.PCX;
{$ELSE FPC_DOTTEDUNITS}
uses pcxcomn;
{$ENDIF FPC_DOTTEDUNITS}

function TFPWriterPCX.SaveHeader(Stream: TStream; Img: TFPCustomImage): boolean;
var
  Header: TPCXHeader;
begin
  Result := False;
  if (Img.Width<1) or (Img.Width>65534) or (Img.Height<1) or
    (Img.Height>65536) then
    raise FPImageException.Create('Invalid PCX dimensions');
  FillChar(Header, SizeOf(Header), 0);
  with Header do
  begin
    FileID  := $0a;
    Version := 5;
    if Compressed then
      Encoding := 1
    else
      Encoding := 0;
    BitsPerPixel := 8;
    XMin := 0;
    YMin := 0;
    XMax := Img.Width - 1;
    YMax := Img.Height - 1;

    Img.ResolutionUnit :=ruPixelsPerInch;
    HRes :=Trunc(Img.ResolutionX);
    VRes :=Trunc(Img.ResolutionY);

    ColorPlanes := 3;
    BytesPerLine := (Img.Width+1) and not 1;
    PaletteType := 1;
  end;
  Stream.WriteBuffer(Header, SizeOf(Header));
  Result := True;
end;

procedure TFPWriterPCX.writeline(Stream: TStream; buffer: PByte; bytes: integer);
var
  Value, Count: byte;
  tmp: byte;
  P:   PByte;
begin
  P := Buffer;
  while bytes > 0 do
  begin
    Value := P[0];
    Inc(P);
    Dec(bytes);
    Count := 1;
    while (bytes < 0) and (Count < 63) and (P[0] = Value) do
    begin
      Inc(Count);
      Inc(P);
      Dec(bytes);
    end;
    if (Value < $c0) and (Count = 1) then
    begin
      Stream.WriteBuffer(Value, 1);
    end
    else
    begin
      tmp := $c0 + Count;
      Stream.WriteBuffer(tmp, 1);
      Stream.WriteBuffer(Value, 1);
    end;
  end;
end;

procedure TFPWriterPCX.InternalWrite(Stream: TStream; Img: TFPCustomImage);
var
  Row, Col, WriteSize, lStride: integer;
  Aline, P: PByte;
  C:    TFPColor;
  Totalwrite: longint;
  continue: boolean;
  Rect: TRect;
begin
  Rect.Left   := 0;
  Rect.Top    := 0;
  Rect.Right  := 0;
  Rect.Bottom := 0;
  continue    := True;
  TotalWrite  := 0;
  Progress(psStarting, 0, False, Rect, '', continue);
  SaveHeader(Stream, Img);
  lStride:=(Img.Width+1) and not 1;
  WriteSize:=lStride*3;
  GetMem(aLine, WriteSize);
  TotalWrite := Img.Height * Img.Width;
  try
    for Row := 0 to Img.Height - 1 do
    begin
      FillChar(ALine^,WriteSize,0);
      P := ALine;
      for Col := 0 to Img.Width - 1 do
      begin
        C      := Img.Colors[Col, Row];
        P[Col + lStride * 2] := C.Blue shr 8;
        P[Col + lStride] := C.Green shr 8;
        P[Col] := C.Red shr 8;
        Progress(psRunning, trunc(100.0 * (Row * Col / TotalWrite)),
          False, Rect, '', continue);
        if not continue then
          exit;
      end;
      if Compressed then
        writeline(Stream, aLine, WriteSize)
      else
        Stream.WriteBuffer(aLine[0], WriteSize);
    end;
    Progress(psEnding, 100, False, Rect, '', continue);
  finally
    FreeMem(aLine);
  end;
end;

{ end TFPWriterPCX}

initialization
  ImageHandlers.RegisterImageWriter('PCX Format', 'pcx', TFPWriterPCX);
end.

// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit obFCLImageProbe;
{$mode objfpc}{$H+}
interface
uses obNXTestContext;
procedure RunFCLImageProbe(AId: Integer; const ADirectory: string; AContext: TNXTestContext);
implementation
uses Classes, SysUtils, FPImage, FPReadQoi, FPWriteQoi, FPReadPNM, FPWritePNM,
  FPReadPCX, FPWritePCX, PCXComn, FPReadTGA, FPWriteTGA, TargaCmn,
  FPWriteBMP, FPReadBMP, FPWriteTiff, FTFont, Dynlibs;

type
  TShortWriteStream = class(TMemoryStream)
  private
    FLimit: Int64;
  public
    function Write(const ABuffer; ACount: LongInt): LongInt; override;
    property Limit: Int64 read FLimit write FLimit;
  end;

function TShortWriteStream.Write(const ABuffer; ACount: LongInt): LongInt;
begin
  if Position + ACount > FLimit then
    ACount:=FLimit-Position;
  if ACount<0 then ACount:=0;
  Result := inherited Write(ABuffer, ACount);
end;

function Color(ARed, AGreen, ABlue: Word; AAlpha: Word = $FFFF): TFPColor;
begin
  Result.Red:=ARed; Result.Green:=AGreen; Result.Blue:=ABlue; Result.Alpha:=AAlpha;
end;

procedure AssertColor(AContext: TNXTestContext; const AExpected, AActual: TFPColor);
begin
  AContext.AssertEquals(AExpected.Red,AActual.Red,'Red');
  AContext.AssertEquals(AExpected.Green,AActual.Green,'Green');
  AContext.AssertEquals(AExpected.Blue,AActual.Blue,'Blue');
  AContext.AssertEquals(AExpected.Alpha,AActual.Alpha,'Alpha');
end;

procedure PutBytes(AStream: TStream; const ABytes: array of Byte);
begin
  if Length(ABytes)>0 then AStream.WriteBuffer(ABytes[0],Length(ABytes));
end;

procedure PutText(AStream: TStream; const AText: RawByteString);
begin
  if AText<>'' then AStream.WriteBuffer(AText[1],Length(AText));
end;

procedure QOI(AStream: TMemoryStream; AWidth,AHeight: Byte;
  const AData: array of Byte; AMarker: Boolean = True);
begin
  AStream.Clear;
  PutBytes(AStream,[$71,$6F,$69,$66,0,0,0,AWidth,0,0,0,AHeight,4,0]);
  PutBytes(AStream,AData);
  if AMarker then PutBytes(AStream,[0,0,0,0,0,0,0,1]);
  AStream.Position:=0;
end;

procedure Load(AStream: TMemoryStream; AImage: TFPCustomImage;
  AReader: TFPCustomImageReader);
begin
  AStream.Position:=0;
  AImage.LoadFromStream(AStream,AReader);
end;

procedure Reject(AContext: TNXTestContext; AStream: TMemoryStream;
  AImage: TFPCustomImage; AReader: TFPCustomImageReader; const AMessage: string);
var lRejected: Boolean;
begin
  lRejected:=False;
  try Load(AStream,AImage,AReader);
  except on lError: FPImageException do lRejected:=True;
    on lError: EReadError do lRejected:=True;
  end;
  AContext.AssertTrue(lRejected,AMessage);
end;

procedure ProbeQOI(AId: Integer; AContext: TNXTestContext);
var
  lStream: TMemoryStream;
  lImage: TFPMemoryImage;
  lReader: TFPReaderQoi;
  lWriter: TFPWriterQoi;
  lIndex: Integer;
begin
  lStream:=TMemoryStream.Create; lImage:=TFPMemoryImage.Create(1,1);
  lReader:=TFPReaderQoi.Create; lWriter:=TFPWriterQoi.Create;
  try
    case AId of
      1: begin
        QOI(lStream,1,1,[53]); Load(lStream,lImage,lReader);
        AssertColor(AContext,Color(0,0,0,0),lImage[0,0]);
      end;
      2: begin
        QOI(lStream,1,1,[$40]); Load(lStream,lImage,lReader);
        AssertColor(AContext,Color($FEFE,$FEFE,$FEFE),lImage[0,0]);
        QOI(lStream,1,1,[$80,$00]); Load(lStream,lImage,lReader);
        AssertColor(AContext,Color($D8D8,$E0E0,$D8D8),lImage[0,0]);
        lImage.SetSize(3,1);
        lImage[0,0]:=Color($FFFF,$FFFF,$FFFF);
        lImage[1,0]:=Color($FEFE,$FDFD,$FCFC);
        lImage[2,0]:=Color(0,0,0);
        lStream.Clear; lImage.SaveToStream(lStream,lWriter);
        Load(lStream,lImage,lReader);
        AssertColor(AContext,Color($FEFE,$FDFD,$FCFC),lImage[1,0]);
      end;
      3: begin
        QOI(lStream,1,1,[$FE,$12],False);
        Reject(AContext,lStream,lImage,lReader,'Truncated RGB chunk accepted');
        QOI(lStream,1,1,[$C0],False);
        Reject(AContext,lStream,lImage,lReader,'Missing marker accepted');
        QOI(lStream,1,1,[$C1]);
        Reject(AContext,lStream,lImage,lReader,'Oversized run accepted');
        QOI(lStream,2,1,[]);
        Reject(AContext,lStream,lImage,lReader,'Early marker accepted');
        QOI(lStream,0,1,[]);
        Reject(AContext,lStream,lImage,lReader,'Zero width accepted');
        QOI(lStream,1,1,[$C0]); lStream.Position:=12; PutBytes(lStream,[2]);
        Reject(AContext,lStream,lImage,lReader,'Invalid channel count accepted');
        QOI(lStream,3,1,[$FF,10,20,30,40,$C0,$FE,11,22,33]);
        Load(lStream,lImage,lReader);
        AssertColor(AContext,Color(10*257,20*257,30*257,40*257),lImage[1,0]);
        AssertColor(AContext,Color(11*257,22*257,33*257,40*257),lImage[2,0]);
        // Runs may span rows and are capped at 62 by the encoder.
        lImage.SetSize(65,2);
        for lIndex:=0 to 129 do lImage[lIndex mod 65,lIndex div 65]:=colBlack;
        lStream.Clear; lImage.SaveToStream(lStream,lWriter);
        Load(lStream,lImage,lReader);
        AssertColor(AContext,colBlack,lImage[64,1]);
      end;
    end;
  finally lWriter.Free; lReader.Free; lImage.Free; lStream.Free; end;
end;

procedure ProbePNM(AId: Integer; AContext: TNXTestContext);
var
  lStream: TMemoryStream;
  lImage: TFPMemoryImage;
  lReader: TFPReaderPNM;
  lWriter: TFPWriterPNM;
  lIndex: Integer;
begin
  lStream:=TMemoryStream.Create; lImage:=TFPMemoryImage.Create(1,1);
  lReader:=TFPReaderPNM.Create; lWriter:=TFPWriterPNM.Create;
  try
    case AId of
      4: begin
        PutText(lStream,'P2'#10'1 1'#10'65535'#10'4660'#10);
        Load(lStream,lImage,lReader);
        AssertColor(AContext,Color($1234,$1234,$1234),lImage[0,0]);
        lStream.Clear; PutText(lStream,'P5'#10'1 1'#10'1023'#10);
        PutBytes(lStream,[$03,$FF]); Load(lStream,lImage,lReader);
        AssertColor(AContext,colWhite,lImage[0,0]);
        lStream.Clear; PutText(lStream,'P3'#10'1 1'#10'65535'#10'4660 0 65535'#10);
        Load(lStream,lImage,lReader);
        AssertColor(AContext,Color($1234,0,$FFFF),lImage[0,0]);
        lStream.Clear; PutText(lStream,'P6'#10'1 1'#10'1023'#10);
        PutBytes(lStream,[3,255,0,0,2,0]); Load(lStream,lImage,lReader);
        AssertColor(AContext,Color($FFFF,0,(Int64(512)*65535) div 1023),lImage[0,0]);
        lStream.Clear; PutText(lStream,'P5'#10'1 1'#10'65536'#10); PutBytes(lStream,[0,0]);
        Reject(AContext,lStream,lImage,lReader,'Invalid PNM maximum accepted');
      end;
      14: begin
        PutText(lStream,'P2'#10'1 1'#10'255'#10'255 '#10);
        Load(lStream,lImage,lReader);
        lStream.Clear; PutText(lStream,'P2'#10'1 1'#10'255'#10'0 '#10);
        Load(lStream,lImage,lReader); AssertColor(AContext,colBlack,lImage[0,0]);
      end;
      5: begin
        lImage[0,0]:=colRed;
        AContext.AssertEquals(Ord(pcdRGB),Ord(lWriter.GuessColorDepthOfImage(lImage)));
        lImage.SaveToStream(lStream,lWriter); Load(lStream,lImage,lReader);
        AssertColor(AContext,colRed,lImage[0,0]);
        lImage[0,0]:=Color(128,128,128);
        AContext.AssertEquals(Ord(pcdGrayscale),Ord(lWriter.GuessColorDepthOfImage(lImage)));
      end;
      6: begin
        lWriter.BinaryFormat:=False;
        for lIndex:=0 to 1 do
        begin
          if lIndex=0 then lWriter.ColorDepth:=pcdGrayscale else lWriter.ColorDepth:=pcdRGB;
          lImage[0,0]:=colWhite; lStream.Clear;
          lImage.SaveToStream(lStream,lWriter);
          Load(lStream,lImage,lReader); AssertColor(AContext,colWhite,lImage[0,0]);
        end;
      end;
    end;
  finally lWriter.Free; lReader.Free; lImage.Free; lStream.Free; end;
end;

procedure PCXHeader(AStream: TMemoryStream; APlanes,ABits,AWidth,AStride,AEncoding: Byte);
var lHeader: TPCXHeader;
begin
  AStream.Clear; FillChar(lHeader,SizeOf(lHeader),0);
  lHeader.FileID:=$0A; lHeader.Version:=5; lHeader.Encoding:=AEncoding;
  lHeader.BitsPerPixel:=ABits; lHeader.XMax:=AWidth-1; lHeader.ColorPlanes:=APlanes;
  lHeader.BytesPerLine:=AStride; lHeader.PaletteType:=1;
  lHeader.ColorMap[1].Red:=255;
  AStream.WriteBuffer(lHeader,SizeOf(lHeader));
end;

procedure Palette256(AStream: TStream);
var lPalette: array[0..767] of Byte;
begin
  FillChar(lPalette,SizeOf(lPalette),0); lPalette[0]:=255;
  PutBytes(AStream,[$0C]); AStream.WriteBuffer(lPalette,SizeOf(lPalette));
end;

procedure ProbePCX(AId: Integer; const ADirectory: string; AContext: TNXTestContext);
var
  lStream: TMemoryStream; lImage: TFPMemoryImage;
  lReader: TFPReaderPCX; lWriter: TFPWriterPCX;
  lHeader: TPCXHeader; lByte: Byte; lIndex: Integer;
begin
  lStream:=TMemoryStream.Create; lImage:=TFPMemoryImage.Create(1,1);
  lReader:=TFPReaderPCX.Create; lWriter:=TFPWriterPCX.Create;
  try
    case AId of
      7: begin
        PCXHeader(lStream,1,8,1,2,0); PutBytes(lStream,[0,0]); Palette256(lStream);
        Load(lStream,lImage,lReader); AssertColor(AContext,colRed,lImage[0,0]);
        PCXHeader(lStream,4,1,1,2,0); PutBytes(lStream,[$80,0,0,0,0,0,0,0]);
        Load(lStream,lImage,lReader); AssertColor(AContext,colRed,lImage[0,0]);
      end;
      8: begin
        PCXHeader(lStream,3,8,3,2,0); PutBytes(lStream,[0,0,0,0,0,0]);
        Reject(AContext,lStream,lImage,lReader,'Undersized PCX row accepted');
        PCXHeader(lStream,1,4,1,2,0); PutBytes(lStream,[0,0]);
        Reject(AContext,lStream,lImage,lReader,'Unsupported packed PCX depth accepted');
        PCXHeader(lStream,3,8,1,2,1); PutBytes(lStream,[$C0,0]);
        Reject(AContext,lStream,lImage,lReader,'Zero-length PCX run accepted');
        PCXHeader(lStream,3,8,1,2,1); PutBytes(lStream,[$C7,0]);
        Reject(AContext,lStream,lImage,lReader,'Oversized PCX run accepted');
        PCXHeader(lStream,3,8,1,2,0); PutBytes(lStream,[0]);
        Reject(AContext,lStream,lImage,lReader,'Truncated PCX row accepted');
      end;
      12: begin
        lImage[0,0]:=Color($1111,$2222,$3333);
        for lIndex:=0 to 1 do
        begin
          lWriter.Compressed:=lIndex<>0; lStream.Clear; lImage.SaveToStream(lStream,lWriter);
          lStream.Position:=0; lStream.ReadBuffer(lHeader,SizeOf(lHeader));
          AContext.AssertEquals(2,lHeader.BytesPerLine,'PCX requires an even plane stride');
          if lIndex=0 then
          begin
            lStream.ReadBuffer(lByte,1); AContext.AssertEquals($11,lByte);
            lStream.ReadBuffer(lByte,1); AContext.AssertEquals(0,lByte);
            lStream.ReadBuffer(lByte,1); AContext.AssertEquals($22,lByte);
            lStream.ReadBuffer(lByte,1); AContext.AssertEquals(0,lByte);
            lStream.ReadBuffer(lByte,1); AContext.AssertEquals($33,lByte);
          end;
          lStream.SaveToFile(IncludeTrailingPathDelimiter(ADirectory)+'odd-width.pcx');
          Load(lStream,lImage,lReader);
          AssertColor(AContext,Color($1111,$2222,$3333),lImage[0,0]);
        end;
      end;
    end;
  finally lWriter.Free; lReader.Free; lImage.Free; lStream.Free; end;
end;

procedure TGAHeader(AStream: TMemoryStream; AType,ABits,AMapBits,AMapLength,AFlags: Byte);
var lHeader: TTargaHeader;
begin
  AStream.Clear; FillChar(lHeader,SizeOf(lHeader),0);
  lHeader.ImgType:=AType; lHeader.PixelSize:=ABits;
  lHeader.Width:=FromWord(1); lHeader.Height:=FromWord(1); lHeader.Flags:=AFlags;
  if AMapBits<>0 then lHeader.MapType:=1;
  lHeader.MapEntrySize:=AMapBits; lHeader.MapLength:=FromWord(AMapLength);
  AStream.WriteBuffer(lHeader,SizeOf(lHeader));
end;

procedure ProbeTGA(AId: Integer; AContext: TNXTestContext);
var
  lStream: TMemoryStream; lImage: TFPMemoryImage;
  lReader: TFPReaderTarga; lIndex: Integer;
begin
  lStream:=TMemoryStream.Create; lImage:=TFPMemoryImage.Create(1,1);
  lReader:=TFPReaderTarga.Create;
  try
    case AId of
      9: begin
        TGAHeader(lStream,1,8,32,1,$28); PutBytes(lStream,[10,20,30,128,0]);
        Load(lStream,lImage,lReader);
        AssertColor(AContext,Color(30*257,20*257,10*257,128*257),lImage[0,0]);
        TGAHeader(lStream,1,8,16,1,$20); PutBytes(lStream,[0,$7C,0]);
        Load(lStream,lImage,lReader); AssertColor(AContext,colRed,lImage[0,0]);
        TGAHeader(lStream,2,16,0,0,$20); PutBytes(lStream,[$FF,$7F]);
        Load(lStream,lImage,lReader); AssertColor(AContext,colWhite,lImage[0,0]);
        TGAHeader(lStream,2,32,0,0,$28); PutBytes(lStream,[10,20,30,64]);
        Load(lStream,lImage,lReader);
        AssertColor(AContext,Color(30*257,20*257,10*257,64*257),lImage[0,0]);
        TGAHeader(lStream,3,16,0,0,$28); PutBytes(lStream,[255,64]);
        Load(lStream,lImage,lReader);
        AssertColor(AContext,Color($FFFF,$FFFF,$FFFF,64*257),lImage[0,0]);
      end;
      10: begin
        TGAHeader(lStream,10,24,0,0,$20); PutBytes(lStream,[$80,0,0,255]);
        Load(lStream,lImage,lReader); AssertColor(AContext,colRed,lImage[0,0]);
        for lIndex:=0 to 3 do
        begin
          TGAHeader(lStream,10,24,0,0,$20); PutBytes(lStream,[$80,255,0,0]);
          Load(lStream,lImage,lReader); AssertColor(AContext,colBlue,lImage[0,0]);
        end;
        TGAHeader(lStream,10,24,0,0,$20);
        lStream.Position:=12; PutBytes(lStream,[2,0,2,0]);
        lStream.Position:=lStream.Size; PutBytes(lStream,[$03,0,0,255]);
        Reject(AContext,lStream,lImage,lReader,'Truncated TGA accepted');
        TGAHeader(lStream,10,24,0,0,$20); PutBytes(lStream,[$80,255,0,0]);
        Load(lStream,lImage,lReader); AssertColor(AContext,colBlue,lImage[0,0]);
      end;
      15: begin
        TGAHeader(lStream,2,24,0,0,$30);
        lStream.Position:=12; PutBytes(lStream,[2,0]);
        lStream.Position:=lStream.Size; PutBytes(lStream,[0,0,255,255,0,0]);
        Load(lStream,lImage,lReader);
        AssertColor(AContext,colBlue,lImage[0,0]);
        AssertColor(AContext,colRed,lImage[1,0]);
      end;
      13: begin
        TGAHeader(lStream,1,8,24,1,$20); PutBytes(lStream,[0,0,255,1]);
        Reject(AContext,lStream,lImage,lReader,'Out-of-range TGA index accepted');
        TGAHeader(lStream,2,8,0,0,$20); PutBytes(lStream,[0]);
        Reject(AContext,lStream,lImage,lReader,'Invalid truecolor depth accepted');
        TGAHeader(lStream,1,24,24,1,$20); PutBytes(lStream,[0,0,255,0,0,0]);
        Reject(AContext,lStream,lImage,lReader,'Invalid indexed depth accepted');
      end;
    end;
  finally lReader.Free; lImage.Free; lStream.Free; end;
end;

procedure ProbeShortWrites(AContext: TNXTestContext);
var
  lImage: TFPMemoryImage; lStream: TShortWriteStream;
  lWriter: TFPCustomImageWriter; lIndex,lStage: Integer;
  lRejected: Boolean; lMissed: string;
begin
  lImage:=TFPMemoryImage.Create(2,1); lStream:=TShortWriteStream.Create;
  try
    lImage[0,0]:=colRed; lImage[1,0]:=colBlue; lMissed:='';
    for lIndex:=0 to 5 do
      for lStage:=0 to 1 do
      begin
        case lIndex of
          0: lWriter:=TFPWriterBMP.Create;
          1: lWriter:=TFPWriterPCX.Create;
          2: lWriter:=TFPWriterPNM.Create;
          3: lWriter:=TFPWriterQoi.Create;
          4: lWriter:=TFPWriterTarga.Create;
          5: lWriter:=TFPWriterTiff.Create;
        end;
        try
          lStream.Clear;
          if lIndex=3 then
          begin lImage[0,0]:=colBlack; lImage[1,0]:=colBlack; end
          else begin lImage[0,0]:=colRed; lImage[1,0]:=colBlue; end;
          if lStage=0 then lStream.Limit:=0
          else case lIndex of
            0: lStream.Limit:=54;
            1: lStream.Limit:=128;
            2: lStream.Limit:=11;
            3: lStream.Limit:=14;
            4: lStream.Limit:=18;
            5: lStream.Limit:=8;
          end;
          lRejected:=False;
          try lImage.SaveToStream(lStream,lWriter);
          except on lError: EWriteError do lRejected:=True; end;
          if not lRejected then lMissed:=lMissed+lWriter.ClassName+' stage '+IntToStr(lStage)+'; ';
        finally lWriter.Free; end;
      end;
    AContext.AssertEquals('',lMissed,'Writers silently accepted short output');
  finally lStream.Free; lImage.Free; end;
end;

procedure ProbeBMP(AContext: TNXTestContext; AWidth: Integer; ARead: Boolean);
var
  lImage: TFPMemoryImage;
  lStream: TMemoryStream;
  lWriter: TFPWriterBMP;
  lReader: TFPReaderBMP;
begin
  lImage:=TFPMemoryImage.Create(AWidth,1); lStream:=TMemoryStream.Create;
  lWriter:=TFPWriterBMP.Create; lReader:=TFPReaderBMP.Create;
  try
    lImage.UsePalette:=True; lImage.Palette.Clear;
    lImage.Palette.Add(colRed); lImage.Palette.Add(colBlue); lImage.Palette.Add(colWhite);
    lImage[0,0]:=colRed; lImage[1,0]:=colBlue; lImage[2,0]:=colWhite;
    if AWidth=4 then lImage[3,0]:=colWhite;
    lWriter.BitsPerPixel:=4; lWriter.RLECompress:=True;
    lImage.SaveToStream(lStream,lWriter);
    AContext.AssertTrue(lStream.Size>60,'Missing BMP data');
    if ARead then
    begin
      Load(lStream,lImage,lReader);
      AssertColor(AContext,colRed,lImage[0,0]);
      AssertColor(AContext,colWhite,lImage[2,0]);
    end;
  finally lReader.Free; lWriter.Free; lStream.Free; lImage.Free; end;
end;

procedure ProbeFreeType(AContext: TNXTestContext);
{$IFDEF LINUX}
var lLibrary: TLibHandle;
{$ENDIF}
begin
  {$IFDEF LINUX}
  lLibrary:=LoadLibrary('libfreetype.so.6');
  if lLibrary=NilHandle then
    AContext.Skip('FreeType runtime is not installed.');
  UnloadLibrary(lLibrary);
  try
    InitEngine;
    AContext.AssertTrue(Assigned(FontMgr),'Default font engine did not initialize');
  finally DoneEngine; end;
  {$ELSE}
  AContext.Skip('Linux runtime-loader regression.');
  {$ENDIF}
end;

procedure RunFCLImageProbe(AId: Integer; const ADirectory: string; AContext: TNXTestContext);
begin
  case AId of
    1..3: ProbeQOI(AId,AContext);
    4..6,14: ProbePNM(AId,AContext);
    7,8,12: ProbePCX(AId,ADirectory,AContext);
    9,10,13,15: ProbeTGA(AId,AContext);
    11: ProbeShortWrites(AContext);
    16: ProbeBMP(AContext,3,False);
    17: ProbeBMP(AContext,4,True);
    18: ProbeFreeType(AContext);
  else raise Exception.Create('Unknown image probe'); end;
end;
end.

// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit tsPasJPEGTests;
{$mode objfpc}{$H+}
interface
uses obNXTestRegistry;
procedure RegisterPasJPEGTests(ARegistry: TNXTestRegistry);
implementation
uses
  Classes, SysUtils, PasJPEG, tpPasJPEGBitmap, jpeglib, jerror, jmorecfg, jinclude,
  jcapimin, jcapistd, jcparam, jdatadst, jdapimin, jdapistd, jdatasrc,
  obNXTestContext, obNXTestSuite;

const
  cWidth = 17;
  cHeight = 13;
var
  lLastProgress: Integer;

procedure Progress(AValue: Integer);
begin
  lLastProgress := AValue;
end;

procedure TestBitmapHeaderSizes(AContext: TNXTestContext);
begin
  AContext.AssertEquals(14, SizeOf(TBitmapFileHeader));
  AContext.AssertEquals(12, SizeOf(TBitmapCoreHeader));
  AContext.AssertEquals(40, SizeOf(TBitmapInfoHeader));
end;

procedure WriteWord(AStream: TStream; AValue: Word);
var lBytes: array[0..1] of Byte;
begin
  lBytes[0] := AValue and $FF;
  lBytes[1] := AValue shr 8;
  AStream.WriteBuffer(lBytes, SizeOf(lBytes));
end;

procedure WriteLong(AStream: TStream; AValue: LongWord);
var lBytes: array[0..3] of Byte;
begin
  lBytes[0] := AValue and $FF;
  lBytes[1] := (AValue shr 8) and $FF;
  lBytes[2] := (AValue shr 16) and $FF;
  lBytes[3] := AValue shr 24;
  AStream.WriteBuffer(lBytes, SizeOf(lBytes));
end;

function ReadWord(AStream: TStream; AOffset: Int64): Word;
var lBytes: array[0..1] of Byte;
begin
  AStream.Position := AOffset;
  AStream.ReadBuffer(lBytes, SizeOf(lBytes));
  Result := lBytes[0] or (Word(lBytes[1]) shl 8);
end;

function ReadLong(AStream: TStream; AOffset: Int64): LongWord;
var lBytes: array[0..3] of Byte;
begin
  AStream.Position := AOffset;
  AStream.ReadBuffer(lBytes, SizeOf(lBytes));
  Result := lBytes[0] or (LongWord(lBytes[1]) shl 8) or
    (LongWord(lBytes[2]) shl 16) or (LongWord(lBytes[3]) shl 24);
end;

function MakeBitmap(AGap, ATrailer: Integer): TMemoryStream;
var
  lRow: array[0..51] of Byte;
  lX, lY, lIndex: Integer;
  lByte: Byte;
begin
  Result := TMemoryStream.Create;
  WriteWord(Result, $4D42);
  WriteLong(Result, 54 + AGap + SizeOf(lRow) * cHeight + ATrailer);
  WriteLong(Result, 0);
  WriteLong(Result, 54 + AGap);
  WriteLong(Result, 40);
  WriteLong(Result, cWidth);
  WriteLong(Result, cHeight);
  WriteWord(Result, 1);
  WriteWord(Result, 24);
  WriteLong(Result, 0);
  WriteLong(Result, SizeOf(lRow) * cHeight);
  for lIndex := 1 to 4 do WriteLong(Result, 0);
  lByte := $A5;
  for lIndex := 1 to AGap do Result.WriteBuffer(lByte, 1);
  for lY := cHeight - 1 downto 0 do
  begin
    FillChar(lRow, SizeOf(lRow), 0);
    for lX := 0 to cWidth - 1 do
    begin
      lRow[lX * 3] := (lX * 7 + lY * 3) mod 256;
      lRow[lX * 3 + 1] := (lX * 5 + lY * 11) mod 256;
      lRow[lX * 3 + 2] := (lX * 13 + lY * 2) mod 256;
    end;
    Result.WriteBuffer(lRow, SizeOf(lRow));
  end;
  lByte := $5A;
  for lIndex := 1 to ATrailer do Result.WriteBuffer(lByte, 1);
  Result.Position := 0;
end;

procedure TestConvenienceAPI(AContext: TNXTestContext);
var lInput, lJPEG, lBitmap: TMemoryStream;
begin
  lInput := MakeBitmap(0, 0);
  lJPEG := TMemoryStream.Create;
  lBitmap := TMemoryStream.Create;
  try
    lLastProgress := -1;
    StoreJPEG(lInput, lJPEG, True, 90, @Progress);
    AContext.AssertEquals(100, lLastProgress, 'Compression completion callback');
    AContext.AssertTrue(lJPEG.Size > 0);
    lJPEG.Position := 0;
    lLastProgress := -1;
    LoadJPEG(lJPEG, lBitmap, True, 0, @Progress);
    AContext.AssertEquals(100, lLastProgress, 'Decompression completion callback');
    AContext.AssertEquals(cWidth, ReadLong(lBitmap, 18));
    AContext.AssertEquals(cHeight, ReadLong(lBitmap, 22));
    AContext.AssertEquals(24, ReadWord(lBitmap, 28));
    AContext.AssertEquals(lBitmap.Size, ReadLong(lBitmap, 2));
  finally
    lBitmap.Free;
    lJPEG.Free;
    lInput.Free;
  end;
end;

procedure TestStoreNilCallback(AContext: TNXTestContext);
var lInput, lJPEG: TMemoryStream;
begin
  lInput := MakeBitmap(0, 0);
  lJPEG := TMemoryStream.Create;
  try
    StoreJPEG(lInput, lJPEG, True, 90, nil);
    AContext.AssertTrue(lJPEG.Size > 0);
  finally
    lJPEG.Free;
    lInput.Free;
  end;
end;

procedure TestLoadNilCallback(AContext: TNXTestContext);
var lInput, lJPEG, lBitmap: TMemoryStream;
begin
  lInput := MakeBitmap(0, 0);
  lJPEG := TMemoryStream.Create;
  lBitmap := TMemoryStream.Create;
  try
    StoreJPEG(lInput, lJPEG, True, 90, @Progress);
    lJPEG.Position := 0;
    LoadJPEG(lJPEG, lBitmap, True, 0, nil);
    AContext.AssertEquals(cWidth, ReadLong(lBitmap, 18));
  finally
    lBitmap.Free;
    lJPEG.Free;
    lInput.Free;
  end;
end;

procedure CheckBitmapLayout(AContext: TNXTestContext; AInMemory: Boolean;
  AGap, ATrailer: Integer);
var lPlain, lPadded, lExpected, lActual: TMemoryStream;
begin
  lPlain := MakeBitmap(0, 0);
  lPadded := MakeBitmap(AGap, ATrailer);
  lExpected := TMemoryStream.Create;
  lActual := TMemoryStream.Create;
  try
    StoreJPEG(lPlain, lExpected, AInMemory, 90, @Progress);
    StoreJPEG(lPadded, lActual, AInMemory, 90, @Progress);
    AContext.AssertEquals(lExpected.Size, lActual.Size, 'Bitmap layout changed JPEG length');
    AContext.AssertTrue(CompareMem(lExpected.Memory, lActual.Memory, lExpected.Size),
      'Bitmap padding/trailing bytes changed encoded pixels');
  finally
    lActual.Free;
    lExpected.Free;
    lPadded.Free;
    lPlain.Free;
  end;
end;

procedure TestBitmapGapBuffered(AContext: TNXTestContext);
begin CheckBitmapLayout(AContext, True, 64, 0); end;
procedure TestBitmapTrailerSeek(AContext: TNXTestContext);
begin CheckBitmapLayout(AContext, False, 0, 52); end;
procedure TestBitmapGapSeek(AContext: TNXTestContext);
begin CheckBitmapLayout(AContext, False, 64, 0); end;

procedure TestQuantizedOutput(AContext: TNXTestContext);
var lInput, lJPEG, lBitmap: TMemoryStream;
begin
  lInput := MakeBitmap(0, 0);
  lJPEG := TMemoryStream.Create;
  lBitmap := TMemoryStream.Create;
  try
    StoreJPEG(lInput, lJPEG, True, 90, @Progress);
    lJPEG.Position := 0;
    LoadJPEG(lJPEG, lBitmap, True, 32, @Progress);
    AContext.AssertEquals(8, ReadWord(lBitmap, 28));
    AContext.AssertEquals(1078, ReadLong(lBitmap, 10));
    AContext.AssertEquals(1078 + 20 * cHeight, lBitmap.Size);
    AContext.AssertEquals(lBitmap.Size, ReadLong(lBitmap, 2));
  finally
    lBitmap.Free;
    lJPEG.Free;
    lInput.Free;
  end;
end;

procedure JPEGError(AInfo: j_common_ptr);
var lMessage: ShortString;
begin
  AInfo^.err^.format_message(AInfo, lMessage);
  raise Exception.Create(lMessage);
end;

procedure CheckCoreCodec(AContext: TNXTestContext; AProgressive: Boolean;
  ADCT: J_DCT_METHOD; AScale: Integer);
var
  lCompress: jpeg_compress_struct;
  lDecompress: jpeg_decompress_struct;
  lError: jpeg_error_mgr;
  lStream: TStream;
  lRow: array[0..cWidth * 3 - 1] of JSAMPLE;
  lRowPointer: JSAMPROW;
  lIndex: Integer;
begin
  lStream := TMemoryStream.Create;
  try
    lCompress.err := jpeg_std_error(lError);
    lError.error_exit := @JPEGError;
    jpeg_create_compress(@lCompress);
    try
      jpeg_stdio_dest(@lCompress, @lStream);
      lCompress.image_width := cWidth;
      lCompress.image_height := cHeight;
      lCompress.input_components := 3;
      lCompress.in_color_space := JCS_RGB;
      jpeg_set_defaults(@lCompress);
      lCompress.dct_method := ADCT;
      if AProgressive then jpeg_simple_progression(@lCompress);
      jpeg_start_compress(@lCompress, True);
      lRowPointer := @lRow;
      while lCompress.next_scanline < cHeight do
      begin
        for lIndex := 0 to High(lRow) do lRow[lIndex] := 128;
        AContext.AssertEquals(1, jpeg_write_scanlines(@lCompress, @lRowPointer, 1));
      end;
      jpeg_finish_compress(@lCompress);
    finally
      jpeg_destroy_compress(@lCompress);
    end;
    lStream.Position := 0;
    lDecompress.err := jpeg_std_error(lError);
    lError.error_exit := @JPEGError;
    jpeg_create_decompress(@lDecompress);
    try
      jpeg_stdio_src(@lDecompress, @lStream);
      jpeg_read_header(@lDecompress, True);
      lDecompress.dct_method := ADCT;
      lDecompress.scale_num := 1;
      lDecompress.scale_denom := AScale;
      jpeg_start_decompress(@lDecompress);
      AContext.AssertEquals((cWidth + AScale - 1) div AScale, lDecompress.output_width);
      AContext.AssertEquals((cHeight + AScale - 1) div AScale, lDecompress.output_height);
      while lDecompress.output_scanline < lDecompress.output_height do
      begin
        AContext.AssertEquals(1, jpeg_read_scanlines(@lDecompress, @lRowPointer, 1));
        for lIndex := 0 to lDecompress.output_width * 3 - 1 do
          AContext.AssertTrue(Abs(Integer(lRow[lIndex]) - 128) <= 1,
            'Neutral gray changed during JPEG roundtrip');
      end;
      jpeg_finish_decompress(@lDecompress);
    finally
      jpeg_destroy_decompress(@lDecompress);
    end;
  finally
    lStream.Free;
  end;
end;

procedure TestBaselineCodec(AContext: TNXTestContext);
begin CheckCoreCodec(AContext, False, JDCT_ISLOW, 1); end;
procedure TestProgressiveCodec(AContext: TNXTestContext);
begin CheckCoreCodec(AContext, True, JDCT_ISLOW, 1); end;
procedure TestFastCodec(AContext: TNXTestContext);
begin CheckCoreCodec(AContext, False, JDCT_IFAST, 1); end;
procedure TestFloatCodec(AContext: TNXTestContext);
begin CheckCoreCodec(AContext, False, JDCT_FLOAT, 1); end;
procedure TestScaledCodec(AContext: TNXTestContext);
begin CheckCoreCodec(AContext, True, JDCT_ISLOW, 8); end;

procedure RegisterPasJPEGTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('PasJPEG');
  lSuite.AddTest('BitmapHeaderSizes', @TestBitmapHeaderSizes);
  lSuite.AddTest('PublicConvenienceAPI', @TestConvenienceAPI);
  lSuite.AddTest('StoreNilCallback', @TestStoreNilCallback);
  lSuite.AddTest('LoadNilCallback', @TestLoadNilCallback);
  lSuite.AddTest('BitmapGapBuffered', @TestBitmapGapBuffered);
  lSuite.AddTest('BitmapTrailerSeek', @TestBitmapTrailerSeek);
  lSuite.AddTest('BitmapGapSeek', @TestBitmapGapSeek);
  lSuite.AddTest('QuantizedOutput', @TestQuantizedOutput);
  lSuite.AddTest('BaselineCodec', @TestBaselineCodec);
  lSuite.AddTest('ProgressiveCodec', @TestProgressiveCodec);
  lSuite.AddTest('FastCodec', @TestFastCodec);
  lSuite.AddTest('FloatCodec', @TestFloatCodec);
  lSuite.AddTest('ScaledCodec', @TestScaledCodec);
end;
end.

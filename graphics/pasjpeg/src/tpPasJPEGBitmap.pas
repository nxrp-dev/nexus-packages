// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit tpPasJPEGBitmap;
{$mode objfpc}{$H+}
interface
type
  TBitmapFileHeader = packed record
    bfType: Word;
    bfSize: LongWord;
    bfReserved1, bfReserved2: Word;
    bfOffBits: LongWord;
  end;
  TBitmapCoreHeader = packed record
    bcSize: LongWord;
    bcWidth, bcHeight, bcPlanes, bcBitCount: Word;
  end;
  TBitmapInfoHeader = packed record
    biSize: LongWord;
    biWidth, biHeight: LongInt;
    biPlanes, biBitCount: Word;
    biCompression, biSizeImage: LongWord;
    biXPelsPerMeter, biYPelsPerMeter: LongInt;
    biClrUsed, biClrImportant: LongWord;
  end;
implementation
end.

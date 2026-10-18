{
    This file is part of the Free Component Library

    libiconv-based XML decoder.
    Copyright (c) 2009 by Sergei Gorelkin, sergei_gorelkin@mail.ru

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
{$IFNDEF FPC_DOTTEDUNITS}
unit xmliconv;
{$ENDIF FPC_DOTTEDUNITS}

{$mode objfpc}
{$h+}

interface

implementation

{$IFDEF FPC_DOTTEDUNITS}
uses
  Xml.Read, UnixApi.Iconvenc, UnixApi.Types, UnixApi.Base, System.InitC;
{$ELSE FPC_DOTTEDUNITS}
uses
  xmlread, iconvenc, unixtype, baseunix, initc;
{$ENDIF FPC_DOTTEDUNITS}

const
  utf16_encoding = 'UTF-16LE';

function Iconv_Decode(AContext: Pointer; AInBuf: PAnsiChar;
  var AInCount: Cardinal; AOutBuf: PWideChar;
  var AOutCount: Cardinal): Integer; stdcall;
var
  lOutBytes, lInBytes, lStatus: size_t;
  lConverted: Cardinal;
begin
  lOutBytes := AOutCount * SizeOf(WideChar);
  lInBytes := AInCount;
  lStatus := iconv(AContext, @AInBuf, @lInBytes, @AOutBuf, @lOutBytes);
  lConverted := AOutCount - lOutBytes div SizeOf(WideChar);
  AInCount := lInBytes;
  AOutCount := lOutBytes div SizeOf(WideChar);
  Result := lConverted;
  if lStatus = High(size_t) then
    case cerrno of
      ESysE2BIG, ESysEINVAL: ; // Preserve the successfully converted prefix.
    else
      Result := -cerrno;
    end;
end;

procedure Iconv_Cleanup(Context: Pointer); stdcall;
begin
  iconv_close(Context);
end;

function GetIconvDecoder(const AEncoding: string; out Decoder: TDecoder): Boolean; stdcall;
var
  f: iconv_t;
begin
  f := iconv_open(utf16_encoding, PAnsiChar(AEncoding));
  if f <> Pointer(-1) then
  begin
    Decoder.Context := f;
    Decoder.Decode := @Iconv_Decode;
    Decoder.Cleanup := @Iconv_Cleanup;
    Result := True;
  end
  else
    Result := False;
end;

initialization
  RegisterDecoder(@GetIconvDecoder);

end.

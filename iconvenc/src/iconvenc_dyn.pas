{
    This file is part of the Free Pascal run time library.
    Copyright (c) 2000 by Marco van de Voort(marco@freepascal.org)
    member of the Free Pascal development team

    libiconv header translation + a helper routine
    http://wiki.freepascal.org/iconvenc Dynamic version

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright. (LGPL)

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

}
{$IFNDEF FPC_DOTTEDUNITS}
unit iconvenc_dyn;
{$ENDIF FPC_DOTTEDUNITS}

interface
{$mode objfpc}{$H+}

{$IFDEF FPC_DOTTEDUNITS}
uses
  System.CTypes,UnixApi.Types,UnixApi.Base,
  UnixApi.Dl,
  System.InitC;
{$ELSE FPC_DOTTEDUNITS}
uses
  ctypes,unixtype,baseunix,
  dl,
  initc;
{$ENDIF FPC_DOTTEDUNITS}

const
  n = 1;


type
   piconv_t = ^iconv_t;
   iconv_t = pointer;

   Ticonv_open = function(__tocode: PAnsiChar; __fromcode: PAnsiChar): iconv_t; cdecl;
   Ticonv = function(__cd: iconv_t; __inbuf: PPAnsiChar; __inbytesleft: psize_t; __outbuf: PPAnsiChar; __outbytesleft: psize_t): size_t; cdecl;
   Ticonv_close = function(__cd: iconv_t): cint; cdecl;

var
  iconv_lib: pointer;
  iconv_open: Ticonv_open;
  iconv: Ticonv;
  iconv_close: Ticonv_close;
  IconvLibFound: boolean = False;

function TryLoadLib(ALibraryName: string; var AError: String): boolean; // can be used to load non standard libname
function Iconvert(AInput: AnsiString; var AOutput: AnsiString; const AFromEncoding, AToEncoding: AnsiString): cint;
function InitIconv(var AError: AnsiString): boolean;

implementation

function TryLoadLib(ALibraryName: string; var AError: String): boolean;
var
  lHandle, lPrevious: Pointer;
  lConvert: Ticonv;
  lOpen: Ticonv_open;
  lClose: Ticonv_close;

  function ResolveSymbols(const APrefix: AnsiString): Boolean;
  begin
    lConvert := Ticonv(dlsym(lHandle, PAnsiChar(APrefix + 'iconv')));
    lOpen := Ticonv_open(dlsym(lHandle, PAnsiChar(APrefix + 'iconv_open')));
    lClose := Ticonv_close(dlsym(lHandle, PAnsiChar(APrefix + 'iconv_close')));
    Result := Assigned(lConvert) and Assigned(lOpen) and Assigned(lClose);
  end;

begin
  AError := AError + #13#10 + 'Trying ' + ALibraryName;
  lHandle := dlopen(PAnsiChar(ALibraryName), RTLD_NOW);
  if lHandle = nil then
  begin
    AError := AError + #13#10 + dlerror();
    Exit(False);
  end;
  Result := ResolveSymbols('');
  if not Result then Result := ResolveSymbols('lib');
  if not Result then
  begin
    AError := AError + #13#10 + 'Missing iconv entry points';
    dlclose(lHandle);
    Exit;
  end;
  lPrevious := iconv_lib;
  iconv_lib := lHandle;
  iconv := lConvert;
  iconv_open := lOpen;
  iconv_close := lClose;
  IconvLibFound := True;
  if lPrevious <> nil then dlclose(lPrevious);
end;

function InitIconv(var AError: string): boolean;
begin
  AError := '';
  if IconvLibFound then Exit(True);
  Result := TryLoadLib('libc.so.6', AError);
  if not Result then Result := TryLoadLib('libiconv.so', AError);
end;

{$i iconvert.inc}

finalization
  if iconv_lib <> nil then dlclose(iconv_lib);
end.

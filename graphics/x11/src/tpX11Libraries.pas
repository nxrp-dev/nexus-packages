// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
{$IFNDEF FPC_DOTTEDUNITS}
unit tpX11Libraries;
{$ENDIF}
{$mode objfpc}
interface
const
  {$IFDEF LINUX}
  libX11 = 'libX11.so.6';
  libXext = 'libXext.so.6';
  libXft = 'libXft.so.2';
  libXrender = 'libXrender.so.1';
  libXi = 'libXi.so.6';
  libXrandr = 'libXrandr.so.2';
  libXfixes = 'libXfixes.so.3';
  libXinerama = 'libXinerama.so.1';
  libXv = 'libXv.so.1';
  libXxf86vm = 'libXxf86vm.so.1';
  libXxf86dga = 'libXxf86dga.so.1';
  libFontconfig = 'libfontconfig.so.1';
  {$ELSE}
  libX11 = 'X11';
  libXext = 'Xext';
  libXrender = 'Xrender';
  libXi = 'Xi';
  libXrandr = 'Xrandr';
  libXfixes = 'Xfixes';
  libXinerama = 'Xinerama';
  libXv = 'Xv';
  libXxf86vm = 'Xxf86vm';
  libXxf86dga = 'Xxf86dga';
    {$IFDEF DARWIN}
  libXft = 'libXft.dylib';
  libFontconfig = 'libfontconfig.dylib';
    {$ELSE}
  libXft = 'libXft.so';
  libFontconfig = 'libfontconfig.so';
    {$ENDIF}
  {$ENDIF}
implementation
end.

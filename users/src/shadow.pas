{$IFNDEF FPC_DOTTEDUNITS}
unit shadow;
{$ENDIF FPC_DOTTEDUNITS}
interface

{$IFDEF FPC_DOTTEDUNITS}
uses System.CTypes;
{$ELSE}
uses ctypes;
{$ENDIF}

{
  Automatically converted by H2Pas 0.99.15 from shadow.h
  The following command line parameters were used:
    -D
    -l
    c
    -p
    -s
    -u
    shadow
    -v
    shadow.h
}

  const
    External_library='c'; {Setup as you need}

  { Pointers to basic pascal types, inserted by h2pas conversion program.}
  Type
    PLongint  = ^Longint;
    PSmallInt = ^SmallInt;
    PByte     = ^Byte;
    PWord     = ^Word;
    PDWord    = ^DWord;
    PDouble   = ^Double;

{$PACKRECORDS C}


type
   PFile = Pointer;

   Pspwd = ^spwd;
   spwd = record
        sp_namp : PAnsiChar;
        sp_pwdp : PAnsiChar;
        sp_lstchg : clong;
        sp_min : clong;
        sp_max : clong;
        sp_warn : clong;
        sp_inact : clong;
        sp_expire : clong;
        sp_flag : culong;
     end;
  TPasswordFileEntry = spwd;
  PPasswordFileEntry = ^TPasswordFileEntry;

procedure setspent;cdecl;external External_library name 'setspent';
procedure endspent;cdecl;external External_library name 'endspent';
function getspent:Pspwd;cdecl;external External_library name 'getspent';
function getspnam(__name:PAnsiChar):Pspwd;cdecl;external External_library name 'getspnam';
function sgetspent(__string:PAnsiChar):Pspwd;cdecl;external External_library name 'sgetspent';
function fgetspent(__stream:PFILE):Pspwd;cdecl;external External_library name 'fgetspent';
function putspent(__p:Pspwd; __stream:PFILE):longint;cdecl;external External_library name 'putspent';
function lckpwdf:longint;cdecl;external External_library name 'lckpwdf';
function ulckpwdf:longint;cdecl;external External_library name 'ulckpwdf';


implementation


end.

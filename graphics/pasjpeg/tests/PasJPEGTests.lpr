// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program PasJPEGTests;
{$mode objfpc}{$H+}
uses
  HeapTrc,
  {$IFDEF UNIX}cthreads, cwstring,{$ENDIF}
  obNXTestRegistry, utNXTestConsole, tsPasJPEGTests;
var
  lRegistry: TNXTestRegistry;
begin
  HaltOnNotReleased := True;
  GlobalSkipIfNoLeaks := True;
  lRegistry := TNXTestRegistry.Create;
  try
    RegisterPasJPEGTests(lRegistry);
    ExitCode := RunConsoleTests(lRegistry);
  finally
    lRegistry.Free;
  end;
end.

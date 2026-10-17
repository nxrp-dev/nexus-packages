// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program FCLXMLBehaviorTests;
{$mode objfpc}{$H+}
uses
  {$IFDEF UNIX}cthreads, cwstring,{$ENDIF}
  obNXTestRegistry, utNXTestConsole,
  domunit,
  extras2,
  extras,
  readertest,
  readerunit;
var
  lRegistry: TNXTestRegistry;
begin
  lRegistry := TNXTestRegistry.Create;
  try
    RegisterdomunitTests(lRegistry);
    Registerextras2Tests(lRegistry);
    RegisterextrasTests(lRegistry);
    RegisterreadertestTests(lRegistry);
    RegisterreaderunitTests(lRegistry);
    ExitCode := RunConsoleTests(lRegistry);
  finally
    lRegistry.Free;
  end;
end.

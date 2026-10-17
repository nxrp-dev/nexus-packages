// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program FCLDBBehaviorTests;
{$mode objfpc}{$H+}
uses
  {$IFDEF UNIX}cthreads, cwstring,{$ENDIF}
  obNXTestRegistry, utNXTestConsole,
  tcgensql,
  testsqlscript,
  testdddiff,
  tcsqlscanner,
  tcparser;
var
  lRegistry: TNXTestRegistry;
begin
  lRegistry := TNXTestRegistry.Create;
  try
    RegistertcgensqlTests(lRegistry);
    RegistertestsqlscriptTests(lRegistry);
    RegistertestdddiffTests(lRegistry);
    RegistertcsqlscannerTests(lRegistry);
    RegistertcparserTests(lRegistry);
    ExitCode := RunConsoleTests(lRegistry);
  finally
    lRegistry.Free;
  end;
end.

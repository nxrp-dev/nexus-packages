// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program FCLJSONBehaviorTests;
{$mode objfpc}{$H+}
uses
  {$IFDEF UNIX}cthreads, cwstring,{$ENDIF}
  obNXTestRegistry, utNXTestConsole,
  testjsonrtti,
  testjsonparser,
  tcjsontocode,
  testjsonreader,
  testjsondata,
  jsonconftest,
  tcjsonini;
var
  lRegistry: TNXTestRegistry;
begin
  lRegistry := TNXTestRegistry.Create;
  try
    RegistertestjsonrttiTests(lRegistry);
    RegistertestjsonparserTests(lRegistry);
    RegistertcjsontocodeTests(lRegistry);
    RegistertestjsonreaderTests(lRegistry);
    RegistertestjsondataTests(lRegistry);
    RegisterjsonconftestTests(lRegistry);
    RegistertcjsoniniTests(lRegistry);
    ExitCode := RunConsoleTests(lRegistry);
  finally
    lRegistry.Free;
  end;
end.

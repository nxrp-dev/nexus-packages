// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program FCLDBRetained;
{$mode objfpc}{$H+}
uses {$IFDEF UNIX}cwstring,{$ENDIF} Classes, SysUtils, ConsoleTestRunner,
  tcsqlscanner, tcparser, tcgensql, testsqlscript, testdddiff;
var lRunner: TTestRunner;
begin
  DefaultRunAllTests:=True; DefaultFormat:=fPlain;
  lRunner:=TTestRunner.Create(nil);
  try lRunner.Initialize; lRunner.Run; finally lRunner.Free; end;
end.

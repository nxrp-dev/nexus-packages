(*
  Copyright (c) 2026 Kevin Collins.
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)
program NXSQLiteTests;

{$mode objfpc}{$H+}

uses SysUtils, obNXTestRegistry, obNXTestSuite, obNXTestResult, tsNXSQLiteTests,
  tsNXSQLiteBindingTests;

procedure Run;
var
  lRegistry: TNXTestRegistry;
  lResult: TNXTestResult;
  lSuite, lTest, lPassed: Integer;
begin
  lRegistry := TNXTestRegistry.Create;
  lPassed := 0;
  try
    RegisterNXSQLiteTests(lRegistry);
    RegisterNXSQLiteBindingTests(lRegistry);
    for lSuite := 0 to lRegistry.SuiteCount - 1 do
      for lTest := 0 to lRegistry.Suites[lSuite].TestCount - 1 do
      begin
        lResult := lRegistry.Suites[lSuite].Tests[lTest].Execute(lRegistry.Suites[lSuite].Name);
        try
          WriteLn(lResult.StatusText, ' ', lResult.TestId, ' ', lResult.Message, ' ', lResult.ErrorMessage);
          if lResult.Status <> tsPassed then
          begin
            WriteLn(lPassed, ' passed; 1 failed/errors/skipped; stopped at first failure');
            ExitCode := 1;
            Exit;
          end;
          Inc(lPassed);
        finally
          lResult.Free;
        end;
      end;
    WriteLn(lPassed, ' passed; 0 failed/errors/skipped');
    if lPassed = 0 then ExitCode := 1;
  finally
    lRegistry.Free;
  end;
end;

begin
  Run;
end.

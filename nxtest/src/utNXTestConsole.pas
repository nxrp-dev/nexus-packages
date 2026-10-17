// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit utNXTestConsole;

{$mode objfpc}{$H+}

interface

uses obNXTestRegistry;

function RunConsoleTests(ARegistry: TNXTestRegistry): Integer;

implementation

uses obNXTestResult;

function RunConsoleTests(ARegistry: TNXTestRegistry): Integer;
var
  lResult: TNXTestResult;
  lSuite, lTest, lPassed, lFailed, lErrors, lSkipped: Integer;
begin
  lPassed := 0;
  lFailed := 0;
  lErrors := 0;
  lSkipped := 0;
  for lSuite := 0 to ARegistry.SuiteCount - 1 do
    for lTest := 0 to ARegistry.Suites[lSuite].TestCount - 1 do
    begin
      lResult := ARegistry.Suites[lSuite].Tests[lTest].Execute(ARegistry.Suites[lSuite].Name);
      try
        case lResult.Status of
          tsPassed: Inc(lPassed);
          tsFailed: Inc(lFailed);
          tsError: Inc(lErrors);
          tsSkipped: Inc(lSkipped);
        end;
        WriteLn(lResult.StatusText, ' ', lResult.TestId, ' ', lResult.Message,
          ' ', lResult.ErrorClass, ' ', lResult.ErrorMessage);
        Flush(Output);
      finally
        lResult.Free;
      end;
    end;
  WriteLn(lPassed, ' passed; ', lFailed, ' failed; ', lErrors, ' errors; ',
    lSkipped, ' skipped');
  Result := Ord((lPassed = 0) or (lFailed + lErrors <> 0));
end;

end.

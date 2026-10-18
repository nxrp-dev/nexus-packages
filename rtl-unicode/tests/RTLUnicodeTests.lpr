// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program RTLUnicodeTests;
{$mode objfpc}
uses
  cp1252, fpwidestring, utRTLUnicodePolicyProbe, unicodeducet,
  UTF8Utils, graphemebreakproperty, eastasianwidth, cpbuildu, buildcollations,
  obNXTestRegistry, obNXTestSuite, obNXTestCase, obNXTestResult,
  utNXTestConsole, tsRTLUnicodeTests;
var
  lRegistry: TNXTestRegistry;
  lSuite: TNXTestSuite;
  lTest: TNXTestCase;
  lResult: TNXTestResult;
begin
  lRegistry := TNXTestRegistry.Create;
  try
    RegisterRTLUnicodeTests(lRegistry);
    if ParamCount = 0 then
      ExitCode := RunConsoleTests(lRegistry)
    else
    begin
      lTest := lRegistry.FindTest(ParamStr(1), lSuite);
      if lTest = nil then Halt(2);
      lResult := lTest.Execute(lSuite.Name);
      try
        WriteLn(lResult.StatusText, ' ', lResult.TestId, ' ', lResult.Message,
          ' ', lResult.ErrorClass, ' ', lResult.ErrorMessage);
        ExitCode := Ord(lResult.Status <> tsPassed);
      finally lResult.Free; end;
    end;
  finally
    lRegistry.Free;
  end;
end.

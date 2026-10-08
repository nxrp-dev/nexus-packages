(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

program NexusVirtualTreeViewTests;

{$mode objfpc}{$H+}

uses
  SysUtils, fpg_main, obNXTestRegistry, obNXTestSuite, obNXTestResult,
  tsNXVirtualTreeViewTests;

var
  lRegistry: TNXTestRegistry;
  lSuite: TNXTestSuite;
  lResult: TNXTestResult;
  lSuiteIndex, lTestIndex, lFailures, lCount: Integer;

begin
  fpgApplication.Initialize;
  lFailures := 0;
  lCount := 0;
  lRegistry := TNXTestRegistry.Create;
  try
    RegisterNXVirtualTreeViewTests(lRegistry);
    for lSuiteIndex := 0 to lRegistry.SuiteCount - 1 do
    begin
      lSuite := lRegistry.Suites[lSuiteIndex];
      for lTestIndex := 0 to lSuite.TestCount - 1 do
      begin
        lResult := lSuite.Tests[lTestIndex].Execute(lSuite.Name);
        try
          Inc(lCount);
          WriteLn(lResult.StatusText, ' ', lResult.TestId);
          if lResult.Status <> tsPassed then
          begin
            Inc(lFailures);
            WriteLn(lResult.Message, ' ', lResult.ErrorClass, ': ', lResult.ErrorMessage);
            WriteLn('Expected: ', lResult.Expected, '; actual: ', lResult.Actual);
          end;
        finally
          lResult.Free;
        end;
      end;
    end;
  finally
    lRegistry.Free;
  end;
  WriteLn(lCount, ' tests; ', lFailures, ' failures.');
  ExitCode := Ord(lFailures <> 0);
end.

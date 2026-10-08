(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

program NexusScriptEditorTests;

{$mode objfpc}{$H+}

uses fpg_main, obNXTestRegistry, obNXTestResult, tsNXScriptEditorTests,
  tsNXPopupTests, tsNXDirectoryDialogTests;

var
  lRegistry: TNXTestRegistry;
  lResult: TNXTestResult;
  lSuite, lTest, lFailures, lCount: Integer;

begin
  fpgApplication.Initialize;
  lRegistry := TNXTestRegistry.Create;
  lFailures := 0;
  lCount := 0;
  try
    RegisterNXScriptEditorTests(lRegistry);
    RegisterNXPopupTests(lRegistry);
    RegisterNXDirectoryDialogTests(lRegistry);
    for lSuite := 0 to lRegistry.SuiteCount - 1 do
      for lTest := 0 to lRegistry.Suites[lSuite].TestCount - 1 do
      begin
        lResult := lRegistry.Suites[lSuite].Tests[lTest].Execute(lRegistry.Suites[lSuite].Name);
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
  finally
    lRegistry.Free;
  end;
  WriteLn(lCount, ' tests; ', lFailures, ' failures.');
  ExitCode := Ord(lFailures <> 0);
end.

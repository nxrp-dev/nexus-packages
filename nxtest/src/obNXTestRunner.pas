(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTestRunner;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  obNXTestRegistry,
  obNXTestSuite,
  obNXTestCase,
  obNXTestResult,
  obNXTestRPCValues;

type
  TNXTestRunner = class
  private
    FRegistry: TNXTestRegistry;
  public
    constructor Create(ARegistry: TNXTestRegistry);

    function RunAll: TNXTestResultArray;
    function RunSuite(const ASuiteName: string): TNXTestResultArray;
    function RunTest(const ATestId: string): TNXTestResultValue;

    property Registry: TNXTestRegistry read FRegistry;
  end;

implementation

constructor TNXTestRunner.Create(ARegistry: TNXTestRegistry);
begin
  inherited Create;
  FRegistry := ARegistry;
end;

function TNXTestRunner.RunAll: TNXTestResultArray;
var
  lSuiteIndex: Integer;
  lTestIndex: Integer;
  lSuite: TNXTestSuite;
  lResult: TNXTestResult;
begin
  Result := TNXTestResultArray.Create;

  for lSuiteIndex := 0 to FRegistry.SuiteCount - 1 do
  begin
    lSuite := FRegistry.Suites[lSuiteIndex];
    for lTestIndex := 0 to lSuite.TestCount - 1 do
    begin
      lResult := lSuite.Tests[lTestIndex].Execute(lSuite.Name);
      try
        Result.AddResult(lResult);
      finally
        lResult.Free;
      end;
    end;
  end;
end;

function TNXTestRunner.RunSuite(const ASuiteName: string): TNXTestResultArray;
var
  lTestIndex: Integer;
  lSuite: TNXTestSuite;
  lResult: TNXTestResult;
begin
  Result := TNXTestResultArray.Create;

  lSuite := FRegistry.FindSuite(ASuiteName);
  if not Assigned(lSuite) then
    Exit;

  for lTestIndex := 0 to lSuite.TestCount - 1 do
  begin
    lResult := lSuite.Tests[lTestIndex].Execute(lSuite.Name);
    try
      Result.AddResult(lResult);
    finally
      lResult.Free;
    end;
  end;
end;

function TNXTestRunner.RunTest(const ATestId: string): TNXTestResultValue;
var
  lSuite: TNXTestSuite;
  lTest: TNXTestCase;
  lResult: TNXTestResult;
begin
  Result := nil;

  lTest := FRegistry.FindTest(ATestId, lSuite);
  if not Assigned(lTest) then
    Exit;

  lResult := lTest.Execute(lSuite.Name);
  try
    Result := NXTestResultValue(lResult);
  finally
    lResult.Free;
  end;
end;

end.

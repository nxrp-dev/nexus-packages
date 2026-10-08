(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTestCase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, obNXTestContext, obNXTestResult;

type
  TNXTestProcedure = procedure(AContext: TNXTestContext);

  TNXTestCase = class
  private
    FCategory: string;
    FName: string;
    FTestId: string;
    FTestProcedure: TNXTestProcedure;
  public
    constructor Create(const AName, ATestId: string;
      ATestProcedure: TNXTestProcedure; const ACategory: string = '');
    function Execute(const ASuiteName: string): TNXTestResult;

    property Category: string read FCategory;
    property Name: string read FName;
    property TestId: string read FTestId;
  end;

implementation

constructor TNXTestCase.Create(const AName, ATestId: string;
  ATestProcedure: TNXTestProcedure; const ACategory: string);
begin
  inherited Create;
  FCategory := ACategory;
  FName := AName;
  FTestId := ATestId;
  FTestProcedure := ATestProcedure;
end;

function TNXTestCase.Execute(const ASuiteName: string): TNXTestResult;
var
  lContext: TNXTestContext;
  lStart: QWord;
begin
  Result := TNXTestResult.Create;
  Result.SuiteName := ASuiteName;
  Result.TestName := FName;
  Result.TestId := FTestId;

  lContext := TNXTestContext.Create(Result);
  try
    lStart := GetTickCount64;
    try
      if not Assigned(FTestProcedure) then
        raise Exception.Create('Test procedure is not assigned.');

      FTestProcedure(lContext);
      Result.Status := tsPassed;
    except
      on E: ENXTestSkip do
        Result.Status := tsSkipped;
      on E: ENXTestFailure do
        Result.Status := tsFailed;
      on E: Exception do
      begin
        Result.Status := tsError;
        Result.ErrorClass := E.ClassName;
        Result.ErrorMessage := E.Message;
      end;
    end;
    Result.DurationMs := GetTickCount64 - lStart;
  finally
    lContext.Free;
  end;
end;

end.

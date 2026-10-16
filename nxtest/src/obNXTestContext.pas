(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTestContext;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, obNXTestResult, tpNXTest;

type
  ENXTestFailure = class(Exception);
  ENXTestSkip = class(Exception);

  TNXTestContext = class
  private
    FResult: TNXTestResult;
  public
    constructor Create(AResult: TNXTestResult);

    procedure Fail(const AMessage: string);
    procedure Skip(const AMessage: string);
    procedure AssertTrue(AValue: Boolean; const AMessage: string = '');
    procedure AssertFalse(AValue: Boolean; const AMessage: string = '');
    procedure AssertEquals(const AExpected, AActual: string; const AMessage: string = ''); overload;
    procedure AssertEquals(AExpected, AActual: Integer; const AMessage: string = ''); overload;
    procedure AssertRaises(AExceptionClass: ExceptClass; AAction: TNXTestAction;
      const AMessage: string = ''); overload;
    procedure AssertRaises(AExceptionClass: ExceptClass; AAction: TNXTestRoutine;
      const AMessage: string = ''); overload;

    property Result: TNXTestResult read FResult;
  end;

implementation

constructor TNXTestContext.Create(AResult: TNXTestResult);
begin
  inherited Create;
  FResult := AResult;
end;

procedure TNXTestContext.Fail(const AMessage: string);
begin
  FResult.Message := AMessage;
  raise ENXTestFailure.Create(AMessage);
end;

procedure TNXTestContext.Skip(const AMessage: string);
begin
  FResult.Message := AMessage;
  raise ENXTestSkip.Create(AMessage);
end;

procedure TNXTestContext.AssertTrue(AValue: Boolean; const AMessage: string);
begin
  if not AValue then
  begin
    if AMessage <> '' then
      Fail(AMessage)
    else
      Fail('Expected true.');
  end;
end;

procedure TNXTestContext.AssertFalse(AValue: Boolean; const AMessage: string);
begin
  if AValue then
  begin
    if AMessage <> '' then
      Fail(AMessage)
    else
      Fail('Expected false.');
  end;
end;

procedure TNXTestContext.AssertEquals(const AExpected, AActual: string; const AMessage: string); overload;
begin
  if AExpected <> AActual then
  begin
    FResult.Expected := AExpected;
    FResult.Actual := AActual;

    if AMessage <> '' then
      Fail(AMessage)
    else
      Fail('Values are not equal.');
  end;
end;

procedure TNXTestContext.AssertEquals(AExpected, AActual: Integer; const AMessage: string); overload;
begin
  AssertEquals(IntToStr(AExpected), IntToStr(AActual), AMessage);
end;

procedure TNXTestContext.AssertRaises(AExceptionClass: ExceptClass;
  AAction: TNXTestAction; const AMessage: string);
var
  lMessage, lExpected, lActual: string;
begin
  lMessage := FResult.Message;
  lExpected := FResult.Expected;
  lActual := FResult.Actual;
  try
    AAction;
  except
    on lError: Exception do
    begin
      if lError is AExceptionClass then
      begin
        FResult.Message := lMessage;
        FResult.Expected := lExpected;
        FResult.Actual := lActual;
        Exit;
      end;
      Fail(AMessage + ' Expected ' + AExceptionClass.ClassName +
        ', received ' + lError.ClassName + ': ' + lError.Message);
    end;
  end;
  Fail(AMessage + ' Expected ' + AExceptionClass.ClassName + '.');
end;

procedure TNXTestContext.AssertRaises(AExceptionClass: ExceptClass;
  AAction: TNXTestRoutine; const AMessage: string);
var
  lMessage, lExpected, lActual: string;
begin
  lMessage := FResult.Message;
  lExpected := FResult.Expected;
  lActual := FResult.Actual;
  try
    AAction;
  except
    on lError: Exception do
    begin
      if lError is AExceptionClass then
      begin
        FResult.Message := lMessage;
        FResult.Expected := lExpected;
        FResult.Actual := lActual;
        Exit;
      end;
      Fail(AMessage + ' Expected ' + AExceptionClass.ClassName +
        ', received ' + lError.ClassName + ': ' + lError.Message);
    end;
  end;
  Fail(AMessage + ' Expected ' + AExceptionClass.ClassName + '.');
end;

end.

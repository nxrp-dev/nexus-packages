(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTestResult;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, tpNXTest;

type
  TNXTestStatus = (tsNotRun, tsPassed, tsFailed, tsError, tsSkipped);

  TNXTestResult = class
  private
    FSuiteName: string;
    FTestName: string;
    FTestId: string;
    FStatus: TNXTestStatus;
    FMessage: string;
    FExpected: string;
    FActual: string;
    FErrorClass: string;
    FErrorMessage: string;
    FDurationMs: Int64;
  public
    constructor Create;
    function StatusText: string;

    property SuiteName: string read FSuiteName write FSuiteName;
    property TestName: string read FTestName write FTestName;
    property TestId: string read FTestId write FTestId;
    property Status: TNXTestStatus read FStatus write FStatus;
    property Message: string read FMessage write FMessage;
    property Expected: string read FExpected write FExpected;
    property Actual: string read FActual write FActual;
    property ErrorClass: string read FErrorClass write FErrorClass;
    property ErrorMessage: string read FErrorMessage write FErrorMessage;
    property DurationMs: Int64 read FDurationMs write FDurationMs;
  end;

implementation

constructor TNXTestResult.Create;
begin
  inherited Create;
  FStatus := tsNotRun;
end;

function TNXTestResult.StatusText: string;
begin
  case FStatus of
    tsPassed: Result := cNXTestStatusPassed;
    tsFailed: Result := cNXTestStatusFailed;
    tsError: Result := cNXTestStatusError;
    tsSkipped: Result := cNXTestStatusSkipped;
  else
    Result := cNXTestStatusNotRun;
  end;
end;

end.

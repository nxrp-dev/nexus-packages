(*
  Copyright (c) 2026 Kevin Collins.
  
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  
  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.
  
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTestRPCValues;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  obNXJSONRPCMessages,
  obNXJSONValues,
  obNXJSONRPCObjects,
  obNXTestCase,
  obNXTestRegistry,
  obNXTestResult,
  obNXTestSuite;

type
  ENXTestRPC = class(ENXJSONRPC)
  private
    FNXTestCode: Integer;
  public
    constructor CreateCode(const ACode: Integer; const ANXTestCode: Integer; const AMessage: string);
    property NXTestCode: Integer read FNXTestCode;
  end;

  TNXTestErrorData = class(TNXJSONObject)
  private
    FnxtestCode: TNXJSONInteger;
  published
    property nxtestCode: TNXJSONInteger read FnxtestCode write FnxtestCode;
  end;

  TNXTestRunSuiteParams = class(TNXJSONRPCObjectParams)
  private
    Fsuite: TNXJSONString;
  published
    property suite: TNXJSONString read Fsuite write Fsuite;
  end;

  TNXTestRunTestParams = class(TNXJSONRPCObjectParams)
  private
    Ftest: TNXJSONString;
  published
    property test: TNXJSONString read Ftest write Ftest;
  end;

  TNXTestMethodArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXTestCapabilitiesValue = class(TNXJSONObject)
  private
    FapiVersion: TNXJSONString;
    Fprotocol: TNXJSONString;
    Fmethods: TNXTestMethodArray;
  published
    property apiVersion: TNXJSONString read FapiVersion write FapiVersion;
    property protocol: TNXJSONString read Fprotocol write Fprotocol;
    property methods: TNXTestMethodArray read Fmethods write Fmethods;
  end;

  TNXTestCaseInfoValue = class(TNXJSONObject)
  private
    Fcategory: TNXJSONString;
    Fname: TNXJSONString;
    Fid: TNXJSONString;
  published
    property category: TNXJSONString read Fcategory write Fcategory;
    property name: TNXJSONString read Fname write Fname;
    property id: TNXJSONString read Fid write Fid;
  end;

  TNXTestCaseInfoArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
    function AddCase(ATest: TNXTestCase): TNXTestCaseInfoValue;
  end;

  TNXTestSuiteInfoValue = class(TNXJSONObject)
  private
    Fname: TNXJSONString;
    Ftests: TNXTestCaseInfoArray;
  published
    property name: TNXJSONString read Fname write Fname;
    property tests: TNXTestCaseInfoArray read Ftests write Ftests;
  end;

  TNXTestSuiteInfoArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
    function AddSuite(ASuite: TNXTestSuite): TNXTestSuiteInfoValue;
  end;

  TNXTestRegistryValue = class(TNXJSONObject)
  private
    Fsuites: TNXTestSuiteInfoArray;
  published
    property suites: TNXTestSuiteInfoArray read Fsuites write Fsuites;
  end;

  TNXTestResultValue = class(TNXJSONObject)
  private
    Fsuite: TNXJSONString;
    Ftest: TNXJSONString;
    Fid: TNXJSONString;
    Fstatus: TNXJSONString;
    FdurationMs: TNXJSONInteger;
    Fmessage: TNXJSONString;
    Fexpected: TNXJSONString;
    Factual: TNXJSONString;
    FerrorClass: TNXJSONString;
    FerrorMessage: TNXJSONString;
  published
    property suite: TNXJSONString read Fsuite write Fsuite;
    property test: TNXJSONString read Ftest write Ftest;
    property id: TNXJSONString read Fid write Fid;
    property status: TNXJSONString read Fstatus write Fstatus;
    property durationMs: TNXJSONInteger read FdurationMs write FdurationMs;
    property message: TNXJSONString read Fmessage write Fmessage;
    property expected: TNXJSONString read Fexpected write Fexpected;
    property actual: TNXJSONString read Factual write Factual;
    property errorClass: TNXJSONString read FerrorClass write FerrorClass;
    property errorMessage: TNXJSONString read FerrorMessage write FerrorMessage;
  end;

  TNXTestResultArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
    function AddResult(AResult: TNXTestResult): TNXTestResultValue;
  end;

  TNXTestRunAllResultValue = class(TNXJSONObject)
  private
    Fresults: TNXTestResultArray;
  published
    property results: TNXTestResultArray read Fresults write Fresults;
  end;

  TNXTestRunSuiteResultValue = class(TNXJSONObject)
  private
    Fsuite: TNXJSONString;
    Fresults: TNXTestResultArray;
  published
    property suite: TNXJSONString read Fsuite write Fsuite;
    property results: TNXTestResultArray read Fresults write Fresults;
  end;

function NXTestErrorData(const ANXTestCode: Integer): TNXTestErrorData;
function NXTestCapabilitiesValue: TNXTestCapabilitiesValue;
function NXTestRegistryValue(ARegistry: TNXTestRegistry): TNXTestRegistryValue;
function NXTestResultValue(AResult: TNXTestResult): TNXTestResultValue;
function NXTestRunAllResultValue(AResults: TNXTestResultArray): TNXTestRunAllResultValue;
function NXTestRunSuiteResultValue(const ASuiteName: string; AResults: TNXTestResultArray): TNXTestRunSuiteResultValue;

implementation

uses
  tpNXTest;

constructor ENXTestRPC.CreateCode(const ACode: Integer; const ANXTestCode: Integer; const AMessage: string);
begin
  inherited CreateCode(ACode, AMessage);
  FNXTestCode := ANXTestCode;
end;

class function TNXTestMethodArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXJSONString;
end;

class function TNXTestCaseInfoArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXTestCaseInfoValue;
end;

function TNXTestCaseInfoArray.AddCase(ATest: TNXTestCase): TNXTestCaseInfoValue;
begin
  Result := TNXTestCaseInfoValue(Add(TNXTestCaseInfoValue.Create));
  Result.category.Value := ATest.Category;
  Result.name.Value := ATest.Name;
  Result.id.Value := ATest.TestId;
end;

class function TNXTestSuiteInfoArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXTestSuiteInfoValue;
end;

function TNXTestSuiteInfoArray.AddSuite(ASuite: TNXTestSuite): TNXTestSuiteInfoValue;
var
  lIndex: Integer;
begin
  Result := TNXTestSuiteInfoValue(Add(TNXTestSuiteInfoValue.Create));
  Result.name.Value := ASuite.Name;
  Result.tests.Assigned := True;

  for lIndex := 0 to ASuite.TestCount - 1 do
    Result.tests.AddCase(ASuite.Tests[lIndex]);
end;

class function TNXTestResultArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXTestResultValue;
end;

function TNXTestResultArray.AddResult(AResult: TNXTestResult): TNXTestResultValue;
begin
  Result := TNXTestResultValue(Add(NXTestResultValue(AResult)));
end;

function NXTestErrorData(const ANXTestCode: Integer): TNXTestErrorData;
begin
  Result := TNXTestErrorData.Create;
  Result.nxtestCode.Value := ANXTestCode;
end;

function NXTestCapabilitiesValue: TNXTestCapabilitiesValue;
begin
  Result := TNXTestCapabilitiesValue.Create;
  try
    Result.apiVersion.Value := cNXTestApiVersion;
    Result.protocol.Value := 'json-rpc-2.0';
    Result.methods.Assigned := True;
    Result.methods.AddString(cNXTestMethodGetCapabilities);
    Result.methods.AddString(cNXTestMethodListTests);
    Result.methods.AddString(cNXTestMethodRunTest);
    Result.methods.AddString(cNXTestMethodRunSuite);
    Result.methods.AddString(cNXTestMethodRunAll);
  except
    Result.Free;
    raise;
  end;
end;

function NXTestRegistryValue(ARegistry: TNXTestRegistry): TNXTestRegistryValue;
var
  lIndex: Integer;
begin
  Result := TNXTestRegistryValue.Create;
  try
    Result.suites.Assigned := True;

    if Assigned(ARegistry) then
      for lIndex := 0 to ARegistry.SuiteCount - 1 do
        Result.suites.AddSuite(ARegistry.Suites[lIndex]);
  except
    Result.Free;
    raise;
  end;
end;

function NXTestResultValue(AResult: TNXTestResult): TNXTestResultValue;
begin
  Result := TNXTestResultValue.Create;
  try
    if not Assigned(AResult) then
      Exit;

    Result.suite.Value := AResult.SuiteName;
    Result.test.Value := AResult.TestName;
    Result.id.Value := AResult.TestId;
    Result.status.Value := AResult.StatusText;
    Result.durationMs.Value := AResult.DurationMs;

    if AResult.Message <> '' then
      Result.message.Value := AResult.Message;
    if AResult.Expected <> '' then
      Result.expected.Value := AResult.Expected;
    if AResult.Actual <> '' then
      Result.actual.Value := AResult.Actual;
    if AResult.ErrorClass <> '' then
      Result.errorClass.Value := AResult.ErrorClass;
    if AResult.ErrorMessage <> '' then
      Result.errorMessage.Value := AResult.ErrorMessage;
  except
    Result.Free;
    raise;
  end;
end;

function NXTestRunAllResultValue(AResults: TNXTestResultArray): TNXTestRunAllResultValue;
begin
  Result := TNXTestRunAllResultValue.Create;
  try
    Result.results.Assigned := True;
    if Assigned(AResults) then
    begin
      try
        Result.results.Assign(AResults);
      finally
        AResults.Free;
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function NXTestRunSuiteResultValue(const ASuiteName: string; AResults: TNXTestResultArray): TNXTestRunSuiteResultValue;
begin
  Result := TNXTestRunSuiteResultValue.Create;
  try
    Result.suite.Value := ASuiteName;
    Result.results.Assigned := True;
    if Assigned(AResults) then
    begin
      try
        Result.results.Assign(AResults);
      finally
        AResults.Free;
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.

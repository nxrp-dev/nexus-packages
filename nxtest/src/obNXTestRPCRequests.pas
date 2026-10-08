(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTestRPCRequests;

{$mode objfpc}{$H+}

interface

uses
  obNXJSONRPCMessages,
  obNXJSONValues,
  obNXJSONRPCObjects,
  obNXTestRPCValues;

type
  TNXTestGetCapabilitiesRequest = class(TNXJSONRPCRequest)
  public
    class function GetFactoryName: string; override;
    function Execute: TNXJSONRPCValue; override;
  end;

  TNXTestListTestsRequest = class(TNXJSONRPCRequest)
  public
    class function GetFactoryName: string; override;
    function Execute: TNXJSONRPCValue; override;
  end;

  TNXTestRunAllRequest = class(TNXJSONRPCRequest)
  public
    class function GetFactoryName: string; override;
    function Execute: TNXJSONRPCValue; override;
  end;

  TNXTestRunSuiteRequest = class(TNXJSONRPCRequest)
    private
    function GetParams: TNXTestRunSuiteParams;
    procedure SetParams(AValue: TNXTestRunSuiteParams);
public
    class function GetFactoryName: string; override;
function Execute: TNXJSONRPCValue; override;
  published
    property params: TNXTestRunSuiteParams read GetParams write SetParams;
  end;

  TNXTestRunTestRequest = class(TNXJSONRPCRequest)
    private
    function GetParams: TNXTestRunTestParams;
    procedure SetParams(AValue: TNXTestRunTestParams);
public
    class function GetFactoryName: string; override;
function Execute: TNXJSONRPCValue; override;
  published
    property params: TNXTestRunTestParams read GetParams write SetParams;
  end;

implementation

uses
  obNXClassFactory,
  obNXTestModule,
  tpNXTest;

function CurrentModule: TNXTestModule;
begin
  Result := TNXTestModule.Current;
end;

class function TNXTestGetCapabilitiesRequest.GetFactoryName: string;
begin
  Result := cNXTestMethodGetCapabilities;
end;

function TNXTestGetCapabilitiesRequest.Execute: TNXJSONRPCValue;
begin
  Result := NXTestCapabilitiesValue;
end;

class function TNXTestListTestsRequest.GetFactoryName: string;
begin
  Result := cNXTestMethodListTests;
end;

function TNXTestListTestsRequest.Execute: TNXJSONRPCValue;
begin
  Result := NXTestRegistryValue(CurrentModule.Registry);
end;

class function TNXTestRunAllRequest.GetFactoryName: string;
begin
  Result := cNXTestMethodRunAll;
end;

function TNXTestRunAllRequest.Execute: TNXJSONRPCValue;
begin
  Result := NXTestRunAllResultValue(CurrentModule.Runner.RunAll);
end;

class function TNXTestRunSuiteRequest.GetFactoryName: string;
begin
  Result := cNXTestMethodRunSuite;
end;

function TNXTestRunSuiteRequest.Execute: TNXJSONRPCValue;
var
  lParams: TNXTestRunSuiteParams;
  lSuiteName: string;
begin
  if not (params is TNXTestRunSuiteParams) then
    raise ENXTestRPC.CreateCode(TNXJSONRPC.InvalidParams, cNXTestErrorInvalidRequest, 'Missing suite parameter.');

  lParams := TNXTestRunSuiteParams(params);
  lSuiteName := lParams.suite.Value;
  if lSuiteName = '' then
    raise ENXTestRPC.CreateCode(TNXJSONRPC.InvalidParams, cNXTestErrorInvalidRequest, 'Missing suite parameter.');

  if CurrentModule.Registry.FindSuite(lSuiteName) = nil then
    raise ENXTestRPC.CreateCode(TNXJSONRPC.InvalidParams, cNXTestErrorUnknownTest, 'Unknown suite.');

  Result := NXTestRunSuiteResultValue(lSuiteName, CurrentModule.Runner.RunSuite(lSuiteName));
end;

class function TNXTestRunTestRequest.GetFactoryName: string;
begin
  Result := cNXTestMethodRunTest;
end;

function TNXTestRunTestRequest.Execute: TNXJSONRPCValue;
var
  lParams: TNXTestRunTestParams;
  lTestId: string;
begin
  if not (params is TNXTestRunTestParams) then
    raise ENXTestRPC.CreateCode(TNXJSONRPC.InvalidParams, cNXTestErrorInvalidRequest, 'Missing test parameter.');

  lParams := TNXTestRunTestParams(params);
  lTestId := lParams.test.Value;
  if lTestId = '' then
    raise ENXTestRPC.CreateCode(TNXJSONRPC.InvalidParams, cNXTestErrorInvalidRequest, 'Missing test parameter.');

  Result := CurrentModule.Runner.RunTest(lTestId);
  if Result = nil then
    raise ENXTestRPC.CreateCode(TNXJSONRPC.InvalidParams, cNXTestErrorUnknownTest, 'Unknown test.');
end;

function TNXTestRunTestRequest.GetParams: TNXTestRunTestParams;
begin
  Result := TNXTestRunTestParams(inherited params);
end;

procedure TNXTestRunTestRequest.SetParams(AValue: TNXTestRunTestParams);
begin
  inherited params := AValue;
end;

function TNXTestRunSuiteRequest.GetParams: TNXTestRunSuiteParams;
begin
  Result := TNXTestRunSuiteParams(inherited params);
end;

procedure TNXTestRunSuiteRequest.SetParams(AValue: TNXTestRunSuiteParams);
begin
  inherited params := AValue;
end;

initialization
  TNXClassFactory.RegisterClass(TNXTestGetCapabilitiesRequest);
  TNXClassFactory.RegisterClass(TNXTestListTestsRequest);
  TNXClassFactory.RegisterClass(TNXTestRunAllRequest);
  TNXClassFactory.RegisterClass(TNXTestRunSuiteRequest);
  TNXClassFactory.RegisterClass(TNXTestRunTestRequest);

end.

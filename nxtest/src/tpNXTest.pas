(*
  Copyright (c) 2026 Kevin Collins.
  
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  
  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.
  
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tpNXTest;

{$mode objfpc}{$H+}

interface

const
  cNXTestSuccess = 0;
  cNXTestErrorNotInitialized = -1;
  cNXTestErrorInvalidRequest = -2;
  cNXTestErrorUnknownCommand = -3;
  cNXTestErrorUnknownTest = -4;
  cNXTestErrorBufferTooSmall = -5;
  cNXTestErrorInternal = -6;
  cNXTestErrorUnknownResult = -7;
  cNXTestErrorInvalidArgument = -8;

  cJsonRpcParseError = -32700;
  cJsonRpcInvalidRequest = -32600;
  cJsonRpcMethodNotFound = -32601;
  cJsonRpcInvalidParams = -32602;
  cJsonRpcInternalError = -32603;

  cNXTestStatusNotRun = 'notRun';
  cNXTestStatusPassed = 'passed';
  cNXTestStatusFailed = 'failed';
  cNXTestStatusError = 'error';
  cNXTestStatusSkipped = 'skipped';
  cNXTestStatusRunning = 'running';
  cNXTestStatusMixed = 'mixed';

  cNXTestMethodGetCapabilities = 'nxtest/getCapabilities';
  cNXTestMethodListTests = 'nxtest/listTests';
  cNXTestMethodRunTest = 'nxtest/runTest';
  cNXTestMethodRunSuite = 'nxtest/runSuite';
  cNXTestMethodRunAll = 'nxtest/runAll';

  cNXTestApiVersion = '1';

implementation

end.

// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit tsFCLRegistryRegressions;
{$mode objfpc}{$H+}
interface
uses obNXTestRegistry;
procedure RegisterFCLRegistryRegressions(ARegistry: TNXTestRegistry);
implementation
uses Classes, SysUtils, Process, obNXTestContext, obNXTestSuite;
procedure RunCase(AContext: TNXTestContext; const ACase: string);
var
  lProcess: TProcess;
  lStart: QWord;
  lOutput, lDirectory: string;
begin
  lProcess := TProcess.Create(nil);
  try
    lDirectory := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'cases/' + ACase;
    ForceDirectories(lDirectory);
    lProcess.Executable := ExtractFilePath(ParamStr(0)) + 'FCLRegistryFixture';
    lProcess.CurrentDirectory := lDirectory;
    lProcess.Parameters.Add(ACase);
    lProcess.Options := [poUsePipes, poStderrToOutPut];
    lProcess.Execute;
    lStart := GetTickCount64;
    while lProcess.Running and (GetTickCount64 - lStart < 4000) do Sleep(5);
    if lProcess.Running then
    begin
      lProcess.Terminate(124);
      lProcess.WaitOnExit;
      AContext.Fail(ACase + ' exceeded its four-second limit');
    end;
    SetLength(lOutput, lProcess.Output.NumBytesAvailable);
    if Length(lOutput) > 0 then lProcess.Output.ReadBuffer(lOutput[1], Length(lOutput));
    AContext.AssertEquals(0, lProcess.ExitStatus, Trim(lOutput));
  finally lProcess.Free; end;
end;

procedure TestKeyProbe(AContext: TNXTestContext);
begin
  RunCase(AContext, 'key-probe');
end;

procedure TestKeyCreate(AContext: TNXTestContext);
begin
  RunCase(AContext, 'key-create');
end;

procedure TestKeyFailedOpen(AContext: TNXTestContext);
begin
  RunCase(AContext, 'key-failed-open');
end;

procedure TestDeleteSelectedControl(AContext: TNXTestContext);
begin
  RunCase(AContext, 'delete-selected-control');
end;

procedure TestSizeBinary(AContext: TNXTestContext);
begin
  RunCase(AContext, 'size-binary');
end;

procedure TestSizeMulti(AContext: TNXTestContext);
begin
  RunCase(AContext, 'size-multi');
end;

procedure TestSizeQword(AContext: TNXTestContext);
begin
  RunCase(AContext, 'size-qword');
end;

procedure TestSizeMaximum(AContext: TNXTestContext);
begin
  RunCase(AContext, 'size-maximum');
end;

procedure TestKeyTimestamp(AContext: TNXTestContext);
begin
  RunCase(AContext, 'key-timestamp');
end;

procedure TestBoundedAnsi(AContext: TNXTestContext);
begin
  RunCase(AContext, 'bounded-ansi');
end;

procedure TestBoundedUnicode(AContext: TNXTestContext);
begin
  RunCase(AContext, 'bounded-unicode');
end;

procedure TestInvalidHex(AContext: TNXTestContext);
begin
  RunCase(AContext, 'invalid-hex');
end;

procedure TestOddHex(AContext: TNXTestContext);
begin
  RunCase(AContext, 'odd-hex');
end;

procedure TestNegativeType(AContext: TNXTestContext);
begin
  RunCase(AContext, 'negative-type');
end;

procedure TestLargeType(AContext: TNXTestContext);
begin
  RunCase(AContext, 'large-type');
end;

procedure TestNonnumericType(AContext: TNXTestContext);
begin
  RunCase(AContext, 'nonnumeric-type');
end;

procedure TestIniDate(AContext: TNXTestContext);
begin
  RunCase(AContext, 'ini-date');
end;

procedure TestIniDatetime(AContext: TNXTestContext);
begin
  RunCase(AContext, 'ini-datetime');
end;

procedure TestIniTime(AContext: TNXTestContext);
begin
  RunCase(AContext, 'ini-time');
end;

procedure TestIniFloat(AContext: TNXTestContext);
begin
  RunCase(AContext, 'ini-float');
end;

procedure TestEmptyMulti(AContext: TNXTestContext);
begin
  RunCase(AContext, 'empty-multi');
end;

procedure TestUnsupportedRemote(AContext: TNXTestContext);
begin
  RunCase(AContext, 'unsupported-remote');
end;

procedure TestMalformedLoad(AContext: TNXTestContext);
begin
  RunCase(AContext, 'malformed-load');
end;

procedure TestFailedReload(AContext: TNXTestContext);
begin
  RunCase(AContext, 'failed-reload');
end;

procedure RegisterFCLRegistryRegressions(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCLRegistryRegressions');
  lSuite.AddTest('key-probe', @TestKeyProbe);
  lSuite.AddTest('key-create', @TestKeyCreate);
  lSuite.AddTest('key-failed-open', @TestKeyFailedOpen);
  lSuite.AddTest('delete-selected-control', @TestDeleteSelectedControl);
  lSuite.AddTest('size-binary', @TestSizeBinary);
  lSuite.AddTest('size-multi', @TestSizeMulti);
  lSuite.AddTest('size-qword', @TestSizeQword);
  lSuite.AddTest('size-maximum', @TestSizeMaximum);
  lSuite.AddTest('key-timestamp', @TestKeyTimestamp);
  lSuite.AddTest('bounded-ansi', @TestBoundedAnsi);
  lSuite.AddTest('bounded-unicode', @TestBoundedUnicode);
  lSuite.AddTest('invalid-hex', @TestInvalidHex);
  lSuite.AddTest('odd-hex', @TestOddHex);
  lSuite.AddTest('negative-type', @TestNegativeType);
  lSuite.AddTest('large-type', @TestLargeType);
  lSuite.AddTest('nonnumeric-type', @TestNonnumericType);
  lSuite.AddTest('ini-date', @TestIniDate);
  lSuite.AddTest('ini-datetime', @TestIniDatetime);
  lSuite.AddTest('ini-time', @TestIniTime);
  lSuite.AddTest('ini-float', @TestIniFloat);
  lSuite.AddTest('empty-multi', @TestEmptyMulti);
  lSuite.AddTest('unsupported-remote', @TestUnsupportedRemote);
  lSuite.AddTest('malformed-load', @TestMalformedLoad);
  lSuite.AddTest('failed-reload', @TestFailedReload);
end;
end.

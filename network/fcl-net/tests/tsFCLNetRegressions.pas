// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit tsFCLNetRegressions;
{$mode objfpc}{$H+}
interface
uses obNXTestRegistry;
procedure RegisterFCLNetRegressions(ARegistry: TNXTestRegistry);
implementation
uses Classes, SysUtils, Process, obNXTestContext, obNXTestSuite;

procedure RunCase(AContext: TNXTestContext; const ACase: string);
var
  lProcess: TProcess;
  lStart: QWord;
  lOutput: string;
begin
  lProcess := TProcess.Create(nil);
  try
    lProcess.Executable := ExtractFilePath(ParamStr(0)) + 'FCLNetFixture';
    lProcess.Parameters.Add(ACase);
    lProcess.Options := [poUsePipes, poStderrToOutPut];
    lProcess.Execute;
    lStart := GetTickCount64;
    while lProcess.Running and (GetTickCount64 - lStart < 3000) do Sleep(5);
    if lProcess.Running then
    begin
      lProcess.Terminate(124);
      lProcess.WaitOnExit;
      AContext.Fail(ACase + ' exceeded its three-second limit');
    end;
    SetLength(lOutput, lProcess.Output.NumBytesAvailable);
    if Length(lOutput) > 0 then lProcess.Output.ReadBuffer(lOutput[1], Length(lOutput));
    AContext.AssertEquals(0, lProcess.ExitStatus, Trim(lOutput));
  finally
    lProcess.Free;
  end;
end;

procedure TestResolverOwnership(AContext: TNXTestContext);
begin
  RunCase(AContext, 'resolver-ownership');
end;

procedure TestUnixAddressFamily(AContext: TNXTestContext);
begin
  RunCase(AContext, 'unix-address');
end;

procedure TestUnixEndpoint(AContext: TNXTestContext);
begin
  RunCase(AContext, 'unix-endpoint');
end;

procedure TestSelectWrite(AContext: TNXTestContext);
begin
  RunCase(AContext, 'select-write');
end;

procedure TestSelectInfiniteWait(AContext: TNXTestContext);
begin
  RunCase(AContext, 'select-infinite');
end;

procedure TestSelectDescriptorZero(AContext: TNXTestContext);
begin
  RunCase(AContext, 'select-zero');
end;

procedure TestCertificateDefaultVersion(AContext: TNXTestContext);
begin
  RunCase(AContext, 'certificate-version');
end;

procedure TestDNSTextEmptyUDP(AContext: TNXTestContext);
begin
  RunCase(AContext, 'txt-empty-udp');
end;

procedure TestDNSTextEmptyTCP(AContext: TNXTestContext);
begin
  RunCase(AContext, 'txt-empty-tcp');
end;

procedure TestDNSTextBoundaryUDP(AContext: TNXTestContext);
begin
  RunCase(AContext, 'txt-boundary-udp');
end;

procedure TestDNSTextBoundaryTCP(AContext: TNXTestContext);
begin
  RunCase(AContext, 'txt-boundary-tcp');
end;

procedure TestDNSTextSegmentsUDP(AContext: TNXTestContext);
begin
  RunCase(AContext, 'txt-segments-udp');
end;

procedure TestDNSTextSegmentsTCP(AContext: TNXTestContext);
begin
  RunCase(AContext, 'txt-segments-tcp');
end;

procedure TestUDPLoopback(AContext: TNXTestContext);
begin
  RunCase(AContext, 'udp-loopback');
end;

procedure TestTCPLoopback(AContext: TNXTestContext);
begin
  RunCase(AContext, 'tcp-loopback');
end;

procedure TestTCPNonBlockingAccept(AContext: TNXTestContext);
begin
  RunCase(AContext, 'tcp-nonblocking');
end;

procedure TestDualStackAddressSize(AContext: TNXTestContext);
begin
  RunCase(AContext, 'dual-stack-size');
end;

procedure RegisterFCLNetRegressions(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCLNetRegressions');
  lSuite.AddTest('resolver-ownership', @TestResolverOwnership);
  lSuite.AddTest('unix-address', @TestUnixAddressFamily);
  lSuite.AddTest('unix-endpoint', @TestUnixEndpoint);
  lSuite.AddTest('select-write', @TestSelectWrite);
  lSuite.AddTest('select-infinite', @TestSelectInfiniteWait);
  lSuite.AddTest('select-zero', @TestSelectDescriptorZero);
  lSuite.AddTest('certificate-version', @TestCertificateDefaultVersion);
  lSuite.AddTest('txt-empty-udp', @TestDNSTextEmptyUDP);
  lSuite.AddTest('txt-empty-tcp', @TestDNSTextEmptyTCP);
  lSuite.AddTest('txt-boundary-udp', @TestDNSTextBoundaryUDP);
  lSuite.AddTest('txt-boundary-tcp', @TestDNSTextBoundaryTCP);
  lSuite.AddTest('txt-segments-udp', @TestDNSTextSegmentsUDP);
  lSuite.AddTest('txt-segments-tcp', @TestDNSTextSegmentsTCP);
  lSuite.AddTest('udp-loopback', @TestUDPLoopback);
  lSuite.AddTest('tcp-loopback', @TestTCPLoopback);
  lSuite.AddTest('tcp-nonblocking', @TestTCPNonBlockingAccept);
  lSuite.AddTest('dual-stack-size', @TestDualStackAddressSize);
end;
end.

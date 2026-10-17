// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program FCLRegistryExampleTests;
{$mode objfpc}{$H+}
uses
  {$ifdef UNIX}cwstring,{$endif}
  Classes, SysUtils, Process, obNXTestRegistry, obNXTestSuite,
  obNXTestContext, utNXTestConsole;

procedure CheckExample(AContext: TNXTestContext; const AName: string);
var
  lProcess: TProcess;
  lDirectory, lOutput: string;
  lStart: QWord;
begin
  lDirectory := IncludeTrailingPathDelimiter(ExpandFileName(ParamStr(1)));
  lProcess := TProcess.Create(nil);
  try
    lProcess.Executable := lDirectory + AName;
    lProcess.CurrentDirectory := lDirectory + 'cases/' + AName;
    ForceDirectories(lProcess.CurrentDirectory);
    lProcess.Options := [poUsePipes, poStderrToOutPut];
    lProcess.Execute;
    lStart := GetTickCount64;
    while lProcess.Running and (GetTickCount64 - lStart < 4000) do Sleep(5);
    if lProcess.Running then
    begin
      lProcess.Terminate(124);
      lProcess.WaitOnExit;
      AContext.Fail(AName + ' exceeded its four-second limit');
    end;
    SetLength(lOutput, lProcess.Output.NumBytesAvailable);
    if Length(lOutput) > 0 then lProcess.Output.ReadBuffer(lOutput[1], Length(lOutput));
    AContext.AssertEquals(0, lProcess.ExitStatus, Trim(lOutput));
    lOutput := LowerCase(lOutput);
    AContext.AssertFalse((Pos('failed', lOutput) > 0) or (Pos('differs', lOutput) > 0) or
      (Pos('error:', lOutput) > 0), Trim(lOutput));
    if AName = 'txmlreg' then
      AContext.AssertTrue(FileExists(lProcess.CurrentDirectory + '/test.xml'), 'XML example did not flush its file');
  finally lProcess.Free; end;
end;

procedure CheckXML(AContext: TNXTestContext);
begin CheckExample(AContext, 'txmlreg'); end;
procedure CheckRegistry(AContext: TNXTestContext);
begin CheckExample(AContext, 'testreg'); end;
procedure CheckUTF8(AContext: TNXTestContext);
begin CheckExample(AContext, 'testunicode'); end;
procedure CheckUnicode(AContext: TNXTestContext);
begin CheckExample(AContext, 'testunicode2'); end;

var
  lRegistry: TNXTestRegistry;
  lSuite: TNXTestSuite;
begin
  if ParamCount <> 1 then
  begin
    WriteLn('Usage: FCLRegistryExampleTests <RegistryExamples output directory>');
    Halt(2);
  end;
  lRegistry := TNXTestRegistry.Create;
  try
    lSuite := lRegistry.AddSuite('FCLRegistryExamples');
    lSuite.AddTest('xml', @CheckXML);
    lSuite.AddTest('registry', @CheckRegistry);
    lSuite.AddTest('utf8', @CheckUTF8);
    lSuite.AddTest('unicode', @CheckUnicode);
    ExitCode := RunConsoleTests(lRegistry);
  finally lRegistry.Free; end;
end.

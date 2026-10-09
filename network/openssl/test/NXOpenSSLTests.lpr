program NXOpenSSLTests;
{$mode objfpc}{$H+}
uses SysUtils, obNXTestRegistry, obNXTestSuite, obNXTestResult, tsNXOpenSSLTests;
var
  lRegistry: TNXTestRegistry;
  lResult: TNXTestResult;
  lSuite, lTest, lPassed: Integer;
begin
  if ParamCount <> 2 then
  begin
    WriteLn('Usage: NXOpenSSLTests <fixture-directory> <OpenSSL-runtime-directory>');
    Halt(2);
  end;
  ConfigureOpenSSLTests(ParamStr(1), ParamStr(2));
  lRegistry := TNXTestRegistry.Create;
  lPassed := 0;
  try
    RegisterNXOpenSSLTests(lRegistry);
    for lSuite := 0 to lRegistry.SuiteCount - 1 do
      for lTest := 0 to lRegistry.Suites[lSuite].TestCount - 1 do
      begin
        lResult := lRegistry.Suites[lSuite].Tests[lTest].Execute(lRegistry.Suites[lSuite].Name);
        try
          WriteLn(lResult.StatusText, ' ', lResult.TestId, ' ', lResult.Message, ' ', lResult.ErrorMessage);
          if lResult.Status <> tsPassed then
          begin
            ExitCode := 1;
            Exit;
          end;
          Inc(lPassed);
        finally
          lResult.Free;
        end;
      end;
    WriteLn(lPassed, ' passed; 0 failed/errors/skipped');
  finally
    lRegistry.Free;
  end;
end.

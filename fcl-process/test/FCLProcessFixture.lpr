// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program FCLProcessFixture;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads, cwstring, BaseUnix,{$ENDIF}
  Classes, SysUtils, obNXTestContext, obNXTestResult, obFCLProcessProbe;

var
  lContext: TNXTestContext;
  lResult: TNXTestResult;
  lLines: TStringList;
begin
  if ParamStr(1) = '--child' then
  begin
    RunFCLProcessChild;
    Halt;
  end;
  {$IFDEF MSWINDOWS}
  if ParamStr(1) = '--service-fixture' then
  begin
    RunFCLProcessService;
    Halt;
  end;
  {$ENDIF}
  if (ParamStr(1) <> '--probe') or (ParamCount <> 4) then
    Halt(2);
  {$IFDEF UNIX}
  if fpSetSid < 0 then
    Halt(3);
  {$ENDIF}
  lResult := TNXTestResult.Create;
  lContext := TNXTestContext.Create(lResult);
  lLines := TStringList.Create;
  try
    try
      RunFCLProcessProbe(StrToInt(ParamStr(2)), ParamStr(4), lContext);
      lLines.Add('passed');
    except
      on E: ENXTestSkip do
      begin
        lLines.Add('skipped');
        lLines.Add(E.Message);
      end;
      on E: Exception do
      begin
        lLines.Add('failed');
        lLines.Add(E.ClassName + ': ' + E.Message);
        ExitCode := 1;
      end;
    end;
    lLines.SaveToFile(ParamStr(3));
  finally
    lLines.Free;
    lContext.Free;
    lResult.Free;
  end;
end.

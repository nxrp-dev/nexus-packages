// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program FCLImageFixture;

{$mode objfpc}{$H+}

uses
  HeapTrc, {$IFDEF UNIX}cthreads, cwstring, BaseUnix,{$ENDIF}
  Classes, SysUtils, obNXTestContext, obNXTestResult, obFCLImageProbe;

var
  lContext: TNXTestContext;
  lResult: TNXTestResult;
  lLines: TStringList;
begin
  if (ParamStr(1)<>'--probe') or (ParamCount<>4) then
    Halt(2);
  {$IFDEF UNIX}
  if fpSetSid<0 then
    Halt(3);
  {$ENDIF}
  HaltOnNotReleased:=True;
  GlobalSkipIfNoLeaks:=True;
  SetHeapTraceOutput(IncludeTrailingPathDelimiter(ParamStr(4))+'heap.txt');
  lResult:=TNXTestResult.Create;
  lContext:=TNXTestContext.Create(lResult);
  lLines:=TStringList.Create;
  try
    try
      RunFCLImageProbe(StrToInt(ParamStr(2)),ParamStr(4),lContext);
      CheckHeap;
      lLines.Add('passed');
    except
      on lError: ENXTestSkip do
      begin
        lLines.Add('skipped');
        lLines.Add(lError.Message);
      end;
      on lError: Exception do
      begin
        lLines.Add('failed');
        lLines.Add(lError.ClassName+': '+lError.Message);
        ExitCode:=1;
      end;
    end;
    if (lResult.Expected<>'') or (lResult.Actual<>'') then
      lLines.Add('expected: '+lResult.Expected+'; actual: '+lResult.Actual);
    lLines.SaveToFile(ParamStr(3));
  finally
    lLines.Free;
    lContext.Free;
    lResult.Free;
  end;
end.

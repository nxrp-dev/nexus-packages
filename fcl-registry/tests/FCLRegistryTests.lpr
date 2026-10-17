// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program FCLRegistryTests;
{$mode objfpc}{$H+}
uses
  {$IFDEF UNIX}cthreads, cwstring,{$ENDIF}
  SysUtils, obNXTestRegistry, utNXTestConsole, tsFCLRegistryRegressions,
  regtcxmlreg,
  RegTestBasics;
var
  lRegistry: TNXTestRegistry;
begin
  SetCurrentDir(ExtractFilePath(ParamStr(0)));
  lRegistry := TNXTestRegistry.Create;
  try
    RegisterregtcxmlregTests(lRegistry);
    RegisterRegTestBasicsTests(lRegistry);
    RegisterFCLRegistryRegressions(lRegistry);
    ExitCode := RunConsoleTests(lRegistry);
  finally
    lRegistry.Free;
  end;
end.

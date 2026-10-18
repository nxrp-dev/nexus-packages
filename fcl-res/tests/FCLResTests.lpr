// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program FCLResTests;
{$mode objfpc}{$H+}
uses
  {$ifdef unix}cwstring,{$endif}
  obNXTestRegistry, utNXTestConsole, tsFCLRes;
var
  lRegistry: TNXTestRegistry;
begin
  lRegistry := TNXTestRegistry.Create;
  try
    RegisterFCLResTests(lRegistry);
    ExitCode := RunConsoleTests(lRegistry);
  finally
    lRegistry.Free;
  end;
end.

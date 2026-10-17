// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program NXSynapseTests;
{$mode objfpc}{$H+}
uses
  {$ifdef UNIX}cthreads, cwstring,{$endif}
  obNXTestRegistry, utNXTestConsole, tsNXSynapseTests;
var lRegistry: TNXTestRegistry;
begin
  lRegistry := TNXTestRegistry.Create;
  try
    RegisterSynapseTests(lRegistry);
    ExitCode := RunConsoleTests(lRegistry);
  finally lRegistry.Free; end;
end.

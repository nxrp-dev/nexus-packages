// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program NXXMPPTransportTests;
{$mode objfpc}{$H+}
uses
  {$ifdef UNIX}cthreads, cwstring,{$endif}
  obNXTestRegistry, utNXTestConsole, tsNXXMPPTransportTests;
var
  lRegistry: TNXTestRegistry;
begin
  if ParamCount <> 1 then
  begin
    WriteLn('Usage: NXXMPPTransportTests <XMPP-fixture-directory>');
    Halt(2);
  end;
  lRegistry := TNXTestRegistry.Create;
  try
    RegisterXMPPTransportTests(lRegistry, ParamStr(1));
    ExitCode := RunConsoleTests(lRegistry);
  finally lRegistry.Free; end;
end.

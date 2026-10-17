program NXOpenSSLTests;
{$mode objfpc}{$H+}
uses
  {$ifdef UNIX}cthreads, cwstring,{$endif}
  SysUtils, obNXTestRegistry, utNXTestConsole, tsNXOpenSSLTests;
var
  lRegistry: TNXTestRegistry;
begin
  if ParamCount <> 2 then
  begin
    WriteLn('Usage: NXOpenSSLTests <fixture-directory> <OpenSSL-runtime-directory>');
    Halt(2);
  end;
  ConfigureOpenSSLTests(ParamStr(1), ParamStr(2));
  lRegistry := TNXTestRegistry.Create;
  try
    RegisterNXOpenSSLTests(lRegistry);
    ExitCode := RunConsoleTests(lRegistry);
  finally
    lRegistry.Free;
  end;
end.

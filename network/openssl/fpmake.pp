{$ifndef ALLPACKAGES}
{$mode objfpc}{$H+}
program fpmake;

uses {$ifdef unix}cthreads,{$endif} fpmkunit;

Var
  P : TPackage;
  T : TTarget;
begin
  With Installer do
    begin
{$endif ALLPACKAGES}

    P:=AddPackage('openssl');
    P.Dependencies.Add('rtl-extra');
    P.Dependencies.Add('rtl-objpas');
    P.ShortName:='ossl';
    P.Description := 'Interface units for OpenSSL libraries supporting SSL-encrypted network communication.';
{$ifdef ALLPACKAGES}
    P.Directory:=ADirectory;
{$endif ALLPACKAGES}
    P.Version:='3.3.1';
    P.SourcePath.Add('src');
    P.OSes := AllUnixOSes+AllWindowsOSes;
    if Defaults.CPU=jvm then
      P.OSes := P.OSes - [java,android];

    T:=P.Targets.AddUnit('tpNXOpenSSLTypes.pas');
    T:=P.Targets.AddUnit('obNXOpenSSLCertificates.pas');
    T:=P.Targets.AddUnit('openssl.pas');
    T:=P.Targets.AddUnit('obNXOpenSSLCrypto.pas');
      T.Dependencies.AddUnit('openssl');
      T.Dependencies.AddUnit('fpopenssl');
    T:=P.Targets.AddUnit('fpopenssl.pp');
      T.ResourceStrings:=true;
    P.ExamplePath.Add('../../../../../../nexus-lab/examples/network/tls');
    P.Targets.AddExampleProgram('test1.pas');


    P.NamespaceMap:='namespaces.lst';

{$ifndef ALLPACKAGES}
    Run;
    end;
end.
{$endif ALLPACKAGES}

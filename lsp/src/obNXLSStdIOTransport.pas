(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXLSStdIOTransport;

{$mode objfpc}{$H+}

interface

uses
  tpNXLS,
  obNXLSTransport;

type
  TNXLSStdIOTransport = class(TNXLSTransport)
  private
    FOpen: Boolean;
  protected
    function ReadLine(out ALine: string): Boolean; override;
    function ReadContent(const ALength: Integer; out AContent: string): Boolean; override;
    procedure WriteContent(const AContent: string); override;
  public
    class function GetFactoryName: string; override;
    procedure Open; override;
    procedure Close; override;
    function IsOpen: Boolean; override;
  end;

implementation

uses
  obNXClassFactory;

class function TNXLSStdIOTransport.GetFactoryName: string;
begin
  Result := 'stdio';
end;

procedure TNXLSStdIOTransport.Open;
begin
  FOpen := True;
end;

procedure TNXLSStdIOTransport.Close;
begin
  FOpen := False;
end;

function TNXLSStdIOTransport.IsOpen: Boolean;
begin
  Result := FOpen;
end;

function TNXLSStdIOTransport.ReadLine(out ALine: string): Boolean;
begin
  ALine := '';

  if EOF(Input) then
    Exit(False);

  ReadLn(Input, ALine);
  Result := True;
end;

function TNXLSStdIOTransport.ReadContent(const ALength: Integer; out AContent: string): Boolean;
var
  lIdx: Integer;
begin
  AContent := '';
  SetLength(AContent, ALength);

  for lIdx := 1 to ALength do
  begin
    if EOF(Input) then
      raise ENXLSException.Create('Unexpected end of stdio input while reading message content.');

    Read(Input, AContent[lIdx]);
  end;

  Result := True;
end;

procedure TNXLSStdIOTransport.WriteContent(const AContent: string);
begin
  Write(Output, AContent);
  Flush(Output);
end;

initialization
  TNXClassFactory.RegisterClass(TNXLSStdIOTransport);

end.

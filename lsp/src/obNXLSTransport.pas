(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXLSTransport;

{$mode objfpc}{$H+}

interface

uses
  tpNXLS,
  obNXClassFactory;

type
  TNXLSTransport = class(TNXFactoryObject)
  protected
    function ReadLine(out ALine: string): Boolean; virtual; abstract;
    function ReadContent(const ALength: Integer; out AContent: string): Boolean; virtual; abstract;
    procedure WriteContent(const AContent: string); virtual; abstract;
  public
    procedure Open; virtual; abstract;
    procedure Close; virtual; abstract;
    function IsOpen: Boolean; virtual; abstract;
    function ReadMessage(out AMessage: string): Boolean; virtual;
    procedure WriteMessage(const AMessage: string); virtual;
  end;

implementation

uses
  SysUtils;

const
  cContentLengthHeader = 'Content-Length';
  cContentTypeHeader = 'Content-Type';
  cContentType = 'application/vscode-jsonrpc; charset=utf-8';

function TNXLSTransport.ReadMessage(out AMessage: string): Boolean;
var
  lLine: string;
  lName: string;
  lValue: string;
  lPos: SizeInt;
  lContentLength: Integer;
  lSawHeader: Boolean;
  lHeaders: string;
begin
  AMessage := '';

  if not IsOpen then
    raise ENXLSException.Create('Cannot read from a closed ' + GetFactoryName + ' transport.');

  lContentLength := -1;
  lSawHeader := False;
  lHeaders := '';

  while True do
  begin
    if not ReadLine(lLine) then
    begin
      if not lSawHeader then
        Exit(False);

      raise ENXLSException.CreateFmt('Unexpected end of %s input while reading message headers.', [GetFactoryName]);
    end;

    if lLine = '' then
    begin
      if not lSawHeader then
        Exit(False);

      Break;
    end;

    lSawHeader := True;
    if lHeaders <> '' then
      lHeaders := lHeaders + ' | ';
    lHeaders := lHeaders + lLine;

    lPos := Pos(':', lLine);

    if lPos <= 0 then
      raise ENXLSException.CreateFmt('Invalid %s message header "%s".', [GetFactoryName, lLine]);

    lName := Trim(Copy(lLine, 1, lPos - 1));
    lValue := Trim(Copy(lLine, lPos + 1, Length(lLine) - lPos));

    if SameText(lName, cContentLengthHeader) then
      lContentLength := StrToIntDef(lValue, -1);
  end;

  if lContentLength < 0 then
    raise ENXLSException.Create(GetFactoryName + ' message is missing a valid Content-Length header. Headers read: ' + lHeaders);

  Result := ReadContent(lContentLength, AMessage);
end;

procedure TNXLSTransport.WriteMessage(const AMessage: string);
begin
  if not IsOpen then
    raise ENXLSException.Create('Cannot write to a closed ' + GetFactoryName + ' transport.');

  WriteContent(
    cContentTypeHeader + ': ' + cContentType + #13#10 +
    cContentLengthHeader + ': ' + IntToStr(Length(AMessage)) + #13#10 +
    #13#10 +
    AMessage
  );
end;

end.

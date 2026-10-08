(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNexusScriptSourceProvider;

{$mode delphi}{$H+}

interface

uses
  Classes;

type
  TNexusScriptSourceProvider = class
  public
    function CanonicalName(const ASourceName: string): string; virtual; abstract;
    function Exists(const ASourceName: string): Boolean; virtual; abstract;
    function FolderExists(const AFolderName: string): Boolean; virtual; abstract;
    function ReadSource(const ASourceName: string; out AText: string;
      out AVersion: Integer): Boolean; virtual; abstract;
    function SelectFiles(const AFolderName, AFileNamePattern: string;
      ARecursive: Boolean): TStringList; virtual; abstract;
    function SameIdentity(const ALeft, ARight: string): Boolean; virtual; abstract;
    function SupportsRelativePaths(const ASourceName: string): Boolean;
      virtual; abstract;
  end;

  TNexusScriptFileSourceProvider = class(TNexusScriptSourceProvider)
  public
    function CanonicalName(const ASourceName: string): string; override;
    function Exists(const ASourceName: string): Boolean; override;
    function FolderExists(const AFolderName: string): Boolean; override;
    function ReadSource(const ASourceName: string; out AText: string;
      out AVersion: Integer): Boolean; override;
    function SelectFiles(const AFolderName, AFileNamePattern: string;
      ARecursive: Boolean): TStringList; override;
    function SameIdentity(const ALeft, ARight: string): Boolean; override;
    function SupportsRelativePaths(const ASourceName: string): Boolean;
      override;
  end;

implementation

uses
  SysUtils;

function TNexusScriptFileSourceProvider.CanonicalName(
  const ASourceName: string): string;
begin
  Result := ExpandFileName(ASourceName);
end;

function TNexusScriptFileSourceProvider.Exists(
  const ASourceName: string): Boolean;
begin
  Result := FileExists(CanonicalName(ASourceName));
end;

function TNexusScriptFileSourceProvider.FolderExists(
  const AFolderName: string): Boolean;
begin
  Result := DirectoryExists(CanonicalName(AFolderName));
end;

function TNexusScriptFileSourceProvider.ReadSource(const ASourceName: string;
  out AText: string; out AVersion: Integer): Boolean;
var
  lSource: TStringList;
begin
  AText := '';
  AVersion := -1;
  Result := False;
  if not Exists(ASourceName) then
    Exit;
  lSource := TStringList.Create;
  try
    lSource.LoadFromFile(CanonicalName(ASourceName));
    AText := lSource.Text;
    Result := True;
  finally
    lSource.Free;
  end;
end;

function TNexusScriptFileSourceProvider.SelectFiles(const AFolderName,
  AFileNamePattern: string; ARecursive: Boolean): TStringList;

  procedure SelectFromFolder(const AFolder: string; AFiles: TStringList);
  var
    lSearch: TSearchRec;
    lFileName: string;
  begin
    if FindFirst(IncludeTrailingPathDelimiter(AFolder) + AFileNamePattern,
      faAnyFile, lSearch) = 0 then
    try
      repeat
        if (lSearch.Attr and faDirectory) = 0 then
        begin
          lFileName := CanonicalName(IncludeTrailingPathDelimiter(AFolder) +
            lSearch.Name);
          AFiles.Add(lFileName);
        end;
      until FindNext(lSearch) <> 0;
    finally
      FindClose(lSearch);
    end;
    if not ARecursive then
      Exit;
    if FindFirst(IncludeTrailingPathDelimiter(AFolder) + '*',
      faDirectory, lSearch) = 0 then
    try
      repeat
        if ((lSearch.Attr and faDirectory) <> 0) and
          (lSearch.Name <> '.') and (lSearch.Name <> '..') then
          SelectFromFolder(IncludeTrailingPathDelimiter(AFolder) +
            lSearch.Name, AFiles);
      until FindNext(lSearch) <> 0;
    finally
      FindClose(lSearch);
    end;
  end;

begin
  Result := TStringList.Create;
  SelectFromFolder(CanonicalName(AFolderName), Result);
end;

function TNexusScriptFileSourceProvider.SameIdentity(const ALeft,
  ARight: string): Boolean;
begin
  Result := SameFileName(CanonicalName(ALeft), CanonicalName(ARight));
end;

function TNexusScriptFileSourceProvider.SupportsRelativePaths(
  const ASourceName: string): Boolean;
begin
  Result := True;
end;

end.

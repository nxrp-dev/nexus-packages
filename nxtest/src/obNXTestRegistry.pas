(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTestRegistry;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, obNXTestSuite, obNXTestCase;

type
  TNXTestRegistry = class
  private
    FSuites: TList;
    function GetSuite(AIndex: Integer): TNXTestSuite;
  public
    constructor Create;
    destructor Destroy; override;

    function AddSuite(const AName: string): TNXTestSuite;
    function FindSuite(const AName: string): TNXTestSuite;
    function FindTest(const ANameOrId: string; out ASuite: TNXTestSuite): TNXTestCase;
    function SuiteCount: Integer;

    property Suites[AIndex: Integer]: TNXTestSuite read GetSuite;
  end;

implementation

constructor TNXTestRegistry.Create;
begin
  inherited Create;
  FSuites := TList.Create;
end;

destructor TNXTestRegistry.Destroy;
var
  lIndex: Integer;
begin
  for lIndex := 0 to FSuites.Count - 1 do
    TObject(FSuites[lIndex]).Free;
  FSuites.Free;
  inherited Destroy;
end;

function TNXTestRegistry.GetSuite(AIndex: Integer): TNXTestSuite;
begin
  Result := TNXTestSuite(FSuites[AIndex]);
end;

function TNXTestRegistry.AddSuite(const AName: string): TNXTestSuite;
begin
  Result := FindSuite(AName);
  if Assigned(Result) then
    Exit;

  Result := TNXTestSuite.Create(AName);
  FSuites.Add(Result);
end;

function TNXTestRegistry.FindSuite(const AName: string): TNXTestSuite;
var
  lIndex: Integer;
  lSuite: TNXTestSuite;
begin
  Result := nil;

  for lIndex := 0 to FSuites.Count - 1 do
  begin
    lSuite := TNXTestSuite(FSuites[lIndex]);
    if SameText(lSuite.Name, AName) then
      Exit(lSuite);
  end;
end;

function TNXTestRegistry.FindTest(const ANameOrId: string; out ASuite: TNXTestSuite): TNXTestCase;
var
  lIndex: Integer;
  lSuite: TNXTestSuite;
begin
  Result := nil;
  ASuite := nil;

  for lIndex := 0 to FSuites.Count - 1 do
  begin
    lSuite := TNXTestSuite(FSuites[lIndex]);
    Result := lSuite.FindTest(ANameOrId);
    if Assigned(Result) then
    begin
      ASuite := lSuite;
      Exit;
    end;
  end;
end;

function TNXTestRegistry.SuiteCount: Integer;
begin
  Result := FSuites.Count;
end;

end.

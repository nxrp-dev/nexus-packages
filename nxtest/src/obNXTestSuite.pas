(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTestSuite;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, obNXTestCase;

type
  TNXTestSuite = class
  private
    FName: string;
    FTests: TList;
    function GetTest(AIndex: Integer): TNXTestCase;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;

    function AddTest(const AName: string; ATestProcedure: TNXTestProcedure;
      const ACategory: string = ''): TNXTestCase;
    function FindTest(const ANameOrId: string): TNXTestCase;
    function TestCount: Integer;

    property Name: string read FName;
    property Tests[AIndex: Integer]: TNXTestCase read GetTest;
  end;

implementation

constructor TNXTestSuite.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FTests := TList.Create;
end;

destructor TNXTestSuite.Destroy;
var
  lIndex: Integer;
begin
  for lIndex := 0 to FTests.Count - 1 do
    TObject(FTests[lIndex]).Free;
  FTests.Free;
  inherited Destroy;
end;

function TNXTestSuite.GetTest(AIndex: Integer): TNXTestCase;
begin
  Result := TNXTestCase(FTests[AIndex]);
end;

function TNXTestSuite.AddTest(const AName: string;
  ATestProcedure: TNXTestProcedure; const ACategory: string): TNXTestCase;
begin
  Result := TNXTestCase.Create(AName, FName + '.' + AName, ATestProcedure,
    ACategory);
  FTests.Add(Result);
end;

function TNXTestSuite.FindTest(const ANameOrId: string): TNXTestCase;
var
  lIndex: Integer;
  lTest: TNXTestCase;
begin
  Result := nil;

  for lIndex := 0 to FTests.Count - 1 do
  begin
    lTest := TNXTestCase(FTests[lIndex]);
    if SameText(lTest.Name, ANameOrId) or SameText(lTest.TestId, ANameOrId) then
      Exit(lTest);
  end;
end;

function TNXTestSuite.TestCount: Integer;
begin
  Result := FTests.Count;
end;

end.

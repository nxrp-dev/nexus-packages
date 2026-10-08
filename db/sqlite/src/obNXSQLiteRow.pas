(*
  Copyright (c) 2026 Kevin Collins.
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)
unit obNXSQLiteRow;

{$mode objfpc}{$H+}

interface

type
  TNXSQLiteRow = class
  private
    FID: QWord;
    FValues: array of Variant;
    FAssigned: array of Boolean;
  protected
    function GetValue(AIndex: Integer): Variant;
    procedure SetValue(AIndex: Integer; const AValue: Variant);
    function GetAssigned(AIndex: Integer): Boolean;
  public
    constructor Create(ACount: Integer);
    procedure Assign(ARow: TNXSQLiteRow);
    procedure Clear;
    property ID: QWord read FID write FID;
    property Values[AIndex: Integer]: Variant read GetValue write SetValue; default;
    property Assigned[AIndex: Integer]: Boolean read GetAssigned;
  end;

implementation

uses Variants;

constructor TNXSQLiteRow.Create(ACount: Integer);
begin
  inherited Create;
  SetLength(FValues, ACount);
  SetLength(FAssigned, ACount);
  Clear;
end;

function TNXSQLiteRow.GetValue(AIndex: Integer): Variant;
begin
  Result := FValues[AIndex];
end;

procedure TNXSQLiteRow.SetValue(AIndex: Integer; const AValue: Variant);
begin
  FValues[AIndex] := AValue;
  FAssigned[AIndex] := True;
end;

function TNXSQLiteRow.GetAssigned(AIndex: Integer): Boolean;
begin
  Result := FAssigned[AIndex];
end;

procedure TNXSQLiteRow.Assign(ARow: TNXSQLiteRow);
var
  lIndex: Integer;
begin
  FID := ARow.ID;
  SetLength(FValues, Length(ARow.FValues));
  SetLength(FAssigned, Length(ARow.FAssigned));
  for lIndex := 0 to High(FValues) do
  begin
    FValues[lIndex] := ARow.FValues[lIndex];
    FAssigned[lIndex] := ARow.FAssigned[lIndex];
  end;
end;

procedure TNXSQLiteRow.Clear;
var
  lIndex: Integer;
begin
  FID := 0;
  for lIndex := 0 to High(FValues) do
  begin
    FValues[lIndex] := Null;
    FAssigned[lIndex] := False;
  end;
end;

end.

(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNexusScriptTextConstraints;

{$mode delphi}{$H+}

interface
uses Classes, SysUtils, Generics.Collections, tpNexusScript;

type
  { Value-dependent dialect checks survive compilation until Live has text. }
  TNexusScriptTextConstraint = class
  private
    FScalarKind: TNSScalarKind;
    FValidationSource: string;
    FAllowedValues: TStringList;
    FAllowedValueCode: string;
  public
    constructor Create;
    destructor Destroy; override;
    function Clone: TNexusScriptTextConstraint;
    function Check(const AText: string; out ACode, AMessage: string): Boolean;
    property ValidationSource: string read FValidationSource write FValidationSource;
    property ScalarKind: TNSScalarKind read FScalarKind write FScalarKind;
    property AllowedValues: TStringList read FAllowedValues;
    property AllowedValueCode: string read FAllowedValueCode write FAllowedValueCode;
  end;

  TNexusScriptTextConstraintList = class(TObjectList<TNexusScriptTextConstraint>)
  public
    procedure Assign(ASource: TNexusScriptTextConstraintList);
  end;

implementation

constructor TNexusScriptTextConstraint.Create;
begin
  inherited Create;
  FAllowedValues := TStringList.Create;
  FAllowedValues.CaseSensitive := False;
  FAllowedValueCode := 'NSV2306';
end;

destructor TNexusScriptTextConstraint.Destroy;
begin
  FAllowedValues.Free;
  inherited Destroy;
end;

function TNexusScriptTextConstraint.Clone: TNexusScriptTextConstraint;
begin
  Result := TNexusScriptTextConstraint.Create;
  Result.FScalarKind := FScalarKind;
  Result.FValidationSource := FValidationSource;
  Result.FAllowedValues.Assign(FAllowedValues);
  Result.FAllowedValueCode := FAllowedValueCode;
end;

function TNexusScriptTextConstraint.Check(const AText: string;
  out ACode, AMessage: string): Boolean;
var
  lInteger, lCode: Integer;
begin
  ACode := '';
  AMessage := '';
  case FScalarKind of
    nskInteger:
      begin
        Val(AText, lInteger, lCode);
        if (lCode <> 0) or not ((IntToStr(lInteger) = AText) or
          ((lInteger = 0) and (AText = '-0'))) then
        begin
          ACode := 'NSV2304';
          AMessage := 'Value must be an Integer.';
        end;
      end;
    nskBoolean:
      if not SameText(AText, 'True') and not SameText(AText, 'False') then
      begin
        ACode := 'NSV2305';
        AMessage := 'Value must be True or False.';
      end;
  end;
  if (ACode = '') and (FAllowedValues.Count > 0) and
    (FAllowedValues.IndexOf(AText) < 0) then
  begin
    ACode := FAllowedValueCode;
    AMessage := 'Value ' + AText + ' is not allowed.';
  end;
  Result := ACode = '';
end;

procedure TNexusScriptTextConstraintList.Assign(ASource: TNexusScriptTextConstraintList);
var
  lConstraint: TNexusScriptTextConstraint;
begin
  if ASource = Self then Exit;
  Clear;
  for lConstraint in ASource do Add(lConstraint.Clone);
end;

end.

(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXSkinPalette;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  fpg_base,
  tpNXRender,
  tpNXSkin;

type
  // Presence is independent of the value, including zero and an empty font
  // descriptor (which explicitly selects fpGUI's application default font).
  // Fill is one value: its stops never fall back independently.
  TNXSkinOverrides = class
  private
    FValues: array[TNXSkinIntent] of TNXSkinAppearance;
    FDefined: array[TNXSkinIntent] of TNXSkinAttributes;
    procedure FillMissing(AIntent: TNXSkinIntent;
      var AValue: TNXSkinAppearance; var AMissing: TNXSkinAttributes);
  protected
    function GetDefined(AIntent: TNXSkinIntent): TNXSkinAttributes;
  public
    procedure SetColor(AIntent: TNXSkinIntent; AColor: TfpgColor);
    procedure SetFont(AIntent: TNXSkinIntent; const AFontDesc: string);
    procedure SetFill(AIntent: TNXSkinIntent; const AFill: TNXSkinFill);
    procedure Clear(AIntent: TNXSkinIntent; AAttributes: TNXSkinAttributes);
    property Defined[AIntent: TNXSkinIntent]: TNXSkinAttributes read GetDefined;
  end;

  TNXSkinRenderValues = class
  private
    FValues: TNXSkinOverrides;
    FStates: array[TNXRenderState] of TNXSkinOverrides;
  protected
    function GetState(AState: TNXRenderState): TNXSkinOverrides;
  public
    constructor Create;
    destructor Destroy; override;
    property Values: TNXSkinOverrides read FValues;
    property States[AState: TNXRenderState]: TNXSkinOverrides read GetState;
  end;

  TNXSkinPalette = class
  private
    // Existing painter roles stay separate until their render model is defined.
    FColors: TNXSkinColors;
    FDefaults: TNXSkinOverrides;
    FRenderValues: TStringList;
  protected
    function GetColor(ARole: TNXSkinColorRole): TfpgColor;
    procedure SetColor(ARole: TNXSkinColorRole; AColor: TfpgColor);
  public
    constructor Create;
    destructor Destroy; override;
    // The palette owns render entries and their override objects.
    function AddRender(const AName: string): TNXSkinRenderValues;
    function FindRender(const AName: string): TNXSkinRenderValues;
    procedure RemoveRender(const AName: string);
    // Read-only lookup: unknown render names fall back to the global intent.
    function Resolve(const ARender: string; AIntent: TNXSkinIntent;
      AStates: TNXRenderStates = []): TNXSkinAppearance;
    property Defaults: TNXSkinOverrides read FDefaults;
    property Colors[ARole: TNXSkinColorRole]: TfpgColor
      read GetColor write SetColor; default;
  end;

implementation

uses
  SysUtils;

procedure TNXSkinOverrides.SetColor(AIntent: TNXSkinIntent;
  AColor: TfpgColor);
begin
  FValues[AIntent].Color := AColor;
  Include(FDefined[AIntent], saColor);
end;

procedure TNXSkinOverrides.SetFont(AIntent: TNXSkinIntent;
  const AFontDesc: string);
begin
  FValues[AIntent].FontDesc := AFontDesc;
  Include(FDefined[AIntent], saFont);
end;

procedure TNXSkinOverrides.SetFill(AIntent: TNXSkinIntent;
  const AFill: TNXSkinFill);
begin
  FValues[AIntent].Fill := AFill;
  Include(FDefined[AIntent], saFill);
end;

procedure TNXSkinOverrides.Clear(AIntent: TNXSkinIntent;
  AAttributes: TNXSkinAttributes);
begin
  FDefined[AIntent] := FDefined[AIntent] - AAttributes;
end;

function TNXSkinOverrides.GetDefined(AIntent: TNXSkinIntent): TNXSkinAttributes;
begin
  Result := FDefined[AIntent];
end;

procedure TNXSkinOverrides.FillMissing(AIntent: TNXSkinIntent;
  var AValue: TNXSkinAppearance; var AMissing: TNXSkinAttributes);
var
  lTake: TNXSkinAttributes;
begin
  lTake := AMissing * FDefined[AIntent];
  if saColor in lTake then
    AValue.Color := FValues[AIntent].Color;
  if saFont in lTake then
    AValue.FontDesc := FValues[AIntent].FontDesc;
  if saFill in lTake then
    AValue.Fill := FValues[AIntent].Fill;
  AMissing := AMissing - lTake;
end;

constructor TNXSkinRenderValues.Create;
var
  lState: TNXRenderState;
begin
  inherited Create;
  FValues := TNXSkinOverrides.Create;
  for lState := Low(TNXRenderState) to High(TNXRenderState) do
    FStates[lState] := TNXSkinOverrides.Create;
end;

destructor TNXSkinRenderValues.Destroy;
var
  lState: TNXRenderState;
begin
  for lState := Low(TNXRenderState) to High(TNXRenderState) do
    FStates[lState].Free;
  FValues.Free;
  inherited Destroy;
end;

function TNXSkinRenderValues.GetState(AState: TNXRenderState): TNXSkinOverrides;
begin
  Result := FStates[AState];
end;

constructor TNXSkinPalette.Create;
begin
  inherited Create;
  FColors := cNXSkinDefaultColors;
  FDefaults := TNXSkinOverrides.Create;
  FRenderValues := TStringList.Create;
  // Use the same name identity as TNXRenderRegistry.
  FRenderValues.CaseSensitive := True;
  FRenderValues.Sorted := True;
end;

destructor TNXSkinPalette.Destroy;
var
  lIndex: Integer;
begin
  if FRenderValues <> nil then
    for lIndex := 0 to FRenderValues.Count - 1 do
      FRenderValues.Objects[lIndex].Free;
  FRenderValues.Free;
  FDefaults.Free;
  inherited Destroy;
end;

function TNXSkinPalette.AddRender(const AName: string): TNXSkinRenderValues;
begin
  if AName = '' then
    raise Exception.Create('Render values require a name.');
  if FindRender(AName) <> nil then
    raise Exception.CreateFmt('Render values "%s" are already defined.', [AName]);
  Result := TNXSkinRenderValues.Create;
  try
    FRenderValues.AddObject(AName, Result);
  except
    Result.Free;
    raise;
  end;
end;

function TNXSkinPalette.FindRender(const AName: string): TNXSkinRenderValues;
var
  lIndex: Integer;
begin
  lIndex := FRenderValues.IndexOf(AName);
  if lIndex < 0 then
    Exit(nil);
  Result := FRenderValues.Objects[lIndex] as TNXSkinRenderValues;
end;

procedure TNXSkinPalette.RemoveRender(const AName: string);
var
  lIndex: Integer;
begin
  lIndex := FRenderValues.IndexOf(AName);
  if lIndex < 0 then
    Exit;
  FRenderValues.Objects[lIndex].Free;
  FRenderValues.Delete(lIndex);
end;

function TNXSkinPalette.Resolve(const ARender: string;
  AIntent: TNXSkinIntent; AStates: TNXRenderStates): TNXSkinAppearance;
const
  cPriority: array[0..4] of TNXRenderState =
    (nrsDisabled, nrsPressed, nrsHovered, nrsSelected, nrsFocused);
var
  lRender: TNXSkinRenderValues;
  lState: TNXRenderState;
  lMissing: TNXSkinAttributes;
begin
  // Built-in defaults remain when a global override is cleared.
  Result.Color := cNXSkinDefaultIntentColors[AIntent];
  Result.FontDesc := cNXSkinDefaultFont;
  Result.Fill := Default(TNXSkinFill);
  Result.Fill.Color := cNXSkinDefaultIntentColors[AIntent];
  lMissing := [saColor, saFont, saFill];
  if nrsDisabled in AStates then
    AStates := AStates * [nrsDisabled, nrsSelected];
  lRender := FindRender(ARender);
  if lRender <> nil then
  begin
    for lState in cPriority do
      if lState in AStates then
        lRender.States[lState].FillMissing(AIntent, Result, lMissing);
    lRender.Values.FillMissing(AIntent, Result, lMissing);
  end;
  FDefaults.FillMissing(AIntent, Result, lMissing);
end;

function TNXSkinPalette.GetColor(ARole: TNXSkinColorRole): TfpgColor;
begin
  Result := FColors[ARole];
end;

procedure TNXSkinPalette.SetColor(ARole: TNXSkinColorRole; AColor: TfpgColor);
begin
  FColors[ARole] := AColor;
end;

end.

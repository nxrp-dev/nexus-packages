(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXRenderAppearance;

{$mode objfpc}{$H+}

interface

uses obNXRender, obNXSkinPalette, tpNXSkin;

type
  // Scalar snapshots for Lua. Borrows the skin palette; owns no font resource.
  TNXRenderAppearance = class(TNXRenderResources)
  private
    FPalette: TNXSkinPalette;
    FIntent: TNXSkinIntent;
    FColor: LongWord;
    FFontDesc: string;
  public
    constructor Create(APalette: TNXSkinPalette; AIntent: TNXSkinIntent);
    procedure Prepare(const ARenderName: string;
      AState: TNexusControlState); override;
  published
    property Color: LongWord read FColor;
    property FontDesc: string read FFontDesc;
  end;

implementation

constructor TNXRenderAppearance.Create(APalette: TNXSkinPalette;
  AIntent: TNXSkinIntent);
begin
  inherited Create;
  FPalette := APalette;
  FIntent := AIntent;
end;

procedure TNXRenderAppearance.Prepare(const ARenderName: string;
  AState: TNexusControlState);
var
  lValue: TNXSkinAppearance;
begin
  lValue := FPalette.Resolve(ARenderName, FIntent, AState.States);
  FColor := LongWord(lValue.Color);
  FFontDesc := lValue.FontDesc;
end;

end.

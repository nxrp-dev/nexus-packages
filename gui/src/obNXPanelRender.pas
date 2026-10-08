(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXPanelRender;

{$mode objfpc}{$H+}

interface

uses Classes, fpg_base, fpg_main, fpg_panel, obNXRender, obNXSkinPalette;

const
  cNXPanelFrame = 'PanelFrame';

type
  TNXPanelFrameState = class(TNexusControlState)
  private
    FStyle: TPanelStyle;
    FBorderStyle: TPanelBorder;
  published
    property Style: TPanelStyle read FStyle write FStyle;
    property BorderStyle: TPanelBorder read FBorderStyle write FBorderStyle;
  end;

  // Borrows the owning skin's palette; retains no control-state reference.
  TNXPanelFrameColors = class(TNXRenderResources)
  private
    FPalette: TNXSkinPalette;
    FHighlight, FShadow: LongWord;
  public
    constructor Create(APalette: TNXSkinPalette);
    procedure Prepare(const ARenderName: string;
      AState: TNexusControlState); override;
  published
    property Highlight: LongWord read FHighlight;
    property Shadow: LongWord read FShadow;
  end;

  TNXPanelFrameRenderer = class(TNXRenderer)
  private
    FColors: TNXPanelFrameColors;
  protected
    function Bind(AState: TNexusControlState): TNXRenderSubscription; override;
  public
    constructor Create(APalette: TNXSkinPalette);
    destructor Destroy; override;
    procedure Draw(ACanvas: TfpgCanvas; AState: TNXPanelFrameState;
      const ARenderName: string);
  end;

implementation

uses SysUtils, tpNXSkin;

type
  TNXPanelFrameSubscription = class(TNXRenderSubscription)
  private
    FRenderer: TNXPanelFrameRenderer;
    FState: TNXPanelFrameState;
  protected
    procedure DoRender(ACanvas: TfpgCanvas); override;
    procedure Invalidate; override;
  public
    constructor Create(ARenderer: TNXPanelFrameRenderer; AState: TNXPanelFrameState);
  end;

constructor TNXPanelFrameColors.Create(APalette: TNXSkinPalette);
begin
  inherited Create;
  if APalette = nil then
    raise Exception.Create('Panel colors require a skin palette.');
  FPalette := APalette;
end;

procedure TNXPanelFrameColors.Prepare(const ARenderName: string;
  AState: TNexusControlState);
begin
  FHighlight := LongWord(FPalette.Resolve(ARenderName, siHighlight, AState.States).Color);
  FShadow := LongWord(FPalette.Resolve(ARenderName, siShadow, AState.States).Color);
end;

constructor TNXPanelFrameSubscription.Create(ARenderer: TNXPanelFrameRenderer;
  AState: TNXPanelFrameState);
begin
  inherited Create;
  FRenderer := ARenderer;
  FState := AState;
end;

procedure TNXPanelFrameSubscription.DoRender(ACanvas: TfpgCanvas);
begin
  FRenderer.Draw(ACanvas, FState, Name);
end;

procedure TNXPanelFrameSubscription.Invalidate;
begin
  FRenderer := nil;
  FState := nil;
  inherited Invalidate;
end;

constructor TNXPanelFrameRenderer.Create(APalette: TNXSkinPalette);
begin
  inherited Create(TNXPanelFrameState);
  FColors := TNXPanelFrameColors.Create(APalette);
end;

destructor TNXPanelFrameRenderer.Destroy;
begin
  FColors.Free;
  inherited Destroy;
end;

function TNXPanelFrameRenderer.Bind(AState: TNexusControlState): TNXRenderSubscription;
begin
  Result := TNXPanelFrameSubscription.Create(Self, AState as TNXPanelFrameState);
end;

procedure TNXPanelFrameRenderer.Draw(ACanvas: TfpgCanvas; AState: TNXPanelFrameState;
  const ARenderName: string);
var
  lWidth: Integer;
begin
  if AState.Style = bsFlat then
    Exit;
  FColors.Prepare(ARenderName, AState);
  if AState.BorderStyle = bsSingle then
    lWidth := 1
  else
    lWidth := 2;
  if AState.Style = bsRaised then
    ACanvas.SetColor(FColors.Highlight)
  else
    ACanvas.SetColor(FColors.Shadow);
  ACanvas.SetLineStyle(lWidth, lsSolid);
  if AState.BorderStyle = bsSingle then
  begin
    ACanvas.DrawLine(AState.Left, AState.Top,
      AState.Left + AState.Width - 1, AState.Top);
    ACanvas.DrawLine(AState.Left, AState.Top + 1,
      AState.Left, AState.Top + AState.Height - 1);
  end
  else
  begin
    ACanvas.DrawLine(AState.Left, AState.Top + 1,
      AState.Left + AState.Width - 1, AState.Top + 1);
    ACanvas.DrawLine(AState.Left + 1, AState.Top + 1,
      AState.Left + 1, AState.Top + AState.Height - 1);
  end;
  if AState.Style = bsRaised then
    ACanvas.SetColor(FColors.Shadow)
  else
    ACanvas.SetColor(FColors.Highlight);
  ACanvas.SetLineStyle(lWidth, lsSolid);
  ACanvas.DrawLine(AState.Left + AState.Width - 1, AState.Top,
    AState.Left + AState.Width - 1, AState.Top + AState.Height - 1);
  ACanvas.DrawLine(AState.Left, AState.Top + AState.Height - 1,
    AState.Left + AState.Width, AState.Top + AState.Height - 1);
end;

end.

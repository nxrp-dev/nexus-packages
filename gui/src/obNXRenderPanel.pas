(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXRenderPanel;

{$mode objfpc}{$H+}

interface

uses Classes, fpg_panel, tpNXRender, obNXRender, obNXPanelRender, obNXSkin;

type
  TNXRenderPanel = class(TfpgPanel)
  private
    FFrameState: TNXPanelFrameState;
    FFrameRender: TNXRenderSubscription;
    FHovered: Boolean;
  protected
    function GetRenderStates: TNXRenderStates;
    procedure HandleMouseEnter; override;
    procedure HandleMouseExit; override;
    procedure HandlePaint; override;
  public
    constructor Create(AOwner: TComponent; ASkin: TNXSkin); reintroduce;
    destructor Destroy; override;
  end;

implementation

uses fpg_base, fpg_main;

constructor TNXRenderPanel.Create(AOwner: TComponent; ASkin: TNXSkin);
begin
  inherited Create(AOwner);
  FFrameState := TNXPanelFrameState.Create;
  FFrameRender := ASkin.Subscribe(cNXPanelFrame, FFrameState);
end;

destructor TNXRenderPanel.Destroy;
begin
  FFrameRender.Free;
  FFrameState.Free;
  inherited Destroy;
end;

function TNXRenderPanel.GetRenderStates: TNXRenderStates;
begin
  Result := [];
  if not Enabled then
    Include(Result, nrsDisabled);
  if FHovered then
    Include(Result, nrsHovered);
  if Focused then
    Include(Result, nrsFocused);
end;

procedure TNXRenderPanel.HandleMouseEnter;
begin
  inherited HandleMouseEnter;
  FHovered := True;
  RePaint;
end;

procedure TNXRenderPanel.HandleMouseExit;
begin
  inherited HandleMouseExit;
  FHovered := False;
  RePaint;
end;

procedure TNXRenderPanel.HandlePaint;
var
  lTextFlags: TfpgTextFlags;
begin
  // TfpgPanel has no border hook: preserve its background/caption orchestration
  // without invoking its border painter. Child traversal remains in fpGUI.
  Canvas.ClearClipRect;
  if BackgroundColor <> clNone then
    Canvas.Clear(BackgroundColor);
  if ParentBackgroundColor then
    Canvas.Clear(Parent.BackgroundColor)
  else
    Canvas.Clear(BackgroundColor);

  FFrameState.Left := 0;
  FFrameState.Top := 0;
  FFrameState.Width := ActualWidth;
  FFrameState.Height := ActualHeight;
  FFrameState.States := GetRenderStates;
  FFrameState.Style := Style;
  FFrameState.BorderStyle := BorderStyle;
  FFrameRender.Render(Canvas);

  Canvas.SetTextColor(TextColor);
  Canvas.SetFont(Font);
  lTextFlags := [];
  if not Enabled then
    Include(lTextFlags, txtDisabled);
  if WrapText then
    Include(lTextFlags, txtWrap);
  case Alignment of
    taLeftJustify: Include(lTextFlags, txtLeft);
    taRightJustify: Include(lTextFlags, txtRight);
    taCenter: Include(lTextFlags, txtHCenter);
  end;
  case Layout of
    tlTop: Include(lTextFlags, txtTop);
    tlBottom: Include(lTextFlags, txtBottom);
    tlCenter: Include(lTextFlags, txtVCenter);
  end;
  Canvas.DrawText(Margin, Margin, ActualWidth - Margin * 2,
    ActualHeight - Margin * 2, Text, lTextFlags, LineSpace);
end;

end.

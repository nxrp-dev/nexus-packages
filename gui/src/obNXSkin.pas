(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXSkin;

{$mode objfpc}{$H+}

interface

uses
  Types,
  fpg_base,
  fpg_main,
  obNXRender,
  obNXSkinPalette,
  obNexusScriptModel,
  tpNXSkin;

type
  TNXSkin = class(TfpgStyle)
  private
    FColors: TNXSkinPalette;
    FRenderRegistry: TNXRenderRegistry;
    procedure InitializeAppearance;
    class procedure SetColorBinding(APalette: TNXSkinPalette;
      const ABinding: TNXSkinColorBinding; AColor: TfpgColor); static;
    class procedure SetFillBinding(APalette: TNXSkinPalette;
      const ABinding: TNXSkinFillBinding; AStart, AStop: TfpgColor); static;
    class procedure CopyBevelFills(APalette: TNXSkinPalette); static;
    procedure DrawFill(ACanvas: TfpgCanvas; ARect: TfpgRect;
      const AFill: TNXSkinFill);
    class function TryParseColor(const AText: string;
      out AColor: TfpgColor): Boolean; static;
    class function TryReadColor(ADefinition: TNexusScriptCompiledDefinition;
      const AName: string; out AColor: TfpgColor; out AError: string): Boolean; static;
  public
    constructor Create; override;
    destructor Destroy; override;
    // Publish this palette to fpGUI's application-wide named colors.
    procedure ApplyNamedColors;
    procedure RegisterRenderer(const AName: string; ARenderer: TNXRenderer);
    function Subscribe(const AName: string;
      AState: TNexusControlState): TNXRenderSubscription;
    procedure ClearRenderers;
    property RenderRegistry: TNXRenderRegistry read FRenderRegistry;

    // On success the caller owns APalette; on failure it is nil.
    class function TryReadPalette(ADocument: TNexusScriptCompiledDocument;
      out APalette: TNXSkinPalette; out AError: string): Boolean; static;
    function LoadCompiledDocument(ADocument: TNexusScriptCompiledDocument;
      out AError: string): Boolean;

    procedure DrawControlFrame(ACanvas: TfpgCanvas; x, y, w, h: TfpgCoord);
      override; overload;
    procedure DrawBevel(ACanvas: TfpgCanvas; x, y, w, h: TfpgCoord;
      ARaised: Boolean = True); override;
    procedure DrawDirectionArrow(ACanvas: TfpgCanvas; x, y, w, h: TfpgCoord;
      ADirection: TArrowDirection); override;
    procedure DrawString(ACanvas: TfpgCanvas; x, y: TfpgCoord;
      AText: string; AEnabled: Boolean = True); override;
    procedure DrawFocusRect(ACanvas: TfpgCanvas; ARect: TfpgRect); override;
    procedure DrawButtonFace(ACanvas: TfpgCanvas; x, y, w, h: TfpgCoord;
      AFlags: TfpgButtonFlags); override;
    function GetButtonBorders: TRect; override;
    function GetButtonShift: TPoint; override;
    function HasButtonHoverEffect: Boolean; override;
    procedure DrawMenuBar(ACanvas: TfpgCanvas; ARect: TfpgRect;
      ABackgroundColor: TfpgColor); override;
    procedure DrawMenuRow(ACanvas: TfpgCanvas; ARect: TfpgRect;
      AFlags: TfpgMenuItemFlags); override;
    procedure DrawMenuItemSeparator(ACanvas: TfpgCanvas;
      ARect: TfpgRect); override;
    procedure DrawProgressBar(ACanvas: TfpgCanvas;
      AParams: TfpgStyleDrawProgressBar); override;
    function GetCheckBoxSize: Integer; override;
    procedure DrawCheckBox(ACanvas: TfpgCanvas; ARect: TfpgRect;
      AFlags: TfpgCheckBoxFlags); override;
    function GetRadioButtonSize: Integer; override;
    procedure DrawRadioButton(ACanvas: TfpgCanvas; ARect: TfpgRect;
      AFlags: TfpgCheckBoxFlags); override;
    procedure DrawPageControlBody(ACanvas: TfpgCanvas;
      ARect: TfpgRect); override;
    procedure DrawPageControlTab(ACanvas: TfpgCanvas;
      AParams: TfpgStyleDrawTab); override;

    property Colors: TNXSkinPalette read FColors;
  end;

implementation

uses
  SysUtils,
  fpg_stylemanager,
  tpNXRender,
  fpg_tab;

constructor TNXSkin.Create;
begin
  inherited Create;
  FRenderRegistry := TNXRenderRegistry.Create;
  FColors := TNXSkinPalette.Create;
  InitializeAppearance;
  ApplyNamedColors;
end;

destructor TNXSkin.Destroy;
begin
  FRenderRegistry.Free;
  FColors.Free;
  inherited Destroy;
end;

procedure TNXSkin.RegisterRenderer(const AName: string; ARenderer: TNXRenderer);
begin
  FRenderRegistry.RegisterRenderer(AName, ARenderer);
end;

function TNXSkin.Subscribe(const AName: string;
  AState: TNexusControlState): TNXRenderSubscription;
begin
  Result := FRenderRegistry.Subscribe(AName, AState);
end;

procedure TNXSkin.ClearRenderers;
begin
  if FRenderRegistry <> nil then
    FRenderRegistry.Clear;
end;

class procedure TNXSkin.SetColorBinding(APalette: TNXSkinPalette;
  const ABinding: TNXSkinColorBinding; AColor: TfpgColor);
var
  lRender: TNXSkinRenderValues;
  lState: TNXRenderState;
begin
  if ABinding.RenderName = '' then
  begin
    APalette.Defaults.SetColor(ABinding.Intent, AColor);
    Exit;
  end;
  lRender := APalette.FindRender(ABinding.RenderName);
  if lRender = nil then
    lRender := APalette.AddRender(ABinding.RenderName);
  if ABinding.States = [] then
    lRender.Values.SetColor(ABinding.Intent, AColor)
  else
    for lState in ABinding.States do
      lRender.States[lState].SetColor(ABinding.Intent, AColor);
end;

class procedure TNXSkin.SetFillBinding(APalette: TNXSkinPalette;
  const ABinding: TNXSkinFillBinding; AStart, AStop: TfpgColor);
var
  lFill: TNXSkinFill;
  lRender: TNXSkinRenderValues;
  lState: TNXRenderState;
begin
  lFill := Default(TNXSkinFill);
  lFill.Kind := sfGradient;
  lFill.Color := AStart;
  lFill.StopColor := AStop;
  lFill.Direction := gdVertical;
  lRender := APalette.FindRender(ABinding.RenderName);
  if lRender = nil then
    lRender := APalette.AddRender(ABinding.RenderName);
  if ABinding.States = [] then
    lRender.Values.SetFill(siHighlight, lFill)
  else
    for lState in ABinding.States do
      lRender.States[lState].SetFill(siHighlight, lFill);
end;

class procedure TNXSkin.CopyBevelFills(APalette: TNXSkinPalette);
var
  lBevel: TNXSkinRenderValues;
begin
  lBevel := APalette.FindRender(cNXBevelRender);
  if lBevel = nil then
    lBevel := APalette.AddRender(cNXBevelRender);
  lBevel.Values.SetFill(siHighlight,
    APalette.Resolve(cNXButtonRender, siHighlight).Fill);
  lBevel.Values.SetFill(siShadow,
    APalette.Resolve(cNXButtonRender, siHighlight, [nrsPressed]).Fill);
end;

procedure TNXSkin.DrawFill(ACanvas: TfpgCanvas; ARect: TfpgRect;
  const AFill: TNXSkinFill);
begin
  case AFill.Kind of
    sfSolid:
      begin
        ACanvas.SetColor(AFill.Color);
        ACanvas.FillRectangle(ARect);
      end;
    sfGradient:
      ACanvas.GradientFill(ARect, AFill.Color, AFill.StopColor,
        AFill.Direction);
  end;
end;

procedure TNXSkin.InitializeAppearance;
var
  lBinding: TNXSkinColorBinding;
  lFillBinding: TNXSkinFillBinding;
begin
  for lBinding in cNXSkinColorBindings do
    SetColorBinding(FColors, lBinding, lBinding.DefaultColor);
  for lFillBinding in cNXSkinFillBindings do
    SetFillBinding(FColors, lFillBinding, lFillBinding.DefaultStart,
      lFillBinding.DefaultStop);
  CopyBevelFills(FColors);
  // WidgetFrame remains a flat painter role until those painters are migrated.
  FColors.Defaults.SetColor(siHighlight, FColors[scrWidgetFrame]);
end;

procedure TNXSkin.ApplyNamedColors;
var
  lText, lDisabledText, lSelectedText, lShadow: TfpgColor;
begin
  lText := FColors.Resolve('', siText).Color;
  lDisabledText := FColors.Resolve(cNXTextRender, siText, [nrsDisabled]).Color;
  lSelectedText := FColors.Resolve(cNXTextRender, siText, [nrsSelected]).Color;
  lShadow := FColors.Resolve('', siShadow).Color;
  fpgSetNamedColor(clWindowBackground, FColors[scrWindowBackground]);
  fpgSetNamedColor(clBoxColor, FColors[scrInputBackground]);
  fpgSetNamedColor(clShadow1, lShadow);
  fpgSetNamedColor(clShadow2, FColors[scrWidgetFrame]);
  fpgSetNamedColor(clHilite1, FColors.Resolve('', siHighlight).Color);
  fpgSetNamedColor(clHilite2, FColors.Resolve('', siHighlight).Color);
  fpgSetNamedColor(clText1, lText);
  fpgSetNamedColor(clText2, FColors[scrSelection]);
  fpgSetNamedColor(clText4, lDisabledText);
  fpgSetNamedColor(clSelection, FColors[scrSelection]);
  fpgSetNamedColor(clSelectionText, lSelectedText);
  fpgSetNamedColor(clInactiveSel, FColors[scrWidgetFrame]);
  fpgSetNamedColor(clInactiveSelText, lText);
  fpgSetNamedColor(clScrollBar, FColors[scrScrollBar]);
  fpgSetNamedColor(clButtonFace, FColors[scrWindowBackground]);
  fpgSetNamedColor(clListBox, FColors[scrInputBackground]);
  fpgSetNamedColor(clGridLines, FColors[scrGridLines]);
  fpgSetNamedColor(clGridHeader, FColors[scrWindowBackground]);
  fpgSetNamedColor(clWidgetFrame, FColors[scrWidgetFrame]);
  fpgSetNamedColor(clInactiveWgFrame, lShadow);
  fpgSetNamedColor(clMenuText, lText);
  fpgSetNamedColor(clMenuDisabled, lDisabledText);
  fpgSetNamedColor(clHintWindow, FColors[scrInputBackground]);
  fpgSetNamedColor(clGridSelection, FColors[scrSelection]);
  fpgSetNamedColor(clGridSelectionText, lSelectedText);
  fpgSetNamedColor(clGridInactiveSel, FColors[scrWidgetFrame]);
  fpgSetNamedColor(clGridInactiveSelText, lText);
  fpgSetNamedColor(clSplitterGrabBar, FColors[scrFocus]);
end;

class function TNXSkin.TryParseColor(const AText: string;
  out AColor: TfpgColor): Boolean;
var
  lValue: QWord;
begin
  AColor := 0;
  Result := (Length(AText) = 9) and (AText[1] = '#') and
    TryStrToQWord('$' + Copy(AText, 2, 8), lValue) and
    (lValue <= High(LongWord));
  if Result then
    AColor := TfpgColor(LongWord(lValue));
end;

class function TNXSkin.TryReadColor(ADefinition: TNexusScriptCompiledDefinition;
  const AName: string; out AColor: TfpgColor; out AError: string): Boolean;
var
  lProperty: TNexusScriptCompiledProperty;
begin
  Result := False;
  lProperty := ADefinition.FindProperty(AName);
  if (lProperty = nil) or not lProperty.Value.HasEffectiveText then
    AError := 'Skin color ' + AName + ' is required.'
  else if not TryParseColor(lProperty.Value.EffectiveText, AColor) then
    AError := 'Skin color ' + AName + ' must use #AARRGGBB.'
  else
    Result := True;
end;

class function TNXSkin.TryReadPalette(
  ADocument: TNexusScriptCompiledDocument; out APalette: TNXSkinPalette;
  out AError: string): Boolean;
var
  lColor: TfpgColor;
  lStart, lStop: TfpgColor;
  lDefinition: TNexusScriptCompiledDefinition;
  lProperty: TNexusScriptCompiledProperty;
  lRole: TNXSkinColorRole;
  lVersion: Integer;
  lPalette: TNXSkinPalette;
  lBinding: TNXSkinColorBinding;
  lFillBinding: TNXSkinFillBinding;
begin
  APalette := nil;
  AError := '';
  Result := False;

  if not Assigned(ADocument) then
  begin
    AError := 'A compiled skin document is required.';
    Exit;
  end;

  if ADocument.Definitions.Count <> 1 then
  begin
    AError := 'A skin document must contain exactly one root definition.';
    Exit;
  end;

  lDefinition := ADocument.Definitions[0];
  if not SameText(lDefinition.Kind, 'Skin') then
  begin
    AError := 'The root definition must be a Skin.';
    Exit;
  end;

  lProperty := lDefinition.FindProperty('Version');
  if (not Assigned(lProperty)) or
    (not lProperty.Value.HasEffectiveText) or
    (not TryStrToInt(lProperty.Value.EffectiveText, lVersion)) then
  begin
    AError := 'Skin Version must be an integer.';
    Exit;
  end;
  if lVersion <> 1 then
  begin
    AError := 'Unsupported skin version: ' + IntToStr(lVersion) + '.';
    Exit;
  end;

  lPalette := TNXSkinPalette.Create;
  try
    for lRole := Low(TNXSkinColorRole) to High(TNXSkinColorRole) do
    begin
      if not TryReadColor(lDefinition, cNXSkinColorNames[lRole], lColor, AError) then
        Exit;
      lPalette[lRole] := lColor;
    end;
    for lBinding in cNXSkinColorBindings do
    begin
      if not TryReadColor(lDefinition, lBinding.ScriptName, lColor, AError) then
        Exit;
      SetColorBinding(lPalette, lBinding, lColor);
    end;
    for lFillBinding in cNXSkinFillBindings do
    begin
      if not TryReadColor(lDefinition, lFillBinding.StartName, lStart,
        AError) then
        Exit;
      if not TryReadColor(lDefinition, lFillBinding.StopName, lStop,
        AError) then
        Exit;
      SetFillBinding(lPalette, lFillBinding, lStart, lStop);
    end;
    CopyBevelFills(lPalette);
    lPalette.Defaults.SetColor(siHighlight, lPalette[scrWidgetFrame]);
    APalette := lPalette;
    lPalette := nil;
    Result := True;
  finally
    lPalette.Free;
  end;
end;

function TNXSkin.LoadCompiledDocument(
  ADocument: TNexusScriptCompiledDocument; out AError: string): Boolean;
var
  lPalette: TNXSkinPalette;
  lRole: TNXSkinColorRole;
  lBinding: TNXSkinColorBinding;
  lFillBinding: TNXSkinFillBinding;
  lFill: TNXSkinFill;
begin
  Result := TryReadPalette(ADocument, lPalette, AError);
  if not Result then
    Exit;
  try
    for lRole := Low(TNXSkinColorRole) to High(TNXSkinColorRole) do
      FColors[lRole] := lPalette[lRole];
    // Import the flat colors and vertical gradient pairs. Keep palette/render
    // identity, fonts and unrelated state overrides intact.
    for lBinding in cNXSkinColorBindings do
      SetColorBinding(FColors, lBinding,
        lPalette.Resolve(lBinding.RenderName, lBinding.Intent, lBinding.States).Color);
    for lFillBinding in cNXSkinFillBindings do
    begin
      lFill := lPalette.Resolve(lFillBinding.RenderName, siHighlight,
        lFillBinding.States).Fill;
      SetFillBinding(FColors, lFillBinding, lFill.Color, lFill.StopColor);
    end;
    CopyBevelFills(FColors);
    FColors.Defaults.SetColor(siHighlight, lPalette.Resolve('', siHighlight).Color);
    ApplyNamedColors;
  finally
    lPalette.Free;
  end;
end;

procedure TNXSkin.DrawControlFrame(ACanvas: TfpgCanvas;
  x, y, w, h: TfpgCoord);
var
  lRect: TfpgRect;
begin
  lRect.SetRect(x, y, w, h);
  ACanvas.SetColor(FColors[scrWidgetFrame]);
  ACanvas.SetLineStyle(1, lsSolid);
  ACanvas.DrawRectangle(lRect);
end;

procedure TNXSkin.DrawBevel(ACanvas: TfpgCanvas; x, y, w, h: TfpgCoord;
  ARaised: Boolean);
var
  lRect: TfpgRect;
begin
  lRect.SetRect(x, y, w, h);
  ACanvas.SetLineStyle(1, lsSolid);
  if ARaised then
    DrawFill(ACanvas, lRect,
      FColors.Resolve(cNXBevelRender, siHighlight).Fill)
  else
    DrawFill(ACanvas, lRect,
      FColors.Resolve(cNXBevelRender, siShadow).Fill);
  ACanvas.SetColor(FColors[scrButtonBorder]);
  ACanvas.DrawRectangle(lRect);
end;

procedure TNXSkin.DrawDirectionArrow(ACanvas: TfpgCanvas;
  x, y, w, h: TfpgCoord; ADirection: TArrowDirection);
begin
  ACanvas.SetColor(clText1);
  inherited DrawDirectionArrow(ACanvas, x + 1, y, w, h, ADirection);
end;

procedure TNXSkin.DrawString(ACanvas: TfpgCanvas; x, y: TfpgCoord;
  AText: string; AEnabled: Boolean);
begin
  if AText = '' then
    Exit;
  if not AEnabled then
    ACanvas.SetTextColor(clText4)
  else if fpgIsNamedColor(ACanvas.TextColor) then
    ACanvas.SetTextColor(clText1);
  ACanvas.DrawString(x, y, AText);
end;

procedure TNXSkin.DrawFocusRect(ACanvas: TfpgCanvas; ARect: TfpgRect);
begin
  ACanvas.SetColor(FColors[scrFocus]);
  ACanvas.SetLineStyle(1, lsSolid);
  ACanvas.DrawRectangle(ARect);
end;

procedure TNXSkin.DrawButtonFace(ACanvas: TfpgCanvas;
  x, y, w, h: TfpgCoord; AFlags: TfpgButtonFlags);
var
  lRect: TfpgRect;
  lStates: TNXRenderStates;
  lAppearance: TNXSkinAppearance;
begin
  lStates := [];
  if btfDisabled in AFlags then
    Include(lStates, nrsDisabled);
  if btfIsPressed in AFlags then
    Include(lStates, nrsPressed);
  if btfHover in AFlags then
    Include(lStates, nrsHovered);
  if btfHasFocus in AFlags then
    Include(lStates, nrsFocused);
  lAppearance := FColors.Resolve(cNXButtonRender, siHighlight, lStates);
  ACanvas.SetLineStyle(1, lsSolid);
  lRect.SetRect(x + 1, y + 1, w - 2, h - 2);

  if (btfFlat in AFlags) and not (btfIsPressed in AFlags) and
    not (btfHover in AFlags) then
  begin
    ACanvas.SetColor(clWindowBackground);
    ACanvas.FillRectangle(lRect);
  end
  else
    DrawFill(ACanvas, lRect, lAppearance.Fill);

  if not (btfFlat in AFlags) and not (btfIsPressed in AFlags) then
  begin
    ACanvas.SetColor(lAppearance.Color);
    ACanvas.DrawLine(x + 2, y + 1, x + w - 2, y + 1);
  end;

  if not (btfFlat in AFlags) then
  begin
    ACanvas.SetColor(FColors[scrButtonBorder]);
    ACanvas.DrawRectangle(x, y, w, h);
  end;

  if (btfIsDefault in AFlags) and not (btfIsPressed in AFlags) then
  begin
    ACanvas.SetColor(FColors[scrFocus]);
    ACanvas.DrawRectangle(x, y, w, h);
  end;

  if (btfHasFocus in AFlags) and not (btfIsPressed in AFlags) then
  begin
    ACanvas.SetColor(FColors[scrFocus]);
    ACanvas.DrawRectangle(x + 1, y + 1, w - 2, h - 2);
  end;
end;

function TNXSkin.GetButtonBorders: TRect;
begin
  Result := Rect(2, 2, 2, 2);
end;

function TNXSkin.GetButtonShift: TPoint;
begin
  Result := Point(0, 0);
end;

function TNXSkin.HasButtonHoverEffect: Boolean;
begin
  Result := True;
end;

procedure TNXSkin.DrawMenuBar(ACanvas: TfpgCanvas; ARect: TfpgRect;
  ABackgroundColor: TfpgColor);
begin
  ACanvas.Clear(clWindowBackground);
  ACanvas.SetColor(FColors[scrWidgetFrame]);
  ACanvas.SetLineStyle(1, lsSolid);
  ACanvas.DrawLine(ARect.Left, ARect.Bottom, ARect.Right + 1, ARect.Bottom);
end;

procedure TNXSkin.DrawMenuRow(ACanvas: TfpgCanvas; ARect: TfpgRect;
  AFlags: TfpgMenuItemFlags);
begin
  inherited DrawMenuRow(ACanvas, ARect, AFlags);
  if (mifSelected in AFlags) and not (mifSeparator in AFlags) then
  begin
    ACanvas.SetColor(FColors[scrSelection]);
    ACanvas.FillRectangle(ARect);
  end;
end;

procedure TNXSkin.DrawMenuItemSeparator(ACanvas: TfpgCanvas;
  ARect: TfpgRect);
begin
  ACanvas.SetColor(FColors[scrMenuSeparator]);
  ACanvas.SetLineStyle(1, lsSolid);
  ACanvas.DrawLine(ARect.Left + 1, ARect.Top + 2, ARect.Right,
    ARect.Top + 2);
end;

procedure TNXSkin.DrawProgressBar(ACanvas: TfpgCanvas;
  AParams: TfpgStyleDrawProgressBar);
var
  lDiff: Integer;
  lFill: TfpgRect;
  lPercent: Integer;
  lPosition: Integer;
  lRect: TfpgRect;
  lText: string;
  lX: TfpgCoord;
  lY: TfpgCoord;
  lAppearance: TNXSkinAppearance;
begin
  lRect := AParams.Rect;
  lDiff := AParams.Max - AParams.Min;
  lPosition := AParams.Position - AParams.Min;
  lPercent := Round((100 / lDiff) * lPosition);
  lPosition := Round(lPercent * (lRect.Width - 2) / 100);

  ACanvas.SetColor(FColors[scrProgressTrack]);
  ACanvas.FillRectangle(lRect);
  ACanvas.SetColor(FColors[scrWidgetFrame]);
  ACanvas.SetLineStyle(1, lsSolid);
  ACanvas.DrawRectangle(lRect);

  if AParams.Position > AParams.Min then
  begin
    lAppearance := FColors.Resolve(cNXProgressRender, siHighlight);
    lFill.SetRect(lRect.Left + 1, lRect.Top + 1, lPosition,
      lRect.Height - 2);
    DrawFill(ACanvas, lFill, lAppearance.Fill);
    // fpGUI's progress draw parameters do not include Enabled.
    ACanvas.SetColor(lAppearance.Color);
    ACanvas.DrawLine(lFill.Left, lFill.Top, lFill.Right, lFill.Top);
    ACanvas.SetColor(FColors[scrProgressBorder]);
    ACanvas.DrawRectangle(lFill);
  end;

  if AParams.ShowCaption then
  begin
    lText := IntToStr(lPercent) + '%';
    lX := lRect.Left + (lRect.Width -
      AParams.Font.GetTextWidth(lText)) div 2;
    lY := lRect.Top + (lRect.Height - AParams.Font.GetHeight) div 2;
    ACanvas.SetFont(AParams.Font);
    ACanvas.SetTextColor(AParams.TextColor);
    ACanvas.DrawString(lX, lY, lText);
  end;
end;

function TNXSkin.GetCheckBoxSize: Integer;
begin
  Result := 20;
end;

procedure TNXSkin.DrawCheckBox(ACanvas: TfpgCanvas; ARect: TfpgRect;
  AFlags: TfpgCheckBoxFlags);
var
  lX1: TfpgCoord;
  lX2: TfpgCoord;
  lX3: TfpgCoord;
  lY1: TfpgCoord;
  lY2: TfpgCoord;
  lY3: TfpgCoord;
begin
  ACanvas.SetLineStyle(1, lsSolid);
  if cbfPressed in AFlags then
    ACanvas.SetColor(FColors[scrCheckPressed])
  else
    ACanvas.SetColor(FColors[scrCheckBackground]);
  ACanvas.FillRectangle(ARect);

  if cbfHasFocus in AFlags then
    ACanvas.SetColor(FColors[scrFocus])
  else
    ACanvas.SetColor(FColors[scrCheckBorder]);
  ACanvas.DrawRectangle(ARect);

  if cbfChecked in AFlags then
  begin
    if (cbfEnabled in AFlags) and not (cbfReadOnly in AFlags) then
      ACanvas.SetColor(FColors[scrFocus])
    else
      // Read-only marks deliberately share the disabled text appearance.
      ACanvas.SetColor(FColors.Resolve(cNXTextRender, siText, [nrsDisabled]).Color);
    ACanvas.SetLineStyle(3, lsSolid);
    lX1 := ARect.Left + Round(ARect.Width * 0.22);
    lY1 := ARect.Top + Round(ARect.Height * 0.50);
    lX2 := ARect.Left + Round(ARect.Width * 0.42);
    lY2 := ARect.Top + Round(ARect.Height * 0.75);
    lX3 := ARect.Left + Round(ARect.Width * 0.70);
    lY3 := ARect.Top + Round(ARect.Height * 0.20);
    ACanvas.DrawLine(lX1, lY1, lX2, lY2);
    ACanvas.DrawLine(lX2, lY2, lX3, lY3);
    ACanvas.SetLineStyle(1, lsSolid);
  end;
end;

function TNXSkin.GetRadioButtonSize: Integer;
begin
  Result := 14;
end;

procedure TNXSkin.DrawRadioButton(ACanvas: TfpgCanvas; ARect: TfpgRect;
  AFlags: TfpgCheckBoxFlags);
var
  lCenterX: Integer;
  lCenterY: Integer;
  lRadius: Integer;
begin
  lCenterX := ARect.Left + (ARect.Width div 2);
  lCenterY := ARect.Top + (ARect.Height div 2);
  lRadius := (ARect.Width div 2) - 1;

  if cbfPressed in AFlags then
    ACanvas.SetColor(FColors[scrCheckPressed])
  else
    ACanvas.SetColor(FColors[scrCheckBackground]);
  ACanvas.FillArc(lCenterX - lRadius, lCenterY - lRadius,
    lRadius * 2, lRadius * 2, 0, 360);

  if cbfHasFocus in AFlags then
    ACanvas.SetColor(FColors[scrFocus])
  else
    ACanvas.SetColor(FColors[scrCheckBorder]);
  ACanvas.SetLineStyle(1, lsSolid);
  ACanvas.DrawArc(lCenterX - lRadius, lCenterY - lRadius,
    lRadius * 2, lRadius * 2, 0, 360);

  if cbfChecked in AFlags then
  begin
    if (cbfEnabled in AFlags) and not (cbfReadOnly in AFlags) then
      ACanvas.SetColor(FColors[scrFocus])
    else
      // Read-only marks deliberately share the disabled text appearance.
      ACanvas.SetColor(FColors.Resolve(cNXTextRender, siText, [nrsDisabled]).Color);
    ACanvas.FillArc(lCenterX - 3, lCenterY - 3, 6, 6, 0, 360);
  end;
end;

procedure TNXSkin.DrawPageControlBody(ACanvas: TfpgCanvas;
  ARect: TfpgRect);
begin
  ACanvas.SetColor(clWindowBackground);
  ACanvas.FillRectangle(ARect);
  ACanvas.SetColor(FColors[scrTabBorder]);
  ACanvas.SetLineStyle(1, lsSolid);
  ACanvas.DrawRectangle(ARect);
  ACanvas.SetColor(FColors[scrScrollBar]);
  ACanvas.DrawLine(ARect.Left, ARect.Bottom, ARect.Right + 1, ARect.Bottom);
end;

procedure TNXSkin.DrawPageControlTab(ACanvas: TfpgCanvas;
  AParams: TfpgStyleDrawTab);
var
  lActiveColor: TfpgColor;
  lRect: TfpgRect;
begin
  lRect := AParams.TabRect;
  ACanvas.SetLineStyle(1, lsSolid);

  if TfpgTabSheet(AParams.TabSheet).PageControl.ActiveTabColor = clDefault then
    lActiveColor := TfpgTabSheet(AParams.TabSheet).TabColor
  else
    lActiveColor := TfpgTabSheet(AParams.TabSheet).PageControl.ActiveTabColor;

  case AParams.TabPosition of
    tpTop:
      if AParams.IsSelected then
      begin
        ACanvas.SetColor(lActiveColor);
        ACanvas.FillRectangle(lRect.Left + 1, lRect.Top + 1,
          lRect.Width - 2, lRect.Height - 1);
        ACanvas.SetColor(FColors[scrTabBorder]);
        ACanvas.DrawLine(lRect.Left, lRect.Bottom - 1,
          lRect.Left, lRect.Top + 1);
        ACanvas.DrawLine(lRect.Left + 1, lRect.Top,
          lRect.Right - 1, lRect.Top);
        ACanvas.DrawLine(lRect.Right - 1, lRect.Top + 1,
          lRect.Right - 1, lRect.Bottom - 1);
      end
      else
      begin
        ACanvas.SetColor(FColors[scrInactiveTab]);
        ACanvas.FillRectangle(lRect.Left + 1, lRect.Top + 1,
          lRect.Width - 2, lRect.Height - 2);
        ACanvas.SetColor(FColors[scrTabBorder]);
        ACanvas.DrawLine(lRect.Left, lRect.Bottom - 1,
          lRect.Left, lRect.Top + 1);
        ACanvas.DrawLine(lRect.Left + 1, lRect.Top,
          lRect.Right - 1, lRect.Top);
        ACanvas.DrawLine(lRect.Right - 1, lRect.Top + 1,
          lRect.Right - 1, lRect.Bottom - 1);
        ACanvas.DrawLine(lRect.Left, lRect.Bottom - 1,
          lRect.Right, lRect.Bottom - 1);
      end;
    tpBottom:
      if AParams.IsSelected then
      begin
        ACanvas.SetColor(lActiveColor);
        ACanvas.FillRectangle(lRect.Left + 1, lRect.Top,
          lRect.Width - 2, lRect.Height - 1);
        ACanvas.SetColor(FColors[scrTabBorder]);
        ACanvas.DrawLine(lRect.Left, lRect.Top,
          lRect.Left, lRect.Bottom - 1);
        ACanvas.DrawLine(lRect.Left + 1, lRect.Bottom - 1,
          lRect.Right - 1, lRect.Bottom - 1);
        ACanvas.DrawLine(lRect.Right - 1, lRect.Top,
          lRect.Right - 1, lRect.Bottom - 1);
      end
      else
      begin
        ACanvas.SetColor(FColors[scrInactiveTab]);
        ACanvas.FillRectangle(lRect.Left + 1, lRect.Top + 1,
          lRect.Width - 2, lRect.Height - 2);
        ACanvas.SetColor(FColors[scrTabBorder]);
        ACanvas.DrawLine(lRect.Left, lRect.Top,
          lRect.Left, lRect.Bottom - 1);
        ACanvas.DrawLine(lRect.Left + 1, lRect.Bottom - 1,
          lRect.Right - 1, lRect.Bottom - 1);
        ACanvas.DrawLine(lRect.Right - 1, lRect.Top,
          lRect.Right - 1, lRect.Bottom - 1);
        ACanvas.DrawLine(lRect.Left, lRect.Top, lRect.Right, lRect.Top);
      end;
    tpLeft:
      if AParams.IsSelected then
      begin
        lRect.Width := lRect.Width - 1;
        lRect.Height := lRect.Height + 2;
        ACanvas.SetColor(lActiveColor);
        ACanvas.FillRectangle(lRect.Left + 1, lRect.Top + 1,
          lRect.Width - 1, lRect.Height - 2);
        ACanvas.SetColor(FColors[scrTabBorder]);
        ACanvas.DrawLine(lRect.Left, lRect.Bottom - 1,
          lRect.Left, lRect.Top + 1);
        ACanvas.DrawLine(lRect.Left + 1, lRect.Top,
          lRect.Right - 1, lRect.Top);
        ACanvas.DrawLine(lRect.Left + 1, lRect.Bottom - 1,
          lRect.Right - 1, lRect.Bottom - 1);
      end
      else
      begin
        ACanvas.SetColor(FColors[scrInactiveTab]);
        ACanvas.FillRectangle(lRect.Left + 1, lRect.Top + 1,
          lRect.Width - 2, lRect.Height - 2);
        ACanvas.SetColor(FColors[scrTabBorder]);
        ACanvas.DrawLine(lRect.Left, lRect.Bottom - 1,
          lRect.Left, lRect.Top + 1);
        ACanvas.DrawLine(lRect.Left + 1, lRect.Top,
          lRect.Right - 1, lRect.Top);
        ACanvas.DrawLine(lRect.Left + 1, lRect.Bottom - 1,
          lRect.Right - 1, lRect.Bottom - 1);
        ACanvas.DrawLine(lRect.Right - 1, lRect.Top + 1,
          lRect.Right - 1, lRect.Bottom);
      end;
    tpRight:
      if AParams.IsSelected then
      begin
        lRect.Height := lRect.Height + 2;
        ACanvas.SetColor(lActiveColor);
        ACanvas.FillRectangle(lRect.Left, lRect.Top + 1,
          lRect.Width - 1, lRect.Height - 2);
        ACanvas.SetColor(FColors[scrTabBorder]);
        ACanvas.DrawLine(lRect.Left + 1, lRect.Top,
          lRect.Right - 1, lRect.Top);
        ACanvas.DrawLine(lRect.Right - 1, lRect.Top + 1,
          lRect.Right - 1, lRect.Bottom - 1);
        ACanvas.DrawLine(lRect.Left + 1, lRect.Bottom - 1,
          lRect.Right - 1, lRect.Bottom - 1);
      end
      else
      begin
        ACanvas.SetColor(FColors[scrInactiveTab]);
        ACanvas.FillRectangle(lRect.Left + 1, lRect.Top + 1,
          lRect.Width - 2, lRect.Height - 2);
        ACanvas.SetColor(FColors[scrTabBorder]);
        ACanvas.DrawLine(lRect.Left + 1, lRect.Top,
          lRect.Right - 1, lRect.Top);
        ACanvas.DrawLine(lRect.Right - 1, lRect.Top + 1,
          lRect.Right - 1, lRect.Bottom - 1);
        ACanvas.DrawLine(lRect.Left + 1, lRect.Bottom - 1,
          lRect.Right - 1, lRect.Bottom - 1);
        ACanvas.DrawLine(lRect.Left, lRect.Top,
          lRect.Left, lRect.Bottom);
      end;
  end;
end;

initialization
  fpgStyleManager.RegisterClass('Nexus', TNXSkin);

end.

(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tsNXSkinTests;

{$mode objfpc}{$H+}

interface

uses
  obNXTestRegistry;

procedure RegisterNXSkinTests(ARegistry: TNXTestRegistry);

implementation

uses
  SysUtils,
  fpg_base,
  fpg_main,
  tpNexusScript,
  obNexusScriptModel,
  obNexusScriptSession,
  obNexusScriptValidator,
  obNXSkin,
  obNXSkinPalette,
  obNXRender,
  obNXTestContext,
  obNXTestSuite,
  tpNXSkin,
  tpNXRender;

var
  gSkinTestApplicationInitialized: Boolean = False;

procedure InitializeSkinTestApplication;
begin
  if gSkinTestApplicationInitialized then
    Exit;
  // fpGUI owns the application and releases it at DLL finalization.
  fpgApplication.Initialize;
  gSkinTestApplicationInitialized := True;
end;

function EmptyRange: TNexusScriptRange;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.SourceName := 'test.skin.nxscript';
end;

procedure AddTextProperty(ADefinition: TNexusScriptCompiledDefinition;
  const AName, AValue: string);
var
  lValue: TNexusScriptCompiledValue;
begin
  lValue := TNexusScriptCompiledValue.Create(nsvText, EmptyRange);
  lValue.EffectiveText := AValue;
  lValue.HasEffectiveText := True;
  ADefinition.Properties.Add(TNexusScriptCompiledProperty.Create(AName,
    lValue, EmptyRange));
end;

function BuildValidDocument: TNexusScriptCompiledDocument;
var
  lDefinition: TNexusScriptCompiledDefinition;
  lRole: TNXSkinColorRole;
  lBinding: TNXSkinColorBinding;
  lFillBinding: TNXSkinFillBinding;
begin
  Result := TNexusScriptCompiledDocument.Create('test.skin.nxscript', Now);
  lDefinition := TNexusScriptCompiledDefinition.Create('Skin', 'Test',
    EmptyRange);
  Result.Definitions.Add(lDefinition);
  AddTextProperty(lDefinition, 'Version', '1');
  for lRole := Low(TNXSkinColorRole) to High(TNXSkinColorRole) do
    AddTextProperty(lDefinition, cNXSkinColorNames[lRole],
      '#' + IntToHex(LongWord(cNXSkinDefaultColors[lRole]), 8));
  for lBinding in cNXSkinColorBindings do
    AddTextProperty(lDefinition, lBinding.ScriptName,
      '#' + IntToHex(LongWord(lBinding.DefaultColor), 8));
  for lFillBinding in cNXSkinFillBindings do
  begin
    AddTextProperty(lDefinition, lFillBinding.StartName,
      '#' + IntToHex(LongWord(lFillBinding.DefaultStart), 8));
    AddTextProperty(lDefinition, lFillBinding.StopName,
      '#' + IntToHex(LongWord(lFillBinding.DefaultStop), 8));
  end;
end;

function SkinFixturePath: string;
begin
  Result := ExpandFileName('fixtures\NexusDark.Skin.nxscript');
  if not FileExists(Result) then
    Result := ExpandFileName(
      'packages\nexus-packages\gui\test\fixtures\NexusDark.Skin.nxscript');
end;

function ValidationFailure(AValidator: TNexusScriptValidator): string;
begin
  if AValidator.Diagnostics.Count = 0 then
    Result := 'no diagnostic'
  else
    Result := AValidator.Diagnostics[0].Code + ': ' +
      AValidator.Diagnostics[0].MessageText;
end;

procedure TestDefaultPalette(AContext: TNXTestContext);
begin
  AContext.AssertEquals('FF31363B',
    IntToHex(LongWord(cNXSkinDefaultColors[scrWindowBackground]), 8),
    'Window background mismatch.');
  AContext.AssertEquals('FF3DAEE9',
    IntToHex(LongWord(cNXSkinDefaultColors[scrFocus]), 8),
    'Focus color mismatch.');
end;

procedure TestPaletteObjectDefaults(AContext: TNXTestContext);
var
  lPalette: TNXSkinPalette;
  lRole: TNXSkinColorRole;
begin
  lPalette := TNXSkinPalette.Create;
  try
    for lRole := Low(TNXSkinColorRole) to High(TNXSkinColorRole) do
      AContext.AssertTrue(lPalette[lRole] = cNXSkinDefaultColors[lRole],
        'Palette default mismatch: ' + cNXSkinColorNames[lRole]);
  finally
    lPalette.Free;
  end;
end;

procedure TestPaletteObjectEditsAndIsolation(AContext: TNXTestContext);
var
  lPalette, lOther: TNXSkinPalette;
  lRole: TNXSkinColorRole;
  lNamedFrame: TfpgColor;
begin
  lNamedFrame := fpgColorToRGB(clWidgetFrame);
  lPalette := TNXSkinPalette.Create;
  lOther := TNXSkinPalette.Create;
  try
    for lRole := Low(TNXSkinColorRole) to High(TNXSkinColorRole) do
      lPalette[lRole] := $FF000000 or LongWord(Ord(lRole) + 1);
    for lRole := Low(TNXSkinColorRole) to High(TNXSkinColorRole) do
    begin
      AContext.AssertTrue(lPalette[lRole] =
        ($FF000000 or LongWord(Ord(lRole) + 1)),
        'Palette edit mismatch: ' + cNXSkinColorNames[lRole]);
      AContext.AssertTrue(lOther[lRole] = cNXSkinDefaultColors[lRole],
        'Palette instances share values: ' + cNXSkinColorNames[lRole]);
    end;
    lPalette[scrFocus] := 0;
    AContext.AssertTrue(lPalette[scrFocus] = 0,
      'Zero must remain a color value, not an unset marker.');
    lPalette[scrFocus] := $FFFFFFFF;
    AContext.AssertEquals('FFFFFFFF', IntToHex(LongWord(lPalette[scrFocus]), 8),
      'Palette must preserve the complete color value.');
    AContext.AssertTrue(fpgColorToRGB(clWidgetFrame) = lNamedFrame,
      'A standalone palette must not update fpGUI named colors.');
  finally
    lOther.Free;
    lPalette.Free;
  end;
end;

procedure TestIntentDefaultsAndIsolation(AContext: TNXTestContext);
var
  lPalette, lOther: TNXSkinPalette;
  lIntent: TNXSkinIntent;
begin
  lPalette := TNXSkinPalette.Create;
  lOther := TNXSkinPalette.Create;
  try
    for lIntent := Low(TNXSkinIntent) to High(TNXSkinIntent) do
    begin
      AContext.AssertTrue(lPalette.Resolve('', lIntent).Color =
        cNXSkinDefaultIntentColors[lIntent], 'Every intent needs a default.');
      lPalette.Defaults.SetColor(lIntent, $FF000001 + LongWord(Ord(lIntent)));
      AContext.AssertTrue(lPalette.Resolve('Unknown', lIntent, [nrsHovered]).Color =
        lPalette.Resolve('', lIntent).Color, 'Unknown render must use the intent default.');
      AContext.AssertTrue(lOther.Resolve('', lIntent).Color =
        cNXSkinDefaultIntentColors[lIntent], 'Palette defaults must be independent.');
    end;
    AContext.AssertTrue(lPalette.FindRender('Unknown') = nil,
      'Resolving a color must not create a render entry.');
    lPalette.AddRender('Button').Values.SetColor(siHighlight, $FF112233);
    AContext.AssertTrue(lOther.FindRender('Button') = nil,
      'Render entries must not be shared between palettes.');
  finally
    lOther.Free;
    lPalette.Free;
  end;
end;

procedure TestRenderColorFallback(AContext: TNXTestContext);
var
  lPalette: TNXSkinPalette;
  lButton: TNXSkinRenderValues;
begin
  lPalette := TNXSkinPalette.Create;
  try
    lPalette.Defaults.SetColor(siHighlight, $FF112233);
    lPalette.Defaults.SetColor(siShadow, $FF334455);
    lButton := lPalette.AddRender('Button');
    AContext.AssertTrue(lPalette.Resolve('Button', siHighlight).Color = $FF112233,
      'Empty render entry must fall back to the global intent.');
    lButton.Values.SetColor(siHighlight, $FF445566);
    AContext.AssertTrue(lPalette.Resolve('Button', siHighlight).Color = $FF445566,
      'Render override must precede the global intent.');
    AContext.AssertTrue(lPalette.Resolve('Button', siShadow).Color = $FF334455,
      'A render override for another intent must not stop fallback.');
    AContext.AssertTrue(lPalette.Resolve('PanelFrame', siHighlight).Color = $FF112233,
      'Render override must not affect another render.');
    lButton.Values.SetColor(siHighlight, 0);
    AContext.AssertTrue(lPalette.Resolve('Button', siHighlight).Color = 0,
      'Zero is an explicit override, not a missing color.');
    lButton.Values.Clear(siHighlight, [saColor]);
    lPalette.Defaults.SetColor(siHighlight, $FF778899);
    AContext.AssertTrue(lPalette.Resolve('Button', siHighlight).Color = $FF778899,
      'Removing an override must reveal the current global default.');
  finally
    lPalette.Free;
  end;
end;

procedure TestStateColorFallback(AContext: TNXTestContext);
var
  lPalette: TNXSkinPalette;
  lButton: TNXSkinRenderValues;
begin
  lPalette := TNXSkinPalette.Create;
  try
    lPalette.Defaults.SetColor(siHighlight, $FF112233);
    lPalette.Defaults.SetColor(siShadow, $FF223344);
    lButton := lPalette.AddRender('Button');
    lButton.Values.SetColor(siHighlight, $FF445566);
    lButton.States[nrsHovered].SetColor(siHighlight, $FF778899);
    lButton.States[nrsDisabled].SetColor(siHighlight, $FFAABBCC);
    AContext.AssertTrue(lPalette.Resolve('Button', siHighlight, [nrsHovered]).Color = $FF778899,
      'Hovered override must precede the render override.');
    AContext.AssertTrue(lPalette.Resolve('Button', siHighlight, [nrsDisabled]).Color = $FFAABBCC,
      'Disabled override must be independent of the hovered override.');
    AContext.AssertTrue(lPalette.Resolve('Button', siHighlight).Color = $FF445566,
      'A request without state must not use a state-specific override.');
    AContext.AssertTrue(lPalette.Resolve('Button', siShadow, [nrsHovered]).Color = $FF223344,
      'Missing state/render intent must fall through both levels.');
    lButton.Values.SetColor(siShadow, $FF556677);
    AContext.AssertTrue(lPalette.Resolve('Button', siShadow, [nrsHovered]).Color = $FF556677,
      'A state override for another intent must not hide the render color.');
    lButton.States[nrsHovered].Clear(siHighlight, [saColor]);
    AContext.AssertTrue(lPalette.Resolve('Button', siHighlight, [nrsHovered]).Color = $FF445566,
      'Missing hovered override must fall back to the render.');
    lButton.Values.Clear(siHighlight, [saColor]);
    AContext.AssertTrue(lPalette.Resolve('Button', siHighlight, [nrsHovered]).Color = $FF112233,
      'Missing hovered and render overrides must fall back to the global intent.');
    AContext.AssertTrue(lPalette.Resolve('Button', siHighlight, [nrsDisabled]).Color = $FFAABBCC,
      'Fallback must not consume the unrequested state override.');
  finally
    lPalette.Free;
  end;
end;

procedure TestStatePrecedence(AContext: TNXTestContext);
var
  lPalette: TNXSkinPalette;
  lButton: TNXSkinRenderValues;
  lState: TNXRenderState;
  lActive, lDefined: TNXRenderStates;
  lActiveMask, lDefinedMask, lBasePass: Integer;
  lExpected, lBase: TfpgColor;
begin
  lPalette := TNXSkinPalette.Create;
  try
    lPalette.Defaults.SetColor(siHighlight, $FF111111);
    lButton := lPalette.AddRender('Button');
    for lBasePass := 0 to 1 do
    begin
      lBase := $FF111111;
      if lBasePass = 1 then
      begin
        lBase := $FF222222;
        lButton.Values.SetColor(siHighlight, lBase);
      end;
      for lDefinedMask := 0 to 31 do
      begin
        lDefined := [];
        for lState := Low(TNXRenderState) to High(TNXRenderState) do
          if (lDefinedMask and (1 shl Ord(lState))) <> 0 then
          begin
            Include(lDefined, lState);
            lButton.States[lState].SetColor(siHighlight, $FF000010 + LongWord(Ord(lState)));
          end
          else
            lButton.States[lState].Clear(siHighlight, [saColor]);
        for lActiveMask := 0 to 31 do
        begin
          lActive := [];
          for lState := Low(TNXRenderState) to High(TNXRenderState) do
            if (lActiveMask and (1 shl Ord(lState))) <> 0 then
              Include(lActive, lState);
          lExpected := lBase;
          if nrsDisabled in lActive then
          begin
            if nrsDisabled in lDefined then
              lExpected := $FF000010
            else if (nrsSelected in lActive) and (nrsSelected in lDefined) then
              lExpected := $FF000014;
          end
          else if (nrsPressed in lActive) and (nrsPressed in lDefined) then
            lExpected := $FF000011
          else if (nrsHovered in lActive) and (nrsHovered in lDefined) then
            lExpected := $FF000012
          else if (nrsSelected in lActive) and (nrsSelected in lDefined) then
            lExpected := $FF000014
          else if (nrsFocused in lActive) and (nrsFocused in lDefined) then
            lExpected := $FF000013;
          AContext.AssertTrue(lPalette.Resolve('Button', siHighlight, lActive).Color = lExpected,
            Format('Wrong state precedence: active=%d, defined=%d, base=%d.',
              [lActiveMask, lDefinedMask, lBasePass]));
        end;
      end;
    end;
  finally
    lPalette.Free;
  end;
end;

procedure TestRenderStateFlags(AContext: TNXTestContext);
var
  lState: TNexusControlState;
begin
  lState := TNexusControlState.Create;
  try
    AContext.AssertTrue(lState.States = [], 'New render state must be normal.');
    AContext.AssertTrue(not lState.Disabled and not lState.Pressed and
      not lState.Hovered and not lState.Focused and not lState.Selected,
      'Normal must expose no abnormal flags.');
    lState.States := [nrsHovered, nrsFocused, nrsSelected];
    AContext.AssertTrue(lState.Hovered and lState.Focused and lState.Selected and
      not lState.Pressed and not lState.Disabled, 'Boolean views must reflect the state set.');
    lState.States := [nrsDisabled, nrsPressed];
    AContext.AssertTrue(lState.Disabled and lState.Pressed and
      not lState.Hovered and not lState.Focused and not lState.Selected,
      'Replacing the set must not retain old flags.');
  finally
    lState.Free;
  end;
end;

procedure TestAppearanceFallback(AContext: TNXTestContext);
var
  lPalette, lOther: TNXSkinPalette;
  lRender: TNXSkinRenderValues;
  lValue, lSnapshot: TNXSkinAppearance;
begin
  lPalette := TNXSkinPalette.Create;
  lOther := TNXSkinPalette.Create;
  try
    lPalette.Defaults.SetColor(siText, $FF123456);
    lPalette.Defaults.SetFont(siText, 'Arial-10');
    lRender := lPalette.AddRender('Text');
    lRender.Values.SetFont(siText, 'Arial-12');
    lRender.States[nrsSelected].SetFont(siText, 'Arial-12:bold');
    lRender.States[nrsDisabled].SetColor(siText, 0);
    lRender.States[nrsHovered].SetFont(siText, 'Arial-16');
    lValue := lPalette.Resolve('Text', siText, [nrsDisabled, nrsSelected, nrsHovered]);
    AContext.AssertTrue(lValue.Color = 0, 'Disabled color must win, including zero.');
    AContext.AssertEquals('Arial-12:bold', lValue.FontDesc,
      'Selected font must survive Disabled, without using Hovered.');
    lSnapshot := lValue;
    lValue.FontDesc := 'local edit';
    AContext.AssertEquals('Arial-12:bold', lSnapshot.FontDesc,
      'Returned values must be independent snapshots.');

    lRender.States[nrsSelected].Clear(siText, [saFont]);
    lValue := lPalette.Resolve('Text', siText, [nrsDisabled, nrsSelected, nrsHovered]);
    AContext.AssertEquals('Arial-12', lValue.FontDesc, 'Missing state font must use render font.');
    lRender.Values.Clear(siText, [saFont]);
    lValue := lPalette.Resolve('Text', siText, [nrsDisabled]);
    AContext.AssertEquals('Arial-10', lValue.FontDesc, 'Missing render font must use global font.');
    AContext.AssertTrue(lValue.Color = 0, 'Font fallback must not replace resolved color.');

    lRender.States[nrsDisabled].SetFont(siText, '');
    lValue := lPalette.Resolve('Text', siText, [nrsDisabled]);
    AContext.AssertEquals('', lValue.FontDesc, 'Empty font is explicit, not missing.');
    lRender.States[nrsDisabled].Clear(siText, [saColor]);
    lValue := lPalette.Resolve('Text', siText, [nrsDisabled]);
    AContext.AssertTrue(lValue.Color = $FF123456, 'Cleared color must fall back independently.');
    AContext.AssertEquals('', lValue.FontDesc, 'Clearing color must not clear font.');
    lValue := lOther.Resolve('Text', siText, [nrsDisabled, nrsSelected]);
    AContext.AssertTrue(lValue.Color = cNXSkinDefaultIntentColors[siText],
      'Palettes must not share appearance entries.');
    AContext.AssertEquals(cNXSkinDefaultFont, lValue.FontDesc, 'Global font isolation failed.');

    lPalette.RemoveRender('Text');
    lValue := lPalette.Resolve('Text', siText, [nrsSelected]);
    AContext.AssertEquals('Arial-10', lValue.FontDesc, 'Removed render must use global font.');
    lPalette.Defaults.Clear(siText, [saColor, saFont]);
    lValue := lPalette.Resolve('Text', siText);
    AContext.AssertEquals(cNXSkinDefaultFont, lValue.FontDesc, 'Cleared global font must use built-in default.');
    AContext.AssertTrue(lValue.Color = cNXSkinDefaultIntentColors[siText],
      'Cleared global color must use built-in default.');
  finally
    lOther.Free;
    lPalette.Free;
  end;
  AContext.AssertEquals('Arial-12:bold', lSnapshot.FontDesc,
    'Snapshot must survive palette and render destruction.');
end;

procedure TestFillFallback(AContext: TNXTestContext);
var
  lPalette: TNXSkinPalette;
  lButton: TNXSkinRenderValues;
  lFill: TNXSkinFill;
  lValue: TNXSkinAppearance;
begin
  lPalette := TNXSkinPalette.Create;
  try
    lValue := lPalette.Resolve('Button', siHighlight);
    AContext.AssertTrue((lValue.Fill.Kind = sfSolid) and
      (lValue.Fill.Color = cNXSkinDefaultIntentColors[siHighlight]),
      'Absent Fill must resolve to a solid built-in default.');
    lFill := Default(TNXSkinFill);
    lFill.Kind := sfGradient;
    lFill.Color := $FF102030;
    lFill.StopColor := $FF405060;
    lFill.Direction := gdHorizontal;
    lPalette.Defaults.SetFill(siHighlight, lFill);
    lButton := lPalette.AddRender('Button');
    lValue := lPalette.Resolve('Button', siHighlight, [nrsHovered]);
    AContext.AssertTrue((lValue.Fill.Color = $FF102030) and
      (lValue.Fill.StopColor = $FF405060) and
      (lValue.Fill.Direction = gdHorizontal),
      'Missing render Fill must fall back as a complete value.');
    lFill.Kind := sfSolid;
    lFill.Color := 0;
    lButton.Values.SetFill(siHighlight, lFill);
    lValue := lPalette.Resolve('Button', siHighlight, [nrsHovered]);
    AContext.AssertTrue((lValue.Fill.Kind = sfSolid) and (lValue.Fill.Color = 0),
      'Solid zero must replace the inherited gradient.');
    lFill.Kind := sfGradient;
    lFill.Color := $FF112233;
    lFill.StopColor := $FF445566;
    lButton.States[nrsHovered].SetFill(siHighlight, lFill);
    lValue := lPalette.Resolve('Button', siHighlight, [nrsHovered]);
    AContext.AssertTrue((lValue.Fill.Color = $FF112233) and
      (lValue.Fill.StopColor = $FF445566),
      'Hovered gradient must replace the entire render Fill.');
    lValue := lPalette.Resolve('Button', siHighlight,
      [nrsDisabled, nrsHovered]);
    AContext.AssertTrue((lValue.Fill.Kind = sfSolid) and (lValue.Fill.Color = 0),
      'Disabled must suppress Hovered Fill.');
    lButton.States[nrsHovered].Clear(siHighlight, [saFill]);
    lValue := lPalette.Resolve('Button', siHighlight, [nrsHovered]);
    AContext.AssertTrue((lValue.Fill.Kind = sfSolid) and (lValue.Fill.Color = 0),
      'Clearing state Fill must reveal the complete render Fill.');
    lButton.Values.Clear(siHighlight, [saFill]);
    lValue := lPalette.Resolve('Button', siHighlight, [nrsHovered]);
    AContext.AssertTrue((lValue.Fill.Color = $FF102030) and
      (lValue.Fill.StopColor = $FF405060),
      'Clearing render Fill must reveal the complete global Fill.');
    AContext.AssertTrue(lValue.Color = cNXSkinDefaultIntentColors[siHighlight],
      'Fill overrides must not replace the independent Color value.');
  finally
    lPalette.Free;
  end;
end;

procedure TestAppearancePrecedence(AContext: TNXTestContext);
const
  cStateCount = Ord(High(TNXRenderState)) + 1;
  cMaskMax = (1 shl cStateCount) - 1;
var
  lPalette: TNXSkinPalette;
  lRender: TNXSkinRenderValues;
  lState: TNXRenderState;
  lActive, lColorDefined, lFontDefined: TNXRenderStates;
  lActiveMask, lColorMask, lFontMask: Integer;
  lValue: TNXSkinAppearance;

  function Winner(ADefined: TNXRenderStates): Integer;
  begin
    Result := -1;
    if nrsDisabled in lActive then
    begin
      if nrsDisabled in ADefined then
        Result := Ord(nrsDisabled)
      else if (nrsSelected in lActive) and (nrsSelected in ADefined) then
        Result := Ord(nrsSelected);
    end
    else if (nrsPressed in lActive) and (nrsPressed in ADefined) then
      Result := Ord(nrsPressed)
    else if (nrsHovered in lActive) and (nrsHovered in ADefined) then
      Result := Ord(nrsHovered)
    else if (nrsSelected in lActive) and (nrsSelected in ADefined) then
      Result := Ord(nrsSelected)
    else if (nrsFocused in lActive) and (nrsFocused in ADefined) then
      Result := Ord(nrsFocused);
  end;

begin
  lPalette := TNXSkinPalette.Create;
  try
    lPalette.Defaults.SetColor(siText, 99);
    lPalette.Defaults.SetFont(siText, 'font-1');
    lRender := lPalette.AddRender('Text');
    for lColorMask := 0 to cMaskMax do
      for lFontMask := 0 to cMaskMax do
      begin
        lColorDefined := [];
        lFontDefined := [];
        for lState := Low(TNXRenderState) to High(TNXRenderState) do
        begin
          lRender.States[lState].Clear(siText, [saColor, saFont]);
          if (lColorMask and (1 shl Ord(lState))) <> 0 then
          begin
            Include(lColorDefined, lState);
            lRender.States[lState].SetColor(siText, 100 + Ord(lState));
          end;
          if (lFontMask and (1 shl Ord(lState))) <> 0 then
          begin
            Include(lFontDefined, lState);
            lRender.States[lState].SetFont(siText, 'font' + IntToStr(Ord(lState)));
          end;
        end;
        for lActiveMask := 0 to cMaskMax do
        begin
          lActive := [];
          for lState := Low(TNXRenderState) to High(TNXRenderState) do
            if (lActiveMask and (1 shl Ord(lState))) <> 0 then
              Include(lActive, lState);
          lValue := lPalette.Resolve('Text', siText, lActive);
          AContext.AssertTrue(lValue.Color = TfpgColor(100 + Winner(lColorDefined)),
            Format('Color precedence: active=%d, color=%d, font=%d.', [lActiveMask, lColorMask, lFontMask]));
          AContext.AssertEquals('font' + IntToStr(Winner(lFontDefined)), lValue.FontDesc,
            Format('Font precedence: active=%d, color=%d, font=%d.', [lActiveMask, lColorMask, lFontMask]));
        end;
      end;
  finally
    lPalette.Free;
  end;
end;

procedure TestStateOnlyColors(AContext: TNXTestContext);
var
  lPalette: TNXSkinPalette;
  lButton: TNXSkinRenderValues;
begin
  lPalette := TNXSkinPalette.Create;
  try
    lPalette.Defaults.SetColor(siHighlight, $FF123456);
    lButton := lPalette.AddRender('Button');
    AContext.AssertTrue(not (saColor in lButton.States[nrsHovered].Defined[siHighlight]),
      'New state overrides must be absent.');
    lButton.States[nrsHovered].SetColor(siHighlight, 0);
    AContext.AssertTrue(saColor in lButton.States[nrsHovered].Defined[siHighlight],
      'Explicit zero must be present.');
    AContext.AssertTrue(lPalette.Resolve('Button', siHighlight, [nrsHovered]).Color = 0,
      'A state override must work without a render-level override.');
    AContext.AssertTrue(lPalette.Resolve('Button', siHighlight, [nrsDisabled]).Color = $FF123456,
      'Disabled must not use the hovered override.');
    lButton.States[nrsHovered].SetColor(siHighlight, $FFFFFFFF);
    AContext.AssertTrue(lPalette.Resolve('Button', siHighlight, [nrsHovered]).Color = $FFFFFFFF,
      'A state override must retain all 32 color bits.');
    lButton.States[nrsHovered].Clear(siHighlight, [saColor]);
    AContext.AssertTrue(not (saColor in lButton.States[nrsHovered].Defined[siHighlight]),
      'Clearing must remove presence, not just change the stored color.');
    lPalette.Defaults.SetColor(siHighlight, 0);
    AContext.AssertTrue(lPalette.Resolve('Button', siHighlight, [nrsHovered]).Color = 0,
      'Zero must also be a valid global default.');
  finally
    lPalette.Free;
  end;
end;

procedure TestRenderColorNamesAndRemoval(AContext: TNXTestContext);
var
  lPalette: TNXSkinPalette;
  lButton: TNXSkinRenderValues;
  lRejected: Boolean;
begin
  lPalette := TNXSkinPalette.Create;
  try
    lButton := lPalette.AddRender('Button');
    lButton.Values.SetColor(siHighlight, $FF123456);
    AContext.AssertTrue(lPalette.FindRender('Button') = lButton,
      'Lookup must retain the owned render object identity.');
    AContext.AssertTrue(lPalette.FindRender('button') = nil,
      'Render color names must match the case-sensitive renderer registry.');
    lPalette.AddRender('button').Values.SetColor(siHighlight, $FFABCDEF);
    AContext.AssertTrue(lPalette.Resolve('Button', siHighlight).Color = $FF123456,
      'Case-distinct render names must not share overrides.');
    AContext.AssertTrue(lPalette.Resolve('button', siHighlight).Color = $FFABCDEF,
      'Lookup must use the exact render name.');
    lRejected := False;
    try
      lPalette.AddRender('Button');
    except
      on lException: Exception do
        lRejected := Pos('already defined', lException.Message) > 0;
    end;
    AContext.AssertTrue(lRejected, 'Duplicate render entries must be rejected.');
    lRejected := False;
    try
      lPalette.AddRender('');
    except
      on lException: Exception do
        lRejected := Pos('require a name', lException.Message) > 0;
    end;
    AContext.AssertTrue(lRejected, 'Empty render names must be rejected.');
    lPalette.RemoveRender('Button');
    AContext.AssertTrue(lPalette.FindRender('Button') = nil,
      'Removing a render entry must remove its lookup.');
    AContext.AssertTrue(lPalette.Resolve('Button', siHighlight, [nrsHovered]).Color =
      lPalette.Resolve('', siHighlight).Color, 'Removed render must use the global default.');
    lPalette.RemoveRender('Button');
    lButton := lPalette.AddRender('Button');
    AContext.AssertTrue(lPalette.Resolve('Button', siHighlight).Color =
      lPalette.Resolve('', siHighlight).Color, 'Recreated render must not retain overrides.');
  finally
    lPalette.Free;
  end;
end;

procedure TestSkinOwnsPalette(AContext: TNXTestContext);
var
  lSkin, lOther: TNXSkin;
begin
  InitializeSkinTestApplication;
  lSkin := TNXSkin.Create;
  lOther := TNXSkin.Create;
  try
    AContext.AssertTrue(lSkin.Colors <> nil, 'Skin must own a palette.');
    AContext.AssertTrue(lSkin.Colors <> lOther.Colors,
      'Each skin must own its own palette.');
    lSkin.Colors[scrWidgetFrame] := $FF123456;
    lSkin.Colors.Defaults.SetColor(siHighlight, $FF123456);
    AContext.AssertTrue(lOther.Colors[scrWidgetFrame] =
      cNXSkinDefaultColors[scrWidgetFrame], 'Skin palettes must be independent.');
    AContext.AssertTrue(fpgColorToRGB(clWidgetFrame) =
      cNXSkinDefaultColors[scrWidgetFrame],
      'Editing palette data must not implicitly apply named colors.');
    lSkin.ApplyNamedColors;
    AContext.AssertEquals('FF123456',
      IntToHex(LongWord(fpgColorToRGB(clWidgetFrame)), 8),
      'Applying the palette must update fpGUI named colors.');
    AContext.AssertEquals('FF123456',
      IntToHex(LongWord(fpgColorToRGB(clHilite2)), 8),
      'Panel highlight must use the applied palette.');
  finally
    lOther.ApplyNamedColors;
    lOther.Free;
    lSkin.Free;
  end;
end;

procedure TestLoadUpdatesOwnedPalette(AContext: TNXTestContext);
var
  lSkin: TNXSkin;
  lPalette: TNXSkinPalette;
  lDocument: TNexusScriptCompiledDocument;
  lError: string;
  lRole: TNXSkinColorRole;
begin
  InitializeSkinTestApplication;
  lSkin := TNXSkin.Create;
  lDocument := BuildValidDocument;
  try
    lPalette := lSkin.Colors;
    for lRole := Low(TNXSkinColorRole) to High(TNXSkinColorRole) do
      lPalette[lRole] := 0;
    AContext.AssertTrue(lSkin.LoadCompiledDocument(lDocument, lError), lError);
    AContext.AssertTrue(lSkin.Colors = lPalette,
      'Loading must update the owned palette, not replace its identity.');
    for lRole := Low(TNXSkinColorRole) to High(TNXSkinColorRole) do
      AContext.AssertTrue(lPalette[lRole] = cNXSkinDefaultColors[lRole],
        'Loaded palette mismatch: ' + cNXSkinColorNames[lRole]);
    AContext.AssertTrue(fpgColorToRGB(clWidgetFrame) = lPalette[scrWidgetFrame],
      'The existing loader must still apply named colors.');
  finally
    lDocument.Free;
    lSkin.Free;
  end;
end;

procedure TestInvalidLoadPreservesPalette(AContext: TNXTestContext);
var
  lSkin: TNXSkin;
  lPalette: TNXSkinPalette;
  lDocument: TNexusScriptCompiledDocument;
  lError: string;
  lRole: TNXSkinColorRole;
begin
  InitializeSkinTestApplication;
  lSkin := TNXSkin.Create;
  lDocument := BuildValidDocument;
  try
    lPalette := lSkin.Colors;
    for lRole := Low(TNXSkinColorRole) to High(TNXSkinColorRole) do
      lPalette[lRole] := $FF123456;
    lSkin.ApplyNamedColors;
    lDocument.Definitions[0].FindProperty('TabBorder').Value.EffectiveText := 'invalid';
    AContext.AssertTrue(not lSkin.LoadCompiledDocument(lDocument, lError),
      'Malformed input must be rejected.');
    AContext.AssertTrue(lSkin.Colors = lPalette, 'Failed load replaced the palette.');
    for lRole := Low(TNXSkinColorRole) to High(TNXSkinColorRole) do
      AContext.AssertTrue(lPalette[lRole] = $FF123456,
        'Failed load changed palette role: ' + cNXSkinColorNames[lRole]);
    AContext.AssertEquals('FF123456',
      IntToHex(LongWord(fpgColorToRGB(clWidgetFrame)), 8),
      'Failed load must not apply partial named colors.');
  finally
    for lRole := Low(TNXSkinColorRole) to High(TNXSkinColorRole) do
      lSkin.Colors[lRole] := cNXSkinDefaultColors[lRole];
    lSkin.ApplyNamedColors;
    lDocument.Free;
    lSkin.Free;
  end;
end;

procedure TestLoadedAppearance(AContext: TNXTestContext);
var
  lSkin: TNXSkin;
  lDocument: TNexusScriptCompiledDocument;
  lButton: TNXSkinRenderValues;
  lError: string;
begin
  InitializeSkinTestApplication;
  lSkin := TNXSkin.Create;
  lDocument := BuildValidDocument;
  try
    AContext.AssertTrue(lSkin.Colors.Resolve('PanelFrame', siHighlight, [nrsHovered]).Color =
      cNXSkinDefaultColors[scrWidgetFrame], 'Panel highlight must retain its original default.');
    AContext.AssertTrue(lSkin.Colors.Resolve('PanelFrame', siShadow, [nrsDisabled]).Color =
      $FF1E1E1E, 'Panel shadow must retain its original default.');
    AContext.AssertTrue(lSkin.Colors.Resolve(cNXButtonRender, siHighlight, [nrsHovered]).Color =
      $FF505860, 'Button highlight must retain its original color.');
    AContext.AssertTrue(lSkin.Colors.Resolve(cNXProgressRender, siHighlight).Color =
      $FF5BBEF0, 'Progress highlight must retain its original color.');
    lButton := lSkin.Colors.FindRender(cNXButtonRender);
    lButton.States[nrsHovered].SetColor(siHighlight, $FF987654);
    lSkin.Colors.Defaults.SetFont(siText, 'Arial-10');
    lButton.States[nrsSelected].SetFont(siText, 'Arial-12:bold');
    lDocument.Definitions[0].FindProperty('WidgetFrame').Value.EffectiveText := '#FF112233';
    lDocument.Definitions[0].FindProperty('DarkShadow').Value.EffectiveText := '#FF223344';
    lDocument.Definitions[0].FindProperty('ButtonHighlight').Value.EffectiveText := '#FF334455';
    lDocument.Definitions[0].FindProperty('ProgressHighlight').Value.EffectiveText := '#FF445566';
    AContext.AssertTrue(lSkin.LoadCompiledDocument(lDocument, lError), lError);
    AContext.AssertTrue(lSkin.Colors.Resolve('', siHighlight).Color = $FF112233,
      'Existing script frame color must supply the global highlight.');
    AContext.AssertTrue(lSkin.Colors.Resolve('', siShadow).Color = $FF223344,
      'Existing script shadow must supply the global shadow.');
    AContext.AssertTrue(lSkin.Colors.Resolve(cNXButtonRender, siHighlight, [nrsDisabled]).Color = $FF334455,
      'Existing script button highlight must supply its render override.');
    AContext.AssertTrue(lSkin.Colors.Resolve(cNXProgressRender, siHighlight).Color = $FF445566,
      'Existing script progress highlight must supply its render override.');
    AContext.AssertTrue(lSkin.Colors.FindRender(cNXButtonRender) = lButton,
      'Loading must preserve the render-color object identity.');
    AContext.AssertTrue(lSkin.Colors.Resolve(cNXButtonRender, siHighlight, [nrsHovered]).Color = $FF987654,
      'The flat script must not erase state overrides it cannot describe.');
    AContext.AssertEquals('Arial-10', lSkin.Colors.Resolve('', siText).FontDesc,
      'The color-only script must not erase global font settings.');
    AContext.AssertEquals('Arial-12:bold',
      lSkin.Colors.Resolve(cNXButtonRender, siText, [nrsSelected]).FontDesc,
      'The color-only script must not erase state fonts.');
    AContext.AssertTrue(fpgColorToRGB(clHilite2) = $FF112233,
      'Named highlight must reflect the imported intent default.');
    AContext.AssertTrue(fpgColorToRGB(clShadow1) = $FF223344,
      'Named shadow must reflect the imported intent default.');
    lDocument.Definitions[0].FindProperty('ProgressHighlight').Value.EffectiveText := 'invalid';
    AContext.AssertTrue(not lSkin.LoadCompiledDocument(lDocument, lError),
      'Invalid script must be rejected before importing intents.');
    AContext.AssertTrue(lSkin.Colors.Resolve('', siHighlight).Color = $FF112233,
      'Invalid script changed the global intent.');
    AContext.AssertTrue(lSkin.Colors.Resolve(cNXButtonRender, siHighlight, [nrsDisabled]).Color = $FF334455,
      'Invalid script changed a render override.');
  finally
    lDocument.Free;
    lSkin.Free;
  end;
end;

procedure TestNamedIntentPublication(AContext: TNXTestContext);
var
  lSkin: TNXSkin;
  lButton: TNXSkinRenderValues;
begin
  InitializeSkinTestApplication;
  lSkin := TNXSkin.Create;
  try
    lSkin.Colors.Defaults.SetColor(siHighlight, $FF123456);
    lSkin.Colors.Defaults.SetColor(siShadow, $FF654321);
    lButton := lSkin.Colors.FindRender(cNXButtonRender);
    lButton.States[nrsHovered].SetColor(siHighlight, $FFFFFFFF);
    lSkin.ApplyNamedColors;
    AContext.AssertTrue(fpgColorToRGB(clHilite2) = $FF123456,
      'Publishing must use the global intent, not the flat frame role.');
    AContext.AssertTrue(fpgColorToRGB(clShadow1) = $FF654321,
      'Publishing must use the global shadow intent.');
    AContext.AssertTrue(lSkin.Colors.Resolve(cNXButtonRender, siHighlight, [nrsHovered]).Color = $FFFFFFFF,
      'Publishing named colors must not re-import or reset overrides.');
  finally
    lSkin.Free;
  end;
end;

procedure TestCollapsedRoleDefaults(AContext: TNXTestContext);
var
  lSkin: TNXSkin;
  lBinding: TNXSkinColorBinding;
begin
  InitializeSkinTestApplication;
  lSkin := TNXSkin.Create;
  try
    AContext.AssertTrue(Ord(High(TNXSkinColorRole)) + 1 = 16,
      'Migrated gradient stops must not remain flat roles.');
    for lBinding in cNXSkinColorBindings do
      AContext.AssertTrue(lSkin.Colors.Resolve(lBinding.RenderName,
        lBinding.Intent, lBinding.States).Color = lBinding.DefaultColor,
        'Default appearance mismatch: ' + lBinding.ScriptName);
    AContext.AssertTrue(lSkin.Colors.Resolve(cNXTextRender, siText, [nrsSelected]).Color = $FFFFFFFF,
      'Selected text must retain its original white color.');
    lSkin.Colors.Defaults.SetColor(siText, $FF102030);
    lSkin.Colors.Defaults.SetColor(siShadow, $FF203040);
    lSkin.Colors.FindRender(cNXTextRender).States[nrsDisabled].SetColor(siText, $FF304050);
    lSkin.Colors.FindRender(cNXTextRender).States[nrsSelected].SetColor(siText, $FF405060);
    lSkin.ApplyNamedColors;
    AContext.AssertTrue((fpgColorToRGB(clText1) = $FF102030) and
      (fpgColorToRGB(clMenuText) = $FF102030) and
      (fpgColorToRGB(clInactiveSelText) = $FF102030) and
      (fpgColorToRGB(clGridInactiveSelText) = $FF102030),
      'Normal and inactive text publication must use the global Text intent.');
    AContext.AssertTrue((fpgColorToRGB(clText4) = $FF304050) and
      (fpgColorToRGB(clMenuDisabled) = $FF304050),
      'Disabled text publication must use Text/Disabled.');
    AContext.AssertTrue((fpgColorToRGB(clSelectionText) = $FF405060) and
      (fpgColorToRGB(clGridSelectionText) = $FF405060),
      'Selection text publication must use Text/Selected.');
    AContext.AssertTrue((fpgColorToRGB(clShadow1) = $FF203040) and
      (fpgColorToRGB(clInactiveWgFrame) = $FF203040),
      'Shadow publication must use the global Shadow intent.');
  finally
    lSkin.Free;
  end;
end;

procedure TestCollapsedRoleLoading(AContext: TNXTestContext);
var
  lSkin: TNXSkin;
  lPalette, lRead: TNXSkinPalette;
  lText: TNXSkinRenderValues;
  lDocument: TNexusScriptCompiledDocument;
  lBinding: TNXSkinColorBinding;
  lError: string;
  lIndex, lPropertyIndex: Integer;
begin
  InitializeSkinTestApplication;
  lSkin := TNXSkin.Create;
  lDocument := BuildValidDocument;
  lRead := nil;
  try
    lPalette := lSkin.Colors;
    lText := lPalette.FindRender(cNXTextRender);
    lText.States[nrsSelected].SetFont(siText, 'Arial-12:bold');
    lText.States[nrsHovered].SetColor(siText, $FFABCDEF);
    for lIndex := Low(cNXSkinColorBindings) to High(cNXSkinColorBindings) do
      lDocument.Definitions[0].FindProperty(cNXSkinColorBindings[lIndex].ScriptName).
        Value.EffectiveText := '#' + IntToHex($FF101010 + LongWord(lIndex), 8);
    AContext.AssertTrue(lSkin.LoadCompiledDocument(lDocument, lError), lError);
    AContext.AssertTrue((lPalette = lSkin.Colors) and
      (lText = lPalette.FindRender(cNXTextRender)), 'Load replaced borrowed palette/render objects.');
    for lIndex := Low(cNXSkinColorBindings) to High(cNXSkinColorBindings) do
    begin
      lBinding := cNXSkinColorBindings[lIndex];
      AContext.AssertTrue(lPalette.Resolve(lBinding.RenderName, lBinding.Intent,
        lBinding.States).Color = $FF101010 + LongWord(lIndex),
        'Script value was not loaded into its matrix entry: ' + lBinding.ScriptName);
    end;
    AContext.AssertEquals('Arial-12:bold',
      lPalette.Resolve(cNXTextRender, siText, [nrsSelected]).FontDesc,
      'Loading color must not replace the selected font.');
    AContext.AssertTrue(lPalette.Resolve(cNXTextRender, siText, [nrsHovered]).Color = $FFABCDEF,
      'Loading must preserve states not represented by the script.');

    for lBinding in cNXSkinColorBindings do
    begin
      lDocument.Definitions[0].FindProperty(lBinding.ScriptName).Value.EffectiveText := 'invalid';
      AContext.AssertTrue(not lSkin.LoadCompiledDocument(lDocument, lError),
        'Malformed matrix input was accepted: ' + lBinding.ScriptName);
      AContext.AssertTrue(Pos(lBinding.ScriptName, lError) > 0,
        'Malformed matrix input diagnostic lost the property name.');
      for lIndex := Low(cNXSkinColorBindings) to High(cNXSkinColorBindings) do
        AContext.AssertTrue(lPalette.Resolve(cNXSkinColorBindings[lIndex].RenderName,
          cNXSkinColorBindings[lIndex].Intent, cNXSkinColorBindings[lIndex].States).Color =
          $FF101010 + LongWord(lIndex), 'Failed load partially changed the matrix.');
      AContext.AssertTrue(fpgColorToRGB(clSelectionText) = $FF101013,
        'Failed load partially published named colors.');
      lDocument.Definitions[0].FindProperty(lBinding.ScriptName).Value.EffectiveText := '#FF998877';
    end;
    // Missing matrix fields must be rejected just like remaining flat roles.
    for lBinding in cNXSkinColorBindings do
    begin
      FreeAndNil(lDocument);
      lDocument := BuildValidDocument;
      for lPropertyIndex := 0 to lDocument.Definitions[0].Properties.Count - 1 do
        if lDocument.Definitions[0].Properties[lPropertyIndex].Name = lBinding.ScriptName then
        begin
          lDocument.Definitions[0].Properties.Delete(lPropertyIndex);
          Break;
        end;
      AContext.AssertTrue(not TNXSkin.TryReadPalette(lDocument, lRead, lError),
        'Missing matrix input was accepted.');
      AContext.AssertTrue(lRead = nil, 'Failed read returned a partial palette.');
      AContext.AssertTrue(Pos(lBinding.ScriptName, lError) > 0,
        'Missing matrix input diagnostic lost the property name.');
    end;
  finally
    lRead.Free;
    lDocument.Free;
    lSkin.Free;
  end;
end;

procedure TestFillLoading(AContext: TNXTestContext);
var
  lSkin: TNXSkin;
  lPalette: TNXSkinPalette;
  lButton, lBevel: TNXSkinRenderValues;
  lDocument: TNexusScriptCompiledDocument;
  lFill: TNXSkinFill;
  lBinding: TNXSkinFillBinding;
  lError: string;
  lIndex: Integer;
begin
  InitializeSkinTestApplication;
  lSkin := TNXSkin.Create;
  lDocument := BuildValidDocument;
  try
    lPalette := lSkin.Colors;
    lButton := lPalette.FindRender(cNXButtonRender);
    lBevel := lPalette.FindRender(cNXBevelRender);
    lFill := Default(TNXSkinFill);
    lFill.Kind := sfSolid;
    lFill.Color := 0;
    lButton.States[nrsDisabled].SetFill(siHighlight, lFill);
    lButton.Values.SetFont(siHighlight, 'Arial-12');
    for lIndex := Low(cNXSkinFillBindings) to High(cNXSkinFillBindings) do
    begin
      lBinding := cNXSkinFillBindings[lIndex];
      lDocument.Definitions[0].FindProperty(lBinding.StartName).Value.EffectiveText :=
        '#' + IntToHex($FF101010 + LongWord(lIndex * 2), 8);
      lDocument.Definitions[0].FindProperty(lBinding.StopName).Value.EffectiveText :=
        '#' + IntToHex($FF101011 + LongWord(lIndex * 2), 8);
    end;
    AContext.AssertTrue(lSkin.LoadCompiledDocument(lDocument, lError), lError);
    AContext.AssertTrue((lPalette = lSkin.Colors) and
      (lButton = lPalette.FindRender(cNXButtonRender)) and
      (lBevel = lPalette.FindRender(cNXBevelRender)),
      'Loading gradient inputs replaced borrowed objects.');
    for lIndex := Low(cNXSkinFillBindings) to High(cNXSkinFillBindings) do
    begin
      lBinding := cNXSkinFillBindings[lIndex];
      lFill := lPalette.Resolve(lBinding.RenderName, siHighlight,
        lBinding.States).Fill;
      AContext.AssertTrue((lFill.Kind = sfGradient) and
        (lFill.Color = $FF101010 + LongWord(lIndex * 2)) and
        (lFill.StopColor = $FF101011 + LongWord(lIndex * 2)) and
        (lFill.Direction = gdVertical),
        'Script gradient pair did not load atomically: ' + lBinding.StartName);
    end;
    AContext.AssertTrue((lPalette.Resolve(cNXBevelRender, siHighlight).Fill.Color =
      $FF101010) and (lPalette.Resolve(cNXBevelRender, siShadow).Fill.Color =
      $FF101014), 'Bevel must use the shared normal and pressed script inputs.');
    AContext.AssertTrue(lPalette.Resolve(cNXButtonRender, siHighlight,
      [nrsDisabled, nrsHovered]).Fill.Kind = sfSolid,
      'Loading must preserve unrelated Disabled Fill.');
    AContext.AssertEquals('Arial-12',
      lPalette.Resolve(cNXButtonRender, siHighlight).FontDesc,
      'Loading gradient inputs must preserve the font.');
    lDocument.Definitions[0].FindProperty('ProgressBottom').Value.EffectiveText :=
      'invalid';
    AContext.AssertTrue(not lSkin.LoadCompiledDocument(lDocument, lError),
      'Malformed gradient stop was accepted.');
    AContext.AssertTrue(Pos('ProgressBottom', lError) > 0,
      'Malformed gradient diagnostic lost the property name.');
    AContext.AssertTrue(lPalette.Resolve(cNXButtonRender, siHighlight).Fill.Color =
      $FF101010, 'Failed load partially changed the live Fill.');
  finally
    lDocument.Free;
    lSkin.Free;
  end;
end;

procedure TestReadCompletePalette(AContext: TNXTestContext);
var
  lColors: TNXSkinPalette;
  lDocument: TNexusScriptCompiledDocument;
  lError: string;
begin
  lColors := nil;
  lDocument := BuildValidDocument;
  try
    AContext.AssertTrue(TNXSkin.TryReadPalette(lDocument, lColors, lError),
      lError);
    AContext.AssertEquals('FF2A8BC4', IntToHex(LongWord(
      lColors.Resolve(cNXProgressRender, siHighlight).Fill.StopColor), 8),
      'Progress fill stop mismatch.');
  finally
    lColors.Free;
    lDocument.Free;
  end;
end;

procedure TestCompileAndValidateFixture(AContext: TNXTestContext);
var
  lColors: TNXSkinPalette;
  lDocument: TNexusScriptCompiledDocument;
  lError: string;
  lSession: TNexusScriptCompilationSession;
  lValidator: TNexusScriptValidator;
begin
  lColors := nil;
  lSession := TNexusScriptCompilationSession.Create;
  lValidator := TNexusScriptValidator.Create;
  try
    AContext.AssertTrue(lSession.CompileFile(SkinFixturePath),
      'Skin fixture should compile: ' + lSession.LastError);
    lDocument := lSession.EntryCompiler.CompiledDocument;
    AContext.AssertTrue(lDocument.DialectDocument <> nil,
      'Skin fixture should retain its compiled dialect.');
    AContext.AssertTrue(lValidator.Validate(lDocument,
      lDocument.DialectDocument),
      'Skin fixture should satisfy its dialect: ' +
      ValidationFailure(lValidator));
    AContext.AssertTrue(TNXSkin.TryReadPalette(lDocument, lColors, lError),
      lError);
  finally
    lColors.Free;
    lValidator.Free;
    lSession.Free;
  end;
end;

procedure TestRejectMalformedColor(AContext: TNXTestContext);
var
  lColors: TNXSkinPalette;
  lDocument: TNexusScriptCompiledDocument;
  lError: string;
begin
  lColors := nil;
  lDocument := BuildValidDocument;
  try
    lDocument.Definitions[0].FindProperty('ButtonBorder').Value.EffectiveText :=
      'not-a-color';
    AContext.AssertTrue(not TNXSkin.TryReadPalette(lDocument, lColors,
      lError), 'Malformed color should fail.');
    AContext.AssertTrue(Pos('ButtonBorder', lError) > 0,
      'Malformed color error should identify the role.');
  finally
    lColors.Free;
    lDocument.Free;
  end;
end;

procedure TestRejectUnsupportedVersion(AContext: TNXTestContext);
var
  lColors: TNXSkinPalette;
  lDocument: TNexusScriptCompiledDocument;
  lError: string;
begin
  lColors := nil;
  lDocument := BuildValidDocument;
  try
    lDocument.Definitions[0].FindProperty('Version').Value.EffectiveText := '2';
    AContext.AssertTrue(not TNXSkin.TryReadPalette(lDocument, lColors,
      lError), 'Unsupported version should fail.');
    AContext.AssertTrue(Pos('Unsupported skin version', lError) > 0,
      'Unsupported version error mismatch.');
  finally
    lColors.Free;
    lDocument.Free;
  end;
end;

procedure TestRejectMissingColor(AContext: TNXTestContext);
var
  lColors: TNXSkinPalette;
  lDefinition: TNexusScriptCompiledDefinition;
  lDocument: TNexusScriptCompiledDocument;
  lError: string;
  lIndex: Integer;
begin
  lColors := nil;
  lDocument := BuildValidDocument;
  try
    lDefinition := lDocument.Definitions[0];
    for lIndex := 0 to lDefinition.Properties.Count - 1 do
      if lDefinition.Properties[lIndex].Name = 'TabBorder' then
      begin
        lDefinition.Properties.Delete(lIndex);
        Break;
      end;
    AContext.AssertTrue(not TNXSkin.TryReadPalette(lDocument, lColors,
      lError), 'Missing color should fail.');
    AContext.AssertTrue(Pos('TabBorder', lError) > 0,
      'Missing color error should identify the role.');
  finally
    lColors.Free;
    lDocument.Free;
  end;
end;

procedure RegisterNXSkinTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('NexusUI.Skin');
  lSuite.AddTest('DefaultPalette', @TestDefaultPalette);
  lSuite.AddTest('PaletteObjectDefaults', @TestPaletteObjectDefaults);
  lSuite.AddTest('PaletteObjectEditsAndIsolation', @TestPaletteObjectEditsAndIsolation);
  lSuite.AddTest('IntentDefaultsAndIsolation', @TestIntentDefaultsAndIsolation);
  lSuite.AddTest('RenderColorFallback', @TestRenderColorFallback);
  lSuite.AddTest('StateColorFallback', @TestStateColorFallback);
  lSuite.AddTest('StatePrecedence', @TestStatePrecedence);
  lSuite.AddTest('RenderStateFlags', @TestRenderStateFlags);
  lSuite.AddTest('AppearanceFallback', @TestAppearanceFallback);
  lSuite.AddTest('FillFallback', @TestFillFallback);
  lSuite.AddTest('AppearancePrecedence', @TestAppearancePrecedence);
  lSuite.AddTest('StateOnlyColors', @TestStateOnlyColors);
  lSuite.AddTest('RenderColorNamesAndRemoval', @TestRenderColorNamesAndRemoval);
  lSuite.AddTest('SkinOwnsPalette', @TestSkinOwnsPalette);
  lSuite.AddTest('LoadUpdatesOwnedPalette', @TestLoadUpdatesOwnedPalette);
  lSuite.AddTest('InvalidLoadPreservesPalette', @TestInvalidLoadPreservesPalette);
  lSuite.AddTest('LoadedAppearance', @TestLoadedAppearance);
  lSuite.AddTest('NamedIntentPublication', @TestNamedIntentPublication);
  lSuite.AddTest('CollapsedRoleDefaults', @TestCollapsedRoleDefaults);
  lSuite.AddTest('CollapsedRoleLoading', @TestCollapsedRoleLoading);
  lSuite.AddTest('FillLoading', @TestFillLoading);
  lSuite.AddTest('ReadCompletePalette', @TestReadCompletePalette);
  lSuite.AddTest('CompileAndValidateFixture', @TestCompileAndValidateFixture);
  lSuite.AddTest('RejectMalformedColor', @TestRejectMalformedColor);
  lSuite.AddTest('RejectUnsupportedVersion', @TestRejectUnsupportedVersion);
  lSuite.AddTest('RejectMissingColor', @TestRejectMissingColor);
end;

end.

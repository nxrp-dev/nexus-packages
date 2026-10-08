(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tpNXSkin;

{$mode objfpc}{$H+}

interface

uses
  fpg_base, tpNXRender;

type
  TNXSkinIntent = (siHighlight, siShadow, siText);
  TNXSkinAttribute = (saColor, saFont, saFill);
  TNXSkinAttributes = set of TNXSkinAttribute;

  TNXSkinFillKind = (sfSolid, sfGradient);
  TNXSkinFill = record
    Kind: TNXSkinFillKind;
    // Color is the solid color or the first gradient stop.
    Color: TfpgColor;
    StopColor: TfpgColor;
    Direction: TGradientDirection;
  end;

  // A value snapshot, not a reference into the palette. fpGUI owns the actual
  // font resource; FontDesc identifies the complete font passed to its manager.
  TNXSkinAppearance = record
    Color: TfpgColor;
    FontDesc: string;
    Fill: TNXSkinFill;
  end;

  // Maps the current flat script inputs directly into the appearance matrix.
  TNXSkinColorBinding = record
    ScriptName: string;
    RenderName: string;
    Intent: TNXSkinIntent;
    States: TNXRenderStates;
    DefaultColor: TfpgColor;
  end;

  TNXSkinFillBinding = record
    StartName: string;
    StopName: string;
    RenderName: string;
    States: TNXRenderStates;
    DefaultStart: TfpgColor;
    DefaultStop: TfpgColor;
  end;

  TNXSkinColorRole = (
    scrWindowBackground,
    scrInputBackground,
    scrWidgetFrame,
    scrSelection,
    scrScrollBar,
    scrGridLines,
    scrFocus,
    scrMenuSeparator,
    scrButtonBorder,
    scrProgressBorder,
    scrProgressTrack,
    scrCheckBackground,
    scrCheckBorder,
    scrCheckPressed,
    scrInactiveTab,
    scrTabBorder
  );

  TNXSkinColors = array[TNXSkinColorRole] of TfpgColor;

const
  cNXButtonRender = 'Button';
  cNXProgressRender = 'Progress';
  cNXTextRender = 'Text';
  cNXBevelRender = 'Bevel';

  cNXSkinColorBindings: array[0..5] of TNXSkinColorBinding = (
    (ScriptName: 'DarkShadow'; RenderName: ''; Intent: siShadow;
      States: []; DefaultColor: $FF1E1E1E),
    (ScriptName: 'PrimaryText'; RenderName: ''; Intent: siText;
      States: []; DefaultColor: $FFEFF0F1),
    (ScriptName: 'DisabledText'; RenderName: cNXTextRender; Intent: siText;
      States: [nrsDisabled]; DefaultColor: $FF72767B),
    (ScriptName: 'SelectionText'; RenderName: cNXTextRender; Intent: siText;
      States: [nrsSelected]; DefaultColor: $FFFFFFFF),
    (ScriptName: 'ButtonHighlight'; RenderName: cNXButtonRender; Intent: siHighlight;
      States: []; DefaultColor: $FF505860),
    (ScriptName: 'ProgressHighlight'; RenderName: cNXProgressRender; Intent: siHighlight;
      States: []; DefaultColor: $FF5BBEF0)
  );

  // The flat script still supplies paired stops; runtime appearance stores
  // each pair as one Fill value. Bevel shares the normal/pressed script inputs.
  cNXSkinFillBindings: array[0..3] of TNXSkinFillBinding = (
    (StartName: 'ButtonTop'; StopName: 'ButtonBottom';
      RenderName: cNXButtonRender; States: [];
      DefaultStart: $FF444A50; DefaultStop: $FF383E44),
    (StartName: 'ButtonHoverTop'; StopName: 'ButtonHoverBottom';
      RenderName: cNXButtonRender; States: [nrsHovered];
      DefaultStart: $FF4F5862; DefaultStop: $FF434B55),
    (StartName: 'ButtonPressedTop'; StopName: 'ButtonPressedBottom';
      RenderName: cNXButtonRender; States: [nrsPressed];
      DefaultStart: $FF2A3035; DefaultStop: $FF252B30),
    (StartName: 'ProgressTop'; StopName: 'ProgressBottom';
      RenderName: cNXProgressRender; States: [];
      DefaultStart: $FF3DAEE9; DefaultStop: $FF2A8BC4)
  );

  cNXSkinDefaultFont = '#Label1';
  cNXSkinDefaultIntentColors: array[TNXSkinIntent] of TfpgColor = (
    $FF54575B,
    $FF1E1E1E,
    $FFEFF0F1
  );

  cNXSkinColorNames: array[TNXSkinColorRole] of string = (
    'WindowBackground',
    'InputBackground',
    'WidgetFrame',
    'Selection',
    'ScrollBar',
    'GridLines',
    'Focus',
    'MenuSeparator',
    'ButtonBorder',
    'ProgressBorder',
    'ProgressTrack',
    'CheckBackground',
    'CheckBorder',
    'CheckPressed',
    'InactiveTab',
    'TabBorder'
  );

  cNXSkinDefaultColors: TNXSkinColors = (
    $FF31363B,
    $FF232629,
    $FF54575B,
    $FF3DAEE9,
    $FF3E4349,
    $FF4A4E52,
    $FF3DAEE9,
    $FF4A4E52,
    $FF5E6164,
    $FF1F7AAE,
    $FF3E4349,
    $FF232629,
    $FF5E6164,
    $FF2A3035,
    $FF272B30,
    $FF54575B
  );

implementation

end.

(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tpNXLuaCanvas;

{$mode objfpc}{$H+}

interface

type
  TNXLuaLine = procedure(AX1, AY1, AX2, AY2: Integer) of object;
  TNXLuaRectangle = procedure(AX, AY, AWidth, AHeight: Integer) of object;
  TNXLuaColor = procedure(AColor: Int64) of object;
  TNXLuaLineWidth = procedure(AWidth: Integer) of object;
  TNXLuaFont = procedure(AFontDesc: string) of object;
  TNXLuaText = procedure(AX, AY: Integer; AText: string) of object;
  TNXLuaTextWidth = function(AText: string): Integer of object;
  TNXLuaFontHeight = function: Integer of object;

implementation

end.


(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXLuaCanvas;

{$mode objfpc}{$H+}

interface

uses fpg_base, fpg_main, Lua51, Lua.Plugin, tpNXLuaCanvas;

type
  TNXLuaCanvas = class(TLuaPlugin)
  private
    FCanvas: TfpgCanvas;
    FDrawLine: TNXLuaLine;
    FDrawRectangle: TNXLuaRectangle;
    FSetColor: TNXLuaColor;
    FSetLineWidth: TNXLuaLineWidth;
    FSetFont: TNXLuaFont;
    FSetTextColor: TNXLuaColor;
    FDrawText: TNXLuaText;
    FTextWidth: TNXLuaTextWidth;
    FFontHeight: TNXLuaFontHeight;
  protected
    function RequireCanvas: TfpgCanvas;
    procedure DrawLine(AX1, AY1, AX2, AY2: Integer);
    procedure DrawRectangle(AX, AY, AWidth, AHeight: Integer);
    procedure SetColor(AColor: Int64);
    procedure SetLineWidth(AWidth: Integer);
    procedure SetFont(AFontDesc: string);
    procedure SetTextColor(AColor: Int64);
    procedure DrawText(AX, AY: Integer; AText: string);
    function TextWidth(AText: string): Integer;
    function FontHeight: Integer;
  public
    constructor Create; override;
    procedure AttachCanvas(ACanvas: TfpgCanvas);
    procedure Push(ALua: Plua_State);
    property AttachedCanvas: TfpgCanvas read FCanvas;
  published
    property Line: TNXLuaLine read FDrawLine;
    property Rectangle: TNXLuaRectangle read FDrawRectangle;
    property Color: TNXLuaColor read FSetColor;
    property LineWidth: TNXLuaLineWidth read FSetLineWidth;
    property Font: TNXLuaFont read FSetFont;
    property TextColor: TNXLuaColor read FSetTextColor;
    property Text: TNXLuaText read FDrawText;
    property MeasureText: TNXLuaTextWidth read FTextWidth;
    property MeasureHeight: TNXLuaFontHeight read FFontHeight;
  end;

implementation

uses SysUtils;

constructor TNXLuaCanvas.Create;
begin
  inherited Create;
  FDrawLine := @DrawLine;
  FDrawRectangle := @DrawRectangle;
  FSetColor := @SetColor;
  FSetLineWidth := @SetLineWidth;
  FSetFont := @SetFont;
  FSetTextColor := @SetTextColor;
  FDrawText := @DrawText;
  FTextWidth := @TextWidth;
  FFontHeight := @FontHeight;
end;

function TNXLuaCanvas.RequireCanvas: TfpgCanvas;
begin
  if FCanvas = nil then
    raise Exception.Create('Lua canvas is only available during drawing.');
  Result := FCanvas;
end;

procedure TNXLuaCanvas.AttachCanvas(ACanvas: TfpgCanvas);
begin
  FCanvas := ACanvas;
end;

procedure TNXLuaCanvas.Push(ALua: Plua_State);
begin
  PushLuaObject(ALua);
end;

procedure TNXLuaCanvas.DrawLine(AX1, AY1, AX2, AY2: Integer);
begin
  RequireCanvas.DrawLine(AX1, AY1, AX2, AY2);
end;

procedure TNXLuaCanvas.DrawRectangle(AX, AY, AWidth, AHeight: Integer);
begin
  RequireCanvas.DrawRectangle(AX, AY, AWidth, AHeight);
end;

procedure TNXLuaCanvas.SetColor(AColor: Int64);
begin
  RequireCanvas.SetColor(TfpgColor(AColor));
  FCanvas.SetLineStyle(1, lsSolid);
end;

procedure TNXLuaCanvas.SetLineWidth(AWidth: Integer);
begin
  RequireCanvas.SetLineStyle(AWidth, lsSolid);
end;

procedure TNXLuaCanvas.SetFont(AFontDesc: string);
begin
  RequireCanvas.SetFont(fpgApplication.FontManager.GetFont(AFontDesc));
end;

procedure TNXLuaCanvas.SetTextColor(AColor: Int64);
begin
  RequireCanvas.SetTextColor(TfpgColor(AColor));
end;

procedure TNXLuaCanvas.DrawText(AX, AY: Integer; AText: string);
begin
  RequireCanvas.DrawString(AX, AY, AText);
end;

function TNXLuaCanvas.TextWidth(AText: string): Integer;
begin
  Result := RequireCanvas.Font.GetTextWidth(AText);
end;

function TNXLuaCanvas.FontHeight: Integer;
begin
  Result := RequireCanvas.Font.GetHeight;
end;

end.


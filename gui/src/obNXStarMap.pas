(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXStarMap;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  Math,
  SysUtils,
  fpg_base,
  fpg_main,
  fpg_widget;

type
  TNXStarMapSystem = record
    ID: Integer;
    Name: string;
    X: Double;
    Y: Double;
    Color: TfpgColor;
    Radius: Integer;
    Visible: Boolean;
    Enabled: Boolean;
  end;

  TNXStarMapSystemArray = array of TNXStarMapSystem;

  TNXStarMapRingStyle = (
    smrsSolid,
    smrsDashed,
    smrsDotted
  );

  TNXStarMapRingCenterKind = (
    smrcMapPoint,
    smrcSystemID,
    smrcSelectedSystem
  );

  TNXStarMapRing = record
    ID: Integer;
    CenterKind: TNXStarMapRingCenterKind;
    SystemID: Integer;
    X: Double;
    Y: Double;
    Radius: Double;
    Color: TfpgColor;
    Style: TNXStarMapRingStyle;
    Visible: Boolean;
  end;

  TNXStarMapRingArray = array of TNXStarMapRing;

  TNXStarMapSystemEvent = procedure(
    ASender: TObject;
    ASystemID: Integer;
    ASystemIndex: Integer;
    const ASystem: TNXStarMapSystem
  ) of object;

  TNXStarMapMapClickEvent = procedure(
    ASender: TObject;
    ASystemID: Integer;
    ASystemIndex: Integer;
    AMapX: Double;
    AMapY: Double
  ) of object;

  TNXStarMap = class(TfpgWidget)
  private
    FAutoFitMargin: Integer;
    FHoverSystemIndex: Integer;
    FMinimumHitRadius: Integer;
    FOnEmptyClick: TNXStarMapMapClickEvent;
    FOnSystemClick: TNXStarMapSystemEvent;
    FOnSystemHover: TNXStarMapSystemEvent;
    FOnSystemSelected: TNXStarMapSystemEvent;
    FRings: TNXStarMapRingArray;
    FSelectedSystemID: Integer;
    FShowLabels: Boolean;
    FSystems: TNXStarMapSystemArray;
    FViewCenterX: Double;
    FViewCenterY: Double;
    FYPositiveUp: Boolean;
    FZoom: Double;

    procedure SetAutoFitMargin(AValue: Integer);
    procedure SetHoverSystemIndex(AValue: Integer);
    procedure SetMinimumHitRadius(AValue: Integer);
    procedure SetRings(const AValue: TNXStarMapRingArray);
    procedure SetSelectedSystemID(AValue: Integer);
    procedure SetShowLabels(AValue: Boolean);
    procedure SetSystems(const AValue: TNXStarMapSystemArray);
    procedure SetViewCenterX(AValue: Double);
    procedure SetViewCenterY(AValue: Double);
    procedure SetYPositiveUp(AValue: Boolean);
    procedure SetZoom(AValue: Double);

    function GetSelectedSystemIndex: Integer;
    function GetSystemCount: Integer;
    function GetRingCount: Integer;
    function GetSystem(AIndex: Integer): TNXStarMapSystem;
    function GetRing(AIndex: Integer): TNXStarMapRing;
    function GetMapRect: TfpgRect;

    function ResolveRingCenter(const ARing: TNXStarMapRing; out AX, AY: Double): Boolean;
    function SystemAt(const AX, AY: Integer): Integer;
    function SystemHitRadius(const ASystem: TNXStarMapSystem): Integer;

    procedure DrawRangeRing(const ARing: TNXStarMapRing);
    procedure DrawSolidRing(AX, AY, ARadius: Integer;
      const AColor: TfpgColor);
    procedure DrawDashedRing(AX, AY, ARadius: Integer;
      const AColor: TfpgColor);
    procedure DrawDottedRing(AX, AY, ARadius: Integer;
      const AColor: TfpgColor);
    procedure DrawSystem(const ASystem: TNXStarMapSystem; AIndex: Integer);
    procedure NotifySystemHover;
    procedure NotifySystemSelected;

  protected
    procedure HandleLMouseUp(AX, AY: Integer;
      AShiftState: TShiftState); override;
    procedure HandleMouseExit; override;
    procedure HandleMouseMove(AX, AY: Integer; AButtonState: Word;
      AShiftState: TShiftState); override;
    procedure HandleMouseScroll(AX, AY: Integer;
      AShiftState: TShiftState; ADelta: SmallInt); override;
    procedure HandlePaint; override;

  public
    constructor Create(AOwner: TComponent); override;

    function AddRing(const ARing: TNXStarMapRing): Integer;
    function AddSystem(const ASystem: TNXStarMapSystem): Integer;
    function ClientToMapX(AX: Integer): Double;
    function ClientToMapY(AY: Integer): Double;
    function FindSystemIndexByID(ASystemID: Integer): Integer;
    function MapToClientX(AX: Double): Integer;
    function MapToClientY(AY: Double): Integer;

    procedure AutoFit;
    procedure CenterOn(AX, AY: Double);
    procedure CenterOnSystemID(ASystemID: Integer);
    procedure ClearRings;
    procedure ClearSystems;
    procedure SetRing(AIndex: Integer; const ARing: TNXStarMapRing);
    procedure SetSystem(AIndex: Integer; const ASystem: TNXStarMapSystem);
    procedure ZoomAtClientPoint(AX, AY: Integer; AFactor: Double);

    property AutoFitMargin: Integer read FAutoFitMargin write SetAutoFitMargin;
    property HoverSystemIndex: Integer read FHoverSystemIndex;
    property MinimumHitRadius: Integer read FMinimumHitRadius
      write SetMinimumHitRadius;
    property OnEmptyClick: TNXStarMapMapClickEvent read FOnEmptyClick write FOnEmptyClick;
    property OnSystemClick: TNXStarMapSystemEvent read FOnSystemClick write FOnSystemClick;
    property OnSystemHover: TNXStarMapSystemEvent read FOnSystemHover write FOnSystemHover;
    property OnSystemSelected: TNXStarMapSystemEvent read FOnSystemSelected write FOnSystemSelected;
    property RingCount: Integer read GetRingCount;
    property Rings: TNXStarMapRingArray read FRings write SetRings;
    property SelectedSystemID: Integer read FSelectedSystemID write SetSelectedSystemID;
    property SelectedSystemIndex: Integer read GetSelectedSystemIndex;
    property ShowLabels: Boolean read FShowLabels write SetShowLabels;
    property SystemCount: Integer read GetSystemCount;
    property Systems: TNXStarMapSystemArray read FSystems write SetSystems;
    property ViewCenterX: Double read FViewCenterX write SetViewCenterX;
    property ViewCenterY: Double read FViewCenterY write SetViewCenterY;
    property YPositiveUp: Boolean read FYPositiveUp write SetYPositiveUp;
    property Zoom: Double read FZoom write SetZoom;
  end;

function MakeNXStarMapSystem(ASystemID: Integer; const AName: string;
  AX, AY: Double; const AColor: TfpgColor; ARadius: Integer): TNXStarMapSystem;
function MakeNXStarMapPointRing(ARingID: Integer; AX, AY, ARadius: Double;
  const AColor: TfpgColor; AStyle: TNXStarMapRingStyle): TNXStarMapRing;
function MakeNXStarMapSystemRing(ARingID, ASystemID: Integer; ARadius: Double;
  const AColor: TfpgColor; AStyle: TNXStarMapRingStyle): TNXStarMapRing;
function MakeNXStarMapSelectedRing(ARingID: Integer; ARadius: Double;
  const AColor: TfpgColor; AStyle: TNXStarMapRingStyle): TNXStarMapRing;

implementation

const
  cInvalidSystemID = -1;
  cDefaultHitRadius = 6;
  cDefaultZoom = 1.0;
  cMinimumZoom = 0.01;
  cMaximumZoom = 1000.0;
  cDefaultAutoFitMargin = 16;
  cFrameWidth = 2;
  cWheelZoomFactor = 1.15;

  cHoverRingColor = TfpgColor($FFFFFFFF);
  cSelectedRingColor = TfpgColor($FFFFDC40);

function MakeNXStarMapSystem(ASystemID: Integer; const AName: string;
  AX, AY: Double; const AColor: TfpgColor; ARadius: Integer): TNXStarMapSystem;
begin
  Result.ID := ASystemID;
  Result.Name := AName;
  Result.X := AX;
  Result.Y := AY;
  Result.Color := AColor;
  Result.Radius := ARadius;
  Result.Visible := True;
  Result.Enabled := True;
end;

function MakeNXStarMapPointRing(ARingID: Integer; AX, AY, ARadius: Double;
  const AColor: TfpgColor; AStyle: TNXStarMapRingStyle): TNXStarMapRing;
begin
  Result.ID := ARingID;
  Result.CenterKind := smrcMapPoint;
  Result.SystemID := cInvalidSystemID;
  Result.X := AX;
  Result.Y := AY;
  Result.Radius := ARadius;
  Result.Color := AColor;
  Result.Style := AStyle;
  Result.Visible := True;
end;

function MakeNXStarMapSystemRing(ARingID, ASystemID: Integer; ARadius: Double;
  const AColor: TfpgColor; AStyle: TNXStarMapRingStyle): TNXStarMapRing;
begin
  Result.ID := ARingID;
  Result.CenterKind := smrcSystemID;
  Result.SystemID := ASystemID;
  Result.X := 0;
  Result.Y := 0;
  Result.Radius := ARadius;
  Result.Color := AColor;
  Result.Style := AStyle;
  Result.Visible := True;
end;

function MakeNXStarMapSelectedRing(ARingID: Integer; ARadius: Double;
  const AColor: TfpgColor; AStyle: TNXStarMapRingStyle): TNXStarMapRing;
begin
  Result.ID := ARingID;
  Result.CenterKind := smrcSelectedSystem;
  Result.SystemID := cInvalidSystemID;
  Result.X := 0;
  Result.Y := 0;
  Result.Radius := ARadius;
  Result.Color := AColor;
  Result.Style := AStyle;
  Result.Visible := True;
end;

constructor TNXStarMap.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoFitMargin := cDefaultAutoFitMargin;
  FHoverSystemIndex := -1;
  FMinimumHitRadius := cDefaultHitRadius;
  FSelectedSystemID := cInvalidSystemID;
  FShowLabels := False;
  FViewCenterX := 0;
  FViewCenterY := 0;
  FYPositiveUp := False;
  FZoom := cDefaultZoom;
  BackgroundColor := clWindowBackground;
  Width := 400;
  Height := 300;
end;

procedure TNXStarMap.SetAutoFitMargin(AValue: Integer);
begin
  FAutoFitMargin := Max(0, AValue);
end;

procedure TNXStarMap.SetHoverSystemIndex(AValue: Integer);
begin
  if FHoverSystemIndex = AValue then
    Exit;

  FHoverSystemIndex := AValue;
  NotifySystemHover;
  Invalidate;
end;

procedure TNXStarMap.SetMinimumHitRadius(AValue: Integer);
begin
  FMinimumHitRadius := Max(0, AValue);
end;

procedure TNXStarMap.SetRings(const AValue: TNXStarMapRingArray);
begin
  FRings := Copy(AValue, 0, Length(AValue));
  Invalidate;
end;

procedure TNXStarMap.SetSelectedSystemID(AValue: Integer);
begin
  if FSelectedSystemID = AValue then
    Exit;

  FSelectedSystemID := AValue;
  NotifySystemSelected;
  Invalidate;
end;

procedure TNXStarMap.SetShowLabels(AValue: Boolean);
begin
  if FShowLabels = AValue then
    Exit;

  FShowLabels := AValue;
  Invalidate;
end;

procedure TNXStarMap.SetSystems(const AValue: TNXStarMapSystemArray);
begin
  FSystems := Copy(AValue, 0, Length(AValue));
  if FindSystemIndexByID(FSelectedSystemID) < 0 then
    FSelectedSystemID := cInvalidSystemID;
  if (FHoverSystemIndex < 0) or (FHoverSystemIndex > High(FSystems)) then
    FHoverSystemIndex := -1;
  Invalidate;
end;

procedure TNXStarMap.SetViewCenterX(AValue: Double);
begin
  FViewCenterX := AValue;
  Invalidate;
end;

procedure TNXStarMap.SetViewCenterY(AValue: Double);
begin
  FViewCenterY := AValue;
  Invalidate;
end;

procedure TNXStarMap.SetYPositiveUp(AValue: Boolean);
begin
  FYPositiveUp := AValue;
  Invalidate;
end;

procedure TNXStarMap.SetZoom(AValue: Double);
begin
  FZoom := EnsureRange(AValue, cMinimumZoom, cMaximumZoom);
  Invalidate;
end;

function TNXStarMap.GetSelectedSystemIndex: Integer;
begin
  Result := FindSystemIndexByID(FSelectedSystemID);
end;

function TNXStarMap.GetSystemCount: Integer;
begin
  Result := Length(FSystems);
end;

function TNXStarMap.GetRingCount: Integer;
begin
  Result := Length(FRings);
end;

function TNXStarMap.GetSystem(AIndex: Integer): TNXStarMapSystem;
begin
  if (AIndex < 0) or (AIndex > High(FSystems)) then
    raise ERangeError.Create('Star system index out of range');

  Result := FSystems[AIndex];
end;

function TNXStarMap.GetRing(AIndex: Integer): TNXStarMapRing;
begin
  if (AIndex < 0) or (AIndex > High(FRings)) then
    raise ERangeError.Create('Star map ring index out of range');

  Result := FRings[AIndex];
end;

function TNXStarMap.GetMapRect: TfpgRect;
begin
  Result.SetRect(cFrameWidth, cFrameWidth,
    Max(0, ActualWidth - (cFrameWidth * 2)),
    Max(0, ActualHeight - (cFrameWidth * 2)));
end;

function TNXStarMap.ResolveRingCenter(const ARing: TNXStarMapRing; out AX,
  AY: Double): Boolean;
var
  lSystemIndex: Integer;
begin
  Result := True;

  case ARing.CenterKind of
    smrcMapPoint:
    begin
      AX := ARing.X;
      AY := ARing.Y;
    end;

    smrcSystemID:
    begin
      lSystemIndex := FindSystemIndexByID(ARing.SystemID);
      Result := lSystemIndex >= 0;
      if Result then
      begin
        AX := FSystems[lSystemIndex].X;
        AY := FSystems[lSystemIndex].Y;
      end;
    end;

    smrcSelectedSystem:
    begin
      lSystemIndex := SelectedSystemIndex;
      Result := lSystemIndex >= 0;
      if Result then
      begin
        AX := FSystems[lSystemIndex].X;
        AY := FSystems[lSystemIndex].Y;
      end;
    end;
  else
    Result := False;
  end;
end;

function TNXStarMap.SystemAt(const AX, AY: Integer): Integer;
var
  lDistanceSquared: Integer;
  lHitRadius: Integer;
  lIndex: Integer;
  lScreenX: Integer;
  lScreenY: Integer;
begin
  Result := -1;

  for lIndex := High(FSystems) downto 0 do
  begin
    if (not FSystems[lIndex].Visible) or (not FSystems[lIndex].Enabled) then
      Continue;

    lScreenX := MapToClientX(FSystems[lIndex].X);
    lScreenY := MapToClientY(FSystems[lIndex].Y);
    lHitRadius := SystemHitRadius(FSystems[lIndex]);
    lDistanceSquared := Sqr(AX - lScreenX) + Sqr(AY - lScreenY);

    if lDistanceSquared <= Sqr(lHitRadius) then
    begin
      Result := lIndex;
      Exit;
    end;
  end;
end;

function TNXStarMap.SystemHitRadius(const ASystem: TNXStarMapSystem): Integer;
begin
  Result := Max(ASystem.Radius, FMinimumHitRadius);
end;

procedure TNXStarMap.DrawRangeRing(const ARing: TNXStarMapRing);
var
  lMapX: Double;
  lMapY: Double;
  lRadius: Integer;
  lScreenX: Integer;
  lScreenY: Integer;
begin
  if (not ARing.Visible) or (ARing.Radius <= 0) then
    Exit;

  if not ResolveRingCenter(ARing, lMapX, lMapY) then
    Exit;

  lScreenX := MapToClientX(lMapX);
  lScreenY := MapToClientY(lMapY);
  lRadius := Round(ARing.Radius * FZoom);

  if lRadius <= 0 then
    Exit;

  case ARing.Style of
    smrsDashed:
      DrawDashedRing(lScreenX, lScreenY, lRadius, ARing.Color);
    smrsDotted:
      DrawDottedRing(lScreenX, lScreenY, lRadius, ARing.Color);
  else
    DrawSolidRing(lScreenX, lScreenY, lRadius, ARing.Color);
  end;
end;

procedure TNXStarMap.DrawSolidRing(AX, AY, ARadius: Integer;
  const AColor: TfpgColor);
begin
  Canvas.SetColor(AColor);
  Canvas.DrawArc(AX - ARadius, AY - ARadius, ARadius * 2,
    ARadius * 2, 0, 360);
end;

procedure TNXStarMap.DrawDashedRing(AX, AY, ARadius: Integer;
  const AColor: TfpgColor);
var
  lAngle: Double;
  lEndAngle: Double;
  lSegment: Integer;
  lSegmentCount: Integer;
  lX0: Integer;
  lX1: Integer;
  lY0: Integer;
  lY1: Integer;
begin
  lSegmentCount := Max(12, Round(ARadius / 3));
  Canvas.SetColor(AColor);

  for lSegment := 0 to lSegmentCount - 1 do
  begin
    if Odd(lSegment) then
      Continue;

    lAngle := (2 * Pi * lSegment) / lSegmentCount;
    lEndAngle := (2 * Pi * (lSegment + 1)) / lSegmentCount;
    lX0 := AX + Round(Cos(lAngle) * ARadius);
    lY0 := AY + Round(Sin(lAngle) * ARadius);
    lX1 := AX + Round(Cos(lEndAngle) * ARadius);
    lY1 := AY + Round(Sin(lEndAngle) * ARadius);
    Canvas.DrawLine(lX0, lY0, lX1, lY1);
  end;
end;

procedure TNXStarMap.DrawDottedRing(AX, AY, ARadius: Integer;
  const AColor: TfpgColor);
var
  lAngle: Double;
  lDot: Integer;
  lDotCount: Integer;
  lX: Integer;
  lY: Integer;
begin
  lDotCount := Max(12, Round(ARadius / 2));
  Canvas.SetColor(AColor);

  for lDot := 0 to lDotCount - 1 do
  begin
    lAngle := (2 * Pi * lDot) / lDotCount;
    lX := AX + Round(Cos(lAngle) * ARadius);
    lY := AY + Round(Sin(lAngle) * ARadius);
    Canvas.FillArc(lX - 1, lY - 1, 3, 3, 0, 360);
  end;
end;

procedure TNXStarMap.DrawSystem(const ASystem: TNXStarMapSystem; AIndex: Integer);
var
  lRadius: Integer;
  lScreenX: Integer;
  lScreenY: Integer;
begin
  if not ASystem.Visible then
    Exit;

  lScreenX := MapToClientX(ASystem.X);
  lScreenY := MapToClientY(ASystem.Y);
  lRadius := Max(1, ASystem.Radius);

  Canvas.SetColor(ASystem.Color);
  Canvas.FillArc(lScreenX - lRadius, lScreenY - lRadius, lRadius * 2,
    lRadius * 2, 0, 360);

  if ASystem.ID = FSelectedSystemID then
    DrawSolidRing(lScreenX, lScreenY, lRadius + 4, cSelectedRingColor);

  if AIndex = FHoverSystemIndex then
    DrawSolidRing(lScreenX, lScreenY, lRadius + 2, cHoverRingColor);

  if FShowLabels and (ASystem.Name <> '') then
  begin
    Canvas.SetFont(Font);
    Canvas.SetTextColor(TextColor);
    Canvas.DrawString(lScreenX + lRadius + 4,
      lScreenY - (Font.GetHeight div 2), ASystem.Name);
  end;
end;

procedure TNXStarMap.NotifySystemHover;
begin
  if (FHoverSystemIndex < 0) or (FHoverSystemIndex > High(FSystems)) then
    Exit;

  if Assigned(FOnSystemHover) then
    FOnSystemHover(Self, FSystems[FHoverSystemIndex].ID, FHoverSystemIndex,
      FSystems[FHoverSystemIndex]);
end;

procedure TNXStarMap.NotifySystemSelected;
var
  lSystemIndex: Integer;
begin
  lSystemIndex := SelectedSystemIndex;
  if lSystemIndex < 0 then
    Exit;

  if Assigned(FOnSystemSelected) then
    FOnSystemSelected(Self, FSystems[lSystemIndex].ID, lSystemIndex,
      FSystems[lSystemIndex]);
end;

procedure TNXStarMap.HandlePaint;
var
  lIndex: Integer;
  lMapRect: TfpgRect;
begin
  inherited HandlePaint;

  lMapRect := GetMapRect;
  Canvas.SetClipRect(lMapRect);

  for lIndex := 0 to High(FRings) do
    DrawRangeRing(FRings[lIndex]);

  for lIndex := 0 to High(FSystems) do
    DrawSystem(FSystems[lIndex], lIndex);

  Canvas.ClearClipRect;
  fpgStyle.DrawControlFrame(Canvas, 0, 0, ActualWidth, ActualHeight);
end;

procedure TNXStarMap.HandleLMouseUp(AX, AY: Integer;
  AShiftState: TShiftState);
var
  lMapX: Double;
  lMapY: Double;
  lSystemIndex: Integer;
begin
  inherited HandleLMouseUp(AX, AY, AShiftState);

  lSystemIndex := SystemAt(AX, AY);
  if lSystemIndex >= 0 then
  begin
    SelectedSystemID := FSystems[lSystemIndex].ID;
    if Assigned(FOnSystemClick) then
      FOnSystemClick(Self, FSystems[lSystemIndex].ID, lSystemIndex,
        FSystems[lSystemIndex]);
    Exit;
  end;

  lMapX := ClientToMapX(AX);
  lMapY := ClientToMapY(AY);
  if Assigned(FOnEmptyClick) then
    FOnEmptyClick(Self, cInvalidSystemID, -1, lMapX, lMapY);
end;

procedure TNXStarMap.HandleMouseExit;
begin
  inherited HandleMouseExit;
  SetHoverSystemIndex(-1);
end;

procedure TNXStarMap.HandleMouseMove(AX, AY: Integer; AButtonState: Word;
  AShiftState: TShiftState);
begin
  inherited HandleMouseMove(AX, AY, AButtonState, AShiftState);
  SetHoverSystemIndex(SystemAt(AX, AY));
end;

procedure TNXStarMap.HandleMouseScroll(AX, AY: Integer;
  AShiftState: TShiftState; ADelta: SmallInt);
begin
  inherited HandleMouseScroll(AX, AY, AShiftState, ADelta);

  if ADelta > 0 then
    ZoomAtClientPoint(AX, AY, cWheelZoomFactor)
  else if ADelta < 0 then
    ZoomAtClientPoint(AX, AY, 1 / cWheelZoomFactor);
end;

function TNXStarMap.AddRing(const ARing: TNXStarMapRing): Integer;
begin
  Result := Length(FRings);
  SetLength(FRings, Result + 1);
  FRings[Result] := ARing;
  Invalidate;
end;

function TNXStarMap.AddSystem(const ASystem: TNXStarMapSystem): Integer;
begin
  Result := Length(FSystems);
  SetLength(FSystems, Result + 1);
  FSystems[Result] := ASystem;
  Invalidate;
end;

function TNXStarMap.ClientToMapX(AX: Integer): Double;
var
  lClientRect: TfpgRect;
begin
  lClientRect := GetMapRect;
  Result := FViewCenterX +
    ((AX - lClientRect.Left - (lClientRect.Width / 2)) / FZoom);
end;

function TNXStarMap.ClientToMapY(AY: Integer): Double;
var
  lClientRect: TfpgRect;
  lDelta: Double;
begin
  lClientRect := GetMapRect;
  lDelta := (AY - lClientRect.Top - (lClientRect.Height / 2)) / FZoom;
  if FYPositiveUp then
    Result := FViewCenterY - lDelta
  else
    Result := FViewCenterY + lDelta;
end;

function TNXStarMap.FindSystemIndexByID(ASystemID: Integer): Integer;
var
  lIndex: Integer;
begin
  Result := -1;

  for lIndex := 0 to High(FSystems) do
    if FSystems[lIndex].ID = ASystemID then
    begin
      Result := lIndex;
      Exit;
    end;
end;

function TNXStarMap.MapToClientX(AX: Double): Integer;
var
  lClientRect: TfpgRect;
begin
  lClientRect := GetMapRect;
  Result := lClientRect.Left + Round((lClientRect.Width / 2) +
    ((AX - FViewCenterX) * FZoom));
end;

function TNXStarMap.MapToClientY(AY: Double): Integer;
var
  lClientRect: TfpgRect;
  lDelta: Double;
begin
  lClientRect := GetMapRect;
  lDelta := AY - FViewCenterY;
  if FYPositiveUp then
    lDelta := -lDelta;

  Result := lClientRect.Top +
    Round((lClientRect.Height / 2) + (lDelta * FZoom));
end;

procedure TNXStarMap.AutoFit;
var
  lAvailableHeight: Integer;
  lAvailableWidth: Integer;
  lIndex: Integer;
  lMaxX: Double;
  lMaxY: Double;
  lMinX: Double;
  lMinY: Double;
  lRangeX: Double;
  lRangeY: Double;
  lZoomX: Double;
  lZoomY: Double;
  lClientRect: TfpgRect;
begin
  if Length(FSystems) = 0 then
    Exit;

  lMinX := FSystems[0].X;
  lMaxX := FSystems[0].X;
  lMinY := FSystems[0].Y;
  lMaxY := FSystems[0].Y;

  for lIndex := 1 to High(FSystems) do
  begin
    lMinX := Min(lMinX, FSystems[lIndex].X);
    lMaxX := Max(lMaxX, FSystems[lIndex].X);
    lMinY := Min(lMinY, FSystems[lIndex].Y);
    lMaxY := Max(lMaxY, FSystems[lIndex].Y);
  end;

  FViewCenterX := (lMinX + lMaxX) / 2;
  FViewCenterY := (lMinY + lMaxY) / 2;

  lClientRect := GetMapRect;
  lAvailableWidth := Max(1,
    lClientRect.Width - (FAutoFitMargin * 2));
  lAvailableHeight := Max(1,
    lClientRect.Height - (FAutoFitMargin * 2));
  lRangeX := Max(1.0, lMaxX - lMinX);
  lRangeY := Max(1.0, lMaxY - lMinY);
  lZoomX := lAvailableWidth / lRangeX;
  lZoomY := lAvailableHeight / lRangeY;
  Zoom := Min(lZoomX, lZoomY);
end;

procedure TNXStarMap.CenterOn(AX, AY: Double);
begin
  FViewCenterX := AX;
  FViewCenterY := AY;
  Invalidate;
end;

procedure TNXStarMap.CenterOnSystemID(ASystemID: Integer);
var
  lSystemIndex: Integer;
begin
  lSystemIndex := FindSystemIndexByID(ASystemID);
  if lSystemIndex < 0 then
    Exit;

  CenterOn(FSystems[lSystemIndex].X, FSystems[lSystemIndex].Y);
end;

procedure TNXStarMap.ClearRings;
begin
  SetLength(FRings, 0);
  Invalidate;
end;

procedure TNXStarMap.ClearSystems;
begin
  SetLength(FSystems, 0);
  FHoverSystemIndex := -1;
  FSelectedSystemID := cInvalidSystemID;
  Invalidate;
end;

procedure TNXStarMap.SetRing(AIndex: Integer; const ARing: TNXStarMapRing);
begin
  if (AIndex < 0) or (AIndex > High(FRings)) then
    raise ERangeError.Create('Star map ring index out of range');

  FRings[AIndex] := ARing;
  Invalidate;
end;

procedure TNXStarMap.SetSystem(AIndex: Integer; const ASystem: TNXStarMapSystem);
begin
  if (AIndex < 0) or (AIndex > High(FSystems)) then
    raise ERangeError.Create('Star system index out of range');

  FSystems[AIndex] := ASystem;
  Invalidate;
end;

procedure TNXStarMap.ZoomAtClientPoint(AX, AY: Integer; AFactor: Double);
var
  lAfterX: Double;
  lAfterY: Double;
  lBeforeX: Double;
  lBeforeY: Double;
begin
  if AFactor <= 0 then
    Exit;

  lBeforeX := ClientToMapX(AX);
  lBeforeY := ClientToMapY(AY);
  Zoom := FZoom * AFactor;
  lAfterX := ClientToMapX(AX);
  lAfterY := ClientToMapY(AY);
  FViewCenterX := FViewCenterX + (lBeforeX - lAfterX);
  FViewCenterY := FViewCenterY + (lBeforeY - lAfterY);
end;

end.

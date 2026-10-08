(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTreeView;

{$mode objfpc}{$H+}

interface

uses
  Classes, Math, fgl,
  fpg_base, fpg_main, fpg_scrollbar, fpg_widget;

type
  TNXTreeView = class;
  TNXTreeViewNode = class;

  TNXTreeViewCellAlign = (tvcaLeft, tvcaCenter, tvcaRight);
  TNXTreeViewGlyphKind = (tvgkNone, tvgkCircle, tvgkSquare);

  TNXTreeViewCell = class
  private
    FAlign: TNXTreeViewCellAlign;
    FBackColor: TfpgColor;
    FForeColor: TfpgColor;
    FGlyphColor: TfpgColor;
    FGlyphKind: TNXTreeViewGlyphKind;
    FImage: TfpgImage;
    FImageHeight: Integer;
    FImageWidth: Integer;
    FText: string;
    FUseBackColor: Boolean;
    FUseForeColor: Boolean;
    FUseGlyphColor: Boolean;
  public
    constructor Create;
    procedure Clear;
    property Align: TNXTreeViewCellAlign read FAlign write FAlign;
    property BackColor: TfpgColor read FBackColor write FBackColor;
    property ForeColor: TfpgColor read FForeColor write FForeColor;
    property GlyphColor: TfpgColor read FGlyphColor write FGlyphColor;
    property GlyphKind: TNXTreeViewGlyphKind read FGlyphKind write FGlyphKind;
    property Image: TfpgImage read FImage write FImage;
    property ImageHeight: Integer read FImageHeight write FImageHeight;
    property ImageWidth: Integer read FImageWidth write FImageWidth;
    property Text: string read FText write FText;
    property UseBackColor: Boolean read FUseBackColor write FUseBackColor;
    property UseForeColor: Boolean read FUseForeColor write FUseForeColor;
    property UseGlyphColor: Boolean read FUseGlyphColor write FUseGlyphColor;
  end;

  TNXTreeViewColumn = class
  private
    FAlign: TNXTreeViewCellAlign;
    FCaption: string;
    FMinWidth: Integer;
    FOwner: TNXTreeView;
    FVisible: Boolean;
    FWidth: Integer;
    procedure Changed;
    procedure SetMinWidth(AValue: Integer);
    procedure SetVisible(AValue: Boolean);
    procedure SetWidth(AValue: Integer);
  public
    constructor Create(const ACaption: string; AWidth: Integer);
    property Align: TNXTreeViewCellAlign read FAlign write FAlign;
    property Caption: string read FCaption write FCaption;
    property MinWidth: Integer read FMinWidth write SetMinWidth;
    property Visible: Boolean read FVisible write SetVisible;
    property Width: Integer read FWidth write SetWidth;
  end;

  TNXTreeViewCellList = specialize TFPGObjectList<TNXTreeViewCell>;
  TNXTreeViewNodeList = specialize TFPGObjectList<TNXTreeViewNode>;
  TNXTreeViewColumnListBase = specialize TFPGObjectList<TNXTreeViewColumn>;
  TNXTreeViewVisibleNodeList = specialize TFPGList<TNXTreeViewNode>;

  TNXTreeViewNode = class
  private
    FCells: TNXTreeViewCellList;
    FChildren: TNXTreeViewNodeList;
    FData: Pointer;
    FExpanded: Boolean;
    FParent: TNXTreeViewNode;
    FSelected: Boolean;
    function GetCell(AIndex: Integer): TNXTreeViewCell;
    function GetCellCount: Integer;
    function GetChild(AIndex: Integer): TNXTreeViewNode;
    function GetChildCount: Integer;
    function GetLevel: Integer;
    function GetText: string;
    procedure SetText(const AValue: string);
  public
    constructor Create(const AText: string = ''; AData: Pointer = nil);
    destructor Destroy; override;
    function AddChild(const AText: string = '';
      AData: Pointer = nil): TNXTreeViewNode;
    procedure Clear;
    procedure ClearCells;
    function Contains(ANode: TNXTreeViewNode): Boolean;
    procedure EnsureCellCount(ACount: Integer);
    function HasChildren: Boolean;
    property Cell[AIndex: Integer]: TNXTreeViewCell read GetCell;
    property CellCount: Integer read GetCellCount;
    property Child[AIndex: Integer]: TNXTreeViewNode read GetChild;
    property ChildCount: Integer read GetChildCount;
    property Data: Pointer read FData write FData;
    property Expanded: Boolean read FExpanded write FExpanded;
    property Level: Integer read GetLevel;
    property Parent: TNXTreeViewNode read FParent;
    property Selected: Boolean read FSelected write FSelected;
    property Text: string read GetText write SetText;
  end;

  TNXTreeViewRootList = class(TNXTreeViewNodeList)
  public
    function AddNode(const AText: string = '';
      AData: Pointer = nil): TNXTreeViewNode;
  end;

  TNXTreeViewColumnList = class(TNXTreeViewColumnListBase)
  public
    function AddColumn(const ACaption: string;
      AWidth: Integer): TNXTreeViewColumn;
  end;

  TNXTreeViewNodeEvent = procedure(Sender: TObject;
    ANode: TNXTreeViewNode) of object;
  TNXTreeViewCellEvent = procedure(Sender: TObject;
    ANode: TNXTreeViewNode; AColumn: Integer) of object;
  TNXTreeViewColumnEvent = procedure(Sender: TObject;
    AColumn: Integer) of object;

  TNXTreeView = class(TfpgWidget)
  private
    FColumns: TNXTreeViewColumnList;
    FContentHeight: Integer;
    FContentWidth: Integer;
    FDefaultColumnWidth: Integer;
    FFont: TfpgFontResourceBase;
    FHeaderHeight: Integer;
    FHorizontalScrollBar: TfpgScrollbar;
    FIndentWidth: Integer;
    FLineHeight: Integer;
    FOnCellActivate: TNXTreeViewCellEvent;
    FOnCellClick: TNXTreeViewCellEvent;
    FOnChange: TNXTreeViewNodeEvent;
    FOnCollapsed: TNXTreeViewNodeEvent;
    FOnColumnClick: TNXTreeViewColumnEvent;
    FOnExpanded: TNXTreeViewNodeEvent;
    FRootNodes: TNXTreeViewRootList;
    FScrollX: Integer;
    FScrollY: Integer;
    FSelectedColumn: Integer;
    FSelectedNode: TNXTreeViewNode;
    FShowColumnHeaders: Boolean;
    FShowGridLines: Boolean;
    FVerticalScrollBar: TfpgScrollbar;
    FVisibleNodes: TNXTreeViewVisibleNodeList;
    function GetTotalColumnWidth: Integer;
    function GetViewportRect: TfpgRect;
    procedure HorizontalScroll(Sender: TObject; APosition: Integer);
    procedure LayoutChanged;
    procedure SetHeaderHeight(AValue: Integer);
    procedure SetIndentWidth(AValue: Integer);
    procedure SetLineHeight(AValue: Integer);
    procedure SetSelectedNode(AValue: TNXTreeViewNode);
    procedure SetShowColumnHeaders(AValue: Boolean);
    procedure UpdateLayout;
    procedure UpdateScrollBars;
    procedure VerticalScroll(Sender: TObject; APosition: Integer);
  protected
    procedure AddVisibleNodes(ANodes: TNXTreeViewNodeList);
    function CellAt(AX, AY: Integer; out AColumn: Integer;
      out ANode: TNXTreeViewNode): Boolean;
    function CellRect(AColumn, AVisibleIndex: Integer): TfpgRect;
    procedure CollapseNode(ANode: TNXTreeViewNode);
    function ColumnAt(AX: Integer; out AColumn: Integer): Boolean;
    function ColumnLeft(AColumn: Integer): Integer;
    procedure DrawCell(ANode: TNXTreeViewNode; AColumn: Integer;
      const ARect: TfpgRect);
    procedure DrawCellContent(ANode: TNXTreeViewNode; AColumn: Integer;
      const ARect: TfpgRect);
    procedure DrawCellText(const AText: string; const ARect: TfpgRect;
      AAlign: TNXTreeViewCellAlign; AColor: TfpgColor);
    procedure DrawExpandGlyph(ANode: TNXTreeViewNode;
      const ARect: TfpgRect);
    procedure DrawHeader(AColumn: Integer; const ARect: TfpgRect);
    procedure DrawStatusGlyph(ACell: TNXTreeViewCell;
      const ARect: TfpgRect);
    procedure EnsureSelectedVisible;
    procedure ExpandNode(ANode: TNXTreeViewNode);
    function GetContentTop: Integer;
    function GetDefaultLineHeight: Integer;
    function GetNodeGlyphRect(ANode: TNXTreeViewNode;
      const ACellRect: TfpgRect): TfpgRect;
    procedure HandleDoubleClick(AX, AY: Integer; AButton: Word;
      AShiftState: TShiftState); override;
    procedure HandleKeyPress(var AKeyCode: Word;
      var AShiftState: TShiftState; var AConsumed: Boolean); override;
    procedure HandleLMouseDown(AX, AY: Integer;
      AShiftState: TShiftState); override;
    procedure HandleMouseHorizScroll(AX, AY: Integer;
      AShiftState: TShiftState; ADelta: SmallInt); override;
    procedure HandleMouseScroll(AX, AY: Integer;
      AShiftState: TShiftState; ADelta: SmallInt); override;
    procedure HandlePaint; override;
    procedure HandleResize(AWidth, AHeight: TfpgCoord); override;
    procedure RebuildVisibleNodes;
    procedure SelectNode(ANode: TNXTreeViewNode; AColumn: Integer = 0);
    procedure ToggleNode(ANode: TNXTreeViewNode);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function AddChildNode(AParentNode: TNXTreeViewNode;
      const AText: string = ''; AData: Pointer = nil): TNXTreeViewNode;
    function AddColumn(const ACaption: string;
      AWidth: Integer = 0): TNXTreeViewColumn;
    function AddNode(const AText: string = '';
      AData: Pointer = nil): TNXTreeViewNode;
    procedure Clear;
    procedure ClearColumns;
    procedure CollapseAll;
    procedure ExpandAll;
    procedure NodeChanged(ANode: TNXTreeViewNode);
    property Columns: TNXTreeViewColumnList read FColumns;
    property DefaultColumnWidth: Integer read FDefaultColumnWidth
      write FDefaultColumnWidth;
    property HeaderHeight: Integer read FHeaderHeight write SetHeaderHeight;
    property IndentWidth: Integer read FIndentWidth write SetIndentWidth;
    property LineHeight: Integer read FLineHeight write SetLineHeight;
    property OnCellActivate: TNXTreeViewCellEvent read FOnCellActivate
      write FOnCellActivate;
    property OnCellClick: TNXTreeViewCellEvent read FOnCellClick
      write FOnCellClick;
    property OnChange: TNXTreeViewNodeEvent read FOnChange write FOnChange;
    property OnCollapsed: TNXTreeViewNodeEvent read FOnCollapsed
      write FOnCollapsed;
    property OnColumnClick: TNXTreeViewColumnEvent read FOnColumnClick
      write FOnColumnClick;
    property OnExpanded: TNXTreeViewNodeEvent read FOnExpanded
      write FOnExpanded;
    property RootNodes: TNXTreeViewRootList read FRootNodes;
    property SelectedColumn: Integer read FSelectedColumn;
    property SelectedNode: TNXTreeViewNode read FSelectedNode
      write SetSelectedNode;
    property ShowColumnHeaders: Boolean read FShowColumnHeaders
      write SetShowColumnHeaders;
    property ShowGridLines: Boolean read FShowGridLines write FShowGridLines;
  end;

implementation

const
  cDefaultColumnWidth = 120;
  cDefaultHeaderHeight = 22;
  cDefaultIndentWidth = 18;
  cDefaultLineHeight = 22;
  cCellPaddingX = 4;
  cExpandGlyphSize = 9;
  cStatusGlyphSize = 10;
  cScrollBarSize = 16;

constructor TNXTreeViewCell.Create;
begin
  inherited Create;
  Clear;
end;

procedure TNXTreeViewCell.Clear;
begin
  FAlign := tvcaLeft;
  FBackColor := clNone;
  FForeColor := clNone;
  FGlyphColor := clNone;
  FGlyphKind := tvgkNone;
  FImage := nil;
  FImageHeight := 0;
  FImageWidth := 0;
  FText := '';
  FUseBackColor := False;
  FUseForeColor := False;
  FUseGlyphColor := False;
end;

constructor TNXTreeViewColumn.Create(const ACaption: string; AWidth: Integer);
begin
  inherited Create;
  FAlign := tvcaLeft;
  FCaption := ACaption;
  FMinWidth := 24;
  FVisible := True;
  FWidth := Max(FMinWidth, AWidth);
end;

procedure TNXTreeViewColumn.Changed;
begin
  if Assigned(FOwner) then
    FOwner.LayoutChanged;
end;

procedure TNXTreeViewColumn.SetMinWidth(AValue: Integer);
begin
  AValue := Max(0, AValue);
  if FMinWidth = AValue then Exit;
  FMinWidth := AValue;
  FWidth := Max(FWidth, FMinWidth);
  Changed;
end;

procedure TNXTreeViewColumn.SetVisible(AValue: Boolean);
begin
  if FVisible = AValue then Exit;
  FVisible := AValue;
  Changed;
end;

procedure TNXTreeViewColumn.SetWidth(AValue: Integer);
begin
  AValue := Max(FMinWidth, AValue);
  if FWidth = AValue then Exit;
  FWidth := AValue;
  Changed;
end;

constructor TNXTreeViewNode.Create(const AText: string; AData: Pointer);
begin
  inherited Create;
  FCells := TNXTreeViewCellList.Create(True);
  FChildren := TNXTreeViewNodeList.Create(True);
  FData := AData;
  EnsureCellCount(1);
  FCells[0].Text := AText;
end;

destructor TNXTreeViewNode.Destroy;
begin
  FChildren.Free;
  FCells.Free;
  inherited Destroy;
end;

function TNXTreeViewNode.AddChild(const AText: string;
  AData: Pointer): TNXTreeViewNode;
begin
  Result := TNXTreeViewNode.Create(AText, AData);
  Result.FParent := Self;
  FChildren.Add(Result);
end;

procedure TNXTreeViewNode.Clear;
begin
  FChildren.Clear;
end;

procedure TNXTreeViewNode.ClearCells;
begin
  FCells.Clear;
end;

function TNXTreeViewNode.Contains(ANode: TNXTreeViewNode): Boolean;
var
  lIndex: Integer;
begin
  if Self = ANode then Exit(True);
  for lIndex := 0 to FChildren.Count - 1 do
    if FChildren[lIndex].Contains(ANode) then Exit(True);
  Result := False;
end;

procedure TNXTreeViewNode.EnsureCellCount(ACount: Integer);
begin
  while FCells.Count < ACount do FCells.Add(TNXTreeViewCell.Create);
end;

function TNXTreeViewNode.GetCell(AIndex: Integer): TNXTreeViewCell;
begin
  EnsureCellCount(AIndex + 1);
  Result := FCells[AIndex];
end;

function TNXTreeViewNode.GetCellCount: Integer;
begin
  Result := FCells.Count;
end;

function TNXTreeViewNode.GetChild(AIndex: Integer): TNXTreeViewNode;
begin
  Result := FChildren[AIndex];
end;

function TNXTreeViewNode.GetChildCount: Integer;
begin
  Result := FChildren.Count;
end;

function TNXTreeViewNode.GetLevel: Integer;
var
  lNode: TNXTreeViewNode;
begin
  Result := 0;
  lNode := FParent;
  while Assigned(lNode) do
  begin
    Inc(Result);
    lNode := lNode.Parent;
  end;
end;

function TNXTreeViewNode.GetText: string;
begin
  Result := Cell[0].Text;
end;

function TNXTreeViewNode.HasChildren: Boolean;
begin
  Result := FChildren.Count > 0;
end;

procedure TNXTreeViewNode.SetText(const AValue: string);
begin
  Cell[0].Text := AValue;
end;

function TNXTreeViewRootList.AddNode(const AText: string;
  AData: Pointer): TNXTreeViewNode;
begin
  Result := TNXTreeViewNode.Create(AText, AData);
  Add(Result);
end;

function TNXTreeViewColumnList.AddColumn(const ACaption: string;
  AWidth: Integer): TNXTreeViewColumn;
begin
  Result := TNXTreeViewColumn.Create(ACaption, AWidth);
  Add(Result);
end;

constructor TNXTreeView.Create(AOwner: TComponent);
var
  lColumn: TNXTreeViewColumn;
begin
  inherited Create(AOwner);
  BackgroundColor := clListBox;
  Focusable := True;
  FColumns := TNXTreeViewColumnList.Create(True);
  FDefaultColumnWidth := cDefaultColumnWidth;
  FFont := fpgApplication.FontManager.GetFont('#Label1');
  FHeaderHeight := cDefaultHeaderHeight;
  FIndentWidth := cDefaultIndentWidth;
  FLineHeight := GetDefaultLineHeight;
  FRootNodes := TNXTreeViewRootList.Create(True);
  FSelectedColumn := -1;
  FShowColumnHeaders := True;
  FShowGridLines := True;
  FVisibleNodes := TNXTreeViewVisibleNodeList.Create;
  lColumn := FColumns.AddColumn('Name', FDefaultColumnWidth);
  lColumn.FOwner := Self;
  FHorizontalScrollBar := TfpgScrollbar.Create(Self);
  FHorizontalScrollBar.Orientation := orHorizontal;
  FHorizontalScrollBar.OnScroll := @HorizontalScroll;
  FHorizontalScrollBar.Visible := False;
  FVerticalScrollBar := TfpgScrollbar.Create(Self);
  FVerticalScrollBar.Orientation := orVertical;
  FVerticalScrollBar.OnScroll := @VerticalScroll;
  FVerticalScrollBar.Visible := False;
  Width := 500;
  Height := 250;
end;

destructor TNXTreeView.Destroy;
begin
  FFont := nil;
  FVisibleNodes.Free;
  FRootNodes.Free;
  FColumns.Free;
  inherited Destroy;
end;

function TNXTreeView.AddChildNode(AParentNode: TNXTreeViewNode;
  const AText: string; AData: Pointer): TNXTreeViewNode;
begin
  if Assigned(AParentNode) then
    Result := AParentNode.AddChild(AText, AData)
  else
    Result := FRootNodes.AddNode(AText, AData);
  Result.EnsureCellCount(Max(1, FColumns.Count));
  LayoutChanged;
end;

function TNXTreeView.AddColumn(const ACaption: string;
  AWidth: Integer): TNXTreeViewColumn;
begin
  if AWidth <= 0 then AWidth := FDefaultColumnWidth;
  Result := FColumns.AddColumn(ACaption, AWidth);
  Result.FOwner := Self;
  LayoutChanged;
end;

function TNXTreeView.AddNode(const AText: string;
  AData: Pointer): TNXTreeViewNode;
begin
  Result := AddChildNode(nil, AText, AData);
end;

procedure TNXTreeView.AddVisibleNodes(ANodes: TNXTreeViewNodeList);
var
  lIndex: Integer;
  lNode: TNXTreeViewNode;
begin
  for lIndex := 0 to ANodes.Count - 1 do
  begin
    lNode := ANodes[lIndex];
    FVisibleNodes.Add(lNode);
    if lNode.Expanded then AddVisibleNodes(lNode.FChildren);
  end;
end;

function TNXTreeView.CellAt(AX, AY: Integer; out AColumn: Integer;
  out ANode: TNXTreeViewNode): Boolean;
var
  lRow: Integer;
  lViewport: TfpgRect;
begin
  Result := False;
  ANode := nil;
  UpdateLayout;
  lViewport := GetViewportRect;
  if not lViewport.PointInRect(Point(AX, AY)) then Exit;
  if FShowColumnHeaders and (AY < lViewport.Top + FHeaderHeight) then Exit;
  if not ColumnAt(AX, AColumn) then Exit;
  lRow := (AY - lViewport.Top - GetContentTop + FScrollY) div FLineHeight;
  if (lRow < 0) or (lRow >= FVisibleNodes.Count) then Exit;
  ANode := FVisibleNodes[lRow];
  Result := True;
end;

function TNXTreeView.CellRect(AColumn, AVisibleIndex: Integer): TfpgRect;
var
  lViewport: TfpgRect;
begin
  lViewport := GetViewportRect;
  Result.SetRect(lViewport.Left + ColumnLeft(AColumn) - FScrollX,
    lViewport.Top + GetContentTop + AVisibleIndex * FLineHeight - FScrollY,
    FColumns[AColumn].Width, FLineHeight);
end;

procedure TNXTreeView.Clear;
begin
  FSelectedColumn := -1;
  FSelectedNode := nil;
  FRootNodes.Clear;
  LayoutChanged;
end;

procedure TNXTreeView.ClearColumns;
begin
  FColumns.Clear;
  FSelectedColumn := -1;
  LayoutChanged;
end;

procedure TNXTreeView.CollapseAll;
  procedure CollapseNodeAndChildren(ANode: TNXTreeViewNode);
  var lIndex: Integer;
  begin
    ANode.Expanded := False;
    for lIndex := 0 to ANode.ChildCount - 1 do
      CollapseNodeAndChildren(ANode.Child[lIndex]);
  end;
var lIndex: Integer;
begin
  for lIndex := 0 to FRootNodes.Count - 1 do
    CollapseNodeAndChildren(FRootNodes[lIndex]);
  LayoutChanged;
end;

procedure TNXTreeView.CollapseNode(ANode: TNXTreeViewNode);
begin
  if not Assigned(ANode) or not ANode.Expanded then Exit;
  ANode.Expanded := False;
  if ANode.Contains(FSelectedNode) and (ANode <> FSelectedNode) then
    SelectNode(ANode, FSelectedColumn);
  LayoutChanged;
  if Assigned(FOnCollapsed) then FOnCollapsed(Self, ANode);
end;

function TNXTreeView.ColumnAt(AX: Integer; out AColumn: Integer): Boolean;
var
  lIndex, lLeft, lX: Integer;
begin
  lX := AX - GetViewportRect.Left + FScrollX;
  lLeft := 0;
  for lIndex := 0 to FColumns.Count - 1 do
    if FColumns[lIndex].Visible then
    begin
      if (lX >= lLeft) and (lX < lLeft + FColumns[lIndex].Width) then
      begin
        AColumn := lIndex;
        Exit(True);
      end;
      Inc(lLeft, FColumns[lIndex].Width);
    end;
  AColumn := -1;
  Result := False;
end;

function TNXTreeView.ColumnLeft(AColumn: Integer): Integer;
var lIndex: Integer;
begin
  Result := 0;
  for lIndex := 0 to AColumn - 1 do
    if FColumns[lIndex].Visible then Inc(Result, FColumns[lIndex].Width);
end;

procedure TNXTreeView.DrawCell(ANode: TNXTreeViewNode; AColumn: Integer;
  const ARect: TfpgRect);
var lCell: TNXTreeViewCell;
begin
  lCell := ANode.Cell[AColumn];
  if ANode = FSelectedNode then
    if Focused then Canvas.SetColor(clSelection)
    else Canvas.SetColor(clInactiveSel)
  else if lCell.UseBackColor then Canvas.SetColor(lCell.BackColor)
  else Canvas.SetColor(clListBox);
  Canvas.FillRectangle(ARect);
  DrawCellContent(ANode, AColumn, ARect);
  if FShowGridLines then
  begin
    Canvas.SetColor(clGridLines);
    Canvas.DrawLine(ARect.Left, ARect.Bottom - 1,
      ARect.Right - 1, ARect.Bottom - 1);
    Canvas.DrawLine(ARect.Right - 1, ARect.Top,
      ARect.Right - 1, ARect.Bottom - 1);
  end;
end;

procedure TNXTreeView.DrawCellContent(ANode: TNXTreeViewNode;
  AColumn: Integer; const ARect: TfpgRect);
var
  lCell: TNXTreeViewCell;
  lColor: TfpgColor;
  lContent, lGlyph: TfpgRect;
  lImageHeight, lImageWidth: Integer;
begin
  lCell := ANode.Cell[AColumn];
  lContent := ARect;
  Inc(lContent.Left, cCellPaddingX);
  Dec(lContent.Width, cCellPaddingX * 2);
  if AColumn = 0 then
  begin
    lGlyph := GetNodeGlyphRect(ANode, ARect);
    DrawExpandGlyph(ANode, lGlyph);
    lContent.Left := lGlyph.Right + cCellPaddingX;
    lContent.Width := Max(0, ARect.Right - lContent.Left - cCellPaddingX);
  end;
  if lCell.GlyphKind <> tvgkNone then
  begin
    lGlyph.SetRect(lContent.Left, lContent.Top +
      Max(0, (lContent.Height - cStatusGlyphSize) div 2),
      cStatusGlyphSize, cStatusGlyphSize);
    DrawStatusGlyph(lCell, lGlyph);
    Inc(lContent.Left, cStatusGlyphSize + cCellPaddingX);
    Dec(lContent.Width, cStatusGlyphSize + cCellPaddingX);
  end;
  if Assigned(lCell.Image) then
  begin
    lImageWidth := lCell.ImageWidth;
    lImageHeight := lCell.ImageHeight;
    if lImageWidth <= 0 then lImageWidth := lCell.Image.Width;
    if lImageHeight <= 0 then lImageHeight := lCell.Image.Height;
    Canvas.DrawImage(lContent.Left, lContent.Top +
      Max(0, (lContent.Height - lImageHeight) div 2), lCell.Image);
    Inc(lContent.Left, lImageWidth + cCellPaddingX);
    Dec(lContent.Width, lImageWidth + cCellPaddingX);
  end;
  if (lCell.Text = '') or (lContent.Width <= 0) then Exit;
  if ANode = FSelectedNode then
    if Focused then lColor := clSelectionText
    else lColor := clInactiveSelText
  else if lCell.UseForeColor then lColor := lCell.ForeColor
  else lColor := TextColor;
  DrawCellText(lCell.Text, lContent, lCell.Align, lColor);
end;

procedure TNXTreeView.DrawCellText(const AText: string;
  const ARect: TfpgRect; AAlign: TNXTreeViewCellAlign; AColor: TfpgColor);
var lTextWidth, lTextX, lTextY: Integer;
begin
  if AText = '' then Exit;
  lTextWidth := FFont.GetTextWidth(AText);
  case AAlign of
    tvcaCenter: lTextX := ARect.Left + (ARect.Width - lTextWidth) div 2;
    tvcaRight: lTextX := ARect.Right - lTextWidth - cCellPaddingX;
  else
    lTextX := ARect.Left;
  end;
  lTextY := ARect.Top + Max(0, (ARect.Height - FFont.GetHeight) div 2);
  Canvas.SetTextColor(AColor);
  Canvas.DrawString(lTextX, lTextY, AText);
end;

procedure TNXTreeView.DrawExpandGlyph(ANode: TNXTreeViewNode;
  const ARect: TfpgRect);
var lCenterX, lCenterY: Integer;
begin
  if not ANode.HasChildren then Exit;
  Canvas.SetColor(TextColor);
  Canvas.DrawRectangle(ARect);
  lCenterX := ARect.Left + ARect.Width div 2;
  lCenterY := ARect.Top + ARect.Height div 2;
  Canvas.DrawLine(ARect.Left + 2, lCenterY, ARect.Right - 3, lCenterY);
  if not ANode.Expanded then
    Canvas.DrawLine(lCenterX, ARect.Top + 2, lCenterX, ARect.Bottom - 3);
end;

procedure TNXTreeView.DrawHeader(AColumn: Integer; const ARect: TfpgRect);
begin
  Canvas.SetColor(clGridHeader);
  Canvas.FillRectangle(ARect);
  DrawCellText(FColumns[AColumn].Caption, ARect,
    FColumns[AColumn].Align, clText1);
  Canvas.SetColor(clGridLines);
  Canvas.DrawLine(ARect.Left, ARect.Bottom - 1,
    ARect.Right - 1, ARect.Bottom - 1);
  Canvas.DrawLine(ARect.Right - 1, ARect.Top,
    ARect.Right - 1, ARect.Bottom - 1);
end;

procedure TNXTreeView.DrawStatusGlyph(ACell: TNXTreeViewCell;
  const ARect: TfpgRect);
begin
  if ACell.UseGlyphColor then Canvas.SetColor(ACell.GlyphColor)
  else Canvas.SetColor(TextColor);
  case ACell.GlyphKind of
    tvgkCircle: Canvas.FillArc(ARect.Left, ARect.Top,
      ARect.Width, ARect.Height, 0, 360);
    tvgkSquare: Canvas.FillRectangle(ARect);
  end;
end;

procedure TNXTreeView.EnsureSelectedVisible;
var lIndex, lTop, lBottom, lHeight: Integer;
begin
  UpdateLayout;
  if not Assigned(FSelectedNode) then Exit;
  lIndex := FVisibleNodes.IndexOf(FSelectedNode);
  if lIndex < 0 then Exit;
  lTop := lIndex * FLineHeight;
  lBottom := lTop + FLineHeight;
  lHeight := GetViewportRect.Height - GetContentTop;
  if lTop < FScrollY then FScrollY := lTop
  else if lBottom > FScrollY + lHeight then FScrollY := lBottom - lHeight;
  UpdateScrollBars;
end;

procedure TNXTreeView.ExpandAll;
  procedure ExpandNodeAndChildren(ANode: TNXTreeViewNode);
  var lIndex: Integer;
  begin
    ANode.Expanded := ANode.HasChildren;
    for lIndex := 0 to ANode.ChildCount - 1 do
      ExpandNodeAndChildren(ANode.Child[lIndex]);
  end;
var lIndex: Integer;
begin
  for lIndex := 0 to FRootNodes.Count - 1 do
    ExpandNodeAndChildren(FRootNodes[lIndex]);
  LayoutChanged;
end;

procedure TNXTreeView.ExpandNode(ANode: TNXTreeViewNode);
begin
  if not Assigned(ANode) or not ANode.HasChildren or ANode.Expanded then Exit;
  ANode.Expanded := True;
  LayoutChanged;
  if Assigned(FOnExpanded) then FOnExpanded(Self, ANode);
end;

function TNXTreeView.GetContentTop: Integer;
begin
  if FShowColumnHeaders then Result := FHeaderHeight else Result := 0;
end;

function TNXTreeView.GetDefaultLineHeight: Integer;
begin
  if Assigned(FFont) then Result := Max(cDefaultLineHeight, FFont.GetHeight + 6)
  else Result := cDefaultLineHeight;
end;

function TNXTreeView.GetNodeGlyphRect(ANode: TNXTreeViewNode;
  const ACellRect: TfpgRect): TfpgRect;
begin
  Result.SetRect(ACellRect.Left + cCellPaddingX +
    ANode.Level * FIndentWidth,
    ACellRect.Top + Max(0, (ACellRect.Height - cExpandGlyphSize) div 2),
    cExpandGlyphSize, cExpandGlyphSize);
end;

function TNXTreeView.GetTotalColumnWidth: Integer;
var lIndex: Integer;
begin
  Result := 0;
  for lIndex := 0 to FColumns.Count - 1 do
    if FColumns[lIndex].Visible then Inc(Result, FColumns[lIndex].Width);
end;

function TNXTreeView.GetViewportRect: TfpgRect;
begin
  Result.SetRect(2, 2, Max(0, ActualWidth - 4), Max(0, ActualHeight - 4));
  if FVerticalScrollBar.Visible then Dec(Result.Width, cScrollBarSize);
  if FHorizontalScrollBar.Visible then Dec(Result.Height, cScrollBarSize);
end;

procedure TNXTreeView.HandleDoubleClick(AX, AY: Integer; AButton: Word;
  AShiftState: TShiftState);
var lColumn: Integer; lNode: TNXTreeViewNode;
begin
  inherited HandleDoubleClick(AX, AY, AButton, AShiftState);
  if CellAt(AX, AY, lColumn, lNode) and Assigned(FOnCellActivate) then
    FOnCellActivate(Self, lNode, lColumn);
end;

procedure TNXTreeView.HandleKeyPress(var AKeyCode: Word;
  var AShiftState: TShiftState; var AConsumed: Boolean);
var lIndex: Integer; lNode: TNXTreeViewNode;
begin
  inherited HandleKeyPress(AKeyCode, AShiftState, AConsumed);
  if AConsumed then Exit;
  UpdateLayout;
  lIndex := FVisibleNodes.IndexOf(FSelectedNode);
  case AKeyCode of
    keyUp: if lIndex > 0 then SelectNode(FVisibleNodes[lIndex - 1], FSelectedColumn);
    keyDown:
      if (lIndex >= 0) and (lIndex < FVisibleNodes.Count - 1) then
        SelectNode(FVisibleNodes[lIndex + 1], FSelectedColumn)
      else if (lIndex < 0) and (FVisibleNodes.Count > 0) then
        SelectNode(FVisibleNodes[0], 0);
    keyHome: if FVisibleNodes.Count > 0 then SelectNode(FVisibleNodes[0], FSelectedColumn);
    keyEnd: if FVisibleNodes.Count > 0 then SelectNode(FVisibleNodes[FVisibleNodes.Count - 1], FSelectedColumn);
    keyLeft:
      begin
        lNode := FSelectedNode;
        if Assigned(lNode) then
          if lNode.Expanded then CollapseNode(lNode)
          else if Assigned(lNode.Parent) then SelectNode(lNode.Parent, FSelectedColumn);
      end;
    keyRight:
      begin
        lNode := FSelectedNode;
        if Assigned(lNode) then
          if lNode.HasChildren and not lNode.Expanded then ExpandNode(lNode)
          else if lNode.HasChildren then SelectNode(lNode.Child[0], FSelectedColumn);
      end;
    keyEnter:
      if Assigned(FSelectedNode) and Assigned(FOnCellActivate) then
        FOnCellActivate(Self, FSelectedNode, Max(0, FSelectedColumn));
  else
    Exit;
  end;
  AConsumed := True;
end;

procedure TNXTreeView.HandleLMouseDown(AX, AY: Integer;
  AShiftState: TShiftState);
var
  lCell, lGlyph: TfpgRect;
  lColumn, lIndex: Integer;
  lNode: TNXTreeViewNode;
begin
  inherited HandleLMouseDown(AX, AY, AShiftState);
  SetFocus;
  UpdateLayout;
  if FShowColumnHeaders and (AY < GetViewportRect.Top + FHeaderHeight) then
  begin
    if ColumnAt(AX, lColumn) and Assigned(FOnColumnClick) then
      FOnColumnClick(Self, lColumn);
    Exit;
  end;
  if not CellAt(AX, AY, lColumn, lNode) then Exit;
  SelectNode(lNode, lColumn);
  if Assigned(FOnCellClick) then FOnCellClick(Self, lNode, lColumn);
  if lColumn <> 0 then Exit;
  lIndex := FVisibleNodes.IndexOf(lNode);
  lCell := CellRect(0, lIndex);
  lGlyph := GetNodeGlyphRect(lNode, lCell);
  if lGlyph.PointInRect(Point(AX, AY)) then ToggleNode(lNode);
end;

procedure TNXTreeView.HandleMouseHorizScroll(AX, AY: Integer;
  AShiftState: TShiftState; ADelta: SmallInt);
begin
  inherited HandleMouseHorizScroll(AX, AY, AShiftState, ADelta);
  FScrollX := EnsureRange(FScrollX - ADelta * FIndentWidth,
    0, FHorizontalScrollBar.Max);
  FHorizontalScrollBar.Position := FScrollX;
  Invalidate;
end;

procedure TNXTreeView.HandleMouseScroll(AX, AY: Integer;
  AShiftState: TShiftState; ADelta: SmallInt);
begin
  inherited HandleMouseScroll(AX, AY, AShiftState, ADelta);
  FScrollY := EnsureRange(FScrollY - ADelta * FLineHeight,
    0, FVerticalScrollBar.Max);
  FVerticalScrollBar.Position := FScrollY;
  Invalidate;
end;

procedure TNXTreeView.HandlePaint;
var
  lColumn, lFirst, lLast, lLine: Integer;
  lRect, lViewport: TfpgRect;
begin
  inherited HandlePaint;
  UpdateLayout;
  Canvas.SetFont(FFont);
  fpgStyle.DrawControlFrame(Canvas, 0, 0, ActualWidth, ActualHeight);
  lViewport := GetViewportRect;
  Canvas.SetClipRect(lViewport);
  if FShowColumnHeaders then
    for lColumn := 0 to FColumns.Count - 1 do
      if FColumns[lColumn].Visible then
      begin
        lRect.SetRect(lViewport.Left + ColumnLeft(lColumn) - FScrollX,
          lViewport.Top, FColumns[lColumn].Width, FHeaderHeight);
        if (lRect.Right > lViewport.Left) and (lRect.Left < lViewport.Right) then
          DrawHeader(lColumn, lRect);
      end;
  lFirst := Max(0, FScrollY div FLineHeight);
  lLast := Min(FVisibleNodes.Count - 1,
    (FScrollY + lViewport.Height - GetContentTop) div FLineHeight + 1);
  for lLine := lFirst to lLast do
    for lColumn := 0 to FColumns.Count - 1 do
      if FColumns[lColumn].Visible then
      begin
        lRect := CellRect(lColumn, lLine);
        if (lRect.Right > lViewport.Left) and (lRect.Left < lViewport.Right) and
          (lRect.Bottom > lViewport.Top + GetContentTop) and
          (lRect.Top < lViewport.Bottom) then
          DrawCell(FVisibleNodes[lLine], lColumn, lRect);
      end;
  Canvas.ClearClipRect;
end;

procedure TNXTreeView.HandleResize(AWidth, AHeight: TfpgCoord);
begin
  inherited HandleResize(AWidth, AHeight);
  UpdateScrollBars;
end;

procedure TNXTreeView.HorizontalScroll(Sender: TObject; APosition: Integer);
begin
  FScrollX := APosition;
  Invalidate;
end;

procedure TNXTreeView.LayoutChanged;
begin
  UpdateLayout;
  Invalidate;
end;

procedure TNXTreeView.NodeChanged(ANode: TNXTreeViewNode);
begin
  LayoutChanged;
end;

procedure TNXTreeView.RebuildVisibleNodes;
begin
  FVisibleNodes.Clear;
  AddVisibleNodes(FRootNodes);
end;

procedure TNXTreeView.SelectNode(ANode: TNXTreeViewNode; AColumn: Integer);
begin
  if (FSelectedNode = ANode) and (FSelectedColumn = AColumn) then Exit;
  if Assigned(FSelectedNode) then FSelectedNode.Selected := False;
  FSelectedNode := ANode;
  FSelectedColumn := AColumn;
  if Assigned(FSelectedNode) then FSelectedNode.Selected := True;
  EnsureSelectedVisible;
  Invalidate;
  if Assigned(FOnChange) then FOnChange(Self, FSelectedNode);
end;

procedure TNXTreeView.SetHeaderHeight(AValue: Integer);
begin
  AValue := Max(0, AValue);
  if FHeaderHeight = AValue then Exit;
  FHeaderHeight := AValue;
  LayoutChanged;
end;

procedure TNXTreeView.SetIndentWidth(AValue: Integer);
begin
  AValue := Max(4, AValue);
  if FIndentWidth = AValue then Exit;
  FIndentWidth := AValue;
  LayoutChanged;
end;

procedure TNXTreeView.SetLineHeight(AValue: Integer);
begin
  AValue := Max(8, AValue);
  if FLineHeight = AValue then Exit;
  FLineHeight := AValue;
  LayoutChanged;
end;

procedure TNXTreeView.SetSelectedNode(AValue: TNXTreeViewNode);
begin
  SelectNode(AValue, FSelectedColumn);
end;

procedure TNXTreeView.SetShowColumnHeaders(AValue: Boolean);
begin
  if FShowColumnHeaders = AValue then Exit;
  FShowColumnHeaders := AValue;
  LayoutChanged;
end;

procedure TNXTreeView.ToggleNode(ANode: TNXTreeViewNode);
begin
  if not Assigned(ANode) then Exit;
  if ANode.Expanded then CollapseNode(ANode) else ExpandNode(ANode);
end;

procedure TNXTreeView.UpdateLayout;
begin
  RebuildVisibleNodes;
  FContentWidth := GetTotalColumnWidth;
  FContentHeight := GetContentTop + FVisibleNodes.Count * FLineHeight;
  UpdateScrollBars;
end;

procedure TNXTreeView.UpdateScrollBars;
var
  lHVisible, lVVisible: Boolean;
  lHeight, lWidth: Integer;
begin
  lWidth := Max(0, ActualWidth - 4);
  lHeight := Max(0, ActualHeight - 4);
  lVVisible := FContentHeight > lHeight;
  if lVVisible then Dec(lWidth, cScrollBarSize);
  lHVisible := FContentWidth > lWidth;
  if lHVisible then Dec(lHeight, cScrollBarSize);
  if not lVVisible and (FContentHeight > lHeight) then
  begin
    lVVisible := True;
    Dec(lWidth, cScrollBarSize);
  end;
  FVerticalScrollBar.Visible := lVVisible;
  FHorizontalScrollBar.Visible := lHVisible;
  FVerticalScrollBar.Left := ActualWidth - cScrollBarSize - 2;
  FVerticalScrollBar.Top := 2;
  FVerticalScrollBar.Width := cScrollBarSize;
  FVerticalScrollBar.Height := lHeight;
  FHorizontalScrollBar.Left := 2;
  FHorizontalScrollBar.Top := ActualHeight - cScrollBarSize - 2;
  FHorizontalScrollBar.Width := lWidth;
  FHorizontalScrollBar.Height := cScrollBarSize;
  FVerticalScrollBar.Min := 0;
  FVerticalScrollBar.Max := Max(0, FContentHeight - lHeight);
  FVerticalScrollBar.PageSize := lHeight;
  FVerticalScrollBar.ScrollStep := FLineHeight;
  if FContentHeight > 0 then
    FVerticalScrollBar.SliderSize := Min(1.0, lHeight / FContentHeight)
  else FVerticalScrollBar.SliderSize := 1.0;
  FScrollY := EnsureRange(FScrollY, 0, FVerticalScrollBar.Max);
  FVerticalScrollBar.Position := FScrollY;
  FHorizontalScrollBar.Min := 0;
  FHorizontalScrollBar.Max := Max(0, FContentWidth - lWidth);
  FHorizontalScrollBar.PageSize := lWidth;
  FHorizontalScrollBar.ScrollStep := FIndentWidth;
  if FContentWidth > 0 then
    FHorizontalScrollBar.SliderSize := Min(1.0, lWidth / FContentWidth)
  else FHorizontalScrollBar.SliderSize := 1.0;
  FScrollX := EnsureRange(FScrollX, 0, FHorizontalScrollBar.Max);
  FHorizontalScrollBar.Position := FScrollX;
end;

procedure TNXTreeView.VerticalScroll(Sender: TObject; APosition: Integer);
begin
  FScrollY := APosition;
  Invalidate;
end;

end.

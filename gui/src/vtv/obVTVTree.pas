{ Native fpGUI adaptation of Virtual TreeView 6.0.0.

  The original VirtualTrees.pas was written by Mike Lischke.
  Copyright (c) 1999-2001 digital publishing AG. All Rights Reserved.
  Lazarus port: Luiz Americo Pereira Camara.
  Native fpGUI adaptations: Copyright (c) 2026 Kevin Collins.

  This file is subject to the Mozilla Public License, Version 1.1.
  https://www.mozilla.org/MPL/1.1/
  Alternatively, it may be used under the GNU Lesser General Public License,
  version 2.1 or later, as described in the upstream source.

  Node records, linked-list attachment/traversal, ancestor metrics, lazy
  initialization, and stable linked-list merge sorting are adapted from the
  pinned upstream VirtualTrees.pas. Window, canvas, and input mechanics are
  native fpGUI; no LCL compatibility layer is used.
}

unit obVTVTree;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, fpg_base, fpg_main, fpg_widget, fpg_scrollbar,
  fpg_edit, fpg_combobox, tpVTV, obVTVColumns, obVTVOptions;

type
  TfpgVirtualStringTree = class;

  TVTChoiceEditor = class(TfpgComboBox)
  public
    property OnKeyPress;
  end;

  TVTInitNodeEvent = procedure(ASender: TfpgVirtualStringTree;
    AParentNode, ANode: PVirtualNode; var AStates: TVirtualNodeInitStates) of object;
  TVTInitChildrenEvent = procedure(ASender: TfpgVirtualStringTree;
    ANode: PVirtualNode; var AChildCount: Cardinal) of object;
  TVTNodeEvent = procedure(ASender: TfpgVirtualStringTree;
    ANode: PVirtualNode) of object;
  TVTGetNodeDataSizeEvent = procedure(ASender: TfpgVirtualStringTree;
    var ASize: Integer) of object;
  TVTGetTextEvent = procedure(ASender: TfpgVirtualStringTree;
    ANode: PVirtualNode; AColumn: TColumnIndex; var AText: string) of object;
  TVTNewTextEvent = procedure(ASender: TfpgVirtualStringTree;
    ANode: PVirtualNode; AColumn: TColumnIndex; const AText: string) of object;
  TVTCompareEvent = procedure(ASender: TfpgVirtualStringTree;
    ANode1, ANode2: PVirtualNode; AColumn: TColumnIndex;
    var AResult: Integer) of object;
  TVTDrawCellEvent = procedure(ASender: TfpgVirtualStringTree;
    ACanvas: TfpgCanvas; ANode: PVirtualNode; AColumn: TColumnIndex;
    const ARect: TfpgRect; var AHandled: Boolean) of object;
  TVTGetImageEvent = procedure(ASender: TfpgVirtualStringTree;
    ANode: PVirtualNode; AColumn: TColumnIndex; var AImage: TfpgImage) of object;
  TVTColumnEvent = procedure(ASender: TfpgVirtualStringTree;
    AColumn: TColumnIndex) of object;

  TfpgVirtualStringTree = class(TfpgWidget)
  private
    FRoot: PVirtualNode;
    FNodeDataSize: Integer;
    FDefaultNodeHeight: Word;
    FIndent: Integer;
    FHeader: TVirtualTreeHeader;
    FOptions: TVirtualTreeOptions;
    FFocusedNode, FRangeAnchor, FHotNode: PVirtualNode;
    FFocusedColumn: TColumnIndex;
    FSelection: TNodeArray;
    FSelectionCount: Integer;
    FPositionCache: TCache;
    FCacheDirty, FLayoutDirty, FChangePending: Boolean;
    FUpdateCount: Integer;
    FDestroying, FUpdatingScrollbars: Boolean;
    FScrollX, FScrollY: Integer;
    FVerticalScrollBar, FHorizontalScrollBar: TfpgScrollBar;
    FViewport: TfpgRect;
    FResizeColumn, FHeaderPressedColumn: Integer;
    FResizeStartX, FResizeStartWidth: Integer;
    FEditor: TfpgEdit;
    FChoiceEditor: TVTChoiceEditor;
    FEditingChoice: Boolean;
    FNodeGeneration: QWord;
    FEditNode: PVirtualNode;
    FEditColumn: TColumnIndex;
    FEndingEdit: Boolean;
    FSearchText: string;
    FSearchTime: QWord;
    FOnInitNode: TVTInitNodeEvent;
    FOnInitChildren: TVTInitChildrenEvent;
    FOnGetNodeDataSize: TVTGetNodeDataSizeEvent;
    FOnFreeNode, FOnChange, FOnExpanded, FOnCollapsed, FOnChecked: TVTNodeEvent;
    FOnGetText: TVTGetTextEvent;
    FOnNewText: TVTNewTextEvent;
    FOnCompareNodes: TVTCompareEvent;
    FOnDrawCell: TVTDrawCellEvent;
    FOnGetImage: TVTGetImageEvent;
    FOnHeaderClick: TVTColumnEvent;
    procedure AdjustTotalCount(ANode: PVirtualNode; ADifference: Integer);
    procedure AdjustTotalHeight(ANode: PVirtualNode; ADifference: Integer);
    procedure AdjustVisibleCount(ANode: PVirtualNode; ADifference: Integer);
    procedure ConnectNode(ANode, ADestination: PVirtualNode;
      AMode: TVTNodeAttachMode);
    procedure DisconnectNode(ANode: PVirtualNode);
    procedure FreeNode(ANode: PVirtualNode);
    procedure RemoveSubtreeReferences(ANode: PVirtualNode);
    procedure ModelChanged;
    procedure FlushChanges;
    procedure HeaderChanged(ASender: TObject);
    procedure OptionsChanged(ASender: TObject);
    procedure HorizontalScroll(ASender: TObject; APosition: Integer);
    procedure VerticalScroll(ASender: TObject; APosition: Integer);
    procedure EditorKeyPress(ASender: TObject; var AKeyCode: Word;
      var AShiftState: TShiftState; var AConsumed: Boolean);
    procedure EditorExit(ASender: TObject);
    procedure SelectRange(ANode: PVirtualNode; AKeepSelection: Boolean);
    procedure SelectFromInput(ANode: PVirtualNode; AShiftState: TShiftState);
    procedure ToggleCheck(ANode: PVirtualNode);
    procedure UpdateParentChecks(ANode: PVirtualNode);
    procedure EnsureCache;
    function NodeAtOffset(AOffset: Integer; out ATop: Integer): PVirtualNode;
    function ColumnAt(AX: Integer): Integer;
    function ColumnLeft(AColumn: Integer): Integer;
    function ColumnWidth(AColumn: Integer): Integer;
    function TotalColumnWidth: Integer;
    function ResizeColumnAt(AX: Integer): Integer;
    function NodeTop(ANode: PVirtualNode): Integer;
    function NodeRowHeight(ANode: PVirtualNode): Integer;
    function NodeChildHeight(ANode: PVirtualNode): Integer;
    function NodeChildVisibleCount(ANode: PVirtualNode): Integer;
    function NodeDisplayed(ANode: PVirtualNode): Boolean;
    function OwnsNode(ANode: PVirtualNode): Boolean;
    procedure RequireNode(ANode: PVirtualNode);
  protected
    function CanEditCell(ANode: PVirtualNode; AColumn: TColumnIndex): Boolean; virtual;
    function GetEditText(ANode: PVirtualNode; AColumn: TColumnIndex): string; virtual;
    procedure GetEditChoices(ANode: PVirtualNode; AColumn: TColumnIndex;
      AChoices: TStrings); virtual;
    function CommitEditText(ANode: PVirtualNode; AColumn: TColumnIndex;
      const AText: string): Boolean; virtual;
    function GetPendingEditText: string;
    procedure SetPendingEditText(const AText: string);
    function MakeNewNode: PVirtualNode;
    procedure InitNode(ANode: PVirtualNode);
    procedure InitChildren(ANode: PVirtualNode);
    function GetRootNodeCount: Cardinal;
    procedure SetRootNodeCount(AValue: Cardinal);
    procedure SetNodeDataSize(AValue: Integer);
    procedure SetDefaultNodeHeight(AValue: Word);
    procedure SetIndent(AValue: Integer);
    procedure SetFocusedNode(AValue: PVirtualNode);
    function GetExpanded(ANode: PVirtualNode): Boolean;
    procedure SetExpanded(ANode: PVirtualNode; AValue: Boolean);
    function GetSelected(ANode: PVirtualNode): Boolean;
    procedure SetSelected(ANode: PVirtualNode; AValue: Boolean);
    function GetVisible(ANode: PVirtualNode): Boolean;
    procedure SetNodeVisible(ANode: PVirtualNode; AValue: Boolean);
    function GetFiltered(ANode: PVirtualNode): Boolean;
    procedure SetFiltered(ANode: PVirtualNode; AValue: Boolean);
    function GetNodeHeight(ANode: PVirtualNode): Word;
    procedure SetNodeHeight(ANode: PVirtualNode; AValue: Word);
    function GetCheckState(ANode: PVirtualNode): TCheckState;
    procedure SetCheckState(ANode: PVirtualNode; AValue: TCheckState);
    function GetTotalCount: Cardinal;
    function GetVisibleCount: Cardinal;
    function GetText(ANode: PVirtualNode; AColumn: TColumnIndex): string;
    procedure SetText(ANode: PVirtualNode; AColumn: TColumnIndex;
      const AValue: string);
    function GetChildCount(ANode: PVirtualNode): Cardinal;
    procedure SetChildCount(ANode: PVirtualNode; AValue: Cardinal);
    procedure UpdateScrollBars;
    procedure DrawHeader;
    procedure DrawCell(ANode: PVirtualNode; AColumn: Integer;
      const ARect: TfpgRect); virtual;
    procedure DrawText(const AText: string; const ARect: TfpgRect;
      AAlignment: TAlignment);
    procedure DrawNodeButton(ANode: PVirtualNode; const ARect: TfpgRect);
    procedure DrawNodeCheck(ANode: PVirtualNode; const ARect: TfpgRect);
    function ButtonRect(ANode: PVirtualNode; const ACellRect: TfpgRect): TfpgRect;
    function CheckRect(ANode: PVirtualNode; const ACellRect: TfpgRect): TfpgRect;
    procedure HandlePaint; override;
    procedure HandleResize(AWidth, AHeight: TfpgCoord); override;
    procedure HandleLMouseDown(AX, AY: Integer; AShiftState: TShiftState); override;
    procedure HandleLMouseUp(AX, AY: Integer; AShiftState: TShiftState); override;
    procedure HandleRMouseDown(AX, AY: Integer; AShiftState: TShiftState); override;
    procedure HandleMouseMove(AX, AY: Integer; AButtons: Word;
      AShiftState: TShiftState); override;
    procedure HandleMouseExit; override;
    procedure HandleDoubleClick(AX, AY: Integer; AButton: Word;
      AShiftState: TShiftState); override;
    procedure HandleMouseScroll(AX, AY: Integer; AShiftState: TShiftState;
      ADelta: SmallInt); override;
    procedure HandleMouseHorizScroll(AX, AY: Integer; AShiftState: TShiftState;
      ADelta: SmallInt); override;
    procedure HandleKeyPress(var AKeyCode: Word; var AShiftState: TShiftState;
      var AConsumed: Boolean); override;
    procedure HandleKeyChar(var AText: TfpgChar; var AShiftState: TShiftState;
      var AConsumed: Boolean); override;
    procedure HandleSetFocus; override;
    procedure HandleKillFocus; override;
    procedure SetFontDesc(const AValue: string); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function AddChild(AParent: PVirtualNode; AUserData: Pointer = nil): PVirtualNode;
    function InsertNode(ANode: PVirtualNode; AMode: TVTNodeAttachMode;
      AUserData: Pointer = nil): PVirtualNode;
    procedure DeleteNode(ANode: PVirtualNode);
    procedure DeleteChildren(ANode: PVirtualNode);
    procedure Clear;
    procedure BeginUpdate;
    procedure EndUpdate;
    function GetNodeData(ANode: PVirtualNode): Pointer;
    function GetNodeLevel(ANode: PVirtualNode): Cardinal;
    function GetFirst: PVirtualNode;
    function GetLast: PVirtualNode;
    function GetFirstChild(ANode: PVirtualNode): PVirtualNode;
    function GetNext(ANode: PVirtualNode): PVirtualNode;
    function GetNextNoInit(ANode: PVirtualNode): PVirtualNode;
    function GetPrevious(ANode: PVirtualNode): PVirtualNode;
    function GetPreviousNoInit(ANode: PVirtualNode): PVirtualNode;
    function GetFirstVisible: PVirtualNode;
    function GetLastVisible: PVirtualNode;
    function GetNextVisible(ANode: PVirtualNode): PVirtualNode;
    function GetNextVisibleNoInit(ANode: PVirtualNode): PVirtualNode;
    function GetPreviousVisible(ANode: PVirtualNode): PVirtualNode;
    function GetFirstSelected: PVirtualNode;
    function GetNextSelected(ANode: PVirtualNode): PVirtualNode;
    function GetSortedSelection: TNodeArray;
    function HasAsParent(ANode, APotentialParent: PVirtualNode): Boolean;
    procedure FullExpand(ANode: PVirtualNode = nil);
    procedure FullCollapse(ANode: PVirtualNode = nil);
    procedure ToggleNode(ANode: PVirtualNode);
    procedure ClearSelection;
    procedure SelectAll(AVisibleOnly: Boolean = True);
    procedure Sort(ANode: PVirtualNode; AColumn: TColumnIndex;
      ADirection: TSortDirection);
    procedure SortTree(AColumn: TColumnIndex; ADirection: TSortDirection);
    function GetNodeAt(AX, AY: Integer): PVirtualNode;
    procedure GetHitTestInfoAt(AX, AY: Integer; out AHitInfo: THitInfo);
    function GetDisplayRect(ANode: PVirtualNode; AColumn: TColumnIndex): TfpgRect;
    function ScrollIntoView(ANode: PVirtualNode): Boolean;
    procedure InvalidateNode(ANode: PVirtualNode);
    function EditNode(ANode: PVirtualNode; AColumn: TColumnIndex): Boolean;
    function EndEditNode: Boolean;
    procedure CancelEditNode;
    property RootNode: PVirtualNode read FRoot;
    property RootNodeCount: Cardinal read GetRootNodeCount write SetRootNodeCount;
    property NodeDataSize: Integer read FNodeDataSize write SetNodeDataSize;
    property DefaultNodeHeight: Word read FDefaultNodeHeight write SetDefaultNodeHeight;
    property Indent: Integer read FIndent write SetIndent;
    property Header: TVirtualTreeHeader read FHeader;
    property TreeOptions: TVirtualTreeOptions read FOptions;
    property FocusedNode: PVirtualNode read FFocusedNode write SetFocusedNode;
    property FocusedColumn: TColumnIndex read FFocusedColumn write FFocusedColumn;
    property Expanded[ANode: PVirtualNode]: Boolean read GetExpanded write SetExpanded;
    property Selected[ANode: PVirtualNode]: Boolean read GetSelected write SetSelected;
    property IsVisible[ANode: PVirtualNode]: Boolean read GetVisible write SetNodeVisible;
    property IsFiltered[ANode: PVirtualNode]: Boolean read GetFiltered write SetFiltered;
    property NodeHeight[ANode: PVirtualNode]: Word read GetNodeHeight write SetNodeHeight;
    property CheckState[ANode: PVirtualNode]: TCheckState read GetCheckState write SetCheckState;
    property ChildCount[ANode: PVirtualNode]: Cardinal read GetChildCount write SetChildCount;
    property Text[ANode: PVirtualNode; AColumn: TColumnIndex]: string read GetText write SetText;
    property TotalCount: Cardinal read GetTotalCount;
    property VisibleCount: Cardinal read GetVisibleCount;
    property SelectedCount: Integer read FSelectionCount;
    property ScrollX: Integer read FScrollX;
    property ScrollY: Integer read FScrollY;
    property OnInitNode: TVTInitNodeEvent read FOnInitNode write FOnInitNode;
    property OnInitChildren: TVTInitChildrenEvent read FOnInitChildren write FOnInitChildren;
    property OnGetNodeDataSize: TVTGetNodeDataSizeEvent read FOnGetNodeDataSize write FOnGetNodeDataSize;
    property OnFreeNode: TVTNodeEvent read FOnFreeNode write FOnFreeNode;
    property OnGetText: TVTGetTextEvent read FOnGetText write FOnGetText;
    property OnNewText: TVTNewTextEvent read FOnNewText write FOnNewText;
    property OnCompareNodes: TVTCompareEvent read FOnCompareNodes write FOnCompareNodes;
    property OnDrawCell: TVTDrawCellEvent read FOnDrawCell write FOnDrawCell;
    property OnGetImage: TVTGetImageEvent read FOnGetImage write FOnGetImage;
    property OnChange: TVTNodeEvent read FOnChange write FOnChange;
    property OnExpanded: TVTNodeEvent read FOnExpanded write FOnExpanded;
    property OnCollapsed: TVTNodeEvent read FOnCollapsed write FOnCollapsed;
    property OnChecked: TVTNodeEvent read FOnChecked write FOnChecked;
    property OnHeaderClick: TVTColumnEvent read FOnHeaderClick write FOnHeaderClick;
  end;

implementation

constructor TfpgVirtualStringTree.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FNodeDataSize := -1;
  FDefaultNodeHeight := cVTVDefaultNodeHeight;
  FIndent := 18;
  FFocusedColumn := 0;
  FResizeColumn := -1;
  FHeaderPressedColumn := -1;
  FCacheDirty := True;
  FLayoutDirty := True;
  FRoot := AllocMem(SizeOf(TVirtualNode));
  FRoot^.States := [vsInitialized, vsChildrenInitialized, vsVisible, vsExpanded];
  FHeader := TVirtualTreeHeader.Create;
  FHeader.Columns.Add.Text := 'Name';
  FHeader.OnChange := @HeaderChanged;
  FOptions := TVirtualTreeOptions.Create;
  FOptions.OnChange := @OptionsChanged;
  FVerticalScrollBar := TfpgScrollBar.Create(Self);
  FVerticalScrollBar.Orientation := orVertical;
  FVerticalScrollBar.Visible := False;
  FVerticalScrollBar.OnScroll := @VerticalScroll;
  FHorizontalScrollBar := TfpgScrollBar.Create(Self);
  FHorizontalScrollBar.Orientation := orHorizontal;
  FHorizontalScrollBar.Visible := False;
  FHorizontalScrollBar.OnScroll := @HorizontalScroll;
  Focusable := True;
  Width := 320;
  Height := 240;
end;

destructor TfpgVirtualStringTree.Destroy;
begin
  FDestroying := True;
  CancelEditNode;
  Clear;
  FreeMem(FRoot);
  FRoot := nil;
  FHeader.Free;
  FOptions.Free;
  inherited Destroy;
end;

function TfpgVirtualStringTree.OwnsNode(ANode: PVirtualNode): Boolean;
begin
  while Assigned(ANode) and (ANode <> FRoot) do
    ANode := ANode^.Parent;
  Result := ANode = FRoot;
end;

procedure TfpgVirtualStringTree.RequireNode(ANode: PVirtualNode);
begin
  if not OwnsNode(ANode) then
    raise EArgumentException.Create('Node does not belong to this tree.');
end;

function TfpgVirtualStringTree.MakeNewNode: PVirtualNode;
begin
  if FNodeDataSize = -1 then
  begin
    FNodeDataSize := SizeOf(Pointer);
    if Assigned(FOnGetNodeDataSize) then FOnGetNodeDataSize(Self, FNodeDataSize);
    if FNodeDataSize < 0 then
      raise EArgumentException.Create('Node data size cannot be negative.');
  end;
  Result := AllocMem(SizeOf(TVirtualNode) + FNodeDataSize);
  Result^.TotalCount := 1;
  Result^.TotalHeight := FDefaultNodeHeight;
  Result^.VisibleCount := 1;
  Result^.NodeHeight := FDefaultNodeHeight;
  Result^.States := [vsVisible];
end;

procedure TfpgVirtualStringTree.AdjustTotalCount(ANode: PVirtualNode;
  ADifference: Integer);
begin
  while Assigned(ANode) do
  begin
    Inc(ANode^.TotalCount, ADifference);
    ANode := ANode^.Parent;
  end;
end;

procedure TfpgVirtualStringTree.AdjustTotalHeight(ANode: PVirtualNode;
  ADifference: Integer);
begin
  if not (vsVisible in ANode^.States) then Exit;
  repeat
    Inc(ANode^.TotalHeight, ADifference);
    if (ANode = FRoot) or not (vsVisible in ANode^.Parent^.States) or
      not (vsExpanded in ANode^.Parent^.States) then Break;
    ANode := ANode^.Parent;
  until False;
end;

procedure TfpgVirtualStringTree.AdjustVisibleCount(ANode: PVirtualNode;
  ADifference: Integer);
begin
  if not (vsVisible in ANode^.States) then Exit;
  repeat
    Inc(ANode^.VisibleCount, ADifference);
    if (ANode = FRoot) or not (vsVisible in ANode^.Parent^.States) or
      not (vsExpanded in ANode^.Parent^.States) then Break;
    ANode := ANode^.Parent;
  until False;
end;

procedure TfpgVirtualStringTree.ConnectNode(ANode, ADestination: PVirtualNode;
  AMode: TVTNodeAttachMode);
var
  lFollowing: PVirtualNode;
begin
  case AMode of
    amInsertBefore:
      begin
        ANode^.Parent := ADestination^.Parent;
        ANode^.PrevSibling := ADestination^.PrevSibling;
        ANode^.NextSibling := ADestination;
        ADestination^.PrevSibling := ANode;
        if Assigned(ANode^.PrevSibling) then
          ANode^.PrevSibling^.NextSibling := ANode
        else ANode^.Parent^.FirstChild := ANode;
        ANode^.Index := ADestination^.Index;
      end;
    amInsertAfter:
      begin
        ANode^.Parent := ADestination^.Parent;
        ANode^.NextSibling := ADestination^.NextSibling;
        ANode^.PrevSibling := ADestination;
        ADestination^.NextSibling := ANode;
        if Assigned(ANode^.NextSibling) then
          ANode^.NextSibling^.PrevSibling := ANode
        else ANode^.Parent^.LastChild := ANode;
        ANode^.Index := ADestination^.Index + 1;
      end;
    amAddChildFirst:
      begin
        ANode^.Parent := ADestination;
        ANode^.NextSibling := ADestination^.FirstChild;
        if Assigned(ANode^.NextSibling) then
          ANode^.NextSibling^.PrevSibling := ANode
        else ADestination^.LastChild := ANode;
        ADestination^.FirstChild := ANode;
        ANode^.Index := 0;
      end;
    amAddChildLast:
      begin
        ANode^.Parent := ADestination;
        ANode^.PrevSibling := ADestination^.LastChild;
        if Assigned(ANode^.PrevSibling) then
        begin
          ANode^.PrevSibling^.NextSibling := ANode;
          ANode^.Index := ANode^.PrevSibling^.Index + 1;
        end
        else ADestination^.FirstChild := ANode;
        ADestination^.LastChild := ANode;
      end;
  end;
  lFollowing := ANode^.NextSibling;
  while Assigned(lFollowing) do
  begin
    Inc(lFollowing^.Index);
    lFollowing := lFollowing^.NextSibling;
  end;
  Inc(ANode^.Parent^.ChildCount);
  Include(ANode^.Parent^.States, vsHasChildren);
  AdjustTotalCount(ANode^.Parent, ANode^.TotalCount);
  if vsExpanded in ANode^.Parent^.States then
  begin
    AdjustTotalHeight(ANode^.Parent, ANode^.TotalHeight);
    AdjustVisibleCount(ANode^.Parent, ANode^.VisibleCount);
  end;
  ModelChanged;
end;

procedure TfpgVirtualStringTree.DisconnectNode(ANode: PVirtualNode);
var
  lParent, lFollowing: PVirtualNode;
begin
  lParent := ANode^.Parent;
  AdjustTotalCount(lParent, -Integer(ANode^.TotalCount));
  if vsExpanded in lParent^.States then
  begin
    AdjustTotalHeight(lParent, -Integer(ANode^.TotalHeight));
    AdjustVisibleCount(lParent, -Integer(ANode^.VisibleCount));
  end;
  if Assigned(ANode^.PrevSibling) then
    ANode^.PrevSibling^.NextSibling := ANode^.NextSibling
  else lParent^.FirstChild := ANode^.NextSibling;
  if Assigned(ANode^.NextSibling) then
    ANode^.NextSibling^.PrevSibling := ANode^.PrevSibling
  else lParent^.LastChild := ANode^.PrevSibling;
  lFollowing := ANode^.NextSibling;
  while Assigned(lFollowing) do
  begin
    Dec(lFollowing^.Index);
    lFollowing := lFollowing^.NextSibling;
  end;
  Dec(lParent^.ChildCount);
  if lParent^.ChildCount = 0 then
    Exclude(lParent^.States, vsHasChildren);
end;

function TfpgVirtualStringTree.AddChild(AParent: PVirtualNode;
  AUserData: Pointer): PVirtualNode;
begin
  Result := InsertNode(AParent, amAddChildLast, AUserData);
end;

function TfpgVirtualStringTree.InsertNode(ANode: PVirtualNode;
  AMode: TVTNodeAttachMode; AUserData: Pointer): PVirtualNode;
begin
  if AMode = amNoWhere then Exit(nil);
  if ANode = nil then ANode := FRoot;
  RequireNode(ANode);
  if (ANode = FRoot) and (AMode in [amInsertBefore, amInsertAfter]) then
    raise EArgumentException.Create('Cannot insert beside the hidden root.');
  Result := MakeNewNode;
  try
    if Assigned(AUserData) then
    begin
      if FNodeDataSize < SizeOf(Pointer) then
        raise EArgumentException.Create('Node data cannot hold a pointer.');
      PPointer(@Result^.Data)^ := AUserData;
      Include(Result^.States, vsOnFreeNodeCallRequired);
    end;
  except
    FreeMem(Result);
    raise;
  end;
  ConnectNode(Result, ANode, AMode);
end;

function TfpgVirtualStringTree.GetNodeData(ANode: PVirtualNode): Pointer;
begin
  if (FNodeDataSize <= 0) or (ANode = nil) or (ANode = FRoot) then Exit(nil);
  Result := @ANode^.Data;
  Include(ANode^.States, vsOnFreeNodeCallRequired);
end;

procedure TfpgVirtualStringTree.FreeNode(ANode: PVirtualNode);
var
  lChild, lNext: PVirtualNode;
begin
  Inc(FNodeGeneration);
  Include(ANode^.States, vsDeleting);
  lChild := ANode^.FirstChild;
  while Assigned(lChild) do
  begin
    lNext := lChild^.NextSibling;
    FreeNode(lChild);
    lChild := lNext;
  end;
  try
    if Assigned(FOnFreeNode) and
      ([vsInitialized, vsOnFreeNodeCallRequired] * ANode^.States <> []) then
      FOnFreeNode(Self, ANode);
  finally
    FreeMem(ANode);
  end;
end;

procedure TfpgVirtualStringTree.RemoveSubtreeReferences(ANode: PVirtualNode);
var
  lIndex: Integer;
begin
  if (FEditNode = ANode) or HasAsParent(FEditNode, ANode) then CancelEditNode;
  if (FFocusedNode = ANode) or HasAsParent(FFocusedNode, ANode) then
  begin
    FFocusedNode := nil;
    FChangePending := True;
  end;
  if (FRangeAnchor = ANode) or HasAsParent(FRangeAnchor, ANode) then FRangeAnchor := nil;
  if (FHotNode = ANode) or HasAsParent(FHotNode, ANode) then FHotNode := nil;
  lIndex := 0;
  while lIndex < FSelectionCount do
    if (FSelection[lIndex] = ANode) or HasAsParent(FSelection[lIndex], ANode) then
    begin
      Exclude(FSelection[lIndex]^.States, vsSelected);
      Dec(FSelectionCount);
      FSelection[lIndex] := FSelection[FSelectionCount];
      FSelection[FSelectionCount] := nil;
      FChangePending := True;
    end
    else Inc(lIndex);
end;

procedure TfpgVirtualStringTree.DeleteNode(ANode: PVirtualNode);
begin
  if ANode = nil then Exit;
  RequireNode(ANode);
  if ANode = FRoot then
    raise EArgumentException.Create('Use Clear to delete root children.');
  if vsDeleting in ANode^.States then Exit;
  BeginUpdate;
  try
    RemoveSubtreeReferences(ANode);
    DisconnectNode(ANode);
    FCacheDirty := True;
    FreeNode(ANode);
    ModelChanged;
  finally
    EndUpdate;
  end;
end;

procedure TfpgVirtualStringTree.DeleteChildren(ANode: PVirtualNode);
begin
  if ANode = nil then ANode := FRoot;
  RequireNode(ANode);
  BeginUpdate;
  try
    while Assigned(ANode^.LastChild) do DeleteNode(ANode^.LastChild);
    Exclude(ANode^.States, vsChildrenInitialized);
  finally
    EndUpdate;
  end;
end;

procedure TfpgVirtualStringTree.Clear;
begin
  if FRoot = nil then Exit;
  BeginUpdate;
  try
    CancelEditNode;
    ClearSelection;
    FFocusedNode := nil;
    FRangeAnchor := nil;
    FHotNode := nil;
    FPositionCache := nil;
    while Assigned(FRoot^.LastChild) do DeleteNode(FRoot^.LastChild);
    FScrollX := 0;
    FScrollY := 0;
    FChangePending := True;
    ModelChanged;
  finally
    EndUpdate;
  end;
end;

procedure TfpgVirtualStringTree.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TfpgVirtualStringTree.EndUpdate;
begin
  if FUpdateCount = 0 then
    raise EInvalidOperation.Create('EndUpdate without BeginUpdate.');
  Dec(FUpdateCount);
  if FUpdateCount = 0 then FlushChanges;
end;

procedure TfpgVirtualStringTree.ModelChanged;
begin
  FCacheDirty := True;
  FLayoutDirty := True;
  if FUpdateCount = 0 then FlushChanges;
end;

procedure TfpgVirtualStringTree.FlushChanges;
begin
  if FDestroying then Exit;
  if FLayoutDirty then UpdateScrollBars;
  Invalidate;
  if FChangePending then
  begin
    FChangePending := False;
    if Assigned(FOnChange) then FOnChange(Self, FFocusedNode);
  end;
end;

procedure TfpgVirtualStringTree.InitNode(ANode: PVirtualNode);
var
  lStates: TVirtualNodeInitStates;
  lParent: PVirtualNode;
begin
  if (ANode = nil) or (vsInitialized in ANode^.States) then Exit;
  lStates := [];
  lParent := ANode^.Parent;
  if lParent = FRoot then lParent := nil;
  Include(ANode^.States, vsInitialized);
  try
    if Assigned(FOnInitNode) then FOnInitNode(Self, lParent, ANode, lStates);
  except
    Exclude(ANode^.States, vsInitialized);
    raise;
  end;
  if ivsDisabled in lStates then Include(ANode^.States, vsDisabled);
  if ivsHasChildren in lStates then Include(ANode^.States, vsHasChildren);
  if ivsMultiline in lStates then Include(ANode^.States, vsMultiline);
  if ivsFiltered in lStates then SetFiltered(ANode, True);
  if ivsSelected in lStates then SetSelected(ANode, True);
  if ivsExpanded in lStates then SetExpanded(ANode, True);
end;

procedure TfpgVirtualStringTree.InitChildren(ANode: PVirtualNode);
var
  lCount: Cardinal;
begin
  InitNode(ANode);
  if vsChildrenInitialized in ANode^.States then Exit;
  Include(ANode^.States, vsChildrenInitialized);
  lCount := ANode^.ChildCount;
  try
    if Assigned(FOnInitChildren) and (vsHasChildren in ANode^.States) then
      FOnInitChildren(Self, ANode, lCount);
    SetChildCount(ANode, lCount);
  except
    Exclude(ANode^.States, vsChildrenInitialized);
    raise;
  end;
end;

function TfpgVirtualStringTree.GetRootNodeCount: Cardinal;
begin
  Result := FRoot^.ChildCount;
end;

procedure TfpgVirtualStringTree.SetRootNodeCount(AValue: Cardinal);
begin
  SetChildCount(FRoot, AValue);
end;

function TfpgVirtualStringTree.GetChildCount(ANode: PVirtualNode): Cardinal;
begin
  if ANode = nil then ANode := FRoot;
  Result := ANode^.ChildCount;
end;

procedure TfpgVirtualStringTree.SetChildCount(ANode: PVirtualNode; AValue: Cardinal);
begin
  if ANode = nil then ANode := FRoot;
  RequireNode(ANode);
  BeginUpdate;
  try
    while ANode^.ChildCount > AValue do DeleteNode(ANode^.LastChild);
    while ANode^.ChildCount < AValue do AddChild(ANode);
  finally
    EndUpdate;
  end;
end;

procedure TfpgVirtualStringTree.SetNodeDataSize(AValue: Integer);
begin
  if AValue < -1 then
    raise EArgumentException.Create('NodeDataSize must be -1 or nonnegative.');
  if FRoot^.ChildCount <> 0 then
    raise EInvalidOperation.Create('Set NodeDataSize before allocating nodes.');
  FNodeDataSize := AValue;
end;

procedure TfpgVirtualStringTree.SetDefaultNodeHeight(AValue: Word);
begin
  if AValue = 0 then raise EArgumentException.Create('Node height cannot be zero.');
  FDefaultNodeHeight := AValue;
end;

procedure TfpgVirtualStringTree.SetIndent(AValue: Integer);
begin
  FIndent := Max(12, AValue);
  Invalidate;
end;

function TfpgVirtualStringTree.GetTotalCount: Cardinal;
begin
  Result := FRoot^.TotalCount;
end;

function TfpgVirtualStringTree.GetVisibleCount: Cardinal;
begin
  Result := FRoot^.VisibleCount;
end;

function TfpgVirtualStringTree.GetNodeLevel(ANode: PVirtualNode): Cardinal;
begin
  Result := 0;
  if (ANode = nil) or (ANode = FRoot) then Exit;
  ANode := ANode^.Parent;
  while ANode <> FRoot do
  begin
    Inc(Result);
    ANode := ANode^.Parent;
  end;
end;

function TfpgVirtualStringTree.HasAsParent(ANode,
  APotentialParent: PVirtualNode): Boolean;
begin
  Result := False;
  if ANode = nil then Exit;
  ANode := ANode^.Parent;
  while Assigned(ANode) do
  begin
    if ANode = APotentialParent then Exit(True);
    ANode := ANode^.Parent;
  end;
end;

function TfpgVirtualStringTree.GetFirst: PVirtualNode;
begin
  Result := FRoot^.FirstChild;
  InitNode(Result);
end;

function TfpgVirtualStringTree.GetLast: PVirtualNode;
begin
  Result := FRoot^.LastChild;
  if Assigned(Result) then
    while Assigned(Result^.LastChild) do Result := Result^.LastChild;
  InitNode(Result);
end;

function TfpgVirtualStringTree.GetFirstChild(ANode: PVirtualNode): PVirtualNode;
begin
  if ANode = nil then ANode := FRoot;
  InitChildren(ANode);
  Result := ANode^.FirstChild;
  InitNode(Result);
end;

function TfpgVirtualStringTree.GetNextNoInit(ANode: PVirtualNode): PVirtualNode;
begin
  Result := ANode;
  if Result = nil then Exit;
  if Assigned(Result^.FirstChild) then Exit(Result^.FirstChild);
  repeat
    if Assigned(Result^.NextSibling) then Exit(Result^.NextSibling);
    Result := Result^.Parent;
  until (Result = nil) or (Result = FRoot);
  Result := nil;
end;

function TfpgVirtualStringTree.GetNext(ANode: PVirtualNode): PVirtualNode;
begin
  Result := GetNextNoInit(ANode);
  InitNode(Result);
end;

function TfpgVirtualStringTree.GetPreviousNoInit(ANode: PVirtualNode): PVirtualNode;
begin
  if ANode = nil then Exit(nil);
  if Assigned(ANode^.PrevSibling) then
  begin
    Result := ANode^.PrevSibling;
    while Assigned(Result^.LastChild) do Result := Result^.LastChild;
  end
  else
  begin
    Result := ANode^.Parent;
    if Result = FRoot then Result := nil;
  end;
end;

function TfpgVirtualStringTree.GetPrevious(ANode: PVirtualNode): PVirtualNode;
begin
  Result := GetPreviousNoInit(ANode);
  InitNode(Result);
end;

function TfpgVirtualStringTree.NodeDisplayed(ANode: PVirtualNode): Boolean;
begin
  Result := (vsVisible in ANode^.States) and not (vsFiltered in ANode^.States);
end;

function TfpgVirtualStringTree.GetNextVisibleNoInit(ANode: PVirtualNode): PVirtualNode;
begin
  if ANode = nil then Exit(nil);
  Result := ANode;
  repeat
    if Assigned(Result^.FirstChild) and
      ([vsExpanded, vsVisible] <= Result^.States) then Result := Result^.FirstChild
    else
    begin
      while (Result <> FRoot) and not Assigned(Result^.NextSibling) do
        Result := Result^.Parent;
      if Result = FRoot then Exit(nil);
      Result := Result^.NextSibling;
    end;
  until NodeDisplayed(Result);
end;

function TfpgVirtualStringTree.GetFirstVisible: PVirtualNode;
begin
  Result := GetNextVisibleNoInit(FRoot);
  InitNode(Result);
  while Assigned(Result) and not NodeDisplayed(Result) do
  begin
    Result := GetNextVisibleNoInit(Result);
    InitNode(Result);
  end;
end;

function TfpgVirtualStringTree.GetNextVisible(ANode: PVirtualNode): PVirtualNode;
begin
  if ANode = nil then Exit(nil);
  Result := GetNextVisibleNoInit(ANode);
  InitNode(Result);
  while Assigned(Result) and not NodeDisplayed(Result) do
  begin
    Result := GetNextVisibleNoInit(Result);
    InitNode(Result);
  end;
end;

function TfpgVirtualStringTree.GetPreviousVisible(ANode: PVirtualNode): PVirtualNode;
begin
  if (ANode = nil) or (ANode = FRoot) then Exit(nil);
  Result := ANode;
  repeat
    if Result = nil then Exit;
    if Assigned(Result^.PrevSibling) then
    begin
      Result := Result^.PrevSibling;
      while Assigned(Result^.LastChild) and
        ([vsExpanded, vsVisible] <= Result^.States) do Result := Result^.LastChild;
    end
    else Result := Result^.Parent;
    if Result = FRoot then Exit(nil);
  until NodeDisplayed(Result);
  InitNode(Result);
  if not NodeDisplayed(Result) then Result := GetPreviousVisible(Result);
end;

function TfpgVirtualStringTree.GetLastVisible: PVirtualNode;
begin
  if FRoot^.LastChild = nil then Exit(nil);
  Result := FRoot^.LastChild;
  while Assigned(Result^.LastChild) and
    ([vsExpanded, vsVisible] <= Result^.States) do Result := Result^.LastChild;
  if not NodeDisplayed(Result) then Result := GetPreviousVisible(Result);
  InitNode(Result);
  if Assigned(Result) and not NodeDisplayed(Result) then Result := GetPreviousVisible(Result);
end;

function TfpgVirtualStringTree.NodeRowHeight(ANode: PVirtualNode): Integer;
begin
  if NodeDisplayed(ANode) then Result := ANode^.NodeHeight else Result := 0;
end;

function TfpgVirtualStringTree.NodeChildHeight(ANode: PVirtualNode): Integer;
var
  lChild: PVirtualNode;
begin
  Result := 0;
  lChild := ANode^.FirstChild;
  while Assigned(lChild) do
  begin
    Inc(Result, lChild^.TotalHeight);
    lChild := lChild^.NextSibling;
  end;
end;

function TfpgVirtualStringTree.NodeChildVisibleCount(ANode: PVirtualNode): Integer;
var
  lChild: PVirtualNode;
begin
  Result := 0;
  lChild := ANode^.FirstChild;
  while Assigned(lChild) do
  begin
    Inc(Result, lChild^.VisibleCount);
    lChild := lChild^.NextSibling;
  end;
end;

function TfpgVirtualStringTree.GetExpanded(ANode: PVirtualNode): Boolean;
begin
  Result := Assigned(ANode) and (vsExpanded in ANode^.States);
end;

procedure TfpgVirtualStringTree.SetExpanded(ANode: PVirtualNode; AValue: Boolean);
begin
  RequireNode(ANode);
  if ANode = FRoot then Exit;
  InitNode(ANode);
  if GetExpanded(ANode) = AValue then Exit;
  BeginUpdate;
  try
    if AValue then
    begin
      InitChildren(ANode);
      Include(ANode^.States, vsExpanded);
      if vsVisible in ANode^.States then
      begin
        AdjustTotalHeight(ANode, NodeChildHeight(ANode));
        AdjustVisibleCount(ANode, NodeChildVisibleCount(ANode));
      end;
      if Assigned(FOnExpanded) then FOnExpanded(Self, ANode);
    end
    else
    begin
      if (FEditNode <> nil) and HasAsParent(FEditNode, ANode) then CancelEditNode;
      if HasAsParent(FFocusedNode, ANode) then SetFocusedNode(ANode);
      Exclude(ANode^.States, vsExpanded);
      if vsVisible in ANode^.States then
      begin
        AdjustTotalHeight(ANode, -NodeChildHeight(ANode));
        AdjustVisibleCount(ANode, -NodeChildVisibleCount(ANode));
      end;
      if Assigned(FOnCollapsed) then FOnCollapsed(Self, ANode);
    end;
    ModelChanged;
  finally
    EndUpdate;
  end;
end;

procedure TfpgVirtualStringTree.ToggleNode(ANode: PVirtualNode);
begin
  if ANode <> nil then SetExpanded(ANode, not GetExpanded(ANode));
end;

procedure TfpgVirtualStringTree.FullExpand(ANode: PVirtualNode);
var
  lChild: PVirtualNode;
begin
  if ANode = nil then ANode := FRoot;
  BeginUpdate;
  try
    if ANode <> FRoot then SetExpanded(ANode, True);
    lChild := ANode^.FirstChild;
    while Assigned(lChild) do
    begin
      FullExpand(lChild);
      lChild := lChild^.NextSibling;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TfpgVirtualStringTree.FullCollapse(ANode: PVirtualNode);
var
  lChild: PVirtualNode;
begin
  if ANode = nil then ANode := FRoot;
  BeginUpdate;
  try
    lChild := ANode^.FirstChild;
    while Assigned(lChild) do
    begin
      FullCollapse(lChild);
      lChild := lChild^.NextSibling;
    end;
    if ANode <> FRoot then SetExpanded(ANode, False);
  finally
    EndUpdate;
  end;
end;

function TfpgVirtualStringTree.GetVisible(ANode: PVirtualNode): Boolean;
begin
  Result := vsVisible in ANode^.States;
end;

procedure TfpgVirtualStringTree.SetNodeVisible(ANode: PVirtualNode; AValue: Boolean);
var
  lHeight, lCount: Integer;
begin
  RequireNode(ANode);
  if (ANode = FRoot) or (GetVisible(ANode) = AValue) then Exit;
  lHeight := ANode^.TotalHeight;
  lCount := ANode^.VisibleCount;
  if AValue then
  begin
    Include(ANode^.States, vsVisible);
    ANode^.TotalHeight := NodeRowHeight(ANode);
    ANode^.VisibleCount := Ord(NodeDisplayed(ANode));
    if vsExpanded in ANode^.States then
    begin
      Inc(ANode^.TotalHeight, NodeChildHeight(ANode));
      Inc(ANode^.VisibleCount, NodeChildVisibleCount(ANode));
    end;
  end
  else
  begin
    Exclude(ANode^.States, vsVisible);
    ANode^.TotalHeight := 0;
    ANode^.VisibleCount := 0;
  end;
  if vsExpanded in ANode^.Parent^.States then
  begin
    AdjustTotalHeight(ANode^.Parent, Integer(ANode^.TotalHeight) - lHeight);
    AdjustVisibleCount(ANode^.Parent, Integer(ANode^.VisibleCount) - lCount);
  end;
  ModelChanged;
end;

function TfpgVirtualStringTree.GetFiltered(ANode: PVirtualNode): Boolean;
begin
  Result := vsFiltered in ANode^.States;
end;

procedure TfpgVirtualStringTree.SetFiltered(ANode: PVirtualNode; AValue: Boolean);
var
  lHeight, lCount: Integer;
begin
  RequireNode(ANode);
  if (ANode = FRoot) or (GetFiltered(ANode) = AValue) then Exit;
  lHeight := NodeRowHeight(ANode);
  lCount := Ord(NodeDisplayed(ANode));
  if AValue then Include(ANode^.States, vsFiltered)
  else Exclude(ANode^.States, vsFiltered);
  AdjustTotalHeight(ANode, NodeRowHeight(ANode) - lHeight);
  AdjustVisibleCount(ANode, Ord(NodeDisplayed(ANode)) - lCount);
  ModelChanged;
end;

function TfpgVirtualStringTree.GetNodeHeight(ANode: PVirtualNode): Word;
begin
  Result := ANode^.NodeHeight;
end;

procedure TfpgVirtualStringTree.SetNodeHeight(ANode: PVirtualNode; AValue: Word);
var
  lOldHeight: Integer;
begin
  RequireNode(ANode);
  if AValue = 0 then raise EArgumentException.Create('Node height cannot be zero.');
  lOldHeight := NodeRowHeight(ANode);
  ANode^.NodeHeight := AValue;
  AdjustTotalHeight(ANode, NodeRowHeight(ANode) - lOldHeight);
  ModelChanged;
end;

function TfpgVirtualStringTree.GetText(ANode: PVirtualNode;
  AColumn: TColumnIndex): string;
begin
  Result := '';
  InitNode(ANode);
  if Assigned(ANode) and Assigned(FOnGetText) then
    FOnGetText(Self, ANode, AColumn, Result);
end;

procedure TfpgVirtualStringTree.SetText(ANode: PVirtualNode;
  AColumn: TColumnIndex; const AValue: string);
begin
  RequireNode(ANode);
  InitNode(ANode);
  if not Assigned(FOnNewText) then
    raise EInvalidOperation.Create('OnNewText is required to update virtual text.');
  FOnNewText(Self, ANode, AColumn, AValue);
  { A virtual-text callback may replace the model, including this node. }
  Invalidate;
end;

procedure TfpgVirtualStringTree.SetFocusedNode(AValue: PVirtualNode);
begin
  if Assigned(AValue) then RequireNode(AValue);
  if AValue = FRoot then AValue := nil;
  if FFocusedNode = AValue then Exit;
  FFocusedNode := AValue;
  InitNode(AValue);
  FChangePending := True;
  if FUpdateCount = 0 then FlushChanges;
end;

function TfpgVirtualStringTree.GetSelected(ANode: PVirtualNode): Boolean;
begin
  Result := Assigned(ANode) and (vsSelected in ANode^.States);
end;

procedure TfpgVirtualStringTree.SetSelected(ANode: PVirtualNode; AValue: Boolean);
var
  lIndex: Integer;
begin
  RequireNode(ANode);
  if (ANode = FRoot) or (GetSelected(ANode) = AValue) then Exit;
  if AValue then
  begin
    if vsDisabled in ANode^.States then Exit;
    if FSelectionCount = Length(FSelection) then
      SetLength(FSelection, Max(16, FSelectionCount * 2));
    FSelection[FSelectionCount] := ANode;
    Inc(FSelectionCount);
    Include(ANode^.States, vsSelected);
  end
  else
  begin
    lIndex := 0;
    while FSelection[lIndex] <> ANode do Inc(lIndex);
    Dec(FSelectionCount);
    FSelection[lIndex] := FSelection[FSelectionCount];
    FSelection[FSelectionCount] := nil;
    Exclude(ANode^.States, vsSelected);
  end;
  FChangePending := True;
  if FUpdateCount = 0 then FlushChanges;
end;

procedure TfpgVirtualStringTree.ClearSelection;
var
  lIndex: Integer;
begin
  if FSelectionCount = 0 then Exit;
  for lIndex := 0 to FSelectionCount - 1 do
  begin
    Exclude(FSelection[lIndex]^.States, vsSelected);
    FSelection[lIndex] := nil;
  end;
  FSelectionCount := 0;
  FChangePending := True;
  if FUpdateCount = 0 then FlushChanges;
end;

function TfpgVirtualStringTree.GetFirstSelected: PVirtualNode;
begin
  Result := FRoot^.FirstChild;
  while Assigned(Result) and not GetSelected(Result) do Result := GetNextNoInit(Result);
end;

function TfpgVirtualStringTree.GetNextSelected(ANode: PVirtualNode): PVirtualNode;
begin
  Result := GetNextNoInit(ANode);
  while Assigned(Result) and not GetSelected(Result) do Result := GetNextNoInit(Result);
end;

function TfpgVirtualStringTree.GetSortedSelection: TNodeArray;
var
  lNode: PVirtualNode;
  lIndex: Integer;
begin
  Result := nil;
  SetLength(Result, FSelectionCount);
  lIndex := 0;
  lNode := GetFirstSelected;
  while Assigned(lNode) do
  begin
    Result[lIndex] := lNode;
    Inc(lIndex);
    lNode := GetNextSelected(lNode);
  end;
end;

procedure TfpgVirtualStringTree.SelectAll(AVisibleOnly: Boolean);
var
  lNode: PVirtualNode;
begin
  BeginUpdate;
  try
    if AVisibleOnly then lNode := GetFirstVisible else lNode := GetFirst;
    while Assigned(lNode) do
    begin
      SetSelected(lNode, True);
      if AVisibleOnly then lNode := GetNextVisible(lNode) else lNode := GetNext(lNode);
    end;
  finally
    EndUpdate;
  end;
end;

procedure TfpgVirtualStringTree.Sort(ANode: PVirtualNode; AColumn: TColumnIndex;
  ADirection: TSortDirection);

  function Merge(ALeft, ARight: PVirtualNode): PVirtualNode;
  var
    lDummy: TVirtualNode;
    lTail: PVirtualNode;
    lCompare: Integer;
  begin
    lDummy.NextSibling := nil;
    lTail := @lDummy;
    while Assigned(ALeft) and Assigned(ARight) do
    begin
      lCompare := 0;
      FOnCompareNodes(Self, ALeft, ARight, AColumn, lCompare);
      if ((ADirection = sdAscending) and (lCompare <= 0)) or
        ((ADirection = sdDescending) and (lCompare >= 0)) then
      begin
        lTail^.NextSibling := ALeft;
        lTail := ALeft;
        ALeft := ALeft^.NextSibling;
      end
      else
      begin
        lTail^.NextSibling := ARight;
        lTail := ARight;
        ARight := ARight^.NextSibling;
      end;
    end;
    if Assigned(ALeft) then lTail^.NextSibling := ALeft
    else lTail^.NextSibling := ARight;
    Result := lDummy.NextSibling;
  end;

  function MergeSort(var AFirst: PVirtualNode; ACount: Cardinal): PVirtualNode;
  var
    lLeft, lRight: PVirtualNode;
  begin
    if ACount > 1 then
    begin
      lLeft := MergeSort(AFirst, ACount div 2);
      lRight := MergeSort(AFirst, (ACount + 1) div 2);
      Result := Merge(lLeft, lRight);
    end
    else
    begin
      Result := AFirst;
      AFirst := AFirst^.NextSibling;
      Result^.NextSibling := nil;
    end;
  end;

  procedure Relink(const ANodes: TNodeArray);
  var
    lIndex: Integer;
  begin
    ANode^.FirstChild := ANodes[0];
    ANode^.LastChild := ANodes[High(ANodes)];
    for lIndex := 0 to High(ANodes) do
    begin
      ANodes[lIndex]^.Index := lIndex;
      if lIndex = 0 then ANodes[lIndex]^.PrevSibling := nil
      else ANodes[lIndex]^.PrevSibling := ANodes[lIndex - 1];
      if lIndex = High(ANodes) then ANodes[lIndex]^.NextSibling := nil
      else ANodes[lIndex]^.NextSibling := ANodes[lIndex + 1];
    end;
  end;

var
  lRun, lPrevious: PVirtualNode;
  lIndex: Cardinal;
  lOriginal: TNodeArray;
begin
  if not Assigned(FOnCompareNodes) then
    raise EInvalidOperation.Create('OnCompareNodes is required for virtual sorting.');
  if ANode = nil then ANode := FRoot;
  RequireNode(ANode);
  InitChildren(ANode);
  if ANode^.ChildCount < 2 then Exit;
  lRun := ANode^.FirstChild;
  SetLength(lOriginal, ANode^.ChildCount);
  lIndex := 0;
  while Assigned(lRun) do
  begin
    InitNode(lRun);
    lOriginal[lIndex] := lRun;
    Inc(lIndex);
    lRun := lRun^.NextSibling;
  end;
  try
    ANode^.FirstChild := MergeSort(ANode^.FirstChild, ANode^.ChildCount);
  except
    Relink(lOriginal);
    raise;
  end;
  lRun := ANode^.FirstChild;
  lPrevious := nil;
  lIndex := 0;
  while Assigned(lRun) do
  begin
    lRun^.Index := lIndex;
    lRun^.PrevSibling := lPrevious;
    lPrevious := lRun;
    lRun := lRun^.NextSibling;
    Inc(lIndex);
  end;
  ANode^.LastChild := lPrevious;
  ModelChanged;
end;

procedure TfpgVirtualStringTree.SortTree(AColumn: TColumnIndex;
  ADirection: TSortDirection);
var
  lNode: PVirtualNode;
begin
  BeginUpdate;
  try
    Sort(FRoot, AColumn, ADirection);
    lNode := FRoot^.FirstChild;
    while Assigned(lNode) do
    begin
      if lNode^.ChildCount > 1 then Sort(lNode, AColumn, ADirection);
      lNode := GetNextNoInit(lNode);
    end;
  finally
    EndUpdate;
  end;
end;

function TfpgVirtualStringTree.GetCheckState(ANode: PVirtualNode): TCheckState;
begin
  Result := ANode^.CheckState;
end;

procedure TfpgVirtualStringTree.SetCheckState(ANode: PVirtualNode; AValue: TCheckState);
var
  lNode: PVirtualNode;
begin
  RequireNode(ANode);
  if ANode = FRoot then Exit;
  if ANode^.CheckState = AValue then Exit;
  BeginUpdate;
  try
    ANode^.CheckState := AValue;
    if (ANode^.CheckType = ctRadioButton) and (AValue = csCheckedNormal) then
    begin
      lNode := ANode^.Parent^.FirstChild;
      while Assigned(lNode) do
      begin
        if (lNode <> ANode) and (lNode^.CheckType = ctRadioButton) then
          SetCheckState(lNode, csUncheckedNormal);
        lNode := lNode^.NextSibling;
      end;
    end;
    if (toAutoTristateTracking in FOptions.AutoOptions) and
      (ANode^.CheckType = ctTriStateCheckBox) and
      (AValue in [csCheckedNormal, csUncheckedNormal]) then
    begin
      Include(ANode^.States, vsChecking);
      try
        lNode := ANode^.FirstChild;
        while Assigned(lNode) do
        begin
          if lNode^.CheckType in [ctCheckBox, ctTriStateCheckBox] then
            SetCheckState(lNode, AValue);
          lNode := lNode^.NextSibling;
        end;
      finally
        Exclude(ANode^.States, vsChecking);
      end;
    end;
    UpdateParentChecks(ANode);
    if Assigned(FOnChecked) then FOnChecked(Self, ANode);
    Invalidate;
  finally
    EndUpdate;
  end;
end;

procedure TfpgVirtualStringTree.UpdateParentChecks(ANode: PVirtualNode);
var
  lParent, lChild: PVirtualNode;
  lState: TCheckState;
  lFound: Boolean;
begin
  if not (toAutoTristateTracking in FOptions.AutoOptions) then Exit;
  lParent := ANode^.Parent;
  while (lParent <> FRoot) and (lParent^.CheckType = ctTriStateCheckBox) and
    not (vsChecking in lParent^.States) do
  begin
    lState := csUncheckedNormal;
    lFound := False;
    lChild := lParent^.FirstChild;
    while Assigned(lChild) do
    begin
      if lChild^.CheckType in [ctCheckBox, ctTriStateCheckBox] then
        if not lFound then
        begin
          lState := lChild^.CheckState;
          lFound := True;
        end
        else if lState <> lChild^.CheckState then lState := csMixedNormal;
      lChild := lChild^.NextSibling;
    end;
    if lParent^.CheckState <> lState then
    begin
      lParent^.CheckState := lState;
      if Assigned(FOnChecked) then FOnChecked(Self, lParent);
    end;
    lParent := lParent^.Parent;
  end;
end;

procedure TfpgVirtualStringTree.ToggleCheck(ANode: PVirtualNode);
begin
  if (ANode = nil) or (vsDisabled in ANode^.States) or
    (toReadOnly in FOptions.MiscOptions) then Exit;
  if ANode^.CheckState = csCheckedNormal then
  begin
    if ANode^.CheckType <> ctRadioButton then SetCheckState(ANode, csUncheckedNormal);
  end
  else SetCheckState(ANode, csCheckedNormal);
end;

procedure TfpgVirtualStringTree.EnsureCache;
var
  lNode: PVirtualNode;
  lTop, lRow, lCount: Integer;
begin
  if not FCacheDirty then Exit;
  FPositionCache := nil;
  lCount := 0;
  lRow := 0;
  lTop := 0;
  lNode := GetNextVisibleNoInit(FRoot);
  while Assigned(lNode) do
  begin
    if lRow mod cVTVCacheStride = 0 then
    begin
      if lCount = Length(FPositionCache) then
        SetLength(FPositionCache, Max(16, lCount * 2));
      FPositionCache[lCount].Node := lNode;
      FPositionCache[lCount].AbsoluteTop := lTop;
      Inc(lCount);
    end;
    Inc(lTop, lNode^.NodeHeight);
    Inc(lRow);
    lNode := GetNextVisibleNoInit(lNode);
  end;
  SetLength(FPositionCache, lCount);
  FCacheDirty := False;
end;

function TfpgVirtualStringTree.NodeAtOffset(AOffset: Integer;
  out ATop: Integer): PVirtualNode;
var
  lLow, lHigh, lMiddle: Integer;
begin
  Result := nil;
  ATop := 0;
  if (AOffset < 0) or (AOffset >= Integer(FRoot^.TotalHeight)) then Exit;
  EnsureCache;
  if Length(FPositionCache) = 0 then Exit;
  lLow := 0;
  lHigh := High(FPositionCache);
  while lLow < lHigh do
  begin
    lMiddle := (lLow + lHigh + 1) div 2;
    if FPositionCache[lMiddle].AbsoluteTop <= AOffset then lLow := lMiddle
    else lHigh := lMiddle - 1;
  end;
  Result := FPositionCache[lLow].Node;
  ATop := FPositionCache[lLow].AbsoluteTop;
  while Assigned(Result) and (ATop + Result^.NodeHeight <= AOffset) do
  begin
    Inc(ATop, Result^.NodeHeight);
    Result := GetNextVisibleNoInit(Result);
  end;
end;

function TfpgVirtualStringTree.ColumnLeft(AColumn: Integer): Integer;
var
  lIndex: Integer;
begin
  Result := FViewport.Left - FScrollX;
  for lIndex := 0 to AColumn - 1 do
    if FHeader.Columns[lIndex].Visible then Inc(Result, FHeader.Columns[lIndex].Width);
end;

function TfpgVirtualStringTree.ColumnWidth(AColumn: Integer): Integer;
begin
  if FHeader.Columns.Count = 0 then Result := Max(0, FViewport.Width)
  else Result := FHeader.Columns[AColumn].Width;
end;

function TfpgVirtualStringTree.TotalColumnWidth: Integer;
var
  lIndex: Integer;
begin
  Result := 0;
  for lIndex := 0 to FHeader.Columns.Count - 1 do
    if FHeader.Columns[lIndex].Visible then Inc(Result, FHeader.Columns[lIndex].Width);
end;

function TfpgVirtualStringTree.ColumnAt(AX: Integer): Integer;
var
  lLeft, lIndex: Integer;
begin
  Result := cNoColumn;
  if (AX < FViewport.Left) or (AX >= FViewport.Right) then Exit;
  if FHeader.Columns.Count = 0 then Exit(0);
  lLeft := FViewport.Left - FScrollX;
  for lIndex := 0 to FHeader.Columns.Count - 1 do
    if FHeader.Columns[lIndex].Visible then
    begin
      if (AX >= lLeft) and (AX < lLeft + FHeader.Columns[lIndex].Width) then Exit(lIndex);
      Inc(lLeft, FHeader.Columns[lIndex].Width);
    end;
end;

function TfpgVirtualStringTree.ResizeColumnAt(AX: Integer): Integer;
var
  lIndex, lLeft: Integer;
begin
  Result := -1;
  lLeft := FViewport.Left - FScrollX;
  for lIndex := 0 to FHeader.Columns.Count - 1 do
    if FHeader.Columns[lIndex].Visible then
    begin
      Inc(lLeft, FHeader.Columns[lIndex].Width);
      if Abs(AX - lLeft) <= 4 then Exit(lIndex);
    end;
end;

procedure TfpgVirtualStringTree.UpdateScrollBars;
var
  lWidth, lHeight, lHeaderHeight, lPass: Integer;
  lVertical, lHorizontal: Boolean;
begin
  if (FHeader = nil) or (FVerticalScrollBar = nil) then Exit;
  FLayoutDirty := False;
  lHeaderHeight := 0;
  if FHeader.Visible and (FHeader.Columns.Count > 0) then lHeaderHeight := FHeader.Height;
  lVertical := False;
  lHorizontal := False;
  for lPass := 1 to 3 do
  begin
    lWidth := Max(0, ActualWidth - 2 - Ord(lVertical) * FVerticalScrollBar.Width);
    lHeight := Max(0, ActualHeight - 2 - lHeaderHeight -
      Ord(lHorizontal) * FHorizontalScrollBar.Height);
    lVertical := FRoot^.TotalHeight > Cardinal(lHeight);
    lHorizontal := TotalColumnWidth > lWidth;
  end;
  lWidth := Max(0, ActualWidth - 2 - Ord(lVertical) * FVerticalScrollBar.Width);
  lHeight := Max(0, ActualHeight - 2 - lHeaderHeight -
    Ord(lHorizontal) * FHorizontalScrollBar.Height);
  FViewport.SetRect(1, 1 + lHeaderHeight, lWidth, lHeight);
  FUpdatingScrollbars := True;
  try
    FVerticalScrollBar.Visible := lVertical;
    FHorizontalScrollBar.Visible := lHorizontal;
    FVerticalScrollBar.Left := FViewport.Right;
    FVerticalScrollBar.Top := FViewport.Top;
    FVerticalScrollBar.Height := lHeight;
    FHorizontalScrollBar.Left := FViewport.Left;
    FHorizontalScrollBar.Top := FViewport.Bottom;
    FHorizontalScrollBar.Width := lWidth;
    FScrollY := EnsureRange(FScrollY, 0, Max(0, Integer(FRoot^.TotalHeight) - lHeight));
    FScrollX := EnsureRange(FScrollX, 0, Max(0, TotalColumnWidth - lWidth));
    FVerticalScrollBar.Min := 0;
    FVerticalScrollBar.Max := Max(0, Integer(FRoot^.TotalHeight) - lHeight);
    FVerticalScrollBar.Position := FScrollY;
    FVerticalScrollBar.ScrollStep := FDefaultNodeHeight;
    FVerticalScrollBar.PageSize := Max(1, lHeight);
    if FRoot^.TotalHeight = 0 then FVerticalScrollBar.SliderSize := 1
    else FVerticalScrollBar.SliderSize := Min(1, lHeight / FRoot^.TotalHeight);
    FHorizontalScrollBar.Min := 0;
    FHorizontalScrollBar.Max := Max(0, TotalColumnWidth - lWidth);
    FHorizontalScrollBar.Position := FScrollX;
    FHorizontalScrollBar.ScrollStep := FIndent;
    FHorizontalScrollBar.PageSize := Max(1, lWidth);
    if TotalColumnWidth = 0 then FHorizontalScrollBar.SliderSize := 1
    else FHorizontalScrollBar.SliderSize := Min(1, lWidth / TotalColumnWidth);
  finally
    FUpdatingScrollbars := False;
  end;
end;

procedure TfpgVirtualStringTree.HeaderChanged(ASender: TObject);
begin
  CancelEditNode;
  FLayoutDirty := True;
  if FUpdateCount = 0 then FlushChanges;
end;

procedure TfpgVirtualStringTree.OptionsChanged(ASender: TObject);
begin
  CancelEditNode;
  Invalidate;
end;

procedure TfpgVirtualStringTree.HorizontalScroll(ASender: TObject; APosition: Integer);
begin
  if FUpdatingScrollbars then Exit;
  CancelEditNode;
  FScrollX := APosition;
  Invalidate;
end;

procedure TfpgVirtualStringTree.VerticalScroll(ASender: TObject; APosition: Integer);
begin
  if FUpdatingScrollbars then Exit;
  CancelEditNode;
  FScrollY := APosition;
  Invalidate;
end;

function TfpgVirtualStringTree.NodeTop(ANode: PVirtualNode): Integer;
var
  lSibling, lParent: PVirtualNode;
begin
  Result := 0;
  while ANode <> FRoot do
  begin
    lSibling := ANode^.PrevSibling;
    while Assigned(lSibling) do
    begin
      Inc(Result, lSibling^.TotalHeight);
      lSibling := lSibling^.PrevSibling;
    end;
    lParent := ANode^.Parent;
    if lParent <> FRoot then
    begin
      if not ([vsVisible, vsExpanded] <= lParent^.States) then Exit(-1);
      Inc(Result, NodeRowHeight(lParent));
    end;
    ANode := lParent;
  end;
end;

function TfpgVirtualStringTree.GetDisplayRect(ANode: PVirtualNode;
  AColumn: TColumnIndex): TfpgRect;
var
  lTop: Integer;
begin
  Result.SetRect(0, 0, 0, 0);
  if (ANode = nil) or (ANode = FRoot) or not NodeDisplayed(ANode) then Exit;
  lTop := NodeTop(ANode);
  if lTop < 0 then Exit;
  if AColumn = cNoColumn then
    Result.SetRect(FViewport.Left, FViewport.Top + lTop - FScrollY,
      FViewport.Width, ANode^.NodeHeight)
  else
  begin
    if (AColumn < 0) or (AColumn >= Max(1, FHeader.Columns.Count)) then Exit;
    Result.SetRect(ColumnLeft(AColumn), FViewport.Top + lTop - FScrollY,
      ColumnWidth(AColumn), ANode^.NodeHeight);
  end;
end;

function TfpgVirtualStringTree.GetNodeAt(AX, AY: Integer): PVirtualNode;
var
  lTop: Integer;
  lPrevious: PVirtualNode;
begin
  if FLayoutDirty then UpdateScrollBars;
  if not FViewport.PointInRect(Point(AX, AY)) then Exit(nil);
  Result := NodeAtOffset(AY - FViewport.Top + FScrollY, lTop);
  repeat
    lPrevious := Result;
    InitNode(Result);
    if FCacheDirty then Result := NodeAtOffset(AY - FViewport.Top + FScrollY, lTop);
  until (Result = nil) or (Result = lPrevious);
end;

function TfpgVirtualStringTree.ButtonRect(ANode: PVirtualNode;
  const ACellRect: TfpgRect): TfpgRect;
begin
  Result.SetRect(ACellRect.Left + GetNodeLevel(ANode) * FIndent + 4,
    ACellRect.Top + (ACellRect.Height - 10) div 2, 10, 10);
end;

function TfpgVirtualStringTree.CheckRect(ANode: PVirtualNode;
  const ACellRect: TfpgRect): TfpgRect;
begin
  Result.SetRect(ACellRect.Left + (GetNodeLevel(ANode) + 1) * FIndent + 3,
    ACellRect.Top + (ACellRect.Height - 14) div 2, 14, 14);
end;

procedure TfpgVirtualStringTree.GetHitTestInfoAt(AX, AY: Integer;
  out AHitInfo: THitInfo);
var
  lRect: TfpgRect;
begin
  AHitInfo.HitNode := nil;
  AHitInfo.HitColumn := cNoColumn;
  AHitInfo.HitPositions := [hiNowhere];
  AHitInfo.HitPoint := Point(AX, AY);
  if FLayoutDirty then UpdateScrollBars;
  AHitInfo.HitColumn := ColumnAt(AX);
  if (AY >= 1) and (AY < FViewport.Top) and
    (AX >= FViewport.Left) and (AX < FViewport.Right) then
  begin
    if AHitInfo.HitColumn = cNoColumn then
      AHitInfo.HitColumn := ResizeColumnAt(AX);
    if AHitInfo.HitColumn <> cNoColumn then
      AHitInfo.HitPositions := [hiOnHeader];
    Exit;
  end;
  AHitInfo.HitNode := GetNodeAt(AX, AY);
  if (AHitInfo.HitNode = nil) or (AHitInfo.HitColumn = cNoColumn) then Exit;
  AHitInfo.HitPositions := [hiOnItem, hiOnItemLabel];
  if AHitInfo.HitColumn <> FHeader.MainColumn then Exit;
  lRect := GetDisplayRect(AHitInfo.HitNode, AHitInfo.HitColumn);
  if (toShowButtons in FOptions.PaintOptions) and
    (vsHasChildren in AHitInfo.HitNode^.States) and
    ButtonRect(AHitInfo.HitNode, lRect).PointInRect(AHitInfo.HitPoint) then
    AHitInfo.HitPositions := [hiOnItem, hiOnItemButton];
  if (toCheckSupport in FOptions.MiscOptions) and
    (AHitInfo.HitNode^.CheckType <> ctNone) and
    CheckRect(AHitInfo.HitNode, lRect).PointInRect(AHitInfo.HitPoint) then
    AHitInfo.HitPositions := [hiOnItem, hiOnItemCheckbox];
end;

function TfpgVirtualStringTree.ScrollIntoView(ANode: PVirtualNode): Boolean;
var
  lAncestors: TNodeArray;
  lParent: PVirtualNode;
  lCount, lIndex, lTop, lOldScroll: Integer;
begin
  Result := False;
  if (ANode = nil) or (ANode = FRoot) then Exit;
  RequireNode(ANode);
  lCount := 0;
  lParent := ANode^.Parent;
  while lParent <> FRoot do
  begin
    SetLength(lAncestors, lCount + 1);
    lAncestors[lCount] := lParent;
    Inc(lCount);
    lParent := lParent^.Parent;
  end;
  BeginUpdate;
  try
    for lIndex := lCount - 1 downto 0 do SetExpanded(lAncestors[lIndex], True);
  finally
    EndUpdate;
  end;
  if not NodeDisplayed(ANode) then Exit;
  if FLayoutDirty then UpdateScrollBars;
  lTop := NodeTop(ANode);
  if lTop < 0 then Exit;
  lOldScroll := FScrollY;
  if lTop < FScrollY then FScrollY := lTop
  else if lTop + ANode^.NodeHeight > FScrollY + FViewport.Height then
    FScrollY := Max(0, lTop + ANode^.NodeHeight - FViewport.Height);
  UpdateScrollBars;
  Result := lOldScroll <> FScrollY;
  if Result then Invalidate;
end;

procedure TfpgVirtualStringTree.InvalidateNode(ANode: PVirtualNode);
var
  lRect: TfpgRect;
begin
  lRect := GetDisplayRect(ANode, cNoColumn);
  if (lRect.Height > 0) and (lRect.Top < FViewport.Bottom) and
    (lRect.Bottom > FViewport.Top) then Invalidate;
end;

procedure TfpgVirtualStringTree.DrawText(const AText: string;
  const ARect: TfpgRect; AAlignment: TAlignment);
var
  lX, lY: Integer;
begin
  lX := ARect.Left + 4;
  case AAlignment of
    taRightJustify: lX := ARect.Right - Font.GetTextWidth(AText) - 4;
    taCenter: lX := ARect.Left + (ARect.Width - Font.GetTextWidth(AText)) div 2;
  end;
  lY := ARect.Top + (ARect.Height - Font.GetHeight) div 2;
  Canvas.DrawString(lX, lY, AText);
end;

procedure TfpgVirtualStringTree.DrawHeader;
var
  lColumn: Integer;
  lRect, lClip, lHeaderClip: TfpgRect;
begin
  if not FHeader.Visible or (FHeader.Columns.Count = 0) then Exit;
  lClip := Canvas.GetClipRect;
  lRect.SetRect(FViewport.Left, 1, FViewport.Width, FHeader.Height);
  lHeaderClip := lRect;
  Canvas.AddClipRect(lRect);
  Canvas.SetColor(clGridHeader);
  Canvas.FillRectangle(lRect);
  Canvas.SetFont(Font);
  Canvas.SetTextColor(clText1);
  for lColumn := 0 to FHeader.Columns.Count - 1 do
    if FHeader.Columns[lColumn].Visible then
    begin
      lRect.SetRect(ColumnLeft(lColumn), 1, ColumnWidth(lColumn), FHeader.Height);
      if (lRect.Right <= FViewport.Left) or (lRect.Left >= FViewport.Right) then Continue;
      Canvas.SetClipRect(lClip);
      Canvas.AddClipRect(lHeaderClip);
      Canvas.AddClipRect(lRect);
      DrawText(FHeader.Columns[lColumn].Text, lRect, FHeader.Columns[lColumn].Alignment);
      Canvas.SetColor(clGridLines);
      Canvas.DrawLine(lRect.Right - 1, lRect.Top, lRect.Right - 1, lRect.Bottom - 1);
      if FHeader.SortColumn = lColumn then
      begin
        Canvas.SetColor(clText1);
        if FHeader.SortDescending then
          Canvas.FillTriangle(lRect.Right - 12, lRect.Top + 10,
            lRect.Right - 4, lRect.Top + 10, lRect.Right - 8, lRect.Top + 15)
        else
          Canvas.FillTriangle(lRect.Right - 12, lRect.Top + 15,
            lRect.Right - 4, lRect.Top + 15, lRect.Right - 8, lRect.Top + 10);
      end;
    end;
  Canvas.SetClipRect(lClip);
  Canvas.SetColor(clGridLines);
  Canvas.DrawLine(FViewport.Left, FViewport.Top - 1,
    FViewport.Right - 1, FViewport.Top - 1);
end;

procedure TfpgVirtualStringTree.DrawNodeButton(ANode: PVirtualNode;
  const ARect: TfpgRect);
var
  lRect: TfpgRect;
begin
  if not (toShowButtons in FOptions.PaintOptions) or
    not (vsHasChildren in ANode^.States) then Exit;
  lRect := ButtonRect(ANode, ARect);
  Canvas.SetColor(clWidgetFrame);
  Canvas.DrawRectangle(lRect);
  Canvas.DrawLine(lRect.Left + 2, lRect.Top + 5, lRect.Right - 3, lRect.Top + 5);
  if not GetExpanded(ANode) then
    Canvas.DrawLine(lRect.Left + 5, lRect.Top + 2, lRect.Left + 5, lRect.Bottom - 3);
end;

procedure TfpgVirtualStringTree.DrawNodeCheck(ANode: PVirtualNode;
  const ARect: TfpgRect);
var
  lRect: TfpgRect;
  lFlags: TfpgCheckBoxFlags;
begin
  if not (toCheckSupport in FOptions.MiscOptions) or (ANode^.CheckType = ctNone) then Exit;
  lRect := CheckRect(ANode, ARect);
  lFlags := [];
  if Enabled and not (vsDisabled in ANode^.States) then Include(lFlags, cbfEnabled);
  if toReadOnly in FOptions.MiscOptions then Include(lFlags, cbfReadOnly);
  if ANode^.CheckState in [csCheckedNormal, csCheckedPressed] then Include(lFlags, cbfChecked);
  if ANode^.CheckState in [csUncheckedPressed, csCheckedPressed, csMixedPressed] then
    Include(lFlags, cbfPressed);
  if ANode^.CheckType = ctRadioButton then fpgStyle.DrawRadioButton(Canvas, lRect, lFlags)
  else fpgStyle.DrawCheckBox(Canvas, lRect, lFlags);
  if ANode^.CheckState in [csMixedNormal, csMixedPressed] then
  begin
    Canvas.SetColor(clText1);
    Canvas.FillRectangle(lRect.Left + 4, lRect.Top + 5, 6, 3);
  end;
end;

procedure TfpgVirtualStringTree.DrawCell(ANode: PVirtualNode; AColumn: Integer;
  const ARect: TfpgRect);
var
  lClip, lTextRect, lGlyph: TfpgRect;
  lSelected, lHandled: Boolean;
  lAlignment: TAlignment;
  lImage: TfpgImage;
begin
  lClip := Canvas.GetClipRect;
  Canvas.AddClipRect(ARect);
  try
    Canvas.SetFont(Font);
    lSelected := GetSelected(ANode) and
      (Focused or not (toHideSelection in FOptions.PaintOptions)) and
      ((toFullRowSelect in FOptions.SelectionOptions) or (AColumn = FHeader.MainColumn));
    if lSelected then
    begin
      if Focused then
      begin
        Canvas.SetColor(clSelection);
        Canvas.SetTextColor(clSelectionText);
      end
      else
      begin
        Canvas.SetColor(clInactiveSel);
        Canvas.SetTextColor(clInactiveSelText);
      end;
    end
    else
    begin
      if (ANode = FHotNode) and (toHotTrack in FOptions.PaintOptions) then
        Canvas.SetColor(clWidgetFrame)
      else Canvas.SetColor(clListBox);
      if not Enabled or (vsDisabled in ANode^.States) then Canvas.SetTextColor(clShadow1)
      else Canvas.SetTextColor(clText1);
    end;
    Canvas.FillRectangle(ARect);
    lHandled := False;
    if Assigned(FOnDrawCell) then FOnDrawCell(Self, Canvas, ANode, AColumn, ARect, lHandled);
    if not lHandled then
    begin
      lTextRect := ARect;
      if AColumn = FHeader.MainColumn then
      begin
        if (toShowTreeLines in FOptions.PaintOptions) and
          ((GetNodeLevel(ANode) > 0) or (toShowRoot in FOptions.PaintOptions)) then
        begin
          lGlyph := ButtonRect(ANode, ARect);
          Canvas.SetColor(clGridLines);
          Canvas.DrawLine(lGlyph.Left + 5, ARect.Top, lGlyph.Left + 5, ARect.Bottom - 1);
          Canvas.DrawLine(lGlyph.Left + 5, ARect.Top + ARect.Height div 2,
            lGlyph.Left + FIndent - 2, ARect.Top + ARect.Height div 2);
        end;
        DrawNodeButton(ANode, ARect);
        Inc(lTextRect.Left, (GetNodeLevel(ANode) + 1) * FIndent);
        Dec(lTextRect.Width, (GetNodeLevel(ANode) + 1) * FIndent);
        DrawNodeCheck(ANode, ARect);
        if (toCheckSupport in FOptions.MiscOptions) and (ANode^.CheckType <> ctNone) then
        begin
          Inc(lTextRect.Left, 20);
          Dec(lTextRect.Width, 20);
        end;
      end;
      lImage := nil;
      if Assigned(FOnGetImage) then FOnGetImage(Self, ANode, AColumn, lImage);
      if Assigned(lImage) then
      begin
        Canvas.DrawImage(lTextRect.Left + 3,
          lTextRect.Top + (lTextRect.Height - lImage.Height) div 2, lImage);
        Inc(lTextRect.Left, lImage.Width + 5);
        Dec(lTextRect.Width, lImage.Width + 5);
      end;
      lAlignment := taLeftJustify;
      if FHeader.Columns.Count > 0 then lAlignment := FHeader.Columns[AColumn].Alignment;
      if lTextRect.Width > 0 then
      begin
        Canvas.AddClipRect(lTextRect);
        if vsMultiline in ANode^.States then
          Canvas.DrawText(lTextRect, GetText(ANode, AColumn), [txtWrap])
        else DrawText(GetText(ANode, AColumn), lTextRect, lAlignment);
      end;
    end;
    Canvas.SetClipRect(lClip);
    Canvas.AddClipRect(ARect);
    Canvas.SetColor(clGridLines);
    if toShowHorzGridLines in FOptions.PaintOptions then
      Canvas.DrawLine(ARect.Left, ARect.Bottom - 1, ARect.Right - 1, ARect.Bottom - 1);
    if toShowVertGridLines in FOptions.PaintOptions then
      Canvas.DrawLine(ARect.Right - 1, ARect.Top, ARect.Right - 1, ARect.Bottom - 1);
  finally
    Canvas.SetClipRect(lClip);
  end;
end;

procedure TfpgVirtualStringTree.HandlePaint;
var
  lNode: PVirtualNode;
  lTop, lColumn, lY: Integer;
  lRect, lClip: TfpgRect;
begin
  if FUpdateCount <> 0 then Exit;
  if FLayoutDirty then UpdateScrollBars;
  lClip := Canvas.GetClipRect;
  Canvas.SetColor(clListBox);
  Canvas.FillRectangle(GetClientRect);
  Canvas.SetColor(clWidgetFrame);
  Canvas.DrawRectangle(GetClientRect);
  DrawHeader;
  Canvas.AddClipRect(FViewport);
  try
    lNode := NodeAtOffset(FScrollY, lTop);
    lY := FViewport.Top + lTop - FScrollY;
    while Assigned(lNode) and (lY < FViewport.Bottom) do
    begin
      InitNode(lNode);
      if NodeDisplayed(lNode) then
      begin
        for lColumn := 0 to Max(1, FHeader.Columns.Count) - 1 do
        begin
          if (FHeader.Columns.Count > 0) and not FHeader.Columns[lColumn].Visible then Continue;
          lRect.SetRect(ColumnLeft(lColumn), lY, ColumnWidth(lColumn), lNode^.NodeHeight);
          if (lRect.Right > FViewport.Left) and (lRect.Left < FViewport.Right) then
            DrawCell(lNode, lColumn, lRect);
        end;
        if (lNode = FFocusedNode) and Focused then
        begin
          lRect.SetRect(FViewport.Left + 1, lY + 1, Max(0, FViewport.Width - 2),
            Max(0, lNode^.NodeHeight - 2));
          fpgStyle.DrawFocusRect(Canvas, lRect);
        end;
        Inc(lY, lNode^.NodeHeight);
      end;
      lNode := GetNextVisibleNoInit(lNode);
    end;
    if toFullVertGridLines in FOptions.PaintOptions then
    begin
      Canvas.SetColor(clGridLines);
      for lColumn := 0 to FHeader.Columns.Count - 1 do
        if FHeader.Columns[lColumn].Visible then
          Canvas.DrawLine(ColumnLeft(lColumn) + ColumnWidth(lColumn) - 1,
            FViewport.Top, ColumnLeft(lColumn) + ColumnWidth(lColumn) - 1,
            FViewport.Bottom - 1);
    end;
  finally
    Canvas.SetClipRect(lClip);
  end;
end;

procedure TfpgVirtualStringTree.HandleResize(AWidth, AHeight: TfpgCoord);
begin
  inherited HandleResize(AWidth, AHeight);
  CancelEditNode;
  FLayoutDirty := True;
  if FUpdateCount = 0 then FlushChanges;
end;

procedure TfpgVirtualStringTree.SetFontDesc(const AValue: string);
begin
  inherited SetFontDesc(AValue);
  Invalidate;
end;

procedure TfpgVirtualStringTree.SelectRange(ANode: PVirtualNode;
  AKeepSelection: Boolean);
var
  lNode: PVirtualNode;
  lInRange: Boolean;
begin
  if not AKeepSelection then ClearSelection;
  if FRangeAnchor = nil then FRangeAnchor := ANode;
  lInRange := False;
  lNode := GetFirstVisible;
  while Assigned(lNode) do
  begin
    if (lNode = ANode) or (lNode = FRangeAnchor) then
    begin
      SetSelected(lNode, True);
      if lInRange or (ANode = FRangeAnchor) then Break;
      lInRange := True;
    end
    else if lInRange then SetSelected(lNode, True);
    lNode := GetNextVisible(lNode);
  end;
end;

procedure TfpgVirtualStringTree.SelectFromInput(ANode: PVirtualNode;
  AShiftState: TShiftState);
begin
  if (ANode = nil) or (vsDisabled in ANode^.States) then Exit;
  BeginUpdate;
  try
    if (toMultiSelect in FOptions.SelectionOptions) and (ssShift in AShiftState) then
      SelectRange(ANode, ssCtrl in AShiftState)
    else if (toMultiSelect in FOptions.SelectionOptions) and (ssCtrl in AShiftState) then
    begin
      SetSelected(ANode, not GetSelected(ANode));
      FRangeAnchor := ANode;
    end
    else
    begin
      ClearSelection;
      SetSelected(ANode, True);
      FRangeAnchor := ANode;
    end;
    SetFocusedNode(ANode);
  finally
    EndUpdate;
  end;
end;

procedure TfpgVirtualStringTree.HandleLMouseDown(AX, AY: Integer;
  AShiftState: TShiftState);
var
  lHit: THitInfo;
begin
  inherited HandleLMouseDown(AX, AY, AShiftState);
  if not Enabled then Exit;
  if not EndEditNode then Exit;
  SetFocus;
  GetHitTestInfoAt(AX, AY, lHit);
  if hiOnHeader in lHit.HitPositions then
  begin
    FResizeColumn := ResizeColumnAt(AX);
    if FResizeColumn >= 0 then
    begin
      FResizeStartX := AX;
      FResizeStartWidth := FHeader.Columns[FResizeColumn].Width;
      CaptureMouse;
    end
    else FHeaderPressedColumn := lHit.HitColumn;
    Exit;
  end;
  if lHit.HitNode = nil then Exit;
  if vsDisabled in lHit.HitNode^.States then Exit;
  FFocusedColumn := lHit.HitColumn;
  if hiOnItemButton in lHit.HitPositions then ToggleNode(lHit.HitNode)
  else if hiOnItemCheckbox in lHit.HitPositions then ToggleCheck(lHit.HitNode)
  else SelectFromInput(lHit.HitNode, AShiftState);
end;

procedure TfpgVirtualStringTree.HandleLMouseUp(AX, AY: Integer;
  AShiftState: TShiftState);
var
  lColumn: Integer;
begin
  inherited HandleLMouseUp(AX, AY, AShiftState);
  if FResizeColumn >= 0 then
  begin
    FResizeColumn := -1;
    ReleaseMouse;
    Exit;
  end;
  lColumn := FHeaderPressedColumn;
  FHeaderPressedColumn := -1;
  if (lColumn >= 0) and (AY < FViewport.Top) and (ColumnAt(AX) = lColumn) and
    Assigned(FOnHeaderClick) then FOnHeaderClick(Self, lColumn);
end;

procedure TfpgVirtualStringTree.HandleRMouseDown(AX, AY: Integer;
  AShiftState: TShiftState);
var
  lNode: PVirtualNode;
begin
  inherited HandleRMouseDown(AX, AY, AShiftState);
  if not Enabled or not (toRightClickSelect in FOptions.SelectionOptions) then Exit;
  lNode := GetNodeAt(AX, AY);
  if not GetSelected(lNode) then SelectFromInput(lNode, AShiftState);
end;

procedure TfpgVirtualStringTree.HandleMouseMove(AX, AY: Integer; AButtons: Word;
  AShiftState: TShiftState);
var
  lNode: PVirtualNode;
begin
  inherited HandleMouseMove(AX, AY, AButtons, AShiftState);
  if FResizeColumn >= 0 then
  begin
    FHeader.Columns[FResizeColumn].Width := FResizeStartWidth + AX - FResizeStartX;
    Exit;
  end;
  if (AY < FViewport.Top) and (ResizeColumnAt(AX) >= 0) then MouseCursor := mcSizeEW
  else MouseCursor := mcDefault;
  if toHotTrack in FOptions.PaintOptions then
  begin
    lNode := GetNodeAt(AX, AY);
    if FHotNode <> lNode then
    begin
      FHotNode := lNode;
      Invalidate;
    end;
  end;
end;

procedure TfpgVirtualStringTree.HandleMouseExit;
begin
  inherited HandleMouseExit;
  FHotNode := nil;
  Invalidate;
end;

procedure TfpgVirtualStringTree.HandleDoubleClick(AX, AY: Integer; AButton: Word;
  AShiftState: TShiftState);
var
  lHit: THitInfo;
begin
  inherited HandleDoubleClick(AX, AY, AButton, AShiftState);
  if (AButton <> MOUSE_LEFT) or not Enabled then Exit;
  GetHitTestInfoAt(AX, AY, lHit);
  if (lHit.HitNode = nil) or (vsDisabled in lHit.HitNode^.States) then Exit;
  if (hiOnItemLabel in lHit.HitPositions) and
    not EditNode(lHit.HitNode, lHit.HitColumn) then ToggleNode(lHit.HitNode);
end;

procedure TfpgVirtualStringTree.HandleMouseScroll(AX, AY: Integer;
  AShiftState: TShiftState; ADelta: SmallInt);
begin
  inherited HandleMouseScroll(AX, AY, AShiftState, ADelta);
  FVerticalScrollBar.Position := FScrollY + ADelta * FDefaultNodeHeight * 3;
  VerticalScroll(FVerticalScrollBar, FVerticalScrollBar.Position);
end;

procedure TfpgVirtualStringTree.HandleMouseHorizScroll(AX, AY: Integer;
  AShiftState: TShiftState; ADelta: SmallInt);
begin
  inherited HandleMouseHorizScroll(AX, AY, AShiftState, ADelta);
  FHorizontalScrollBar.Position := FScrollX + ADelta * FIndent * 3;
  HorizontalScroll(FHorizontalScrollBar, FHorizontalScrollBar.Position);
end;

procedure TfpgVirtualStringTree.HandleKeyPress(var AKeyCode: Word;
  var AShiftState: TShiftState; var AConsumed: Boolean);
var
  lNode: PVirtualNode;
  lRect: TfpgRect;
begin
  inherited HandleKeyPress(AKeyCode, AShiftState, AConsumed);
  if AConsumed or not Enabled then Exit;
  if (AKeyCode = Ord('A')) and (ssCtrl in AShiftState) and
    (toMultiSelect in FOptions.SelectionOptions) then
  begin
    SelectAll;
    AConsumed := True;
    Exit;
  end;
  lNode := FFocusedNode;
  case AKeyCode of
    keyUp: if Assigned(lNode) then lNode := GetPreviousVisible(lNode) else lNode := GetFirstVisible;
    keyDown: if Assigned(lNode) then lNode := GetNextVisible(lNode) else lNode := GetFirstVisible;
    keyHome: lNode := GetFirstVisible;
    keyEnd: lNode := GetLastVisible;
    keyPageUp, keyPageDown:
      begin
        if lNode = nil then lNode := GetFirstVisible
        else
        begin
          lRect := GetDisplayRect(lNode, cNoColumn);
          if AKeyCode = keyPageUp then
            lNode := GetNodeAt(FViewport.Left, Max(FViewport.Top,
              lRect.Top - FViewport.Height + FDefaultNodeHeight))
          else
            lNode := GetNodeAt(FViewport.Left, Min(FViewport.Bottom - 1,
              lRect.Top + FViewport.Height - FDefaultNodeHeight));
        end;
      end;
    keyLeft:
      if Assigned(lNode) then
        if GetExpanded(lNode) then SetExpanded(lNode, False)
        else if lNode^.Parent <> FRoot then lNode := lNode^.Parent;
    keyRight:
      if Assigned(lNode) then
        if not GetExpanded(lNode) then SetExpanded(lNode, True)
        else if lNode^.FirstChild <> nil then lNode := GetNextVisible(lNode);
    keySpace:
      begin
        if Assigned(lNode) and (toCheckSupport in FOptions.MiscOptions) and
          (lNode^.CheckType <> ctNone) then ToggleCheck(lNode)
        else if Assigned(lNode) then SetSelected(lNode, not GetSelected(lNode));
        AConsumed := True;
        Exit;
      end;
    keyF2:
      begin
        EditNode(lNode, FFocusedColumn);
        AConsumed := True;
        Exit;
      end;
  else
    Exit;
  end;
  if Assigned(lNode) then
  begin
    if (ssCtrl in AShiftState) and not (ssShift in AShiftState) then SetFocusedNode(lNode)
    else SelectFromInput(lNode, AShiftState);
    ScrollIntoView(lNode);
  end;
  AConsumed := True;
end;

procedure TfpgVirtualStringTree.HandleKeyChar(var AText: TfpgChar;
  var AShiftState: TShiftState; var AConsumed: Boolean);
var
  lNode, lStart: PVirtualNode;
  lText: string;
begin
  inherited HandleKeyChar(AText, AShiftState, AConsumed);
  if AConsumed or not Enabled or (AShiftState * [ssCtrl, ssAlt] <> []) or
    (AText = '') or (Ord(AText[1]) < 32) then Exit;
  if GetTickCount64 - FSearchTime > 1000 then FSearchText := '';
  FSearchTime := GetTickCount64;
  FSearchText := FSearchText + AText;
  lStart := FFocusedNode;
  lNode := lStart;
  repeat
    if lNode = nil then lNode := GetFirstVisible else lNode := GetNextVisible(lNode);
    if lNode = nil then lNode := GetFirstVisible;
    if lNode = nil then Break;
    lText := GetText(lNode, FHeader.MainColumn);
    if CompareText(Copy(lText, 1, Length(FSearchText)), FSearchText) = 0 then
    begin
      SelectFromInput(lNode, []);
      ScrollIntoView(lNode);
      Break;
    end;
    if lStart = nil then lStart := lNode;
  until lNode = lStart;
  AConsumed := True;
end;

procedure TfpgVirtualStringTree.HandleSetFocus;
begin
  inherited HandleSetFocus;
  Invalidate;
end;

procedure TfpgVirtualStringTree.HandleKillFocus;
begin
  inherited HandleKillFocus;
  Invalidate;
end;

function TfpgVirtualStringTree.CanEditCell(ANode: PVirtualNode;
  AColumn: TColumnIndex): Boolean;
begin
  Result := Assigned(FOnNewText);
end;

function TfpgVirtualStringTree.GetEditText(ANode: PVirtualNode;
  AColumn: TColumnIndex): string;
begin
  Result := GetText(ANode, AColumn);
end;

procedure TfpgVirtualStringTree.GetEditChoices(ANode: PVirtualNode;
  AColumn: TColumnIndex; AChoices: TStrings);
begin
  AChoices.Clear;
end;

function TfpgVirtualStringTree.CommitEditText(ANode: PVirtualNode;
  AColumn: TColumnIndex; const AText: string): Boolean;
begin
  SetText(ANode, AColumn, AText);
  Result := True;
end;

function TfpgVirtualStringTree.GetPendingEditText: string;
begin
  if FEditingChoice then Result := FChoiceEditor.Text else Result := FEditor.Text;
end;

procedure TfpgVirtualStringTree.SetPendingEditText(const AText: string);
begin
  if FEditingChoice then FChoiceEditor.Text := AText else FEditor.Text := AText;
end;

function TfpgVirtualStringTree.EditNode(ANode: PVirtualNode;
  AColumn: TColumnIndex): Boolean;
var
  lRect, lClippedRect: TfpgRect;
  lChoices: TStringList;
  lWidget: TfpgWidget;
  lGeneration: QWord;
begin
  Result := False;
  lGeneration := FNodeGeneration;
  if not EndEditNode or (lGeneration <> FNodeGeneration) then Exit;
  if ANode <> nil then RequireNode(ANode);
  if (ANode = nil) or not Enabled or (vsDisabled in ANode^.States) or
    not (toEditable in FOptions.MiscOptions) or (toReadOnly in FOptions.MiscOptions) or
    (AColumn < 0) or
    (AColumn >= FHeader.Columns.Count) or not FHeader.Columns[AColumn].Editable then Exit;
  if not CanEditCell(ANode, AColumn) then Exit;
  ScrollIntoView(ANode);
  lRect := GetDisplayRect(ANode, AColumn);
  if (lRect.Height = 0) or not FHeader.Columns[AColumn].Visible then Exit;
  if AColumn = FHeader.MainColumn then
  begin
    Inc(lRect.Left, (GetNodeLevel(ANode) + 1) * FIndent);
    Dec(lRect.Width, (GetNodeLevel(ANode) + 1) * FIndent);
    if (toCheckSupport in FOptions.MiscOptions) and (ANode^.CheckType <> ctNone) then
    begin
      Inc(lRect.Left, 20);
      Dec(lRect.Width, 20);
    end;
  end;
  if not lRect.IntersectRect(lClippedRect, FViewport) then Exit;
  lRect := lClippedRect;
  if (lRect.Width <= 0) or (lRect.Height <= 0) then Exit;
  lChoices := TStringList.Create;
  try
    GetEditChoices(ANode, AColumn, lChoices);
    FEditingChoice := lChoices.Count > 0;
    if FEditingChoice then
    begin
      if FChoiceEditor = nil then
      begin
        FChoiceEditor := TVTChoiceEditor.Create(Self);
        FChoiceEditor.AutoSize := False;
        FChoiceEditor.OnKeyPress := @EditorKeyPress;
        FChoiceEditor.OnExit := @EditorExit;
      end;
      FChoiceEditor.FontDesc := FontDesc;
      FChoiceEditor.Items.Assign(lChoices);
      lWidget := FChoiceEditor;
    end
    else
    begin
      if FEditor = nil then
      begin
        FEditor := TfpgEdit.Create(Self);
        FEditor.AutoSize := False;
        FEditor.OnKeyPress := @EditorKeyPress;
        FEditor.OnExit := @EditorExit;
      end;
      FEditor.FontDesc := FontDesc;
      lWidget := FEditor;
    end;
  finally
    lChoices.Free;
  end;
  lWidget.Left := lRect.Left;
  lWidget.Top := lRect.Top;
  lWidget.Width := lRect.Width;
  lWidget.Height := lRect.Height;
  SetPendingEditText(GetEditText(ANode, AColumn));
  FEditNode := ANode;
  FEditColumn := AColumn;
  lWidget.Visible := True;
  lWidget.BringToFront;
  lWidget.SetFocus;
  Result := True;
end;

function TfpgVirtualStringTree.EndEditNode: Boolean;
var
  lNode: PVirtualNode;
  lColumn: Integer;
  lText: string;
begin
  Result := True;
  if (FEditNode = nil) or FEndingEdit then Exit;
  lNode := FEditNode;
  lColumn := FEditColumn;
  lText := GetPendingEditText;
  FEndingEdit := True;
  try
    Result := CommitEditText(lNode, lColumn, lText);
  finally
    FEndingEdit := False;
  end;
  if Result then CancelEditNode;
end;

procedure TfpgVirtualStringTree.CancelEditNode;
var
  lWasEnding: Boolean;
begin
  if FEditNode = nil then Exit;
  FEditNode := nil;
  lWasEnding := FEndingEdit;
  FEndingEdit := True;
  try
    if FEditingChoice then FChoiceEditor.Visible := False else FEditor.Visible := False;
    { A hidden cell editor must not remain the tree's focus owner. }
    if ((FEditor <> nil) and (ActiveWidget = FEditor)) or
      ((FChoiceEditor <> nil) and (ActiveWidget = FChoiceEditor)) then ActiveWidget := nil;
    if not FDestroying then SetFocus;
  finally
    FEndingEdit := lWasEnding;
  end;
end;

procedure TfpgVirtualStringTree.EditorKeyPress(ASender: TObject;
  var AKeyCode: Word; var AShiftState: TShiftState; var AConsumed: Boolean);
begin
  case AKeyCode of
    keyReturn, keyPEnter:
      begin
        EndEditNode;
        AConsumed := True;
      end;
    keyEscape:
      begin
        CancelEditNode;
        AConsumed := True;
      end;
  end;
end;

procedure TfpgVirtualStringTree.EditorExit(ASender: TObject);
begin
  { Switching editor kinds causes the previous widget to lose focus. That
    notification does not belong to the newly opened cell. }
  if FEditingChoice then
  begin
    if ASender <> FChoiceEditor then Exit;
  end
  else if ASender <> FEditor then Exit;
  EndEditNode;
end;

end.

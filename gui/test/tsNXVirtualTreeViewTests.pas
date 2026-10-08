(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tsNXVirtualTreeViewTests;

{$mode objfpc}{$H+}

interface

uses
  obNXTestRegistry;

procedure RegisterNXVirtualTreeViewTests(ARegistry: TNXTestRegistry);

implementation

uses
  Classes, SysUtils, fpg_base, fpg_main, fpg_widget, fpg_hybrid_canvas, obNXVirtualTreeView,
  obVTVTree, tpVTV, obNXTestContext, obNXTestSuite;

type
  PNodeData = ^TNodeData;
  TNodeData = record
    Caption: string;
    Value: Integer;
  end;

  TCallbacks = class
  private
    FInitCount, FFreeCount, FChildrenCount, FChangeCount: Integer;
    FRaiseInit, FRaiseCompare: Boolean;
  public
    procedure InitNode(ASender: TfpgVirtualStringTree; AParentNode,
      ANode: PVirtualNode; var AStates: TVirtualNodeInitStates);
    procedure InitChildren(ASender: TfpgVirtualStringTree; ANode: PVirtualNode;
      var AChildCount: Cardinal);
    procedure FreeNode(ASender: TfpgVirtualStringTree; ANode: PVirtualNode);
    procedure GetText(ASender: TfpgVirtualStringTree; ANode: PVirtualNode;
      AColumn: TColumnIndex; var AText: string);
    procedure NewText(ASender: TfpgVirtualStringTree; ANode: PVirtualNode;
      AColumn: TColumnIndex; const AText: string);
    procedure CompareNodes(ASender: TfpgVirtualStringTree; ANode1,
      ANode2: PVirtualNode; AColumn: TColumnIndex; var AResult: Integer);
    procedure Changed(ASender: TfpgVirtualStringTree; ANode: PVirtualNode);
    property InitCount: Integer read FInitCount;
    property FreeCount: Integer read FFreeCount;
    property ChildrenCount: Integer read FChildrenCount;
    property ChangeCount: Integer read FChangeCount;
    property RaiseInit: Boolean read FRaiseInit write FRaiseInit;
    property RaiseCompare: Boolean read FRaiseCompare write FRaiseCompare;
  end;

  TMemoryBufferManager = class(TInterfacedObject, IBufferManager)
  private
    FStorage: array of LongWord;
    FWidth, FHeight, FStridePixels: Integer;
  public
    procedure AttachWindow(AWindow: TfpgWindowBase);
    procedure DetachWindow;
    procedure AllocateBuffer(AWidth, AHeight: Integer;
      out AData: Pointer; out AStride: Integer);
    function BufferAllocated: Boolean;
    procedure FreeBuffer;
    procedure PutBufferToScreen(AX, AY, AWidth, AHeight: TfpgCoord);
    procedure RestoreFromBuffer(const ARect: TfpgRect);
    function Pixel(AX, AY: Integer): LongWord;
    function GuardsIntact: Boolean;
  end;

  TTestCanvas = class(THybridCanvas)
  public
    procedure Allocate;
  end;

  TTestTree = class(TNXVirtualTreeView)
  private
    FTestCanvas: TTestCanvas;
    FMemory: TMemoryBufferManager;
  protected
    function CreateCanvas: TfpgCanvasBase; override;
  public
    procedure Paint;
    procedure MouseDown(AX, AY: Integer; AShift: TShiftState);
    procedure MouseUp(AX, AY: Integer);
    procedure MouseMove(AX, AY: Integer; AButtons: Word);
    procedure Scroll(ADelta: SmallInt);
    procedure HorizScroll(ADelta: SmallInt);
    procedure Key(AKey: Word; AShift: TShiftState = []);
    property Memory: TMemoryBufferManager read FMemory;
  end;

  TPaintCallbacks = class
  public
    procedure Overflow(ASender: TfpgVirtualStringTree; ACanvas: TfpgCanvas;
      ANode: PVirtualNode; AColumn: TColumnIndex; const ARect: TfpgRect;
      var AHandled: Boolean);
  end;

const
  cGuardPixels = 32;
  cGuardColor = LongWord($A5A5A5A5);

var
  gLastMemory: TMemoryBufferManager;

procedure TCallbacks.InitNode(ASender: TfpgVirtualStringTree; AParentNode,
  ANode: PVirtualNode; var AStates: TVirtualNodeInitStates);
var
  lData: PNodeData;
begin
  Inc(FInitCount);
  lData := ASender.GetNodeData(ANode);
  lData^.Caption := 'Node ' + IntToStr(ANode^.Index);
  lData^.Value := ANode^.Index;
  if AParentNode = nil then Include(AStates, ivsHasChildren);
  if FRaiseInit then raise Exception.Create('Deliberate initialization failure');
end;

procedure TCallbacks.InitChildren(ASender: TfpgVirtualStringTree;
  ANode: PVirtualNode; var AChildCount: Cardinal);
begin
  Inc(FChildrenCount);
  AChildCount := 3;
end;

procedure TCallbacks.FreeNode(ASender: TfpgVirtualStringTree; ANode: PVirtualNode);
begin
  Inc(FFreeCount);
  Finalize(PNodeData(ASender.GetNodeData(ANode))^);
end;

procedure TCallbacks.GetText(ASender: TfpgVirtualStringTree; ANode: PVirtualNode;
  AColumn: TColumnIndex; var AText: string);
begin
  AText := PNodeData(ASender.GetNodeData(ANode))^.Caption;
end;

procedure TCallbacks.NewText(ASender: TfpgVirtualStringTree; ANode: PVirtualNode;
  AColumn: TColumnIndex; const AText: string);
begin
  PNodeData(ASender.GetNodeData(ANode))^.Caption := AText;
end;

procedure TCallbacks.CompareNodes(ASender: TfpgVirtualStringTree;
  ANode1, ANode2: PVirtualNode; AColumn: TColumnIndex; var AResult: Integer);
begin
  if FRaiseCompare then raise Exception.Create('Deliberate comparison failure');
  AResult := PNodeData(ASender.GetNodeData(ANode1))^.Value -
    PNodeData(ASender.GetNodeData(ANode2))^.Value;
end;

procedure TCallbacks.Changed(ASender: TfpgVirtualStringTree; ANode: PVirtualNode);
begin
  Inc(FChangeCount);
end;

function CreateTree(ACallbacks: TCallbacks): TNXVirtualTreeView;
begin
  Result := TNXVirtualTreeView.Create(nil);
  Result.NodeDataSize := SizeOf(TNodeData);
  Result.OnInitNode := @ACallbacks.InitNode;
  Result.OnInitChildren := @ACallbacks.InitChildren;
  Result.OnFreeNode := @ACallbacks.FreeNode;
  Result.OnGetText := @ACallbacks.GetText;
  Result.OnNewText := @ACallbacks.NewText;
  Result.OnCompareNodes := @ACallbacks.CompareNodes;
end;

function CreateMemory: IBufferManager;
begin
  gLastMemory := TMemoryBufferManager.Create;
  Result := gLastMemory;
end;

procedure TMemoryBufferManager.AttachWindow(AWindow: TfpgWindowBase);
begin
end;

procedure TMemoryBufferManager.DetachWindow;
begin
end;

procedure TMemoryBufferManager.PutBufferToScreen(AX, AY, AWidth, AHeight: TfpgCoord);
begin
end;

procedure TMemoryBufferManager.RestoreFromBuffer(const ARect: TfpgRect);
begin
end;

procedure TMemoryBufferManager.AllocateBuffer(AWidth, AHeight: Integer;
  out AData: Pointer; out AStride: Integer);
var
  lIndex: Integer;
begin
  FWidth := AWidth;
  FHeight := AHeight;
  FStridePixels := AWidth + 8;
  SetLength(FStorage, cGuardPixels * 2 + FStridePixels * AHeight);
  for lIndex := 0 to High(FStorage) do FStorage[lIndex] := cGuardColor;
  AData := @FStorage[cGuardPixels];
  AStride := FStridePixels * SizeOf(LongWord);
end;

function TMemoryBufferManager.BufferAllocated: Boolean;
begin
  Result := Length(FStorage) > 0;
end;

procedure TMemoryBufferManager.FreeBuffer;
begin
  FStorage := nil;
end;

function TMemoryBufferManager.Pixel(AX, AY: Integer): LongWord;
begin
  Result := FStorage[cGuardPixels + AY * FStridePixels + AX];
end;

function TMemoryBufferManager.GuardsIntact: Boolean;
var
  lIndex, lX, lY: Integer;
begin
  Result := False;
  for lIndex := 0 to cGuardPixels - 1 do
    if (FStorage[lIndex] <> cGuardColor) or
      (FStorage[High(FStorage) - lIndex] <> cGuardColor) then Exit;
  for lY := 0 to FHeight - 1 do
    for lX := FWidth to FStridePixels - 1 do
      if Pixel(lX, lY) <> cGuardColor then Exit;
  Result := True;
end;

procedure TTestCanvas.Allocate;
begin
  DoAllocateBuffer;
  FCanvasTarget := Self;
  FDeltaX := 0;
  FDeltaY := 0;
  DoBeginDraw(Widget, Self);
  ClearClipRect;
end;

function TTestTree.CreateCanvas: TfpgCanvasBase;
begin
  FTestCanvas := TTestCanvas.Create(Self);
  FMemory := gLastMemory;
  Result := FTestCanvas;
end;

procedure TTestTree.Paint;
begin
  FTestCanvas.Allocate;
  HandlePaint;
end;

procedure TTestTree.MouseDown(AX, AY: Integer; AShift: TShiftState);
begin
  HandleLMouseDown(AX, AY, AShift);
end;

procedure TTestTree.MouseUp(AX, AY: Integer);
begin
  HandleLMouseUp(AX, AY, []);
end;

procedure TTestTree.MouseMove(AX, AY: Integer; AButtons: Word);
begin
  HandleMouseMove(AX, AY, AButtons, []);
end;

procedure TTestTree.Scroll(ADelta: SmallInt);
begin
  HandleMouseScroll(0, 0, [], ADelta);
end;

procedure TTestTree.HorizScroll(ADelta: SmallInt);
begin
  HandleMouseHorizScroll(0, 0, [], ADelta);
end;

procedure TTestTree.Key(AKey: Word; AShift: TShiftState);
var
  lConsumed: Boolean;
begin
  lConsumed := False;
  HandleKeyPress(AKey, AShift, lConsumed);
end;

function CreatePaintTree: TTestTree;
var
  lSavedFactory: TBufferManagerFactory;
begin
  lSavedFactory := CreateBufferManager;
  CreateBufferManager := @CreateMemory;
  try
    Result := TTestTree.Create(nil);
  finally
    CreateBufferManager := lSavedFactory;
  end;
  Result.Width := 220;
  Result.Height := 160;
end;

procedure TPaintCallbacks.Overflow(ASender: TfpgVirtualStringTree;
  ACanvas: TfpgCanvas; ANode: PVirtualNode; AColumn: TColumnIndex;
  const ARect: TfpgRect; var AHandled: Boolean);
begin
  if AColumn = 0 then ACanvas.SetColor(clRed) else ACanvas.SetColor(clBlue);
  ACanvas.FillRectangle(ARect.Left - 100, ARect.Top - 100, 1000, 500);
  AHandled := True;
end;

procedure TestNodeDataAndTraversal(AContext: TNXTestContext);
var
  lTree: TNXVirtualTreeView;
  lParent, lChild, lSibling: PVirtualNode;
begin
  lTree := TNXVirtualTreeView.Create(nil);
  try
    lTree.NodeDataSize := SizeOf(Integer);
    lParent := lTree.AddChild(nil);
    lChild := lTree.AddChild(lParent);
    lSibling := lTree.AddChild(nil);
    PInteger(lTree.GetNodeData(lChild))^ := 42;
    AContext.AssertEquals(42, PInteger(lTree.GetNodeData(lChild))^);
    AContext.AssertEquals(3, lTree.TotalCount);
    AContext.AssertTrue(lTree.GetFirst = lParent);
    AContext.AssertTrue(lTree.GetNext(lParent) = lChild);
    AContext.AssertTrue(lTree.GetNext(lChild) = lSibling);
    AContext.AssertTrue(lTree.GetPrevious(lSibling) = lChild);
  finally
    lTree.Free;
  end;
end;

procedure TestLazyInitialization(AContext: TNXTestContext);
var
  lCallbacks: TCallbacks;
  lTree: TNXVirtualTreeView;
  lNode: PVirtualNode;
begin
  lCallbacks := TCallbacks.Create;
  lTree := CreateTree(lCallbacks);
  try
    lTree.RootNodeCount := 1000;
    AContext.AssertEquals(0, lCallbacks.InitCount);
    lNode := lTree.GetFirst;
    AContext.AssertEquals(1, lCallbacks.InitCount);
    AContext.AssertEquals('Node 0', lTree.Text[lNode, 0]);
    AContext.AssertEquals(1, lCallbacks.InitCount);
    lTree.Expanded[lNode] := True;
    AContext.AssertEquals(1, lCallbacks.ChildrenCount);
    AContext.AssertEquals(3, lTree.ChildCount[lNode]);
    AContext.AssertEquals(1003, lTree.TotalCount);
    lTree.Expanded[lNode] := False;
    lTree.Expanded[lNode] := True;
    AContext.AssertEquals(1, lCallbacks.ChildrenCount);
  finally
    lTree.Free;
    lCallbacks.Free;
  end;
end;

procedure TestInsertionAndDeletionLinks(AContext: TNXTestContext);
var
  lTree: TNXVirtualTreeView;
  lFirst, lSecond, lBefore, lAfter: PVirtualNode;
begin
  lTree := TNXVirtualTreeView.Create(nil);
  try
    lFirst := lTree.AddChild(nil);
    lSecond := lTree.AddChild(nil);
    lBefore := lTree.InsertNode(lFirst, amInsertBefore);
    lAfter := lTree.InsertNode(lFirst, amInsertAfter);
    AContext.AssertTrue(lTree.RootNode^.FirstChild = lBefore);
    AContext.AssertTrue(lBefore^.NextSibling = lFirst);
    AContext.AssertTrue(lFirst^.NextSibling = lAfter);
    AContext.AssertTrue(lAfter^.NextSibling = lSecond);
    AContext.AssertEquals(3, lSecond^.Index);
    lTree.DeleteNode(lFirst);
    AContext.AssertTrue(lBefore^.NextSibling = lAfter);
    AContext.AssertTrue(lAfter^.PrevSibling = lBefore);
    AContext.AssertEquals(1, lAfter^.Index);
    AContext.AssertEquals(2, lSecond^.Index);
    lTree.DeleteNode(lSecond);
    AContext.AssertTrue(lTree.RootNode^.LastChild = lAfter);
  finally
    lTree.Free;
  end;
end;

procedure TestVisibilityMetrics(AContext: TNXTestContext);
var
  lTree: TNXVirtualTreeView;
  lParent, lChild, lGrandchild: PVirtualNode;
begin
  lTree := TNXVirtualTreeView.Create(nil);
  try
    lParent := lTree.AddChild(nil);
    lChild := lTree.AddChild(lParent);
    lGrandchild := lTree.AddChild(lChild);
    AContext.AssertEquals(1, lTree.VisibleCount);
    lTree.Expanded[lParent] := True;
    lTree.Expanded[lChild] := True;
    AContext.AssertEquals(3, lTree.VisibleCount);
    AContext.AssertEquals(72, lTree.RootNode^.TotalHeight);
    lTree.NodeHeight[lChild] := 40;
    AContext.AssertEquals(88, lTree.RootNode^.TotalHeight);
    lTree.IsFiltered[lChild] := True;
    AContext.AssertEquals(2, lTree.VisibleCount);
    AContext.AssertEquals(48, lTree.RootNode^.TotalHeight);
    AContext.AssertTrue(lTree.GetNextVisible(lParent) = lGrandchild);
    lTree.IsVisible[lChild] := False;
    AContext.AssertEquals(1, lTree.VisibleCount);
    AContext.AssertEquals(24, lTree.RootNode^.TotalHeight);
    lTree.IsVisible[lChild] := True;
    lTree.IsFiltered[lChild] := False;
    AContext.AssertEquals(3, lTree.VisibleCount);
    AContext.AssertEquals(88, lTree.RootNode^.TotalHeight);
    lTree.Expanded[lParent] := False;
    AContext.AssertEquals(1, lTree.VisibleCount);
    lTree.DeleteNode(lChild);
    AContext.AssertEquals(1, lTree.TotalCount);
  finally
    lTree.Free;
  end;
end;

procedure TestHiddenParentMutation(AContext: TNXTestContext);
var
  lTree: TNXVirtualTreeView;
  lParent, lChild: PVirtualNode;
begin
  lTree := TNXVirtualTreeView.Create(nil);
  try
    lParent := lTree.AddChild(nil);
    lTree.Expanded[lParent] := True;
    lTree.IsVisible[lParent] := False;
    lChild := lTree.AddChild(lParent);
    lTree.NodeHeight[lChild] := 40;
    AContext.AssertEquals(0, lTree.VisibleCount);
    AContext.AssertEquals(0, lTree.RootNode^.TotalHeight);
    lTree.IsVisible[lParent] := True;
    AContext.AssertEquals(2, lTree.VisibleCount);
    AContext.AssertEquals(64, lTree.RootNode^.TotalHeight);
  finally
    lTree.Free;
  end;
end;

procedure TestSelectionDeletionSafety(AContext: TNXTestContext);
var
  lTree: TNXVirtualTreeView;
  lParent, lChild, lOther: PVirtualNode;
begin
  lTree := TNXVirtualTreeView.Create(nil);
  try
    lParent := lTree.AddChild(nil);
    lChild := lTree.AddChild(lParent);
    lOther := lTree.AddChild(nil);
    lTree.Selected[lChild] := True;
    lTree.Selected[lOther] := True;
    lTree.FocusedNode := lChild;
    lTree.DeleteNode(lParent);
    AContext.AssertTrue(lTree.FocusedNode = nil);
    AContext.AssertEquals(1, lTree.SelectedCount);
    AContext.AssertTrue(lTree.GetFirstSelected = lOther);
    lTree.Clear;
    AContext.AssertEquals(0, lTree.SelectedCount);
    AContext.AssertTrue(lTree.GetFirstSelected = nil);
  finally
    lTree.Free;
  end;
end;

procedure TestBatchedNotifications(AContext: TNXTestContext);
var
  lCallbacks: TCallbacks;
  lTree: TNXVirtualTreeView;
  lNode: PVirtualNode;
begin
  lCallbacks := TCallbacks.Create;
  lTree := CreateTree(lCallbacks);
  try
    lTree.OnChange := @lCallbacks.Changed;
    lTree.BeginUpdate;
    lTree.BeginUpdate;
    lNode := lTree.AddChild(nil);
    lTree.Selected[lNode] := True;
    lTree.FocusedNode := lNode;
    lTree.EndUpdate;
    AContext.AssertEquals(0, lCallbacks.ChangeCount);
    lTree.EndUpdate;
    AContext.AssertEquals(1, lCallbacks.ChangeCount);
  finally
    lTree.Free;
    lCallbacks.Free;
  end;
end;

procedure TestDataFinalization(AContext: TNXTestContext);
var
  lCallbacks: TCallbacks;
  lTree: TNXVirtualTreeView;
begin
  lCallbacks := TCallbacks.Create;
  lTree := CreateTree(lCallbacks);
  try
    lTree.RootNodeCount := 20;
    lTree.GetFirst;
    lTree.Clear;
    AContext.AssertEquals(1, lCallbacks.FreeCount);
    lTree.RootNodeCount := 1;
    lTree.GetFirst;
  finally
    lTree.Free;
  end;
  try
    AContext.AssertEquals(2, lCallbacks.FreeCount);
  finally
    lCallbacks.Free;
  end;
end;

procedure TestInitFailureCleanup(AContext: TNXTestContext);
var
  lCallbacks: TCallbacks;
  lTree: TNXVirtualTreeView;
  lCaught: Boolean;
begin
  lCallbacks := TCallbacks.Create;
  lTree := CreateTree(lCallbacks);
  try
    lCallbacks.RaiseInit := True;
    lTree.RootNodeCount := 1;
    lCaught := False;
    try
      lTree.GetFirst;
    except
      on lError: Exception do lCaught := lError.Message = 'Deliberate initialization failure';
    end;
    AContext.AssertTrue(lCaught);
    AContext.AssertFalse(vsInitialized in lTree.RootNode^.FirstChild^.States);
    lTree.Clear;
    AContext.AssertEquals(1, lCallbacks.FreeCount);
  finally
    lTree.Free;
    lCallbacks.Free;
  end;
end;

procedure TestStableSortAndFailureRecovery(AContext: TNXTestContext);
var
  lCallbacks: TCallbacks;
  lTree: TNXVirtualTreeView;
  lFirst, lSecond, lThird: PVirtualNode;
  lCaught: Boolean;
begin
  lCallbacks := TCallbacks.Create;
  lTree := CreateTree(lCallbacks);
  try
    lTree.RootNodeCount := 3;
    lFirst := lTree.GetFirst;
    lSecond := lTree.GetNext(lFirst);
    lThird := lTree.GetNext(lSecond);
    PNodeData(lTree.GetNodeData(lFirst))^.Value := 2;
    PNodeData(lTree.GetNodeData(lSecond))^.Value := 1;
    PNodeData(lTree.GetNodeData(lThird))^.Value := 1;
    lTree.Sort(nil, 0, sdAscending);
    AContext.AssertTrue(lTree.RootNode^.FirstChild = lSecond);
    AContext.AssertTrue(lSecond^.NextSibling = lThird);
    AContext.AssertTrue(lThird^.NextSibling = lFirst);
    AContext.AssertEquals(2, lFirst^.Index);
    lCallbacks.RaiseCompare := True;
    lCaught := False;
    try
      lTree.Sort(nil, 0, sdDescending);
    except
      on lError: Exception do lCaught := lError.Message = 'Deliberate comparison failure';
    end;
    AContext.AssertTrue(lCaught);
    AContext.AssertTrue(lTree.RootNode^.FirstChild = lSecond);
    AContext.AssertTrue(lTree.RootNode^.LastChild = lFirst);
    AContext.AssertTrue(lSecond^.NextSibling = lThird);
    AContext.AssertTrue(lThird^.NextSibling = lFirst);
    AContext.AssertTrue(lFirst^.PrevSibling = lThird);
  finally
    lTree.Free;
    lCallbacks.Free;
  end;
end;

procedure TestCheckPropagation(AContext: TNXTestContext);
var
  lTree: TNXVirtualTreeView;
  lParent, lFirst, lSecond: PVirtualNode;
begin
  lTree := TNXVirtualTreeView.Create(nil);
  try
    lTree.TreeOptions.AutoOptions := [toAutoTristateTracking];
    lParent := lTree.AddChild(nil);
    lFirst := lTree.AddChild(lParent);
    lSecond := lTree.AddChild(lParent);
    lParent^.CheckType := ctTriStateCheckBox;
    lFirst^.CheckType := ctCheckBox;
    lSecond^.CheckType := ctCheckBox;
    lTree.CheckState[lFirst] := csCheckedNormal;
    AContext.AssertTrue(lTree.CheckState[lParent] = csMixedNormal);
    lTree.CheckState[lParent] := csCheckedNormal;
    AContext.AssertTrue(lTree.CheckState[lSecond] = csCheckedNormal);
    AContext.AssertTrue(lTree.CheckState[lParent] = csCheckedNormal);
    lTree.CheckState[lSecond] := csUncheckedNormal;
    AContext.AssertTrue(lTree.CheckState[lParent] = csMixedNormal);
  finally
    lTree.Free;
  end;
end;

procedure TestForeignNodeRejected(AContext: TNXTestContext);
var
  lTree, lOther: TNXVirtualTreeView;
  lCaught: Boolean;
begin
  lTree := TNXVirtualTreeView.Create(nil);
  lOther := TNXVirtualTreeView.Create(nil);
  try
    lOther.RootNodeCount := 1;
    lCaught := False;
    try
      lTree.AddChild(lOther.GetFirst);
    except
      on lError: EArgumentException do lCaught := True;
    end;
    AContext.AssertTrue(lCaught);
    AContext.AssertEquals(0, lTree.TotalCount);
  finally
    lOther.Free;
    lTree.Free;
  end;
end;

procedure TestVirtualViewportAndCache(AContext: TNXTestContext);
var
  lTree: TTestTree;
  lCallbacks: TCallbacks;
  lLast: PVirtualNode;
  lRect: TfpgRect;
begin
  lCallbacks := TCallbacks.Create;
  lTree := CreatePaintTree;
  try
    lTree.NodeDataSize := SizeOf(TNodeData);
    lTree.OnInitNode := @lCallbacks.InitNode;
    lTree.OnFreeNode := @lCallbacks.FreeNode;
    lTree.OnGetText := @lCallbacks.GetText;
    lTree.RootNodeCount := 100000;
    lTree.Paint;
    AContext.AssertTrue(lCallbacks.InitCount > 0);
    AContext.AssertTrue(lCallbacks.InitCount < 10, 'Painting initialized offscreen rows.');
    lLast := lTree.RootNode^.LastChild;
    lTree.ScrollIntoView(lLast);
    lTree.Paint;
    lRect := lTree.GetDisplayRect(lLast, 0);
    AContext.AssertTrue(lTree.GetNodeAt(lRect.Left + 20, lRect.Top + 2) = lLast);
    AContext.AssertTrue(lCallbacks.InitCount < 20);
    AContext.AssertTrue(lTree.Memory.GuardsIntact);
  finally
    lTree.Free;
    lCallbacks.Free;
  end;
end;

procedure TestCellAndHeaderClipping(AContext: TNXTestContext);
var
  lTree: TTestTree;
  lPaint: TPaintCallbacks;
  lRect: TfpgRect;
  lHeaderPixel: LongWord;
begin
  lTree := CreatePaintTree;
  lPaint := TPaintCallbacks.Create;
  try
    lTree.Header.Columns[0].Width := 90;
    lTree.Header.Columns.Add.Width := 90;
    lTree.RootNodeCount := 20;
    lTree.Paint;
    lHeaderPixel := lTree.Memory.Pixel(20, 10);
    lTree.OnDrawCell := @lPaint.Overflow;
    lTree.Scroll(1);
    lTree.Paint;
    lRect := lTree.GetDisplayRect(lTree.GetFirstVisible, 0);
    AContext.AssertTrue(lTree.Memory.Pixel(20, 10) = lHeaderPixel,
      'Body paint overwrote the header.');
    AContext.AssertTrue(lTree.Memory.Pixel(20, 40) =
      (LongWord(fpgColorToRGB(clRed)) or $FF000000));
    AContext.AssertTrue(lTree.Memory.Pixel(120, 40) =
      (LongWord(fpgColorToRGB(clBlue)) or $FF000000), 'Cell paint crossed columns.');
    AContext.AssertTrue(lTree.Memory.GuardsIntact);
  finally
    lTree.Free;
    lPaint.Free;
  end;
end;

procedure TestVerticalWheelScrolling(AContext: TNXTestContext);
var
  lTree: TTestTree;
  lFirst: PVirtualNode;
  lOriginalRect, lMovedRect: TfpgRect;
  lStep, lEndScroll: Integer;
begin
  lTree := CreatePaintTree;
  try
    lTree.RootNodeCount := 100;
    lTree.Paint;
    lFirst := lTree.GetFirst;
    lOriginalRect := lTree.GetDisplayRect(lFirst, 0);
    lStep := lTree.DefaultNodeHeight * 3;
    lTree.Scroll(1);
    AContext.AssertEquals(lStep, lTree.ScrollY, 'Wheel must update the content offset.');
    lMovedRect := lTree.GetDisplayRect(lFirst, 0);
    AContext.AssertEquals(lOriginalRect.Top - lStep, lMovedRect.Top);
    AContext.AssertEquals(3, lTree.GetNodeAt(lOriginalRect.Left + 40,
      lOriginalRect.Top + 2)^.Index, 'Hit testing must follow the scrolled rows.');
    lTree.Paint;
    lTree.Scroll(1);
    AContext.AssertEquals(lStep * 2, lTree.ScrollY);
    lTree.Scroll(-1);
    AContext.AssertEquals(lStep, lTree.ScrollY);
    lTree.Scroll(32767);
    lEndScroll := lTree.ScrollY;
    AContext.AssertTrue(lEndScroll > lStep * 2);
    lTree.Scroll(1);
    AContext.AssertEquals(lEndScroll, lTree.ScrollY, 'Scrolling must clamp at the end.');
    lTree.Scroll(-32767);
    AContext.AssertEquals(0, lTree.ScrollY);
    lTree.Scroll(-1);
    AContext.AssertEquals(0, lTree.ScrollY, 'Scrolling must clamp at the beginning.');
    AContext.AssertTrue(lTree.Memory.GuardsIntact);
  finally
    lTree.Free;
  end;
end;

procedure TestHorizontalWheelScrolling(AContext: TNXTestContext);
var
  lTree: TTestTree;
  lFirst: PVirtualNode;
  lOriginalRect, lMovedRect: TfpgRect;
  lHit: THitInfo;
  lStep, lEndScroll: Integer;
begin
  lTree := CreatePaintTree;
  try
    lTree.Header.Columns[0].Width := 90;
    lTree.Header.Columns.Add.Width := 500;
    lTree.RootNodeCount := 100;
    lTree.Paint;
    lFirst := lTree.GetFirst;
    lOriginalRect := lTree.GetDisplayRect(lFirst, 1);
    lStep := lTree.Indent * 3;
    lTree.GetHitTestInfoAt(lOriginalRect.Left - 2, 10, lHit);
    AContext.AssertEquals(0, lHit.HitColumn);
    lTree.HorizScroll(1);
    AContext.AssertEquals(lStep, lTree.ScrollX, 'Wheel must update the content offset.');
    lMovedRect := lTree.GetDisplayRect(lFirst, 1);
    AContext.AssertEquals(lOriginalRect.Left - lStep, lMovedRect.Left);
    lTree.GetHitTestInfoAt(lOriginalRect.Left - 2, 10, lHit);
    AContext.AssertEquals(1, lHit.HitColumn, 'Header hit testing must follow the scrolled columns.');
    lTree.Paint;
    lTree.HorizScroll(1);
    AContext.AssertEquals(lStep * 2, lTree.ScrollX);
    lTree.HorizScroll(-1);
    AContext.AssertEquals(lStep, lTree.ScrollX);
    lTree.HorizScroll(32767);
    lEndScroll := lTree.ScrollX;
    AContext.AssertTrue(lEndScroll > lStep * 2);
    lTree.HorizScroll(1);
    AContext.AssertEquals(lEndScroll, lTree.ScrollX, 'Scrolling must clamp at the end.');
    lTree.HorizScroll(-32767);
    AContext.AssertEquals(0, lTree.ScrollX);
    lTree.HorizScroll(-1);
    AContext.AssertEquals(0, lTree.ScrollX, 'Scrolling must clamp at the beginning.');
    AContext.AssertEquals(0, lTree.ScrollY, 'Horizontal scrolling must not move rows vertically.');
    AContext.AssertTrue(lTree.Memory.GuardsIntact);
  finally
    lTree.Free;
  end;
end;

procedure TestInputSelectionAndKeyboard(AContext: TNXTestContext);
var
  lTree: TTestTree;
  lFirst, lSecond, lThird: PVirtualNode;
  lRect: TfpgRect;
begin
  lTree := CreatePaintTree;
  try
    lTree.TreeOptions.SelectionOptions := [toMultiSelect, toFullRowSelect];
    lTree.RootNodeCount := 3;
    lFirst := lTree.GetFirst;
    lSecond := lTree.GetNext(lFirst);
    lThird := lTree.GetNext(lSecond);
    lRect := lTree.GetDisplayRect(lFirst, 0);
    lTree.MouseDown(lRect.Left + 40, lRect.Top + 3, []);
    lTree.Key(keyDown, [ssShift]);
    AContext.AssertEquals(2, lTree.SelectedCount);
    AContext.AssertTrue(lTree.FocusedNode = lSecond);
    lTree.Key(keyEnd);
    AContext.AssertEquals(1, lTree.SelectedCount);
    AContext.AssertTrue(lTree.FocusedNode = lThird);
    lTree.Key(keyHome, [ssCtrl]);
    AContext.AssertTrue(lTree.FocusedNode = lFirst);
    AContext.AssertTrue(lTree.Selected[lThird]);
  finally
    lTree.Free;
  end;
end;

procedure TestHeaderResize(AContext: TNXTestContext);
var
  lTree: TTestTree;
begin
  lTree := CreatePaintTree;
  try
    lTree.Header.Columns[0].Width := 90;
    lTree.MouseDown(91, 10, []);
    lTree.MouseMove(121, 10, MOUSE_LEFT);
    lTree.MouseUp(121, 10);
    AContext.AssertEquals(120, lTree.Header.Columns[0].Width);
  finally
    lTree.Free;
  end;
end;

procedure TestFontAndEditing(AContext: TNXTestContext);
var
  lCallbacks: TCallbacks;
  lTree: TNXVirtualTreeView;
  lNode: PVirtualNode;
  lOldHeight: Integer;
begin
  lCallbacks := TCallbacks.Create;
  lTree := CreateTree(lCallbacks);
  try
    lTree.RootNodeCount := 1;
    lNode := lTree.GetFirst;
    lOldHeight := lTree.Font.GetHeight;
    lTree.FontDesc := 'Arial-24';
    AContext.AssertTrue(lTree.Font.GetHeight > lOldHeight);
    lTree.Text[lNode, 0] := 'Changed';
    AContext.AssertEquals('Changed', lTree.Text[lNode, 0]);
    lTree.TreeOptions.MiscOptions := [toEditable];
    lTree.Header.Columns[0].Editable := True;
    AContext.AssertTrue(lTree.EditNode(lNode, 0));
    lTree.CancelEditNode;
    AContext.AssertEquals('Changed', lTree.Text[lNode, 0]);
    AContext.AssertTrue(lTree.EditNode(lNode, 0));
    lTree.DeleteNode(lNode);
    AContext.AssertTrue(lTree.FocusedNode = nil);
  finally
    lTree.Free;
    lCallbacks.Free;
  end;
end;

procedure RegisterNXVirtualTreeViewTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('NXVirtualTreeView');
  lSuite.AddTest('NodeDataAndTraversal', @TestNodeDataAndTraversal);
  lSuite.AddTest('LazyInitialization', @TestLazyInitialization);
  lSuite.AddTest('InsertionAndDeletionLinks', @TestInsertionAndDeletionLinks);
  lSuite.AddTest('VisibilityMetrics', @TestVisibilityMetrics);
  lSuite.AddTest('HiddenParentMutation', @TestHiddenParentMutation);
  lSuite.AddTest('SelectionDeletionSafety', @TestSelectionDeletionSafety);
  lSuite.AddTest('BatchedNotifications', @TestBatchedNotifications);
  lSuite.AddTest('DataFinalization', @TestDataFinalization);
  lSuite.AddTest('InitFailureCleanup', @TestInitFailureCleanup);
  lSuite.AddTest('StableSortAndFailureRecovery', @TestStableSortAndFailureRecovery);
  lSuite.AddTest('CheckPropagation', @TestCheckPropagation);
  lSuite.AddTest('ForeignNodeRejected', @TestForeignNodeRejected);
  lSuite.AddTest('VirtualViewportAndCache', @TestVirtualViewportAndCache);
  lSuite.AddTest('CellAndHeaderClipping', @TestCellAndHeaderClipping);
  lSuite.AddTest('VerticalWheelScrolling', @TestVerticalWheelScrolling);
  lSuite.AddTest('HorizontalWheelScrolling', @TestHorizontalWheelScrolling);
  lSuite.AddTest('InputSelectionAndKeyboard', @TestInputSelectionAndKeyboard);
  lSuite.AddTest('HeaderResize', @TestHeaderResize);
  lSuite.AddTest('FontAndEditing', @TestFontAndEditing);
end;

end.

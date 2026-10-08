(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit uiNXVirtualTreeViewDemo;

{$mode objfpc}{$H+}

interface

procedure RunNXVirtualTreeViewDemo;

implementation

uses
  Classes, SysUtils, fpg_main, fpg_form, fpg_stylemanager, obNXControls, obNXSkin,
  obNXVirtualTreeView, obVTVTree, tpVTV;

type
  PDemoNodeData = ^TDemoNodeData;
  TDemoNodeData = record
    Caption, Kind: string;
  end;

  TNXVirtualTreeViewDemoForm = class(TNXForm)
  private
    FTree: TNXVirtualTreeView;
    FStatus: TNXLabel;
    FInitializedCount: Integer;
    FDescending: Boolean;
  protected
    procedure InitNode(ASender: TfpgVirtualStringTree; AParentNode,
      ANode: PVirtualNode; var AStates: TVirtualNodeInitStates);
    procedure InitChildren(ASender: TfpgVirtualStringTree; ANode: PVirtualNode;
      var AChildCount: Cardinal);
    procedure FreeNode(ASender: TfpgVirtualStringTree; ANode: PVirtualNode);
    procedure GetText(ASender: TfpgVirtualStringTree; ANode: PVirtualNode;
      AColumn: TColumnIndex; var AText: string);
    procedure NewText(ASender: TfpgVirtualStringTree; ANode: PVirtualNode;
      AColumn: TColumnIndex; const AText: string);
    procedure Changed(ASender: TfpgVirtualStringTree; ANode: PVirtualNode);
    procedure RefreshStatus;
    procedure ExpandClicked(ASender: TObject);
    procedure CollapseClicked(ASender: TObject);
    procedure SortClicked(ASender: TObject);
    procedure LastClicked(ASender: TObject);
  public
    procedure AfterCreate; override;
  end;

procedure TNXVirtualTreeViewDemoForm.AfterCreate;
var
  lBar, lFooter: TNXPanel;
  lButton: TNXButton;
  lHint: TNXLabel;
  lNode: PVirtualNode;
begin
  inherited AfterCreate;
  WindowTitle := 'Nexus Virtual TreeView - native fpGUI';
  WindowPosition := wpScreenCenter;
  Width := 960;
  Height := 700;
  MinWidth := 740;
  MinHeight := 400;

  lBar := TNXPanel.Create(Self);
  lBar.Align := alTop;
  lBar.Height := 48;

  lButton := TNXButton.Create(lBar);
  lButton.Left := 10;
  lButton.Top := 10;
  lButton.Width := 150;
  lButton.Height := 28;
  lButton.Text := 'Expand selected';
  lButton.OnClick := @ExpandClicked;
  lButton := TNXButton.Create(lBar);
  lButton.Left := 170;
  lButton.Top := 10;
  lButton.Width := 140;
  lButton.Height := 28;
  lButton.Text := 'Collapse all';
  lButton.OnClick := @CollapseClicked;
  lButton := TNXButton.Create(lBar);
  lButton.Left := 320;
  lButton.Top := 10;
  lButton.Width := 140;
  lButton.Height := 28;
  lButton.Text := 'Sort names';
  lButton.OnClick := @SortClicked;
  lButton := TNXButton.Create(lBar);
  lButton.Left := 470;
  lButton.Top := 10;
  lButton.Width := 170;
  lButton.Height := 28;
  lButton.Text := 'Jump to last branch';
  lButton.OnClick := @LastClicked;

  lFooter := TNXPanel.Create(Self);
  lFooter.Align := alBottom;
  lFooter.Height := 58;
  FStatus := TNXLabel.Create(lFooter);
  FStatus.Left := 10;
  FStatus.Top := 5;
  FStatus.Width := 920;
  FStatus.Height := 22;
  FStatus.Anchors := [anLeft, anRight, anTop];
  lHint := TNXLabel.Create(lFooter);
  lHint.Left := 10;
  lHint.Top := 29;
  lHint.Width := 920;
  lHint.Height := 22;
  lHint.Anchors := [anLeft, anRight, anTop];
  lHint.Text := 'Expand +  |  Ctrl/Shift select  |  F2 edits a name  |  Drag column edges to resize';

  FTree := TNXVirtualTreeView.Create(Self);
  FTree.Align := alClient;
  FTree.FontDesc := 'Arial-11';
  FTree.DefaultNodeHeight := 28;
  FTree.Header.Height := 32;
  FTree.Header.Columns[0].Text := 'Name (editable)';
  FTree.Header.Columns[0].Width := 420;
  FTree.Header.Columns[0].Editable := True;
  FTree.Header.Columns.Add.Text := 'Kind';
  FTree.Header.Columns[1].Width := 150;
  FTree.Header.Columns.Add.Text := 'Data';
  FTree.Header.Columns[2].Width := 260;
  FTree.TreeOptions.SelectionOptions := [toMultiSelect, toFullRowSelect];
  FTree.TreeOptions.PaintOptions := FTree.TreeOptions.PaintOptions +
    [toShowHorzGridLines, toShowVertGridLines];
  FTree.TreeOptions.MiscOptions := [toEditable, toCheckSupport];
  FTree.NodeDataSize := SizeOf(TDemoNodeData);
  FTree.OnInitNode := @InitNode;
  FTree.OnInitChildren := @InitChildren;
  FTree.OnFreeNode := @FreeNode;
  FTree.OnGetText := @GetText;
  FTree.OnNewText := @NewText;
  FTree.OnChange := @Changed;
  FTree.OnExpanded := @Changed;
  FTree.OnCollapsed := @Changed;
  FTree.OnChecked := @Changed;
  FTree.RootNodeCount := 100000;
  lNode := FTree.GetFirst;
  FTree.Expanded[lNode] := True;
  FTree.FocusedNode := lNode;
  FTree.Selected[lNode] := True;
  RefreshStatus;
end;

procedure TNXVirtualTreeViewDemoForm.InitNode(ASender: TfpgVirtualStringTree;
  AParentNode, ANode: PVirtualNode; var AStates: TVirtualNodeInitStates);
var
  lData: PDemoNodeData;
begin
  Inc(FInitializedCount);
  lData := ASender.GetNodeData(ANode);
  if AParentNode = nil then
  begin
    lData^.Caption := Format('Branch %.6d', [ANode^.Index + 1]);
    lData^.Kind := 'Lazy branch';
    Include(AStates, ivsHasChildren);
  end
  else
  begin
    lData^.Caption := Format('Item %d.%d', [AParentNode^.Index + 1, ANode^.Index + 1]);
    lData^.Kind := 'Leaf';
  end;
  ANode^.CheckType := ctCheckBox;
  RefreshStatus;
end;

procedure TNXVirtualTreeViewDemoForm.InitChildren(ASender: TfpgVirtualStringTree;
  ANode: PVirtualNode; var AChildCount: Cardinal);
begin
  AChildCount := 5;
end;

procedure TNXVirtualTreeViewDemoForm.FreeNode(ASender: TfpgVirtualStringTree;
  ANode: PVirtualNode);
begin
  Finalize(PDemoNodeData(ASender.GetNodeData(ANode))^);
end;

procedure TNXVirtualTreeViewDemoForm.GetText(ASender: TfpgVirtualStringTree;
  ANode: PVirtualNode; AColumn: TColumnIndex; var AText: string);
var
  lData: PDemoNodeData;
begin
  lData := ASender.GetNodeData(ANode);
  case AColumn of
    0: AText := lData^.Caption;
    1: AText := lData^.Kind;
    2: AText := 'Initialized on demand';
  end;
end;

procedure TNXVirtualTreeViewDemoForm.NewText(ASender: TfpgVirtualStringTree;
  ANode: PVirtualNode; AColumn: TColumnIndex; const AText: string);
begin
  if AColumn = 0 then PDemoNodeData(ASender.GetNodeData(ANode))^.Caption := AText;
end;

procedure TNXVirtualTreeViewDemoForm.Changed(ASender: TfpgVirtualStringTree;
  ANode: PVirtualNode);
begin
  RefreshStatus;
end;

procedure TNXVirtualTreeViewDemoForm.RefreshStatus;
begin
  FStatus.Text := Format('%d root branches | %d allocated nodes | %d initialized | %d selected',
    [FTree.RootNodeCount, FTree.TotalCount, FInitializedCount, FTree.SelectedCount]);
end;

procedure TNXVirtualTreeViewDemoForm.ExpandClicked(ASender: TObject);
begin
  if FTree.FocusedNode <> nil then FTree.Expanded[FTree.FocusedNode] := True;
  FTree.SetFocus;
end;

procedure TNXVirtualTreeViewDemoForm.CollapseClicked(ASender: TObject);
begin
  FTree.FullCollapse;
  FTree.SetFocus;
end;

procedure TNXVirtualTreeViewDemoForm.SortClicked(ASender: TObject);
begin
  FDescending := not FDescending;
  if FDescending then FTree.Sort(nil, 0, sdDescending)
  else FTree.Sort(nil, 0, sdAscending);
  FTree.SetFocus;
  RefreshStatus;
end;

procedure TNXVirtualTreeViewDemoForm.LastClicked(ASender: TObject);
begin
  FTree.FocusedNode := FTree.RootNode^.LastChild;
  FTree.ClearSelection;
  FTree.Selected[FTree.FocusedNode] := True;
  FTree.ScrollIntoView(FTree.FocusedNode);
  FTree.SetFocus;
end;

procedure RunNXVirtualTreeViewDemo;
var
  lForm: TNXVirtualTreeViewDemoForm;
begin
  fpgApplication.Initialize;
  fpgStyleManager.SetStyle('Nexus');
  fpgStyle := fpgStyleManager.Style;
  fpgApplication.AppTitle := 'Nexus Virtual TreeView';
  lForm := TNXVirtualTreeViewDemoForm.Create(nil);
  try
    lForm.Show;
    fpgApplication.Run;
  finally
    lForm.Free;
  end;
end;

end.

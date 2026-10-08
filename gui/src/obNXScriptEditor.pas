(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXScriptEditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, fpg_base, fpg_main, fpg_menu, obNXVirtualTreeView, obVTVTree,
  tpVTV, tpNexusScript, obNexusScriptModel, obNexusScriptLanguageDefinition,
  obNexusScriptEditDocument;

type
  TNXScriptEditor = class(TNXVirtualTreeView)
  private
    FDocument: TNexusScriptEditDocument;
    FMenu: TfpgPopupMenu;
    FPropertyItems, FDefinitionItems, FRootItems, FFormItems: TStringList;
    FMenuRevision: Integer;
    FTreeRevision, FRestoreOffset: Integer;
    FRestoreDefinition: Boolean;
    FOnDocumentChanged, FOnEditRejected: TNotifyEvent;
    procedure AddDefinitionNode(AParent: PVirtualNode;
      ADefinition: TNexusScriptSourceDefinition;
      AArrayOffset: Integer = -1; AArrayIndex: Integer = -1);
    procedure AddValueNode(AParent: PVirtualNode;
      ADefinition: TNexusScriptSourceDefinition; const APropertyName, ACaption: string;
      AValue: TNexusScriptSourceValue; AArrayOffset: Integer = -1;
      AArrayIndex: Integer = -1);
    procedure Rebuild;
    function OwnerOffset(ANode: PVirtualNode): Integer;
    function ArrayRule(ANode: PVirtualNode): TNSArrayRule;
    function NodeValue(ANode: PVirtualNode): TNexusScriptSourceValue;
    procedure NotifyRejected;
    function PromptValue(AOwnerOffset: Integer; ARule: TNSValueRule; AArrayRule: TNSArrayRule;
      AForm: TNSSourceForm; const AInitial: string; out ASource: string;
      const ACaption: string = 'Value'): Boolean;
    function ChooseForm(AForms: TNSSourceForms; out AForm: TNSSourceForm): Boolean;
    function PromptProperty(AOwnerOffset: Integer; ARule: TNSValueRule; const AName: string;
      out ASource: string): Boolean;
    function PromptDefinition(AOwnerOffset: Integer; const AKind: string; APath: TStrings;
      out AName, ABody: string): Boolean;
  protected
    procedure DocumentChanging(ASender: TObject);
    procedure DocumentChanged(ASender: TObject);
    procedure FreeNodeData(ASender: TfpgVirtualStringTree; ANode: PVirtualNode);
    procedure GetNodeText(ASender: TfpgVirtualStringTree; ANode: PVirtualNode;
      AColumn: TColumnIndex; var AText: string);
    function CanEditCell(ANode: PVirtualNode; AColumn: TColumnIndex): Boolean; override;
    function GetEditText(ANode: PVirtualNode; AColumn: TColumnIndex): string; override;
    procedure GetEditChoices(ANode: PVirtualNode; AColumn: TColumnIndex;
      AChoices: TStrings); override;
    function CommitEditText(ANode: PVirtualNode; AColumn: TColumnIndex;
      const AText: string): Boolean; override;
    procedure HandleRMouseUp(AX, AY: Integer; AShiftState: TShiftState); override;
    procedure HandleKeyPress(var AKeyCode: Word; var AShiftState: TShiftState;
      var AConsumed: Boolean); override;
    procedure PropertyClicked(ASender: TObject);
    procedure CustomPropertyClicked(ASender: TObject);
    procedure DefinitionClicked(ASender: TObject);
    procedure RootClicked(ASender: TObject);
    procedure CreateDefinition(AOwnerOffset: Integer; const AKind: string);
    procedure FormClicked(ASender: TObject);
    procedure AddItemClicked(ASender: TObject);
    procedure RemoveClicked(ASender: TObject);
    procedure UndoClicked(ASender: TObject);
    procedure RedoClicked(ASender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure LoadSource(const ASourceName, AText: string);
    procedure LoadFile(const AFileName: string);
    procedure ShowActions(AX, AY: Integer);
    function SetNodeValue(ANode: PVirtualNode; const AText: string): Boolean;
    function SetNodeSource(ANode: PVirtualNode; const ASource: string): Boolean;
    function CanRemove(ANode: PVirtualNode): Boolean;
    function Remove(ANode: PVirtualNode): Boolean;
    procedure GetPropertyChoices(ANode: PVirtualNode; AChoices: TStrings);
    procedure GetDefinitionChoices(ANode: PVirtualNode; AChoices: TStrings);
    procedure GetSourceForms(ANode: PVirtualNode; AChoices: TStrings);
    property Document: TNexusScriptEditDocument read FDocument;
    property OnDocumentChanged: TNotifyEvent read FOnDocumentChanged write FOnDocumentChanged;
    property OnEditRejected: TNotifyEvent read FOnEditRejected write FOnEditRejected;
  end;

implementation

uses
  SysUtils, uiNXScriptValueDialog, utNexusScriptEditing;

type
  TScriptNodeKind = (snDefinition, snProperty, snArrayItem);
  PScriptNodeData = ^TScriptNodeData;
  TScriptNodeData = record
    Kind: TScriptNodeKind;
    OwnerOffset, ValueOffset, ArrayOffset, ArrayIndex, Revision: Integer;
    Caption, PropertyName: string;
  end;

const
  cSourceForms: array[TNSSourceForm] of string =
    ('Literal', 'Array', 'Reference', 'Text composition', 'Inline definition');

constructor TNXScriptEditor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDocument := TNexusScriptEditDocument.Create;
  FRestoreOffset := -1;
  FDocument.OnChanging := @DocumentChanging;
  FDocument.OnChanged := @DocumentChanged;
  FPropertyItems := TStringList.Create;
  FDefinitionItems := TStringList.Create;
  FRootItems := TStringList.Create;
  FFormItems := TStringList.Create;
  NodeDataSize := SizeOf(TScriptNodeData);
  OnFreeNode := @FreeNodeData;
  OnGetText := @GetNodeText;
  Header.Columns[0].Text := 'Definition / property';
  Header.Columns[0].Width := 300;
  Header.Columns[0].Editable := True;
  Header.Columns.Add.Text := 'Value / name';
  Header.Columns[1].Width := 400;
  Header.Columns[1].Editable := True;
  Header.Columns.Add.Text := 'Type';
  Header.Columns[2].Width := 160;
  TreeOptions.MiscOptions := [toEditable];
  TreeOptions.SelectionOptions := [toFullRowSelect, toRightClickSelect];
  TreeOptions.PaintOptions := TreeOptions.PaintOptions +
    [toShowHorzGridLines, toShowVertGridLines];
  FocusedColumn := 1;
end;

destructor TNXScriptEditor.Destroy;
begin
  FDocument.OnChanging := nil;
  FDocument.OnChanged := nil;
  CancelEditNode;
  Clear;
  FreeAndNil(FDocument);
  FMenu.Free;
  FPropertyItems.Free;
  FDefinitionItems.Free;
  FRootItems.Free;
  FFormItems.Free;
  inherited Destroy;
end;

procedure TNXScriptEditor.LoadSource(const ASourceName, AText: string);
begin
  FDocument.LoadSource(ASourceName, AText);
end;

procedure TNXScriptEditor.LoadFile(const AFileName: string);
begin
  FDocument.LoadFile(AFileName);
end;

procedure TNXScriptEditor.DocumentChanging(ASender: TObject);
var
  lData: PScriptNodeData;
begin
  FRestoreOffset := -1;
  if FocusedNode <> nil then
  begin
    lData := GetNodeData(FocusedNode);
    FRestoreDefinition := lData^.Kind = snDefinition;
    if FRestoreDefinition then FRestoreOffset := lData^.OwnerOffset
    else FRestoreOffset := lData^.ValueOffset;
  end;
  CancelEditNode;
  Clear;
end;

procedure TNXScriptEditor.DocumentChanged(ASender: TObject);
begin
  if FTreeRevision <> FDocument.Revision then Rebuild;
  if Assigned(FOnDocumentChanged) then FOnDocumentChanged(Self);
end;

procedure TNXScriptEditor.Rebuild;
var
  lDefinition: TNexusScriptSourceDefinition;
  lNode: PVirtualNode;
  lData: PScriptNodeData;
  lOffset: Integer;
begin
  BeginUpdate;
  try
    Clear;
    if FDocument.SourceDocument <> nil then
      for lDefinition in FDocument.SourceDocument.Definitions do
        AddDefinitionNode(nil, lDefinition);
    FullExpand;
    lNode := GetFirst;
    while lNode <> nil do
    begin
      lData := GetNodeData(lNode);
      if lData^.Kind = snDefinition then lOffset := lData^.OwnerOffset
      else lOffset := lData^.ValueOffset;
      if (lOffset = FRestoreOffset) and
        ((lData^.Kind = snDefinition) = FRestoreDefinition) then
      begin
        FocusedNode := lNode;
        Selected[lNode] := True;
        Break;
      end;
      lNode := GetNext(lNode);
    end;
    FTreeRevision := FDocument.Revision;
  finally
    EndUpdate;
  end;
  if FocusedNode <> nil then ScrollIntoView(FocusedNode);
end;

procedure TNXScriptEditor.AddDefinitionNode(AParent: PVirtualNode;
  ADefinition: TNexusScriptSourceDefinition; AArrayOffset, AArrayIndex: Integer);
var
  lNode: PVirtualNode;
  lData: PScriptNodeData;
  lProperty: TNexusScriptSourceProperty;
  lChild: TNexusScriptSourceDefinition;
begin
  lNode := AddChild(AParent);
  lData := GetNodeData(lNode);
  lData^.Kind := snDefinition;
  lData^.OwnerOffset := ADefinition.SourceRange.StartPosition.Offset;
  lData^.ValueOffset := -1;
  if AArrayOffset <> -1 then lData^.ValueOffset := lData^.OwnerOffset;
  lData^.ArrayOffset := AArrayOffset;
  lData^.ArrayIndex := AArrayIndex;
  lData^.Revision := FDocument.Revision;
  lData^.Caption := ADefinition.Kind;
  for lProperty in ADefinition.Properties do
    AddValueNode(lNode, ADefinition, lProperty.Name, lProperty.Name, lProperty.Value);
  for lChild in ADefinition.Children do AddDefinitionNode(lNode, lChild);
end;

procedure TNXScriptEditor.AddValueNode(AParent: PVirtualNode;
  ADefinition: TNexusScriptSourceDefinition; const APropertyName, ACaption: string;
  AValue: TNexusScriptSourceValue; AArrayOffset, AArrayIndex: Integer);
var
  lNode: PVirtualNode;
  lData: PScriptNodeData;
  lItem: TNexusScriptSourceValue;
  lIndex: Integer;
  lCaption: string;
begin
  if AValue.InlineDefinition <> nil then
  begin
    AddDefinitionNode(AParent, AValue.InlineDefinition, AArrayOffset, AArrayIndex);
    Exit;
  end;
  lNode := AddChild(AParent);
  lData := GetNodeData(lNode);
  if AArrayOffset = -1 then lData^.Kind := snProperty else lData^.Kind := snArrayItem;
  lData^.OwnerOffset := ADefinition.SourceRange.StartPosition.Offset;
  lData^.ValueOffset := AValue.SourceRange.StartPosition.Offset;
  lData^.ArrayOffset := AArrayOffset;
  lData^.ArrayIndex := AArrayIndex;
  lData^.Revision := FDocument.Revision;
  lData^.Caption := ACaption;
  lData^.PropertyName := APropertyName;
  if AValue.Kind <> nsvArray then Exit;
  for lIndex := 0 to AValue.Items.Count - 1 do
  begin
    lItem := AValue.Items[lIndex];
    lCaption := '[' + IntToStr(lIndex) + ']';
    if lItem.EntryName <> '' then lCaption := lItem.EntryName;
    AddValueNode(lNode, ADefinition, APropertyName, lCaption, lItem,
      AValue.SourceRange.StartPosition.Offset, lIndex);
  end;
end;

procedure TNXScriptEditor.FreeNodeData(ASender: TfpgVirtualStringTree; ANode: PVirtualNode);
begin
  Finalize(PScriptNodeData(GetNodeData(ANode))^);
end;

function TNXScriptEditor.NodeValue(ANode: PVirtualNode): TNexusScriptSourceValue;
var
  lData: PScriptNodeData;
begin
  Result := nil;
  if ANode = nil then Exit;
  lData := GetNodeData(ANode);
  if lData^.Revision = FDocument.Revision then
    Result := FDocument.FindValue(lData^.ValueOffset);
end;

procedure TNXScriptEditor.GetNodeText(ASender: TfpgVirtualStringTree;
  ANode: PVirtualNode; AColumn: TColumnIndex; var AText: string);
var
  lData: PScriptNodeData;
  lValue: TNexusScriptSourceValue;
  lDefinition: TNexusScriptSourceDefinition;
  lRule: TNSPropertyRule;
begin
  lData := GetNodeData(ANode);
  if AColumn = 0 then
  begin
    AText := lData^.Caption;
    Exit;
  end;
  if lData^.Kind = snDefinition then
  begin
    lDefinition := FDocument.FindDefinition(lData^.OwnerOffset);
    if lDefinition = nil then Exit;
    if AColumn = 1 then AText := lDefinition.Name else AText := 'Definition';
    Exit;
  end;
  lValue := NodeValue(ANode);
  if lValue = nil then Exit;
  if AColumn = 1 then
  begin
    if lValue.Kind = nsvText then AText := lValue.Text
    else if lValue.Kind = nsvArray then AText := Format('[%d items]', [lValue.Items.Count])
    else AText := FDocument.SourceSlice(FDocument.ValueRange(lValue));
    Exit;
  end;
  case lValue.Kind of
    nsvReference: AText := 'Reference';
    nsvTextComposition: AText := 'Text composition';
    nsvArray: AText := 'Array';
  else
    AText := 'Text';
    lRule := FDocument.PropertyRule(lData^.OwnerOffset, lData^.PropertyName);
    if (lData^.Kind = snProperty) and (lRule <> nil) and (lRule.ValueRule <> nil) then
      case lRule.ValueRule.ScalarKind of
        nskBoolean: AText := 'Boolean';
        nskInteger: AText := 'Integer';
      end;
  end;
end;

function TNXScriptEditor.CanEditCell(ANode: PVirtualNode; AColumn: TColumnIndex): Boolean;
var
  lValue: TNexusScriptSourceValue;
  lData: PScriptNodeData;
  lArrayRule: TNSArrayRule;
begin
  Result := False;
  if (FDocument.Language = nil) or
    (FDocument.Language.DefinitionRuleCount = 0) then Exit;
  lData := GetNodeData(ANode);
  if AColumn = 0 then
  begin
    if lData^.Kind <> snArrayItem then Exit;
    lArrayRule := ArrayRule(ANode);
    Exit((lArrayRule = nil) or (lArrayRule.NamePolicy <> nnpForbidden));
  end;
  if AColumn <> 1 then Exit;
  if PScriptNodeData(GetNodeData(ANode))^.Kind = snDefinition then Exit(True);
  lValue := NodeValue(ANode);
  Result := (lValue <> nil) and (lValue.Kind <> nsvArray);
end;

function TNXScriptEditor.GetEditText(ANode: PVirtualNode; AColumn: TColumnIndex): string;
var
  lValue: TNexusScriptSourceValue;
begin
  if AColumn = 0 then
  begin
    lValue := NodeValue(ANode);
    if lValue <> nil then Exit(lValue.EntryName);
  end;
  Result := Text[ANode, AColumn];
end;

function TNXScriptEditor.ArrayRule(ANode: PVirtualNode): TNSArrayRule;
var
  lData: PScriptNodeData;
  lDefinition: TNexusScriptSourceDefinition;
  lProperty: TNexusScriptSourceProperty;
  lRule: TNSPropertyRule;
begin
  Result := nil;
  lData := GetNodeData(ANode);
  if lData^.Kind = snDefinition then
  begin
    if lData^.ArrayOffset <> -1 then Result := ArrayRule(ANode^.Parent);
    Exit;
  end;
  lDefinition := FDocument.FindDefinition(lData^.OwnerOffset);
  if lDefinition = nil then Exit;
  lProperty := lDefinition.FindProperty(lData^.PropertyName);
  if lProperty = nil then Exit;
  if (lData^.ArrayOffset <> -1) and
    (lData^.ArrayOffset <> lProperty.Value.SourceRange.StartPosition.Offset) then Exit;
  lRule := FDocument.PropertyRule(lData^.OwnerOffset, lData^.PropertyName);
  if (lRule <> nil) and (lRule.ValueRule <> nil) then Result := lRule.ValueRule.ArrayRule;
end;

procedure TNXScriptEditor.GetEditChoices(ANode: PVirtualNode;
  AColumn: TColumnIndex; AChoices: TStrings);
var
  lValue: TNexusScriptSourceValue;
  lData: PScriptNodeData;
  lRule: TNSPropertyRule;
  lArrayRule: TNSArrayRule;
  lIndex: Integer;
begin
  AChoices.Clear;
  if AColumn <> 1 then Exit;
  lValue := NodeValue(ANode);
  if lValue = nil then Exit;
  lData := GetNodeData(ANode);
  lRule := FDocument.PropertyRule(lData^.OwnerOffset, lData^.PropertyName);
  if lValue.Kind = nsvReference then
  begin
    if lData^.ArrayOffset <> -1 then
      FDocument.GetReferenceChoices(lData^.OwnerOffset, nil, ArrayRule(ANode), AChoices)
    else if (lRule <> nil) and (lRule.ValueRule <> nil) then
      FDocument.GetReferenceChoices(lData^.OwnerOffset, lRule.ValueRule.ReferenceRule, nil, AChoices)
    else FDocument.GetReferenceChoices(lData^.OwnerOffset, nil, nil, AChoices);
    Exit;
  end;
  if lValue.Kind <> nsvText then Exit;
  if lData^.ArrayOffset <> -1 then
  begin
    lArrayRule := ArrayRule(ANode);
    if lArrayRule <> nil then
      for lIndex := 0 to lArrayRule.AllowedValueCount - 1 do
        AChoices.Add(lArrayRule.AllowedValues[lIndex]);
    Exit;
  end;
  if (lRule = nil) or (lRule.ValueRule = nil) then Exit;
  for lIndex := 0 to lRule.ValueRule.AllowedValueCount - 1 do
    AChoices.Add(lRule.ValueRule.AllowedValues[lIndex]);
  if (AChoices.Count = 0) and (lRule.ValueRule.ScalarKind = nskBoolean) then
  begin
    AChoices.Add('False');
    AChoices.Add('True');
  end;
end;

function TNXScriptEditor.SetNodeSource(ANode: PVirtualNode; const ASource: string): Boolean;
var
  lValue: TNexusScriptSourceValue;
begin
  lValue := NodeValue(ANode);
  Result := (lValue <> nil) and
    FDocument.ReplaceValue(lValue.SourceRange.StartPosition.Offset, ASource);
end;

function TNXScriptEditor.SetNodeValue(ANode: PVirtualNode; const AText: string): Boolean;
var
  lData: PScriptNodeData;
  lValue: TNexusScriptSourceValue;
  lRule: TNSPropertyRule;
begin
  lData := GetNodeData(ANode);
  if lData^.Kind = snDefinition then
    Exit(FDocument.RenameDefinition(lData^.OwnerOffset, AText));
  lValue := NodeValue(ANode);
  if lValue = nil then Exit(False);
  if lValue.Kind = nsvText then
  begin
    if lValue.Text = AText then Exit(True);
    lRule := FDocument.PropertyRule(lData^.OwnerOffset, lData^.PropertyName);
    if (lData^.Kind = snProperty) and (lRule <> nil) and (lRule.ValueRule <> nil) and
      (lRule.ValueRule.ScalarKind in [nskBoolean, nskInteger]) then
      Result := SetNodeSource(ANode, AText)
    else Result := SetNodeSource(ANode, FDocument.QuoteText(AText));
  end
  else Result := SetNodeSource(ANode, AText);
end;

procedure TNXScriptEditor.NotifyRejected;
begin
  if Assigned(FOnEditRejected) then FOnEditRejected(Self);
end;

function TNXScriptEditor.CommitEditText(ANode: PVirtualNode;
  AColumn: TColumnIndex; const AText: string): Boolean;
var
  lData: PScriptNodeData;
begin
  if AColumn = 0 then
  begin
    lData := GetNodeData(ANode);
    Result := FDocument.RenameArrayEntry(lData^.ArrayOffset, lData^.ArrayIndex, AText);
  end
  else Result := SetNodeValue(ANode, AText);
  if not Result then NotifyRejected;
end;

function TNXScriptEditor.OwnerOffset(ANode: PVirtualNode): Integer;
begin
  Result := -1;
  if ANode <> nil then Result := PScriptNodeData(GetNodeData(ANode))^.OwnerOffset;
end;

procedure TNXScriptEditor.GetPropertyChoices(ANode: PVirtualNode; AChoices: TStrings);
begin
  FDocument.GetPropertyNames(OwnerOffset(ANode), AChoices);
end;

procedure TNXScriptEditor.GetDefinitionChoices(ANode: PVirtualNode; AChoices: TStrings);
begin
  FDocument.GetDefinitionKinds(OwnerOffset(ANode), AChoices);
end;

procedure TNXScriptEditor.GetSourceForms(ANode: PVirtualNode; AChoices: TStrings);
var
  lData: PScriptNodeData;
  lValue: TNexusScriptSourceValue;
  lRule: TNSPropertyRule;
  lArrayRule: TNSArrayRule;
  lForms: TNSSourceForms;
  lForm: TNSSourceForm;
begin
  AChoices.Clear;
  lValue := NodeValue(ANode);
  if lValue = nil then Exit;
  lData := GetNodeData(ANode);
  if lData^.ArrayOffset <> -1 then
  begin
    lArrayRule := ArrayRule(ANode);
    lForms := NexusScriptEditForms(nil, lArrayRule, True);
  end
  else
  begin
    lRule := FDocument.PropertyRule(lData^.OwnerOffset, lData^.PropertyName);
    if lRule <> nil then lForms := NexusScriptEditForms(lRule.ValueRule, nil, False)
    else lForms := NexusScriptEditForms(nil, nil, False);
  end;
  for lForm in lForms do AChoices.Add(cSourceForms[lForm]);
end;

function TNXScriptEditor.CanRemove(ANode: PVirtualNode): Boolean;
var
  lData: PScriptNodeData;
  lArray: TNexusScriptSourceValue;
  lRule: TNSArrayRule;
begin
  Result := False;
  if ANode = nil then Exit;
  lData := GetNodeData(ANode);
  if lData^.ArrayOffset <> -1 then
  begin
    lArray := FDocument.FindValue(lData^.ArrayOffset);
    lRule := ArrayRule(ANode^.Parent);
    Result := (lArray <> nil) and
      ((lRule = nil) or (lArray.Items.Count > lRule.Minimum));
  end
  else if lData^.Kind = snDefinition then
    Result := FDocument.CanRemoveDefinition(lData^.OwnerOffset)
  else if lData^.Kind = snProperty then
    Result := FDocument.CanRemoveProperty(lData^.OwnerOffset, lData^.PropertyName);
end;

function TNXScriptEditor.Remove(ANode: PVirtualNode): Boolean;
var
  lData: PScriptNodeData;
begin
  if not CanRemove(ANode) then Exit(False);
  lData := GetNodeData(ANode);
  if lData^.ArrayOffset <> -1 then
    Result := FDocument.RemoveArrayItem(lData^.ArrayOffset, lData^.ArrayIndex)
  else if lData^.Kind = snDefinition then
    Result := FDocument.RemoveDefinition(lData^.OwnerOffset)
  else Result := FDocument.RemoveProperty(lData^.OwnerOffset, lData^.PropertyName);
end;

function TNXScriptEditor.ChooseForm(AForms: TNSSourceForms;
  out AForm: TNSSourceForm): Boolean;
var
  lChoices: TStringList;
  lForm: TNSSourceForm;
  lText: string;
begin
  Result := False;
  lChoices := TStringList.Create;
  try
    for lForm in AForms do lChoices.Add(cSourceForms[lForm]);
    if lChoices.Count = 0 then Exit;
    if lChoices.Count = 1 then lText := lChoices[0]
    else if not RequestNXScriptValue('Value', 'Source form', '', lChoices, False, lText) then Exit;
    for lForm in AForms do
      if cSourceForms[lForm] = lText then
      begin
        AForm := lForm;
        Exit(True);
      end;
  finally
    lChoices.Free;
  end;
end;

function TNXScriptEditor.PromptProperty(AOwnerOffset: Integer; ARule: TNSValueRule; const AName: string;
  out ASource: string): Boolean;
var
  lForm: TNSSourceForm;
begin
  Result := ChooseForm(NexusScriptEditForms(ARule, nil, False), lForm);
  if Result then Result := PromptValue(AOwnerOffset, ARule, nil, lForm, '', ASource, AName);
end;

function TNXScriptEditor.PromptValue(AOwnerOffset: Integer; ARule: TNSValueRule; AArrayRule: TNSArrayRule;
  AForm: TNSSourceForm; const AInitial: string; out ASource: string;
  const ACaption: string): Boolean;
var
  lChoices: TStringList;
  lIndex: Integer;
  lText: string;
begin
  lChoices := TStringList.Create;
  try
    if AForm = nsfText then
    begin
      if AArrayRule <> nil then
        for lIndex := 0 to AArrayRule.AllowedValueCount - 1 do
          lChoices.Add(AArrayRule.AllowedValues[lIndex])
      else if ARule <> nil then
      begin
        for lIndex := 0 to ARule.AllowedValueCount - 1 do
          lChoices.Add(ARule.AllowedValues[lIndex]);
        if (lChoices.Count = 0) and (ARule.ScalarKind = nskBoolean) then
        begin
          lChoices.Add('False');
          lChoices.Add('True');
        end;
      end;
    end
    else if AForm = nsfReference then
    begin
      if ARule <> nil then
        FDocument.GetReferenceChoices(AOwnerOffset, ARule.ReferenceRule, AArrayRule, lChoices)
      else FDocument.GetReferenceChoices(AOwnerOffset, nil, AArrayRule, lChoices);
    end;
    Result := RequestNXScriptValue(ACaption, cSourceForms[AForm] + ' value', AInitial,
      lChoices, AForm in [nsfArray, nsfTextComposition, nsfInlineDefinition], lText);
    if not Result then Exit;
    if (AForm = nsfText) and ((ARule = nil) or
      not (ARule.ScalarKind in [nskBoolean, nskInteger])) then
      ASource := FDocument.QuoteText(lText)
    else ASource := lText;
  finally
    lChoices.Free;
  end;
end;

function TNXScriptEditor.PromptDefinition(AOwnerOffset: Integer; const AKind: string; APath: TStrings;
  out AName, ABody: string): Boolean;
var
  lRule: TNSDefinitionRule;
  lProperty: TNSPropertyRule;
  lChild: TNSChildRule;
  lChoices: TStringList;
  lSource, lKind, lName, lBody: string;
  lIndex, lItem, lKindIndex: Integer;
begin
  Result := False;
  ABody := '';
  if APath.IndexOf(AKind) >= 0 then
  begin
    FDocument.Diagnostics.Text := 'Required child rules recursively require ' + AKind + '.';
    NotifyRejected;
    Exit;
  end;
  if not RequestNXScriptValue('Create ' + AKind, 'Definition name', '', nil, False, AName) then Exit;
  lRule := FDocument.Language.FindDefinitionRule(AKind);
  if lRule = nil then Exit;
  lChoices := TStringList.Create;
  APath.Add(AKind);
  try
    for lIndex := 0 to lRule.PropertyRuleCount - 1 do
    begin
      lProperty := lRule.PropertyRules[lIndex];
      if not lProperty.Required then Continue;
      if not PromptProperty(AOwnerOffset, lProperty.ValueRule, lProperty.Name, lSource) then Exit;
      ABody := ABody + '  ' + lProperty.Name + ': ' + lSource + ';' + LineEnding;
    end;
    for lIndex := 0 to lRule.ChildRuleCount - 1 do
    begin
      lChild := lRule.ChildRules[lIndex];
      for lItem := 1 to lChild.Minimum do
      begin
        lChoices.Clear;
        for lKindIndex := 0 to lChild.KindCount - 1 do lChoices.Add(lChild.Kinds[lKindIndex]);
        if not RequestNXScriptValue('Required child ' + lChild.Name,
          'Definition kind', '', lChoices, False, lKind) then Exit;
        if not PromptDefinition(AOwnerOffset, lKind, APath, lName, lBody) then Exit;
        ABody := ABody + '  ' + lKind + ' ' + lName + ' {' + LineEnding +
          lBody + '  }' + LineEnding;
      end;
    end;
    Result := True;
  finally
    APath.Delete(APath.Count - 1);
    lChoices.Free;
  end;
end;

procedure TNXScriptEditor.ShowActions(AX, AY: Integer);
var
  lChoices: TStringList;
  lIndex: Integer;
  lMenu: TfpgPopupMenu;
  lValue: TNexusScriptSourceValue;
  lRule: TNSArrayRule;
  lDefinition: TNexusScriptSourceDefinition;
  lDefinitionRule: TNSDefinitionRule;
begin
  if not EndEditNode then Exit;
  FreeAndNil(FMenu);
  FMenu := TfpgPopupMenu.Create(Self);
  FPropertyItems.Clear;
  FDefinitionItems.Clear;
  FRootItems.Clear;
  FFormItems.Clear;
  FMenuRevision := FDocument.Revision;
  lChoices := TStringList.Create;
  try
    GetPropertyChoices(FocusedNode, lChoices);
    if lChoices.Count > 0 then
    begin
      lMenu := TfpgPopupMenu.Create(FMenu);
      FMenu.AddMenuItem('Add property', '', nil).SubMenu := lMenu;
      for lIndex := 0 to lChoices.Count - 1 do
        FPropertyItems.AddObject(lChoices[lIndex],
          lMenu.AddMenuItem(lChoices[lIndex], '', @PropertyClicked));
    end;
    lDefinition := FDocument.FindDefinition(OwnerOffset(FocusedNode));
    if lDefinition <> nil then
    begin
      lDefinitionRule := FDocument.Language.FindDefinitionRule(lDefinition.Kind);
      if (lDefinitionRule <> nil) and (lDefinitionRule.UnknownProperties = nupAllow) then
        FMenu.AddMenuItem('Add custom property', '', @CustomPropertyClicked);
    end;
    if FocusedNode <> nil then GetDefinitionChoices(FocusedNode, lChoices)
    else lChoices.Clear;
    if lChoices.Count > 0 then
    begin
      lMenu := TfpgPopupMenu.Create(FMenu);
      FMenu.AddMenuItem('Add child definition', '', nil).SubMenu := lMenu;
      for lIndex := 0 to lChoices.Count - 1 do
        FDefinitionItems.AddObject(lChoices[lIndex],
          lMenu.AddMenuItem(lChoices[lIndex], '', @DefinitionClicked));
    end;
    FDocument.GetDefinitionKinds(-1, lChoices);
    if lChoices.Count > 0 then
    begin
      lMenu := TfpgPopupMenu.Create(FMenu);
      FMenu.AddMenuItem('Add root definition', '', nil).SubMenu := lMenu;
      for lIndex := 0 to lChoices.Count - 1 do
        FRootItems.AddObject(lChoices[lIndex], lMenu.AddMenuItem(lChoices[lIndex], '', @RootClicked));
    end;
    if FocusedNode <> nil then
    begin
      GetSourceForms(FocusedNode, lChoices);
      if lChoices.Count > 0 then
      begin
        lMenu := TfpgPopupMenu.Create(FMenu);
        FMenu.AddMenuItem('Set value as', '', nil).SubMenu := lMenu;
        for lIndex := 0 to lChoices.Count - 1 do
          FFormItems.AddObject(lChoices[lIndex],
            lMenu.AddMenuItem(lChoices[lIndex], '', @FormClicked));
      end;
      lValue := NodeValue(FocusedNode);
      if (lValue <> nil) and (lValue.Kind = nsvArray) then
      begin
        lRule := ArrayRule(FocusedNode);
        FMenu.AddMenuItem('Add array item', '', @AddItemClicked).Enabled :=
          (lRule = nil) or (lRule.Maximum = cNexusScriptUnbounded) or
          (lValue.Items.Count < lRule.Maximum);
      end;
    end;
    FMenu.AddMenuItem('Remove', 'Delete', @RemoveClicked).Enabled := CanRemove(FocusedNode);
    FMenu.AddMenuItem('Undo', 'Ctrl+Z', @UndoClicked).Enabled := FDocument.CanUndo;
    FMenu.AddMenuItem('Redo', 'Ctrl+Y', @RedoClicked).Enabled := FDocument.CanRedo;
    FMenu.ShowAt(Self, AX, AY);
  finally
    lChoices.Free;
  end;
end;

procedure TNXScriptEditor.PropertyClicked(ASender: TObject);
var
  lIndex, lOwner: Integer;
  lRule: TNSPropertyRule;
  lName, lSource: string;
begin
  if FMenuRevision <> FDocument.Revision then Exit;
  lIndex := FPropertyItems.IndexOfObject(ASender);
  if lIndex < 0 then Exit;
  lOwner := OwnerOffset(FocusedNode);
  lName := FPropertyItems[lIndex];
  lRule := FDocument.PropertyRule(lOwner, lName);
  if not PromptProperty(lOwner, lRule.ValueRule, lName, lSource) then Exit;
  if not FDocument.SetProperty(lOwner, lName, lSource) then NotifyRejected;
end;

procedure TNXScriptEditor.CustomPropertyClicked(ASender: TObject);
var
  lName, lSource: string;
  lOwner: Integer;
begin
  if FMenuRevision <> FDocument.Revision then Exit;
  lOwner := OwnerOffset(FocusedNode);
  if not RequestNXScriptValue('Add property', 'Property name', '', nil, False, lName) then Exit;
  if not PromptProperty(OwnerOffset(FocusedNode), nil, lName, lSource) then Exit;
  if not FDocument.SetProperty(lOwner, lName, lSource) then NotifyRejected;
end;

procedure TNXScriptEditor.DefinitionClicked(ASender: TObject);
var
  lIndex: Integer;
begin
  if FMenuRevision <> FDocument.Revision then Exit;
  lIndex := FDefinitionItems.IndexOfObject(ASender);
  if lIndex < 0 then Exit;
  CreateDefinition(OwnerOffset(FocusedNode), FDefinitionItems[lIndex]);
end;

procedure TNXScriptEditor.RootClicked(ASender: TObject);
var
  lIndex: Integer;
begin
  if FMenuRevision <> FDocument.Revision then Exit;
  lIndex := FRootItems.IndexOfObject(ASender);
  if lIndex >= 0 then CreateDefinition(-1, FRootItems[lIndex]);
end;

procedure TNXScriptEditor.CreateDefinition(AOwnerOffset: Integer; const AKind: string);
var
  lName, lBody: string;
  lPath: TStringList;
begin
  lPath := TStringList.Create;
  try
    if not PromptDefinition(AOwnerOffset, AKind, lPath, lName, lBody) then Exit;
    if not FDocument.AddDefinition(AOwnerOffset, AKind, lName, lBody) then NotifyRejected;
  finally
    lPath.Free;
  end;
end;

procedure TNXScriptEditor.FormClicked(ASender: TObject);
var
  lIndex, lValueOffset: Integer;
  lData: PScriptNodeData;
  lRule: TNSPropertyRule;
  lForm: TNSSourceForm;
  lSource: string;
begin
  if FMenuRevision <> FDocument.Revision then Exit;
  lIndex := FFormItems.IndexOfObject(ASender);
  if lIndex < 0 then Exit;
  lData := GetNodeData(FocusedNode);
  lValueOffset := lData^.ValueOffset;
  lRule := FDocument.PropertyRule(lData^.OwnerOffset, lData^.PropertyName);
  for lForm := Low(TNSSourceForm) to High(TNSSourceForm) do
    if cSourceForms[lForm] = FFormItems[lIndex] then Break;
  if lData^.ArrayOffset <> -1 then
  begin
    if not PromptValue(lData^.OwnerOffset, nil, ArrayRule(FocusedNode), lForm, '', lSource) then Exit;
  end
  else if lRule <> nil then
  begin
    if not PromptValue(lData^.OwnerOffset, lRule.ValueRule, ArrayRule(FocusedNode), lForm, '', lSource) then Exit;
  end
  else if not PromptValue(lData^.OwnerOffset, nil, nil, lForm, '', lSource) then Exit;
  if not FDocument.ReplaceValue(lValueOffset, lSource) then NotifyRejected;
end;

procedure TNXScriptEditor.AddItemClicked(ASender: TObject);
var
  lValue: TNexusScriptSourceValue;
  lRule: TNSArrayRule;
  lOffset: Integer;
  lForm: TNSSourceForm;
  lAllowedForms: TNSSourceForms;
  lName, lSource, lKind, lBody: string;
  lChoices, lPath: TStringList;
  lIndex: Integer;
begin
  if FMenuRevision <> FDocument.Revision then Exit;
  lValue := NodeValue(FocusedNode);
  if (lValue = nil) or (lValue.Kind <> nsvArray) then Exit;
  lOffset := lValue.SourceRange.StartPosition.Offset;
  lRule := ArrayRule(FocusedNode);
  lAllowedForms := NexusScriptEditForms(nil, lRule, True);
  lChoices := TStringList.Create;
  lPath := TStringList.Create;
  try
    if not ChooseForm(lAllowedForms, lForm) then Exit;
    lName := '';
    if (lForm <> nsfInlineDefinition) and (lRule <> nil) and
      (lRule.NamePolicy <> nnpForbidden) then
      if not RequestNXScriptValue('Add array item', 'Entry name (blank if optional)',
        '', nil, False, lName) then Exit;
    if lForm = nsfInlineDefinition then
    begin
      FDocument.GetDefinitionKinds(OwnerOffset(FocusedNode), lChoices);
      if (lRule <> nil) and (lRule.DefinitionKindCount > 0) then
        for lIndex := lChoices.Count - 1 downto 0 do
          if not lRule.HasDefinitionKind(lChoices[lIndex]) then lChoices.Delete(lIndex);
      if lChoices.Count = 0 then Exit;
      if not RequestNXScriptValue('Add inline definition', 'Definition kind',
        '', lChoices, False, lKind) then Exit;
      if not PromptDefinition(OwnerOffset(FocusedNode), lKind, lPath, lName, lBody) then Exit;
      lSource := lKind + ' ' + lName + ' {' + LineEnding + lBody + '}';
      lName := '';
    end
    else if not PromptValue(OwnerOffset(FocusedNode), nil, lRule, lForm, '', lSource) then Exit;
    if not FDocument.AddArrayItem(lOffset, lSource, lName) then NotifyRejected;
  finally
    lPath.Free;
    lChoices.Free;
  end;
end;

procedure TNXScriptEditor.RemoveClicked(ASender: TObject);
begin
  if (FMenuRevision = FDocument.Revision) and not Remove(FocusedNode) then NotifyRejected;
end;

procedure TNXScriptEditor.UndoClicked(ASender: TObject);
begin
  FDocument.Undo;
end;

procedure TNXScriptEditor.RedoClicked(ASender: TObject);
begin
  FDocument.Redo;
end;

procedure TNXScriptEditor.HandleRMouseUp(AX, AY: Integer; AShiftState: TShiftState);
begin
  inherited HandleRMouseUp(AX, AY, AShiftState);
  ShowActions(AX, AY);
end;

procedure TNXScriptEditor.HandleKeyPress(var AKeyCode: Word;
  var AShiftState: TShiftState; var AConsumed: Boolean);
begin
  if (AKeyCode = keyZ) and (ssCtrl in AShiftState) then
  begin
    CancelEditNode;
    FDocument.Undo;
    AConsumed := True;
  end
  else if (AKeyCode = keyY) and (ssCtrl in AShiftState) then
  begin
    CancelEditNode;
    FDocument.Redo;
    AConsumed := True;
  end
  else if AKeyCode = keyDelete then
  begin
    if not Remove(FocusedNode) then NotifyRejected;
    AConsumed := True;
  end
  else if AKeyCode = keyInsert then
  begin
    ShowActions(8, Header.Height + 8);
    AConsumed := True;
  end
  else inherited HandleKeyPress(AKeyCode, AShiftState, AConsumed);
end;

end.

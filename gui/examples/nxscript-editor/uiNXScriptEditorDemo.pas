(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit uiNXScriptEditorDemo;

{$mode objfpc}{$H+}

interface

procedure RunNXScriptEditorDemo;

implementation

uses Classes, SysUtils, fpg_main, fpg_form, fpg_stylemanager, fpg_dialogs,
  obNXSkin, obNXControls, obNXScriptEditor;

type
  TNXScriptEditorDemoForm = class(TNXForm)
  private
    FEditor: TNXScriptEditor;
    FSource: TNXMemo;
    FStatus: TNXLabel;
  protected
    procedure RefreshDisplay(ASender: TObject);
    procedure Rejected(ASender: TObject);
    procedure OpenClicked(ASender: TObject);
    procedure SaveClicked(ASender: TObject);
    procedure UndoClicked(ASender: TObject);
    procedure RedoClicked(ASender: TObject);
    procedure ActionsClicked(ASender: TObject);
    procedure HandleClose; override;
  public
    procedure AfterCreate; override;
    procedure OpenFile(const AFileName: string);
  end;

procedure TNXScriptEditorDemoForm.AfterCreate;
var
  lBar: TNXPanel;
  lButton: TNXButton;

  procedure AddButton(const ACaption: string; ALeft: Integer; AHandler: TNotifyEvent);
  begin
    lButton := TNXButton.Create(lBar);
    lButton.Left := ALeft;
    lButton.Top := 10;
    lButton.Width := 110;
    lButton.Height := 30;
    lButton.Text := ACaption;
    lButton.OnClick := AHandler;
  end;

begin
  inherited AfterCreate;
  WindowTitle := 'NexusScript structural editor';
  WindowPosition := wpScreenCenter;
  Width := 1080;
  Height := 800;
  MinWidth := 800;
  MinHeight := 480;
  lBar := TNXPanel.Create(Self);
  lBar.Align := alTop;
  lBar.Height := 52;
  AddButton('Open', 12, @OpenClicked);
  AddButton('Save', 132, @SaveClicked);
  AddButton('Undo', 252, @UndoClicked);
  AddButton('Redo', 372, @RedoClicked);
  AddButton('Actions', 492, @ActionsClicked);
  FStatus := TNXLabel.Create(Self);
  FStatus.Align := alBottom;
  FStatus.Height := 32;
  FSource := TNXMemo.Create(Self);
  FSource.Align := alBottom;
  FSource.Height := 230;
  FSource.ReadOnly := True;
  FSource.FontDesc := 'Courier New-10';
  FEditor := TNXScriptEditor.Create(Self);
  FEditor.Align := alClient;
  FEditor.FontDesc := 'Arial-11';
  FEditor.DefaultNodeHeight := 28;
  FEditor.Header.Height := 32;
  FEditor.OnDocumentChanged := @RefreshDisplay;
  FEditor.OnEditRejected := @Rejected;
  RefreshDisplay(Self);
end;

procedure TNXScriptEditorDemoForm.RefreshDisplay(ASender: TObject);
begin
  FSource.Text := FEditor.Document.SourceText;
  FStatus.Text := 'F2 / double-click a value | Right-click / Insert for supported actions';
  if FEditor.Document.Dirty then FStatus.Text := '* Unsaved | ' + FStatus.Text;
  WindowTitle := 'NexusScript structural editor - ' + ExtractFileName(FEditor.Document.SourceName);
  if not FEditor.Document.Valid and (FEditor.Document.Diagnostics.Count > 0) then Rejected(Self);
end;

procedure TNXScriptEditorDemoForm.Rejected(ASender: TObject);
begin
  if FEditor.Document.Diagnostics.Count > 0 then
    FStatus.Text := 'Edit not accepted: ' + FEditor.Document.Diagnostics[0];
end;

procedure TNXScriptEditorDemoForm.OpenFile(const AFileName: string);
begin
  FEditor.LoadFile(AFileName);
end;

procedure TNXScriptEditorDemoForm.OpenClicked(ASender: TObject);
var
  lName: string;
begin
  if FEditor.Document.Dirty and (TfpgMessageDialog.Question('Unsaved changes',
    'Discard the unsaved changes?') <> mbYes) then Exit;
  lName := SelectFileDialog(sfdOpen, 'NexusScript|*.nxscript|All files|*');
  if lName = '' then Exit;
  try
    OpenFile(lName);
  except
    on E: Exception do TfpgMessageDialog.Critical('Open failed', E.Message);
  end;
end;

procedure TNXScriptEditorDemoForm.SaveClicked(ASender: TObject);
begin
  if not FEditor.EndEditNode then Exit;
  try
    FEditor.Document.Save;
  except
    on E: Exception do TfpgMessageDialog.Critical('Save failed', E.Message);
  end;
end;

procedure TNXScriptEditorDemoForm.UndoClicked(ASender: TObject);
begin
  FEditor.CancelEditNode;
  FEditor.Document.Undo;
end;

procedure TNXScriptEditorDemoForm.RedoClicked(ASender: TObject);
begin
  FEditor.CancelEditNode;
  FEditor.Document.Redo;
end;

procedure TNXScriptEditorDemoForm.ActionsClicked(ASender: TObject);
begin
  FEditor.ShowActions(12, FEditor.Header.Height + 8);
end;

procedure TNXScriptEditorDemoForm.HandleClose;
begin
  if not FEditor.Document.Dirty or (TfpgMessageDialog.Question('Unsaved changes',
    'Discard the unsaved changes?') = mbYes) then inherited HandleClose;
end;

procedure RunNXScriptEditorDemo;
var
  lForm: TNXScriptEditorDemoForm;
  lName: string;
  lSmoke: Boolean;
begin
  fpgApplication.Initialize;
  fpgStyleManager.SetStyle('Nexus');
  fpgStyle := fpgStyleManager.Style;
  fpgApplication.AppTitle := 'NexusScript editor';
  lSmoke := ParamStr(1) = '--smoke';
  lName := ParamStr(1);
  if lSmoke then lName := ParamStr(2);
  if lName = '' then lName := 'packages/nexus-packages/gui/examples/nxscript-editor/Demo.nxscript';
  lForm := TNXScriptEditorDemoForm.Create(nil);
  try
    lForm.OpenFile(lName);
    lForm.Show;
    if lSmoke then
    begin
      fpgApplication.ProcessMessages;
      fpgApplication.ProcessMessages;
      lForm.Close;
    end
    else fpgApplication.Run;
  finally
    lForm.Free;
  end;
end;

end.

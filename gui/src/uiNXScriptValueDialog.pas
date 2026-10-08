(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit uiNXScriptValueDialog;

{$mode objfpc}{$H+}

interface

uses Classes;

function RequestNXScriptValue(const ACaption, APrompt, AInitial: string;
  AChoices: TStrings; ASourceSyntax: Boolean; out AValue: string): Boolean;

implementation

uses fpg_base, fpg_main, fpg_form, fpg_label, fpg_edit, fpg_combobox,
  fpg_memo, fpg_button;

type
  TNXScriptValueDialog = class(TfpgForm)
  private
    FPrompt: TfpgLabel;
    FEdit: TfpgEdit;
    FChoices: TfpgComboBox;
    FSource: TfpgMemo;
    FAccept: TfpgButton;
  protected
    procedure AcceptClicked(ASender: TObject);
    procedure CancelClicked(ASender: TObject);
    procedure SelectionChanged(ASender: TObject);
  public
    procedure AfterCreate; override;
    procedure Configure(const ACaption, APrompt, AInitial: string;
      AChoices: TStrings; ASourceSyntax: Boolean);
    function Value: string;
  end;

procedure TNXScriptValueDialog.AfterCreate;
var
  lButton: TfpgButton;
begin
  inherited AfterCreate;
  WindowPosition := wpScreenCenter;
  Width := 580;
  Height := 320;
  FPrompt := TfpgLabel.Create(Self);
  FPrompt.Left := 12;
  FPrompt.Top := 12;
  FPrompt.Width := 556;
  FPrompt.Height := 24;
  FEdit := TfpgEdit.Create(Self);
  FEdit.Left := 12;
  FEdit.Top := 44;
  FEdit.Width := 556;
  FEdit.Height := 28;
  FChoices := TfpgComboBox.Create(Self);
  FChoices.OnChange := @SelectionChanged;
  FChoices.Left := 12;
  FChoices.Top := 44;
  FChoices.Width := 556;
  FChoices.Height := 28;
  FSource := TfpgMemo.Create(Self);
  FSource.Left := 12;
  FSource.Top := 44;
  FSource.Width := 556;
  FSource.Height := 216;
  FSource.FontDesc := 'Courier New-11';
  lButton := TfpgButton.Create(Self);
  lButton.Left := 364;
  lButton.Top := 276;
  lButton.Width := 96;
  lButton.Height := 30;
  lButton.Text := 'OK';
  lButton.OnClick := @AcceptClicked;
  FAccept := lButton;
  lButton := TfpgButton.Create(Self);
  lButton.Left := 472;
  lButton.Top := 276;
  lButton.Width := 96;
  lButton.Height := 30;
  lButton.Text := 'Cancel';
  lButton.OnClick := @CancelClicked;
end;

procedure TNXScriptValueDialog.Configure(const ACaption, APrompt, AInitial: string;
  AChoices: TStrings; ASourceSyntax: Boolean);
begin
  WindowTitle := ACaption;
  FPrompt.Text := APrompt;
  FChoices.Visible := (AChoices <> nil) and (AChoices.Count > 0);
  FSource.Visible := not FChoices.Visible and ASourceSyntax;
  FEdit.Visible := not FChoices.Visible and not FSource.Visible;
  if FChoices.Visible then
  begin
    FChoices.Items.Assign(AChoices);
    FChoices.Text := AInitial;
    ActiveWidget := FChoices;
  end
  else if FSource.Visible then
  begin
    FSource.Text := AInitial;
    ActiveWidget := FSource;
  end
  else
  begin
    FEdit.Text := AInitial;
    ActiveWidget := FEdit;
  end;
  SelectionChanged(Self);
end;

function TNXScriptValueDialog.Value: string;
begin
  if FChoices.Visible then Result := FChoices.Text
  else if FSource.Visible then Result := FSource.Text
  else Result := FEdit.Text;
end;

procedure TNXScriptValueDialog.AcceptClicked(ASender: TObject);
begin
  if FAccept.Enabled then ModalResult := mrOK;
end;

procedure TNXScriptValueDialog.SelectionChanged(ASender: TObject);
begin
  if FAccept <> nil then
    FAccept.Enabled := not FChoices.Visible or (FChoices.FocusItem >= 0);
end;

procedure TNXScriptValueDialog.CancelClicked(ASender: TObject);
begin
  ModalResult := mrCancel;
end;

function RequestNXScriptValue(const ACaption, APrompt, AInitial: string;
  AChoices: TStrings; ASourceSyntax: Boolean; out AValue: string): Boolean;
var
  lDialog: TNXScriptValueDialog;
begin
  AValue := '';
  lDialog := TNXScriptValueDialog.Create(nil);
  try
    lDialog.Configure(ACaption, APrompt, AInitial, AChoices, ASourceSyntax);
    Result := lDialog.ShowModal = mrOK;
    if Result then AValue := lDialog.Value;
  finally
    lDialog.Free;
  end;
end;

end.

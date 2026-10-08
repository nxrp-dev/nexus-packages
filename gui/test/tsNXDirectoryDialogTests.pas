(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tsNXDirectoryDialogTests;

{$mode objfpc}{$H+}

interface

uses obNXTestRegistry;

procedure RegisterNXDirectoryDialogTests(ARegistry: TNXTestRegistry);

implementation

uses SysUtils, obNXTestSuite, obNXTestContext, fpg_base, fpg_main,
  fpg_widget, fpg_form, fpg_dialogs, fpg_editbtn, fpg_tree, fpg_button;

type
  TChooserHostForm = class(TfpgForm)
  public
    procedure AllocateForTest;
  end;

  TChooserDialog = class(TfpgSelectDirDialog)
  public
    procedure AllocateForTest;
    property Tree: TfpgTreeView read tv;
    property OKButton: TfpgButton read btnOK;
    property CancelButton: TfpgButton read btnCancel;
  end;

procedure TChooserHostForm.AllocateForTest;
begin
  WindowPosition := wpUser;
  DoAllocateWindowHandle;
  Window.AllocateWindowHandle;
end;

procedure TChooserDialog.AllocateForTest;
begin
  DoAllocateWindowHandle;
  Window.AllocateWindowHandle;
end;

procedure TestResize(AContext: TNXTestContext);
var
  lDialog: TChooserDialog;
  lTreeWidth, lTreeHeight, lButtonHeight, lBottomGap: Integer;
  lSelected: string;
begin
  lDialog := TChooserDialog.Create(nil);
  try
    lDialog.SelectedDir := ExpandFileName('packages2/nexus-packages/gui');
    lSelected := lDialog.SelectedDir;
    lDialog.Realign;
    lTreeWidth := lDialog.Tree.ActualWidth;
    lTreeHeight := lDialog.Tree.ActualHeight;
    lButtonHeight := lDialog.CancelButton.ActualHeight;
    lBottomGap := lDialog.ActualHeight - lDialog.CancelButton.Top - lButtonHeight;
    lDialog.Width := 500;
    lDialog.Height := 570;
    lDialog.Realign;
    AContext.AssertEquals(lTreeWidth + 200, lDialog.Tree.ActualWidth,
      'The folder tree consumes added horizontal space.');
    AContext.AssertEquals(lTreeHeight + 200, lDialog.Tree.ActualHeight,
      'The folder tree consumes added vertical space.');
    AContext.AssertEquals(lButtonHeight, lDialog.CancelButton.ActualHeight,
      'Buttons keep their height rather than growing with the tree.');
    AContext.AssertEquals(lBottomGap,
      lDialog.ActualHeight - lDialog.CancelButton.Top - lDialog.CancelButton.ActualHeight,
      'The button row stays at the bottom.');
    AContext.AssertTrue(lDialog.OKButton.Top >= lDialog.Tree.Top + lDialog.Tree.ActualHeight,
      'Buttons do not overlap the folder tree.');
    lDialog.Width := 300;
    lDialog.Height := 370;
    lDialog.Realign;
    AContext.AssertEquals(lTreeWidth, lDialog.Tree.ActualWidth, 'Shrinking restores the tree width.');
    AContext.AssertEquals(lTreeHeight, lDialog.Tree.ActualHeight, 'Shrinking restores the tree height.');
    AContext.AssertEquals(lSelected, lDialog.SelectedDir, 'Resizing preserves folder selection.');
  finally
    lDialog.Free;
  end;
end;

procedure TestBelowInitialSize(AContext: TNXTestContext);
var
  lDialog: TChooserDialog;
  lTreeWidth, lTreeHeight, lButtonWidth, lButtonHeight, lBottomGap: Integer;
  lButton: TfpgButton;
  lSelected: string;
  lIndex: Integer;
begin
  lDialog := TChooserDialog.Create(nil);
  try
    lDialog.SelectedDir := ExpandFileName('packages2/nexus-packages/gui');
    lSelected := lDialog.SelectedDir;
    lDialog.Realign;
    lTreeWidth := lDialog.Tree.ActualWidth;
    lTreeHeight := lDialog.Tree.ActualHeight;
    lButtonWidth := lDialog.CancelButton.ActualWidth;
    lButtonHeight := lDialog.CancelButton.ActualHeight;
    lBottomGap := lDialog.ActualHeight - lDialog.CancelButton.Top - lButtonHeight;
    AContext.AssertTrue((lDialog.MinWidth < 300) and (lDialog.MinHeight < 370),
      'The chooser can shrink below its initial size.');
    lDialog.Width := lDialog.MinWidth;
    lDialog.Height := lDialog.MinHeight;
    lDialog.Realign;
    AContext.AssertTrue(lDialog.Tree.ActualWidth < lTreeWidth,
      'The tree absorbs the horizontal reduction.');
    AContext.AssertTrue(lDialog.Tree.ActualHeight < lTreeHeight,
      'The tree absorbs the vertical reduction.');
    AContext.AssertTrue(lDialog.Tree.ActualWidth >= lDialog.Tree.MinWidth,
      'The minimum dialog width leaves a usable tree.');
    AContext.AssertTrue(lDialog.Tree.ActualHeight >= lDialog.Tree.MinHeight,
      'The minimum dialog height leaves a usable tree.');
    for lIndex := 0 to 1 do
    begin
      if lIndex = 0 then
        lButton := lDialog.OKButton
      else
        lButton := lDialog.CancelButton;
      AContext.AssertEquals(lButtonWidth, lButton.ActualWidth,
        'Both buttons keep their normal width at the minimum dialog size.');
      AContext.AssertEquals(lButtonHeight, lButton.ActualHeight,
        'Both buttons keep their normal height at the minimum dialog size.');
      AContext.AssertEquals(lBottomGap,
        lDialog.ActualHeight - lButton.Top - lButton.ActualHeight,
        'Both buttons stay at the bottom when the chooser shrinks.');
      AContext.AssertTrue(lButton.Top >= lDialog.Tree.Top + lDialog.Tree.ActualHeight,
        'Buttons remain below the tree at the minimum size.');
      AContext.AssertTrue((lButton.Left >= 0) and
        (lButton.Left + lButton.ActualWidth <= lDialog.ActualWidth),
        'Both buttons remain fully inside the chooser.');
    end;
    AContext.AssertTrue(
      (lDialog.OKButton.Left + lDialog.OKButton.ActualWidth <= lDialog.CancelButton.Left) or
      (lDialog.CancelButton.Left + lDialog.CancelButton.ActualWidth <= lDialog.OKButton.Left),
      'The buttons do not overlap at the minimum size.');
    AContext.AssertEquals(lSelected, lDialog.SelectedDir,
      'Shrinking below the initial size preserves folder selection.');
    lDialog.Width := 1;
    lDialog.Height := 1;
    AContext.AssertEquals(lDialog.MinWidth, lDialog.ActualWidth,
      'The dialog clamps a requested width below its usable minimum.');
    AContext.AssertEquals(lDialog.MinHeight, lDialog.ActualHeight,
      'The dialog clamps a requested height below its usable minimum.');
  finally
    lDialog.Free;
  end;
end;

procedure TestInvokingForm(AContext: TNXTestContext);
var
  lMain, lOwner: TChooserHostForm;
  lContainer: TfpgWidget;
  lEdit: TfpgDirectoryEdit;
  lDialog: TChooserDialog;
  lPreviousMain: TfpgWidgetBase;
begin
  lPreviousMain := fpgApplication.MainForm;
  lMain := TChooserHostForm.Create(nil);
  lOwner := TChooserHostForm.Create(nil);
  lDialog := nil;
  try
    lMain.Left := 40;
    lMain.Top := 40;
    lMain.Width := 300;
    lMain.Height := 200;
    lMain.AllocateForTest;
    fpgApplication.MainForm := lMain;
    lOwner.Left := 420;
    lOwner.Top := 160;
    lOwner.Width := 700;
    lOwner.Height := 500;
    lOwner.AllocateForTest;
    lContainer := TfpgWidget.Create(lOwner);
    lEdit := TfpgDirectoryEdit.Create(lContainer);
    lDialog := TChooserDialog.Create(lEdit);
    lDialog.AllocateForTest;
    AContext.AssertEquals(lOwner.Left + (lOwner.ActualWidth - lDialog.Width) div 2,
      lDialog.Left, 'The chooser centers horizontally on the invoking form, not MainForm.');
    AContext.AssertEquals(lOwner.Top + (lOwner.ActualHeight - lDialog.Height) div 2,
      lDialog.Top, 'Nested controls use the invoking form for vertical centering.');
    AContext.AssertEquals(lDialog.Left, lDialog.Window.Left,
      'The native window receives the centered horizontal position before display.');
    AContext.AssertEquals(lDialog.Top, lDialog.Window.Top,
      'The native window receives the centered vertical position before display.');
  finally
    lDialog.Free;
    lOwner.Free;
    lMain.Free;
    fpgApplication.MainForm := lPreviousMain;
  end;
end;

procedure TestExplicitPosition(AContext: TNXTestContext);
var
  lOwner: TChooserHostForm;
  lDialog: TChooserDialog;
  lPreviousMain: TfpgWidgetBase;
begin
  lPreviousMain := fpgApplication.MainForm;
  lOwner := TChooserHostForm.Create(nil);
  lDialog := nil;
  try
    lOwner.Left := 400;
    lOwner.Top := 200;
    lOwner.AllocateForTest;
    lDialog := TChooserDialog.Create(lOwner);
    lDialog.WindowPosition := wpUser;
    lDialog.Left := 75;
    lDialog.Top := 90;
    lDialog.AllocateForTest;
    AContext.AssertEquals(75, lDialog.Left, 'An explicit position overrides default owner centering.');
    AContext.AssertEquals(90, lDialog.Top);
  finally
    lDialog.Free;
    lOwner.Free;
    fpgApplication.MainForm := lPreviousMain;
  end;
end;

procedure TestOwnerlessPosition(AContext: TNXTestContext);
var
  lDialog: TChooserDialog;
  lGeometry: TfpgRect;
  lPreviousMain: TfpgWidgetBase;
begin
  lPreviousMain := fpgApplication.MainForm;
  lDialog := TChooserDialog.Create(nil);
  try
    lGeometry := fpgApplication.Desktop.AvailableGeometry(fpgApplication.Desktop.PrimaryScreen);
    lDialog.AllocateForTest;
    AContext.AssertEquals(lGeometry.Left + (lGeometry.Width - lDialog.Width) div 2,
      lDialog.Left, 'An ownerless chooser retains its screen-position fallback.');
    AContext.AssertEquals(lGeometry.Top + (lGeometry.Height - lDialog.Height) div 3,
      lDialog.Top);
  finally
    lDialog.Free;
    fpgApplication.MainForm := lPreviousMain;
  end;
end;

procedure RegisterNXDirectoryDialogTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('DirectoryDialog');
  lSuite.AddTest('ResizeGrowAndShrink', @TestResize);
  lSuite.AddTest('BelowInitialSizeKeepsButtonsUsable', @TestBelowInitialSize);
  lSuite.AddTest('CenterOnInvokingForm', @TestInvokingForm);
  lSuite.AddTest('ExplicitPositionIsPreserved', @TestExplicitPosition);
  lSuite.AddTest('OwnerlessScreenFallback', @TestOwnerlessPosition);
end;

end.

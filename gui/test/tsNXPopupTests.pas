(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tsNXPopupTests;

{$mode objfpc}{$H+}

interface

uses obNXTestRegistry;

procedure RegisterNXPopupTests(ARegistry: TNXTestRegistry);

implementation

uses Classes, SysUtils, Windows, obNXTestSuite, obNXTestContext,
  fpg_base, fpg_main, fpg_widget, fpg_form, fpg_button, fpg_combobox,
  fpg_popupwindow;

type
  THiddenForm = class(TfpgForm)
  public
    procedure AllocateForTest;
  end;

  THiddenPopup = class(TfpgPopupWindow)
  protected
    procedure HandleShow; override;
  end;

  TPopupFixture = class
  private
    FForm: THiddenForm;
    FButton: TfpgButton;
    FPopup: THiddenPopup;
    FClicks: Integer;
    FCloses: Integer;
    procedure ButtonClick(ASender: TObject);
    procedure PopupClose(ASender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
    procedure DestroyReceiver(ASender: TObject);
    property Form: THiddenForm read FForm;
    property Button: TfpgButton read FButton;
    property Popup: THiddenPopup read FPopup;
    property Clicks: Integer read FClicks;
    property Closes: Integer read FCloses;
  end;

procedure THiddenForm.AllocateForTest;
begin
  WindowPosition := wpUser;
  DoAllocateWindowHandle;
  Window.AllocateWindowHandle;
end;

procedure THiddenPopup.HandleShow;
begin
  // Exercise real native handles and input dispatch without displaying a UI.
  DoAllocateWindowHandle;
  Window.AllocateWindowHandle;
end;

constructor TPopupFixture.Create;
var
  lContainer: TfpgWidget;
begin
  inherited Create;
  FForm := THiddenForm.Create(nil);
  FForm.Left := 100;
  FForm.Top := 100;
  FForm.Width := 300;
  FForm.Height := 200;
  lContainer := TfpgWidget.Create(FForm);
  lContainer.Left := 20;
  lContainer.Top := 20;
  lContainer.Width := 140;
  lContainer.Height := 60;
  FButton := TfpgButton.Create(lContainer);
  FButton.Left := 15;
  FButton.Top := 10;
  FButton.Width := 90;
  FButton.Height := 25;
  FButton.Text := 'Outside';
  FButton.OnClick := @ButtonClick;
  FForm.AllocateForTest;
  FocusRootWidget := FForm;
  FPopup := THiddenPopup.Create(nil);
  FPopup.Width := 160;
  FPopup.Height := 100;
  FPopup.OnClose := @PopupClose;
  FPopup.ShowAt(FForm, 180, 40);
end;

destructor TPopupFixture.Destroy;
begin
  ClosePopups;
  FocusRootWidget := nil;
  FPopup.Free;
  FForm.Free;
  inherited Destroy;
end;

procedure TPopupFixture.ButtonClick(ASender: TObject);
begin
  Inc(FClicks);
end;

procedure TPopupFixture.PopupClose(ASender: TObject);
begin
  Inc(FCloses);
end;

procedure TPopupFixture.DestroyReceiver(ASender: TObject);
begin
  FreeAndNil(FForm);
end;

procedure Mouse(AWidget: TfpgWidget; AMessage: UINT; AX, AY: TfpgCoord);
begin
  AWidget.WidgetToWindow(AX, AY);
  Windows.SendMessage(AWidget.Window.WinHandle, AMessage, 0,
    LPARAM((AY and $FFFF) shl 16 or (AX and $FFFF)));
end;

procedure TestOutsideButtons(AContext: TNXTestContext);
const
  cDown: array[0..2] of UINT = (WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_MBUTTONDOWN);
  cUp: array[0..2] of UINT = (WM_LBUTTONUP, WM_RBUTTONUP, WM_MBUTTONUP);
var
  lFixture: TPopupFixture;
  lIndex: Integer;
begin
  for lIndex := 0 to High(cDown) do
  begin
    lFixture := TPopupFixture.Create;
    try
      Mouse(lFixture.Button, cDown[lIndex], 5, 5);
      Mouse(lFixture.Button, cUp[lIndex], 5, 5);
      AContext.AssertTrue(PopupListFirst = nil, 'An outside mouse press must dismiss the popup.');
      AContext.AssertEquals(1, lFixture.Closes);
      AContext.AssertEquals(Ord(lIndex = 0), lFixture.Clicks, 'The outside click must arrive exactly once.');
      AContext.AssertTrue(FocusRootWidget = lFixture.Form);
    finally
      lFixture.Free;
    end;
  end;
end;

procedure TestInsideChild(AContext: TNXTestContext);
var
  lFixture: TPopupFixture;
  lChild: TfpgButton;
begin
  lFixture := TPopupFixture.Create;
  try
    lChild := TfpgButton.Create(lFixture.Popup);
    lChild.Left := 10;
    lChild.Top := 10;
    lChild.Width := 90;
    lChild.Height := 25;
    Mouse(lChild, WM_LBUTTONDOWN, 5, 5);
    Mouse(lChild, WM_LBUTTONUP, 5, 5);
    AContext.AssertTrue(PopupListFirst = lFixture.Popup);
    AContext.AssertEquals(0, lFixture.Closes);
  finally
    lFixture.Free;
  end;
end;

procedure TestNestedPopups(AContext: TNXTestContext);
var
  lFixture: TPopupFixture;
  lSubmenu: THiddenPopup;
begin
  lFixture := TPopupFixture.Create;
  lSubmenu := THiddenPopup.Create(nil);
  try
    lSubmenu.Width := 100;
    lSubmenu.Height := 60;
    lSubmenu.ShowAt(lFixture.Popup, 160, 0);
    Mouse(lFixture.Popup, WM_LBUTTONDOWN, 5, 5);
    Mouse(lSubmenu, WM_LBUTTONDOWN, 5, 5);
    AContext.AssertTrue(PopupListFind(lFixture.Popup.Window.WinHandle) = lFixture.Popup);
    AContext.AssertTrue(PopupListFind(lSubmenu.Window.WinHandle) = lSubmenu);
    Mouse(lFixture.Button, WM_LBUTTONDOWN, 5, 5);
    AContext.AssertTrue(PopupListFirst = nil, 'An outside click must close the whole popup chain.');
  finally
    ClosePopups;
    lSubmenu.Free;
    lFixture.Free;
  end;
end;

procedure TestDontCloseWidget(AContext: TNXTestContext);
var
  lFixture: TPopupFixture;
begin
  lFixture := TPopupFixture.Create;
  try
    lFixture.Popup.DontCloseWidget := lFixture.Button;
    Mouse(lFixture.Button, WM_LBUTTONDOWN, 5, 5);
    Mouse(lFixture.Button, WM_LBUTTONUP, 5, 5);
    AContext.AssertTrue(PopupListFirst = lFixture.Popup);
    AContext.AssertEquals(1, lFixture.Clicks);
    AContext.AssertEquals(0, lFixture.Closes);
    Mouse(lFixture.Form, WM_LBUTTONDOWN, 5, 5);
    AContext.AssertTrue(PopupListFirst = nil, 'The exception must apply only to the clicked widget.');
  finally
    lFixture.Free;
  end;
end;

procedure TestModalRestriction(AContext: TNXTestContext);
var
  lFixture: TPopupFixture;
  lModal: THiddenForm;
begin
  lFixture := TPopupFixture.Create;
  lModal := THiddenForm.Create(nil);
  try
    lModal.Left := 400;
    lModal.Top := 100;
    lModal.Width := 200;
    lModal.Height := 100;
    lModal.AllocateForTest;
    lFixture.Popup.ShowAt(lFixture.Form, 180, 40);
    fpgApplication.PushModalForm(lModal);
    try
      Mouse(lFixture.Button, WM_LBUTTONDOWN, 5, 5);
      AContext.AssertTrue(PopupListFirst = lFixture.Popup, 'Blocked owner input must not dismiss popups.');
      AContext.AssertEquals(0, lFixture.Clicks);
      Mouse(lModal, WM_LBUTTONDOWN, 5, 5);
      AContext.AssertTrue(PopupListFirst = nil, 'Permitted modal input must dismiss outside popups.');
    finally
      fpgApplication.PopModalForm;
    end;
  finally
    lModal.Free;
    lFixture.Free;
  end;
end;

procedure TestMoveAndRelease(AContext: TNXTestContext);
var
  lFixture: TPopupFixture;
begin
  lFixture := TPopupFixture.Create;
  try
    Mouse(lFixture.Button, WM_MOUSEMOVE, 5, 5);
    Mouse(lFixture.Button, WM_LBUTTONUP, 5, 5);
    AContext.AssertTrue(PopupListFirst = lFixture.Popup, 'Movement and release alone must not dismiss popups.');
  finally
    lFixture.Free;
  end;
end;

procedure TestReceiverDestroyedOnClose(AContext: TNXTestContext);
var
  lFixture: TPopupFixture;
begin
  lFixture := TPopupFixture.Create;
  try
    lFixture.Popup.OnClose := @lFixture.DestroyReceiver;
    Mouse(lFixture.Button, WM_LBUTTONDOWN, 5, 5);
    AContext.AssertTrue(lFixture.Form = nil, 'The close callback must have executed.');
    AContext.AssertTrue(PopupListFirst = nil);
  finally
    lFixture.Free;
  end;
end;

procedure TestCapturedOutsideClick(AContext: TNXTestContext);
var
  lFixture: TPopupFixture;
  lHandle: HWND;
begin
  lFixture := TPopupFixture.Create;
  try
    lHandle := lFixture.Form.Window.WinHandle;
    Windows.SetCapture(lHandle);
    try
      AContext.AssertTrue(Windows.GetCapture = lHandle, 'The fixture must acquire native mouse capture.');
      // The hidden capture window is not the native window under this point.
      Mouse(lFixture.Form, WM_LBUTTONDOWN, 5, 5);
      AContext.AssertTrue(PopupListFirst = nil, 'A captured outside press must dismiss popups.');
      AContext.AssertTrue(Windows.GetCapture = lHandle, 'Dismissal must not release another widget''s capture.');
    finally
      Windows.ReleaseCapture;
    end;
  finally
    lFixture.Free;
  end;
end;

procedure TestComboToggle(AContext: TNXTestContext);
var
  lFixture: TPopupFixture;
  lCombo: TfpgComboBox;
begin
  lFixture := TPopupFixture.Create;
  try
    ClosePopups;
    lCombo := TfpgComboBox.Create(lFixture.Form);
    lCombo.Left := 20;
    lCombo.Top := 100;
    lCombo.Width := 120;
    lCombo.Height := 25;
    lCombo.Items.Add('First');
    lCombo.Items.Add('Second');
    Mouse(lCombo, WM_LBUTTONDOWN, 110, 10);
    Mouse(lCombo, WM_LBUTTONUP, 110, 10);
    AContext.AssertTrue(PopupListFirst <> nil, 'The first click must open the combo dropdown.');
    AContext.AssertTrue(PopupDontCloseWidget(lCombo));
    Mouse(lCombo, WM_LBUTTONDOWN, 110, 10);
    Mouse(lCombo, WM_LBUTTONUP, 110, 10);
    AContext.AssertTrue(PopupListFirst = nil, 'The second click must close, not reopen, the dropdown.');
  finally
    lFixture.Free;
  end;
end;

procedure RegisterNXPopupTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('WindowsPopupDismissal');
  lSuite.AddTest('OutsideMouseButtonsAndClickDelivery', @TestOutsideButtons);
  lSuite.AddTest('InsidePopupChild', @TestInsideChild);
  lSuite.AddTest('NestedPopups', @TestNestedPopups);
  lSuite.AddTest('DontCloseWidget', @TestDontCloseWidget);
  lSuite.AddTest('ModalRestriction', @TestModalRestriction);
  lSuite.AddTest('MoveAndReleaseDoNotDismiss', @TestMoveAndRelease);
  lSuite.AddTest('ReceiverDestroyedOnClose', @TestReceiverDestroyedOnClose);
  lSuite.AddTest('CapturedOutsideClick', @TestCapturedOutsideClick);
  lSuite.AddTest('ComboToggle', @TestComboToggle);
end;

end.

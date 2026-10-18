// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit tclistviewselection;

{$mode objfpc}{$H+}

interface

uses obNXTestRegistry;

procedure RegisterListViewSelectionTests(ARegistry: TNXTestRegistry);

implementation

uses
  Classes, fpg_base, fpg_listview, obNXTestContext, obNXTestSuite;

type
  TSelectionListView = class(TfpgListView)
  public
    procedure PressKey(AKey: Word; AShift: TShiftState);
    procedure ReleaseModifiers;
  end;

  TSelectionObserver = class
  private
    FContext: TNXTestContext;
    FCount: Integer;
  public
    constructor Create(AContext: TNXTestContext);
    procedure Changed(AListView: TfpgListView; AItem: TfpgLVItem;
      AItemIndex: Integer; ASelected: Boolean);
    property Count: Integer read FCount;
  end;

procedure TSelectionListView.PressKey(AKey: Word; AShift: TShiftState);
var
  lConsumed: Boolean;
begin
  lConsumed := False;
  HandleKeyPress(AKey, AShift, lConsumed);
end;

procedure TSelectionListView.ReleaseModifiers;
var
  lKey: Word;
  lShift: TShiftState;
  lConsumed: Boolean;
begin
  lKey := 0;
  lShift := [];
  lConsumed := False;
  HandleKeyRelease(lKey, lShift, lConsumed);
end;

constructor TSelectionObserver.Create(AContext: TNXTestContext);
begin
  inherited Create;
  FContext := AContext;
end;

procedure TSelectionObserver.Changed(AListView: TfpgListView; AItem: TfpgLVItem;
  AItemIndex: Integer; ASelected: Boolean);
begin
  FContext.AssertTrue(AListView.Items.Item[AItemIndex] = AItem);
  FContext.AssertTrue(AItem.Selected[AListView] = ASelected,
    'Selection state must be updated before its notification');
  Inc(FCount);
end;

function CreateListView: TSelectionListView;
var
  lIndex: Integer;
begin
  Result := TSelectionListView.Create(nil);
  Result.SetPosition(0, 0, 320, 200);
  Result.MultiSelect := True;
  for lIndex := 0 to 3 do Result.AddItem.Caption := 'Item';
end;

procedure TestMembershipNotifications(AContext: TNXTestContext);
var
  lList: TSelectionListView;
  lObserver: TSelectionObserver;
begin
  lList := CreateListView;
  lObserver := TSelectionObserver.Create(AContext);
  try
    lList.OnSelectionChanged := @lObserver.Changed;
    lList.Items.Item[0].Selected[lList] := False;
    AContext.AssertEquals(0, lObserver.Count);
    lList.Items.Item[0].Selected[lList] := True;
    lList.Items.Item[0].Selected[lList] := True;
    AContext.AssertEquals(1, lObserver.Count);
    AContext.AssertTrue(lList.Items.Item[0].Selected[lList]);
    lList.Items.Item[0].Selected[lList] := False;
    lList.Items.Item[0].Selected[lList] := False;
    AContext.AssertEquals(2, lObserver.Count);
    AContext.AssertFalse(lList.Items.Item[0].Selected[lList]);
  finally
    lList.Free;
    lObserver.Free;
  end;
end;

procedure TestShiftSelectionSnapshot(AContext: TNXTestContext);
var
  lList: TSelectionListView;
begin
  lList := CreateListView;
  try
    lList.Items.Item[0].Selected[lList] := True;
    lList.Items.Item[1].Selected[lList] := True;
    lList.ItemIndex := 1;
    lList.PressKey(keyDown, [ssShift]);
    lList.PressKey(keyDown, [ssShift]);
    AContext.AssertTrue(lList.Items.Item[3].Selected[lList]);
    lList.PressKey(keyUp, [ssShift]);
    AContext.AssertTrue(lList.Items.Item[0].Selected[lList]);
    AContext.AssertTrue(lList.Items.Item[1].Selected[lList]);
    AContext.AssertTrue(lList.Items.Item[2].Selected[lList]);
    AContext.AssertFalse(lList.Items.Item[3].Selected[lList],
      'Shrinking a Shift range must restore the original selection first');
    lList.ReleaseModifiers;
  finally
    lList.Free;
  end;
end;

procedure TestClearPreservesItems(AContext: TNXTestContext);
var
  lList: TSelectionListView;
  lObserver: TSelectionObserver;
  lIndex: Integer;
begin
  lList := CreateListView;
  lObserver := TSelectionObserver.Create(AContext);
  try
    lList.Items.Item[0].Selected[lList] := True;
    lList.Items.Item[1].Selected[lList] := True;
    lList.OnSelectionChanged := @lObserver.Changed;
    lList.SelectionFollowsFocus := False;
    lList.ItemIndex := 1;
    lList.PressKey(keyDown, []);
    AContext.AssertEquals(2, lObserver.Count);
    AContext.AssertEquals(4, lList.Items.Count);
    for lIndex := 0 to 3 do
    begin
      AContext.AssertFalse(lList.Items.Item[lIndex].Selected[lList]);
      AContext.AssertEquals('Item', lList.Items.Item[lIndex].Caption);
    end;
  finally
    lList.Free;
    lObserver.Free;
  end;
end;

procedure RegisterListViewSelectionTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('ListView.Selection');
  lSuite.AddTest('MembershipNotifications', @TestMembershipNotifications);
  lSuite.AddTest('ShiftSelectionSnapshot', @TestShiftSelectionSnapshot);
  lSuite.AddTest('ClearPreservesItems', @TestClearPreservesItems);
end;

end.

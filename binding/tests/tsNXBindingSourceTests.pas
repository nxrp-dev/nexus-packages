(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tsNXBindingSourceTests;

{$mode objfpc}{$H+}{$interfaces corba}

interface

uses obNXTestRegistry;

procedure RegisterBindingSourceTests(ARegistry: TNXTestRegistry);

implementation

uses SysUtils, tpNXBinding, obNXBindingSource, obNXBindingTestObjects,
  obNXTestContext;

type
  TFixture = class
  private
    FSource: TTestSource;
    FCoordinator: TNXBindingSource;
    FName, FNumber: TTestTarget;
    FConverter: TTestConverter;
    FValidator: TTestValidator;
    FNameBinding, FNumberBinding: QWord;
  public
    constructor Create(AFacade: Boolean = True; AEdit: Boolean = False);
    destructor Destroy; override;
    procedure Bind(ATrigger: TNXBindingTrigger = btExplicit);
    function State(ABinding: QWord): TNXBindingState;
  end;

  TCallbackKind = (ckUnsubscribe, ckBusy, ckRemove, ckRaise, ckCloseSource);
  TCallbackAction = class
  private
    FKind: TCallbackKind;
    FCoordinator: TNXBindingSource;
    FSource: TTestSource;
    FSubject: TTestObservable;
    FNewObserver: TTestObserver;
    FToken, FOtherToken, FBinding: QWord;
    FObservedResult: TNXBindingResult;
  public
    procedure Invoke(ASubject: TObject; const AEvent: TNXBindingEvent);
  end;

procedure TCallbackAction.Invoke(ASubject: TObject; const AEvent: TNXBindingEvent);
begin
  case FKind of
    ckUnsubscribe:
      begin
        FSubject.Unsubscribe(FToken);
        FSubject.Unsubscribe(FOtherToken);
        FSubject.Subscribe(FNewObserver);
      end;
    ckBusy: FObservedResult := FCoordinator.Next;
    ckRemove: FObservedResult := FCoordinator.Remove(FBinding);
    ckRaise: raise Exception.Create('Observer test exception');
    ckCloseSource: FSource.Close;
  end;
end;

constructor TFixture.Create(AFacade: Boolean; AEdit: Boolean);
begin
  inherited Create;
  if AEdit then FSource := TTestEditableSource.Create(AFacade)
  else if AFacade then FSource := TTestSource.Create(True)
  else FSource := TTestListSource.Create;
  FCoordinator := TNXBindingSource.Create;
  FName := TTestTarget.Create(TNXBindingValue.FromString('pre-existing'));
  FNumber := TTestTarget.Create(TNXBindingValue.FromString('unbound'));
  FConverter := TTestConverter.Create;
  FValidator := TTestValidator.Create;
  FCoordinator.Attach(FSource);
end;

destructor TFixture.Destroy;
begin
  FCoordinator.Free;
  FSource.Free;
  FName.Free;
  FNumber.Free;
  FConverter.Free;
  FValidator.Free;
  inherited Destroy;
end;

procedure TFixture.Bind(ATrigger: TNXBindingTrigger);
begin
  FCoordinator.Bind('Name', FName, bmTwoWay, ATrigger, FNameBinding);
  FCoordinator.Bind('Number', FNumber, bmTwoWay, ATrigger, FNumberBinding,
    FConverter, FValidator);
end;

function TFixture.State(ABinding: QWord): TNXBindingState;
begin
  FCoordinator.GetState(ABinding, Result);
end;

procedure AssertCode(AContext: TNXTestContext; AExpected: TNXBindingCode;
  const AResult: TNXBindingResult);
begin
  AContext.AssertEquals(Ord(AExpected), Ord(AResult.Code), AResult.MessageText);
end;

procedure InitialSourceFirst(AContext: TNXTestContext);
var lFixture: TFixture;
begin
  lFixture := TFixture.Create;
  try
    lFixture.Bind(btOnChange);
    AContext.AssertEquals('Alice', lFixture.FName.Value.StringValue);
    AContext.AssertEquals('10', lFixture.FNumber.Value.StringValue);
    AContext.AssertEquals(0, lFixture.FSource.CurrentData.NameValue.Writes);
    AContext.AssertEquals(0, lFixture.FSource.CurrentData.NumberValue.Writes);
    AContext.AssertFalse(lFixture.FCoordinator.GetDirty);
  finally lFixture.Free; end;
end;

procedure InitialFailure(AContext: TNXTestContext);
var lFixture: TFixture;
begin
  lFixture := TFixture.Create;
  try
    lFixture.FName.Reject := True;
    AssertCode(AContext, bcRejected, lFixture.FCoordinator.Bind('Name',
      lFixture.FName, bmTwoWay, btOnChange, lFixture.FNameBinding));
    AContext.AssertTrue(lFixture.FNameBinding <> 0);
    AContext.AssertEquals('pre-existing', lFixture.FName.Value.StringValue);
    AContext.AssertFalse(lFixture.State(lFixture.FNameBinding).Pending);
    AContext.AssertEquals(0, lFixture.FSource.CurrentData.NameValue.Writes);
    lFixture.FName.Reject := False;
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.Refresh);
    AContext.AssertEquals('Alice', lFixture.FName.Value.StringValue);
  finally lFixture.Free; end;
end;

procedure OneWay(AContext: TNXTestContext);
var lFixture: TFixture;
begin
  lFixture := TFixture.Create(False);
  try
    lFixture.FCoordinator.Bind('Name', lFixture.FName, bmOneWay,
      btOnChange, lFixture.FNameBinding);
    lFixture.FName.SetValue(TNXBindingValue.FromString('ignored'));
    AContext.AssertEquals('Alice', lFixture.FSource.CurrentData.NameValue.Value.StringValue);
    lFixture.FSource.CurrentData.NameValue.SetValue(TNXBindingValue.FromString('changed'));
    AContext.AssertEquals('changed', lFixture.FName.Value.StringValue);
  finally lFixture.Free; end;
end;

procedure ExplicitEdits(AContext: TNXTestContext);
var lFixture: TFixture;
begin
  lFixture := TFixture.Create;
  try
    lFixture.Bind;
    lFixture.FName.SetValue(TNXBindingValue.FromString('Carol'));
    AContext.AssertEquals('Alice', lFixture.FSource.CurrentData.NameValue.Value.StringValue);
    AContext.AssertTrue(lFixture.State(lFixture.FNameBinding).Pending);
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.Submit(lFixture.FNameBinding));
    AContext.AssertEquals('Carol', lFixture.FSource.CurrentData.NameValue.Value.StringValue);
    AContext.AssertFalse(lFixture.FCoordinator.GetDirty);
  finally lFixture.Free; end;
end;

procedure InvalidInput(AContext: TNXTestContext);
var lFixture: TFixture;
begin
  lFixture := TFixture.Create;
  try
    lFixture.Bind(btOnChange);
    lFixture.FNumber.SetValue(TNXBindingValue.FromString('-'));
    AssertCode(AContext, bcIncomplete, lFixture.State(lFixture.FNumberBinding).LastResult);
    AContext.AssertEquals('-', lFixture.FNumber.Value.StringValue);
    AContext.AssertTrue(lFixture.FSource.CurrentData.NumberValue.Value.IntegerValue = 10);
    lFixture.FNumber.SetValue(TNXBindingValue.FromString('-2'));
    AssertCode(AContext, bcValidationFailed, lFixture.State(lFixture.FNumberBinding).LastResult);
    lFixture.FNumber.SetValue(TNXBindingValue.FromString('bad'));
    AssertCode(AContext, bcConversionFailed, lFixture.State(lFixture.FNumberBinding).LastResult);
    lFixture.FNumber.SetValue(TNXBindingValue.FromString('24'));
    AContext.AssertTrue(lFixture.FSource.CurrentData.NumberValue.Value.IntegerValue = 24);
    AContext.AssertFalse(lFixture.FCoordinator.GetDirty);
  finally lFixture.Free; end;
end;

procedure RejectedAndReadOnly(AContext: TNXTestContext);
var lFixture: TFixture;
begin
  lFixture := TFixture.Create;
  try
    lFixture.Bind;
    lFixture.FName.SetValue(TNXBindingValue.FromString('proposal'));
    lFixture.FSource.CurrentData.NameValue.Reject := True;
    AssertCode(AContext, bcRejected, lFixture.FCoordinator.Submit(lFixture.FNameBinding));
    lFixture.FSource.CurrentData.NameValue.Reject := False;
    lFixture.FSource.CurrentData.NameValue.SetWritable(False);
    AssertCode(AContext, bcReadOnly, lFixture.FCoordinator.Submit(lFixture.FNameBinding));
    AContext.AssertEquals('proposal', lFixture.FName.Value.StringValue);
    lFixture.FSource.CurrentData.NameValue.SetWritable(True);
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.CancelPending(lFixture.FNameBinding));
    AContext.AssertEquals('Alice', lFixture.FName.Value.StringValue);
    AContext.AssertFalse(lFixture.FCoordinator.GetDirty);
  finally lFixture.Free; end;
end;

procedure NormalizedSiblings(AContext: TNXTestContext);
var lFixture: TFixture; lSibling: TTestTarget; lHandle: QWord;
begin
  lFixture := TFixture.Create;
  lSibling := TTestTarget.Create(TNXBindingValue.FromString(''));
  try
    lFixture.Bind(btOnChange);
    lFixture.FCoordinator.Bind('Name', lSibling, bmTwoWay, btExplicit, lHandle);
    lFixture.FSource.CurrentData.NameValue.Normalize := True;
    lFixture.FName.SetValue(TNXBindingValue.FromString('  Carol  '));
    AContext.AssertEquals('Carol', lFixture.FName.Value.StringValue);
    AContext.AssertEquals('Carol', lSibling.Value.StringValue);
    AContext.AssertEquals(1, lFixture.FSource.CurrentData.NameValue.Writes);
    AContext.AssertFalse(lFixture.FCoordinator.GetDirty);
  finally
    lSibling.Free;
    lFixture.Free;
  end;
end;

procedure CheckNavigation(AContext: TNXTestContext; AFacade: Boolean);
var lFixture: TFixture; lObserver: TTestObserver;
begin
  lFixture := TFixture.Create(AFacade);
  lObserver := TTestObserver.Create;
  try
    lFixture.FSource.Next;
    lFixture.FCoordinator.Attach(lFixture.FSource);
    lFixture.Bind;
    AContext.AssertEquals('Bob', lFixture.FName.Value.StringValue);
    AContext.AssertEquals(1, lFixture.FSource.NavigationCalls);
    lFixture.FCoordinator.Subscribe(lObserver);
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.First);
    AContext.AssertEquals('Alice', lFixture.FName.Value.StringValue);
    AContext.AssertEquals('10', lFixture.FNumber.Value.StringValue);
    AContext.AssertEquals(1, lObserver.Count(beCurrentChanged));
    AContext.AssertEquals(1, lObserver.Count(beDataChanged));
    AContext.AssertEquals(Ord(beCurrentChanged), Ord(lObserver.EventAt(0)));
    AContext.AssertEquals(Ord(beBindingChanged), Ord(lObserver.EventAt(1)));
    AContext.AssertEquals(Ord(beBindingChanged), Ord(lObserver.EventAt(2)));
    AContext.AssertEquals(Ord(beDataChanged), Ord(lObserver.EventAt(3)));
    AssertCode(AContext, bcNoMovement, lFixture.FCoordinator.Prior);
    AContext.AssertEquals(1, lObserver.Count(beCurrentChanged));
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.Last);
    AContext.AssertEquals('20', lFixture.FNumber.Value.StringValue);
    AssertCode(AContext, bcNoMovement, lFixture.FCoordinator.Next);
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.Prior);
  finally
    lFixture.Free;
    lObserver.Free;
  end;
end;

procedure FacadeNavigation(AContext: TNXTestContext);
begin CheckNavigation(AContext, True); end;

procedure ListNavigation(AContext: TNXTestContext);
begin CheckNavigation(AContext, False); end;

procedure PendingNavigation(AContext: TNXTestContext);
var lFixture: TFixture;
begin
  lFixture := TFixture.Create;
  try
    lFixture.Bind;
    lFixture.FNumber.SetValue(TNXBindingValue.FromString('-'));
    AssertCode(AContext, bcPendingEdits, lFixture.FCoordinator.Next);
    AssertCode(AContext, bcPendingEdits, lFixture.FCoordinator.First);
    AssertCode(AContext, bcPendingEdits, lFixture.FCoordinator.Attach(nil));
    AContext.AssertEquals(0, lFixture.FSource.NavigationCalls);
    lFixture.FCoordinator.CancelPending(lFixture.FNumberBinding);
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.Next);
    AContext.AssertEquals('Bob', lFixture.FName.Value.StringValue);
  finally lFixture.Free; end;
end;

procedure OrphanedFacade(AContext: TNXTestContext);
var lFixture: TFixture;
begin
  lFixture := TFixture.Create;
  try
    lFixture.Bind;
    lFixture.FNumber.SetValue(TNXBindingValue.FromString('999'));
    lFixture.FSource.Next;
    AContext.AssertTrue(lFixture.State(lFixture.FNumberBinding).Orphaned);
    AContext.AssertEquals('999', lFixture.FNumber.Value.StringValue);
    AssertCode(AContext, bcUnavailable, lFixture.FCoordinator.Submit(lFixture.FNumberBinding));
    AssertCode(AContext, bcUnavailable, lFixture.FCoordinator.Rebase(lFixture.FNumberBinding));
    AContext.AssertTrue(lFixture.FSource.CurrentData.NumberValue.Value.IntegerValue = 20);
    lFixture.FCoordinator.CancelPending(lFixture.FNumberBinding);
    AContext.AssertEquals('20', lFixture.FNumber.Value.StringValue);
  finally lFixture.Free; end;
end;

procedure OrphanedRemoval(AContext: TNXTestContext);
var lFixture: TFixture;
begin
  lFixture := TFixture.Create(False);
  try
    lFixture.Bind;
    lFixture.FName.SetValue(TNXBindingValue.FromString('pending'));
    lFixture.FSource.RemoveCurrent;
    AContext.AssertTrue(lFixture.State(lFixture.FNameBinding).Orphaned);
    AContext.AssertEquals('pending', lFixture.FName.Value.StringValue);
    lFixture.FCoordinator.CancelPending(lFixture.FNameBinding);
    AContext.AssertEquals('Bob', lFixture.FName.Value.StringValue);
    lFixture.FSource.RemoveCurrent;
    AContext.AssertTrue(lFixture.FCoordinator.Current = nil);
    AContext.AssertFalse(lFixture.State(lFixture.FNameBinding).Available);
  finally lFixture.Free; end;
end;

procedure SourceChangedRebase(AContext: TNXTestContext);
var lFixture: TFixture;
begin
  lFixture := TFixture.Create(False);
  try
    lFixture.Bind;
    lFixture.FName.SetValue(TNXBindingValue.FromString('pending'));
    lFixture.FSource.CurrentData.NameValue.SetValue(TNXBindingValue.FromString('external'));
    AContext.AssertTrue(lFixture.State(lFixture.FNameBinding).SourceChanged);
    AssertCode(AContext, bcSourceChanged, lFixture.FCoordinator.Submit(lFixture.FNameBinding));
    lFixture.FCoordinator.Refresh;
    AContext.AssertEquals('pending', lFixture.FName.Value.StringValue);
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.Rebase(lFixture.FNameBinding));
    AContext.AssertEquals('external', lFixture.FSource.CurrentData.NameValue.Value.StringValue);
    lFixture.FSource.CurrentData.NameValue.SetValue(TNXBindingValue.FromString('external2'));
    AssertCode(AContext, bcSourceChanged, lFixture.FCoordinator.Submit(lFixture.FNameBinding));
    lFixture.FCoordinator.Rebase(lFixture.FNameBinding);
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.Submit(lFixture.FNameBinding));
    AContext.AssertEquals('pending', lFixture.FSource.CurrentData.NameValue.Value.StringValue);
  finally lFixture.Free; end;
end;

procedure SessionCommitCancel(AContext: TNXTestContext);
var lFixture: TFixture;
begin
  lFixture := TFixture.Create(True, True);
  try
    lFixture.Bind;
    lFixture.FName.SetValue(TNXBindingValue.FromString('edited'));
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.Submit(lFixture.FNameBinding));
    AContext.AssertTrue(lFixture.FCoordinator.GetDirty);
    AssertCode(AContext, bcPendingEdits, lFixture.FCoordinator.Next);
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.CancelEdit);
    AContext.AssertEquals('Alice', lFixture.FName.Value.StringValue);
    lFixture.FName.SetValue(TNXBindingValue.FromString('committed'));
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.CommitEdit);
    AContext.AssertFalse(lFixture.FCoordinator.GetDirty);
    AContext.AssertEquals('committed', lFixture.FSource.CurrentData.NameValue.Value.StringValue);
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.Next);
  finally lFixture.Free; end;
end;

procedure UnsupportedSession(AContext: TNXTestContext);
var lFixture: TFixture;
begin
  lFixture := TFixture.Create;
  try
    lFixture.Bind;
    lFixture.FName.SetValue(TNXBindingValue.FromString('edited'));
    AssertCode(AContext, bcUnsupported, lFixture.FCoordinator.CommitEdit);
    AssertCode(AContext, bcUnsupported, lFixture.FCoordinator.CancelEdit);
    AContext.AssertEquals('Alice', lFixture.FSource.CurrentData.NameValue.Value.StringValue);
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.SubmitAll);
  finally lFixture.Free; end;
end;

procedure PartialSubmission(AContext: TNXTestContext);
var lFixture: TFixture;
begin
  lFixture := TFixture.Create;
  try
    lFixture.Bind;
    lFixture.FName.SetValue(TNXBindingValue.FromString('accepted'));
    lFixture.FNumber.SetValue(TNXBindingValue.FromString('-'));
    AssertCode(AContext, bcIncomplete, lFixture.FCoordinator.SubmitAll);
    AContext.AssertEquals('accepted', lFixture.FSource.CurrentData.NameValue.Value.StringValue);
    AContext.AssertEquals('-', lFixture.FNumber.Value.StringValue);
    AContext.AssertFalse(lFixture.State(lFixture.FNameBinding).Pending);
    AContext.AssertTrue(lFixture.State(lFixture.FNumberBinding).Pending);
  finally lFixture.Free; end;
end;

procedure ConflictingProposals(AContext: TNXTestContext);
var lFixture: TFixture; lSibling: TTestTarget; lHandle: QWord;
begin
  lFixture := TFixture.Create;
  lSibling := TTestTarget.Create(TNXBindingValue.FromString(''));
  try
    lFixture.Bind;
    lFixture.FCoordinator.Bind('Name', lSibling, bmTwoWay, btExplicit, lHandle);
    lFixture.FName.SetValue(TNXBindingValue.FromString('one'));
    lSibling.SetValue(TNXBindingValue.FromString('two'));
    AssertCode(AContext, bcAmbiguousProposal, lFixture.FCoordinator.SubmitAll);
    AContext.AssertEquals(0, lFixture.FSource.CurrentData.NameValue.Writes);
    lSibling.SetValue(TNXBindingValue.FromString('one'));
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.SubmitAll);
    AContext.AssertEquals(1, lFixture.FSource.CurrentData.NameValue.Writes);
    AContext.AssertFalse(lFixture.FCoordinator.GetDirty);
  finally lSibling.Free; lFixture.Free; end;
end;

procedure Teardown(AContext: TNXTestContext);
var lFixture: TFixture;
begin
  lFixture := TFixture.Create;
  try
    lFixture.Bind;
    lFixture.FName.SetValue(TNXBindingValue.FromString('saved input'));
    FreeAndNil(lFixture.FSource);
    AContext.AssertTrue(lFixture.FCoordinator.Current = nil);
    AContext.AssertEquals('saved input', lFixture.FName.Value.StringValue);
    AssertCode(AContext, bcUnavailable, lFixture.FCoordinator.Submit(lFixture.FNameBinding));
    FreeAndNil(lFixture.FName);
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.Remove(lFixture.FNameBinding));
    AssertCode(AContext, bcInvalidHandle, lFixture.FCoordinator.Remove(lFixture.FNameBinding));
  finally lFixture.Free; end;
end;

procedure MissingAndRecovery(AContext: TNXTestContext);
var lFixture: TFixture;
begin
  lFixture := TFixture.Create(False);
  try
    lFixture.FSource.CurrentData.Hidden := True;
    lFixture.Bind;
    AContext.AssertFalse(lFixture.State(lFixture.FNameBinding).Available);
    lFixture.FSource.CurrentData.Hidden := False;
    lFixture.FSource.DataChanged;
    AContext.AssertEquals('Alice', lFixture.FName.Value.StringValue);
    AContext.AssertTrue(lFixture.State(lFixture.FNameBinding).Available);
  finally lFixture.Free; end;
end;

procedure ExceptionRecovery(AContext: TNXTestContext);
var lFixture: TFixture; lCaught: Boolean;
begin
  lFixture := TFixture.Create;
  try
    lFixture.Bind;
    lFixture.FNumber.SetValue(TNXBindingValue.FromString('42'));
    lFixture.FConverter.RaiseError := True;
    lCaught := False;
    try
      lFixture.FCoordinator.Submit(lFixture.FNumberBinding);
    except on lError: Exception do lCaught := True; end;
    AContext.AssertTrue(lCaught);
    lFixture.FConverter.RaiseError := False;
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.Submit(lFixture.FNumberBinding));
    AContext.AssertTrue(lFixture.FSource.CurrentData.NumberValue.Value.IntegerValue = 42);
  finally lFixture.Free; end;
end;

procedure SubscriptionRemoval(AContext: TNXTestContext);
var
  lSubject: TTestObservable;
  lFirst, lSecond, lNew: TTestObserver;
  lAction: TCallbackAction;
begin
  lSubject := TTestObservable.Create;
  lFirst := TTestObserver.Create;
  lSecond := TTestObserver.Create;
  lNew := TTestObserver.Create;
  lAction := TCallbackAction.Create;
  try
    lAction.FKind := ckUnsubscribe;
    lAction.FSubject := lSubject;
    lAction.FNewObserver := lNew;
    lAction.FToken := lSubject.Subscribe(lFirst);
    lAction.FOtherToken := lSubject.Subscribe(lSecond);
    lFirst.Action := @lAction.Invoke;
    lSubject.Emit(beValueChanged);
    AContext.AssertEquals(1, lFirst.Count(beValueChanged));
    AContext.AssertEquals(0, lSecond.Count(beValueChanged));
    AContext.AssertEquals(0, lNew.Count(beValueChanged));
    lSubject.Unsubscribe(lAction.FOtherToken);
    lSubject.Emit(beValueChanged);
    AContext.AssertEquals(1, lNew.Count(beValueChanged));
    lSubject.Close;
    AContext.AssertTrue(lSubject.Subscribe(lSecond) = 0);
  finally
    lSubject.Free;
    lAction.Free;
    lNew.Free;
    lSecond.Free;
    lFirst.Free;
  end;
end;

procedure ClosingException(AContext: TNXTestContext);
var
  lFixture: TFixture;
  lObserver: TTestObserver;
  lAction: TCallbackAction;
  lCaught: Boolean;
begin
  lFixture := TFixture.Create;
  lObserver := TTestObserver.Create;
  lAction := TCallbackAction.Create;
  try
    { Subscribe the failing observer BEFORE binding's lifetime observer. }
    lAction.FKind := ckRaise;
    lObserver.Action := @lAction.Invoke;
    lFixture.FName.Subscribe(lObserver);
    lObserver.Action := nil;
    lFixture.Bind;
    lObserver.Action := @lAction.Invoke;
    lCaught := False;
    try
      lFixture.FName.Close;
    except on lError: Exception do lCaught := True; end;
    AContext.AssertTrue(lCaught);
    AContext.AssertFalse(lFixture.State(lFixture.FNameBinding).Available);
    FreeAndNil(lFixture.FName);
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.Remove(lFixture.FNameBinding));
  finally
    lFixture.Free;
    lAction.Free;
    lObserver.Free;
  end;
end;

procedure ReentrantMutation(AContext: TNXTestContext);
var
  lState: TNXBindingState;
  lFixture: TFixture;
  lObserver: TTestObserver;
  lAction: TCallbackAction;
begin
  lFixture := TFixture.Create;
  lObserver := TTestObserver.Create;
  lAction := TCallbackAction.Create;
  try
    lFixture.Bind;
    lAction.FKind := ckBusy;
    lAction.FCoordinator := lFixture.FCoordinator;
    lObserver.Action := @lAction.Invoke;
    lFixture.FCoordinator.Subscribe(lObserver);
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.Next);
    AssertCode(AContext, bcBusy, lAction.FObservedResult);
    AContext.AssertEquals(1, lFixture.FSource.NavigationCalls);
    lAction.FKind := ckRemove;
    lAction.FBinding := lFixture.FNumberBinding;
    lFixture.FCoordinator.First;
    AssertCode(AContext, bcInvalidHandle,
      lFixture.FCoordinator.GetState(lFixture.FNumberBinding, lState));
  finally
    lObserver.Action := nil;
    lFixture.Free;
    lAction.Free;
    lObserver.Free;
  end;
end;

procedure ObserverExceptionRecovery(AContext: TNXTestContext);
var
  lFixture: TFixture;
  lObserver: TTestObserver;
  lAction: TCallbackAction;
  lCaught: Boolean;
begin
  lFixture := TFixture.Create;
  lObserver := TTestObserver.Create;
  lAction := TCallbackAction.Create;
  try
    lFixture.Bind;
    lAction.FKind := ckRaise;
    lObserver.Action := @lAction.Invoke;
    lFixture.FCoordinator.Subscribe(lObserver);
    lCaught := False;
    try lFixture.FCoordinator.Next;
    except on lError: Exception do lCaught := True; end;
    AContext.AssertTrue(lCaught);
    lObserver.Action := nil;
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.First);
    AContext.AssertEquals('Alice', lFixture.FName.Value.StringValue);
  finally
    lObserver.Action := nil;
    lFixture.Free;
    lAction.Free;
    lObserver.Free;
  end;
end;

procedure CloseDuringTransfer(AContext: TNXTestContext);
var
  lFixture: TFixture;
  lObserver: TTestObserver;
  lAction: TCallbackAction;
begin
  lFixture := TFixture.Create;
  lObserver := TTestObserver.Create;
  lAction := TCallbackAction.Create;
  try
    lAction.FKind := ckCloseSource;
    lAction.FSource := lFixture.FSource;
    lObserver.Action := @lAction.Invoke;
    lFixture.FName.Subscribe(lObserver);
    AssertCode(AContext, bcUnavailable, lFixture.FCoordinator.Bind('Name',
      lFixture.FName, bmTwoWay, btOnChange, lFixture.FNameBinding));
    AContext.AssertTrue(lFixture.FCoordinator.Current = nil);
    AContext.AssertEquals(0, lFixture.FSource.CurrentData.NameValue.Writes);
    lObserver.Action := nil;
  finally
    lObserver.Action := nil;
    lFixture.Free;
    lObserver.Free;
    lAction.Free;
  end;
end;

procedure FailedSessions(AContext: TNXTestContext);
var
  lFixture: TFixture;
  lSource: TTestEditableSource;
begin
  lFixture := TFixture.Create;
  lSource := TTestEditableSource.Create;
  try
    lFixture.FCoordinator.Attach(lSource);
    lFixture.Bind;
    lFixture.FName.SetValue(TNXBindingValue.FromString('pending'));
    lSource.FailCommit := True;
    AssertCode(AContext, bcRejected, lFixture.FCoordinator.CommitEdit);
    AContext.AssertTrue(lSource.GetDirty);
    lSource.FailCancel := True;
    AssertCode(AContext, bcRejected, lFixture.FCoordinator.CancelEdit);
    AContext.AssertEquals('pending', lFixture.FName.Value.StringValue);
    lSource.FailCancel := False;
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.CancelEdit);
    AContext.AssertEquals('Alice', lFixture.FName.Value.StringValue);
  finally
    lFixture.Free;
    lSource.Free;
  end;
end;

procedure PendingSibling(AContext: TNXTestContext);
var lFixture: TFixture; lSibling: TTestTarget; lHandle: QWord;
begin
  lFixture := TFixture.Create;
  lSibling := TTestTarget.Create(TNXBindingValue.FromString(''));
  try
    lFixture.Bind;
    lFixture.FCoordinator.Bind('Name', lSibling, bmTwoWay, btExplicit, lHandle);
    lFixture.FName.SetValue(TNXBindingValue.FromString('pending'));
    lSibling.SetValue(TNXBindingValue.FromString('different'));
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.Submit(lHandle));
    AContext.AssertEquals('pending', lFixture.FName.Value.StringValue);
    AssertCode(AContext, bcSourceChanged, lFixture.FCoordinator.Submit(lFixture.FNameBinding));
    lFixture.FCoordinator.CancelPending(lFixture.FNameBinding);
    AContext.AssertEquals('different', lFixture.FName.Value.StringValue);
  finally lSibling.Free; lFixture.Free; end;
end;

procedure EmptyAndLateAttach(AContext: TNXTestContext);
var lFixture: TFixture; lEmpty: TTestSource;
begin
  lFixture := TFixture.Create;
  lEmpty := TTestSource.Create(True, True);
  try
    lFixture.FCoordinator.Attach(nil);
    lFixture.Bind;
    AContext.AssertFalse(lFixture.State(lFixture.FNameBinding).Available);
    AssertCode(AContext, bcUnavailable, lFixture.FCoordinator.Next);
    lFixture.FCoordinator.Attach(lEmpty);
    AssertCode(AContext, bcNoMovement, lFixture.FCoordinator.First);
    AContext.AssertTrue(lFixture.FCoordinator.Current = nil);
    lFixture.FCoordinator.Attach(lFixture.FSource);
    AContext.AssertEquals('Alice', lFixture.FName.Value.StringValue);
  finally lFixture.Free; lEmpty.Free; end;
end;

procedure NoOpAndReadability(AContext: TNXTestContext);
var lFixture: TFixture; lObserver: TTestObserver; lToken: QWord;
begin
  lFixture := TFixture.Create(False);
  lObserver := TTestObserver.Create;
  try
    lFixture.Bind;
    lToken := lFixture.FName.Subscribe(lObserver);
    lFixture.FSource.CurrentData.NameValue.SetValue(TNXBindingValue.FromString('Alice'));
    AContext.AssertEquals(0, lObserver.Count(beValueChanged));
    lFixture.FSource.CurrentData.NameValue.SetReadable(False);
    AContext.AssertFalse(lFixture.State(lFixture.FNameBinding).Available);
    lFixture.FSource.CurrentData.NameValue.SetReadable(True);
    AContext.AssertTrue(lFixture.State(lFixture.FNameBinding).Available);
    lFixture.FName.SetValue(TNXBindingValue.FromString('change'));
    lFixture.FName.SetValue(TNXBindingValue.FromString('Alice'));
    AContext.AssertFalse(lFixture.FCoordinator.GetDirty);
    lFixture.FName.Unsubscribe(lToken);
  finally lFixture.Free; lObserver.Free; end;
end;

procedure InvalidParticipants(AContext: TNXTestContext);
var lFixture: TFixture; lObject: TObject; lHandle: QWord;
begin
  lFixture := TFixture.Create;
  lObject := TObject.Create;
  try
    AssertCode(AContext, bcUnsupported, lFixture.FCoordinator.Attach(lObject));
    AContext.AssertTrue(lFixture.FCoordinator.Current <> nil);
    AssertCode(AContext, bcUnsupported, lFixture.FCoordinator.Bind('Name', lObject,
      bmOneWay, btExplicit, lHandle));
    AContext.AssertTrue(lHandle = 0);
    AssertCode(AContext, bcUnsupported, lFixture.FCoordinator.Bind('Name', nil,
      bmTwoWay, btExplicit, lHandle));
  finally lObject.Free; lFixture.Free; end;
end;

procedure DuplicateValidation(AContext: TNXTestContext);
var lFixture: TFixture; lSibling: TTestTarget; lHandle: QWord;
begin
  lFixture := TFixture.Create;
  lSibling := TTestTarget.Create(TNXBindingValue.FromString(''));
  try
    lFixture.FCoordinator.Bind('Number', lFixture.FNumber, bmTwoWay,
      btExplicit, lFixture.FNumberBinding, lFixture.FConverter);
    lFixture.FCoordinator.Bind('Number', lSibling, bmTwoWay, btExplicit,
      lHandle, lFixture.FConverter, lFixture.FValidator);
    lFixture.FNumber.SetValue(TNXBindingValue.FromString('-3'));
    lSibling.SetValue(TNXBindingValue.FromString('-3'));
    AssertCode(AContext, bcValidationFailed, lFixture.FCoordinator.SubmitAll);
    AContext.AssertEquals(0, lFixture.FSource.CurrentData.NumberValue.Writes);
    lFixture.FNumber.SetValue(TNXBindingValue.FromString('003'));
    lSibling.SetValue(TNXBindingValue.FromString('3'));
    AssertCode(AContext, bcSuccess, lFixture.FCoordinator.SubmitAll);
    AContext.AssertEquals(1, lFixture.FSource.CurrentData.NumberValue.Writes);
    AContext.AssertFalse(lFixture.FCoordinator.GetDirty);
  finally lSibling.Free; lFixture.Free; end;
end;

procedure DetachedOldEndpoints(AContext: TNXTestContext);
var lFixture: TFixture; lOld: TTestItem;
begin
  lFixture := TFixture.Create(False);
  try
    lFixture.Bind;
    lOld := lFixture.FSource.CurrentData;
    lFixture.FCoordinator.Next;
    lOld.NameValue.SetValue(TNXBindingValue.FromString('old record changed'));
    AContext.AssertEquals('Bob', lFixture.FName.Value.StringValue);
    lFixture.FCoordinator.Attach(nil);
    lFixture.FSource.CurrentData.NameValue.SetValue(TNXBindingValue.FromString('detached'));
    AContext.AssertEquals('Bob', lFixture.FName.Value.StringValue);
  finally lFixture.Free; end;
end;

procedure NavigationFailure(AContext: TNXTestContext);
var lFixture: TFixture;
begin
  lFixture := TFixture.Create;
  try
    lFixture.Bind;
    lFixture.FSource.FailNavigation := True;
    AssertCode(AContext, bcRejected, lFixture.FCoordinator.Next);
    AContext.AssertEquals('Alice', lFixture.FName.Value.StringValue);
    AContext.AssertEquals(1, lFixture.FSource.NavigationCalls);
  finally lFixture.Free; end;
end;

procedure UnreadableTarget(AContext: TNXTestContext);
var lFixture: TFixture;
begin
  lFixture := TFixture.Create;
  try
    lFixture.FName.SetReadable(False);
    AssertCode(AContext, bcUnavailable, lFixture.FCoordinator.Bind('Name',
      lFixture.FName, bmTwoWay, btOnChange, lFixture.FNameBinding));
    AContext.AssertFalse(lFixture.State(lFixture.FNameBinding).Pending);
    lFixture.FName.SetReadable(True);
    AContext.AssertEquals('Alice', lFixture.FName.Value.StringValue);
    AContext.AssertEquals(0, lFixture.FSource.CurrentData.NameValue.Writes);
  finally lFixture.Free; end;
end;

procedure RegisterBindingSourceTests(ARegistry: TNXTestRegistry);
begin
  with ARegistry.AddSuite('Binding.Source') do
  begin
    AddTest('InitialSourceFirst', @InitialSourceFirst);
    AddTest('InitialFailure', @InitialFailure);
    AddTest('OneWay', @OneWay);
    AddTest('ExplicitEdits', @ExplicitEdits);
    AddTest('InvalidInput', @InvalidInput);
    AddTest('RejectedAndReadOnly', @RejectedAndReadOnly);
    AddTest('NormalizedSiblings', @NormalizedSiblings);
    AddTest('FacadeNavigation', @FacadeNavigation);
    AddTest('ListNavigation', @ListNavigation);
    AddTest('PendingNavigation', @PendingNavigation);
    AddTest('OrphanedFacade', @OrphanedFacade);
    AddTest('OrphanedRemoval', @OrphanedRemoval);
    AddTest('SourceChangedRebase', @SourceChangedRebase);
    AddTest('SessionCommitCancel', @SessionCommitCancel);
    AddTest('UnsupportedSession', @UnsupportedSession);
    AddTest('PartialSubmission', @PartialSubmission);
    AddTest('ConflictingProposals', @ConflictingProposals);
    AddTest('Teardown', @Teardown);
    AddTest('MissingAndRecovery', @MissingAndRecovery);
    AddTest('ExceptionRecovery', @ExceptionRecovery);
    AddTest('SubscriptionRemoval', @SubscriptionRemoval);
    AddTest('ClosingException', @ClosingException);
    AddTest('ReentrantMutation', @ReentrantMutation);
    AddTest('ObserverExceptionRecovery', @ObserverExceptionRecovery);
    AddTest('CloseDuringTransfer', @CloseDuringTransfer);
    AddTest('FailedSessions', @FailedSessions);
    AddTest('PendingSibling', @PendingSibling);
    AddTest('EmptyAndLateAttach', @EmptyAndLateAttach);
    AddTest('NoOpAndReadability', @NoOpAndReadability);
    AddTest('InvalidParticipants', @InvalidParticipants);
    AddTest('DuplicateValidation', @DuplicateValidation);
    AddTest('DetachedOldEndpoints', @DetachedOldEndpoints);
    AddTest('NavigationFailure', @NavigationFailure);
    AddTest('UnreadableTarget', @UnreadableTarget);
  end;
end;

end.

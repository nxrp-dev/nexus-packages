(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXBindingSource;

{$mode objfpc}{$H+}{$interfaces corba}

interface

uses tpNXBinding, obNXBindingSubscriptions;

type
  TNXBindingSource = class;

  { Owned by the coordinator. Its lifetime spans any active callback. }
  TNXBindingLink = class(TObject, INXBindingObserver)
  private
    FOwner: TNXBindingSource;
    FHandle: QWord;
    FMember: UTF8String;
    FTarget: INXBindingValue;
    FTargetObject, FSourceObject: TObject;
    FTargetWriter: INXBindingWritableValue;
    FSource: INXBindingValue;
    FWriter: INXBindingWritableValue;
    FTargetToken, FSourceToken: QWord;
    FMode: TNXBindingMode;
    FTrigger: TNXBindingTrigger;
    FConverter: INXBindingConverter;
    FValidator: INXBindingValidator;
    FState: TNXBindingState;
    FBaseline, FAccepted: TNXBindingValue;
    FHasAccepted, FActive, FNotify: Boolean;
    FTargetWrite: Integer;
    procedure DetachSource;
    procedure Disconnect;
    procedure Resolve;
    function Live(AGeneration: QWord): Boolean;
    function Remember(const AResult: TNXBindingResult): TNXBindingResult;
    function Translate(const AValue: TNXBindingValue;
      const ADescriptor: TNXBindingDescriptor; ADirection: TNXBindingDirection;
      out AConverted: TNXBindingValue): TNXBindingResult;
    function Pull: TNXBindingResult;
    function Prepare(out AValue: TNXBindingValue): TNXBindingResult;
    function Push: TNXBindingResult;
    procedure Capture;
    procedure ClearPending;
  public
    constructor Create(AOwner: TNXBindingSource);
    destructor Destroy; override;
    procedure Changed(ASubject: TObject; const AEvent: TNXBindingEvent);
  end;

  TNXBindingSource = class(TObject, INXBindingObservable, INXBindingSource,
    INXBindingObserver)
  private
    type
      TNavigation = (nFirst, nPrior, nNext, nLast);
    var
    FSource: INXItemSource;
    FSourceObject: TObject;
    FSession: INXBindingEditSession;
    FSourceToken: QWord;
    FLinks: array of TNXBindingLink;
    FSubscriptions: TNXBindingSubscriptions;
    FNextHandle, FGeneration: QWord;
    FDepth: Integer;
    FCurrentNotification, FDataNotification: Boolean;
    FWriting: TNXBindingLink;
    FSessionOperation: Boolean;
    FSubmittingAll: Boolean;
    FRefreshPending: Boolean;
    procedure Leave;
    procedure Flush;
    procedure Collect;
    function Find(ABinding: QWord): TNXBindingLink;
    procedure DisconnectSource;
    procedure Rebind;
    function PullAll: TNXBindingResult;
    function SubmitPending: TNXBindingResult;
    function Navigate(ADirection: TNavigation): TNXBindingResult;
  public
    constructor Create;
    destructor Destroy; override;
    function Subscribe(AObserver: INXBindingObserver): QWord;
    procedure Unsubscribe(AToken: QWord);
    procedure Changed(ASubject: TObject; const AEvent: TNXBindingEvent);
    function Attach(ASource: TObject): TNXBindingResult;
    function GetCurrent: INXBindingItem;
    function First: TNXBindingResult;
    function Prior: TNXBindingResult;
    function Next: TNXBindingResult;
    function Last: TNXBindingResult;
    function Bind(const AMember: UTF8String; ATarget: TObject;
      AMode: TNXBindingMode; ATrigger: TNXBindingTrigger;
      out ABinding: QWord; AConverter: INXBindingConverter = nil;
      AValidator: INXBindingValidator = nil): TNXBindingResult;
    function Remove(ABinding: QWord): TNXBindingResult;
    function GetState(ABinding: QWord; out AState: TNXBindingState): TNXBindingResult;
    function Refresh: TNXBindingResult;
    function Submit(ABinding: QWord): TNXBindingResult;
    function SubmitAll: TNXBindingResult;
    function CancelPending(ABinding: QWord): TNXBindingResult;
    function Rebase(ABinding: QWord): TNXBindingResult;
    function CommitEdit: TNXBindingResult;
    function CancelEdit: TNXBindingResult;
    function GetDirty: Boolean;
    property Current: INXBindingItem read GetCurrent;
  end;

implementation

uses SysUtils;

constructor TNXBindingLink.Create(AOwner: TNXBindingSource);
begin
  inherited Create;
  FOwner := AOwner;
  FActive := True;
end;

destructor TNXBindingLink.Destroy;
begin
  Disconnect;
  inherited Destroy;
end;

procedure TNXBindingLink.DetachSource;
var
  lSource: INXBindingValue;
  lToken: QWord;
begin
  lSource := FSource;
  lToken := FSourceToken;
  FSource := nil;
  FSourceObject := nil;
  FWriter := nil;
  FSourceToken := 0;
  FState.Available := False;
  if (lSource <> nil) and (lToken <> 0) then lSource.Unsubscribe(lToken);
end;

procedure TNXBindingLink.Disconnect;
var
  lTarget: INXBindingValue;
  lToken: QWord;
begin
  DetachSource;
  lTarget := FTarget;
  lToken := FTargetToken;
  FTarget := nil;
  FTargetObject := nil;
  FTargetWriter := nil;
  FTargetToken := 0;
  FConverter := nil;
  FValidator := nil;
  if (lTarget <> nil) and (lToken <> 0) then lTarget.Unsubscribe(lToken);
end;

function TNXBindingLink.Live(AGeneration: QWord): Boolean;
begin
  Result := FActive and (FTarget <> nil) and (FSource <> nil) and
    (AGeneration = FOwner.FGeneration);
end;

function TNXBindingLink.Remember(const AResult: TNXBindingResult): TNXBindingResult;
begin
  Result := AResult;
  Result.Binding := FHandle;
  FState.LastResult := Result;
  FNotify := True;
  FOwner.FDataNotification := True;
end;

procedure TNXBindingLink.Resolve;
var
  lItem: INXBindingItem;
  lObject: TObject;
  lGeneration: QWord;
  lResult: TNXBindingResult;
begin
  DetachSource;
  lGeneration := FOwner.FGeneration;
  lItem := FOwner.GetCurrent;
  if not FActive or (lItem = nil) or (FTarget = nil) then
  begin
    Remember(TNXBindingResult.Make(bcUnavailable));
    Exit;
  end;
  lObject := nil;
  lResult := lItem.ResolveValue(FMember, lObject);
  if not FActive or (lGeneration <> FOwner.FGeneration) then Exit;
  if not lResult.Succeeded then
  begin
    Remember(lResult);
    Exit;
  end;
  if not Supports(lObject, INXBindingValue, FSource) then
  begin
    Remember(TNXBindingResult.Make(bcUnsupported, 'Member is not a value endpoint.'));
    Exit;
  end;
  Supports(lObject, INXBindingWritableValue, FWriter);
  FSourceObject := lObject;
  FSourceToken := FSource.Subscribe(Self);
  if FSourceToken = 0 then
  begin
    FSource := nil;
    FSourceObject := nil;
    FWriter := nil;
    Remember(TNXBindingResult.Make(bcUnavailable));
  end;
end;

function TNXBindingLink.Translate(const AValue: TNXBindingValue;
  const ADescriptor: TNXBindingDescriptor; ADirection: TNXBindingDirection;
  out AConverted: TNXBindingValue): TNXBindingResult;
begin
  AConverted := AValue;
  if FConverter <> nil then
  begin
    Result := FConverter.Convert(AValue, ADescriptor, ADirection, AConverted);
    if not Result.Succeeded then Exit;
  end;
  Result := ADescriptor.Check(AConverted);
end;

function TNXBindingLink.Pull: TNXBindingResult;
var
  lValue, lConverted: TNXBindingValue;
  lGeneration: QWord;
begin
  lGeneration := FOwner.FGeneration;
  FState.Available := False;
  if not Live(lGeneration) then
    Exit(Remember(TNXBindingResult.Make(bcUnavailable)));
  if not FSource.GetDescriptor.Readable then
    Exit(Remember(TNXBindingResult.Make(bcUnavailable)));
  Result := FSource.TryRead(lValue);
  if not Live(lGeneration) then
    Exit(Remember(TNXBindingResult.Make(bcUnavailable)));
  if not Result.Succeeded then Exit(Remember(Result));
  FState.SourceValue := lValue;
  FState.Available := True;
  if FState.Pending then
  begin
    if FState.Orphaned then
      Exit(Remember(TNXBindingResult.Make(bcUnavailable, 'Pending input is orphaned.')));
    if not FBaseline.SameValue(lValue) then FState.SourceChanged := True;
    if FState.SourceChanged then
      Exit(Remember(TNXBindingResult.Make(bcSourceChanged)));
    Exit(FState.LastResult);
  end;
  Result := Translate(lValue, FTarget.GetDescriptor, bdToTarget, lConverted);
  if not Live(lGeneration) then
    Exit(Remember(TNXBindingResult.Make(bcUnavailable)));
  if not Result.Succeeded then Exit(Remember(Result));
  if (FMode = bmTwoWay) and not FTarget.GetDescriptor.Readable then
    Exit(Remember(TNXBindingResult.Make(bcUnavailable, 'Two-way target is not readable.')));
  if not FTargetWriter.GetWritable then
    Exit(Remember(TNXBindingResult.Make(bcReadOnly, 'Target is read-only.')));
  Inc(FTargetWrite);
  try
    Result := FTargetWriter.TryWrite(lConverted);
    if not Live(lGeneration) then
      Exit(Remember(TNXBindingResult.Make(bcUnavailable)));
    if not Result.Succeeded then Exit(Remember(Result));
    { Accept the target's own formatting/normalization as its clean value. }
    if FTarget.GetDescriptor.Readable then
      Result := FTarget.TryRead(lConverted);
    if not Live(lGeneration) then
      Exit(Remember(TNXBindingResult.Make(bcUnavailable)));
    if not Result.Succeeded then Exit(Remember(Result));
    FAccepted := lConverted;
    FHasAccepted := True;
    FBaseline := lValue;
    Result := Remember(TNXBindingResult.Make(bcSuccess));
  finally
    Dec(FTargetWrite);
  end;
end;

procedure TNXBindingLink.ClearPending;
begin
  FState.Pending := False;
  FState.Orphaned := False;
  FState.SourceChanged := False;
  FState.PendingValue := Default(TNXBindingValue);
end;

procedure TNXBindingLink.Capture;
var
  lValue: TNXBindingValue;
  lResult: TNXBindingResult;
  lGeneration: QWord;
begin
  if (FTarget = nil) or (FMode <> bmTwoWay) or (FTargetWrite <> 0) then Exit;
  lGeneration := FOwner.FGeneration;
  lResult := FTarget.TryRead(lValue);
  if not FActive or (FTarget = nil) then Exit;
  if not lResult.Succeeded then
  begin
    Remember(lResult);
    Exit;
  end;
  if FHasAccepted and FAccepted.SameValue(lValue) and
    not FState.Orphaned and not FState.SourceChanged then
  begin
    ClearPending;
    Remember(TNXBindingResult.Make(bcSuccess));
    Exit;
  end;
  FState.PendingValue := lValue;
  FState.Pending := True;
  if not Live(lGeneration) then
    Remember(TNXBindingResult.Make(bcUnavailable))
  else if FTrigger = btOnChange then
    Push
  else
    Remember(TNXBindingResult.Make(bcSuccess));
end;

function TNXBindingLink.Prepare(out AValue: TNXBindingValue): TNXBindingResult;
var
  lGeneration: QWord;
begin
  AValue := FState.PendingValue;
  lGeneration := FOwner.FGeneration;
  if (FMode <> bmTwoWay) then Exit(TNXBindingResult.Make(bcReadOnly));
  if not Live(lGeneration) or FState.Orphaned then
    Exit(TNXBindingResult.Make(bcUnavailable));
  if FState.SourceChanged then Exit(TNXBindingResult.Make(bcSourceChanged));
  if (FWriter = nil) or not FWriter.GetWritable then
    Exit(TNXBindingResult.Make(bcReadOnly));
  Result := Translate(FState.PendingValue, FSource.GetDescriptor, bdToSource, AValue);
  if not Live(lGeneration) then Exit(TNXBindingResult.Make(bcUnavailable));
  if not Result.Succeeded then Exit;
  if FValidator <> nil then
    Result := FValidator.Validate(FOwner.GetCurrent, FMember, AValue);
  if not Live(lGeneration) then Result := TNXBindingResult.Make(bcUnavailable);
end;

function TNXBindingLink.Push: TNXBindingResult;
var
  lValue: TNXBindingValue;
  lGeneration: QWord;
  lIndex: Integer;
  lSibling: TNXBindingLink;
begin
  if not FState.Pending then Exit(Remember(TNXBindingResult.Make(bcSuccess)));
  lGeneration := FOwner.FGeneration;
  Result := Prepare(lValue);
  if not Result.Succeeded then Exit(Remember(Result));
  if FOwner.FSession <> nil then
  begin
    Result := FOwner.FSession.BeginEdit;
    if not Live(lGeneration) then
      Exit(Remember(TNXBindingResult.Make(bcUnavailable)));
    if not Result.Succeeded then Exit(Remember(Result));
  end;
  FOwner.FWriting := Self;
  try
    Result := FWriter.TryWrite(lValue);
    if not Live(lGeneration) then
      Exit(Remember(TNXBindingResult.Make(bcUnavailable)));
    if not Result.Succeeded then Exit(Remember(Result));
    { Equivalent proposals for the same member become clean together. }
    for lIndex := 0 to High(FOwner.FLinks) do
    begin
      lSibling := FOwner.FLinks[lIndex];
      if FOwner.FSubmittingAll and lSibling.FActive and
        (lSibling.FMember = FMember) and lSibling.FState.Pending and
        not lSibling.FState.Orphaned and not lSibling.FState.SourceChanged then
        if lSibling <> Self then lSibling.ClearPending;
    end;
    ClearPending;
  finally
    FOwner.FWriting := nil;
  end;
  FOwner.PullAll;
  Result := FState.LastResult;
end;

procedure TNXBindingLink.Changed(ASubject: TObject;
  const AEvent: TNXBindingEvent);
begin
  if not FActive then Exit;
  Inc(FOwner.FDepth);
  try
    if AEvent.Kind = beClosing then
    begin
      if ASubject = FTargetObject then
      begin
        FTarget := nil;
        FTargetObject := nil;
        FTargetWriter := nil;
        FTargetToken := 0;
        DetachSource;
      end;
      if ASubject = FSourceObject then
      begin
        FSource := nil;
        FSourceObject := nil;
        FWriter := nil;
        FSourceToken := 0;
      end;
      FState.Available := False;
      if FState.Pending then FState.Orphaned := True;
      Remember(TNXBindingResult.Make(bcUnavailable));
      Exit;
    end;
    if ASubject = FTargetObject then
    begin
      if FTargetWrite <> 0 then Exit;
      if AEvent.Kind = beValueChanged then Capture else Pull;
    end
    else if ASubject = FSourceObject then
    begin
      if (FOwner.FWriting <> nil) or FOwner.FSessionOperation then
      begin
        FOwner.FRefreshPending := True;
        Exit;
      end;
      Pull;
    end;
  finally
    FOwner.Leave;
  end;
end;

constructor TNXBindingSource.Create;
begin
  inherited Create;
  FSubscriptions := TNXBindingSubscriptions.Create;
end;

destructor TNXBindingSource.Destroy;
var
  lIndex: Integer;
begin
  Inc(FDepth);
  try
    DisconnectSource;
    for lIndex := 0 to High(FLinks) do FLinks[lIndex].Disconnect;
    FSubscriptions.Notify(Self, beClosing);
  finally
    for lIndex := 0 to High(FLinks) do FLinks[lIndex].Free;
    FSubscriptions.Free;
    inherited Destroy;
  end;
end;

function TNXBindingSource.Subscribe(AObserver: INXBindingObserver): QWord;
begin
  Result := FSubscriptions.Subscribe(AObserver);
end;

procedure TNXBindingSource.Unsubscribe(AToken: QWord);
begin
  FSubscriptions.Unsubscribe(AToken);
end;

procedure TNXBindingSource.Collect;
var
  lRead, lWrite: Integer;
begin
  if FDepth <> 0 then Exit;
  lWrite := 0;
  for lRead := 0 to High(FLinks) do
    if FLinks[lRead].FActive then
    begin
      FLinks[lWrite] := FLinks[lRead];
      Inc(lWrite);
    end
    else FLinks[lRead].Free;
  SetLength(FLinks, lWrite);
end;

procedure TNXBindingSource.Flush;
var
  lIndex: Integer;
  lCurrent, lData: Boolean;
begin
  lCurrent := FCurrentNotification;
  lData := FDataNotification;
  FCurrentNotification := False;
  FDataNotification := False;
  if lCurrent then FSubscriptions.Notify(Self, beCurrentChanged);
  for lIndex := 0 to High(FLinks) do
    if FLinks[lIndex].FActive and FLinks[lIndex].FNotify then
    begin
      FLinks[lIndex].FNotify := False;
      FSubscriptions.Notify(Self, beBindingChanged, FLinks[lIndex].FHandle);
    end;
  if lData then FSubscriptions.Notify(Self, beDataChanged);
end;

procedure TNXBindingSource.Leave;
begin
  try
    if FDepth = 1 then
    begin
      if FRefreshPending then PullAll;
      Flush;
    end;
  finally
    Dec(FDepth);
    Collect;
  end;
end;

function TNXBindingSource.Find(ABinding: QWord): TNXBindingLink;
var
  lIndex: Integer;
begin
  Result := nil;
  for lIndex := 0 to High(FLinks) do
    if FLinks[lIndex].FActive and (FLinks[lIndex].FHandle = ABinding) then
      Exit(FLinks[lIndex]);
end;

procedure TNXBindingSource.DisconnectSource;
var
  lSource: INXItemSource;
  lToken: QWord;
  lIndex: Integer;
begin
  lSource := FSource;
  lToken := FSourceToken;
  FSource := nil;
  FSourceObject := nil;
  FSession := nil;
  FSourceToken := 0;
  Inc(FGeneration);
  for lIndex := 0 to High(FLinks) do FLinks[lIndex].DetachSource;
  if (lSource <> nil) and (lToken <> 0) then lSource.Unsubscribe(lToken);
end;

procedure TNXBindingSource.Rebind;
var
  lIndex: Integer;
begin
  Inc(FGeneration);
  FCurrentNotification := True;
  FDataNotification := True;
  for lIndex := 0 to High(FLinks) do
    if FLinks[lIndex].FActive then
    begin
      if FLinks[lIndex].FState.Pending then FLinks[lIndex].FState.Orphaned := True;
      FLinks[lIndex].FHasAccepted := False;
      FLinks[lIndex].Resolve;
    end;
  PullAll;
end;

function TNXBindingSource.PullAll: TNXBindingResult;
var
  lIndex: Integer;
  lResult: TNXBindingResult;
begin
  FRefreshPending := False;
  Result := TNXBindingResult.Make(bcSuccess);
  for lIndex := 0 to High(FLinks) do
    if FLinks[lIndex].FActive then
    begin
      lResult := FLinks[lIndex].Pull;
      if Result.Succeeded and not lResult.Succeeded then Result := lResult;
    end;
end;

procedure TNXBindingSource.Changed(ASubject: TObject;
  const AEvent: TNXBindingEvent);
var
  lIndex: Integer;
begin
  if ASubject <> FSourceObject then Exit;
  Inc(FDepth);
  try
    if AEvent.Kind = beClosing then
    begin
      FSource := nil;
      FSourceObject := nil;
      FSession := nil;
      FSourceToken := 0;
      Rebind;
    end
    else if AEvent.Kind = beCurrentChanged then Rebind
    else if (FWriting <> nil) or FSessionOperation then FRefreshPending := True
    else
    begin
      for lIndex := 0 to High(FLinks) do
        if FLinks[lIndex].FActive and (FLinks[lIndex].FSource = nil) then
          FLinks[lIndex].Resolve;
      PullAll;
      FDataNotification := True;
    end;
  finally
    Leave;
  end;
end;

function TNXBindingSource.Attach(ASource: TObject): TNXBindingResult;
var
  lSource: INXItemSource;
  lSession: INXBindingEditSession;
begin
  if FDepth <> 0 then Exit(TNXBindingResult.Make(bcBusy));
  if GetDirty then Exit(TNXBindingResult.Make(bcPendingEdits));
  lSource := nil;
  lSession := nil;
  if ASource <> nil then
  begin
    if not Supports(ASource, INXItemSource, lSource) then
      Exit(TNXBindingResult.Make(bcUnsupported));
    Supports(ASource, INXBindingEditSession, lSession);
  end;
  Inc(FDepth);
  try
    DisconnectSource;
    FSource := lSource;
    FSourceObject := ASource;
    FSession := lSession;
    if FSource <> nil then
    begin
      FSourceToken := FSource.Subscribe(Self);
      if FSourceToken = 0 then
      begin
        FSource := nil;
        FSourceObject := nil;
        FSession := nil;
      end;
    end;
    Rebind;
    if (ASource <> nil) and (FSource = nil) then
      Result := TNXBindingResult.Make(bcUnavailable)
    else Result := TNXBindingResult.Make(bcSuccess);
  finally
    Leave;
  end;
end;

function TNXBindingSource.GetCurrent: INXBindingItem;
begin
  Result := nil;
  if FSource <> nil then Result := FSource.GetCurrent;
end;

function TNXBindingSource.GetDirty: Boolean;
var
  lIndex: Integer;
begin
  Result := True;
  for lIndex := 0 to High(FLinks) do
    if FLinks[lIndex].FActive and FLinks[lIndex].FState.Pending then Exit;
  Result := (FSession <> nil) and FSession.GetDirty;
end;

function TNXBindingSource.Navigate(ADirection: TNavigation): TNXBindingResult;
begin
  if FDepth <> 0 then Exit(TNXBindingResult.Make(bcBusy));
  if GetDirty then Exit(TNXBindingResult.Make(bcPendingEdits));
  if FSource = nil then Exit(TNXBindingResult.Make(bcUnavailable));
  Inc(FDepth);
  try
    case ADirection of
      nFirst: Result := FSource.First;
      nPrior: Result := FSource.Prior;
      nNext: Result := FSource.Next;
      nLast: Result := FSource.Last;
    end;
  finally
    Leave;
  end;
end;

function TNXBindingSource.First: TNXBindingResult;
begin
  Result := Navigate(nFirst);
end;

function TNXBindingSource.Prior: TNXBindingResult;
begin
  Result := Navigate(nPrior);
end;

function TNXBindingSource.Next: TNXBindingResult;
begin
  Result := Navigate(nNext);
end;

function TNXBindingSource.Last: TNXBindingResult;
begin
  Result := Navigate(nLast);
end;

function TNXBindingSource.Bind(const AMember: UTF8String; ATarget: TObject;
  AMode: TNXBindingMode; ATrigger: TNXBindingTrigger; out ABinding: QWord;
  AConverter: INXBindingConverter; AValidator: INXBindingValidator): TNXBindingResult;
var
  lValue: INXBindingValue;
  lWriter: INXBindingWritableValue;
  lLink: TNXBindingLink;
begin
  ABinding := 0;
  if FDepth <> 0 then Exit(TNXBindingResult.Make(bcBusy));
  if not Supports(ATarget, INXBindingValue, lValue) or
    not Supports(ATarget, INXBindingWritableValue, lWriter) then
    Exit(TNXBindingResult.Make(bcUnsupported, 'Target must be a writable endpoint.'));
  Inc(FDepth);
  try
    lLink := TNXBindingLink.Create(Self);
    Inc(FNextHandle);
    lLink.FHandle := FNextHandle;
    lLink.FMember := AMember;
    lLink.FTarget := lValue;
    lLink.FTargetObject := ATarget;
    lLink.FTargetWriter := lWriter;
    lLink.FMode := AMode;
    lLink.FTrigger := ATrigger;
    lLink.FConverter := AConverter;
    lLink.FValidator := AValidator;
    SetLength(FLinks, Length(FLinks) + 1);
    FLinks[High(FLinks)] := lLink;
    ABinding := lLink.FHandle;
    lLink.FTargetToken := lValue.Subscribe(lLink);
    if lLink.FTargetToken = 0 then
    begin
      lLink.Disconnect;
      Exit(lLink.Remember(TNXBindingResult.Make(bcUnavailable)));
    end;
    lLink.Resolve;
    Result := lLink.Pull;
  finally
    Leave;
  end;
end;

function TNXBindingSource.Remove(ABinding: QWord): TNXBindingResult;
var
  lLink: TNXBindingLink;
begin
  lLink := Find(ABinding);
  if lLink = nil then Exit(TNXBindingResult.Make(bcInvalidHandle));
  lLink.FActive := False;
  lLink.Disconnect;
  Collect;
  Result := TNXBindingResult.Make(bcSuccess);
end;

function TNXBindingSource.GetState(ABinding: QWord;
  out AState: TNXBindingState): TNXBindingResult;
var
  lLink: TNXBindingLink;
begin
  AState := Default(TNXBindingState);
  lLink := Find(ABinding);
  if lLink = nil then Exit(TNXBindingResult.Make(bcInvalidHandle));
  AState := lLink.FState;
  Result := TNXBindingResult.Make(bcSuccess);
end;

function TNXBindingSource.Refresh: TNXBindingResult;
var
  lIndex: Integer;
begin
  if FDepth <> 0 then Exit(TNXBindingResult.Make(bcBusy));
  Inc(FDepth);
  try
    for lIndex := 0 to High(FLinks) do
      if FLinks[lIndex].FActive and (FLinks[lIndex].FSource = nil) then
        FLinks[lIndex].Resolve;
    Result := PullAll;
  finally
    Leave;
  end;
end;

function TNXBindingSource.Submit(ABinding: QWord): TNXBindingResult;
var
  lLink: TNXBindingLink;
begin
  if FDepth <> 0 then Exit(TNXBindingResult.Make(bcBusy));
  lLink := Find(ABinding);
  if lLink = nil then Exit(TNXBindingResult.Make(bcInvalidHandle));
  Inc(FDepth);
  try
    Result := lLink.Push;
  finally
    Leave;
  end;
end;

function TNXBindingSource.SubmitPending: TNXBindingResult;
var
  lIndex, lOther: Integer;
  lLink, lSibling: TNXBindingLink;
  lValue, lOtherValue: TNXBindingValue;
begin
  { Reject conflicting proposals before any write, not after the first one. }
  for lIndex := 0 to High(FLinks) do
  begin
    lLink := FLinks[lIndex];
    if not lLink.FActive or not lLink.FState.Pending then Continue;
    for lOther := lIndex + 1 to High(FLinks) do
    begin
      lSibling := FLinks[lOther];
      if lSibling.FActive and lSibling.FState.Pending and
        (lLink.FMember = lSibling.FMember) then
      begin
        Result := lLink.Prepare(lValue);
        if not Result.Succeeded then Exit(lLink.Remember(Result));
        Result := lSibling.Prepare(lOtherValue);
        if not Result.Succeeded then Exit(lSibling.Remember(Result));
        if not lValue.SameValue(lOtherValue) then
          Exit(lLink.Remember(TNXBindingResult.Make(bcAmbiguousProposal)));
      end;
    end;
  end;
  Result := TNXBindingResult.Make(bcSuccess);
  FSubmittingAll := True;
  try
    for lIndex := 0 to High(FLinks) do
      if FLinks[lIndex].FActive and FLinks[lIndex].FState.Pending then
      begin
        Result := FLinks[lIndex].Push;
        if not Result.Succeeded then Exit;
      end;
  finally
    FSubmittingAll := False;
  end;
end;

function TNXBindingSource.SubmitAll: TNXBindingResult;
begin
  if FDepth <> 0 then Exit(TNXBindingResult.Make(bcBusy));
  Inc(FDepth);
  try
    Result := SubmitPending;
  finally
    Leave;
  end;
end;

function TNXBindingSource.CancelPending(ABinding: QWord): TNXBindingResult;
var
  lLink: TNXBindingLink;
begin
  if FDepth <> 0 then Exit(TNXBindingResult.Make(bcBusy));
  lLink := Find(ABinding);
  if lLink = nil then Exit(TNXBindingResult.Make(bcInvalidHandle));
  Inc(FDepth);
  try
    lLink.ClearPending;
    Result := lLink.Pull;
  finally
    Leave;
  end;
end;

function TNXBindingSource.Rebase(ABinding: QWord): TNXBindingResult;
var
  lLink: TNXBindingLink;
  lValue: TNXBindingValue;
  lGeneration: QWord;
begin
  if FDepth <> 0 then Exit(TNXBindingResult.Make(bcBusy));
  lLink := Find(ABinding);
  if lLink = nil then Exit(TNXBindingResult.Make(bcInvalidHandle));
  lGeneration := FGeneration;
  Inc(FDepth);
  try
    if lLink.FState.Orphaned or not lLink.Live(lGeneration) then
      Exit(lLink.Remember(TNXBindingResult.Make(bcUnavailable)));
    Result := lLink.FSource.TryRead(lValue);
    if not lLink.Live(lGeneration) then
      Exit(lLink.Remember(TNXBindingResult.Make(bcUnavailable)));
    if Result.Succeeded then
    begin
      lLink.FBaseline := lValue;
      lLink.FState.SourceValue := lValue;
      lLink.FState.SourceChanged := False;
    end;
    Result := lLink.Remember(Result);
  finally
    Leave;
  end;
end;

function TNXBindingSource.CommitEdit: TNXBindingResult;
begin
  if FDepth <> 0 then Exit(TNXBindingResult.Make(bcBusy));
  if FSession = nil then Exit(TNXBindingResult.Make(bcUnsupported));
  Inc(FDepth);
  try
    Result := SubmitPending;
    if not Result.Succeeded then Exit;
    if FSession = nil then Exit(TNXBindingResult.Make(bcUnavailable));
    FSessionOperation := True;
    try
      Result := FSession.Commit;
    finally
      FSessionOperation := False;
    end;
    if Result.Succeeded then PullAll;
    FDataNotification := True;
  finally
    Leave;
  end;
end;

function TNXBindingSource.CancelEdit: TNXBindingResult;
var
  lIndex: Integer;
begin
  if FDepth <> 0 then Exit(TNXBindingResult.Make(bcBusy));
  if FSession = nil then Exit(TNXBindingResult.Make(bcUnsupported));
  Inc(FDepth);
  try
    FSessionOperation := True;
    try
      Result := FSession.Cancel;
    finally
      FSessionOperation := False;
    end;
    if Result.Succeeded then
    begin
      for lIndex := 0 to High(FLinks) do
        if FLinks[lIndex].FActive and not FLinks[lIndex].FState.Orphaned then
          FLinks[lIndex].ClearPending;
      PullAll;
    end;
    FDataNotification := True;
  finally
    Leave;
  end;
end;

end.

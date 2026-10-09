(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXBindingSubscriptions;

{$mode objfpc}{$H+}{$interfaces corba}

interface

uses tpNXBinding;

type
  { Owned registration storage; never owns a subject or observer. }
  TNXBindingSubscriptions = class
  private
    type
      TEntry = record
        Token: QWord;
        Observer: INXBindingObserver;
      end;
    var
      FEntries: array of TEntry;
      FNextToken: QWord;
      FDepth: Integer;
      FClosed: Boolean;
    procedure Compact;
  public
    function Subscribe(AObserver: INXBindingObserver): QWord;
    procedure Unsubscribe(AToken: QWord);
    procedure Notify(ASubject: TObject;
      AKind: TNXBindingEventKind; ABinding: QWord = 0);
    property Closed: Boolean read FClosed;
  end;

implementation

uses SysUtils;

procedure TNXBindingSubscriptions.Compact;
var
  lRead, lWrite: Integer;
begin
  if FDepth <> 0 then Exit;
  lWrite := 0;
  for lRead := 0 to High(FEntries) do
    if FEntries[lRead].Observer <> nil then
    begin
      FEntries[lWrite] := FEntries[lRead];
      Inc(lWrite);
    end;
  SetLength(FEntries, lWrite);
end;

function TNXBindingSubscriptions.Subscribe(AObserver: INXBindingObserver): QWord;
var
  lIndex: Integer;
begin
  Result := 0;
  if FClosed or (AObserver = nil) then Exit;
  Inc(FNextToken);
  lIndex := Length(FEntries);
  SetLength(FEntries, lIndex + 1);
  FEntries[lIndex].Token := FNextToken;
  FEntries[lIndex].Observer := AObserver;
  Result := FNextToken;
end;

procedure TNXBindingSubscriptions.Unsubscribe(AToken: QWord);
var
  lIndex: Integer;
begin
  for lIndex := 0 to High(FEntries) do
    if FEntries[lIndex].Token = AToken then
    begin
      FEntries[lIndex].Observer := nil;
      Break;
    end;
  Compact;
end;

procedure TNXBindingSubscriptions.Notify(ASubject: TObject;
  AKind: TNXBindingEventKind; ABinding: QWord);
var
  lIndex, lLimit: Integer;
  lEvent: TNXBindingEvent;
  lError: Exception;
begin
  if FClosed then Exit;
  if AKind = beClosing then FClosed := True;
  lEvent.Kind := AKind;
  lEvent.Binding := ABinding;
  lLimit := Length(FEntries);
  lError := nil;
  Inc(FDepth);
  try
    for lIndex := 0 to lLimit - 1 do
      if FEntries[lIndex].Observer <> nil then
      begin
        try
          FEntries[lIndex].Observer.Changed(ASubject, lEvent);
        except
          on lCaught: Exception do
          begin
            if AKind <> beClosing then raise;
            { Closing must reach the remaining borrowers even if one fails. }
            if lError = nil then
            begin
              AcquireExceptionObject;
              lError := lCaught;
            end;
          end;
        end;
      end;
  finally
    Dec(FDepth);
    if FClosed then
      for lIndex := 0 to High(FEntries) do FEntries[lIndex].Observer := nil;
    Compact;
  end;
  if lError <> nil then raise lError;
end;

end.

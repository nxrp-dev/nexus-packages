(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPQueue;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, SyncObjs, obNXXMPPError, tpNXXMPPTypes;

type
  TNXXMPPObjectQueue = class
  private
    FCapacity: Integer;
    FCriticalSection: TCriticalSection;
    FItems: TList;
  public
    constructor Create(ACapacity: Integer);
    destructor Destroy; override;
    function Count: Integer;
    function Dequeue: TObject;
    function Enqueue(AItem: TObject): Boolean;
  end;

implementation

constructor TNXXMPPObjectQueue.Create(ACapacity: Integer);
begin
  inherited Create;
  if ACapacity < 1 then
    raise ENXXMPPError.Create(xesConfiguration, 'invalid-queue-capacity',
      'An XMPP queue capacity must be positive.');
  FCapacity := ACapacity;
  FCriticalSection := TCriticalSection.Create;
  FItems := TList.Create;
end;

destructor TNXXMPPObjectQueue.Destroy;
var
  lIndex: Integer;
begin
  FCriticalSection.Acquire;
  try
    for lIndex := 0 to FItems.Count - 1 do
      TObject(FItems[lIndex]).Free;
    FItems.Clear;
  finally
    FCriticalSection.Release;
  end;
  FItems.Free;
  FCriticalSection.Free;
  inherited Destroy;
end;

function TNXXMPPObjectQueue.Count: Integer;
begin
  FCriticalSection.Acquire;
  try
    Result := FItems.Count;
  finally
    FCriticalSection.Release;
  end;
end;

function TNXXMPPObjectQueue.Enqueue(AItem: TObject): Boolean;
begin
  if not Assigned(AItem) then
    Exit(False);
  FCriticalSection.Acquire;
  try
    Result := FItems.Count < FCapacity;
    if Result then
      FItems.Add(AItem);
  finally
    FCriticalSection.Release;
  end;
end;

function TNXXMPPObjectQueue.Dequeue: TObject;
begin
  FCriticalSection.Acquire;
  try
    if FItems.Count = 0 then
      Exit(nil);
    Result := TObject(FItems[0]);
    FItems.Delete(0);
  finally
    FCriticalSection.Release;
  end;
end;

end.

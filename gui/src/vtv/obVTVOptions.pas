(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obVTVOptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, tpVTV;

type
  TVirtualTreeOptions = class(TPersistent)
  private
    FAutoOptions: TVTAutoOptions;
    FMiscOptions: TVTMiscOptions;
    FPaintOptions: TVTPaintOptions;
    FSelectionOptions: TVTSelectionOptions;
    FOnChange: TNotifyEvent;
  protected
    procedure SetAutoOptions(AValue: TVTAutoOptions);
    procedure SetMiscOptions(AValue: TVTMiscOptions);
    procedure SetPaintOptions(AValue: TVTPaintOptions);
    procedure SetSelectionOptions(AValue: TVTSelectionOptions);
    procedure Changed;
  public
    constructor Create;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property AutoOptions: TVTAutoOptions read FAutoOptions write SetAutoOptions;
    property MiscOptions: TVTMiscOptions read FMiscOptions write SetMiscOptions;
    property PaintOptions: TVTPaintOptions read FPaintOptions write SetPaintOptions;
    property SelectionOptions: TVTSelectionOptions read FSelectionOptions
      write SetSelectionOptions;
  end;

implementation

constructor TVirtualTreeOptions.Create;
begin
  inherited Create;
  FPaintOptions := [toShowButtons, toShowTreeLines, toShowRoot];
  FSelectionOptions := [toFullRowSelect];
end;

procedure TVirtualTreeOptions.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TVirtualTreeOptions.SetAutoOptions(AValue: TVTAutoOptions);
begin
  if FAutoOptions = AValue then Exit;
  FAutoOptions := AValue;
  Changed;
end;

procedure TVirtualTreeOptions.SetMiscOptions(AValue: TVTMiscOptions);
begin
  if FMiscOptions = AValue then Exit;
  FMiscOptions := AValue;
  Changed;
end;

procedure TVirtualTreeOptions.SetPaintOptions(AValue: TVTPaintOptions);
begin
  if FPaintOptions = AValue then Exit;
  FPaintOptions := AValue;
  Changed;
end;

procedure TVirtualTreeOptions.SetSelectionOptions(AValue: TVTSelectionOptions);
begin
  if FSelectionOptions = AValue then Exit;
  FSelectionOptions := AValue;
  Changed;
end;

end.

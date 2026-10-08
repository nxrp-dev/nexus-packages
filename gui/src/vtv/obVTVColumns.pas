(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obVTVColumns;

{$mode objfpc}{$H+}

interface

uses
  Classes, Math;

type
  TVirtualTreeColumn = class(TCollectionItem)
  private
    FAlignment: TAlignment;
    FEditable: Boolean;
    FMinWidth: Integer;
    FText: string;
    FVisible: Boolean;
    FWidth: Integer;
  protected
    procedure SetAlignment(AValue: TAlignment);
    procedure SetEditable(AValue: Boolean);
    procedure SetMinWidth(AValue: Integer);
    procedure SetText(const AValue: string);
    procedure SetVisible(AValue: Boolean);
    procedure SetWidth(AValue: Integer);
  public
    constructor Create(ACollection: TCollection); override;
  published
    property Alignment: TAlignment read FAlignment write SetAlignment;
    property Editable: Boolean read FEditable write SetEditable;
    property MinWidth: Integer read FMinWidth write SetMinWidth;
    property Text: string read FText write SetText;
    property Visible: Boolean read FVisible write SetVisible;
    property Width: Integer read FWidth write SetWidth;
  end;

  TVirtualTreeColumns = class(TCollection)
  private
    FOnChange: TNotifyEvent;
  protected
    function GetColumn(AIndex: Integer): TVirtualTreeColumn;
    procedure Update(AItem: TCollectionItem); override;
  public
    constructor Create;
    function Add: TVirtualTreeColumn;
    property Items[AIndex: Integer]: TVirtualTreeColumn read GetColumn; default;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TVirtualTreeHeader = class(TPersistent)
  private
    FColumns: TVirtualTreeColumns;
    FHeight: Integer;
    FMainColumn: Integer;
    FOnChange: TNotifyEvent;
    FSortColumn: Integer;
    FSortDescending: Boolean;
    FVisible: Boolean;
  protected
    procedure Changed(ASender: TObject);
    procedure SetHeight(AValue: Integer);
    procedure SetMainColumn(AValue: Integer);
    procedure SetSortColumn(AValue: Integer);
    procedure SetSortDescending(AValue: Boolean);
    procedure SetVisible(AValue: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    property Columns: TVirtualTreeColumns read FColumns;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Height: Integer read FHeight write SetHeight;
    property MainColumn: Integer read FMainColumn write SetMainColumn;
    property SortColumn: Integer read FSortColumn write SetSortColumn;
    property SortDescending: Boolean read FSortDescending write SetSortDescending;
    property Visible: Boolean read FVisible write SetVisible;
  end;

implementation

constructor TVirtualTreeColumn.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FWidth := 200;
  FMinWidth := 24;
  FVisible := True;
end;

procedure TVirtualTreeColumn.SetAlignment(AValue: TAlignment);
begin
  if FAlignment = AValue then Exit;
  FAlignment := AValue;
  Changed(False);
end;

procedure TVirtualTreeColumn.SetEditable(AValue: Boolean);
begin
  if FEditable = AValue then Exit;
  FEditable := AValue;
  Changed(False);
end;

procedure TVirtualTreeColumn.SetMinWidth(AValue: Integer);
begin
  FMinWidth := Max(1, AValue);
  FWidth := Max(FWidth, FMinWidth);
  Changed(False);
end;

procedure TVirtualTreeColumn.SetText(const AValue: string);
begin
  if FText = AValue then Exit;
  FText := AValue;
  Changed(False);
end;

procedure TVirtualTreeColumn.SetVisible(AValue: Boolean);
begin
  if FVisible = AValue then Exit;
  FVisible := AValue;
  Changed(False);
end;

procedure TVirtualTreeColumn.SetWidth(AValue: Integer);
begin
  AValue := Max(FMinWidth, AValue);
  if FWidth = AValue then Exit;
  FWidth := AValue;
  Changed(False);
end;

constructor TVirtualTreeColumns.Create;
begin
  inherited Create(TVirtualTreeColumn);
end;

function TVirtualTreeColumns.Add: TVirtualTreeColumn;
begin
  Result := TVirtualTreeColumn(inherited Add);
end;

function TVirtualTreeColumns.GetColumn(AIndex: Integer): TVirtualTreeColumn;
begin
  Result := TVirtualTreeColumn(inherited Items[AIndex]);
end;

procedure TVirtualTreeColumns.Update(AItem: TCollectionItem);
begin
  inherited Update(AItem);
  if Assigned(FOnChange) then FOnChange(Self);
end;

constructor TVirtualTreeHeader.Create;
begin
  inherited Create;
  FHeight := 28;
  FVisible := True;
  FSortColumn := -1;
  FColumns := TVirtualTreeColumns.Create;
  FColumns.OnChange := @Changed;
end;

destructor TVirtualTreeHeader.Destroy;
begin
  FColumns.Free;
  inherited Destroy;
end;

procedure TVirtualTreeHeader.Changed(ASender: TObject);
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TVirtualTreeHeader.SetHeight(AValue: Integer);
begin
  AValue := Max(1, AValue);
  if FHeight = AValue then Exit;
  FHeight := AValue;
  Changed(Self);
end;

procedure TVirtualTreeHeader.SetMainColumn(AValue: Integer);
begin
  if FMainColumn = AValue then Exit;
  FMainColumn := AValue;
  Changed(Self);
end;

procedure TVirtualTreeHeader.SetSortColumn(AValue: Integer);
begin
  if FSortColumn = AValue then Exit;
  FSortColumn := AValue;
  Changed(Self);
end;

procedure TVirtualTreeHeader.SetSortDescending(AValue: Boolean);
begin
  if FSortDescending = AValue then Exit;
  FSortDescending := AValue;
  Changed(Self);
end;

procedure TVirtualTreeHeader.SetVisible(AValue: Boolean);
begin
  if FVisible = AValue then Exit;
  FVisible := AValue;
  Changed(Self);
end;

end.

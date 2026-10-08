(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXRender;

{$mode objfpc}{$H+}

interface

uses Classes, fpg_main, tpNXRender;

type
  TNexusControlState = class(TPersistent)
  private
    FLeft, FTop, FWidth, FHeight: Integer;
    FStates: TNXRenderStates;
  protected
    function GetDisabled: Boolean;
    function GetPressed: Boolean;
    function GetHovered: Boolean;
    function GetFocused: Boolean;
    function GetSelected: Boolean;
  public
    property States: TNXRenderStates read FStates write FStates;
  published
    property Left: Integer read FLeft write FLeft;
    property Top: Integer read FTop write FTop;
    property Width: Integer read FWidth write FWidth;
    property Height: Integer read FHeight write FHeight;
    // Boolean views of the set for the existing scalar Lua snapshot contract.
    property Disabled: Boolean read GetDisabled;
    property Pressed: Boolean read GetPressed;
    property Hovered: Boolean read GetHovered;
    property Focused: Boolean read GetFocused;
    property Selected: Boolean read GetSelected;
  end;

  TNXRenderRegistry = class;

  // Values prepared for one draw, then projected to a Lua snapshot if needed.
  TNXRenderResources = class(TPersistent)
  public
    procedure Prepare(const ARenderName: string;
      AState: TNexusControlState); virtual; abstract;
  end;

  TNXRenderSubscription = class
  private
    FOwner: TNXRenderRegistry;
    FName: string;
  protected
    procedure DoRender(ACanvas: TfpgCanvas); virtual; abstract;
    procedure Invalidate; virtual;
    property Name: string read FName;
  public
    destructor Destroy; override;
    procedure Render(ACanvas: TfpgCanvas);
    function IsValid: Boolean;
  end;

  TNXRenderer = class
  private
    FStateClass: TPersistentClass;
  protected
    function Bind(AState: TNexusControlState): TNXRenderSubscription;
      virtual; abstract;
  public
    constructor Create(AStateClass: TPersistentClass);
    property StateClass: TPersistentClass read FStateClass;
  end;

  TNXRenderRegistry = class
  private
    FRenderers: TStringList;
    FSubscriptions: TFPList;
    FResolutionCount: SizeInt;
  public
    constructor Create;
    destructor Destroy; override;
    // Ownership transfers only on successful registration.
    procedure RegisterRenderer(const AName: string; ARenderer: TNXRenderer);
    function Subscribe(const AName: string;
      AState: TNexusControlState): TNXRenderSubscription;
    procedure Clear;
    property ResolutionCount: SizeInt read FResolutionCount;
  end;

implementation

uses SysUtils;

function TNexusControlState.GetDisabled: Boolean;
begin
  Result := nrsDisabled in FStates;
end;

function TNexusControlState.GetPressed: Boolean;
begin
  Result := nrsPressed in FStates;
end;

function TNexusControlState.GetHovered: Boolean;
begin
  Result := nrsHovered in FStates;
end;

function TNexusControlState.GetFocused: Boolean;
begin
  Result := nrsFocused in FStates;
end;

function TNexusControlState.GetSelected: Boolean;
begin
  Result := nrsSelected in FStates;
end;

destructor TNXRenderSubscription.Destroy;
begin
  if FOwner <> nil then
    FOwner.FSubscriptions.Remove(Self);
  inherited Destroy;
end;

procedure TNXRenderSubscription.Invalidate;
begin
  FOwner := nil;
end;

function TNXRenderSubscription.IsValid: Boolean;
begin
  Result := FOwner <> nil;
end;

procedure TNXRenderSubscription.Render(ACanvas: TfpgCanvas);
begin
  if not IsValid then
    raise Exception.CreateFmt('Render subscription "%s" is no longer valid.', [FName]);
  DoRender(ACanvas);
end;

constructor TNXRenderer.Create(AStateClass: TPersistentClass);
begin
  inherited Create;
  if (AStateClass = nil) or not AStateClass.InheritsFrom(TNexusControlState) then
    raise Exception.Create('A renderer requires a TNexusControlState class.');
  FStateClass := AStateClass;
end;

constructor TNXRenderRegistry.Create;
begin
  inherited Create;
  FRenderers := TStringList.Create;
  FRenderers.CaseSensitive := True;
  FRenderers.Sorted := True;
  FSubscriptions := TFPList.Create;
end;

destructor TNXRenderRegistry.Destroy;
begin
  Clear;
  FSubscriptions.Free;
  FRenderers.Free;
  inherited Destroy;
end;

procedure TNXRenderRegistry.Clear;
var
  lIndex: Integer;
begin
  if FSubscriptions <> nil then
  begin
    for lIndex := 0 to FSubscriptions.Count - 1 do
      TNXRenderSubscription(FSubscriptions[lIndex]).Invalidate;
    FSubscriptions.Clear;
  end;
  if FRenderers <> nil then
  begin
    for lIndex := 0 to FRenderers.Count - 1 do
      FRenderers.Objects[lIndex].Free;
    FRenderers.Clear;
  end;
end;

procedure TNXRenderRegistry.RegisterRenderer(const AName: string;
  ARenderer: TNXRenderer);
begin
  if (AName = '') or (ARenderer = nil) then
    raise Exception.Create('A render registration requires a name and renderer.');
  if FRenderers.IndexOf(AName) >= 0 then
    raise Exception.CreateFmt('Render capability "%s" is already registered.', [AName]);
  if FRenderers.IndexOfObject(ARenderer) >= 0 then
    raise Exception.Create('A renderer instance can only have one owner.');
  FRenderers.AddObject(AName, ARenderer);
end;

function TNXRenderRegistry.Subscribe(const AName: string;
  AState: TNexusControlState): TNXRenderSubscription;
var
  lIndex: Integer;
  lRenderer: TNXRenderer;
begin
  Inc(FResolutionCount);
  lIndex := FRenderers.IndexOf(AName);
  if lIndex < 0 then
    raise Exception.CreateFmt('Render capability "%s" is not registered.', [AName]);
  lRenderer := FRenderers.Objects[lIndex] as TNXRenderer;
  if AState = nil then
    raise Exception.CreateFmt('Render capability "%s" requires state.', [AName]);
  if not AState.InheritsFrom(lRenderer.StateClass) then
    raise Exception.CreateFmt('Render capability "%s" expects %s, received %s.',
      [AName, lRenderer.StateClass.ClassName, AState.ClassName]);
  Result := lRenderer.Bind(AState);
  try
    FSubscriptions.Add(Result);
    Result.FName := AName;
    Result.FOwner := Self;
  except
    Result.Free;
    raise;
  end;
end;

end.

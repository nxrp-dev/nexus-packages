(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXClassFactory;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils;

type
  ENXClassFactory = class(Exception);

  TNXFactoryObject = class(TPersistent)
  public
    constructor Create; virtual;
    class function GetFactoryName: string; virtual;
    class procedure InitClass; virtual;
    class procedure ReleaseClass; virtual;
  end;

  TNXFactoryObjectClass = class of TNXFactoryObject;

  TNXClassFactory = class(TObject)
  private
    class var FClasses: TStringList;

    class function NormalizeKey(const AKey: string): string;
  public
    class constructor Create;
    class destructor Destroy;

    class procedure Clear;
    class procedure RegisterClass(const AClass: TNXFactoryObjectClass); overload;
    class procedure RegisterClass(const AKey: string; const AClass: TNXFactoryObjectClass); overload;
    class function CreateObject(const AKey: string): TNXFactoryObject;
    class function FindClass(const AKey: string): TNXFactoryObjectClass;
    class function Registered(const AKey: string): Boolean;
  end;

implementation

constructor TNXFactoryObject.Create;
begin
  inherited Create;
end;

class function TNXFactoryObject.GetFactoryName: string;
begin
  Result := ClassName;
end;

class procedure TNXFactoryObject.InitClass;
begin
end;

class procedure TNXFactoryObject.ReleaseClass;
begin
end;

class constructor TNXClassFactory.Create;
begin
  FClasses := TStringList.Create;
  FClasses.CaseSensitive := True;
  FClasses.Sorted := True;
  FClasses.Duplicates := dupError;
end;

class destructor TNXClassFactory.Destroy;
begin
  Clear;
  FreeAndNil(FClasses);
end;

class function TNXClassFactory.NormalizeKey(const AKey: string): string;
begin
  Result := Trim(AKey);

  if Result = '' then
    raise ENXClassFactory.Create('Class factory key cannot be blank.');
end;

class procedure TNXClassFactory.Clear;
var
  lIdx: Integer;
begin
  for lIdx := FClasses.Count - 1 downto 0 do
    TNXFactoryObjectClass(FClasses.Objects[lIdx]).ReleaseClass;

  FClasses.Clear;
end;

class procedure TNXClassFactory.RegisterClass(const AClass: TNXFactoryObjectClass);
begin
  if AClass = nil then
    raise ENXClassFactory.Create('Class factory cannot register a nil class.');

  RegisterClass(AClass.GetFactoryName, AClass);
end;

class procedure TNXClassFactory.RegisterClass(const AKey: string; const AClass: TNXFactoryObjectClass);
var
  lKey: string;
  lIdx: Integer;
begin
  lKey := NormalizeKey(AKey);

  if AClass = nil then
    raise ENXClassFactory.CreateFmt('Class factory key "%s" cannot register a nil class.', [lKey]);

  if FClasses.Find(lKey, lIdx) then
    raise ENXClassFactory.CreateFmt('Class factory key "%s" is already registered.', [lKey]);

  FClasses.AddObject(lKey, TObject(AClass));

  try
    AClass.InitClass;
  except
    FClasses.Delete(FClasses.IndexOf(lKey));
    raise;
  end;
end;

class function TNXClassFactory.CreateObject(const AKey: string): TNXFactoryObject;
begin
  Result := FindClass(AKey).Create;
end;

class function TNXClassFactory.FindClass(const AKey: string): TNXFactoryObjectClass;
var
  lKey: string;
  lIdx: Integer;
begin
  lKey := NormalizeKey(AKey);

  if not FClasses.Find(lKey, lIdx) then
    raise ENXClassFactory.CreateFmt('Class factory key "%s" is not registered.', [lKey]);

  Result := TNXFactoryObjectClass(FClasses.Objects[lIdx]);
end;

class function TNXClassFactory.Registered(const AKey: string): Boolean;
var
  lIdx: Integer;
begin
  Result := FClasses.Find(NormalizeKey(AKey), lIdx);
end;

end.

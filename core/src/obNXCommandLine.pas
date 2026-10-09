(*
  Copyright (c) 2026 Kevin Collins.
  
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  
  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.
  
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXCommandLine;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils;

type
  ENXCommandLine = class(Exception);

  TNXCommandLineFlag = record
    Name: string;
    Required: Boolean;
    RequiresValue: Boolean;
    DefaultValue: string;
    ShortHelp: string;
    LongHelp: string;
  end;

  TNXCommandLineFlagDefinition = class(TObject)
  private
    FName: string;
    FRequired: Boolean;
    FRequiresValue: Boolean;
    FDefaultValue: string;
    FShortHelp: string;
    FLongHelp: string;
  public
    constructor Create(const AFlag: TNXCommandLineFlag);

    property Name: string read FName;
    property Required: Boolean read FRequired;
    property RequiresValue: Boolean read FRequiresValue;
    property DefaultValue: string read FDefaultValue;
    property ShortHelp: string read FShortHelp;
    property LongHelp: string read FLongHelp;
  end;

  TNXCommandLine = class(TObject)
  private
    class var FCommandLineFlags: TList;
    class var FValues: TStringList;
    class var FSupplied: TStringList;
    class var FExplicitValues: TStringList;
    class var FUnknownFlags: TStringList;
    class var FInvalidArguments: TStringList;
    class var FAllowUnknownFlags: Boolean;
    class var FParsed: Boolean;
    class var FDirty: Boolean;

    class procedure DefineInternalFlags; static;
    class function FindFlag(const AName: string): TNXCommandLineFlagDefinition; static;
    class function GetFlagDefinitionCount: Integer; static;
    class function HasRegisteredFlags: Boolean; static;
    class procedure RegisterFlagDefinition(AFlag: TNXCommandLineFlagDefinition); static;

    class function CleanName(const AName: string): string; static;
    class function IsSlashSwitch(const AArgument: string): Boolean; static;

    class function GetFlagCount: Integer; static;
    class function GetHelpRequested: Boolean; static;
    class function GetHelpFlagName: string; static;
    class function GetInvalidText: string; static;
    class function GetText: string; static;
    class function GetUnknownText: string; static;
    class function GetValue(const AName: string): string; static;
    class function GetValueRaw(const AName: string): string; static;
    class procedure SetValue(const AName, AValue: string); static;
    class function SuppliedRaw(const AName: string): Boolean; static;

    class procedure ApplyDefaults; static;
    class procedure WriteHelpAndHaltIfRequested; static;
    class procedure ParseArgument(const AArgument: string; out AName, AValue: string; out AHasValue: Boolean); static;
  public
    class constructor Create;
    class destructor Destroy;

    class procedure ClearRegisteredFlags; static;
    class procedure RegisterFlag(const AName: string; const ARequired: Boolean = False; const ARequiresValue: Boolean = False; const ADefaultValue: string = ''; const AShortHelp: string = ''; const ALongHelp: string = ''); static;
    class procedure RegisterFlags(const AFlags: array of TNXCommandLineFlag); static;

    class procedure ClearValues; static;
    class procedure Parse; static;
    class procedure ParseArguments(const AArguments: array of string); static;
    class procedure Validate; static;

    class function GetValueDefault(const AName, ADefaultValue: string): string; static;
    class function HasValue(const AName: string): Boolean; static;
    class function Supplied(const AName: string): Boolean; static;
    class function SuppliedWithValue(const AName: string): Boolean; static;
    class function HelpText: string; static;
    class function FlagHelpText(const AName: string): string; static;

    class property AllowUnknownFlags: Boolean read FAllowUnknownFlags write FAllowUnknownFlags;
    class property FlagCount: Integer read GetFlagCount;
    class property HelpRequested: Boolean read GetHelpRequested;
    class property HelpFlagName: string read GetHelpFlagName;
    class property InvalidText: string read GetInvalidText;
    class property Text: string read GetText;
    class property UnknownText: string read GetUnknownText;
    class property Value[const AName: string]: string read GetValue write SetValue; default;
  end;

function NXCommandLineFlag(const AName: string; const ARequired: Boolean = False; const ARequiresValue: Boolean = False; const ADefaultValue: string = ''; const AShortHelp: string = ''; const ALongHelp: string = ''): TNXCommandLineFlag;

implementation

function NXCommandLineFlag(const AName: string; const ARequired: Boolean; const ARequiresValue: Boolean; const ADefaultValue: string; const AShortHelp: string; const ALongHelp: string): TNXCommandLineFlag;
begin
  Result.Name := AName;
  Result.Required := ARequired;
  Result.RequiresValue := ARequiresValue;
  Result.DefaultValue := ADefaultValue;
  Result.ShortHelp := AShortHelp;
  Result.LongHelp := ALongHelp;
end;

constructor TNXCommandLineFlagDefinition.Create(const AFlag: TNXCommandLineFlag);
begin
  inherited Create;

  FName := AFlag.Name;
  FRequired := AFlag.Required;
  FRequiresValue := AFlag.RequiresValue;
  FDefaultValue := AFlag.DefaultValue;
  FShortHelp := AFlag.ShortHelp;
  FLongHelp := AFlag.LongHelp;
end;

class constructor TNXCommandLine.Create;
begin
  FCommandLineFlags := TList.Create;

  FValues := TStringList.Create;
  FValues.CaseSensitive := True;

  FSupplied := TStringList.Create;
  FSupplied.CaseSensitive := True;

  FExplicitValues := TStringList.Create;
  FExplicitValues.CaseSensitive := True;

  FUnknownFlags := TStringList.Create;
  FUnknownFlags.CaseSensitive := True;

  FInvalidArguments := TStringList.Create;
  FInvalidArguments.CaseSensitive := True;

  FAllowUnknownFlags := True;
  FParsed := False;
  FDirty := True;

  DefineInternalFlags;
  ApplyDefaults;
end;

class destructor TNXCommandLine.Destroy;
var
  lIdx: Integer;
begin
  for lIdx := 0 to FCommandLineFlags.Count - 1 do
    TObject(FCommandLineFlags[lIdx]).Free;

  FreeAndNil(FCommandLineFlags);
  FreeAndNil(FInvalidArguments);
  FreeAndNil(FUnknownFlags);
  FreeAndNil(FExplicitValues);
  FreeAndNil(FSupplied);
  FreeAndNil(FValues);
end;

class function TNXCommandLine.CleanName(const AName: string): string;
begin
  Result := Trim(AName);

  if Result = '' then
    Exit;

  if Pos('/', Result) > 0 then
    raise ENXCommandLine.CreateFmt('Command line flag name "%s" is invalid. Register names without a slash prefix.', [AName]);

  if Pos('=', Result) > 0 then
    raise ENXCommandLine.CreateFmt('Command line flag name "%s" is invalid. Register the name only.', [AName]);
end;

class procedure TNXCommandLine.DefineInternalFlags;
begin
  RegisterFlagDefinition(TNXCommandLineFlagDefinition.Create(
    NXCommandLineFlag('help', False, False, '', 'Show command line help', 'Use /help to show all flags or /help=flagname to show detailed help for one flag.')
  ));
end;

class procedure TNXCommandLine.ClearRegisteredFlags;
var
  lIdx: Integer;
begin
  for lIdx := 0 to FCommandLineFlags.Count - 1 do
    TObject(FCommandLineFlags[lIdx]).Free;

  FCommandLineFlags.Clear;
  DefineInternalFlags;
  ClearValues;
  FDirty := True;
end;

class function TNXCommandLine.FindFlag(const AName: string): TNXCommandLineFlagDefinition;
var
  lIdx: Integer;
  lName: string;
  lFlag: TNXCommandLineFlagDefinition;
begin
  Result := nil;
  lName := CleanName(AName);

  for lIdx := 0 to FCommandLineFlags.Count - 1 do
  begin
    lFlag := TNXCommandLineFlagDefinition(FCommandLineFlags[lIdx]);
    if lFlag.Name = lName then
    begin
      Result := lFlag;
      Exit;
    end;
  end;
end;

class function TNXCommandLine.GetFlagDefinitionCount: Integer;
begin
  Result := FCommandLineFlags.Count;
end;

class function TNXCommandLine.HasRegisteredFlags: Boolean;
begin
  Result := GetFlagDefinitionCount > 1;
end;

class procedure TNXCommandLine.RegisterFlagDefinition(AFlag: TNXCommandLineFlagDefinition);
var
  lName: string;
begin
  if AFlag = nil then
    Exit;

  lName := CleanName(AFlag.Name);

  if lName = '' then
    raise ENXCommandLine.Create('Command line flag name cannot be blank.');

  if FindFlag(lName) <> nil then
    raise ENXCommandLine.CreateFmt('Command line flag "%s" is already registered.', [lName]);

  FCommandLineFlags.Add(AFlag);

  if (AFlag.DefaultValue <> '') and (FValues.IndexOfName(lName) < 0) then
    FValues.Values[lName] := AFlag.DefaultValue;

  FDirty := True;
end;

class procedure TNXCommandLine.RegisterFlag(const AName: string; const ARequired: Boolean; const ARequiresValue: Boolean; const ADefaultValue: string; const AShortHelp: string; const ALongHelp: string);
var
  lFlag: TNXCommandLineFlag;
begin
  lFlag := NXCommandLineFlag(AName, ARequired, ARequiresValue, ADefaultValue, AShortHelp, ALongHelp);
  RegisterFlagDefinition(TNXCommandLineFlagDefinition.Create(lFlag));
end;

class procedure TNXCommandLine.RegisterFlags(const AFlags: array of TNXCommandLineFlag);
var
  lIdx: Integer;
begin
  for lIdx := Low(AFlags) to High(AFlags) do
    RegisterFlagDefinition(TNXCommandLineFlagDefinition.Create(AFlags[lIdx]));
end;

class function TNXCommandLine.IsSlashSwitch(const AArgument: string): Boolean;
var
  lArgument: string;
begin
  lArgument := Trim(AArgument);
  Result := (Length(lArgument) > 0) and (lArgument[1] = '/');
end;

class procedure TNXCommandLine.ClearValues;
begin
  FValues.Clear;
  FSupplied.Clear;
  FExplicitValues.Clear;
  FUnknownFlags.Clear;
  FInvalidArguments.Clear;
  FParsed := False;
  FDirty := True;
  ApplyDefaults;
end;

class procedure TNXCommandLine.ApplyDefaults;
var
  lIdx: Integer;
  lFlag: TNXCommandLineFlagDefinition;
begin
  for lIdx := 0 to FCommandLineFlags.Count - 1 do
  begin
    lFlag := TNXCommandLineFlagDefinition(FCommandLineFlags[lIdx]);

    if (lFlag.DefaultValue <> '') and (FValues.IndexOfName(lFlag.Name) < 0) then
      FValues.Values[lFlag.Name] := lFlag.DefaultValue;
  end;
end;


class procedure TNXCommandLine.WriteHelpAndHaltIfRequested;
var
  lHelpFlagName: string;
begin
  if not SuppliedRaw('help') then
    Exit;

  lHelpFlagName := GetValueRaw('help');

  if lHelpFlagName = 'true' then
    lHelpFlagName := '';

  if lHelpFlagName = '' then
  begin
    Write(HelpText);
    Halt(0);
  end;

  if FindFlag(lHelpFlagName) = nil then
  begin
    WriteLn('Unknown help topic: ' + lHelpFlagName);
    WriteLn;
    WriteLn('Use /help to list available options.');
    Halt(1);
  end;

  Write(FlagHelpText(lHelpFlagName));
  Halt(0);
end;

class procedure TNXCommandLine.ParseArgument(const AArgument: string; out AName, AValue: string; out AHasValue: Boolean);
var
  lArgument: string;
  lPos: Integer;
begin
  AName := '';
  AValue := '';
  AHasValue := False;

  lArgument := Trim(AArgument);

  if not IsSlashSwitch(lArgument) then
    raise ENXCommandLine.CreateFmt('Command line argument "%s" is invalid. Use /name or /name=value syntax.', [AArgument]);

  lArgument := Copy(lArgument, 2, Length(lArgument) - 1);

  if lArgument = '' then
    raise ENXCommandLine.Create('Command line argument "/" is invalid. Use /name or /name=value syntax.');

  lPos := Pos('=', lArgument);

  if lPos > 0 then
  begin
    AName := Copy(lArgument, 1, lPos - 1);
    AValue := Copy(lArgument, lPos + 1, Length(lArgument) - lPos);
    AHasValue := True;
  end
  else
    AName := lArgument;

  AName := CleanName(AName);

  if AName = '' then
    raise ENXCommandLine.CreateFmt('Command line argument "%s" is invalid. Flag name cannot be blank.', [AArgument]);
end;

class procedure TNXCommandLine.Parse;
var
  lArguments: array of string;
  lIdx: Integer;
begin
  if FParsed then
    Exit;

  SetLength(lArguments, ParamCount);

  for lIdx := 1 to ParamCount do
    lArguments[lIdx - 1] := ParamStr(lIdx);

  ParseArguments(lArguments);
end;

class procedure TNXCommandLine.ParseArguments(const AArguments: array of string);
var
  lIdx: Integer;
  lName: string;
  lValue: string;
  lHasValue: Boolean;
  lFlag: TNXCommandLineFlagDefinition;
begin
  ClearValues;

  for lIdx := Low(AArguments) to High(AArguments) do
  begin
    if not IsSlashSwitch(AArguments[lIdx]) then
    begin
      if Trim(AArguments[lIdx]) <> '' then
        FInvalidArguments.Add(AArguments[lIdx]);
      Continue;
    end;

    ParseArgument(AArguments[lIdx], lName, lValue, lHasValue);
    lFlag := FindFlag(lName);

    if not lHasValue then
      lValue := 'true';

    FValues.Values[lName] := lValue;
    FSupplied.Values[lName] := 'true';
    FExplicitValues.Values[lName] := BoolToStr(lHasValue, True);

    if (lFlag = nil) and HasRegisteredFlags then
      FUnknownFlags.Values[lName] := lValue;
  end;

  FParsed := True;
  FDirty := True;
end;

class procedure TNXCommandLine.Validate;
var
  lIdx: Integer;
  lFlag: TNXCommandLineFlagDefinition;
begin
  if not FParsed then
    Parse;

  WriteHelpAndHaltIfRequested;

  if not FDirty then
    Exit;

  if FInvalidArguments.Count > 0 then
    raise ENXCommandLine.CreateFmt('Invalid command line argument "%s". Use /name or /name=value syntax.', [FInvalidArguments[0]]);

  if (not FAllowUnknownFlags) and (FUnknownFlags.Count > 0) then
    raise ENXCommandLine.CreateFmt('Unknown command line flag "%s".', [FUnknownFlags.Names[0]]);

  for lIdx := 0 to FCommandLineFlags.Count - 1 do
  begin
    lFlag := TNXCommandLineFlagDefinition(FCommandLineFlags[lIdx]);

    if lFlag.Required and not SuppliedRaw(lFlag.Name) and (GetValueRaw(lFlag.Name) = '') then
      raise ENXCommandLine.CreateFmt('Required command line flag "%s" was not supplied.', [lFlag.Name]);

    if lFlag.RequiresValue and SuppliedRaw(lFlag.Name) and (GetValueRaw(lFlag.Name) = '') then
      raise ENXCommandLine.CreateFmt('Command line flag "%s" requires a value.', [lFlag.Name]);
  end;

  FDirty := False;
end;

class function TNXCommandLine.GetValue(const AName: string): string;
begin
  Validate;
  Result := GetValueRaw(AName);
end;

class function TNXCommandLine.GetValueRaw(const AName: string): string;
begin
  Result := FValues.Values[CleanName(AName)];
end;

class procedure TNXCommandLine.SetValue(const AName, AValue: string);
var
  lName: string;
begin
  lName := CleanName(AName);
  FValues.Values[lName] := AValue;
  FSupplied.Values[lName] := 'true';
  FDirty := True;
end;

class function TNXCommandLine.GetValueDefault(const AName, ADefaultValue: string): string;
begin
  Result := GetValue(AName);

  if Result = '' then
    Result := ADefaultValue;
end;

class function TNXCommandLine.HasValue(const AName: string): Boolean;
begin
  Validate;
  Result := FValues.IndexOfName(CleanName(AName)) >= 0;
end;

class function TNXCommandLine.Supplied(const AName: string): Boolean;
begin
  Validate;
  Result := SuppliedRaw(AName);
end;

class function TNXCommandLine.SuppliedWithValue(
  const AName: string): Boolean;
begin
  Validate;
  Result := SameText(FExplicitValues.Values[CleanName(AName)], 'true');
end;

class function TNXCommandLine.SuppliedRaw(const AName: string): Boolean;
begin
  Result := SameStr(FSupplied.Values[CleanName(AName)], 'true');
end;

class function TNXCommandLine.GetHelpRequested: Boolean;
begin
  if not FParsed then
    Parse;

  Result := SuppliedRaw('help');
end;

class function TNXCommandLine.GetHelpFlagName: string;
begin
  if not HelpRequested then
    Exit('');

  Result := GetValueRaw('help');

  if Result = 'true' then
    Result := '';
end;

class function TNXCommandLine.GetFlagCount: Integer;
begin
  Result := GetFlagDefinitionCount;
end;

class function TNXCommandLine.GetInvalidText: string;
begin
  Validate;
  Result := FInvalidArguments.Text;
end;

class function TNXCommandLine.GetText: string;
begin
  Validate;
  Result := FValues.Text;
end;

class function TNXCommandLine.GetUnknownText: string;
begin
  Validate;
  Result := FUnknownFlags.Text;
end;

class function TNXCommandLine.HelpText: string;
var
  lIdx: Integer;
  lFlag: TNXCommandLineFlagDefinition;
  lLine: string;
begin
  Result := '';

  for lIdx := 0 to FCommandLineFlags.Count - 1 do
  begin
    lFlag := TNXCommandLineFlagDefinition(FCommandLineFlags[lIdx]);
    lLine := '/' + lFlag.Name;

    if lFlag.RequiresValue then
      lLine := lLine + '=<value>';

    if lFlag.ShortHelp <> '' then
      lLine := lLine + '  ' + lFlag.ShortHelp;

    if lFlag.Required then
      lLine := lLine + '  [required]';

    if lFlag.DefaultValue <> '' then
      lLine := lLine + '  [default: ' + lFlag.DefaultValue + ']';

    Result := Result + lLine + LineEnding;
  end;
end;

class function TNXCommandLine.FlagHelpText(const AName: string): string;
var
  lFlag: TNXCommandLineFlagDefinition;
begin
  lFlag := FindFlag(AName);

  if lFlag = nil then
    raise ENXCommandLine.CreateFmt('Command line flag "%s" is not registered.', [AName]);

  Result := '/' + lFlag.Name;

  if lFlag.RequiresValue then
    Result := Result + '=<value>';

  Result := Result + LineEnding;

  if lFlag.ShortHelp <> '' then
    Result := Result + lFlag.ShortHelp + LineEnding;

  if lFlag.LongHelp <> '' then
    Result := Result + lFlag.LongHelp + LineEnding;

  if lFlag.Required then
    Result := Result + 'Required: true' + LineEnding;

  if lFlag.DefaultValue <> '' then
    Result := Result + 'Default: ' + lFlag.DefaultValue + LineEnding;
end;

end.

(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit utNexusScriptEditing;

{$mode delphi}{$H+}

interface

uses obNexusScriptLanguageDefinition;

function NexusScriptEditForms(AValueRule: TNSValueRule;
  AArrayRule: TNSArrayRule; AArrayEntry: Boolean): TNSSourceForms;

implementation

function NexusScriptEditForms(AValueRule: TNSValueRule;
  AArrayRule: TNSArrayRule; AArrayEntry: Boolean): TNSSourceForms;
var
  lCategories: TNSEffectiveCategories;
  lHasCategories: Boolean;
begin
  Result := [nsfText, nsfArray, nsfReference, nsfTextComposition];
  lHasCategories := False;
  lCategories := [];
  if AArrayEntry then
  begin
    Include(Result, nsfInlineDefinition);
    if AArrayRule <> nil then
    begin
      if AArrayRule.HasEntrySourceForms then Result := AArrayRule.EntrySourceForms;
      lHasCategories := AArrayRule.HasEntryCategories;
      lCategories := AArrayRule.EntryCategories;
    end;
  end
  else if AValueRule <> nil then
  begin
    if AValueRule.HasSourceForms then Result := AValueRule.SourceForms;
    { The current grammar accepts inline definitions as array entries only. }
    Exclude(Result, nsfInlineDefinition);
    lHasCategories := AValueRule.HasEffectiveCategories;
    lCategories := AValueRule.EffectiveCategories;
  end;
  if not lHasCategories then Exit;
  if not (necText in lCategories) then Result := Result - [nsfText, nsfTextComposition];
  if not (necArray in lCategories) then Exclude(Result, nsfArray);
  if not (necDefinition in lCategories) then Exclude(Result, nsfInlineDefinition);
end;

end.

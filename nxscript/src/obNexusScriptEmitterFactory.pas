(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNexusScriptEmitterFactory;

{$mode delphi}{$H+}

interface

uses
  obNexusScriptEmitter;

type
  TNexusScriptEmitterFactory = class
  public
    class function CreateEmitter(
      const AFormat: string): TNexusScriptEmitter; static;
  end;

implementation

uses
  obNXClassFactory,
  obNexusScriptJSON,
  obNexusScriptSQLite;

class function TNexusScriptEmitterFactory.CreateEmitter(
  const AFormat: string): TNexusScriptEmitter;
begin
  Result := TNexusScriptEmitter(TNXClassFactory.CreateObject(AFormat));
end;

end.

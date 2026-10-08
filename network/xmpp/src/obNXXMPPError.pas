(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPError;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  SysUtils, tpNXXMPPTypes;

type
  ENXXMPPError = class(Exception)
  private
    FStage: TNXXMPPErrorStage;
    FCondition: string;
    FRecoverable: Boolean;
  public
    constructor Create(AStage: TNXXMPPErrorStage; const ACondition,
      AMessage: string; ARecoverable: Boolean = False);
    property Stage: TNXXMPPErrorStage read FStage;
    property Condition: string read FCondition;
    property Recoverable: Boolean read FRecoverable;
  end;

implementation

constructor ENXXMPPError.Create(AStage: TNXXMPPErrorStage;
  const ACondition, AMessage: string; ARecoverable: Boolean);
begin
  inherited Create(AMessage);
  FStage := AStage;
  FCondition := ACondition;
  FRecoverable := ARecoverable;
end;

end.

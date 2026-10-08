(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tpNXLS;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  obNXJSONRPCMessages;

type
  ENXLSException = class(Exception);

const
  cNXLSModeStdIO = 'stdio';
  cNXLSModeTcpIP = 'tcpip';
  cNXLSRequestFailed = -32803;

procedure NXLSRaiseNotImplemented(const AFeature: string);

implementation

procedure NXLSRaiseNotImplemented(const AFeature: string);
begin
  raise ENXJSONRPC.CreateCode(cNXLSRequestFailed, AFeature + ' is not implemented.');
end;

end.

(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXLSTransportFactory;

{$mode objfpc}{$H+}

interface

uses
  obNXLSTransport;

type
  TNXLSTransportFactory = class
  public
    class function CreateTransport(const AMode: string): TNXLSTransport;
  end;

implementation

uses
  obNXClassFactory,
  obNXLSStdIOTransport,
  obNXLSTcpIPTransport;

class function TNXLSTransportFactory.CreateTransport(const AMode: string): TNXLSTransport;
begin
  Result := TNXLSTransport(TNXClassFactory.CreateObject(AMode));
end;

end.

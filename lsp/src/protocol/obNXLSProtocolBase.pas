(*
  Copyright (c) 2026 Kevin Collins.
  
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  
  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.
  
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXLSProtocolBase;

{$mode objfpc}{$H+}

interface

uses
  obNXJSONValues,
  obNXJSONRPCObjects;

type
  TNXLSPosition = class(TNXJSONObject)
  private
    Fline: TNXJSONInteger;
    Fcharacter: TNXJSONInteger;
  published
    property line: TNXJSONInteger read Fline write Fline;
    property character: TNXJSONInteger read Fcharacter write Fcharacter;
  end;

  TNXLSRange = class(TNXJSONObject)
  private
    Fstart: TNXLSPosition;
    Fend: TNXLSPosition;
  published
    property start: TNXLSPosition read Fstart write Fstart;
    property &end: TNXLSPosition read Fend write Fend;
  end;

  TNXLSTextDocumentIdentifier = class(TNXJSONObject)
  private
    Furi: TNXJSONString;
  published
    property uri: TNXJSONString read Furi write Furi;
  end;

  TNXLSVersionedTextDocumentIdentifier = class(TNXLSTextDocumentIdentifier)
  private
    Fversion: TNXJSONInteger;
  published
    property version: TNXJSONInteger read Fversion write Fversion;
  end;

  TNXLSOptionalVersionedTextDocumentIdentifier = class(TNXLSTextDocumentIdentifier)
  private
    Fversion: TNXJSONInteger;
  public
    constructor Create; override;
  published
    property version: TNXJSONInteger read Fversion write Fversion;
  end;

  TNXLSTextDocumentItem = class(TNXJSONObject)
  private
    Furi: TNXJSONString;
    FlanguageId: TNXJSONString;
    Fversion: TNXJSONInteger;
    Ftext: TNXJSONString;
  published
    property uri: TNXJSONString read Furi write Furi;
    property languageId: TNXJSONString read FlanguageId write FlanguageId;
    property version: TNXJSONInteger read Fversion write Fversion;
    property text: TNXJSONString read Ftext write Ftext;
  end;

  TNXLSLocation = class(TNXJSONObject)
  private
    Furi: TNXJSONString;
    Frange: TNXLSRange;
  published
    property uri: TNXJSONString read Furi write Furi;
    property range: TNXLSRange read Frange write Frange;
  end;

  TNXLSTextDocumentPositionParams = class(TNXJSONRPCObjectParams)
  private
    FtextDocument: TNXLSTextDocumentIdentifier;
    Fposition: TNXLSPosition;
  published
    property textDocument: TNXLSTextDocumentIdentifier read FtextDocument write FtextDocument;
    property position: TNXLSPosition read Fposition write Fposition;
  end;

implementation

constructor TNXLSOptionalVersionedTextDocumentIdentifier.Create;
begin
  inherited Create;
  version.AcceptsNull := True;
end;

end.

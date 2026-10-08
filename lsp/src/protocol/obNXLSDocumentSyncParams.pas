(*
  Copyright (c) 2026 Kevin Collins.
  
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  
  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.
  
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXLSDocumentSyncParams;

{$mode objfpc}{$H+}

interface

uses
  obNXJSONValues,
  obNXJSONRPCObjects,
  obNXLSProtocolBase;

type
  TNXLSContentChange = class(TNXJSONObject)
  private
    Frange: TNXLSRange;
    FrangeLength: TNXJSONInteger;
    Ftext: TNXJSONString;
  published
    property range: TNXLSRange read Frange write Frange;
    property rangeLength: TNXJSONInteger read FrangeLength write FrangeLength;
    property text: TNXJSONString read Ftext write Ftext;
  end;

  TNXLSContentChangeArray = class(TNXJSONArray)
  public
    class function ItemClass: TNXJSONRPCValueClass; override;
  end;

  TNXLSDidOpenTextDocumentParams = class(TNXJSONRPCObjectParams)
  private
    FtextDocument: TNXLSTextDocumentItem;
  published
    property textDocument: TNXLSTextDocumentItem read FtextDocument write FtextDocument;
  end;

  TNXLSDidChangeTextDocumentParams = class(TNXJSONRPCObjectParams)
  private
    FtextDocument: TNXLSVersionedTextDocumentIdentifier;
    FcontentChanges: TNXLSContentChangeArray;
  published
    property textDocument: TNXLSVersionedTextDocumentIdentifier read FtextDocument write FtextDocument;
    property contentChanges: TNXLSContentChangeArray read FcontentChanges write FcontentChanges;
  end;

  TNXLSWillSaveTextDocumentParams = class(TNXJSONRPCObjectParams)
  private
    FtextDocument: TNXLSTextDocumentIdentifier;
    Freason: TNXJSONInteger;
  published
    property textDocument: TNXLSTextDocumentIdentifier read FtextDocument write FtextDocument;
    property reason: TNXJSONInteger read Freason write Freason;
  end;

  TNXLSDidSaveTextDocumentParams = class(TNXJSONRPCObjectParams)
  private
    FtextDocument: TNXLSTextDocumentIdentifier;
    Ftext: TNXJSONString;
  published
    property textDocument: TNXLSTextDocumentIdentifier read FtextDocument write FtextDocument;
    property text: TNXJSONString read Ftext write Ftext;
  end;

  TNXLSDidCloseTextDocumentParams = class(TNXJSONRPCObjectParams)
  private
    FtextDocument: TNXLSTextDocumentIdentifier;
  published
    property textDocument: TNXLSTextDocumentIdentifier read FtextDocument write FtextDocument;
  end;

implementation

class function TNXLSContentChangeArray.ItemClass: TNXJSONRPCValueClass;
begin
  Result := TNXLSContentChange;
end;

end.

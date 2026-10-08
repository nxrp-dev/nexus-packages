(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tsNXLSPProtocolObjectTests;

{$mode objfpc}{$H+}

interface

uses
  obNXTestRegistry;

procedure RegisterNXLSPProtocolObjectTests(ARegistry: TNXTestRegistry);

implementation

uses
  fpjson,
  jsonparser,
  obNXLSDocumentSyncParams,
  obNXLSProtocolBase,
  obNXLSProtocolObjects,
  obNXLSProtocolParams,
  obNXTestContext,
  obNXTestSuite;

procedure NXLSSetPosition(APosition: TNXLSPosition; const ALine,
  ACharacter: Integer);
begin
  APosition.line.Value := ALine;
  APosition.character.Value := ACharacter;
end;

procedure NXLSSetRange(ARange: TNXLSRange; const AStartLine,
  AStartCharacter, AEndLine, AEndCharacter: Integer);
begin
  NXLSSetPosition(ARange.start, AStartLine, AStartCharacter);
  NXLSSetPosition(ARange.&end, AEndLine, AEndCharacter);
end;

procedure NXLSAssertRange(AContext: TNXTestContext; const AMessage: string;
  ARange: TNXLSRange; const AStartLine, AStartCharacter, AEndLine,
  AEndCharacter: Integer);
begin
  AContext.AssertTrue(Assigned(ARange), AMessage + ': range should exist.');
  AContext.AssertTrue(Assigned(ARange.start), AMessage + ': start should exist.');
  AContext.AssertTrue(Assigned(ARange.&end), AMessage + ': end should exist.');
  AContext.AssertEquals(AStartLine, ARange.start.line.AsInteger,
    AMessage + ': start line.');
  AContext.AssertEquals(AStartCharacter, ARange.start.character.AsInteger,
    AMessage + ': start character.');
  AContext.AssertEquals(AEndLine, ARange.&end.line.AsInteger,
    AMessage + ': end line.');
  AContext.AssertEquals(AEndCharacter, ARange.&end.character.AsInteger,
    AMessage + ': end character.');
end;

procedure TestRangeAutoCreatesPositions(AContext: TNXTestContext);
var
  lRange: TNXLSRange;
begin
  lRange := TNXLSRange.Create;
  try
    AContext.AssertTrue(Assigned(lRange.start),
      'Range should auto-create the start position.');
    AContext.AssertTrue(Assigned(lRange.&end),
      'Range should auto-create the end position.');
    AContext.AssertTrue(Assigned(lRange.start.line),
      'Range start should auto-create line.');
    AContext.AssertTrue(Assigned(lRange.start.character),
      'Range start should auto-create character.');
    AContext.AssertTrue(Assigned(lRange.&end.line),
      'Range end should auto-create line.');
    AContext.AssertTrue(Assigned(lRange.&end.character),
      'Range end should auto-create character.');
  finally
    lRange.Free;
  end;
end;

procedure TestRangeAssign(AContext: TNXTestContext);
var
  lSource: TNXLSRange;
  lTarget: TNXLSRange;
begin
  lSource := TNXLSRange.Create;
  lTarget := TNXLSRange.Create;
  try
    NXLSSetRange(lSource, 12, 13, 14, 15);
    lTarget.Assign(lSource);
    NXLSAssertRange(AContext, 'Assign', lTarget, 12, 13, 14, 15);
  finally
    lTarget.Free;
    lSource.Free;
  end;
end;

procedure TestRangeFromJSONData(AContext: TNXTestContext);
var
  lRange: TNXLSRange;
  lJSON: TJSONData;
begin
  lRange := TNXLSRange.Create;
  lJSON := GetJSON('{"start":{"line":10,"character":11},"end":{"line":12,"character":13}}');
  try
    lRange.FromJSONData(lJSON);
    NXLSAssertRange(AContext, 'FromJSONData', lRange, 10, 11, 12, 13);
  finally
    lJSON.Free;
    lRange.Free;
  end;
end;

procedure TestRangeToJSONData(AContext: TNXTestContext);
var
  lRange: TNXLSRange;
  lJSON: TJSONData;
  lObject: TJSONObject;
begin
  lRange := TNXLSRange.Create;
  try
    NXLSSetRange(lRange, 10, 11, 12, 13);

    lJSON := lRange.ToJSONData;
    try
      AContext.AssertTrue(lJSON is TJSONObject,
        'Range should serialize to a JSON object.');
      lObject := TJSONObject(lJSON);
      AContext.AssertEquals(10, lObject.Objects['start'].Integers['line'],
        'Serialized start line.');
      AContext.AssertEquals(11, lObject.Objects['start'].Integers['character'],
        'Serialized start character.');
      AContext.AssertEquals(12, lObject.Objects['end'].Integers['line'],
        'Serialized end line.');
      AContext.AssertEquals(13, lObject.Objects['end'].Integers['character'],
        'Serialized end character.');
    finally
      lJSON.Free;
    end;
  finally
    lRange.Free;
  end;
end;

procedure TestInitializeParamsIgnoreUnknownProperties(AContext: TNXTestContext);
var
  lParams: TNXLSInitializeParams;
  lJSON: TJSONData;
begin
  lParams := TNXLSInitializeParams.Create;
  lJSON := GetJSON('{"processId":123,"symbolDatabase":"/tmp/symbols.db","nonExistentProperty":"test"}');
  try
    lParams.FromJSONData(lJSON);
    AContext.AssertEquals(123, lParams.processId.AsInteger,
      'Known properties should still deserialize when unknown properties are present.');
  finally
    lJSON.Free;
    lParams.Free;
  end;
end;

procedure TestDocumentSyncAndCapabilitiesUseTypedObjects(AContext: TNXTestContext);
var
  lCapabilities: TNXLSServerCapabilities;
  lChange: TNXLSContentChange;
  lParams: TNXLSDidChangeTextDocumentParams;
begin
  lCapabilities := TNXLSServerCapabilities.Create;
  lParams := TNXLSDidChangeTextDocumentParams.Create;
  try
    AContext.AssertTrue(Assigned(lCapabilities.textDocumentSync),
      'Server capabilities should own typed document-sync options.');
    lChange := TNXLSContentChange(
      lParams.contentChanges.AddObject(TNXLSContentChange));
    lChange.text.Value := 'replacement';
    AContext.AssertTrue(lParams.contentChanges[0] is TNXLSContentChange,
      'Document changes should preserve their typed item class.');
  finally
    lParams.Free;
    lCapabilities.Free;
  end;
end;

procedure RegisterNXLSPProtocolObjectTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('NexusLSP.ProtocolObjects');
  lSuite.AddTest('RangeAutoCreatesPositions', @TestRangeAutoCreatesPositions);
  lSuite.AddTest('RangeAssign', @TestRangeAssign);
  lSuite.AddTest('RangeFromJSONData', @TestRangeFromJSONData);
  lSuite.AddTest('RangeToJSONData', @TestRangeToJSONData);
  lSuite.AddTest('InitializeParamsIgnoreUnknownProperties',
    @TestInitializeParamsIgnoreUnknownProperties);
  lSuite.AddTest('DocumentSyncAndCapabilitiesUseTypedObjects',
    @TestDocumentSyncAndCapabilitiesUseTypedObjects);
end;

end.

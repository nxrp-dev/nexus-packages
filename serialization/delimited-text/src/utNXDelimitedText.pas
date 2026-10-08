(*
  Copyright (c) 2026 Kevin Collins.
  
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  
  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.
  
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit utNXDelimitedText;

{$mode delphi}{$H+}

interface
uses SysUtils, fpjson;

type
  ENXDelimitedText = class(Exception);

// Caller owns the result. Values remain text; formatting belongs to the consumer.
function LoadNXDelimitedData(const AFileName: string; ADelimiter: Char): TJSONObject;

implementation
uses Classes;

procedure ParseDelimitedLine(const AFileName, ALine: string;
  ALineNumber: Integer; ADelimiter: Char; AValues: TStrings);
var
  lIndex: Integer;
  lInQuote: Boolean;
  lValue: string;
begin
  AValues.Clear;
  lIndex := 1;
  lInQuote := False;
  lValue := '';
  while lIndex <= Length(ALine) do
  begin
    if ALine[lIndex] = '"' then
    begin
      if lInQuote and (lIndex < Length(ALine)) and
        (ALine[lIndex + 1] = '"') then
      begin
        lValue := lValue + '"';
        Inc(lIndex);
      end
      else
        lInQuote := not lInQuote;
    end
    else if (ALine[lIndex] = ADelimiter) and not lInQuote then
    begin
      AValues.Add(lValue);
      lValue := '';
    end
    else
      lValue := lValue + ALine[lIndex];
    Inc(lIndex);
  end;
  if lInQuote then
    raise ENXDelimitedText.CreateFmt(
      'Malformed quoted field in %s at line %d.',
      [AFileName, ALineNumber]);
  AValues.Add(lValue);
end;

function LoadNXDelimitedData(const AFileName: string; ADelimiter: Char): TJSONObject;
var
  lLines: TStringList;
  lFields: TStringList;
  lValues: TStringList;
  lFieldNames: TStringList;
  lRoot: TJSONObject;
  lFieldArray: TJSONArray;
  lRecordArray: TJSONArray;
  lRecord: TJSONArray;
  lIndex: Integer;
  lLineIndex: Integer;
begin
  if not FileExists(AFileName) then
    raise ENXDelimitedText.CreateFmt(
      'External data source file not found: %s', [AFileName]);
  lLines := TStringList.Create;
  lFields := TStringList.Create;
  lValues := TStringList.Create;
  lFieldNames := TStringList.Create;
  lRoot := TJSONObject.Create;
  try
    lFieldNames.CaseSensitive := False;
    lFieldNames.Sorted := True;
    lFieldNames.Duplicates := dupError;
    lLines.LoadFromFile(AFileName);
    if lLines.Count = 0 then
      raise ENXDelimitedText.CreateFmt(
        'External data source file is empty: %s', [AFileName]);

    ParseDelimitedLine(AFileName, lLines[0], 1, ADelimiter, lFields);
    for lIndex := 0 to lFields.Count - 1 do
    begin
      if Trim(lFields[lIndex]) = '' then
        raise ENXDelimitedText.CreateFmt(
          'Blank field name in %s at column %d.',
          [AFileName, lIndex + 1]);
      if lFieldNames.IndexOf(lFields[lIndex]) >= 0 then
        raise ENXDelimitedText.CreateFmt(
          'Duplicate field name %s in %s.',
          [lFields[lIndex], AFileName]);
      lFieldNames.Add(lFields[lIndex]);
    end;

    lFieldArray := TJSONArray.Create;
    lRoot.Add('Fields', lFieldArray);
    for lIndex := 0 to lFields.Count - 1 do
      lFieldArray.Add(lFields[lIndex]);

    lRecordArray := TJSONArray.Create;
    lRoot.Add('Records', lRecordArray);
    for lLineIndex := 1 to lLines.Count - 1 do
    begin
      if Trim(lLines[lLineIndex]) = '' then
        Continue;
      ParseDelimitedLine(AFileName, lLines[lLineIndex],
        lLineIndex + 1, ADelimiter, lValues);
      if lValues.Count <> lFields.Count then
        raise ENXDelimitedText.CreateFmt(
          'Field count mismatch in %s at line %d: expected %d, found %d.',
          [AFileName, lLineIndex + 1, lFields.Count, lValues.Count]);
      lRecord := TJSONArray.Create;
      lRecordArray.Add(lRecord);
      for lIndex := 0 to lValues.Count - 1 do
        lRecord.Add(lValues[lIndex]);
    end;
    Result := lRoot;
    lRoot := nil;
  finally
    lRoot.Free;
    lFieldNames.Free;
    lValues.Free;
    lFields.Free;
    lLines.Free;
  end;
end;

end.

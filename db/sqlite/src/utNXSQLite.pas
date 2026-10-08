(*
  Copyright (c) 2026 Kevin Collins.
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)
unit utNXSQLite;

{$mode objfpc}{$H+}

interface

uses SysUtils, DB, SQLite3Dyn;

function QuoteSQLiteIdentifier(const AName: string): string;
function SQLiteColumnValue(AStatement: Psqlite3_stmt; AIndex: Integer): Variant;
function SQLiteDeclaredFieldType(const AType: string; out ASize: Integer): TFieldType;
function SQLiteVariantBytes(const AValue: Variant): TBytes;
function SQLiteBytesVariant(const ABytes: TBytes): Variant;
procedure SQLiteValueToBuffer(AField: TField; const AValue: Variant; ABuffer: Pointer);
function SQLiteBufferToValue(AField: TField; ABuffer: Pointer): Variant;
function SQLiteValuesEqual(const ALeft, ARight: Variant): Boolean;
function SQLiteFieldValuesEqual(AType: TFieldType; const ALeft, ARight: Variant): Boolean;
function CompareSQLiteText(const ALeft, ARight: UnicodeString): Integer;

implementation

uses Variants, DateUtils, FmtBCD;

function CompareSQLiteText(const ALeft, ARight: UnicodeString): Integer;
var
  lLeft, lRight: UTF8String;
  lLength: SizeInt;
begin
  lLeft := UTF8Encode(ALeft);
  lRight := UTF8Encode(ARight);
  lLength := Length(lLeft);
  if Length(lRight) < lLength then lLength := Length(lRight);
  Result := 0;
  if lLength > 0 then Result := CompareByte(lLeft[1], lRight[1], lLength);
  if Result <> 0 then Exit;
  if Length(lLeft) < Length(lRight) then Result := -1
  else if Length(lLeft) > Length(lRight) then Result := 1;
end;

function QuoteSQLiteIdentifier(const AName: string): string;
begin
  Result := '"' + StringReplace(AName, '"', '""', [rfReplaceAll]) + '"';
end;

function SQLiteBytesVariant(const ABytes: TBytes): Variant;
var
  lIndex: Integer;
begin
  Result := VarArrayCreate([0, Length(ABytes) - 1], varByte);
  for lIndex := 0 to High(ABytes) do Result[lIndex] := ABytes[lIndex];
end;

function SQLiteVariantBytes(const AValue: Variant): TBytes;
var
  lIndex, lLow: Integer;
begin
  Result := nil;
  if VarIsNull(AValue) or VarIsEmpty(AValue) then Exit;
  lLow := VarArrayLowBound(AValue, 1);
  SetLength(Result, VarArrayHighBound(AValue, 1) - lLow + 1);
  for lIndex := 0 to High(Result) do Result[lIndex] := AValue[lIndex + lLow];
end;

function SQLiteColumnValue(AStatement: Psqlite3_stmt; AIndex: Integer): Variant;
var
  lText: UTF8String;
  lBytes: TBytes;
  lLength: Integer;
begin
  case sqlite3_column_type(AStatement, AIndex) of
    SQLITE_NULL: Result := Null;
    SQLITE_INTEGER: Result := sqlite3_column_int64(AStatement, AIndex);
    SQLITE_FLOAT: Result := sqlite3_column_double(AStatement, AIndex);
    SQLITE_BLOB:
      begin
        lLength := sqlite3_column_bytes(AStatement, AIndex);
        SetLength(lBytes, lLength);
        if lLength > 0 then Move(sqlite3_column_blob(AStatement, AIndex)^, lBytes[0], lLength);
        Result := SQLiteBytesVariant(lBytes);
      end;
    else
      begin
        lLength := sqlite3_column_bytes(AStatement, AIndex);
        SetString(lText, PAnsiChar(sqlite3_column_text(AStatement, AIndex)), lLength);
        Result := UTF8Decode(lText);
      end;
  end;
end;

function SQLiteDeclaredFieldType(const AType: string; out ASize: Integer): TFieldType;
var
  lType: string;
  lStart, lEnd: Integer;
begin
  ASize := 0;
  lType := UpperCase(Trim(AType));
  if lType = '' then Exit(ftUnknown);
  if Pos('BOOL', lType) > 0 then Exit(ftBoolean);
  if Pos('INT', lType) > 0 then Exit(ftLargeint);
  if (Pos('DATETIME', lType) > 0) or (Pos('TIMESTAMP', lType) > 0) then Exit(ftDateTime);
  if lType = 'DATE' then Exit(ftDate);
  if lType = 'TIME' then Exit(ftTime);
  if (Pos('REAL', lType) > 0) or (Pos('FLOA', lType) > 0) or
    (Pos('DOUB', lType) > 0) then Exit(ftFloat);
  if Pos('BLOB', lType) > 0 then Exit(ftBlob);
  if (Pos('DECIMAL', lType) > 0) or (Pos('NUMERIC', lType) > 0) then Exit(ftFMTBcd);
  if (Pos('CHAR', lType) > 0) or (Pos('TEXT', lType) > 0) or
    (Pos('CLOB', lType) > 0) then
  begin
    lStart := Pos('(', lType);
    lEnd := Pos(')', lType);
    if (lStart > 0) and (lEnd > lStart) then
      ASize := StrToIntDef(Copy(lType, lStart + 1, lEnd - lStart - 1), 0);
    if ASize > 0 then Exit(ftWideString);
    Exit(ftWideMemo);
  end;
  Result := ftWideMemo;
end;

function SQLiteValuesEqual(const ALeft, ARight: Variant): Boolean;
var
  lLeftBytes, lRightBytes: TBytes;
begin
  if VarIsNull(ALeft) or VarIsNull(ARight) then
    Exit(VarIsNull(ALeft) and VarIsNull(ARight));
  if VarIsArray(ALeft) or VarIsArray(ARight) then
  begin
    if not (VarIsArray(ALeft) and VarIsArray(ARight)) then Exit(False);
    lLeftBytes := SQLiteVariantBytes(ALeft);
    lRightBytes := SQLiteVariantBytes(ARight);
    Result := Length(lLeftBytes) = Length(lRightBytes);
    if Result and (Length(lLeftBytes) > 0) then
      Result := CompareByte(lLeftBytes[0], lRightBytes[0], Length(lLeftBytes)) = 0;
  end
  else if VarIsStr(ALeft) and VarIsStr(ARight) then
    Result := VarToWideStr(ALeft) = VarToWideStr(ARight)
  else Result := VarCompareValue(ALeft, ARight) = vrEqual;
end;

function ValueDateTime(const AValue: Variant; AType: TFieldType): TDateTime;
var
  lText: string;
  lSettings: TFormatSettings;
begin
  if not VarIsStr(AValue) then Exit(TDateTime(AValue));
  lText := VarToStr(AValue);
  if AType = ftTime then
  begin
    lSettings := DefaultFormatSettings;
    lSettings.TimeSeparator := ':';
    Exit(StrToTime(lText, lSettings));
  end;
  if (Length(lText) > 10) and (lText[11] = ' ') then lText[11] := 'T';
  if Length(lText) = 10 then lText := lText + 'T00:00:00';
  Result := ISO8601ToDate(lText, True);
end;

function SQLiteFieldValuesEqual(AType: TFieldType; const ALeft, ARight: Variant): Boolean;
var
  lLeft, lRight: TDateTimeRec;
begin
  if not (AType in [ftDate, ftTime, ftDateTime]) or
    VarIsNull(ALeft) or VarIsNull(ARight) then
    Exit(SQLiteValuesEqual(ALeft, ARight));
  lLeft := DateTimeToDateTimeRec(AType, ValueDateTime(ALeft, AType));
  lRight := DateTimeToDateTimeRec(AType, ValueDateTime(ARight, AType));
  case AType of
    ftDate: Result := lLeft.Date = lRight.Date;
    ftTime: Result := lLeft.Time = lRight.Time;
    else Result := lLeft.DateTime = lRight.DateTime;
  end;
end;

procedure SQLiteValueToBuffer(AField: TField; const AValue: Variant; ABuffer: Pointer);
var
  lText: UTF8String;
  lWide: UnicodeString;
  lBytes: TBytes;
  lSettings: TFormatSettings;
begin
  if ABuffer = nil then Exit;
  case AField.DataType of
    ftString, ftFixedChar, ftGuid:
      begin
        lText := UTF8Encode(VarToWideStr(AValue));
        if Length(lText) >= AField.DataSize then
          DatabaseError('Text exceeds field size: ' + AField.FieldName);
        FillChar(ABuffer^, AField.DataSize, 0);
        if lText <> '' then Move(lText[1], ABuffer^, Length(lText));
      end;
    ftWideString, ftFixedWideChar:
      begin
        lWide := VarToWideStr(AValue);
        if Length(lWide) > AField.Size then
          DatabaseError('Text exceeds field size: ' + AField.FieldName);
        FillChar(ABuffer^, AField.DataSize, 0);
        if lWide <> '' then Move(lWide[1], ABuffer^, Length(lWide) * SizeOf(WideChar));
      end;
    ftSmallint: PSmallInt(ABuffer)^ := AValue;
    ftInteger, ftAutoInc: PLongInt(ABuffer)^ := AValue;
    ftWord: PWord(ABuffer)^ := AValue;
    ftLargeint: PInt64(ABuffer)^ := AValue;
    ftBoolean: PWordBool(ABuffer)^ := Boolean(AValue);
    ftFloat: PDouble(ABuffer)^ := AValue;
    ftCurrency, ftBCD: PCurrency(ABuffer)^ := AValue;
    ftFMTBcd:
      begin
        lSettings := DefaultFormatSettings;
        lSettings.DecimalSeparator := '.';
        TBcd(ABuffer^) := StrToBCD(VarToStr(AValue), lSettings);
      end;
    ftDate, ftTime, ftDateTime:
      PDateTimeRec(ABuffer)^ := DateTimeToDateTimeRec(AField.DataType,
        ValueDateTime(AValue, AField.DataType));
    ftBytes, ftVarBytes:
      begin
        lBytes := SQLiteVariantBytes(AValue);
        if Length(lBytes) > AField.Size then DatabaseError('Bytes exceed field size.');
        FillChar(ABuffer^, AField.DataSize, 0);
        if AField.DataType = ftVarBytes then
        begin
          PWord(ABuffer)^ := Length(lBytes);
          if Length(lBytes) > 0 then Move(lBytes[0], (PByte(ABuffer) + SizeOf(Word))^, Length(lBytes));
        end
        else if Length(lBytes) > 0 then Move(lBytes[0], ABuffer^, Length(lBytes));
      end;
    else DatabaseError('Unsupported scalar field: ' + AField.FieldName);
  end;
end;

function SQLiteBufferToValue(AField: TField; ABuffer: Pointer): Variant;
var
  lBytes: TBytes;
  lSettings: TFormatSettings;
begin
  if ABuffer = nil then Exit(Null);
  case AField.DataType of
    ftString, ftFixedChar, ftGuid: Result := UTF8Decode(PAnsiChar(ABuffer));
    ftWideString, ftFixedWideChar: Result := UnicodeString(PWideChar(ABuffer));
    ftSmallint: Result := PSmallInt(ABuffer)^;
    ftInteger, ftAutoInc: Result := PLongInt(ABuffer)^;
    ftWord: Result := PWord(ABuffer)^;
    ftLargeint: Result := PInt64(ABuffer)^;
    ftBoolean: Result := PWordBool(ABuffer)^;
    ftFloat: Result := PDouble(ABuffer)^;
    ftCurrency, ftBCD: Result := PCurrency(ABuffer)^;
    ftFMTBcd:
      begin
        lSettings := DefaultFormatSettings;
        lSettings.DecimalSeparator := '.';
        Result := BCDToStr(TBcd(ABuffer^), lSettings);
      end;
    ftDate, ftTime, ftDateTime:
      Result := VarFromDateTime(DateTimeRecToDateTime(AField.DataType, PDateTimeRec(ABuffer)^));
    ftBytes, ftVarBytes:
      begin
        if AField.DataType = ftVarBytes then
        begin
          SetLength(lBytes, PWord(ABuffer)^);
          if Length(lBytes) > 0 then Move((PByte(ABuffer) + SizeOf(Word))^, lBytes[0], Length(lBytes));
        end
        else
        begin
          SetLength(lBytes, AField.Size);
          if Length(lBytes) > 0 then Move(ABuffer^, lBytes[0], Length(lBytes));
        end;
        Result := SQLiteBytesVariant(lBytes);
      end;
    else DatabaseError('Unsupported scalar field: ' + AField.FieldName);
  end;
end;

end.

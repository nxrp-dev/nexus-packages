(*
  Copyright (c) 2026 Kevin Collins.
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)
unit obNXSQLiteConnection;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils, DB, SQLite3Dyn;

type
  ENXSQLiteError = class(EDatabaseError)
  private
    FErrorCode: Integer;
  public
    constructor CreateSQLite(AErrorCode: Integer; const AMessage: string);
    property ErrorCode: Integer read FErrorCode;
  end;

  TNXSQLiteConnection = class(TComponent)
  private
    FHandle: Psqlite3;
    FDatabaseName: string;
    FLibraryName: string;
    FReadOnly: Boolean;
    FBusyTimeout: Integer;
    FDataSets: TList;
    FSavepoint: QWord;
  protected
    function GetConnected: Boolean;
    function GetInTransaction: Boolean;
    procedure SetConnected(AValue: Boolean);
    procedure SetDatabaseName(const AValue: string);
    procedure SetLibraryName(const AValue: string);
    procedure SetReadOnly(AValue: Boolean);
    procedure SetBusyTimeout(AValue: Integer);
    procedure CheckInactive;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Open;
    procedure Close;
    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;
    procedure RegisterDataSet(ADataSet: TDataSet);
    procedure UnregisterDataSet(ADataSet: TDataSet);
    procedure CheckResult(AResult: Integer; const AOperation: string);
    function Prepare(const ASQL: string): Psqlite3_stmt;
    procedure BindValue(AStatement: Psqlite3_stmt; AIndex: Integer;
      ADataType: TFieldType; const AValue: Variant);
    procedure BindParams(AStatement: Psqlite3_stmt; AParams: TParams);
    function Execute(const ASQL: string; AParams: TParams = nil): Int64;
    function BeginSavepoint: string;
    procedure ReleaseSavepoint(const AName: string);
    procedure RollbackSavepoint(const AName: string);
    property Handle: Psqlite3 read FHandle;
    property InTransaction: Boolean read GetInTransaction;
  published
    property DatabaseName: string read FDatabaseName write SetDatabaseName;
    property LibraryName: string read FLibraryName write SetLibraryName;
    property Connected: Boolean read GetConnected write SetConnected default False;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
    property BusyTimeout: Integer read FBusyTimeout write SetBusyTimeout default 5000;
  end;

implementation

uses Variants;

constructor ENXSQLiteError.CreateSQLite(AErrorCode: Integer; const AMessage: string);
begin
  inherited Create(AMessage);
  FErrorCode := AErrorCode;
end;

constructor TNXSQLiteConnection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDataSets := TList.Create;
  FBusyTimeout := 5000;
end;

destructor TNXSQLiteConnection.Destroy;
begin
  Close;
  FDataSets.Free;
  inherited Destroy;
end;

function TNXSQLiteConnection.GetConnected: Boolean;
begin
  Result := FHandle <> nil;
end;

function TNXSQLiteConnection.GetInTransaction: Boolean;
begin
  Result := Connected and (sqlite3_get_autocommit(FHandle) = 0);
end;

procedure TNXSQLiteConnection.CheckInactive;
begin
  if Connected then DatabaseError('Close the SQLite connection first.', Self);
end;

procedure TNXSQLiteConnection.SetConnected(AValue: Boolean);
begin
  if AValue then Open else Close;
end;

procedure TNXSQLiteConnection.SetDatabaseName(const AValue: string);
begin
  CheckInactive;
  FDatabaseName := AValue;
end;

procedure TNXSQLiteConnection.SetLibraryName(const AValue: string);
begin
  CheckInactive;
  FLibraryName := AValue;
end;

procedure TNXSQLiteConnection.SetReadOnly(AValue: Boolean);
begin
  CheckInactive;
  FReadOnly := AValue;
end;

procedure TNXSQLiteConnection.SetBusyTimeout(AValue: Integer);
begin
  if AValue < 0 then DatabaseError('BusyTimeout must not be negative.', Self);
  if Connected then CheckResult(sqlite3_busy_timeout(FHandle, AValue), 'busy timeout');
  FBusyTimeout := AValue;
end;

procedure TNXSQLiteConnection.CheckResult(AResult: Integer; const AOperation: string);
var
  lCode: Integer;
  lMessage: string;
begin
  if AResult in [SQLITE_OK, SQLITE_ROW, SQLITE_DONE] then Exit;
  lCode := AResult;
  if FHandle <> nil then
  begin
    lCode := sqlite3_extended_errcode(FHandle);
    lMessage := string(sqlite3_errmsg(FHandle));
  end
  else lMessage := string(sqlite3_errstr(AResult));
  raise ENXSQLiteError.CreateSQLite(lCode, AOperation + ': ' + lMessage);
end;

procedure TNXSQLiteConnection.Open;
var
  lName: UTF8String;
  lFlags: Integer;
begin
  if Connected then Exit;
  if FDatabaseName = '' then DatabaseError('DatabaseName is required.', Self);
  if not AcquireSQLite3(FLibraryName) then DatabaseError(SQLite3LoadError, Self);
  try
    if not Assigned(sqlite3_bind_text) or not Assigned(sqlite3_bind_blob) or
      not Assigned(sqlite3_get_autocommit) or not Assigned(sqlite3_busy_timeout) or
      not Assigned(sqlite3_changes64) or not Assigned(sqlite3_extended_errcode) then
      DatabaseError('SQLite library is missing dataset exports.', Self);
    lName := UTF8Encode(FDatabaseName);
    if FReadOnly then lFlags := SQLITE_OPEN_READONLY
    else lFlags := SQLITE_OPEN_READWRITE or SQLITE_OPEN_CREATE;
    CheckResult(sqlite3_open_v2(PAnsiChar(lName), @FHandle, lFlags, nil), 'open database');
    CheckResult(sqlite3_busy_timeout(FHandle, FBusyTimeout), 'busy timeout');
    Execute('PRAGMA foreign_keys = ON');
  except
    if FHandle <> nil then sqlite3_close(FHandle);
    FHandle := nil;
    ReleaseSQLite3;
    raise;
  end;
end;

procedure TNXSQLiteConnection.Close;
var
  lIndex: Integer;
begin
  if not Connected then Exit;
  for lIndex := FDataSets.Count - 1 downto 0 do TDataSet(FDataSets[lIndex]).Close;
  CheckResult(sqlite3_close(FHandle), 'close database');
  FHandle := nil;
  ReleaseSQLite3;
end;

procedure TNXSQLiteConnection.RegisterDataSet(ADataSet: TDataSet);
begin
  if FDataSets.IndexOf(ADataSet) < 0 then FDataSets.Add(ADataSet);
end;

procedure TNXSQLiteConnection.UnregisterDataSet(ADataSet: TDataSet);
begin
  FDataSets.Remove(ADataSet);
end;

function TNXSQLiteConnection.Prepare(const ASQL: string): Psqlite3_stmt;
var
  lTail: PAnsiChar;
begin
  Open;
  Result := nil;
  try
    CheckResult(sqlite3_prepare_v3(FHandle, PAnsiChar(ASQL), Length(ASQL), 0,
      @Result, @lTail), 'prepare SQL');
    if Result = nil then DatabaseError('SQL statement is empty.', Self);
    if Trim(string(lTail)) <> '' then
      DatabaseError('Only one SQL statement is allowed per operation.', Self);
  except
    if Result <> nil then sqlite3_finalize(Result);
    raise;
  end;
end;

procedure TNXSQLiteConnection.BindValue(AStatement: Psqlite3_stmt; AIndex: Integer;
  ADataType: TFieldType; const AValue: Variant);
var
  lBytes: RawByteString;
  lText: UTF8String;
  lIndex, lLow, lResult: Integer;
begin
  if VarIsNull(AValue) or VarIsEmpty(AValue) then
    lResult := sqlite3_bind_null(AStatement, AIndex)
  else case ADataType of
    ftSmallint, ftInteger, ftWord, ftAutoInc, ftLargeint:
      lResult := sqlite3_bind_int64(AStatement, AIndex, Int64(AValue));
    ftBoolean: lResult := sqlite3_bind_int64(AStatement, AIndex, Ord(Boolean(AValue)));
    ftFloat: lResult := sqlite3_bind_double(AStatement, AIndex, Double(AValue));
    ftBlob, ftBytes, ftVarBytes, ftGraphic, ftTypedBinary:
      begin
        if VarIsArray(AValue) then
        begin
          lLow := VarArrayLowBound(AValue, 1);
          SetLength(lBytes, VarArrayHighBound(AValue, 1) - lLow + 1);
          for lIndex := 1 to Length(lBytes) do
            lBytes[lIndex] := AnsiChar(Byte(AValue[lLow + lIndex - 1]));
        end
        else lBytes := RawByteString(VarToStr(AValue));
        if lBytes = '' then lResult := sqlite3_bind_zeroblob(AStatement, AIndex, 0)
        else lResult := sqlite3_bind_blob(AStatement, AIndex, PAnsiChar(lBytes),
          Length(lBytes), sqlite3_destructor_type(SQLITE_TRANSIENT));
      end;
    else
      begin
        case ADataType of
          ftDate, ftTime, ftDateTime:
            begin
              if VarIsStr(AValue) then lText := UTF8Encode(VarToWideStr(AValue))
              else case ADataType of
                ftDate: lText := UTF8Encode(FormatDateTime('yyyy-mm-dd', TDateTime(AValue)));
                ftTime: lText := UTF8Encode(FormatDateTime('hh:nn:ss.zzz', TDateTime(AValue)));
                ftDateTime: lText := UTF8Encode(FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', TDateTime(AValue)));
              end;
            end;
          ftCurrency, ftBCD, ftFMTBcd:
            lText := UTF8Encode(StringReplace(VarToStr(AValue),
              DefaultFormatSettings.DecimalSeparator, '.', []));
          else lText := UTF8Encode(VarToWideStr(AValue));
        end;
        lResult := sqlite3_bind_text(AStatement, AIndex, PAnsiChar(lText),
          Length(lText), sqlite3_destructor_type(SQLITE_TRANSIENT));
      end;
  end;
  CheckResult(lResult, 'bind parameter');
end;

procedure TNXSQLiteConnection.BindParams(AStatement: Psqlite3_stmt; AParams: TParams);
var
  lIndex: Integer;
  lName: string;
  lParam: TParam;
begin
  for lIndex := 1 to sqlite3_bind_parameter_count(AStatement) do
  begin
    lName := string(sqlite3_bind_parameter_name(AStatement, lIndex));
    if lName = '' then DatabaseError('Use named SQL parameters.', Self);
    Delete(lName, 1, 1);
    if AParams = nil then DatabaseError('SQL parameters are required.', Self);
    lParam := AParams.ParamByName(lName);
    if not lParam.Bound then DatabaseError('Parameter is not bound: ' + lName, Self);
    BindValue(AStatement, lIndex, lParam.DataType, lParam.Value);
  end;
end;

function TNXSQLiteConnection.Execute(const ASQL: string; AParams: TParams): Int64;
var
  lStatement: Psqlite3_stmt;
  lChanges: Int64;
begin
  lStatement := Prepare(ASQL);
  try
    if sqlite3_column_count(lStatement) <> 0 then
      DatabaseError('Use a dataset to read SQL results.', Self);
    BindParams(lStatement, AParams);
    lChanges := sqlite3_total_changes64(FHandle);
    CheckResult(sqlite3_step(lStatement), 'execute SQL');
    if sqlite3_total_changes64(FHandle) = lChanges then Result := 0
    else Result := sqlite3_changes64(FHandle);
  finally
    sqlite3_finalize(lStatement);
  end;
end;

procedure TNXSQLiteConnection.StartTransaction;
begin
  Open;
  if InTransaction then DatabaseError('SQLite transaction is already active.', Self);
  Execute('BEGIN');
end;

procedure TNXSQLiteConnection.Commit;
var
  lIndex: Integer;
begin
  if not InTransaction then DatabaseError('No active SQLite transaction.', Self);
  for lIndex := 0 to FDataSets.Count - 1 do
    if TDataSet(FDataSets[lIndex]).Active then TDataSet(FDataSets[lIndex]).CheckBrowseMode;
  Execute('COMMIT');
end;

procedure TNXSQLiteConnection.Rollback;
var
  lIndex: Integer;
begin
  if not InTransaction then DatabaseError('No active SQLite transaction.', Self);
  for lIndex := 0 to FDataSets.Count - 1 do
    if TDataSet(FDataSets[lIndex]).State in [dsEdit, dsInsert] then
      TDataSet(FDataSets[lIndex]).Cancel;
  Execute('ROLLBACK');
  for lIndex := 0 to FDataSets.Count - 1 do
    if TDataSet(FDataSets[lIndex]).Active then TDataSet(FDataSets[lIndex]).Refresh;
end;

function TNXSQLiteConnection.BeginSavepoint: string;
begin
  Inc(FSavepoint);
  Result := 'nx_dataset_' + UIntToStr(FSavepoint);
  Execute('SAVEPOINT ' + Result);
end;

procedure TNXSQLiteConnection.ReleaseSavepoint(const AName: string);
begin
  Execute('RELEASE ' + AName);
end;

procedure TNXSQLiteConnection.RollbackSavepoint(const AName: string);
begin
  Execute('ROLLBACK TO ' + AName);
  Execute('RELEASE ' + AName);
end;

end.

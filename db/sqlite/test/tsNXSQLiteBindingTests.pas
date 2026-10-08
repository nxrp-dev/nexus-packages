(*
  Copyright (c) 2026 Kevin Collins.
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)
unit tsNXSQLiteBindingTests;

{$mode objfpc}{$H+}

interface

uses obNXTestRegistry;

procedure RegisterNXSQLiteBindingTests(ARegistry: TNXTestRegistry);

implementation

uses ctypes, SysUtils, SQLite3Dyn, obNXSQLiteConnection,
  obNXTestContext, obNXTestSuite;

type
  PCallbackState = ^TCallbackState;
  TCallbackState = record
    Rows: Integer;
    Values: string;
    AbortRows: Boolean;
    FunctionCalls: Integer;
    FunctionDestructions: Integer;
    Commits: Integer;
    Rollbacks: Integer;
    Updates: Integer;
    LastOperation: Integer;
    LastRowId: Int64;
    VetoCommit: Boolean;
    ProgressCalls: Integer;
    Columns: Integer;
    Phrases: Integer;
    Instances: Integer;
    QueryRows: Integer;
    Tokens: Integer;
    TokenOffsets: string;
    ColumnText: string;
    QueryToken: string;
    AuxDataMatched: Boolean;
    AuxDataDestructions: Integer;
    FtsDestructions: Integer;
    FtsResultCode: Integer;
  end;

function OpenConnection: TNXSQLiteConnection;
begin
  Result := TNXSQLiteConnection.Create(nil);
  try
    Result.LibraryName := ExpandFileName(ExtractFilePath(ParamStr(0)) +
      '../runtime/win64/sqlite3.dll');
    Result.DatabaseName := ':memory:';
    Result.Open;
  except
    Result.Free;
    raise;
  end;
end;

function CaptureRow(AUserData: Pointer; AColumnCount: cint;
  AColumnValues, AColumnNames: PPAnsiChar): cint; cdecl;
var
  lState: PCallbackState;
  lValues, lNames: PPAnsiChar;
  lColumn: Integer;
begin
  lState := AUserData;
  Inc(lState^.Rows);
  lValues := AColumnValues;
  lNames := AColumnNames;
  for lColumn := 0 to AColumnCount - 1 do
  begin
    if lState^.Values <> '' then lState^.Values := lState^.Values + ';';
    lState^.Values := lState^.Values + lNames^ + '=';
    if lValues^ = nil then
      lState^.Values := lState^.Values + '<NULL>'
    else
      lState^.Values := lState^.Values + lValues^;
    Inc(lValues);
    Inc(lNames);
  end;
  Result := Ord(lState^.AbortRows);
end;

procedure TestExecAndTablePointers(AContext: TNXTestContext);
var
  lConnection: TNXSQLiteConnection;
  lState: TCallbackState;
  lCallback: sqlite3_callback;
  lError: PAnsiChar;
  lTable, lCell: PPAnsiChar;
  lRows, lColumns: cint;
begin
  lState := Default(TCallbackState);
  lCallback := @CaptureRow;
  lConnection := OpenConnection;
  try
    lError := nil;
    try
      AContext.AssertEquals(SQLITE_OK, sqlite3_exec(lConnection.Handle,
        'SELECT 42 AS number, NULL AS missing, ''word'' AS label',
        lCallback, @lState, @lError));
      AContext.AssertTrue(lError = nil);
      AContext.AssertEquals(1, lState.Rows);
      AContext.AssertEquals('number=42;missing=<NULL>;label=word', lState.Values);
      lState.AbortRows := True;
      AContext.AssertEquals(SQLITE_ABORT, sqlite3_exec(lConnection.Handle,
        'SELECT 1 UNION ALL SELECT 2', lCallback, @lState, @lError));
      AContext.AssertEquals(2, lState.Rows);
      AContext.AssertTrue(lError <> nil);
    finally
      sqlite3_free(lError);
    end;
    lError := nil;
    lTable := nil;
    try
      AContext.AssertEquals(SQLITE_OK, sqlite3_get_table(lConnection.Handle,
        'SELECT 7 AS number, NULL AS missing', @lTable, @lRows, @lColumns, @lError));
      AContext.AssertEquals(1, lRows);
      AContext.AssertEquals(2, lColumns);
      lCell := lTable;
      AContext.AssertEquals('number', string(lCell^));
      Inc(lCell);
      AContext.AssertEquals('missing', string(lCell^));
      Inc(lCell);
      AContext.AssertEquals('7', string(lCell^));
      Inc(lCell);
      AContext.AssertTrue(lCell^ = nil);
    finally
      sqlite3_free_table(lTable);
      sqlite3_free(lError);
    end;
  finally
    lConnection.Free;
  end;
end;

procedure ScalarValue(AContext: Psqlite3_context; AArgumentCount: cint;
  AArguments: PPsqlite3_value); cdecl;
var
  lState: PCallbackState;
begin
  lState := sqlite3_user_data(AContext);
  Inc(lState^.FunctionCalls);
  if AArgumentCount = 1 then
    sqlite3_result_int64(AContext, sqlite3_value_int64(AArguments^) + 10)
  else
    sqlite3_result_error(AContext, 'Expected one argument', -1);
end;

procedure AggregateStep(AContext: Psqlite3_context; AArgumentCount: cint;
  AArguments: PPsqlite3_value); cdecl;
var
  lSum: Psqlite3_int64;
begin
  lSum := sqlite3_aggregate_context(AContext, SizeOf(sqlite3_int64));
  if (lSum <> nil) and (AArgumentCount = 1) then
    lSum^ := lSum^ + sqlite3_value_int64(AArguments^);
end;

procedure AggregateFinal(AContext: Psqlite3_context); cdecl;
var
  lSum: Psqlite3_int64;
begin
  lSum := sqlite3_aggregate_context(AContext, 0);
  if lSum = nil then sqlite3_result_int64(AContext, 0)
  else sqlite3_result_int64(AContext, lSum^);
end;

procedure WindowValue(AContext: Psqlite3_context); cdecl;
begin
  AggregateFinal(AContext);
end;

procedure WindowInverse(AContext: Psqlite3_context; AArgumentCount: cint;
  AArguments: PPsqlite3_value); cdecl;
var
  lSum: Psqlite3_int64;
begin
  lSum := sqlite3_aggregate_context(AContext, 0);
  if (lSum <> nil) and (AArgumentCount = 1) then
    lSum^ := lSum^ - sqlite3_value_int64(AArguments^);
end;

procedure DestroyFunction(AUserData: Pointer); cdecl;
var
  lState: PCallbackState;
begin
  lState := AUserData;
  Inc(lState^.FunctionDestructions);
end;

procedure TestFunctionCallbackRoles(AContext: TNXTestContext);
var
  lConnection: TNXSQLiteConnection;
  lState: TCallbackState;
  lScalar: TSQLite3ScalarFunctionCallback;
  lStep: TSQLite3AggregateStepCallback;
  lFinal: TSQLite3AggregateFinalCallback;
  lValue: TSQLite3WindowValueCallback;
  lInverse: TSQLite3WindowInverseCallback;
  lDestructor: TSQLite3FunctionDestroyCallback;
begin
  lState := Default(TCallbackState);
  lScalar := @ScalarValue;
  lStep := @AggregateStep;
  lFinal := @AggregateFinal;
  lValue := @WindowValue;
  lInverse := @WindowInverse;
  lDestructor := @DestroyFunction;
  lConnection := OpenConnection;
  try
    AContext.AssertEquals(SQLITE_OK, sqlite3_create_function_v2(lConnection.Handle,
      'nx_scalar', 1, SQLITE_UTF8, @lState, lScalar, nil, nil, lDestructor));
    AContext.AssertEquals(SQLITE_OK, sqlite3_create_function_v2(lConnection.Handle,
      'nx_sum', 1, SQLITE_UTF8, @lState, nil, lStep, lFinal, lDestructor));
    AContext.AssertEquals(SQLITE_OK, sqlite3_create_window_function(lConnection.Handle,
      'nx_window', 1, SQLITE_UTF8, @lState, lStep, lFinal, lValue, lInverse, lDestructor));
    lConnection.Execute('CREATE TABLE numbers(n)');
    lConnection.Execute('INSERT INTO numbers VALUES (1),(2),(3)');
    AContext.AssertEquals(SQLITE_OK, sqlite3_exec(lConnection.Handle,
      'SELECT nx_scalar(5) AS scalar, nx_sum(n) AS total FROM numbers',
      @CaptureRow, @lState, nil));
    AContext.AssertEquals('scalar=15;total=6', lState.Values);
    AContext.AssertEquals(1, lState.FunctionCalls);
    lState.Values := '';
    AContext.AssertEquals(SQLITE_OK, sqlite3_exec(lConnection.Handle,
      'SELECT nx_window(n) OVER (ORDER BY n ROWS BETWEEN ' +
      '1 PRECEDING AND CURRENT ROW) AS total FROM numbers', @CaptureRow, @lState, nil));
    AContext.AssertEquals('total=1;total=3;total=5', lState.Values);
    AContext.AssertEquals(0, lState.FunctionDestructions);
    lConnection.Close;
    AContext.AssertEquals(3, lState.FunctionDestructions);
  finally
    lConnection.Free;
  end;
end;

function CommitTransaction(AUserData: Pointer): cint; cdecl;
var
  lState: PCallbackState;
begin
  lState := AUserData;
  Inc(lState^.Commits);
  Result := Ord(lState^.VetoCommit);
end;

procedure RollbackTransaction(AUserData: Pointer); cdecl;
var
  lState: PCallbackState;
begin
  lState := AUserData;
  Inc(lState^.Rollbacks);
end;

procedure UpdateRow(AUserData: Pointer; AOperation: cint;
  ASchemaName, ATableName: PAnsiChar; ARowId: Int64); cdecl;
var
  lState: PCallbackState;
begin
  lState := AUserData;
  Inc(lState^.Updates);
  lState^.LastOperation := AOperation;
  lState^.LastRowId := ARowId;
end;

function CancelProgress(AUserData: Pointer): cint; cdecl;
var
  lState: PCallbackState;
begin
  lState := AUserData;
  Inc(lState^.ProgressCalls);
  Result := 1;
end;

procedure TestHookCallbackRoles(AContext: TNXTestContext);
var
  lConnection: TNXSQLiteConnection;
  lState: TCallbackState;
  lError: PAnsiChar;
begin
  lState := Default(TCallbackState);
  lConnection := OpenConnection;
  try
    lConnection.Execute('CREATE TABLE entries(id INTEGER PRIMARY KEY)');
    sqlite3_commit_hook(lConnection.Handle, @CommitTransaction, @lState);
    sqlite3_rollback_hook(lConnection.Handle, @RollbackTransaction, @lState);
    sqlite3_update_hook(lConnection.Handle, @UpdateRow, @lState);
    lState.VetoCommit := True;
    lError := nil;
    try
      AContext.AssertEquals(SQLITE_CONSTRAINT, sqlite3_exec(lConnection.Handle,
        'BEGIN; INSERT INTO entries VALUES(11); COMMIT', nil, nil, @lError));
    finally
      sqlite3_free(lError);
    end;
    AContext.AssertEquals(1, lState.Commits);
    AContext.AssertEquals(1, lState.Rollbacks);
    AContext.AssertEquals(SQLITE_OK, sqlite3_exec(lConnection.Handle,
      'SELECT COUNT(*) AS count FROM entries', @CaptureRow, @lState, nil));
    AContext.AssertEquals('count=0', lState.Values);
    lState.VetoCommit := False;
    lConnection.Execute('INSERT INTO entries VALUES(22)');
    AContext.AssertEquals(2, lState.Commits);
    AContext.AssertEquals(2, lState.Updates);
    AContext.AssertEquals(SQLITE_INSERT, lState.LastOperation);
    AContext.AssertTrue(lState.LastRowId = 22);
    sqlite3_progress_handler(lConnection.Handle, 1, @CancelProgress, @lState);
    lError := nil;
    try
      AContext.AssertEquals(SQLITE_INTERRUPT, sqlite3_exec(lConnection.Handle,
        'WITH RECURSIVE n(x) AS (VALUES(1) UNION ALL SELECT x+1 FROM n WHERE x<10000) ' +
        'SELECT SUM(x) FROM n', nil, nil, @lError));
      AContext.AssertTrue(lState.ProgressCalls > 0);
    finally
      sqlite3_progress_handler(lConnection.Handle, 0, nil, nil);
      sqlite3_free(lError);
    end;
  finally
    lConnection.Free;
  end;
end;

function CaptureToken(AUserData: Pointer; AFlags: cint; AToken: PAnsiChar;
  ATokenByteCount, AStartByteOffset, AEndByteOffset: cint): cint; cdecl;
var
  lState: PCallbackState;
begin
  lState := AUserData;
  Inc(lState^.Tokens);
  if lState^.TokenOffsets <> '' then lState^.TokenOffsets := lState^.TokenOffsets + ';';
  lState^.TokenOffsets := lState^.TokenOffsets + IntToStr(AStartByteOffset) + ':' +
    IntToStr(AEndByteOffset);
  Result := SQLITE_OK;
end;

function QueryPhraseRow(AExtensionApi: PFts5ExtensionApi; AContext: PFts5Context;
  AUserData: Pointer): cint; cdecl;
var
  lState: PCallbackState;
begin
  lState := AUserData;
  Inc(lState^.QueryRows);
  Result := SQLITE_OK;
end;

procedure DestroyFtsAuxData(AAuxData: Pointer); cdecl;
var
  lState: PCallbackState;
begin
  lState := AAuxData;
  Inc(lState^.AuxDataDestructions);
end;

procedure DestroyFtsFunction(AUserData: Pointer); cdecl;
var
  lState: PCallbackState;
begin
  lState := AUserData;
  Inc(lState^.FtsDestructions);
end;

procedure FtsDetails(AExtensionApi: PFts5ExtensionApi; AContext: PFts5Context;
  AResultContext: Psqlite3_context; AArgumentCount: cint;
  AArguments: PPsqlite3_value); cdecl;
var
  lState: PCallbackState;
  lText: PAnsiChar;
  lByteCount: cint;
begin
  lState := AExtensionApi^.xUserData(AContext);
  lState^.Columns := AExtensionApi^.xColumnCount(AContext);
  lState^.Phrases := AExtensionApi^.xPhraseCount(AContext);
  lState^.FtsResultCode := AExtensionApi^.xInstCount(AContext, @lState^.Instances);
  if lState^.FtsResultCode = SQLITE_OK then
  begin
    lState^.FtsResultCode := AExtensionApi^.xColumnText(AContext, 0, @lText, @lByteCount);
    if lState^.FtsResultCode = SQLITE_OK then SetString(lState^.ColumnText, lText, lByteCount);
  end;
  if lState^.FtsResultCode = SQLITE_OK then
  begin
    lState^.FtsResultCode := AExtensionApi^.xQueryToken(AContext, 0, 0, @lText, @lByteCount);
    if lState^.FtsResultCode = SQLITE_OK then SetString(lState^.QueryToken, lText, lByteCount);
  end;
  if lState^.FtsResultCode = SQLITE_OK then
    lState^.FtsResultCode := AExtensionApi^.xTokenize(AContext, 'blue sky', 8,
      lState, @CaptureToken);
  if lState^.FtsResultCode = SQLITE_OK then
    lState^.FtsResultCode := AExtensionApi^.xQueryPhrase(AContext, 0, lState, @QueryPhraseRow);
  if lState^.FtsResultCode = SQLITE_OK then
  begin
    lState^.FtsResultCode := AExtensionApi^.xSetAuxdata(AContext, lState, @DestroyFtsAuxData);
    lState^.AuxDataMatched := AExtensionApi^.xGetAuxdata(AContext, 0) = lState;
  end;
  if lState^.FtsResultCode = SQLITE_OK then sqlite3_result_int(AResultContext, lState^.Instances)
  else sqlite3_result_error_code(AResultContext, lState^.FtsResultCode);
end;

procedure TestFtsCallbackRoles(AContext: TNXTestContext);
var
  lConnection: TNXSQLiteConnection;
  lState: TCallbackState;
  lApi: Pfts5_api;
  lStatement: Psqlite3_stmt;
  lExtension: fts5_extension_function;
begin
  lState := Default(TCallbackState);
  lApi := nil;
  lStatement := nil;
  lExtension := @FtsDetails;
  lConnection := OpenConnection;
  try
    AContext.AssertEquals(SQLITE_OK, sqlite3_prepare_v2(lConnection.Handle,
      'SELECT fts5(?1)', -1, @lStatement, nil));
    try
      AContext.AssertEquals(SQLITE_OK, sqlite3_bind_pointer(lStatement, 1,
        @lApi, 'fts5_api_ptr', nil));
      AContext.AssertEquals(SQLITE_ROW, sqlite3_step(lStatement));
    finally
      sqlite3_finalize(lStatement);
    end;
    AContext.AssertTrue(lApi <> nil);
    AContext.AssertEquals(SQLITE_OK, lApi^.xCreateFunction(lApi, 'nx_details',
      @lState, lExtension, @DestroyFtsFunction));
    lConnection.Execute('CREATE VIRTUAL TABLE documents USING fts5(title,body)');
    lConnection.Execute('INSERT INTO documents VALUES(''blue sky'',''blue blue'')');
    AContext.AssertEquals(SQLITE_OK, sqlite3_exec(lConnection.Handle,
      'SELECT nx_details(documents) AS instances FROM documents ' +
      'WHERE documents MATCH ''blue''', @CaptureRow, @lState, nil));
    AContext.AssertEquals(SQLITE_OK, lState.FtsResultCode);
    AContext.AssertEquals(2, lState.Columns);
    AContext.AssertEquals(1, lState.Phrases);
    AContext.AssertEquals(3, lState.Instances);
    AContext.AssertEquals('instances=3', lState.Values);
    AContext.AssertEquals('blue sky', lState.ColumnText);
    AContext.AssertEquals('blue', lState.QueryToken);
    AContext.AssertEquals(2, lState.Tokens);
    AContext.AssertEquals('0:4;5:8', lState.TokenOffsets);
    AContext.AssertEquals(1, lState.QueryRows);
    AContext.AssertTrue(lState.AuxDataMatched);
    AContext.AssertEquals(1, lState.AuxDataDestructions);
    AContext.AssertEquals(0, lState.FtsDestructions);
    lConnection.Close;
    AContext.AssertEquals(1, lState.FtsDestructions);
  finally
    lConnection.Free;
  end;
end;

procedure RegisterNXSQLiteBindingTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('Foundation.SQLite.Binding');
  lSuite.AddTest('ExecAndTablePointers', @TestExecAndTablePointers);
  lSuite.AddTest('FunctionCallbackRoles', @TestFunctionCallbackRoles);
  lSuite.AddTest('HookCallbackRoles', @TestHookCallbackRoles);
  lSuite.AddTest('FtsCallbackRoles', @TestFtsCallbackRoles);
end;

end.

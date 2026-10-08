(*
  Copyright (c) 2026 Kevin Collins.
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)
unit obNXSQLiteDataSet;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils, DB, FGL, SQLite3Dyn, tpNXSQLite,
  obNXSQLiteConnection, obNXSQLiteRow;

type
  TNXSQLiteDataSet = class;

  TNXSQLiteBlobField = class(TBlobField)
  protected
    function GetAsVariant: Variant; override;
    procedure SetVarValue(const AValue: Variant); override;
  public
    procedure Clear; override;
  end;

  TNXSQLiteMemoField = class(TWideMemoField)
  public
    procedure Clear; override;
  end;

  TNXSQLiteBlobStream = class(TMemoryStream)
  private
    FDataSet: TNXSQLiteDataSet;
    FField: TField;
    FMode: TBlobStreamMode;
    FSerial: QWord;
  protected
    procedure CheckWritable;
  public
    constructor Create(ADataSet: TNXSQLiteDataSet; AField: TField;
      AMode: TBlobStreamMode);
    destructor Destroy; override;
    function Write(const ABuffer; ACount: Longint): Longint; override;
    procedure SetSize(const ASize: Int64); override;
    procedure Detach;
  end;

  TNXSQLiteRows = specialize TFPGObjectList<TNXSQLiteRow>;

  TNXSQLiteDataSet = class(TDataSet)
  private
    FConnection: TNXSQLiteConnection;
    FSQL: TStringList;
    FParams: TParams;
    FInsertSQL: TStringList;
    FUpdateSQL: TStringList;
    FDeleteSQL: TStringList;
    FRows: TNXSQLiteRows;
    FColumns: array of TNXSQLiteColumn;
    FView: array of Integer;
    FKeys: array of Integer;
    FCursor: Integer;
    FOpen: Boolean;
    FReadOnly: Boolean;
    FWritable: Boolean;
    FNextID: QWord;
    FEditSerial: QWord;
    FStreams: TList;
    FOriginal: TNXSQLiteRow;
    FFilterBuffer: TRecordBuffer;
    FFilterStatement: Psqlite3_stmt;
    FUpdateTableName: string;
    FUpdateDatabaseName: string;
    FTableName: string;
    FDatabaseName: string;
    FTableKeyCount: Integer;
    FKeyFields: string;
    FIndexFieldNames: string;
    FIndexDefs: TIndexDefs;
    FMasterLink: TMasterParamsDataLink;
    FRowsAffected: Int64;
    procedure SQLChanging(ASender: TObject);
    procedure SQLChanged(ASender: TObject);
    procedure MasterDisabled(ASender: TObject);
    function CreateExecutionParams: TParams;
    procedure ReadColumns(AStatement: Psqlite3_stmt);
    procedure ReadTableInfo;
    procedure ResolveKeys;
    procedure InferFieldTypes;
    procedure ValidateRows(ARows: TNXSQLiteRows);
    function LoadRows: TNXSQLiteRows;
    procedure ReplaceRows(ARows: TNXSQLiteRows; ATarget: TNXSQLiteRow);
    procedure BuildView;
    procedure PrepareFilter;
    function AcceptRow(ARow: TNXSQLiteRow): Boolean;
    function EvaluateRow(ARow: TNXSQLiteRow): Boolean;
    function CompareRows(ALeft, ARight: TNXSQLiteRow): Integer;
    procedure SortView(ALeft, ARight: Integer);
    function FindRowID(AID: QWord): Integer;
    function FindKey(ARows: TNXSQLiteRows; ARow: TNXSQLiteRow): Integer;
    function SameKey(ALeft, ARight: TNXSQLiteRow): Boolean;
    function RowsHaveUniqueKeys(ARows: TNXSQLiteRows): Boolean;
    function CurrentBuffer: TRecordBuffer;
    function CurrentRow: TNXSQLiteRow;
    procedure CheckStreams;
    procedure DetachStreams;
    procedure SetBlobValue(AField: TField; const AValue: Variant);
    function BuildWriteSQL(AKind: TUpdateKind; ARow: TNXSQLiteRow): string;
    procedure BindWriteParams(AStatement: Psqlite3_stmt; ARow, AOld: TNXSQLiteRow);
    procedure WriteRow(AKind: TUpdateKind);
    function MatchRow(ARow: TNXSQLiteRow; const AKeyFields: string;
      const AKeyValues: Variant; AOptions: TLocateOptions): Boolean;
    function SearchRow(const AKeyFields: string; const AKeyValues: Variant;
      AOptions: TLocateOptions): Integer;
    function QualifiedTable: string;
  protected
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
    procedure DataConvert(AField: TField; ASource, ADest: Pointer;
      AToNative: Boolean); override;
    procedure SetConnection(AValue: TNXSQLiteConnection);
    procedure SetSQL(AValue: TStrings);
    procedure SetParams(AValue: TParams);
    procedure SetInsertSQL(AValue: TStrings);
    procedure SetUpdateSQL(AValue: TStrings);
    procedure SetDeleteSQL(AValue: TStrings);
    function GetSQL: TStrings;
    function GetInsertSQL: TStrings;
    function GetUpdateSQL: TStrings;
    function GetDeleteSQL: TStrings;
    procedure SetReadOnly(AValue: Boolean);
    procedure SetUpdateTableName(const AValue: string);
    procedure SetUpdateDatabaseName(const AValue: string);
    procedure SetKeyFields(const AValue: string);
    procedure SetIndexFieldNames(const AValue: string);
    procedure SetMasterSource(AValue: TDataSource);
    function GetMasterSource: TDataSource;
    function GetDataSource: TDataSource; override;
    function AllocRecordBuffer: TRecordBuffer; override;
    procedure FreeRecordBuffer(var ABuffer: TRecordBuffer); override;
    function GetRecordSize: Word; override;
    procedure ClearCalcFields(ABuffer: TRecordBuffer); override;
    procedure InternalInitRecord(ABuffer: TRecordBuffer); override;
    procedure InternalInitFieldDefs; override;
    procedure InternalOpen; override;
    procedure InternalClose; override;
    function IsCursorOpen: Boolean; override;
    function GetRecord(ABuffer: TRecordBuffer; AGetMode: TGetMode;
      ADoCheck: Boolean): TGetResult; override;
    procedure InternalFirst; override;
    procedure InternalLast; override;
    procedure InternalSetToRecord(ABuffer: TRecordBuffer); override;
    procedure InternalGotoBookmark(ABookmark: Pointer); override;
    procedure GetBookmarkData(ABuffer: TRecordBuffer; AData: Pointer); override;
    procedure SetBookmarkData(ABuffer: TRecordBuffer; AData: Pointer); override;
    function GetBookmarkFlag(ABuffer: TRecordBuffer): TBookmarkFlag; override;
    procedure SetBookmarkFlag(ABuffer: TRecordBuffer; AValue: TBookmarkFlag); override;
    function GetRecNo: Longint; override;
    procedure SetRecNo(AValue: Longint); override;
    function GetRecordCount: Longint; override;
    function GetCanModify: Boolean; override;
    function GetIsIndexField(AField: TField): Boolean; override;
    function GetFieldClass(AFieldType: TFieldType): TFieldClass; override;
    procedure InternalEdit; override;
    procedure InternalInsert; override;
    procedure InternalCancel; override;
    procedure InternalPost; override;
    procedure InternalDelete; override;
    procedure InternalAddRecord(ABuffer: Pointer; AAppend: Boolean); override;
    procedure InternalRefresh; override;
    procedure SetFiltered(AValue: Boolean); override;
    procedure SetFilterText(const AValue: string); override;
    procedure SetFilterOptions(AValue: TFilterOptions); override;
    procedure SetOnFilterRecord(const AValue: TFilterRecordEvent); override;
    function FindRecord(ARestart, AGoForward: Boolean): Boolean; override;
    procedure UpdateIndexDefs; override;
    procedure PSGetAttributes(AList: TList); override;
    function PSGetCommandType: TPSCommandType; override;
    function PSGetDefaultOrder: TIndexDef; override;
    function PSGetIndexDefs(AIndexTypes: TIndexOptions): TIndexDefs; override;
    function PSUpdateRecord(AUpdateKind: TUpdateKind; ADelta: TDataSet): Boolean; override;
    procedure PSStartTransaction; override;
    procedure PSEndTransaction(ACommit: Boolean); override;
    function PSInTransaction: Boolean; override;
    function PSIsSQLBased: Boolean; override;
    function PSIsSQLSupported: Boolean; override;
    function PSGetCommandText: string; override;
    function PSGetParams: TParams; override;
    function PSGetTableName: string; override;
    function PSGetKeyFields: string; override;
    function PSGetQuoteChar: string; override;
    procedure PSSetCommandText(const ACommandText: string); override;
    procedure PSSetParams(AParams: TParams); override;
    procedure PSExecute; override;
    function PSExecuteStatement(const ASQL: string; AParams: TParams;
      AResultSet: Pointer = nil): Integer; override;
    procedure PSReset; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetFieldData(AField: TField; ABuffer: Pointer): Boolean; override;
    function GetCurrentRecord(ABuffer: TRecordBuffer): Boolean; override;
    function GetFieldData(AField: TField; ABuffer: Pointer; ANativeFormat: Boolean): Boolean; override;
    procedure SetFieldData(AField: TField; ABuffer: Pointer); override;
    procedure SetFieldData(AField: TField; ABuffer: Pointer; ANativeFormat: Boolean); override;
    function BookmarkValid(ABookmark: TBookmark): Boolean; override;
    function CompareBookmarks(ABookmark1, ABookmark2: TBookmark): Longint; override;
    function FindFirst: Boolean; override;
    function FindLast: Boolean; override;
    function FindNext: Boolean; override;
    function FindPrior: Boolean; override;
    function Locate(const AKeyFields: string; const AKeyValues: Variant;
      AOptions: TLocateOptions): Boolean; override;
    function Lookup(const AKeyFields: string; const AKeyValues: Variant;
      const AResultFields: string): Variant; override;
    function CreateBlobStream(AField: TField; AMode: TBlobStreamMode): TStream; override;
    function UpdateStatus: TUpdateStatus; override;
    function ParamByName(const AName: string): TParam;
    procedure ExecSQL;
    property RowsAffected: Int64 read FRowsAffected;
    property IndexDefs: TIndexDefs read FIndexDefs;
  published
    property Connection: TNXSQLiteConnection read FConnection write SetConnection;
    property SQL: TStrings read GetSQL write SetSQL;
    property Params: TParams read FParams write SetParams;
    property InsertSQL: TStrings read GetInsertSQL write SetInsertSQL;
    property UpdateSQL: TStrings read GetUpdateSQL write SetUpdateSQL;
    property DeleteSQL: TStrings read GetDeleteSQL write SetDeleteSQL;
    property UpdateTableName: string read FUpdateTableName write SetUpdateTableName;
    property UpdateDatabaseName: string read FUpdateDatabaseName write SetUpdateDatabaseName;
    property KeyFields: string read FKeyFields write SetKeyFields;
    property IndexFieldNames: string read FIndexFieldNames write SetIndexFieldNames;
    property MasterSource: TDataSource read GetMasterSource write SetMasterSource;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
    property Active;
    property FieldDefs;
    property AutoCalcFields;
    property Filter;
    property Filtered;
    property FilterOptions;
    property BeforeOpen;
    property AfterOpen;
    property BeforeClose;
    property AfterClose;
    property BeforeInsert;
    property AfterInsert;
    property BeforeEdit;
    property AfterEdit;
    property BeforePost;
    property AfterPost;
    property BeforeCancel;
    property AfterCancel;
    property BeforeDelete;
    property AfterDelete;
    property BeforeScroll;
    property AfterScroll;
    property BeforeRefresh;
    property AfterRefresh;
    property OnCalcFields;
    property OnFilterRecord;
    property OnNewRecord;
    property OnEditError;
    property OnPostError;
    property OnDeleteError;
  end;

implementation

uses Variants, StrUtils, utNXSQLite;

type
  TNXSQLiteRecordBuffer = record
    Row: TNXSQLiteRow;
    Bookmark: TNXSQLiteBookmark;
    Flag: TBookmarkFlag;
  end;
  PNXSQLiteRecordBuffer = ^TNXSQLiteRecordBuffer;

constructor TNXSQLiteDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSQL := TStringList.Create;
  FSQL.OnChanging := @SQLChanging;
  FSQL.OnChange := @SQLChanged;
  FParams := TParams.Create(Self);
  FInsertSQL := TStringList.Create;
  FUpdateSQL := TStringList.Create;
  FDeleteSQL := TStringList.Create;
  FInsertSQL.OnChanging := @SQLChanging;
  FUpdateSQL.OnChanging := @SQLChanging;
  FDeleteSQL.OnChanging := @SQLChanging;
  FRows := TNXSQLiteRows.Create(True);
  FStreams := TList.Create;
  FIndexDefs := TIndexDefs.Create(Self);
  FMasterLink := TMasterParamsDataLink.Create(Self);
  FMasterLink.Params := FParams;
  FMasterLink.OnMasterDisable := @MasterDisabled;
  FCursor := -1;
  BookmarkSize := SizeOf(TNXSQLiteBookmark);
end;

destructor TNXSQLiteDataSet.Destroy;
begin
  Close;
  SetConnection(nil);
  FMasterLink.Free;
  FIndexDefs.Free;
  FStreams.Free;
  FRows.Free;
  FDeleteSQL.Free;
  FUpdateSQL.Free;
  FInsertSQL.Free;
  FParams.Free;
  FSQL.Free;
  inherited Destroy;
end;

procedure TNXSQLiteDataSet.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited Notification(AComponent, AOperation);
  if (AOperation = opRemove) and (AComponent = FConnection) then
  begin
    Close;
    FConnection := nil;
  end;
end;

procedure TNXSQLiteDataSet.SetConnection(AValue: TNXSQLiteConnection);
begin
  if AValue = FConnection then Exit;
  CheckInactive;
  if FConnection <> nil then
  begin
    FConnection.UnregisterDataSet(Self);
    FConnection.RemoveFreeNotification(Self);
  end;
  FConnection := AValue;
  if FConnection <> nil then
  begin
    FConnection.RegisterDataSet(Self);
    FConnection.FreeNotification(Self);
  end;
end;

procedure TNXSQLiteDataSet.SQLChanging(ASender: TObject);
begin
  CheckInactive;
end;

procedure TNXSQLiteDataSet.SQLChanged(ASender: TObject);
var
  lOldParams: TParams;
begin
  FieldDefs.Clear;
  lOldParams := TParams.Create;
  try
    lOldParams.Assign(FParams);
    FParams.ParseSQL(FSQL.Text, True);
    FParams.AssignValues(lOldParams);
    FMasterLink.RefreshParamNames;
  finally
    lOldParams.Free;
  end;
end;

function TNXSQLiteDataSet.GetSQL: TStrings;
begin
  Result := FSQL;
end;

function TNXSQLiteDataSet.GetInsertSQL: TStrings;
begin
  Result := FInsertSQL;
end;

function TNXSQLiteDataSet.GetUpdateSQL: TStrings;
begin
  Result := FUpdateSQL;
end;

function TNXSQLiteDataSet.GetDeleteSQL: TStrings;
begin
  Result := FDeleteSQL;
end;

procedure TNXSQLiteDataSet.SetSQL(AValue: TStrings);
begin
  FSQL.Assign(AValue);
end;

procedure TNXSQLiteDataSet.SetParams(AValue: TParams);
begin
  CheckInactive;
  FParams.Assign(AValue);
end;

procedure TNXSQLiteDataSet.SetInsertSQL(AValue: TStrings);
begin
  FInsertSQL.Assign(AValue);
end;

procedure TNXSQLiteDataSet.SetUpdateSQL(AValue: TStrings);
begin
  FUpdateSQL.Assign(AValue);
end;

procedure TNXSQLiteDataSet.SetDeleteSQL(AValue: TStrings);
begin
  FDeleteSQL.Assign(AValue);
end;

procedure TNXSQLiteDataSet.SetReadOnly(AValue: Boolean);
begin
  CheckInactive;
  FReadOnly := AValue;
end;

procedure TNXSQLiteDataSet.SetUpdateTableName(const AValue: string);
begin
  CheckInactive;
  FUpdateTableName := AValue;
end;

procedure TNXSQLiteDataSet.SetUpdateDatabaseName(const AValue: string);
begin
  CheckInactive;
  FUpdateDatabaseName := AValue;
end;

procedure TNXSQLiteDataSet.SetKeyFields(const AValue: string);
begin
  CheckInactive;
  FKeyFields := AValue;
end;

procedure TNXSQLiteDataSet.SetMasterSource(AValue: TDataSource);
begin
  if AValue = FMasterLink.DataSource then Exit;
  CheckInactive;
  if (AValue <> nil) and ((AValue.DataSet = Self) or IsLinkedTo(AValue)) then
    DatabaseError('Circular master/detail link.', Self);
  FMasterLink.DataSource := AValue;
end;

function TNXSQLiteDataSet.GetMasterSource: TDataSource;
begin
  Result := FMasterLink.DataSource;
end;

function TNXSQLiteDataSet.GetDataSource: TDataSource;
begin
  Result := MasterSource;
end;

procedure TNXSQLiteDataSet.MasterDisabled(ASender: TObject);
begin
  Close;
end;

function TNXSQLiteDataSet.ParamByName(const AName: string): TParam;
begin
  Result := FParams.ParamByName(AName);
end;

procedure TNXSQLiteDataSet.ExecSQL;
var
  lParams: TParams;
begin
  CheckInactive;
  if FConnection = nil then DatabaseError('Connection is required.', Self);
  lParams := CreateExecutionParams;
  try
    FRowsAffected := FConnection.Execute(FSQL.Text, lParams);
  finally
    lParams.Free;
  end;
end;

function TNXSQLiteDataSet.CreateExecutionParams: TParams;
var
  lIndex: Integer;
begin
  FMasterLink.CopyParamsFromMaster(False);
  Result := TParams.Create(Self);
  try
    Result.Assign(FParams);
    if FMasterLink.Active then
      for lIndex := 0 to Result.Count - 1 do
        if not Result[lIndex].Bound and
          (FMasterLink.DataSet.FindField(Result[lIndex].Name) <> nil) then
          Result[lIndex].Bound := True;
  except
    Result.Free;
    raise;
  end;
end;

procedure TNXSQLiteDataSet.ReadColumns(AStatement: Psqlite3_stmt);
var
  lIndex, lDefIndex: Integer;
  lField: TField;
  lDef: TFieldDef;
begin
  SetLength(FColumns, sqlite3_column_count(AStatement));
  if Length(FColumns) = 0 then DatabaseError('Open requires a result-producing query.', Self);
  FTableName := FUpdateTableName;
  FDatabaseName := FUpdateDatabaseName;
  for lIndex := 0 to High(FColumns) do
  begin
    FColumns[lIndex] := Default(TNXSQLiteColumn);
    FColumns[lIndex].Name := string(sqlite3_column_name(AStatement, lIndex));
    FColumns[lIndex].DeclaredType := string(sqlite3_column_decltype(AStatement, lIndex));
    if Assigned(sqlite3_column_origin_name) and Assigned(sqlite3_column_table_name) and
      Assigned(sqlite3_column_database_name) then
    begin
      FColumns[lIndex].OriginName := string(sqlite3_column_origin_name(AStatement, lIndex));
      FColumns[lIndex].TableName := string(sqlite3_column_table_name(AStatement, lIndex));
      FColumns[lIndex].DatabaseName := string(sqlite3_column_database_name(AStatement, lIndex));
    end;
    if FUpdateTableName <> '' then
    begin
      if FColumns[lIndex].OriginName = '' then
        FColumns[lIndex].OriginName := FColumns[lIndex].Name;
    end
    else if (FTableName = '') and (FColumns[lIndex].TableName <> '') then
      FTableName := FColumns[lIndex].TableName;
    if (FDatabaseName = '') and (FColumns[lIndex].DatabaseName <> '') then
      FDatabaseName := FColumns[lIndex].DatabaseName;
    FColumns[lIndex].Generated := FColumns[lIndex].OriginName = '';
    FColumns[lIndex].DataType := SQLiteDeclaredFieldType(
      FColumns[lIndex].DeclaredType, FColumns[lIndex].Size);
    lDef := nil;
    for lDefIndex := 0 to FieldDefs.Count - 1 do
      if SameText(FieldDefs[lDefIndex].Name, FColumns[lIndex].Name) then
        lDef := FieldDefs[lDefIndex];
    if lDef <> nil then
    begin
      FColumns[lIndex].DataType := lDef.DataType;
      FColumns[lIndex].Size := lDef.Size;
    end;
    lField := FindField(FColumns[lIndex].Name);
    if (lField <> nil) and (lField.FieldKind = fkData) then
    begin
      FColumns[lIndex].DataType := lField.DataType;
      FColumns[lIndex].Size := lField.Size;
    end;
    FColumns[lIndex].PrimaryKey := 0;
  end;
  if FDatabaseName = '' then FDatabaseName := 'main';
end;

function TNXSQLiteDataSet.QualifiedTable: string;
begin
  Result := QuoteSQLiteIdentifier(FDatabaseName) + '.' + QuoteSQLiteIdentifier(FTableName);
end;

procedure TNXSQLiteDataSet.ReadTableInfo;
var
  lStatement: Psqlite3_stmt;
  lIndex, lResult: Integer;
  lName: string;
begin
  FTableKeyCount := 0;
  if FTableName = '' then Exit;
  lStatement := FConnection.Prepare('PRAGMA ' + QuoteSQLiteIdentifier(FDatabaseName) +
    '.table_xinfo(' + QuoteSQLiteIdentifier(FTableName) + ')');
  try
    repeat
      lResult := sqlite3_step(lStatement);
      FConnection.CheckResult(lResult, 'read table metadata');
      if lResult <> SQLITE_ROW then Break;
      lName := string(PAnsiChar(sqlite3_column_text(lStatement, 1)));
      if sqlite3_column_int(lStatement, 5) > 0 then Inc(FTableKeyCount);
      for lIndex := 0 to High(FColumns) do
        if SameText(FColumns[lIndex].OriginName, lName) then
        begin
          FColumns[lIndex].PrimaryKey := sqlite3_column_int(lStatement, 5);
          FColumns[lIndex].Generated := sqlite3_column_int(lStatement, 6) <> 0;
        end;
    until False;
  finally
    sqlite3_finalize(lStatement);
  end;
end;

procedure TNXSQLiteDataSet.ResolveKeys;
var
  lIndex, lOrdinal: Integer;
  lNames: TStringList;
  lName: string;
  lUsableKeys: Boolean;
begin
  SetLength(FKeys, 0);
  lNames := TStringList.Create;
  try
    if FKeyFields <> '' then
    begin
      ExtractStrings([';'], [], PChar(FKeyFields), lNames);
      for lOrdinal := 0 to lNames.Count - 1 do
      begin
        lName := Trim(lNames[lOrdinal]);
        lIndex := 0;
        while (lIndex < Length(FColumns)) and not SameText(FColumns[lIndex].Name, lName) do Inc(lIndex);
        if lIndex = Length(FColumns) then DatabaseError('Unknown key field: ' + lName, Self);
        SetLength(FKeys, Length(FKeys) + 1);
        FKeys[High(FKeys)] := lIndex;
      end;
    end
    else
    begin
      lOrdinal := 1;
      repeat
        lIndex := 0;
        while (lIndex < Length(FColumns)) and (FColumns[lIndex].PrimaryKey <> lOrdinal) do Inc(lIndex);
        if lIndex = Length(FColumns) then Break;
        SetLength(FKeys, Length(FKeys) + 1);
        FKeys[High(FKeys)] := lIndex;
        Inc(lOrdinal);
      until False;
    end;
  finally
    lNames.Free;
  end;
  lUsableKeys := Length(FKeys) <> 0;
  if FKeyFields = '' then lUsableKeys := lUsableKeys and (Length(FKeys) = FTableKeyCount);
  lUsableKeys := lUsableKeys and RowsHaveUniqueKeys(FRows);
  if not lUsableKeys then SetLength(FKeys, 0);
  FWritable := (FTableName <> '') and lUsableKeys;
  for lIndex := 0 to High(FColumns) do
    if (FUpdateTableName = '') and (FColumns[lIndex].TableName <> '') and
      (not SameText(FColumns[lIndex].TableName, FTableName) or
       not SameText(FColumns[lIndex].DatabaseName, FDatabaseName)) then FWritable := False;
end;

function TNXSQLiteDataSet.LoadRows: TNXSQLiteRows;
var
  lStatement: Psqlite3_stmt;
  lParams: TParams;
  lRow: TNXSQLiteRow;
  lIndex, lResult: Integer;
begin
  Result := TNXSQLiteRows.Create(True);
  lStatement := nil;
  lParams := nil;
  try
    try
      lStatement := FConnection.Prepare(FSQL.Text);
      if sqlite3_stmt_readonly(lStatement) = 0 then
        DatabaseError('Open requires a read-only SELECT; use ExecSQL for writes.', Self);
      lParams := CreateExecutionParams;
      FConnection.BindParams(lStatement, lParams);
      if not FOpen then ReadColumns(lStatement)
      else
      begin
        if sqlite3_column_count(lStatement) <> Length(FColumns) then
          DatabaseError('Query field layout changed; close and reopen the dataset.', Self);
        for lIndex := 0 to High(FColumns) do
          if string(sqlite3_column_name(lStatement, lIndex)) <> FColumns[lIndex].Name then
            DatabaseError('Query field layout changed; close and reopen the dataset.', Self);
      end;
      repeat
        lResult := sqlite3_step(lStatement);
        FConnection.CheckResult(lResult, 'read query');
        if lResult <> SQLITE_ROW then Break;
        lRow := TNXSQLiteRow.Create(Length(FColumns));
        Result.Add(lRow);
        Inc(FNextID);
        lRow.ID := FNextID;
        for lIndex := 0 to High(FColumns) do lRow[lIndex] := SQLiteColumnValue(lStatement, lIndex);
      until False;
    except
      Result.Free;
      raise;
    end;
  finally
    if lStatement <> nil then sqlite3_finalize(lStatement);
    lParams.Free;
  end;
end;

procedure TNXSQLiteDataSet.InferFieldTypes;
var
  lColumn, lRow: Integer;
  lValue: Variant;
  lType, lValueType: TFieldType;
begin
  for lColumn := 0 to High(FColumns) do
    if FColumns[lColumn].DataType = ftUnknown then
    begin
      lType := ftUnknown;
      for lRow := 0 to FRows.Count - 1 do
      begin
        lValue := FRows[lRow][lColumn];
        if VarIsNull(lValue) then Continue;
        if VarIsArray(lValue) then lValueType := ftBlob
        else case VarType(lValue) of
          varSmallint, varInteger, varInt64: lValueType := ftLargeint;
          varDouble, varSingle: lValueType := ftFloat;
          else lValueType := ftWideMemo;
        end;
        if lType = ftUnknown then lType := lValueType
        else if lType <> lValueType then
        begin
          if (lType in [ftLargeint, ftFloat]) and (lValueType in [ftLargeint, ftFloat]) then
            lType := ftFloat
          else DatabaseError('Mixed SQLite types require a persistent field: ' + FColumns[lColumn].Name, Self);
        end;
      end;
      if lType = ftUnknown then lType := ftWideMemo;
      FColumns[lColumn].DataType := lType;
    end;
end;

procedure TNXSQLiteDataSet.InternalInitFieldDefs;
var
  lRows: TNXSQLiteRows;
  lIndex: Integer;
begin
  if FConnection = nil then DatabaseError('Connection is required.', Self);
  if not FOpen then
  begin
    lRows := LoadRows;
    FRows.Free;
    FRows := lRows;
    InferFieldTypes;
    ReadTableInfo;
    ResolveKeys;
  end;
  FieldDefs.Clear;
  for lIndex := 0 to High(FColumns) do
    FieldDefs.Add(FColumns[lIndex].Name, FColumns[lIndex].DataType, FColumns[lIndex].Size, False);
end;

procedure TNXSQLiteDataSet.InternalOpen;
var
  lIndex: Integer;
  lField: TField;
begin
  InternalInitFieldDefs;
  if DefaultFields then CreateFields;
  BindFields(True);
  for lIndex := 0 to High(FColumns) do
  begin
    lField := FieldByNumber(lIndex + 1);
    if lField <> nil then
    begin
      if FColumns[lIndex].Generated then lField.ReadOnly := True;
      if FColumns[lIndex].PrimaryKey > 0 then
        lField.ProviderFlags := lField.ProviderFlags + [pfInKey];
    end;
  end;
  FOpen := True;
  try
    PrepareFilter;
    ValidateRows(FRows);
    BuildView;
    FCursor := -1;
    UpdateIndexDefs;
  except
    InternalClose;
    raise;
  end;
end;

procedure TNXSQLiteDataSet.InternalClose;
begin
  DetachStreams;
  FreeAndNil(FOriginal);
  if FFilterStatement <> nil then sqlite3_finalize(FFilterStatement);
  FFilterStatement := nil;
  FFilterBuffer := nil;
  BindFields(False);
  if DefaultFields then DestroyFields;
  FRows.Clear;
  SetLength(FView, 0);
  FOpen := False;
  FWritable := False;
  FCursor := -1;
  Inc(FEditSerial);
end;

function TNXSQLiteDataSet.IsCursorOpen: Boolean;
begin
  Result := FOpen;
end;

function TNXSQLiteDataSet.AllocRecordBuffer: TRecordBuffer;
begin
  Result := AllocMem(SizeOf(TNXSQLiteRecordBuffer) + CalcFieldsSize);
  PNXSQLiteRecordBuffer(Result)^.Row := TNXSQLiteRow.Create(Length(FColumns));
end;

procedure TNXSQLiteDataSet.FreeRecordBuffer(var ABuffer: TRecordBuffer);
begin
  if ABuffer = nil then Exit;
  PNXSQLiteRecordBuffer(ABuffer)^.Row.Free;
  FreeMem(ABuffer);
  ABuffer := nil;
end;

function TNXSQLiteDataSet.GetRecordSize: Word;
begin
  Result := SizeOf(TNXSQLiteRecordBuffer);
end;

procedure TNXSQLiteDataSet.ClearCalcFields(ABuffer: TRecordBuffer);
begin
  if CalcFieldsSize > 0 then FillChar((ABuffer + GetRecordSize)^, CalcFieldsSize, 0);
end;

procedure TNXSQLiteDataSet.InternalInitRecord(ABuffer: TRecordBuffer);
begin
  PNXSQLiteRecordBuffer(ABuffer)^.Row.Clear;
  PNXSQLiteRecordBuffer(ABuffer)^.Bookmark.DataSet := Self;
  PNXSQLiteRecordBuffer(ABuffer)^.Bookmark.RowID := 0;
  PNXSQLiteRecordBuffer(ABuffer)^.Flag := bfInserted;
  ClearCalcFields(ABuffer);
end;

function TNXSQLiteDataSet.GetRecord(ABuffer: TRecordBuffer; AGetMode: TGetMode;
  ADoCheck: Boolean): TGetResult;
var
  lCursor: Integer;
begin
  lCursor := FCursor;
  case AGetMode of
    gmNext: Inc(lCursor);
    gmPrior: Dec(lCursor);
  end;
  if lCursor < 0 then Exit(grBOF);
  if lCursor >= Length(FView) then Exit(grEOF);
  FCursor := lCursor;
  PNXSQLiteRecordBuffer(ABuffer)^.Row.Assign(FRows[FView[FCursor]]);
  PNXSQLiteRecordBuffer(ABuffer)^.Bookmark.DataSet := Self;
  PNXSQLiteRecordBuffer(ABuffer)^.Bookmark.RowID := FRows[FView[FCursor]].ID;
  PNXSQLiteRecordBuffer(ABuffer)^.Flag := bfCurrent;
  GetCalcFields(ABuffer);
  Result := grOK;
end;

procedure TNXSQLiteDataSet.InternalFirst;
begin
  FCursor := -1;
end;

procedure TNXSQLiteDataSet.InternalLast;
begin
  FCursor := Length(FView);
end;

function TNXSQLiteDataSet.FindRowID(AID: QWord): Integer;
var
  lIndex: Integer;
begin
  for lIndex := 0 to High(FView) do
    if FRows[FView[lIndex]].ID = AID then Exit(lIndex);
  Result := -1;
end;

procedure TNXSQLiteDataSet.InternalSetToRecord(ABuffer: TRecordBuffer);
var
  lCursor: Integer;
begin
  lCursor := FindRowID(PNXSQLiteRecordBuffer(ABuffer)^.Bookmark.RowID);
  if lCursor >= 0 then FCursor := lCursor;
end;

procedure TNXSQLiteDataSet.InternalGotoBookmark(ABookmark: Pointer);
begin
  if not BookmarkValid(ABookmark) then DatabaseError('Invalid SQLite bookmark.', Self);
  FCursor := FindRowID(PNXSQLiteBookmark(ABookmark)^.RowID);
end;

procedure TNXSQLiteDataSet.GetBookmarkData(ABuffer: TRecordBuffer; AData: Pointer);
begin
  PNXSQLiteBookmark(AData)^ := PNXSQLiteRecordBuffer(ABuffer)^.Bookmark;
end;

procedure TNXSQLiteDataSet.SetBookmarkData(ABuffer: TRecordBuffer; AData: Pointer);
begin
  PNXSQLiteRecordBuffer(ABuffer)^.Bookmark := PNXSQLiteBookmark(AData)^;
end;

function TNXSQLiteDataSet.GetBookmarkFlag(ABuffer: TRecordBuffer): TBookmarkFlag;
begin
  Result := PNXSQLiteRecordBuffer(ABuffer)^.Flag;
end;

procedure TNXSQLiteDataSet.SetBookmarkFlag(ABuffer: TRecordBuffer; AValue: TBookmarkFlag);
begin
  PNXSQLiteRecordBuffer(ABuffer)^.Flag := AValue;
end;

function TNXSQLiteDataSet.BookmarkValid(ABookmark: TBookmark): Boolean;
begin
  Result := Active and (ABookmark <> nil) and
    (PNXSQLiteBookmark(ABookmark)^.DataSet = Pointer(Self)) and
    (FindRowID(PNXSQLiteBookmark(ABookmark)^.RowID) >= 0);
end;

function TNXSQLiteDataSet.CompareBookmarks(ABookmark1, ABookmark2: TBookmark): Longint;
var
  lLeft, lRight: Integer;
begin
  if not BookmarkValid(ABookmark1) or not BookmarkValid(ABookmark2) then
    DatabaseError('Invalid SQLite bookmark.', Self);
  lLeft := FindRowID(PNXSQLiteBookmark(ABookmark1)^.RowID);
  lRight := FindRowID(PNXSQLiteBookmark(ABookmark2)^.RowID);
  if lLeft < lRight then Result := -1
  else if lLeft > lRight then Result := 1
  else Result := 0;
end;

function TNXSQLiteDataSet.GetRecNo: Longint;
begin
  if not Active or IsEmpty then Exit(0);
  if State = dsInsert then Exit(Length(FView) + 1);
  Result := FindRowID(PNXSQLiteRecordBuffer(ActiveBuffer)^.Bookmark.RowID) + 1;
end;

procedure TNXSQLiteDataSet.SetRecNo(AValue: Longint);
begin
  CheckBrowseMode;
  if (AValue < 1) or (AValue > Length(FView)) then DatabaseError('RecNo is outside the dataset.', Self);
  DoBeforeScroll;
  FCursor := AValue - 1;
  Resync([]);
  DoAfterScroll;
end;

function TNXSQLiteDataSet.GetRecordCount: Longint;
begin
  Result := Length(FView);
end;

function TNXSQLiteDataSet.GetCanModify: Boolean;
begin
  Result := FOpen and FWritable and not FReadOnly and
    (FConnection <> nil) and not FConnection.ReadOnly;
end;

function TNXSQLiteDataSet.GetIsIndexField(AField: TField): Boolean;
var
  lOrder: TIndexDef;
  lNames: TStringList;
  lIndex: Integer;
begin
  Result := False;
  if not Active then Exit;
  lOrder := PSGetDefaultOrder;
  if lOrder = nil then Exit;
  lNames := TStringList.Create;
  try
    ExtractStrings([';'], [], PChar(lOrder.Fields), lNames);
    for lIndex := 0 to lNames.Count - 1 do
      if SameText(lNames[lIndex], AField.FieldName) then Exit(True);
  finally
    lNames.Free;
  end;
end;

function TNXSQLiteDataSet.CurrentBuffer: TRecordBuffer;
begin
  case State of
    dsFilter: Result := FFilterBuffer;
    dsCalcFields: Result := CalcBuffer;
    else Result := ActiveBuffer;
  end;
end;

function TNXSQLiteDataSet.CurrentRow: TNXSQLiteRow;
var
  lBuffer: TRecordBuffer;
begin
  if (State = dsBrowse) and IsEmpty then Exit(nil);
  if State = dsOldValue then Exit(FOriginal);
  lBuffer := CurrentBuffer;
  if lBuffer = nil then Exit(nil);
  Result := PNXSQLiteRecordBuffer(lBuffer)^.Row;
end;

function TNXSQLiteDataSet.GetFieldData(AField: TField; ABuffer: Pointer): Boolean;
var
  lRow: TNXSQLiteRow;
  lBuffer: TRecordBuffer;
  lValue: Variant;
begin
  Result := False;
  if AField.FieldNo > 0 then
  begin
    lRow := CurrentRow;
    if lRow = nil then Exit;
    lValue := lRow[AField.FieldNo - 1];
    if VarIsNull(lValue) or VarIsEmpty(lValue) then Exit;
    if not AField.IsBlob then SQLiteValueToBuffer(AField, lValue, ABuffer)
    else if (ABuffer <> nil) and (AField.DataSize > 0) then FillChar(ABuffer^, AField.DataSize, 0);
    Result := True;
  end
  else
  begin
    lBuffer := CurrentBuffer;
    if lBuffer = nil then Exit;
    Inc(lBuffer, GetRecordSize + AField.Offset);
    Result := Boolean(lBuffer^);
    if Result and (ABuffer <> nil) then Move((lBuffer + 1)^, ABuffer^, AField.DataSize);
  end;
end;

procedure TNXSQLiteDataSet.DataConvert(AField: TField; ASource, ADest: Pointer;
  AToNative: Boolean);
begin
  if AField.DataType in [ftDate, ftTime, ftDateTime] then
    inherited DataConvert(AField, ASource, ADest, AToNative)
  else if AField.DataSize > 0 then
    Move(ASource^, ADest^, AField.DataSize);
end;

function TNXSQLiteDataSet.GetFieldData(AField: TField; ABuffer: Pointer;
  ANativeFormat: Boolean): Boolean;
begin
  if ABuffer = nil then Result := GetFieldData(AField, ABuffer)
  else Result := inherited GetFieldData(AField, ABuffer, ANativeFormat);
end;

procedure TNXSQLiteDataSet.SetFieldData(AField: TField; ABuffer: Pointer);
var
  lRow: TNXSQLiteRow;
  lBuffer: TRecordBuffer;
begin
  if not (State in dsWriteModes) then DatabaseError('Dataset is not editing.', Self);
  if (AField.FieldKind = fkData) and AField.ReadOnly then
    DatabaseError('Field is read-only: ' + AField.FieldName, Self);
  if State in [dsEdit, dsInsert, dsNewValue] then AField.Validate(ABuffer);
  if AField.FieldNo > 0 then
  begin
    lRow := CurrentRow;
    if AField.IsBlob then
    begin
      if ABuffer <> nil then DatabaseError('Use CreateBlobStream to write blob fields.', Self);
      lRow[AField.FieldNo - 1] := Null;
    end
    else lRow[AField.FieldNo - 1] := SQLiteBufferToValue(AField, ABuffer);
  end
  else
  begin
    lBuffer := CurrentBuffer + GetRecordSize + AField.Offset;
    Boolean(lBuffer^) := ABuffer <> nil;
    if ABuffer <> nil then Move(ABuffer^, (lBuffer + 1)^, AField.DataSize);
  end;
  if not (State in [dsCalcFields, dsFilter, dsNewValue]) then
    DataEvent(deFieldChange, PtrInt(AField));
end;

procedure TNXSQLiteDataSet.SetFieldData(AField: TField; ABuffer: Pointer;
  ANativeFormat: Boolean);
begin
  if ABuffer = nil then SetFieldData(AField, ABuffer)
  else inherited SetFieldData(AField, ABuffer, ANativeFormat);
end;

function TNXSQLiteDataSet.GetFieldClass(AFieldType: TFieldType): TFieldClass;
begin
  case AFieldType of
    ftBlob: Result := TNXSQLiteBlobField;
    ftWideMemo: Result := TNXSQLiteMemoField;
    else Result := inherited GetFieldClass(AFieldType);
  end;
end;

procedure TNXSQLiteDataSet.CheckStreams;
var
  lIndex: Integer;
begin
  for lIndex := 0 to FStreams.Count - 1 do
    if TNXSQLiteBlobStream(FStreams[lIndex]).FMode <> bmRead then
      DatabaseError('Close writable blob streams before posting or refreshing.', Self);
end;

procedure TNXSQLiteDataSet.DetachStreams;
var
  lIndex: Integer;
begin
  for lIndex := 0 to FStreams.Count - 1 do TNXSQLiteBlobStream(FStreams[lIndex]).Detach;
  FStreams.Clear;
end;

procedure TNXSQLiteDataSet.InternalEdit;
begin
  CheckStreams;
  FreeAndNil(FOriginal);
  FOriginal := TNXSQLiteRow.Create(Length(FColumns));
  FOriginal.Assign(CurrentRow);
  Inc(FEditSerial);
end;

procedure TNXSQLiteDataSet.InternalInsert;
begin
  CheckStreams;
  FreeAndNil(FOriginal);
  Inc(FEditSerial);
end;

procedure TNXSQLiteDataSet.InternalCancel;
begin
  DetachStreams;
  FreeAndNil(FOriginal);
  Inc(FEditSerial);
end;

function TNXSQLiteDataSet.UpdateStatus: TUpdateStatus;
begin
  // Posts are written through; there is no pending update cache.
  Result := usUnmodified;
end;

procedure TNXSQLiteDataSet.PrepareFilter;
var
  lSQL: string;
  lIndex: Integer;
  lStatement: Psqlite3_stmt;
begin
  lStatement := nil;
  if Filter <> '' then
  begin
    lSQL := 'SELECT CASE WHEN (' + Filter + ') THEN 1 ELSE 0 END FROM (SELECT ';
    for lIndex := 0 to High(FColumns) do
    begin
      if lIndex > 0 then lSQL := lSQL + ', ';
      lSQL := lSQL + '?' + IntToStr(lIndex + 1);
      if foCaseInsensitive in FilterOptions then lSQL := lSQL + ' COLLATE NOCASE';
      lSQL := lSQL + ' AS ' + QuoteSQLiteIdentifier(FColumns[lIndex].Name);
    end;
    lSQL := lSQL + ')';
    lStatement := FConnection.Prepare(lSQL);
    if (sqlite3_stmt_readonly(lStatement) = 0) or
      (sqlite3_bind_parameter_count(lStatement) <> Length(FColumns)) then
    begin
      sqlite3_finalize(lStatement);
      DatabaseError('Filter must be a SQLite predicate without parameters.', Self);
    end;
  end;
  if FFilterStatement <> nil then sqlite3_finalize(FFilterStatement);
  FFilterStatement := lStatement;
end;

function TNXSQLiteDataSet.EvaluateRow(ARow: TNXSQLiteRow): Boolean;
var
  lBuffer, lOldBuffer: TRecordBuffer;
  lState: TDataSetState;
  lIndex, lResult: Integer;
begin
  Result := True;
  if FFilterStatement <> nil then
  begin
    FConnection.CheckResult(sqlite3_reset(FFilterStatement), 'reset filter');
    for lIndex := 0 to High(FColumns) do
      FConnection.BindValue(FFilterStatement, lIndex + 1, FColumns[lIndex].DataType, ARow[lIndex]);
    lResult := sqlite3_step(FFilterStatement);
    FConnection.CheckResult(lResult, 'evaluate filter');
    Result := (lResult = SQLITE_ROW) and (sqlite3_column_int(FFilterStatement, 0) <> 0);
    sqlite3_reset(FFilterStatement);
  end;
  if not Result or not Assigned(OnFilterRecord) then Exit;
  lBuffer := AllocRecordBuffer;
  lOldBuffer := FFilterBuffer;
  lState := SetTempState(dsFilter);
  try
    PNXSQLiteRecordBuffer(lBuffer)^.Row.Assign(ARow);
    FFilterBuffer := lBuffer;
    GetCalcFields(lBuffer);
    OnFilterRecord(Self, Result);
  finally
    FFilterBuffer := lOldBuffer;
    RestoreState(lState);
    FreeRecordBuffer(lBuffer);
  end;
end;

function TNXSQLiteDataSet.AcceptRow(ARow: TNXSQLiteRow): Boolean;
begin
  Result := not Filtered or EvaluateRow(ARow);
end;

function TNXSQLiteDataSet.CompareRows(ALeft, ARight: TNXSQLiteRow): Integer;
var
  lNames: TStringList;
  lIndex, lColumn: Integer;
  lName: string;
  lDescending: Boolean;
  lLeft, lRight: Variant;
  lRelation: TVariantRelationship;
begin
  Result := 0;
  lNames := TStringList.Create;
  try
    ExtractStrings([';'], [], PChar(FIndexFieldNames), lNames);
    for lIndex := 0 to lNames.Count - 1 do
    begin
      lName := Trim(lNames[lIndex]);
      lDescending := AnsiEndsText(' DESC', lName);
      if lDescending then SetLength(lName, Length(lName) - 5)
      else if AnsiEndsText(' ASC', lName) then SetLength(lName, Length(lName) - 4);
      lColumn := FieldByName(Trim(lName)).FieldNo - 1;
      if lColumn < 0 then DatabaseError('Indexes require stored fields.', Self);
      lLeft := ALeft[lColumn];
      lRight := ARight[lColumn];
      if VarIsNull(lLeft) then
      begin
        if not VarIsNull(lRight) then Result := -1;
      end
      else if VarIsNull(lRight) then Result := 1
      else
      begin
        if VarIsArray(lLeft) or VarIsArray(lRight) then DatabaseError('Cannot index blob fields.', Self);
        if VarIsStr(lLeft) and VarIsStr(lRight) then
          Result := CompareSQLiteText(VarToWideStr(lLeft), VarToWideStr(lRight))
        else
        begin
          lRelation := VarCompareValue(lLeft, lRight);
          case lRelation of
            vrLessThan: Result := -1;
            vrGreaterThan: Result := 1;
          end;
        end;
      end;
      if lDescending then Result := -Result;
      if Result <> 0 then Exit;
    end;
    if ALeft.ID < ARight.ID then Result := -1
    else if ALeft.ID > ARight.ID then Result := 1;
  finally
    lNames.Free;
  end;
end;

procedure TNXSQLiteDataSet.SortView(ALeft, ARight: Integer);
var
  lLeft, lRight, lSwap: Integer;
  lPivot: TNXSQLiteRow;
begin
  lLeft := ALeft;
  lRight := ARight;
  lPivot := FRows[FView[(ALeft + ARight) div 2]];
  repeat
    while CompareRows(FRows[FView[lLeft]], lPivot) < 0 do Inc(lLeft);
    while CompareRows(FRows[FView[lRight]], lPivot) > 0 do Dec(lRight);
    if lLeft <= lRight then
    begin
      lSwap := FView[lLeft];
      FView[lLeft] := FView[lRight];
      FView[lRight] := lSwap;
      Inc(lLeft);
      Dec(lRight);
    end;
  until lLeft > lRight;
  if ALeft < lRight then SortView(ALeft, lRight);
  if lLeft < ARight then SortView(lLeft, ARight);
end;

procedure TNXSQLiteDataSet.BuildView;
var
  lIndex, lCount: Integer;
  lView: array of Integer;
begin
  SetLength(lView, FRows.Count);
  lCount := 0;
  for lIndex := 0 to FRows.Count - 1 do
    if AcceptRow(FRows[lIndex]) then
    begin
      lView[lCount] := lIndex;
      Inc(lCount);
    end;
  SetLength(lView, lCount);
  FView := lView;
  if (FIndexFieldNames <> '') and (lCount > 1) then SortView(0, lCount - 1);
end;

procedure TNXSQLiteDataSet.SetIndexFieldNames(const AValue: string);
var
  lOld: string;
  lID: QWord;
begin
  if AValue = FIndexFieldNames then Exit;
  if Active then CheckBrowseMode;
  lOld := FIndexFieldNames;
  lID := 0;
  if Active and not IsEmpty then lID := CurrentRow.ID;
  FIndexFieldNames := AValue;
  if not Active then Exit;
  try
    BuildView;
  except
    FIndexFieldNames := lOld;
    BuildView;
    raise;
  end;
  FCursor := FindRowID(lID);
  Resync([]);
  UpdateIndexDefs;
end;

procedure TNXSQLiteDataSet.SetFiltered(AValue: Boolean);
begin
  if AValue = Filtered then Exit;
  if Active then CheckBrowseMode;
  inherited SetFiltered(AValue);
  if Active then
  begin
    BuildView;
    FCursor := -1;
    Resync([]);
  end;
end;

procedure TNXSQLiteDataSet.SetFilterText(const AValue: string);
var
  lOld: string;
begin
  if AValue = Filter then Exit;
  if Active then CheckBrowseMode;
  lOld := Filter;
  inherited SetFilterText(AValue);
  if not Active then Exit;
  try
    PrepareFilter;
  except
    inherited SetFilterText(lOld);
    raise;
  end;
  BuildView;
  FCursor := -1;
  Resync([]);
end;

procedure TNXSQLiteDataSet.SetFilterOptions(AValue: TFilterOptions);
begin
  if Active then CheckBrowseMode;
  inherited SetFilterOptions(AValue);
  if Active then
  begin
    PrepareFilter;
    BuildView;
    FCursor := -1;
    Resync([]);
  end;
end;

procedure TNXSQLiteDataSet.SetOnFilterRecord(const AValue: TFilterRecordEvent);
begin
  inherited SetOnFilterRecord(AValue);
  if Active and Filtered then
  begin
    CheckBrowseMode;
    BuildView;
    FCursor := -1;
    Resync([]);
  end;
end;

function TNXSQLiteDataSet.FindFirst: Boolean;
begin
  Result := FindRecord(True, True);
  SetFound(Result);
end;

function TNXSQLiteDataSet.FindLast: Boolean;
begin
  Result := FindRecord(True, False);
  SetFound(Result);
end;

function TNXSQLiteDataSet.FindNext: Boolean;
begin
  Result := FindRecord(False, True);
  SetFound(Result);
end;

function TNXSQLiteDataSet.FindPrior: Boolean;
begin
  Result := FindRecord(False, False);
  SetFound(Result);
end;

function TNXSQLiteDataSet.FindRecord(ARestart, AGoForward: Boolean): Boolean;
var
  lIndex, lStep: Integer;
begin
  CheckBrowseMode;
  Result := False;
  if AGoForward then lStep := 1 else lStep := -1;
  if ARestart then
  begin
    if AGoForward then lIndex := 0 else lIndex := High(FView);
  end
  else lIndex := GetRecNo - 1 + lStep;
  while (lIndex >= 0) and (lIndex < Length(FView)) do
  begin
    if EvaluateRow(FRows[FView[lIndex]]) then
    begin
      SetRecNo(lIndex + 1);
      Exit(True);
    end;
    Inc(lIndex, lStep);
  end;
end;

function TNXSQLiteDataSet.SameKey(ALeft, ARight: TNXSQLiteRow): Boolean;
var
  lIndex: Integer;
begin
  Result := False;
  if (ALeft = nil) or (ARight = nil) or (Length(FKeys) = 0) then Exit;
  for lIndex := 0 to High(FKeys) do
    if not SQLiteFieldValuesEqual(FColumns[FKeys[lIndex]].DataType,
      ALeft[FKeys[lIndex]], ARight[FKeys[lIndex]]) then Exit;
  Result := True;
end;

function TNXSQLiteDataSet.RowsHaveUniqueKeys(ARows: TNXSQLiteRows): Boolean;
var
  lRow, lOther, lKey: Integer;
begin
  Result := False;
  if Length(FKeys) = 0 then Exit;
  for lRow := 0 to ARows.Count - 1 do
  begin
    for lKey := 0 to High(FKeys) do
      if VarIsNull(ARows[lRow][FKeys[lKey]]) then Exit;
    for lOther := 0 to lRow - 1 do
      if SameKey(ARows[lRow], ARows[lOther]) then Exit;
  end;
  Result := True;
end;

function TNXSQLiteDataSet.FindKey(ARows: TNXSQLiteRows; ARow: TNXSQLiteRow): Integer;
var
  lIndex: Integer;
begin
  for lIndex := 0 to ARows.Count - 1 do
    if SameKey(ARows[lIndex], ARow) then Exit(lIndex);
  Result := -1;
end;

procedure TNXSQLiteDataSet.ReplaceRows(ARows: TNXSQLiteRows; ATarget: TNXSQLiteRow);
var
  lIndex, lOldIndex, lCursor: Integer;
  lOldRows: TNXSQLiteRows;
  lOldView: array of Integer;
  lID: QWord;
  lUniqueKeys: Boolean;
begin
  lID := 0;
  lCursor := FCursor;
  lUniqueKeys := RowsHaveUniqueKeys(ARows);
  lOldRows := FRows;
  lOldView := Copy(FView);
  for lIndex := 0 to ARows.Count - 1 do
  begin
    lOldIndex := -1;
    if lUniqueKeys then lOldIndex := FindKey(FRows, ARows[lIndex]);
    if lOldIndex >= 0 then ARows[lIndex].ID := FRows[lOldIndex].ID;
    if lUniqueKeys and SameKey(ARows[lIndex], ATarget) then lID := ARows[lIndex].ID;
  end;
  FRows := ARows;
  try
    BuildView;
    FCursor := FindRowID(lID);
    if FCursor < 0 then
    begin
      FCursor := lCursor;
      if FCursor >= Length(FView) then FCursor := Length(FView) - 1;
    end;
  except
    FRows := lOldRows;
    FView := lOldView;
    FCursor := lCursor;
    ARows.Free;
    raise;
  end;
  lOldRows.Free;
end;

procedure TNXSQLiteDataSet.InternalRefresh;
var
  lTarget: TNXSQLiteRow;
  lRows: TNXSQLiteRows;
begin
  CheckStreams;
  lTarget := TNXSQLiteRow.Create(Length(FColumns));
  try
    if not IsEmpty then lTarget.Assign(CurrentRow);
    lRows := LoadRows;
    try
      ValidateRows(lRows);
    except
      lRows.Free;
      raise;
    end;
    ReplaceRows(lRows, lTarget);
    ResolveKeys;
    UpdateIndexDefs;
  finally
    lTarget.Free;
  end;
end;

function TNXSQLiteDataSet.BuildWriteSQL(AKind: TUpdateKind; ARow: TNXSQLiteRow): string;
var
  lNames, lValues, lWhere, lReturn: string;
  lIndex, lColumn: Integer;
  lField: TField;
begin
  case AKind of
    ukInsert: if Trim(FInsertSQL.Text) <> '' then Exit(FInsertSQL.Text);
    ukModify: if Trim(FUpdateSQL.Text) <> '' then Exit(FUpdateSQL.Text);
    ukDelete: if Trim(FDeleteSQL.Text) <> '' then Exit(FDeleteSQL.Text);
  end;
  lNames := '';
  lValues := '';
  lWhere := '';
  lReturn := '';
  if AKind <> ukDelete then
    for lIndex := 0 to High(FColumns) do
    begin
      lField := FieldByNumber(lIndex + 1);
      if FColumns[lIndex].Generated or (lField = nil) or lField.ReadOnly then Continue;
      if (AKind = ukInsert) and not ARow.Assigned[lIndex] then Continue;
      if (AKind = ukModify) and SQLiteFieldValuesEqual(lField.DataType,
        ARow[lIndex], FOriginal[lIndex]) then Continue;
      if lNames <> '' then
      begin
        lNames := lNames + ', ';
        lValues := lValues + ', ';
      end;
      lNames := lNames + QuoteSQLiteIdentifier(FColumns[lIndex].OriginName);
      lValues := lValues + ':NX_NEW_' + IntToStr(lIndex);
      if AKind = ukModify then lNames := lNames + ' = :NX_NEW_' + IntToStr(lIndex);
    end;
  for lIndex := 0 to High(FKeys) do
  begin
    lColumn := FKeys[lIndex];
    if lWhere <> '' then
    begin
      lWhere := lWhere + ' AND ';
      lReturn := lReturn + ', ';
    end;
    lWhere := lWhere + QuoteSQLiteIdentifier(FColumns[lColumn].OriginName) +
      ' IS :NX_OLD_' + IntToStr(lColumn);
    lReturn := lReturn + QuoteSQLiteIdentifier(FColumns[lColumn].OriginName);
  end;
  if AKind <> ukInsert then
    for lIndex := 0 to High(FColumns) do
      if not FColumns[lIndex].Generated and (FColumns[lIndex].PrimaryKey = 0) then
        lWhere := lWhere + ' AND ' + QuoteSQLiteIdentifier(FColumns[lIndex].OriginName) +
          ' IS :NX_OLD_' + IntToStr(lIndex);
  case AKind of
    ukInsert:
      begin
        Result := 'INSERT INTO ' + QualifiedTable;
        if lNames = '' then Result := Result + ' DEFAULT VALUES'
        else Result := Result + ' (' + lNames + ') VALUES (' + lValues + ')';
        Result := Result + ' RETURNING ' + lReturn;
      end;
    ukModify:
      begin
        if lNames = '' then Exit('');
        Result := 'UPDATE ' + QualifiedTable + ' SET ' + lNames +
          ' WHERE ' + lWhere + ' RETURNING ' + lReturn;
      end;
    ukDelete: Result := 'DELETE FROM ' + QualifiedTable + ' WHERE ' + lWhere;
  end;
end;

procedure TNXSQLiteDataSet.BindWriteParams(AStatement: Psqlite3_stmt; ARow, AOld: TNXSQLiteRow);
var
  lIndex, lColumn: Integer;
  lName: string;
  lOld: Boolean;
  lParam: TParam;
  lParams: TParams;
begin
  lParams := nil;
  try
    for lIndex := 1 to sqlite3_bind_parameter_count(AStatement) do
    begin
      lName := string(sqlite3_bind_parameter_name(AStatement, lIndex));
      if lName = '' then DatabaseError('Update SQL requires named parameters.', Self);
      System.Delete(lName, 1, 1);
      lOld := AnsiStartsText('OLD_', lName) or AnsiStartsText('NX_OLD_', lName);
      if AnsiStartsText('NX_OLD_', lName) or AnsiStartsText('NX_NEW_', lName) then
        lColumn := StrToInt(Copy(lName, 8, MaxInt))
      else
      begin
        if AnsiStartsText('OLD_', lName) or AnsiStartsText('NEW_', lName) then System.Delete(lName, 1, 4);
        lColumn := 0;
        while (lColumn < Length(FColumns)) and not SameText(FColumns[lColumn].Name, lName) do Inc(lColumn);
      end;
      if (lColumn < 0) or (lColumn >= Length(FColumns)) then
      begin
        if lParams = nil then lParams := CreateExecutionParams;
        lParam := lParams.ParamByName(lName);
        if not lParam.Bound then DatabaseError('Update parameter is not bound: ' + lName, Self);
        FConnection.BindValue(AStatement, lIndex, lParam.DataType, lParam.Value);
      end
      else if lOld then
      begin
        if AOld = nil then DatabaseError('Old field values are unavailable for an insert.', Self);
        FConnection.BindValue(AStatement, lIndex, FColumns[lColumn].DataType, AOld[lColumn]);
      end
      else FConnection.BindValue(AStatement, lIndex, FColumns[lColumn].DataType, ARow[lColumn]);
    end;
  finally
    lParams.Free;
  end;
end;

procedure TNXSQLiteDataSet.WriteRow(AKind: TUpdateKind);
var
  lSQL, lSavepoint: string;
  lStatement: Psqlite3_stmt;
  lRow, lOld: TNXSQLiteRow;
  lRows, lOldRows: TNXSQLiteRows;
  lOldView, lOldKeys: array of Integer;
  lResult, lIndex, lOldIndex, lTargetIndex, lCursor: Integer;
  lReleased, lUniqueKeys, lOldWritable: Boolean;
begin
  CheckStreams;
  if not CanModify then DatabaseError('Dataset is read-only.', Self);
  lRow := TNXSQLiteRow.Create(Length(FColumns));
  lOld := nil;
  lRows := nil;
  lStatement := nil;
  lOldRows := FRows;
  lOldView := Copy(FView);
  lOldKeys := Copy(FKeys);
  lOldWritable := FWritable;
  lCursor := FCursor;
  lReleased := False;
  try
    lRow.Assign(CurrentRow);
    if AKind = ukModify then lOld := FOriginal
    else if AKind = ukDelete then
    begin
      lOld := FOriginal;
      if lOld = nil then lOld := lRow;
    end;
    lSQL := BuildWriteSQL(AKind, lRow);
    if lSQL = '' then
    begin
      FRowsAffected := 0;
      Exit;
    end;
    lSavepoint := FConnection.BeginSavepoint;
    try
      lStatement := FConnection.Prepare(lSQL);
      BindWriteParams(lStatement, lRow, lOld);
      lResult := sqlite3_step(lStatement);
      FConnection.CheckResult(lResult, 'write record');
      if lResult = SQLITE_ROW then
      begin
        if sqlite3_column_count(lStatement) <> Length(FKeys) then
          DatabaseError('Update RETURNING must return the key fields in KeyFields order.', Self);
        for lIndex := 0 to High(FKeys) do lRow[FKeys[lIndex]] := SQLiteColumnValue(lStatement, lIndex);
        lResult := sqlite3_step(lStatement);
        FConnection.CheckResult(lResult, 'finish write');
        if lResult <> SQLITE_DONE then DatabaseError('Update affected multiple records.', Self);
      end;
      sqlite3_finalize(lStatement);
      lStatement := nil;
      FRowsAffected := sqlite3_changes64(FConnection.Handle);
      if FRowsAffected <> 1 then DatabaseError('Expected exactly one affected record.', Self);
      lRows := LoadRows;
      ValidateRows(lRows);
      lUniqueKeys := RowsHaveUniqueKeys(lRows);
      lTargetIndex := -1;
      for lIndex := 0 to lRows.Count - 1 do
      begin
        lOldIndex := -1;
        if lUniqueKeys then lOldIndex := FindKey(FRows, lRows[lIndex]);
        if lOldIndex >= 0 then lRows[lIndex].ID := FRows[lOldIndex].ID;
        if lUniqueKeys and (AKind <> ukDelete) and SameKey(lRows[lIndex], lRow) then
        begin
          if lRow.ID <> 0 then lRows[lIndex].ID := lRow.ID;
          lTargetIndex := lIndex;
        end;
      end;
      FRows := lRows;
      BuildView;
      if lTargetIndex >= 0 then FCursor := FindRowID(lRows[lTargetIndex].ID)
      else FCursor := -1;
      if FCursor < 0 then
      begin
        FCursor := lCursor;
        if FCursor >= Length(FView) then FCursor := Length(FView) - 1;
      end;
      ResolveKeys;
      UpdateIndexDefs;
      FConnection.ReleaseSavepoint(lSavepoint);
      lReleased := True;
      lOldRows.Free;
      lRows := nil;
    except
      FRows := lOldRows;
      FView := lOldView;
      FKeys := lOldKeys;
      FWritable := lOldWritable;
      UpdateIndexDefs;
      FCursor := lCursor;
      if lStatement <> nil then sqlite3_finalize(lStatement);
      lStatement := nil;
      if not lReleased and FConnection.InTransaction then
        FConnection.RollbackSavepoint(lSavepoint);
      raise;
    end;
  finally
    lRows.Free;
    lRow.Free;
  end;
end;

procedure TNXSQLiteDataSet.InternalPost;
begin
  inherited InternalPost;
  if State = dsInsert then WriteRow(ukInsert) else WriteRow(ukModify);
  FreeAndNil(FOriginal);
  Inc(FEditSerial);
end;

procedure TNXSQLiteDataSet.InternalDelete;
begin
  WriteRow(ukDelete);
  FreeAndNil(FOriginal);
  Inc(FEditSerial);
end;

procedure TNXSQLiteDataSet.InternalAddRecord(ABuffer: Pointer; AAppend: Boolean);
begin
  InternalPost;
end;

function TNXSQLiteDataSet.MatchRow(ARow: TNXSQLiteRow; const AKeyFields: string;
  const AKeyValues: Variant; AOptions: TLocateOptions): Boolean;
var
  lNames: TStringList;
  lIndex, lColumn, lLow: Integer;
  lActual, lExpected: Variant;
  lText, lKey: UnicodeString;
begin
  Result := False;
  lNames := TStringList.Create;
  try
    ExtractStrings([';'], [], PChar(AKeyFields), lNames);
    if lNames.Count = 0 then DatabaseError('KeyFields is empty.', Self);
    lLow := 0;
    if VarIsArray(AKeyValues) then
    begin
      lLow := VarArrayLowBound(AKeyValues, 1);
      if VarArrayHighBound(AKeyValues, 1) - lLow + 1 <> lNames.Count then
        DatabaseError('Locate key count does not match KeyFields.', Self);
    end
    else if lNames.Count <> 1 then DatabaseError('Composite locate keys require a variant array.', Self);
    for lIndex := 0 to lNames.Count - 1 do
    begin
      lColumn := FieldByName(Trim(lNames[lIndex])).FieldNo - 1;
      if lColumn < 0 then DatabaseError('Locate requires stored key fields.', Self);
      lActual := ARow[lColumn];
      if VarIsArray(AKeyValues) then lExpected := AKeyValues[lLow + lIndex]
      else lExpected := AKeyValues;
      if VarIsStr(lActual) and VarIsStr(lExpected) then
      begin
        lText := VarToWideStr(lActual);
        lKey := VarToWideStr(lExpected);
        if loPartialKey in AOptions then lText := Copy(lText, 1, Length(lKey));
        if loCaseInsensitive in AOptions then
        begin
          if UnicodeCompareText(lText, lKey) <> 0 then Exit;
        end
        else if lText <> lKey then Exit;
      end
      else if not SQLiteFieldValuesEqual(FieldByNumber(lColumn + 1).DataType,
        lActual, lExpected) then Exit;
    end;
    Result := True;
  finally
    lNames.Free;
  end;
end;

function TNXSQLiteDataSet.SearchRow(const AKeyFields: string; const AKeyValues: Variant;
  AOptions: TLocateOptions): Integer;
var
  lIndex: Integer;
begin
  for lIndex := 0 to High(FView) do
    if MatchRow(FRows[FView[lIndex]], AKeyFields, AKeyValues, AOptions) then Exit(lIndex);
  Result := -1;
end;

function TNXSQLiteDataSet.Locate(const AKeyFields: string; const AKeyValues: Variant;
  AOptions: TLocateOptions): Boolean;
var
  lIndex: Integer;
begin
  CheckBrowseMode;
  lIndex := SearchRow(AKeyFields, AKeyValues, AOptions);
  Result := lIndex >= 0;
  if Result then SetRecNo(lIndex + 1);
end;

function TNXSQLiteDataSet.Lookup(const AKeyFields: string; const AKeyValues: Variant;
  const AResultFields: string): Variant;
var
  lIndex, lFieldIndex: Integer;
  lNames: TStringList;
  lBuffer, lOldBuffer: TRecordBuffer;
  lState: TDataSetState;
begin
  CheckActive;
  lIndex := SearchRow(AKeyFields, AKeyValues, []);
  if lIndex < 0 then Exit(Null);
  lNames := TStringList.Create;
  lBuffer := AllocRecordBuffer;
  lOldBuffer := FFilterBuffer;
  lState := SetTempState(dsFilter);
  try
    PNXSQLiteRecordBuffer(lBuffer)^.Row.Assign(FRows[FView[lIndex]]);
    FFilterBuffer := lBuffer;
    GetCalcFields(lBuffer);
    ExtractStrings([';'], [], PChar(AResultFields), lNames);
    if lNames.Count = 0 then DatabaseError('ResultFields is empty.', Self);
    if lNames.Count = 1 then Result := FieldByName(Trim(lNames[0])).Value
    else
    begin
      Result := VarArrayCreate([0, lNames.Count - 1], varVariant);
      for lFieldIndex := 0 to lNames.Count - 1 do
        Result[lFieldIndex] := FieldByName(Trim(lNames[lFieldIndex])).Value;
    end;
  finally
    FFilterBuffer := lOldBuffer;
    RestoreState(lState);
    FreeRecordBuffer(lBuffer);
    lNames.Free;
  end;
end;

procedure TNXSQLiteBlobField.Clear;
begin
  DataSet.SetFieldData(Self, nil);
end;

function TNXSQLiteBlobField.GetAsVariant: Variant;
begin
  if IsNull then Result := Null else Result := SQLiteBytesVariant(AsBytes);
end;

procedure TNXSQLiteBlobField.SetVarValue(const AValue: Variant);
begin
  if VarIsNull(AValue) then Clear
  else if VarIsArray(AValue) then AsBytes := SQLiteVariantBytes(AValue)
  else inherited SetVarValue(AValue);
end;

procedure TNXSQLiteMemoField.Clear;
begin
  DataSet.SetFieldData(Self, nil);
end;

function TNXSQLiteDataSet.CreateBlobStream(AField: TField; AMode: TBlobStreamMode): TStream;
begin
  CheckActive;
  if (AField.DataSet <> Self) or not AField.IsBlob or (AField.FieldNo <= 0) then
    DatabaseError('Blob streams require a stored blob field in this dataset.', Self);
  if AMode <> bmRead then
  begin
    if not (State in [dsEdit, dsInsert]) then DatabaseError('Dataset is not editing.', Self);
    if AField.ReadOnly then DatabaseError('Blob field is read-only.', Self);
  end
  else if AField.IsNull then Exit(nil);
  Result := TNXSQLiteBlobStream.Create(Self, AField, AMode);
end;

procedure TNXSQLiteDataSet.SetBlobValue(AField: TField; const AValue: Variant);
begin
  if not (State in [dsEdit, dsInsert]) then DatabaseError('Dataset is not editing.', Self);
  if AField.ReadOnly then DatabaseError('Blob field is read-only.', Self);
  CurrentRow[AField.FieldNo - 1] := AValue;
  DataEvent(deFieldChange, PtrInt(AField));
end;

constructor TNXSQLiteBlobStream.Create(ADataSet: TNXSQLiteDataSet; AField: TField;
  AMode: TBlobStreamMode);
var
  lValue: Variant;
  lBytes: TBytes;
  lWide: UnicodeString;
  lText: UTF8String;
begin
  inherited Create;
  if AMode <> bmWrite then
  begin
    lValue := ADataSet.CurrentRow[AField.FieldNo - 1];
    if not VarIsNull(lValue) then
      case AField.DataType of
        ftWideMemo:
          begin
            lWide := VarToWideStr(lValue);
            if lWide <> '' then inherited Write(lWide[1], Length(lWide) * SizeOf(WideChar));
          end;
        ftMemo, ftFmtMemo:
          begin
            lText := UTF8Encode(VarToWideStr(lValue));
            if lText <> '' then inherited Write(lText[1], Length(lText));
          end;
        else
          begin
            lBytes := SQLiteVariantBytes(lValue);
            if Length(lBytes) > 0 then inherited Write(lBytes[0], Length(lBytes));
          end;
      end;
  end;
  Position := 0;
  FDataSet := ADataSet;
  FField := AField;
  FMode := AMode;
  FSerial := ADataSet.FEditSerial;
  ADataSet.FStreams.Add(Self);
end;

procedure TNXSQLiteBlobStream.Detach;
begin
  FDataSet := nil;
  FField := nil;
end;

procedure TNXSQLiteBlobStream.CheckWritable;
begin
  if FMode = bmRead then DatabaseError('Blob stream is read-only.');
  if (FDataSet = nil) or (FSerial <> FDataSet.FEditSerial) or
    not (FDataSet.State in [dsEdit, dsInsert]) then
    DatabaseError('Blob stream no longer belongs to an active edit.');
end;

function TNXSQLiteBlobStream.Write(const ABuffer; ACount: Longint): Longint;
begin
  CheckWritable;
  Result := inherited Write(ABuffer, ACount);
end;

procedure TNXSQLiteBlobStream.SetSize(const ASize: Int64);
begin
  CheckWritable;
  inherited SetSize(ASize);
end;

destructor TNXSQLiteBlobStream.Destroy;
var
  lBytes: TBytes;
  lWide: UnicodeString;
  lText: UTF8String;
  lValue: Variant;
begin
  try
    if FDataSet <> nil then
    begin
      FDataSet.FStreams.Remove(Self);
      if FMode <> bmRead then
      begin
        CheckWritable;
        case FField.DataType of
          ftWideMemo:
            begin
              if Size mod SizeOf(WideChar) <> 0 then DatabaseError('Wide memo stream contains incomplete UTF-16.');
              SetLength(lWide, Size div SizeOf(WideChar));
              if Size > 0 then Move(Memory^, lWide[1], Size);
              lValue := lWide;
            end;
          ftMemo, ftFmtMemo:
            begin
              SetLength(lText, Size);
              if Size > 0 then Move(Memory^, lText[1], Size);
              lValue := UTF8Decode(lText);
            end;
          else
            begin
              SetLength(lBytes, Size);
              if Size > 0 then Move(Memory^, lBytes[0], Size);
              lValue := SQLiteBytesVariant(lBytes);
            end;
        end;
        FDataSet.SetBlobValue(FField, lValue);
      end;
    end;
  finally
    inherited Destroy;
  end;
end;

procedure TNXSQLiteDataSet.UpdateIndexDefs;
var
  lIndex: Integer;
  lFields, lDescending, lName: string;
  lNames: TStringList;
begin
  FIndexDefs.Clear;
  lFields := '';
  for lIndex := 0 to High(FKeys) do
  begin
    if lFields <> '' then lFields := lFields + ';';
    lFields := lFields + FColumns[FKeys[lIndex]].Name;
  end;
  if lFields <> '' then FIndexDefs.Add('PRIMARY', lFields, [ixPrimary, ixUnique]);
  if FIndexFieldNames = '' then Exit;
  lNames := TStringList.Create;
  try
    ExtractStrings([';'], [], PChar(FIndexFieldNames), lNames);
    lFields := '';
    lDescending := '';
    for lIndex := 0 to lNames.Count - 1 do
    begin
      lName := Trim(lNames[lIndex]);
      if AnsiEndsText(' DESC', lName) then
      begin
        SetLength(lName, Length(lName) - 5);
        lName := Trim(lName);
        if lDescending <> '' then lDescending := lDescending + ';';
        lDescending := lDescending + lName;
      end
      else if AnsiEndsText(' ASC', lName) then
        lName := Trim(Copy(lName, 1, Length(lName) - 4));
      if lFields <> '' then lFields := lFields + ';';
      lFields := lFields + lName;
    end;
    FIndexDefs.Add('LOCAL', lFields, []);
    FIndexDefs[FIndexDefs.Count - 1].DescFields := lDescending;
  finally
    lNames.Free;
  end;
end;

procedure TNXSQLiteDataSet.ValidateRows(ARows: TNXSQLiteRows);
var
  lRow, lIndex: Integer;
  lField: TField;
  lBuffer: Pointer;
  lValue: Variant;
begin
  for lIndex := 0 to High(FColumns) do
  begin
    lField := FieldByNumber(lIndex + 1);
    if lField = nil then Continue;
    lBuffer := AllocMem(lField.DataSize + 1);
    try
      for lRow := 0 to ARows.Count - 1 do
      begin
        lValue := ARows[lRow][lIndex];
        if VarIsNull(lValue) then Continue;
        if not lField.IsBlob then SQLiteValueToBuffer(lField, lValue, lBuffer)
        else if (lField.DataType in [ftBlob, ftGraphic, ftTypedBinary]) <> VarIsArray(lValue) then
          DatabaseError('SQLite storage type does not match field: ' + lField.FieldName, Self);
      end;
    finally
      FreeMem(lBuffer);
    end;
  end;
end;

function TNXSQLiteDataSet.GetCurrentRecord(ABuffer: TRecordBuffer): Boolean;
begin
  CheckActive;
  Result := not IsEmpty;
  if not Result then Exit;
  PNXSQLiteRecordBuffer(ABuffer)^.Row.Assign(CurrentRow);
  PNXSQLiteRecordBuffer(ABuffer)^.Bookmark := PNXSQLiteRecordBuffer(ActiveBuffer)^.Bookmark;
  PNXSQLiteRecordBuffer(ABuffer)^.Flag := bfCurrent;
  GetCalcFields(ABuffer);
end;

procedure TNXSQLiteDataSet.PSGetAttributes(AList: TList);
begin
  AList.Clear;
end;

function TNXSQLiteDataSet.PSGetCommandType: TPSCommandType;
begin
  Result := ctQuery;
end;

function TNXSQLiteDataSet.PSGetDefaultOrder: TIndexDef;
var
  lIndex: Integer;
begin
  Result := nil;
  lIndex := FIndexDefs.IndexOf('LOCAL');
  if lIndex >= 0 then Result := FIndexDefs[lIndex];
end;

function TNXSQLiteDataSet.PSGetIndexDefs(AIndexTypes: TIndexOptions): TIndexDefs;
begin
  Result := GetIndexDefs(FIndexDefs, AIndexTypes);
end;

function TNXSQLiteDataSet.PSUpdateRecord(AUpdateKind: TUpdateKind; ADelta: TDataSet): Boolean;
begin
  // Let the standard provider resolver generate and execute its update SQL.
  Result := False;
end;

procedure TNXSQLiteDataSet.PSStartTransaction;
begin
  if FConnection = nil then DatabaseError('Connection is required.', Self);
  FConnection.StartTransaction;
end;

procedure TNXSQLiteDataSet.PSEndTransaction(ACommit: Boolean);
begin
  if ACommit then FConnection.Commit else FConnection.Rollback;
end;

function TNXSQLiteDataSet.PSInTransaction: Boolean;
begin
  Result := (FConnection <> nil) and FConnection.InTransaction;
end;

function TNXSQLiteDataSet.PSIsSQLBased: Boolean;
begin
  Result := True;
end;

function TNXSQLiteDataSet.PSIsSQLSupported: Boolean;
begin
  Result := True;
end;

function TNXSQLiteDataSet.PSGetCommandText: string;
begin
  Result := FSQL.Text;
end;

function TNXSQLiteDataSet.PSGetParams: TParams;
begin
  Result := FParams;
end;

function TNXSQLiteDataSet.PSGetTableName: string;
begin
  Result := FTableName;
end;

function TNXSQLiteDataSet.PSGetKeyFields: string;
var
  lIndex: Integer;
begin
  Result := '';
  for lIndex := 0 to High(FKeys) do
  begin
    if Result <> '' then Result := Result + ';';
    Result := Result + FColumns[FKeys[lIndex]].Name;
  end;
end;

function TNXSQLiteDataSet.PSGetQuoteChar: string;
begin
  Result := '"';
end;

procedure TNXSQLiteDataSet.PSSetCommandText(const ACommandText: string);
begin
  Close;
  FSQL.Text := ACommandText;
end;

procedure TNXSQLiteDataSet.PSSetParams(AParams: TParams);
begin
  Close;
  FParams.Assign(AParams);
end;

procedure TNXSQLiteDataSet.PSExecute;
begin
  ExecSQL;
end;

function TNXSQLiteDataSet.PSExecuteStatement(const ASQL: string; AParams: TParams;
  AResultSet: Pointer): Integer;
var
  lDataSet: TNXSQLiteDataSet;
begin
  if FConnection = nil then DatabaseError('Connection is required.', Self);
  if AResultSet = nil then Exit(FConnection.Execute(ASQL, AParams));
  lDataSet := TNXSQLiteDataSet.Create(nil);
  try
    lDataSet.Connection := FConnection;
    lDataSet.SQL.Text := ASQL;
    if AParams <> nil then lDataSet.Params.Assign(AParams);
    lDataSet.Open;
    TDataSet(AResultSet^) := lDataSet;
    Result := lDataSet.RecordCount;
  except
    lDataSet.Free;
    raise;
  end;
end;

procedure TNXSQLiteDataSet.PSReset;
begin
  if Active then Refresh;
end;

end.

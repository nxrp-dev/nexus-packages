(*
  Copyright (c) 2026 Kevin Collins.
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)
unit tsNXSQLiteTests;

{$mode objfpc}{$H+}{$codepage utf8}

interface

uses obNXTestRegistry;

procedure RegisterNXSQLiteTests(ARegistry: TNXTestRegistry);

implementation

uses Classes, SysUtils, Variants, DB, DateUtils, SQLite3Dyn,
  obNXSQLiteConnection, obNXSQLiteDataSet, obNXTestContext, obNXTestSuite;

type
  TNXSQLiteProviderTestDataSet = class(TNXSQLiteDataSet)
  public
    function IsLocalIndexField(AField: TField): Boolean;
    property ProviderDefaultOrder: TIndexDef read PSGetDefaultOrder;
    property ProviderKeyFields: string read PSGetKeyFields;
  end;

  TNXSQLiteFixture = class
  private
    FConnection: TNXSQLiteConnection;
    FDataSet: TNXSQLiteDataSet;
  public
    constructor Create;
    destructor Destroy; override;
    property Connection: TNXSQLiteConnection read FConnection;
    property DataSet: TNXSQLiteDataSet read FDataSet;
  end;

  TNXSQLiteEvents = class
  private
    FAfterPost: Integer;
    FPostErrors: Integer;
    FChanges: Integer;
    FStates: Integer;
  public
    procedure AfterPost(ADataSet: TDataSet);
    procedure PostError(ADataSet: TDataSet; AException: EDatabaseError; var AAction: TDataAction);
    procedure DataChange(ASender: TObject; AField: TField);
    procedure StateChange(ASender: TObject);
    procedure FilterRow(ADataSet: TDataSet; var AAccept: Boolean);
    procedure CalcFields(ADataSet: TDataSet);
    property Posts: Integer read FAfterPost;
    property Errors: Integer read FPostErrors;
    property Changes: Integer read FChanges;
    property States: Integer read FStates;
  end;

function TNXSQLiteProviderTestDataSet.IsLocalIndexField(AField: TField): Boolean;
begin
  Result := GetIsIndexField(AField);
end;

function LibraryPath: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '../runtime/win64/sqlite3.dll');
end;

function UTF8Text(const AValue: UnicodeString): string;
var
  lText: UTF8String;
begin
  lText := UTF8Encode(AValue);
  SetString(Result, PAnsiChar(lText), Length(lText));
end;

constructor TNXSQLiteFixture.Create;
begin
  inherited Create;
  FConnection := TNXSQLiteConnection.Create(nil);
  FConnection.LibraryName := LibraryPath;
  FConnection.DatabaseName := ':memory:';
  FConnection.Open;
  FConnection.Execute('CREATE TABLE items (id INTEGER PRIMARY KEY, name VARCHAR(80) NOT NULL UNIQUE, ' +
    'category INTEGER, amount DECIMAL(18,4), born DATE, note TEXT, payload BLOB, flag BOOLEAN DEFAULT 0)');
  FConnection.Execute('INSERT INTO items(id,name,category,amount,born,note,payload) VALUES ' +
    '(1,''alpha'',10,12.5,''2024-02-29'',''one'',X''0001FF''),' +
    '(2,''beta'',20,NULL,NULL,'''',X''''),' +
    '(3,''Gamma'',10,7.25,''2025-01-01'',NULL,NULL)');
  FDataSet := TNXSQLiteDataSet.Create(nil);
  FDataSet.Connection := FConnection;
  FDataSet.SQL.Text := 'SELECT * FROM items ORDER BY id';
end;

destructor TNXSQLiteFixture.Destroy;
begin
  FDataSet.Free;
  FConnection.Free;
  inherited Destroy;
end;

procedure TNXSQLiteEvents.AfterPost(ADataSet: TDataSet);
begin
  Inc(FAfterPost);
end;

procedure TNXSQLiteEvents.PostError(ADataSet: TDataSet; AException: EDatabaseError;
  var AAction: TDataAction);
begin
  Inc(FPostErrors);
  AAction := daFail;
end;

procedure TNXSQLiteEvents.DataChange(ASender: TObject; AField: TField);
begin
  Inc(FChanges);
end;

procedure TNXSQLiteEvents.StateChange(ASender: TObject);
begin
  Inc(FStates);
end;

procedure TNXSQLiteEvents.FilterRow(ADataSet: TDataSet; var AAccept: Boolean);
begin
  AAccept := ADataSet.FieldByName('category').AsInteger = 10;
end;

procedure TNXSQLiteEvents.CalcFields(ADataSet: TDataSet);
begin
  ADataSet.FieldByName('display').AsString := ADataSet.FieldByName('name').AsString + '!';
end;

procedure TestNavigation(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
  lBookmark: TBookmark;
begin
  lFixture := TNXSQLiteFixture.Create;
  try
    with lFixture.DataSet do
    begin
      Open;
      AContext.AssertEquals(3, RecordCount);
      AContext.AssertTrue(BOF);
      AContext.AssertEquals(1, RecNo);
      AContext.AssertEquals('alpha', FieldByName('name').AsString);
      Next;
      lBookmark := GetBookmark;
      try
        Last;
        AContext.AssertEquals('Gamma', FieldByName('name').AsString);
        Next;
        AContext.AssertTrue(EOF);
        Prior;
        AContext.AssertEquals('beta', FieldByName('name').AsString);
        First;
        GotoBookmark(lBookmark);
        AContext.AssertEquals(2, RecNo);
        AContext.AssertTrue(BookmarkValid(lBookmark));
        AContext.AssertEquals(-1, MoveBy(-1));
        AContext.AssertEquals(1, RecNo);
        RecNo := 3;
        AContext.AssertEquals('Gamma', FieldByName('name').AsString);
      finally
        FreeBookmark(lBookmark);
      end;
    end;
  finally
    lFixture.Free;
  end;
end;

procedure TestEmptyAndReopen(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
begin
  lFixture := TNXSQLiteFixture.Create;
  try
    with lFixture.DataSet do
    begin
      SQL.Text := 'SELECT * FROM items WHERE id > 100';
      Open;
      AContext.AssertTrue(IsEmpty and BOF and EOF);
      AContext.AssertEquals(0, RecNo);
      AContext.AssertEquals(8, FieldCount);
      Close;
      SQL.Text := 'SELECT * FROM items ORDER BY id';
      Open;
      AContext.AssertEquals(3, RecordCount);
      AContext.AssertEquals('alpha', FieldByName('name').AsString);
    end;
  finally
    lFixture.Free;
  end;
end;

procedure TestWritesDefaultsAndCancel(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
  lBookmark: TBookmark;
begin
  lFixture := TNXSQLiteFixture.Create;
  try
    with lFixture.DataSet do
    begin
      Open;
      AContext.AssertTrue(CanModify);
      lBookmark := GetBookmark;
      try
        Edit;
        FieldByName('name').AsString := 'changed';
        Cancel;
        AContext.AssertEquals('alpha', FieldByName('name').AsString);
        Edit;
        FieldByName('name').AsString := 'updated';
        Post;
        AContext.AssertTrue(State = dsBrowse);
        AContext.AssertEquals('updated', FieldByName('name').AsString);
        AContext.AssertTrue(BookmarkValid(lBookmark));
        Append;
        FieldByName('name').AsString := 'delta';
        Post;
        AContext.AssertEquals(4, RecordCount);
        AContext.AssertEquals('4', FieldByName('id').AsString);
        AContext.AssertFalse(FieldByName('flag').IsNull);
        AContext.AssertFalse(FieldByName('flag').AsBoolean);
        AContext.AssertTrue(UpdateStatus = usUnmodified);
        Insert;
        FieldByName('name').AsString := 'cancelled';
        Cancel;
        AContext.AssertEquals(4, RecordCount);
        Delete;
        AContext.AssertEquals(3, RecordCount);
        GotoBookmark(lBookmark);
        AContext.AssertEquals('updated', FieldByName('name').AsString);
        Refresh;
        AContext.AssertEquals('updated', FieldByName('name').AsString);
      finally
        FreeBookmark(lBookmark);
      end;
    end;
  finally
    lFixture.Free;
  end;
end;

procedure TestFailedPost(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
  lEvents: TNXSQLiteEvents;
  lFailed: Boolean;
begin
  lFixture := TNXSQLiteFixture.Create;
  lEvents := TNXSQLiteEvents.Create;
  try
    with lFixture.DataSet do
    begin
      OnPostError := @lEvents.PostError;
      AfterPost := @lEvents.AfterPost;
      Open;
      Edit;
      FieldByName('name').AsString := 'beta';
      lFailed := False;
      try Post except on E: ENXSQLiteError do lFailed := True; end;
      AContext.AssertTrue(lFailed, 'Unique constraint must fail the post.');
      AContext.AssertTrue(State = dsEdit, 'Failed Post must remain in edit state.');
      AContext.AssertEquals('beta', FieldByName('name').AsString);
      AContext.AssertEquals(0, lEvents.Posts);
      AContext.AssertEquals(1, lEvents.Errors);
      AContext.AssertFalse(lFixture.Connection.InTransaction, 'Failed autocommit write must release its savepoint.');
      FieldByName('name').AsString := 'repaired';
      Post;
      AContext.AssertEquals(1, lEvents.Posts);
      AContext.AssertEquals('repaired', FieldByName('name').AsString);
    end;
  finally
    lEvents.Free;
    lFixture.Free;
  end;
end;

procedure TestTransactionRollback(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
begin
  lFixture := TNXSQLiteFixture.Create;
  try
    lFixture.DataSet.Open;
    lFixture.Connection.StartTransaction;
    lFixture.DataSet.Edit;
    lFixture.DataSet.FieldByName('name').AsString := 'temporary';
    lFixture.DataSet.Post;
    AContext.AssertTrue(lFixture.Connection.InTransaction);
    lFixture.Connection.Rollback;
    AContext.AssertEquals('alpha', lFixture.DataSet.FieldByName('name').AsString);
    lFixture.Connection.StartTransaction;
    lFixture.DataSet.Edit;
    lFixture.DataSet.FieldByName('name').AsString := 'committed';
    lFixture.DataSet.Post;
    lFixture.Connection.Commit;
    lFixture.DataSet.Refresh;
    AContext.AssertEquals('committed', lFixture.DataSet.FieldByName('name').AsString);
    lFixture.Connection.StartTransaction;
    lFixture.DataSet.Append;
    lFixture.DataSet.FieldByName('name').AsString := 'unposted';
    lFixture.Connection.Rollback;
    AContext.AssertTrue(lFixture.DataSet.State = dsBrowse);
    AContext.AssertEquals(3, lFixture.DataSet.RecordCount);
  finally
    lFixture.Free;
  end;
end;

procedure TestBlobsAndUnicode(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
  lBytes: TBytes;
  lText: UnicodeString;
  lStream: TStream;
  lFailed: Boolean;
begin
  lFixture := TNXSQLiteFixture.Create;
  try
    with lFixture.DataSet do
    begin
      Open;
      lBytes := FieldByName('payload').AsBytes;
      AContext.AssertEquals(3, Length(lBytes));
      AContext.AssertEquals(255, lBytes[2]);
      Next;
      AContext.AssertFalse(FieldByName('payload').IsNull, 'An empty blob is not NULL.');
      AContext.AssertEquals(0, Length(FieldByName('payload').AsBytes));
      Next;
      AContext.AssertTrue(FieldByName('payload').IsNull);
      Edit;
      SetLength(lBytes, 0);
      FieldByName('payload').AsBytes := lBytes;
      lText := UnicodeString('Grüße 世界 😀');
      FieldByName('note').AsUnicodeString := lText;
      Post;
      AContext.AssertFalse(FieldByName('payload').IsNull);
      AContext.AssertTrue(FieldByName('note').AsUnicodeString = lText);
      Edit;
      FieldByName('payload').Clear;
      FieldByName('note').AsUnicodeString := '';
      Post;
      AContext.AssertTrue(FieldByName('payload').IsNull);
      AContext.AssertFalse(FieldByName('note').IsNull, 'Empty text must remain distinct from NULL.');
      Edit;
      lStream := CreateBlobStream(FieldByName('payload'), bmWrite);
      try
        lFailed := False;
        try Post except on E: EDatabaseError do lFailed := True; end;
        AContext.AssertTrue(lFailed, 'Post must reject a writable blob stream that is still open.');
      finally
        lStream.Free;
      end;
      Cancel;
    end;
  finally
    lFixture.Free;
  end;
end;

procedure TestFilterLocateLookup(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
  lEvents: TNXSQLiteEvents;
  lValue: Variant;
  lBefore: Integer;
begin
  lFixture := TNXSQLiteFixture.Create;
  lEvents := TNXSQLiteEvents.Create;
  try
    with lFixture.DataSet do
    begin
      Open;
      Filter := 'category = 10';
      Filtered := True;
      AContext.AssertEquals(2, RecordCount);
      AContext.AssertTrue(Locate('name', 'ga', [loCaseInsensitive, loPartialKey]));
      AContext.AssertEquals('Gamma', FieldByName('name').AsString);
      lBefore := RecNo;
      lValue := Lookup('id', 1, 'name;category');
      AContext.AssertEquals('alpha', VarToStr(lValue[0]));
      AContext.AssertEquals('10', VarToStr(lValue[1]));
      AContext.AssertEquals(lBefore, RecNo, 'Lookup must not move the dataset.');
      AContext.AssertTrue(VarIsNull(Lookup('id', 999, 'name')));
      AContext.AssertFalse(Locate('id', 2, []), 'Locate must respect filtering.');
      Filtered := False;
      Filter := 'amount IS NULL';
      AContext.AssertTrue(FindFirst);
      AContext.AssertEquals('beta', FieldByName('name').AsString);
      AContext.AssertFalse(FindNext);
      Filter := '';
      OnFilterRecord := @lEvents.FilterRow;
      Filtered := True;
      AContext.AssertEquals(2, RecordCount);
      Filtered := False;
      IndexFieldNames := 'name DESC';
      First;
      AContext.AssertEquals('beta', FieldByName('name').AsString);
      IndexFieldNames := 'category;id DESC';
      First;
      AContext.AssertEquals('3', FieldByName('id').AsString);
    end;
  finally
    lFixture.Free;
    lEvents.Free;
  end;
end;

procedure TestCompositeKeys(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
begin
  lFixture := TNXSQLiteFixture.Create;
  try
    lFixture.Connection.Execute('CREATE TABLE composite (a INTEGER, b TEXT, value TEXT, PRIMARY KEY(a,b)) WITHOUT ROWID');
    lFixture.Connection.Execute('INSERT INTO composite VALUES(1,''x'',''old''),(1,''y'',''other'')');
    with lFixture.DataSet do
    begin
      SQL.Text := 'SELECT a,b,value FROM composite ORDER BY b';
      Open;
      AContext.AssertTrue(CanModify);
      AContext.AssertTrue(Locate('a;b', VarArrayOf([1, 'y']), []));
      Edit;
      FieldByName('value').AsUnicodeString := 'new';
      Post;
      AContext.AssertEquals('new', FieldByName('value').AsString);
      AContext.AssertEquals('old', VarToStr(Lookup('a;b', VarArrayOf([1, 'x']), 'value')));
      Delete;
      AContext.AssertEquals(1, RecordCount);
      Append;
      FieldByName('a').AsLargeInt := 2;
      FieldByName('b').AsUnicodeString := 'z';
      FieldByName('value').AsUnicodeString := 'insert';
      Post;
      AContext.AssertEquals(2, RecordCount);
      AContext.AssertEquals('z', FieldByName('b').AsString);
      Close;
      SQL.Text := 'SELECT a,value FROM composite';
      Open;
      AContext.AssertFalse(CanModify, 'A partial primary key must not make a query writable.');
    end;
  finally
    lFixture.Free;
  end;
end;

procedure TestPersistentCalculatedAndLookupFields(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
  lEvents: TNXSQLiteEvents;
  lLookup: TNXSQLiteDataSet;
  lID, lCategory: TLargeintField;
  lName, lReference: TWideStringField;
  lDisplay: TStringField;
begin
  lFixture := TNXSQLiteFixture.Create;
  lEvents := TNXSQLiteEvents.Create;
  lLookup := TNXSQLiteDataSet.Create(nil);
  try
    lLookup.Connection := lFixture.Connection;
    lLookup.SQL.Text := 'SELECT id,name FROM items';
    lLookup.Open;
    lFixture.DataSet.SQL.Text := 'SELECT id,name,category FROM items ORDER BY id';
    lID := TLargeintField.Create(lFixture.DataSet);
    lID.FieldName := 'id';
    lID.DataSet := lFixture.DataSet;
    lName := TWideStringField.Create(lFixture.DataSet);
    lName.FieldName := 'name';
    lName.Size := 80;
    lName.DataSet := lFixture.DataSet;
    lCategory := TLargeintField.Create(lFixture.DataSet);
    lCategory.FieldName := 'category';
    lCategory.DataSet := lFixture.DataSet;
    lDisplay := TStringField.Create(lFixture.DataSet);
    lDisplay.FieldName := 'display';
    lDisplay.FieldKind := fkCalculated;
    lDisplay.Size := 100;
    lDisplay.DataSet := lFixture.DataSet;
    lReference := TWideStringField.Create(lFixture.DataSet);
    lReference.FieldName := 'reference';
    lReference.Size := 80;
    lReference.FieldKind := fkLookup;
    lReference.KeyFields := 'id';
    lReference.LookupDataSet := lLookup;
    lReference.LookupKeyFields := 'id';
    lReference.LookupResultField := 'name';
    lReference.DataSet := lFixture.DataSet;
    lFixture.DataSet.OnCalcFields := @lEvents.CalcFields;
    lFixture.DataSet.Open;
    AContext.AssertEquals('alpha!', lDisplay.AsString);
    AContext.AssertEquals('alpha', lReference.AsString);
    lFixture.DataSet.Next;
    AContext.AssertEquals('beta!', lDisplay.AsString);
    AContext.AssertEquals('beta', lReference.AsString);
    lFixture.DataSet.Edit;
    lName.AsString := 'edited';
    AContext.AssertEquals('edited!', lDisplay.AsString);
    AContext.AssertEquals('beta', VarToStr(lName.OldValue));
    lFixture.DataSet.Cancel;
    AContext.AssertEquals('beta!', lDisplay.AsString);
  finally
    lFixture.Free;
    lLookup.Free;
    lEvents.Free;
  end;
end;

procedure TestMasterDetail(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
  lMaster: TNXSQLiteDataSet;
  lSource: TDataSource;
begin
  lFixture := TNXSQLiteFixture.Create;
  lMaster := TNXSQLiteDataSet.Create(nil);
  lSource := TDataSource.Create(nil);
  try
    lMaster.Connection := lFixture.Connection;
    lMaster.SQL.Text := 'SELECT DISTINCT category FROM items ORDER BY category';
    lMaster.Open;
    lSource.DataSet := lMaster;
    lFixture.DataSet.SQL.Text := 'SELECT * FROM items WHERE category=:category ORDER BY id';
    lFixture.DataSet.MasterSource := lSource;
    lFixture.DataSet.Open;
    AContext.AssertEquals(2, lFixture.DataSet.RecordCount);
    AContext.AssertFalse(lFixture.DataSet.ParamByName('category').Bound,
      'A master-supplied parameter must remain owned by the master link.');
    lMaster.Next;
    AContext.AssertEquals(1, lFixture.DataSet.RecordCount);
    AContext.AssertFalse(lFixture.DataSet.ParamByName('category').Bound);
    AContext.AssertEquals('beta', lFixture.DataSet.FieldByName('name').AsString);
    lMaster.Close;
    AContext.AssertFalse(lFixture.DataSet.Active);
  finally
    lSource.Free;
    lMaster.Free;
    lFixture.Free;
  end;
end;

procedure TestFieldTypesAndLargeKeys(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
begin
  lFixture := TNXSQLiteFixture.Create;
  try
    with lFixture.DataSet do
    begin
      Open;
      AContext.AssertTrue(FieldByName('id').DataType = ftLargeint);
      AContext.AssertTrue(FieldByName('amount').DataType = ftFMTBcd);
      AContext.AssertTrue(FieldByName('born').DataType = ftDate);
      AContext.AssertTrue(Trunc(FieldByName('born').AsDateTime) = Trunc(EncodeDate(2024, 2, 29)));
      AContext.AssertTrue(Abs(FieldByName('amount').AsFloat - 12.5) < 0.00001);
      Edit;
      FieldByName('id').AsLargeInt := 9223372036854775806;
      FieldByName('born').AsDateTime := EncodeDate(2026, 10, 4);
      FieldByName('flag').AsBoolean := True;
      Post;
      AContext.AssertEquals('9223372036854775806', FieldByName('id').AsString);
      AContext.AssertTrue(FieldByName('flag').AsBoolean);
      AContext.AssertTrue(Trunc(FieldByName('born').AsDateTime) = Trunc(EncodeDate(2026, 10, 4)));
    end;
  finally
    lFixture.Free;
  end;
end;

procedure TestReadOnlyAndQueryIdentity(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
begin
  lFixture := TNXSQLiteFixture.Create;
  try
    with lFixture.DataSet do
    begin
      SQL.Text := 'SELECT name FROM items';
      Open;
      AContext.AssertFalse(CanModify, 'Query must include a complete row identity.');
      Close;
      SQL.Text := 'SELECT id,name FROM items UNION ALL SELECT id,name FROM items';
      Open;
      AContext.AssertFalse(CanModify, 'Duplicate row identities must be read-only.');
      Close;
      SQL.Text := 'SELECT * FROM items';
      ReadOnly := True;
      Open;
      AContext.AssertFalse(CanModify);
      Close;
      ReadOnly := False;
      lFixture.Connection.Execute('CREATE TABLE other(id INTEGER PRIMARY KEY,value TEXT)');
      lFixture.Connection.Execute('INSERT INTO other VALUES(1,''other'')');
      SQL.Text := 'SELECT items.id,items.name,other.value FROM items JOIN other ON items.id=other.id';
      Open;
      AContext.AssertFalse(CanModify, 'Joins require an explicit update contract.');
    end;
  finally
    lFixture.Free;
  end;
end;

procedure TestCustomSQLAndExecSQL(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
begin
  lFixture := TNXSQLiteFixture.Create;
  try
    with lFixture.DataSet do
    begin
      UpdateSQL.Text := 'UPDATE items SET name=:NEW_name WHERE id=:OLD_id RETURNING id';
      Open;
      Edit;
      FieldByName('name').AsString := 'custom';
      Post;
      AContext.AssertEquals('custom', FieldByName('name').AsString);
      Close;
      SQL.Text := 'UPDATE items SET category=:category WHERE id=:id';
      ParamByName('category').AsInteger := 30;
      ParamByName('id').AsInteger := 1;
      ExecSQL;
      AContext.AssertTrue(RowsAffected = 1);
      SQL.Text := 'SELECT * FROM items WHERE category=:category';
      ParamByName('category').AsInteger := 30;
      Open;
      AContext.AssertEquals(1, RecordCount);
      AContext.AssertEquals('custom', FieldByName('name').AsString);
    end;
  finally
    lFixture.Free;
  end;
end;

procedure TestDataSourceNotifications(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
  lSource: TDataSource;
  lEvents: TNXSQLiteEvents;
  lBefore: Integer;
begin
  lFixture := TNXSQLiteFixture.Create;
  lSource := TDataSource.Create(nil);
  lEvents := TNXSQLiteEvents.Create;
  try
    lSource.DataSet := lFixture.DataSet;
    lSource.OnDataChange := @lEvents.DataChange;
    lSource.OnStateChange := @lEvents.StateChange;
    lFixture.DataSet.Open;
    AContext.AssertTrue(lEvents.Changes > 0);
    AContext.AssertTrue(lEvents.States > 0);
    lBefore := lEvents.Changes;
    lFixture.DataSet.DisableControls;
    lFixture.DataSet.Next;
    lFixture.DataSet.Last;
    AContext.AssertEquals(lBefore, lEvents.Changes);
    lFixture.DataSet.EnableControls;
    AContext.AssertTrue(lEvents.Changes > lBefore);
  finally
    lSource.Free;
    lFixture.Free;
    lEvents.Free;
  end;
end;

procedure TestConnectionAndLibraryLifetime(AContext: TNXTestContext);
var
  lFirst, lSecond: TNXSQLiteFixture;
  lFailed: Boolean;
begin
  lFirst := TNXSQLiteFixture.Create;
  lSecond := TNXSQLiteFixture.Create;
  try
    lFirst.DataSet.Open;
    lSecond.DataSet.Open;
    lFailed := False;
    try UnloadSQLite3 except on E: Exception do lFailed := True; end;
    AContext.AssertTrue(lFailed, 'Active connections must prevent unloading SQLite.');
    AContext.AssertTrue(LoadSQLite3(LibraryPath), 'Reloading the same leased library must keep existing handles valid.');
    lFirst.Connection.Close;
    AContext.AssertFalse(lFirst.DataSet.Active);
    lSecond.DataSet.Refresh;
    AContext.AssertEquals(3, lSecond.DataSet.RecordCount);
  finally
    lFirst.Free;
    lSecond.Free;
  end;
  AContext.AssertFalse(SQLite3IsLoaded, 'Last owned connection must release its library.');
end;

procedure TestRefreshAndBookmarkInvalidation(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
  lBookmark: TBookmark;
begin
  lFixture := TNXSQLiteFixture.Create;
  try
    with lFixture.DataSet do
    begin
      Open;
      Next;
      lBookmark := GetBookmark;
      try
        lFixture.Connection.Execute('UPDATE items SET name=''external'' WHERE id=2');
        Refresh;
        AContext.AssertEquals('external', FieldByName('name').AsString);
        AContext.AssertTrue(BookmarkValid(lBookmark));
        Delete;
        AContext.AssertFalse(BookmarkValid(lBookmark));
        Close;
        Open;
        AContext.AssertFalse(BookmarkValid(lBookmark), 'Bookmarks from an earlier open must stay invalid.');
      finally
        FreeBookmark(lBookmark);
      end;
    end;
  finally
    lFixture.Free;
  end;
end;

procedure TestTriggersAndQueryMembership(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
begin
  lFixture := TNXSQLiteFixture.Create;
  try
    lFixture.Connection.Execute('CREATE TRIGGER normalize_name AFTER UPDATE OF name ON items ' +
      'BEGIN UPDATE items SET name=upper(NEW.name) WHERE id=NEW.id; END');
    with lFixture.DataSet do
    begin
      SQL.Text := 'SELECT id AS identity,name,category FROM items WHERE category=10 ORDER BY name';
      Open;
      AContext.AssertTrue(CanModify, 'Column aliases must retain source identity.');
      AContext.AssertTrue(Locate('identity', 1, []));
      Edit;
      FieldByName('name').AsString := 'normalized';
      Post;
      AContext.AssertEquals('NORMALIZED', FieldByName('name').AsString);
      Edit;
      FieldByName('category').AsInteger := 20;
      Post;
      AContext.AssertEquals(1, RecordCount, 'A write must re-evaluate SQL WHERE membership.');
      AContext.AssertEquals('3', FieldByName('identity').AsString);
    end;
  finally
    lFixture.Free;
  end;
end;

procedure TestStaleWrites(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
  lFailed: Boolean;
begin
  lFixture := TNXSQLiteFixture.Create;
  try
    with lFixture.DataSet do
    begin
      Open;
      lFixture.Connection.Execute('UPDATE items SET name=''external'' WHERE id=1');
      Edit;
      FieldByName('category').AsInteger := 99;
      lFailed := False;
      try Post except on E: EDatabaseError do lFailed := True; end;
      AContext.AssertTrue(lFailed, 'A stale snapshot must not overwrite a changed row.');
      AContext.AssertTrue(State = dsEdit);
      Cancel;
      Refresh;
      AContext.AssertEquals('external', FieldByName('name').AsString);
      AContext.AssertEquals(10, FieldByName('category').AsInteger);
    end;
  finally
    lFixture.Free;
  end;
end;

procedure TestFindDirectionsAndFound(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
begin
  lFixture := TNXSQLiteFixture.Create;
  try
    with lFixture.DataSet do
    begin
      Open;
      Filter := 'category=10';
      AContext.AssertTrue(FindLast);
      AContext.AssertTrue(Found);
      AContext.AssertEquals(3, FieldByName('id').AsInteger);
      AContext.AssertTrue(FindPrior);
      AContext.AssertEquals(1, FieldByName('id').AsInteger);
      AContext.AssertFalse(FindPrior);
      AContext.AssertFalse(Found);
      AContext.AssertEquals(1, FieldByName('id').AsInteger);
      AContext.AssertTrue(FindFirst);
      AContext.AssertTrue(FindNext);
      AContext.AssertEquals(3, FieldByName('id').AsInteger);
      AContext.AssertFalse(FindNext);
      AContext.AssertFalse(Found);
    end;
  finally
    lFixture.Free;
  end;
end;

procedure TestDateTimeEditsAndLocate(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
  lStamp, lTime: TDateTime;
begin
  lFixture := TNXSQLiteFixture.Create;
  try
    lFixture.Connection.Execute('CREATE TABLE dates(id INTEGER PRIMARY KEY, day DATE, clock TIME, stamp DATETIME)');
    lFixture.Connection.Execute('INSERT INTO dates VALUES(1,''2024-02-29'',''12:34:56.789'',''2024-02-29T12:34:56.789'')');
    with lFixture.DataSet do
    begin
      SQL.Text := 'SELECT * FROM dates';
      Open;
      lTime := EncodeTime(12, 34, 56, 789);
      lStamp := EncodeDate(2024, 2, 29) + lTime;
      AContext.AssertTrue(Abs(FieldByName('clock').AsDateTime - lTime) < 1 / MSecsPerDay);
      AContext.AssertTrue(Abs(FieldByName('stamp').AsDateTime - lStamp) < 1 / MSecsPerDay);
      AContext.AssertTrue(Locate('day', VarFromDateTime(EncodeDate(2024, 2, 29)), []));
      Edit;
      FieldByName('day').AsDateTime := EncodeDate(2024, 2, 29);
      FieldByName('clock').AsDateTime := lTime;
      FieldByName('stamp').AsDateTime := lStamp;
      Post;
      AContext.AssertEquals('0', IntToStr(RowsAffected), 'Reassigning identical dates must not write a row.');
      lTime := EncodeTime(1, 2, 3, 456);
      lStamp := EncodeDate(2026, 10, 4) + lTime;
      Edit;
      FieldByName('day').AsDateTime := EncodeDate(2026, 10, 4);
      FieldByName('clock').AsDateTime := lTime;
      FieldByName('stamp').AsDateTime := lStamp;
      Post;
      AContext.AssertTrue(Locate('day', VarFromDateTime(EncodeDate(2026, 10, 4)), []));
      AContext.AssertTrue(Abs(FieldByName('clock').AsDateTime - lTime) < 1 / MSecsPerDay);
      AContext.AssertTrue(Abs(FieldByName('stamp').AsDateTime - lStamp) < 1 / MSecsPerDay);
    end;
  finally
    lFixture.Free;
  end;
end;

procedure TestPersistentBCDAndBooleanStorage(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
  lAmount: TBCDField;
  lFlag: TBooleanField;
  lCheck: TNXSQLiteDataSet;
  lCurrency: Currency;
begin
  lFixture := TNXSQLiteFixture.Create;
  lCheck := TNXSQLiteDataSet.Create(nil);
  try
    lAmount := TBCDField.Create(lFixture.DataSet);
    lAmount.FieldName := 'amount';
    lAmount.DataSet := lFixture.DataSet;
    lFlag := TBooleanField.Create(lFixture.DataSet);
    lFlag.FieldName := 'flag';
    lFlag.DataSet := lFixture.DataSet;
    lFixture.DataSet.Open;
    AContext.AssertTrue(lAmount.AsCurrency = 12.5);
    AContext.AssertTrue(lAmount.GetData(@lCurrency, False));
    AContext.AssertTrue(lCurrency = 12.5);
    lFixture.DataSet.Edit;
    lCurrency := 14.25;
    lAmount.SetData(@lCurrency, False);
    lFlag.AsBoolean := True;
    lFixture.DataSet.Post;
    AContext.AssertTrue(lAmount.AsCurrency = 14.25);
    AContext.AssertTrue(lFlag.AsBoolean);
    lCheck.Connection := lFixture.Connection;
    lCheck.SQL.Text := 'SELECT count(*) AS matched FROM items WHERE id=1 AND amount=14.25 AND flag=1';
    lCheck.Open;
    AContext.AssertEquals(1, lCheck.FieldByName('matched').AsInteger);
  finally
    lCheck.Free;
    lFixture.Free;
  end;
end;

procedure TestBinaryTextKeysAndOrdering(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
  lReference: TNXSQLiteDataSet;
begin
  lFixture := TNXSQLiteFixture.Create;
  lReference := TNXSQLiteDataSet.Create(nil);
  try
    lFixture.Connection.Execute('CREATE TABLE textkeys(key VARCHAR(80) PRIMARY KEY, value INTEGER)');
    lFixture.Connection.Execute('INSERT INTO textkeys VALUES(''a'',1),(''A'',2),(''é'',3),(''é'',4),('''',5)');
    with lFixture.DataSet do
    begin
      SQL.Text := 'SELECT * FROM textkeys ORDER BY value';
      Open;
      AContext.AssertTrue(CanModify, 'Binary-distinct text keys must remain distinct.');
      AContext.AssertTrue(Locate('key', 'é', []));
      Edit;
      FieldByName('value').AsInteger := 30;
      Post;
      AContext.AssertEquals(30, FieldByName('value').AsInteger);
      AContext.AssertTrue(Locate('key', 'é', []));
      AContext.AssertEquals(4, FieldByName('value').AsInteger);
      IndexFieldNames := 'key DESC';
      First;
      lReference.Connection := lFixture.Connection;
      lReference.SQL.Text := 'SELECT * FROM textkeys ORDER BY key COLLATE BINARY DESC';
      lReference.Open;
      while not lReference.EOF do
      begin
        AContext.AssertFalse(EOF);
        AContext.AssertEquals(lReference.FieldByName('value').AsInteger, FieldByName('value').AsInteger);
        Next;
        lReference.Next;
      end;
      AContext.AssertTrue(EOF);
    end;
  finally
    lReference.Free;
    lFixture.Free;
  end;
end;

procedure TestConvenienceInsertsAndUnicodeIdentifiers(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
begin
  lFixture := TNXSQLiteFixture.Create;
  try
    lFixture.Connection.Execute('CREATE TABLE "é数据" ("clé" INTEGER PRIMARY KEY, "名称" VARCHAR(80))');
    with lFixture.DataSet do
    begin
      SQL.Text := 'SELECT * FROM "é数据" ORDER BY "clé"';
      Open;
      AppendRecord([1, 'first']);
      InsertRecord([2, 'second']);
      AContext.AssertEquals(2, RecordCount);
      AContext.AssertTrue(Locate(UTF8Text('clé'), 1, []));
      Edit;
      FieldByName(UTF8Text('名称')).AsString := 'changed';
      Post;
      AContext.AssertEquals('changed', FieldByName(UTF8Text('名称')).AsString);
      Delete;
      AContext.AssertEquals(1, RecordCount);
    end;
  finally
    lFixture.Free;
  end;
end;

procedure TestProviderOrderAndAmbiguousBookmarks(AContext: TNXTestContext);
var
  lFixture: TNXSQLiteFixture;
  lDataSet: TNXSQLiteProviderTestDataSet;
  lBookmark: TBookmark;
begin
  lFixture := TNXSQLiteFixture.Create;
  lDataSet := TNXSQLiteProviderTestDataSet.Create(nil);
  try
    lDataSet.Connection := lFixture.Connection;
    lDataSet.SQL.Text := 'SELECT * FROM items ORDER BY name';
    lDataSet.Open;
    AContext.AssertEquals('id', lDataSet.ProviderKeyFields);
    AContext.AssertTrue(lDataSet.ProviderDefaultOrder = nil,
      'A primary key definition does not prove the query order.');
    lDataSet.IndexFieldNames := 'category ASC;id DESC';
    AContext.AssertTrue(lDataSet.ProviderDefaultOrder <> nil);
    AContext.AssertEquals('category;id', lDataSet.ProviderDefaultOrder.Fields);
    AContext.AssertEquals('id', lDataSet.ProviderDefaultOrder.DescFields);
    AContext.AssertTrue(lDataSet.IsLocalIndexField(lDataSet.FieldByName('category')));
    AContext.AssertTrue(lDataSet.IsLocalIndexField(lDataSet.FieldByName('id')));
    AContext.AssertFalse(lDataSet.IsLocalIndexField(lDataSet.FieldByName('name')));
    lDataSet.Close;
    lDataSet.IndexFieldNames := '';
    lDataSet.SQL.Text := 'SELECT id,name,category FROM items UNION ALL ' +
      'SELECT id,name,category FROM items WHERE category=99';
    lDataSet.Open;
    lBookmark := lDataSet.GetBookmark;
    try
      lFixture.Connection.Execute('UPDATE items SET category=99 WHERE id=1');
      lDataSet.Refresh;
      AContext.AssertFalse(lDataSet.CanModify);
      AContext.AssertEquals('', lDataSet.ProviderKeyFields);
      AContext.AssertFalse(lDataSet.BookmarkValid(lBookmark),
        'An ambiguous key must not preserve a bookmark for the wrong row.');
    finally
      lDataSet.FreeBookmark(lBookmark);
    end;
    AContext.AssertEquals(4, lDataSet.RecordCount);
    lDataSet.Close;
    lFixture.Connection.Execute('UPDATE items SET category=10 WHERE id=1');
    lDataSet.Open;
    AContext.AssertTrue(lDataSet.CanModify);
    lDataSet.Edit;
    lDataSet.FieldByName('category').AsInteger := 99;
    lDataSet.Post;
    AContext.AssertFalse(lDataSet.CanModify, 'Post must recheck the new query identity.');
    AContext.AssertEquals('', lDataSet.ProviderKeyFields);
    AContext.AssertEquals(4, lDataSet.RecordCount);
  finally
    lDataSet.Free;
    lFixture.Free;
  end;
end;

procedure RegisterNXSQLiteTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('Foundation.SQLite.DataSet');
  lSuite.AddTest('Navigation', @TestNavigation);
  lSuite.AddTest('EmptyAndReopen', @TestEmptyAndReopen);
  lSuite.AddTest('WritesDefaultsAndCancel', @TestWritesDefaultsAndCancel);
  lSuite.AddTest('FailedPost', @TestFailedPost);
  lSuite.AddTest('TransactionRollback', @TestTransactionRollback);
  lSuite.AddTest('BlobsAndUnicode', @TestBlobsAndUnicode);
  lSuite.AddTest('FilterLocateLookup', @TestFilterLocateLookup);
  lSuite.AddTest('CompositeKeys', @TestCompositeKeys);
  lSuite.AddTest('PersistentCalculatedAndLookupFields', @TestPersistentCalculatedAndLookupFields);
  lSuite.AddTest('MasterDetail', @TestMasterDetail);
  lSuite.AddTest('FieldTypesAndLargeKeys', @TestFieldTypesAndLargeKeys);
  lSuite.AddTest('ReadOnlyAndQueryIdentity', @TestReadOnlyAndQueryIdentity);
  lSuite.AddTest('CustomSQLAndExecSQL', @TestCustomSQLAndExecSQL);
  lSuite.AddTest('DataSourceNotifications', @TestDataSourceNotifications);
  lSuite.AddTest('ConnectionAndLibraryLifetime', @TestConnectionAndLibraryLifetime);
  lSuite.AddTest('RefreshAndBookmarkInvalidation', @TestRefreshAndBookmarkInvalidation);
  lSuite.AddTest('TriggersAndQueryMembership', @TestTriggersAndQueryMembership);
  lSuite.AddTest('StaleWrites', @TestStaleWrites);
  lSuite.AddTest('FindDirectionsAndFound', @TestFindDirectionsAndFound);
  lSuite.AddTest('DateTimeEditsAndLocate', @TestDateTimeEditsAndLocate);
  lSuite.AddTest('PersistentBCDAndBooleanStorage', @TestPersistentBCDAndBooleanStorage);
  lSuite.AddTest('BinaryTextKeysAndOrdering', @TestBinaryTextKeysAndOrdering);
  lSuite.AddTest('ConvenienceInsertsAndUnicodeIdentifiers', @TestConvenienceInsertsAndUnicodeIdentifiers);
  lSuite.AddTest('ProviderOrderAndAmbiguousBookmarks', @TestProviderOrderAndAmbiguousBookmarks);
end;

end.

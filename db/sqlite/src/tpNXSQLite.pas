(*
  Copyright (c) 2026 Kevin Collins.
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)
unit tpNXSQLite;

{$mode objfpc}{$H+}

interface

uses DB;

type
  TNXSQLiteColumn = record
    Name: string;
    DatabaseName: string;
    TableName: string;
    OriginName: string;
    DeclaredType: string;
    DataType: TFieldType;
    Size: Integer;
    PrimaryKey: Integer;
    Generated: Boolean;
  end;

  TNXSQLiteBookmark = record
    DataSet: Pointer;
    RowID: QWord;
  end;
  PNXSQLiteBookmark = ^TNXSQLiteBookmark;

implementation

end.

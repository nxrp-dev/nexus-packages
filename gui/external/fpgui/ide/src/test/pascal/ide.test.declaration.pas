{
    fpGUI IDE - Go to Declaration Tests

    Tests for identifier resolution and Go to Declaration functionality.
}
unit ide.test.declaration;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  ide.highlighter,
  ide.declaration;

type

  { TTestDeclaration }

  TTestDeclaration = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FHL: TPascalHighlighter;
    FLines: TStringList;
    FTempDir: string;
    procedure SetSource(const ASource: string);
    procedure WriteTempUnit(const AUnitName, ASource: string);
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    { Phase A -- Identifier extraction }
    procedure TestGetIdentAtCursor_OnIdentifier;
    procedure TestGetIdentAtCursor_OnKeyword;
    procedure TestGetIdentAtCursor_OnWhitespace;
    procedure TestGetIdentAtCursor_StartOfIdent;
    procedure TestGetIdentAtCursor_EndOfIdent;
    { Phase B -- Single-unit resolution }
    procedure TestFindDecl_LocalVar;
    procedure TestFindDecl_ProcParam;
    procedure TestFindDecl_TypeName;
    procedure TestFindDecl_ClassMethod;
    procedure TestFindDecl_OverloadedProc;
    procedure TestFindDecl_DottedExpr;
    procedure TestFindDecl_SameIdentTwiceOnLine;
    procedure TestFindDecl_NotAnIdent;
    procedure TestFindDecl_ParseError;
    { Phase C -- Cross-unit resolution }
    procedure TestFindDecl_CrossUnit_Type;
    procedure TestFindDecl_CrossUnit_Proc;
    procedure TestFindDecl_UnitNotFound;
    { Phase D -- Edge cases }
    procedure TestFindDecl_EmptySource;
    procedure TestFindDecl_ConstRef;
    procedure TestFindDecl_ProgramName;
    procedure TestFindDecl_CircularUses;
    { Phase E -- Uses unit navigation (Ctrl+B on unit name) }
    procedure TestFindDecl_UsesUnit_Simple;
    procedure TestFindDecl_UsesUnit_Dotted;
    procedure TestFindDecl_UsesUnit_SecondInList;
    procedure TestFindDecl_UsesUnit_NotFound;
  end;


procedure RegisteridetestdeclarationTests(ARegistry: TNXTestRegistry);

implementation

const
  cSimpleProgram =
    'program Test;'              + LineEnding +   // 0
    'begin'                      + LineEnding +   // 1
    '  WriteLn(''hello'');'      + LineEnding +   // 2
    'end.';                                        // 3

  cVarProgram =
    'program Test;'              + LineEnding +   // 0
    'var'                        + LineEnding +   // 1
    '  MyCounter: Integer;'      + LineEnding +   // 2
    'begin'                      + LineEnding +   // 3
    '  MyCounter := 1;'          + LineEnding +   // 4
    'end.';                                        // 5

  { Phase B test sources }

  cLocalVar =
    'program Test;'              + LineEnding +   // 0
    '{$mode objfpc}{$H+}'       + LineEnding +   // 1
    'var'                        + LineEnding +   // 2
    '  x: Integer;'              + LineEnding +   // 3
    'begin'                      + LineEnding +   // 4
    '  x := 1;'                  + LineEnding +   // 5
    'end.';                                        // 6

  cProcParam =
    'program Test;'              + LineEnding +   // 0
    '{$mode objfpc}{$H+}'       + LineEnding +   // 1
    'procedure DoIt(AValue: Integer);' + LineEnding + // 2
    'begin'                      + LineEnding +   // 3
    '  AValue := 0;'             + LineEnding +   // 4 -- AValue ref, col 2
    'end;'                       + LineEnding +   // 5
    'begin'                      + LineEnding +   // 6
    'end.';                                        // 7

  cTypeName =
    'program Test;'              + LineEnding +   // 0
    '{$mode objfpc}{$H+}'       + LineEnding +   // 1
    'type'                       + LineEnding +   // 2
    '  TMyRecord = record'       + LineEnding +   // 3
    '    Value: Integer;'        + LineEnding +   // 4
    '  end;'                     + LineEnding +   // 5
    'var'                        + LineEnding +   // 6
    '  r: TMyRecord;'            + LineEnding +   // 7
    'begin'                      + LineEnding +   // 8
    '  r.Value := 42;'           + LineEnding +   // 9 -- Value ref, col 4
    'end.';                                        // 10

  cClassMethod =
    'program Test;'              + LineEnding +   // 0
    '{$mode objfpc}{$H+}'       + LineEnding +   // 1
    'type'                       + LineEnding +   // 2
    '  TFoo = object'            + LineEnding +   // 3
    '    procedure DoWork;'      + LineEnding +   // 4
    '  end;'                     + LineEnding +   // 5
    'procedure TFoo.DoWork;'     + LineEnding +   // 6
    'begin'                      + LineEnding +   // 7
    'end;'                       + LineEnding +   // 8
    'var'                        + LineEnding +   // 9
    '  f: TFoo;'                 + LineEnding +   // 10
    'begin'                      + LineEnding +   // 11
    '  f.DoWork;'                + LineEnding +   // 12 -- DoWork ref, col 4
    'end.';                                        // 13

  cOverloaded =
    'program Test;'              + LineEnding +   // 0
    '{$mode objfpc}{$H+}'       + LineEnding +   // 1
    'procedure Calc(A: Integer); overload;' + LineEnding + // 2
    'begin'                      + LineEnding +   // 3
    'end;'                       + LineEnding +   // 4
    'procedure Calc(A: String); overload;' + LineEnding + // 5
    'begin'                      + LineEnding +   // 6
    'end;'                       + LineEnding +   // 7
    'begin'                      + LineEnding +   // 8
    '  Calc(42);'                + LineEnding +   // 9  -- resolves to Integer overload (line 2)
    '  Calc(''hi'');'            + LineEnding +   // 10 -- resolves to String overload (line 5)
    'end.';                                        // 11

  cDottedExpr =
    'program Test;'              + LineEnding +   // 0
    '{$mode objfpc}{$H+}'       + LineEnding +   // 1
    'type'                       + LineEnding +   // 2
    '  TFoo = object'            + LineEnding +   // 3
    '    FField: Integer;'       + LineEnding +   // 4
    '    procedure Go;'          + LineEnding +   // 5
    '  end;'                     + LineEnding +   // 6
    'procedure TFoo.Go;'         + LineEnding +   // 7
    'begin'                      + LineEnding +   // 8
    '  Self.FField := 1;'        + LineEnding +   // 9 -- FField ref, col 7
    'end;'                       + LineEnding +   // 10
    'begin'                      + LineEnding +   // 11
    'end.';                                        // 12

  cSameIdentTwice =
    'program Test;'              + LineEnding +   // 0
    '{$mode objfpc}{$H+}'       + LineEnding +   // 1
    'var'                        + LineEnding +   // 2
    '  x: Integer;'              + LineEnding +   // 3
    'begin'                      + LineEnding +   // 4
    '  x := x + 1;'             + LineEnding +   // 5 -- both x resolve to line 3
    'end.';                                        // 6

  cBrokenSyntax =
    'program Test;'              + LineEnding +   // 0
    'begin'                      + LineEnding +   // 1
    '  x := ;'                   + LineEnding +   // 2
    'end.';                                        // 3


{ TTestDeclaration }

procedure TTestDeclaration.SetSource(const ASource: string);
begin
  FLines.Text := ASource;
  FHL.Tokenise(ASource);
end;

procedure TTestDeclaration.WriteTempUnit(const AUnitName, ASource: string);
var
  sl: TStringList;
begin
  if FTempDir = '' then
  begin
    FTempDir := IncludeTrailingPathDelimiter(GetTempDir) + 'fpgui_decl_test';
    ForceDirectories(FTempDir);
  end;
  sl := TStringList.Create;
  try
    sl.Text := ASource;
    sl.SaveToFile(IncludeTrailingPathDelimiter(FTempDir) + AUnitName + '.pas');
  finally
    sl.Free;
  end;
end;

procedure TTestDeclaration.SetUp;
begin
  FHL := TPascalHighlighter.Create;
  FLines := TStringList.Create;
  FTempDir := '';
end;

procedure TTestDeclaration.TearDown;
var
  sr: TSearchRec;
begin
  FLines.Free;
  FHL.Free;
  { Clean up any temp files }
  if FTempDir <> '' then
  begin
    if FindFirst(IncludeTrailingPathDelimiter(FTempDir) + '*', faAnyFile, sr) = 0 then
    begin
      repeat
        if (sr.Name <> '.') and (sr.Name <> '..') then
          DeleteFile(IncludeTrailingPathDelimiter(FTempDir) + sr.Name);
      until FindNext(sr) <> 0;
      FindClose(sr);
    end;
    RemoveDir(FTempDir);
  end;
end;

procedure TTestDeclaration.TestGetIdentAtCursor_OnIdentifier;
begin
  SetSource(cSimpleProgram);
  // Line 2: '  WriteLn(''hello'');'  -- WriteLn starts at column 2
  TestContext.AssertTrue(('WriteLn')=(GetIdentifierAtCursor(FHL, FLines, 2, 4)), 'Cursor in middle of WriteLn should return WriteLn');
end;

procedure TTestDeclaration.TestGetIdentAtCursor_OnKeyword;
begin
  SetSource(cSimpleProgram);
  // Line 1: 'begin' -- keyword, not an identifier
  TestContext.AssertTrue(('')=(GetIdentifierAtCursor(FHL, FLines, 1, 2)), 'Cursor on keyword begin should return empty');
end;

procedure TTestDeclaration.TestGetIdentAtCursor_OnWhitespace;
begin
  SetSource(cSimpleProgram);
  // Line 2: '  WriteLn(''hello'');' -- column 0 is whitespace
  TestContext.AssertTrue(('')=(GetIdentifierAtCursor(FHL, FLines, 2, 0)), 'Cursor on whitespace should return empty');
end;

procedure TTestDeclaration.TestGetIdentAtCursor_StartOfIdent;
begin
  SetSource(cVarProgram);
  // Line 4: '  MyCounter := 1;'  -- MyCounter starts at column 2
  TestContext.AssertTrue(('MyCounter')=(GetIdentifierAtCursor(FHL, FLines, 4, 2)), 'Cursor at first char of MyCounter should return MyCounter');
end;

procedure TTestDeclaration.TestGetIdentAtCursor_EndOfIdent;
begin
  SetSource(cVarProgram);
  // Line 4: '  MyCounter := 1;'  -- MyCounter ends at column 10
  TestContext.AssertTrue(('MyCounter')=(GetIdentifierAtCursor(FHL, FLines, 4, 10)), 'Cursor at last char of MyCounter should return MyCounter');
end;


{ Phase B -- Single-unit resolution }

procedure TTestDeclaration.TestFindDecl_LocalVar;
var
  decl: TDeclarationResult;
begin
  SetSource(cLocalVar);
  // Line 5: '  x := 1;' -- x at col 2, declared on line 3 (0-based) = line 4 (1-based)
  decl := FindDeclaration(FHL, FLines, 'test.pas', 5, 2, nil, nil);
  TestContext.AssertTrue(decl.Found, 'Should find local var declaration');
  TestContext.AssertTrue((4)=(decl.DeclLine), 'x declared on 1-based line 4');
end;

procedure TTestDeclaration.TestFindDecl_ProcParam;
var
  decl: TDeclarationResult;
begin
  SetSource(cProcParam);
  // Line 4: '  AValue := 0;' -- AValue at col 2, declared on line 2 (0-based) = line 3 (1-based)
  decl := FindDeclaration(FHL, FLines, 'test.pas', 4, 2, nil, nil);
  TestContext.AssertTrue(decl.Found, 'Should find proc param declaration');
  TestContext.AssertTrue((3)=(decl.DeclLine), 'AValue declared on 1-based line 3');
end;

procedure TTestDeclaration.TestFindDecl_TypeName;
var
  decl: TDeclarationResult;
begin
  SetSource(cTypeName);
  // Line 9: '  r.Value := 42;' -- Value at col 4, declared on line 4 (0-based) = line 5 (1-based)
  decl := FindDeclaration(FHL, FLines, 'test.pas', 9, 4, nil, nil);
  TestContext.AssertTrue(decl.Found, 'Should find record field declaration');
  TestContext.AssertTrue((5)=(decl.DeclLine), 'Value declared on 1-based line 5');
end;

procedure TTestDeclaration.TestFindDecl_ClassMethod;
var
  decl: TDeclarationResult;
begin
  SetSource(cClassMethod);
  // Line 12: '  f.DoWork;' -- DoWork at col 4, declared on line 4 (0-based) = line 5 (1-based)
  decl := FindDeclaration(FHL, FLines, 'test.pas', 12, 4, nil, nil);
  TestContext.AssertTrue(decl.Found, 'Should find class method declaration');
  TestContext.AssertTrue((5)=(decl.DeclLine), 'DoWork declared on 1-based line 5');
end;

procedure TTestDeclaration.TestFindDecl_OverloadedProc;
var
  decl: TDeclarationResult;
begin
  SetSource(cOverloaded);
  // Line 9: '  Calc(42);' -- Calc at col 2, should resolve to Integer overload (line 2, 0-based) = line 3 (1-based)
  decl := FindDeclaration(FHL, FLines, 'test.pas', 9, 2, nil, nil);
  TestContext.AssertTrue(decl.Found, 'Should find overloaded proc (Integer)');
  TestContext.AssertTrue((3)=(decl.DeclLine), 'Calc(Integer) declared on 1-based line 3');
end;

procedure TTestDeclaration.TestFindDecl_DottedExpr;
var
  decl: TDeclarationResult;
begin
  SetSource(cDottedExpr);
  // Line 9: '  Self.FField := 1;' -- FField at col 7, declared on line 4 (0-based) = line 5 (1-based)
  decl := FindDeclaration(FHL, FLines, 'test.pas', 9, 7, nil, nil);
  TestContext.AssertTrue(decl.Found, 'Should find field declaration via Self.FField');
  TestContext.AssertTrue((5)=(decl.DeclLine), 'FField declared on 1-based line 5');
end;

procedure TTestDeclaration.TestFindDecl_SameIdentTwiceOnLine;
var
  decl1, decl2: TDeclarationResult;
begin
  SetSource(cSameIdentTwice);
  // Line 5: '  x := x + 1;' -- first x at col 2, second x at col 7
  decl1 := FindDeclaration(FHL, FLines, 'test.pas', 5, 2, nil, nil);
  decl2 := FindDeclaration(FHL, FLines, 'test.pas', 5, 7, nil, nil);
  TestContext.AssertTrue(decl1.Found, 'First x should resolve');
  TestContext.AssertTrue(decl2.Found, 'Second x should resolve');
  TestContext.AssertTrue((decl1.DeclLine)=(decl2.DeclLine), 'Both x should resolve to same decl line');
  TestContext.AssertTrue((4)=(decl1.DeclLine), 'x declared on 1-based line 4');
end;

procedure TTestDeclaration.TestFindDecl_NotAnIdent;
var
  decl: TDeclarationResult;
begin
  SetSource(cLocalVar);
  // Line 4: 'begin' -- keyword, not an identifier
  decl := FindDeclaration(FHL, FLines, 'test.pas', 4, 2, nil, nil);
  TestContext.AssertTrue(not (decl.Found), 'Cursor on keyword should not find declaration');
end;

procedure TTestDeclaration.TestFindDecl_ParseError;
var
  decl: TDeclarationResult;
begin
  SetSource(cBrokenSyntax);
  // Line 2: '  x := ;' -- broken syntax, should not crash
  decl := FindDeclaration(FHL, FLines, 'test.pas', 2, 2, nil, nil);
  TestContext.AssertTrue(not (decl.Found), 'Broken syntax should return Found=False, no exception');
end;


{ Phase C -- Cross-unit resolution }

procedure TTestDeclaration.TestFindDecl_CrossUnit_Type;
var
  decl: TDeclarationResult;
  unitPaths: TStringList;
  mainSrc: string;
begin
  { Write dependency unit to temp dir }
  WriteTempUnit('HelperUnit',
    'unit HelperUnit;'             + LineEnding +
    '{$mode objfpc}{$H+}'        + LineEnding +
    'interface'                    + LineEnding +
    'type'                         + LineEnding +
    '  TMyHelper = record'         + LineEnding +   // line 5 (1-based)
    '    Value: Integer;'          + LineEnding +
    '  end;'                       + LineEnding +
    'implementation'               + LineEnding +
    'end.');

  { Main program uses the type from HelperUnit }
  mainSrc :=
    'program Test;'                + LineEnding +   // 0
    '{$mode objfpc}{$H+}'        + LineEnding +   // 1
    'uses HelperUnit;'             + LineEnding +   // 2
    'var'                          + LineEnding +   // 3
    '  h: TMyHelper;'             + LineEnding +   // 4
    'begin'                        + LineEnding +   // 5
    '  h.Value := 1;'             + LineEnding +   // 6 -- Value ref, col 4
    'end.';
  SetSource(mainSrc);

  unitPaths := TStringList.Create;
  try
    unitPaths.Add(FTempDir);
    decl := FindDeclaration(FHL, FLines, 'test.pas', 6, 4, unitPaths, nil);
    TestContext.AssertTrue(decl.Found, 'Should find type member from cross-unit');
    TestContext.AssertTrue((6)=(decl.DeclLine), 'Value declared on 1-based line 6 of HelperUnit');
    TestContext.AssertTrue(Pos('HelperUnit', decl.DeclFile) > 0, 'DeclFile should reference HelperUnit');
  finally
    unitPaths.Free;
  end;
end;

procedure TTestDeclaration.TestFindDecl_CrossUnit_Proc;
var
  decl: TDeclarationResult;
  unitPaths: TStringList;
  mainSrc: string;
begin
  { Write dependency unit with a procedure }
  WriteTempUnit('MathUtils',
    'unit MathUtils;'              + LineEnding +
    '{$mode objfpc}{$H+}'        + LineEnding +
    'interface'                    + LineEnding +
    'function AddTwo(A: Integer): Integer;' + LineEnding +  // line 4 (1-based)
    'implementation'               + LineEnding +
    'function AddTwo(A: Integer): Integer;' + LineEnding +
    'begin'                        + LineEnding +
    '  Result := A + 2;'          + LineEnding +
    'end;'                         + LineEnding +
    'end.');

  { Main program calls the function }
  mainSrc :=
    'program Test;'                + LineEnding +   // 0
    '{$mode objfpc}{$H+}'        + LineEnding +   // 1
    'uses MathUtils;'              + LineEnding +   // 2
    'var'                          + LineEnding +   // 3
    '  x: Integer;'                + LineEnding +   // 4
    'begin'                        + LineEnding +   // 5
    '  x := AddTwo(5);'           + LineEnding +   // 6 -- AddTwo ref, col 7
    'end.';
  SetSource(mainSrc);

  unitPaths := TStringList.Create;
  try
    unitPaths.Add(FTempDir);
    decl := FindDeclaration(FHL, FLines, 'test.pas', 6, 7, unitPaths, nil);
    TestContext.AssertTrue(decl.Found, 'Should find proc from cross-unit');
    TestContext.AssertTrue((4)=(decl.DeclLine), 'AddTwo declared on 1-based line 4 of MathUtils');
    TestContext.AssertTrue(Pos('MathUtils', decl.DeclFile) > 0, 'DeclFile should reference MathUtils');
  finally
    unitPaths.Free;
  end;
end;

procedure TTestDeclaration.TestFindDecl_UnitNotFound;
var
  decl: TDeclarationResult;
  mainSrc: string;
begin
  { Program uses a non-existent unit -- should fail gracefully }
  mainSrc :=
    'program Test;'                + LineEnding +   // 0
    '{$mode objfpc}{$H+}'        + LineEnding +   // 1
    'uses NonExistentUnit;'        + LineEnding +   // 2
    'begin'                        + LineEnding +   // 3
    'end.';
  SetSource(mainSrc);

  decl := FindDeclaration(FHL, FLines, 'test.pas', 3, 2, nil, nil);
  TestContext.AssertTrue(not (decl.Found), 'Missing unit should return Found=False gracefully');
end;


{ Phase D -- Edge cases }

procedure TTestDeclaration.TestFindDecl_EmptySource;
var
  decl: TDeclarationResult;
begin
  SetSource('');
  decl := FindDeclaration(FHL, FLines, 'test.pas', 0, 0, nil, nil);
  TestContext.AssertTrue(not (decl.Found), 'Empty source should return Found=False gracefully');
end;

procedure TTestDeclaration.TestFindDecl_ConstRef;
const
  cConstSrc =
    'program Test;'              + LineEnding +   // 0
    '{$mode objfpc}{$H+}'       + LineEnding +   // 1
    'const'                      + LineEnding +   // 2
    '  MaxItems = 100;'          + LineEnding +   // 3
    'var'                        + LineEnding +   // 4
    '  n: Integer;'              + LineEnding +   // 5
    'begin'                      + LineEnding +   // 6
    '  n := MaxItems;'           + LineEnding +   // 7 -- MaxItems ref, col 7
    'end.';
var
  decl: TDeclarationResult;
begin
  SetSource(cConstSrc);
  decl := FindDeclaration(FHL, FLines, 'test.pas', 7, 7, nil, nil);
  TestContext.AssertTrue(decl.Found, 'Should find const declaration');
  TestContext.AssertTrue((4)=(decl.DeclLine), 'MaxItems declared on 1-based line 4');
  TestContext.AssertTrue(('MaxItems')=(decl.DeclName), 'DeclName should be MaxItems');
end;

procedure TTestDeclaration.TestFindDecl_ProgramName;
const
  cProgSrc =
    'program MyApp;'             + LineEnding +   // 0
    '{$mode objfpc}{$H+}'       + LineEnding +   // 1
    'begin'                      + LineEnding +   // 2
    'end.';
var
  decl: TDeclarationResult;
begin
  SetSource(cProgSrc);
  { Cursor on 'MyApp' in program declaration -- this is the declaration itself,
    not a reference, so there is no resolved reference to follow }
  decl := FindDeclaration(FHL, FLines, 'test.pas', 0, 10, nil, nil);
  TestContext.AssertTrue(not (decl.Found), 'Program name is not a reference -- should return Found=False');
end;

procedure TTestDeclaration.TestFindDecl_CircularUses;
var
  decl: TDeclarationResult;
  unitPaths: TStringList;
  mainSrc: string;
begin
  { UnitA uses UnitB, UnitB uses UnitA -- circular dependency }
  WriteTempUnit('UnitA',
    'unit UnitA;'                  + LineEnding +
    '{$mode objfpc}{$H+}'        + LineEnding +
    'interface'                    + LineEnding +
    'uses UnitB;'                  + LineEnding +
    'type'                         + LineEnding +
    '  TThingA = record'           + LineEnding +   // line 6 (1-based)
    '    Name: Integer;'           + LineEnding +
    '  end;'                       + LineEnding +
    'implementation'               + LineEnding +
    'end.');

  WriteTempUnit('UnitB',
    'unit UnitB;'                  + LineEnding +
    '{$mode objfpc}{$H+}'        + LineEnding +
    'interface'                    + LineEnding +
    'uses UnitA;'                  + LineEnding +
    'var'                          + LineEnding +
    '  GlobalB: Integer;'          + LineEnding +   // line 6 (1-based)
    'implementation'               + LineEnding +
    'end.');

  { Main program uses UnitA -- should not hang or crash due to circular uses }
  mainSrc :=
    'program Test;'                + LineEnding +   // 0
    '{$mode objfpc}{$H+}'        + LineEnding +   // 1
    'uses UnitA;'                  + LineEnding +   // 2
    'var'                          + LineEnding +   // 3
    '  a: TThingA;'               + LineEnding +   // 4
    'begin'                        + LineEnding +   // 5
    'end.';
  SetSource(mainSrc);

  unitPaths := TStringList.Create;
  try
    unitPaths.Add(FTempDir);
    { The circular use guard should prevent infinite recursion.
      We don't require it to fully resolve -- just that it doesn't crash. }
    decl := FindDeclaration(FHL, FLines, 'test.pas', 4, 5, unitPaths, nil);
    { Result may or may not be Found depending on how deep resolution gets,
      but the key assertion is that we reach this point without hanging. }
    TestContext.AssertTrue(True, 'Circular uses did not hang or crash');
  finally
    unitPaths.Free;
  end;
end;


{ Phase E -- Uses unit navigation }

procedure TTestDeclaration.TestFindDecl_UsesUnit_Simple;
var
  decl: TDeclarationResult;
  unitPaths: TStringList;
  mainSrc: string;
begin
  WriteTempUnit('HelperUnit',
    'unit HelperUnit;'             + LineEnding +
    '{$mode objfpc}{$H+}'        + LineEnding +
    'interface'                    + LineEnding +
    'implementation'               + LineEnding +
    'end.');

  mainSrc :=
    'program Test;'                + LineEnding +   // 0
    '{$mode objfpc}{$H+}'        + LineEnding +   // 1
    'uses HelperUnit;'             + LineEnding +   // 2 -- HelperUnit at col 5
    'begin'                        + LineEnding +   // 3
    'end.';
  SetSource(mainSrc);

  unitPaths := TStringList.Create;
  try
    unitPaths.Add(FTempDir);
    decl := FindDeclaration(FHL, FLines, 'test.pas', 2, 7, unitPaths, nil);
    TestContext.AssertTrue(decl.Found, 'Should find unit file for HelperUnit');
    TestContext.AssertTrue((1)=(decl.DeclLine), 'Should navigate to line 1 of the unit');
    TestContext.AssertTrue(Pos('HelperUnit', decl.DeclFile) > 0, 'DeclFile should reference HelperUnit');
  finally
    unitPaths.Free;
  end;
end;

procedure TTestDeclaration.TestFindDecl_UsesUnit_Dotted;
var
  decl: TDeclarationResult;
  unitPaths: TStringList;
  mainSrc: string;
begin
  WriteTempUnit('my.helper.utils',
    'unit my.helper.utils;'        + LineEnding +
    '{$mode objfpc}{$H+}'        + LineEnding +
    'interface'                    + LineEnding +
    'implementation'               + LineEnding +
    'end.');

  mainSrc :=
    'program Test;'                + LineEnding +   // 0
    '{$mode objfpc}{$H+}'        + LineEnding +   // 1
    'uses my.helper.utils;'        + LineEnding +   // 2 -- cursor on 'helper' at col 8
    'begin'                        + LineEnding +   // 3
    'end.';
  SetSource(mainSrc);

  unitPaths := TStringList.Create;
  try
    unitPaths.Add(FTempDir);
    // Cursor on middle part 'helper' of the dotted name
    decl := FindDeclaration(FHL, FLines, 'test.pas', 2, 8, unitPaths, nil);
    TestContext.AssertTrue(decl.Found, 'Should find unit file for dotted unit name');
    TestContext.AssertTrue((1)=(decl.DeclLine), 'Should navigate to line 1 of the unit');
    TestContext.AssertTrue(Pos('my.helper.utils', decl.DeclFile) > 0, 'DeclFile should reference my.helper.utils');
  finally
    unitPaths.Free;
  end;
end;

procedure TTestDeclaration.TestFindDecl_UsesUnit_SecondInList;
var
  decl: TDeclarationResult;
  unitPaths: TStringList;
  mainSrc: string;
begin
  WriteTempUnit('UnitAlpha',
    'unit UnitAlpha;'              + LineEnding +
    '{$mode objfpc}{$H+}'        + LineEnding +
    'interface'                    + LineEnding +
    'implementation'               + LineEnding +
    'end.');
  WriteTempUnit('UnitBeta',
    'unit UnitBeta;'               + LineEnding +
    '{$mode objfpc}{$H+}'        + LineEnding +
    'interface'                    + LineEnding +
    'implementation'               + LineEnding +
    'end.');

  mainSrc :=
    'program Test;'                + LineEnding +   // 0
    '{$mode objfpc}{$H+}'        + LineEnding +   // 1
    'uses UnitAlpha, UnitBeta;'    + LineEnding +   // 2 -- UnitBeta at col 16
    'begin'                        + LineEnding +   // 3
    'end.';
  SetSource(mainSrc);

  unitPaths := TStringList.Create;
  try
    unitPaths.Add(FTempDir);
    decl := FindDeclaration(FHL, FLines, 'test.pas', 2, 18, unitPaths, nil);
    TestContext.AssertTrue(decl.Found, 'Should find second unit in uses list');
    TestContext.AssertTrue((1)=(decl.DeclLine), 'Should navigate to line 1');
    TestContext.AssertTrue(Pos('UnitBeta', decl.DeclFile) > 0, 'DeclFile should reference UnitBeta');
  finally
    unitPaths.Free;
  end;
end;

procedure TTestDeclaration.TestFindDecl_UsesUnit_NotFound;
var
  decl: TDeclarationResult;
  mainSrc: string;
begin
  mainSrc :=
    'program Test;'                + LineEnding +   // 0
    '{$mode objfpc}{$H+}'        + LineEnding +   // 1
    'uses NoSuchUnit;'             + LineEnding +   // 2 -- NoSuchUnit at col 5
    'begin'                        + LineEnding +   // 3
    'end.';
  SetSource(mainSrc);

  // Unit not on disk — should fall through gracefully (Found=False)
  decl := FindDeclaration(FHL, FLines, 'test.pas', 2, 7, nil, nil);
  TestContext.AssertTrue(not (decl.Found), 'Uses unit not on disk should return Found=False');
end;



constructor TTestDeclaration.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestDeclarationTestGetIdentAtCursor_OnIdentifier(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestGetIdentAtCursor_OnIdentifier');
  try
    lFixture.SetUp;
    try lFixture.TestGetIdentAtCursor_OnIdentifier; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestGetIdentAtCursor_OnKeyword(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestGetIdentAtCursor_OnKeyword');
  try
    lFixture.SetUp;
    try lFixture.TestGetIdentAtCursor_OnKeyword; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestGetIdentAtCursor_OnWhitespace(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestGetIdentAtCursor_OnWhitespace');
  try
    lFixture.SetUp;
    try lFixture.TestGetIdentAtCursor_OnWhitespace; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestGetIdentAtCursor_StartOfIdent(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestGetIdentAtCursor_StartOfIdent');
  try
    lFixture.SetUp;
    try lFixture.TestGetIdentAtCursor_StartOfIdent; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestGetIdentAtCursor_EndOfIdent(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestGetIdentAtCursor_EndOfIdent');
  try
    lFixture.SetUp;
    try lFixture.TestGetIdentAtCursor_EndOfIdent; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestFindDecl_LocalVar(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestFindDecl_LocalVar');
  try
    lFixture.SetUp;
    try lFixture.TestFindDecl_LocalVar; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestFindDecl_ProcParam(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestFindDecl_ProcParam');
  try
    lFixture.SetUp;
    try lFixture.TestFindDecl_ProcParam; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestFindDecl_TypeName(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestFindDecl_TypeName');
  try
    lFixture.SetUp;
    try lFixture.TestFindDecl_TypeName; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestFindDecl_ClassMethod(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestFindDecl_ClassMethod');
  try
    lFixture.SetUp;
    try lFixture.TestFindDecl_ClassMethod; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestFindDecl_OverloadedProc(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestFindDecl_OverloadedProc');
  try
    lFixture.SetUp;
    try lFixture.TestFindDecl_OverloadedProc; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestFindDecl_DottedExpr(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestFindDecl_DottedExpr');
  try
    lFixture.SetUp;
    try lFixture.TestFindDecl_DottedExpr; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestFindDecl_SameIdentTwiceOnLine(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestFindDecl_SameIdentTwiceOnLine');
  try
    lFixture.SetUp;
    try lFixture.TestFindDecl_SameIdentTwiceOnLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestFindDecl_NotAnIdent(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestFindDecl_NotAnIdent');
  try
    lFixture.SetUp;
    try lFixture.TestFindDecl_NotAnIdent; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestFindDecl_ParseError(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestFindDecl_ParseError');
  try
    lFixture.SetUp;
    try lFixture.TestFindDecl_ParseError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestFindDecl_CrossUnit_Type(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestFindDecl_CrossUnit_Type');
  try
    lFixture.SetUp;
    try lFixture.TestFindDecl_CrossUnit_Type; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestFindDecl_CrossUnit_Proc(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestFindDecl_CrossUnit_Proc');
  try
    lFixture.SetUp;
    try lFixture.TestFindDecl_CrossUnit_Proc; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestFindDecl_UnitNotFound(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestFindDecl_UnitNotFound');
  try
    lFixture.SetUp;
    try lFixture.TestFindDecl_UnitNotFound; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestFindDecl_EmptySource(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestFindDecl_EmptySource');
  try
    lFixture.SetUp;
    try lFixture.TestFindDecl_EmptySource; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestFindDecl_ConstRef(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestFindDecl_ConstRef');
  try
    lFixture.SetUp;
    try lFixture.TestFindDecl_ConstRef; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestFindDecl_ProgramName(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestFindDecl_ProgramName');
  try
    lFixture.SetUp;
    try lFixture.TestFindDecl_ProgramName; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestFindDecl_CircularUses(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestFindDecl_CircularUses');
  try
    lFixture.SetUp;
    try lFixture.TestFindDecl_CircularUses; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestFindDecl_UsesUnit_Simple(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestFindDecl_UsesUnit_Simple');
  try
    lFixture.SetUp;
    try lFixture.TestFindDecl_UsesUnit_Simple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestFindDecl_UsesUnit_Dotted(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestFindDecl_UsesUnit_Dotted');
  try
    lFixture.SetUp;
    try lFixture.TestFindDecl_UsesUnit_Dotted; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestFindDecl_UsesUnit_SecondInList(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestFindDecl_UsesUnit_SecondInList');
  try
    lFixture.SetUp;
    try lFixture.TestFindDecl_UsesUnit_SecondInList; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclarationTestFindDecl_UsesUnit_NotFound(AContext: TNXTestContext);
var lFixture: TTestDeclaration;
begin
  lFixture:=TTestDeclaration.Create(AContext, 'TestFindDecl_UsesUnit_NotFound');
  try
    lFixture.SetUp;
    try lFixture.TestFindDecl_UsesUnit_NotFound; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegisteridetestdeclarationTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.declaration.TTestDeclaration');
  lSuite.AddTest('TestGetIdentAtCursor_OnIdentifier', @RunTTestDeclarationTestGetIdentAtCursor_OnIdentifier);
  lSuite.AddTest('TestGetIdentAtCursor_OnKeyword', @RunTTestDeclarationTestGetIdentAtCursor_OnKeyword);
  lSuite.AddTest('TestGetIdentAtCursor_OnWhitespace', @RunTTestDeclarationTestGetIdentAtCursor_OnWhitespace);
  lSuite.AddTest('TestGetIdentAtCursor_StartOfIdent', @RunTTestDeclarationTestGetIdentAtCursor_StartOfIdent);
  lSuite.AddTest('TestGetIdentAtCursor_EndOfIdent', @RunTTestDeclarationTestGetIdentAtCursor_EndOfIdent);
  lSuite.AddTest('TestFindDecl_LocalVar', @RunTTestDeclarationTestFindDecl_LocalVar);
  lSuite.AddTest('TestFindDecl_ProcParam', @RunTTestDeclarationTestFindDecl_ProcParam);
  lSuite.AddTest('TestFindDecl_TypeName', @RunTTestDeclarationTestFindDecl_TypeName);
  lSuite.AddTest('TestFindDecl_ClassMethod', @RunTTestDeclarationTestFindDecl_ClassMethod);
  lSuite.AddTest('TestFindDecl_OverloadedProc', @RunTTestDeclarationTestFindDecl_OverloadedProc);
  lSuite.AddTest('TestFindDecl_DottedExpr', @RunTTestDeclarationTestFindDecl_DottedExpr);
  lSuite.AddTest('TestFindDecl_SameIdentTwiceOnLine', @RunTTestDeclarationTestFindDecl_SameIdentTwiceOnLine);
  lSuite.AddTest('TestFindDecl_NotAnIdent', @RunTTestDeclarationTestFindDecl_NotAnIdent);
  lSuite.AddTest('TestFindDecl_ParseError', @RunTTestDeclarationTestFindDecl_ParseError);
  lSuite.AddTest('TestFindDecl_CrossUnit_Type', @RunTTestDeclarationTestFindDecl_CrossUnit_Type);
  lSuite.AddTest('TestFindDecl_CrossUnit_Proc', @RunTTestDeclarationTestFindDecl_CrossUnit_Proc);
  lSuite.AddTest('TestFindDecl_UnitNotFound', @RunTTestDeclarationTestFindDecl_UnitNotFound);
  lSuite.AddTest('TestFindDecl_EmptySource', @RunTTestDeclarationTestFindDecl_EmptySource);
  lSuite.AddTest('TestFindDecl_ConstRef', @RunTTestDeclarationTestFindDecl_ConstRef);
  lSuite.AddTest('TestFindDecl_ProgramName', @RunTTestDeclarationTestFindDecl_ProgramName);
  lSuite.AddTest('TestFindDecl_CircularUses', @RunTTestDeclarationTestFindDecl_CircularUses);
  lSuite.AddTest('TestFindDecl_UsesUnit_Simple', @RunTTestDeclarationTestFindDecl_UsesUnit_Simple);
  lSuite.AddTest('TestFindDecl_UsesUnit_Dotted', @RunTTestDeclarationTestFindDecl_UsesUnit_Dotted);
  lSuite.AddTest('TestFindDecl_UsesUnit_SecondInList', @RunTTestDeclarationTestFindDecl_UsesUnit_SecondInList);
  lSuite.AddTest('TestFindDecl_UsesUnit_NotFound', @RunTTestDeclarationTestFindDecl_UsesUnit_NotFound);
end;

end.

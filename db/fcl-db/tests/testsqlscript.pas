{
    This file is part of the Free Pascal run time library.
    Copyright (c) 2008 by the Free Pascal development team

    FPCUnit SQLScript test.

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
unit testsqlscript;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, sqlscript;

type

  { TMyScript }

  TMyScript = class (TCustomSQLScript)
  private
    FExcept: string;
    FStatements : TStrings;
    FDirectives : TStrings;
    FCommits : integer;
  protected
    procedure ExecuteStatement (SQLStatement: TStrings; var StopExecution: Boolean); override;
    procedure ExecuteDirective (Directive, Argument: String; var StopExecution: Boolean); override;
    procedure ExecuteCommit(CommitRetaining: boolean=true); override;
    procedure DefaultDirectives; override;
  public
    constructor create (AnOwner: TComponent); override;
    destructor destroy; override;
    function StatementsExecuted : string;
    function DirectivesExecuted : string;
    property DoException : string read FExcept write FExcept;
    property Aborted;
    property Line;
    property UseDollarString;
    property dollarstrings;
    property Directives;
    property Defines;
    property Script;
    property Terminator;
    property CommentsinSQL;
    property UseSetTerm;
    property UseCommit;
    property UseDefines;
    property OnException;
  end;

  { TTestSQLScript }

  TTestSQLScript = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    Script : TMyScript;
    exceptionstatement,
    exceptionmessage : string;
    UseContinue : boolean;
    procedure Add (s :string);
    procedure AssertStatDir (Statements, Directives : string);
    procedure DoExecution;
    procedure ExceptionHandler(Sender: TObject; Statement: TStrings; TheException: Exception; var Continue: boolean);
    procedure TestDirectiveOnException3;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestCreateDefaults;
    procedure TestTerminator;
    procedure TestTerminatorNoFinal;
    procedure TestSetTerm;
    procedure TestUseSetTerm;
    procedure TestComments;
    procedure TestUseComments;
    procedure TestCommit;
    procedure TestUseCommit;
    procedure TestDefine;
    procedure TestUndefine;
    procedure TestUndef;
    procedure TestIfdef1;
    procedure TestIfdef2;
    procedure TestIfndef1;
    procedure TestIfndef2;
    procedure TestElse1;
    procedure TestElse2;
    procedure TestEndif1;
    procedure TestEndif2;
    procedure TestUseDefines;
    procedure TestTermInComment;
    procedure TestTermInQuotes1;
    procedure TestTermInQuotes2;
    procedure TestCommentInComment;
    procedure TestCommentInQuotes1;
    procedure TestCommentInQuotes2;
    Procedure TestDashDashComment;
    procedure TestQuote1InComment;
    procedure TestQuote2InComment;
    procedure TestQuoteInQuotes1;
    procedure TestQuoteInQuotes2;
    procedure TestStatementStop;
    procedure TestDirectiveStop;
    procedure TestStatementExeception;
    procedure TestDirectiveException;
    procedure TestCommitException;
    procedure TestStatementOnExeception1;
    procedure TestStatementOnExeception2;
    procedure TestDirectiveOnException1;
    procedure TestDirectiveOnException2;
    procedure TestCommitOnException1;
    procedure TestCommitOnException2;
    procedure TestUseDollarSign;
    procedure TestUseDollarSign2;
    procedure TestUseDollarSign3;
  end;

  { TTestEventSQLScript }

  TTestEventSQLScript = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    Script : TEventSQLScript;
    StopToSend : boolean;
    Received : string;
    notifycount : integer;
    LastSender : TObject;
    procedure Notify (Sender : TObject);
    procedure NotifyStatement (Sender: TObject; SQL_Statement: TStrings; var StopExecution: Boolean);
    procedure NotifyDirective (Sender: TObject; Directive, Argument: AnsiString; var StopExecution: Boolean);
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure TestStatement;
    procedure TestStatementStop;
    procedure TestDirective;
    procedure TestDirectiveStop;
    procedure TestCommit;
    procedure TestBeforeExec;
    procedure TestAfterExec;
  end;

procedure RegistertestsqlscriptTests(ARegistry: TNXTestRegistry);

implementation

{ TMyScript }

procedure TMyScript.ExecuteStatement(SQLStatement: TStrings; var StopExecution: Boolean);
var s : string;
    r : integer;
begin
  if (SQLStatement.count = 1) and (compareText(SQLStatement[0],'END')=0) then
    StopExecution := true;
  s := '';
  for r := 0 to SQLstatement.count-1 do
    begin
    if s <> '' then
      s := s + ' ';
    s := s + SQLStatement[r];
    end;
  FStatements.Add (s);
  if DoException <> '' then
    raise exception.create(DoException);
end;

procedure TMyScript.ExecuteDirective(Directive, Argument: String; var StopExecution: Boolean);
begin
  if Directive = 'STOP' then
    StopExecution := true;
  if Argument = '' then
    FDirectives.Add (Directive)
  else
    FDirectives.Add (format('%s(%s)', [Directive, Argument]));
  if DoException <> '' then
    raise exception.create(DoException);
end;

procedure TMyScript.ExecuteCommit(CommitRetaining: boolean=true);
begin
  inc (FCommits);
  if DoException <> '' then
    raise exception.create(DoException);
end;

procedure TMyScript.DefaultDirectives;
begin
  inherited DefaultDirectives;
  directives.add ('STOP');
end;

constructor TMyScript.create (AnOwner: TComponent);
begin
  inherited create (AnOwner);
  FStatements := TStringlist.Create;
  FDirectives := TStringlist.Create;
  FCommits := 0;
  DoException := '';
end;

destructor TMyScript.destroy;
begin
  FStatements.Free;
  FDirectives.Free;
  inherited destroy;
end;

function TMyScript.StatementsExecuted: string;
begin
  result := FStatements.Commatext;
end;

function TMyScript.DirectivesExecuted: string;
begin
  result := FDirectives.Commatext;
end;


{ TTestSQLScript }

procedure TTestSQLScript.Add(s: string);
begin
  Script.Script.Add (s);
end;

procedure TTestSQLScript.AssertStatDir(Statements, Directives: string);
begin
  TestContext.AssertTrue((Statements)=(script.StatementsExecuted), 'Executed Statements');
  TestContext.AssertTrue((Directives)=(script.DirectivesExecuted), 'Executed Directives');
end;

procedure TTestSQLScript.DoExecution;
begin
  script.execute;
end;

procedure TTestSQLScript.ExceptionHandler(Sender: TObject; Statement: TStrings;
  TheException: Exception; var Continue: boolean);
var r : integer;
    s : string;
begin
  Continue := UseContinue;
  if Statement.count > 0 then
    s := Statement[0];
  for r := 1 to Statement.count-1 do
    s := s + ',' + Statement[r];
  exceptionstatement := s;
  exceptionmessage := TheException.message;
end;

procedure TTestSQLScript.SetUp;
begin
  
  Script := TMyscript.Create (nil);
end;

procedure TTestSQLScript.TearDown;
begin
  Script.Free;
  
end;

procedure TTestSQLScript.TestCreateDefaults;
begin
  with Script do
    begin
    TestContext.AssertTrue((';')=(Terminator), 'Terminator');
    TestContext.AssertTrue(UseCommit, 'UseCommit');
    TestContext.AssertTrue(UseSetTerm, 'UseSetTerm');
    TestContext.AssertTrue(UseDefines, 'UseDefines');
    TestContext.AssertTrue(CommentsInSQL, 'CommentsInSQL');
    TestContext.AssertTrue(not (Aborted), 'Aborted');
    TestContext.AssertTrue((0)=(Line), 'Line');
    TestContext.AssertTrue((0)=(Defines.count), 'Defines');
    TestContext.AssertTrue((12)=(Directives.count), 'Directives');
    TestContext.AssertTrue(Directives.IndexOf('SET TERM')<>-1, 'Have SET TERM');
    TestContext.AssertTrue(Directives.IndexOf('COMMIT WORK')<>-1, 'Have COMMIT WORK');
    TestContext.AssertTrue(Directives.IndexOf('COMMIT RETAIN')<>-1, 'Have COMMIT RETAIN');
    TestContext.AssertTrue(Directives.IndexOf('COMMIT')<>-1, 'Have COMMIT');
    TestContext.AssertTrue(Directives.IndexOf('#IFDEF')<>-1, 'Have #IFDEF');
    TestContext.AssertTrue(Directives.IndexOf('#IFNDEF')<>-1, 'Have #IFNDEF');
    TestContext.AssertTrue(Directives.IndexOf('#ELSE')<>-1, 'Have #ELSE');
    TestContext.AssertTrue(Directives.IndexOf('#ENDIF')<>-1, 'Have #ENDIF');
    TestContext.AssertTrue(Directives.IndexOf('#DEFINE')<>-1, 'Have #DEFINE');
    TestContext.AssertTrue(Directives.IndexOf('#UNDEF')<>-1, 'Have #UNDEF');
    TestContext.AssertTrue(Directives.IndexOf('#UNDEFINE')<>-1, 'Have #UNDEFINE');
    // This is defined in our test class.
    TestContext.AssertTrue(Directives.IndexOf('STOP')<>-1, 'Have STOP');
    end;
end;

procedure TTestSQLScript.TestTerminator;
begin
  script.terminator := '!';
  Add('doe!iets!');
  Add('anders!');
  script.execute;
  AssertStatDir('doe,iets,anders', '');
end;

procedure TTestSQLScript.TestTerminatorNoFinal;
begin
  script.terminator := '!';
  Add('doe!iets!');
  Add('anders');
  script.execute;
  AssertStatDir('doe,iets,anders', '');
end;

procedure TTestSQLScript.TestSetTerm;
begin
  script.UseSetTerm:=true;
  Add('SET TERM !;');
  script.execute;
  TestContext.AssertTrue(('!')=(script.terminator), 'terminator');
  AssertStatDir('', '');
end;

procedure TTestSQLScript.TestUseSetTerm;
begin
  script.UseSetTerm:=false;
  Script.Directives.Add ('SET TERM');
  Add('SET TERM !;');
  script.execute;
  TestContext.AssertTrue((';')=(script.terminator), 'terminator');
  AssertStatDir('', '"SET TERM(!)"');
end;

procedure TTestSQLScript.TestComments;
begin
  script.CommentsInSQL := true;
  Add('/* comment */');
  Add('statement;');
  script.execute;
  AssertStatDir ('"/* comment */ statement"', '');
end;

procedure TTestSQLScript.TestUseComments;
begin
  script.CommentsInSQL := false;
  Add('/* comment */');
  Add('statement;');
  script.execute;
  AssertStatDir ('statement', '');
end;

procedure TTestSQLScript.TestCommit;
begin
  script.UseCommit := true;
  Add('commit;');
  script.execute;
  TestContext.AssertTrue((1)=(script.FCommits), 'Commits');
  AssertStatDir ('', '');
end;

procedure TTestSQLScript.TestUseCommit;
begin
  script.UseCommit := false;
  with script.Directives do
    Delete(IndexOf('COMMIT'));
  Add('commit;');
  script.execute;
  TestContext.AssertTrue((0)=(script.FCommits), 'Commits');
  AssertStatDir ('commit', '');
end;

procedure TTestSQLScript.TestDefine;
begin
  script.UseDefines := true;
  Add ('#define iets;');
  script.execute;
  AssertStatDir ('', '');
  TestContext.AssertTrue((1)=(script.defines.count), 'Aantal defines');
  TestContext.AssertTrue(('iets')=(script.Defines[0]), 'Juiste define');
end;

procedure TTestSQLScript.TestUndefine;
begin
  script.UseDefines := true;
  script.defines.Add ('iets');
  Add ('#undefine iets;');
  script.execute;
  AssertStatDir ('', '');
  TestContext.AssertTrue((0)=(script.defines.count), 'Aantal defines');
end;

procedure TTestSQLScript.TestUndef;
begin
  script.UseDefines := true;
  script.defines.Add ('iets');
  Add ('#Undef iets;');
  script.execute;
  AssertStatDir ('', '');
  TestContext.AssertTrue((0)=(script.defines.count), 'Aantal defines');
end;

procedure TTestSQLScript.TestIfdef1;
begin
  script.UseDefines := true;
  script.defines.add ('iets');
  Add('#ifdef iets;');
  Add('doe iets;');
  script.execute;
  AssertStatDir('"doe iets"', '');
end;

procedure TTestSQLScript.TestIfdef2;
begin
  script.UseDefines := true;
  Add('#ifdef iets;');
  Add('doe iets;');
  script.execute;
  AssertStatDir('', '');
end;

procedure TTestSQLScript.TestIfndef1;
begin
  script.UseDefines := true;
  Add('#ifndef iets;');
  Add('doe iets;');
  script.execute;
  AssertStatDir('"doe iets"', '');
end;

procedure TTestSQLScript.TestIfndef2;
begin
  script.UseDefines := true;
  script.defines.add ('iets');
  Add('#ifndef iets;');
  Add('doe iets;');
  script.execute;
  AssertStatDir('', '');
end;

procedure TTestSQLScript.TestElse1;
begin
  script.UseDefines := true;
  script.defines.add ('iets');
  Add('#ifdef iets;');
  Add('doe iets;');
  add('#else;');
  add('anders;');
  script.execute;
  AssertStatDir('"doe iets"', '');
end;

procedure TTestSQLScript.TestElse2;
begin
  script.UseDefines := true;
  script.defines.add ('iets');
  Add('#ifndef iets;');
  Add('doe iets;');
  add('#else;');
  add('anders;');
  script.execute;
  AssertStatDir('anders', '');
end;

procedure TTestSQLScript.TestEndif1;
begin
  script.UseDefines := true;
  Add('#ifdef iets;');
  Add('doe iets;');
  add('#endif;');
  add('anders;');
  script.execute;
  AssertStatDir('anders', '');
end;

procedure TTestSQLScript.TestEndif2;
begin
  script.UseDefines := true;
  Add('#ifndef iets;');
  Add('doe iets;');
  add('#endif;');
  add('anders;');
  script.execute;
  AssertStatDir('"doe iets",anders', '');
end;

procedure TTestSQLScript.TestUseDefines;
begin
  script.UseDefines := false;
  Add('#ifndef iets;');
  Add('doe iets;');
  add('#endif;');
  add('anders;');
  script.execute;
  AssertStatDir('"doe iets",anders', '#IFNDEF(iets),#ENDIF');
end;

procedure TTestSQLScript.TestTermInComment;
begin
  script.CommentsInSQL := false;
  Add('/* terminator ; */iets;');
  script.execute;
  AssertStatDir('iets', '');
end;

procedure TTestSQLScript.TestTermInQuotes1;
begin
  script.CommentsInSQL := false;
  Add('iets '';'';');
  script.execute;
  AssertStatDir('"iets '';''"', '');
end;

procedure TTestSQLScript.TestTermInQuotes2;
begin
  script.CommentsInSQL := false;
  Add('iets ";";');
  script.execute;
  AssertStatDir('"iets "";"""', '');
end;

procedure TTestSQLScript.TestCommentInComment;
begin
  script.CommentsInSQL := false;
  Add('/* meer /* */iets;');
  script.execute;
  AssertStatDir('iets', '');
end;

procedure TTestSQLScript.TestCommentInQuotes1;
begin
  script.CommentsInSQL := false;
  Add('iets ''/* meer */'';');
  script.execute;
  AssertStatDir('"iets ''/* meer */''"', '');
end;

procedure TTestSQLScript.TestCommentInQuotes2;
begin
  script.CommentsInSQL := false;
  Add('iets "/* meer */";');
  script.execute;
  AssertStatDir('"iets ""/* meer */"""', '');
end;

procedure TTestSQLScript.TestDashDashComment;
begin
  script.CommentsInSQL := false;
  Add('-- my comment');
  Add('CREATE TABLE "tPatients" (');
  Add('  "BloodGroup" character(2),');
  Add('  CONSTRAINT "ck_tPatients_BloodGroup" CHECK (("BloodGroup" = ANY (ARRAY[''A''::bpchar, ''B''::bpchar, ''AB''::bpchar, ''0''::bpchar]))),');
  Add(');');
  script.execute;
  AssertStatDir('"CREATE TABLE ""tPatients"" (   ""BloodGroup"" character(2),   CONSTRAINT ""ck_tPatients_BloodGroup"" CHECK ((""BloodGroup"" = ANY (ARRAY[''A''::bpchar, ''B''::bpchar, ''AB''::bpchar, ''0''::bpchar]))), )"', '');
end;

procedure TTestSQLScript.TestQuote1InComment;
begin
  script.CommentsInSQL := false;
  Add('/* s''morgens */iets;');
  script.execute;
  AssertStatDir('iets', '');
end;

procedure TTestSQLScript.TestQuote2InComment;
begin
  script.CommentsInSQL := false;
  Add('/* s"morgens */iets;');
  script.execute;
  AssertStatDir('iets', '');
end;

procedure TTestSQLScript.TestQuoteInQuotes1;
begin
  script.CommentsInSQL := false;
  Add('iets ''s"morgens'';');
  script.execute;
  AssertStatDir('"iets ''s""morgens''"', '');
end;

procedure TTestSQLScript.TestQuoteInQuotes2;
begin
  script.CommentsInSQL := false;
  Add('iets "s''morgens";');
  script.execute;
  AssertStatDir('"iets ""s''morgens"""', '');
end;

procedure TTestSQLScript.TestStatementStop;
begin
  Add('END;meer;');
  script.execute;
  AssertStatDir('END', '');
end;

procedure TTestSQLScript.TestDirectiveStop;
begin
  Add('Stop;meer;');
  script.execute;
  AssertStatDir('', 'STOP');
end;

procedure TTestSQLScript.TestStatementExeception;
begin
  Add('iets;');
  script.DoException:='FOUT';
  TestContext.AssertRaises(exception, @DoExecution, '');
  AssertStatDir('iets', '');
end;

procedure TTestSQLScript.TestDirectiveException;
begin
  Add('iets;');
  script.Directives.Add('IETS');
  script.DoException := 'FOUT';
  TestContext.AssertRaises(exception, @DoExecution, '');
  AssertStatDir('', 'IETS');
end;

procedure TTestSQLScript.TestCommitException;
begin
  Add ('commit;');
  script.DoException := 'FOUT';
  TestContext.AssertRaises(exception, @DoExecution, '');
  AssertStatDir('', '');
  TestContext.AssertTrue((1)=(Script.FCommits), 'Commit count');
end;

procedure TTestSQLScript.TestStatementOnExeception1;
begin
  UseContinue := true;
  script.DoException := 'Fout';
  Add ('foutief;');
  script.OnException:=@ExceptionHandler;
  Script.Execute;
  TestContext.AssertTrue(('Fout')=(exceptionmessage), 'exception message');
  TestContext.AssertTrue(('foutief')=(exceptionstatement), 'exception statement');
end;

procedure TTestSQLScript.TestStatementOnExeception2;
begin
  UseContinue := false;
  script.DoException := 'Fout';
  Add ('foutief;');
  script.OnException:=@ExceptionHandler;
  TestContext.AssertRaises(exception, @DoExecution, '');
  TestContext.AssertTrue(('Fout')=(exceptionmessage), 'exception message');
  TestContext.AssertTrue(('foutief')=(exceptionstatement), 'exception statement');
end;

procedure TTestSQLScript.TestDirectiveOnException1;
begin
  UseContinue := true;
  script.DoException := 'Fout';
  Add ('foutief;');
  Script.Directives.Add ('FOUTIEF');
  script.OnException:=@ExceptionHandler;
  Script.Execute;
  TestContext.AssertTrue(('Fout')=(exceptionmessage), 'exception message');
  TestContext.AssertTrue(('FOUTIEF')=(exceptionstatement), 'exception statement');
end;

procedure TTestSQLScript.TestDirectiveOnException2;
begin
  UseContinue := False;
  script.DoException := 'Fout';
  Add ('foutief;');
  Script.Directives.Add ('FOUTIEF');
  script.OnException:=@ExceptionHandler;
  TestContext.AssertRaises(exception, @DoExecution, '');
  TestContext.AssertTrue(('Fout')=(exceptionmessage), 'exception message');
  TestContext.AssertTrue(('FOUTIEF')=(exceptionstatement), 'exception statement');
end;

procedure TTestSQLScript.TestDirectiveOnException3;
begin
  UseContinue := true;
  script.DoException := 'Fout';
  Add ('foutief probleem;');
  Script.Directives.Add ('FOUTIEF');
  script.OnException:=@ExceptionHandler;
  Script.Execute;
  TestContext.AssertTrue(('Fout')=(exceptionmessage), 'exception message');
  TestContext.AssertTrue(('FOUTIEF,probleem')=(exceptionstatement), 'exception statement');
end;

procedure TTestSQLScript.TestCommitOnException1;
begin
  UseContinue := true;
  script.DoException := 'Fout';
  Add ('Commit;');
  script.OnException:=@ExceptionHandler;
  Script.Execute;
  TestContext.AssertTrue(('Fout')=(exceptionmessage), 'exception message');
  TestContext.AssertTrue(('COMMIT')=(exceptionstatement), 'exception statement');
  TestContext.AssertTrue((1)=(Script.FCommits), 'commit count');
end;

procedure TTestSQLScript.TestCommitOnException2;
begin
  UseContinue := false;
  script.DoException := 'Fout';
  Add ('Commit;');
  script.OnException:=@ExceptionHandler;
  TestContext.AssertRaises(exception, @DoExecution, '');
  TestContext.AssertTrue(('Fout')=(exceptionmessage), 'exception message');
  TestContext.AssertTrue(('COMMIT')=(exceptionstatement), 'exception statement');
  TestContext.AssertTrue((1)=(Script.FCommits), 'commit count');
end;


Const
  PLSQL1 = 'CREATE or replace FUNCTION test_double_bad_sum ( value1 int, value2 int ) '+
    'RETURNS int AS $$  '+
    'DECLARE  '+
    '  TheDoubleSum int;  '+
    'BEGIN  '+
    '  -- Start  '+
    '  TheDoubleSum := value1; '+
    '  /* sum  '+
    '       number  '+
    '       1 */  '+
    '  TheDoubleSum := TheDoubleSum + value2; '+
    '  TheDoubleSum := TheDoubleSum + value2; -- Sum number 2  '+
    '  return TheDoubleSum; '+
    'END;  '+
    '$$ '+
    'LANGUAGE plpgsql';
  PLSQL2 = 'COMMENT ON FUNCTION test_double_bad_sum(IN integer, IN integer) '+
    '  IS ''Just a  '+
    '  test function '+
    '  !!!''';
  PLSQL3 = 'CREATE or replace FUNCTION test_double_bad_sum ( value1 int, value2 int ) '+
    'RETURNS int AS $BOB$  '+
    'DECLARE  '+
    '  TheDoubleSum int;  '+
    'BEGIN  '+
    '  -- Start  '+
    '  TheDoubleSum := value1; '+
    '  /* sum  '+
    '       number  '+
    '       1 */  '+
    '  TheDoubleSum := TheDoubleSum + value2; '+
    '  TheDoubleSum := TheDoubleSum + value2; -- Sum number 2  '+
    '  return TheDoubleSum; '+
    'END;  '+
    '$BOB$ '+
    'LANGUAGE plpgsql';

procedure TTestSQLScript.TestUseDollarSign;

begin
  script.UseDollarString:=True;
  Add(PLSQL1+';');
  script.execute;
  // Double quotes because there are spaces.
  AssertStatDir('"'+plsql1+'"', '');
end;

procedure TTestSQLScript.TestUseDollarSign2;
begin
  script.UseDollarString:=True;
  Add(PLSQL1+';');
  Add(PLSQL2+';');
  script.execute;
  // Double quotes because there are spaces.
  AssertStatDir('"'+plsql1+'","'+PLSQL2+'"', '');

end;

procedure TTestSQLScript.TestUseDollarSign3;
begin
  script.UseDollarString:=True;
  script.DollarStrings.Add('BOB');
  Add(PLSQL3+';');
  script.execute;
  // Double quotes because there are spaces.
  AssertStatDir('"'+plsql3+'"', '');

end;

{ TTestEventSQLScript }

procedure TTestEventSQLScript.Notify(Sender: TObject);
begin
  inc (NotifyCount);
  LastSender := Sender;
end;

procedure TTestEventSQLScript.NotifyStatement(Sender: TObject;
  SQL_Statement: TStrings; var StopExecution: Boolean);
var r : integer;
    s : string;
begin
  StopExecution := StopToSend;
  if SQL_Statement.count > 0 then
    begin
    s := SQL_Statement[0];
    for r := 1 to SQL_Statement.count-1 do
      s := s + ';' + SQL_Statement[r];
    if SQL_Statement.count > 1 then
      s := '"' + s + '"';
    end
  else
    s := '';
  if received <> '' then
    received := received + ';' + s
  else
    received := s;
  LastSender := Sender;
end;

procedure TTestEventSQLScript.NotifyDirective(Sender: TObject; Directive,
  Argument: AnsiString; var StopExecution: Boolean);
var s : string;
begin
  StopExecution := StopToSend;
  if Argument = '' then
    s := UTF8Decode(Directive)
  else
    s := UTF8Decode(format ('%s(%s)', [UTF8Decode(Directive), UTF8Decode(Argument)]));
  if received <> '' then
    received := received + ';' + s
  else
    received := s;
  LastSender := Sender;
end;

procedure TTestEventSQLScript.SetUp;
begin
  
  Script := TEventSQLScript.Create (nil);
  notifycount := 0;
  Received := '';
  LastSender := nil;
end;

procedure TTestEventSQLScript.TearDown;
begin
  Script.Free;
  
end;

procedure TTestEventSQLScript.TestStatement;
begin
  StopToSend:=false;
  Script.OnSQLStatement := @NotifyStatement;
  Script.Script.Text := 'stat1;stat2;';
  script.execute;
  TestContext.AssertTrue(('stat1;stat2')=(received), 'Received');
  TestContext.AssertTrue((script)=(LastSender), 'Sender');
end;

procedure TTestEventSQLScript.TestStatementStop;
begin
  StopToSend:=true;
  Script.OnSQLStatement := @NotifyStatement;
  Script.Script.Text := 'stat1;stat2;';
  script.execute;
  TestContext.AssertTrue(('stat1')=(received), 'Received');
  TestContext.AssertTrue((script)=(LastSender), 'Sender');
end;

procedure TTestEventSQLScript.TestDirective;
begin
  StopToSend:=false;
  Script.OnSQLStatement := @NotifyStatement;
  Script.OnDirective := @NotifyDirective;
  script.Directives.Add ('STAT1');
  Script.Script.Text := 'stat1 ik;stat2;';
  script.execute;
  TestContext.AssertTrue(('STAT1(ik);stat2')=(received), 'Received');
  TestContext.AssertTrue((script)=(LastSender), 'Sender');
end;

procedure TTestEventSQLScript.TestDirectiveStop;
begin
  StopToSend:=true;
  Script.OnSQLStatement := @NotifyStatement;
  Script.OnDirective := @NotifyDirective;
  script.Directives.Add ('STAT1');
  Script.Script.Text := 'stat1 ik;stat2;';
  script.execute;
  TestContext.AssertTrue(('STAT1(ik)')=(received), 'Received');
  TestContext.AssertTrue((script)=(LastSender), 'Sender');
end;

procedure TTestEventSQLScript.TestCommit;
begin
  Script.OnCommit := @Notify;
  Script.Script.Text := 'iets; commit; anders;';
  script.execute;
  TestContext.AssertTrue((1)=(NotifyCount), 'NotifyCount');
  TestContext.AssertTrue((script)=(LastSender), 'Sender');
end;

procedure TTestEventSQLScript.TestBeforeExec;
begin
  Script.BeforeExecute := @Notify;
  Script.Script.Text := 'update iets; anders iets;';
  script.execute;
  TestContext.AssertTrue((1)=(NotifyCount), 'NotifyCount');
  TestContext.AssertTrue((script)=(LastSender), 'Sender');
end;

procedure TTestEventSQLScript.TestAfterExec;
begin
  Script.AfterExecute := @Notify;
  Script.Script.Text := 'update iets; anders iets; en meer;';
  script.execute;
  TestContext.AssertTrue((1)=(NotifyCount), 'NotifyCount');
  TestContext.AssertTrue((script)=(LastSender), 'Sender');
end;


constructor TTestSQLScript.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

constructor TTestEventSQLScript.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestSQLScriptTestCreateDefaults(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestCreateDefaults');
  try
    lFixture.SetUp;
    try lFixture.TestCreateDefaults; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestTerminator(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestTerminator');
  try
    lFixture.SetUp;
    try lFixture.TestTerminator; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestTerminatorNoFinal(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestTerminatorNoFinal');
  try
    lFixture.SetUp;
    try lFixture.TestTerminatorNoFinal; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestSetTerm(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestSetTerm');
  try
    lFixture.SetUp;
    try lFixture.TestSetTerm; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestUseSetTerm(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestUseSetTerm');
  try
    lFixture.SetUp;
    try lFixture.TestUseSetTerm; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestComments(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestComments');
  try
    lFixture.SetUp;
    try lFixture.TestComments; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestUseComments(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestUseComments');
  try
    lFixture.SetUp;
    try lFixture.TestUseComments; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestCommit(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestCommit');
  try
    lFixture.SetUp;
    try lFixture.TestCommit; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestUseCommit(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestUseCommit');
  try
    lFixture.SetUp;
    try lFixture.TestUseCommit; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestDefine(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestDefine');
  try
    lFixture.SetUp;
    try lFixture.TestDefine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestUndefine(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestUndefine');
  try
    lFixture.SetUp;
    try lFixture.TestUndefine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestUndef(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestUndef');
  try
    lFixture.SetUp;
    try lFixture.TestUndef; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestIfdef1(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestIfdef1');
  try
    lFixture.SetUp;
    try lFixture.TestIfdef1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestIfdef2(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestIfdef2');
  try
    lFixture.SetUp;
    try lFixture.TestIfdef2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestIfndef1(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestIfndef1');
  try
    lFixture.SetUp;
    try lFixture.TestIfndef1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestIfndef2(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestIfndef2');
  try
    lFixture.SetUp;
    try lFixture.TestIfndef2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestElse1(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestElse1');
  try
    lFixture.SetUp;
    try lFixture.TestElse1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestElse2(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestElse2');
  try
    lFixture.SetUp;
    try lFixture.TestElse2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestEndif1(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestEndif1');
  try
    lFixture.SetUp;
    try lFixture.TestEndif1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestEndif2(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestEndif2');
  try
    lFixture.SetUp;
    try lFixture.TestEndif2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestUseDefines(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestUseDefines');
  try
    lFixture.SetUp;
    try lFixture.TestUseDefines; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestTermInComment(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestTermInComment');
  try
    lFixture.SetUp;
    try lFixture.TestTermInComment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestTermInQuotes1(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestTermInQuotes1');
  try
    lFixture.SetUp;
    try lFixture.TestTermInQuotes1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestTermInQuotes2(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestTermInQuotes2');
  try
    lFixture.SetUp;
    try lFixture.TestTermInQuotes2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestCommentInComment(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestCommentInComment');
  try
    lFixture.SetUp;
    try lFixture.TestCommentInComment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestCommentInQuotes1(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestCommentInQuotes1');
  try
    lFixture.SetUp;
    try lFixture.TestCommentInQuotes1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestCommentInQuotes2(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestCommentInQuotes2');
  try
    lFixture.SetUp;
    try lFixture.TestCommentInQuotes2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestDashDashComment(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestDashDashComment');
  try
    lFixture.SetUp;
    try lFixture.TestDashDashComment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestQuote1InComment(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestQuote1InComment');
  try
    lFixture.SetUp;
    try lFixture.TestQuote1InComment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestQuote2InComment(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestQuote2InComment');
  try
    lFixture.SetUp;
    try lFixture.TestQuote2InComment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestQuoteInQuotes1(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestQuoteInQuotes1');
  try
    lFixture.SetUp;
    try lFixture.TestQuoteInQuotes1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestQuoteInQuotes2(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestQuoteInQuotes2');
  try
    lFixture.SetUp;
    try lFixture.TestQuoteInQuotes2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestStatementStop(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestStatementStop');
  try
    lFixture.SetUp;
    try lFixture.TestStatementStop; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestDirectiveStop(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestDirectiveStop');
  try
    lFixture.SetUp;
    try lFixture.TestDirectiveStop; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestStatementExeception(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestStatementExeception');
  try
    lFixture.SetUp;
    try lFixture.TestStatementExeception; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestDirectiveException(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestDirectiveException');
  try
    lFixture.SetUp;
    try lFixture.TestDirectiveException; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestCommitException(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestCommitException');
  try
    lFixture.SetUp;
    try lFixture.TestCommitException; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestStatementOnExeception1(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestStatementOnExeception1');
  try
    lFixture.SetUp;
    try lFixture.TestStatementOnExeception1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestStatementOnExeception2(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestStatementOnExeception2');
  try
    lFixture.SetUp;
    try lFixture.TestStatementOnExeception2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestDirectiveOnException1(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestDirectiveOnException1');
  try
    lFixture.SetUp;
    try lFixture.TestDirectiveOnException1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestDirectiveOnException2(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestDirectiveOnException2');
  try
    lFixture.SetUp;
    try lFixture.TestDirectiveOnException2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestCommitOnException1(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestCommitOnException1');
  try
    lFixture.SetUp;
    try lFixture.TestCommitOnException1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestCommitOnException2(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestCommitOnException2');
  try
    lFixture.SetUp;
    try lFixture.TestCommitOnException2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestUseDollarSign(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestUseDollarSign');
  try
    lFixture.SetUp;
    try lFixture.TestUseDollarSign; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestUseDollarSign2(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestUseDollarSign2');
  try
    lFixture.SetUp;
    try lFixture.TestUseDollarSign2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScriptTestUseDollarSign3(AContext: TNXTestContext);
var lFixture: TTestSQLScript;
begin
  lFixture:=TTestSQLScript.Create(AContext, 'TestUseDollarSign3');
  try
    lFixture.SetUp;
    try lFixture.TestUseDollarSign3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestEventSQLScriptTestStatement(AContext: TNXTestContext);
var lFixture: TTestEventSQLScript;
begin
  lFixture:=TTestEventSQLScript.Create(AContext, 'TestStatement');
  try
    lFixture.SetUp;
    try lFixture.TestStatement; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestEventSQLScriptTestStatementStop(AContext: TNXTestContext);
var lFixture: TTestEventSQLScript;
begin
  lFixture:=TTestEventSQLScript.Create(AContext, 'TestStatementStop');
  try
    lFixture.SetUp;
    try lFixture.TestStatementStop; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestEventSQLScriptTestDirective(AContext: TNXTestContext);
var lFixture: TTestEventSQLScript;
begin
  lFixture:=TTestEventSQLScript.Create(AContext, 'TestDirective');
  try
    lFixture.SetUp;
    try lFixture.TestDirective; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestEventSQLScriptTestDirectiveStop(AContext: TNXTestContext);
var lFixture: TTestEventSQLScript;
begin
  lFixture:=TTestEventSQLScript.Create(AContext, 'TestDirectiveStop');
  try
    lFixture.SetUp;
    try lFixture.TestDirectiveStop; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestEventSQLScriptTestCommit(AContext: TNXTestContext);
var lFixture: TTestEventSQLScript;
begin
  lFixture:=TTestEventSQLScript.Create(AContext, 'TestCommit');
  try
    lFixture.SetUp;
    try lFixture.TestCommit; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestEventSQLScriptTestBeforeExec(AContext: TNXTestContext);
var lFixture: TTestEventSQLScript;
begin
  lFixture:=TTestEventSQLScript.Create(AContext, 'TestBeforeExec');
  try
    lFixture.SetUp;
    try lFixture.TestBeforeExec; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestEventSQLScriptTestAfterExec(AContext: TNXTestContext);
var lFixture: TTestEventSQLScript;
begin
  lFixture:=TTestEventSQLScript.Create(AContext, 'TestAfterExec');
  try
    lFixture.SetUp;
    try lFixture.TestAfterExec; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegistertestsqlscriptTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('testsqlscript.TTestSQLScript');
  lSuite.AddTest('TestCreateDefaults', @RunTTestSQLScriptTestCreateDefaults);
  lSuite.AddTest('TestTerminator', @RunTTestSQLScriptTestTerminator);
  lSuite.AddTest('TestTerminatorNoFinal', @RunTTestSQLScriptTestTerminatorNoFinal);
  lSuite.AddTest('TestSetTerm', @RunTTestSQLScriptTestSetTerm);
  lSuite.AddTest('TestUseSetTerm', @RunTTestSQLScriptTestUseSetTerm);
  lSuite.AddTest('TestComments', @RunTTestSQLScriptTestComments);
  lSuite.AddTest('TestUseComments', @RunTTestSQLScriptTestUseComments);
  lSuite.AddTest('TestCommit', @RunTTestSQLScriptTestCommit);
  lSuite.AddTest('TestUseCommit', @RunTTestSQLScriptTestUseCommit);
  lSuite.AddTest('TestDefine', @RunTTestSQLScriptTestDefine);
  lSuite.AddTest('TestUndefine', @RunTTestSQLScriptTestUndefine);
  lSuite.AddTest('TestUndef', @RunTTestSQLScriptTestUndef);
  lSuite.AddTest('TestIfdef1', @RunTTestSQLScriptTestIfdef1);
  lSuite.AddTest('TestIfdef2', @RunTTestSQLScriptTestIfdef2);
  lSuite.AddTest('TestIfndef1', @RunTTestSQLScriptTestIfndef1);
  lSuite.AddTest('TestIfndef2', @RunTTestSQLScriptTestIfndef2);
  lSuite.AddTest('TestElse1', @RunTTestSQLScriptTestElse1);
  lSuite.AddTest('TestElse2', @RunTTestSQLScriptTestElse2);
  lSuite.AddTest('TestEndif1', @RunTTestSQLScriptTestEndif1);
  lSuite.AddTest('TestEndif2', @RunTTestSQLScriptTestEndif2);
  lSuite.AddTest('TestUseDefines', @RunTTestSQLScriptTestUseDefines);
  lSuite.AddTest('TestTermInComment', @RunTTestSQLScriptTestTermInComment);
  lSuite.AddTest('TestTermInQuotes1', @RunTTestSQLScriptTestTermInQuotes1);
  lSuite.AddTest('TestTermInQuotes2', @RunTTestSQLScriptTestTermInQuotes2);
  lSuite.AddTest('TestCommentInComment', @RunTTestSQLScriptTestCommentInComment);
  lSuite.AddTest('TestCommentInQuotes1', @RunTTestSQLScriptTestCommentInQuotes1);
  lSuite.AddTest('TestCommentInQuotes2', @RunTTestSQLScriptTestCommentInQuotes2);
  lSuite.AddTest('TestDashDashComment', @RunTTestSQLScriptTestDashDashComment);
  lSuite.AddTest('TestQuote1InComment', @RunTTestSQLScriptTestQuote1InComment);
  lSuite.AddTest('TestQuote2InComment', @RunTTestSQLScriptTestQuote2InComment);
  lSuite.AddTest('TestQuoteInQuotes1', @RunTTestSQLScriptTestQuoteInQuotes1);
  lSuite.AddTest('TestQuoteInQuotes2', @RunTTestSQLScriptTestQuoteInQuotes2);
  lSuite.AddTest('TestStatementStop', @RunTTestSQLScriptTestStatementStop);
  lSuite.AddTest('TestDirectiveStop', @RunTTestSQLScriptTestDirectiveStop);
  lSuite.AddTest('TestStatementExeception', @RunTTestSQLScriptTestStatementExeception);
  lSuite.AddTest('TestDirectiveException', @RunTTestSQLScriptTestDirectiveException);
  lSuite.AddTest('TestCommitException', @RunTTestSQLScriptTestCommitException);
  lSuite.AddTest('TestStatementOnExeception1', @RunTTestSQLScriptTestStatementOnExeception1);
  lSuite.AddTest('TestStatementOnExeception2', @RunTTestSQLScriptTestStatementOnExeception2);
  lSuite.AddTest('TestDirectiveOnException1', @RunTTestSQLScriptTestDirectiveOnException1);
  lSuite.AddTest('TestDirectiveOnException2', @RunTTestSQLScriptTestDirectiveOnException2);
  lSuite.AddTest('TestCommitOnException1', @RunTTestSQLScriptTestCommitOnException1);
  lSuite.AddTest('TestCommitOnException2', @RunTTestSQLScriptTestCommitOnException2);
  lSuite.AddTest('TestUseDollarSign', @RunTTestSQLScriptTestUseDollarSign);
  lSuite.AddTest('TestUseDollarSign2', @RunTTestSQLScriptTestUseDollarSign2);
  lSuite.AddTest('TestUseDollarSign3', @RunTTestSQLScriptTestUseDollarSign3);
  lSuite:=ARegistry.AddSuite('testsqlscript.TTestEventSQLScript');
  lSuite.AddTest('TestStatement', @RunTTestEventSQLScriptTestStatement);
  lSuite.AddTest('TestStatementStop', @RunTTestEventSQLScriptTestStatementStop);
  lSuite.AddTest('TestDirective', @RunTTestEventSQLScriptTestDirective);
  lSuite.AddTest('TestDirectiveStop', @RunTTestEventSQLScriptTestDirectiveStop);
  lSuite.AddTest('TestCommit', @RunTTestEventSQLScriptTestCommit);
  lSuite.AddTest('TestBeforeExec', @RunTTestEventSQLScriptTestBeforeExec);
  lSuite.AddTest('TestAfterExec', @RunTTestEventSQLScriptTestAfterExec);
end;

end.

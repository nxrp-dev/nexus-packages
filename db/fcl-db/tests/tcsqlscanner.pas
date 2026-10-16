{
    This file is part of the Free Component Library
    Copyright (c) 2010-2014 by the Free Pascal development team

    SQL source lexical scanner test suite

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
unit tcsqlscanner;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpsqlscanner;

type

  { TTestSQLScanner }

  TTestSQLScanner= class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  Private
    FStream : TStream;
    FLineReader : TLineReader;
    FScanner : TSQLScanner;
    FErrorSource : String;
    FErrorOptions : TSQLScannerOptions;
    
    procedure CheckToken(AToken: TSQLToken; ASource: String);
    procedure CheckTokens(ASource: String; ATokens: array of TSQLToken);
    procedure DoTestFloat(F: Double);
    procedure DoTestFloat(F: Double; S: String);
    procedure DoTestString(S: String; DoubleDelim : Boolean = False);
    procedure TestErrorSource;
  protected
    Function CreateScanner(AInput : String; AOptions : TSQLScannerOptions = []) : TSQLScanner;
    procedure FreeScanner;
    procedure SetUp; virtual;
    procedure TearDown; virtual;
    Property Scanner : TSQLScanner Read FScanner;
  public
    procedure TestAction;
    procedure TestAdd;
    procedure TestAdmin;
    procedure TestAfter;
    procedure TestALTER;
    procedure TestAnd;
    procedure TestAny;
    procedure TestAs;
    procedure TestASC;
    procedure TestASCENDING;
    Procedure TestAt;
    procedure TestAuto;
    procedure TestAVG;
    procedure TestAssign;
    procedure TestBefore;
    Procedure TestBegin;
    procedure TestBetween;
    procedure TestBlob;
    procedure TestBraceClose;
    procedure TestBraceOpen;
    procedure TestBy;
    Procedure TestCache;
    procedure TestCascade;
    procedure TestChar;
    procedure TestCharacter;
    procedure TestCheck;
    procedure TestCollate;
    procedure TestColon;
    procedure TestColumn;
    procedure TestComma;
    procedure TestCommit;
    procedure TestComputed;
    procedure TestConcatenate;
    Procedure TestConditional;
    Procedure TestConnect;
    procedure TestConstraint;
    procedure TestContaining;
    procedure TestCount;
    procedure TestCreate;
    procedure TestCString;
    Procedure TestDatabase;
    Procedure TestDate;
    Procedure TestDecimal;
    procedure TestDeclare;
    procedure TestDefault;
    procedure TestDelete;
    procedure TestDesc;
    procedure TestDescending;
    procedure TestDistinct;
    procedure TestDiv;
    procedure TestDO;
    procedure TestDomain;
    procedure TestDot;
    procedure TestDrop;
    procedure TestElse;
    procedure TestEmpty;
    procedure TestEnd;
    Procedure TestEntryPoint;
    procedure TestEq;
    procedure TestEscape;
    procedure TestException;
    procedure TestExists;
    procedure TestExit;
    Procedure TestExternal;
    Procedure TestExtract;
    procedure TestFile;
    Procedure TestFloat;
    procedure TestFor;
    procedure TestForeign;
    procedure TestFreeIt;
    procedure TestFunction;
    Procedure TestGDSError;
    procedure TestGE;
    procedure TestGenerator;
    procedure TestGrant;
    procedure TestGreaterThan;
    procedure TestGroup;
    Procedure TestHaving;
    procedure TestIf;
    procedure TestIn;
    procedure TestIndex;
    procedure TestInner;
    procedure TestInsert;
    procedure TestInt;
    procedure TestInteger;
    procedure TestInto;
    procedure TestIs;
    procedure TestJoin;
    procedure TestKey;
    procedure TestLeft;
    Procedure TestLength;
    procedure TestLike;
    procedure TestLE;
    procedure TestLessThan;
    Procedure TestManual;
    Procedure TestModuleName;
    procedure TestMax;
    procedure TestMerge;
    procedure TestMin;
    procedure TestMinus;
    procedure TestMul;
    procedure TestNational;
    procedure TestNatural;
    procedure TestNE;
    procedure TestNo;
    procedure TestNot;
    procedure TestNull;
    procedure TestNumeric;
    Procedure TestOn;
    Procedure TestOption;
    Procedure TestOr;
    Procedure TestOrder;
    Procedure TestOuter;
    Procedure TestPage;
    Procedure TestPages;
    Procedure TestPageSize;
    Procedure TestPassword;
    procedure TestPlus;
    procedure TestPosition;
    Procedure TestPostEvent;
    procedure TestPrimary;
    procedure TestPrivileges;
    procedure TestProcedure;
    procedure TestPublic;
    Procedure TestReferences;
    Procedure TestRelease;
    Procedure TestReturningValues;
    Procedure TestReturns;
    Procedure TestRetain;
    Procedure TestRevoke;
    Procedure TestRight;
    Procedure TestRole;
    Procedure TestRollback;
    Procedure TestSegment;
    Procedure TestSelect;
    procedure TestSemicolon;
    Procedure TestSet;
    Procedure TestSchema;
    Procedure TestShadow;
    Procedure TestSingular;
    Procedure TestSize;
    Procedure TestSkip;
    Procedure TestSome;
    Procedure TestSort;
    Procedure TestSnapshot;
    Procedure TestSQLCode;
    procedure TestSquareBraceClose;
    procedure TestSquareBraceOpen;
    Procedure TestStarting;
    procedure TestString;
    procedure TestSubtype;
    procedure TestSum;
    procedure TestSuspend;
    Procedure TestTable;
    Procedure TestThen;
    Procedure TestTime;
    Procedure TestTimeStamp;
    Procedure TestTo;
    Procedure TestTransaction;
    Procedure TestTrigger;
    Procedure TestType;
    Procedure TestUnion;
    Procedure TestUnique;
    Procedure TestUpdate;
    Procedure TestUpper;
    Procedure TestUser;
    procedure TestValue;
    procedure TestValues;
    procedure TestVariable;
    procedure TestVarChar;
    Procedure TestVarying;
    Procedure TestView;
    Procedure TestWhen;
    Procedure TestWhere;
    procedure TestWhile;
    procedure TestWith;
    procedure TestWork;
    procedure TestTerm;
    procedure TestTermExclude;
    procedure TestRecreate;
    procedure TestRestart;
    procedure TestSequence;
    Procedure Test2Words;
    procedure Test3Words;
    procedure TestIdentifier;
    procedure TestIdentifier2;
    procedure TestIdentifier3;
    procedure TestIdentifier4;
    procedure TestIdentifier5;
    procedure TestIdentifier6;
    procedure TestIdentifierDotIdentifier;
    procedure TestEOLN;
    procedure TestEOLN2;
    procedure TestEOLN3;
    procedure TestEOLN4;
    procedure TestComment1;
    procedure TestComment2;
    procedure TestComment3;
    procedure TestComment4;
    procedure TestComment5;
    procedure TestComment6;
    procedure TestFloatLiteral;
    procedure TestStringLiteral1;
    procedure TestStringLiteral2;
    procedure TestSymbolLiteral1;
    procedure TestSymbolLiteral2;
    procedure TestStringError;
    procedure TestFloatError;
    Procedure TestOptionsoDoubleQuoteStringLiteral;
    Procedure TestOptionsoSingleQuoteIdentifier;
    procedure TestOptionsoBackQuoteIdentifier;
    procedure TestOptionNosoBackQuoteIdentifier;
    procedure TestOptionNosoBackslashEscapes;
    procedure TestOptionsoBackslashEscapesTab;
    procedure TestOptionsoBackslashEscapesNewLine;
    procedure TestOptionsoBackslashEscapesBackSlash;
    procedure TestOptionsoBackslashEscapesBackspace;
    procedure TestOptionsoBackslashEscapesLineFeed;
    procedure TestOptionsoBackslashEscapesNewPage;
    procedure TestOptionsoBackslashEscapesSlash;
    procedure TestOptionsoBackslashEscapesQuote;
    procedure TestOptionsoBackslashEscapesDoubleQuote;
  end;

procedure RegistertcsqlscannerTests(ARegistry: TNXTestRegistry);

implementation

uses typinfo;



procedure TTestSQLScanner.CheckToken(AToken: TSQLToken; ASource: String);

Var
  J : TSqlToken;
  EN2 : String;

begin
  CreateScanner(ASource);
  J:=Scanner.FetchToken;
  EN2:=GetEnumName(TypeInfo(TSQLToken),Ord(AToken));
  TestContext.AssertTrue((AToken)=(J), Format('Source %s should result in %s.',[ASource,EN2]));
end;


procedure TTestSQLScanner.DoTestFloat(F: Double);
Var
  S : String;

begin
  Str(F,S);
  DoTestFloat(F,S);
end;

procedure TTestSQLScanner.DoTestFloat(F: Double; S: String);
Var
  J : TSQLToken;
  C : Double;
  I : integer;
  V : String;

begin
  CreateScanner(S);
  try
    J:=FScanner.FetchToken;
    TestContext.AssertTrue((tsqlFloatNumber)=(J), S+' is a number');
    V:=FScanner.CurTokenString;
    Val(V,C,I);
    If (I<>0) then
      TestContext.Fail(FScanner.CurTokenString+' does not contain a float value');
    TestContext.AssertTrue((F)=(C), 'Parsed float equals original float');
  finally
    FreeScanner;
  end;
end;

procedure TTestSQLScanner.DoTestString(S: String; DoubleDelim : Boolean = False);
Var
  J : TSQLToken;
  C : AnsiChar;

begin
  CreateScanner(S);
  try
    J:=FScanner.FetchToken;
    TestContext.AssertTrue((tsqlString)=(J), S+' is a string');
    If (Length(S)>0) and (S[1] in ['"','''']) then
      begin
      C:=S[1];
      S:=Copy(S,2,Length(S)-2);
      end;
    If DoubleDelim then
      S:=StringReplace(S,C+C,C,[rfReplaceAll]);
    TestContext.AssertTrue((S)=(FScanner.CurTokenString), 'Correct string is returned');
  finally
    FreeScanner;
  end;
end;

procedure TTestSQLScanner.TestErrorSource;
begin
  CreateScanner(FErrorSource,FErrorOptions);
  While (FScanner.FetchToken<>tsqlEOF) do ;
end;

function TTestSQLScanner.CreateScanner(AInput: String; AOptions : TSQLScannerOptions = []): TSQLScanner;
begin
  FStream:=TStringStream.Create(AInput);
  FLineReader:=TStreamLineReader.Create(Fstream);
  FScanner:=TSQLScanner.Create(FLineReader);
  FScanner.Options:=AOptions;
  Result:=FScanner;
end;

procedure TTestSQLScanner.FreeScanner;
begin
  FreeAndNil(FScanner);
  FreeAndNil(FLineReader);
  FreeAndNil(FStream);
end;

procedure TTestSQLScanner.SetUp;
begin
  
  FErrorSource:='';
  FErrorOptions:=[];
end;

procedure TTestSQLScanner.TearDown;
begin
  FreeScanner;

end;

procedure TTestSQLScanner.TestAction;
begin
  CheckToken(tsqlAction,'ACTION');
end;

procedure TTestSQLScanner.TestAdd;
begin
  CheckToken(tsqlAdd,'ADD');
end;

procedure TTestSQLScanner.TestAdmin;
begin
  CheckToken(tsqlAdmin,'ADMIN');
end;

procedure TTestSQLScanner.TestAfter;
begin
  CheckToken(tsqlAfter,'AFTER');
end;

procedure TTestSQLScanner.TestEmpty;

Var
  J : TSQLToken;
begin
  CreateScanner('');
  J:=Scanner.FetchToken;
  If (J<>tsqlEOF) then
    TestContext.Fail('Empty returns EOF');
end;

procedure TTestSQLScanner.TestEnd;
begin
  CheckToken(tsqlEnd,'END');
end;

procedure TTestSQLScanner.TestEntryPoint;
begin
  CheckToken(tsqlEntryPoint,'ENTRY_POINT');
end;

procedure TTestSQLScanner.TestEscape;
begin
  CheckToken(tsqlEscape,'ESCAPE');
end;

procedure TTestSQLScanner.TestException;
begin
  CheckToken(tsqlException,'EXCEPTION');
end;

procedure TTestSQLScanner.TestExists;
begin
  CheckToken(tsqlExists,'EXISTS');
end;

procedure TTestSQLScanner.TestExit;
begin
  CheckToken(tsqlExit,'EXIT');
end;

procedure TTestSQLScanner.TestExternal;
begin
  CheckToken(tsqlExternal,'external');
end;

procedure TTestSQLScanner.TestExtract;
begin
  CheckToken(tsqlExtract,'EXTRACT');
end;

procedure TTestSQLScanner.TestAnd;

begin
  CheckToken(tsqlAnd,'and');
end;

procedure TTestSQLScanner.TestAny;
begin
  CheckToken(tsqlAny,'any');
end;

procedure TTestSQLScanner.TestAs;
begin
  CheckToken(tsqlAs,'as');
end;

procedure TTestSQLScanner.TestAt;
begin
  CheckToken(tsqlAt,'at');
end;

procedure TTestSQLScanner.TestAuto;
begin
  CheckToken(tsqlAUTO,'auto');
end;

procedure TTestSQLScanner.TestASC;
begin
  CheckToken(tsqlASC,'asc');
end;

procedure TTestSQLScanner.TestASCENDING;
begin
  CheckToken(tsqlASCENDING,'ascending');
end;

procedure TTestSQLScanner.TestAVG;
begin
  CheckToken(tsqlAVG,'avg');
end;

procedure TTestSQLScanner.TestALTER;
begin
  CheckToken(tsqlALTER,'alter');
end;

procedure TTestSQLScanner.TestBraceOpen;

begin
  CheckToken(tsqlBraceOpen,'(');
end;

procedure TTestSQLScanner.TestBraceClose;

begin
  CheckToken(tsqlBraceClose,')');
end;


procedure TTestSQLScanner.TestComma;

begin
  CheckToken(tsqlComma,',');
end;

procedure TTestSQLScanner.TestCommit;
begin
  CheckToken(tsqlCommit,'COMMIT');
end;

procedure TTestSQLScanner.TestComputed;
begin
  CheckToken(tsqlComputed,'COMPUTED');
end;

procedure TTestSQLScanner.TestConditional;
begin
  CheckToken(tsqlConditional,'CONDITIONAL');
end;

procedure TTestSQLScanner.TestConnect;
begin
  CheckToken(tsqlConnect,'CONNECT');
end;

procedure TTestSQLScanner.TestConstraint;
begin
  CheckToken(tsqlConstraint,'CONSTRAINT');
end;

procedure TTestSQLScanner.TestColon;

begin
  CheckToken(tsqlColon,':');
end;

procedure TTestSQLScanner.TestColumn;
begin
  CheckToken(tsqlColumn,'COLUMN');
end;

procedure TTestSQLScanner.TestDot;

begin
  CheckToken(tsqlDot,'.');
end;

procedure TTestSQLScanner.TestDrop;
begin
  CheckToken(tsqldrop,'DROP');
end;

procedure TTestSQLScanner.TestSemicolon;

begin
  CheckToken(tsqlSemicolon,';');
end;

procedure TTestSQLScanner.TestSet;
begin
  CheckToken(tsqlSet,'SET');
end;

procedure TTestSQLScanner.TestSchema;
begin
  CheckToken(tsqlSchema,'SCHEMA');
end;

procedure TTestSQLScanner.TestShadow;
begin
  CheckToken(tsqlShadow,'SHADOW');
end;

procedure TTestSQLScanner.TestSingular;
begin
  CheckToken(tsqlSINGULAR,'SINGULAR');
end;

procedure TTestSQLScanner.TestSize;
begin
  CheckToken(tsqlSize,'size');
end;

procedure TTestSQLScanner.TestSkip;
begin
  CheckToken(tsqlSkip,'skip');
end;

procedure TTestSQLScanner.TestSome;
begin
  CheckToken(tsqlSome,'some');
end;

procedure TTestSQLScanner.TestSort;
begin
  CheckToken(tsqlSort,'sort');
end;

procedure TTestSQLScanner.TestSnapshot;
begin
  CheckToken(tsqlSnapshot,'snapshot');
end;

procedure TTestSQLScanner.TestSQLCode;
begin
  CheckToken(tsqlSQLCOde,'SQLCODE');
end;

procedure TTestSQLScanner.TestSquareBraceClose;
begin
  CheckToken(tsqlSquareBraceClose,']');
end;

procedure TTestSQLScanner.TestSquareBraceOpen;
begin
  CheckToken(tsqlSquareBraceOpen,'[');
end;

procedure TTestSQLScanner.TestSubtype;
begin
  CheckToken(tsqlSubtype,'sub_type');
end;

procedure TTestSQLScanner.TestSuspend;
begin
  CheckToken(tsqlSuspend,'Suspend');
end;

procedure TTestSQLScanner.TestSymbolLiteral1;
begin
  CheckToken(tsqlSymbolString,'%');
end;

procedure TTestSQLScanner.TestSymbolLiteral2;
begin
  CheckToken(tsqlSymbolString,'%^');
end;

procedure TTestSQLScanner.TestStarting;
begin
  CheckToken(tsqlStarting,'starting');
end;

procedure TTestSQLScanner.TestSum;
begin
  CheckToken(tsqlSum,'sum');
end;

procedure TTestSQLScanner.TestString;
begin
  DoTestString('''A string''');
  DoTestString('''''');
  DoTestString(''' " ''');
  DoTestString('''A string''');
  DoTestString(''' '''' ''',True);
  DoTestString('''12345'#10'67890''');
  DoTestString('''12345'#13'67890''');
  DoTestString('''12345'#13#10'67890''');
end;

procedure TTestSQLScanner.TestTable;
begin
  CheckToken(tsqltable,'TABLE');
end;

procedure TTestSQLScanner.TestThen;
begin
  CheckToken(tsqlThen,'THEN');
end;

procedure TTestSQLScanner.TestTime;
begin
  CheckToken(tsqlTime,'TIME');
end;

procedure TTestSQLScanner.TestTimeStamp;
begin
  CheckToken(tsqlTimeStamp,'TIMESTAMP');
end;

procedure TTestSQLScanner.TestTo;
begin
  CheckToken(tsqlTo,'TO');
end;

procedure TTestSQLScanner.TestTransaction;
begin
  CheckToken(tsqlTransaction,'TRANSACTION');
end;

procedure TTestSQLScanner.TestTrigger;
begin
  CheckToken(tsqlTrigger,'TRIGGER');
end;

procedure TTestSQLScanner.TestType;
begin
  CheckToken(tsqltype,'TYPE');
end;

procedure TTestSQLScanner.TestUnion;
begin
  CheckToken(tsqlUnion,'UNION');
end;

procedure TTestSQLScanner.TestUnique;
begin
  CheckToken(tsqlUnique,'UNIQUE');
end;

procedure TTestSQLScanner.TestUpdate;
begin
  CheckToken(tsqlUPDATE,'UPDATE');
end;

procedure TTestSQLScanner.TestUpper;
begin
  CheckToken(tsqlUPPER,'UPPER');
end;

procedure TTestSQLScanner.TestUser;
begin
  CheckToken(tsqlUSER,'USER');
end;

procedure TTestSQLScanner.TestValues;
begin
  CheckToken(tsqlVALUES,'VALUES');
end;

procedure TTestSQLScanner.TestValue;
begin
  CheckToken(tsqlVALUE,'VALUE');
end;

procedure TTestSQLScanner.TestAssign;

begin
  CheckToken(tsqlEq,'=');
end;

procedure TTestSQLScanner.TestBefore;
begin
  CheckToken(tsqlbefore,'BEFORE');
end;

procedure TTestSQLScanner.TestBegin;
begin
  CheckToken(tsqlbegin,'BEGIN');
end;

procedure TTestSQLScanner.TestBetween;
begin
  CheckToken(tsqlBetween,'BETWEEN');
end;

procedure TTestSQLScanner.TestGreaterThan;

begin
  CheckToken(tsqlGT,'>');
end;

procedure TTestSQLScanner.TestGroup;
begin
  CheckToken(tsqlGroup,'group');
end;

procedure TTestSQLScanner.TestHaving;
begin
  CheckToken(tsqlHaving,'HAVING');
end;

procedure TTestSQLScanner.TestLessThan;

begin
  CheckToken(tsqlLT,'<');
end;

procedure TTestSQLScanner.TestManual;
begin
  Checktoken(tsqlManual,'manual');
end;

procedure TTestSQLScanner.TestModuleName;
begin
  Checktoken(tsqlModuleName,'module_name');
end;

procedure TTestSQLScanner.TestMax;
begin
  Checktoken(tsqlMax,'max');
end;

procedure TTestSQLScanner.TestMerge;
begin
  Checktoken(tsqlMerge,'merge');
end;

procedure TTestSQLScanner.TestMin;
begin
  Checktoken(tsqlMin,'min');
end;

procedure TTestSQLScanner.TestPlus;

begin
  CheckToken(tsqlPlus,'+');
end;

procedure TTestSQLScanner.TestPosition;
begin
  Checktoken(tsqlposition,'position');
end;

procedure TTestSQLScanner.TestPostEvent;
begin
  Checktoken(tsqlpostevent,'post_event');
end;

procedure TTestSQLScanner.TestPrimary;
begin
  Checktoken(tsqlprimary,'primary');
end;

procedure TTestSQLScanner.TestPrivileges;
begin
  Checktoken(tsqlprivileges,'privileges');
end;

procedure TTestSQLScanner.TestProcedure;
begin
  Checktoken(tsqlprocedure,'procedure');
end;

procedure TTestSQLScanner.TestPublic;
begin
  CheckToken(tsqlPublic,'PUBLIC');
end;

procedure TTestSQLScanner.TestReferences;
begin
  CheckToken(tsqlReferences,'REFERENCES');
end;

procedure TTestSQLScanner.TestRelease;
begin
  CheckToken(tsqlrelease,'release');
end;

procedure TTestSQLScanner.TestReturningValues;
begin
  CheckToken(tsqlreturningvalues,'returning_values');
end;

procedure TTestSQLScanner.TestReturns;
begin
  CheckToken(tsqlreturns,'returns');
end;

procedure TTestSQLScanner.TestRetain;
begin
  Checktoken(tsqlRetain,'retain');
end;

procedure TTestSQLScanner.TestRevoke;
begin
  Checktoken(tsqlRevoke,'revoke');
end;

procedure TTestSQLScanner.TestRight;
begin
  Checktoken(tsqlright,'right');
end;

procedure TTestSQLScanner.TestRole;
begin
  Checktoken(tsqlrole,'role');
end;

procedure TTestSQLScanner.TestRollback;
begin
  Checktoken(tsqlrollback,'rollback');
end;

procedure TTestSQLScanner.TestSegment;
begin
  CheckToken(tsqlSegment,'SEGMENT');
end;

procedure TTestSQLScanner.TestSelect;
begin
  CheckToken(tsqlSelect,'SELECT');
end;

procedure TTestSQLScanner.TestMinus;

begin
  CheckToken(tsqlMinus,'-');
end;

procedure TTestSQLScanner.TestMul;

begin
  CheckToken(tsqlMul,'*');
end;

procedure TTestSQLScanner.TestNational;
begin
  CheckToken(tsqlNational,'NATIONAL');
end;

procedure TTestSQLScanner.TestNatural;
begin
  CheckToken(tsqlNatural,'NATURAL');
end;

procedure TTestSQLScanner.TestDiv;

begin
  CheckToken(tsqlDiv,'/');
end;

procedure TTestSQLScanner.TestEq;

begin
  CheckToken(tsqlEq,'==');
end;

procedure TTestSQLScanner.TestFloat;
begin
  CheckToken(tsqlFloat,'FLOAT');
end;

procedure TTestSQLScanner.TestGE;

begin
  CheckToken(tsqlGE,'>=');
end;

procedure TTestSQLScanner.TestGenerator;
begin
  CheckToken(tsqlGenerator,'generator');
end;

procedure TTestSQLScanner.TestGrant;
begin
  CheckToken(tsqlGrant,'grant');
end;

procedure TTestSQLScanner.TestLE;

begin
  CheckToken(tsqlLE,'<=');
end;


procedure TTestSQLScanner.TestNE;

begin
  CheckToken(tsqlNE,'<>');
end;

procedure TTestSQLScanner.TestNo;
begin
  CheckToken(tsqlNo,'no');
end;

procedure TTestSQLScanner.TestNot;

begin
  CheckToken(tsqlNot,'not');
end;

procedure TTestSQLScanner.TestNull;
begin
  CheckToken(tsqlnull,'null');
end;

procedure TTestSQLScanner.TestNumeric;
begin
  CheckToken(tsqlNumeric,'NUMERIC');
end;

procedure TTestSQLScanner.TestOn;
begin
  CheckToken(tsqlON,'on');
end;

procedure TTestSQLScanner.TestOption;
begin
  CheckToken(tsqlOption,'option');
end;

procedure TTestSQLScanner.TestOr;
begin
  CheckToken(tsqlOR,'or');
end;

procedure TTestSQLScanner.TestOrder;
begin
  CheckToken(tsqlORDER,'order');
end;

procedure TTestSQLScanner.TestOuter;
begin
  CheckToken(tsqlOUTER,'outer');
end;

procedure TTestSQLScanner.TestPage;
begin
  CheckToken(tsqlPage,'PAGE');
end;

procedure TTestSQLScanner.TestPages;
begin
  CheckToken(tsqlPages,'PAGES');
end;

procedure TTestSQLScanner.TestPageSize;
begin
  CheckToken(tsqlPageSize,'PAGE_SIZE');
end;

procedure TTestSQLScanner.TestPassword;
begin
  CheckToken(tsqlPassword,'PASSWORD');
end;

{
procedure TTestSQLScanner.TestTrue;

begin
  CheckToken(tsqlTrue,'true');
end;

procedure TTestSQLScanner.TestFalse;

begin
  CheckToken(tsqlFalse,'false');
end;
}

procedure TTestSQLScanner.TestBy;

begin
  CheckToken(tsqlBy,'by');
end;

procedure TTestSQLScanner.TestCache;
begin
  CheckToken(tsqlCache,'CACHE');
end;

procedure TTestSQLScanner.TestCascade;
begin
  CheckToken(tsqlCascade,'cascade');
end;

procedure TTestSQLScanner.TestBlob;

begin
  CheckToken(tsqlBlob,'blob');
end;

procedure TTestSQLScanner.TestChar;
begin
  CheckToken(tsqlChar,'char');
end;

procedure TTestSQLScanner.TestCharacter;
begin
  CheckToken(tsqlCharacter,'character');
end;

procedure TTestSQLScanner.TestCheck;
begin
  CheckToken(tsqlCHECK,'check');
end;

procedure TTestSQLScanner.TestCollate;

begin
  CheckToken(tsqlCollate,'collate');
end;

procedure TTestSQLScanner.TestConcatenate;
begin
  CheckToken(tsqlConcatenate,'||');
end;

procedure TTestSQLScanner.TestContaining;

begin
  CheckToken(tsqlContaining,'containing');
end;

procedure TTestSQLScanner.TestCount;

begin
  CheckToken(tsqlCount,'count');
end;

procedure TTestSQLScanner.TestCreate;
begin
  CheckToken(tsqlCreate,'create');
end;

procedure TTestSQLScanner.TestCString;
begin
  CheckToken(tsqlCString,'CSTRING');
end;

procedure TTestSQLScanner.TestDatabase;
begin
  CheckToken(tsqlDatabase,'database');
end;

procedure TTestSQLScanner.TestDate;
begin
  CheckToken(tsqlDate,'date');
end;

procedure TTestSQLScanner.TestDecimal;
begin
  CheckToken(tsqlDecimal,'decimal');
end;

procedure TTestSQLScanner.TestDefault;

begin
  CheckToken(tsqldefault,'default');
end;

procedure TTestSQLScanner.TestDelete;

begin
  CheckToken(tsqldelete,'delete');
end;

procedure TTestSQLScanner.TestDeclare;
begin
  CheckToken(tsqlDeclare,'DECLARE');
end;

procedure TTestSQLScanner.TestDesc;
begin
  CheckToken(tsqlDESC,'DESC');
end;

procedure TTestSQLScanner.TestDescending;
begin
 CheckToken(tsqlDescending,'DESCENDING');
end;

procedure TTestSQLScanner.TestDistinct;
begin
 CheckToken(tsqlDistinct,'DISTINCT');
end;

procedure TTestSQLScanner.TestDO;

begin
  CheckToken(tsqldo,'do');
end;

procedure TTestSQLScanner.TestDomain;
begin
  CheckToken(tsqlDomain,'domain');
end;

procedure TTestSQLScanner.TestElse;

begin
  CheckToken(tsqlelse,'else');
end;

procedure TTestSQLScanner.TestFor;

begin
  CheckToken(tsqlfor,'for');
end;

procedure TTestSQLScanner.TestForeign;
begin
  CheckToken(tsqlForeign,'foreign');
end;

procedure TTestSQLScanner.TestFreeIt;
begin
  CheckToken(tsqlFreeIt,'FREE_IT');
end;

procedure TTestSQLScanner.TestFile;
begin
  CheckToken(tsqlFile,'FILE');
end;

procedure TTestSQLScanner.TestFunction;

begin
  CheckToken(tsqlfunction,'function');
end;

procedure TTestSQLScanner.TestGDSError;
begin
  CheckToken(tsqlGDSCODE,'GDSCODE');
end;

procedure TTestSQLScanner.TestIf;

begin
  CheckToken(tsqlif,'if');
end;

procedure TTestSQLScanner.TestIn;

begin
  CheckToken(tsqlin,'in');
end;

procedure TTestSQLScanner.TestInner;

begin
  CheckToken(tsqlInner,'inner');
end;

procedure TTestSQLScanner.TestInsert;

begin
  CheckToken(tsqlInsert,'insert');
end;

procedure TTestSQLScanner.TestInt;

begin
  CheckToken(tsqlInt,'int');
end;

procedure TTestSQLScanner.TestInteger;

begin
  CheckToken(tsqlInteger,'integer');
end;

procedure TTestSQLScanner.TestInto;
begin
  CheckToken(tsqlInto,'into');
end;

procedure TTestSQLScanner.TestIs;
begin
  CheckToken(tsqlis,'is');
end;

procedure TTestSQLScanner.TestJoin;
begin
  CheckToken(tsqlJoin,'JOIN');
end;

procedure TTestSQLScanner.TestKey;
begin
  CheckToken(tsqlKey,'KEY');
end;

procedure TTestSQLScanner.TestLeft;
begin
  CheckToken(tsqlLEFT,'LEFT');
end;

procedure TTestSQLScanner.TestLength;
begin
  CheckToken(tsqlLength,'LENGTH');
end;

procedure TTestSQLScanner.TestLike;
begin
  CheckToken(tsqlLIKE,'LIKE');
end;

procedure TTestSQLScanner.TestIndex;
begin
  CheckToken(tsqlindex,'index');
end;

procedure TTestSQLScanner.TestVariable;

begin
  CheckToken(tsqlvariable,'variable');
end;

procedure TTestSQLScanner.TestVarChar;
begin
  CheckToken(tsqlvarchar,'varchar');
end;

procedure TTestSQLScanner.TestVarying;
begin
  CheckToken(tsqlvarying,'varying');
end;

procedure TTestSQLScanner.TestView;
begin
  CheckToken(tsqlview,'view');
end;

procedure TTestSQLScanner.TestWhen;
begin
  CheckToken(tsqlWhen,'when');
end;

procedure TTestSQLScanner.TestWhere;
begin
  CheckToken(tsqlwhere,'where');
end;

procedure TTestSQLScanner.TestWhile;

begin
  CheckToken(tsqlwhile,'while');
end;

procedure TTestSQLScanner.TestWith;

begin
  CheckToken(tsqlwith,'with');
end;

procedure TTestSQLScanner.TestWork;
begin
  CheckToken(tsqlWork,'work');
end;

procedure TTestSQLScanner.TestTerm;
begin
  CheckToken(tsqlTerm,'term');
end;

procedure TTestSQLScanner.TestTermExclude;
begin
  CreateScanner('term');
  FScanner.Excludekeywords.Add('term');
  TestContext.AssertTrue((tsqlIdentifier)=(FScanner.FetchToken), 'Term is identifier');
end;

procedure TTestSQLScanner.TestRecreate;
begin
  CheckToken(tsqlRecreate,'recreate');
end;

procedure TTestSQLScanner.TestRestart;
begin
  CheckToken(tsqlRestart,'restart');
end;

procedure TTestSQLScanner.TestSequence;
begin
  CheckToken(tsqlSequence,'sequence');
end;

procedure TTestSQLScanner.CheckTokens(ASource: String; ATokens: array of TSQLToken);

Var
  I : Integer;
  J : TSQLToken;
  S : String;

begin
  CreateScanner(ASource);
  For I:=Low(ATokens) to High(ATokens) do
    begin
    J:=FScanner.FetchToken;
    S:=GetEnumName(TypeINfo(TSQLToken),Ord(ATokens[i]));
    S:=Format('Source "%s", token %d (%s): expected %s',[ASource,I,FScanner.CurTokenString,S]);
    TestContext.AssertTrue((ATokens[i])=(J), S);
    end;
end;

procedure TTestSQLScanner.Test2Words;
begin
  CheckTokens('with do',[tsqlWith,tsqlDo]);
end;

procedure TTestSQLScanner.Test3Words;
begin
  CheckTokens('with do for',[tsqlWith,tsqlDo,tsqlFor]);
end;

procedure TTestSQLScanner.TestIdentifier;
begin
  CheckToken(tsqlIdentifier,'something');
  TestContext.AssertTrue(('something')=(FScanner.CurTokenString), 'Correct identifier');
end;

procedure TTestSQLScanner.TestIdentifier2;
begin
  CheckToken(tsqlIdentifier,'"_something"');
  TestContext.AssertTrue(('_something')=(FScanner.CurTokenString), 'Correct identifier');
end;

procedure TTestSQLScanner.TestIdentifier3;
begin
  CheckToken(tsqlIdentifier,'RDB$');
  TestContext.AssertTrue(('RDB$')=(FScanner.CurTokenString), 'Correct identifier');
end;

procedure TTestSQLScanner.TestIdentifier4;
begin
  CheckToken(tsqlIdentifier,'A_0');
  TestContext.AssertTrue(('A_0')=(FScanner.CurTokenString), 'Correct identifier');
end;

procedure TTestSQLScanner.TestIdentifier5;
begin
  // $0 should not be parsed as an identifier but as a symbol literal
  CheckToken(tsqlSymbolString,'$0');
end;

procedure TTestSQLScanner.TestIdentifier6;
begin
  CreateScanner('[A]',[soSquareBracketsIdentifier]);
  TestContext.AssertTrue((tsqlIdentifier)=(FScanner.FetchToken), 'Identifier is returned');
  TestContext.AssertTrue(('A')=(FScanner.CurTokenString), 'Correct identifier');
end;

procedure TTestSQLScanner.TestIdentifierDotIdentifier;
begin
  CheckTokens('something.different',[tsqlIdentifier,tsqldot,tsqlIdentifier]);
//  AssertEquals('Correct identifier','something',FScanner.CurTokenString);
end;

procedure TTestSQLScanner.TestEOLN;
begin
  CreateScanner('something');
  FScanner.FetchToken;
  TestContext.AssertTrue((True)=(FScanner.IsEndOfLine), 'Got to end of line after reading single token at EOF');
//  AssertEquals('Correct identifier','something',FScanner.CurTokenString);
end;

procedure TTestSQLScanner.TestEOLN2;
begin
  CreateScanner('something different');
  FScanner.FetchToken;
  TestContext.AssertTrue((False)=(FScanner.IsEndOfLine), 'Not yet end of line after reading single token at EOF');
end;

procedure TTestSQLScanner.TestEOLN3;
begin
  CreateScanner('something'#13#10'different');
  FScanner.FetchToken;
  TestContext.AssertTrue((True)=(FScanner.IsEndOfLine), 'End of line after reading single token');
end;

procedure TTestSQLScanner.TestEOLN4;
begin
  CreateScanner('something'#10'different');
  FScanner.FetchToken;
  TestContext.AssertTrue((True)=(FScanner.IsEndOfLine), 'End of line after reading first token');
  FScanner.FetchToken;
  TestContext.AssertTrue((True)=(FScanner.IsEndOfLine), 'End of line after reading second token');
end;

procedure TTestSQLScanner.TestComment1;
begin
  CreateScanner('-- some comment string');
  TestContext.AssertTrue((tsqlEOF)=(FScanner.FetchToken), 'Comment line is skipped');
end;

procedure TTestSQLScanner.TestComment2;
begin
  CreateScanner('--  some comment string');
  FScanner.Options:=[soReturnComments];
  TestContext.AssertTrue((tsqlComment)=(FScanner.FetchToken), 'Comment line is returned');
  TestContext.AssertTrue((' some comment string')=(FScanner.CurTokenString), 'Comment contents is returned');
end;

procedure TTestSQLScanner.TestComment3;
begin
  CreateScanner('/* some comment string */');
  TestContext.AssertTrue((tsqlEOF)=(FScanner.FetchToken), 'Comment line is skipped');
end;

procedure TTestSQLScanner.TestComment4;
begin
  CreateScanner('/* some comment string */');
  FScanner.Options:=[soReturnComments];
  TestContext.AssertTrue((tsqlComment)=(FScanner.FetchToken), 'Comment line is returned');
  TestContext.AssertTrue((' some comment string ')=(FScanner.CurTokenString), 'Comment contents is returned');
end;

procedure TTestSQLScanner.TestComment5;
begin
  CreateScanner('/* some nested comment -- string */');
  FScanner.Options:=[soReturnComments];
  TestContext.AssertTrue((tsqlComment)=(FScanner.FetchToken), 'Comment line is returned');
  TestContext.AssertTrue((' some nested comment -- string ')=(FScanner.CurTokenString), 'Comment contents is returned');
end;

procedure TTestSQLScanner.TestComment6;
begin
  CreateScanner('-- /* some nested comment string */');
  FScanner.Options:=[soReturnComments];
  TestContext.AssertTrue((tsqlComment)=(FScanner.FetchToken), 'Comment line is returned');
  TestContext.AssertTrue(('/* some nested comment string */')=(FScanner.CurTokenString), 'Comment contents is returned');
end;

procedure TTestSQLScanner.TestFloatLiteral;
begin
  DoTestFloat(1.2);
  DoTestFloat(-1.2);
  DoTestFloat(1.2e1);
  DoTestFloat(-1.2e1);
  DoTestFloat(1.2,'1.2');
  DoTestFloat(-1.2,'-1.2');
  DoTestFloat(0,'0.0');
end;

procedure TTestSQLScanner.TestStringLiteral1;
begin
  CreateScanner('''A''');
  FScanner.Options:=[];
  TestContext.AssertTrue((tsqlString)=(FScanner.FetchToken), 'String is returned');
  TestContext.AssertTrue(('A')=(FScanner.CurTokenString), 'Correct string');
end;

procedure TTestSQLScanner.TestStringLiteral2;
begin
  CreateScanner('"A"',[soDoubleQuoteStringLiteral]);
  TestContext.AssertTrue((tsqlString)=(FScanner.FetchToken), 'String is returned');
  TestContext.AssertTrue(('A')=(FScanner.CurTokenString), 'Correct string');
end;

procedure TTestSQLScanner.TestStringError;
begin
end;

procedure TTestSQLScanner.TestFloatError;
begin
  FErrorSource:='1xz';
  TestContext.AssertRaises(ESQLScannerError, @TestErrorSource, 'Wrong float');
end;

procedure TTestSQLScanner.TestOptionsoDoubleQuoteStringLiteral;
begin
  CreateScanner('"A"',[soDoubleQuoteStringLiteral]);
  TestContext.AssertTrue((tsqlString)=(FScanner.FetchToken), 'String is returned');
  TestContext.AssertTrue(('A')=(FScanner.CurTokenString), 'Correct string');
end;

procedure TTestSQLScanner.TestOptionsoSingleQuoteIdentifier;
begin
  CreateScanner('''A''',[soSingleQuoteIdentifier,soDoubleQuoteStringLiteral]);
  If (Scanner.Options<>[soSingleQuoteIdentifier,soDoubleQuoteStringLiteral]) then
    TestContext.Fail('Options not correctly set');
  TestContext.AssertTrue((tsqlIdentifier)=(FScanner.FetchToken), 'Identifier is returned');
  TestContext.AssertTrue(('A')=(FScanner.CurTokenString), 'Correct string');
end;

procedure TTestSQLScanner.TestOptionsoBackQuoteIdentifier;
begin
  CreateScanner('`A`',[soBackQuoteIdentifier]);
  TestContext.AssertTrue((tsqlIdentifier)=(FScanner.FetchToken), 'String is returned');
  TestContext.AssertTrue(('A')=(FScanner.CurTokenString), 'Correct string');
end;

procedure TTestSQLScanner.TestOptionNosoBackQuoteIdentifier;
begin
  FErrorSource:='`A`';
  TestContext.AssertRaises(ESQLScannerError, @TestErrorSource, 'Wrong token');
end;

procedure TTestSQLScanner.TestOptionsoBackslashEscapesTab;
begin
  CreateScanner('''\t''',[soBackslashEscapes]);
  TestContext.AssertTrue((tsqlString)=(FScanner.FetchToken), 'String is returned');
  TestContext.AssertTrue((#9)=(FScanner.CurTokenString), 'Correct string');
end;

procedure TTestSQLScanner.TestOptionsoBackslashEscapesNewLine;
begin
  CreateScanner('''\n''',[soBackslashEscapes]);
  TestContext.AssertTrue((tsqlString)=(FScanner.FetchToken), 'String is returned');
  TestContext.AssertTrue((#10)=(FScanner.CurTokenString), 'Correct string');
end;

procedure TTestSQLScanner.TestOptionsoBackslashEscapesLineFeed;

begin
  CreateScanner('''\r''',[soBackslashEscapes]);
  TestContext.AssertTrue((tsqlString)=(FScanner.FetchToken), 'String is returned');
  TestContext.AssertTrue((#13)=(FScanner.CurTokenString), 'Correct string');
end;

procedure TTestSQLScanner.TestOptionsoBackslashEscapesBackSlash;

begin
  CreateScanner('''\\''',[soBackslashEscapes]);
  TestContext.AssertTrue((tsqlString)=(FScanner.FetchToken), 'String is returned');
  TestContext.AssertTrue(('\')=(FScanner.CurTokenString), 'Correct string');
end;

procedure TTestSQLScanner.TestOptionsoBackslashEscapesNewPage;

begin
  CreateScanner('''\f''',[soBackslashEscapes]);
  TestContext.AssertTrue((tsqlString)=(FScanner.FetchToken), 'String is returned');
  TestContext.AssertTrue((#12)=(FScanner.CurTokenString), 'Correct string');
end;

procedure TTestSQLScanner.TestOptionsoBackslashEscapesSlash;
begin
  CreateScanner('''\/''',[soBackslashEscapes]);
  TestContext.AssertTrue((tsqlString)=(FScanner.FetchToken), 'String is returned');
  TestContext.AssertTrue(('/')=(FScanner.CurTokenString), 'Correct string');
end;

procedure TTestSQLScanner.TestOptionsoBackslashEscapesBackspace;

begin
  CreateScanner('''\f''',[soBackslashEscapes]);
  TestContext.AssertTrue((tsqlString)=(FScanner.FetchToken), 'String is returned');
  TestContext.AssertTrue((#12)=(FScanner.CurTokenString), 'Correct string');
end;

procedure TTestSQLScanner.TestOptionsoBackslashEscapesQuote;

begin
  CreateScanner('''\''''',[soBackslashEscapes]);
  TestContext.AssertTrue((tsqlString)=(FScanner.FetchToken), 'String is returned');
  TestContext.AssertTrue(('''')=(FScanner.CurTokenString), 'Correct string');
end;

procedure TTestSQLScanner.TestOptionsoBackslashEscapesDoubleQuote;
begin
  CreateScanner('''\"''',[soBackslashEscapes]);
  TestContext.AssertTrue((tsqlString)=(FScanner.FetchToken), 'String is returned');
  TestContext.AssertTrue(('"')=(FScanner.CurTokenString), 'Correct string');
end;

procedure TTestSQLScanner.TestOptionNosoBackslashEscapes;
begin
  CreateScanner('''\"''',[]);
  TestContext.AssertTrue((tsqlString)=(FScanner.FetchToken), 'String is returned');
  TestContext.AssertTrue(('\"')=(FScanner.CurTokenString), 'Correct string');
end;



constructor TTestSQLScanner.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestSQLScannerTestAction(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestAction');
  try
    lFixture.SetUp;
    try lFixture.TestAction; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestAdd(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestAdd');
  try
    lFixture.SetUp;
    try lFixture.TestAdd; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestAdmin(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestAdmin');
  try
    lFixture.SetUp;
    try lFixture.TestAdmin; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestAfter(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestAfter');
  try
    lFixture.SetUp;
    try lFixture.TestAfter; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestALTER(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestALTER');
  try
    lFixture.SetUp;
    try lFixture.TestALTER; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestAnd(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestAnd');
  try
    lFixture.SetUp;
    try lFixture.TestAnd; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestAny(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestAny');
  try
    lFixture.SetUp;
    try lFixture.TestAny; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestAs(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestAs');
  try
    lFixture.SetUp;
    try lFixture.TestAs; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestASC(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestASC');
  try
    lFixture.SetUp;
    try lFixture.TestASC; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestASCENDING(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestASCENDING');
  try
    lFixture.SetUp;
    try lFixture.TestASCENDING; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestAt(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestAt');
  try
    lFixture.SetUp;
    try lFixture.TestAt; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestAuto(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestAuto');
  try
    lFixture.SetUp;
    try lFixture.TestAuto; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestAVG(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestAVG');
  try
    lFixture.SetUp;
    try lFixture.TestAVG; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestAssign(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestAssign');
  try
    lFixture.SetUp;
    try lFixture.TestAssign; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestBefore(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestBefore');
  try
    lFixture.SetUp;
    try lFixture.TestBefore; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestBegin(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestBegin');
  try
    lFixture.SetUp;
    try lFixture.TestBegin; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestBetween(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestBetween');
  try
    lFixture.SetUp;
    try lFixture.TestBetween; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestBlob(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestBlob');
  try
    lFixture.SetUp;
    try lFixture.TestBlob; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestBraceClose(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestBraceClose');
  try
    lFixture.SetUp;
    try lFixture.TestBraceClose; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestBraceOpen(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestBraceOpen');
  try
    lFixture.SetUp;
    try lFixture.TestBraceOpen; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestBy(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestBy');
  try
    lFixture.SetUp;
    try lFixture.TestBy; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestCache(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestCache');
  try
    lFixture.SetUp;
    try lFixture.TestCache; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestCascade(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestCascade');
  try
    lFixture.SetUp;
    try lFixture.TestCascade; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestChar(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestChar');
  try
    lFixture.SetUp;
    try lFixture.TestChar; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestCharacter(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestCharacter');
  try
    lFixture.SetUp;
    try lFixture.TestCharacter; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestCheck(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestCheck');
  try
    lFixture.SetUp;
    try lFixture.TestCheck; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestCollate(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestCollate');
  try
    lFixture.SetUp;
    try lFixture.TestCollate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestColon(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestColon');
  try
    lFixture.SetUp;
    try lFixture.TestColon; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestColumn(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestColumn');
  try
    lFixture.SetUp;
    try lFixture.TestColumn; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestComma(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestComma');
  try
    lFixture.SetUp;
    try lFixture.TestComma; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestCommit(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestCommit');
  try
    lFixture.SetUp;
    try lFixture.TestCommit; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestComputed(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestComputed');
  try
    lFixture.SetUp;
    try lFixture.TestComputed; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestConcatenate(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestConcatenate');
  try
    lFixture.SetUp;
    try lFixture.TestConcatenate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestConditional(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestConditional');
  try
    lFixture.SetUp;
    try lFixture.TestConditional; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestConnect(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestConnect');
  try
    lFixture.SetUp;
    try lFixture.TestConnect; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestConstraint(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestConstraint');
  try
    lFixture.SetUp;
    try lFixture.TestConstraint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestContaining(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestContaining');
  try
    lFixture.SetUp;
    try lFixture.TestContaining; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestCount(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestCount');
  try
    lFixture.SetUp;
    try lFixture.TestCount; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestCreate(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestCreate');
  try
    lFixture.SetUp;
    try lFixture.TestCreate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestCString(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestCString');
  try
    lFixture.SetUp;
    try lFixture.TestCString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestDatabase(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestDatabase');
  try
    lFixture.SetUp;
    try lFixture.TestDatabase; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestDate(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestDate');
  try
    lFixture.SetUp;
    try lFixture.TestDate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestDecimal(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestDecimal');
  try
    lFixture.SetUp;
    try lFixture.TestDecimal; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestDeclare(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestDeclare');
  try
    lFixture.SetUp;
    try lFixture.TestDeclare; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestDefault(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestDefault');
  try
    lFixture.SetUp;
    try lFixture.TestDefault; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestDelete(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestDelete');
  try
    lFixture.SetUp;
    try lFixture.TestDelete; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestDesc(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestDesc');
  try
    lFixture.SetUp;
    try lFixture.TestDesc; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestDescending(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestDescending');
  try
    lFixture.SetUp;
    try lFixture.TestDescending; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestDistinct(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestDistinct');
  try
    lFixture.SetUp;
    try lFixture.TestDistinct; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestDiv(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestDiv');
  try
    lFixture.SetUp;
    try lFixture.TestDiv; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestDO(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestDO');
  try
    lFixture.SetUp;
    try lFixture.TestDO; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestDomain(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestDomain');
  try
    lFixture.SetUp;
    try lFixture.TestDomain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestDot(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestDot');
  try
    lFixture.SetUp;
    try lFixture.TestDot; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestDrop(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestDrop');
  try
    lFixture.SetUp;
    try lFixture.TestDrop; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestElse(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestElse');
  try
    lFixture.SetUp;
    try lFixture.TestElse; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestEmpty(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestEmpty');
  try
    lFixture.SetUp;
    try lFixture.TestEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestEnd(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestEnd');
  try
    lFixture.SetUp;
    try lFixture.TestEnd; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestEntryPoint(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestEntryPoint');
  try
    lFixture.SetUp;
    try lFixture.TestEntryPoint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestEq(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestEq');
  try
    lFixture.SetUp;
    try lFixture.TestEq; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestEscape(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestEscape');
  try
    lFixture.SetUp;
    try lFixture.TestEscape; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestException(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestException');
  try
    lFixture.SetUp;
    try lFixture.TestException; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestExists(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestExists');
  try
    lFixture.SetUp;
    try lFixture.TestExists; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestExit(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestExit');
  try
    lFixture.SetUp;
    try lFixture.TestExit; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestExternal(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestExternal');
  try
    lFixture.SetUp;
    try lFixture.TestExternal; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestExtract(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestExtract');
  try
    lFixture.SetUp;
    try lFixture.TestExtract; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestFile(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestFile');
  try
    lFixture.SetUp;
    try lFixture.TestFile; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestFloat(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestFloat');
  try
    lFixture.SetUp;
    try lFixture.TestFloat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestFor(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestFor');
  try
    lFixture.SetUp;
    try lFixture.TestFor; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestForeign(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestForeign');
  try
    lFixture.SetUp;
    try lFixture.TestForeign; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestFreeIt(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestFreeIt');
  try
    lFixture.SetUp;
    try lFixture.TestFreeIt; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestFunction(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestFunction');
  try
    lFixture.SetUp;
    try lFixture.TestFunction; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestGDSError(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestGDSError');
  try
    lFixture.SetUp;
    try lFixture.TestGDSError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestGE(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestGE');
  try
    lFixture.SetUp;
    try lFixture.TestGE; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestGenerator(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestGenerator');
  try
    lFixture.SetUp;
    try lFixture.TestGenerator; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestGrant(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestGrant');
  try
    lFixture.SetUp;
    try lFixture.TestGrant; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestGreaterThan(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestGreaterThan');
  try
    lFixture.SetUp;
    try lFixture.TestGreaterThan; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestGroup(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestGroup');
  try
    lFixture.SetUp;
    try lFixture.TestGroup; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestHaving(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestHaving');
  try
    lFixture.SetUp;
    try lFixture.TestHaving; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestIf(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestIf');
  try
    lFixture.SetUp;
    try lFixture.TestIf; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestIn(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestIn');
  try
    lFixture.SetUp;
    try lFixture.TestIn; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestIndex(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestIndex');
  try
    lFixture.SetUp;
    try lFixture.TestIndex; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestInner(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestInner');
  try
    lFixture.SetUp;
    try lFixture.TestInner; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestInsert(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestInsert');
  try
    lFixture.SetUp;
    try lFixture.TestInsert; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestInt(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestInt');
  try
    lFixture.SetUp;
    try lFixture.TestInt; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestInteger(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestInteger');
  try
    lFixture.SetUp;
    try lFixture.TestInteger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestInto(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestInto');
  try
    lFixture.SetUp;
    try lFixture.TestInto; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestIs(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestIs');
  try
    lFixture.SetUp;
    try lFixture.TestIs; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestJoin(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestJoin');
  try
    lFixture.SetUp;
    try lFixture.TestJoin; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestKey(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestKey');
  try
    lFixture.SetUp;
    try lFixture.TestKey; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestLeft(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestLeft');
  try
    lFixture.SetUp;
    try lFixture.TestLeft; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestLength(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestLength');
  try
    lFixture.SetUp;
    try lFixture.TestLength; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestLike(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestLike');
  try
    lFixture.SetUp;
    try lFixture.TestLike; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestLE(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestLE');
  try
    lFixture.SetUp;
    try lFixture.TestLE; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestLessThan(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestLessThan');
  try
    lFixture.SetUp;
    try lFixture.TestLessThan; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestManual(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestManual');
  try
    lFixture.SetUp;
    try lFixture.TestManual; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestModuleName(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestModuleName');
  try
    lFixture.SetUp;
    try lFixture.TestModuleName; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestMax(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestMax');
  try
    lFixture.SetUp;
    try lFixture.TestMax; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestMerge(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestMerge');
  try
    lFixture.SetUp;
    try lFixture.TestMerge; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestMin(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestMin');
  try
    lFixture.SetUp;
    try lFixture.TestMin; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestMinus(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestMinus');
  try
    lFixture.SetUp;
    try lFixture.TestMinus; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestMul(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestMul');
  try
    lFixture.SetUp;
    try lFixture.TestMul; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestNational(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestNational');
  try
    lFixture.SetUp;
    try lFixture.TestNational; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestNatural(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestNatural');
  try
    lFixture.SetUp;
    try lFixture.TestNatural; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestNE(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestNE');
  try
    lFixture.SetUp;
    try lFixture.TestNE; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestNo(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestNo');
  try
    lFixture.SetUp;
    try lFixture.TestNo; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestNot(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestNot');
  try
    lFixture.SetUp;
    try lFixture.TestNot; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestNull(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestNull');
  try
    lFixture.SetUp;
    try lFixture.TestNull; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestNumeric(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestNumeric');
  try
    lFixture.SetUp;
    try lFixture.TestNumeric; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestOn(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestOn');
  try
    lFixture.SetUp;
    try lFixture.TestOn; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestOption(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestOption');
  try
    lFixture.SetUp;
    try lFixture.TestOption; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestOr(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestOr');
  try
    lFixture.SetUp;
    try lFixture.TestOr; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestOrder(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestOrder');
  try
    lFixture.SetUp;
    try lFixture.TestOrder; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestOuter(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestOuter');
  try
    lFixture.SetUp;
    try lFixture.TestOuter; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestPage(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestPage');
  try
    lFixture.SetUp;
    try lFixture.TestPage; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestPages(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestPages');
  try
    lFixture.SetUp;
    try lFixture.TestPages; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestPageSize(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestPageSize');
  try
    lFixture.SetUp;
    try lFixture.TestPageSize; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestPassword(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestPassword');
  try
    lFixture.SetUp;
    try lFixture.TestPassword; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestPlus(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestPlus');
  try
    lFixture.SetUp;
    try lFixture.TestPlus; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestPosition(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestPosition');
  try
    lFixture.SetUp;
    try lFixture.TestPosition; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestPostEvent(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestPostEvent');
  try
    lFixture.SetUp;
    try lFixture.TestPostEvent; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestPrimary(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestPrimary');
  try
    lFixture.SetUp;
    try lFixture.TestPrimary; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestPrivileges(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestPrivileges');
  try
    lFixture.SetUp;
    try lFixture.TestPrivileges; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestProcedure(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestProcedure');
  try
    lFixture.SetUp;
    try lFixture.TestProcedure; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestPublic(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestPublic');
  try
    lFixture.SetUp;
    try lFixture.TestPublic; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestReferences(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestReferences');
  try
    lFixture.SetUp;
    try lFixture.TestReferences; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestRelease(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestRelease');
  try
    lFixture.SetUp;
    try lFixture.TestRelease; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestReturningValues(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestReturningValues');
  try
    lFixture.SetUp;
    try lFixture.TestReturningValues; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestReturns(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestReturns');
  try
    lFixture.SetUp;
    try lFixture.TestReturns; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestRetain(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestRetain');
  try
    lFixture.SetUp;
    try lFixture.TestRetain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestRevoke(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestRevoke');
  try
    lFixture.SetUp;
    try lFixture.TestRevoke; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestRight(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestRight');
  try
    lFixture.SetUp;
    try lFixture.TestRight; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestRole(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestRole');
  try
    lFixture.SetUp;
    try lFixture.TestRole; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestRollback(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestRollback');
  try
    lFixture.SetUp;
    try lFixture.TestRollback; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestSegment(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestSegment');
  try
    lFixture.SetUp;
    try lFixture.TestSegment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestSelect(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestSelect');
  try
    lFixture.SetUp;
    try lFixture.TestSelect; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestSemicolon(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestSemicolon');
  try
    lFixture.SetUp;
    try lFixture.TestSemicolon; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestSet(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestSet');
  try
    lFixture.SetUp;
    try lFixture.TestSet; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestSchema(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestSchema');
  try
    lFixture.SetUp;
    try lFixture.TestSchema; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestShadow(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestShadow');
  try
    lFixture.SetUp;
    try lFixture.TestShadow; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestSingular(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestSingular');
  try
    lFixture.SetUp;
    try lFixture.TestSingular; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestSize(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestSize');
  try
    lFixture.SetUp;
    try lFixture.TestSize; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestSkip(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestSkip');
  try
    lFixture.SetUp;
    try lFixture.TestSkip; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestSome(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestSome');
  try
    lFixture.SetUp;
    try lFixture.TestSome; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestSort(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestSort');
  try
    lFixture.SetUp;
    try lFixture.TestSort; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestSnapshot(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestSnapshot');
  try
    lFixture.SetUp;
    try lFixture.TestSnapshot; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestSQLCode(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestSQLCode');
  try
    lFixture.SetUp;
    try lFixture.TestSQLCode; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestSquareBraceClose(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestSquareBraceClose');
  try
    lFixture.SetUp;
    try lFixture.TestSquareBraceClose; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestSquareBraceOpen(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestSquareBraceOpen');
  try
    lFixture.SetUp;
    try lFixture.TestSquareBraceOpen; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestStarting(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestStarting');
  try
    lFixture.SetUp;
    try lFixture.TestStarting; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestString(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestString');
  try
    lFixture.SetUp;
    try lFixture.TestString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestSubtype(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestSubtype');
  try
    lFixture.SetUp;
    try lFixture.TestSubtype; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestSum(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestSum');
  try
    lFixture.SetUp;
    try lFixture.TestSum; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestSuspend(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestSuspend');
  try
    lFixture.SetUp;
    try lFixture.TestSuspend; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestTable(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestTable');
  try
    lFixture.SetUp;
    try lFixture.TestTable; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestThen(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestThen');
  try
    lFixture.SetUp;
    try lFixture.TestThen; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestTime(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestTime');
  try
    lFixture.SetUp;
    try lFixture.TestTime; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestTimeStamp(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestTimeStamp');
  try
    lFixture.SetUp;
    try lFixture.TestTimeStamp; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestTo(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestTo');
  try
    lFixture.SetUp;
    try lFixture.TestTo; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestTransaction(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestTransaction');
  try
    lFixture.SetUp;
    try lFixture.TestTransaction; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestTrigger(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestTrigger');
  try
    lFixture.SetUp;
    try lFixture.TestTrigger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestType(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestType');
  try
    lFixture.SetUp;
    try lFixture.TestType; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestUnion(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestUnion');
  try
    lFixture.SetUp;
    try lFixture.TestUnion; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestUnique(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestUnique');
  try
    lFixture.SetUp;
    try lFixture.TestUnique; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestUpdate(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestUpdate');
  try
    lFixture.SetUp;
    try lFixture.TestUpdate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestUpper(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestUpper');
  try
    lFixture.SetUp;
    try lFixture.TestUpper; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestUser(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestUser');
  try
    lFixture.SetUp;
    try lFixture.TestUser; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestValue(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestValue');
  try
    lFixture.SetUp;
    try lFixture.TestValue; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestValues(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestValues');
  try
    lFixture.SetUp;
    try lFixture.TestValues; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestVariable(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestVariable');
  try
    lFixture.SetUp;
    try lFixture.TestVariable; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestVarChar(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestVarChar');
  try
    lFixture.SetUp;
    try lFixture.TestVarChar; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestVarying(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestVarying');
  try
    lFixture.SetUp;
    try lFixture.TestVarying; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestView(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestView');
  try
    lFixture.SetUp;
    try lFixture.TestView; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestWhen(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestWhen');
  try
    lFixture.SetUp;
    try lFixture.TestWhen; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestWhere(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestWhere');
  try
    lFixture.SetUp;
    try lFixture.TestWhere; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestWhile(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestWhile');
  try
    lFixture.SetUp;
    try lFixture.TestWhile; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestWith(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestWith');
  try
    lFixture.SetUp;
    try lFixture.TestWith; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestWork(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestWork');
  try
    lFixture.SetUp;
    try lFixture.TestWork; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestTerm(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestTerm');
  try
    lFixture.SetUp;
    try lFixture.TestTerm; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestTermExclude(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestTermExclude');
  try
    lFixture.SetUp;
    try lFixture.TestTermExclude; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestRecreate(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestRecreate');
  try
    lFixture.SetUp;
    try lFixture.TestRecreate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestRestart(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestRestart');
  try
    lFixture.SetUp;
    try lFixture.TestRestart; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestSequence(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestSequence');
  try
    lFixture.SetUp;
    try lFixture.TestSequence; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTest2Words(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'Test2Words');
  try
    lFixture.SetUp;
    try lFixture.Test2Words; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTest3Words(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'Test3Words');
  try
    lFixture.SetUp;
    try lFixture.Test3Words; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestIdentifier(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestIdentifier');
  try
    lFixture.SetUp;
    try lFixture.TestIdentifier; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestIdentifier2(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestIdentifier2');
  try
    lFixture.SetUp;
    try lFixture.TestIdentifier2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestIdentifier3(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestIdentifier3');
  try
    lFixture.SetUp;
    try lFixture.TestIdentifier3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestIdentifier4(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestIdentifier4');
  try
    lFixture.SetUp;
    try lFixture.TestIdentifier4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestIdentifier5(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestIdentifier5');
  try
    lFixture.SetUp;
    try lFixture.TestIdentifier5; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestIdentifier6(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestIdentifier6');
  try
    lFixture.SetUp;
    try lFixture.TestIdentifier6; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestIdentifierDotIdentifier(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestIdentifierDotIdentifier');
  try
    lFixture.SetUp;
    try lFixture.TestIdentifierDotIdentifier; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestEOLN(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestEOLN');
  try
    lFixture.SetUp;
    try lFixture.TestEOLN; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestEOLN2(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestEOLN2');
  try
    lFixture.SetUp;
    try lFixture.TestEOLN2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestEOLN3(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestEOLN3');
  try
    lFixture.SetUp;
    try lFixture.TestEOLN3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestEOLN4(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestEOLN4');
  try
    lFixture.SetUp;
    try lFixture.TestEOLN4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestComment1(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestComment1');
  try
    lFixture.SetUp;
    try lFixture.TestComment1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestComment2(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestComment2');
  try
    lFixture.SetUp;
    try lFixture.TestComment2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestComment3(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestComment3');
  try
    lFixture.SetUp;
    try lFixture.TestComment3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestComment4(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestComment4');
  try
    lFixture.SetUp;
    try lFixture.TestComment4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestComment5(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestComment5');
  try
    lFixture.SetUp;
    try lFixture.TestComment5; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestComment6(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestComment6');
  try
    lFixture.SetUp;
    try lFixture.TestComment6; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestFloatLiteral(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestFloatLiteral');
  try
    lFixture.SetUp;
    try lFixture.TestFloatLiteral; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestStringLiteral1(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestStringLiteral1');
  try
    lFixture.SetUp;
    try lFixture.TestStringLiteral1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestStringLiteral2(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestStringLiteral2');
  try
    lFixture.SetUp;
    try lFixture.TestStringLiteral2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestSymbolLiteral1(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestSymbolLiteral1');
  try
    lFixture.SetUp;
    try lFixture.TestSymbolLiteral1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestSymbolLiteral2(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestSymbolLiteral2');
  try
    lFixture.SetUp;
    try lFixture.TestSymbolLiteral2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestStringError(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestStringError');
  try
    lFixture.SetUp;
    try lFixture.TestStringError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestFloatError(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestFloatError');
  try
    lFixture.SetUp;
    try lFixture.TestFloatError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestOptionsoDoubleQuoteStringLiteral(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestOptionsoDoubleQuoteStringLiteral');
  try
    lFixture.SetUp;
    try lFixture.TestOptionsoDoubleQuoteStringLiteral; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestOptionsoSingleQuoteIdentifier(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestOptionsoSingleQuoteIdentifier');
  try
    lFixture.SetUp;
    try lFixture.TestOptionsoSingleQuoteIdentifier; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestOptionsoBackQuoteIdentifier(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestOptionsoBackQuoteIdentifier');
  try
    lFixture.SetUp;
    try lFixture.TestOptionsoBackQuoteIdentifier; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestOptionNosoBackQuoteIdentifier(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestOptionNosoBackQuoteIdentifier');
  try
    lFixture.SetUp;
    try lFixture.TestOptionNosoBackQuoteIdentifier; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestOptionNosoBackslashEscapes(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestOptionNosoBackslashEscapes');
  try
    lFixture.SetUp;
    try lFixture.TestOptionNosoBackslashEscapes; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestOptionsoBackslashEscapesTab(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestOptionsoBackslashEscapesTab');
  try
    lFixture.SetUp;
    try lFixture.TestOptionsoBackslashEscapesTab; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestOptionsoBackslashEscapesNewLine(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestOptionsoBackslashEscapesNewLine');
  try
    lFixture.SetUp;
    try lFixture.TestOptionsoBackslashEscapesNewLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestOptionsoBackslashEscapesBackSlash(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestOptionsoBackslashEscapesBackSlash');
  try
    lFixture.SetUp;
    try lFixture.TestOptionsoBackslashEscapesBackSlash; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestOptionsoBackslashEscapesBackspace(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestOptionsoBackslashEscapesBackspace');
  try
    lFixture.SetUp;
    try lFixture.TestOptionsoBackslashEscapesBackspace; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestOptionsoBackslashEscapesLineFeed(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestOptionsoBackslashEscapesLineFeed');
  try
    lFixture.SetUp;
    try lFixture.TestOptionsoBackslashEscapesLineFeed; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestOptionsoBackslashEscapesNewPage(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestOptionsoBackslashEscapesNewPage');
  try
    lFixture.SetUp;
    try lFixture.TestOptionsoBackslashEscapesNewPage; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestOptionsoBackslashEscapesSlash(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestOptionsoBackslashEscapesSlash');
  try
    lFixture.SetUp;
    try lFixture.TestOptionsoBackslashEscapesSlash; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestOptionsoBackslashEscapesQuote(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestOptionsoBackslashEscapesQuote');
  try
    lFixture.SetUp;
    try lFixture.TestOptionsoBackslashEscapesQuote; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSQLScannerTestOptionsoBackslashEscapesDoubleQuote(AContext: TNXTestContext);
var lFixture: TTestSQLScanner;
begin
  lFixture:=TTestSQLScanner.Create(AContext, 'TestOptionsoBackslashEscapesDoubleQuote');
  try
    lFixture.SetUp;
    try lFixture.TestOptionsoBackslashEscapesDoubleQuote; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegistertcsqlscannerTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcsqlscanner.TTestSQLScanner');
  lSuite.AddTest('TestAction', @RunTTestSQLScannerTestAction);
  lSuite.AddTest('TestAdd', @RunTTestSQLScannerTestAdd);
  lSuite.AddTest('TestAdmin', @RunTTestSQLScannerTestAdmin);
  lSuite.AddTest('TestAfter', @RunTTestSQLScannerTestAfter);
  lSuite.AddTest('TestALTER', @RunTTestSQLScannerTestALTER);
  lSuite.AddTest('TestAnd', @RunTTestSQLScannerTestAnd);
  lSuite.AddTest('TestAny', @RunTTestSQLScannerTestAny);
  lSuite.AddTest('TestAs', @RunTTestSQLScannerTestAs);
  lSuite.AddTest('TestASC', @RunTTestSQLScannerTestASC);
  lSuite.AddTest('TestASCENDING', @RunTTestSQLScannerTestASCENDING);
  lSuite.AddTest('TestAt', @RunTTestSQLScannerTestAt);
  lSuite.AddTest('TestAuto', @RunTTestSQLScannerTestAuto);
  lSuite.AddTest('TestAVG', @RunTTestSQLScannerTestAVG);
  lSuite.AddTest('TestAssign', @RunTTestSQLScannerTestAssign);
  lSuite.AddTest('TestBefore', @RunTTestSQLScannerTestBefore);
  lSuite.AddTest('TestBegin', @RunTTestSQLScannerTestBegin);
  lSuite.AddTest('TestBetween', @RunTTestSQLScannerTestBetween);
  lSuite.AddTest('TestBlob', @RunTTestSQLScannerTestBlob);
  lSuite.AddTest('TestBraceClose', @RunTTestSQLScannerTestBraceClose);
  lSuite.AddTest('TestBraceOpen', @RunTTestSQLScannerTestBraceOpen);
  lSuite.AddTest('TestBy', @RunTTestSQLScannerTestBy);
  lSuite.AddTest('TestCache', @RunTTestSQLScannerTestCache);
  lSuite.AddTest('TestCascade', @RunTTestSQLScannerTestCascade);
  lSuite.AddTest('TestChar', @RunTTestSQLScannerTestChar);
  lSuite.AddTest('TestCharacter', @RunTTestSQLScannerTestCharacter);
  lSuite.AddTest('TestCheck', @RunTTestSQLScannerTestCheck);
  lSuite.AddTest('TestCollate', @RunTTestSQLScannerTestCollate);
  lSuite.AddTest('TestColon', @RunTTestSQLScannerTestColon);
  lSuite.AddTest('TestColumn', @RunTTestSQLScannerTestColumn);
  lSuite.AddTest('TestComma', @RunTTestSQLScannerTestComma);
  lSuite.AddTest('TestCommit', @RunTTestSQLScannerTestCommit);
  lSuite.AddTest('TestComputed', @RunTTestSQLScannerTestComputed);
  lSuite.AddTest('TestConcatenate', @RunTTestSQLScannerTestConcatenate);
  lSuite.AddTest('TestConditional', @RunTTestSQLScannerTestConditional);
  lSuite.AddTest('TestConnect', @RunTTestSQLScannerTestConnect);
  lSuite.AddTest('TestConstraint', @RunTTestSQLScannerTestConstraint);
  lSuite.AddTest('TestContaining', @RunTTestSQLScannerTestContaining);
  lSuite.AddTest('TestCount', @RunTTestSQLScannerTestCount);
  lSuite.AddTest('TestCreate', @RunTTestSQLScannerTestCreate);
  lSuite.AddTest('TestCString', @RunTTestSQLScannerTestCString);
  lSuite.AddTest('TestDatabase', @RunTTestSQLScannerTestDatabase);
  lSuite.AddTest('TestDate', @RunTTestSQLScannerTestDate);
  lSuite.AddTest('TestDecimal', @RunTTestSQLScannerTestDecimal);
  lSuite.AddTest('TestDeclare', @RunTTestSQLScannerTestDeclare);
  lSuite.AddTest('TestDefault', @RunTTestSQLScannerTestDefault);
  lSuite.AddTest('TestDelete', @RunTTestSQLScannerTestDelete);
  lSuite.AddTest('TestDesc', @RunTTestSQLScannerTestDesc);
  lSuite.AddTest('TestDescending', @RunTTestSQLScannerTestDescending);
  lSuite.AddTest('TestDistinct', @RunTTestSQLScannerTestDistinct);
  lSuite.AddTest('TestDiv', @RunTTestSQLScannerTestDiv);
  lSuite.AddTest('TestDO', @RunTTestSQLScannerTestDO);
  lSuite.AddTest('TestDomain', @RunTTestSQLScannerTestDomain);
  lSuite.AddTest('TestDot', @RunTTestSQLScannerTestDot);
  lSuite.AddTest('TestDrop', @RunTTestSQLScannerTestDrop);
  lSuite.AddTest('TestElse', @RunTTestSQLScannerTestElse);
  lSuite.AddTest('TestEmpty', @RunTTestSQLScannerTestEmpty);
  lSuite.AddTest('TestEnd', @RunTTestSQLScannerTestEnd);
  lSuite.AddTest('TestEntryPoint', @RunTTestSQLScannerTestEntryPoint);
  lSuite.AddTest('TestEq', @RunTTestSQLScannerTestEq);
  lSuite.AddTest('TestEscape', @RunTTestSQLScannerTestEscape);
  lSuite.AddTest('TestException', @RunTTestSQLScannerTestException);
  lSuite.AddTest('TestExists', @RunTTestSQLScannerTestExists);
  lSuite.AddTest('TestExit', @RunTTestSQLScannerTestExit);
  lSuite.AddTest('TestExternal', @RunTTestSQLScannerTestExternal);
  lSuite.AddTest('TestExtract', @RunTTestSQLScannerTestExtract);
  lSuite.AddTest('TestFile', @RunTTestSQLScannerTestFile);
  lSuite.AddTest('TestFloat', @RunTTestSQLScannerTestFloat);
  lSuite.AddTest('TestFor', @RunTTestSQLScannerTestFor);
  lSuite.AddTest('TestForeign', @RunTTestSQLScannerTestForeign);
  lSuite.AddTest('TestFreeIt', @RunTTestSQLScannerTestFreeIt);
  lSuite.AddTest('TestFunction', @RunTTestSQLScannerTestFunction);
  lSuite.AddTest('TestGDSError', @RunTTestSQLScannerTestGDSError);
  lSuite.AddTest('TestGE', @RunTTestSQLScannerTestGE);
  lSuite.AddTest('TestGenerator', @RunTTestSQLScannerTestGenerator);
  lSuite.AddTest('TestGrant', @RunTTestSQLScannerTestGrant);
  lSuite.AddTest('TestGreaterThan', @RunTTestSQLScannerTestGreaterThan);
  lSuite.AddTest('TestGroup', @RunTTestSQLScannerTestGroup);
  lSuite.AddTest('TestHaving', @RunTTestSQLScannerTestHaving);
  lSuite.AddTest('TestIf', @RunTTestSQLScannerTestIf);
  lSuite.AddTest('TestIn', @RunTTestSQLScannerTestIn);
  lSuite.AddTest('TestIndex', @RunTTestSQLScannerTestIndex);
  lSuite.AddTest('TestInner', @RunTTestSQLScannerTestInner);
  lSuite.AddTest('TestInsert', @RunTTestSQLScannerTestInsert);
  lSuite.AddTest('TestInt', @RunTTestSQLScannerTestInt);
  lSuite.AddTest('TestInteger', @RunTTestSQLScannerTestInteger);
  lSuite.AddTest('TestInto', @RunTTestSQLScannerTestInto);
  lSuite.AddTest('TestIs', @RunTTestSQLScannerTestIs);
  lSuite.AddTest('TestJoin', @RunTTestSQLScannerTestJoin);
  lSuite.AddTest('TestKey', @RunTTestSQLScannerTestKey);
  lSuite.AddTest('TestLeft', @RunTTestSQLScannerTestLeft);
  lSuite.AddTest('TestLength', @RunTTestSQLScannerTestLength);
  lSuite.AddTest('TestLike', @RunTTestSQLScannerTestLike);
  lSuite.AddTest('TestLE', @RunTTestSQLScannerTestLE);
  lSuite.AddTest('TestLessThan', @RunTTestSQLScannerTestLessThan);
  lSuite.AddTest('TestManual', @RunTTestSQLScannerTestManual);
  lSuite.AddTest('TestModuleName', @RunTTestSQLScannerTestModuleName);
  lSuite.AddTest('TestMax', @RunTTestSQLScannerTestMax);
  lSuite.AddTest('TestMerge', @RunTTestSQLScannerTestMerge);
  lSuite.AddTest('TestMin', @RunTTestSQLScannerTestMin);
  lSuite.AddTest('TestMinus', @RunTTestSQLScannerTestMinus);
  lSuite.AddTest('TestMul', @RunTTestSQLScannerTestMul);
  lSuite.AddTest('TestNational', @RunTTestSQLScannerTestNational);
  lSuite.AddTest('TestNatural', @RunTTestSQLScannerTestNatural);
  lSuite.AddTest('TestNE', @RunTTestSQLScannerTestNE);
  lSuite.AddTest('TestNo', @RunTTestSQLScannerTestNo);
  lSuite.AddTest('TestNot', @RunTTestSQLScannerTestNot);
  lSuite.AddTest('TestNull', @RunTTestSQLScannerTestNull);
  lSuite.AddTest('TestNumeric', @RunTTestSQLScannerTestNumeric);
  lSuite.AddTest('TestOn', @RunTTestSQLScannerTestOn);
  lSuite.AddTest('TestOption', @RunTTestSQLScannerTestOption);
  lSuite.AddTest('TestOr', @RunTTestSQLScannerTestOr);
  lSuite.AddTest('TestOrder', @RunTTestSQLScannerTestOrder);
  lSuite.AddTest('TestOuter', @RunTTestSQLScannerTestOuter);
  lSuite.AddTest('TestPage', @RunTTestSQLScannerTestPage);
  lSuite.AddTest('TestPages', @RunTTestSQLScannerTestPages);
  lSuite.AddTest('TestPageSize', @RunTTestSQLScannerTestPageSize);
  lSuite.AddTest('TestPassword', @RunTTestSQLScannerTestPassword);
  lSuite.AddTest('TestPlus', @RunTTestSQLScannerTestPlus);
  lSuite.AddTest('TestPosition', @RunTTestSQLScannerTestPosition);
  lSuite.AddTest('TestPostEvent', @RunTTestSQLScannerTestPostEvent);
  lSuite.AddTest('TestPrimary', @RunTTestSQLScannerTestPrimary);
  lSuite.AddTest('TestPrivileges', @RunTTestSQLScannerTestPrivileges);
  lSuite.AddTest('TestProcedure', @RunTTestSQLScannerTestProcedure);
  lSuite.AddTest('TestPublic', @RunTTestSQLScannerTestPublic);
  lSuite.AddTest('TestReferences', @RunTTestSQLScannerTestReferences);
  lSuite.AddTest('TestRelease', @RunTTestSQLScannerTestRelease);
  lSuite.AddTest('TestReturningValues', @RunTTestSQLScannerTestReturningValues);
  lSuite.AddTest('TestReturns', @RunTTestSQLScannerTestReturns);
  lSuite.AddTest('TestRetain', @RunTTestSQLScannerTestRetain);
  lSuite.AddTest('TestRevoke', @RunTTestSQLScannerTestRevoke);
  lSuite.AddTest('TestRight', @RunTTestSQLScannerTestRight);
  lSuite.AddTest('TestRole', @RunTTestSQLScannerTestRole);
  lSuite.AddTest('TestRollback', @RunTTestSQLScannerTestRollback);
  lSuite.AddTest('TestSegment', @RunTTestSQLScannerTestSegment);
  lSuite.AddTest('TestSelect', @RunTTestSQLScannerTestSelect);
  lSuite.AddTest('TestSemicolon', @RunTTestSQLScannerTestSemicolon);
  lSuite.AddTest('TestSet', @RunTTestSQLScannerTestSet);
  lSuite.AddTest('TestSchema', @RunTTestSQLScannerTestSchema);
  lSuite.AddTest('TestShadow', @RunTTestSQLScannerTestShadow);
  lSuite.AddTest('TestSingular', @RunTTestSQLScannerTestSingular);
  lSuite.AddTest('TestSize', @RunTTestSQLScannerTestSize);
  lSuite.AddTest('TestSkip', @RunTTestSQLScannerTestSkip);
  lSuite.AddTest('TestSome', @RunTTestSQLScannerTestSome);
  lSuite.AddTest('TestSort', @RunTTestSQLScannerTestSort);
  lSuite.AddTest('TestSnapshot', @RunTTestSQLScannerTestSnapshot);
  lSuite.AddTest('TestSQLCode', @RunTTestSQLScannerTestSQLCode);
  lSuite.AddTest('TestSquareBraceClose', @RunTTestSQLScannerTestSquareBraceClose);
  lSuite.AddTest('TestSquareBraceOpen', @RunTTestSQLScannerTestSquareBraceOpen);
  lSuite.AddTest('TestStarting', @RunTTestSQLScannerTestStarting);
  lSuite.AddTest('TestString', @RunTTestSQLScannerTestString);
  lSuite.AddTest('TestSubtype', @RunTTestSQLScannerTestSubtype);
  lSuite.AddTest('TestSum', @RunTTestSQLScannerTestSum);
  lSuite.AddTest('TestSuspend', @RunTTestSQLScannerTestSuspend);
  lSuite.AddTest('TestTable', @RunTTestSQLScannerTestTable);
  lSuite.AddTest('TestThen', @RunTTestSQLScannerTestThen);
  lSuite.AddTest('TestTime', @RunTTestSQLScannerTestTime);
  lSuite.AddTest('TestTimeStamp', @RunTTestSQLScannerTestTimeStamp);
  lSuite.AddTest('TestTo', @RunTTestSQLScannerTestTo);
  lSuite.AddTest('TestTransaction', @RunTTestSQLScannerTestTransaction);
  lSuite.AddTest('TestTrigger', @RunTTestSQLScannerTestTrigger);
  lSuite.AddTest('TestType', @RunTTestSQLScannerTestType);
  lSuite.AddTest('TestUnion', @RunTTestSQLScannerTestUnion);
  lSuite.AddTest('TestUnique', @RunTTestSQLScannerTestUnique);
  lSuite.AddTest('TestUpdate', @RunTTestSQLScannerTestUpdate);
  lSuite.AddTest('TestUpper', @RunTTestSQLScannerTestUpper);
  lSuite.AddTest('TestUser', @RunTTestSQLScannerTestUser);
  lSuite.AddTest('TestValue', @RunTTestSQLScannerTestValue);
  lSuite.AddTest('TestValues', @RunTTestSQLScannerTestValues);
  lSuite.AddTest('TestVariable', @RunTTestSQLScannerTestVariable);
  lSuite.AddTest('TestVarChar', @RunTTestSQLScannerTestVarChar);
  lSuite.AddTest('TestVarying', @RunTTestSQLScannerTestVarying);
  lSuite.AddTest('TestView', @RunTTestSQLScannerTestView);
  lSuite.AddTest('TestWhen', @RunTTestSQLScannerTestWhen);
  lSuite.AddTest('TestWhere', @RunTTestSQLScannerTestWhere);
  lSuite.AddTest('TestWhile', @RunTTestSQLScannerTestWhile);
  lSuite.AddTest('TestWith', @RunTTestSQLScannerTestWith);
  lSuite.AddTest('TestWork', @RunTTestSQLScannerTestWork);
  lSuite.AddTest('TestTerm', @RunTTestSQLScannerTestTerm);
  lSuite.AddTest('TestTermExclude', @RunTTestSQLScannerTestTermExclude);
  lSuite.AddTest('TestRecreate', @RunTTestSQLScannerTestRecreate);
  lSuite.AddTest('TestRestart', @RunTTestSQLScannerTestRestart);
  lSuite.AddTest('TestSequence', @RunTTestSQLScannerTestSequence);
  lSuite.AddTest('Test2Words', @RunTTestSQLScannerTest2Words);
  lSuite.AddTest('Test3Words', @RunTTestSQLScannerTest3Words);
  lSuite.AddTest('TestIdentifier', @RunTTestSQLScannerTestIdentifier);
  lSuite.AddTest('TestIdentifier2', @RunTTestSQLScannerTestIdentifier2);
  lSuite.AddTest('TestIdentifier3', @RunTTestSQLScannerTestIdentifier3);
  lSuite.AddTest('TestIdentifier4', @RunTTestSQLScannerTestIdentifier4);
  lSuite.AddTest('TestIdentifier5', @RunTTestSQLScannerTestIdentifier5);
  lSuite.AddTest('TestIdentifier6', @RunTTestSQLScannerTestIdentifier6);
  lSuite.AddTest('TestIdentifierDotIdentifier', @RunTTestSQLScannerTestIdentifierDotIdentifier);
  lSuite.AddTest('TestEOLN', @RunTTestSQLScannerTestEOLN);
  lSuite.AddTest('TestEOLN2', @RunTTestSQLScannerTestEOLN2);
  lSuite.AddTest('TestEOLN3', @RunTTestSQLScannerTestEOLN3);
  lSuite.AddTest('TestEOLN4', @RunTTestSQLScannerTestEOLN4);
  lSuite.AddTest('TestComment1', @RunTTestSQLScannerTestComment1);
  lSuite.AddTest('TestComment2', @RunTTestSQLScannerTestComment2);
  lSuite.AddTest('TestComment3', @RunTTestSQLScannerTestComment3);
  lSuite.AddTest('TestComment4', @RunTTestSQLScannerTestComment4);
  lSuite.AddTest('TestComment5', @RunTTestSQLScannerTestComment5);
  lSuite.AddTest('TestComment6', @RunTTestSQLScannerTestComment6);
  lSuite.AddTest('TestFloatLiteral', @RunTTestSQLScannerTestFloatLiteral);
  lSuite.AddTest('TestStringLiteral1', @RunTTestSQLScannerTestStringLiteral1);
  lSuite.AddTest('TestStringLiteral2', @RunTTestSQLScannerTestStringLiteral2);
  lSuite.AddTest('TestSymbolLiteral1', @RunTTestSQLScannerTestSymbolLiteral1);
  lSuite.AddTest('TestSymbolLiteral2', @RunTTestSQLScannerTestSymbolLiteral2);
  lSuite.AddTest('TestStringError', @RunTTestSQLScannerTestStringError);
  lSuite.AddTest('TestFloatError', @RunTTestSQLScannerTestFloatError);
  lSuite.AddTest('TestOptionsoDoubleQuoteStringLiteral', @RunTTestSQLScannerTestOptionsoDoubleQuoteStringLiteral);
  lSuite.AddTest('TestOptionsoSingleQuoteIdentifier', @RunTTestSQLScannerTestOptionsoSingleQuoteIdentifier);
  lSuite.AddTest('TestOptionsoBackQuoteIdentifier', @RunTTestSQLScannerTestOptionsoBackQuoteIdentifier);
  lSuite.AddTest('TestOptionNosoBackQuoteIdentifier', @RunTTestSQLScannerTestOptionNosoBackQuoteIdentifier);
  lSuite.AddTest('TestOptionNosoBackslashEscapes', @RunTTestSQLScannerTestOptionNosoBackslashEscapes);
  lSuite.AddTest('TestOptionsoBackslashEscapesTab', @RunTTestSQLScannerTestOptionsoBackslashEscapesTab);
  lSuite.AddTest('TestOptionsoBackslashEscapesNewLine', @RunTTestSQLScannerTestOptionsoBackslashEscapesNewLine);
  lSuite.AddTest('TestOptionsoBackslashEscapesBackSlash', @RunTTestSQLScannerTestOptionsoBackslashEscapesBackSlash);
  lSuite.AddTest('TestOptionsoBackslashEscapesBackspace', @RunTTestSQLScannerTestOptionsoBackslashEscapesBackspace);
  lSuite.AddTest('TestOptionsoBackslashEscapesLineFeed', @RunTTestSQLScannerTestOptionsoBackslashEscapesLineFeed);
  lSuite.AddTest('TestOptionsoBackslashEscapesNewPage', @RunTTestSQLScannerTestOptionsoBackslashEscapesNewPage);
  lSuite.AddTest('TestOptionsoBackslashEscapesSlash', @RunTTestSQLScannerTestOptionsoBackslashEscapesSlash);
  lSuite.AddTest('TestOptionsoBackslashEscapesQuote', @RunTTestSQLScannerTestOptionsoBackslashEscapesQuote);
  lSuite.AddTest('TestOptionsoBackslashEscapesDoubleQuote', @RunTTestSQLScannerTestOptionsoBackslashEscapesDoubleQuote);
end;

end.

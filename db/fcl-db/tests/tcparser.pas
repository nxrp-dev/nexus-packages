{
    This file is part of the Free Component Library
    Copyright (c) 2010-2014 by the Free Pascal development team

    SQL source syntax parser test suite

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
unit tcparser;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpsqltree, fpsqlscanner, fpsqlparser;

type

  { TTestParser }

  TTestParser = Class(TSQLParser)
  public
    Procedure ParseStringDef(Out DT : TSQLDataType; Out Len : Integer; Out ACharset : TSQLStringtype);
    Function  ParseType(Flags : TParseTypeFlags) : TSQLTypeDefinition;
    Function  ParseConstraint : TSQLExpression;
    Function  ParseProcedureStatements : TSQLStatement;
  end;

  { TTestSQLParser }

  TTestSQLParser = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  Private
    FParserOptions: TParserOptions;
    FSource : TStringStream;
    FParser : TTestParser;
    FToFree : TSQLElement; //will be freed by test teardown
    FErrSource : string;
    function GetParserOptions: TParserOptions;
  protected
    procedure AssertTypeDefaults(TD: TSQLTypeDefinition; Len: Integer=0);
    procedure TestStringDef(ASource: String; ExpectDT: TSQLDataType; ExpectLen: Integer; ExpectCharset : TSQLStringType='');
    function TestType(ASource : string; AFlags : TParseTypeFlags; AExpectedType : TSQLDataType) : TSQLTypeDefinition;
    function TestCheck(ASource : string; AExpectedConstraint : TSQLElementClass) : TSQLExpression;
    procedure CreateParser(Const ASource : string; aOptions : TParserOptions = []);
    function CheckClass(E : TSQLElement; C : TSQLElementClass) : TSQLElement;
    procedure TestDropStatement(Const ASource : string;C : TSQLElementClass);
    function TestCreateStatement(Const ASource,AName : string;C: TSQLElementClass) : TSQLCreateOrAlterStatement;
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function AssertLiteralExpr(Const AMessage : String; Element : TSQLExpression; ALiteralClass : TSQLElementClass) : TSQLLiteral;
    procedure AssertIdentifierName(Const AMessage : String; Const AExpected : String; Element : TSQLElement);
    procedure AssertField(AField : TSQLElement; Const AName : String; Const AAlias : String = '');
    procedure AssertAggregate(AField : TSQLElement; AAgregate : TSQLAggregateFunction; Const AFieldName : String; AOption : TSQLAggregateOption; Const AAlias : String = '');
    procedure AssertAggregateExpression(E : TSQLElement; AAgregate : TSQLAggregateFunction; Const AFieldName : String; AOption : TSQLAggregateOption);
    procedure AssertTable(ATable : TSQLElement; Const AName : String; Const AAlias : String = '');
    function AssertJoin(AJoin : TSQLElement; Const AFirst,ASecond : String; Const aJoinType : TSQLJoinType) : TSQLJoinTableReference;
    function AssertJoinOn(AJoin : TSQLExpression; Const AFirst,ASecond : String; Const AOperation : TSQLBinaryOperation) : TSQLBinaryExpression;
    function AssertOrderBy(AOrderBy : TSQLElement; Const AField : String; Const ANumber : Integer; Const AOrdering : TSQLOrderDirection) : TSQLOrderByElement;
    function AssertSecondaryFile(ASecondaryFile : TSQLElement; Const AFile : String; Const ALength,AStart : Integer) : TSQLDatabaseFileInfo;
    procedure TestTypeError;
    procedure TestStringError;
    procedure TestCheckError;
    procedure TestParseError;
    procedure SetUp; virtual;
    procedure TearDown; virtual;
    property Parser : TTestParser Read FParser;
    property ParserOptions : TParserOptions Read GetParserOptions Write FParserOptions;
    property ToFree : TSQLElement Read FToFree Write FTofree;
  end;

  { TTestDropParser }

  TTestDropParser = Class(TTestSQLParser)
  public
    procedure TestDropDatabase;
    procedure TestDropDomain;
    procedure TestDropException;
    procedure TestDropGenerator;
    procedure TestDropIndex;
    procedure TestDropProcedure;
    procedure TestDropRole;
    procedure TestDropTable;
    procedure TestDropTrigger;
    procedure TestDropView;
    procedure TestDropShadow;
    procedure TestDropExternalFunction;
  end;

  { TTestGeneratorParser }

  TTestGeneratorParser = Class(TTestSQLParser)
  public
    procedure TestCreateGenerator;
    procedure TestCreateSequence;
    procedure TestAlterSequence;
    procedure TestSetGenerator;
  end;

  { TTestSetTermParser }

  TTestSetTermParser = Class(TTestSQLParser)
  public
    procedure TestSetTermNoOption;
    procedure TestSetTermOption;
  end;


  { TTestRoleParser }

  TTestRoleParser = Class(TTestSQLParser)
  public
    procedure TestCreateRole;
    procedure TestAlterRole;
  end;

  { TTestTypeParser }

  TTestTypeParser = Class(TTestSQLParser)
  private
  public
    procedure TestStringType1;
    procedure TestStringType2;
    procedure TestStringType3;
    procedure TestStringType4;
    procedure TestStringType5;
    procedure TestStringType6;
    procedure TestStringType7;
    procedure TestStringType8;
    procedure TestStringType9;
    procedure TestStringType10;
    procedure TestStringType11;
    procedure TestStringType12;
    procedure TestStringType13;
    procedure TestStringType14;
    procedure TestStringType15;
    procedure TestStringType16;
    procedure TestStringType17;
    procedure TestStringType18;
    procedure TestStringType19;
    procedure TestStringTypeErrors1;
    procedure TestStringTypeErrors2;
    procedure TestStringTypeErrors3;
    procedure TestTypeInt1;
    procedure TestTypeInt2;
    procedure TestTypeInt3;
    procedure TestTypeInt4;
    procedure TestTypeInt5;
    procedure TestNumerical1;
    procedure TestNumerical2;
    procedure TestNumerical3;
    procedure TestNumericalError1;
    procedure TestNumericalError2;
    procedure TestNumericalError3;
    procedure TestNumericalError4;
    procedure TestNumericalError5;
    procedure TestNumericalError6;
    procedure TestNumericalError7;
    procedure TestBlob1;
    procedure TestBlob2;
    procedure TestBlob3;
    procedure TestBlob4;
    procedure TestBlob5;
    procedure TestBlob6;
    procedure TestBlob7;
    procedure TestBlob8;
    procedure TestBlobError1;
    procedure TestBlobError2;
    procedure TestBlobError3;
    procedure TestBlobError4;
    procedure TestBlobError5;
    procedure TestBlobError6;
    procedure TestBlobError7;
    procedure TestSmallInt;
    procedure TestFloat;
    procedure TestDoublePrecision;
    procedure TestDoublePrecisionDefault;
  end;

  { TTestCheckParser }

  TTestCheckParser = Class (TTestSQLParser)
  private
  public
    procedure TestCheckNull;
    procedure TestCheckNotNull;
    procedure TestCheckBraces;
    procedure TestCheckBracesError;
    procedure TestCheckParamError;
    procedure TestCheckIdentifierError;
    procedure TestIsEqual;
    procedure TestIsNotEqual1;
    procedure TestIsNotEqual2;
    procedure TestGreaterThan;
    procedure TestGreaterThanEqual1;
    procedure TestGreaterThanEqual2;
    procedure TestLessThan;
    procedure TestLessThanEqual1;
    procedure TestLessThanEqual2;
    procedure TestLike;
    procedure TestNotLike;
    procedure TestContaining;
    procedure TestNotContaining;
    procedure TestStarting;
    procedure TestNotStarting;
    procedure TestStartingWith;
    procedure TestNotStartingWith;
    procedure TestBetween;
    procedure TestNotBetween;
    procedure TestLikeEscape;
    procedure TestNotLikeEscape;
    procedure TestAnd;
    procedure TestOr;
    procedure TestNotOr;
    procedure TestCase;
    procedure TestCaseWithSelector;
    procedure TestAdd;
    procedure TestSubtract;
    procedure TestMultiply;
    procedure TestDivide;
  end;

  { TTestDomainParser }

  // Most relevant tests are in type definition testing.
  TTestDomainParser = Class(TTestSQLParser)
  private
  public
    procedure TestSimpleDomain;
    procedure TestSimpleDomainAs;
    procedure TestNotNullDomain;
    procedure TestDefaultNotNullDomain;
    procedure TestCheckDomain;
    procedure TestDefaultCheckNotNullDomain;
    procedure TestAlterDomainDropDefault;
    procedure TestAlterDomainDropCheck;
    procedure TestAlterDomainDropCheckError;
    procedure TestAlterDomainAddCheck;
    procedure TestAlterDomainAddConstraintCheck;
    procedure TestAlterDomainAddConstraintError;
    procedure TestAlterDomainSetDefault;
    procedure TestAlterDomainRename;
    procedure TestAlterDomainNewType;
    procedure TestAlterDomainNewTypeError1;
    procedure TestAlterDomainNewTypeError2;
  end;

  { TTestExceptionParser }

  TTestExceptionParser = Class(TTestSQLParser)
  public
    procedure TestException;
    procedure TestAlterException;
    procedure TestExceptionError1;
    procedure TestExceptionError2;
  end;

  { TTestIndexParser }

  TTestIndexParser = Class(TTestSQLParser)
  private
  public
    procedure TestAlterindexActive;
    procedure TestAlterindexInactive;
    procedure TestCreateIndexSimple;
    procedure TestIndexIndexDouble;
    procedure TestCreateIndexAscending;
    procedure TestCreateIndexDescending;
    procedure TestCreateIndexUnique;
    procedure TestCreateIndexUniqueAscending;
    procedure TestCreateIndexUniqueDescending;
    procedure TestIndexError1;
    procedure TestIndexError2;
    procedure TestIndexError3;
    procedure TestIndexError4;
    procedure TestIndexError5;
    procedure TestIndexError6;
  end;

  { TTestTableParser }

  TTestTableParser = Class(TTestSQLParser)
  private
    procedure DoTestCreateReferencesField(Const ASource : String; AOnUpdate,AOnDelete : TForeignKeyAction);
  public
    procedure TestCreateOneSimpleField;
    procedure TestCreateTwoSimpleFields;
    procedure TestCreateOnePrimaryField;
    procedure TestCreateOneNamedPrimaryField;
    procedure TestCreateOneUniqueField;
    procedure TestCreateOneNamedUniqueField;
    procedure TestCreateNotNullPrimaryField;
    procedure TestCreateNotNullDefaultPrimaryField;
    procedure TestCreateComputedByField;
    procedure TestCreateCheckField;
    procedure TestCreateNamedCheckField;
    procedure TestCreateReferencesField;
    procedure TestCreateReferencesOnUpdateCascadeField;
    procedure TestCreateReferencesOnUpdateNoActionField;
    procedure TestCreateReferencesOnUpdateSetDefaultField;
    procedure TestCreateReferencesOnUpdateSetNullField;
    procedure TestCreateReferencesOnDeleteCascadeField;
    procedure TestCreateReferencesOnDeleteNoActionField;
    procedure TestCreateReferencesOnDeleteSetDefaultField;
    procedure TestCreateReferencesOnDeleteSetNullField;
    procedure TestCreateReferencesOnUpdateAndDeleteSetNullField;
    procedure TestCreateNamedReferencesField;
    procedure TestCreatePrimaryKeyConstraint;
    procedure TestCreateNamedPrimaryKeyConstraint;
    procedure TestCreateForeignKeyConstraint;
    procedure TestCreateNamedForeignKeyConstraint;
    procedure TestCreateUniqueConstraint;
    procedure TestCreateNamedUniqueConstraint;
    procedure TestCreateCheckConstraint;
    procedure TestCreateNamedCheckConstraint;
    procedure TestAlterDropField;
    procedure TestAlterDropFields;
    procedure TestAlterDropConstraint;
    procedure TestAlterDropConstraints;
    procedure TestAlterRenameField;
    procedure TestAlterRenameColumnField;
    procedure TestAlterFieldType;
    procedure TestAlterFieldPosition;
    procedure TestAlterAddField;
    procedure TestAlterAddFields;
    procedure TestAlterAddPrimarykey;
    procedure TestAlterAddNamedPrimarykey;
    procedure TestAlterAddCheckConstraint;
    procedure TestAlterAddNamedCheckConstraint;
    procedure TestAlterAddForeignkey;
    procedure TestAlterAddNamedForeignkey;
  end;

  { TTestDeleteParser }

  TTestDeleteParser = Class(TTestSQLParser)
  Private
    function TestDelete(Const ASource , ATable: String) : TSQLDeleteStatement;
  public
    procedure TestSimpleDelete;
    procedure TestSimpleDeleteAlias;
    procedure TestDeleteWhereNull;
  end;

  { TTestUpdateParser }

  TTestUpdateParser = Class(TTestSQLParser)
  Private
    function TestUpdate(Const ASource , ATable: String) : TSQLUpdateStatement;
  public
    procedure TestUpdateOneField;
    procedure TestUpdateOneFieldFull;
    procedure TestUpdateTwoFields;
    procedure TestUpdateOneFieldWhereIsNull;
  end;

  { TTestInsertParser }

  TTestInsertParser = Class(TTestSQLParser)
  Private
    function TestInsert(Const ASource , ATable: String) : TSQLInsertStatement;
  public
    procedure TestInsertOneField;
    procedure TestInsertTwoFields;
    procedure TestInsertOneValue;
    procedure TestInsertTwoValues;
  end;

  { TTestSelectParser }

  TTestSelectParser = Class(TTestSQLParser)
  Private
    FSelect : TSQLSelectStatement;
    function TestSelect(Const ASource : String; AOptions : TParserOptions = []; AScannerOptions : TSQLScannerOptions = []) : TSQLSelectStatement;
    procedure TestSelectError(Const ASource : String);
    procedure DoExtractSimple(Expected : TSQLExtractElement);
    property Select : TSQLSelectStatement Read FSelect;
  public
    procedure TestSelectOneFieldOneTable;
    procedure TestSelectOneFieldOneTableTransaction;
    procedure TestSelectOneArrayFieldOneTable;
    procedure TestSelectTwoFieldsOneTable;
    procedure TestSelectOneFieldAliasOneTable;
    procedure TestSelectTwoFieldAliasesOneTable;
    procedure TestSelectOneTableFieldOneTable;
    procedure TestSelectOneDistinctFieldOneTable;
    procedure TestSelectOneAllFieldOneTable;
    procedure TestSelectAsteriskOneTable;
    procedure TestSelectDistinctAsteriskOneTable;
    procedure TestSelectAsteriskWithPath;
    procedure TestSelectOneFieldOneTableAlias;
    procedure TestSelectOneFieldOneTableAsAlias;
    procedure TestSelectTwoFieldsTwoTables;
    procedure TestSelectTwoFieldsTwoTablesJoin;
    procedure TestSelectTwoFieldsTwoInnerTablesJoin;
    procedure TestSelectTwoFieldsTwoLeftTablesJoin;
    procedure TestSelectTwoFieldsTwoFullOuterTablesJoin;
    procedure TestSelectTwoFieldsTwoFullTablesJoin;
    procedure TestSelectTwoFieldsTwoRightTablesJoin;
    procedure TestSelectTwoFieldsThreeTablesJoin;
    procedure TestSelectTwoFieldsBracketThreeTablesJoin;
    procedure TestSelectTwoFieldsThreeBracketTablesJoin;
    procedure TestSelectTableWithSchema;
    procedure TestSelectFieldWithSchema;
    procedure TestSelectFieldAsStringLiteral;
    procedure TestSelectFirst;
    procedure TestSelectFirstSkip;
    procedure TestSelectTop;
    procedure TestSelectLimit;
    procedure TestSelectLimitAll;
    procedure TestSelectLimitAllOffset;
    procedure TestSelectLimitOffset1;
    procedure TestSelectLimitOffset2;
    procedure TestSelectOffset;
    procedure TestAggregateCount;
    procedure TestAggregateCountAsterisk;
    procedure TestAggregateCountAll;
    procedure TestAggregateCountDistinct;
    procedure TestAggregateMax;
    procedure TestAggregateMaxAll;
    procedure TestAggregateMaxAsterisk;
    procedure TestAggregateMaxDistinct;
    procedure TestAggregateMin;
    procedure TestAggregateMinAll;
    procedure TestAggregateMinAsterisk;
    procedure TestAggregateMinDistinct;
    procedure TestAggregateSum;
    procedure TestAggregateSumAll;
    procedure TestAggregateSumAsterisk;
    procedure TestAggregateSumDistinct;
    procedure TestAggregateAvg;
    procedure TestAggregateAvgAll;
    procedure TestAggregateAvgAsterisk;
    procedure TestAggregateAvgDistinct;
    procedure TestUpperConst;
    procedure TestUpperError;
    procedure TestLeft;
    procedure TestFunctionWithPath;
    procedure TestGenID;
    procedure TestGenIDError1;
    procedure TestGenIDError2;
    procedure TestCastSimple;
    procedure TestExtractSimple;
    procedure TestOrderByOneField;
    procedure TestOrderByTwoFields;
    procedure TestOrderByThreeFields;
    procedure TestOrderByOneDescField;
    procedure TestOrderByTwoDescFields;
    procedure TestOrderByThreeDescFields;
    procedure TestOrderByOneTableField;
    procedure TestOrderByOneColumn;
    procedure TestOrderByTwoColumns;
    procedure TestOrderByTwoColumnsDesc;
    procedure TestOrderByCollate;
    procedure TestOrderByCollateDesc;
    procedure TestOrderByCollateDescTwoFields;
    procedure TestOrderByUpper;
    procedure TestGroupByOne;
    procedure TestGroupByTwo;
    procedure TestHavingOne;
    procedure TestUnionSimple;
    procedure TestUnionSimpleAll;
    procedure TestUnionSimpleOrderBy;
    procedure TestUnionDouble;
    procedure TestUnionError1;
    procedure TestUnionError2;
    procedure TestPlanOrderNatural;
    procedure TestPlanOrderOrder;
    procedure TestPlanOrderIndex1;
    procedure TestPlanOrderIndex2;
    procedure TestPlanJoinNatural;
    procedure TestPlanDefaultNatural;
    procedure TestPlanMergeNatural;
    procedure TestPlanMergeNested;
    procedure TestSubSelect;
    procedure TestWhereExists;
    procedure TestWhereSingular;
    procedure TestWhereAll;
    procedure TestWhereAny;
    procedure TestWhereSome;
    procedure TestWhereInRange;
    procedure TestWhereDotFloat;
    procedure TestParam;
    procedure TestParam_Underscore;
    procedure TestParamExpr;
    procedure TestNoTable;
    procedure TestSourcePosition;
    procedure TestForUpdate;
    procedure TestForUpdateNowait;
    procedure TestForUpdateOf;
    procedure TestWithLock;
  end;

  { TTestRollBackParser }

  TTestRollBackParser = Class(TTestSQLParser)
  Private
    FRollback : TSQLRollbackStatement;
    function TestRollback(Const ASource : String) : TSQLRollbackStatement;
    procedure TestRollbackError(Const ASource : String);
    property Rollback : TSQLRollbackStatement Read FRollback;
  public
    procedure TestRollback;
    procedure TestRollbackWork;
    procedure TestRollbackRelease;
    procedure TestRollbackWorkRelease;
    procedure TestRollbackTransaction;
    procedure TestRollbackTransactionWork;
    procedure TestRollbackTransactionRelease;
    procedure TestRollbackTransactionWorkRelease;
  end;

  { TTestCommitParser }

  TTestCommitParser = Class(TTestSQLParser)
  Private
    FCommit : TSQLCommitStatement;
    function TestCommit(Const ASource : String) : TSQLCommitStatement;
    procedure TestCommitError(Const ASource : String);
    property Commit : TSQLCommitStatement Read FCommit;
  public
    procedure TestCommit;
    procedure TestCommitWork;
    procedure TestCommitRelease;
    procedure TestCommitWorkRelease;
    procedure TestCommitTransaction;
    procedure TestCommitTransactionWork;
    procedure TestCommitTransactionRelease;
    procedure TestCommitTransactionWorkRelease;
    procedure TestCommitRetain;
    procedure TestCommitWorkRetain;
    procedure TestCommitReleaseRetain;
    procedure TestCommitWorkReleaseRetain;
    procedure TestCommitTransactionRetain;
    procedure TestCommitTransactionWorkRetain;
    procedure TestCommitTransactionReleaseRetain;
    procedure TestCommitTransactionWorkReleaseRetain;
    procedure TestCommitRetainSnapShot;
  end;

  { TTestExecuteProcedureParser }

  TTestExecuteProcedureParser = Class(TTestSQLParser)
  Private
    FExecute : TSQLExecuteProcedureStatement;
    function TestExecute(Const ASource : String) : TSQLExecuteProcedureStatement;
    procedure TestExecuteError(Const ASource : String);
    property Execute: TSQLExecuteProcedureStatement Read FExecute;
  public
    procedure TestExecuteSimple;
    procedure TestExecuteSimpleTransaction;
    procedure TestExecuteSimpleReturningValues;
    procedure TestExecuteSimpleReturning2Values;
    procedure TestExecuteOneArg;
    procedure TestExecuteOneArgNB;
    procedure TestExecuteTwoArgs;
    procedure TestExecuteTwoArgsNB;
    procedure TestExecuteOneArgSelect;
    procedure TestExecuteOneArgSelectNB;
    procedure TestExecuteTwoArgsSelect;
    procedure TestExecuteTwoArgsSelectNB;
    procedure TestExecuteOneArgSelectErr;
    procedure TestExecuteOneArgSelectErr2;
    procedure TestExecuteOneArgSelectErr3;
    procedure TestExecuteOneArgSelectErr4;
  end;

  { TTestConnectParser }

  TTestConnectParser = Class(TTestSQLParser)
  Private
    FConnect : TSQLConnectStatement;
    function TestConnect(Const ASource : String) : TSQLConnectStatement;
    procedure TestConnectError(Const ASource : String);
    property Connect: TSQLConnectStatement Read FConnect;
  public
    procedure TestConnectSimple;
    procedure TestConnectUser;
    procedure TestConnectPassword;
    procedure TestConnectUserPassword;
    procedure TestConnectUserPasswordRole;
    procedure TestConnectUserPasswordRoleCache;
    procedure TestConnectSimpleCache;
  end;

  { TTestCreateDatabaseParser }

  TTestCreateDatabaseParser = Class(TTestSQLParser)
  Private
    FCreateDB : TSQLCreateDatabaseStatement;
    function TestCreate(Const ASource : String) : TSQLCreateDatabaseStatement;
    procedure TestCreateError(Const ASource : String);
    property CreateDB : TSQLCreateDatabaseStatement Read FCreateDB;
  public
    procedure TestSimple;
    procedure TestSimpleSchema;
    procedure TestSimpleUSer;
    procedure TestSimpleUSerPassword;
    procedure TestSimplePassword;
    procedure TestPageSize;
    procedure TestPageSize2;
    procedure TestPageSizeLength;
    procedure TestPageSizeLength2;
    procedure TestPageSizeLength3;
    procedure TestPageSizeLength4;
    procedure TestCharset;
    procedure TestSecondaryFile1;
    procedure TestSecondaryFile2;
    procedure TestSecondaryFile3;
    procedure TestSecondaryFile4;
    procedure TestSecondaryFile5;
    procedure TestSecondaryFile6;
    procedure TestSecondaryFile7;
    procedure TestSecondaryFile8;
    procedure TestSecondaryFile9;
    procedure TestSecondaryFile10;
    procedure TestSecondaryFileS;
    procedure TestSecondaryFileError1;
    procedure TestSecondaryFileError2;
    procedure TestSecondaryFileError3;
  end;

  { TTestAlterDatabaseParser }

  TTestAlterDatabaseParser = Class(TTestSQLParser)
  Private
    FAlterDB : TSQLAlterDatabaseStatement;
    function TestAlter(Const ASource : String) : TSQLAlterDatabaseStatement;
    procedure TestAlterError(Const ASource : String);
    property AlterDB : TSQLAlterDatabaseStatement Read FAlterDB;
  public
    procedure TestSimple;
    procedure TestLength;
    procedure TestStarting;
    procedure TestStartingLength;
    procedure TestFiles;
    procedure TestFiles2;
    procedure TestError;
    procedure TestFilesError;
  end;

  { TTestCreateViewParser }

  TTestCreateViewParser = Class(TTestSQLParser)
  Private
    FView : TSQLCreateViewStatement;
    function TestCreate(Const ASource : String) : TSQLCreateViewStatement;
    procedure TestCreateError(Const ASource : String);
    property View : TSQLCreateViewStatement Read FView;
  public
    procedure TestSimple;
    procedure TestFieldList;
    procedure TestFieldList2;
    procedure TestSimpleWithCheckoption;
  end;

  { TTestCreateShadowParser }

  TTestCreateShadowParser = Class(TTestSQLParser)
  Private
    FShadow : TSQLCreateShadowStatement;
    function TestCreate(Const ASource : String) : TSQLCreateShadowStatement;
    procedure TestCreateError(Const ASource : String);
    property Shadow : TSQLCreateShadowStatement Read FShadow;
  public
    procedure TestSimple;
    procedure TestLength;
    procedure TestLength2;
    procedure TestLength3;
    procedure TestLength4;
    procedure TestSecondaryFile1;
    procedure TestSecondaryFile2;
    procedure TestSecondaryFile3;
    procedure TestSecondaryFile4;
    procedure TestSecondaryFile5;
    procedure TestSecondaryFile6;
    procedure TestSecondaryFile7;
    procedure TestSecondaryFile8;
    procedure TestSecondaryFileS;
  end;

  { TTestProcedureStatement }

  TTestProcedureStatement = Class(TTestSQLParser)
  Private
    FStatement : TSQLStatement;
    procedure TestParseStatementError;
    function TestStatement(Const ASource : String) : TSQLStatement;
    procedure TestStatementError(Const ASource : String);
  Public
    property Statement : TSQLStatement Read FStatement;
  public
    procedure TestException;
    procedure TestExceptionError;
    procedure TestExit;
    procedure TestSuspend;
    procedure TestEmptyBlock;
    procedure TestExitBlock;
    procedure TestExitBlockError;
    procedure TestPostEvent;
    procedure TestPostEventColName;
    procedure TestPostError;
    procedure TestAssignSimple;
    procedure TestAssignSimpleNew;
    procedure TestAssignSelect;
    procedure TestBlockAssignSimple;
    procedure TestIf;
    procedure TestIfBlock;
    procedure TestIfElse;
    procedure TestIfBlockElse;
    procedure TestIfElseError;
    procedure TestIfBlockElseBlock;
    procedure TestIfErrorBracketLeft;
    procedure TestIfErrorBracketRight;
    procedure TestIfErrorNoThen;
    procedure TestIfErrorSemicolonElse;
    procedure TestWhile;
    procedure TestWhileBlock;
    procedure TestWhileErrorBracketLeft;
    procedure TestWhileErrorBracketRight;
    procedure TestWhileErrorNoDo;
    procedure TestWhenAny;
    procedure TestWhenSQLCode;
    procedure TestWhenGDSCode;
    procedure TestWhenException;
    procedure TestWhenExceptionGDS;
    procedure TestWhenAnyBlock;
    procedure TestWhenErrorAny;
    procedure TestWhenErrorNoDo;
    procedure TestWhenErrorExceptionInt;
    procedure TestWhenErrorExceptionString;
    procedure TestWhenErrorSqlCode;
    procedure TestWhenErrorGDSCode;
    procedure TestExecuteStatement;
    procedure TestExecuteStatementReturningValues;
    procedure TestExecuteStatementReturningValuesColon;
    procedure TestExecuteStatementReturningValuesBrackets;
    procedure TestForSimple;
    procedure TestForSimpleNoColon;
    procedure TestForSimple2fields;
    procedure TestForBlock;
  end;

  { TTestCreateProcedureParser }

  TTestCreateProcedureParser = Class(TTestSQLParser)
  Private
    FStatement : TSQLCreateProcedureStatement;
    function TestCreate(Const ASource : String) : TSQLCreateProcedureStatement;
    procedure TestCreateError(Const ASource : String);
    property Statement : TSQLCreateProcedureStatement Read FStatement;
  public
    procedure TestEmptyProcedure;
    procedure TestExitProcedure;
    procedure TestProcedureOneArgument;
    procedure TestProcedureTwoArguments;
    procedure TestProcedureOneReturnValue;
    procedure TestProcedureTwoReturnValues;
    procedure TestProcedureOneLocalVariable;
    procedure TestProcedureTwoLocalVariable;
    procedure TestProcedureInputOutputLocal;
  end;

  { TTestCreateTriggerParser }

  TTestCreateTriggerParser = Class(TTestSQLParser)
  Private
    FStatement : TSQLAlterCreateTriggerStatement;
    function TestCreate(Const ASource : String) : TSQLCreateTriggerStatement;
    function TestAlter(Const ASource : String) : TSQLAlterTriggerStatement;
    procedure TestCreateError(Const ASource : String);
    property Statement : TSQLAlterCreateTriggerStatement Read FStatement;
  public
    procedure TestEmptyTrigger;
    procedure TestExitTrigger;
    procedure TestEmptyTriggerAfterUpdate;
    procedure TestEmptyTriggerBeforeDelete;
    procedure TestEmptyTriggerBeforeInsert;
    procedure TestEmptyTriggerBeforeInsertPosition1;
    procedure TestEmptyTriggerBeforeInsertPosition1inActive;
    procedure TestEmptyTriggerBeforeInsertPosition1Active;
    procedure TestTriggerOneLocalVariable;
    procedure TestTriggerTwoLocalVariables;
    procedure TestAlterTrigger;
  end;

  { TTestDeclareExternalFunctionParser }

  TTestDeclareExternalFunctionParser = Class(TTestSQLParser)
  Private
    FStatement : TSQLDeclareExternalFunctionStatement;
    function TestCreate(Const ASource : String) : TSQLDeclareExternalFunctionStatement;
    procedure TestCreateError(Const ASource : String);
    property Statement : TSQLDeclareExternalFunctionStatement Read FStatement;
  public
    procedure TestEmptyfunction;
    procedure TestEmptyfunctionByValue;
    procedure TestCStringfunction;
    procedure TestCStringFreeItfunction;
    procedure TestOneArgumentFunction;
    procedure TestTwoArgumentsFunction;
  end;

  { TTestGrantParser }

  TTestGrantParser = Class(TTestSQLParser)
  Private
    FStatement : TSQLGrantStatement;
    function TestGrant(Const ASource : String) : TSQLGrantStatement;
    procedure TestGrantError(Const ASource : String);
    property Statement : TSQLGrantStatement Read FStatement;
  public
    procedure TestSimple;
    procedure Test2Operations;
    procedure TestDeletePrivilege;
    procedure TestUpdatePrivilege;
    procedure TestInsertPrivilege;
    procedure TestReferencePrivilege;
    procedure TestAllPrivileges;
    procedure TestAllPrivileges2;
    procedure TestUpdateColPrivilege;
    procedure TestUpdate2ColsPrivilege;
    procedure TestReferenceColPrivilege;
    procedure TestReference2ColsPrivilege;
    procedure TestUserPrivilege;
    procedure TestUserPrivilegeWithGrant;
    procedure TestGroupPrivilege;
    procedure TestProcedurePrivilege;
    procedure TestViewPrivilege;
    procedure TestTriggerPrivilege;
    procedure TestPublicPrivilege;
    procedure TestExecuteToUser;
    procedure TestExecuteToProcedure;
    procedure TestRoleToUser;
    procedure TestRoleToUserWithAdmin;
    procedure TestRoleToPublic;
    procedure Test2RolesToUser;
  end;

  { TTestRevokeParser }

  TTestRevokeParser = Class(TTestSQLParser)
  Private
    FStatement : TSQLRevokeStatement;
    function TestRevoke(Const ASource : String) : TSQLRevokeStatement;
    procedure TestRevokeError(Const ASource : String);
    property Statement : TSQLRevokeStatement Read FStatement;
  public
    procedure TestSimple;
    procedure Test2Operations;
    procedure TestDeletePrivilege;
    procedure TestUpdatePrivilege;
    procedure TestInsertPrivilege;
    procedure TestReferencePrivilege;
    procedure TestAllPrivileges;
    procedure TestAllPrivileges2;
    procedure TestUpdateColPrivilege;
    procedure TestUpdate2ColsPrivilege;
    procedure TestReferenceColPrivilege;
    procedure TestReference2ColsPrivilege;
    procedure TestUserPrivilege;
    procedure TestUserPrivilegeWithRevoke;
    procedure TestGroupPrivilege;
    procedure TestProcedurePrivilege;
    procedure TestViewPrivilege;
    procedure TestTriggerPrivilege;
    procedure TestPublicPrivilege;
    procedure TestExecuteToUser;
    procedure TestExecuteToProcedure;
    procedure TestRoleToUser;
    procedure TestRoleToPublic;
    procedure Test2RolesToUser;
  end;

  { TTestGlobalParser }

  TTestGlobalParser = Class(TTestSQLParser)
  public
    procedure TestEmpty;
  end;

procedure RegistertcparserTests(ARegistry: TNXTestRegistry);

implementation

uses typinfo;

{ TTestSetTermParser }

procedure TTestSetTermParser.TestSetTermNoOption;
begin
  FErrSource:='SET TERM ^ ;';
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestSetTermParser.TestSetTermOption;
begin
  CreateParser('SET TERM ^ ;');
  FToFree:=Parser.Parse([poAllowSetTerm]);
  TestContext.AssertTrue(('^')=(Parser.Scanner.AlternateTerminator), 'Terminator set');
end;

{ TTestGlobalParser }

procedure TTestGlobalParser.TestEmpty;
begin
  CreateParser('');
  TestContext.AssertTrue((Parser.Parse)=nil, 'Empty statement returns nil');
end;

{ --------------------------------------------------------------------
  TTestParser
  --------------------------------------------------------------------}

procedure TTestParser.ParseStringDef(Out DT: TSQLDataType; Out Len: Integer; Out ACharset : TSQLStringtype);
begin
  ParseCharTypeDefinition(DT,Len,ACharset);
end;

function TTestParser.ParseType(Flags: TParseTypeFlags): TSQLTypeDefinition;
begin
  Result:=ParseTypeDefinition(Nil,Flags);
end;

function TTestParser.ParseConstraint: TSQLExpression;
begin
//  GetNextToken;
  Result:=ParseCheckConstraint(Nil);
end;

function TTestParser.ParseProcedureStatements: TSQLStatement;
begin
  Result:=Self.ParseProcedureStatement(Nil);
end;

{ --------------------------------------------------------------------
  TTestSQLParser
  --------------------------------------------------------------------}

procedure TTestSQLParser.SetUp;
begin
end;

procedure TTestSQLParser.TearDown;
begin
  FreeAndNil(FParser);
  FreeAndNil(FSource);
  FreeAndNil(FToFree);
end;

procedure TTestSQLParser.CreateParser(const ASource: string; aOptions: TParserOptions = []);
begin
  FSource:=TStringStream.Create(ASource);
  FParserOptions:=aOptions;
  FParser:=TTestParser.Create(FSource);
end;


Function TTestSQLParser.CheckClass(E: TSQLElement; C: TSQLElementClass) : TSQLElement;
begin
  TestContext.AssertTrue((C)=(E.ClassType), '');
  Result:=E;
end;





























Function TTestSQLParser.AssertLiteralExpr(const AMessage: String;
  Element: TSQLExpression; ALiteralClass: TSQLElementClass) : TSQLLiteral;
begin
  CheckClass(Element,TSQLLiteralExpression);
  Result:=TSQLLiteral(Checkclass(TSQLLiteralExpression(Element).Literal,ALiteralClass));
end;

procedure TTestSQLParser.AssertIdentifierName(const AMessage : String;
  const AExpected: String; Element: TSQLElement);
begin
  TestContext.AssertTrue((Element)<>nil, AMessage+': Have identifier ');
  CheckClass(Element,TSQLidentifierName);
  TestContext.AssertTrue((AExpected)=(TSQLidentifierName(Element).Name), AMessage+': Correct identifier name');
end;

procedure TTestSQLParser.AssertField(AField: TSQLElement; const AName: String;
  const AAlias: String);

Var
  F : TSQLSelectField;
  E : TSQLidentifierExpression;

begin
  TestContext.AssertTrue((AField)<>nil, 'Have field');
  F:=TSQLSelectField(CheckClass(AField,TSQLSelectField));
  TestContext.AssertTrue((F.Expression)<>nil, 'Have field expresssion,');
  E:=TSQLidentifierExpression(CheckClass(F.Expression,TSQLidentifierExpression));
  AssertIdentifierName('Correct field name',AName,E.Identifier);
  If (AAlias<>'') then
    AssertIdentifierName('Correct alias',AALias,F.AliasName);
end;

procedure TTestSQLParser.AssertAggregate(AField: TSQLElement;
  AAgregate: TSQLAggregateFunction; const AFieldName: String;
  AOption: TSQLAggregateOption; const AAlias: String);
Var
  F : TSQLSelectField;

begin
  TestContext.AssertTrue((AField)<>nil, 'Have field');
  F:=TSQLSelectField(CheckClass(AField,TSQLSelectField));
  TestContext.AssertTrue((F.Expression)<>nil, 'Have field expresssion,');
  AssertAggregateExpression(F.Expression,AAgregate,AFieldName,AOption);
  If (AAlias<>'') then
    AssertIdentifierName('Correct alias',AALias,F.AliasName);
end;

procedure TTestSQLParser.AssertAggregateExpression(E: TSQLElement;
  AAgregate: TSQLAggregateFunction; const AFieldName: String;
  AOption: TSQLAggregateOption);

Var
  AF : TSQLAggregateFunctionExpression;
  I : TSQLIdentifierExpression;

begin
  AF:=TSQLAggregateFunctionExpression(CheckClass(E,TSQLAggregateFunctionExpression));
  TestContext.AssertTrue((AAgregate)=(AF.Aggregate), 'Correct function');
  TestContext.AssertTrue((AOption)=(AF.Option), 'Correct function');
  If (AFieldName<>'') then
    begin
    I:=TSQLIdentifierExpression(CheckClass(AF.Expression, TSQLIdentifierExpression));
    AssertIdentifierName('Correct field name',AFieldName,I.Identifier);
    end;
end;

procedure TTestSQLParser.AssertTable(ATable: TSQLElement; const AName: String;
  const AAlias: String);
Var
  T : TSQLSimpleTablereference;

begin
  TestContext.AssertTrue((ATable)<>nil, 'Have table');
  T:=TSQLSimpleTablereference(CheckClass(ATable,TSQLSimpleTablereference));
  AssertIdentifierName('Correct table name',AName,T.ObjectName);
  If (AAlias<>'') then
    AssertIdentifierName('Correct alias',AALias,T.AliasName);
end;

function TTestSQLParser.AssertJoin(AJoin: TSQLElement; const AFirst,
  ASecond: String; const ajointype: TSQLJoinType):TSQLJoinTableReference;
Var
  J : TSQLJoinTableReference;

begin
  TestContext.AssertTrue((AJoin)<>nil, 'Have join');
  J:=TSQLJoinTableReference(CheckClass(AJoin,TSQLJoinTableReference));
  if (AFirst<>'') then
    AssertTable(J.Left,AFirst,'');
  if (ASecond<>'') then
    AssertTable(J.Right,ASecond,'');
  TestContext.AssertTrue((AJoinType)=(J.JoinType), 'Correct join type');
  Result:=J;
end;

function TTestSQLParser.AssertJoinOn(AJoin: TSQLExpression; const AFirst,
  ASecond: String; const AOperation: TSQLBinaryOperation): TSQLBinaryExpression;

Var
  I : TSQLIdentifierExpression;

begin
  Result:=TSQLBinaryExpression(CheckClass(AJoin,TSQLBinaryExpression));
  TestContext.AssertTrue((AOperation)=(Result.Operation), 'Correct ON operation');
  I:=TSQLIdentifierExpression(CheckClass(Result.Left,TSQLIdentifierExpression));
  AssertIdentifierName('Left field name',AFirst,I.Identifier);
  I:=TSQLIdentifierExpression(CheckClass(Result.Right,TSQLIdentifierExpression));
  AssertIdentifierName('Right field name',ASecond,I.Identifier);
end;

function TTestSQLParser.AssertOrderBy(AOrderBy: TSQLElement;
  const AField: String; const ANumber: Integer; const AOrdering: TSQLOrderDirection
  ): TSQLOrderByElement;

Var
  I : TSQLIntegerLiteral;

begin
  Result:=TSQLOrderByElement(CheckClass(AorderBy,TSQLOrderByElement));
  If (AField<>'') then
    AssertIdentifierName('Correct order by field',AField,Result.Field)
  else if (ANumber>0) then
    begin
    I:=TSQLIntegerLiteral(CheckClass(Result.Field,TSQLIntegerLiteral));
    TestContext.AssertTrue((ANumber)=(I.Value), 'Correct order by column number');
    end;
  TestContext.AssertTrue((AOrdering)=(Result.OrderBy), 'Correct ordering');
end;

function TTestSQLParser.AssertSecondaryFile(ASecondaryFile: TSQLElement;
  const AFile: String; const ALength, AStart: Integer): TSQLDatabaseFileInfo;
begin
  Result:=TSQLDatabaseFileInfo(CheckClass(ASecondaryFile,TSQLDatabaseFileInfo));
  TestContext.AssertTrue((AFile)=(Result.FileName), 'Secondary file name');
  TestContext.AssertTrue((ALength)=(Result.Length), 'Secondary file length');
  TestContext.AssertTrue((AStart)=(Result.StartPage), 'Secondary file start');
end;

procedure TTestSQLParser.TestTypeError;

begin
  TestType(FErrSource,[],sdtInteger);
end;

procedure TTestSQLParser.TestStringError;

begin
  TestStringDef(FErrSource,sdtchar,0);
end;

procedure TTestSQLParser.TestCheckError;
begin
  TestCheck(FErrSource,TSQLExpression);
end;

procedure TTestSQLParser.TestParseError;
begin
  CreateParser(FErrSource);
  FToFree:=Parser.Parse;
end;

procedure TTestSQLParser.TestStringDef(ASource : String; ExpectDT : TSQLDataType; ExpectLen : Integer; ExpectCharset : TSQLStringType='');

Var
  Dt : TSQLDataType;
  L : integer;
  cs : TSQLStringType;
begin
  CreateParser(ASOURCE);
  Parser.GetNextToken;
  Parser.ParseStringDef(dt,l,cs);
  TestContext.AssertTrue((ExpectDT)=(Dt), 'Datatype is Char');
  TestContext.AssertTrue((ExpectLen)=(l), 'Length is 1');
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of Stream reached');
  TestContext.AssertTrue((ExpectCharset)=(CS), 'Correct character set');
end;


Function TTestSQLParser.TestType(ASource : string; AFlags : TParseTypeFlags; AExpectedType : TSQLDataType) : TSQLTypeDefinition;

begin
  CreateParser(ASource);
  FToFree:=Parser.ParseType(AFlags);
  TestContext.AssertTrue((FToFree)<>nil, 'ParseType returns result');
  CheckClass(FTofree,TSQLTypeDefinition);
  Result:=TSQLTypeDefinition(FToFree);
  TestContext.AssertTrue((AExpectedType)=(Result.Datatype), 'Type definition has correct data type');
end;

function TTestSQLParser.TestCheck(ASource: string; AExpectedConstraint: TSQLElementClass
  ): TSQLExpression;
begin
  CreateParser('('+ASource+')');
  FToFree:=Parser.ParseConstraint();
  TestContext.AssertTrue((FToFree)<>nil, 'ParseType returns result');
  CheckClass(FTofree,AExpectedConstraint);
  Result:=TSQLExpression(FToFree);
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

function TTestSQLParser.GetParserOptions: TParserOptions;
begin
  if Assigned(FParser) then
    Result:=FParser.Options
  else
    Result:=FParserOptions;
end;

procedure TTestSQLParser.AssertTypeDefaults(TD : TSQLTypeDefinition;Len : Integer = 0);

begin
  TestContext.AssertTrue((TD.DefaultValue)=nil, '');
  TestContext.AssertTrue((TD.Check)=nil, '');
  TestContext.AssertTrue((TD.Collation)=nil, '');
  TestContext.AssertTrue((0)=(Length(TD.ArrayDims)), 'Array dim 0');
  TestContext.AssertTrue((0)=(TD.BlobType), 'Blob type 0');
  TestContext.AssertTrue((False)=(TD.NotNull), 'Not required');
  TestContext.AssertTrue((Len)=(TD.Len), 'Length');
end;

procedure TTestSQLParser.TestDropStatement(const ASource: string;
  C: TSQLElementClass);

Var
  D : TSQLDropStatement;
begin
  If ASOURCE='SHADOW' then
    CreateParser('DROP '+ASource+' 1')
  else
    CreateParser('DROP '+ASource+' A');
  FToFree:=Parser.Parse;
  TestContext.AssertTrue((FTofree)<>nil, 'Parse returns result');
  If Not FToFree.InheritsFrom(TSQLDropStatement) then
    TestContext.Fail('Drop statement is not of type TSQLDropStatement');
  CheckClass(FToFree ,C);
  D:=TSQLDropStatement(FToFree);
  If ASOURCE='SHADOW' then
    AssertIdentifierName('object name','1',D.ObjectName)
  else
    AssertIdentifierName('object name','A',D.ObjectName);
end;

function TTestSQLParser.TestCreateStatement(const ASource,AName: string;
  C: TSQLElementClass): TSQLCreateOrAlterStatement;
begin
  CreateParser(ASource);
  FToFree:=Parser.Parse;
  TestContext.AssertTrue((FTofree)<>nil, 'Parse returns result');
  If Not FToFree.InheritsFrom(TSQLCreateOrAlterStatement) then
    TestContext.Fail('create statement is not of type TSQLCreateOrAlterStatement');
  CheckClass(FToFree ,C);
  Result:=TSQLCreateOrAlterStatement(FToFree);
  AssertIdentifierName('Correct identifier',AName,Result.ObjectName);
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;



{ --------------------------------------------------------------------
  TTestDropParser
  --------------------------------------------------------------------}

procedure TTestDropParser.TestDropDatabase;

begin
  TestDropStatement('DATABASE',TSQLDropDatabaseStatement);
end;

procedure TTestDropParser.TestDropDomain;

begin
  TestDropStatement('DOMAIN',TSQLDropDomainStatement);
end;

procedure TTestDropParser.TestDropException;
begin
  TestDropStatement('EXCEPTION',TSQLDropExceptionStatement);
end;

procedure TTestDropParser.TestDropGenerator;

begin
  TestDropStatement('GENERATOR',TSQLDropGeneratorStatement);
end;

procedure TTestDropParser.TestDropIndex;

begin
  TestDropStatement('INDEX',TSQLDropIndexStatement);
end;

procedure TTestDropParser.TestDropProcedure;

begin
  TestDropStatement('PROCEDURE',TSQLDropProcedureStatement);
end;

procedure TTestDropParser.TestDropRole;
begin
  TestDropStatement('ROLE',TSQLDropRoleStatement);
end;

procedure TTestDropParser.TestDropTable;

begin
  TestDropStatement('TABLE',TSQLDropTableStatement);
end;

procedure TTestDropParser.TestDropTrigger;

begin
  TestDropStatement('TRIGGER',TSQLDropTriggerStatement);
end;

procedure TTestDropParser.TestDropView;

begin
  TestDropStatement('VIEW',TSQLDropViewStatement);
end;

procedure TTestDropParser.TestDropShadow;
begin
  TestDropStatement('SHADOW',TSQLDropShadowStatement);
end;

procedure TTestDropParser.TestDropExternalFunction;
begin
  TestDropStatement('EXTERNAL FUNCTION',TSQLDropExternalFunctionStatement);

end;

{ --------------------------------------------------------------------
  TTestGeneratorParser
  --------------------------------------------------------------------}


procedure TTestGeneratorParser.TestCreateGenerator;

begin
  TestCreateStatement('CREATE GENERATOR A','A',TSQLCreateGeneratorStatement);
end;

procedure TTestGeneratorParser.TestCreateSequence;

Var
  C : TSQLCreateOrAlterStatement;
begin
  C:=TestCreateStatement('CREATE SEQUENCE A','A',TSQLCreateGeneratorStatement);
  TestContext.AssertTrue((True)=(TSQLCreateGeneratorStatement(c).IsSequence), 'Sequence detected');
end;

procedure TTestGeneratorParser.TestAlterSequence;
Var
  C : TSQLCreateOrAlterStatement;
  D : TSQLAlterGeneratorStatement absolute C;
begin
  C:=TestCreateStatement('ALTER SEQUENCE A RESTART WITH 100','A',TSQLAlterGeneratorStatement);
  TestContext.AssertTrue((True)=(D.IsSequence), 'Sequence detected');
  TestContext.AssertTrue((True)=(D.HasRestart), 'Sequence restart ');
  TestContext.AssertTrue((100)=(D.Restart), 'Sequence restart value');
end;

procedure TTestGeneratorParser.TestSetGenerator;

Var
  S : TSQLSetGeneratorStatement;

begin
  CreateParser('SET GENERATOR A TO 1');
  FToFree:=Parser.Parse;
  S:=TSQLSetGeneratorStatement(CheckClass(FToFree,TSQLSetGeneratorStatement));
  AssertIdentifierName('Correct generator name','A',S.Objectname);
  TestContext.AssertTrue((1)=(S.NewValue), 'New value');
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

{ --------------------------------------------------------------------
  TTestTypeParser
  --------------------------------------------------------------------}

procedure TTestTypeParser.TestStringType1;

begin
  TestStringDef('CHAR(1)',sdtChar,1);
end;

procedure TTestTypeParser.TestStringType2;

begin
  TestStringDef('CHAR',sdtChar,0);
end;

procedure TTestTypeParser.TestStringType3;

begin
  TestStringDef('CHARACTER',sdtChar,0);
end;

procedure TTestTypeParser.TestStringType4;

begin
  TestStringDef('CHARACTER VARYING',sdtVarChar,0);
end;

procedure TTestTypeParser.TestStringType5;

begin
  TestStringDef('VARCHAR',sdtVarChar,0);
end;

procedure TTestTypeParser.TestStringType6;

begin
  TestStringDef('VARCHAR(2)',sdtVarChar,2);
end;

procedure TTestTypeParser.TestStringType7;

begin
  TestStringDef('CHARACTER VARYING (2)',sdtVarChar,2);
end;

procedure TTestTypeParser.TestStringType8;

begin
  TestStringDef('NATIONAL CHARACTER VARYING (2)',sdtNVarChar,2);
end;

procedure TTestTypeParser.TestStringType9;

begin
  TestStringDef('NATIONAL CHARACTER (2)',sdtNChar,2);
end;

procedure TTestTypeParser.TestStringType10;

begin
  TestStringDef('NATIONAL CHARACTER',sdtNChar,0);
end;

procedure TTestTypeParser.TestStringType11;

begin
  TestStringDef('NATIONAL CHARACTER VARYING',sdtNVarChar,0);
end;

procedure TTestTypeParser.TestStringType12;

begin
  TestStringDef('NCHAR',sdtNChar,0);
end;

procedure TTestTypeParser.TestStringType13;

begin
  TestStringDef('NCHAR(2)',sdtNChar,2);
end;


procedure TTestTypeParser.TestStringType14;

begin
  TestStringDef('NCHAR VARYING(2)',sdtNVarChar,2);
end;

procedure TTestTypeParser.TestStringType15;
begin
  TestStringDef('CHAR (15) CHARACTER SET UTF8',sdtChar,15,'UTF8');
end;

procedure TTestTypeParser.TestStringType16;
begin
  TestStringDef('CHAR VARYING (15) CHARACTER SET UTF8',sdtVarChar,15,'UTF8');
end;

procedure TTestTypeParser.TestStringType17;
begin
  TestStringDef('CHAR VARYING CHARACTER SET UTF8',sdtVarChar,0,'UTF8');
end;

procedure TTestTypeParser.TestStringType18;
begin
  TestStringDef('CHARACTER CHARACTER SET UTF8',sdtChar,0,'UTF8');
end;

procedure TTestTypeParser.TestStringType19;

Var
  T : TSQLTypeDefinition;

begin
  T:=TestType('CHAR(10) COLLATE UTF8',[],sdtChar);
  TestContext.AssertTrue((T.Collation)<>nil, 'Have collation');
  TestContext.AssertTrue(('UTF8')=(T.Collation.Name), 'Correct collation');
end;

procedure TTestTypeParser.TestStringTypeErrors1;
begin
  FErrSource:='VARCHAR VARYING';
  TestContext.AssertRaises(ESQLParser, @TestStringError, '');
end;

procedure TTestTypeParser.TestStringTypeErrors2;
begin
  FErrSource:='CHAR(A)';
  TestContext.AssertRaises(ESQLParser, @TestStringError, '');
end;

procedure TTestTypeParser.TestStringTypeErrors3;
begin
  FErrSource:='CHAR(1]';
  TestContext.AssertRaises(ESQLParser, @TestStringError, '');
end;


procedure TTestTypeParser.TestTypeInt1;

Var
  TD : TSQLTypeDefinition;

begin
  TD:=TestType('INT',[],sdtInteger);
  AssertTypeDefaults(TD);
end;

procedure TTestTypeParser.TestTypeInt2;

Var
  TD : TSQLTypeDefinition;

begin
  TD:=TestType('INT DEFAULT NULL',[],sdtInteger);
  TestContext.AssertTrue((TD.DefaultValue)<>nil, 'Have Default value');
  CheckClass(TD.DefaultValue,TSQLNullLiteral);
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestTypeParser.TestTypeInt3;

Var
  TD : TSQLTypeDefinition;

begin
  TD:=TestType('INT DEFAULT 1',[],sdtInteger);
  TestContext.AssertTrue((TD.DefaultValue)<>nil, 'Have Default value');
  CheckClass(TD.DefaultValue,TSQLIntegerLiteral);
  TestContext.AssertTrue((1)=(TSQLIntegerLiteral(TD.DefaultValue).Value), 'Correct default value ');
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestTypeParser.TestTypeInt4;

Var
  TD : TSQLTypeDefinition;

begin
  TD:=TestType('INT NOT NULL',[],sdtInteger);
  TestContext.AssertTrue((TD.DefaultValue)=nil, 'No Default value');
  TestContext.AssertTrue((True)=(TD.NotNull), 'Required field');
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestTypeParser.TestTypeInt5;

Var
  TD : TSQLTypeDefinition;

begin
  TD:=TestType('INT [3]',[],sdtInteger);
  TestContext.AssertTrue((1)=(Length(TD.ArrayDims)), 'Array of length');
  TestContext.AssertTrue((3)=(TD.ArrayDims[0][2]), 'Upper bound');
  TestContext.AssertTrue((1)=(TD.ArrayDims[0][1]), 'Lower bound');
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestTypeParser.TestNumerical1;
Var
  TD : TSQLTypeDefinition;

begin
  TD:=TestType('NUMERIC (10)',[],sdtNumeric);
  TestContext.AssertTrue((10)=(TD.Len), 'Correct length');
end;

procedure TTestTypeParser.TestNumerical2;
Var
  TD : TSQLTypeDefinition;

begin
  TD:=TestType('NUMERIC (10,3)',[],sdtNumeric);
  TestContext.AssertTrue((10)=(TD.Len), 'Correct length');
  TestContext.AssertTrue((3)=(TD.Scale), 'Correct scale');
end;

procedure TTestTypeParser.TestNumerical3;
Var
  TD : TSQLTypeDefinition;

begin
  TD:=TestType('NUMERIC',[],sdtNumeric);
  TestContext.AssertTrue((0)=(TD.Len), 'Correct length');
  TestContext.AssertTrue((0)=(TD.Scale), 'Correct scale');
end;

procedure TTestTypeParser.TestNumericalError1;

begin
  FErrSource:='NUMERIC ()';
  TestContext.AssertRaises(ESQLParser, @TestTypeError, '');
end;

procedure TTestTypeParser.TestNumericalError2;

begin
  FErrSource:='NUMERIC (A)';
  TestContext.AssertRaises(ESQLParser, @TestTypeError, '');
end;

procedure TTestTypeParser.TestNumericalError3;

begin
  FErrSource:='NUMERIC (,1)';
  TestContext.AssertRaises(ESQLParser, @TestTypeError, '');
end;

procedure TTestTypeParser.TestNumericalError4;

begin
  FErrSource:='NUMERIC (1,)';
  TestContext.AssertRaises(ESQLParser, @TestTypeError, '');
end;

procedure TTestTypeParser.TestNumericalError5;
begin
  FErrSource:='NUMERIC (1';
  TestContext.AssertRaises(ESQLParser, @TestTypeError, '');
end;

procedure TTestTypeParser.TestNumericalError6;
begin
  FErrSource:='NUMERIC (1,';
  TestContext.AssertRaises(ESQLParser, @TestTypeError, '');
end;

procedure TTestTypeParser.TestNumericalError7;
begin
  FErrSource:='NUMERIC (1 NOT';
  TestContext.AssertRaises(ESQLParser, @TestTypeError, '');
end;

procedure TTestTypeParser.TestBlob1;
Var
  TD : TSQLTypeDefinition;

begin
  TD:=TestType('BLOB sub_type 1 SEGMENT SIZE 80 CHARACTER SET UTF8',[],sdtBlob);
  TestContext.AssertTrue((1)=(TD.BlobType), 'Blob type 1');
  TestContext.AssertTrue((80)=(TD.Len), 'Blob segment size');
  TestContext.AssertTrue(('UTF8')=(TD.Charset), 'Character set');

end;

procedure TTestTypeParser.TestBlob2;
Var
  TD : TSQLTypeDefinition;

begin
  TD:=TestType('BLOB (80,1) CHARACTER SET UTF8',[],sdtBlob);
  TestContext.AssertTrue((1)=(TD.BlobType), 'Blob type 1');
  TestContext.AssertTrue((80)=(TD.Len), 'Blob segment size');
  TestContext.AssertTrue(('UTF8')=(TD.Charset), 'Character set');
end;

procedure TTestTypeParser.TestBlob3;
Var
  TD : TSQLTypeDefinition;

begin
  TD:=TestType('BLOB SEGMENT SIZE 80',[],sdtBlob);
  TestContext.AssertTrue((0)=(TD.BlobType), 'Blob type 0');
  TestContext.AssertTrue((80)=(TD.Len), 'Blob segment size');
  TestContext.AssertTrue(('')=(TD.Charset), 'Character set');
end;

procedure TTestTypeParser.TestBlob4;
Var
  TD : TSQLTypeDefinition;

begin
  TD:=TestType('BLOB SUB_TYPE 1',[],sdtBlob);
  TestContext.AssertTrue((1)=(TD.BlobType), 'Blob type 1');
  TestContext.AssertTrue((0)=(TD.Len), 'Blob segment size');
  TestContext.AssertTrue(('')=(TD.Charset), 'Character set');
end;

procedure TTestTypeParser.TestBlob5;
Var
  TD : TSQLTypeDefinition;

begin
  TD:=TestType('BLOB (80)',[],sdtBlob);
  TestContext.AssertTrue((0)=(TD.BlobType), 'Blob type 0');
  TestContext.AssertTrue((80)=(TD.Len), 'Blob segment size');
  TestContext.AssertTrue(('')=(TD.Charset), 'Character set');
end;

procedure TTestTypeParser.TestBlob6;
Var
  TD : TSQLTypeDefinition;

begin
  TD:=TestType('BLOB',[],sdtBlob);
  TestContext.AssertTrue((0)=(TD.BlobType), 'Blob type 0');
  TestContext.AssertTrue((0)=(TD.Len), 'Blob segment size');
  TestContext.AssertTrue(('')=(TD.Charset), 'Character set');
end;

procedure TTestTypeParser.TestBlob7;
var
  TD : TSQLTypeDefinition;

begin
  TD:=TestType('BLOB SUB_TYPE BINARY',[],sdtBlob);
  TestContext.AssertTrue((0)=(TD.BlobType), 'Blob type 0');
  TestContext.AssertTrue((0)=(TD.Len), 'Blob segment size');
  TestContext.AssertTrue(('')=(TD.Charset), 'Character set');
end;

procedure TTestTypeParser.TestBlob8;
var
  TD : TSQLTypeDefinition;

begin
  TD:=TestType('BLOB SUB_TYPE TEXT',[],sdtBlob);
  TestContext.AssertTrue((1)=(TD.BlobType), 'Blob type 1');
  TestContext.AssertTrue((0)=(TD.Len), 'Blob segment size');
  TestContext.AssertTrue(('')=(TD.Charset), 'Character set');
end;

procedure TTestTypeParser.TestSmallInt;

begin
  TestType('SMALLINT',[],sdtSmallint);
end;

procedure TTestTypeParser.TestFloat;

begin
  TestType('FLOAT',[],sdtFloat);
end;

procedure TTestTypeParser.TestDoublePrecision;

begin
  TestType('DOUBLE PRECISION',[],sdtDoublePrecision);
end;

procedure TTestTypeParser.TestDoublePrecisionDefault;

begin
  TestType('DOUBLE PRECISION DEFAULT 0',[],sdtDoublePrecision);
end;

procedure TTestTypeParser.TestBlobError1;
begin
  FerrSource:='BLOB (1,)';
  TestContext.AssertRaises(ESQLParser, @TestTypeError, '');
end;

procedure TTestTypeParser.TestBlobError2;
begin
  FerrSource:='BLOB 1,)';
  // EAssertionfailed, due to not EOF
  TestContext.AssertRaises(ENXTestFailure, @TestTypeError, '');
end;

procedure TTestTypeParser.TestBlobError3;
begin
  FerrSource:='BLOB (80) SUB_TYPE 3';
  TestContext.AssertRaises(ESQLParser, @TestTypeError, '');
end;

procedure TTestTypeParser.TestBlobError4;
begin
  FerrSource:='BLOB CHARACTER UTF8';
  TestContext.AssertRaises(ESQLParser, @TestTypeError, '');
end;

procedure TTestTypeParser.TestBlobError5;
begin
  FerrSource:='BLOB (80) SEGMENT SIZE 80';
  TestContext.AssertRaises(ESQLParser, @TestTypeError, '');
end;

procedure TTestTypeParser.TestBlobError6;
begin
  FerrSource:='BLOB (A)';
  TestContext.AssertRaises(ESQLParser, @TestTypeError, '');
end;

procedure TTestTypeParser.TestBlobError7;
begin
  FerrSource:='BLOB (1';
  TestContext.AssertRaises(ESQLParser, @TestTypeError, '');
end;


{ --------------------------------------------------------------------
  TTestCheckParser
  --------------------------------------------------------------------}

procedure TTestCheckParser.TestCheckNotNull;

Var
  B : TSQLBinaryExpression;

begin
  B:=TSQLBinaryExpression(TestCheck('VALUE IS NOT NULL',TSQLBinaryExpression));
  TestContext.AssertTrue((boISNot)=(B.Operation), 'IS NOT operator,');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is null',B.Right,TSQLNullLiteral);
end;

procedure TTestCheckParser.TestCheckNull;

Var
  B : TSQLBinaryExpression;

begin
  B:=TSQLBinaryExpression(TestCheck('VALUE IS NULL',TSQLBinaryExpression));
  TestContext.AssertTrue((boIS)=(B.Operation), 'IS operator,');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is null',B.Right,TSQLNullLiteral);
end;

procedure TTestCheckParser.TestCheckBraces;

Var
  B : TSQLBinaryExpression;

begin
  B:=TSQLBinaryExpression(TestCheck('(VALUE IS NULL)',TSQLBinaryExpression));
  TestContext.AssertTrue((boIS)=(B.Operation), 'IS operator,');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is null',B.Right,TSQLNullLiteral);
end;

procedure TTestCheckParser.TestCheckBracesError;

begin
  FErrSource:='(VALUE IS NOT NULL ME )';
  TestContext.AssertRaises(ESQLParser, @TestCheckError, 'Error in braces.');
end;

procedure TTestCheckParser.TestCheckParamError;
begin
  FErrSource:='VALUE <> :P';
  TestContext.AssertRaises(ESQLParser, @TestCheckError, 'Parameter.');
end;

procedure TTestCheckParser.TestCheckIdentifierError;

begin
  FErrSource:='(X IS NOT NULL)';
  TestContext.AssertRaises(ESQLParser, @TestCheckError, 'Error in check: identifier.');
end;

procedure TTestCheckParser.TestIsEqual;

Var
  B : TSQLBinaryExpression;

begin
  B:=TSQLBinaryExpression(TestCheck('VALUE = 3',TSQLBinaryExpression));
  TestContext.AssertTrue((boEq)=(B.Operation), 'Equal operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is integer',B.Right,TSQLIntegerLiteral);
end;

procedure TTestCheckParser.TestIsNotEqual1;

Var
  B : TSQLBinaryExpression;

begin
  B:=TSQLBinaryExpression(TestCheck('VALUE <> 3',TSQLBinaryExpression));
  TestContext.AssertTrue((boNE)=(B.Operation), 'Not Equal operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is integer',B.Right,TSQLIntegerLiteral);
end;

procedure TTestCheckParser.TestIsNotEqual2;

Var
  B : TSQLBinaryExpression;

begin
  B:=TSQLBinaryExpression(TestCheck('VALUE != 3',TSQLBinaryExpression));
  TestContext.AssertTrue((boNE)=(B.Operation), 'ENot qual operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is integer',B.Right,TSQLIntegerLiteral);
end;

procedure TTestCheckParser.TestGreaterThan;

Var
  B : TSQLBinaryExpression;

begin
  B:=TSQLBinaryExpression(TestCheck('VALUE > 3',TSQLBinaryExpression));
  TestContext.AssertTrue((boGT)=(B.Operation), 'Greater than operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is integer',B.Right,TSQLIntegerLiteral);
end;

procedure TTestCheckParser.TestGreaterThanEqual1;
Var
  B : TSQLBinaryExpression;

begin
  B:=TSQLBinaryExpression(TestCheck('VALUE >= 3',TSQLBinaryExpression));
  TestContext.AssertTrue((boGE)=(B.Operation), 'Greater or Equal operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is integer',B.Right,TSQLIntegerLiteral);
end;

procedure TTestCheckParser.TestGreaterThanEqual2;
Var
  B : TSQLBinaryExpression;

begin
  B:=TSQLBinaryExpression(TestCheck('VALUE !< 3',TSQLBinaryExpression));
  TestContext.AssertTrue((boGE)=(B.Operation), 'Greater or Equal operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is integer',B.Right,TSQLIntegerLiteral);
end;

procedure TTestCheckParser.TestLessThan;

Var
  B : TSQLBinaryExpression;

begin
  B:=TSQLBinaryExpression(TestCheck('VALUE < 3',TSQLBinaryExpression));
  TestContext.AssertTrue((boLT)=(B.Operation), 'Less than operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is integer',B.Right,TSQLIntegerLiteral);
end;

procedure TTestCheckParser.TestLessThanEqual1;
Var
  B : TSQLBinaryExpression;

begin
  B:=TSQLBinaryExpression(TestCheck('VALUE <= 3',TSQLBinaryExpression));
  TestContext.AssertTrue((boLE)=(B.Operation), 'Less or Equal operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is integer',B.Right,TSQLIntegerLiteral);
end;

procedure TTestCheckParser.TestLessThanEqual2;
Var
  B : TSQLBinaryExpression;

begin
  B:=TSQLBinaryExpression(TestCheck('VALUE !> 3',TSQLBinaryExpression));
  TestContext.AssertTrue((boLE)=(B.Operation), 'Less or Equal operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is integer',B.Right,TSQLIntegerLiteral);
end;

procedure TTestCheckParser.TestLike;

Var
  B : TSQLBinaryExpression;

begin
  B:=TSQLBinaryExpression(TestCheck('VALUE LIKE ''%3''',TSQLBinaryExpression));
  TestContext.AssertTrue((boLike)=(B.Operation), 'Like operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is string',B.Right,TSQLStringLiteral);
end;

procedure TTestCheckParser.TestNotLike;

Var
  B : TSQLBinaryExpression;
  U : TSQLUnaryExpression;
begin
  U:=TSQLUnaryExpression(TestCheck('VALUE NOT LIKE ''%3''',TSQLUnaryExpression));
  TestContext.AssertTrue((uoNot)=(U.Operation), 'Like operator');
  CheckClass(U.Operand,TSQLBinaryExpression);
  B:=TSQLBinaryExpression(U.Operand);
  TestContext.AssertTrue((boLike)=(B.Operation), 'Like operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is string',B.Right,TSQLStringLiteral);
end;

procedure TTestCheckParser.TestContaining;

Var
  B : TSQLBinaryExpression;

begin
  B:=TSQLBinaryExpression(TestCheck('VALUE CONTAINING ''3''',TSQLBinaryExpression));
  TestContext.AssertTrue((boContaining)=(B.Operation), 'Like operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is string',B.Right,TSQLStringLiteral);
end;

procedure TTestCheckParser.TestDivide;

Var
  B : TSQLBinaryExpression;

begin
  B:=TSQLBinaryExpression(TestCheck('VALUE / 1',TSQLBinaryExpression));
  TestContext.AssertTrue((boDivide)=(B.Operation), 'Correct operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is integer',B.Right,TSQLIntegerLiteral);
  TestContext.AssertTrue((1)=(TSQLIntegerLiteral(TSQLLiteralExpression(B.Right).Literal).Value), 'Right is 1');
end;

procedure TTestCheckParser.TestNotContaining;

Var
  B : TSQLBinaryExpression;
  U : TSQLUnaryExpression;
begin
  U:=TSQLUnaryExpression(TestCheck('VALUE NOT CONTAINING ''3''',TSQLUnaryExpression));
  TestContext.AssertTrue((uoNot)=(U.Operation), 'Like operator');
  CheckClass(U.Operand,TSQLBinaryExpression);
  B:=TSQLBinaryExpression(U.Operand);
  TestContext.AssertTrue((boContaining)=(B.Operation), 'Like operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is string',B.Right,TSQLStringLiteral);
end;

procedure TTestCheckParser.TestStarting;

Var
  B : TSQLBinaryExpression;

begin
  B:=TSQLBinaryExpression(TestCheck('VALUE STARTING ''3''',TSQLBinaryExpression));
  TestContext.AssertTrue((boStarting)=(B.Operation), 'Starting operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is string',B.Right,TSQLStringLiteral);
end;

procedure TTestCheckParser.TestNotStarting;

Var
  B : TSQLBinaryExpression;
  U : TSQLUnaryExpression;
begin
  U:=TSQLUnaryExpression(TestCheck('VALUE NOT STARTING ''3''',TSQLUnaryExpression));
  TestContext.AssertTrue((uoNot)=(U.Operation), 'Not operator');
  CheckClass(U.Operand,TSQLBinaryExpression);
  B:=TSQLBinaryExpression(U.Operand);
  TestContext.AssertTrue((boStarting)=(B.Operation), 'Starting operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is string',B.Right,TSQLStringLiteral);
end;

procedure TTestCheckParser.TestStartingWith;

Var
  B : TSQLBinaryExpression;

begin
  B:=TSQLBinaryExpression(TestCheck('VALUE STARTING WITH ''3''',TSQLBinaryExpression));
  TestContext.AssertTrue((boStarting)=(B.Operation), 'Starting operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is string',B.Right,TSQLStringLiteral);
end;

procedure TTestCheckParser.TestSubtract;

Var
  B : TSQLBinaryExpression;

begin
  B:=TSQLBinaryExpression(TestCheck('VALUE - 1',TSQLBinaryExpression));
  TestContext.AssertTrue((boSubtract)=(B.Operation), 'Correct operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is integer',B.Right,TSQLIntegerLiteral);
  TestContext.AssertTrue((1)=(TSQLIntegerLiteral(TSQLLiteralExpression(B.Right).Literal).Value), 'Right is 1');
end;

procedure TTestCheckParser.TestNotStartingWith;

Var
  B : TSQLBinaryExpression;
  U : TSQLUnaryExpression;
begin
  U:=TSQLUnaryExpression(TestCheck('VALUE NOT STARTING WITH ''3''',TSQLUnaryExpression));
  TestContext.AssertTrue((uoNot)=(U.Operation), 'Not operator');
  CheckClass(U.Operand,TSQLBinaryExpression);
  B:=TSQLBinaryExpression(U.Operand);
  TestContext.AssertTrue((boStarting)=(B.Operation), 'Starting operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is string',B.Right,TSQLStringLiteral);
end;


procedure TTestCheckParser.TestBetween;

Var
  T : TSQLTernaryExpression;

begin
  T:=TSQLTernaryExpression(TestCheck('VALUE BETWEEN 1 AND 5',TSQLTernaryExpression));
  TestContext.AssertTrue((tobetween)=(T.Operation), 'Like operator');
  AssertLiteralExpr('Left is value',T.Left,TSQLValueLiteral);
  AssertLiteralExpr('Middle is integer',T.Middle,TSQLIntegerLiteral);
  AssertLiteralExpr('Right is integer',T.Right,TSQLIntegerLiteral);
end;

procedure TTestCheckParser.TestCase;

Var
  T : TSQLCaseExpression;
  B : TSQLBinaryExpression;
  R : TSQLIdentifierName;

begin
  T:=TSQLCaseExpression(TestCheck('CASE WHEN A=1 THEN "a" WHEN B=2 THEN "b" ELSE "c" END',TSQLCaseExpression));
  TestContext.AssertTrue((2)=(T.BranchCount), 'Branch count = 2');
  TestContext.AssertTrue((T.ElseBranch)<>nil, 'Else branch exists');

  B:=(T.Branches[0].Condition as TSQLBinaryExpression);
  R:=(T.Branches[0].Expression as TSQLIdentifierExpression).Identifier;
  TestContext.AssertTrue(('A')=((B.Left as TSQLIdentifierExpression).Identifier.Name), 'First WHEN Identifier is A');
  TestContext.AssertTrue((1)=(((B.Right as TSQLLiteralExpression).Literal as TSQLIntegerLiteral).Value), 'First WHEN Number is 1');
  TestContext.AssertTrue(('a')=(R.Name), 'First THEN result is "a"');

  B:=(T.Branches[1].Condition as TSQLBinaryExpression);
  R:=(T.Branches[1].Expression as TSQLIdentifierExpression).Identifier;
  TestContext.AssertTrue(('B')=((B.Left as TSQLIdentifierExpression).Identifier.Name), 'Second WHEN Identifier is B');
  TestContext.AssertTrue((2)=(((B.Right as TSQLLiteralExpression).Literal as TSQLIntegerLiteral).Value), 'Second WHEN Number is 2');
  TestContext.AssertTrue(('b')=(R.Name), 'Second THEN result is "b"');

  R:=(T.ElseBranch as TSQLIdentifierExpression).Identifier;
  TestContext.AssertTrue(('c')=(R.Name), 'ELSE result is "c"');
end;

procedure TTestCheckParser.TestCaseWithSelector;

Var
  T : TSQLCaseExpression;
  L : TSQLLiteralExpression;
  R : TSQLIdentifierName;

begin
  T:=TSQLCaseExpression(TestCheck('CASE A WHEN 1 THEN "a" WHEN 2 THEN "b" ELSE "c" END',TSQLCaseExpression));
  TestContext.AssertTrue((T.Selector)<>nil, 'Selector exists');
  TestContext.AssertTrue((2)=(T.BranchCount), 'Branch count = 2');
  TestContext.AssertTrue((T.ElseBranch)<>nil, 'Else branch exists');

  R:=(T.Selector as TSQLIdentifierExpression).Identifier;
  TestContext.AssertTrue(('A')=(R.Name), 'Selector identifier is "A"');

  L:=(T.Branches[0].Condition as TSQLLiteralExpression);
  R:=(T.Branches[0].Expression as TSQLIdentifierExpression).Identifier;
  TestContext.AssertTrue((1)=((L.Literal as TSQLIntegerLiteral).Value), 'First WHEN Number is 1');
  TestContext.AssertTrue(('a')=(R.Name), 'First THEN result is "a"');

  L:=(T.Branches[1].Condition as TSQLLiteralExpression);
  R:=(T.Branches[1].Expression as TSQLIdentifierExpression).Identifier;
  TestContext.AssertTrue((2)=((L.Literal as TSQLIntegerLiteral).Value), 'Second WHEN Number is 2');
  TestContext.AssertTrue(('b')=(R.Name), 'Second THEN result is "b"');

  R:=(T.ElseBranch as TSQLIdentifierExpression).Identifier;
  TestContext.AssertTrue(('c')=(R.Name), 'ELSE result is "c"');
end;

procedure TTestCheckParser.TestNotBetween;

Var
  U : TSQLUnaryExpression;
  T : TSQLTernaryExpression;

begin
  U:=TSQLUnaryExpression(TestCheck('VALUE NOT BETWEEN 1 AND 5',TSQLUnaryExpression));
  TestContext.AssertTrue((uoNot)=(U.Operation), 'Not operator');
  CheckClass(U.Operand,TSQLTernaryExpression);
  T:=TSQLTernaryExpression(U.Operand);
  TestContext.AssertTrue((tobetween)=(T.Operation), 'Like operator');
  AssertLiteralExpr('Left is value',T.Left,TSQLValueLiteral);
  AssertLiteralExpr('Middle is integer',T.Middle,TSQLIntegerLiteral);
  AssertLiteralExpr('Right is integer',T.Right,TSQLIntegerLiteral);
end;

procedure TTestCheckParser.TestLikeEscape;

Var
  T : TSQLTernaryExpression;

begin
  T:=TSQLTernaryExpression(TestCheck('VALUE LIKE ''%2'' ESCAPE ''3''',TSQLTernaryExpression));
  TestContext.AssertTrue((toLikeEscape)=(T.Operation), 'Like operator');
  AssertLiteralExpr('Left is value',T.Left,TSQLValueLiteral);
  AssertLiteralExpr('Middle is string',T.Middle,TSQLStringLiteral);
  AssertLiteralExpr('Right is string',T.Right,TSQLStringLiteral);
end;

procedure TTestCheckParser.TestMultiply;

Var
  B : TSQLBinaryExpression;

begin
  B:=TSQLBinaryExpression(TestCheck('VALUE * 1',TSQLBinaryExpression));
  TestContext.AssertTrue((boMultiply)=(B.Operation), 'Correct operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is integer',B.Right,TSQLIntegerLiteral);
  TestContext.AssertTrue((1)=(TSQLIntegerLiteral(TSQLLiteralExpression(B.Right).Literal).Value), 'Right is 1');
end;

procedure TTestCheckParser.TestNotLikeEscape;
Var
  U : TSQLUnaryExpression;
  T : TSQLTernaryExpression;

begin
  U:=TSQLUnaryExpression(TestCheck('VALUE NOT LIKE ''%2'' ESCAPE ''3''',TSQLUnaryExpression));
  TestContext.AssertTrue((uoNot)=(U.Operation), 'Not operator');
  CheckClass(U.Operand,TSQLTernaryExpression);
  T:=TSQLTernaryExpression(U.Operand);
  TestContext.AssertTrue((toLikeEscape)=(T.Operation), 'Like operator');
  AssertLiteralExpr('Left is value',T.Left,TSQLValueLiteral);
  AssertLiteralExpr('Middle is string',T.Middle,TSQLStringLiteral);
  AssertLiteralExpr('Right is string',T.Right,TSQLStringLiteral);
end;

procedure TTestCheckParser.TestAdd;

Var
  B : TSQLBinaryExpression;

begin
  B:=TSQLBinaryExpression(TestCheck('VALUE + 1',TSQLBinaryExpression));
  TestContext.AssertTrue((boAdd)=(B.Operation), 'Correct operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  AssertLiteralExpr('Right is integer',B.Right,TSQLIntegerLiteral);
  TestContext.AssertTrue((1)=(TSQLIntegerLiteral(TSQLLiteralExpression(B.Right).Literal).Value), 'Right is 1');
end;

procedure TTestCheckParser.TestAnd;

Var
  T,B : TSQLBinaryExpression;

begin
  T:=TSQLBinaryExpression(TestCheck('VALUE > 4 AND Value < 11',TSQLBinaryExpression));
  TestContext.AssertTrue((boand)=(T.Operation), 'And operator');
  CheckClass(T.Left,TSQLBinaryExpression);
  CheckClass(T.Right,TSQLBinaryExpression);
  B:=TSQLBinaryExpression(T.Left);
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  TestContext.AssertTrue((boGT)=(B.Operation), 'Less than operator');
  AssertLiteralExpr('Right is value',B.Right,TSQLIntegerLiteral);
  B:=TSQLBinaryExpression(T.Right);
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  TestContext.AssertTrue((boLT)=(B.Operation), 'Less than operator');
  AssertLiteralExpr('Right is value',B.Right,TSQLIntegerLiteral);
end;

procedure TTestCheckParser.TestOr;

Var
  T,B : TSQLBinaryExpression;

begin
  T:=TSQLBinaryExpression(TestCheck('VALUE < 4 or Value > 11',TSQLBinaryExpression));
  TestContext.AssertTrue((boor)=(T.Operation), 'And operator');
  CheckClass(T.Left,TSQLBinaryExpression);
  CheckClass(T.Right,TSQLBinaryExpression);
  B:=TSQLBinaryExpression(T.Left);
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  TestContext.AssertTrue((boLT)=(B.Operation), 'Less than operator');
  AssertLiteralExpr('Right is value',B.Right,TSQLIntegerLiteral);
  B:=TSQLBinaryExpression(T.Right);
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  TestContext.AssertTrue((boGT)=(B.Operation), 'Less than operator');
  AssertLiteralExpr('Right is value',B.Right,TSQLIntegerLiteral);
end;

procedure TTestCheckParser.TestNotOr;

Var
  T,B : TSQLBinaryExpression;

begin
  T:=TSQLBinaryExpression(TestCheck('VALUE IS NOT NULL or Value > 11',TSQLBinaryExpression));
  TestContext.AssertTrue((boor)=(T.Operation), 'And operator');
  CheckClass(T.Left,TSQLBinaryExpression);
  CheckClass(T.Right,TSQLBinaryExpression);
  B:=TSQLBinaryExpression(T.Left);
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  TestContext.AssertTrue((boisNot)=(B.Operation), 'Is not null operator');
  AssertLiteralExpr('Right is value',B.Right,TSQLNullLiteral);
  B:=TSQLBinaryExpression(T.Right);
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  TestContext.AssertTrue((boGT)=(B.Operation), 'Less than operator');
  AssertLiteralExpr('Right is value',B.Right,TSQLIntegerLiteral);
end;

{ TTestDomainParser }

procedure TTestDomainParser.TestSimpleDomain;

Var
  P : TSQLCreateOrAlterStatement;
  D : TSQLCreateDomainStatement;
  T : TSQLTypeDefinition;

begin
  P:=TestCreateStatement('CREATE DOMAIN A INT','A',TSQLCreateDomainStatement);
  CheckClass(P,TSQLCreateDomainStatement);
  D:=TSQLCreateDomainStatement(P);
  TestContext.AssertTrue((D.TypeDefinition)<>nil, 'Have type Definition');
  T:=D.TypeDefinition;
  AssertTypeDefaults(T);
  TestContext.AssertTrue((sdtInteger)=(T.DataType), 'Integer data type');
end;

procedure TTestDomainParser.TestSimpleDomainAs;
Var
  P : TSQLCreateOrAlterStatement;
  D : TSQLCreateDomainStatement;
  T : TSQLTypeDefinition;

begin
  P:=TestCreateStatement('CREATE DOMAIN A AS INT','A',TSQLCreateDomainStatement);
  CheckClass(P,TSQLCreateDomainStatement);
  D:=TSQLCreateDomainStatement(P);
  TestContext.AssertTrue((D.TypeDefinition)<>nil, 'Have type Definition');
  T:=D.TypeDefinition;
  AssertTypeDefaults(T);
  TestContext.AssertTrue((sdtInteger)=(T.DataType), 'Integer data type');
end;

procedure TTestDomainParser.TestNotNullDomain;
Var
  P : TSQLCreateOrAlterStatement;
  D : TSQLCreateDomainStatement;
  T : TSQLTypeDefinition;

begin
  P:=TestCreateStatement('CREATE DOMAIN A INT NOT NULL','A',TSQLCreateDomainStatement);
  CheckClass(P,TSQLCreateDomainStatement);
  D:=TSQLCreateDomainStatement(P);
  TestContext.AssertTrue((D.TypeDefinition)<>nil, 'Have type Definition');
  T:=D.TypeDefinition;
  TestContext.AssertTrue((sdtInteger)=(T.DataType), 'Integer data type');
  TestContext.AssertTrue((True)=(T.NotNull), 'Not null');
end;

procedure TTestDomainParser.TestDefaultNotNullDomain;
Var
  P : TSQLCreateOrAlterStatement;
  D : TSQLCreateDomainStatement;
  T : TSQLTypeDefinition;

begin
  P:=TestCreateStatement('CREATE DOMAIN A INT DEFAULT 2 NOT NULL','A',TSQLCreateDomainStatement);
  CheckClass(P,TSQLCreateDomainStatement);
  D:=TSQLCreateDomainStatement(P);
  TestContext.AssertTrue((D.TypeDefinition)<>nil, 'Have type Definition');
  T:=D.TypeDefinition;
  TestContext.AssertTrue((T.DefaultValue)<>nil, 'Have default value');
  CheckClass(T.DefaultValue,TSQLINtegerLiteral);
  TestContext.AssertTrue((sdtInteger)=(T.DataType), 'Integer data type');
  TestContext.AssertTrue((True)=(T.NotNull), 'Not null');
end;

procedure TTestDomainParser.TestCheckDomain;
var
  P : TSQLCreateOrAlterStatement;
  D : TSQLCreateDomainStatement;
  T : TSQLTypeDefinition;

begin
  P:=TestCreateStatement('CREATE DOMAIN A AS CHAR(8) CHECK (VALUE STARTING WITH ''V'')','A',TSQLCreateDomainStatement);
  CheckClass(P,TSQLCreateDomainStatement);
  D:=TSQLCreateDomainStatement(P);
  TestContext.AssertTrue((D.TypeDefinition)<>nil, 'Have type Definition');
  T:=D.TypeDefinition;
  TestContext.AssertTrue((T.DefaultValue)=nil, 'No default value');
  TestContext.AssertTrue((sdtChar)=(T.DataType), 'Character data type');
  TestContext.AssertTrue((False)=(T.NotNull), 'Not null must be allowed');
end;

procedure TTestDomainParser.TestDefaultCheckNotNullDomain;
var
  P : TSQLCreateOrAlterStatement;
  D : TSQLCreateDomainStatement;
  T : TSQLTypeDefinition;
begin
  P:=TestCreateStatement(
    'CREATE DOMAIN DEFCHECKNOTN AS VARCHAR(1) DEFAULT ''s'' CHECK (VALUE IN (''s'',''h'',''A'')) NOT NULL',
    'DEFCHECKNOTN',TSQLCreateDomainStatement);
  CheckClass(P,TSQLCreateDomainStatement);
  D:=TSQLCreateDomainStatement(P);
  TestContext.AssertTrue((D.TypeDefinition)<>nil, 'Have type Definition');
  T:=D.TypeDefinition;
  TestContext.AssertTrue((T.DefaultValue)<>nil, 'Have default value');
  TestContext.AssertTrue((sdtVarChar)=(T.DataType), 'Varchar data type');
  TestContext.AssertTrue((True)=(T.NotNull), 'Not null');
end;

procedure TTestDomainParser.TestAlterDomainDropDefault;
begin
  TestCreateStatement('ALTER DOMAIN A DROP DEFAULT','A',TSQLAlterDomainDropDefaultStatement);
end;

procedure TTestDomainParser.TestAlterDomainDropCheck;
begin
  TestCreateStatement('ALTER DOMAIN A DROP CONSTRAINT','A',TSQLAlterDomainDropCheckStatement);
end;

procedure TTestDomainParser.TestAlterDomainAddCheck;

Var
  P : TSQLCreateOrAlterStatement;
  D : TSQLAlterDomainAddCheckStatement;
  B : TSQLBinaryExpression;

begin
  P:=TestCreateStatement('ALTER DOMAIN A ADD CHECK (VALUE IS NOT NULL)','A',TSQLAlterDomainAddCheckStatement);
  D:=TSQLAlterDomainAddCheckStatement(P);
  TestContext.AssertTrue((D.Check)<>nil, 'Have check');
  CheckClass(D.Check,TSQLBinaryExpression);
  B:=TSQLBinaryExpression(D.Check);
  TestContext.AssertTrue((boIsNot)=(B.Operation), 'Is not null operator');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  TestContext.AssertTrue((boisNot)=(B.Operation), 'Is not null operator');
  AssertLiteralExpr('Right is value',B.Right,TSQLNullLiteral);
end;
procedure TTestDomainParser.TestAlterDomainAddConstraintCheck;

Var
  P : TSQLCreateOrAlterStatement;
  D : TSQLAlterDomainAddCheckStatement;
  B : TSQLBinaryExpression;

begin
  P:=TestCreateStatement('ALTER DOMAIN A ADD CONSTRAINT CHECK (VALUE IS NOT NULL)','A',TSQLAlterDomainAddCheckStatement);
  D:=TSQLAlterDomainAddCheckStatement(P);
  TestContext.AssertTrue((D.Check)<>nil, 'Have check');
  CheckClass(D.Check,TSQLBinaryExpression);
  B:=TSQLBinaryExpression(D.Check);
  TestContext.AssertTrue((boIsNot)=(B.Operation), 'Is not null operation');
  AssertLiteralExpr('Left is value',B.Left,TSQLValueLiteral);
  TestContext.AssertTrue((boisNot)=(B.Operation), 'Is not null operator');
  AssertLiteralExpr('Right is value',B.Right,TSQLNullLiteral);
end;

procedure TTestDomainParser.TestAlterDomainAddConstraintError;
begin
  FErrSource:='ALTER DOMAIN A ADD CONSTRAINT (VALUE IS NOT NULL)';
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestDomainParser.TestAlterDomainSetDefault;
Var
  P : TSQLCreateOrAlterStatement;
  D : TSQLAlterDomainSetDefaultStatement;

begin
  P:=TestCreateStatement('ALTER DOMAIN A SET DEFAULT NULL','A',TSQLAlterDomainSetDefaultStatement);
  D:=TSQLAlterDomainSetDefaultStatement(P);
  TestContext.AssertTrue((D.DefaultValue)<>nil, 'Have default');
  CheckClass(D.DefaultValue,TSQLNullLiteral);
end;

procedure TTestDomainParser.TestAlterDomainRename;
Var
  P : TSQLCreateOrAlterStatement;
  D : TSQLAlterDomainRenameStatement;

begin
  P:=TestCreateStatement('ALTER DOMAIN A B','A',TSQLAlterDomainRenameStatement);
  D:=TSQLAlterDomainRenameStatement(P);
  AssertIdentifierName('New name','B',D.NewName);
end;

procedure TTestDomainParser.TestAlterDomainNewType;
Var
  P : TSQLCreateOrAlterStatement;
  D : TSQLAlterDomainTypeStatement;

begin
  P:=TestCreateStatement('ALTER DOMAIN A TYPE CHAR(10)','A',TSQLAlterDomainTypeStatement);
  D:=TSQLAlterDomainTypeStatement(P);
  TestContext.AssertTrue((D.NewType)<>nil, 'Have type definition');
  TestContext.AssertTrue((sdtChar)=(D.NewType.DataType), 'Char type');
  TestContext.AssertTrue((10)=(D.NewType.Len), 'Char type of len 10');
end;

procedure TTestDomainParser.TestAlterDomainNewTypeError1;

begin
  FErrSource:='ALTER DOMAIN A TYPE INT NOT NULL';
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestDomainParser.TestAlterDomainNewTypeError2;
begin
  FErrSource:='ALTER DOMAIN A TYPE INT DEFAULT 1';
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestDomainParser.TestAlterDomainDropCheckError;
begin
  FErrSource:='ALTER DOMAIN A DROP CHECK';
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;


{ TTestExceptionParser }

procedure TTestExceptionParser.TestException;
Var
  P : TSQLCreateOrAlterStatement;
  E : TSQLCreateExceptionStatement;

begin
  P:=TestCreateStatement('CREATE EXCEPTION A ''A message''','A',TSQLCreateExceptionStatement);
  E:=TSQLCreateExceptionStatement(P);
  TestContext.AssertTrue((E.ExceptionMessage)<>nil, 'Have message');
  TestContext.AssertTrue(('A message')=(E.ExceptionMessage.Value), 'Message')
end;

procedure TTestExceptionParser.TestAlterException;
Var
  P : TSQLCreateOrAlterStatement;
  E : TSQLCreateExceptionStatement;

begin
  P:=TestCreateStatement('ALTER EXCEPTION A ''A massage''','A',TSQLAlterExceptionStatement);
  E:=TSQLCreateExceptionStatement(P);
  TestContext.AssertTrue((E.ExceptionMessage)<>nil, 'Have message');
  TestContext.AssertTrue(('A massage')=(E.ExceptionMessage.Value), 'Message')
end;

procedure TTestExceptionParser.TestExceptionError1;
begin
  FErrSource:='CREATE EXCEPTION NOT';
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestExceptionParser.TestExceptionError2;
begin
  FErrSource:='CREATE EXCEPTION A NOT';
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

{ TTestRoleParser }

procedure TTestRoleParser.TestCreateRole;

begin
  TestCreateStatement('CREATE ROLE A','A',TSQLCreateROLEStatement);
end;

procedure TTestRoleParser.TestAlterRole;
begin
  FErrSource:='ALTER ROLE A';
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

{ TTestIndexParser }

procedure TTestIndexParser.TestAlterindexActive;

Var
  A : TSQLAlterIndexStatement;

begin
  A:=TSQLAlterIndexStatement(TestCreateStatement('ALTER INDEX A ACTIVE','A',TSQLAlterIndexStatement));
  TestContext.AssertTrue((False)=(A.Inactive), 'Active');
end;

procedure TTestIndexParser.TestAlterindexInactive;

Var
  A : TSQLAlterIndexStatement;

begin
  A:=TSQLAlterIndexStatement(TestCreateStatement('ALTER INDEX A INACTIVE','A',TSQLAlterIndexStatement));
  TestContext.AssertTrue((True)=(A.Inactive), 'Inactive');
end;

procedure TTestIndexParser.TestCreateIndexSimple;

Var
  C : TSQLCreateIndexStatement;

begin
  C:=TSQLCreateIndexStatement(TestCreateStatement('CREATE INDEX A ON B (C)','A',TSQLCreateIndexStatement));
  If Not (C.Options=[]) then
    TestContext.Fail('Options empty');
  AssertIdentifiername('Correct table name','B',C.TableName);
  TestContext.AssertTrue((C.FieldNames)<>nil, 'Have fieldlist');
  TestContext.AssertTrue((1)=(C.FieldNames.Count), 'Number of fields');
  AssertIdentifiername('Field name','C',C.FieldNames[0]);
end;

procedure TTestIndexParser.TestIndexIndexDouble;

Var
  C : TSQLCreateIndexStatement;

begin
  C:=TSQLCreateIndexStatement(TestCreateStatement('CREATE INDEX A ON B (C,D)','A',TSQLCreateIndexStatement));
  If Not (C.Options=[]) then
    TestContext.Fail('Options empty');
  AssertIdentifiername('Correct table name','B',C.TableName);
  TestContext.AssertTrue((C.FieldNames)<>nil, 'Have fieldlist');
  TestContext.AssertTrue((2)=(C.FieldNames.Count), 'Number of fields');
  AssertIdentifiername('Field name 1','C',C.FieldNames[0]);
  AssertIdentifiername('Field name 2','D',C.FieldNames[1]);
end;

procedure TTestIndexParser.TestIndexError1;
begin
  FErrSource:='ALTER UNIQUE INDEX A ACTIVE';
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestIndexParser.TestIndexError2;
begin
  FErrSource:='ALTER ASCENDING INDEX A ACTIVE';
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestIndexParser.TestIndexError3;
begin
  FErrSource:='ALTER DESCENDING INDEX A ACTIVE';
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestIndexParser.TestIndexError4;
begin
  FErrSource:='CREATE INDEX A ON B';
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestIndexParser.TestIndexError5;
begin
  FErrSource:='CREATE INDEX A ON B ()';
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestIndexParser.TestIndexError6;
begin
  FErrSource:='CREATE INDEX A ON B (A,)';
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestIndexParser.TestCreateIndexUnique;

Var
  C : TSQLCreateIndexStatement;

begin
  C:=TSQLCreateIndexStatement(TestCreateStatement('CREATE UNIQUE INDEX A ON B (C)','A',TSQLCreateIndexStatement));
  If not ([ioUnique]=C.Options) then
    TestContext.Fail('Not Unique index');
  AssertIdentifierName('Have table name','B',C.TableName);
  TestContext.AssertTrue((C.FieldNames)<>nil, 'Have fieldlist');
  TestContext.AssertTrue((1)=(C.FieldNames.Count), 'Number of fields');
  AssertIdentifierName('Correct field name','C',C.FieldNames[0]);
end;

procedure TTestIndexParser.TestCreateIndexUniqueAscending;

Var
  C : TSQLCreateIndexStatement;

begin
  C:=TSQLCreateIndexStatement(TestCreateStatement('CREATE UNIQUE ASCENDING INDEX A ON B (C)','A',TSQLCreateIndexStatement));
  If not ([ioUnique,ioAscending ]=C.Options) then
    TestContext.Fail('Not Unique ascending index');
  AssertIdentifierName('Have table name','B',C.TableName);
  TestContext.AssertTrue((C.FieldNames)<>nil, 'Have fieldlist');
  TestContext.AssertTrue((1)=(C.FieldNames.Count), 'Number of fields');
  AssertIdentifierName('Correct field name','C',C.FieldNames[0]);
end;

procedure TTestIndexParser.TestCreateIndexUniqueDescending;

Var
  C : TSQLCreateIndexStatement;

begin
  C:=TSQLCreateIndexStatement(TestCreateStatement('CREATE UNIQUE DESCENDING INDEX A ON B (C)','A',TSQLCreateIndexStatement));
  If not ([ioUnique,ioDescending]=C.Options) then
    TestContext.Fail('Not Unique descending index');
  AssertIdentifierName('Have table name','B',C.TableName);
  TestContext.AssertTrue((C.FieldNames)<>nil, 'Have fieldlist');
  TestContext.AssertTrue((1)=(C.FieldNames.Count), 'Number of fields');
  AssertIdentifierName('Correct field name','C',C.FieldNames[0]);
end;

procedure TTestIndexParser.TestCreateIndexAscending;

Var
  C : TSQLCreateIndexStatement;

begin
  C:=TSQLCreateIndexStatement(TestCreateStatement('CREATE ASCENDING INDEX A ON B (C)','A',TSQLCreateIndexStatement));
  If not ([ioAscending]=C.Options) then
    TestContext.Fail('Not ascending index');
  AssertIdentifierName('Have table name','B',C.TableName);
  TestContext.AssertTrue((C.FieldNames)<>nil, 'Have fieldlist');
  TestContext.AssertTrue((1)=(C.FieldNames.Count), 'Number of fields');
  AssertIdentifierName('Correct field name','C',C.FieldNames[0]);
end;

procedure TTestIndexParser.TestCreateIndexDescending;

Var
  C : TSQLCreateIndexStatement;

begin
  C:=TSQLCreateIndexStatement(TestCreateStatement('CREATE DESCENDING INDEX A ON B (C)','A',TSQLCreateIndexStatement));
  If not ([ioDescending] = C.Options) then
    TestContext.Fail('Not descending index');
  AssertIdentifierName('Table name','B',C.TableName);
  TestContext.AssertTrue((C.FieldNames)<>nil, 'Have fieldlist');
  TestContext.AssertTrue((1)=(C.FieldNames.Count), 'Number of fields');
  AssertIdentifierName('Correct field name','C',C.FieldNames[0]);
end;

{ TTestTableParser }

procedure TTestTableParser.DoTestCreateReferencesField(const ASource: String;
  AOnUpdate, AOnDelete: TForeignKeyAction);
Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;
  D : TSQLForeignKeyFieldConstraint;

begin

  C:=TSQLCreateTableStatement(TestCreateStatement(ASource,'A',TSQLCreateTableStatement));
  TestContext.AssertTrue((1)=(C.FieldDefs.Count), 'One field');
  TestContext.AssertTrue((0)=(C.Constraints.Count), 'No constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[0],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','B',F.FieldName);
  TestContext.AssertTrue((F.FieldType)<>nil, 'Have field type');
  TestContext.AssertTrue((sdtInteger)=(F.FieldType.DataType), 'Correct field type');
  TestContext.AssertTrue((false)=(F.FieldType.NotNull), 'Field can be NULL');
  TestContext.AssertTrue((F.FieldType.DefaultValue)=nil, 'Have default');
  TestContext.AssertTrue((F.FieldType.Constraint)<>nil, 'Have constraint');
  D:=TSQLForeignKeyFieldConstraint(CheckClass(F.FieldType.Constraint,TSQLForeignKeyFieldConstraint));
  TestContext.AssertTrue((D.ConstraintName)=nil, 'No constraint name');
  AssertIdentifierName('Correct table name','C',D.Definition.TableName);
  TestContext.AssertTrue((1)=(D.Definition.FieldList.Count), 'Correct field list count');
  AssertIdentifierName('Correct field name','D',D.Definition.FieldList[0]);
  TestContext.AssertTrue((AOnUpdate)=(D.Definition.OnUpdate), 'No on update action');
  TestContext.AssertTrue((AOnDelete)=(D.Definition.OnDelete), 'No on delete action');
end;

procedure TTestTableParser.TestCreateOneSimpleField;

Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;

begin
  C:=TSQLCreateTableStatement(TestCreateStatement('CREATE TABLE A (B INT)','A',TSQLCreateTableStatement));
  TestContext.AssertTrue((1)=(C.FieldDefs.Count), 'One field');
  TestContext.AssertTrue((0)=(C.Constraints.Count), 'No constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[0],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','B',F.FieldName);
  TestContext.AssertTrue((F.FieldType)<>nil, 'Have field type');
  TestContext.AssertTrue((sdtInteger)=(F.FieldType.DataType), 'Correct field type');
end;

procedure TTestTableParser.TestCreateTwoSimpleFields;

Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;

begin
  C:=TSQLCreateTableStatement(TestCreateStatement('CREATE TABLE A (B INT, C CHAR(5))','A',TSQLCreateTableStatement));
  TestContext.AssertTrue((2)=(C.FieldDefs.Count), 'Two fields');
  TestContext.AssertTrue((0)=(C.Constraints.Count), 'No constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[0],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','B',F.FieldName);
  TestContext.AssertTrue((F.FieldType)<>nil, 'Have field type');
  TestContext.AssertTrue((sdtInteger)=(F.FieldType.DataType), 'Correct field type');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[1],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','C',F.FieldName);
  TestContext.AssertTrue((F.FieldType)<>nil, 'Have field type');
  TestContext.AssertTrue((sdtChar)=(F.FieldType.DataType), 'Correct field type');
end;

procedure TTestTableParser.TestCreateOnePrimaryField;

Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;
  P : TSQLPrimaryKeyFieldConstraint;

begin
  C:=TSQLCreateTableStatement(TestCreateStatement('CREATE TABLE A (B INT PRIMARY KEY)','A',TSQLCreateTableStatement));
  TestContext.AssertTrue((1)=(C.FieldDefs.Count), 'One field');
  TestContext.AssertTrue((0)=(C.Constraints.Count), 'No constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[0],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','B',F.FieldName);
  TestContext.AssertTrue((F.FieldType)<>nil, 'Have field type');
  TestContext.AssertTrue((sdtInteger)=(F.FieldType.DataType), 'Correct field type');
  TestContext.AssertTrue((F.FieldType.Constraint)<>nil, 'Have constraint');
  P:=TSQLPrimaryKeyFieldConstraint(CheckClass(F.FieldType.Constraint,TSQLPrimaryKeyFieldConstraint));
  TestContext.AssertTrue((P.ConstraintName)=nil, 'No constraint name');
end;

procedure TTestTableParser.TestCreateOneNamedPrimaryField;
Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;
  P : TSQLPrimaryKeyFieldConstraint;

begin
  C:=TSQLCreateTableStatement(TestCreateStatement('CREATE TABLE A (B INT CONSTRAINT C PRIMARY KEY)','A',TSQLCreateTableStatement));
  TestContext.AssertTrue((1)=(C.FieldDefs.Count), 'One field');
  TestContext.AssertTrue((0)=(C.Constraints.Count), 'No constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[0],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','B',F.FieldName);
  TestContext.AssertTrue((F.FieldType)<>nil, 'Have field type');
  TestContext.AssertTrue((sdtInteger)=(F.FieldType.DataType), 'Correct field type');
  TestContext.AssertTrue((F.FieldType.Constraint)<>nil, 'Have constraint');
  P:=TSQLPrimaryKeyFieldConstraint(CheckClass(F.FieldType.Constraint,TSQLPrimaryKeyFieldConstraint));
  AssertIdentifierName('Constraint name','C',P.ConstraintName);
end;

procedure TTestTableParser.TestCreateOneUniqueField;

Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;
  U : TSQLUniqueFieldConstraint;

begin
  C:=TSQLCreateTableStatement(TestCreateStatement('CREATE TABLE A (B INT UNIQUE)','A',TSQLCreateTableStatement));
  TestContext.AssertTrue((1)=(C.FieldDefs.Count), 'One field');
  TestContext.AssertTrue((0)=(C.Constraints.Count), 'No constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[0],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','B',F.FieldName);
  TestContext.AssertTrue((F.FieldType)<>nil, 'Have field type');
  TestContext.AssertTrue((sdtInteger)=(F.FieldType.DataType), 'Correct field type');
  TestContext.AssertTrue((F.FieldType.Constraint)<>nil, 'Have constraint');
  U:=TSQLUniqueFieldConstraint(CheckClass(F.FieldType.Constraint,TSQLUniqueFieldConstraint));
  TestContext.AssertTrue((U.ConstraintName)=nil, 'No constraint name');
end;

procedure TTestTableParser.TestCreateOneNamedUniqueField;

Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;
  U : TSQLUniqueFieldConstraint;

begin
  C:=TSQLCreateTableStatement(TestCreateStatement('CREATE TABLE A (B INT CONSTRAINT C UNIQUE)','A',TSQLCreateTableStatement));
  TestContext.AssertTrue((1)=(C.FieldDefs.Count), 'One field');
  TestContext.AssertTrue((0)=(C.Constraints.Count), 'No constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[0],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','B',F.FieldName);
  TestContext.AssertTrue((F.FieldType)<>nil, 'Have field type');
  TestContext.AssertTrue((sdtInteger)=(F.FieldType.DataType), 'Correct field type');
  TestContext.AssertTrue((F.FieldType.Constraint)<>nil, 'Have constraint');
  U:=TSQLUniqueFieldConstraint(CheckClass(F.FieldType.Constraint,TSQLUniqueFieldConstraint));
  AssertIdentifierName('Constraint name','C',U.ConstraintName);
end;

procedure TTestTableParser.TestCreateNotNullPrimaryField;
Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;

begin
  C:=TSQLCreateTableStatement(TestCreateStatement('CREATE TABLE A (B INT NOT NULL PRIMARY KEY)','A',TSQLCreateTableStatement));
  TestContext.AssertTrue((1)=(C.FieldDefs.Count), 'One field');
  TestContext.AssertTrue((0)=(C.Constraints.Count), 'No constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[0],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','B',F.FieldName);
  TestContext.AssertTrue((F.FieldType)<>nil, 'Have field type');
  TestContext.AssertTrue((sdtInteger)=(F.FieldType.DataType), 'Correct field type');
  TestContext.AssertTrue((true)=(F.FieldType.NotNull), 'Field is not NULL');
  TestContext.AssertTrue((F.FieldType.Constraint)<>nil, 'Have constraint');
  CheckClass(F.FieldType.Constraint,TSQLPrimaryKeyFieldConstraint);
end;

procedure TTestTableParser.TestCreateNotNullDefaultPrimaryField;
Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;

begin
  C:=TSQLCreateTableStatement(TestCreateStatement('CREATE TABLE A (B INT DEFAULT 0 NOT NULL PRIMARY KEY)','A',TSQLCreateTableStatement));
  TestContext.AssertTrue((1)=(C.FieldDefs.Count), 'One field');
  TestContext.AssertTrue((0)=(C.Constraints.Count), 'No constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[0],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','B',F.FieldName);
  TestContext.AssertTrue((F.FieldType)<>nil, 'Have field type');
  TestContext.AssertTrue((sdtInteger)=(F.FieldType.DataType), 'Correct field type');
  TestContext.AssertTrue((true)=(F.FieldType.NotNull), 'Field is not NULL');
  TestContext.AssertTrue((F.FieldType.DefaultValue)<>nil, 'Have default');
  CheckClass(F.FieldType.DefaultValue,TSQLIntegerLiteral);
  TestContext.AssertTrue((F.FieldType.Constraint)<>nil, 'Have constraint');
  CheckClass(F.FieldType.Constraint,TSQLPrimaryKeyFieldConstraint);
end;

procedure TTestTableParser.TestCreateCheckField;

Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;
  B : TSQLBinaryExpression;
  CC : TSQLCheckFieldConstraint;

begin
  C:=TSQLCreateTableStatement(TestCreateStatement('CREATE TABLE A (B INT CHECK (B<>0))','A',TSQLCreateTableStatement));
  TestContext.AssertTrue((1)=(C.FieldDefs.Count), 'One field');
  TestContext.AssertTrue((0)=(C.Constraints.Count), 'No constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[0],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','B',F.FieldName);
  TestContext.AssertTrue((F.FieldType)<>nil, 'Have field type');
  TestContext.AssertTrue((sdtInteger)=(F.FieldType.DataType), 'Correct field type');
  TestContext.AssertTrue((F.FieldType.DefaultValue)=nil, 'Have no default');
  TestContext.AssertTrue((F.FieldType.Check)=nil, 'Fieldtype has no check');
  TestContext.AssertTrue((F.FieldType.Constraint)<>nil, 'Field has constraint check');
  CC:=TSQLCheckFieldConstraint(CheckClass(F.FieldType.Constraint,TSQLCheckFieldConstraint));
  TestContext.AssertTrue((CC.ConstraintName)=nil, 'No constraint name');
  B:=TSQLBinaryExpression(CheckClass(CC.Expression,TSQLBinaryExpression));
  TestContext.AssertTrue((boNE)=(B.Operation), 'Unequal check');
end;

procedure TTestTableParser.TestCreateNamedCheckField;

Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;
  B : TSQLBinaryExpression;
  CC : TSQLCheckFieldConstraint;

begin
  C:=TSQLCreateTableStatement(TestCreateStatement('CREATE TABLE A (B INT CONSTRAINT C CHECK (B<>0))','A',TSQLCreateTableStatement));
  TestContext.AssertTrue((1)=(C.FieldDefs.Count), 'One field');
  TestContext.AssertTrue((0)=(C.Constraints.Count), 'No constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[0],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','B',F.FieldName);
  TestContext.AssertTrue((F.FieldType)<>nil, 'Have field type');
  TestContext.AssertTrue((sdtInteger)=(F.FieldType.DataType), 'Correct field type');
  TestContext.AssertTrue((F.FieldType.DefaultValue)=nil, 'Have no default');
  TestContext.AssertTrue((F.FieldType.Check)=nil, 'Fieldtype has no check');
  TestContext.AssertTrue((F.FieldType.Constraint)<>nil, 'Field has constraint check');
  CC:=TSQLCheckFieldConstraint(CheckClass(F.FieldType.Constraint,TSQLCheckFieldConstraint));
  AssertidentifierName('Constraint name','C',CC.ConstraintName);
  B:=TSQLBinaryExpression(CheckClass(CC.Expression,TSQLBinaryExpression));
  TestContext.AssertTrue((boNE)=(B.Operation), 'Unequal check');
end;

procedure TTestTableParser.TestCreateReferencesField;

begin
  DoTestCreateReferencesField('CREATE TABLE A (B INT REFERENCES C(D))',fkaNone,fkaNone);
end;

procedure TTestTableParser.TestCreateReferencesOnUpdateCascadeField;

begin
  DoTestCreateReferencesField('CREATE TABLE A (B INT REFERENCES C(D) ON UPDATE CASCADE)',fkaCascade,fkaNone);
end;

procedure TTestTableParser.TestCreateReferencesOnUpdateNoActionField;

begin
  DoTestCreateReferencesField('CREATE TABLE A (B INT REFERENCES C(D) ON UPDATE NO ACTION)',fkaNoAction,fkaNone);
end;

procedure TTestTableParser.TestCreateReferencesOnUpdateSetDefaultField;
begin
  DoTestCreateReferencesField('CREATE TABLE A (B INT REFERENCES C(D) ON UPDATE SET DEFAULT)',fkaSetDefault,fkaNone);
end;

procedure TTestTableParser.TestCreateReferencesOnUpdateSetNullField;
begin
  DoTestCreateReferencesField('CREATE TABLE A (B INT REFERENCES C(D) ON UPDATE SET NULL)',fkaSetNull,fkaNone);
end;

procedure TTestTableParser.TestCreateReferencesOnDeleteCascadeField;

begin
  DoTestCreateReferencesField('CREATE TABLE A (B INT REFERENCES C(D) ON DELETE CASCADE)',fkaNone,fkaCascade);
end;

procedure TTestTableParser.TestCreateReferencesOnDeleteNoActionField;

begin
  DoTestCreateReferencesField('CREATE TABLE A (B INT REFERENCES C(D) ON DELETE NO ACTION)',fkaNone,fkaNoAction);
end;

procedure TTestTableParser.TestCreateReferencesOnDeleteSetDefaultField;
begin
  DoTestCreateReferencesField('CREATE TABLE A (B INT REFERENCES C(D) ON DELETE SET DEFAULT)',fkaNone,fkaSetDefault);
end;

procedure TTestTableParser.TestCreateReferencesOnDeleteSetNullField;
begin
  DoTestCreateReferencesField('CREATE TABLE A (B INT REFERENCES C(D) ON DELETE SET NULL)',fkaNone,fkaSetNull);
end;

procedure TTestTableParser.TestCreateReferencesOnUpdateAndDeleteSetNullField;
begin
  DoTestCreateReferencesField('CREATE TABLE A (B INT REFERENCES C(D) ON UPDATE SET NULL ON DELETE SET NULL)',fkaSetNull,fkaSetNull);
end;

procedure TTestTableParser.TestCreateNamedReferencesField;
Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;
  D : TSQLForeignKeyFieldConstraint;

begin
  C:=TSQLCreateTableStatement(TestCreateStatement('CREATE TABLE A (B INT CONSTRAINT FK REFERENCES C(D))','A',TSQLCreateTableStatement));
  TestContext.AssertTrue((1)=(C.FieldDefs.Count), 'One field');
  TestContext.AssertTrue((0)=(C.Constraints.Count), 'No constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[0],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','B',F.FieldName);
  TestContext.AssertTrue((F.FieldType)<>nil, 'Have field type');
  TestContext.AssertTrue((sdtInteger)=(F.FieldType.DataType), 'Correct field type');
  TestContext.AssertTrue((false)=(F.FieldType.NotNull), 'Field can be NULL');
  TestContext.AssertTrue((F.FieldType.DefaultValue)=nil, 'Have default');
  TestContext.AssertTrue((F.FieldType.Constraint)<>nil, 'Have constraint');
  D:=TSQLForeignKeyFieldConstraint(CheckClass(F.FieldType.Constraint,TSQLForeignKeyFieldConstraint));
  AssertIdentifierName('Correct constraint name','FK',D.ConstraintName);
  AssertIdentifierName('Correct table name','C',D.Definition.TableName);
  TestContext.AssertTrue((1)=(D.Definition.FieldList.Count), 'Correct field list count');
  AssertIdentifierName('Correct field name','D',D.Definition.FieldList[0]);
end;

procedure TTestTableParser.TestCreateComputedByField;

Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;
  B : TSQLBinaryExpression;

begin
  C:=TSQLCreateTableStatement(TestCreateStatement('CREATE TABLE A (B INT, C INT, D COMPUTED BY (B+C))','A',TSQLCreateTableStatement));
  TestContext.AssertTrue((3)=(C.FieldDefs.Count), 'Three fields');
  TestContext.AssertTrue((0)=(C.Constraints.Count), 'No constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[2],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','D',F.FieldName);
  TestContext.AssertTrue((F.FieldType)=nil, 'No field type');
  TestContext.AssertTrue((F.ComputedBy)<>nil, 'Have computed by expression');
  B:=TSQLBinaryExpression(CheckClass(F.ComputedBy,TSQLBinaryExpression));
  TestContext.AssertTrue((boAdd)=(B.Operation), 'Add operation');
  CheckClass(B.Left,TSQLIdentifierExpression);
  AssertIdentifierName('Correct identifier','B',TSQLIdentifierExpression(B.Left).Identifier);
  CheckClass(B.Right,TSQLIdentifierExpression);
  AssertIdentifierName('Correct identifier','C',TSQLIdentifierExpression(B.Right).Identifier);
end;

procedure TTestTableParser.TestCreatePrimaryKeyConstraint;

Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;
  P: TSQLTablePrimaryKeyConstraintDef;

begin
  C:=TSQLCreateTableStatement(TestCreateStatement('CREATE TABLE A (B INT, PRIMARY KEY (B))','A',TSQLCreateTableStatement));
  TestContext.AssertTrue((1)=(C.FieldDefs.Count), 'One field');
  TestContext.AssertTrue((1)=(C.Constraints.Count), 'One constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[0],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','B',F.FieldName);
  P:=TSQLTablePrimaryKeyConstraintDef(CheckClass(C.Constraints[0],TSQLTablePrimaryKeyConstraintDef));
  TestContext.AssertTrue((P.FieldList)<>nil, 'Fieldlist assigned');
  TestContext.AssertTrue((P.ConstraintName)=nil, 'Constraint name empty');
  TestContext.AssertTrue((1)=(P.FieldList.Count), 'One field in primary key');
  AssertIdentifierName('fieldname','B',P.FieldList[0]);
end;

procedure TTestTableParser.TestCreateNamedPrimaryKeyConstraint;

Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;
  P: TSQLTablePrimaryKeyConstraintDef;

begin
  C:=TSQLCreateTableStatement(TestCreateStatement('CREATE TABLE A (B INT, CONSTRAINT A_PK PRIMARY KEY (B))','A',TSQLCreateTableStatement));
  TestContext.AssertTrue((1)=(C.FieldDefs.Count), 'One field');
  TestContext.AssertTrue((1)=(C.Constraints.Count), 'One constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[0],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','B',F.FieldName);
  P:=TSQLTablePrimaryKeyConstraintDef(CheckClass(C.Constraints[0],TSQLTablePrimaryKeyConstraintDef));
  TestContext.AssertTrue((P.FieldList)<>nil, 'Fieldlist assigned');
  AssertIdentifierName('fieldname','A_PK',P.ConstraintName);
  TestContext.AssertTrue((1)=(P.FieldList.Count), 'One field in primary key');
  AssertIdentifierName('fieldname','B',P.FieldList[0]);
end;

procedure TTestTableParser.TestCreateForeignKeyConstraint;
Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;
  P: TSQLTableForeignKeyConstraintDef;

begin
  C:=TSQLCreateTableStatement(TestCreateStatement('CREATE TABLE A (B INT, FOREIGN KEY (B) REFERENCES C(D))','A',TSQLCreateTableStatement));
  TestContext.AssertTrue((1)=(C.FieldDefs.Count), 'One field');
  TestContext.AssertTrue((1)=(C.Constraints.Count), 'One constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[0],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','B',F.FieldName);
  P:=TSQLTableForeignKeyConstraintDef(CheckClass(C.Constraints[0],TSQLTableForeignKeyConstraintDef));
  TestContext.AssertTrue((P.FieldList)<>nil, 'Fieldlist assigned');
  TestContext.AssertTrue((P.ConstraintName)=nil, 'Constraint name');
  TestContext.AssertTrue((1)=(P.FieldList.Count), 'One field in foreign key');
  AssertIdentifierName('fieldname','B',P.FieldList[0]);
  AssertIdentifierName('Target table name','C',P.Definition.TableName);
  TestContext.AssertTrue((1)=(P.Definition.FieldList.Count), 'One field in primary key target');
  AssertIdentifierName('target fieldname','D',P.Definition.FieldList[0]);
end;

procedure TTestTableParser.TestCreateNamedForeignKeyConstraint;
Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;
  P: TSQLTableForeignKeyConstraintDef;

begin
  C:=TSQLCreateTableStatement(TestCreateStatement('CREATE TABLE A (B INT, CONSTRAINT A_FK FOREIGN KEY (B) REFERENCES C(D))','A',TSQLCreateTableStatement));
  TestContext.AssertTrue((1)=(C.FieldDefs.Count), 'One field');
  TestContext.AssertTrue((1)=(C.Constraints.Count), 'One constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[0],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','B',F.FieldName);
  P:=TSQLTableForeignKeyConstraintDef(CheckClass(C.Constraints[0],TSQLTableForeignKeyConstraintDef));
  TestContext.AssertTrue((P.FieldList)<>nil, 'Fieldlist assigned');
  AssertIdentifierName('fieldname','A_FK',P.ConstraintName);
  TestContext.AssertTrue((1)=(P.FieldList.Count), 'One field in foreign key');
  AssertIdentifierName('fieldname','B',P.FieldList[0]);
  AssertIdentifierName('Target table name','C',P.Definition.TableName);
  TestContext.AssertTrue((1)=(P.Definition.FieldList.Count), 'One field in primary key target');
  AssertIdentifierName('target fieldname','D',P.Definition.FieldList[0]);
end;

procedure TTestTableParser.TestCreateUniqueConstraint;
Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;
  P: TSQLTableUniqueConstraintDef;

begin
  C:=TSQLCreateTableStatement(TestCreateStatement('CREATE TABLE A (B INT, UNIQUE (B))','A',TSQLCreateTableStatement));
  TestContext.AssertTrue((1)=(C.FieldDefs.Count), 'One field');
  TestContext.AssertTrue((1)=(C.Constraints.Count), 'One constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[0],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','B',F.FieldName);
  P:=TSQLTableUniqueConstraintDef(CheckClass(C.Constraints[0],TSQLTableUniqueConstraintDef));
  TestContext.AssertTrue((P.FieldList)<>nil, 'Fieldlist assigned');
  TestContext.AssertTrue((P.ConstraintName)=nil, 'Constraint name empty');
  TestContext.AssertTrue((1)=(P.FieldList.Count), 'One field in primary key');
  AssertIdentifierName('Name is correct','B',P.FieldList[0]);
end;

procedure TTestTableParser.TestCreateNamedUniqueConstraint;
Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;
  P: TSQLTableUniqueConstraintDef;

begin
  C:=TSQLCreateTableStatement(TestCreateStatement('CREATE TABLE A (B INT, CONSTRAINT U_A UNIQUE (B))','A',TSQLCreateTableStatement));
  TestContext.AssertTrue((1)=(C.FieldDefs.Count), 'One field');
  TestContext.AssertTrue((1)=(C.Constraints.Count), 'One constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[0],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','B',F.FieldName);
  P:=TSQLTableUniqueConstraintDef(CheckClass(C.Constraints[0],TSQLTableUniqueConstraintDef));
  TestContext.AssertTrue((P.FieldList)<>nil, 'Fieldlist assigned');
  AssertIdentifierName('fieldname','U_A',P.ConstraintName);
  TestContext.AssertTrue((1)=(P.FieldList.Count), 'One field in primary key');
  AssertIdentifierName('Name is correct','B',P.FieldList[0]);
end;

procedure TTestTableParser.TestCreateCheckConstraint;
Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;
  B : TSQLBinaryExpression;
  P: TSQLTableCheckConstraintDef;

begin
  C:=TSQLCreateTableStatement(TestCreateStatement('CREATE TABLE A (B INT, CHECK (B<>0))','A',TSQLCreateTableStatement));
  TestContext.AssertTrue((1)=(C.FieldDefs.Count), 'One field');
  TestContext.AssertTrue((1)=(C.Constraints.Count), 'One constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[0],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','B',F.FieldName);
  P:=TSQLTableCheckConstraintDef(CheckClass(C.Constraints[0],TSQLTableCheckConstraintDef));
  TestContext.AssertTrue((P.ConstraintName)=nil, 'Constraint name empty');
  TestContext.AssertTrue((P.Check)<>nil, 'Check expression assigned');
  B:=TSQLBinaryExpression(CheckClass(P.Check,TSQLBinaryExpression));
  TestContext.AssertTrue((boNE)=(B.Operation), 'Unequal');
end;

procedure TTestTableParser.TestCreateNamedCheckConstraint;
Var
  C : TSQLCreateTableStatement;
  F : TSQLTableFieldDef;
  B : TSQLBinaryExpression;
  P: TSQLTableCheckConstraintDef;

begin
  C:=TSQLCreateTableStatement(TestCreateStatement('CREATE TABLE A (B INT, CONSTRAINT C_A CHECK (B<>0))','A',TSQLCreateTableStatement));
  TestContext.AssertTrue((1)=(C.FieldDefs.Count), 'One field');
  TestContext.AssertTrue((1)=(C.Constraints.Count), 'One constraints');
  F:=TSQLTableFieldDef(CheckClass(C.FieldDefs[0],TSQLTableFieldDef));
  AssertIdentifierName('fieldname','B',F.FieldName);
  P:=TSQLTableCheckConstraintDef(CheckClass(C.Constraints[0],TSQLTableCheckConstraintDef));
  AssertIdentifierName('Constainrname','C_A',P.ConstraintName);
  TestContext.AssertTrue((P.Check)<>nil, 'Check expression assigned');
  B:=TSQLBinaryExpression(CheckClass(P.Check,TSQLBinaryExpression));
  TestContext.AssertTrue((boNE)=(B.Operation), 'Not equal operation');
end;

procedure TTestTableParser.TestAlterDropField;
Var
  A : TSQLAlterTableStatement;
  D : TSQLDropTableFieldOperation;

begin
  A:=TSQLAlterTableStatement(TestCreateStatement('ALTER TABLE A DROP B','A',TSQLAlterTableStatement));
  TestContext.AssertTrue((1)=(A.Operations.Count), 'One operation');
  D:=TSQLDropTableFieldOperation(CheckClass(A.Operations[0],TSQLDropTableFieldOperation));
  AssertidentifierName('Drop field name','B',D.ObjectName);
end;

procedure TTestTableParser.TestAlterDropFields;
Var
  A : TSQLAlterTableStatement;
  D : TSQLDropTableFieldOperation;

begin
  A:=TSQLAlterTableStatement(TestCreateStatement('ALTER TABLE A DROP B, DROP C','A',TSQLAlterTableStatement));
  TestContext.AssertTrue((2)=(A.Operations.Count), 'Two operations');
  D:=TSQLDropTableFieldOperation(CheckClass(A.Operations[0],TSQLDropTableFieldOperation));
  AssertidentifierName('Drop field name','B',D.ObjectName);
  D:=TSQLDropTableFieldOperation(CheckClass(A.Operations[1],TSQLDropTableFieldOperation));
  AssertidentifierName('Drop field name','C',D.ObjectName);
end;

procedure TTestTableParser.TestAlterDropConstraint;
Var
  A : TSQLAlterTableStatement;
  D : TSQLDropTableConstraintOperation;

begin
  A:=TSQLAlterTableStatement(TestCreateStatement('ALTER TABLE A DROP CONSTRAINT B','A',TSQLAlterTableStatement));
  TestContext.AssertTrue((1)=(A.Operations.Count), 'One operation');
  D:=TSQLDropTableConstraintOperation(CheckClass(A.Operations[0],TSQLDropTableConstraintOperation));
  AssertidentifierName('Drop field name','B',D.ObjectName);
end;

procedure TTestTableParser.TestAlterDropConstraints;
Var
  A : TSQLAlterTableStatement;
  D : TSQLDropTableConstraintOperation;

begin
  A:=TSQLAlterTableStatement(TestCreateStatement('ALTER TABLE A DROP CONSTRAINT B, DROP CONSTRAINT C','A',TSQLAlterTableStatement));
  TestContext.AssertTrue((2)=(A.Operations.Count), 'Two operations');
  D:=TSQLDropTableConstraintOperation(CheckClass(A.Operations[0],TSQLDropTableConstraintOperation));
  AssertidentifierName('Drop Constraint name','B',D.ObjectName);
  D:=TSQLDropTableConstraintOperation(CheckClass(A.Operations[1],TSQLDropTableConstraintOperation));
  AssertidentifierName('Drop field name','C',D.ObjectName);
end;

procedure TTestTableParser.TestAlterRenameField;
Var
  A : TSQLAlterTableStatement;
  R : TSQLAlterTableFieldNameOperation;

begin
  A:=TSQLAlterTableStatement(TestCreateStatement('ALTER TABLE A ALTER B TO C','A',TSQLAlterTableStatement));
  TestContext.AssertTrue((1)=(A.Operations.Count), 'One operation');
  R:=TSQLAlterTableFieldNameOperation(CheckClass(A.Operations[0],TSQLAlterTableFieldNameOperation));
  AssertidentifierName('Old field name','B',R.ObjectName);
  AssertidentifierName('New field name','C',R.NewName);
end;
procedure TTestTableParser.TestAlterRenameColumnField;
Var
  A : TSQLAlterTableStatement;
  R : TSQLAlterTableFieldNameOperation;

begin
  A:=TSQLAlterTableStatement(TestCreateStatement('ALTER TABLE A ALTER COLUMN B TO C','A',TSQLAlterTableStatement));
  TestContext.AssertTrue((1)=(A.Operations.Count), 'One operation');
  R:=TSQLAlterTableFieldNameOperation(CheckClass(A.Operations[0],TSQLAlterTableFieldNameOperation));
  AssertidentifierName('Old field name','B',R.ObjectName);
  AssertidentifierName('New field name','C',R.NewName);
end;

procedure TTestTableParser.TestAlterFieldType;
Var
  A : TSQLAlterTableStatement;
  R : TSQLAlterTableFieldTypeOperation;

begin
  A:=TSQLAlterTableStatement(TestCreateStatement('ALTER TABLE A ALTER COLUMN B TYPE INT','A',TSQLAlterTableStatement));
  TestContext.AssertTrue((1)=(A.Operations.Count), 'One operation');
  R:=TSQLAlterTableFieldTypeOperation(CheckClass(A.Operations[0],TSQLAlterTableFieldTypeOperation));
  AssertidentifierName('Old field name','B',R.ObjectName);
  TestContext.AssertTrue((R.NewType)<>nil, 'Have field type');
  Checkclass(R.NewType,TSQLTypeDefinition);
  TestContext.AssertTrue((sdtInteger)=(R.NewType.DataType), 'Correct data type');
end;

procedure TTestTableParser.TestAlterFieldPosition;
Var
  A : TSQLAlterTableStatement;
  R : TSQLAlterTableFieldPositionOperation;

begin
  A:=TSQLAlterTableStatement(TestCreateStatement('ALTER TABLE A ALTER COLUMN B POSITION 3','A',TSQLAlterTableStatement));
  TestContext.AssertTrue((1)=(A.Operations.Count), 'One operation');
  R:=TSQLAlterTableFieldPositionOperation(CheckClass(A.Operations[0],TSQLAlterTableFieldPositionOperation));
  AssertidentifierName('Old field name','B',R.ObjectName);
  TestContext.AssertTrue((3)=(R.NewPosition), 'Correct position');
end;

procedure TTestTableParser.TestAlterAddField;
Var
  A : TSQLAlterTableStatement;
  F : TSQLAlterTableAddFieldOperation;
  D : TSQLTableFieldDef;

begin
  A:=TSQLAlterTableStatement(TestCreateStatement('ALTER TABLE A ADD B INT','A',TSQLAlterTableStatement));
  TestContext.AssertTrue((1)=(A.Operations.Count), 'One operation');
  F:=TSQLAlterTableAddFieldOperation(CheckClass(A.Operations[0],TSQLAlterTableAddFieldOperation));
  TestContext.AssertTrue((F.Element)<>nil, 'Have element');
  D:=TSQLTableFieldDef(CheckClass(F.Element,TSQLTableFieldDef));
  AssertIdentifierName('New field name','B',D.FieldName);
  TestContext.AssertTrue((D.FieldType)<>nil, 'Have fielddef');
  TestContext.AssertTrue((sdtINteger)=(D.FieldType.DataType), 'Correct field type');
end;

procedure TTestTableParser.TestAlterAddFields;

Var
  A : TSQLAlterTableStatement;
  F : TSQLAlterTableAddFieldOperation;
  D : TSQLTableFieldDef;

begin
  A:=TSQLAlterTableStatement(TestCreateStatement('ALTER TABLE A ADD B INT, ADD C CHAR(50)','A',TSQLAlterTableStatement));
  TestContext.AssertTrue((2)=(A.Operations.Count), 'Two operations');
  F:=TSQLAlterTableAddFieldOperation(CheckClass(A.Operations[0],TSQLAlterTableAddFieldOperation));
  TestContext.AssertTrue((F.Element)<>nil, 'Have element');
  D:=TSQLTableFieldDef(CheckClass(F.Element,TSQLTableFieldDef));
  AssertIdentifierName('New field name','B',D.FieldName);
  TestContext.AssertTrue((D.FieldType)<>nil, 'Have fielddef');
  TestContext.AssertTrue((sdtINteger)=(D.FieldType.DataType), 'Correct field type');
  F:=TSQLAlterTableAddFieldOperation(CheckClass(A.Operations[1],TSQLAlterTableAddFieldOperation));
  TestContext.AssertTrue((F.Element)<>nil, 'Have element');
  D:=TSQLTableFieldDef(CheckClass(F.Element,TSQLTableFieldDef));
  AssertIdentifierName('New field name','C',D.FieldName);
  TestContext.AssertTrue((D.FieldType)<>nil, 'Have fielddef');
  TestContext.AssertTrue((sdtChar)=(D.FieldType.DataType), 'Correct field type');
  TestContext.AssertTrue((50)=(D.FieldType.Len), 'Correct field lengthe');
end;

procedure TTestTableParser.TestAlterAddPrimarykey;
Var
  A : TSQLAlterTableStatement;
  F : TSQLAlterTableAddConstraintOperation;
  D : TSQLTablePrimaryKeyConstraintDef;

begin
  A:=TSQLAlterTableStatement(TestCreateStatement('ALTER TABLE A ADD PRIMARY KEY (B)','A',TSQLAlterTableStatement));
  TestContext.AssertTrue((1)=(A.Operations.Count), 'One operation');
  F:=TSQLAlterTableAddConstraintOperation(CheckClass(A.Operations[0],TSQLAlterTableAddConstraintOperation));
  TestContext.AssertTrue((F.Element)<>nil, 'Have element');
  D:=TSQLTablePrimaryKeyConstraintDef(CheckClass(F.Element,TSQLTablePrimaryKeyConstraintDef));
  TestContext.AssertTrue((D.ConstraintName)=nil, 'No constraint name');
  TestContext.AssertTrue((1)=(D.FieldList.Count), 'Have 1 field');
  AssertIdentifierName('fieldname','B',D.FieldList[0]);
end;

procedure TTestTableParser.TestAlterAddNamedPrimarykey;
Var
  A : TSQLAlterTableStatement;
  F : TSQLAlterTableAddConstraintOperation;
  D : TSQLTablePrimaryKeyConstraintDef;

begin
  A:=TSQLAlterTableStatement(TestCreateStatement('ALTER TABLE A ADD CONSTRAINT U_K PRIMARY KEY (B)','A',TSQLAlterTableStatement));
  TestContext.AssertTrue((1)=(A.Operations.Count), 'One operation');
  F:=TSQLAlterTableAddConstraintOperation(CheckClass(A.Operations[0],TSQLAlterTableAddConstraintOperation));
  TestContext.AssertTrue((F.Element)<>nil, 'Have element');
  D:=TSQLTablePrimaryKeyConstraintDef(CheckClass(F.Element,TSQLTablePrimaryKeyConstraintDef));
  AssertIdentifierName('No constraint name','U_K',D.ConstraintName);
  TestContext.AssertTrue((1)=(D.FieldList.Count), 'Have 1 field');
  AssertIdentifierName('fieldname','B',D.FieldList[0]);
end;

procedure TTestTableParser.TestAlterAddCheckConstraint;

Var
  A : TSQLAlterTableStatement;
  F : TSQLAlterTableAddConstraintOperation;
  D : TSQLTableCheckConstraintDef;

begin
  A:=TSQLAlterTableStatement(TestCreateStatement('ALTER TABLE A ADD CHECK (B<>0)','A',TSQLAlterTableStatement));
  TestContext.AssertTrue((1)=(A.Operations.Count), 'One operation');
  F:=TSQLAlterTableAddConstraintOperation(CheckClass(A.Operations[0],TSQLAlterTableAddConstraintOperation));
  TestContext.AssertTrue((F.Element)<>nil, 'Have element');
  D:=TSQLTableCheckConstraintDef(CheckClass(F.Element,TSQLTableCheckConstraintDef));
  TestContext.AssertTrue((D.ConstraintName)=nil, 'Constaintname');
  TestContext.AssertTrue((D.Check)<>nil, 'Check expression assigned');
  CheckClass(D.Check,TSQLBinaryExpression);
end;

procedure TTestTableParser.TestAlterAddNamedCheckConstraint;

Var
  A : TSQLAlterTableStatement;
  F : TSQLAlterTableAddConstraintOperation;
  D : TSQLTableCheckConstraintDef;

begin
  A:=TSQLAlterTableStatement(TestCreateStatement('ALTER TABLE A ADD CONSTRAINT C_A CHECK (B<>0)','A',TSQLAlterTableStatement));
  TestContext.AssertTrue((1)=(A.Operations.Count), 'One operation');
  F:=TSQLAlterTableAddConstraintOperation(CheckClass(A.Operations[0],TSQLAlterTableAddConstraintOperation));
  TestContext.AssertTrue((F.Element)<>nil, 'Have element');
  D:=TSQLTableCheckConstraintDef(CheckClass(F.Element,TSQLTableCheckConstraintDef));
  AssertIdentifierName('Constaintname','C_A',D.ConstraintName);
  TestContext.AssertTrue((D.Check)<>nil, 'Check expression assigned');
  CheckClass(D.Check,TSQLBinaryExpression);
end;

procedure TTestTableParser.TestAlterAddForeignkey;

Var
  A : TSQLAlterTableStatement;
  F : TSQLAlterTableAddConstraintOperation;
  D : TSQLTableForeignKeyConstraintDef;

begin
  A:=TSQLAlterTableStatement(TestCreateStatement('ALTER TABLE A ADD FOREIGN KEY (B) REFERENCES C(D)','A',TSQLAlterTableStatement));
  TestContext.AssertTrue((1)=(A.Operations.Count), 'One operation');
  F:=TSQLAlterTableAddConstraintOperation(CheckClass(A.Operations[0],TSQLAlterTableAddConstraintOperation));
  TestContext.AssertTrue((F.Element)<>nil, 'Have element');
  D:=TSQLTableForeignKeyConstraintDef(CheckClass(F.Element,TSQLTableForeignKeyConstraintDef));
  TestContext.AssertTrue((D.ConstraintName)=nil, 'No constraint name');
  TestContext.AssertTrue((1)=(D.FieldList.Count), 'Have 1 field');
  AssertIdentifierName('fieldname','B',D.FieldList[0]);
  AssertIdentifierName('Target table name','C',D.Definition.TableName);
  TestContext.AssertTrue((1)=(D.Definition.FieldList.Count), 'One field in primary key target');
  AssertIdentifierName('target fieldname','D',D.Definition.FieldList[0]);
end;

procedure TTestTableParser.TestAlterAddNamedForeignkey;
Var
  A : TSQLAlterTableStatement;
  F : TSQLAlterTableAddConstraintOperation;
  D : TSQLTableForeignKeyConstraintDef;

begin
  A:=TSQLAlterTableStatement(TestCreateStatement('ALTER TABLE A ADD CONSTRAINT F_A FOREIGN KEY (B) REFERENCES C(D)','A',TSQLAlterTableStatement));
  TestContext.AssertTrue((1)=(A.Operations.Count), 'One operation');
  F:=TSQLAlterTableAddConstraintOperation(CheckClass(A.Operations[0],TSQLAlterTableAddConstraintOperation));
  TestContext.AssertTrue((F.Element)<>nil, 'Have element');
  D:=TSQLTableForeignKeyConstraintDef(CheckClass(F.Element,TSQLTableForeignKeyConstraintDef));
  AssertIdentifierName('constraint name','F_A',D.ConstraintName);
  TestContext.AssertTrue((1)=(D.FieldList.Count), 'Have 1 field');
  AssertIdentifierName('fieldname','B',D.FieldList[0]);
  AssertIdentifierName('Target table name','C',D.Definition.TableName);
  TestContext.AssertTrue((1)=(D.Definition.FieldList.Count), 'One field in primary key target');
  AssertIdentifierName('target fieldname','D',D.Definition.FieldList[0]);
end;

{ TTestDeleteParser }

function TTestDeleteParser.TestDelete(const ASource,ATable: String
  ): TSQLDeleteStatement;
begin
  CreateParser(ASource);
  FToFree:=Parser.Parse;
  Result:=TSQLDeleteStatement(CheckClass(FToFree,TSQLDeleteStatement));
  AssertIdentifierName('Correct table name',ATable,Result.TableName);
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestDeleteParser.TestSimpleDelete;

Var
  D : TSQLDeleteStatement;

begin
  D:=TestDelete('DELETE FROM A','A');
  TestContext.AssertTrue((D.WhereClause)=nil, 'No where');
end;

procedure TTestDeleteParser.TestSimpleDeleteAlias;
Var
  D : TSQLDeleteStatement;
begin
  D:=TestDelete('DELETE FROM A B','A');
  AssertIdentifierName('Alias name','B',D.AliasName);
  TestContext.AssertTrue((D.WhereClause)=nil, 'No where');
end;

procedure TTestDeleteParser.TestDeleteWhereNull;
Var
  D : TSQLDeleteStatement;
  B : TSQLBinaryExpression;
  I : TSQLIdentifierExpression;
  L : TSQLLiteralExpression;

begin
  D:=TestDelete('DELETE FROM A WHERE B IS NULL','A');
  TestContext.AssertTrue((D.WhereClause)<>nil, 'No where');
  B:=TSQLBinaryExpression(CheckClass(D.WhereClause,TSQLBinaryExpression));
  TestContext.AssertTrue((boIs)=(B.Operation), 'Is null operation');
  I:=TSQLIdentifierExpression(CheckClass(B.Left,TSQLIdentifierExpression));
  AssertIdentifierName('Correct field name','B',I.Identifier);
  L:=TSQLLiteralExpression(CheckClass(B.Right,TSQLLiteralExpression));
  CheckClass(L.Literal,TSQLNullLiteral);
end;

{ TTestUpdateParser }

function TTestUpdateParser.TestUpdate(const ASource, ATable: String
  ): TSQLUpdateStatement;
begin
  CreateParser(ASource);
  FToFree:=Parser.Parse;
  Result:=TSQLUpdateStatement(CheckClass(FToFree,TSQLUpdateStatement));
  AssertIdentifierName('Correct table name',ATable,Result.TableName);
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestUpdateParser.TestUpdateOneField;

Var
  U : TSQLUpdateStatement;
  P : TSQLUpdatePair;
  E : TSQLLiteralExpression;
  I : TSQLIntegerLiteral;

begin
  U:=TestUpdate('UPDATE A SET B=1','A');
  TestContext.AssertTrue((1)=(U.Values.Count), 'One field updated');
  P:=TSQLUpdatePair(CheckClass(U.Values[0],TSQLUpdatePair));
  AssertIdentifierName('Correct field name','B',P.FieldName);
  E:=TSQLLiteralExpression(CheckClass(P.Value,TSQLLiteralExpression));
  I:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(I.Value), 'Value 1');
  TestContext.AssertTrue((U.WhereClause)=nil, 'No where clause');
end;

procedure TTestUpdateParser.TestUpdateOneFieldFull;
Var
  U : TSQLUpdateStatement;
  P : TSQLUpdatePair;
  E : TSQLLiteralExpression;
  I : TSQLIntegerLiteral;

begin
  U:=TestUpdate('UPDATE A SET A.B=1','A');
  TestContext.AssertTrue((1)=(U.Values.Count), 'One field updated');
  P:=TSQLUpdatePair(CheckClass(U.Values[0],TSQLUpdatePair));
  AssertIdentifierName('Correct field name','A.B',P.FieldName);
  E:=TSQLLiteralExpression(CheckClass(P.Value,TSQLLiteralExpression));
  I:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(I.Value), 'Value 1');
  TestContext.AssertTrue((U.WhereClause)=nil, 'No where clause');
end;

procedure TTestUpdateParser.TestUpdateTwoFields;
Var
  U : TSQLUpdateStatement;
  P : TSQLUpdatePair;
  E : TSQLLiteralExpression;
  I : TSQLIntegerLiteral;

begin
  U:=TestUpdate('UPDATE A SET B=1, C=2','A');
  TestContext.AssertTrue((2)=(U.Values.Count), 'One field updated');
  P:=TSQLUpdatePair(CheckClass(U.Values[0],TSQLUpdatePair));
  AssertIdentifierName('Correct field name','B',P.FieldName);
  E:=TSQLLiteralExpression(CheckClass(P.Value,TSQLLiteralExpression));
  I:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(I.Value), 'Value 1');
  P:=TSQLUpdatePair(CheckClass(U.Values[1],TSQLUpdatePair));
  AssertIdentifierName('Correct field name','C',P.FieldName);
  E:=TSQLLiteralExpression(CheckClass(P.Value,TSQLLiteralExpression));
  I:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((2)=(I.Value), 'Value 2');
  TestContext.AssertTrue((U.WhereClause)=nil, 'No where clause');
end;

procedure TTestUpdateParser.TestUpdateOneFieldWhereIsNull;
Var
  U : TSQLUpdateStatement;
  P : TSQLUpdatePair;
  E : TSQLLiteralExpression;
  I : TSQLIntegerLiteral;
  B : TSQLBinaryExpression;
  IE : TSQLIdentifierExpression;
  L : TSQLLiteralExpression;

begin
  U:=TestUpdate('UPDATE A SET B=1 WHERE B IS NULL','A');
  TestContext.AssertTrue((1)=(U.Values.Count), 'One field updated');
  P:=TSQLUpdatePair(CheckClass(U.Values[0],TSQLUpdatePair));
  AssertIdentifierName('Correct field name','B',P.FieldName);
  E:=TSQLLiteralExpression(CheckClass(P.Value,TSQLLiteralExpression));
  I:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(I.Value), 'Value 1');
  TestContext.AssertTrue((U.WhereClause)<>nil, 'where clause');
  B:=TSQLBinaryExpression(CheckClass(U.WhereClause,TSQLBinaryExpression));
  TestContext.AssertTrue((boIs)=(B.Operation), 'Is null operation');
  IE:=TSQLIdentifierExpression(CheckClass(B.Left,TSQLIdentifierExpression));
  AssertIdentifierName('Correct field name','B',IE.Identifier);
  L:=TSQLLiteralExpression(CheckClass(B.Right,TSQLLiteralExpression));
  CheckClass(L.Literal,TSQLNullLiteral);
end;

{ TTestInsertParser }

function TTestInsertParser.TestInsert(const ASource, ATable: String
  ): TSQLInsertStatement;
begin
  CreateParser(ASource);
  FToFree:=Parser.Parse;
  Result:=TSQLInsertStatement(CheckClass(FToFree,TSQLInsertStatement));
  AssertIdentifierName('Correct table name',ATable,Result.TableName);
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestInsertParser.TestInsertOneField;

Var
  I : TSQLInsertStatement;
  E : TSQLLiteralExpression;
  L : TSQLIntegerLiteral;

begin
  I:=TestInsert('INSERT INTO A (B) VALUES (1)','A');
  TestContext.AssertTrue((I.Fields)<>nil, 'Have fields');
  TestContext.AssertTrue((1)=(I.Fields.Count), '1 field');
  AssertIdentifierName('Correct field name','B',I.Fields[0]);
  TestContext.AssertTrue((I.Values)<>nil, 'Have values');
  TestContext.AssertTrue((1)=(I.Values.Count), 'Have 1 value');
  E:=TSQLLiteralExpression(CheckClass(I.Values[0],TSQLLiteralExpression));
  L:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(L.Value), 'Correct value');
end;

procedure TTestInsertParser.TestInsertTwoFields;

Var
  I : TSQLInsertStatement;
  E : TSQLLiteralExpression;
  L : TSQLIntegerLiteral;

begin
  I:=TestInsert('INSERT INTO A (B,C) VALUES (1,2)','A');
  TestContext.AssertTrue((I.Fields)<>nil, 'Have fields');
  TestContext.AssertTrue((2)=(I.Fields.Count), '2 fields');
  AssertIdentifierName('Correct field 1 name','B',I.Fields[0]);
  AssertIdentifierName('Correct field 2 name','C',I.Fields[1]);
  TestContext.AssertTrue((I.Values)<>nil, 'Have values');
  TestContext.AssertTrue((2)=(I.Values.Count), 'Have 2 values');
  E:=TSQLLiteralExpression(CheckClass(I.Values[0],TSQLLiteralExpression));
  L:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(L.Value), 'Correct value');
  E:=TSQLLiteralExpression(CheckClass(I.Values[1],TSQLLiteralExpression));
  L:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((2)=(L.Value), 'Correct value');
end;

procedure TTestInsertParser.TestInsertOneValue;
Var
  I : TSQLInsertStatement;
  E : TSQLLiteralExpression;
  L : TSQLIntegerLiteral;

begin
  I:=TestInsert('INSERT INTO A VALUES (1)','A');
  TestContext.AssertTrue((I.Fields)=nil, 'Have no fields');
  TestContext.AssertTrue((I.Values)<>nil, 'Have values');
  TestContext.AssertTrue((1)=(I.Values.Count), 'Have 1 value');
  E:=TSQLLiteralExpression(CheckClass(I.Values[0],TSQLLiteralExpression));
  L:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(L.Value), 'Correct value');
end;

procedure TTestInsertParser.TestInsertTwoValues;
Var
  I : TSQLInsertStatement;
  E : TSQLLiteralExpression;
  L : TSQLIntegerLiteral;

begin
  I:=TestInsert('INSERT INTO A VALUES (1,2)','A');
  TestContext.AssertTrue((I.Fields)=nil, 'Have no fields');
  TestContext.AssertTrue((I.Values)<>nil, 'Have values');
  TestContext.AssertTrue((2)=(I.Values.Count), 'Have 2 values');
  E:=TSQLLiteralExpression(CheckClass(I.Values[0],TSQLLiteralExpression));
  L:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(L.Value), 'Correct value');
  E:=TSQLLiteralExpression(CheckClass(I.Values[1],TSQLLiteralExpression));
  L:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((2)=(L.Value), 'Correct value');
end;

{ TTestSelectParser }

function TTestSelectParser.TestSelect(const ASource: String; AOptions: TParserOptions;
  AScannerOptions: TSQLScannerOptions): TSQLSelectStatement;
begin
  CreateParser(ASource,AOptions);
  Parser.Scanner.Options:=AScannerOptions;
  FToFree:=Parser.Parse;
  Result:=TSQLSelectStatement(CheckClass(FToFree,TSQLSelectStatement));
  FSelect:=Result;
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestSelectParser.TestSelectError(const ASource: String);
begin
  FErrSource:=ASource;
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestSelectParser.TestSelectFieldAsStringLiteral;

Var
  F : TSQLSelectField;
  L : TSQLStringLiteral;

begin
  TestSelect('SELECT ''B'' ''C'''); // 'B' as 'C'
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  F:=TSQLSelectField(CheckClass(Select.Fields[0],TSQLSelectField));
  TestContext.AssertTrue((F.Expression)<>nil, 'Have field expresssion,');
  L:=TSQLStringLiteral(AssertLiteralExpr('Field is a literal',F.Expression,TSQLStringLiteral));
  TestContext.AssertTrue(('B')=(L.Value), 'Field literal is B');
  TestContext.AssertTrue(('C')=(F.AliasName.Name), 'Field alias is C');
  TestContext.AssertTrue((0)=(Select.Tables.Count), 'No table');
end;

procedure TTestSelectParser.TestSelectFieldWithSchema;

Var
  Expr: TSQLIdentifierExpression;

begin
  TestSelect('SELECT S.A.B,C FROM S.A');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  AssertField(Select.Fields[0],'B');
  Expr := ((Select.Fields[0] as TSQLSelectField).Expression as TSQLIdentifierExpression);
  TestContext.AssertTrue((3)=(Expr.IdentifierPath.Count), 'Field[0] path has 3 identifiers');
  TestContext.AssertTrue(('S')=(Expr.IdentifierPath[0].Name), 'Field[0] schema is S');
  TestContext.AssertTrue(('A')=(Expr.IdentifierPath[1].Name), 'Field[0] table is A');
  AssertField(Select.Fields[1],'C');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A','');
  TestContext.AssertTrue((2)=((Select.Tables[0] as TSQLSimpleTableReference).ObjectNamePath.Count), 'Table path has 2 objects');
  TestContext.AssertTrue(('S')=((Select.Tables[0] as TSQLSimpleTableReference).ObjectNamePath[0].Name), 'Schema name = S');
end;

procedure TTestSelectParser.TestSelectFirst;
begin
  // FireBird
  TestSelect('SELECT FIRST 100 A FROM B');
  TestContext.AssertTrue((Ord(lsFireBird))=(Ord(Select.Limit.Style)), 'Limit style');
  TestContext.AssertTrue((100)=(Select.Limit.First), 'Limit FIRST 100');
end;

procedure TTestSelectParser.TestSelectFirstSkip;
begin
  // FireBird
  TestSelect('SELECT FIRST 100 SKIP 200 A FROM B');
  TestContext.AssertTrue((Ord(lsFireBird))=(Ord(Select.Limit.Style)), 'Limit style');
  TestContext.AssertTrue((100)=(Select.Limit.First), 'Limit FIRST 100');
  TestContext.AssertTrue((200)=(Select.Limit.Skip), 'Limit SKIP 200');
end;

procedure TTestSelectParser.TestSelectLimit;
begin
  // MySQL&Postgres
  TestSelect('SELECT A FROM B LIMIT 100');
  TestContext.AssertTrue((Ord(lsPostgres))=(Ord(Select.Limit.Style)), 'Limit style');
  TestContext.AssertTrue((100)=(Select.Limit.RowCount), 'Limit RowCount 100');
end;

procedure TTestSelectParser.TestSelectLimitAll;
begin
  // Postgres
  TestSelect('SELECT A FROM B LIMIT ALL');
  TestContext.AssertTrue((Ord(lsPostgres))=(Ord(Select.Limit.Style)), 'Limit style');
  TestContext.AssertTrue((-1)=(Select.Limit.RowCount), 'Limit RowCount -1');
end;

procedure TTestSelectParser.TestSelectLimitAllOffset;
begin
  // Postgres
  TestSelect('SELECT A FROM B LIMIT ALL OFFSET 200');
  TestContext.AssertTrue((Ord(lsPostgres))=(Ord(Select.Limit.Style)), 'Limit style');
  TestContext.AssertTrue((200)=(Select.Limit.Offset), 'Limit Offset 200');
end;

procedure TTestSelectParser.TestSelectLimitOffset1;
begin
  // MySQL
  TestSelect('SELECT A FROM B LIMIT 200, 100');
  TestContext.AssertTrue((Ord(lsPostgres))=(Ord(Select.Limit.Style)), 'Limit style');
  TestContext.AssertTrue((100)=(Select.Limit.RowCount), 'Limit RowCount 100');
  TestContext.AssertTrue((200)=(Select.Limit.Offset), 'Limit Offset 200');
end;

procedure TTestSelectParser.TestSelectLimitOffset2;
begin
  // MySQL&Postgres
  TestSelect('SELECT A FROM B LIMIT 100 OFFSET 200');
  TestContext.AssertTrue((Ord(lsPostgres))=(Ord(Select.Limit.Style)), 'Limit style');
  TestContext.AssertTrue((100)=(Select.Limit.RowCount), 'Limit RowCount 100');
  TestContext.AssertTrue((200)=(Select.Limit.Offset), 'Limit Offset 200');
end;

procedure TTestSelectParser.TestSelectOffset;
begin
  // Postgres
  TestSelect('SELECT A FROM B OFFSET 200');
  TestContext.AssertTrue((Ord(lsPostgres))=(Ord(Select.Limit.Style)), 'Limit style');
  TestContext.AssertTrue((200)=(Select.Limit.Offset), 'Limit Offset 200');
end;

procedure TTestSelectParser.TestSelectOneFieldOneTable;
begin
  TestSelect('SELECT B FROM A');
  TestContext.AssertTrue((Select.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  AssertField(Select.Fields[0],'B');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
end;

procedure TTestSelectParser.TestSelectOneFieldOneTableTransaction;
begin
  TestSelect('SELECT TRANSACTION C B FROM A');
  AssertIdentifierName('Correct transaction name','C',Select.TransactionName);
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  AssertField(Select.Fields[0],'B');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
end;

procedure TTestSelectParser.TestSelectOneArrayFieldOneTable;
Var
  E : TSQLIdentifierExpression;
begin
  TestSelect('SELECT B[1] FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  AssertField(Select.Fields[0],'B');
  E:=TSQLIdentifierExpression(CheckClass(TSQLSelectField(Select.Fields[0]).Expression,TSQLIdentifierExpression));
  TestContext.AssertTrue((1)=(E.ElementIndex), 'Element 1 in array ');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
end;

procedure TTestSelectParser.TestSelectTwoFieldsOneTable;
begin
  TestSelect('SELECT B,_C FROM A');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  AssertField(Select.Fields[0],'B');
  AssertField(Select.Fields[1],'_C');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
end;

procedure TTestSelectParser.TestSelectOneFieldAliasOneTable;

begin
  TestSelect('SELECT B AS C FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  AssertField(Select.Fields[0],'B','C');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
end;

procedure TTestSelectParser.TestSelectTwoFieldAliasesOneTable;
begin
  TestSelect('SELECT B AS D,C AS E FROM A');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  AssertField(Select.Fields[0],'B','D');
  AssertField(Select.Fields[1],'C','E');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
end;

procedure TTestSelectParser.TestSelectOneTableFieldOneTable;

Var
  Expr: TSQLIdentifierExpression;

begin
  TestSelect('SELECT A.B FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  // Field supports linking/referring to a table
  AssertField(Select.Fields[0],'B');
  Expr := ((Select.Fields[0] as TSQLSelectField).Expression as TSQLIdentifierExpression);
  TestContext.AssertTrue((2)=(Expr.IdentifierPath.Count), 'Field has explicit table');
  TestContext.AssertTrue(('A')=(Expr.IdentifierPath[0].Name), 'Field has explicit table named A');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
end;

procedure TTestSelectParser.TestSelectTableWithSchema;
begin
  TestSelect('SELECT B,C FROM S.A');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  AssertField(Select.Fields[0],'B');
  AssertField(Select.Fields[1],'C');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A','');
  TestContext.AssertTrue((2)=((Select.Tables[0] as TSQLSimpleTableReference).ObjectNamePath.Count), 'Table path has 2 objects');
  TestContext.AssertTrue(('S')=((Select.Tables[0] as TSQLSimpleTableReference).ObjectNamePath[0].Name), 'Schema name = S');
end;

procedure TTestSelectParser.TestSelectTop;
begin
  // MSSQL
  TestSelect('SELECT TOP 100 A FROM B');
  TestContext.AssertTrue((Ord(lsMSSQL))=(Ord(Select.Limit.Style)), 'Limit style');
  TestContext.AssertTrue((100)=(Select.Limit.Top), 'Limit TOP 100');
end;

procedure TTestSelectParser.TestSelectOneDistinctFieldOneTable;
begin
  TestSelect('SELECT DISTINCT B FROM A');
  TestContext.AssertTrue((True)=(Select.Distinct), 'DISTINCT Query');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  AssertField(Select.Fields[0],'B');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
end;

procedure TTestSelectParser.TestSelectOneAllFieldOneTable;
begin
  TestSelect('SELECT ALL B FROM A');
  TestContext.AssertTrue((True)=(Select.All), 'ALL Query');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  AssertField(Select.Fields[0],'B');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
end;

procedure TTestSelectParser.TestSelectAsteriskOneTable;
begin
  TestSelect('SELECT * FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  CheckClass(Select.Fields[0],TSQLSelectAsterisk);
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
end;

procedure TTestSelectParser.TestSelectAsteriskWithPath;
begin
  TestSelect('SELECT A.* FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  CheckClass(Select.Fields[0],TSQLSelectAsterisk);
  TestContext.AssertTrue((1)=(TSQLSelectAsterisk(Select.Fields[0]).Expression.IdentifierPath.Count), 'Path count = 1');
  TestContext.AssertTrue(('A')=(TSQLSelectAsterisk(Select.Fields[0]).Expression.IdentifierPath[0].Name), 'Path table = A');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
end;

procedure TTestSelectParser.TestSelectDistinctAsteriskOneTable;
begin
  TestSelect('SELECT DISTINCT * FROM A');
  TestContext.AssertTrue((True)=(Select.Distinct), 'DISTINCT Query');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  CheckClass(Select.Fields[0],TSQLSelectAsterisk);
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
end;

procedure TTestSelectParser.TestSelectOneFieldOneTableAlias;

Var
  Expr: TSQLIdentifierExpression;

begin
  TestSelect('SELECT C.B FROM A C');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  AssertField(Select.Fields[0],'B');
  Expr := ((Select.Fields[0] as TSQLSelectField).Expression as TSQLIdentifierExpression);
  TestContext.AssertTrue((2)=(Expr.IdentifierPath.Count), 'Field has explicit table');
  TestContext.AssertTrue(('C')=(Expr.IdentifierPath[0].Name), 'Field has explicit table named C');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
end;

procedure TTestSelectParser.TestSelectOneFieldOneTableAsAlias;

Var
  Expr: TSQLIdentifierExpression;

begin
  TestSelect('SELECT C.B FROM A AS C');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  AssertField(Select.Fields[0],'B');
  Expr := ((Select.Fields[0] as TSQLSelectField).Expression as TSQLIdentifierExpression);
  TestContext.AssertTrue((2)=(Expr.IdentifierPath.Count), 'Field has explicit table');
  TestContext.AssertTrue(('C')=(Expr.IdentifierPath[0].Name), 'Field has explicit table named C');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
end;

procedure TTestSelectParser.TestSelectTwoFieldsTwoTables;
begin
  TestSelect('SELECT B,C FROM A,D');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  AssertField(Select.Fields[0],'B');
  AssertField(Select.Fields[1],'C');
  TestContext.AssertTrue((2)=(Select.Tables.Count), 'Two table');
  AssertTable(Select.Tables[0],'A');
  AssertTable(Select.Tables[1],'D');
end;

procedure TTestSelectParser.TestSelectTwoFieldsTwoTablesJoin;

Var
  J : TSQLJoinTableReference;

begin
  TestSelect('SELECT B,C FROM A JOIN D ON E=F');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  AssertField(Select.Fields[0],'B');
  AssertField(Select.Fields[1],'C');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  J:=AssertJoin(Select.Tables[0],'A','D',jtNone);
  AssertJoinOn(J.JoinClause,'E','F',boEq);
end;

procedure TTestSelectParser.TestSourcePosition;
begin
  TestSelect('SELECT X FROM ABC ORDER BY Y');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  TestContext.AssertTrue((1)=(Select.Tables.SourceLine), 'FROM source line = 1');
  TestContext.AssertTrue((10)=(Select.Tables.SourcePos), 'FROM source position = 10');
  TestContext.AssertTrue((1)=(Select.Orderby.SourceLine), 'ORDER BY source line = 1');
  TestContext.AssertTrue((19)=(Select.Orderby.SourcePos), 'ORDER BY source position = 19');
  TestContext.AssertTrue((1)=(Select.Tables[0].SourceLine), 'Table source line = 1');
  TestContext.AssertTrue((15)=(Select.Tables[0].SourcePos), 'Table source position = 15');

  TestSelect('SELECT X'+sLineBreak+'FROM ABC'+sLineBreak+'ORDER BY Y');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  TestContext.AssertTrue((2)=(Select.Tables.SourceLine), 'FROM source line = 2');
  TestContext.AssertTrue((1)=(Select.Tables.SourcePos), 'FROM source position = 1');
  TestContext.AssertTrue((3)=(Select.Orderby.SourceLine), 'ORDER BY source line = 3');
  TestContext.AssertTrue((1)=(Select.Orderby.SourcePos), 'ORDER BY source position = 1');
  TestContext.AssertTrue((2)=(Select.Tables[0].SourceLine), 'Table source line = 2');
  TestContext.AssertTrue((6)=(Select.Tables[0].SourcePos), 'Table source position = 6');
end;

procedure TTestSelectParser.TestForUpdate;
begin
  TestSelect('SELECT B FROM A FOR UPDATE');
  TestContext.AssertTrue((Select.ForUpdate<>nil)=(true), 'FOR UPDATE');
  TestContext.AssertTrue((Select.ForUpdate.Count)=(0), 'FOR UPDATE list count');
end;

procedure TTestSelectParser.TestForUpdateNowait;
begin
  TestSelect('SELECT B FROM A FOR UPDATE NOWAIT');
  TestContext.AssertTrue((Select.ForUpdate<>nil)=(true), 'FOR UPDATE');
  TestContext.AssertTrue((Select.ForUpdate.Count)=(0), 'FOR UPDATE list count');
  TestContext.AssertTrue((Select.ForUpdateNoWait)=(true), 'FOR UPDATE');
end;

procedure TTestSelectParser.TestForUpdateOf;
begin
  TestSelect('SELECT * FROM A FOR UPDATE OF B,C');
  TestContext.AssertTrue((Select.ForUpdate<>nil)=(true), 'FOR UPDATE');
  TestContext.AssertTrue((Select.ForUpdate.Count)=(2), 'FOR UPDATE list count');
  AssertIdentifierName('FOR UPDATE[0]','B',Select.ForUpdate[0]);
  AssertIdentifierName('FOR UPDATE[1]','C',Select.ForUpdate[1]);
end;

procedure TTestSelectParser.TestWithLock;
begin
  TestSelect('SELECT * FROM DOCUMENT WITH LOCK');
  TestContext.AssertTrue((Select.WithLock)=(true), 'WITH LOCK');
end;

procedure TTestSelectParser.TestSelectTwoFieldsTwoInnerTablesJoin;
Var
  J : TSQLJoinTableReference;

begin
  TestSelect('SELECT B,C FROM A INNER JOIN D ON E=F');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  AssertField(Select.Fields[0],'B');
  AssertField(Select.Fields[1],'C');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  J:=AssertJoin(Select.Tables[0],'A','D',jtInner);
  AssertJoinOn(J.JoinClause,'E','F',boEq);
end;

procedure TTestSelectParser.TestSelectTwoFieldsTwoFullOuterTablesJoin;
Var
  J : TSQLJoinTableReference;

begin
  TestSelect('SELECT B,C FROM A FULL OUTER JOIN D ON E=F');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  AssertField(Select.Fields[0],'B');
  AssertField(Select.Fields[1],'C');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  J:=AssertJoin(Select.Tables[0],'A','D',jtFullOuter);
  AssertJoinOn(J.JoinClause,'E','F',boEq);
end;

procedure TTestSelectParser.TestSelectTwoFieldsTwoFullTablesJoin;
Var
  J : TSQLJoinTableReference;

begin
  TestSelect('SELECT B,C FROM A FULL JOIN D ON E=F');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  AssertField(Select.Fields[0],'B');
  AssertField(Select.Fields[1],'C');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  J:=AssertJoin(Select.Tables[0],'A','D',jtFullOuter);
  AssertJoinOn(J.JoinClause,'E','F',boEq);
end;

procedure TTestSelectParser.TestSelectTwoFieldsTwoLeftTablesJoin;
Var
  J : TSQLJoinTableReference;

begin
  TestSelect('SELECT B,C FROM A LEFT JOIN D ON E=F');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  AssertField(Select.Fields[0],'B');
  AssertField(Select.Fields[1],'C');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  J:=AssertJoin(Select.Tables[0],'A','D',jtLeft);
  AssertJoinOn(J.JoinClause,'E','F',boEq);
end;

procedure TTestSelectParser.TestSelectTwoFieldsTwoRightTablesJoin;
Var
  J : TSQLJoinTableReference;

begin
  TestSelect('SELECT B,C FROM A RIGHT JOIN D ON E=F');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  AssertField(Select.Fields[0],'B');
  AssertField(Select.Fields[1],'C');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  J:=AssertJoin(Select.Tables[0],'A','D',jtRight);
  AssertJoinOn(J.JoinClause,'E','F',boEq);
end;

procedure TTestSelectParser.TestSelectTwoFieldsThreeTablesJoin;

Var
  J : TSQLJoinTableReference;

begin
  TestSelect('SELECT B,C FROM A JOIN D ON E=F JOIN G ON (H=I)');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  AssertField(Select.Fields[0],'B');
  AssertField(Select.Fields[1],'C');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  j:=AssertJoin(Select.Tables[0],'','G',jtNone);
  AssertJoinOn(J.JoinClause,'H','I',boEq);
  J:=AssertJoin(J.Left,'A','D',jtNone);
  AssertJoinOn(J.JoinClause,'E','F',boEq);
end;

procedure TTestSelectParser.TestSelectTwoFieldsBracketThreeTablesJoin;

Var
  J : TSQLJoinTableReference;

begin
  TestSelect('SELECT B,C FROM (A JOIN D ON E=F) JOIN G ON (H=I)');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  AssertField(Select.Fields[0],'B');
  AssertField(Select.Fields[1],'C');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  j:=AssertJoin(Select.Tables[0],'','G',jtNone);
  AssertJoinOn(J.JoinClause,'H','I',boEq);
  J:=AssertJoin(J.Left,'A','D',jtNone);
  AssertJoinOn(J.JoinClause,'E','F',boEq);
end;

procedure TTestSelectParser.TestSelectTwoFieldsThreeBracketTablesJoin;
Var
  J : TSQLJoinTableReference;

begin
  TestSelect('SELECT B,C FROM A JOIN (D JOIN G ON E=F)  ON (H=I)');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  AssertField(Select.Fields[0],'B');
  AssertField(Select.Fields[1],'C');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  j:=AssertJoin(Select.Tables[0],'A','',jtNone);
  AssertJoinOn(J.JoinClause,'H','I',boEq);
  j:=AssertJoin(J.Right,'D','G',jtNone);
  AssertJoinOn(J.JoinClause,'E','F',boEq);
end;

procedure TTestSelectParser.TestAggregateCount;

begin
  TestSelect('SELECT COUNT(B) FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  AssertAggregate(Select.Fields[0],afCount,'B',aoNone,'');
end;

procedure TTestSelectParser.TestAggregateCountAsterisk;

begin
  TestSelect('SELECT COUNT(*) FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  AssertAggregate(Select.Fields[0],afCount,'',aoAsterisk,'');
end;

procedure TTestSelectParser.TestAggregateCountAll;
begin
  TestSelect('SELECT COUNT(ALL B) FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  AssertAggregate(Select.Fields[0],afCount,'B',aoAll,'');
end;

procedure TTestSelectParser.TestAggregateCountDistinct;
begin
  TestSelect('SELECT COUNT(DISTINCT B) FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  AssertAggregate(Select.Fields[0],afCount,'B',aoDistinct,'');
end;

procedure TTestSelectParser.TestAggregateMax;

begin
  TestSelect('SELECT MAX(B) FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  AssertAggregate(Select.Fields[0],afMax,'B',aoNone,'');
end;

procedure TTestSelectParser.TestAggregateMaxAsterisk;

begin
  TestSelectError('SELECT Max(*) FROM A');
end;

procedure TTestSelectParser.TestAggregateMaxAll;
begin
  TestSelect('SELECT MAX(ALL B) FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  AssertAggregate(Select.Fields[0],afMax,'B',aoAll,'');
end;

procedure TTestSelectParser.TestAggregateMaxDistinct;
begin
  TestSelect('SELECT MAX(DISTINCT B) FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  AssertAggregate(Select.Fields[0],afMax,'B',aoDistinct,'');
end;

procedure TTestSelectParser.TestAggregateMin;

begin
  TestSelect('SELECT Min(B) FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  AssertAggregate(Select.Fields[0],afMin,'B',aoNone,'');
end;

procedure TTestSelectParser.TestAggregateMinAsterisk;

begin
  TestSelectError('SELECT Min(*) FROM A');
end;

procedure TTestSelectParser.TestAggregateMinAll;
begin
  TestSelect('SELECT Min(ALL B) FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  AssertAggregate(Select.Fields[0],afMin,'B',aoAll,'');
end;

procedure TTestSelectParser.TestAggregateMinDistinct;
begin
  TestSelect('SELECT Min(DISTINCT B) FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  AssertAggregate(Select.Fields[0],afMin,'B',aoDistinct,'');
end;

procedure TTestSelectParser.TestAggregateSum;

begin
  TestSelect('SELECT Sum(B) FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  AssertAggregate(Select.Fields[0],afSum,'B',aoNone,'');
end;

procedure TTestSelectParser.TestAggregateSumAsterisk;

begin
  TestSelectError('SELECT Sum(*) FROM A');
end;

procedure TTestSelectParser.TestAggregateSumAll;
begin
  TestSelect('SELECT Sum(ALL B) FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  AssertAggregate(Select.Fields[0],afSum,'B',aoAll,'');
end;

procedure TTestSelectParser.TestAggregateSumDistinct;
begin
  TestSelect('SELECT Sum(DISTINCT B) FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  AssertAggregate(Select.Fields[0],afSum,'B',aoDistinct,'');
end;

procedure TTestSelectParser.TestAggregateAvg;

begin
  TestSelect('SELECT Avg(B) FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  AssertAggregate(Select.Fields[0],afAvg,'B',aoNone,'');
end;

procedure TTestSelectParser.TestAggregateAvgAsterisk;

begin
  TestSelectError('SELECT Avg(*) FROM A');
end;

procedure TTestSelectParser.TestAggregateAvgAll;
begin
  TestSelect('SELECT Avg(ALL B) FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  AssertAggregate(Select.Fields[0],afAvg,'B',aoAll,'');
end;

procedure TTestSelectParser.TestAggregateAvgDistinct;
begin
  TestSelect('SELECT Avg(DISTINCT B) FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  AssertAggregate(Select.Fields[0],afAvg,'B',aoDistinct,'');
end;

procedure TTestSelectParser.TestUpperConst;

Var
  E : TSQLFunctionCallExpression;
  L : TSQLLiteralExpression;
  S : TSQLStringLiteral;

begin
  TestSelect('SELECT UPPER(''a'') FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  CheckClass(Select.Fields[0],TSQLSelectField);
  E:=TSQLFunctionCallExpression(CheckClass(TSQLSelectField(Select.Fields[0]).Expression,TSQLFunctionCallExpression));
  TestContext.AssertTrue(('UPPER')=(E.Identifier), 'UPPER function name');
  TestContext.AssertTrue((1)=(E.Arguments.Count), 'One function element');
  L:=TSQLLiteralExpression(CheckClass(E.Arguments[0],TSQLLiteralExpression));
  S:=TSQLStringLiteral(CheckClass(L.Literal,TSQLStringLiteral));
  TestContext.AssertTrue(('a')=(S.Value), 'Correct constant');
end;

procedure TTestSelectParser.TestUpperError;

begin
  TestSelectError('SELECT UPPER(''A'',''B'') FROM C');
end;

procedure TTestSelectParser.TestGenID;
Var
  E : TSQLGenIDExpression;
  L : TSQLLiteralExpression;
  S : TSQLIntegerLiteral;

begin
  TestSelect('SELECT GEN_ID(GEN_B,1) FROM RDB$DATABASE');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'RDB$DATABASE');
  CheckClass(Select.Fields[0],TSQLSelectField);
  E:=TSQLGenIDExpression(CheckClass(TSQLSelectField(Select.Fields[0]).Expression,TSQLGenIDExpression));
  AssertIdentifierName('GenID generator function name','GEN_B',E.Generator);
  L:=TSQLLiteralExpression(CheckClass(E.Value,TSQLLiteralExpression));
  S:=TSQLIntegerLiteral(CheckClass(L.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(S.Value), 'Correct constant');
end;

procedure TTestSelectParser.TestGenIDError1;
begin
  TestSelectError('SELECT GEN_ID(''GEN_B'',1) FROM RDB$DATABASE');
end;

procedure TTestSelectParser.TestGenIDError2;
begin
  TestSelectError('SELECT GEN_ID(''GEN_B'') FROM RDB$DATABASE');
end;

procedure TTestSelectParser.TestCastSimple;
var
  C : TSQLCastExpression;
  L : TSQLLiteralExpression;
  S : TSQLIntegerLiteral;

begin
  TestSelect('SELECT CAST(1 AS VARCHAR(5)) FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  CheckClass(Select.Fields[0],TSQLSelectField);
  C:=TSQLCastExpression(CheckClass(TSQLSelectField(Select.Fields[0]).Expression,TSQLCastExpression));
  L:=TSQLLiteralExpression(CheckClass(C.Value,TSQLLiteralExpression));
  S:=TSQLIntegerLiteral(CheckClass(L.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(S.Value), 'Correct constant');
  AssertTypeDefaults(C.NewType,5);
  TestContext.AssertTrue((sdtVarChar)=(C.NewType.DataType), 'Correct type');
end;

procedure TTestSelectParser.DoExtractSimple(Expected: TSQLExtractElement);

var
  E : TSQLExtractExpression;
  I : TSQLIdentifierExpression;

begin
  TestSelect('SELECT EXTRACT('+ExtractElementNames[Expected]+' FROM B) FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  CheckClass(Select.Fields[0],TSQLSelectField);
  E:=TSQLExtractExpression(CheckClass(TSQLSelectField(Select.Fields[0]).Expression,TSQLExtractExpression));
  I:=TSQLIdentifierExpression(CheckClass(E.Value,TSQLIdentifierExpression));
  AssertIdentifierName('Correct field','B',I.Identifier);
  FreeAndNil(FParser);
  FreeAndNil(FSource);
  FreeAndNil(FToFree);
end;


procedure TTestSelectParser.TestExtractSimple;
Var
  E : TSQLExtractElement;
begin
  For E:=Low(TSQLExtractElement) to High(TSQLExtractElement) do
    DoExtractSimple(E);
end;

procedure TTestSelectParser.TestFunctionWithPath;

Var
  E : TSQLFunctionCallExpression;
  L : TSQLLiteralExpression;
  S : TSQLStringLiteral;
  I : TSQLIntegerLiteral;

begin
  TestSelect('SELECT [dbo].[myFunc] (''abc'', 1) FROM A', [], [soSquareBracketsIdentifier]);
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  CheckClass(Select.Fields[0],TSQLSelectField);
  E:=TSQLFunctionCallExpression(CheckClass(TSQLSelectField(Select.Fields[0]).Expression,TSQLFunctionCallExpression));
  TestContext.AssertTrue((2)=(E.IdentifierPath.Count), 'Function two identifiers');
  TestContext.AssertTrue(('dbo')=(E.IdentifierPath[0].Name), 'dbo function first identifier');
  TestContext.AssertTrue(('myFunc')=(E.IdentifierPath[1].Name), 'myFunc function second identifier');
  TestContext.AssertTrue((2)=(E.Arguments.Count), 'Two function elements');
  L:=TSQLLiteralExpression(CheckClass(E.Arguments[0],TSQLLiteralExpression));
  S:=TSQLStringLiteral(CheckClass(L.Literal,TSQLStringLiteral));
  TestContext.AssertTrue(('abc')=(S.Value), 'Correct string constant');
  L:=TSQLLiteralExpression(CheckClass(E.Arguments[1],TSQLLiteralExpression));
  I:=TSQLIntegerLiteral(CheckClass(L.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(I.Value), 'Correct integer constant');
end;

procedure TTestSelectParser.TestOrderByOneField;

begin
  TestSelect('SELECT B FROM A ORDER BY C');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertField(Select.Fields[0],'B');
  AssertTable(Select.Tables[0],'A');
  TestContext.AssertTrue((1)=(Select.Orderby.Count), 'One order by field');
  AssertOrderBy(Select.OrderBy[0],'C',0,obAscending);
end;

procedure TTestSelectParser.TestOrderByTwoFields;

begin
  TestSelect('SELECT B FROM A ORDER BY C,D');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertField(Select.Fields[0],'B');
  AssertTable(Select.Tables[0],'A');
  TestContext.AssertTrue((2)=(Select.Orderby.Count), 'Two order by fields');
  AssertOrderBy(Select.OrderBy[0],'C',0,obAscending);
  AssertOrderBy(Select.OrderBy[1],'D',0,obAscending);
end;

procedure TTestSelectParser.TestOrderByThreeFields;
begin
  TestSelect('SELECT B FROM A ORDER BY C,D,E');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertField(Select.Fields[0],'B');
  AssertTable(Select.Tables[0],'A');
  TestContext.AssertTrue((3)=(Select.Orderby.Count), 'Three order by fields');
  AssertOrderBy(Select.OrderBy[0],'C',0,obAscending);
  AssertOrderBy(Select.OrderBy[1],'D',0,obAscending);
  AssertOrderBy(Select.OrderBy[2],'E',0,obAscending);
end;

procedure TTestSelectParser.TestOrderByOneDescField;

begin
  TestSelect('SELECT B FROM A ORDER BY C DESC');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertField(Select.Fields[0],'B');
  AssertTable(Select.Tables[0],'A');
  TestContext.AssertTrue((1)=(Select.Orderby.Count), 'One order by field');
  AssertOrderBy(Select.OrderBy[0],'C',0,obDescending);
end;

procedure TTestSelectParser.TestOrderByTwoDescFields;

begin
  TestSelect('SELECT B FROM A ORDER BY C DESC, D DESCENDING');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertField(Select.Fields[0],'B');
  AssertTable(Select.Tables[0],'A');
  TestContext.AssertTrue((2)=(Select.Orderby.Count), 'Two order by fields');
  AssertOrderBy(Select.OrderBy[0],'C',0,obDescending);
  AssertOrderBy(Select.OrderBy[1],'D',0,obDescending);
end;

procedure TTestSelectParser.TestOrderByThreeDescFields;
begin
  TestSelect('SELECT B FROM A ORDER BY C DESC,D DESCENDING, E DESC');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertField(Select.Fields[0],'B');
  AssertTable(Select.Tables[0],'A');
  TestContext.AssertTrue((3)=(Select.Orderby.Count), 'Three order by fields');
  AssertOrderBy(Select.OrderBy[0],'C',0,obDescending);
  AssertOrderBy(Select.OrderBy[1],'D',0,obDescending);
  AssertOrderBy(Select.OrderBy[2],'E',0,obDescending);
end;

procedure TTestSelectParser.TestOrderByOneTableField;

begin
  TestSelect('SELECT B FROM A ORDER BY C.D');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertField(Select.Fields[0],'B');
  AssertTable(Select.Tables[0],'A');
  TestContext.AssertTrue((1)=(Select.Orderby.Count), 'One order by field');
  // Field does not support linking/referring to a table, so the field name is
  // assigned as C.D (instead of D with a <link to table C>)
  AssertOrderBy(Select.OrderBy[0],'C.D',0,obAscending);
end;


procedure TTestSelectParser.TestOrderByOneColumn;
begin
  TestSelect('SELECT B FROM A ORDER BY 1');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertField(Select.Fields[0],'B');
  AssertTable(Select.Tables[0],'A');
  TestContext.AssertTrue((1)=(Select.Orderby.Count), 'One order by field');
  AssertOrderBy(Select.OrderBy[0],'',1,obAscending);
end;

procedure TTestSelectParser.TestOrderByTwoColumns;

begin
  TestSelect('SELECT B,C FROM A ORDER BY 1,2');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertField(Select.Fields[0],'B');
  AssertField(Select.Fields[1],'C');
  AssertTable(Select.Tables[0],'A');
  TestContext.AssertTrue((2)=(Select.Orderby.Count), 'Two order by fields');
  AssertOrderBy(Select.OrderBy[0],'',1,obAscending);
  AssertOrderBy(Select.OrderBy[1],'',2,obAscending);
end;

procedure TTestSelectParser.TestOrderByTwoColumnsDesc;

begin
  TestSelect('SELECT B,C FROM A ORDER BY 1 DESC,2');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertField(Select.Fields[0],'B');
  AssertField(Select.Fields[1],'C');
  AssertTable(Select.Tables[0],'A');
  TestContext.AssertTrue((2)=(Select.Orderby.Count), 'Two order by fields');
  AssertOrderBy(Select.OrderBy[0],'',1,obDescending);
  AssertOrderBy(Select.OrderBy[1],'',2,obAscending);
end;

procedure TTestSelectParser.TestOrderByCollate;

Var
  O : TSQLOrderByElement;

begin
  TestSelect('SELECT B,C FROM A ORDER BY D COLLATE E');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertField(Select.Fields[0],'B');
  AssertField(Select.Fields[1],'C');
  AssertTable(Select.Tables[0],'A');
  TestContext.AssertTrue((1)=(Select.Orderby.Count), 'One order by fields');
  O:=AssertOrderBy(Select.OrderBy[0],'D',0,obAscending);
  AssertIdentifierName('Correct collation','E',O.Collation);
end;

procedure TTestSelectParser.TestOrderByCollateDesc;

Var
  O : TSQLOrderByElement;

begin
  TestSelect('SELECT B,C FROM A ORDER BY D COLLATE E');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertField(Select.Fields[0],'B');
  AssertField(Select.Fields[1],'C');
  AssertTable(Select.Tables[0],'A');
  TestContext.AssertTrue((1)=(Select.Orderby.Count), 'One order by fields');
  O:=AssertOrderBy(Select.OrderBy[0],'D',0,obAscending);
  AssertIdentifierName('Correct collation','E',O.Collation);
end;

procedure TTestSelectParser.TestOrderByCollateDescTwoFields;

Var
  O : TSQLOrderByElement;

begin
  TestSelect('SELECT B,C FROM A ORDER BY D COLLATE E DESC,F COLLATE E');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertField(Select.Fields[0],'B');
  AssertField(Select.Fields[1],'C');
  AssertTable(Select.Tables[0],'A');
  TestContext.AssertTrue((2)=(Select.Orderby.Count), 'Two order by fields');
  O:=AssertOrderBy(Select.OrderBy[0],'D',0,obDescending);
  AssertIdentifierName('Correct collation','E',O.Collation);
  O:=AssertOrderBy(Select.OrderBy[1],'F',0,obAscending);
  AssertIdentifierName('Correct collation','E',O.Collation);
end;

procedure TTestSelectParser.TestOrderByUpper;
var
  O: TSQLOrderByElement;
begin
  TestSelect('SELECT B FROM A ORDER BY UPPER(C)');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertField(Select.Fields[0],'B');
  AssertTable(Select.Tables[0],'A');
  TestContext.AssertTrue((1)=(Select.Orderby.Count), 'One order by field');
  O:=AssertOrderBy(Select.OrderBy[0],'C',0,obAscending);
  TestContext.AssertTrue((O.Upper)=(true), 'Order by upper');
end;

procedure TTestSelectParser.TestGroupByOne;
begin
  TestSelect('SELECT B,COUNT(C) AS THECOUNT FROM A GROUP BY B');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  TestContext.AssertTrue((1)=(Select.GroupBy.Count), 'One group by field');
  AssertIdentifierName('Correct group by field','B',Select.GroupBy[0]);
  AssertField(Select.Fields[0],'B');
  AssertAggregate(Select.Fields[1],afCount,'C',aoNone,'THECOUNT');
end;

procedure TTestSelectParser.TestGroupByTwo;
begin
  TestSelect('SELECT B,C,SUM(D) AS THESUM FROM A GROUP BY B,C');
  TestContext.AssertTrue((3)=(Select.Fields.Count), 'Three fields');
  TestContext.AssertTrue((2)=(Select.GroupBy.Count), 'One group two fields');
  AssertIdentifierName('Correct first group by field','B',Select.GroupBy[0]);
  AssertIdentifierName('Correct second group by field','C',Select.GroupBy[1]);
  AssertField(Select.Fields[0],'B');
  AssertField(Select.Fields[1],'C');
  AssertAggregate(Select.Fields[2],afSum,'D',aoNone,'THESUM');
end;

procedure TTestSelectParser.TestHavingOne;

Var
  H : TSQLBinaryExpression;
  L : TSQLLiteralExpression;
  S : TSQLIntegerLiteral;

begin
  TestSelect('SELECT B,COUNT(C) AS THECOUNT FROM A GROUP BY B HAVING COUNT(C)>1');
  TestContext.AssertTrue((2)=(Select.Fields.Count), 'Two fields');
  TestContext.AssertTrue((1)=(Select.GroupBy.Count), 'One group by field');
  AssertIdentifierName('Correct group by field','B',Select.GroupBy[0]);
  AssertField(Select.Fields[0],'B');
  AssertAggregate(Select.Fields[1],afCount,'C',aoNone,'THECOUNT');
  TestContext.AssertTrue((Select.Having)<>nil, 'Have having');
  H:=TSQLBinaryExpression(CheckClass(Select.Having,TSQLBinaryExpression));
  TestContext.AssertTrue((boGT)=(H.Operation), 'Larger than');
  L:=TSQLLiteralExpression(CheckClass(H.Right,TSQLLiteralExpression));
  S:=TSQLIntegerLiteral(CheckClass(L.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(S.Value), 'One');
  AssertAggregateExpression(H.Left,afCount,'C',aoNone);
end;

procedure TTestSelectParser.TestLeft;

Var
  E : TSQLFunctionCallExpression;
  L : TSQLLiteralExpression;
  S : TSQLStringLiteral;
  I : TSQLIntegerLiteral;

begin
  TestSelect('SELECT LEFT(''abc'', 1) FROM A');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  CheckClass(Select.Fields[0],TSQLSelectField);
  E:=TSQLFunctionCallExpression(CheckClass(TSQLSelectField(Select.Fields[0]).Expression,TSQLFunctionCallExpression));
  TestContext.AssertTrue(('LEFT')=(E.Identifier), 'LEFT function name');
  TestContext.AssertTrue((2)=(E.Arguments.Count), 'Two function elements');
  L:=TSQLLiteralExpression(CheckClass(E.Arguments[0],TSQLLiteralExpression));
  S:=TSQLStringLiteral(CheckClass(L.Literal,TSQLStringLiteral));
  TestContext.AssertTrue(('abc')=(S.Value), 'Correct string constant');
  L:=TSQLLiteralExpression(CheckClass(E.Arguments[1],TSQLLiteralExpression));
  I:=TSQLIntegerLiteral(CheckClass(L.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(I.Value), 'Correct integer constant');
end;

procedure TTestSelectParser.TestNoTable;

Var
  F : TSQLSelectField;
  L : TSQLIntegerLiteral;

begin
  TestSelect('SELECT 1');
  TestContext.AssertTrue((0)=(Select.Tables.Count), '0 tables in select');
  TestContext.AssertTrue((1)=(Select.Fields.Count), '1 field in select');
  TestContext.AssertTrue((Select.Fields[0])<>nil, 'Have field');
  F:=TSQLSelectField(CheckClass(Select.Fields[0],TSQLSelectField));
  TestContext.AssertTrue((F.Expression)<>nil, 'Have field expresssion,');
  L:=TSQLIntegerLiteral(AssertLiteralExpr('Field is a literal',F.Expression,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(L.Value), 'SELECT 1');
end;

procedure TTestSelectParser.TestUnionSimple;

Var
  S : TSQLSelectStatement;

begin
  TestSelect('SELECT B FROM A UNION SELECT C FROM D');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  AssertField(Select.Fields[0],'B');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  S:=TSQLSelectStatement(CheckClass(Select.Union,TSQLSelectStatement));
  TestContext.AssertTrue((1)=(S.Fields.Count), 'One field');
  AssertField(S.Fields[0],'C');
  TestContext.AssertTrue((1)=(S.Tables.Count), 'One table');
  AssertTable(S.Tables[0],'D');
  TestContext.AssertTrue((False)=(Select.UnionAll), 'No UNION ALL : ')
end;

procedure TTestSelectParser.TestUnionSimpleAll;

Var
  S : TSQLSelectStatement;

begin
  TestSelect('SELECT B FROM A UNION ALL SELECT C FROM D');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  AssertField(Select.Fields[0],'B');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  S:=TSQLSelectStatement(CheckClass(Select.Union,TSQLSelectStatement));
  TestContext.AssertTrue((1)=(S.Fields.Count), 'One field');
  AssertField(S.Fields[0],'C');
  TestContext.AssertTrue((1)=(S.Tables.Count), 'One table');
  AssertTable(S.Tables[0],'D');
  TestContext.AssertTrue((True)=(Select.UnionAll), 'UNION ALL : ')
end;

procedure TTestSelectParser.TestUnionSimpleOrderBy;
Var
  S : TSQLSelectStatement;

begin
  TestSelect('SELECT B FROM A UNION SELECT C FROM D ORDER BY 1');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  AssertField(Select.Fields[0],'B');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  AssertOrderBy(Select.OrderBy[0],'',1,obAscending);
  S:=TSQLSelectStatement(CheckClass(Select.Union,TSQLSelectStatement));
  TestContext.AssertTrue((1)=(S.Fields.Count), 'One field');
  AssertField(S.Fields[0],'C');
  TestContext.AssertTrue((1)=(S.Tables.Count), 'One table');
  AssertTable(S.Tables[0],'D');
end;

procedure TTestSelectParser.TestUnionDouble;
Var
  S : TSQLSelectStatement;

begin
  TestSelect('SELECT B FROM A UNION SELECT C FROM D UNION SELECT E FROM F ORDER BY 1');
  TestContext.AssertTrue((1)=(Select.Fields.Count), 'One field');
  AssertField(Select.Fields[0],'B');
  TestContext.AssertTrue((1)=(Select.Tables.Count), 'One table');
  AssertTable(Select.Tables[0],'A');
  AssertOrderBy(Select.OrderBy[0],'',1,obAscending);
  S:=TSQLSelectStatement(CheckClass(Select.Union,TSQLSelectStatement));
  TestContext.AssertTrue((1)=(S.Fields.Count), 'One field');
  AssertField(S.Fields[0],'C');
  TestContext.AssertTrue((1)=(S.Tables.Count), 'One table');
  AssertTable(S.Tables[0],'D');
  S:=TSQLSelectStatement(CheckClass(S.Union,TSQLSelectStatement));
  TestContext.AssertTrue((1)=(S.Fields.Count), 'One field');
  AssertField(S.Fields[0],'E');
  TestContext.AssertTrue((1)=(S.Tables.Count), 'One table');
  AssertTable(S.Tables[0],'F');
end;

procedure TTestSelectParser.TestUnionError1;

begin
  TestSelectError('SELECT B FROM A ORDER BY B UNION SELECT C FROM D');
end;

procedure TTestSelectParser.TestUnionError2;
begin
  TestSelectError('SELECT B FROM A UNION SELECT C,E FROM D');
end;

procedure TTestSelectParser.TestPlanOrderNatural;

Var
  E : TSQLSelectPlanExpr;
  N : TSQLSelectNaturalPLan;

begin
  TestSelect('SELECT A FROM B PLAN SORT (B NATURAL)');
  E:=TSQLSelectPlanExpr(CheckClass(Select.Plan,TSQLSelectPlanExpr));
  TestContext.AssertTrue((1)=(E.Items.Count), 'One plan item');
  TestContext.AssertTrue((pjtSort)=(E.JoinType), 'Correct plan type');
  N:=TSQLSelectNaturalPLan(CheckClass(E.Items[0],TSQLSelectNaturalPLan));
  AssertIdentifierName('Correct table','B',N.TableName);
end;

procedure TTestSelectParser.TestPlanOrderOrder;

Var
  E : TSQLSelectPlanExpr;
  O : TSQLSelectOrderedPLan;

begin
  TestSelect('SELECT A FROM B PLAN SORT (B ORDER C)');
  E:=TSQLSelectPlanExpr(CheckClass(Select.Plan,TSQLSelectPlanExpr));
  TestContext.AssertTrue((1)=(E.Items.Count), 'One plan item');
  TestContext.AssertTrue((pjtSort)=(E.JoinType), 'Correct plan type');
  O:=TSQLSelectOrderedPLan(CheckClass(E.Items[0],TSQLSelectOrderedPLan));
  AssertIdentifierName('Correct table','B',O.TableName);
  AssertIdentifierName('Correct table','C',O.OrderIndex);
end;

procedure TTestSelectParser.TestPlanOrderIndex1;

Var
  E : TSQLSelectPlanExpr;
  O : TSQLSelectIndexedPLan;

begin
  TestSelect('SELECT A FROM B PLAN SORT (B INDEX (C))');
  E:=TSQLSelectPlanExpr(CheckClass(Select.Plan,TSQLSelectPlanExpr));
  TestContext.AssertTrue((1)=(E.Items.Count), 'One plan item');
  TestContext.AssertTrue((pjtSort)=(E.JoinType), 'Correct plan type');
  O:=TSQLSelectIndexedPLan(CheckClass(E.Items[0],TSQLSelectIndexedPlan));
  AssertIdentifierName('Correct table','B',O.TableName);
  TestContext.AssertTrue((1)=(O.Indexes.Count), 'Correct index count');
  AssertIdentifierName('Correct table','C',O.Indexes[0]);
end;

procedure TTestSelectParser.TestPlanOrderIndex2;
Var
  E : TSQLSelectPlanExpr;
  O : TSQLSelectIndexedPLan;

begin
  TestSelect('SELECT A FROM B PLAN SORT (B INDEX (C,D))');
  E:=TSQLSelectPlanExpr(CheckClass(Select.Plan,TSQLSelectPlanExpr));
  TestContext.AssertTrue((1)=(E.Items.Count), 'One plan item');
  TestContext.AssertTrue((pjtSort)=(E.JoinType), 'Correct plan type');
  O:=TSQLSelectIndexedPLan(CheckClass(E.Items[0],TSQLSelectIndexedPlan));
  AssertIdentifierName('Correct table','B',O.TableName);
  TestContext.AssertTrue((2)=(O.Indexes.Count), 'Correct index count');
  AssertIdentifierName('Correct table','C',O.Indexes[0]);
  AssertIdentifierName('Correct table','D',O.Indexes[1]);
end;

procedure TTestSelectParser.TestPlanJoinNatural;
Var
  E : TSQLSelectPlanExpr;
  N : TSQLSelectNaturalPLan;
  O : TSQLSelectOrderedPLan;

begin
  TestSelect('SELECT A FROM B PLAN JOIN (B NATURAL, C ORDER D)');
  E:=TSQLSelectPlanExpr(CheckClass(Select.Plan,TSQLSelectPlanExpr));
  TestContext.AssertTrue((2)=(E.Items.Count), 'One plan item');
  TestContext.AssertTrue((pjtJoin)=(E.JoinType), 'Correct plan type');
  N:=TSQLSelectNaturalPLan(CheckClass(E.Items[0],TSQLSelectNaturalPlan));
  AssertIdentifierName('Correct table','B',N.TableName);
  O:=TSQLSelectOrderedPLan(CheckClass(E.Items[1],TSQLSelectOrderedPlan));
  AssertIdentifierName('Correct table','C',O.TableName);
  AssertIdentifierName('Correct index','D',O.OrderIndex);
end;

procedure TTestSelectParser.TestPlanDefaultNatural;
Var
  E : TSQLSelectPlanExpr;
  N : TSQLSelectNaturalPLan;
  O : TSQLSelectOrderedPLan;

begin
  TestSelect('SELECT A FROM B PLAN  (B NATURAL, C ORDER D)');
  E:=TSQLSelectPlanExpr(CheckClass(Select.Plan,TSQLSelectPlanExpr));
  TestContext.AssertTrue((2)=(E.Items.Count), 'One plan item');
  TestContext.AssertTrue((pjtJoin)=(E.JoinType), 'Correct plan type');
  N:=TSQLSelectNaturalPLan(CheckClass(E.Items[0],TSQLSelectNaturalPlan));
  AssertIdentifierName('Correct table','B',N.TableName);
  O:=TSQLSelectOrderedPLan(CheckClass(E.Items[1],TSQLSelectOrderedPlan));
  AssertIdentifierName('Correct table','C',O.TableName);
  AssertIdentifierName('Correct index','D',O.OrderIndex);
end;

procedure TTestSelectParser.TestPlanMergeNatural;
Var
  E : TSQLSelectPlanExpr;
  N : TSQLSelectNaturalPLan;
  O : TSQLSelectOrderedPLan;

begin
  TestSelect('SELECT A FROM B PLAN MERGE (B NATURAL, C ORDER D)');
  E:=TSQLSelectPlanExpr(CheckClass(Select.Plan,TSQLSelectPlanExpr));
  TestContext.AssertTrue((2)=(E.Items.Count), 'One plan item');
  TestContext.AssertTrue((pjtMerge)=(E.JoinType), 'Correct plan type');
  N:=TSQLSelectNaturalPLan(CheckClass(E.Items[0],TSQLSelectNaturalPlan));
  AssertIdentifierName('Correct table','B',N.TableName);
  O:=TSQLSelectOrderedPLan(CheckClass(E.Items[1],TSQLSelectOrderedPlan));
  AssertIdentifierName('Correct table','C',O.TableName);
  AssertIdentifierName('Correct index','D',O.OrderIndex);
end;

procedure TTestSelectParser.TestPlanMergeNested;
Var
  E,EN : TSQLSelectPlanExpr;
  N : TSQLSelectNaturalPLan;
  I : TSQLSelectIndexedPLan;

begin
  TestSelect('SELECT A FROM B PLAN MERGE (SORT (B NATURAL), SORT (JOIN (D NATURAL, E INDEX (F))))');
  E:=TSQLSelectPlanExpr(CheckClass(Select.Plan,TSQLSelectPlanExpr));
  TestContext.AssertTrue((2)=(E.Items.Count), 'Two plan items');
  TestContext.AssertTrue((pjtMerge)=(E.JoinType), 'Correct overall plan type');
  // SORT (B NATURAL)
  EN:=TSQLSelectPlanExpr(CheckClass(E.Items[0],TSQLSelectPlanExpr));
  TestContext.AssertTrue((pjtSort)=(EN.JoinType), 'Correct plan type Item 1');
  TestContext.AssertTrue((1)=(EN.Items.Count), 'On plan item in item 1');
  N:=TSQLSelectNaturalPLan(CheckClass(EN.Items[0],TSQLSelectNaturalPlan));
  AssertIdentifierName('Correct table','B',N.TableName);
  // SORT (JOIN (D...
  EN:=TSQLSelectPlanExpr(CheckClass(E.Items[1],TSQLSelectPlanExpr));
  TestContext.AssertTrue((pjtSort)=(EN.JoinType), 'Correct plan type item 2');
  TestContext.AssertTrue((1)=(EN.Items.Count), 'One plan item in item 2');
  // JOIN (D NATURAL, E
  E:=TSQLSelectPlanExpr(CheckClass(EN.Items[0],TSQLSelectPlanExpr));
  TestContext.AssertTrue((pjtJoin)=(E.JoinType), 'Correct plan type');
  TestContext.AssertTrue((2)=(E.Items.Count), 'Two plan items in item 2');
  N:=TSQLSelectNaturalPLan(CheckClass(E.Items[0],TSQLSelectNaturalPlan));
  AssertIdentifierName('Correct table','D',N.TableName);
  // E INDEX (F)
  I:=TSQLSelectIndexedPLan(CheckClass(E.Items[1],TSQLSelectIndexedPlan));
  AssertIdentifierName('Correct table','E',I.TableName);
  TestContext.AssertTrue((1)=(I.Indexes.Count), 'Correct index count for table E');
  AssertIdentifierName('Correct index for table E','F',I.Indexes[0]);
end;

procedure TTestSelectParser.TestSubSelect;

Var
  F : TSQLSelectField;
  E : TSQLSelectExpression;
  S : TSQLSelectStatement;

begin
  TestSelect('SELECT A,(SELECT C FROM D WHERE E=A) AS THECOUNT FROM B');
  TestContext.AssertTrue((1)=(Select.Tables.Count), '1 table in select');
  AssertTable(Select.Tables[0],'B','');
  TestContext.AssertTrue((2)=(Select.Fields.Count), '2 fields in select');
  AssertField(Select.Fields[0],'A','');
  F:=TSQLSelectField(CheckClass(Select.fields[1],TSQLSelectField));
  AssertIdentifierName('Correct alias name for subselect','THECOUNT',F.AliasName);
  E:=TSQLSelectExpression(CheckClass(F.Expression,TSQLSelectExpression));
  S:=TSQLSelectStatement(CheckClass(E.Select,TSQLSelectStatement));
  TestContext.AssertTrue((1)=(S.Fields.Count), '1 field in subselect');
  AssertField(S.Fields[0],'C','');
  TestContext.AssertTrue((1)=(S.Tables.Count), '1 table in subselect');
  AssertTable(S.Tables[0],'D','');
end;

procedure TTestSelectParser.TestWhereExists;

Var
  E : TSQLExistsExpression;
  S : TSQLSelectStatement;

begin
  TestSelect('SELECT A FROM B WHERE EXISTS (SELECT C FROM D WHERE E=A)');
  TestContext.AssertTrue((1)=(Select.Tables.Count), '1 table in select');
  AssertTable(Select.Tables[0],'B','');
  TestContext.AssertTrue((1)=(Select.Fields.Count), '1 fields in select');
  AssertField(Select.Fields[0],'A','');
  E:=TSQLExistsExpression(CheckClass(Select.Where,TSQLExistsExpression));
  S:=TSQLSelectStatement(CheckClass(E.Select,TSQLSelectStatement));
  TestContext.AssertTrue((1)=(S.Fields.Count), '1 field in subselect');
  AssertField(S.Fields[0],'C','');
  TestContext.AssertTrue((1)=(S.Tables.Count), '1 table in subselect');
  AssertTable(S.Tables[0],'D','');
end;

procedure TTestSelectParser.TestWhereSingular;

Var
  E : TSQLSingularExpression;
  S : TSQLSelectStatement;

begin
  TestSelect('SELECT A FROM B WHERE SINGULAR (SELECT C FROM D WHERE E=A)');
  TestContext.AssertTrue((1)=(Select.Tables.Count), '1 table in select');
  AssertTable(Select.Tables[0],'B','');
  TestContext.AssertTrue((1)=(Select.Fields.Count), '1 fields in select');
  AssertField(Select.Fields[0],'A','');
  E:=TSQLSingularExpression(CheckClass(Select.Where,TSQLSingularExpression));
  S:=TSQLSelectStatement(CheckClass(E.Select,TSQLSelectStatement));
  TestContext.AssertTrue((1)=(S.Fields.Count), '1 field in subselect');
  AssertField(S.Fields[0],'C','');
  TestContext.AssertTrue((1)=(S.Tables.Count), '1 table in subselect');
  AssertTable(S.Tables[0],'D','');
end;

procedure TTestSelectParser.TestWhereAll;

Var
  E : TSQLAllExpression;
  S : TSQLSelectStatement;
  B : TSQLBinaryExpression;

begin
  TestSelect('SELECT A FROM B WHERE A > ALL (SELECT C FROM D WHERE E=F)');
  TestContext.AssertTrue((1)=(Select.Tables.Count), '1 table in select');
  AssertTable(Select.Tables[0],'B','');
  TestContext.AssertTrue((1)=(Select.Fields.Count), '1 fields in select');
  AssertField(Select.Fields[0],'A','');
  B:=TSQLBinaryExpression(CheckClass(Select.Where,TSQLBinaryExpression));
  TestContext.AssertTrue((boGT)=(B.Operation), 'Correct operation');
  E:=TSQLAllExpression(CheckClass(B.right,TSQLAllExpression));
  S:=TSQLSelectStatement(CheckClass(E.Select,TSQLSelectStatement));
  TestContext.AssertTrue((1)=(S.Fields.Count), '1 field in subselect');
  AssertField(S.Fields[0],'C','');
  TestContext.AssertTrue((1)=(S.Tables.Count), '1 table in subselect');
  AssertTable(S.Tables[0],'D','');
end;

procedure TTestSelectParser.TestWhereAny;

Var
  E : TSQLANyExpression;
  S : TSQLSelectStatement;
  B : TSQLBinaryExpression;

begin
  TestSelect('SELECT A FROM B WHERE A > ANY (SELECT C FROM D WHERE E=F)');
  TestContext.AssertTrue((1)=(Select.Tables.Count), '1 table in select');
  AssertTable(Select.Tables[0],'B','');
  TestContext.AssertTrue((1)=(Select.Fields.Count), '1 fields in select');
  AssertField(Select.Fields[0],'A','');
  B:=TSQLBinaryExpression(CheckClass(Select.Where,TSQLBinaryExpression));
  TestContext.AssertTrue((boGT)=(B.Operation), 'Correct operation');
  E:=TSQLAnyExpression(CheckClass(B.right,TSQLANyExpression));
  S:=TSQLSelectStatement(CheckClass(E.Select,TSQLSelectStatement));
  TestContext.AssertTrue((1)=(S.Fields.Count), '1 field in subselect');
  AssertField(S.Fields[0],'C','');
  TestContext.AssertTrue((1)=(S.Tables.Count), '1 table in subselect');
  AssertTable(S.Tables[0],'D','');
end;

procedure TTestSelectParser.TestWhereSome;

Var
  E : TSQLSomeExpression;
  S : TSQLSelectStatement;
  B : TSQLBinaryExpression;

begin
  TestSelect('SELECT A FROM B WHERE A > SOME (SELECT C FROM D WHERE E=F)');
  TestContext.AssertTrue((1)=(Select.Tables.Count), '1 table in select');
  AssertTable(Select.Tables[0],'B','');
  TestContext.AssertTrue((1)=(Select.Fields.Count), '1 fields in select');
  AssertField(Select.Fields[0],'A','');
  B:=TSQLBinaryExpression(CheckClass(Select.Where,TSQLBinaryExpression));
  TestContext.AssertTrue((boGT)=(B.Operation), 'Correct operation');
  E:=TSQLSomeExpression(CheckClass(B.right,TSQLSomeExpression));
  S:=TSQLSelectStatement(CheckClass(E.Select,TSQLSelectStatement));
  TestContext.AssertTrue((1)=(S.Fields.Count), '1 field in subselect');
  AssertField(S.Fields[0],'C','');
  TestContext.AssertTrue((1)=(S.Tables.Count), '1 table in subselect');
  AssertTable(S.Tables[0],'D','');
end;

procedure TTestSelectParser.TestWhereInRange;
begin
  TestSelect('SELECT A FROM B WHERE A IN (4..6)');
end;

procedure TTestSelectParser.TestWhereDotFloat;
begin
  TestSelect('SELECT A FROM B WHERE (A + .3 > -.5)');
end;

procedure TTestSelectParser.TestParam;

Var
  F : TSQLSelectField;
  P : TSQLParameterExpression;

begin
  TestSelect('SELECT :A FROM B');
  TestContext.AssertTrue((1)=(Select.Tables.Count), '1 table in select');
  AssertTable(Select.Tables[0],'B','');
  TestContext.AssertTrue((1)=(Select.Fields.Count), '1 fields in select');
  TestContext.AssertTrue((Select.Fields[0])<>nil, 'Have field');
  F:=TSQLSelectField(CheckClass(Select.Fields[0],TSQLSelectField));
  TestContext.AssertTrue((F.Expression)<>nil, 'Have field expresssion,');
  P:=TSQLParameterExpression(CheckClass(F.Expression,TSQLParameterExpression));
  AssertIdentifierName('Correct parameter name','A',P.Identifier);
end;

procedure TTestSelectParser.TestParam_Underscore;
var
  F: TSQLSelectField;
  P: TSQLParameterExpression;
begin
  TestSelect('SELECT :_A FROM B');
  TestContext.AssertTrue((1)=(Select.Tables.Count), '1 table in select');
  AssertTable(Select.Tables[0],'B','');
  TestContext.AssertTrue((1)=(Select.Fields.Count), '1 fields in select');
  TestContext.AssertTrue((Select.Fields[0])<>nil, 'Have field');
  F:=TSQLSelectField(CheckClass(Select.Fields[0],TSQLSelectField));
  TestContext.AssertTrue((F.Expression)<>nil, 'Have field expresssion,');
  P:=TSQLParameterExpression(CheckClass(F.Expression,TSQLParameterExpression));
  AssertIdentifierName('Correct parameter name','_A',P.Identifier);
end;

procedure TTestSelectParser.TestParamExpr;

Var
  F : TSQLSelectField;
  P : TSQLParameterExpression;
  B : TSQLBinaryExpression;

begin
  TestSelect('SELECT :A + 1 FROM B');
  TestContext.AssertTrue((1)=(Select.Tables.Count), '1 table in select');
  AssertTable(Select.Tables[0],'B','');
  TestContext.AssertTrue((1)=(Select.Fields.Count), '1 fields in select');
  TestContext.AssertTrue((Select.Fields[0])<>nil, 'Have field');
  F:=TSQLSelectField(CheckClass(Select.Fields[0],TSQLSelectField));
  TestContext.AssertTrue((F.Expression)<>nil, 'Have field expresssion,');
  B:=TSQLBinaryExpression(CheckClass(F.Expression,TSQLBinaryExpression));
  P:=TSQLParameterExpression(CheckClass(B.Left,TSQLParameterExpression));
  AssertIdentifierName('Correct parameter name','A',P.Identifier);
end;

{ TTestRollBackParser }

function TTestRollBackParser.TestRollback(const ASource: String
  ): TSQLRollbackStatement;
begin
  CreateParser(ASource);
  FToFree:=Parser.Parse;
  Result:=TSQLRollbackStatement(CheckClass(FToFree,TSQLRollbackStatement));
  FRollback:=Result;
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestRollBackParser.TestRollbackError(const ASource: String);
begin
  FErrSource:=ASource;
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestRollBackParser.TestRollback;
begin
  TestRollBack('ROLLBACK');
  TestContext.AssertTrue((Rollback.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((False)=(Rollback.Work), 'No work');
  TestContext.AssertTrue((False)=(Rollback.Release), 'No release');
end;

procedure TTestRollBackParser.TestRollbackWork;
begin
  TestRollBack('ROLLBACK WORK');
  TestContext.AssertTrue((Rollback.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((True)=(Rollback.Work), 'work');
  TestContext.AssertTrue((False)=(Rollback.Release), 'No release');
end;

procedure TTestRollBackParser.TestRollbackRelease;
begin
  TestRollBack('ROLLBACK RELEASE');
  TestContext.AssertTrue((Rollback.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((False)=(Rollback.Work), 'no work');
  TestContext.AssertTrue((True)=(Rollback.Release), 'release');
end;

procedure TTestRollBackParser.TestRollbackWorkRelease;
begin
  TestRollBack('ROLLBACK WORK RELEASE');
  TestContext.AssertTrue((Rollback.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((True)=(Rollback.Work), 'work');
  TestContext.AssertTrue((True)=(Rollback.Release), 'release');
end;

procedure TTestRollBackParser.TestRollbackTransaction;
begin
  TestRollBack('ROLLBACK TRANSACTION T');
  AssertIdentifierName('Transaction name','T',Rollback.TransactionName);
  TestContext.AssertTrue((False)=(Rollback.Work), 'No work');
  TestContext.AssertTrue((False)=(Rollback.Release), 'No release');
end;

procedure TTestRollBackParser.TestRollbackTransactionWork;
begin
  TestRollBack('ROLLBACK TRANSACTION T WORK');
  AssertIdentifierName('Transaction name','T',Rollback.TransactionName);
  TestContext.AssertTrue((True)=(Rollback.Work), 'work');
  TestContext.AssertTrue((False)=(Rollback.Release), 'No release');
end;

procedure TTestRollBackParser.TestRollbackTransactionRelease;
begin
  TestRollBack('ROLLBACK TRANSACTION T RELEASE');
  AssertIdentifierName('Transaction name','T',Rollback.TransactionName);
  TestContext.AssertTrue((False)=(Rollback.Work), 'no work');
  TestContext.AssertTrue((True)=(Rollback.Release), 'release');
end;

procedure TTestRollBackParser.TestRollbackTransactionWorkRelease;
begin
  TestRollBack('ROLLBACK TRANSACTION T WORK RELEASE');
  AssertIdentifierName('Transaction name','T',Rollback.TransactionName);
  TestContext.AssertTrue((True)=(Rollback.Work), 'work');
  TestContext.AssertTrue((True)=(Rollback.Release), 'release');
end;
{ TTestCommitParser }

function TTestCommitParser.TestCommit(const ASource: String
  ): TSQLCommitStatement;
begin
  CreateParser(ASource);
  FToFree:=Parser.Parse;
  Result:=TSQLCommitStatement(CheckClass(FToFree,TSQLCommitStatement));
  FCommit:=Result;
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestCommitParser.TestCommitError(const ASource: String);
begin
  FErrSource:=ASource;
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestCommitParser.TestCommit;
begin
  TestCommit('Commit');
  TestContext.AssertTrue((Commit.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((False)=(Commit.Work), 'No work');
  TestContext.AssertTrue((False)=(Commit.Release), 'No release');
  TestContext.AssertTrue((False)=(Commit.Retain), 'No Retain');
end;

procedure TTestCommitParser.TestCommitWork;
begin
  TestCommit('Commit WORK');
  TestContext.AssertTrue((Commit.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((True)=(Commit.Work), 'work');
  TestContext.AssertTrue((False)=(Commit.Release), 'No release');
  TestContext.AssertTrue((False)=(Commit.Retain), 'No Retain');
end;

procedure TTestCommitParser.TestCommitRelease;
begin
  TestCommit('Commit RELEASE');
  TestContext.AssertTrue((Commit.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((False)=(Commit.Work), 'no work');
  TestContext.AssertTrue((True)=(Commit.Release), 'release');
  TestContext.AssertTrue((False)=(Commit.Retain), 'No Retain');
end;

procedure TTestCommitParser.TestCommitWorkRelease;
begin
  TestCommit('Commit WORK RELEASE');
  TestContext.AssertTrue((Commit.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((True)=(Commit.Work), 'work');
  TestContext.AssertTrue((True)=(Commit.Release), 'release');
  TestContext.AssertTrue((False)=(Commit.Retain), 'No Retain');
end;

procedure TTestCommitParser.TestCommitTransaction;
begin
  TestCommit('Commit TRANSACTION T');
  AssertIdentifierName('Transaction name','T',Commit.TransactionName);
  TestContext.AssertTrue((False)=(Commit.Work), 'No work');
  TestContext.AssertTrue((False)=(Commit.Release), 'No release');
  TestContext.AssertTrue((False)=(Commit.Retain), 'No Retain');
end;

procedure TTestCommitParser.TestCommitTransactionWork;
begin
  TestCommit('Commit WORK TRANSACTION T ');
  AssertIdentifierName('Transaction name','T',Commit.TransactionName);
  TestContext.AssertTrue((True)=(Commit.Work), 'work');
  TestContext.AssertTrue((False)=(Commit.Release), 'No release');
  TestContext.AssertTrue((False)=(Commit.Retain), 'No Retain');
end;

procedure TTestCommitParser.TestCommitTransactionRelease;
begin
  TestCommit('Commit TRANSACTION T RELEASE');
  AssertIdentifierName('Transaction name','T',Commit.TransactionName);
  TestContext.AssertTrue((False)=(Commit.Work), 'no work');
  TestContext.AssertTrue((True)=(Commit.Release), 'release');
  TestContext.AssertTrue((False)=(Commit.Retain), 'No Retain');
end;

procedure TTestCommitParser.TestCommitTransactionWorkRelease;
begin
  TestCommit('Commit WORK TRANSACTION T  RELEASE');
  AssertIdentifierName('Transaction name','T',Commit.TransactionName);
  TestContext.AssertTrue((True)=(Commit.Work), 'work');
  TestContext.AssertTrue((True)=(Commit.Release), 'release');
  TestContext.AssertTrue((False)=(Commit.Retain), 'No Retain');
end;

procedure TTestCommitParser.TestCommitRetain;
begin
  TestCommit('Commit RETAIN');
  TestContext.AssertTrue((Commit.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((False)=(Commit.Work), 'No work');
  TestContext.AssertTrue((False)=(Commit.Release), 'No release');
  TestContext.AssertTrue((True)=(Commit.Retain), 'Retain');
end;

procedure TTestCommitParser.TestCommitRetainSnapShot;
begin
  TestCommit('Commit RETAIN SNAPSHOT');
  TestContext.AssertTrue((Commit.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((False)=(Commit.Work), 'No work');
  TestContext.AssertTrue((False)=(Commit.Release), 'No release');
  TestContext.AssertTrue((True)=(Commit.Retain), 'Retain');
end;

procedure TTestCommitParser.TestCommitWorkRetain;
begin
  TestCommit('Commit WORK  RETAIN');
  TestContext.AssertTrue((Commit.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((True)=(Commit.Work), 'work');
  TestContext.AssertTrue((False)=(Commit.Release), 'No release');
  TestContext.AssertTrue((True)=(Commit.Retain), 'Retain');
end;

procedure TTestCommitParser.TestCommitReleaseRetain;
begin
  TestCommit('Commit RELEASE  RETAIN');
  TestContext.AssertTrue((Commit.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((False)=(Commit.Work), 'no work');
  TestContext.AssertTrue((True)=(Commit.Release), 'release');
  TestContext.AssertTrue((True)=(Commit.Retain), 'Retain');
end;

procedure TTestCommitParser.TestCommitWorkReleaseRetain;
begin
  TestCommit('Commit WORK RELEASE  RETAIN');
  TestContext.AssertTrue((Commit.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((True)=(Commit.Work), 'work');
  TestContext.AssertTrue((True)=(Commit.Release), 'release');
  TestContext.AssertTrue((True)=(Commit.Retain), 'Retain');
end;

procedure TTestCommitParser.TestCommitTransactionRetain;
begin
  TestCommit('Commit TRANSACTION T  RETAIN');
  AssertIdentifierName('Transaction name','T',Commit.TransactionName);
  TestContext.AssertTrue((False)=(Commit.Work), 'No work');
  TestContext.AssertTrue((False)=(Commit.Release), 'No release');
  TestContext.AssertTrue((True)=(Commit.Retain), 'Retain');
end;

procedure TTestCommitParser.TestCommitTransactionWorkRetain;
begin
  TestCommit('Commit WORK TRANSACTION T  RETAIN');
  AssertIdentifierName('Transaction name','T',Commit.TransactionName);
  TestContext.AssertTrue((True)=(Commit.Work), 'work');
  TestContext.AssertTrue((False)=(Commit.Release), 'No release');
  TestContext.AssertTrue((True)=(Commit.Retain), 'Retain');
end;

procedure TTestCommitParser.TestCommitTransactionReleaseRetain;
begin
  TestCommit('Commit TRANSACTION T RELEASE  RETAIN');
  AssertIdentifierName('Transaction name','T',Commit.TransactionName);
  TestContext.AssertTrue((False)=(Commit.Work), 'no work');
  TestContext.AssertTrue((True)=(Commit.Release), 'release');
  TestContext.AssertTrue((True)=(Commit.Retain), 'Retain');
end;

procedure TTestCommitParser.TestCommitTransactionWorkReleaseRetain;
begin
  TestCommit('Commit WORK TRANSACTION T  RELEASE RETAIN');
  AssertIdentifierName('Transaction name','T',Commit.TransactionName);
  TestContext.AssertTrue((True)=(Commit.Work), 'work');
  TestContext.AssertTrue((True)=(Commit.Release), 'release');
  TestContext.AssertTrue((True)=(Commit.Retain), 'Retain');
end;

{ TTestExecuteProcedureParser }

function TTestExecuteProcedureParser.TestExecute(const ASource: String
  ): TSQLExecuteProcedureStatement;
begin
  CreateParser(ASource);
  FToFree:=Parser.Parse;
  Result:=TSQLExecuteProcedureStatement(CheckClass(FToFree,TSQLExecuteProcedureStatement));
  FExecute:=Result;
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestExecuteProcedureParser.TestExecuteError(const ASource: String);
begin
  FErrSource:=ASource;
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestExecuteProcedureParser.TestExecuteSimple;
begin
  TestExecute('EXECUTE PROCEDURE A');
  AssertIdentifierName('Correct procedure name','A',Execute.ProcedureName);
  TestContext.AssertTrue((Execute.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((0)=(Execute.Params.Count), 'No arguments');
  TestContext.AssertTrue((0)=(Execute.Returning.Count), 'No return values');
end;

procedure TTestExecuteProcedureParser.TestExecuteSimpleTransaction;
begin
  TestExecute('EXECUTE PROCEDURE TRANSACTION B A');
  AssertIdentifierName('Correct procedure name','A',Execute.ProcedureName);
  AssertIdentifierName('Correct transaction name','B',Execute.TransactionName);
  TestContext.AssertTrue((0)=(Execute.Params.Count), 'No arguments');
  TestContext.AssertTrue((0)=(Execute.Returning.Count), 'No return values');
end;

procedure TTestExecuteProcedureParser.TestExecuteSimpleReturningValues;
begin
  TestExecute('EXECUTE PROCEDURE A RETURNING_VALUES :B');
  AssertIdentifierName('Correct procedure name','A',Execute.ProcedureName);
  TestContext.AssertTrue((Execute.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((0)=(Execute.Params.Count), 'No arguments');
  TestContext.AssertTrue((1)=(Execute.Returning.Count), '1 return value');
  AssertIdentifierName('return value','B',Execute.Returning[0]);
end;

procedure TTestExecuteProcedureParser.TestExecuteSimpleReturning2Values;
begin
  TestExecute('EXECUTE PROCEDURE A RETURNING_VALUES :B,:C');
  AssertIdentifierName('Correct procedure name','A',Execute.ProcedureName);
  TestContext.AssertTrue((Execute.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((0)=(Execute.Params.Count), 'No arguments');
  TestContext.AssertTrue((2)=(Execute.Returning.Count), '2 return values');
  AssertIdentifierName('return value','B',Execute.Returning[0]);
  AssertIdentifierName('return value','C',Execute.Returning[1]);
end;

procedure TTestExecuteProcedureParser.TestExecuteOneArg;

Var
  I : TSQLIdentifierExpression;

begin
  TestExecute('EXECUTE PROCEDURE A (B)');
  AssertIdentifierName('Correct procedure name','A',Execute.ProcedureName);
  TestContext.AssertTrue((Execute.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((1)=(Execute.Params.Count), 'One argument');
  I:=TSQLIdentifierExpression(CheckClass(Execute.Params[0],TSQLIdentifierExpression));
  AssertIdentifierName('Correct argument','B',I.Identifier);
  TestContext.AssertTrue((0)=(Execute.Returning.Count), 'No return values');
end;

procedure TTestExecuteProcedureParser.TestExecuteOneArgNB;

Var
  I : TSQLIdentifierExpression;

begin
  TestExecute('EXECUTE PROCEDURE A B');
  AssertIdentifierName('Correct procedure name','A',Execute.ProcedureName);
  TestContext.AssertTrue((Execute.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((1)=(Execute.Params.Count), 'One argument');
  I:=TSQLIdentifierExpression(CheckClass(Execute.Params[0],TSQLIdentifierExpression));
  AssertIdentifierName('Correct argument','B',I.Identifier);
  TestContext.AssertTrue((0)=(Execute.Returning.Count), 'No return values');
end;


procedure TTestExecuteProcedureParser.TestExecuteTwoArgs;
Var
  I : TSQLIdentifierExpression;

begin
  TestExecute('EXECUTE PROCEDURE A (B,C)');
  AssertIdentifierName('Correct procedure name','A',Execute.ProcedureName);
  TestContext.AssertTrue((Execute.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((2)=(Execute.Params.Count), 'Two arguments');
  I:=TSQLIdentifierExpression(CheckClass(Execute.Params[0],TSQLIdentifierExpression));
  AssertIdentifierName('Correct argument','B',I.Identifier);
  I:=TSQLIdentifierExpression(CheckClass(Execute.Params[1],TSQLIdentifierExpression));
  AssertIdentifierName('Correct argument','C',I.Identifier);
  TestContext.AssertTrue((0)=(Execute.Returning.Count), 'No return values');
end;

procedure TTestExecuteProcedureParser.TestExecuteTwoArgsNB;
Var
  I : TSQLIdentifierExpression;

begin
  TestExecute('EXECUTE PROCEDURE A B, C');
  AssertIdentifierName('Correct procedure name','A',Execute.ProcedureName);
  TestContext.AssertTrue((Execute.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((2)=(Execute.Params.Count), 'Two arguments');
  I:=TSQLIdentifierExpression(CheckClass(Execute.Params[0],TSQLIdentifierExpression));
  AssertIdentifierName('Correct argument','B',I.Identifier);
  I:=TSQLIdentifierExpression(CheckClass(Execute.Params[1],TSQLIdentifierExpression));
  AssertIdentifierName('Correct argument','C',I.Identifier);
  TestContext.AssertTrue((0)=(Execute.Returning.Count), 'No return values');
end;

procedure TTestExecuteProcedureParser.TestExecuteOneArgSelect;

Var
  S : TSQLSelectExpression;

begin
  TestExecute('EXECUTE PROCEDURE A ((SELECT B FROM C))');
  AssertIdentifierName('Correct procedure name','A',Execute.ProcedureName);
  TestContext.AssertTrue((Execute.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((1)=(Execute.Params.Count), 'One argument');
  S:=TSQLSelectExpression(CheckClass(Execute.Params[0],TSQLSelectExpression));
  AssertField(S.Select.Fields[0],'B','');
  AssertTable(S.Select.Tables[0],'C','');
  TestContext.AssertTrue((0)=(Execute.Returning.Count), 'No return values');
end;

procedure TTestExecuteProcedureParser.TestExecuteOneArgSelectNB;

Var
  S : TSQLSelectExpression;

begin
  TestExecute('EXECUTE PROCEDURE A (SELECT B FROM C)');
  AssertIdentifierName('Correct procedure name','A',Execute.ProcedureName);
  TestContext.AssertTrue((Execute.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((1)=(Execute.Params.Count), 'One argument');
  S:=TSQLSelectExpression(CheckClass(Execute.Params[0],TSQLSelectExpression));
  AssertField(S.Select.Fields[0],'B','');
  AssertTable(S.Select.Tables[0],'C','');
  TestContext.AssertTrue((0)=(Execute.Returning.Count), 'No return values');
end;

procedure TTestExecuteProcedureParser.TestExecuteTwoArgsSelect;

Var
  S : TSQLSelectExpression;
  I : TSQLIdentifierExpression;

begin
  TestExecute('EXECUTE PROCEDURE A ((SELECT B FROM C),D)');
  AssertIdentifierName('Correct procedure name','A',Execute.ProcedureName);
  TestContext.AssertTrue((Execute.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((2)=(Execute.Params.Count), 'Two arguments');
  S:=TSQLSelectExpression(CheckClass(Execute.Params[0],TSQLSelectExpression));
  AssertField(S.Select.Fields[0],'B','');
  AssertTable(S.Select.Tables[0],'C','');
  I:=TSQLIdentifierExpression(CheckClass(Execute.Params[1],TSQLIdentifierExpression));
  AssertIdentifierName('Correct argument','D',I.Identifier);
  TestContext.AssertTrue((0)=(Execute.Returning.Count), 'No return values');
end;

procedure TTestExecuteProcedureParser.TestExecuteTwoArgsSelectNB;

Var
  S : TSQLSelectExpression;
  I : TSQLIdentifierExpression;

begin
  TestExecute('EXECUTE PROCEDURE A (SELECT B FROM C),D');
  AssertIdentifierName('Correct procedure name','A',Execute.ProcedureName);
  TestContext.AssertTrue((Execute.TransactionName)=nil, 'No transaction name');
  TestContext.AssertTrue((2)=(Execute.Params.Count), 'Two arguments');
  S:=TSQLSelectExpression(CheckClass(Execute.Params[0],TSQLSelectExpression));
  AssertField(S.Select.Fields[0],'B','');
  AssertTable(S.Select.Tables[0],'C','');
  I:=TSQLIdentifierExpression(CheckClass(Execute.Params[1],TSQLIdentifierExpression));
  AssertIdentifierName('Correct argument','D',I.Identifier);
  TestContext.AssertTrue((0)=(Execute.Returning.Count), 'No return values');
end;

procedure TTestExecuteProcedureParser.TestExecuteOneArgSelectErr;
begin
  TestExecuteError('EXECUTE PROCEDURE A ((SELECT B FROM C), 2')
end;

procedure TTestExecuteProcedureParser.TestExecuteOneArgSelectErr2;
begin
  TestExecuteError('EXECUTE PROCEDURE A (SELECT B FROM C), 2)')
end;

procedure TTestExecuteProcedureParser.TestExecuteOneArgSelectErr3;
begin
  TestExecuteError('EXECUTE PROCEDURE A B)')
end;

procedure TTestExecuteProcedureParser.TestExecuteOneArgSelectErr4;
begin
  TestExecuteError('EXECUTE PROCEDURE A B,C)')
end;

{ EXECUTE PROCEDURE DELETE_EMPLOYEE2 1, 2;
  EXECUTE PROCEDURE DELETE_EMPLOYEE2 (1, 2);
  EXECUTE PROCEDURE DELETE_EMPLOYEE2 ((SELECT A FROM A), 2);
  EXECUTE PROCEDURE DELETE_EMPLOYEE2 (SELECT A FROM A), 2;
}

{ TTestConnectParser }

function TTestConnectParser.TestConnect(const ASource: String
  ): TSQLConnectStatement;
begin
  CreateParser(ASource);
  FToFree:=Parser.Parse;
  Result:=TSQLConnectStatement(CheckClass(FToFree,TSQLConnectStatement));
  FConnect:=Result;
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestConnectParser.TestConnectError(const ASource: String);
begin
  FErrSource:=ASource;
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestConnectParser.TestConnectSimple;
begin
  TestConnect('CONNECT ''/my/database/file''');
  TestContext.AssertTrue(('/my/database/file')=(Connect.DatabaseName), 'Database name');
  TestContext.AssertTrue(('')=(Connect.UserName), 'User name');
  TestContext.AssertTrue(('')=(Connect.Password), 'Password');
  TestContext.AssertTrue(('')=(Connect.Role), 'Role');
  TestContext.AssertTrue((0)=(Connect.Cache), 'Cache');
end;

procedure TTestConnectParser.TestConnectUser;
begin
  TestConnect('CONNECT ''/my/database/file'' USER ''me''');
  TestContext.AssertTrue(('/my/database/file')=(Connect.DatabaseName), 'Database name');
  TestContext.AssertTrue(('me')=(Connect.UserName), 'User name');
  TestContext.AssertTrue(('')=(Connect.Password), 'Password');
  TestContext.AssertTrue(('')=(Connect.Role), 'Role');
  TestContext.AssertTrue((0)=(Connect.Cache), 'Cache');
end;

procedure TTestConnectParser.TestConnectPassword;
begin
  TestConnect('CONNECT ''/my/database/file'' PASSWORD ''secret''');
  TestContext.AssertTrue(('/my/database/file')=(Connect.DatabaseName), 'Database name');
  TestContext.AssertTrue(('')=(Connect.UserName), 'User name');
  TestContext.AssertTrue(('secret')=(Connect.Password), 'Password');
  TestContext.AssertTrue(('')=(Connect.Role), 'Role');
  TestContext.AssertTrue((0)=(Connect.Cache), 'Cache');
end;

procedure TTestConnectParser.TestConnectUserPassword;
begin
  TestConnect('CONNECT ''/my/database/file'' USER ''me'' PASSWORD ''secret''');
  TestContext.AssertTrue(('/my/database/file')=(Connect.DatabaseName), 'Database name');
  TestContext.AssertTrue(('me')=(Connect.UserName), 'User name');
  TestContext.AssertTrue(('secret')=(Connect.Password), 'Password');
  TestContext.AssertTrue(('')=(Connect.Role), 'Role');
  TestContext.AssertTrue((0)=(Connect.Cache), 'Cache');
end;
procedure TTestConnectParser.TestConnectUserPasswordRole;
begin
  TestConnect('CONNECT ''/my/database/file'' USER ''me'' PASSWORD ''secret'' ROLE ''admin''');
  TestContext.AssertTrue(('/my/database/file')=(Connect.DatabaseName), 'Database name');
  TestContext.AssertTrue(('me')=(Connect.UserName), 'User name');
  TestContext.AssertTrue(('secret')=(Connect.Password), 'Password');
  TestContext.AssertTrue(('admin')=(Connect.Role), 'Role');
  TestContext.AssertTrue((0)=(Connect.Cache), 'Cache');
end;

procedure TTestConnectParser.TestConnectUserPasswordRoleCache;
begin
  TestConnect('CONNECT ''/my/database/file'' USER ''me'' PASSWORD ''secret'' ROLE ''admin'' CACHE 2048');
  TestContext.AssertTrue(('/my/database/file')=(Connect.DatabaseName), 'Database name');
  TestContext.AssertTrue(('me')=(Connect.UserName), 'User name');
  TestContext.AssertTrue(('secret')=(Connect.Password), 'Password');
  TestContext.AssertTrue(('admin')=(Connect.Role), 'Role');
  TestContext.AssertTrue((2048)=(Connect.Cache), 'Cache');
end;

procedure TTestConnectParser.TestConnectSimpleCache;
begin
  TestConnect('CONNECT ''/my/database/file'' CACHE 2048');
  TestContext.AssertTrue(('/my/database/file')=(Connect.DatabaseName), 'Database name');
  TestContext.AssertTrue(('')=(Connect.UserName), 'User name');
  TestContext.AssertTrue(('')=(Connect.Password), 'Password');
  TestContext.AssertTrue(('')=(Connect.Role), 'Role');
  TestContext.AssertTrue((2048)=(Connect.Cache), 'Cache');
end;

{ TTestCreateDatabaseParser }

function TTestCreateDatabaseParser.TestCreate(const ASource: String
  ): TSQLCreateDatabaseStatement;
begin
  CreateParser(ASource);
  FToFree:=Parser.Parse;
  Result:=TSQLCreateDatabaseStatement(CheckClass(FToFree,TSQLCreateDatabaseStatement));
  FCreateDB:=Result;
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestCreateDatabaseParser.TestCreateError(const ASource: String);
begin
  FerrSource:=ASource;
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestCreateDatabaseParser.TestSimple;
begin
  TestCreate('CREATE DATABASE ''/my/database/file''');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((0)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((0)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((0)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
end;

procedure TTestCreateDatabaseParser.TestSimpleSchema;
begin
  TestCreate('CREATE SCHEMA ''/my/database/file''');
  TestContext.AssertTrue((True)=(CreateDB.UseSchema), 'schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((0)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((0)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((0)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
end;

procedure TTestCreateDatabaseParser.TestSimpleUSer;
begin
  TestCreate('CREATE DATABASE ''/my/database/file'' USER ''me''');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('me')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((0)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((0)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((0)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
end;

procedure TTestCreateDatabaseParser.TestSimpleUSerPassword;

begin
  TestCreate('CREATE DATABASE ''/my/database/file'' USER ''me'' PASSWORD ''SECRET''');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('me')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('SECRET')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((0)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((0)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((0)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
end;

procedure TTestCreateDatabaseParser.TestSimplePassword;
begin
  TestCreate('CREATE DATABASE ''/my/database/file'' PASSWORD ''SECRET''');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('SECRET')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((0)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((0)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((0)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
end;

procedure TTestCreateDatabaseParser.TestPageSize;
begin
  TestCreate('CREATE DATABASE ''/my/database/file'' PAGE_SIZE = 2048');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((2048)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((0)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((0)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
end;

procedure TTestCreateDatabaseParser.TestPageSize2;
begin
  TestCreate('CREATE DATABASE ''/my/database/file'' PAGE_SIZE 2048');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((2048)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((0)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((0)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
end;

procedure TTestCreateDatabaseParser.TestPageSizeLength;
begin
  TestCreate('CREATE DATABASE ''/my/database/file'' PAGE_SIZE 2048 LENGTH = 2000');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((2048)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((2000)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((0)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
end;

procedure TTestCreateDatabaseParser.TestPageSizeLength2;
begin
  TestCreate('CREATE DATABASE ''/my/database/file'' PAGE_SIZE 2048 LENGTH 2000');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((2048)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((2000)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((0)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
end;

procedure TTestCreateDatabaseParser.TestPageSizeLength3;
begin
  TestCreate('CREATE DATABASE ''/my/database/file'' PAGE_SIZE 2048 LENGTH 2000 PAGES');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((2048)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((2000)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((0)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
end;

procedure TTestCreateDatabaseParser.TestPageSizeLength4;
begin
  TestCreate('CREATE DATABASE ''/my/database/file'' PAGE_SIZE 2048 LENGTH 2000 PAGE');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((2048)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((2000)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((0)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
end;

procedure TTestCreateDatabaseParser.TestCharset;
begin
  TestCreate('CREATE DATABASE ''/my/database/file'' DEFAULT CHARACTER SET UTF8');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  AssertIDentifierName('Character set','UTF8',CreateDB.CharSet);
  TestContext.AssertTrue((0)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((0)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((0)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
end;

procedure TTestCreateDatabaseParser.TestSecondaryFile1;
begin
  TestCreate('CREATE DATABASE ''/my/database/file'' PAGE_SIZE 2048 LENGTH 2000 FILE ''/my/database/file2''');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((2048)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((2000)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((1)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
  AssertSecondaryFile(CreateDB.SecondaryFiles[0],'/my/database/file2',0,0);
end;
procedure TTestCreateDatabaseParser.TestSecondaryFile2;
begin
  TestCreate('CREATE DATABASE ''/my/database/file'' PAGE_SIZE 2048 LENGTH 2000 FILE ''/my/database/file2'' LENGTH 1000');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((2048)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((2000)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((1)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
  AssertSecondaryFile(CreateDB.SecondaryFiles[0],'/my/database/file2',1000,0);
end;

procedure TTestCreateDatabaseParser.TestSecondaryFile3;
begin
  TestCreate('CREATE DATABASE ''/my/database/file'' PAGE_SIZE 2048 LENGTH 2000 FILE ''/my/database/file2'' LENGTH = 1000');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((2048)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((2000)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((1)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
  AssertSecondaryFile(CreateDB.SecondaryFiles[0],'/my/database/file2',1000,0);
end;

procedure TTestCreateDatabaseParser.TestSecondaryFile4;
begin
  TestCreate('CREATE DATABASE ''/my/database/file'' PAGE_SIZE 2048 LENGTH 2000 FILE ''/my/database/file2'' LENGTH = 1000 PAGE');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((2048)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((2000)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((1)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
  AssertSecondaryFile(CreateDB.SecondaryFiles[0],'/my/database/file2',1000,0);
end;

procedure TTestCreateDatabaseParser.TestSecondaryFile5;
begin
  TestCreate('CREATE DATABASE ''/my/database/file'' PAGE_SIZE 2048 LENGTH 2000 FILE ''/my/database/file2'' LENGTH = 1000 PAGES');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((2048)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((2000)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((1)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
  AssertSecondaryFile(CreateDB.SecondaryFiles[0],'/my/database/file2',1000,0);
end;

procedure TTestCreateDatabaseParser.TestSecondaryFile6;
begin
  TestCreate('CREATE DATABASE ''/my/database/file'' PAGE_SIZE 2048 LENGTH 2000 FILE ''/my/database/file2'' STARTING 3000 ');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((2048)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((2000)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((1)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
  AssertSecondaryFile(CreateDB.SecondaryFiles[0],'/my/database/file2',0,3000);
end;

procedure TTestCreateDatabaseParser.TestSecondaryFile7;
begin
  TestCreate('CREATE DATABASE ''/my/database/file'' PAGE_SIZE 2048 LENGTH 2000 FILE ''/my/database/file2'' STARTING AT 3000 ');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((2048)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((2000)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((1)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
  AssertSecondaryFile(CreateDB.SecondaryFiles[0],'/my/database/file2',0,3000);
end;

procedure TTestCreateDatabaseParser.TestSecondaryFile9;
begin
  TestCreate('CREATE DATABASE ''/my/database/file'' PAGE_SIZE 2048 LENGTH 2000 FILE ''/my/database/file2'' LENGTH 201 STARTING AT PAGE 3000 ');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((2048)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((2000)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((1)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
  AssertSecondaryFile(CreateDB.SecondaryFiles[0],'/my/database/file2',201,3000);
end;

procedure TTestCreateDatabaseParser.TestSecondaryFile10;
begin
  TestCreate('CREATE DATABASE ''/my/database/file'' PAGE_SIZE 2048 LENGTH 2000 FILE ''/my/database/file2''  STARTING AT PAGE 3000 LENGTH 201');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((2048)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((2000)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((1)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
  AssertSecondaryFile(CreateDB.SecondaryFiles[0],'/my/database/file2',201,3000);
end;
procedure TTestCreateDatabaseParser.TestSecondaryFile8;
begin
  TestCreate('CREATE DATABASE ''/my/database/file'' PAGE_SIZE 2048 LENGTH 2000 FILE ''/my/database/file2'' STARTING AT PAGE 3000 ');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((2048)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((2000)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((1)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
  AssertSecondaryFile(CreateDB.SecondaryFiles[0],'/my/database/file2',0,3000);
end;

procedure TTestCreateDatabaseParser.TestSecondaryFileS;
begin
  TestCreate('CREATE DATABASE ''/my/database/file'' PAGE_SIZE 2048 LENGTH 2000 FILE ''/my/database/file2'' FILE ''/my/database/file3'' ');
  TestContext.AssertTrue((False)=(CreateDB.UseSchema), 'Not schema');
  TestContext.AssertTrue(('/my/database/file')=(CreateDB.FileName), 'Database file');
  TestContext.AssertTrue(('')=(CreateDB.UserName), 'Username');
  TestContext.AssertTrue(('')=(CreateDB.Password), 'Password');
  TestContext.AssertTrue((CreateDB.CharSet)=nil, 'Character set');
  TestContext.AssertTrue((2048)=(CreateDB.PageSize), 'Page size');
  TestContext.AssertTrue((2000)=(CreateDB.Length), 'Length');
  TestContext.AssertTrue((2)=(CreateDB.SecondaryFiles.Count), 'Secondary files');
  AssertSecondaryFile(CreateDB.SecondaryFiles[0],'/my/database/file2',0,0);
  AssertSecondaryFile(CreateDB.SecondaryFiles[1],'/my/database/file3',0,0);
end;

procedure TTestCreateDatabaseParser.TestSecondaryFileError1;
begin
  TestCreateError('CREATE DATABASE ''/my/database/file'' PAGE_SIZE 2048 LENGTH 2000 FILE ''/my/database/file2'' LENGTH 3 LENGTH 2');
end;

procedure TTestCreateDatabaseParser.TestSecondaryFileError2;
begin
  TestCreateError('CREATE DATABASE ''/my/database/file'' PAGE_SIZE 2048 LENGTH 2000 FILE ''/my/database/file2'' STARTING 3 STARTING 2');
end;

procedure TTestCreateDatabaseParser.TestSecondaryFileError3;
begin
  TestCreateError('CREATE DATABASE ''/my/database/file'' PAGE_SIZE 2048 LENGTH 2000 FILE ''/my/database/file2'' STARTING 3 LENGTH 2 STARTING 2');
end;

{ TTestAlterDatabaseParser }

function TTestAlterDatabaseParser.TestAlter(const ASource: String
  ): TSQLAlterDatabaseStatement;
begin
  CreateParser(ASource);
  FToFree:=Parser.Parse;
  Result:=TSQLAlterDatabaseStatement(CheckClass(FToFree,TSQLAlterDatabaseStatement));
  FAlterDB:=Result;
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestAlterDatabaseParser.TestAlterError(const ASource: String);
begin
  FerrSource:=ASource;
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestAlterDatabaseParser.TestSimple;
begin
  TestAlter('ALTER DATABASE ADD FILE ''/my/file''');
  TestContext.AssertTrue((1)=(AlterDB.Operations.Count), 'Operation count');
  AssertSecondaryFile(AlterDB.Operations[0],'/my/file',0,0);
end;

procedure TTestAlterDatabaseParser.TestStarting;
begin
  TestAlter('ALTER DATABASE ADD FILE ''/my/file'' STARTING AT 100');
  TestContext.AssertTrue((1)=(AlterDB.Operations.Count), 'Operation count');
  AssertSecondaryFile(AlterDB.Operations[0],'/my/file',0,100);
end;

procedure TTestAlterDatabaseParser.TestStartingLength;
begin
  TestAlter('ALTER DATABASE ADD FILE ''/my/file'' STARTING AT 100 LENGTH 200');
  TestContext.AssertTrue((1)=(AlterDB.Operations.Count), 'Operation count');
  AssertSecondaryFile(AlterDB.Operations[0],'/my/file',200,100);
end;

procedure TTestAlterDatabaseParser.TestFiles;
begin
  TestAlter('ALTER DATABASE ADD FILE ''/my/file2'' ADD FILE ''/my/file3'' ');
  TestContext.AssertTrue((2)=(AlterDB.Operations.Count), 'Operation count');
  AssertSecondaryFile(AlterDB.Operations[0],'/my/file2',0,0);
  AssertSecondaryFile(AlterDB.Operations[1],'/my/file3',0,0);
end;

procedure TTestAlterDatabaseParser.TestFiles2;
begin
  TestAlter('ALTER DATABASE ADD FILE ''/my/file2'' FILE ''/my/file3'' ');
  TestContext.AssertTrue((2)=(AlterDB.Operations.Count), 'Operation count');
  AssertSecondaryFile(AlterDB.Operations[0],'/my/file2',0,0);
  AssertSecondaryFile(AlterDB.Operations[1],'/my/file3',0,0);
end;

procedure TTestAlterDatabaseParser.TestFilesError;
begin
  TestAlterError('ALTER DATABASE FILE ''/my/file2'' FILE ''/my/file3'' ');
end;

procedure TTestAlterDatabaseParser.TestError;
begin
  TestAlterError('ALTER DATABASE ');
end;

procedure TTestAlterDatabaseParser.TestLength;
begin
  TestAlter('ALTER DATABASE ADD FILE ''/my/file'' LENGTH 200');
  TestContext.AssertTrue((1)=(AlterDB.Operations.Count), 'Operation count');
  AssertSecondaryFile(AlterDB.Operations[0],'/my/file',200,0);
end;

{ TTestCreateViewParser }

function TTestCreateViewParser.TestCreate(const ASource: String
  ): TSQLCreateViewStatement;
begin
  CreateParser(ASource);
  FToFree:=Parser.Parse;
  Result:=TSQLCreateViewStatement(CheckClass(FToFree,TSQLCreateViewStatement));
  FView:=Result;
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestCreateViewParser.TestCreateError(const ASource: String);
begin
  FerrSource:=ASource;
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestCreateViewParser.TestSimple;

Var
  S : TSQLSelectStatement;

begin
  TestCreate('CREATE VIEW A AS SELECT B FROM C');
  AssertIdentifierName('View name','A',View.ObjectName);
  TestContext.AssertTrue((View.Fields)<>nil, 'field list created');
  TestContext.AssertTrue((0)=(View.Fields.Count), 'No fields in list');
  S:=TSQLSelectStatement(CheckClass(View.select,TSQLSelectStatement));
  TestContext.AssertTrue((1)=(S.Fields.Count), '1 Field');
  AssertField(S.Fields[0],'B','');
  TestContext.AssertTrue((1)=(S.Tables.Count), '1 table');
  AssertTable(S.Tables[0],'C','');
  TestContext.AssertTrue((False)=(View.WithCheckOption), 'No with check option');
end;

procedure TTestCreateViewParser.TestFieldList;

Var
  S : TSQLSelectStatement;

begin
  TestCreate('CREATE VIEW A (D) AS SELECT B FROM C');
  AssertIdentifierName('View name','A',View.ObjectName);
  TestContext.AssertTrue((View.Fields)<>nil, 'field list created');
  TestContext.AssertTrue((1)=(View.Fields.Count), '1 field in list');
  AssertIdentifierName('Field name','D',View.Fields[0]);
  S:=TSQLSelectStatement(CheckClass(View.select,TSQLSelectStatement));
  TestContext.AssertTrue((1)=(S.Fields.Count), '1 Field');
  AssertField(S.Fields[0],'B','');
  TestContext.AssertTrue((1)=(S.Tables.Count), '1 table');
  AssertTable(S.Tables[0],'C','');
  TestContext.AssertTrue((False)=(View.WithCheckOption), 'No with check option');
end;

procedure TTestCreateViewParser.TestFieldList2;

Var
  S : TSQLSelectStatement;

begin
  TestCreate('CREATE VIEW A (B,C) AS SELECT D,E FROM F');
  AssertIdentifierName('View name','A',View.ObjectName);
  TestContext.AssertTrue((View.Fields)<>nil, 'field list created');
  TestContext.AssertTrue((2)=(View.Fields.Count), '2 fields in list');
  AssertIdentifierName('Field name','B',View.Fields[0]);
  AssertIdentifierName('Field name','C',View.Fields[1]);
  S:=TSQLSelectStatement(CheckClass(View.select,TSQLSelectStatement));
  TestContext.AssertTrue((2)=(S.Fields.Count), '2 Fields in select');
  AssertField(S.Fields[0],'D','');
  AssertField(S.Fields[1],'E','');
  TestContext.AssertTrue((1)=(S.Tables.Count), '1 table');
  AssertTable(S.Tables[0],'F','');
  TestContext.AssertTrue((False)=(View.WithCheckOption), 'No with check option');
end;

procedure TTestCreateViewParser.TestSimpleWithCheckoption;

Var
  S : TSQLSelectStatement;

begin
  TestCreate('CREATE VIEW A AS SELECT B FROM C WITH CHECK OPTION');
  AssertIdentifierName('View name','A',View.ObjectName);
  TestContext.AssertTrue((View.Fields)<>nil, 'field list created');
  TestContext.AssertTrue((0)=(View.Fields.Count), 'No fields in list');
  S:=TSQLSelectStatement(CheckClass(View.select,TSQLSelectStatement));
  TestContext.AssertTrue((1)=(S.Fields.Count), '1 Field');
  AssertField(S.Fields[0],'B','');
  TestContext.AssertTrue((1)=(S.Tables.Count), '1 table');
  AssertTable(S.Tables[0],'C','');
  TestContext.AssertTrue((True)=(View.WithCheckOption), 'With check option');
end;

{ TTestCreateShadowParser }

function TTestCreateShadowParser.TestCreate(const ASource: String
  ): TSQLCreateShadowStatement;
begin
  CreateParser(ASource);
  FToFree:=Parser.Parse;
  Result:=TSQLCreateShadowStatement(CheckClass(FToFree,TSQLCreateShadowStatement));
  FShadow:=Result;
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestCreateShadowParser.TestCreateError(const ASource: String);
begin
  FerrSource:=ASource;
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestCreateShadowParser.TestSimple;
begin
  TestCreate('CREATE SHADOW 1 ''/my/file''');
  TestContext.AssertTrue((False)=(Shadow.Manual), 'Not manual');
  TestContext.AssertTrue((False)=(Shadow.COnditional), 'Not conditional');
  TestContext.AssertTrue(('/my/file')=(Shadow.FileName), 'Filename');
  TestContext.AssertTrue((0)=(Shadow.Length), 'No length');
  TestContext.AssertTrue((0)=(Shadow.SecondaryFiles.Count), 'No secondary files');
end;


procedure TTestCreateShadowParser.TestLength;
begin
  TestCreate('CREATE SHADOW 1 ''/my/file'' LENGTH 2');
  TestContext.AssertTrue((False)=(Shadow.Manual), 'Not manual');
  TestContext.AssertTrue((False)=(Shadow.COnditional), 'Not conditional');
  TestContext.AssertTrue(('/my/file')=(Shadow.FileName), 'Filename');
  TestContext.AssertTrue((2)=(Shadow.Length), 'No length');
  TestContext.AssertTrue((0)=(Shadow.SecondaryFiles.Count), 'No secondary files');
end;

procedure TTestCreateShadowParser.TestLength2;
begin
  TestCreate('CREATE SHADOW 1 ''/my/file'' LENGTH = 2');
  TestContext.AssertTrue((False)=(Shadow.Manual), 'Not manual');
  TestContext.AssertTrue((False)=(Shadow.COnditional), 'Not conditional');
  TestContext.AssertTrue(('/my/file')=(Shadow.FileName), 'Filename');
  TestContext.AssertTrue((2)=(Shadow.Length), 'No length');
  TestContext.AssertTrue((0)=(Shadow.SecondaryFiles.Count), 'No secondary files');
end;

procedure TTestCreateShadowParser.TestLength3;
begin
  TestCreate('CREATE SHADOW 1 ''/my/file'' LENGTH = 2 PAGE');
  TestContext.AssertTrue((False)=(Shadow.Manual), 'Not manual');
  TestContext.AssertTrue((False)=(Shadow.COnditional), 'Not conditional');
  TestContext.AssertTrue(('/my/file')=(Shadow.FileName), 'Filename');
  TestContext.AssertTrue((2)=(Shadow.Length), 'No length');
  TestContext.AssertTrue((0)=(Shadow.SecondaryFiles.Count), 'No secondary files');
end;

procedure TTestCreateShadowParser.TestLength4;
begin
  TestCreate('CREATE SHADOW 1 ''/my/file'' LENGTH = 2 PAGES');
  TestContext.AssertTrue((False)=(Shadow.Manual), 'Not manual');
  TestContext.AssertTrue((False)=(Shadow.COnditional), 'Not conditional');
  TestContext.AssertTrue(('/my/file')=(Shadow.FileName), 'Filename');
  TestContext.AssertTrue((2)=(Shadow.Length), 'No length');
  TestContext.AssertTrue((0)=(Shadow.SecondaryFiles.Count), 'No secondary files');
end;


procedure TTestCreateShadowParser.TestSecondaryFile1;
begin
  TestCreate('CREATE SHADOW 1 ''/my/file'' LENGTH 2 FILE ''/my/file2''');
  TestContext.AssertTrue((False)=(Shadow.Manual), 'Not manual');
  TestContext.AssertTrue((False)=(Shadow.COnditional), 'Not conditional');
  TestContext.AssertTrue(('/my/file')=(Shadow.FileName), 'Filename');
  TestContext.AssertTrue((2)=(Shadow.Length), 'No length');
  TestContext.AssertTrue((1)=(Shadow.SecondaryFiles.Count), '1 secondary file');
  AssertSecondaryFile(Shadow.SecondaryFiles[0],'/my/file2',0,0);
end;

procedure TTestCreateShadowParser.TestSecondaryFile2;
begin
  TestCreate('CREATE SHADOW 1 ''/my/file'' LENGTH 2 FILE ''/my/file2'' LENGTH 1000');
  TestContext.AssertTrue((False)=(Shadow.Manual), 'Not manual');
  TestContext.AssertTrue((False)=(Shadow.COnditional), 'Not conditional');
  TestContext.AssertTrue(('/my/file')=(Shadow.FileName), 'Filename');
  TestContext.AssertTrue((2)=(Shadow.Length), 'No length');
  TestContext.AssertTrue((1)=(Shadow.SecondaryFiles.Count), '1 secondary file');
  AssertSecondaryFile(Shadow.SecondaryFiles[0],'/my/file2',1000,0);

end;

procedure TTestCreateShadowParser.TestSecondaryFile3;
begin
  TestCreate('CREATE SHADOW 1 ''/my/file'' LENGTH 2 FILE ''/my/file2'' LENGTH = 1000');
  TestContext.AssertTrue((False)=(Shadow.Manual), 'Not manual');
  TestContext.AssertTrue((False)=(Shadow.COnditional), 'Not conditional');
  TestContext.AssertTrue(('/my/file')=(Shadow.FileName), 'Filename');
  TestContext.AssertTrue((2)=(Shadow.Length), 'No length');
  TestContext.AssertTrue((1)=(Shadow.SecondaryFiles.Count), '1 secondary file');
  AssertSecondaryFile(Shadow.SecondaryFiles[0],'/my/file2',1000,0);
end;

procedure TTestCreateShadowParser.TestSecondaryFile4;
begin
  TestCreate('CREATE SHADOW 1 ''/my/file'' LENGTH 2 FILE ''/my/file2'' LENGTH = 1000 PAGE');
  TestContext.AssertTrue((False)=(Shadow.Manual), 'Not manual');
  TestContext.AssertTrue((False)=(Shadow.COnditional), 'Not conditional');
  TestContext.AssertTrue(('/my/file')=(Shadow.FileName), 'Filename');
  TestContext.AssertTrue((2)=(Shadow.Length), 'No length');
  TestContext.AssertTrue((1)=(Shadow.SecondaryFiles.Count), '1 secondary file');
  AssertSecondaryFile(Shadow.SecondaryFiles[0],'/my/file2',1000,0);
end;

procedure TTestCreateShadowParser.TestSecondaryFile5;
begin
  TestCreate('CREATE SHADOW 1 ''/my/file'' LENGTH 2 FILE ''/my/file2'' LENGTH = 1000 PAGES');
  TestContext.AssertTrue((False)=(Shadow.Manual), 'Not manual');
  TestContext.AssertTrue((False)=(Shadow.COnditional), 'Not conditional');
  TestContext.AssertTrue(('/my/file')=(Shadow.FileName), 'Filename');
  TestContext.AssertTrue((2)=(Shadow.Length), 'No length');
  TestContext.AssertTrue((1)=(Shadow.SecondaryFiles.Count), '1 secondary file');
  AssertSecondaryFile(Shadow.SecondaryFiles[0],'/my/file2',1000,0);
end;

procedure TTestCreateShadowParser.TestSecondaryFile6;
begin
  TestCreate('CREATE SHADOW 1 ''/my/file'' LENGTH 2 FILE ''/my/file2'' STARTING 3000');
  TestContext.AssertTrue((False)=(Shadow.Manual), 'Not manual');
  TestContext.AssertTrue((False)=(Shadow.COnditional), 'Not conditional');
  TestContext.AssertTrue(('/my/file')=(Shadow.FileName), 'Filename');
  TestContext.AssertTrue((2)=(Shadow.Length), 'No length');
  TestContext.AssertTrue((1)=(Shadow.SecondaryFiles.Count), '1 secondary file');
  AssertSecondaryFile(Shadow.SecondaryFiles[0],'/my/file2',0,3000);
end;

procedure TTestCreateShadowParser.TestSecondaryFile7;
begin
  TestCreate('CREATE SHADOW 1 ''/my/file'' LENGTH 2 FILE ''/my/file2'' STARTING AT 3000');
  TestContext.AssertTrue((False)=(Shadow.Manual), 'Not manual');
  TestContext.AssertTrue((False)=(Shadow.COnditional), 'Not conditional');
  TestContext.AssertTrue(('/my/file')=(Shadow.FileName), 'Filename');
  TestContext.AssertTrue((2)=(Shadow.Length), 'No length');
  TestContext.AssertTrue((1)=(Shadow.SecondaryFiles.Count), '1 secondary file');
  AssertSecondaryFile(Shadow.SecondaryFiles[0],'/my/file2',0,3000);
end;

procedure TTestCreateShadowParser.TestSecondaryFile8;
begin
  TestCreate('CREATE SHADOW 1 ''/my/file'' LENGTH 2 FILE ''/my/file2'' STARTING AT PAGE 3000');
  TestContext.AssertTrue((False)=(Shadow.Manual), 'Not manual');
  TestContext.AssertTrue((False)=(Shadow.COnditional), 'Not conditional');
  TestContext.AssertTrue(('/my/file')=(Shadow.FileName), 'Filename');
  TestContext.AssertTrue((2)=(Shadow.Length), 'No length');
  TestContext.AssertTrue((1)=(Shadow.SecondaryFiles.Count), '1 secondary file');
  AssertSecondaryFile(Shadow.SecondaryFiles[0],'/my/file2',0,3000);
end;


procedure TTestCreateShadowParser.TestSecondaryFileS;
begin
  TestCreate('CREATE SHADOW 1 ''/my/file'' LENGTH 2 FILE ''/my/file2'' FILE ''/my/file3''');
  TestContext.AssertTrue((False)=(Shadow.Manual), 'Not manual');
  TestContext.AssertTrue((False)=(Shadow.COnditional), 'Not conditional');
  TestContext.AssertTrue(('/my/file')=(Shadow.FileName), 'Filename');
  TestContext.AssertTrue((2)=(Shadow.Length), 'No length');
  TestContext.AssertTrue((2)=(Shadow.SecondaryFiles.Count), '2 secondary file');
  AssertSecondaryFile(Shadow.SecondaryFiles[0],'/my/file2',0,0);
  AssertSecondaryFile(Shadow.SecondaryFiles[1],'/my/file3',0,0);
end;


{ TTestProcedureStatement }

function TTestProcedureStatement.TestStatement(const ASource: String
  ): TSQLStatement;
begin
  CreateParser(ASource);
  Parser.GetNextToken;
  FToFree:=Parser.ParseProcedureStatements;
  If not (FToFree is TSQLStatement) then
    TestContext.Fail('Not a TSQLStatement');
  Result:=TSQLStatement(FToFree);
  FSTatement:=Result;
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestProcedureStatement.TestParseStatementError;

begin
  CreateParser(FErrSource);
  FToFree:=Parser.ParseProcedureStatements;
end;

procedure TTestProcedureStatement.TestStatementError(const ASource: String);
begin
  FerrSource:=ASource;
  TestContext.AssertRaises(ESQLParser, @TestParseStatementError, '');
end;

procedure TTestProcedureStatement.TestException;

Var
  E : TSQLExceptionStatement;
begin
  E:=TSQLExceptionStatement(CheckClass(TestStatement('EXCEPTION MYE'),TSQLExceptionStatement));
  AssertIdentifierName('Exception name','MYE',E.ExceptionName);
end;

procedure TTestProcedureStatement.TestExceptionError;
begin
  TestStatementError('EXCEPTION ''MYE''');
end;

procedure TTestProcedureStatement.TestExit;

begin
  CheckClass(TestStatement('EXIT'),TSQLExitStatement);
end;

procedure TTestProcedureStatement.TestSuspend;

begin
  CheckClass(TestStatement('Suspend'),TSQLSuspendStatement);
end;

procedure TTestProcedureStatement.TestEmptyBlock;

Var
  B : TSQLStatementBlock;

begin
  B:=TSQLStatementBlock(CheckClass(TestStatement('BEGIN END'),TSQLStatementBlock));
  TestContext.AssertTrue((0)=(B.Statements.Count), 'No statements')
end;

procedure TTestProcedureStatement.TestExitBlock;

Var
  B : TSQLStatementBlock;

begin
  B:=TSQLStatementBlock(CheckClass(TestStatement('BEGIN EXIT; END'),TSQLStatementBlock));
  TestContext.AssertTrue((1)=(B.Statements.Count), '1 statement');
  CheckClass(B.Statements[0],TSQLExitStatement);
end;

procedure TTestProcedureStatement.TestExitBlockError;

begin
  TestStatementError('BEGIN EXIT END')
end;

procedure TTestProcedureStatement.TestPostEvent;
Var
  P : TSQLPostEventStatement;

begin
  P:=TSQLPostEventStatement(CheckClass(TestStatement('POST_EVENT ''MYEVENT'''),TSQLPostEventStatement));
  TestContext.AssertTrue(('MYEVENT')=(P.EventName), 'Correct event name');
  TestContext.AssertTrue((P.ColName)=nil, 'No event column');
end;

procedure TTestProcedureStatement.TestPostEventColName;

Var
  P : TSQLPostEventStatement;

begin
  P:=TSQLPostEventStatement(CheckClass(TestStatement('POST_EVENT MyColName'),TSQLPostEventStatement));
  TestContext.AssertTrue(('')=(P.EventName), 'Correct event name');
  AssertIdentifierName('event column','MyColName',P.ColName);
end;

procedure TTestProcedureStatement.TestPostError;

begin
  TestStatementError('POST_EVENT 1');
end;

procedure TTestProcedureStatement.TestAssignSimple;
Var
  A : TSQLAssignStatement;
  E : TSQLLiteralExpression;
  I : TSQLIntegerLiteral;
begin
  A:=TSQLAssignStatement(CheckClass(TestStatement('A=1'),TSQLAssignStatement));
  AssertIdentifierName('Variable name','A',A.Variable);
  E:=TSQLLiteralExpression(CheckClass(A.Expression,TSQLLiteralExpression));
  I:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(I.Value), 'Correct value');
end;

procedure TTestProcedureStatement.TestAssignSimpleNew;
Var
  A : TSQLAssignStatement;
  E : TSQLLiteralExpression;
  I : TSQLIntegerLiteral;
begin
  A:=TSQLAssignStatement(CheckClass(TestStatement('NEW.A=1'),TSQLAssignStatement));
  AssertIdentifierName('Variable name','NEW.A',A.Variable);
  E:=TSQLLiteralExpression(CheckClass(A.Expression,TSQLLiteralExpression));
  I:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(I.Value), 'Correct value');
end;

procedure TTestProcedureStatement.TestAssignSelect;
Var
  A : TSQLAssignStatement;
  S : TSQLSelectExpression;

begin
  A:=TSQLAssignStatement(CheckClass(TestStatement('A=(SELECT B FROM C)'),TSQLAssignStatement));
  AssertIdentifierName('Variable name','A',A.Variable);
  S:=TSQLSelectExpression(CheckClass(A.Expression,TSQLSelectExpression));
  TestContext.AssertTrue((1)=(S.Select.Fields.Count), 'Field count');
  TestContext.AssertTrue((1)=(S.Select.Tables.Count), 'Table count');
  AssertField(S.Select.Fields[0],'B','');
  AssertTable(S.Select.Tables[0],'C','');
end;

procedure TTestProcedureStatement.TestBlockAssignSimple;
Var
  A : TSQLAssignStatement;
  E : TSQLLiteralExpression;
  I : TSQLIntegerLiteral;
  B : TSQLStatementBlock;

begin
  B:=TSQLStatementBlock(CheckClass(TestStatement('BEGIN A=1; EXIT; END'),TSQLStatementBlock));
  TestContext.AssertTrue((2)=(B.Statements.Count), '2 statements');
  CheckClass(B.Statements[1],TSQLExitStatement);
  A:=TSQLAssignStatement(CheckClass(B.Statements[0],TSQLAssignStatement));
  AssertIdentifierName('Variable name','A',A.Variable);
  E:=TSQLLiteralExpression(CheckClass(A.Expression,TSQLLiteralExpression));
  I:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(I.Value), 'Correct value');
end;

procedure TTestProcedureStatement.TestIf;
Var
  I : TSQLIfStatement;
  C : TSQLBinaryExpression;
  E : TSQLLiteralExpression;
  A : TSQLIdentifierExpression;
  LI : TSQLIntegerLiteral;

begin
  I:=TSQLIfStatement(CheckClass(TestStatement('IF (A=1) THEN EXIT'),TSQLIfStatement));
  C:=TSQLBinaryExpression(CheckClass(I.Condition,TSQLBinaryExpression));
  TestContext.AssertTrue((boEq)=(C.Operation), 'Equals');
  E:=TSQLLiteralExpression(CheckClass(C.Right,TSQLLiteralExpression));
  LI:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(LI.Value), 'Correct value');
  A:=TSQLIdentifierExpression(CheckClass(C.Left,TSQLIdentifierExpression));
  AssertIdentifierName('Variable name','A',A.Identifier);
  CheckClass(I.TrueBranch,TSQLExitStatement);
end;

procedure TTestProcedureStatement.TestIfBlock;

Var
  I : TSQLIfStatement;
  C : TSQLBinaryExpression;
  E : TSQLLiteralExpression;
  A : TSQLIdentifierExpression;
  LI : TSQLIntegerLiteral;
  B : TSQLStatementBlock;

begin
  I:=TSQLIfStatement(CheckClass(TestStatement('IF (A=1) THEN BEGIN EXIT; END'),TSQLIfStatement));
  C:=TSQLBinaryExpression(CheckClass(I.Condition,TSQLBinaryExpression));
  TestContext.AssertTrue((boEq)=(C.Operation), 'Equals');
  E:=TSQLLiteralExpression(CheckClass(C.Right,TSQLLiteralExpression));
  LI:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(LI.Value), 'Correct value');
  A:=TSQLIdentifierExpression(CheckClass(C.Left,TSQLIdentifierExpression));
  AssertIdentifierName('Variable name','A',A.Identifier);
  B:=TSQLStatementBlock(CheckClass(I.TrueBranch,TSQLStatementBlock));
  TestContext.AssertTrue((1)=(B.Statements.Count), '1 statement');
  CheckClass(B.Statements[0],TSQLExitStatement);
end;

procedure TTestProcedureStatement.TestIfElse;
Var
  I : TSQLIfStatement;
  C : TSQLBinaryExpression;
  E : TSQLLiteralExpression;
  A : TSQLIdentifierExpression;
  LI : TSQLIntegerLiteral;
begin
  I:=TSQLIfStatement(CheckClass(TestStatement('IF (A=1) THEN EXIT; ELSE SUSPEND'),TSQLIfStatement));
  C:=TSQLBinaryExpression(CheckClass(I.Condition,TSQLBinaryExpression));
  TestContext.AssertTrue((boEq)=(C.Operation), 'Equals');
  E:=TSQLLiteralExpression(CheckClass(C.Right,TSQLLiteralExpression));
  LI:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(LI.Value), 'Correct value');
  A:=TSQLIdentifierExpression(CheckClass(C.Left,TSQLIdentifierExpression));
  AssertIdentifierName('Variable name','A',A.Identifier);
  CheckClass(I.TrueBranch,TSQLExitStatement);
  CheckClass(I.FalseBranch,TSQLSuspendStatement);
end;

procedure TTestProcedureStatement.TestIfBlockElse;

Var
  I : TSQLIfStatement;
  C : TSQLBinaryExpression;
  E : TSQLLiteralExpression;
  A : TSQLIdentifierExpression;
  LI : TSQLIntegerLiteral;
  B : TSQLStatementBlock;

begin
  I:=TSQLIfStatement(CheckClass(TestStatement('IF (A=1) THEN BEGIN EXIT; END ELSE SUSPEND'),TSQLIfStatement));
  C:=TSQLBinaryExpression(CheckClass(I.Condition,TSQLBinaryExpression));
  TestContext.AssertTrue((boEq)=(C.Operation), 'Equals');
  E:=TSQLLiteralExpression(CheckClass(C.Right,TSQLLiteralExpression));
  LI:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(LI.Value), 'Correct value');
  A:=TSQLIdentifierExpression(CheckClass(C.Left,TSQLIdentifierExpression));
  AssertIdentifierName('Variable name','A',A.Identifier);
  B:=TSQLStatementBlock(CheckClass(I.TrueBranch,TSQLStatementBlock));
  TestContext.AssertTrue((1)=(B.Statements.Count), '1 statement');
  CheckClass(B.Statements[0],TSQLExitStatement);
  CheckClass(I.FalseBranch,TSQLSuspendStatement);
end;

procedure TTestProcedureStatement.TestIfElseError;
begin
  TestStatementError('IF (A=B) THEN EXIT ELSE SUSPEND');
  TestStatementError('IF (A=B) THEN BEGIN EXIT; END; ELSE SUSPEND');
end;

procedure TTestProcedureStatement.TestIfBlockElseBlock;

Var
  I : TSQLIfStatement;
  C : TSQLBinaryExpression;
  E : TSQLLiteralExpression;
  A : TSQLIdentifierExpression;
  LI : TSQLIntegerLiteral;
  B : TSQLStatementBlock;

begin
  I:=TSQLIfStatement(CheckClass(TestStatement('IF (A=1) THEN BEGIN EXIT; END ELSE BEGIN SUSPEND; END'),TSQLIfStatement));
  C:=TSQLBinaryExpression(CheckClass(I.Condition,TSQLBinaryExpression));
  TestContext.AssertTrue((boEq)=(C.Operation), 'Equals');
  E:=TSQLLiteralExpression(CheckClass(C.Right,TSQLLiteralExpression));
  LI:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(LI.Value), 'Correct value');
  A:=TSQLIdentifierExpression(CheckClass(C.Left,TSQLIdentifierExpression));
  AssertIdentifierName('Variable name','A',A.Identifier);
  B:=TSQLStatementBlock(CheckClass(I.TrueBranch,TSQLStatementBlock));
  TestContext.AssertTrue((1)=(B.Statements.Count), '1 statement');
  CheckClass(B.Statements[0],TSQLExitStatement);
  B:=TSQLStatementBlock(CheckClass(I.FalseBranch,TSQLStatementBlock));
  TestContext.AssertTrue((1)=(B.Statements.Count), '1 statement');
  CheckClass(B.Statements[0],TSQLSuspendStatement);
end;

procedure TTestProcedureStatement.TestIfErrorBracketLeft;
begin
  TestStatementError('IF A=1) THEN EXIT');
end;

procedure TTestProcedureStatement.TestIfErrorBracketRight;
begin
  TestStatementError('IF (A=1 THEN EXIT');
end;

procedure TTestProcedureStatement.TestIfErrorNoThen;
begin
  TestStatementError('IF (A=1) EXIT');
end;

procedure TTestProcedureStatement.TestIfErrorSemicolonElse;
begin
  TestStatementError('IF (A=1) THEN EXIT; ELSE SUSPEND');
end;

procedure TTestProcedureStatement.TestWhile;

Var
  W : TSQLWhileStatement;
  C : TSQLBinaryExpression;
  E : TSQLLiteralExpression;
  A : TSQLIdentifierExpression;
  LI : TSQLIntegerLiteral;
  SA : TSQLAssignStatement;

begin
  W:=TSQLWhileStatement(CheckClass(TestStatement('WHILE (A>1) DO A=A-1'),TSQLWhileStatement));
  C:=TSQLBinaryExpression(CheckClass(W.Condition,TSQLBinaryExpression));
  TestContext.AssertTrue((boGT)=(C.Operation), 'Equals');
  E:=TSQLLiteralExpression(CheckClass(C.Right,TSQLLiteralExpression));
  LI:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(LI.Value), 'Correct value');
  A:=TSQLIdentifierExpression(CheckClass(C.Left,TSQLIdentifierExpression));
  AssertIdentifierName('Variable name','A',A.Identifier);
  SA:=TSQLAssignStatement(CheckClass(W.Statement,TSQLAssignStatement));
  AssertIdentifierName('Variable name','A',SA.Variable);
  // Check assignment expression
  C:=TSQLBinaryExpression(CheckClass(SA.Expression,TSQLBinaryExpression));
  TestContext.AssertTrue((boAdd)=(C.Operation), 'Equals');
  // Left operand
  A:=TSQLIdentifierExpression(CheckClass(C.Left,TSQLIdentifierExpression));
  AssertIdentifierName('Variable name','A',A.Identifier);
  // Right operand
  E:=TSQLLiteralExpression(CheckClass(C.Right,TSQLLiteralExpression));
  LI:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((-1)=(LI.Value), 'Correct value');
end;

procedure TTestProcedureStatement.TestWhileBlock;

Var
  W  : TSQLWhileStatement;
  C  : TSQLBinaryExpression;
  E  : TSQLLiteralExpression;
  A  : TSQLIdentifierExpression;
  LI : TSQLIntegerLiteral;
  SA : TSQLAssignStatement;
  B  : TSQLStatementBlock;

begin
  W:=TSQLWhileStatement(CheckClass(TestStatement('WHILE (A>1) DO BEGIN A=A-1; END'),TSQLWhileStatement));
  C:=TSQLBinaryExpression(CheckClass(W.Condition,TSQLBinaryExpression));
  TestContext.AssertTrue((boGT)=(C.Operation), 'Equals');
  E:=TSQLLiteralExpression(CheckClass(C.Right,TSQLLiteralExpression));
  LI:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((1)=(LI.Value), 'Correct value');
  A:=TSQLIdentifierExpression(CheckClass(C.Left,TSQLIdentifierExpression));
  AssertIdentifierName('Variable name','A',A.Identifier);
  B:=TSQLStatementBlock(CheckClass(W.Statement,TSQLStatementBlock));
  TestContext.AssertTrue((1)=(B.Statements.Count), 'One statement');
  SA:=TSQLAssignStatement(CheckClass(B.Statements[0],TSQLAssignStatement));
  AssertIdentifierName('Variable name','A',SA.Variable);
  // Check assignment expression
  C:=TSQLBinaryExpression(CheckClass(SA.Expression,TSQLBinaryExpression));
  TestContext.AssertTrue((boAdd)=(C.Operation), 'Equals');
  // Left operand
  A:=TSQLIdentifierExpression(CheckClass(C.Left,TSQLIdentifierExpression));
  AssertIdentifierName('Variable name','A',A.Identifier);
  // Right operand
  E:=TSQLLiteralExpression(CheckClass(C.Right,TSQLLiteralExpression));
  LI:=TSQLIntegerLiteral(CheckClass(E.Literal,TSQLIntegerLiteral));
  TestContext.AssertTrue((-1)=(LI.Value), 'Correct value');
end;

procedure TTestProcedureStatement.TestWhileErrorBracketLeft;
begin
  TestStatementError('WHILE A>1) DO A=A-1');
end;

procedure TTestProcedureStatement.TestWhileErrorBracketRight;
begin
  TestStatementError('WHILE (A>1 DO A=A-1');
end;

procedure TTestProcedureStatement.TestWhileErrorNoDo;
begin
  TestStatementError('WHILE (A>1) A=A-1');
end;

procedure TTestProcedureStatement.TestWhenAny;
Var
  W : TSQLWhenStatement;
begin
  W:=TSQLWhenStatement(CheckClass(TestStatement('WHEN ANY DO EXIT'),TSQLWhenStatement));
  TestContext.AssertTrue((0)=(W.Errors.Count), 'No error codes');
  TestContext.AssertTrue((True)=(W.AnyError), 'Any error');
  CheckClass(W.Statement,TSQLExitStatement);
end;

procedure TTestProcedureStatement.TestWhenSQLCode;
Var
  W : TSQLWhenStatement;
  E : TSQLWhenSQLError;

begin
  W:=TSQLWhenStatement(CheckClass(TestStatement('WHEN SQLCODE 1 DO EXIT'),TSQLWhenStatement));
  TestContext.AssertTrue((False)=(W.AnyError), 'Not Any error');
  TestContext.AssertTrue((1)=(W.Errors.Count), '1 error code');
  CheckClass(W.Statement,TSQLExitStatement);
  E:=TSQLWhenSQLError(CheckClass(W.Errors[0],TSQLWhenSQLError));
  TestContext.AssertTrue((1)=(E.ErrorCode), 'Correct SQL Code');
end;

procedure TTestProcedureStatement.TestWhenGDSCode;
Var
  W : TSQLWhenStatement;
  E : TSQLWhenGDSError;

begin
  W:=TSQLWhenStatement(CheckClass(TestStatement('WHEN GDSCODE 1 DO EXIT'),TSQLWhenStatement));
  TestContext.AssertTrue((False)=(W.AnyError), 'Not Any error');
  TestContext.AssertTrue((1)=(W.Errors.Count), '1 error code');
  CheckClass(W.Statement,TSQLExitStatement);
  E:=TSQLWhenGDSError(CheckClass(W.Errors[0],TSQLWhenGDSError));
  TestContext.AssertTrue((1)=(E.GDSErrorNumber), 'Correct SQL Code');
end;

procedure TTestProcedureStatement.TestWhenException;
Var
  W : TSQLWhenStatement;
  E : TSQLWhenException;

begin
  W:=TSQLWhenStatement(CheckClass(TestStatement('WHEN EXCEPTION MYE DO EXIT'),TSQLWhenStatement));
  TestContext.AssertTrue((False)=(W.AnyError), 'Not Any error');
  TestContext.AssertTrue((1)=(W.Errors.Count), '1 error code');
  CheckClass(W.Statement,TSQLExitStatement);
  E:=TSQLWhenException(CheckClass(W.Errors[0],TSQLWhenException));
  AssertIdentifierName('Correct SQL Code','MYE',E.ExceptionName);
end;

procedure TTestProcedureStatement.TestWhenExceptionGDS;
Var
  W : TSQLWhenStatement;
  E : TSQLWhenException;
  G : TSQLWhenGDSError;

begin
  W:=TSQLWhenStatement(CheckClass(TestStatement('WHEN EXCEPTION MYE, GDSCODE 1 DO EXIT'),TSQLWhenStatement));
  TestContext.AssertTrue((False)=(W.AnyError), 'Not Any error');
  TestContext.AssertTrue((2)=(W.Errors.Count), '2 error code');
  CheckClass(W.Statement,TSQLExitStatement);
  E:=TSQLWhenException(CheckClass(W.Errors[0],TSQLWhenException));
  AssertIdentifierName('Correct SQL Code','MYE',E.ExceptionName);
  G:=TSQLWhenGDSError(CheckClass(W.Errors[1],TSQLWhenGDSError));
  TestContext.AssertTrue((1)=(G.GDSErrorNumber), 'Correct SQL Code');
end;

procedure TTestProcedureStatement.TestWhenAnyBlock;

Var
  W : TSQLWhenStatement;
  B : TSQLStatementBlock;

begin
  W:=TSQLWhenStatement(CheckClass(TestStatement('WHEN ANY DO BEGIN EXIT; END'),TSQLWhenStatement));
  TestContext.AssertTrue((0)=(W.Errors.Count), 'No error codes');
  TestContext.AssertTrue((True)=(W.AnyError), 'Any error');
  B:=TSQLStatementBlock(CheckClass(W.Statement,TSQLStatementBlock));
  TestContext.AssertTrue((1)=(B.Statements.Count), 'One statement');
  CheckClass(B.Statements[0],TSQLExitStatement);
end;

procedure TTestProcedureStatement.TestWhenErrorAny;
begin
  TestStatementError('WHEN ANY, EXCEPTION MY DO EXIT');
end;

procedure TTestProcedureStatement.TestWhenErrorNoDo;

begin
  TestStatementError('WHEN ANY EXIT');
end;

procedure TTestProcedureStatement.TestWhenErrorExceptionInt;
begin
  TestStatementError('WHEN EXCEPTION 1 DO EXIT');
end;

procedure TTestProcedureStatement.TestWhenErrorExceptionString;
begin
  TestStatementError('WHEN EXCEPTION ''1'' DO EXIT');
end;

procedure TTestProcedureStatement.TestWhenErrorSqlCode;
begin
  TestStatementError('WHEN SQLCODE A DO EXIT');
end;

procedure TTestProcedureStatement.TestWhenErrorGDSCode;
begin
  TestStatementError('WHEN GDSCODE A DO EXIT');
end;

procedure TTestProcedureStatement.TestExecuteStatement;

Var
  E : TSQLExecuteProcedureStatement;

begin
  E:=TSQLExecuteProcedureStatement(CheckClass(TestStatement('EXECUTE PROCEDURE A'),TSQLExecuteProcedureStatement));
  AssertIDentifierName('Correct procedure','A',E.ProcedureName);
end;

procedure TTestProcedureStatement.TestExecuteStatementReturningValues;

Var
  E : TSQLExecuteProcedureStatement;

begin
  E:=TSQLExecuteProcedureStatement(CheckClass(TestStatement('EXECUTE PROCEDURE A RETURNING_VALUES B'),TSQLExecuteProcedureStatement));
  AssertIDentifierName('Correct procedure','A',E.ProcedureName);
  TestContext.AssertTrue((1)=(E.Returning.Count), 'Returning 1 value');
  AssertIDentifierName('Correct return value','B',E.Returning[0]);
end;
procedure TTestProcedureStatement.TestExecuteStatementReturningValuesColon;

Var
  E : TSQLExecuteProcedureStatement;

begin
  E:=TSQLExecuteProcedureStatement(CheckClass(TestStatement('EXECUTE PROCEDURE A RETURNING_VALUES :B'),TSQLExecuteProcedureStatement));
  AssertIDentifierName('Correct procedure','A',E.ProcedureName);
  TestContext.AssertTrue((1)=(E.Returning.Count), 'Returning 1 value');
  AssertIDentifierName('Correct return value','B',E.Returning[0]);
end;

procedure TTestProcedureStatement.TestExecuteStatementReturningValuesBrackets;

Var
  E : TSQLExecuteProcedureStatement;

begin
  E:=TSQLExecuteProcedureStatement(CheckClass(TestStatement('EXECUTE PROCEDURE A RETURNING_VALUES (:B)'),TSQLExecuteProcedureStatement));
  AssertIDentifierName('Correct procedure','A',E.ProcedureName);
  TestContext.AssertTrue((1)=(E.Returning.Count), 'Returning 1 value');
  AssertIDentifierName('Correct return value','B',E.Returning[0]);
end;

procedure TTestProcedureStatement.TestForSimple;
Var
  F : TSQLForStatement;
  P : TSQLPostEventStatement;

begin
  F:=TSQLForStatement(CheckClass(TestStatement('FOR SELECT A FROM B INTO :C DO POST_EVENT C'),TSQLForStatement));
  TestContext.AssertTrue((1)=(F.Select.Fields.Count), 'Field count');
  TestContext.AssertTrue((1)=(F.Select.Tables.Count), 'Table count');
  AssertField(F.Select.Fields[0],'A','');
  AssertTable(F.Select.Tables[0],'B','');
  TestContext.AssertTrue((1)=(F.FieldList.Count), 'Into Fieldlist count');
  AssertIdentifierName('Correct field name','C',F.FieldList[0]);
  P:=TSQLPostEventStatement(CheckClass(F.Statement,TSQLPostEventStatement));
  AssertIdentifierName('Event name','C',P.ColName);
end;

procedure TTestProcedureStatement.TestForSimpleNoColon;
Var
  F : TSQLForStatement;
  P : TSQLPostEventStatement;

begin
  F:=TSQLForStatement(CheckClass(TestStatement('FOR SELECT A FROM B INTO C DO POST_EVENT C'),TSQLForStatement));
  TestContext.AssertTrue((1)=(F.Select.Fields.Count), 'Field count');
  TestContext.AssertTrue((1)=(F.Select.Tables.Count), 'Table count');
  AssertField(F.Select.Fields[0],'A','');
  AssertTable(F.Select.Tables[0],'B','');
  TestContext.AssertTrue((1)=(F.FieldList.Count), 'Into Fieldlist count');
  AssertIdentifierName('Correct field name','C',F.FieldList[0]);
  P:=TSQLPostEventStatement(CheckClass(F.Statement,TSQLPostEventStatement));
  AssertIdentifierName('Event name','C',P.ColName);
end;

procedure TTestProcedureStatement.TestForSimple2fields;
Var
  F : TSQLForStatement;
  P : TSQLPostEventStatement;

begin
  F:=TSQLForStatement(CheckClass(TestStatement('FOR SELECT A,B FROM C INTO :D,:E DO POST_EVENT D'),TSQLForStatement));
  TestContext.AssertTrue((2)=(F.Select.Fields.Count), 'Field count');
  TestContext.AssertTrue((1)=(F.Select.Tables.Count), 'Table count');
  AssertField(F.Select.Fields[0],'A','');
  AssertField(F.Select.Fields[1],'B','');
  AssertTable(F.Select.Tables[0],'C','');
  TestContext.AssertTrue((2)=(F.FieldList.Count), 'Into Fieldlist count');
  AssertIdentifierName('Correct field name','D',F.FieldList[0]);
  AssertIdentifierName('Correct field name','E',F.FieldList[1]);
  P:=TSQLPostEventStatement(CheckClass(F.Statement,TSQLPostEventStatement));
  AssertIdentifierName('Event name','D',P.ColName);
end;

procedure TTestProcedureStatement.TestForBlock;
Var
  F : TSQLForStatement;
  P : TSQLPostEventStatement;
  B : TSQLStatementBlock;

begin
  F:=TSQLForStatement(CheckClass(TestStatement('FOR SELECT A FROM B INTO :C DO BEGIN POST_EVENT C; END'),TSQLForStatement));
  TestContext.AssertTrue((1)=(F.Select.Fields.Count), 'Field count');
  TestContext.AssertTrue((1)=(F.Select.Tables.Count), 'Table count');
  AssertField(F.Select.Fields[0],'A','');
  AssertTable(F.Select.Tables[0],'B','');
  TestContext.AssertTrue((1)=(F.FieldList.Count), 'Into Fieldlist count');
  AssertIdentifierName('Correct field name','C',F.FieldList[0]);
  B:=TSQLStatementBlock(CheckClass(F.Statement,TSQLStatementBlock));
  TestContext.AssertTrue((1)=(B.Statements.Count), 'One statement');
  P:=TSQLPostEventStatement(CheckClass(B.Statements[0],TSQLPostEventStatement));
  AssertIdentifierName('Event name','C',P.ColName);
end;

{ TTestCreateProcedureParser }

function TTestCreateProcedureParser.TestCreate(const ASource: String
  ): TSQLCreateProcedureStatement;
begin
  CreateParser(ASource);
  FToFree:=Parser.Parse;
  Result:=TSQLCreateProcedureStatement(CheckClass(FToFree,TSQLCreateProcedureStatement));
  FSTatement:=Result;
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestCreateProcedureParser.TestCreateError(const ASource: String
  );
begin
  FErrSource:=ASource;
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestCreateProcedureParser.TestEmptyProcedure;

begin
  TestCreate('CREATE PROCEDURE A AS BEGIN END');
  AssertIdentifierName('Correct procedure name','A',Statement.ObjectName);
  TestContext.AssertTrue((0)=(Statement.InputVariables.Count), 'No arguments');
  TestContext.AssertTrue((0)=(Statement.OutputVariables.Count), 'No return values');
  TestContext.AssertTrue((0)=(Statement.LocalVariables.Count), 'No local variables');
  TestContext.AssertTrue((0)=(Statement.Statements.Count), 'No statements');
end;

procedure TTestCreateProcedureParser.TestExitProcedure;

begin
  TestCreate('CREATE PROCEDURE A AS BEGIN EXIT; END');
  AssertIdentifierName('Correct procedure name','A',Statement.ObjectName);
  TestContext.AssertTrue((0)=(Statement.InputVariables.Count), 'No arguments');
  TestContext.AssertTrue((0)=(Statement.OutputVariables.Count), 'No return values');
  TestContext.AssertTrue((0)=(Statement.LocalVariables.Count), 'No local variables');
  TestContext.AssertTrue((1)=(Statement.Statements.Count), 'One statement');
  CheckClass(Statement.Statements[0],TSQLExitStatement);
end;

procedure TTestCreateProcedureParser.TestProcedureOneArgument;

Var
  P : TSQLProcedureParamDef;

begin
  TestCreate('CREATE PROCEDURE A (P INT) AS BEGIN END');
  AssertIdentifierName('Correct procedure name','A',Statement.ObjectName);
  TestContext.AssertTrue((1)=(Statement.InputVariables.Count), '1 arguments');
  P:=TSQLProcedureParamDef(CheckClass(Statement.InputVariables[0],TSQLProcedureParamDef));
  AssertIdentifierName('Correct parameter name','P',P.ParamName);
  TestContext.AssertTrue((P.ParamType)<>nil, 'Have type definition');
  TestContext.AssertTrue((sdtInteger)=(P.ParamType.DataType), 'Correct type');
  TestContext.AssertTrue((0)=(Statement.OutputVariables.Count), 'No return values');
  TestContext.AssertTrue((0)=(Statement.LocalVariables.Count), 'No local variables');
  TestContext.AssertTrue((0)=(Statement.Statements.Count), 'No statements');
end;

procedure TTestCreateProcedureParser.TestProcedureTwoArguments;
Var
  P : TSQLProcedureParamDef;

begin
  TestCreate('CREATE PROCEDURE A (P INT,Q CHAR(4)) AS BEGIN END');
  AssertIdentifierName('Correct procedure name','A',Statement.ObjectName);
  TestContext.AssertTrue((2)=(Statement.InputVariables.Count), 'Two arguments');
  P:=TSQLProcedureParamDef(CheckClass(Statement.InputVariables[0],TSQLProcedureParamDef));
  AssertIdentifierName('Correct parameter name','P',P.ParamName);
  TestContext.AssertTrue((P.ParamType)<>nil, 'Have type definition');
  TestContext.AssertTrue((sdtInteger)=(P.ParamType.DataType), 'Correct type');
  TestContext.AssertTrue((0)=(Statement.OutputVariables.Count), 'No return values');
  P:=TSQLProcedureParamDef(CheckClass(Statement.InputVariables[1],TSQLProcedureParamDef));
  AssertIdentifierName('Correct parameter name','Q',P.ParamName);
  TestContext.AssertTrue((P.ParamType)<>nil, 'Have type definition');
  TestContext.AssertTrue((sdtChar)=(P.ParamType.DataType), 'Correct type');
  TestContext.AssertTrue((4)=(P.ParamType.Len), 'Correct length');
  //
  TestContext.AssertTrue((0)=(Statement.LocalVariables.Count), 'No local variables');
  TestContext.AssertTrue((0)=(Statement.Statements.Count), 'No statements');
end;

procedure TTestCreateProcedureParser.TestProcedureOneReturnValue;
Var
  P : TSQLProcedureParamDef;

begin
  TestCreate('CREATE PROCEDURE A RETURNS (P INT) AS BEGIN END');
  AssertIdentifierName('Correct procedure name','A',Statement.ObjectName);
  TestContext.AssertTrue((1)=(Statement.OutputVariables.Count), '1 return value');
  P:=TSQLProcedureParamDef(CheckClass(Statement.OutputVariables[0],TSQLProcedureParamDef));
  AssertIdentifierName('Correct parameter name','P',P.ParamName);
  TestContext.AssertTrue((P.ParamType)<>nil, 'Have type definition');
  TestContext.AssertTrue((sdtInteger)=(P.ParamType.DataType), 'Correct type');
  TestContext.AssertTrue((0)=(Statement.InputVariables.Count), 'No input values');
  TestContext.AssertTrue((0)=(Statement.LocalVariables.Count), 'No local variables');
  TestContext.AssertTrue((0)=(Statement.Statements.Count), 'No statements');
end;

procedure TTestCreateProcedureParser.TestProcedureTwoReturnValues;
Var
  P : TSQLProcedureParamDef;

begin
  TestCreate('CREATE PROCEDURE A RETURNS (P INT, Q CHAR(5)) AS BEGIN END');
  AssertIdentifierName('Correct procedure name','A',Statement.ObjectName);
  TestContext.AssertTrue((2)=(Statement.OutputVariables.Count), '2 return values');
  P:=TSQLProcedureParamDef(CheckClass(Statement.OutputVariables[0],TSQLProcedureParamDef));
  AssertIdentifierName('Correct parameter name','P',P.ParamName);
  TestContext.AssertTrue((P.ParamType)<>nil, 'Have type definition');
  TestContext.AssertTrue((sdtInteger)=(P.ParamType.DataType), 'Correct type');
  P:=TSQLProcedureParamDef(CheckClass(Statement.OutputVariables[1],TSQLProcedureParamDef));
  AssertIdentifierName('Correct parameter name','Q',P.ParamName);
  TestContext.AssertTrue((P.ParamType)<>nil, 'Have type definition');
  TestContext.AssertTrue((sdtChar)=(P.ParamType.DataType), 'Correct type');
  TestContext.AssertTrue((5)=(P.ParamType.Len), 'Correct length');
  TestContext.AssertTrue((0)=(Statement.InputVariables.Count), 'No input values');
  TestContext.AssertTrue((0)=(Statement.LocalVariables.Count), 'No local variables');
  TestContext.AssertTrue((0)=(Statement.Statements.Count), 'No statements');
end;

procedure TTestCreateProcedureParser.TestProcedureOneLocalVariable;
Var
  P : TSQLProcedureParamDef;

begin
  TestCreate('CREATE PROCEDURE A AS DECLARE VARIABLE P INT; BEGIN END');
  AssertIdentifierName('Correcte procedure naam','A',Statement.ObjectName);
  TestContext.AssertTrue((0)=(Statement.OutputVariables.Count), '0 return values');
  TestContext.AssertTrue((1)=(Statement.LocalVariables.Count), '1 local variable');
  P:=TSQLProcedureParamDef(CheckClass(Statement.LocalVariables[0],TSQLProcedureParamDef));
  AssertIdentifierName('Correct parameter name','P',P.ParamName);
  TestContext.AssertTrue((P.ParamType)<>nil, 'Have type definition');
  TestContext.AssertTrue((sdtInteger)=(P.ParamType.DataType), 'Correct type');
  TestContext.AssertTrue((0)=(Statement.InputVariables.Count), 'No input values');
  TestContext.AssertTrue((0)=(Statement.Statements.Count), 'No statements');
end;

procedure TTestCreateProcedureParser.TestProcedureTwoLocalVariable;
Var
  P : TSQLProcedureParamDef;

begin
  TestCreate('CREATE PROCEDURE A AS DECLARE VARIABLE P INT; DECLARE VARIABLE Q CHAR(5); BEGIN END');
  AssertIdentifierName('Correcte procedure naam','A',Statement.ObjectName);
  TestContext.AssertTrue((0)=(Statement.OutputVariables.Count), '0 return values');
  TestContext.AssertTrue((2)=(Statement.LocalVariables.Count), '2 local variable');
  P:=TSQLProcedureParamDef(CheckClass(Statement.LocalVariables[0],TSQLProcedureParamDef));
  AssertIdentifierName('Correct parameter name','P',P.ParamName);
  TestContext.AssertTrue((P.ParamType)<>nil, 'Have type definition');
  TestContext.AssertTrue((sdtInteger)=(P.ParamType.DataType), 'Correct type');
  P:=TSQLProcedureParamDef(CheckClass(Statement.LocalVariables[1],TSQLProcedureParamDef));
  AssertIdentifierName('Correct parameter name','Q',P.ParamName);
  TestContext.AssertTrue((P.ParamType)<>nil, 'Have type definition');
  TestContext.AssertTrue((sdtChar)=(P.ParamType.DataType), 'Correct type');
  TestContext.AssertTrue((5)=(P.ParamType.Len), 'Correct length');
  TestContext.AssertTrue((0)=(Statement.InputVariables.Count), 'No input values');
  TestContext.AssertTrue((0)=(Statement.Statements.Count), 'No statements');
end;

procedure TTestCreateProcedureParser.TestProcedureInputOutputLocal;

Var
  P : TSQLProcedureParamDef;

begin
  TestCreate('CREATE PROCEDURE A (P INT) RETURNS (Q CHAR(5)) AS DECLARE VARIABLE R VARCHAR(5); BEGIN END');
  AssertIdentifierName('Correcte procedure naam','A',Statement.ObjectName);
  // Input
  TestContext.AssertTrue((1)=(Statement.InputVariables.Count), '1 input value');
  P:=TSQLProcedureParamDef(CheckClass(Statement.InputVariables[0],TSQLProcedureParamDef));
  AssertIdentifierName('Correct parameter name','P',P.ParamName);
  TestContext.AssertTrue((P.ParamType)<>nil, 'Have type definition');
  TestContext.AssertTrue((sdtInteger)=(P.ParamType.DataType), 'Correct type');
  // Output
  TestContext.AssertTrue((1)=(Statement.OutputVariables.Count), '1 return values');
  P:=TSQLProcedureParamDef(CheckClass(Statement.OutputVariables[0],TSQLProcedureParamDef));
  AssertIdentifierName('Correct parameter name','Q',P.ParamName);
  TestContext.AssertTrue((P.ParamType)<>nil, 'Have type definition');
  TestContext.AssertTrue((sdtChar)=(P.ParamType.DataType), 'Correct type');
  TestContext.AssertTrue((5)=(P.ParamType.Len), 'Correct length');
  // Local
  TestContext.AssertTrue((1)=(Statement.LocalVariables.Count), '1 local variable');
  P:=TSQLProcedureParamDef(CheckClass(Statement.LocalVariables[0],TSQLProcedureParamDef));
  AssertIdentifierName('Correct parameter name','R',P.ParamName);
  TestContext.AssertTrue((P.ParamType)<>nil, 'Have type definition');
  TestContext.AssertTrue((sdtvarChar)=(P.ParamType.DataType), 'Correct type');
  TestContext.AssertTrue((5)=(P.ParamType.Len), 'Correct length');
  TestContext.AssertTrue((0)=(Statement.Statements.Count), 'No statements');
end;

{ TTestCreateTriggerParser }

function TTestCreateTriggerParser.TestCreate(const ASource: String
  ): TSQLCreateTriggerStatement;
begin
  CreateParser(ASource);
  FToFree:=Parser.Parse;
  Result:=TSQLCreateTriggerStatement(CheckClass(FToFree,TSQLCreateTriggerStatement));
  FSTatement:=Result;
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

function TTestCreateTriggerParser.TestAlter(const ASource: String
  ): TSQLAlterTriggerStatement;
begin
  CreateParser(ASource);
  FToFree:=Parser.Parse;
  Result:=TSQLAlterTriggerStatement(CheckClass(FToFree,TSQLAlterTriggerStatement));
  FSTatement:=Result;
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestCreateTriggerParser.TestCreateError(const ASource: String);
begin
  FErrSource:=ASource;
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestCreateTriggerParser.TestEmptyTrigger;
begin
  TestCreate('CREATE TRIGGER A FOR B BEFORE UPDATE AS BEGIN END');
  AssertIdentifierName('Correct trigger name','A',Statement.ObjectName);
  AssertIdentifierName('Correct table','B',Statement.TableName);
  TestContext.AssertTrue((0)=(Statement.LocalVariables.Count), 'No variables');
  TestContext.AssertTrue((0)=(Statement.Statements.Count), 'No Statements');
  TestContext.AssertTrue((0)=(Statement.Position), 'No position');
  TestContext.AssertTrue((tsNone)=(Statement.State), 'No active/inactive');
  TestContext.AssertTrue((tmBefore)=(Statement.Moment), 'Before moment');
  TestContext.AssertTrue(([toUpdate])=(Statement.Operations), 'Update operation');
end;

procedure TTestCreateTriggerParser.TestExitTrigger;
begin
  TestCreate('CREATE TRIGGER A FOR B BEFORE UPDATE AS BEGIN EXIT; END');
  AssertIdentifierName('Correct trigger name','A',Statement.ObjectName);
  AssertIdentifierName('Correct table','B',Statement.TableName);
  TestContext.AssertTrue((0)=(Statement.LocalVariables.Count), 'No variables');
  TestContext.AssertTrue((1)=(Statement.Statements.Count), '1 Statements');
  TestContext.AssertTrue((0)=(Statement.Position), 'No position');
  TestContext.AssertTrue((tsNone)=(Statement.State), 'No active/inactive');
  TestContext.AssertTrue((tmBefore)=(Statement.Moment), 'Before moment');
  TestContext.AssertTrue(([toUpdate])=(Statement.Operations), 'Update operation');
  CheckClass(Statement.Statements[0],TSQLExitStatement);
end;

procedure TTestCreateTriggerParser.TestEmptyTriggerAfterUpdate;
begin
  TestCreate('CREATE TRIGGER A FOR B AFTER UPDATE AS BEGIN END');
  AssertIdentifierName('Correct trigger name','A',Statement.ObjectName);
  AssertIdentifierName('Correct table','B',Statement.TableName);
  TestContext.AssertTrue((0)=(Statement.LocalVariables.Count), 'No variables');
  TestContext.AssertTrue((0)=(Statement.Statements.Count), 'No Statements');
  TestContext.AssertTrue((0)=(Statement.Position), 'No position');
  TestContext.AssertTrue((tsNone)=(Statement.State), 'No active/inactive');
  TestContext.AssertTrue((tmAfter)=(Statement.Moment), 'Before moment');
  TestContext.AssertTrue(([toUpdate])=(Statement.Operations), 'Update operation');
end;

procedure TTestCreateTriggerParser.TestEmptyTriggerBeforeDelete;
begin
  TestCreate('CREATE TRIGGER A FOR B BEFORE DELETE AS BEGIN END');
  AssertIdentifierName('Correct trigger name','A',Statement.ObjectName);
  AssertIdentifierName('Correct table','B',Statement.TableName);
  TestContext.AssertTrue((0)=(Statement.LocalVariables.Count), 'No variables');
  TestContext.AssertTrue((0)=(Statement.Statements.Count), 'No Statements');
  TestContext.AssertTrue((0)=(Statement.Position), 'No position');
  TestContext.AssertTrue((tsNone)=(Statement.State), 'No active/inactive');
  TestContext.AssertTrue((tmBefore)=(Statement.Moment), 'Before moment');
  TestContext.AssertTrue(([toDelete])=(Statement.Operations), 'Delete operation');
end;

procedure TTestCreateTriggerParser.TestEmptyTriggerBeforeInsert;
begin
  TestCreate('CREATE TRIGGER A FOR B BEFORE INSERT AS BEGIN END');
  AssertIdentifierName('Correct trigger name','A',Statement.ObjectName);
  AssertIdentifierName('Correct table','B',Statement.TableName);
  TestContext.AssertTrue((0)=(Statement.LocalVariables.Count), 'No variables');
  TestContext.AssertTrue((0)=(Statement.Statements.Count), 'No Statements');
  TestContext.AssertTrue((0)=(Statement.Position), 'No position');
  TestContext.AssertTrue((tsNone)=(Statement.State), 'No active/inactive');
  TestContext.AssertTrue((tmBefore)=(Statement.Moment), 'Before moment');
  TestContext.AssertTrue(([toInsert])=(Statement.Operations), 'Insert operation');
end;

procedure TTestCreateTriggerParser.TestEmptyTriggerBeforeInsertPosition1;
begin
  TestCreate('CREATE TRIGGER A FOR B BEFORE INSERT POSITION 1 AS BEGIN END');
  AssertIdentifierName('Correct trigger name','A',Statement.ObjectName);
  AssertIdentifierName('Correct table','B',Statement.TableName);
  TestContext.AssertTrue((0)=(Statement.LocalVariables.Count), 'No variables');
  TestContext.AssertTrue((0)=(Statement.Statements.Count), 'No Statements');
  TestContext.AssertTrue((1)=(Statement.Position), 'position 1');
  TestContext.AssertTrue((tsNone)=(Statement.State), 'No active/inactive');
  TestContext.AssertTrue((tmBefore)=(Statement.Moment), 'Before moment');
  TestContext.AssertTrue(([toInsert])=(Statement.Operations), 'Insert operation');
end;

procedure TTestCreateTriggerParser.TestEmptyTriggerBeforeInsertPosition1inActive;
begin
  TestCreate('CREATE TRIGGER A FOR B INACTIVE BEFORE INSERT POSITION 1 AS BEGIN END');
  AssertIdentifierName('Correct trigger name','A',Statement.ObjectName);
  AssertIdentifierName('Correct table','B',Statement.TableName);
  TestContext.AssertTrue((0)=(Statement.LocalVariables.Count), 'No variables');
  TestContext.AssertTrue((0)=(Statement.Statements.Count), 'No Statements');
  TestContext.AssertTrue((1)=(Statement.Position), 'position 1');
  TestContext.AssertTrue((tsInactive)=(Statement.State), 'inactive');
  TestContext.AssertTrue((tmBefore)=(Statement.Moment), 'Before moment');
  TestContext.AssertTrue(([toInsert])=(Statement.Operations), 'Insert operation');
end;

procedure TTestCreateTriggerParser.TestEmptyTriggerBeforeInsertPosition1Active;
begin
  TestCreate('CREATE TRIGGER A FOR B ACTIVE BEFORE INSERT POSITION 1 AS BEGIN END');
  AssertIdentifierName('Correct trigger name','A',Statement.ObjectName);
  AssertIdentifierName('Correct table','B',Statement.TableName);
  TestContext.AssertTrue((0)=(Statement.LocalVariables.Count), 'No variables');
  TestContext.AssertTrue((0)=(Statement.Statements.Count), 'No Statements');
  TestContext.AssertTrue((1)=(Statement.Position), 'position 1');
  TestContext.AssertTrue((tsActive)=(Statement.State), 'Active');
  TestContext.AssertTrue((tmBefore)=(Statement.Moment), 'Before moment');
  TestContext.AssertTrue(([toInsert])=(Statement.Operations), 'Insert operation');
end;

procedure TTestCreateTriggerParser.TestTriggerOneLocalVariable;

Var
  P : TSQLProcedureParamDef;

begin
  TestCreate('CREATE TRIGGER A FOR B ACTIVE BEFORE INSERT POSITION 1 AS DECLARE VARIABLE P INT; BEGIN END');
  AssertIdentifierName('Correcte procedure naam','A',Statement.ObjectName);
  AssertIdentifierName('Correct table','B',Statement.TableName);
  TestContext.AssertTrue((0)=(Statement.Statements.Count), 'No Statements');
  TestContext.AssertTrue((1)=(Statement.Position), 'position 1');
  TestContext.AssertTrue((tsActive)=(Statement.State), 'Active');
  TestContext.AssertTrue((tmBefore)=(Statement.Moment), 'Before moment');
  TestContext.AssertTrue(([toInsert])=(Statement.Operations), 'Insert operation');
  TestContext.AssertTrue((1)=(Statement.LocalVariables.Count), '1 local variable');
  P:=TSQLProcedureParamDef(CheckClass(Statement.LocalVariables[0],TSQLProcedureParamDef));
  AssertIdentifierName('Correct parameter name','P',P.ParamName);
  TestContext.AssertTrue((P.ParamType)<>nil, 'Have type definition');
  TestContext.AssertTrue((sdtInteger)=(P.ParamType.DataType), 'Correct type');
end;

procedure TTestCreateTriggerParser.TestTriggerTwoLocalVariables;
Var
  P : TSQLProcedureParamDef;

begin
  TestCreate('CREATE TRIGGER A FOR B ACTIVE BEFORE INSERT POSITION 1 AS DECLARE VARIABLE P INT; DECLARE VARIABLE Q INT; BEGIN END');
  AssertIdentifierName('Correcte procedure naam','A',Statement.ObjectName);
  AssertIdentifierName('Correct table','B',Statement.TableName);
  TestContext.AssertTrue((0)=(Statement.Statements.Count), 'No Statements');
  TestContext.AssertTrue((1)=(Statement.Position), 'position 1');
  TestContext.AssertTrue((tsActive)=(Statement.State), 'Active');
  TestContext.AssertTrue((tmBefore)=(Statement.Moment), 'Before moment');
  TestContext.AssertTrue(([toInsert])=(Statement.Operations), 'Insert operation');
  TestContext.AssertTrue((2)=(Statement.LocalVariables.Count), '2 local variables');
  P:=TSQLProcedureParamDef(CheckClass(Statement.LocalVariables[0],TSQLProcedureParamDef));
  AssertIdentifierName('Correct parameter name','P',P.ParamName);
  TestContext.AssertTrue((P.ParamType)<>nil, 'Have type definition');
  TestContext.AssertTrue((sdtInteger)=(P.ParamType.DataType), 'Correct type');
  P:=TSQLProcedureParamDef(CheckClass(Statement.LocalVariables[1],TSQLProcedureParamDef));
  AssertIdentifierName('Correct parameter name','Q',P.ParamName);
  TestContext.AssertTrue((P.ParamType)<>nil, 'Have type definition');
  TestContext.AssertTrue((sdtInteger)=(P.ParamType.DataType), 'Correct type');
end;

procedure TTestCreateTriggerParser.TestAlterTrigger;
begin
  TestAlter('ALTER TRIGGER A BEFORE UPDATE AS BEGIN END');
  AssertIdentifierName('Correct trigger name','A',Statement.ObjectName);
  TestContext.AssertTrue((Statement.TableName)=nil, 'Correct table');
  TestContext.AssertTrue((0)=(Statement.LocalVariables.Count), 'No variables');
  TestContext.AssertTrue((0)=(Statement.Statements.Count), 'No Statements');
  TestContext.AssertTrue((0)=(Statement.Position), 'No position');
  TestContext.AssertTrue((tsNone)=(Statement.State), 'No active/inactive');
  TestContext.AssertTrue((tmBefore)=(Statement.Moment), 'Before moment');
  TestContext.AssertTrue(([toUpdate])=(Statement.Operations), 'Update operation');

end;

{ TTestDeclareExternalFunctionParser }

function TTestDeclareExternalFunctionParser.TestCreate(const ASource: String
  ): TSQLDeclareExternalFunctionStatement;
begin
  CreateParser(ASource);
  FToFree:=Parser.Parse;
  Result:=TSQLDeclareExternalFunctionStatement(CheckClass(FToFree,TSQLDeclareExternalFunctionStatement));
  FSTatement:=Result;
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestDeclareExternalFunctionParser.TestCreateError(
  const ASource: String);
begin
  FErrSource:=ASource;
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestDeclareExternalFunctionParser.TestEmptyfunction;
begin
  TestCreate('DECLARE EXTERNAL FUNCTION A RETURNS INT ENTRY_POINT ''A'' MODULE_NAME ''B''');
  AssertIdentifierName('Correct function','A',Statement.ObjectName);
  TestContext.AssertTrue(('A')=(Statement.EntryPoint), 'Correct entry point');
  TestContext.AssertTrue(('B')=(Statement.ModuleName), 'Correct module name');
  TestContext.AssertTrue((0)=(Statement.Arguments.Count), 'No arguments');
  TestContext.AssertTrue((Statement.ReturnType)<>nil, 'Have return type');
  TestContext.AssertTrue((False)=(Statement.FreeIt), 'No FreeIt');
  TestContext.AssertTrue((sdtInteger)=(Statement.ReturnType.DataType), 'Correct return type');
end;

procedure TTestDeclareExternalFunctionParser.TestEmptyfunctionByValue;
begin
  TestCreate('DECLARE EXTERNAL FUNCTION A RETURNS INT BY VALUE ENTRY_POINT ''A'' MODULE_NAME ''B''');
  AssertIdentifierName('Correct function','A',Statement.ObjectName);
  TestContext.AssertTrue(('A')=(Statement.EntryPoint), 'Correct entry point');
  TestContext.AssertTrue(('B')=(Statement.ModuleName), 'Correct module name');
  TestContext.AssertTrue((0)=(Statement.Arguments.Count), 'No arguments');
  TestContext.AssertTrue((Statement.ReturnType)<>nil, 'Have return type');
  TestContext.AssertTrue((False)=(Statement.FreeIt), 'No FreeIt');
  TestContext.AssertTrue((sdtInteger)=(Statement.ReturnType.DataType), 'Correct return type');
  TestContext.AssertTrue((True)=(Statement.ReturnType.ByValue), 'By Value');
end;

procedure TTestDeclareExternalFunctionParser.TestCStringfunction;

begin
  TestCreate('DECLARE EXTERNAL FUNCTION A RETURNS CSTRING (50) ENTRY_POINT ''A'' MODULE_NAME ''B''');
  AssertIdentifierName('Correct function','A',Statement.ObjectName);
  TestContext.AssertTrue(('A')=(Statement.EntryPoint), 'Correct entry point');
  TestContext.AssertTrue(('B')=(Statement.ModuleName), 'Correct module name');
  TestContext.AssertTrue((0)=(Statement.Arguments.Count), 'No arguments');
  TestContext.AssertTrue((Statement.ReturnType)<>nil, 'Have return type');
  TestContext.AssertTrue((False)=(Statement.FreeIt), 'No FreeIt');
  TestContext.AssertTrue((sdtCstring)=(Statement.ReturnType.DataType), 'Correct return type');
  TestContext.AssertTrue((50)=(Statement.ReturnType.Len), 'Correct return length');
end;

procedure TTestDeclareExternalFunctionParser.TestCStringFreeItfunction;
begin
  TestCreate('DECLARE EXTERNAL FUNCTION A RETURNS CSTRING (50) FREE_IT ENTRY_POINT ''A'' MODULE_NAME ''B''');
  AssertIdentifierName('Correct function','A',Statement.ObjectName);
  TestContext.AssertTrue(('A')=(Statement.EntryPoint), 'Correct entry point');
  TestContext.AssertTrue(('B')=(Statement.ModuleName), 'Correct module name');
  TestContext.AssertTrue((0)=(Statement.Arguments.Count), 'No arguments');
  TestContext.AssertTrue((Statement.ReturnType)<>nil, 'Have return type');
  TestContext.AssertTrue((True)=(Statement.FreeIt), 'FreeIt');
  TestContext.AssertTrue((sdtCstring)=(Statement.ReturnType.DataType), 'Correct return type');
  TestContext.AssertTrue((50)=(Statement.ReturnType.Len), 'Correct return length');
end;

procedure TTestDeclareExternalFunctionParser.TestOneArgumentFunction;

Var
  T : TSQLTypeDefinition;

begin
  TestCreate('DECLARE EXTERNAL FUNCTION A INT RETURNS INT ENTRY_POINT ''A'' MODULE_NAME ''B''');
  AssertIdentifierName('Correct function','A',Statement.ObjectName);
  TestContext.AssertTrue(('A')=(Statement.EntryPoint), 'Correct entry point');
  TestContext.AssertTrue(('B')=(Statement.ModuleName), 'Correct module name');
  TestContext.AssertTrue((1)=(Statement.Arguments.Count), '1 argument');
  T:=TSQLTypeDefinition(CheckClass(Statement.Arguments[0],TSQLTypeDefinition));
  TestContext.AssertTrue((sdtInteger)=(T.DataType), 'Correct return type');
  TestContext.AssertTrue((Statement.ReturnType)<>nil, 'Have return type');
  TestContext.AssertTrue((False)=(Statement.FreeIt), 'No FreeIt');
  TestContext.AssertTrue((sdtInteger)=(Statement.ReturnType.DataType), 'Correct return type');
end;

procedure TTestDeclareExternalFunctionParser.TestTwoArgumentsFunction;

Var
  T : TSQLTypeDefinition;

begin
  TestCreate('DECLARE EXTERNAL FUNCTION A INT, CSTRING(10) RETURNS INT ENTRY_POINT ''A'' MODULE_NAME ''B''');
  AssertIdentifierName('Correct function','A',Statement.ObjectName);
  TestContext.AssertTrue(('A')=(Statement.EntryPoint), 'Correct entry point');
  TestContext.AssertTrue(('B')=(Statement.ModuleName), 'Correct module name');
  TestContext.AssertTrue((2)=(Statement.Arguments.Count), '2 arguments');
  T:=TSQLTypeDefinition(CheckClass(Statement.Arguments[0],TSQLTypeDefinition));
  TestContext.AssertTrue((sdtInteger)=(T.DataType), 'Correct argument type');
  T:=TSQLTypeDefinition(CheckClass(Statement.Arguments[1],TSQLTypeDefinition));
  TestContext.AssertTrue((sdtCstring)=(T.DataType), 'Correct return type');
  TestContext.AssertTrue((10)=(T.Len), 'Correct argument length');
  TestContext.AssertTrue((Statement.ReturnType)<>nil, 'Have return type');
  TestContext.AssertTrue((False)=(Statement.FreeIt), 'No FreeIt');
  TestContext.AssertTrue((sdtInteger)=(Statement.ReturnType.DataType), 'Correct return type');
end;

{ TTestGrantParser }

function TTestGrantParser.TestGrant(const ASource: String): TSQLGrantStatement;
begin
  CreateParser(ASource);
  FToFree:=Parser.Parse;
  If not (FToFree is  TSQLGrantStatement) then
    TestContext.Fail(Format('Wrong parse result class. Expected TSQLGrantStatement, got %s',[FTofree.ClassName]));
  Result:=TSQLGrantStatement(Ftofree);
  FSTatement:=Result;
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestGrantParser.TestGrantError(const ASource: String);
begin
  FErrSource:=ASource;
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestGrantParser.TestSimple;

Var
  t : TSQLTableGrantStatement;
  G : TSQLUSerGrantee;

begin
  TestGrant('GRANT SELECT ON A TO B');
  T:=TSQLTableGrantStatement(CheckClass(Statement,TSQLTableGrantStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLSelectPrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No grant option');
end;

procedure TTestGrantParser.Test2Operations;

Var
  t : TSQLTableGrantStatement;
  G : TSQLUSerGrantee;

begin
  TestGrant('GRANT SELECT,INSERT ON A TO B');
  T:=TSQLTableGrantStatement(CheckClass(Statement,TSQLTableGrantStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((2)=(T.Privileges.Count), 'Two permissions');
  CheckClass(T.Privileges[0],TSQLSelectPrivilege);
  CheckClass(T.Privileges[1],TSQLINSERTPrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No grant option');
end;

procedure TTestGrantParser.TestDeletePrivilege;

Var
  t : TSQLTableGrantStatement;
  G : TSQLUSerGrantee;

begin
  TestGrant('GRANT DELETE ON A TO B');
  T:=TSQLTableGrantStatement(CheckClass(Statement,TSQLTableGrantStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLDeletePrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No grant option');
end;

procedure TTestGrantParser.TestUpdatePrivilege;
Var
  t : TSQLTableGrantStatement;
  G : TSQLUSerGrantee;

begin
  TestGrant('GRANT UPDATE ON A TO B');
  T:=TSQLTableGrantStatement(CheckClass(Statement,TSQLTableGrantStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLUPDATEPrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No grant option');
end;

procedure TTestGrantParser.TestInsertPrivilege;

Var
  t : TSQLTableGrantStatement;
  G : TSQLUSerGrantee;

begin
  TestGrant('GRANT INSERT ON A TO B');
  T:=TSQLTableGrantStatement(CheckClass(Statement,TSQLTableGrantStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLInsertPrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No grant option');
end;

procedure TTestGrantParser.TestReferencePrivilege;
Var
  t : TSQLTableGrantStatement;
  G : TSQLUSerGrantee;

begin
  TestGrant('GRANT REFERENCES ON A TO B');
  T:=TSQLTableGrantStatement(CheckClass(Statement,TSQLTableGrantStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLReferencePrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No grant option');
end;

procedure TTestGrantParser.TestAllPrivileges;
Var
  t : TSQLTableGrantStatement;
  G : TSQLUSerGrantee;

begin
  TestGrant('GRANT ALL ON A TO B');
  T:=TSQLTableGrantStatement(CheckClass(Statement,TSQLTableGrantStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLAllPrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No grant option');
end;

procedure TTestGrantParser.TestAllPrivileges2;
Var
  t : TSQLTableGrantStatement;
  G : TSQLUSerGrantee;

begin
  TestGrant('GRANT ALL PRIVILEGES ON A TO B');
  T:=TSQLTableGrantStatement(CheckClass(Statement,TSQLTableGrantStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLAllPrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No grant option');
end;

procedure TTestGrantParser.TestUpdateColPrivilege;
Var
  t : TSQLTableGrantStatement;
  G : TSQLUSerGrantee;
  U : TSQLUPDATEPrivilege;

begin
  TestGrant('GRANT UPDATE (C) ON A TO B');
  T:=TSQLTableGrantStatement(CheckClass(Statement,TSQLTableGrantStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  U:=TSQLUPDATEPrivilege(CheckClass(T.Privileges[0],TSQLUPDATEPrivilege));
  TestContext.AssertTrue((1)=(U.Columns.Count), '1 column');
  AssertIdentifierName('Column C','C',U.Columns[0]);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No grant option');
end;

procedure TTestGrantParser.TestUpdate2ColsPrivilege;
Var
  t : TSQLTableGrantStatement;
  G : TSQLUSerGrantee;
  U : TSQLUPDATEPrivilege;

begin
  TestGrant('GRANT UPDATE (C,D) ON A TO B');
  T:=TSQLTableGrantStatement(CheckClass(Statement,TSQLTableGrantStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  U:=TSQLUPDATEPrivilege(CheckClass(T.Privileges[0],TSQLUPDATEPrivilege));
  TestContext.AssertTrue((2)=(U.Columns.Count), '2 column');
  AssertIdentifierName('Column C','C',U.Columns[0]);
  AssertIdentifierName('Column D','D',U.Columns[1]);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No grant option');
end;

procedure TTestGrantParser.TestReferenceColPrivilege;
Var
  t : TSQLTableGrantStatement;
  G : TSQLUSerGrantee;
  U : TSQLReferencePrivilege;

begin
  TestGrant('GRANT REFERENCES (C) ON A TO B');
  T:=TSQLTableGrantStatement(CheckClass(Statement,TSQLTableGrantStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  U:=TSQLReferencePrivilege(CheckClass(T.Privileges[0],TSQLReferencePrivilege));
  TestContext.AssertTrue((1)=(U.Columns.Count), '1 column');
  AssertIdentifierName('Column C','C',U.Columns[0]);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No grant option');
end;

procedure TTestGrantParser.TestReference2ColsPrivilege;
Var
  t : TSQLTableGrantStatement;
  G : TSQLUSerGrantee;
  U : TSQLReferencePrivilege;

begin
  TestGrant('GRANT REFERENCES (C,D) ON A TO B');
  T:=TSQLTableGrantStatement(CheckClass(Statement,TSQLTableGrantStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  U:=TSQLReferencePrivilege(CheckClass(T.Privileges[0],TSQLReferencePrivilege));
  TestContext.AssertTrue((2)=(U.Columns.Count), '2 column');
  AssertIdentifierName('Column C','C',U.Columns[0]);
  AssertIdentifierName('Column D','D',U.Columns[1]);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No grant option');
end;

procedure TTestGrantParser.TestUserPrivilege;

Var
  t : TSQLTableGrantStatement;
  G : TSQLUSerGrantee;

begin
    TestGrant('GRANT SELECT ON A TO USER B');
    T:=TSQLTableGrantStatement(CheckClass(Statement,TSQLTableGrantStatement));
    AssertIdentifierName('Table name','A',T.TableName);
    TestContext.AssertTrue((1)=(T.Grantees.Count), 'One grantee');
    G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
    TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
    TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
    CheckClass(T.Privileges[0],TSQLSelectPrivilege);
    TestContext.AssertTrue((False)=(T.GrantOption), 'No grant option');
end;

procedure TTestGrantParser.TestUserPrivilegeWithGrant;
Var
  t : TSQLTableGrantStatement;
  G : TSQLUSerGrantee;

begin
    TestGrant('GRANT SELECT ON A TO USER B WITH GRANT OPTION');
    T:=TSQLTableGrantStatement(CheckClass(Statement,TSQLTableGrantStatement));
    AssertIdentifierName('Table name','A',T.TableName);
    TestContext.AssertTrue((1)=(T.Grantees.Count), 'One grantee');
    G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
    TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
    TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
    CheckClass(T.Privileges[0],TSQLSelectPrivilege);
    TestContext.AssertTrue((True)=(T.GrantOption), 'With grant option');
end;

procedure TTestGrantParser.TestGroupPrivilege;

Var
  t : TSQLTableGrantStatement;
  G : TSQLGroupGrantee;

begin
    TestGrant('GRANT SELECT ON A TO GROUP B');
    T:=TSQLTableGrantStatement(CheckClass(Statement,TSQLTableGrantStatement));
    AssertIdentifierName('Table name','A',T.TableName);
    TestContext.AssertTrue((1)=(T.Grantees.Count), 'One grantee');
    G:=TSQLGroupGrantee(CheckClass(T.Grantees[0],TSQLGroupGrantee));
    TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
    TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
    CheckClass(T.Privileges[0],TSQLSelectPrivilege);
    TestContext.AssertTrue((False)=(T.GrantOption), 'No grant option');
end;

procedure TTestGrantParser.TestProcedurePrivilege;
Var
  t : TSQLTableGrantStatement;
  G : TSQLProcedureGrantee;

begin
  TestGrant('GRANT SELECT ON A TO PROCEDURE B');
  T:=TSQLTableGrantStatement(CheckClass(Statement,TSQLTableGrantStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One grantee');
  G:=TSQLProcedureGrantee(CheckClass(T.Grantees[0],TSQLProcedureGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLSelectPrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No grant option');
end;

procedure TTestGrantParser.TestViewPrivilege;
Var
  t : TSQLTableGrantStatement;
  G : TSQLViewGrantee;

begin
  TestGrant('GRANT SELECT ON A TO VIEW B');
  T:=TSQLTableGrantStatement(CheckClass(Statement,TSQLTableGrantStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One grantee');
  G:=TSQLViewGrantee(CheckClass(T.Grantees[0],TSQLViewGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLSelectPrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No grant option');
end;

procedure TTestGrantParser.TestTriggerPrivilege;

Var
  t : TSQLTableGrantStatement;
  G : TSQLTriggerGrantee;

begin
  TestGrant('GRANT SELECT ON A TO TRIGGER B');
  T:=TSQLTableGrantStatement(CheckClass(Statement,TSQLTableGrantStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One grantee');
  G:=TSQLTriggerGrantee(CheckClass(T.Grantees[0],TSQLTriggerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLSelectPrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No grant option');
end;

procedure TTestGrantParser.TestPublicPrivilege;
Var
  t : TSQLTableGrantStatement;
begin
  TestGrant('GRANT SELECT ON A TO PUBLIC');
  T:=TSQLTableGrantStatement(CheckClass(Statement,TSQLTableGrantStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One grantee');
  (CheckClass(T.Grantees[0],TSQLPublicGrantee));
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLSelectPrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No grant option');
end;

procedure TTestGrantParser.TestExecuteToUser;
Var
  P : TSQLProcedureGrantStatement;
  U : TSQLUserGrantee;

begin
  TestGrant('GRANT EXECUTE ON PROCEDURE A TO B');
  P:=TSQLProcedureGrantStatement(CheckClass(Statement,TSQLProcedureGrantStatement));
  AssertIdentifierName('Procedure name','A',P.ProcedureName);
  TestContext.AssertTrue((1)=(P.Grantees.Count), 'One grantee');
  U:=TSQLUserGrantee(CheckClass(P.Grantees[0],TSQLUserGrantee));
  TestContext.AssertTrue(('B')=(U.Name), 'User name');
  TestContext.AssertTrue((False)=(P.GrantOption), 'No grant option');
end;

procedure TTestGrantParser.TestExecuteToProcedure;
Var
  P : TSQLProcedureGrantStatement;
  U : TSQLProcedureGrantee;

begin
  TestGrant('GRANT EXECUTE ON PROCEDURE A TO PROCEDURE B');
  P:=TSQLProcedureGrantStatement(CheckClass(Statement,TSQLProcedureGrantStatement));
  AssertIdentifierName('Procedure name','A',P.ProcedureName);
  TestContext.AssertTrue((1)=(P.Grantees.Count), 'One grantee');
  U:=TSQLProcedureGrantee(CheckClass(P.Grantees[0],TSQLProcedureGrantee));
  TestContext.AssertTrue(('B')=(U.Name), 'Procedure grantee name');
  TestContext.AssertTrue((False)=(P.GrantOption), 'No grant option');
end;

procedure TTestGrantParser.TestRoleToUser;
Var
  R : TSQLRoleGrantStatement;
  U : TSQLUserGrantee;

begin
  TestGrant('GRANT A TO B');
  R:=TSQLRoleGrantStatement(CheckClass(Statement,TSQLRoleGrantStatement));
  TestContext.AssertTrue((1)=(R.Roles.Count), 'One role');
  AssertIdentifierName('Role name','A',R.Roles[0]);
  TestContext.AssertTrue((1)=(R.Grantees.Count), 'One grantee');
  U:=TSQLUserGrantee(CheckClass(R.Grantees[0],TSQLUserGrantee));
  TestContext.AssertTrue(('B')=(U.Name), 'Procedure grantee name');
  TestContext.AssertTrue((False)=(R.AdminOption), 'No admin option');
end;

procedure TTestGrantParser.TestRoleToUserWithAdmin;
Var
  R : TSQLRoleGrantStatement;
  U : TSQLUserGrantee;

begin
  TestGrant('GRANT A TO B WITH ADMIN OPTION');
  R:=TSQLRoleGrantStatement(CheckClass(Statement,TSQLRoleGrantStatement));
  TestContext.AssertTrue((1)=(R.Roles.Count), 'One role');
  AssertIdentifierName('Role name','A',R.Roles[0]);
  TestContext.AssertTrue((1)=(R.Grantees.Count), 'One grantee');
  U:=TSQLUserGrantee(CheckClass(R.Grantees[0],TSQLUserGrantee));
  TestContext.AssertTrue(('B')=(U.Name), 'Procedure grantee name');
  TestContext.AssertTrue((True)=(R.AdminOption), 'Admin option');
end;

procedure TTestGrantParser.TestRoleToPublic;
Var
  R : TSQLRoleGrantStatement;

begin
  TestGrant('GRANT A TO PUBLIC');
  R:=TSQLRoleGrantStatement(CheckClass(Statement,TSQLRoleGrantStatement));
  TestContext.AssertTrue((1)=(R.Roles.Count), 'One role');
  AssertIdentifierName('Role name','A',R.Roles[0]);
  TestContext.AssertTrue((1)=(R.Grantees.Count), 'One grantee');
  CheckClass(R.Grantees[0],TSQLPublicGrantee);
  TestContext.AssertTrue((False)=(R.AdminOption), 'No admin option');
end;

procedure TTestGrantParser.Test2RolesToUser;

Var
  R : TSQLRoleGrantStatement;
  U : TSQLUserGrantee;

begin
  TestGrant('GRANT A,C TO B');
  R:=TSQLRoleGrantStatement(CheckClass(Statement,TSQLRoleGrantStatement));
  TestContext.AssertTrue((2)=(R.Roles.Count), '2 roles');
  AssertIdentifierName('Role name','A',R.Roles[0]);
  AssertIdentifierName('Role name','C',R.Roles[1]);
  TestContext.AssertTrue((1)=(R.Grantees.Count), 'One grantee');
  U:=TSQLUserGrantee(CheckClass(R.Grantees[0],TSQLUserGrantee));
  TestContext.AssertTrue(('B')=(U.Name), 'Procedure grantee name');
  TestContext.AssertTrue((False)=(R.AdminOption), 'No admin option');
end;

{ TTestRevokeParser }

function TTestRevokeParser.TestRevoke(const ASource: String): TSQLRevokeStatement;
begin
  CreateParser(ASource);
  FToFree:=Parser.Parse;
  If not (FToFree is  TSQLRevokeStatement) then
    TestContext.Fail(Format('Wrong parse result class. Expected TSQLRevokeStatement, got %s',[FTofree.ClassName]));
  Result:=TSQLRevokeStatement(Ftofree);
  FSTatement:=Result;
  TestContext.AssertTrue((tsqlEOF)=(Parser.CurrentToken), 'End of stream reached');
end;

procedure TTestRevokeParser.TestRevokeError(const ASource: String);
begin
  FErrSource:=ASource;
  TestContext.AssertRaises(ESQLParser, @TestParseError, '');
end;

procedure TTestRevokeParser.TestSimple;

Var
  t : TSQLTableRevokeStatement;
  G : TSQLUSerGrantee;

begin
  TestRevoke('Revoke SELECT ON A FROM B');
  T:=TSQLTableRevokeStatement(CheckClass(Statement,TSQLTableRevokeStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One Grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLSelectPrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No Revoke option');
end;

procedure TTestRevokeParser.Test2Operations;

Var
  t : TSQLTableRevokeStatement;
  G : TSQLUSerGrantee;

begin
  TestRevoke('Revoke SELECT,INSERT ON A FROM B');
  T:=TSQLTableRevokeStatement(CheckClass(Statement,TSQLTableRevokeStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One Grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((2)=(T.Privileges.Count), 'Two permissions');
  CheckClass(T.Privileges[0],TSQLSelectPrivilege);
  CheckClass(T.Privileges[1],TSQLINSERTPrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No Revoke option');
end;

procedure TTestRevokeParser.TestDeletePrivilege;

Var
  t : TSQLTableRevokeStatement;
  G : TSQLUSerGrantee;

begin
  TestRevoke('Revoke DELETE ON A FROM B');
  T:=TSQLTableRevokeStatement(CheckClass(Statement,TSQLTableRevokeStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One Grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLDeletePrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No Revoke option');
end;

procedure TTestRevokeParser.TestUpdatePrivilege;
Var
  t : TSQLTableRevokeStatement;
  G : TSQLUSerGrantee;

begin
  TestRevoke('Revoke UPDATE ON A FROM B');
  T:=TSQLTableRevokeStatement(CheckClass(Statement,TSQLTableRevokeStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One Grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLUPDATEPrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No Revoke option');
end;

procedure TTestRevokeParser.TestInsertPrivilege;

Var
  t : TSQLTableRevokeStatement;
  G : TSQLUSerGrantee;

begin
  TestRevoke('Revoke INSERT ON A FROM B');
  T:=TSQLTableRevokeStatement(CheckClass(Statement,TSQLTableRevokeStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One Grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLInsertPrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No Revoke option');
end;

procedure TTestRevokeParser.TestReferencePrivilege;
Var
  t : TSQLTableRevokeStatement;
  G : TSQLUSerGrantee;

begin
  TestRevoke('Revoke REFERENCES ON A FROM B');
  T:=TSQLTableRevokeStatement(CheckClass(Statement,TSQLTableRevokeStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One Grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLReferencePrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No Revoke option');
end;

procedure TTestRevokeParser.TestAllPrivileges;
Var
  t : TSQLTableRevokeStatement;
  G : TSQLUSerGrantee;

begin
  TestRevoke('Revoke ALL ON A FROM B');
  T:=TSQLTableRevokeStatement(CheckClass(Statement,TSQLTableRevokeStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One Grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLAllPrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No Revoke option');
end;

procedure TTestRevokeParser.TestAllPrivileges2;
Var
  t : TSQLTableRevokeStatement;
  G : TSQLUSerGrantee;

begin
  TestRevoke('Revoke ALL PRIVILEGES ON A FROM B');
  T:=TSQLTableRevokeStatement(CheckClass(Statement,TSQLTableRevokeStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One Grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLAllPrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No Revoke option');
end;

procedure TTestRevokeParser.TestUpdateColPrivilege;
Var
  t : TSQLTableRevokeStatement;
  G : TSQLUSerGrantee;
  U : TSQLUPDATEPrivilege;

begin
  TestRevoke('Revoke UPDATE (C) ON A FROM B');
  T:=TSQLTableRevokeStatement(CheckClass(Statement,TSQLTableRevokeStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One Grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  U:=TSQLUPDATEPrivilege(CheckClass(T.Privileges[0],TSQLUPDATEPrivilege));
  TestContext.AssertTrue((1)=(U.Columns.Count), '1 column');
  AssertIdentifierName('Column C','C',U.Columns[0]);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No Revoke option');
end;

procedure TTestRevokeParser.TestUpdate2ColsPrivilege;
Var
  t : TSQLTableRevokeStatement;
  G : TSQLUSerGrantee;
  U : TSQLUPDATEPrivilege;

begin
  TestRevoke('Revoke UPDATE (C,D) ON A FROM B');
  T:=TSQLTableRevokeStatement(CheckClass(Statement,TSQLTableRevokeStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One Grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  U:=TSQLUPDATEPrivilege(CheckClass(T.Privileges[0],TSQLUPDATEPrivilege));
  TestContext.AssertTrue((2)=(U.Columns.Count), '2 column');
  AssertIdentifierName('Column C','C',U.Columns[0]);
  AssertIdentifierName('Column D','D',U.Columns[1]);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No Revoke option');
end;

procedure TTestRevokeParser.TestReferenceColPrivilege;
Var
  t : TSQLTableRevokeStatement;
  G : TSQLUSerGrantee;
  U : TSQLReferencePrivilege;

begin
  TestRevoke('Revoke REFERENCES (C) ON A FROM B');
  T:=TSQLTableRevokeStatement(CheckClass(Statement,TSQLTableRevokeStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One Grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  U:=TSQLReferencePrivilege(CheckClass(T.Privileges[0],TSQLReferencePrivilege));
  TestContext.AssertTrue((1)=(U.Columns.Count), '1 column');
  AssertIdentifierName('Column C','C',U.Columns[0]);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No Revoke option');
end;

procedure TTestRevokeParser.TestReference2ColsPrivilege;
Var
  t : TSQLTableRevokeStatement;
  G : TSQLUSerGrantee;
  U : TSQLReferencePrivilege;

begin
  TestRevoke('Revoke REFERENCES (C,D) ON A FROM B');
  T:=TSQLTableRevokeStatement(CheckClass(Statement,TSQLTableRevokeStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One Grantee');
  G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  U:=TSQLReferencePrivilege(CheckClass(T.Privileges[0],TSQLReferencePrivilege));
  TestContext.AssertTrue((2)=(U.Columns.Count), '2 column');
  AssertIdentifierName('Column C','C',U.Columns[0]);
  AssertIdentifierName('Column D','D',U.Columns[1]);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No Revoke option');
end;

procedure TTestRevokeParser.TestUserPrivilege;

Var
  t : TSQLTableRevokeStatement;
  G : TSQLUSerGrantee;

begin
    TestRevoke('Revoke SELECT ON A FROM USER B');
    T:=TSQLTableRevokeStatement(CheckClass(Statement,TSQLTableRevokeStatement));
    AssertIdentifierName('Table name','A',T.TableName);
    TestContext.AssertTrue((1)=(T.Grantees.Count), 'One Grantee');
    G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
    TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
    TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
    CheckClass(T.Privileges[0],TSQLSelectPrivilege);
    TestContext.AssertTrue((False)=(T.GrantOption), 'No Revoke option');
end;

procedure TTestRevokeParser.TestUserPrivilegeWithRevoke;
Var
  t : TSQLTableRevokeStatement;
  G : TSQLUSerGrantee;

begin
    TestRevoke('Revoke GRANT OPTION FOR SELECT ON A FROM USER B');
    T:=TSQLTableRevokeStatement(CheckClass(Statement,TSQLTableRevokeStatement));
    AssertIdentifierName('Table name','A',T.TableName);
    TestContext.AssertTrue((1)=(T.Grantees.Count), 'One Grantee');
    G:=TSQLUSerGrantee(CheckClass(T.Grantees[0],TSQLUSerGrantee));
    TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
    TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
    CheckClass(T.Privileges[0],TSQLSelectPrivilege);
    TestContext.AssertTrue((True)=(T.GrantOption), 'With Revoke option');
end;

procedure TTestRevokeParser.TestGroupPrivilege;

Var
  t : TSQLTableRevokeStatement;
  G : TSQLGroupGrantee;

begin
    TestRevoke('Revoke SELECT ON A FROM GROUP B');
    T:=TSQLTableRevokeStatement(CheckClass(Statement,TSQLTableRevokeStatement));
    AssertIdentifierName('Table name','A',T.TableName);
    TestContext.AssertTrue((1)=(T.Grantees.Count), 'One Grantee');
    G:=TSQLGroupGrantee(CheckClass(T.Grantees[0],TSQLGroupGrantee));
    TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
    TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
    CheckClass(T.Privileges[0],TSQLSelectPrivilege);
    TestContext.AssertTrue((False)=(T.GrantOption), 'No Revoke option');
end;

procedure TTestRevokeParser.TestProcedurePrivilege;
Var
  t : TSQLTableRevokeStatement;
  G : TSQLProcedureGrantee;

begin
  TestRevoke('Revoke SELECT ON A FROM PROCEDURE B');
  T:=TSQLTableRevokeStatement(CheckClass(Statement,TSQLTableRevokeStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One Grantee');
  G:=TSQLProcedureGrantee(CheckClass(T.Grantees[0],TSQLProcedureGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLSelectPrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No Revoke option');
end;

procedure TTestRevokeParser.TestViewPrivilege;
Var
  t : TSQLTableRevokeStatement;
  G : TSQLViewGrantee;

begin
  TestRevoke('Revoke SELECT ON A FROM VIEW B');
  T:=TSQLTableRevokeStatement(CheckClass(Statement,TSQLTableRevokeStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One Grantee');
  G:=TSQLViewGrantee(CheckClass(T.Grantees[0],TSQLViewGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLSelectPrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No Revoke option');
end;

procedure TTestRevokeParser.TestTriggerPrivilege;

Var
  t : TSQLTableRevokeStatement;
  G : TSQLTriggerGrantee;

begin
  TestRevoke('Revoke SELECT ON A FROM TRIGGER B');
  T:=TSQLTableRevokeStatement(CheckClass(Statement,TSQLTableRevokeStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One Grantee');
  G:=TSQLTriggerGrantee(CheckClass(T.Grantees[0],TSQLTriggerGrantee));
  TestContext.AssertTrue(('B')=(G.Name), 'Grantee B');
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLSelectPrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No Revoke option');
end;

procedure TTestRevokeParser.TestPublicPrivilege;
Var
  t : TSQLTableRevokeStatement;
begin
  TestRevoke('Revoke SELECT ON A FROM PUBLIC');
  T:=TSQLTableRevokeStatement(CheckClass(Statement,TSQLTableRevokeStatement));
  AssertIdentifierName('Table name','A',T.TableName);
  TestContext.AssertTrue((1)=(T.Grantees.Count), 'One Grantee');
  (CheckClass(T.Grantees[0],TSQLPublicGrantee));
  TestContext.AssertTrue((1)=(T.Privileges.Count), 'One permission');
  CheckClass(T.Privileges[0],TSQLSelectPrivilege);
  TestContext.AssertTrue((False)=(T.GrantOption), 'No Revoke option');
end;

procedure TTestRevokeParser.TestExecuteToUser;
Var
  P : TSQLProcedureRevokeStatement;
  U : TSQLUserGrantee;

begin
  TestRevoke('Revoke EXECUTE ON PROCEDURE A FROM B');
  P:=TSQLProcedureRevokeStatement(CheckClass(Statement,TSQLProcedureRevokeStatement));
  AssertIdentifierName('Procedure name','A',P.ProcedureName);
  TestContext.AssertTrue((1)=(P.Grantees.Count), 'One Grantee');
  U:=TSQLUserGrantee(CheckClass(P.Grantees[0],TSQLUserGrantee));
  TestContext.AssertTrue(('B')=(U.Name), 'User name');
  TestContext.AssertTrue((False)=(P.GrantOption), 'No Revoke option');
end;

procedure TTestRevokeParser.TestExecuteToProcedure;
Var
  P : TSQLProcedureRevokeStatement;
  U : TSQLProcedureGrantee;

begin
  TestRevoke('Revoke EXECUTE ON PROCEDURE A FROM PROCEDURE B');
  P:=TSQLProcedureRevokeStatement(CheckClass(Statement,TSQLProcedureRevokeStatement));
  AssertIdentifierName('Procedure name','A',P.ProcedureName);
  TestContext.AssertTrue((1)=(P.Grantees.Count), 'One Grantee');
  U:=TSQLProcedureGrantee(CheckClass(P.Grantees[0],TSQLProcedureGrantee));
  TestContext.AssertTrue(('B')=(U.Name), 'Procedure Grantee name');
  TestContext.AssertTrue((False)=(P.GrantOption), 'No Revoke option');
end;

procedure TTestRevokeParser.TestRoleToUser;
Var
  R : TSQLRoleRevokeStatement;
  U : TSQLUserGrantee;

begin
  TestRevoke('Revoke A FROM B');
  R:=TSQLRoleRevokeStatement(CheckClass(Statement,TSQLRoleRevokeStatement));
  TestContext.AssertTrue((1)=(R.Roles.Count), 'One role');
  AssertIdentifierName('Role name','A',R.Roles[0]);
  TestContext.AssertTrue((1)=(R.Grantees.Count), 'One Grantee');
  U:=TSQLUserGrantee(CheckClass(R.Grantees[0],TSQLUserGrantee));
  TestContext.AssertTrue(('B')=(U.Name), 'Procedure Grantee name');
  TestContext.AssertTrue((False)=(R.AdminOption), 'No admin option');
end;

procedure TTestRevokeParser.TestRoleToPublic;
Var
  R : TSQLRoleRevokeStatement;

begin
  TestRevoke('Revoke A FROM PUBLIC');
  R:=TSQLRoleRevokeStatement(CheckClass(Statement,TSQLRoleRevokeStatement));
  TestContext.AssertTrue((1)=(R.Roles.Count), 'One role');
  AssertIdentifierName('Role name','A',R.Roles[0]);
  TestContext.AssertTrue((1)=(R.Grantees.Count), 'One Grantee');
  CheckClass(R.Grantees[0],TSQLPublicGrantee);
  TestContext.AssertTrue((False)=(R.AdminOption), 'No admin option');
end;

procedure TTestRevokeParser.Test2RolesToUser;

Var
  R : TSQLRoleRevokeStatement;
  U : TSQLUserGrantee;

begin
  TestRevoke('Revoke A,C FROM B');
  R:=TSQLRoleRevokeStatement(CheckClass(Statement,TSQLRoleRevokeStatement));
  TestContext.AssertTrue((2)=(R.Roles.Count), '2 roles');
  AssertIdentifierName('Role name','A',R.Roles[0]);
  AssertIdentifierName('Role name','C',R.Roles[1]);
  TestContext.AssertTrue((1)=(R.Grantees.Count), 'One Grantee');
  U:=TSQLUserGrantee(CheckClass(R.Grantees[0],TSQLUserGrantee));
  TestContext.AssertTrue(('B')=(U.Name), 'Procedure Grantee name');
  TestContext.AssertTrue((False)=(R.AdminOption), 'No admin option');
end;



constructor TTestSQLParser.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestDropParserTestDropDatabase(AContext: TNXTestContext);
var lFixture: TTestDropParser;
begin
  lFixture:=TTestDropParser.Create(AContext, 'TestDropDatabase');
  try
    lFixture.SetUp;
    try lFixture.TestDropDatabase; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDropParserTestDropDomain(AContext: TNXTestContext);
var lFixture: TTestDropParser;
begin
  lFixture:=TTestDropParser.Create(AContext, 'TestDropDomain');
  try
    lFixture.SetUp;
    try lFixture.TestDropDomain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDropParserTestDropException(AContext: TNXTestContext);
var lFixture: TTestDropParser;
begin
  lFixture:=TTestDropParser.Create(AContext, 'TestDropException');
  try
    lFixture.SetUp;
    try lFixture.TestDropException; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDropParserTestDropGenerator(AContext: TNXTestContext);
var lFixture: TTestDropParser;
begin
  lFixture:=TTestDropParser.Create(AContext, 'TestDropGenerator');
  try
    lFixture.SetUp;
    try lFixture.TestDropGenerator; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDropParserTestDropIndex(AContext: TNXTestContext);
var lFixture: TTestDropParser;
begin
  lFixture:=TTestDropParser.Create(AContext, 'TestDropIndex');
  try
    lFixture.SetUp;
    try lFixture.TestDropIndex; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDropParserTestDropProcedure(AContext: TNXTestContext);
var lFixture: TTestDropParser;
begin
  lFixture:=TTestDropParser.Create(AContext, 'TestDropProcedure');
  try
    lFixture.SetUp;
    try lFixture.TestDropProcedure; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDropParserTestDropRole(AContext: TNXTestContext);
var lFixture: TTestDropParser;
begin
  lFixture:=TTestDropParser.Create(AContext, 'TestDropRole');
  try
    lFixture.SetUp;
    try lFixture.TestDropRole; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDropParserTestDropTable(AContext: TNXTestContext);
var lFixture: TTestDropParser;
begin
  lFixture:=TTestDropParser.Create(AContext, 'TestDropTable');
  try
    lFixture.SetUp;
    try lFixture.TestDropTable; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDropParserTestDropTrigger(AContext: TNXTestContext);
var lFixture: TTestDropParser;
begin
  lFixture:=TTestDropParser.Create(AContext, 'TestDropTrigger');
  try
    lFixture.SetUp;
    try lFixture.TestDropTrigger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDropParserTestDropView(AContext: TNXTestContext);
var lFixture: TTestDropParser;
begin
  lFixture:=TTestDropParser.Create(AContext, 'TestDropView');
  try
    lFixture.SetUp;
    try lFixture.TestDropView; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDropParserTestDropShadow(AContext: TNXTestContext);
var lFixture: TTestDropParser;
begin
  lFixture:=TTestDropParser.Create(AContext, 'TestDropShadow');
  try
    lFixture.SetUp;
    try lFixture.TestDropShadow; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDropParserTestDropExternalFunction(AContext: TNXTestContext);
var lFixture: TTestDropParser;
begin
  lFixture:=TTestDropParser.Create(AContext, 'TestDropExternalFunction');
  try
    lFixture.SetUp;
    try lFixture.TestDropExternalFunction; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGeneratorParserTestCreateGenerator(AContext: TNXTestContext);
var lFixture: TTestGeneratorParser;
begin
  lFixture:=TTestGeneratorParser.Create(AContext, 'TestCreateGenerator');
  try
    lFixture.SetUp;
    try lFixture.TestCreateGenerator; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGeneratorParserTestCreateSequence(AContext: TNXTestContext);
var lFixture: TTestGeneratorParser;
begin
  lFixture:=TTestGeneratorParser.Create(AContext, 'TestCreateSequence');
  try
    lFixture.SetUp;
    try lFixture.TestCreateSequence; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGeneratorParserTestAlterSequence(AContext: TNXTestContext);
var lFixture: TTestGeneratorParser;
begin
  lFixture:=TTestGeneratorParser.Create(AContext, 'TestAlterSequence');
  try
    lFixture.SetUp;
    try lFixture.TestAlterSequence; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGeneratorParserTestSetGenerator(AContext: TNXTestContext);
var lFixture: TTestGeneratorParser;
begin
  lFixture:=TTestGeneratorParser.Create(AContext, 'TestSetGenerator');
  try
    lFixture.SetUp;
    try lFixture.TestSetGenerator; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSetTermParserTestSetTermNoOption(AContext: TNXTestContext);
var lFixture: TTestSetTermParser;
begin
  lFixture:=TTestSetTermParser.Create(AContext, 'TestSetTermNoOption');
  try
    lFixture.SetUp;
    try lFixture.TestSetTermNoOption; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSetTermParserTestSetTermOption(AContext: TNXTestContext);
var lFixture: TTestSetTermParser;
begin
  lFixture:=TTestSetTermParser.Create(AContext, 'TestSetTermOption');
  try
    lFixture.SetUp;
    try lFixture.TestSetTermOption; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRoleParserTestCreateRole(AContext: TNXTestContext);
var lFixture: TTestRoleParser;
begin
  lFixture:=TTestRoleParser.Create(AContext, 'TestCreateRole');
  try
    lFixture.SetUp;
    try lFixture.TestCreateRole; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRoleParserTestAlterRole(AContext: TNXTestContext);
var lFixture: TTestRoleParser;
begin
  lFixture:=TTestRoleParser.Create(AContext, 'TestAlterRole');
  try
    lFixture.SetUp;
    try lFixture.TestAlterRole; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringType1(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringType1');
  try
    lFixture.SetUp;
    try lFixture.TestStringType1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringType2(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringType2');
  try
    lFixture.SetUp;
    try lFixture.TestStringType2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringType3(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringType3');
  try
    lFixture.SetUp;
    try lFixture.TestStringType3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringType4(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringType4');
  try
    lFixture.SetUp;
    try lFixture.TestStringType4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringType5(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringType5');
  try
    lFixture.SetUp;
    try lFixture.TestStringType5; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringType6(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringType6');
  try
    lFixture.SetUp;
    try lFixture.TestStringType6; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringType7(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringType7');
  try
    lFixture.SetUp;
    try lFixture.TestStringType7; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringType8(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringType8');
  try
    lFixture.SetUp;
    try lFixture.TestStringType8; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringType9(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringType9');
  try
    lFixture.SetUp;
    try lFixture.TestStringType9; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringType10(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringType10');
  try
    lFixture.SetUp;
    try lFixture.TestStringType10; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringType11(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringType11');
  try
    lFixture.SetUp;
    try lFixture.TestStringType11; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringType12(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringType12');
  try
    lFixture.SetUp;
    try lFixture.TestStringType12; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringType13(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringType13');
  try
    lFixture.SetUp;
    try lFixture.TestStringType13; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringType14(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringType14');
  try
    lFixture.SetUp;
    try lFixture.TestStringType14; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringType15(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringType15');
  try
    lFixture.SetUp;
    try lFixture.TestStringType15; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringType16(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringType16');
  try
    lFixture.SetUp;
    try lFixture.TestStringType16; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringType17(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringType17');
  try
    lFixture.SetUp;
    try lFixture.TestStringType17; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringType18(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringType18');
  try
    lFixture.SetUp;
    try lFixture.TestStringType18; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringType19(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringType19');
  try
    lFixture.SetUp;
    try lFixture.TestStringType19; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringTypeErrors1(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringTypeErrors1');
  try
    lFixture.SetUp;
    try lFixture.TestStringTypeErrors1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringTypeErrors2(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringTypeErrors2');
  try
    lFixture.SetUp;
    try lFixture.TestStringTypeErrors2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestStringTypeErrors3(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestStringTypeErrors3');
  try
    lFixture.SetUp;
    try lFixture.TestStringTypeErrors3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestTypeInt1(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestTypeInt1');
  try
    lFixture.SetUp;
    try lFixture.TestTypeInt1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestTypeInt2(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestTypeInt2');
  try
    lFixture.SetUp;
    try lFixture.TestTypeInt2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestTypeInt3(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestTypeInt3');
  try
    lFixture.SetUp;
    try lFixture.TestTypeInt3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestTypeInt4(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestTypeInt4');
  try
    lFixture.SetUp;
    try lFixture.TestTypeInt4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestTypeInt5(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestTypeInt5');
  try
    lFixture.SetUp;
    try lFixture.TestTypeInt5; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestNumerical1(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestNumerical1');
  try
    lFixture.SetUp;
    try lFixture.TestNumerical1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestNumerical2(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestNumerical2');
  try
    lFixture.SetUp;
    try lFixture.TestNumerical2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestNumerical3(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestNumerical3');
  try
    lFixture.SetUp;
    try lFixture.TestNumerical3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestNumericalError1(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestNumericalError1');
  try
    lFixture.SetUp;
    try lFixture.TestNumericalError1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestNumericalError2(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestNumericalError2');
  try
    lFixture.SetUp;
    try lFixture.TestNumericalError2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestNumericalError3(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestNumericalError3');
  try
    lFixture.SetUp;
    try lFixture.TestNumericalError3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestNumericalError4(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestNumericalError4');
  try
    lFixture.SetUp;
    try lFixture.TestNumericalError4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestNumericalError5(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestNumericalError5');
  try
    lFixture.SetUp;
    try lFixture.TestNumericalError5; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestNumericalError6(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestNumericalError6');
  try
    lFixture.SetUp;
    try lFixture.TestNumericalError6; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestNumericalError7(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestNumericalError7');
  try
    lFixture.SetUp;
    try lFixture.TestNumericalError7; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestBlob1(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestBlob1');
  try
    lFixture.SetUp;
    try lFixture.TestBlob1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestBlob2(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestBlob2');
  try
    lFixture.SetUp;
    try lFixture.TestBlob2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestBlob3(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestBlob3');
  try
    lFixture.SetUp;
    try lFixture.TestBlob3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestBlob4(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestBlob4');
  try
    lFixture.SetUp;
    try lFixture.TestBlob4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestBlob5(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestBlob5');
  try
    lFixture.SetUp;
    try lFixture.TestBlob5; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestBlob6(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestBlob6');
  try
    lFixture.SetUp;
    try lFixture.TestBlob6; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestBlob7(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestBlob7');
  try
    lFixture.SetUp;
    try lFixture.TestBlob7; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestBlob8(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestBlob8');
  try
    lFixture.SetUp;
    try lFixture.TestBlob8; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestBlobError1(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestBlobError1');
  try
    lFixture.SetUp;
    try lFixture.TestBlobError1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestBlobError2(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestBlobError2');
  try
    lFixture.SetUp;
    try lFixture.TestBlobError2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestBlobError3(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestBlobError3');
  try
    lFixture.SetUp;
    try lFixture.TestBlobError3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestBlobError4(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestBlobError4');
  try
    lFixture.SetUp;
    try lFixture.TestBlobError4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestBlobError5(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestBlobError5');
  try
    lFixture.SetUp;
    try lFixture.TestBlobError5; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestBlobError6(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestBlobError6');
  try
    lFixture.SetUp;
    try lFixture.TestBlobError6; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestBlobError7(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestBlobError7');
  try
    lFixture.SetUp;
    try lFixture.TestBlobError7; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestSmallInt(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestSmallInt');
  try
    lFixture.SetUp;
    try lFixture.TestSmallInt; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestFloat(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestFloat');
  try
    lFixture.SetUp;
    try lFixture.TestFloat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestDoublePrecision(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestDoublePrecision');
  try
    lFixture.SetUp;
    try lFixture.TestDoublePrecision; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTypeParserTestDoublePrecisionDefault(AContext: TNXTestContext);
var lFixture: TTestTypeParser;
begin
  lFixture:=TTestTypeParser.Create(AContext, 'TestDoublePrecisionDefault');
  try
    lFixture.SetUp;
    try lFixture.TestDoublePrecisionDefault; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestCheckNull(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestCheckNull');
  try
    lFixture.SetUp;
    try lFixture.TestCheckNull; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestCheckNotNull(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestCheckNotNull');
  try
    lFixture.SetUp;
    try lFixture.TestCheckNotNull; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestCheckBraces(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestCheckBraces');
  try
    lFixture.SetUp;
    try lFixture.TestCheckBraces; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestCheckBracesError(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestCheckBracesError');
  try
    lFixture.SetUp;
    try lFixture.TestCheckBracesError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestCheckParamError(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestCheckParamError');
  try
    lFixture.SetUp;
    try lFixture.TestCheckParamError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestCheckIdentifierError(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestCheckIdentifierError');
  try
    lFixture.SetUp;
    try lFixture.TestCheckIdentifierError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestIsEqual(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestIsEqual');
  try
    lFixture.SetUp;
    try lFixture.TestIsEqual; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestIsNotEqual1(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestIsNotEqual1');
  try
    lFixture.SetUp;
    try lFixture.TestIsNotEqual1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestIsNotEqual2(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestIsNotEqual2');
  try
    lFixture.SetUp;
    try lFixture.TestIsNotEqual2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestGreaterThan(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestGreaterThan');
  try
    lFixture.SetUp;
    try lFixture.TestGreaterThan; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestGreaterThanEqual1(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestGreaterThanEqual1');
  try
    lFixture.SetUp;
    try lFixture.TestGreaterThanEqual1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestGreaterThanEqual2(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestGreaterThanEqual2');
  try
    lFixture.SetUp;
    try lFixture.TestGreaterThanEqual2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestLessThan(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestLessThan');
  try
    lFixture.SetUp;
    try lFixture.TestLessThan; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestLessThanEqual1(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestLessThanEqual1');
  try
    lFixture.SetUp;
    try lFixture.TestLessThanEqual1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestLessThanEqual2(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestLessThanEqual2');
  try
    lFixture.SetUp;
    try lFixture.TestLessThanEqual2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestLike(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestLike');
  try
    lFixture.SetUp;
    try lFixture.TestLike; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestNotLike(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestNotLike');
  try
    lFixture.SetUp;
    try lFixture.TestNotLike; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestContaining(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestContaining');
  try
    lFixture.SetUp;
    try lFixture.TestContaining; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestNotContaining(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestNotContaining');
  try
    lFixture.SetUp;
    try lFixture.TestNotContaining; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestStarting(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestStarting');
  try
    lFixture.SetUp;
    try lFixture.TestStarting; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestNotStarting(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestNotStarting');
  try
    lFixture.SetUp;
    try lFixture.TestNotStarting; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestStartingWith(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestStartingWith');
  try
    lFixture.SetUp;
    try lFixture.TestStartingWith; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestNotStartingWith(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestNotStartingWith');
  try
    lFixture.SetUp;
    try lFixture.TestNotStartingWith; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestBetween(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestBetween');
  try
    lFixture.SetUp;
    try lFixture.TestBetween; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestNotBetween(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestNotBetween');
  try
    lFixture.SetUp;
    try lFixture.TestNotBetween; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestLikeEscape(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestLikeEscape');
  try
    lFixture.SetUp;
    try lFixture.TestLikeEscape; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestNotLikeEscape(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestNotLikeEscape');
  try
    lFixture.SetUp;
    try lFixture.TestNotLikeEscape; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestAnd(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestAnd');
  try
    lFixture.SetUp;
    try lFixture.TestAnd; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestOr(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestOr');
  try
    lFixture.SetUp;
    try lFixture.TestOr; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestNotOr(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestNotOr');
  try
    lFixture.SetUp;
    try lFixture.TestNotOr; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestCase(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestCase');
  try
    lFixture.SetUp;
    try lFixture.TestCase; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestCaseWithSelector(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestCaseWithSelector');
  try
    lFixture.SetUp;
    try lFixture.TestCaseWithSelector; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestAdd(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestAdd');
  try
    lFixture.SetUp;
    try lFixture.TestAdd; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestSubtract(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestSubtract');
  try
    lFixture.SetUp;
    try lFixture.TestSubtract; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestMultiply(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestMultiply');
  try
    lFixture.SetUp;
    try lFixture.TestMultiply; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCheckParserTestDivide(AContext: TNXTestContext);
var lFixture: TTestCheckParser;
begin
  lFixture:=TTestCheckParser.Create(AContext, 'TestDivide');
  try
    lFixture.SetUp;
    try lFixture.TestDivide; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDomainParserTestSimpleDomain(AContext: TNXTestContext);
var lFixture: TTestDomainParser;
begin
  lFixture:=TTestDomainParser.Create(AContext, 'TestSimpleDomain');
  try
    lFixture.SetUp;
    try lFixture.TestSimpleDomain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDomainParserTestSimpleDomainAs(AContext: TNXTestContext);
var lFixture: TTestDomainParser;
begin
  lFixture:=TTestDomainParser.Create(AContext, 'TestSimpleDomainAs');
  try
    lFixture.SetUp;
    try lFixture.TestSimpleDomainAs; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDomainParserTestNotNullDomain(AContext: TNXTestContext);
var lFixture: TTestDomainParser;
begin
  lFixture:=TTestDomainParser.Create(AContext, 'TestNotNullDomain');
  try
    lFixture.SetUp;
    try lFixture.TestNotNullDomain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDomainParserTestDefaultNotNullDomain(AContext: TNXTestContext);
var lFixture: TTestDomainParser;
begin
  lFixture:=TTestDomainParser.Create(AContext, 'TestDefaultNotNullDomain');
  try
    lFixture.SetUp;
    try lFixture.TestDefaultNotNullDomain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDomainParserTestCheckDomain(AContext: TNXTestContext);
var lFixture: TTestDomainParser;
begin
  lFixture:=TTestDomainParser.Create(AContext, 'TestCheckDomain');
  try
    lFixture.SetUp;
    try lFixture.TestCheckDomain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDomainParserTestDefaultCheckNotNullDomain(AContext: TNXTestContext);
var lFixture: TTestDomainParser;
begin
  lFixture:=TTestDomainParser.Create(AContext, 'TestDefaultCheckNotNullDomain');
  try
    lFixture.SetUp;
    try lFixture.TestDefaultCheckNotNullDomain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDomainParserTestAlterDomainDropDefault(AContext: TNXTestContext);
var lFixture: TTestDomainParser;
begin
  lFixture:=TTestDomainParser.Create(AContext, 'TestAlterDomainDropDefault');
  try
    lFixture.SetUp;
    try lFixture.TestAlterDomainDropDefault; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDomainParserTestAlterDomainDropCheck(AContext: TNXTestContext);
var lFixture: TTestDomainParser;
begin
  lFixture:=TTestDomainParser.Create(AContext, 'TestAlterDomainDropCheck');
  try
    lFixture.SetUp;
    try lFixture.TestAlterDomainDropCheck; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDomainParserTestAlterDomainDropCheckError(AContext: TNXTestContext);
var lFixture: TTestDomainParser;
begin
  lFixture:=TTestDomainParser.Create(AContext, 'TestAlterDomainDropCheckError');
  try
    lFixture.SetUp;
    try lFixture.TestAlterDomainDropCheckError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDomainParserTestAlterDomainAddCheck(AContext: TNXTestContext);
var lFixture: TTestDomainParser;
begin
  lFixture:=TTestDomainParser.Create(AContext, 'TestAlterDomainAddCheck');
  try
    lFixture.SetUp;
    try lFixture.TestAlterDomainAddCheck; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDomainParserTestAlterDomainAddConstraintCheck(AContext: TNXTestContext);
var lFixture: TTestDomainParser;
begin
  lFixture:=TTestDomainParser.Create(AContext, 'TestAlterDomainAddConstraintCheck');
  try
    lFixture.SetUp;
    try lFixture.TestAlterDomainAddConstraintCheck; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDomainParserTestAlterDomainAddConstraintError(AContext: TNXTestContext);
var lFixture: TTestDomainParser;
begin
  lFixture:=TTestDomainParser.Create(AContext, 'TestAlterDomainAddConstraintError');
  try
    lFixture.SetUp;
    try lFixture.TestAlterDomainAddConstraintError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDomainParserTestAlterDomainSetDefault(AContext: TNXTestContext);
var lFixture: TTestDomainParser;
begin
  lFixture:=TTestDomainParser.Create(AContext, 'TestAlterDomainSetDefault');
  try
    lFixture.SetUp;
    try lFixture.TestAlterDomainSetDefault; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDomainParserTestAlterDomainRename(AContext: TNXTestContext);
var lFixture: TTestDomainParser;
begin
  lFixture:=TTestDomainParser.Create(AContext, 'TestAlterDomainRename');
  try
    lFixture.SetUp;
    try lFixture.TestAlterDomainRename; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDomainParserTestAlterDomainNewType(AContext: TNXTestContext);
var lFixture: TTestDomainParser;
begin
  lFixture:=TTestDomainParser.Create(AContext, 'TestAlterDomainNewType');
  try
    lFixture.SetUp;
    try lFixture.TestAlterDomainNewType; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDomainParserTestAlterDomainNewTypeError1(AContext: TNXTestContext);
var lFixture: TTestDomainParser;
begin
  lFixture:=TTestDomainParser.Create(AContext, 'TestAlterDomainNewTypeError1');
  try
    lFixture.SetUp;
    try lFixture.TestAlterDomainNewTypeError1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDomainParserTestAlterDomainNewTypeError2(AContext: TNXTestContext);
var lFixture: TTestDomainParser;
begin
  lFixture:=TTestDomainParser.Create(AContext, 'TestAlterDomainNewTypeError2');
  try
    lFixture.SetUp;
    try lFixture.TestAlterDomainNewTypeError2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestExceptionParserTestException(AContext: TNXTestContext);
var lFixture: TTestExceptionParser;
begin
  lFixture:=TTestExceptionParser.Create(AContext, 'TestException');
  try
    lFixture.SetUp;
    try lFixture.TestException; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestExceptionParserTestAlterException(AContext: TNXTestContext);
var lFixture: TTestExceptionParser;
begin
  lFixture:=TTestExceptionParser.Create(AContext, 'TestAlterException');
  try
    lFixture.SetUp;
    try lFixture.TestAlterException; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestExceptionParserTestExceptionError1(AContext: TNXTestContext);
var lFixture: TTestExceptionParser;
begin
  lFixture:=TTestExceptionParser.Create(AContext, 'TestExceptionError1');
  try
    lFixture.SetUp;
    try lFixture.TestExceptionError1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestExceptionParserTestExceptionError2(AContext: TNXTestContext);
var lFixture: TTestExceptionParser;
begin
  lFixture:=TTestExceptionParser.Create(AContext, 'TestExceptionError2');
  try
    lFixture.SetUp;
    try lFixture.TestExceptionError2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIndexParserTestAlterindexActive(AContext: TNXTestContext);
var lFixture: TTestIndexParser;
begin
  lFixture:=TTestIndexParser.Create(AContext, 'TestAlterindexActive');
  try
    lFixture.SetUp;
    try lFixture.TestAlterindexActive; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIndexParserTestAlterindexInactive(AContext: TNXTestContext);
var lFixture: TTestIndexParser;
begin
  lFixture:=TTestIndexParser.Create(AContext, 'TestAlterindexInactive');
  try
    lFixture.SetUp;
    try lFixture.TestAlterindexInactive; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIndexParserTestCreateIndexSimple(AContext: TNXTestContext);
var lFixture: TTestIndexParser;
begin
  lFixture:=TTestIndexParser.Create(AContext, 'TestCreateIndexSimple');
  try
    lFixture.SetUp;
    try lFixture.TestCreateIndexSimple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIndexParserTestIndexIndexDouble(AContext: TNXTestContext);
var lFixture: TTestIndexParser;
begin
  lFixture:=TTestIndexParser.Create(AContext, 'TestIndexIndexDouble');
  try
    lFixture.SetUp;
    try lFixture.TestIndexIndexDouble; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIndexParserTestCreateIndexAscending(AContext: TNXTestContext);
var lFixture: TTestIndexParser;
begin
  lFixture:=TTestIndexParser.Create(AContext, 'TestCreateIndexAscending');
  try
    lFixture.SetUp;
    try lFixture.TestCreateIndexAscending; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIndexParserTestCreateIndexDescending(AContext: TNXTestContext);
var lFixture: TTestIndexParser;
begin
  lFixture:=TTestIndexParser.Create(AContext, 'TestCreateIndexDescending');
  try
    lFixture.SetUp;
    try lFixture.TestCreateIndexDescending; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIndexParserTestCreateIndexUnique(AContext: TNXTestContext);
var lFixture: TTestIndexParser;
begin
  lFixture:=TTestIndexParser.Create(AContext, 'TestCreateIndexUnique');
  try
    lFixture.SetUp;
    try lFixture.TestCreateIndexUnique; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIndexParserTestCreateIndexUniqueAscending(AContext: TNXTestContext);
var lFixture: TTestIndexParser;
begin
  lFixture:=TTestIndexParser.Create(AContext, 'TestCreateIndexUniqueAscending');
  try
    lFixture.SetUp;
    try lFixture.TestCreateIndexUniqueAscending; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIndexParserTestCreateIndexUniqueDescending(AContext: TNXTestContext);
var lFixture: TTestIndexParser;
begin
  lFixture:=TTestIndexParser.Create(AContext, 'TestCreateIndexUniqueDescending');
  try
    lFixture.SetUp;
    try lFixture.TestCreateIndexUniqueDescending; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIndexParserTestIndexError1(AContext: TNXTestContext);
var lFixture: TTestIndexParser;
begin
  lFixture:=TTestIndexParser.Create(AContext, 'TestIndexError1');
  try
    lFixture.SetUp;
    try lFixture.TestIndexError1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIndexParserTestIndexError2(AContext: TNXTestContext);
var lFixture: TTestIndexParser;
begin
  lFixture:=TTestIndexParser.Create(AContext, 'TestIndexError2');
  try
    lFixture.SetUp;
    try lFixture.TestIndexError2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIndexParserTestIndexError3(AContext: TNXTestContext);
var lFixture: TTestIndexParser;
begin
  lFixture:=TTestIndexParser.Create(AContext, 'TestIndexError3');
  try
    lFixture.SetUp;
    try lFixture.TestIndexError3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIndexParserTestIndexError4(AContext: TNXTestContext);
var lFixture: TTestIndexParser;
begin
  lFixture:=TTestIndexParser.Create(AContext, 'TestIndexError4');
  try
    lFixture.SetUp;
    try lFixture.TestIndexError4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIndexParserTestIndexError5(AContext: TNXTestContext);
var lFixture: TTestIndexParser;
begin
  lFixture:=TTestIndexParser.Create(AContext, 'TestIndexError5');
  try
    lFixture.SetUp;
    try lFixture.TestIndexError5; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestIndexParserTestIndexError6(AContext: TNXTestContext);
var lFixture: TTestIndexParser;
begin
  lFixture:=TTestIndexParser.Create(AContext, 'TestIndexError6');
  try
    lFixture.SetUp;
    try lFixture.TestIndexError6; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateOneSimpleField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateOneSimpleField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateOneSimpleField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateTwoSimpleFields(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateTwoSimpleFields');
  try
    lFixture.SetUp;
    try lFixture.TestCreateTwoSimpleFields; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateOnePrimaryField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateOnePrimaryField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateOnePrimaryField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateOneNamedPrimaryField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateOneNamedPrimaryField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateOneNamedPrimaryField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateOneUniqueField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateOneUniqueField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateOneUniqueField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateOneNamedUniqueField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateOneNamedUniqueField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateOneNamedUniqueField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateNotNullPrimaryField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateNotNullPrimaryField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateNotNullPrimaryField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateNotNullDefaultPrimaryField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateNotNullDefaultPrimaryField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateNotNullDefaultPrimaryField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateComputedByField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateComputedByField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateComputedByField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateCheckField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateCheckField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateCheckField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateNamedCheckField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateNamedCheckField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateNamedCheckField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateReferencesField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateReferencesField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateReferencesField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateReferencesOnUpdateCascadeField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateReferencesOnUpdateCascadeField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateReferencesOnUpdateCascadeField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateReferencesOnUpdateNoActionField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateReferencesOnUpdateNoActionField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateReferencesOnUpdateNoActionField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateReferencesOnUpdateSetDefaultField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateReferencesOnUpdateSetDefaultField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateReferencesOnUpdateSetDefaultField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateReferencesOnUpdateSetNullField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateReferencesOnUpdateSetNullField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateReferencesOnUpdateSetNullField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateReferencesOnDeleteCascadeField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateReferencesOnDeleteCascadeField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateReferencesOnDeleteCascadeField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateReferencesOnDeleteNoActionField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateReferencesOnDeleteNoActionField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateReferencesOnDeleteNoActionField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateReferencesOnDeleteSetDefaultField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateReferencesOnDeleteSetDefaultField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateReferencesOnDeleteSetDefaultField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateReferencesOnDeleteSetNullField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateReferencesOnDeleteSetNullField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateReferencesOnDeleteSetNullField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateReferencesOnUpdateAndDeleteSetNullField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateReferencesOnUpdateAndDeleteSetNullField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateReferencesOnUpdateAndDeleteSetNullField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateNamedReferencesField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateNamedReferencesField');
  try
    lFixture.SetUp;
    try lFixture.TestCreateNamedReferencesField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreatePrimaryKeyConstraint(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreatePrimaryKeyConstraint');
  try
    lFixture.SetUp;
    try lFixture.TestCreatePrimaryKeyConstraint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateNamedPrimaryKeyConstraint(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateNamedPrimaryKeyConstraint');
  try
    lFixture.SetUp;
    try lFixture.TestCreateNamedPrimaryKeyConstraint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateForeignKeyConstraint(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateForeignKeyConstraint');
  try
    lFixture.SetUp;
    try lFixture.TestCreateForeignKeyConstraint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateNamedForeignKeyConstraint(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateNamedForeignKeyConstraint');
  try
    lFixture.SetUp;
    try lFixture.TestCreateNamedForeignKeyConstraint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateUniqueConstraint(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateUniqueConstraint');
  try
    lFixture.SetUp;
    try lFixture.TestCreateUniqueConstraint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateNamedUniqueConstraint(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateNamedUniqueConstraint');
  try
    lFixture.SetUp;
    try lFixture.TestCreateNamedUniqueConstraint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateCheckConstraint(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateCheckConstraint');
  try
    lFixture.SetUp;
    try lFixture.TestCreateCheckConstraint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestCreateNamedCheckConstraint(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestCreateNamedCheckConstraint');
  try
    lFixture.SetUp;
    try lFixture.TestCreateNamedCheckConstraint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestAlterDropField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestAlterDropField');
  try
    lFixture.SetUp;
    try lFixture.TestAlterDropField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestAlterDropFields(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestAlterDropFields');
  try
    lFixture.SetUp;
    try lFixture.TestAlterDropFields; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestAlterDropConstraint(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestAlterDropConstraint');
  try
    lFixture.SetUp;
    try lFixture.TestAlterDropConstraint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestAlterDropConstraints(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestAlterDropConstraints');
  try
    lFixture.SetUp;
    try lFixture.TestAlterDropConstraints; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestAlterRenameField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestAlterRenameField');
  try
    lFixture.SetUp;
    try lFixture.TestAlterRenameField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestAlterRenameColumnField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestAlterRenameColumnField');
  try
    lFixture.SetUp;
    try lFixture.TestAlterRenameColumnField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestAlterFieldType(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestAlterFieldType');
  try
    lFixture.SetUp;
    try lFixture.TestAlterFieldType; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestAlterFieldPosition(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestAlterFieldPosition');
  try
    lFixture.SetUp;
    try lFixture.TestAlterFieldPosition; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestAlterAddField(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestAlterAddField');
  try
    lFixture.SetUp;
    try lFixture.TestAlterAddField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestAlterAddFields(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestAlterAddFields');
  try
    lFixture.SetUp;
    try lFixture.TestAlterAddFields; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestAlterAddPrimarykey(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestAlterAddPrimarykey');
  try
    lFixture.SetUp;
    try lFixture.TestAlterAddPrimarykey; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestAlterAddNamedPrimarykey(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestAlterAddNamedPrimarykey');
  try
    lFixture.SetUp;
    try lFixture.TestAlterAddNamedPrimarykey; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestAlterAddCheckConstraint(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestAlterAddCheckConstraint');
  try
    lFixture.SetUp;
    try lFixture.TestAlterAddCheckConstraint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestAlterAddNamedCheckConstraint(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestAlterAddNamedCheckConstraint');
  try
    lFixture.SetUp;
    try lFixture.TestAlterAddNamedCheckConstraint; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestAlterAddForeignkey(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestAlterAddForeignkey');
  try
    lFixture.SetUp;
    try lFixture.TestAlterAddForeignkey; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestTableParserTestAlterAddNamedForeignkey(AContext: TNXTestContext);
var lFixture: TTestTableParser;
begin
  lFixture:=TTestTableParser.Create(AContext, 'TestAlterAddNamedForeignkey');
  try
    lFixture.SetUp;
    try lFixture.TestAlterAddNamedForeignkey; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeleteParserTestSimpleDelete(AContext: TNXTestContext);
var lFixture: TTestDeleteParser;
begin
  lFixture:=TTestDeleteParser.Create(AContext, 'TestSimpleDelete');
  try
    lFixture.SetUp;
    try lFixture.TestSimpleDelete; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeleteParserTestSimpleDeleteAlias(AContext: TNXTestContext);
var lFixture: TTestDeleteParser;
begin
  lFixture:=TTestDeleteParser.Create(AContext, 'TestSimpleDeleteAlias');
  try
    lFixture.SetUp;
    try lFixture.TestSimpleDeleteAlias; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeleteParserTestDeleteWhereNull(AContext: TNXTestContext);
var lFixture: TTestDeleteParser;
begin
  lFixture:=TTestDeleteParser.Create(AContext, 'TestDeleteWhereNull');
  try
    lFixture.SetUp;
    try lFixture.TestDeleteWhereNull; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUpdateParserTestUpdateOneField(AContext: TNXTestContext);
var lFixture: TTestUpdateParser;
begin
  lFixture:=TTestUpdateParser.Create(AContext, 'TestUpdateOneField');
  try
    lFixture.SetUp;
    try lFixture.TestUpdateOneField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUpdateParserTestUpdateOneFieldFull(AContext: TNXTestContext);
var lFixture: TTestUpdateParser;
begin
  lFixture:=TTestUpdateParser.Create(AContext, 'TestUpdateOneFieldFull');
  try
    lFixture.SetUp;
    try lFixture.TestUpdateOneFieldFull; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUpdateParserTestUpdateTwoFields(AContext: TNXTestContext);
var lFixture: TTestUpdateParser;
begin
  lFixture:=TTestUpdateParser.Create(AContext, 'TestUpdateTwoFields');
  try
    lFixture.SetUp;
    try lFixture.TestUpdateTwoFields; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestUpdateParserTestUpdateOneFieldWhereIsNull(AContext: TNXTestContext);
var lFixture: TTestUpdateParser;
begin
  lFixture:=TTestUpdateParser.Create(AContext, 'TestUpdateOneFieldWhereIsNull');
  try
    lFixture.SetUp;
    try lFixture.TestUpdateOneFieldWhereIsNull; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestInsertParserTestInsertOneField(AContext: TNXTestContext);
var lFixture: TTestInsertParser;
begin
  lFixture:=TTestInsertParser.Create(AContext, 'TestInsertOneField');
  try
    lFixture.SetUp;
    try lFixture.TestInsertOneField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestInsertParserTestInsertTwoFields(AContext: TNXTestContext);
var lFixture: TTestInsertParser;
begin
  lFixture:=TTestInsertParser.Create(AContext, 'TestInsertTwoFields');
  try
    lFixture.SetUp;
    try lFixture.TestInsertTwoFields; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestInsertParserTestInsertOneValue(AContext: TNXTestContext);
var lFixture: TTestInsertParser;
begin
  lFixture:=TTestInsertParser.Create(AContext, 'TestInsertOneValue');
  try
    lFixture.SetUp;
    try lFixture.TestInsertOneValue; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestInsertParserTestInsertTwoValues(AContext: TNXTestContext);
var lFixture: TTestInsertParser;
begin
  lFixture:=TTestInsertParser.Create(AContext, 'TestInsertTwoValues');
  try
    lFixture.SetUp;
    try lFixture.TestInsertTwoValues; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectOneFieldOneTable(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectOneFieldOneTable');
  try
    lFixture.SetUp;
    try lFixture.TestSelectOneFieldOneTable; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectOneFieldOneTableTransaction(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectOneFieldOneTableTransaction');
  try
    lFixture.SetUp;
    try lFixture.TestSelectOneFieldOneTableTransaction; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectOneArrayFieldOneTable(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectOneArrayFieldOneTable');
  try
    lFixture.SetUp;
    try lFixture.TestSelectOneArrayFieldOneTable; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectTwoFieldsOneTable(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectTwoFieldsOneTable');
  try
    lFixture.SetUp;
    try lFixture.TestSelectTwoFieldsOneTable; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectOneFieldAliasOneTable(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectOneFieldAliasOneTable');
  try
    lFixture.SetUp;
    try lFixture.TestSelectOneFieldAliasOneTable; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectTwoFieldAliasesOneTable(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectTwoFieldAliasesOneTable');
  try
    lFixture.SetUp;
    try lFixture.TestSelectTwoFieldAliasesOneTable; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectOneTableFieldOneTable(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectOneTableFieldOneTable');
  try
    lFixture.SetUp;
    try lFixture.TestSelectOneTableFieldOneTable; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectOneDistinctFieldOneTable(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectOneDistinctFieldOneTable');
  try
    lFixture.SetUp;
    try lFixture.TestSelectOneDistinctFieldOneTable; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectOneAllFieldOneTable(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectOneAllFieldOneTable');
  try
    lFixture.SetUp;
    try lFixture.TestSelectOneAllFieldOneTable; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectAsteriskOneTable(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectAsteriskOneTable');
  try
    lFixture.SetUp;
    try lFixture.TestSelectAsteriskOneTable; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectDistinctAsteriskOneTable(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectDistinctAsteriskOneTable');
  try
    lFixture.SetUp;
    try lFixture.TestSelectDistinctAsteriskOneTable; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectAsteriskWithPath(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectAsteriskWithPath');
  try
    lFixture.SetUp;
    try lFixture.TestSelectAsteriskWithPath; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectOneFieldOneTableAlias(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectOneFieldOneTableAlias');
  try
    lFixture.SetUp;
    try lFixture.TestSelectOneFieldOneTableAlias; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectOneFieldOneTableAsAlias(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectOneFieldOneTableAsAlias');
  try
    lFixture.SetUp;
    try lFixture.TestSelectOneFieldOneTableAsAlias; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectTwoFieldsTwoTables(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectTwoFieldsTwoTables');
  try
    lFixture.SetUp;
    try lFixture.TestSelectTwoFieldsTwoTables; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectTwoFieldsTwoTablesJoin(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectTwoFieldsTwoTablesJoin');
  try
    lFixture.SetUp;
    try lFixture.TestSelectTwoFieldsTwoTablesJoin; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectTwoFieldsTwoInnerTablesJoin(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectTwoFieldsTwoInnerTablesJoin');
  try
    lFixture.SetUp;
    try lFixture.TestSelectTwoFieldsTwoInnerTablesJoin; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectTwoFieldsTwoLeftTablesJoin(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectTwoFieldsTwoLeftTablesJoin');
  try
    lFixture.SetUp;
    try lFixture.TestSelectTwoFieldsTwoLeftTablesJoin; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectTwoFieldsTwoFullOuterTablesJoin(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectTwoFieldsTwoFullOuterTablesJoin');
  try
    lFixture.SetUp;
    try lFixture.TestSelectTwoFieldsTwoFullOuterTablesJoin; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectTwoFieldsTwoFullTablesJoin(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectTwoFieldsTwoFullTablesJoin');
  try
    lFixture.SetUp;
    try lFixture.TestSelectTwoFieldsTwoFullTablesJoin; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectTwoFieldsTwoRightTablesJoin(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectTwoFieldsTwoRightTablesJoin');
  try
    lFixture.SetUp;
    try lFixture.TestSelectTwoFieldsTwoRightTablesJoin; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectTwoFieldsThreeTablesJoin(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectTwoFieldsThreeTablesJoin');
  try
    lFixture.SetUp;
    try lFixture.TestSelectTwoFieldsThreeTablesJoin; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectTwoFieldsBracketThreeTablesJoin(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectTwoFieldsBracketThreeTablesJoin');
  try
    lFixture.SetUp;
    try lFixture.TestSelectTwoFieldsBracketThreeTablesJoin; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectTwoFieldsThreeBracketTablesJoin(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectTwoFieldsThreeBracketTablesJoin');
  try
    lFixture.SetUp;
    try lFixture.TestSelectTwoFieldsThreeBracketTablesJoin; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectTableWithSchema(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectTableWithSchema');
  try
    lFixture.SetUp;
    try lFixture.TestSelectTableWithSchema; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectFieldWithSchema(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectFieldWithSchema');
  try
    lFixture.SetUp;
    try lFixture.TestSelectFieldWithSchema; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectFieldAsStringLiteral(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectFieldAsStringLiteral');
  try
    lFixture.SetUp;
    try lFixture.TestSelectFieldAsStringLiteral; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectFirst(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectFirst');
  try
    lFixture.SetUp;
    try lFixture.TestSelectFirst; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectFirstSkip(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectFirstSkip');
  try
    lFixture.SetUp;
    try lFixture.TestSelectFirstSkip; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectTop(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectTop');
  try
    lFixture.SetUp;
    try lFixture.TestSelectTop; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectLimit(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectLimit');
  try
    lFixture.SetUp;
    try lFixture.TestSelectLimit; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectLimitAll(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectLimitAll');
  try
    lFixture.SetUp;
    try lFixture.TestSelectLimitAll; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectLimitAllOffset(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectLimitAllOffset');
  try
    lFixture.SetUp;
    try lFixture.TestSelectLimitAllOffset; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectLimitOffset1(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectLimitOffset1');
  try
    lFixture.SetUp;
    try lFixture.TestSelectLimitOffset1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectLimitOffset2(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectLimitOffset2');
  try
    lFixture.SetUp;
    try lFixture.TestSelectLimitOffset2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSelectOffset(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSelectOffset');
  try
    lFixture.SetUp;
    try lFixture.TestSelectOffset; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestAggregateCount(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestAggregateCount');
  try
    lFixture.SetUp;
    try lFixture.TestAggregateCount; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestAggregateCountAsterisk(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestAggregateCountAsterisk');
  try
    lFixture.SetUp;
    try lFixture.TestAggregateCountAsterisk; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestAggregateCountAll(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestAggregateCountAll');
  try
    lFixture.SetUp;
    try lFixture.TestAggregateCountAll; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestAggregateCountDistinct(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestAggregateCountDistinct');
  try
    lFixture.SetUp;
    try lFixture.TestAggregateCountDistinct; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestAggregateMax(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestAggregateMax');
  try
    lFixture.SetUp;
    try lFixture.TestAggregateMax; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestAggregateMaxAll(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestAggregateMaxAll');
  try
    lFixture.SetUp;
    try lFixture.TestAggregateMaxAll; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestAggregateMaxAsterisk(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestAggregateMaxAsterisk');
  try
    lFixture.SetUp;
    try lFixture.TestAggregateMaxAsterisk; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestAggregateMaxDistinct(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestAggregateMaxDistinct');
  try
    lFixture.SetUp;
    try lFixture.TestAggregateMaxDistinct; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestAggregateMin(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestAggregateMin');
  try
    lFixture.SetUp;
    try lFixture.TestAggregateMin; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestAggregateMinAll(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestAggregateMinAll');
  try
    lFixture.SetUp;
    try lFixture.TestAggregateMinAll; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestAggregateMinAsterisk(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestAggregateMinAsterisk');
  try
    lFixture.SetUp;
    try lFixture.TestAggregateMinAsterisk; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestAggregateMinDistinct(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestAggregateMinDistinct');
  try
    lFixture.SetUp;
    try lFixture.TestAggregateMinDistinct; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestAggregateSum(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestAggregateSum');
  try
    lFixture.SetUp;
    try lFixture.TestAggregateSum; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestAggregateSumAll(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestAggregateSumAll');
  try
    lFixture.SetUp;
    try lFixture.TestAggregateSumAll; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestAggregateSumAsterisk(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestAggregateSumAsterisk');
  try
    lFixture.SetUp;
    try lFixture.TestAggregateSumAsterisk; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestAggregateSumDistinct(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestAggregateSumDistinct');
  try
    lFixture.SetUp;
    try lFixture.TestAggregateSumDistinct; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestAggregateAvg(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestAggregateAvg');
  try
    lFixture.SetUp;
    try lFixture.TestAggregateAvg; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestAggregateAvgAll(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestAggregateAvgAll');
  try
    lFixture.SetUp;
    try lFixture.TestAggregateAvgAll; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestAggregateAvgAsterisk(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestAggregateAvgAsterisk');
  try
    lFixture.SetUp;
    try lFixture.TestAggregateAvgAsterisk; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestAggregateAvgDistinct(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestAggregateAvgDistinct');
  try
    lFixture.SetUp;
    try lFixture.TestAggregateAvgDistinct; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestUpperConst(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestUpperConst');
  try
    lFixture.SetUp;
    try lFixture.TestUpperConst; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestUpperError(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestUpperError');
  try
    lFixture.SetUp;
    try lFixture.TestUpperError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestLeft(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestLeft');
  try
    lFixture.SetUp;
    try lFixture.TestLeft; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestFunctionWithPath(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestFunctionWithPath');
  try
    lFixture.SetUp;
    try lFixture.TestFunctionWithPath; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestGenID(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestGenID');
  try
    lFixture.SetUp;
    try lFixture.TestGenID; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestGenIDError1(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestGenIDError1');
  try
    lFixture.SetUp;
    try lFixture.TestGenIDError1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestGenIDError2(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestGenIDError2');
  try
    lFixture.SetUp;
    try lFixture.TestGenIDError2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestCastSimple(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestCastSimple');
  try
    lFixture.SetUp;
    try lFixture.TestCastSimple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestExtractSimple(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestExtractSimple');
  try
    lFixture.SetUp;
    try lFixture.TestExtractSimple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestOrderByOneField(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestOrderByOneField');
  try
    lFixture.SetUp;
    try lFixture.TestOrderByOneField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestOrderByTwoFields(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestOrderByTwoFields');
  try
    lFixture.SetUp;
    try lFixture.TestOrderByTwoFields; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestOrderByThreeFields(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestOrderByThreeFields');
  try
    lFixture.SetUp;
    try lFixture.TestOrderByThreeFields; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestOrderByOneDescField(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestOrderByOneDescField');
  try
    lFixture.SetUp;
    try lFixture.TestOrderByOneDescField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestOrderByTwoDescFields(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestOrderByTwoDescFields');
  try
    lFixture.SetUp;
    try lFixture.TestOrderByTwoDescFields; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestOrderByThreeDescFields(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestOrderByThreeDescFields');
  try
    lFixture.SetUp;
    try lFixture.TestOrderByThreeDescFields; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestOrderByOneTableField(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestOrderByOneTableField');
  try
    lFixture.SetUp;
    try lFixture.TestOrderByOneTableField; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestOrderByOneColumn(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestOrderByOneColumn');
  try
    lFixture.SetUp;
    try lFixture.TestOrderByOneColumn; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestOrderByTwoColumns(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestOrderByTwoColumns');
  try
    lFixture.SetUp;
    try lFixture.TestOrderByTwoColumns; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestOrderByTwoColumnsDesc(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestOrderByTwoColumnsDesc');
  try
    lFixture.SetUp;
    try lFixture.TestOrderByTwoColumnsDesc; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestOrderByCollate(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestOrderByCollate');
  try
    lFixture.SetUp;
    try lFixture.TestOrderByCollate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestOrderByCollateDesc(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestOrderByCollateDesc');
  try
    lFixture.SetUp;
    try lFixture.TestOrderByCollateDesc; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestOrderByCollateDescTwoFields(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestOrderByCollateDescTwoFields');
  try
    lFixture.SetUp;
    try lFixture.TestOrderByCollateDescTwoFields; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestOrderByUpper(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestOrderByUpper');
  try
    lFixture.SetUp;
    try lFixture.TestOrderByUpper; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestGroupByOne(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestGroupByOne');
  try
    lFixture.SetUp;
    try lFixture.TestGroupByOne; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestGroupByTwo(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestGroupByTwo');
  try
    lFixture.SetUp;
    try lFixture.TestGroupByTwo; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestHavingOne(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestHavingOne');
  try
    lFixture.SetUp;
    try lFixture.TestHavingOne; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestUnionSimple(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestUnionSimple');
  try
    lFixture.SetUp;
    try lFixture.TestUnionSimple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestUnionSimpleAll(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestUnionSimpleAll');
  try
    lFixture.SetUp;
    try lFixture.TestUnionSimpleAll; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestUnionSimpleOrderBy(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestUnionSimpleOrderBy');
  try
    lFixture.SetUp;
    try lFixture.TestUnionSimpleOrderBy; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestUnionDouble(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestUnionDouble');
  try
    lFixture.SetUp;
    try lFixture.TestUnionDouble; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestUnionError1(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestUnionError1');
  try
    lFixture.SetUp;
    try lFixture.TestUnionError1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestUnionError2(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestUnionError2');
  try
    lFixture.SetUp;
    try lFixture.TestUnionError2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestPlanOrderNatural(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestPlanOrderNatural');
  try
    lFixture.SetUp;
    try lFixture.TestPlanOrderNatural; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestPlanOrderOrder(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestPlanOrderOrder');
  try
    lFixture.SetUp;
    try lFixture.TestPlanOrderOrder; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestPlanOrderIndex1(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestPlanOrderIndex1');
  try
    lFixture.SetUp;
    try lFixture.TestPlanOrderIndex1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestPlanOrderIndex2(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestPlanOrderIndex2');
  try
    lFixture.SetUp;
    try lFixture.TestPlanOrderIndex2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestPlanJoinNatural(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestPlanJoinNatural');
  try
    lFixture.SetUp;
    try lFixture.TestPlanJoinNatural; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestPlanDefaultNatural(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestPlanDefaultNatural');
  try
    lFixture.SetUp;
    try lFixture.TestPlanDefaultNatural; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestPlanMergeNatural(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestPlanMergeNatural');
  try
    lFixture.SetUp;
    try lFixture.TestPlanMergeNatural; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestPlanMergeNested(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestPlanMergeNested');
  try
    lFixture.SetUp;
    try lFixture.TestPlanMergeNested; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSubSelect(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSubSelect');
  try
    lFixture.SetUp;
    try lFixture.TestSubSelect; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestWhereExists(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestWhereExists');
  try
    lFixture.SetUp;
    try lFixture.TestWhereExists; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestWhereSingular(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestWhereSingular');
  try
    lFixture.SetUp;
    try lFixture.TestWhereSingular; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestWhereAll(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestWhereAll');
  try
    lFixture.SetUp;
    try lFixture.TestWhereAll; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestWhereAny(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestWhereAny');
  try
    lFixture.SetUp;
    try lFixture.TestWhereAny; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestWhereSome(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestWhereSome');
  try
    lFixture.SetUp;
    try lFixture.TestWhereSome; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestWhereInRange(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestWhereInRange');
  try
    lFixture.SetUp;
    try lFixture.TestWhereInRange; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestWhereDotFloat(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestWhereDotFloat');
  try
    lFixture.SetUp;
    try lFixture.TestWhereDotFloat; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestParam(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestParam');
  try
    lFixture.SetUp;
    try lFixture.TestParam; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestParam_Underscore(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestParam_Underscore');
  try
    lFixture.SetUp;
    try lFixture.TestParam_Underscore; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestParamExpr(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestParamExpr');
  try
    lFixture.SetUp;
    try lFixture.TestParamExpr; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestNoTable(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestNoTable');
  try
    lFixture.SetUp;
    try lFixture.TestNoTable; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestSourcePosition(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestSourcePosition');
  try
    lFixture.SetUp;
    try lFixture.TestSourcePosition; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestForUpdate(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestForUpdate');
  try
    lFixture.SetUp;
    try lFixture.TestForUpdate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestForUpdateNowait(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestForUpdateNowait');
  try
    lFixture.SetUp;
    try lFixture.TestForUpdateNowait; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestForUpdateOf(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestForUpdateOf');
  try
    lFixture.SetUp;
    try lFixture.TestForUpdateOf; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestSelectParserTestWithLock(AContext: TNXTestContext);
var lFixture: TTestSelectParser;
begin
  lFixture:=TTestSelectParser.Create(AContext, 'TestWithLock');
  try
    lFixture.SetUp;
    try lFixture.TestWithLock; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRollBackParserTestRollback(AContext: TNXTestContext);
var lFixture: TTestRollBackParser;
begin
  lFixture:=TTestRollBackParser.Create(AContext, 'TestRollback');
  try
    lFixture.SetUp;
    try lFixture.TestRollback; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRollBackParserTestRollbackWork(AContext: TNXTestContext);
var lFixture: TTestRollBackParser;
begin
  lFixture:=TTestRollBackParser.Create(AContext, 'TestRollbackWork');
  try
    lFixture.SetUp;
    try lFixture.TestRollbackWork; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRollBackParserTestRollbackRelease(AContext: TNXTestContext);
var lFixture: TTestRollBackParser;
begin
  lFixture:=TTestRollBackParser.Create(AContext, 'TestRollbackRelease');
  try
    lFixture.SetUp;
    try lFixture.TestRollbackRelease; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRollBackParserTestRollbackWorkRelease(AContext: TNXTestContext);
var lFixture: TTestRollBackParser;
begin
  lFixture:=TTestRollBackParser.Create(AContext, 'TestRollbackWorkRelease');
  try
    lFixture.SetUp;
    try lFixture.TestRollbackWorkRelease; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRollBackParserTestRollbackTransaction(AContext: TNXTestContext);
var lFixture: TTestRollBackParser;
begin
  lFixture:=TTestRollBackParser.Create(AContext, 'TestRollbackTransaction');
  try
    lFixture.SetUp;
    try lFixture.TestRollbackTransaction; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRollBackParserTestRollbackTransactionWork(AContext: TNXTestContext);
var lFixture: TTestRollBackParser;
begin
  lFixture:=TTestRollBackParser.Create(AContext, 'TestRollbackTransactionWork');
  try
    lFixture.SetUp;
    try lFixture.TestRollbackTransactionWork; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRollBackParserTestRollbackTransactionRelease(AContext: TNXTestContext);
var lFixture: TTestRollBackParser;
begin
  lFixture:=TTestRollBackParser.Create(AContext, 'TestRollbackTransactionRelease');
  try
    lFixture.SetUp;
    try lFixture.TestRollbackTransactionRelease; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRollBackParserTestRollbackTransactionWorkRelease(AContext: TNXTestContext);
var lFixture: TTestRollBackParser;
begin
  lFixture:=TTestRollBackParser.Create(AContext, 'TestRollbackTransactionWorkRelease');
  try
    lFixture.SetUp;
    try lFixture.TestRollbackTransactionWorkRelease; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCommitParserTestCommit(AContext: TNXTestContext);
var lFixture: TTestCommitParser;
begin
  lFixture:=TTestCommitParser.Create(AContext, 'TestCommit');
  try
    lFixture.SetUp;
    try lFixture.TestCommit; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCommitParserTestCommitWork(AContext: TNXTestContext);
var lFixture: TTestCommitParser;
begin
  lFixture:=TTestCommitParser.Create(AContext, 'TestCommitWork');
  try
    lFixture.SetUp;
    try lFixture.TestCommitWork; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCommitParserTestCommitRelease(AContext: TNXTestContext);
var lFixture: TTestCommitParser;
begin
  lFixture:=TTestCommitParser.Create(AContext, 'TestCommitRelease');
  try
    lFixture.SetUp;
    try lFixture.TestCommitRelease; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCommitParserTestCommitWorkRelease(AContext: TNXTestContext);
var lFixture: TTestCommitParser;
begin
  lFixture:=TTestCommitParser.Create(AContext, 'TestCommitWorkRelease');
  try
    lFixture.SetUp;
    try lFixture.TestCommitWorkRelease; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCommitParserTestCommitTransaction(AContext: TNXTestContext);
var lFixture: TTestCommitParser;
begin
  lFixture:=TTestCommitParser.Create(AContext, 'TestCommitTransaction');
  try
    lFixture.SetUp;
    try lFixture.TestCommitTransaction; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCommitParserTestCommitTransactionWork(AContext: TNXTestContext);
var lFixture: TTestCommitParser;
begin
  lFixture:=TTestCommitParser.Create(AContext, 'TestCommitTransactionWork');
  try
    lFixture.SetUp;
    try lFixture.TestCommitTransactionWork; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCommitParserTestCommitTransactionRelease(AContext: TNXTestContext);
var lFixture: TTestCommitParser;
begin
  lFixture:=TTestCommitParser.Create(AContext, 'TestCommitTransactionRelease');
  try
    lFixture.SetUp;
    try lFixture.TestCommitTransactionRelease; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCommitParserTestCommitTransactionWorkRelease(AContext: TNXTestContext);
var lFixture: TTestCommitParser;
begin
  lFixture:=TTestCommitParser.Create(AContext, 'TestCommitTransactionWorkRelease');
  try
    lFixture.SetUp;
    try lFixture.TestCommitTransactionWorkRelease; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCommitParserTestCommitRetain(AContext: TNXTestContext);
var lFixture: TTestCommitParser;
begin
  lFixture:=TTestCommitParser.Create(AContext, 'TestCommitRetain');
  try
    lFixture.SetUp;
    try lFixture.TestCommitRetain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCommitParserTestCommitWorkRetain(AContext: TNXTestContext);
var lFixture: TTestCommitParser;
begin
  lFixture:=TTestCommitParser.Create(AContext, 'TestCommitWorkRetain');
  try
    lFixture.SetUp;
    try lFixture.TestCommitWorkRetain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCommitParserTestCommitReleaseRetain(AContext: TNXTestContext);
var lFixture: TTestCommitParser;
begin
  lFixture:=TTestCommitParser.Create(AContext, 'TestCommitReleaseRetain');
  try
    lFixture.SetUp;
    try lFixture.TestCommitReleaseRetain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCommitParserTestCommitWorkReleaseRetain(AContext: TNXTestContext);
var lFixture: TTestCommitParser;
begin
  lFixture:=TTestCommitParser.Create(AContext, 'TestCommitWorkReleaseRetain');
  try
    lFixture.SetUp;
    try lFixture.TestCommitWorkReleaseRetain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCommitParserTestCommitTransactionRetain(AContext: TNXTestContext);
var lFixture: TTestCommitParser;
begin
  lFixture:=TTestCommitParser.Create(AContext, 'TestCommitTransactionRetain');
  try
    lFixture.SetUp;
    try lFixture.TestCommitTransactionRetain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCommitParserTestCommitTransactionWorkRetain(AContext: TNXTestContext);
var lFixture: TTestCommitParser;
begin
  lFixture:=TTestCommitParser.Create(AContext, 'TestCommitTransactionWorkRetain');
  try
    lFixture.SetUp;
    try lFixture.TestCommitTransactionWorkRetain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCommitParserTestCommitTransactionReleaseRetain(AContext: TNXTestContext);
var lFixture: TTestCommitParser;
begin
  lFixture:=TTestCommitParser.Create(AContext, 'TestCommitTransactionReleaseRetain');
  try
    lFixture.SetUp;
    try lFixture.TestCommitTransactionReleaseRetain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCommitParserTestCommitTransactionWorkReleaseRetain(AContext: TNXTestContext);
var lFixture: TTestCommitParser;
begin
  lFixture:=TTestCommitParser.Create(AContext, 'TestCommitTransactionWorkReleaseRetain');
  try
    lFixture.SetUp;
    try lFixture.TestCommitTransactionWorkReleaseRetain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCommitParserTestCommitRetainSnapShot(AContext: TNXTestContext);
var lFixture: TTestCommitParser;
begin
  lFixture:=TTestCommitParser.Create(AContext, 'TestCommitRetainSnapShot');
  try
    lFixture.SetUp;
    try lFixture.TestCommitRetainSnapShot; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestExecuteProcedureParserTestExecuteSimple(AContext: TNXTestContext);
var lFixture: TTestExecuteProcedureParser;
begin
  lFixture:=TTestExecuteProcedureParser.Create(AContext, 'TestExecuteSimple');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteSimple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestExecuteProcedureParserTestExecuteSimpleTransaction(AContext: TNXTestContext);
var lFixture: TTestExecuteProcedureParser;
begin
  lFixture:=TTestExecuteProcedureParser.Create(AContext, 'TestExecuteSimpleTransaction');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteSimpleTransaction; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestExecuteProcedureParserTestExecuteSimpleReturningValues(AContext: TNXTestContext);
var lFixture: TTestExecuteProcedureParser;
begin
  lFixture:=TTestExecuteProcedureParser.Create(AContext, 'TestExecuteSimpleReturningValues');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteSimpleReturningValues; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestExecuteProcedureParserTestExecuteSimpleReturning2Values(AContext: TNXTestContext);
var lFixture: TTestExecuteProcedureParser;
begin
  lFixture:=TTestExecuteProcedureParser.Create(AContext, 'TestExecuteSimpleReturning2Values');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteSimpleReturning2Values; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestExecuteProcedureParserTestExecuteOneArg(AContext: TNXTestContext);
var lFixture: TTestExecuteProcedureParser;
begin
  lFixture:=TTestExecuteProcedureParser.Create(AContext, 'TestExecuteOneArg');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteOneArg; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestExecuteProcedureParserTestExecuteOneArgNB(AContext: TNXTestContext);
var lFixture: TTestExecuteProcedureParser;
begin
  lFixture:=TTestExecuteProcedureParser.Create(AContext, 'TestExecuteOneArgNB');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteOneArgNB; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestExecuteProcedureParserTestExecuteTwoArgs(AContext: TNXTestContext);
var lFixture: TTestExecuteProcedureParser;
begin
  lFixture:=TTestExecuteProcedureParser.Create(AContext, 'TestExecuteTwoArgs');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteTwoArgs; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestExecuteProcedureParserTestExecuteTwoArgsNB(AContext: TNXTestContext);
var lFixture: TTestExecuteProcedureParser;
begin
  lFixture:=TTestExecuteProcedureParser.Create(AContext, 'TestExecuteTwoArgsNB');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteTwoArgsNB; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestExecuteProcedureParserTestExecuteOneArgSelect(AContext: TNXTestContext);
var lFixture: TTestExecuteProcedureParser;
begin
  lFixture:=TTestExecuteProcedureParser.Create(AContext, 'TestExecuteOneArgSelect');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteOneArgSelect; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestExecuteProcedureParserTestExecuteOneArgSelectNB(AContext: TNXTestContext);
var lFixture: TTestExecuteProcedureParser;
begin
  lFixture:=TTestExecuteProcedureParser.Create(AContext, 'TestExecuteOneArgSelectNB');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteOneArgSelectNB; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestExecuteProcedureParserTestExecuteTwoArgsSelect(AContext: TNXTestContext);
var lFixture: TTestExecuteProcedureParser;
begin
  lFixture:=TTestExecuteProcedureParser.Create(AContext, 'TestExecuteTwoArgsSelect');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteTwoArgsSelect; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestExecuteProcedureParserTestExecuteTwoArgsSelectNB(AContext: TNXTestContext);
var lFixture: TTestExecuteProcedureParser;
begin
  lFixture:=TTestExecuteProcedureParser.Create(AContext, 'TestExecuteTwoArgsSelectNB');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteTwoArgsSelectNB; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestExecuteProcedureParserTestExecuteOneArgSelectErr(AContext: TNXTestContext);
var lFixture: TTestExecuteProcedureParser;
begin
  lFixture:=TTestExecuteProcedureParser.Create(AContext, 'TestExecuteOneArgSelectErr');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteOneArgSelectErr; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestExecuteProcedureParserTestExecuteOneArgSelectErr2(AContext: TNXTestContext);
var lFixture: TTestExecuteProcedureParser;
begin
  lFixture:=TTestExecuteProcedureParser.Create(AContext, 'TestExecuteOneArgSelectErr2');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteOneArgSelectErr2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestExecuteProcedureParserTestExecuteOneArgSelectErr3(AContext: TNXTestContext);
var lFixture: TTestExecuteProcedureParser;
begin
  lFixture:=TTestExecuteProcedureParser.Create(AContext, 'TestExecuteOneArgSelectErr3');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteOneArgSelectErr3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestExecuteProcedureParserTestExecuteOneArgSelectErr4(AContext: TNXTestContext);
var lFixture: TTestExecuteProcedureParser;
begin
  lFixture:=TTestExecuteProcedureParser.Create(AContext, 'TestExecuteOneArgSelectErr4');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteOneArgSelectErr4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestConnectParserTestConnectSimple(AContext: TNXTestContext);
var lFixture: TTestConnectParser;
begin
  lFixture:=TTestConnectParser.Create(AContext, 'TestConnectSimple');
  try
    lFixture.SetUp;
    try lFixture.TestConnectSimple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestConnectParserTestConnectUser(AContext: TNXTestContext);
var lFixture: TTestConnectParser;
begin
  lFixture:=TTestConnectParser.Create(AContext, 'TestConnectUser');
  try
    lFixture.SetUp;
    try lFixture.TestConnectUser; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestConnectParserTestConnectPassword(AContext: TNXTestContext);
var lFixture: TTestConnectParser;
begin
  lFixture:=TTestConnectParser.Create(AContext, 'TestConnectPassword');
  try
    lFixture.SetUp;
    try lFixture.TestConnectPassword; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestConnectParserTestConnectUserPassword(AContext: TNXTestContext);
var lFixture: TTestConnectParser;
begin
  lFixture:=TTestConnectParser.Create(AContext, 'TestConnectUserPassword');
  try
    lFixture.SetUp;
    try lFixture.TestConnectUserPassword; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestConnectParserTestConnectUserPasswordRole(AContext: TNXTestContext);
var lFixture: TTestConnectParser;
begin
  lFixture:=TTestConnectParser.Create(AContext, 'TestConnectUserPasswordRole');
  try
    lFixture.SetUp;
    try lFixture.TestConnectUserPasswordRole; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestConnectParserTestConnectUserPasswordRoleCache(AContext: TNXTestContext);
var lFixture: TTestConnectParser;
begin
  lFixture:=TTestConnectParser.Create(AContext, 'TestConnectUserPasswordRoleCache');
  try
    lFixture.SetUp;
    try lFixture.TestConnectUserPasswordRoleCache; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestConnectParserTestConnectSimpleCache(AContext: TNXTestContext);
var lFixture: TTestConnectParser;
begin
  lFixture:=TTestConnectParser.Create(AContext, 'TestConnectSimpleCache');
  try
    lFixture.SetUp;
    try lFixture.TestConnectSimpleCache; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestSimple(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestSimple');
  try
    lFixture.SetUp;
    try lFixture.TestSimple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestSimpleSchema(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestSimpleSchema');
  try
    lFixture.SetUp;
    try lFixture.TestSimpleSchema; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestSimpleUSer(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestSimpleUSer');
  try
    lFixture.SetUp;
    try lFixture.TestSimpleUSer; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestSimpleUSerPassword(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestSimpleUSerPassword');
  try
    lFixture.SetUp;
    try lFixture.TestSimpleUSerPassword; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestSimplePassword(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestSimplePassword');
  try
    lFixture.SetUp;
    try lFixture.TestSimplePassword; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestPageSize(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestPageSize');
  try
    lFixture.SetUp;
    try lFixture.TestPageSize; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestPageSize2(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestPageSize2');
  try
    lFixture.SetUp;
    try lFixture.TestPageSize2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestPageSizeLength(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestPageSizeLength');
  try
    lFixture.SetUp;
    try lFixture.TestPageSizeLength; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestPageSizeLength2(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestPageSizeLength2');
  try
    lFixture.SetUp;
    try lFixture.TestPageSizeLength2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestPageSizeLength3(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestPageSizeLength3');
  try
    lFixture.SetUp;
    try lFixture.TestPageSizeLength3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestPageSizeLength4(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestPageSizeLength4');
  try
    lFixture.SetUp;
    try lFixture.TestPageSizeLength4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestCharset(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestCharset');
  try
    lFixture.SetUp;
    try lFixture.TestCharset; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestSecondaryFile1(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestSecondaryFile1');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFile1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestSecondaryFile2(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestSecondaryFile2');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFile2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestSecondaryFile3(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestSecondaryFile3');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFile3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestSecondaryFile4(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestSecondaryFile4');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFile4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestSecondaryFile5(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestSecondaryFile5');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFile5; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestSecondaryFile6(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestSecondaryFile6');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFile6; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestSecondaryFile7(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestSecondaryFile7');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFile7; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestSecondaryFile8(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestSecondaryFile8');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFile8; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestSecondaryFile9(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestSecondaryFile9');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFile9; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestSecondaryFile10(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestSecondaryFile10');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFile10; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestSecondaryFileS(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestSecondaryFileS');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFileS; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestSecondaryFileError1(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestSecondaryFileError1');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFileError1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestSecondaryFileError2(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestSecondaryFileError2');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFileError2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateDatabaseParserTestSecondaryFileError3(AContext: TNXTestContext);
var lFixture: TTestCreateDatabaseParser;
begin
  lFixture:=TTestCreateDatabaseParser.Create(AContext, 'TestSecondaryFileError3');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFileError3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestAlterDatabaseParserTestSimple(AContext: TNXTestContext);
var lFixture: TTestAlterDatabaseParser;
begin
  lFixture:=TTestAlterDatabaseParser.Create(AContext, 'TestSimple');
  try
    lFixture.SetUp;
    try lFixture.TestSimple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestAlterDatabaseParserTestLength(AContext: TNXTestContext);
var lFixture: TTestAlterDatabaseParser;
begin
  lFixture:=TTestAlterDatabaseParser.Create(AContext, 'TestLength');
  try
    lFixture.SetUp;
    try lFixture.TestLength; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestAlterDatabaseParserTestStarting(AContext: TNXTestContext);
var lFixture: TTestAlterDatabaseParser;
begin
  lFixture:=TTestAlterDatabaseParser.Create(AContext, 'TestStarting');
  try
    lFixture.SetUp;
    try lFixture.TestStarting; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestAlterDatabaseParserTestStartingLength(AContext: TNXTestContext);
var lFixture: TTestAlterDatabaseParser;
begin
  lFixture:=TTestAlterDatabaseParser.Create(AContext, 'TestStartingLength');
  try
    lFixture.SetUp;
    try lFixture.TestStartingLength; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestAlterDatabaseParserTestFiles(AContext: TNXTestContext);
var lFixture: TTestAlterDatabaseParser;
begin
  lFixture:=TTestAlterDatabaseParser.Create(AContext, 'TestFiles');
  try
    lFixture.SetUp;
    try lFixture.TestFiles; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestAlterDatabaseParserTestFiles2(AContext: TNXTestContext);
var lFixture: TTestAlterDatabaseParser;
begin
  lFixture:=TTestAlterDatabaseParser.Create(AContext, 'TestFiles2');
  try
    lFixture.SetUp;
    try lFixture.TestFiles2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestAlterDatabaseParserTestError(AContext: TNXTestContext);
var lFixture: TTestAlterDatabaseParser;
begin
  lFixture:=TTestAlterDatabaseParser.Create(AContext, 'TestError');
  try
    lFixture.SetUp;
    try lFixture.TestError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestAlterDatabaseParserTestFilesError(AContext: TNXTestContext);
var lFixture: TTestAlterDatabaseParser;
begin
  lFixture:=TTestAlterDatabaseParser.Create(AContext, 'TestFilesError');
  try
    lFixture.SetUp;
    try lFixture.TestFilesError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateViewParserTestSimple(AContext: TNXTestContext);
var lFixture: TTestCreateViewParser;
begin
  lFixture:=TTestCreateViewParser.Create(AContext, 'TestSimple');
  try
    lFixture.SetUp;
    try lFixture.TestSimple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateViewParserTestFieldList(AContext: TNXTestContext);
var lFixture: TTestCreateViewParser;
begin
  lFixture:=TTestCreateViewParser.Create(AContext, 'TestFieldList');
  try
    lFixture.SetUp;
    try lFixture.TestFieldList; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateViewParserTestFieldList2(AContext: TNXTestContext);
var lFixture: TTestCreateViewParser;
begin
  lFixture:=TTestCreateViewParser.Create(AContext, 'TestFieldList2');
  try
    lFixture.SetUp;
    try lFixture.TestFieldList2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateViewParserTestSimpleWithCheckoption(AContext: TNXTestContext);
var lFixture: TTestCreateViewParser;
begin
  lFixture:=TTestCreateViewParser.Create(AContext, 'TestSimpleWithCheckoption');
  try
    lFixture.SetUp;
    try lFixture.TestSimpleWithCheckoption; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateShadowParserTestSimple(AContext: TNXTestContext);
var lFixture: TTestCreateShadowParser;
begin
  lFixture:=TTestCreateShadowParser.Create(AContext, 'TestSimple');
  try
    lFixture.SetUp;
    try lFixture.TestSimple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateShadowParserTestLength(AContext: TNXTestContext);
var lFixture: TTestCreateShadowParser;
begin
  lFixture:=TTestCreateShadowParser.Create(AContext, 'TestLength');
  try
    lFixture.SetUp;
    try lFixture.TestLength; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateShadowParserTestLength2(AContext: TNXTestContext);
var lFixture: TTestCreateShadowParser;
begin
  lFixture:=TTestCreateShadowParser.Create(AContext, 'TestLength2');
  try
    lFixture.SetUp;
    try lFixture.TestLength2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateShadowParserTestLength3(AContext: TNXTestContext);
var lFixture: TTestCreateShadowParser;
begin
  lFixture:=TTestCreateShadowParser.Create(AContext, 'TestLength3');
  try
    lFixture.SetUp;
    try lFixture.TestLength3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateShadowParserTestLength4(AContext: TNXTestContext);
var lFixture: TTestCreateShadowParser;
begin
  lFixture:=TTestCreateShadowParser.Create(AContext, 'TestLength4');
  try
    lFixture.SetUp;
    try lFixture.TestLength4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateShadowParserTestSecondaryFile1(AContext: TNXTestContext);
var lFixture: TTestCreateShadowParser;
begin
  lFixture:=TTestCreateShadowParser.Create(AContext, 'TestSecondaryFile1');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFile1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateShadowParserTestSecondaryFile2(AContext: TNXTestContext);
var lFixture: TTestCreateShadowParser;
begin
  lFixture:=TTestCreateShadowParser.Create(AContext, 'TestSecondaryFile2');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFile2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateShadowParserTestSecondaryFile3(AContext: TNXTestContext);
var lFixture: TTestCreateShadowParser;
begin
  lFixture:=TTestCreateShadowParser.Create(AContext, 'TestSecondaryFile3');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFile3; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateShadowParserTestSecondaryFile4(AContext: TNXTestContext);
var lFixture: TTestCreateShadowParser;
begin
  lFixture:=TTestCreateShadowParser.Create(AContext, 'TestSecondaryFile4');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFile4; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateShadowParserTestSecondaryFile5(AContext: TNXTestContext);
var lFixture: TTestCreateShadowParser;
begin
  lFixture:=TTestCreateShadowParser.Create(AContext, 'TestSecondaryFile5');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFile5; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateShadowParserTestSecondaryFile6(AContext: TNXTestContext);
var lFixture: TTestCreateShadowParser;
begin
  lFixture:=TTestCreateShadowParser.Create(AContext, 'TestSecondaryFile6');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFile6; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateShadowParserTestSecondaryFile7(AContext: TNXTestContext);
var lFixture: TTestCreateShadowParser;
begin
  lFixture:=TTestCreateShadowParser.Create(AContext, 'TestSecondaryFile7');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFile7; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateShadowParserTestSecondaryFile8(AContext: TNXTestContext);
var lFixture: TTestCreateShadowParser;
begin
  lFixture:=TTestCreateShadowParser.Create(AContext, 'TestSecondaryFile8');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFile8; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateShadowParserTestSecondaryFileS(AContext: TNXTestContext);
var lFixture: TTestCreateShadowParser;
begin
  lFixture:=TTestCreateShadowParser.Create(AContext, 'TestSecondaryFileS');
  try
    lFixture.SetUp;
    try lFixture.TestSecondaryFileS; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestException(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestException');
  try
    lFixture.SetUp;
    try lFixture.TestException; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestExceptionError(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestExceptionError');
  try
    lFixture.SetUp;
    try lFixture.TestExceptionError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestExit(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestExit');
  try
    lFixture.SetUp;
    try lFixture.TestExit; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestSuspend(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestSuspend');
  try
    lFixture.SetUp;
    try lFixture.TestSuspend; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestEmptyBlock(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestEmptyBlock');
  try
    lFixture.SetUp;
    try lFixture.TestEmptyBlock; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestExitBlock(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestExitBlock');
  try
    lFixture.SetUp;
    try lFixture.TestExitBlock; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestExitBlockError(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestExitBlockError');
  try
    lFixture.SetUp;
    try lFixture.TestExitBlockError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestPostEvent(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestPostEvent');
  try
    lFixture.SetUp;
    try lFixture.TestPostEvent; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestPostEventColName(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestPostEventColName');
  try
    lFixture.SetUp;
    try lFixture.TestPostEventColName; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestPostError(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestPostError');
  try
    lFixture.SetUp;
    try lFixture.TestPostError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestAssignSimple(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestAssignSimple');
  try
    lFixture.SetUp;
    try lFixture.TestAssignSimple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestAssignSimpleNew(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestAssignSimpleNew');
  try
    lFixture.SetUp;
    try lFixture.TestAssignSimpleNew; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestAssignSelect(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestAssignSelect');
  try
    lFixture.SetUp;
    try lFixture.TestAssignSelect; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestBlockAssignSimple(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestBlockAssignSimple');
  try
    lFixture.SetUp;
    try lFixture.TestBlockAssignSimple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestIf(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestIf');
  try
    lFixture.SetUp;
    try lFixture.TestIf; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestIfBlock(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestIfBlock');
  try
    lFixture.SetUp;
    try lFixture.TestIfBlock; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestIfElse(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestIfElse');
  try
    lFixture.SetUp;
    try lFixture.TestIfElse; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestIfBlockElse(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestIfBlockElse');
  try
    lFixture.SetUp;
    try lFixture.TestIfBlockElse; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestIfElseError(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestIfElseError');
  try
    lFixture.SetUp;
    try lFixture.TestIfElseError; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestIfBlockElseBlock(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestIfBlockElseBlock');
  try
    lFixture.SetUp;
    try lFixture.TestIfBlockElseBlock; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestIfErrorBracketLeft(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestIfErrorBracketLeft');
  try
    lFixture.SetUp;
    try lFixture.TestIfErrorBracketLeft; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestIfErrorBracketRight(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestIfErrorBracketRight');
  try
    lFixture.SetUp;
    try lFixture.TestIfErrorBracketRight; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestIfErrorNoThen(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestIfErrorNoThen');
  try
    lFixture.SetUp;
    try lFixture.TestIfErrorNoThen; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestIfErrorSemicolonElse(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestIfErrorSemicolonElse');
  try
    lFixture.SetUp;
    try lFixture.TestIfErrorSemicolonElse; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestWhile(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestWhile');
  try
    lFixture.SetUp;
    try lFixture.TestWhile; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestWhileBlock(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestWhileBlock');
  try
    lFixture.SetUp;
    try lFixture.TestWhileBlock; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestWhileErrorBracketLeft(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestWhileErrorBracketLeft');
  try
    lFixture.SetUp;
    try lFixture.TestWhileErrorBracketLeft; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestWhileErrorBracketRight(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestWhileErrorBracketRight');
  try
    lFixture.SetUp;
    try lFixture.TestWhileErrorBracketRight; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestWhileErrorNoDo(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestWhileErrorNoDo');
  try
    lFixture.SetUp;
    try lFixture.TestWhileErrorNoDo; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestWhenAny(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestWhenAny');
  try
    lFixture.SetUp;
    try lFixture.TestWhenAny; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestWhenSQLCode(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestWhenSQLCode');
  try
    lFixture.SetUp;
    try lFixture.TestWhenSQLCode; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestWhenGDSCode(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestWhenGDSCode');
  try
    lFixture.SetUp;
    try lFixture.TestWhenGDSCode; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestWhenException(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestWhenException');
  try
    lFixture.SetUp;
    try lFixture.TestWhenException; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestWhenExceptionGDS(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestWhenExceptionGDS');
  try
    lFixture.SetUp;
    try lFixture.TestWhenExceptionGDS; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestWhenAnyBlock(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestWhenAnyBlock');
  try
    lFixture.SetUp;
    try lFixture.TestWhenAnyBlock; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestWhenErrorAny(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestWhenErrorAny');
  try
    lFixture.SetUp;
    try lFixture.TestWhenErrorAny; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestWhenErrorNoDo(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestWhenErrorNoDo');
  try
    lFixture.SetUp;
    try lFixture.TestWhenErrorNoDo; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestWhenErrorExceptionInt(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestWhenErrorExceptionInt');
  try
    lFixture.SetUp;
    try lFixture.TestWhenErrorExceptionInt; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestWhenErrorExceptionString(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestWhenErrorExceptionString');
  try
    lFixture.SetUp;
    try lFixture.TestWhenErrorExceptionString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestWhenErrorSqlCode(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestWhenErrorSqlCode');
  try
    lFixture.SetUp;
    try lFixture.TestWhenErrorSqlCode; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestWhenErrorGDSCode(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestWhenErrorGDSCode');
  try
    lFixture.SetUp;
    try lFixture.TestWhenErrorGDSCode; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestExecuteStatement(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestExecuteStatement');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteStatement; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestExecuteStatementReturningValues(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestExecuteStatementReturningValues');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteStatementReturningValues; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestExecuteStatementReturningValuesColon(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestExecuteStatementReturningValuesColon');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteStatementReturningValuesColon; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestExecuteStatementReturningValuesBrackets(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestExecuteStatementReturningValuesBrackets');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteStatementReturningValuesBrackets; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestForSimple(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestForSimple');
  try
    lFixture.SetUp;
    try lFixture.TestForSimple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestForSimpleNoColon(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestForSimpleNoColon');
  try
    lFixture.SetUp;
    try lFixture.TestForSimpleNoColon; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestForSimple2fields(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestForSimple2fields');
  try
    lFixture.SetUp;
    try lFixture.TestForSimple2fields; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestProcedureStatementTestForBlock(AContext: TNXTestContext);
var lFixture: TTestProcedureStatement;
begin
  lFixture:=TTestProcedureStatement.Create(AContext, 'TestForBlock');
  try
    lFixture.SetUp;
    try lFixture.TestForBlock; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateProcedureParserTestEmptyProcedure(AContext: TNXTestContext);
var lFixture: TTestCreateProcedureParser;
begin
  lFixture:=TTestCreateProcedureParser.Create(AContext, 'TestEmptyProcedure');
  try
    lFixture.SetUp;
    try lFixture.TestEmptyProcedure; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateProcedureParserTestExitProcedure(AContext: TNXTestContext);
var lFixture: TTestCreateProcedureParser;
begin
  lFixture:=TTestCreateProcedureParser.Create(AContext, 'TestExitProcedure');
  try
    lFixture.SetUp;
    try lFixture.TestExitProcedure; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateProcedureParserTestProcedureOneArgument(AContext: TNXTestContext);
var lFixture: TTestCreateProcedureParser;
begin
  lFixture:=TTestCreateProcedureParser.Create(AContext, 'TestProcedureOneArgument');
  try
    lFixture.SetUp;
    try lFixture.TestProcedureOneArgument; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateProcedureParserTestProcedureTwoArguments(AContext: TNXTestContext);
var lFixture: TTestCreateProcedureParser;
begin
  lFixture:=TTestCreateProcedureParser.Create(AContext, 'TestProcedureTwoArguments');
  try
    lFixture.SetUp;
    try lFixture.TestProcedureTwoArguments; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateProcedureParserTestProcedureOneReturnValue(AContext: TNXTestContext);
var lFixture: TTestCreateProcedureParser;
begin
  lFixture:=TTestCreateProcedureParser.Create(AContext, 'TestProcedureOneReturnValue');
  try
    lFixture.SetUp;
    try lFixture.TestProcedureOneReturnValue; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateProcedureParserTestProcedureTwoReturnValues(AContext: TNXTestContext);
var lFixture: TTestCreateProcedureParser;
begin
  lFixture:=TTestCreateProcedureParser.Create(AContext, 'TestProcedureTwoReturnValues');
  try
    lFixture.SetUp;
    try lFixture.TestProcedureTwoReturnValues; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateProcedureParserTestProcedureOneLocalVariable(AContext: TNXTestContext);
var lFixture: TTestCreateProcedureParser;
begin
  lFixture:=TTestCreateProcedureParser.Create(AContext, 'TestProcedureOneLocalVariable');
  try
    lFixture.SetUp;
    try lFixture.TestProcedureOneLocalVariable; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateProcedureParserTestProcedureTwoLocalVariable(AContext: TNXTestContext);
var lFixture: TTestCreateProcedureParser;
begin
  lFixture:=TTestCreateProcedureParser.Create(AContext, 'TestProcedureTwoLocalVariable');
  try
    lFixture.SetUp;
    try lFixture.TestProcedureTwoLocalVariable; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateProcedureParserTestProcedureInputOutputLocal(AContext: TNXTestContext);
var lFixture: TTestCreateProcedureParser;
begin
  lFixture:=TTestCreateProcedureParser.Create(AContext, 'TestProcedureInputOutputLocal');
  try
    lFixture.SetUp;
    try lFixture.TestProcedureInputOutputLocal; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateTriggerParserTestEmptyTrigger(AContext: TNXTestContext);
var lFixture: TTestCreateTriggerParser;
begin
  lFixture:=TTestCreateTriggerParser.Create(AContext, 'TestEmptyTrigger');
  try
    lFixture.SetUp;
    try lFixture.TestEmptyTrigger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateTriggerParserTestExitTrigger(AContext: TNXTestContext);
var lFixture: TTestCreateTriggerParser;
begin
  lFixture:=TTestCreateTriggerParser.Create(AContext, 'TestExitTrigger');
  try
    lFixture.SetUp;
    try lFixture.TestExitTrigger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateTriggerParserTestEmptyTriggerAfterUpdate(AContext: TNXTestContext);
var lFixture: TTestCreateTriggerParser;
begin
  lFixture:=TTestCreateTriggerParser.Create(AContext, 'TestEmptyTriggerAfterUpdate');
  try
    lFixture.SetUp;
    try lFixture.TestEmptyTriggerAfterUpdate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateTriggerParserTestEmptyTriggerBeforeDelete(AContext: TNXTestContext);
var lFixture: TTestCreateTriggerParser;
begin
  lFixture:=TTestCreateTriggerParser.Create(AContext, 'TestEmptyTriggerBeforeDelete');
  try
    lFixture.SetUp;
    try lFixture.TestEmptyTriggerBeforeDelete; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateTriggerParserTestEmptyTriggerBeforeInsert(AContext: TNXTestContext);
var lFixture: TTestCreateTriggerParser;
begin
  lFixture:=TTestCreateTriggerParser.Create(AContext, 'TestEmptyTriggerBeforeInsert');
  try
    lFixture.SetUp;
    try lFixture.TestEmptyTriggerBeforeInsert; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateTriggerParserTestEmptyTriggerBeforeInsertPosition1(AContext: TNXTestContext);
var lFixture: TTestCreateTriggerParser;
begin
  lFixture:=TTestCreateTriggerParser.Create(AContext, 'TestEmptyTriggerBeforeInsertPosition1');
  try
    lFixture.SetUp;
    try lFixture.TestEmptyTriggerBeforeInsertPosition1; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateTriggerParserTestEmptyTriggerBeforeInsertPosition1inActive(AContext: TNXTestContext);
var lFixture: TTestCreateTriggerParser;
begin
  lFixture:=TTestCreateTriggerParser.Create(AContext, 'TestEmptyTriggerBeforeInsertPosition1inActive');
  try
    lFixture.SetUp;
    try lFixture.TestEmptyTriggerBeforeInsertPosition1inActive; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateTriggerParserTestEmptyTriggerBeforeInsertPosition1Active(AContext: TNXTestContext);
var lFixture: TTestCreateTriggerParser;
begin
  lFixture:=TTestCreateTriggerParser.Create(AContext, 'TestEmptyTriggerBeforeInsertPosition1Active');
  try
    lFixture.SetUp;
    try lFixture.TestEmptyTriggerBeforeInsertPosition1Active; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateTriggerParserTestTriggerOneLocalVariable(AContext: TNXTestContext);
var lFixture: TTestCreateTriggerParser;
begin
  lFixture:=TTestCreateTriggerParser.Create(AContext, 'TestTriggerOneLocalVariable');
  try
    lFixture.SetUp;
    try lFixture.TestTriggerOneLocalVariable; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateTriggerParserTestTriggerTwoLocalVariables(AContext: TNXTestContext);
var lFixture: TTestCreateTriggerParser;
begin
  lFixture:=TTestCreateTriggerParser.Create(AContext, 'TestTriggerTwoLocalVariables');
  try
    lFixture.SetUp;
    try lFixture.TestTriggerTwoLocalVariables; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCreateTriggerParserTestAlterTrigger(AContext: TNXTestContext);
var lFixture: TTestCreateTriggerParser;
begin
  lFixture:=TTestCreateTriggerParser.Create(AContext, 'TestAlterTrigger');
  try
    lFixture.SetUp;
    try lFixture.TestAlterTrigger; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclareExternalFunctionParserTestEmptyfunction(AContext: TNXTestContext);
var lFixture: TTestDeclareExternalFunctionParser;
begin
  lFixture:=TTestDeclareExternalFunctionParser.Create(AContext, 'TestEmptyfunction');
  try
    lFixture.SetUp;
    try lFixture.TestEmptyfunction; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclareExternalFunctionParserTestEmptyfunctionByValue(AContext: TNXTestContext);
var lFixture: TTestDeclareExternalFunctionParser;
begin
  lFixture:=TTestDeclareExternalFunctionParser.Create(AContext, 'TestEmptyfunctionByValue');
  try
    lFixture.SetUp;
    try lFixture.TestEmptyfunctionByValue; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclareExternalFunctionParserTestCStringfunction(AContext: TNXTestContext);
var lFixture: TTestDeclareExternalFunctionParser;
begin
  lFixture:=TTestDeclareExternalFunctionParser.Create(AContext, 'TestCStringfunction');
  try
    lFixture.SetUp;
    try lFixture.TestCStringfunction; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclareExternalFunctionParserTestCStringFreeItfunction(AContext: TNXTestContext);
var lFixture: TTestDeclareExternalFunctionParser;
begin
  lFixture:=TTestDeclareExternalFunctionParser.Create(AContext, 'TestCStringFreeItfunction');
  try
    lFixture.SetUp;
    try lFixture.TestCStringFreeItfunction; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclareExternalFunctionParserTestOneArgumentFunction(AContext: TNXTestContext);
var lFixture: TTestDeclareExternalFunctionParser;
begin
  lFixture:=TTestDeclareExternalFunctionParser.Create(AContext, 'TestOneArgumentFunction');
  try
    lFixture.SetUp;
    try lFixture.TestOneArgumentFunction; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestDeclareExternalFunctionParserTestTwoArgumentsFunction(AContext: TNXTestContext);
var lFixture: TTestDeclareExternalFunctionParser;
begin
  lFixture:=TTestDeclareExternalFunctionParser.Create(AContext, 'TestTwoArgumentsFunction');
  try
    lFixture.SetUp;
    try lFixture.TestTwoArgumentsFunction; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestSimple(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestSimple');
  try
    lFixture.SetUp;
    try lFixture.TestSimple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTest2Operations(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'Test2Operations');
  try
    lFixture.SetUp;
    try lFixture.Test2Operations; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestDeletePrivilege(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestDeletePrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestDeletePrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestUpdatePrivilege(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestUpdatePrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestUpdatePrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestInsertPrivilege(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestInsertPrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestInsertPrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestReferencePrivilege(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestReferencePrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestReferencePrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestAllPrivileges(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestAllPrivileges');
  try
    lFixture.SetUp;
    try lFixture.TestAllPrivileges; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestAllPrivileges2(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestAllPrivileges2');
  try
    lFixture.SetUp;
    try lFixture.TestAllPrivileges2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestUpdateColPrivilege(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestUpdateColPrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestUpdateColPrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestUpdate2ColsPrivilege(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestUpdate2ColsPrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestUpdate2ColsPrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestReferenceColPrivilege(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestReferenceColPrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestReferenceColPrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestReference2ColsPrivilege(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestReference2ColsPrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestReference2ColsPrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestUserPrivilege(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestUserPrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestUserPrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestUserPrivilegeWithGrant(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestUserPrivilegeWithGrant');
  try
    lFixture.SetUp;
    try lFixture.TestUserPrivilegeWithGrant; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestGroupPrivilege(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestGroupPrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestGroupPrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestProcedurePrivilege(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestProcedurePrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestProcedurePrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestViewPrivilege(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestViewPrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestViewPrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestTriggerPrivilege(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestTriggerPrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestTriggerPrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestPublicPrivilege(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestPublicPrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestPublicPrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestExecuteToUser(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestExecuteToUser');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteToUser; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestExecuteToProcedure(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestExecuteToProcedure');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteToProcedure; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestRoleToUser(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestRoleToUser');
  try
    lFixture.SetUp;
    try lFixture.TestRoleToUser; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestRoleToUserWithAdmin(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestRoleToUserWithAdmin');
  try
    lFixture.SetUp;
    try lFixture.TestRoleToUserWithAdmin; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTestRoleToPublic(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'TestRoleToPublic');
  try
    lFixture.SetUp;
    try lFixture.TestRoleToPublic; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGrantParserTest2RolesToUser(AContext: TNXTestContext);
var lFixture: TTestGrantParser;
begin
  lFixture:=TTestGrantParser.Create(AContext, 'Test2RolesToUser');
  try
    lFixture.SetUp;
    try lFixture.Test2RolesToUser; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestSimple(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestSimple');
  try
    lFixture.SetUp;
    try lFixture.TestSimple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTest2Operations(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'Test2Operations');
  try
    lFixture.SetUp;
    try lFixture.Test2Operations; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestDeletePrivilege(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestDeletePrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestDeletePrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestUpdatePrivilege(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestUpdatePrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestUpdatePrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestInsertPrivilege(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestInsertPrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestInsertPrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestReferencePrivilege(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestReferencePrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestReferencePrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestAllPrivileges(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestAllPrivileges');
  try
    lFixture.SetUp;
    try lFixture.TestAllPrivileges; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestAllPrivileges2(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestAllPrivileges2');
  try
    lFixture.SetUp;
    try lFixture.TestAllPrivileges2; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestUpdateColPrivilege(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestUpdateColPrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestUpdateColPrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestUpdate2ColsPrivilege(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestUpdate2ColsPrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestUpdate2ColsPrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestReferenceColPrivilege(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestReferenceColPrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestReferenceColPrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestReference2ColsPrivilege(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestReference2ColsPrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestReference2ColsPrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestUserPrivilege(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestUserPrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestUserPrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestUserPrivilegeWithRevoke(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestUserPrivilegeWithRevoke');
  try
    lFixture.SetUp;
    try lFixture.TestUserPrivilegeWithRevoke; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestGroupPrivilege(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestGroupPrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestGroupPrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestProcedurePrivilege(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestProcedurePrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestProcedurePrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestViewPrivilege(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestViewPrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestViewPrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestTriggerPrivilege(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestTriggerPrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestTriggerPrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestPublicPrivilege(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestPublicPrivilege');
  try
    lFixture.SetUp;
    try lFixture.TestPublicPrivilege; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestExecuteToUser(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestExecuteToUser');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteToUser; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestExecuteToProcedure(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestExecuteToProcedure');
  try
    lFixture.SetUp;
    try lFixture.TestExecuteToProcedure; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestRoleToUser(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestRoleToUser');
  try
    lFixture.SetUp;
    try lFixture.TestRoleToUser; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTestRoleToPublic(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'TestRoleToPublic');
  try
    lFixture.SetUp;
    try lFixture.TestRoleToPublic; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestRevokeParserTest2RolesToUser(AContext: TNXTestContext);
var lFixture: TTestRevokeParser;
begin
  lFixture:=TTestRevokeParser.Create(AContext, 'Test2RolesToUser');
  try
    lFixture.SetUp;
    try lFixture.Test2RolesToUser; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestGlobalParserTestEmpty(AContext: TNXTestContext);
var lFixture: TTestGlobalParser;
begin
  lFixture:=TTestGlobalParser.Create(AContext, 'TestEmpty');
  try
    lFixture.SetUp;
    try lFixture.TestEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegistertcparserTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcparser.TTestDropParser');
  lSuite.AddTest('TestDropDatabase', @RunTTestDropParserTestDropDatabase);
  lSuite.AddTest('TestDropDomain', @RunTTestDropParserTestDropDomain);
  lSuite.AddTest('TestDropException', @RunTTestDropParserTestDropException);
  lSuite.AddTest('TestDropGenerator', @RunTTestDropParserTestDropGenerator);
  lSuite.AddTest('TestDropIndex', @RunTTestDropParserTestDropIndex);
  lSuite.AddTest('TestDropProcedure', @RunTTestDropParserTestDropProcedure);
  lSuite.AddTest('TestDropRole', @RunTTestDropParserTestDropRole);
  lSuite.AddTest('TestDropTable', @RunTTestDropParserTestDropTable);
  lSuite.AddTest('TestDropTrigger', @RunTTestDropParserTestDropTrigger);
  lSuite.AddTest('TestDropView', @RunTTestDropParserTestDropView);
  lSuite.AddTest('TestDropShadow', @RunTTestDropParserTestDropShadow);
  lSuite.AddTest('TestDropExternalFunction', @RunTTestDropParserTestDropExternalFunction);
  lSuite:=ARegistry.AddSuite('tcparser.TTestGeneratorParser');
  lSuite.AddTest('TestCreateGenerator', @RunTTestGeneratorParserTestCreateGenerator);
  lSuite.AddTest('TestCreateSequence', @RunTTestGeneratorParserTestCreateSequence);
  lSuite.AddTest('TestAlterSequence', @RunTTestGeneratorParserTestAlterSequence);
  lSuite.AddTest('TestSetGenerator', @RunTTestGeneratorParserTestSetGenerator);
  lSuite:=ARegistry.AddSuite('tcparser.TTestSetTermParser');
  lSuite.AddTest('TestSetTermNoOption', @RunTTestSetTermParserTestSetTermNoOption);
  lSuite.AddTest('TestSetTermOption', @RunTTestSetTermParserTestSetTermOption);
  lSuite:=ARegistry.AddSuite('tcparser.TTestRoleParser');
  lSuite.AddTest('TestCreateRole', @RunTTestRoleParserTestCreateRole);
  lSuite.AddTest('TestAlterRole', @RunTTestRoleParserTestAlterRole);
  lSuite:=ARegistry.AddSuite('tcparser.TTestTypeParser');
  lSuite.AddTest('TestStringType1', @RunTTestTypeParserTestStringType1);
  lSuite.AddTest('TestStringType2', @RunTTestTypeParserTestStringType2);
  lSuite.AddTest('TestStringType3', @RunTTestTypeParserTestStringType3);
  lSuite.AddTest('TestStringType4', @RunTTestTypeParserTestStringType4);
  lSuite.AddTest('TestStringType5', @RunTTestTypeParserTestStringType5);
  lSuite.AddTest('TestStringType6', @RunTTestTypeParserTestStringType6);
  lSuite.AddTest('TestStringType7', @RunTTestTypeParserTestStringType7);
  lSuite.AddTest('TestStringType8', @RunTTestTypeParserTestStringType8);
  lSuite.AddTest('TestStringType9', @RunTTestTypeParserTestStringType9);
  lSuite.AddTest('TestStringType10', @RunTTestTypeParserTestStringType10);
  lSuite.AddTest('TestStringType11', @RunTTestTypeParserTestStringType11);
  lSuite.AddTest('TestStringType12', @RunTTestTypeParserTestStringType12);
  lSuite.AddTest('TestStringType13', @RunTTestTypeParserTestStringType13);
  lSuite.AddTest('TestStringType14', @RunTTestTypeParserTestStringType14);
  lSuite.AddTest('TestStringType15', @RunTTestTypeParserTestStringType15);
  lSuite.AddTest('TestStringType16', @RunTTestTypeParserTestStringType16);
  lSuite.AddTest('TestStringType17', @RunTTestTypeParserTestStringType17);
  lSuite.AddTest('TestStringType18', @RunTTestTypeParserTestStringType18);
  lSuite.AddTest('TestStringType19', @RunTTestTypeParserTestStringType19);
  lSuite.AddTest('TestStringTypeErrors1', @RunTTestTypeParserTestStringTypeErrors1);
  lSuite.AddTest('TestStringTypeErrors2', @RunTTestTypeParserTestStringTypeErrors2);
  lSuite.AddTest('TestStringTypeErrors3', @RunTTestTypeParserTestStringTypeErrors3);
  lSuite.AddTest('TestTypeInt1', @RunTTestTypeParserTestTypeInt1);
  lSuite.AddTest('TestTypeInt2', @RunTTestTypeParserTestTypeInt2);
  lSuite.AddTest('TestTypeInt3', @RunTTestTypeParserTestTypeInt3);
  lSuite.AddTest('TestTypeInt4', @RunTTestTypeParserTestTypeInt4);
  lSuite.AddTest('TestTypeInt5', @RunTTestTypeParserTestTypeInt5);
  lSuite.AddTest('TestNumerical1', @RunTTestTypeParserTestNumerical1);
  lSuite.AddTest('TestNumerical2', @RunTTestTypeParserTestNumerical2);
  lSuite.AddTest('TestNumerical3', @RunTTestTypeParserTestNumerical3);
  lSuite.AddTest('TestNumericalError1', @RunTTestTypeParserTestNumericalError1);
  lSuite.AddTest('TestNumericalError2', @RunTTestTypeParserTestNumericalError2);
  lSuite.AddTest('TestNumericalError3', @RunTTestTypeParserTestNumericalError3);
  lSuite.AddTest('TestNumericalError4', @RunTTestTypeParserTestNumericalError4);
  lSuite.AddTest('TestNumericalError5', @RunTTestTypeParserTestNumericalError5);
  lSuite.AddTest('TestNumericalError6', @RunTTestTypeParserTestNumericalError6);
  lSuite.AddTest('TestNumericalError7', @RunTTestTypeParserTestNumericalError7);
  lSuite.AddTest('TestBlob1', @RunTTestTypeParserTestBlob1);
  lSuite.AddTest('TestBlob2', @RunTTestTypeParserTestBlob2);
  lSuite.AddTest('TestBlob3', @RunTTestTypeParserTestBlob3);
  lSuite.AddTest('TestBlob4', @RunTTestTypeParserTestBlob4);
  lSuite.AddTest('TestBlob5', @RunTTestTypeParserTestBlob5);
  lSuite.AddTest('TestBlob6', @RunTTestTypeParserTestBlob6);
  lSuite.AddTest('TestBlob7', @RunTTestTypeParserTestBlob7);
  lSuite.AddTest('TestBlob8', @RunTTestTypeParserTestBlob8);
  lSuite.AddTest('TestBlobError1', @RunTTestTypeParserTestBlobError1);
  lSuite.AddTest('TestBlobError2', @RunTTestTypeParserTestBlobError2);
  lSuite.AddTest('TestBlobError3', @RunTTestTypeParserTestBlobError3);
  lSuite.AddTest('TestBlobError4', @RunTTestTypeParserTestBlobError4);
  lSuite.AddTest('TestBlobError5', @RunTTestTypeParserTestBlobError5);
  lSuite.AddTest('TestBlobError6', @RunTTestTypeParserTestBlobError6);
  lSuite.AddTest('TestBlobError7', @RunTTestTypeParserTestBlobError7);
  lSuite.AddTest('TestSmallInt', @RunTTestTypeParserTestSmallInt);
  lSuite.AddTest('TestFloat', @RunTTestTypeParserTestFloat);
  lSuite.AddTest('TestDoublePrecision', @RunTTestTypeParserTestDoublePrecision);
  lSuite.AddTest('TestDoublePrecisionDefault', @RunTTestTypeParserTestDoublePrecisionDefault);
  lSuite:=ARegistry.AddSuite('tcparser.TTestCheckParser');
  lSuite.AddTest('TestCheckNull', @RunTTestCheckParserTestCheckNull);
  lSuite.AddTest('TestCheckNotNull', @RunTTestCheckParserTestCheckNotNull);
  lSuite.AddTest('TestCheckBraces', @RunTTestCheckParserTestCheckBraces);
  lSuite.AddTest('TestCheckBracesError', @RunTTestCheckParserTestCheckBracesError);
  lSuite.AddTest('TestCheckParamError', @RunTTestCheckParserTestCheckParamError);
  lSuite.AddTest('TestCheckIdentifierError', @RunTTestCheckParserTestCheckIdentifierError);
  lSuite.AddTest('TestIsEqual', @RunTTestCheckParserTestIsEqual);
  lSuite.AddTest('TestIsNotEqual1', @RunTTestCheckParserTestIsNotEqual1);
  lSuite.AddTest('TestIsNotEqual2', @RunTTestCheckParserTestIsNotEqual2);
  lSuite.AddTest('TestGreaterThan', @RunTTestCheckParserTestGreaterThan);
  lSuite.AddTest('TestGreaterThanEqual1', @RunTTestCheckParserTestGreaterThanEqual1);
  lSuite.AddTest('TestGreaterThanEqual2', @RunTTestCheckParserTestGreaterThanEqual2);
  lSuite.AddTest('TestLessThan', @RunTTestCheckParserTestLessThan);
  lSuite.AddTest('TestLessThanEqual1', @RunTTestCheckParserTestLessThanEqual1);
  lSuite.AddTest('TestLessThanEqual2', @RunTTestCheckParserTestLessThanEqual2);
  lSuite.AddTest('TestLike', @RunTTestCheckParserTestLike);
  lSuite.AddTest('TestNotLike', @RunTTestCheckParserTestNotLike);
  lSuite.AddTest('TestContaining', @RunTTestCheckParserTestContaining);
  lSuite.AddTest('TestNotContaining', @RunTTestCheckParserTestNotContaining);
  lSuite.AddTest('TestStarting', @RunTTestCheckParserTestStarting);
  lSuite.AddTest('TestNotStarting', @RunTTestCheckParserTestNotStarting);
  lSuite.AddTest('TestStartingWith', @RunTTestCheckParserTestStartingWith);
  lSuite.AddTest('TestNotStartingWith', @RunTTestCheckParserTestNotStartingWith);
  lSuite.AddTest('TestBetween', @RunTTestCheckParserTestBetween);
  lSuite.AddTest('TestNotBetween', @RunTTestCheckParserTestNotBetween);
  lSuite.AddTest('TestLikeEscape', @RunTTestCheckParserTestLikeEscape);
  lSuite.AddTest('TestNotLikeEscape', @RunTTestCheckParserTestNotLikeEscape);
  lSuite.AddTest('TestAnd', @RunTTestCheckParserTestAnd);
  lSuite.AddTest('TestOr', @RunTTestCheckParserTestOr);
  lSuite.AddTest('TestNotOr', @RunTTestCheckParserTestNotOr);
  lSuite.AddTest('TestCase', @RunTTestCheckParserTestCase);
  lSuite.AddTest('TestCaseWithSelector', @RunTTestCheckParserTestCaseWithSelector);
  lSuite.AddTest('TestAdd', @RunTTestCheckParserTestAdd);
  lSuite.AddTest('TestSubtract', @RunTTestCheckParserTestSubtract);
  lSuite.AddTest('TestMultiply', @RunTTestCheckParserTestMultiply);
  lSuite.AddTest('TestDivide', @RunTTestCheckParserTestDivide);
  lSuite:=ARegistry.AddSuite('tcparser.TTestDomainParser');
  lSuite.AddTest('TestSimpleDomain', @RunTTestDomainParserTestSimpleDomain);
  lSuite.AddTest('TestSimpleDomainAs', @RunTTestDomainParserTestSimpleDomainAs);
  lSuite.AddTest('TestNotNullDomain', @RunTTestDomainParserTestNotNullDomain);
  lSuite.AddTest('TestDefaultNotNullDomain', @RunTTestDomainParserTestDefaultNotNullDomain);
  lSuite.AddTest('TestCheckDomain', @RunTTestDomainParserTestCheckDomain);
  lSuite.AddTest('TestDefaultCheckNotNullDomain', @RunTTestDomainParserTestDefaultCheckNotNullDomain);
  lSuite.AddTest('TestAlterDomainDropDefault', @RunTTestDomainParserTestAlterDomainDropDefault);
  lSuite.AddTest('TestAlterDomainDropCheck', @RunTTestDomainParserTestAlterDomainDropCheck);
  lSuite.AddTest('TestAlterDomainDropCheckError', @RunTTestDomainParserTestAlterDomainDropCheckError);
  lSuite.AddTest('TestAlterDomainAddCheck', @RunTTestDomainParserTestAlterDomainAddCheck);
  lSuite.AddTest('TestAlterDomainAddConstraintCheck', @RunTTestDomainParserTestAlterDomainAddConstraintCheck);
  lSuite.AddTest('TestAlterDomainAddConstraintError', @RunTTestDomainParserTestAlterDomainAddConstraintError);
  lSuite.AddTest('TestAlterDomainSetDefault', @RunTTestDomainParserTestAlterDomainSetDefault);
  lSuite.AddTest('TestAlterDomainRename', @RunTTestDomainParserTestAlterDomainRename);
  lSuite.AddTest('TestAlterDomainNewType', @RunTTestDomainParserTestAlterDomainNewType);
  lSuite.AddTest('TestAlterDomainNewTypeError1', @RunTTestDomainParserTestAlterDomainNewTypeError1);
  lSuite.AddTest('TestAlterDomainNewTypeError2', @RunTTestDomainParserTestAlterDomainNewTypeError2);
  lSuite:=ARegistry.AddSuite('tcparser.TTestExceptionParser');
  lSuite.AddTest('TestException', @RunTTestExceptionParserTestException);
  lSuite.AddTest('TestAlterException', @RunTTestExceptionParserTestAlterException);
  lSuite.AddTest('TestExceptionError1', @RunTTestExceptionParserTestExceptionError1);
  lSuite.AddTest('TestExceptionError2', @RunTTestExceptionParserTestExceptionError2);
  lSuite:=ARegistry.AddSuite('tcparser.TTestIndexParser');
  lSuite.AddTest('TestAlterindexActive', @RunTTestIndexParserTestAlterindexActive);
  lSuite.AddTest('TestAlterindexInactive', @RunTTestIndexParserTestAlterindexInactive);
  lSuite.AddTest('TestCreateIndexSimple', @RunTTestIndexParserTestCreateIndexSimple);
  lSuite.AddTest('TestIndexIndexDouble', @RunTTestIndexParserTestIndexIndexDouble);
  lSuite.AddTest('TestCreateIndexAscending', @RunTTestIndexParserTestCreateIndexAscending);
  lSuite.AddTest('TestCreateIndexDescending', @RunTTestIndexParserTestCreateIndexDescending);
  lSuite.AddTest('TestCreateIndexUnique', @RunTTestIndexParserTestCreateIndexUnique);
  lSuite.AddTest('TestCreateIndexUniqueAscending', @RunTTestIndexParserTestCreateIndexUniqueAscending);
  lSuite.AddTest('TestCreateIndexUniqueDescending', @RunTTestIndexParserTestCreateIndexUniqueDescending);
  lSuite.AddTest('TestIndexError1', @RunTTestIndexParserTestIndexError1);
  lSuite.AddTest('TestIndexError2', @RunTTestIndexParserTestIndexError2);
  lSuite.AddTest('TestIndexError3', @RunTTestIndexParserTestIndexError3);
  lSuite.AddTest('TestIndexError4', @RunTTestIndexParserTestIndexError4);
  lSuite.AddTest('TestIndexError5', @RunTTestIndexParserTestIndexError5);
  lSuite.AddTest('TestIndexError6', @RunTTestIndexParserTestIndexError6);
  lSuite:=ARegistry.AddSuite('tcparser.TTestTableParser');
  lSuite.AddTest('TestCreateOneSimpleField', @RunTTestTableParserTestCreateOneSimpleField);
  lSuite.AddTest('TestCreateTwoSimpleFields', @RunTTestTableParserTestCreateTwoSimpleFields);
  lSuite.AddTest('TestCreateOnePrimaryField', @RunTTestTableParserTestCreateOnePrimaryField);
  lSuite.AddTest('TestCreateOneNamedPrimaryField', @RunTTestTableParserTestCreateOneNamedPrimaryField);
  lSuite.AddTest('TestCreateOneUniqueField', @RunTTestTableParserTestCreateOneUniqueField);
  lSuite.AddTest('TestCreateOneNamedUniqueField', @RunTTestTableParserTestCreateOneNamedUniqueField);
  lSuite.AddTest('TestCreateNotNullPrimaryField', @RunTTestTableParserTestCreateNotNullPrimaryField);
  lSuite.AddTest('TestCreateNotNullDefaultPrimaryField', @RunTTestTableParserTestCreateNotNullDefaultPrimaryField);
  lSuite.AddTest('TestCreateComputedByField', @RunTTestTableParserTestCreateComputedByField);
  lSuite.AddTest('TestCreateCheckField', @RunTTestTableParserTestCreateCheckField);
  lSuite.AddTest('TestCreateNamedCheckField', @RunTTestTableParserTestCreateNamedCheckField);
  lSuite.AddTest('TestCreateReferencesField', @RunTTestTableParserTestCreateReferencesField);
  lSuite.AddTest('TestCreateReferencesOnUpdateCascadeField', @RunTTestTableParserTestCreateReferencesOnUpdateCascadeField);
  lSuite.AddTest('TestCreateReferencesOnUpdateNoActionField', @RunTTestTableParserTestCreateReferencesOnUpdateNoActionField);
  lSuite.AddTest('TestCreateReferencesOnUpdateSetDefaultField', @RunTTestTableParserTestCreateReferencesOnUpdateSetDefaultField);
  lSuite.AddTest('TestCreateReferencesOnUpdateSetNullField', @RunTTestTableParserTestCreateReferencesOnUpdateSetNullField);
  lSuite.AddTest('TestCreateReferencesOnDeleteCascadeField', @RunTTestTableParserTestCreateReferencesOnDeleteCascadeField);
  lSuite.AddTest('TestCreateReferencesOnDeleteNoActionField', @RunTTestTableParserTestCreateReferencesOnDeleteNoActionField);
  lSuite.AddTest('TestCreateReferencesOnDeleteSetDefaultField', @RunTTestTableParserTestCreateReferencesOnDeleteSetDefaultField);
  lSuite.AddTest('TestCreateReferencesOnDeleteSetNullField', @RunTTestTableParserTestCreateReferencesOnDeleteSetNullField);
  lSuite.AddTest('TestCreateReferencesOnUpdateAndDeleteSetNullField', @RunTTestTableParserTestCreateReferencesOnUpdateAndDeleteSetNullField);
  lSuite.AddTest('TestCreateNamedReferencesField', @RunTTestTableParserTestCreateNamedReferencesField);
  lSuite.AddTest('TestCreatePrimaryKeyConstraint', @RunTTestTableParserTestCreatePrimaryKeyConstraint);
  lSuite.AddTest('TestCreateNamedPrimaryKeyConstraint', @RunTTestTableParserTestCreateNamedPrimaryKeyConstraint);
  lSuite.AddTest('TestCreateForeignKeyConstraint', @RunTTestTableParserTestCreateForeignKeyConstraint);
  lSuite.AddTest('TestCreateNamedForeignKeyConstraint', @RunTTestTableParserTestCreateNamedForeignKeyConstraint);
  lSuite.AddTest('TestCreateUniqueConstraint', @RunTTestTableParserTestCreateUniqueConstraint);
  lSuite.AddTest('TestCreateNamedUniqueConstraint', @RunTTestTableParserTestCreateNamedUniqueConstraint);
  lSuite.AddTest('TestCreateCheckConstraint', @RunTTestTableParserTestCreateCheckConstraint);
  lSuite.AddTest('TestCreateNamedCheckConstraint', @RunTTestTableParserTestCreateNamedCheckConstraint);
  lSuite.AddTest('TestAlterDropField', @RunTTestTableParserTestAlterDropField);
  lSuite.AddTest('TestAlterDropFields', @RunTTestTableParserTestAlterDropFields);
  lSuite.AddTest('TestAlterDropConstraint', @RunTTestTableParserTestAlterDropConstraint);
  lSuite.AddTest('TestAlterDropConstraints', @RunTTestTableParserTestAlterDropConstraints);
  lSuite.AddTest('TestAlterRenameField', @RunTTestTableParserTestAlterRenameField);
  lSuite.AddTest('TestAlterRenameColumnField', @RunTTestTableParserTestAlterRenameColumnField);
  lSuite.AddTest('TestAlterFieldType', @RunTTestTableParserTestAlterFieldType);
  lSuite.AddTest('TestAlterFieldPosition', @RunTTestTableParserTestAlterFieldPosition);
  lSuite.AddTest('TestAlterAddField', @RunTTestTableParserTestAlterAddField);
  lSuite.AddTest('TestAlterAddFields', @RunTTestTableParserTestAlterAddFields);
  lSuite.AddTest('TestAlterAddPrimarykey', @RunTTestTableParserTestAlterAddPrimarykey);
  lSuite.AddTest('TestAlterAddNamedPrimarykey', @RunTTestTableParserTestAlterAddNamedPrimarykey);
  lSuite.AddTest('TestAlterAddCheckConstraint', @RunTTestTableParserTestAlterAddCheckConstraint);
  lSuite.AddTest('TestAlterAddNamedCheckConstraint', @RunTTestTableParserTestAlterAddNamedCheckConstraint);
  lSuite.AddTest('TestAlterAddForeignkey', @RunTTestTableParserTestAlterAddForeignkey);
  lSuite.AddTest('TestAlterAddNamedForeignkey', @RunTTestTableParserTestAlterAddNamedForeignkey);
  lSuite:=ARegistry.AddSuite('tcparser.TTestDeleteParser');
  lSuite.AddTest('TestSimpleDelete', @RunTTestDeleteParserTestSimpleDelete);
  lSuite.AddTest('TestSimpleDeleteAlias', @RunTTestDeleteParserTestSimpleDeleteAlias);
  lSuite.AddTest('TestDeleteWhereNull', @RunTTestDeleteParserTestDeleteWhereNull);
  lSuite:=ARegistry.AddSuite('tcparser.TTestUpdateParser');
  lSuite.AddTest('TestUpdateOneField', @RunTTestUpdateParserTestUpdateOneField);
  lSuite.AddTest('TestUpdateOneFieldFull', @RunTTestUpdateParserTestUpdateOneFieldFull);
  lSuite.AddTest('TestUpdateTwoFields', @RunTTestUpdateParserTestUpdateTwoFields);
  lSuite.AddTest('TestUpdateOneFieldWhereIsNull', @RunTTestUpdateParserTestUpdateOneFieldWhereIsNull);
  lSuite:=ARegistry.AddSuite('tcparser.TTestInsertParser');
  lSuite.AddTest('TestInsertOneField', @RunTTestInsertParserTestInsertOneField);
  lSuite.AddTest('TestInsertTwoFields', @RunTTestInsertParserTestInsertTwoFields);
  lSuite.AddTest('TestInsertOneValue', @RunTTestInsertParserTestInsertOneValue);
  lSuite.AddTest('TestInsertTwoValues', @RunTTestInsertParserTestInsertTwoValues);
  lSuite:=ARegistry.AddSuite('tcparser.TTestSelectParser');
  lSuite.AddTest('TestSelectOneFieldOneTable', @RunTTestSelectParserTestSelectOneFieldOneTable);
  lSuite.AddTest('TestSelectOneFieldOneTableTransaction', @RunTTestSelectParserTestSelectOneFieldOneTableTransaction);
  lSuite.AddTest('TestSelectOneArrayFieldOneTable', @RunTTestSelectParserTestSelectOneArrayFieldOneTable);
  lSuite.AddTest('TestSelectTwoFieldsOneTable', @RunTTestSelectParserTestSelectTwoFieldsOneTable);
  lSuite.AddTest('TestSelectOneFieldAliasOneTable', @RunTTestSelectParserTestSelectOneFieldAliasOneTable);
  lSuite.AddTest('TestSelectTwoFieldAliasesOneTable', @RunTTestSelectParserTestSelectTwoFieldAliasesOneTable);
  lSuite.AddTest('TestSelectOneTableFieldOneTable', @RunTTestSelectParserTestSelectOneTableFieldOneTable);
  lSuite.AddTest('TestSelectOneDistinctFieldOneTable', @RunTTestSelectParserTestSelectOneDistinctFieldOneTable);
  lSuite.AddTest('TestSelectOneAllFieldOneTable', @RunTTestSelectParserTestSelectOneAllFieldOneTable);
  lSuite.AddTest('TestSelectAsteriskOneTable', @RunTTestSelectParserTestSelectAsteriskOneTable);
  lSuite.AddTest('TestSelectDistinctAsteriskOneTable', @RunTTestSelectParserTestSelectDistinctAsteriskOneTable);
  lSuite.AddTest('TestSelectAsteriskWithPath', @RunTTestSelectParserTestSelectAsteriskWithPath);
  lSuite.AddTest('TestSelectOneFieldOneTableAlias', @RunTTestSelectParserTestSelectOneFieldOneTableAlias);
  lSuite.AddTest('TestSelectOneFieldOneTableAsAlias', @RunTTestSelectParserTestSelectOneFieldOneTableAsAlias);
  lSuite.AddTest('TestSelectTwoFieldsTwoTables', @RunTTestSelectParserTestSelectTwoFieldsTwoTables);
  lSuite.AddTest('TestSelectTwoFieldsTwoTablesJoin', @RunTTestSelectParserTestSelectTwoFieldsTwoTablesJoin);
  lSuite.AddTest('TestSelectTwoFieldsTwoInnerTablesJoin', @RunTTestSelectParserTestSelectTwoFieldsTwoInnerTablesJoin);
  lSuite.AddTest('TestSelectTwoFieldsTwoLeftTablesJoin', @RunTTestSelectParserTestSelectTwoFieldsTwoLeftTablesJoin);
  lSuite.AddTest('TestSelectTwoFieldsTwoFullOuterTablesJoin', @RunTTestSelectParserTestSelectTwoFieldsTwoFullOuterTablesJoin);
  lSuite.AddTest('TestSelectTwoFieldsTwoFullTablesJoin', @RunTTestSelectParserTestSelectTwoFieldsTwoFullTablesJoin);
  lSuite.AddTest('TestSelectTwoFieldsTwoRightTablesJoin', @RunTTestSelectParserTestSelectTwoFieldsTwoRightTablesJoin);
  lSuite.AddTest('TestSelectTwoFieldsThreeTablesJoin', @RunTTestSelectParserTestSelectTwoFieldsThreeTablesJoin);
  lSuite.AddTest('TestSelectTwoFieldsBracketThreeTablesJoin', @RunTTestSelectParserTestSelectTwoFieldsBracketThreeTablesJoin);
  lSuite.AddTest('TestSelectTwoFieldsThreeBracketTablesJoin', @RunTTestSelectParserTestSelectTwoFieldsThreeBracketTablesJoin);
  lSuite.AddTest('TestSelectTableWithSchema', @RunTTestSelectParserTestSelectTableWithSchema);
  lSuite.AddTest('TestSelectFieldWithSchema', @RunTTestSelectParserTestSelectFieldWithSchema);
  lSuite.AddTest('TestSelectFieldAsStringLiteral', @RunTTestSelectParserTestSelectFieldAsStringLiteral);
  lSuite.AddTest('TestSelectFirst', @RunTTestSelectParserTestSelectFirst);
  lSuite.AddTest('TestSelectFirstSkip', @RunTTestSelectParserTestSelectFirstSkip);
  lSuite.AddTest('TestSelectTop', @RunTTestSelectParserTestSelectTop);
  lSuite.AddTest('TestSelectLimit', @RunTTestSelectParserTestSelectLimit);
  lSuite.AddTest('TestSelectLimitAll', @RunTTestSelectParserTestSelectLimitAll);
  lSuite.AddTest('TestSelectLimitAllOffset', @RunTTestSelectParserTestSelectLimitAllOffset);
  lSuite.AddTest('TestSelectLimitOffset1', @RunTTestSelectParserTestSelectLimitOffset1);
  lSuite.AddTest('TestSelectLimitOffset2', @RunTTestSelectParserTestSelectLimitOffset2);
  lSuite.AddTest('TestSelectOffset', @RunTTestSelectParserTestSelectOffset);
  lSuite.AddTest('TestAggregateCount', @RunTTestSelectParserTestAggregateCount);
  lSuite.AddTest('TestAggregateCountAsterisk', @RunTTestSelectParserTestAggregateCountAsterisk);
  lSuite.AddTest('TestAggregateCountAll', @RunTTestSelectParserTestAggregateCountAll);
  lSuite.AddTest('TestAggregateCountDistinct', @RunTTestSelectParserTestAggregateCountDistinct);
  lSuite.AddTest('TestAggregateMax', @RunTTestSelectParserTestAggregateMax);
  lSuite.AddTest('TestAggregateMaxAll', @RunTTestSelectParserTestAggregateMaxAll);
  lSuite.AddTest('TestAggregateMaxAsterisk', @RunTTestSelectParserTestAggregateMaxAsterisk);
  lSuite.AddTest('TestAggregateMaxDistinct', @RunTTestSelectParserTestAggregateMaxDistinct);
  lSuite.AddTest('TestAggregateMin', @RunTTestSelectParserTestAggregateMin);
  lSuite.AddTest('TestAggregateMinAll', @RunTTestSelectParserTestAggregateMinAll);
  lSuite.AddTest('TestAggregateMinAsterisk', @RunTTestSelectParserTestAggregateMinAsterisk);
  lSuite.AddTest('TestAggregateMinDistinct', @RunTTestSelectParserTestAggregateMinDistinct);
  lSuite.AddTest('TestAggregateSum', @RunTTestSelectParserTestAggregateSum);
  lSuite.AddTest('TestAggregateSumAll', @RunTTestSelectParserTestAggregateSumAll);
  lSuite.AddTest('TestAggregateSumAsterisk', @RunTTestSelectParserTestAggregateSumAsterisk);
  lSuite.AddTest('TestAggregateSumDistinct', @RunTTestSelectParserTestAggregateSumDistinct);
  lSuite.AddTest('TestAggregateAvg', @RunTTestSelectParserTestAggregateAvg);
  lSuite.AddTest('TestAggregateAvgAll', @RunTTestSelectParserTestAggregateAvgAll);
  lSuite.AddTest('TestAggregateAvgAsterisk', @RunTTestSelectParserTestAggregateAvgAsterisk);
  lSuite.AddTest('TestAggregateAvgDistinct', @RunTTestSelectParserTestAggregateAvgDistinct);
  lSuite.AddTest('TestUpperConst', @RunTTestSelectParserTestUpperConst);
  lSuite.AddTest('TestUpperError', @RunTTestSelectParserTestUpperError);
  lSuite.AddTest('TestLeft', @RunTTestSelectParserTestLeft);
  lSuite.AddTest('TestFunctionWithPath', @RunTTestSelectParserTestFunctionWithPath);
  lSuite.AddTest('TestGenID', @RunTTestSelectParserTestGenID);
  lSuite.AddTest('TestGenIDError1', @RunTTestSelectParserTestGenIDError1);
  lSuite.AddTest('TestGenIDError2', @RunTTestSelectParserTestGenIDError2);
  lSuite.AddTest('TestCastSimple', @RunTTestSelectParserTestCastSimple);
  lSuite.AddTest('TestExtractSimple', @RunTTestSelectParserTestExtractSimple);
  lSuite.AddTest('TestOrderByOneField', @RunTTestSelectParserTestOrderByOneField);
  lSuite.AddTest('TestOrderByTwoFields', @RunTTestSelectParserTestOrderByTwoFields);
  lSuite.AddTest('TestOrderByThreeFields', @RunTTestSelectParserTestOrderByThreeFields);
  lSuite.AddTest('TestOrderByOneDescField', @RunTTestSelectParserTestOrderByOneDescField);
  lSuite.AddTest('TestOrderByTwoDescFields', @RunTTestSelectParserTestOrderByTwoDescFields);
  lSuite.AddTest('TestOrderByThreeDescFields', @RunTTestSelectParserTestOrderByThreeDescFields);
  lSuite.AddTest('TestOrderByOneTableField', @RunTTestSelectParserTestOrderByOneTableField);
  lSuite.AddTest('TestOrderByOneColumn', @RunTTestSelectParserTestOrderByOneColumn);
  lSuite.AddTest('TestOrderByTwoColumns', @RunTTestSelectParserTestOrderByTwoColumns);
  lSuite.AddTest('TestOrderByTwoColumnsDesc', @RunTTestSelectParserTestOrderByTwoColumnsDesc);
  lSuite.AddTest('TestOrderByCollate', @RunTTestSelectParserTestOrderByCollate);
  lSuite.AddTest('TestOrderByCollateDesc', @RunTTestSelectParserTestOrderByCollateDesc);
  lSuite.AddTest('TestOrderByCollateDescTwoFields', @RunTTestSelectParserTestOrderByCollateDescTwoFields);
  lSuite.AddTest('TestOrderByUpper', @RunTTestSelectParserTestOrderByUpper);
  lSuite.AddTest('TestGroupByOne', @RunTTestSelectParserTestGroupByOne);
  lSuite.AddTest('TestGroupByTwo', @RunTTestSelectParserTestGroupByTwo);
  lSuite.AddTest('TestHavingOne', @RunTTestSelectParserTestHavingOne);
  lSuite.AddTest('TestUnionSimple', @RunTTestSelectParserTestUnionSimple);
  lSuite.AddTest('TestUnionSimpleAll', @RunTTestSelectParserTestUnionSimpleAll);
  lSuite.AddTest('TestUnionSimpleOrderBy', @RunTTestSelectParserTestUnionSimpleOrderBy);
  lSuite.AddTest('TestUnionDouble', @RunTTestSelectParserTestUnionDouble);
  lSuite.AddTest('TestUnionError1', @RunTTestSelectParserTestUnionError1);
  lSuite.AddTest('TestUnionError2', @RunTTestSelectParserTestUnionError2);
  lSuite.AddTest('TestPlanOrderNatural', @RunTTestSelectParserTestPlanOrderNatural);
  lSuite.AddTest('TestPlanOrderOrder', @RunTTestSelectParserTestPlanOrderOrder);
  lSuite.AddTest('TestPlanOrderIndex1', @RunTTestSelectParserTestPlanOrderIndex1);
  lSuite.AddTest('TestPlanOrderIndex2', @RunTTestSelectParserTestPlanOrderIndex2);
  lSuite.AddTest('TestPlanJoinNatural', @RunTTestSelectParserTestPlanJoinNatural);
  lSuite.AddTest('TestPlanDefaultNatural', @RunTTestSelectParserTestPlanDefaultNatural);
  lSuite.AddTest('TestPlanMergeNatural', @RunTTestSelectParserTestPlanMergeNatural);
  lSuite.AddTest('TestPlanMergeNested', @RunTTestSelectParserTestPlanMergeNested);
  lSuite.AddTest('TestSubSelect', @RunTTestSelectParserTestSubSelect);
  lSuite.AddTest('TestWhereExists', @RunTTestSelectParserTestWhereExists);
  lSuite.AddTest('TestWhereSingular', @RunTTestSelectParserTestWhereSingular);
  lSuite.AddTest('TestWhereAll', @RunTTestSelectParserTestWhereAll);
  lSuite.AddTest('TestWhereAny', @RunTTestSelectParserTestWhereAny);
  lSuite.AddTest('TestWhereSome', @RunTTestSelectParserTestWhereSome);
  lSuite.AddTest('TestWhereInRange', @RunTTestSelectParserTestWhereInRange);
  lSuite.AddTest('TestWhereDotFloat', @RunTTestSelectParserTestWhereDotFloat);
  lSuite.AddTest('TestParam', @RunTTestSelectParserTestParam);
  lSuite.AddTest('TestParam_Underscore', @RunTTestSelectParserTestParam_Underscore);
  lSuite.AddTest('TestParamExpr', @RunTTestSelectParserTestParamExpr);
  lSuite.AddTest('TestNoTable', @RunTTestSelectParserTestNoTable);
  lSuite.AddTest('TestSourcePosition', @RunTTestSelectParserTestSourcePosition);
  lSuite.AddTest('TestForUpdate', @RunTTestSelectParserTestForUpdate);
  lSuite.AddTest('TestForUpdateNowait', @RunTTestSelectParserTestForUpdateNowait);
  lSuite.AddTest('TestForUpdateOf', @RunTTestSelectParserTestForUpdateOf);
  lSuite.AddTest('TestWithLock', @RunTTestSelectParserTestWithLock);
  lSuite:=ARegistry.AddSuite('tcparser.TTestRollBackParser');
  lSuite.AddTest('TestRollback', @RunTTestRollBackParserTestRollback);
  lSuite.AddTest('TestRollbackWork', @RunTTestRollBackParserTestRollbackWork);
  lSuite.AddTest('TestRollbackRelease', @RunTTestRollBackParserTestRollbackRelease);
  lSuite.AddTest('TestRollbackWorkRelease', @RunTTestRollBackParserTestRollbackWorkRelease);
  lSuite.AddTest('TestRollbackTransaction', @RunTTestRollBackParserTestRollbackTransaction);
  lSuite.AddTest('TestRollbackTransactionWork', @RunTTestRollBackParserTestRollbackTransactionWork);
  lSuite.AddTest('TestRollbackTransactionRelease', @RunTTestRollBackParserTestRollbackTransactionRelease);
  lSuite.AddTest('TestRollbackTransactionWorkRelease', @RunTTestRollBackParserTestRollbackTransactionWorkRelease);
  lSuite:=ARegistry.AddSuite('tcparser.TTestCommitParser');
  lSuite.AddTest('TestCommit', @RunTTestCommitParserTestCommit);
  lSuite.AddTest('TestCommitWork', @RunTTestCommitParserTestCommitWork);
  lSuite.AddTest('TestCommitRelease', @RunTTestCommitParserTestCommitRelease);
  lSuite.AddTest('TestCommitWorkRelease', @RunTTestCommitParserTestCommitWorkRelease);
  lSuite.AddTest('TestCommitTransaction', @RunTTestCommitParserTestCommitTransaction);
  lSuite.AddTest('TestCommitTransactionWork', @RunTTestCommitParserTestCommitTransactionWork);
  lSuite.AddTest('TestCommitTransactionRelease', @RunTTestCommitParserTestCommitTransactionRelease);
  lSuite.AddTest('TestCommitTransactionWorkRelease', @RunTTestCommitParserTestCommitTransactionWorkRelease);
  lSuite.AddTest('TestCommitRetain', @RunTTestCommitParserTestCommitRetain);
  lSuite.AddTest('TestCommitWorkRetain', @RunTTestCommitParserTestCommitWorkRetain);
  lSuite.AddTest('TestCommitReleaseRetain', @RunTTestCommitParserTestCommitReleaseRetain);
  lSuite.AddTest('TestCommitWorkReleaseRetain', @RunTTestCommitParserTestCommitWorkReleaseRetain);
  lSuite.AddTest('TestCommitTransactionRetain', @RunTTestCommitParserTestCommitTransactionRetain);
  lSuite.AddTest('TestCommitTransactionWorkRetain', @RunTTestCommitParserTestCommitTransactionWorkRetain);
  lSuite.AddTest('TestCommitTransactionReleaseRetain', @RunTTestCommitParserTestCommitTransactionReleaseRetain);
  lSuite.AddTest('TestCommitTransactionWorkReleaseRetain', @RunTTestCommitParserTestCommitTransactionWorkReleaseRetain);
  lSuite.AddTest('TestCommitRetainSnapShot', @RunTTestCommitParserTestCommitRetainSnapShot);
  lSuite:=ARegistry.AddSuite('tcparser.TTestExecuteProcedureParser');
  lSuite.AddTest('TestExecuteSimple', @RunTTestExecuteProcedureParserTestExecuteSimple);
  lSuite.AddTest('TestExecuteSimpleTransaction', @RunTTestExecuteProcedureParserTestExecuteSimpleTransaction);
  lSuite.AddTest('TestExecuteSimpleReturningValues', @RunTTestExecuteProcedureParserTestExecuteSimpleReturningValues);
  lSuite.AddTest('TestExecuteSimpleReturning2Values', @RunTTestExecuteProcedureParserTestExecuteSimpleReturning2Values);
  lSuite.AddTest('TestExecuteOneArg', @RunTTestExecuteProcedureParserTestExecuteOneArg);
  lSuite.AddTest('TestExecuteOneArgNB', @RunTTestExecuteProcedureParserTestExecuteOneArgNB);
  lSuite.AddTest('TestExecuteTwoArgs', @RunTTestExecuteProcedureParserTestExecuteTwoArgs);
  lSuite.AddTest('TestExecuteTwoArgsNB', @RunTTestExecuteProcedureParserTestExecuteTwoArgsNB);
  lSuite.AddTest('TestExecuteOneArgSelect', @RunTTestExecuteProcedureParserTestExecuteOneArgSelect);
  lSuite.AddTest('TestExecuteOneArgSelectNB', @RunTTestExecuteProcedureParserTestExecuteOneArgSelectNB);
  lSuite.AddTest('TestExecuteTwoArgsSelect', @RunTTestExecuteProcedureParserTestExecuteTwoArgsSelect);
  lSuite.AddTest('TestExecuteTwoArgsSelectNB', @RunTTestExecuteProcedureParserTestExecuteTwoArgsSelectNB);
  lSuite.AddTest('TestExecuteOneArgSelectErr', @RunTTestExecuteProcedureParserTestExecuteOneArgSelectErr);
  lSuite.AddTest('TestExecuteOneArgSelectErr2', @RunTTestExecuteProcedureParserTestExecuteOneArgSelectErr2);
  lSuite.AddTest('TestExecuteOneArgSelectErr3', @RunTTestExecuteProcedureParserTestExecuteOneArgSelectErr3);
  lSuite.AddTest('TestExecuteOneArgSelectErr4', @RunTTestExecuteProcedureParserTestExecuteOneArgSelectErr4);
  lSuite:=ARegistry.AddSuite('tcparser.TTestConnectParser');
  lSuite.AddTest('TestConnectSimple', @RunTTestConnectParserTestConnectSimple);
  lSuite.AddTest('TestConnectUser', @RunTTestConnectParserTestConnectUser);
  lSuite.AddTest('TestConnectPassword', @RunTTestConnectParserTestConnectPassword);
  lSuite.AddTest('TestConnectUserPassword', @RunTTestConnectParserTestConnectUserPassword);
  lSuite.AddTest('TestConnectUserPasswordRole', @RunTTestConnectParserTestConnectUserPasswordRole);
  lSuite.AddTest('TestConnectUserPasswordRoleCache', @RunTTestConnectParserTestConnectUserPasswordRoleCache);
  lSuite.AddTest('TestConnectSimpleCache', @RunTTestConnectParserTestConnectSimpleCache);
  lSuite:=ARegistry.AddSuite('tcparser.TTestCreateDatabaseParser');
  lSuite.AddTest('TestSimple', @RunTTestCreateDatabaseParserTestSimple);
  lSuite.AddTest('TestSimpleSchema', @RunTTestCreateDatabaseParserTestSimpleSchema);
  lSuite.AddTest('TestSimpleUSer', @RunTTestCreateDatabaseParserTestSimpleUSer);
  lSuite.AddTest('TestSimpleUSerPassword', @RunTTestCreateDatabaseParserTestSimpleUSerPassword);
  lSuite.AddTest('TestSimplePassword', @RunTTestCreateDatabaseParserTestSimplePassword);
  lSuite.AddTest('TestPageSize', @RunTTestCreateDatabaseParserTestPageSize);
  lSuite.AddTest('TestPageSize2', @RunTTestCreateDatabaseParserTestPageSize2);
  lSuite.AddTest('TestPageSizeLength', @RunTTestCreateDatabaseParserTestPageSizeLength);
  lSuite.AddTest('TestPageSizeLength2', @RunTTestCreateDatabaseParserTestPageSizeLength2);
  lSuite.AddTest('TestPageSizeLength3', @RunTTestCreateDatabaseParserTestPageSizeLength3);
  lSuite.AddTest('TestPageSizeLength4', @RunTTestCreateDatabaseParserTestPageSizeLength4);
  lSuite.AddTest('TestCharset', @RunTTestCreateDatabaseParserTestCharset);
  lSuite.AddTest('TestSecondaryFile1', @RunTTestCreateDatabaseParserTestSecondaryFile1);
  lSuite.AddTest('TestSecondaryFile2', @RunTTestCreateDatabaseParserTestSecondaryFile2);
  lSuite.AddTest('TestSecondaryFile3', @RunTTestCreateDatabaseParserTestSecondaryFile3);
  lSuite.AddTest('TestSecondaryFile4', @RunTTestCreateDatabaseParserTestSecondaryFile4);
  lSuite.AddTest('TestSecondaryFile5', @RunTTestCreateDatabaseParserTestSecondaryFile5);
  lSuite.AddTest('TestSecondaryFile6', @RunTTestCreateDatabaseParserTestSecondaryFile6);
  lSuite.AddTest('TestSecondaryFile7', @RunTTestCreateDatabaseParserTestSecondaryFile7);
  lSuite.AddTest('TestSecondaryFile8', @RunTTestCreateDatabaseParserTestSecondaryFile8);
  lSuite.AddTest('TestSecondaryFile9', @RunTTestCreateDatabaseParserTestSecondaryFile9);
  lSuite.AddTest('TestSecondaryFile10', @RunTTestCreateDatabaseParserTestSecondaryFile10);
  lSuite.AddTest('TestSecondaryFileS', @RunTTestCreateDatabaseParserTestSecondaryFileS);
  lSuite.AddTest('TestSecondaryFileError1', @RunTTestCreateDatabaseParserTestSecondaryFileError1);
  lSuite.AddTest('TestSecondaryFileError2', @RunTTestCreateDatabaseParserTestSecondaryFileError2);
  lSuite.AddTest('TestSecondaryFileError3', @RunTTestCreateDatabaseParserTestSecondaryFileError3);
  lSuite:=ARegistry.AddSuite('tcparser.TTestAlterDatabaseParser');
  lSuite.AddTest('TestSimple', @RunTTestAlterDatabaseParserTestSimple);
  lSuite.AddTest('TestLength', @RunTTestAlterDatabaseParserTestLength);
  lSuite.AddTest('TestStarting', @RunTTestAlterDatabaseParserTestStarting);
  lSuite.AddTest('TestStartingLength', @RunTTestAlterDatabaseParserTestStartingLength);
  lSuite.AddTest('TestFiles', @RunTTestAlterDatabaseParserTestFiles);
  lSuite.AddTest('TestFiles2', @RunTTestAlterDatabaseParserTestFiles2);
  lSuite.AddTest('TestError', @RunTTestAlterDatabaseParserTestError);
  lSuite.AddTest('TestFilesError', @RunTTestAlterDatabaseParserTestFilesError);
  lSuite:=ARegistry.AddSuite('tcparser.TTestCreateViewParser');
  lSuite.AddTest('TestSimple', @RunTTestCreateViewParserTestSimple);
  lSuite.AddTest('TestFieldList', @RunTTestCreateViewParserTestFieldList);
  lSuite.AddTest('TestFieldList2', @RunTTestCreateViewParserTestFieldList2);
  lSuite.AddTest('TestSimpleWithCheckoption', @RunTTestCreateViewParserTestSimpleWithCheckoption);
  lSuite:=ARegistry.AddSuite('tcparser.TTestCreateShadowParser');
  lSuite.AddTest('TestSimple', @RunTTestCreateShadowParserTestSimple);
  lSuite.AddTest('TestLength', @RunTTestCreateShadowParserTestLength);
  lSuite.AddTest('TestLength2', @RunTTestCreateShadowParserTestLength2);
  lSuite.AddTest('TestLength3', @RunTTestCreateShadowParserTestLength3);
  lSuite.AddTest('TestLength4', @RunTTestCreateShadowParserTestLength4);
  lSuite.AddTest('TestSecondaryFile1', @RunTTestCreateShadowParserTestSecondaryFile1);
  lSuite.AddTest('TestSecondaryFile2', @RunTTestCreateShadowParserTestSecondaryFile2);
  lSuite.AddTest('TestSecondaryFile3', @RunTTestCreateShadowParserTestSecondaryFile3);
  lSuite.AddTest('TestSecondaryFile4', @RunTTestCreateShadowParserTestSecondaryFile4);
  lSuite.AddTest('TestSecondaryFile5', @RunTTestCreateShadowParserTestSecondaryFile5);
  lSuite.AddTest('TestSecondaryFile6', @RunTTestCreateShadowParserTestSecondaryFile6);
  lSuite.AddTest('TestSecondaryFile7', @RunTTestCreateShadowParserTestSecondaryFile7);
  lSuite.AddTest('TestSecondaryFile8', @RunTTestCreateShadowParserTestSecondaryFile8);
  lSuite.AddTest('TestSecondaryFileS', @RunTTestCreateShadowParserTestSecondaryFileS);
  lSuite:=ARegistry.AddSuite('tcparser.TTestProcedureStatement');
  lSuite.AddTest('TestException', @RunTTestProcedureStatementTestException);
  lSuite.AddTest('TestExceptionError', @RunTTestProcedureStatementTestExceptionError);
  lSuite.AddTest('TestExit', @RunTTestProcedureStatementTestExit);
  lSuite.AddTest('TestSuspend', @RunTTestProcedureStatementTestSuspend);
  lSuite.AddTest('TestEmptyBlock', @RunTTestProcedureStatementTestEmptyBlock);
  lSuite.AddTest('TestExitBlock', @RunTTestProcedureStatementTestExitBlock);
  lSuite.AddTest('TestExitBlockError', @RunTTestProcedureStatementTestExitBlockError);
  lSuite.AddTest('TestPostEvent', @RunTTestProcedureStatementTestPostEvent);
  lSuite.AddTest('TestPostEventColName', @RunTTestProcedureStatementTestPostEventColName);
  lSuite.AddTest('TestPostError', @RunTTestProcedureStatementTestPostError);
  lSuite.AddTest('TestAssignSimple', @RunTTestProcedureStatementTestAssignSimple);
  lSuite.AddTest('TestAssignSimpleNew', @RunTTestProcedureStatementTestAssignSimpleNew);
  lSuite.AddTest('TestAssignSelect', @RunTTestProcedureStatementTestAssignSelect);
  lSuite.AddTest('TestBlockAssignSimple', @RunTTestProcedureStatementTestBlockAssignSimple);
  lSuite.AddTest('TestIf', @RunTTestProcedureStatementTestIf);
  lSuite.AddTest('TestIfBlock', @RunTTestProcedureStatementTestIfBlock);
  lSuite.AddTest('TestIfElse', @RunTTestProcedureStatementTestIfElse);
  lSuite.AddTest('TestIfBlockElse', @RunTTestProcedureStatementTestIfBlockElse);
  lSuite.AddTest('TestIfElseError', @RunTTestProcedureStatementTestIfElseError);
  lSuite.AddTest('TestIfBlockElseBlock', @RunTTestProcedureStatementTestIfBlockElseBlock);
  lSuite.AddTest('TestIfErrorBracketLeft', @RunTTestProcedureStatementTestIfErrorBracketLeft);
  lSuite.AddTest('TestIfErrorBracketRight', @RunTTestProcedureStatementTestIfErrorBracketRight);
  lSuite.AddTest('TestIfErrorNoThen', @RunTTestProcedureStatementTestIfErrorNoThen);
  lSuite.AddTest('TestIfErrorSemicolonElse', @RunTTestProcedureStatementTestIfErrorSemicolonElse);
  lSuite.AddTest('TestWhile', @RunTTestProcedureStatementTestWhile);
  lSuite.AddTest('TestWhileBlock', @RunTTestProcedureStatementTestWhileBlock);
  lSuite.AddTest('TestWhileErrorBracketLeft', @RunTTestProcedureStatementTestWhileErrorBracketLeft);
  lSuite.AddTest('TestWhileErrorBracketRight', @RunTTestProcedureStatementTestWhileErrorBracketRight);
  lSuite.AddTest('TestWhileErrorNoDo', @RunTTestProcedureStatementTestWhileErrorNoDo);
  lSuite.AddTest('TestWhenAny', @RunTTestProcedureStatementTestWhenAny);
  lSuite.AddTest('TestWhenSQLCode', @RunTTestProcedureStatementTestWhenSQLCode);
  lSuite.AddTest('TestWhenGDSCode', @RunTTestProcedureStatementTestWhenGDSCode);
  lSuite.AddTest('TestWhenException', @RunTTestProcedureStatementTestWhenException);
  lSuite.AddTest('TestWhenExceptionGDS', @RunTTestProcedureStatementTestWhenExceptionGDS);
  lSuite.AddTest('TestWhenAnyBlock', @RunTTestProcedureStatementTestWhenAnyBlock);
  lSuite.AddTest('TestWhenErrorAny', @RunTTestProcedureStatementTestWhenErrorAny);
  lSuite.AddTest('TestWhenErrorNoDo', @RunTTestProcedureStatementTestWhenErrorNoDo);
  lSuite.AddTest('TestWhenErrorExceptionInt', @RunTTestProcedureStatementTestWhenErrorExceptionInt);
  lSuite.AddTest('TestWhenErrorExceptionString', @RunTTestProcedureStatementTestWhenErrorExceptionString);
  lSuite.AddTest('TestWhenErrorSqlCode', @RunTTestProcedureStatementTestWhenErrorSqlCode);
  lSuite.AddTest('TestWhenErrorGDSCode', @RunTTestProcedureStatementTestWhenErrorGDSCode);
  lSuite.AddTest('TestExecuteStatement', @RunTTestProcedureStatementTestExecuteStatement);
  lSuite.AddTest('TestExecuteStatementReturningValues', @RunTTestProcedureStatementTestExecuteStatementReturningValues);
  lSuite.AddTest('TestExecuteStatementReturningValuesColon', @RunTTestProcedureStatementTestExecuteStatementReturningValuesColon);
  lSuite.AddTest('TestExecuteStatementReturningValuesBrackets', @RunTTestProcedureStatementTestExecuteStatementReturningValuesBrackets);
  lSuite.AddTest('TestForSimple', @RunTTestProcedureStatementTestForSimple);
  lSuite.AddTest('TestForSimpleNoColon', @RunTTestProcedureStatementTestForSimpleNoColon);
  lSuite.AddTest('TestForSimple2fields', @RunTTestProcedureStatementTestForSimple2fields);
  lSuite.AddTest('TestForBlock', @RunTTestProcedureStatementTestForBlock);
  lSuite:=ARegistry.AddSuite('tcparser.TTestCreateProcedureParser');
  lSuite.AddTest('TestEmptyProcedure', @RunTTestCreateProcedureParserTestEmptyProcedure);
  lSuite.AddTest('TestExitProcedure', @RunTTestCreateProcedureParserTestExitProcedure);
  lSuite.AddTest('TestProcedureOneArgument', @RunTTestCreateProcedureParserTestProcedureOneArgument);
  lSuite.AddTest('TestProcedureTwoArguments', @RunTTestCreateProcedureParserTestProcedureTwoArguments);
  lSuite.AddTest('TestProcedureOneReturnValue', @RunTTestCreateProcedureParserTestProcedureOneReturnValue);
  lSuite.AddTest('TestProcedureTwoReturnValues', @RunTTestCreateProcedureParserTestProcedureTwoReturnValues);
  lSuite.AddTest('TestProcedureOneLocalVariable', @RunTTestCreateProcedureParserTestProcedureOneLocalVariable);
  lSuite.AddTest('TestProcedureTwoLocalVariable', @RunTTestCreateProcedureParserTestProcedureTwoLocalVariable);
  lSuite.AddTest('TestProcedureInputOutputLocal', @RunTTestCreateProcedureParserTestProcedureInputOutputLocal);
  lSuite:=ARegistry.AddSuite('tcparser.TTestCreateTriggerParser');
  lSuite.AddTest('TestEmptyTrigger', @RunTTestCreateTriggerParserTestEmptyTrigger);
  lSuite.AddTest('TestExitTrigger', @RunTTestCreateTriggerParserTestExitTrigger);
  lSuite.AddTest('TestEmptyTriggerAfterUpdate', @RunTTestCreateTriggerParserTestEmptyTriggerAfterUpdate);
  lSuite.AddTest('TestEmptyTriggerBeforeDelete', @RunTTestCreateTriggerParserTestEmptyTriggerBeforeDelete);
  lSuite.AddTest('TestEmptyTriggerBeforeInsert', @RunTTestCreateTriggerParserTestEmptyTriggerBeforeInsert);
  lSuite.AddTest('TestEmptyTriggerBeforeInsertPosition1', @RunTTestCreateTriggerParserTestEmptyTriggerBeforeInsertPosition1);
  lSuite.AddTest('TestEmptyTriggerBeforeInsertPosition1inActive', @RunTTestCreateTriggerParserTestEmptyTriggerBeforeInsertPosition1inActive);
  lSuite.AddTest('TestEmptyTriggerBeforeInsertPosition1Active', @RunTTestCreateTriggerParserTestEmptyTriggerBeforeInsertPosition1Active);
  lSuite.AddTest('TestTriggerOneLocalVariable', @RunTTestCreateTriggerParserTestTriggerOneLocalVariable);
  lSuite.AddTest('TestTriggerTwoLocalVariables', @RunTTestCreateTriggerParserTestTriggerTwoLocalVariables);
  lSuite.AddTest('TestAlterTrigger', @RunTTestCreateTriggerParserTestAlterTrigger);
  lSuite:=ARegistry.AddSuite('tcparser.TTestDeclareExternalFunctionParser');
  lSuite.AddTest('TestEmptyfunction', @RunTTestDeclareExternalFunctionParserTestEmptyfunction);
  lSuite.AddTest('TestEmptyfunctionByValue', @RunTTestDeclareExternalFunctionParserTestEmptyfunctionByValue);
  lSuite.AddTest('TestCStringfunction', @RunTTestDeclareExternalFunctionParserTestCStringfunction);
  lSuite.AddTest('TestCStringFreeItfunction', @RunTTestDeclareExternalFunctionParserTestCStringFreeItfunction);
  lSuite.AddTest('TestOneArgumentFunction', @RunTTestDeclareExternalFunctionParserTestOneArgumentFunction);
  lSuite.AddTest('TestTwoArgumentsFunction', @RunTTestDeclareExternalFunctionParserTestTwoArgumentsFunction);
  lSuite:=ARegistry.AddSuite('tcparser.TTestGrantParser');
  lSuite.AddTest('TestSimple', @RunTTestGrantParserTestSimple);
  lSuite.AddTest('Test2Operations', @RunTTestGrantParserTest2Operations);
  lSuite.AddTest('TestDeletePrivilege', @RunTTestGrantParserTestDeletePrivilege);
  lSuite.AddTest('TestUpdatePrivilege', @RunTTestGrantParserTestUpdatePrivilege);
  lSuite.AddTest('TestInsertPrivilege', @RunTTestGrantParserTestInsertPrivilege);
  lSuite.AddTest('TestReferencePrivilege', @RunTTestGrantParserTestReferencePrivilege);
  lSuite.AddTest('TestAllPrivileges', @RunTTestGrantParserTestAllPrivileges);
  lSuite.AddTest('TestAllPrivileges2', @RunTTestGrantParserTestAllPrivileges2);
  lSuite.AddTest('TestUpdateColPrivilege', @RunTTestGrantParserTestUpdateColPrivilege);
  lSuite.AddTest('TestUpdate2ColsPrivilege', @RunTTestGrantParserTestUpdate2ColsPrivilege);
  lSuite.AddTest('TestReferenceColPrivilege', @RunTTestGrantParserTestReferenceColPrivilege);
  lSuite.AddTest('TestReference2ColsPrivilege', @RunTTestGrantParserTestReference2ColsPrivilege);
  lSuite.AddTest('TestUserPrivilege', @RunTTestGrantParserTestUserPrivilege);
  lSuite.AddTest('TestUserPrivilegeWithGrant', @RunTTestGrantParserTestUserPrivilegeWithGrant);
  lSuite.AddTest('TestGroupPrivilege', @RunTTestGrantParserTestGroupPrivilege);
  lSuite.AddTest('TestProcedurePrivilege', @RunTTestGrantParserTestProcedurePrivilege);
  lSuite.AddTest('TestViewPrivilege', @RunTTestGrantParserTestViewPrivilege);
  lSuite.AddTest('TestTriggerPrivilege', @RunTTestGrantParserTestTriggerPrivilege);
  lSuite.AddTest('TestPublicPrivilege', @RunTTestGrantParserTestPublicPrivilege);
  lSuite.AddTest('TestExecuteToUser', @RunTTestGrantParserTestExecuteToUser);
  lSuite.AddTest('TestExecuteToProcedure', @RunTTestGrantParserTestExecuteToProcedure);
  lSuite.AddTest('TestRoleToUser', @RunTTestGrantParserTestRoleToUser);
  lSuite.AddTest('TestRoleToUserWithAdmin', @RunTTestGrantParserTestRoleToUserWithAdmin);
  lSuite.AddTest('TestRoleToPublic', @RunTTestGrantParserTestRoleToPublic);
  lSuite.AddTest('Test2RolesToUser', @RunTTestGrantParserTest2RolesToUser);
  lSuite:=ARegistry.AddSuite('tcparser.TTestRevokeParser');
  lSuite.AddTest('TestSimple', @RunTTestRevokeParserTestSimple);
  lSuite.AddTest('Test2Operations', @RunTTestRevokeParserTest2Operations);
  lSuite.AddTest('TestDeletePrivilege', @RunTTestRevokeParserTestDeletePrivilege);
  lSuite.AddTest('TestUpdatePrivilege', @RunTTestRevokeParserTestUpdatePrivilege);
  lSuite.AddTest('TestInsertPrivilege', @RunTTestRevokeParserTestInsertPrivilege);
  lSuite.AddTest('TestReferencePrivilege', @RunTTestRevokeParserTestReferencePrivilege);
  lSuite.AddTest('TestAllPrivileges', @RunTTestRevokeParserTestAllPrivileges);
  lSuite.AddTest('TestAllPrivileges2', @RunTTestRevokeParserTestAllPrivileges2);
  lSuite.AddTest('TestUpdateColPrivilege', @RunTTestRevokeParserTestUpdateColPrivilege);
  lSuite.AddTest('TestUpdate2ColsPrivilege', @RunTTestRevokeParserTestUpdate2ColsPrivilege);
  lSuite.AddTest('TestReferenceColPrivilege', @RunTTestRevokeParserTestReferenceColPrivilege);
  lSuite.AddTest('TestReference2ColsPrivilege', @RunTTestRevokeParserTestReference2ColsPrivilege);
  lSuite.AddTest('TestUserPrivilege', @RunTTestRevokeParserTestUserPrivilege);
  lSuite.AddTest('TestUserPrivilegeWithRevoke', @RunTTestRevokeParserTestUserPrivilegeWithRevoke);
  lSuite.AddTest('TestGroupPrivilege', @RunTTestRevokeParserTestGroupPrivilege);
  lSuite.AddTest('TestProcedurePrivilege', @RunTTestRevokeParserTestProcedurePrivilege);
  lSuite.AddTest('TestViewPrivilege', @RunTTestRevokeParserTestViewPrivilege);
  lSuite.AddTest('TestTriggerPrivilege', @RunTTestRevokeParserTestTriggerPrivilege);
  lSuite.AddTest('TestPublicPrivilege', @RunTTestRevokeParserTestPublicPrivilege);
  lSuite.AddTest('TestExecuteToUser', @RunTTestRevokeParserTestExecuteToUser);
  lSuite.AddTest('TestExecuteToProcedure', @RunTTestRevokeParserTestExecuteToProcedure);
  lSuite.AddTest('TestRoleToUser', @RunTTestRevokeParserTestRoleToUser);
  lSuite.AddTest('TestRoleToPublic', @RunTTestRevokeParserTestRoleToPublic);
  lSuite.AddTest('Test2RolesToUser', @RunTTestRevokeParserTest2RolesToUser);
  lSuite:=ARegistry.AddSuite('tcparser.TTestGlobalParser');
  lSuite.AddTest('TestEmpty', @RunTTestGlobalParserTestEmpty);
end;

end.

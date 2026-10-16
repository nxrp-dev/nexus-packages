{
    fpGUI IDE - Pascal Tokeniser Tests

    Copyright (C) 2026 See the file AUTHORS.txt, included in this
    distribution, for details of the copyright.

    See the file COPYING.modifiedLGPL, included in this distribution,
    for details about redistributing fpGUI.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

    Description:
      Unit tests for TFpgPascalTokeniser. Tests are organised by token
      category: keywords, identifiers, numbers, strings, comments,
      directives, symbols/operators, and multi-line handling.
}
unit ide.test.pascal.tokeniser;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, ide.pascal.tokeniser;

type
  TFpgPasTokenKindArray = array of TFpgPasTokenKind;
  TStringArray = array of string;

  { TTestPascalTokeniser }

  TTestPascalTokeniser = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FTok: TFpgPascalTokeniser;
    { Helper: collect all non-whitespace, non-line-ending tokens }
    procedure CollectTokens(const ASource: string;
      out AKinds: array of TFpgPasTokenKind;
      out ATexts: array of string;
      out ACount: Integer); overload;
    procedure CollectTokens(const ASource: string;
      out AKinds: TFpgPasTokenKindArray;
      out ATexts: TStringArray); overload;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    { --- Empty / EOF --- }
    procedure TestEmptySource;

    { --- Keywords --- }
    procedure TestSingleKeyword_Begin;
    procedure TestSingleKeyword_End;
    procedure TestSingleKeyword_Procedure;
    procedure TestSingleKeyword_Function;
    procedure TestSingleKeyword_Interface;
    procedure TestSingleKeyword_Generic;
    procedure TestSingleKeyword_Specialize;
    procedure TestSingleKeyword_Dispinterface;
    procedure TestKeyword_CaseInsensitive;
    procedure TestAllKeywordsRecognised;

    { --- Identifiers --- }
    procedure TestSimpleIdentifier;
    procedure TestIdentifier_WithUnderscore;
    procedure TestIdentifier_WithDigits;
    procedure TestIdentifier_NotKeyword;

    { --- Numbers --- }
    procedure TestNumber_Decimal;
    procedure TestNumber_Hex;
    procedure TestNumber_Binary;
    procedure TestNumber_Octal;
    procedure TestNumber_Float;
    procedure TestNumber_FloatExponent;

    { --- Strings --- }
    procedure TestString_Simple;
    procedure TestString_EmbeddedQuotes;
    procedure TestString_Empty;
    procedure TestString_CharHash;
    procedure TestString_CharCaret;
    procedure TestString_Concatenated;

    { --- Comments --- }
    procedure TestComment_LineComment;
    procedure TestComment_BraceComment;
    procedure TestComment_ParenStarComment;
    procedure TestComment_MultiLine_Brace;
    procedure TestComment_MultiLine_ParenStar;

    { --- Directives --- }
    procedure TestDirective_BraceStyle;
    procedure TestDirective_ParenStarStyle;

    { --- Symbols / Operators --- }
    procedure TestSymbol_SingleChars;
    procedure TestSymbol_Assign;
    procedure TestSymbol_NotEqual;
    procedure TestSymbol_LessEqual;
    procedure TestSymbol_GreaterEqual;
    procedure TestSymbol_DotDot;
    procedure TestSymbol_Power;
    procedure TestSymbol_AtAt;
    procedure TestSymbol_PlusAssign;

    { --- Line and Column Tracking --- }
    procedure TestLineColumn_FirstToken;
    procedure TestLineColumn_SecondLine;
    procedure TestLineColumn_MultipleTokensOnLine;

    { --- Incomplete / Error Recovery --- }
    procedure TestIncomplete_UnterminatedString;
    procedure TestIncomplete_UnterminatedBraceComment;
    procedure TestIncomplete_UnterminatedParenStarComment;
    procedure TestIncomplete_UnknownChar;

    { --- Mixed Source --- }
    procedure TestMixedSource_SimpleProgram;
    procedure TestMixedSource_UsesClause;

    { --- FpgPasIsKeyword --- }
    procedure TestIsKeyword_True;
    procedure TestIsKeyword_False;
    procedure TestIsKeyword_CaseInsensitive;

    { --- FpgPasIsModifier + fptkModifier token kind --- }
    procedure TestModifier_VisibilityTokens;
    procedure TestModifier_MethodModifierTokens;
    procedure TestModifier_CallingConventionTokens;
    procedure TestIsModifier_True;
    procedure TestIsModifier_False;
    procedure TestIsModifier_CaseInsensitive;
    procedure TestModifier_NotKeyword;
    procedure TestKeyword_NotModifier;

    { --- Property directives --- }
    procedure TestModifier_PropertyDirectiveTokens;
    procedure TestIsModifier_PropertyDirectives;

    { --- Lookup table invariants --- }
    procedure TestKeywordTableIsSorted;
    procedure TestModifierTableIsSorted;
    procedure TestEveryKeywordIsFound;
    procedure TestEveryModifierIsFound;
    procedure TestKeywordTableHasNoDuplicates;
    procedure TestModifierTableHasNoDuplicates;
  end;


procedure RegisteridetestpascaltokeniserTests(ARegistry: TNXTestRegistry);

implementation

{ TTestPascalTokeniser }

procedure TTestPascalTokeniser.CollectTokens(const ASource: string;
  out AKinds: array of TFpgPasTokenKind;
  out ATexts: array of string;
  out ACount: Integer);
var
  tok: TFpgPasToken;
begin
  ACount := 0;
  FTok.SetSource(ASource);
  repeat
    tok := FTok.NextToken;
    if tok.Kind in [fptkWhitespace, fptkLineEnding] then
      Continue;
    if tok.Kind = fptkEOF then
      Break;
    if ACount <= High(AKinds) then
    begin
      AKinds[ACount] := tok.Kind;
      ATexts[ACount] := FTok.TokenText;
    end;
    Inc(ACount);
  until False;
end;

procedure TTestPascalTokeniser.CollectTokens(const ASource: string;
  out AKinds: TFpgPasTokenKindArray;
  out ATexts: TStringArray);
var
  count: Integer;
  localKinds: array[0..63] of TFpgPasTokenKind;
  localTexts: array[0..63] of string;
  i: Integer;
begin
  CollectTokens(ASource, localKinds, localTexts, count);
  SetLength(AKinds, count);
  SetLength(ATexts, count);
  for i := 0 to count - 1 do
  begin
    AKinds[i] := localKinds[i];
    ATexts[i] := localTexts[i];
  end;
end;

procedure TTestPascalTokeniser.SetUp;
begin
  FTok := TFpgPascalTokeniser.Create;
end;

procedure TTestPascalTokeniser.TearDown;
begin
  FTok.Free;
end;

{ --- Empty / EOF --- }

procedure TTestPascalTokeniser.TestEmptySource;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkEOF))=(Ord(tok.Kind)), 'Empty source should yield EOF');
end;

{ --- Keywords --- }

procedure TTestPascalTokeniser.TestSingleKeyword_Begin;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('begin');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkKeyword))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('begin')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestSingleKeyword_End;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('end');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkKeyword))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('end')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestSingleKeyword_Procedure;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('procedure');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkKeyword))=(Ord(tok.Kind)), 'Kind');
end;

procedure TTestPascalTokeniser.TestSingleKeyword_Function;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('function');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkKeyword))=(Ord(tok.Kind)), 'Kind');
end;

procedure TTestPascalTokeniser.TestSingleKeyword_Interface;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('interface');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkKeyword))=(Ord(tok.Kind)), 'Kind');
end;

procedure TTestPascalTokeniser.TestSingleKeyword_Generic;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('generic');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkKeyword))=(Ord(tok.Kind)), 'Kind');
end;

procedure TTestPascalTokeniser.TestSingleKeyword_Specialize;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('specialize');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkKeyword))=(Ord(tok.Kind)), 'Kind');
end;

procedure TTestPascalTokeniser.TestSingleKeyword_Dispinterface;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('dispinterface');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkKeyword))=(Ord(tok.Kind)), 'Kind');
end;

procedure TTestPascalTokeniser.TestKeyword_CaseInsensitive;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('BEGIN');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkKeyword))=(Ord(tok.Kind)), 'Uppercase');
  FContext.AssertTrue(('BEGIN')=(FTok.TokenText), 'Preserves case');

  FTok.SetSource('Begin');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkKeyword))=(Ord(tok.Kind)), 'Mixed case');
  FContext.AssertTrue(('Begin')=(FTok.TokenText), 'Preserves case');
end;

procedure TTestPascalTokeniser.TestAllKeywordsRecognised;
const
  Keywords: array[0..78] of string = (
    'absolute', 'and', 'array', 'as', 'asm', 'begin', 'bitpacked',
    'case', 'class', 'const', 'constref', 'constructor', 'contains',
    'destructor', 'dispinterface', 'div', 'do', 'downto',
    'else', 'end', 'except', 'exports', 'false', 'file',
    'finalization', 'finally', 'for', 'function',
    'generic', 'goto',
    'if', 'implementation', 'in', 'inherited', 'initialization',
    'inline', 'interface', 'is',
    'label', 'library',
    'mod', 'nil', 'not',
    'objccategory', 'objcclass', 'objcprotocol', 'object', 'of',
    'operator', 'or', 'otherwise',
    'package', 'packed', 'procedure', 'program', 'property',
    'raise', 'record', 'repeat', 'requires', 'resourcestring',
    'self', 'set', 'shl', 'shr', 'specialize',
    'then', 'threadvar', 'to', 'true', 'try', 'type',
    'unit', 'until', 'uses', 'var', 'while', 'with', 'xor'
  );
var
  i: Integer;
  tok: TFpgPasToken;
begin
  for i := Low(Keywords) to High(Keywords) do
  begin
    FTok.SetSource(Keywords[i]);
    tok := FTok.NextToken;
    FContext.AssertTrue((Ord(fptkKeyword))=(Ord(tok.Kind)), 'Keyword "' + Keywords[i] + '" should be fptkKeyword');
  end;
end;

{ --- Identifiers --- }

procedure TTestPascalTokeniser.TestSimpleIdentifier;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('MyVar');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkIdentifier))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('MyVar')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestIdentifier_WithUnderscore;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('_private_field');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkIdentifier))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('_private_field')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestIdentifier_WithDigits;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('Item2Count');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkIdentifier))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('Item2Count')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestIdentifier_NotKeyword;
var
  tok: TFpgPasToken;
begin
  { 'beginning' starts with 'begin' but is not a keyword }
  FTok.SetSource('beginning');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkIdentifier))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('beginning')=(FTok.TokenText), 'Text');
end;

{ --- Numbers --- }

procedure TTestPascalTokeniser.TestNumber_Decimal;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('42');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkNumber))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('42')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestNumber_Hex;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('$FF');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkNumber))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('$FF')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestNumber_Binary;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('%10110');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkNumber))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('%10110')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestNumber_Octal;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('&77');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkNumber))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('&77')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestNumber_Float;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('3.14');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkNumber))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('3.14')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestNumber_FloatExponent;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('1.5e10');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkNumber))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('1.5e10')=(FTok.TokenText), 'Text');
end;

{ --- Strings --- }

procedure TTestPascalTokeniser.TestString_Simple;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('''hello''');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkString))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('''hello''')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestString_EmbeddedQuotes;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('''it''''s''');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkString))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('''it''''s''')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestString_Empty;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('''''');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkString))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('''''')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestString_CharHash;
var
  tok: TFpgPasToken;
begin
  { #13#10 should be a single string token }
  FTok.SetSource('#13#10');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkString))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('#13#10')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestString_CharCaret;
var
  tok: TFpgPasToken;
begin
  { ^M = control character }
  FTok.SetSource('^M');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkString))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('^M')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestString_Concatenated;
var
  tok: TFpgPasToken;
begin
  { 'abc'#13#10'def' should be a single string token }
  FTok.SetSource('''abc''#13#10''def''');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkString))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('''abc''#13#10''def''')=(FTok.TokenText), 'Text');
end;

{ --- Comments --- }

procedure TTestPascalTokeniser.TestComment_LineComment;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('// this is a comment');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkComment))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('// this is a comment')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestComment_BraceComment;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('{ a comment }');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkComment))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('{ a comment }')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestComment_ParenStarComment;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('(* a comment *)');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkComment))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('(* a comment *)')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestComment_MultiLine_Brace;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('{ line1' + LineEnding + '  line2 }');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkComment))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(Pos(LineEnding, FTok.TokenText) > 0, 'Contains line ending');
end;

procedure TTestPascalTokeniser.TestComment_MultiLine_ParenStar;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('(* line1' + LineEnding + '   line2 *)');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkComment))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(Pos(LineEnding, FTok.TokenText) > 0, 'Contains line ending');
end;

{ --- Directives --- }

procedure TTestPascalTokeniser.TestDirective_BraceStyle;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('{$mode objfpc}');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkDirective))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('{$mode objfpc}')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestDirective_ParenStarStyle;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('(*$IFDEF UNIX*)');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkDirective))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('(*$IFDEF UNIX*)')=(FTok.TokenText), 'Text');
end;

{ --- Symbols / Operators --- }

procedure TTestPascalTokeniser.TestSymbol_SingleChars;
const
  Chars: array[0..17] of Char = (
    '(', ')', '*', '+', ',', '-', '.', '/', ':', ';',
    '<', '=', '>', '@', '[', ']', '^', '\'
  );
var
  i: Integer;
  tok: TFpgPasToken;
begin
  for i := Low(Chars) to High(Chars) do
  begin
    FTok.SetSource(Chars[i]);
    tok := FTok.NextToken;
    FContext.AssertTrue((Ord(fptkSymbol))=(Ord(tok.Kind)), 'Char "' + Chars[i] + '" kind');
    FContext.AssertTrue((Chars[i])=(FTok.TokenText), 'Char "' + Chars[i] + '" text');
  end;
end;

procedure TTestPascalTokeniser.TestSymbol_Assign;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource(':=');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkSymbol))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue((':=')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestSymbol_NotEqual;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('<>');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkSymbol))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('<>')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestSymbol_LessEqual;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('<=');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkSymbol))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('<=')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestSymbol_GreaterEqual;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('>=');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkSymbol))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('>=')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestSymbol_DotDot;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('..');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkSymbol))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('..')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestSymbol_Power;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('**');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkSymbol))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('**')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestSymbol_AtAt;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('@@');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkSymbol))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('@@')=(FTok.TokenText), 'Text');
end;

procedure TTestPascalTokeniser.TestSymbol_PlusAssign;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('+=');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkSymbol))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue(('+=')=(FTok.TokenText), 'Text');
end;

{ --- Line and Column Tracking --- }

procedure TTestPascalTokeniser.TestLineColumn_FirstToken;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('begin');
  tok := FTok.NextToken;
  FContext.AssertTrue((1)=(tok.Line), 'Line');
  FContext.AssertTrue((1)=(tok.Column), 'Column');
end;

procedure TTestPascalTokeniser.TestLineColumn_SecondLine;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('begin' + LineEnding + 'end');
  tok := FTok.NextToken;  { begin }
  FContext.AssertTrue((1)=(tok.Line), 'begin line');
  tok := FTok.NextToken;  { line ending }
  tok := FTok.NextToken;  { end }
  FContext.AssertTrue((2)=(tok.Line), 'end line');
  FContext.AssertTrue((1)=(tok.Column), 'end column');
end;

procedure TTestPascalTokeniser.TestLineColumn_MultipleTokensOnLine;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('var x: Integer;');
  tok := FTok.NextToken;  { var }
  FContext.AssertTrue((1)=(tok.Column), 'var col');
  tok := FTok.NextToken;  { whitespace }
  tok := FTok.NextToken;  { x }
  FContext.AssertTrue((5)=(tok.Column), 'x col');
  tok := FTok.NextToken;  { : }
  FContext.AssertTrue((6)=(tok.Column), ': col');
end;

{ --- Incomplete / Error Recovery --- }

procedure TTestPascalTokeniser.TestIncomplete_UnterminatedString;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('''hello');
  tok := FTok.NextToken;
  { Should return a string token for what it has, not crash }
  FContext.AssertTrue((Ord(fptkString))=(Ord(tok.Kind)), 'Kind');
end;

procedure TTestPascalTokeniser.TestIncomplete_UnterminatedBraceComment;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('{ unterminated');
  tok := FTok.NextToken;
  { Should return a comment token, not crash }
  FContext.AssertTrue((Ord(fptkComment))=(Ord(tok.Kind)), 'Kind');
end;

procedure TTestPascalTokeniser.TestIncomplete_UnterminatedParenStarComment;
var
  tok: TFpgPasToken;
begin
  FTok.SetSource('(* unterminated');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkComment))=(Ord(tok.Kind)), 'Kind');
end;

procedure TTestPascalTokeniser.TestIncomplete_UnknownChar;
var
  tok: TFpgPasToken;
begin
  { Tilde is not a Pascal token }
  FTok.SetSource('~');
  tok := FTok.NextToken;
  FContext.AssertTrue((Ord(fptkSymbol))=(Ord(tok.Kind)), 'Kind');
  FContext.AssertTrue((1)=(tok.Len), 'Len');
end;

{ --- Mixed Source --- }

procedure TTestPascalTokeniser.TestMixedSource_SimpleProgram;
var
  kinds: array[0..19] of TFpgPasTokenKind;
  texts: array[0..19] of string;
  count: Integer;
begin
  CollectTokens(
    'program Test;' + LineEnding +
    'begin' + LineEnding +
    'end.',
    kinds, texts, count);
  FContext.AssertTrue(count >= 5, 'At least 5 tokens');
  FContext.AssertTrue((Ord(fptkKeyword))=(Ord(kinds[0])), 'program');
  FContext.AssertTrue((Ord(fptkIdentifier))=(Ord(kinds[1])), 'Test');
  FContext.AssertTrue((Ord(fptkSymbol))=(Ord(kinds[2])), ';');
  FContext.AssertTrue((Ord(fptkKeyword))=(Ord(kinds[3])), 'begin');
  FContext.AssertTrue((Ord(fptkKeyword))=(Ord(kinds[4])), 'end');
end;

procedure TTestPascalTokeniser.TestMixedSource_UsesClause;
var
  kinds: array[0..19] of TFpgPasTokenKind;
  texts: array[0..19] of string;
  count: Integer;
begin
  CollectTokens('uses SysUtils, Classes;', kinds, texts, count);
  FContext.AssertTrue((5)=(count), 'Count');
  FContext.AssertTrue((Ord(fptkKeyword))=(Ord(kinds[0])), 'uses');
  FContext.AssertTrue(('SysUtils')=(texts[1]), '');
  FContext.AssertTrue((Ord(fptkSymbol))=(Ord(kinds[2])), ',');
  FContext.AssertTrue(('Classes')=(texts[3]), '');
  FContext.AssertTrue((Ord(fptkSymbol))=(Ord(kinds[4])), ';');
end;

{ --- FpgPasIsKeyword --- }

procedure TTestPascalTokeniser.TestIsKeyword_True;
begin
  FContext.AssertTrue(FpgPasIsKeyword('begin'), 'begin is keyword');
  FContext.AssertTrue(FpgPasIsKeyword('procedure'), 'procedure is keyword');
  FContext.AssertTrue(FpgPasIsKeyword('interface'), 'interface is keyword');
end;

procedure TTestPascalTokeniser.TestIsKeyword_False;
begin
  FContext.AssertTrue(not (FpgPasIsKeyword('MyVar')), 'MyVar is not keyword');
  FContext.AssertTrue(not (FpgPasIsKeyword('')), 'empty is not keyword');
  FContext.AssertTrue(not (FpgPasIsKeyword('beginning')), 'beginning is not keyword');
end;

procedure TTestPascalTokeniser.TestIsKeyword_CaseInsensitive;
begin
  FContext.AssertTrue(FpgPasIsKeyword('BEGIN'), 'BEGIN');
  FContext.AssertTrue(FpgPasIsKeyword('Begin'), 'Begin');
  FContext.AssertTrue(FpgPasIsKeyword('bEgIn'), 'bEgIn');
end;


{ --- FpgPasIsModifier + fptkModifier token kind --- }

procedure TTestPascalTokeniser.TestModifier_VisibilityTokens;
var
  kinds: array of TFpgPasTokenKind;
  texts: array of string;
begin
  CollectTokens('private', kinds, texts);
  FContext.AssertTrue((1)=(Length(kinds)), 'private count');
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'private kind');
  FContext.AssertTrue(('private')=(texts[0]), 'private text');

  CollectTokens('protected', kinds, texts);
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'protected kind');

  CollectTokens('public', kinds, texts);
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'public kind');

  CollectTokens('published', kinds, texts);
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'published kind');

  CollectTokens('strict', kinds, texts);
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'strict kind');
end;

procedure TTestPascalTokeniser.TestModifier_MethodModifierTokens;
var
  kinds: array of TFpgPasTokenKind;
  texts: array of string;
begin
  CollectTokens('override', kinds, texts);
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'override kind');

  CollectTokens('virtual', kinds, texts);
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'virtual kind');

  CollectTokens('abstract', kinds, texts);
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'abstract kind');

  CollectTokens('final', kinds, texts);
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'final kind');

  CollectTokens('overload', kinds, texts);
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'overload kind');

  CollectTokens('reintroduce', kinds, texts);
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'reintroduce kind');
end;

procedure TTestPascalTokeniser.TestModifier_CallingConventionTokens;
var
  kinds: array of TFpgPasTokenKind;
  texts: array of string;
begin
  CollectTokens('stdcall', kinds, texts);
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'stdcall kind');

  CollectTokens('cdecl', kinds, texts);
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'cdecl kind');

  CollectTokens('register', kinds, texts);
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'register kind');

  CollectTokens('safecall', kinds, texts);
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'safecall kind');
end;

procedure TTestPascalTokeniser.TestIsModifier_True;
begin
  FContext.AssertTrue(FpgPasIsModifier('private'), 'private is modifier');
  FContext.AssertTrue(FpgPasIsModifier('override'), 'override is modifier');
  FContext.AssertTrue(FpgPasIsModifier('stdcall'), 'stdcall is modifier');
  FContext.AssertTrue(FpgPasIsModifier('virtual'), 'virtual is modifier');
  FContext.AssertTrue(FpgPasIsModifier('deprecated'), 'deprecated is modifier');
  FContext.AssertTrue(FpgPasIsModifier('external'), 'external is modifier');
end;

procedure TTestPascalTokeniser.TestIsModifier_False;
begin
  FContext.AssertTrue(not (FpgPasIsModifier('MyVar')), 'MyVar is not modifier');
  FContext.AssertTrue(not (FpgPasIsModifier('')), 'empty is not modifier');
  FContext.AssertTrue(not (FpgPasIsModifier('overrideX')), 'overrideX not modifier');
end;

procedure TTestPascalTokeniser.TestIsModifier_CaseInsensitive;
begin
  FContext.AssertTrue(FpgPasIsModifier('PRIVATE'), 'PRIVATE');
  FContext.AssertTrue(FpgPasIsModifier('Private'), 'Private');
  FContext.AssertTrue(FpgPasIsModifier('OVERRIDE'), 'OVERRIDE');
  FContext.AssertTrue(FpgPasIsModifier('StdCall'), 'StdCall');
end;

procedure TTestPascalTokeniser.TestModifier_NotKeyword;
begin
  { Modifier words must not be classified as keywords }
  FContext.AssertTrue(not (FpgPasIsKeyword('private')), 'private not keyword');
  FContext.AssertTrue(not (FpgPasIsKeyword('override')), 'override not keyword');
  FContext.AssertTrue(not (FpgPasIsKeyword('virtual')), 'virtual not keyword');
  FContext.AssertTrue(not (FpgPasIsKeyword('stdcall')), 'stdcall not keyword');
end;

procedure TTestPascalTokeniser.TestKeyword_NotModifier;
begin
  { Reserved words must not be classified as modifiers }
  FContext.AssertTrue(not (FpgPasIsModifier('begin')), 'begin not modifier');
  FContext.AssertTrue(not (FpgPasIsModifier('procedure')), 'procedure not modifier');
  FContext.AssertTrue(not (FpgPasIsModifier('class')), 'class not modifier');
  FContext.AssertTrue(not (FpgPasIsModifier('interface')), 'interface not modifier');
end;

{ --- Property directives --- }

procedure TTestPascalTokeniser.TestModifier_PropertyDirectiveTokens;
var
  kinds: array of TFpgPasTokenKind;
  texts: array of string;
begin
  CollectTokens('read', kinds, texts);
  FContext.AssertTrue((1)=(Length(kinds)), 'read count');
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'read kind');
  FContext.AssertTrue(('read')=(texts[0]), 'read text');

  CollectTokens('write', kinds, texts);
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'write kind');

  CollectTokens('default', kinds, texts);
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'default kind');

  CollectTokens('nodefault', kinds, texts);
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'nodefault kind');

  CollectTokens('index', kinds, texts);
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'index kind');

  CollectTokens('stored', kinds, texts);
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'stored kind');

  CollectTokens('implements', kinds, texts);
  FContext.AssertTrue((Ord(fptkModifier))=(Ord(kinds[0])), 'implements kind');
end;

procedure TTestPascalTokeniser.TestIsModifier_PropertyDirectives;
begin
  FContext.AssertTrue(FpgPasIsModifier('read'), 'read');
  FContext.AssertTrue(FpgPasIsModifier('write'), 'write');
  FContext.AssertTrue(FpgPasIsModifier('default'), 'default');
  FContext.AssertTrue(FpgPasIsModifier('nodefault'), 'nodefault');
  FContext.AssertTrue(FpgPasIsModifier('index'), 'index');
  FContext.AssertTrue(FpgPasIsModifier('stored'), 'stored');
  FContext.AssertTrue(FpgPasIsModifier('implements'), 'implements');
  FContext.AssertTrue(FpgPasIsModifier('readonly'), 'readonly');
  { Mixed case must work too - lookup uppercases first }
  FContext.AssertTrue(FpgPasIsModifier('Read'), 'Read');
  FContext.AssertTrue(FpgPasIsModifier('WRITE'), 'WRITE');
end;

{ --- Lookup table invariants ---

  Both tables are sorted arrays searched with CompareStr. An entry inserted out
  of order, or a count constant that disagrees with the literal, breaks lookups
  for unrelated entries without any compiler error. These tests guard the table
  itself rather than any single word. }

procedure TTestPascalTokeniser.TestKeywordTableIsSorted;
var
  i: Integer;
begin
  for i := 1 to FpgPasKeywordCount-1 do
    FContext.AssertTrue(CompareStr(FpgPasKeyword(i-1), FpgPasKeyword(i)) < 0, Format('keyword table out of order at %d: "%s" follows "%s"',
        [i, FpgPasKeyword(i), FpgPasKeyword(i-1)]));
end;

procedure TTestPascalTokeniser.TestModifierTableIsSorted;
var
  i: Integer;
begin
  for i := 1 to FpgPasModifierCount-1 do
    FContext.AssertTrue(CompareStr(FpgPasModifier(i-1), FpgPasModifier(i)) < 0, Format('modifier table out of order at %d: "%s" follows "%s"',
        [i, FpgPasModifier(i), FpgPasModifier(i-1)]));
end;

{ Also catches a count constant larger than the literal: the accessor returns
  '' for the overshoot, which is not findable. }
procedure TTestPascalTokeniser.TestEveryKeywordIsFound;
var
  i: Integer;
begin
  for i := 0 to FpgPasKeywordCount-1 do
    FContext.AssertTrue(FpgPasIsKeyword(FpgPasKeyword(i)), Format('keyword %d ("%s") not found by lookup',
        [i, FpgPasKeyword(i)]));
end;

procedure TTestPascalTokeniser.TestEveryModifierIsFound;
var
  i: Integer;
begin
  for i := 0 to FpgPasModifierCount-1 do
    FContext.AssertTrue(FpgPasIsModifier(FpgPasModifier(i)), Format('modifier %d ("%s") not found by lookup',
        [i, FpgPasModifier(i)]));
end;

procedure TTestPascalTokeniser.TestKeywordTableHasNoDuplicates;
var
  i: Integer;
begin
  for i := 1 to FpgPasKeywordCount-1 do
    FContext.AssertTrue(not (FpgPasKeyword(i) = FpgPasKeyword(i-1)), Format('duplicate keyword "%s" at %d', [FpgPasKeyword(i), i]));
end;

procedure TTestPascalTokeniser.TestModifierTableHasNoDuplicates;
var
  i: Integer;
begin
  for i := 1 to FpgPasModifierCount-1 do
    FContext.AssertTrue(not (FpgPasModifier(i) = FpgPasModifier(i-1)), Format('duplicate modifier "%s" at %d', [FpgPasModifier(i), i]));
end;


procedure RunTTestPascalTokeniserTestEmptySource(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEmptySource';
    lFixture.SetUp;
    try lFixture.TestEmptySource; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestSingleKeyword_Begin(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSingleKeyword_Begin';
    lFixture.SetUp;
    try lFixture.TestSingleKeyword_Begin; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestSingleKeyword_End(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSingleKeyword_End';
    lFixture.SetUp;
    try lFixture.TestSingleKeyword_End; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestSingleKeyword_Procedure(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSingleKeyword_Procedure';
    lFixture.SetUp;
    try lFixture.TestSingleKeyword_Procedure; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestSingleKeyword_Function(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSingleKeyword_Function';
    lFixture.SetUp;
    try lFixture.TestSingleKeyword_Function; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestSingleKeyword_Interface(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSingleKeyword_Interface';
    lFixture.SetUp;
    try lFixture.TestSingleKeyword_Interface; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestSingleKeyword_Generic(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSingleKeyword_Generic';
    lFixture.SetUp;
    try lFixture.TestSingleKeyword_Generic; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestSingleKeyword_Specialize(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSingleKeyword_Specialize';
    lFixture.SetUp;
    try lFixture.TestSingleKeyword_Specialize; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestSingleKeyword_Dispinterface(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSingleKeyword_Dispinterface';
    lFixture.SetUp;
    try lFixture.TestSingleKeyword_Dispinterface; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestKeyword_CaseInsensitive(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestKeyword_CaseInsensitive';
    lFixture.SetUp;
    try lFixture.TestKeyword_CaseInsensitive; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestAllKeywordsRecognised(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestAllKeywordsRecognised';
    lFixture.SetUp;
    try lFixture.TestAllKeywordsRecognised; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestSimpleIdentifier(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSimpleIdentifier';
    lFixture.SetUp;
    try lFixture.TestSimpleIdentifier; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestIdentifier_WithUnderscore(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIdentifier_WithUnderscore';
    lFixture.SetUp;
    try lFixture.TestIdentifier_WithUnderscore; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestIdentifier_WithDigits(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIdentifier_WithDigits';
    lFixture.SetUp;
    try lFixture.TestIdentifier_WithDigits; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestIdentifier_NotKeyword(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIdentifier_NotKeyword';
    lFixture.SetUp;
    try lFixture.TestIdentifier_NotKeyword; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestNumber_Decimal(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNumber_Decimal';
    lFixture.SetUp;
    try lFixture.TestNumber_Decimal; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestNumber_Hex(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNumber_Hex';
    lFixture.SetUp;
    try lFixture.TestNumber_Hex; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestNumber_Binary(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNumber_Binary';
    lFixture.SetUp;
    try lFixture.TestNumber_Binary; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestNumber_Octal(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNumber_Octal';
    lFixture.SetUp;
    try lFixture.TestNumber_Octal; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestNumber_Float(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNumber_Float';
    lFixture.SetUp;
    try lFixture.TestNumber_Float; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestNumber_FloatExponent(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestNumber_FloatExponent';
    lFixture.SetUp;
    try lFixture.TestNumber_FloatExponent; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestString_Simple(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestString_Simple';
    lFixture.SetUp;
    try lFixture.TestString_Simple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestString_EmbeddedQuotes(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestString_EmbeddedQuotes';
    lFixture.SetUp;
    try lFixture.TestString_EmbeddedQuotes; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestString_Empty(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestString_Empty';
    lFixture.SetUp;
    try lFixture.TestString_Empty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestString_CharHash(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestString_CharHash';
    lFixture.SetUp;
    try lFixture.TestString_CharHash; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestString_CharCaret(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestString_CharCaret';
    lFixture.SetUp;
    try lFixture.TestString_CharCaret; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestString_Concatenated(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestString_Concatenated';
    lFixture.SetUp;
    try lFixture.TestString_Concatenated; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestComment_LineComment(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestComment_LineComment';
    lFixture.SetUp;
    try lFixture.TestComment_LineComment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestComment_BraceComment(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestComment_BraceComment';
    lFixture.SetUp;
    try lFixture.TestComment_BraceComment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestComment_ParenStarComment(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestComment_ParenStarComment';
    lFixture.SetUp;
    try lFixture.TestComment_ParenStarComment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestComment_MultiLine_Brace(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestComment_MultiLine_Brace';
    lFixture.SetUp;
    try lFixture.TestComment_MultiLine_Brace; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestComment_MultiLine_ParenStar(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestComment_MultiLine_ParenStar';
    lFixture.SetUp;
    try lFixture.TestComment_MultiLine_ParenStar; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestDirective_BraceStyle(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDirective_BraceStyle';
    lFixture.SetUp;
    try lFixture.TestDirective_BraceStyle; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestDirective_ParenStarStyle(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDirective_ParenStarStyle';
    lFixture.SetUp;
    try lFixture.TestDirective_ParenStarStyle; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestSymbol_SingleChars(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSymbol_SingleChars';
    lFixture.SetUp;
    try lFixture.TestSymbol_SingleChars; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestSymbol_Assign(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSymbol_Assign';
    lFixture.SetUp;
    try lFixture.TestSymbol_Assign; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestSymbol_NotEqual(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSymbol_NotEqual';
    lFixture.SetUp;
    try lFixture.TestSymbol_NotEqual; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestSymbol_LessEqual(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSymbol_LessEqual';
    lFixture.SetUp;
    try lFixture.TestSymbol_LessEqual; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestSymbol_GreaterEqual(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSymbol_GreaterEqual';
    lFixture.SetUp;
    try lFixture.TestSymbol_GreaterEqual; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestSymbol_DotDot(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSymbol_DotDot';
    lFixture.SetUp;
    try lFixture.TestSymbol_DotDot; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestSymbol_Power(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSymbol_Power';
    lFixture.SetUp;
    try lFixture.TestSymbol_Power; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestSymbol_AtAt(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSymbol_AtAt';
    lFixture.SetUp;
    try lFixture.TestSymbol_AtAt; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestSymbol_PlusAssign(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestSymbol_PlusAssign';
    lFixture.SetUp;
    try lFixture.TestSymbol_PlusAssign; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestLineColumn_FirstToken(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLineColumn_FirstToken';
    lFixture.SetUp;
    try lFixture.TestLineColumn_FirstToken; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestLineColumn_SecondLine(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLineColumn_SecondLine';
    lFixture.SetUp;
    try lFixture.TestLineColumn_SecondLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestLineColumn_MultipleTokensOnLine(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestLineColumn_MultipleTokensOnLine';
    lFixture.SetUp;
    try lFixture.TestLineColumn_MultipleTokensOnLine; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestIncomplete_UnterminatedString(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIncomplete_UnterminatedString';
    lFixture.SetUp;
    try lFixture.TestIncomplete_UnterminatedString; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestIncomplete_UnterminatedBraceComment(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIncomplete_UnterminatedBraceComment';
    lFixture.SetUp;
    try lFixture.TestIncomplete_UnterminatedBraceComment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestIncomplete_UnterminatedParenStarComment(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIncomplete_UnterminatedParenStarComment';
    lFixture.SetUp;
    try lFixture.TestIncomplete_UnterminatedParenStarComment; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestIncomplete_UnknownChar(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIncomplete_UnknownChar';
    lFixture.SetUp;
    try lFixture.TestIncomplete_UnknownChar; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestMixedSource_SimpleProgram(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMixedSource_SimpleProgram';
    lFixture.SetUp;
    try lFixture.TestMixedSource_SimpleProgram; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestMixedSource_UsesClause(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestMixedSource_UsesClause';
    lFixture.SetUp;
    try lFixture.TestMixedSource_UsesClause; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestIsKeyword_True(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIsKeyword_True';
    lFixture.SetUp;
    try lFixture.TestIsKeyword_True; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestIsKeyword_False(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIsKeyword_False';
    lFixture.SetUp;
    try lFixture.TestIsKeyword_False; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestIsKeyword_CaseInsensitive(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIsKeyword_CaseInsensitive';
    lFixture.SetUp;
    try lFixture.TestIsKeyword_CaseInsensitive; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestModifier_VisibilityTokens(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestModifier_VisibilityTokens';
    lFixture.SetUp;
    try lFixture.TestModifier_VisibilityTokens; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestModifier_MethodModifierTokens(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestModifier_MethodModifierTokens';
    lFixture.SetUp;
    try lFixture.TestModifier_MethodModifierTokens; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestModifier_CallingConventionTokens(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestModifier_CallingConventionTokens';
    lFixture.SetUp;
    try lFixture.TestModifier_CallingConventionTokens; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestIsModifier_True(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIsModifier_True';
    lFixture.SetUp;
    try lFixture.TestIsModifier_True; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestIsModifier_False(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIsModifier_False';
    lFixture.SetUp;
    try lFixture.TestIsModifier_False; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestIsModifier_CaseInsensitive(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIsModifier_CaseInsensitive';
    lFixture.SetUp;
    try lFixture.TestIsModifier_CaseInsensitive; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestModifier_NotKeyword(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestModifier_NotKeyword';
    lFixture.SetUp;
    try lFixture.TestModifier_NotKeyword; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestKeyword_NotModifier(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestKeyword_NotModifier';
    lFixture.SetUp;
    try lFixture.TestKeyword_NotModifier; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestModifier_PropertyDirectiveTokens(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestModifier_PropertyDirectiveTokens';
    lFixture.SetUp;
    try lFixture.TestModifier_PropertyDirectiveTokens; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestIsModifier_PropertyDirectives(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestIsModifier_PropertyDirectives';
    lFixture.SetUp;
    try lFixture.TestIsModifier_PropertyDirectives; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestKeywordTableIsSorted(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestKeywordTableIsSorted';
    lFixture.SetUp;
    try lFixture.TestKeywordTableIsSorted; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestModifierTableIsSorted(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestModifierTableIsSorted';
    lFixture.SetUp;
    try lFixture.TestModifierTableIsSorted; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestEveryKeywordIsFound(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEveryKeywordIsFound';
    lFixture.SetUp;
    try lFixture.TestEveryKeywordIsFound; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestEveryModifierIsFound(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestEveryModifierIsFound';
    lFixture.SetUp;
    try lFixture.TestEveryModifierIsFound; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestKeywordTableHasNoDuplicates(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestKeywordTableHasNoDuplicates';
    lFixture.SetUp;
    try lFixture.TestKeywordTableHasNoDuplicates; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestPascalTokeniserTestModifierTableHasNoDuplicates(AContext: TNXTestContext);
var lFixture: TTestPascalTokeniser;
begin
  lFixture:=TTestPascalTokeniser.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestModifierTableHasNoDuplicates';
    lFixture.SetUp;
    try lFixture.TestModifierTableHasNoDuplicates; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegisteridetestpascaltokeniserTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.pascal.tokeniser.TTestPascalTokeniser');
  lSuite.AddTest('TestEmptySource', @RunTTestPascalTokeniserTestEmptySource);
  lSuite.AddTest('TestSingleKeyword_Begin', @RunTTestPascalTokeniserTestSingleKeyword_Begin);
  lSuite.AddTest('TestSingleKeyword_End', @RunTTestPascalTokeniserTestSingleKeyword_End);
  lSuite.AddTest('TestSingleKeyword_Procedure', @RunTTestPascalTokeniserTestSingleKeyword_Procedure);
  lSuite.AddTest('TestSingleKeyword_Function', @RunTTestPascalTokeniserTestSingleKeyword_Function);
  lSuite.AddTest('TestSingleKeyword_Interface', @RunTTestPascalTokeniserTestSingleKeyword_Interface);
  lSuite.AddTest('TestSingleKeyword_Generic', @RunTTestPascalTokeniserTestSingleKeyword_Generic);
  lSuite.AddTest('TestSingleKeyword_Specialize', @RunTTestPascalTokeniserTestSingleKeyword_Specialize);
  lSuite.AddTest('TestSingleKeyword_Dispinterface', @RunTTestPascalTokeniserTestSingleKeyword_Dispinterface);
  lSuite.AddTest('TestKeyword_CaseInsensitive', @RunTTestPascalTokeniserTestKeyword_CaseInsensitive);
  lSuite.AddTest('TestAllKeywordsRecognised', @RunTTestPascalTokeniserTestAllKeywordsRecognised);
  lSuite.AddTest('TestSimpleIdentifier', @RunTTestPascalTokeniserTestSimpleIdentifier);
  lSuite.AddTest('TestIdentifier_WithUnderscore', @RunTTestPascalTokeniserTestIdentifier_WithUnderscore);
  lSuite.AddTest('TestIdentifier_WithDigits', @RunTTestPascalTokeniserTestIdentifier_WithDigits);
  lSuite.AddTest('TestIdentifier_NotKeyword', @RunTTestPascalTokeniserTestIdentifier_NotKeyword);
  lSuite.AddTest('TestNumber_Decimal', @RunTTestPascalTokeniserTestNumber_Decimal);
  lSuite.AddTest('TestNumber_Hex', @RunTTestPascalTokeniserTestNumber_Hex);
  lSuite.AddTest('TestNumber_Binary', @RunTTestPascalTokeniserTestNumber_Binary);
  lSuite.AddTest('TestNumber_Octal', @RunTTestPascalTokeniserTestNumber_Octal);
  lSuite.AddTest('TestNumber_Float', @RunTTestPascalTokeniserTestNumber_Float);
  lSuite.AddTest('TestNumber_FloatExponent', @RunTTestPascalTokeniserTestNumber_FloatExponent);
  lSuite.AddTest('TestString_Simple', @RunTTestPascalTokeniserTestString_Simple);
  lSuite.AddTest('TestString_EmbeddedQuotes', @RunTTestPascalTokeniserTestString_EmbeddedQuotes);
  lSuite.AddTest('TestString_Empty', @RunTTestPascalTokeniserTestString_Empty);
  lSuite.AddTest('TestString_CharHash', @RunTTestPascalTokeniserTestString_CharHash);
  lSuite.AddTest('TestString_CharCaret', @RunTTestPascalTokeniserTestString_CharCaret);
  lSuite.AddTest('TestString_Concatenated', @RunTTestPascalTokeniserTestString_Concatenated);
  lSuite.AddTest('TestComment_LineComment', @RunTTestPascalTokeniserTestComment_LineComment);
  lSuite.AddTest('TestComment_BraceComment', @RunTTestPascalTokeniserTestComment_BraceComment);
  lSuite.AddTest('TestComment_ParenStarComment', @RunTTestPascalTokeniserTestComment_ParenStarComment);
  lSuite.AddTest('TestComment_MultiLine_Brace', @RunTTestPascalTokeniserTestComment_MultiLine_Brace);
  lSuite.AddTest('TestComment_MultiLine_ParenStar', @RunTTestPascalTokeniserTestComment_MultiLine_ParenStar);
  lSuite.AddTest('TestDirective_BraceStyle', @RunTTestPascalTokeniserTestDirective_BraceStyle);
  lSuite.AddTest('TestDirective_ParenStarStyle', @RunTTestPascalTokeniserTestDirective_ParenStarStyle);
  lSuite.AddTest('TestSymbol_SingleChars', @RunTTestPascalTokeniserTestSymbol_SingleChars);
  lSuite.AddTest('TestSymbol_Assign', @RunTTestPascalTokeniserTestSymbol_Assign);
  lSuite.AddTest('TestSymbol_NotEqual', @RunTTestPascalTokeniserTestSymbol_NotEqual);
  lSuite.AddTest('TestSymbol_LessEqual', @RunTTestPascalTokeniserTestSymbol_LessEqual);
  lSuite.AddTest('TestSymbol_GreaterEqual', @RunTTestPascalTokeniserTestSymbol_GreaterEqual);
  lSuite.AddTest('TestSymbol_DotDot', @RunTTestPascalTokeniserTestSymbol_DotDot);
  lSuite.AddTest('TestSymbol_Power', @RunTTestPascalTokeniserTestSymbol_Power);
  lSuite.AddTest('TestSymbol_AtAt', @RunTTestPascalTokeniserTestSymbol_AtAt);
  lSuite.AddTest('TestSymbol_PlusAssign', @RunTTestPascalTokeniserTestSymbol_PlusAssign);
  lSuite.AddTest('TestLineColumn_FirstToken', @RunTTestPascalTokeniserTestLineColumn_FirstToken);
  lSuite.AddTest('TestLineColumn_SecondLine', @RunTTestPascalTokeniserTestLineColumn_SecondLine);
  lSuite.AddTest('TestLineColumn_MultipleTokensOnLine', @RunTTestPascalTokeniserTestLineColumn_MultipleTokensOnLine);
  lSuite.AddTest('TestIncomplete_UnterminatedString', @RunTTestPascalTokeniserTestIncomplete_UnterminatedString);
  lSuite.AddTest('TestIncomplete_UnterminatedBraceComment', @RunTTestPascalTokeniserTestIncomplete_UnterminatedBraceComment);
  lSuite.AddTest('TestIncomplete_UnterminatedParenStarComment', @RunTTestPascalTokeniserTestIncomplete_UnterminatedParenStarComment);
  lSuite.AddTest('TestIncomplete_UnknownChar', @RunTTestPascalTokeniserTestIncomplete_UnknownChar);
  lSuite.AddTest('TestMixedSource_SimpleProgram', @RunTTestPascalTokeniserTestMixedSource_SimpleProgram);
  lSuite.AddTest('TestMixedSource_UsesClause', @RunTTestPascalTokeniserTestMixedSource_UsesClause);
  lSuite.AddTest('TestIsKeyword_True', @RunTTestPascalTokeniserTestIsKeyword_True);
  lSuite.AddTest('TestIsKeyword_False', @RunTTestPascalTokeniserTestIsKeyword_False);
  lSuite.AddTest('TestIsKeyword_CaseInsensitive', @RunTTestPascalTokeniserTestIsKeyword_CaseInsensitive);
  lSuite.AddTest('TestModifier_VisibilityTokens', @RunTTestPascalTokeniserTestModifier_VisibilityTokens);
  lSuite.AddTest('TestModifier_MethodModifierTokens', @RunTTestPascalTokeniserTestModifier_MethodModifierTokens);
  lSuite.AddTest('TestModifier_CallingConventionTokens', @RunTTestPascalTokeniserTestModifier_CallingConventionTokens);
  lSuite.AddTest('TestIsModifier_True', @RunTTestPascalTokeniserTestIsModifier_True);
  lSuite.AddTest('TestIsModifier_False', @RunTTestPascalTokeniserTestIsModifier_False);
  lSuite.AddTest('TestIsModifier_CaseInsensitive', @RunTTestPascalTokeniserTestIsModifier_CaseInsensitive);
  lSuite.AddTest('TestModifier_NotKeyword', @RunTTestPascalTokeniserTestModifier_NotKeyword);
  lSuite.AddTest('TestKeyword_NotModifier', @RunTTestPascalTokeniserTestKeyword_NotModifier);
  lSuite.AddTest('TestModifier_PropertyDirectiveTokens', @RunTTestPascalTokeniserTestModifier_PropertyDirectiveTokens);
  lSuite.AddTest('TestIsModifier_PropertyDirectives', @RunTTestPascalTokeniserTestIsModifier_PropertyDirectives);
  lSuite.AddTest('TestKeywordTableIsSorted', @RunTTestPascalTokeniserTestKeywordTableIsSorted);
  lSuite.AddTest('TestModifierTableIsSorted', @RunTTestPascalTokeniserTestModifierTableIsSorted);
  lSuite.AddTest('TestEveryKeywordIsFound', @RunTTestPascalTokeniserTestEveryKeywordIsFound);
  lSuite.AddTest('TestEveryModifierIsFound', @RunTTestPascalTokeniserTestEveryModifierIsFound);
  lSuite.AddTest('TestKeywordTableHasNoDuplicates', @RunTTestPascalTokeniserTestKeywordTableHasNoDuplicates);
  lSuite.AddTest('TestModifierTableHasNoDuplicates', @RunTTestPascalTokeniserTestModifierTableHasNoDuplicates);
end;

end.

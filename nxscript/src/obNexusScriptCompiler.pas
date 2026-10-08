(*
  Copyright (c) 2026 Kevin Collins.
  
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  
  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.
  
  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNexusScriptCompiler;

{$mode delphi}{$H+}

interface

uses
  Classes,
  SysUtils,
  Generics.Collections,
  tpNexusScript,
  obNexusScriptModel;

type
  TNexusScriptCompiler = class
  private
    FSelectedTargets: TNexusScriptTargetSelection;
    FDiagnostics: TNexusScriptDiagnosticList;
    FSourceDocument: TNexusScriptSourceDocument;
    FCompiledDocument: TNexusScriptCompiledDocument;
    FImportedDefinitions: TNexusScriptCompiledDefinitionList;
    procedure AddError(const ACode, AMessageText: string;
      const ASourceRange: TNexusScriptRange);
    procedure CompileSource;
  public
    constructor Create(ASelectedTargets: TNexusScriptTargetSelection = nil);
    destructor Destroy; override;
    function CompileText(const ASourceName, AText: string;
      ACompiledAt: TDateTime = 0): Boolean;
    function CompileFile(const AFileName: string): Boolean;
    procedure ClearImports;
    procedure AddImportedDefinition(
      ADefinition: TNexusScriptCompiledDefinition);
    procedure AddImportedDocument(ADocument: TNexusScriptCompiledDocument);
    property Diagnostics: TNexusScriptDiagnosticList read FDiagnostics;
    property SourceDocument: TNexusScriptSourceDocument read FSourceDocument;
    property CompiledDocument: TNexusScriptCompiledDocument read FCompiledDocument;
  end;

implementation

uses obNexusScriptImport, DateUtils;

type
  TNexusScriptTokenKind = (
    nstWord, nstQuoted, nstLeftBrace, nstRightBrace, nstColon, nstSemicolon,
    nstLeftParenthesis, nstRightParenthesis, nstComma, nstLeftBracket,
    nstRightBracket, nstAt, nstDot, nstPlus, nstEndOfFile
  );

  TNexusScriptToken = record
    Kind: TNexusScriptTokenKind;
    Text: string;
    SourceRange: TNexusScriptRange;
  end;

  TNexusScriptTokenList = TList<TNexusScriptToken>;
  TNexusScriptTokenKindSet = set of TNexusScriptTokenKind;

  TNexusScriptParser = class
  private
    FCompiler: TNexusScriptCompiler;
    FSourceName: string;
    FTokens: TNexusScriptTokenList;
    FIndex: Integer;
    procedure Tokenize(const AText: string);
    function Current: TNexusScriptToken;
    function Match(AKind: TNexusScriptTokenKind): Boolean;
    function Require(AKind: TNexusScriptTokenKind;
      const ADescription: string): TNexusScriptToken;
    function ParsePath(out ARange: TNexusScriptRange;
      ARanges: TNexusScriptRangeList = nil): string;
    function ParseValue(const AStopKinds: TNexusScriptTokenKindSet): TNexusScriptSourceValue;
    function ParseDefinition(AParent: TNexusScriptSourceDefinition): TNexusScriptSourceDefinition;
    procedure ParseModule(ADocument: TNexusScriptSourceDocument);
    procedure ParseDialect(ADocument: TNexusScriptSourceDocument);
    procedure ParseInclude(ADocument: TNexusScriptSourceDocument);
    procedure ParseData(ADocument: TNexusScriptSourceDocument);
  public
    constructor Create(ACompiler: TNexusScriptCompiler;
      const ASourceName, AText: string);
    destructor Destroy; override;
    function Parse: TNexusScriptSourceDocument;
  end;

function NewPosition(AOffset, ALine, AColumn: Integer): TNexusScriptPosition;
begin
  Result.Offset := AOffset;
  Result.Line := ALine;
  Result.Column := AColumn;
end;

constructor TNexusScriptParser.Create(ACompiler: TNexusScriptCompiler;
  const ASourceName, AText: string);
begin
  inherited Create;
  FCompiler := ACompiler;
  FSourceName := ASourceName;
  FTokens := TNexusScriptTokenList.Create;
  Tokenize(AText);
end;

destructor TNexusScriptParser.Destroy;
begin
  FTokens.Free;
  inherited Destroy;
end;

procedure TNexusScriptParser.Tokenize(const AText: string);
var
  lIndex: Integer;
  lLine: Integer;
  lColumn: Integer;
  lStart: Integer;
  lStartLine: Integer;
  lStartColumn: Integer;
  lText: string;
  lToken: TNexusScriptToken;
  lCharacter: Char;

  procedure Advance;
  begin
    if lIndex <= Length(AText) then
    begin
      if AText[lIndex] = #10 then
      begin
        Inc(lLine);
        lColumn := 1;
      end
      else
        Inc(lColumn);
      Inc(lIndex);
    end;
  end;

  procedure Emit(AKind: TNexusScriptTokenKind; const AValue: string);
  begin
    lToken.Kind := AKind;
    lToken.Text := AValue;
    lToken.SourceRange.SourceName := FSourceName;
    lToken.SourceRange.StartPosition := NewPosition(lStart - 1,
      lStartLine, lStartColumn);
    lToken.SourceRange.EndPosition := NewPosition(lIndex - 1,
      lLine, lColumn);
    FTokens.Add(lToken);
  end;

begin
  lIndex := 1;
  lLine := 1;
  lColumn := 1;
  while lIndex <= Length(AText) do
  begin
    if AText[lIndex] <= ' ' then
    begin
      Advance;
      Continue;
    end;
    if (AText[lIndex] = '/') and (lIndex < Length(AText)) and
      (AText[lIndex + 1] = '/') then
    begin
      while (lIndex <= Length(AText)) and
        not (AText[lIndex] in [#10, #13]) do
        Advance;
      Continue;
    end;
    if (AText[lIndex] = '/') and (lIndex < Length(AText)) and
      (AText[lIndex + 1] = '*') then
    begin
      lStart := lIndex;
      lStartLine := lLine;
      lStartColumn := lColumn;
      Advance;
      Advance;
      while (lIndex <= Length(AText)) and not ((AText[lIndex] = '*') and
        (lIndex < Length(AText)) and (AText[lIndex + 1] = '/')) do
        Advance;
      if lIndex > Length(AText) then
      begin
        lToken.SourceRange.SourceName := FSourceName;
        lToken.SourceRange.StartPosition := NewPosition(lStart - 1,
          lStartLine, lStartColumn);
        lToken.SourceRange.EndPosition := NewPosition(lIndex - 1,
          lLine, lColumn);
        FCompiler.AddError('NXS1002', 'Unterminated block comment',
          lToken.SourceRange);
        Break;
      end;
      Advance;
      Advance;
      Continue;
    end;

    lStart := lIndex;
    lStartLine := lLine;
    lStartColumn := lColumn;
    case AText[lIndex] of
      '{': begin Advance; Emit(nstLeftBrace, '{'); end;
      '}': begin Advance; Emit(nstRightBrace, '}'); end;
      ':': begin Advance; Emit(nstColon, ':'); end;
      ';': begin Advance; Emit(nstSemicolon, ';'); end;
      '(': begin Advance; Emit(nstLeftParenthesis, '('); end;
      ')': begin Advance; Emit(nstRightParenthesis, ')'); end;
      ',': begin Advance; Emit(nstComma, ','); end;
      '[': begin Advance; Emit(nstLeftBracket, '['); end;
      ']': begin Advance; Emit(nstRightBracket, ']'); end;
      '@': begin Advance; Emit(nstAt, '@'); end;
      '.': begin Advance; Emit(nstDot, '.'); end;
      '+': begin Advance; Emit(nstPlus, '+'); end;
      '"':
        begin
          Advance;
          lText := '';
          while (lIndex <= Length(AText)) and (AText[lIndex] <> '"') do
          begin
            if AText[lIndex] = '^' then
            begin
              Advance;
              if lIndex > Length(AText) then
                Break;
              lCharacter := AText[lIndex];
              case lCharacter of
                '^': lText := lText + '^';
                '"': lText := lText + '"';
                'n': lText := lText + #10;
                'r': lText := lText + #13;
                't': lText := lText + #9;
              else
                begin
                  lToken.SourceRange.SourceName := FSourceName;
                  lToken.SourceRange.StartPosition := NewPosition(lIndex - 1,
                    lLine, lColumn);
                  lToken.SourceRange.EndPosition := lToken.SourceRange.StartPosition;
                  FCompiler.AddError('NXS1003', 'Invalid string escape',
                    lToken.SourceRange);
                  lText := lText + lCharacter;
                end;
              end;
              Advance;
            end
            else
            begin
              lText := lText + AText[lIndex];
              Advance;
            end;
          end;
          if lIndex > Length(AText) then
            FCompiler.AddError('NXS1001', 'Unterminated quoted text',
              lToken.SourceRange)
          else
            Advance;
          Emit(nstQuoted, lText);
        end;
    else
      lText := '';
      while (lIndex <= Length(AText)) and not (AText[lIndex] <= ' ') and
        not (AText[lIndex] in ['{', '}', ':', ';', '(', ')', ',', '[', ']',
          '@', '.', '+', '"']) do
      begin
        lText := lText + AText[lIndex];
        Advance;
      end;
      Emit(nstWord, lText);
    end;
  end;
  lStart := lIndex;
  lStartLine := lLine;
  lStartColumn := lColumn;
  Emit(nstEndOfFile, '');
end;

function TNexusScriptParser.Current: TNexusScriptToken;
begin
  Result := FTokens[FIndex];
end;

function TNexusScriptParser.Match(AKind: TNexusScriptTokenKind): Boolean;
begin
  Result := Current.Kind = AKind;
  if Result then
    Inc(FIndex);
end;

function TNexusScriptParser.Require(AKind: TNexusScriptTokenKind;
  const ADescription: string): TNexusScriptToken;
begin
  Result := Current;
  if Result.Kind = AKind then
    Inc(FIndex)
  else
  begin
    FCompiler.AddError('NXS2001', 'Expected ' + ADescription,
      Result.SourceRange);
    if Result.Kind <> nstEndOfFile then
      Inc(FIndex);
  end;
end;

function TNexusScriptParser.ParsePath(out ARange: TNexusScriptRange;
  ARanges: TNexusScriptRangeList): string;
var
  lToken: TNexusScriptToken;
begin
  lToken := Require(nstWord, 'name');
  Result := lToken.Text;
  ARange := lToken.SourceRange;
  if ARanges <> nil then
    ARanges.Add(lToken.SourceRange);
  while Match(nstDot) do
  begin
    lToken := Require(nstWord, 'name');
    Result := Result + '.' + lToken.Text;
    ARange.EndPosition := lToken.SourceRange.EndPosition;
    if ARanges <> nil then
      ARanges.Add(lToken.SourceRange);
  end;
end;

function TNexusScriptParser.ParseValue(
  const AStopKinds: TNexusScriptTokenKindSet): TNexusScriptSourceValue;
var
  lPart: TNexusScriptSourceValue;
  lText: string;
  lEntry: TNexusScriptSourceValue;
  lEntryName: string;
  lEntryNameRange: TNexusScriptRange;
  lResultRange: TNexusScriptRange;

  function StartsInlineDefinition: Boolean;
  var
    lTokenIndex: Integer;
  begin
    Result := False;
    if (Current.Kind <> nstWord) or
      (FIndex + 2 >= FTokens.Count) or
      (FTokens[FIndex + 1].Kind <> nstWord) then
      Exit;
    lTokenIndex := FIndex + 2;
    if FTokens[lTokenIndex].Kind = nstLeftParenthesis then
    begin
      Inc(lTokenIndex);
      while (lTokenIndex < FTokens.Count) and
        (FTokens[lTokenIndex].Kind <> nstRightParenthesis) do
        Inc(lTokenIndex);
      if lTokenIndex >= FTokens.Count then
        Exit;
      Inc(lTokenIndex);
    end;
    while (lTokenIndex + 1 < FTokens.Count) and
      (FTokens[lTokenIndex].Kind in [nstWord, nstQuoted]) and
      (FTokens[lTokenIndex + 1].Kind = nstLeftBracket) do
    begin
      Inc(lTokenIndex, 2);
      while (lTokenIndex < FTokens.Count) and
        (FTokens[lTokenIndex].Kind <> nstRightBracket) do
        Inc(lTokenIndex);
      if lTokenIndex >= FTokens.Count then
        Exit;
      Inc(lTokenIndex);
    end;
    Result := (lTokenIndex < FTokens.Count) and
      (FTokens[lTokenIndex].Kind = nstLeftBrace);
  end;

  function ParsePart: TNexusScriptSourceValue;
  var
    lRange: TNexusScriptRange;
    lToken: TNexusScriptToken;
  begin
    lRange := Current.SourceRange;
    if Match(nstAt) then
    begin
      Result := TNexusScriptSourceValue.Create(nsvReference, lRange);
      Result.Text := ParsePath(lRange, Result.ReferenceRanges);
      lRange.StartPosition := Result.SourceRange.StartPosition;
      Result.SourceRange := lRange;
    end
    else if Current.Kind = nstQuoted then
    begin
      Result := TNexusScriptSourceValue.Create(nsvText, lRange);
      Result.Text := Current.Text;
      Inc(FIndex);
    end
    else
    begin
      Result := TNexusScriptSourceValue.Create(nsvText, lRange);
      lText := '';
      while not (Current.Kind in AStopKinds + [nstPlus, nstComma,
        nstRightBracket, nstEndOfFile]) do
      begin
        lToken := Current;
        if lText <> '' then
          lText := lText + ' ';
        lText := lText + Current.Text;
        Inc(FIndex);
        lRange.EndPosition := lToken.SourceRange.EndPosition;
      end;
      Result.Text := Trim(lText);
      Result.SourceRange := lRange;
    end;
  end;

begin
  if Match(nstLeftBracket) then
  begin
    Result := TNexusScriptSourceValue.Create(nsvArray,
      FTokens[FIndex - 1].SourceRange);
    while not Match(nstRightBracket) and
      (Current.Kind <> nstEndOfFile) do
    begin
      lEntryName := '';
      lEntryNameRange := Default(TNexusScriptRange);
      if (Current.Kind = nstWord) and (FIndex + 1 < FTokens.Count) and
        (FTokens[FIndex + 1].Kind = nstColon) then
      begin
        lEntryName := Current.Text;
        lEntryNameRange := Current.SourceRange;
        Inc(FIndex, 2);
      end;
      if StartsInlineDefinition then
      begin
        lEntry := TNexusScriptSourceValue.Create(nsvDefinition,
          Current.SourceRange);
        lEntry.InlineDefinition := ParseDefinition(nil);
      end
      else
        lEntry := ParseValue([nstComma, nstRightBracket]);
      lEntry.EntryName := lEntryName;
      lEntry.EntryNameRange := lEntryNameRange;
      Result.Items.Add(lEntry);
      if not Match(nstComma) then
      begin
        Require(nstRightBracket, ']');
        Break;
      end;
    end;
    if (FIndex > 0) and (FTokens[FIndex - 1].Kind = nstRightBracket) then
    begin
      lResultRange := Result.SourceRange;
      lResultRange.EndPosition :=
        FTokens[FIndex - 1].SourceRange.EndPosition;
      Result.SourceRange := lResultRange;
    end;
    Exit;
  end;

  lPart := ParsePart;
  if Current.Kind <> nstPlus then
    Exit(lPart);
  Result := TNexusScriptSourceValue.Create(nsvTextComposition,
    lPart.SourceRange);
  Result.Items.Add(lPart);
  while Match(nstPlus) do
    Result.Items.Add(ParsePart);
  lResultRange := Result.SourceRange;
  lResultRange.EndPosition :=
    Result.Items[Result.Items.Count - 1].SourceRange.EndPosition;
  Result.SourceRange := lResultRange;
end;

function TNexusScriptParser.ParseDefinition(
  AParent: TNexusScriptSourceDefinition): TNexusScriptSourceDefinition;
var
  lKindToken: TNexusScriptToken;
  lNameToken: TNexusScriptToken;
  lTargetNameToken: TNexusScriptToken;
  lTargetToken: TNexusScriptToken;
  lTargetEndToken: TNexusScriptToken;
  lMemberToken: TNexusScriptToken;
  lEndToken: TNexusScriptToken;
  lSourceRange: TNexusScriptRange;
  lValue: TNexusScriptSourceValue;
  lChild: TNexusScriptSourceDefinition;
  lTarget: TNexusScriptTarget;
  lDuplicateTarget: Boolean;
  lSelectorRange: TNexusScriptRange;
begin
  lKindToken := Require(nstWord, 'definition kind');
  lNameToken := Require(nstWord, 'definition name');
  Result := TNexusScriptSourceDefinition.Create(lKindToken.Text,
    lNameToken.Text, lKindToken.SourceRange);
  Result.KindRange := lKindToken.SourceRange;
  Result.NameRange := lNameToken.SourceRange;
  Result.Parent := AParent;
  if Match(nstLeftParenthesis) then
  begin
    while not Match(nstRightParenthesis) and
      (Current.Kind <> nstEndOfFile) do
    begin
      Result.CompositionSelectors.Add(ParsePath(lSelectorRange));
      Result.CompositionSelectorRanges.Add(lSelectorRange);
      if not Match(nstComma) then
      begin
        Require(nstRightParenthesis, ')');
        Break;
      end;
    end;
  end;
  while (Current.Kind in [nstWord, nstQuoted]) and
    (FIndex + 1 < FTokens.Count) and
    (FTokens[FIndex + 1].Kind = nstLeftBracket) do
  begin
    lTargetNameToken := Current;
    Inc(FIndex, 2);
    lTargetEndToken.Kind := nstEndOfFile;
    lTarget := TNexusScriptTarget.Create(lTargetNameToken.Text,
      lTargetNameToken.SourceRange);
    lTarget.NameRange := lTargetNameToken.SourceRange;
    lDuplicateTarget := Result.Targets.Find(lTarget.Name) <> nil;
    if lDuplicateTarget then
      FCompiler.AddError('NXS3007', 'Duplicate definition Target kind ' +
        lTarget.Name, lTargetNameToken.SourceRange);
    if Match(nstRightBracket) then
    begin
      lTargetEndToken := FTokens[FIndex - 1];
      FCompiler.AddError('NXS3005', 'Definition Target clause cannot be empty',
        lTargetEndToken.SourceRange);
    end
    else
    begin
      while Current.Kind <> nstEndOfFile do
      begin
        lTargetToken := Current;
        if not (lTargetToken.Kind in [nstWord, nstQuoted]) then
        begin
          FCompiler.AddError('NXS2001', 'Expected definition Target',
            lTargetToken.SourceRange);
          while not (Current.Kind in [nstRightBracket, nstLeftBrace,
            nstEndOfFile]) do
            Inc(FIndex);
          Match(nstRightBracket);
          Break;
        end;
        Inc(FIndex);
        if lTarget.Values.IndexOf(lTargetToken.Text) >= 0 then
          FCompiler.AddError('NXS3006', 'Duplicate definition Target ' +
            lTargetToken.Text, lTargetToken.SourceRange)
        else
        begin
          lTarget.Values.Add(lTargetToken.Text);
          lTarget.ValueRanges.Add(lTargetToken.SourceRange);
        end;
        if Match(nstRightBracket) then
        begin
          lTargetEndToken := FTokens[FIndex - 1];
          Break;
        end;
        if not Match(nstComma) then
        begin
          FCompiler.AddError('NXS2001', 'Expected comma or ]',
            Current.SourceRange);
          while not (Current.Kind in [nstRightBracket, nstLeftBrace,
            nstEndOfFile]) do
            Inc(FIndex);
          Match(nstRightBracket);
          Break;
        end;
        if Current.Kind = nstRightBracket then
        begin
          FCompiler.AddError('NXS2001', 'Expected definition Target',
            Current.SourceRange);
          Inc(FIndex);
          Break;
        end;
      end;
    end;
    if lTargetEndToken.Kind = nstRightBracket then
    begin
      lSourceRange := lTarget.SourceRange;
      lSourceRange.EndPosition := lTargetEndToken.SourceRange.EndPosition;
      lTarget.SourceRange := lSourceRange;
    end;
    if lDuplicateTarget then
      lTarget.Free
    else
      Result.Targets.Add(lTarget);
  end;
  Require(nstLeftBrace, '{');
  while (Current.Kind <> nstRightBrace) and
    (Current.Kind <> nstEndOfFile) do
  begin
    lMemberToken := Require(nstWord, 'member name');
    if Match(nstColon) then
    begin
      lValue := ParseValue([nstSemicolon]);
      lEndToken := Require(nstSemicolon, ';');
      if Result.FindProperty(lMemberToken.Text) <> nil then
      begin
        FCompiler.AddError('NXS3001', 'Duplicate member ' +
          lMemberToken.Text, lMemberToken.SourceRange);
        lValue.Free;
      end
      else
      begin
        Result.Properties.Add(TNexusScriptSourceProperty.Create(
          lMemberToken.Text, lValue, lMemberToken.SourceRange));
        Result.Properties[Result.Properties.Count - 1].NameRange :=
          lMemberToken.SourceRange;
        Result.Properties[Result.Properties.Count - 1].ValueRange :=
          lValue.SourceRange;
        lSourceRange := lMemberToken.SourceRange;
        lSourceRange.EndPosition := lEndToken.SourceRange.EndPosition;
        Result.Properties[Result.Properties.Count - 1].SourceRange :=
          lSourceRange;
      end;
    end
    else
    begin
      Dec(FIndex);
      lChild := ParseDefinition(Result);
      Result.Children.Add(lChild);
    end;
  end;
  lEndToken := Require(nstRightBrace, '}');
  lSourceRange := Result.SourceRange;
  lSourceRange.EndPosition := lEndToken.SourceRange.EndPosition;
  Result.SourceRange := lSourceRange;
  Result.BodyEndRange := lEndToken.SourceRange;
end;

procedure TNexusScriptParser.ParseModule(ADocument: TNexusScriptSourceDocument);
var
  lModule: TNexusScriptSourceModule;
  lPieces: TStringList;
  lRange: TNexusScriptRange;
  lJoinPath: Boolean;
  lFirstPieceQuoted: Boolean;
  lPieceRanges: TNexusScriptRangeList;
  lTokenRange: TNexusScriptRange;
begin
  lRange := Current.SourceRange;
  Inc(FIndex);
  lModule := TNexusScriptSourceModule.Create;
  lPieces := TStringList.Create;
  lPieceRanges := TNexusScriptRangeList.Create;
  try
    lModule.SourceRange := lRange;
    lJoinPath := False;
    lFirstPieceQuoted := False;
    while not (Current.Kind in [nstSemicolon, nstEndOfFile]) do
    begin
      if Current.Kind = nstDot then
      begin
        if lPieces.Count > 0 then
          lPieces[lPieces.Count - 1] := lPieces[lPieces.Count - 1] + '.';
        lJoinPath := True;
      end
      else if (lPieces.Count > 0) and lJoinPath then
      begin
        lPieces[lPieces.Count - 1] := lPieces[lPieces.Count - 1] + Current.Text;
        lTokenRange := lPieceRanges[lPieceRanges.Count - 1];
        lTokenRange.EndPosition := Current.SourceRange.EndPosition;
        lPieceRanges[lPieceRanges.Count - 1] := lTokenRange;
        lJoinPath := False;
      end
      else
      begin
        if lPieces.Count = 0 then
          lFirstPieceQuoted := Current.Kind = nstQuoted;
        lPieces.Add(Current.Text);
        lPieceRanges.Add(Current.SourceRange);
      end;
      Inc(FIndex);
    end;
    Require(nstSemicolon, ';');
    if (lPieces.Count > 0) and not lFirstPieceQuoted and
      SameText(lPieces[0], 'recursive') then
    begin
      if lPieces.Count = 2 then
      begin
        lModule.Recursive := True;
        lModule.Path := lPieces[1];
        lModule.PathRange := lPieceRanges[1];
      end
      else
        FCompiler.AddError('NXS2002', 'Invalid module declaration', lRange);
    end
    else if lPieces.Count = 1 then
    begin
      lModule.Path := lPieces[0];
      lModule.PathRange := lPieceRanges[0];
    end
    else if lPieces.Count = 2 then
    begin
      lModule.RootSelector := lPieces[0];
      lModule.Path := lPieces[1];
      lModule.RootSelectorRange := lPieceRanges[0];
      lModule.PathRange := lPieceRanges[1];
      if (Pos('*', lModule.Path) > 0) or (Pos('?', lModule.Path) > 0) then
        FCompiler.AddError('NXS2002', 'Invalid module declaration', lRange);
    end
    else
      FCompiler.AddError('NXS2002', 'Invalid module declaration', lRange);
    ADocument.Modules.Add(lModule);
    lModule := nil;
  finally
    lPieceRanges.Free;
    lPieces.Free;
    lModule.Free;
  end;
end;

procedure TNexusScriptParser.ParseDialect(
  ADocument: TNexusScriptSourceDocument);
var
  lDialect: TNexusScriptSourceDialect;
  lPieces: TStringList;
  lPieceRanges: TNexusScriptRangeList;
  lRange: TNexusScriptRange;
  lTokenRange: TNexusScriptRange;
begin
  lRange := Current.SourceRange;
  Inc(FIndex);
  lDialect := TNexusScriptSourceDialect.Create;
  lPieces := TStringList.Create;
  lPieceRanges := TNexusScriptRangeList.Create;
  try
    lDialect.SourceRange := lRange;
    while not (Current.Kind in [nstSemicolon, nstEndOfFile]) do
    begin
      if Current.Kind = nstDot then
      begin
        if lPieces.Count > 0 then
          lPieces[lPieces.Count - 1] := lPieces[lPieces.Count - 1] + '.';
      end
      else if (lPieces.Count > 0) and
        (lPieces[lPieces.Count - 1][Length(lPieces[lPieces.Count - 1])] = '.') then
      begin
        lPieces[lPieces.Count - 1] := lPieces[lPieces.Count - 1] +
          Current.Text;
        lTokenRange := lPieceRanges[lPieceRanges.Count - 1];
        lTokenRange.EndPosition := Current.SourceRange.EndPosition;
        lPieceRanges[lPieceRanges.Count - 1] := lTokenRange;
      end
      else
      begin
        lPieces.Add(Current.Text);
        lPieceRanges.Add(Current.SourceRange);
      end;
      Inc(FIndex);
    end;
    Require(nstSemicolon, ';');
    if lPieces.Count <> 1 then
      FCompiler.AddError('NXS2011', 'Invalid dialect declaration', lRange)
    else if ADocument.Dialect <> nil then
      FCompiler.AddError('NXS2012', 'Duplicate dialect declaration', lRange)
    else
    begin
      lDialect.Path := lPieces[0];
      lDialect.PathRange := lPieceRanges[0];
      ADocument.Dialect := lDialect;
      lDialect := nil;
    end;
  finally
    lPieceRanges.Free;
    lPieces.Free;
    lDialect.Free;
  end;
end;

procedure TNexusScriptParser.ParseInclude(
  ADocument: TNexusScriptSourceDocument);
var
  lInclude: TNexusScriptSourceInclude;
  lPieces: TStringList;
  lRange: TNexusScriptRange;
  lJoinPath: Boolean;
  lFirstPieceQuoted: Boolean;
  lPieceRanges: TNexusScriptRangeList;
  lTokenRange: TNexusScriptRange;
begin
  lRange := Current.SourceRange;
  Inc(FIndex);
  lInclude := TNexusScriptSourceInclude.Create;
  lPieces := TStringList.Create;
  lPieceRanges := TNexusScriptRangeList.Create;
  try
    lInclude.SourceRange := lRange;
    lJoinPath := False;
    lFirstPieceQuoted := False;
    while not (Current.Kind in [nstSemicolon, nstEndOfFile]) do
    begin
      if Current.Kind = nstDot then
      begin
        if lPieces.Count > 0 then
          lPieces[lPieces.Count - 1] := lPieces[lPieces.Count - 1] + '.';
        lJoinPath := True;
      end
      else if (lPieces.Count > 0) and lJoinPath then
      begin
        lPieces[lPieces.Count - 1] := lPieces[lPieces.Count - 1] + Current.Text;
        lTokenRange := lPieceRanges[lPieceRanges.Count - 1];
        lTokenRange.EndPosition := Current.SourceRange.EndPosition;
        lPieceRanges[lPieceRanges.Count - 1] := lTokenRange;
        lJoinPath := False;
      end
      else
      begin
        if lPieces.Count = 0 then
          lFirstPieceQuoted := Current.Kind = nstQuoted;
        lPieces.Add(Current.Text);
        lPieceRanges.Add(Current.SourceRange);
      end;
      Inc(FIndex);
    end;
    Require(nstSemicolon, ';');
    if (lPieces.Count > 0) and not lFirstPieceQuoted and
      SameText(lPieces[0], 'recursive') then
    begin
      if lPieces.Count = 2 then
      begin
        lInclude.Recursive := True;
        lInclude.Path := lPieces[1];
        lInclude.PathRange := lPieceRanges[1];
      end
      else
        FCompiler.AddError('NXS2015', 'Invalid include declaration', lRange);
      ADocument.Includes.Add(lInclude);
      lInclude := nil;
    end
    else if lPieces.Count <> 1 then
      FCompiler.AddError('NXS2015', 'Invalid include declaration', lRange)
    else
    begin
      lInclude.Path := lPieces[0];
      lInclude.PathRange := lPieceRanges[0];
      ADocument.Includes.Add(lInclude);
      lInclude := nil;
    end;
  finally
    lPieceRanges.Free;
    lPieces.Free;
    lInclude.Free;
  end;
end;

procedure TNexusScriptParser.ParseData(
  ADocument: TNexusScriptSourceDocument);
var
  lDataSource: TNexusScriptSourceData;
  lName: TNexusScriptToken;
  lPath: TNexusScriptToken;
  lRange: TNexusScriptRange;
begin
  lRange := Current.SourceRange;
  Inc(FIndex);
  lName := Require(nstWord, 'data source name');
  lPath := Require(nstQuoted, 'quoted data source path');
  Require(nstSemicolon, ';');
  if (lName.Kind <> nstWord) or (lPath.Kind <> nstQuoted) then
    Exit;
  if ADocument.FindDataSource(lName.Text) <> nil then
  begin
    FCompiler.AddError('NXS2018', 'Duplicate data source ' + lName.Text,
      lRange);
    Exit;
  end;
  lDataSource := TNexusScriptSourceData.Create;
  lDataSource.Name := lName.Text;
  lDataSource.Path := lPath.Text;
  lDataSource.SourceRange := lRange;
  ADocument.DataSources.Add(lDataSource);
end;

function TNexusScriptParser.Parse: TNexusScriptSourceDocument;
var
  lDefinition: TNexusScriptSourceDefinition;
  lHasDefinition: Boolean;
begin
  Result := TNexusScriptSourceDocument.Create(FSourceName);
  lHasDefinition := False;
  while Current.Kind <> nstEndOfFile do
  begin
    if (Current.Kind = nstWord) and SameText(Current.Text, 'module') then
    begin
      if lHasDefinition then
        FCompiler.AddError('NXS2013',
          'Module declaration must precede definitions', Current.SourceRange);
      ParseModule(Result);
      Continue;
    end;
    if (Current.Kind = nstWord) and SameText(Current.Text, 'dialect') then
    begin
      if lHasDefinition then
        FCompiler.AddError('NXS2014',
          'Dialect declaration must precede definitions', Current.SourceRange);
      ParseDialect(Result);
      Continue;
    end;
    if (Current.Kind = nstWord) and SameText(Current.Text, 'include') then
    begin
      if lHasDefinition then
        FCompiler.AddError('NXS2016',
          'Include declaration must precede definitions', Current.SourceRange);
      ParseInclude(Result);
      Continue;
    end;
    if (Current.Kind = nstWord) and SameText(Current.Text, 'data') then
    begin
      if lHasDefinition then
        FCompiler.AddError('NXS2017',
          'Data declaration must precede definitions', Current.SourceRange);
      ParseData(Result);
      Continue;
    end;
    lHasDefinition := True;
    lDefinition := ParseDefinition(nil);
    Result.Definitions.Add(lDefinition);
  end;
end;

constructor TNexusScriptCompiler.Create(
  ASelectedTargets: TNexusScriptTargetSelection);
begin
  inherited Create;
  FSelectedTargets := TNexusScriptTargetSelection.Create;
  FSelectedTargets.Assign(ASelectedTargets);
  FDiagnostics := TNexusScriptDiagnosticList.Create(True);
  FImportedDefinitions := TNexusScriptCompiledDefinitionList.Create(True);
end;

destructor TNexusScriptCompiler.Destroy;
begin
  FCompiledDocument.Free;
  FSourceDocument.Free;
  FImportedDefinitions.Free;
  FDiagnostics.Free;
  FSelectedTargets.Free;
  inherited Destroy;
end;

procedure TNexusScriptCompiler.AddError(const ACode, AMessageText: string;
  const ASourceRange: TNexusScriptRange);
begin
  FDiagnostics.Add(TNexusScriptDiagnostic.Create(ACode, AMessageText,
    ASourceRange));
end;

function DefinitionAppliesToTargets(ASource: TNexusScriptSourceDefinition;
  ASelectedTargets: TNexusScriptTargetSelection): Boolean;
var
  lIndex: Integer;
  lSelectedTarget: TNexusScriptSelectedTarget;
  lTarget: TNexusScriptTarget;
begin
  Result := True;
  for lIndex := 0 to ASelectedTargets.Count - 1 do
  begin
    lSelectedTarget := ASelectedTargets[lIndex];
    lTarget := ASource.Targets.Find(lSelectedTarget.Name);
    if (lTarget <> nil) and not lTarget.HasValue(lSelectedTarget.Value) then
      Exit(False);
  end;
end;

function CopyDefinition(ACompiler: TNexusScriptCompiler;
  ASource: TNexusScriptSourceDefinition;
  AParent: TNexusScriptCompiledDefinition;
  ASelectedTargets: TNexusScriptTargetSelection):
  TNexusScriptCompiledDefinition; forward;

function CopyValue(ACompiler: TNexusScriptCompiler;
  AValue: TNexusScriptSourceValue;
  ASelectedTargets: TNexusScriptTargetSelection): TNexusScriptCompiledValue;
var
  lItem: TNexusScriptSourceValue;
  lCompiledItem: TNexusScriptCompiledValue;
begin
  if (AValue.InlineDefinition <> nil) and
    not DefinitionAppliesToTargets(AValue.InlineDefinition,
      ASelectedTargets) then
    Exit(nil);
  Result := TNexusScriptCompiledValue.Create(AValue.Kind, AValue.SourceRange);
  Result.SourceText := AValue.Text;
  Result.ReferenceRanges.AddRange(AValue.ReferenceRanges);
  Result.EntryName := AValue.EntryName;
  Result.InlineSourceDefinition := AValue.InlineDefinition;
  if AValue.InlineDefinition <> nil then
  begin
    Result.OriginalDefinitionName := AValue.InlineDefinition.Name;
    Result.StructuralDefinition := CopyDefinition(ACompiler,
      AValue.InlineDefinition, nil, ASelectedTargets);
  end;
  for lItem in AValue.Items do
  begin
    lCompiledItem := CopyValue(ACompiler, lItem, ASelectedTargets);
    if lCompiledItem <> nil then
      Result.Items.Add(lCompiledItem);
  end;
end;

function CopyDefinition(ACompiler: TNexusScriptCompiler;
  ASource: TNexusScriptSourceDefinition;
  AParent: TNexusScriptCompiledDefinition;
  ASelectedTargets: TNexusScriptTargetSelection):
  TNexusScriptCompiledDefinition;
var
  lProperty: TNexusScriptSourceProperty;
  lChild: TNexusScriptSourceDefinition;
  lCompiledValue: TNexusScriptCompiledValue;
  lCompiledChild: TNexusScriptCompiledDefinition;
begin
  if not DefinitionAppliesToTargets(ASource, ASelectedTargets) then
    Exit(nil);
  Result := TNexusScriptCompiledDefinition.Create(ASource.Kind, ASource.Name,
    ASource.SourceRange);
  Result.Parent := AParent;
  Result.SourceDefinition := ASource;
  Result.Targets.Assign(ASource.Targets);
  for lProperty in ASource.Properties do
  begin
    lCompiledValue := CopyValue(ACompiler, lProperty.Value, ASelectedTargets);
    if lCompiledValue <> nil then
      Result.Properties.Add(TNexusScriptCompiledProperty.Create(lProperty.Name,
        lCompiledValue, lProperty.SourceRange));
  end;
  for lChild in ASource.Children do
  begin
    lCompiledChild := CopyDefinition(ACompiler, lChild, Result,
      ASelectedTargets);
    if lCompiledChild <> nil then
    begin
      if (Result.FindProperty(lCompiledChild.Name) <> nil) or
        (Result.FindChild(lCompiledChild.Name) <> nil) then
      begin
        ACompiler.AddError('NXS3001', 'Duplicate member ' +
          lCompiledChild.Name, lCompiledChild.SourceRange);
        lCompiledChild.Free;
      end
      else
        Result.Children.Add(lCompiledChild);
    end;
  end;
end;

function CloneDefinition(ASource: TNexusScriptCompiledDefinition;
  AParent: TNexusScriptCompiledDefinition): TNexusScriptCompiledDefinition; forward;

function CloneDefinitionForRebinding(ASource: TNexusScriptCompiledDefinition;
  AParent: TNexusScriptCompiledDefinition;
  ADetachSource: Boolean = False): TNexusScriptCompiledDefinition; forward;

procedure CopyContributorRanges(ASource,
  ADestination: TNexusScriptCompiledProperty);
begin
  ADestination.ContributorRanges.Clear;
  ADestination.ContributorRanges.AddRange(ASource.ContributorRanges);
end;

function CloneValue(AValue: TNexusScriptCompiledValue): TNexusScriptCompiledValue;
var
  lItem: TNexusScriptCompiledValue;
  lContributor: TNexusScriptCompiledValue;
begin
  Result := TNexusScriptCompiledValue.Create(AValue.Kind, AValue.SourceRange);
  Result.SourceText := AValue.SourceText;
  Result.ImportBinding := AValue.ImportBinding;
  Result.ReferenceRanges.AddRange(AValue.ReferenceRanges);
  Result.EntryName := AValue.EntryName;
  Result.EffectiveName := AValue.EffectiveName;
  Result.OriginalDefinitionName := AValue.OriginalDefinitionName;
  Result.InlineSourceDefinition := AValue.InlineSourceDefinition;
  Result.EffectiveText := AValue.EffectiveText;
  Result.HasEffectiveText := AValue.HasEffectiveText;
  Result.ResolvedDefinition := AValue.ResolvedDefinition;
  Result.ResolvedProperty := AValue.ResolvedProperty;
  Result.ResolvedValue := AValue.ResolvedValue;
  if AValue.EvaluationState = nsvesCompleted then
    Result.EvaluationState := nsvesCompleted
  else if AValue.EvaluationState = nsvesFailed then
    Result.EvaluationState := nsvesFailed;
  if AValue.ArrayPreparationState = nsapsPrepared then
    Result.ArrayPreparationState := nsapsPrepared
  else if AValue.ArrayPreparationState = nsapsFailed then
    Result.ArrayPreparationState := nsapsFailed;
  if AValue.EffectiveValue <> nil then
    Result.EffectiveValue := CloneValue(AValue.EffectiveValue);
  if AValue.StructuralDefinition <> nil then
    Result.StructuralDefinition := CloneDefinition(
      AValue.StructuralDefinition, nil);
  for lItem in AValue.Items do
    Result.Items.Add(CloneValue(lItem));
  for lContributor in AValue.CompositionContributors do
    Result.CompositionContributors.Add(CloneValue(lContributor));
end;

procedure RestoreImportBinding(AValue: TNexusScriptCompiledValue;
  AParent: TNexusScriptCompiledDefinition = nil);
var
  lBinding: TNexusScriptCompiledValue;
begin
  lBinding := AValue.ImportBinding;
  if (lBinding = nil) or (AValue.EvaluationState = nsvesCompleted) or
    (AValue.CompositionContributors.Count > 0) then Exit;
  AValue.ResolvedDefinition := lBinding.ResolvedDefinition;
  AValue.ResolvedProperty := lBinding.ResolvedProperty;
  AValue.ResolvedValue := lBinding.ResolvedValue;
  AValue.EffectiveText := lBinding.EffectiveText;
  AValue.HasEffectiveText := lBinding.HasEffectiveText;
  AValue.EffectiveName := lBinding.EffectiveName;
  AValue.OriginalDefinitionName := lBinding.OriginalDefinitionName;
  AValue.EffectiveValue.Free;
  AValue.EffectiveValue := nil;
  if lBinding.EffectiveValue <> nil then AValue.EffectiveValue := CloneValue(lBinding.EffectiveValue);
  AValue.StructuralDefinition.Free;
  AValue.StructuralDefinition := nil;
  if lBinding.StructuralDefinition <> nil then
    AValue.StructuralDefinition := CloneDefinition(lBinding.StructuralDefinition, AParent);
  AValue.EvaluationState := lBinding.EvaluationState;
  AValue.ArrayPreparationState := lBinding.ArrayPreparationState;
end;

function CloneValueForRebinding(
  AValue: TNexusScriptCompiledValue;
  ADetachSource: Boolean = False): TNexusScriptCompiledValue;
var
  lItem: TNexusScriptCompiledValue;
  lContributor: TNexusScriptCompiledValue;
begin
  Result := TNexusScriptCompiledValue.Create(AValue.Kind, AValue.SourceRange);
  Result.SourceText := AValue.SourceText;
  Result.ImportBinding := AValue.ImportBinding;
  Result.ReferenceRanges.AddRange(AValue.ReferenceRanges);
  Result.EntryName := AValue.EntryName;
  Result.OriginalDefinitionName := AValue.OriginalDefinitionName;
  if not ADetachSource then
    Result.InlineSourceDefinition := AValue.InlineSourceDefinition;
  if Result.EntryName <> '' then
    Result.EffectiveName := Result.EntryName
  else if Result.Kind = nsvDefinition then
    Result.EffectiveName := Result.OriginalDefinitionName;
  if (Result.Kind = nsvDefinition) and
    (AValue.StructuralDefinition <> nil) then
    Result.StructuralDefinition := CloneDefinitionForRebinding(
      AValue.StructuralDefinition, nil, ADetachSource);
  for lItem in AValue.Items do
    Result.Items.Add(CloneValueForRebinding(lItem, ADetachSource));
  for lContributor in AValue.CompositionContributors do
    Result.CompositionContributors.Add(
      CloneValueForRebinding(lContributor, ADetachSource));
end;

function CloneDefinition(ASource: TNexusScriptCompiledDefinition;
  AParent: TNexusScriptCompiledDefinition): TNexusScriptCompiledDefinition;
var
  lProperty: TNexusScriptCompiledProperty;
  lChild: TNexusScriptCompiledDefinition;
begin
  Result := TNexusScriptCompiledDefinition.Create(ASource.Kind, ASource.Name,
    ASource.SourceRange);
  Result.ImportedRoot := ASource.ImportedRoot;
  Result.Parent := AParent;
  Result.SourceDefinition := ASource.SourceDefinition;
  Result.Composed := ASource.Composed;
  Result.Targets.Assign(ASource.Targets);
  for lProperty in ASource.Properties do
  begin
    Result.Properties.Add(TNexusScriptCompiledProperty.Create(lProperty.Name,
      CloneValue(lProperty.Value), lProperty.SourceRange));
    CopyContributorRanges(lProperty,
      Result.Properties[Result.Properties.Count - 1]);
  end;
  for lChild in ASource.Children do
    Result.Children.Add(CloneDefinition(lChild, Result));
end;

function CloneDefinitionForRebinding(ASource: TNexusScriptCompiledDefinition;
  AParent: TNexusScriptCompiledDefinition;
  ADetachSource: Boolean): TNexusScriptCompiledDefinition;
var
  lProperty: TNexusScriptCompiledProperty;
  lChild: TNexusScriptCompiledDefinition;
begin
  Result := TNexusScriptCompiledDefinition.Create(ASource.Kind, ASource.Name,
    ASource.SourceRange);
  Result.ImportedRoot := ASource.ImportedRoot;
  Result.Parent := AParent;
  if not ADetachSource then
    Result.SourceDefinition := ASource.SourceDefinition;
  Result.Composed := ASource.Composed;
  Result.Targets.Assign(ASource.Targets);
  for lProperty in ASource.Properties do
  begin
    Result.Properties.Add(TNexusScriptCompiledProperty.Create(lProperty.Name,
      CloneValueForRebinding(lProperty.Value, ADetachSource),
      lProperty.SourceRange));
    CopyContributorRanges(lProperty,
      Result.Properties[Result.Properties.Count - 1]);
  end;
  for lChild in ASource.Children do
    Result.Children.Add(CloneDefinitionForRebinding(lChild, Result,
      ADetachSource));
end;

procedure TNexusScriptCompiler.CompileSource;
var
  lSourceDefinition: TNexusScriptSourceDefinition;

  function EvaluateProperty(AScope: TNexusScriptCompiledDefinition;
    AProperty: TNexusScriptCompiledProperty): Boolean; forward;

  function EvaluateValue(AScope: TNexusScriptCompiledDefinition;
    AValue: TNexusScriptCompiledValue;
    const AReceiverName: string): Boolean; forward;

  function PrepareArrayValue(AScope: TNexusScriptCompiledDefinition;
    AValue: TNexusScriptCompiledValue;
    out AArrayValue: TNexusScriptCompiledValue): Boolean; forward;

  function BindDefinition(
    ADefinition: TNexusScriptCompiledDefinition): Boolean; forward;

  function FindNestedScope(AScope: TNexusScriptCompiledDefinition;
    const AName: string): TNexusScriptCompiledDefinition;
  var
    lProperty: TNexusScriptCompiledProperty;
  begin
    Result := AScope.FindChild(AName);
    if Result <> nil then
      Exit;
    lProperty := AScope.FindProperty(AName);
    if lProperty <> nil then
    begin
      if lProperty.Value.DefinitionValue = nil then
        EvaluateProperty(AScope, lProperty);
      Result := lProperty.Value.DefinitionValue;
    end;
  end;

  function FindStructuralPropertyScope(
    AScope: TNexusScriptCompiledDefinition;
    const AName: string): TNexusScriptCompiledDefinition;
  var
    lProperty: TNexusScriptCompiledProperty;
  begin
    Result := nil;
    if AScope = nil then
      Exit;
    lProperty := AScope.FindProperty(AName);
    if lProperty <> nil then
    begin
      if lProperty.Value.DefinitionValue = nil then
        EvaluateProperty(AScope, lProperty);
      Result := lProperty.Value.DefinitionValue;
    end;
  end;

  function FindDefinitionPath(AScope: TNexusScriptCompiledDefinition;
    const APath: string): TNexusScriptCompiledDefinition;
  var
    lParts: TStringList;
    lScope: TNexusScriptCompiledDefinition;
    lIndex: Integer;
  begin
    Result := nil;
    lParts := TStringList.Create;
    try
      lParts.Delimiter := '.';
      lParts.StrictDelimiter := True;
      lParts.DelimitedText := APath;
      if lParts.Count = 1 then
      begin
        if AScope = nil then
          Exit(FCompiledDocument.FindDefinition(lParts[0]));
        Result := AScope.FindChild(lParts[0]);
        if Result = nil then
        begin
          Result := FCompiledDocument.FindDefinition(lParts[0]);
          if (Result <> nil) and not Result.ImportedRoot then
            Result := nil;
        end;
        Exit;
      end;
      lScope := FindStructuralPropertyScope(AScope, lParts[0]);
      if lScope <> nil then
      begin
        for lIndex := 1 to lParts.Count - 1 do
        begin
          lScope := FindNestedScope(lScope, lParts[lIndex]);
          if lScope = nil then
            Exit;
        end;
        Exit(lScope);
      end;
      lScope := AScope;
      while (lScope <> nil) and not SameText(lScope.Name, lParts[0]) do
        lScope := lScope.Parent;
      if lScope = nil then
      begin
        lScope := FCompiledDocument.FindDefinition(lParts[0]);
        if (lScope <> nil) and not lScope.ImportedRoot then
          lScope := nil;
      end;
      if lScope = nil then
        Exit;
      for lIndex := 1 to lParts.Count - 1 do
      begin
        lScope := FindNestedScope(lScope, lParts[lIndex]);
        if lScope = nil then
          Exit;
      end;
      Result := lScope;
    finally
      lParts.Free;
    end;
  end;

  procedure Compose(ADefinition: TNexusScriptCompiledDefinition);
  var
    lSource: TNexusScriptSourceDefinition;
    lSelector: string;
    lBase: TNexusScriptCompiledDefinition;
    lProperty: TNexusScriptCompiledProperty;
    lChild: TNexusScriptCompiledDefinition;
    lLocalProperties: TNexusScriptCompiledPropertyList;
    lLocalChildren: TNexusScriptCompiledDefinitionList;
    lEmptyRange: TNexusScriptRange;

    procedure RemoveProperty(const AName: string);
    var
      lMemberIndex: Integer;
    begin
      for lMemberIndex := ADefinition.Properties.Count - 1 downto 0 do
        if SameText(ADefinition.Properties[lMemberIndex].Name, AName) then
          ADefinition.Properties.Delete(lMemberIndex);
    end;

    procedure RemoveChild(const AName: string);
    var
      lMemberIndex: Integer;
    begin
      for lMemberIndex := ADefinition.Children.Count - 1 downto 0 do
        if SameText(ADefinition.Children[lMemberIndex].Name, AName) then
          ADefinition.Children.Delete(lMemberIndex);
    end;

    procedure AppendCompositionLayers(ATarget,
      ASource: TNexusScriptCompiledValue);
    var
      lContributor: TNexusScriptCompiledValue;
    begin
      if ASource.CompositionContributors.Count = 0 then
        ATarget.CompositionContributors.Add(
          CloneValueForRebinding(ASource))
      else
        for lContributor in ASource.CompositionContributors do
          ATarget.CompositionContributors.Add(
            CloneValueForRebinding(lContributor));
    end;

    procedure ApplyProperty(AProperty: TNexusScriptCompiledProperty);
    var
      lExisting: TNexusScriptCompiledProperty;
      lMergedValue: TNexusScriptCompiledValue;
      lResultProperty: TNexusScriptCompiledProperty;

      function CanHaveArrayResult(
        AValue: TNexusScriptCompiledValue): Boolean;
      begin
        Result := AValue.Kind in [nsvArray, nsvReference];
      end;
    begin
      if ADefinition.FindChild(AProperty.Name) <> nil then
      begin
        AddError('NXS4003', 'Ambiguous composed member ' + AProperty.Name,
          ADefinition.SourceRange);
        Exit;
      end;
      lExisting := ADefinition.FindProperty(AProperty.Name);
      if (lExisting <> nil) and CanHaveArrayResult(lExisting.Value) and
        CanHaveArrayResult(AProperty.Value) then
      begin
        lMergedValue := CloneValueForRebinding(AProperty.Value);
        lMergedValue.CompositionContributors.Clear;
        lMergedValue.EvaluationState := nsvesPending;
        lMergedValue.ArrayPreparationState := nsapsUnprepared;
        AppendCompositionLayers(lMergedValue, lExisting.Value);
        AppendCompositionLayers(lMergedValue, AProperty.Value);
        lResultProperty := TNexusScriptCompiledProperty.Create(
          AProperty.Name, lMergedValue, AProperty.SourceRange);
        lResultProperty.ContributorRanges.Clear;
        lResultProperty.ContributorRanges.AddRange(
          lExisting.ContributorRanges);
        lResultProperty.ContributorRanges.AddRange(
          AProperty.ContributorRanges);
        RemoveProperty(AProperty.Name);
        ADefinition.Properties.Add(lResultProperty);
        Exit;
      end;
      lResultProperty := TNexusScriptCompiledProperty.Create(
        AProperty.Name, CloneValueForRebinding(AProperty.Value),
        AProperty.SourceRange);
      lResultProperty.ContributorRanges.Clear;
      if lExisting <> nil then
        lResultProperty.ContributorRanges.AddRange(
          lExisting.ContributorRanges);
      lResultProperty.ContributorRanges.AddRange(
        AProperty.ContributorRanges);
      RemoveProperty(AProperty.Name);
      ADefinition.Properties.Add(lResultProperty);
    end;
  begin
    if ADefinition.Composed then
      Exit;
    if ADefinition.Composing then
    begin
      AddError('NXS4001', 'Composition cycle at ' + ADefinition.Name,
        ADefinition.SourceRange);
      Exit;
    end;
    ADefinition.Composing := True;
    lSource := ADefinition.SourceDefinition;
    if lSource = nil then
    begin
      ADefinition.Composing := False;
      ADefinition.Composed := True;
      Exit;
    end;
    lLocalProperties := TNexusScriptCompiledPropertyList.Create(True);
    lLocalChildren := TNexusScriptCompiledDefinitionList.Create(True);
    try
      for lProperty in ADefinition.Properties do
      begin
        lLocalProperties.Add(TNexusScriptCompiledProperty.Create(lProperty.Name,
          CloneValue(lProperty.Value), lProperty.SourceRange));
        CopyContributorRanges(lProperty,
          lLocalProperties[lLocalProperties.Count - 1]);
      end;
      for lChild in ADefinition.Children do
        lLocalChildren.Add(CloneDefinitionForRebinding(lChild,
          ADefinition));
      ADefinition.Properties.Clear;
      ADefinition.Children.Clear;

      lEmptyRange := Default(TNexusScriptRange);
      for lSelector in lSource.CompositionSelectors do
      begin
        lBase := FindDefinitionPath(ADefinition.Parent, lSelector);
        if lBase = nil then
        begin
          lSource.CompositionTargetRanges.Add(lEmptyRange);
          AddError('NXS4002', 'Unresolved composition target ' + lSelector,
            ADefinition.SourceRange);
          Continue;
        end;
        if lBase.SourceDefinition <> nil then
          lSource.CompositionTargetRanges.Add(
            lBase.SourceDefinition.NameRange)
        else
          lSource.CompositionTargetRanges.Add(lBase.SourceRange);
        Compose(lBase);
        for lProperty in lBase.Properties do
          ApplyProperty(lProperty);
        for lChild in lBase.Children do
        begin
          if ADefinition.FindProperty(lChild.Name) <> nil then
            AddError('NXS4003', 'Ambiguous composed member ' + lChild.Name,
              ADefinition.SourceRange)
          else
          begin
            RemoveChild(lChild.Name);
            ADefinition.Children.Add(CloneDefinitionForRebinding(lChild,
              ADefinition));
          end;
        end;
      end;

      for lProperty in lLocalProperties do
        ApplyProperty(lProperty);
      for lChild in lLocalChildren do
      begin
        if ADefinition.FindProperty(lChild.Name) <> nil then
          AddError('NXS4003', 'Ambiguous composed member ' + lChild.Name,
            ADefinition.SourceRange)
        else
        begin
          RemoveChild(lChild.Name);
          ADefinition.Children.Add(CloneDefinitionForRebinding(lChild,
            ADefinition));
        end;
      end;
    finally
      lLocalChildren.Free;
      lLocalProperties.Free;
    end;
    ADefinition.Composing := False;
    ADefinition.Composed := True;
    for lChild in ADefinition.Children do
      Compose(lChild);
  end;

  function ResolveNamedArrayItem(AScope: TNexusScriptCompiledDefinition;
    AValue: TNexusScriptCompiledValue; const AName: string;
    out AArrayValue: TNexusScriptCompiledValue;
    out AItem: TNexusScriptCompiledValue): Boolean;
  begin
    AArrayValue := nil;
    AItem := nil;
    if not PrepareArrayValue(AScope, AValue, AArrayValue) then
      Exit(False);
    if AArrayValue = nil then
      Exit(False);
    AItem := AArrayValue.FindNamedItem(AName);
    Result := AItem <> nil;
  end;

  function ResolveMember(AScope: TNexusScriptCompiledDefinition;
    const APath: string; out AProperty: TNexusScriptCompiledProperty;
    out ADefinition: TNexusScriptCompiledDefinition;
    out APropertyOwner: TNexusScriptCompiledDefinition;
    out ADirectValue: TNexusScriptCompiledValue): Boolean;
  var
    lParts: TStringList;
    lScope: TNexusScriptCompiledDefinition;

    function ResolveDown(ACurrentScope: TNexusScriptCompiledDefinition;
      AIndex: Integer): Boolean;
    var
      lMemberProperty: TNexusScriptCompiledProperty;
      lMemberDefinition: TNexusScriptCompiledDefinition;
      lArrayItem: TNexusScriptCompiledValue;
      lArrayValue: TNexusScriptCompiledValue;
    begin
      Result := False;
      lMemberProperty := ACurrentScope.FindProperty(lParts[AIndex]);
      if lMemberProperty <> nil then
      begin
        if AIndex = lParts.Count - 1 then
        begin
          AProperty := lMemberProperty;
          APropertyOwner := ACurrentScope;
          Exit(True);
        end;
        lArrayValue := nil;
        if (lMemberProperty.Value.Kind in [nsvArray, nsvReference]) or
          (lMemberProperty.Value.CompositionContributors.Count > 0) then
        begin
          if not lMemberProperty.Resolving then
            if not EvaluateProperty(ACurrentScope, lMemberProperty) then
            begin
              AProperty := lMemberProperty;
              APropertyOwner := ACurrentScope;
              Exit(True);
            end;
          if not ResolveNamedArrayItem(ACurrentScope,
            lMemberProperty.Value, lParts[AIndex + 1], lArrayValue,
            lArrayItem) then
          begin
            if (lMemberProperty.Value.ArrayPreparationState = nsapsFailed) or
              (lMemberProperty.Value.EvaluationState = nsvesFailed) then
            begin
              AProperty := lMemberProperty;
              APropertyOwner := ACurrentScope;
              Exit(True);
            end;
            if lArrayValue <> nil then
              Exit;
          end
          else
          begin
            if AIndex + 1 = lParts.Count - 1 then
            begin
              APropertyOwner := ACurrentScope;
              ADirectValue := lArrayItem;
              Exit(True);
            end;
            if (lArrayItem.EvaluationState = nsvesResolving) and
              (lArrayItem.Kind = nsvDefinition) and
              (lArrayItem.StructuralDefinition <> nil) then
              Exit(ResolveDown(lArrayItem.StructuralDefinition,
                AIndex + 2));
            if not EvaluateValue(ACurrentScope, lArrayItem,
              lArrayItem.EntryName) then
            begin
              ADirectValue := lArrayItem;
              Exit(True);
            end;
            if lArrayItem.DefinitionValue = nil then
              Exit;
            Exit(ResolveDown(lArrayItem.DefinitionValue, AIndex + 2));
          end;
        end;
        if not EvaluateProperty(ACurrentScope, lMemberProperty) then
        begin
          AProperty := lMemberProperty;
          APropertyOwner := ACurrentScope;
          Exit(True);
        end;
        if lMemberProperty.Value.DefinitionValue <> nil then
          Exit(ResolveDown(lMemberProperty.Value.DefinitionValue,
            AIndex + 1));
        Exit;
      end;
      lMemberDefinition := ACurrentScope.FindChild(lParts[AIndex]);
      if lMemberDefinition = nil then
        Exit;
      if AIndex = lParts.Count - 1 then
      begin
        ADefinition := lMemberDefinition;
        Exit(True);
      end;
      Result := ResolveDown(lMemberDefinition, AIndex + 1);
    end;
  begin
    AProperty := nil;
    ADefinition := nil;
    APropertyOwner := nil;
    ADirectValue := nil;
    lParts := TStringList.Create;
    try
      lParts.Delimiter := '.';
      lParts.StrictDelimiter := True;
      lParts.DelimitedText := APath;
      if lParts.Count = 1 then
      begin
        if ResolveDown(AScope, 0) then
          Exit(True);
        lScope := FCompiledDocument.FindDefinition(lParts[0]);
        if (lScope <> nil) and lScope.ImportedRoot then
        begin
          ADefinition := lScope;
          Exit(True);
        end;
        Exit(False);
      end;
      lScope := AScope;
      while lScope <> nil do
      begin
        if (lScope.FindProperty(lParts[0]) <> nil) or
          (lScope.FindChild(lParts[0]) <> nil) then
          Exit(ResolveDown(lScope, 0));
        lScope := lScope.Parent;
      end;
      lScope := AScope;
      while (lScope <> nil) and not SameText(lScope.Name, lParts[0]) do
        lScope := lScope.Parent;
      if lScope = nil then
      begin
        lScope := FCompiledDocument.FindDefinition(lParts[0]);
        if (lScope <> nil) and not lScope.ImportedRoot then
          lScope := nil;
      end;
      if lScope = nil then
        Exit(False);
      Result := ResolveDown(lScope, 1);
    finally
      lParts.Free;
    end;
  end;

  function EvaluateProperty(AScope: TNexusScriptCompiledDefinition;
    AProperty: TNexusScriptCompiledProperty): Boolean;
  begin
    if AProperty.Resolving then
    begin
      AddError('NXS5002', 'Value dependency cycle at ' + AProperty.Name,
        AProperty.SourceRange);
      Exit(False);
    end;
    if AProperty.Value.EvaluationState = nsvesCompleted then
      Exit(True);
    if AProperty.Value.EvaluationState = nsvesFailed then
      Exit(False);
    AProperty.Resolving := True;
    try
      Result := EvaluateValue(AScope, AProperty.Value, AProperty.Name);
    finally
      AProperty.Resolving := False;
    end;
  end;

  function ValueDiagnosticName(AValue: TNexusScriptCompiledValue): string;
  begin
    Result := AValue.EffectiveName;
    if Result = '' then
      Result := AValue.EntryName;
    if Result = '' then
      Result := AValue.OriginalDefinitionName;
    if Result = '' then
      Result := AValue.SourceText;
    if Result = '' then
      Result := 'array';
  end;

  function EstablishEntryIdentity(AScope: TNexusScriptCompiledDefinition;
    AValue: TNexusScriptCompiledValue): Boolean;
  var
    lProperty: TNexusScriptCompiledProperty;
    lDefinition: TNexusScriptCompiledDefinition;
    lPropertyOwner: TNexusScriptCompiledDefinition;
    lDirectValue: TNexusScriptCompiledValue;
  begin
    RestoreImportBinding(AValue, AScope);
    if AValue.EffectiveName <> '' then
      Exit(True);
    if AValue.EntryName <> '' then
    begin
      AValue.EffectiveName := AValue.EntryName;
      Exit(True);
    end;
    if AValue.Kind = nsvDefinition then
    begin
      AValue.EffectiveName := AValue.OriginalDefinitionName;
      Exit(True);
    end;
    if AValue.Kind <> nsvReference then
      Exit(True);
    lDefinition := AValue.ResolvedDefinition;
    if lDefinition = nil then
    begin
      if not ResolveMember(AScope, AValue.SourceText, lProperty,
        lDefinition, lPropertyOwner, lDirectValue) then
      begin
        AddError('NXS5001', 'Unresolved reference @' + AValue.SourceText,
          AValue.SourceRange);
        AValue.EvaluationState := nsvesFailed;
        Exit(False);
      end;
      AValue.ResolvedProperty := lProperty;
      AValue.ResolvedDefinition := lDefinition;
      AValue.ResolvedValue := lDirectValue;
    end;
    if lDefinition <> nil then
    begin
      AValue.EffectiveName := lDefinition.Name;
      AValue.OriginalDefinitionName := lDefinition.Name;
    end;
    Result := True;
  end;

  function PrepareArrayValue(AScope: TNexusScriptCompiledDefinition;
    AValue: TNexusScriptCompiledValue;
    out AArrayValue: TNexusScriptCompiledValue): Boolean;
  var
    lItem: TNexusScriptCompiledValue;
    lContributor: TNexusScriptCompiledValue;
    lContributorArray: TNexusScriptCompiledValue;
    lTargetArray: TNexusScriptCompiledValue;
    lMergedItem: TNexusScriptCompiledValue;
    lExistingItem: TNexusScriptCompiledValue;
    lProperty: TNexusScriptCompiledProperty;
    lDefinition: TNexusScriptCompiledDefinition;
    lPropertyOwner: TNexusScriptCompiledDefinition;
    lDirectValue: TNexusScriptCompiledValue;
    lNames: TStringList;
    lExistingIndex: Integer;
    lAllContributorArrays: Boolean;
    lSucceeded: Boolean;
  begin
    AArrayValue := nil;
    RestoreImportBinding(AValue, AScope);
    case AValue.ArrayPreparationState of
      nsapsPrepared:
        begin
          if AValue.Kind = nsvArray then
            AArrayValue := AValue
          else if (AValue.EffectiveValue <> nil) and
            (AValue.EffectiveValue.Kind = nsvArray) then
            AArrayValue := AValue.EffectiveValue;
          Exit(True);
        end;
      nsapsPreparing:
        begin
          AddError('NXS5002', 'Value dependency cycle at ' +
            ValueDiagnosticName(AValue), AValue.SourceRange);
          AValue.ArrayPreparationState := nsapsFailed;
          Exit(False);
        end;
      nsapsFailed:
        Exit(False);
    end;

    AValue.ArrayPreparationState := nsapsPreparing;
    Result := False;
    try
      if AValue.CompositionContributors.Count > 0 then
      begin
        lAllContributorArrays := True;
        for lContributor in AValue.CompositionContributors do
        begin
          if not PrepareArrayValue(AScope, lContributor,
            lContributorArray) then
            Exit;
          if lContributorArray = nil then
            lAllContributorArrays := False;
        end;
        if lAllContributorArrays then
        begin
          AValue.Kind := nsvArray;
          AValue.EffectiveValue.Free;
          AValue.EffectiveValue := nil;
          AValue.Items.Clear;
          for lContributor in AValue.CompositionContributors do
          begin
            if not PrepareArrayValue(AScope, lContributor,
              lContributorArray) then
              Exit;
            for lItem in lContributorArray.Items do
            begin
              lMergedItem := CloneValueForRebinding(lItem);
              lExistingIndex := -1;
              if lMergedItem.EffectiveName <> '' then
              begin
                lExistingItem := AValue.FindNamedItem(
                  lMergedItem.EffectiveName);
                if lExistingItem <> nil then
                  lExistingIndex := AValue.Items.IndexOf(lExistingItem);
              end;
              if lExistingIndex >= 0 then
                AValue.Items[lExistingIndex] := lMergedItem
              else
                AValue.Items.Add(lMergedItem);
            end;
          end;
        end
        else
          AValue.CompositionContributors.Clear;
      end;

      if AValue.Kind = nsvArray then
      begin
        lNames := TStringList.Create;
        try
          lNames.CaseSensitive := False;
          lSucceeded := True;
          for lItem in AValue.Items do
          begin
            if not EstablishEntryIdentity(AScope, lItem) then
              lSucceeded := False;
            if lItem.EffectiveName <> '' then
            begin
              if lNames.IndexOf(lItem.EffectiveName) >= 0 then
              begin
                AddError('NXS5005', 'Duplicate array entry name ' +
                  lItem.EffectiveName, lItem.SourceRange);
                lSucceeded := False;
              end
              else
                lNames.Add(lItem.EffectiveName);
            end;
          end;
          if not lSucceeded then
            Exit;
        finally
          lNames.Free;
        end;
        AArrayValue := AValue;
        Result := True;
        Exit;
      end;

      if AValue.Kind = nsvReference then
      begin
        lProperty := nil;
        lDefinition := nil;
        lPropertyOwner := nil;
        lDirectValue := nil;
        if not ResolveMember(AScope, AValue.SourceText, lProperty,
          lDefinition, lPropertyOwner, lDirectValue) then
        begin
          AddError('NXS5001', 'Unresolved reference @' + AValue.SourceText,
            AValue.SourceRange);
          Exit;
        end;
        AValue.ResolvedProperty := lProperty;
        AValue.ResolvedDefinition := lDefinition;
        AValue.ResolvedValue := lDirectValue;
        lTargetArray := nil;
        if lProperty <> nil then
        begin
          if not PrepareArrayValue(lPropertyOwner, lProperty.Value,
            lTargetArray) then
            Exit;
        end
        else if lDirectValue <> nil then
        begin
          if not PrepareArrayValue(AScope, lDirectValue, lTargetArray) then
            Exit;
        end;
        if lTargetArray <> nil then
        begin
          AValue.EffectiveValue.Free;
          AValue.EffectiveValue := CloneValue(lTargetArray);
          AArrayValue := AValue.EffectiveValue;
        end;
      end;
      Result := True;
    finally
      if Result then
        AValue.ArrayPreparationState := nsapsPrepared
      else
        AValue.ArrayPreparationState := nsapsFailed;
    end;
  end;

  function EvaluateValue(AScope: TNexusScriptCompiledDefinition;
    AValue: TNexusScriptCompiledValue;
    const AReceiverName: string): Boolean;
  var
    lItem: TNexusScriptCompiledValue;
    lProperty: TNexusScriptCompiledProperty;
    lDefinition: TNexusScriptCompiledDefinition;
    lPropertyOwner: TNexusScriptCompiledDefinition;
    lOriginalDefinition: TNexusScriptCompiledDefinition;
    lEffectiveName: string;
    lDirectValue: TNexusScriptCompiledValue;
    lArrayValue: TNexusScriptCompiledValue;
    lSucceeded: Boolean;
  begin
    RestoreImportBinding(AValue, AScope);
    case AValue.EvaluationState of
      nsvesCompleted:
        Exit(True);
      nsvesResolving:
        begin
          AddError('NXS5002', 'Value dependency cycle at ' +
            ValueDiagnosticName(AValue), AValue.SourceRange);
          AValue.EvaluationState := nsvesFailed;
          Exit(False);
        end;
      nsvesFailed:
        Exit(False);
    end;

    AValue.EvaluationState := nsvesResolving;
    Result := False;
    try
      if AValue.CompositionContributors.Count > 0 then
        if not PrepareArrayValue(AScope, AValue, lArrayValue) then
          Exit;
      case AValue.Kind of
      nsvText:
        begin
          AValue.EffectiveText := AValue.SourceText;
          AValue.HasEffectiveText := True;
          Result := True;
        end;
      nsvDefinition:
        begin
          lOriginalDefinition := AValue.StructuralDefinition;
          lOriginalDefinition.Parent := AScope;
          Compose(lOriginalDefinition);
          if not BindDefinition(lOriginalDefinition) then
            Exit;
          lEffectiveName := AValue.EntryName;
          if lEffectiveName = '' then
            lEffectiveName := AValue.OriginalDefinitionName;
          lOriginalDefinition.Name := lEffectiveName;
          AValue.EffectiveName := lEffectiveName;
          Result := True;
        end;
      nsvReference:
        begin
          lProperty := nil;
          lDefinition := nil;
          lPropertyOwner := nil;
          lDirectValue := nil;
          if not ResolveMember(AScope, AValue.SourceText, lProperty,
            lDefinition, lPropertyOwner, lDirectValue) then
          begin
            AddError('NXS5001', 'Unresolved reference @' + AValue.SourceText,
              AValue.SourceRange);
            Exit;
          end;
          AValue.ResolvedProperty := lProperty;
          AValue.ResolvedDefinition := lDefinition;
          AValue.ResolvedValue := lDirectValue;
          if lDirectValue <> nil then
          begin
            if (lDirectValue.Kind = nsvDefinition) and
              (lDirectValue.StructuralDefinition <> nil) then
            begin
              AValue.ResolvedDefinition :=
                lDirectValue.StructuralDefinition;
              AValue.OriginalDefinitionName :=
                lDirectValue.OriginalDefinitionName;
              AValue.EffectiveName := AReceiverName;
              Result := True;
              Exit;
            end;
            if lPropertyOwner = nil then
              lPropertyOwner := AScope;
            if not EvaluateValue(lPropertyOwner, lDirectValue,
              lDirectValue.EntryName) then
              Exit;
            AValue.EffectiveText := lDirectValue.EffectiveText;
            AValue.HasEffectiveText := lDirectValue.HasEffectiveText;
            AValue.ResolvedDefinition := lDirectValue.DefinitionValue;
            AValue.EffectiveValue.Free;
            AValue.EffectiveValue := nil;
            if lDirectValue.EffectiveValue <> nil then
              AValue.EffectiveValue := CloneValue(
                lDirectValue.EffectiveValue)
            else if lDirectValue.Kind = nsvArray then
              AValue.EffectiveValue := CloneValue(lDirectValue);
            if lDirectValue.DefinitionValue <> nil then
            begin
              AValue.OriginalDefinitionName :=
                lDirectValue.OriginalDefinitionName;
            end;
            AValue.EffectiveName := AReceiverName;
            Result := True;
            Exit;
          end;
          if lProperty <> nil then
          begin
            if (lProperty.Value.Kind = nsvDefinition) and
              (lProperty.Value.StructuralDefinition <> nil) then
            begin
              AValue.ResolvedDefinition := lProperty.Value.StructuralDefinition;
              AValue.OriginalDefinitionName := lProperty.Value.OriginalDefinitionName;
              AValue.EffectiveName := AReceiverName;
              Exit(True);
            end;
            if not EvaluateProperty(lPropertyOwner, lProperty) then
              Exit;
            AValue.EffectiveText := lProperty.Value.EffectiveText;
            AValue.HasEffectiveText := lProperty.Value.HasEffectiveText;
            AValue.EffectiveValue.Free;
            AValue.EffectiveValue := nil;
            if lProperty.Value.EffectiveValue <> nil then
              AValue.EffectiveValue := CloneValue(
                lProperty.Value.EffectiveValue)
            else if lProperty.Value.Kind = nsvArray then
              AValue.EffectiveValue := CloneValue(lProperty.Value);
            if lProperty.Value.DefinitionValue <> nil then
            begin
              AValue.ResolvedDefinition := lProperty.Value.DefinitionValue;
              AValue.OriginalDefinitionName :=
                lProperty.Value.OriginalDefinitionName;
            end;
            AValue.EffectiveName := AReceiverName;
            Result := True;
          end;
          if lDefinition <> nil then
          begin
            AValue.EffectiveName := AReceiverName;
            if AValue.EffectiveName = '' then AValue.EffectiveName := lDefinition.Name;
            AValue.OriginalDefinitionName := lDefinition.Name;
            Result := True;
          end;
        end;
      nsvTextComposition:
        begin
          AValue.EffectiveText := '';
          AValue.HasEffectiveText := True;
          lSucceeded := True;
          for lItem in AValue.Items do
          begin
            if not EvaluateValue(AScope, lItem, AReceiverName) then
              lSucceeded := False;
            if not lItem.HasEffectiveText then
            begin
              AddError('NXS5003',
                'Definition reference cannot be composed as text',
                lItem.SourceRange);
              AValue.HasEffectiveText := False;
              lSucceeded := False;
            end
            else
              AValue.EffectiveText := AValue.EffectiveText +
                lItem.EffectiveText;
          end;
          Result := lSucceeded;
        end;
      nsvArray:
        begin
          if not PrepareArrayValue(AScope, AValue, lArrayValue) then
            Exit;
          lSucceeded := True;
          for lItem in lArrayValue.Items do
            if not EvaluateValue(AScope, lItem, lItem.EntryName) then
              lSucceeded := False;
          Result := lSucceeded;
        end;
      end;
    finally
      if Result then
        AValue.EvaluationState := nsvesCompleted
      else
        AValue.EvaluationState := nsvesFailed;
    end;
  end;

  function BindDefinition(
    ADefinition: TNexusScriptCompiledDefinition): Boolean;
  var
    lProperty: TNexusScriptCompiledProperty;
    lChild: TNexusScriptCompiledDefinition;
  begin
    Result := True;
    for lProperty in ADefinition.Properties do
      if not EvaluateProperty(ADefinition, lProperty) then
        Result := False;
    for lChild in ADefinition.Children do
      if not BindDefinition(lChild) then
        Result := False;
  end;

var
  lCompiledDefinition: TNexusScriptCompiledDefinition;
  lExistingDefinition: TNexusScriptCompiledDefinition;
  lImportedDefinition: TNexusScriptCompiledDefinition;

  procedure MarkComposed(ADefinition: TNexusScriptCompiledDefinition);
  var
    lChild: TNexusScriptCompiledDefinition;
  begin
    ADefinition.Composed := True;
    for lChild in ADefinition.Children do
      MarkComposed(lChild);
  end;
begin
  for lImportedDefinition in FImportedDefinitions do
  begin
    if FCompiledDocument.FindDefinition(lImportedDefinition.Name) <> nil then
    begin
      AddError('NXS3003', 'Duplicate imported root ' +
        lImportedDefinition.Name, lImportedDefinition.SourceRange);
      Continue;
    end;
    lCompiledDefinition := CloneDefinitionForRebinding(lImportedDefinition,
      nil, True);
    PreserveNexusScriptImportBindings(lImportedDefinition, lCompiledDefinition);
    MarkComposed(lCompiledDefinition);
    FCompiledDocument.Definitions.Add(lCompiledDefinition);
  end;
  for lSourceDefinition in FSourceDocument.Definitions do
  begin
    if not DefinitionAppliesToTargets(lSourceDefinition,
      FSelectedTargets) then
      Continue;
    lExistingDefinition := FCompiledDocument.FindDefinition(
      lSourceDefinition.Name);
    if lExistingDefinition <> nil then
    begin
      if lExistingDefinition.ImportedRoot then
        AddError('NXS3004',
          'Imported root collides with local root definition ' +
          lSourceDefinition.Name, lSourceDefinition.SourceRange)
      else
        AddError('NXS3002', 'Duplicate root definition ' +
          lSourceDefinition.Name, lSourceDefinition.SourceRange);
    end
    else
      FCompiledDocument.Definitions.Add(CopyDefinition(Self,
        lSourceDefinition, nil, FSelectedTargets));
  end;
  for lCompiledDefinition in FCompiledDocument.Definitions do
    Compose(lCompiledDefinition);
  for lCompiledDefinition in FCompiledDocument.Definitions do
    BindDefinition(lCompiledDefinition);
end;

procedure TNexusScriptCompiler.ClearImports;
begin
  FImportedDefinitions.Clear;
end;

procedure TNexusScriptCompiler.AddImportedDefinition(
  ADefinition: TNexusScriptCompiledDefinition);
var
  lImportedDefinition: TNexusScriptCompiledDefinition;
begin
  lImportedDefinition := CloneDefinitionForRebinding(ADefinition, nil, True);
  PreserveNexusScriptImportBindings(ADefinition, lImportedDefinition);
  lImportedDefinition.ImportedRoot := True;
  FImportedDefinitions.Add(lImportedDefinition);
end;

procedure TNexusScriptCompiler.AddImportedDocument(
  ADocument: TNexusScriptCompiledDocument);
var
  lDefinition: TNexusScriptCompiledDefinition;
begin
  for lDefinition in ADocument.Definitions do
    AddImportedDefinition(lDefinition);
end;

function TNexusScriptCompiler.CompileText(const ASourceName,
  AText: string; ACompiledAt: TDateTime): Boolean;
var
  lParser: TNexusScriptParser;
begin
  if ACompiledAt = 0 then ACompiledAt := LocalTimeToUniversal(Now);
  FDiagnostics.Clear;
  FreeAndNil(FCompiledDocument);
  FreeAndNil(FSourceDocument);
  FCompiledDocument := TNexusScriptCompiledDocument.Create(ASourceName, ACompiledAt);
  lParser := TNexusScriptParser.Create(Self, ASourceName, AText);
  try
    FSourceDocument := lParser.Parse;
  finally
    lParser.Free;
  end;
  CompileSource;
  Result := FDiagnostics.Count = 0;
end;

function TNexusScriptCompiler.CompileFile(const AFileName: string): Boolean;
var
  lText: TStringList;
begin
  lText := TStringList.Create;
  try
    lText.LoadFromFile(AFileName);
    Result := CompileText(ExpandFileName(AFileName), lText.Text);
  finally
    lText.Free;
  end;
end;

end.

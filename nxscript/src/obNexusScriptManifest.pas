(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNexusScriptManifest;

{$mode delphi}{$H+}

interface

uses
  Classes,
  SysUtils,
  obNexusScriptModel;

type
  ENexusScriptCommand = class(Exception);

  TNexusScriptManifest = class
  private
    class function LoadTextFile(const AFileName: string): string; static;
    class procedure WriteText(AStream: TStream; const AValue: string); static;
    class procedure WriteOutput(const AFileName, AArtifact: string;
      AStdOut: TStream); static;
    class function RenderTemplate(const AJSON,
      ATemplateFile: string): string; static;
    class procedure ValidateDocument(
      ADocument: TNexusScriptCompiledDocument); static;
    class function ManifestOutputFile(const AOutputDirectory,
      ARelativePath: string): string; static;
  public
    class procedure Render(const AManifestFile,
      AOutputDirectory, ADialectRoot: string; AValidate: Boolean); static;
  end;

implementation

uses
  Generics.Collections,
  tpNexusScript,
  obNexusScriptSession,
  obNexusScriptArtifactModel,
  obNexusScriptArtifactContext,
  obNexusScriptJSON,
  obNexusScriptExternalSource,
  obNexusScriptValidator,
  obMustacheRenderer;

type
  TNexusScriptSourceTemplateRule = class
  private
    FName: string;
    FTypes: TStringList;
    FCompilerName: string;
    FTemplateFile: string;
    FOutputDirectory: string;
    FOutputExtension: string;
  public
    constructor Create;
    destructor Destroy; override;
    property Name: string read FName write FName;
    property Types: TStringList read FTypes;
    property CompilerName: string read FCompilerName write FCompilerName;
    property TemplateFile: string read FTemplateFile write FTemplateFile;
    property OutputDirectory: string read FOutputDirectory
      write FOutputDirectory;
    property OutputExtension: string read FOutputExtension
      write FOutputExtension;
  end;

  TNexusScriptSourceRender = class
  private
    FSource: TNexusScriptExternalSource;
    FRule: TNexusScriptSourceTemplateRule;
    FOutputFile: string;
  public
    constructor Create(ASource: TNexusScriptExternalSource;
      ARule: TNexusScriptSourceTemplateRule; const AOutputFile: string);
    property Source: TNexusScriptExternalSource read FSource;
    property Rule: TNexusScriptSourceTemplateRule read FRule;
    property OutputFile: string read FOutputFile;
  end;

constructor TNexusScriptSourceTemplateRule.Create;
begin
  inherited Create;
  FTypes := TStringList.Create;
  FTypes.CaseSensitive := False;
end;

destructor TNexusScriptSourceTemplateRule.Destroy;
begin
  FTypes.Free;
  inherited Destroy;
end;

constructor TNexusScriptSourceRender.Create(ASource: TNexusScriptExternalSource;
  ARule: TNexusScriptSourceTemplateRule; const AOutputFile: string);
begin
  inherited Create;
  FSource := ASource;
  FRule := ARule;
  FOutputFile := AOutputFile;
end;

function ValidationFailureText(
  ADiagnostics: TNexusScriptValidationDiagnosticList): string;
var
  lDiagnostic: TNexusScriptValidationDiagnostic;
begin
  Result := 'Validation failed';
  for lDiagnostic in ADiagnostics do
    Result := Result + LineEnding + Format('%s(%d,%d): %s: %s', [
      lDiagnostic.SourceRange.SourceName,
      lDiagnostic.SourceRange.StartPosition.Line,
      lDiagnostic.SourceRange.StartPosition.Column,
      lDiagnostic.Code,
      lDiagnostic.MessageText]);
end;

class function TNexusScriptManifest.LoadTextFile(
  const AFileName: string): string;
var
  lStream: TFileStream;
  lBytes: RawByteString;
begin
  if not FileExists(AFileName) then
    raise ENexusScriptCommand.CreateFmt('File not found: %s', [AFileName]);
  lStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(lBytes, lStream.Size);
    if Length(lBytes) > 0 then
      lStream.ReadBuffer(Pointer(lBytes)^, Length(lBytes));
    Result := string(lBytes);
  finally
    lStream.Free;
  end;
end;

class procedure TNexusScriptManifest.WriteText(AStream: TStream;
  const AValue: string);
var
  lText: UTF8String;
begin
  if AStream = nil then
    raise ENexusScriptCommand.Create('Output stream is not available.');
  lText := UTF8Encode(AValue);
  if Length(lText) > 0 then
    AStream.WriteBuffer(Pointer(lText)^, Length(lText));
end;

class procedure TNexusScriptManifest.WriteOutput(const AFileName,
  AArtifact: string; AStdOut: TStream);
var
  lDirectory: string;
  lStream: TFileStream;
begin
  if AFileName = '' then
  begin
    WriteText(AStdOut, AArtifact);
    Exit;
  end;

  lDirectory := ExtractFileDir(ExpandFileName(AFileName));
  if (lDirectory <> '') and not DirectoryExists(lDirectory) and
    not ForceDirectories(lDirectory) then
    raise ENexusScriptCommand.CreateFmt(
      'Unable to create output directory: %s', [lDirectory]);

  lStream := TFileStream.Create(AFileName, fmCreate);
  try
    WriteText(lStream, AArtifact);
  finally
    lStream.Free;
  end;
end;

class function TNexusScriptManifest.RenderTemplate(const AJSON,
  ATemplateFile: string): string;
var
  lJSONFile: string;
  lOutputFile: string;
begin
  if not FileExists(ATemplateFile) then
    raise ENexusScriptCommand.CreateFmt('File not found: %s', [ATemplateFile]);
  lJSONFile := GetTempFileName(GetTempDir, 'nsj');
  lOutputFile := GetTempFileName(GetTempDir, 'nso');
  try
    WriteOutput(lJSONFile, AJSON, nil);
    RenderMustacheFile(lJSONFile, ATemplateFile, lOutputFile);
    Result := LoadTextFile(lOutputFile);
  finally
    DeleteFile(lOutputFile);
    DeleteFile(lJSONFile);
  end;
end;

class procedure TNexusScriptManifest.ValidateDocument(
  ADocument: TNexusScriptCompiledDocument);
var
  lValidator: TNexusScriptValidator;
begin
  if ADocument.DialectDocument = nil then
    Exit;
  lValidator := TNexusScriptValidator.Create;
  try
    if not lValidator.Validate(ADocument, ADocument.DialectDocument) then
      raise ENexusScriptCommand.Create(
        ValidationFailureText(lValidator.Diagnostics));
  finally
    lValidator.Free;
  end;
end;

class function TNexusScriptManifest.ManifestOutputFile(
  const AOutputDirectory, ARelativePath: string): string;
var
  lOutputRoot: string;
begin
  if Trim(ARelativePath) = '' then
    raise ENexusScriptCommand.Create('Output path must not be empty.');
  if (ExtractFileDrive(ARelativePath) <> '') or
    (ARelativePath[1] in ['\', '/']) then
    raise ENexusScriptCommand.CreateFmt(
      'Output path must be relative: %s', [ARelativePath]);

  lOutputRoot := IncludeTrailingPathDelimiter(ExpandFileName(AOutputDirectory));
  Result := ExpandFileName(lOutputRoot + ARelativePath);
  if CompareText(Copy(Result, 1, Length(lOutputRoot)), lOutputRoot) <> 0 then
    raise ENexusScriptCommand.CreateFmt(
      'Output path escapes the output directory: %s', [ARelativePath]);
end;

class procedure TNexusScriptManifest.Render(const AManifestFile,
  AOutputDirectory, ADialectRoot: string; AValidate: Boolean);
var
  lManifestSession: TNexusScriptCompilationSession;
  lModelSessions: TObjectList<TNexusScriptCompilationSession>;
  lArtifactContexts: TObjectList<TNexusScriptArtifactContext>;
  lSourceRules: TObjectList<TNexusScriptSourceTemplateRule>;
  lSourceRenders: TObjectList<TNexusScriptSourceRender>;
  lModelSources: TStringList;
  lArtifactSources: TStringList;
  lExternalSourceNames: TStringList;
  lOutputFiles: TStringList;
  lJSONEmitter: TNexusScriptJSONEmitter;
  lDocument: TNexusScriptCompiledDocument;
  lNexusManifest: TNexusScriptCompiledDefinition;
  lModel: TNexusScriptCompiledDefinition;
  lTemplate: TNexusScriptCompiledDefinition;
  lSourceTemplate: TNexusScriptCompiledDefinition;
  lModelSession: TNexusScriptCompilationSession;
  lArtifactContext: TNexusScriptArtifactContext;
  lArtifactDocument: TNexusScriptArtifactDocument;
  lExternalSource: TNexusScriptExternalSource;
  lRule: TNexusScriptSourceTemplateRule;
  lRender: TNexusScriptSourceRender;
  lSourceProperty: TNexusScriptCompiledProperty;
  lOutputProperty: TNexusScriptCompiledProperty;
  lTypesProperty: TNexusScriptCompiledProperty;
  lTypeValue: TNexusScriptCompiledValue;
  lSourceFile: string;
  lArtifactSource: string;
  lOutputFile: string;
  lRelativeOutput: string;
  lExistingFile: string;
  lSourceType: string;
  lCompilerName: string;
  lOutputDirectory: string;
  lOutputExtension: string;
  lEntryName: string;
  lJSON: string;
  lSourceJSON: string;
  lRendered: string;
  lIndex: Integer;

  function RequiredText(ADefinition: TNexusScriptCompiledDefinition;
    const APropertyName: string): string;
  var
    lProperty: TNexusScriptCompiledProperty;
  begin
    lProperty := ADefinition.FindProperty(APropertyName);
    if (lProperty = nil) or not lProperty.Value.HasEffectiveText then
      raise ENexusScriptCommand.Create(
        APropertyName + ' must have compiled effective text.');
    Result := lProperty.Value.EffectiveText;
  end;

  function OptionalText(ADefinition: TNexusScriptCompiledDefinition;
    const APropertyName: string): string;
  var
    lProperty: TNexusScriptCompiledProperty;
  begin
    Result := '';
    lProperty := ADefinition.FindProperty(APropertyName);
    if lProperty = nil then
      Exit;
    if not lProperty.Value.HasEffectiveText then
      raise ENexusScriptCommand.Create(
        APropertyName + ' must have compiled effective text.');
    Result := lProperty.Value.EffectiveText;
  end;

  function FindSourceRule(const ASourceType: string):
    TNexusScriptSourceTemplateRule;
  var
    lCandidate: TNexusScriptSourceTemplateRule;
  begin
    Result := nil;
    for lCandidate in lSourceRules do
      if lCandidate.Types.IndexOf(ASourceType) >= 0 then
      begin
        if Result <> nil then
          raise ENexusScriptCommand.CreateFmt(
            'Source type %s matches more than one SourceTemplate.',
            [ASourceType]);
        Result := lCandidate;
      end;
  end;
begin
  lManifestSession := TNexusScriptCompilationSession.Create;
  lManifestSession.DialectRoot := ADialectRoot;
  lModelSessions := TObjectList<TNexusScriptCompilationSession>.Create(True);
  lArtifactContexts := TObjectList<TNexusScriptArtifactContext>.Create(True);
  lSourceRules := TObjectList<TNexusScriptSourceTemplateRule>.Create(True);
  lSourceRenders := TObjectList<TNexusScriptSourceRender>.Create(True);
  lModelSources := TStringList.Create;
  lArtifactSources := TStringList.Create;
  lExternalSourceNames := TStringList.Create;
  lOutputFiles := TStringList.Create;
  lJSONEmitter := TNexusScriptJSONEmitter.Create;
  try
    lModelSources.CaseSensitive := False;
    lModelSources.Sorted := True;
    lModelSources.Duplicates := dupError;
    lArtifactSources.CaseSensitive := False;
    lArtifactSources.Sorted := True;
    lArtifactSources.Duplicates := dupIgnore;
    lExternalSourceNames.CaseSensitive := False;
    lExternalSourceNames.NameValueSeparator := '=';
    lOutputFiles.CaseSensitive := False;
    lOutputFiles.Sorted := True;
    lOutputFiles.Duplicates := dupIgnore;

    if not lManifestSession.CompileFile(AManifestFile) then
      raise ENexusScriptCommand.Create(lManifestSession.LastError);
    lDocument := lManifestSession.EntryCompiler.CompiledDocument;
    if lDocument.DialectDocument = nil then
      raise ENexusScriptCommand.Create(
        'NexusScript manifest requires an explicit dialect association.');
    ValidateDocument(lDocument);

    if (lDocument.Definitions.Count <> 1) or
      not SameText(lDocument.Definitions[0].Kind, 'NexusManifest') then
      raise ENexusScriptCommand.Create(
        'NexusScript manifest requires exactly one NexusManifest root.');
    lNexusManifest := lDocument.Definitions[0];

    for lSourceTemplate in lNexusManifest.Children do
    begin
      if not SameText(lSourceTemplate.Kind, 'SourceTemplate') then
        Continue;
      lEntryName := lNexusManifest.Name + '.' + lSourceTemplate.Name;
      try
        lRule := TNexusScriptSourceTemplateRule.Create;
        lSourceRules.Add(lRule);
        lRule.Name := lEntryName;
        lCompilerName := RequiredText(lSourceTemplate, 'Compiler');
        if not TNexusScriptExternalSourceCompilerRegistry.SupportsCompiler(
          lCompilerName) then
          raise ENexusScriptCommand.CreateFmt(
            'Unknown external source compiler: %s', [lCompilerName]);
        lRule.CompilerName := lCompilerName;
        lSourceFile := RequiredText(lSourceTemplate, 'Source');
        lRule.TemplateFile := ExpandFileName(IncludeTrailingPathDelimiter(
          ExtractFileDir(ExpandFileName(AManifestFile))) + lSourceFile);
        if not FileExists(lRule.TemplateFile) then
          raise ENexusScriptCommand.CreateFmt('File not found: %s',
            [lRule.TemplateFile]);
        lOutputDirectory := OptionalText(lSourceTemplate, 'OutputDirectory');
        lRule.OutputDirectory := lOutputDirectory;
        lOutputExtension := RequiredText(lSourceTemplate, 'OutputExtension');
        if (Length(lOutputExtension) < 2) or
          (lOutputExtension[1] <> '.') or
          (Pos('/', lOutputExtension) > 0) or
          (Pos('\', lOutputExtension) > 0) then
          raise ENexusScriptCommand.CreateFmt(
            'Invalid OutputExtension: %s', [lOutputExtension]);
        lRule.OutputExtension := lOutputExtension;

        lTypesProperty := lSourceTemplate.FindProperty('Types');
        if (lTypesProperty = nil) or
          (lTypesProperty.Value.ArtifactKind <> nsavArray) or
          (lTypesProperty.Value.Items.Count = 0) then
          raise ENexusScriptCommand.Create(
            'Types must be a nonempty compiled array.');
        for lTypeValue in lTypesProperty.Value.Items do
        begin
          if not lTypeValue.ArtifactValue.HasEffectiveText then
            raise ENexusScriptCommand.Create(
              'Every Types entry must have compiled effective text.');
          lSourceType := LowerCase(lTypeValue.ArtifactValue.EffectiveText);
          if lRule.Types.IndexOf(lSourceType) >= 0 then
            raise ENexusScriptCommand.CreateFmt(
              'Source type %s is repeated in this rule.', [lSourceType]);
          if not TNexusScriptExternalSourceCompilerRegistry.CompilerSupportsType(
            lCompilerName, lSourceType) then
            raise ENexusScriptCommand.CreateFmt(
              'Compiler %s does not support source type %s.',
              [lCompilerName, lSourceType]);
          if FindSourceRule(lSourceType) <> nil then
            raise ENexusScriptCommand.CreateFmt(
              'Source type %s is assigned to more than one SourceTemplate.',
              [lSourceType]);
          lRule.Types.Add(lSourceType);
        end;
      except
        on E: Exception do
          raise ENexusScriptCommand.CreateFmt(
            'Manifest entry %s failed: %s', [lEntryName, E.Message]);
      end;
    end;

    for lTemplate in lNexusManifest.Children do
    begin
      if not SameText(lTemplate.Kind, 'Template') then
        Continue;
      lEntryName := lNexusManifest.Name + '.' + lTemplate.Name;
      try
        lOutputFile := ManifestOutputFile(AOutputDirectory,
          RequiredText(lTemplate, 'Output'));
        lOutputFiles.Add(lOutputFile);
      except
        on E: Exception do
          raise ENexusScriptCommand.CreateFmt(
            'Manifest entry %s failed: %s', [lEntryName, E.Message]);
      end;
    end;

    for lModel in lNexusManifest.Children do
    begin
      if not SameText(lModel.Kind, 'Model') then
        Continue;
      lEntryName := lNexusManifest.Name + '.' + lModel.Name;
      try
        lSourceProperty := lModel.FindProperty('Source');
        if (lSourceProperty = nil) or
          not lSourceProperty.Value.HasEffectiveText then
          raise ENexusScriptCommand.Create(
            'Source must have compiled effective text.');
        lSourceFile := ExpandFileName(IncludeTrailingPathDelimiter(
          ExtractFileDir(ExpandFileName(AManifestFile))) +
          lSourceProperty.Value.EffectiveText);
        if lModelSources.IndexOf(lSourceFile) >= 0 then
          raise ENexusScriptCommand.CreateFmt(
            'Model source is declared more than once: %s', [lSourceFile]);
        lModelSources.Add(lSourceFile);

        lModelSession := TNexusScriptCompilationSession.Create;
        lModelSession.DialectRoot := ADialectRoot;
        lModelSessions.Add(lModelSession);
        if not lModelSession.CompileFile(lSourceFile) then
          raise ENexusScriptCommand.Create(lModelSession.LastError);
        if AValidate then
          ValidateDocument(lModelSession.EntryCompiler.CompiledDocument);

        lArtifactContext := TNexusScriptArtifactContext.Create(lModelSession);
        lArtifactContexts.Add(lArtifactContext);
        lArtifactContext.Build;
        for lArtifactDocument in lArtifactContext.ArtifactDocuments do
        begin
          lArtifactSource := ExpandFileName(
            lArtifactDocument.SourceDocument.SourceName);
          if lArtifactSources.IndexOf(lArtifactSource) >= 0 then
            Continue;
          lArtifactSources.Add(lArtifactSource);
          lJSONEmitter.AddDocument(lArtifactDocument.CompiledDocument);
        end;
      except
        on E: Exception do
          raise ENexusScriptCommand.CreateFmt(
            'Manifest entry %s failed: %s', [lEntryName, E.Message]);
      end;
    end;
    lJSON := lJSONEmitter.JSON;

    for lArtifactContext in lArtifactContexts do
      for lExternalSource in lArtifactContext.ExternalSources do
      begin
        lIndex := lExternalSourceNames.IndexOfName(lExternalSource.Name);
        if lIndex >= 0 then
        begin
          lExistingFile := lExternalSourceNames.ValueFromIndex[lIndex];
          if SameFileName(lExistingFile, lExternalSource.FileName) then
            Continue;
          raise ENexusScriptCommand.CreateFmt(
            'External data source %s resolves to both %s and %s.',
            [lExternalSource.Name, lExistingFile,
            lExternalSource.FileName]);
        end;
        lExternalSourceNames.Add(lExternalSource.Name + '=' +
          lExternalSource.FileName);
        if not FileExists(lExternalSource.FileName) then
          raise ENexusScriptCommand.CreateFmt(
            'External data source file not found: %s',
            [lExternalSource.FileName]);
        lRule := FindSourceRule(lExternalSource.SourceType);
        if lRule = nil then
          raise ENexusScriptCommand.CreateFmt(
            'No SourceTemplate matches external data source %s of type %s.',
            [lExternalSource.Name, lExternalSource.SourceType]);
        lRelativeOutput := ChangeFileExt(
          ExtractFileName(lExternalSource.FileName),
          lRule.OutputExtension);
        if lRule.OutputDirectory <> '' then
          lRelativeOutput := IncludeTrailingPathDelimiter(
            lRule.OutputDirectory) + lRelativeOutput;
        lOutputFile := ManifestOutputFile(AOutputDirectory, lRelativeOutput);
        if lOutputFiles.IndexOf(lOutputFile) >= 0 then
          raise ENexusScriptCommand.CreateFmt(
            'Generated output collision at %s for external data source %s.',
            [lOutputFile, lExternalSource.Name]);
        lOutputFiles.Add(lOutputFile);
        lSourceRenders.Add(TNexusScriptSourceRender.Create(
          lExternalSource, lRule, lOutputFile));
      end;

    for lTemplate in lNexusManifest.Children do
    begin
      if not SameText(lTemplate.Kind, 'Template') then
        Continue;
      lEntryName := lNexusManifest.Name + '.' + lTemplate.Name;
      try
        lSourceProperty := lTemplate.FindProperty('Source');
        lOutputProperty := lTemplate.FindProperty('Output');
        if (lSourceProperty = nil) or
          not lSourceProperty.Value.HasEffectiveText then
          raise ENexusScriptCommand.Create(
            'Source must have compiled effective text.');
        if (lOutputProperty = nil) or
          not lOutputProperty.Value.HasEffectiveText then
          raise ENexusScriptCommand.Create(
            'Output must have compiled effective text.');

        lSourceFile := ExpandFileName(IncludeTrailingPathDelimiter(
          ExtractFileDir(ExpandFileName(AManifestFile))) +
          lSourceProperty.Value.EffectiveText);
        lOutputFile := ManifestOutputFile(AOutputDirectory,
          lOutputProperty.Value.EffectiveText);
        lRendered := RenderTemplate(lJSON, lSourceFile);
        WriteOutput(lOutputFile, lRendered, nil);
      except
        on E: Exception do
          raise ENexusScriptCommand.CreateFmt(
            'Manifest entry %s failed: %s', [lEntryName, E.Message]);
      end;
    end;

    for lRender in lSourceRenders do
    begin
      try
        lSourceJSON := TNexusScriptExternalSourceCompilerRegistry.Compile(
          lRender.Rule.CompilerName, lRender.Source);
        lRendered := RenderTemplate(lSourceJSON,
          lRender.Rule.TemplateFile);
        WriteOutput(lRender.OutputFile, lRendered, nil);
      except
        on E: Exception do
          raise ENexusScriptCommand.CreateFmt(
            'Manifest source %s (%s) failed through %s: %s',
            [lRender.Source.Name, lRender.Source.FileName,
            lRender.Rule.Name, E.Message]);
      end;
    end;
  finally
    lJSONEmitter.Free;
    lOutputFiles.Free;
    lExternalSourceNames.Free;
    lArtifactSources.Free;
    lModelSources.Free;
    lSourceRenders.Free;
    lSourceRules.Free;
    lArtifactContexts.Free;
    lModelSessions.Free;
    lManifestSession.Free;
  end;
end;

end.

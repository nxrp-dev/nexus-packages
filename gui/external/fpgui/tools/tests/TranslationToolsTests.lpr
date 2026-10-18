// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program TranslationToolsTests;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, Process, obNXTestContext, obNXTestRegistry,
  obNXTestSuite, utNXTestConsole;

procedure RemoveFixtureFile(const AFileName: string);
begin
  if FileExists(AFileName) and not DeleteFile(AFileName) then
    raise EInOutError.Create('Cannot remove fixture: ' + AFileName);
end;

procedure RemoveFixtureDirectory(const ADirectory: string);
begin
  if DirectoryExists(ADirectory) and not RemoveDir(ADirectory) then
    raise EInOutError.Create('Cannot remove fixture directory: ' + ADirectory);
end;

procedure TestHeaderWithoutComment(AContext: TNXTestContext);
var
  lID: TGUID;
  lDirectory, lIncludeFile: string;
  lLines: TStringList;
  lProcess: TProcess;
begin
  AContext.AssertTrue((ParamCount = 1) and FileExists(ParamStr(1)),
    'Pass the include-generator executable as the first argument');
  CreateGUID(lID);
  lDirectory := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    'nexus-po-' + GUIDToString(lID);
  lIncludeFile := lDirectory + '/src/corelib/lang_fr.inc';
  lLines := TStringList.Create;
  try
    ForceDirectories(lDirectory + '/languages');
    ForceDirectories(lDirectory + '/src/corelib');
    lLines.Text := 'Fixture';
    lLines.SaveToFile(lDirectory + '/AUTHORS.txt');
    lLines.Text :=
      'msgid ""' + LineEnding +
      'msgstr ""' + LineEnding +
      '"Language: fr\n"' + LineEnding + LineEnding +
      '#: fpgui:rsOne' + LineEnding +
      'msgid "One"' + LineEnding +
      'msgstr "Un"' + LineEnding;
    lLines.SaveToFile(lDirectory + '/languages/fpgui.fr.po');
    lProcess := TProcess.Create(nil);
    try
      lProcess.Executable := ExpandFileName(ParamStr(1));
      lProcess.Parameters.Add(lDirectory);
      lProcess.Options := [poWaitOnExit];
      lProcess.Execute;
      AContext.AssertEquals(0, lProcess.ExitStatus,
        'An uncommented PO header must not crash the include generator');
    finally
      lProcess.Free;
    end;
    AContext.AssertTrue(FileExists(lIncludeFile));
    lLines.LoadFromFile(lIncludeFile);
    AContext.AssertTrue(Pos('rsOne  =  ''Un'';', lLines.Text) > 0);
  finally
    lLines.Free;
    RemoveFixtureFile(lIncludeFile);
    RemoveFixtureFile(lDirectory + '/languages/fpgui.fr.po');
    RemoveFixtureFile(lDirectory + '/AUTHORS.txt');
    RemoveFixtureDirectory(lDirectory + '/src/corelib');
    RemoveFixtureDirectory(lDirectory + '/src');
    RemoveFixtureDirectory(lDirectory + '/languages');
    RemoveFixtureDirectory(lDirectory);
  end;
end;

var
  lRegistry: TNXTestRegistry;
  lSuite: TNXTestSuite;
begin
  lRegistry := TNXTestRegistry.Create;
  try
    lSuite := lRegistry.AddSuite('TranslationTools');
    lSuite.AddTest('HeaderWithoutComment', @TestHeaderWithoutComment);
    ExitCode := RunConsoleTests(lRegistry);
  finally
    lRegistry.Free;
  end;
end.

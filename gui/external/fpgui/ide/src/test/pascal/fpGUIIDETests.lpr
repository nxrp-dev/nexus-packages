// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program fpGUIIDETests;
{$mode objfpc}{$H+}
uses
  {$IFDEF UNIX}cthreads, cwstring,{$ENDIF}
  obNXTestRegistry, utNXTestConsole,
  ide.test.pascal.tokeniser,
  ide.test.highlighter,
  ide.test.navigation,
  ide.test.editor.tabs,
  ide.test.declaration,
  ide.test.projecttree,
  ide.test.profiles,
  ide.test.runner,
  ide.test.highlighter.xml,
  ide.test.cursorhistory,
  ide.test.editortheme,
  ide.test.callstack,
  ide.test.filefinder,
  ide.test.watches,
  ide.test.highlighter.ini,
  ide.test.editor.blockindent,
  ide.test.bracketmatch,
  ide.test.variables,
  ide.test.breakpoint,
  ide.test.symbolfinder,
  ide.test.build.dispatch,
  ide.test.highlight.renderer,
  ide.test.editor.undo;
var
  lRegistry: TNXTestRegistry;
begin
  lRegistry := TNXTestRegistry.Create;
  try
    RegisteridetestpascaltokeniserTests(lRegistry);
    RegisteridetesthighlighterTests(lRegistry);
    RegisteridetestnavigationTests(lRegistry);
    RegisteridetesteditortabsTests(lRegistry);
    RegisteridetestdeclarationTests(lRegistry);
    RegisteridetestprojecttreeTests(lRegistry);
    RegisteridetestprofilesTests(lRegistry);
    RegisteridetestrunnerTests(lRegistry);
    RegisteridetesthighlighterxmlTests(lRegistry);
    RegisteridetestcursorhistoryTests(lRegistry);
    RegisteridetesteditorthemeTests(lRegistry);
    RegisteridetestcallstackTests(lRegistry);
    RegisteridetestfilefinderTests(lRegistry);
    RegisteridetestwatchesTests(lRegistry);
    RegisteridetesthighlighteriniTests(lRegistry);
    RegisteridetesteditorblockindentTests(lRegistry);
    RegisteridetestbracketmatchTests(lRegistry);
    RegisteridetestvariablesTests(lRegistry);
    RegisteridetestbreakpointTests(lRegistry);
    RegisteridetestsymbolfinderTests(lRegistry);
    RegisteridetestbuilddispatchTests(lRegistry);
    RegisteridetesthighlightrendererTests(lRegistry);
    RegisteridetesteditorundoTests(lRegistry);
    ExitCode := RunConsoleTests(lRegistry);
  finally
    lRegistry.Free;
  end;
end.

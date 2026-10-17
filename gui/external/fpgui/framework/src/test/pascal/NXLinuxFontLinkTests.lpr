// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program NXLinuxFontLinkTests;
{$mode objfpc}{$H+}
uses
  {$IFDEF UNIX}cthreads, cwstring,{$ENDIF}
  freetypeh, agg_font_freetype_lib,
  obNXTestRegistry, obNXTestSuite, obNXTestContext, utNXTestConsole;

procedure TestFCLStaticRuntime(AContext: TNXTestContext);
var lLibrary: freetypeh.PFT_Library;
begin
  lLibrary := nil;
  AContext.AssertEquals(0, freetypeh.FT_Init_FreeType(lLibrary));
  try
    AContext.AssertTrue(lLibrary <> nil);
  finally
    AContext.AssertEquals(0, freetypeh.FT_Done_FreeType(lLibrary));
  end;
end;

procedure TestAGGStaticRuntime(AContext: TNXTestContext);
var lLibrary: agg_font_freetype_lib.FT_Library_ptr;
begin
  lLibrary := nil;
  AContext.AssertEquals(0, agg_font_freetype_lib.FT_Init_FreeType(lLibrary));
  try
    AContext.AssertTrue(lLibrary <> nil);
  finally
    AContext.AssertEquals(0, agg_font_freetype_lib.FT_Done_FreeType(lLibrary));
  end;
end;

var
  lRegistry: TNXTestRegistry;
  lSuite: TNXTestSuite;
begin
  lRegistry := TNXTestRegistry.Create;
  try
    lSuite := lRegistry.AddSuite('LinuxFontBindings');
    lSuite.AddTest('FCLStaticRuntime', @TestFCLStaticRuntime);
    lSuite.AddTest('AGGStaticRuntime', @TestAGGStaticRuntime);
    ExitCode := RunConsoleTests(lRegistry);
  finally
    lRegistry.Free;
  end;
end.

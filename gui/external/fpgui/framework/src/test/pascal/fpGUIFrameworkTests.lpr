// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program fpGUIFrameworkTests;
{$mode objfpc}{$H+}
uses
  {$IFDEF UNIX}cthreads, cwstring,{$ENDIF}
  obNXTestRegistry, utNXTestConsole,
  fpg_main,
  tcmig_platformdefaults,
  tcmig_resizeconstraint,
  tcmig_boundsize,
  tcprocessmessages,
  tcfontmanager,
  tcfpgbase,
  tcmig_layoututil,
  tccanvasblit,
  tcasynctask,
  tcmenuaccel,
  tcspinedit,
  tcmig_ac,
  tchvif,
  tcmig_grid,
  tcpropertyread,
  tcgridstretch,
  tctimer,
  tcmig_constraintparser,
  tclayoutmanager,
  tcmig_dimconstraint,
  tcmig_cc,
  tcmig_quickstart,
  tchvif_writer,
  tcborderlayout,
  tcaccelerator,
  tcTreeview,
  tcmiglayout,
  CsvParser_Test,
  tcmig_lc,
  tcmsgcoalesce,
  tcfontcacheremoval,
  tcflowlayout,
  tcfontdefinition,
  tchybridcanvas,
  tcmig_linkhandler,
  tcmig_unitvalue;
var
  lRegistry: TNXTestRegistry;
begin
  fpgApplication.Initialize;
  lRegistry := TNXTestRegistry.Create;
  try
    RegistertcmigplatformdefaultsTests(lRegistry);
    RegistertcmigresizeconstraintTests(lRegistry);
    RegistertcmigboundsizeTests(lRegistry);
    RegistertcprocessmessagesTests(lRegistry);
    RegistertcfontmanagerTests(lRegistry);
    RegistertcfpgbaseTests(lRegistry);
    RegistertcmiglayoututilTests(lRegistry);
    RegistertccanvasblitTests(lRegistry);
    RegistertcasynctaskTests(lRegistry);
    RegistertcmenuaccelTests(lRegistry);
    RegistertcspineditTests(lRegistry);
    RegistertcmigacTests(lRegistry);
    RegistertchvifTests(lRegistry);
    RegistertcmiggridTests(lRegistry);
    RegistertcpropertyreadTests(lRegistry);
    RegistertcgridstretchTests(lRegistry);
    RegistertctimerTests(lRegistry);
    RegistertcmigconstraintparserTests(lRegistry);
    RegistertclayoutmanagerTests(lRegistry);
    RegistertcmigdimconstraintTests(lRegistry);
    RegistertcmigccTests(lRegistry);
    RegistertcmigquickstartTests(lRegistry);
    RegistertchvifwriterTests(lRegistry);
    RegistertcborderlayoutTests(lRegistry);
    RegistertcacceleratorTests(lRegistry);
    RegistertcTreeviewTests(lRegistry);
    RegistertcmiglayoutTests(lRegistry);
    RegisterCsvParserTestTests(lRegistry);
    RegistertcmiglcTests(lRegistry);
    RegistertcmsgcoalesceTests(lRegistry);
    RegistertcfontcacheremovalTests(lRegistry);
    RegistertcflowlayoutTests(lRegistry);
    RegistertcfontdefinitionTests(lRegistry);
    RegistertchybridcanvasTests(lRegistry);
    RegistertcmiglinkhandlerTests(lRegistry);
    RegistertcmigunitvalueTests(lRegistry);
    ExitCode := RunConsoleTests(lRegistry);
  finally
    lRegistry.Free;
  end;
end.

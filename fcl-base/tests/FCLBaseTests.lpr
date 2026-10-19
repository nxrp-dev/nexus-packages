// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program FCLBaseTests;
{$mode objfpc}{$H+}
uses
  {$IFDEF UNIX}cthreads, cwstring,{$ENDIF}
  obNXTestRegistry, utNXTestConsole,
  utcchainstream,
  utcdirwatch,
  tsNXOrderedContainers,
  utcbasenenc,
  utcBufferedFileStream,
  utcClassList,
  utcComponentList,
  utcCSVDocument,
  utcCSVReadWrite,
  utcExprBuiltin,
  utcExprParsAggr,
  utcExprParsNodes,
  utcexprparsops,
  utcExprParsParser,
  utcExprParsScanner,
  utcFPHashObjectList,
  utcFPObjectHashTable,
  utcfpobjectlist,
  utcFPStringHashTable,
  utcFPTemplate,
  utcIniFile,
  utcinterlocked,
  utcLZW,
  utcMaskUtils,
  utcObjectList;
var
  lRegistry: TNXTestRegistry;
begin
  lRegistry := TNXTestRegistry.Create;
  try
    RegisterutcchainstreamTests(lRegistry);
    RegisterutcdirwatchTests(lRegistry);
    RegisterOrderedContainerTests(lRegistry);
    RegisterutcbasenencTests(lRegistry);
    RegisterutcBufferedFileStreamTests(lRegistry);
    RegisterutcClassListTests(lRegistry);
    RegisterutcComponentListTests(lRegistry);
    RegisterutcCSVDocumentTests(lRegistry);
    RegisterutcCSVReadWriteTests(lRegistry);
    RegisterutcExprBuiltinTests(lRegistry);
    RegisterutcExprParsAggrTests(lRegistry);
    RegisterutcExprParsNodesTests(lRegistry);
    RegisterutcexprparsopsTests(lRegistry);
    RegisterutcExprParsParserTests(lRegistry);
    RegisterutcExprParsScannerTests(lRegistry);
    RegisterutcFPHashObjectListTests(lRegistry);
    RegisterutcFPObjectHashTableTests(lRegistry);
    RegisterutcfpobjectlistTests(lRegistry);
    RegisterutcFPStringHashTableTests(lRegistry);
    RegisterutcFPTemplateTests(lRegistry);
    RegisterutcIniFileTests(lRegistry);
    RegisterutcinterlockedTests(lRegistry);
    RegisterutcLZWTests(lRegistry);
    RegisterutcMaskUtilsTests(lRegistry);
    RegisterutcObjectListTests(lRegistry);
    ExitCode := RunConsoleTests(lRegistry);
  finally
    lRegistry.Free;
  end;
end.

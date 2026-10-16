// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit tsFCLImageTests;

{$mode objfpc}{$H+}

interface

uses obNXTestRegistry;

procedure RegisterFCLImageTests(ARegistry: TNXTestRegistry);

implementation

uses
  Classes, SysUtils, Process, {$IFDEF UNIX}BaseUnix,{$ENDIF}
  obNXTestContext, obNXTestSuite;

procedure RemoveProbeDirectory(const ADirectory: string);
var
  lSearch: TSearchRec;
  lPath: string;
begin
  if FindFirst(IncludeTrailingPathDelimiter(ADirectory) + '*', faAnyFile,
    lSearch) = 0 then
  try
    repeat
      if (lSearch.Name = '.') or (lSearch.Name = '..') then
        Continue;
      lPath := IncludeTrailingPathDelimiter(ADirectory) + lSearch.Name;
      if (lSearch.Attr and faDirectory) <> 0 then
        RemoveProbeDirectory(lPath)
      else
        DeleteFile(lPath);
    until FindNext(lSearch) <> 0;
  finally
    FindClose(lSearch);
  end;
  RemoveDir(ADirectory);
end;

procedure RunProbe(AContext: TNXTestContext; AId: Integer);
var
  lDirectory, lFixture, lResultPath: string;
  lProcess: TProcess;
  lResult: TStringList;
  lFinished: Boolean;
  lTimeout: Integer;
begin
  lFixture := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'FCLImageFixture' + {$IFDEF MSWINDOWS}'.exe'{$ELSE}''{$ENDIF};
  AContext.AssertTrue(FileExists(lFixture), 'Missing fixture: ' + lFixture);
  lDirectory := GetTempFileName(GetTempDir(False), 'fcli');
  DeleteFile(lDirectory);
  ForceDirectories(lDirectory);
  lResultPath := IncludeTrailingPathDelimiter(lDirectory) + 'result.txt';
  lProcess := TProcess.Create(nil);
  lResult := TStringList.Create;
  try
    lProcess.Executable := lFixture;
    lProcess.Parameters.Add('--probe');
    lProcess.Parameters.Add(IntToStr(AId));
    lProcess.Parameters.Add(lResultPath);
    lProcess.Parameters.Add(lDirectory);
    lTimeout:=30000;
    lProcess.Execute;
    lFinished := lProcess.WaitOnExit(lTimeout);
    {$IFDEF UNIX}
    // The probe creates its own session; descendants stay in its process group.
    fpKill(-lProcess.ProcessID, SIGKILL);
    if not lFinished then
    begin
      fpKill(lProcess.ProcessID, SIGKILL);
      lProcess.WaitOnExit;
    end;
    {$ELSE}
    if not lFinished then
    begin
      lProcess.Terminate(1);
      lProcess.WaitOnExit;
    end;
    {$ENDIF}
    AContext.AssertTrue(lFinished,
      Format('Probe exceeded its %d-second deadline.',[lTimeout div 1000]));
    AContext.AssertTrue(FileExists(lResultPath),
      'Probe exited without a result; process status ' + IntToStr(lProcess.ExitStatus));
    lResult.LoadFromFile(lResultPath);
    AContext.AssertTrue(lResult.Count > 0, 'Probe produced an empty result.');
    if lResult[0] = 'skipped' then
      AContext.Skip(Trim(Copy(lResult.Text, Length(lResult[0]) + 1, MaxInt)));
    if FileExists(IncludeTrailingPathDelimiter(lDirectory)+'heap.txt') and
      (lResult[0]='passed') then
      lResult.LoadFromFile(IncludeTrailingPathDelimiter(lDirectory)+'heap.txt');
    AContext.AssertEquals(0, lProcess.ExitStatus, 'Fixture heap/process failure: '+lResult.Text);
    lResult.LoadFromFile(lResultPath);
    AContext.AssertEquals('passed', lResult[0], Trim(lResult.Text));
  finally
    lResult.Free;
    lProcess.Free;
    RemoveProbeDirectory(lDirectory);
  end;
end;

procedure Test01(AContext: TNXTestContext); begin RunProbe(AContext, 1); end;
procedure Test02(AContext: TNXTestContext); begin RunProbe(AContext, 2); end;
procedure Test03(AContext: TNXTestContext); begin RunProbe(AContext, 3); end;
procedure Test04(AContext: TNXTestContext); begin RunProbe(AContext, 4); end;
procedure Test05(AContext: TNXTestContext); begin RunProbe(AContext, 5); end;
procedure Test06(AContext: TNXTestContext); begin RunProbe(AContext, 6); end;
procedure Test07(AContext: TNXTestContext); begin RunProbe(AContext, 7); end;
procedure Test08(AContext: TNXTestContext); begin RunProbe(AContext, 8); end;
procedure Test09(AContext: TNXTestContext); begin RunProbe(AContext, 9); end;
procedure Test10(AContext: TNXTestContext); begin RunProbe(AContext, 10); end;
procedure Test11(AContext: TNXTestContext); begin RunProbe(AContext, 11); end;
procedure Test12(AContext: TNXTestContext); begin RunProbe(AContext, 12); end;
procedure Test13(AContext: TNXTestContext); begin RunProbe(AContext, 13); end;

procedure Test14(AContext: TNXTestContext); begin RunProbe(AContext, 14); end;
procedure Test15(AContext: TNXTestContext); begin RunProbe(AContext, 15); end;

procedure Test16(AContext: TNXTestContext); begin RunProbe(AContext, 16); end;

procedure Test17(AContext: TNXTestContext); begin RunProbe(AContext, 17); end;

procedure Test18(AContext: TNXTestContext); begin RunProbe(AContext, 18); end;

procedure RegisterFCLImageTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('FCLImage.Review');
  lSuite.AddTest('01InitialQOIIndex',@Test01);
  lSuite.AddTest('02QOIModuloArithmetic',@Test02);
  lSuite.AddTest('03MalformedQOI',@Test03);
  lSuite.AddTest('04PNMSampleOrder',@Test04);
  lSuite.AddTest('05PNMAutomaticDepth',@Test05);
  lSuite.AddTest('06PNMAsciiBoundaries',@Test06);
  lSuite.AddTest('07PCXPaletteRange',@Test07);
  lSuite.AddTest('08PCXMalformedRows',@Test08);
  lSuite.AddTest('09TGAPixelPrecision',@Test09);
  lSuite.AddTest('10TGAReaderReuse',@Test10);
  lSuite.AddTest('11ShortOutputWrites',@Test11);
  lSuite.AddTest('12PCXEvenStride',@Test12);
  lSuite.AddTest('13TGAMalformedInput',@Test13);
  lSuite.AddTest('14PNMReaderReuse',@Test14);
  lSuite.AddTest('15TGAHorizontalOrigin',@Test15);
  lSuite.AddTest('16BMPOddWidthRLE4',@Test16);
  lSuite.AddTest('17BMPRLE4Padding',@Test17);
  lSuite.AddTest('18LinuxFreeTypeRuntime',@Test18);
end;

end.

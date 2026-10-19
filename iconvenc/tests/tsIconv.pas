// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit tsIconv;
{$mode objfpc}{$H+}
interface
uses obNXTestRegistry;
procedure RegisterIconvTests(ARegistry: TNXTestRegistry);
implementation
uses SysUtils, ctypes, dl, iconvenc, iconvenc_dyn, obNXTestContext, obNXTestSuite;

function Convert(AContext: TNXTestContext; const AInput, AFrom, ATo: AnsiString;
  var AOutput: AnsiString): cint;
var lError: AnsiString;
begin
  if Pos('.Dynamic.', AContext.Result.TestId) > 0 then
  begin
    AContext.AssertTrue(iconvenc_dyn.InitIconv(lError), lError);
    Result := iconvenc_dyn.Iconvert(AInput, AOutput, AFrom, ATo);
  end
  else Result := iconvenc.Iconvert(AInput, AOutput, AFrom, ATo);
end;

procedure EmptyInput(AContext: TNXTestContext);
var lOutput: AnsiString;
begin
  lOutput := 'old contents';
  AContext.AssertEquals(0, Convert(AContext, '', 'UTF-8', 'UTF-16LE', lOutput));
  AContext.AssertEquals('', lOutput, 'Empty input produces empty output');
end;

procedure ExpandInput(AContext: TNXTestContext);
var lOutput, lExpected: AnsiString;
begin
  lExpected := #$41#0#0#0#$E9#0#0#0;
  AContext.AssertEquals(0, Convert(AContext, 'A' + #$E9, 'ISO-8859-1', 'UTF-32LE', lOutput));
  AContext.AssertEquals(lExpected, lOutput, 'Conversion expands beyond its initial allocation');
end;

procedure ShrinkInput(AContext: TNXTestContext);
var lOutput: AnsiString; lIndex: Integer;
begin
  for lIndex := 1 to 1000 do
  begin
    AContext.AssertEquals(0, Convert(AContext, #$C3#$A9, 'UTF-8', 'ISO-8859-1', lOutput));
    AContext.AssertEquals(AnsiString(#$E9), lOutput, 'Shrinking conversion retains the produced byte');
  end;
end;

procedure StatefulFlush(AContext: TNXTestContext);
var lOutput: AnsiString;
begin
  AContext.AssertEquals(0, Convert(AContext, #$E3#$81#$82, 'UTF-8', 'ISO-2022-JP', lOutput));
  AContext.AssertEquals(AnsiString(#$1B'$B$'#$22#$1B'(B'), lOutput, 'Flush emits the final shift back to ASCII');
end;

procedure InvalidByteAtBoundary(AContext: TNXTestContext);
var lOutput, lExpected: AnsiString;
begin
  // The valid prefix exactly fills the first output buffer before the bad byte.
  lExpected := #$41#0#0#0#$FF#$FF#$FF;
  AContext.AssertEquals(0, Convert(AContext, 'A' + #$FF#$FF#$FF, 'UTF-8', 'UTF-32LE', lOutput));
  AContext.AssertEquals(lExpected, lOutput, 'Invalid input byte is retained without overwriting the output allocation');
end;

procedure IncompleteSequence(AContext: TNXTestContext);
var lOutput: AnsiString;
begin
  AContext.AssertTrue(Convert(AContext, 'A' + #$C3, 'UTF-8', 'UTF-16LE', lOutput) <> 0,
    'Truncated UTF-8 sequence reports failure');
end;

procedure UnknownEncoding(AContext: TNXTestContext);
var lOutput: AnsiString;
begin
  AContext.AssertTrue(Convert(AContext, 'unchanged', 'NXTEST-NOT-AN-ENCODING', 'UTF-8', lOutput) <> 0,
    'Unknown encoding reports failure');
  AContext.AssertEquals('unchanged', lOutput, 'Failed open retains original input');
end;

function IncompleteLibrary: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'native/a.out';
end;

procedure FailedLoadPreservesConverter(AContext: TNXTestContext);
var lError, lOutput: AnsiString;
begin
  AContext.AssertTrue(iconvenc_dyn.InitIconv(lError), lError);
  AContext.AssertTrue(FileExists(IncompleteLibrary), 'Incomplete library fixture was built');
  AContext.AssertFalse(iconvenc_dyn.TryLoadLib(IncompleteLibrary, lError), 'Incomplete library is rejected');
  AContext.AssertTrue(Assigned(iconvenc_dyn.iconv_open) and Assigned(iconvenc_dyn.iconv) and
    Assigned(iconvenc_dyn.iconv_close), 'A rejected library does not replace working function pointers');
  AContext.AssertEquals(0, iconvenc_dyn.Iconvert('hello', lOutput, 'UTF-8', 'UTF-8'));
  AContext.AssertEquals('hello', lOutput, 'Working converter remains usable after rejection');
end;

procedure RejectedHandleClosed(AContext: TNXTestContext);
const cRTLD_NOLOAD = 4;
var lError: AnsiString; lHandle: Pointer;
begin
  AContext.AssertTrue(FileExists(IncompleteLibrary), 'Incomplete library fixture was built');
  AContext.AssertFalse(iconvenc_dyn.TryLoadLib(IncompleteLibrary, lError), 'Incomplete library is rejected');
  lHandle := dlopen(PAnsiChar(IncompleteLibrary), RTLD_NOW or cRTLD_NOLOAD);
  if lHandle <> nil then dlclose(lHandle);
  AContext.AssertTrue(lHandle = nil, 'Rejected library handle is released');
end;

procedure RegisterIconvTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite; lVariant: string;
begin
  for lVariant in ['Static', 'Dynamic'] do
  begin
    lSuite := ARegistry.AddSuite('Unix.Iconv.' + lVariant);
    lSuite.AddTest('EmptyInput', @EmptyInput, 'encoding');
    lSuite.AddTest('ExpandInput', @ExpandInput, 'encoding');
    lSuite.AddTest('ShrinkInput', @ShrinkInput, 'encoding');
    lSuite.AddTest('StatefulFlush', @StatefulFlush, 'encoding');
    lSuite.AddTest('InvalidByteAtBoundary', @InvalidByteAtBoundary, 'encoding');
    lSuite.AddTest('IncompleteSequence', @IncompleteSequence, 'encoding');
    lSuite.AddTest('UnknownEncoding', @UnknownEncoding, 'encoding');
  end;
  lSuite := ARegistry.AddSuite('Unix.Iconv.Loading');
  lSuite.AddTest('FailedLoadPreservesConverter', @FailedLoadPreservesConverter, 'native-loading');
  lSuite.AddTest('RejectedHandleClosed', @RejectedHandleClosed, 'native-loading');
end;
end.

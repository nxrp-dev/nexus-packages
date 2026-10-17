// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
program PasJPEGFixture;
{$mode objfpc}{$H+}
uses HeapTrc, Classes, SysUtils, PasJPEG;
var
  lInput, lOutput: TFileStream;
begin
  HaltOnNotReleased := True;
  GlobalSkipIfNoLeaks := True;
  if (ParamCount <> 3) or
    ((ParamStr(1) <> 'encode') and (ParamStr(1) <> 'decode')) then
    raise Exception.Create('Usage: PasJPEGFixture encode|decode input output');
  lInput := TFileStream.Create(ParamStr(2), fmOpenRead or fmShareDenyWrite);
  try
    lOutput := TFileStream.Create(ParamStr(3), fmCreate);
    try
      if ParamStr(1) = 'encode' then
        StoreJPEG(lInput, lOutput, True, 95, nil)
      else
        LoadJPEG(lInput, lOutput, True, 0, nil);
    finally
      lOutput.Free;
    end;
  finally
    lInput.Free;
  end;
end.

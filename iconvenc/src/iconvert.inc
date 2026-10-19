{$ifndef Unix}
 {$define noerrnoiconv}
{$endif}

function Iconvert(AInput: AnsiString; var AOutput: AnsiString;
  const AFromEncoding, AToEncoding: AnsiString): cint;
var
  lInputLeft, lOutputLeft, lConverted: size_t;
  lSource, lDestination: PAnsiChar;
  lHandle: iconv_t;
  {$ifndef noerrnoiconv}lError: cint;{$endif}

  procedure GrowOutput;
  var lWritten: size_t;
  begin
    lWritten := lDestination - PAnsiChar(AOutput);
    SetLength(AOutput, Length(AOutput) + lInputLeft * 2 + 8);
    lDestination := PAnsiChar(AOutput) + lWritten;
    lOutputLeft := Length(AOutput) - lWritten;
  end;

begin
  lHandle := iconv_open(PAnsiChar(AToEncoding), PAnsiChar(AFromEncoding));
  if lHandle = iconv_t(-1) then
  begin
    AOutput := AInput;
    Exit(-1);
  end;
  try
    lInputLeft := Length(AInput);
    {$ifdef noerrnoiconv}
    lOutputLeft := lInputLeft * 4 + 15;
    {$else}
    lOutputLeft := lInputLeft;
    {$endif}
    SetLength(AOutput, lOutputLeft);
    lSource := PAnsiChar(AInput);
    lDestination := PAnsiChar(AOutput);
    while lInputLeft > 0 do
    begin
      lConverted := iconv(lHandle, @lSource, @lInputLeft, @lDestination, @lOutputLeft);
      if lConverted <> size_t(-1) then Continue;
      {$ifdef noerrnoiconv}
      AOutput := AInput;
      Exit(-1);
      {$else}
      lError := cerrno;
      if lError = ESysE2BIG then GrowOutput
      else if lError = ESysEILSEQ then
      begin
        if lOutputLeft = 0 then GrowOutput;
        lDestination^ := lSource^;
        Inc(lSource);
        Inc(lDestination);
        Dec(lInputLeft);
        Dec(lOutputLeft);
      end
      else
      begin
        AOutput := AInput;
        Exit(-1);
      end;
      {$endif}
    end;
    repeat
      lConverted := iconv(lHandle, nil, nil, @lDestination, @lOutputLeft);
      if lConverted <> size_t(-1) then Break;
      {$ifndef noerrnoiconv}
      if cerrno = ESysE2BIG then GrowOutput
      else
      {$endif}
      begin
        AOutput := AInput;
        Exit(-1);
      end;
    until False;
    SetLength(AOutput, Length(AOutput) - lOutputLeft);
    Result := 0;
  finally
    iconv_close(lHandle);
  end;
end;

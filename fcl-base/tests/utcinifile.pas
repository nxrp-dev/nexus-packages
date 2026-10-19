unit utcIniFile;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, obNXTestContext, obNXTestRegistry, obNXTestSuite, inifiles;

procedure RegisterutcIniFileTests(ARegistry: TNXTestRegistry);

implementation

var
  Fini: TCustomIniFile;
  FFileName: string;

procedure Setup(AContext: TNXTestContext);
var lGuid: TGUID;
begin

  if Assigned(Fini) then
    Fini.Free;
  Fini := nil;
  if FFileName <> '' then DeleteFile(FFileName);
  try
    CreateGUID(lGuid);
    FFileName := IncludeTrailingPathDelimiter(GetTempDir(False)) + 'nxtest-ini-' + GUIDToString(lGuid) + '.ini';
    Fini := TMemIniFile.Create(FFileName);
  except
    on E: Exception do
      AContext.Fail('Setup failed: ' + E.Message);
  end;
end;

procedure TearDown(AContext: TNXTestContext);
begin

  if Assigned(Fini) then
    Fini.Free;
  Fini := nil;
  if FFileName <> '' then DeleteFile(FFileName);
  FFileName := '';
end;

procedure TIniFile_TestWriteBoolean(AContext: TNXTestContext);
begin
  try
    Setup(AContext);

    AContext.AssertTrue((Fini) <> nil, 'Ini object should be created');
    if not Assigned(Fini) then Exit;

    Fini.WriteBool('a','b',true);
    AContext.AssertTrue(('1') = (Fini.ReadString('a','b','')), 'Default true');
    Fini.WriteBool('a','b',False);
    AContext.AssertTrue(('0') = (Fini.ReadString('a','b','')), 'Default false');
    Fini.Options:=Fini.Options+[ifoWriteStringBoolean];
    Fini.WriteBool('a','b',true);
    AContext.AssertTrue(('true') = (Fini.ReadString('a','b','')), 'Default string true');
    Fini.WriteBool('a','b',false);
    AContext.AssertTrue(('false') = (Fini.ReadString('a','b','')), 'Default string false');
    Fini.SetBoolStringValues(true,['t','true']);
    Fini.WriteBool('a','b',true);
    AContext.AssertTrue(('t') = (Fini.ReadString('a','b','')), 'True from string array');
    Fini.SetBoolStringValues(false,['f','false']);
    Fini.WriteBool('a','b',false);
    AContext.AssertTrue(('f') = (Fini.ReadString('a','b','')), 'False from string array');
  finally
    TearDown(AContext);
  end;
end;

procedure TIniFile_TestReadBoolean(AContext: TNXTestContext);
begin
  try
    Setup(AContext);

    AContext.AssertTrue((Fini) <> nil, 'Ini object should be created');
    if not Assigned(Fini) then Exit;

    Fini.WriteString('a','b','1');
    AContext.AssertTrue((true) = (Fini.ReadBool('a','b',False)), 'Default true');
    Fini.WriteString('a','b','0');
    AContext.AssertTrue((false) = (Fini.ReadBool('a','b',True)), 'Default false');
    Fini.WriteString('a','b','');
    AContext.AssertTrue((true) = (Fini.ReadBool('a','b',true)), 'Empty returns Default ');
    Fini.SetBoolStringValues(true,['t','true']);
    Fini.WriteString('a','b','t');
    AContext.AssertTrue((true) = (Fini.ReadBool('a','b',false)), 'First string match');
    Fini.WriteString('a','b','true');
    AContext.AssertTrue((true) = (Fini.ReadBool('a','b',false)), 'Second string match');
    Fini.WriteString('a','b','d');
    AContext.AssertTrue((true) = (Fini.ReadBool('a','b',true)), 'No string match, default');
    Fini.SetBoolStringValues(true,[]);
    Fini.SetBoolStringValues(false,['f','false']);
    Fini.WriteString('a','b','f');
    AContext.AssertTrue((false) = (Fini.ReadBool('a','b',true)), 'First string match false');
    Fini.WriteString('a','b','false');
    AContext.AssertTrue((false) = (Fini.ReadBool('a','b',true)), 'Second string match false');
    Fini.WriteString('a','b','d');
    AContext.AssertTrue((false) = (Fini.ReadBool('a','b',false)), 'No string match, default false');
    Fini.SetBoolStringValues(true,['t','true']);
    AContext.AssertTrue((false) = (Fini.ReadBool('a','b',false)), 'No string match, default false 2');
    Fini.SetBoolStringValues(true,[]);
    Fini.SetBoolStringValues(False,[]);
    Fini.Options:=Fini.Options+[ifoWriteStringBoolean];
    Fini.WriteString('a','b','true');
    AContext.AssertTrue((True) = (Fini.ReadBool('a','b',false)), 'ifoWriteStringBoolean, true string ');
    Fini.WriteString('a','b','false');
    AContext.AssertTrue((false) = (Fini.ReadBool('a','b',true)), 'ifoWriteStringBoolean, false string');
    Fini.WriteString('a','b','soso');
    AContext.AssertTrue((True) = (Fini.ReadBool('a','b',true)), 'ifoWriteStringBoolean, No string match, default');
  finally
    TearDown(AContext);
  end;
end;

procedure RegisterutcIniFileTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCL.Configuration.TIniFileTests');
  lSuite.AddTest('TestWriteBoolean', @TIniFile_TestWriteBoolean, 'configuration');
  lSuite.AddTest('TestReadBoolean', @TIniFile_TestReadBoolean, 'configuration');
end;

end.

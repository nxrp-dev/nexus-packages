unit utcdirwatch;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, obNXTestContext, obNXTestRegistry, obNXTestSuite, dirwatch;

procedure RegisterutcdirwatchTests(ARegistry: TNXTestRegistry);

implementation

uses typinfo, inifiles;

type
  TChangedEntry = record
    Dir : TWatchDirectoryEntry;
    Events : TWatchFileEvents;
    FN : String;
  end;
  TChangedEntryArray = Array of TChangedEntry;

  { TEventObject }

  TEventObject = class
    procedure DoChange(Sender: TObject; const aEvent: TFileChangeEvent);
  private
    procedure DoCheck(sender: TObject; var aContinue: Boolean);
    procedure HandleCreateFile(Sender: TObject);
  end;

var
  FDirWatch: TDirwatch;
  FTestDir: string;
  FChanged: TChangedEntryArray;
  FCheckCount : Integer;
  FMaxLoopCount : Integer;
  FDoCheckOne : TNotifyEvent;
  BaseDir : String;
  Events : TEventObject;

// Helper functions from the original test case
procedure CleanDirs(AContext: TNXTestContext; aDir: String);
Var
  Info : TSearchRec;
  lDir,lFull : String;
begin
  lDir:=IncludeTrailingPathDelimiter(aDir);
  If FindFirst(lDir+AllFilesMask,sysutils.faDirectory,Info)=0 then
    try
      Repeat
        lFull:=lDir+Info.Name;
        if (Info.Attr and faDirectory)<>0 then
          begin
          if not ((Info.Name='.') or (Info.Name='..')) then
            begin
            CleanDirs(AContext, lFull);
            if not RemoveDir(lFull) then
              AContext.Fail('Failed to remove directory '+lFull)
            end;
          end
        else if not DeleteFile(lFull) then
          AContext.Fail('Failed to remove file '+lFull)
      until FindNext(Info)<>0;
    finally
      FindClose(Info);
    end;
end;

procedure TEventObject.DoChange(Sender: TObject; const aEvent: TFileChangeEvent);
var
  Len : Integer;
begin
  len:=Length(FChanged);
  SetLength(FChanged,Len+1);
  FChanged[Len].Dir:=aEvent.Entry;
  FChanged[Len].Events:=aEvent.Events;
  FChanged[Len].FN:=aEvent.FileName;
end;

procedure TEventObject.DoCheck(sender: TObject; var aContinue: Boolean);
begin
  aContinue:=FCheckCount<FMaxLoopCount;
  if (FCheckCount=0) then
    if Assigned(FDoCheckOne) then
       FDoCheckOne(nil);
  inc(FCheckCount);
end;

procedure DoAppendFile(const aName : string);
var
  FD : THandle;
begin
  FD:=FileOpen(FTestDir+aName,fmOpenWrite);
  try
    FileSeek(FD,0,fsFromEnd);
    if FileWrite(FD,aName[1],Length(aName))=-1 then
      Writeln(GetLastOSError);
  finally
    FileClose(FD);
  end;
end;

procedure DoCreateFile(const aName : string);
var
  L: TStrings;
begin
  L:=TStringList.Create;
  try
    L.Add(aName);
    L.SaveToFile(FTestDir+aName);
  finally
    L.Free;
  end;
end;

procedure DoDeleteFile(AContext: TNXTestContext; const aName: string);
begin
  If not DeleteFile(FTestDir+aName) then
    AContext.Fail('Failed to delete file '+FTestDir+aName);
end;

procedure TEventObject.HandleCreateFile(Sender: TObject);
begin
  DoCreateFile('name.txt');
end;

procedure AssertEventsEquals(AContext: TNXTestContext; const Msg: String; aExpected, aActual: TWatchFileEvents);
begin
  AContext.AssertTrue((SetToString(PTypeInfo(TypeInfo(TWatchFileEvents)),Longint(aExpected),False))=(SetToString(PTypeInfo(TypeInfo(TWatchFileEvents)),Longint(aActual),False)), Msg);
end;

procedure AssertChange(AContext: TNXTestContext; const Msg: String; aIndex: Integer; aEntry: TWatchDirectoryEntry; aEvents: TWatchFileEvents; const aFileName: string = '');
var
  M : String;
begin
  M:=Msg+Format(' [%d]: ',[aIndex]);
  AContext.AssertTrue(aIndex<Length(FChanged), M+'correct index');
  AContext.AssertTrue((aEntry)=(FChanged[aIndex].Dir), M+'correct dir entry');
  AssertEventsEquals(AContext, M+'correct changes',aEvents,FChanged[aIndex].Events);
  if aFileName<>'' then
    AContext.AssertTrue((aFileName)=(FChanged[aIndex].FN), M+'correct fileName');
end;

// Per-test setup and teardown
procedure TestSetup;
var lGuid: TGUID;
begin
  Events:=TEventObject.Create;
  CreateGUID(lGuid);
  BaseDir:=IncludeTrailingPathDelimiter(GetTempDir(False))+'nx-dirwatch-'+GUIDToString(lGuid)+PathDelim;
  FDirWatch:=TDirwatch.Create(Nil);
  FTestDir:=IncludeTrailingPathDelimiter(BaseDir);
  ForceDirectories(FTestDir);
  FDirWatch.OnChange:=@Events.DoChange;
  FMaxLoopCount:=0;
  FCheckCount:=0;
  FDoCheckOne:=Nil;
  SetLength(FChanged, 0);
end;

procedure TestTearDown(AContext: TNXTestContext);
begin
  FDirWatch.Free;
  CleanDirs(AContext, FTestDir);
  RemoveDir(FTestDir);
  FreeAndNil(Events);
end;

// Flattened Tests
procedure TestDirWatch_TestHookUp(AContext: TNXTestContext);
begin

  TestSetup;
  try
    AContext.AssertTrue((FDirWatch)<>nil, 'Have watch');
    AContext.AssertTrue((0)=(FDirWatch.Watches.Count), 'No watches');
    AContext.AssertTrue(FTestDir<>'', 'Have test dir');
    AContext.AssertTrue(DirectoryExists(FTestDir), 'test dir exists');
    AContext.AssertTrue((0)=(FMaxLoopCount), 'No max check count');
    AContext.AssertTrue((0)=(FCheckCount), 'No check count');
    AContext.AssertTrue(FDoCheckOne=nil, 'No docheckone');
  finally
    TestTearDown(AContext);
  end;
end;

procedure TestDirWatch_TestAddFile(AContext: TNXTestContext);
begin

  TestSetup;
  try
    FDirwatch.AddWatch(FTestDir,[feCreate]);
    FDirWatch.InitWatch;
    DoCreateFile('name.txt');
    AContext.AssertTrue((1)=(FDirWatch.Check), 'Change detected');
    AssertChange(AContext, 'Create',0,FDirWatch.Watches[0],[feCreate],'name.txt');
  finally
    TestTearDown(AContext);
  end;
end;

procedure TestDirWatch_TestAppendFile(AContext: TNXTestContext);
begin

  TestSetup;
  try
    FDirwatch.AddWatch(FTestDir,[feModify]);
    DoCreateFile('name.txt');
    FDirWatch.InitWatch;
    DoAppendFile('name.txt');
    AContext.AssertTrue((1)=(FDirWatch.Check), 'Change detected');
    AssertChange(AContext, 'Change detected',0,FDirWatch.Watches[0],[feModify],'name.txt');
  finally
    TestTearDown(AContext);
  end;
end;

procedure TestDirWatch_TestDeleteFile(AContext: TNXTestContext);
begin

  TestSetup;
  try
    FDirwatch.AddWatch(FTestDir,[feDelete]);
    DoCreateFile('name.txt');
    FDirWatch.InitWatch;
    DoDeleteFile(AContext, 'name.txt');
    AContext.AssertTrue((1)=(FDirWatch.Check), 'Change detected');
    AssertChange(AContext, 'Change detected',0,FDirWatch.Watches[0],[feDelete],'name.txt');
  finally
    TestTearDown(AContext);
  end;
end;

procedure TestDirWatch_TestLoopNoThread(AContext: TNXTestContext);
begin

  TestSetup;
  try
    FDirwatch.AddWatch(FTestDir,[feCreate]);
    FDirwatch.OnCheck:=@Events.DoCheck;
    FDoCheckOne:=@Events.HandleCreateFile;
    FMaxLoopCount:=2;
    FDirWatch.StartLoop;
    AssertChange(AContext, 'Change detected',0,FDirWatch.Watches[0],[feCreate],'name.txt');
  finally
    TestTearDown(AContext);
  end;
end;

procedure TestDirWatch_TestLoopThread(AContext: TNXTestContext);
var
  I : Integer;
begin

  TestSetup;
  try
    FDirwatch.AddWatch(FTestDir,[feCreate]);
    FDirwatch.Threaded:=True;
    FDirWatch.StartLoop;
    Sleep(50);
    DoCreateFile('name.txt');
    I:=0;
    Repeat
      Sleep(10);
      CheckSynchronize;
      inc(i);
    until (I>=50) or (length(FChanged)>0);
    AssertChange(AContext, 'Change detected',0,FDirWatch.Watches[0],[feCreate],'name.txt');
  finally
    TestTearDown(AContext);
  end;
end;

procedure TestDirWatch_TestAddFileBaseDir(AContext: TNXTestContext);
begin

  TestSetup;
  try
    FDirwatch.BaseDir:=FTestDir;
    AContext.AssertTrue(ForceDirectories(FTestDir+'sub'), 'Create Subdir ');
    FDirwatch.AddWatch('',[feCreate]);
    FDirWatch.InitWatch;
    DoCreateFile('sub/name.txt');
    AContext.AssertTrue((0)=(FDirWatch.Check), 'Subdirs not watched');
  finally
    TestTearDown(AContext);
  end;
end;

procedure RegisterutcdirwatchTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('utcdirwatch.TDirWatchTests');
  lSuite.AddTest('TestHookUp', @TestDirWatch_TestHookUp, 'filesystem');
  lSuite.AddTest('TestAddFile', @TestDirWatch_TestAddFile, 'filesystem');
  lSuite.AddTest('TestAppendFile', @TestDirWatch_TestAppendFile, 'filesystem');
  lSuite.AddTest('TestDeleteFile', @TestDirWatch_TestDeleteFile, 'filesystem');
  lSuite.AddTest('TestLoopNoThread', @TestDirWatch_TestLoopNoThread, 'filesystem');
  lSuite.AddTest('TestLoopThread', @TestDirWatch_TestLoopThread, 'filesystem');
  lSuite.AddTest('TestAddFileBaseDir', @TestDirWatch_TestAddFileBaseDir, 'filesystem');
end;
end.

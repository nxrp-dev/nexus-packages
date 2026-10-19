unit utcObjectList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, contnrs, obNXTestContext, obNXTestRegistry, obNXTestSuite;

procedure RegisterutcObjectListTests(ARegistry: TNXTestRegistry);

implementation

type
  TMyObject = class(TObject)
    IsFreed: ^Boolean;
    destructor Destroy; override;
  end;

destructor TMyObject.Destroy;
begin
  if Assigned(IsFreed) then
    IsFreed^ := True;
  inherited Destroy;
end;

procedure TObjectList_TestCreate(AContext: TNXTestContext);
var
  L: TObjectList;
begin

  L := TObjectList.Create;
  try
    AContext.AssertTrue((L) <> nil, 'List should be created');
    AContext.AssertTrue((0) = (L.Count), 'Count should be 0 on creation');
    AContext.AssertTrue(L.OwnsObjects, 'OwnsObjects should be true by default');
  finally
    L.Free;
  end;
end;

procedure TObjectList_TestAdd(AContext: TNXTestContext);
var
  L: TObjectList;
  O1, O2: TObject;
begin

  L := TObjectList.Create(False);
  try
    O1 := TObject.Create;
    O2 := TObject.Create;
    L.Add(O1);
    AContext.AssertTrue((1) = (L.Count), 'Count should be 1 after adding one object');
    AContext.AssertTrue((O1) = (L.Items[0]), 'First item should be O1');
    L.Add(O2);
    AContext.AssertTrue((2) = (L.Count), 'Count should be 2 after adding a second object');
    AContext.AssertTrue((O2) = (L.Items[1]), 'Second item should be O2');
  finally
    L.Free;
    O1.Free;
    O2.Free;
  end;
end;

procedure TObjectList_TestExtract(AContext: TNXTestContext);
var
  L: TObjectList;
  O1, O2, Extracted: TObject;
begin

  L := TObjectList.Create(False);
  try
    O1 := TObject.Create;
    O2 := TObject.Create;
    L.Add(O1);
    L.Add(O2);
    Extracted := L.Extract(O1);
    AContext.AssertTrue((O1) = (Extracted), 'Extracted object should be O1');
    AContext.AssertTrue((1) = (L.Count), 'Count should be 1 after extracting an object');
    AContext.AssertTrue((O2) = (L.Items[0]), 'First item should now be O2');
  finally
    L.Free;
    O1.Free;
    O2.Free;
  end;
end;

procedure TObjectList_TestRemove(AContext: TNXTestContext);
var
  L: TObjectList;
  O1, O2: TObject;
begin

  L := TObjectList.Create(False);
  try
    O1 := TObject.Create;
    O2 := TObject.Create;
    L.Add(O1);
    L.Add(O2);
    L.Remove(O1);
    AContext.AssertTrue((1) = (L.Count), 'Count should be 1 after removing an object');
    AContext.AssertTrue((O2) = (L.Items[0]), 'First item should now be O2');
  finally
    L.Free;
    O2.Free;
  end;
end;

procedure TObjectList_TestIndexOf(AContext: TNXTestContext);
var
  L: TObjectList;
  O1, O2, O3: TObject;
begin

  L := TObjectList.Create(False);
  O3 := TObject.Create;
  try
    O1 := TObject.Create;
    O2 := TObject.Create;
    L.Add(O1);
    L.Add(O2);
    AContext.AssertTrue((0) = (L.IndexOf(O1)), 'Index of O1 should be 0');
    AContext.AssertTrue((1) = (L.IndexOf(O2)), 'Index of O2 should be 1');
    AContext.AssertTrue((-1) = (L.IndexOf(O3)), 'Index of a non-existent object should be -1');
  finally
    L.Free;
    O1.Free;
    O2.Free;
    O3.Free;
  end;
end;

procedure TObjectList_TestFindInstanceOf(AContext: TNXTestContext);
var
  L: TObjectList;
  O1: TObject;
  C1: TMyObject;
begin

  L := TObjectList.Create(False);
  try
    O1 := TObject.Create;
    C1 := TMyObject.Create;
    L.Add(O1);
    L.Add(C1);
    AContext.AssertTrue((0) = (L.FindInstanceOf(TObject, True, 0)), 'Find TObject exact');
    AContext.AssertTrue((1) = (L.FindInstanceOf(TMyObject, True, 0)), 'Find TMyObject exact');
    AContext.AssertTrue((0) = (L.FindInstanceOf(TObject, False, 0)), 'Find TObject inexact');
    AContext.AssertTrue((1) = (L.FindInstanceOf(TMyObject, False, 0)), 'Find TMyObject inexact from start');
  finally
    L.Free;
    O1.Free;
    C1.Free;
  end;
end;

procedure TObjectList_TestInsert(AContext: TNXTestContext);
var
  L: TObjectList;
  O1, O2, O3: TObject;
begin

  L := TObjectList.Create(False);
  try
    O1 := TObject.Create;
    O2 := TObject.Create;
    O3 := TObject.Create;
    L.Add(O1);
    L.Add(O2);
    L.Insert(1, O3);
    AContext.AssertTrue((3) = (L.Count), 'Count should be 3 after inserting an object');
    AContext.AssertTrue((O3) = (L.Items[1]), 'Item at index 1 should be O3');
    AContext.AssertTrue((O2) = (L.Items[2]), 'Item at index 2 should be O2');
  finally
    L.Free;
    O1.Free;
    O2.Free;
    O3.Free;
  end;
end;

procedure TObjectList_TestFirstLast(AContext: TNXTestContext);
var
  L: TObjectList;
  O1, O2: TObject;
begin

  L := TObjectList.Create(False);
  try
    O1 := TObject.Create;
    O2 := TObject.Create;
    L.Add(O1);
    L.Add(O2);
    AContext.AssertTrue((O1) = (L.First), 'First object should be O1');
    AContext.AssertTrue((O2) = (L.Last), 'Last object should be O2');
  finally
    L.Free;
    O1.Free;
    O2.Free;
  end;
end;

procedure TObjectList_TestOwnsObjects(AContext: TNXTestContext);
var
  L: TObjectList;
  O1: TMyObject;
  Freed: Boolean;
begin

  L := TObjectList.Create(True);
  Freed := False;
  O1 := TMyObject.Create;
  O1.IsFreed := @Freed;
  L.Add(O1);
  L.Free; // This should free O1 as well
  AContext.AssertTrue(Freed, 'Object should be freed when OwnsObjects is true and list is freed');
end;

procedure RegisterutcObjectListTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCL.Collections.TObjectListTests');
  lSuite.AddTest('TestCreate', @TObjectList_TestCreate, 'collections');
  lSuite.AddTest('TestAdd', @TObjectList_TestAdd, 'collections');
  lSuite.AddTest('TestExtract', @TObjectList_TestExtract, 'collections');
  lSuite.AddTest('TestRemove', @TObjectList_TestRemove, 'collections');
  lSuite.AddTest('TestIndexOf', @TObjectList_TestIndexOf, 'collections');
  lSuite.AddTest('TestFindInstanceOf', @TObjectList_TestFindInstanceOf, 'collections');
  lSuite.AddTest('TestInsert', @TObjectList_TestInsert, 'collections');
  lSuite.AddTest('TestFirstLast', @TObjectList_TestFirstLast, 'collections');
  lSuite.AddTest('TestOwnsObjects', @TObjectList_TestOwnsObjects, 'collections');
end;

end.

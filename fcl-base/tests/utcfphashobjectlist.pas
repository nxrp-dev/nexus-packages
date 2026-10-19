unit utcFPHashObjectList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, contnrs, obNXTestContext, obNXTestRegistry, obNXTestSuite;

procedure RegisterutcFPHashObjectListTests(ARegistry: TNXTestRegistry);

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

procedure TFPHashObjectList_TestCreate(AContext: TNXTestContext);
var
  L: TFPHashObjectList;
begin

  L := TFPHashObjectList.Create;
  try
    AContext.AssertTrue((L) <> nil, 'List should be created');
    AContext.AssertTrue((0) = (L.Count), 'Count should be 0 on creation');
    AContext.AssertTrue(L.OwnsObjects, 'OwnsObjects should be true by default');
  finally
    L.Free;
  end;
end;

procedure TFPHashObjectList_TestAdd(AContext: TNXTestContext);
var
  L: TFPHashObjectList;
  O1, O2: TObject;
begin

  L := TFPHashObjectList.Create(False);
  try
    O1 := TObject.Create;
    O2 := TObject.Create;
    L.Add('O1', O1);
    AContext.AssertTrue((1) = (L.Count), 'Count should be 1 after adding one object');
    AContext.AssertTrue((O1) = (L.Items[0]), 'First item should be O1');
    L.Add('O2', O2);
    AContext.AssertTrue((2) = (L.Count), 'Count should be 2 after adding a second object');
    AContext.AssertTrue((O2) = (L.Items[1]), 'Second item should be O2');
  finally
    L.Free;
    O1.Free;
    O2.Free;
  end;
end;

procedure TFPHashObjectList_TestDelete(AContext: TNXTestContext);
var
  L: TFPHashObjectList;
  O1, O2: TObject;
begin

  L := TFPHashObjectList.Create(False);
  try
    O1 := TObject.Create;
    O2 := TObject.Create;
    L.Add('O1', O1);
    L.Add('O2', O2);
    L.Delete(0);
    AContext.AssertTrue((1) = (L.Count), 'Count should be 1 after deleting an object');
    AContext.AssertTrue((O2) = (L.Items[0]), 'First item should now be O2');
  finally
    L.Free;
    O1.Free;
    O2.Free;
  end;
end;

procedure TFPHashObjectList_TestClear(AContext: TNXTestContext);
var
  L: TFPHashObjectList;
  O1, O2: TObject;
begin

  L := TFPHashObjectList.Create(False);
  try
    O1 := TObject.Create;
    O2 := TObject.Create;
    L.Add('O1', O1);
    L.Add('O2', O2);
    L.Clear;
    AContext.AssertTrue((0) = (L.Count), 'Count should be 0 after clearing the list');
  finally
    L.Free;
    O1.Free;
    O2.Free;
  end;
end;

procedure TFPHashObjectList_TestIndexOf(AContext: TNXTestContext);
var
  L: TFPHashObjectList;
  O1, O2, O3: TObject;
begin

  L := TFPHashObjectList.Create(False);
  O3 := TObject.Create;
  try
    O1 := TObject.Create;
    O2 := TObject.Create;
    L.Add('O1', O1);
    L.Add('O2', O2);
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

procedure TFPHashObjectList_TestRemove(AContext: TNXTestContext);
var
  L: TFPHashObjectList;
  O1, O2: TObject;
begin

  L := TFPHashObjectList.Create(False);
  try
    O1 := TObject.Create;
    O2 := TObject.Create;
    L.Add('O1', O1);
    L.Add('O2', O2);
    L.Remove(O1);
    AContext.AssertTrue((1) = (L.Count), 'Count should be 1 after removing an object');
    AContext.AssertTrue((O2) = (L.Items[0]), 'First item should now be O2');
  finally
    L.Free;
    O1.Free;
    O2.Free;
  end;
end;

procedure TFPHashObjectList_TestOwnsObjects(AContext: TNXTestContext);
var
  L: TFPHashObjectList;
  O1: TMyObject;
  Freed: Boolean;
begin

  L := TFPHashObjectList.Create(True);
  Freed := False;
  O1 := TMyObject.Create;
  O1.IsFreed := @Freed;
  L.Add('O1', O1);
  L.Free; // This should free O1 as well
  AContext.AssertTrue(Freed, 'Object should be freed when OwnsObjects is true and list is freed');
end;

procedure TFPHashObjectList_TestFind(AContext: TNXTestContext);
var
  L: TFPHashObjectList;
  O1, O2: TObject;
begin

  L := TFPHashObjectList.Create(False);
  try
    O1 := TObject.Create;
    O2 := TObject.Create;
    L.Add('O1', O1);
    L.Add('O2', O2);
    AContext.AssertTrue((O1) = (L.Find('O1')), 'Find should return O1');
    AContext.AssertTrue((O2) = (L.Find('O2')), 'Find should return O2');
    AContext.AssertTrue((nil) = (L.Find('O3')), 'Find for a non-existent object should return nil');
  finally
    L.Free;
    O1.Free;
    O2.Free;
  end;
end;

procedure TFPHashObjectList_TestFindLong(AContext: TNXTestContext);
var
  L: TFPHashObjectList;
  O0, O1, O2: TObject;
  S : String;
begin

  O0:=Nil;
  O1:=Nil;
  O2:=Nil;
  L := TFPHashObjectList.Create(False);
  try
    O0 := TObject.Create;
    O1 := TObject.Create;
    O2 := TObject.Create;
    S:=StringOfChar('A',333);
    L.Add('x', O0);
    L.Add(S, O1);
    L.Add(S+'2', O2);
    AContext.AssertTrue((O1) = (L.Find(S)), 'Find should return O1');
    AContext.AssertTrue((O2) = (L.Find(S+'2')), 'Find should return O2');
    AContext.AssertTrue((nil) = (L.Find('O3')), 'Find for a non-existent object should return nil');
  finally
    L.Free;
    O0.Free;
    O1.Free;
    O2.Free;
  end;
end;

procedure TFPHashObjectList_TestFindIndexOf(AContext: TNXTestContext);
var
  L: TFPHashObjectList;
  O0, O1, O2: TObject;
begin

  O0:=Nil;
  O1:=Nil;
  O2:=Nil;
  L := TFPHashObjectList.Create(False);
  try
    O0 := TObject.Create;
    O1 := TObject.Create;
    O2 := TObject.Create;
    L.Add('O1', O1);
    L.Add('O2', O2);
    AContext.AssertTrue((0) = (L.FindIndexOf('O1')), 'FindIndexOf for O1 should be 0');
    AContext.AssertTrue((1) = (L.FindIndexOf('O2')), 'FindIndexOf for O2 should be 1');
    AContext.AssertTrue((-1) = (L.FindIndexOf('O3')), 'FindIndexOf for a non-existent object should be -1');
  finally
    L.Free;
    O0.Free;
    O1.Free;
    O2.Free;
  end;
end;

procedure RegisterutcFPHashObjectListTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCL.Collections.TFPHashObjectListTests');
  lSuite.AddTest('TestCreate', @TFPHashObjectList_TestCreate, 'collections');
  lSuite.AddTest('TestAdd', @TFPHashObjectList_TestAdd, 'collections');
  lSuite.AddTest('TestDelete', @TFPHashObjectList_TestDelete, 'collections');
  lSuite.AddTest('TestClear', @TFPHashObjectList_TestClear, 'collections');
  lSuite.AddTest('TestIndexOf', @TFPHashObjectList_TestIndexOf, 'collections');
  lSuite.AddTest('TestRemove', @TFPHashObjectList_TestRemove, 'collections');
  lSuite.AddTest('TestOwnsObjects', @TFPHashObjectList_TestOwnsObjects, 'collections');
  lSuite.AddTest('TestFind', @TFPHashObjectList_TestFind, 'collections');
  lSuite.AddTest('TestFindLong', @TFPHashObjectList_TestFindLong, 'collections');
  lSuite.AddTest('TestFindIndexOf', @TFPHashObjectList_TestFindIndexOf, 'collections');
end;

end.

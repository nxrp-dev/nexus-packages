unit utcfpobjectlist;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, contnrs, obNXTestContext, obNXTestRegistry, obNXTestSuite;

procedure RegisterutcfpobjectlistTests(ARegistry: TNXTestRegistry);

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

procedure TFPObjectList_TestCreate(AContext: TNXTestContext);
var
  L: TFPObjectList;
begin

  L := TFPObjectList.Create;
  try
    AContext.AssertTrue((L) <> nil, 'List should be created');
    AContext.AssertTrue((0) = (L.Count), 'Count should be 0 on creation');
    AContext.AssertTrue(L.OwnsObjects, 'OwnsObjects should be true by default');
  finally
    L.Free;
  end;
end;

procedure TFPObjectList_TestAdd(AContext: TNXTestContext);
var
  L: TFPObjectList;
  O1, O2: TObject;
begin

  L := TFPObjectList.Create(False);
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

procedure TFPObjectList_TestDelete(AContext: TNXTestContext);
var
  L: TFPObjectList;
  O1, O2: TObject;
begin

  L := TFPObjectList.Create(False);
  try
    O1 := TObject.Create;
    O2 := TObject.Create;
    L.Add(O1);
    L.Add(O2);
    L.Delete(0);
    AContext.AssertTrue((1) = (L.Count), 'Count should be 1 after deleting an object');
    AContext.AssertTrue((O2) = (L.Items[0]), 'First item should now be O2');
  finally
    L.Free;
    O1.Free;
    O2.Free;
  end;
end;

procedure TFPObjectList_TestClear(AContext: TNXTestContext);
var
  L: TFPObjectList;
  O1, O2: TObject;
begin

  L := TFPObjectList.Create(False);
  try
    O1 := TObject.Create;
    O2 := TObject.Create;
    L.Add(O1);
    L.Add(O2);
    L.Clear;
    AContext.AssertTrue((0) = (L.Count), 'Count should be 0 after clearing the list');
  finally
    L.Free;
    O1.Free;
    O2.Free;
  end;
end;

procedure TFPObjectList_TestIndexOf(AContext: TNXTestContext);
var
  L: TFPObjectList;
  O1, O2, O3: TObject;
begin

  L := TFPObjectList.Create(False);
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

procedure TFPObjectList_TestRemove(AContext: TNXTestContext);
var
  L: TFPObjectList;
  O1, O2: TObject;
begin

  L := TFPObjectList.Create(False);
  try
    O1 := TObject.Create;
    O2 := TObject.Create;
    try
      L.Add(O1);
      L.Add(O2);
      L.Remove(O1);
      AContext.AssertTrue((1) = (L.Count), 'Count should be 1 after removing an object');
      AContext.AssertTrue((O2) = (L.Items[0]), 'First item should now be O2');
    finally
      O1.Free;
      O2.Free;
    end;
  finally
    L.Free;
  end;
end;

procedure TFPObjectList_TestOwnsObjects(AContext: TNXTestContext);
var
  L: TFPObjectList;
  O1: TMyObject;
  Freed: Boolean;
begin

  L := TFPObjectList.Create(True);
  Freed := False;
  O1 := TMyObject.Create;
  O1.IsFreed := @Freed;
  L.Add(O1);
  L.Free; // This should free O1 as well
  AContext.AssertTrue(Freed, 'Object should be freed when OwnsObjects is true and list is freed');
end;

procedure RegisterutcfpobjectlistTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCL.Collections.TFPObjectListTests');
  lSuite.AddTest('TestCreate', @TFPObjectList_TestCreate, 'collections');
  lSuite.AddTest('TestAdd', @TFPObjectList_TestAdd, 'collections');
  lSuite.AddTest('TestDelete', @TFPObjectList_TestDelete, 'collections');
  lSuite.AddTest('TestClear', @TFPObjectList_TestClear, 'collections');
  lSuite.AddTest('TestIndexOf', @TFPObjectList_TestIndexOf, 'collections');
  lSuite.AddTest('TestRemove', @TFPObjectList_TestRemove, 'collections');
  lSuite.AddTest('TestOwnsObjects', @TFPObjectList_TestOwnsObjects, 'collections');
end;

end.

unit utcClassList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, contnrs, obNXTestContext, obNXTestRegistry, obNXTestSuite;

procedure RegisterutcClassListTests(ARegistry: TNXTestRegistry);

implementation

procedure TClassList_TestCreate(AContext: TNXTestContext);
var
  L: TClassList;
begin

  L := TClassList.Create;
  try
    AContext.AssertTrue((L) <> nil, 'List should be created');
    AContext.AssertTrue((0) = (L.Count), 'Count should be 0 on creation');
  finally
    L.Free;
  end;
end;

procedure TClassList_TestAdd(AContext: TNXTestContext);
var
  L: TClassList;
begin

  L := TClassList.Create;
  try
    L.Add(TObject);
    AContext.AssertTrue((1) = (L.Count), 'Count should be 1 after adding one class');
    AContext.AssertTrue((TObject) = (L.Items[0]), 'First item should be TObject');
    L.Add(TList);
    AContext.AssertTrue((2) = (L.Count), 'Count should be 2 after adding a second class');
    AContext.AssertTrue((TList) = (L.Items[1]), 'Second item should be TList');
  finally
    L.Free;
  end;
end;

procedure TClassList_TestExtract(AContext: TNXTestContext);
var
  L: TClassList;
  Extracted: TClass;
begin

  L := TClassList.Create;
  try
    L.Add(TObject);
    L.Add(TList);
    Extracted := L.Extract(TObject);
    AContext.AssertTrue((TObject) = (Extracted), 'Extracted class should be TObject');
    AContext.AssertTrue((1) = (L.Count), 'Count should be 1 after extracting a class');
    AContext.AssertTrue((TList) = (L.Items[0]), 'First item should now be TList');
  finally
    L.Free;
  end;
end;

procedure TClassList_TestRemove(AContext: TNXTestContext);
var
  L: TClassList;
begin

  L := TClassList.Create;
  try
    L.Add(TObject);
    L.Add(TList);
    L.Remove(TObject);
    AContext.AssertTrue((1) = (L.Count), 'Count should be 1 after removing a class');
    AContext.AssertTrue((TList) = (L.Items[0]), 'First item should now be TList');
  finally
    L.Free;
  end;
end;

procedure TClassList_TestIndexOf(AContext: TNXTestContext);
var
  L: TClassList;
begin

  L := TClassList.Create;
  try
    L.Add(TObject);
    L.Add(TList);
    AContext.AssertTrue((0) = (L.IndexOf(TObject)), 'Index of TObject should be 0');
    AContext.AssertTrue((1) = (L.IndexOf(TList)), 'Index of TList should be 1');
    AContext.AssertTrue((-1) = (L.IndexOf(TComponent)), 'Index of a non-existent class should be -1');
  finally
    L.Free;
  end;
end;

procedure TClassList_TestInsert(AContext: TNXTestContext);
var
  L: TClassList;
begin

  L := TClassList.Create;
  try
    L.Add(TObject);
    L.Add(TList);
    L.Insert(1, TComponent);
    AContext.AssertTrue((3) = (L.Count), 'Count should be 3 after inserting a class');
    AContext.AssertTrue((TComponent) = (L.Items[1]), 'Item at index 1 should be TComponent');
    AContext.AssertTrue((TList) = (L.Items[2]), 'Item at index 2 should be TList');
  finally
    L.Free;
  end;
end;

procedure TClassList_TestFirstLast(AContext: TNXTestContext);
var
  L: TClassList;
begin

  L := TClassList.Create;
  try
    L.Add(TObject);
    L.Add(TList);
    AContext.AssertTrue((TObject) = (L.First), 'First class should be TObject');
    AContext.AssertTrue((TList) = (L.Last), 'Last class should be TList');
  finally
    L.Free;
  end;
end;

procedure RegisterutcClassListTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCL.Collections.TClassListTests');
  lSuite.AddTest('TestCreate', @TClassList_TestCreate, 'collections');
  lSuite.AddTest('TestAdd', @TClassList_TestAdd, 'collections');
  lSuite.AddTest('TestExtract', @TClassList_TestExtract, 'collections');
  lSuite.AddTest('TestRemove', @TClassList_TestRemove, 'collections');
  lSuite.AddTest('TestIndexOf', @TClassList_TestIndexOf, 'collections');
  lSuite.AddTest('TestInsert', @TClassList_TestInsert, 'collections');
  lSuite.AddTest('TestFirstLast', @TClassList_TestFirstLast, 'collections');
end;

end.

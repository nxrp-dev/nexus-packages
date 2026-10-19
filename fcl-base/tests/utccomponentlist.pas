unit utcComponentList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, contnrs, obNXTestContext, obNXTestRegistry, obNXTestSuite;

procedure RegisterutcComponentListTests(ARegistry: TNXTestRegistry);

implementation

type
  TMyComponent = class(TComponent)
  public
    IsFreed: ^Boolean;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

constructor TMyComponent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  IsFreed := nil;
end;

destructor TMyComponent.Destroy;
begin
  if Assigned(IsFreed) then
    IsFreed^ := True;
  inherited Destroy;
end;

procedure TComponentList_TestCreate(AContext: TNXTestContext);
var
  L: TComponentList;
begin

  L := TComponentList.Create;
  try
    AContext.AssertTrue((L) <> nil, 'List should be created');
    AContext.AssertTrue((0) = (L.Count), 'Count should be 0 on creation');
    AContext.AssertTrue(L.OwnsObjects, 'OwnsObjects should be true by default');
  finally
    L.Free;
  end;
end;

procedure TComponentList_TestAdd(AContext: TNXTestContext);
var
  L: TComponentList;
  C1, C2: TComponent;
begin

  L := TComponentList.Create(False);
  try
    C1 := TComponent.Create(nil);
    C2 := TComponent.Create(nil);
    L.Add(C1);
    AContext.AssertTrue((1) = (L.Count), 'Count should be 1 after adding one component');
    AContext.AssertTrue((C1) = (L.Items[0]), 'First item should be C1');
    L.Add(C2);
    AContext.AssertTrue((2) = (L.Count), 'Count should be 2 after adding a second component');
    AContext.AssertTrue((C2) = (L.Items[1]), 'Second item should be C2');
  finally
    L.Free;
    C1.Free;
    C2.Free;
  end;
end;

procedure TComponentList_TestExtract(AContext: TNXTestContext);
var
  L: TComponentList;
  C1, C2, Extracted: TComponent;
begin

  L := TComponentList.Create(False);
  try
    C1 := TComponent.Create(nil);
    C2 := TComponent.Create(nil);
    L.Add(C1);
    L.Add(C2);
    Extracted := L.Extract(C1);
    AContext.AssertTrue((C1) = (Extracted), 'Extracted component should be C1');
    AContext.AssertTrue((1) = (L.Count), 'Count should be 1 after extracting a component');
    AContext.AssertTrue((C2) = (L.Items[0]), 'First item should now be C2');
  finally
    L.Free;
    C1.Free;
    C2.Free;
  end;
end;

procedure TComponentList_TestRemove(AContext: TNXTestContext);
var
  L: TComponentList;
  C1, C2: TComponent;
begin

  L := TComponentList.Create(False);
  try
    C1 := TComponent.Create(nil);
    C2 := TComponent.Create(nil);
    L.Add(C1);
    L.Add(C2);
    L.Remove(C1);
    AContext.AssertTrue((1) = (L.Count), 'Count should be 1 after removing a component');
    AContext.AssertTrue((C2) = (L.Items[0]), 'First item should now be C2');
  finally
    L.Free;
    C2.Free;
  end;
end;

procedure TComponentList_TestIndexOf(AContext: TNXTestContext);
var
  L: TComponentList;
  C1, C2, C3: TComponent;
begin

  L := TComponentList.Create(False);
  C3 := TComponent.Create(nil);
  try
    C1 := TComponent.Create(nil);
    C2 := TComponent.Create(nil);
    L.Add(C1);
    L.Add(C2);
    AContext.AssertTrue((0) = (L.IndexOf(C1)), 'Index of C1 should be 0');
    AContext.AssertTrue((1) = (L.IndexOf(C2)), 'Index of C2 should be 1');
    AContext.AssertTrue((-1) = (L.IndexOf(C3)), 'Index of a non-existent component should be -1');
  finally
    L.Free;
    C1.Free;
    C2.Free;
    C3.Free;
  end;
end;

procedure TComponentList_TestInsert(AContext: TNXTestContext);
var
  L: TComponentList;
  C1, C2, C3: TComponent;
begin

  L := TComponentList.Create(False);
  try
    C1 := TComponent.Create(nil);
    C2 := TComponent.Create(nil);
    C3 := TComponent.Create(nil);
    L.Add(C1);
    L.Add(C2);
    L.Insert(1, C3);
    AContext.AssertTrue((3) = (L.Count), 'Count should be 3 after inserting a component');
    AContext.AssertTrue((C3) = (L.Items[1]), 'Item at index 1 should be C3');
    AContext.AssertTrue((C2) = (L.Items[2]), 'Item at index 2 should be C2');
  finally
    L.Free;
    C1.Free;
    C2.Free;
    C3.Free;
  end;
end;

procedure TComponentList_TestFirstLast(AContext: TNXTestContext);
var
  L: TComponentList;
  C1, C2: TComponent;
begin

  L := TComponentList.Create(False);
  try
    C1 := TComponent.Create(nil);
    C2 := TComponent.Create(nil);
    L.Add(C1);
    L.Add(C2);
    AContext.AssertTrue((C1) = (L.First), 'First component should be C1');
    AContext.AssertTrue((C2) = (L.Last), 'Last component should be C2');
  finally
    L.Free;
    C1.Free;
    C2.Free;
  end;
end;

procedure TComponentList_TestOwnsObjects(AContext: TNXTestContext);
var
  L: TComponentList;
  C1: TMyComponent;
  Freed: Boolean;
begin

  L := TComponentList.Create(True);
  Freed := False;
  C1 := TMyComponent.Create(nil);
  C1.IsFreed := @Freed;
  L.Add(C1);
  L.Free; // This should free C1 as well
  AContext.AssertTrue(Freed, 'Component should be freed when OwnsObjects is true and list is freed');
end;

procedure RegisterutcComponentListTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCL.Collections.TComponentListTests');
  lSuite.AddTest('TestCreate', @TComponentList_TestCreate, 'collections');
  lSuite.AddTest('TestAdd', @TComponentList_TestAdd, 'collections');
  lSuite.AddTest('TestExtract', @TComponentList_TestExtract, 'collections');
  lSuite.AddTest('TestRemove', @TComponentList_TestRemove, 'collections');
  lSuite.AddTest('TestIndexOf', @TComponentList_TestIndexOf, 'collections');
  lSuite.AddTest('TestInsert', @TComponentList_TestInsert, 'collections');
  lSuite.AddTest('TestFirstLast', @TComponentList_TestFirstLast, 'collections');
  lSuite.AddTest('TestOwnsObjects', @TComponentList_TestOwnsObjects, 'collections');
end;

end.

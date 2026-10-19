unit utcFPObjectHashTable;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, contnrs, obNXTestContext, obNXTestRegistry, obNXTestSuite;

procedure RegisterutcFPObjectHashTableTests(ARegistry: TNXTestRegistry);

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

procedure TFPObjectHashTable_TestCreate(AContext: TNXTestContext);
var
  HT: TFPObjectHashTable;
begin

  HT := TFPObjectHashTable.Create;
  try
    AContext.AssertTrue((HT) <> nil, 'Hash table should be created');
    AContext.AssertTrue((0) = (HT.Count), 'Count should be 0 on creation');
    AContext.AssertTrue(HT.IsEmpty, 'IsEmpty should be true on creation');
    AContext.AssertTrue(HT.OwnsObjects, 'OwnsObjects should be true by default');
  finally
    HT.Free;
  end;
end;

procedure TFPObjectHashTable_TestAdd(AContext: TNXTestContext);
var
  HT: TFPObjectHashTable;
  O1, O2: TObject;
begin

  HT := TFPObjectHashTable.Create(False);
  try
    O1 := TObject.Create;
    O2 := TObject.Create;
    HT.Add('Key1', O1);
    AContext.AssertTrue((1) = (HT.Count), 'Count should be 1 after adding one item');
    AContext.AssertFalse(HT.IsEmpty, 'IsEmpty should be false after adding an item');
    AContext.AssertTrue((O1) = (HT.Items['Key1']), 'Items property should return correct value');

    HT.Add('Key2', O2);
    AContext.AssertTrue((2) = (HT.Count), 'Count should be 2 after adding a second item');
    AContext.AssertTrue((O2) = (HT.Items['Key2']), 'Items property should return correct value for second item');
  finally
    HT.Free;
    O1.Free;
    O2.Free;
  end;
end;

procedure TFPObjectHashTable_TestDelete(AContext: TNXTestContext);
var
  HT: TFPObjectHashTable;
  O1, O2: TObject;
begin

  HT := TFPObjectHashTable.Create(False);
  try
    O1 := TObject.Create;
    O2 := TObject.Create;
    HT.Add('Key1', O1);
    HT.Add('Key2', O2);
    HT.Delete('Key1');
    AContext.AssertTrue((1) = (HT.Count), 'Count should be 1 after deleting an item');
    AContext.AssertTrue((HT.Items['Key1']) = nil, 'Accessing deleted key should return nil');
    AContext.AssertTrue((O2) = (HT.Items['Key2']), 'Other item should still exist');
  finally
    HT.Free;
    O1.Free;
    O2.Free;
  end;
end;

procedure TFPObjectHashTable_TestClear(AContext: TNXTestContext);
var
  HT: TFPObjectHashTable;
  O1, O2: TObject;
begin

  HT := TFPObjectHashTable.Create(False);
  try
    O1 := TObject.Create;
    O2 := TObject.Create;
    HT.Add('Key1', O1);
    HT.Add('Key2', O2);
    HT.Clear;
    AContext.AssertTrue((0) = (HT.Count), 'Count should be 0 after clearing');
    AContext.AssertTrue(HT.IsEmpty, 'IsEmpty should be true after clearing');
  finally
    HT.Free;
    O1.Free;
    O2.Free;
  end;
end;

procedure TFPObjectHashTable_TestItemsProperty(AContext: TNXTestContext);
var
  HT: TFPObjectHashTable;
  O1, O2: TObject;
begin

  HT := TFPObjectHashTable.Create(False);
  try
    O1 := TObject.Create;
    O2 := TObject.Create;
    HT.Items['Key1'] := O1;
    AContext.AssertTrue((1) = (HT.Count), 'Count should be 1 after setting item');
    AContext.AssertTrue((O1) = (HT.Items['Key1']), 'Items property should return correct value');
    HT.Items['Key1'] := O2;
    AContext.AssertTrue((1) = (HT.Count), 'Count should still be 1 after updating item');
    AContext.AssertTrue((O2) = (HT.Items['Key1']), 'Items property should return updated value');
  finally
    HT.Free;
    O1.Free;
    O2.Free;
  end;
end;

procedure TFPObjectHashTable_TestFind(AContext: TNXTestContext);
var
  HT: TFPObjectHashTable;
  O1: TObject;
  Node: THTCustomNode;
begin

  HT := TFPObjectHashTable.Create(False);
  try
    O1 := TObject.Create;
    HT.Add('Key1', O1);
    Node := HT.Find('Key1');
    AContext.AssertTrue((Node) <> nil, 'Find should return a node for an existing key');
    if Node <> nil then
    begin
      AContext.AssertTrue(('Key1') = (Node.Key), 'Node should have the correct key');
      AContext.AssertTrue((O1) = (THTObjectNode(Node).Data), 'Node data should be correct');
    end;

    Node := HT.Find('NonExistentKey');
    AContext.AssertTrue((Node) = nil, 'Find should return nil for a non-existent key');
  finally
    HT.Free;
    O1.Free;
  end;
end;

procedure TFPObjectHashTable_TestOwnsObjects(AContext: TNXTestContext);
var
  HT: TFPObjectHashTable;
  O1: TMyObject;
  Freed: Boolean;
begin

  HT := TFPObjectHashTable.Create(True);
  Freed := False;
  O1 := TMyObject.Create;
  O1.IsFreed := @Freed;
  HT.Add('Key1', O1);
  HT.Free; // This should free O1 as well
  AContext.AssertTrue(Freed, 'Object should be freed when OwnsObjects is true and hash table is freed');
end;

procedure RegisterutcFPObjectHashTableTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCL.Collections.TFPObjectHashTableTests');
  lSuite.AddTest('TestCreate', @TFPObjectHashTable_TestCreate, 'collections');
  lSuite.AddTest('TestAdd', @TFPObjectHashTable_TestAdd, 'collections');
  lSuite.AddTest('TestDelete', @TFPObjectHashTable_TestDelete, 'collections');
  lSuite.AddTest('TestClear', @TFPObjectHashTable_TestClear, 'collections');
  lSuite.AddTest('TestItemsProperty', @TFPObjectHashTable_TestItemsProperty, 'collections');
  lSuite.AddTest('TestFind', @TFPObjectHashTable_TestFind, 'collections');
  lSuite.AddTest('TestOwnsObjects', @TFPObjectHashTable_TestOwnsObjects, 'collections');
end;

end.

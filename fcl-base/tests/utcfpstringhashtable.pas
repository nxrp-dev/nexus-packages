unit utcFPStringHashTable;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, contnrs, obNXTestContext, obNXTestRegistry, obNXTestSuite;

procedure RegisterutcFPStringHashTableTests(ARegistry: TNXTestRegistry);

implementation

procedure TFPStringHashTable_TestCreate(AContext: TNXTestContext);
var
  HT: TFPStringHashTable;
begin

  HT := TFPStringHashTable.Create;
  try
    AContext.AssertTrue((HT) <> nil, 'Hash table should be created');
    AContext.AssertTrue((0) = (HT.Count), 'Count should be 0 on creation');
    AContext.AssertTrue(HT.IsEmpty, 'IsEmpty should be true on creation');
  finally
    HT.Free;
  end;
end;

procedure TFPStringHashTable_TestAdd(AContext: TNXTestContext);
var
  HT: TFPStringHashTable;
begin

  HT := TFPStringHashTable.Create;
  try
    HT.Add('Key1', 'Value1');
    AContext.AssertTrue((1) = (HT.Count), 'Count should be 1 after adding one item');
    AContext.AssertFalse(HT.IsEmpty, 'IsEmpty should be false after adding an item');
    AContext.AssertTrue(('Value1') = (HT.Items['Key1']), 'Items property should return correct value');

    HT.Add('Key2', 'Value2');
    AContext.AssertTrue((2) = (HT.Count), 'Count should be 2 after adding a second item');
    AContext.AssertTrue(('Value2') = (HT.Items['Key2']), 'Items property should return correct value for second item');
  finally
    HT.Free;
  end;
end;

procedure TFPStringHashTable_TestDelete(AContext: TNXTestContext);
var
  HT: TFPStringHashTable;
begin

  HT := TFPStringHashTable.Create;
  try
    HT.Add('Key1', 'Value1');
    HT.Add('Key2', 'Value2');
    HT.Delete('Key1');
    AContext.AssertTrue((1) = (HT.Count), 'Count should be 1 after deleting an item');
    AContext.AssertTrue(('') = (HT.Items['Key1']), 'Accessing deleted key should return empty string');
    AContext.AssertTrue(('Value2') = (HT.Items['Key2']), 'Other item should still exist');
  finally
    HT.Free;
  end;
end;

procedure TFPStringHashTable_TestClear(AContext: TNXTestContext);
var
  HT: TFPStringHashTable;
begin

  HT := TFPStringHashTable.Create;
  try
    HT.Add('Key1', 'Value1');
    HT.Add('Key2', 'Value2');
    HT.Clear;
    AContext.AssertTrue((0) = (HT.Count), 'Count should be 0 after clearing');
    AContext.AssertTrue(HT.IsEmpty, 'IsEmpty should be true after clearing');
  finally
    HT.Free;
  end;
end;

procedure TFPStringHashTable_TestItemsProperty(AContext: TNXTestContext);
var
  HT: TFPStringHashTable;
begin

  HT := TFPStringHashTable.Create;
  try
    HT.Items['Key1'] := 'Value1';
    AContext.AssertTrue((1) = (HT.Count), 'Count should be 1 after setting item');
    AContext.AssertTrue(('Value1') = (HT.Items['Key1']), 'Items property should return correct value');
    HT.Items['Key1'] := 'NewValue1';
    AContext.AssertTrue((1) = (HT.Count), 'Count should still be 1 after updating item');
    AContext.AssertTrue(('NewValue1') = (HT.Items['Key1']), 'Items property should return updated value');
  finally
    HT.Free;
  end;
end;

procedure TFPStringHashTable_TestFind(AContext: TNXTestContext);
var
  HT: TFPStringHashTable;
  Node: THTCustomNode;
begin

  HT := TFPStringHashTable.Create;
  try
    HT.Add('Key1', 'Value1');
    Node := HT.Find('Key1');
    AContext.AssertTrue((Node) <> nil, 'Find should return a node for an existing key');
    if Node <> nil then
      AContext.AssertTrue(('Key1') = (Node.Key), 'Node should have the correct key');

    Node := HT.Find('NonExistentKey');
    AContext.AssertTrue((Node) = nil, 'Find should return nil for a non-existent key');
  finally
    HT.Free;
  end;
end;

procedure RegisterutcFPStringHashTableTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCL.Collections.TFPStringHashTableTests');
  lSuite.AddTest('TestCreate', @TFPStringHashTable_TestCreate, 'collections');
  lSuite.AddTest('TestAdd', @TFPStringHashTable_TestAdd, 'collections');
  lSuite.AddTest('TestDelete', @TFPStringHashTable_TestDelete, 'collections');
  lSuite.AddTest('TestClear', @TFPStringHashTable_TestClear, 'collections');
  lSuite.AddTest('TestItemsProperty', @TFPStringHashTable_TestItemsProperty, 'collections');
  lSuite.AddTest('TestFind', @TFPStringHashTable_TestFind, 'collections');
end;

end.

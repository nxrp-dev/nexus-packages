unit tsNXOrderedContainers;

{$mode objfpc}{$H+}

interface

uses obNXTestRegistry;

procedure RegisterOrderedContainerTests(ARegistry: TNXTestRegistry);

implementation

uses contnrs, obNXTestContext, obNXTestSuite;

procedure CheckPointerOrder(AContext: TNXTestContext; AList: TOrderedList;
  AFirst, ASecond: Pointer);
begin
  try
    AContext.AssertEquals(0, AList.Count, 'Initially empty');
    AContext.AssertTrue(AList.AtLeast(0), 'Empty list has at least zero items');
    AContext.AssertFalse(AList.AtLeast(1), 'Empty list has fewer than one item');
    AContext.AssertTrue(AList.Peek = nil, 'Peek on empty list');
    AContext.AssertTrue(AList.Pop = nil, 'Pop on empty list');
    AContext.AssertTrue(AList.Push(Pointer(1)) = Pointer(1), 'Push returns item');
    AContext.AssertTrue(AList.Peek = Pointer(1), 'Peek after first push');
    AContext.AssertEquals(1, AList.Count, 'Peek retains the item');
    AContext.AssertTrue(AList.AtLeast(1), 'AtLeast after push');
    AContext.AssertTrue(AList.Push(Pointer(2)) = Pointer(2), 'Second push returns item');
    AContext.AssertEquals(2, AList.Count, 'Two items');
    AContext.AssertTrue(AList.Peek = AFirst, 'Peek respects ordering');
    AContext.AssertEquals(2, AList.Count, 'Peek retains both items');
    AContext.AssertTrue(AList.Pop = AFirst, 'First pop respects ordering');
    AContext.AssertEquals(1, AList.Count, 'One item remains');
    AContext.AssertTrue(AList.Peek = ASecond, 'Peek after pop');
    AContext.AssertTrue(AList.Pop = ASecond, 'Second pop');
    AContext.AssertEquals(0, AList.Count, 'Drained');
    AContext.AssertTrue(AList.Pop = nil, 'Pop after draining');
    AContext.AssertTrue(AList.Peek = nil, 'Peek after draining');
  finally
    AList.Free;
  end;
end;

procedure PointerStack(AContext: TNXTestContext);
begin
  CheckPointerOrder(AContext, TStack.Create, Pointer(2), Pointer(1));
end;

procedure PointerQueue(AContext: TNXTestContext);
begin
  CheckPointerOrder(AContext, TQueue.Create, Pointer(1), Pointer(2));
end;

// The typed facades have their own methods; exercise those overloads directly.
procedure ObjectStack(AContext: TNXTestContext);
var
  lStack: TObjectStack;
  lFirst, lSecond: TObject;
begin
  lFirst := TObject.Create;
  lSecond := TObject.Create;
  lStack := TObjectStack.Create;
  try
    AContext.AssertTrue(lStack.Push(lFirst) = lFirst, 'Typed push');
    AContext.AssertTrue(lStack.Push(lSecond) = lSecond, 'Second typed push');
    AContext.AssertTrue(lStack.Peek = lSecond, 'Typed LIFO peek');
    AContext.AssertEquals(2, lStack.Count, 'Typed peek retains both items');
    AContext.AssertTrue(lStack.Pop = lSecond, 'Typed LIFO pop');
    AContext.AssertTrue(lStack.Peek = lFirst, 'Typed peek after pop');
    AContext.AssertTrue(lStack.Pop = lFirst, 'Typed remaining pop');
    AContext.AssertTrue(lStack.Pop = nil, 'Typed empty pop');
    AContext.AssertTrue(lStack.Peek = nil, 'Typed empty peek');
    AContext.AssertEquals(0, lStack.Count, 'Typed stack drained');
  finally
    lStack.Free;
    lSecond.Free;
    lFirst.Free;
  end;
end;

procedure ObjectQueue(AContext: TNXTestContext);
var
  lQueue: TObjectQueue;
  lFirst, lSecond: TObject;
begin
  lFirst := TObject.Create;
  lSecond := TObject.Create;
  lQueue := TObjectQueue.Create;
  try
    AContext.AssertTrue(lQueue.Push(lFirst) = lFirst, 'Typed push');
    AContext.AssertTrue(lQueue.Push(lSecond) = lSecond, 'Second typed push');
    AContext.AssertTrue(lQueue.Peek = lFirst, 'Typed FIFO peek');
    AContext.AssertEquals(2, lQueue.Count, 'Typed peek retains both items');
    AContext.AssertTrue(lQueue.Pop = lFirst, 'Typed FIFO pop');
    AContext.AssertTrue(lQueue.Peek = lSecond, 'Typed peek after pop');
    AContext.AssertTrue(lQueue.Pop = lSecond, 'Typed remaining pop');
    AContext.AssertTrue(lQueue.Pop = nil, 'Typed empty pop');
    AContext.AssertTrue(lQueue.Peek = nil, 'Typed empty peek');
    AContext.AssertEquals(0, lQueue.Count, 'Typed queue drained');
  finally
    lQueue.Free;
    lSecond.Free;
    lFirst.Free;
  end;
end;

procedure RegisterOrderedContainerTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCL.Collections.OrderedContainers');
  lSuite.AddTest('PointerStack', @PointerStack, 'collections');
  lSuite.AddTest('PointerQueue', @PointerQueue, 'collections');
  lSuite.AddTest('ObjectStack', @ObjectStack, 'collections');
  lSuite.AddTest('ObjectQueue', @ObjectQueue, 'collections');
end;

end.

// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit tsX11CoreTests;
{$mode objfpc}{$H+}
interface
uses obNXTestRegistry;
procedure RegisterX11CoreTests(ARegistry: TNXTestRegistry);
implementation
uses SysUtils, ctypes, x, xlib, xkb, xi2, obNXTestSuite, obNXTestContext;

procedure TestGroupAction(AContext: TNXTestContext);
var lAction: TXkbAnyAction; lType: Integer;
begin
  FillChar(lAction, SizeOf(lAction), 0);
  for lType := 0 to 255 do
  begin
    lAction._type := lType;
    AContext.AssertTrue(Boolean(XkbIsGroupAction(@lAction)) =
      ((lType >= XkbSA_SetGroup) and (lType <= XkbSA_LockGroup)),
      'Action type ' + IntToStr(lType));
  end;
end;

procedure TestSignedBytes(AContext: TNXTestContext);
begin
  AContext.AssertEquals(-2, XkbCharToInt($FE));
  AContext.AssertEquals(-128, XkbCharToInt($80));
  AContext.AssertEquals(127, XkbCharToInt($7F));
end;

procedure TestSignedWords(AContext: TNXTestContext);
begin
  AContext.AssertEquals(-2, Xkb2CharsToInt($FF, $FE));
  AContext.AssertEquals(-32768, Xkb2CharsToInt($80, 0));
  AContext.AssertEquals(32767, Xkb2CharsToInt($7F, $FF));
end;

procedure TestModAction(AContext: TNXTestContext);
var lAction: TXkbModAction; lValue: Word;
begin
  FillChar(lAction, SizeOf(lAction), 0);
  lValue := $ABCD;
  XkbSetModActionVMods(@lAction, lValue);
  AContext.AssertEquals($AB, lAction.vmods1);
  AContext.AssertEquals($CD, lAction.vmods2);
  AContext.AssertEquals($ABCD, XkbModActionVMods(@lAction));
end;

procedure TestPointerWrite(AContext: TNXTestContext);
var lAction: TXkbPtrAction; lX, lY: SmallInt;
begin
  FillChar(lAction, SizeOf(lAction), 0);
  lX := -257; lY := 1025;
  XkbSetPtrActionX(@lAction, lX);
  XkbSetPtrActionY(@lAction, lY);
  AContext.AssertEquals($FE, lAction.high_XXX);
  AContext.AssertEquals($FF, lAction.low_XXX);
  AContext.AssertEquals(4, lAction.high_YYY);
  AContext.AssertEquals(1, lAction.low_YYY);
end;

procedure TestPointerRead(AContext: TNXTestContext);
var lAction: TXkbPtrAction;
begin
  FillChar(lAction, SizeOf(lAction), 0);
  lAction.high_XXX := $FE; lAction.low_XXX := $FF;
  lAction.high_YYY := $80; lAction.low_YYY := 0;
  AContext.AssertEquals(-257, XkbPtrActionX(@lAction));
  AContext.AssertEquals(-32768, XkbPtrActionY(@lAction));
end;

procedure TestSignedActions(AContext: TNXTestContext);
var lGroup: TXkbGroupAction; lPointer: TXkbPtrDfltAction;
  lScreen: TXkbSwitchScreenAction; lValue: ShortInt;
begin
  FillChar(lGroup, SizeOf(lGroup), 0);
  FillChar(lPointer, SizeOf(lPointer), 0);
  FillChar(lScreen, SizeOf(lScreen), 0);
  lValue := -3;
  XkbSASetGroup(@lGroup, lValue);
  AContext.AssertEquals(-3, XkbSAGroup(@lGroup));
  XkbSASetPtrDfltValue(@lPointer, lValue);
  AContext.AssertEquals(-3, XkbSAPtrDfltValue(@lPointer));
  XkbSASetScreen(@lScreen, lValue);
  AContext.AssertEquals(-3, XkbSAScreen(@lScreen));
end;

procedure TestControls(AContext: TNXTestContext);
var lAction: TXkbCtrlsAction; lValue: Cardinal;
begin
  FillChar(lAction, SizeOf(lAction), 0);
  lValue := $89ABCDEF;
  XkbActionSetCtrls(@lAction, lValue);
  AContext.AssertEquals($89, lAction.ctrls3);
  AContext.AssertEquals($AB, lAction.ctrls2);
  AContext.AssertEquals($CD, lAction.ctrls1);
  AContext.AssertEquals($EF, lAction.ctrls0);
  AContext.AssertTrue(XkbActionCtrls(@lAction) = lValue);
end;

procedure TestRedirectValue(AContext: TNXTestContext);
var lAction: TXkbRedirectKeyAction;
begin
  FillChar(lAction, SizeOf(lAction), 0);
  lAction.vmods_mask1 := $A5; lAction.vmods_mask0 := $5A;
  XkbSARedirectSetVMods(@lAction, $12);
  AContext.AssertEquals($12, XkbSARedirectVMods(@lAction));
  AContext.AssertEquals($A55A, XkbSARedirectVModsMask(@lAction));
end;

procedure TestRedirectWidths(AContext: TNXTestContext);
var lAction: TXkbRedirectKeyAction; lValue, lMask: Word;
begin
  FillChar(lAction, SizeOf(lAction), 0);
  lValue := $ABCD; lMask := $A55A;
  XkbSARedirectSetVMods(@lAction, lValue);
  XkbSARedirectSetVModsMask(@lAction, lMask);
  AContext.AssertEquals($ABCD, XkbSARedirectVMods(@lAction));
  AContext.AssertEquals($A55A, XkbSARedirectVModsMask(@lAction));
end;

procedure TestSymbolCount(AContext: TNXTestContext);
var lMap: TXkbClientMapRec; lKeys: array[0..8] of TXkbSymMapRec;
begin
  FillChar(lMap, SizeOf(lMap), 0);
  FillChar(lKeys, SizeOf(lKeys), 0);
  lMap.key_sym_map := @lKeys[0];
  lKeys[8].width := 3; lKeys[8].group_info := 2;
  AContext.AssertEquals(6, XkbCMKeyNumSyms(@lMap, 8));
end;

procedure TestSymbolOffset(AContext: TNXTestContext);
var lMap: TXkbClientMapRec; lKeys: array[0..8] of TXkbSymMapRec;
  lSymbols: array[0..513] of TKeySym;
begin
  FillChar(lMap, SizeOf(lMap), 0);
  FillChar(lKeys, SizeOf(lKeys), 0);
  FillChar(lSymbols, SizeOf(lSymbols), 0);
  lMap.key_sym_map := @lKeys[0]; lMap.syms := @lSymbols[0];
  lKeys[8].offset := 512; lSymbols[512] := $1234;
  AContext.AssertEquals(512, XkbCMKeySymsOffset(@lMap, 8));
  AContext.AssertTrue(XkbCMKeySymsPtr(@lMap, 8) = @lSymbols[512]);
  AContext.AssertEquals($1234, XkbCMKeySymsPtr(@lMap, 8)^);
end;

procedure TestActionEntry(AContext: TNXTestContext);
var lDesc: TXkbDescRec; lMap: TXkbClientMapRec; lServer: TXkbServerMapRec;
  lKeys: array[0..8] of TXkbSymMapRec; lOffsets: array[0..8] of Word;
  lActions: array[0..7] of TXkbAction;
begin
  FillChar(lDesc, SizeOf(lDesc), 0); FillChar(lMap, SizeOf(lMap), 0);
  FillChar(lServer, SizeOf(lServer), 0); FillChar(lKeys, SizeOf(lKeys), 0);
  FillChar(lOffsets, SizeOf(lOffsets), 0); FillChar(lActions, SizeOf(lActions), 0);
  lDesc.map := @lMap; lDesc.server := @lServer;
  lMap.key_sym_map := @lKeys[0]; lKeys[8].width := 2;
  lServer.key_acts := @lOffsets[0]; lServer.acts := @lActions[0];
  lOffsets[8] := 1;
  AContext.AssertTrue(PtrUInt(XkbKeyActionEntry(@lDesc, 8, 1, 1)) =
    PtrUInt(@lActions[4]), 'Return the selected action address');
  lOffsets[8] := 0;
  AContext.AssertTrue(PtrUInt(XkbKeyActionEntry(@lDesc, 8, 1, 1)) = 0);
  AContext.AssertTrue(XkbKeyAction(@lDesc, 8, 0) = nil);
end;

procedure TestGeometryBounds(AContext: TNXTestContext);
var lBounds: TXkbBoundsRec;
begin
  lBounds.x1 := -32000; lBounds.x2 := 32000;
  lBounds.y1 := -30000; lBounds.y2 := 30000;
  AContext.AssertEquals(64000, XkbBoundsWidth(@lBounds));
  AContext.AssertEquals(60000, XkbBoundsHeight(@lBounds));
end;

procedure TestGeometryShape(AContext: TNXTestContext);
var lGeometry: TXkbGeometryRec; lIndicator: TXkbIndicatorDoodadRec;
  lLogo: TXkbLogoDoodadRec; lKey: TXkbKeyRec;
  lShapes: array[0..1] of TXkbShapeRec;
begin
  FillChar(lGeometry, SizeOf(lGeometry), 0);
  FillChar(lIndicator, SizeOf(lIndicator), 0); FillChar(lLogo, SizeOf(lLogo), 0);
  FillChar(lKey, SizeOf(lKey), 0); FillChar(lShapes, SizeOf(lShapes), 0);
  lGeometry.shapes := @lShapes[0];
  lIndicator.shape_ndx := 1; lLogo.shape_ndx := 1; lKey.shape_ndx := 1;
  AContext.AssertEquals(SizeOf(TXkbShapeRec),
    SizeOf(XkbIndicatorDoodadShape(@lGeometry, @lIndicator)^));
  AContext.AssertEquals(SizeOf(TXkbShapeRec),
    SizeOf(XkbLogoDoodadShape(@lGeometry, @lLogo)^));
  AContext.AssertEquals(SizeOf(TXkbShapeRec),
    SizeOf(XkbKeyShape(@lGeometry, @lKey)^));
  AContext.AssertTrue(Pointer(XkbKeyShape(@lGeometry, @lKey)) = @lShapes[1]);
end;

procedure TestXIMasks(AContext: TNXTestContext);
var lMask: array[0..7] of cuchar; lEvent: Integer;
begin
  FillChar(lMask, SizeOf(lMask), 0);
  for lEvent := 0 to 63 do XISetMask(@lMask[0], lEvent);
  for lEvent := 0 to 63 do AContext.AssertTrue(XIMaskIsSet(@lMask[0], lEvent));
  for lEvent := 0 to 63 do
  begin
    XIClearMask(@lMask[0], lEvent);
    AContext.AssertFalse(XIMaskIsSet(@lMask[0], lEvent));
  end;
  AContext.AssertEquals(8, XIMaskLen(63));
end;

procedure TestKeyboardRecord(AContext: TNXTestContext);
var lEntry: TXkbKTMapEntryRec;
begin
  AContext.AssertEquals(SizeOf(cint), SizeOf(lEntry.active));
  AContext.AssertEquals(4, PtrUInt(@lEntry.level) - PtrUInt(@lEntry));
  AContext.AssertEquals(12, SizeOf(lEntry));
end;

procedure RegisterX11CoreTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('X11Core');
  lSuite.AddTest('GroupAction', @TestGroupAction);
  lSuite.AddTest('SignedBytes', @TestSignedBytes);
  lSuite.AddTest('SignedWords', @TestSignedWords);
  lSuite.AddTest('ModAction', @TestModAction);
  lSuite.AddTest('PointerWrite', @TestPointerWrite);
  lSuite.AddTest('PointerRead', @TestPointerRead);
  lSuite.AddTest('SignedActions', @TestSignedActions);
  lSuite.AddTest('Controls', @TestControls);
  lSuite.AddTest('RedirectValue', @TestRedirectValue);
  lSuite.AddTest('RedirectWidths', @TestRedirectWidths);
  lSuite.AddTest('SymbolCount', @TestSymbolCount);
  lSuite.AddTest('SymbolOffset', @TestSymbolOffset);
  lSuite.AddTest('ActionEntry', @TestActionEntry);
  lSuite.AddTest('GeometryBounds', @TestGeometryBounds);
  lSuite.AddTest('GeometryShape', @TestGeometryShape);
  lSuite.AddTest('XIMasks', @TestXIMasks);
  lSuite.AddTest('KeyboardRecord', @TestKeyboardRecord);
end;
end.

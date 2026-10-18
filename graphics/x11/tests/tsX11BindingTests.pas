// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit tsX11BindingTests;
{$mode objfpc}{$H+}
interface
uses obNXTestRegistry;
procedure RegisterX11BindingTests(ARegistry: TNXTestRegistry);
implementation
uses SysUtils, Dynlibs, ctypes, x, xlib, xrender, xshm, xi, xinput, xkb, xkblib,
  xft, fontconfig, tpX11Libraries, obNXTestSuite, obNXTestContext;

type
  TFcFontSetCreate = function: PFcFontSet; cdecl;

function OpenTestDisplay(AContext: TNXTestContext): PDisplay;
begin
  Result := XOpenDisplay(nil);
  if Result = nil then AContext.Skip('No accessible X display; run with Xvfb.');
end;

procedure CheckSymbols(AContext: TNXTestContext; const ALibrary: string;
  const ASymbols: array of string);
var lLibrary: TLibHandle; lSymbol: string;
begin
  lLibrary := LoadLibrary(ALibrary);
  AContext.AssertTrue(lLibrary <> NilHandle, 'Load ' + ALibrary);
  try
    for lSymbol in ASymbols do
      AContext.AssertTrue(GetProcedureAddress(lLibrary, lSymbol) <> nil,
        ALibrary + ': ' + lSymbol);
  finally UnloadLibrary(lLibrary); end;
end;

procedure TestRuntimeLibraries(AContext: TNXTestContext);
var lLibrary: TLibHandle; lCreate: TFcFontSetCreate; lFontSet: PFcFontSet;
begin
  AContext.AssertEquals('libX11.so.6', tpX11Libraries.libX11);
  AContext.AssertEquals('libXext.so.6', tpX11Libraries.libXext);
  AContext.AssertEquals('libXft.so.2', tpX11Libraries.libXft);
  CheckSymbols(AContext, 'libXrender.so.1', ['XRenderFindVisualFormat']);
  CheckSymbols(AContext, 'libXext.so.6', ['XShmQueryVersion']);
  CheckSymbols(AContext, 'libXi.so.6', ['_XiGetDevicePresenceNotifyEvent']);
  lLibrary := LoadLibrary('libfontconfig.so.1');
  AContext.AssertTrue(lLibrary <> NilHandle);
  try
    lCreate := TFcFontSetCreate(GetProcedureAddress(lLibrary, 'FcFontSetCreate'));
    AContext.AssertTrue(Assigned(lCreate));
    lFontSet := lCreate();
    AContext.AssertTrue(lFontSet <> nil);
    try
      AContext.AssertEquals(0, lFontSet^.nfont);
    finally FcFontSetDestroy(lFontSet); end;
  finally UnloadLibrary(lLibrary); end;
end;

procedure TestRenderABI(AContext: TNXTestContext);
var lFormat: TXRenderPictFormat; lAttributes: TXRenderPictureAttributes;
begin
  AContext.AssertEquals(SizeOf(culong), SizeOf(xrender.TGlyph));
  AContext.AssertEquals(SizeOf(culong), SizeOf(xrender.TGlyphSet));
  AContext.AssertEquals(SizeOf(culong), SizeOf(xrender.TPicture));
  AContext.AssertEquals(SizeOf(culong), SizeOf(xrender.TPictFormat));
  if SizeOf(Pointer) = 8 then
  begin
    AContext.AssertEquals(40, SizeOf(lFormat));
    AContext.AssertEquals(8, PtrUInt(@lFormat._type) - PtrUInt(@lFormat));
    AContext.AssertEquals(72, SizeOf(lAttributes));
    AContext.AssertEquals(56, PtrUInt(@lAttributes.dither) - PtrUInt(@lAttributes));
  end
  else
  begin
    AContext.AssertEquals(32, SizeOf(lFormat));
    AContext.AssertEquals(52, SizeOf(lAttributes));
  end;
end;

procedure TestXftABI(AContext: TNXTestContext);
begin
  AContext.AssertEquals(SizeOf(culong), SizeOf(xft.TPicture));
end;

procedure TestFontconfigABI(AContext: TNXTestContext);
begin
  AContext.AssertEquals(SizeOf(cint), SizeOf(TFcType));
  if SizeOf(Pointer) = 8 then AContext.AssertEquals(16, SizeOf(TFcValue))
  else AContext.AssertEquals(12, SizeOf(TFcValue));
end;

procedure TestRenderRuntime(AContext: TNXTestContext);
var lDisplay: PDisplay; lScreen: cint; lFormat: PXRenderPictFormat;
  lPixmap: TPixmap; lPicture: xrender.TPicture;
begin
  lDisplay := OpenTestDisplay(AContext);
  try
    lScreen := XDefaultScreen(lDisplay);
    lFormat := XRenderFindVisualFormat(lDisplay, XDefaultVisual(lDisplay, lScreen));
    AContext.AssertTrue(lFormat <> nil);
    AContext.AssertEquals(XDefaultDepth(lDisplay, lScreen), lFormat^.depth);
    lPixmap := XCreatePixmap(lDisplay, XDefaultRootWindow(lDisplay), 4, 4,
      XDefaultDepth(lDisplay, lScreen));
    try
      lPicture := XRenderCreatePicture(lDisplay, lPixmap, lFormat, 0, nil);
      AContext.AssertTrue(lPicture <> 0);
      XRenderFreePicture(lDisplay, lPicture);
    finally XFreePixmap(lDisplay, lPixmap); end;
    XSync(lDisplay, False);
  finally XCloseDisplay(lDisplay); end;
end;

procedure TestShmRuntime(AContext: TNXTestContext);
var lDisplay: PDisplay; lMajor, lMinor: cint; lPixmaps: TBool;
begin
  lDisplay := OpenTestDisplay(AContext);
  try
    AContext.AssertTrue(XShmQueryExtension(lDisplay));
    AContext.AssertTrue(XShmQueryVersion(lDisplay, @lMajor, @lMinor, @lPixmaps));
    AContext.AssertTrue(lMajor >= 1);
  finally XCloseDisplay(lDisplay); end;
end;

procedure TestDevicePresence(AContext: TNXTestContext);
var lDisplay: PDisplay; lType: cint; lClass: TXEventClass;
begin
  lDisplay := OpenTestDisplay(AContext);
  try
    lType := 0; lClass := $ABCD;
    DevicePresence(lDisplay, lType, lClass);
    AContext.AssertTrue(lType > 0);
    AContext.AssertTrue(lClass = $10000, 'Return the DevicePresence event class');
  finally XCloseDisplay(lDisplay); end;
end;

procedure TestKeyboardMap(AContext: TNXTestContext);
var lDisplay: PDisplay; lMap: PXkbDescPtr;
begin
  lDisplay := OpenTestDisplay(AContext);
  try
    lMap := XkbGetMap(lDisplay, XkbAllClientInfoMask, XkbUseCoreKbd);
    AContext.AssertTrue(lMap <> nil);
    try
      AContext.AssertTrue(lMap^.map <> nil);
      AContext.AssertTrue(lMap^.max_key_code >= lMap^.min_key_code);
      AContext.AssertTrue(lMap^.map^.num_syms > 0);
    finally XkbFreeKeyboard(lMap, 0, True); end;
  finally XCloseDisplay(lDisplay); end;
end;

procedure TestSymbolsdpms(AContext: TNXTestContext);
begin
  CheckSymbols(AContext, 'libXext.so.6', [
    'DPMSQueryExtension', 'DPMSGetVersion', 'DPMSCapable',
    'DPMSSetTimeouts', 'DPMSGetTimeouts', 'DPMSEnable',
    'DPMSDisable', 'DPMSForceLevel', 'DPMSInfo']);
end;

procedure TestSymbolsmitmisc(AContext: TNXTestContext);
begin
  CheckSymbols(AContext, 'libXext.so.6', [
    'XMITMiscQueryExtension', 'XMITMiscSetBugMode', 'XMITMiscGetBugMode']);
end;

procedure TestSymbolsmultibuf(AContext: TNXTestContext);
begin
  CheckSymbols(AContext, 'libXext.so.6', [
    'XmbufQueryExtension', 'XmbufGetVersion', 'XmbufCreateBuffers',
    'XmbufDestroyBuffers', 'XmbufDisplayBuffers', 'XmbufGetWindowAttributes',
    'XmbufChangeWindowAttributes', 'XmbufGetBufferAttributes', 'XmbufChangeBufferAttributes',
    'XmbufGetScreenInfo', 'XmbufCreateStereoWindow', 'XmbufClearBufferArea']);
end;

procedure TestSymbolssecurity(AContext: TNXTestContext);
begin
  CheckSymbols(AContext, 'libXext.so.6', [
    'XSecurityQueryExtension', 'XSecurityFreeXauth', 'XSecurityGenerateAuthorization',
    'XSecurityRevokeAuthorization']);
end;

procedure TestSymbolsshape(AContext: TNXTestContext);
begin
  CheckSymbols(AContext, 'libXext.so.6', [
    'XShapeQueryExtension', 'XShapeQueryVersion', 'XShapeCombineRegion',
    'XShapeCombineRectangles', 'XShapeCombineMask', 'XShapeCombineShape',
    'XShapeOffsetShape', 'XShapeQueryExtents', 'XShapeSelectInput',
    'XShapeInputSelected', 'XShapeGetRectangles']);
end;

procedure TestSymbolssync(AContext: TNXTestContext);
begin
  CheckSymbols(AContext, 'libXext.so.6', [
    'XSyncIntToValue', 'XSyncIntsToValue', 'XSyncValueGreaterThan',
    'XSyncValueLessThan', 'XSyncValueGreaterOrEqual', 'XSyncValueLessOrEqual',
    'XSyncValueEqual', 'XSyncValueIsNegative', 'XSyncValueIsZero',
    'XSyncValueIsPositive', 'XSyncValueLow32', 'XSyncValueHigh32',
    'XSyncValueAdd', 'XSyncValueSubtract', 'XSyncMaxValue',
    'XSyncMinValue', 'XSyncQueryExtension', 'XSyncInitialize',
    'XSyncListSystemCounters', 'XSyncFreeSystemCounterList', 'XSyncCreateCounter',
    'XSyncSetCounter', 'XSyncChangeCounter', 'XSyncDestroyCounter',
    'XSyncQueryCounter', 'XSyncAwait', 'XSyncCreateAlarm',
    'XSyncDestroyAlarm', 'XSyncQueryAlarm', 'XSyncChangeAlarm',
    'XSyncSetPriority', 'XSyncGetPriority', 'XSyncCreateFence',
    'XSyncTriggerFence', 'XSyncResetFence', 'XSyncDestroyFence',
    'XSyncQueryFence', 'XSyncAwaitFence']);
end;

procedure TestSymbolsxag(AContext: TNXTestContext);
begin
  CheckSymbols(AContext, 'libXext.so.6', [
    'XagQueryVersion', 'XagCreateEmbeddedApplicationGroup', 'XagCreateNonembeddedApplicationGroup',
    'XagDestroyApplicationGroup', 'XagGetApplicationGroupAttributes', 'XagQueryApplicationGroup',
    'XagCreateAssociation', 'XagDestroyAssociation']);
end;

procedure TestSymbolsxcup(AContext: TNXTestContext);
begin
  CheckSymbols(AContext, 'libXext.so.6', [
    'XcupQueryVersion', 'XcupGetReservedColormapEntries', 'XcupStoreColors']);
end;

procedure TestSymbolsxdbe(AContext: TNXTestContext);
begin
  CheckSymbols(AContext, 'libXext.so.6', [
    'XdbeQueryExtension', 'XdbeAllocateBackBufferName', 'XdbeDeallocateBackBufferName',
    'XdbeSwapBuffers', 'XdbeBeginIdiom', 'XdbeEndIdiom',
    'XdbeGetVisualInfo', 'XdbeFreeVisualInfo', 'XdbeGetBackBufferAttributes']);
end;

procedure TestSymbolsxevi(AContext: TNXTestContext);
begin
  CheckSymbols(AContext, 'libXext.so.6', [
    'XeviQueryExtension', 'XeviQueryVersion', 'XeviGetVisualInfo']);
end;

procedure TestSymbolsxext(AContext: TNXTestContext);
begin
  CheckSymbols(AContext, 'libXext.so.6', [
    'XSetExtensionErrorHandler', 'XMissingExtension']);
end;

procedure TestSymbolsxfixes(AContext: TNXTestContext);
begin
  CheckSymbols(AContext, 'libXfixes.so.3', [
    'XFixesQueryExtension', 'XFixesQueryVersion', 'XFixesSelectSelectionInput',
    'XFixesSelectCursorInput', 'XFixesGetCursorImage', 'XFixesCreateRegion',
    'XFixesCreateRegionFromBitmap', 'XFixesCreateRegionFromWindow', 'XFixesCreateRegionFromGC',
    'XFixesCreateRegionFromPicture', 'XFixesDestroyRegion', 'XFixesSetRegion',
    'XFixesCopyRegion', 'XFixesUnionRegion', 'XFixesIntersectRegion',
    'XFixesSubtractRegion', 'XFixesInvertRegion', 'XFixesTranslateRegion',
    'XFixesRegionExtents', 'XFixesFetchRegion', 'XFixesFetchRegionAndBounds',
    'XFixesSetGCClipRegion', 'XFixesSetWindowShapeRegion', 'XFixesSetPictureClipRegion',
    'XFixesSetCursorName', 'XFixesGetCursorName', 'XFixesChangeCursor',
    'XFixesChangeCursorByName', 'XFixesExpandRegion', 'XFixesHideCursor',
    'XFixesShowCursor', 'XFixesCreatePointerBarrier', 'XFixesDestroyPointerBarrier']);
end;

procedure TestSymbolsxge(AContext: TNXTestContext);
begin
  CheckSymbols(AContext, 'libXext.so.6', [
    'XGEQueryExtension', 'XGEQueryVersion']);
end;

procedure TestSymbolsxinput2(AContext: TNXTestContext);
begin
  CheckSymbols(AContext, 'libXi.so.6', [
    'XIQueryPointer', 'XIWarpPointer', 'XIDefineCursor',
    'XIUndefineCursor', 'XIChangeHierarchy', 'XISetClientPointer',
    'XIGetClientPointer', 'XISelectEvents', 'XIGetSelectedEvents',
    'XIQueryVersion', 'XIQueryDevice', 'XISetFocus',
    'XIGetFocus', 'XIGrabDevice', 'XIUngrabDevice',
    'XIAllowEvents', 'XIAllowTouchEvents', 'XIGrabButton',
    'XIGrabKeycode', 'XIGrabEnter', 'XIGrabFocusIn',
    'XIGrabTouchBegin', 'XIUngrabButton', 'XIUngrabKeycode',
    'XIUngrabEnter', 'XIUngrabFocusIn', 'XIUngrabTouchBegin',
    'XIListProperties', 'XIChangeProperty', 'XIDeleteProperty',
    'XIGetProperty', 'XIBarrierReleasePointers', 'XIBarrierReleasePointer',
    'XIFreeDeviceInfo']);
end;

procedure TestSymbolsxinput(AContext: TNXTestContext);
begin
  CheckSymbols(AContext, 'libXi.so.6', [
    'XChangeKeyboardDevice', 'XChangePointerDevice', 'XGrabDevice',
    'XUngrabDevice', 'XGrabDeviceKey', 'XUngrabDeviceKey',
    'XGrabDeviceButton', 'XUngrabDeviceButton', 'XAllowDeviceEvents',
    'XGetDeviceFocus', 'XSetDeviceFocus', 'XGetFeedbackControl',
    'XFreeFeedbackList', 'XChangeFeedbackControl', 'XDeviceBell',
    'XGetDeviceKeyMapping', 'XChangeDeviceKeyMapping', 'XGetDeviceModifierMapping',
    'XSetDeviceModifierMapping', 'XSetDeviceButtonMapping', 'XGetDeviceButtonMapping',
    'XQueryDeviceState', 'XFreeDeviceState', 'XGetExtensionVersion',
    'XListInputDevices', 'XFreeDeviceList', 'XOpenDevice',
    'XCloseDevice', 'XSetDeviceMode', 'XSetDeviceValuators',
    'XGetDeviceControl', 'XChangeDeviceControl', 'XSelectExtensionEvent',
    'XGetSelectedExtensionEvents', 'XChangeDeviceDontPropagateList', 'XGetDeviceDontPropagateList',
    'XSendExtensionEvent', 'XGetDeviceMotionEvents', 'XFreeDeviceMotionEvents',
    'XFreeDeviceControl', 'XListDeviceProperties', 'XChangeDeviceProperty',
    'XDeleteDeviceProperty', 'XGetDeviceProperty']);
end;

procedure TestSymbolsxlbx(AContext: TNXTestContext);
begin
  CheckSymbols(AContext, 'libXext.so.6', [
    'XLbxQueryExtension', 'XLbxQueryVersion', 'XLbxGetEventBase']);
end;

procedure TestSymbolsxtestext1(AContext: TNXTestContext);
begin
  CheckSymbols(AContext, 'libXext.so.6', [
    'XTestFakeInput', 'XTestGetInput', 'XTestQueryInputSize',
    'XTestPressKey', 'XTestPressButton', 'XTestMovePointer',
    'XTestFlush', 'XTestStopInput', 'XTestReset']);
end;

procedure RegisterX11BindingTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('X11Bindings');
  lSuite.AddTest('RuntimeLibraries', @TestRuntimeLibraries);
  lSuite.AddTest('RenderABI', @TestRenderABI);
  lSuite.AddTest('XftABI', @TestXftABI);
  lSuite.AddTest('FontconfigABI', @TestFontconfigABI);
  lSuite.AddTest('RenderRuntime', @TestRenderRuntime);
  lSuite.AddTest('ShmRuntime', @TestShmRuntime);
  lSuite.AddTest('DevicePresence', @TestDevicePresence);
  lSuite.AddTest('KeyboardMap', @TestKeyboardMap);
  lSuite.AddTest('Symbolsdpms', @TestSymbolsdpms);
  lSuite.AddTest('Symbolsmitmisc', @TestSymbolsmitmisc);
  lSuite.AddTest('Symbolsmultibuf', @TestSymbolsmultibuf);
  lSuite.AddTest('Symbolssecurity', @TestSymbolssecurity);
  lSuite.AddTest('Symbolsshape', @TestSymbolsshape);
  lSuite.AddTest('Symbolssync', @TestSymbolssync);
  lSuite.AddTest('Symbolsxag', @TestSymbolsxag);
  lSuite.AddTest('Symbolsxcup', @TestSymbolsxcup);
  lSuite.AddTest('Symbolsxdbe', @TestSymbolsxdbe);
  lSuite.AddTest('Symbolsxevi', @TestSymbolsxevi);
  lSuite.AddTest('Symbolsxext', @TestSymbolsxext);
  lSuite.AddTest('Symbolsxfixes', @TestSymbolsxfixes);
  lSuite.AddTest('Symbolsxge', @TestSymbolsxge);
  lSuite.AddTest('Symbolsxinput2', @TestSymbolsxinput2);
  lSuite.AddTest('Symbolsxinput', @TestSymbolsxinput);
  lSuite.AddTest('Symbolsxlbx', @TestSymbolsxlbx);
  lSuite.AddTest('Symbolsxtestext1', @TestSymbolsxtestext1);
end;
end.

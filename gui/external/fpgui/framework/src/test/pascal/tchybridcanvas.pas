(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tchybridcanvas;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, fpg_base, fpg_widget,
  fpg_hybrid_canvas;

type
  TMemoryBufferManager = class(TInterfacedObject, IBufferManager)
  private
    FStorage: array of LongWord;
    FWidth, FHeight, FRowPixels: Integer;
  public
    procedure AttachWindow(AWindow: TfpgWindowBase);
    procedure DetachWindow;
    procedure AllocateBuffer(AWidth, AHeight: Integer;
      out AData: Pointer; out AStride: Integer);
    function BufferAllocated: Boolean;
    procedure FreeBuffer;
    procedure PutBufferToScreen(x, y, w, h: TfpgCoord);
    procedure RestoreFromBuffer(const ARect: TfpgRect);
  end;

  TTestableHybridCanvas = class(THybridCanvas)
  public
    procedure Allocate;
    procedure Attach(ATarget: TTestableHybridCanvas; AX, AY: Integer);
  end;

  TTestHybridCanvas = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FSavedFactory: TBufferManagerFactory;
    FSurfaceWidget, FChildWidget: TfpgWidget;
    FSurface, FChild: TTestableHybridCanvas;
    FMemory: TMemoryBufferManager;
    procedure AttachChild(AX, AY, AWidth, AHeight: Integer);
    procedure AssertPixels(const ARect: TfpgRect; AExact: Boolean = True);
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    procedure OversizedChildCannotWrapRows;
    procedure NegativeOriginStaysInBuffer;
    procedure OffSurfaceChildWritesNothing;
    procedure ClipCoordinatesRemainLocal;
    procedure ExplicitClipCanExtendOutsideChild;
    procedure ClearClipRestoresChildArea;
    procedure AggRenderingStaysInBuffer;
    procedure TextRenderingStaysInBuffer;
    procedure ImageBlitStaysInBuffer;
    procedure XorAndPixelsStayInBuffer;
    procedure PopupHasIndependentSurface;
  end;

procedure RegistertchybridcanvasTests(ARegistry: TNXTestRegistry);

implementation

uses
  fpg_main, fpg_form, fpg_popupwindow;

const
  cGuardPixels = 32;
  cSentinel = LongWord($A5A5A5A5);
  cFillColor = TfpgColor($00224466);
  cFillPixel = LongWord($FF224466);

var
  uLastManager: TMemoryBufferManager;

function CreateMemoryBufferManager: IBufferManager;
begin
  uLastManager := TMemoryBufferManager.Create;
  Result := uLastManager;
end;

procedure TMemoryBufferManager.AttachWindow(AWindow: TfpgWindowBase); begin end;
procedure TMemoryBufferManager.DetachWindow; begin end;
procedure TMemoryBufferManager.PutBufferToScreen(x, y, w, h: TfpgCoord); begin end;
procedure TMemoryBufferManager.RestoreFromBuffer(const ARect: TfpgRect); begin end;

procedure TMemoryBufferManager.AllocateBuffer(AWidth, AHeight: Integer;
  out AData: Pointer; out AStride: Integer);
var
  lIndex: Integer;
begin
  FWidth := AWidth;
  FHeight := AHeight;
  FRowPixels := AWidth + 8;
  SetLength(FStorage, cGuardPixels * 2 + FRowPixels * AHeight);
  for lIndex := 0 to High(FStorage) do
    FStorage[lIndex] := cSentinel;
  AData := @FStorage[cGuardPixels];
  AStride := FRowPixels * SizeOf(LongWord);
end;

function TMemoryBufferManager.BufferAllocated: Boolean;
begin
  Result := Length(FStorage) <> 0;
end;

procedure TMemoryBufferManager.FreeBuffer;
begin
  FStorage := nil;
end;

procedure TTestableHybridCanvas.Allocate;
begin
  DoAllocateBuffer;
  Attach(Self, 0, 0);
end;

procedure TTestableHybridCanvas.Attach(ATarget: TTestableHybridCanvas;
  AX, AY: Integer);
begin
  FCanvasTarget := ATarget;
  FDeltaX := AX;
  FDeltaY := AY;
  DoBeginDraw(Widget, ATarget);
  ClearClipRect;
end;

procedure TTestHybridCanvas.SetUp;
begin
  if not fpgApplication.IsInitialized then
    fpgApplication.Initialize;
  FSavedFactory := CreateBufferManager;
  CreateBufferManager := @CreateMemoryBufferManager;
  FSurfaceWidget := TfpgWidget.Create(nil);
  FSurfaceWidget.SetPosition(0, 0, 20, 20);
  FSurface := TTestableHybridCanvas.Create(FSurfaceWidget);
  FMemory := uLastManager;
  FSurface.Allocate;
  FChildWidget := TfpgWidget.Create(FSurfaceWidget);
  FChild := TTestableHybridCanvas.Create(FChildWidget);
end;

procedure TTestHybridCanvas.TearDown;
begin
  FChild.Free;
  FSurface.Free;
  FSurfaceWidget.Free;
  CreateBufferManager := FSavedFactory;
end;

procedure TTestHybridCanvas.AttachChild(AX, AY, AWidth, AHeight: Integer);
begin
  FChildWidget.SetPosition(AX, AY, AWidth, AHeight);
  FChild.Attach(FSurface, AX, AY);
  FChild.SetColor(cFillColor);
end;

procedure TTestHybridCanvas.AssertPixels(const ARect: TfpgRect; AExact: Boolean);
var
  lIndex, lX, lY: Integer;
  lExpected: LongWord;
  lInside, lChanged: Boolean;
begin
  lChanged := False;
  for lIndex := 0 to High(FMemory.FStorage) do
  begin
    lX := (lIndex - cGuardPixels) mod FMemory.FRowPixels;
    lY := (lIndex - cGuardPixels) div FMemory.FRowPixels;
    lInside := (lIndex >= cGuardPixels) and
      (lIndex < cGuardPixels + FMemory.FRowPixels * FMemory.FHeight) and
      (lX >= 0) and (lX < FMemory.FWidth) and
      (lX >= ARect.Left) and (lX < ARect.Left + ARect.Width) and
      (lY >= ARect.Top) and (lY < ARect.Top + ARect.Height);
    if lInside and (FMemory.FStorage[lIndex] <> cSentinel) then
      lChanged := True;
    if lInside and not AExact then Continue;
    if lInside then lExpected := cFillPixel else lExpected := cSentinel;
    TestContext.AssertTrue((IntToHex(lExpected, 8))=(IntToHex(FMemory.FStorage[lIndex], 8)), 'buffer pixel ' + IntToStr(lIndex));
  end;
  if (ARect.Width > 0) and (ARect.Height > 0) then
    TestContext.AssertTrue(lChanged, 'drawing reached the visible part of the surface');
end;

procedure TTestHybridCanvas.OversizedChildCannotWrapRows;
begin
  AttachChild(60, 60, 200, 200);
  FChild.FillRectangle(0, 0, 200, 200);
  AssertPixels(fpgRect(60, 60, 10, 10));
end;

procedure TTestHybridCanvas.NegativeOriginStaysInBuffer;
begin
  AttachChild(-4, -3, 10, 8);
  FChild.FillRectangle(0, 0, 10, 8);
  AssertPixels(fpgRect(0, 0, 6, 5));
end;

procedure TTestHybridCanvas.OffSurfaceChildWritesNothing;
begin
  AttachChild(90, 90, 10, 8);
  FChild.FillRectangle(0, 0, 10, 8);
  AssertPixels(fpgRect(0, 0, 0, 0));
end;

procedure TTestHybridCanvas.ClipCoordinatesRemainLocal;
var
  lRect: TfpgRect;
begin
  AttachChild(10, 12, 20, 20);
  FChild.SetClipRect(fpgRect(2, 3, 8, 9));
  lRect := FChild.GetClipRect;
  TestContext.AssertTrue((2)=(lRect.Left), '');
  TestContext.AssertTrue((3)=(lRect.Top), '');
  TestContext.AssertTrue((8)=(lRect.Width), '');
  TestContext.AssertTrue((9)=(lRect.Height), '');
  FChild.AddClipRect(fpgRect(4, 5, 8, 9));
  FChild.FillRectangle(0, 0, 20, 20);
  AssertPixels(fpgRect(14, 17, 6, 7));
end;

procedure TTestHybridCanvas.ExplicitClipCanExtendOutsideChild;
begin
  AttachChild(10, 10, 2, 2);
  FChild.SetClipRect(fpgRect(-5, -4, 12, 10));
  FChild.FillRectangle(-5, -4, 12, 10);
  AssertPixels(fpgRect(5, 6, 12, 10));
end;

procedure TTestHybridCanvas.ClearClipRestoresChildArea;
begin
  AttachChild(10, 10, 2, 2);
  FChild.SetClipRect(fpgRect(-5, -4, 12, 10));
  FChild.ClearClipRect;
  FChild.FillRectangle(-5, -4, 12, 10);
  AssertPixels(fpgRect(10, 10, 2, 2));
end;

procedure TTestHybridCanvas.AggRenderingStaysInBuffer;
begin
  AttachChild(60, 60, 200, 200);
  FChild.GradientFill(fpgRect(0, 0, 200, 200), cFillColor, clWhite, gdVertical);
  FChild.DrawLine(0, 0, 199, 199);
  AssertPixels(fpgRect(60, 60, 10, 10), False);
end;

procedure TTestHybridCanvas.ImageBlitStaysInBuffer;
var
  lImage: TfpgImage;
  lX, lY: Integer;
begin
  AttachChild(60, 60, 20, 20);
  lImage := TfpgImage.Create;
  try
    lImage.AllocateImage(32, 20, 20);
    for lY := 0 to 19 do
      for lX := 0 to 19 do
        PLongWord(lImage.ScanLine[lY])[lX] := cFillPixel;
    FChild.BlitImage(0, 0, lImage);
    AssertPixels(fpgRect(60, 60, 10, 10));
  finally
    lImage.Free;
  end;
end;

procedure TTestHybridCanvas.TextRenderingStaysInBuffer;
begin
  AttachChild(60, 60, 200, 200);
  FChild.SetFont(fpgStyle.GetDefaultFont);
  FChild.SetTextColor(cFillColor);
  FChild.DrawString(0, 0, 'Overflow');
  AssertPixels(fpgRect(60, 60, 10, 10), False);
end;

procedure TTestHybridCanvas.XorAndPixelsStayInBuffer;
begin
  AttachChild(60, 60, 200, 200);
  FChild.XORFillRectangle(cFillColor, 0, 0, 200, 200);
  FChild.Pixels[199, 199] := cFillColor;
  TestContext.AssertTrue((0)=(Int64(FChild.Pixels[199, 199])), 'out-of-buffer read');
  AssertPixels(fpgRect(60, 60, 10, 10), False);
end;

procedure TTestHybridCanvas.PopupHasIndependentSurface;
var
  lForm: TfpgForm;
  lPopup: TfpgPopupWindow;
  lCycle: Integer;
begin
  { Exercise real window allocation, paint and popup close/re-show. }
  CreateBufferManager := FSavedFactory;
  lForm := TfpgForm.Create(nil);
  try
    lForm.SetPosition(100, 100, 80, 60);
    lForm.Show;
    lPopup := TfpgPopupWindow.Create(lForm);
    lPopup.SetPosition(0, 0, 120, 90);
    for lCycle := 1 to 2 do
    begin
      lPopup.ShowAt(lForm, 70, 50);
      TestContext.AssertTrue(lPopup.Window <> lForm.Window, 'popup owns a different native window');
      TestContext.AssertTrue(lPopup.ActualWidth > lForm.ActualWidth, 'popup extends beyond the owner');
      lPopup.Canvas.BeginDraw;
      try
        lPopup.Canvas.SetColor(cFillColor);
        lPopup.Canvas.FillRectangle(100, 70, 8, 8);
        TestContext.AssertTrue((Int64(cFillColor))=(Int64(lPopup.Canvas.Pixels[103, 73])), 'popup draws beyond the owner extent');
      finally
        lPopup.Canvas.EndDraw;
      end;
      lPopup.Close;
    end;
  finally
    ClosePopups;
    lForm.Free;
  end;
end;


constructor TTestHybridCanvas.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestHybridCanvasOversizedChildCannotWrapRows(AContext: TNXTestContext);
var lFixture: TTestHybridCanvas;
begin
  lFixture:=TTestHybridCanvas.Create(AContext, 'OversizedChildCannotWrapRows');
  try
    lFixture.SetUp;
    try lFixture.OversizedChildCannotWrapRows; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestHybridCanvasNegativeOriginStaysInBuffer(AContext: TNXTestContext);
var lFixture: TTestHybridCanvas;
begin
  lFixture:=TTestHybridCanvas.Create(AContext, 'NegativeOriginStaysInBuffer');
  try
    lFixture.SetUp;
    try lFixture.NegativeOriginStaysInBuffer; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestHybridCanvasOffSurfaceChildWritesNothing(AContext: TNXTestContext);
var lFixture: TTestHybridCanvas;
begin
  lFixture:=TTestHybridCanvas.Create(AContext, 'OffSurfaceChildWritesNothing');
  try
    lFixture.SetUp;
    try lFixture.OffSurfaceChildWritesNothing; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestHybridCanvasClipCoordinatesRemainLocal(AContext: TNXTestContext);
var lFixture: TTestHybridCanvas;
begin
  lFixture:=TTestHybridCanvas.Create(AContext, 'ClipCoordinatesRemainLocal');
  try
    lFixture.SetUp;
    try lFixture.ClipCoordinatesRemainLocal; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestHybridCanvasExplicitClipCanExtendOutsideChild(AContext: TNXTestContext);
var lFixture: TTestHybridCanvas;
begin
  lFixture:=TTestHybridCanvas.Create(AContext, 'ExplicitClipCanExtendOutsideChild');
  try
    lFixture.SetUp;
    try lFixture.ExplicitClipCanExtendOutsideChild; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestHybridCanvasClearClipRestoresChildArea(AContext: TNXTestContext);
var lFixture: TTestHybridCanvas;
begin
  lFixture:=TTestHybridCanvas.Create(AContext, 'ClearClipRestoresChildArea');
  try
    lFixture.SetUp;
    try lFixture.ClearClipRestoresChildArea; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestHybridCanvasAggRenderingStaysInBuffer(AContext: TNXTestContext);
var lFixture: TTestHybridCanvas;
begin
  lFixture:=TTestHybridCanvas.Create(AContext, 'AggRenderingStaysInBuffer');
  try
    lFixture.SetUp;
    try lFixture.AggRenderingStaysInBuffer; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestHybridCanvasTextRenderingStaysInBuffer(AContext: TNXTestContext);
var lFixture: TTestHybridCanvas;
begin
  lFixture:=TTestHybridCanvas.Create(AContext, 'TextRenderingStaysInBuffer');
  try
    lFixture.SetUp;
    try lFixture.TextRenderingStaysInBuffer; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestHybridCanvasImageBlitStaysInBuffer(AContext: TNXTestContext);
var lFixture: TTestHybridCanvas;
begin
  lFixture:=TTestHybridCanvas.Create(AContext, 'ImageBlitStaysInBuffer');
  try
    lFixture.SetUp;
    try lFixture.ImageBlitStaysInBuffer; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestHybridCanvasXorAndPixelsStayInBuffer(AContext: TNXTestContext);
var lFixture: TTestHybridCanvas;
begin
  lFixture:=TTestHybridCanvas.Create(AContext, 'XorAndPixelsStayInBuffer');
  try
    lFixture.SetUp;
    try lFixture.XorAndPixelsStayInBuffer; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestHybridCanvasPopupHasIndependentSurface(AContext: TNXTestContext);
var lFixture: TTestHybridCanvas;
begin
  lFixture:=TTestHybridCanvas.Create(AContext, 'PopupHasIndependentSurface');
  try
    lFixture.SetUp;
    try lFixture.PopupHasIndependentSurface; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegistertchybridcanvasTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tchybridcanvas.TTestHybridCanvas');
  lSuite.AddTest('OversizedChildCannotWrapRows', @RunTTestHybridCanvasOversizedChildCannotWrapRows);
  lSuite.AddTest('NegativeOriginStaysInBuffer', @RunTTestHybridCanvasNegativeOriginStaysInBuffer);
  lSuite.AddTest('OffSurfaceChildWritesNothing', @RunTTestHybridCanvasOffSurfaceChildWritesNothing);
  lSuite.AddTest('ClipCoordinatesRemainLocal', @RunTTestHybridCanvasClipCoordinatesRemainLocal);
  lSuite.AddTest('ExplicitClipCanExtendOutsideChild', @RunTTestHybridCanvasExplicitClipCanExtendOutsideChild);
  lSuite.AddTest('ClearClipRestoresChildArea', @RunTTestHybridCanvasClearClipRestoresChildArea);
  lSuite.AddTest('AggRenderingStaysInBuffer', @RunTTestHybridCanvasAggRenderingStaysInBuffer);
  lSuite.AddTest('TextRenderingStaysInBuffer', @RunTTestHybridCanvasTextRenderingStaysInBuffer);
  lSuite.AddTest('ImageBlitStaysInBuffer', @RunTTestHybridCanvasImageBlitStaysInBuffer);
  lSuite.AddTest('XorAndPixelsStayInBuffer', @RunTTestHybridCanvasXorAndPixelsStayInBuffer);
  lSuite.AddTest('PopupHasIndependentSurface', @RunTTestHybridCanvasPopupHasIndependentSurface);
end;

end.

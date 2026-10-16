unit tccanvasblit;

{$mode objfpc}{$H+}

{ Tests for the TfpgCanvasBase BlitImage/BlitImagePart API (GitHub issue #194).

  The blit contract: BlitImage/BlitImagePart dispatch through the protected
  virtual DoBlitImagePart, whose default procedure RegistertccanvasblitTests(ARegistry: TNXTestRegistry);

implementation forwards to
  DoDrawImagePart so backends without an opaque fast path still render
  correctly. These tests verify the dispatch plumbing with a recording mock
  canvas; the THybridCanvas pixel-copy override needs an attached window
  buffer and is exercised interactively instead. }

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils,
  fpg_base;

type
  TCanvasCall = record
    Name: string;
    x, y, xi, yi, w, h: Integer;
    img: TObject;
  end;

  { Records DoDrawImagePart/DoBlitImagePart calls; stubs the rest }
  TMockCanvas = class(TfpgCanvasBase)
  public
    Calls: array of TCanvasCall;
    BlitOverridden: Boolean;
  protected
    procedure DoSetFontRes(fntres: TfpgFontResourceBase); override;
    procedure DoSetTextColor(cl: TfpgColor); override;
    procedure DoSetColor(cl: TfpgColor); override;
    procedure DoSetLineStyle(awidth: integer; astyle: TfpgLineStyle); override;
    procedure DoFillRectangle(x, y, w, h: TfpgCoord); override;
    procedure DoXORFillRectangle(col: TfpgColor; x, y, w, h: TfpgCoord); override;
    procedure DoFillTriangle(x1, y1, x2, y2, x3, y3: TfpgCoord); override;
    procedure DoDrawRectangle(x, y, w, h: TfpgCoord); override;
    procedure DoDrawLine(x1, y1, x2, y2: TfpgCoord); override;
    procedure DoDrawImagePart(x, y: TfpgCoord; img: TfpgImageBase; xi, yi, w, h: integer); override;
    procedure DoBlitImagePart(x, y: TfpgCoord; img: TfpgImageBase; xi, yi, w, h: integer); override;
    procedure DoDrawString(x, y: TfpgCoord; const txt: string); override;
    procedure DoSetClipRect(const ARect: TfpgRect); override;
    function  DoGetClipRect: TfpgRect; override;
    procedure DoAddClipRect(const ARect: TfpgRect); override;
    procedure DoClearClipRect; override;
    procedure DoBeginDraw(awidget: TfpgWidgetBase; CanvasTarget: TfpgCanvasBase); override;
    procedure DoPutBufferToScreen(x, y, w, h: TfpgCoord); override;
    procedure DoEndDraw; override;
    function  GetPixel(X, Y: integer): TfpgColor; override;
    procedure SetPixel(X, Y: integer; const AValue: TfpgColor); override;
    procedure DoDrawArc(x, y, w, h: TfpgCoord; a1, a2: double); override;
    procedure DoFillArc(x, y, w, h: TfpgCoord; a1, a2: double); override;
    procedure DoDrawPolygon(const Points: array of TPoint); override;
    function  GetBufferAllocated: Boolean; override;
    procedure DoAllocateBuffer; override;
  end;


  TTestCanvasBlit = class(TObject)
  protected
    FContext: TNXTestContext;
    FCaseName: string;
  private
    FCanvas: TMockCanvas;
    FImage: TfpgImageBase;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    { BlitImage covers the whole image and dispatches via DoBlitImagePart }
    procedure TestBlitImageDispatchesFullBounds;
    { BlitImagePart passes all arguments through unchanged }
    procedure TestBlitImagePartPassesArguments;
    { The default DoBlitImagePart forwards to DoDrawImagePart }
    procedure TestDefaultBlitForwardsToDraw;
    { A nil image is ignored, matching DrawImage }
    procedure TestBlitImageNilIsIgnored;
  end;


implementation

uses
  fpg_main;

{ TMockCanvas }

procedure TMockCanvas.DoSetFontRes(fntres: TfpgFontResourceBase); begin end;
procedure TMockCanvas.DoSetTextColor(cl: TfpgColor); begin end;
procedure TMockCanvas.DoSetColor(cl: TfpgColor); begin end;
procedure TMockCanvas.DoSetLineStyle(awidth: integer; astyle: TfpgLineStyle); begin end;
procedure TMockCanvas.DoFillRectangle(x, y, w, h: TfpgCoord); begin end;
procedure TMockCanvas.DoXORFillRectangle(col: TfpgColor; x, y, w, h: TfpgCoord); begin end;
procedure TMockCanvas.DoFillTriangle(x1, y1, x2, y2, x3, y3: TfpgCoord); begin end;
procedure TMockCanvas.DoDrawRectangle(x, y, w, h: TfpgCoord); begin end;
procedure TMockCanvas.DoDrawLine(x1, y1, x2, y2: TfpgCoord); begin end;
procedure TMockCanvas.DoDrawString(x, y: TfpgCoord; const txt: string); begin end;
procedure TMockCanvas.DoSetClipRect(const ARect: TfpgRect); begin end;
function  TMockCanvas.DoGetClipRect: TfpgRect; begin Result.SetRect(0, 0, 0, 0); end;
procedure TMockCanvas.DoAddClipRect(const ARect: TfpgRect); begin end;
procedure TMockCanvas.DoClearClipRect; begin end;
procedure TMockCanvas.DoBeginDraw(awidget: TfpgWidgetBase; CanvasTarget: TfpgCanvasBase); begin end;
procedure TMockCanvas.DoPutBufferToScreen(x, y, w, h: TfpgCoord); begin end;
procedure TMockCanvas.DoEndDraw; begin end;
function  TMockCanvas.GetPixel(X, Y: integer): TfpgColor; begin Result := 0; end;
procedure TMockCanvas.SetPixel(X, Y: integer; const AValue: TfpgColor); begin end;
procedure TMockCanvas.DoDrawArc(x, y, w, h: TfpgCoord; a1, a2: double); begin end;
procedure TMockCanvas.DoFillArc(x, y, w, h: TfpgCoord; a1, a2: double); begin end;
procedure TMockCanvas.DoDrawPolygon(const Points: array of TPoint); begin end;
function  TMockCanvas.GetBufferAllocated: Boolean; begin Result := False; end;
procedure TMockCanvas.DoAllocateBuffer; begin end;

procedure TMockCanvas.DoDrawImagePart(x, y: TfpgCoord; img: TfpgImageBase; xi, yi, w, h: integer);
var
  n: Integer;
begin
  n := Length(Calls);
  SetLength(Calls, n + 1);
  Calls[n].Name := 'DoDrawImagePart';
  Calls[n].x := x;
  Calls[n].y := y;
  Calls[n].xi := xi;
  Calls[n].yi := yi;
  Calls[n].w := w;
  Calls[n].h := h;
  Calls[n].img := img;
end;

procedure TMockCanvas.DoBlitImagePart(x, y: TfpgCoord; img: TfpgImageBase; xi, yi, w, h: integer);
var
  n: Integer;
begin
  if BlitOverridden then
  begin
    n := Length(Calls);
    SetLength(Calls, n + 1);
    Calls[n].Name := 'DoBlitImagePart';
    Calls[n].x := x;
    Calls[n].y := y;
    Calls[n].xi := xi;
    Calls[n].yi := yi;
    Calls[n].w := w;
    Calls[n].h := h;
    Calls[n].img := img;
  end
  else
    inherited DoBlitImagePart(x, y, img, xi, yi, w, h);
end;

{ TTestCanvasBlit }

procedure TTestCanvasBlit.SetUp;
var
  img: TfpgImage;
begin
  if not fpgApplication.IsInitialized then
    fpgApplication.Initialize;
  FCanvas := TMockCanvas.Create(nil);
  img := TfpgImage.Create;
  img.AllocateImage(32, 8, 6);
  FImage := img;
end;

procedure TTestCanvasBlit.TearDown;
begin
  FImage.Free;
  FCanvas.Free;
end;

procedure TTestCanvasBlit.TestBlitImageDispatchesFullBounds;
begin
  FCanvas.BlitOverridden := True;
  FCanvas.BlitImage(10, 20, FImage);
  FContext.AssertTrue((1)=(Length(FCanvas.Calls)), 'call count');
  FContext.AssertTrue(('DoBlitImagePart')=(FCanvas.Calls[0].Name), 'routed via DoBlitImagePart');
  FContext.AssertTrue((10)=(FCanvas.Calls[0].x), 'x');
  FContext.AssertTrue((20)=(FCanvas.Calls[0].y), 'y');
  FContext.AssertTrue((0)=(FCanvas.Calls[0].xi), 'xi');
  FContext.AssertTrue((0)=(FCanvas.Calls[0].yi), 'yi');
  FContext.AssertTrue((8)=(FCanvas.Calls[0].w), 'w');
  FContext.AssertTrue((6)=(FCanvas.Calls[0].h), 'h');
end;

procedure TTestCanvasBlit.TestBlitImagePartPassesArguments;
begin
  FCanvas.BlitOverridden := True;
  FCanvas.BlitImagePart(1, 2, FImage, 3, 4, 5, 6);
  FContext.AssertTrue((1)=(Length(FCanvas.Calls)), 'call count');
  FContext.AssertTrue(('DoBlitImagePart')=(FCanvas.Calls[0].Name), 'routed via DoBlitImagePart');
  FContext.AssertTrue((1)=(FCanvas.Calls[0].x), 'x');
  FContext.AssertTrue((2)=(FCanvas.Calls[0].y), 'y');
  FContext.AssertTrue((3)=(FCanvas.Calls[0].xi), 'xi');
  FContext.AssertTrue((4)=(FCanvas.Calls[0].yi), 'yi');
  FContext.AssertTrue((5)=(FCanvas.Calls[0].w), 'w');
  FContext.AssertTrue((6)=(FCanvas.Calls[0].h), 'h');
end;

procedure TTestCanvasBlit.TestDefaultBlitForwardsToDraw;
begin
  { BlitOverridden = False: the mock defers to the inherited default,
    which must render through the normal image path }
  FCanvas.BlitImage(7, 8, FImage);
  FContext.AssertTrue((1)=(Length(FCanvas.Calls)), 'call count');
  FContext.AssertTrue(('DoDrawImagePart')=(FCanvas.Calls[0].Name), 'forwarded to DoDrawImagePart');
  FContext.AssertTrue((7)=(FCanvas.Calls[0].x), 'x');
  FContext.AssertTrue((8)=(FCanvas.Calls[0].y), 'y');
  FContext.AssertTrue((8)=(FCanvas.Calls[0].w), 'w');
  FContext.AssertTrue((6)=(FCanvas.Calls[0].h), 'h');
  FContext.AssertTrue((FImage)=(TObject(FCanvas.Calls[0].img)), 'same image');
end;

procedure TTestCanvasBlit.TestBlitImageNilIsIgnored;
begin
  FCanvas.BlitImage(0, 0, nil);
  FContext.AssertTrue((0)=(Length(FCanvas.Calls)), 'no dispatch for nil image');
end;



procedure RunTTestCanvasBlitTestBlitImageDispatchesFullBounds(AContext: TNXTestContext);
var lFixture: TTestCanvasBlit;
begin
  lFixture:=TTestCanvasBlit.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestBlitImageDispatchesFullBounds';
    lFixture.SetUp;
    try lFixture.TestBlitImageDispatchesFullBounds; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCanvasBlitTestBlitImagePartPassesArguments(AContext: TNXTestContext);
var lFixture: TTestCanvasBlit;
begin
  lFixture:=TTestCanvasBlit.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestBlitImagePartPassesArguments';
    lFixture.SetUp;
    try lFixture.TestBlitImagePartPassesArguments; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCanvasBlitTestDefaultBlitForwardsToDraw(AContext: TNXTestContext);
var lFixture: TTestCanvasBlit;
begin
  lFixture:=TTestCanvasBlit.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestDefaultBlitForwardsToDraw';
    lFixture.SetUp;
    try lFixture.TestDefaultBlitForwardsToDraw; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestCanvasBlitTestBlitImageNilIsIgnored(AContext: TNXTestContext);
var lFixture: TTestCanvasBlit;
begin
  lFixture:=TTestCanvasBlit.Create;
  try
    lFixture.FContext:=AContext;
    lFixture.FCaseName:='TestBlitImageNilIsIgnored';
    lFixture.SetUp;
    try lFixture.TestBlitImageNilIsIgnored; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegistertccanvasblitTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tccanvasblit.TTestCanvasBlit');
  lSuite.AddTest('TestBlitImageDispatchesFullBounds', @RunTTestCanvasBlitTestBlitImageDispatchesFullBounds);
  lSuite.AddTest('TestBlitImagePartPassesArguments', @RunTTestCanvasBlitTestBlitImagePartPassesArguments);
  lSuite.AddTest('TestDefaultBlitForwardsToDraw', @RunTTestCanvasBlitTestDefaultBlitForwardsToDraw);
  lSuite.AddTest('TestBlitImageNilIsIgnored', @RunTTestCanvasBlitTestBlitImageNilIsIgnored);
end;

end.

unit tcfontmanager;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  //TestFramework,
  fpg_base,
  fpg_main,
  fpg_fontmanager;

type
  { TTestFontManager - Unit tests for TfpgFontManager }
  TTestFontManager = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  private
    FFontManager: TfpgFontManager;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;
  public
    { Basic functionality tests }
    procedure TestCreate;
    procedure TestGetDefaultFont;
    procedure TestGetFixedFont;

    { Font caching tests }
    procedure TestFontCaching_SameDescriptor;
    procedure TestFontCaching_DifferentDescriptors;
    procedure TestCacheSize;

    { Font descriptor resolution tests }
    procedure TestEmptyDescriptor_ReturnsDefault;
    procedure TestValidDescriptor;

    { Cache statistics tests }
    procedure TestGetCacheStats;
    procedure TestGetCacheSize_Empty;
    procedure TestGetCacheSize_WithFonts;

    { Cleanup tests }
    procedure TestCacheClearsOnDestroy;
  end;

procedure RegistertcfontmanagerTests(ARegistry: TNXTestRegistry);

implementation



{ TTestFontManager }

procedure TTestFontManager.SetUp;
begin
  
  FFontManager := TfpgFontManager.Create;

  { Set reasonable defaults for testing }
  {$IFDEF UNIX}
  FFontManager.DefaultFontDesc := 'Liberation Sans-10';
  FFontManager.FixedFontDesc := 'Liberation Mono-10';
  {$ELSE}
  FFontManager.DefaultFontDesc := 'Arial-10';
  FFontManager.FixedFontDesc := 'Courier New-10';
  {$ENDIF}
end;

procedure TTestFontManager.TearDown;
begin
  FFontManager.Free;
  
end;

procedure TTestFontManager.TestCreate;
begin
  TestContext.AssertTrue((FFontManager)<>nil, 'FontManager should be created');
  TestContext.AssertTrue((0)=(FFontManager.GetCacheSize), 'Cache should start empty');
end;

procedure TTestFontManager.TestGetDefaultFont;
var
  font: TfpgFontResourceBase;
begin
  font := FFontManager.GetDefaultFont;

  TestContext.AssertTrue((font)<>nil, 'Default font should not be nil');
  TestContext.AssertTrue(font.HandleIsValid, 'Default font should have valid handle');

  { Default font should be cached }
  TestContext.AssertTrue((1)=(FFontManager.GetCacheSize), 'Default font should be in cache');
end;

procedure TTestFontManager.TestGetFixedFont;
var
  font: TfpgFontResourceBase;
begin
  font := FFontManager.GetFixedFont;

  TestContext.AssertTrue((font)<>nil, 'Fixed font should not be nil');
  TestContext.AssertTrue(font.HandleIsValid, 'Fixed font should have valid handle');

  { Fixed font should be cached }
  TestContext.AssertTrue((1)=(FFontManager.GetCacheSize), 'Fixed font should be in cache');
end;

procedure TTestFontManager.TestFontCaching_SameDescriptor;
var
  font1, font2: TfpgFontResourceBase;
  descriptor: string;
begin
  {$IFDEF UNIX}
  descriptor := 'Liberation Sans-12';
  {$ELSE}
  descriptor := 'Arial-12';
  {$ENDIF}

  { Request same font twice }
  font1 := FFontManager.GetFont(descriptor);
  font2 := FFontManager.GetFont(descriptor);

  { Should return same instance (cached) }
  TestContext.AssertTrue(font1 = font2, 'Same descriptor should return same font instance');

  { Cache should only have one entry }
  TestContext.AssertTrue((1)=(FFontManager.GetCacheSize), 'Cache should have only 1 font');
end;

procedure TTestFontManager.TestFontCaching_DifferentDescriptors;
var
  font1, font2: TfpgFontResourceBase;
begin
  {$IFDEF UNIX}
  font1 := FFontManager.GetFont('Liberation Sans-10');
  font2 := FFontManager.GetFont('Liberation Sans-12');
  {$ELSE}
  font1 := FFontManager.GetFont('Arial-10');
  font2 := FFontManager.GetFont('Arial-12');
  {$ENDIF}

  { Different descriptors should return different fonts }
  TestContext.AssertTrue(not (font1 = font2), 'Different descriptors should return different fonts');

  { Cache should have two entries }
  TestContext.AssertTrue((2)=(FFontManager.GetCacheSize), 'Cache should have 2 fonts');
end;

procedure TTestFontManager.TestCacheSize;
begin
  TestContext.AssertTrue((0)=(FFontManager.GetCacheSize), 'Initial cache should be empty');

  {$IFDEF UNIX}
  FFontManager.GetFont('Liberation Sans-10');
  {$ELSE}
  FFontManager.GetFont('Arial-10');
  {$ENDIF}
  TestContext.AssertTrue((1)=(FFontManager.GetCacheSize), 'Cache size should be 1');

  {$IFDEF UNIX}
  FFontManager.GetFont('Liberation Sans-12');
  {$ELSE}
  FFontManager.GetFont('Arial-12');
  {$ENDIF}
  TestContext.AssertTrue((2)=(FFontManager.GetCacheSize), 'Cache size should be 2');

  {$IFDEF UNIX}
  FFontManager.GetFont('Liberation Mono-10');
  {$ELSE}
  FFontManager.GetFont('Courier New-10');
  {$ENDIF}
  TestContext.AssertTrue((3)=(FFontManager.GetCacheSize), 'Cache size should be 3');

  { Request cached font - size should not increase }
  FFontManager.GetFont(TfpgFontResource(FFontManager.GetFont('Liberation Sans-10')).FontDesc);
  TestContext.AssertTrue((3)=(FFontManager.GetCacheSize), 'Cache size should still be 3');
end;

procedure TTestFontManager.TestEmptyDescriptor_ReturnsDefault;
var
  font: TfpgFontResourceBase;
begin
  font := FFontManager.GetFont('');

  TestContext.AssertTrue((font)<>nil, 'Empty descriptor should return default font');
  TestContext.AssertTrue(font.HandleIsValid, 'Returned font should be valid');

  { Should be same as explicitly getting default font }
  TestContext.AssertTrue(font = FFontManager.GetDefaultFont, 'Empty descriptor should return same as GetDefaultFont');
end;

procedure TTestFontManager.TestValidDescriptor;
var
  font: TfpgFontResourceBase;
  descriptor: string;
begin
  {$IFDEF UNIX}
  descriptor := 'Liberation Sans-14';
  {$ELSE}
  descriptor := 'Arial-14';
  {$ENDIF}

  font := FFontManager.GetFont(descriptor);

  TestContext.AssertTrue((font)<>nil, 'Valid descriptor should return font');
  TestContext.AssertTrue(font.HandleIsValid, 'Font should have valid handle');
  TestContext.AssertTrue((descriptor)=(font.FontDesc), 'Font descriptor should match');
end;

procedure TTestFontManager.TestGetCacheStats;
var
  stats: string;
  font: TfpgFontResourceBase;
begin
  font := nil;
  { Get a font to populate cache }
  {$IFDEF UNIX}
  font := FFontManager.GetFont('Liberation Sans-12');
  {$ELSE}
  font := FFontManager.GetFont('Arial-12');
  {$ENDIF}
  TestContext.AssertTrue((font)<>nil, 'font should be a valid font');
  stats := FFontManager.GetCacheStats;

  TestContext.AssertTrue(Length(stats) > 0, 'Stats should not be empty');
  TestContext.AssertTrue(Pos('Font Cache Statistics', stats) > 0, 'Stats should contain header');
  TestContext.AssertTrue(Pos('Total cached fonts: 1', stats) > 0, 'Stats should show 1 cached font');
end;

procedure TTestFontManager.TestGetCacheSize_Empty;
begin
  TestContext.AssertTrue((0)=(FFontManager.GetCacheSize), 'Empty cache should return 0');
end;

procedure TTestFontManager.TestGetCacheSize_WithFonts;
begin
  {$IFDEF UNIX}
  FFontManager.GetFont('Liberation Sans-10');
  FFontManager.GetFont('Liberation Mono-10');
  {$ELSE}
  FFontManager.GetFont('Arial-10');
  FFontManager.GetFont('Courier New-10');
  {$ENDIF}

  TestContext.AssertTrue((2)=(FFontManager.GetCacheSize), 'Cache with 2 fonts should return 2');
end;

procedure TTestFontManager.TestCacheClearsOnDestroy;
var
  tempManager: TfpgFontManager;
begin
  { Create temporary manager and add fonts }
  tempManager := TfpgFontManager.Create;
  try
    {$IFDEF UNIX}
    tempManager.DefaultFontDesc := 'Liberation Sans-10';
    tempManager.GetFont('Liberation Sans-12');
    {$ELSE}
    tempManager.DefaultFontDesc := 'Arial-10';
    tempManager.GetFont('Arial-12');
    {$ENDIF}

    TestContext.AssertTrue((1)=(tempManager.GetCacheSize), 'Cache should have 1 font');
  finally
    { Destroying manager should free all cached fonts }
    tempManager.Free;
  end;

  { Test passes if no memory leaks or access violations }
  TestContext.AssertTrue(True, 'Manager destroyed without errors');
end;

constructor TTestFontManager.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestFontManagerTestCreate(AContext: TNXTestContext);
var lFixture: TTestFontManager;
begin
  lFixture:=TTestFontManager.Create(AContext, 'TestCreate');
  try
    lFixture.SetUp;
    try lFixture.TestCreate; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFontManagerTestGetDefaultFont(AContext: TNXTestContext);
var lFixture: TTestFontManager;
begin
  lFixture:=TTestFontManager.Create(AContext, 'TestGetDefaultFont');
  try
    lFixture.SetUp;
    try lFixture.TestGetDefaultFont; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFontManagerTestGetFixedFont(AContext: TNXTestContext);
var lFixture: TTestFontManager;
begin
  lFixture:=TTestFontManager.Create(AContext, 'TestGetFixedFont');
  try
    lFixture.SetUp;
    try lFixture.TestGetFixedFont; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFontManagerTestFontCaching_SameDescriptor(AContext: TNXTestContext);
var lFixture: TTestFontManager;
begin
  lFixture:=TTestFontManager.Create(AContext, 'TestFontCaching_SameDescriptor');
  try
    lFixture.SetUp;
    try lFixture.TestFontCaching_SameDescriptor; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFontManagerTestFontCaching_DifferentDescriptors(AContext: TNXTestContext);
var lFixture: TTestFontManager;
begin
  lFixture:=TTestFontManager.Create(AContext, 'TestFontCaching_DifferentDescriptors');
  try
    lFixture.SetUp;
    try lFixture.TestFontCaching_DifferentDescriptors; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFontManagerTestCacheSize(AContext: TNXTestContext);
var lFixture: TTestFontManager;
begin
  lFixture:=TTestFontManager.Create(AContext, 'TestCacheSize');
  try
    lFixture.SetUp;
    try lFixture.TestCacheSize; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFontManagerTestEmptyDescriptor_ReturnsDefault(AContext: TNXTestContext);
var lFixture: TTestFontManager;
begin
  lFixture:=TTestFontManager.Create(AContext, 'TestEmptyDescriptor_ReturnsDefault');
  try
    lFixture.SetUp;
    try lFixture.TestEmptyDescriptor_ReturnsDefault; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFontManagerTestValidDescriptor(AContext: TNXTestContext);
var lFixture: TTestFontManager;
begin
  lFixture:=TTestFontManager.Create(AContext, 'TestValidDescriptor');
  try
    lFixture.SetUp;
    try lFixture.TestValidDescriptor; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFontManagerTestGetCacheStats(AContext: TNXTestContext);
var lFixture: TTestFontManager;
begin
  lFixture:=TTestFontManager.Create(AContext, 'TestGetCacheStats');
  try
    lFixture.SetUp;
    try lFixture.TestGetCacheStats; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFontManagerTestGetCacheSize_Empty(AContext: TNXTestContext);
var lFixture: TTestFontManager;
begin
  lFixture:=TTestFontManager.Create(AContext, 'TestGetCacheSize_Empty');
  try
    lFixture.SetUp;
    try lFixture.TestGetCacheSize_Empty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFontManagerTestGetCacheSize_WithFonts(AContext: TNXTestContext);
var lFixture: TTestFontManager;
begin
  lFixture:=TTestFontManager.Create(AContext, 'TestGetCacheSize_WithFonts');
  try
    lFixture.SetUp;
    try lFixture.TestGetCacheSize_WithFonts; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestFontManagerTestCacheClearsOnDestroy(AContext: TNXTestContext);
var lFixture: TTestFontManager;
begin
  lFixture:=TTestFontManager.Create(AContext, 'TestCacheClearsOnDestroy');
  try
    lFixture.SetUp;
    try lFixture.TestCacheClearsOnDestroy; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegistertcfontmanagerTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('tcfontmanager.TTestFontManager');
  lSuite.AddTest('TestCreate', @RunTTestFontManagerTestCreate);
  lSuite.AddTest('TestGetDefaultFont', @RunTTestFontManagerTestGetDefaultFont);
  lSuite.AddTest('TestGetFixedFont', @RunTTestFontManagerTestGetFixedFont);
  lSuite.AddTest('TestFontCaching_SameDescriptor', @RunTTestFontManagerTestFontCaching_SameDescriptor);
  lSuite.AddTest('TestFontCaching_DifferentDescriptors', @RunTTestFontManagerTestFontCaching_DifferentDescriptors);
  lSuite.AddTest('TestCacheSize', @RunTTestFontManagerTestCacheSize);
  lSuite.AddTest('TestEmptyDescriptor_ReturnsDefault', @RunTTestFontManagerTestEmptyDescriptor_ReturnsDefault);
  lSuite.AddTest('TestValidDescriptor', @RunTTestFontManagerTestValidDescriptor);
  lSuite.AddTest('TestGetCacheStats', @RunTTestFontManagerTestGetCacheStats);
  lSuite.AddTest('TestGetCacheSize_Empty', @RunTTestFontManagerTestGetCacheSize_Empty);
  lSuite.AddTest('TestGetCacheSize_WithFonts', @RunTTestFontManagerTestGetCacheSize_WithFonts);
  lSuite.AddTest('TestCacheClearsOnDestroy', @RunTTestFontManagerTestCacheClearsOnDestroy);
end;



end.

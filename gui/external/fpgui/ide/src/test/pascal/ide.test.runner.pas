{
    fpGUI IDE - Runner Tests

    Tests for executable path resolution in ide.runner.thread.
}
unit ide.test.runner;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes,
  SysUtils,
  ide.runner.thread,
  ide.project,
  ide.project.backend,
  ide.project.pasbuild;

type

  { TTestResolveExecutablePath }

  TTestResolveExecutablePath = class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  protected
    procedure TearDown; virtual;
  public
    procedure TestNilProjectReturnsEmpty;
    procedure TestLegacyWithTargetFile;
    procedure TestLegacyWithEmptyTargetFile;
    procedure TestPasBuildWithActiveModulePath;
    procedure TestPasBuildDocviewModule;
  end;

procedure RegisteridetestrunnerTests(ARegistry: TNXTestRegistry);

implementation

{ TTestResolveExecutablePath }

procedure TTestResolveExecutablePath.TearDown;
begin
  { SetProject frees the previous project, so just reset to a fresh default }
  SetProject(TLegacyProjectBackend.Create);
end;

procedure TTestResolveExecutablePath.TestNilProjectReturnsEmpty;
begin
  SetProject(nil);
  TestContext.AssertTrue(('')=(ResolveProjectExecutablePath), 'nil project should return empty');
end;

procedure TTestResolveExecutablePath.TestLegacyWithTargetFile;
var
  proj: TLegacyProjectBackend;
begin
  proj := TLegacyProjectBackend.Create;
  proj.ProjectDir := '/tmp/myproject/';
  proj.TargetFile := 'myapp';
  SetProject(proj);
  TestContext.AssertTrue(('/tmp/myproject/myapp')=(ResolveProjectExecutablePath), 'legacy with target file');
end;

procedure TTestResolveExecutablePath.TestLegacyWithEmptyTargetFile;
var
  proj: TLegacyProjectBackend;
begin
  proj := TLegacyProjectBackend.Create;
  proj.ProjectDir := '/tmp/myproject/';
  proj.TargetFile := '';
  SetProject(proj);
  TestContext.AssertTrue(('')=(ResolveProjectExecutablePath), 'legacy with empty target should return empty');
end;

procedure TTestResolveExecutablePath.TestPasBuildWithActiveModulePath;
var
  pb: TPasBuildProjectBackend;
  module: TPasBuildModule;
begin
  pb := TPasBuildProjectBackend.Create;
  module := TPasBuildModule.Create;
  module.ProjectDir := '/data/devel/fpgui/ide';
  module.OutputDir := 'target';
  module.ExecutableName := 'maximus';
  pb.ActiveModule := module;
  SetProject(pb);
  TestContext.AssertTrue(('/data/devel/fpgui/ide/target/maximus')=(ResolveProjectExecutablePath), 'projectDir + outputDir + executableName');
end;

procedure TTestResolveExecutablePath.TestPasBuildDocviewModule;
var
  pb: TPasBuildProjectBackend;
  module: TPasBuildModule;
begin
  pb := TPasBuildProjectBackend.Create;
  module := TPasBuildModule.Create;
  module.ProjectDir := '/data/devel/fpgui/docview';
  module.OutputDir := 'target';
  module.ExecutableName := 'docview';
  pb.ActiveModule := module;
  SetProject(pb);
  TestContext.AssertTrue(('/data/devel/fpgui/docview/target/docview')=(ResolveProjectExecutablePath), 'docview module resolves correctly');
end;



constructor TTestResolveExecutablePath.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTTestResolveExecutablePathTestNilProjectReturnsEmpty(AContext: TNXTestContext);
var lFixture: TTestResolveExecutablePath;
begin
  lFixture:=TTestResolveExecutablePath.Create(AContext, 'TestNilProjectReturnsEmpty');
  try
    try lFixture.TestNilProjectReturnsEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestResolveExecutablePathTestLegacyWithTargetFile(AContext: TNXTestContext);
var lFixture: TTestResolveExecutablePath;
begin
  lFixture:=TTestResolveExecutablePath.Create(AContext, 'TestLegacyWithTargetFile');
  try
    try lFixture.TestLegacyWithTargetFile; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestResolveExecutablePathTestLegacyWithEmptyTargetFile(AContext: TNXTestContext);
var lFixture: TTestResolveExecutablePath;
begin
  lFixture:=TTestResolveExecutablePath.Create(AContext, 'TestLegacyWithEmptyTargetFile');
  try
    try lFixture.TestLegacyWithEmptyTargetFile; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestResolveExecutablePathTestPasBuildWithActiveModulePath(AContext: TNXTestContext);
var lFixture: TTestResolveExecutablePath;
begin
  lFixture:=TTestResolveExecutablePath.Create(AContext, 'TestPasBuildWithActiveModulePath');
  try
    try lFixture.TestPasBuildWithActiveModulePath; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTTestResolveExecutablePathTestPasBuildDocviewModule(AContext: TNXTestContext);
var lFixture: TTestResolveExecutablePath;
begin
  lFixture:=TTestResolveExecutablePath.Create(AContext, 'TestPasBuildDocviewModule');
  try
    try lFixture.TestPasBuildDocviewModule; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegisteridetestrunnerTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('ide.test.runner.TTestResolveExecutablePath');
  lSuite.AddTest('TestNilProjectReturnsEmpty', @RunTTestResolveExecutablePathTestNilProjectReturnsEmpty);
  lSuite.AddTest('TestLegacyWithTargetFile', @RunTTestResolveExecutablePathTestLegacyWithTargetFile);
  lSuite.AddTest('TestLegacyWithEmptyTargetFile', @RunTTestResolveExecutablePathTestLegacyWithEmptyTargetFile);
  lSuite.AddTest('TestPasBuildWithActiveModulePath', @RunTTestResolveExecutablePathTestPasBuildWithActiveModulePath);
  lSuite.AddTest('TestPasBuildDocviewModule', @RunTTestResolveExecutablePathTestPasBuildDocviewModule);
end;

end.

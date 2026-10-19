unit utcFPTemplate;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, obNXTestContext, obNXTestRegistry, obNXTestSuite, fpTemplate;

procedure RegisterutcFPTemplateTests(ARegistry: TNXTestRegistry);

implementation

type
  TTestCallbacks = class(TObject)
  public
    AContext: TNXTestContext;
    procedure TestAllowTagParamsBasics_replacetag(Sender : TObject; Const TagString : String; TagParams:TStringList; Out ReplaceText : String);
    procedure TestAllowTagParamsFunctionLike_replacetag(Sender : TObject; Const TagString : String; TagParams:TStringList; Out ReplaceText : String);
    procedure TestAllowTagParamsDelphiStyle_replacetag(Sender : TObject; Const TagString : String; TagParams:TStringList; Out ReplaceText : String);
  end;

var
  Callbacks: TTestCallbacks;

procedure SuiteSetup(AContext: TNXTestContext);
begin

  Callbacks := TTestCallbacks.Create;
  Callbacks.AContext := AContext;
end;

procedure SuiteTearDown(AContext: TNXTestContext);
begin

  Callbacks.Free;
end;

procedure TTestCallbacks.TestAllowTagParamsBasics_replacetag(
  Sender: TObject; const TagString: String; TagParams: TStringList; out
  ReplaceText: String);
begin
  if TagString='test' then
    begin
    AContext.AssertTrue((1) = (TagParams.Count), 'Callback basics: Param count');
    AContext.AssertTrue(('param1') = (TagParams.Names[0]), 'Callback basics: Param name');
    AContext.AssertTrue(('test ') = (TagParams.ValueFromIndex[0]), 'Callback basics: Param value');
    ReplaceText := 'template'
    end
  else if TagString='dream' then ReplaceText := 'think';
end;

procedure TTestCallbacks.TestAllowTagParamsFunctionLike_replacetag(
  Sender: TObject; const TagString: String; TagParams: TStringList; out
  ReplaceText: String);
begin
  if TagString='uppercase' then
    begin
    AContext.AssertTrue((1) = (TagParams.Count), 'Callback function-like: Param count');
    ReplaceText:=UpperCase(TagParams[0]);
    end;
end;

procedure TTestCallbacks.TestAllowTagParamsDelphiStyle_replacetag(
  Sender: TObject; const TagString: String; TagParams: TStringList; out
  ReplaceText: String);
begin
  AContext.AssertTrue((2) = (TagParams.Count), 'Callback delphi-style: Param count');
  AContext.AssertTrue(('param1') = (TagParams.Names[0]), 'Callback delphi-style: Param 1 name');
  AContext.AssertTrue(('first param') = (TagParams.ValueFromIndex[0]), 'Callback delphi-style: Param 1 value');
  AContext.AssertTrue(('param2') = (TagParams.Names[1]), 'Callback delphi-style: Param 2 name');
  AContext.AssertTrue(('second param') = (TagParams.ValueFromIndex[1]), 'Callback delphi-style: Param 2 value');
  ReplaceText := 'Delphi parameter'
end;

procedure TFPtemplate_TestBasics(AContext: TNXTestContext);
var
  templ: TTemplateParser;
begin
  try
    SuiteSetup(AContext);

    templ := TTemplateParser.Create;
    try
      templ.Values['dream'] := 'think';
      templ.Values['test'] := 'template';
      AContext.AssertTrue(('This is the simplest template I could think of.') = (templ.ParseString('This is the simplest {test} I could {dream} of.')), 'TestBasics simple replace');

      templ.recursive := true;
      templ.Values['val2'] := 'template';
      templ.Values['test'] := '{val2} test';
      AContext.AssertTrue(('This is the simplest template test I could think of.') = (templ.ParseString('This is the simplest {test} I could {dream} of.')), 'TestBasics recursive replace');

    finally
      templ.free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TFPtemplate_TestBasicDelimiters(AContext: TNXTestContext);
var
  templ: TTemplateParser;
begin
  try
    SuiteSetup(AContext);

    templ := TTemplateParser.Create;
    try
      templ.StartDelimiter:='[-';
      templ.EndDelimiter:=')';
      templ.Values['dream'] := 'think';
      templ.Values['test'] := 'template';
      AContext.AssertTrue(('This is [the] simplest template I could think (of).') = (templ.ParseString('This is [the] simplest [-test) I could [-dream) (of).')), 'TestBasicDelimiters custom 1');

      templ.StartDelimiter:='(';
      templ.EndDelimiter:='-)';
      templ.Values['dream'] := 'think';
      templ.Values['test'] := 'template';
      AContext.AssertTrue(('This is [the] simplest template I could think of:-).') = (templ.ParseString('This is [the] simplest (test-) I could (dream-) of:-).')), 'TestBasicDelimiters custom 2');

    finally
      templ.free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TFPtemplate_TestAllowTagParamsBasics(AContext: TNXTestContext);
var
  templ: TTemplateParser;
begin
  try
    SuiteSetup(AContext);

    templ := TTemplateParser.Create;
    try
      templ.AllowTagParams := true;
      templ.OnReplaceTag := @Callbacks.TestAllowTagParamsBasics_replacetag;
      AContext.AssertTrue(('This is the simplest template I could think of.') = (templ.ParseString('This is the simplest {test [- param1=test -]} I could {dream} of.')), 'TestAllowTagParamsBasics 1');

      AContext.AssertTrue(('This is the simplest template I could think of.') = (templ.ParseString('This is the simplest {test[- param1=test -]} I could {dream} of.')), 'TestAllowTagParamsBasics 2');

      templ.ParamValueSeparator:=':';
      AContext.AssertTrue(('This is the simplest template I could think of.') = (templ.ParseString('This is the simplest {test [- param1:test -]} I could {dream} of.')), 'TestAllowTagParamsBasics 3');

      AContext.AssertTrue(('This is the simplest template I could think of.') = (templ.ParseString('This is the simplest {test [-param1:test -]} I could {dream} of.')), 'TestAllowTagParamsBasics 4');

      AContext.AssertTrue(('This is the simplest template I could think of.') = (templ.ParseString('This is the simplest {test  [-param1:test -]} I could {dream} of.')), 'TestAllowTagParamsBasics 5');

    finally
      templ.free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TFPtemplate_TestAllowTagParamsFunctionLike(AContext: TNXTestContext);
var
  templ: TTemplateParser;
begin
  try
    SuiteSetup(AContext);

    templ := TTemplateParser.Create;
    try
      templ.AllowTagParams := true;
      templ.ParamStartDelimiter:='(';
      templ.ParamEndDelimiter:=')';
      templ.OnReplaceTag := @Callbacks.TestAllowTagParamsFunctionLike_replacetag;

      AContext.AssertTrue(('THIS should be uppercased.') = (templ.ParseString('{uppercase(This)} should be uppercased.')), 'TestAllowTagParamsFunctionLike');
    finally
      templ.free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure TFPtemplate_TestAllowTagParamsDelphiStyle(AContext: TNXTestContext);
var
  templ: TTemplateParser;
begin
  try
    SuiteSetup(AContext);

    templ := TTemplateParser.Create;
    try
      templ.AllowTagParams := true;
      templ.StartDelimiter:='<#';
      templ.EndDelimiter:='>';
      templ.ParamStartDelimiter:=' ';
      templ.ParamEndDelimiter:='"';
      templ.ParamValueSeparator:='="';
      templ.OnReplaceTag := @Callbacks.TestAllowTagParamsDelphiStyle_replacetag;

      AContext.AssertTrue(('Test for a Delphi parameter.') = (templ.ParseString('Test for a <#DelphiTag param1="first param" param2="second param">.')), 'TestAllowTagParamsDelphiStyle');
    finally
      templ.free;
    end;
  finally
    SuiteTearDown(AContext);
  end;
end;

procedure RegisterutcFPTemplateTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCL.Text.TFPtemplateTests');
  lSuite.AddTest('TestBasics', @TFPtemplate_TestBasics, 'text');
  lSuite.AddTest('TestBasicDelimiters', @TFPtemplate_TestBasicDelimiters, 'text');
  lSuite.AddTest('TestAllowTagParamsBasics', @TFPtemplate_TestAllowTagParamsBasics, 'text');
  lSuite.AddTest('TestAllowTagParamsFunctionLike', @TFPtemplate_TestAllowTagParamsFunctionLike, 'text');
  lSuite.AddTest('TestAllowTagParamsDelphiStyle', @TFPtemplate_TestAllowTagParamsDelphiStyle, 'text');
end;

end.

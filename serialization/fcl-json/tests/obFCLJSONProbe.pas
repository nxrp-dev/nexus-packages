// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit obFCLJSONProbe;

{$mode objfpc}{$H+}

interface

uses obNXTestContext;

procedure RunFCLJSONProbe(AId: Integer; const ADirectory: string;
  AContext: TNXTestContext);

implementation

uses
  Classes, SysUtils, Process, fpJSON, JSONParser, JSONScanner, JSONConf,
  JSONIni, JSONWriter, JSONComparer, fpJSONRTTI, JSON2Yaml, fpJSONToPas;

type
  TCharacterSample = class(TPersistent)
  private
    FWide: WideChar;
    FUnicode: UnicodeChar;
  published
    property WideValue: WideChar read FWide write FWide;
    property UnicodeValue: UnicodeChar read FUnicode write FUnicode;
  end;

procedure SaveBytes(const AFileName: string; const AData: UTF8String);
var
  lStream: TFileStream;
begin
  lStream:=TFileStream.Create(AFileName,fmCreate);
  try
    if AData<>'' then
      lStream.WriteBuffer(AData[1],Length(AData));
  finally
    lStream.Free;
  end;
end;

function LoadText(const AFileName: string): string;
var
  lLines: TStringList;
begin
  lLines:=TStringList.Create;
  try
    lLines.LoadFromFile(AFileName);
    Result:=lLines.Text;
  finally
    lLines.Free;
  end;
end;

function StreamText(AStream: TStream): UTF8String;
begin
  SetLength(Result,AStream.Size);
  AStream.Position:=0;
  if Result<>'' then
    AStream.ReadBuffer(Result[1],Length(Result));
end;

function RunTool(const AExecutable: string; const AArguments: array of string;
  const ALog: string; AContext: TNXTestContext): Integer;
var
  lProcess: TProcess;
  lArgument: string;
begin
  lProcess:=TProcess.Create(nil);
  try
    lProcess.Executable:=AExecutable;
    for lArgument in AArguments do
      lProcess.Parameters.Add(lArgument);
    lProcess.OutputDescriptor.FileName:=ALog;
    lProcess.Options:=[poStderrToOutput];
    lProcess.Execute;
    if not lProcess.WaitOnExit(10000) then
    begin
      lProcess.Terminate(1);
      lProcess.WaitOnExit;
      AContext.Fail('Tool exceeded ten seconds: '+AExecutable);
    end;
    Result:=lProcess.ExitCode;
  finally
    lProcess.Free;
  end;
end;

procedure AssertRejected(const AJSON: UTF8String; AOptions: TJSONOptions;
  AContext: TNXTestContext); forward;

procedure Probe01(AContext: TNXTestContext);
const
  cInputs: array[0..4] of UTF8String = (
    '{"a":1,"a":{"x":2},"b":3}',
    '{"a":1,"a":[{"x":[2]}],"b":3}',
    '{"a":{"keep":1},"a":{"x":2},"b":3}',
    '{"a":[1],"a":[{"x":2}],"b":3}',
    '{"a":1,"a":{"x":1,"x":{"nested":2}},"b":3}');
  cMalformed: UTF8String = '{"a":1,"a":{"x":[}}';
var
  lParser: TJSONParser;
  lData: TJSONData;
  lIndex: Integer;
  lBefore, lAfter: PtrUInt;
begin
  for lIndex:=Low(cInputs) to High(cInputs) do
  begin
    lParser:=TJSONParser.Create(cInputs[lIndex],[joUTF8,joIgnoreDuplicates,joStrict]);
    lData:=nil;
    try
      lData:=lParser.Parse;
      AContext.AssertTrue(lData is TJSONObject);
      AContext.AssertEquals(2,lData.Count,'Ignored duplicate added a member.');
      AContext.AssertEquals(3,TJSONObject(lData).Integers['b'],'Parsing after the ignored container.');
      case lIndex of
        0,1,4: AContext.AssertEquals(1,TJSONObject(lData).Integers['a']);
        2: AContext.AssertEquals(1,TJSONObject(lData).Objects['a'].Integers['keep']);
        3: AContext.AssertEquals(1,TJSONObject(lData).Arrays['a'].Integers[0]);
      end;
    finally
      lData.Free;
      lParser.Free;
    end;
  end;
  AssertRejected(cMalformed,[joUTF8,joIgnoreDuplicates,joStrict],AContext);
  lBefore:=GetFPCHeapStatus.CurrHeapUsed;
  for lIndex:=1 to 32 do
    AssertRejected(cMalformed,[joUTF8,joIgnoreDuplicates,joStrict],AContext);
  lAfter:=GetFPCHeapStatus.CurrHeapUsed;
  AContext.AssertTrue(lAfter<=lBefore+256,
    Format('Ignored containers leaked on syntax failure: before=%d after=%d.',[lBefore,lAfter]));
end;

procedure Probe02(const ADirectory: string; AContext: TNXTestContext);
var
  lConfig, lReopened: TJSONConfig;
  lFirst, lSecond: string;
begin
  lFirst:=IncludeTrailingPathDelimiter(ADirectory)+'first.json';
  lSecond:=IncludeTrailingPathDelimiter(ADirectory)+'second.json';
  SaveBytes(lFirst,'{"value":1}');
  SaveBytes(lSecond,'{"value":2}');
  lConfig:=TJSONConfig.Create(nil);
  lReopened:=TJSONConfig.Create(nil);
  try
    lConfig.FileName:=lFirst;
    lConfig.SetValue('/value',11);
    lConfig.FileName:=lSecond;
    AContext.AssertEquals(2,lConfig.GetValue('/value',0),'Switching overwrote the destination.');
    lReopened.FileName:=lFirst;
    AContext.AssertEquals(11,lReopened.GetValue('/value',0),'Dirty source was not flushed.');
    lReopened.FileName:=lSecond;
    AContext.AssertEquals(2,lReopened.GetValue('/value',0),'Destination changed on disk.');
  finally
    lReopened.Free;
    lConfig.Free;
  end;
end;

procedure Probe03(const ADirectory: string; AContext: TNXTestContext);
var
  lIni, lReopened: TJSONIniFile;
  lFileName: string;
begin
  lFileName:=IncludeTrailingPathDelimiter(ADirectory)+'settings.json';
  lIni:=TJSONIniFile.Create(lFileName);
  try
    lIni.CacheUpdates:=False;
    lIni.WriteString('section','text','saved');
    AContext.AssertTrue(FileExists(lFileName),'Write-through did not create the file.');
    lIni.WriteInteger('section','number',42);
    lIni.WriteInt64('section','large',Int64(1234567890123));
    lIni.WriteBool('section','enabled',True);
    lIni.WriteFloat('section','fraction',1.25);
    lReopened:=TJSONIniFile.Create(lFileName);
    try
      AContext.AssertEquals('saved',lReopened.ReadString('section','text',''));
      AContext.AssertEquals(42,lReopened.ReadInteger('section','number',0));
      AContext.AssertTrue(lReopened.ReadInt64('section','large',0)=1234567890123);
      AContext.AssertTrue(lReopened.ReadBool('section','enabled',False));
      AContext.AssertTrue(lReopened.ReadFloat('section','fraction',0)=1.25);
    finally
      lReopened.Free;
    end;
    lIni.CacheUpdates:=True;
    AContext.AssertTrue(lIni.CacheUpdates,'Cache setting was not retained.');
    lIni.WriteString('section','text','cached');
    lReopened:=TJSONIniFile.Create(lFileName);
    try
      AContext.AssertEquals('saved',lReopened.ReadString('section','text',''),
        'Cached changes were written before disabling caching.');
    finally
      lReopened.Free;
    end;
    lIni.CacheUpdates:=False;
    AContext.AssertFalse(lIni.CacheUpdates);
  finally
    lIni.Free;
  end;
  lReopened:=TJSONIniFile.Create(lFileName);
  try
    AContext.AssertEquals('cached',lReopened.ReadString('section','text',''),
      'Disabling caching did not flush pending changes.');
  finally
    lReopened.Free;
  end;
end;

procedure AssertRejected(const AJSON: UTF8String; AOptions: TJSONOptions;
  AContext: TNXTestContext);
var
  lParser: TJSONParser;
  lData: TJSONData;
  lRejected: Boolean;
begin
  lParser:=TJSONParser.Create(AJSON,AOptions);
  lData:=nil;
  lRejected:=False;
  try
    try
      lData:=lParser.Parse;
    except
      on E: EJSONParser do lRejected:=True;
      on E: EScannerError do lRejected:=True;
    end;
    AContext.AssertTrue(lRejected,'Malformed JSON was accepted: '+UTF8Decode(AJSON));
  finally
    lData.Free;
    lParser.Free;
  end;
end;

procedure Probe04(AContext: TNXTestContext);
const
  cInputs: array[0..2] of UTF8String = ('[:]', '{"a"::}', '[1,:]');
var
  lInput: UTF8String;
begin
  for lInput in cInputs do
  begin
    AssertRejected(lInput,[joUTF8],AContext);
    AssertRejected(lInput,[joUTF8,joStrict],AContext);
  end;
end;

procedure Probe05(AContext: TNXTestContext);
var
  lCode: Integer;
  lData: TJSONData;
  lEscaped: UTF8String;
begin
  for lCode:=0 to 31 do
  begin
    AssertRejected('"'+UTF8String(AnsiChar(lCode))+'"',[joUTF8,joStrict],AContext);
    lEscaped:=UTF8Encode('"\u'+IntToHex(lCode,4)+'"');
    lData:=GetJSON(lEscaped);
    try
      AContext.AssertEquals(1,Length(lData.AsUnicodeString));
      AContext.AssertEquals(lCode,Ord(lData.AsUnicodeString[1]),'Valid escaped control value.');
    finally
      lData.Free;
    end;
  end;
end;

procedure Probe06(AContext: TNXTestContext);
var
  lWriter: TJSONDataWriter;
  lData: TJSONData;
begin
  lWriter:=TJSONDataWriter.Create;
  lWriter.Free;
  lWriter:=TJSONDataWriter.Create;
  lData:=nil;
  try
    lWriter.WriteValue(42);
    lData:=lWriter.ExtractData;
    AContext.AssertEquals(42,lData.AsInteger);
  finally
    lWriter.Free;
    lData.Free;
  end;
end;

procedure Probe07(AContext: TNXTestContext);
const
  cNumbers: array[0..2] of QWord = (9223372036854775807,
    9223372036854775808,18446744073709551615);
  cExpected: array[0..2] of string = ('9223372036854775807',
    '9223372036854775808','18446744073709551615');
var
  lIndex: Integer;
  lInput, lOutput: TJSONData;
  lStream: TMemoryStream;
  lStreamWriter: TJSONStreamWriter;
  lDataWriter: TJSONDataWriter;
  lWriter: TAbstractJSONWriter;
begin
  for lIndex:=Low(cNumbers) to High(cNumbers) do
  begin
    lInput:=TJSONQWordNumber.Create(cNumbers[lIndex]);
    lStream:=TMemoryStream.Create;
    lStreamWriter:=TJSONStreamWriter.Create(lStream);
    lDataWriter:=nil;
    lOutput:=nil;
    try
      lWriter:=lStreamWriter;
      lWriter.WriteValue(lInput);
      AContext.AssertEquals(cExpected[lIndex],UTF8Decode(StreamText(lStream)),
        'Unsigned stream output was narrowed.');
      lDataWriter:=TJSONDataWriter.Create;
      lWriter:=lDataWriter;
      lWriter.WriteValue(lInput);
      lOutput:=lDataWriter.ExtractData;
      AContext.AssertTrue(lOutput.AsQWord=cNumbers[lIndex],'Unsigned data writer round trip.');
    finally
      lOutput.Free;
      lDataWriter.Free;
      lStreamWriter.Free;
      lStream.Free;
      lInput.Free;
    end;
  end;
end;

procedure Probe08(AContext: TNXTestContext);
var
  lExpected, lActual: TJSONData;
  lErrors: TStringList;
  lIndex: Integer;
begin
  lErrors:=TStringList.Create;
  try
    for lIndex:=0 to 2 do
    begin
      case lIndex of
        0: begin lExpected:=TJSONIntegerNumber.Create(10); lActual:=TJSONIntegerNumber.Create(11); end;
        1: begin lExpected:=TJSONInt64Number.Create(-1234567890123); lActual:=TJSONInt64Number.Create(-1234567890122); end;
        2: begin lExpected:=TJSONQWordNumber.Create(High(QWord)); lActual:=TJSONQWordNumber.Create(High(QWord)-1); end;
      end;
      try
        lErrors.Clear;
        TJSONComparer.Compare(lExpected,lActual,lErrors);
        AContext.AssertEquals(1,lErrors.Count,'Expected one numeric difference.');
        AContext.AssertTrue(Pos(UTF8Decode(lExpected.AsJSON),lErrors[0])>0,
          'Missing expected integer in diagnostic.');
        AContext.AssertTrue(Pos(UTF8Decode(lActual.AsJSON),lErrors[0])>0,
          'Missing actual integer in diagnostic.');
      finally
        lActual.Free;
        lExpected.Free;
      end;
    end;
  finally
    lErrors.Free;
  end;
end;

procedure Probe09(AContext: TNXTestContext);
const
  cCharacters: array[0..2] of WideChar = (#$00E9,#$03A9,#$4E2D);
var
  lSource, lTarget: TCharacterSample;
  lStreamer: TJSONStreamer;
  lRestorer: TJSONDeStreamer;
  lJSON: TJSONObject;
  lCharacter: WideChar;
begin
  lSource:=TCharacterSample.Create;
  lTarget:=TCharacterSample.Create;
  lStreamer:=TJSONStreamer.Create(nil);
  lRestorer:=TJSONDeStreamer.Create(nil);
  try
    for lCharacter in cCharacters do
    begin
      lSource.WideValue:=lCharacter;
      lSource.UnicodeValue:=lCharacter;
      lJSON:=lStreamer.ObjectToJSON(lSource);
      try
        lRestorer.JSONToObject(lJSON,lTarget);
        AContext.AssertEquals(Ord(lCharacter),Ord(lTarget.WideValue),'WideChar UTF-8 restoration.');
        AContext.AssertEquals(Ord(lCharacter),Ord(lTarget.UnicodeValue),'UnicodeChar UTF-8 restoration.');
      finally
        lJSON.Free;
      end;
    end;
  finally
    lRestorer.Free;
    lStreamer.Free;
    lTarget.Free;
    lSource.Free;
  end;
end;

procedure Probe10(const ADirectory: string; AContext: TNXTestContext);
const
  cJSON: UTF8String = '{"s":"true","false":"false","n":"123","nil":"null",'+
    '"empty":"","lines":"first\nsecond","punctuation":"a: b # c",'+
    '"a: b":"quote\" and slash\\","list":["yes","01","- item"],'+
    '"unicode":"\u00e9\u03a9\u4e2d","typed":{"flag":true,"count":3,"nothing":null}}';
  cCheck = 'import json,sys,yaml; '+
    'expected=json.load(open(sys.argv[1],encoding="utf-8")); '+
    'actual=yaml.safe_load(open(sys.argv[2],encoding="utf-8")); '+
    'assert actual==expected,repr(actual)';
var
  lData: TJSONData;
  lConverter: TJSONToYaml;
  lStream: TMemoryStream;
  lPython, lJSONPath, lYamlPath, lScript, lLog: string;
  lExit: Integer;
begin
  lPython:=GetEnvironmentVariable('NXTEST_PYTHON');
  if lPython='' then
    lPython:={$IFDEF MSWINDOWS}'python'{$ELSE}'python3'{$ENDIF};
  lLog:=IncludeTrailingPathDelimiter(ADirectory)+'yaml.log';
  try
    lExit:=RunTool(lPython,['-c','import yaml'],lLog,AContext);
  except
    on E: EProcess do
      AContext.Skip('Python executable is unavailable: '+E.Message);
  end;
  if lExit<>0 then
    AContext.Skip('YAML round-trip test requires Python with PyYAML: '+LoadText(lLog));
  lData:=GetJSON(cJSON);
  lConverter:=TJSONToYaml.Create;
  lStream:=TMemoryStream.Create;
  try
    lConverter.Convert(lData,lStream);
    lJSONPath:=IncludeTrailingPathDelimiter(ADirectory)+'expected.json';
    lYamlPath:=IncludeTrailingPathDelimiter(ADirectory)+'actual.yaml';
    lScript:=IncludeTrailingPathDelimiter(ADirectory)+'check_yaml.py';
    SaveBytes(lJSONPath,cJSON);
    SaveBytes(lYamlPath,StreamText(lStream));
    SaveBytes(lScript,UTF8Encode(cCheck));
    lExit:=RunTool(lPython,[lScript,lJSONPath,lYamlPath],lLog,AContext);
    AContext.AssertEquals(0,lExit,
      'YAML changed string values or document structure: '+LoadText(lLog));
  finally
    lStream.Free;
    lConverter.Free;
    lData.Free;
  end;
end;

procedure Probe11(const ADirectory: string; AContext: TNXTestContext);
const
  cInputs: array[0..2] of UTF8String = ('{"value":1}', '{"items":[{"value":1}]}',
    '{"text":"plain","enabled":true}');
var
  lGenerator: TJSONToPascal;
  lIndex, lMode, lExit: Integer;
  lUnitName, lSource, lCompiler, lRTL, lLog: string;
begin
  lCompiler:=GetEnvironmentVariable('NXTEST_FPC');
  lRTL:=GetEnvironmentVariable('NXTEST_RTL');
  lGenerator:=TJSONToPascal.Create(nil);
  try
    for lIndex:=Low(cInputs) to High(cInputs) do
    for lMode:=0 to 3 do
    begin
      lGenerator.Code.Clear;
      case lMode of
        0: lGenerator.Options:=[];
        1: lGenerator.Options:=[jpoGenerateLoad];
        2: lGenerator.Options:=[jpoGenerateSave];
        3: lGenerator.Options:=[jpoGenerateLoad,jpoGenerateSave];
      end;
      lUnitName:='GeneratedJSON'+IntToStr(lIndex)+'Mode'+IntToStr(lMode);
      lGenerator.DestUnitName:=lUnitName;
      lGenerator.JSON:=cInputs[lIndex];
      lGenerator.Execute;
      if lIndex<>1 then
        AContext.AssertFalse(Pos('Destructor Destroy; override;',lGenerator.Code.Text)>0,
          'Scalar-only class has a destructor declaration without an implementation.');
      lSource:=IncludeTrailingPathDelimiter(ADirectory)+lUnitName+'.pas';
      SaveBytes(lSource,UTF8Encode('{$mode objfpc}{$H+}'+LineEnding+lGenerator.Code.Text));
      if (lCompiler='') or (lRTL='') then
        AContext.Skip('Set NXTEST_FPC and NXTEST_RTL to compile generated Pascal with the matching SDK.');
      if not FileExists(lCompiler) or not DirectoryExists(lRTL) then
        AContext.Skip('NXTEST_FPC or NXTEST_RTL does not identify an available compiler/SDK.');
      lLog:=IncludeTrailingPathDelimiter(ADirectory)+'compile.log';
      lExit:=RunTool(lCompiler,['-n','-MObjFPC',
        {$IFDEF UNIX}'-Aas-clang',{$ENDIF}
        '-Fu'+lRTL,'-Fu'+ExtractFilePath(ParamStr(0)),
        '-FU'+ADirectory,'-FE'+ADirectory,lSource],lLog,AContext);
      AContext.AssertEquals(0,lExit,'Generated Pascal did not compile: '+LoadText(lLog));
    end;
  finally
    lGenerator.Free;
  end;
end;

procedure CheckGeneratedArray(AKind, AMode: Integer; AUseSuffix: Boolean;
  const ADirectory: string; AContext: TNXTestContext);
const
  cInputs: array[0..4] of UTF8String = (
    '{"a":[{}]}',
    '{"a":[["abc","def"],["ghi"]]}',
    '{"a":[[{"b":"abc"},{"b":"def"}],[{"b":"ghi"}]]}',
    '{"a":[{"b":"abc"}]}',
    '{"a":[{"b":"abc"}],"numbers":[1,2]}');
  cTrackedUnit = '{$mode objfpc}{$H+}'#10+
    'unit TrackedJSONObjects;'#10+
    'interface'#10+
    'type TTrackedObject = class(TObject)'#10+
    'public constructor Create; destructor Destroy; override; end;'#10+
    'var LiveObjects: Integer = 0;'#10+
    'implementation'#10+
    'constructor TTrackedObject.Create;'#10+
    'begin inherited Create; Inc(LiveObjects); end;'#10+
    'destructor TTrackedObject.Destroy;'#10+
    'begin Dec(LiveObjects); inherited Destroy; end;'#10+
    'end.'#10;
var
  lGenerator: TJSONToPascal;
  lProgram: TStringList;
  lCompiler, lRTL, lUnitName, lSuffix, lLog, lSource, lExecutable: string;
  lExit: Integer;
begin
  lCompiler:=GetEnvironmentVariable('NXTEST_FPC');
  lRTL:=GetEnvironmentVariable('NXTEST_RTL');
  if (lCompiler='') or (lRTL='') then
    AContext.Skip('Set NXTEST_FPC and NXTEST_RTL to compile generated array classes.');
  if not FileExists(lCompiler) or not DirectoryExists(lRTL) then
    AContext.Skip('NXTEST_FPC or NXTEST_RTL does not identify an available compiler/SDK.');
  lSuffix:='';
  if AUseSuffix then
    lSuffix:='Type';
  lUnitName:='GeneratedArray'+IntToStr(AKind)+'Mode'+IntToStr(AMode)+lSuffix;
  lGenerator:=TJSONToPascal.Create(nil);
  lProgram:=TStringList.Create;
  try
    case AMode of
      0: lGenerator.Options:=[];
      1: lGenerator.Options:=[jpoGenerateLoad];
      2: lGenerator.Options:=[jpoGenerateSave];
      3: lGenerator.Options:=[jpoGenerateLoad,jpoGenerateSave];
    end;
    lGenerator.DestUnitName:=lUnitName;
    lGenerator.DefaultParentName:='TTrackedObject';
    lGenerator.ExtraUnitNames:='TrackedJSONObjects';
    lGenerator.PropertyTypeSuffix:=lSuffix;
    lGenerator.JSON:=cInputs[AKind];
    lGenerator.Execute;
    SaveBytes(IncludeTrailingPathDelimiter(ADirectory)+lUnitName+'.pas',
      UTF8Encode('{$mode objfpc}{$H+}'+LineEnding+lGenerator.Code.Text));
    SaveBytes(IncludeTrailingPathDelimiter(ADirectory)+'TrackedJSONObjects.pas',cTrackedUnit);
    lProgram.Add('program GeneratedArrayCheck;');
    lProgram.Add('{$mode objfpc}{$H+}');
    lProgram.Add('uses SysUtils, fpJSON, JSONParser, TrackedJSONObjects, '+lUnitName+';');
    lProgram.Add('var lModel: TMyObject; lArray: Ta'+lSuffix+';');
    if AKind=4 then
      lProgram.Add('lNumbers: Tnumbers;');
    lProgram.Add('lData, lSaved: TJSONData;');
    lProgram.Add('begin');
    lProgram.Add('lData:=GetJSON('''+string(cInputs[AKind])+''');');
    lProgram.Add('lSaved:=nil; lModel:=nil;');
    lProgram.Add('try');
    if jpoGenerateLoad in lGenerator.Options then
      lProgram.Add('lModel:=TMyObject.CreateFromJSON(lData);')
    else
    begin
      lProgram.Add('lModel:=TMyObject.Create;');
      if AKind in [1,2] then
        lProgram.Add('SetLength(lArray,2); SetLength(lArray[0],2); SetLength(lArray[1],1);')
      else
        lProgram.Add('SetLength(lArray,1);');
      case AKind of
        0: lProgram.Add('lArray[0]:=TaItem'+lSuffix+'.Create;');
        1: lProgram.Add('lArray[0][0]:=''abc''; lArray[0][1]:=''def''; lArray[1][0]:=''ghi'';');
        2:
          begin
            lProgram.Add('lArray[0][0]:=TaItemItem.Create; lArray[0][0].b:=''abc'';');
            lProgram.Add('lArray[0][1]:=TaItemItem.Create; lArray[0][1].b:=''def'';');
            lProgram.Add('lArray[1][0]:=TaItemItem.Create; lArray[1][0].b:=''ghi'';');
          end;
        3,4: lProgram.Add('lArray[0]:=TaItem.Create; lArray[0].b:=''abc'';');
      end;
      lProgram.Add('lModel.a:=lArray; lArray:=nil;');
      if AKind=4 then
      begin
        lProgram.Add('SetLength(lNumbers,2); lNumbers[0]:=1; lNumbers[1]:=2;');
        lProgram.Add('lModel.numbers:=lNumbers; lNumbers:=nil;');
      end;
    end;
    if AKind in [1,2] then
    begin
      lProgram.Add('if (Length(lModel.a)<>2) or (Length(lModel.a[0])<>2) or');
      lProgram.Add('(Length(lModel.a[1])<>1) then raise Exception.Create(''Nested array lengths'');');
      if AKind=1 then
        lProgram.Add('if (lModel.a[0][0]<>''abc'') or (lModel.a[0][1]<>''def'') or (lModel.a[1][0]<>''ghi'') then')
      else
        lProgram.Add('if (lModel.a[0][0].b<>''abc'') or (lModel.a[0][1].b<>''def'') or (lModel.a[1][0].b<>''ghi'') then');
      lProgram.Add('raise Exception.Create(''Nested array values'');');
    end
    else
    begin
      lProgram.Add('if Length(lModel.a)<>1 then raise Exception.Create(''Object array length'');');
      if AKind in [3,4] then
        lProgram.Add('if lModel.a[0].b<>''abc'' then raise Exception.Create(''Object array value'');');
    end;
    if AKind=4 then
      lProgram.Add('if (Length(lModel.numbers)<>2) or (lModel.numbers[0]<>1) or (lModel.numbers[1]<>2) then raise Exception.Create(''Scalar array values'');');
    if jpoGenerateSave in lGenerator.Options then
    begin
      lProgram.Add('lSaved:=lModel.SaveToJSON;');
      lProgram.Add('if lSaved.AsJSON<>lData.AsJSON then raise Exception.Create(''JSON round trip: ''+lSaved.AsJSON);');
    end;
    lProgram.Add('finally lModel.Free; lSaved.Free; lData.Free; end;');
    lProgram.Add('if LiveObjects<>0 then raise Exception.Create(''Generated array destructor leaked objects'');');
    lProgram.Add('end.');
    lSource:=IncludeTrailingPathDelimiter(ADirectory)+'GeneratedArrayCheck.lpr';
    SaveBytes(lSource,UTF8Encode(lProgram.Text));
    lLog:=IncludeTrailingPathDelimiter(ADirectory)+'compile.log';
    lExit:=RunTool(lCompiler,['-n','-MObjFPC','-gt','-Cr',
      {$IFDEF UNIX}'-Aas-clang',{$ENDIF}
      '-Fu'+lRTL,'-Fu'+ExtractFilePath(ParamStr(0)),'-Fu'+ADirectory,
      '-FU'+ADirectory,'-FE'+ADirectory,lSource],lLog,AContext);
    AContext.AssertEquals(0,lExit,lUnitName+' did not compile: '+LoadText(lLog));
    lExecutable:=IncludeTrailingPathDelimiter(ADirectory)+'GeneratedArrayCheck'+
      {$IFDEF MSWINDOWS}'.exe'{$ELSE}''{$ENDIF};
    lLog:=IncludeTrailingPathDelimiter(ADirectory)+'run.log';
    lExit:=RunTool(lExecutable,[],lLog,AContext);
    AContext.AssertEquals(0,lExit,lUnitName+' failed: '+LoadText(lLog));
  finally
    lProgram.Free;
    lGenerator.Free;
  end;
end;

procedure Probe12(const ADirectory: string; AContext: TNXTestContext);
var
  lMode, lKind: Integer;
begin
  for lMode:=0 to 3 do
  begin
    CheckGeneratedArray(0,lMode,False,ADirectory,AContext);
    CheckGeneratedArray(0,lMode,True,ADirectory,AContext);
    for lKind:=2 to 4 do
      CheckGeneratedArray(lKind,lMode,False,ADirectory,AContext);
  end;
end;

procedure Probe13(const ADirectory: string; AContext: TNXTestContext);
var
  lMode: Integer;
begin
  for lMode:=0 to 3 do
    CheckGeneratedArray(1,lMode,False,ADirectory,AContext);
end;

procedure Probe14(const ADirectory: string; AContext: TNXTestContext);
var
  lIni, lReopened: TJSONIniFile;
  lData: TJSONData;
  lFileName: string;
begin
  lFileName:=IncludeTrailingPathDelimiter(ADirectory)+'booleans.json';
  lIni:=TJSONIniFile.Create(lFileName);
  try
    lIni.WriteBool('section','enabled',True);
    lIni.WriteBool('section','disabled',False);
    AContext.AssertFalse(FileExists(lFileName),'Cached Boolean writes created the file.');
    lIni.CacheUpdates:=False;
    lData:=GetJSON(UTF8Encode(LoadText(lFileName)));
    try
      AContext.AssertTrue(lData.FindPath('section.enabled').JSONType=jtBoolean);
      AContext.AssertTrue(lData.FindPath('section.disabled').JSONType=jtBoolean);
      AContext.AssertEquals('true',string(lData.FindPath('section.enabled').AsString));
      AContext.AssertEquals('false',string(lData.FindPath('section.disabled').AsString));
    finally
      lData.Free;
    end;
    lIni.WriteBool('section','enabled',False);
    lIni.WriteBool('section','disabled',True);
    lReopened:=TJSONIniFile.Create(lFileName);
    try
      AContext.AssertFalse(lReopened.ReadBool('section','enabled',True));
      AContext.AssertTrue(lReopened.ReadBool('section','disabled',False));
    finally
      lReopened.Free;
    end;
  finally
    lIni.Free;
  end;
end;

procedure RunFCLJSONProbe(AId: Integer; const ADirectory: string;
  AContext: TNXTestContext);
begin
  case AId of
    1: Probe01(AContext);
    2: Probe02(ADirectory,AContext);
    3: Probe03(ADirectory,AContext);
    4: Probe04(AContext);
    5: Probe05(AContext);
    6: Probe06(AContext);
    7: Probe07(AContext);
    8: Probe08(AContext);
    9: Probe09(AContext);
    10: Probe10(ADirectory,AContext);
    11: Probe11(ADirectory,AContext);
    12: Probe12(ADirectory,AContext);
    13: Probe13(ADirectory,AContext);
    14: Probe14(ADirectory,AContext);
  else
    AContext.Fail('Unknown JSON review probe.');
  end;
end;

end.

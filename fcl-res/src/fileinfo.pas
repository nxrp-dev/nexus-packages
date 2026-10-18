{
    This file is part of the Free Component Library (FCL)
    Copyright (c) 2013 by the Free Pascal development team

    File/Program version information routines.

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{$IFNDEF FPC_DOTTEDUNITS}
unit FileInfo;
{$ENDIF FPC_DOTTEDUNITS}

{$mode objfpc}
{$h+}
interface

{$IFDEF FPC_DOTTEDUNITS}
uses
  System.SysUtils, System.Classes,  System.Resources.Resource, System.Resources.VersionTypes, System.Resources.Version;
{$ELSE FPC_DOTTEDUNITS}
uses
  SysUtils, Classes,  resource, versiontypes, versionresource;
{$ENDIF FPC_DOTTEDUNITS}

type
  // Low level interface
  { TVersionInfo }
  TVersionInfo = class
  private
    FResources : TResources;
    FVersionInfo : TVersionResource;
    procedure CheckLoaded;
    procedure FreeResources;
    function GetFixedInfo: TVersionFixedInfo;
    function GetStringFileInfo: TVersionStringFileInfo;
    function GetVarFileInfo: TVersionVarFileInfo;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(Const Instance: THandle); overload;
    procedure Load(Const AFileName : string); overload;
    property FixedInfo: TVersionFixedInfo read GetFixedInfo;
    property StringFileInfo: TVersionStringFileInfo read GetStringFileInfo;
    property VarFileInfo: TVersionVarFileInfo read GetVarFileInfo;
  end;

type
  // Higher level interface
  { TFileVersionInfo }

  TFileVersionInfo = class(TComponent)
  private
    FEnabled: Boolean;
    FFileName : String;
    FFilter : TStrings;
    FTranslation: String;
    FTranslationOnly: Boolean;
    FVersionStrings: TStrings;
    procedure CheckRead;
    Procedure FilterChange(Sender : TObject);
    procedure SetEnabled(AValue: Boolean);
    procedure SetFileName (Const AFileName : String);
    procedure SetFilter(AValue: TStrings);
    procedure SetTranslation(const AValue: String);
    procedure SetTranslationOnly(AValue: Boolean);
  public
    constructor Create(AOwner: TComponent);  override;
    destructor Destroy; override;
    Procedure Loaded; override;
    // Read info from file "FileName".
    procedure ReadFileInfo;
  published
    // If True, the info will be read as soon as a property changes.
    Property Enabled : Boolean Read FEnabled Write SetEnabled;
    // Filename to read version info from.
    property FileName : string  read FFileName write SetFileName;
    // Extracted version information.
    property VersionStrings : TStrings  read FVersionStrings;
    // Set of key namess to read. If Empty, all keys are read.
    property Filter : TStrings read FFilter Write SetFilter;
    // Translation to use. If none, take first language. After reading it will contain the used translation.
    property Translation : String read FTranslation Write SetTranslation;
    // If set to true, if the detected language is not found, an exception is raised.
    Property TranslationOnly : Boolean Read FTranslationOnly Write SetTranslationOnly;
  end;
  EVersionInfo = Class(Exception);

  {  Convenience functions }

  TVersionQuad = Array[1..4] of Word; // Array version
  TProgramVersion = Record
    Major,Minor,Revision,Build : Word;  // Record version
  end;

  // Compare result.
  TVersionCompare = (vcEqual,           // Equal version
                     vcBuildDiffers,    // Build differs version
                     vcRevisionDiffers, // At least revision differs
                     vcMinorDiffers,    // At least Minor version differs
                     vcMajorDiffers     // At least Major version differs
                     );

// Extract program version information in 1 call.
Function GetProgramVersion (Out Version : TVersionQuad) : Boolean;
Function GetProgramVersion (Out Version : TProgramVersion) : Boolean;
// Compare 2 versions
Function CompareVersionQuads(Quad1,Quad2 : TVersionQuad) : TVersionCompare;
Function CompareProgramVersion(Version1,Version2 : TProgramVersion) : TVersionCompare;
// Convert version quad to string
Function VersionQuadToStr(Const Quad : TVersionQuad) : String;
Function ProgramVersionToStr(Const Version : TProgramVersion) : String;
// Try to convert string to version quad.
Function TryStrToVersionQuad(AText: String; Out AQuad: TVersionQuad): Boolean;
Function TryStrToProgramVersion(const S : String; Out Version : TProgramVersion) : Boolean;
// Convert string to version quad, raise exception if invalid string.
Function StrToVersionQuad(Const S : String) : TVersionQuad;
Function StrToProgramVersion(Const S : String ): TProgramVersion;
// Check if a version is newer than another. Maybe convert to operators ?
Function NewerVersion(Q1,Q2 : TVersionQuad) : Boolean;
Function NewerVersion(V1,V2 : TProgramVersion) : Boolean;
Function NewerVersion(V1,V2 : String) : Boolean;

Operator := (q : TVersionQuad) : TProgramVersion;
Operator := (V : TProgramVersion) : TVersionQuad;

implementation

Resourcestring
  SErrNoResourcesLoaded = 'No version info loaded';
  SErrNoTranslation = 'Translation "%s" not found in version strings.';
  SErrNotVersionQuad = 'Quadruple "%s" is not a valid version';

{ TVersionInfo }

function TVersionInfo.GetFixedInfo: TVersionFixedInfo;
begin
  CheckLoaded;
  Result:=FVersionInfo.FixedInfo;
end;

Procedure TVersionInfo.CheckLoaded;

begin
  if (FVersionInfo=Nil) then
    Raise EVersionInfo.Create(SErrNoResourcesLoaded);
end;

function TVersionInfo.GetStringFileInfo: TVersionStringFileInfo;
begin
  CheckLoaded;
  Result := FVersionInfo.StringFileInfo;
end;

function TVersionInfo.GetVarFileInfo: TVersionVarFileInfo;
begin
  CheckLoaded;
  Result := FVersionInfo.VarFileInfo;
end;

constructor TVersionInfo.Create;
begin
  inherited Create;
end;

destructor TVersionInfo.Destroy;
begin
  FreeResources;
  inherited Destroy;
end;

procedure TVersionInfo.FreeResources;

begin
  if Assigned(FResources) then
    begin
      FreeAndNil(FResources);
      FVersionInfo := nil;
    end
  else
    FreeAndNil(FVersionInfo);
end;

procedure TVersionInfo.Load(Const AFileName : String);

Var
  I : LongWord;

begin
  FreeResources;
  FResources:=TResources.Create;
  FResources.LoadFromFile(AFileName);
  I:=0;
  While (FVersionInfo=Nil) and (I<FResources.Count) do
    begin
    if FResources.Items[i] is TVersionResource then
       FVersionInfo:=TVersionResource(FResources.Items[i]);
    Inc(I);
    end;
  // This will read the info.
  if assigned(FVersionInfo) then
    FVersionInfo.FixedInfo;
end;

procedure TVersionInfo.Load(Const Instance: THandle);
var
  Stream: TResourceStream;
begin
  FreeResources;
  Stream := TResourceStream.CreateFromID(Instance, 1, {$ifdef FPC_OS_UNICODE}PWideChar{$else}PAnsiChar{$endif}(RT_VERSION));
  try
    FVersionInfo:=TVersionResource.Create;
    FVersionInfo.SetCustomRawDataStream(Stream);
    // access some property to load from the stream
    FVersionInfo.FixedInfo;
    // clear the stream
    FVersionInfo.SetCustomRawDataStream(nil);
  finally
    Stream.Free;
  end;
end;

{ initialize everything }
constructor TFileVersionInfo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FVersionStrings := TStringList.Create;
  TStringList(FVersionStrings).Duplicates:=dupIgnore;
  FFilter:=TStringList.Create;
  TStringList(FFilter).Duplicates:= dupIgnore;
  TStringList(FFilter).OnChange:=@FilterChange;
  FFileName := '';
end;

destructor TFileVersionInfo.Destroy;
begin
  FreeAndNil(FVersionStrings);
  FreeAndNil(FFilter);
  inherited;
end;

procedure TFileVersionInfo.Loaded;
begin
  CheckRead;
end;

{ Get filename, check if file exists and read info from file }
procedure TFileVersionInfo.SetFileName (Const AFileName : string);
begin
  FVersionStrings.clear;
  FFileName := AFileName;
  if FileExists(FFileName) or (FFileName='') then
    CheckRead;
end;

procedure TFileVersionInfo.SetEnabled(AValue: Boolean);
begin
  if FEnabled=AValue then Exit;
  FEnabled:=AValue;
  CheckRead;
end;

{ read info from file }
procedure TFileVersionInfo.ReadFileInfo;
var
  lInfo: TVersionInfo;
  lTable: TVersionStringTable;
  lTableIndex, lIndex: Integer;
begin
  FEnabled := True;
  FVersionStrings.Clear;
  lInfo := TVersionInfo.Create;
  try
    if (FileName <> '') and (FileName <> ParamStr(0)) then
      lInfo.Load(FileName)
    else
      lInfo.Load(HInstance);
    if (FTranslation = '') and (lInfo.VarFileInfo.Count > 0) then
      FTranslation := Format('%.4x%.4x', [lInfo.VarFileInfo[0].language,
        lInfo.VarFileInfo[0].codepage]);
    lTableIndex := lInfo.StringFileInfo.Count - 1;
    if FTranslation <> '' then
      while (lTableIndex >= 0) and
        (CompareText(lInfo.StringFileInfo[lTableIndex].Name, FTranslation) <> 0) do
        Dec(lTableIndex);
    if lTableIndex < 0 then
    begin
      if FTranslationOnly and (FTranslation <> '') then
        raise EVersionInfo.CreateFmt(SErrNoTranslation, [FTranslation]);
      if lInfo.StringFileInfo.Count = 0 then Exit;
      lTableIndex := 0;
    end
    else if FTranslation = '' then
      lTableIndex := 0;
    lTable := lInfo.StringFileInfo[lTableIndex];
    FTranslation := lTable.Name;
    for lIndex := 0 to lTable.Count - 1 do
      if (FFilter.Count = 0) or (FFilter.IndexOf(lTable.Keys[lIndex]) <> -1) then
        FVersionStrings.Add(lTable.Keys[lIndex] + '=' + lTable.ValuesByIndex[lIndex]);
  finally
    lInfo.Free;
  end;
end;

procedure TFileVersionInfo.SetFilter(AValue: TStrings);
begin
  if FFilter=AValue then Exit;
  FFilter.Assign(AValue);
  CheckRead;
end;

procedure TFileVersionInfo.SetTranslation(const AValue: String);
begin
  if FTranslation=AValue then Exit;
  FTranslation:=AValue;
  CheckRead;
end;

procedure TFileVersionInfo.SetTranslationOnly(AValue: Boolean);
begin
  if FTranslationOnly=AValue then Exit;
  FTranslationOnly:=AValue;
  CheckRead;
end;

procedure TFileVersionInfo.CheckRead;

begin
  if Enabled and not (csLoading in ComponentState) then
    ReadFileInfo;
end;

procedure TFileVersionInfo.FilterChange(Sender: TObject);
begin
  CheckRead;
end;

{ Convenience function }

Function GetProgramVersion (Out Version : TVersionQuad) : Boolean;

Var
  VI : TVersionInfo;
  I : Integer;

begin
  Result:=False;
  VI:=TVersionInfo.Create;
  try
    try
      VI.Load(HInstance);
      For I:=1 to 4 do
        Version[i]:=VI.FixedInfo.FileVersion[I-1];
      Result:=True;
    except
      // Ignore
    end;
  finally
    VI.Free;
  end;
end;

Function GetProgramVersion (Out Version : TProgramVersion) : Boolean;
Var
  VQ : TVersionQuad;
begin
  Result:=GetProgramVersion(VQ);
  if Result then
    Version:=VQ;
end;

Function CompareVersionQuads(Quad1,Quad2 : TVersionQuad) : TVersionCompare;

Const
  EqualResults : Array[1..4] of TVersionCompare =
    (vcMajorDiffers,vcMinorDiffers,vcRevisionDiffers,vcBuildDiffers);

Var
  I : Integer;
begin
  Result:=vcEqual;
  I:=1;
  While (Result=vcEqual) and (I<5) do
    If Quad1[i]<>Quad2[i] then
      Result:=EqualResults[i]
    else
      inc(I);
end;

Function CompareProgramVersion(Version1,Version2 : TProgramVersion) : TVersionCompare;
Var
  Q1,Q2 : TVersionQuad;
begin
  Q1:=Version1;
  Q2:=Version2;
  Result:=CompareVersionQuads(Q1,Q2);
end;

function PadVersion(const S: String): String;

Var
  I,Dots : Integer;

begin
  Dots:=0;
  For i:=1 to length(S) do
    if S[i]='.' then
      Inc(Dots);
  Result:=S;
  while (Dots<3) do
   begin
   Result:=result+'.0';
   Inc(Dots);
   end;
end;

function VersionQuadToStr(const Quad: TVersionQuad): String;
begin
  Result:=Format('%d.%d.%d.%d',[Quad[1],Quad[2],Quad[3],Quad[4]]);
end;

Function ProgramversionToStr(Const Version : TProgramVersion) : String;

begin
  Result:=Format('%d.%d.%d.%d',[Version.Major,Version.Minor,Version.Revision,Version.Build]);
end;

Function TryStrToProgramVersion(const S : String; Out Version : TProgramVersion) : Boolean;

Var
  Q : TVersionQuad;
begin
  Result:=TryStrToVersionQuad(S,Q);
  if Result then
    Version:=Q;
end;

function TryStrToVersionQuad(AText: String; out AQuad: TVersionQuad): Boolean;
var
  lIndex, lPart, lValue, lStart: Integer;
  lParsed: TVersionQuad;
begin
  Result := False;
  FillChar(AQuad, SizeOf(AQuad), 0);
  lIndex := 1;
  for lPart := 1 to 4 do
  begin
    lStart := lIndex;
    lValue := 0;
    while (lIndex <= Length(AText)) and (AText[lIndex] in ['0'..'9']) do
    begin
      lValue := lValue * 10 + Ord(AText[lIndex]) - Ord('0');
      if lValue > High(Word) then Exit;
      Inc(lIndex);
    end;
    if lIndex = lStart then Exit;
    lParsed[lPart] := lValue;
    if lPart < 4 then
    begin
      if (lIndex > Length(AText)) or (AText[lIndex] <> '.') then Exit;
      Inc(lIndex);
    end;
  end;
  if lIndex <= Length(AText) then Exit;
  AQuad := lParsed;
  Result := True;
end;

Function StrToVersionQuad(Const S : String) : TVersionQuad;

begin
  if Not TryStrToVersionQuad(S,Result) then
    Raise EConvertError.CreateFmt(SErrNotVersionQuad,[S]);
end;

Function StrToProgramVersion(Const S : String ): TProgramVersion;

begin
  Result:=StrToVersionQuad(S);
end;

Function NewerVersion(V1,V2 : TProgramVersion) : Boolean;

Var
  Q1,Q2 : TVersionQuad;

begin
  Q1:=V1;
  Q2:=V2;
  Result:=NewerVersion(Q1,Q2);
end;

Function NewerVersion(Q1,Q2 : TVersionQuad) : Boolean;

begin
  Result:=False;
  Case CompareVersionQuads(Q1,Q2) of
    vcEqual           : Result:=False;
    vcBuildDiffers    : Result:=Q1[4]>Q2[4];
    vcRevisionDiffers : Result:=Q1[3]>Q2[3];
    vcMinorDiffers    : Result:=Q1[2]>Q2[2];
    vcMajorDiffers    : Result:=Q1[1]>Q2[1];
  end;
end;

function NewerVersion(V1, V2: String): Boolean;

Var
  Q1,Q2 : TVersionQuad;

begin
  if TryStrToVersionQuad(V1,Q1) and TryStrToVersionQuad(V2,Q2) then
    Result:=NewerVersion(Q1,Q2)
  else
    Result:=False;
end;

Operator := (q : TVersionQuad) : TProgramVersion;

begin
  Result.Major:=Q[1];
  Result.Minor:=Q[2];
  Result.Revision:=Q[3];
  Result.Build:=Q[4];
end;

Operator := (V : TProgramVersion) : TVersionQuad;
begin
  Result[1]:=V.Major;
  Result[2]:=V.Minor;
  Result[3]:=V.Revision;
  Result[4]:=V.Build;
end;
end.

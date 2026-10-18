{
 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 51 Franklin Street, Fifth Floor, Boston, MA, 02110-1301, USA.   *
 *                                                                         *
 ***************************************************************************

  Author:
      Graeme Geldenhuys

  Name:
      generateincfiles - generates include files from po files.

  Synopsis:
      generateincfiles fpgui_base_dir

  Description:
      generateincfiles will generate the lang_<langID>.inc files in the
      src/corelib/ directory. The include files are used when changing the
      default language of fpGUI.

}

program GenarateIncFiles;

{$mode objfpc}{$H+}

{$ifdef Windows}
  {$define CaseInsensitiveFilenames}
{$endif}


uses
  Classes, SysUtils, Generics.Collections, Generics.Defaults;
  
const
  UTF8FileHeader = #$ef#$bb#$bf;
  
type
  TMsgItem = record
    Comment: string;
    ID: string;
    Str: string;
  end;
  PMsgItem = ^TMsgItem;
  
  TMsgItemClass = class(TObject)
  private
    function GetIdentifier: string;
    function GetValue: string;
  public
    Comment: string;
    ID: string;
    Str: string;
    property Identifier: string read GetIdentifier;
    property Value: string read GetValue;
  end;

{ TMsgItemClass }

function TMsgItemClass.GetIdentifier: string;
var
  s: string;
  p: integer;
begin
  if Comment = '' then
    Result := ''
  else
  begin
    p := Pos(':', Comment);
    if p = 0 then
    begin
      Result := '';
      Exit;
    end
    else
    begin
      s := Copy(Comment, p+1, Length(Comment)-p);
      p := Pos(':', s);
      Result := Copy(s, p+1, Length(s)-p);
    end;
  end;
end;

function TMsgItemClass.GetValue: string;
begin
  if Str <> '' then
    Result := Str
  else
    Result := ID;
end;
  
function CompareMsgIDs(const AFirst, ASecond: string): Integer;
begin
  Result := CompareStr(AFirst, ASecond);
end;

procedure DisposeMsgTree(var ATree: specialize TAVLTreeMap<string, PMsgItem>);
var
  lMessage: PMsgItem;
begin
  for lMessage in ATree.Values do Dispose(lMessage);
  FreeAndNil(ATree);
end;

function GetAllFilesMask: string;
begin
  {$IFDEF WINDOWS}
  Result:='*.*';
  {$ELSE}
  Result:='*';
  {$ENDIF}
end;

function CompareFilenames(const Filename1, Filename2: string): integer;
begin
  {$IFDEF CaseInsensitiveFilenames}
  Result:=AnsiCompareText(Filename1, Filename2);
  {$ELSE}
  Result:=CompareStr(Filename1, Filename2);
  {$ENDIF}
end;


type
  TPoFile = class
  public
    Tree: specialize TAVLTreeMap<string, PMsgItem>;
    Header: TStringList;
    Items: specialize TObjectList<TMsgItemClass>;
    UTF8Header: string;
    constructor Create;
    destructor Destroy; override;
  end;

{ TPoFile }

constructor TPoFile.Create;
begin
  Tree := specialize TAVLTreeMap<string, PMsgItem>.Create(
    specialize TComparer<string>.Construct(@CompareMsgIDs));
  Header:=TStringList.Create;
  Items := specialize TObjectList<TMsgItemClass>.Create(True);
end;

destructor TPoFile.Destroy;
begin
  DisposeMsgTree(Tree);
  Header.Free;
  Items.Free;
  inherited Destroy;
end;

//==============================================================================
var
  Files: TStringList;
  Prefix: string;
  BaseDir: string;
  
const
  cLang = PathDelim + 'languages' + PathDelim;
  cCorelib = PathDelim + 'src' + PathDelim + 'corelib' + PathDelim;

procedure IncPrefix;
begin
  Prefix:=Prefix+'  ';
end;

procedure DecPrefix;
begin
  Prefix:=LeftStr(Prefix,length(Prefix)-2);
end;

function ParamsValid: boolean;
begin
  Result := false;
  if ParamCount < 1 then
    Exit; //==>
  BaseDir := ParamStr(1);
  if not DirectoryExists(BaseDir) then
  begin
    writeln('ERROR: fpGUI base directory <'+BaseDir+'> does not exist.');
    Exit; //==>
  end;
  // Does it look like the fpGUI base directory? We do three simple tests.
  if not FileExists(BaseDir + PathDelim + 'AUTHORS.txt') then
  begin
    writeln('ERROR: <'+BaseDir+'> directory does not look like the fpGUI base directory.');
    Exit; //==>
  end;
  if not DirectoryExists(BaseDir + cLang) then
  begin
    writeln('ERROR: <'+BaseDir+'> directory does not look like the fpGUI base directory.');
    writeln('       The ' + cLang + ' directory is missing.');
    Exit; //==>
  end;
  if not DirectoryExists(BaseDir + cCoreLib) then
  begin
    writeln('ERROR: <'+BaseDir+'> directory does not look like the fpGUI base directory.');
    writeln('       The ' + cCoreLib + ' directory is missing.');
    Exit; //==>
  end;
  Result := true;
end;

function ReadMessageItem(SrcFile: TStringList; var Line: integer): PMsgItem;
var
  s: string;
begin
  New(Result);
  while Line<SrcFile.Count do begin
    s:=SrcFile[Line];
    if (s<>'') and (s[1]='#') then begin
      Result^.Comment:=Result^.Comment+copy(s,2,length(s));
    end
    else if (LeftStr(s,7)='msgid "') then begin
      // read ID
      Result^.ID:=copy(s,8,length(s)-8);
      inc(Line);
      while Line<SrcFile.Count do begin
        s:=SrcFile[Line];
        if (s<>'') and (s[1]='"') then begin
          Result^.ID:=Result^.ID+#10+copy(s,2,length(s)-2);
          inc(Line);
        end else
          break;
      end;
      // read Str
      if Line<SrcFile.Count then begin
        s:=SrcFile[Line];
        if LeftStr(s,8)='msgstr "' then begin
          Result^.Str:=copy(s,9,length(s)-9);
          inc(Line);
          while Line<SrcFile.Count do begin
            s:=SrcFile[Line];
            if (s<>'') and (s[1]='"') then begin
              Result^.Str:=Result^.Str+#10+copy(s,2,length(s)-2);
              inc(Line);
            end else
              break;
          end;
        end;
      end;
      exit;
    end;
    inc(Line);
  end;
end;

function CreateMsgItemClass(AMsgItem: PMsgItem): TMsgItemClass;
begin
  Result := nil;
  if (AMsgItem^.Comment = '') or (AMsgItem^.Comment[1] <> ':') then
    exit;
  Result := TMsgItemClass.Create;
  Result.Comment := AMsgItem^.Comment;
//  writeln(Prefix, ' Comment: ', Result.Comment);
  Result.ID := AMsgItem^.ID;
  Result.Str := AMsgItem^.Str;
end;

procedure WriteMessageItem(MsgItem: PMsgItem; DestFile: TStringList);

  procedure WriteItem(const Prefix: string; Str: string);
  var
    s: String;
    p: Integer;
  begin
    s:=Prefix+' "';
    p:=1;
    while (p<=length(Str)) do begin
      if Str[p]=#10 then begin
        // a new line
        s:=s+copy(Str,1,p-1)+'"';
        DestFile.Add(s);
        Str:=copy(Str,p+1,length(Str));
        p:=1;
        // start new line
        s:='"';
      end else
        inc(p);
    end;
    if (Str<>'') or (s<>'"') then begin
      s:=s+Str+'"';
      DestFile.Add(s);
    end;
  end;

begin
  if MsgItem^.Comment<>'' then
    DestFile.Add('#'+MsgItem^.Comment);
  WriteItem('msgid',MsgItem^.ID);
  WriteItem('msgstr',MsgItem^.Str);
  DestFile.Add('');
end;

function ReadPoFile(const Filename: string): TPoFile;
var
  SrcFile: TStringList;
  MsgItem: PMsgItem;
  Line: Integer;
  oMsgItem: TMsgItemClass;
begin
  Result:=TPoFile.Create;

  // read source .po file
  //writeln(Prefix,'Loading ',Filename,' ...');
  SrcFile:=TStringList.Create;
  SrcFile.LoadFromFile(Filename);
  
  if (SrcFile.Count>0) and (copy(SrcFile[0],1,3)=UTF8FileHeader) then
  begin
    Result.UTF8Header:=copy(SrcFile[0],1,3);
    SrcFile[0]:=copy(SrcFile[0],4,length(SrcFile[0]));
  end;
  
  Line:=0;
  while Line<SrcFile.Count do
  begin
    if (SrcFile[Line]='') then
    begin
      // empty line
      inc(Line);
    end
    else
    begin
      // message
      MsgItem:=ReadMessageItem(SrcFile,Line);
      // ignore doubles
      if (Result.Tree.Find(MsgItem^.ID)<>nil) then
      begin
        Dispose(MsgItem);
        continue;
      end;
      // message class
      oMsgItem := CreateMsgItemClass(MsgItem);
      // add message
      Result.Tree.Add(MsgItem^.ID, MsgItem);
      if oMsgItem <> nil then
        Result.Items.Add(oMsgItem);
    end;
  end;

  SrcFile.Free;
end;

procedure WritePoFile(APoFile: TPoFile; const AFileName: string);
var
  lDestFile: TStringList;
  lMessage: PMsgItem;
  lSave: Boolean;
  lOldDestFile: TStringList;
begin
  lDestFile:=TStringList.Create;
  if (APoFile.Header.Count>0) then begin
    lDestFile.Add('msgid ""');
    lDestFile.Add('msgstr ""');
    lDestFile.AddStrings(APoFile.Header);
    lDestFile.Add('');
  end;
  for lMessage in APoFile.Tree.Values do begin
    WriteMessageItem(lMessage,lDestFile);
  end;
  if (APoFile.UTF8Header<>'') and (lDestFile.Count>0) then
    lDestFile[0]:=APoFile.UTF8Header+lDestFile[0];
  lSave:=true;
  if FileExists(AFileName) then begin
    lOldDestFile:=TStringList.Create;
    lOldDestFile.LoadFromFile(AFileName);
    if lOldDestFile.Text=lDestFile.Text then lSave:=false;
    lOldDestFile.Free;
  end;
  if lSave then
    lDestFile.SaveToFile(AFileName);
  lDestFile.Free;
end;

procedure WriteIncludeFile(APoFile: TPoFile; const AFileName: string);
var
  lDestFile: TStringList;
  lMessage: TMsgItemClass;
begin
  lDestFile := TStringList.Create;
  lDestFile.Add('{%mainunit fpg_constants.pas}');
  lDestFile.Add('');
  lDestFile.Add('{ This file is auto generated!  DO NOT EDIT. }');
  lDestFile.Add('{ Only exception is the default language English - lang_en.inc  }');
  lDestFile.Add('');
  for lMessage in APoFile.Items do
  begin
    lDestFile.Add(Format('%s  =  %s;', [lMessage.Identifier, QuotedStr(lMessage.Value)]));
    { ***** Handle special cases ***** }

    // Long and Short month May has the same text so one gets lost. Add it back.
    if SameText(lMessage.Identifier, 'rsShortMay') then
      lDestFile.Add(Format('%s  =  %s;', ['rsLongMay', QuotedStr(lMessage.Value)]));
  end;
  lDestFile.SaveToFile(AFileName);
  lDestFile.Free;
end;

function FindAllTranslatedPoFiles(const ALangDir: string): TStringList;
var
  Path: String;
  NameOnly: String;
  FileInfo: TSearchRec;
  CurExt: String;
begin
  Result := TStringList.Create;
  Path := ALangDir;
  NameOnly := 'fpgui';
  if SysUtils.FindFirst(Path+GetAllFilesMask,faAnyFile,FileInfo)=0 then begin
    repeat
      if (FileInfo.Name='.') or (FileInfo.Name='..') or (FileInfo.Name='')
      or (CompareFilenames(FileInfo.Name, 'fpgui.po')=0) then continue;
      CurExt:=ExtractFileExt(FileInfo.Name);
      if (CompareFilenames(CurExt,'.po')<>0)
      or (CompareFilenames(LeftStr(FileInfo.Name,length(NameOnly)),NameOnly)<>0)
      then
        continue;
      Result.Add(Path+FileInfo.Name);
    until SysUtils.FindNext(FileInfo)<>0;
  end;
  SysUtils.FindClose(FileInfo);
end;

procedure MergePoTrees(ASrcTree, ADestTree: specialize TAVLTreeMap<string, PMsgItem>);
var
  lSrcNode, lDestNode, lOldNode: specialize TAVLTreeMap<string, PMsgItem>.PNode;
  lSrcMessage, lDestMessage: PMsgItem;
begin
  lSrcNode := ASrcTree.FindLowest;
  while lSrcNode <> nil do
  begin
    lSrcMessage := lSrcNode^.Value;
    lDestNode := ADestTree.Find(lSrcMessage^.ID);
    if lDestNode <> nil then
      lDestNode^.Value^.Comment := lSrcMessage^.Comment
    else
    begin
      New(lDestMessage);
      lDestMessage^ := lSrcMessage^;
      ADestTree.Add(lDestMessage^.ID, lDestMessage);
    end;
    lSrcNode := lSrcNode^.Successor;
  end;
  lDestNode := ADestTree.FindLowest;
  while lDestNode <> nil do
  begin
    lDestMessage := lDestNode^.Value;
    lOldNode := lDestNode;
    lDestNode := lDestNode^.Successor;
    if (lDestMessage^.ID <> '') and (ASrcTree.Find(lDestMessage^.ID) = nil) then
    begin
      WriteLn('Deleting unused message "', lDestMessage^.ID, '"');
      ADestTree.Delete(lOldNode);
      Dispose(lDestMessage);
    end;
  end;
end;

procedure ProcessPoFile(const Filename: string);
var
  SrcFile: TPoFile;

  function Newfile: string;
  var
    s: string;
    p: integer;
  begin
    s := ExtractFileName(Filename);
    p := Pos('.', s);
    s := Copy(s, p+1, Length(s));
    s := StringReplace(s, '.po', '.inc', [rfIgnoreCase]);
    Result := BaseDir + cCorelib + 'lang_' + s;
//    writeln('  Newfile: ', Result);
  end;
  
begin
  writeln('Loading ',Filename,' ...');
  SrcFile := ReadPoFile(Filename);
  WriteIncludeFile(SrcFile, Newfile);
  SrcFile.Free;
end;

procedure ProcessAllPoFiles;
var
  i: Integer;
begin
  Files := FindAllTranslatedPoFiles(BaseDir + cLang);
  for i := 0 to Files.Count-1 do
    ProcessPoFile(Files[i]);
end;

begin
  Prefix:='';
  Files:=nil;
  if not ParamsValid then
  begin
    writeln('Usage: ',ExtractFileName(ParamStr(0)), ' fpgui_base_dir');
    Exit;
  end
  else
  begin
    ProcessAllPoFiles;
  end;
  Files.Free;
end.


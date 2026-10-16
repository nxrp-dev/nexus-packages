{$IFNDEF FPC_DOTTEDUNITS}
unit fpsimplejsonexport;
{$ENDIF FPC_DOTTEDUNITS}
{
    This file is part of the Free Pascal run time library.
    Copyright (c) 1999-2022 by Michael van Canney and other members of the
    Free Pascal development team

    Simple Json Export code

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
{$mode objfpc}{$H+}

interface

{$IFDEF FPC_DOTTEDUNITS}
uses
  System.Classes, System.SysUtils, Data.Db, Data.Export.Db, FpJson.Data;
{$ELSE FPC_DOTTEDUNITS}
uses
  Classes, SysUtils, DB, fpDBExport, fpjson;
{$ENDIF FPC_DOTTEDUNITS}

Type
  TJSONRowFormat = (rfArray,rfObject);
  TJSONColumnFormat = (cfObject,cfArray);

  { TSimpleJSONFormatSettings }

  TSimpleJSONFormatSettings = Class(TExportFormatSettings)
  private
    FColumnFormat: TJSONColumnFormat;
    FIndentSize: Integer;
    FRowElementName: String;
    FRowFormat: TJSONRowFormat;
  Public
    Procedure Assign(Source : TPersistent); override;
  Published
    Property RowElementName : String Read FRowElementName Write FRowElementName;
    Property RowFormat : TJSONRowFormat Read FRowFormat Write FRowFormat;
    Property ColumnFormat : TJSONColumnFormat Read FColumnFormat Write FColumnFormat;
    Property IndentSize : Integer Read FIndentSize Write FIndentSize;
  end;

  { TCustomSimpleJSONExporter }

  TCustomSimpleJSONExporter = Class(TCustomFileExporter)
  Private
    FCurrentRow : String;
    FIndent : String;
    FIS : Integer;
    FREN : String;
    FCF : TJSONColumnFormat;
    FRF : TJSONRowFormat;
    FRC : Int64;
    procedure DecIndent;
    function GetJSONFormatsettings: TSimpleJSONFormatSettings;
    procedure IncIndent;
    procedure OutputRow(const ARow: String);
    procedure SetJSONFormatSettings(const AValue: TSimpleJSONFormatSettings);
    function TextString(const AValue: String): String;
  Protected
    Function  CreateFormatSettings : TCustomExportFormatSettings; override;
    Procedure DoBeforeExecute; override;
    Procedure DoAfterExecute; override;
    Procedure DoDataRowStart; override;
    Procedure DoDataHeader; override;
    Procedure DoDataFooter; override;
    Procedure ExportField(AExportField : TExportFieldItem); override;
    Procedure DoDataRowEnd; override;
  Public
    Property FormatSettings : TSimpleJSONFormatSettings Read GetJSONFormatsettings Write SetJSONFormatSettings;
  end;

  TSimpleJSONExporter = Class(TCustomSimpleJSONExporter)
  Published
    Property FileName;
    Property Dataset;
    Property ExportFields;
    Property FromCurrent;
    Property RestorePosition;
    Property FormatSettings;
    Property OnExportRow;
  end;

Procedure RegisterSimpleJSONExportFormat;
Procedure UnRegisterSimpleJSONExportFormat;

Const
  SSimpleJSON            = 'SimpleJSON';
  SSimpleJSONExtensions  = '.json';

Resourcestring
  SSimpleJSONDescription = 'Simple ASCII JSON file';

implementation


{ TSimpleJSONFormatSettings }

procedure TSimpleJSONFormatSettings.Assign(Source: TPersistent);

Var
  FS : TSimpleJSONFormatSettings;

begin
  if (Source is TSimpleJSONFormatSettings) then
    begin
    FS:=Source as TSimpleJSONFormatSettings;
    FColumnFormat:=FS.FColumnFormat;
    FRowElementName:=FS.FRowElementName;
    FRowFormat:=FS.FRowFormat;
    FIndentSize:=FS.IndentSize;
    end;
  inherited Assign(Source);
end;

{ TCustomSimpleJSONExporter }

procedure TCustomSimpleJSONExporter.DecIndent;
begin
  If (FIS>0) and (length(FIndent)>=FIS) then
    Delete(FIndent,1,FIS);
end;

function TCustomSimpleJSONExporter.GetJSONFormatsettings: TSimpleJSONFormatSettings;
begin
  Result:=TSimpleJSONFormatSettings(Inherited formatsettings)
end;

procedure TCustomSimpleJSONExporter.IncIndent;
begin
  If FIS>0 then
    FIndent:=FIndent+StringOfChar(' ',FIS);
end;

procedure TCustomSimpleJSONExporter.OutputRow(const ARow: String);
begin
  Writeln(TextFile,FIndent,ARow);
end;

procedure TCustomSimpleJSONExporter.SetJSONFormatSettings(
  const AValue: TSimpleJSONFormatSettings);
begin
  Inherited FormatSettings.Assign(AValue);
end;

function TCustomSimpleJSONExporter.TextString(const AValue: String): String;
begin
  Result:=StringToJSONString(AValue);
end;

function TCustomSimpleJSONExporter.CreateFormatSettings: TCustomExportFormatSettings;
begin
  Result:=TSimpleJSONFormatSettings.Create(False);
end;

procedure TCustomSimpleJSONExporter.DoBeforeExecute;
begin
  inherited DoBeforeExecute;
  OpenTextFile;
  FREN:=FormatSettings.RowElementName;
  FRF:=FormatSettings.RowFormat;
  FCF:=FormatSettings.ColumnFormat;
  If (FREN='') and (FRF=rfObject) then
    FREN:='ROW';
  FIS:=FormatSettings.IndentSize;
  FIndent:='';
  FRC:=0;
end;

procedure TCustomSimpleJSONExporter.DoAfterExecute;
begin
  CloseTextFile;
  inherited DoAfterExecute;
end;

procedure TCustomSimpleJSONExporter.DoDataRowStart;
begin
  Inc(FRC);
  FCurrentRow:='';
end;

procedure TCustomSimpleJSONExporter.DoDataHeader;
begin
  If FRF=rfObject then
    OutputRow('{')
  else
    OutputRow('[');
  IncIndent;
end;

procedure TCustomSimpleJSONExporter.DoDataFooter;
begin
  DecIndent;
  If FRF=rfObject then
    OutputRow('}')
  else
    OutputRow(']');
end;

procedure TCustomSimpleJSONExporter.ExportField(AExportField: TExportFieldItem);

Var
  lValue : String;

begin
  if AExportField.Field.IsNull then
    lValue:='null' // do not localize
  else if AExportField.Field.DataType=ftBoolean then
    begin
    If AExportField.FIeld.AsBoolean then
      lValue:='true' // Do not localize
    else
      lValue:='false';// Do not localize
    end
  else if AExportField.Field.DataType=ftFloat then
    Str(AExportField.FIeld.asFloat,lValue)
  else
    lValue:=FormatField(AExportField.Field);
  if not (AExportField.Field.isnull or (AExportField.field.Datatype in (ordFieldTypes+[ftFloat]))) then
    lValue:='"'+TextString(lValue)+'"';
  If FCF=cfObject then
    lValue:='"'+TextString(AExportField.ExportedName)+'" : '+lValue;
  If (FCurrentRow<>'') then
    FCurrentRow:=FCurrentRow+', ';
  FCurrentRow:=FCurrentRow+lValue;
end;

procedure TCustomSimpleJSONExporter.DoDataRowEnd;

begin
  If FcF=cfObject then
    FCurrentRow:='{ '+FCurrentRow+' }'
  else
    FCurrentRow:='[ '+FCurrentRow+' ]';
  If FRF = rfObject then
    FCurrentRow:=Format('"%s%d" : %s',[TextString(FREN),FRC,FCurrentRow]);
  if FRC>1 then
    FCurrentRow:=','+FCurrentRow;
  OutputRow(FCurrentRow);
end;

Procedure RegisterSimpleJSONExportFormat;

begin
  ExportFormats.RegisterExportFormat(SSimpleJSON,SSimpleJSONDescription,SSimpleJSONExtensions,TSimpleJSONExporter);
end;
Procedure UnRegisterSimpleJSONExportFormat;

begin
  ExportFormats.UnRegisterExportFormat(SSimpleJSON);
end;

end.


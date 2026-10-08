(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNexusScriptEmitter;

{$mode delphi}{$H+}

interface

uses
  Classes,
  obNXClassFactory,
  obNexusScriptModel;

type
  TNexusScriptEmitter = class(TNXFactoryObject)
  public
    procedure AddDocument(
      ADocument: TNexusScriptCompiledDocument); virtual; abstract;
    procedure WriteArtifact(AStream: TStream); overload; virtual; abstract;
    procedure WriteArtifact(
      const AFileName: string); overload; virtual;
  end;

implementation

uses
  SysUtils;

procedure TNexusScriptEmitter.WriteArtifact(const AFileName: string);
var
  lStream: TFileStream;
begin
  if AFileName = '' then
    raise EStreamError.Create('Artifact output file name is required.');
  if not ForceDirectories(ExtractFileDir(ExpandFileName(AFileName))) then
    raise EStreamError.CreateFmt(
      'Cannot create artifact output directory for %s.', [AFileName]);
  lStream := TFileStream.Create(AFileName, fmCreate);
  try
    WriteArtifact(lStream);
  finally
    lStream.Free;
  end;
end;

end.

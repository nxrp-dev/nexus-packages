(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit tsNXPersistTests;

{$mode objfpc}{$H+}

interface

uses
  obNXTestRegistry;

procedure RegisterNXPersistTests(ARegistry: TNXTestRegistry);

implementation

uses
  Classes,
  SysUtils,
  obNXTestContext,
  obNXTestSuite,
  obNXPersist;

type
  TXXPersistMood = (
    pmCalm,
    pmFocused,
    pmChaotic
  );

  TXXPersistFlag = (
    pfVisible,
    pfEnabled,
    pfChecked
  );

  TXXPersistFlags = set of TXXPersistFlag;

  TXXPersistChild = class(TNXPersistObject)
  private
    FCaption: string;
    FScore: Integer;
  public
    class function PersistAlias: string; override;
  published
    property Caption: string read FCaption write FCaption;
    property Score: Integer read FScore write FScore;
  end;

  TXXPersistAnimal = class(TNXPersistObject)
  private
    FLegs: Integer;
    FSpecies: string;
  public
    class function PersistAlias: string; override;
  published
    property Legs: Integer read FLegs write FLegs;
    property Species: string read FSpecies write FSpecies;
  end;

  TXXPersistCat = class(TXXPersistAnimal)
  private
    FLives: Integer;
  public
    class function PersistAlias: string; override;
  published
    property Lives: Integer read FLives write FLives;
  end;

  TXXPersistDog = class(TXXPersistAnimal)
  private
    FGood: Boolean;
  public
    class function PersistAlias: string; override;
  published
    property Good: Boolean read FGood write FGood;
  end;

  TXXPersistRoot = class(TNXPersistObject)
  private
    FAnimals: TNXPersistList;
    FChild: TXXPersistChild;
    FFavorite: TXXPersistAnimal;
    FFlags: TXXPersistFlags;
    FMood: TXXPersistMood;
    FNotes: TStringList;
    FPayload: TNXPersistBinary;
    FTitle: string;
    procedure SetFavorite(AValue: TXXPersistAnimal);
  public
    constructor Create; override;
    destructor Destroy; override;

    class function PersistAlias: string; override;
  published
    property Animals: TNXPersistList read FAnimals;
    property Child: TXXPersistChild read FChild;
    property Favorite: TXXPersistAnimal read FFavorite write SetFavorite;
    property Flags: TXXPersistFlags read FFlags write FFlags;
    property Mood: TXXPersistMood read FMood write FMood;
    property Notes: TStringList read FNotes;
    property Payload: TNXPersistBinary read FPayload;
    property Title: string read FTitle write FTitle;
  end;

procedure LoadPayload(APayload: TNXPersistBinary);
const
  cPayload: array[0..7] of Byte = (0, 1, 2, 3, 4, 5, Ord('N'), Ord('X'));
var
  lStream: TMemoryStream;
begin
  lStream := TMemoryStream.Create;
  try
    lStream.WriteBuffer(cPayload[0], SizeOf(cPayload));
    lStream.Position := 0;
    APayload.LoadFromStream(lStream);
  finally
    lStream.Free;
  end;
end;

procedure AssertPayload(AContext: TNXTestContext; const AMessage: string;
  APayload: TNXPersistBinary);
const
  cPayload: array[0..7] of Byte = (0, 1, 2, 3, 4, 5, Ord('N'), Ord('X'));
var
  lBytes: array[0..7] of Byte;
  lStream: TMemoryStream;
begin
  FillChar(lBytes, SizeOf(lBytes), 0);
  lStream := TMemoryStream.Create;
  try
    APayload.SaveToStream(lStream);
    AContext.AssertEquals(SizeOf(cPayload), lStream.Size,
      AMessage + ' size mismatch');
    lStream.Position := 0;
    lStream.ReadBuffer(lBytes[0], SizeOf(lBytes));
    AContext.AssertTrue(CompareMem(@lBytes[0], @cPayload[0],
      SizeOf(cPayload)), AMessage + ' content mismatch');
  finally
    lStream.Free;
  end;
end;

function BuildRoot: TXXPersistRoot;
var
  lCat: TXXPersistCat;
  lDog: TXXPersistDog;
begin
  Result := TXXPersistRoot.Create;
  Result.Title := 'Persist Test';
  Result.Mood := pmFocused;
  Result.Flags := [pfVisible, pfEnabled];
  Result.Child.Caption := 'Nested child';
  Result.Child.Score := 42;
  Result.Notes.Add('first line');
  Result.Notes.Add('second line');
  LoadPayload(Result.Payload);

  lCat := TXXPersistCat.Create;
  lCat.Name := 'Milo';
  lCat.Species := 'Cat';
  lCat.Legs := 4;
  lCat.Lives := 9;
  Result.Animals.Add(lCat);

  lCat := TXXPersistCat.Create;
  lCat.Name := 'Favorite';
  lCat.Species := 'Cat';
  lCat.Legs := 4;
  lCat.Lives := 7;
  Result.Favorite := lCat;

  lDog := TXXPersistDog.Create;
  lDog.Name := 'Ada';
  lDog.Species := 'Dog';
  lDog.Legs := 4;
  lDog.Good := True;
  Result.Animals.Add(lDog);
end;

class function TXXPersistChild.PersistAlias: string;
begin
  Result := 'Child';
end;

class function TXXPersistAnimal.PersistAlias: string;
begin
  Result := 'Animal';
end;

class function TXXPersistCat.PersistAlias: string;
begin
  Result := 'Cat';
end;

class function TXXPersistDog.PersistAlias: string;
begin
  Result := 'Dog';
end;

constructor TXXPersistRoot.Create;
begin
  inherited Create;
  StoreReadOnlyProperties := True;
  FChild := TXXPersistChild.Create;
  FAnimals := TNXPersistList.Create;
  FAnimals.ItemClass := TXXPersistAnimal;
  FNotes := TStringList.Create;
  FPayload := TNXPersistBinary.Create;
end;

destructor TXXPersistRoot.Destroy;
begin
  FreeAndNil(FFavorite);
  FreeAndNil(FPayload);
  FreeAndNil(FNotes);
  FreeAndNil(FAnimals);
  FreeAndNil(FChild);
  inherited Destroy;
end;

class function TXXPersistRoot.PersistAlias: string;
begin
  Result := 'Root';
end;

procedure TXXPersistRoot.SetFavorite(AValue: TXXPersistAnimal);
begin
  if FFavorite = AValue then
    Exit;

  FreeAndNil(FFavorite);
  FFavorite := AValue;
end;

procedure TestRoundTripAndClone(AContext: TNXTestContext);
var
  lAnimal: TNXPersistObject;
  lClone: TNXPersistObject;
  lJSON: string;
  lLoaded: TNXPersistObject;
  lRoot: TXXPersistRoot;
begin
  lRoot := BuildRoot;
  try
    lJSON := lRoot.JSON;
    AContext.AssertTrue(Pos('"Favorite"', lJSON) > 0,
      'Favorite should stream out.');
    AContext.AssertTrue(Pos('"Lives" : 7', lJSON) > 0,
      'Favorite descendant data should stream out.');

    lLoaded := TNXPersistObject.CreateObjectFromJSON(lJSON);
    try
      AContext.AssertTrue(lLoaded is TXXPersistRoot,
        'Loaded object should be TXXPersistRoot.');
      AContext.AssertEquals(lJSON, lLoaded.JSON, 'Round-trip JSON mismatch.');
      AContext.AssertTrue(lRoot.Equals(TNXPersistObject(lLoaded)),
        'Root equality failed.');

      lAnimal := TXXPersistRoot(lLoaded).Animals[0];
      AContext.AssertTrue(lAnimal is TXXPersistCat,
        'First animal should reconstruct as TXXPersistCat.');

      lAnimal := TXXPersistRoot(lLoaded).Animals[1];
      AContext.AssertTrue(lAnimal is TXXPersistDog,
        'Second animal should reconstruct as TXXPersistDog.');
      AContext.AssertTrue(TXXPersistRoot(lLoaded).Favorite is TXXPersistCat,
        'Favorite should stream-construct as TXXPersistCat.');
      AContext.AssertEquals(7, TXXPersistCat(TXXPersistRoot(lLoaded).Favorite).Lives,
        'Favorite descendant value should round-trip.');
      AssertPayload(AContext, 'Loaded payload', TXXPersistRoot(lLoaded).Payload);
    finally
      lLoaded.Free;
    end;

    lClone := lRoot.CloneSelf;
    try
      AContext.AssertEquals(lJSON, lClone.JSON, 'Clone JSON mismatch.');
    finally
      lClone.Free;
    end;
  finally
    lRoot.Free;
  end;
end;

procedure RegisterNXPersistClasses;
begin
  TNXPersistObject.RegisterPersistClass(TXXPersistChild);
  TNXPersistObject.RegisterPersistClass(TXXPersistAnimal);
  TNXPersistObject.RegisterPersistClass(TXXPersistCat);
  TNXPersistObject.RegisterPersistClass(TXXPersistDog);
  TNXPersistObject.RegisterPersistClass(TXXPersistRoot);
end;

procedure RegisterNXPersistTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  RegisterNXPersistClasses;

  lSuite := ARegistry.AddSuite('NexusUI.Persist');
  lSuite.AddTest('RoundTripAndClone', @TestRoundTripAndClone);
end;

initialization
  RegisterNXPersistClasses;

end.

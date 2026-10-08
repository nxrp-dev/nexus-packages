(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXBEncode;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  ENXBEncodeError = class(Exception);

  TNXBEncodeValue = class
  public
    function AsBEncodedString: string; virtual; abstract;
    function Clone: TNXBEncodeValue; virtual; abstract;
  end;

  TNXBEncodeInteger = class(TNXBEncodeValue)
  private
    FValue: Int64;
  public
    constructor Create(AValue: Int64);
    function AsBEncodedString: string; override;
    function Clone: TNXBEncodeValue; override;

    property Value: Int64 read FValue write FValue;
  end;

  TNXBEncodeBytes = class(TNXBEncodeValue)
  private
    FValue: string;
  public
    constructor Create(const AValue: string);
    function AsBEncodedString: string; override;
    function Clone: TNXBEncodeValue; override;

    property Value: string read FValue write FValue;
  end;

  TNXBEncodeList = class(TNXBEncodeValue)
  private
    FItems: TList;
    function GetCount: Integer;
    function GetItem(AIndex: Integer): TNXBEncodeValue;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Add(AValue: TNXBEncodeValue);
    function AsBEncodedString: string; override;
    function Clone: TNXBEncodeValue; override;

    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TNXBEncodeValue read GetItem; default;
  end;

  TNXBEncodeDictionaryEntry = class
  private
    FKey: string;
    FValue: TNXBEncodeValue;
  public
    constructor Create(const AKey: string; AValue: TNXBEncodeValue);
    destructor Destroy; override;

    property Key: string read FKey;
    property Value: TNXBEncodeValue read FValue;
  end;

  TNXBEncodeDictionary = class(TNXBEncodeValue)
  private
    FEntries: TList;
    function GetCount: Integer;
    function GetEntry(AIndex: Integer): TNXBEncodeDictionaryEntry;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Add(const AKey: string; AValue: TNXBEncodeValue);
    function Find(const AKey: string): TNXBEncodeValue;
    function RequireBytes(const AKey: string): string;
    function RequireInteger(const AKey: string): Int64;
    function RequireDictionary(const AKey: string): TNXBEncodeDictionary;
    function FindList(const AKey: string): TNXBEncodeList;
    function AsBEncodedString: string; override;
    function Clone: TNXBEncodeValue; override;

    property Count: Integer read GetCount;
    property Entries[AIndex: Integer]: TNXBEncodeDictionaryEntry read GetEntry;
  end;

  TNXBEncodeCodec = class
  private
    FText: string;
    FPosition: Integer;
    function AtEnd: Boolean;
    function CurrentChar: Char;
    function ReadValue: TNXBEncodeValue;
    function ReadInteger: TNXBEncodeInteger;
    function ReadBytes: TNXBEncodeBytes;
    function ReadList: TNXBEncodeList;
    function ReadDictionary: TNXBEncodeDictionary;
    function ReadDecimalUntil(AEndChar: Char): string;
  public
    class function Decode(const AText: string): TNXBEncodeValue;
    class function DecodeDictionary(const AText: string): TNXBEncodeDictionary;
    class function Encode(AValue: TNXBEncodeValue): string;
  end;

implementation

function NXTextIsDigits(const AText: string): Boolean;
var
  lIndex: Integer;
begin
  Result := AText <> '';
  for lIndex := 1 to Length(AText) do
    Result := Result and (AText[lIndex] in ['0'..'9']);
end;

function NXValidBEncodeIntegerText(const AText: string): Boolean;
var
  lDigits: string;
begin
  Result := False;
  if AText = '' then
    Exit;
  if AText[1] = '-' then
  begin
    lDigits := Copy(AText, 2, MaxInt);
    if lDigits = '' then
      Exit;
    if lDigits = '0' then
      Exit;
  end
  else
    lDigits := AText;
  if not NXTextIsDigits(lDigits) then
    Exit;
  if (Length(lDigits) > 1) and (lDigits[1] = '0') then
    Exit;
  Result := True;
end;

function NXValidBEncodeLengthText(const AText: string): Boolean;
begin
  Result := NXTextIsDigits(AText);
  if Result and (Length(AText) > 1) and (AText[1] = '0') then
    Result := False;
end;

constructor TNXBEncodeInteger.Create(AValue: Int64);
begin
  inherited Create;
  FValue := AValue;
end;

function TNXBEncodeInteger.AsBEncodedString: string;
begin
  Result := 'i' + IntToStr(FValue) + 'e';
end;

function TNXBEncodeInteger.Clone: TNXBEncodeValue;
begin
  Result := TNXBEncodeInteger.Create(FValue);
end;

constructor TNXBEncodeBytes.Create(const AValue: string);
begin
  inherited Create;
  FValue := AValue;
end;

function TNXBEncodeBytes.AsBEncodedString: string;
begin
  Result := IntToStr(Length(FValue)) + ':' + FValue;
end;

function TNXBEncodeBytes.Clone: TNXBEncodeValue;
begin
  Result := TNXBEncodeBytes.Create(FValue);
end;

constructor TNXBEncodeList.Create;
begin
  inherited Create;
  FItems := TList.Create;
end;

destructor TNXBEncodeList.Destroy;
var
  lIndex: Integer;
begin
  for lIndex := 0 to FItems.Count - 1 do
    TObject(FItems[lIndex]).Free;
  FItems.Free;
  inherited Destroy;
end;

function TNXBEncodeList.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TNXBEncodeList.GetItem(AIndex: Integer): TNXBEncodeValue;
begin
  Result := TNXBEncodeValue(FItems[AIndex]);
end;

procedure TNXBEncodeList.Add(AValue: TNXBEncodeValue);
begin
  FItems.Add(AValue);
end;

function TNXBEncodeList.AsBEncodedString: string;
var
  lIndex: Integer;
begin
  Result := 'l';
  for lIndex := 0 to FItems.Count - 1 do
    Result := Result + Items[lIndex].AsBEncodedString;
  Result := Result + 'e';
end;

function TNXBEncodeList.Clone: TNXBEncodeValue;
var
  lList: TNXBEncodeList;
  lIndex: Integer;
begin
  lList := TNXBEncodeList.Create;
  try
    for lIndex := 0 to Count - 1 do
      lList.Add(Items[lIndex].Clone);
    Result := lList;
  except
    lList.Free;
    raise;
  end;
end;

constructor TNXBEncodeDictionaryEntry.Create(const AKey: string;
  AValue: TNXBEncodeValue);
begin
  inherited Create;
  FKey := AKey;
  FValue := AValue;
end;

destructor TNXBEncodeDictionaryEntry.Destroy;
begin
  FValue.Free;
  inherited Destroy;
end;

constructor TNXBEncodeDictionary.Create;
begin
  inherited Create;
  FEntries := TList.Create;
end;

destructor TNXBEncodeDictionary.Destroy;
var
  lIndex: Integer;
begin
  for lIndex := 0 to FEntries.Count - 1 do
    TObject(FEntries[lIndex]).Free;
  FEntries.Free;
  inherited Destroy;
end;

function TNXBEncodeDictionary.GetCount: Integer;
begin
  Result := FEntries.Count;
end;

function TNXBEncodeDictionary.GetEntry(AIndex: Integer): TNXBEncodeDictionaryEntry;
begin
  Result := TNXBEncodeDictionaryEntry(FEntries[AIndex]);
end;

procedure TNXBEncodeDictionary.Add(const AKey: string; AValue: TNXBEncodeValue);
begin
  if Assigned(Find(AKey)) then
    raise ENXBEncodeError.CreateFmt('Duplicate bencode dictionary key "%s".',
      [AKey]);
  FEntries.Add(TNXBEncodeDictionaryEntry.Create(AKey, AValue));
end;

function TNXBEncodeDictionary.Find(const AKey: string): TNXBEncodeValue;
var
  lIndex: Integer;
begin
  Result := nil;
  for lIndex := 0 to Count - 1 do
    if Entries[lIndex].Key = AKey then
      Exit(Entries[lIndex].Value);
end;

function TNXBEncodeDictionary.RequireBytes(const AKey: string): string;
var
  lValue: TNXBEncodeValue;
begin
  lValue := Find(AKey);
  if not (lValue is TNXBEncodeBytes) then
    raise ENXBEncodeError.CreateFmt('Missing byte string key "%s".', [AKey]);
  Result := TNXBEncodeBytes(lValue).Value;
end;

function TNXBEncodeDictionary.RequireInteger(const AKey: string): Int64;
var
  lValue: TNXBEncodeValue;
begin
  lValue := Find(AKey);
  if not (lValue is TNXBEncodeInteger) then
    raise ENXBEncodeError.CreateFmt('Missing integer key "%s".', [AKey]);
  Result := TNXBEncodeInteger(lValue).Value;
end;

function TNXBEncodeDictionary.RequireDictionary(
  const AKey: string): TNXBEncodeDictionary;
var
  lValue: TNXBEncodeValue;
begin
  lValue := Find(AKey);
  if not (lValue is TNXBEncodeDictionary) then
    raise ENXBEncodeError.CreateFmt('Missing dictionary key "%s".', [AKey]);
  Result := TNXBEncodeDictionary(lValue);
end;

function TNXBEncodeDictionary.FindList(const AKey: string): TNXBEncodeList;
var
  lValue: TNXBEncodeValue;
begin
  lValue := Find(AKey);
  if lValue is TNXBEncodeList then
    Result := TNXBEncodeList(lValue)
  else
    Result := nil;
end;

function TNXBEncodeDictionary.AsBEncodedString: string;
var
  lIndex: Integer;
  lKey: TNXBEncodeBytes;
begin
  Result := 'd';
  for lIndex := 0 to Count - 1 do
  begin
    lKey := TNXBEncodeBytes.Create(Entries[lIndex].Key);
    try
      Result := Result + lKey.AsBEncodedString + Entries[lIndex].Value.AsBEncodedString;
    finally
      lKey.Free;
    end;
  end;
  Result := Result + 'e';
end;

function TNXBEncodeDictionary.Clone: TNXBEncodeValue;
var
  lDictionary: TNXBEncodeDictionary;
  lIndex: Integer;
begin
  lDictionary := TNXBEncodeDictionary.Create;
  try
    for lIndex := 0 to Count - 1 do
      lDictionary.Add(Entries[lIndex].Key, Entries[lIndex].Value.Clone);
    Result := lDictionary;
  except
    lDictionary.Free;
    raise;
  end;
end;

function TNXBEncodeCodec.AtEnd: Boolean;
begin
  Result := FPosition > Length(FText);
end;

function TNXBEncodeCodec.CurrentChar: Char;
begin
  if AtEnd then
    raise ENXBEncodeError.Create('Unexpected end of bencode text.');
  Result := FText[FPosition];
end;

function TNXBEncodeCodec.ReadDecimalUntil(AEndChar: Char): string;
begin
  Result := '';
  while (not AtEnd) and (CurrentChar <> AEndChar) do
  begin
    Result := Result + CurrentChar;
    Inc(FPosition);
  end;
  if AtEnd then
    raise ENXBEncodeError.Create('Unterminated bencode number.');
  Inc(FPosition);
end;

function TNXBEncodeCodec.ReadInteger: TNXBEncodeInteger;
var
  lText: string;
  lValue: Int64;
begin
  Inc(FPosition);
  lText := ReadDecimalUntil('e');
  if (not NXValidBEncodeIntegerText(lText)) or
    (not TryStrToInt64(lText, lValue)) then
    raise ENXBEncodeError.Create('Invalid bencode integer.');
  Result := TNXBEncodeInteger.Create(lValue);
end;

function TNXBEncodeCodec.ReadBytes: TNXBEncodeBytes;
var
  lLengthText: string;
  lLength: Integer;
begin
  lLengthText := ReadDecimalUntil(':');
  if (not NXValidBEncodeLengthText(lLengthText)) or
    (not TryStrToInt(lLengthText, lLength)) or
    (lLength < 0) then
    raise ENXBEncodeError.Create('Invalid bencode byte string length.');
  if FPosition + lLength - 1 > Length(FText) then
    raise ENXBEncodeError.Create('Bencode byte string exceeds input.');
  Result := TNXBEncodeBytes.Create(Copy(FText, FPosition, lLength));
  Inc(FPosition, lLength);
end;

function TNXBEncodeCodec.ReadList: TNXBEncodeList;
begin
  Inc(FPosition);
  Result := TNXBEncodeList.Create;
  try
    while CurrentChar <> 'e' do
      Result.Add(ReadValue);
    Inc(FPosition);
  except
    Result.Free;
    raise;
  end;
end;

function TNXBEncodeCodec.ReadDictionary: TNXBEncodeDictionary;
var
  lKey: TNXBEncodeBytes;
  lValue: TNXBEncodeValue;
begin
  Inc(FPosition);
  Result := TNXBEncodeDictionary.Create;
  try
    while CurrentChar <> 'e' do
    begin
      lKey := ReadBytes;
      try
        lValue := ReadValue;
        try
          Result.Add(lKey.Value, lValue);
          lValue := nil;
        finally
          lValue.Free;
        end;
      finally
        lKey.Free;
      end;
    end;
    Inc(FPosition);
  except
    Result.Free;
    raise;
  end;
end;

function TNXBEncodeCodec.ReadValue: TNXBEncodeValue;
begin
  case CurrentChar of
    'i':
      Result := ReadInteger;
    'l':
      Result := ReadList;
    'd':
      Result := ReadDictionary;
    '0'..'9':
      Result := ReadBytes;
  else
    raise ENXBEncodeError.CreateFmt('Unexpected bencode marker "%s".',
      [CurrentChar]);
  end;
end;

class function TNXBEncodeCodec.Decode(const AText: string): TNXBEncodeValue;
var
  lCodec: TNXBEncodeCodec;
begin
  lCodec := TNXBEncodeCodec.Create;
  try
    lCodec.FText := AText;
    lCodec.FPosition := 1;
    Result := lCodec.ReadValue;
    try
      if not lCodec.AtEnd then
        raise ENXBEncodeError.Create('Trailing data after bencode value.');
    except
      Result.Free;
      raise;
    end;
  finally
    lCodec.Free;
  end;
end;

class function TNXBEncodeCodec.DecodeDictionary(
  const AText: string): TNXBEncodeDictionary;
var
  lValue: TNXBEncodeValue;
begin
  lValue := Decode(AText);
  if not (lValue is TNXBEncodeDictionary) then
  begin
    lValue.Free;
    raise ENXBEncodeError.Create('Top-level bencode value is not a dictionary.');
  end;
  Result := TNXBEncodeDictionary(lValue);
end;

class function TNXBEncodeCodec.Encode(AValue: TNXBEncodeValue): string;
begin
  if not Assigned(AValue) then
    raise ENXBEncodeError.Create('Cannot encode nil bencode value.');
  Result := AValue.AsBEncodedString;
end;

end.

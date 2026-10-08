(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXXMPPEndpointResolver;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, dnssend, obNXXMPPError, tpNXXMPPTypes;

type
  TNXXMPPEndpointResolver = class
  private
    function QuerySRV(const AName: UTF8String;
      ASecurity: TNXXMPPTransportSecurity;
      out AServiceUnavailable: Boolean): TNXXMPPEndpointArray;
  public
    class function OrderEndpoints(const ACandidates: TNXXMPPEndpointArray;
      ASeed: Cardinal): TNXXMPPEndpointArray; static;
    class function OrderSRVRecords(ARecords: TStrings;
      ASecurity: TNXXMPPTransportSecurity;
      ASeed: Cardinal): TNXXMPPEndpointArray; static;
    function Resolve(const ADomain: UTF8String): TNXXMPPEndpointArray;
  end;

implementation

function NextRandom(var ASeed: Cardinal; AMaximum: Cardinal): Cardinal;
begin
  ASeed := (ASeed * 1664525) + 1013904223;
  if AMaximum = 0 then
    Result := 0
  else
    Result := ASeed mod AMaximum;
end;

function ParseWord(const AValue: string; const AName: string): Word;
var
  lNumber: Integer;
begin
  if not TryStrToInt(AValue, lNumber) or (lNumber < 0) or
    (lNumber > High(Word)) then
    raise ENXXMPPError.Create(xesResolution, 'malformed-srv-record',
      'The SRV ' + AName + ' is invalid.');
  Result := Word(lNumber);
end;

function ParseRecord(const AValue: string;
  ASecurity: TNXXMPPTransportSecurity): TNXXMPPEndpoint;
var
  lParts: TStringList;
begin
  Result.Host := '';
  Result.Port := 0;
  Result.Priority := 0;
  Result.Weight := 0;
  Result.Security := ASecurity;
  lParts := TStringList.Create;
  try
    lParts.StrictDelimiter := True;
    lParts.Delimiter := ',';
    lParts.DelimitedText := AValue;
    if lParts.Count <> 4 then
      raise ENXXMPPError.Create(xesResolution, 'malformed-srv-record',
        'An SRV record must contain priority, weight, port, and target.');
    Result.Priority := ParseWord(lParts[0], 'priority');
    Result.Weight := ParseWord(lParts[1], 'weight');
    Result.Port := ParseWord(lParts[2], 'port');
    Result.Host := lParts[3];
    while (Length(Result.Host) > 0) and
      (Result.Host[Length(Result.Host)] = '.') do
      Delete(Result.Host, Length(Result.Host), 1);
    if (Result.Port = 0) or (Result.Host = '') then
      raise ENXXMPPError.Create(xesResolution, 'malformed-srv-record',
        'An SRV record contains an empty target or zero port.');
  finally
    lParts.Free;
  end;
end;

class function TNXXMPPEndpointResolver.OrderSRVRecords(ARecords: TStrings;
  ASecurity: TNXXMPPTransportSecurity;
  ASeed: Cardinal): TNXXMPPEndpointArray;
var
  lCandidates: TNXXMPPEndpointArray;
  lIndex: Integer;
begin
  Result := nil;
  if not Assigned(ARecords) then
    Exit;
  SetLength(lCandidates, ARecords.Count);
  for lIndex := 0 to ARecords.Count - 1 do
    lCandidates[lIndex] := ParseRecord(ARecords[lIndex], ASecurity);
  Result := OrderEndpoints(lCandidates, ASeed);
end;

class function TNXXMPPEndpointResolver.OrderEndpoints(
  const ACandidates: TNXXMPPEndpointArray;
  ASeed: Cardinal): TNXXMPPEndpointArray;
var
  lCandidates: TNXXMPPEndpointArray;
  lChosen: Integer;
  lCount: Integer;
  lIndex: Integer;
  lMinimumPriority: Integer;
  lRemaining: array of Boolean;
  lRemainingAtPriority: Integer;
  lRoll: Cardinal;
  lTotalWeight: Cardinal;
begin
  Result := nil;
  lCandidates := Copy(ACandidates);
  SetLength(lRemaining, Length(lCandidates));
  for lIndex := 0 to High(lCandidates) do
  begin
    lRemaining[lIndex] := True;
  end;
  SetLength(Result, Length(lCandidates));
  lCount := 0;
  while lCount < Length(lCandidates) do
  begin
    lMinimumPriority := High(Integer);
    for lIndex := 0 to High(lCandidates) do
      if lRemaining[lIndex] and
        (lCandidates[lIndex].Priority < lMinimumPriority) then
        lMinimumPriority := lCandidates[lIndex].Priority;
    lTotalWeight := 0;
    lRemainingAtPriority := 0;
    for lIndex := 0 to High(lCandidates) do
      if lRemaining[lIndex] and
        (lCandidates[lIndex].Priority = lMinimumPriority) then
      begin
        Inc(lTotalWeight, lCandidates[lIndex].Weight);
        Inc(lRemainingAtPriority);
      end;
    lChosen := -1;
    if lTotalWeight = 0 then
    begin
      lRoll := NextRandom(ASeed, lRemainingAtPriority);
      for lIndex := 0 to High(lCandidates) do
        if lRemaining[lIndex] and
          (lCandidates[lIndex].Priority = lMinimumPriority) then
        begin
          if lRoll = 0 then
          begin
            lChosen := lIndex;
            Break;
          end;
          Dec(lRoll);
        end;
    end
    else
    begin
      lRoll := NextRandom(ASeed, lTotalWeight) + 1;
      for lIndex := 0 to High(lCandidates) do
        if lRemaining[lIndex] and
          (lCandidates[lIndex].Priority = lMinimumPriority) then
        begin
          if lRoll <= lCandidates[lIndex].Weight then
          begin
            lChosen := lIndex;
            Break;
          end;
          Dec(lRoll, lCandidates[lIndex].Weight);
        end;
    end;
    if lChosen < 0 then
      raise ENXXMPPError.Create(xesResolution, 'srv-ordering-failure',
        'The SRV candidate set could not be ordered.');
    Result[lCount] := lCandidates[lChosen];
    lRemaining[lChosen] := False;
    Inc(lCount);
  end;
end;

function TNXXMPPEndpointResolver.QuerySRV(const AName: UTF8String;
  ASecurity: TNXXMPPTransportSecurity;
  out AServiceUnavailable: Boolean): TNXXMPPEndpointArray;
var
  lDNS: TDNSSend;
  lRecords: TStringList;
begin
  Result := nil;
  AServiceUnavailable := False;
  lDNS := TDNSSend.Create;
  lRecords := TStringList.Create;
  try
    if lDNS.DNSQuery(AnsiString(AName), QTYPE_SRV, lRecords) then
    begin
      if (lRecords.Count = 1) and
        ((lRecords[0] = '0,0,0,.') or (lRecords[0] = '0,0,0,')) then
      begin
        AServiceUnavailable := True;
        Exit;
      end;
      Result := OrderSRVRecords(lRecords, ASecurity, Cardinal(GetTickCount64));
    end;
  finally
    lRecords.Free;
    lDNS.Free;
  end;
end;

function TNXXMPPEndpointResolver.Resolve(
  const ADomain: UTF8String): TNXXMPPEndpointArray;
var
  lDirect: TNXXMPPEndpointArray;
  lIndex: Integer;
  lDirectUnavailable: Boolean;
  lStartTLS: TNXXMPPEndpointArray;
  lStartTLSUnavailable: Boolean;
  lCombined: TNXXMPPEndpointArray;
begin
  Result := nil;
  if ADomain = '' then
    raise ENXXMPPError.Create(xesResolution, 'empty-service-domain',
      'An XMPP service domain is required.');
  lDirect := QuerySRV('_xmpps-client._tcp.' + ADomain, xtsDirectTLS,
    lDirectUnavailable);
  lStartTLS := QuerySRV('_xmpp-client._tcp.' + ADomain, xtsStartTLS,
    lStartTLSUnavailable);
  if (Length(lDirect) = 0) and (Length(lStartTLS) = 0) then
  begin
    if lStartTLSUnavailable then
      Exit;
    SetLength(Result, 1);
    Result[0].Host := string(ADomain);
    Result[0].Port := 5222;
    Result[0].Security := xtsStartTLS;
    Exit;
  end;
  SetLength(lCombined, Length(lDirect) + Length(lStartTLS));
  for lIndex := 0 to High(lDirect) do
    lCombined[lIndex] := lDirect[lIndex];
  for lIndex := 0 to High(lStartTLS) do
    lCombined[Length(lDirect) + lIndex] := lStartTLS[lIndex];
  Result := OrderEndpoints(lCombined, Cardinal(GetTickCount64));
end;

end.

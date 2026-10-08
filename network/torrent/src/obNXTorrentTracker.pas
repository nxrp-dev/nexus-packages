(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTorrentTracker;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, tpNXTorrent, obNXBEncode;

type
  ENXTorrentTrackerError = class(Exception);

  TNXTorrentPeerAddress = record
    Host: string;
    Port: Integer;
    PeerId: string;
  end;

  TNXTorrentTrackerResponse = class
  private
    FFailureReason: string;
    FInterval: Integer;
    FPeers: array of TNXTorrentPeerAddress;
    function GetPeer(AIndex: Integer): TNXTorrentPeerAddress;
    function GetPeerCount: Integer;
    procedure AddPeer(const AHost: string; APort: Integer; const APeerId: string);
    procedure LoadCompactPeers(const APeers: string);
    procedure LoadDictionaryPeers(APeers: TNXBEncodeList);
  public
    class function Decode(const AText: string): TNXTorrentTrackerResponse;

    property FailureReason: string read FFailureReason;
    property Interval: Integer read FInterval;
    property PeerCount: Integer read GetPeerCount;
    property Peers[AIndex: Integer]: TNXTorrentPeerAddress read GetPeer;
  end;

  TNXTorrentTrackerAnnounce = class
  private
    FDownloaded: Int64;
    FEvent: TNXTorrentTrackerEvent;
    FInfoHash: TNXTorrentHash;
    FLeft: Int64;
    FPeerId: string;
    FPort: Integer;
    FUploaded: Int64;
  public
    function BuildQueryString: string;

    property Downloaded: Int64 read FDownloaded write FDownloaded;
    property Event: TNXTorrentTrackerEvent read FEvent write FEvent;
    property InfoHash: TNXTorrentHash read FInfoHash write FInfoHash;
    property Left: Int64 read FLeft write FLeft;
    property PeerId: string read FPeerId write FPeerId;
    property Port: Integer read FPort write FPort;
    property Uploaded: Int64 read FUploaded write FUploaded;
  end;

  TNXTorrentHTTPTrackerClient = class
  private
    FLastStatusCode: Integer;
    FLastStatusText: string;
    FTimeout: Integer;
    function StreamToString(AStream: TStream): string;
  public
    constructor Create;

    function Announce(const AURL: string;
      ARequest: TNXTorrentTrackerAnnounce): TNXTorrentTrackerResponse;

    property LastStatusCode: Integer read FLastStatusCode;
    property LastStatusText: string read FLastStatusText;
    property Timeout: Integer read FTimeout write FTimeout;
  end;

implementation

uses
  httpsend;

function NXEventName(AEvent: TNXTorrentTrackerEvent): string;
begin
  case AEvent of
    tteStarted:
      Result := 'started';
    tteStopped:
      Result := 'stopped';
    tteCompleted:
      Result := 'completed';
  else
    Result := '';
  end;
end;

function TNXTorrentTrackerResponse.GetPeerCount: Integer;
begin
  Result := Length(FPeers);
end;

function TNXTorrentTrackerResponse.GetPeer(
  AIndex: Integer): TNXTorrentPeerAddress;
begin
  Result := FPeers[AIndex];
end;

procedure TNXTorrentTrackerResponse.AddPeer(const AHost: string; APort: Integer;
  const APeerId: string);
var
  lIndex: Integer;
begin
  lIndex := Length(FPeers);
  SetLength(FPeers, lIndex + 1);
  FPeers[lIndex].Host := AHost;
  FPeers[lIndex].Port := APort;
  FPeers[lIndex].PeerId := APeerId;
end;

procedure TNXTorrentTrackerResponse.LoadCompactPeers(const APeers: string);
var
  lIndex: Integer;
  lHost: string;
  lPort: Integer;
begin
  if Length(APeers) mod 6 <> 0 then
    raise ENXTorrentTrackerError.Create('Compact peer list length is invalid.');
  lIndex := 1;
  while lIndex <= Length(APeers) do
  begin
    lHost := Format('%d.%d.%d.%d', [Ord(APeers[lIndex]),
      Ord(APeers[lIndex + 1]), Ord(APeers[lIndex + 2]),
      Ord(APeers[lIndex + 3])]);
    lPort := (Ord(APeers[lIndex + 4]) shl 8) or Ord(APeers[lIndex + 5]);
    AddPeer(lHost, lPort, '');
    Inc(lIndex, 6);
  end;
end;

procedure TNXTorrentTrackerResponse.LoadDictionaryPeers(APeers: TNXBEncodeList);
var
  lIndex: Integer;
  lPeer: TNXBEncodeDictionary;
  lPeerIdValue: TNXBEncodeValue;
  lPeerId: string;
  lPort: Int64;
begin
  for lIndex := 0 to APeers.Count - 1 do
  begin
    if not (APeers[lIndex] is TNXBEncodeDictionary) then
      raise ENXTorrentTrackerError.Create('Tracker peer is not a dictionary.');
    lPeer := TNXBEncodeDictionary(APeers[lIndex]);
    lPeerId := '';
    lPeerIdValue := lPeer.Find('peer id');
    if lPeerIdValue is TNXBEncodeBytes then
      lPeerId := TNXBEncodeBytes(lPeerIdValue).Value;
    lPort := lPeer.RequireInteger('port');
    if (lPort < 0) or (lPort > 65535) then
      raise ENXTorrentTrackerError.Create('Tracker peer port is outside UInt16 range.');
    AddPeer(lPeer.RequireBytes('ip'), lPort, lPeerId);
  end;
end;

class function TNXTorrentTrackerResponse.Decode(
  const AText: string): TNXTorrentTrackerResponse;
var
  lRoot: TNXBEncodeDictionary;
  lValue: TNXBEncodeValue;
begin
  lRoot := TNXBEncodeCodec.DecodeDictionary(AText);
  try
    Result := TNXTorrentTrackerResponse.Create;
    try
      lValue := lRoot.Find('failure reason');
      if lValue is TNXBEncodeBytes then
        Result.FFailureReason := TNXBEncodeBytes(lValue).Value;
      lValue := lRoot.Find('interval');
      if lValue is TNXBEncodeInteger then
        Result.FInterval := TNXBEncodeInteger(lValue).Value;
      lValue := lRoot.Find('peers');
      if lValue is TNXBEncodeBytes then
        Result.LoadCompactPeers(TNXBEncodeBytes(lValue).Value)
      else if lValue is TNXBEncodeList then
        Result.LoadDictionaryPeers(TNXBEncodeList(lValue));
    except
      Result.Free;
      raise;
    end;
  finally
    lRoot.Free;
  end;
end;

function TNXTorrentTrackerAnnounce.BuildQueryString: string;
var
  lInfoHash: string;
  lEvent: string;
begin
  SetLength(lInfoHash, 20);
  Move(FInfoHash[0], lInfoHash[1], 20);
  Result := 'info_hash=' + NXTorrentURLQueryEscape(lInfoHash) +
    '&peer_id=' + NXTorrentURLQueryEscape(FPeerId) +
    '&port=' + IntToStr(FPort) +
    '&uploaded=' + IntToStr(FUploaded) +
    '&downloaded=' + IntToStr(FDownloaded) +
    '&left=' + IntToStr(FLeft) +
    '&compact=1';
  lEvent := NXEventName(FEvent);
  if lEvent <> '' then
    Result := Result + '&event=' + lEvent;
end;

constructor TNXTorrentHTTPTrackerClient.Create;
begin
  inherited Create;
  FTimeout := 15000;
end;

function TNXTorrentHTTPTrackerClient.StreamToString(AStream: TStream): string;
begin
  SetLength(Result, AStream.Size);
  if AStream.Size = 0 then
    Exit;
  AStream.Position := 0;
  AStream.ReadBuffer(Result[1], AStream.Size);
end;

function TNXTorrentHTTPTrackerClient.Announce(const AURL: string;
  ARequest: TNXTorrentTrackerAnnounce): TNXTorrentTrackerResponse;
var
  lHTTP: THTTPSend;
  lURL: string;
begin
  if not Assigned(ARequest) then
    raise EArgumentNilException.Create('ARequest');

  lURL := AURL;
  if Pos('?', lURL) = 0 then
    lURL := lURL + '?' + ARequest.BuildQueryString
  else
    lURL := lURL + '&' + ARequest.BuildQueryString;

  lHTTP := THTTPSend.Create;
  try
    lHTTP.Timeout := FTimeout;
    lHTTP.UserAgent := 'NexusNetTorrent/0.1';
    if not lHTTP.HTTPMethod('GET', lURL) then
      raise ENXTorrentTrackerError.Create('HTTP tracker announce failed.');
    FLastStatusCode := lHTTP.ResultCode;
    FLastStatusText := lHTTP.ResultString;
    if (FLastStatusCode < 200) or (FLastStatusCode > 299) then
      raise ENXTorrentTrackerError.CreateFmt('HTTP tracker returned %d %s.',
        [FLastStatusCode, FLastStatusText]);
    Result := TNXTorrentTrackerResponse.Decode(StreamToString(lHTTP.Document));
  finally
    lHTTP.Free;
  end;
end;

end.

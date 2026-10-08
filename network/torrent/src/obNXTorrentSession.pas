(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

unit obNXTorrentSession;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, tpNXTorrent, obNXTorrentMetaInfo, obNXTorrentPieceMap,
  obNXTorrentFileStore, obNXTorrentPeerProtocol, obNXTorrentPeerConnection,
  obNXTorrentTracker;

type
  TNXTorrentStatus = class
  private
    FDownloadedBytes: Int64;
    FInfoHashHex: string;
    FName: string;
    FPieceCount: Integer;
    FState: TNXTorrentSessionState;
    FTotalBytes: Int64;
    FVerifiedPieces: Integer;
  public
    property DownloadedBytes: Int64 read FDownloadedBytes write FDownloadedBytes;
    property InfoHashHex: string read FInfoHashHex write FInfoHashHex;
    property Name: string read FName write FName;
    property PieceCount: Integer read FPieceCount write FPieceCount;
    property State: TNXTorrentSessionState read FState write FState;
    property TotalBytes: Int64 read FTotalBytes write FTotalBytes;
    property VerifiedPieces: Integer read FVerifiedPieces write FVerifiedPieces;
  end;

  TNXTorrentSession = class
  private
    FFileStore: TNXTorrentFileStore;
    FMetaInfo: TNXTorrentMetaInfo;
    FPeerId: string;
    FPieceMap: TNXTorrentPieceMap;
    FState: TNXTorrentSessionState;
    function BuildHandshake: TNXTorrentHandshake;
  public
    constructor Create(AMetaInfo: TNXTorrentMetaInfo; const ARootPath: string);
    destructor Destroy; override;

    procedure Start;
    procedure Pause;
    procedure Stop;
    procedure WriteBlock(APieceIndex, ABlockOffset: Integer; const AData: string);
    function AcceptPeer(AListener: TNXTorrentPeerListener): TNXTorrentPeerConnection;
    function AnnounceToTracker(const AURL: string; APort: Integer): TNXTorrentTrackerResponse;
    function ConnectToPeer(const AHost: string; APort: Integer): TNXTorrentPeerConnection;
    function VerifyPiece(APieceIndex: Integer): Boolean;
    function Status: TNXTorrentStatus;

    property FileStore: TNXTorrentFileStore read FFileStore;
    property MetaInfo: TNXTorrentMetaInfo read FMetaInfo;
    property PeerId: string read FPeerId write FPeerId;
    property PieceMap: TNXTorrentPieceMap read FPieceMap;
    property State: TNXTorrentSessionState read FState;
  end;

implementation

constructor TNXTorrentSession.Create(AMetaInfo: TNXTorrentMetaInfo;
  const ARootPath: string);
begin
  inherited Create;
  if not Assigned(AMetaInfo) then
    raise EArgumentNilException.Create('AMetaInfo');
  FMetaInfo := AMetaInfo;
  FPieceMap := TNXTorrentPieceMap.Create(FMetaInfo, False);
  FFileStore := TNXTorrentFileStore.Create(FPieceMap, ARootPath);
  FPeerId := '-NX0001-000000000001';
  FState := tssStopped;
end;

destructor TNXTorrentSession.Destroy;
begin
  FFileStore.Free;
  FPieceMap.Free;
  FMetaInfo.Free;
  inherited Destroy;
end;

procedure TNXTorrentSession.Start;
begin
  FFileStore.PrepareFiles;
  FState := tssRunning;
end;

procedure TNXTorrentSession.Pause;
begin
  if FState = tssRunning then
    FState := tssPaused;
end;

procedure TNXTorrentSession.Stop;
begin
  FState := tssStopped;
end;

procedure TNXTorrentSession.WriteBlock(APieceIndex, ABlockOffset: Integer;
  const AData: string);
begin
  if FState = tssStopped then
    Start;
  FFileStore.WriteBlock(APieceIndex, ABlockOffset, AData);
end;

function TNXTorrentSession.BuildHandshake: TNXTorrentHandshake;
begin
  Result := TNXTorrentHandshake.Create;
  try
    Result.InfoHash := FMetaInfo.InfoHash;
    Result.PeerId := FPeerId;
  except
    Result.Free;
    raise;
  end;
end;

function TNXTorrentSession.ConnectToPeer(const AHost: string;
  APort: Integer): TNXTorrentPeerConnection;
var
  lHandshake: TNXTorrentHandshake;
  lReply: TNXTorrentHandshake;
begin
  Result := TNXTorrentPeerConnection.Create;
  try
    Result.Connect(AHost, APort);
    lHandshake := BuildHandshake;
    try
      Result.SendHandshake(lHandshake);
    finally
      lHandshake.Free;
    end;
    lReply := Result.ReceiveHandshake;
    try
      if not NXTorrentHashEquals(FMetaInfo.InfoHash, lReply.InfoHash) then
        raise ENXTorrentPeerConnectionError.Create(
          'Peer handshake returned a different torrent info hash.');
    finally
      lReply.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TNXTorrentSession.AcceptPeer(
  AListener: TNXTorrentPeerListener): TNXTorrentPeerConnection;
var
  lHandshake: TNXTorrentHandshake;
  lReply: TNXTorrentHandshake;
begin
  if not Assigned(AListener) then
    raise EArgumentNilException.Create('AListener');
  Result := AListener.Accept;
  try
    lHandshake := Result.ReceiveHandshake;
    try
      if not NXTorrentHashEquals(FMetaInfo.InfoHash, lHandshake.InfoHash) then
        raise ENXTorrentPeerConnectionError.Create(
          'Inbound peer requested a different torrent info hash.');
      lReply := BuildHandshake;
      try
        Result.SendHandshake(lReply);
      finally
        lReply.Free;
      end;
    finally
      lHandshake.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TNXTorrentSession.AnnounceToTracker(const AURL: string;
  APort: Integer): TNXTorrentTrackerResponse;
var
  lAnnounce: TNXTorrentTrackerAnnounce;
  lClient: TNXTorrentHTTPTrackerClient;
begin
  lAnnounce := TNXTorrentTrackerAnnounce.Create;
  lClient := TNXTorrentHTTPTrackerClient.Create;
  try
    lAnnounce.InfoHash := FMetaInfo.InfoHash;
    lAnnounce.PeerId := FPeerId;
    lAnnounce.Port := APort;
    lAnnounce.Uploaded := 0;
    lAnnounce.Downloaded := FFileStore.VerifiedCount * FMetaInfo.PieceLength;
    if lAnnounce.Downloaded > FPieceMap.TotalLength then
      lAnnounce.Downloaded := FPieceMap.TotalLength;
    lAnnounce.Left := FPieceMap.TotalLength - lAnnounce.Downloaded;
    if FState = tssComplete then
      lAnnounce.Event := tteCompleted
    else
      lAnnounce.Event := tteStarted;
    Result := lClient.Announce(AURL, lAnnounce);
  finally
    lClient.Free;
    lAnnounce.Free;
  end;
end;

function TNXTorrentSession.VerifyPiece(APieceIndex: Integer): Boolean;
begin
  Result := FFileStore.VerifyPiece(APieceIndex);
  if FFileStore.VerifiedCount = FPieceMap.PieceCount then
    FState := tssComplete;
end;

function TNXTorrentSession.Status: TNXTorrentStatus;
begin
  Result := TNXTorrentStatus.Create;
  Result.Name := FMetaInfo.Name;
  Result.InfoHashHex := FMetaInfo.InfoHashHex;
  Result.PieceCount := FPieceMap.PieceCount;
  Result.VerifiedPieces := FFileStore.VerifiedCount;
  Result.TotalBytes := FPieceMap.TotalLength;
  Result.DownloadedBytes := Int64(FFileStore.VerifiedCount) * FMetaInfo.PieceLength;
  if Result.DownloadedBytes > Result.TotalBytes then
    Result.DownloadedBytes := Result.TotalBytes;
  Result.State := FState;
end;

end.

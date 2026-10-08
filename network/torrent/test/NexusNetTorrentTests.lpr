(*
  Copyright (c) 2026 Kevin Collins.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  This Source Code Form is "Incompatible With Secondary Licenses",
  as defined by the Mozilla Public License, v. 2.0.

  SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
*)

program NexusNetTorrentTests;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, sha1, tpNXTorrent, obNXBEncode, obNXTorrentMetaInfo,
  obNXTorrentPieceMap, obNXTorrentFileStore, obNXTorrentPeerProtocol,
  obNXTorrentPeer, obNXTorrentPeerConnection, obNXTorrentTracker,
  obNXTorrentSession, obNXTorrentService;

type
  TNXTestProcedure = procedure;

  TNXTorrentHandshakeServerThread = class(TThread)
  private
    FErrorMessage: string;
    FInfoHash: TNXTorrentHash;
    FPeerId: string;
    FPort: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(APort: Integer; const AInfoHash: TNXTorrentHash;
      const APeerId: string);

    property ErrorMessage: string read FErrorMessage;
  end;

procedure AssertTrue(AValue: Boolean; const AMessage: string);
begin
  if not AValue then
    raise Exception.Create(AMessage);
end;

procedure AssertFalse(AValue: Boolean; const AMessage: string);
begin
  if AValue then
    raise Exception.Create(AMessage);
end;

procedure AssertEquals(const AExpected, AActual, AMessage: string); overload;
begin
  if AExpected <> AActual then
    raise Exception.CreateFmt('%s Expected "%s" but got "%s".',
      [AMessage, AExpected, AActual]);
end;

procedure AssertEquals(AExpected, AActual: Integer; const AMessage: string); overload;
begin
  if AExpected <> AActual then
    raise Exception.CreateFmt('%s Expected %d but got %d.',
      [AMessage, AExpected, AActual]);
end;

procedure AssertRaises(AExceptionClass: ExceptClass; AProcedure: TNXTestProcedure;
  const AMessage: string);
begin
  try
    AProcedure;
  except
    on E: Exception do
    begin
      if E.ClassType.InheritsFrom(AExceptionClass) then
        Exit;
      raise Exception.CreateFmt('%s Expected %s but got %s: %s.',
        [AMessage, AExceptionClass.ClassName, E.ClassName, E.Message]);
    end;
  end;
  raise Exception.Create(AMessage + ' Expected exception was not raised.');
end;

function UInt32Bytes(AValue: Cardinal): string;
begin
  SetLength(Result, 4);
  Result[1] := Chr((AValue shr 24) and $ff);
  Result[2] := Chr((AValue shr 16) and $ff);
  Result[3] := Chr((AValue shr 8) and $ff);
  Result[4] := Chr(AValue and $ff);
end;

function PeerPacket(AId: Byte; const APayload: string): string;
begin
  Result := UInt32Bytes(Length(APayload) + 1) + Chr(AId) + APayload;
end;

function HashBytes(const AText: string): string;
var
  lDigest: TSHA1Digest;
  lIndex: Integer;
begin
  lDigest := SHA1String(AText);
  SetLength(Result, 20);
  for lIndex := 0 to 19 do
    Result[lIndex + 1] := Chr(lDigest[lIndex]);
end;

function HashForText(const AText: string): TNXTorrentHash;
var
  lDigest: TSHA1Digest;
begin
  lDigest := SHA1String(AText);
  Move(lDigest[0], Result[0], SizeOf(Result));
end;

constructor TNXTorrentHandshakeServerThread.Create(APort: Integer;
  const AInfoHash: TNXTorrentHash; const APeerId: string);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FPort := APort;
  FInfoHash := AInfoHash;
  FPeerId := APeerId;
end;

procedure TNXTorrentHandshakeServerThread.Execute;
var
  lListener: TNXTorrentPeerListener;
  lConnection: TNXTorrentPeerConnection;
  lHandshake: TNXTorrentHandshake;
  lReply: TNXTorrentHandshake;
begin
  try
    lListener := TNXTorrentPeerListener.Create;
    try
      lListener.Open('127.0.0.1', FPort);
      lConnection := lListener.Accept;
      try
        lHandshake := lConnection.ReceiveHandshake;
        try
          if not NXTorrentHashEquals(FInfoHash, lHandshake.InfoHash) then
            raise Exception.Create('Server received unexpected info hash.');
          lReply := TNXTorrentHandshake.Create;
          try
            lReply.InfoHash := FInfoHash;
            lReply.PeerId := FPeerId;
            lConnection.SendHandshake(lReply);
          finally
            lReply.Free;
          end;
        finally
          lHandshake.Free;
        end;
      finally
        lConnection.Free;
      end;
    finally
      lListener.Free;
    end;
  except
    on E: Exception do
      FErrorMessage := E.Message;
  end;
end;

procedure TestBEncodeRoundTrip;
var
  lValue: TNXBEncodeValue;
begin
  lValue := TNXBEncodeCodec.Decode('d3:cow3:moo4:spam4:eggse');
  try
    AssertEquals('d3:cow3:moo4:spam4:eggse', lValue.AsBEncodedString,
      'Bencode dictionary should round trip.');
  finally
    lValue.Free;
  end;
end;

procedure TestMetaInfoSingleFile;
var
  lMeta: TNXTorrentMetaInfo;
  lLoaded: TNXTorrentMetaInfo;
  lText: string;
begin
  lMeta := TNXTorrentMetaInfo.CreateSingleFile(
    'http://tracker.example/announce', 'hello.txt', 11, 16384,
    HashBytes('hello world'));
  try
    lText := lMeta.AsBEncodedString;
    lLoaded := TNXTorrentMetaInfo.LoadFromBEncodedString(lText);
    try
      AssertEquals('hello.txt', lLoaded.Name, 'Torrent name should load.');
      AssertEquals(1, lLoaded.Files.Count, 'Single-file torrent should have one file.');
      AssertEquals(lMeta.InfoHashHex, lLoaded.InfoHashHex,
        'Info hash should survive encode/load.');
    finally
      lLoaded.Free;
    end;
  finally
    lMeta.Free;
  end;
end;

procedure TestPieceMap;
var
  lMeta: TNXTorrentMetaInfo;
  lMap: TNXTorrentPieceMap;
begin
  lMeta := TNXTorrentMetaInfo.CreateSingleFile('tracker', 'data.bin', 10, 4,
    HashBytes('abcd') + HashBytes('efgh') + HashBytes('ij'));
  lMap := TNXTorrentPieceMap.Create(lMeta, True);
  try
    AssertEquals(3, lMap.PieceCount, 'Piece count should include tail piece.');
    AssertEquals(4, lMap.PieceLength(0), 'First piece length.');
    AssertEquals(2, lMap.PieceLength(2), 'Tail piece length.');
    AssertEquals(2, lMap.PieceIndexForOffset(9), 'Offset should map to tail piece.');
  finally
    lMap.Free;
  end;
end;

procedure TestFileStoreVerify;
var
  lRoot: string;
  lMeta: TNXTorrentMetaInfo;
  lMap: TNXTorrentPieceMap;
  lStore: TNXTorrentFileStore;
begin
  lRoot := IncludeTrailingPathDelimiter(GetTempDir(False)) + 'nexusnet-torrent-test';
  lMeta := TNXTorrentMetaInfo.CreateSingleFile('tracker', 'payload.bin', 11, 11,
    HashBytes('hello world'));
  lMap := TNXTorrentPieceMap.Create(lMeta, True);
  lStore := TNXTorrentFileStore.Create(lMap, lRoot);
  try
    lStore.WriteBlock(0, 0, 'hello world');
    AssertTrue(lStore.VerifyPiece(0), 'Written piece should verify.');
    AssertEquals(1, lStore.VerifiedCount, 'Verified count should update.');
  finally
    lStore.Free;
    lMap.Free;
  end;
end;

procedure TestPeerMessages;
var
  lMessage: TNXTorrentPeerMessage;
  lDecoded: TNXTorrentPeerMessage;
  lUsed: Integer;
  lWire: string;
begin
  lMessage := TNXTorrentPeerMessage.Create(tpmRequest);
  try
    lMessage.Index := 2;
    lMessage.Offset := 16;
    lMessage.Length := 1024;
    lWire := lMessage.Encode;
    lDecoded := TNXTorrentPeerMessageCodec.Decode(lWire, lUsed);
    try
      AssertEquals(17, lUsed, 'Request message size.');
      AssertEquals(2, lDecoded.Index, 'Request index.');
      AssertEquals(16, lDecoded.Offset, 'Request offset.');
      AssertEquals(1024, lDecoded.Length, 'Request length.');
    finally
      lDecoded.Free;
    end;
  finally
    lMessage.Free;
  end;
end;

procedure DecodeShortHave;
var
  lUsed: Integer;
begin
  TNXTorrentPeerMessageCodec.Decode(PeerPacket(4, ''), lUsed);
end;

procedure DecodeShortRequest;
var
  lUsed: Integer;
begin
  TNXTorrentPeerMessageCodec.Decode(PeerPacket(6, #0#0#0#1), lUsed);
end;

procedure DecodeShortCancel;
var
  lUsed: Integer;
begin
  TNXTorrentPeerMessageCodec.Decode(PeerPacket(8, #0#0#0#1), lUsed);
end;

procedure DecodeShortPort;
var
  lUsed: Integer;
begin
  TNXTorrentPeerMessageCodec.Decode(PeerPacket(9, #$1A), lUsed);
end;

procedure DecodeExtraChokePayload;
var
  lUsed: Integer;
begin
  TNXTorrentPeerMessageCodec.Decode(PeerPacket(0, #0), lUsed);
end;

procedure DecodeOverflowLengthPrefix;
var
  lUsed: Integer;
begin
  TNXTorrentPeerMessageCodec.Decode(#$FF#$FF#$FF#$FF, lUsed);
end;

procedure EncodeZeroRequest;
var
  lMessage: TNXTorrentPeerMessage;
begin
  lMessage := TNXTorrentPeerMessage.Create(tpmRequest);
  try
    lMessage.Index := 0;
    lMessage.Offset := 0;
    lMessage.Length := 0;
    lMessage.Encode;
  finally
    lMessage.Free;
  end;
end;

procedure EncodeNegativeRequestOffset;
var
  lMessage: TNXTorrentPeerMessage;
begin
  lMessage := TNXTorrentPeerMessage.Create(tpmRequest);
  try
    lMessage.Index := 0;
    lMessage.Offset := -1;
    lMessage.Length := 1;
    lMessage.Encode;
  finally
    lMessage.Free;
  end;
end;

procedure TestPeerMessageHardening;
var
  lDecoded: TNXTorrentPeerMessage;
  lMessage: TNXTorrentPeerMessage;
  lUsed: Integer;
begin
  lMessage := TNXTorrentPeerMessage.Create(tpmPort);
  try
    lMessage.Offset := 6881;
    AssertEquals(#0#0#0#3 + #9 + #$1A#$E1, lMessage.Encode,
      'Port message should encode as ID plus UInt16.');
  finally
    lMessage.Free;
  end;

  lDecoded := TNXTorrentPeerMessageCodec.Decode(#0#0#0#3 + #9 + #$1A#$E1,
    lUsed);
  try
    AssertEquals(7, lUsed, 'Port message wire size.');
    AssertEquals(6881, lDecoded.Offset, 'Port message should decode UInt16.');
  finally
    lDecoded.Free;
  end;

  AssertRaises(ENXTorrentPeerProtocolError, @DecodeShortHave,
    'Short have message should fail.');
  AssertRaises(ENXTorrentPeerProtocolError, @DecodeShortRequest,
    'Short request message should fail.');
  AssertRaises(ENXTorrentPeerProtocolError, @DecodeShortCancel,
    'Short cancel message should fail.');
  AssertRaises(ENXTorrentPeerProtocolError, @DecodeShortPort,
    'Short port message should fail.');
  AssertRaises(ENXTorrentPeerProtocolError, @DecodeExtraChokePayload,
    'Choke message with extra payload should fail.');
  AssertRaises(ENXTorrentPeerProtocolError, @DecodeOverflowLengthPrefix,
    'Overflow-sized message length prefix should fail.');
  AssertRaises(ENXTorrentPeerProtocolError, @EncodeZeroRequest,
    'Zero-length request should fail.');
  AssertRaises(ENXTorrentPeerProtocolError, @EncodeNegativeRequestOffset,
    'Negative request offset should fail.');
end;

procedure ValidateOversizedFrame;
begin
  TNXTorrentPeerConnection.ValidatePeerMessageLength(
    NXTorrentMaxPeerMessageBytes + 1);
end;

procedure TestPeerConnectionFrameLimit;
begin
  AssertRaises(ENXTorrentPeerConnectionError, @ValidateOversizedFrame,
    'Oversized peer frame should fail before body read.');
end;

procedure TestTrackerResponse;
var
  lResponse: TNXTorrentTrackerResponse;
begin
  lResponse := TNXTorrentTrackerResponse.Decode(
    'd8:intervali1800e5:peers6:' + #127#0#0#1#$1A#$E1 + 'e');
  try
    AssertEquals(1800, lResponse.Interval, 'Tracker interval.');
    AssertEquals(1, lResponse.PeerCount, 'Tracker peer count.');
    AssertEquals('127.0.0.1', lResponse.Peers[0].Host, 'Compact peer host.');
    AssertEquals(6881, lResponse.Peers[0].Port, 'Compact peer port.');
  finally
    lResponse.Free;
  end;
end;

procedure DecodeMalformedTrackerPeerList;
begin
  TNXTorrentTrackerResponse.Decode('d5:peers5:abcdee');
end;

procedure DecodeInvalidTrackerPort;
begin
  TNXTorrentTrackerResponse.Decode(
    'd5:peersld2:ip9:127.0.0.14:porti70000eeee');
end;

procedure TestTrackerHardening;
begin
  AssertRaises(ENXTorrentTrackerError, @DecodeMalformedTrackerPeerList,
    'Malformed compact tracker peer list should fail.');
  AssertRaises(ENXTorrentTrackerError, @DecodeInvalidTrackerPort,
    'Invalid dictionary tracker peer port should fail.');
end;

procedure DecodeLeadingZeroInteger;
begin
  TNXBEncodeCodec.Decode('i03e').Free;
end;

procedure DecodeNegativeZeroInteger;
begin
  TNXBEncodeCodec.Decode('i-0e').Free;
end;

procedure DecodeEmptyInteger;
begin
  TNXBEncodeCodec.Decode('ie').Free;
end;

procedure DecodeDuplicateDictionaryKey;
begin
  TNXBEncodeCodec.Decode('d1:a1:x1:a1:ye').Free;
end;

procedure LoadBadPiecesMetaInfo;
begin
  TNXTorrentMetaInfo.LoadFromBEncodedString(
    'd8:announce7:tracker4:infod6:lengthi1e4:name4:test12:piece lengthi1e6:pieces3:abcee').Free;
end;

procedure TestBEncodeAndMetaInfoHardening;
begin
  AssertRaises(ENXBEncodeError, @DecodeLeadingZeroInteger,
    'Leading-zero integer should fail.');
  AssertRaises(ENXBEncodeError, @DecodeNegativeZeroInteger,
    'Negative zero integer should fail.');
  AssertRaises(ENXBEncodeError, @DecodeEmptyInteger,
    'Empty integer should fail.');
  AssertRaises(ENXBEncodeError, @DecodeDuplicateDictionaryKey,
    'Duplicate dictionary key should fail.');
  AssertRaises(ENXTorrentMetaInfoError, @LoadBadPiecesMetaInfo,
    'Invalid pieces length should fail.');
end;

procedure TestPeerState;
var
  lPeer: TNXTorrentPeer;
  lMessage: TNXTorrentPeerMessage;
begin
  lPeer := TNXTorrentPeer.Create('peer', 10);
  try
    lMessage := TNXTorrentPeerMessage.Create(tpmBitfield);
    try
      lMessage.Payload := #$A0;
      lPeer.ApplyMessage(lMessage);
      AssertTrue(lPeer.HasPiece(0), 'Bitfield should set piece 0.');
      AssertFalse(lPeer.HasPiece(1), 'Bitfield should leave piece 1 missing.');
      AssertTrue(lPeer.HasPiece(2), 'Bitfield should set piece 2.');
    finally
      lMessage.Free;
    end;

    lMessage := TNXTorrentPeerMessage.Create(tpmHave);
    try
      lMessage.Index := 1;
      lPeer.ApplyMessage(lMessage);
      AssertTrue(lPeer.HasPiece(1), 'Have message should set piece.');
    finally
      lMessage.Free;
    end;

    AssertEquals(3, lPeer.CompletePieceCount, 'Peer piece count should update.');
  finally
    lPeer.Free;
  end;
end;

procedure WriteBeyondFinalPiece;
var
  lRoot: string;
  lMeta: TNXTorrentMetaInfo;
  lMap: TNXTorrentPieceMap;
  lStore: TNXTorrentFileStore;
begin
  lRoot := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    'nexusnet-torrent-range-test';
  lMeta := TNXTorrentMetaInfo.CreateSingleFile('tracker', 'payload.bin', 5, 4,
    HashBytes('abcd') + HashBytes('e'));
  lMap := TNXTorrentPieceMap.Create(lMeta, True);
  lStore := TNXTorrentFileStore.Create(lMap, lRoot);
  try
    lStore.WriteBlock(1, 0, 'ee');
  finally
    lStore.Free;
    lMap.Free;
  end;
end;

procedure PrepareUnsafeTraversalPath;
var
  lRoot: string;
  lMeta: TNXTorrentMetaInfo;
  lMap: TNXTorrentPieceMap;
  lStore: TNXTorrentFileStore;
begin
  lRoot := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    'nexusnet-torrent-path-test';
  lMeta := TNXTorrentMetaInfo.Create;
  lMeta.Announce := 'tracker';
  lMeta.Name := 'bad';
  lMeta.PieceLength := 1;
  lMeta.Pieces := HashBytes('x');
  lMeta.Files.Add('..\evil.bin', 1);
  lMap := TNXTorrentPieceMap.Create(lMeta, True);
  lStore := TNXTorrentFileStore.Create(lMap, lRoot);
  try
    lStore.PrepareFiles;
  finally
    lStore.Free;
    lMap.Free;
  end;
end;

procedure PrepareUnsafeAbsolutePath;
var
  lRoot: string;
  lMeta: TNXTorrentMetaInfo;
  lMap: TNXTorrentPieceMap;
  lStore: TNXTorrentFileStore;
begin
  lRoot := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    'nexusnet-torrent-path-test';
  lMeta := TNXTorrentMetaInfo.Create;
  lMeta.Announce := 'tracker';
  lMeta.Name := 'bad';
  lMeta.PieceLength := 1;
  lMeta.Pieces := HashBytes('x');
  lMeta.Files.Add('C:\temp\evil.bin', 1);
  lMap := TNXTorrentPieceMap.Create(lMeta, True);
  lStore := TNXTorrentFileStore.Create(lMap, lRoot);
  try
    lStore.PrepareFiles;
  finally
    lStore.Free;
    lMap.Free;
  end;
end;

procedure PrepareUnsafeRootedPath;
var
  lRoot: string;
  lMeta: TNXTorrentMetaInfo;
  lMap: TNXTorrentPieceMap;
  lStore: TNXTorrentFileStore;
begin
  lRoot := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    'nexusnet-torrent-path-test';
  lMeta := TNXTorrentMetaInfo.Create;
  lMeta.Announce := 'tracker';
  lMeta.Name := 'bad';
  lMeta.PieceLength := 1;
  lMeta.Pieces := HashBytes('x');
  lMeta.Files.Add('\temp\evil.bin', 1);
  lMap := TNXTorrentPieceMap.Create(lMeta, True);
  lStore := TNXTorrentFileStore.Create(lMap, lRoot);
  try
    lStore.PrepareFiles;
  finally
    lStore.Free;
    lMap.Free;
  end;
end;

procedure PrepareUnsafeRelativeDrivePath;
var
  lRoot: string;
  lMeta: TNXTorrentMetaInfo;
  lMap: TNXTorrentPieceMap;
  lStore: TNXTorrentFileStore;
begin
  lRoot := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    'nexusnet-torrent-path-test';
  lMeta := TNXTorrentMetaInfo.Create;
  lMeta.Announce := 'tracker';
  lMeta.Name := 'bad';
  lMeta.PieceLength := 1;
  lMeta.Pieces := HashBytes('x');
  lMeta.Files.Add('C:evil.bin', 1);
  lMap := TNXTorrentPieceMap.Create(lMeta, True);
  lStore := TNXTorrentFileStore.Create(lMap, lRoot);
  try
    lStore.PrepareFiles;
  finally
    lStore.Free;
    lMap.Free;
  end;
end;

procedure PrepareUnsafeColonSegmentPath;
var
  lRoot: string;
  lMeta: TNXTorrentMetaInfo;
  lMap: TNXTorrentPieceMap;
  lStore: TNXTorrentFileStore;
begin
  lRoot := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    'nexusnet-torrent-path-test';
  lMeta := TNXTorrentMetaInfo.Create;
  lMeta.Announce := 'tracker';
  lMeta.Name := 'bad';
  lMeta.PieceLength := 1;
  lMeta.Pieces := HashBytes('x');
  lMeta.Files.Add('subdir:name\evil.bin', 1);
  lMap := TNXTorrentPieceMap.Create(lMeta, True);
  lStore := TNXTorrentFileStore.Create(lMap, lRoot);
  try
    lStore.PrepareFiles;
  finally
    lStore.Free;
    lMap.Free;
  end;
end;

procedure PrepareUnsafeEmptySegmentPath;
var
  lRoot: string;
  lMeta: TNXTorrentMetaInfo;
  lMap: TNXTorrentPieceMap;
  lStore: TNXTorrentFileStore;
begin
  lRoot := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    'nexusnet-torrent-path-test';
  lMeta := TNXTorrentMetaInfo.Create;
  lMeta.Announce := 'tracker';
  lMeta.Name := 'bad';
  lMeta.PieceLength := 1;
  lMeta.Pieces := HashBytes('x');
  lMeta.Files.Add('subdir\\evil.bin', 1);
  lMap := TNXTorrentPieceMap.Create(lMeta, True);
  lStore := TNXTorrentFileStore.Create(lMap, lRoot);
  try
    lStore.PrepareFiles;
  finally
    lStore.Free;
    lMap.Free;
  end;
end;

procedure TestFileStoreHardening;
begin
  AssertRaises(ERangeError, @WriteBeyondFinalPiece,
    'Write beyond final piece should fail.');
  AssertRaises(ENXTorrentFileStoreError, @PrepareUnsafeTraversalPath,
    'Traversal path should fail.');
  AssertRaises(ENXTorrentFileStoreError, @PrepareUnsafeAbsolutePath,
    'Drive-qualified absolute path should fail.');
  AssertRaises(ENXTorrentFileStoreError, @PrepareUnsafeRootedPath,
    'Rooted absolute path should fail.');
  AssertRaises(ENXTorrentFileStoreError, @PrepareUnsafeRelativeDrivePath,
    'Relative drive-qualified path should fail.');
  AssertRaises(ENXTorrentFileStoreError, @PrepareUnsafeColonSegmentPath,
    'Colon path segment should fail.');
  AssertRaises(ENXTorrentFileStoreError, @PrepareUnsafeEmptySegmentPath,
    'Empty path segment should fail.');
end;

procedure TestSynapsePeerHandshake;
const
  cPort = 49197;
var
  lConnection: TNXTorrentPeerConnection;
  lHandshake: TNXTorrentHandshake;
  lInfoHash: TNXTorrentHash;
  lReply: TNXTorrentHandshake;
  lServer: TNXTorrentHandshakeServerThread;
begin
  lInfoHash := HashForText('socket-test');
  lServer := TNXTorrentHandshakeServerThread.Create(cPort, lInfoHash,
    '-NX0001-server-peer!');
  try
    lServer.Start;
    Sleep(200);

    lConnection := TNXTorrentPeerConnection.Create;
    try
      lConnection.Timeout := 5000;
      lConnection.Connect('127.0.0.1', cPort);
      lHandshake := TNXTorrentHandshake.Create;
      try
        lHandshake.InfoHash := lInfoHash;
        lHandshake.PeerId := '-NX0001-client-peer!';
        lConnection.SendHandshake(lHandshake);
      finally
        lHandshake.Free;
      end;

      lReply := lConnection.ReceiveHandshake;
      try
        AssertEquals('-NX0001-server-peer!', lReply.PeerId,
          'Peer socket should exchange handshake.');
        AssertTrue(NXTorrentHashEquals(lInfoHash, lReply.InfoHash),
          'Peer socket should preserve info hash.');
      finally
        lReply.Free;
      end;
    finally
      lConnection.Free;
    end;

    lServer.WaitFor;
    AssertEquals('', lServer.ErrorMessage, 'Peer server thread should not fail.');
  finally
    lServer.Free;
  end;
end;

procedure TestServiceStatus;
var
  lRoot: string;
  lService: TNXTorrentService;
  lSession: TNXTorrentSession;
  lStatus: TNXTorrentStatus;
begin
  lRoot := IncludeTrailingPathDelimiter(GetTempDir(False)) + 'nexusnet-torrent-service-test';
  lService := TNXTorrentService.Create;
  try
    lSession := lService.AddMetaInfo(TNXTorrentMetaInfo.CreateSingleFile(
      'tracker', 'payload.bin', 5, 5, HashBytes('abcde')), lRoot);
    lSession.Start;
    lSession.WriteBlock(0, 0, 'abcde');
    AssertTrue(lSession.VerifyPiece(0), 'Service session piece should verify.');
    lStatus := lSession.Status;
    try
      AssertEquals(1, lStatus.VerifiedPieces, 'Status verified pieces.');
      AssertTrue(lStatus.State = tssComplete, 'Status should be complete.');
    finally
      lStatus.Free;
    end;
  finally
    lService.Free;
  end;
end;

begin
  TestBEncodeRoundTrip;
  TestMetaInfoSingleFile;
  TestPieceMap;
  TestFileStoreVerify;
  TestPeerMessages;
  TestPeerMessageHardening;
  TestPeerConnectionFrameLimit;
  TestTrackerResponse;
  TestTrackerHardening;
  TestBEncodeAndMetaInfoHardening;
  TestPeerState;
  TestFileStoreHardening;
  TestSynapsePeerHandshake;
  TestServiceStatus;
  WriteLn('NexusNet torrent tests passed.');
end.

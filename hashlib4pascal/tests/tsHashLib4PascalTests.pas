// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit tsHashLib4PascalTests;
{$mode objfpc}{$H+}
interface
uses obNXTestRegistry;
procedure RegisterHashLibTests(ARegistry: TNXTestRegistry);
implementation
uses Classes, SysUtils, HlpHashFactory, HlpIHash, HlpHashLibTypes,
  obNXTestContext, obNXTestSuite;

// Known-answer/API coverage adapted from the pinned upstream HashLibTestBase,
// CryptoTests and CRCTests. Upstream: Ugochukwu Mmaduekwe/contributors, MIT.
// Original MIT notice is preserved in ../external/hashlib4pascal/LICENSE.
procedure CheckHash(AContext: TNXTestContext; const AHash: IHash;
  const AData: RawByteString; const AExpected: string);
var
  lBytes: THashLibByteArray;
  lStream: TMemoryStream;
  lClone: IHash;
  lSplit: Integer;
  lFileName: string;
  lFile: TFileStream;
  lByte: Byte;
begin
  SetLength(lBytes, Length(AData));
  if AData <> '' then Move(AData[1], lBytes[0], Length(AData));
  AContext.AssertEquals(AExpected, AHash.ComputeBytes(lBytes).ToString(False), 'Bytes');
  lByte := 0;
  if AData = '' then
    AContext.AssertEquals(AExpected, AHash.ComputeUntyped(lByte, 0).ToString(False), 'Empty untyped')
  else
    AContext.AssertEquals(AExpected, AHash.ComputeUntyped(AData[1], Length(AData)).ToString(False), 'Untyped');
  lFileName := GetTempFileName(GetTempDir(False), 'nxh');
  try
    lFile := TFileStream.Create(lFileName, fmCreate);
    try
      if Length(lBytes) > 0 then lFile.WriteBuffer(lBytes[0], Length(lBytes));
    finally lFile.Free; end;
    AContext.AssertEquals(AExpected, AHash.ComputeFile(lFileName).ToString(False), 'File');
  finally DeleteFile(lFileName); end;
  lStream := TMemoryStream.Create;
  try
    if AData <> '' then lStream.WriteBuffer(AData[1], Length(AData));
    lStream.Position := 0;
    AContext.AssertEquals(AExpected, AHash.ComputeStream(lStream).ToString(False), 'Stream');
  finally
    lStream.Free;
  end;
  AHash.Initialize;
  lSplit := Length(lBytes) div 2;
  AHash.TransformBytes(lBytes, 0, lSplit);
  lClone := AHash.Clone;
  AHash.TransformBytes(lBytes, lSplit, Length(lBytes) - lSplit);
  lClone.TransformBytes(lBytes, lSplit, Length(lBytes) - lSplit);
  AContext.AssertEquals(AExpected, AHash.TransformFinal.ToString(False), 'Incremental');
  AContext.AssertEquals(AExpected, lClone.TransformFinal.ToString(False), 'Clone');
  AContext.AssertEquals(AExpected, AHash.ComputeBytes(lBytes).ToString(False), 'Reset');
end;

procedure TestMD5(AContext: TNXTestContext);
begin
  CheckHash(AContext, THashFactory.TCrypto.CreateMD5, '', 'D41D8CD98F00B204E9800998ECF8427E');
  CheckHash(AContext, THashFactory.TCrypto.CreateMD5, 'abc', '900150983CD24FB0D6963F7D28E17F72');
end;
procedure TestSHA1(AContext: TNXTestContext);
begin
  CheckHash(AContext, THashFactory.TCrypto.CreateSHA1, '', 'DA39A3EE5E6B4B0D3255BFEF95601890AFD80709');
  CheckHash(AContext, THashFactory.TCrypto.CreateSHA1, 'abc', 'A9993E364706816ABA3E25717850C26C9CD0D89D');
end;
procedure TestSHA256(AContext: TNXTestContext);
begin
  CheckHash(AContext, THashFactory.TCrypto.CreateSHA2_256, '', 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855');
  CheckHash(AContext, THashFactory.TCrypto.CreateSHA2_256, 'abc', 'BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD');
end;
procedure TestHMAC(AContext: TNXTestContext);
var
  lKey: THashLibByteArray;
begin
  SetLength(lKey, 20);
  FillChar(lKey[0], Length(lKey), $0B);
  // RFC 2202 SHA-1 and RFC 4231 SHA-256, test case 1.
  CheckHash(AContext, THashFactory.THMAC.CreateHMAC(THashFactory.TCrypto.CreateSHA1, lKey),
    'Hi There', 'B617318655057264E28BC0B6FB378C8EF146BE00');
  CheckHash(AContext, THashFactory.THMAC.CreateHMAC(THashFactory.TCrypto.CreateSHA2_256, lKey),
    'Hi There', 'B0344C61D8DB38535CA8AFCEAF0BF12B881DC200C9833DA726E9376C2E32CFF7');
end;
procedure TestCRC32(AContext: TNXTestContext);
begin
  CheckHash(AContext, THashFactory.TChecksum.TCRC.CreateCRC32_PKZIP, '123456789', 'CBF43926');
end;

// Useful vectors from the retired FPC SHA-1/CRC provider tests.
procedure TestSHA1StandardVectors(AContext: TNXTestContext);
var
  lHash: IHash;
  lChunk: RawByteString;
  lIndex: Integer;
begin
  CheckHash(AContext, THashFactory.TCrypto.CreateSHA1,
    'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq',
    '84983E441C3BD26EBAAE4AA1F95129E5E54670F1');
  lHash := THashFactory.TCrypto.CreateSHA1;
  lHash.Initialize;
  lChunk := StringOfChar('a', 1000);
  for lIndex := 1 to 1000 do
    lHash.TransformUntyped(lChunk[1], Length(lChunk));
  AContext.AssertEquals('34AA973CD4C4DAA4F61EEB2BDBAD27316534016F',
    lHash.TransformFinal.ToString(False));
end;

procedure TestCRCProviderVectors(AContext: TNXTestContext);
const
  cInput: array[0..1] of RawByteString = (
    'MNIIQGNLVGTGLKIGIVVGRFNDFITSKLLSGAEDALLRHGVDTNDIDVAWVPGAFEIPFAAKKMAETKKYDAIITLGTVIRGATTSYDYVCNEAAKGIAQAANTTGVPVIFGIVTTENIEQAIERAGTKAGNKGVDCAVSAIEMANLNRSFE',
    'MNIIQGNLVGTGLKIGIVVGRFNDFITSKLLSGAEDALLRHGVDTNDIDVAWVPGAFEIPFAAKKMAETKKYDAIITLGDVIRGATTHYDYVCNEAAKGIAQAANTTGVPVIFGIVTTENIEQAIERAGTKAGNKGVDCAVSAIEMANLNRSFE');
  cCRC32: array[0..1] of Cardinal = (3405150022, 1264209917);
  cCRC64: array[0..1] of QWord = (14444300186948028230, 3310614217963326015);
var
  lIndex: Integer;
  lHash: IHash;
begin
  for lIndex := 0 to High(cInput) do
  begin
    CheckHash(AContext, THashFactory.TChecksum.TCRC.CreateCRC32_PKZIP,
      cInput[lIndex], IntToHex(cCRC32[lIndex], 8));
    lHash := THashFactory.TChecksum.TCRC.CreateCRC64($AD93D23594C935A9,
      High(UInt64), True, True, 0, $CAA717168609F281, ['CRC-64/JONES']);
    CheckHash(AContext, lHash, cInput[lIndex], IntToHex(cCRC64[lIndex], 16));
  end;
end;

procedure TestBinaryBoundaries(AContext: TNXTestContext);
const
  cLengths: array[0..8] of Integer = (1, 55, 56, 63, 64, 65, 127, 128, 257);
  cSHA1: array[0..8] of string = ('5BA93C9DB0CFF93F52B521D7420E43F6EDA2784F',
    '8AE2D46729CFE68FF927AF5EEC9C7D1B66D65AC2',
    '636E2EC698DAC903498E648BD2F3AF641D3C88CB',
    '6D942DA0C4392B123528F2905C713A3CE28364BD',
    'C6138D514FFA2135BFCE0ED0B8FAC65669917EC7',
    '69BD728AD6E13CD76FF19751FDE427B00E395746',
    '89D7312A903F65CD2B3E34A975E55DBEA9033353',
    'E6434BC401F98603D7EDA504790C98C67385D535',
    '89D6D7A79DFC4C2588E5BA3726D163FAA67C4249');
  cSHA256: array[0..8] of string = ('6E340B9CFFB37A989CA544E6BB780A2C78901D3FB33738768511A30617AFA01D',
    '463EB28E72F82E0A96C0A4CC53690C571281131F672AA229E0D45AE59B598B59',
    'DA2AE4D6B36748F2A318F23E7AB1DFDF45ACDC9D049BD80E59DE82A60895F562',
    '29AF2686FD53374A36B0846694CC342177E428D1647515F078784D69CDB9E488',
    'FDEAB9ACF3710362BD2658CDC9A29E8F9C757FCF9811603A8C447CD1D9151108',
    '4BFD2C8B6F1EEC7A2AFEB48B934EE4B2694182027E6D0FC075074F2FABB31781',
    '92CA0FA6651EE2F97B884B7246A562FA71250FEDEFE5EBF270D31C546BFEA976',
    '471FB943AA23C511F6F72F8D1652D9C880CFA392AD80503120547703E56A2BE5',
    '54ACFBFEDC4D8DA40F76F275E1A98F10AF8EF1FB9FB39E5A67A00AABCBE6597C');
var
  lData: RawByteString;
  lCase, lIndex: Integer;
begin
  for lCase := 0 to High(cLengths) do
  begin
    SetLength(lData, cLengths[lCase]);
    for lIndex := 1 to Length(lData) do lData[lIndex] := AnsiChar((lIndex - 1) mod 256);
    CheckHash(AContext, THashFactory.TCrypto.CreateSHA1, lData, cSHA1[lCase]);
    CheckHash(AContext, THashFactory.TCrypto.CreateSHA2_256, lData, cSHA256[lCase]);
  end;
end;
procedure TestEncodedString(AContext: TNXTestContext);
begin
  AContext.AssertEquals('BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD',
    THashFactory.TCrypto.CreateSHA2_256.ComputeString('abc', TEncoding.UTF8).ToString(False));
end;

// RFC 1319/1320/1321 vectors retained from the original FPC MD demonstration.
procedure CheckMDSuite(AContext: TNXTestContext; const AHash: IHash; ARow: Integer);
const
  cInput: array[0..6] of RawByteString = ('', 'a', 'abc', 'message digest',
    'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789',
    '12345678901234567890123456789012345678901234567890123456789012345678901234567890');
  cExpected: array[0..2, 0..6] of string = (('8350E5A3E24C153DF2275C9F80692773', '32EC01EC4A6DAC72C0AB96FB34C0B5D1', 'DA853B0D3F88D99B30283A69E6DED6BB', 'AB4F496BFB2A530B219FF33031FE06B0', '4E8DDFF3650292AB5A4108C3AA47940B', 'DA33DEF2A42DF13975352846C30338CD', 'D5976F79D83D3A0DC9806C3C66F3EFD8'),
    ('31D6CFE0D16AE931B73C59D7E0C089C0', 'BDE52CB31DE33E46245E05FBDBD6FB24', 'A448017AAF21D8525FC10AE87AA6729D', 'D9130A8164549FE818874806E1C7014B', 'D79E1C308AA5BBCDEEA8ED63DF412DA9', '043F8582F241DB351CE627E153E7F0E4', 'E33B4DDC9C38F2199C3E7B164FCC0536'),
    ('D41D8CD98F00B204E9800998ECF8427E', '0CC175B9C0F1B6A831C399E269772661', '900150983CD24FB0D6963F7D28E17F72', 'F96B697D7CB7938D525A2F31AAF161D0', 'C3FCD3D76192E4007DFB496CCA67E13B', 'D174AB98D277D9F5A5611C2C9F419D9F', '57EDF4A22BE3C955AC49DA2E2107B67A'));
var lIndex: Integer;
begin
  for lIndex := 0 to High(cInput) do CheckHash(AContext, AHash, cInput[lIndex], cExpected[ARow, lIndex]);
end;
procedure TestMD2Vectors(AContext: TNXTestContext);
begin CheckMDSuite(AContext, THashFactory.TCrypto.CreateMD2, 0); end;
procedure TestMD4Vectors(AContext: TNXTestContext);
begin CheckMDSuite(AContext, THashFactory.TCrypto.CreateMD4, 1); end;
procedure TestMD5Vectors(AContext: TNXTestContext);
begin CheckMDSuite(AContext, THashFactory.TCrypto.CreateMD5, 2); end;

procedure RegisterHashLibTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('HashLib4Pascal');
  lSuite.AddTest('BinaryBoundaries', @TestBinaryBoundaries);
  lSuite.AddTest('EncodedString', @TestEncodedString);
  lSuite.AddTest('MD2RFCVectors', @TestMD2Vectors);
  lSuite.AddTest('MD4RFCVectors', @TestMD4Vectors);
  lSuite.AddTest('MD5RFCVectors', @TestMD5Vectors);
  lSuite.AddTest('MD5', @TestMD5);
  lSuite.AddTest('SHA1', @TestSHA1);
  lSuite.AddTest('SHA256', @TestSHA256);
  lSuite.AddTest('HMAC', @TestHMAC);
  lSuite.AddTest('CRC32', @TestCRC32);
  lSuite.AddTest('SHA1StandardVectors', @TestSHA1StandardVectors);
  lSuite.AddTest('CRCProviderVectors', @TestCRCProviderVectors);
end;
end.

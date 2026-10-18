// RFC 2202 vectors adapted from the Free Pascal development team's hash tests.
// SPDX-License-Identifier: LGPL-2.1-only WITH Independent-modules-exception
// Original license texts: COPYING.FPC and COPYING.txt beside this unit.
unit tsHMACVectors;
{$mode objfpc}{$H+}
interface
uses obNXTestRegistry;
procedure RegisterHMACVectors(ARegistry: TNXTestRegistry);
implementation
uses SysUtils, HlpHashFactory, HlpIHash, obNXTestContext, obNXTestSuite;

procedure CheckVector(AContext: TNXTestContext; const AHash: IHash;
  ACase: Integer; const AExpected: string);
var
  lKey, lData: RawByteString;
  lKeyBytes, lDataBytes: TBytes;
  lDigest: string;
begin
  case ACase of
    1: begin lKey := StringOfChar(#$0B, AHash.HashSize); lData := 'Hi There'; end;
    2: begin lKey := 'Jefe'; lData := 'what do ya want for nothing?'; end;
    3: begin lKey := StringOfChar(#$AA, AHash.HashSize); lData := StringOfChar(#$DD, 50); end;
    4: begin
      lKey := #$01#$02#$03#$04#$05#$06#$07#$08#$09#$0A#$0B#$0C#$0D#$0E#$0F#$10#$11#$12#$13#$14#$15#$16#$17#$18#$19;
      lData := StringOfChar(#$CD, 50);
    end;
    5: begin lKey := StringOfChar(#$0C, AHash.HashSize); lData := 'Test With Truncation'; end;
    6: begin lKey := StringOfChar(#$AA, 80); lData := 'Test Using Larger Than Block-Size Key - Hash Key First'; end;
    7: begin lKey := StringOfChar(#$AA, 80); lData := 'Test Using Larger Than Block-Size Key and Larger Than One Block-Size Data'; end;
  end;
  SetLength(lKeyBytes, Length(lKey));
  Move(lKey[1], lKeyBytes[0], Length(lKey));
  SetLength(lDataBytes, Length(lData));
  Move(lData[1], lDataBytes[0], Length(lData));
  lDigest := LowerCase(THashFactory.THMAC.CreateHMAC(AHash, lKeyBytes).ComputeBytes(lDataBytes).ToString(False));
  AContext.AssertEquals(AExpected, lDigest);
  if ACase = 5 then
    AContext.AssertEquals(Copy(AExpected, 1, 24), Copy(lDigest, 1, 24), '96-bit truncation');
end;

procedure TestMD5Case1(AContext: TNXTestContext);
begin CheckVector(AContext, THashFactory.TCrypto.CreateMD5, 1, '9294727a3638bb1c13f48ef8158bfc9d'); end;
procedure TestMD5Case2(AContext: TNXTestContext);
begin CheckVector(AContext, THashFactory.TCrypto.CreateMD5, 2, '750c783e6ab0b503eaa86e310a5db738'); end;
procedure TestMD5Case3(AContext: TNXTestContext);
begin CheckVector(AContext, THashFactory.TCrypto.CreateMD5, 3, '56be34521d144c88dbb8c733f0e8b3f6'); end;
procedure TestMD5Case4(AContext: TNXTestContext);
begin CheckVector(AContext, THashFactory.TCrypto.CreateMD5, 4, '697eaf0aca3a3aea3a75164746ffaa79'); end;
procedure TestMD5Case5(AContext: TNXTestContext);
begin CheckVector(AContext, THashFactory.TCrypto.CreateMD5, 5, '56461ef2342edc00f9bab995690efd4c'); end;
procedure TestMD5Case6(AContext: TNXTestContext);
begin CheckVector(AContext, THashFactory.TCrypto.CreateMD5, 6, '6b1ab7fe4bd7bf8f0b62e6ce61b9d0cd'); end;
procedure TestMD5Case7(AContext: TNXTestContext);
begin CheckVector(AContext, THashFactory.TCrypto.CreateMD5, 7, '6f630fad67cda0ee1fb1f562db3aa53e'); end;
procedure TestSHA1Case1(AContext: TNXTestContext);
begin CheckVector(AContext, THashFactory.TCrypto.CreateSHA1, 1, 'b617318655057264e28bc0b6fb378c8ef146be00'); end;
procedure TestSHA1Case2(AContext: TNXTestContext);
begin CheckVector(AContext, THashFactory.TCrypto.CreateSHA1, 2, 'effcdf6ae5eb2fa2d27416d5f184df9c259a7c79'); end;
procedure TestSHA1Case3(AContext: TNXTestContext);
begin CheckVector(AContext, THashFactory.TCrypto.CreateSHA1, 3, '125d7342b9ac11cd91a39af48aa17b4f63f175d3'); end;
procedure TestSHA1Case4(AContext: TNXTestContext);
begin CheckVector(AContext, THashFactory.TCrypto.CreateSHA1, 4, '4c9007f4026250c6bc8414f9bf50c86c2d7235da'); end;
procedure TestSHA1Case5(AContext: TNXTestContext);
begin CheckVector(AContext, THashFactory.TCrypto.CreateSHA1, 5, '4c1a03424b55e07fe7f27be1d58bb9324a9a5a04'); end;
procedure TestSHA1Case6(AContext: TNXTestContext);
begin CheckVector(AContext, THashFactory.TCrypto.CreateSHA1, 6, 'aa4ae5e15272d00e95705637ce8a3b55ed402112'); end;
procedure TestSHA1Case7(AContext: TNXTestContext);
begin CheckVector(AContext, THashFactory.TCrypto.CreateSHA1, 7, 'e8e99d0f45237d786d6bbaa7965c7808bbff1a91'); end;

procedure RegisterHMACVectors(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('HMACMD5RFC2202');
  lSuite.AddTest('Case1', @TestMD5Case1);
  lSuite.AddTest('Case2', @TestMD5Case2);
  lSuite.AddTest('Case3', @TestMD5Case3);
  lSuite.AddTest('Case4', @TestMD5Case4);
  lSuite.AddTest('Case5', @TestMD5Case5);
  lSuite.AddTest('Case6', @TestMD5Case6);
  lSuite.AddTest('Case7', @TestMD5Case7);
  lSuite := ARegistry.AddSuite('HMACSHA1RFC2202');
  lSuite.AddTest('Case1', @TestSHA1Case1);
  lSuite.AddTest('Case2', @TestSHA1Case2);
  lSuite.AddTest('Case3', @TestSHA1Case3);
  lSuite.AddTest('Case4', @TestSHA1Case4);
  lSuite.AddTest('Case5', @TestSHA1Case5);
  lSuite.AddTest('Case6', @TestSHA1Case6);
  lSuite.AddTest('Case7', @TestSHA1Case7);
end;
end.

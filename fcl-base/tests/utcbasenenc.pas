unit utcbasenenc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, obNXTestContext, obNXTestRegistry, obNXTestSuite, basenenc;

procedure RegisterutcbasenencTests(ARegistry: TNXTestRegistry);

implementation

function BytesToStr(const aBytes: TBytes): String;
var
  I: Integer;
begin
  Result := '';
  for I := Low(aBytes) to High(aBytes) do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + IntToStr(aBytes[I]);
  end;
  Result := '[' + Result + ']';
end;

procedure AssertBytesEqual(AContext: TNXTestContext; const Msg: String; const aActual, aExpected: TBytes);
var
  Cmp: Boolean;
begin
  Cmp := (Length(aActual) = Length(aExpected)) and CompareMem(Pointer(aActual), Pointer(aExpected), Length(aActual));
  AContext.AssertTrue(Cmp, Msg + '. Expected: ' + BytesToStr(aExpected) + ', Actual: ' + BytesToStr(aActual));
end;

procedure TestBaseN_RFC3548(AContext: TNXTestContext);
begin

  AContext.AssertTrue(('FPucA9l+') = (Base64.Encode([$14,$fb,$9c,$03,$d9,$7e])), 'RFC3548 B64 1');
  AssertBytesEqual(AContext, 'RFC3548 B64 1 Decode', [$14,$fb,$9c,$03,$d9,$7e], Base64.Decode('FPucA9l+'));
  AContext.AssertTrue(('FPucA9k=') = (Base64.Encode([$14,$fb,$9c,$03,$d9])), 'RFC3548 B64 2');
  AssertBytesEqual(AContext, 'RFC3548 B64 2 Decode', [$14,$fb,$9c,$03,$d9], Base64.Decode('FPucA9k='));
  AContext.AssertTrue(('FPucAw==') = (Base64.Encode([$14,$fb,$9c,$03])), 'RFC3548 B64 3');
  AssertBytesEqual(AContext, 'RFC3548 B64 3 Decode', [$14,$fb,$9c,$03], Base64.Decode('FPucAw=='));
  AContext.AssertTrue(('FPucA9l-') = (Base64URL.Encode([$14,$fb,$9c,$03,$d9,$7e])), 'RFC3548 B64 URL');
  AssertBytesEqual(AContext, 'RFC3548 B64 URL Decode', [$14,$fb,$9c,$03,$d9,$7e], Base64URL.Decode('FPucA9l-'));
end;

procedure TestBaseN_RFC4648_Base64(AContext: TNXTestContext);
begin

  AContext.AssertTrue(('') = (Base64.Encode('')), 'RFC4648 B64 empty');
  AContext.AssertTrue(('Zg==') = (Base64.Encode('f')), 'RFC4648 B64 "f"');
  AContext.AssertTrue(('Zm8=') = (Base64.Encode('fo')), 'RFC4648 B64 "fo"');
  AContext.AssertTrue(('Zm9v') = (Base64.Encode('foo')), 'RFC4648 B64 "foo"');
  AContext.AssertTrue(('Zm9vYg==') = (Base64.Encode('foob')), 'RFC4648 B64 "foob"');
  AContext.AssertTrue(('Zm9vYmE=') = (Base64.Encode('fooba')), 'RFC4648 B64 "fooba"');
  AContext.AssertTrue(('Zm9vYmFy') = (Base64.Encode('foobar')), 'RFC4648 B64 "foobar"');
end;

procedure TestBaseN_RFC4648_Base32(AContext: TNXTestContext);
begin

  AContext.AssertTrue(('') = (Base32.Encode('')), 'RFC4648 B32 empty');
  AContext.AssertTrue(('MY======') = (Base32.Encode('f')), 'RFC4648 B32 "f"');
  AContext.AssertTrue(('MZXQ====') = (Base32.Encode('fo')), 'RFC4648 B32 "fo"');
  AContext.AssertTrue(('MZXW6===') = (Base32.Encode('foo')), 'RFC4648 B32 "foo"');
  AContext.AssertTrue(('MZXW6YQ=') = (Base32.Encode('foob')), 'RFC4648 B32 "foob"');
  AContext.AssertTrue(('MZXW6YTB') = (Base32.Encode('fooba')), 'RFC4648 B32 "fooba"');
  AContext.AssertTrue(('MZXW6YTBOI======') = (Base32.Encode('foobar')), 'RFC4648 B32 "foobar"');
end;

procedure TestBaseN_RFC4648_Base32Hex(AContext: TNXTestContext);
begin

  AContext.AssertTrue(('') = (Base32Hex.Encode('')), 'RFC4648 B32Hex empty');
  AContext.AssertTrue(('CO======') = (Base32Hex.Encode('f')), 'RFC4648 B32Hex "f"');
  AContext.AssertTrue(('CPNG====') = (Base32Hex.Encode('fo')), 'RFC4648 B32Hex "fo"');
  AContext.AssertTrue(('CPNMU===') = (Base32Hex.Encode('foo')), 'RFC4648 B32Hex "foo"');
  AContext.AssertTrue(('CPNMUOG=') = (Base32Hex.Encode('foob')), 'RFC4648 B32Hex "foob"');
  AContext.AssertTrue(('CPNMUOJ1') = (Base32Hex.Encode('fooba')), 'RFC4648 B32Hex "fooba"');
  AContext.AssertTrue(('CPNMUOJ1E8======') = (Base32Hex.Encode('foobar')), 'RFC4648 B32Hex "foobar"');
end;

procedure TestBaseN_RFC4648_Base16(AContext: TNXTestContext);
begin

  AContext.AssertTrue(('') = (Base16.Encode('')), 'RFC4648 B16 empty');
  AContext.AssertTrue(('66') = (Base16.Encode('f')), 'RFC4648 B16 "f"');
  AContext.AssertTrue(('666F') = (Base16.Encode('fo')), 'RFC4648 B16 "fo"');
  AContext.AssertTrue(('666F6F') = (Base16.Encode('foo')), 'RFC4648 B16 "foo"');
  AContext.AssertTrue(('666F6F62') = (Base16.Encode('foob')), 'RFC4648 B16 "foob"');
  AContext.AssertTrue(('666F6F6261') = (Base16.Encode('fooba')), 'RFC4648 B16 "fooba"');
  AContext.AssertTrue(('666F6F626172') = (Base16.Encode('foobar')), 'RFC4648 B16 "foobar"');
end;

procedure RegisterutcbasenencTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCL.Encoding.TBaseNTests');
  lSuite.AddTest('TestRFC3548', @TestBaseN_RFC3548, 'encoding');
  lSuite.AddTest('TestRFC4648_Base64', @TestBaseN_RFC4648_Base64, 'encoding');
  lSuite.AddTest('TestRFC4648_Base32', @TestBaseN_RFC4648_Base32, 'encoding');
  lSuite.AddTest('TestRFC4648_Base32Hex', @TestBaseN_RFC4648_Base32Hex, 'encoding');
  lSuite.AddTest('TestRFC4648_Base16', @TestBaseN_RFC4648_Base16, 'encoding');
end;

end.

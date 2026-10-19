unit utcLZW;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, obNXTestContext, obNXTestRegistry, obNXTestSuite, lzwstream;

procedure RegisterutcLZWTests(ARegistry: TNXTestRegistry);

implementation

{ TTestLZW }

{$i filec.inc}
{$i filed.inc}

procedure TestFileC(AContext: TNXTestContext);

Var
  Z : TLZWDecompressionStream;
  C,D : TBytesStream;
  B : TBytes;
  I,R : Integer;

begin

  D:=Nil;
  Z:=Nil;
  C:=TBytesStream.Create([]);
  try
    C.WriteBuffer(filec,sizeof(filec));
    C.Position:=0;
    D:=TBytesStream.Create;
    D.WriteBuffer(filed,sizeof(filed));
    D.Position:=0;
    Z:=TLZWDecompressionStream.Create(C,[zoTIFFCodes]);
    Z.SourceOwner:=False;
    SetLength(B,D.Size);
    R:=Z.Read(B[0],D.Size);
    AContext.AssertTrue((D.Size) = (R), 'Correct length read');
    For I:=0 to Length(B)-1 do
      AContext.AssertTrue((PByte(D.Memory)[i]) = (B[i]), 'Byte '+IntToStr(I));
  finally
    C.Free;
    D.Free;
    Z.Free;
  end;

end;

procedure RegisterutcLZWTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCL.Streams.TTestLZW');
  lSuite.AddTest('TestFileC', @TestFileC, 'streams');
end;

end.

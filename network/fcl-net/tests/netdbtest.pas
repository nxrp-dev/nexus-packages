unit netdbtest;

{$mode objfpc}{$H+}

interface

uses
  obNXTestContext, obNXTestRegistry, obNXTestSuite, Classes, SysUtils, Sockets, math, netdb;

const
  FAKETLD = 'doesnotexist';
  FAKEDOMAIN = 'fakedomain';

  FAKEFQDN=FAKEDOMAIN+'.'+FAKETLD;

type
  TDomainCompressionOffset = packed record
    nm: String;
    offset: Word;
  end;
  TDomainCompressionTable = Array of TDomainCompressionOffset;

  TTwoByteArr = array[0 .. 1] of Byte;
  TDNSDomainPointer = packed record
    case b: boolean of
      true: (ba: TTwoByteArr);
      false: (b1,b2: Byte);
  end;

  TDNSDomainByteStream = packed record
    ulabels: Array of byte;
    cptr: Word;
  end;

  TBuffer = Array of Byte;

  // can't use dynamic arrays in variant records, so fudge things by
  // having between 1 and 5 subsstrings per text RR. it's good enough
  // for these tests.
  TTextArray = array [1 .. 5] of ShortString;

  TFakeQuery = record
    nm: ShortString;
    qtype, qclass: Word;
  end;

  TFakeSOA = record
    mn,rn: ShortString;
    serial,refresh,retry,expire,min: Cardinal;
  end;
  TFakeMX = record
    pref: Word;
    exch: ShortString;
  end;
  TFakeSRV = record
    priority, weight, port: Word;
    target: ShortString;
  end;

  TFakeRR = record
    RRName   : ShortString;
    AClass   : Word;
    TTL      : Cardinal;
    RDLength : Word;
    case Atype: Word of
      DNSQRY_A: (ip: THostAddr);
      DNSQRY_AAAA: (ip6: THostAddr6);
      DNSQRY_CNAME: (cn: ShortString);
      DNSQRY_MX: (fmx: TFakeMX);
      DNSQRY_NS: (nsh: ShortString);
      DNSQRY_PTR: (ptr: ShortString);
      DNSQRY_SOA: (fsoa: TFakeSoa);
      DNSQRY_TXT: (sstrcount: Byte; txtarr: TTextArray);
      DNSQRY_SRV: (fsrv: TFakeSRV);
  end;

  TRRSection = Array of TFakeRR;

  TFakeDNSResponse = record
    strtable: TDomainCompressionTable;
    compresslabels: Boolean;
    hdr: TDNSHeader;
    qry: TFakeQuery;
    answers, authority, additional: TRRSection;
  end;

  TRDataWriteRes = packed record
    bw, etw: Word;
  end;

  { TNetDbTest }

  TNetDbTest= class(TObject)
  private
    FContext: TNXTestContext;
    FCaseName: string;
  protected
    property TestContext: TNXTestContext read FContext;
    property CaseName: string read FCaseName;
  public
    constructor Create(AContext: TNXTestContext; const ACaseName: string);
  strict private
    tsl: TStringList;
  protected
    procedure SetUp; virtual;
    procedure TearDown; virtual;

    procedure BuildFakeRR_A(out RR: TFakeRR; nm: String; ttl: Cardinal;
      val: String);
    procedure BuildFakeRR_AAAA(out RR: TFakeRR; nm: String; ttl: Cardinal;
      val: String);
    procedure BuildFakeRR_MX(out RR: TFakeRR; nm: String; ttl: Cardinal;
      pref: Word; exch: ShortString );
    procedure BuildFakeRR_NS(out RR: TFakeRR; nm: String; ttl: Cardinal;
      val: String);
    procedure BuildFakeRR_PTR(out RR: TFakeRR; nm: String; ttl: Cardinal;
      val: String);
    procedure BuildFakeRR_CNAME(out RR: TFakeRR; nm: String; ttl: Cardinal;
      val: String);
    procedure BuildFakeRR_SOA(out RR: TFakeRR; nm: String; ttl: Cardinal;
      mn,rn: ShortString; serial,refresh,retry,expire,min: Cardinal);
    procedure BuildFakeRR_TXT(out RR: TFakeRR; nm: String; ttl: Cardinal;
      n: Byte; txt: TTextArray);
    procedure BuildFakeRR_SRV(out RR: TFakeRR; nm: String; ttl: Cardinal;
       priority, weight, port: Word; target: ShortString);

    procedure CopyBytesTo(var buf: TPayLoad; startidx,destidx,count: Word);
    procedure CopyBytesTo(var buf: TPayLoadTCP; startidx,destidx,count: Word);

    function WriteNumToBuffer(var buf: TBuffer; var offset: Cardinal;
       val: Word): Word;
    function WriteNumToBuffer(var buf: TBuffer; var offset: Cardinal;
       val: Cardinal): Word;

    function WriteNumToBufferN(var buf: TBuffer; var offset: Cardinal;
       val: Word): Word;
    function WriteNumToBufferN(var buf: TBuffer; var offset: Cardinal;
       val: Cardinal): Word;

    function WriteMXAsRData(var buf: TBuffer; var offset: Cardinal;
      fmx: TFakeMX): TRDataWriteRes;
    function WriteSOAasRData(var buf: TBuffer; var offset: Cardinal;
      fsoa: TFakeSOA): TRDataWriteRes;
    function WriteSOAasRData(var buf: TBuffer; var offset: Cardinal;
      fsoa: TFakeSOA; var ctbl: TDomainCompressionTable): TRDataWriteRes;
    function WriteAAAAasRData(var buf: TBuffer; var offset: Cardinal;
      ip6: THostAddr6): TRDataWriteRes;
    function WriteAasRData(var buf: TBuffer; var offset: Cardinal;
      ip: THostAddr): TRDataWriteRes;

    function WriteSRVasRData(var buf: TBuffer; var offset: Cardinal;
      fsrv: TFakeSRV): TRDataWriteRes;
    function WriteSRVasRData(var buf: TBuffer; var offset: Cardinal;
      fsrv: TFakeSRV; var ctbl: TDomainCompressionTable): TRDataWriteRes;

    function WriteMXAsRData(var buf: TBuffer; var offset: Cardinal;
      fmx: TFakeMX; var ctbl: TDomainCompressionTable): TRDataWriteRes;

    function CalcRdLength(o: TDNSDomainByteStream): Word;
    function CalcRdLength(o: TTextArray): Word;
    function WriteTextRecAsRData(var buf: TBuffer; var offset: Cardinal;
      tt: TTextArray): TRDataWriteRes;

    function DomainNameToByteStream(nm: ShortString;
      var ctbl: TDomainCompressionTable): TDNSDomainByteStream;
    function DomainNameToByteStream(nm: ShortString): TDNSDomainByteStream;

    function WriteDNSDomainByteStreamToBuffer(var buf: TBuffer;
      var offset: Cardinal; dbs: TDNSDomainByteStream): Word;

    function WriteDomainAsRdata(var buf: TBuffer; var offset: Cardinal;
      dbs: TDNSDomainByteStream): TRDataWriteRes;

    function WriteRRToBuffer(var buf: TBuffer; var offset: Cardinal;
      rr: TFakeRR): Word;
    function WriteRRToBuffer(var buf: TBuffer; var offset: Cardinal;
      rr: TFakeRR; var ctbl: TDomainCompressionTable): Word;
    function FakeDNSResponseToByteBuffer(fdr: TFakeDNSResponse;
      out buf: TBuffer; compress: Boolean = False): Cardinal;
    function BufferToPayload(const buf: TBuffer; out pl: TPayload): Boolean;
    function BufferToPayload(const buf: TBuffer; out pl: TPayLoadTCP): Boolean;

    function BuildQueryData(fdr: TFakeDNSResponse; out qd: TQueryData;
      out qlen: Word; Compress: Boolean = False): Boolean;

    function BuildQueryData(fdr: TFakeDNSResponse;
      out qd: TQueryDataLengthTCP; out qlen: Word;
        Compress: Boolean = False): Boolean;

    function BuildTruncatedQueryData(fdr: TFakeDNSResponse; out qd: TQueryData;
      out qlen: Word; truncoffset: Word): Boolean;

    procedure BuildFakeResponseA(nm: ShortString; out fr: TFakeDNSResponse);
    procedure BuildFakeResponseAAAA(nm: ShortString; out fr: TFakeDNSResponse);
    procedure BuildFakeResponseMX(nm: ShortString; out fr: TFakeDNSResponse);
    procedure BuildFakeResponseSOA(nm: ShortString; out fr: TFakeDNSResponse);
    procedure BuildFakeResponseCNAME(nm: ShortString; out fr: TFakeDNSResponse);
    procedure BuildFakeResponseNS(nm: ShortString; out fr: TFakeDNSResponse);
    procedure BuildFakeResponsePTR(nm: ShortString; out fr: TFakeDNSResponse);
    procedure BuildFakeResponseTXT(nm: ShortString; out fr: TFakeDNSResponse);
    procedure BuildFakeResponseSRV(nm: ShortString; out fr: TFakeDNSResponse);

  public
    procedure TestBuildPayloadSimple;
    procedure TestBuildPayloadSimpleEmpty;
    procedure TestBuildPayloadSimpleEndDot;
    procedure TestBuildPayloadSimpleStartDot;
    procedure TestBuildPayloadSimpleMultipleDot;

    { * straightforward tests for the api with valid data. Have to test each
      * known RR type with both TCP and UDP buffer functions, and with and
      * without compression of domain names.
      * No network calls will be made. These tests hit all functions for
      * processing dns requests except network functions.}
    procedure TestDnsQueryUDP_A;
    procedure TestDnsQueryTCP_A;
    procedure TestDnsQueryCompressUDP_A;
    procedure TestDnsQueryCompressTCP_A;

    procedure TestDnsQueryUDP_AAAA;
    procedure TestDnsQueryTCP_AAAA;
    procedure TestDnsQueryCompressUDP_AAAA;
    procedure TestDnsQueryCompressTCP_AAAA;

    procedure TestDnsQueryUDP_MX;
    procedure TestDnsQueryTCP_MX;
    procedure TestDnsQueryCompressUDP_MX;
    procedure TestDnsQueryCompressTCP_MX;

    procedure TestDnsQueryUDP_SOA;
    procedure TestDnsQueryTCP_SOA;
    procedure TestDnsQueryCompressUDP_SOA;
    procedure TestDnsQueryCompressTCP_SOA;

    procedure TestDnsQueryUDP_CNAME;
    procedure TestDnsQueryTCP_CNAME;
    procedure TestDnsQueryCompressUDP_CNAME;
    procedure TestDnsQueryCompressTCP_CNAME;

    procedure TestDnsQueryUDP_NS;
    procedure TestDnsQueryTCP_NS;
    procedure TestDnsQueryCompressUDP_NS;
    procedure TestDnsQueryCompressTCP_NS;

    procedure TestDnsQueryUDP_PTR;
    procedure TestDnsQueryTCP_PTR;
    procedure TestDnsQueryCompressUDP_PTR;
    procedure TestDnsQueryCompressTCP_PTR;

    procedure TestDnsQueryUDP_TXT;
    procedure TestDnsQueryTCP_TXT;
    procedure TestDnsQueryCompressUDP_TXT;
    procedure TestDnsQueryCompressTCP_TXT;

    procedure TestDnsQueryUDP_SRV;
    procedure TestDnsQueryTCP_SRV;
    procedure TestDnsQueryCompressUDP_SRV;
    procedure TestDnsQueryCompressTCP_SRV;

    {
      * Tests with invalid input data. These attempt to simulate a hostile
      * dns server returning deliberately invalid data in an attempt to
      * cause a buffer overflow, memory corruption, or DDOS.
    }

    // buffer truncated so RRs have invalid types.
    procedure TestDnsQueryTruncateRR_UDP_A;

    {
     * Tests of DNSRRGet* functions where RR is near the end of the buffer,
     * testing both when the RR just fits, and when it doesn't.
     }
    procedure TestDnsRRBufferEdgeA;
    procedure TestDnsRRBufferPastEdgeA;
    procedure TestDnsRRBufferEdgeAAAA;
    procedure TestDNsRRBufferPastEdgeAAAA;
    procedure TestDnsRRBufferEdgeMX;
    procedure TestDnsRRBufferPastEdgeMX;
    procedure TestDnsRRBufferEdgeSOA;
    procedure TestDnsRRBufferPastEdgeSOA;
    procedure TestDnsRRBufferEdgeSRV;
    procedure TestDnsRRBufferPastEdgeSRV;
    procedure TestDnsRRBufferEdgeCNAME;
    procedure TestDnsRRBufferPastEdgeCNAME;
    procedure TestDnsRRBufferEdgeNS;
    procedure TestDnsRRBufferPastEdgeNS;
    procedure TestDnsRRBufferEdgePTR;
    procedure TestDnsRRBufferPastEdgePTR;
    procedure TestDnsRRBufferEdgeTXT;
    procedure TestDnsRRBufferPastEdgeTXT;


    {
     * the TCP variants. identical code, but qd variable is a different type
     * and so different paths get followed in netdb.
    }
    procedure TestDnsRRBufferEdgeTCPA;
    procedure TestDnsRRBufferPastEdgeTCPA;
    procedure TestDnsRRBufferEdgeTCPAAAA;
    procedure TestDNsRRBufferPastEdgeTCPAAAA;
    procedure TestDnsRRBufferEdgeTCPMX;
    procedure TestDnsRRBufferPastEdgeTCPMX;
    procedure TestDnsRRBufferEdgeTCPSOA;
    procedure TestDnsRRBufferPastEdgeTCPSOA;
    procedure TestDnsRRBufferEdgeTCPSRV;
    procedure TestDnsRRBufferPastEdgeTCPSRV;
    procedure TestDnsRRBufferEdgeTCPCNAME;
    procedure TestDnsRRBufferPastEdgeTCPCNAME;
    procedure TestDnsRRBufferEdgeTCPNS;
    procedure TestDnsRRBufferPastEdgeTCPNS;
    procedure TestDnsRRBufferEdgeTCPPTR;
    procedure TestDnsRRBufferPastEdgeTCPPTR;
    procedure TestDnsRRBufferEdgeTCPTXT;
    procedure TestDnsRRBufferPastEdgeTCPTXT;

    // Testing of NextNameRR at buffer edge and beyond. this differs from
    // the above tests in that they tests DNSGet* at the edge, but NextNameRR
    // is never called to read at the edge in those functions.
    // Because NextNameRR does nothing that is specific to RR types it's
    // not necessary to test with each type of RR.

    procedure TestNextNameRREdgeA;
    procedure TestNextNameRRPastEdgeA;
    procedure TestNextNameRREdgeTCPA;
    procedure TestNextNameRRPastEdgeTCPA;

    {
     * Test GetRRrecords at and beyond buffer boundaries.
    }
    procedure TestGetRRrecordsInvalidStart;
    procedure TestGetRRrecordsInvalidStartTCP;

    {
    Tests for GetFixlenStr
    }
    procedure TestGetFixLenStrSimple;
    procedure TestGetFixLenStrSimpleTCP;
    procedure TestGetFixLenStrSimpleAtEdge;
    procedure TestGetFixLenStrSimpleTCPAtEdge;
    procedure TestGetFixLenStrSimplePastEdge;
    procedure TestGetFixLenStrSimpleTCPPastEdge;


    {
     * Test stringfromlabel with buffer edges and beyond. Its behaviour
     * at present is to drop any label that would exceed the buffer boundary
     * but still return any other labels successfully received.

     * Some of the previous tests already verify what happens with a label
     * that occurs on the edge. See the tests for TestDnsRRBufferEdgeSRV
     * and TestDnsRRBufferEdgeTCPSRV, TestDnsRRBufferEdgeCNAME, etc.
    }

    // read a label starting at the end of the buffer where the count is
    // greater than 0.
    procedure TestStringFromLabelCountAsLastByte;
    procedure TestStringFromLabelCountAsLastByteTCP;

    // compressed label
    procedure TestStringFromLabelCompress;
    procedure TestStringFromLabelCompressTCP;
    // another compressed label test, this time with one uncompressed label
    procedure TestStringFromLabelCompressWithUncompressedLabel;
    // as above, but on the tcp payload buffer
    procedure TestStringFromLabelCompressWithUncompressedLabelTCP;
    // compressed label at the edge of the buffer
    procedure TestStringFromLabelCompressEndBuffer;
    // compressed label at the edge of the tcp buffer
    procedure TestStringFromLabelCompressEndBufferTCP;
    // test stringfromlabel when last byte is 192. 192 is the signal
    // that the next byte is a pointer offset, but of course there's
    // no next byte.
    procedure TestStringFromLabelCompressSplit;
    // repeat using TCP buffer variant
    procedure TestStringFromLabelCompressSplitTCP;
    // test that stringfromlabel rejects pointers that go forward. per
    // rfc 1035, pointers must go backward.
    procedure TestStringFromLabelCompressPtrFwd;
    procedure TestStringFromLabelCompressPtrFwdTCP;
    // fill buffer with 192, pointer marker, then try stringfromlabel on it.
    procedure TestStringFromLabelCompressAllPtrStart;
    procedure TestStringFromLabelCompressAllPtrStartTCP;

    // test string from label where second byte is 0.
    procedure TestStringFromLabelCompressedZero;
    procedure TestStringFromLabelCompressedZeroTCP;

    // test whether an infinite loop can be triggered.
    procedure TestStringFromLabelInfiniteLoop;
    procedure TestStringFromLabelInfiniteLoopTCP;

    // test short domain less than 12 chars. this tests that dns pointer
    // calculations in stringfromlabel are correct
    procedure TestCompressShortDomain;
    procedure TestCompressShortDomainTCP;
  end;

procedure RegisternetdbtestTests(ARegistry: TNXTestRegistry);

implementation

procedure dump_payload(const pl: TBuffer);
var
  idx,llen: Cardinal;
begin
  idx := 0;
  llen := 0;
  for idx := 0 to Length(pl) - 1 do
  begin
    write('['+inttostr(idx)+'] '+IntToHex(pl[idx],2));
    if (pl[idx] > 48) and (pl[idx] < 123) then
      write(' ' + chr(pl[idx]))
    else
      write(' .');
    write(' ');
    Inc(llen);
    if llen >= 6 then
    begin
      llen := 0;
      writeln();
    end;
  end;
  if llen > 0 then
  begin
    writeln();
  end;
end;

procedure dump_payload(const pl: TPayload; count: Word);
var
  idx,llen: Cardinal;
begin
  idx := 0;
  llen := 0;
  for idx := 0 to count - 1 do
  begin
    write('['+inttostr(idx)+'] '+IntToHex(pl[idx],2));
    if (pl[idx] > 48) and (pl[idx] < 123) then
      write(' ' + chr(pl[idx]))
    else
      write(' .');
    write(' ');
    Inc(llen);
    if llen >= 6 then
    begin
      llen := 0;
      writeln();
    end;
  end;
  if llen > 0 then
  begin
    writeln();
  end;
end;

function LookupStr(ls: String; stt: TDomainCompressionTable; out idx: Word): Boolean;
var
  so: TDomainCompressionOffset;
begin
  Result := False;
  for so in stt do
  begin
    if ls = so.nm then
    begin
      Result := True;
      idx := so.offset;
      exit;
    end;
  end;
end;

function AddStr(ls: String; var stt: TDomainCompressionTable; idx: Word): Boolean;
var
  so: TDomainCompressionOffset;
begin
  so.nm := ls;
  so.offset := idx;
  SetLength(stt, Length(stt)+1);
  stt[Length(stt)-1] := so;
  Result := True;
end;

function GetDnsDomainPointer(offset: Word): TDNSDomainPointer;
begin
  Result.b1 := 0;
  Result.b2 := 0;
  // dns comp. ptr can't be > 2 ** 14 or 16383
  if offset > 16383 then exit;
  Result.b1 := (offset SHR 8) OR 192;
  Result.b2 := (offset AND $00FF);
end;

procedure DomainNameToLabels(const dmn: String; var labels: TStringList);
begin
  labels.Clear;
  labels.Delimiter := '.';
  labels.StrictDelimiter := True;
  labels.DelimitedText := dmn;
end;

procedure TNetDbTest.BuildFakeRR_A(out RR: TFakeRR; nm: String; ttl: Cardinal;
  val: String);
begin
  RR.RRName := nm;
  RR.Atype := DNSQRY_A;
  RR.AClass := 1;
  RR.TTL := ttl;
  RR.ip := StrToNetAddr(val);
  RR.RDLength := 4;
end;

procedure TNetDbTest.BuildFakeRR_AAAA(out RR: TFakeRR; nm: String;
  ttl: Cardinal; val: String);
begin
  RR.RRName := nm;
  RR.Atype := DNSQRY_AAAA;
  RR.AClass := 1;
  RR.TTL := ttl;
  RR.ip6 := StrToNetAddr6(val);
  RR.RDLength := 16;
end;

procedure TNetDbTest.BuildFakeRR_MX(out RR: TFakeRR; nm: String; ttl: Cardinal;
  pref: Word; exch: ShortString );
begin
  RR.RRName := nm;
  RR.Atype := DNSQRY_MX;
  RR.AClass := 1;
  RR.TTL := ttl;
  RR.fmx.pref := pref;
  RR.fmx.exch := exch;
end;

procedure TNetDbTest.BuildFakeRR_NS(out RR: TFakeRR; nm: String; ttl: Cardinal;
  val: String);
begin
  RR.RRName := nm;
  RR.Atype := DNSQRY_NS;
  RR.AClass := 1;
  RR.TTL := ttl;
  RR.nsh := val;
end;

procedure TNetDbTest.BuildFakeRR_PTR(out RR: TFakeRR; nm: String; ttl: Cardinal;
  val: String);
begin
  RR.RRName := nm;
  RR.Atype := DNSQRY_PTR;
  RR.AClass := 1;
  RR.TTL := ttl;
  RR.ptr := val;
end;

procedure TNetDbTest.BuildFakeRR_CNAME(out RR: TFakeRR; nm: String;
  ttl: Cardinal; val: String);
begin
  RR.RRName := nm;
  RR.Atype := DNSQRY_CNAME;
  RR.AClass := 1;
  RR.TTL := ttl;
  RR.cn := val;
end;

procedure TNetDbTest.BuildFakeRR_SOA(out RR: TFakeRR; nm: String; ttl: Cardinal;
  mn,rn: ShortString; serial,refresh,retry,expire,min: Cardinal);
begin
  RR.RRName := nm;
  RR.Atype := DNSQRY_SOA;
  RR.AClass := 1;
  RR.TTL := ttl;
  RR.fsoa.mn := mn;
  RR.fsoa.rn := rn;
  RR.fsoa.serial := serial;
  RR.fsoa.refresh := refresh;
  RR.fsoa.retry := retry;
  RR.fsoa.expire := expire;
  RR.fsoa.min := min;
end;

procedure TNetDbTest.BuildFakeRR_TXT(out RR: TFakeRR; nm: String; ttl: Cardinal;
  n: Byte; txt: TTextArray);
var
  idx: Byte;
begin
  RR.RRName := nm;
  RR.Atype := DNSQRY_TXT;
  RR.AClass := 1;
  RR.TTL := ttl;
  RR.sstrcount := n;
  RR.txtarr[1] := '';
  RR.txtarr[2] := '';
  RR.txtarr[3] := '';
  RR.txtarr[4] := '';
  RR.txtarr[5] := '';
  for idx := Low(txt) to Min(n, High(txt)) do
    RR.txtarr[idx] := txt[idx];
end;

procedure TNetDbTest.BuildFakeRR_SRV(out RR: TFakeRR; nm: String; ttl: Cardinal;
   priority, weight, port: Word; target: ShortString);
begin
  RR.RRName := nm;
  RR.Atype := DNSQRY_SRV;
  RR.AClass := 1;
  RR.TTL := ttl;
  RR.fsrv.priority := priority;
  RR.fsrv.weight := weight;
  RR.fsrv.port := port;
  RR.fsrv.target := target;
end;

function TNetDbTest.CalcRdLength(o: TTextArray): Word;
var
  tmps: ShortString;
begin
  Result := 0;
  for tmps in o do
  begin
    if tmps = '' then break;
    Result := Result + Length(tmps)+1; // don't forget length byte!
  end;
end;

function TNetDbTest.WriteAasRData(var buf: TBuffer; var offset: Cardinal;
  ip: THostAddr): TRDataWriteRes;
var
  s,l: Word;
begin
  s := offset;
  l := SizeOf(ip.s_addr);
  Result.etw := l + 2; //rdlength +2 for length itself
  // rdlength
  WriteNumToBuffer(buf, offset, l);
  // rr data
  WriteNumToBufferN(buf, offset, ip.s_addr);
  Result.bw := offset - s;
end;

function TNetDbTest.WriteSRVasRData(var buf: TBuffer; var offset: Cardinal;
  fsrv: TFakeSRV): TRDataWriteRes;
var
  s, l: Word;
  dmbs: TDNSDomainByteStream;
begin
  s := offset;
  dmbs := DomainNameToByteStream(fsrv.target);
  l := CalcRdLength(dmbs) + SizeOf(Word) * 3;
  Result.etw := l + 2; //rdlength +2 for length byte

  // rdlength
  WriteNumToBuffer(buf, offset, l);

  // RR data
  WriteNumToBuffer(buf, offset, fsrv.priority);
  WriteNumToBuffer(buf, offset, fsrv.weight);
  WriteNumToBuffer(buf, offset, fsrv.port);
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);
  Result.bw := offset - s;
end;

function TNetDbTest.WriteSRVasRData(var buf: TBuffer; var offset: Cardinal;
  fsrv: TFakeSRV; var ctbl: TDomainCompressionTable): TRDataWriteRes;
var
  s, l: Word;
  dmbs: TDNSDomainByteStream;
begin
  s := offset;
  dmbs := DomainNameToByteStream(fsrv.target, ctbl);
  l := CalcRdLength(dmbs) + SizeOf(Word) * 3;
  Result.etw := l + 2; //rdlength +2 for length byte

  // rdlength
  WriteNumToBuffer(buf, offset, l);

  // RR data
  WriteNumToBuffer(buf, offset, fsrv.priority);
  WriteNumToBuffer(buf, offset, fsrv.weight);
  WriteNumToBuffer(buf, offset, fsrv.port);
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);
  Result.bw := offset - s;
end;

function TNetDbTest.WriteMXAsRData(var buf: TBuffer; var offset: Cardinal;
  fmx: TFakeMX; var ctbl: TDomainCompressionTable): TRDataWriteRes;
var
  s, l: Word;
  dmbs: TDNSDomainByteStream;
begin
  s := offset;
  dmbs := DomainNameToByteStream(fmx.exch, ctbl);
  l := SizeOf(fmx.pref) + CalcRdLength(dmbs);
  Result.etw := l + 2; // we'll write rdlength bytes+2 bytes for length itself.

  // rdlength
  WriteNumToBuffer(buf, offset, l);

  // RR data
  // pref
  WriteNumToBuffer(buf, offset, fmx.pref);
  // exchange
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);
  Result.bw := offset - s;
end;

function TNetDbTest.CalcRdLength(o: TDNSDomainByteStream): Word;
begin
  Result := Length(o.ulabels);
  if o.cptr > 0 then Inc(Result,2);
end;

function TNetDbTest.WriteAAAAasRData(var buf: TBuffer; var offset: Cardinal;
  ip6: THostAddr6): TRDataWriteRes;
var
  s,l: Word;
begin
  s := offset;
  l := SizeOf(ip6.u6_addr32);
  Result.etw := l + 2; //rdlength + 2 for length itself
  // rdlength
  WriteNumToBuffer(buf, offset, l);
  // rr data
  Move(ip6.s6_addr, buf[offset], l);
  Inc(offset, l);
  Result.bw := offset - s;
end;

function TNetDbTest.WriteSOAasRData(var buf: TBuffer; var offset: Cardinal;
  fsoa: TFakeSOA): TRDataWriteRes;
var
  s, l: Word;
  dmbsmn, dmbsrn: TDNSDomainByteStream;
begin
  s := offset;
  dmbsmn := DomainNameToByteStream(fsoa.mn);
  dmbsrn := DomainNameToByteStream(fsoa.rn);
  l := CalcRdLength(dmbsmn) + CalcRdLength(dmbsrn) + (SizeOf(Cardinal) * 5);

  Result.etw := l + 2; // rdlength bytes + 2 for length itself

  // rdlength
  WriteNumToBuffer(buf, offset, l);

  // rr data
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbsmn);
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbsrn);

  WriteNumToBuffer(buf, offset, fsoa.serial);
  WriteNumToBuffer(buf, offset, fsoa.refresh);
  WriteNumToBuffer(buf, offset, fsoa.retry);
  WriteNumToBuffer(buf, offset, fsoa.expire);
  WriteNumToBuffer(buf, offset, fsoa.min);

  Result.bw := offset - s;
end;

function TNetDbTest.WriteSOAasRData(var buf: TBuffer; var offset: Cardinal;
  fsoa: TFakeSOA; var ctbl: TDomainCompressionTable): TRDataWriteRes;
var
  s, l: Word;
  dmbsmn, dmbsrn: TDNSDomainByteStream;
begin
  s := offset;
  dmbsmn := DomainNameToByteStream(fsoa.mn, ctbl);
  dmbsrn := DomainNameToByteStream(fsoa.rn, ctbl);
  l := CalcRdLength(dmbsmn) + CalcRdLength(dmbsrn) + (SizeOf(Cardinal) * 5);
  Result.etw := l + 2; // rdlength bytes + 2 for length itself

  // rdlength
  WriteNumToBuffer(buf, offset, l);

  // rr data
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbsmn);
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbsrn);

  WriteNumToBuffer(buf, offset, fsoa.serial);
  WriteNumToBuffer(buf, offset, fsoa.refresh);
  WriteNumToBuffer(buf, offset, fsoa.retry);
  WriteNumToBuffer(buf, offset, fsoa.expire);
  WriteNumToBuffer(buf, offset, fsoa.min);

  Result.bw := offset - s;
end;

function TNetDbTest.WriteMXAsRData(var buf: TBuffer; var offset: Cardinal;
  fmx: TFakeMX): TRDataWriteRes;
var
  s, l: Word;
  dmbs: TDNSDomainByteStream;
begin
  Result.bw := 0;
  s := offset;
  dmbs := DomainNameToByteStream(fmx.exch);
  l := SizeOf(fmx.pref) + CalcRdLength(dmbs);
  Result.etw := l + 2; // we'll write rdlength + 2 bytes for the length itself.

  // rdlength
  WriteNumToBuffer(buf, offset, l);

  // RR data
  // pref
  WriteNumToBuffer(buf, offset, fmx.pref);
  // exchange
  dmbs := DomainNameToByteStream(fmx.exch);
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);
  Result.bw := offset - s;
end;

function TNetDbTest.WriteTextRecAsRData(var buf: TBuffer; var offset: Cardinal;
  tt: TTextArray): TRDataWriteRes;
var
  s, l: Word;
  ws: ShortString;
begin
  s := offset;
  l := CalcRdLength(tt);
  Result.etw := l + 2; // rdlength +2 for length itself
  // rdlength
  WriteNumToBuffer(buf, offset, l);

  for ws in tt do
  begin
    if  ws = '' then break;
    Move(ws, buf[offset], Length(ws)+1);
    Inc(offset,Length(ws)+1);
  end;

  Result.bw := offset - s;
end;

{
Convert a domain name into a byte stream. Compression is supported using the
supplied compression table.
}
function TNetDbTest.DomainNameToByteStream(nm: ShortString;
  var ctbl: TDomainCompressionTable): TDNSDomainByteStream;
var
  dmn: ShortString;
  offset,cmpoffset: Word;
  ptrseen: Boolean = False;
begin
  SetLength(Result.ulabels, 0);
  Result.cptr := 0;
  offset := 0;

  if nm = '' then exit;
  DomainNameToLabels(nm, tsl);
  if tsl.Count = 0 then exit;

  dmn := '';
  cmpoffset := 0;

  {
  for a domain a.b.c, using the lookup table,
   -> lookup (a.b.c), if not found, add to table,
   ->   lookup (b.c), if not found, add to table,
   ->   lookup   (c), if not found, add to table,

   buf if any label domain is found, add the pointer to the buffer and stop.
  }
  repeat
    dmn := tsl.DelimitedText;
    ptrseen := LookupStr(dmn, ctbl, cmpoffset);
    if ptrseen then
    begin
      // found the domain name. add a pointer, then we're done. Per RFC1035,
      // section 4.1.4, a domain name is either a series of labels, a pointer,
      // or a series of labels ending with a pointer. There's just one pointer
      // for a domain name.
      Result.cptr := cmpoffset;
      break;
    end
    else
    begin
      // add the last full domain we looked up, not the working label,
      // to the compression lookup table. E.g, add a.b.c rather than a.
      // Add 12 for the dns header, which our buffer doesn't include, but
      // api methods like stringfromlabel adjust offsets to account for it.
      if Length(dmn) > 0 then AddStr(dmn, ctbl, offset+12);
      // write the label to the buffer
      dmn := tsl[0];
      tsl.Delete(0);
      SetLength(Result.ulabels, (Length(Result.ulabels) + Length(dmn)+1));
      Result.ulabels[offset] := Length(dmn);
      Inc(offset);
      Move(dmn[1], Result.ulabels[offset], Length(dmn));
      Inc(offset, Length(dmn));
    end;
  until tsl.Count = 0;

  // if we didn't see a pointer then we have to write a 0. see rfc1035, s4.1.4.
  if not ptrseen then
  begin
    SetLength(Result.ulabels, Length(Result.ulabels) + 1);
    Result.ulabels[offset] := 0;
    Inc(offset);
  end;
end;

{
This version of DomainNameToByteStream doesn't compress.
}
function TNetDbTest.DomainNameToByteStream(nm: ShortString
  ): TDNSDomainByteStream;
var
  dmn: ShortString;
  offset: Word;
begin
  SetLength(Result.ulabels, 0);
  Result.cptr := 0;
  offset := 0;

  if nm = '' then exit;
  DomainNameToLabels(nm, tsl);
  if tsl.Count = 0 then exit;

  for dmn in tsl do
  begin
    SetLength(Result.ulabels, (Length(Result.ulabels) + Length(dmn)+1));
    Result.ulabels[offset] := Length(dmn);
    Inc(offset);
    Move(dmn[1], Result.ulabels[offset], Length(dmn));
    Inc(offset, Length(dmn));
  end;

  SetLength(Result.ulabels, Length(Result.ulabels) + 1);
  Result.ulabels[offset] := 0;
end;

function TNetDbTest.WriteDNSDomainByteStreamToBuffer(var buf: TBuffer;
  var offset: Cardinal; dbs: TDNSDomainByteStream): Word;
var
  p: TDNSDomainPointer;
  so: Word;
begin
  Result := 0;
  // no label, no pointer, no write for you.
  if (Length(dbs.ulabels) = 0) and (dbs.cptr = 0) then exit;
  if (offset + CalcRdLength(dbs)) > Length(buf) then exit;

  so := offset;
  // labels can be empty, in which case we're writing just a pointer.
  if Length(dbs.ulabels) > 0 then
  begin
    Move(dbs.ulabels[0], buf[offset], Length(dbs.ulabels));
    Inc(offset, Length(dbs.ulabels));
  end;
  if dbs.cptr > 0 then
  begin
    p := GetDnsDomainPointer(dbs.cptr);
    Move(p.ba, buf[offset], Length(p.ba));
    Inc(offset, Min(Length(p.ba), (Length(buf) - offset)));
  end;
  Result := offset - so;
end;

{
Write a domain name as RDATA. This means an RDLength (Word) and the
domain labels.
}
function TNetDbTest.WriteDomainAsRdata(var buf: TBuffer; var offset: Cardinal;
  dbs: TDNSDomainByteStream): TRDataWriteRes;
var
  s,l: Word;
begin
  l := CalcRdLength(dbs);
  Result.etw := l + 2;
  s := offset;
  WriteNumToBuffer(buf, offset,l);
  WriteDNSDomainByteStreamToBuffer(buf, offset, dbs);
  Result.bw := offset - s;
end;


procedure TNetDbTest.BuildFakeResponseA(nm: ShortString; out
  fr: TFakeDNSResponse);
begin
  // metadata
  SetLength(fr.strtable, 0);

  // start by building a fake header.
  fr.hdr.ID[0] := 12;
  fr.hdr.ID[1] := 34;
  fr.hdr.flags1 := QF_QR or QF_RD;
  fr.hdr.flags2 := 0;
  fr.hdr.qdcount := 1;
  fr.hdr.ancount := 2;
  fr.hdr.nscount := 0;
  fr.hdr.arcount := 0;

  // Next is the query part
  fr.qry.nm := nm;
  fr.qry.qclass := 1;
  fr.qry.qtype := DNSQRY_A;

  // now the answer RRs
  SetLength(fr.answers,2);
  BuildFakeRR_A(fr.answers[0], nm, 300, '127.0.0.1');
  BuildFakeRR_A(fr.answers[1], nm, 215, '127.0.5.1');
end;

procedure TNetDbTest.BuildFakeResponseAAAA(nm: ShortString; out
  fr: TFakeDNSResponse);
begin
  // metadata
  SetLength(fr.strtable, 0);

  // start by building a fake header.
  fr.hdr.ID[0] := 12;
  fr.hdr.ID[1] := 34;
  fr.hdr.flags1 := QF_QR or QF_RD;
  fr.hdr.flags2 := 0;
  fr.hdr.qdcount := 1;
  fr.hdr.ancount := 2;
  fr.hdr.nscount := 0;
  fr.hdr.arcount := 0;

  // Next is the query part
  fr.qry.nm := nm;
  fr.qry.qclass := 1;
  fr.qry.qtype := DNSQRY_AAAA;

  // now the answer RRs
  SetLength(fr.answers,2);
  BuildFakeRR_AAAA(fr.answers[0], nm, 300, 'fe80::3b92:3429:ff16:a3e4');
  BuildFakeRR_AAAA(fr.answers[1], nm, 215, 'fe80::92e6:baff:fe44:ffbb');
end;

procedure TNetDbTest.BuildFakeResponseMX(nm: ShortString; out
  fr: TFakeDNSResponse);
begin
  // metadata
  SetLength(fr.strtable, 0);

  // start by building a fake header.
  fr.hdr.ID[0] := 12;
  fr.hdr.ID[1] := 34;
  fr.hdr.flags1 := QF_QR or QF_RD;
  fr.hdr.flags2 := 0;
  fr.hdr.qdcount := 1;
  fr.hdr.ancount := 1;
  fr.hdr.nscount := 0;
  fr.hdr.arcount := 2;

  // Next is the query part
  fr.qry.nm := nm;
  fr.qry.qclass := 1;
  fr.qry.qtype := DNSQRY_MX;

  // now the answer RRs
  SetLength(fr.answers,1);
  BuildFakeRR_MX(fr.answers[0], nm, 0, 10, 'mailer.'+FAKEFQDN);
  // now an additional rr with the A record for the above.
  SetLength(fr.additional, 2);
  BuildFakeRR_A(fr.additional[0], 'mailer.'+FAKEFQDN, 0,
    '172.16.27.238');
  BuildFakeRR_AAAA(fr.additional[1], 'mailer.'+FAKEFQDN, 0,
    'fe80::3b92:3429:ff16:a3e4');
end;

procedure TNetDbTest.BuildFakeResponseSOA(nm: ShortString; out
  fr: TFakeDNSResponse);
begin
  // metadata
  SetLength(fr.strtable, 0);

  // start by building a fake header.
  fr.hdr.ID[0] := 12;
  fr.hdr.ID[1] := 34;
  fr.hdr.flags1 := QF_QR or QF_RD;
  fr.hdr.flags2 := 0;
  fr.hdr.qdcount := 1;
  fr.hdr.ancount := 1;
  fr.hdr.nscount := 0;
  fr.hdr.arcount := 0;

  // Next is the query part
  fr.qry.nm := nm;
  fr.qry.qclass := 1;
  fr.qry.qtype := DNSQRY_SOA;
  // now the answer RRs
  SetLength(fr.answers,1);
  BuildFakeRR_SOA(fr.answers[0],FAKEFQDN,33,
    'mn.'+FAKEFQDN,'rn.'+FAKEFQDN,76543210,
      123,456,789,60);
end;

procedure TNetDbTest.BuildFakeResponseCNAME(nm: ShortString; out
  fr: TFakeDNSResponse);
begin
  // metadata
  SetLength(fr.strtable, 0);

  // start by building a fake header.
  fr.hdr.ID[0] := 12;
  fr.hdr.ID[1] := 34;
  fr.hdr.flags1 := QF_QR or QF_RD;
  fr.hdr.flags2 := 0;
  fr.hdr.qdcount := 1;
  fr.hdr.ancount := 1;
  fr.hdr.nscount := 0;
  fr.hdr.arcount := 0;

  // Next is the query part
  fr.qry.nm := nm;
  fr.qry.qclass := 1;
  fr.qry.qtype := DNSQRY_CNAME;

  // now the answer RRs
  SetLength(fr.answers,1);
  BuildFakeRR_CNAME(fr.answers[0], nm, 300, 'fakecname.'+FAKEFQDN);
end;

procedure TNetDbTest.BuildFakeResponseNS(nm: ShortString; out
  fr: TFakeDNSResponse);
begin
  // metadata
  SetLength(fr.strtable, 0);

  // start by building a fake header.
  fr.hdr.ID[0] := 12;
  fr.hdr.ID[1] := 34;
  fr.hdr.flags1 := QF_QR or QF_RD;
  fr.hdr.flags2 := 0;
  fr.hdr.qdcount := 1;
  fr.hdr.ancount := 1;
  fr.hdr.nscount := 0;
  fr.hdr.arcount := 0;

  // Next is the query part
  fr.qry.nm := nm;
  fr.qry.qclass := 1;
  fr.qry.qtype := DNSQRY_NS;

  // now the answer RRs
  SetLength(fr.answers,1);
  BuildFakeRR_NS(fr.answers[0], nm, 300, 'fakens.'+FAKEFQDN);
end;

procedure TNetDbTest.BuildFakeResponsePTR(nm: ShortString; out
  fr: TFakeDNSResponse);
begin
  // metadata
  SetLength(fr.strtable, 0);

  // start by building a fake header.
  fr.hdr.ID[0] := 12;
  fr.hdr.ID[1] := 34;
  fr.hdr.flags1 := QF_QR or QF_RD;
  fr.hdr.flags2 := 0;
  fr.hdr.qdcount := 1;
  fr.hdr.ancount := 1;
  fr.hdr.nscount := 0;
  fr.hdr.arcount := 0;

  // Next is the query part
  fr.qry.nm := nm;
  fr.qry.qclass := 1;
  fr.qry.qtype := DNSQRY_PTR;

  // now the answer RRs
  SetLength(fr.answers,1);
  BuildFakeRR_PTR(fr.answers[0], nm, 300, 'fakeptrans.'+FAKEFQDN);
end;

procedure TNetDbTest.BuildFakeResponseTXT(nm: ShortString; out
  fr: TFakeDNSResponse);
var
  txtarr: TTextArray;
begin
  // metadata
  SetLength(fr.strtable, 0);

  // start by building a fake header.
  fr.hdr.ID[0] := 12;
  fr.hdr.ID[1] := 34;
  fr.hdr.flags1 := QF_QR or QF_RD;
  fr.hdr.flags2 := 0;
  fr.hdr.qdcount := 1;
  fr.hdr.ancount := 1;
  fr.hdr.nscount := 0;
  fr.hdr.arcount := 0;

  // Next is the query part
  fr.qry.nm := nm;
  fr.qry.qclass := 1;
  fr.qry.qtype := DNSQRY_TXT;

  txtarr[1] := 'v=spf1 mx a:lists.'+FAKEFQDN;
  txtarr[2] := 'Always look on the bright side of life!';
  // now the answer RRs
  SetLength(fr.answers,1);
  BuildFakeRR_TXT(fr.answers[0], nm, 300, 2, txtarr);
end;

procedure TNetDbTest.BuildFakeResponseSRV(nm: ShortString; out
  fr: TFakeDNSResponse);
begin
  // metadata
  SetLength(fr.strtable, 0);

  // start by building a fake header.
  fr.hdr.ID[0] := 12;
  fr.hdr.ID[1] := 34;
  fr.hdr.flags1 := QF_QR or QF_RD;
  fr.hdr.flags2 := 0;
  fr.hdr.qdcount := 1;
  fr.hdr.ancount := 1;
  fr.hdr.nscount := 0;
  fr.hdr.arcount := 0;

  // Next is the query part
  fr.qry.nm := nm;
  fr.qry.qclass := 1;
  fr.qry.qtype := DNSQRY_SRV;
  // now the answer RRs
  SetLength(fr.answers,1);
  BuildFakeRR_SRV(fr.answers[0],FAKEFQDN,3300,22,44,2201,'_this._that._other');
end;

{
Test that BuildPayload puts the right values into the payload buffer.
}
procedure TNetDbTest.TestBuildPayloadSimple;
var
  Q: TQueryData;
  R, I,J,el: Integer;
  S: String;
begin
  R := BuildPayLoad(Q, FAKEFQDN, DNSQRY_A, 1);
  // this is the expected length. Essentially, for each label, len(label)+1,
  // then 4 bytes for the qclass and qtype, and 1 more for a 0 byte.
  // rather than hardwire the length we calculate it so that no matter
  // what the fake domain the test passes.
  el := (Length(FAKEDOMAIN)+1)+(Length(FAKETLD)+1)+5;
  TestContext.AssertTrue((el)=(R), 'Payload byte count wrong:');
  I := 0;
  J := 0;
  S := stringfromlabel(Q.Payload,I);
  TestContext.AssertTrue((FAKEFQDN)=(S), 'Wrong domain name returned:');
  Move(Q.Payload[I],J,SizeOf(Word));
  TestContext.AssertTrue((DNSQRY_A)=(NToHs(J)), 'Wrong query type');
  Inc(I,2);
  Move(Q.Payload[I],J,SizeOf(Word));
  TestContext.AssertTrue((1)=(NToHs(J)), 'Wrong class');
end;

{
Test building a payload with an empty str.
}
procedure TNetDbTest.TestBuildPayloadSimpleEmpty;
var
  Q: TQueryData;
  R: Integer;
begin
  R := BuildPayLoad(Q, '', DNSQRY_A, 1);
  TestContext.AssertTrue((-1)=(R), 'Payload byte count wrong:');
end;

{
Test BuildQuery with a label that ends in a dot. This should be allowed.
A dot at the end is an empty label but we must not count its 0 byte twice.
}
procedure TNetDbTest.TestBuildPayloadSimpleEndDot;
var
  Q: TQueryData;
  R,el: Integer;
begin
  // this is the expected length. Essentially, for each label, len(label)+1,
  // then 4 bytes for the qclass and qtype, and 1 more for a 0 byte.
  // rather than hardwire the length we calculate it so that no matter
  // what the fake domain the test passes.
  el := (Length(FAKEDOMAIN)+1)+(Length(FAKETLD)+1)+5;
  R := BuildPayLoad(Q, FAKEFQDN+'.', DNSQRY_A, 1);
  TestContext.AssertTrue((el)=(R), 'Payload byte count wrong:');
end;

{
Test BuildPayload with a label that starts with a dot. This should be
rejected outright.
}
procedure TNetDbTest.TestBuildPayloadSimpleStartDot;
var
  Q: TQueryData;
  R: Integer;
begin
  R := BuildPayLoad(Q, '.'+FAKEFQDN, DNSQRY_A, 1);
  TestContext.AssertTrue((-1)=(R), 'Payload byte count wrong:');
end;

{
Test BuildPayload with multiple dots (empty labels) in the middle of the domain
name. This should be rejected outright.
}
procedure TNetDbTest.TestBuildPayloadSimpleMultipleDot;
var
  Q: TQueryData;
  R: Integer;
begin
  R := BuildPayLoad(Q, FAKEDOMAIN+'.....'+FAKETLD, DNSQRY_A, 1);
  TestContext.AssertTrue((-1)=(R), 'Payload byte count wrong:');
end;

procedure TNetDbTest.TestDnsQueryUDP_A;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  ip: THostAddr;
begin
  BuildFakeResponseA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((2)=(qd.h.ancount), 'Wrong number of A records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((2)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_A)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an A RR.');
  TestContext.AssertTrue((DNSQRY_A)=(RRarr[1].RRMeta.Atype), 'RR 1 is not an A RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong A record name for RR 0');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[1].RRName), 'Wrong A record name for RR 1');
  TestContext.AssertTrue(DNSRRGetA(RRArr[0], qd.Payload, ip), 'Did not get RR A data.');
  TestContext.AssertTrue(('127.0.0.1')=(HostAddrToStr(ip)), 'Wrong ip for A.');
  TestContext.AssertTrue(DNSRRGetA(RRArr[1], qd.Payload, ip), 'Did not get RR A data.');
  TestContext.AssertTrue(('127.0.5.1')=(HostAddrToStr(ip)), 'Wrong ip for A.');
end;

procedure TNetDbTest.TestDnsQueryTCP_A;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  ip: THostAddr;
begin
  BuildFakeResponseA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((2)=(qd.h.ancount), 'Wrong number of A records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((2)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_A)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an A RR.');
  TestContext.AssertTrue((DNSQRY_A)=(RRarr[1].RRMeta.Atype), 'RR 1 is not an A RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong A record name for RR 0');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[1].RRName), 'Wrong A record name for RR 1');
  TestContext.AssertTrue(DNSRRGetA(RRArr[0], qd.Payload, ip), 'Did not get RR A data.');
  TestContext.AssertTrue(('127.0.0.1')=(HostAddrToStr(ip)), 'Wrong ip for A.');
  TestContext.AssertTrue(DNSRRGetA(RRArr[1], qd.Payload, ip), 'Did not get RR A data.');
  TestContext.AssertTrue(('127.0.5.1')=(HostAddrToStr(ip)), 'Wrong ip for A.');
end;

procedure TNetDbTest.TestDnsQueryCompressUDP_A;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  ip: THostAddr;
begin
  BuildFakeResponseA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen, True), 'Unable to convert fake dns response to compressed querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((2)=(qd.h.ancount), 'Wrong number of A records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((2)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_A)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an A RR.');
  TestContext.AssertTrue((DNSQRY_A)=(RRarr[1].RRMeta.Atype), 'RR 1 is not an A RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong A record name for RR 0');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[1].RRName), 'Wrong A record name for RR 1');
  TestContext.AssertTrue(DNSRRGetA(RRArr[0], qd.Payload, ip), 'Did not get RR A data.');
  TestContext.AssertTrue(('127.0.0.1')=(HostAddrToStr(ip)), 'Wrong ip for A.');
  TestContext.AssertTrue(DNSRRGetA(RRArr[1], qd.Payload, ip), 'Did not get RR A data.');
  TestContext.AssertTrue(('127.0.5.1')=(HostAddrToStr(ip)), 'Wrong ip for A.');
end;

procedure TNetDbTest.TestDnsQueryCompressTCP_A;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  ip: THostAddr;
begin
  BuildFakeResponseA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen, True), 'Unable to convert fake dns response to compressed querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((2)=(qd.h.ancount), 'Wrong number of A records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((2)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_A)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an A RR.');
  TestContext.AssertTrue((DNSQRY_A)=(RRarr[1].RRMeta.Atype), 'RR 1 is not an A RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong A record name for RR 0');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[1].RRName), 'Wrong A record name for RR 1');
  TestContext.AssertTrue(DNSRRGetA(RRArr[0], qd.Payload, ip), 'Did not get RR A data.');
  TestContext.AssertTrue(('127.0.0.1')=(HostAddrToStr(ip)), 'Wrong ip for A.');
  TestContext.AssertTrue(DNSRRGetA(RRArr[1], qd.Payload, ip), 'Did not get RR A data.');
  TestContext.AssertTrue(('127.0.5.1')=(HostAddrToStr(ip)), 'Wrong ip for A.');
end;

procedure TNetDbTest.TestDnsQueryUDP_AAAA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  ip: THostAddr6;
begin
  BuildFakeResponseAAAA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((2)=(qd.h.ancount), 'Wrong number of AAAA records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((2)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_AAAA)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an AAAA RR.');
  TestContext.AssertTrue((DNSQRY_AAAA)=(RRarr[1].RRMeta.Atype), 'RR 1 is not an AAAA RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong AAAA record name for RR 0');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[1].RRName), 'Wrong AAAA record name for RR 1');
  TestContext.AssertTrue(DNSRRGetAAAA(RRArr[0], qd.Payload, ip), 'Did not get RR AAAA data.');
  TestContext.AssertTrue(('FE80::3B92:3429:FF16:A3E4')=(HostAddrToStr6(ip)), 'Wrong ip for AAAA.');
  TestContext.AssertTrue(DNSRRGetAAAA(RRArr[1], qd.Payload, ip), 'Did not get RR AAAA data.');
  TestContext.AssertTrue(('FE80::92E6:BAFF:FE44:FFBB')=(HostAddrToStr6(ip)), 'Wrong ip for AAAA.');
end;

procedure TNetDbTest.TestDnsQueryTCP_AAAA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  ip: THostAddr6;
begin
  BuildFakeResponseAAAA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((2)=(qd.h.ancount), 'Wrong number of AAAA records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((2)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_AAAA)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an AAAA RR.');
  TestContext.AssertTrue((DNSQRY_AAAA)=(RRarr[1].RRMeta.Atype), 'RR 1 is not an AAAA RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong AAAA record name for RR 0');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[1].RRName), 'Wrong AAAA record name for RR 1');
  TestContext.AssertTrue(DNSRRGetAAAA(RRArr[0],
    qd.Payload, ip), 'Did not get RR AAAA data.');
  TestContext.AssertTrue(('FE80::3B92:3429:FF16:A3E4')=(HostAddrToStr6(ip)), 'Wrong ip for AAAA.');
  TestContext.AssertTrue(DNSRRGetAAAA(RRArr[1],
    qd.Payload, ip), 'Did not get RR AAAA data.');
  TestContext.AssertTrue(('FE80::92E6:BAFF:FE44:FFBB')=(HostAddrToStr6(ip)), 'Wrong ip for AAAA.');
end;

procedure TNetDbTest.TestDnsQueryCompressUDP_AAAA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  ip: THostAddr6;
begin
  BuildFakeResponseAAAA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen, True), 'Unable to convert fake dns response to compressed querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((2)=(qd.h.ancount), 'Wrong number of AAAA records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((2)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_AAAA)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an AAAA RR.');
  TestContext.AssertTrue((DNSQRY_AAAA)=(RRarr[1].RRMeta.Atype), 'RR 1 is not an AAAA RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong AAAA record name for RR 0');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[1].RRName), 'Wrong AAAA record name for RR 1');
  TestContext.AssertTrue(DNSRRGetAAAA(RRArr[0],
    qd.Payload, ip), 'Did not get RR AAAA data.');
  TestContext.AssertTrue(('FE80::3B92:3429:FF16:A3E4')=(HostAddrToStr6(ip)), 'Wrong ip for AAAA.');
  TestContext.AssertTrue(DNSRRGetAAAA(RRArr[1],
    qd.Payload, ip), 'Did not get RR AAAA data.');
  TestContext.AssertTrue(('FE80::92E6:BAFF:FE44:FFBB')=(HostAddrToStr6(ip)), 'Wrong ip for AAAA.');
end;

procedure TNetDbTest.TestDnsQueryCompressTCP_AAAA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  ip: THostAddr6;
begin
  BuildFakeResponseAAAA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen, True), 'Unable to convert fake dns response to compressed querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((2)=(qd.h.ancount), 'Wrong number of AAAA records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((2)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_AAAA)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an AAAA RR.');
  TestContext.AssertTrue((DNSQRY_AAAA)=(RRarr[1].RRMeta.Atype), 'RR 1 is not an AAAA RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong AAAA record name for RR 0');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[1].RRName), 'Wrong AAAA record name for RR 1');
  TestContext.AssertTrue(DNSRRGetAAAA(RRArr[0],
    qd.Payload, ip), 'Did not get RR AAAA data.');
  TestContext.AssertTrue(('FE80::3B92:3429:FF16:A3E4')=(HostAddrToStr6(ip)), 'Wrong ip for AAAA.');
  TestContext.AssertTrue(DNSRRGetAAAA(RRArr[1],
    qd.Payload, ip), 'Did not get RR AAAA data.');
  TestContext.AssertTrue(('FE80::92E6:BAFF:FE44:FFBB')=(HostAddrToStr6(ip)), 'Wrong ip for AAAA.');
end;

procedure TNetDbTest.TestDnsQueryUDP_MX;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  mxrec: TDNSRR_MX;
  ip: THostAddr;
  ip6: THostAddr6;
begin
  BuildFakeResponseMX(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of MX records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_MX)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an MX RR.');

  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong record name for RR 0');

  TestContext.AssertTrue(DNSRRGetMX(RRArr[0], qd.Payload, mxrec), 'Did not get RR MX data.');
  TestContext.AssertTrue(('mailer.'+FAKEFQDN)=(mxrec.exchange), 'Wrong MX hostname');
  TestContext.AssertTrue((10)=(mxrec.preference), 'Wrong MX preference');

  TestContext.AssertTrue((2)=(NToHs(qd.h.arcount)), 'Should be 2 additional RR records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, NToHs(qd.h.arcount));
  TestContext.AssertTrue((2)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_A)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an A RR.');
  TestContext.AssertTrue((DNSQRY_AAAA)=(RRarr[1].RRMeta.Atype), 'RR 1 is not an AAAA RR.');
  TestContext.AssertTrue(DNSRRGetA(RRArr[0], qd.Payload, ip), 'Did not get RR A data.');
  TestContext.AssertTrue(DNSRRGetAAAA(RRArr[1], qd.Payload, ip6), 'Did not get RR AAAA data.');

  TestContext.AssertTrue(('172.16.27.238')=(HostAddrToStr(ip)), 'Wrong ip for A.');
  TestContext.AssertTrue(('FE80::3B92:3429:FF16:A3E4')=(HostAddrToStr6(ip6)), 'Wrong ip for AAAA.');
end;

procedure TNetDbTest.TestDnsQueryTCP_MX;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  mxrec: TDNSRR_MX;
  ip: THostAddr;
  ip6: THostAddr6;
begin
  BuildFakeResponseMX(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of MX records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_MX)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an MX RR.');

  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong record name for RR 0');

  TestContext.AssertTrue(DNSRRGetMX(RRArr[0], qd.Payload, mxrec), 'Did not get RR MX data.');
  TestContext.AssertTrue(('mailer.'+FAKEFQDN)=(mxrec.exchange), 'Wrong MX hostname');
  TestContext.AssertTrue((10)=(mxrec.preference), 'Wrong MX preference');

  TestContext.AssertTrue((2)=(NToHs(qd.h.arcount)), 'Should be 2 additional RR records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, NToHs(qd.h.arcount));
  TestContext.AssertTrue((2)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_A)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an A RR.');
  TestContext.AssertTrue((DNSQRY_AAAA)=(RRarr[1].RRMeta.Atype), 'RR 1 is not an AAAA RR.');
  TestContext.AssertTrue(DNSRRGetA(RRArr[0], qd.Payload, ip), 'Did not get RR A data.');
  TestContext.AssertTrue(DNSRRGetAAAA(RRArr[1], qd.Payload, ip6), 'Did not get RR AAAA data.');

  TestContext.AssertTrue(('172.16.27.238')=(HostAddrToStr(ip)), 'Wrong ip for A.');
  TestContext.AssertTrue(('FE80::3B92:3429:FF16:A3E4')=(HostAddrToStr6(ip6)), 'Wrong ip for AAAA.');
end;

procedure TNetDbTest.TestDnsQueryCompressUDP_MX;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  mxrec: TDNSRR_MX;
  ip: THostAddr;
  ip6: THostAddr6;
begin
  BuildFakeResponseMX(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen, True), 'Unable to convert fake dns response to compressed querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of MX records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_MX)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an MX RR.');

  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong record name for RR 0');

  TestContext.AssertTrue(DNSRRGetMX(RRArr[0], qd.Payload, mxrec), 'Did not get RR MX data.');
  TestContext.AssertTrue(('mailer.'+FAKEFQDN)=(mxrec.exchange), 'Wrong MX hostname');
  TestContext.AssertTrue((10)=(mxrec.preference), 'Wrong MX preference');

  TestContext.AssertTrue((2)=(NToHs(qd.h.arcount)), 'Should be 2 additional RR records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, NToHs(qd.h.arcount));
  TestContext.AssertTrue((2)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_A)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an A RR.');
  TestContext.AssertTrue((DNSQRY_AAAA)=(RRarr[1].RRMeta.Atype), 'RR 1 is not an AAAA RR.');
  TestContext.AssertTrue(DNSRRGetA(RRArr[0], qd.Payload, ip), 'Did not get RR A data.');
  TestContext.AssertTrue(DNSRRGetAAAA(RRArr[1], qd.Payload,
    ip6), 'Did not get RR AAAA data.');

  TestContext.AssertTrue(('172.16.27.238')=(HostAddrToStr(ip)), 'Wrong ip for A.');
  TestContext.AssertTrue(('FE80::3B92:3429:FF16:A3E4')=(HostAddrToStr6(ip6)), 'Wrong ip for AAAA.');
end;

procedure TNetDbTest.TestDnsQueryCompressTCP_MX;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  mxrec: TDNSRR_MX;
  ip: THostAddr;
  ip6: THostAddr6;
begin
  BuildFakeResponseMX(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen, True), 'Unable to convert fake dns response to compressed querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of MX records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_MX)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an MX RR.');

  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong record name for RR 0');

  TestContext.AssertTrue(DNSRRGetMX(RRArr[0], qd.Payload, mxrec), 'Did not get RR MX data.');
  TestContext.AssertTrue(('mailer.'+FAKEFQDN)=(mxrec.exchange), 'Wrong MX hostname');
  TestContext.AssertTrue((10)=(mxrec.preference), 'Wrong MX preference');

  TestContext.AssertTrue((2)=(NToHs(qd.h.arcount)), 'Should be 2 additional RR records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, NToHs(qd.h.arcount));
  TestContext.AssertTrue((2)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_A)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an A RR.');
  TestContext.AssertTrue((DNSQRY_AAAA)=(RRarr[1].RRMeta.Atype), 'RR 1 is not an AAAA RR.');
  TestContext.AssertTrue(DNSRRGetA(RRArr[0], qd.Payload, ip), 'Did not get RR A data.');
  TestContext.AssertTrue(DNSRRGetAAAA(RRArr[1], qd.Payload,
    ip6), 'Did not get RR AAAA data.');

  TestContext.AssertTrue(('172.16.27.238')=(HostAddrToStr(ip)), 'Wrong ip for A.');
  TestContext.AssertTrue(('FE80::3B92:3429:FF16:A3E4')=(HostAddrToStr6(ip6)), 'Wrong ip for AAAA.');
end;

procedure TNetDbTest.TestDnsQueryUDP_SOA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  soarec: TDNSRR_SOA;
begin
  BuildFakeResponseSOA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of SOA records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_SOA)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an SOA RR.');

  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong record name for RR 0');

  TestContext.AssertTrue(DNSRRGetSOA(RRArr[0], qd.Payload,
    soarec), 'Did not get RR SOA data.');
  TestContext.AssertTrue(('mn.'+FAKEFQDN)=(soarec.mname), 'Wrong mname hostname');
  TestContext.AssertTrue(('rn.'+FAKEFQDN)=(soarec.rname), 'Wrong rname hostname');
  TestContext.AssertTrue((76543210)=(soarec.serial), 'Wrong SOA serial');
  TestContext.AssertTrue((123)=(soarec.refresh), 'Wrong SOA refresh');
  TestContext.AssertTrue((456)=(soarec.retry), 'Wrong SOA retry');
  TestContext.AssertTrue((789)=(soarec.expire), 'Wrong SOA expire');
  TestContext.AssertTrue((60)=(soarec.min), 'Wrong SOA min');
end;

procedure TNetDbTest.TestDnsQueryTCP_SOA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  soarec: TDNSRR_SOA;
begin
  BuildFakeResponseSOA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of SOA records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_SOA)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an SOA RR.');

  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong record name for RR 0');

  TestContext.AssertTrue(DNSRRGetSOA(RRArr[0], qd.Payload,
    soarec), 'Did not get RR SOA data.');
  TestContext.AssertTrue(('mn.'+FAKEFQDN)=(soarec.mname), 'Wrong mname hostname');
  TestContext.AssertTrue(('rn.'+FAKEFQDN)=(soarec.rname), 'Wrong rname hostname');
  TestContext.AssertTrue((76543210)=(soarec.serial), 'Wrong SOA serial');
  TestContext.AssertTrue((123)=(soarec.refresh), 'Wrong SOA refresh');
  TestContext.AssertTrue((456)=(soarec.retry), 'Wrong SOA retry');
  TestContext.AssertTrue((789)=(soarec.expire), 'Wrong SOA expire');
  TestContext.AssertTrue((60)=(soarec.min), 'Wrong SOA min');
end;

procedure TNetDbTest.TestDnsQueryCompressUDP_SOA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  soarec: TDNSRR_SOA;
begin
  BuildFakeResponseSOA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen, True), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of SOA records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_SOA)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an SOA RR.');

  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong record name for RR 0');

  TestContext.AssertTrue(DNSRRGetSOA(RRArr[0], qd.Payload,
    soarec), 'Did not get RR SOA data.');
  TestContext.AssertTrue(('mn.'+FAKEFQDN)=(soarec.mname), 'Wrong mname hostname');
  TestContext.AssertTrue(('rn.'+FAKEFQDN)=(soarec.rname), 'Wrong rname hostname');
  TestContext.AssertTrue((76543210)=(soarec.serial), 'Wrong SOA serial');
  TestContext.AssertTrue((123)=(soarec.refresh), 'Wrong SOA refresh');
  TestContext.AssertTrue((456)=(soarec.retry), 'Wrong SOA retry');
  TestContext.AssertTrue((789)=(soarec.expire), 'Wrong SOA expire');
  TestContext.AssertTrue((60)=(soarec.min), 'Wrong SOA min');
end;

procedure TNetDbTest.TestDnsQueryCompressTCP_SOA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  soarec: TDNSRR_SOA;
begin
  BuildFakeResponseSOA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen, True), 'Unable to convert fake dns response to compressed querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of SOA records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_SOA)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an SOA RR.');

  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong record name for RR 0');

  TestContext.AssertTrue(DNSRRGetSOA(RRArr[0], qd.Payload,
    soarec), 'Did not get RR SOA data.');
  TestContext.AssertTrue(('mn.'+FAKEFQDN)=(soarec.mname), 'Wrong mname hostname');
  TestContext.AssertTrue(('rn.'+FAKEFQDN)=(soarec.rname), 'Wrong rname hostname');
  TestContext.AssertTrue((76543210)=(soarec.serial), 'Wrong SOA serial');
  TestContext.AssertTrue((123)=(soarec.refresh), 'Wrong SOA refresh');
  TestContext.AssertTrue((456)=(soarec.retry), 'Wrong SOA retry');
  TestContext.AssertTrue((789)=(soarec.expire), 'Wrong SOA expire');
  TestContext.AssertTrue((60)=(soarec.min), 'Wrong SOA min');
end;

procedure TNetDbTest.TestDnsQueryUDP_CNAME;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  BuildFakeResponseCNAME(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of CNAME records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_CNAME)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an CNAME RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong CNAME record name for RR 0');
  TestContext.AssertTrue(DNSRRGetCNAME(RRArr[0], qd.Payload, s), 'Did not get RR CNAME data.');
  TestContext.AssertTrue(('fakecname.'+FAKEFQDN)=(s), 'Wrong CNAME.');
end;

procedure TNetDbTest.TestDnsQueryTCP_CNAME;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  BuildFakeResponseCNAME(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of CNAME records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_CNAME)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an CNAME RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong CNAME record name for RR 0');
  TestContext.AssertTrue(DNSRRGetCNAME(RRArr[0], qd.Payload, s), 'Did not get RR CNAME data.');
  TestContext.AssertTrue(('fakecname.'+FAKEFQDN)=(s), 'Wrong CNAME.');
end;

procedure TNetDbTest.TestDnsQueryCompressUDP_CNAME;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  BuildFakeResponseCNAME(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen, True), 'Unable to convert fake dns response to compressed querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of CNAME records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_CNAME)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an CNAME RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong CNAME record name for RR 0');
  TestContext.AssertTrue(DNSRRGetCNAME(RRArr[0], qd.Payload, s), 'Did not get RR CNAME data.');
  TestContext.AssertTrue(('fakecname.'+FAKEFQDN)=(s), 'Wrong CNAME.');
end;

procedure TNetDbTest.TestDnsQueryCompressTCP_CNAME;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  BuildFakeResponseCNAME(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen, True), 'Unable to convert fake dns response to compressed querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of CNAME records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_CNAME)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an CNAME RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong CNAME record name for RR 0');
  TestContext.AssertTrue(DNSRRGetCNAME(RRArr[0], qd.Payload,
    s), 'Did not get RR CNAME data.');
  TestContext.AssertTrue(('fakecname.'+FAKEFQDN)=(s), 'Wrong CNAME.');
end;

procedure TNetDbTest.TestDnsQueryUDP_NS;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  BuildFakeResponseNS(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of NS records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_NS)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an NS RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong NS record name for RR 0');
  TestContext.AssertTrue(DNSRRGetNS(RRArr[0], qd.Payload, s), 'Did not get RR NS data.');
  TestContext.AssertTrue(('fakens.'+FAKEFQDN)=(s), 'Wrong NS.');
end;

procedure TNetDbTest.TestDnsQueryTCP_NS;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  BuildFakeResponseNS(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of NS records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_NS)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an NS RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong NS record name for RR 0');
  TestContext.AssertTrue(DNSRRGetNS(RRArr[0], qd.Payload, s), 'Did not get RR NS data.');
  TestContext.AssertTrue(('fakens.'+FAKEFQDN)=(s), 'Wrong NS.');
end;

procedure TNetDbTest.TestDnsQueryCompressUDP_NS;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  BuildFakeResponseNS(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen, True), 'Unable to convert fake dns response to compressed querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of NS records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_NS)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an NS RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong NS record name for RR 0');
  TestContext.AssertTrue(DNSRRGetNS(RRArr[0], qd.Payload, s), 'Did not get RR NS data.');
  TestContext.AssertTrue(('fakens.'+FAKEFQDN)=(s), 'Wrong NS.');
end;

procedure TNetDbTest.TestDnsQueryCompressTCP_NS;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  BuildFakeResponseNS(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen, True), 'Unable to convert fake dns response to compressed querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of NS records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_NS)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an NS RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong NS record name for RR 0');
  TestContext.AssertTrue(DNSRRGetNS(RRArr[0], qd.Payload, s), 'Did not get RR NS data.');
  TestContext.AssertTrue(('fakens.'+FAKEFQDN)=(s), 'Wrong NS.');
end;

procedure TNetDbTest.TestDnsQueryUDP_PTR;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  // the str passed in to this function doesn't really matter, but using
  // a proper in-addr.arpa domain helps keep it clear what we're testing.
  BuildFakeResponsePTR('0.5.0.127.in-addr.arpa', fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of PTR records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_PTR)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an PTR RR.');
  TestContext.AssertTrue(('0.5.0.127.in-addr.arpa')=(RRArr[0].RRName), 'Wrong PTR record name for RR 0');
  TestContext.AssertTrue(DNSRRGetPTR(RRArr[0], qd.Payload, s), 'Did not get RR PTR data.');
  TestContext.AssertTrue(('fakeptrans.'+FAKEFQDN)=(s), 'Wrong PTR.');
end;

procedure TNetDbTest.TestDnsQueryTCP_PTR;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  // the str passed in to this function doesn't really matter, but using
  // a proper in-addr.arpa domain helps keep it clear what we're testing.
  BuildFakeResponsePTR('0.5.0.127.in-addr.arpa', fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of PTR records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_PTR)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an PTR RR.');
  TestContext.AssertTrue(('0.5.0.127.in-addr.arpa')=(RRArr[0].RRName), 'Wrong PTR record name for RR 0');
  TestContext.AssertTrue(DNSRRGetPTR(RRArr[0], qd.Payload, s), 'Did not get RR PTR data.');
  TestContext.AssertTrue(('fakeptrans.'+FAKEFQDN)=(s), 'Wrong PTR.');
end;

procedure TNetDbTest.TestDnsQueryCompressUDP_PTR;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  // the str passed in to this function doesn't really matter, but using
  // a proper in-addr.arpa domain helps keep it clear what we're testing.
  BuildFakeResponsePTR('0.5.0.127.in-addr.arpa', fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen, True), 'Unable to convert fake dns response to compressed querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of PTR records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_PTR)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an PTR RR.');
  TestContext.AssertTrue(('0.5.0.127.in-addr.arpa')=(RRArr[0].RRName), 'Wrong PTR record name for RR 0');
  TestContext.AssertTrue(DNSRRGetPTR(RRArr[0], qd.Payload, s), 'Did not get RR PTR data.');
  TestContext.AssertTrue(('fakeptrans.'+FAKEFQDN)=(s), 'Wrong PTR.');
end;

procedure TNetDbTest.TestDnsQueryCompressTCP_PTR;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  // the str passed in to this function doesn't really matter, but using
  // a proper in-addr.arpa domain helps keep it clear what we're testing.
  BuildFakeResponsePTR('0.5.0.127.in-addr.arpa', fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen, True), 'Unable to convert fake dns response to compressed querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of PTR records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_PTR)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an PTR RR.');
  TestContext.AssertTrue(('0.5.0.127.in-addr.arpa')=(RRArr[0].RRName), 'Wrong PTR record name for RR 0');
  TestContext.AssertTrue(DNSRRGetPTR(RRArr[0], qd.Payload, s), 'Did not get RR PTR data.');
  TestContext.AssertTrue(('fakeptrans.'+FAKEFQDN)=(s), 'Wrong PTR.');
end;

procedure TNetDbTest.TestDnsQueryUDP_TXT;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  s: AnsiString;
begin
  s := '';
  BuildFakeResponseTXT(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of TXT records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_TXT)=(RRarr[0].RRMeta.Atype), 'RR 0 is not a TXT RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong TXT record name for RR 0');
  TestContext.AssertTrue(DNSRRGetText(RRArr[0], qd.Payload, s), 'Did not get RR TXT data.');
  TestContext.AssertTrue(('v=spf1 mx a:lists.'+FAKEFQDN+'Always look on the bright side of life!')=(s), '');
end;

procedure TNetDbTest.TestDnsQueryTCP_TXT;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  s: AnsiString;
begin
  s := '';
  BuildFakeResponseTXT(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of TXT records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_TXT)=(RRarr[0].RRMeta.Atype), 'RR 0 is not a TXT RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong TXT record name for RR 0');
  TestContext.AssertTrue(DNSRRGetText(RRArr[0], qd.Payload, s), 'Did not get RR TXT data.');
  TestContext.AssertTrue(('v=spf1 mx a:lists.'+FAKEFQDN+'Always look on the bright side of life!')=(s), '');
end;

procedure TNetDbTest.TestDnsQueryCompressUDP_TXT;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  s: AnsiString;
begin
  s := '';
  BuildFakeResponseTXT(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen, True), 'Unable to convert fake dns response to compressed querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of TXT records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_TXT)=(RRarr[0].RRMeta.Atype), 'RR 0 is not a TXT RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong TXT record name for RR 0');
  TestContext.AssertTrue(DNSRRGetText(RRArr[0], qd.Payload, s), 'Did not get RR TXT data.');
  TestContext.AssertTrue(('v=spf1 mx a:lists.'+FAKEFQDN+'Always look on the bright side of life!')=(s), '');
end;

procedure TNetDbTest.TestDnsQueryCompressTCP_TXT;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  s: AnsiString;
begin
  s := '';
  BuildFakeResponseTXT(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen, True), 'Unable to convert fake dns response to compressed querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of TXT records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_TXT)=(RRarr[0].RRMeta.Atype), 'RR 0 is not a TXT RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong TXT record name for RR 0');
  TestContext.AssertTrue(DNSRRGetText(RRArr[0], qd.Payload, s), 'Did not get RR TXT data.');
  TestContext.AssertTrue(('v=spf1 mx a:lists.'+FAKEFQDN+'Always look on the bright side of life!')=(s), '');
end;

procedure TNetDbTest.TestDnsQueryUDP_SRV;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  srvrec: TDNSRR_SRV;
begin
  BuildFakeResponseSRV(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of SRV records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_SRV)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an SRV RR.');

  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong record name for RR 0');

  TestContext.AssertTrue(DNSRRGetSRV(RRArr[0], qd.Payload,
    srvrec), 'Did not get RR SRV data.');
  TestContext.AssertTrue((22)=(srvrec.priority), 'Wrong SRV priority');
  TestContext.AssertTrue((44)=(srvrec.weight), 'Wrong SRV weight');
  TestContext.AssertTrue((2201)=(srvrec.port), 'Wrong SRV port');

  TestContext.AssertTrue(('_this._that._other')=(srvrec.target), 'Wrong SRV hostname');
end;

procedure TNetDbTest.TestDnsQueryTCP_SRV;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  srvrec: TDNSRR_SRV;
begin
  BuildFakeResponseSRV(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of SRV records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_SRV)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an SRV RR.');

  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong record name for RR 0');

  TestContext.AssertTrue(DNSRRGetSRV(RRArr[0], qd.Payload,
    srvrec), 'Did not get RR SOA data.');
  TestContext.AssertTrue((22)=(srvrec.priority), 'Wrong SRV priority');
  TestContext.AssertTrue((44)=(srvrec.weight), 'Wrong SRV weight');
  TestContext.AssertTrue((2201)=(srvrec.port), 'Wrong SRV port');

  TestContext.AssertTrue(('_this._that._other')=(srvrec.target), 'Wrong SRV hostname');
end;

procedure TNetDbTest.TestDnsQueryCompressUDP_SRV;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  srvrec: TDNSRR_SRV;
begin
  BuildFakeResponseSRV(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen, True), 'Unable to convert fake dns response to compressed querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of SRV records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_SRV)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an SRV RR.');

  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong record name for RR 0');

  TestContext.AssertTrue(DNSRRGetSRV(RRArr[0], qd.Payload,
    srvrec), 'Did not get RR SRV data.');
  TestContext.AssertTrue((22)=(srvrec.priority), 'Wrong SRV priority');
  TestContext.AssertTrue((44)=(srvrec.weight), 'Wrong SRV weight');
  TestContext.AssertTrue((2201)=(srvrec.port), 'Wrong SRV port');

  TestContext.AssertTrue(('_this._that._other')=(srvrec.target), 'Wrong SRV hostname');
end;

procedure TNetDbTest.TestDnsQueryCompressTCP_SRV;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  srvrec: TDNSRR_SRV;
begin
  BuildFakeResponseSRV(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen, True), 'Unable to convert fake dns response to compressed querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of SRV records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_SRV)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an SRV RR.');

  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong record name for RR 0');

  TestContext.AssertTrue(DNSRRGetSRV(RRArr[0], qd.Payload,
    srvrec), 'Did not get RR SOA data.');
  TestContext.AssertTrue((22)=(srvrec.priority), 'Wrong SRV priority');
  TestContext.AssertTrue((44)=(srvrec.weight), 'Wrong SRV weight');
  TestContext.AssertTrue((2201)=(srvrec.port), 'Wrong SRV port');

  TestContext.AssertTrue(('_this._that._other')=(srvrec.target), 'Wrong SRV hostname');
end;

{
This test is of debatable value, as it only detects truncation if the buffer
contents are zeroed which gives an invalid RR type.
}
procedure TNetDbTest.TestDnsQueryTruncateRR_UDP_A;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
begin
  BuildFakeResponseA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildTruncatedQueryData(fakeresp, qd, anslen,40), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  // the header says there are 2 A records, but it's a trap!
  TestContext.AssertTrue((2)=(qd.h.ancount), 'Wrong number of A records.');
  // truncation of buffer means this call returns 0 RRs.
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((0)=(Length(RRArr)), 'Wrong number of RRs');
end;

procedure TNetDbTest.TestDnsRRBufferEdgeA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  ip: THostAddr;
begin
  BuildFakeResponseA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((2)=(qd.h.ancount), 'Wrong number of A records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);

  // Change start position for RR[0] to end of buffer - 4
  RRArr[0].RDataSt := Length(qd.Payload) - RRArr[0].RRMeta.RDLength;
  qd.Payload[Length(qd.Payload)-1] := $AA; // sentinel marker we can look for

  TestContext.AssertTrue(DNSRRGetA(RRArr[0], qd.Payload, ip), 'Did not get RR A data.');
  TestContext.AssertTrue(('0.0.0.170')=(HostAddrToStr(ip)), 'Wrong ip for A.');
end;

procedure TNetDbTest.TestDnsRRBufferPastEdgeA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  ip: THostAddr;
begin
  BuildFakeResponseA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((2)=(qd.h.ancount), 'Wrong number of A records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);

  // Change start position for RR[0] to end of buffer - 3
  RRArr[0].RDataSt := Length(qd.Payload) - (RRArr[0].RRMeta.RDLength - 3);
  TestContext.AssertTrue(not (DNSRRGetA(RRArr[0], qd.Payload, ip)), 'Got RR A data.');
end;

{
Test that we read the AAAA right at the buffer edge, with the last byte
being a special value we can test for.
}
procedure TNetDbTest.TestDnsRRBufferEdgeAAAA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  ip: THostAddr6;
begin
  BuildFakeResponseAAAA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((2)=(qd.h.ancount), 'Wrong number of AAAA records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  // Change start position for RR[0]
  RRArr[0].RDataSt := Length(qd.Payload) - SizeOf(THostAddr6);
  qd.Payload[Length(qd.Payload)-1] := $AA;
  TestContext.AssertTrue(DNSRRGetAAAA(RRArr[0], qd.Payload, ip), 'Got RR AAAA data.');
  TestContext.AssertTrue(($AA)=(ip.u6_addr8[15]), '');
end;

{
Attempt to read an AAAA that goes past the end of the buffer.
}
procedure TNetDbTest.TestDNsRRBufferPastEdgeAAAA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  ip: THostAddr6;
begin
  BuildFakeResponseAAAA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((2)=(qd.h.ancount), 'Wrong number of AAAA records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  // Change start position for RR[0]. attempting to read 16 bytes
  // from this position will pass the end of the buffer.
  RRArr[0].RDataSt := Length(qd.Payload) - (SizeOf(THostAddr6)-1);
  qd.Payload[Length(qd.Payload)-1] := $AA;
  TestContext.AssertTrue(not (DNSRRGetAAAA(RRArr[0], qd.Payload, ip)), 'Got RR AAAA data.');
end;

{
Test reading an MX RR that terminates on the last byte of the buffer.
}
procedure TNetDbTest.TestDnsRRBufferEdgeMX;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  fmx: TDNSRR_MX;
begin
  BuildFakeResponseMX(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of MX records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);

  // move the MX RR bytes to the end of the payload buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - RRArr[0].RRMeta.RDLength;
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt, RRArr[0].RRMeta.RDLength);

  TestContext.AssertTrue(DNSRRGetMX(RRArr[0], qd.Payload, fmx), 'Got RR MX data.');
  TestContext.AssertTrue(('mailer.'+FAKEFQDN)=(fmx.exchange), 'Wrong MX hostname');
  TestContext.AssertTrue((10)=(fmx.preference), 'Wrong MX preference');
end;

procedure TNetDbTest.TestDnsRRBufferPastEdgeMX;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  fmx: TDNSRR_MX;
begin
  BuildFakeResponseMX(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of MX records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);

  // move the MX RR bytes to the end of the payload buffer. We omit the last
  // 2 bytes of the MX to attempt to trick the code into reading past the buffer
  // edge.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - (RRArr[0].RRMeta.RDLength - 2);
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt,
    (RRArr[0].RRMeta.RDLength-2));

  TestContext.AssertTrue(DNSRRGetMX(RRArr[0], qd.Payload, fmx), 'Got RR MX data.');
  // stringfromlabel should drop the last label, so the result should be just
  // missing the tld.
  TestContext.AssertTrue(('mailer.'+FAKEDOMAIN)=(fmx.exchange), 'Wrong MX hostname');
  TestContext.AssertTrue((10)=(fmx.preference), 'Wrong MX preference');
end;

procedure TNetDbTest.TestDnsRRBufferEdgeSOA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  soarec: TDNSRR_SOA;
begin
  BuildFakeResponseSOA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of SOA records.');

  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_SOA)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an SOA RR.');

  // move the SOA RR bytes to the end of the payload buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - RRArr[0].RRMeta.RDLength;
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt, RRArr[0].RRMeta.RDLength);

  TestContext.AssertTrue(DNSRRGetSOA(RRArr[0], qd.Payload,
    soarec), 'Did not get RR SOA data.');
  TestContext.AssertTrue(('mn.'+FAKEFQDN)=(soarec.mname), 'Wrong mname hostname');
  TestContext.AssertTrue(('rn.'+FAKEFQDN)=(soarec.rname), 'Wrong rname hostname');
  TestContext.AssertTrue((76543210)=(soarec.serial), 'Wrong SOA serial');
  TestContext.AssertTrue((123)=(soarec.refresh), 'Wrong SOA refresh');
  TestContext.AssertTrue((456)=(soarec.retry), 'Wrong SOA retry');
  TestContext.AssertTrue((789)=(soarec.expire), 'Wrong SOA expire');
  TestContext.AssertTrue((60)=(soarec.min), 'Wrong SOA min');
end;

procedure TNetDbTest.TestDnsRRBufferPastEdgeSOA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  soarec: TDNSRR_SOA;
begin
  BuildFakeResponseSOA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of SOA records.');

  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_SOA)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an SOA RR.');

  // move the SOA RR bytes to the end of the payload buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - (RRArr[0].RRMeta.RDLength-1);
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt,
    (RRArr[0].RRMeta.RDLength-1));

  TestContext.AssertTrue(not (DNSRRGetSOA(RRArr[0], qd.Payload,
    soarec)), 'Got RR SOA data.');
end;

procedure TNetDbTest.TestDnsRRBufferEdgeSRV;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  srvrec: TDNSRR_SRV;
begin
  BuildFakeResponseSRV(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of SRV records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_SRV)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an SRV RR.');

  // move the SRV RR bytes to the end of the payload buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - RRArr[0].RRMeta.RDLength;
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt, RRArr[0].RRMeta.RDLength);

  TestContext.AssertTrue(DNSRRGetSRV(RRArr[0], qd.Payload,
    srvrec), 'Did not get RR SRV data.');
  TestContext.AssertTrue((22)=(srvrec.priority), 'Wrong SRV priority');
  TestContext.AssertTrue((44)=(srvrec.weight), 'Wrong SRV weight');
  TestContext.AssertTrue((2201)=(srvrec.port), 'Wrong SRV port');

  TestContext.AssertTrue(('_this._that._other')=(srvrec.target), 'Wrong SRV hostname');
end;

procedure TNetDbTest.TestDnsRRBufferPastEdgeSRV;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  srvrec: TDNSRR_SRV;
begin
  BuildFakeResponseSRV(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of SRV records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_SRV)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an SRV RR.');

  // move the SRV RR bytes to the end of the payload buffer. ensure that
  // we're one byte short to try and trick the code into reading past the
  // end of the buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - (RRArr[0].RRMeta.RDLength - 1);
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt,
    (RRArr[0].RRMeta.RDLength - 1));

  TestContext.AssertTrue(not (DNSRRGetSRV(RRArr[0], qd.Payload,
    srvrec)), 'Got RR SRV data.');
end;

procedure TNetDbTest.TestDnsRRBufferEdgeCNAME;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  BuildFakeResponseCNAME(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of CNAME records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_CNAME)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an CNAME RR.');

  // move the cname to the end of the buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - RRArr[0].RRMeta.RDLength;
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt, RRArr[0].RRMeta.RDLength);

  TestContext.AssertTrue(DNSRRGetCNAME(RRArr[0], qd.Payload, s), 'Did not get RR CNAME data.');
  TestContext.AssertTrue(('fakecname.'+FAKEFQDN)=(s), 'Wrong CNAME.');
end;

{
Test retrieving a cname when the actual string is longer than rdlength says it
is. The bytes in the payload buffer try to point past the end of the buffer.
}
procedure TNetDbTest.TestDnsRRBufferPastEdgeCNAME;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  BuildFakeResponseCNAME(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of CNAME records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_CNAME)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an CNAME RR.');

  // move the cname to the end of the buffer. we drop two bytes off the end of
  // the cname, because there's a 0 byte at the end of a label if not a ptr.
  // now, the last label's size is greater than the number of bytes left in
  // the buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - (RRArr[0].RRMeta.RDLength-2);
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt,
    (RRArr[0].RRMeta.RDLength-2));

  // lie about the rdlength too!
  Dec(RRArr[0].RRMeta.RDLength,2);
  TestContext.AssertTrue(DNSRRGetCNAME(RRArr[0], qd.Payload, s), 'Did not get RR CNAME data.');
  // last label will get removed, leaving just the domain part.
  TestContext.AssertTrue(('fakecname.'+FAKEDOMAIN)=(s), 'Wrong CNAME.');
end;

{
Test retrieving an NS RR when it's at the end of the payload buffer.
}
procedure TNetDbTest.TestDnsRRBufferEdgeNS;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  BuildFakeResponseNS(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of NS records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_NS)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an NS RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong NS record name for RR 0');

  // move the ns to the end of the buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - RRArr[0].RRMeta.RDLength;
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt, RRArr[0].RRMeta.RDLength);

  TestContext.AssertTrue(DNSRRGetNS(RRArr[0], qd.Payload, s), 'Did not get RR NS data.');
  TestContext.AssertTrue(('fakens.'+FAKEFQDN)=(s), 'Wrong NS.');
end;

procedure TNetDbTest.TestDnsRRBufferPastEdgeNS;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  BuildFakeResponseNS(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of NS records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_NS)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an NS RR.');

  // move the ns to the end of the buffer. we drop two bytes off the end of
  // the ns, because there's a 0 byte at the end of a label if not a ptr.
  // now, the last label's size is greater than the number of bytes left in
  // the buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - (RRArr[0].RRMeta.RDLength-2);
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt,
    (RRArr[0].RRMeta.RDLength-2));

  // lie about the rdlength too!
  Dec(RRArr[0].RRMeta.RDLength,2);
  TestContext.AssertTrue(DNSRRGetNS(RRArr[0], qd.Payload, s), 'Did not get RR NS data.');
  // last label will get removed, leaving just the domain part.
  TestContext.AssertTrue(('fakens.'+FAKEDOMAIN)=(s), 'Wrong NS.');
end;

procedure TNetDbTest.TestDnsRRBufferEdgePTR;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  // the str passed in to this function doesn't really matter, but using
  // a proper in-addr.arpa domain helps keep it clear what we're testing.
  BuildFakeResponsePTR('0.5.0.127.in-addr.arpa', fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of PTR records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_PTR)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an PTR RR.');
  TestContext.AssertTrue(('0.5.0.127.in-addr.arpa')=(RRArr[0].RRName), 'Wrong PTR record name for RR 0');

  // move the ptr to the end of the buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - RRArr[0].RRMeta.RDLength;
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt, RRArr[0].RRMeta.RDLength);

  TestContext.AssertTrue(DNSRRGetPTR(RRArr[0], qd.Payload, s), 'Did not get RR PTR data.');
  TestContext.AssertTrue(('fakeptrans.'+FAKEFQDN)=(s), 'Wrong PTR.');
end;

procedure TNetDbTest.TestDnsRRBufferPastEdgePTR;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  // the str passed in to this function doesn't really matter, but using
  // a proper in-addr.arpa domain helps keep it clear what we're testing.
  BuildFakeResponsePTR('0.5.0.127.in-addr.arpa', fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of PTR records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_PTR)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an PTR RR.');
  TestContext.AssertTrue(('0.5.0.127.in-addr.arpa')=(RRArr[0].RRName), 'Wrong PTR record name for RR 0');

  // move the ns to the end of the buffer. we drop two bytes off the end of
  // the ns, because there's a 0 byte at the end of a label if not a ptr.
  // now, the last label's size is greater than the number of bytes left in
  // the buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - (RRArr[0].RRMeta.RDLength-2);
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt,
    (RRArr[0].RRMeta.RDLength-2));

  // lie about the rdlength too!
  Dec(RRArr[0].RRMeta.RDLength,2);
  TestContext.AssertTrue(DNSRRGetPTR(RRArr[0], qd.Payload, s), 'Did not get RR PTR data.');
  // last label will get removed, leaving just the domain part.
  TestContext.AssertTrue(('fakeptrans.'+FAKEDOMAIN)=(s), 'Wrong PTR.');
end;

{
Test reading a text record right at the edge of the payload buffer.
}
procedure TNetDbTest.TestDnsRRBufferEdgeTXT;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart,oldstart: Word;
  RRArr: TRRNameDataArray;
  s: AnsiString;
begin
  s := '';
  BuildFakeResponseTXT(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of TXT records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_TXT)=(RRarr[0].RRMeta.Atype), 'RR 0 is not a TXT RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong TXT record name for RR 0');

  // Move the text record to the end of the buffer
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - RRArr[0].RRMeta.RDLength;
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt, RRArr[0].RRMeta.RDLength);
  TestContext.AssertTrue(DNSRRGetText(RRArr[0], qd.Payload, s), 'Did not get RR TXT data.');
  TestContext.AssertTrue(('v=spf1 mx a:lists.'+FAKEFQDN+'Always look on the bright side of life!')=(s), '');
end;

{
Try reading a TXT record that points past the end of the payload buffer.
}
procedure TNetDbTest.TestDnsRRBufferPastEdgeTXT;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart,oldstart: Word;
  RRArr: TRRNameDataArray;
  s: AnsiString;
begin
  s := '';
  BuildFakeResponseTXT(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of TXT records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_TXT)=(RRarr[0].RRMeta.Atype), 'RR 0 is not a TXT RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong TXT record name for RR 0');

  // Move the text record to the end of the buffer, cutting off the last
  // 2 bytes. this means the length byte for the second string will point
  // past the end of the buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - (RRArr[0].RRMeta.RDLength - 2);
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt,
    (RRArr[0].RRMeta.RDLength - 2));
  TestContext.AssertTrue(not (DNSRRGetText(RRArr[0], qd.Payload, s)), 'Did not get RR TXT data.');
end;

procedure TNetDbTest.TestDnsRRBufferEdgeTCPA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  ip: THostAddr;
begin
  BuildFakeResponseA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((2)=(qd.h.ancount), 'Wrong number of A records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);

  // Change start position for RR[0] to end of buffer - 4
  RRArr[0].RDataSt := Length(qd.Payload) - RRArr[0].RRMeta.RDLength;
  qd.Payload[Length(qd.Payload)-1] := $AA; // sentinel marker we can look for
  TestContext.AssertTrue(DNSRRGetA(RRArr[0], qd.Payload, ip), 'Did not get RR A data.');
  TestContext.AssertTrue(('0.0.0.170')=(HostAddrToStr(ip)), 'Wrong ip for A.');
end;

procedure TNetDbTest.TestDnsRRBufferPastEdgeTCPA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  ip: THostAddr;
begin
  BuildFakeResponseA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((2)=(qd.h.ancount), 'Wrong number of A records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);

  // Change start position for RR[0] to end of buffer - 3
  RRArr[0].RDataSt := Length(qd.Payload) - (RRArr[0].RRMeta.RDLength - 2);
  TestContext.AssertTrue(not (DNSRRGetA(RRArr[0], qd.Payload, ip)), 'Got RR A data.');
end;

procedure TNetDbTest.TestDnsRRBufferEdgeTCPAAAA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  ip: THostAddr6;
begin
  BuildFakeResponseAAAA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((2)=(qd.h.ancount), 'Wrong number of AAAA records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  // Change start position for RR[0]
  RRArr[0].RDataSt := Length(qd.Payload) - SizeOf(THostAddr6);
  qd.Payload[Length(qd.Payload)-1] := $AA;
  TestContext.AssertTrue(DNSRRGetAAAA(RRArr[0], qd.Payload, ip), 'Got RR AAAA data.');
  TestContext.AssertTrue(($AA)=(ip.u6_addr8[15]), '');
end;

procedure TNetDbTest.TestDNsRRBufferPastEdgeTCPAAAA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
  ip: THostAddr6;
begin
  BuildFakeResponseAAAA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((2)=(qd.h.ancount), 'Wrong number of AAAA records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  // Change start position for RR[0]. attempting to read 16 bytes
  // from this position will pass the end of the buffer.
  RRArr[0].RDataSt := Length(qd.Payload) - (SizeOf(THostAddr6)-1);
  TestContext.AssertTrue(not (DNSRRGetAAAA(RRArr[0], qd.Payload, ip)), 'Got RR AAAA data.');
end;

procedure TNetDbTest.TestDnsRRBufferEdgeTCPMX;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  fmx: TDNSRR_MX;
begin
  BuildFakeResponseMX(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of MX records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);

  // move the MX RR bytes to the end of the payload buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - RRArr[0].RRMeta.RDLength;
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt, RRArr[0].RRMeta.RDLength);

  TestContext.AssertTrue(DNSRRGetMX(RRArr[0], qd.Payload, fmx), 'Got RR MX data.');
  TestContext.AssertTrue(('mailer.'+FAKEFQDN)=(fmx.exchange), 'Wrong MX hostname');
  TestContext.AssertTrue((10)=(fmx.preference), 'Wrong MX preference');
end;

procedure TNetDbTest.TestDnsRRBufferPastEdgeTCPMX;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  fmx: TDNSRR_MX;
begin
  BuildFakeResponseMX(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of MX records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);

  // move the MX RR bytes to the end of the payload buffer. We omit the last
  // 2 bytes of the MX to attempt to trick the code into reading past the buffer
  // edge.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - (RRArr[0].RRMeta.RDLength - 2);
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt,
    (RRArr[0].RRMeta.RDLength-2));

  TestContext.AssertTrue(DNSRRGetMX(RRArr[0], qd.Payload, fmx), 'Got RR MX data.');
  // stringfromlabel should drop the last label, so the result should be just
  // missing the tld.
  TestContext.AssertTrue(('mailer.'+FAKEDOMAIN)=(fmx.exchange), 'Wrong MX hostname');
  TestContext.AssertTrue((10)=(fmx.preference), 'Wrong MX preference');
end;

procedure TNetDbTest.TestDnsRRBufferEdgeTCPSOA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  soarec: TDNSRR_SOA;
begin
  BuildFakeResponseSOA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of SOA records.');

  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_SOA)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an SOA RR.');

  // move the SOA RR bytes to the end of the payload buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - RRArr[0].RRMeta.RDLength;
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt, RRArr[0].RRMeta.RDLength);

  TestContext.AssertTrue(DNSRRGetSOA(RRArr[0], qd.Payload,
    soarec), 'Did not get RR SOA data.');
  TestContext.AssertTrue(('mn.'+FAKEFQDN)=(soarec.mname), 'Wrong mname hostname');
  TestContext.AssertTrue(('rn.'+FAKEFQDN)=(soarec.rname), 'Wrong rname hostname');
  TestContext.AssertTrue((76543210)=(soarec.serial), 'Wrong SOA serial');
  TestContext.AssertTrue((123)=(soarec.refresh), 'Wrong SOA refresh');
  TestContext.AssertTrue((456)=(soarec.retry), 'Wrong SOA retry');
  TestContext.AssertTrue((789)=(soarec.expire), 'Wrong SOA expire');
  TestContext.AssertTrue((60)=(soarec.min), 'Wrong SOA min');
end;

procedure TNetDbTest.TestDnsRRBufferPastEdgeTCPSOA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  soarec: TDNSRR_SOA;
begin
  BuildFakeResponseSOA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of SOA records.');

  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_SOA)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an SOA RR.');

  // move the SOA RR bytes to the end of the payload buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - (RRArr[0].RRMeta.RDLength-1);
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt,
    (RRArr[0].RRMeta.RDLength-1));

  TestContext.AssertTrue(not (DNSRRGetSOA(RRArr[0], qd.Payload,
    soarec)), 'Got RR SOA data.');
end;

procedure TNetDbTest.TestDnsRRBufferEdgeTCPSRV;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  srvrec: TDNSRR_SRV;
begin
  BuildFakeResponseSRV(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of SRV records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_SRV)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an SRV RR.');

  // move the SRV RR bytes to the end of the payload buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - RRArr[0].RRMeta.RDLength;
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt, RRArr[0].RRMeta.RDLength);

  TestContext.AssertTrue(DNSRRGetSRV(RRArr[0], qd.Payload,
    srvrec), 'Did not get RR SRV data.');
  TestContext.AssertTrue((22)=(srvrec.priority), 'Wrong SRV priority');
  TestContext.AssertTrue((44)=(srvrec.weight), 'Wrong SRV weight');
  TestContext.AssertTrue((2201)=(srvrec.port), 'Wrong SRV port');

  TestContext.AssertTrue(('_this._that._other')=(srvrec.target), 'Wrong SRV hostname');
end;

procedure TNetDbTest.TestDnsRRBufferPastEdgeTCPSRV;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  srvrec: TDNSRR_SRV;
begin
  BuildFakeResponseSRV(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of SRV records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_SRV)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an SRV RR.');

  // move the SRV RR bytes to the end of the payload buffer. ensure that
  // we're one byte short to try and trick the code into reading past the
  // end of the buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - (RRArr[0].RRMeta.RDLength - 1);
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt,
    (RRArr[0].RRMeta.RDLength - 1));

  TestContext.AssertTrue(not (DNSRRGetSRV(RRArr[0], qd.Payload,
    srvrec)), 'Got RR SRV data.');
end;

procedure TNetDbTest.TestDnsRRBufferEdgeTCPCNAME;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  BuildFakeResponseCNAME(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of CNAME records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_CNAME)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an CNAME RR.');

  // move the cname to the end of the buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - RRArr[0].RRMeta.RDLength;
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt, RRArr[0].RRMeta.RDLength);

  TestContext.AssertTrue(DNSRRGetCNAME(RRArr[0], qd.Payload, s), 'Did not get RR CNAME data.');
  TestContext.AssertTrue(('fakecname.'+FAKEFQDN)=(s), 'Wrong CNAME.');
end;

procedure TNetDbTest.TestDnsRRBufferPastEdgeTCPCNAME;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  BuildFakeResponseCNAME(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of CNAME records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_CNAME)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an CNAME RR.');

  // move the cname to the end of the buffer. we drop two bytes off the end of
  // the cname, because there's a 0 byte at the end of a label if not a ptr.
  // now, the last label's size is greater than the number of bytes left in
  // the buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - (RRArr[0].RRMeta.RDLength-2);
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt,
    (RRArr[0].RRMeta.RDLength-2));

  // lie about the rdlength too!
  Dec(RRArr[0].RRMeta.RDLength,2);
  TestContext.AssertTrue(DNSRRGetCNAME(RRArr[0], qd.Payload, s), 'Did not get RR CNAME data.');
  // last label will get removed, leaving just the domain part.
  TestContext.AssertTrue(('fakecname.'+FAKEDOMAIN)=(s), 'Wrong CNAME.');
end;

procedure TNetDbTest.TestDnsRRBufferEdgeTCPNS;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  BuildFakeResponseNS(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of NS records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_NS)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an NS RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong NS record name for RR 0');

  // move the ns to the end of the buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - RRArr[0].RRMeta.RDLength;
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt, RRArr[0].RRMeta.RDLength);

  TestContext.AssertTrue(DNSRRGetNS(RRArr[0], qd.Payload, s), 'Did not get RR NS data.');
  TestContext.AssertTrue(('fakens.'+FAKEFQDN)=(s), 'Wrong NS.');
end;

procedure TNetDbTest.TestDnsRRBufferPastEdgeTCPNS;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  BuildFakeResponseNS(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of NS records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_NS)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an NS RR.');

  // move the ns to the end of the buffer. we drop two bytes off the end of
  // the ns, because there's a 0 byte at the end of a label if not a ptr.
  // now, the last label's size is greater than the number of bytes left in
  // the buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - (RRArr[0].RRMeta.RDLength-2);
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt,
    (RRArr[0].RRMeta.RDLength-2));

  // lie about the rdlength too!
  Dec(RRArr[0].RRMeta.RDLength,2);
  TestContext.AssertTrue(DNSRRGetNS(RRArr[0], qd.Payload, s), 'Did not get RR NS data.');
  // last label will get removed, leaving just the domain part.
  TestContext.AssertTrue(('fakens.'+FAKEDOMAIN)=(s), 'Wrong NS.');
end;

procedure TNetDbTest.TestDnsRRBufferEdgeTCPPTR;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  // the str passed in to this function doesn't really matter, but using
  // a proper in-addr.arpa domain helps keep it clear what we're testing.
  BuildFakeResponsePTR('0.5.0.127.in-addr.arpa', fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of PTR records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_PTR)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an PTR RR.');
  TestContext.AssertTrue(('0.5.0.127.in-addr.arpa')=(RRArr[0].RRName), 'Wrong PTR record name for RR 0');

  // move the ptr to the end of the buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - RRArr[0].RRMeta.RDLength;
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt, RRArr[0].RRMeta.RDLength);

  TestContext.AssertTrue(DNSRRGetPTR(RRArr[0], qd.Payload, s), 'Did not get RR PTR data.');
  TestContext.AssertTrue(('fakeptrans.'+FAKEFQDN)=(s), 'Wrong PTR.');
end;

procedure TNetDbTest.TestDnsRRBufferPastEdgeTCPPTR;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
begin
  // the str passed in to this function doesn't really matter, but using
  // a proper in-addr.arpa domain helps keep it clear what we're testing.
  BuildFakeResponsePTR('0.5.0.127.in-addr.arpa', fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of PTR records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_PTR)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an PTR RR.');
  TestContext.AssertTrue(('0.5.0.127.in-addr.arpa')=(RRArr[0].RRName), 'Wrong PTR record name for RR 0');

  // move the ns to the end of the buffer. we drop two bytes off the end of
  // the ns, because there's a 0 byte at the end of a label if not a ptr.
  // now, the last label's size is greater than the number of bytes left in
  // the buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - (RRArr[0].RRMeta.RDLength-2);
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt,
    (RRArr[0].RRMeta.RDLength-2));

  // lie about the rdlength too!
  Dec(RRArr[0].RRMeta.RDLength,2);
  TestContext.AssertTrue(DNSRRGetPTR(RRArr[0], qd.Payload, s), 'Did not get RR PTR data.');
  // last label will get removed, leaving just the domain part.
  TestContext.AssertTrue(('fakeptrans.'+FAKEDOMAIN)=(s), 'Wrong PTR.');
end;

procedure TNetDbTest.TestDnsRRBufferEdgeTCPTXT;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart,oldstart: Word;
  RRArr: TRRNameDataArray;
  s: AnsiString;
begin
  s := '';
  BuildFakeResponseTXT(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of TXT records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_TXT)=(RRarr[0].RRMeta.Atype), 'RR 0 is not a TXT RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong TXT record name for RR 0');

  // Move the text record to the end of the buffer
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - RRArr[0].RRMeta.RDLength;
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt, RRArr[0].RRMeta.RDLength);
  TestContext.AssertTrue(DNSRRGetText(RRArr[0], qd.Payload, s), 'Did not get RR TXT data.');
  TestContext.AssertTrue(('v=spf1 mx a:lists.'+FAKEFQDN+'Always look on the bright side of life!')=(s), '');
end;

procedure TNetDbTest.TestDnsRRBufferPastEdgeTCPTXT;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart,oldstart: Word;
  RRArr: TRRNameDataArray;
  s: AnsiString;
begin
  s := '';
  BuildFakeResponseTXT(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of TXT records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_TXT)=(RRarr[0].RRMeta.Atype), 'RR 0 is not a TXT RR.');
  TestContext.AssertTrue((FAKEFQDN)=(RRArr[0].RRName), 'Wrong TXT record name for RR 0');

  // Move the text record to the end of the buffer, cutting off the last
  // 2 bytes. this means the length byte for the second string will point
  // past the end of the buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - (RRArr[0].RRMeta.RDLength - 2);
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt,
    (RRArr[0].RRMeta.RDLength - 2));
  TestContext.AssertTrue(not (DNSRRGetText(RRArr[0], qd.Payload, s)), 'Did not get RR TXT data.');
end;

{
Test that NextNameRR correctly reads an RR on the edge of the buffer.
}
procedure TNetDbTest.TestNextNameRREdgeA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  rrn: TRRNameData;
  ip: THostAddr;
  t: Cardinal;
begin
  BuildFakeResponseA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);

  // get an RR from its normal position. need this to calculate the length.
  TestContext.AssertTrue(NextNameRR(qd.Payload, ansstart,  rrn), 'NextNameRR should succeed.');

  // calculate the size in bytes of the rr so we can copy it to the end
  // of the payload buffer
  t := (rrn.RDataSt + rrn.RRMeta.RDLength) - ansstart;
  CopyBytesTo(qd.Payload,ansstart,Length(qd.Payload)-t, t);
  TestContext.AssertTrue(NextNameRR(qd.Payload, Length(qd.Payload)-t,  rrn), 'NextNameRR should succeed.');
  TestContext.AssertTrue((DNSQRY_A)=(rrn.RRMeta.Atype), '');
  TestContext.AssertTrue((300)=(rrn.RRMeta.TTL), '');
  TestContext.AssertTrue(DNSRRGetA(rrn, qd.Payload, ip), '');
  TestContext.AssertTrue(('127.0.0.1')=(HostAddrToStr(ip)), 'Wrong ip for A.');
end;

{
Try to trick NextNameRR into reading past the end of the payload buffer.
}
procedure TNetDbTest.TestNextNameRRPastEdgeA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  rrn: TRRNameData;
  t: Cardinal;
begin
  BuildFakeResponseA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);

  // get an RR from its normal position. need this to calculate the length.
  TestContext.AssertTrue(NextNameRR(qd.Payload, ansstart,  rrn), 'NextNameRR should succeed.');

  // calculate the size in bytes of the rr so we can copy it to the end
  // of the payload buffer
  t := (rrn.RDataSt + rrn.RRMeta.RDLength) - ansstart;
  // copy the bytes, but leave off the last one. leave the rdlength unchanged.
  CopyBytesTo(qd.Payload,ansstart,Length(qd.Payload)-(t-1), t-1);
  TestContext.AssertTrue(not (NextNameRR(qd.Payload, Length(qd.Payload)-(t-1),  rrn)), 'NextNameRR should fail.');
end;

procedure TNetDbTest.TestNextNameRREdgeTCPA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  rrn: TRRNameData;
  ip: THostAddr;
  t: Cardinal;
begin
  BuildFakeResponseA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);

  // get an RR from its normal position. need this to calculate the length.
  TestContext.AssertTrue(NextNameRR(qd.Payload, ansstart,  rrn), 'NextNameRR should succeed.');

  // calculate the size in bytes of the rr so we can copy it to the end
  // of the payload buffer
  t := (rrn.RDataSt + rrn.RRMeta.RDLength) - ansstart;
  CopyBytesTo(qd.Payload,ansstart,Length(qd.Payload)-t, t);
  TestContext.AssertTrue(NextNameRR(qd.Payload, Length(qd.Payload)-t,  rrn), 'NextNameRR should succeed.');
  TestContext.AssertTrue((DNSQRY_A)=(rrn.RRMeta.Atype), '');
  TestContext.AssertTrue((300)=(rrn.RRMeta.TTL), '');
  TestContext.AssertTrue(DNSRRGetA(rrn, qd.Payload, ip), '');
  TestContext.AssertTrue(('127.0.0.1')=(HostAddrToStr(ip)), 'Wrong ip for A.');
end;

procedure TNetDbTest.TestNextNameRRPastEdgeTCPA;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  rrn: TRRNameData;
  t: Cardinal;
begin
  BuildFakeResponseA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);

  // get an RR from its normal position. need this to calculate the length.
  TestContext.AssertTrue(NextNameRR(qd.Payload, ansstart,  rrn), 'NextNameRR should succeed.');

  // calculate the size in bytes of the rr so we can copy it to the end
  // of the payload buffer
  t := (rrn.RDataSt + rrn.RRMeta.RDLength) - ansstart;
  // copy the bytes, but leave off the last one. leave the rdlength unchanged.
  CopyBytesTo(qd.Payload,ansstart,Length(qd.Payload)-(t-1), t-1);
  TestContext.AssertTrue(not (NextNameRR(qd.Payload, Length(qd.Payload)-(t-1),  rrn)), 'NextNameRR should fail.');
end;

{
Call GetRRrecords with a start position past the end of the buffer.
}

procedure TNetDbTest.TestGetRRrecordsInvalidStart;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
begin
  BuildFakeResponseA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := High(Word);
  anslen := High(Word);
  TestContext.AssertTrue((2)=(qd.h.ancount), 'Wrong number of A records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, anslen);
  TestContext.AssertTrue((0)=(Length(RRArr)), '');
end;

procedure TNetDbTest.TestGetRRrecordsInvalidStartTCP;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart: Word;
  RRArr: TRRNameDataArray;
begin
  BuildFakeResponseA(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := High(Word);
  anslen := High(Word);
  TestContext.AssertTrue((2)=(qd.h.ancount), 'Wrong number of A records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, anslen);
  TestContext.AssertTrue((0)=(Length(RRArr)), '');
end;

procedure TNetDbTest.TestGetFixLenStrSimple;
const
  s = 'another fine mess';
var
  buf: TBuffer;
  pl: TPayload;
  tr: TTextArray;
  offset: Cardinal;
  res: ShortString;
begin
  tr[1] := s;
  tr[2] := '';
  tr[3] := '';
  tr[4] := '';
  tr[5] := '';
  SetLength(buf, 1024);
  offset := 0;
  WriteTextRecAsRData(buf, offset, tr);
  SetLength(buf, offset);
  BufferToPayload(buf, pl);
  // rdlength is word, so len byte for str is at offset 2 and str starts
  // at offset 3.
  GetFixlenStr(pl, 3, pl[2], res);
  TestContext.AssertTrue((s)=(res), '');
end;

procedure TNetDbTest.TestGetFixLenStrSimpleTCP;
const
  s = 'another fine mess';
var
  buf: TBuffer;
  pl: TPayLoadTCP;
  tr: TTextArray;
  offset: Cardinal;
  res: ShortString;
begin
  tr[1] := s;
  tr[2] := '';
  tr[3] := '';
  tr[4] := '';
  tr[5] := '';
  SetLength(buf, 1024);
  offset := 0;
  WriteTextRecAsRData(buf, offset, tr);
  SetLength(buf, offset);
  BufferToPayload(buf, pl);
  // rdlength is word, so len byte for str is at offset 2 and str starts
  // at offset 3.
  GetFixlenStr(pl, 3, pl[2], res);
  TestContext.AssertTrue((s)=(res), '');
end;

procedure TNetDbTest.TestGetFixLenStrSimpleAtEdge;
const
  s = 'another fine mess';
var
  buf: TBuffer;
  pl: TPayload;
  tr: TTextArray;
  offset,n: Cardinal;
  res: ShortString;
begin
  tr[1] := s;
  tr[2] := '';
  tr[3] := '';
  tr[4] := '';
  tr[5] := '';
  SetLength(buf, Length(pl));
  offset := Length(pl) - (Length(s)+3);
  n := offset+2;
  WriteTextRecAsRData(buf, offset, tr);
  SetLength(buf, offset);
  BufferToPayload(buf, pl);
  GetFixlenStr(pl, n+1, pl[n], res);
  TestContext.AssertTrue((s)=(res), '');
end;

procedure TNetDbTest.TestGetFixLenStrSimpleTCPAtEdge;
const
  s = 'another fine mess';
var
  buf: TBuffer;
  pl: TPayLoadTCP;
  tr: TTextArray;
  offset,n: Cardinal;
  res: ShortString;
begin
  tr[1] := s;
  tr[2] := '';
  tr[3] := '';
  tr[4] := '';
  tr[5] := '';
  SetLength(buf, Length(pl));
  offset := Length(pl) - (Length(s)+3);
  n := offset+2;
  WriteTextRecAsRData(buf, offset, tr);
  SetLength(buf, offset);
  BufferToPayload(buf, pl);
  GetFixlenStr(pl, n+1, pl[n], res);
  TestContext.AssertTrue((s)=(res), '');
end;

{
Test GetFixLenStr where len would take string past edge of buffer.
}
procedure TNetDbTest.TestGetFixLenStrSimplePastEdge;
var
  pl: TPayLoadTCP;
  res: ShortString;
begin
  pl[Length(pl) - 2] := 30;
  pl[Length(pl) - 1] := Ord('a');
  GetFixlenStr(pl, Length(pl)-1, pl[Length(pl)-2], res);
  TestContext.AssertTrue(('')=(res), '');
end;

procedure TNetDbTest.TestGetFixLenStrSimpleTCPPastEdge;
var
  pl: TPayLoadTCP;
  res: ShortString;
begin
  pl[Length(pl) - 2] := 30;
  pl[Length(pl) - 1] := Ord('a');
  GetFixlenStr(pl, Length(pl)-1, pl[Length(pl)-2], res);
  TestContext.AssertTrue(('')=(res), '');
end;

{
 read a label at the end of the buffer where the last byte is a count
 greater than 0. this is to try and trick stringfromlabel into reading past
 the end of the buffer.
}
procedure TNetDbTest.TestStringFromLabelCountAsLastByte;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryData;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
  startpos: Longint;
begin
  // we can use any of CNAME, NS or PTR because these RRs are just a single
  // domain name or series of labels.
  BuildFakeResponseNS(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of NS records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_NS)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an NS RR.');

  // move the ns to the end of the buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - RRArr[0].RRMeta.RDLength;
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt, RRArr[0].RRMeta.RDLength);

  // Set the last byte in the buffer to a high count
  qd.Payload[Length(qd.Payload)-1] := 63; // must be less than 64

  // need this var because stringfromlabel expects a longint that's a var type.
  startpos := RRarr[0].RDataSt;
  s := stringfromlabel(qd.Payload, startpos);
  TestContext.AssertTrue(('fakens.'+FAKEFQDN)=(s), '');
  TestContext.AssertTrue((Length(qd.Payload))=(startpos), '');
end;

procedure TNetDbTest.TestStringFromLabelCountAsLastByteTCP;
var
  fakeresp: TFakeDNSResponse;
  qd: TQueryDataLengthTCP;
  anslen, ansstart, oldstart: Word;
  RRArr: TRRNameDataArray;
  s: TDNSDomainName;
  startpos: Longint;
begin
  // we can use any of CNAME, NS or PTR because these RRs are just a single
  // domain name or series of labels.
  BuildFakeResponseNS(FAKEFQDN, fakeresp);
  TestContext.AssertTrue(BuildQueryData(fakeresp, qd, anslen), 'Unable to convert fake dns response to querydata');
  TestContext.AssertTrue(CheckAnswer(qd.h,qd.h), 'CheckAnswer should return true.');
  ansstart := SkipAnsQueries(qd, anslen);
  TestContext.AssertTrue((1)=(qd.h.ancount), 'Wrong number of NS records.');
  RRArr := GetRRrecords(qd.Payload, ansstart, qd.h.ancount);
  TestContext.AssertTrue((1)=(Length(RRArr)), 'Wrong number of resource records.');
  TestContext.AssertTrue((DNSQRY_NS)=(RRarr[0].RRMeta.Atype), 'RR 0 is not an NS RR.');

  // move the ns to the end of the buffer.
  oldstart := RRArr[0].RDataSt;
  RRArr[0].RDataSt := Length(qd.Payload) - RRArr[0].RRMeta.RDLength;
  CopyBytesTo(qd.Payload, oldstart, RRArr[0].RDataSt, RRArr[0].RRMeta.RDLength);

  // Set the last byte in the buffer to a high count
  qd.Payload[Length(qd.Payload)-1] := 63; // must be less than 64

  // need this var because stringfromlabel expects a longint that's a var type.
  startpos := RRarr[0].RDataSt;
  s := stringfromlabel(qd.Payload, startpos);
  TestContext.AssertTrue(('fakens.'+FAKEFQDN)=(s), '');
  TestContext.AssertTrue((Length(qd.Payload))=(startpos), '');
end;

procedure TNetDbTest.TestStringFromLabelCompress;
var
  buf: TBuffer;
  stt: TDomainCompressionTable;
  offset: Cardinal;
  offset2: Longint;
  pl: TPayload;
  s: String;
  dmbs: TDNSDomainByteStream;
begin
  SetLength(buf, 1024);
  SetLength(stt,0);
  offset := 0;
  // initial str is uncompressed because compress table empty
  dmbs := DomainNameToByteStream(FAKEFQDN, stt);
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);
  offset2 := offset;
  // write same domain, this time we get compression.
  dmbs := DomainNameToByteStream(FAKEFQDN, stt);
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);
  BufferToPayload(buf,pl);
  s := stringfromlabel(pl, offset2);
  TestContext.AssertTrue((FAKEFQDN)=(s), '');
end;

procedure TNetDbTest.TestStringFromLabelCompressTCP;
var
  buf: TBuffer;
  stt: TDomainCompressionTable;
  offset: Cardinal;
  offset2: Longint;
  pl: TPayLoadTCP;
  s: String;
  dmbs: TDNSDomainByteStream;
begin
  SetLength(buf, 1024);
  SetLength(stt,0);
  offset := 0;
  // initial str is uncompressed because compress table empty
  dmbs := DomainNameToByteStream(FAKEFQDN, stt);
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);
  offset2 := offset;
  // write same domain, this time we get compression.
  dmbs := DomainNameToByteStream(FAKEFQDN, stt);
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);
  BufferToPayload(buf,pl);
  s := stringfromlabel(pl, offset2);
  TestContext.AssertTrue((FAKEFQDN)=(s), '');
end;

procedure TNetDbTest.TestStringFromLabelCompressWithUncompressedLabel;
var
  buf: TBuffer;
  dmbs: TDNSDomainByteStream;
  offset: Cardinal;
  so: Longint;
  stt: TDomainCompressionTable;
  len: Word;
  pl: TPayload;
  s: String;
begin
  SetLength(buf, 1024);
  SetLength(stt,0);
  // compress table empty so no compression here.
  dmbs := DomainNameToByteStream(FAKEFQDN, stt);
  offset := 0;
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);

  so := offset;
  // should get compression on FAKEFQDN but label "foo" is written as full label.
  dmbs := DomainNameToByteStream('foo.' + FAKEFQDN, stt);
  len := CalcRdLength(dmbs);
  // len is 4 for 'foo' (including its length byte) and 2 for the pointer.
  TestContext.AssertTrue((6)=(len), '');
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);
  BufferToPayload(buf,pl);
  s := stringfromlabel(pl, so);
  TestContext.AssertTrue(('foo.'+FAKEFQDN)=(s), '');
end;

procedure TNetDbTest.TestStringFromLabelCompressWithUncompressedLabelTCP;
var
  buf: TBuffer;
  dmbs: TDNSDomainByteStream;
  offset: Cardinal;
  so: Longint;
  stt: TDomainCompressionTable;
  len: Word;
  pl: TPayLoadTCP;
  s: String;
begin
  SetLength(buf, 1024);
  SetLength(stt,0);
  // compress table empty so no compression here.
  dmbs := DomainNameToByteStream(FAKEFQDN, stt);
  offset := 0;
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);

  so := offset;
  // should get compression on FAKEFQDN but label "foo" is written as full label.
  dmbs := DomainNameToByteStream('foo.' + FAKEFQDN, stt);
  len := CalcRdLength(dmbs);
  // len is 4 for 'foo' (including its length byte) and 2 for the pointer.
  TestContext.AssertTrue((6)=(len), '');
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);
  BufferToPayload(buf,pl);
  s := stringfromlabel(pl, so);
  TestContext.AssertTrue(('foo.'+FAKEFQDN)=(s), '');
end;

{
Test stringfromlabel with a compressed label at the end of the buffer.
}
procedure TNetDbTest.TestStringFromLabelCompressEndBuffer;
var
  buf: TBuffer;
  stt: TDomainCompressionTable;
  offset: Cardinal;
  offset2: Longint;
  pl: TPayload;
  s: String;
  dmbs: TDNSDomainByteStream;
begin
  SetLength(buf, 1024);
  SetLength(stt,0);
  offset := 0;

  // initial str is uncompressed because compress table empty
  dmbs := DomainNameToByteStream(FAKEFQDN, stt);
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);
  offset2 := offset;
  // write same domain, this time we get compression.
  dmbs := DomainNameToByteStream(FAKEFQDN, stt);

  // write the pointer at the end of the payload buffer
  offset := Length(pl) - 2;
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);
  BufferToPayload(buf,pl);

  // read back the label.
  offset2 := Length(pl) - 2;
  s := stringfromlabel(pl, offset2);
  TestContext.AssertTrue((FAKEFQDN)=(s), '');
end;

procedure TNetDbTest.TestStringFromLabelCompressEndBufferTCP;
var
  buf: TBuffer;
  stt: TDomainCompressionTable;
  offset: Cardinal;
  offset2: Longint;
  pl: TPayLoadTCP;
  s: String;
  dmbs: TDNSDomainByteStream;
begin
  SetLength(buf, Length(pl));
  SetLength(stt,0);
  offset := 0;

  // initial str is uncompressed because compress table empty
  dmbs := DomainNameToByteStream(FAKEFQDN, stt);
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);
  offset2 := offset;
  // write same domain, this time we get compression.
  dmbs := DomainNameToByteStream(FAKEFQDN, stt);

  // write the pointer at the end of the payload buffer
  offset := Length(pl) - 2;
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);
  BufferToPayload(buf,pl);

  // read back the label.
  offset2 := Length(pl) - 2;
  s := stringfromlabel(pl, offset2);
  TestContext.AssertTrue((FAKEFQDN)=(s), '');
end;

procedure TNetDbTest.TestStringFromLabelCompressSplit;
var
  pl: TPayload;
  s: String;
  offset: Longint;
begin
  // fill the buffer with 'A' so that we'll know if stringfromlabel read any
  // of it.
  FillByte(pl, Length(pl), 65);
  offset := Length(pl) - 1;
  pl[offset] := 192;
  s := stringfromlabel(pl, offset);
  TestContext.AssertTrue(('')=(s), '');
end;

procedure TNetDbTest.TestStringFromLabelCompressSplitTCP;
var
  pl: TPayLoadTCP;
  s: String;
  offset: Longint;
begin
  // fill the buffer with 'A' so that we'll know if stringfromlabel read any
  // of it.
  FillByte(pl, Length(pl), 65);
  offset := Length(pl) - 1;
  pl[offset] := 192;
  s := stringfromlabel(pl, offset);
  TestContext.AssertTrue(('')=(s), '');
end;

procedure TNetDbTest.TestStringFromLabelCompressPtrFwd;
var
  pl: TPayload;
  s: String;
  offset: Longint;
  ptr: TDNSDomainPointer;
begin
  FillByte(pl, Length(pl), 0);
  Move('foo', pl[21], 3);
  pl[20] := 3;

  ptr := GetDnsDomainPointer(32); // offset 20 + 12 for the header
  offset := 0;
  pl[offset] := ptr.b1;
  pl[offset+1] := ptr.b2;
  s := stringfromlabel(pl, offset);
  TestContext.AssertTrue(('')=(s), '');
end;

procedure TNetDbTest.TestStringFromLabelCompressPtrFwdTCP;
var
  pl: TPayLoadTCP;
  s: String;
  offset: Longint;
  ptr: TDNSDomainPointer;
begin
  FillByte(pl, Length(pl), 0);
  Move('foo', pl[21], 3);
  pl[20] := 3;

  ptr := GetDnsDomainPointer(32); // offset 20 + 12 for the header
  offset := 0;
  pl[offset] := ptr.b1;
  pl[offset+1] := ptr.b2;
  s := stringfromlabel(pl, offset);
  TestContext.AssertTrue(('')=(s), '');
end;

procedure TNetDbTest.TestStringFromLabelCompressAllPtrStart;
var
  pl: TPayload;
  s: String;
  offset: Longint;
begin
  FillByte(pl, Length(pl), 192);
  offset := 0;
  s := stringfromlabel(pl, offset);
  TestContext.AssertTrue(('')=(s), '');
end;

procedure TNetDbTest.TestStringFromLabelCompressAllPtrStartTCP;
var
  pl: TPayLoadTCP;
  s: String;
  offset: Longint;
begin
  FillByte(pl, Length(pl), 192);
  offset := 0;
  s := stringfromlabel(pl, offset);
  TestContext.AssertTrue(('')=(s), '');
end;

{
Test what happens when pointer is 0.
}
procedure TNetDbTest.TestStringFromLabelCompressedZero;
var
  pl: TPayLoad;
  s: String;
  offset: Longint;
  ptr: TDNSDomainPointer;
begin
  FillByte(pl, Length(pl), 0);
  pl[0] := 1;
  pl[1] := Ord('a');
  ptr := GetDnsDomainPointer(0);
  offset := 5;
  pl[offset] := ptr.b1;
  pl[offset+1] := ptr.b2;

  s := stringfromlabel(pl, offset);
  TestContext.AssertTrue(('')=(s), '');
end;

{
Test what happens when pointer is 0.
}
procedure TNetDbTest.TestStringFromLabelCompressedZeroTCP;
var
  pl: TPayLoadTCP;
  s: String;
  offset: Longint;
  ptr: TDNSDomainPointer;
begin
  FillByte(pl, Length(pl), 0);
  pl[0] := 1;
  pl[1] := Ord('a');
  ptr := GetDnsDomainPointer(0);
  offset := 5;
  pl[offset] := ptr.b1;
  pl[offset+1] := ptr.b2;

  s := stringfromlabel(pl, offset);
  TestContext.AssertTrue(('')=(s), '');
end;

procedure TNetDbTest.TestStringFromLabelInfiniteLoop;
var
  buf: TBuffer;
  stt: TDomainCompressionTable;
  offset: Cardinal;
  offset2: Longint;
  pl: TPayload;
  s: String;
  dmbs: TDNSDomainByteStream;
  ptr: TDNSDomainPointer;
begin
  SetLength(buf, 1024);
  SetLength(stt,0);
  offset := 0;
  // initial str is uncompressed because compress table empty
  dmbs := DomainNameToByteStream(FAKEFQDN, stt);
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);
  ptr := GetDnsDomainPointer(12);

  // offset now points to 0 byte at end of label. We're overwriting that
  // 0 so that stringfromlabel will be tricked into a loop.
  Dec(offset);
  Move(ptr.ba, buf[offset], 2);

  BufferToPayload(buf,pl);
  offset2 := 0;
  s := stringfromlabel(pl, offset2);
  // if stringfromlabel returns at all then the test passed.
end;

procedure TNetDbTest.TestStringFromLabelInfiniteLoopTCP;
var
  buf: TBuffer;
  stt: TDomainCompressionTable;
  offset: Cardinal;
  offset2: Longint;
  pl: TPayLoadTCP;
  s: String;
  dmbs: TDNSDomainByteStream;
  ptr: TDNSDomainPointer;
begin
  SetLength(buf, 1024);
  SetLength(stt,0);
  offset := 0;
  // initial str is uncompressed because compress table empty
  dmbs := DomainNameToByteStream(FAKEFQDN, stt);
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);
  ptr := GetDnsDomainPointer(12);

  // offset now points to 0 byte at end of label. We're overwriting that
  // 0 so that stringfromlabel will be tricked into a loop.
  Dec(offset);
  Move(ptr.ba, buf[offset], 2);

  BufferToPayload(buf,pl);
  offset2 := 0;
  s := stringfromlabel(pl, offset2);
  // if stringfromlabel returns at all then the test passed.
end;

procedure TNetDbTest.TestCompressShortDomain;
const
  shortdomain = 'a.b';
var
  buf: TBuffer;
  stt: TDomainCompressionTable;
  offset: Cardinal;
  offset2: Longint;
  pl: TPayload;
  s: String;
  dmbs: TDNSDomainByteStream;
begin
  SetLength(buf, 1024);
  SetLength(stt,0);
  offset := 0;
  // initial str is uncompressed because compress table empty
  dmbs := DomainNameToByteStream(shortdomain, stt);
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);
  offset2 := offset;
  // second str is compressed
  dmbs := DomainNameToByteStream(shortdomain, stt);
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);

  BufferToPayload(buf,pl);
  s := stringfromlabel(pl, offset2);
  TestContext.AssertTrue((shortdomain)=(s), '');
end;

procedure TNetDbTest.TestCompressShortDomainTCP;
const
  shortdomain = 'a.b';
var
  buf: TBuffer;
  stt: TDomainCompressionTable;
  offset: Cardinal;
  offset2: Longint;
  pl: TPayLoadTCP;
  s: String;
  dmbs: TDNSDomainByteStream;
begin
  SetLength(buf, 1024);
  SetLength(stt,0);
  offset := 0;
  // initial str is uncompressed because compress table empty
  dmbs := DomainNameToByteStream(shortdomain, stt);
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);
  offset2 := offset;
  // second str is compressed
  dmbs := DomainNameToByteStream(shortdomain, stt);
  WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs);

  BufferToPayload(buf,pl);
  s := stringfromlabel(pl, offset2);
  TestContext.AssertTrue((shortdomain)=(s), '');
end;

procedure TNetDbTest.SetUp;
begin
  tsl := TStringList.Create;
end;

procedure TNetDbTest.TearDown;
begin
  tsl.Free;
end;

procedure TNetDbTest.CopyBytesTo(var buf: TPayLoad; startidx, destidx,
  count: Word);
begin
  // no tests for overlapping source and dest.
  if ((startidx+count) > Length(buf)) or ((destidx+count) > Length(buf)) then
    exit;
  Move(buf[startidx], buf[destidx], count);
end;

procedure TNetDbTest.CopyBytesTo(var buf: TPayLoadTCP; startidx, destidx,
  count: Word);
begin
  // no tests for overlapping source and dest.
  if ((startidx+count) > Length(buf)) or ((destidx+count) > Length(buf)) then
    exit;
  Move(buf[startidx], buf[destidx], count);
end;

function TNetDbTest.WriteNumToBuffer(var buf: TBuffer; var offset: Cardinal;
  val: Word): Word;
begin
  Result := 0;
  if (offset + SizeOf(val)) > Length(buf) then exit;
  Move(HToNs(val), buf[offset], SizeOf(val));
  Inc(offset, SizeOf(val));
  Result := SizeOf(val);
end;

function TNetDbTest.WriteNumToBuffer(var buf: TBuffer; var offset: Cardinal;
  val: Cardinal): Word;
begin
  Result := 0;
  if (offset + SizeOf(val)) > Length(buf) then exit;
  Move(HToNl(val), buf[offset], SizeOf(val));
  Inc(offset, SizeOf(val));
  Result := SizeOf(val);
end;

{
Write a number to the buffer without converting it to network byte order.
}
function TNetDbTest.WriteNumToBufferN(var buf: TBuffer; var offset: Cardinal;
  val: Word): Word;
begin
  Result := 0;
  if (offset + SizeOf(val)) > Length(buf) then exit;
  Move(val, buf[offset], SizeOf(val));
  Inc(offset, SizeOf(val));
  Result := SizeOf(val);
end;

{
Write a number to the buffer without converting it to network byte order.
}
function TNetDbTest.WriteNumToBufferN(var buf: TBuffer; var offset: Cardinal;
  val: Cardinal): Word;
begin
  Result := 0;
  if (offset + SizeOf(val)) > Length(buf) then exit;
  Move(val, buf[offset], SizeOf(val));
  Inc(offset, SizeOf(val));
  Result := SizeOf(val);
end;

{
Write an RR to the byte buffer. No compression of domain names will occur.
}
function TNetDbTest.WriteRRToBuffer(var buf: TBuffer; var offset: Cardinal;
  rr: TFakeRR): Word;
var
  s,etw: Word;
  dmbs: TDNSDomainByteStream;
  res: TRDataWriteRes;
begin
  etw := 0;
  s := offset;
  // write the RR Name
  dmbs := DomainNameToByteStream(rr.RRName);
  etw := CalcRdLength(dmbs);
  if WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs) < etw
  then
    TestContext.Fail('Cannot write RR name to buffer at offset '+ inttostr(offset));

  if (offset + SizeOf(rr.Atype) + SizeOf(rr.AClass) + SizeOf(rr.TTL)) >
    Length(buf)
  then
    TestContext.Fail('Not enough space to add RR type,class,ttl at offset '+ inttostr(offset));

  // Write the RR type, class and TTL.
  WriteNumToBuffer(buf, offset,rr.Atype);
  WriteNumToBuffer(buf, offset, rr.AClass);
  WriteNumToBuffer(buf, offset, rr.TTL);

  // now the RR data, which is type specific. Each type-specific method
  // also writes the RDLength word, so we have to account for 2 additional
  // bytes.
  case rr.Atype of
    DNSQRY_A:
        res := WriteAasRData(buf, offset, rr.ip);
    DNSQRY_AAAA:
        res := WriteAAAAasRData(buf, offset, rr.ip6);
    DNSQRY_SOA:
        res := WriteSOAasRData(buf, offset, rr.fsoa);
    DNSQRY_MX:
        res := WriteMXAsRData(buf, offset, rr.fmx);
    DNSQRY_NS:
      begin
        dmbs := DomainNameToByteStream(rr.nsh);
        res := WriteDomainAsRdata(buf,offset,dmbs);
      end;
    DNSQRY_PTR:
      begin
        dmbs := DomainNameToByteStream(rr.nsh);
        res := WriteDomainAsRdata(buf,offset,dmbs);
      end;
    DNSQRY_CNAME:
      begin
        dmbs := DomainNameToByteStream(rr.cn);
        res := WriteDomainAsRdata(buf,offset,dmbs);
      end;
    DNSQRY_TXT:
        res := WriteTextRecAsRData(buf, offset, rr.txtarr);
    DNSQRY_SRV:
        res := WriteSRVasRData(buf, offset, rr.fsrv);
  else
    TestContext.Fail('Called to handle RR type '+inttostr(rr.Atype)+
      ' but no code to handle it.');
  end;

  if res.bw < res.etw then
    TestContext.Fail('Unable to write RR of type ' +inttostr(RR.Atype) +
      ', name "'  + rr.RRName + '" to buffer at offset '+inttostr(offset)+
      '. Wrote '+inttostr(res.bw)+' bytes, expected to write '+
        inttostr(res.etw)+' bytes.');

  Result := offset - s;
end;

{
Write an RR to the output buffer, with compression of domain names turned on.
}
function TNetDbTest.WriteRRToBuffer(var buf: TBuffer; var offset: Cardinal;
  rr: TFakeRR; var ctbl: TDomainCompressionTable): Word;
var
  s, etw: Word;
  dmbs: TDNSDomainByteStream;
  res: TRDataWriteRes;
begin
  etw := 0;
  s := offset;
  // write the RR Name
  dmbs := DomainNameToByteStream(rr.RRName, ctbl);
  etw := CalcRdLength(dmbs);
  if WriteDNSDomainByteStreamToBuffer(buf, offset, dmbs) < etw
  then
    TestContext.Fail('Cannot write RR name to buffer at offset '+ inttostr(offset));

  if (offset + SizeOf(rr.Atype) + SizeOf(rr.AClass) + SizeOf(rr.TTL)) >
    Length(buf)
  then
    TestContext.Fail('Not enough space to add RR type,class,ttl at offset '+ inttostr(offset));

  // Write the RR type, class and TTL.
  WriteNumToBuffer(buf, offset,rr.Atype);
  WriteNumToBuffer(buf, offset, rr.AClass);
  WriteNumToBuffer(buf, offset, rr.TTL);

  // now the RR data, which is type specific. Each type-specific method
  // also writes the RDLength word, so we have to account for 2 additional
  // bytes.
  case rr.Atype of
    DNSQRY_A:
      begin
        res := WriteAasRData(buf, offset, rr.ip);
      end;
    DNSQRY_AAAA:
      begin
        res := WriteAAAAasRData(buf, offset, rr.ip6);
      end;
    DNSQRY_SOA:
      begin
        res := WriteSOAasRData(buf, offset, rr.fsoa);
      end;
    DNSQRY_MX:
      begin
        res := WriteMXAsRData(buf, offset, rr.fmx, ctbl);
      end;
    DNSQRY_NS:
      begin
        dmbs := DomainNameToByteStream(rr.nsh, ctbl);
        res := WriteDomainAsRdata(buf,offset,dmbs);
      end;
    DNSQRY_PTR:
      begin
        dmbs := DomainNameToByteStream(rr.nsh, ctbl);
        res := WriteDomainAsRdata(buf,offset,dmbs);
      end;
    DNSQRY_CNAME:
      begin
        dmbs := DomainNameToByteStream(rr.cn, ctbl);
        res := WriteDomainAsRdata(buf,offset,dmbs);
      end;
    DNSQRY_TXT:
      begin
        res := WriteTextRecAsRData(buf, offset, rr.txtarr);
      end;
    DNSQRY_SRV:
      begin
        res := WriteSRVasRData(buf, offset, rr.fsrv);
      end;
  else
    TestContext.Fail('Called to handle RR type '+inttostr(rr.Atype)+
      ' but no code to handle it.');
  end;

  if res.bw < res.etw then
    TestContext.Fail('Unable to write RR of type ' +inttostr(RR.Atype) +
      ', name "'  + rr.RRName + '" to buffer at offset '+inttostr(offset)+
      '. Wrote '+inttostr(res.bw)+' bytes, expected to write '+
        inttostr(res.etw)+' bytes.');

  Result := offset - s;
end;

{
Turn a fake DNS response into a payload buffer. This is a byte buffer minus the
DNS header. That is, the buffer begins with the question part of the response,
after which comes the RRs of the answers, authority, and additional sections.
}
function TNetDbTest.FakeDNSResponseToByteBuffer(fdr: TFakeDNSResponse; out
  buf: TBuffer; compress: Boolean): Cardinal;
var
  offset: Cardinal;
  rr: TFakeRR;
  dbs: TDNSDomainByteStream;
begin
  // plenty of room for our test responses. could precalculate this, but there's
  // no benefit. The return value of this function is the length of the
  // DNS reply, which we get for free since we have to track our offset into
  // the buffer as we write it.
  SetLength(buf, 2048);
  offset := 0;

  if compress then
    dbs := DomainNameToByteStream(fdr.qry.nm,fdr.strtable)
  else
    dbs := DomainNameToByteStream(fdr.qry.nm);

  // The question section consists of the dns query name, the qtype and
  // qclass.
  if WriteDNSDomainByteStreamToBuffer(buf, offset, dbs) < CalcRdLength(dbs)
  then
    TestContext.Fail('Cannot write name to buffer at offset '+ inttostr(offset));

  WriteNumToBuffer(buf, offset, fdr.qry.qtype);
  WriteNumToBuffer(buf, offset, fdr.qry.qclass);

  // Now the answer sections.
  for rr in fdr.answers do
    if compress then
      WriteRRToBuffer(buf, offset, rr, fdr.strtable)
    else
      WriteRRToBuffer(buf, offset, rr);
  for rr in fdr.authority do
    if compress then
      WriteRRToBuffer(buf, offset, rr, fdr.strtable)
    else
      WriteRRToBuffer(buf, offset, rr);
  for rr in fdr.additional do
    if compress then
      WriteRRToBuffer(buf, offset, rr, fdr.strtable)
    else
      WriteRRToBuffer(buf, offset, rr);

  SetLength(buf, offset);
  Result := offset;
end;

{
Generate a TPayload buffer, a fixed-length array of byte, from the TBuffer
type, which is a variable-length array of byte.
}
function TNetDbTest.BufferToPayload(const buf: TBuffer;
  out pl: TPayload): Boolean;
begin
  Result := False;
  FillChar(pl,Length(pl),0);
  Move(buf[0], pl[0], Min(Length(pl),Length(buf)));
  Result := True;
end;

function TNetDbTest.BufferToPayload(const buf: TBuffer;
  out pl: TPayLoadTCP): Boolean;
begin
  Result := False;
  FillChar(pl,Length(pl),0);
  Move(buf[0], pl[0], Min(Length(pl),Length(buf)));
  Result := True;
end;

function TNetDbTest.BuildQueryData(fdr: TFakeDNSResponse; out qd: TQueryData;
  out qlen: Word; Compress: Boolean = False): Boolean;
var
  buf: TBuffer;
begin
  qlen := FakeDNSResponseToByteBuffer(fdr, buf, Compress);
  qd.h.ancount := HToNs(fdr.hdr.ancount);
  qd.h.arcount := HToNs(fdr.hdr.arcount);
  qd.h.nscount := HToNs(fdr.hdr.nscount);
  qd.h.qdcount := HToNs(fdr.hdr.qdcount);
  qd.h.flags1 := fdr.hdr.flags1;
  qd.h.flags2 := fdr.hdr.flags2;
  qd.h.id[0] := fdr.hdr.id[0];
  qd.h.id[1] := fdr.hdr.id[1];
  Result := BufferToPayload(buf, qd.Payload);
end;

function TNetDbTest.BuildQueryData(fdr: TFakeDNSResponse; out
  qd: TQueryDataLengthTCP; out qlen: Word; Compress: Boolean = False): Boolean;
var
  buf: TBuffer;
begin
  qlen := FakeDNSResponseToByteBuffer(fdr, buf, Compress);
  qd.h.ancount := HToNs(fdr.hdr.ancount);
  qd.h.arcount := HToNs(fdr.hdr.arcount);
  qd.h.nscount := HToNs(fdr.hdr.nscount);
  qd.h.qdcount := HToNs(fdr.hdr.qdcount);
  qd.h.flags1 := fdr.hdr.flags1;
  qd.h.flags2 := fdr.hdr.flags2;
  qd.h.id[0] := fdr.hdr.id[0];
  qd.h.id[1] := fdr.hdr.id[1];
  Result := BufferToPayload(buf, qd.Payload);
end;

{
Create a deliberately invalid DNS response to test our API's ability to cope
with invalid data without causing memory corruption.

After building a valid DNS response as normal, we truncate it at the given
offset.}
function TNetDbTest.BuildTruncatedQueryData(fdr: TFakeDNSResponse; out
  qd: TQueryData; out qlen: Word; truncoffset: Word): Boolean;
var
  buf: TBuffer;
begin
  qlen := FakeDNSResponseToByteBuffer(fdr, buf);
  qd.h.ancount := HToNs(fdr.hdr.ancount);
  qd.h.arcount := HToNs(fdr.hdr.arcount);
  qd.h.nscount := HToNs(fdr.hdr.nscount);
  qd.h.qdcount := HToNs(fdr.hdr.qdcount);
  qd.h.flags1 := fdr.hdr.flags1;
  qd.h.flags2 := fdr.hdr.flags2;
  qd.h.id[0] := fdr.hdr.id[0];
  qd.h.id[1] := fdr.hdr.id[1];
  SetLength(buf, truncoffset);
  Result := BufferToPayload(buf, qd.Payload);
end;


constructor TNetDbTest.Create(AContext: TNXTestContext; const ACaseName: string);
begin
  inherited Create;
  FContext:=AContext;
  FCaseName:=ACaseName;
end;

procedure RunTNetDbTestTestBuildPayloadSimple(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestBuildPayloadSimple');
  try
    lFixture.SetUp;
    try lFixture.TestBuildPayloadSimple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestBuildPayloadSimpleEmpty(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestBuildPayloadSimpleEmpty');
  try
    lFixture.SetUp;
    try lFixture.TestBuildPayloadSimpleEmpty; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestBuildPayloadSimpleEndDot(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestBuildPayloadSimpleEndDot');
  try
    lFixture.SetUp;
    try lFixture.TestBuildPayloadSimpleEndDot; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestBuildPayloadSimpleStartDot(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestBuildPayloadSimpleStartDot');
  try
    lFixture.SetUp;
    try lFixture.TestBuildPayloadSimpleStartDot; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestBuildPayloadSimpleMultipleDot(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestBuildPayloadSimpleMultipleDot');
  try
    lFixture.SetUp;
    try lFixture.TestBuildPayloadSimpleMultipleDot; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryUDP_A(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryUDP_A');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryUDP_A; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryTCP_A(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryTCP_A');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryTCP_A; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryCompressUDP_A(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryCompressUDP_A');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryCompressUDP_A; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryCompressTCP_A(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryCompressTCP_A');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryCompressTCP_A; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryUDP_AAAA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryUDP_AAAA');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryUDP_AAAA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryTCP_AAAA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryTCP_AAAA');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryTCP_AAAA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryCompressUDP_AAAA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryCompressUDP_AAAA');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryCompressUDP_AAAA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryCompressTCP_AAAA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryCompressTCP_AAAA');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryCompressTCP_AAAA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryUDP_MX(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryUDP_MX');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryUDP_MX; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryTCP_MX(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryTCP_MX');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryTCP_MX; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryCompressUDP_MX(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryCompressUDP_MX');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryCompressUDP_MX; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryCompressTCP_MX(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryCompressTCP_MX');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryCompressTCP_MX; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryUDP_SOA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryUDP_SOA');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryUDP_SOA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryTCP_SOA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryTCP_SOA');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryTCP_SOA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryCompressUDP_SOA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryCompressUDP_SOA');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryCompressUDP_SOA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryCompressTCP_SOA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryCompressTCP_SOA');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryCompressTCP_SOA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryUDP_CNAME(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryUDP_CNAME');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryUDP_CNAME; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryTCP_CNAME(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryTCP_CNAME');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryTCP_CNAME; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryCompressUDP_CNAME(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryCompressUDP_CNAME');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryCompressUDP_CNAME; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryCompressTCP_CNAME(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryCompressTCP_CNAME');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryCompressTCP_CNAME; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryUDP_NS(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryUDP_NS');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryUDP_NS; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryTCP_NS(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryTCP_NS');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryTCP_NS; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryCompressUDP_NS(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryCompressUDP_NS');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryCompressUDP_NS; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryCompressTCP_NS(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryCompressTCP_NS');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryCompressTCP_NS; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryUDP_PTR(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryUDP_PTR');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryUDP_PTR; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryTCP_PTR(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryTCP_PTR');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryTCP_PTR; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryCompressUDP_PTR(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryCompressUDP_PTR');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryCompressUDP_PTR; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryCompressTCP_PTR(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryCompressTCP_PTR');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryCompressTCP_PTR; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryUDP_TXT(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryUDP_TXT');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryUDP_TXT; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryTCP_TXT(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryTCP_TXT');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryTCP_TXT; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryCompressUDP_TXT(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryCompressUDP_TXT');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryCompressUDP_TXT; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryCompressTCP_TXT(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryCompressTCP_TXT');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryCompressTCP_TXT; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryUDP_SRV(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryUDP_SRV');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryUDP_SRV; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryTCP_SRV(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryTCP_SRV');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryTCP_SRV; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryCompressUDP_SRV(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryCompressUDP_SRV');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryCompressUDP_SRV; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryCompressTCP_SRV(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryCompressTCP_SRV');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryCompressTCP_SRV; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsQueryTruncateRR_UDP_A(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsQueryTruncateRR_UDP_A');
  try
    lFixture.SetUp;
    try lFixture.TestDnsQueryTruncateRR_UDP_A; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferEdgeA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferEdgeA');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferEdgeA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferPastEdgeA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferPastEdgeA');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferPastEdgeA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferEdgeAAAA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferEdgeAAAA');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferEdgeAAAA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDNsRRBufferPastEdgeAAAA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDNsRRBufferPastEdgeAAAA');
  try
    lFixture.SetUp;
    try lFixture.TestDNsRRBufferPastEdgeAAAA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferEdgeMX(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferEdgeMX');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferEdgeMX; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferPastEdgeMX(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferPastEdgeMX');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferPastEdgeMX; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferEdgeSOA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferEdgeSOA');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferEdgeSOA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferPastEdgeSOA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferPastEdgeSOA');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferPastEdgeSOA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferEdgeSRV(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferEdgeSRV');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferEdgeSRV; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferPastEdgeSRV(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferPastEdgeSRV');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferPastEdgeSRV; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferEdgeCNAME(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferEdgeCNAME');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferEdgeCNAME; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferPastEdgeCNAME(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferPastEdgeCNAME');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferPastEdgeCNAME; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferEdgeNS(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferEdgeNS');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferEdgeNS; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferPastEdgeNS(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferPastEdgeNS');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferPastEdgeNS; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferEdgePTR(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferEdgePTR');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferEdgePTR; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferPastEdgePTR(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferPastEdgePTR');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferPastEdgePTR; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferEdgeTXT(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferEdgeTXT');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferEdgeTXT; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferPastEdgeTXT(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferPastEdgeTXT');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferPastEdgeTXT; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferEdgeTCPA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferEdgeTCPA');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferEdgeTCPA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferPastEdgeTCPA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferPastEdgeTCPA');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferPastEdgeTCPA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferEdgeTCPAAAA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferEdgeTCPAAAA');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferEdgeTCPAAAA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDNsRRBufferPastEdgeTCPAAAA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDNsRRBufferPastEdgeTCPAAAA');
  try
    lFixture.SetUp;
    try lFixture.TestDNsRRBufferPastEdgeTCPAAAA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferEdgeTCPMX(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferEdgeTCPMX');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferEdgeTCPMX; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferPastEdgeTCPMX(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferPastEdgeTCPMX');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferPastEdgeTCPMX; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferEdgeTCPSOA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferEdgeTCPSOA');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferEdgeTCPSOA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferPastEdgeTCPSOA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferPastEdgeTCPSOA');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferPastEdgeTCPSOA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferEdgeTCPSRV(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferEdgeTCPSRV');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferEdgeTCPSRV; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferPastEdgeTCPSRV(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferPastEdgeTCPSRV');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferPastEdgeTCPSRV; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferEdgeTCPCNAME(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferEdgeTCPCNAME');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferEdgeTCPCNAME; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferPastEdgeTCPCNAME(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferPastEdgeTCPCNAME');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferPastEdgeTCPCNAME; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferEdgeTCPNS(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferEdgeTCPNS');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferEdgeTCPNS; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferPastEdgeTCPNS(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferPastEdgeTCPNS');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferPastEdgeTCPNS; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferEdgeTCPPTR(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferEdgeTCPPTR');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferEdgeTCPPTR; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferPastEdgeTCPPTR(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferPastEdgeTCPPTR');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferPastEdgeTCPPTR; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferEdgeTCPTXT(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferEdgeTCPTXT');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferEdgeTCPTXT; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestDnsRRBufferPastEdgeTCPTXT(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestDnsRRBufferPastEdgeTCPTXT');
  try
    lFixture.SetUp;
    try lFixture.TestDnsRRBufferPastEdgeTCPTXT; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestNextNameRREdgeA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestNextNameRREdgeA');
  try
    lFixture.SetUp;
    try lFixture.TestNextNameRREdgeA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestNextNameRRPastEdgeA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestNextNameRRPastEdgeA');
  try
    lFixture.SetUp;
    try lFixture.TestNextNameRRPastEdgeA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestNextNameRREdgeTCPA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestNextNameRREdgeTCPA');
  try
    lFixture.SetUp;
    try lFixture.TestNextNameRREdgeTCPA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestNextNameRRPastEdgeTCPA(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestNextNameRRPastEdgeTCPA');
  try
    lFixture.SetUp;
    try lFixture.TestNextNameRRPastEdgeTCPA; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestGetRRrecordsInvalidStart(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestGetRRrecordsInvalidStart');
  try
    lFixture.SetUp;
    try lFixture.TestGetRRrecordsInvalidStart; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestGetRRrecordsInvalidStartTCP(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestGetRRrecordsInvalidStartTCP');
  try
    lFixture.SetUp;
    try lFixture.TestGetRRrecordsInvalidStartTCP; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestGetFixLenStrSimple(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestGetFixLenStrSimple');
  try
    lFixture.SetUp;
    try lFixture.TestGetFixLenStrSimple; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestGetFixLenStrSimpleTCP(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestGetFixLenStrSimpleTCP');
  try
    lFixture.SetUp;
    try lFixture.TestGetFixLenStrSimpleTCP; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestGetFixLenStrSimpleAtEdge(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestGetFixLenStrSimpleAtEdge');
  try
    lFixture.SetUp;
    try lFixture.TestGetFixLenStrSimpleAtEdge; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestGetFixLenStrSimpleTCPAtEdge(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestGetFixLenStrSimpleTCPAtEdge');
  try
    lFixture.SetUp;
    try lFixture.TestGetFixLenStrSimpleTCPAtEdge; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestGetFixLenStrSimplePastEdge(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestGetFixLenStrSimplePastEdge');
  try
    lFixture.SetUp;
    try lFixture.TestGetFixLenStrSimplePastEdge; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestGetFixLenStrSimpleTCPPastEdge(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestGetFixLenStrSimpleTCPPastEdge');
  try
    lFixture.SetUp;
    try lFixture.TestGetFixLenStrSimpleTCPPastEdge; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestStringFromLabelCountAsLastByte(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestStringFromLabelCountAsLastByte');
  try
    lFixture.SetUp;
    try lFixture.TestStringFromLabelCountAsLastByte; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestStringFromLabelCountAsLastByteTCP(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestStringFromLabelCountAsLastByteTCP');
  try
    lFixture.SetUp;
    try lFixture.TestStringFromLabelCountAsLastByteTCP; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestStringFromLabelCompress(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestStringFromLabelCompress');
  try
    lFixture.SetUp;
    try lFixture.TestStringFromLabelCompress; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestStringFromLabelCompressTCP(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestStringFromLabelCompressTCP');
  try
    lFixture.SetUp;
    try lFixture.TestStringFromLabelCompressTCP; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestStringFromLabelCompressWithUncompressedLabel(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestStringFromLabelCompressWithUncompressedLabel');
  try
    lFixture.SetUp;
    try lFixture.TestStringFromLabelCompressWithUncompressedLabel; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestStringFromLabelCompressWithUncompressedLabelTCP(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestStringFromLabelCompressWithUncompressedLabelTCP');
  try
    lFixture.SetUp;
    try lFixture.TestStringFromLabelCompressWithUncompressedLabelTCP; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestStringFromLabelCompressEndBuffer(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestStringFromLabelCompressEndBuffer');
  try
    lFixture.SetUp;
    try lFixture.TestStringFromLabelCompressEndBuffer; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestStringFromLabelCompressEndBufferTCP(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestStringFromLabelCompressEndBufferTCP');
  try
    lFixture.SetUp;
    try lFixture.TestStringFromLabelCompressEndBufferTCP; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestStringFromLabelCompressSplit(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestStringFromLabelCompressSplit');
  try
    lFixture.SetUp;
    try lFixture.TestStringFromLabelCompressSplit; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestStringFromLabelCompressSplitTCP(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestStringFromLabelCompressSplitTCP');
  try
    lFixture.SetUp;
    try lFixture.TestStringFromLabelCompressSplitTCP; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestStringFromLabelCompressPtrFwd(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestStringFromLabelCompressPtrFwd');
  try
    lFixture.SetUp;
    try lFixture.TestStringFromLabelCompressPtrFwd; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestStringFromLabelCompressPtrFwdTCP(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestStringFromLabelCompressPtrFwdTCP');
  try
    lFixture.SetUp;
    try lFixture.TestStringFromLabelCompressPtrFwdTCP; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestStringFromLabelCompressAllPtrStart(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestStringFromLabelCompressAllPtrStart');
  try
    lFixture.SetUp;
    try lFixture.TestStringFromLabelCompressAllPtrStart; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestStringFromLabelCompressAllPtrStartTCP(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestStringFromLabelCompressAllPtrStartTCP');
  try
    lFixture.SetUp;
    try lFixture.TestStringFromLabelCompressAllPtrStartTCP; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestStringFromLabelCompressedZero(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestStringFromLabelCompressedZero');
  try
    lFixture.SetUp;
    try lFixture.TestStringFromLabelCompressedZero; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestStringFromLabelCompressedZeroTCP(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestStringFromLabelCompressedZeroTCP');
  try
    lFixture.SetUp;
    try lFixture.TestStringFromLabelCompressedZeroTCP; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestStringFromLabelInfiniteLoop(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestStringFromLabelInfiniteLoop');
  try
    lFixture.SetUp;
    try lFixture.TestStringFromLabelInfiniteLoop; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestStringFromLabelInfiniteLoopTCP(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestStringFromLabelInfiniteLoopTCP');
  try
    lFixture.SetUp;
    try lFixture.TestStringFromLabelInfiniteLoopTCP; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestCompressShortDomain(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestCompressShortDomain');
  try
    lFixture.SetUp;
    try lFixture.TestCompressShortDomain; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RunTNetDbTestTestCompressShortDomainTCP(AContext: TNXTestContext);
var lFixture: TNetDbTest;
begin
  lFixture:=TNetDbTest.Create(AContext, 'TestCompressShortDomainTCP');
  try
    lFixture.SetUp;
    try lFixture.TestCompressShortDomainTCP; finally lFixture.TearDown; end;
  finally lFixture.Free; end;
end;

procedure RegisternetdbtestTests(ARegistry: TNXTestRegistry);
var lSuite: TNXTestSuite;
begin
  lSuite:=ARegistry.AddSuite('netdbtest.TNetDbTest');
  lSuite.AddTest('TestBuildPayloadSimple', @RunTNetDbTestTestBuildPayloadSimple);
  lSuite.AddTest('TestBuildPayloadSimpleEmpty', @RunTNetDbTestTestBuildPayloadSimpleEmpty);
  lSuite.AddTest('TestBuildPayloadSimpleEndDot', @RunTNetDbTestTestBuildPayloadSimpleEndDot);
  lSuite.AddTest('TestBuildPayloadSimpleStartDot', @RunTNetDbTestTestBuildPayloadSimpleStartDot);
  lSuite.AddTest('TestBuildPayloadSimpleMultipleDot', @RunTNetDbTestTestBuildPayloadSimpleMultipleDot);
  lSuite.AddTest('TestDnsQueryUDP_A', @RunTNetDbTestTestDnsQueryUDP_A);
  lSuite.AddTest('TestDnsQueryTCP_A', @RunTNetDbTestTestDnsQueryTCP_A);
  lSuite.AddTest('TestDnsQueryCompressUDP_A', @RunTNetDbTestTestDnsQueryCompressUDP_A);
  lSuite.AddTest('TestDnsQueryCompressTCP_A', @RunTNetDbTestTestDnsQueryCompressTCP_A);
  lSuite.AddTest('TestDnsQueryUDP_AAAA', @RunTNetDbTestTestDnsQueryUDP_AAAA);
  lSuite.AddTest('TestDnsQueryTCP_AAAA', @RunTNetDbTestTestDnsQueryTCP_AAAA);
  lSuite.AddTest('TestDnsQueryCompressUDP_AAAA', @RunTNetDbTestTestDnsQueryCompressUDP_AAAA);
  lSuite.AddTest('TestDnsQueryCompressTCP_AAAA', @RunTNetDbTestTestDnsQueryCompressTCP_AAAA);
  lSuite.AddTest('TestDnsQueryUDP_MX', @RunTNetDbTestTestDnsQueryUDP_MX);
  lSuite.AddTest('TestDnsQueryTCP_MX', @RunTNetDbTestTestDnsQueryTCP_MX);
  lSuite.AddTest('TestDnsQueryCompressUDP_MX', @RunTNetDbTestTestDnsQueryCompressUDP_MX);
  lSuite.AddTest('TestDnsQueryCompressTCP_MX', @RunTNetDbTestTestDnsQueryCompressTCP_MX);
  lSuite.AddTest('TestDnsQueryUDP_SOA', @RunTNetDbTestTestDnsQueryUDP_SOA);
  lSuite.AddTest('TestDnsQueryTCP_SOA', @RunTNetDbTestTestDnsQueryTCP_SOA);
  lSuite.AddTest('TestDnsQueryCompressUDP_SOA', @RunTNetDbTestTestDnsQueryCompressUDP_SOA);
  lSuite.AddTest('TestDnsQueryCompressTCP_SOA', @RunTNetDbTestTestDnsQueryCompressTCP_SOA);
  lSuite.AddTest('TestDnsQueryUDP_CNAME', @RunTNetDbTestTestDnsQueryUDP_CNAME);
  lSuite.AddTest('TestDnsQueryTCP_CNAME', @RunTNetDbTestTestDnsQueryTCP_CNAME);
  lSuite.AddTest('TestDnsQueryCompressUDP_CNAME', @RunTNetDbTestTestDnsQueryCompressUDP_CNAME);
  lSuite.AddTest('TestDnsQueryCompressTCP_CNAME', @RunTNetDbTestTestDnsQueryCompressTCP_CNAME);
  lSuite.AddTest('TestDnsQueryUDP_NS', @RunTNetDbTestTestDnsQueryUDP_NS);
  lSuite.AddTest('TestDnsQueryTCP_NS', @RunTNetDbTestTestDnsQueryTCP_NS);
  lSuite.AddTest('TestDnsQueryCompressUDP_NS', @RunTNetDbTestTestDnsQueryCompressUDP_NS);
  lSuite.AddTest('TestDnsQueryCompressTCP_NS', @RunTNetDbTestTestDnsQueryCompressTCP_NS);
  lSuite.AddTest('TestDnsQueryUDP_PTR', @RunTNetDbTestTestDnsQueryUDP_PTR);
  lSuite.AddTest('TestDnsQueryTCP_PTR', @RunTNetDbTestTestDnsQueryTCP_PTR);
  lSuite.AddTest('TestDnsQueryCompressUDP_PTR', @RunTNetDbTestTestDnsQueryCompressUDP_PTR);
  lSuite.AddTest('TestDnsQueryCompressTCP_PTR', @RunTNetDbTestTestDnsQueryCompressTCP_PTR);
  lSuite.AddTest('TestDnsQueryUDP_TXT', @RunTNetDbTestTestDnsQueryUDP_TXT);
  lSuite.AddTest('TestDnsQueryTCP_TXT', @RunTNetDbTestTestDnsQueryTCP_TXT);
  lSuite.AddTest('TestDnsQueryCompressUDP_TXT', @RunTNetDbTestTestDnsQueryCompressUDP_TXT);
  lSuite.AddTest('TestDnsQueryCompressTCP_TXT', @RunTNetDbTestTestDnsQueryCompressTCP_TXT);
  lSuite.AddTest('TestDnsQueryUDP_SRV', @RunTNetDbTestTestDnsQueryUDP_SRV);
  lSuite.AddTest('TestDnsQueryTCP_SRV', @RunTNetDbTestTestDnsQueryTCP_SRV);
  lSuite.AddTest('TestDnsQueryCompressUDP_SRV', @RunTNetDbTestTestDnsQueryCompressUDP_SRV);
  lSuite.AddTest('TestDnsQueryCompressTCP_SRV', @RunTNetDbTestTestDnsQueryCompressTCP_SRV);
  lSuite.AddTest('TestDnsQueryTruncateRR_UDP_A', @RunTNetDbTestTestDnsQueryTruncateRR_UDP_A);
  lSuite.AddTest('TestDnsRRBufferEdgeA', @RunTNetDbTestTestDnsRRBufferEdgeA);
  lSuite.AddTest('TestDnsRRBufferPastEdgeA', @RunTNetDbTestTestDnsRRBufferPastEdgeA);
  lSuite.AddTest('TestDnsRRBufferEdgeAAAA', @RunTNetDbTestTestDnsRRBufferEdgeAAAA);
  lSuite.AddTest('TestDNsRRBufferPastEdgeAAAA', @RunTNetDbTestTestDNsRRBufferPastEdgeAAAA);
  lSuite.AddTest('TestDnsRRBufferEdgeMX', @RunTNetDbTestTestDnsRRBufferEdgeMX);
  lSuite.AddTest('TestDnsRRBufferPastEdgeMX', @RunTNetDbTestTestDnsRRBufferPastEdgeMX);
  lSuite.AddTest('TestDnsRRBufferEdgeSOA', @RunTNetDbTestTestDnsRRBufferEdgeSOA);
  lSuite.AddTest('TestDnsRRBufferPastEdgeSOA', @RunTNetDbTestTestDnsRRBufferPastEdgeSOA);
  lSuite.AddTest('TestDnsRRBufferEdgeSRV', @RunTNetDbTestTestDnsRRBufferEdgeSRV);
  lSuite.AddTest('TestDnsRRBufferPastEdgeSRV', @RunTNetDbTestTestDnsRRBufferPastEdgeSRV);
  lSuite.AddTest('TestDnsRRBufferEdgeCNAME', @RunTNetDbTestTestDnsRRBufferEdgeCNAME);
  lSuite.AddTest('TestDnsRRBufferPastEdgeCNAME', @RunTNetDbTestTestDnsRRBufferPastEdgeCNAME);
  lSuite.AddTest('TestDnsRRBufferEdgeNS', @RunTNetDbTestTestDnsRRBufferEdgeNS);
  lSuite.AddTest('TestDnsRRBufferPastEdgeNS', @RunTNetDbTestTestDnsRRBufferPastEdgeNS);
  lSuite.AddTest('TestDnsRRBufferEdgePTR', @RunTNetDbTestTestDnsRRBufferEdgePTR);
  lSuite.AddTest('TestDnsRRBufferPastEdgePTR', @RunTNetDbTestTestDnsRRBufferPastEdgePTR);
  lSuite.AddTest('TestDnsRRBufferEdgeTXT', @RunTNetDbTestTestDnsRRBufferEdgeTXT);
  lSuite.AddTest('TestDnsRRBufferPastEdgeTXT', @RunTNetDbTestTestDnsRRBufferPastEdgeTXT);
  lSuite.AddTest('TestDnsRRBufferEdgeTCPA', @RunTNetDbTestTestDnsRRBufferEdgeTCPA);
  lSuite.AddTest('TestDnsRRBufferPastEdgeTCPA', @RunTNetDbTestTestDnsRRBufferPastEdgeTCPA);
  lSuite.AddTest('TestDnsRRBufferEdgeTCPAAAA', @RunTNetDbTestTestDnsRRBufferEdgeTCPAAAA);
  lSuite.AddTest('TestDNsRRBufferPastEdgeTCPAAAA', @RunTNetDbTestTestDNsRRBufferPastEdgeTCPAAAA);
  lSuite.AddTest('TestDnsRRBufferEdgeTCPMX', @RunTNetDbTestTestDnsRRBufferEdgeTCPMX);
  lSuite.AddTest('TestDnsRRBufferPastEdgeTCPMX', @RunTNetDbTestTestDnsRRBufferPastEdgeTCPMX);
  lSuite.AddTest('TestDnsRRBufferEdgeTCPSOA', @RunTNetDbTestTestDnsRRBufferEdgeTCPSOA);
  lSuite.AddTest('TestDnsRRBufferPastEdgeTCPSOA', @RunTNetDbTestTestDnsRRBufferPastEdgeTCPSOA);
  lSuite.AddTest('TestDnsRRBufferEdgeTCPSRV', @RunTNetDbTestTestDnsRRBufferEdgeTCPSRV);
  lSuite.AddTest('TestDnsRRBufferPastEdgeTCPSRV', @RunTNetDbTestTestDnsRRBufferPastEdgeTCPSRV);
  lSuite.AddTest('TestDnsRRBufferEdgeTCPCNAME', @RunTNetDbTestTestDnsRRBufferEdgeTCPCNAME);
  lSuite.AddTest('TestDnsRRBufferPastEdgeTCPCNAME', @RunTNetDbTestTestDnsRRBufferPastEdgeTCPCNAME);
  lSuite.AddTest('TestDnsRRBufferEdgeTCPNS', @RunTNetDbTestTestDnsRRBufferEdgeTCPNS);
  lSuite.AddTest('TestDnsRRBufferPastEdgeTCPNS', @RunTNetDbTestTestDnsRRBufferPastEdgeTCPNS);
  lSuite.AddTest('TestDnsRRBufferEdgeTCPPTR', @RunTNetDbTestTestDnsRRBufferEdgeTCPPTR);
  lSuite.AddTest('TestDnsRRBufferPastEdgeTCPPTR', @RunTNetDbTestTestDnsRRBufferPastEdgeTCPPTR);
  lSuite.AddTest('TestDnsRRBufferEdgeTCPTXT', @RunTNetDbTestTestDnsRRBufferEdgeTCPTXT);
  lSuite.AddTest('TestDnsRRBufferPastEdgeTCPTXT', @RunTNetDbTestTestDnsRRBufferPastEdgeTCPTXT);
  lSuite.AddTest('TestNextNameRREdgeA', @RunTNetDbTestTestNextNameRREdgeA);
  lSuite.AddTest('TestNextNameRRPastEdgeA', @RunTNetDbTestTestNextNameRRPastEdgeA);
  lSuite.AddTest('TestNextNameRREdgeTCPA', @RunTNetDbTestTestNextNameRREdgeTCPA);
  lSuite.AddTest('TestNextNameRRPastEdgeTCPA', @RunTNetDbTestTestNextNameRRPastEdgeTCPA);
  lSuite.AddTest('TestGetRRrecordsInvalidStart', @RunTNetDbTestTestGetRRrecordsInvalidStart);
  lSuite.AddTest('TestGetRRrecordsInvalidStartTCP', @RunTNetDbTestTestGetRRrecordsInvalidStartTCP);
  lSuite.AddTest('TestGetFixLenStrSimple', @RunTNetDbTestTestGetFixLenStrSimple);
  lSuite.AddTest('TestGetFixLenStrSimpleTCP', @RunTNetDbTestTestGetFixLenStrSimpleTCP);
  lSuite.AddTest('TestGetFixLenStrSimpleAtEdge', @RunTNetDbTestTestGetFixLenStrSimpleAtEdge);
  lSuite.AddTest('TestGetFixLenStrSimpleTCPAtEdge', @RunTNetDbTestTestGetFixLenStrSimpleTCPAtEdge);
  lSuite.AddTest('TestGetFixLenStrSimplePastEdge', @RunTNetDbTestTestGetFixLenStrSimplePastEdge);
  lSuite.AddTest('TestGetFixLenStrSimpleTCPPastEdge', @RunTNetDbTestTestGetFixLenStrSimpleTCPPastEdge);
  lSuite.AddTest('TestStringFromLabelCountAsLastByte', @RunTNetDbTestTestStringFromLabelCountAsLastByte);
  lSuite.AddTest('TestStringFromLabelCountAsLastByteTCP', @RunTNetDbTestTestStringFromLabelCountAsLastByteTCP);
  lSuite.AddTest('TestStringFromLabelCompress', @RunTNetDbTestTestStringFromLabelCompress);
  lSuite.AddTest('TestStringFromLabelCompressTCP', @RunTNetDbTestTestStringFromLabelCompressTCP);
  lSuite.AddTest('TestStringFromLabelCompressWithUncompressedLabel', @RunTNetDbTestTestStringFromLabelCompressWithUncompressedLabel);
  lSuite.AddTest('TestStringFromLabelCompressWithUncompressedLabelTCP', @RunTNetDbTestTestStringFromLabelCompressWithUncompressedLabelTCP);
  lSuite.AddTest('TestStringFromLabelCompressEndBuffer', @RunTNetDbTestTestStringFromLabelCompressEndBuffer);
  lSuite.AddTest('TestStringFromLabelCompressEndBufferTCP', @RunTNetDbTestTestStringFromLabelCompressEndBufferTCP);
  lSuite.AddTest('TestStringFromLabelCompressSplit', @RunTNetDbTestTestStringFromLabelCompressSplit);
  lSuite.AddTest('TestStringFromLabelCompressSplitTCP', @RunTNetDbTestTestStringFromLabelCompressSplitTCP);
  lSuite.AddTest('TestStringFromLabelCompressPtrFwd', @RunTNetDbTestTestStringFromLabelCompressPtrFwd);
  lSuite.AddTest('TestStringFromLabelCompressPtrFwdTCP', @RunTNetDbTestTestStringFromLabelCompressPtrFwdTCP);
  lSuite.AddTest('TestStringFromLabelCompressAllPtrStart', @RunTNetDbTestTestStringFromLabelCompressAllPtrStart);
  lSuite.AddTest('TestStringFromLabelCompressAllPtrStartTCP', @RunTNetDbTestTestStringFromLabelCompressAllPtrStartTCP);
  lSuite.AddTest('TestStringFromLabelCompressedZero', @RunTNetDbTestTestStringFromLabelCompressedZero);
  lSuite.AddTest('TestStringFromLabelCompressedZeroTCP', @RunTNetDbTestTestStringFromLabelCompressedZeroTCP);
  lSuite.AddTest('TestStringFromLabelInfiniteLoop', @RunTNetDbTestTestStringFromLabelInfiniteLoop);
  lSuite.AddTest('TestStringFromLabelInfiniteLoopTCP', @RunTNetDbTestTestStringFromLabelInfiniteLoopTCP);
  lSuite.AddTest('TestCompressShortDomain', @RunTNetDbTestTestCompressShortDomain);
  lSuite.AddTest('TestCompressShortDomainTCP', @RunTNetDbTestTestCompressShortDomainTCP);
end;

end.

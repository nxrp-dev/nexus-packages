unit utNXSynapseResolver;
{
    This file is part of the Free Pascal run time library.
    Copyright (c) 2003 by the Free Pascal development team

    Implement networking routines.

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

// Resolver support extracted from FCL Net for Synapse. Database query records
// and DNS packet helpers are private; callers use Synapse's socket interface.
{$mode objfpc}{$H+}
interface
uses Sockets;
function FindHostAddress(const AName: string; out AAddress: TInAddr): Boolean;
function ResolveName(const HostName: string; var Addresses: array of TInAddr): Integer;
function ResolveName6(const HostName: string; var Addresses: array of TIn6Addr): Integer;
function ResolveAddress(HostAddr: TInAddr; var Addresses: array of string): Integer;
function ResolveAddress6(HostAddr: TIn6Addr; var Addresses: array of string): Integer;
function ResolveServicePort(const AName: string; AProtocol: Integer): Word;
implementation
{$if defined(android) or defined(FPC_USE_LIBC)}
{$define NX_RESOLVER_LIBC}
{$endif}
uses BaseUnix, SysUtils{$ifdef NX_RESOLVER_LIBC}, InitC{$endif};
{$ifndef NX_RESOLVER_LIBC}
const
  DNSPort = 53;
  SHostsFile = 'hosts';
  SProtocolFile = 'protocols';
  SServicesFile = 'services';
  SResolveFile = 'resolv.conf';
  MaxRecursion = 10;
  MaxIP4Mapped = 10;
  DNSQRY_A = 1;
  DNSQRY_AAAA = 28;
  DNSQRY_PTR = 12;
  DNSQRY_CNAME = 5;
  QF_QR = $80;
  QF_OPCODE = $78;
  QF_RD = $01;
  QF_RCODE = $0F;
type
  THostEntry = record
    Name: string;
    Addr: TInAddr;
    Aliases: string;
  end;
  PHostListEntry = ^THostListEntry;
  THostListEntry = record
    Entry: THostEntry;
    Next: PHostListEntry;
  end;
  TProtocolEntry = record
    Name: string;
    Number: Integer;
    Aliases: string;
  end;
  TServiceEntry = record
    Name, Protocol: string;
    Port: Word;
    Aliases: string;
  end;
  TDNSServerArray = array of TInAddr;
  TPayLoad = array[0..511] of Byte;
  TDNSHeader = packed record
    ID: array[0..1] of Byte;
    Flags1, Flags2: Byte;
    QDCount, ANCount, NSCount, ARCount: Word;
  end;
  TQueryData = packed record
    H: TDNSHeader;
    Payload: TPayLoad;
  end;
  PRRData = ^TRRData;
  TRRData = packed record
    AType, AClass: Word;
    TTL: Cardinal;
    RDLength: Word;
  end;
var
  EtcPath: string;
  DNSServers: TDNSServerArray;
  DNSOptions, DefaultDomainList: string;
  DefaultDomainListArr: array of string;
  NDots: Integer;
  CheckResolveFileAge, CheckHostsFileAge: Boolean;
  TimeOutS, TimeOutMS: LongInt;
Const
  Whitespace = [' ',#9];

Function NextWord(Var Line : String) : String;

Var
  I,J : Integer;

begin
  I:=1;
  While (I<=Length(Line)) and (Line[i] in Whitespace) do
    inc(I);
  J:=I;
  While (J<=Length(Line)) and Not (Line[J] in WhiteSpace) do
    inc(j);
  Result:=Copy(Line,I,J-I);
  Delete(Line,1,J);
end;

Function StripComment(var L : String) : Boolean;

Var
  i : Integer;

begin
  I:=Pos('#',L);
  If (I<>0) then
    L:=Copy(L,1,I-1)
  else
    begin
      I:=Pos(';',L);
      If (I<>0) then
        L:=Copy(L,1,I-1)
    end;
  Result:=Length(L)>0;
end;

Function MatchNameOrAlias(Const Entry,Name: String; Aliases : String) : Boolean;

Var
  P : Integer;
  A : String;

begin
  Result:=CompareText(Entry,Name)=0;
  If Not Result then
    While (Not Result) and (Length(Aliases)>0) do
      begin
      P:=Pos(',',Aliases);
      If (P=0) then
        P:=Length(Aliases)+1;
      A:=Copy(Aliases,1,P-1);
      Delete(Aliases,1,P);
      Result:=CompareText(A,Entry)=0;
      end;
end;

{ ---------------------------------------------------------------------
    hosts processing
  ---------------------------------------------------------------------}

Function GetAddr(Var L : String; Var Addr : TInAddr) : Boolean;

Var
  S : String;
//  i,p,a : Integer;

begin
  Result:=True;
  S:=NextWord(L);
  Addr:=StrToNetAddr(S);
//  Writeln(s,'->',Addr.s_bytes[1],'.',Addr.s_bytes[2],'.',Addr.s_bytes[3],'.',Addr.s_bytes[4]);
  Result:=Addr.s_bytes[1]<>0;
end;


Function FillHostEntry (Var Entry : THostEntry; L: String) : boolean;

Var
  H : String;

begin
  Result := False;
  Repeat
  H:=NextWord(L);
    If (H<>'') then begin
      if (Entry.Name='') then
        Entry.Name:=H
      else
        begin
        If (Entry.Aliases<>'') then
          Entry.Aliases:=Entry.Aliases+',';
        Entry.Aliases:=Entry.Aliases+H;
        end;
      Result := True;
    end;
  until (H='');
end;

Function ProcessHosts(const FileName : String) : PHostListEntry;

Var
  F : Text;
  L : String;
  A : TInAddr;
  T : PHostListEntry;
  B : Array of byte;
  FS : Int64;

begin
  Result:=Nil;
  Assign(F,FileName);
  {$push}{$I-}
  Reset(F);
  SetLength(B,65355);
  SetTextBuf(F,B[0],65355);
  {$pop};
  If (IOResult<>0) then
    Exit;
  Try
    While Not EOF(F) do
      begin
      Readln(F,L);
      If StripComment(L) then
        begin
        If GetAddr(L,A) then
          begin
          T:=New(PHostListEntry);
          T^.Entry.Addr:=A;
          FillHostEntry(T^.Entry,L);
          T^.Next:=Result;
          Result:=T;
          end;
        end;
      end;
  Finally
    Close(F);
  end;
end;

{ Internal lookup, used in GetHostByName and friends. }

Var
  HostsList : PHostListEntry = Nil;
  HostsFileAge  : Longint;
//  HostsFileName : String;

Function FreeHostsList(var List : PHostListEntry) : Integer;

Var
  P : PHostListEntry;

begin
  Result:=0;
  While (List<>Nil) do
    begin
    Inc(Result);
    P:=List^.Next;
    Dispose(List);
    List:=P;
    end;
end;


Procedure CheckHostsFile;

Var
  F : Integer;

begin
  If CheckHostsFileAge then
    begin
    F:=FileAge (EtcPath + SHostsFile);
    If HostsFileAge<F then
      begin
      // Rescan.
      FreeHostsList(HostsList);
      HostsList:=ProcessHosts (EtcPath + SHostsFile);
      HostsFileAge:=F;
      end;
    end;
end;

Function FindHostEntryInHostsFile(const N: String; Addr: TInAddr; Var H : THostEntry) : boolean;

Var
//  F : Text;
  HE : THostEntry;
  P : PHostListEntry;

begin
  Result:=False;
  CheckHostsFile;
  P:=HostsList;
  While (Not Result) and (P<>Nil) do
    begin
    HE:=P^.Entry;
    If (N<>'') then
      Result:=MatchNameOrAlias(N,HE.Name,HE.Aliases)
    else
      Result:=Cardinal(hosttonet(Addr))=Cardinal(HE.Addr);
    P:=P^.Next;
    end;
 If Result then
   begin
   H.Name:=HE.Name;
   H.Addr:=nettohost(HE.Addr);
   H.Aliases:=HE.Aliases;
   end;
end;

{ ---------------------------------------------------------------------
   Resolve.conf handling
  ---------------------------------------------------------------------}


Var
  ResolveFileAge  : Longint;
  ResolveFileName : String;

Function GetDNSServers(const Fn : String) : Integer;

Var
  R : Text;
  L : String;
//  I : Integer;
  H : TInAddr;
  E : THostEntry;

  Function CheckDirective(const Dir : String) : Boolean;

  Var
    P : Integer;

  begin
    P:=Pos(Dir,L);
    Result:=(P<>0);
    If Result then
      begin
      Delete(L,1,P+Length(Dir));
      L:=Trim(L);
      end;
  end;

begin
  Result:=0;
  ResolveFileName:=Fn;
  ResolveFileAge:=FileAge(FN);
  DefaultDomainListArr:=[];
  NDots:=1;
  {$push}{$i-}
  Assign(R,FN);
  Reset(R);
  {$pop}
  If (IOResult<>0) then
    exit;
  Try
    While not EOF(R) do
      begin
      Readln(R,L);
      if StripComment(L) then
        If CheckDirective('nameserver') then
          begin
          H:=HostToNet(StrToHostAddr(L));
          If (H.s_bytes[1]<>0) then
            begin
            setlength(DNSServers,Result+1);
            DNSServers[Result]:=H;
            Inc(Result);
            end
          else if FindHostEntryInHostsFile(L,H,E) then
            begin
            setlength(DNSServers,Result+1);
            DNSServers[Result]:=E.Addr;
            Inc(Result);
            end;
          end
        else if CheckDirective('domain') then
          DefaultDomainList:=L
        else if CheckDirective('search') then
          DefaultDomainList:=L
        else if CheckDirective('options') then
          DNSOptions:=L;
      end;
  Finally
    Close(R);
  end;
  L := GetEnvironmentVariable('LOCALDOMAIN');
  if L <> '' then
    DefaultDomainList := L;
end;

Procedure CheckResolveFile;

Var
  F : Integer;
  N : String;

begin
  If CheckResolveFileAge then
    begin
    N:=ResolveFileName;
    if (N='') then
      N:=EtcPath + SResolveFile;
    F:=FileAge(N);
    If ResolveFileAge<F then
      GetDnsServers(N);
    end;
end;


Function BuildPayLoad(Var Q : TQueryData; Name : String; RR : Word; QClass : Word) : Integer;

Var
  P : PByte;
  l,S : Integer;

begin
  Result:=-1;
  If (Length(Name) = 0) or (length(Name)>506) then
    Exit;

  Result:=0;
  P:=@Q.Payload[0];
  Repeat
    L:=Pos('.',Name);
    If (L=0) then
      S:=Length(Name)
    else
      S:=L-1;
    // empty label is invalid, unless it's a dot at the end.
    if (S = 0) then
    begin
      if (Length(Name) > 0) then
      begin
        Result := -1;
        exit;
      end
      else
        break; // empty label at end, break out for final 0 length byte.
    end;
    P[Result]:=S;
    Move(Name[1],P[Result+1],S);
    Inc(Result,S+1);
    If (L>0) then
      Delete(Name,1,L);
  Until (L=0);
  P[Result]:=0;
  rr := htons(rr);
  Move(rr,P[Result+1],2);
  Inc(Result,3);
  QClass := htons(QClass);
  Move(qclass,P[Result],2);
  Inc(Result,2);
end;

{Construct a TCP query payload from the given name, rr and qclass. The
 principal difference between the TCP and UDP payloads is the two-octet
 length field in the TCP payload. The UDP payload has no length field.

 See RFC-1035, section 4.2.2.

 Returns the length of the constructed payload, which doesn't include
 the header or the length field.}

Function NextRR(Const PayLoad : TPayLoad;Var Start : LongInt; AnsLen : LongInt; Var RR : TRRData) : Boolean;

Var
  I : Integer;
  HaveName : Boolean;
  PA : PRRData;

begin
  Result:=False;
  I:=Start;
  // Skip labels and pointers. At least 1 label or pointer is present.
  Repeat
    HaveName:=True;
    If (Payload[i]>63) then // Pointer, skip
      Inc(I,2)
    else If Payload[i]=0 then // Null termination of label, skip.
      Inc(i)
    else
      begin
      Inc(I,Payload[i]+1); // Label, continue scan.
      HaveName:=False;
      end;
  Until HaveName or (I>(AnsLen-SizeOf(TRRData)));
  Result:=(I<=(AnsLen-SizeOf(TRRData)));
  // Check RR record.
  PA:=PRRData(@Payload[i]);
  RR:=PA^;
  Start:=I+SizeOf(TRRData);
end;


Function BuildName (Const PayLoad : TPayLoad; Start,len : Integer) : String;

Const
  FIREDNS_POINTER_VALUE = $C000;

Var
  I,O : Integer;
  P : Word;

begin
  SetLength(Result,512);
  I:=Start;
  O:=1;
  // Copy labels and pointers. At least 1 label or pointer is present.
  Repeat
    If (Payload[i]>63) then // Pointer, move.
      begin
      Move(Payload[i],P,2);
      I:=ntohs(p)-FIREDNS_POINTER_VALUE-12;
      end
    else if Payload[i]<>0 then // Label, copy
      begin
      If O<>1 then
        begin
        Result[O]:='.';
        Inc(O);
        end;
      P:=Payload[i];
      Move(Payload[i+1],Result[o],P);
      Inc(I,P+1);
      Inc(O,P);
      end;
   Until (Payload[I]=0);
   setlength(result,o-1);
end;


{ ---------------------------------------------------------------------
    QueryData handling functions
  ---------------------------------------------------------------------}

function CheckAnswer(const Qry: TDNSHeader; var Ans: TDNSHeader): Boolean;
begin
  Result:=False;
  With Ans do
    begin
    // Check ID.
    If (ID[1]<>QRY.ID[1]) or (ID[0]<>Qry.ID[0]) then
      exit;
    // Flags ?
    If (Flags1 and QF_QR)=0 then
      exit;
    if (Flags1 and QF_OPCODE)<>0 then
      exit;
    if (Flags2 and QF_RCODE)<>0 then
      exit;
    // Number of answers ?
    AnCount := htons(Ancount);
    If Ancount<1 then
      Exit;
    Result:=True;
    end;
end;

{
 Check that Atype is valid. These are the DNSQRY_? params we support. See the
 definitions at the top of this unit for the names.
 Deliberately excluding axfr (252), mailb (253), maila (254), and * (255).
}

Function SkipAnsQueries(Var Ans : TQueryData; L : Integer) : integer;

Var
  Q,I : Integer;

begin
  Result:=0;
  With Ans do
    begin
    h.qdcount := htons(h.qdcount);
    i:=0;
    q:=0;
    While (Q<h.qdcount) and (i<l) do
      begin
      If Payload[i]>63 then
        begin
        Inc(I,6);
        Inc(Q);
        end
      else
        begin
        If Payload[i]=0 then
          begin
          inc(q);
          Inc(I,5);
          end
        else
          Inc(I,Payload[i]+1);
        end;
      end;
    Result:=I;
    end;
end;


Function Query(Resolver : Integer; Var Qry,Ans : TQueryData; QryLen : Integer; Var AnsLen : Integer) : Boolean;

Var
  SA : TInetSockAddr;
  Sock,L : Longint;
  Al,RTO : Longint;
  ReadFDS : TFDSet;

begin
  Result:=False;
  With Qry.h do
    begin
    ID[0]:=Random(256);
    ID[1]:=Random(256);
    Flags1:=QF_RD;
    Flags2:=0;
    qdcount:=htons(1); // was 1 shl 8;
    ancount:=0;
    nscount:=0;
    arcount:=0;
    end;
  Sock:=FpSocket(PF_INET,SOCK_DGRAM,0);
  If Sock=-1 then
    exit;
  With SA do
    begin
    sin_family:=AF_INET;
    sin_port:=htons(DNSport);
    sin_addr.s_addr:=cardinal(DNSServers[Resolver]); // dnsservers already in net order
    end;
  fpsendto(sock,@qry,qrylen+12,0,@SA,SizeOf(SA));
  // Wait for answer.
  RTO:=TimeOutS*1000+TimeOutMS;
  fpFD_ZERO(ReadFDS);
  fpFD_Set(sock,readfds);
  if fpSelect(Sock+1,@readfds,Nil,Nil,RTO)<=0 then
    begin
    fpclose(Sock);
    exit;
    end;
  AL:=SizeOf(SA);
  L:=fprecvfrom(Sock,@ans,SizeOf(Ans),0,@SA,@AL);
  fpclose(Sock);

  if L < 12 then exit;
  // Return Payload length.
  Anslen:=L-12;
  // even though we may still return false to indicate an error, if AnsLen
  // is >= 0 then the caller knows the dns server responded.
  If not CheckAnswer(Qry.h,Ans.h) Then
    exit;
  Result:=True;
  //end;
end;


function stringfromlabel(pl: TPayLoad; var start: Integer): string;
var
  l,i,n,lc: integer;
  ptr: Word;
  ptrseen: Boolean = False;
begin
  result := '';
  l := 0;
  i := 0;
  n := start;
  // Label counter. Per rfc1035, s. 3.1, each label is at least 2 bytes and the
  // max length for a domain is 255, so there can't be more than 127 labels.
  // This helps to short-circuit loops in label pointers.
  lc := 0;
  repeat
    // each iteration of this loop is for one label. whether a pointer or a
    // regular label, we need 2 bytes headroom minimum.
    if n > (Length(pl) - 2) then break;
    l := ord(pl[n]);
    { compressed reply }
    while (l >= 192) do
      begin
        if not ptrseen then start := n + 2;
        ptrseen := True;
        ptr := (l and not(192)) shl 8 + ord(pl[n+1]);
        {ptr must point backward and be >= 12 (for the dns header.}
        if (ptr >= (n+12)) or (ptr < 12) then l := 0 // l=0 causes loop to exit
        else
        begin
          { the -12 is because of the reply header length. we do the decrement
          here to avoid overflowing if ptr < 12.}
          n := ptr - 12;
          l := ord(pl[n]);
        end;
      end;
    // check we point inside the buffer
    if (n+l+1) > Length(pl) then l := 0;
    if l <> 0 then begin
      setlength(result,length(result)+l);
      move(pl[n+1],result[i+1],l);
      result := result + '.';
      inc(n,l); inc(n);
      inc(i,l); inc(i);
      if n > start then start := n;
    end;
    Inc(lc); // label count
  until (l = 0) or (lc > 127);
  // per rfc1035, section 4.1.4, a domain name may be represented by
  // either a sequence of labels followed by 0, or a pointer, or a series
  // of labels followed by a pointer. If there's a pointer there's no 0 to
  // skip over when calculating the final index.
  if not ptrseen then Inc(start); // jump past the 0.
  if (Length(result) > 0) and (result[length(result)] = '.') then
    setlength(result,length(result)-1);
end;


Function ResolveNameAt(Resolver : Integer; const HostName : String; Var Addresses : Array of TInAddr; Recurse: Integer) : Integer;

Var
  Qry, Ans            : TQueryData;
  MaxAnswer,I,QryLen,
  AnsLen,AnsStart     : Longint;
  RR                  : TRRData;
  cname               : string;
begin
  Result:=0;
  QryLen:=BuildPayLoad(Qry,HostName,DNSQRY_A,1);
  If Not Query(Resolver,Qry,Ans,QryLen,AnsLen) then
    Result:=-1
  else
    begin
    AnsStart:=SkipAnsQueries(Ans,AnsLen);
    MaxAnswer:=Ans.h.AnCount-1;
    If MaxAnswer>High(Addresses) then
      MaxAnswer:=High(Addresses);
    I:=0;
    While (I<=MaxAnswer) and NextRR(Ans.Payload,AnsStart,AnsLen,RR) do
      begin
      if htons(rr.AClass) = 1 then
        case ntohs(rr.AType) of
          DNSQRY_A: begin
            Move(Ans.PayLoad[AnsStart],Addresses[i],SizeOf(TInAddr));
            inc(Result);
            Inc(AnsStart,htons(RR.RDLength));
          end;
          DNSQRY_CNAME: begin
            if Recurse >= MaxRecursion then begin
              Result := -1;
              exit;
            end;
            rr.rdlength := ntohs(rr.rdlength);
            setlength(cname, rr.rdlength);
            cname := stringfromlabel(ans.payload, ansstart);
            Result := ResolveNameAt(Resolver, cname, Addresses, Recurse+1);
            exit; // FIXME: what about other servers?!
          end;
        end;
        Inc(I);
      end;
    end;
end;

Function ResolveName(const HostName : String; Var Addresses : Array of TInAddr) : Integer;

Var
  I : Integer;

begin
  CheckResolveFile;
  I:=0;
  Result:=0;
  While (Result<=0) and (I<=high(DNSServers)) do
    begin
    Result:=ResolveNameAt(I,HostName,Addresses,0);
    Inc(I);
    end;
end;

//const NoAddress6 : array[0..7] of word = (0,0,0,0,0,0,0,0);

Function ResolveNameAt6(Resolver : Integer; const HostName : String; Var Addresses : Array of TIn6Addr; Recurse: Integer) : Integer;

Var
  Qry, Ans            : TQueryData;
  MaxAnswer,I,QryLen,
  AnsLen,AnsStart     : Longint;
  RR                  : TRRData;
  cname               : string;
  LIP4mapped: array[0..MaxIP4Mapped-1] of TInAddr;
  LIP4count: Longint;

begin
  Result:=0;
  QryLen:=BuildPayLoad(Qry,HostName,DNSQRY_AAAA,1);
  If Not Query(Resolver,Qry,Ans,QryLen,AnsLen) then begin
    // no answer? try IPv4 mapped addresses, maybe that will generate one
    LIP4Count := ResolveName(HostName, LIP4Mapped);
    if LIP4Count > 0 then begin
      inc(LIP4Count); // we loop to LIP4Count-1 later
      if LIP4Count > MaxIP4Mapped then LIP4Count := MaxIP4Mapped;
      if LIP4Count > Length(Addresses) then LIP4Count := Length(Addresses);
      for i := 0 to LIP4Count-2 do begin
        Addresses[i] := NoAddress6;
        Addresses[i].u6_addr16[5] := $FFFF;
        Move(LIP4Mapped[i], Addresses[i].u6_addr16[6], 4);
      end;
      Result := LIP4Count;
    end else begin
      Result:=-1
    end;
  end else
    begin
    AnsStart:=SkipAnsQueries(Ans,AnsLen);
    MaxAnswer:=Ans.h.AnCount-1;
    If MaxAnswer>High(Addresses) then
      MaxAnswer:=High(Addresses);
    I:=0;
    While (I<=MaxAnswer) and NextRR(Ans.Payload,AnsStart,AnsLen,RR) do
      begin
      if (1=NtoHS(RR.AClass)) then
      case ntohs(rr.atype) of
        DNSQRY_AAAA: begin
            Move(Ans.PayLoad[AnsStart],Addresses[i],SizeOf(TIn6Addr));
            inc(Result);
            rr.rdlength := ntohs(rr.rdlength);
            Inc(AnsStart,RR.RDLength);
          end;
        DNSQRY_CNAME: begin
          if Recurse >= MaxRecursion then begin
            Result := -1;
            exit;
          end;
          rr.rdlength := ntohs(rr.rdlength);
          setlength(cname, rr.rdlength);
          cname := stringfromlabel(ans.payload, ansstart);
          Result := ResolveNameAt6(Resolver, cname, Addresses, Recurse+1);
          exit; // FIXME: what about other servers?!
        end;
      end;
      Inc(I);
      end;
    end;
end;



Function ResolveName6(const HostName: String; Var Addresses: Array of TIn6Addr) : Integer;
var
  i: Integer;
begin
  CheckResolveFile;
  i := 0;
  Result := 0;
  while (Result <= 0) and (I<= high(DNSServers)) do begin
    Result := ResolveNameAt6(I, Hostname, Addresses, 0);
    Inc(i);
  end;
end;

Function ResolveAddressAt(Resolver : Integer; Address : String; Var Names : Array of String; Recurse: Integer) : Integer;


Var
  Qry, Ans            : TQueryData;
  MaxAnswer,I,QryLen,
  AnsLen,AnsStart     : Longint;
  RR                  : TRRData;

begin
  Result:=0;
  QryLen:=BuildPayLoad(Qry,Address,DNSQRY_PTR,1);
  If Not Query(Resolver,Qry,Ans,QryLen,AnsLen) then
    Result:=-1
  else
    begin
    AnsStart:=SkipAnsQueries(Ans,AnsLen);
    MaxAnswer:=Ans.h.AnCount-1;
    If MaxAnswer>High(Names) then
      MaxAnswer:=High(Names);
    I:=0;
    While (I<=MaxAnswer) and NextRR(Ans.Payload,AnsStart,AnsLen,RR) do
      begin
      Case Ntohs(RR.AType) of
        DNSQRY_PTR:
          if (1=NtoHS(RR.AClass)) then
            begin
            Names[i]:=BuildName(Ans.Payload,AnsStart,AnsLen);
            inc(Result);
            RR.RDLength := ntohs(RR.RDLength);
            Inc(AnsStart,RR.RDLength);
            end;
        DNSQRY_CNAME:
          begin
          if Recurse >= MaxRecursion then
            begin
            Result := -1;
            exit;
            end;
          rr.rdlength := ntohs(rr.rdlength);
          setlength(Address, rr.rdlength);
          address := stringfromlabel(ans.payload, ansstart);
          Result := ResolveAddressAt(Resolver, Address, Names, Recurse+1);
          exit;
          end;
      end;
      Inc(I);
      end;
    end;
end;


Function ResolveAddress(HostAddr : TInAddr; Var Addresses : Array of String) : Integer;

Var
  I : Integer;
  S : String;
  nt : TInAddr;

begin
  CheckResolveFile;
  I:=0;
  Result:=0;
  nt:=hosttonet(hostaddr);
  S:=Format('%d.%d.%d.%d.in-addr.arpa',[nt.s_bytes[4],nt.s_bytes[3],nt.s_bytes[2],nt.s_bytes[1]]);
  While (Result=0) and (I<=high(DNSServers)) do
    begin
    Result:=ResolveAddressAt(I,S,Addresses,1);
    Inc(I);
    end;
end;

Function ResolveAddress6(HostAddr : TIn6Addr; Var Addresses : Array of String) : Integer;

const
  hexdig: string[16] = '0123456789abcdef';

Var
  I : Integer;
  S : ShortString;

begin
  CheckResolveFile;
  Result:=0;
  S := '0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa';
  for i := 7 downto 0 do begin
    S[5+(7-i)*8] := hexdig[1+(HostAddr.u6_addr16[i] and $000F) shr 00];
    S[7+(7-i)*8] := hexdig[1+(HostAddr.u6_addr16[i] and $00F0) shr 04];
    S[1+(7-i)*8] := hexdig[1+(HostAddr.u6_addr16[i] and $0F00) shr 08];
    S[3+(7-i)*8] := hexdig[1+(HostAddr.u6_addr16[i] and $F000) shr 12];
  end;
  I := 0;
  While (Result=0) and (I<=high(DNSServers)) do
    begin
    Result:=ResolveAddressAt(I,S,Addresses,1);
    Inc(I);
    end;
end;


Function GetHostByName(const HostName: String;  Var H : THostEntry) : boolean;

begin
  Result:=FindHostEntryInHostsFile(HostName,NoAddress,H);
end;



Function GetNextProtoEntry(var F : Text; Var H : TProtocolEntry): boolean;

Var
  Line,S : String;
  I      : integer;

begin
  Result:=False;
  Repeat
    ReadLn(F,Line);
    StripComment(Line);
    S:=NextWord(Line);
    If (S<>'') then
      begin
        H.Name:=S;
        S:=NextWord(Line);
	i:=strtointdef(s,-1);
        If (i<>-1) then
          begin
          H.number:=i;
          Result:=True;
          H.Aliases:='';
          Repeat
            S:=NextWord(line);
            If (S<>'') then
              If (H.Aliases='') then
                H.Aliases:=S
              else
                H.Aliases:=H.Aliases+','+S;
          until (S='');
          end;
      end;
  until Result or EOF(F);
end;

Function FindProtoEntryInProtoFile(const N: String; prot: integer; Var H : TProtocolEntry) : boolean;

Var
  F : Text;
  HE : TProtocolEntry;

begin
  Result:=False;
  If FileExists (EtcPath + SProtocolFile) then
    begin
    Assign (F, EtcPath + SProtocolFile);
    {$push}{$i-}
    Reset(F);
    {$pop}
    If (IOResult=0) then
      begin
      While Not Result and GetNextProtoEntry(F,HE) do
        begin
        If (N<>'') then
          Result:=MatchNameOrAlias(N,HE.Name,HE.Aliases)
        else
          Result:=prot=he.number;
        end;
      Close(f);
      If Result then
        begin
        H.Name:=HE.Name;
        H.number:=he.number;
        H.Aliases:=HE.Aliases;
        end;
      end;
    end;
end;


Function GetProtocolByNumber(proto: Integer;  Var H : TProtocolEntry) : boolean;

begin
  Result:=FindProtoEntryInProtoFile('',Proto,H);
end;


Function GetNextServiceEntry(Var F : Text; Var E : TServiceEntry) : Boolean;


Var
  Line,S : String;
  P : INteger;

begin
  Result:=False;
  Repeat
    ReadLn(F,Line);
    StripComment(Line);
    S:=NextWord(Line);
    If (S<>'') then
      begin
      E.Name:=S;
      S:=NextWord(Line);
      P:=Pos('/',S);
      If (P<>0) then
        begin
        E.Port:=StrToIntDef(Copy(S,1,P-1),0);
        If (E.Port<>0) then
          begin
          E.Protocol:=Copy(S,P+1,Length(S)-P);
          Result:=length(E.Protocol)>0;
          E.Aliases:='';
          Repeat
            S:=NextWord(Line);
            If (S<>'') then
              If (Length(E.Aliases)=0) then
                E.aliases:=S
              else
                E.Aliases:=E.Aliases+','+S;
          until (S='');
          end;
        end;
      end;
  until Result or EOF(F);
end;


Function FindServiceEntryInFile(Const Name,Proto : String; Port : Integer; Var E : TServiceEntry) : Boolean;

Var
  F : Text;
  TE : TServiceEntry;

begin
  Result:=False;
  If FileExists (EtcPath + SServicesFile) then
    begin
    Assign (F, EtcPath + SServicesFile);
    {$push}{$i-}
    Reset(F);
    {$pop}
    If (IOResult=0) then
      begin
      While Not Result and GetNextServiceEntry(F,TE) do
        begin
        If (Port=-1) then
          Result:=MatchNameOrAlias(Name,TE.Name,TE.Aliases)
        else
          Result:=(Port=TE.Port);
        If Result and (Proto<>'') then
          Result:=(Proto=TE.Protocol);
        end;
      Close(f);
      If Result then
        begin
        E.Name:=TE.Name;
        E.Port:=TE.Port;
        E.Protocol:=TE.Protocol;
        E.Aliases:=TE.Aliases;
        end;
      end;
    end;
end;

Function GetServiceByName(Const Name,Proto : String; Var E : TServiceEntry) : Boolean;

begin
  Result:=FindServiceEntryInFile(Name,Proto,-1,E);
end;


function FindHostAddress(const AName: string; out AAddress: TInAddr): Boolean;
var
  lHost: THostEntry;
begin
  Result := GetHostByName(AName, lHost);
  if Result then AAddress := lHost.Addr;
end;

function ResolveServicePort(const AName: string; AProtocol: Integer): Word;
var
  lProtocol: TProtocolEntry;
  lService: TServiceEntry;
begin
  Result := 0;
  if GetProtocolByNumber(AProtocol, lProtocol) and
    GetServiceByName(AName, lProtocol.Name, lService) then
    Result := lService.Port; // The parser already returns host byte order.
end;

procedure InitResolver;
begin
  CheckResolveFileAge := False;
  CheckHostsFileAge := False;
  TimeOutS := 5;
  TimeOutMS := 0;
  EtcPath := '/etc/';
  if FileExists(EtcPath + SHostsFile) then
    HostsList := ProcessHosts(EtcPath + SHostsFile);
  if FileExists(EtcPath + SResolveFile) then
    GetDNSServers(EtcPath + SResolveFile);
  if Length(DNSServers) = 0 then
  begin
    SetLength(DNSServers, 1);
    DNSServers[0] := StrToNetAddr('127.0.0.1');
  end;
end;

procedure DoneResolver;
begin
  FreeHostsList(HostsList);
end;
{$else}
{$i nxresolverlibc.inc}
{$endif}
initialization
  InitResolver;
finalization
  DoneResolver;
end.

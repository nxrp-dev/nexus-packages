{*-
 * Copyright (c) 1980, 1983, 1988, 1993
 *	The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the University of
 *	California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * -
 * Portions Copyright (c) 1993 by Digital Equipment Corporation.
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies, and that
 * the name of Digital Equipment Corporation not be used in advertising or
 * publicity pertaining to distribution of the document or software without
 * specific, written prior permission.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND DIGITAL EQUIPMENT CORP. DISCLAIMS ALL
 * WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS.   IN NO EVENT SHALL DIGITAL EQUIPMENT
 * CORPORATION BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
 * DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
 * PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
 * ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
 * SOFTWARE.
 * -
 * --Copyright--
 *}

{*
 *      @(#)netdb.h	8.1 (Berkeley) 6/2/93
 *      From: Id: netdb.h,v 8.9 1996/11/19 08:39:29 vixie Exp $
 * $FreeBSD: src/include/netdb.h,v 1.38.2.1 2005/07/22 20:17:30 ume Exp $
 *}

// Private libc resolver declarations retained for Android/FPC_USE_LIBC.
{$push}
{$packrecords c}
type
  PAddrInfo = ^TAddrInfo;
  TAddrInfo = record
    Flags, Family, SocketType, Protocol: cint;
    AddressLength: TSockLen;
    {$ifdef android}
    CanonicalName: PAnsiChar;
    Address: PSockAddr;
    {$else}
    Address: PSockAddr;
    CanonicalName: PAnsiChar;
    {$endif}
    Next: PAddrInfo;
  end;
  PServiceEntry = ^TServiceEntry;
  TServiceEntry = record
    Name: PAnsiChar;
    Aliases: PPAnsiChar;
    Port: cint;
    Protocol: PAnsiChar;
  end;
  PProtocolEntry = ^TProtocolEntry;
  TProtocolEntry = record
    Name: PAnsiChar;
    Aliases: PPAnsiChar;
    Number: cint;
  end;
{$pop}
function getaddrinfo(AName, AService: PAnsiChar; AHints: PAddrInfo;
  out AResult: PAddrInfo): cint; cdecl; external clib;
procedure freeaddrinfo(AAddress: PAddrInfo); cdecl; external clib;
function getnameinfo(AAddress: PSockAddr; ALength: TSockLen; AHost: PAnsiChar;
  AHostLength: TSize; AService: PAnsiChar; AServiceLength: TSize;
  AFlags: cint): cint; cdecl; external clib;
function getprotobynumber(AProtocol: cint): PProtocolEntry; cdecl; external clib;
function getservbyname(AName, AProtocol: PAnsiChar): PServiceEntry; cdecl; external clib;

function ResolveAddresses(const AName: string; AFamily: cint;
  AAddresses: Pointer; ACount: Integer): Integer;
var
  lHints: TAddrInfo;
  lResult, lAddress: PAddrInfo;
  lIPv4: PInAddr;
  lIPv6: PIn6Addr;
begin
  Result := -1;
  if ACount = 0 then Exit;
  FillChar(lHints, SizeOf(lHints), 0);
  lHints.Family := AFamily;
  lHints.SocketType := SOCK_STREAM;
  lResult := nil;
  if getaddrinfo(PAnsiChar(AName), nil, @lHints, lResult) <> 0 then Exit;
  try
    Result := 0;
    lAddress := lResult;
    lIPv4 := AAddresses;
    lIPv6 := AAddresses;
    while (lAddress <> nil) and (Result < ACount) do
    begin
      if lAddress^.Family = AFamily then
      begin
        if AFamily = AF_INET then
        begin
          lIPv4^ := PInetSockAddr(lAddress^.Address)^.sin_addr;
          Inc(lIPv4);
        end
        else
        begin
          lIPv6^ := PInetSockAddr6(lAddress^.Address)^.sin6_addr;
          Inc(lIPv6);
        end;
        Inc(Result);
      end;
      lAddress := lAddress^.Next;
    end;
  finally
    freeaddrinfo(lResult);
  end;
end;

function ResolveName(const HostName: string; var Addresses: array of TInAddr): Integer;
begin
  if Length(Addresses) = 0 then Exit(-1);
  Result := ResolveAddresses(HostName, AF_INET, @Addresses[0], Length(Addresses));
end;

function ResolveName6(const HostName: string; var Addresses: array of TIn6Addr): Integer;
begin
  if Length(Addresses) = 0 then Exit(-1);
  Result := ResolveAddresses(HostName, AF_INET6, @Addresses[0], Length(Addresses));
end;

function FindHostAddress(const AName: string; out AAddress: TInAddr): Boolean;
var
  lAddresses: array[0..0] of TInAddr;
begin
  Result := ResolveName(AName, lAddresses) > 0;
  if Result then AAddress := NetToHost(lAddresses[0]);
end;

function ResolveHost(AAddress: PSockAddr; ALength: TSockLen;
  var ANames: array of string): Integer;
var
  lName: array[0..1024] of AnsiChar;
begin
  Result := -1;
  if Length(ANames) = 0 then Exit;
  FillChar(lName, SizeOf(lName), 0);
  if getnameinfo(AAddress, ALength, @lName[0], SizeOf(lName), nil, 0, 0) = 0 then
  begin
    ANames[0] := StrPas(@lName[0]);
    Result := 1;
  end;
end;

function ResolveAddress(HostAddr: TInAddr; var Addresses: array of string): Integer;
var
  lAddress: TInetSockAddr;
begin
  FillChar(lAddress, SizeOf(lAddress), 0);
  lAddress.sin_family := AF_INET;
  lAddress.sin_addr := HostToNet(HostAddr);
  Result := ResolveHost(@lAddress, SizeOf(lAddress), Addresses);
end;

function ResolveAddress6(HostAddr: TIn6Addr; var Addresses: array of string): Integer;
var
  lAddress: TInetSockAddr6;
begin
  FillChar(lAddress, SizeOf(lAddress), 0);
  lAddress.sin6_family := AF_INET6;
  lAddress.sin6_addr := HostAddr;
  Result := ResolveHost(@lAddress, SizeOf(lAddress), Addresses);
end;

function ResolveServicePort(const AName: string; AProtocol: Integer): Word;
var
  lProtocol: PProtocolEntry;
  lService: PServiceEntry;
begin
  Result := 0;
  lProtocol := getprotobynumber(AProtocol);
  if lProtocol = nil then Exit;
  lService := getservbyname(PAnsiChar(AName), lProtocol^.Name);
  if lService <> nil then Result := ntohs(lService^.Port);
end;

procedure InitResolver;
begin
end;
procedure DoneResolver;
begin
end;

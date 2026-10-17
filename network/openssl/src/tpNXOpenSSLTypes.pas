unit tpNXOpenSSLTypes;
{
    This file is part of the Free Pascal run time library.
    Copyright (c) 1999-2022 by Michael van Canney and other members of the
    Free Pascal development team

    SSL Base unit

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{$mode objfpc}{$H+}
interface
uses SysUtils;
type
  TSSLType = (stAny, stSSLv2, stSSLv3, stTLSv1, stTLSv1_1, stTLSv1_2);
  TCertAndKey = record
    Certificate: TBytes;
    PrivateKey: TBytes;
  end;
implementation
end.

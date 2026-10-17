unit obNXOpenSSLCertificates;
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
uses Classes, SysUtils, tpNXOpenSSLTypes;
type
  { TSSLData }

  TSSLData = Class(TPersistent)
  private
    FFileName: String;
    FValue: TBytes;
  Public
    Function Empty : Boolean;
    Procedure Assign(Source : TPersistent);override;
    Property FileName : String Read FFileName Write FFileName;
    Property Value: TBytes Read FValue Write FValue;
  end;

  { TX509Certificate }

  TX509Certificate = Class (TObject)
  private
    FCommonName: string;
    FCountry: String;
    FHostName: string;
    FKeySize: Integer;
    FOrganization: String;
    FSerial: Integer;
    FValidFrom: TDateTime;
    FValidTo: TDateTime;
    FVersion: Integer;
  protected
    function GetKeySize: Integer;
    function GetValidFrom: TDateTime;
    function GetValidTo: TDateTime;
    function GetVersion: Integer;
    Function GetRealSerial : Integer;
  Public
    Function CreateCertificateAndKey : TCertAndKey; virtual; abstract;
    Procedure CreateCertificateAndKey(Var aCertificate,aKey : TBytes);
    Property Country : String Read FCountry Write FCountry;
    Property HostName : string Read FHostName Write FHostName;
    Property CommonName : string Read FCommonName Write FCommonName;
    Property Organization : String Read FOrganization Write FOrganization;
    Property KeySize : Integer Read GetKeySize Write FKeySize;
    // Valid from. Default today -1;
    Property ValidFrom : TDateTime Read GetValidFrom Write FValidFrom;
    // Valid To. Default today + 31;
    Property ValidTo : TDateTime Read GetValidTo Write FValidTo;
    // Version Default 1.
    Property Version : Integer Read GetVersion Write FVersion;
    // Serial. If zero, then a serial is generated.
    Property Serial : Integer Read FSerial Write FSerial;
  end;

implementation
{ TSSLData }

Function TSSLData.Empty: Boolean;
begin
  Result:=(Length(Value)=0) and (FileName='');
end;

Procedure TSSLData.Assign(Source: TPersistent);

begin
  if Source is TSSLData then
   With TSSLData(Source) do
    begin
    Self.FValue:=FValue;
    Self.FFileName:=FFileName;
    end
  else
    inherited Assign(Source);
end;

function TX509Certificate.GetKeySize: Integer;
begin
  Result:=FKeySize;
  if Result=0 then
    Result:=2048;
end;

function TX509Certificate.GetValidFrom: TDateTime;
begin
  Result:=FValidFrom;
  If Result=0 then
    Result:=Date-1;
end;

function TX509Certificate.GetValidTo: TDateTime;
begin
  Result:=FValidTo;
  If Result=0 then
    Result:=Date+31;
end;


function TX509Certificate.GetVersion: Integer;
begin
  Result:=FVersion;
  if Result=0 then
    Result:=1;
end;

function TX509Certificate.GetRealSerial: Integer;
begin
  Result:=FSerial;
  if Result=0 then
    Result:=10; // MinutesBetween(Now,EncodeDate(2019,1,1));
end;

procedure TX509Certificate.CreateCertificateAndKey(var aCertificate, aKey: TBytes);

Var
  CK : TCertAndKey;

begin
  CK:=CreateCertificateAndKey;
  aCertificate:=CK.Certificate;
  aKey:=CK.PrivateKey;
end;

end.


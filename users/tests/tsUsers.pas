// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit tsUsers;
{$mode objfpc}{$H+}
interface
uses obNXTestRegistry;
procedure RegisterUsersTests(ARegistry: TNXTestRegistry);
implementation
uses Classes, SysUtils, BaseUnix, ctypes, users, pwd, grp, shadow,
  obNXTestContext;
{$link users_abi.o}
{$linklib dl}
function nx_has_setgroupent: cint; cdecl; external;
function nx_passwd_size: size_t; cdecl; external;
function nx_group_size: size_t; cdecl; external;
function nx_shadow_size: size_t; cdecl; external;
function nx_shadow_offset(AIndex: cuint): size_t; cdecl; external;

procedure UserGroupResult(AContext: TNXTestContext);
var lName, lExpected: AnsiString;
begin
  lName := GetUserName(fpGetUID);
  lExpected := GetGroupName(GetUserGid(lName));
  AContext.AssertTrue(lExpected <> '', 'Current account has a named primary group');
  AContext.AssertEquals(lExpected, GetUserGroup(lName), 'GetUserGroup returns the lookup result');
end;

procedure ShadowLayout(AContext: TNXTestContext);
var lEntry: spwd;
begin
  AContext.AssertTrue(SizeOf(lEntry) = nx_shadow_size, 'spwd size agrees with native shadow.h');
  AContext.AssertTrue(PtrUInt(@lEntry.sp_lstchg) - PtrUInt(@lEntry) = nx_shadow_offset(0), 'sp_lstchg offset');
  AContext.AssertTrue(PtrUInt(@lEntry.sp_min) - PtrUInt(@lEntry) = nx_shadow_offset(1), 'sp_min offset');
  AContext.AssertTrue(PtrUInt(@lEntry.sp_max) - PtrUInt(@lEntry) = nx_shadow_offset(2), 'sp_max offset');
  AContext.AssertTrue(PtrUInt(@lEntry.sp_warn) - PtrUInt(@lEntry) = nx_shadow_offset(3), 'sp_warn offset');
  AContext.AssertTrue(PtrUInt(@lEntry.sp_inact) - PtrUInt(@lEntry) = nx_shadow_offset(4), 'sp_inact offset');
  AContext.AssertTrue(PtrUInt(@lEntry.sp_expire) - PtrUInt(@lEntry) = nx_shadow_offset(5), 'sp_expire offset');
  AContext.AssertTrue(PtrUInt(@lEntry.sp_flag) - PtrUInt(@lEntry) = nx_shadow_offset(6), 'sp_flag offset');
end;

procedure ShadowValues(AContext: TNXTestContext);
var lEntry: PPasswordFileEntry;
begin
  lEntry := users.sgetspent('nxtest:x:19001:2:30003:4:5:60006:7');
  AContext.AssertTrue(lEntry <> nil, 'Parse synthetic entry without reading system shadow data');
  AContext.AssertEquals('nxtest', StrPas(lEntry^.sp_namp));
  AContext.AssertTrue(lEntry^.sp_lstchg = 19001, 'Last change');
  AContext.AssertTrue(lEntry^.sp_min = 2, 'Minimum');
  AContext.AssertTrue(lEntry^.sp_max = 30003, 'Maximum');
  AContext.AssertTrue(lEntry^.sp_warn = 4, 'Warning');
  AContext.AssertTrue(lEntry^.sp_inact = 5, 'Inactive');
  AContext.AssertTrue(lEntry^.sp_expire = 60006, 'Expiry');
  AContext.AssertTrue(lEntry^.sp_flag = 7, 'Flags');
end;

type
  TGroupEnumerationProcedure = procedure; cdecl;
  TGroupEnumerationFunction = function: cint; cdecl;
function HasVoidResult(AProc: TGroupEnumerationProcedure): Boolean; overload;
begin Result := True; end;
function HasVoidResult(AProc: TGroupEnumerationFunction): Boolean; overload;
begin Result := False; end;

procedure GroupEnumerationSignature(AContext: TNXTestContext);
begin
  AContext.AssertTrue(HasVoidResult(@grp.fpsetgrent), 'setgrent returns void in the native Linux header');
end;

procedure GroupEntryPointAvailability(AContext: TNXTestContext);
const cDeclared = {$if declared(fpsetgroupent)}True{$else}False{$endif};
begin
  AContext.AssertEquals(nx_has_setgroupent, Ord(cDeclared),
    'BSD setgroupent availability agrees with the native Linux runtime');
end;

procedure CurrentUserAndGroup(AContext: TNXTestContext);
var lUser: TPasswordRecord; lGroup: TGroup; lName: AnsiString;
begin
  AContext.AssertTrue(SizeOf(lUser) = nx_passwd_size, 'passwd ABI size');
  AContext.AssertTrue(SizeOf(lGroup) = nx_group_size, 'group ABI size');
  GetUserData(fpGetUID, lUser);
  lName := StrPas(lUser.pw_name);
  AContext.AssertTrue(lName <> '', 'Current user exists');
  AContext.AssertTrue(GetUserId(lName) = fpGetUID, 'Name to UID roundtrip');
  GetGroupData(GetUserGid(lName), lGroup);
  AContext.AssertTrue(GetGroupId(StrPas(lGroup.gr_name)) = lGroup.gr_gid, 'Group roundtrip');
  AContext.AssertEquals(StrPas(lUser.pw_dir), GetUserDir(lName), 'Home directory');
end;

procedure EnumerateAccounts(AContext: TNXTestContext);
var lList: TStringList; lName: AnsiString;
begin
  lName := GetUserName(fpGetUID);
  lList := TStringList.Create;
  try
    GetUserList(lList);
    AContext.AssertTrue(lList.IndexOf(lName) >= 0, 'User enumeration includes the current account');
    GetGroupList(lList);
    AContext.AssertTrue(lList.IndexOf(GetGroupName(GetUserGid(lName))) >= 0, 'Group enumeration includes the primary group');
    GetUserList(lList, True);
    AContext.AssertTrue(lList.IndexOf(IntToStr(fpGetUID) + '=' + lName) >= 0, 'UID enumeration');
    GetGroupMembers(GetUserGid(lName), lList);
  finally lList.Free; end;
end;

procedure MissingAccount(AContext: TNXTestContext);
var lData: TPasswordRecord; lRaised: Boolean;
begin
  lRaised := False;
  try GetUserData('nxtest-nonexistent-' + IntToStr(GetProcessID), lData);
  except on EUserLookupError do lRaised := True; end;
  AContext.AssertTrue(lRaised, 'Missing account raises the documented lookup exception');
end;

procedure RegisterUsersTests(ARegistry: TNXTestRegistry);
begin
  with ARegistry.AddSuite('Unix.Users') do
  begin
    AddTest('UserGroupResult', @UserGroupResult, 'account-lookup');
    AddTest('ShadowLayout', @ShadowLayout, 'native-abi');
    AddTest('ShadowValues', @ShadowValues, 'native-abi');
    AddTest('GroupEnumerationSignature', @GroupEnumerationSignature, 'native-abi');
    AddTest('GroupEntryPointAvailability', @GroupEntryPointAvailability, 'native-abi');
    AddTest('CurrentUserAndGroup', @CurrentUserAndGroup, 'account-lookup');
    AddTest('EnumerateAccounts', @EnumerateAccounts, 'account-lookup');
    AddTest('MissingAccount', @MissingAccount, 'account-lookup');
  end;
end;
end.

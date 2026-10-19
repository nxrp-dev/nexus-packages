// Copyright (c) 2026 Kevin Collins.
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
unit tsPthreads;
{$mode objfpc}{$H+}
interface
uses obNXTestRegistry;
procedure RegisterPthreadsTests(ARegistry: TNXTestRegistry);
implementation
uses ctypes, UnixType, BaseUnix, pthreads, obNXTestContext;
{$link pthreads_abi.o}
{$linklib dl}
function nx_has_linuxthreads: cint; cdecl; external;
function nx_mutex_fast: cint; cdecl; external;
function nx_rwlock_default: cint; cdecl; external;
function nx_pthread_size(AIndex: cuint): size_t; cdecl; external;

procedure FastMutexConstant(AContext: TNXTestContext);
begin AContext.AssertEquals(nx_mutex_fast, PTHREAD_MUTEX_FAST_NP, 'Native fast mutex kind'); end;
procedure DefaultRwlockConstant(AContext: TNXTestContext);
var lAttr: pthread_rwlockattr_t; lKind: cint;
begin
  AContext.AssertEquals(nx_rwlock_default, PTHREAD_RWLOCK_DEFAULT_NP, 'Native default rwlock kind');
  AContext.AssertEquals(0, pthread_rwlockattr_init(@lAttr));
  try
    AContext.AssertEquals(0, pthread_rwlockattr_getkind_np(@lAttr, @lKind));
    AContext.AssertEquals(lKind, PTHREAD_RWLOCK_DEFAULT_NP, 'Initialized attributes use the declared default');
  finally pthread_rwlockattr_destroy(@lAttr); end;
end;

type
  TSetGuardValue = function(AAttr: Ppthread_attr_t; ASize: size_t): cint; cdecl;
  TSetGuardPointer = function(AAttr: Ppthread_attr_t; ASize: Psize_t): cint; cdecl;
function IsValueParameter(AProc: TSetGuardValue): Boolean; overload;
begin Result := True; end;
function IsValueParameter(AProc: TSetGuardPointer): Boolean; overload;
begin Result := False; end;
function SetGuard(AProc: TSetGuardValue; AAttr: Ppthread_attr_t; ASize: size_t): cint; overload;
begin Result := AProc(AAttr, ASize); end;
function SetGuard(AProc: TSetGuardPointer; AAttr: Ppthread_attr_t; ASize: size_t): cint; overload;
begin Result := AProc(AAttr, @ASize); end;

procedure GuardSizeSignature(AContext: TNXTestContext);
begin
  AContext.AssertTrue(IsValueParameter(@pthread_attr_setguardsize), 'Guard size is a size_t value, not a pointer');
end;

procedure YieldCurrentThread(AContext: TNXTestContext);
begin
  AContext.AssertEquals(0, pthread_yield(), 'The native pthread header redirects yield to sched_yield');
end;

procedure LegacyEntryPointAvailability(AContext: TNXTestContext);
const cDeclared = {$if declared(pthread_kill_other_threads_np) or declared(__pthread_initialize)}True{$else}False{$endif};
begin
  AContext.AssertEquals(nx_has_linuxthreads, Ord(cDeclared),
    'LinuxThreads entry point availability agrees with the native Linux runtime');
end;
procedure GuardSizeRoundTrip(AContext: TNXTestContext);
var lAttr: pthread_attr_t; lSize: size_t;
begin
  AContext.AssertEquals(0, pthread_attr_init(@lAttr));
  try
    AContext.AssertEquals(0, SetGuard(@pthread_attr_setguardsize, @lAttr, 8192));
    AContext.AssertEquals(0, pthread_attr_getguardsize(@lAttr, @lSize));
    AContext.AssertTrue(lSize = 8192, 'Native setter/getter preserves the requested byte count');
  finally pthread_attr_destroy(@lAttr); end;
end;

procedure RecordLayouts(AContext: TNXTestContext);
const cSizes: array[0..13] of SizeUInt = (
  SizeOf(pthread_t), SizeOf(pthread_attr_t), SizeOf(pthread_mutex_t),
  SizeOf(pthread_mutexattr_t), SizeOf(pthread_cond_t), SizeOf(pthread_condattr_t),
  SizeOf(pthread_rwlock_t), SizeOf(pthread_rwlockattr_t), SizeOf(pthread_once_t),
  SizeOf(pthread_key_t), SizeOf(pthread_barrier_t), SizeOf(pthread_barrierattr_t),
  SizeOf(sem_t), SizeOf(__sigset_t));
var lIndex: Integer;
begin
  for lIndex := Low(cSizes) to High(cSizes) do
    AContext.AssertTrue(cSizes[lIndex] = nx_pthread_size(lIndex), 'Native synchronization record size');
end;

procedure Synchronization(AContext: TNXTestContext);
var lMutex: pthread_mutex_t; lCond: pthread_cond_t; lRwlock: pthread_rwlock_t;
  lBarrier: pthread_barrier_t; lSem: sem_t; lCount: cint;
begin
  AContext.AssertEquals(0, pthread_mutex_init(@lMutex, nil));
  try
    AContext.AssertEquals(0, pthread_mutex_lock(@lMutex));
    AContext.AssertEquals(0, pthread_mutex_unlock(@lMutex));
    AContext.AssertEquals(0, pthread_cond_init(@lCond, nil));
    try AContext.AssertEquals(0, pthread_cond_signal(@lCond));
    finally pthread_cond_destroy(@lCond); end;
  finally pthread_mutex_destroy(@lMutex); end;
  AContext.AssertEquals(0, pthread_rwlock_init(@lRwlock, nil));
  try
    AContext.AssertEquals(0, pthread_rwlock_rdlock(@lRwlock));
    AContext.AssertEquals(0, pthread_rwlock_unlock(@lRwlock));
    AContext.AssertEquals(0, pthread_rwlock_wrlock(@lRwlock));
    AContext.AssertEquals(0, pthread_rwlock_unlock(@lRwlock));
  finally pthread_rwlock_destroy(@lRwlock); end;
  AContext.AssertEquals(0, sem_init(@lSem, 0, 1));
  try
    AContext.AssertEquals(0, sem_trywait(@lSem));
    AContext.AssertEquals(0, sem_post(@lSem));
    AContext.AssertEquals(0, sem_getvalue(@lSem, @lCount));
    AContext.AssertEquals(1, lCount);
  finally sem_destroy(@lSem); end;
  AContext.AssertTrue(SizeOf(lBarrier) = nx_pthread_size(10), 'Barrier storage agrees before calling native code');
  AContext.AssertEquals(0, pthread_barrier_init(@lBarrier, nil, 1));
  try AContext.AssertEquals(PTHREAD_BARRIER_SERIAL_THREAD, pthread_barrier_wait(@lBarrier));
  finally pthread_barrier_destroy(@lBarrier); end;
end;

var lOnceCalls: Integer;
procedure InitializeOnce;
begin Inc(lOnceCalls); end;
procedure InitializeOnceCdecl; cdecl;
begin Inc(lOnceCalls); end;
type
  TOnceCdecl = function(AOnce: Ppthread_once_t; AInit: TInitOnceProc): cint; cdecl;
  TOnceRegister = function(AOnce: Ppthread_once_t; AInit: TProcedure): cint; cdecl;
function HasCdeclCallback(AProc: TOnceCdecl): Boolean; overload;
begin Result := True; end;
function HasCdeclCallback(AProc: TOnceRegister): Boolean; overload;
begin Result := False; end;
function CallOnce(AProc: TOnceCdecl; AOnce: Ppthread_once_t): cint; overload;
begin Result := AProc(AOnce, @InitializeOnceCdecl); end;
function CallOnce(AProc: TOnceRegister; AOnce: Ppthread_once_t): cint; overload;
begin Result := AProc(AOnce, @InitializeOnce); end;

procedure OnceCallbackSignature(AContext: TNXTestContext);
begin
  AContext.AssertTrue(HasCdeclCallback(@pthread_once), 'pthread_once accepts a C calling-convention callback');
end;
procedure OnceAndTls(AContext: TNXTestContext);
var lOnce: pthread_once_t; lKey: pthread_key_t; lValue: Integer;
begin
  lOnce := PTHREAD_ONCE_INIT;
  lOnceCalls := 0;
  AContext.AssertEquals(0, CallOnce(@pthread_once, @lOnce));
  AContext.AssertEquals(0, CallOnce(@pthread_once, @lOnce));
  AContext.AssertEquals(1, lOnceCalls);
  AContext.AssertEquals(0, pthread_key_create(@lKey, nil));
  try
    lValue := 42;
    AContext.AssertEquals(0, pthread_setspecific(lKey, @lValue));
    AContext.AssertTrue(pthread_getspecific(lKey) = @lValue, 'Thread-local storage identity');
    AContext.AssertTrue(pthread_equal(pthread_self, pthread_self) <> 0, 'Current thread identity');
  finally pthread_key_delete(lKey); end;
end;

procedure RegisterPthreadsTests(ARegistry: TNXTestRegistry);
begin
  with ARegistry.AddSuite('Unix.Pthreads') do
  begin
    AddTest('FastMutexConstant', @FastMutexConstant, 'native-abi');
    AddTest('DefaultRwlockConstant', @DefaultRwlockConstant, 'native-abi');
    AddTest('GuardSizeSignature', @GuardSizeSignature, 'native-abi');
    AddTest('YieldCurrentThread', @YieldCurrentThread, 'native-abi');
    AddTest('LegacyEntryPointAvailability', @LegacyEntryPointAvailability, 'native-abi');
    AddTest('GuardSizeRoundTrip', @GuardSizeRoundTrip, 'attributes');
    AddTest('RecordLayouts', @RecordLayouts, 'native-abi');
    AddTest('OnceCallbackSignature', @OnceCallbackSignature, 'native-abi');
    AddTest('Synchronization', @Synchronization, 'synchronization');
    AddTest('OnceAndTls', @OnceAndTls, 'synchronization');
  end;
end;
end.

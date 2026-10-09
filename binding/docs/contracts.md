# Nexus binding contracts

`TNXBindingSource` connects current-item values to value endpoints. The source
owns navigation. The coordinator delegates it, checks pending edits, and keeps
bound consumers synchronized. The core has no GUI, dataset, RTTI property,
indexing, sorting, or filtering dependency.

The public declarations are in [tpNXBinding.pas](../src/tpNXBinding.pas).
[obNXBindingSource.pas](../src/obNXBindingSource.pas) implements the coordinator.
`obNXBindingSubscriptions` is owned callback-registration storage used by the
coordinator; it is not a data-access layer.

## Connecting participants

Given source and target objects that implement the contracts:

```pascal
lBindingSource := TNXBindingSource.Create;
try
  lResult := lBindingSource.Attach(lSource);
  if not lResult.Succeeded then
    raise Exception.Create('Source could not be attached.');

  lResult := lBindingSource.Bind('Name', lTarget, bmTwoWay, btExplicit, lHandle);
  // Check lResult; a nonzero handle also exposes an initialization failure.
  // Target changes create pending input. Application code chooses when:
  lResult := lBindingSource.Submit(lHandle);
finally
  lBindingSource.Free;
end;
```

Registration always initializes the target from the source. A conversion or
target-write failure remains inspectable through `GetState`; it does not submit
the target's pre-existing contents to the source. A target lacking required
interfaces is rejected before registration, returning handle zero.

`Attach(nil)` detaches explicitly. Attachment and detachment refuse while edits
remain pending. Attachment preserves the source's current record.

## Interfaces and discovery

All interfaces use `{$interfaces corba}` and string identifiers. They are
non-owning. Attach, Bind, and member resolution exchange borrowed `TObject`
references at connection points so the coordinator can use standard
`Supports(AObject, INX..., AInterface)` checks. Every data operation then goes
through the discovered interface; no concrete model/control class is required.

In FPC 3.2.2, object-to-CORBA is/as, Supports, and GetInterface work, while
CORBA-interface-to-interface is/as and Supports do not. A failed check is a
missing capability, not an invitation to cast an interface pointer into an
object. There are no capability getters or custom query registries. See the FPC
[Supports overloads](https://www.freepascal.org/docs-html/rtl/sysutils/supports.html)
and [CORBA interface rules](https://www.freepascal.org/docs-html/ref/refse50.html).

| Contract | Behavior |
| --- | --- |
| `INXItemSource` | Current, First/Prior/Next/Last, and source notifications. |
| `INXBindingItem` | Resolve a case-sensitive opaque member key to an endpoint object. Keys are not property paths. |
| `INXBindingValue` | Descriptor, read, and notifications. |
| `INXBindingWritableValue` | Optional write capability, including runtime writable state. |
| `INXBindingEditSession` | Optional capability on the source object for BeginEdit/Commit/Cancel and dirty state. |
| `INXBindingConverter` | Pure conversion in either direction. |
| `INXBindingValidator` | Pure validation of a proposed source value and its current-item/member context. |
| `INXBindingObservable` / `INXBindingObserver` | Synchronous subscription and notifications. |
| `INXBindingSource` | Public coordinator operations and observable state. |

A readable source without write capability can initialize a two-way binding's
display. Submission returns `bcReadOnly`. Targets must expose value and write
interfaces; two-way operation requires a readable target. Source edit-session
notifications use the same source subject as normal data/state notifications.

## Values and results

`TNXBindingValue` distinguishes Boolean, Int64, Double, UTF8String, DateTime, and
Currency. Null, unset, and a present value are separate; an empty string is
present. Descriptors specify kind, readability, and null/unset acceptance.
DateTime and Currency have typed fields. There is no implicit numeric conversion,
timezone conversion, formatting, or floating-point Currency intermediate.
Only the payload selected by Kind is meaningful.

Record constructors initialize values. SameValue compares kind, presence, and
the active payload. Converters must produce a value accepted by the destination
descriptor. Without a converter, kinds must match.

Expected failures return `TNXBindingResult`: code, copied diagnostic text, and
the affected handle where applicable. Success and NoMovement satisfy Succeeded.
Failed writes must leave the endpoint unchanged. Successful writes may normalize
a value; the coordinator reads back accepted values.

Unexpected exceptions propagate after guards are released. They are not
validation results and do not imply rollback of a write already performed.
Observer exceptions violate the callback contract. Closing still reaches the
remaining subscribers before the first exception is re-raised.

## Navigation and current values

**Cursor** means the source's navigation state. **Current** is its current item.
**Currency** refers exclusively to the monetary datatype. There is no Count,
Position, numeric lookup, or independent coordinator cursor.

First/Prior/Next/Last check edits and invoke the corresponding source method
once. Empty/boundary behavior belongs to the source; it reports Success,
NoMovement, or a failure that leaves Current unchanged. Current may be nil.
The coordinator processes synchronous CurrentChanged once, without repeating
rebinding when the navigation method returns.

The source may reuse the same current-item facade and endpoints for successive
records. It must report every actual record transition even when object
addresses are unchanged. The coordinator detaches old member subscriptions,
resolves against the new Current, and initializes clean targets. No stable
per-record object or record-identity lookup is required.

Sources establish their new Current before reporting a transition and keep old
endpoints alive through synchronous detachment. Missing members or unreadable
sources produce unavailable bindings. Displayed values are not replaced by
invented defaults. Source data-change or Refresh retries unavailable resolution.

The DataSet design check uses ordinary current-record navigation, field access,
Edit/Post/Cancel, and notifications. An eventual adapter translates these
behaviors, including case-sensitive member keys and event/lifetime rules; it
need not fabricate indexed records. This is an API compatibility check, not
a claim that a production DataSet adapter was tested. The
[FPC DataSet API](https://www.freepascal.org/docs-html/fcl/db/tdataset.html)
is the reference. Tests exercise a reusable-record facade and object-list source.

## Edits and caller decisions

`bmOneWay` never submits target changes. `bmTwoWay` captures them; `btOnChange`
attempts submission immediately, while `btExplicit` waits for Submit. A future
focus-loss adapter calls Submit. There is no core focus event or policy callback.

GetState exposes source availability/value, pending input, orphaned state,
source-baseline changes, and the last result. GetDirty combines local pending
input with the optional source session's dirty state. Returning a target to its
accepted representation clears a local edit when its source baseline has not
changed; otherwise the caller resolves the baseline explicitly.

Submission converts, validates, begins the optional edit session, writes, then
reads back and refreshes clean bindings. Rejection, incomplete input such as
`"-"`, and validation failure preserve the proposal. Successful source writes
are distinct from committing the source edit session.

| Operation | Effect |
| --- | --- |
| `Submit(handle)` | Submit that pending proposal; no pending proposal is a no-op. |
| `SubmitAll` | Submit pending bindings in registration order. |
| `CancelPending(handle)` | Discard local input and refresh; does not undo an accepted source write. |
| `CommitEdit` | Submit pending input, then commit the source session. Unsupported without that capability. |
| `CancelEdit` | Cancel the source session, discard current-item proposals, and refresh. Unsupported without that capability. |
| `Rebase(handle)` | Acknowledge the latest source baseline while retaining input. Does not write or bypass validation. |
| `Refresh` | Refresh clean targets. Does not discard pending input or acknowledge changed baselines. |

Navigation with pending input or a dirty session returns `bcPendingEdits`
before calling the source, even if movement might be a no-op. The caller
submits/commits or cancels explicitly and retries navigation.

When source values change under pending input, input is preserved and ordinary
Submit returns `bcSourceChanged`. The caller chooses CancelPending or Rebase
followed by Submit. Another source change requires another acknowledgement.

When the current record changes externally, including removal, pending input
becomes orphaned. It remains inspectable but cannot be submitted or rebased.
CancelPending discards it and displays the new Current.

SubmitAll is not atomic. Later failure leaves earlier writes accepted (or in
the source session), with later proposals untouched. Multiple proposals to one
member have all involved conversions/validators checked before any write:
conflicting source values return `bcAmbiguousProposal`. Equivalent validated
proposals are written once and refreshed together. Submitting one binding
individually does not silently accept a pending sibling.

Source BeginEdit is idempotent for the active session. Failed Commit keeps the
session; failed Cancel leaves it unchanged. Successful Cancel restores its
baseline. The coordinator provides no cross-item transaction.

## Notifications, reentrancy, and lifetime

Subscribe returns a subject-local token; zero means refused. Delivery follows
registration order. Unsubscribe is idempotent and removes a callback immediately,
including a later callback in the current dispatch. New subscribers start with
the next dispatch. Subscription storage never owns observers.

Notifications carry the borrowed subject object as identity and a typed event.
This avoids treating distinct interface references on one object as different
subjects. Value access still uses interfaces, not the object's concrete class.

Getters, resolution, conversion, and validation must not cause independent data
mutations or navigation. Coordinator mutations during active operations or
notifications return `bcBusy`. Remove and Unsubscribe remain safe; internal
binding reclamation waits until calls unwind. Coordinator-generated target
writes use local echo guards, including nested target normalization.

CurrentChanged is published after rebinding, followed by affected BindingChanged
events and DataChanged. Source and binding state is coherent at these callbacks.
Targets can observe individual writes before the final coordinator event;
there is no promise of atomic visual updates across targets.

Application owners explicitly own and free all participants. The coordinator
owns bindings and subscriptions. Converters/validators outlive their bindings
or are detached by Remove. Source edit capabilities share the source lifetime.

Before destruction, source/target owners issue Closing while their contracts
are alive. Closing clears borrowed references and tokens; recipients never call
that subject again. Observer owners unsubscribe before destroying themselves.
Destroying a currently executing participant or the coordinator inside its own
callback is prohibited: disconnect/remove there, free after it returns. The
core uses no reference counting, worker thread, or event-loop queue.

## Verification

From repository root:

```powershell
lazbuild packages\nexus-packages\binding\tests\NexusBindingTests.lpi
& .\output\NexusBindingTests\x86_64-win64\NexusBindingTests.exe
```

The console project executes NexusTest cases directly, with range, overflow,
assertion, debug-line, and heap checking enabled. Tests cover capability discovery,
six scalar kinds/presence states, propagation and edit failures, source-owned
navigation, facade reuse, partial submissions, teardown, callback removal,
reentrancy, and exception recovery. CheckEndpoint is reusable for adapter fixtures.

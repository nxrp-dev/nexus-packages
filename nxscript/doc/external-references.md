# External references and desired values

Implemented October 19, 2026. `$` is the external-reference prefix. `@` remains
an internal document reference. The attached exploratory design's `!` spelling
was superseded by the owner's decision.

```text
Project Example {
    OutputRoot: "/output/" + $TargetOS + "/" + $TargetCPU;
    FPCBin: "/nexus/bin";
    $Path: $Path + ":" + @FPCBin;
}
```

External identities are case-sensitive, qualified paths. `$Server.Options.Name`
has one identity shared by every use, with `Server` and `Options` as namespace
parents. Internal `Path` and external `$Path` are independent identities.
Quoted text such as `"$Path"` is literal; there is no string interpolation.
External assignments use the ordinary property location inside a definition
and the existing colon/semicolon syntax. Values are text, including text
composition and references to internal scalar values. Arrays may contain
external-reference expressions.

## Binding and evaluation

Compilation retains external-reference expressions and binds their internal
references. `RequiresContext` marks bound text that has no `EffectiveText` yet.
It does not read the environment, invoke processor events, or calculate desired
external state. Ordinary source-defined text keeps its existing evaluation
behavior. Target filtering and definition composition still happen during
compilation.

A Live document owns its graph after the compiler/session is released. Calling
`Value.AsText` evaluates external expressions at that access. Repeated accesses
observe the current event-supplied value; external text is not cached or frozen
into compilation output. Internal aliases, text composition, named array
entries and imported private dependencies preserve these expressions and their
source ranges. Reentrant value evaluation reports a dependency cycle.

Every name supplied through `TNexusScriptTargetSelection` is available without
an event handler. This uses the same copied selection that filtered the document,
including custom Target names. Target names and values retain their existing
case-sensitive selection semantics. The Live selection does not change if the
caller's original selection is later modified or freed.

Selected Target values take precedence over extension events and are read-only.
An assignment to one is rejected. A name with no selected value goes to the
extension event; the core does not assume it is an environment variable.

## Processor events and ownership

```pascal
procedure TProcessor.ReadExternal(const APath: string;
  out AValue: string; out AHandled: Boolean);
begin
  AHandled := APath = 'Path';
  if AHandled then
    AValue := ReadTargetPath
  else
    AValue := '';
end;

procedure TProcessor.ReceiveExternalResult(const APath, AValue: string;
  out AHandled: Boolean);
begin
  AHandled := APath = 'Path';
  if AHandled then
    RecordDesiredPath(AValue);
end;

lLive.OnReadExternal := ReadExternal;
lLive.OnExternalResult := ReceiveExternalResult;
```

The event receiver must outlive its attachment to the document. A successful
empty string is represented by `AHandled = True` and `AValue = ''`. An absent
handler or `AHandled = False` raises an unresolved-reference error with the
reference's file, line and column. The core supplies no automatic environment
variable read/write behavior.

`ExternalRoot`, `FindExternal`, `Parent` and `Children` expose the namespace.
`Value.Reference.Kind = nslrExternal` distinguishes external edges, and
`Reference.Target` is the shared external identity. `ReferenceRanges` belongs to
the individual use, not just the shared identity. Selected identities expose
`IsSelectedTarget`.

The document owns all graph nodes. Navigation links are borrowed. Definition
`Properties` contains ordinary properties; `ExternalAssignments` contains its
external declarations. `FindExternalAssignment` uses the exact external path.
Document `ExternalAssignments` contains effective public contributions. Private
module dependencies remain private, including their desired-state declarations.

## Receiving desired state

`$Path: $Path + ":" + @FPCBin;` reads the processor's current Path on the right
and describes desired Path on the left. Reading the desired expression does not
call the result event and does not feed the desired value back into `$Path`.

`EvaluateExternalAssignments` returns a caller-owned result list. Each result
owns its path, calculated text and source range, so the list can outlive the
Live document. Free it when finished. This is suitable for inspecting or
building a product-specific plan without applying it.

`PublishExternalAssignments` explicitly evaluates the full result batch, then
delivers each result through `OnExternalResult`. No result is delivered if value
evaluation fails. A missing result handler or an unhandled result raises an
error. The processor owns physical application, persistence and any transaction
or rollback policy; publication itself offers no transaction across callbacks.

Duplicate declarations within a definition fail compilation. Normal definition
composition can reduce inherited/local assignments to one effective declaration;
local scalar winner rules and contributor ranges are preserved. Live construction
rejects multiple surviving public assignments to the same external identity,
identifying both declaration locations. Differently cased paths remain distinct.

## Dialect validation and artifacts

`ExternalReference` is a distinct dialect source form. Internal-reference rules
cannot be satisfied by external identities. Structural constraints are checked
during normal validation. Integer, Boolean and allowed-value checks that require
external text are retained and enforced on Live access, using the existing
`NSV2304`, `NSV2305`, `NSV2306` and `NSV2409` diagnostic codes. These checks survive
compiler, validator and imported-module lifetimes. Revalidation replaces checks
from that subject while retaining independently validated imported constraints.

Generic JSON and SQLite emitters accept materialized compiled values. They reject
unevaluated external expressions and external assignments explicitly, before
producing an incomplete artifact. They neither emit assignments as ordinary
properties nor silently discard external semantics. A processor that needs to
persist these expressions must lower them into its own artifact representation.
This change does not add a serialized Live format.

nxbuild already consumes Live values. Its publication paths can therefore use
`$TargetOS`, `$TargetCPU` and any other selection the caller supplies. This
mechanism does not introduce new product command-line flags or register product
read/write handlers.

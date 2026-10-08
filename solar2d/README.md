# Solar2D Pascal RTTI Bridge v2

This implementation is split across two packages:

- `packages/nexus-packages/lua` provides the generic Lua 5.1 ABI and RTTI bridge.
- `packages/nexus-packages/solar2d` provides the Solar2D integration and depends on
  the Lua package.

The bridge separates generic Lua integration from Solar2D-specific integration:

```text
TLuaPlugin
    |
TSolarPlugin
    |
TUserPlugin
```

A user plugin can remain ordinary Pascal:

```pascal
type
  TAddLink = function(A, B: Integer): Integer of object;

  TSamplePlugin = class(TSolarPlugin)
  private
    FAdd: TAddLink;
    FName: string;
    function LinkAdd(A, B: Integer): Integer;
  published
    property Add: TAddLink read FAdd;
    property Name: string read FName write FName;
  end;
```

Read-only published method-pointer properties are Lua links. Writable published
method-pointer properties remain ordinary Pascal events and are not exposed by
the Lua bridge. Direct published methods are not part of the bridge contract.

Lua sees an object-like surface:

```lua
local sample = require("plugin.sample")
local obj = sample.new()

obj.Name = "Nexus"
print(obj:Add(20, 22))
```

## Event surface

The Solar2D layer adds familiar local event methods:

```lua
obj:addEventListener("pulse", onPulse)
obj:removeEventListener("pulse", onPulse)
obj:dispatchEvent({ name = "setVolume", value = 0.25 })
```

Pascal descendants can receive Lua events by overriding `HandleEvent()` and can send local or global events with `DispatchEvent()` and `DispatchRuntimeEvent()`.

See `sample/Sample.Plugin.pas` and `sample/main.lua` for the complete small example. See `STATUS.txt` for the validation state recorded when this archive was assembled.

## Review findings / production readiness

The overall architecture is worth keeping. In particular, the separation between the generic `TLuaPlugin` RTTI bridge and the Solar2D-specific `TSolarPlugin` layer is clean, the Pascal-facing plugin API is intentionally small, and detached link closures retain their userdata correctly.

The bridge is not yet considered production-ready, however. The following issues should be resolved or consciously accepted before expanding the supported surface.

### 1. Runtime event dispatch ABI documentation should be clarified

The installed Corona SDK header in this workspace confirms the active export and the deprecated compatibility helper side by side:

```c
CORONA_API void CoronaLuaDispatchRuntimeEvent(lua_State *L, int nresults);
CORONA_API void CoronaLuaRuntimeDispatchEvent(lua_State *L, int index);
```

The header comment marks the older `CoronaLuaRuntimeDispatchEvent()` helper as deprecated because it leaves the Lua stack in an inconsistent state, and directs callers to prefer `CoronaLuaDispatchRuntimeEvent()` instead.

That means the repository source in `src/Solar2D.Corona.pas` and the dispatch site in `src/Solar2D.Plugin.pas` are aligned with the installed Corona header's current public contract, while the explanatory review note should be corrected to describe the active API accurately and to mark `CoronaLuaRuntimeDispatchEvent()` as the deprecated helper rather than the current ABI.

The bridge can still be made more explicit about stack ownership by documenting that `CoronaLuaDispatchRuntimeEvent()` consumes the event table placed on the top of the stack, as the header comments indicate, and by consulting the current CoronaLua.h file when a fresh audit is needed.

### 2. Lua errors use a boundary-thin callback

Bridge validation and conversion failures are ordinary Pascal exceptions. The
callback boundary catches them, copies the message to the Lua stack, and returns
from the Pascal-managed frame. Only then does the minimal outer callback call
`lua_error()`. This prevents an intentional Lua long jump from bypassing Pascal
exception cleanup and managed-value finalization.

### 3. Local listener ownership can form an uncollectable cross-runtime cycle

The current local event implementation stores listeners through `CoronaLuaRef`, producing a possible ownership chain such as:

```text
Lua userdata
    -> Pascal plugin object
    -> CoronaLuaRef listener
    -> Lua closure/table
    -> Lua userdata
```

If the listener itself captures the plugin userdata, neither Lua's collector nor Pascal ownership alone can see and collect the complete cycle. Explicit listener removal breaks it, but relying on callers to do so makes a common Lua coding pattern a lifetime hazard.

Solar2D provides `system.newEventDispatcher()` specifically for plugin-style event dispatch. A strong alternative is to keep the private dispatcher and its listeners entirely inside Lua's traced object graph and let the Pascal userdata retain that dispatcher through its Lua environment or equivalent Lua-owned storage.

That approach may eliminate most of the custom `TSolarEventListener` bookkeeping, dispatch-depth cleanup logic, and the cross-runtime listener cycle at the same time. It should be evaluated before treating the current local event implementation as final.

### 4. A shared metatable name is unsafe across independently built plugin binaries

The generic bridge currently uses a fixed metatable name:

```text
Nexus.Lua.Plugin.Object
```

That is safe only if one compiled copy of the bridge owns that metatable for the lifetime of the Lua state.

If several separately built Pascal Solar2D plugins each embed `Lua.Plugin.pas`, the first one to create the registry metatable installs callback addresses from its own binary. Later plugins can then reuse the same metatable while pointing at callbacks owned by another DLL/shared object.

The metatable identity should therefore be unique enough to prevent collisions between independently built native plugins. Plugin-specific or concrete-class-specific metatable identities are both preferable to one process-global fixed string.

This should be resolved before using the bridge as a foundation for multiple independently distributed native plugins.

### 5. Integer support is narrower than the declared Pascal types imply

The current conversion layer advertises types including `Int64` and `QWord`, but Lua 5.1 uses `lua_Number` as a `Double` in this bridge and `lua_Integer` is declared as `PtrInt`.

Consequences include:

- integer values outside the exact IEEE-754 double integer range can lose precision when emitted through `lua_pushnumber()`;
- a 32-bit target further constrains values passing through `lua_Integer` / `PtrInt`;
- the current input path uses a signed `Int64` intermediate, so the full upper half of the `QWord` domain cannot be represented;
- narrower Pascal ordinals need explicit range checking before constructing the target `TValue`;
- numeric enum input should be checked against the valid ordinal range rather than merely accepted as an integer.

Until this is tightened, the documented contract should be understood as supporting Lua-representable ordinal values mapped to Pascal types, not the complete mathematical domain of every published Pascal integer type.

### 6. Failure during `LuaObjectPushed()` can leave userdata pointing at a freed object

`PushLuaObject()` stores `Self` into the userdata before calling the overridable `LuaObjectPushed()` hook.

If that hook raises a normal Pascal exception, the caller can free the Pascal object while the already-created Lua userdata still contains the old instance pointer. A later userdata finalizer can then observe a dangling pointer and potentially free or access the object again.

Before propagating an initialization failure, the userdata instance slot should be cleared or the construction sequence should otherwise guarantee that a failed push cannot leave a live Lua object referencing a destroyed Pascal instance.

### 7. Event field getters perform repeated Lua lookups

`TSolarEvent` accessors currently perform separate operations to test presence, validate type, and retrieve a field. A normal `lua_getfield()` lookup can invoke Lua metatable behavior, so repeated access is not necessarily a passive table read.

A cleaner implementation would fetch once, inspect once, convert once, and restore the stack in one operation. Raw table access is also worth considering if event fields are intended to be plain data rather than dynamically resolved properties.

This is not a blocker, but it reduces surprising behavior and unnecessary Lua calls.

### 8. Lua/Solar2D thread affinity needs an explicit contract

`TSolarPlugin` retains access to a Lua state and exposes Pascal-side event dispatch methods. Native plugins may eventually add worker threads for networking, SDK callbacks, file I/O, or other asynchronous work.

The bridge should explicitly state that Lua/Solar2D API calls must occur on the appropriate Solar2D/Lua thread unless a documented Solar2D mechanism marshals work back to it. Merely retaining a `lua_State` pointer does not make that state safe to call from an arbitrary Pascal thread.

This is primarily a documentation/API-contract issue now, but it becomes a runtime issue as soon as asynchronous plugins are built on top of the bridge.

### 9. RTTI metadata caching is currently per instance

Each plugin object currently builds its own link/property lookup structures even though those descriptors are primarily class metadata.

For plugins that create many instances, a per-class immutable descriptor cache would avoid repeated RTTI scans and repeated string-list construction. This is an optimization and cleanup item rather than a production blocker, and should come after the runtime-boundary issues above.

## Recommended stabilization order

Before adding more bridged types or convenience features, the recommended order is:

1. Correct `CoronaLuaRuntimeDispatchEvent()` and audit every imported Solar2D/Lua C signature against the actual headers used for the target build.
2. Retain the boundary-thin Pascal-exception/Lua-error handling while extending the bridge.
3. Decide whether local event handling should delegate to a Lua/Solar2D-owned `system.newEventDispatcher()` rather than maintaining listener references in Pascal.
4. Make userdata metatable identity safe across multiple independently built plugin binaries.
5. Tighten integer/ordinal range and precision handling and document the exact numeric contract.
6. Make object construction failure-safe around `LuaObjectPushed()`.
7. Establish thread-affinity rules and then address lower-priority event lookup and RTTI-cache cleanup.
8. Compile and run `tests/TestPublishedRTTI.pas`, then build and exercise the native sample on every supported target CPU/ABI.

The core RTTI bridge concept does not need to be replaced to address these findings. Most of the risk is concentrated at the Lua/Pascal/Solar2D runtime boundary, while the public Pascal plugin model can remain essentially as designed.

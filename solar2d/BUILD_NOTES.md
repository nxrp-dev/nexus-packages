# Build notes

This archive contains source for the bridge and sample; it does not contain a prebuilt Solar2D plugin.

## Units

- `../lua/src/bindings/Lua51.pas` — minimal Lua 5.1 C ABI declarations used by the bridge.
- `../lua/src/Lua.Plugin.pas` — generic RTTI-backed `TLuaPlugin` object bridge.
- `src/Solar2D.Corona.pas` — Solar2D `CoronaLibrary` / `CoronaLua` C API declarations used by the Solar2D layer.
- `src/Solar2D.Plugin.pas` — `TSolarPlugin`, Solar2D library creation, and event integration.

The final link must resolve both the Lua 5.1 symbols used by `Lua51.pas` and the Solar2D Native symbols used by `Solar2D.Corona.pas`. On targets other than x86-64 Windows, it must also resolve native libffi for RTTI invocation of published links. The separate `Lua55.pas` binding does not change the Lua 5.1 ABI required by Solar2D.

Solar2D's current native headers define `CoronaLibraryNew()` in `CoronaLibrary.h` and the event/ref helpers in `CoronaLua.h`. The engine repository currently carries the Lua 5.1 ABI.

For Windows, the FPC link needs the Solar2D Native import library or equivalent imports. For ELF/Mach-O/static targets, use the target's normal Solar2D Native link inputs.

## Quick validation order

1. Run the NexusFPC libffi ABI probe against the headers matching the native libffi library selected for this target.
2. Compile and run `../lua/test/TestPublishedRTTI.pas`. It has no Lua/Solar2D link dependency and proves the required published RTTI/`Invoke()` behavior for the chosen FPC target. On Win64, define `NX_TEST_FFI_MANAGER` to test the libffi manager separately from native invocation.
3. Build `sample/plugin_sample.lpr` with `../lua/src`, `src`, and `sample` on the unit path and the target Solar2D/Lua/libffi link inputs available.
4. Export `luaopen_plugin_sample` exactly as shown in the sample library project.
5. Load `sample/main.lua` under Solar2D and verify the link/property and event output.
6. Repeat the ABI and RTTI invoke checks for every supported CPU/ABI.

## Verification status

The bridge and sample compile on the local FPC 3.2.2 Win64 toolchain with linking disabled. The published-link RTTI test compiles and passes. A native Solar2D runtime test still requires the matching target compiler and link inputs.

# Lua Package

This package contains the generic Lua integration shared by Nexus packages.

## Source

- `src/bindings/Lua51.pas` provides the public Lua 5.1 core, auxiliary,
  debug, and standard-library C APIs, including Pascal equivalents of the
  header macros. Solar2D uses this binding.
- `src/bindings/Lua55.pas` provides Lua 5.5.1 C API declarations and macro equivalents.
- `src/Lua.Plugin.pas` provides the RTTI-backed `TLuaPlugin` bridge for the Lua 5.1 host ABI.

Published method-property links use RTTI `Invoke`. On targets other than
x86-64 Windows, `Lua.Plugin` imports NexusFPC's `ffi.manager`; the final plugin
must link a native libffi library built for that target. The matching libffi
headers and Pascal binding must pass the ABI probe in NexusFPC's
`packages/libffi/tests`. Ordinary Lua C callbacks do not use libffi.

`Lua55` mirrors the default Lua 5.5.1 ABI (64-bit `lua_Integer`, double
`lua_Number`, pointer-sized `lua_KContext`). It declares imports by C symbol
name; consumers must link against a matching Lua 5.5 library. This package does
not bundle a Lua runtime. Upstream 5.5.1 headers are retained under `reference/`.

`Lua51` follows the default Lua 5.1 number and integer configuration. Its
`luaL_Buffer` layout uses the target C runtime's default `BUFSIZ`; a Lua build
with a customized `luaconf.h` must use matching Pascal declarations. Because
Pascal identifiers are case-insensitive, the C status constant `LUA_YIELD` is
exposed as `LUA_STATUS_YIELD` alongside the `lua_yield` function.

Solar2D-specific integration lives in the dependent
`packages/nexus-packages/solar2d` package.

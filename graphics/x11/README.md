# Nexus X11 bindings

`NXRP.Graphics.X11` owns the former NexusFPC X11 bindings: Xlib and keyboard,
input, rendering, font and extension interfaces. fpGUI's Linux backend consumes
this package. Compiler bootstrap is unchanged and does not depend on X11.

Original notices, namespace wrappers/maps and license texts remain beside the
source. Authors, upstream revision and import evidence are recorded in
[Nexus ATTRIBUTIONS.md](../../../../ATTRIBUTIONS.md#x11).

From the Nexus root, build the complete 45-unit source package and its direct
nxtest suites:

```sh
output/nxbuild-next/x86_64-linux/nxbuild /action=build /project=packages/nexus-packages/graphics/x11/X11.nxproject
output/nxbuild-next/x86_64-linux/nxbuild /action=build /project=packages/nexus-packages/graphics/x11/tests/X11Tests.nxproject
output/x11-tests/x86_64-linux/X11CoreTests
output/x11-tests/x86_64-linux/X11BindingTests
```

Recipes use the shared native NexusFPC installation settings. The unit build
uses FPC mode for the inherited C header translations; individual units retain
their own explicit language directives. This is a unit/source-package build,
not a claim of compiled runtime-package publication.

On Linux, the bindings name supported runtime ABIs explicitly in
`src/tpX11Libraries.pas`: X11 `.so.6`, Xext `.so.6`, Xft `.so.2`, Xrender `.so.1`,
Xi `.so.6`, Xrandr `.so.2`, Xfixes `.so.3`, Xinerama `.so.1`, Xv `.so.1`,
Xxf86vm `.so.1`, Xxf86dga `.so.1` and fontconfig `.so.1`. Only libraries required
by the selected units/calls enter a consumer's link. No development `.so`
symlinks or fabricated aliases are required for these imports.

The 17 core tests exercise XKB helpers and XI masks without an X display. The
25 binding tests include 227 symbol checks converted from the old link-only
programs. Four behavioral cases need an accessible X display and report skips
when none is available. Use an existing display or a private Xvfb instance to
exercise Render, shared-memory queries, input presence and keyboard mapping.
The tests do not change the keyboard configuration or map a visible window.

`tests/X11ABI.c` is an optional independent layout reference compiled with native
X11 and Fontconfig development headers. Those headers and a C compiler are not
needed by the normal Pascal package/tests. The relocation verification used
extracted native distribution headers without installing them system-wide.

The keyboard-map demonstration is centralized in Nexus Lab:
`examples/gui/x11/KeyboardMap.pas`, built by `X11Examples.nxproject`. Old link
programs are replaced by the nxtest symbol checks; their original source remains
in the baseline Git tree and hash inventory. No FPCUnit bridge is used.

Native Linux x86-64 is the verified target. Other platform branches and dotted
unit wrappers are preserved; their complete SDK/build matrices were not run.

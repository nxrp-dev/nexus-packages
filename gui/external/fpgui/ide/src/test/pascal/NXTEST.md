# Native fpGUIIDETests

From the Nexus root, build this suite with Nexus nxbuild and NexusFPC:

```sh
nxbuild /action=build /project=packages/nexus-packages/gui/external/fpgui/ide/src/test/pascal/fpGUIIDETests.nxproject
```

Configure the matching compiler and RTL in Nexus
`projects/nxbuild/nxbuild.environment.nxscript`.

Run on a local GUI display. Copy `ide/src/main/resources/editor-themes`
from this fpGUI checkout into the executable working directory as
`editor-themes` before running. The six optional debugger adapter cases remain
excluded because their PDR source dependencies are absent.

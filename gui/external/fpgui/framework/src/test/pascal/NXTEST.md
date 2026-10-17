# Native fpGUIFrameworkTests

From the Nexus root, build this suite with Nexus nxbuild and NexusFPC:

```sh
nxbuild /action=build /project=packages/nexus-packages/gui/external/fpgui/framework/src/test/pascal/fpGUIFrameworkTests.nxproject
```

Configure the matching compiler and RTL in Nexus
`projects/nxbuild/nxbuild.environment.nxscript`.

Run on a local GUI display. Normal fpGUI X11/font libraries must be
installed. The external Haiku HVIF fixture is explicitly skipped when absent.

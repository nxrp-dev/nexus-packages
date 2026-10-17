
## Native behavior suite

From the Nexus root, build this suite with Nexus nxbuild and NexusFPC:

```sh
nxbuild /action=build /project=packages/nexus-packages/fcl-process/tests/FCLProcessBehaviorTests.nxproject
```

Configure the matching compiler and RTL in Nexus
`projects/nxbuild/nxbuild.environment.nxscript`.

Run `FCLProcessBehaviorTests` from its output directory. The process suite
recipe also builds its five subprocess fixtures beside the runner.

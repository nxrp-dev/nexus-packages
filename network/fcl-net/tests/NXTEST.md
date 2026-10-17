# Native FCL Net tests

From the Nexus root, build with Nexus nxbuild and the installed NexusFPC:

```sh
output/nxbuild-next/x86_64-linux/nxbuild /action=build /project=packages/nexus-packages/network/fcl-net/tests/FCLNetTests.nxproject
output/fcl-net-tests/x86_64-linux/FCLNetTests
```

The Linux runner registers 110 retained DNS/parser tests and 17 direct nxtest
regressions (127 cases total). The UDP/TCP regressions use ephemeral loopback
ports; no external service is needed. Each new regression runs its fixture in a bounded child process,
so a crash or hang in original source becomes an ordinary failed nxtest case.
The three original standalone socket test programs are preserved unchanged.
No FPCUnit bridge or external test discovery is used.

The preserved standalone `tfpsock1`, `tfpsock2` and `tfpsock3` programs contain
4 address, 10 UDP and 12 TCP cases respectively. All 26 passed during relocation.
The live suites use local IPv4/IPv6 sockets on port 1337 and must run serially.

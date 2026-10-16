# FCL DB verification

`FCLDBTests.lpr` registers 16 nxtest cases. Each case runs a bounded subprocess
fixture so recursion, buffer corruption and cleanup failures cannot silently
pass or take down the whole runner. Fixtures use HeapTrc guards and leak checks;
the nxbuild project also enables range checks and local-variable instrumentation.
Case 03 is a passing Int64-export control: the initial suspicion was disproved.

From the Nexus root:

```sh
nxbuild /project=packages/nexus-packages/db/fcl-db/tests/FCLDBTests.nxproject /action=build
output/fcl-db-tests/x86_64-linux/FCLDBTests
nxbuild /project=packages/nexus-packages/db/fcl-db/tests/FCLDBRetained.nxproject /action=build
output/fcl-db-tests/x86_64-linux/retained/FCLDBRetained
```

`FCLDBRetained.lpr` runs the unchanged scanner, parser, SQL generator, SQL script
and dictionary-diff suites: 943 tests. Historical runners and standalone test
programs remain available; the console wrapper needs no Lazarus or GUI resource.

## Compare with the untouched source

On x86_64 Linux, the Python helper verifies/extracts the saved baseline archive,
compiles the same fixture/test sources against either original or maintained
runtime code, and runs the cases:

```sh
python3 packages/nexus-packages/db/fcl-db/tests/VerifyReview.py baseline
python3 packages/nexus-packages/db/fcl-db/tests/VerifyReview.py fixed
python3 packages/nexus-packages/db/fcl-db/tests/VerifyReview.py plain
```

The baseline command is expected to return failure: **1 passed, 15 failed**.
Fixed and plain modes each pass all 16. `baseline-plain` is also available.
Plain modes omit range/local instrumentation while retaining heap guards.
Optional arguments after the mode override the SDK root and NexusFPC source
root. Defaults are the sibling NexusFPC tree and
`../../toolchain/nexus-fpc/x86_64-linux/current` relative to Nexus.

The helper refuses to overwrite a differing baseline file. Its outputs are
under `output/fcl-db-tests/<mode>`. Tracked comparison outputs and summaries
are in [review/evidence](../review/evidence); the full conclusions and limits
are in [CODE_REVIEW.md](../CODE_REVIEW.md).

Probe 112 separately isolates the buffered blob implementation. After building
the fixtures, supply an existing empty directory and an absolute result path:

```sh
output/fcl-db-tests/baseline/FCLDBFixture --probe 112 /tmp/fcldb-before/result.txt /tmp/fcldb-before
output/fcl-db-tests/fixed/FCLDBFixture --probe 112 /tmp/fcldb-after/result.txt /tmp/fcldb-after
```

Create those two directories first. Original source exits 204 on heap corruption;
fixed source exits zero and writes `passed`. This supplements case 12, whose
first original failure is the memory dataset's incorrect overwrite size.

No database server is required by these suites. The separate SQLite consumer
check uses the Nexus SQLite wrapper and a native SQLite library; its 28 passing
results are saved in the review evidence.

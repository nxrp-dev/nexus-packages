# NexusScript fixture boundary

Fixtures under `fixtures/` remain test inputs. They do not define the generic JSON
contract and do not require a Schema-specific producer.

The maintained inForce/Storm models and templates moved to
`projects/schema/examples/`. Their synthetic data is demonstration input,
not historical production-data parity. The old NexusSchema executable is retired.
Generic source/manifest regressions remain in the NexusScript suite. New CSV jobs
can invoke nxcsv through an ordinary Forge CSV operation.

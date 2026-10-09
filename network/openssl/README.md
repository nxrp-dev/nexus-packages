# Nexus OpenSSL package

This package owns the OpenSSL Pascal binding (`src/openssl.pas`), object wrapper
(`src/fpopenssl.pp`), and FCL socket adapter (`src/opensslsockets.pp`). It was moved
from NexusFPC commit af042760 without changing those source units.

Add this package's `src` directory to the compiler unit search path. The object
and socket wrappers require matching NexusFPC `fcl-net` units. Native OpenSSL
libraries are loaded dynamically and are not bundled here.

Existing Nexus Synapse transports continue to use their own bindings; this move
does not select a different provider for them.

The inherited `fpmake.pp` and namespace map describe the package. `Makefile`
builds the library-load example with the compiler selected through `FPC`.
Preserve the original license notices in all inherited sources.

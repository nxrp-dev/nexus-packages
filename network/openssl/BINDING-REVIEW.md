# OpenSSL binding review

Reviewed the three implementations that mattered to the active consumers:
the Nexus OpenSSL package, Synapse's OpenSSL 3 binding/adapter, and XMPP's
cryptography-only binding. The shared package now supplies all three use cases.
This review covers the migrated API paths, not every inherited declaration.

| Implementation | Completeness | Verified defects and disposition |
| --- | --- | --- |
| [Nexus OpenSSL](src/openssl.pas) and [wrappers](src/fpopenssl.pp) | Broadest API: TLS, X.509/certificates, keys/signatures, ciphers, BIO, random generation and crypto primitives. Includes ALPN and SNI routing. It is not a complete binding of every OpenSSL 3 API. | Retained and repaired. Fourteen Win64 regression tests pass. The shared loader validates required exports and version before success, releases incomplete loads, and permits retries. |
| [Synapse OpenSSL 3 binding](../external/synapse/ssl_openssl3_lib.pas) and [adapter](../external/synapse/ssl_openssl3.pas) | Smaller, primarily the Synapse TLS contract; less general crypto/certificate coverage. | Known defects include RSA-only generic-key loading, macro names treated as exports, wrong-library lookup for X509_STORE_add_cert, PFX intermediates added to the trust store instead of the transmitted chain, missing native stack cleanup, unchecked identity configuration, and unbounded/busy TLS retries. Active consumers now use [our adapter](synapse/obNXSynapseOpenSSL.pas) over the shared binding. Vendored adapters remain unchanged. |
| Former XMPP OpenSSL binding | Twelve native declarations for hashes, HMAC/PBKDF2, random bytes and comparison; no TLS adapter or certificate support. | Its independent loader published readiness before loading/symbol validation, so a failed first load could leave nil function pointers on later calls. Loading was not synchronized, and its platform names were incomplete. Removed after moving generic behavior into [shared crypto helpers](src/obNXOpenSSLCrypto.pas). XMPP keeps SCRAM and other protocol behavior. |

The Nexus package is the most complete and is the implementation whose migrated
paths now have passing regression coverage. Its known defects in those paths
were repaired. Synapse's vendored adapter still contains the defects above but
is inactive in BotHost/XMPP. The former XMPP implementation was too narrow to
serve as the shared binding. A total bug-count comparison is not established
by this focused review; the choice rests on API breadth, concrete defects and
exercised behavior.

The owned Synapse adapter derives directly from `TCustomSSL`. It reuses the
shared certificate/key/PFX ownership rules, checks configuration results,
verifies DNS/IP identities and bounds retries with operation deadlines. The
binding alone does not supply socket policy; FCL and Synapse keep separate
transport adapters over the same native API owner.

Synapse's legacy 1.1 and older providers are still present as upstream source,
with no active consumer found in the inspected Nexus projects. They are not
selected or runtime-certified by this change. The only vendored Synapse edit is
the approved guard around JEDI's Delphi-only IFOPT G test, needed by NexusFPC.

## Native API evidence

- [Private-key loading](https://docs.openssl.org/3.5/man3/SSL_CTX_use_certificate/) distinguishes generic `SSL_CTX_use_PrivateKey_file` from RSA-only loading.
- [X.509 BIO decoding](https://docs.openssl.org/3.5/man3/d2i_X509/) uses BIO first and an optional pointer to the certificate pointer second; the standalone wrapper previously reversed them.
- [SNI callbacks](https://docs.openssl.org/3.5/man3/SSL_CTX_set_tlsext_servername_callback/) receive `SSL*`, `int*`, and `void*`; a Pascal class or dynamic-array parameter is not that callback ABI.
- [BIO controls](https://docs.openssl.org/3.5/man3/BIO_ctrl/) declare the pending count as `size_t`.
- [TLS options](https://docs.openssl.org/3.5/man3/SSL_CTX_set_options/) use `uint64_t` in OpenSSL 3.
- [OpenSSL release policy](https://openssl-library.org/policies/releasestrat/) gives the supported release lines. Prefer the supported 3.5 LTS series for a new deployment. The locally tested 3.4.7 runtime was not upgraded by this package repair.

## Crypto ABI evidence

- [EVP digest APIs](https://docs.openssl.org/3.4/man3/EVP_DigestInit/) distinguish size_t input lengths and unsigned-int digest lengths; EVP_sha256 returns an EVP_MD pointer, not an EVP_CIPHER pointer.
- [HMAC](https://docs.openssl.org/3.4/man3/HMAC/) uses int key length, size_t data length and caller-owned output. The one-shot HMAC API remains available in OpenSSL 3.
- [PBKDF2](https://docs.openssl.org/3.4/man3/PKCS5_PBKDF2_HMAC/) has explicit int-sized password/salt/output lengths and requires positive iterations.
- [CRYPTO_memcmp](https://docs.openssl.org/3.4/man3/CRYPTO_memcmp/) compares contents in time independent of those contents; length is not hidden by the helper.

## Scope of the conclusion

Verified with NexusFPC 3.3.1 and OpenSSL 3.4.7 on Win64. The complete deterministic
XMPP suite also passes, including SCRAM vectors, trusted/mismatched/untrusted
TLS peers and connection lifecycle checks. BotHost builds successfully, and its
registered FileExchange and OpenAI suites each pass all 13 tests. These runs
exercise the owned adapter, not the vendored Synapse OpenSSL adapter. Other OS/CPU combinations and native
C-heap leak freedom remain unverified. The inherited FCL adapter remains
available; shared binding ownership does not require merging transport APIs.


BotHost verification deliberately selects NexusFPC 3.3.1 and its matching RTL,
whereas the prior working BotHost outputs and Lazarus default used FPC 3.2.2.
The owner-approved prerequisites are a JEDI guard for a Delphi-only directive,
a Mustache assembly operand-width correction, and enabling Mustache's existing
FPC 3.3 AttributeTable adjustment. The HTTPS test fixture path was updated after
the XMPP package relocation. Existing test assertions were preserved.

Reproduce the registered BotHost suites from the Nexus checkout with
`projects/bothost/test/Invoke-NXBotTLSIntegrationTests.ps1`; it rebuilds the
existing test module and NexusTest host, checks every returned test status, and
keeps build products and logs under a unique temporary directory. Reproduce the
deterministic XMPP suite with `network/xmpp/test/Invoke-NXXMPPTests.ps1`. These
runs use local fixtures and loopback peers; no live-service result is claimed.

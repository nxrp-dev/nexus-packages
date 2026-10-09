# OpenSSL binding review

Reviewed the standalone Nexus package and Synapse's OpenSSL 3 and 1.1 bindings.
These are independent loaders and declarations. Fixes in the standalone package
do not repair or change Synapse. This is a focused source review of loading,
ABI declarations, identity verification, key/certificate handling, chain
ownership and TLS I/O, not an exhaustive audit of every inherited declaration.

| Implementation | Current role | Findings and recommendation |
| --- | --- | --- |
| [Nexus OpenSSL](src/openssl.pas), [object wrappers](src/fpopenssl.pp), [FCL adapter](src/opensslsockets.pp) | Independent binding and FCL socket integration | Retain the repaired package. Ten Win64 regression tests pass with OpenSSL 3.4.7. The tested paths cover identity verification, SNI, ALPN, keys, PFX chains, certificate generation and retry deadlines. Historical declarations and fallback library names remain; runtime loading is not a complete per-symbol capability check. |
| [Synapse OpenSSL 3 binding](../external/synapse/ssl_openssl3_lib.pas) and [adapter](../external/synapse/ssl_openssl3.pas) | Used by Nexus BotHost and XMPP transports | Requires a separate repair. `InitSSLInterface` maps generic private-key loading to RSA-only loading, so PEM EC keys are rejected. It looks up `X509_NAME_hash`, which is a macro in OpenSSL 3 rather than the required exported `X509_NAME_hash_ex`. It loads `X509_STORE_add_cert` from libssl rather than libcrypto. Its PFX path adds intermediates to a verification store rather than configuring the transmitted chain, and its stack cleanup depends on the nonexistent `SK_X509_POP_FREE` export. |
| [Synapse OpenSSL 1.1 binding](../external/synapse/ssl_openssl11_lib.pas) and [adapter](../external/synapse/ssl_openssl11.pas) | Available legacy provider; no active Nexus project consumer found in the inspected Pascal sources | Retire after confirming consumers. It repeats the RSA-only private-key loading and macro-based stack cleanup problems. Its PFX store insertion is not transmitted-chain configuration. OpenSSL 1.1.1 has ended public support; this provider is not a current runtime target. |

Both Synapse adapters call `SslSet1Host` only when `SNIHost` is nonempty and ignore
its return value. They do not configure IP identity checking through
`X509_VERIFY_PARAM_set1_ip_asc`. A verified IP connection therefore needs explicit
attention; chain verification alone does not establish the intended IP identity.
The standalone wrapper now distinguishes DNS names from IP addresses and the
socket adapter rejects an identity-configuration failure before connecting.

The inspected Synapse ABI declarations also use Pascal `Integer` for C `long`
control arguments/results and `BIO_ctrl_pending`'s `size_t`. C `long` is 64-bit
on common 64-bit Unix platforms, whereas Windows C `long` is 32-bit; `size_t` is
pointer-sized. This is a source-level portability defect, not a demonstrated
Win64 test failure. The standalone pending-size declaration now uses `csize_t`
and explicitly bounds conversion to the native `BIO_read` int-length interface.

A fourth older Synapse provider, `ssl_openssl.pas`/`ssl_openssl_lib.pas`, is also
present. It retains SHA-1 self-signed certificate generation and several of the
same legacy loading/cleanup choices. It was inspected for these shared issues,
but no runtime certification or changes were made to any Synapse provider.

## Native API evidence

- [Private-key loading](https://docs.openssl.org/3.5/man3/SSL_CTX_use_certificate/) distinguishes generic `SSL_CTX_use_PrivateKey_file` from RSA-only loading.
- [X.509 BIO decoding](https://docs.openssl.org/3.5/man3/d2i_X509/) uses BIO first and an optional pointer to the certificate pointer second; the standalone wrapper previously reversed them.
- [SNI callbacks](https://docs.openssl.org/3.5/man3/SSL_CTX_set_tlsext_servername_callback/) receive `SSL*`, `int*`, and `void*`; a Pascal class or dynamic-array parameter is not that callback ABI.
- [BIO controls](https://docs.openssl.org/3.5/man3/BIO_ctrl/) declare the pending count as `size_t`.
- [TLS options](https://docs.openssl.org/3.5/man3/SSL_CTX_set_options/) use `uint64_t` in OpenSSL 3.
- [OpenSSL release policy](https://openssl-library.org/policies/releasestrat/) gives the supported release lines. Prefer the supported 3.5 LTS series for a new deployment. The locally tested 3.4.7 runtime was not upgraded by this package repair.

## Scope of the conclusion

The regression results establish the listed behavior for the standalone package
on Win64. They do not establish full declaration coverage, native-library leak
freedom, or correct operation across the supported OS/CPU matrix. Synapse review
findings are source findings; its providers were neither substituted nor repaired.
Keep the transport APIs separate while deciding which low-level binding should
ultimately own the common OpenSSL declarations. Sharing that binding does not
require replacing either the FCL or Synapse transport architecture.

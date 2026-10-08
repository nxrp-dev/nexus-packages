# Synthetic XMPP TLS Fixtures

The loopback certificates and server private key are synthetic test-only
material. The separately identified Openfire certificate is public trust
material for the controlled local interoperability server. None of these files
is production trust material.

- `ca.crt` signs the trusted `localhost` server certificate.
- `server.crt` contains the `DNS:localhost` subject alternative name.
- `server.key` is the intentionally public test server key.
- `untrusted-ca.crt` provides a different trust anchor for the rejected-issuer test.
- `server.ext` records the server certificate extensions used when producing the fixture.
- `openfire-nexus-local.crt` is the public self-signed certificate exported
  from the controlled Openfire 5.1.2 server. Its SHA-256 fingerprint is
  `7E:1B:CD:90:CA:93:B4:DC:EB:8E:8C:06:36:22:4E:E3:21:33:5F:01:02:F1:06:BA:CA:3F:F8:AC:21:5F:A6:53`.
  No corresponding private key is stored here.

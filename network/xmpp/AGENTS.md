# NexusXMPP Agent Instructions

These rules apply to `packages/nexus-packages/network/xmpp`.

## Standards

- Follow `../../../../.ai/standards/pascal.md`.
- Follow `../AGENTS.md` for Nexus networking boundaries.

## Architecture

- NexusXMPP is a client-to-server XMPP protocol library, not a generic transport or XML framework.
- The connection thread exclusively owns its socket, parser, and protocol state.
- Connection and module events are raised directly on the connection thread.
- Applications own any transfer of event data to another thread.
- Cross-thread command queues are bounded and queued payloads own their data.
- Keep OpenSSL use behind the XMPP crypto and TLS owners.
- JID parts and authentication credentials are deliberately ASCII-only. Reject
  non-ASCII identity input explicitly; do not add Unicode normalization,
  PRECIS, IDNA, or internationalization dependencies without a verified owner
  requirement.
- Preserve UTF-8 stanza and message content without identity normalization.
- Never silently fall back to plaintext, `TSSLNone`, or disabled certificate
  verification.

# synkty

Local-first markdown notes and peer-to-peer file sync, written from scratch in Rust.
Our own protocol: no Syncthing source, no BEP compatibility, no MPL obligations.

**Status: M0 skeleton.** This repo currently holds the protocol spec, the workspace
layout and CI. The identity implementation lands with milestone M0 (see below).

## The wedge

1. **Sync costs nothing to run.** Peer-to-peer, no account, no quota. A relay is optional
   and carries ciphertext only.
2. **Agents are clients.** Scoped, signed grants per agent; every write attributable and
   verifiable offline. No shared API key.
3. **The map is a view, not a plugin.** One `.canvas` file (JSON Canvas spec), two views:
   auto-laid-out mind map and hand-placed board.
4. **Plain markdown underneath.** A vault is a folder. Obsidian can open ours; we can open
   Obsidian's. Never a binary container.

## Milestones

| id | what | demo (the definition of done) |
|----|------|-------------------------------|
| M0 | identity + pairing | two terminals pair, `fald devices` lists both, revocation is refused immediately |
| M1 | one-shot LAN sync | 1 GB folder, killed twice mid-transfer, completes and every file verifies |
| M2 | continuous sync + merge | same note edited offline on both sides -> one file, both edits, shadow version, no conflict twin |
| M3 | WAN | two homes, no port forwarding, sync through a relay that sees only ciphertext |
| M4 | index + MCP + agents | agent writes inside its grant, outside is refused, `fald log` verifies each write |
| M5 | desktop shell + canvas | opens an Obsidian vault, edits a `.canvas` both apps understand |

## Layout

```
crates/
  fald-identity/   Ed25519 keys, device ids, pairing, grants, revocation
  fald-proto/      wire messages (versioned, fuzzed, vector-tested)      [M1]
  fald-store/      block store (BLAKE3 CAS), packs, GC, placeholders     [M1]
  fald-net/        QUIC transport, Noise handshake, discovery, relay     [M1/M3]
  fald-vault/      scanner, watcher, ignore rules, manifest diff         [M1/M2]
  fald-merge/      3-way text merge, conflict policy, shadow versions    [M2]
  fald-index/      SQLite index, backlinks, full-text search             [M4]
  fald-attrib/     signed write records and audit queries                [M4]
  fald-mcp/        MCP server (rmcp)                                     [M4]
  fald-daemon/     supervisor + local JSON-RPC                           [M2]
  fald-cli/        init, pair, devices, status, log, grant               [M0]
docs/
  protocol.md      the spec; written before the code
  threat-model.md  what we promise and what we do not
```

## Build

```
cargo test --workspace
```

Requires a stable Rust toolchain (see `rust-toolchain.toml`).

## Licence

Code: AGPL-3.0-or-later. Spec and docs: CC BY 4.0. The name and logo are not licensed.
`synkty` is a placeholder name.

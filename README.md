# synkty

Local-first Markdown notes and device-to-device sync, written from scratch in Rust.
Files stay files: a vault is a folder Obsidian can open, and nothing is locked in a container.

**Status: pre-alpha.** The repo holds the plan, the protocol spec and a CI skeleton.
Code starts at 0.1.0 (see the release train below). Nothing here is usable yet.

## What 1.0 is

One owner, several of their own devices, plus their agents. Byte-preserving
Obsidian-compatible Markdown and attachment sync, explicit whole-file transfer,
deterministic conflict copies, version history and trash, exportable backups with a
restored-at-least-once guarantee, signed attribution of every write, scoped agent grants
over a local stdio MCP, and a small Linux desktop shell with a mind map derived from
headings and wiki-links. Direct connections over configured endpoints, or a
user-operated relay that only ever carries ciphertext.

**Target: Tue 2027-06-01**, with a four-week-earlier path if a second maintainer appears.
The full plan, contract and calendar: [`docs/plan.md`](docs/plan.md).

## What 1.0 is not

No mobile. No supported Windows or macOS packages (CI experiments only). No teams, no
CRDT editing, no hosted service, no public relay, no automatic NAT traversal, no Obsidian
plugin, no Canvas editing, no selective sync, no placeholder files, no auto-updater, no
billing. `.canvas` files sync as opaque files; synkty does not edit them in v1.

## The promises that are actually true

1. **No accounts, no quota.** Peer-to-peer. A relay is optional, self-hosted, and sees
   ciphertext plus device IDs and byte counts — never note content or paths.
2. **Agents have their own keys.** A grant is a signed, expiring, path-scoped document.
   Every write is attributable and verifiable offline, without our server or our code.
3. **The map is derived.** Headings and wiki-links project into one view; editing it
   changes only the matching Markdown span. There is no second map document to keep in
   sync, and existing `.canvas` files are left alone.
4. **Obsidian-compatible means** an existing vault opens in both apps at once, notes and
   attachments round-trip byte-for-byte, and `.obsidian` (workspace, themes, plugins)
   stays per-device and is never synced. Running another sync provider on the same vault
   is unsupported, and onboarding refuses to start without a verified backup.

## Release train

| version | name | ships | date |
|---|---|---|---|
| 0.1.0 | Welcoming | identity, pairing, membership, recovery kit, frozen byte formats | Sun 2026-12-06 |
| 0.2.0 | Keeping | crash-safe vault, WAL log, history, trash, backup and restore | Sun 2027-01-10 |
| 0.3.0 | Joining | direct sync, deterministic conflicts, resumable transfer, Obsidian fixtures | Sun 2027-02-21 |
| 0.4.0 | Carrying | self-hosted ciphertext-only relay with counters and limits | Sun 2027-03-14 |
| 0.5.0 | Tending | agent grants, stdio MCP, quotas, portable proofs | Sun 2027-04-11 |
| 0.6.0 | Gathering | Linux desktop shell, derived map, packages, service | Sun 2027-05-09 |
| 1.0.0 | Arriving | release candidate, verification matrix, publication | Tue 2027-06-01 |

Patch releases fix defects and never change signed bytes or persistent formats.

## Repository

```
crates/            synkty-identity, -proto, -store, -net, -vault, -merge,
                   -index, -attrib, -mcp, -daemon, -cli   (0.1 renames the skeleton)
docs/
  plan.md          authoritative plan, contract, calendar, risks, cuts
  protocol.md      wire format and identity spec
  crypto-and-log.md  primitives and the attribution log
  threat-model.md  adversaries and non-promises
  relay.md         relay economics and abuse model
  packaging.md     installers per platform
  review-2.md      the review that shaped the contract
```

## Build

```
cargo test --workspace
```

Pinned toolchain in `rust-toolchain.toml`; `Cargo.lock` is committed.

## Licence

Code, including the relay and desktop shell: AGPL-3.0-or-later. Specs and docs: CC BY 4.0
(`LICENSE-docs`). The name and logo are not licensed. Contributions are DCO sign-off,
not a CLA. A future managed service may be operated, but this code stays AGPL.

`synkty` is still a placeholder name; protocol domain strings are frozen regardless.

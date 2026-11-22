# synkty v1 build plan — first Kimi K3.1-Pro planning pass

Provenance: `moonshotai/Kimi-K3.1-Pro` over CommandCode, one-shot call, Sun 2026-11-22 11:00 PST.
Input 36,711 tok / output 13,786 tok (10,709 of them reasoning) = **$0.211** at $2/$10 per M.
Prompt = the four design docs in this folder; no other context.

How later passes run (decision, 2026-11-22): **per job, never the delegation pin.** My subagents
stay on deepseek-v4.1-flash; each planning pass is its own one-shot process:

    tools/kimi-plan.sh docs/plan-v2.md "the task" docs/a.md docs/b.md

It calls `hermes -z ... -m moonshotai/Kimi-K3.1-Pro --provider commandcode --usage-file`,
writes the answer with a provenance header, and appends tokens + cost to `docs/plan-log.md`.
Floor cost per pass is ~30k input tokens (~$0.06) because every call carries the agent system
prompt; the pass below measured $0.211.

Status: proposal, not adopted. Three of its findings were defects in my own docs and are already
fixed in `crypto-and-log.md`: the 16-vs-10-byte device id contradiction, the missing `prev`
field in the entry body, and the `apply → append` ordering that was not write-ahead logging.
Two findings need a decision rather than an edit (X25519 key in `DeviceRecord`; canonical
vector-clock encoding) and are listed at the end.

---

1. MILESTONES M0–M5

M0 — Identity, pairing, and a frozen wire format (2 weeks)
Scope: Ship a `synkty` CLI that creates device identities, performs SPAKE2 pairing over loopback/LAN TCP, persists verified device records, and freezes the formats that later milestones cannot be allowed to reinterpret.
Binary: Static Linux `synkty`, attached to the M0 GitHub release; repository licensed AGPL-3.0 from the first commit.
Demo:
  A: `synkty pair offer --listen 127.0.0.1:4700`
  B: `synkty pair join 127.0.0.1:4700 --code '<six words>'`
  Both print: `PAIR ok peer=<20-symbol-device-id> record_verified=true`
  `synkty identity vectors` prints the three frozen vector rows; `cargo test -p synkty-protocol` finishes with all vector and malformed-input tests passing.
Exit criterion:
  - Resolve the specification contradictions before M1: one 10-byte raw device-ID representation everywhere; `prev` explicitly present in log entries; vector clocks encoded as sorted vectors, not maps; one domain-separation rule; one revocation encoding; `synkty` naming throughout.
  - Add a signed X25519 encryption public key to `DeviceRecord`; an Ed25519 identity key alone is not a vault-key wrapping design.
  - Document that pairing authenticates a device but does not confer vault ownership.
  - Decoders pass fuzz/property tests for oversized lengths, trailing bytes, invalid UTF-8/NFC, bad checksums, path traversal, and segment-prefix escapes.
  - Identity files are `0600`, keys never appear in logs, paired records survive restart, and oversized frames are rejected before allocation.

M1 — A crash-safe local vault with a real write-ahead log (4 weeks)
Scope: Implement one local Markdown vault with atomic file writes, save-burst coalescing, signed per-device log entries, deterministic replay, JSON CLI output, and offline chain verification—without network sync yet.
Binary: Updated static `synkty`; agents can already automate every vault operation with stable JSON and exit codes.
Demo:
  `printf '# First note\n' | synkty --vault /tmp/v note put inbox/first.md --json`
  Output: `{"committed":true,"seq":1,"path":"inbox/first.md"}`
  `synkty --vault /tmp/v log verify`
  Output: `VERIFY ok entries=1 corrupt=0 gaps=0`
  After restart, `synkty --vault /tmp/v note get inbox/first.md` prints exactly `# First note`.
Exit criterion:
  - Replace the document’s `apply → append` sequence with `verify/resolve → append+fsync → atomic apply → persist applied cursor`; the current order is not write-ahead logging.
  - Kill-process tests at every persistence boundary recover without silent file/log divergence.
  - Replay is idempotent; out-of-order receiving is buffered, while genuine post-sync sequence gaps, bad signatures, truncation, and equivocation are detected.
  - A 300 ms editing burst creates one entry; a file transfer creates one entry per completed file, never per block.
  - No pruning: correctness and recovery are proven before storage optimization.

M2 — Direct two-device synchronization and resumable file transfer (5 weeks)
Scope: Add pinned-peer QUIC/TLS synchronization, end-to-end encrypted vault payloads, deterministic concurrent-edit conflict copies, block-verified resumable whole-file transfer, and explicit suspect-device handling.
Binary: Updated `synkty` on Linux, Windows, and macOS; no GUI dependency.
Demo:
  After editing the same note offline on both devices and interrupting one file transfer:
  `synkty --vault /tmp/a sync --peer 127.0.0.1:4701 --json`
  Output: `{"converged":true,"conflicts":1,"transfers_resumed":1,"content_hashes_match":true}`
  Both vaults contain the same primary note, the same deterministic conflict copy, and byte-identical transferred files.
Exit criterion:
  - Randomized tests converge regardless of message order, duplication, delay, restart, or which side initiates.
  - Concurrent writes never silently overwrite either version; do not ship CRDT or last-write-wins merging.
  - Transfers resume from verified blocks, write to temporary files, verify the final BLAKE3 hash, and atomically rename.
  - Unpaired, revoked, and wrong-key peers cannot read or write a vault.
  - Payload confidentiality does not depend on a relay terminating TLS; the relay design must forward end-to-end ciphertext.
  - Repeated large-note and multi-gigabyte-file tests show bounded memory use.

M3 — Self-hosted ciphertext-only relay with useful metering (3 weeks)
Scope: Ship a separate `synkty-relay` binary that forwards only authenticated synkty frames, enforces connection/rate/volume limits, survives reconnect accounting, and exposes signed per-device usage records without deploying a public service.
Binary: `synkty-relay` plus relay-enabled `synkty`.
Demo:
  `synkty --vault /tmp/a sync --peer <device-id> --relay 127.0.0.1:4740 --force-relay --json`
  Output: `{"transport":"relay","converged":true,"relay_bytes":18342}`
  `synkty relay quota --relay 127.0.0.1:4740`
  Output showing separate monthly note/file byte totals and current limits.
Exit criterion:
  - An unpaired third device gets zero forwarded bytes; generic TCP/UDP tunneling attempts fail.
  - Relay packet captures contain neither note contents nor vault paths.
  - Relay bit-flips, injection, replay, and reordering are detected by the endpoints.
  - Reconnects do not double-count usage; per-device, per-IP, and global concurrency limits survive basic abuse tests.
  - Direct sync still works when the relay is unavailable.
  - Run only in tests or on user-operated machines; no hosted relay and no new infrastructure spend.

M4 — Agent grants, revocation, and portable attribution proofs (3 weeks)
Scope: Add agent-owned Ed25519 keys, owner-signed least-privilege grants, causal revocation, per-entry grant verification, author attribution, JSONL export, and self-contained log proofs verifiable without private keys or network access.
Binary: Updated `synkty`, including `grant`, `agent`, `log prove`, `log export`, and `log verify-proof` commands.
Demo:
  `synkty log prove /tmp/v inbox/task.md | synkty log verify-proof`
  Output: `PROOF ok author=indexer authority_chain=agent->grant->owner revoked_in_causal_past=false`
  An attempted write outside `inbox` prints `DENIED path_outside_prefix`; a post-revocation write prints `DENIED grant_revoked`.
Exit criterion:
  - A separate verifier crate can validate proofs using only public records and documented bytes.
  - Historical verification does not use the current clock: grant expiry governs acceptance on the enforcing device, while causal history determines whether an already-accepted entry was authorized.
  - Revocation remains monotonic locally but does not retroactively invalidate entries outside its causal past.
  - Path normalization, segment boundaries, every op bit, expiry/skew handling, replayed grants, and revoked owners all have negative tests.
  - “Verified” means a valid authority chain—not human intent, truthful content, or trustworthy wall-clock time.

M5 — Minimal desktop product and installable v1 (5 weeks)
Scope: Ship a Tauri desktop shell with Markdown editing, vault/file browsing, conflict resolution, transfer status, author/fork warnings, and a mind map generated from headings and wiki-links, with all mutation logic remaining in the Rust core.
Binary: `synkty`, `synkty-gui`, and desktop release packages; Linux AppImage/deb, unsigned Windows NSIS with a SmartScreen note, and signed/notarized macOS DMG using the existing Apple account.
Demo:
  `synkty-gui --smoke-test`
  Output: `UI_SMOKE ok note_created=true map_updated=true conflict_visible=true author_badge=verified synced_cli_peer=true`
Exit criterion:
  - Clean-machine tests install, create/edit a note, edit a map node, restart without loss, and sync with a CLI-only peer.
  - Map edits modify Markdown directly; there is no second map document format to synchronize.
  - Broken chains and forks produce blocking red warnings, never automatic repair.
  - Every UI operation has an equivalent stable CLI/JSON operation.
  - No mobile, account system, billing, updater, or hosted control plane is required to use the release.


2. THE SIX HIGHEST RISKS, ORDERED BY EXPECTED DAMAGE

1. Scope collapse: the project becomes six products and never ships
What breaks: Notes, arbitrary files, agent authorization, verifiable history, relay operations, mind mapping, and five platforms compete before the core loop is reliable.
Early warning: M0 exceeds two weeks, M1 starts acquiring UI/mobile work, or agents produce parallel subsystems without executable milestone exits.
Cheapest mitigation: Enforce the milestone gates literally, keep one releasable branch, and treat section 3 as the v1 boundary rather than a backlog wish list.

2. Protocol and threat-model ambiguity produces unauthorized access or incompatible implementations
What breaks: Pairing may be mistaken for vault membership, relay-terminated TLS may expose plaintext, signature bytes may diverge, and grants/revocations may acquire contradictory meanings.
Early warning: The current raw-ID sizes, map encoding, missing `prev`, DeviceRecord key material, and revocation semantics already disagree across documents; adversarial tests would expose more.
Cheapest mitigation: Freeze a short normative threat model and byte-format specification in M0, use one-owner vaults in v1, and require malicious-peer tests plus frozen vectors before sync coding.

3. The transaction log becomes an unauditable sidecar or loses writes during crashes
What breaks: `apply → append` permits unlogged writes; treating network reordering as a sequence attack rejects valid entries; pruning or equivocation handling can destroy evidence.
Early warning: Kill-process tests find file/log divergence, randomized delivery reports false gaps, or corrupted history passes verification.
Cheapest mitigation: Implement the append/fsync/apply/replay state machine first, keep complete logs in v1, buffer out-of-order entries, quarantine forks, and fault-inject every persistence boundary.

4. Conflict and transfer bugs silently damage notes or files
What breaks: Concurrent edits overwrite each other, resumed blocks assemble incorrectly, or interrupted transfers appear as complete files.
Early warning: Repeated two-device runs produce different hashes, conflict counts vary by delivery order, or partial files become visible under final names.
Cheapest mitigation: Use deterministic conflict copies, content-addressed blocks, final-hash verification, temporary files, atomic rename, and idempotent transfer state; no clever automatic merging in v1.

5. The relay becomes an abuse channel, a surprise cost, or a privacy liability
What breaks: Attackers mint unlimited device keys to evade per-device quotas, reconnect accounting inflates usage, or relay logs expose paths despite the ciphertext-only claim.
Early warning: Tests show that pairing alone does not prevent Sybil enrollment, per-device limits reset after key rotation, or metadata reveals more than device IDs/timing/bytes.
Cheapest mitigation: Keep v1 self-hosted, add global and per-IP/ASN backpressure alongside device counters, disclose metadata collection, and launch any future public relay notes-only before considering capped files.

6. iOS turns “sync” into a promise the platform cannot meet
What breaks: Background suspension prevents an always-on peer, container/File Provider semantics complicate vault access, and the UI port forks product behavior.
Early warning: A small TestFlight spike syncs only while foregrounded or loses access to externally selected folders.
Cheapest mitigation: Exclude iOS from v1 and do not advertise Syncthing parity; later build a companion that syncs on open with opportunistic refresh only after the Rust core is stable.


3. WHAT TO CUT FROM V1

- iOS and Android: background execution and storage semantics would consume disproportionate time while changing the product promise.
- Public hosted relay: operate nothing until real users justify it; self-hosting proves the protocol without ongoing cost.
- Automatic NAT hole punching: direct connections plus a self-hosted relay deliver connectivity without another fragile state machine.
- Team/multi-owner vaults, SSO, LDAP, and fleet policy: these belong to the future paid control plane, not single-user synchronization.
- Real-time collaborative editing and CRDTs: deterministic conflict copies are understandable, testable, and sufficient for v1.
- Free-form mind-map canvas or separate map files: derive a useful editable projection from Markdown instead of creating a second sync format.
- Placeholder files and virtual-filesystem integration: OS-specific data-availability bugs are not worth the convenience yet.
- Selective sync: ship complete vaults and explicit whole-file transfers first.
- Log pruning and compaction: retain provable history until verification and recovery have real-world mileage.
- Relay volume-shape heuristics: simple disclosed quotas and backpressure are easier to audit and less invasive.
- Auto-update infrastructure: signed release artifacts and manual upgrades avoid another security-critical service.
- Authenticode purchase, app-store releases, Flathub/winget/Homebrew/F-Droid: distribution breadth does not prove the product.
- Post-quantum signatures or custom ML-KEM work: retain rustls’s hybrid TLS support and format suite bytes, but add no new cryptography.


4. THE THREE DECISIONS THE OWNER MUST MAKE BEFORE CODING STARTS

1. “Exactly whose problem does v1 solve?”
Recommended answer: One technical owner synchronizing their own desktop devices and agents, with complete Markdown vaults, manual conflict resolution, explicit file transfer, and a minimal desktop mind map; no mobile or multi-human teams.

2. “What security promise are we willing to put on the tin?”
Recommended answer: Pairing proves device identity only, vault access requires explicit owner membership, network payloads are end-to-end encrypted, and v1 stores local Markdown and logs plaintext with an honest OS-disk-encryption recommendation rather than implying encrypted-at-rest vaults.

3. “Will we operate a free public relay in v1?”
Recommended answer: No; ship the self-hosted relay and metering now, then consider a notes-only public relay after real users exist, adding capped file relay only if measured abuse and egress costs remain acceptable.

---

## Findings from this pass still open

1. **`DeviceRecord` has no X25519 key.** Vault keys are wrapped to devices, but the record only
   carries an Ed25519 identity key. Either add `enc_pub: [u8;32]` (signed, rotated separately)
   or derive wrapping from the identity key with a domain-separated KDF and document the choice.
2. **Vector-clock encoding.** `seen` as a map is not canonical; encode as a sorted vector of
   `(dev, seq)` pairs and reject duplicates and unsorted input on decode.

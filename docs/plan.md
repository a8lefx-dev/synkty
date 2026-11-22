<!--
Authoritative plan for synkty 1.0, adopted 2026-11-22.
Produced by one per-job Kimi K3.1-Pro pass (534,525 in / 52,950 out, $1.599) over all
prior documents. This file controls scope, dates, release names and the v1 contract;
docs/plan-v1-kimi.md and docs/review-2.md are historical inputs.
-->

# synkty execution plan and v1 contract

Status: authoritative. Adopted Sun 2026-11-22. The earlier planning and review documents are historical inputs, not parallel work queues.

This plan controls scope, dates, release names, and the ten v1 decisions. In week 1, section 4 becomes `docs/v1-contract.md` and each normative format gets its own specification. Later ADRs may amend this contract only explicitly. Implementation PRs may not change signed bytes, persistent formats, or compatibility claims incidentally. Every normative requirement has an entry in the requirement-to-test matrix before its implementation merges.

## 1. ONE-PAGE SUMMARY

Version 1.0 is a Linux-supported, local-first notes and file-synchronization product for one owner with multiple devices and agents. It provides a Rust CLI and daemon, a minimal Tauri desktop application, byte-preserving Obsidian-compatible Markdown and attachment sync, explicit whole-file transfer, deterministic conflict copies, version history, trash, exportable backups, tested restore, signed attribution, scoped agent grants, and a local stdio MCP interface. Devices connect directly over configured endpoints or through a separately identified, user-operated ciphertext-only relay. The desktop map is derived from Markdown headings and wiki-links. Existing `.canvas` files are preserved as opaque files. There is no second map document to synchronize.

Version 1.0 is not a mobile product, a supported Windows or macOS product, a team collaboration system, a CRDT editor, an Obsidian plugin, a Canvas editor, a hosted sync service, a public relay, an automatic NAT-traversal system, a selective-sync or placeholder-file system, an auto-updater, a billing product, or an XRP integration. Windows and macOS core CI may remain experimental, but their installers and filesystems are not release claims. Local vaults, indexes, logs, and CAS content are not advertised as encrypted at rest; OS account protection and full-disk encryption are recommended honestly.

The committed release date is Tue 2027-06-01. The schedule uses 24 feature-build weeks, one release-candidate week, and two defended buffer weeks: 27 full calendar weeks from Mon 2026-11-23 through Sun 2027-05-30. Mon 2027-05-31 is final artifact verification and Tue 2027-06-01 is publication. This accounts for approximately 546 gross founder hours at 20 hours per week. There is no unallocated feature slack.

The three events most likely to break the date are:

1. Founder review and integration capacity falling behind agent output, or new scope entering after the contract freezes.
2. A late redesign caused by persistence, key-lifecycle, or revocation defects that escaped the executable format and recovery gates.
3. Real Obsidian, filename, watcher, and desktop-integration behavior consuming more time than synthetic tests predicted.

The date is protected by narrowing supported scope, by weekly binary gates, and by the dated cuts in section 8. It is not protected by adding founder hours, skipping recovery drills, or treating agent reports as verification. A release-blocking safety failure overrides the date; an unsafe build is not released to satisfy the calendar.

## 2. NAMED PHASES

### Pre-1.0 numbering

Releases use `0.<train>.<patch>`. The six feature trains are `0.1.0` through `0.6.0`. The train increments only for a gated feature release. Patch releases contain fixes only and may not change normative signed bytes or persistent formats. A required wire or schema change reopens the relevant specification and requires an ADR, new vectors, migration tests, and a new train rather than an undocumented patch.

Release candidates use `1.0.0-rc.N`. The codenames below are release names only. They are not product brands, crate names, protocol domains, or new commands; the version number is always primary. The number becomes `1.0.0` only when the accepted release candidate passes the complete clean-machine, restore, mixed-version, rollback, security, Obsidian, and artifact gates on the declared Linux support matrix with no open P0 or P1 issue. A change after an RC requires another RC.

### 0.1.0 Welcoming — identity and immutable formats

Dates: Mon 2026-11-23 through Sun 2026-12-06.

Scope: Freeze the contract and byte formats, then implement device identity, authenticated pairing, signed membership and role records, key wrapping, an offline owner recovery record, strict decoders, revocation records, and independently checked vectors.

Demo:

```
A: synkty --config /tmp/a pair offer --listen 127.0.0.1:4700
B: synkty --config /tmp/b pair join 127.0.0.1:4700 --code '<six words>'
B: PAIR ok peer=7F3K-2QX9-M4TB-8ZRD-1Y6C record_verified=true vault_member=false
$ synkty identity vectors --check
VECTORS ok device_id_bytes=10 valid=3 malformed=47 independent_verifier=pass
```

Exit criteria:

- All ten decisions in section 4 are reflected in normative documents and the requirement-to-test matrix; no older `fald` name or contradictory rule remains active.
- `DeviceRecord` contains both Ed25519 and signed X25519 public keys with explicit key epochs. Pairing alone cannot read, write, or administer a vault.
- Frozen vectors cover `Signed<T>`, device IDs, grants, membership, revocations, key wrapping, sorted vector clocks, canonical paths, and malformed lengths, trailing bytes, noncanonical NFC, unsorted or duplicate clocks, and unknown versions.
- A separately written decoder validates the vectors without importing production decoder code.
- SPAKE2 pairing survives restart, single-use and ten-minute expiry are enforced, identity files receive correct Linux permissions, and keys never appear in diagnostics.
- Recovery-record generation and an offline restore of owner authority are demonstrated before downstream coding opens.

First new user ability: create a recoverable owner root, pair devices, compare fingerprints, and verify identity and policy bytes offline.

Explicitly absent: vault mutation, file sync, transport beyond direct TCP pairing, public discovery, GUI, mobile, and accounts.

### 0.2.0 Keeping — a recoverable local vault

Dates: Mon 2026-12-07 through Sun 2027-01-10.

Scope: Implement the single-instance daemon, crash-safe vault mutation, write-ahead signed log, CAS history, save-burst coalescing, external-edit reconciliation, trash, backup export, restore, status JSON, and complete storage fault injection before any networking.

Demo:

```
$ printf '# First note\n' | synkty --vault /tmp/v note put inbox/first.md --json
{"schema":1,"committed":true,"seq":1,"path":"inbox/first.md"}
$ synkty --vault /tmp/v backup export /tmp/v.skbak && \
  synkty backup restore /tmp/v.skbak --into /tmp/restored --verify
RESTORE ok notes=1 blobs=1 log_entries=1 content_hashes_match=true
$ synkty --vault /tmp/restored log verify
VERIFY ok entries=1 corrupt=0 gaps=0 working_tree_mismatches=0
```

Exit criteria:

- Every mutation follows `verify and authorize -> append and fsync log -> write and fsync same-filesystem temporary content -> atomic replace -> fsync parent -> persist and fsync applied cursor`. Startup reconciliation is idempotent at every boundary.
- Kill, fsync-failure, read-only-filesystem, corrupt-block, stale-lock, interrupted-migration, and ENOSPC tests produce either the complete old state or the complete new state, never an unlogged or partially visible file.
- A 300 ms edit burst emits one entry; a completed file transfer emits one entry; replay is idempotent and out-of-order replication is buffered rather than mislabeled as equivocation.
- Historical content, signed tombstones, user-visible trash, explicit permanent deletion, and export/restore work without a peer or network.
- Watchers are backed by periodic hashed reconciliation; shutdown flushes pending saves and self-generated and internal temporary events are suppressed.
- The support envelope of 100,000 files, 100 GiB of current content, and bounded history metadata is measured. Storage use and cleanup are visible in `status --json`.

First new user ability: use one local Markdown vault with reliable edit recovery, undo through retained versions and trash, and a backup that has actually been restored.

Explicitly absent: network sync, agents through MCP, multi-human ownership, log pruning, placeholders, and GUI.

### 0.3.0 Joining — direct sync and safe file transfer

Dates: Mon 2027-01-11 through Sun 2027-02-21.

Scope: Add pinned QUIC/TLS peer connections, end-to-end vault encryption, manifest exchange, deterministic convergence for every mutation pair, verified resumable block transfer, exclusive-provider migration checks, and automated Obsidian fixtures.

Demo:

```
$ synkty --vault /tmp/a sync --peer 127.0.0.1:4701 --json
{"schema":1,"converged":true,"conflicts":1,"transfers_resumed":1,"content_hashes_match":true}
$ diff -r /tmp/a/current /tmp/b/current && synkty --vault /tmp/a conflicts diff --peer /tmp/b
CONVERGED identical_current=true identical_conflict_names=true missing_blobs=0
```

Exit criteria:

- Randomized message order, duplication, delay, repeated initiation, restart, and 72-hour partitioned soak tests yield byte-identical current files, conflict artifacts, tombstones, and applied history on both peers.
- Text edits, binary writes, edit/delete, rename/rename, rename/edit, file/directory replacement, and case or normalization collisions never discard either input. Automatic three-way and last-write-wins merging are absent.
- Transfer resumes only from verified blocks, uses hidden temporary storage, verifies the final BLAKE3 hash, fsyncs, and atomically renames. A partial file never appears under its final name or inside Obsidian.
- Unpaired, paired-but-not-member, revoked, wrong-key, wrong-vault, and old-epoch peers receive no content or unauthorized mutation.
- The 1 GiB transfer demo is killed twice and completes with no restart-from-zero requirement. An 8 GiB file, four concurrent transfers, faulty disks, and a 100,000-file manifest stay within the published CPU, memory, and disk limits.
- Real-vault fixtures preserve Markdown, frontmatter, BOM and line endings, links, embeds, tags, attachments, `.canvas`, `.base`, and unknown plugin content byte-for-byte except the exact span edited by synkty.
- First-run activation refuses to write until backup, inventory, and exclusive-sync confirmation are complete.

First new user ability: synchronize an existing complete Obsidian vault between two explicitly connected Linux devices and send a large file with recovery from interruption.

Explicitly absent: public discovery, automatic NAT traversal, a hosted or public relay, automatic semantic merge, selective sync, `.obsidian` sync, and supported Windows/macOS packages.

### 0.4.0 Carrying — self-hosted ciphertext-only relay

Dates: Mon 2027-02-22 through Sun 2027-03-14.

Scope: Ship a separate relay binary with its own pinned relay identity, authenticated member-pair forwarding, configurable rate and volume counters, reconnect-safe accounting, direct fallback, and disclosed metadata handling.

Demo:

```
$ synkty --vault /tmp/a sync --peer <device-id> --relay 127.0.0.1:4740 --force-relay --json
{"schema":1,"transport":"relay","converged":true,"relay_bytes":18342,"plaintext_paths_observed":false}
$ synkty relay quota --relay 127.0.0.1:4740 --json
{"schema":1,"device_pair":"...","notes_month_bytes":18342,"files_month_bytes":0,"reconnect_double_count":0}
```

Exit criteria:

- Packet captures and relay storage contain no note contents, vault paths, vault keys, or reusable end-to-end plaintext. Endpoint bit flips, injection, replay, and reordering are detected.
- An unpaired or nonmember third device receives zero forwarded bytes. Generic TCP, UDP, VPN, proxy, and CDN tunnel attempts fail.
- Device-pair counters reconcile across reconnects; per-device, per-IP, and global concurrency and rate limits pass abuse tests. Self-host operators can inspect and configure limits without any billing system.
- Relay availability does not change convergence. Direct sync resumes when the relay is stopped.
- Two real networks complete the forced-relay drill through an operator-configured reachable relay. No port-forwarding-free claim is made.

First new user ability: synchronize through a machine the user controls when a direct route is unavailable.

Explicitly absent: a project-operated public relay, free-tier accounts, payments, automatic hole punching, anonymous metadata, volume-shape surveillance heuristics, and relay access to plaintext.

### 0.5.0 Tending — agents, MCP, and portable verification

Dates: Mon 2027-03-15 through Sun 2027-04-11.

Scope: Enforce agent-owned keys and least-privilege grants in the daemon, add versioned local stdio MCP, concurrency preconditions, resource quotas, cancellation on revocation, JSONL audit export, and independently verifiable log proofs.

Demo:

```
$ synkty --vault /tmp/v log prove inbox/task.md | synkty log verify-proof
PROOF ok author=indexer authority_chain=agent->grant->owner revoked_in_causal_past=false
$ synkty-agent --stdio synkty-mcp --write ../outside.md
DENIED code=path_outside_prefix operation=write committed=false
$ synkty grant revoke <grant-id> && synkty-agent --stdio synkty-mcp --append inbox/task.md
DENIED code=grant_revoked operation=append committed=false active_jobs_cancelled=true
```

Exit criteria:

- Every MCP read, search, write, append, move, delete, export, and status operation is authorized at admission and again at commit with canonical paths and the current deny set and key epoch.
- Expected-content-hash preconditions, per-vault serialized commits, idempotency keys, dry-run, capability discovery, structured errors, and versioned schemas prevent lost read-modify-write updates.
- Path traversal, symlink race, separator, ADS, rename TOCTOU, expiration, skew, replay, wrong vault, revoked owner, every op bit, and scoped-query tests all fail closed.
- Per-grant operation, byte, file-size, job, queue, and execution-time quotas are enforced and reported. Revocation cancels active jobs and cached capabilities without erasing valid history.
- Grant default expiry is 24 hours, maximum lifetime is seven days, and renewal or key rotation requires current owner authority with explicit overlap rules.
- An independent verifier validates entries, checkpoints, grant chains, revocations, and single-file proofs from public records and documented bytes alone. Historical verification does not consult the current clock.

First new user ability: let an agent perform bounded vault work through MCP, inspect exactly what it did, prove the authority chain offline, and stop it immediately.

Explicitly absent: shared API keys, arbitrary agent filesystem access through the product, remote hosted MCP, agent self-renewal, multi-owner teams, and proof that a human intended an action.

### 0.6.0 Gathering — the Linux desktop product

Dates: Mon 2027-04-12 through Sun 2027-05-09.

Scope: Ship a minimal keyboard-accessible Tauri shell over the existing authorized core API with vault and file browsing, exact-span Markdown editing, author and fork warnings, conflict and restore workflows, transfer status, exclusive-provider onboarding, service lifecycle, packages, and the derived editable mind map.

Demo:

```
$ synkty-gui --smoke-test --obsidian-fixture tests/fixtures/messy-vault
UI_SMOKE ok note_created=true unchanged_bytes_preserved=true map_updated=true conflict_visible=true trash_restore=true author_badge=verified synced_cli_peer=true obsidian_reopen=pass keyboard_only=pass
```

Exit criteria:

- A clean Linux machine installs, completes backup-first onboarding, edits simultaneously with Obsidian, syncs with a CLI-only peer, resolves a conflict, restores a deletion, and restarts without loss.
- The map is generated from headings and basic wiki-links. Editing a node changes only its corresponding Markdown heading or link span; frontmatter, unknown syntax, `.canvas`, and other bytes remain unchanged.
- Broken chains, forks, unsupported paths, relay state, and transfer failures are visible. No automatic history repair or hidden conflict resolution exists.
- Every mutation and recovery operation has a stable CLI/JSON equivalent. The GUI does not obtain a broader authority bypass around the daemon.
- Install, start, stop, restart, upgrade, safe refusal, data-preserving uninstall, backup, and recovery all pass. Keyboard-only and screen-reader labels cover onboarding, conflict, and restore flows.
- No open P0/P1 defects remain and the full supported feature freeze takes effect at this gate.

First new user ability: perform the complete daily notes, map, sync, conflict, agent-attribution, and recovery loop from a desktop application while Obsidian remains usable on the same vault.

Explicitly absent: mobile, supported Windows/macOS installers, hand-placed boards, Canvas editing, plugin or workspace sync, live cursors, CRDTs, auto-update, accounts, and hosted control plane.

### 1.0.0 Arriving — release candidate and publication

Dates: RC work Mon 2027-05-10 through Sun 2027-05-16; defended buffer Mon 2027-05-17 through Sun 2027-05-30; final verification Mon 2027-05-31; publication Tue 2027-06-01.

Scope: Fix only release-blocking defects, repeat the complete verification matrix, publish the signed Linux artifacts and corresponding source, and ship no new feature.

Demo:

```
$ ./tools/release-verify.sh dist/1.0.0-rc.1
RELEASE_GATES ok requirements=184/184 restore=pass crash=pass enospc=pass obsidian=pass mixed_version=pass rollback=pass vectors=pass spec_drift=none signatures=pass sbom=pass p0=0 p1=0
```

Exit criteria: the common and release-specific gates in section 6 all pass against a clean checkout and clean machine, the two buffer weeks remain otherwise unused, and the final artifact verification reproduces the accepted candidate except for documented tag/version metadata. Publication uses immutable tags and a signed manifest.

First new user ability: download and verify a documented, recoverable Linux 1.0 release with explicit supported limits and upgrade/rollback instructions.

Explicitly absent: every item excluded above remains absent. Buffer time may not be spent adding them.

## 3. WEEK-BY-WEEK CALENDAR

The founder normally allocates 20 hours as approximately four hours of decisions and specification, eight of review and integration, five of adversarial verification on real systems, and three of documentation and release work. Agents do not merge their own work. A failed gate stops dependent implementation; agents continue only independent tests, fixtures, documentation, or defect isolation, and the founder applies section 8 when required.

| Week | Week start | Phase | Founder focus | Agents build in parallel | End-of-week gate |
|---|---|---|---|---|---|
| W1 | Mon 2026-11-23 | 0.1 Welcoming | Freeze all ten contract decisions; assign every MUST a test and owner; approve ADR and format layout. | Rewrite normative docs; rename workspace to `synkty`; pin toolchain and lockfile; build CI, DCO, license, and requirement-matrix scaffolding. | No unresolved contract fork; exact schemas and independent-verifier plan committed. |
| W2 | Mon 2026-11-30 | 0.1 Welcoming | Review identity, membership, wrapping, recovery, and pairing line by line; exercise recovery material. | Implement identity/pairing; independent decoder; strict limits, fuzz and malformed vectors. | All 0.1 exits pass; tag `0.1.0`; downstream specs have no identity ambiguity. |
| W3 | Mon 2026-12-07 | 0.2 Keeping | Approve transaction and recovery state machine; review fsync and cursor ordering. | Implement WAL, atomic apply, CAS, checkpoints; build crash/fsync-failure harness and JSON status schemas. | Every injected stop before and after each persistence boundary reconciles idempotently. |
| W4 | Mon 2026-12-14 | 0.2 Keeping | Review scanner, path policy, watcher reconciliation, history and trash behavior. | Implement scanner/watcher/save coalescing, versions, tombstones, external-edit and filesystem fixtures. | External edit and restart matrix has zero file/log divergence or suppressed failures. |
| W5 | Mon 2026-12-21 | 0.2 Keeping — HOLIDAY, Christmas week | Limit work to decision review and inspection of automated recovery evidence; no new design. | Run backup/export/restore automation, corrupt-CAS repair tests, ENOSPC/read-only fault campaigns, and documentation. | Automated export restores to a clean directory with identical content and valid history. |
| W6 | Mon 2026-12-28 | 0.2 Keeping — HOLIDAY, New Year week | Review soak results and recovery runbooks; avoid discretionary UI or network work. | Run daemon locking, stale-state, long replay, disk-pressure and storage-accounting soaks; independent log verification. | Multi-day fault soak has no unexplained mismatch, unbounded queue, or silent skipped file. |
| W7 | Mon 2027-01-04 | 0.2 Keeping | Perform clean-machine backup/restore and safe-mode acceptance; close storage specification. | Fix gate defects; package Linux CLI; generate evidence and schema documentation. | `0.2.0` passes every local safety gate and is tagged. |
| W8 | Mon 2027-01-11 | 0.3 Joining | Freeze manifest, capability, key-epoch and sync-state specs; review transport trust anchors. | Write independent sync vectors and disorder harness; implement handshake and manifest skeleton; draft GUI flows without core duplication. | A second implementation decodes manifests and rejects wrong vault, peer, epoch, and capability cases. |
| W9 | Mon 2027-01-18 | 0.3 Joining | Review direct-sync apply path and encryption boundary. | Implement pinned QUIC/TLS direct sync, reconciliation, negative-peer tests, and wire-capture assertions. | Two complete vaults converge under duplicate, delayed and reversed delivery. |
| W10 | Mon 2027-01-25 | 0.3 Joining | Review transfer bitmap, receive authorization, resource budgets and disk-full behavior. | Implement streaming verified blocks, idempotent resume, hidden temporaries, stale cleanup and explicit file receive. | Killed transfers resume correctly; no partial final file; 8 GiB resource envelope passes. |
| W11 | Mon 2027-02-01 | 0.3 Joining | Freeze deterministic outcomes for every mutation pair; inspect conflict evidence. | Implement conflict artifacts and resolution operations; property-test all edit/delete/rename/type/case combinations. | At least 10,000 generated schedules converge to identical files and conflict names. |
| W12 | Mon 2027-02-08 | 0.3 Joining | Review Obsidian preservation, migration refusal, links, attachments and unsupported-name reporting. | Expand sanitized real-vault fixtures, provider detection, link-map parsing and byte-preservation tests. | Messy fixture inventory is complete; no normalization, skipped file, or provider conflict is silent. |
| W13 | Mon 2027-02-15 | 0.3 Joining | Run real Obsidian, sleep/wake, two-machine, 1 GiB interruption and 72-hour partition drills. | Fix convergence and watcher defects; publish compatibility and resource evidence; keep Windows/macOS core CI experimental. | `0.3.0` passes direct-sync, real-Obsidian and recovery gates and is tagged. |
| W14 | Mon 2027-02-22 | 0.4 Carrying | Freeze relay identity, enrollment, frame, metadata, retention and counter specifications. | Build independent relay vectors, relay skeleton, config examples, abuse and capture harnesses. | Trust and forwarding rules reject nonmembers and generic tunneling before payload forwarding. |
| W15 | Mon 2027-03-01 | 0.4 Carrying | Review ciphertext boundary and reconnect accounting. | Implement forwarding, rate/volume limits, signed quota response, per-IP/global backpressure and pcap tests. | Forced relay converges; captures contain no content/path; reconnect counters reconcile exactly. |
| W16 | Mon 2027-03-08 | 0.4 Carrying | Run two-network and relay-outage drills on real systems; approve disclosure and operator guide. | Soak reconnect, overload, direct fallback and relay compromise cases; package relay and service example. | `0.4.0` passes relay, abuse, metadata and fallback gates and is tagged. |
| W17 | Mon 2027-03-15 | 0.5 Tending | Freeze grant-history/admission cutoffs, MCP tool contracts and quota defaults. | Implement grant vectors, independent policy checker, MCP schema stubs and negative authorization corpus. | Historical validity and new-admission decisions agree across two implementations. |
| W18 | Mon 2027-03-22 | 0.5 Tending | Review canonicalization at use and commit; inspect every read/export scope. | Implement agent keys and daemon enforcement; race, symlink, TOCTOU, wrong-vault, expiry and revocation tests. | No negative authorization case commits or discloses out-of-scope data. |
| W19 | Mon 2027-03-29 | 0.5 Tending | Exercise concurrent human/agent update semantics and denial UX. | Implement stdio MCP, dry-run, preconditions, idempotency, quotas, cancellation and mock agent clients. | Valid agent flow succeeds; stale, duplicated, excessive and revoked work fails without corruption. |
| W20 | Mon 2027-04-05 | 0.5 Tending | Verify renewal, rotation, recovery, checkpoints and proof completeness offline. | Implement JSONL export, single-file proofs, owner renewal/rotation, independent proof tooling and docs. | `0.5.0` passes portable proof, revocation and live-cancellation gates and is tagged. |
| W21 | Mon 2027-04-12 | 0.6 Gathering | Integrate GUI with authorized core; review onboarding and accessibility acceptance flows. | Build vault browser, Markdown exact-span editor, history/author views and component tests; CLI/JSON parity checks. | Clean Linux UI creates and edits a note without broad daemon bypass or byte drift. |
| W22 | Mon 2027-04-19 | 0.6 Gathering | Review derived-map semantics, conflict and recovery UX and warning language. | Build map projection/edit actions, conflict/trash/restore screens, transfer status and accessibility labels. | Map edits preserve fixture bytes; conflicts, forks and deletions are visible and recoverable keyboard-only. |
| W23 | Mon 2027-04-26 | 0.6 Gathering | Review packages, daemon handoff, migration backup and data-preserving uninstall. | Build AppImage/deb/tarball, service integration, signed manifest/SBOM tooling and clean-VM install tests. | Install, upgrade, safe refusal, rollback, uninstall and reinstall preserve data and identities. |
| W24 | Mon 2027-05-03 | 0.6 Gathering | Run complete human+Obsidian+agent+sync+restore acceptance and final scope freeze. | Fix only acceptance defects; freeze docs and test matrix; prepare RC automation and draft notes. | `0.6.0` feature gate passes and is tagged; no open P0/P1 remains. |
| W25 | Mon 2027-05-10 | 1.0 Arriving — RC | Select RC only on evidence; review all release claims and recovery/upgrade results. | Run full locked build, clean-machine, fault, mixed-version, 90-day-offline, migration, rollback and security matrix. | `1.0.0-rc.1` qualifies, or the release gate remains closed; no feature work enters. |
| W26 | Mon 2027-05-17 | 1.0 Arriving — DEFENDED BUFFER 1 | Address only reproduced release blockers and failed drills. | Isolate/fix P0/P1 issues and rerun affected plus downstream matrices. | Accepted RC restored to all-green; otherwise use remaining buffer and make no date claim based on hope. |
| W27 | Mon 2027-05-24 | 1.0 Arriving — DEFENDED BUFFER 2 | Final go/no-go, signing-key and withdrawal drill, notes and corresponding-source review. | Rebuild evidence bundles, verify artifacts and documentation; make no optional improvement. | Final exact release checklist passes; unresolved blocker means do not publish. |
| W28 | Mon 2027-05-31 | 1.0 Arriving — final two days | Mon: reproduce and inspect final artifacts and hashes. Tue: sign, tag and publish immutable release. | Generate final checksums, SBOM, signatures, source links and publication validation. | Tue 2027-06-01: published artifact downloads, verifies and installs from a clean machine. |

W5 and W6 are deliberately review-light because they are holiday weeks; they do not contain new architectural decisions. If the founder is unavailable rather than merely reducing load, the lost gates consume buffer or trigger cuts. W26 and W27 are reserved exclusively for release-blocking defects and failed restore, security, upgrade, or rollback drills.

### Accelerated variant: release Tue 2027-05-04

This path requires at least 30 focused founder hours each week from Mon 2026-12-07, or a second human by that date who owns at least 15 hours per week of review, integration, hardware testing, and release evidence. Additional typing alone does not activate this path. The extra capacity goes to parallel review and earlier hardware verification, not additional scope. M0 and M1 remain unchanged because formats, local recovery, and the holiday calendar are not compressed.

The direct-sync phase loses one week, relay and agents each lose one, and desktop loses one. RC and both defended buffer weeks remain intact. This gives 20 feature-build weeks, one RC week, and two buffer weeks.

| Release | Standard release week | Accelerated release week | Movement |
|---|---|---|---|
| 0.1.0 Welcoming | W2, ends Sun 2026-12-06 | W2, ends Sun 2026-12-06 | None |
| 0.2.0 Keeping | W7, ends Sun 2027-01-10 | W7, ends Sun 2027-01-10 | None |
| 0.3.0 Joining | W13, ends Sun 2027-02-21 | W12, ends Sun 2027-02-14 | One week earlier |
| 0.4.0 Carrying | W16, ends Sun 2027-03-14 | W14, ends Sun 2027-02-28 | Two weeks earlier |
| 0.5.0 Tending | W20, ends Sun 2027-04-11 | W17, ends Sun 2027-03-21 | Three weeks earlier |
| 0.6.0 Gathering | W24, ends Sun 2027-05-09 | W20, ends Sun 2027-04-11 | Four weeks earlier |
| 1.0.0 Arriving | Tue 2027-06-01 | Tue 2027-05-04 | Four weeks earlier |

Accelerated RC work is W21, Mon 2027-04-12 through Sun 2027-04-18. Defended buffers are W22, Mon 2027-04-19 through Sun 2027-04-25, and W23, Mon 2027-04-26 through Sun 2027-05-02. Final verification is Mon 2027-05-03 and publication is Tue 2027-05-04. Any missed accelerated gate returns that train and all later dates to the standard schedule; the buffer is not consumed early to preserve the acceleration claim.

## 4. THE V1 CONTRACT

### 4.1 Scope of 1.0

1.0 supports one owner principal, multiple owner-controlled devices, complete Markdown-and-attachment vaults, explicit whole-file receive directories, direct Linux-to-Linux sync, a self-hosted relay, local scoped MCP agents, recoverable history and deletion, and a minimal Linux GUI with a derived map. Whole-file senders and receivers are authenticated vault members; the receiver explicitly selects and authorizes the destination. The tested envelope is 100,000 current files, 100 GiB current content, and an 8 GiB single file, with full-history storage reported separately. Windows/macOS are CI experiments, not support claims. Multi-human teams, mobile, hosted services, automatic NAT traversal, plugin/workspace sync, Canvas editing, selective sync, placeholders, semantic auto-merge, pruning, auto-update, payments, wallet assets, chain writes, and billing are later or cut. The README milestone and platform implications are superseded by this scope and the six named trains; no milestone table may promise three supported desktops, mobile, hosted WAN service, or features not listed here.

### 4.2 Canonical path and file model

A synchronized object is a regular file or directory. Paths are vault-relative UTF-8 using `/`, with empty, absolute, drive, UNC, `.` and `..` components rejected. Signed paths are NFC; original case and platform-returned Unicode spelling are preserved on disk and synkty never renames merely to normalize. Create and manifest comparison uses a documented NFC plus Unicode default case-fold key and applies portable Windows reserved-name, trailing-space/dot, colon/ADS, backslash, and control-character rules on every peer so later platform support does not create overwrite hazards. Components are at most 255 UTF-8 bytes and logical paths at most 4,096 bytes. Non-UTF-8 or unsupported names are skipped with an exported inventory and never abort the vault scan. Symlinks, junctions and special files are never followed or written; hard links synchronize as independent regular files. Content, executable-bit policy as specified in the manifest, and size are synchronized; mtime, ACLs, xattrs, resource forks and ownership are not fidelity claims. New case/type collisions become deterministic unresolved artifacts rather than overwrites; existing unsupported branches block only those branches and require explicit user resolution. The README phrase “a vault is a folder” remains true only with this visible unsupported-file policy; it must not imply every POSIX object is supported.

### 4.3 Identity, membership, ownership and recovery

Pairing authenticates a device key and nothing more. Each `DeviceRecord` version 1 contains an Ed25519 identity key, a separately rotatable X25519 encryption public key, a key epoch, display name, and timestamps, all covered by the specified signed envelope. A vault genesis record names one owner principal, its initial owner devices, member devices, and an offline recovery public key; `vault_id` commits to that genesis. Signed membership and role records admit devices, and only currently authorized owner devices may issue membership, grant, rotation, or revocation policy. The vault data key is a random 256-bit symmetric key, wrapped per member device and to the recovery encryption key using X25519 plus domain-separated BLAKE3 key derivation and XChaCha20-Poly1305, with explicit key and wrap epochs. Old wraps are retained only as needed for authorized catch-up and historical verification; compromised old content is not promised retroactive confidentiality. Vault creation generates a printable offline recovery kit and requires a tested restore of owner authority. Device reset or restored cloned state creates a new device identity; copied active identities are detected as equivocation and quarantined. Losing all owner devices without the recovery kit requires an explicit export-and-reinitialize-as-a-new-vault ceremony, never silent privilege inheritance. The README’s “trust comes only from pairing” text is wrong when read as vault authorization and is replaced by: “Pairing proves possession of a device key. Vault membership, ownership, grants, and recovery are separate signed records.”

### 4.4 Permanent names and signed bytes

The repository, CLI, crate prefix, config directory, and immutable protocol identifiers use `synkty` through 1.0; every active `fald` occurrence is renamed in W1. A later display-brand change does not rewrite protocol literals, existing config automatically, or signed history. The permanent domain strings include `synkty/device-id/v1`, `synkty/device-id-check/v1`, `synkty/record/v1`, `synkty/entry/v1`, `synkty/chain/v1`, and `synkty/leaf/v1`; they are historical compatibility identifiers, not licensed branding. A device ID is ten raw bytes decoded from 16 Crockford symbols plus four checksum symbols, displayed as five groups of four, never 16 bytes or 56 symbols. Every signed object uses the single specified `Signed<T>` postcard envelope with version, kind, suite, canonical payload, signer identifier, and signature, with exact field layout and size limits in the format spec. Peers verify transmitted canonical bytes without re-encoding. JSON is never signed. Maps and floats are absent; `seen` is a strictly sorted vector of `(device_id, key_epoch, seq)` and duplicates, unsorted input, noncanonical NFC, trailing bytes, over-limit fields, and unknown versions or suites are rejected. One grant and revocation payload schema is used in log replication and policy gossip. Cross-implementation valid and invalid vectors are frozen before peer code. The README layout and command examples using `fald-*` and `fald` are wrong and are replaced wholesale by `synkty-*` crates and `synkty` commands.

### 4.5 Obsidian compatibility and the map

Compatibility means an existing Obsidian vault can be opened and edited concurrently without import, note-format conversion, loss of supported Markdown information, or synkty ownership of `.obsidian`. Notes, attachments, existing `.canvas`, `.base`, templates, unknown Markdown/YAML, BOM, line endings, aliases, tags, block IDs, links and embeds round-trip byte-for-byte unless the user edits that exact span. Link parsing is for indexing and the map, not whole-document reserialization. Tags in code blocks are not tags, and a move without safe link rewriting is labeled potentially link-breaking. `.obsidian` is entirely per-device in 1.0: no workspace, cache, settings, theme, snippet, plugin executable or plugin state is synchronized or deleted. Internal logs, databases, keys, CAS and temporaries live outside the vault. The v1 map has one automatic derived view built from headings and basic wiki-links; map edits update only the corresponding Markdown span. Existing `.canvas` files sync as opaque user files and Obsidian can continue editing them. The README wedge promising one shared `.canvas` with two views is wrong and is replaced by: “The map is derived from Markdown headings and wiki-links, not stored as a second document. Existing `.canvas` files are preserved but not edited by synkty in v1.” Before first write, onboarding requires a verified backup, read-only inventory, best-effort third-party-provider detection, and explicit exclusive-sync confirmation. Concurrent use of another sync engine is unsupported.

### 4.6 Data safety and conflict guarantees

The daemon uses the complete WAL sequence stated in 0.2, with same-filesystem temporary files, explicit file and parent-directory durability, cursor durability, startup reconciliation, and idempotent replay. It never overwrites unexpected working-tree corruption; it quarantines and offers repair from verified CAS, peer, or backup. Reservation and streaming prevent ENOSPC from touching the original. Every accepted content version is retained in BLAKE3-addressed storage, and signed tombstones feed user-visible versions and trash. Full logs and history are retained by default; explicit vacuum may remove only unreferenced historical blobs and trash older than 30 days after a verified external backup, and 1.0 never prunes the signed log. Concurrent or incompatible mutations produce deterministic conflict artifacts named from the immutable entry ID and preserve both byte streams and operation histories. A deterministic primary is selected only so peers converge; it is not called a merge and never discards the loser. Edit/delete, rename/rename, type replacement, binary and collision cases follow the same preservation rule, and resolution is a new signed operation. Exportable backups include manifests, required history, policy, and wrapped keys; a release requires a clean-directory restore drill. The README promise “three-way merge, one file, no conflict twin” is wrong and is replaced by: “Concurrent edits converge deterministically and preserve both versions in a named conflict artifact. Resolution is explicit and logged; v1 does not perform automatic semantic merging.”

### 4.7 Log validity and revocation

Every chain is namespaced by `(vault_id, device_id, key_epoch)`, and the signed body includes the vault domain. Sequence is contiguous per chain, `prev` covers the previous entry including its signature, `seen` is canonical, and wall time is advisory. Receipt verifies signature, path, key epoch, grant and expected predecessor; missing predecessors are buffered within documented limits, while permanent gaps, bad signatures and duplicate `(device, epoch, seq)` with different bytes are quarantined. Signed checkpoints occur every 1,024 entries with a Merkle root, and segments are not pruned in 1.0. A fork marks the author suspect and blocks automatic application; evidence is retained. Revocation is monotonic for admission and carries target, vault, key epoch, and an explicit sequence cutoff recorded from the owner’s known authority state. After local revocation, new target work and active jobs stop immediately, cached capabilities are invalid, and no post-cutoff entry is accepted even if its author omits revocation from `seen`. Newly arriving old material may be retained for evidence but is not automatically applied. Historical proof asks whether an entry was signed by then-valid authority and lies before applicable causal and sequence cutoffs, without using today’s clock or deleting accepted history. Grant expiry governs live admission using the enforcing device’s skew-bounded and rollback-detected clock. Revocation gossip cannot guarantee that an uninformed offline peer refuses a write; the published promise is local immediate enforcement and convergence of deny evidence, not global instantaneous revocation.

### 4.8 Agent interface

Agents use local stdio MCP served by the single-instance daemon; the MCP service is a thin adapter over the same authorized core and has no ambient device-key access. Human owner CLI/JSON and MCP schemas, exit codes, errors, capabilities, and deprecations are versioned independently. Every operation, including reads, searches, log export and render/index queries, carries and rechecks the agent grant. Agents generate their own Ed25519 keys; grants identify vault, agent key, segment-canonical prefix, ops, issue/expiry, unique ID and resource limits. Default lifetime is 24 hours and maximum seven days. Writes require expected revision/content hash, support idempotency keys and dry-run, and serialize at commit; append has an explicit atomic operation. Canonicalization and authority are checked on admission and again at commit, with no symlink or rename escape. Operation rate, bytes, individual file size, concurrency, queued work and execution time have finite defaults and visible denials. Revocation stops new work, invalidates cached capabilities and cancels running jobs; owner-only renewal and key rotation are logged. A verified badge means valid key and authority chain only, never truthful content or human intent. Agents remain first-class at the 0.2 local JSON stage for owner automation, but unscoped third-party agent access is not claimed before 0.5.

### 4.9 Connectivity without paid infrastructure

Direct sync uses QUIC with TLS 1.3 and RFC 7250 raw Ed25519 public keys pinned to authenticated device records; the documented stable self-signed-SPKI fallback is permitted if rustls cannot express a needed raw-key case. Noise is removed. The rustls hybrid key-exchange default and a suite byte are retained, but no post-quantum signature or custom ML-KEM work is claimed. Application vault payloads and paths are end-to-end encrypted separately under the vault data-key epoch, so no relay terminates the content trust boundary. Version 1 accepts configured IP/host-and-port endpoints or user-configured port forwarding; it does not promise LAN discovery, NAT hole punching, or two-home connectivity with no configuration. The optional relay is user-operated and has a distinct pinned Ed25519 relay identity used to authenticate its endpoint and quota responses; “no keys” always means no vault keys. It forwards only authenticated sync frames between authorized member pairs, holds no vault key or general tunnel capability, and discloses device IDs, IPs, timing, sizes, file counts, counter use, and 30-day default operational-log retention. Reconnect-safe counters and configurable per-device, per-IP and global limits exist without billing. No project public relay, bought certificate, new host, domain, paid egress, or always-on project service is required. The README’s transport and unqualified two-home/no-port-forwarding implications are replaced by this exact promise.

### 4.10 Licensing, contribution and release rules

Code, including the relay, MCP, daemon, GUI and any future control plane derived from this repository, is `AGPL-3.0-or-later`; manifests, LICENSE, notices and UI agree. A paid managed service may be operated later, but it is not a proprietary closed-source exception. Specifications and documentation are CC BY 4.0 with a real `LICENSE-docs`, NOTICE, copyright and corresponding-source offer. The name and logo are outside those licenses. Contributions use inbound-equals-outbound DCO sign-offs, not a CLA. Substantive AI assistance is recorded in the PR, and copied proprietary implementation code is prohibited. `main` is protected, PR-only, no force-push; agents cannot self-merge, and the founder or designated maintainer is accountable for line-by-line review. Crypto, formats, storage, migration, and authorization changes require independent implementation or adversarial review and executable vectors. Releases use a pinned toolchain, committed `Cargo.lock`, locked builds, immutable protected tags, SHA-256 checksums, offline-held minisign release keys with a replacement drill, CycloneDX SBOM, reproducible-build instructions and signed manifests. Updates are manual with pre-migration backup and safe refusal; no auto-updater ships in 1.0. No “independently security audited” statement is made without an actual named external audit; the required 1.0 assurance is the independent decoder/verifier, separate adversarial agent review, founder review, and public security-response process.

## 5. WORK BREAKDOWN FOR AGENTS

General rule: an agent may implement only against a merged specification with acceptance tests assigned. Up to three independent streams run at once: format/core implementation, an independent verifier or adversarial test harness, and fixtures/documentation/packaging. The critical path is contract and identity formats -> durable local state -> direct convergence and transfer -> relay and authorized agent operation -> complete desktop loop -> RC. Noncritical prototypes may start early but cannot bypass integration gates or fork mutation logic.

### 0.1 Welcoming

- Agent tasks without further founder input: rename crates/config commands; pin CI; write postcard schemas from adopted decisions; implement pairing and storage; generate valid/invalid vectors; independently implement a decoder in a separate crate; fuzz length, UTF-8, NFC, path and clock decoding; prepare DCO/license/NOTICE/CONTRIBUTING and test-matrix automation. The independent decoder, fuzz harness, documentation, and CI stream are parallel.
- Founder decisions required first: final envelope field order and limits; owner/genesis record shape; recovery-kit encoding and storage ceremony; key-wrap transcript and epochs; revocation cutoff semantics; exact domain literals. These are critical-path and cannot be delegated.
- Human-only work: generate and physically secure recovery and release test keys; verify fingerprint comparison on two terminals; inspect restored owner authority using only the offline kit; review all cryptography and membership code. No hardware security or audited-crypto claim is accepted from agent output.

### 0.2 Keeping

- Agent tasks without further founder input: implement the approved transaction state machine, CAS, checkpoints, snapshot/version/trash views, daemon locking, watcher plus reconciliation, JSON status and backup format; generate crash, ENOSPC, fsync failure, corruption, read-only and replay tests; collect licensed sanitized fixtures; build independent log and restore verifiers. Core, fault harness, and fixture/docs work are parallel after the layout freezes.
- Founder decisions required first: on-disk directory layout; retention/vacuum defaults; block and manifest limits; save-burst boundary; daemon lock and safe-mode behavior; backup compatibility and recovery precedence. A late on-disk-layout change blocks everything downstream.
- Human-only work: abrupt power-loss and sleep/wake tests on a physical Linux machine; real full-disk and read-only-media drills; inspect restore outside the development checkout; verify uninstall preserves notes and identity. Passed process-kill tests alone do not close the phase.
- Critical path: WAL and durable apply -> external-edit reconciliation -> backup/restore. Soak duration, metrics and documentation parallelize; the first network task requiring real vault mutation waits for all three.

### 0.3 Joining

- Agent tasks without further founder input: write sync vectors and disorder generators; implement TLS/QUIC transport, manifest exchange, resume state, conflict rules, provider detection, attachment transfer, fixtures and resource instrumentation; run weekly experimental Windows/macOS core CI. Transport, conflict generator, and Obsidian fixture streams are parallel once signed formats freeze.
- Founder decisions required first: negotiation and mixed-version policy; manifest and block schemas; deterministic winner and conflict naming for each mutation pair; receive-directory authorization; supported resource envelope; third-party-provider refusal UX; exact path collision behavior. Any ambiguity here blocks convergence and grant enforcement later.
- Human-only work: use real Obsidian on at least two physical Linux installations with messy vaults; disable other providers and verify backups; exercise sleep, atomic saves, rename exchange, large attachments, link behavior and manual conflict resolution; capture two-device failure evidence. Experimental non-Linux tests require those physical OSes before their claims change.
- Critical path: direct authenticated sync -> deterministic apply/conflicts -> verified resume -> real-Obsidian acceptance. Fixture authoring and UI wireframes are off the critical path until their integration weeks.

### 0.4 Carrying

- Agent tasks without further founder input: implement relay state machine and separate identity; counters, quotas, backpressure, signed status, config and service examples; capture/assert privacy properties; generate reconnect, replay, tamper, generic-tunnel, concurrency and overload tests. Relay core, adversarial network suite, and operator documentation parallelize.
- Founder decisions required first: relay enrollment/pinning UX; exact frame classification and accounting units; metadata retention and disclosure; default self-host limits; direct-fallback behavior. The decision not to run a public relay is already final and needs no revisit.
- Human-only work: run a relay on an existing user-controlled reachable host; connect from two real networks; force relay and inspect actual packet capture and stored logs; stop the relay during sync and confirm direct recovery. No new paid relay host is provisioned.
- Critical path: endpoint-authenticated E2E forwarding -> correct reconnect accounting -> real-network drill. Metering polish is parallel and is the first component eligible for a cut.

### 0.5 Tending

- Agent tasks without further founder input: implement grant/key storage, MCP schemas and stdio adapter, precondition and idempotency handling, quota counters, renewal/rotation, JSONL export and proofs; build a separate policy evaluator and adversarial clients; generate race, path, expiry and revocation cases. MCP adapter, independent policy/proof tooling, and negative tests are parallel after the policy format is final.
- Founder decisions required first: versioned MCP tool names and payload semantics; default finite quotas; append behavior; grant renewal overlap; proof contents and redaction; exact cutoff/admission distinction. These choices are required before agent implementation, not delegated to the MCP library.
- Human-only work: connect at least one real MCP-capable agent; attempt out-of-scope reads and writes; revoke during queued and active work; lose and rotate an agent key; inspect user-facing authority and denial displays; independently verify a proof on a clean machine without private keys or network.
- Critical path: admission/commit authorization -> concurrent mutation semantics -> revocation cancellation. Export, proof UX and client examples parallelize but do not substitute for enforcement.

### 0.6 Gathering

- Agent tasks without further founder input: build Tauri views exclusively against core APIs; exact-span editor and map parser; accessible components; conflict/trash/restore screens; package and service scripts; SBOM/checksum/signature tooling; clean-VM UI automation and CLI/JSON parity tests. UI components, map fixtures, and packaging can run in three streams after core API schemas freeze.
- Founder decisions required first: supported desktop workflow; first-run backup/refusal copy; map edit operations; accessibility acceptance level; package set and service defaults; display-brand treatment; final compatibility/security wording. The founder also rejects scope additions rather than silently accepting them in PRs.
- Human-only work: clean Linux install and uninstall; simultaneous real Obsidian use; keyboard-only and basic screen-reader onboarding/conflict/restore; service reboot and upgrade; inspection on a small display; actual external-user migration observation with at least three non-synthetic vaults by the end of W24. No automation substitutes for Obsidian or accessibility acceptance.
- Critical path: authorized core integration -> recoverable daily workflow -> onboarding and package/service acceptance. Visual polish and extra map layouts are noncritical and cuttable.

### 1.0 Arriving

- Agent tasks without further founder input: execute locked CI, generate evidence matrix and artifacts, build SBOMs and checksums, repeat automated upgrade/rollback/fault/mixed-version/fixture suites, draft release notes strictly from evidence, and test download verification. Independent reruns are parallel; no feature stream exists.
- Founder decisions required first: accept an RC; triage every blocker; authorize any post-RC change; approve final claims and publication. Cutting a requirement requires an explicit section-8 decision and revised product claim.
- Human-only work: clean-machine final install/restore/rollback; release key access and offline backup check; signing-key replacement/withdrawal drill; verify corresponding source and signatures on a separate machine; final go/no-go and publication. Artifact tags are never moved to hide a failed candidate.

## 6. RELEASE ENGINEERING

### Common gate for every tag

A release stops before tagging if any of the following is true: a test or clean-machine run demonstrates user-data loss, silent divergence, unauthorized read/write, or an unrecoverable state; backup/restore or a required recovery drill fails; current and conflict content hashes differ after convergence; any independent vector or decoder disagrees; a signed-byte or persistent-format diff lacks an ADR, version decision, migration, negative tests and updated vectors; a required test was not actually run; a P0 or P1 issue is open; an artifact, source, checksum, SBOM or signature cannot be verified; or release notes claim an unsupported feature or security property. Spec drift is detected by diffing canonical schemas, domain strings, golden bytes and generated requirement IDs, not by reviewer memory. The failed candidate is quarantined, the tag is not created or moved, and dependent feature merges stop until a regression test exists.

Every candidate is built from a clean protected-tag checkout using the pinned toolchain and `Cargo.lock`. Formatting, clippy, all workspace tests, fuzz smoke, dependency audit, license checks and locked builds are fresh. CLI/source builds run twice in clean environments and unexplained nonreproducibility blocks release. Test evidence includes requirement IDs, OS/kernel/filesystem, Obsidian version, fixture counts, random seeds, fault boundaries, resource maxima and a restore result. The release key is offline; CI receives only disposable build credentials and never the minisign private key.

Every release note contains version and codename; wire/protocol suite, persistent schema, CLI/JSON/MCP schema and minimum compatible peer versions; new user ability and explicit absences; migration, backup, downgrade/refusal and rollback instructions; supported platforms and numerical limits; privacy/security changes; known issues; corresponding source, SHA-256 sums, minisign verification command and key identity; SBOM; and linked gate evidence including the latest restore drill. Patch notes additionally identify regressions fixed and prove formats did not silently change.

Rollback never deletes a vault, identity, log, backup, or tag. A schema-compatible rollback stops the service, preserves config and data, and starts the prior binary. An incompatible prior binary opens only in safe read-only/export mode or refuses without mutation; recovery uses the pre-upgrade export in a new data directory. The supported migration is backup -> verify -> stop -> upgrade -> verify -> restart, with downgrade explicitly tested or safely refused.

| Release | Artifacts shipped | Release-specific verification before tag | Rollback story |
|---|---|---|---|
| 0.1.0 Welcoming | Source tarball/zip; static Linux x86_64 `synkty`; signed spec-and-vector snapshot; SHA-256SUMS; minisign manifest/signature; SBOM; reproduction instructions. | Two terminal pairings, offline recovery drill, strict malformed corpus, independent decoder, frozen vectors, key/log hygiene, restart persistence. | Remove binary while preserving config; reinstall 0.1 source/binary. Pre-sync formats have no vault migration; an invalid candidate is simply withdrawn before peers adopt it. |
| 0.2.0 Keeping | Updated Linux CLI; storage/log/backup specs; JSON schemas; fault and restore evidence bundle; signed checksums/SBOM/source. | Complete crash and ENOSPC matrix, clean-directory export restore, external-edit reconciliation, long replay, CAS verification, daemon lock and safe-mode test. | Stop daemon and preserve data. Prior binary runs only if schema permits; otherwise safe export and restore the verified 0.1-to-0.2 pre-migration backup into a fresh directory. |
| 0.3.0 Joining | Linux CLI/daemon; sync/transfer/conflict specs and vectors; explicit receive support; Obsidian fixture report and resource report; same signed release bundle. Experimental Windows/macOS CI logs are not supported artifacts. | Disorder/convergence seeds, 72-hour partition, killed 1 GiB and 8 GiB envelope, two physical peers, real Obsidian reopen, mixed 0.2/0.3 refusal or negotiation, restore-from-peer and restore-from-backup. | Stop sync on both peers; direct local data remains usable. Revert only within negotiated storage/protocol compatibility, otherwise export and restore pre-upgrade backup. Never solve rollback by deleting conflicts or logs. |
| 0.4.0 Carrying | Linux `synkty-relay` and relay-enabled client; pinned identity/config/service examples; privacy and counter specification; signed packages/source/checksums/SBOM. | Two-network forced-relay drill, packet/storage inspection, nonmember/tunnel rejection, reconnect accounting, overload, tamper and direct fallback. | Disable relay and revert to direct sync without vault migration. Remove relay package independently; client and relay versions can roll back separately. Relay operational logs expire by documented policy. |
| 0.5.0 Tending | Updated Linux client; MCP/versioned JSON schemas and error catalog; grant/proof specs; JSONL export and independent proof verifier; signed standard bundle. | Real MCP client flow, every scoped denial, races and TOCTOU, live cancellation, quota exhaustion, renewal/rotation, offline proof on clean machine, history-vs-admission cases. | Disable all agent grants and MCP on rollback. Unauthorized work cannot be “rolled back” by deleting history; restore affected content from versions/backup and issue new grants only after the fixed client is verified. Schema rules follow common safe refusal. |
| 0.6.0 Gathering | Linux CLI/daemon and `synkty-gui`; AppImage, deb and tarball; service units; desktop and map docs; install/upgrade/uninstall evidence; signed standard bundle. | Clean Linux full daily loop with real Obsidian and CLI peer, exact-span/map fixtures, keyboard-only conflict and restore, install/reboot/upgrade/rollback/uninstall, no open P0/P1. | GUI can be removed without removing CLI, notes, config or identity. Restore previous service unit and compatible binaries; incompatible storage follows pre-upgrade backup/safe refusal. Uninstall default preserves all user data. |
| 1.0.0 Arriving | Final accepted 0.6-scope artifact set as `1.0.0`; immutable source tag; signed release manifest and checksums; minisign public key and rotation procedure; SBOM; compatibility, security/privacy, backup/recovery and operator runbooks; complete evidence index. | Full common matrix plus 90/180-day offline fixture catch-up, previous-train mixed-version tests, all migration and rollback paths, clean final download/install, no P0/P1, no spec drift, signing-key replacement and emergency-withdrawal drill. | Manual previous release only under tested compatibility; otherwise prior version refuses new schema safely and user restores pre-upgrade export. After publication, a bad release is withdrawn through signed incident notice and last-known-good artifact links, never by rewriting or deleting the tag/history. |

An emergency withdrawal publishes affected versions and platforms, stops new downloads, preserves evidence, gives a backup-first recovery path, rotates signing keys if implicated, and requires a new version and full affected gate rerun. There is no auto-update channel to recall or repair remotely.

## 7. RISK REGISTER

Risks are ordered by expected damage to the launch date, including both probability and the amount of downstream work invalidated.

| Rank | Risk and phase where it bites | Early warning observable within one week | Mitigation |
|---|---|---|---|
| 1 | Founder review and integration capacity is overwhelmed by agent-generated volume; all phases. | More than two substantive PRs wait over three days, review/integration exceeds ten founder hours in a week, or green agent branches cannot be integrated into one demo. | Cap active streams at three, require small issue-linked PRs, stop new assignments when review queue exceeds two, reserve founder hours for verification, and invoke cuts instead of reviewing faster or expanding scope. |
| 2 | Signed format, membership, key-wrap or revocation semantics require redesign; 0.1, then 0.2-0.5. | Any golden byte changes after W2 without an explicit version decision, independent decoder differs, or one adversarial policy case has two valid interpretations. | Freeze exact schemas and vectors first, keep independent decoder and policy evaluator, reject incidental format diffs, use one-owner 1.0, and stop dependent work until an ADR and all downstream vectors agree. |
| 3 | WAL, fsync, cursor, CAS or restore behavior loses or strands local data; 0.2 and every later phase. | One injected boundary produces file/log mismatch, a restore hash differs, replay changes state twice, or ENOSPC touches the original file. | Implement the complete transaction state machine before sync, fault-inject every persistence boundary, retain full history, run real power/disk drills, and block all downstream merges on one reproducible mismatch. |
| 4 | Real Obsidian and platform filenames/watchers diverge from synthetic behavior; 0.2-0.3 and 0.6. | Weekly fixture round-trip changes one unedited byte, reconciliation finds an edit the watcher missed, unsupported-name inventory is incomplete, or Obsidian renders a partial attachment. | Preserve bytes except explicit spans, reconcile periodically with hashes, keep `.obsidian` per-device, inventory unsupported files, use messy licensed fixtures, and start two-installation real Obsidian tests no later than W13. |
| 5 | Deterministic convergence or conflict resolution fails across message orders and mutation types; 0.3. | Two random seeds yield different hashes or conflict names, a conflict count changes after replay, or edit/delete loses a recoverable blob. | Specify total deterministic outcomes before coding, property-test every mutation pair, quarantine equivocation, keep both contents and logs, and hold the phase gate through a 72-hour partitioned soak. |
| 6 | Large transfer and manifest memory/disk behavior forces storage redesign; 0.3, recurring under soak. | Transfer RSS exceeds 512 MiB excluding OS cache, temporary data is visible, resume trusts an unverified block, or storage grows without an itemized `status` explanation. | Stream fixed-size verified blocks, cap concurrency and manifest sizes, use hidden temporaries and final hash/atomic rename, publish full-history overhead, and cut only resume optimization before considering any safety change. |
| 7 | Agent sandbox, commit-time authority, quotas or revocation arrives too late and invalidates core APIs; 0.5 with redesign back to 0.2-0.3. | A single negative scoped-read, race or revocation case succeeds, commit does not recheck authority, or one granted agent can enqueue unbounded work. | Freeze the daemon authority interface in 0.2, build adversarial MCP and policy clients before UI integration, enforce finite defaults at every operation, and treat an authorization failure as a P1 merge stop. |
| 8 | Desktop shell duplicates core behavior or the daily recovery loop is not usable; 0.6. | By W21 the UI cannot complete one mutation solely through core APIs, by W22 keyboard-only conflict/restore fails, or a GUI action lacks CLI/JSON parity. | Keep the GUI thin, implement conflict/restore before visual polish, run clean-machine UI smoke weekly, remove built-in editing and then the GUI according to section 8 rather than moving core code into TypeScript. |
| 9 | Relay trust, reachability, accounting or metadata claims need rework; 0.4. | Forced relay fails on the first two-network attempt, one path/content string appears in captures/logs, reconnect changes totals, or a nonmember receives a frame. | Keep it self-hosted and manually configured, give it a separate pinned identity, capture actual traffic, separate relay and vault trust, disclose metadata, and cut the entire relay on Fri 2027-02-19 if direct sync is late. |
| 10 | Persistent migration, mixed-version compatibility or rollback is discovered only in RC; 0.3 onward, damage at 1.0. | One upgrade test lacks a pre-backup, old binary mutates an unknown schema, previous train cannot negotiate/refuse cleanly, or a rollback drill has no restored copy. | Version every persistent schema, carry safe refusal from 0.2, add previous-train tests at each release, rehearse signed withdrawal/key replacement before RC, and never equate manual update with safe update. |
| 11 | External messy-vault migration exposes unscoped user behavior late; 0.3 and 0.6. | The first observed vault requires an undocumented manual repair, another provider remains active, links break after a move, or a user cannot explain the restore/conflict result. | Require backup-first read-only inventory and exclusive-sync acknowledgment, observe at least three external vault migrations by W24, populate fixtures from observed legal/sanitized cases, and document unsupported workflows rather than improvising fixes. |
| 12 | Founder absence or loss of repository, recovery, or signing authority removes the only release operator; holidays and RC. | A weekly gate has no founder verdict, recovery kit/release-key backup cannot be located in a drill, or no other person can reproduce the source/artifact verification instructions. | Keep decisions and runbooks executable in the repo, maintain offline encrypted repository/key backups with no secrets in issues or agent contexts, rehearse recovery quarterly, onboard a second maintainer when available, and consume buffer or move scope rather than bypass the gate. |

## 8. WHAT I WOULD CUT IF JUNE SLIPS

Cuts are decided by the dates below even if the team hopes to recover later. A cut changes release notes and the compatibility/clients affected, but may not weaken verification, backup, restore, logging, conflict preservation, path authorization, or end-to-end confidentiality. Versions are not renumbered merely to hide a skipped feature; an omitted train is recorded in the release history.

| Rank | Cut and exact decision deadline | Trigger and retained minimum |
|---|---|---|
| 1 | Cut relay signed quota UI/client display and policy configurability beyond simple local counters, rate and concurrency limits. Decide Fri 2027-01-15. | If 0.2 consumed more than its five weeks or review queue exceeded two PRs for two weeks. Retain reconnect-safe byte counters, `synkty relay quota --json` local inspection, documented limits, and privacy tests. No billing or hosted status service enters. |
| 2 | Replace cross-restart bitmap resume for explicit non-vault file transfer with verified temporary cleanup and restart-from-zero; vault attachment resume remains. Decide Fri 2027-01-29. | If the W10 resume/resource gate is not passing or its complexity delays conflict work. Retain block verification, idempotent destination state, hidden temporary files, final hash and atomic rename. A killed 1 GiB explicit send may restart safely, and release notes must stop claiming every transfer resumes. |
| 3 | Drop the self-hosted relay from 1.0 entirely. Decide Fri 2027-02-19. | If 0.3 is more than one week late, any critical convergence gate is open, or relay design still has ambiguous trust/metadata semantics. Retain pinned direct endpoints and user-configured port forwarding. Skip 0.4 Carrying, move agents and desktop forward three weeks, mark relay “post-1.0,” and remove forced-relay and WAN claims. The two buffer weeks remain defended. |
| 4 | Cut single-file Merkle proof generation and its GUI display. Decide Fri 2027-03-19. | If 0.5 authorization/cancellation work is late or the independent proof implementation is not ready. Retain complete log verification, checkpoints, JSONL export, grant-chain verification and independent entry/range verification. Do not claim portable single-file proofs. |
| 5 | Cut the built-in Markdown text editor from Tauri. Decide Fri 2027-03-26. | If exact-span editing or the authorized core integration is not stable before desktop work, or it threatens W22. Retain vault browsing, derived map, history, conflict and restore UX; notes open in Obsidian or an external editor and synchronize through the reconciled watcher. CLI exact writes remain for agents. |
| 6 | Make the derived map read-only. Decide Fri 2027-04-02. | If map edit fixtures cannot guarantee byte preservation or map work delays recovery UX. Retain automatic headings/wiki-link projection, navigation to the source note, and all editing in Obsidian/external editor. Remove “editable map” from the 0.6 demo and product copy. |
| 7 | Reduce packaging to a verified tarball with CLI/GUI binaries and a documented install/service command; cut AppImage and deb. Decide Fri 2027-04-16. | If either package format fails clean install, upgrade, service handoff or data-preserving uninstall while the tarball passes. Retain signed manual downloads, checksums, SBOM, reproducible source, service lifecycle, upgrade backup and safe refusal. |
| 8 | Replace the Tauri shell with CLI workflows plus a generated local static HTML mind map and status/report view. Decide Fri 2027-04-23. | If the complete GUI daily/recovery loop cannot pass clean-machine smoke by this date. Retain Obsidian as the editor, the Rust daemon/CLI, a derived map opened in a browser, visible conflicts/trash/restore/status, MCP, direct sync and any retained relay. This is a Linux technical 1.0, not a desktop-GUI claim; no GUI mutation logic is reimplemented in JavaScript at the last minute. |

On Sun 2027-05-09 the retained scope freezes absolutely. After that date only optional artifacts can be dropped; feature code does not change except to fix a release blocker. The following are never cut to save the date: verified backup and restore, durable WAL apply, conflict preservation, retained recoverable deletion, strict signed decoding, vault/device authorization, causal history plus local revocation enforcement, scoped agent admission and commit checks, end-to-end content/path confidentiality, release signature verification, and safe refusal of incompatible persistent state.

If the noncuttable minimum still fails its gates after the two defended buffer weeks, the release date moves and the failure is reported. June is protected first by the cuts above; safety gates remain more important than either calendar.

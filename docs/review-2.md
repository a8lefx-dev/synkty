# Kimi planning pass

provenance: `moonshotai/Kimi-K3.1-Pro` over commandcode, one-shot, Sun 2026-11-22 11:11 PST
task: You are reviewing the design and plan for synkty, a Rust project, before coding starts. Below are all six documents that exist. Read them and find what is missi
usage: in 337,705 tok / out 25,197 tok = **$0.927**

---

1. GAP SWEEP

Priorities below are for a supported 1 June 2027 release. “MUST” means the release is unsafe or misleading without it.

Specification integrity

- No adopted, internally consistent product contract — MUST
  Failure: `plan-v1-kimi.md` is only a proposal, while the README contradicts it on Noise versus TLS, `.canvas` versus a derived map, three-way merging versus conflict copies, and milestone contents.
  Fix: Adopt one versioned v1 contract, declare normative-document precedence, and convert every deviation into an ADR and spec change.

- The protocol stops before the difficult protocols — MUST
  Failure: `protocol.md:140-150` leaves sync, relay, and attribution unspecified, so independent implementations cannot interoperate and reviewers cannot validate the security claims.
  Fix: Write normative manifest, sync-state, transfer, relay, membership, and `docs/log-format.md` specifications before their implementation milestones.

- Signed encoding is not actually frozen — MUST
  Failure: `fald/...` and `synkty/...` domain strings disagree, signed wrappers and signature fields are absent, `seen` is a map despite the no-maps rule, and several strings and collections are unbounded.
  Fix: Define one `Signed<T>` envelope, permanent domain strings, exact postcard schemas, sorted vector clocks, strict field limits, unknown-version handling, and cross-language test vectors.

Obsidian interoperability

- “Obsidian-compatible” has no testable meaning — MUST
  Failure: Users can reasonably expect plugins, settings, links, Canvas, attachments, and concurrent editing to work, while the implementation may only copy `.md` files.
  Fix: Publish the explicit compatibility contract in section 2 and test it against real Obsidian installations and real vault fixtures.

- `.obsidian` configuration and executable plugins have no policy — MUST
  Failure: Syncing workspaces causes cross-device UI fights; syncing plugins silently distributes executable JavaScript; excluding everything surprises users expecting settings sync.
  Fix: Keep all `.obsidian` state per-device in v1, never sync workspace state or plugin code, and document an optional settings-only allowlist as later work.

- Lossless Markdown editing is unspecified — MUST
  Failure: Generic YAML or Markdown serialization can destroy frontmatter types, comments, aliases, tags, block IDs, wiki-links, embeds, and unknown plugin fields.
  Fix: Preserve original bytes except for the exact edited span; build round-trip fixtures rather than promising lossless editing through a generic serializer.

- The map format contradicts itself — MUST
  Failure: The README promises a shared `.canvas` file while the adopted-looking plan prohibits a second map format, producing incompatible UI and sync implementations.
  Fix: Make the v1 mind map a derived projection of Markdown; defer bidirectional `.canvas` editing and preserve existing `.canvas` files as opaque files.

- Existing third-party sync is not addressed — MUST
  Failure: Running Syncthing, iCloud, Dropbox, or Obsidian Sync on the same vault can produce deletion loops, conflict storms, and partial-file propagation.
  Fix: Require migration to a non-synced location, take a backup, detect common providers, and refuse activation until the user explicitly confirms exclusive synchronization.

Data safety

- Sync is being designed without backup or content restoration — MUST
  Failure: The log stores hashes, not historical content, so replicated deletion, ransomware, or a bad agent write cannot be undone.
  Fix: Retain historical blobs in a content-addressed store, add snapshots, a user-visible trash, exportable backups, and a documented restore command with restore drills.

- “Atomic rename” is treated as durability — MUST
  Failure: A crash or power loss can leave a zero-length file, missing directory entry, or stale log cursor unless temp files, file data, and parent directories are synced correctly.
  Fix: Specify same-filesystem temp files, flush/atomic-replace/fsync-parent sequences per OS, and test actual crash points rather than rename success alone.

- Disk-full and quota behavior is absent — MUST
  Failure: ENOSPC during a write, log append, migration, or attachment receive can corrupt the vault or strand an unrecoverable half-state.
  Fix: Reserve space before mutation, stream to temporary files, fail without touching the original, clean stale transfers, and fault-test every persistence boundary.

- WAL recovery is only an ordering sentence — MUST
  Failure: Applying before cursor persistence, source-file races, or non-idempotent replay can diverge the working tree, log, and applied state.
  Fix: Define the complete transaction state machine, stable entry IDs, replay idempotency, cursor fsync, content snapshots, and startup reconciliation.

- Local corruption detection stops at network blocks — MUST
  Failure: Bit rot or an externally modified file can pass `log verify` while the vault no longer matches its authenticated history.
  Fix: Add working-tree/CAS verification, quarantine rather than overwrite unexpected corruption, and provide a repair-from-peer or restore-from-backup path.

- Deletion and trash semantics are absent — MUST
  Failure: One mistaken deletion can propagate everywhere with no recoverable tombstone or user-facing undo.
  Fix: Use signed tombstones with retention, a per-vault trash/version view, explicit permanent deletion, and edit-versus-delete conflict handling.

- Storage amplification has no budget — SHOULD
  Failure: Temporary files, CAS history, conflict copies, logs, and multi-gigabyte transfers can consume several times the visible vault size.
  Fix: Publish worst-case space requirements, expose usage, add safe cleanup commands, and defer provable log pruning until checkpoint semantics are mature.

Identity and key lifecycle

- Pairing, vault membership, and ownership are not a coherent authorization model — MUST
  Failure: A paired device may be mistaken for a vault member, and any device called “owner” may be able to issue grants or revocations without a verifiable owner list.
  Fix: Add signed vault membership and role records, an owner root or owner set, explicit membership removal, and separate pairing from vault admission.

- The vault-key design uses the wrong key type and cannot wrap to devices — MUST
  Failure: `crypto-and-log.md` calls the vault key “X25519,” while `DeviceRecord` contains only an Ed25519 key, leaving no specified payload-encryption or wrapping scheme.
  Fix: Use a random symmetric vault data key and a signed, separately rotatable X25519 encryption public key in each device record; define KDF, AEAD, key IDs, and epochs.

- Loss of the last owner device has no recovery path — MUST
  Failure: Notes may remain readable locally, but nobody can authorize devices, rotate keys, or administer the vault.
  Fix: Provide an offline owner recovery key or an explicit, tested reinitialize-from-plaintext recovery ceremony; do not silently equate device pairing with recovery.

- Device reset and cloned backups can duplicate identity — MUST
  Failure: Restoring the same device key and sequence state on two machines produces equivocation, forks, and ambiguous revocation.
  Fix: Treat reset/restore as a new device identity, detect cloned state, document safe migration, and never copy an identity into a second active installation.

- Rotation is only “rotate and re-share” — MUST
  Failure: Offline devices cannot catch up, old ciphertext remains readable to compromised devices, and historical logs lose their verification context without key epochs.
  Fix: Specify device and vault-key epochs, old-key retention for catch-up, future-content re-encryption, historical verification, and revocation of wrapped keys.

- Revocation is local gossip, not a global offline guarantee — MUST
  Failure: A revoked device can continue syncing with an uninformed peer, and a clock rollback can extend an otherwise expired grant.
  Fix: Bound the promise honestly, propagate deny records with vault state, fail closed where feasible, and test long-offline and rolled-back-clock cases.

- Causal revocation alone does not stop future unauthorized writes — MUST
  Failure: A revoked agent can omit the revocation from every subsequent `seen` snapshot and continue producing entries considered valid under the stated rule.
  Fix: Separate historical validation from admission; include target sequence/key-epoch cutoffs in revocations and reject new authority after local revocation without erasing valid history.

- A second vault breaks sequence and replay assumptions — MUST
  Failure: A global per-device sequence causes apparent gaps in each vault, while entries without a vault ID can be replayed into another vault using the same device key.
  Fix: Namespace chains and vector clocks by `(vault_id, device_id, key_epoch)`, include the vault domain in every signed entry, and define per-vault storage.

- Key-file protection is Unix-only — MUST
  Failure: `0600` does not protect Windows ACLs, backups, crash dumps, or copied configuration directories.
  Fix: Define per-OS key storage and ACLs, redact diagnostics, test backup behavior, and offer passphrase or OS-keychain protection without implying full-disk encryption.

Sync semantics

- Case, Unicode, and platform filename rules are reduced to “NFC” — MUST
  Failure: Existing names can be silently renamed or collide across APFS, NTFS, and Linux; Windows reserved names, trailing dots, separators, and long paths add more failures.
  Fix: Define a canonical comparison key while preserving original names, reject unsupported names visibly, and generate deterministic collision cases rather than overwriting.

- Non-UTF-8 filenames have no policy — SHOULD
  Failure: Valid Linux files can disappear from manifests or abort an entire scan.
  Fix: For v1, skip and report non-UTF-8 names with an exportable error list; add escaped-byte filename support only if required later.

- Symlinks, junctions, hard links, and special files are unspecified — MUST
  Failure: A peer or agent can escape the vault, overwrite arbitrary files, or create cycles and unexpected duplication.
  Fix: Reject symlinks/junctions/special files in v1, never follow them during scanning or writing, and document hard links as independent regular files.

- Permission and metadata behavior is unspecified — SHOULD
  Failure: Mode bits, executable files, mtimes, ACLs, xattrs, and resource forks can diverge or cause repeated apparent modifications.
  Fix: Sync content plus a minimal documented executable-bit policy; ignore unsupported metadata and avoid promising lossless archival fidelity.

- Conflict rules cover only concurrent text edits — MUST
  Failure: Rename/rename, edit/delete, file/directory replacement, case collisions, and conflicting attachment writes can still lose data.
  Fix: Specify deterministic conflict copies and names for every mutation pair, retain both contents, and make resolution an explicit logged operation.

- Large-file support lacks a resource envelope — MUST
  Failure: A 1 MiB frame limit does not prevent multi-gigabyte allocations, hash recomputation, block-bitmap exhaustion, or disk exhaustion.
  Fix: Specify streaming block sizes, maximum file and manifest sizes, bounded concurrency, sparse-file policy, and memory/disk acceptance limits.

- Partial transfer state is not a protocol — MUST
  Failure: Restarted transfers can trust corrupted blocks, expose temporary files to Obsidian, or leave permanent garbage.
  Fix: Define signed manifests, verified block bitmaps, hidden temp locations, final-hash verification, atomic rename, idempotent resume, and stale-transfer cleanup.

- Offline months and clock skew are not tested semantics — MUST
  Failure: Expired grants, old key epochs, deletion tombstones, buffered sequence gaps, and software upgrades can make a returning device unable to converge.
  Fix: Define retention and catch-up rules, bounded out-of-order buffers, clock-skew policy, and 90/180-day offline compatibility tests.

- Filesystem watchers are assumed complete — MUST
  Failure: Obsidian atomic saves, rename exchanges, closed-laptop edits, and dropped watcher events can leave permanent divergence or sync loops.
  Fix: Combine watchers with periodic hashed reconciliation, ignore internal temp files, flush pending debounces on shutdown, and suppress self-generated events.

- Connectivity documents assume different transports — SHOULD
  Failure: Relay economics assume QUIC hole punching while the v1 plan cuts it, so many users may require manual addresses or relay configuration.
  Fix: For v1, document explicit endpoints/port forwarding plus self-hosted relay; treat automatic discovery and NAT traversal as separate later features.

The agent story

- Agents are called first-class, but MCP is absent from the implementation plan — MUST
  Failure: M1 exposes trusted local JSON while actual scoped agent authorization arrives at M4, with no MCP transport, schemas, versioning, or capability negotiation.
  Fix: Specify local stdio MCP backed by the same authorized core API, versioned tool schemas, structured errors, dry-run, and explicit capability discovery.

- Concurrent agent and human writes lack a concurrency contract — MUST
  Failure: Read-modify-write clients can overwrite one another even when every individual write is validly signed.
  Fix: Require expected-content-hash/revision preconditions, idempotency keys, atomic append semantics, per-vault serialization, and deterministic conflict results.

- Valid agents have no resource limits — MUST
  Failure: A buggy or compromised agent can fill disks, grow logs, consume CPU, and hold unlimited transfers without violating its path grant.
  Fix: Add per-grant operation, byte, file-size, concurrency, queue, and execution-time quotas with visible denial and usage counters.

- A path prefix is being mistaken for sandboxing — MUST
  Failure: Symlink races, Windows separators/ADS, rename TOCTOU, search results, embeds, and log exports can access data outside the grant.
  Fix: Broker all access through a least-privilege daemon, canonicalize at operation time, revalidate at commit, and scope every read/query/export—not only writes.

- Revocation during running work is undefined — MUST
  Failure: A long-lived session or queued transfer can continue for hours after its grant is revoked.
  Fix: Check authority at admission and commit, cancel active jobs, invalidate cached capabilities and key epochs, and define whether already-committed writes remain.

- Agent-key renewal and rotation are absent — MUST
  Failure: Expiry can strand automation, while a lost or compromised agent key has no clean replacement process.
  Fix: Add grant IDs, renewal requiring owner authority, key rotation with explicit overlap rules, least-privilege defaults, and an effective-permissions display.

Operations

- Local observability is absent — SHOULD
  Failure: Users cannot diagnose sync lag, repeated conflicts, key-epoch mismatches, disk pressure, or a failing transfer from example CLI output alone.
  Fix: Add redacted structured logs with rotation plus `status --json` for health, lag, bytes, conflicts, storage, and protocol versions.

- Crash handling and support bundles are absent — SHOULD
  Failure: A crash loop can repeatedly damage state, and support requests will encourage users to paste paths, note contents, or keys into public issues.
  Fix: Add safe mode, local panic/minidump capture, and explicit-consent redacted support bundles with a checklist of excluded material.

- Version skew and persistent migrations have no compatibility policy — MUST
  Failure: An upgraded device can emit records an offline-months peer cannot read or migrate a database that cannot be reopened by the prior release.
  Fix: Negotiate protocol capabilities, version every persistent schema, test mixed-version sync, and provide backup, migration, and rollback/refusal rules.

- Daemon lifecycle is outside every milestone — MUST
  Failure: Multiple processes can write one vault, upgrades can leave stale daemons, and uninstall instructions can accidentally delete identities or notes.
  Fix: Specify single-instance locking, service start/stop/restart behavior, upgrade handoff, data-preserving uninstall, and recovery from stale locks.

- Relay key claims contradict the signed quota endpoint — MUST
  Failure: The relay supposedly holds no keys but must sign status, leaving no defined signing identity or client trust anchor.
  Fix: Say “no vault keys,” define a separate relay identity key and enrollment/pinning process, or make quota responses endpoint-authenticated rather than relay-signed.

- Pairing does not make a free public relay Sybil-resistant — LATER
  Failure: Two strangers can generate keys and pair with each other, satisfying the stated relay condition while consuming unlimited fresh device identities.
  Fix: Keep v1 self-hosted; require owner enrollment or capability vouchers plus global limits before any public relay.

- Relay metadata claims are too strong — MUST
  Failure: Stable device IDs, IP addresses, timing, sizes, connection pairs, and file counts can be correlated despite “no accounts to correlate.”
  Fix: Publish exact metadata, retention, and threat limits; remove volume-shape heuristics from v1 as the plan already suggests.

Distribution and updates

- Cross-platform work starts too late — MUST
  Failure: Waiting until M5 for Windows/macOS packaging hides filesystem, service, and installer defects until after the protocol and storage layouts harden.
  Fix: Run build and filesystem integration CI on all intended cores from M1/M2 and do installer spikes before GUI feature completion.

- Release authenticity is undefined — MUST
  Failure: Unsigned GitHub binaries without checksums, provenance, or a key-rotation process leave users unable to distinguish releases from tampered artifacts.
  Fix: Provide checksums, signed release manifests, SBOMs, reproducible build instructions, protected tags, and a documented signing-key replacement process.

- Manual updates without migration rollback are not a safe update strategy — MUST
  Failure: A bad release can make a vault unreadable even without an auto-updater.
  Fix: Require pre-migration backup, upgrade/downgrade compatibility tests, release notes, and a safe refusal mode; defer the auto-updater itself.

- Service installation and uninstall are not deliverables — SHOULD
  Failure: Users receive a GUI but no reliable way to run, stop, upgrade, or remove the background synchronizer.
  Fix: Scope systemd, launchd, and Windows service commands with data-preserving uninstall tests.

- Toolchain and dependencies are not reproducible — MUST
  Failure: `rust-toolchain.toml` tracks moving stable, the manifest disagrees with documented crypto versions, and no lockfile appears in the repository, undermining vectors and builds.
  Fix: Pin a toolchain, commit `Cargo.lock`, reconcile dependency versions, and run MSRV plus locked-build CI.

Legal, licence and naming

- AGPL variant is ambiguous — MUST
  Failure: The requirement says AGPL-3.0 while Cargo and README say `AGPL-3.0-or-later`; changing after external contributions may require every contributor’s consent.
  Fix: Choose `AGPL-3.0-only` or `AGPL-3.0-or-later` now and make manifest, notices, UI, and repository metadata agree.

- Documentation licensing is asserted but not completed — MUST
  Failure: “CC BY 4.0” in the README without its own notice/license file leaves spec reuse and independent implementations ambiguous.
  Fix: Add `LICENSE-docs`, copyright/NOTICE information, third-party notices, and source-offer instructions for network-facing AGPL components.

- Contributor and AI-generated-work provenance is absent — MUST
  Failure: Future relicensing, auditability, and clean-room claims become dependent on private recollections of who or what produced each change.
  Fix: Use inbound-equals-outbound DCO sign-offs, record substantive agent assistance in commits/PRs, and prohibit copied proprietary implementation code.

- `synkty` is still a placeholder while `fald` is embedded in formats — MUST
  Failure: Renaming later either breaks signed compatibility or leaves permanent misleading domain strings and config paths.
  Fix: Screen and select the public name now, use one CLI/config naming scheme, and freeze protocol domain strings independently of future branding.

- Future control-plane licensing is unresolved — SHOULD
  Failure: Accepting AGPL-only contributions now can prevent later closing a control plane that the founder expects to sell as proprietary software.
  Fix: Decide whether the future control plane will also be AGPL or separately owned, and state that boundary before accepting contributions.

Testing and QA

- Milestone demos are not a release-quality test plan — MUST
  Failure: Happy-path JSON output can pass while data loss, interoperability, and upgrade failures remain undetected.
  Fix: Create a requirement-to-test matrix with explicit release gates and named owners for every MUST in this review.

- The crash tests do not cover the real fault matrix — MUST
  Failure: Killing a process does not simulate power loss, fsync failure, read-only filesystems, disk full, corrupted sectors, or interrupted migrations.
  Fix: Add fault injection at every write/rename/fsync/cursor/migration boundary and recovery assertions for each boundary.

- Filesystem and Obsidian fixture coverage is absent — MUST
  Failure: Path normalization, attachment handling, external edits, and frontmatter behavior will be tested only against synthetic notes invented by the implementer.
  Fix: Maintain licensed, sanitized real-vault fixtures and run concurrent Obsidian tests on every supported desktop OS.

- Scale, soak, and skew tests lack numeric targets — MUST
  Failure: “Bounded memory” and “converged” do not reveal unusable scan times, runaway log growth, battery drain, or divergence after months offline.
  Fix: Set targets for vault count/size, attachment size, memory, sync latency, mixed versions, clock skew, and multi-day partitioned soak runs.

- Independent security verification arrives too late and has no release gate — SHOULD
  Failure: Cryptographic and authorization defects can become frozen compatibility burdens before anyone independent examines them.
  Fix: Build an independent decoder/verifier from the spec in M0/M1 and require an external protocol/security review before broad public release.

Documentation and onboarding

- There is no safe first-run migration guide — MUST
  Failure: A new user can point the daemon at their only Obsidian vault while another sync provider is active and lose data immediately.
  Fix: Provide backup-first installation, read-only scan/preview, provider-exclusion checks, and a small test-vault tutorial before enabling a real vault.

- Recovery documentation is absent — MUST
  Failure: Users facing a fork, revoked owner, lost device, corruption, or accidental deletion will improvise destructive repairs.
  Fix: Write task-oriented runbooks for backup, restore, undo, reset, cloning, compromise, fork, disk full, and version refusal.

- CLI/JSON/MCP compatibility is undocumented — MUST
  Failure: Agents will scrape unstable text or depend on undocumented errors and field meanings.
  Fix: Version JSON schemas, exit codes, error catalogs, MCP tools, idempotency behavior, and deprecation policy.

- Supported limits and security/privacy disclosures are scattered — MUST
  Failure: Users cannot tell which filesystems, files, plugins, metadata, offline durations, and relay exposures are actually supported.
  Fix: Publish one compatibility matrix and one plain-language security/privacy/backup document linked from onboarding.

2. OBSIDIAN INTEROP, HONESTLY

Compatibility must mean “synkty can safely synchronize an existing Obsidian vault in place without requiring an import, changing its note format, or destroying information Obsidian understands.” It must not mean “Obsidian opens the folder once.”

Files and directories

- Synchronize regular `.md` notes, attachments such as images/PDF/audio/video, and other ordinary user files byte-for-byte.
- Preserve existing `.canvas`, `.base`, plugin-specific Markdown, templates, snippets, and unknown files as opaque content unless explicit editing support is implemented.
- Keep synkty’s logs, keys, database, temporary transfers, and CAS outside the vault where practical; nothing internal should appear as an Obsidian note.
- Do not claim compatibility with Obsidian’s plugin API or proprietary internals. Compatibility is with the folder and documented file conventions.

`.obsidian`

- Treat `.obsidian` as per-device application state in v1.
- Never synchronize `workspace*` files, caches, plugin executables, or plugin state by default.
- Do not delete or rewrite plugins, themes, hotkeys, snippets, or settings; leave the directory entirely under Obsidian’s control.
- Later, offer an explicit allowlist for selected declarative settings only. Community plugin code requires a separate trust and installation decision, not file sync.
- Document clearly that v1 synchronizes content, not the Obsidian workspace or plugin installation.

Markdown, links and properties

- Preserve unknown Markdown and YAML rather than normalizing whole documents.
- Support reading basic `[[Note]]`, path-qualified links, aliases, headings, block references, and `![[...]]` embeds for indexing and the derived map.
- Preserve relative Markdown links, URL-encoded spaces, configured attachment-folder behavior, and extensionless attachment links.
- Preserve YAML frontmatter field order, quoting, comments, unknown properties, aliases, nested tags, and tag lists unless the user edits that exact property.
- Recognize tags in frontmatter and prose without treating tags inside code blocks as note tags.
- Preserve BOM/line-ending policy and attachment bytes; never run newline or Unicode conversion across an entire vault.
- Do not silently rename files to NFC or update links after moves. If safe link-aware rename is not implemented, expose move as a potentially link-breaking operation.

Attachments and maps

- Synchronize attachments as binary files with final-hash verification; size limits and unsupported files must be visible rather than silently skipped.
- Build the v1 mind map from headings and basic wiki-links without adding a map file.
- Existing `.canvas` files remain usable by Obsidian because synkty leaves them alone, not because synkty claims to edit them.
- Any later Canvas editor needs JSON Canvas conformance fixtures, unknown-field preservation, and tests for file nodes, text nodes, links, groups, and edges.

A vault already synced by something else

- The supported migration is: back up, verify the backup, disable or move away from the other provider, run a read-only inventory, then enable synkty.
- Detect common Dropbox, OneDrive, iCloud, Google Drive, Syncthing, and Obsidian Sync arrangements where feasible, but do not claim detection is exhaustive.
- Refuse to silently “adopt” conflict files or partial placeholders; show what will be synchronized before the first write.
- Obsidian’s own documentation warns against synchronizing the same vault through multiple services, so “use both and hope” cannot be a supported mode.

What breaks a real user on day one

- Unicode/case normalization renames notes and breaks existing links.
- A full-file YAML or Markdown rewrite strips properties and plugin-specific syntax.
- Syncing workspaces repeatedly rearranges panes; syncing plugins introduces unreviewed executable code.
- Conflict logic chooses one version, creates unbounded conflict copies, or replicates a deletion everywhere with no restore.
- Attachments, hidden files, or unsupported names are skipped without a complete report.
- synkty temp files appear inside Obsidian and are indexed or synchronized back.
- External Obsidian edits are missed after sleep, watcher overflow, or atomic-save sequences.
- Another sync provider remains enabled and both engines repeatedly resurrect or delete files.
- The derived map edits Markdown structurally and destroys formatting or frontmatter.
- A partial transfer appears under its final attachment name and Obsidian renders a truncated file.

Smallest acceptable v1 definition

An existing vault can be opened simultaneously in synkty and Obsidian; notes and attachments round-trip byte-for-byte; ordinary wiki-links, embeds, frontmatter, and tags survive; Obsidian-originated edits synchronize; `.obsidian` remains per-device; conflicts and deletions are recoverable; unsupported names/files are reported; and no other sync provider is supported concurrently. That definition needs automated fixtures plus clean-machine tests in the real Obsidian app, not just a folder-open screenshot.

3. SCHEDULE AGAINST 1 JUNE 2027

The arithmetic is 191 elapsed days, or 27.3 weeks. At 20 focused owner hours per week, that is approximately 546 gross hours before subtracting holidays, support, review, and integration time.

The document plan totals 22 weeks:

- M0–M5: Mon 2026-11-23 through Sun 2027-04-25.
- Remaining before release: five weeks and one day.
- A three-week hardening period and the required two-week buffer consume all of it.

That leaves zero slack for the missing backup/restore system, Obsidian work, sync and log specifications, MCP, key lifecycle, filesystem compatibility, release engineering, or mixed-version testing. At 20 hours per week, the current three-desktop scope is not responsibly reachable by 1 June 2027. Agent capacity can produce code in parallel, but it does not multiply the owner’s specification, security review, integration, and release capacity.

A defensible narrowed calendar is:

- Mon 2026-11-23 – Sun 2026-12-06: M0; decisions, identity/membership model, frozen encoding, vectors, contributor gates.
- Mon 2026-12-07 – Sun 2027-01-10: M1; crash-safe vault, WAL, snapshots, backup and restore, external-edit reconciliation.
- Mon 2027-01-11 – Sun 2027-02-21: M2; direct sync, deterministic conflicts, resumable files, Obsidian fixtures, path policy.
- Mon 2027-02-22 – Sun 2027-03-14: M3; self-hosted relay, end-to-end ciphertext, quotas and reconnect accounting.
- Mon 2027-03-15 – Sun 2027-04-11: M4; grants, revocation, agent recovery, stdio MCP, proofs and scoped audit.
- Mon 2027-04-12 – Sun 2027-05-09: M5; supported Linux GUI, editor, derived mind map, conflict/restore UX, installer.
- Mon 2027-05-10 – Sun 2027-05-16: release-candidate hardening only.
- Mon 2027-05-17 – Sun 2027-05-30: defended buffer for release-blocking defects and failed restore/upgrade drills only.
- Mon 2027-05-31: final artifact verification and release staging.
- Tue 2027-06-01: release.

Critical path: M0 specification and identity → M1 durable local state → M2 convergence and transfer → M3/M4 authorized networked operation → M5 product UX → RC. GUI design, fixtures, documentation, relay scaffolding, and packaging spikes can proceed in parallel through agents, but they cannot bypass those dependencies.

Slack: there is none in the feature schedule. The only defensible buffer is 17–30 May. Do not spend it on Windows/macOS installers, Canvas editing, NAT traversal, automatic updates, or feature polish.

The smallest reachable scope for that calendar is a Linux-supported technical v1 with CLI and minimal GUI, complete Markdown/attachment vaults, direct sync and self-hosted relay, conflict copies, backup/restore, derived mind map, scoped local MCP agents, and manual signed downloads. Windows/macOS may remain experimental CI targets, but their supported installers move after release. Mobile, public relay, multi-owner teams, live collaborative merging, Canvas editing, selective sync, and auto-update remain out.

Capacity changes:

- At 10 hours per week, approximately 273 gross hours exist: do not promise a public product; target an internal M0–M2 developer preview and move the product date.
- At 20 hours per week, approximately 546 gross hours exist: only the narrowed scope above has a credible path, and it remains tight.
- At 40 hours per week, approximately 1,091 gross hours exist: the three-desktop plan becomes plausible if decisions freeze by 6 December and the extra time goes to review, testing, recovery, and packaging rather than more features.

4. READY FOR A SECOND CONTRIBUTOR

A second contributor currently faces contradictory specifications and an Ubuntu-only `fmt/clippy/test` workflow. Before they touch the code, require:

Repository hygiene

- Protected `main`; PR-only changes; no force pushes; no direct agent commits.
- One final CLI/config/protocol naming scheme and a documented workspace layout.
- Pinned Rust toolchain, committed lockfile, locked dependency builds, and reproducible local setup.
- `.gitignore` coverage for test vaults, identity files, support bundles, crash dumps, and signing material.
- `SECURITY.md`, support/issue templates, code/documentation license notices, and a public security contact.
- A single adopted v1 scope; resolve README/plan contradictions instead of letting contributors choose.

CI gates

- Required formatting, clippy, tests, dependency audit/license checks, and locked builds.
- Linux, Windows, and macOS core tests as soon as those platforms are claimed.
- Frozen protocol vectors, malformed-input fuzz smoke, independent decoder/verifier tests.
- Deterministic convergence, crash/ENOSPC, symlink/traversal, disk-full, and restore tests for storage/sync changes.
- Obsidian fixture round-trips and real-application migration smoke tests before releases.
- Package installation, service lifecycle, mixed-version sync, and upgrade/rollback checks for release candidates.

Decision records and specification control

- ADRs for identity/membership, key recovery, path semantics, conflicts, log/revocation, transport, agent authorization, map format, updates, and licensing.
- A spec-change template identifying wire compatibility, persistent-state migration, vectors, negative tests, and affected documents.
- Normative bytes change only with an explicit version decision; no “small” implementation PR may silently change signed encoding.
- A public requirement-to-test matrix so nobody needs Able’s memory to discover acceptance criteria.

Issues and review

- Labels: `type:{bug,feature,spec,security}`, `area:{store,sync,obsidian,identity,agent,relay,ui,packaging,docs}`, `severity:{P0-data-loss,P1-security/P1-major,P2,P3}`, `milestone:*`, `needs-decision`, and `agent-ready`.
- Reproduction template requiring OS, filesystem, versions, steps, expected/actual result, and sanitized logs; sensitive security reports stay private.
- No self-merge. Able or a designated maintainer reviews every PR; crypto, protocol, storage, migrations, and authorization require an additional domain review.
- Agent-authored PRs receive the same tests plus human line-by-line accountability; provenance and linked issue are mandatory.
- A P0 data-loss or authorization defect blocks release and stops related feature merges until a regression test exists.

Release process

- Versioning and changelog rules, release candidates, tagged source, protected release environments, checksums, signatures, SBOM, and corresponding-source links.
- Clean-machine installation, upgrade, mixed-version, backup/restore, and rollback/refusal drills before tagging.
- Documented incident response for malicious artifacts, signing-key compromise, and emergency withdrawal of a release.
- No release based solely on green unit tests or agent reports.

Key-handling ceremony

- Generate release and update keys outside CI; store encrypted offline backups and publish only public verification keys.
- Keep Apple/notarization and other platform credentials in protected CI environments, unavailable to ordinary PRs and agents.
- Record who generated, accessed, backed up, rotated, or revoked each release key without recording secret material.
- Require two authorized humans for adding or replacing a release verification key once a second maintainer exists.
- Use separate disposable test keys and run a revocation/replacement drill before the first public release.

The one missing front-door document is `CONTRIBUTING.md`. It should contain the exact setup/test/PR commands, ownership boundaries, agent rules, labels, ADR process, release path, and links to the adopted product contract and recovery/security runbooks.

5. TEN DECISIONS IN THE NEXT FOURTEEN DAYS

All ten should be settled by Sun 2026-12-06.

1. What exactly is the 1 June release?
   Recommended answer: The narrowed Linux-supported technical v1 described above, with Windows/macOS only experimental until their install and filesystem gates pass; no mobile or public relay.
   Unblocks: Schedule, staffing, packaging, test matrix, and honest release messaging.

2. What is the canonical path and file model?
   Recommended answer: Regular files only; vault-relative UTF-8 paths; preserved original names with a defined comparison key; visible rejection of unsupported names; no symlinks/junctions/special files; minimal metadata.
   Unblocks: Manifests, Obsidian behavior, grants, transfer code, and cross-platform tests.

3. How do identity, membership, ownership, and recovery relate?
   Recommended answer: Pairing authenticates only a device; signed vault membership grants access; an explicit owner set authorizes policy; each device has Ed25519 plus signed X25519 keys; a random symmetric vault key has epochs; owner recovery is documented and tested.
   Unblocks: `DeviceRecord`, key wrapping, rotation, reset, compromise, and second-vault behavior.

4. What are the permanent names and signed bytes?
   Recommended answer: Select the public name now, remove `fald` drift, freeze protocol domain strings independently of branding, use one signed envelope and sorted vector clocks, and reject noncanonical/unbounded input.
   Unblocks: M0 vectors, independent implementations, pairing, and every later protocol version.

5. What does Obsidian compatibility include, and what is the map?
   Recommended answer: The section-2 contract; `.obsidian` and plugins remain per-device; existing files are preserved; the v1 map is derived from Markdown; `.canvas` is opaque and not bidirectionally edited.
   Unblocks: Fixtures, parser scope, GUI design, migration onboarding, and product claims.

6. What are the data-safety and conflict guarantees?
   Recommended answer: Deterministic conflict copies for all mutation types, retained historical blobs, snapshots, trash, durable fsync sequences, idempotent WAL recovery, and tested backup/restore; no silent automatic merge.
   Unblocks: M1 storage layout, M2 convergence, disk requirements, and release acceptance tests.

7. What do log validity and revocation mean?
   Recommended answer: Namespace entries by vault/device/key epoch; separate historical verification from admission; use sequence/epoch revocation cutoffs; define owner trust roots, checkpoints, and proof completeness; keep full logs in v1.
   Unblocks: Log format, causal tests, agent revocation, offline behavior, and portable proofs.

8. What is the v1 agent interface?
   Recommended answer: Local stdio MCP through the daemon, scoped grants on every operation, expected-revision writes, idempotency keys, quotas, dry-run, scoped reads/audit, and cancellation plus commit-time checks on revocation.
   Unblocks: MCP schemas, concurrency, sandbox boundaries, renewal, and M4 implementation.

9. What connectivity is promised without paid infrastructure?
   Recommended answer: Pinned end-to-end encrypted direct connections plus a separately identified self-hosted relay; manual endpoint configuration in v1; no public relay, automatic NAT traversal, or relay-terminated plaintext.
   Unblocks: M2/M3 transport, relay trust, privacy disclosures, quota design, and cost claims.

10. What are the licensing, contribution, and release rules?
    Recommended answer: Explicitly confirm the current `AGPL-3.0-or-later` or change it now, CC BY 4.0 documentation with actual notices, DCO rather than a CLA, AI provenance rules, final-name screening, signed manual releases, and an early decision on control-plane licensing.
    Unblocks: External contributors, public releases, future paid-layer boundaries, and release-key setup.

6. WHAT WE MISSED

- Nobody has scheduled observation of real Obsidian users migrating messy vaults, so the central product promise currently has no external validation loop.
- Antivirus, search indexing, cloud placeholders, and application file locks can invalidate the neat atomic-write model, especially on Windows.
- Filesystem watcher events are lossy, so without periodic full reconciliation some edits will simply never synchronize.
- Replicated deletion without accessible version history turns a minor user mistake into permanent data loss on every device.
- A valid but malfunctioning agent can destroy availability through disk, CPU, memory, log, and network exhaustion without triggering any cryptographic alarm.
- Accessibility and keyboard-only conflict/restore workflows are completely unscoped, despite being product functionality rather than polish.
- Idle CPU, battery drain, network chatter, and full-vault rescans can make an always-on daemon unacceptable even when synchronization is correct.
- There is no coordinated vulnerability-response exercise for discovering that identity, grants, or update verification are defective after release.
- There is no rehearsed rollback for a bad persistent-state migration, so even manual upgrades can make a vault inaccessible.
- There is no privacy-respecting way to measure active installations or successful syncs, leaving “when real users exist” undefined as an infrastructure trigger.
- Agent-generated implementation volume can exceed human review capacity, making apparent schedule progress increase rather than reduce release risk.
- Repository ownership, signing keys, recovery material, and release authority still have a one-founder bus-factor problem that the protocol’s device revocation cannot solve.

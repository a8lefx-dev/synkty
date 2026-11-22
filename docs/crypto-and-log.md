# Crypto and the attribution log

Status: design, no code. Everything here is chosen so that a stranger can verify our claims
without trusting us, and so that no part of it needs a server.

## Primitives: one per job, no choices at runtime

| job | primitive | crate (version checked today) | why this one |
|---|---|---|---|
| identity + signatures | **Ed25519** | `ed25519-dalek` 3.0.0 | 32-byte key, 64-byte sig, deterministic — no per-signature randomness to reuse (the ECDSA catastrophe: one repeated `k` leaks the key, cf. the PS3) |
| key agreement | **X25519** | `x25519-dalek` 3.0.0 | same curve family, one API, no parameter negotiation |
| hashing / IDs / chaining | **BLAKE3** | `blake3` 1.8.7 | fast, parallel, built-in keyed mode and `derive_key` for domain separation; no length-extension games |
| payload encryption | **XChaCha20-Poly1305** | `chacha20poly1305` 0.11.0 | 24-byte nonce makes random nonces safe at our volume; constant-time without hardware AES |
| pairing | **SPAKE2** | `spake2` 0.5.0 | a six-word code must not be brute-forceable offline by a passive eavesdropper — PAKE is the only primitive that gets that |
| transport | **TLS 1.3** with raw public keys | `rustls` 0.23.x + `quinn` 0.11.12 | we keep the protocol everyone has already attacked and replace only the trust anchor |
| secret hygiene | **zeroize** | 1.9.2 | keys die on drop, not on GC |

**Post-quantum, decided now not later.** "Harvest now, decrypt later" is real for a notes app —
people write things they expect to be private in ten years. rustls 0.23.27+ enables the hybrid
group **X25519MLKEM768** by default; we keep it and put a suite byte in every format so a future
hybrid signature can be added without a flag day. We do not hand-roll ML-KEM.

## What we do not use, and why

- **No X.509 chain.** Syncthing's certs are self-signed and no CA is ever checked: a keypair in
  an ASN.1 suit. We use RFC 7250 raw public keys — the handshake carries the subject public key
  itself — with a verifier that pins it to the device ID from the pairing record. If a rustls API
  gap appears, the fallback is the stable one: a self-signed Ed25519 cert whose SPKI we extract
  and compare in a custom `ServerCertVerifier`. Either way, nothing parses a certificate chain.
- **No ECDSA.** Random-nonce signing is one RNG bug away from total key disclosure.
- **No JWT for grants.** `alg: none` and HS/RS confusion are not theoretical; a grant is a
  fixed-size signed struct with an explicit version byte.
- **No blockchain, no token, no consensus.** A signed hash chain needs none of it. There is no
  global ordering problem because there is no global ledger.
- **No wall-clock ordering.** Clocks lie and are trivially skewable. Order comes from causality.

## Keys

- **Device key** (Ed25519): generated on the device, never exported. Device ID =
  `base32(BLAKE3(pubkey)[..16])` + check group → 20 characters, not 56.
- **Vault key** (X25519, per vault): wrapped to each member device, so adding a device does not
  re-encrypt the vault.
- **Session keys**: derived per connection from the TLS 1.3 handshake; nothing long-lived.
- **Agent key** (Ed25519): the agent generates its own. It never holds a device key; it holds a
  grant signed by one.

## Encoding rules (where signature schemes actually die)

1. Sign the **bytes**, never the struct. Deterministic encoding only — fixed field order, no
   JSON, no floats, no maps with unspecified order.
2. Every signed blob starts with a **domain-separation prefix** and a version byte
   (`"synkty/entry/v1"`), so a signature over one kind of object can never be replayed as another.
3. Paths are UTF-8, **NFC-normalised**, vault-relative, no leading `/`, no `..`. Two spellings of
   the same filename are a security bug, not a UX bug.
4. Length-prefix every variable field; reject trailing bytes.
5. Ed25519 signs the message directly — it hashes internally. BLAKE3 is for content and chain
   links only; double-hashing a signature gains nothing and invites confusion.

## The attribution log

Not a payment ledger, not a blockchain: an **append-only, per-device, signed, hash-chained
record of every mutation**, replicated with the vault. It answers one question offline: *who
changed this file, under which authority, and has anything been rewritten since?*

```
entry := header || body || sig

header (8 bytes)
  magic "SKLE" | ver u8 (suite) | kind u8 | flags u8 | reserved 0x00

body
  dev    [u8;16]    author device id (raw bytes, not base32)
  seq    u64        monotonic per device, no gaps
  seen   map<dev,seq>   vector clock: what this author had observed at write time
  path   bytes      NFC, vault-relative
  blob   [u8;32]    BLAKE3 of resulting content; zeros for delete
  size   u64
  ts     i64        wall clock — advisory, never used for ordering
  grant  option<[u8;16]>  set iff the author is an agent
  meta   bytes      file mode, agent label

sig    64 bytes     Ed25519 over "synkty/entry/v1" || header || body
```

**Chaining.** `prev = BLAKE3("synkty/chain/v1" || previous entry, including its signature)`.
Editing any past entry breaks every link after it, and the attacker cannot re-sign: they do not
have that device's key. Deleting an entry breaks `prev`. Gaps in `seq` are a hard error.

**Checkpoints.** Every 1024 entries, a signed record `{dev, from_seq, to_seq, merkle_root}`. The
root is over `BLAKE3("synkty/leaf/v1" || entry)`. Checkpoints are what make two things possible
without shipping the whole history: pruning old segments without losing provability, and
detecting truncation — a rewrite that drops entries contradicts a checkpoint someone already
holds. Devices gossip their heads, so history rewrites are detectable by anyone who remembered
the old head (the certificate-transparency trick, minus the log server).

**Ordering.** The vector clock, not `ts`. Concurrent edits — neither `seen` contains the other's
entry — are a genuine conflict, resolved by the merge layer, and both entries stay in the log as
evidence. This is why merge is deterministic and testable.

**Forks.** Two different entries with the same `(dev, seq)` is proof of equivocation: that key
signed two histories. Keep both, mark the device suspect, surface it loudly. Never auto-repair.

## Verification, at three levels

1. **Per entry, on receipt** — O(1): signature verifies against the device key; `prev` matches
   the stored head; `seq` is exactly head+1; path is normalised; `grant` (if present) resolves and
   is unexpired and unrevoked. Failing entries are quarantined, never applied.
2. **Range** — `synkty log verify --dev <id> --from 1 --to 5000` recomputes the chain and compares
   against the newest checkpoint's Merkle root. BLAKE3 does gigabytes per second, so this is fast
   even for large logs.
3. **Single-file proof** — `synkty log prove <path>` emits the entries plus a Merkle path to a
   signed checkpoint. Anyone with the repo and the device's public key can verify it: no server,
   no account, no trust in us.

An independent implementation must be possible from the spec alone — that is the point of
"verify it yourself". Byte layout, test vectors and the exact acceptance rules belong in
`docs/log-format.md` before M1 coding starts, not after.

## Agents: the three-link chain

1. Agent generates its own Ed25519 key.
2. Owner signs a **grant**: `{vault, path_prefix, ops, expires, agent_pubkey}` — stored in the
   log as `kind=Grant`.
3. Agent writes entries signed with **its** key, carrying the grant id.

So "an agent wrote this" is verifiable offline by chaining entry → grant → owner device, with the
owner's device in a signed device list. Revocation is another log entry (`kind=Revoke`); an entry
is valid only if no revocation of its author is in that entry's causal past (i.e. absent from its
`seen` snapshot). That is checkable without a clock and without a server.

## What the log proves, and what it does not

- **Proves:** which key signed which change, in what causal order, under which grant, and that
  nothing was rewritten since the last checkpoint anyone held.
- **Does not prove:** that a human wanted it. A compromised device signs perfectly valid entries.
  Mitigation is not crypto — it is device revocation, short grant expiries, and a UI that shows
  the author.
- **Does not prove:** that an entry was never withheld. Absence is not evidence; the log is
  append-only per device, and a device can simply not tell you about its own fork of history
  (until two peers compare heads).

## Integration points

- **Apply path**: verify → resolve merge → apply → append. No entry, no write. The log is not a
  side-car to the sync engine; it *is* the sync engine's write-ahead record.
- **Relay**: never sees plaintext, and never signs anything. It forwards frames; it is not part
  of the trust graph at all. A malicious relay can drop or delay traffic (a denial of service),
  and cannot forge, reorder undetectably, or read.
- **UI**: every note shows last author (device or agent label) with a verified badge; a broken
  chain or a fork is a red banner, never a silent repair.
- **Growth**: entries are ~150-250 bytes; 100k edits ≈ 25 MB. Segments rotate at 4 MB, checkpoints
  every 1024 entries, old segments prunable once their roots are signed and gossiped.

## Open questions for Able

1. **Log granularity**: every write, or coalesce rapid saves (a 300 ms debounce) into one entry?
   (Recommend: coalesce within a session, one entry per save-burst — otherwise a long editing
   day is 1000 entries of noise.)
2. **Encrypt the log too?** Paths leak note titles. Encrypting the entry body under the vault key
   keeps authors verifiable but titles private from anyone holding the repo file alone.
3. **Attribution export**: a JSONL `synkty log export` for agents/audit, or keep it binary and
   add a viewer first?

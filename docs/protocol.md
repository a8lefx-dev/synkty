# synkty wire protocol — v0 (draft)

Status: **draft**, M0 scope. Written before the code; the code is expected to match this
document, not the other way round. Anything not written here is not part of the protocol.

Conventions: BLAKE3-256 for hashes, Ed25519 (RFC 8032) for signatures, postcard for
canonical encoding, UTF-8 strings, Unix seconds for times.

---

## 1. Identity

### 1.1 Device key

One Ed25519 keypair per device. Generated on first run, stored at
`$XDG_CONFIG_HOME/fald/identity.key` with mode `0600`, never exported by any command and
never logged. There is no certificate, no CA, no expiry: the identity **is** the key.

### 1.2 Device id

```
payload = BLAKE3("fald/device-id/v1" || pubkey)[0..10]          // 80 bits
check   = BLAKE3("fald/device-id-check/v1" || payload)[0..3]     // first 20 bits
display = base32crockford(payload) || base32crockford20(check)   // 16 + 4 symbols
printed = 5 groups of 4 separated by '-', e.g. 7F3K-2QX9-M4TB-8ZRD-1Y6C
```

- 80 bits of payload: birthday bound is about 2^40 devices, which is every device that
  will ever run this software.
- The 20-bit check group catches single-symbol typos and adjacent transpositions with
  probability `1 - 2^-20`.
- Parsing: strip `-` and whitespace, uppercase, map `O -> 0`, `I -> 1`, `L -> 1`, then
  require length 20, every symbol in the alphabet, and a matching check group. Any failure
  is a rejection — ids are never "repaired".
- The alphabet is Crockford base32 (`0-9 A-Z` without `I L O U`), chosen so nothing is
  confusable with `1`, `0`, and nothing spells a rude word.

### 1.3 Canonical encoding

- Records are postcard structs, fields in declaration order, no maps, no floats.
- The first two fields of every signed struct are `version: u8` and `kind: u8`.
- A signature covers the postcard bytes exactly as transmitted. Peers verify the bytes they
  received; they never re-encode and then verify, because any encoder drift would silently
  change what was signed.
- JSON is a debugging format only, never a signing input.

### 1.4 Device record

```
DeviceRecord {
  version: u8 = 1,
  kind:    u8 = 0x01,
  pubkey:  [u8; 32],
  name:    String,        // human label, 1..=64 bytes, no control characters
  added_at: i64,
}
```

Self-signed with the same key. A record on its own proves possession of the key, not
trustworthiness: trust comes only from pairing (§1.7) or an explicit `fald devices add`
where a human compares fingerprints.

### 1.5 Grant (an agent's rights)

```
Grant {
  version:      u8 = 1,
  kind:         u8 = 0x02,
  subject:      String,      // agent name
  subject_pubkey: [u8; 32],
  vault_id:     [u8; 16],
  path_prefix:  String,      // e.g. "inbox"
  ops:          u8,          // read=0x01 write=0x02 append=0x04 move=0x08 delete=0x10
  issued_at:    i64,
  expires_at:   i64,
  nonce:        [u8; 16],
}
```

Signed by the **owner device key**; verified offline by any peer holding the owner's
record. An operation is allowed only if all of the following hold:

1. `now < expires_at` and `now >= issued_at - 300` (five minutes of clock skew);
2. the requested op bit is set;
3. the target path is inside `path_prefix`, compared **per path segment** — prefix
   `inbox` must not authorise `inbox-secret/notes.md`;
4. the grant nonce is not in the local deny set (§1.6).

### 1.6 Revocation

```
Revocation {
  version:     u8 = 1,
  kind:        u8 = 0x03,
  target_kind: u8,      // 0x01 device, 0x02 grant
  target:      [u8; 32],   // device pubkey hash, or grant nonce padded
  revoked_at:  i64,
  reason:      String,
}
```

Signed by an owner key, gossiped to peers, and kept forever in a local deny set.
**Revocation is monotonic**: no later record can undo it, and clock skew cannot resurrect
a revoked device or grant.

### 1.7 Pairing

- The offering device prints a code of **6 words** from a 2048-word list: 66 bits.
- PAKE: SPAKE2 (symmetric), so a passive eavesdropper learns nothing and an active
  man-in-the-middle gets exactly one guess per handshake.
- On success each side sends its `DeviceRecord`, sealed with the PAKE-derived key, and both
  display the other's fingerprint for a human confirmation.
- The code is single-use and expires after 10 minutes.
- M0 transport: a direct TCP connection on the LAN, or loopback for the demo. The PAKE and
  record exchange are transport-agnostic; the relay arrives at M3 and changes nothing here.

### 1.8 Frame

```
frame = u32 length (big endian) || postcard(Envelope { version: u8 = 1, kind: u8, body: bytes })
```

`length` counts the envelope only. Maximum frame in v0 is **1 MiB**; a decoder must reject
anything larger *before* allocating, and must reject a length that does not match the bytes
actually read.

### 1.9 Test vectors

Frozen at M0, before any peer code exists. Three fixed seeds produce: the device id, the
postcard bytes of the record, and the verify result. They are generated with
`fald identity vectors`, pasted into this section, and then asserted in
`crates/fald-identity/tests/vectors.rs`. A spec without vectors is a wish.

| seed | device id | record bytes (hex) | verifies |
|------|-----------|--------------------|----------|
| _to be frozen at M0_ | | | |

---

## 2. Sync (M1, not yet specified)

Folder manifest, block sizing, resumption, placeholders.

## 3. Relay (M3, not yet specified)

Ciphertext-only relay: what the relay is allowed to see, and what it must never see.

## 4. Attribution (M4, not yet specified)

Signed write records, hash chaining, and how a peer verifies history offline.

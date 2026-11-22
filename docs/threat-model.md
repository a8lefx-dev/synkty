# Threat model — v0

Scope: the M0 identity layer, plus the shapes it commits the rest of the system to.

## Assets

- Note contents and filenames.
- Device private keys and folder keys.
- Grants (an agent's rights) and the revocation/deny set.
- The attribution log: who wrote what, when.

## Adversaries

| adversary | capability | what stops them |
|---|---|---|
| Passive network | reads every byte on the wire | per-session ephemeral X25519, AEAD; relay sees ciphertext only |
| Active MITM | can inject, drop, replay | mutual signature over the handshake; PAKE makes an off-line guess useless and an on-line guess single-shot |
| Compromised peer | holds a *valid* device key | folder keys are per-folder and rotatable; revocation is monotonic; attribution names the key |
| Stolen device | has the disk | folder keys wrapped to that device only; revoke + rotate on discovery; optional passphrase-wrapped identity key |
| Malicious agent | holds a *valid* grant | path-segment scope, op bitmask, expiry, deny set, every write signed and reviewable |
| Relay operator | routes traffic, sees metadata | content and paths are inside encrypted manifests; no accounts to correlate |
| Root on your own host | everything | nothing. Be honest with users: local root wins. |

## Promises

1. **Confidentiality in transit and at the relay.** No plaintext content, and no plaintext
   paths, leave a device unencrypted.
2. **Integrity.** Every block is addressed by its BLAKE3 hash; a corrupt or substituted
   block is discarded, never written.
3. **Authenticity of policy.** Device records, grants and revocations are signed; a peer
   that cannot verify does not act.
4. **Non-repudiation of writes.** Each write record is signed by the writing key and chains
   to the previous content hash; any peer can verify the chain offline.
5. **Revocation is monotonic.** Once revoked, always revoked, regardless of clocks.

## Non-promises

- Protection from an administrator on your own machine.
- Traffic analysis resistance on the LAN (packet timing, sizes) in v0.
- Anonymity: device ids are stable pseudonyms, and peers you paired know them.
- Confidentiality from a peer you chose to pair: they hold the folder key.
- Retroactive confidentiality after a key compromise. Rotate forward, never backward.

## Key compromise runbook (the promise we make instead)

1. `fald devices revoke <id>` on any owner device → signed revocation.
2. Rotate the folder key and re-share to remaining devices.
3. Content the compromised device already had stays compromised: say so plainly in the UI.

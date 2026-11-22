# XRP: where it can and cannot go

Able wants to use XRP "if possible". Short version: **XRP cannot be our crypto — it is not a
primitive — but it fits two real jobs, and only one of them is worth doing.** Both are optional,
both can be added after v1 without changing a single signed byte, and neither belongs before
1 June 2027.

## Why it cannot replace the suite

Ed25519, X25519, BLAKE3, XChaCha20-Poly1305 and SPAKE2 answer questions like "who signed this"
and "can this device read that". XRP answers "who owns this asset" on a public ledger. Swapping
them is a category error, and putting the sync path on a public chain would make every note
write cost a fee, take a ledger close (~4 s), publish your activity, and still leave you unable
to verify anything offline. The whole point of the design is that verification needs no network.

## Role A — payments for the paid control plane (someday)

Accept XRP for the managed relay / control plane, not for the free tier.

- **Price in USD, convert at checkout.** XRP moves double-digit percentages; a $5 subscription
  priced in XRP is a different business every week.
- **Custody is the real decision.** A processor (hosted checkout, they hold the funds) keeps us
  out of wallet operations; self-custody means running a hot wallet, seeds, and reconciliation.
  For a one-person shop the processor wins, even at a fee.
- **Accounting.** Crypto receipts are income at fair-market value on receipt, with a disposal
  event each time we spend it. That is bookkeeping work, and it is a post-entity task.
- XRPL mechanics: a new account needs a **1 XRP base reserve** (0.2 XRP per extra owned object,
  verified at xrpl.org today), a standard transaction costs **10 drops = 0.00001 XRP**, and
  **destination tags** let one deposit address serve many customers.
- **Blocked until January 2027** by the entity timeline, exactly like Stripe. Nothing to build
  now; the metering counters already exist and are what a paid tier would bill against.

## Role B — external anchoring of log checkpoints (the good one)

Our checkpoints are signed Merkle roots over `(device, from_seq, to_seq)`. Publishing that root
somewhere we do not control turns "trust our clock" into "this history existed at ledger height
N, and you can check it yourself". XRPL is a decent anchor: cheap, fast, permanent enough, and
one transaction can carry many roots in a memo.

Do it this way:

- Anchor `BLAKE3(anchor_secret || checkpoint_root)` with `anchor_secret` held by the vault, so
  the chain shows *a* blob was anchored at a time but does not link it to a vault or a person.
  Vault members can prove their history; the public learns nothing.
- **Batch**: one transaction per customer-visible interval (daily/weekly), not per checkpoint.
- **Opt-in per vault**, off by default, because even a salted hash is a permanent public record
  that something was anchored.
- **No change to the protocol**: a checkpoint is already an independent signed record, so an
  anchor can be attached to old checkpoints retroactively. That is why this can wait.

Cheaper alternatives that need no wallet at all: publish signed checkpoint files as GitHub
release assets, or use OpenTimestamps (free, Bitcoin-anchored). If those are enough, XRPL adds
nothing but a dependency.

## What we should not do

- No XRP token, no "sync coin", no staking, no incentive layer. None of it serves the promise.
- No wallet keys on our servers or in the vault's key material.
- No holding customer funds before there is an entity and an accountant.
- No chain writes in the sync path, ever — sync must work with no network and no money.

## The decision

1. **Anchoring**: post-v1, opt-in, and only if a real user asks for third-party timestamping.
2. **Payments**: post-entity (Jan 2027), USD-priced, processor-custodied.
3. **Now**: nothing. Recorded here so the option is not lost, and so nobody "adds XRP" to M0-M5
   and spends the June buffer on it.

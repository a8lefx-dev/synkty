# Relay: free, then what?

Status: design. Nothing built. This answers "offer a free relay like RustDesk, then a paid relay?"
and records the numbers that make the answer safe or reckless.

## What a relay is here

A relay is a dumb forwarder. Two devices cannot punch through NAT (home router, CGNAT on mobile),
so both open a QUIC connection to a third machine and it copies frames from one to the other.
It runs our protocol, not TCP: it accepts our sync frames between two **paired** device IDs and
nothing else. It never holds keys, so it never sees a note. It does see metadata — which device
IDs talked, when, and how many bytes. That is the whole privacy story and it should be written
on the tin, not discovered.

Direct-first is what keeps this cheap: QUIC hole punching succeeds on most home networks, so the
relay is the fallback for symmetric NAT and cellular CGNAT. Fallback usage is the cost driver, and
phones on LTE are the fallback.

## What RustDesk actually does (checked today, not remembered)

- **OSS server: $0 forever, self-hosted.** `hbbs` (rendezvous/ID) + `hbbr` (relay), two daemons.
- **Free public relay servers**: best-effort, community-funded, no promise.
- **Paid**: Server **Pro licenses, $11.88/mo** (1 user / 20 devices) to **$23.88/mo** (10 users /
  100 devices), +$1.20/extra user, +$0.12/extra device, +$24/extra concurrent connection.
- Their own pricing page says it plainly: *"This pricing is for self-hosting solution, it is NOT
  a SaaS subscription."* **They do not sell bandwidth.** They sell the control plane — 2FA, SSO,
  LDAP, address book, audit log, custom client generator — running on a server you rent yourself.
- Sizing from their docs: 1 CPU core + 1 GB RAM holds ~1000 concurrent relay connections. The
  relay is CPU-cheap; the bill is egress.

That is the business lesson and it is worth copying exactly: **the pipe is a commodity with
brutal margins; the control plane is the product.**

## Cost math for us (computed, not estimated)

Egress at $0.01/GB (typical cloud) and $0.005/GB (cheap egress / included traffic on a VPS).

| scenario | GB/mo | @ $0.01/GB | @ $0.005/GB |
|---|---|---|---|
| md: 100 users, 10% relayed, 50 MB/mo | 0.5 | $0.00 | $0.00 |
| md: 1,000 users, 10% relayed, 50 MB/mo | 4.9 | $0.05 | $0.02 |
| md: 10,000 users, 10% relayed, 50 MB/mo | 48.8 | $0.49 | $0.24 |
| md: 10,000 users, 25% relayed, 200 MB/mo | 488.3 | $4.88 | $2.44 |
| files: 100 users, 20% relayed, 5 GB cap | 100.0 | $1.00 | $0.50 |
| files: 1,000 users, 20% relayed, 5 GB cap | 1,000.0 | $10.00 | $5.00 |
| files: 1,000 users, 20% relayed, 20 GB cap | 4,000.0 | $40.00 | $20.00 |

Read it off the table: **text is free at any scale we will reach.** Ten thousand people syncing
markdown through our relay costs about the price of a coffee a month. The moment the relay also
carries arbitrary files, the cap becomes the business — uncapped file relay is an open CDN with
our name on it.

So the two halves of synkty have to be priced differently:
- **Notes (md)**: free relay, no quota worth arguing about (say 1 GB/mo, which nobody will hit).
- **File transfer**: free relay with a real cap (5 GB/mo) and a hard per-device rate limit.

## Abuse defence (the part that decides whether free survives)

RustDesk's own docs warn that open relays get discovered by scanners and used by strangers. Ours
is structurally harder to abuse, and that is a design choice, not luck:

1. **No generic tunnelling.** The relay forwards only our sync frame type between two device IDs.
   It cannot be used as a VPN, a proxy, a CDN, or a TCP tunnel. This is the single biggest reason
   a free relay is defensible for us and painful for a remote-desktop product.
2. **Pairing required.** Both ends must present a pairing claim signed by both device keys before
   the relay forwards a single byte. Strangers cannot borrow the relay.
3. **Per-device quotas, not per-IP.** Counters key on device ID, so rotating IPs does not buy more.
4. **Token bucket per device**: ~2 Mbit sustained, burst-friendly. Markdown sync is unaffected;
   bulk transfer feels slow enough that it is not attractive.
5. **Per-IP / per-ASN concurrency caps** on connection setup, to stop a single host from holding a
   thousand sessions.
6. **Volume-shape heuristics**, metadata only: many bytes with almost no distinct-file index, or
   one device pair saturating for hours, gets throttled. Disclosed in the privacy note because the
   relay has to look at sizes even though it cannot look at contents.
7. **Self-hosting is free forever.** Everyone who might abuse the quota is welcome to run their own
   relay instead — which is also the honest answer to "why should I trust your relay".

## Metering to build now (free), so a paid tier is possible later

Do not build billing. Build the counters, because retrofitting metering into a sync protocol is
worse than carrying it from the start:

- Relay counts bytes per device pair per day and per month in local SQLite.
- Client shows it: *"3.4 MB of 1 GB relayed this month"* on the devices screen.
- Relay exposes a signed status/quota endpoint the client can query.
- Frame header carries a session id so counters survive reconnects without double-counting.

## What "paid relay" should actually be, if it happens

Not "more bandwidth" — that competes with free self-hosting and loses. The defensible paid layer
is the one RustDesk proved: **the control plane, on a relay we run.**

- Managed relay: no server to operate, no DNS, no certificate, just works from a phone.
- Team/grant management: agent grants, per-device policy, audit of which agent wrote what.
- SSO/LDAP, custom builds, priority routing.
- Price shape, if ever: per-seat (like RustDesk's $11.88–23.88/mo), not per-gigabyte.

And the honest blocker: taking money needs business identity and a payment processor, which is a
2027 decision, not this week's. The relay itself, the metering, and the free tier are buildable
now and cost almost nothing while the users are us.

## Decisions this needs

1. **Free relay for notes only, or notes + capped files?** (Recommend: both, files capped at 5 GB/mo.)
2. **Free tier quota**: 1 GB/mo notes, 5 GB/mo files — or unlimited notes and drop the counters?
3. **Run it on the existing RackNerd box, or a separate small relay host?** (Separate is better:
   relay traffic must never compete with Legaci or the learn lane for the same pipe.)
4. **Public relay now or after M2?** Direct-only works between two machines on the same LAN, so the
   relay can wait until M2 without blocking anything.

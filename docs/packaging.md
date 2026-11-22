# Packaging and installers

Status: plan. M0 ships a CLI only (`cargo install --git`), so nobody needs an installer yet.
This is the map for M5 onward, with the constraints that actually decide the design.

## The matrix

| platform | build on | artifact | signing | distribution | the catch |
|---|---|---|---|---|---|
| Linux | this box (native) or ubuntu runner | `.AppImage`, `.deb`, tarball | optional (minisign) | direct download, later Flathub | none serious; AppImage needs FUSE or `--appimage-extract` |
| Windows | **windows-latest runner** (native) | `.msi` (WiX) or NSIS `.exe` | Authenticode OV/EV cert | direct download, later winget | cross-compiling MSVC from Linux is a trap; unsigned installers hit SmartScreen until reputation accrues |
| macOS | **macos-latest runner** (no local Mac needed) | `.dmg` / `.app` | Developer ID + **notarization** | direct download, later Homebrew cask | Gatekeeper blocks anything unsigned; notarization needs the $99 Apple account |
| Android | ubuntu runner + NDK | `.apk` + `.aab` | self-signed keystore (free) | direct APK, Google Play, possibly F-Droid | needs a **foreground service** (persistent notification) and SAF folder access; raw filesystem access is restricted |
| iOS | **macos runner only** (cloud Mac) | `.ipa` | Apple certificate + provisioning | TestFlight -> App Store, 100-device ad hoc | no long-running daemon: BGTaskScheduler, sync mostly on open; vault must live in the app container / File Provider |

The thing that costs money is not the tooling, it is the accounts: Apple Developer $99/yr
(already owned, approved 2026-07-16) and Google Play $25 once (already owned). A Windows
Authenticode certificate is the only new spend (~$250-400/yr) and it is deferrable.

## What this means for synkty specifically

- **One Rust core, several shells.** Our daemon is a library plus a CLI; the UI shells are
  Tauri v2, which builds desktop **and** mobile from one codebase (Tauri's own docs list
  iOS and Android distribution alongside Windows/macOS/Linux).
- **iOS is a different product, not a port.** iOS suspends background processes. There is no
  always-on peer. Promise "syncs when you open it, plus opportunistic background refresh",
  not Syncthing parity. This is exactly why Syncthing has no official iOS app.
- **Android needs a foreground service.** A persistent notification is the price of syncing
  while the screen is off, plus a battery-optimisation exemption prompt. Vault access goes
  through SAF (user picks the folder), never a hard-coded path.
- **Agents do not need an installer.** `cargo install --git` for the CLI, or a single static
  binary; `fald service install` writes the systemd unit / launchd plist / Scheduled Task.

## CI shape (GitHub Actions, public repo)

```
desktop   [ubuntu-latest, windows-latest, macos-latest]
          -> tauri build -> sign (per-OS) -> upload artifacts to the GitHub Release
android   [ubuntu-latest]  -> cargo-ndk + gradle -> .apk and .aab
ios       [macos-latest]   -> xcodebuild -> altool / notarytool -> TestFlight
```

- Public repos are free within GitHub's included minutes; **macOS runners meter at 10x**, so
  keep iOS builds short and cache aggressively.
- Signing material lives in repo secrets only: Apple API key (`.p8`) + team id, Android
  keystore (base64) + two passwords, Windows cert + password. Never in the repo, never in a
  chat message, never in an agent's context.

## Tools that already solve the boring parts

`cargo-dist` (packaging + release artifacts), `cargo-deb`, `cargo-appimage`, `cargo-wix`
(MSI), `cargo-ndk` (Android), `tauri-cli`. All verified present on crates.io today.

## Order of work (and why)

1. **M0** — `cargo install --git`, no installers. The only users are us.
2. **M5a Linux** — AppImage + deb, unsigned. Free, immediate, proves packaging.
3. **M5b Windows** — NSIS `.exe` first (cross-buildable), `.msi` later. Ship unsigned with a
   one-line SmartScreen note; buy the certificate when there are real users.
4. **M5c macOS** — signed `.dmg` with notarization. Needs nothing but the Apple account and CI.
5. **M6 Android** — direct `.apk` first, then Play AAB once the foreground service behaves.
6. **M7 iOS** — TestFlight. Deliberately last: it is the platform where the product promise
   changes.

## Decisions this needs from Able

1. **Windows certificate now or later?** Later is fine; early users see a SmartScreen warning.
2. **Android channels:** Play only, or also direct APK / F-Droid? F-Droid requires
   reproducible builds and no proprietary blobs.
3. **iOS shape:** companion that syncs on open (recommended) or nothing until we can do better.
4. **Auto-update:** Tauri updater with signed manifests, or manual downloads until 1.0?

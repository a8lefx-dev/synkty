//! `fald` — the synkty command line.
//!
//! M0 commands (not implemented yet):
//!   fald identity show          print this device's id and fingerprint
//!   fald identity init          create a key, refuse to overwrite an existing one
//!   fald pair offer             print a one-time code and wait on the LAN
//!   fald pair accept <code>     join the offering device
//!   fald devices                list trusted devices
//!   fald devices revoke <id>    stop trusting a device, locally and on the wire

fn main() {
    println!("fald {} (M0 not implemented yet)", env!("CARGO_PKG_VERSION"));
}

//! Device identity for synkty.
//!
//! One Ed25519 key per device, generated locally and never exported. The device id is a
//! truncated BLAKE3 hash of the public key with a check group, so it is safe to say out
//! loud, paste in a chat, or read over the phone.
//!
//! Nothing here is implemented yet: M0 lands with the first real commit. The contract is
//! in `docs/protocol.md` §1 — id format, canonical encoding, what a signature covers.

/// Human-readable length of a device id including its check group: `7F3K-2QX9-M4TB-8ZRD-1Y6C`.
pub const DEVICE_ID_DISPLAY_LEN: usize = 23;

/// Crockford base32, chosen because it has no `I`, `L`, `O` or `U`: nothing to confuse
/// with `1`, `0`, or a rude word, and it round-trips from lowercase.
pub const ALPHABET: &[u8; 32] = b"0123456789ABCDEFGHJKMNPQRSTVWXYZ";

/// Errors an id can fail with.
#[derive(Debug, PartialEq, Eq)]
pub enum IdError {
    /// Wrong number of symbols once separators are stripped.
    Length,
    /// A symbol that is not in the alphabet.
    Symbol(char),
    /// The check group does not match the payload: a typo, or a mangled paste.
    Checksum,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn alphabet_is_crockford() {
        assert_eq!(ALPHABET.len(), 32);
        for bad in [b'I', b'L', b'O', b'U'] {
            assert!(!ALPHABET.contains(&bad));
        }
    }
}

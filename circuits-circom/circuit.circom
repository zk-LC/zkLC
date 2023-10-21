pragma circom 2.1.5;

include "circomlib/circuits/poseidon.circom";
include "@zk-email/circuits/email-verifier.circom";
include "@zk-email/circuits/regexes/from_regex.circom";

template WaybillEmail(max_header_bytes, max_body_bytes, n, k, pack_size) {
    assert(n * k > 1024); // constraints for 1024 bit RSA

    signal input in_padded[max_header_bytes]; // prehashed email data, includes up to 512 + 64? bytes of padding pre SHA256, and padded with lots of 0s at end after the length
    signal input modulus[k]; // rsa pubkey, verified with smart contract + DNSSEC proof. split up into k parts of n bits each.
    signal input signature[k]; // rsa signature. split up into k parts of n bits each.
    signal input in_len_padded_bytes; // length of in email data including the padding, which will inform the sha256 block length

    // Base 64 body hash variables
    signal input body_hash_idx;
    // The precomputed_sha value is the Merkle-Damgard state of our SHA hash uptil our first regex match which allows us to save SHA constraints by only hashing the relevant part of the body
    signal input precomputed_sha[32];
    // Suffix of the body after precomputed SHA
    signal input in_body_padded[max_body_bytes];
    // Length of the body after precomputed SHA
    signal input in_body_len_padded_bytes;

    signal output modulus_hash;

    // DKIM VERIFICATION
    component EV = EmailVerifier(max_header_bytes, max_body_bytes, n, k, 0);
    EV.in_padded <== in_padded;
    EV.pubkey <== modulus;
    EV.signature <== signature;
    EV.in_len_padded_bytes <== in_len_padded_bytes;
    EV.body_hash_idx <== body_hash_idx;
    EV.precomputed_sha <== precomputed_sha;
    EV.in_body_padded <== in_body_padded;
    EV.in_body_len_padded_bytes <== in_body_len_padded_bytes;
    signal header_hash[256] <== EV.sha;

    modulus_hash <== EV.pubkey_hash;

    // FROM HEADER REGEX
    var max_email_from_packed_bytes = count_packed(max_email_from_len, pack_size);
    assert(max_email_from_packed_bytes < max_header_bytes);

    signal input email_from_idx;
    signal output reveal_email_from_packed[max_email_from_packed_bytes]; // packed into 7-bytes

    signal (from_regex_out, from_regex_reveal[max_header_bytes]) <== FromRegex(max_header_bytes)(in_padded);
    from_regex_out === 1;
    reveal_email_from_packed <== ShiftAndPack(max_header_bytes, max_email_from_len, pack_size)(from_regex_reveal, email_from_idx);

    // NULLIFIER
    
    // The following signals do not take part in any computation, but tie the proof to a specific address to prevent replay attacks and frontrunning.
    // https://geometry.xyz/notebook/groth16-malleability
    signal input address;
    signal address_squared;
    address_squared <== address * address;
}

// Args:
// * max_header_bytes = 1024 is the max number of bytes in the header
// * max_body_bytes = 6720 is the max number of bytes in the body after precomputed slice (Need to leave room for >280 char custom message)
// * n = 121 is the number of bits in each chunk of the modulus (RSA parameter)
// * k = 17 is the number of chunks in the modulus (RSA parameter)
// * pack_size = 7 is the number of bytes that can fit into a 255ish bit signal (can increase later)
component main { public [ address ] } = VenmoReceiveEmail(1024, 6720, 121, 17, 7);

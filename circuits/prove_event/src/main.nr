use dep::std::hash::poseidon;

fn main(
    current_timestamp: pub Field,
    time_delay: pub Field,
    create_timestamp: Field,
    root: pub Field,
    secret: Field,
    nullifier: Field,
    nullifier_hash: pub Field,
    proof_siblings: [Field; 32],
    proof_path_indices: [Field; 32],
) {
    // check current_timestamp - 86400 > deposit_timestamp
    // let one_day_ago = current_timestamp - 86400;
    let one_day_ago = current_timestamp - time_delay; // 10 seconds (for testing)
    let can_withdraw = create_timestamp.lt(one_day_ago);
    assert(can_withdraw);

    let hash_0 = poseidon::bn254::hash_2([secret, nullifier]);
    let leaf = poseidon::bn254::hash_2([hash_0, create_timestamp]);

    assert(nullifier_hash == poseidon::bn254::hash_1([nullifier]));

    let mut hash: Field = leaf;

    for i in 0..32 {
        if proof_path_indices[i] == 0 {
            let input: [Field; 2] = [hash, proof_siblings[i]];
            hash = poseidon::bn254::hash_2(input);
        } else {
            let input: [Field; 2] = [proof_siblings[i], hash];
            hash = poseidon::bn254::hash_2(input);
        }
    }
    assert(hash == root);
}

#[test]
fn test_main() {
    // Step 1: Set up inputs
    let current_timestamp = 1731728931; // Sat Nov 16 2024 03:48:51 GMT+0000
    let time_delay = 10; // 10 seconds
    let create_timestamp = 1731613683; // Thu Nov 14 2024 19:48:03 GMT+0000
    let nullifier = 123456789;
    let secret = 987654321;

    // Step 2: Compute the leaf hash
    let hash_0 = poseidon::bn254::hash_2([secret, nullifier]);
    let leaf = poseidon::bn254::hash_2([hash_0, create_timestamp]);

    // Step 3: Compute the nullifier hash
    let nullifier_hash: Field = poseidon::bn254::hash_1([nullifier]);

    // Step 4: Generate Merkle proof (all siblings are zeros)
    let proof_siblings: [Field; 32] = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0,
    ];
    let proof_path_indices: [Field; 32] = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0,
    ]; // All zeros (left child)
    // Step 5: Compute the root hash
    let mut hash = leaf;
    for i in 0..32 {
        if proof_path_indices[i] == 0 {
            // Current node is a left child
            hash = poseidon::bn254::hash_2([hash, proof_siblings[i]]);
        } else {
            // Current node is a right child
            hash = poseidon::bn254::hash_2([proof_siblings[i], hash]);
        }
    }
    let root = hash;

    println(root);
    println(nullifier_hash);
    println(nullifier);
    println(secret);
    println(proof_siblings);
    println(proof_path_indices);

    // Step 6: Invoke the main function
    main(
        current_timestamp,
        time_delay,
        create_timestamp,
        root,
        secret,
        nullifier,
        nullifier_hash,
        proof_siblings,
        proof_path_indices,
    );
}

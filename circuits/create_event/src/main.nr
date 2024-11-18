use dep::std::hash::poseidon;

fn main(secret: Field, nullifier: Field, timestamp: pub Field, leaf: pub Field) {
    let hash_0 = poseidon::bn254::hash_2([secret, nullifier]);
    let _leaf = poseidon::bn254::hash_2([hash_0, timestamp]);

    // assert proposed leaf matches certain constraints
    assert(_leaf == leaf);
}

#[test]
fn test_main() {
    let secret = 0;
    let nullifier = 0;
    let timestamp = 0; // Sat Nov 16 2024 04:54:06 GMT+0000

    let hash_0 = poseidon::bn254::hash_2([secret, nullifier]);
    let _leaf = poseidon::bn254::hash_2([hash_0, timestamp]);

    println(_leaf);
    
    main(secret, nullifier, timestamp, _leaf);

    let nulifier_hash = poseidon::bn254::hash_1([nullifier]);
    println(nulifier_hash);

}


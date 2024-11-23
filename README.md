# Proof of Time

## Setting up:

1) Install Noir
```
curl -L noirup.dev | bash
noirup
```

2) Install Proving Backend:
```
curl -L bbup.dev | bash
bbup
```

## Running Tests Locally:

### 1) Create Deposit proof from /deposit/Prover.toml
```
cd circuits/create_event
nargo execute
bb prove -b ./target/create_event.json -w ./target/create_event.gz -o ./target/proof
bb write_vk -b ./target/create_event.json -o ./target/vk
cd ..
cd ..
cd rust-tools
cargo run --package rust-tools --bin create_event_proof_convert 
cd ..
```

### 2) Compute nullifier hash
```
forge test --match-test test_write_nullifier
```


### 3) Get IMT root, proof siblings, and path indicies, then format /withdraw/Prover.toml
```
forge test --match-test test_create_event_proof_generate_data

cd rust-tools 
cargo run --package rust-tools  --bin prove_event_prover_formatter
cd ..
```

### 4) Create withdraw proof, convert to hex, run test
```
cd circuits/prove_event
nargo execute
bb prove -b ./target/prove_event.json -w ./target/prove_event.gz -o ./target/proof
bb write_vk -b ./target/prove_event.json -o ./target/vk
cd ..
cd ..

cd rust-tools
cargo run --package rust-tools --bin prove_event_proof_convert
cd ..

forge test --match-test test_prove_event_proof 
```

### RUNNING THE FRONTEND:
1) deploy contracts & run anvil
```
anvil --accounts 10 --timestamp $(date +%s) --block-time 5

```
2) in new terminal deploy the vault & verifier contracts:
```
forge script script/Deploy.s.sol --fork-url http://127.0.0.1:8545 --private-key 2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6 --broadcast
```


### Full DEMO Commands:

### 1) Create Deposit proof from /deposit/Prover.toml
```
cd circuits/deposit
nargo execute
bb prove -b ./target/deposit.json -w ./target/deposit.gz -o ./target/proof
bb write_vk -b ./target/deposit.json -o ./target/vk
cd ..
cd ..
cd tornado-cli 
cargo run --package tornado-cli --bin deposit_proof_convert 
cd ..

forge test --match-test test_write_nullifier
```

```
sleep 11

forge test --match-test test_deposit_proof_vault_generate_data

cd tornado-cli
cargo run --package tornado-cli --bin withdraw_prover_formatter
cd ..
```

### 2) Create Withdraw Proof

```
cd circuits/withdraw
nargo execute
bb prove -b ./target/withdraw.json -w ./target/withdraw.gz -o ./target/proof
bb write_vk -b ./target/withdraw.json -o ./target/vk
cd ..
cd ..

cd tornado-cli
cargo run --package tornado-cli --bin withdraw_proof_convert
cd ..

forge test --match-test test_withdraw_proof
```

forge test --match-test test_withdraw_proof 

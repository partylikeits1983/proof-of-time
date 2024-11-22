// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {CryptoTools} from "../src/CryptoTools.sol";

import {BinaryIMTData} from "../src/libraries/InternalBinaryIMT.sol";
import {PoseidonT2} from "../src/libraries/PoseidonT2.sol";
import {PoseidonT3} from "../src/libraries/PoseidonT3.sol";

import {UltraVerifier as CreateEventVerifier} from "../../circuits/create_event/target/contract.sol";
import {UltraVerifier as ProveEventVerifier} from "../../circuits/prove_event/target/contract.sol";

import {ConvertBytes32ToString} from "../src/libraries/Bytes32ToString.sol";

import {ProofOfTime} from "../src/ProofOfTime.sol";

contract CryptographyTest is Test, ConvertBytes32ToString {
    CryptoTools public hasher;

    CreateEventVerifier public createEventVerifier;
    ProveEventVerifier public proveEventVerifier;
    ProofOfTime public proofOfTime;

    function setUp() public {
        hasher = new CryptoTools();
        createEventVerifier = new CreateEventVerifier();
        proveEventVerifier = new ProveEventVerifier();
        proofOfTime = new ProofOfTime(address(createEventVerifier), address(proveEventVerifier));
    }

    function test_hash() public view {
        uint256 result = hasher.hash2(1, 2);
        console.log("result: %d", result);

        bytes32 value = bytes32(result);
        console.logBytes32(value);
    }

    function test_IMTinsert() public {
        (uint256 depth, uint256 root, uint256 numberOfLeaves,) = hasher.binaryIMTData();

        console.log("root: %d", root);
        console.log("depth: %d", depth);
        console.log("numberOfLeaves: %d", numberOfLeaves);
        hasher.insert(1);

        (depth, root, numberOfLeaves,) = hasher.binaryIMTData();
        console.log("root: %d", root);
        console.log("depth: %d", depth);
        console.log("numberOfLeaves: %d", numberOfLeaves);
    }

    function test_IMT_insertVerify() public {
        (uint256 depth, uint256 root, uint256 numberOfLeaves,) = hasher.binaryIMTData();
        console.log("Initial state - depth: %d, numberOfLeaves: %d", depth, numberOfLeaves);

        uint256 leafValue = 1;
        hasher.insert(leafValue);

        (depth, root, numberOfLeaves,) = hasher.binaryIMTData();
        console.log("After insertion - depth: %d, numberOfLeaves: %d", depth, numberOfLeaves);

        (uint256[] memory proofSiblings, uint8[] memory proofPathIndices) = hasher.createProof(0);

        console.log("leafValue: %d", leafValue);

        console.log("root: %d", root);

        console.log("Proof siblings:");
        for (uint256 i = 0; i < proofSiblings.length; i++) {
            console.logBytes32(bytes32(proofSiblings[i]));
        }

        console.log("Proof path indices:");
        for (uint256 i = 0; i < proofPathIndices.length; i++) {
            console.logBytes32(bytes32(uint256(proofPathIndices[i])));
        }

        require(hasher.verify(leafValue, proofSiblings, proofPathIndices), "failed");
        console.log("Leaf %d verified successfully.", leafValue);
    }

    function test_write_nullifier() public {
        // generate nullifier_hash from nullifier

        // Path to the Prover.toml file
        string memory filePath = "circuits/create_event/Prover.toml";

        // Read the entire file content
        string memory fileContent = vm.readFile(filePath);

        // Define the key we're looking for
        string memory key = "nullifier = \"";
        bytes memory keyBytes = bytes(key);

        // Convert file content to bytes for processing
        bytes memory contentBytes = bytes(fileContent);

        // Find the starting index of the key
        uint256 startIndex = findSubstring(contentBytes, keyBytes, 0);
        require(startIndex != type(uint256).max, "nullifier key not found");

        // Calculate the starting position of the value
        uint256 valueStart = startIndex + keyBytes.length;
        require(valueStart < contentBytes.length, "Invalid file format");

        // Find the closing quote of the value
        uint256 valueEnd = valueStart;
        while (valueEnd < contentBytes.length && contentBytes[valueEnd] != '"') {
            valueEnd++;
        }
        require(valueEnd < contentBytes.length, "Closing quote not found");

        // Extract the nullifier value
        bytes memory nullifierBytes = new bytes(valueEnd - valueStart);
        for (uint256 i = 0; i < valueEnd - valueStart; i++) {
            nullifierBytes[i] = contentBytes[valueStart + i];
        }
        uint256 nullifier = stringToUint(string(nullifierBytes));

        // Output the nullifier value
        console.log("Nullifier:", nullifier);

        bytes32 nullifier_hash = bytes32(PoseidonT2.hash([nullifier]));

        vm.writeFile("data/prove_event_nullifier_hash.txt", bytes32ToString(nullifier_hash));
    }

    function test_create_event_proof_generate_data() public {
        // public inputs
        string memory timestamp = vm.readLine("./data/create_event_timestamp.txt");
        string memory leaf = vm.readLine("./data/create_event_leaf.txt");

        // proof
        string memory proof = vm.readLine("./data/create_event_proof.txt");
        bytes memory proofBytes = vm.parseBytes(proof);

        // public inputs
        bytes32[] memory publicInputs = new bytes32[](2);
        publicInputs[0] = stringToBytes32(timestamp);
        publicInputs[1] = stringToBytes32(leaf);

        uint256 currentTimestamp = 1732276090; // Fri Nov 15 2024 04:54:06 GMT+0000
        vm.warp(currentTimestamp);

        uint256 leafIndex = proofOfTime.createEvent(proofBytes, publicInputs);

        (, uint256 root,,) = proofOfTime.binaryIMTData();

        // Generate Data for Withdraw Proof
        (uint256[] memory proofSiblings, uint8[] memory proofPathIndices) = proofOfTime.createProof(leafIndex);

        vm.writeFile("data/root.txt", bytes32ToString(bytes32(root)));

        vm.writeFile("data/proof_siblings.txt", "");
        vm.writeFile("data/proof_path_indices.txt", "");

        for (uint256 i = 0; i < proofSiblings.length; i++) {
            string memory path = "data/proof_siblings.txt";
            vm.writeLine(path, bytes32ToString(bytes32(proofSiblings[i])));
        }

        for (uint256 i = 0; i < proofPathIndices.length; i++) {
            string memory path = "data/proof_path_indices.txt";
            vm.writeLine(path, bytes32ToString(bytes32(uint256(proofPathIndices[i]))));
        }
    }

    function test_prove_event_proof() public view {
        string memory proof = vm.readLine("./data/prove_event_proof.txt");
        bytes memory proofBytes = vm.parseBytes(proof);

        string memory current_timestamp = vm.readLine("./data/prove_event_current_timestamp.txt");
        string memory root = vm.readLine("./data/prove_event_root.txt");
        string memory nullifier_hash = vm.readLine("./data/prove_event_nullifier_hash.txt");

        console.log(current_timestamp);
        console.log(root);
        console.log(nullifier_hash);

        bytes32[] memory publicInputs = new bytes32[](3);
        publicInputs[0] = stringToBytes32(current_timestamp);
        publicInputs[1] = stringToBytes32(root);
        publicInputs[2] = stringToBytes32(nullifier_hash);

        console.log("checking zk proof");
        proveEventVerifier.verify(proofBytes, publicInputs);
        console.log("verified");
    }

    function test_create_and_prove() public {
        // public inputs
        string memory create_event_timestamp = vm.readLine("./data/create_event_timestamp.txt");
        string memory create_event_leaf = vm.readLine("./data/create_event_leaf.txt");

        // proof
        string memory create_event_proof = vm.readLine("./data/create_event_proof.txt");
        bytes memory create_event_proofBytes = vm.parseBytes(create_event_proof);

        // public inputs
        bytes32[] memory create_event_public_inputs = new bytes32[](2);
        create_event_public_inputs[0] = stringToBytes32(create_event_timestamp);
        create_event_public_inputs[1] = stringToBytes32(create_event_leaf);

        uint256 currentTimestamp = 1731646446; // Fri Nov 15 2024 04:54:06 GMT+0000
        vm.warp(currentTimestamp);

        proveEventVerifier.verify(create_event_proofBytes, create_event_public_inputs);

        // Simulate deposit from an address
        address depositor = vm.addr(1);
        vm.deal(depositor, 1e18);
        vm.startPrank(depositor);

        proofOfTime.createEvent(create_event_proofBytes, create_event_public_inputs);
        vm.stopPrank();

        string memory prove_event_proof = vm.readLine("./data/prove_event_proof.txt");
        bytes memory prove_event_proofBytes = vm.parseBytes(prove_event_proof);

        string memory prove_event_current_timestamp = vm.readLine("./data/prove_event_current_timestamp.txt");
        string memory prove_event_root = vm.readLine("./data/prove_event_root.txt");
        string memory prove_event_nullifier_hash = vm.readLine("./data/prove_event_nullifier_hash.txt");

        console.log(prove_event_root);
        console.log(prove_event_nullifier_hash);

        bytes32[] memory publicInputs = new bytes32[](3);
        publicInputs[0] = stringToBytes32(prove_event_current_timestamp);
        publicInputs[1] = stringToBytes32(prove_event_root);
        publicInputs[2] = stringToBytes32(prove_event_nullifier_hash);

        uint256 timestamp = 1731747190; // Sat Nov 16 2024 08:53:10 GMT+0000
        vm.warp(timestamp);

        console.log("checking zk proof");
        createEventVerifier.verify(prove_event_proofBytes, publicInputs);
        console.log("verified");

        // Simulate withdrawal from another address
        address withdrawer = vm.addr(2);
        vm.startPrank(withdrawer);
        proofOfTime.proveEvent(prove_event_proofBytes, publicInputs);
        vm.stopPrank();
    }
}

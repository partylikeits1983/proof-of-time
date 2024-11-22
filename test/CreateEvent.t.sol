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

    function test_create_event_proof() public view {
        // public inputs
        string memory timestamp = vm.readLine("./data/create_event_timestamp.txt");
        string memory leaf = vm.readLine("./data/create_event_leaf.txt");

        console.log("HERE");
        console.log(timestamp);
        console.log(leaf);

        // proof
        string memory proof = vm.readLine("./data/create_event_proof.txt");
        bytes memory proofBytes = vm.parseBytes(proof);

        // public inputs
        bytes32[] memory publicInputs = new bytes32[](2);
        publicInputs[0] = stringToBytes32(timestamp);
        publicInputs[1] = stringToBytes32(leaf);

        createEventVerifier.verify(proofBytes, publicInputs);
    }

    function test_create_event_proof_vault() public {
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

        uint256 currentTimestamp = 1731646446; // Fri Nov 15 2024 04:54:06 GMT+0000
        vm.warp(currentTimestamp);

        proofOfTime.createEvent(proofBytes, publicInputs);
    }

    function test_create_event_fails() public {
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

        uint256 currentTimestamp = 1731646446; // Fri Nov 15 2024 04:54:06 GMT+0000
        vm.warp(currentTimestamp);

        proofOfTime.createEvent(proofBytes, publicInputs);
    }
}

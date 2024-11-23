// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CryptoTools} from "./CryptoTools.sol";
import {UltraVerifier as CreateEventVerifier} from "../../circuits/create_event/target/contract.sol";
import {UltraVerifier as ProveEventVerifier} from "../../circuits/prove_event/target/contract.sol";

import {Test, console} from "forge-std/Test.sol";

contract ProofOfTime is CryptoTools {
    CreateEventVerifier public createEventVerifier;
    ProveEventVerifier public proveEventVerifier;

    mapping(uint256 => bool) public nullifier_hashes;

    // @dev storing last 32 IMT roots
    uint256[32] public roots;
    uint8 public nextRootIndex;

    constructor(address _createEventVerifier, address _proveEventVerifier) CryptoTools() {
        createEventVerifier = CreateEventVerifier(_createEventVerifier);
        proveEventVerifier = ProveEventVerifier(_proveEventVerifier);
    }

    function createEvent(bytes memory proof, bytes32[] memory publicInputs) public returns (uint256 leafIndex) {
        uint256 timestamp = uint256(publicInputs[0]);
        uint256 leaf = uint256(publicInputs[1]);

        // Ensure that the current block.timestamp is less than the provided timestamp
        require(block.timestamp < timestamp, "deposit timestamp >= block.timestamp");

        // Verify the proof with the given public inputs
        createEventVerifier.verify(proof, publicInputs);

        // Insert the leaf into the cryptographic tree
        CryptoTools.insert(leaf);

        // @dev Append the new IMT root during the deposit
        uint256 newRoot = binaryIMTData.root;
        roots[nextRootIndex] = newRoot;
        nextRootIndex = (nextRootIndex + 1) % 32;

        // Return the new leaf index
        return CryptoTools.leafCount - 1;
    }

    function proveEvent(bytes memory proof, bytes32[] memory publicInputs) public {
        uint256 current_timestamp = uint256(publicInputs[0]);
        uint256 root = uint256(publicInputs[1]);
        uint256 nullifier_hash = uint256(publicInputs[2]);

        console.log(current_timestamp);
        console.log(block.timestamp);
        require(block.timestamp > current_timestamp, "please wait");

        require(nullifier_hashes[nullifier_hash] == false, "hash already used");

        // @dev Check if the root in the withdraw function is in 1 of the last 32 IMT roots
        bool rootIsValid = false;
        for (uint8 i = 0; i < 32; i++) {
            if (roots[i] == root) {
                rootIsValid = true;
                break;
            }
        }
        require(rootIsValid, "Invalid root");

        // Verify the proof with the given public inputs
        proveEventVerifier.verify(proof, publicInputs);

        // Mark the nullifier as used
        nullifier_hashes[nullifier_hash] = true;
    }

    // Fallback function to accept ETH (if needed for future implementations)
    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {ProofOfTime} from "../src/ProofOfTime.sol";
import {UltraVerifier as CreateEventVerifier} from "../../circuits/create_event/target/contract.sol";
import {UltraVerifier as ProveEventVerifier} from "../../circuits/prove_event/target/contract.sol";

contract ProofOfTime_Deploy is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy verifiers
        CreateEventVerifier createEventVerifier = new CreateEventVerifier();
        ProveEventVerifier proveEventVerifier = new ProveEventVerifier();

        // Set the maximum gas price for the next transaction (Vault deployment)
        uint256 maxGasPrice = 1e18; // Adjust this value as needed
        vm.txGasPrice(maxGasPrice);

        // Deploy the ProofOfTime contract with the specified gas price
        ProofOfTime proofOfTime = new ProofOfTime(address(createEventVerifier), address(proveEventVerifier));

        console.log("ProofOfTime deployed at:", address(proofOfTime));
        console.log("CreateEventVerifier deployed at:", address(createEventVerifier));
        console.log("ProveEventVerifier deployed at:", address(proveEventVerifier));

        vm.stopBroadcast();
    }
}

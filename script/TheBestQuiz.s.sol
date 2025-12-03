// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {the_BEST_Quiz} from "../src/TheBestQuiz.sol";

contract QuizScript is Script {
    the_BEST_Quiz public quiz;

    function run() public {
        vm.startBroadcast();

        // 1. Prepare the admin array for the constructor
        // The contract expects the admin's address to be hashed via keccak256(abi.encodePacked(address))
        bytes32[] memory admins = new bytes32[](1);
        admins[0] = keccak256(abi.encodePacked(msg.sender));

        // 2. Deploy with the arguments
        quiz = new the_BEST_Quiz(admins);

        vm.stopBroadcast();
    }
}

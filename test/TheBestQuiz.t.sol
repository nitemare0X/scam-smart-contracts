// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {the_BEST_Quiz} from "../src/TheBestQuiz.sol";

contract QuizHoneypotTest is Test {
    the_BEST_Quiz quiz;
    address attacker = address(0xBAD); // The Scam Admin
    address victim = address(0x123);   // The unsuspecting user

    function setUp() public {
        // 1. Attacker deploys contract
        vm.startPrank(attacker);
        
        bytes32[] memory admins = new bytes32[](1);
        admins[0] = keccak256(abi.encodePacked(attacker));
        
        quiz = new the_BEST_Quiz(admins);
        vm.stopPrank();
    }

    function test_HoneypotMechanics() public {
        console.log("-------------------------------------------------------");
        console.log("--- [START] Testing Honeypot Mechanics ---");

        // --- STEP 1: Attacker Setup ---
        vm.startPrank(attacker, attacker);

        // Attacker sets the REAL answer secretly
        bytes32 secretHash = keccak256(abi.encode("IMPOSSIBLE"));
        quiz.New("Rainbows?", secretHash);
        console.log("[Attacker] Called New() (Hidden). Secret Answer: 'IMPOSSIBLE'");

        // Attacker sends the BAIT transaction
        // They send 40 ETH and a FAKE answer "EasyAnswer"
        vm.deal(attacker, 50 ether);
        quiz.Start{value: 40 ether}("Rainbows?", "EasyAnswer");
        console.log("[Attacker] Called Start() (Visible). Bait Answer: 'EasyAnswer'");
        console.log("[Contract] Current Balance: %s ETH", address(quiz).balance / 1 ether);
        
        vm.stopPrank();

        // --- STEP 2: Victim Interaction ---
        vm.deal(victim, 10 ether);
        uint256 balanceBefore = victim.balance;

        console.log("-------------------------------------------------------");
        console.log("[Victim] Sees 'EasyAnswer' on Etherscan.");
        console.log("[Victim] Initial Balance: %s ETH", balanceBefore / 1 ether);
        console.log("[Victim] Calling Try('EasyAnswer') with 1.1 ETH...");

        // Simulate victim (setting msg.sender AND tx.origin)
        vm.startPrank(victim, victim); 
        
        // Victim tries the bait answer
        quiz.Try{value: 1.1 ether}("EasyAnswer");

        vm.stopPrank();

        // --- STEP 3: Results ---
        console.log("-------------------------------------------------------");
        console.log("[Result] Victim Balance:   %s ETH (Lost 1.1 ETH)", victim.balance / 1 ether);
        console.log("[Result] Contract Balance: %s ETH (Now holds 41.1 ETH)", address(quiz).balance / 1 ether);

        // Assertions
        assertEq(victim.balance, balanceBefore - 1.1 ether, "Victim should lose funds");
        assertEq(address(quiz).balance, 41.1 ether, "Contract should keep funds");
        
        console.log("--- [SUCCESS] Honeypot trap executed successfully ---");
        console.log("-------------------------------------------------------");
    }

    function test_MainnetForkExploit() public {
        // 1. Fork the state of Ethereum Mainnet
        // Note: Ensure you pass --rpc-url in your command line
        // vm.createSelectFork("https://eth.llamarpc.com"); 
        
        // 2. The Address of the Scam Contract
        // FIXED: Correct Checksum (Capital 'F' in 7Fc8850)
        address scamContract = 0xE1C46c921b79Ae1782f95fe627Fc8850e973ba58;
        
        // 3. Verify the Hash matches what we found via CAST
        bytes32 realHash = vm.load(scamContract, bytes32(uint256(1))); // Slot 1
        console.logBytes32(realHash);
        
        // Assert the hash is the one we found (0xf152...)
        assertEq(realHash, 0xf152950bed091c9854229d3eecb07fae4c84127704751a692c8409543dc02bd3);

        // 4. Prove "letteR W" is the WRONG answer
        bytes32 baitHash = keccak256(abi.encode(" letteR W "));
        console.log("Bait Hash:", vm.toString(baitHash));
        
        assertTrue(realHash != baitHash, "The real lock should NOT match the bait answer");
        
        // 5. Simulate a Victim trying to pay
        // FIXED: Renamed to 'forkVictim' to avoid shadowing global variable
        address forkVictim = address(0xABC);
        vm.deal(forkVictim, 10 ether);
        
        // FIXED: Set both msg.sender and tx.origin to pass the check
        vm.startPrank(forkVictim, forkVictim);
        
        // Try to call it with the bait answer
        (bool success, ) = scamContract.call{value: 2 ether}(
            abi.encodeWithSignature("Try(string)", " letteR W ")
        );
        
        // The call succeeds (no revert), but we don't get money back
        require(success, "Transaction should not revert (it just fails silently)");
        assertEq(forkVictim.balance, 8 ether, "Victim lost 2 ETH");
        
        vm.stopPrank();
    }
}

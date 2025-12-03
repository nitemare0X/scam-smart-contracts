# Case Study: "The BEST Quiz" Honeypot and look into scam contracts.

**Status:** CONFIRMED SCAM  
**Target:** Ethereum Mainnet  
**Contract:** [`0xE1C46c921b79Ae1782f95fe627Fc8850e973ba58`](https://etherscan.io/address/0xE1C46c921b79Ae1782f95fe627Fc8850e973ba58)  
**Balance:** ~40 ETH (At time of analysis)

*similar constract:*
**Contract:** [`0x7777fe71ef56ec1dab003e77516fa2e6e1e0c877`](https://etherscan.io/address/0x7777fe71ef56ec1dab003e77516fa2e6e1e0c877) which moved to [`0x7777915EFD4fa386104914C264242d40ec4B451A`](https://etherscan.io/address/0x7777915EFD4fa386104914C264242d40ec4B451A)   
**Balance:** 0.1 ETH  (At time of analysis)


## Overview

This repository contains a security analysis and reproduction of a sophisticated "Bait and Switch" honeypot discovered on Ethereum.

The contract presents itself as a CTF (Capture The Flag) riddle game. It holds a large balance (~40 ETH) and challenges users to send the correct answer to the question: *"What is at the end of a rainbow?"*.

While the transaction history suggests the answer is `" letteR W "`, the contract is rigged to ignore this answer, permanently locking victim funds.

## The Deception (How it Works)

The scam exploits a discrepancy between **Visible Transaction History** and **Actual Contract State**.

### 1. The Code Logic
The contract has a `Start` function intended to initialize the quiz. Crucially, it only sets the secret hash if the hash is currently empty (`0x0`).

```solidity
function Start(string calldata _question, string calldata _response) public payable isAdmin {
    // CRITICAL: This block only runs if responseHash is 0
    if(responseHash == 0x0) { 
        responseHash = keccak256(abi.encode(_response));
        question = _question;
    }
}
```

### 2. The Setup (The Bait)
The attacker performs the following sequence:

1.  **Hidden Initialization (`New`):** The attacker uses an *Internal Transaction* (via another contract) to call `New()`. This sets `responseHash` to a secret value (e.g., hash of "IMPOSSIBLE").
    *   *Note:* Internal transactions do not appear on the main Etherscan transaction list, but instead the internal transactions list having to toggle advanced mode, making this step invisible to casual users.
2.  **Visible Bait (`Start`):** The attacker calls `Start()` with 40 ETH and the fake answer `" letteR W "`.
    *   Because `responseHash` was set in Step 1, the `if(responseHash == 0x0)` check fails.
    *   The code inside the block **is skipped**.
    *   The 40 ETH is deposited, but the password remains the secret one from Step 1.

### 3. The Trap
Users see the `Start` transaction on Etherscan with the input `" letteR W "`. They assume this is the correct answer. When they call `Try(" letteR W ")`, the hash mismatch causes the transfer to fail, but since the function doesn't revert (it uses an `if`), the contract keeps their ETH.

## Forensic Evidence

We confirmed this behavior by analyzing storage slots and internal transactions on Mainnet.

### 1. The Internal Transaction
The attacker called `New` via an internal message call before calling `Start`.
*   **Tx Hash:** `0xc1f33e94a858efaaa1836de5517e43bf50d4f43f0b4cb65668a7a682ccd78fb7`
*   **Method:** `New(string, bytes32)`

### 2. Storage Slot Verification
Using `cast`, we read the storage slot for `responseHash` (Slot 1) on the live contract.

```bash
cast storage 0xE1C46c921b79Ae1782f95fe627Fc8850e973ba58 1 --rpc-url https://eth.llamarpc.com
```

**Result:** `0xf152950bed091c9854229d3eecb07fae4c84127704751a692c8409543dc02bd3`

**Verification:**
The hash of the bait answer `" letteR W "` is `0xf5a6...`.
The fact that the stored hash (`0xf152...`) does not match the bait hash proves the contract is rigged.

```bash
chisel
Welcome to Chisel! Type `!help` to show available commands.
➜ keccak256(abi.encode(" letteR W "))
Type: bytes32
└ Data: 0xf5a6f3657e435b6aac259ea812be018ac5561bccc1a0382b24928c3bb2516b40
```

## Reproduction & Testing

This repository includes Foundry tests that simulate the attack locally and fork Mainnet to prove the exploit against the live contract.

### Prerequisites
*   [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Installation
```bash
forge init --force
```

### Running the Tests

**1. Test Local Mechanics:**
Simulates the "Bait and Switch" flow locally.
```bash
forge test -vv --mt test_HoneypotMechanics
```

**2. Test Against Mainnet Fork:**
Forks the live Ethereum state and asserts that the real contract is indeed locked with a secret hash.
```bash
forge test -vv --mt test_MainnetForkExploit --rpc-url https://eth.llamarpc.com
```

## ⚠️ Disclaimer
This repository is for **educational and defensive research purposes only**. The code analyzes an existing scam contract to understand its mechanics. DO NOT interact with the actual contract (`0xE1C4...`) on Mainnet. DO NOT send funds to it.

---
*Analysis performed by Carlos*

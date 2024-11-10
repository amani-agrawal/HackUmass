// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DigitalCardAccess {    
    bytes32 public storedHash;

    event HashStored(bytes32 indexed hash);

    function storeHash(string memory _netId, string memory _locationHash) public {
        bytes32 hash = sha256(abi.encodePacked(_netId, _locationHash));
        
        storedHash = hash;

        emit HashStored(hash);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract LoginSystem {
    mapping(address => bool) public registeredUsers;

    event UserRegistered(address user);

    function register(address userAddress) public {
        require(!registeredUsers[userAddress], "User already registered.");
        registeredUsers[userAddress] = true;
        emit UserRegistered(userAddress);
    }

    function verifyLogin(address user, uint256 nonce, bytes memory signature) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(user, nonce);
        address recoveredAddress = recoverSigner(messageHash, signature);
        return recoveredAddress == user;
    }

    function getMessageHash(address user, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(user, nonce));
    }

    function recoverSigner(bytes32 messageHash, bytes memory signature) public pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        return ecrecover(messageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65, "Invalid signature length");
        assembly {
            r := mload(add(sig, 0x20))
            s := mload(add(sig, 0x40))
            v := byte(0, mload(add(sig, 0x60)))
        }
    }
}

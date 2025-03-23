// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract loginsystem {
    struct User {
        bytes32 passwordHash;
        address userAddress;
    }

    mapping(address => User) private users;

    event UserRegistered(address user);

    function register(string memory password) public {
        require(users[msg.sender].userAddress == address(0), "User already registered");
        bytes32 passwordHash = keccak256(abi.encodePacked(password));
        users[msg.sender] = User({
            passwordHash: passwordHash,
            userAddress: msg.sender
        });
        emit UserRegistered(msg.sender);
    }

    function login(string memory password) public view returns (bool) {
        bytes32 passwordHash = keccak256(abi.encodePacked(password));
        return users[msg.sender].passwordHash == passwordHash;
    }

    function isUserRegistered() public view returns (bool) {
        return users[msg.sender].userAddress != address(0);
    }
}

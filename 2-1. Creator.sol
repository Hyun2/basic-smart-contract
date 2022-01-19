// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

contract A {
    address public owner;

    constructor(address eoa) {
        owner = eoa;
    }
}

contract Creator {
    A[] public deployedA;

    function deployA() public {
        A newA = new A(msg.sender);
        deployedA.push(newA);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

contract Lottery {
    address payable[] public players;
    address public manager;

    constructor() {
        manager = msg.sender;
    }

    receive() external payable {
        require(
            msg.value == 0.1 ether,
            "you can send 0.1 ether per transaction."
        );
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint256) {
        require(msg.sender == manager, "You're not the manager.");
        return address(this).balance;
    }

    function random() public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.number,
                        block.gaslimit,
                        block.timestamp,
                        block.difficulty,
                        players.length,
                        address(this).balance
                    )
                )
            );
    }

    function pickWinner() public {
        require(msg.sender == manager, "You're not the manager.");
        uint256 index = random() % players.length;
        players[index].transfer(getBalance());

        players = new address payable[](0);
    }
}

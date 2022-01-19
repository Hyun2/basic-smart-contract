// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

contract AuctionCreator {
    Auction[] public deployedAuctions;

    function createAuction() public {
        Auction newAuction = new Auction(msg.sender);
        deployedAuctions.push(newAuction);
    }
}

contract Auction {
    address payable owner;

    string public ipfsHash;

    uint256 public highestBindingBid;
    address payable public highestBidder;
    mapping(address => uint256) public bids;

    uint256 public startBlock;
    uint256 public endBlock;

    enum State {
        Running,
        Started,
        Ended,
        Canceled
    }
    State public auctionState;

    uint256 public bidIncrement;

    constructor(address eoa) {
        owner = payable(eoa);
        startBlock = block.number;
        endBlock = block.number + 3; // test
        // endBlock = block.number + 40320; // 1 week
        auctionState = State.Running;
        ipfsHash = "";
        bidIncrement = 1000000000000000000;
        // bidIncrement = 100;
    }

    modifier onlyOwner() {
        require(
            owner == payable(msg.sender),
            "You're not the owner. Only the owner can execute this function."
        );
        _;
    }

    modifier notOwner() {
        require(
            owner != payable(msg.sender),
            "You're the owner. The owner can't execute this function."
        );
        _;
    }

    modifier betweenStartAndEnd() {
        require(startBlock <= block.number);
        require(endBlock >= block.number);
        _;
    }

    function cancelAuction() public onlyOwner {
        auctionState = State.Canceled;
    }

    function min(uint256 a, uint256 b) public pure returns (uint256) {
        if (a > b) {
            return b;
        } else {
            return a;
        }
    }

    function placeBid() public payable notOwner betweenStartAndEnd {
        require(auctionState == State.Running, "State is not running");
        require(msg.value >= 100, "msg.value >= 100 Error");

        uint256 currentBid = bids[msg.sender] + msg.value;
        require(
            currentBid > highestBindingBid,
            "currentBid > highestBindingBid Error"
        );

        bids[msg.sender] = currentBid;

        if (currentBid > bids[highestBidder]) {
            highestBindingBid = min(
                currentBid,
                bids[highestBidder] + bidIncrement
            );
            highestBidder = payable(msg.sender);
        } else {
            highestBindingBid = min(
                currentBid + bidIncrement,
                bids[highestBidder]
            );
        }
    }

    function finalize() public payable {
        require(
            auctionState == State.Canceled || block.number > endBlock,
            "auctionState == State.Canceled || block.number > endBlock Error"
        );
        require(
            msg.sender == owner || bids[msg.sender] > 0,
            "msg.sender == owner || bids[msg.sender] > 0 Error"
        );

        address payable recipient;
        uint256 value;

        if (auctionState == State.Canceled) {
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else {
            if (msg.sender == owner) {
                recipient = owner;
                value = highestBindingBid;
            } else {
                if (msg.sender == highestBidder) {
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                } else {
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }

        recipient.transfer(value);
        bids[recipient] = 0;
    }
}
// 사용자의 인터렉션에 의해 여러 개의 컨트랙트를 각각 deploy할 때
// 사용자가 여러 개의 Auction 컨트랙트를 배포하여 여러 물건을 판매할 수 있다.
// 1. 바이트 코드를 이용해서 프론트에서 바로 delploy
//    : 메타마스크를 통해서 사용자에게 승인을 받는 과정에서 바이트 코드를 사용자가 볼 수 있고,
//      바이트 코드가 수정되어 원치않는 형태의 스마트 컨트랙트가 생성될 수 있다.
//      (예를 들어 owner만 호출할 수 있는 함수를 owner가 아닌 사용자도 호출할 수 있게 된다던가 하는...)
// 2. 컨트랙트를 생성하는 별도의 컨트랙트를 따로 두고 해당 컨트랙트에서 deploy
//    : 바이트 코드가 노출되지 않기 때문에 덜 위험하다.

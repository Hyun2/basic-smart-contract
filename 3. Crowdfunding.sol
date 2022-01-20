// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

contract Crowdfunding {
    mapping(address => uint256) public contributors;
    address public admin;
    uint256 public numOfContributors;
    uint256 public minContribution;
    uint256 public deadline;
    uint256 public goal;
    uint256 public raisedAmount;

    struct Request {
        string description;
        address payable recipient;
        uint256 value;
        bool completed;
        uint256 numOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint256 => Request) public requests;

    uint256 public numOfRequests = 0;

    constructor(uint256 _goal, uint256 _deadline) {
        admin = msg.sender;
        minContribution = 100 wei;
        deadline = block.timestamp + _deadline;
        goal = _goal;
    }

    event ContributeEvent(address _contributor, uint256 _value);
    event CreateRequestEvent(
        string _description,
        address _recipient,
        uint256 _value
    );
    event MakePaymentEvent(address _recipient, uint256 _value);

    function contribute() public payable {
        require(block.timestamp < deadline, "Deadline has passed."); // deadline is seconds.
        require(msg.value >= minContribution, "Minimum Contribution not met.");

        if (contributors[msg.sender] == 0) {
            numOfContributors++;
        }

        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    receive() external payable {
        contribute();
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getRefund() public payable {
        require(goal > raisedAmount && deadline > block.timestamp);
        require(contributors[msg.sender] > 0);

        payable(msg.sender).transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
        numOfContributors -= 1;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function createRequest(
        string memory _description,
        address payable _recipient,
        uint256 _value
    ) public onlyAdmin {
        Request storage newRequest = requests[numOfRequests];
        numOfRequests++;

        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.numOfVoters = 0;
        newRequest.completed = false;
    }

    function voteRequest(uint256 _requestNo) public {
        require(contributors[msg.sender] > 0);
        Request storage thisRequest = requests[_requestNo];

        require(thisRequest.voters[msg.sender] == false);
        require(thisRequest.completed == false);
        thisRequest.voters[msg.sender] = true;
        thisRequest.numOfVoters++;
    }

    function makePayment(uint256 _requestNo) public payable onlyAdmin {
        require(raisedAmount >= goal && deadline > block.timestamp);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false);
        require(thisRequest.numOfVoters > numOfContributors / 2);

        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}

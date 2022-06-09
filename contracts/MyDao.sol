//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IErc20.sol";
import "./interfaces/IMintable.sol";

contract MyDao {

    address public chairman;
    address public token;
    Proposal[] public proposals;
    uint256 public minimumQuorum;
    uint256 public duration;
    mapping(address => uint256) public balances;
    mapping(uint256 => mapping(address => bool)) public voted;

    struct Proposal {
        string description;
        address recipient;
        bytes callData;
        uint256 startTime;
        uint256 votesYes;
        uint256 votesNo;
        bool finished;
    }

    modifier onlyChairman {
        require(msg.sender == chairman, "Only chairman allowed");
        _;
    }

    constructor(address _chairman, address _token, uint256 _minimumQuorum, uint256 _duration) {
        chairman = _chairman;
        token = _token;
        minimumQuorum = _minimumQuorum;
        duration = _duration;
    }

    function deposit(uint _amount) external {
        balances[msg.sender] += _amount;
        IErc20(token).transferFrom(msg.sender, address(this), _amount);
    }

    function addProposal(bytes calldata _callData, address _recipient, string calldata _description) onlyChairman external returns (uint _proposalId) {
        Proposal memory proposal = Proposal({
            description: _description, 
            recipient: _recipient, 
            callData: _callData, 
            startTime: block.timestamp, 
            votesYes: 0, 
            votesNo: 0,
            finished: false });
        proposals.push(proposal);
        return proposals.length;
    }

    function vote(uint256 _proposalIndex, bool _answer) external{
        require(_proposalIndex < proposals.length, "Invalid proposal index");
        require(msg.sender != chairman, "Chairman cannot vote");
        Proposal storage proposal = proposals[_proposalIndex];
        require(!voted[_proposalIndex][msg.sender], "You have already voted");
        require(block.timestamp < proposal.startTime + duration, "Voting period has ended");
        if (_answer) {
            proposal.votesYes += balances[msg.sender];
        } else {
            proposal.votesNo += balances[msg.sender];
        }
        voted[_proposalIndex][msg.sender] = true;
    }

    function finishProposal(uint256 _proposalIndex) external{
        require(_proposalIndex < proposals.length, "Invalid proposal index");
        Proposal memory proposal = proposals[_proposalIndex];
        require(!proposal.finished, "Proposal has already finished");
        require(block.timestamp >= proposal.startTime + duration, "Voting period has not yet ended");
        proposals[_proposalIndex].finished = true;
        if (proposal.votesYes > proposal.votesNo && 
            proposal.votesYes + proposal.votesNo >= minimumQuorum) {
            (bool success, ) = proposal.recipient.call{value: 0}(proposal.callData);
            require(success, "Proposal reverted");
        }
    }

    function withdraw(uint256 _amount) external {
        require(balances[msg.sender] >= _amount, "Not enough balance");
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].startTime + duration >= block.timestamp && voted[i][msg.sender]) {
                revert("You have active votings");
            }
        }
        balances[msg.sender] -= _amount;
        IErc20(token).transfer(msg.sender, _amount);
    }
}
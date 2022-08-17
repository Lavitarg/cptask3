pragma solidity ^0.8.4;

import "./CurrencyE20.sol";
import "hardhat/console.sol";

contract Dao {


    address private _owner;
    address private _chairman;
    address private _backendServiceAddress;
    CurrencyE20 private _currencyContract;
    uint private _minimumQuorum;
    uint private _voteDuration;
    uint private _voteCounter = 0;

    enum VoteStatus{Active, FinishedPositive, FinishedNegative, Cancelled}

    struct Vote {
        uint affirmativeCount;
        uint negativeCount;
        bytes signature;
        address recipient;
        VoteStatus status;
        string description;
        uint dateEnd;
    }

    mapping(address => uint) public balances;
    mapping(uint => Vote) public votes;
    mapping(address => uint) public locks;

    constructor (address currencyAddress, uint quorum, uint voteSecondsDuration){
        _owner = msg.sender;
        _chairman = msg.sender;
        _currencyContract = CurrencyE20(currencyAddress);
        _minimumQuorum = quorum;
        _voteDuration = voteSecondsDuration;
    }

    function deposit(uint amount) public {
        _currencyContract.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
    }

    function addProposal(bytes memory signature, address recipient, string memory description) public {
        require(msg.sender == _chairman, "Not allowed");
        votes[_voteCounter] = Vote(0, 0, signature, recipient, VoteStatus.Active, description, block.timestamp + _voteDuration);
        _voteCounter ++;
    }

    function vote(uint voteId, bool decision) public {
        Vote memory currentVote = votes [voteId];
        require(currentVote.status == VoteStatus.Active, "Incorrect vote id");
        if(locks[msg.sender] < currentVote.dateEnd){
            locks[msg.sender] = currentVote.dateEnd;
        }
        if (decision) {
            currentVote.affirmativeCount += balances[msg.sender];
        } else {
            currentVote.negativeCount += balances[msg.sender];
        }
        votes[voteId] = currentVote;
    }

    function finishVote(uint voteId) public {
        Vote memory currentVote = votes [voteId];
        console.log("finish vote func, current vote = %s", currentVote.negativeCount);
        require(currentVote.status == VoteStatus.Active, "Incorrect vote id");
        require(block.timestamp >= currentVote.dateEnd, "Too early to finish vote");
        if (currentVote.negativeCount + currentVote.affirmativeCount < _minimumQuorum) {
            currentVote.status = VoteStatus.Cancelled;
            console.log("Cancelling vote, voteid = %d, ncount = %d, pcount = %d", voteId, currentVote.negativeCount, currentVote.affirmativeCount);
        }
        else if (currentVote.affirmativeCount > currentVote.negativeCount){
            (bool success, ) =  currentVote.recipient.call{value: 0}(currentVote.signature);
            require(success,"func call failed");
            currentVote.status = VoteStatus.FinishedPositive;
            console.log("finishing vote positive, voteid = %d, ncount = %d, pcount = %d", voteId, currentVote.negativeCount, currentVote.affirmativeCount);
        }
        else {
            console.log("finishing vote negative, voteid = %d, ncount = %d, pcount = %d", voteId, currentVote.negativeCount, currentVote.affirmativeCount);
        currentVote.status = VoteStatus.FinishedNegative;
        }
        votes[voteId] = currentVote;
    }

    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount, "Not enough funds");
        require(block.timestamp >= locks[msg.sender], "Your funds are locked till the end of the last vote");
        _currencyContract.transfer(msg.sender, amount);
    }

}
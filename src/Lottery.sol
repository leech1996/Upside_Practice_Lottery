// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Lottery{

    struct buyerInfo{
        uint16 numberPicked;
        bool isInTheRound;
        bool prizeClaimed;
    }

    uint256 public round;
    uint256 public startTime;
    uint256 public buyerNum;
    uint256 public winnerNum;
    uint256 public prize;
    bool public isDrawn;
    bool public isClaimed;
    uint16 public winningNumber;

    address[] private buyers;
    mapping(uint256 => mapping(address => buyerInfo)) private buyerInfos;
    
    constructor() {
        round = 0;
        startTime = block.timestamp;
        buyerNum = 0;
        isDrawn = false;
        isClaimed = false;
    }
   
    function buy(uint16 n) public payable {
        require(msg.value == 0.1 ether , "insufficient");
        require(!buyerInfos[round][msg.sender].isInTheRound, "no duplicate");
        require(block.timestamp < startTime + 24 hours, "sellphase ended");

        buyers.push(msg.sender);
        buyerInfos[round][msg.sender].numberPicked = n;
        buyerInfos[round][msg.sender].isInTheRound = true;
        buyerNum += 1;
    }

    function draw() public{
        require(block.timestamp >= startTime + 24 hours, "ongoing sellphase");
        require(!isDrawn, "already drawed");
        require(!isClaimed, "no draw after claim");
        // draw winning number w. easy PRNG
        winningNumber = uint16(block.timestamp % uint256(type(uint16).max));
        isDrawn = true;

        // count number of winners and prize
        winnerNum = 0;
        buyerInfo memory b;
        for(uint256 i=0; i<buyers.length; i++){
            b = buyerInfos[round][buyers[i]];
            if (b.numberPicked == winningNumber){
                winnerNum += 1;
            }
        }
        prize = (winnerNum == 0) ? 0 : (address(this).balance / winnerNum);
    }

    function claim() public{
        
        require(block.timestamp >= startTime + 24 hours, "ongoing sellphase");
        require(isDrawn, "not yet");

        isClaimed = true;
        buyerInfo storage b;
        b = buyerInfos[round][msg.sender];

        if(b.numberPicked == winningNumber){
            b.prizeClaimed = true;
            address(msg.sender).call{value: prize}("");
            if(address(this).balance == 0){
               startNewRound();
            }
        }
        // rollover
        else if(winnerNum == 0){
            startNewRound();
        }
        else{
            revert("you lost");
        }
    }

    function startNewRound() private{
        round += 1;
        startTime = block.timestamp;
        buyerNum = 0;
        isDrawn = false;
        isClaimed = false;
        buyers = new address[](0);
    }

    receive() external payable { }
}
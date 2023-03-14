// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract InfoBoard is Initializable, OwnableUpgradeable {
    uint256 public auctionStartTime;
    uint256 public auctionEndTime;

    struct spaceInfo {
        address currentBidder;
        uint256 currentBidAmount;
    }

    mapping(uint256 => spaceInfo) InfoSpace;

    mapping(uint256 => mapping(address => uint256)) balances;

    event newAuction(address bidder, uint256 amount, uint256 spaceId);

    function initialize() public initializer {
        __Ownable_init();
    }

    function startAuction() external onlyOwner {
        require(
            block.timestamp >= auctionStartTime + 2 days,
            "Auction and Ads not completed"
        );
        auctionStartTime = block.timestamp;
        auctionEndTime = auctionStartTime + 1 days;
        for (uint256 i = 1; i < 12; i++) {
            InfoSpace[i] = spaceInfo(address(0), 0);
        }
    }

    function firstBid(uint256 _spaceId) internal {
        require(msg.value > 0, "Did not send any PXN");
        require(block.timestamp > auctionStartTime, "Auction Not Started");
        require(block.timestamp < auctionEndTime, "Auction Ended");
        balances[_spaceId][msg.sender] += msg.value;
        InfoSpace[_spaceId].currentBidder = msg.sender;
        InfoSpace[_spaceId].currentBidAmount = msg.value;

        emit newAuction(msg.sender, msg.value, _spaceId);
    }

    function BidOnSpace(uint256 _spaceId) external payable {
        if (InfoSpace[_spaceId].currentBidAmount == 0) {
            firstBid(_spaceId);
        } else {
            require(
                msg.value + balances[_spaceId][msg.sender] >
                    InfoSpace[_spaceId].currentBidAmount,
                "Bid higher"
            );
            require(block.timestamp > auctionStartTime, "Auction Not Started");
            require(block.timestamp < auctionEndTime, "Auction Ended");
            balances[_spaceId][msg.sender] += msg.value;
            InfoSpace[_spaceId].currentBidder = msg.sender;
            InfoSpace[_spaceId].currentBidAmount = balances[_spaceId][
                msg.sender
            ];

            emit newAuction(msg.sender, msg.value, _spaceId);
        }
    }

    function withdrawFunds(uint256 _spaceId) external {
        require(
            InfoSpace[_spaceId].currentBidder != msg.sender,
            "Current Leader Can't withdraw"
        );
        require(balances[_spaceId][msg.sender] > 0, "Zero Amount");
        uint256 amount = balances[_spaceId][msg.sender];
        (bool result, ) = payable(msg.sender).call{value: amount}("");
        require(result, "Ether not sent successfully");
        balances[_spaceId][msg.sender] = 0;
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is 0");
        payable(owner()).transfer(balance);
    }

    function getWinner(uint256 _spaceId) external view returns (address) {
        return InfoSpace[_spaceId].currentBidder;
    }

    function getAmount(uint256 _spaceId) external view returns (uint256) {
        return InfoSpace[_spaceId].currentBidAmount;
    }

    function getBalance(uint256 _spaceId) external view returns (uint256) {
        return balances[_spaceId][msg.sender];
    }
}

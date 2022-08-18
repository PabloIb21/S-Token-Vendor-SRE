// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {

    YourToken public yourToken;

    uint256 public constant tokensPerEth = 100;

    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(address seller, uint256 amountOfETH, uint256 amountOfTokens);

    constructor(address tokenAddress) {
        yourToken = YourToken(tokenAddress);
    }

    function buyTokens() public payable {
        uint256 amountOfETH = msg.value;
        require(amountOfETH > 0, "Vendor: You need to send some Ether");

        uint256 amountOfTokens = amountOfETH * tokensPerEth;
        uint256 contractBalance = yourToken.balanceOf(address(this));
        require(contractBalance >= amountOfTokens, "Vendor: Not enough tokens in the reserve");

        address buyer = msg.sender;
        (bool success) = yourToken.transfer(buyer, amountOfTokens);
        require(success, "Vendor: Transfer failed");

        emit BuyTokens(buyer, amountOfETH, amountOfTokens);
    }

    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Vendor: Contract balance is 0");

        (bool success, ) = msg.sender.call{value: contractBalance}("");
        require(success, "Vendor: Withdraw failed");
    }

    function sellTokens(uint256 _amount) public {
        require(_amount > 0, "Vendor: You need to sell at least some tokens");

        uint256 balance = yourToken.balanceOf(msg.sender);
        require(balance >= _amount, "Vendor: Not enough tokens");

        uint256 amountOfETH = _amount / tokensPerEth;
        uint256 contractBalance = address(this).balance;
        require(contractBalance >= amountOfETH, "Vendor: Not enough Ether in the reserve");

        yourToken.approve(address(this), _amount);
        yourToken.transferFrom(msg.sender, address(this), _amount);

        (bool success, ) = msg.sender.call{value: amountOfETH}("");
        require(success, "Vendor: Transfer failed");

        emit SellTokens(msg.sender, amountOfETH, _amount);
    }

}
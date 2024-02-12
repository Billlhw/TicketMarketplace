// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

// interface or ERC20: https://solidity-by-example.org/app/erc20/
contract SampleCoin is ERC20 {
    // your code goes here (you can do it!)

    // name is the full name of the token
    // symbol is the abbreviation
    constructor () ERC20("SampleCoinToken", "SCT") {
        //called ERC20 constructor using the name and symbol
        //allocate 100 coins to the sender (100*10^18, use 18 decimal places for divisability) 
        _mint(msg.sender, 100 * 10 ** uint(decimals()));
    } 
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ITicketNFT} from "./interfaces/ITicketNFT.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

//example of ERC1155 (MyMultiToken): https://solidity-by-example.org/app/erc1155/

contract TicketNFT is ERC1155, ITicketNFT {
    // your code goes here (you can do it!)
    address public ownerAddress;
    string public NFTUri;

    constructor(string memory uri, address ownerAddr) ERC1155(uri) {
        // metadataURL provides information about token attributes
        NFTUri = uri;
        ownerAddress = ownerAddr;
    }

    function owner() external view returns(address) {
        return ownerAddress;
    }

    //create tokens on the blockchain and assign ownership to the to address
    function mintFromMarketPlace(address to, uint256 nftId) external {
        //create a `value` amount of tokens of type `id` and assign them to `to` 
        _mint(to, nftId, 1, ""); 
    }
}
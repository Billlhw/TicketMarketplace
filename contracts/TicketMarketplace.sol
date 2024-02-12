// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITicketNFT} from "./interfaces/ITicketNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol"; 
import {ITicketMarketplace} from "./interfaces/ITicketMarketplace.sol";
import "hardhat/console.sol";

contract TicketMarketplace is ITicketMarketplace {
    // your code goes here (you can do it!)
    struct EventStruct {
        uint128 nextTicketToSell;
        uint128 maxTickets;
        uint256 pricePerTicket;
        uint256 pricePerTicketERC20;
    }

    mapping(uint128 => EventStruct) public eventMap;
    address public nftContractAddress; //address for the 'TicketNFT' contract, 20-byte value
    address public ERC20SampleCoinAddr;
    address public ownerAddress;
    TicketNFT public ticketNFT;
    uint128 curEventIdVal = 0; //add 1 each time an event is created 
    
    
    //constructor
    constructor(address ERC20Addr) { //can be various length
        // Constructor logic here
        ERC20SampleCoinAddr = ERC20Addr;
        ownerAddress = msg.sender;

        //deploy TicketNFT to manage NFTs within the marketplace class
        ticketNFT = new TicketNFT("metadata_uri", address(this)); //can use any string
        nftContractAddress = address(ticketNFT);
    }

    // record the creation of an event (identified by an unique eventId)
    function createEvent(uint128 maxTickets, uint256 pricePerTicket, uint256 pricePerTicketERC20) external {
        // Revert if the sender is not the owner
        if (msg.sender != this.owner()) {
            revert("Unauthorized access");
        }

        uint128 eventIdUsing = curEventIdVal;
        curEventIdVal = curEventIdVal + 1;
        eventMap[eventIdUsing] = EventStruct(0, maxTickets, pricePerTicket, pricePerTicketERC20);
        emit EventCreated(eventIdUsing, maxTickets, pricePerTicket, pricePerTicketERC20);
    }

    //return the ticketNFT generated, this function does not modify the state of the contract
    function nftContract() external view returns(TicketNFT) {
        return ticketNFT;
    }

    //returns the address of ERC20
    function ERC20Address() external view returns(address) {
        return ERC20SampleCoinAddr;
    }

    function owner() external view returns(address) {
        return ownerAddress;
    }

    //get events with specified ID
    function events(uint128 eventId) external view returns(uint128 nextTicketToSell, uint128 maxTickets,
            uint256 pricePerTicket, uint256 pricePerTicketERC20) {
        EventStruct memory eventRef = eventMap[eventId];
        return (eventRef.nextTicketToSell, eventRef.maxTickets, eventRef.pricePerTicket, eventRef.pricePerTicketERC20);
    }

    //currentEventId
    function currentEventId() external view returns(uint128) {
        return curEventIdVal;
    }

    //set the max number of tickets limit
    function setMaxTicketsForEvent(uint128 eventId, uint128 newMaxTickets) external {
        // verify caller identity
        if (msg.sender != this.owner()) {
            revert("Unauthorized access");
        }

        //revert when maxTickets value is smaller than the one that is already present
        if (newMaxTickets < eventMap[eventId].maxTickets) {
            revert("The new number of max tickets is too small!");
        }

        //admin adds more tickets in the system
        eventMap[eventId].maxTickets = newMaxTickets;
        emit MaxTicketsUpdate(eventId, newMaxTickets);
    }

    //set the ETH price for an event
    function setPriceForTicketETH(uint128 eventId, uint256 price) external {
        // verify caller identity
        if (msg.sender != this.owner()) {
            revert("Unauthorized access");
        }

        //update the price
        eventMap[eventId].pricePerTicket = price;
        emit PriceUpdate(eventId, price, "ETH");
    }

    //set the ERC20 price for an event
    function setPriceForTicketERC20(uint128 eventId, uint256 price) external {
        // verify caller identity
        if (msg.sender != this.owner()) {
            revert("Unauthorized access");
        }

        //update the price
        eventMap[eventId].pricePerTicketERC20 = price;
        emit PriceUpdate(eventId, price, "ERC20");
    }

    function setERC20Address(address newERC20Address) external {
        // verify caller identity
        if (msg.sender != this.owner()) {
            revert("Unauthorized access");
        }

        ERC20SampleCoinAddr = newERC20Address;
        emit ERC20AddressUpdate(newERC20Address);
    }

    // Buy tickets using ether sent to the contract
    function buyTickets(uint128 eventId, uint128 ticketCount) payable external {
        EventStruct memory eventRef = eventMap[eventId];
        uint256 totalPrice;
        
        //possible for overflow
        unchecked {
            totalPrice = ticketCount * eventRef.pricePerTicket;
            if (totalPrice / ticketCount != eventRef.pricePerTicket) {
                revert("Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
            } 
        }

        //check if there is enough funds, msg.value is the amount sent with the message
        if (msg.value < totalPrice) {
            revert("Not enough funds supplied to buy the specified number of tickets.");
        }

        //revert when trying to buy too many tickets
        if (ticketCount > (eventRef.maxTickets - eventRef.nextTicketToSell+1)) {
            revert("We don't have that many tickets left to sell!");
        }

        //mint NFTs to the user's account
        for (uint128 i = 0; i < ticketCount; i++) {
            uint256 curTicketId = eventId;
            uint128 seatNum = eventMap[eventId].nextTicketToSell;
            eventMap[eventId].nextTicketToSell = eventMap[eventId].nextTicketToSell + 1;
            curTicketId = (curTicketId << 128) + seatNum;
            ticketNFT.mintFromMarketPlace(msg.sender, curTicketId);
        }

        emit TicketsBought(eventId, ticketCount, "ETH");
    }

    // Buy tickets using ERC20 token
    function buyTicketsERC20(uint128 eventId, uint128 ticketCount) external {
        EventStruct memory eventRef = eventMap[eventId];
        uint256 totalPrice;

        //possible for overflow
        unchecked {
            totalPrice = ticketCount * eventRef.pricePerTicketERC20;
            if (totalPrice / ticketCount != eventRef.pricePerTicketERC20) {
                revert("Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
            } 
        }

        //revert when not enough funds is on the account
        IERC20 ERC20Interface = IERC20(ERC20SampleCoinAddr);
        uint256 userBalance = ERC20Interface.balanceOf(msg.sender);
        if (userBalance < totalPrice) {
            revert("Not enough funds supplied to buy the specified number of tickets.");
        }

        //revert when trying to buy too many tickets
        if (ticketCount > (eventRef.maxTickets - eventRef.nextTicketToSell+1)) {
            revert("We don't have that many tickets left to sell!");
        }

        for (uint128 i = 0; i < ticketCount; i++) {
            //Transfer to the TicketMarketPlace
            ERC20Interface.transferFrom(msg.sender, address(this), eventMap[eventId].pricePerTicketERC20);

            //Compute the unique ticket ID
            uint256 curTicketId = eventId;
            uint128 seatNum = eventMap[eventId].nextTicketToSell;
            eventMap[eventId].nextTicketToSell = eventMap[eventId].nextTicketToSell + 1;
            curTicketId = (curTicketId << 128) + seatNum;

            //Mint ticket using the ticket ID and assign to the buyer
            ticketNFT.mintFromMarketPlace(msg.sender, curTicketId);
        }
        emit TicketsBought(eventId, ticketCount, "ERC20");
    }
}
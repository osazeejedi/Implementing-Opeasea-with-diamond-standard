// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


import "@openzeppelin/contracts/utils/Counters.sol";

struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller; //person selling the nft
        address payable owner; //owner of the nft
        uint256 price;
        bool sold;
}
struct AppStorage {
  
  uint256 listingPrice;
  address payable owner; //owner of the smart contract
  mapping(uint256 => MarketItem)  idMarketItem;
  Counters.Counter _itemIds; //total number of items ever created
  Counters.Counter _itemsSold; //total number of items sold
}
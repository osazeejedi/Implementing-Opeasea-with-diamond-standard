//SPDX-License-Identifier: MIT
import "./AppStorage2.sol";
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
 //prevents re-entrancy attacks
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract NFTMarket is ReentrancyGuard {
  AppStorage internal s;

    constructor(){
        s.owner = payable(msg.sender);
        //people have to pay to puy their NFT on this marketplace
        s.listingPrice = 0.025 ether;
        
    }



    //log message (when Item is sold)
    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address  seller,
        address  owner,
        uint256 price,
        bool sold
    );

    /// @notice function to get listingprice
    function getListingPrice() public view returns (uint256){
        return s.listingPrice;
    }

    function setListingPrice(uint _price) public returns(uint) {
         if(msg.sender == address(this) ){
             s.listingPrice = _price;
         }
         return s.listingPrice;
    }

    /// @notice function to create market item
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price) public payable nonReentrant{
         require(price > 0, "Price must be above zero");
         require(msg.value == s.listingPrice, "Price must be equal to listing price");

         s._itemIds.increment(); //add 1 to the total number of items ever created
         uint256 itemId = s._itemIds.current();

         s.idMarketItem[itemId] = MarketItem(
             itemId,
             nftContract,
             tokenId,
             payable(msg.sender), //address of the seller putting the nft up for sale
             payable(address(0)), //no owner yet (set owner to empty address)
             price,
             false
         );

            //transfer ownership of the nft to the contract itself
            IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

            //log this transaction
            emit MarketItemCreated(
                itemId,
             nftContract,
             tokenId,
             msg.sender,
             address(0),
             price,
             false);

        }


        /// @notice function to create a sale
        function createMarketSale(
            address nftContract,
            uint256 itemId
            ) public payable nonReentrant{
                uint price = s.idMarketItem[itemId].price;
                uint tokenId = s.idMarketItem[itemId].tokenId;

                require(msg.value == price, "Please submit the asking price");

           //pay the seller the amount
           s.idMarketItem[itemId].seller.transfer(msg.value);

             //transfer ownership of the nft from the contract itself to the buyer
            IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

            s.idMarketItem[itemId].owner = payable(msg.sender); //mark buyer as new owner
            s.idMarketItem[itemId].sold = true; //mark that it has been sold
            s._itemsSold.increment(); //increment the total number of Items sold by 1
            payable(s.owner).transfer(s.listingPrice); //pay owner of contract the listing price
        }


        /// @notice total number of items unsold on our platform
        function fetchMarketItems() public view returns (MarketItem[] memory){
            uint itemCount = s._itemIds.current(); //total number of items ever created
            //total number of items that are unsold = total items ever created - total items ever sold
            uint unsoldItemCount = s._itemIds.current() - s._itemsSold.current();
            uint currentIndex = 0;

            MarketItem[] memory items =  new MarketItem[](unsoldItemCount);

            //loop through all items ever created
            for(uint i = 0; i < itemCount; i++){

                //get only unsold item
                //check if the item has not been sold
                //by checking if the owner field is empty
                if(s.idMarketItem[i+1].owner == address(0)){
                    //yes, this item has never been sold
                    uint currentId = s.idMarketItem[i + 1].itemId;
                    MarketItem storage currentItem = s.idMarketItem[currentId];
                    items[currentIndex] = currentItem;
                    currentIndex += 1;

                }
            }
            return items; //return array of all unsold items
        }

        /// @notice fetch list of NFTS owned/bought by this user
        function fetchMyNFTs() public view returns (MarketItem[] memory){
            //get total number of items ever created
            uint totalItemCount = s._itemIds.current();

            uint itemCount = 0;
            uint currentIndex = 0;


            for(uint i = 0; i < totalItemCount; i++){
                //get only the items that this user has bought/is the owner
                if(s.idMarketItem[i+1].owner == msg.sender){
                    itemCount += 1; //total length
                }
            }

            MarketItem[] memory items = new MarketItem[](itemCount);
            for(uint i = 0; i < totalItemCount; i++){
               if(s.idMarketItem[i+1].owner == msg.sender){
                   uint currentId = s.idMarketItem[i+1].itemId;
                   MarketItem storage currentItem = s.idMarketItem[currentId];
                   items[currentIndex] = currentItem;
                   currentIndex += 1;
               }
            }
            return items;

        }


         /// @notice fetch list of NFTS owned/bought by this user
        function fetchItemsCreated() public view returns (MarketItem[] memory){
            //get total number of items ever created
            uint totalItemCount = s._itemIds.current();

            uint itemCount = 0;
            uint currentIndex = 0;


            for(uint i = 0; i < totalItemCount; i++){
                //get only the items that this user has bought/is the owner
                if(s.idMarketItem[i+1].seller == msg.sender){
                    itemCount += 1; //total length
                }
            }

            MarketItem[] memory items = new MarketItem[](itemCount);
            for(uint i = 0; i < totalItemCount; i++){
               if(s.idMarketItem[i+1].seller == msg.sender){
                   uint currentId = s.idMarketItem[i+1].itemId;
                   MarketItem storage currentItem = s.idMarketItem[currentId];
                   items[currentIndex] = currentItem;
                   currentIndex += 1;
               }
            }
            return items;

        }




}

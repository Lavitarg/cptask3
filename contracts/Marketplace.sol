pragma solidity ^0.8.0;

import "./Beerhound721.sol";
import "./CurrencyE20.sol";

contract Marketplace {

    Beerhound721 private _nftContract;
    CurrencyE20 private _currencyContract;

    string public name = "Marketplace";
    string public symbol = "MPE20C";
    address public owner;

    address private _currencyAddress;
    address private _nftAddress;
    uint private counter;


    enum SaleStatus{Active, Sold, Canceled}

     struct SaleEntry {
        address sellerAddress;
        uint price;
        SaleStatus status;
    }

     struct AuctionLot {
        address creator;
        address lastBidder;
        uint minAmountOfBets;
        uint price;
        SaleStatus status;
        uint betsCounter;
    }

    mapping(uint => SaleEntry) private _sales;
    mapping(uint => AuctionLot) private _auctionBets;


    constructor (address currencyAddress, address nftAddress){
        _nftContract = Beerhound721(nftAddress);
        _currencyContract = CurrencyE20(currencyAddress);
        owner = msg.sender;
    }

    function createItem(string memory metadataUrl, address nftOwner) public {
        _nftContract.mint(nftOwner, counter, metadataUrl);
        counter++;
    }

    function listItem(uint tokenId, uint price) public{
        require(_nftContract.ownerOf(tokenId) == msg.sender);
        SaleStatus existingSaleStatus = _sales[tokenId].status;
        require(existingSaleStatus != SaleStatus.Active, "This nft is already for sale");
        _nftContract.safeTransferFrom(msg.sender, address(this), tokenId);
        _sales[tokenId] = SaleEntry(msg.sender, price, SaleStatus.Active);
    }

    function buy(uint tokenId) public{
        SaleEntry memory currentSale = _sales[tokenId];
        SaleStatus existingSaleStatus = currentSale.status;
        require(existingSaleStatus == SaleStatus.Active, "This nft is not for sale");

        _currencyContract.transferFrom(msg.sender, currentSale.sellerAddress, currentSale.price);
        _nftContract.transferFrom(address(this), msg.sender, tokenId);
    }

    function cancel(uint tokenId) public{
        SaleEntry memory sale = _sales[tokenId];
        require(sale.sellerAddress == msg.sender, "U cant cancel other people sales");
        require(sale.status == SaleStatus.Active, "This nft is not for sale");
        _sales[tokenId].status = SaleStatus.Canceled;
    }

    function createAuction(uint tokenId, uint initialPrice, uint minAmountOfBets) public{
        require(tokenId <= counter, "This token doesn't exists");
        require(_auctionBets[tokenId].status != SaleStatus.Active, "This item is already for sale!");
        _nftContract.safeTransferFrom(msg.sender, address(this), tokenId);
        _auctionBets[tokenId] = AuctionLot(msg.sender, address(0), minAmountOfBets, initialPrice, SaleStatus.Active, 0);
    }

    function makeBid(uint tokenId, uint newPrice) public{
        AuctionLot memory bet = _auctionBets[tokenId];
        require(bet.status == SaleStatus.Active);
        require(newPrice > bet.price);
        _currencyContract.transferFrom(msg.sender, address(this), newPrice);
        if (bet.lastBidder != address(0)) {
            _currencyContract.transfer(bet.lastBidder, bet.price);
        }
        bet.price = newPrice;
        bet.lastBidder = msg.sender;
        bet.betsCounter++;
    }

    function finishAuction(uint tokenId) public{
        AuctionLot memory bet = _auctionBets[tokenId];
        require(bet.status == SaleStatus.Active);
        require(bet.betsCounter >= bet.minAmountOfBets);
        _currencyContract.transfer(bet.lastBidder, bet.price);
        _nftContract.transferFrom(address(this), bet.creator, tokenId);
        bet.status = SaleStatus.Sold;
    }
}

pragma solidity ^0.8.4;

import "./CurrencyE20.sol";
import "hardhat/console.sol";

contract Bridge {

    address private _owner;
    address private _backendServiceAddress;
    CurrencyE20 private _currencyContract;

    event Swap(address indexed to, uint256 amount);

    mapping(bytes32 => bool) private _transfers;



    constructor (address backendServiceAddress, address currencyAddress){
        _owner = msg.sender;
        _backendServiceAddress = backendServiceAddress;
        _currencyContract = CurrencyE20(currencyAddress);
    }

    function swap(address to, uint amount) public {
        _currencyContract.burn(msg.sender, amount);
        bytes32 message = keccak256(abi.encodePacked(to, amount));
        _transfers[message] = false;
        emit Swap(to, amount);
    }

    function redeem(address to, uint256 amount, uint8 v, bytes32 r, bytes32 s) public {
        require(checkSign(to, amount, v, r, s), "Invalid request");
        bytes32 message = keccak256(abi.encodePacked(to, amount));
        require(!_transfers[message], "Already transfered");
        _currencyContract.mint(to, amount);
        _transfers[message] = true;

    }

    function checkSign(address to, uint256 amount, uint8 v, bytes32 r, bytes32 s) private returns (bool success){
        bytes32 message = keccak256(abi.encodePacked(to, amount));
        address addr = ecrecover(message, v, r, s);
        return addr == _backendServiceAddress;
    }

    function hashMessage(bytes32 message) private pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, message));
    }

}
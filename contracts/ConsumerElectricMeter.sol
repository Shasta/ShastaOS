pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "zos-lib/contracts/migrations/Migratable.sol";
import "./BillSystem.sol";

/**
 * @title ElectricMeter
 */

contract ConsumerElectricMeter is Ownable, Migratable {

  struct EnergyContract {
    address tokenAddress; // If tokenAddress 0x00 == ETHER as payment
    address seller;
    address consumer;
    uint256 price;
    string ipfsContractMetadata;
  }

  address public billSystemAddress;
  address public marketRbacAddress;

  BillSystem billSystem;
  EnergyContract public currentContract;

  /** TODO:
    * Make it only accesible via RBAC, so only the Shasta contract that manages contracts can call this function
    * OR ownable that accepts an Offer marketer id and grabs the info from the Shasta offer registry. 
    */
  function setEnergyContract(address tokenAddress, address seller, address consumer, uint price, string ipfsContractMetadata) public {
    currentContract = EnergyContract(tokenAddress, seller, consumer, price, ipfsContractMetadata);
  }

  function setBillSystemAddress(address _address) public {
    billSystemAddress = _address;
    billSystem = BillSystem(billSystemAddress);
  }

  function energyConsumed(uint wh, string ipfsMetadata) public returns(uint billId) {
    billId = billSystem.generateBill(wh, currentContract.price, currentContract.seller, currentContract.tokenAddress, ipfsMetadata);
  }

  function getCurrentContract() public view returns (
    address tokenAddress,
    address seller,
    address consumer,
    uint256 price,
    string ipfsContractMetadata
  ) {
    tokenAddress = currentContract.tokenAddress;
    seller = currentContract.seller;
    consumer = currentContract.consumer;
    price = currentContract.price;
    ipfsContractMetadata = currentContract.ipfsContractMetadata;
  }
}
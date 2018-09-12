pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "zos-lib/contracts/migrations/Migratable.sol";
import "./libraries/ShastaTypes.sol";

/**
 * @title ContractRegistry
 */

contract ContractRegistry is Ownable, Migratable {

  ShastaTypes.EnergyContract[] public contracts;

  event NewContract(address seller, address consumer, uint index);


  // Upgradeable contract pattern with initializer using zeppelinOS way.
  function initialize() public isInitializer("ContractRegistry", "0") {
  }

  /** TODO:
    * Make it only accesible via RBAC, so only the Shasta contract that manages contracts can call this function
    * OR ownable that accepts an Offer marketer id and grabs the info from the Shasta offer registry. 
    */
  function newContract(address tokenAddress, address seller, address consumer, uint price, bool enabled, string ipfsContractMetadata) public {
    uint newIndex = contracts.push(ShastaTypes.EnergyContract(tokenAddress, seller, consumer, price, enabled, ipfsContractMetadata)) - 1;
    emit NewContract(seller, consumer, newIndex);
  }

  function setContractStatus(uint index, bool status) public {
    ShastaTypes.EnergyContract storage currentContract = contracts[index];
    currentContract.enabled = status;
  }

  function getContractsLength() public view  returns (uint length) {
    length = contracts.length;
  }

  function isEnabled(uint index) public view returns (bool enabled) {
    ShastaTypes.EnergyContract memory currentContract = contracts[index];
    enabled = currentContract.enabled;
  }

  function getContract(uint index) public view returns (
    address tokenAddress,
    address seller,
    address consumer,
    uint price,
    bool enabled,
    string ipfsContractMetadata
  ) {
    ShastaTypes.EnergyContract memory currentContract = contracts[index];
    tokenAddress = currentContract.tokenAddress;
    seller = currentContract.seller;
    consumer = currentContract.consumer;
    price = currentContract.price;
    enabled = currentContract.enabled;
    ipfsContractMetadata = currentContract.ipfsContractMetadata;
  }

  function getContractData(uint index) public view returns (
    address,
    address,
    address,
    uint,
    bool
  ) {
    ShastaTypes.EnergyContract storage currentContract = contracts[index];
    return (currentContract.tokenAddress, currentContract.seller, currentContract.consumer, currentContract.price, currentContract.enabled);
  }
}
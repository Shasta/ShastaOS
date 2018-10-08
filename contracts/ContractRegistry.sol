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

  /** 
    * @dev Stores a new contract between consumer and producer
    * @param tokenAddress The ERC20 contract address. 0x00 == ETH
    * @param seller The seller/producer address
    * @param consumer The consumer address
    * @param price The unit price of energy per hour
    * @param monthlyWh The estimated monthly watt hour
    * @param enabled Set the state of the contract
    * @param ipfsContractMetadata IFPS hash string that points to extra contract metadata
    */
  function newContract(
    address tokenAddress,
    address seller,
    address consumer,
    uint price,
    uint monthlyWh,
    bool enabled,
    string ipfsContractMetadata
  ) public returns (uint newIndex) {
    newIndex = contracts.push(
      ShastaTypes.EnergyContract(tokenAddress, seller, consumer, price, monthlyWh, enabled, ipfsContractMetadata)
    ) - 1;
    emit NewContract(seller, consumer, newIndex);
  }
  
  /** 
    * @dev Set the contract status by id
    * @param index The index of the contract
    * @param status The new boolean state
    */
  function setContractStatus(uint index, bool status) public {
    ShastaTypes.EnergyContract storage currentContract = contracts[index];
    require(currentContract.seller == msg.sender || currentContract.consumer == msg.sender, "You must be the consumer or the producer address");
    currentContract.enabled = status;
  }

  /** 
    * @dev Get the contracts length
    * @return The length of the contracts list
    */
  function getContractsLength() public view  returns (uint length) {
    length = contracts.length;
  }

  /** 
    * @dev Get the current contract status
    * @param index The contract index
    * @return bool The current contract status
    */
  function isEnabled(uint index) public view returns (bool enabled) {
    ShastaTypes.EnergyContract memory currentContract = contracts[index];
    enabled = currentContract.enabled;
  }

  /** 
    * @dev Get the current contract data by index
    * @param index The contract index
    * @return tokenAddress The ERC20 contract address. 0x00 == ETH
    * @return seller The seller/producer address
    * @return consumer The consumer address
    * @return price The unit price of energy per hour
    * @return enabled Set the state of the contract
    * @return ipfsContractMetadata IFPS hash string that points to extra contract metadata
    */
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

  /** 
    * @dev Get the current contract data by index
    * @param index The contract index
    * @return tokenAddress The ERC20 contract address. 0x00 == ETH
    * @return seller The seller/producer address
    * @return consumer The consumer address
    * @return price The unit price of energy per hour
    * @return enabled Set the state of the contract
    */
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
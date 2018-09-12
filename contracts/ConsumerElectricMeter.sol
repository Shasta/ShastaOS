pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "zos-lib/contracts/migrations/Migratable.sol";
import "./BillSystem.sol";
import "./ContractRegistry.sol";

/**
 * @title ElectricMeter
 */

contract ConsumerElectricMeter is Ownable{

  address public billSystemAddress;
  address public contractRegistryAddress;

  BillSystem billSystem;
  ContractRegistry contractRegistry;

  uint public currentContractIndex;

  event NewBillIndex(uint index);

  /** TODO:
    * Make it only accesible via RBAC, so only the Shasta contract that manages contracts can call this function
    * OR ownable that accepts an Offer marketer id and grabs the info from the Shasta offer registry. 
    */


  function setContractRegistry(address _contractRegistryAddress) public onlyOwner {
    contractRegistryAddress = _contractRegistryAddress;
    contractRegistry = ContractRegistry(contractRegistryAddress);
  }

  function setEnergyContract(uint index) public {
    currentContractIndex = index;
  }

  function setBillSystemAddress(address _address) public {
    billSystemAddress = _address;
    billSystem = BillSystem(billSystemAddress);
  }

  function energyConsumed(uint wh, string ipfsMetadata, address _bill, address _registry) public {
    BillSystem(_bill).generateBill(
      wh,
      currentContractIndex,
      ipfsMetadata,
      _registry
    );
  }
}
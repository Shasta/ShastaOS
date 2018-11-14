pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "zos-lib/contracts/Initializable.sol";
import "./libraries/ShastaTypes.sol";
/**
 * @title GridState
 */
contract GridState is Ownable, Initializable {
  mapping(bytes32 => uint) public uintRules;
  mapping(bytes32 => address) public addressRules;

  // Upgradeable contract pattern with initializer using zeppelinOS way.
  function initialize() public initializer {
    // Set watts/hour/usd_token to 0.0001, equivalent to 0.10 per kW/hour
    setUintRule("WATT_HOUR_PRICE", 100000000000000);

    // Set token address to 0x0, so it uses Ether
    setAddressRule("TOKEN_ADDRESS", address(0));
  }

  function setUintRule(string key, uint value) public onlyOwner {
    bytes32 hashed_key = keccak256(bytes(key));
    uintRules[hashed_key] = value;
  }

  function setAddressRule(string key, address value) public onlyOwner {
    bytes32 hashed_key = keccak256(bytes(key));
    addressRules[hashed_key] = value;
  }

  function getUintRule(string key) public view returns (uint) {
    return uintRules[keccak256(bytes(key))];
  }

  function getAddressRule(string key) public view returns (address) {
    return addressRules[keccak256(bytes(key))];
  }
}
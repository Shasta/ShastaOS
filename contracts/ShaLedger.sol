pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title ERC20 token named kWht that mimics a kiloWatt/hour.
 * 
 */
contract ShaLedger is ERC20, Ownable, ERC20Burnable, ERC20Mintable {
  string public name = "fake USD";
  string public symbol = "USD";
  uint8 public decimals = 18;
  
  constructor() public {
    addMinter(msg.sender);
  }
}
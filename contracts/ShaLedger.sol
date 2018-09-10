pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./token/RBACBurnableToken.sol";
import "openzeppelin-solidity/contracts/token/ERC20/RBACMintableToken.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/access/rbac/RBAC.sol";

/**
 * @title ERC20 token named kWht that mimics a kiloWatt/hour.
 * 
 */
contract ShaLedger is ERC20, Ownable, RBAC, RBACBurnableToken, RBACMintableToken {
  string public name = "fake USD";
  string public symbol = "USD";
  uint8 public decimals = 8;
  
}
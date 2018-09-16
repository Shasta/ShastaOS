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
 
 
  mapping (address => uint256) public _balances;
  // Shadow _balances private mapping to allow Drizzle to keep the balance state.
  
  string public name = "Sha";
  string public symbol = "SHA";
  uint8 public decimals = 18;

  bool private _mintingFinished = false;

/**
  * @dev Gets the balance of the current address.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balance() public view returns (uint256) {
    return _balances[msg.sender];
  }

  // Shadow ERC20Mintable.mint function to remove RBAC permissions and set a limit.
  function mint(
    address to,
    uint256 amount
  )
    public
    onlyBeforeMintingFinished
    returns (bool)
  {
    uint user_balance = balanceOf(to);
    require(user_balance < 300000000000000000000, "You can't mint more if you have an amount greater than 300 Shasta tokens");
    _mint(to, amount);
    return true;
  }

  function toggleMinting(bool _bool)
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    _mintingFinished = _bool;
    emit MintingFinished();
    return true;
  }
}
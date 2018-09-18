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
  string public name = "Sha";
  string public symbol = "SHA";
  uint8 public decimals = 18;

  bool private _mintingFinished = false;

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

  function approveAndCall(address _spender, uint256 _value, bytes _data) public payable returns (bool) {
    require(_spender != address(this));
    require(super.approve(_spender, _value));
    require(_spender.call(_data));
    return true;
  }
}
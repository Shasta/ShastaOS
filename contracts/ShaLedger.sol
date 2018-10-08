pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title ERC20 token named kWht that mimics a kiloWatt/hour.
 */
contract ShaLedger is ERC20, Ownable, ERC20Burnable, ERC20Mintable {
  string public name = "Sha";
  string public symbol = "SHA";
  uint8 public decimals = 18;

  bool private _mintingFinished = false;

  /** 
    * @dev Allow everyone to mint is own tokens
    * @dev Shadow ERC20Mintable.mint function to remove RBAC permissions and set a limit.
    * @param to The address to mint tokens
    * @param amount The amount of tokens to mint
    * @return bool Returns true if the operation was succesful
    */
  function mint(
    address to,
    uint256 amount
  )
    public
    onlyBeforeMintingFinished
    returns (bool)
  {
    uint user_balance = balanceOf(to);
    require(user_balance < 1000000000000000000000, "You can't mint more if you have an amount greater than 1000 Shasta tokens");
    require(amount <= 1000000000000000000000, "You can't mint more than 1000 Shasta tokens");
    _mint(to, amount);
    return true;
  }

  /** 
    * @dev Disable or enable mintin
    * @param _bool Set to false to disable minting. True to reenable minting.
    * @return bool Returns true if the operation was succesful
    */
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

  /** 
    * @dev Basic approveAndCall implementation. Allows an ERC20 holder to approve the movement of funds and call to bytecoded function
    * @return bool Returns true if the operation was succesful
    */
  function approveAndCall(address _spender, uint256 _value, bytes _data) public payable returns (bool) {
    require(_spender != address(this));
    require(super.approve(_spender, _value));
    require(_spender.call(_data));
    return true;
  }
}
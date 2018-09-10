pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/rbac/RBAC.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title RBACBurnableToken
 * @author David Canillas
 * @dev Burnable Token, with RBAC burner permissions
 */

contract RBACBurnableToken is ERC20, Ownable, RBAC  {
  /**
   * A constant role name for indicating minters.
   */
  string private constant ROLE_BURNER = "burner";
  
  event TokensBurned(address indexed burner, uint256 value);

  /**
   * @dev modifier with role based logic
   */
  modifier hasBurnerPermission() {
    checkRole(msg.sender, ROLE_BURNER);
    _;
  }


  /**
   * @dev Overrides ERC20._burn in order for burn and burnFrom to emit
   * an additional Burn event.
   */
  function _burn(address _who, uint256 _value) internal {
    super._burn(_who, _value);
    emit TokensBurned(_who, _value);
  }

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public hasBurnerPermission {
    _burn(msg.sender, _value);
  }

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param _from address The address which you want to send tokens from
   * @param _value uint256 The amount of token to be burned
   */
  function burnFrom(address _from, uint256 _value) public hasBurnerPermission {
    _burnFrom(_from, _value);
  }

  /**
   * @return true if the account is a burner, false otherwise.
   */
  function isBurner(address _account) public view returns(bool) {
    return hasRole(_account, ROLE_BURNER);
  }

  /**
   * @dev add a burner role to an address
   * @param _burner address
   */
  function addBurner(address _burner) public onlyOwner {
    super._addRole(_burner, ROLE_BURNER);
  }

  /**
   * @dev remove a burner role from an address
   * @param _burner address
   */
  function removeBurner(address _burner) public onlyOwner {
    super._removeRole(_burner, ROLE_BURNER);
  }
}
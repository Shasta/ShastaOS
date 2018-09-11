pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/access/Roles.sol";

// TODO: all
contract ConsumerRole {
  using Roles for Roles.Role;

  event MarketAdded(address indexed account);
  event MarketRemoved(address indexed account);

  Roles.Role private markets;

  constructor () public {
    markets.add(msg.sender);
  }

  modifier onlyMarket() {
    require(isMarket(msg.sender), "Address has no RBAC Market role access.");
    _;
  }

  function isMarket(address account) public view returns (bool) {
    return markets.has(account);
  }

  function addMarket(address account) public onlyMarket {
    markets.add(account);
    emit MarketAdded(account);
  }

  function renounceMarket() public {
    markets.remove(msg.sender);
  }

  function _removeMarket(address account) internal {
    markets.remove(account);
    emit MarketRemoved(account);
  }
}
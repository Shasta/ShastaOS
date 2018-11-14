pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "zos-lib/contracts/Initializable.sol";
import "./libraries/ShastaTypes.sol";
import "./libraries/RoundTypes.sol";
import "./GridState.sol";
/**
 * @title Rounds
 */
contract Rounds is Ownable, Initializable {
  GridState gridState;

  mapping(address => bool) public trustedRelayers;
  mapping(uint => RoundTypes.Round) public rounds;

  uint public currentRound;

  modifier afterGracePeriod() {
    require(rounds[currentRound].inactiveUntilBlock >= block.number, "The current block must be equal or higher than the grace period.");
    _;
  }

  modifier onlyTrustedRelayer() {
    require(trustedRelayers[msg.sender] == true, "The address is not trusted");
    _;
  }

  // Upgradeable contract pattern with initializer using zeppelinOS way.
  function initialize(address gridAddress) public initializer {
    currentRound = 0;
    gridState = GridState(gridAddress);
    inheritGridState();
  }

  function enableRelayerAddress(address trustedAddress) public onlyOwner {
    trustedRelayers[trustedAddress] = true;
  }

  function disableRelayerAddress(address trustedAddress) public onlyOwner {
    trustedRelayers[trustedAddress] = false;
  }

  function setRoundRoots(
    bytes32 consumersRoot,
    bytes32 producersRoot,
    bytes32 billingRoot
  )
  public
  onlyTrustedRelayer()
  returns (bool)
  {
    require(rounds[currentRound].stage == RoundTypes.RoundStage(0), "The round is finished and can't be updated.");
    rounds[currentRound].consumersRoot = consumersRoot;
    rounds[currentRound].producersRoot = producersRoot;
    rounds[currentRound].billingRoot = billingRoot;
    rounds[currentRound].activatedBlock = block.number;
    // Set the stage to active
    rounds[currentRound].stage = RoundTypes.RoundStage.ACTIVATED;

    // Generate the next round
    generateNextRound();
    
    return true;
  }

  function inheritGridState() internal {
    require(rounds[currentRound].stage == RoundTypes.RoundStage(0), "The round is finished and can't be updated.");
    rounds[currentRound].tokenAddress = gridState.getAddressRule("TOKEN_ADDRESS");
    rounds[currentRound].energyPrice = gridState.getUintRule("WATTS_PRICE");
  }

  function generateNextRound() internal {
    currentRound += 1;
    // Wait until current block + 183000 blocks (around 1 month) to let relayers post the result
    rounds[currentRound].inactiveUntilBlock = block.number + 183000;
    inheritGridState();
  }

  function getRound(uint index) public view returns (
    uint stage,
    uint energyPrice,
    uint inactiveUntilBlock,
    uint activatedBlock,
    address tokenAddress,
    bytes32 consumersRoot,
    bytes32 producersRoot,
    bytes32 billingRoot
  ) {
    stage = uint(rounds[index].stage);
    energyPrice = rounds[index].energyPrice;
    inactiveUntilBlock = rounds[index].inactiveUntilBlock;
    activatedBlock = rounds[index].activatedBlock;
    tokenAddress = rounds[index].tokenAddress;
    consumersRoot = rounds[index].consumersRoot;
    producersRoot = rounds[index].producersRoot;
    billingRoot = rounds[index].billingRoot;
  }

  function getRoundForBilling(uint index) public view returns (
    uint stage,
    uint energyPrice,
    address tokenAddress,
    bytes32 billingRoot
  ) {
    stage = uint(rounds[index].stage);
    energyPrice = rounds[index].energyPrice;
    tokenAddress = rounds[index].tokenAddress;
    billingRoot = rounds[index].billingRoot;
  }
}
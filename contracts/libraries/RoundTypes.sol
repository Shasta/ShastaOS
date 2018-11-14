pragma solidity ^0.4.24;

/** @title RoundTypes */

library RoundTypes {
  enum RoundStage {
    WAITING_INPUT,
    ACTIVATED
  }

  struct Round {
    RoundStage stage;
    uint energyPrice;
    uint inactiveUntilBlock;
    uint activatedBlock;
    address tokenAddress;
    bytes32 consumersRoot;
    bytes32 producersRoot;
    bytes32 billingRoot;
  }
}
pragma solidity ^0.4.24;

/** @title ShastaTypes */

/** Internal Shasta types, for code reuse */
library ShastaTypes {
  
  struct EnergyContract {
    address tokenAddress; // If tokenAddress 0x00 == ETHER as payment
    address seller;
    address consumer;
    uint256 price;
    uint monthlyWh;
    bool enabled;
    string ipfsContractMetadata;
  }

  struct Bill {
    uint256 whConsumed;
    address tokenAddress; // If tokenAddress 0x00 == ETHER as payment
    address seller;
    address consumer;
    uint256 price;
    uint256 amount;
    string ipfsMetadata;
  }

}
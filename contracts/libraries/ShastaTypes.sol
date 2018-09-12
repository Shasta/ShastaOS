pragma solidity ^0.4.24;

library ShastaTypes {
  
  struct EnergyContract {
    address tokenAddress; // If tokenAddress 0x00 == ETHER as payment
    address seller;
    address consumer;
    uint256 price;
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
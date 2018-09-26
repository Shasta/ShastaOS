# ShastaOS v0.1.0 Alpha
This repository contains all the Shasta logic behind Shasta Core 0.1, implemented in Solidity smart contracts.

The current finality of Shasta OS 0.1.0 is to be able to show the core ideas about Shasta energy market.

:boom: All the smart contracts located in this repository are highly experimental, are not battle-tested, so please do not use in Ethereum mainnet, and if you do, we are not responsible of irreversible loss of funds.

Contributions are welcome! You can also open issues for reporting bugs, launch new ideas or for questions regarding ShastaOS. 

# Content inside ShastaOS 0.1.0 Alpha

- libraries/ShastaTypes.sol
  Small library that contains structs for reuse by ShastaOS smart contracts
- BillSystem.sol
  The bill generator, generates a bill between a user and a producer, linked with an energy Contract. The bill system support any ERC20 token or Ether.
- ContractRegistry.sol
  Energy contract registry. The registry holds all the contracts between the energy consumer and the enery producer.
- ShaLedger.sol
  The current Shasta token, for testing purposes. Follows the ERC20 standard but have also implemented the approveAndCall function, making it possible to do some steps in only one tx.
- ShastaMarket.sol
  The ShastaMarket currently holds the producer offers logic. Allows energy producers to show the location of his energy production plant, and create an energy offer to Shasta.
- User.sol
  The contract manages the registry of users, and allows to add extra metadata via IPFS.

# Install
For installing ShastaOS locally, you need to clone the repository and run the following commands:

Install the needed dependencies:
```
npm install
```

Run tests, uses ganache-cli as private Ethereum network:
```
npm run test
```

# Interact via Truffle
You can use Truffle commands to compile, migrate, and test the contracts using a private or public Ethereum network:

Compile contracts
```
truffle compile
```

Migrate contracts to a local Ethereum network

```
truffle migrate
```

Test the contracts deployed in your Ethereum network

```
truffle test
```
# Use as a dependency in your project

You can import Shasta solidity contracts in your own Solidity smart contracts to add new functionalities or interact with Shasta OS with your front-end. For importing ShastaOS you need to install it using NPM.
```
npm install git+ssh://git@github.com/alexsicart/ShastaOS.git#v0.1.0
```

Then, you can import a ShastaOS solidity contract via the following way, to use in your contract or interact with a deployed smart contract:
```
pragma solidity ^0.4.24;

import "shasta-os/ShastaTypes.sol";
import "shasta-os/BillSystem";

/**
 * @title Your new contract
 */

contract YourContract {

  BillSystem billSystemInstance;

  ShastaTypes.Bill[] public bills;

  fn setBillInstance(address billAddress) {
    billSystemInstance = BillSystem(billAddress);
  }

  ...
}

```


You can even interact with ShastaOS with your own front-end, via importing the smart contracts ABI interfaces, located at /abi directory.

Example with Web3 1.0.0 beta

```
import billInterface from 'shasta-os/abi/BillSystem.json';

// BillSystem deployed address at Rinkeby
const deployedBillAddress = '0x85D49ca656df46ab590Ff959737D7c86938F6B61'; 

 /* Create a Web3 Contract instance to interact with BillSystem smart contract */
const billInstance = new web3.eth.Contract(billInterface, billAddress);
```


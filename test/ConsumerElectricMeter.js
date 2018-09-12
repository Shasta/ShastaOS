const truffleAssert = require("truffle-assertions");
const ShaLedger = artifacts.require("shasta-os/ShaLedger");
const BillSystem = artifacts.require("shasta-os/BillSystem");
const ConsumerElectricMeter = artifacts.require("shasta-os/ConsumerElectricMeter");
const ContractRegistry = artifacts.require("shasta-os/ContractRegistry");
const Promise = require("bluebird");

/**
 * SharedMap test cases
 */
contract('ConsumerElectricMeter', function(accounts) {
  // Participants
  var owner = accounts[0];
  var seller = accounts[1];
  var consumer = accounts[2];

  const priceSha = "0.00017" // Sha/wattHour
  const contractId = 0;
  // Contract pointers
  let shaLedgerInstance;
  let billSystemInstance;
  let electricMeterInstance;
  let contractRegistryInstance;

  let tokenDecimals;
  // Fake IPFS hash string for testing purposes
  const ipfsHash = "QmZfSNpHVzTNi9gezLcgq64Wbj1xhwi9wk4AxYyxMZgtCc";

  // Seller-Consumer contract;
  let storedContract;

  // In each test the contracts are deployed again, recovering the initial state.
  beforeEach('Initialize contract with Web3 state per test case', async function () {
    // Currently shaLedger is a fake USD ERC20 token. Bill system allows any
    // ERC20 compatible token and Ether. The seller-consumer contract will determine
    // the token used.

    // Initialize each contract data in Web3, instead of Truffle contract.
    const shaLedgerContract = await new web3.eth.Contract(ShaLedger.abi);
    const billSystemContract = await new web3.eth.Contract(BillSystem.abi);
    const electricMeterContract = await new web3.eth.Contract(ConsumerElectricMeter.abi);
    const contractRegistryContract = await new web3.eth.Contract(ContractRegistry.abi);

    const shaLedgerGas = await shaLedgerContract.deploy({ data: ShaLedger.bytecode }).estimateGas({from: owner});
    const billSystemGas = await billSystemContract.deploy({ data: BillSystem.bytecode }).estimateGas({from: owner});
    const meterGas = await electricMeterContract.deploy({ data: ConsumerElectricMeter.bytecode }).estimateGas({from: accounts[2]})
    const contractRegistryGas = await contractRegistryContract.deploy({ data: ContractRegistry.bytecode }).estimateGas({from: owner})

    shaLedgerInstance = await shaLedgerContract.deploy({ data: ShaLedger.bytecode }).send({from: owner, gas: shaLedgerGas});
    billSystemInstance = await billSystemContract.deploy({ data: BillSystem.bytecode }).send({from: owner, gas: billSystemGas});
    electricMeterInstance = await electricMeterContract.deploy({ data: ConsumerElectricMeter.bytecode }).send({from: accounts[2], gas: meterGas});
    contractRegistryInstance = await contractRegistryContract.deploy({ data: ContractRegistry.bytecode }).send({from: owner, gas: contractRegistryGas});

    // Estimate gas for setting contract registry at billing and electric meter instances
    const setRegistryAtBillingGas = await billSystemInstance.methods.setContractRegistry(contractRegistryInstance.options.address).estimateGas({from: owner});
    const setRegistryAtMeterGas = await electricMeterInstance.methods.setContractRegistry(contractRegistryInstance.options.address).estimateGas({from: consumer})

    // Set the contract registry in both billing and electric meter instances
    await billSystemInstance.methods.setContractRegistry(contractRegistryInstance.options.address).send({from: owner, gas: setRegistryAtBillingGas});
    await electricMeterInstance.methods.setContractRegistry(contractRegistryInstance.options.address).send({from: consumer, gas: setRegistryAtMeterGas})

    // Set the billing instance in consumer electric meter hardware
    const setBillGas = await electricMeterInstance.methods.setBillSystemAddress(billSystemInstance.options.address).estimateGas({from: consumer})
    await electricMeterInstance.methods.setBillSystemAddress(billSystemInstance.options.address).send({from: consumer, gas: setBillGas})

    // Enable a contract between seller and consumer
    const contractParams = [
      shaLedgerInstance.options.address,
      seller,
      consumer,
      web3.utils.toBN(web3.utils.toWei(priceSha, 'ether')),
      true,
      ipfsHash
    ];

    const newContractGas = await contractRegistryInstance.methods.newContract(...contractParams).estimateGas({from: owner});
    await contractRegistryInstance.methods.newContract(...contractParams).send({from: owner, gas: newContractGas});
    fakeContract = await contractRegistryInstance.methods.getContract(contractId).call({from: owner});

    // 100 "Sha" for each account, make it rain!
    tokenDecimals = await shaLedgerInstance.methods.decimals().call();
    const initialBalance = (web3.utils.toBN(100)).pow(web3.utils.toBN(tokenDecimals));
    await Promise.map([0, 1, 2], account => shaLedgerInstance.methods.mint(accounts[account], initialBalance).send({ from: accounts[0]}));
  });
/*
  it('Should be able to set a new contract into the electric meter', async function() {
    const gas = await electricMeterInstance.methods.setEnergyContract(contractId).estimateGas({from: consumer});
    await electricMeterInstance.methods.setEnergyContract(contractId).send({from: consumer, gas});

    const currentContractIndex = await electricMeterInstance.methods.currentContractIndex().call();

    const currentContract = await contractRegistryInstance.methods.getContract(currentContractIndex).call();
    assert.equal(currentContract.tokenAddress, fakeContract.tokenAddress);
    assert.equal(currentContract.seller, fakeContract.seller);
    assert.equal(currentContract.consumer, fakeContract.consumer);
    assert.equal(currentContract.price, fakeContract.price);
    assert.equal(currentContract.ipfsContractMetadata, ipfsHash);
  });*/
  
  it('Should be able to generate a bill', async function() {
    const wattsHourConsumed = web3.utils.toBN(1.5 * 1000); // 1.5 kWh to watt Hour
    const gas = await electricMeterInstance.methods.setEnergyContract(contractId).estimateGas({from: accounts[2]});
    await electricMeterInstance.methods.setEnergyContract(contractId).send({from: accounts[2], gas});

    const address = await billSystemInstance.methods.contractRegistryAddress().call();
    const billAdd = await electricMeterInstance.methods.billSystemAddress().call();
    console.log("consuming energy with contract...", address, contractRegistryInstance.options.address);
    
    console.log("current bill address", billAdd, billSystemInstance.options.address)
    
    const energyConsumedGas = await electricMeterInstance.methods.energyConsumed(wattsHourConsumed, ipfsHash, billAdd, address).estimateGas({from: accounts[2]});
    const tx = await electricMeterInstance.methods.energyConsumed(wattsHourConsumed, ipfsHash, billAdd, address).send({from: accounts[2], gas: energyConsumedGas})
    console.log("tx", tx)
    const newId = tx.events.NewBill.returnValues["index"];

    console.log("setting getting bill", newId)
    const bill = await billSystemInstance.methods.getBill(web3.utils.toBN(newId)).call();
    const consumerBillsLength = await billSystemInstance.methods.getConsumerBillsLength(fakeContract.consumer).call();
    const sellerBillsLength = await billSystemInstance.methods.getSellerBillsLength(fakeContract.seller).call();

    const {
      whConsumed,
      tokenAddress,
      seller,
      consumer,
      price,
      amount,
      ipfsMetadata
    } = bill;

    assert.equal(whConsumed, wattsHourConsumed);
    assert.equal(tokenAddress, fakeContract.token);
    assert.equal(seller, fakeContract.seller);
    assert.equal(consumer, fakeContract.consumer);
    assert.equal(price, fakeContract.price);
    assert.equal(web3.utils.fromWei(price, "ether"), priceUsd);
    assert.equal(amount, fakeContract.price.mul(wattsHourConsumed));
    assert.equal(ipfsMetadata, ipfsHash);
    assert.equal(consumerBillsLength, 1);
    assert.equal(sellerBillsLength, 1);
    assert.equal("debug test error", false)
  });
});

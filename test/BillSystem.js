const truffleAssert = require("truffle-assertions");
const ShaLedger = artifacts.require("shasta-os/ShaLedger");
const BillSystem = artifacts.require("shasta-os/BillSystem");
const ContractRegistry = artifacts.require("shasta-os/ContractRegistry");
const Promise = require("bluebird");

/**
 * SharedMap test cases
 */
contract('BillSystem', function(accounts) {
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

  // In each test the contracts are deployed again, recovering the initial state.
  beforeEach('Initialize contract with Web3 state per test case', async function () {
    // Currently shaLedger is a fake USD ERC20 token. Bill system allows any
    // ERC20 compatible token and Ether. The seller-consumer contract will determine
    // the token used.

    // Initialize each contract data in Web3, instead of Truffle contract.
    console.log("\nWeb3 version: ", web3.version)
    const shaLedgerContract = await new web3.eth.Contract(ShaLedger.abi);
    const billSystemContract = await new web3.eth.Contract(BillSystem.abi);
    const contractRegistryContract = await new web3.eth.Contract(ContractRegistry.abi);

    const shaLedgerGas = await shaLedgerContract.deploy({ data: ShaLedger.bytecode }).estimateGas({from: owner});
    const billSystemGas = await billSystemContract.deploy({ data: BillSystem.bytecode }).estimateGas({from: owner});
    const contractRegistryGas = await contractRegistryContract.deploy({ data: ContractRegistry.bytecode }).estimateGas({from: owner})

    shaLedgerInstance = await shaLedgerContract.deploy({ data: ShaLedger.bytecode }).send({from: owner, gas: shaLedgerGas});
    billSystemInstance = await billSystemContract.deploy({ data: BillSystem.bytecode }).send({from: owner, gas: billSystemGas});
    contractRegistryInstance = await contractRegistryContract.deploy({ data: ContractRegistry.bytecode }).send({from: owner, gas: contractRegistryGas});

    // Estimate gas for setting contract registry at billing and electric meter instances
    const setRegistryAtBillingGas = await billSystemInstance.methods.setContractRegistry(contractRegistryInstance.options.address).estimateGas({from: owner});
    await billSystemInstance.methods.setContractRegistry(contractRegistryInstance.options.address).send({from: owner, gas: setRegistryAtBillingGas});

    // Enable a contract between seller and consumer
    const contractParams = [
      shaLedgerInstance.options.address,
      seller,
      consumer,
      web3.utils.toBN(web3.utils.toWei(priceSha, 'ether')),
      web3.utils.toBN(1.5 * 1000),
      true,
      ipfsHash
    ];

    const newContractGas = await contractRegistryInstance.methods.newContract(...contractParams).estimateGas({from: owner});
    await contractRegistryInstance.methods.newContract(...contractParams).send({from: owner, gas: newContractGas});
    fakeContract = await contractRegistryInstance.methods.getContract(contractId).call({from: owner});

    // 100 "Sha" for each account, make it rain!
    tokenDecimals = await shaLedgerInstance.methods.decimals().call();
    const initialBalance = web3.utils.toWei('100', 'ether');
    await Promise.map([0, 1, 2], account => shaLedgerInstance.methods.mint(accounts[account], initialBalance).send({ from: accounts[0]}));
  });

  it('Should be able to generate a bill', async function() {
    const wattsHourConsumed = web3.utils.toBN(1.5 * 1000); // 1.5 kWh to watt Hour

    const energyConsumedGas = await billSystemInstance.methods.generateBill(wattsHourConsumed, contractId, ipfsHash).estimateGas({from: accounts[2]});
    const tx = await billSystemInstance.methods.generateBill(wattsHourConsumed, contractId, ipfsHash).send({from: accounts[2], gas: energyConsumedGas})
    const newId = tx.events.NewBill.returnValues["index"];

    const bill = await billSystemInstance.methods.getBill(web3.utils.toBN(newId)).call();
    const consumerBillsLength = await billSystemInstance.methods.getConsumerBillsLength(fakeContract.consumer).call();
    const sellerBillsLength = await billSystemInstance.methods.getSellerBillsLength(fakeContract.seller).call();

    const {
      whConsumed,
      tokenAddress,
      price,
      amount,
      ipfsMetadata
    } = bill;

    assert.equal(whConsumed, wattsHourConsumed);
    assert.equal(tokenAddress, fakeContract.tokenAddress);
    assert.equal(seller, bill.seller);
    assert.equal(consumer, bill.consumer);
    assert.equal(price, fakeContract.price);
    assert.equal(web3.utils.fromWei(price, "ether"), priceSha);
    assert.equal(amount, web3.utils.toBN(price).mul(wattsHourConsumed));
    assert.equal(ipfsMetadata, ipfsHash);
    assert.equal(consumerBillsLength, 1);
    assert.equal(sellerBillsLength, 1);
  });
});

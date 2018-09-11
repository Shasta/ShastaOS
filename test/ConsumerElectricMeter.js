const truffleAssert = require("truffle-assertions");
const ShaLedger = artifacts.require("shasta-os/ShaLedger");
const BillSystem = artifacts.require("shasta-os/BillSystem");
const ConsumerElectricMeter = artifacts.require("shasta-os/ConsumerElectricMeter");
const Promise = require("bluebird");

/**
 * SharedMap test cases
 */
contract('ConsumerElectricMeter', function(accounts) {
  // Participants
  var owner = accounts[0];
  var seller = accounts[1];
  var consumer = accounts[2];

  const priceUsd = "0.00017" // FakeUSD/wattHour

  // Contract pointers
  let shaLedgerInstance;
  let billSystemInstance;
  let electricMeterInstance;

  let tokenDecimals;
  // Fake IPFS hash string for testing purposes
  const ipfsHash = "QmZfSNpHVzTNi9gezLcgq64Wbj1xhwi9wk4AxYyxMZgtCc";

  // Seller-Consumer contract;
  let fakeContract;

  // In each test the contracts are deployed again, recovering the initial state.
  beforeEach('Initialize contract with Web3 state per test case', async function () {
    // Currently shaLedger is a fake USD ERC20 token. Bill system allows any
    // ERC20 compatible token and Ether. The seller-consumer contract will determine
    // the token used.

    // Initialize each contract data in Web3, instead of Truffle contract.
    const shaLedgerContract = await new web3.eth.Contract(ShaLedger.abi);
    const billSystemContract = await new web3.eth.Contract(BillSystem.abi);
    const electricMeterContract = await new web3.eth.Contract(ConsumerElectricMeter.abi);

    const shaLedgerGas = await shaLedgerContract.deploy({ data: ShaLedger.bytecode }).estimateGas({from: owner});
    const billSystemGas = await billSystemContract.deploy({ data: BillSystem.bytecode }).estimateGas({from: owner});
    const meterGas = await electricMeterContract.deploy({ data: ConsumerElectricMeter.bytecode }).estimateGas({from: accounts[2]})

    shaLedgerInstance = await shaLedgerContract.deploy({ data: ShaLedger.bytecode }).send({from: owner, gas: shaLedgerGas});
    billSystemInstance = await billSystemContract.deploy({ data: BillSystem.bytecode }).send({from: owner, gas: billSystemGas});
    electricMeterInstance = await electricMeterContract.deploy({ data: ConsumerElectricMeter.bytecode }).send({from: accounts[2], gas: meterGas});

    // Set the billing instance in consumer electric meter hardware
    const setBillGas = await electricMeterInstance.methods.setBillSystemAddress(billSystemInstance.options.address).estimateGas({from: consumer})
    await electricMeterInstance.methods.setBillSystemAddress(billSystemInstance.options.address).send({from: consumer, gas: setBillGas})
    const newBillAddress = await electricMeterInstance.methods.billSystemAddress().call();
    console.log("new bill", newBillAddress, "current bil", billSystemInstance.options.address)

    // 100 usd for each account, make it rain!
    tokenDecimals = await shaLedgerInstance.methods.decimals().call();
    const initialBalance = (web3.utils.toBN(100)).pow(web3.utils.toBN(tokenDecimals));
    await Promise.map([0, 1, 2], account => shaLedgerInstance.methods.mint(accounts[account], initialBalance).send({ from: accounts[0]}));

    // Create the fake contract in JS
    fakeContract = {
      seller,
      consumer,
      price: web3.utils.toBN(web3.utils.toWei(priceUsd, 'ether')),
      token: shaLedgerInstance.options.address,
    }
    console.log("BeforeEach is finished.")
  });

  it('Should be able to set a new contract', async function() {
    const gas = await electricMeterInstance.methods.setEnergyContract(fakeContract.token, fakeContract.seller, fakeContract.consumer, fakeContract.price,  ipfsHash).estimateGas({from: consumer});
    await electricMeterInstance.methods.setEnergyContract(fakeContract.token, fakeContract.seller, fakeContract.consumer, fakeContract.price, ipfsHash).send({from: consumer, gas});

    const currentContract = await electricMeterInstance.methods.getCurrentContract().call();

    assert.equal(currentContract.tokenAddress, fakeContract.token);
    assert.equal(currentContract.seller, fakeContract.seller);
    assert.equal(currentContract.consumer, fakeContract.consumer);
    assert.equal(currentContract.price, fakeContract.price);
    assert.equal(currentContract.ipfsContractMetadata, ipfsHash);
  });
  
  it('Should be able to generate a bill', async function() {
    console.log("Start");
    const wattsHourConsumed = web3.utils.toBN(1.5 * 1000); // 1.5 kWh to watt Hour
    const gas = await electricMeterInstance.methods.setEnergyContract(fakeContract.token, fakeContract.seller, fakeContract.consumer, fakeContract.price,  ipfsHash).estimateGas({from: accounts[2]});
    await electricMeterInstance.methods.setEnergyContract(fakeContract.token, fakeContract.seller, fakeContract.consumer, fakeContract.price, ipfsHash).send({from: accounts[2], gas});
    const currentBillAddress = await electricMeterInstance.methods.billSystemAddress().call();
    console.log("curr biill", currentBillAddress)
    console.log("curr bill addr", billSystemInstance.options.address)
    const energyConsumedGas = await electricMeterInstance.methods.energyConsumed(wattsHourConsumed, ipfsHash).estimateGas({from: accounts[2]});
    electricMeterInstance.methods.energyConsumed(1500, ipfsHash).send({from: accounts[0], gas: 3000000})
    .on('receipt', function(receipt){
      console.log("OK", receipt);
    })
    .on('error', error => {
      console.log(error)
    });


    /*
    console.log("AFTR")

    console.log("bill id", billId);

    const txConfig = { from: fakeContract.consumer };
    txConfig.gas = await billSystemInstance.methods.generateBill(...billParams).estimateGas(txConfig);
    const bill = await billSystemInstance.methods.getBill(web3.utils.toBN(billId)).call();
    const consumerBillsLength = await billSystemInstance.methods.getConsumerBillsLength(fakeContract.consumer).call();
    const sellerBillsLength = await billSystemInstance.methods.getSellerBillsLength(fakeContract.seller).call();

    const {
      whConsumed,
      tokenAddress,
      seller,
      consumer,
      price,
      amount,
      ipfsMetadata,
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
    assert.equal(sellerBillsLength, 1); */
  });
});

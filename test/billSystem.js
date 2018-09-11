const truffleAssert = require("truffle-assertions");
const ShaLedger = artifacts.require("shasta-os/ShaLedger");
const BillSystem = artifacts.require("shasta-os/BillSystem");
const Promise = require("bluebird");

/**
 * SharedMap test cases
 */
contract('BillSystem', function(accounts) {
  // Participants
  const owner = accounts[0];
  const seller = accounts[1];
  const consumer = accounts[2];
  const priceUsd = "0.00017" // FakeUSD/wattHour

  // Contract pointers
  let shaLedgerInstance;
  let billSystemInstance;
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
    const shaLedgerContract = await new web3.eth.Contract(ShaLedger.abi, ShaLedger.address);
    const billSystemContract = await new web3.eth.Contract(BillSystem.abi, BillSystem.address);

    const shaLedgerGas = await shaLedgerContract.deploy({ data: ShaLedger.bytecode }).estimateGas({from: owner});
    const billSystemGas = await billSystemContract.deploy({ data: BillSystem.bytecode }).estimateGas({from: owner});

    shaLedgerInstance = await shaLedgerContract.deploy({ data: ShaLedger.bytecode }).send({from: owner, gas: shaLedgerGas});
    billSystemInstance = await billSystemContract.deploy({ data: BillSystem.bytecode }).send({from: owner, gas: billSystemGas});

    tokenDecimals = await shaLedgerInstance.methods.decimals().call();
    
    // 100 usd for each account, make it rain!
    const initialBalance = (web3.utils.toBN(100)).pow(web3.utils.toBN(tokenDecimals));
    await Promise.map([0, 1, 2], account => shaLedgerInstance.methods.mint(accounts[account], initialBalance).send({ from: accounts[0]}));

    // Create the fake contract in JS
    fakeContract = {
      seller,
      consumer,
      price: web3.utils.toBN(web3.utils.toWei(priceUsd, 'ether')),
      token: shaLedgerInstance.options.address,
    }

  });

  it('Should be able to create a new bill', async function() {
    const wattsHourConsumed = web3.utils.toBN(1.5 * 1000); // 1.5 kWh to watt Hour
    const billParams = [wattsHourConsumed, fakeContract.price, fakeContract.seller, fakeContract.token, ipfsHash]
    const txConfig = { from: fakeContract.consumer };
    txConfig.gas = await billSystemInstance.methods.generateBill(...billParams).estimateGas(txConfig);
    const result = await billSystemInstance.methods.generateBill(...billParams).send(txConfig);
    const eventResult = result.events.NewBill.returnValues["index"];
    const bill = await billSystemInstance.methods.getBill(eventResult).call();
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
    assert.equal(sellerBillsLength, 1);
  });
});

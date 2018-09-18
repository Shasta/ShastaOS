const truffleAssert = require("truffle-assertions");
const ShaLedger = artifacts.require("shasta-os/ShaLedger");
const BillSystem = artifacts.require("shasta-os/BillSystem");
const ConsumerElectricMeter = artifacts.require("shasta-os/ConsumerElectricMeter");
const ContractRegistry = artifacts.require("shasta-os/ContractRegistry");
const Promise = require("bluebird");

/**
 * SharedMap test cases
 */
contract('PrepaidContract', function(accounts) {
  // Participants
  const owner = accounts[0];
  const seller = accounts[1];
  const consumer = accounts[2];

  const priceSha = "0.0002" // Sha/wattHour
  const contractId = 0;
  // Contract pointers
  let shaLedgerInstance;
  let billSystemInstance;
  let electricMeterInstance;
  let contractRegistryInstance;

  let tokenDecimals;
  // Fake IPFS hash string for testing purposes
  const ipfsHash = "QmZfSNpHVzTNi9gezLcgq64Wbj1xhwi9wk4AxYyxMZgtCc";
  const ipfsBillHash = "QmZfSNpHVzTNi9gezLcgq64Wbj1xhwi9wk4AxYyxMZgtCc";

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

    // 100 "Sha" for each account, make it rain!
    tokenDecimals = await shaLedgerInstance.methods.decimals().call();
    const initialBalance = web3.utils.toWei('100', 'ether');
    await Promise.map([0, 1, 2], account => shaLedgerInstance.methods.mint(accounts[account], initialBalance).send({ from: accounts[0]}));
  });

  it('Should be able to create and pay a prepaid contract between user and producer, in one TX', async function() {
    const consumerBalancePrior = await shaLedgerInstance.methods.balanceOf(consumer).call();
    const rawPriceSha = web3.utils.toBN(web3.utils.toWei(priceSha, 'ether'));
    const monthlyWattsHour = web3.utils.toBN(200 * 1000); // 20kWh of monthly consumption
    const totalPrepaidShaCost = rawPriceSha.mul(monthlyWattsHour);
    console.log(totalPrepaidShaCost)
    // Enable a contract between seller and consumer
    const contractParams = [
      shaLedgerInstance.options.address,
      seller,
      consumer,
      rawPriceSha,
      monthlyWattsHour,
      true,
      ipfsHash,
      ipfsBillHash
    ];

    // const newContractGas = await billSystemInstance.methods.newPrepaidContract(...contractParams).estimateGas({from: consumer});
    try {
      const newContractAbi = await billSystemInstance.methods.newPrepaidContract(...contractParams).encodeABI();
      const newContractPayment = await shaLedgerInstance.methods.approveAndCall(billSystemInstance.options.address, totalPrepaidShaCost, newContractAbi).send({gas: 3000000, from: consumer});
      const consumerBalanceAfter = await shaLedgerInstance.methods.balanceOf(consumer).call();
      console.log(newContractPayment)
      console.log("prior balance", web3.utils.fromWei(consumerBalancePrior, 'ether'));
      console.log("after balance", web3.utils.fromWei(consumerBalanceAfter, 'ether'));
    } catch (err) {
      console.log(err)
      throw err;
    }
  });

  it('Should be able to allow producer withdraw his SHA', async function() {
    const sellerBalancePrior = await shaLedgerInstance.methods.balanceOf(seller).call();
    const rawPriceSha = web3.utils.toBN(web3.utils.toWei(priceSha, 'ether'));
    const monthlyWattsHour = web3.utils.toBN(200 * 1000); // 20kWh of monthly consumption
    const totalPrepaidShaCost = rawPriceSha.mul(monthlyWattsHour);
    console.log(totalPrepaidShaCost)
    // Enable a contract between seller and consumer
    const contractParams = [
      shaLedgerInstance.options.address,
      seller,
      consumer,
      rawPriceSha,
      monthlyWattsHour,
      true,
      ipfsHash,
      ipfsBillHash
    ];

    // const newContractGas = await billSystemInstance.methods.newPrepaidContract(...contractParams).estimateGas({from: consumer});
    try {
      // Create contract
      const newContractAbi = await billSystemInstance.methods.newPrepaidContract(...contractParams).encodeABI();
      const newContractPayment = await shaLedgerInstance.methods.approveAndCall(billSystemInstance.options.address, totalPrepaidShaCost, newContractAbi).send({gas: 3000000, from: consumer})

      // Withdraw Sha tokens
      const withdrawShaGas = await billSystemInstance.methods.withdrawERC20(shaLedgerInstance.options.address).estimateGas({from: seller})
      const withdrawSha = await billSystemInstance.methods.withdrawERC20(shaLedgerInstance.options.address).send({gas: withdrawShaGas, from: seller})
      const sellerBalanceAfter = await shaLedgerInstance.methods.balanceOf(seller).call();

      console.log("prior balance", web3.utils.fromWei(sellerBalancePrior, 'ether'));
      console.log("after balance", web3.utils.fromWei(sellerBalanceAfter, 'ether'));
      assert.equal(web3.utils.fromWei(sellerBalanceAfter, 'ether'), "140");
    } catch (err) {
      console.log(err)
      throw err;
    }
  });
});

const HardwareData = artifacts.require("shasta-os/HardwareData");
const Promise = require("bluebird");


contract('HardwareTests', function (accounts) {

    const owner = accounts[0];
    const user = accounts[1]
    let HardwareInstance;
    let randomHash = web3.utils.utf8ToHex("aRandomHash");

    before('Initialize contract with Web3', async function () {

        const HardwareContract = await new web3.eth.Contract(HardwareData.abi);
        const hardwareGas = await HardwareContract.deploy({ data: HardwareData.bytecode }).estimateGas({ from: owner });
        HardwareInstance = await HardwareContract.deploy({ data: HardwareData.bytecode }).send({ from: owner, gas: hardwareGas });
        console.log(HardwareInstance)
    });

    it('Should add a hash to the smart contract and check it exists', async function () {

        //Add new hash
        const gas = await HardwareInstance.methods.addHash(randomHash).estimateGas({ from: user });
        await HardwareInstance.methods.addHash(randomHash).send({ from: user, gas: gas });
        
        //Check the has has been added
        let hashes = await HardwareInstance.ipfsHashes.call();
        console.log("Hashes: ", hashes);

    });

});

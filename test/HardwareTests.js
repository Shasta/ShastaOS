const HardwareData = artifacts.require("shasta-os/HardwareData");
const User = artifacts.require("shasta-os/User");
const ShastaMarket = artifacts.require("shasta-os/ShastaMarket")

const Promise = require("bluebird");


contract('HardwareTests', function (accounts) {

    const owner = accounts[0];
    const user = accounts[1]
    let HardwareInstance;
    let UserInstance;
    let randomHash = web3.utils.utf8ToHex("aRandomHash");
    const randomHardwareId = web3.utils.utf8ToHex("randomHardwareId");
    const randomUsername = web3.utils.utf8ToHex("randomUsername");

    before('Initialize contracts with Web3', async function () {

        const MarketContract = await new web3.eth.Contract(ShastaMarket.abi);
        const marketGas = await MarketContract.deploy({ data: ShastaMarket.bytecode }).estimateGas({ from: owner });
        MarketInstance = await MarketContract.deploy({ data: ShastaMarket.bytecode }).send({ from: owner, gas: marketGas });

        const HardwareContract = await new web3.eth.Contract(HardwareData.abi);
        const hardwareGas = await HardwareContract.deploy({ data: HardwareData.bytecode }).estimateGas({ from: owner });
        HardwareInstance = await HardwareContract.deploy({ data: HardwareData.bytecode }).send({ from: owner, gas: hardwareGas });
        
        const UserContract = await new web3.eth.Contract(User.abi);
        const userGas = await UserContract.deploy({ data: User.bytecode, arguments: [MarketInstance.options.address] }).estimateGas({ from: owner });
        UserInstance = await UserContract.deploy({ data: User.bytecode, arguments: [MarketInstance.options.address] }).send({ from: owner, gas: userGas });
       
    });

    it('Should create a user and add a new hardware to that user', async function () {

        //Create a new user
        const gas = await UserInstance.methods.createUser(randomUsername, randomHash).estimateGas({ from: user });
        await UserInstance.methods.createUser(randomUsername, randomHash).send({ from: user, gas: gas });

        //Add new hardware to the created user
        const hardwareGas = await HardwareInstance.methods.addNewHardwareId(randomHardwareId).estimateGas({ from: user });
        await HardwareInstance.methods.addNewHardwareId(randomHardwareId).send({ from: user, gas: hardwareGas });
        
        //Check the hardware exists for the created user
        const hardwareId = await HardwareInstance.methods.getHardwareIdFromSender().call({ from: user });
        assert.equal(randomHardwareId, hardwareId);
    })


    it('Should add a hash to the smart contract and check it exists', async function () {

        //Add new hash
        const gas = await HardwareInstance.methods.addHash(randomHash).estimateGas({ from: user });
        await HardwareInstance.methods.addHash(randomHash).send({ from: user, gas: gas });
        
        //Get number of hashes
        const hashesCount = await HardwareInstance.methods.getHashesCount().call();
        assert.equal(hashesCount, 1)

        //Check the hash has been added
        let hash = await HardwareInstance.methods.ipfsHashes(hashesCount - 1).call();
        assert.equal(hash, randomHash);
    });

});

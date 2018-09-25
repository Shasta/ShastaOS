const User = artifacts.require("shasta-os/User");
const ShastaMarket = artifacts.require("shasta-os/ShastaMarket")
const Promise = require("bluebird");


contract('OffersCreation', function (accounts) {

    const owner = accounts[0];
    const user = accounts[1]
    let UserInstance;
    let MarketInstance;

    let name = web3.utils.utf8ToHex("myOrg");
    let offerIndexes;

    before('Initialize contract with Web3', async function () {

        const MarketContract = await new web3.eth.Contract(ShastaMarket.abi);
        const UserContract = await new web3.eth.Contract(User.abi);

        const marketGas = await MarketContract.deploy({ data: ShastaMarket.bytecode }).estimateGas({ from: owner });
        MarketInstance = await MarketContract.deploy({ data: ShastaMarket.bytecode }).send({ from: owner, gas: marketGas });

        const userGas = await UserContract.deploy({ data: User.bytecode, arguments: [MarketInstance.options.address] }).estimateGas({ from: owner });
        UserInstance = await UserContract.deploy({ data: User.bytecode, arguments: [MarketInstance.options.address] }).send({ from: owner, gas: userGas });

    });

    it('Should create a new organization', async function () {

        const gas = await UserInstance.methods.createUser(name, "0x123456").estimateGas({ from: user });
        await UserInstance.methods.createUser(name, "0x123456").send({ from: user, gas: gas });
        let userCount = await UserInstance.methods.getUserCount().call();
        //Check created users is two (the created when deploy and this one)
        assert.equal(userCount, 2);

        //Check address has user
        const hasUser = await UserInstance.methods.hasUser(user).call();
        assert(hasUser);

    });

    it('Should create a new offer', async function () {

        const gas = await UserInstance.methods.createOffer(200, "0x123456").estimateGas({ from: user });
        await UserInstance.methods.createOffer(200, "0x123456").send({ from: user, gas: gas });
        let offersCount = await MarketInstance.methods.getOffersLength().call();
        //Check one offer created
        assert.equal(1, offersCount);
        offerIndexes = await MarketInstance.methods.getOfferIndexesFromAddress().call({ from: user })
        //Check array length is one
        assert.equal(offerIndexes.length, 1)
        //Get the offer
        const offer = await MarketInstance.methods.getOfferFromIndex(offerIndexes[0]).call();
        assert.equal(offer[2],true);

    });

    it('Should cancel an offer', async function () {

        const gas = await UserInstance.methods.cancelOffer(offerIndexes[0], "0x123456").estimateGas({ from: user });
        await UserInstance.methods.cancelOffer(offerIndexes[0], "0x123456").send({ from: user, gas: gas });
        let canceledOffer = await MarketInstance.methods.getOfferFromIndex(offerIndexes[0]).call();
        assert.equal(canceledOffer[2],false);

    });
});
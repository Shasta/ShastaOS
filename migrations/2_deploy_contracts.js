var SharedMapPrice = artifacts.require('shasta-os/SharedMapPrice');
var User = artifacts.require('shasta-os/User');
var ShastaMarket = artifacts.require('shasta-os/ShastaMarket');
var BillSystem = artifacts.require('shasta-os/BillSystem');
var ContractRegistry = artifacts.require('shasta-os/ContractRegistry');

module.exports = function(deployer) {
  deployer.deploy(BillSystem);
  deployer.deploy(ContractRegistry);
  deployer.deploy(ShastaMarket).then(function() {
    return deployer.deploy(User, ShastaMarket.address).then(function() {
      return deployer.deploy(SharedMapPrice, User.address, ShastaMarket.address);
    })
  })
};
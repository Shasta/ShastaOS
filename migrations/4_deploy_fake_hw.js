var ConsumerElectricMeter = artifacts.require('shasta-os/ConsumerElectricMeter')

// Deploy fake USD ledger, 18 decimals
module.exports = function(deployer, network, accounts) {
  deployer.deploy(ConsumerElectricMeter);
};
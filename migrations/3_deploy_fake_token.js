var ShaLedger = artifacts.require('shasta-os/ShaLedger')

// Deploy fake USD ledger, 18 decimals
module.exports = function(deployer, network, accounts) {
  deployer.deploy(ShaLedger);
};
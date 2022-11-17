const LazyNFT = artifacts.require("LazyNFT");

module.exports = function (deployer) {
  deployer.deploy(LazyNFT);
};

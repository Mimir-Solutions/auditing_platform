require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/test-helpers");
require("hardhat-gas-reporter");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      gas: "auto",
      gasPrice: "auto",
      loggingEnabled: false
    },
    hardhatNode: {
      url: "127.0.0.1",
      port: 7546,
      network_id: "*"
    },
    ganache: {
      url: "127.0.0.1",
      port: 7545,
      network_id: "*"
    },
    rinkeby: {
      url: "https://rinkeby.infura.io/v3/123abc123abc123abc123abc123abcde"
    }
  },
  solidity: {
    version: "0.7.5",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  /*
  gasReporter: {
    enabled: true,
    currency: 'CHF',
    gasPrice: 21
  }
  */
}
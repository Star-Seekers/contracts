require("dotenv").config();

const { ethers } = require("ethers");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("hardhat-gas-reporter");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-deploy");
require("hardhat-contract-sizer");
require("solidity-coverage");
// Tasks
task("seed", "Seed account with Buidler ETH")
  .addParam("account", "The account's address")
  .setAction(async (taskArgs) => {
    const accounts = await ethers.getSigners();

    await accounts[0].sendTransaction({
      to: taskArgs.account,
      value: ethers.utils.parseEther("1000.0"),
    });

    console.log(`Star Seekers: Seeded ${taskArgs.account} with 1000 ETH`);
  });

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "hardhat",
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
      },
    },
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
  },
  paths: {
    sources: "./src",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  networks: {
    hardhat: {
      gasPrice: 0,
      blockGasLimit: 100000000,
      allowUnlimitedContractSize: true,
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
    coinmarketcap: process.env.COINMARKETCAP,
    showTimeSpent: "true",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  namedAccounts: {
    playerOne: {
      default: 0,
    },
    admin: {
      default: 1,
    },
    federation: {
      default: 3,
    },
    userOne: {
      default: 3,
    },
  },
};

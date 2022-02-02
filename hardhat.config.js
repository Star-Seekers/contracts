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

    console.log(`Star Seekers: Seeded ${taskArgs.account}`);
  });

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
    localhost: {
      live: false,
      saveDeployments: true,
      tags: ["local"],
    },
    hardhat: {
      saveDeployments: true,
      tags: ["test", "local"],
      forking: {
        url: "https://api.avax.network/ext/bc/C/rpc",
      },
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
    coinmarketcap: process.env.COINMARKETCAP,
    showTimeSpent: "true",
  },
  // etherscan: {
  //   apiKey: process.env.ETHERSCAN_API_KEY,
  // },
  namedAccounts: {
    admin: {
      default: 0,
    },
    federation: {
      default: 1,
    },
    playerOne: {
      default: 2,
    },
    playerTwo: {
      default: 3,
    },
    avaxChainlink: {
      default: "0x0a77230d17318075983913bc2145db16c7366156",
    },
    fakeContractForTests: {
      default: 4,
    },
  },
};

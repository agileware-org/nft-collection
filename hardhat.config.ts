/* eslint-disable comma-dangle */
import * as dotenv from "dotenv";

import { HardhatUserConfig } from "hardhat/types";

import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "@nomiclabs/hardhat-etherscan";
import "solidity-coverage";
import "hardhat-deploy";
import "hardhat-gas-reporter";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [{
        version: "0.8.9",
        settings: {
          optimizer: {
            runs: 200000,
            enabled: true,
          }
        }
      }]
  },
  defaultNetwork: "rinkeby",
  namedAccounts: {
    deployer: {
      default: 0,
      1: "0xDEE48aB42ceEb910c8C61a8966A57Dcf3E8B6706",
      4: "0xDEE48aB42ceEb910c8C61a8966A57Dcf3E8B6706",
    }
  },
  networks: {
    hardhat: {
      mining: {
        auto: true,
        interval: 200
      }
    },
    localhost: {},
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [process.env.PRIVATE_KEY || ""],
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
      gasPrice: 70000000000, // 70 Gwei
      accounts: [process.env.PRIVATE_KEY || ""],
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  gasReporter: {
    currency: "USD",
    enabled: process.env.REPORT_GAS !== undefined,
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    maxMethodDiff: 10,
  },
  typechain: {
    outDir: "src/types"
  },
};

export default config;

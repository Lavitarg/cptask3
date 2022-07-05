import * as dotenv from "dotenv";

import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import {environment} from "./environment";


dotenv.config();


const PK = environment.pk;
const INFURA_URL = environment.infuraUrl;
const ETHER_KEY = environment.etherKey;
module.exports = {
  solidity: "0.8.4",
  networks: {
    rinkeby: {
      url: INFURA_URL,
      accounts: [PK]
    }
  },
  etherscan: {
    apiKey: {
      rinkeby: ETHER_KEY
    },
    customChains: [
      {
        network: "rinkeby",
        chainId: 4,
        urls: {
          apiURL: "https://api-rinkeby.etherscan.io/api",
          browserURL: "https://rinkeby.etherscan.io"
        }
      }
    ]
  }
};

/** @type import('hardhat/config').HardhatUserConfig */
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: "0.8.22",
  networks: {
    nidumTestnet: {
      url: process.env.NIDUM_TESTNET_RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
    },
    polygonAmoy: {
      url: process.env.POLYGON_AMOY_RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
    }
  },
  etherscan: {
    apiKey: {
      nidumTestnet: "YOUR_NIDUM_API_KEY",
      polygonAmoy: "YOUR_POLYGONSCAN_API_KEY",
    }
  }
};

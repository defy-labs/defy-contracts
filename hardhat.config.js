require('dotenv').config();
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

const { MAINNET_API_URL, POLYGON_API_URL, MUMBAI_API_URL, PRIVATE_KEY, ETHERSCAN_API_KEY, POLYGONSCAN_API_KEY } = process.env;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 50
      }
    }
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    mainnet: {
      url: MAINNET_API_URL ?? '',
      accounts: PRIVATE_KEY ? [`0x${PRIVATE_KEY}`] : []
    },
    polygon: {
      url: POLYGON_API_URL ?? '',
      accounts: PRIVATE_KEY ? [`0x${PRIVATE_KEY}`] : []
    },
    polygon_mumbai: {
      url: MUMBAI_API_URL ?? '',
      accounts: PRIVATE_KEY ? [`0x${PRIVATE_KEY}`] : []
    }
  },
  etherscan: {
    apiKey: {
      mainnet: ETHERSCAN_API_KEY ?? '',
      polygonMumbai: POLYGONSCAN_API_KEY ?? '',
      polygon: POLYGONSCAN_API_KEY ?? '',
    }
  }
};

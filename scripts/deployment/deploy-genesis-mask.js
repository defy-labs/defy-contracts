// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("hardhat");

async function main() {

  // We get the contract to deploy
  const DEFYGenesisMask = await ethers.getContractFactory("DEFYGenesisMask");
  
  const defyGenesisMask = await DEFYGenesisMask.deploy("0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed", "0x326C977E6efc84E512bB9C30f76E30c160eD06FB"); // Mumbai chainlink addresses
  // const defyGenesisMask = await DEFYGenesisMask.deploy("0xAE975071Be8F8eE67addBC1A82488F1C24858067", "0xb0897686c545045afc77cf20ec7a532e3120e0f1"); // Mainnet chainlink addresses

  console.log('Deploying defyGenesisMask')

  await defyGenesisMask.deployed();

  console.log("defyGenesisMask deployed to:", defyGenesisMask.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

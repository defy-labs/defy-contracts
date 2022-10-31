// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("hardhat");

const addresses = require("../temp/decals/drone-killer.json")

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

Array.prototype.count = function() {
  return this.reduce(function(obj, name) {
      obj[name] = obj[name] ? ++obj[name] : 1;
      return obj;
  }, {});
}

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.

  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const DEFYDecals = await ethers.getContractFactory("DEFYDecals");
  const defyDecals = await DEFYDecals.attach("0xd753b94df74a54c76e54cf4c327094d1dfc35ebc")

  for (let i = 0; i < addresses.length; i++) {
		const address = addresses[i].ConnectedWalletAddress
		console.log(`minting to ${address}`)
		await defyDecals.mint(address, 26, 1, "0xd753b94df74a54c76e54cf4c327094d1dfc35ebc", { gasPrice: 50000000000 })
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

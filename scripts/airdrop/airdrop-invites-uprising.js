// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("hardhat");

const addresses = require("../temp/uprising/owners-pg.json")

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
  const DEFYUprisingInvite = await ethers.getContractFactory("DEFYUprisingInvite");
  const defyUprisingInvite = await DEFYUprisingInvite.attach("0x9162c5dcD344B9B3C2527A77a8C2cd7F1334b6e7")

  const chunkSize = 60;
  for (let i = 0; i < addresses.length; i += chunkSize) {
      const chunk = addresses.slice(i, i + chunkSize);
      console.log(`${i}: ${chunk[0]} - ${chunk[chunkSize-1]}`)
      await defyUprisingInvite.safeMint_batch(chunk, { gasPrice: 100000000000, gasLimit: 10000000 })
      console.log('done')
      await sleep(1000)
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

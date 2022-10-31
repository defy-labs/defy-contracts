// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("hardhat");

const tokenContract = '0x86aad261465a1f7432efb8618d6736e910025c69'
const tokenId = 11

const addresses = require("../temp/badges/alpha_all_mission1.json").map(a => a.ConnectedWalletAddress)

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
  const BatchAirdrop = await ethers.getContractFactory("BatchAirdrop");
  const batchAirdrop = await BatchAirdrop.attach("0x4b433b9A785C5F38f425F06AFeECAebBF4A1A752")

  const chunkSize = 60;
  for (let i = 0; i < addresses.length; i += chunkSize) {
      const chunk = addresses.slice(i, i + chunkSize);
			const tokenIds = Array.from({length: chunk.length}, () => tokenId)
			const tokenCounts = Array.from({length: chunk.length}, () => 1)

      console.log(`${i}: ${chunk[0]} - ${chunk[chunkSize-1]}`)
			// console.log(tokenIds)
			// console.log(tokenCounts)
			// console.log(chunk)
      await batchAirdrop.batchAirdrop1155(tokenContract, chunk, tokenIds, tokenCounts, { gasPrice: 100000000000, gasLimit: 10000000 })
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

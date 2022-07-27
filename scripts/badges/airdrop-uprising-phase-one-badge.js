// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("hardhat");

const addresses = require("../temp/uprising/phase-one-minters.json")

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
  const DEFYBadges = await ethers.getContractFactory("DEFYBadges");
  const defyBadges = await DEFYBadges.attach("0x86aad261465a1f7432efb8618d6736e910025c69")
//   const defyBadges = await DEFYBadges.attach("0x7023662dF3D6fDd2E9D948540e22a3a6e174CD00")

  //   function mint(address account, uint256 id, uint256 amount, bytes memory data)
  for (let i = 0; i < addresses.length; i++) {
	const address = addresses[i]
	console.log(`minting to ${address}`)
	await defyBadges.mint(address, 0, 1, "0x7023662dF3D6fDd2E9D948540e22a3a6e174CD00", { gasPrice: 50000000000 })
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

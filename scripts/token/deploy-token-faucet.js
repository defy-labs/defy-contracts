// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const TokenFaucet = await ethers.getContractFactory("TokenFaucet");
  const tokenFaucet = await TokenFaucet.deploy('0xa2c03ABbD5cD696C97061907F17A28A9F7A108BA');

  console.log('Deploying tokenFaucet')

  await tokenFaucet.deployed();

  console.log("tokenFaucet deployed to:", tokenFaucet.address);

	console.log("waiting 20s then verifying...");
	await new Promise(r => setTimeout(r, 20000));

	console.log("verifying");
	await hre.run("verify:verify", {
		address: tokenFaucet.address,
		constructorArguments: [
			'0xa2c03ABbD5cD696C97061907F17A28A9F7A108BA'
		],
	})
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

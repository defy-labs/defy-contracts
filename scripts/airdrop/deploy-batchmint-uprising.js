// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { ethers } = hre;

async function main() {
	const BatchMintUprising = await ethers.getContractFactory("BatchMintUprising");
	const batchMintUprising = await BatchMintUprising.deploy();

	await batchMintUprising.deployed();

	console.log("batchMintUprising deployed to:", batchMintUprising.address);

	console.log("waiting 30s then verifying...");
	await new Promise(r => setTimeout(r, 30000));

	console.log("verifying");
	await hre.run("verify:verify", {
		address: batchMintUprising.address,
	});
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});

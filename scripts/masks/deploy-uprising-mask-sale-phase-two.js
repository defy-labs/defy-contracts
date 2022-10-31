// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { ethers } = hre;

async function main() {
	// Hardhat always runs the compile task when running scripts with its command
	// line interface.
	//
	// If this script is run directly using `node` you may want to call compile
	// manually to make sure everything is compiled
	// await hre.run('compile');

	const env = 'PROD' // 'DEV' || 'PROD'

	const addresses = {
		token: env === 'DEV' ? '0xa2c03abbd5cd696c97061907f17a28a9f7a108ba' : '0xBF9f916bBda29A7F990F5F55c7607D94D7C3A60b',
		inviteTier1: env === 'DEV' ? '0xFc6A13353Bf45462e304218EA51ACd72Da6430c4' : '0xa3b7945a9a964e6a8434c2dfa249181a818a5cd2',
		uprisingMask: env === 'DEV' ? '0x079C888558a553de2aC6D10d7877fEc5a63297b3' : '0x0973f5e8A888f3172c056099EB053879dE972684',
		hotWallet: env === 'DEV' ? '0xcdA56c0EeDB40c0F292CD42A68E1C3AC83DAdef1' : '0xAE2BF730327e95f3998F730aD31CffF29382AaBD'
	}

	const saleStartTime = Math.round(new Date('2022-09-06T00:00:00.000Z').getTime() / 1000)

	// We get the contract to deploy
	console.log('Attaching invite contracts')

	const DEFYUprisingInviteTier1 = await ethers.getContractFactory("DEFYUprisingInvite");
	const defyUprisingInviteTier1 = DEFYUprisingInviteTier1.attach(addresses.inviteTier1);

	console.log('Attaching mask contract')

	const DEFYUprisingMask = await ethers.getContractFactory("DEFYUprisingMask");
	const defyUprisingMask = DEFYUprisingMask.attach(addresses.uprisingMask);

	console.log('Deploying defyUprisingSalePhaseTwo')

	const DEFYUprisingSalePhaseTwo = await ethers.getContractFactory("DEFYUprisingSalePhaseTwo");
	const defyUprisingSalePhaseTwo = await DEFYUprisingSalePhaseTwo.deploy(saleStartTime, '0x005205F4707a7954b9e0248CA6Cda23A65ff99Ef', addresses.token, addresses.inviteTier1, addresses.uprisingMask);

	await defyUprisingSalePhaseTwo.deployed();

	console.log("defyUprisingSalePhaseTwo deployed to:", defyUprisingSalePhaseTwo.address);

	console.log('granting INVITE_SPENDER role on invite contract')
	await defyUprisingInviteTier1.grantRole('0xdccc1989d74912b93bf418567a92dfdbc8fde7ffc7bffb3218a0397a2c4285ae', defyUprisingSalePhaseTwo.address);

	console.log('granting MINTER_ROLE role on mask contract')
	await defyUprisingMask.grantRole('0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6', defyUprisingSalePhaseTwo.address);

	console.log('granting APP_MINTER_ROLE role on mask contract')
	await defyUprisingSalePhaseTwo.grantRole('0xade562200b65c5ad4113d46be0a8ba90f65358fa53a92ee6cb2f95159ff82402', addresses.hotWallet);

	console.log("defyUprisingSalePhaseTwo deployed to:", defyUprisingSalePhaseTwo.address);

	console.log("waiting 30s then verifying...");
	await new Promise(r => setTimeout(r, 30000));

	console.log("verifying");
	await hre.run("verify:verify", {
		address: defyUprisingSalePhaseTwo.address,
		constructorArguments: [
			saleStartTime, '0x005205F4707a7954b9e0248CA6Cda23A65ff99Ef', addresses.token, addresses.inviteTier1, addresses.uprisingMask
		],
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

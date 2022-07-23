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

  const env = 'PROD' // 'DEV' || 'PROD'

  const addresses = {
	inviteTier1: env === 'DEV' ? '0xFc6A13353Bf45462e304218EA51ACd72Da6430c4' : '0xa3b7945a9a964e6a8434c2dfa249181a818a5cd2',
	inviteTier2: env === 'DEV' ? '0xc8Aa0FE090b17CcF594C31FFC314844eE625e900' : '0x9162c5dcD344B9B3C2527A77a8C2cd7F1334b6e7',
	uprisingMask: env === 'DEV' ? '0x079C888558a553de2aC6D10d7877fEc5a63297b3' : '0x0973f5e8A888f3172c056099EB053879dE972684',
  }

  // We get the contract to deploy
  console.log('Attaching invite contracts')

  const DEFYUprisingInviteTier1 = await ethers.getContractFactory("DEFYUprisingInvite");
  const defyUprisingInviteTier1 = DEFYUprisingInviteTier1.attach(addresses.inviteTier1);
  
  const DEFYUprisingInviteTier2 = await ethers.getContractFactory("DEFYUprisingInvite");
  const defyUprisingInviteTier2 = DEFYUprisingInviteTier2.attach(addresses.inviteTier2);

  console.log('Attaching mask contract')

  const DEFYUprisingMask = await ethers.getContractFactory("DEFYUprisingMask");
  const defyUprisingMask = DEFYUprisingMask.attach(addresses.uprisingMask);

  const DEFYUprisingSalePhaseOne = await ethers.getContractFactory("DEFYUprisingSalePhaseOne");
  const defyUprisingSalePhaseOne = await DEFYUprisingSalePhaseOne.deploy(addresses.inviteTier1, addresses.inviteTier2, addresses.uprisingMask);

  console.log('Deploying defyUprisingSalePhaseOne')

  await defyUprisingSalePhaseOne.deployed();

  console.log("defyUprisingSalePhaseOne deployed to:", defyUprisingSalePhaseOne.address);

  console.log('granting INVITE_SPENDER role on invite contract')
  await defyUprisingInviteTier1.grantRole('0xdccc1989d74912b93bf418567a92dfdbc8fde7ffc7bffb3218a0397a2c4285ae', defyUprisingSalePhaseOne.address);
  await defyUprisingInviteTier2.grantRole('0xdccc1989d74912b93bf418567a92dfdbc8fde7ffc7bffb3218a0397a2c4285ae', defyUprisingSalePhaseOne.address);

  console.log('granting MINTER_ROLE role on mask contract')
  await defyUprisingMask.grantRole('0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6', defyUprisingSalePhaseOne.address);

  if (env === 'DEV') {
	console.log('updating mint price on sale contract')
	await defyUprisingSalePhaseOne.updateMintPrice(40000000000000000n);
  
	console.log('updating tier 1 mint active')
	await defyUprisingSalePhaseOne.updateTier1MintActive(true);
  }

  console.log("defyUprisingSalePhaseOne deployed to:", defyUprisingSalePhaseOne.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

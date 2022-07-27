// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("hardhat");

const series0 = require("./temp/series0-2.json")

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const DEFYGenesisInvite = await ethers.getContractFactory("DEFYGenesisInvite");
  const defyGenesisInvite = await DEFYGenesisInvite.attach("0x48697417f102663BeA75a52CcCc7bD5da9e8705f")

  console.log('Attached to invite contract')

  console.log(series0.length)
  let addresses = series0.filter(a => ethers.utils.isAddress(a))
  console.log(addresses.length)

  // addresses = pathAddresses

  // await defyGenesisInvite['safeMint(address,uint8)']("0x5A0e0e08c4c322a206bf13DeDD5952B9740B29FA",1)
  // console.log("minted pg invite to 0x5A0e0e08c4c322a206bf13DeDD5952B9740B29FA")

  const MINT_SERIES = 0;

  const chunkSize = 80;
  for (let i = 7360; i < addresses.length; i += chunkSize) {
      const chunk = addresses.slice(i, i + chunkSize);
      console.log(`${i}: ${chunk[0]} - ${chunk[chunkSize-1]}`)
      await defyGenesisInvite.safeMint_batch(chunk, MINT_SERIES, { gasPrice: 50000000000 })
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

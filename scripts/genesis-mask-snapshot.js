// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("hardhat");

const GENESIS_MINTED_COUNT = 1084;
const GENESIS_RESERVED_COUNT = 33;
const GENESIS_PG_MINTED_COUNT = 436;

async function main() {

  // We get the contract to deploy
  const DEFYGenesisMask = await ethers.getContractFactory("DEFYGenesisMask");
  const defyGenesisMask = await DEFYGenesisMask.attach("0xfD257dDf743DA7395470Df9a0517a2DFbf66D156")
  // const defyGenesisMask = await DEFYGenesisMask.attach("0x76D2Bc6575D60D190654384Aa6Ec98215789eF43")

  const promises = []

  const maskOwners = []

  for (let i = 0; i < GENESIS_MINTED_COUNT; i++) {
    promises.push(defyGenesisMask.ownerOf(i).then(a => {
      maskOwners.push({
        token: i,
        owner: a
      })
    }))
    
    if (i % 400 == 0) {
      await Promise.all(promises)
    }
  }

  await Promise.all(promises)

  console.log(JSON.stringify(maskOwners))
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

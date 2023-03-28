// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("hardhat");

const tayasa_tokens = require('../temp/tayasa-masks.json')

async function main() {

  // We get the contract to deploy
  const DEFYGenesisMask = await ethers.getContractFactory("DEFYGenesisMask");
  const defyGenesisMask = DEFYGenesisMask.attach("0xfD257dDf743DA7395470Df9a0517a2DFbf66D156")
  const defyPgGenesisMask = DEFYGenesisMask.attach("0x76D2Bc6575D60D190654384Aa6Ec98215789eF43")

  const promises = []

  const tokenAmounts = []

  for (let i = 0; i < tayasa_tokens.length; i++) {
		const token = tayasa_tokens[i]
		const maskContract = token.contractAddress == '0xfd257ddf743da7395470df9a0517a2dfbf66d156' ? defyGenesisMask : defyPgGenesisMask

		console.log(token.tokenId)
		console.log(token.contractAddress == '0xfd257ddf743da7395470df9a0517a2dfbf66d156' ? 'defyGenesisMask' : 'defyPgGenesisMask')

    promises.push(maskContract.getTotalBondedTokensForMask(token.tokenId).then(a => {
      tokenAmounts.push({
        token: token.tokenId,
        amount: a.toNumber()
      })
    }))
  }

  await Promise.all(promises)

  console.log(JSON.stringify(tokenAmounts))
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

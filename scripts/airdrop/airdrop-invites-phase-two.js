// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("hardhat");

// const series0 = require("./temp/series0-2.json")

let appAddresses = require('../temp/snapshot-addresses.json')

appAddresses = appAddresses.map(a => a.toLowerCase())

// const series2 = require("./temp/snapshot-genesis-reserved.json")

// const series2Owners = series2.map(s => s.owner.toLowerCase())

const addresses = require("../temp/toMint.json")

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

Array.prototype.count = function() {
  return this.reduce(function(obj, name) {
      obj[name] = obj[name] ? ++obj[name] : 1;
      return obj;
  }, {});
}

const toMint = []

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.

  let totalMissing = 0
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const DEFYGenesisInvite = await ethers.getContractFactory("DEFYGenesisInvitePhaseTwo");
  const defyGenesisInvite = await DEFYGenesisInvite.attach("0x27c91aC770cAe37Db870aa01737Ac50EE31067A7")

  // const mintMissingInvitesForAddress = async (address, count) => {
  //   const actualBalance = await defyGenesisInvite.balanceOf(address)

  //   const transfersFilter = defyGenesisInvite.filters.Transfer(address)
  //   const transfers = await defyGenesisInvite.queryFilter(transfersFilter)

  //   const missingAmount = count - transfers.length - actualBalance;
  
  //   if (missingAmount > 0) {
  //     // console.log(`Address ${address} is missing ${missingAmount} invites, minting...`)
  //     totalMissing += missingAmount

  //     for (let i = 0; i < missingAmount; i++) {
  //       toMint.push(address)
  //     }

  //     // await defyGenesisInvite.safeMint_batch(mintAddresses, 2, { gasPrice: 50000000000 })
  //   }
  // }

  // // console.log('Attached to invite contract')

  // const addressCount = addresses.count()

  // // console.log(JSON.stringify(addressCount))

  // const uniqueAddresses = Object.keys(addressCount)

  // const promises = []

  // for (let i = 0; i < uniqueAddresses.length; i++) {
  //   const address = uniqueAddresses[i]
  //   const count = addressCount[address]
  //   // console.log('asdf')
  //   // console.log(`Address ${address} has ${count} invites`)
  //   promises.push(mintMissingInvitesForAddress(address, count))

  //   if (i % 300 == 0) await Promise.all(promises)
  // }

  // await Promise.all(promises)

  // console.log(JSON.stringify(toMint))

  // const MINT_SERIES = 2;

  // // const chunkSize = 80;

  // for (let i = 0; i < series2.length; i++) {
  //   const address = series2Owners[i]
  //   const linkedToApp = appAddresses.includes(address)

  //   if (linkedToApp) {
  //     for (let j = 0; j < 10; j++) {
  //       addresses.push(address)
  //     }
  //   } else {
  //     addresses.push(address)
  //   };
  // }

  // console.log(JSON.stringify(addresses))

  // console.log(series0.length)
  // let addresses = series0.filter(a => ethers.utils.isAddress(a))
  // console.log(addresses.length)

  // addresses = pathAddresses

  // await defyGenesisInvite['safeMint(address,uint8)']("0x5A0e0e08c4c322a206bf13DeDD5952B9740B29FA",1)
  // console.log("minted pg invite to 0x5A0e0e08c4c322a206bf13DeDD5952B9740B29FA")

  const MINT_SERIES = 2;

  const chunkSize = 80;
  for (let i = 0; i < addresses.length; i += chunkSize) {
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

# DEFY Smart Contracts

This project uses a basic Hardhat setup for building and deploying.

This repository contains the contracts used for the DEFY game.

## Contract deployment addresses (Ethereum)
| **Contract**               | **Ethereum Mainnet**                       | _Updated_                | **Ethereum Testnet**                       | _Updated_                |
|----------------------------|--------------------------------------------|--------------------------|--------------------------------------------|--------------------------|
| DEFY Token                 | 0x205eD31C867bF715E4182137Af95AFE9177Cd8E7 | 2022-03-24T12:15:10.719Z |                                            |                          |

## Contract deployment addresses (Polygon)

| **Contract**               | **Polygon Mainnet**                        | _Updated_                | **Polygon Mumbai**                         | _Updated_                |
|----------------------------|--------------------------------------------|--------------------------|--------------------------------------------|--------------------------|
| Genesis Invite - Phase One | 0x48697417f102663BeA75a52CcCc7bD5da9e8705f | 2022-03-24T12:15:10.719Z | 0xC2D213d11f01215F9714B9B2504840e13A62c013 | 2022-03-24T12:14:17.719Z |
| Genesis Invite - Phase Two | 0x27c91aC770cAe37Db870aa01737Ac50EE31067A7 | 2022-04-27T04:19:48.844Z |                                            |                          |
| Uprising Invite - Tier One | 0xa3b7945a9a964e6a8434c2dfa249181a818a5cd2 | 2022-07-18T12:36:47.277Z | 0xFc6A13353Bf45462e304218EA51ACd72Da6430c4 | 2022-07-18T08:36:06.038Z |
| Uprising Invite - Tier Two | 0x9162c5dcD344B9B3C2527A77a8C2cd7F1334b6e7 | 2022-07-18T12:36:47.277Z | 0xc8Aa0FE090b17CcF594C31FFC314844eE625e900 | 2022-07-22T17:14:00.000Z |
| Genesis Masks              | 0xfD257dDf743DA7395470Df9a0517a2DFbf66D156 | 2022-03-26T00:56:12.494Z | 0x5f4D7c752Aff818c903F1fb2f3b2B5692Ff375D7 | 2022-03-26T00:12:34.494Z |
| Phantom Galaxies Masks     | 0x76D2Bc6575D60D190654384Aa6Ec98215789eF43 | 2022-03-25T13:38:20.960Z | 0xB599F3eAE4D9c5894dAc7934B0e5d6902A6D1502 | 2022-03-26T00:12:34.494Z |
| Uprising Masks             | 0x0973f5e8A888f3172c056099EB053879dE972684 | 2022-07-23T03:11:00.960Z | 0x079C888558a553de2aC6D10d7877fEc5a63297b3 | 2022-07-23T03:06:00.494Z |
| DEFY Decals                | 0xd753b94df74a54c76e54cf4c327094d1dfc35ebc | 2022-07-20T03:31:25.000Z | 0x74b4019736ca3cd0f467378aa041686f9b32e9f2 | 2022-07-19T04:57:56.000Z |
| DEFY Badges                | 0x86Aad261465A1f7432efb8618D6736e910025c69 | 2022-07-25T03:53:00.000Z | 0x7023662dF3D6fDd2E9D948540e22a3a6e174CD00 | 2022-07-25T03:47:00.000Z |
| Uprising Phase One Sale    | 0x626979d5f00Df77Fee1Be2FD1Ec226cEF1F0bBE3 | 2022-07-23T03:46:48.000Z | 0xFFa85909698Fc3Cb2BaebF0C1B2D26bDF72fa546 | 2022-07-23T03:20:00.000Z |



## Genesis Invitation contracts

Invites belong to a particular "series".  Each series has an 8 bit numeric id, with the default being 0.  Each series maintains its own counter, which starts at 0 and increments by 1 for each new token. The token ID is offset by the series id multiplied by a fixed offset.  At the time of writing, this offset is set to 100,000.  This means that token 1 for series 0 will have an id of 1, and token 1 for series 1 will have an id of 100001.

Current series mappings are as below:
* Series 0 - Phase 1 General Genesis invites
* Series 1 - Phase 1 Phantom Galaxies invites
* Series 2 - Phase 2 General Genesis invites

## Contract deployment steps
### Invite Contract
* Give the INVITE_SPENDER_ROLE to the mask contract
* Upload metadata somewhere (ideally IPFS)
* Set the baseURI to the metadata location
* Set the contractURI to the location of the OpenSea metadata file

### Mask Contract
* Don't forget to update the contructor in the deploy script to use the correct ChainlinkVRF addresses
* Update the invite contract address
* Upload metadata somewhere (ideally IPFS)
* Set the baseURI to the metadata location
* Set the contractURI to the location of the OpenSea metadata file
* Set ChainlinVRF Parameters
* Assign BALANCE_WITHDRAWER_ROLE to Gnosis safe

### Configure ChainlinkVRF
* Create a subscription on the ChainlinkVRF coordinator contract
* Fund the subscription by transferring LINK to ChainlinkVRF and calling the function with your subscriptionId
* Add the Mask contract as a consumer to the subscription

## Chainlink Details (Polygon)
### Polygon Mainnet
* LINK Token: `0xb0897686c545045afc77cf20ec7a532e3120e0f1`
* VRF Coordinator: `0xAE975071Be8F8eE67addBC1A82488F1C24858067`
* 200 gwei Key Hash: `0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93`
* 500 gwei Key Hash: `0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd`
* 1000 gwei Key Hash: `0xd729dc84e21ae57ffb6be0053bf2b0668aa2aaf300a2a7b2ddf7dc0bb6e875a8`
* Premium: 0.0005 LINK
* Minimum Confirmations: 3

### Polygon Mumbai Testnet
* LINK Token: `0x326C977E6efc84E512bB9C30f76E30c160eD06FB`
* VRF Coordinator: `0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed`
* 500 gwei Key Hash: `0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f`
* Premium: 0.0005 LINK

## Hardhat Info

To deploy contracts, create a deployment script in `scripts/deployment`, and run it with:

`npx hardhat run ./scripts/deployment/{script}.js --network { polygon | polygon_mumbai }`

Verify it with:
`npx hardhat verify {address} --network { polygon | polygon_mumbai }`

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
npx hardhat verify {address} --network polygon_mumbai
```

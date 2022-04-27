const { expect } = require("chai");
const { ethers } = require("hardhat");

let DEFYGenesisInvite;
let defyGenesisInvite;

let DEFAULT_ADMIN_ROLE, PAUSER_ROLE, MINTER_ROLE, INVITE_SPENDER_ROLE;
let DEFAULT_ADDRESS, SECONDARY_ADDRESS;

describe("DEFYGenesisInvite", function () {

  beforeEach(async function () {
    DEFYGenesisInvite = await ethers.getContractFactory("DEFYGenesisInvite");
    defyGenesisInvite = await DEFYGenesisInvite.deploy();
    await defyGenesisInvite.deployed();

    DEFAULT_ADMIN_ROLE = await defyGenesisInvite['DEFAULT_ADMIN_ROLE()']();
    PAUSER_ROLE = await defyGenesisInvite['PAUSER_ROLE()']();
    MINTER_ROLE = await defyGenesisInvite['MINTER_ROLE()']();
    INVITE_SPENDER_ROLE = await defyGenesisInvite['INVITE_SPENDER_ROLE()']();
    const [owner, secondaryAddress] = await ethers.getSigners();
    DEFAULT_ADDRESS = owner.address;
    SECONDARY_ADDRESS = secondaryAddress.address;
  });


  it("Should fail to mint an NFT when mint is called by an account without the minter role", async function () {
    await defyGenesisInvite['revokeRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS)
    
    await expect(defyGenesisInvite['safeMint(address)'](DEFAULT_ADDRESS)).to.be.revertedWith('AccessControl')
  })

  it("Should mint an NFT for the default series and correctly store the metadata", async function () {
    await defyGenesisInvite['safeMint(address)'](DEFAULT_ADDRESS)

    const owner = await defyGenesisInvite.ownerOf(0);

    expect(owner).to.equal(DEFAULT_ADDRESS);

    const metadata = await defyGenesisInvite.getInviteMetadata(0);

    expect(metadata.originalOwner).to.equal(DEFAULT_ADDRESS);
    expect(metadata.inviteState).to.equal(0);
    expect(metadata.seriesId).to.equal(0);
  })

  it("Should mint multiple NFTs for the default series and correctly increment the ids", async function () {
    await defyGenesisInvite['safeMint(address)'](DEFAULT_ADDRESS)
    await defyGenesisInvite['safeMint(address)'](DEFAULT_ADDRESS)

    expect(await defyGenesisInvite.ownerOf(0)).to.equal(DEFAULT_ADDRESS);
    expect(await defyGenesisInvite.ownerOf(1)).to.equal(DEFAULT_ADDRESS);
    await expect(defyGenesisInvite.ownerOf(2)).to.be.revertedWith('owner query for nonexistent token');
  })

  it("Should mint multiple NFTs for the multiple series and correctly increment the ids separately for each series", async function () {
    await defyGenesisInvite['safeMint(address,uint8)'](DEFAULT_ADDRESS,0)
    await defyGenesisInvite['safeMint(address,uint8)'](DEFAULT_ADDRESS,1)
    await defyGenesisInvite['safeMint(address,uint8)'](DEFAULT_ADDRESS,0)
    await defyGenesisInvite['safeMint(address,uint8)'](DEFAULT_ADDRESS,1)

    expect(await defyGenesisInvite.ownerOf(0)).to.equal(DEFAULT_ADDRESS);
    expect(await defyGenesisInvite.ownerOf(1)).to.equal(DEFAULT_ADDRESS);
    expect(await defyGenesisInvite.ownerOf(100000)).to.equal(DEFAULT_ADDRESS);
    expect(await defyGenesisInvite.ownerOf(100001)).to.equal(DEFAULT_ADDRESS);

    await expect(defyGenesisInvite.ownerOf(2)).to.be.revertedWith('owner query for nonexistent token');
    await expect(defyGenesisInvite.ownerOf(100002)).to.be.revertedWith('owner query for nonexistent token');
  })

  it("Should fail to update the baseURI when update function called by non-admin", async function () {
    await defyGenesisInvite['revokeRole(bytes32,address)'](DEFAULT_ADMIN_ROLE, DEFAULT_ADDRESS)
    
    await expect(defyGenesisInvite.setBaseURI('')).to.be.revertedWith('AccessControl');
  })

  it("Should correctly update the baseURI", async function () {
    await defyGenesisInvite['safeMint(address)'](DEFAULT_ADDRESS)

    let tokenURI = await defyGenesisInvite.tokenURI(0);

    expect(tokenURI).to.equal("0.json")

    await defyGenesisInvite.setBaseURI('https://test.com/')

    tokenURI = await defyGenesisInvite.tokenURI(0);

    expect(tokenURI).to.equal("https://test.com/0.json")
  })

  it("Should generate the correct token URI for tokens in multiple series", async function () {
    await defyGenesisInvite['safeMint(address,uint8)'](DEFAULT_ADDRESS,0)
    await defyGenesisInvite['safeMint(address,uint8)'](DEFAULT_ADDRESS,1)

    const firstTokenURI = await defyGenesisInvite.tokenURI(0);
    const secondTokenURI = await defyGenesisInvite.tokenURI(100000);

    expect(firstTokenURI).to.equal("0.json")
    expect(secondTokenURI).to.equal("100000.json")
  })

  it("Should generate the correct token URI for spent tokens", async function () {
    await defyGenesisInvite['grantRole(bytes32,address)'](INVITE_SPENDER_ROLE, DEFAULT_ADDRESS)
    
    await defyGenesisInvite['safeMint(address,uint8)'](DEFAULT_ADDRESS,0)

    let tokenURI = await defyGenesisInvite.tokenURI(0);

    expect(tokenURI).to.equal("0.json")

    await defyGenesisInvite['spendInvite(uint256,address)'](0, DEFAULT_ADDRESS)

    tokenURI = await defyGenesisInvite.tokenURI(0)

    expect(tokenURI).to.equal("0_spent.json");
  })

  it("Should fail to get tokenURI for non-existant tokens", async function () {
    await expect(defyGenesisInvite.tokenURI(0)).to.be.revertedWith("URI query for nonexistent token");
  })

  it("Should fail to pause the contract when pause is called by an account without the pauser role", async function () {
    await defyGenesisInvite['revokeRole(bytes32,address)'](PAUSER_ROLE, DEFAULT_ADDRESS)
    
    await expect(defyGenesisInvite.pause()).to.be.revertedWith('AccessControl')
  })

  it("Should revert when attempting to transfer while the contract is paused", async function () {
    await defyGenesisInvite['safeMint(address,uint8)'](DEFAULT_ADDRESS, 0)

    await defyGenesisInvite.pause();

    defyGenesisInvite['safeTransferFrom(address,address,uint256)'](DEFAULT_ADDRESS, SECONDARY_ADDRESS, 0)

    await expect(defyGenesisInvite['safeTransferFrom(address,address,uint256)'](DEFAULT_ADDRESS, SECONDARY_ADDRESS, 0)).to.be.revertedWith("paused")
  })

  it("Should revert when attempting to spend an invite when spend is called by an account without the invite spender role", async function () {
    await defyGenesisInvite['safeMint(address,uint8)'](DEFAULT_ADDRESS, 0)

    await expect(defyGenesisInvite['spendInvite(uint256,address)'](0, DEFAULT_ADDRESS)).to.be.revertedWith("AccessControl")
  })

  it("Should correctly spend an invite that hasn't yet been spent", async function () {
    await defyGenesisInvite['grantRole(bytes32,address)'](INVITE_SPENDER_ROLE, DEFAULT_ADDRESS)

    await defyGenesisInvite['safeMint(address,uint8)'](DEFAULT_ADDRESS, 0)

    let metadata = await defyGenesisInvite.getInviteMetadata(0);

    expect(metadata.inviteState).to.equal(0);

    await defyGenesisInvite['spendInvite(uint256,address)'](0, DEFAULT_ADDRESS)

    metadata = await defyGenesisInvite.getInviteMetadata(0);

    expect(metadata.inviteState).to.equal(1);
  })

  it("Should revert when attempting to spend an invite that has already been spent", async function () {
    await defyGenesisInvite['grantRole(bytes32,address)'](INVITE_SPENDER_ROLE, DEFAULT_ADDRESS)

    await defyGenesisInvite['safeMint(address,uint8)'](DEFAULT_ADDRESS, 0)
    await defyGenesisInvite['spendInvite(uint256,address)'](0, DEFAULT_ADDRESS)

    await expect(defyGenesisInvite['spendInvite(uint256,address)'](0, DEFAULT_ADDRESS)).to.be.revertedWith("invite was already spent")
  })

  it("Should revert when attempting to transfer an invite that has already been spent", async function () {
    await defyGenesisInvite['grantRole(bytes32,address)'](INVITE_SPENDER_ROLE, DEFAULT_ADDRESS)

    await defyGenesisInvite['safeMint(address,uint8)'](DEFAULT_ADDRESS, 0)
    await defyGenesisInvite['spendInvite(uint256,address)'](0, DEFAULT_ADDRESS)

    await expect(defyGenesisInvite['safeTransferFrom(address,address,uint256)'](DEFAULT_ADDRESS, SECONDARY_ADDRESS, 0)).to.be.revertedWith("spent invites cannot be transferred")
  })
});

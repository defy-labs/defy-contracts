const { expect } = require("chai");
const { ethers } = require("hardhat");

let DEFYGenesisInvite;
let defyGenesisInvite;

let DEFYGenesisMask;
let defyGenesisMask;

let DEFAULT_ADMIN_ROLE, PAUSER_ROLE, MINTER_ROLE, INVITE_SPENDER_ROLE;
let DEFAULT_ADDRESS, SECONDARY_ADDRESS;

let DEFAULT_PRICE = 100;

describe("DEFYGenesisMask", function () {

  beforeEach(async function () {
    MockVRFCoordinator = await ethers.getContractFactory("MockVRFCoordinator");
    mockVRFCoordinator = await MockVRFCoordinator.deploy();
    await mockVRFCoordinator.deployed();

    DEFYGenesisInvite = await ethers.getContractFactory("DEFYGenesisInvite");
    defyGenesisInvite = await DEFYGenesisInvite.deploy();
    await defyGenesisInvite.deployed();

    DEFYGenesisMask = await ethers.getContractFactory("DEFYGenesisMask");
    defyGenesisMask = await DEFYGenesisMask.deploy(mockVRFCoordinator.address, "0x0000000000000000000000000000000000000000");
    await defyGenesisMask.deployed();

    await defyGenesisMask.updateMintPrice(DEFAULT_PRICE);

    DEFAULT_ADMIN_ROLE = await defyGenesisInvite['DEFAULT_ADMIN_ROLE()']();
    PAUSER_ROLE = await defyGenesisInvite['PAUSER_ROLE()']();
    MINTER_ROLE = await defyGenesisInvite['MINTER_ROLE()']();
    INVITE_SPENDER_ROLE = await defyGenesisInvite['INVITE_SPENDER_ROLE()']();

    const [owner, secondaryAddress] = await ethers.getSigners();
    DEFAULT_ADDRESS = owner.address;
    SECONDARY_ADDRESS = secondaryAddress.address;
  });


  it("Should have no phase enabled when contract is first deployed", async function () {
    expect(await defyGenesisMask.phaseOneActive() == false);
    expect(await defyGenesisMask.phaseTwoActive() == false);
    expect(await defyGenesisMask.publicMintActive() == false);
  })

  it("Should mint a phase one mask when the minter has a valid invite", async function () {
    await defyGenesisInvite['grantRole(bytes32,address)'](INVITE_SPENDER_ROLE, defyGenesisMask.address)

    await defyGenesisMask.updateInviteContractAddress(defyGenesisInvite.address);
    await defyGenesisMask.updatePhaseOneStatus(true);

    await defyGenesisInvite['safeMint(address)'](DEFAULT_ADDRESS)

    await defyGenesisMask.phaseOneInviteMint(0, { value: DEFAULT_PRICE })

    const owner = await defyGenesisMask.ownerOf(1);

    expect(owner).to.equal(DEFAULT_ADDRESS);
  })

  it("Should fail to mint a phase one mask when the minter uses someone elses invite", async function () {
    await defyGenesisInvite['grantRole(bytes32,address)'](INVITE_SPENDER_ROLE, defyGenesisMask.address)

    await defyGenesisMask.updateInviteContractAddress(defyGenesisInvite.address);
    await defyGenesisMask.updatePhaseOneStatus(true);

    await defyGenesisInvite['safeMint(address)'](SECONDARY_ADDRESS)

    await expect(defyGenesisMask.phaseOneInviteMint(0, { value: DEFAULT_PRICE })).to.be.revertedWith('DEFYGenesisInvite')
  })

  it("Should fail to mint a phase one mask when phase one is not active", async function () {
    await defyGenesisInvite['grantRole(bytes32,address)'](INVITE_SPENDER_ROLE, defyGenesisMask.address)

    await defyGenesisMask.updateInviteContractAddress(defyGenesisInvite.address);

    await defyGenesisInvite['safeMint(address)'](DEFAULT_ADDRESS)

    await expect(defyGenesisMask.phaseOneInviteMint(0, { value: DEFAULT_PRICE })).to.be.revertedWith('DGM')
  })

  it("Should fail to mint a phase one mask when not enough matic is sent", async function () {
    await defyGenesisInvite['grantRole(bytes32,address)'](INVITE_SPENDER_ROLE, defyGenesisMask.address)

    await defyGenesisMask.updateInviteContractAddress(defyGenesisInvite.address);

    await defyGenesisInvite['safeMint(address)'](DEFAULT_ADDRESS)

    await expect(defyGenesisMask.phaseOneInviteMint(0, { value: DEFAULT_PRICE - 1 })).to.be.revertedWith('DGM')
  })

  it("Should fail to mint a phase one mask when too much matic is sent", async function () {
    await defyGenesisInvite['grantRole(bytes32,address)'](INVITE_SPENDER_ROLE, defyGenesisMask.address)

    await defyGenesisMask.updateInviteContractAddress(defyGenesisInvite.address);

    await defyGenesisInvite['safeMint(address)'](DEFAULT_ADDRESS)

    await expect(defyGenesisMask.phaseOneInviteMint(0, { value: DEFAULT_PRICE + 1 })).to.be.revertedWith('DGM')
  })

  it("Should fail to mint a phase one mask when no matic is sent", async function () {
    await defyGenesisInvite['grantRole(bytes32,address)'](INVITE_SPENDER_ROLE, defyGenesisMask.address)

    await defyGenesisMask.updateInviteContractAddress(defyGenesisInvite.address);

    await defyGenesisInvite['safeMint(address)'](DEFAULT_ADDRESS)

    await expect(defyGenesisMask.phaseOneInviteMint(0)).to.be.revertedWith('DGM')
  })

  it("Should mint a phase one mask when the minter has a valid invite, and award tokens randomly", async function () {
    await defyGenesisInvite['grantRole(bytes32,address)'](INVITE_SPENDER_ROLE, defyGenesisMask.address)

    await defyGenesisMask.updateInviteContractAddress(defyGenesisInvite.address);
    await defyGenesisMask.updatePhaseOneStatus(true);

    await defyGenesisInvite['safeMint(address)'](DEFAULT_ADDRESS)

    await defyGenesisMask.phaseOneInviteMint(0, { value: DEFAULT_PRICE })
  })

  // it("Should mint 1000 masks", async function () {
  //   await defyGenesisInvite['grantRole(bytes32,address)'](INVITE_SPENDER_ROLE, defyGenesisMask.address)

  //   await defyGenesisMask.updateInviteContractAddress(defyGenesisInvite.address);
  //   await defyGenesisMask.updatePhaseOneStatus(true);

  //   for (let i = 0; i < 1000; i++) {
  //     if (i % 50 == 0) {
  //       console.log(i)
  //     }
  //     await defyGenesisInvite['safeMint(address)'](DEFAULT_ADDRESS)
  //     await defyGenesisMask.phaseOneInviteMint(i, { value: DEFAULT_PRICE })
  //   }

  //   console.log(`PRIZE: ${await defyGenesisMask._remainingMaskTypeAllocation(0)}`)
  //   console.log(`ELITE: ${await defyGenesisMask._remainingMaskTypeAllocation(1)}`)
  //   console.log(`MID: ${await defyGenesisMask._remainingMaskTypeAllocation(2)}`)
  //   console.log(`LOW: ${await defyGenesisMask._remainingMaskTypeAllocation(3)}`)

  //   console.log(await defyGenesisMask.getTotalBondedTokens())
  // })

});

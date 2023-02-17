const { expect } = require("chai");
const { ethers } = require("hardhat");
const helpers = require("@nomicfoundation/hardhat-network-helpers");

let DEFYMasks;
let defyMasks;

let DEFAULT_ADMIN_ROLE, MINTER_ROLE, BURNER_ROLE, PAUSER_ROLE;

let DEFAULT_OWNER, addr1;

describe("DEFYMasks", function () {

    beforeEach(async function () {
        DEFYMasks = await ethers.getContractFactory("DEFYMasks");
        defyMasks = await DEFYMasks.deploy();
        await defyMasks.deployed();

        DEFAULT_ADMIN_ROLE = await defyMasks['DEFAULT_ADMIN_ROLE()']();
        PAUSER_ROLE = await defyMasks['PAUSER_ROLE()']();
        MINTER_ROLE = await defyMasks['MINTER_ROLE()']();
        BURNER_ROLE = await defyMasks['BURNER_ROLE()']();

        const [owner, secondaryAddress] = await ethers.getSigners();

        DEFAULT_ADDRESS = owner.address;
        SECONDARY_ADDRESS = secondaryAddress.address;

        DEFAULT_OWNER = owner;
        addr1 = secondaryAddress;

    });

    describe('DEFYMasks', () => {
        it("Should fail to mint for a non-minter", async function () {
            await expect(defyMasks.safeMint(DEFAULT_ADDRESS)).to.be.revertedWith(
                'AccessControl: account ');
        });

        it("Should fail to burn for a non-burner", async function () {
            await expect(defyMasks.burnMask(DEFAULT_ADDRESS)).to.be.revertedWith(
                'AccessControl: account ');
        });

        it("Should allow minter to perform mints", async function () {
            await defyMasks['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyMasks.safeMint(DEFAULT_ADDRESS);
            expect(await defyMasks.balanceOf(DEFAULT_ADDRESS)).to.equal(1);
            expect(await defyMasks.ownerOf(0)).to.equal(DEFAULT_ADDRESS);

        });

        it("Should allow burner to perform burns", async function () {
            await defyMasks['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyMasks['grantRole(bytes32,address)'](BURNER_ROLE, DEFAULT_ADDRESS);
            await defyMasks.safeBatchMint([DEFAULT_ADDRESS, DEFAULT_ADDRESS]);
            expect(await defyMasks.balanceOf(DEFAULT_ADDRESS)).to.equal(2);
            await defyMasks.burnMask(0);
            expect(await defyMasks.balanceOf(DEFAULT_ADDRESS)).to.equal(1);
            await expect(defyMasks.ownerOf(0)).to.revertedWith(
                'ERC721: owner query for nonexistent token');
        });

        it("Should allow minter to perform batch mints", async function () {
            await defyMasks['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyMasks.safeBatchMint([DEFAULT_ADDRESS, DEFAULT_ADDRESS, SECONDARY_ADDRESS]);
            expect(await defyMasks.balanceOf(DEFAULT_ADDRESS)).to.equal(2);
            expect(await defyMasks.balanceOf(SECONDARY_ADDRESS)).to.equal(1);
        });

        it("Should prevent burning when owner has 1 mask", async function () {
            await defyMasks['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyMasks['grantRole(bytes32,address)'](BURNER_ROLE, DEFAULT_ADDRESS);
            await defyMasks.safeMint(DEFAULT_ADDRESS);
            await expect(defyMasks.burnMask(0)).to.be.revertedWith(
                "DEFYMasks: Token trading is not enabled"
            );
        });

        it("Should prevent transfers when owner has 1 mask", async function () {
            await defyMasks['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyMasks['grantRole(bytes32,address)'](BURNER_ROLE, DEFAULT_ADDRESS);
            await defyMasks.safeMint(DEFAULT_ADDRESS);
            await expect(defyMasks.transferFrom(DEFAULT_ADDRESS, SECONDARY_ADDRESS, 0)).to.be.revertedWith(
                "DEFYMasks: Token trading is not enabled"
            );
        });

        it("Should allow transfers when owner has 2 masks", async function () {
            await defyMasks['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyMasks['grantRole(bytes32,address)'](BURNER_ROLE, DEFAULT_ADDRESS);
            await defyMasks.safeMint(DEFAULT_ADDRESS);
            await defyMasks.safeMint(DEFAULT_ADDRESS);
            await defyMasks.transferFrom(DEFAULT_ADDRESS, SECONDARY_ADDRESS, 0);
            expect(await defyMasks.balanceOf(SECONDARY_ADDRESS)).to.equal(1);
            expect(await defyMasks.ownerOf(0)).to.be.equal(SECONDARY_ADDRESS);
        });

        it("Should allow burns when owner has 2 masks", async function () {
            await defyMasks['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyMasks['grantRole(bytes32,address)'](BURNER_ROLE, DEFAULT_ADDRESS);
            await defyMasks.safeMint(DEFAULT_ADDRESS);
            await defyMasks.safeMint(DEFAULT_ADDRESS);
            await defyMasks.burnMask(1);
            expect(await defyMasks.balanceOf(DEFAULT_ADDRESS)).to.equal(1);
            await expect(defyMasks.ownerOf(1)).to.revertedWith(
                'ERC721: owner query for nonexistent token');
        });

        it("Should allow transfers with 1 mask when owner transfer is admin enabled", async function () {
            await defyMasks['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyMasks['grantRole(bytes32,address)'](BURNER_ROLE, DEFAULT_ADDRESS);
            await defyMasks.safeMint(DEFAULT_ADDRESS);
            await defyMasks.setTokenTradingEnabledForToken(DEFAULT_ADDRESS, true);
            await defyMasks.transferFrom(DEFAULT_ADDRESS, SECONDARY_ADDRESS, 0);
            expect(await defyMasks.balanceOf(SECONDARY_ADDRESS)).to.equal(1);
            expect(await defyMasks.ownerOf(0)).to.be.equal(SECONDARY_ADDRESS);
        });

        it("Should fail transfers with 1 mask after an owner has transferred already", async function () {
            await defyMasks['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyMasks['grantRole(bytes32,address)'](BURNER_ROLE, DEFAULT_ADDRESS);
            await defyMasks.safeMint(DEFAULT_ADDRESS);
            await defyMasks.setTokenTradingEnabledForToken(DEFAULT_ADDRESS, true);
            await defyMasks.transferFrom(DEFAULT_ADDRESS, SECONDARY_ADDRESS, 0);
            expect(await defyMasks.balanceOf(SECONDARY_ADDRESS)).to.equal(1);
            expect(await defyMasks.ownerOf(0)).to.be.equal(SECONDARY_ADDRESS);
            await defyMasks.safeMint(DEFAULT_ADDRESS);
            expect(await defyMasks.ownerOf(1)).to.be.equal(DEFAULT_ADDRESS);
            await expect(defyMasks.transferFrom(DEFAULT_ADDRESS, SECONDARY_ADDRESS, 1)).to.revertedWith(
                "DEFYMasks: Token trading is not enabled");
        });

    });
});
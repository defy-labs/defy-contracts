const { expect } = require("chai");
const { ethers } = require("hardhat");
const helpers = require("@nomicfoundation/hardhat-network-helpers");

let DEFYMaskCustomisation;
let defyMaskCustomisation;

let DEFAULT_ADMIN_ROLE, MINTER_ROLE, BURNER_ROLE, PAUSER_ROLE;

let DEFAULT_OWNER, addr1;

describe("DEFYMaskCustomisation", function () {

    beforeEach(async function () {
        DEFYMaskCustomisation = await ethers.getContractFactory("DEFYMaskCustomisation");
        defyMaskCustomisation = await DEFYMaskCustomisation.deploy();
        await defyMaskCustomisation.deployed();

        DEFAULT_ADMIN_ROLE = await defyMaskCustomisation['DEFAULT_ADMIN_ROLE()']();
        PAUSER_ROLE = await defyMaskCustomisation['PAUSER_ROLE()']();
        MINTER_ROLE = await defyMaskCustomisation['MINTER_ROLE()']();
        BURNER_ROLE = await defyMaskCustomisation['BURNER_ROLE()']();

        const [owner, secondaryAddress] = await ethers.getSigners();

        DEFAULT_ADDRESS = owner.address;
        SECONDARY_ADDRESS = secondaryAddress.address;

        DEFAULT_OWNER = owner;
        addr1 = secondaryAddress;

    });

    describe('DEFYMaskCustomisation', () => {
        it("Should fail to mint for a non-minter", async function () {
            await expect(defyMaskCustomisation.mint(DEFAULT_ADDRESS, 1, 1, 0x00)).to.be.revertedWith(
                'AccessControl: account ');
        });

        it("Should fail to burn for a non-burner", async function () {
            await expect(defyMaskCustomisation.burnToken(DEFAULT_ADDRESS, 1, 1)).to.be.revertedWith(
                'AccessControl: account ');
        });

        it("Should allow minter to perform mints", async function () {
            await defyMaskCustomisation['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyMaskCustomisation.mint(DEFAULT_ADDRESS, 1, 1, 0x00);
            expect(await defyMaskCustomisation.balanceOf(DEFAULT_ADDRESS, 1)).to.equal(1);
        });

        it("Should allow burner to perform burns", async function () {
            await defyMaskCustomisation['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyMaskCustomisation['grantRole(bytes32,address)'](BURNER_ROLE, DEFAULT_ADDRESS);
            await defyMaskCustomisation.mint(DEFAULT_ADDRESS, 1, 2, 0x00);
            expect(await defyMaskCustomisation.balanceOf(DEFAULT_ADDRESS, 1)).to.equal(2);
            await defyMaskCustomisation.burnToken(DEFAULT_ADDRESS, 1, 1);
            expect(await defyMaskCustomisation.balanceOf(DEFAULT_ADDRESS, 1)).to.equal(1);
        });

        it("Should allow minter to perform batch mints", async function () {
            await defyMaskCustomisation['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyMaskCustomisation.mintBatch(DEFAULT_ADDRESS, [1, 2], [2, 3], 0x00);
            expect(await defyMaskCustomisation.balanceOf(DEFAULT_ADDRESS, 1)).to.equal(2);
            expect(await defyMaskCustomisation.balanceOf(DEFAULT_ADDRESS, 2)).to.equal(3);
        });

        it("Should allow minter to perform batch mint multi user", async function () {
            await defyMaskCustomisation['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyMaskCustomisation.mintBatchMultiUser([DEFAULT_ADDRESS, SECONDARY_ADDRESS], [1, 2], [2, 3]);
            expect(await defyMaskCustomisation.balanceOf(DEFAULT_ADDRESS, 1)).to.equal(2);
            expect(await defyMaskCustomisation.balanceOf(SECONDARY_ADDRESS, 2)).to.equal(3);
        });

        it("Should allow burner to perform batch burn", async function () {
            await defyMaskCustomisation['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyMaskCustomisation['grantRole(bytes32,address)'](BURNER_ROLE, DEFAULT_ADDRESS);
            await defyMaskCustomisation.mintBatchMultiUser([DEFAULT_ADDRESS, SECONDARY_ADDRESS], [1, 2], [2, 3]);
            await defyMaskCustomisation.burnBatchTokens([DEFAULT_ADDRESS, SECONDARY_ADDRESS], [1, 2], [1, 2]);
            expect(await defyMaskCustomisation.balanceOf(DEFAULT_ADDRESS, 1)).to.equal(1);
            expect(await defyMaskCustomisation.balanceOf(SECONDARY_ADDRESS, 2)).to.equal(1);
        });

        it("Should prevent transfers on soulbound tokens", async function () {
            await defyMaskCustomisation['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyMaskCustomisation.mint(DEFAULT_ADDRESS, 1, 10, 0x00);
            await defyMaskCustomisation.safeTransferFrom(DEFAULT_ADDRESS, SECONDARY_ADDRESS, 1, 4, 0x00);
            expect(await defyMaskCustomisation.balanceOf(DEFAULT_ADDRESS, 1)).to.equal(6);
            expect(await defyMaskCustomisation.balanceOf(SECONDARY_ADDRESS, 1)).to.equal(4);
            await defyMaskCustomisation.setTokenTradingDisabledForToken(1, true);
            await expect(defyMaskCustomisation.safeTransferFrom(DEFAULT_ADDRESS, SECONDARY_ADDRESS, 1, 1, 0x00))
                .to.be.revertedWith(
                    "DEFYMaskCustomisation: Token trading has not been enabled this token"
                );
            await defyMaskCustomisation.setTokenTradingDisabledForToken(1, false);
            await defyMaskCustomisation.safeTransferFrom(DEFAULT_ADDRESS, SECONDARY_ADDRESS, 1, 1, 0x00);
            expect(await defyMaskCustomisation.balanceOf(DEFAULT_ADDRESS, 1)).to.equal(5);
            expect(await defyMaskCustomisation.balanceOf(SECONDARY_ADDRESS, 1)).to.equal(5);
        });

    });

});
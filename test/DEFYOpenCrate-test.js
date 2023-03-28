const { expect } = require("chai");
const { ethers } = require("hardhat");
const helpers = require("@nomicfoundation/hardhat-network-helpers");

let DEFYOpenCrate;
let defyOpenCrate;

let DEFYLoot;
let defyLoot;

let DEFAULT_ADMIN_ROLE, MINTER_ROLE, LOOT_BURNER_ROLE, PAUSER_ROLE, OPENER_ROLE;

describe("DEFYOpenCrate", function () {

    beforeEach(async function () {
        DEFYLoot = await ethers.getContractFactory("DEFYLoot");
        defyLoot = await DEFYLoot.deploy();
        await defyLoot.deployed();

        DEFYOpenCrate = await ethers.getContractFactory("DEFYOpenCrate");
        defyOpenCrate = await DEFYOpenCrate.deploy();
        await defyOpenCrate.deployed();

        DEFAULT_ADMIN_ROLE = await defyLoot['DEFAULT_ADMIN_ROLE()']();
        PAUSER_ROLE = await defyLoot['PAUSER_ROLE()']();
        MINTER_ROLE = await defyLoot['MINTER_ROLE()']();
        LOOT_BURNER_ROLE = await defyLoot['LOOT_BURNER_ROLE()']();
        OPENER_ROLE = await defyOpenCrate['OPENER_ROLE()']();

        const [owner, secondaryAddress] = await ethers.getSigners();
        DEFAULT_ADDRESS = owner.address;
        SECONDARY_ADDRESS = secondaryAddress.address;

        DEFAULT_OWNER = owner;
        addr1 = secondaryAddress;

    });

    describe('DEFYOpenCrate', () => {
        it("Should fail to open crate if the loot contract is not approved", async function () {
            await defyOpenCrate['grantRole(bytes32,address)'](OPENER_ROLE, DEFAULT_ADDRESS);
            await expect(defyOpenCrate.openCrate(
                defyLoot.address,
                DEFAULT_ADDRESS,
                [1],
                [1],
                10
            )).to.be.revertedWith("DEFYOpenCrate: Loot contract not valid");
        });

        it("Should fail if caller is not an opener", async function () {
            await expect(defyOpenCrate.openCrate(
                defyLoot.address,
                DEFAULT_ADDRESS,
                [1],
                [1],
                10
            )).to.be.revertedWith('AccessControl: account ');
        });

        it("Should fail a open crate if inputs are not valid", async function () {
            await defyOpenCrate['grantRole(bytes32,address)'](OPENER_ROLE, DEFAULT_ADDRESS);
            await defyOpenCrate.approveLootContract(defyLoot.address);
            await expect(defyOpenCrate.openCrate(
                defyLoot.address,
                DEFAULT_ADDRESS,
                [],
                [1],
                10
            )).to.be.revertedWith("DEFYOpenCrate: Invalid input loots");
        });

        it("Should fail if operative does not own input loots", async function () {
            await defyOpenCrate['grantRole(bytes32,address)'](OPENER_ROLE, DEFAULT_ADDRESS);
            await defyOpenCrate.approveLootContract(defyLoot.address);
            await expect(defyOpenCrate.openCrate(
                defyLoot.address,
                DEFAULT_ADDRESS,
                [1],
                [1],
                10
            )).to.be.revertedWith("DEFYOpenCrate: Operative does not own Crate item");
        });

        it("Should successfully burn input tokens when opening crate", async function () {
            await defyOpenCrate['grantRole(bytes32,address)'](OPENER_ROLE, DEFAULT_ADDRESS);
            await defyOpenCrate.approveLootContract(defyLoot.address);

            await defyLoot['grantRole(bytes32,address)'](LOOT_BURNER_ROLE, defyOpenCrate.address);
            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, defyOpenCrate.address);
            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);

            await defyLoot.mintBatch(SECONDARY_ADDRESS, [10], [10], 0x00);

            await defyOpenCrate.openCrate(
                defyLoot.address,
                SECONDARY_ADDRESS,
                [2],
                [2],
                10
            );

            expect(await defyLoot.balanceOf(SECONDARY_ADDRESS, 2)).to.equal(2);
            expect(await defyLoot.balanceOf(SECONDARY_ADDRESS, 10)).to.equal(9);
        });
    });
});


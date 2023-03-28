const { expect } = require("chai");
const { ethers } = require("hardhat");
const helpers = require("@nomicfoundation/hardhat-network-helpers");

let DEFYForge;
let defyForge;

let DEFYLoot;
let defyLoot;

let DEFAULT_ADMIN_ROLE, MINTER_ROLE, LOOT_BURNER_ROLE, PAUSER_ROLE, URI_SETTER_ROLE, CUSTOMISE_MASK_ROLE;

describe("DEFYApplyMaskCustomItems", function () {

    beforeEach(async function () {
        DEFYLoot = await ethers.getContractFactory("DEFYLoot");
        defyLoot = await DEFYLoot.deploy();
        await defyLoot.deployed();

        DEFYApplyMaskCustomItems = await ethers.getContractFactory("DEFYApplyMaskCustomItems");
        defyApplyMaskCustomItems = await DEFYApplyMaskCustomItems.deploy();
        await defyApplyMaskCustomItems.deployed();

        DEFAULT_ADMIN_ROLE = await defyLoot['DEFAULT_ADMIN_ROLE()']();
        PAUSER_ROLE = await defyLoot['PAUSER_ROLE()']();
        MINTER_ROLE = await defyLoot['MINTER_ROLE()']();
        LOOT_BURNER_ROLE = await defyLoot['LOOT_BURNER_ROLE()']();
        URI_SETTER_ROLE = await defyLoot['URI_SETTER_ROLE()']();
        CUSTOMISE_MASK_ROLE = await defyApplyMaskCustomItems['CUSTOMISE_MASK_ROLE()']();

        const [owner, secondaryAddress] = await ethers.getSigners();
        DEFAULT_ADDRESS = owner.address;
        SECONDARY_ADDRESS = secondaryAddress.address;

        DEFAULT_OWNER = owner;
        addr1 = secondaryAddress;

    });

    describe('DEFYApplyMaskCustomItems', () => {
        it("Should fail to apply custom mask item if the loot contract is not approved", async function () {
            await defyApplyMaskCustomItems['grantRole(bytes32,address)'](CUSTOMISE_MASK_ROLE, DEFAULT_ADDRESS);
            await expect(defyApplyMaskCustomItems.applyMaskCustomisation(
                defyLoot.address,
                DEFAULT_ADDRESS,
                [1]
            )).to.be.revertedWith("DEFYApplyMaskCustomItems: Loot contract not valid");
        });

        it("Should fail if caller is not a mask customiser", async function () {
            await expect(defyApplyMaskCustomItems.applyMaskCustomisation(
                defyLoot.address,
                DEFAULT_ADDRESS,
                [1]
            )).to.be.revertedWith('AccessControl: account ');
        });

        it("Should fail a customise mask job if inputs are not valid", async function () {
            await defyApplyMaskCustomItems['grantRole(bytes32,address)'](CUSTOMISE_MASK_ROLE, DEFAULT_ADDRESS);
            await defyApplyMaskCustomItems.approveLootContract(defyLoot.address);
            await expect(defyApplyMaskCustomItems.applyMaskCustomisation(
                defyLoot.address,
                DEFAULT_ADDRESS,
                []
            )).to.be.revertedWith("DEFYApplyMaskCustomItems: Invalid input loots");
        });

        it("Should fail if operative does not own input loots", async function () {
            await defyApplyMaskCustomItems['grantRole(bytes32,address)'](CUSTOMISE_MASK_ROLE, DEFAULT_ADDRESS);
            await defyApplyMaskCustomItems.approveLootContract(defyLoot.address);
            await expect(defyApplyMaskCustomItems.applyMaskCustomisation(
                defyLoot.address,
                DEFAULT_ADDRESS,
                [1]
            )).to.be.revertedWith("DEFYApplyMaskCustomItems: Operative does not have suffient loots");
        });

        it("Should successfully burn input tokens when applying custom mask tokens", async function () {
            await defyApplyMaskCustomItems['grantRole(bytes32,address)'](CUSTOMISE_MASK_ROLE, DEFAULT_ADDRESS);
            await defyApplyMaskCustomItems.approveLootContract(defyLoot.address);

            await defyLoot['grantRole(bytes32,address)'](LOOT_BURNER_ROLE, defyApplyMaskCustomItems.address);
            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyLoot['grantRole(bytes32,address)'](LOOT_BURNER_ROLE, defyApplyMaskCustomItems.address);

            await defyLoot.mintBatch(SECONDARY_ADDRESS, [1, 2], [2, 3], 0x00);

            await defyApplyMaskCustomItems.applyMaskCustomisation(
                defyLoot.address,
                SECONDARY_ADDRESS,
                [1, 2]
            );

            expect(await defyLoot.balanceOf(SECONDARY_ADDRESS, 1)).to.equal(1);
            expect(await defyLoot.balanceOf(SECONDARY_ADDRESS, 2)).to.equal(2);
        });


    });

});


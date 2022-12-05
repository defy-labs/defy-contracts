const { expect } = require("chai");
const { ethers } = require("hardhat");
const helpers = require("@nomicfoundation/hardhat-network-helpers");

let DEFYForge;
let defyForge;

let DEFYLoot;
let defyLoot;

let DEFAULT_ADMIN_ROLE, MINTER_ROLE, LOOT_BURNER_ROLE, PAUSER_ROLE, URI_SETTER_ROLE, FORGER_ROLE;

describe("DEFYForge", function () {

    beforeEach(async function () {
        DEFYLoot = await ethers.getContractFactory("DEFYLoot");
        defyLoot = await DEFYLoot.deploy();
        await defyLoot.deployed();

        DEFYForge = await ethers.getContractFactory("DEFYForge");
        defyForge = await DEFYForge.deploy();
        await defyForge.deployed();

        DEFAULT_ADMIN_ROLE = await defyLoot['DEFAULT_ADMIN_ROLE()']();
        PAUSER_ROLE = await defyLoot['PAUSER_ROLE()']();
        MINTER_ROLE = await defyLoot['MINTER_ROLE()']();
        LOOT_BURNER_ROLE = await defyLoot['LOOT_BURNER_ROLE()']();
        URI_SETTER_ROLE = await defyLoot['URI_SETTER_ROLE()']();
        FORGER_ROLE = await defyForge['FORGER_ROLE()']();

        const [owner, secondaryAddress] = await ethers.getSigners();
        DEFAULT_ADDRESS = owner.address;
        SECONDARY_ADDRESS = secondaryAddress.address;

    });

    describe('DEFYLoot', () => {
        it("Should fail to mint for a non-minter", async function () {
            await expect(defyLoot.mint(DEFAULT_ADDRESS, 1, 1, 0x00)).to.be.revertedWith(
                'AccessControl: account ');
        });

        it("Should fail to burn for a non-burner", async function () {
            await expect(defyLoot.burnToken(DEFAULT_ADDRESS, 1, 1)).to.be.revertedWith(
                'AccessControl: account ');
        });

        it("Should allow minter to perform mints", async function () {
            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyLoot.mint(DEFAULT_ADDRESS, 1, 1, 0x00);
            expect(await defyLoot.balanceOf(DEFAULT_ADDRESS, 1)).to.equal(1);
        });

        it("Should allow loot burner to perform burns", async function () {
            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyLoot['grantRole(bytes32,address)'](LOOT_BURNER_ROLE, DEFAULT_ADDRESS);
            await defyLoot.mint(DEFAULT_ADDRESS, 1, 2, 0x00);
            expect(await defyLoot.balanceOf(DEFAULT_ADDRESS, 1)).to.equal(2);
            await defyLoot.burnToken(DEFAULT_ADDRESS, 1, 1);
            expect(await defyLoot.balanceOf(DEFAULT_ADDRESS, 1)).to.equal(1);
        });

        it("Should allow minter to perform batch mints", async function () {
            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyLoot.mintBatch(DEFAULT_ADDRESS, [1, 2], [2, 3], 0x00);
            expect(await defyLoot.balanceOf(DEFAULT_ADDRESS, 1)).to.equal(2);
            expect(await defyLoot.balanceOf(DEFAULT_ADDRESS, 2)).to.equal(3);
        });

        it("Should allow minter to perform batch mint multi user", async function () {
            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyLoot.mintBatchMultiUser([DEFAULT_ADDRESS, SECONDARY_ADDRESS], [1, 2], [2, 3]);
            expect(await defyLoot.balanceOf(DEFAULT_ADDRESS, 1)).to.equal(2);
            expect(await defyLoot.balanceOf(SECONDARY_ADDRESS, 2)).to.equal(3);
        });
    });

    describe('DEFYForge', () => {
        it("Should fail a forge job if the loot contract is not approved", async function () {
            await defyForge['grantRole(bytes32,address)'](FORGER_ROLE, DEFAULT_ADDRESS);
            await expect(defyForge.createForgeJob(
                defyLoot.address,
                DEFAULT_ADDRESS,
                [1],
                [1],
                1,
                [2],
                3
            )).to.be.revertedWith('DEFYForge: Loot contract not valid');
        });

        it("Should fail if caller is not a forger", async function () {
            await expect(defyForge.createForgeJob(
                defyLoot.address,
                DEFAULT_ADDRESS,
                [1],
                [1],
                1,
                [2],
                3
            )).to.be.revertedWith('AccessControl: account ');
        });

        it("Should fail a forge job if inputs are not valid", async function () {
            await defyForge['grantRole(bytes32,address)'](FORGER_ROLE, DEFAULT_ADDRESS);
            await defyForge.approveLootContract(defyLoot.address);
            await expect(defyForge.createForgeJob(
                defyLoot.address,
                DEFAULT_ADDRESS,
                [1, 2],
                [1],
                1,
                [2],
                3
            )).to.be.revertedWith('DEFYForge: All arrays must be the same length');
        });

        it("Should fail if null inputs are passed", async function () {
            await defyForge['grantRole(bytes32,address)'](FORGER_ROLE, DEFAULT_ADDRESS);
            await defyForge.approveLootContract(defyLoot.address);
            await expect(defyForge.createForgeJob(
                defyLoot.address,
                DEFAULT_ADDRESS,
                [],
                [],
                1,
                [2],
                3
            )).to.be.revertedWith('DEFYForge: Invalid input loots');
        });

        it("Should fail if operative does not own input loots", async function () {
            await defyForge['grantRole(bytes32,address)'](FORGER_ROLE, DEFAULT_ADDRESS);
            await defyForge.approveLootContract(defyLoot.address);
            await expect(defyForge.createForgeJob(
                defyLoot.address,
                DEFAULT_ADDRESS,
                [1],
                [1],
                1,
                [2],
                3
            )).to.be.revertedWith('DEFYForge: Operative does not have suffient loots');
        });

        it("Should successfully create a forge job", async function () {
            await defyForge['grantRole(bytes32,address)'](FORGER_ROLE, DEFAULT_ADDRESS);
            await defyForge.approveLootContract(defyLoot.address);

            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, defyForge.address);
            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyLoot['grantRole(bytes32,address)'](LOOT_BURNER_ROLE, defyForge.address);

            await defyLoot.mintBatch(SECONDARY_ADDRESS, [1, 2], [2, 3], 0x00);

            await defyForge.createForgeJob(
                defyLoot.address,
                SECONDARY_ADDRESS,
                [1],
                [1],
                10,
                [2],
                3
            );

            expect(await defyForge.getForgeJobsCountByOperative(SECONDARY_ADDRESS)).to.equal(1);
        });

        it("Should fail a forge jobs when called", async function () {
            await defyForge['grantRole(bytes32,address)'](FORGER_ROLE, DEFAULT_ADDRESS);
            await defyForge.approveLootContract(defyLoot.address);

            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, defyForge.address);
            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyLoot['grantRole(bytes32,address)'](LOOT_BURNER_ROLE, defyForge.address);

            await defyLoot.mintBatch(SECONDARY_ADDRESS, [1, 2], [2, 3], 0x00);

            await defyForge.createForgeJob(
                defyLoot.address,
                SECONDARY_ADDRESS,
                [1],
                [1],
                10,
                [2],
                3
            );

            await defyForge.failForgeJob(0);

            await expect(defyForge.completeForgeJob(0)).to.be.revertedWith('DEFYForge: ForgeJob is not processing');
        });

        it("Should cancel a forge job when called", async function () {
            await defyForge['grantRole(bytes32,address)'](FORGER_ROLE, DEFAULT_ADDRESS);
            await defyForge.approveLootContract(defyLoot.address);

            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, defyForge.address);
            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyLoot['grantRole(bytes32,address)'](LOOT_BURNER_ROLE, defyForge.address);

            await defyLoot.mintBatch(SECONDARY_ADDRESS, [1, 2], [2, 3], 0x00);

            await defyForge.createForgeJob(
                defyLoot.address,
                SECONDARY_ADDRESS,
                [1],
                [1],
                10,
                [2],
                3
            );

            await defyForge.cancelForgeJob(0);

            await expect(defyForge.completeForgeJob(0)).to.be.revertedWith('DEFYForge: ForgeJob is not processing');
        });

        it("Should fail when a wrong forgeJobId is passed to be completed", async function () {
            await defyForge['grantRole(bytes32,address)'](FORGER_ROLE, DEFAULT_ADDRESS);
            await defyForge.approveLootContract(defyLoot.address);

            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, defyForge.address);
            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyLoot['grantRole(bytes32,address)'](LOOT_BURNER_ROLE, defyForge.address);

            await defyLoot.mintBatch(SECONDARY_ADDRESS, [1, 2], [2, 3], 0x00);

            await defyForge.createForgeJob(
                defyLoot.address,
                SECONDARY_ADDRESS,
                [1],
                [1],
                10,
                [2],
                3
            );

            await expect(defyForge.completeForgeJob(2)).to.be.revertedWith('DEFYForge: ForgeJobId out of bounds');
        });

        it("Should fail when insufficient duration has passed", async function () {
            it("Should fail when a wrong forgeJobId is passed to be completed", async function () {
                await defyForge['grantRole(bytes32,address)'](FORGER_ROLE, DEFAULT_ADDRESS);
                await defyForge.approveLootContract(defyLoot.address);

                await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, defyForge.address);
                await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
                await defyLoot['grantRole(bytes32,address)'](LOOT_BURNER_ROLE, defyForge.address);

                await defyLoot.mintBatch(SECONDARY_ADDRESS, [1, 2], [2, 3], 0x00);

                await defyForge.createForgeJob(
                    defyLoot.address,
                    SECONDARY_ADDRESS,
                    [1],
                    [1],
                    100,
                    [2],
                    3
                );

                await expect(defyForge.completeForgeJob(0)).to.be.revertedWith('DEFYForge: ForgeJob is not ready to complete');
            });
        });

        it("Should mint tokens back to owner for a cancelled job", async function () {
            await defyForge['grantRole(bytes32,address)'](FORGER_ROLE, DEFAULT_ADDRESS);
            await defyForge.approveLootContract(defyLoot.address);

            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, defyForge.address);
            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyLoot['grantRole(bytes32,address)'](LOOT_BURNER_ROLE, defyForge.address);

            await defyLoot.mintBatch(SECONDARY_ADDRESS, [1, 2], [2, 3], 0x00);
            expect(await defyLoot.balanceOf(SECONDARY_ADDRESS, 1)).to.equal(2);

            await defyForge.createForgeJob(
                defyLoot.address,
                SECONDARY_ADDRESS,
                [1],
                [2],
                1000,
                [2],
                3
            );

            await helpers.time.increase(100);

            expect(await defyLoot.balanceOf(SECONDARY_ADDRESS, 1)).to.equal(0);

            await defyForge.cancelForgeJob(0);

            expect(await defyLoot.balanceOf(SECONDARY_ADDRESS, 1)).to.equal(1);
        });

        it("Should mint output token for a completed job", async function () {
            await defyForge['grantRole(bytes32,address)'](FORGER_ROLE, DEFAULT_ADDRESS);
            await defyForge.approveLootContract(defyLoot.address);

            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, defyForge.address);
            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyLoot['grantRole(bytes32,address)'](LOOT_BURNER_ROLE, defyForge.address);

            await defyLoot.mintBatch(SECONDARY_ADDRESS, [1, 2], [2, 3], 0x00);
            expect(await defyLoot.balanceOf(SECONDARY_ADDRESS, 1)).to.equal(2);

            await defyForge.createForgeJob(
                defyLoot.address,
                SECONDARY_ADDRESS,
                [1],
                [2],
                1,
                [2],
                3
            );

            expect(await defyLoot.balanceOf(SECONDARY_ADDRESS, 1)).to.equal(0);

            await defyForge.completeForgeJob(0);

            expect(await defyLoot.balanceOf(SECONDARY_ADDRESS, 3)).to.equal(1);
        });

    })

});
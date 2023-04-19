const { expect } = require("chai");
const { ethers } = require("hardhat");
const helpers = require("@nomicfoundation/hardhat-network-helpers");

let DEFYBatchBurn;
let defyBatchBurn;

let DEFYLoot;
let defyLoot;

let DEFAULT_ADMIN_ROLE, MINTER_ROLE, LOOT_BURNER_ROLE, PAUSER_ROLE;

describe("DEFYBatchBurn", function () {
    beforeEach(async function () {
        DEFYLoot = await ethers.getContractFactory("DEFYLoot");
        defyLoot = await DEFYLoot.deploy();
        await defyLoot.deployed();

        DEFYBatchBurn = await ethers.getContractFactory("DEFYBatchBurn");
        defyBatchBurn = await DEFYBatchBurn.deploy();
        await defyBatchBurn.deployed();

        DEFAULT_ADMIN_ROLE = await defyLoot["DEFAULT_ADMIN_ROLE()"]();
        PAUSER_ROLE = await defyLoot["PAUSER_ROLE()"]();
        MINTER_ROLE = await defyLoot["MINTER_ROLE()"]();
        LOOT_BURNER_ROLE = await defyLoot["LOOT_BURNER_ROLE()"]();
        LOOT_BURNER_ROLE = await defyBatchBurn["LOOT_BURNER_ROLE()"]();

        const [owner, secondaryAddress] = await ethers.getSigners();
        DEFAULT_ADDRESS = owner.address;
        SECONDARY_ADDRESS = secondaryAddress.address;

        DEFAULT_OWNER = owner;
        addr1 = secondaryAddress;
    });

    describe("DEFYBatchBurn", () => {
        it("Should fail to open crate if the loot contract is not approved", async function () {
            await defyBatchBurn["grantRole(bytes32,address)"](
                LOOT_BURNER_ROLE,
                DEFAULT_ADDRESS
            );
            await expect(
                defyBatchBurn.batchBurn(
                    defyLoot.address,
                    [DEFAULT_ADDRESS],
                    [1],
                    [1]
                )
            ).to.be.revertedWith("DEFYBatchBurn: Loot contract not valid");
        });

        it("Should fail if caller is not a burner", async function () {
            await expect(
                defyBatchBurn.batchBurn(
                    defyLoot.address,
                    [DEFAULT_ADDRESS],
                    [1],
                    [1]
                )
            ).to.be.revertedWith("AccessControl: account ");
        });

        it("Should fail a burn inputs are not valid", async function () {
            await defyBatchBurn["grantRole(bytes32,address)"](
                LOOT_BURNER_ROLE,
                DEFAULT_ADDRESS
            );
            await defyBatchBurn.approveLootContract(defyLoot.address);
            await expect(
                defyBatchBurn.batchBurn(
                    defyLoot.address,
                    [DEFAULT_ADDRESS],
                    [],
                    [1]
                )
            ).to.be.revertedWith("DEFYBatchBurn: Invalid input loots");
        });

        it("Should fail a burn inputs are not valid", async function () {
            await defyBatchBurn["grantRole(bytes32,address)"](
                LOOT_BURNER_ROLE,
                DEFAULT_ADDRESS
            );
            await defyBatchBurn.approveLootContract(defyLoot.address);
            await expect(
                defyBatchBurn.batchBurn(
                    defyLoot.address,
                    [DEFAULT_ADDRESS],
                    [1, 2],
                    [1]
                )
            ).to.be.revertedWith(
                "DEFYBatchBurn: All arrays must be the same length"
            );
        });

        it("Should fail if operative does not own input loots", async function () {
            await defyBatchBurn["grantRole(bytes32,address)"](
                LOOT_BURNER_ROLE,
                DEFAULT_ADDRESS
            );
            await defyBatchBurn.approveLootContract(defyLoot.address);
            await expect(
                defyBatchBurn.batchBurn(
                    defyLoot.address,
                    [DEFAULT_ADDRESS],
                    [1],
                    [1]
                )
            ).to.be.revertedWith(
                "DEFYBatchBurn: Operative does not have suffient loots"
            );
        });

        it("Should successfully burn input tokens when opening crate", async function () {
            await defyBatchBurn["grantRole(bytes32,address)"](
                LOOT_BURNER_ROLE,
                DEFAULT_ADDRESS
            );
            await defyBatchBurn.approveLootContract(defyLoot.address);

            await defyLoot["grantRole(bytes32,address)"](
                LOOT_BURNER_ROLE,
                defyBatchBurn.address
            );
            await defyLoot["grantRole(bytes32,address)"](
                MINTER_ROLE,
                DEFAULT_ADDRESS
            );

            await defyLoot.mintBatch(
                SECONDARY_ADDRESS,
                [10, 20],
                [10, 20],
                0x00
            );

            await defyBatchBurn.batchBurn(
                defyLoot.address,
                [SECONDARY_ADDRESS, SECONDARY_ADDRESS],
                [10, 20],
                [2, 5]
            );

            expect(await defyLoot.balanceOf(SECONDARY_ADDRESS, 10)).to.equal(8);
            expect(await defyLoot.balanceOf(SECONDARY_ADDRESS, 20)).to.equal(
                15
            );
        });
    });
});

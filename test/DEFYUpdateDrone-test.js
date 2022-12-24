const { expect } = require("chai");
const { ethers } = require("hardhat");
const helpers = require("@nomicfoundation/hardhat-network-helpers");

let DEFYDrone;
let defyDrone;

let DEFYLoot;
let defyLoot;

let DEFYUpdateDrone;
let defyUpdateDrone;

let DEFAULT_ADMIN_ROLE, MINTER_ROLE, LOOT_BURNER_ROLE, PAUSER_ROLE, URI_SETTER_ROLE, FORGER_ROLE, DRONE_MINTER_ROLE, DRONE_UPDATER_ROLE;

let DEFAULT_OWNER, addr1;

describe("DEFYUpdate", function () {

    beforeEach(async function () {
        DEFYLoot = await ethers.getContractFactory("DEFYLoot");
        defyLoot = await DEFYLoot.deploy();
        await defyLoot.deployed();

        DEFYDrone = await ethers.getContractFactory("DEFYDrone");
        defyDrone = await DEFYDrone.deploy();
        await defyDrone.deployed();

        DEFYUpdateDrone = await ethers.getContractFactory("DEFYUpdateDrone");
        defyUpdateDrone = await DEFYUpdateDrone.deploy();
        await defyUpdateDrone.deployed();

        DEFAULT_ADMIN_ROLE = await defyLoot['DEFAULT_ADMIN_ROLE()']();
        PAUSER_ROLE = await defyLoot['PAUSER_ROLE()']();
        MINTER_ROLE = await defyLoot['MINTER_ROLE()']();
        LOOT_BURNER_ROLE = await defyLoot['LOOT_BURNER_ROLE()']();
        URI_SETTER_ROLE = await defyLoot['URI_SETTER_ROLE()']();
        DRONE_UPDATER_ROLE = await defyUpdateDrone['DRONE_UPDATER_ROLE()']();
        DRONE_MINTER_ROLE = await defyDrone['DRONE_MINTER_ROLE()']();

        const [owner, secondaryAddress] = await ethers.getSigners();

        DEFAULT_ADDRESS = owner.address;
        SECONDARY_ADDRESS = secondaryAddress.address;

        DEFAULT_OWNER = owner;
        addr1 = secondaryAddress;

    });

    describe('DEFYUpdateDrone', () => {
        it("Should fail a update job if the loot contract is not approved", async function () {
            await defyUpdateDrone['grantRole(bytes32,address)'](DRONE_UPDATER_ROLE, DEFAULT_ADDRESS);
            await expect(defyUpdateDrone.updateDrone(
                defyLoot.address,
                defyDrone.address,
                DEFAULT_ADDRESS,
                [1],
                [1],
                0
            )).to.be.revertedWith('DEFYUpdateDrone: Loot contract not valid');
        });

        it("Should fail a update job if the drone contract is not approved", async function () {
            await defyUpdateDrone['grantRole(bytes32,address)'](DRONE_UPDATER_ROLE, DEFAULT_ADDRESS);
            await defyUpdateDrone.approveLootContract(defyLoot.address);
            await expect(defyUpdateDrone.updateDrone(
                defyLoot.address,
                defyDrone.address,
                DEFAULT_ADDRESS,
                [1],
                [1],
                0
            )).to.be.revertedWith('DEFYUpdateDrone: Drone contract not valid');
        });

        it("Should fail a update job if inputs are null", async function () {
            await defyUpdateDrone['grantRole(bytes32,address)'](DRONE_UPDATER_ROLE, DEFAULT_ADDRESS);
            await defyUpdateDrone.approveLootContract(defyLoot.address);
            await defyUpdateDrone.approveDroneContract(defyDrone.address);
            await expect(defyUpdateDrone.updateDrone(
                defyLoot.address,
                defyDrone.address,
                DEFAULT_ADDRESS,
                [1],
                [],
                0
            )).to.be.revertedWith('DEFYUpdateDrone: Invalid input loots');
        });

        it("Should fail a update job if inputs are different length", async function () {
            await defyUpdateDrone['grantRole(bytes32,address)'](DRONE_UPDATER_ROLE, DEFAULT_ADDRESS);
            await defyUpdateDrone.approveLootContract(defyLoot.address);
            await defyUpdateDrone.approveDroneContract(defyDrone.address);
            await expect(defyUpdateDrone.updateDrone(
                defyLoot.address,
                defyDrone.address,
                DEFAULT_ADDRESS,
                [1],
                [2, 3],
                0
            )).to.be.revertedWith('DEFYUpdateDrone: All arrays must be the same length');
        });

        it("Should fail a update job if operative does not own the drone", async function () {
            await defyUpdateDrone['grantRole(bytes32,address)'](DRONE_UPDATER_ROLE, DEFAULT_ADDRESS);
            await defyUpdateDrone.approveLootContract(defyLoot.address);
            await defyUpdateDrone.approveDroneContract(defyDrone.address);

            await defyDrone['grantRole(bytes32,address)'](DRONE_MINTER_ROLE, DEFAULT_ADDRESS);
            await defyDrone.safeMint(SECONDARY_ADDRESS);

            await expect(defyUpdateDrone.updateDrone(
                defyLoot.address,
                defyDrone.address,
                DEFAULT_ADDRESS,
                [1],
                [2],
                0
            )).to.be.revertedWith('DEFYUpdateDrone: Operative does not own drone');
        });

        it("Should fail a update job if operative does not own tokens", async function () {
            await defyUpdateDrone['grantRole(bytes32,address)'](DRONE_UPDATER_ROLE, DEFAULT_ADDRESS);
            await defyUpdateDrone.approveLootContract(defyLoot.address);
            await defyUpdateDrone.approveDroneContract(defyDrone.address);

            await defyDrone['grantRole(bytes32,address)'](DRONE_MINTER_ROLE, DEFAULT_ADDRESS);
            await defyDrone.safeMint(DEFAULT_ADDRESS);

            await expect(defyUpdateDrone.updateDrone(
                defyLoot.address,
                defyDrone.address,
                DEFAULT_ADDRESS,
                [1],
                [2],
                0
            )).to.be.revertedWith('DEFYUpdateDrone: Operative does not have suffient loots');
        });

        it("Should successfully update a drone and burn input loot", async function () {
            await defyUpdateDrone['grantRole(bytes32,address)'](DRONE_UPDATER_ROLE, DEFAULT_ADDRESS);
            await defyUpdateDrone.approveLootContract(defyLoot.address);
            await defyUpdateDrone.approveDroneContract(defyDrone.address);

            await defyDrone['grantRole(bytes32,address)'](DRONE_MINTER_ROLE, DEFAULT_ADDRESS);
            await defyDrone.safeMint(SECONDARY_ADDRESS);

            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, defyUpdateDrone.address);
            await defyLoot['grantRole(bytes32,address)'](LOOT_BURNER_ROLE, defyUpdateDrone.address);

            await defyLoot.mintBatch(SECONDARY_ADDRESS, [1, 2], [3, 3], 0x00);
            await defyUpdateDrone.updateDrone(
                defyLoot.address,
                defyDrone.address,
                SECONDARY_ADDRESS,
                [1],
                [2],
                0
            );

            expect(await defyLoot.balanceOf(SECONDARY_ADDRESS, 1)).to.equal(1);
            expect(await defyDrone.balanceOf(SECONDARY_ADDRESS)).to.equal(1);
            //expect(await defyUpdateDrone.getDroneTokenId(0)).to.equal(0);
            expect(await defyUpdateDrone.getUpdateJobsCount()).to.equal(1);
            expect(await defyUpdateDrone.getUpdateJobsCountByOperative(SECONDARY_ADDRESS)).to.equal(1);
        });

    });

});

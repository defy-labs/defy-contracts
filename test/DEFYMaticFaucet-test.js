const { expect } = require("chai");
const { ethers } = require("hardhat");
const helpers = require("@nomicfoundation/hardhat-network-helpers");
const { BigNumber } = require("ethers");

let DEFYMaticFaucet;
let defyMaticFaucet;

let DEFYLoot;
let defyLoot;

let DEFYMasks;
let defyMasks;

let DEFAULT_ADMIN_ROLE, MINTER_ROLE, PAUSER_ROLE, FAUCET_ROLE;

let addressWithNoEther, connectedAddressWithNoEther;

describe("DEFYMaticFaucet", function () {

    beforeEach(async function () {
        DEFYLoot = await ethers.getContractFactory("DEFYLoot");
        defyLoot = await DEFYLoot.deploy();
        await defyLoot.deployed();

        DEFYMasks = await ethers.getContractFactory("DEFYMasks");
        defyMasks = await DEFYMasks.deploy();
        await defyMasks.deployed();

        DEFYMaticFaucet = await ethers.getContractFactory("DEFYMaticFaucet");
        defyMaticFaucet = await DEFYMaticFaucet.deploy(defyLoot.address, defyMasks.address, 3);
        await defyMaticFaucet.deployed();

        DEFAULT_ADMIN_ROLE = await defyLoot['DEFAULT_ADMIN_ROLE()']();
        PAUSER_ROLE = await defyLoot['PAUSER_ROLE()']();
        MINTER_ROLE = await defyLoot['MINTER_ROLE()']();
        URI_SETTER_ROLE = await defyLoot['URI_SETTER_ROLE()']();

        DEFAULT_ADMIN_ROLE = await defyMaticFaucet['DEFAULT_ADMIN_ROLE()']();
        FAUCET_ROLE = await defyMaticFaucet['FAUCET_ROLE()']();

        DEFAULT_ADMIN_ROLE = await defyMasks['DEFAULT_ADMIN_ROLE()']();
        PAUSER_ROLE = await defyMasks['PAUSER_ROLE()']();
        MINTER_ROLE = await defyMasks['MINTER_ROLE()']();

        const [owner, secondaryAddress] = await ethers.getSigners();

        DEFAULT_ADDRESS = owner.address;
        SECONDARY_ADDRESS = secondaryAddress.address;

        DEFAULT_OWNER = owner;
        addr1 = secondaryAddress;

        const randomWallet = ethers.Wallet.createRandom();
        addressWithNoEther = randomWallet.address;
        connectedAddressWithNoEther = randomWallet.connect(ethers.provider);
    });

    describe('DEFYMaticFaucet', () => {
        it('Should receive Matic', async function () {
            await DEFAULT_OWNER.sendTransaction({
                to: defyMaticFaucet.address,
                value: ethers.utils.parseEther("1")
            });
            expect(await defyMaticFaucet.getBalance()).to.equal(ethers.utils.parseEther("1"));
        });

        it('Should withdraw all matic to owner', async function () {
            await DEFAULT_OWNER.sendTransaction({
                to: defyMaticFaucet.address,
                value: ethers.utils.parseEther("1")
            });
            var beforeAmount = await DEFAULT_OWNER.getBalance();

            await defyMaticFaucet.withdrawAllMatic(DEFAULT_ADDRESS);
            expect(await defyMaticFaucet.getBalance()).to.equal(0);

            var afterAmount = await DEFAULT_OWNER.getBalance();
            expect((afterAmount - beforeAmount) / 1e18).to.be.below(1).and.above(0.999)

        });

        if ('Should fail to faucet if the caller is not FAUCET_ROLE', async function () {
            await DEFAULT_OWNER.sendTransaction({
                to: defyMaticFaucet.address,
                value: ethers.utils.parseEther("1")
            });
            await expect(defyMaticFaucet.requestMatic(SECONDARY_ADDRESS))
                .to.be.revertedWith('AccessControl: ');
        });

        it('Should fail to faucet if address has matic', async function () {
            await defyMaticFaucet['grantRole(bytes32,address)'](FAUCET_ROLE, DEFAULT_ADDRESS);
            await DEFAULT_OWNER.sendTransaction({
                to: defyMaticFaucet.address,
                value: ethers.utils.parseEther("1")
            });
            await expect(defyMaticFaucet.requestMatic(SECONDARY_ADDRESS))
                .to.be.revertedWith('DEFYMaticFaucet: Address already has Matic');
        });

        it('Should fail to faucet if address has no loot', async function () {
            await defyMaticFaucet['grantRole(bytes32,address)'](FAUCET_ROLE, DEFAULT_ADDRESS);
            await addr1.sendTransaction({
                to: defyMaticFaucet.address,
                value: ethers.utils.parseEther("1")
            });

            await expect(defyMaticFaucet.requestMatic(addressWithNoEther))
                .to.be.revertedWith('DEFYMaticFaucet: Address does not own specified item');
        });

        it('Should fail to faucet if address has no mask', async function () {
            await defyMaticFaucet['grantRole(bytes32,address)'](FAUCET_ROLE, DEFAULT_ADDRESS);
            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await addr1.sendTransaction({
                to: defyMaticFaucet.address,
                value: ethers.utils.parseEther("1")
            });
            await defyLoot.mint(addressWithNoEther, 3, 3, 0x00);

            await expect(defyMaticFaucet.requestMatic(addressWithNoEther))
                .to.be.revertedWith('DEFYMaticFaucet: Address does not own a mask');
        });

        it('Should fail to faucet if address has already claimed', async function () {
            await defyMaticFaucet['grantRole(bytes32,address)'](FAUCET_ROLE, DEFAULT_ADDRESS);
            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyMasks['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);

            await addr1.sendTransaction({
                to: defyMaticFaucet.address,
                value: ethers.utils.parseEther("1")
            });
            await defyLoot.mint(addressWithNoEther, 3, 3, 0x00);
            await defyMasks.safeMint(addressWithNoEther);

            await defyMaticFaucet.setFaucetAmount(0);
            await defyMaticFaucet.requestMatic(addressWithNoEther);

            await expect(defyMaticFaucet.requestMatic(addressWithNoEther))
                .to.be.revertedWith('DEFYMaticFaucet: Address has already claimed Matic');
        });

        it('Should faucet the correct matic to address', async function () {
            await defyMaticFaucet['grantRole(bytes32,address)'](FAUCET_ROLE, DEFAULT_ADDRESS);
            await defyLoot['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);
            await defyMasks['grantRole(bytes32,address)'](MINTER_ROLE, DEFAULT_ADDRESS);

            await addr1.sendTransaction({
                to: defyMaticFaucet.address,
                value: ethers.utils.parseEther("1")
            });
            await defyLoot.mint(addressWithNoEther, 3, 3, 0x00);
            await defyMasks.safeMint(addressWithNoEther);

            await defyMaticFaucet.setFaucetAmount(1e9);
            await defyMaticFaucet.requestMatic(addressWithNoEther);
            expect(await connectedAddressWithNoEther.getBalance()).to.equal(ethers.BigNumber.from(1e9));
        });

    });
});
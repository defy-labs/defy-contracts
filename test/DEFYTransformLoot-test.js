const { expect } = require("chai");
const { ethers } = require("hardhat");
const helpers = require("@nomicfoundation/hardhat-network-helpers");

let DEFYTransformLoot;
let TransformLoot;

let DEFYLoot;
let defyLoot;

let DEFAULT_ADMIN_ROLE, MINTER_ROLE, LOOT_BURNER_ROLE, PAUSER_ROLE, OPENER_ROLE;

describe("DEFYTransformLoot", function () {
  beforeEach(async function () {
    DEFYLoot = await ethers.getContractFactory("DEFYLoot");
    defyLoot = await DEFYLoot.deploy();
    await defyLoot.deployed();

    DEFYTransformLoot = await ethers.getContractFactory("DEFYTransformLoot");
    defyTransformLoot = await DEFYTransformLoot.deploy();
    await defyTransformLoot.deployed();

    DEFAULT_ADMIN_ROLE = await defyLoot["DEFAULT_ADMIN_ROLE()"]();
    PAUSER_ROLE = await defyLoot["PAUSER_ROLE()"]();
    MINTER_ROLE = await defyLoot["MINTER_ROLE()"]();
    LOOT_BURNER_ROLE = await defyLoot["LOOT_BURNER_ROLE()"]();
    OPENER_ROLE = await defyTransformLoot["OPENER_ROLE()"]();

    const [owner, secondaryAddress] = await ethers.getSigners();
    DEFAULT_ADDRESS = owner.address;
    SECONDARY_ADDRESS = secondaryAddress.address;

    DEFAULT_OWNER = owner;
    addr1 = secondaryAddress;
  });

  describe("DEFYTransformLoot", () => {
    it("Should fail to transform loot if the loot contract is not approved", async function () {
      await defyTransformLoot["grantRole(bytes32,address)"](
        OPENER_ROLE,
        DEFAULT_ADDRESS
      );
      await expect(
        defyTransformLoot.transformLoot(
          defyLoot.address,
          DEFAULT_ADDRESS,
          [1],
          [1],
          [10],
          [1]
        )
      ).to.be.revertedWith("DEFYTransformLoot: Loot contract not valid");
    });

    it("Should fail if caller is not an opener", async function () {
      await expect(
        defyTransformLoot.transformLoot(
          defyLoot.address,
          DEFAULT_ADDRESS,
          [1],
          [1],
          [10],
          [1]
        )
      ).to.be.revertedWith("AccessControl: account ");
    });

    it("Should fail a transform loot if outputs are not valid", async function () {
      await defyTransformLoot["grantRole(bytes32,address)"](
        OPENER_ROLE,
        DEFAULT_ADDRESS
      );
      await defyTransformLoot.approveLootContract(defyLoot.address);
      await expect(
        defyTransformLoot.transformLoot(
          defyLoot.address,
          DEFAULT_ADDRESS,
          [],
          [1],
          [10],
          [1]
        )
      ).to.be.revertedWith("DEFYTransformLoot: Invalid input loots");
    });

    it("Should fail a transform loot if inputs are not valid", async function () {
      await defyTransformLoot["grantRole(bytes32,address)"](
        OPENER_ROLE,
        DEFAULT_ADDRESS
      );
      await defyTransformLoot.approveLootContract(defyLoot.address);
      await expect(
        defyTransformLoot.transformLoot(
          defyLoot.address,
          DEFAULT_ADDRESS,
          [1],
          [1],
          [10],
          []
        )
      ).to.be.revertedWith("DEFYTransformLoot: Invalid input loots");
    });

    it("Should fail if operative does not own input loots", async function () {
      await defyTransformLoot["grantRole(bytes32,address)"](
        OPENER_ROLE,
        DEFAULT_ADDRESS
      );
      await defyTransformLoot.approveLootContract(defyLoot.address);
      await expect(
        defyTransformLoot.transformLoot(
          defyLoot.address,
          DEFAULT_ADDRESS,
          [1],
          [1],
          [10],
          [1]
        )
      ).to.be.revertedWith(
        "DEFYTransformLoot: Operative does not own the input items"
      );
    });

    it("Should successfully burn input tokens when transforming loot", async function () {
      await defyTransformLoot["grantRole(bytes32,address)"](
        OPENER_ROLE,
        DEFAULT_ADDRESS
      );
      await defyTransformLoot.approveLootContract(defyLoot.address);

      await defyLoot["grantRole(bytes32,address)"](
        LOOT_BURNER_ROLE,
        defyTransformLoot.address
      );
      await defyLoot["grantRole(bytes32,address)"](
        MINTER_ROLE,
        defyTransformLoot.address
      );
      await defyLoot["grantRole(bytes32,address)"](
        MINTER_ROLE,
        DEFAULT_ADDRESS
      );

      await defyLoot.mintBatch(SECONDARY_ADDRESS, [10, 11], [10, 10], 0x00);

      await defyTransformLoot.transformLoot(
        defyLoot.address,
        SECONDARY_ADDRESS,
        [2],
        [2],
        [10, 11],
        [1, 2]
      );

      expect(await defyLoot.balanceOf(SECONDARY_ADDRESS, 2)).to.equal(2);
      expect(await defyLoot.balanceOf(SECONDARY_ADDRESS, 10)).to.equal(9);
      expect(await defyLoot.balanceOf(SECONDARY_ADDRESS, 11)).to.equal(8);
    });
  });
});

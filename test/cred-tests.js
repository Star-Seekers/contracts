const { assert } = require("chai");
const { deployments, ethers } = require("hardhat");

let cloningFacility;
let cred;
let admin;
let gameManager;
let fakeContractForTests;

beforeEach(async () => {
  await deployments.fixture();
  [admin, fakeContractForTests] = await ethers.getSigners();

  cloningFacility = await ethers.getContract("CloningFacility", admin);
  cred = await ethers.getContract("Cred", fakeContractForTests);
  gameManager = await ethers.getContract("GameManager", admin);
});

describe("CRED", async () => {
  it("should burn user tokens when spending", async () => {
    await cloningFacility.create("https://test.url", {
      value: await cloningFacility.cloneCostInBaseToken(),
    });
    await gameManager.addContract("Test", fakeContractForTests.address);

    assert.equal(
      ethers.utils.formatEther(await cred.balanceOf(admin.address)),
      "10000.0"
    );

    await cred.spend(admin.address, ethers.utils.parseEther("1000.0"));

    assert.equal(
      ethers.utils.formatEther(await cred.balanceOf(admin.address)),
      "9000.0"
    );
  });
});

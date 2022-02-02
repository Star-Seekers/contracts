const { assert } = require("chai");
const { deployments, ethers } = require("hardhat");

let clone;
let cloningFacility;
let admin;

beforeEach(async () => {
  await deployments.fixture();
  [admin] = await ethers.getSigners();

  clone = await ethers.getContract("Clone", admin);
  cloningFacility = await ethers.getContract("CloningFacility", admin);
});

describe("Clone", async () => {
  it("should get token URI from token contract", async () => {
    await cloningFacility.create("https://test.url", {
      value: await cloningFacility.cloneCostInBaseToken(),
    });

    assert.equal(await clone.tokenURI(1), "https://test.url");
  });
});

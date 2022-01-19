// const { assert } = require("chai");
const { assert } = require("chai");
const { deployments, ethers } = require("hardhat");

describe("Cloning Facility", async () => {
  let clongingFacility;
  let cred;
  let clone;
  // let gameManager;
  const [admin] = await ethers.getSigners();

  beforeEach(async () => {
    await deployments.fixture();

    clongingFacility = await ethers.getContract("CloningFacility", admin);
    // gameManager = await ethers.getContract("GameManager", admin);
    cred = await ethers.getContract("Cred", admin);
    clone = await ethers.getContract("Clone", admin);
  });

  it("should create a new clone", async () => {
    const tx = await clongingFacility.create("https://test.url", {
      value: ethers.utils.parseEther("0.7"),
    });
    const data = await tx.wait();

    assert.ok(Array.isArray(data.events));
    assert.equal(data.events.length, 5);

    for (let i = 0; i < data.events.length; i++) {
      if (typeof data.events[i].event !== "undefined") {
        assert.equal(data.events[i].event, "CloneCreated");
        assert.equal(data.events[i].args.cloneId, 0);
        assert.equal(data.events[i].args.owner, admin.address);
      }
    }

    console.log("cred contract", await cred.name());
    console.log("clone contract", await clone.name());
  });
});

const { assert, expect } = require("chai");
const { deployments, ethers } = require("hardhat");

let cloningFacility;
let cred;
let clone;
let admin;
let federation;
let fakeContractForTests;
let gameManager;

beforeEach(async () => {
  await deployments.fixture();
  [admin, federation, fakeContractForTests] = await ethers.getSigners();

  cloningFacility = await ethers.getContract("CloningFacility", admin);
  cred = await ethers.getContract("Cred", admin);
  clone = await ethers.getContract("Clone", admin);
  gameManager = await ethers.getContract("GameManager", admin);
});

describe("Cloning Facility", async () => {
  it("should create a new clone", async () => {
    const federationBalanceBefore = await ethers.provider.getBalance(
      federation.address
    );

    const tx = await cloningFacility.create("https://test.url", {
      value: await cloningFacility.cloneCostInBaseToken(),
    });
    const data = await tx.wait();

    assert.ok(Array.isArray(data.events));
    assert.equal(data.events.length, 5);

    for (let i = 0; i < data.events.length; i++) {
      if (typeof data.events[i].event !== "undefined") {
        assert.equal(data.events[i].event, "CloneCreated");
        assert.equal(data.events[i].args.cloneId.toNumber(), "1");
        assert.equal(data.events[i].args.owner, admin.address);
      }
    }

    await cloningFacility.create("https://test.url", {
      value: ethers.utils.parseEther(
        ethers.utils.formatEther(await cloningFacility.cloneCostInBaseToken())
      ),
    });

    const cloneBalance = await clone.balanceOf(admin.address);
    const credBalance = await cred.balanceOf(admin.address);
    const cloneData = await cloningFacility.getCloneData(1);
    const cloneUri = await cloningFacility.getCloneUri(1);
    const federationBalanceAfter = await ethers.provider.getBalance(
      federation.address
    );
    const cloneCostInBaseToken = await cloningFacility.cloneCostInBaseToken();

    assert.equal(
      ethers.utils.formatEther(
        federationBalanceBefore.add(cloneCostInBaseToken.mul(2))
      ),
      ethers.utils.formatEther(federationBalanceAfter)
    );
    assert.equal(cloneUri, "https://test.url");
    assert.equal(cloneData.for_sale, false);
    assert.equal(cloneData.uri, "https://test.url");
    assert.equal(ethers.utils.formatEther(credBalance), "10000.0");
    assert.equal(cloneBalance.toNumber(), 2);
  });

  it("should create a new clone and return the difference if the user over pays", async () => {
    const federationBalanceBefore = await ethers.provider.getBalance(
      federation.address
    );
    const cloneCostInBaseToken = await cloningFacility.cloneCostInBaseToken();

    const tx = await cloningFacility.create("https://test.url", {
      value: cloneCostInBaseToken.add(ethers.utils.parseEther("1.0")),
    });
    const data = await tx.wait();

    assert.ok(Array.isArray(data.events));
    assert.equal(data.events.length, 5);

    for (let i = 0; i < data.events.length; i++) {
      if (typeof data.events[i].event !== "undefined") {
        assert.equal(data.events[i].event, "CloneCreated");
        assert.equal(data.events[i].args.cloneId.toNumber(), "1");
        assert.equal(data.events[i].args.owner, admin.address);
      }
    }

    const cloneBalance = await clone.balanceOf(admin.address);
    const credBalance = await cred.balanceOf(admin.address);
    const cloneData = await cloningFacility.getCloneData(1);
    const cloneUri = await cloningFacility.getCloneUri(1);
    const federationBalanceAfter = await ethers.provider.getBalance(
      federation.address
    );

    assert.equal(
      ethers.utils.formatEther(
        federationBalanceBefore.add(cloneCostInBaseToken)
      ),
      ethers.utils.formatEther(federationBalanceAfter)
    );
    assert.equal(cloneUri, "https://test.url");
    assert.equal(cloneData.for_sale, false);
    assert.equal(cloneData.uri, "https://test.url");
    assert.equal(ethers.utils.formatEther(credBalance), "10000.0");
    assert.equal(cloneBalance.toNumber(), 1);
  });

  it("should change the clone uri", async () => {
    await cloningFacility.create("https://test.url", {
      value: await cloningFacility.cloneCostInBaseToken(),
    });
    expect(await cloningFacility.getCloneUri(1)).to.equal("https://test.url");
    await gameManager.addContract("Test", fakeContractForTests.address);
    cloningFacility = await ethers.getContract(
      "CloningFacility",
      fakeContractForTests
    );

    await cloningFacility.changeUri(1, "https://changed.url");
    expect(await cloningFacility.getCloneUri(1)).to.equal(
      "https://changed.url"
    );
  });
  it("should increase clone stat", async () => {
    await cloningFacility.create("https://test.url", {
      value: await cloningFacility.cloneCostInBaseToken(),
    });
    expect(await cloningFacility.getCloneUri(1)).to.equal("https://test.url");
    await gameManager.addContract("Test", fakeContractForTests.address);
    cloningFacility = await ethers.getContract(
      "CloningFacility",
      fakeContractForTests
    );

    await cloningFacility.increaseStat(1, 0, 1);
    expect(await cloningFacility.stats(1, 0)).to.equal(6);
  });
  it("should decrease clone stat", async () => {
    await cloningFacility.create("https://test.url", {
      value: await cloningFacility.cloneCostInBaseToken(),
    });
    expect(await cloningFacility.getCloneUri(1)).to.equal("https://test.url");
    await gameManager.addContract("Test", fakeContractForTests.address);
    cloningFacility = await ethers.getContract(
      "CloningFacility",
      fakeContractForTests
    );

    await cloningFacility.decreaseStat(1, 0, 1);
    expect(await cloningFacility.stats(1, 0)).to.equal(4);
  });
});

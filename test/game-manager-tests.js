const { expect, assert } = require("chai");
const { deployments, ethers, getNamedAccounts } = require("hardhat");

let gameManager;
let admin;
let federation;

beforeEach(async () => {
  await deployments.fixture();
  [admin, federation] = await ethers.getSigners();

  gameManager = await ethers.getContract("GameManager", admin);
});

describe("GameManager", async () => {
  it("should add a new contract to the list of approved contracts", async () => {
    const Learning = await deployments.get("Learning");

    const tx = await gameManager.addContract("Learning", Learning.address);
    const data = await tx.wait();

    assert.ok(Array.isArray(data.events));
    assert.equal(data.events.length, 1);

    assert.equal(data.events[0].event, "AddContract");
    assert.equal(data.events[0].args.name, "Learning");
    assert.equal(data.events[0].args.contractAddress, Learning.address);
    assert.equal(true, await gameManager.isGameContract(Learning.address));
  });

  it("should not add a new contract to the list of approved contracts if called by non admin", async () => {
    gameManager = await ethers.getContract("GameManager", federation);
    const Learning = await deployments.get("Learning");

    await expect(
      gameManager.addContract("Learning", Learning.address)
    ).to.be.revertedWith("Star Seekers: Admin only");
  });

  it("shoud change admin address when called by the admin", async () => {
    expect(await gameManager.admin()).to.equal(admin.address);

    await gameManager.changeAdmin(federation.address);

    expect(await gameManager.admin()).to.equal(federation.address);
  });

  it("shoud not change admin address when called by a non admin", async () => {
    expect(await gameManager.admin()).to.equal(admin.address);

    gameManager = await ethers.getContract("GameManager", federation);

    await expect(
      gameManager.changeAdmin(federation.address)
    ).to.be.revertedWith("Star Seekers: Admin only");
  });

  it("should remove a contract from the list of valid contracts", async () => {
    const Learning = await deployments.get("Learning");

    let tx = await gameManager.addContract("Learning", Learning.address);
    let data = await tx.wait();

    assert.equal(data.events[0].event, "AddContract");
    assert.equal(data.events[0].args.name, "Learning");
    assert.equal(data.events[0].args.contractAddress, Learning.address);
    assert.equal(true, await gameManager.isGameContract(Learning.address));
    assert.equal(
      Learning.address,
      await gameManager.contractAddresses("Learning")
    );

    tx = await gameManager.removeContract("Learning");
    data = await tx.wait();

    assert.equal(data.events[0].event, "RemoveContract");
    assert.equal(data.events[0].args.name, "Learning");
    assert.equal(data.events[0].args.contractAddress, Learning.address);
    assert.equal(false, await gameManager.isGameContract(Learning.address));
    assert.equal(
      ethers.constants.AddressZero,
      await gameManager.contractAddresses("Learning")
    );
  });

  it("should not remove a contract from the list of valid contracts when called by non admin", async () => {
    gameManager = await ethers.getContract("GameManager", federation);

    await expect(gameManager.removeContract("Learning")).to.be.revertedWith(
      "Star Seekers: Admin only"
    );
  });

  it("should set chainlink feed address", async () => {
    const { avaxChainlink } = await getNamedAccounts();
    const tx = await gameManager.setChainlinkFeed(avaxChainlink);
    const data = await tx.wait();

    assert.equal(data.events[0].event, "ChainlinkFeedUpdated");
    assert.equal(data.events[0].args.feed, avaxChainlink);
    assert.equal(await gameManager.chainlinkFeed(), avaxChainlink);
  });

  it("should not set chainlink feed address if called by non admin", async () => {
    const { avaxChainlink } = await getNamedAccounts();
    gameManager = await ethers.getContract("GameManager", federation);

    await expect(
      gameManager.setChainlinkFeed(avaxChainlink)
    ).to.be.revertedWith("Star Seekers: Admin only");
  });

  it("should set maintenance status", async () => {
    const tx = await gameManager.setMaintenance(true);
    const data = await tx.wait();

    assert.equal(data.events[0].event, "MaintenanceUpdated");
    assert.equal(data.events[0].args.status, true);
    assert.equal(await gameManager.maintenance(), true);
  });

  it("should not set maintenance status if called by non admin", async () => {
    gameManager = await ethers.getContract("GameManager", federation);

    await expect(gameManager.setMaintenance(true)).to.be.revertedWith(
      "Star Seekers: Admin only"
    );
  });

  it("should set sales tax", async () => {
    let salesTax = await gameManager.salesTax();
    assert.equal(salesTax.toNumber(), 5);

    const tx = await gameManager.setSalesTax(10);
    const data = await tx.wait();

    assert.equal(data.events[0].event, "SalesTaxUpdated");
    assert.equal(data.events[0].args.amount, 10);
    salesTax = await gameManager.salesTax();
    assert.equal(salesTax.toNumber(), 10);
  });

  it("should not set sales tax if called by non admin", async () => {
    gameManager = await ethers.getContract("GameManager", federation);

    await expect(gameManager.setSalesTax(10)).to.be.revertedWith(
      "Star Seekers: Admin only"
    );
  });

  it("should set fed address", async () => {
    let fed = await gameManager.federation();
    assert.equal(fed, federation.address);

    const tx = await gameManager.setFederation(admin.address);
    const data = await tx.wait();

    assert.equal(data.events[0].event, "FederationUpdated");
    assert.equal(data.events[0].args.federation, admin.address);
    fed = await gameManager.federation();
    assert.equal(fed, admin.address);
  });

  it("should not set fed address if called by non admin", async () => {
    gameManager = await ethers.getContract("GameManager", federation);

    await expect(gameManager.setFederation(admin.address)).to.be.revertedWith(
      "Star Seekers: Admin only"
    );
  });

  it("should set starting credits amount", async () => {
    let startingCred = await gameManager.startingCred();
    assert.equal(ethers.utils.formatEther(startingCred), "10000.0");

    const tx = await gameManager.setStartingCred(
      ethers.utils.parseEther("100000")
    );
    const data = await tx.wait();

    assert.equal(data.events[0].event, "StartingCredUpdated");
    assert.equal(
      ethers.utils.formatEther(data.events[0].args.amount),
      "100000.0"
    );
    startingCred = await gameManager.startingCred();
    assert.equal(ethers.utils.formatEther(startingCred), "100000.0");
  });

  it("should not set starting cred if called by non admin", async () => {
    gameManager = await ethers.getContract("GameManager", federation);

    await expect(
      gameManager.setStartingCred(ethers.utils.parseEther("10"))
    ).to.be.revertedWith("Star Seekers: Admin only");
  });
});

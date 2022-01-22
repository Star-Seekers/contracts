const { expect, assert } = require("chai");
const { deployments, ethers } = require("hardhat");

let cloneMarket;
let cloningFacility;
let clone;
let cred;
let admin;
let federation;
let playerOne;

beforeEach(async () => {
  await deployments.fixture();
  [admin, federation, playerOne] = await ethers.getSigners();

  cloneMarket = await ethers.getContract("CloneMarket", admin);
  cloningFacility = await ethers.getContract("CloningFacility", admin);
  clone = await ethers.getContract("Clone", admin);
});

describe("Clone Market", async () => {
  it("should list a clone for sale", async () => {
    await cloningFacility.create("https://test.url", {
      value: ethers.utils.parseEther(
        ethers.utils.formatEther(await cloningFacility.cloneCostInBaseToken())
      ),
    });

    await clone.setApprovalForAll(cloneMarket.address, true);

    const tx = await cloneMarket.list(0, ethers.utils.parseEther("1000"));
    const data = await tx.wait();

    assert.equal(data.events[0].event, "CloneListed");
    assert.equal(data.events[0].args.cloneId, 0);
    assert.equal(ethers.utils.formatEther(data.events[0].args.price), "1000.0");

    const cloneData = await cloningFacility.getCloneData(0);
    assert.equal(cloneData.for_sale, true);
    assert.equal(ethers.utils.formatEther(cloneData.price), "1000.0");
  });

  it("should not list a clone if user has not approved market contract", async () => {
    await cloningFacility.create("https://test.url", {
      value: ethers.utils.parseEther(
        ethers.utils.formatEther(await cloningFacility.cloneCostInBaseToken())
      ),
    });

    await expect(
      cloneMarket.list(0, ethers.utils.parseEther("1000"))
    ).to.be.revertedWith("Star Seekers: Market not approved");
  });

  it("should not list a clone if caller does not own it", async () => {
    await cloningFacility.create("https://test.url", {
      value: ethers.utils.parseEther(
        ethers.utils.formatEther(await cloningFacility.cloneCostInBaseToken())
      ),
    });

    clone = await ethers.getContract("Clone", federation);
    cloneMarket = await ethers.getContract("CloneMarket", federation);
    await clone.setApprovalForAll(cloneMarket.address, true);

    await expect(
      cloneMarket.list(0, ethers.utils.parseEther("1000"))
    ).to.be.revertedWith("Star Seekers: Clone owner only");
  });

  it("should cancel a listed clone if it has not been purchased", async () => {
    await cloningFacility.create("https://test.url", {
      value: ethers.utils.parseEther(
        ethers.utils.formatEther(await cloningFacility.cloneCostInBaseToken())
      ),
    });

    await clone.setApprovalForAll(cloneMarket.address, true);

    let tx = await cloneMarket.list(0, ethers.utils.parseEther("1000"));
    let data = await tx.wait();

    assert.equal(data.events[0].event, "CloneListed");
    assert.equal(data.events[0].args.cloneId, 0);
    assert.equal(ethers.utils.formatEther(data.events[0].args.price), "1000.0");

    tx = await cloneMarket.cancel(0);
    data = await tx.wait();

    assert.equal(data.events[0].event, "CloneListingCancelled");
    assert.equal(data.events[0].args.cloneId, 0);

    const cloneData = await cloningFacility.getCloneData(0);

    assert.equal(cloneData.for_sale, false);
    assert.equal(ethers.utils.formatEther(cloneData.price), "0.0");
  });

  it("should not buy a clone if user does not have enough CRED", async () => {
    await cloningFacility.create("https://test.url", {
      value: ethers.utils.parseEther(
        ethers.utils.formatEther(await cloningFacility.cloneCostInBaseToken())
      ),
    });

    await clone.setApprovalForAll(cloneMarket.address, true);

    const tx = await cloneMarket.list(0, ethers.utils.parseEther("1000"));
    const data = await tx.wait();

    assert.equal(data.events[0].event, "CloneListed");
    assert.equal(data.events[0].args.cloneId, 0);
    assert.equal(ethers.utils.formatEther(data.events[0].args.price), "1000.0");

    cloneMarket = await ethers.getContract("CloneMarket", federation);

    await expect(cloneMarket.buy(0)).to.be.revertedWith(
      "Star Seekers: Not enough CRED"
    );
  });
  it("should not allow owner to wash trade own clone", async () => {
    await cloningFacility.create("https://test.url", {
      value: ethers.utils.parseEther(
        ethers.utils.formatEther(await cloningFacility.cloneCostInBaseToken())
      ),
    });

    await clone.setApprovalForAll(cloneMarket.address, true);

    const tx = await cloneMarket.list(0, ethers.utils.parseEther("1000"));
    const data = await tx.wait();

    assert.equal(data.events[0].event, "CloneListed");
    assert.equal(data.events[0].args.cloneId, 0);
    assert.equal(ethers.utils.formatEther(data.events[0].args.price), "1000.0");

    await expect(cloneMarket.buy(0)).to.be.revertedWith(
      "Star Seekers: Can not purchase own clone"
    );
  });
  it("should not buy clone if buyer has not approved Market Contract for CRED allowance", async () => {
    await cloningFacility.create("https://test.url", {
      value: ethers.utils.parseEther(
        ethers.utils.formatEther(await cloningFacility.cloneCostInBaseToken())
      ),
    });
    await clone.setApprovalForAll(cloneMarket.address, true);

    const tx = await cloneMarket.list(0, ethers.utils.parseEther("1000"));
    const data = await tx.wait();

    assert.equal(data.events[0].event, "CloneListed");
    assert.equal(data.events[0].args.cloneId, 0);
    assert.equal(ethers.utils.formatEther(data.events[0].args.price), "1000.0");

    cloneMarket = await ethers.getContract("CloneMarket", federation);
    cloningFacility = await ethers.getContract("CloningFacility", federation);

    await cloningFacility.create("https://test.url", {
      value: ethers.utils.parseEther(
        ethers.utils.formatEther(await cloningFacility.cloneCostInBaseToken())
      ),
    });

    await expect(cloneMarket.buy(0)).to.be.revertedWith(
      "Star Seekers: Improper allowance"
    );
  });
  it("should not buy clone if the clone is not for sale", async () => {
    await cloningFacility.create("https://test.url", {
      value: ethers.utils.parseEther(
        ethers.utils.formatEther(await cloningFacility.cloneCostInBaseToken())
      ),
    });
    await clone.setApprovalForAll(cloneMarket.address, true);

    cloneMarket = await ethers.getContract("CloneMarket", federation);
    cloningFacility = await ethers.getContract("CloningFacility", federation);

    await cloningFacility.create("https://test.url", {
      value: ethers.utils.parseEther(
        ethers.utils.formatEther(await cloningFacility.cloneCostInBaseToken())
      ),
    });

    await expect(cloneMarket.buy(0)).to.be.revertedWith(
      "Star Seekers: Clone not for sale"
    );
  });

  it("should should purchase a clone", async () => {
    await cloningFacility.create("https://test.url", {
      value: ethers.utils.parseEther(
        ethers.utils.formatEther(await cloningFacility.cloneCostInBaseToken())
      ),
    });
    await clone.setApprovalForAll(cloneMarket.address, true);

    let tx = await cloneMarket.list(0, ethers.utils.parseEther("1000"));
    let data = await tx.wait();

    assert.equal(data.events[0].event, "CloneListed");
    assert.equal(data.events[0].args.cloneId, 0);
    assert.equal(ethers.utils.formatEther(data.events[0].args.price), "1000.0");

    cloneMarket = await ethers.getContract("CloneMarket", playerOne);
    cloningFacility = await ethers.getContract("CloningFacility", playerOne);

    await cloningFacility.create("https://test.url", {
      value: ethers.utils.parseEther(
        ethers.utils.formatEther(await cloningFacility.cloneCostInBaseToken())
      ),
    });

    cred = await ethers.getContract("Cred", playerOne);
    await cred.approve(cloneMarket.address, ethers.utils.parseEther("10000"));

    tx = await cloneMarket.buy(0);
    data = await tx.wait();

    const cloneData = await cloningFacility.getCloneData(0);
    const adminBalance = await clone.balanceOf(admin.address);
    const playerBalance = await clone.balanceOf(playerOne.address);
    assert.equal(
      ethers.utils.formatEther(await cred.balanceOf(admin.address)),
      "10950.0"
    );
    assert.equal(
      ethers.utils.formatEther(await cred.balanceOf(federation.address)),
      "50.0"
    );
    assert.equal(adminBalance.toNumber(), "0.0");
    assert.equal(playerBalance.toNumber(), "2.0");
    assert.equal(cloneData.owner, playerOne.address);
    assert.equal(await clone.ownerOf(cloneData.id), playerOne.address);
  });
});

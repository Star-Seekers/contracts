const { expect, assert } = require("chai");
const { deployments, ethers } = require("hardhat");

let skills;
let admin;
let cloningFacility;
let learning;

beforeEach(async () => {
  await deployments.fixture();
  [admin] = await ethers.getSigners();

  learning = await ethers.getContract("Learning", admin);
  skills = await ethers.getContract("Skills", admin);
  cloningFacility = await ethers.getContract("CloningFacility", admin);
});

describe("Learning", async () => {
  it("should start learning a skill", async () => {
    await cloningFacility.create("https://test.url", {
      value: await cloningFacility.cloneCostInBaseToken(),
    });

    const tx = await learning.startLearning(1, 1);
    const data = await tx.wait();

    assert.equal(data.events[0].event, "LearningStateUpdated");
    assert.equal(data.events[0].args.cloneId.toNumber(), 1);
    assert.equal(data.events[0].args.learningState.learning.toNumber(), 1);
    assert.equal(data.events[0].args.learningState.is_learning, true);
  });
  it("should not start learning a skill with dependency if the dependency isn't trained", async () => {
    const skill = await skills.getSkillById(2);

    const tx = await cloningFacility.create("https://test.url", {
      value: await cloningFacility.cloneCostInBaseToken(),
    });

    const clone = await tx.wait();

    await expect(
      learning.startLearning(clone.events[4].args.cloneId, skill.id)
    ).to.be.revertedWith(
      "Skill Seekers: Dependent skill must be level 5 before training"
    );
  });
  it("should start training a skill with a dependency", () => {});
  it("should not start learning if clone is for sale", async () => {});
  it("should not start learning if not called by owner", async () => {});
  it("should not start learning if in maintenance", async () => {});
  it("should complete learning a skill", async () => {});
  it("should not complete learning if clone is for sale", async () => {});
  it("should not complete learning if not called by owner", async () => {});
  it("should not complete learning if in maintenance", async () => {});
  it("should not start learning if skill does not exist", async () => {});
  it("should stop learning a skill", async () => {});
  it("should not stop learning if clone is for sale", async () => {});
  it("should not stop learning if not called by owner", async () => {});
  it("should not stop learning if in maintenance", async () => {});
});

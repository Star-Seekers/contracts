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
  it("should start training a skill with a dependency", async () => {
    await trainSkillToLevel(1, 1, 5);

    const tx = await learning.startLearning(1, 2);
    const data = await tx.wait();

    assert.equal(data.events[0].event, "LearningStateUpdated");
    const learningLog = await learning.getLearningLog(1, 1);
    assert.equal(learningLog.learning_points.toNumber(), 0);
    assert.equal(learningLog.skill_level.toNumber(), 5);
  });
  it("should complete learning a skill", async () => {
    await trainSkillToLevel(1, 1, 2);

    const learningLog = await learning.getLearningLog(1, 1);
    assert.equal(learningLog.skill_level.toNumber(), 2);
  });
  it("should stop learning a skill", async () => {
    await cloningFacility.create("https://test.url", {
      value: await cloningFacility.cloneCostInBaseToken(),
    });

    await learning.startLearning(1, 1);
    await ethers.provider.send("evm_increaseTime", [600]);
    await ethers.provider.send("evm_mine");

    await learning.stopLearning(1);
    const learningLog = await learning.getLearningLog(1, 1);
    assert.equal(learningLog.skill_level.toNumber(), 0);
    assert.equal(learningLog.learning_points.toNumber(), 18750);
  });
  it("should continue learning a stopped skill where it left off", async () => {
    await cloningFacility.create("https://test.url", {
      value: await cloningFacility.cloneCostInBaseToken(),
    });

    await learning.startLearning(1, 1);
    await ethers.provider.send("evm_increaseTime", [600]);
    await ethers.provider.send("evm_mine");

    await learning.stopLearning(1);
    let learningLog = await learning.getLearningLog(1, 1);
    assert.equal(learningLog.skill_level.toNumber(), 0);
    assert.equal(learningLog.learning_points.toNumber(), 18750);

    await learning.startLearning(1, 1);
    learningLog = await learning.getLearningLog(1, 1);
    let learningState = await learning.getLearningState(1);

    assert.equal(learningState.learning.toNumber(), 1);
    assert.equal(learningState.is_learning, true);
    assert.equal(learningLog.skill_level.toNumber(), 0);

    await ethers.provider.send("evm_increaseTime", [605]);
    await ethers.provider.send("evm_mine");

    await learning.completeLearning(1);
    learningLog = await learning.getLearningLog(1, 1);
    learningState = await learning.getLearningState(1);

    assert.equal(learningLog.skill_level.toNumber(), 1);
    assert.equal(learningLog.learning_points.toNumber(), 0);
    assert.equal(learningState.is_learning, false);
    assert.equal(learningState.learning.toNumber(), 0);
  });
  it("should not start learning if clone is for sale", async () => {});
  it("should not start learning if not called by owner", async () => {});
  it("should not start learning if in maintenance", async () => {});
  it("should not complete learning if not called by owner", async () => {});
  it("should not complete learning if in maintenance", async () => {});
  it("should not complete learning if skill training not complete", async () => {});
  it("should not start learning if skill does not exist", async () => {});

  it("should not stop learning if clone is for sale", async () => {});
  it("should not stop learning if not called by owner", async () => {});
  it("should not stop learning if in maintenance", async () => {});
});

const trainSkillToLevel = async (cloneId, skillId, level) => {
  await cloningFacility.create("https://test.url", {
    value: await cloningFacility.cloneCostInBaseToken(),
  });

  for (let i = 1; i <= level; i++) {
    await learning.startLearning(cloneId, skillId);

    const learningState = await learning.getLearningState(cloneId);
    const trainingTime = learningState.end_time.sub(learningState.start_time);

    await ethers.provider.send("evm_increaseTime", [
      trainingTime.toNumber() * 2,
    ]);
    await ethers.provider.send("evm_mine");

    await learning.completeLearning(cloneId);
  }
};

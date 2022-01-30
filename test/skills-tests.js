const { expect, assert } = require("chai");
const { deployments, ethers } = require("hardhat");

let skills;
let admin;
let federation;

beforeEach(async () => {
  await deployments.fixture();
  [admin, federation] = await ethers.getSigners();

  skills = await ethers.getContract("Skills", admin);
});

describe("Skills", async () => {
  it("should add a skill to the game", async () => {
    const tx = await skills.addSkill({
      dependency: false,
      primary_attribute: 0,
      secondary_attribute: 1,
      icon: "https://image.url",
      name: "Comptroller",
      dependency_id: 0, // if there is no dependency we use 0
      id: 0, /// we always pass 0 as the id when creating a new skill, an id will be assigned to the struct
      multiplier: 1,
    });

    const data = await tx.wait();

    assert.equal(data.events[0].event, "SkillAdded");
    assert.equal(data.events[0].args.skillId.toNumber(), 0);
    const skill = await skills.getSkillById(0);
    assert.equal(skill.dependency, false);
    assert.equal(skill.primary_attribute, 0);
    assert.equal(skill.secondary_attribute, 1);
    assert.equal(skill.icon, "https://image.url");
    assert.equal(skill.name, "Comptroller");
    assert.equal(skill.dependency_id, 0);
    assert.equal(skill.id, 0);
    assert.equal(skill.multiplier, 1);
  });

  it("should not add a skill to the game if not admin", async () => {
    skills = await ethers.getContract("Skills", federation);

    await expect(
      skills.addSkill({
        dependency: false,
        primary_attribute: 0,
        secondary_attribute: 1,
        icon: "https://image.url",
        name: "Comptroller",
        dependency_id: 0,
        id: 0,
        multiplier: 1,
      })
    ).to.be.revertedWith("Star Seekers: Admin only");
  });
  it("should remove a skill from the game", async () => {
    const tx = await skills.removeSkill(19);
    const data = await tx.wait();

    assert.equal(data.events[0].event, "SkillRemoved");
    assert.equal(data.events[0].args.skillId.toNumber(), 19);
    const skillRemoved = await skills.getSkillByName("Comptroller");
    assert.equal(skillRemoved.name, "");
  });
  it("should not remove a skill from the game if not admin", async () => {
    skills = await ethers.getContract("Skills", federation);

    await expect(skills.removeSkill(1)).to.be.revertedWith(
      "Star Seekers: Admin only"
    );
  });
});

// const { ethers } = require("ethers");
// const hre = require("hardhat").ethers;
const skillsJson = require("../json/skills.json");

module.exports = async ({
  getNamedAccounts,
  deployments,
  getChainId,
  ethers,
}) => {
  // const { deterministic, deploy, log } = deployments;
  const { log, deploy } = deployments;
  const { admin, federation, avaxChainlink } = await getNamedAccounts();
  const [adminSigner] = await ethers.getSigners();
  // const chainId = await getChainId();

  log("###################################");
  log(`#    Star Seekers: Deployments    #`);
  log("##########################################################");

  const GameManager = await deploy("GameManager", {
    from: federation,
    args: [],
    proxy: {
      owner: federation,
      execute: {
        methodName: "initialize",
        args: [admin, avaxChainlink, federation],
      },
    },
  });
  const gameManager = await ethers.getContract("GameManager", adminSigner);

  if (GameManager.newlyDeployed) {
    log(`# Game Manager Proxy: ${GameManager.address} `);
    log(`# Game Manager Implementation: ${GameManager.implementation}`);
    log("##########################################################");
  }

  const Skills = await deploy("Skills", {
    from: federation,
    args: [],
    proxy: {
      owner: federation,
      execute: {
        methodName: "initialize",
        args: [gameManager.address],
      },
    },
  });
  const skills = await ethers.getContract("Skills", adminSigner);

  if (Skills.newlyDeployed) {
    log(`# Skills Proxy: ${Skills.address} `);
    log(`# Skills Implementation: ${Skills.implementation} `);
    await gameManager.addContract("Skills", Skills.address);
    log("##########################################################");

    log("# Adding Skills");
    for (let i = 0; i < skillsJson.skills.security.length; i++) {
      await skills.addSkill(skillsJson.skills.security[i]);
      log(`# Skill: ${skillsJson.skills.security[i].name} Added`);
    }
    for (let i = 0; i < skillsJson.skills.mining.length; i++) {
      await skills.addSkill(skillsJson.skills.mining[i]);
      log(`# Skill: ${skillsJson.skills.mining[i].name} Added`);
    }
    for (let i = 0; i < skillsJson.skills.manufacturing.length; i++) {
      await skills.addSkill(skillsJson.skills.manufacturing[i]);
      log(`# Skill: ${skillsJson.skills.manufacturing[i].name} Added`);
    }
    for (let i = 0; i < skillsJson.skills.trading.length; i++) {
      await skills.addSkill(skillsJson.skills.trading[i]);
      log(`# Skill: ${skillsJson.skills.trading[i].name} Added`);
    }
    for (let i = 0; i < skillsJson.skills.fleet.length; i++) {
      await skills.addSkill(skillsJson.skills.fleet[i]);
      log(`# Skill: ${skillsJson.skills.fleet[i].name} Added`);
    }
    log("##########################################################");
  }

  const clone = await deploy("Clone", {
    from: federation,
    args: [],
    proxy: {
      owner: federation,
      execute: {
        methodName: "initialize",
        args: [gameManager.address],
      },
    },
  });

  if (clone.newlyDeployed) {
    log(`# Clone Proxy: ${clone.address} `);
    log(`# Clone Implementation: ${clone.implementation}`);
    await gameManager.addContract("Clone", clone.address);
    log("##########################################################");
  }

  const cloneMarket = await deploy("CloneMarket", {
    from: federation,
    args: [],
    proxy: {
      owner: federation,
      execute: {
        methodName: "initialize",
        args: [gameManager.address],
      },
    },
  });

  if (cloneMarket.newlyDeployed) {
    log(`# Clone Market Proxy: ${cloneMarket.address} `);
    log(`# Clone Market Implementation: ${cloneMarket.implementation} `);
    await gameManager.addContract("CloneMarket", cloneMarket.address);
    log("##########################################################");
  }

  const cloningFacility = await deploy("CloningFacility", {
    from: federation,
    args: [],
    proxy: {
      owner: federation,
      execute: {
        methodName: "initialize",
        args: [gameManager.address],
      },
    },
  });

  if (cloningFacility.newlyDeployed) {
    log(`# Cloning Facility Proxy: ${cloningFacility.address} `);
    log(
      `# Cloning Facility Implementation: ${cloningFacility.implementation} `
    );
    gameManager.addContract("CloningFacility", cloningFacility.address);
    log("##########################################################");
  }

  const learning = await deploy("Learning", {
    from: federation,
    args: [],
    proxy: {
      owner: federation,
      execute: {
        methodName: "initialize",
        args: [gameManager.address],
      },
    },
  });

  if (learning.newlyDeployed) {
    log(`# Learning Proxy: ${learning.address} `);
    log(`# Learning Implementation: ${learning.implementation} `);
    gameManager.addContract("Learning", learning.address);
    log("##########################################################");
  }

  const cred = await deploy("Cred", {
    from: federation,
    args: [],
    proxy: {
      owner: federation,
      execute: {
        methodName: "initialize",
        args: [gameManager.address],
      },
    },
  });

  if (cred.newlyDeployed) {
    log(`# CRED Proxy: ${cred.address} `);
    log(`# CRED Implementation: ${cred.implementation} `);
    gameManager.addContract("CRED", cred.address);
    log("##########################################################");
  }
};

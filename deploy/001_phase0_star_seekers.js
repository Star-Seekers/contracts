// const { ethers } = require("ethers");
// const hre = require("hardhat").ethers;

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

  const skills = await deploy("Skills", {
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

  if (skills.newlyDeployed) {
    log(`# Skills Proxy: ${skills.address} `);
    log(`# Skills Implementation: ${skills.implementation} `);
    await gameManager.addContract("Skills", skills.address);
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

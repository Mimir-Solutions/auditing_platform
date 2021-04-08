const { ethers, waffle, solidity } = require("hardhat");
const { deployContract, loadFixture } = waffle;
const { utils } = require("ethers").utils;
const { hexlify, parseUnits, formatUnits } = utils;
const { expect } = require("chai");
const { expectRevert, time, BN } = require('@openzeppelin/test-helpers');

describe(
  "AuditPlatformRepository contract waffle/chai/ethers test",
  function () {
    let deployer;
    let auditor;
    let nonAuditor;

    beforeEach(
      async function () {
        [
          deployer,
          auditor,
          nonAuditor
        ] = await ethers.getSigners();

        // UniswapV2FactoryContract = await ethers.getContractFactory("UniswapV2Factory");
        // uniswapV2Factory = await UniswapV2FactoryContract
        //     .connect( owner )
        //     .deploy( owner.address );

      }
    );

    describe(
      "Deployment",
      function () {
        it(
          "DeploymentSuccess", 
          async function() {
            // expect( await eris.hasRole( eris.DEFAULT_ADMIN_ROLE(), deployer.address ) ).to.equal( true );
            console.log("Test::Deployment::DeploymentSuccess: token name.");
            // expect( await eris.name() ).to.equal("ERIS");
            // console.log("Test::Deployment::DeploymentSuccess: token symbol.");
          }
        );
      }
    );
  }
);
const { ethers, waffle, solidity } = require("hardhat");
const { deployContract, loadFixture } = waffle;
const { utils } = require("ethers").utils;
const { hexlify, parseUnits, formatUnits } = utils;
const { expect } = require("chai");
const { expectRevert, time, BN } = require('@openzeppelin/test-helpers');

// describe(
//     "Fixtures",
//     () => {
//         async function deployment(
//             [deployer, buyer1],
//             provider
//         ) {
//             ErisContract = await ethers.getContractFactory("ErisToken");
//             eris = await ErisContract.connect( deployer ).deploy();

//             return 
//         }
//     }
// );

describe(
  "AuditorRepository contract waffle/chai/ethers test",
  function () {

    // Roles
    // let DEFAULT_ADMIN_ROLE = ethers.utils.solidityKeccak256( ["string"], ["DEFAULT_ADMIN_ROLE"] );
    // let MINTER_ROLE = ethers.utils.solidityKeccak256( ["string"], ["MINTER_ROLE"] );

    // let burnAddress = "0x0000000000000000000000000000000000000000";

    // Wallets
    let deployer;
    let auditor;
    let nonAuditor;

    // Contracts

    // let UniswapV2FactoryContract;
    // let uniswapV2Factory;

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

        // WETH9Contract = await ethers.getContractFactory("WETH9")
        // weth = await WETH9Contract.connect( owner ).deploy();

                // UniswapV2RouterContract = await ethers.getContractFactory("UniswapV2Router02");
                // uniswapV2Router = await UniswapV2RouterContract.connect( owner ).deploy( uniswapV2Factory.address, weth.address );

                // ErisContract = await ethers.getContractFactory("ErisToken");

                //Add check for events
                // eris = await ErisContract.connect( deployer ).deploy();

                // erisWETHDEXPair = await uniswapV2Factory.connect( owner ).getPair( eris.address, weth.address);
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
                        expect( await eris.name() ).to.equal("ERIS");
                        console.log("Test::Deployment::DeploymentSuccess: token symbol.");
                        expect( await eris.symbol() ).to.equal("ERIS");
                        console.log("Test::Deployment::DeploymentSuccess: token decimals.");
                        expect( await eris.decimals() ).to.equal(18);
                        //console.log("Deployment::DeploymentSuccess: token burnAddress.");
                        // expect( await eris.burnAddress() ).to.equal(burnAddress);
                        expect( await eris.totalSupply() ).to.equal( ethers.utils.parseUnits( String( 0 ), "ether" ) );
                        //console.log("Deployment::DeploymentSuccess: owner.");
                        // expect( await eris.owner() ).to.equal(owner.address);
                        //console.log("Deployment::DeploymentSuccess: devAddress.");
                        // expect( await eris.devAddress() ).to.equal(owner.address);
                        //console.log("Deployment::DeploymentSuccess: charityAddress.");
                        // expect( await eris.charityAddress() ).to.equal(charity.address);
                        //console.log("Deployment::DeploymentSuccess: qplgmeActive.");
                        // expect( await eris.qplgmeActive() ).to.equal(false);
                        expect( await eris.connect(deployer).balanceOf(deployer.address) ).to.equal( String( ethers.utils.parseUnits( String( 0 ), "ether" ) ) );
                        expect( await eris.connect(deployer).balanceOf(buyer1.address) ).to.equal( String( 0 ) );
                        // expect( await eris.connect(owner).balanceOf(charity.address) ).to.equal( String( 0 ) );
                        // expect( await eris.connect(owner).balanceOf( eris.uniswapV2ErisWETHDEXPairAddress() ) ).to.equal( String( 0 ) );
                        // expect( await eris.connect(owner).balanceOf( eris.address ) ).to.equal( String( 0 ) );
                    }
                );
            }
        );
    }
);
const { ethers, waffle, solidity } = require("hardhat");
const { deployContract, loadFixture } = waffle;
const { utils } = require("ethers").utils;
// const { hexlify, parseUnits, formatUnits } = utils;
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
    let ERC165_INTERFACE_ID = ethers.utils.solidityKeccak256( ["string"], ["supportsInterface(bytes4)"] );

    // Wallets
    let deployer;

    // Contracts

    let EERC1820ImplementerImplementorContract;
    let erc1820Implementor;

    beforeEach(
      async function () {
        [
          deployer
        ] = await ethers.getSigners();

        EERC1820ImplementerImplementorContract = await ethers.getContractFactory("ERC1820ImplementerImplementor");
        erc1820Implementor = await EERC1820ImplementerImplementorContract.connect( deployer ).deploy();
      }
    );

    describe(
      "Deployment",
      function () {
        it( 
          "DeploymentSuccess", 
          async function() {
            console.log( await erc1820Implementor.ERC1820_ACCEPT_MAGIC() );
            console.log( await erc1820Implementor.ERC1820_IMPLEMENTER_INTERFACE_ID() );
            expect( await erc1820Implementor.canImplementInterfaceForAddress( await erc1820Implementor.ERC1820_IMPLEMENTER_INTERFACE_ID(), erc1820Implementor.address ) ).to.equal( await erc1820Implementor.ERC1820_ACCEPT_MAGIC() );
          }
        );
      }
    );
  }
);
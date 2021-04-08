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

    let ERC165ImplementorContract;
    let erc165;

    beforeEach(
      async function () {
        [
          deployer
        ] = await ethers.getSigners();

        ERC165ImplementorContract = await ethers.getContractFactory("ERC165Implementor");
        erc165 = await ERC165ImplementorContract.connect( deployer ).deploy();
      }
    );

    describe(
      "Deployment",
      function () {
        it( 
          "DeploymentSuccess", 
          async function() {
            console.log( await erc165.ERC165_INTERFACE_ID() );
            expect( await erc165.supportsInterface( await erc165.ERC165_INTERFACE_ID() ) ).to.equal( true );
          }
        );
      }
    );
  }
);
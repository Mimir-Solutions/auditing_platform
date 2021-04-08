const { ethers, waffle, solidity } = require("hardhat");
const { deployContract, loadFixture } = waffle;
const { utils } = require("ethers").utils;
// const { hexlify, parseUnits, formatUnits } = utils;
const { expect } = require("chai");
const { expectRevert, time, BN } = require('@openzeppelin/test-helpers');

describe(
  "AuditorRepository contract waffle/chai/ethers test",
  function () {

    // Wallets
    let deployer;

    // Contracts

    let ERC1820ImplementerERC165CompliantImplementorContract;
    let erc1820Implementor;

    // beforeEach(
    //   async function () {
    //     [
    //       deployer
    //     ] = await ethers.getSigners();

    //     ERC1820ImplementerERC165CompliantImplementorContract = await ethers.getContractFactory("ERC1820ImplementerERC165CompliantImplementor");
    //     erc1820ImplementerERC165Compliant = await ERC1820ImplementerERC165CompliantImplementorContract.connect( deployer ).deploy();
    //   }
    // );

    // describe(
    //   "Deployment",
    //   function () {
    //     it( 
    //       "DeploymentSuccess", 
    //       async function() {
    //         console.log( await erc1820ImplementerERC165Compliant.ERC1820_ACCEPT_MAGIC() );
    //         console.log( await erc1820ImplementerERC165Compliant.ERC1820_IMPLEMENTER_INTERFACE_ID() );
    //         expect( await erc1820ImplementerERC165Compliant.supportsInterface( await erc1820ImplementerERC165Compliant.ERC165_INTERFACE_ID() ) ).to.equal( true );
    //         expect( await erc1820ImplementerERC165Compliant.supportsInterface( await erc1820ImplementerERC165Compliant.ERC1820_IMPLEMENTER_ERC165_INTERFACE_ID() ) ).to.equal( true );
    //         expect( 
    //           await erc1820ImplementerERC165Compliant.canImplementInterfaceForAddress( 
    //             await erc1820ImplementerERC165Compliant.ERC1820_IMPLEMENTER_INTERFACE_ID(), erc1820ImplementerERC165Compliant.address 
    //           ) 
    //         ).to.equal( await erc1820ImplementerERC165Compliant.ERC1820_ACCEPT_MAGIC() );
    //         expect( 
    //           await erc1820ImplementerERC165Compliant.canImplementInterfaceForAddress( 
    //             ethers.utils.parseBytes32String( await erc1820ImplementerERC165Compliant.ERC165_INTERFACE_ID() ), erc1820ImplementerERC165Compliant.address 
    //           )
    //         ).to.equal( await erc1820ImplementerERC165Compliant.ERC1820_ACCEPT_MAGIC() );
    //       }
    //     );
    //   }
    // );
  }
);
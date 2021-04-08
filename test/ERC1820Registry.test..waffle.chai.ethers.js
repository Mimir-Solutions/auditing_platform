const { ethers, waffle, solidity } = require("hardhat");
const { deployContract, loadFixture } = waffle;
const { utils } = require("ethers").utils;
// const { hexlify, parseUnits, formatUnits } = utils;
const { expect } = require("chai");
const { expectRevert, time, BN } = require('@openzeppelin/test-helpers');

describe(
  "ERC1820Registry contract waffle/chai/ethers test",
  function () {

    // Wallets
    let deployer;

    // Contracts

    let ERC1820RegistryContract;
    let erc1820Registry;

    beforeEach(
      async function () {
        [
          deployer
        ] = await ethers.getSigners();

        ERC1820RegistryContract = await ethers.getContractFactory("ERC1820Registry");
        erc1820Registry = await ERC1820RegistryContract.connect( deployer ).deploy();

        console.log( "Test::ERC1820Registry::beforeEach:01 erc1820Registry address is %s.", erc1820Registry.address );

        expect( await erc1820Registry.registerWithNewRegistry( erc1820Registry.address ) ).to.equal( true );
      }
    );

    describe(
      "Deployment",
      function () {
        it( 
          "DeploymentSuccess", 
          async function() {
            console.log( "Test::Deployment:01 ERC1820_ACCEPT_MAGIC is %s.", await erc1820Registry.ERC1820_ACCEPT_MAGIC() );
            console.log( await erc1820Registry.ERC1820_IMPLEMENTER_INTERFACE_ID() );
            console.log( await erc1820Registry.ERC1820_REGISTRAR_ERC1820_INTERFACE_ID() );
            expect( await erc1820Registry.supportsInterface( await erc1820Registry.ERC1820_IMPLEMENTER_INTERFACE_ID() ) ).to.equal( true );
            expect( await erc1820Registry.supportsInterface( await erc1820Registry.ERC1820_REGISTRAR_ERC1820_INTERFACE_ID() ) ).to.equal( true );
            expect( await erc1820Registry.supportsInterface( await erc1820Registry.ERC1820_REGISTRY_INTERFACE_ID() ) ).to.equal( true );
            expect( await erc1820ImplementerERC165Compliant.supportsInterface( await erc1820ImplementerERC165Compliant.ERC1820_IMPLEMENTER_ERC165_INTERFACE_ID() ) ).to.equal( true );
            expect( 
              await erc1820ImplementerERC165Compliant.canImplementInterfaceForAddress( 
                await erc1820ImplementerERC165Compliant.ERC1820_IMPLEMENTER_INTERFACE_ID(), erc1820ImplementerERC165Compliant.address 
              ) 
            ).to.equal( await erc1820ImplementerERC165Compliant.ERC1820_ACCEPT_MAGIC() );
            expect( 
              await erc1820ImplementerERC165Compliant.canImplementInterfaceForAddress( 
                await erc1820ImplementerERC165Compliant.ERC1820_REGISTRAR_ERC1820_INTERFACE_ID(), erc1820ImplementerERC165Compliant.address 
              ) 
            ).to.equal( await erc1820ImplementerERC165Compliant.ERC1820_ACCEPT_MAGIC() );
            expect( 
              await erc1820ImplementerERC165Compliant.canImplementInterfaceForAddress( 
                await erc1820ImplementerERC165Compliant.ERC1820_REGISTRY_INTERFACE_ID(), erc1820ImplementerERC165Compliant.address 
              ) 
            ).to.equal( await erc1820ImplementerERC165Compliant.ERC1820_ACCEPT_MAGIC() );
          }
        );
      }
    );
  }
);
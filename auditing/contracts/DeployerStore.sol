// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.1;

import "./SafeMath.sol";
import "./Ownable.sol";
// TODO: Add recursivev calls from IDatastore?

// TODO: Ban list for deploying addresses? Address list linking one address to others since you can easily create a new wallet
contract DeployerStore {
    
    using SafeMath for uint256; 

    /**
     *  @notice Represents the number of currently valid deployers
     */
    uint256 public activeDeployerCount;

    /**
     *  @notice Represents the number of invalid deployers who have been banned
     */
    uint256 public blacklistedDeployerCount;

    address previousDeployerStore;

    /**
     *  @param deployer The address of the deployer used as a check for whether the deployer exists
     *  @param blacklisted Indicator of whether the deployer has been banned
     *  @param approvedContracts Contains indexes of the contracts that the deployer has had approved
     *  @param opposedContracts Contains indexes of the contracts that the deployer has had opposed
     */
    struct Deployer {
        address    deployer;
        bool       blacklisted;
        uint256[]  approvedContracts;
        uint256[]  opposedContracts;
    }

    /**
     *  @notice Store data related to the deployers
     */
    mapping( address => Deployer ) public deployers;

    /**
     *  @notice Add a deployer into the current data store for the first time
     *  @param owner The platform that added the deployer
     *  @param deployer The deployer who has been added
     */
    event AddedDeployer(
        address indexed platform, 
        address indexed dataStore, 
        address indexed deployer
    );

    /**
     *  @notice Prevent the deployer from adding new contracts by suspending their access
     *  @param owner The platform that suspended the deployer
     *  @param deployer The deployer who has been suspended
     */
    event SuspendedDeployer(
        address indexed platformOwner,
        address indexed platform,
        address         dataStore,
        address indexed deployer
    );
    
    /**
     *  @notice Allow the deployer to continue acting as a valid deployer which can have their contracts added
     *  @param owner The platform that reinstated the deployer
     *  @param deployer The deployer who has been reinstated
     */
    event ReinstatedDeployer(
        address indexed platformOwner,
        address indexed platform,
        address         dataStore,
        address indexed deployer
    );

    event SetContractIndex(
        address platform, 
        address dataStore, 
        address deployer,
        uint256 contractIndex, 
        bool    approved 
    );
    
    event LinkedDeployerStore();

    constructor() public {}

    function addDeployer( address platform, address deployer ) external onlyOwner() {
        // If this is a new deployer address then write them into the store
        if ( !_hasDeployerRecord( deployer ) ) {
            deployers[ deployer ].deployer = deployer;

            activeDeployerCount = activeDeployerCount.add( 1 );

            emit AddedDeployer( platform, _msgSender(), deployer );
        } else if ( deployers[ deployer ].blacklisted ) {
            revert( "Deployer has been blacklisted" );
        }
    }

    function suspendDeployer( address platformOwner, address platform, address deployer ) external onlyOwner() {
        if ( _hasDeployerRecord( deployer ) ) {
            if ( !_isBlacklisted( deployer ) ) {
                revert( "Deployer has already been blacklisted" );
            }
            activeDeployerCount = activeDeployerCount.sub( 1 );
        } else {
            // If the previous store has been disabled when they were an auditor then write them into the (new) current store and disable
            // their permissions for writing into this store and onwards. They should not be able to write back into the previous store anyway
            deployers[ deployer ].deployer = deployer;
        }

        deployers[ deployer ].blacklisted = true;
        blacklistedDeployerCount = blacklistedDeployerCount.add( 1 );

        emit SuspendedDeployer( platformOwner, platform, _msgSender(), deployer );
    }

    function reinstateDeployer( address platformOwner, address platform, address deployer ) external onlyOwner() {
        require( _hasDeployerRecord( deployer ),    "No deployer record in the current store" );
        require( _isBlacklisted( deployer ),        "Deployer already has active status" );

        deployers[ deployer ].blacklisted = false;
        
        activeDeployerCount = activeDeployerCount.add( 1 );
        blacklistedDeployerCount = blacklistedDeployerCount.sub( 1 );

        emit ReinstatedDeployer( platformOwner, platform, _msgSender(), deployer );
    }

    function _hasDeployerRecord( address deployer ) private view returns ( bool ) {
        return deployers[ deployer ].deployer != address( 0 );
    }

    /**
     *  @dev Returns false in both cases where an deployer has not been added into this datastore or if they have been added but blacklisted
     */
    function isBlacklisted( address deployer ) external onlyOwner() view returns ( bool ) {
        return deployers[ deployer ].blacklisted;
    }

    function getDeployerInformation( address deployer ) external onlyOwner() view returns ( bool, uint256, uint256 ) {
        require( _hasDeployerRecord( deployer ), "No deployer record in the current store" );

        return 
        (
            deployers[ deployer ].blacklisted, 
            deployers[ deployer ].approvedContracts.length, 
            deployers[ deployer ].opposedContracts.length
        );
    }

    function getDeployerApprovedContractIndex( address deployer, uint256 contractIndex ) external onlyOwner() view returns ( uint256 ) {
        require( _hasDeployerRecord( deployer ),                                    "No deployer record in the current store" );
        require( 0 < deployers[ deployer ].approvedContracts.length,                "Approved list is empty" );
        require( contractIndex <= deployers[ deployer ].approvedContracts.length,   "Record does not exist" );

        // Indexing from the number 0 therefore decrement if you must
        if ( contractIndex != 0 ) {
            contractIndex = contractIndex.sub( 1 );
        }

        return deployers[ deployer ].approvedContracts[ contractIndex ];
    }

    function getDeployerOpposedContractIndex( address deployer, uint256 contractIndex ) external view returns ( uint256 ) {
        require( _hasDeployerRecord( deployer ),                                    "No deployer record in the current store" );
        require( 0 < deployers[ deployer ].opposedContracts.length,                 "Opposed list is empty" );
        require( contractIndex <= deployers[ deployer ].opposedContracts.length,    "Record does not exist" );

        // Indexing from the number 0 therefore decrement if you must
        if ( contractIndex != 0 ) {
            contractIndex = contractIndex.sub( 1 );
        }

        return deployers[ deployer ].opposedContracts[ contractIndex ];
    }

    function saveContractIndexForDeplyer( address platform, address deployer, bool approved, uint256 contractIndex ) external onlyOwner() {
        if ( approved ) {
            deployers[ deployer ].approvedContracts.push( contractIndex );
        } else {
            deployers[ deployer ].opposedContracts.push( contractIndex );
        }

        emit SetContractIndex( platform, msg.sender, deployer, contractIndex, approved );
    }

    function linkDeplyerStore( address deplyerStore ) external onlyOwner() {
        previousDeployerStore = deplyerStore;
    }

    
}


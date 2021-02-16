// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.1;

import "./SafeMath.sol";
import "./IDatastore.sol";
import "./Ownable.sol";

contract AuditorStore {
    
    using SafeMath for uint256;

    /**
     * @param activeAuditorCount Represents the number of currently valid auditors who can write into the store
     */
    uint256 public activeAuditorCount;

    /**
     * @param activeAuditorCount Represents the number of currently invalid auditors who have their write permissions suspended
     */
    uint256 public suspendedAuditorCount;
    
    address previousAuditorStore;

    /**
     * @param auditor The address of the auditor used as a check for whether the auditor exists
     * @param isAuditor Indicator of whether the auditor currently has write permissions
     * @param approvedContracts Contains indexes of the contracts that the auditor has approved
     * @param opposedContracts Contains indexes of the contracts that the auditor has opposed
     */
    struct Auditor {
        address    auditor;
        bool       isAuditor;
        uint256[]  approvedContracts;
        uint256[]  opposedContracts;
    }

    /**
     * @notice Store data related to the auditors
     */
    mapping( address => Auditor ) public auditors;

    /**
     * @notice Add an auditor into the current data store for the first time
     * @param platformOwner The admin of a platform that is able to manipulate the auditors
     * @param platform The organization which the dataStore belongs to
     * @param dataStore The data store which called into this auditor store
     * @param auditor The entity that is/was deemed as someone able to perform audits
     */
    event AddedAuditor(
        address platformOwner, 
        address platform, 
        address indexed dataStore, 
        address indexed auditor
    );

    /**
     * @notice Prevent the auditor from adding new records by suspending their access
     * @param platformOwner The admin of a platform that is able to manipulate the auditors
     * @param platform The organization which the dataStore belongs to
     * @param dataStore The data store which called into this auditor store
     * @param auditor The entity that is/was deemed as someone able to perform audits
     */
    event SuspendedAuditor(
        address platformOwner, 
        address platform, 
        address indexed dataStore, 
        address indexed auditor
    );
    
    /**
     * @notice Allow the auditor to continue acting as a valid auditor which can add new records
     * @param platformOwner The admin of a platform that is able to manipulate the auditors
     * @param platform The organization which the dataStore belongs to
     * @param dataStore The data store which called into this auditor store
     * @param auditor The entity that is/was deemed as someone able to perform audits
     */
    event ReinstatedAuditor(
        address platformOwner, 
        address platform, 
        address indexed dataStore, 
        address indexed auditor
    );

    /**
     * @notice If the auditor is currently a valid auditor then they can be migrated into the newer store
     * @param migrator Who attempted the migration (pre-access control it is the auditor themselves)
     * @param auditor The auditor who is being migrated
     */
    event AcceptedMigration( address indexed migrator, address indexed auditor );

    event SetContractIndex(
        address platform, 
        address dataStore, 
        address auditor, 
        uint256 index,
        bool approved
    );
    
    event LinkedAuditorStore();

    constructor() public {}

    function addAuditor( address platformOwner, address platform, address auditor ) external onlyOwner() {
        require( !_hasAuditorRecord( auditor ), "Auditor record already exists" );

        auditors[ auditor ].isAuditor = true;
        auditors[ auditor ].auditor = auditor;

        activeAuditorCount = activeAuditorCount.add( 1 );

        emit AddedAuditor( platformOwner, platform, _msgSender(), auditor );
    }

    function suspendAuditor( address platformOwner, address platform, address auditor ) external onlyOwner() {
        if ( _hasAuditorRecord( auditor ) ) {
            if ( !_isAuditor( auditor ) ) {
                revert( "Auditor has already been suspended" );
            }
            activeAuditorCount = activeAuditorCount.sub( 1 );
        } else {
            // If the previous store has been disabled when they were an auditor then write them into the (new) current store 
            // and disable their permissions for writing into this store and onwards. They should not be able to write back into 
            // the previous store anyway
            auditors[ auditor ].auditor = auditor;
        }

        auditors[ auditor ].isAuditor = false;        
        suspendedAuditorCount = suspendedAuditorCount.add( 1 );

        emit SuspendedAuditor( platformOwner, platform, _msgSender(), auditor );
    }

    function reinstateAuditor( address platformOwner, address platform, address auditor ) external onlyOwner() {
        require( _hasAuditorRecord( auditor ),  "No auditor record in the current store" );
        require( !_isAuditor( auditor ),        "Auditor already has active status" );

        auditors[ auditor ].isAuditor = true;
        
        activeAuditorCount = activeAuditorCount.add( 1 );
        suspendedAuditorCount = suspendedAuditorCount.sub( 1 );

        emit ReinstatedAuditor( platformOwner, platform, _msgSender(), auditor );
    }

    function hasAuditorRecord( address auditor ) external onlyOwner() view returns ( bool ) {
        return auditors[ auditor ].auditor != address( 0 );
    }

    /**
     * @dev Returns false in both cases where an auditor has not been added into this datastore or if they have been added but suspended
     */
    function isAuditor( address auditor ) external onlyOwner() view returns ( bool ) {
        return auditors[ auditor ].isAuditor;
    }

    function getAuditorInformation( address auditor ) external onlyOwner() view returns ( bool, uint256, uint256 ) {
        require( _hasAuditorRecord( auditor ), "No auditor record in the current store" );

        return 
        (
            auditors[ auditor ].isAuditor, 
            auditors[ auditor ].approvedContracts.length, 
            auditors[ auditor ].opposedContracts.length
        );
    }

    /**
     * @notice 
     * @param auditor The entity that is/was deemed as someone able to perform audits
     * @param index A number which should be less than or equal to the total number of approved contracts for the auditor
     * @return A number that represents the location in the contract array where the contract information is referenced by
     */
    function getAuditorApprovedContractIndex( address auditor, uint256 index ) external onlyOwner() view returns ( uint256 ) {
        require( _hasAuditorRecord( auditor ),                          "There is no record of the specified auditor in the current store" );
        require( 0 < auditors[ auditor ].approvedContracts.length,      "Approved list is empty" );
        require( index <= auditors[ auditor ].approvedContracts.length, "Record does not exist" );

        // Indexing from the number 0 therefore decrement if you must
        if ( index != 0 ) {
            index = index.sub( 1 );
        }

        return auditors[ auditor ].approvedContracts[ index ];
    }

    /**
     * @notice 
     * @param auditor The entity that is/was deemed as someone able to perform audits
     * @param index A number which should be less than or equal to the total number of opposed contracts for the auditor
     * @return A number that represents the location in the contract array where the contract information is referenced by
     */
    function getAuditorOpposedContractIndex( address auditor, uint256 index ) external onlyOwner() view returns ( uint256 ) {
        require( _hasAuditorRecord( auditor ),                          "There is no record of the specified auditor in the current store" );
        require( 0 < auditors[ auditor ].opposedContracts.length,       "Opposed list is empty" );
        require( index <= auditors[ auditor ].opposedContracts.length,  "Record does not exist" );

        // Indexing from the number 0 therefore decrement if you must
        if ( index != 0 ) {
            index = index.sub( 1 );
        }

        return auditors[ auditor ].opposedContracts[ index ];
    }

    function migrate( address platform, address previousDatastore, address auditor ) external onlyOwner() {
        // Auditor should not exist to mitigate event spamming or possible neglectful changes to 
        // _recursiveIsAuditorSearch(address) which may allow them to switch their suspended status to active
        require( !_hasAuditorRecord( auditor ), "Already in data store" );
        
        bool isAnAuditor = _recursiveIsAuditorSearch( auditor, previousDatastore );

        if ( isAnAuditor ) {
            // Do not rewrite previous audits into each new datastore as that will eventually become too expensive
            auditors[ auditor ].isAuditor = true;
            auditors[ auditor ].auditor = auditor;

            activeAuditorCount = activeAuditorCount.add( 1 );

            emit AcceptedMigration( platform, auditor );
        } else {
            revert( "Auditor is either suspended or has never been in the system" );
        }
    }

    function saveContractIndexForAuditor( address platform, address auditor, bool approved, uint256 index ) external onlyOwner() {
        if ( approved ) {
            auditors[ auditor ].approvedContracts.push( index );
        } else {
            auditors[ auditor ].opposedContracts.push( index );
        }

        emit SetContractIndex( platform, msg.sender, auditor, index, approved );
    }

    function _recursiveIsAuditorSearch( address auditor, address previousDatastore ) private view returns ( bool ) {
        bool isAnAuditor = false;

        if ( _hasAuditorRecord( auditor ) ) {
            if ( _isAuditor( auditor ) ) {
                isAnAuditor = true;
            }
        } else if ( previousDatastore != address( 0 ) ) {
            bool isAnAuditor = IDatastore( previousDatastore ).searchAllStoresForIsAuditor( auditor );
        } else {
            revert( "No auditor record in any data store" );
        }

        return isAnAuditor;
    }
    
    function linkAuditorStore( address auditorStore ) external onlyOwner() {
        previousAuditorStore = auditorStore;
    }

}


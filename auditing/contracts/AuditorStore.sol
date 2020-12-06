// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.4;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IDatastore.sol";

contract AuditorStore {
    
    using SafeMath for uint256;

    /**
     *  @param activeAuditorCount Represents the number of currently valid auditors who can write into the store
     */
    uint256 public activeAuditorCount;

    /**
     *  @param activeAuditorCount Represents the number of currently invalid auditors who have their write permissions suspended
     */
    uint256 public suspendedAuditorCount;

    /**
     *  @param auditor The address of the auditor used as a check for whether the auditor exists
     *  @param isAuditor Indicator of whether the auditor currently has write permissions
     *  @param approvedContracts Contains indexes of the contracts that the auditor has approved
     *  @param opposedContracts Contains indexes of the contracts that the auditor has opposed
     */
    struct Auditor {
        address    auditor;
        bool       isAuditor;
        uint256[]  approvedContracts;
        uint256[]  opposedContracts;
    }

    /**
     *  @notice Store data related to the auditors
     */
    mapping( address => Auditor ) public auditors;

    /**
     *  @notice Add an auditor into the current data store for the first time
     *  @param owner The platform that added the auditor
     *  @param auditor The auditor who has been added
     */
    event AddedAuditor( address indexed owner, address indexed auditor );

    /**
     *  @notice Prevent the auditor from adding new records by suspending their access
     *  @param owner The platform that suspended the auditor
     *  @param auditor The auditor who has been suspended
     */
    event SuspendedAuditor( address indexed owner, address indexed auditor );
    
    /**
     *  @notice Allow the auditor to continue acting as a valid auditor which can add new records
     *  @param owner The platform that reinstated the auditor
     *  @param auditor The auditor who has been reinstated
     */
    event ReinstatedAuditor( address indexed owner, address indexed auditor );

    /**
     *  @notice If the auditor is currently a valid auditor then they can be migrated into the newer store
     *  @param migrator Who attempted the migration (pre-access control it is the auditor themselves)
     *  @param auditor The auditor who is being migrated
     */
    event AcceptedMigration( address indexed migrator, address indexed auditor );

    constructor() internal {}

    function _addAuditor( address auditor ) internal {
        require( !_hasAuditorRecord( auditor ), "Auditor record already exists" );

        auditors[ auditor ].isAuditor = true;
        auditors[ auditor ].auditor = auditor;

        activeAuditorCount = activeAuditorCount.add( 1 );

        // Which platform initiated the call on the auditor
        // Since this is an internal call will the caller change to the data store?
        emit AddedAuditor( _msgSender(), auditor );
    }

    function _suspendAuditor( address auditor ) internal {
        if ( _hasAuditorRecord( auditor ) ) {
            if ( !_isAuditor( auditor ) ) {
                revert( "Auditor has already been suspended" );
            }
            activeAuditorCount = activeAuditorCount.sub( 1 );
        } else {
            // If the previous store has been disabled when they were an auditor then write them into the (new) current store and disable
            // their permissions for writing into this store and onwards. They should not be able to write back into the previous store anyway
            auditors[ auditor ].auditor = auditor;
        }

        auditors[auditor].isAuditor = false;        
        suspendedAuditorCount = suspendedAuditorCount.add( 1 );

        // Which platform initiated the call on the auditor
        // Since this is an internal call will the caller change to the data store?
        emit SuspendedAuditor( _msgSender(), auditor );
    }

    function _reinstateAuditor( address auditor ) internal {
        require( _hasAuditorRecord( auditor ),  "No auditor record in the current store" );
        require( !_isAuditor( auditor ),        "Auditor already has active status" );

        auditors[ auditor ].isAuditor = true;
        
        activeAuditorCount = activeAuditorCount.add( 1 );
        suspendedAuditorCount = suspendedAuditorCount.sub( 1 );

        // Which platform initiated the call on the auditor
        // Since this is an internal call will the caller change to the data store?
        emit ReinstatedAuditor( _msgSender(), auditor );
    }

    function _hasAuditorRecord( address auditor ) internal view returns ( bool ) {
        return auditors[ auditor ].auditor != address( 0 );
    }

    /**
     *  @dev Returns false in both cases where an auditor has not been added into this datastore or if they have been added but suspended
     */
    function _isAuditor( address auditor ) internal view returns ( bool ) {
        return auditors[ auditor ].isAuditor;
    }

    function _auditorDetails( address auditor ) internal view returns ( bool, uint256, uint256 ) {
        require( _hasAuditorRecord( auditor ), "No auditor record in the current store" );

        return 
        (
            auditors[ auditor ].isAuditor, 
            auditors[ auditor ].approvedContracts.length, 
            auditors[ auditor ].opposedContracts.length
        );
    }

    function _auditorApprovedContract( address auditor, uint256 index ) internal view returns ( uint256 ) {
        require( _hasAuditorRecord( auditor ),                          "No auditor record in the current store" );
        require( 0 < auditors[ auditor ].approvedContracts.length,      "Approved list is empty" );
        require( index <= auditors[ auditor ].approvedContracts.length, "Record does not exist" );

        // Indexing from the number 0 therefore decrement if you must
        if ( index != 0 ) {
            index = index.sub( 1 );
        }

        return auditors[ auditor ].approvedContracts[ index ];
    }

    function _auditorOpposedContract( address auditor, uint256 index ) internal view returns ( uint256 ) {
        require( _hasAuditorRecord( auditor ),                          "No auditor record in the current store" );
        require( 0 < auditors[ auditor ].opposedContracts.length,       "Opposed list is empty" );
        require( index <= auditors[ auditor ].opposedContracts.length,  "Record does not exist" );

        // Indexing from the number 0 therefore decrement if you must
        if ( index != 0 ) {
            index = index.sub( 1 );
        }

        return auditors[ auditor ].opposedContracts[ index ];
    }

    function _migrate( address migrator, address auditor ) internal {
        // Auditor should not exist to mitigate event spamming or possible neglectful changes to 
        // _recursiveAuditorSearch(address) which may allow them to switch their suspended status to active
        require( !_hasAuditorRecord( auditor ), "Already in data store" );
        
        bool isAnAuditor = _recursiveAuditorSearch( auditor );

        if ( isAnAuditor ) {
            // Do not rewrite previous audits into each new datastore as that will eventually become too expensive
            auditors[ auditor ].isAuditor = true;
            auditors[ auditor ].auditor = auditor;

            activeAuditorCount = activeAuditorCount.add( 1 );

            emit AcceptedMigration( migrator, auditor );
        } else {
            revert( "Auditor is either suspended or has never been in the system" );
        }
    }

    function _saveContractIndexForAuditor( address auditor, bool approved, uint256 index ) internal {
        if ( approved ) {
            auditors[ auditor ].approvedContracts.push( index );
        } else {
            auditors[ auditor ].opposedContracts.push( index );
        }
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

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.4;

import "./Pausable.sol";
import "./IDatastore.sol";
import "./IAuditNFT.sol";

// TODO: How do you implement the completeAudit, migrateAuditor, contractDestructed via an interface? Prettu sure the caller using the interface would be the contract ...
// TODO: Does the platform really need the same events as the store? Pointless in between?

contract Platform is Pausable {

    /**
        @notice The non-fungible token that shall be issued as a receipt to the auditor for their work
        @dev A new NFT should be issued with each new iteration of the platform
     */ 
    address public NFT;

    /**
        @notice The storage for the auditors and their audits
        @dev The store may be swapped out over time
     */
    address public dataStore;

    /**
        @notice As new versions are issued the variable will be updated to reflect that
     */
    string public constant version = "Demo: 1";

    /**
        @notice Event tracking whenever an auditor is added and who added them
        @param _owner The current owner of the platform
        @param auditor The auditor that has been added
     */
    event AuditorAdded( address indexed owner, address indexed auditor );

    /**
        @notice Event tracking whenever an auditor is suspended and who suspended them, will prevent the auditor from completing future audits
        @param _owner The current owner of the platform
        @param auditor The auditor who has been blocked for continuing to use the platform to perform audits
     */
    event AuditorSuspended( address indexed owner, address indexed auditor );

    /**
        @notice Event tracking whenever an auditor is reinstated and who reinstated them, will allow the auditor to complete audits again
        @param _owner The current owner of the platform
        @param auditor The auditor who can complete audits again
     */
    event AuditorReinstated( address indexed owner, address indexed auditor );

    /**
        @notice Event tracking whenever an auditor has migrated themselves to the new datastore
        @param _sender Who initiated the migration
        @param auditor The auditor who was migrated to the lateset datastore
        @dev when role based permissions are implemented the _sender shall become more meaningful
     */
    event AuditorMigrated( address indexed sender, address indexed auditor );

    /**
        @notice Event tracking whenever an audit is completed by an auditor indicating the contract and the result of that audit
        @param auditor The auditor who completed the audit
        @param _caller The contract that has called the completeAudit function in the platform
        @param contract_ The contract hash that is conventionally used to find the contract
        @param approved Bool indicating whether the auditor has approved or opposed the contract
        @param hash The contract creation hash
     */
    event AuditCompleted( address indexed auditor, address caller, address indexed contract_, bool approved, string indexed hash );
    
    /**
        @notice Event tracking whenever the datastore is being swapped out
        @param owner The current owner of the platform
        @param dataStore Address meant to be a contract that stores information regarding audits
     */
    event ChangedDataStore( address indexed owner, address dataStore );
    
    /**
     * @notice Event tracking when a contract has been destructed
     * @param sender Initiator of the destruction
     * @param contract_ the contract that has been destructed
     */
    event ContractDestructed( address indexed sender, address contract_ );

    /**
        @notice Event confirming that the NFT has been set when deployed
        @param _NFT Intended to be a contract that mints an NFT for the auditor post audit
     */
    event InitializedNFT( address NFT );

    /**
        @notice Event confirming that the datastore has been set when deployed
        @param _dataStore Intended to be a contract that stores the data regarding audits and auditors
     */
    event InitializedDataStore( address dataStore );

    /**
        @notice Event indicating the change of state of the datastore which prevents additive actions
        @param _sender Who initiated the pause
        @param _dataStore Which datastore has been paused
        @dev Just in case the owner can still suspend auditors and when role based permissions are implemented the _sender shall become more meaningful
     */
    event PausedDataStore( address indexed sender, address indexed dataStore );

    /**
        @notice Event indicating the change of state of the datastore which allows functionality to continue
        @param _sender Who unpaused the datastore
        @param _dataStore Which datastore has been unpaused
        @dev When role based permissions are implemented the _sender shall become more meaningful
     */
    event UnpausedDataStore( address indexed sender, address indexed dataStore );

    /**
        @notice Set the NFT to be able to send them to auditors and the datastore that will store the audit data
        @param _NFT The non-fungible token that shall be issued as a receipt to the auditor for their work
        @param _dataStore The storage for the auditors and their audits
        @dev notice Pausable allows us to pause and unpause functionality in case an issue occurs
     */
    constructor( address _NFT, address _dataStore ) Pausable() public {
        NFT = _NFT;
        dataStore = _dataStore;

        emit InitializedNFT( NFT );
        emit InitializedDataStore( dataStore );
    }

    function register( address deployer, address auditor, address creationHash ) external whenNotPaused() {
        IDatastore.register( deployer, auditor, _msgSender(), creationHash );
    }


    /**
        @notice Adds a new entry to the datastore post audit and mints the auditor a receipt NFT
        @param auditor The auditor who performed the audit
        @param _caller The contract that has called the completeAudit function in the platform
        @param approved Bool indicating whether the auditor has approved or opposed the contract
        @param hash The contract creation hash
     */
    function completeAudit( address auditor, address deployer, address contract_, address hash, bool approved ) external whenNotPaused() {  
        // Current design flaw: any auditor can call this instead of the auditor who is auditing the contract
        // TODO: restrict to auditor only by removing auditor and using _msgSender() (outdated TODO)

        IDatastore( dataStore ).completeAudit( auditor, deployer, contract_, hash, approved );

        // Mint a non-fungible token for the auditor as a receipt
        IAuditNFT( NFT ).mint( auditor, contract_, deployer, approved, hash );

        emit AuditCompleted( auditor, _msgSender(), contract_, approved, string( hash ) );
    }

    /**
        @notice Adds a new auditor to the current datastore
        @param auditor The auditor who has been added
     */
    function addAuditor( address auditor ) external onlyOwner() whenNotPaused() {
        IDatastore( dataStore ).addAuditor( auditor );
        emit AuditorAdded( _msgSender(), auditor );
    }

    /**
        @notice Prevents the auditor from performing any audits
        @param auditor The auditor who is suspended
     */
    function suspendAuditor( address auditor ) external onlyOwner() {
        IDatastore( dataStore ).suspendAuditor( auditor );
        emit AuditorSuspended( _msgSender(), auditor );
    }

    /**
        @notice Adds a record of a previously valid audit to the newer datastore
        @param auditor The auditor who is migrated
     */
    function migrateAuditor( address auditor ) external {
        // In the next iteration role based permissions will be implemented
        address _initiator = _msgSender();  // TODO: What if the contract calls with itself as an argument... cannot allow that
        require( _initiator == auditor, "Cannot migrate someone else" );

        // Tell the data store to migrate the auditor
        IDatastore( dataStore ).migrateAuditor( _initiator, auditor );
        emit AuditorMigrated( _initiator, auditor );
    }

    function contractDestructed( address sender ) external {
        // Design flaw: this does not ensure that the contract will be destroyed as a contract may have a function that
        // allows it to call this and falsely set the bool from false to true
        // TODO: Better to make the auditor be the _msgSender() and pass in the contract as a default argument
        
        /**
         * Scenario 1: Contract is honest
         *      Either auditor or deployer init the call and thus this function is called with them as the argument
         *      Everything is OK
         * 
         * Scenario 2: Use this function directly
         *      Implementation should force the destruct() function to call this and thus force the audited contract to call this
         *      However, an unaccounted issue occurs and the auditor wants (or has to) directly call this function instead.
         *      E.g. there is another selfdestruct and the auditor approves the contract but then that other function is used making
         *      our original destruct() function obsolete since the contract is nuked at that point and thus this function could be the
         *      saviour for the auditor ... then again it is their responsibility before they approve to not allow such things?
         *      What about our "clean" store?
         *      Tough shit or do we allow such an event? I want a clean store but also "do not fuck up" (probably more so).
         * 
         * Scenario 3: Dishonest contract
         *      Contract function that differs from destruct() is called which passes in anyone.
         *      If they pass in the auditor or deployer and the contract is not actually destroyed then what?
         *      We do not want to force the destruct() function to be auditor only but that would fix this (assuming vetted + honest auditor)
         */

        IDatastore( dataStore ).contractDestructed( _msgSender(), sender );
        emit ContractDestructed( sender, _msgSender() );
    }

    /**
        @notice Allows the auditor to perform audits again
        @param auditor The auditor who is reinstated
     */
    function reinstateAuditor( address auditor ) external onlyOwner() whenNotPaused() {
        IDatastore( dataStore ).reinstateAuditor( auditor );
        emit AuditorReinstated( _msgSender(), auditor );
    }

    /**
        @notice Blocks functionality that prevents writing of additive data to the store
        @dev You can suspend just in case
     */
    function pauseDataStore() external onlyOwner() {
        IDatastore( dataStore ).pause();
        emit PausedDataStore( _msgSender(), dataStore );
    }

    /**
        @notice Unblocks functionality that prevented writing to the store
     */
    function unpauseDataStore() external onlyOwner() {
        IDatastore( dataStore ).unpause();
        emit UnpausedDataStore( _msgSender(), dataStore );
    }

    /**
        @notice Changes the datastore to a newer version
        @param _dataStore Address meant to be a contract that stores information regarding audits
     */
    function changeDataStore( address _dataStore ) external onlyOwner() {
        // TODO: note regarding permissions
        IDatastore( _dataStore ).linkDataStore( dataStore );
  
        dataStore = _dataStore;
        
        emit ChangedDataStore( _msgSender(), dataStore );
    }
}


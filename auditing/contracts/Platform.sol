// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.4;

import "./Pausable.sol";
import "./IDatastore.sol";


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
        @param _auditor The auditor that has been added
     */
    event AuditorAdded( address indexed owner, address indexed auditor );

    /**
        @notice Event tracking whenever an auditor is suspended and who suspended them, will prevent the auditor from completing future audits
        @param _owner The current owner of the platform
        @param _auditor The auditor who has been blocked for continuing to use the platform to perform audits
     */
    event AuditorSuspended( address indexed owner, address indexed auditor );

    /**
        @notice Event tracking whenever an auditor is reinstated and who reinstated them, will allow the auditor to complete audits again
        @param _owner The current owner of the platform
        @param _auditor The auditor who can complete audits again
     */
    event AuditorReinstated( address indexed owner, address indexed auditor );

    /**
        @notice Event tracking whenever an auditor has migrated themselves to the new datastore
        @param _sender Who initiated the migration
        @param _auditor The auditor who was migrated to the lateset datastore
        @dev when role based permissions are implemented the _sender shall become more meaningful
     */
    event AuditorMigrated( address indexed sender,  address indexed auditor );

    /**
        @notice Event tracking whenever an audit is completed by an auditor indicating the contract and the result of that audit
        @param _auditor The auditor who completed the audit
        @param _caller The contract that has called the completeAudit function in the platform
        @param _contract The contract hash that is conventionally used to find the contract
        @param _approved Bool indicating whether the auditor has approved or opposed the contract
        @param _hash The contract creation hash
     */
    event AuditCompleted( address indexed auditor, address caller, address indexed contract_, bool approved, string indexed hash );
    
    /**
        @notice Event tracking whenever the datastore is being swapped out
        @param _owner The current owner of the platform
        @param _dataStore Address meant to be a contract that stores information regarding audits
     */
    event ChangedDataStore( address indexed owner, address dataStore );

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

    /**
        @notice Adds a new entry to the datastore post audit and mints the auditor a receipt NFT
        @param _auditor The auditor who performed the audit
        @param _caller The contract that has called the completeAudit function in the platform
        @param _approved Bool indicating whether the auditor has approved or opposed the contract
        @param _hash The contract creation hash
     */
    function completeAudit( address _auditor, address _deployer, address _contract, address _hash, bool _approved ) external whenNotPaused() {  
        // Current design flaw: any auditor can call this instead of the auditor who is auditing the contract
        // TODO: restrict to auditor only by removing _auditor and using _msgSender()

        IDatastore( dataStore ).completeAudit( _auditor, _deployer, _contract, _hash, _approved );

        // TODO: add the deployer into the NFT mint
        // Mint a non-fungible token for the auditor as a receipt
        (bool _NFTSuccess, ) = NFT.call(abi.encodeWithSignature("mint(address,address,bool,bytes)", _auditor, _contract, _approved, _hash));
        
        require(_NFTSuccess, "Unknown error with the minting of the Audit NFT");

        emit AuditCompleted(_auditor, _msgSender(), _contract, _approved, string(_hash));
    }

    /**
        @notice Adds a new auditor to the current datastore
        @param _auditor The auditor who has been added
     */
    function addAuditor( address _auditor ) external onlyOwner() whenNotPaused() {
        IDatastore( dataStore ).addAuditor( _auditor );
        emit AuditorAdded(_msgSender(), _auditor);
    }

    /**
        @notice Prevents the auditor from performing any audits
        @param _auditor The auditor who is suspended
     */
    function suspendAuditor( address _auditor ) external onlyOwner() {
        IDatastore( dataStore ).suspendAuditor( _auditor );
        emit AuditorSuspended(_msgSender(), _auditor);
    }

    /**
        @notice Adds a record of a previously valid audit to the newer datastore
        @param _auditor The auditor who is migrated
     */
    function migrateAuditor( address _auditor ) external {
        // In the next iteration role based permissions will be implemented
        address _initiator = _msgSender();
        require(_initiator == _auditor, "Cannot migrate someone else");

        // Tell the data store to migrate the auditor
        IDatastore( dataStore ).migrateAuditor( _initiator, _auditor );
        emit AuditorMigrated(_initiator, _auditor);
    }

    function contractDestructed( address _sender ) external {
        // Design flaw: this does not ensure that the contract will be destroyed as a contract may have a function that
        // allows it to call this and falsely set the bool from false to true
        // TODO: Better to make the auditor be the _msgSender() and pass in the contract as a default argument

        IDatastore( dataStore ).contractDestructed( _msgSender(), _sender );
    }

    /**
        @notice Allows the auditor to perform audits again
        @param _auditor The auditor who is reinstated
     */
    function reinstateAuditor( address _auditor ) external onlyOwner() whenNotPaused() {
        IDatastore( dataStore ).reinstateAuditor( _auditor );
        emit AuditorReinstated(_msgSender(), _auditor);
    }

    /**
        @notice Blocks functionality that prevents writing of additive data to the store
        @dev You can suspend just in case
     */
    function pauseDataStore() external onlyOwner() {
        IDatastore( dataStore ).pause();
        emit PausedDataStore(_msgSender(), dataStore);
    }

    /**
        @notice Unblocks functionality that prevented writing to the store
     */
    function unpauseDataStore() external onlyOwner() {
        IDatastore( dataStore ).unpause();
        emit UnpausedDataStore(_msgSender(), dataStore);
    }

    /**
        @notice Changes the datastore to a newer version
        @param _dataStore Address meant to be a contract that stores information regarding audits
     */
    function changeDataStore( address _dataStore ) external onlyOwner() {
        // TODO: note regarding permissions
        IDatastore( _dataStore ).linkDataStore( dataStore );
  
        dataStore = _dataStore;
        
        emit ChangedDataStore(_msgSender(), dataStore);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.4;

import "./Pausable.sol";
import "./IDatastore.sol";
import "./IAuditable.sol";
import "./IAuditNFT.sol";


contract Platform is Pausable {

    /**
     * @notice The non-fungible token that shall be issued as a receipt to the auditor for their work
     * @dev A new NFT should be issued with each new iteration of the platform
     */ 
    address public NFT;

    /**
     * @notice The contract that acts as a storage center for various bits of data regarding audits
     * @dev The store may be swapped out over time
     */
    address public dataStore;

    /**
     * @notice As new versions are issued the variable will be updated to reflect that
     */
    string public constant version = "Demo: 1";

    /**
     * @notice Event tracking whenever an auditor is added and who added them
     * @param owner The current owner of the platform
     * @param auditor The entity that has been added
     */
    event AuditorAdded( address indexed owner, address indexed auditor );

    /**
     * @notice Event tracking whenever an auditor is suspended and who suspended them, will prevent the auditor from completing future audits
     * @param owner The current owner of the platform
     * @param auditor The entity who has been blocked for continuing to use the platform to perform audits
     */
    event AuditorSuspended( address indexed owner, address indexed auditor );

    /**
     * @notice Event tracking whenever an auditor is reinstated and who reinstated them, will allow the auditor to complete audits again
     * @param owner The current owner of the platform
     * @param auditor The entity who can complete audits again
     */
    event AuditorReinstated( address indexed owner, address indexed auditor );

    /**
     * @notice Event tracking whenever an auditor has migrated themselves to the new datastore
     * @param sender Who initiated the migration
     * @param auditor The entity who was migrated to the latest datastore
     * @dev when role based permissions are implemented the sender shall become more meaningful
     */
    event AuditorMigrated( address indexed sender, address indexed auditor );
    
    /**
     * @notice Event tracking whenever the datastore is swapped out
     * @param owner The current owner of the platform
     * @param dataStore The contract that acts as a storage center for various bits of data regarding audits
     */
    event ChangedDataStore( address indexed owner, address dataStore );

    /**
     * @notice Event confirming that the NFT has been set when deployed
     * @param NFT Intended to be a contract that mints an NFT for the auditor post audit as a receipt
     */
    event InitializedNFT( address NFT );

    /**
     * @notice Event confirming that the datastore has been set when deployed
     * @param dataStore The contract that acts as a storage center for various bits of data regarding audits
     */
    event InitializedDataStore( address dataStore );

    /**
     * @notice Event indicating the change of state of the datastore which prevents additive actions
     * @param sender Who initiated the pause
     * @param dataStore The datastore that has been paused
     * @dev The sender is currently the owner, will become more meaningful when role based permissions are implemented
     */
    event PausedDataStore( address indexed sender, address indexed dataStore );

    /**
     * @notice Event indicating the change of state of the datastore which allows functionality to continue
     * @param sender Who unpaused the datastore
     * @param dataStore The datastore that has been unpaused
     * @dev The sender is currently the owner, will become more meaningful when role based permissions are implemented
     */
    event UnpausedDataStore( address indexed sender, address indexed dataStore );

    /**
     * @notice Event confirming that the contract has been registered in the datastore
     * @param contract_ The contract that has been registered
     * @param deployer The original owner (deployer) of the contract
     */
    event RegisteredContract( address contract_, address deployer );

    /**
     * @notice Event triggered when an auditor confirms the contract details and sets the contract creation hash
     * @param contract_ The contract that has been registered
     * @param deployer The original owner (deployer) of the contract
     * @param creationHash The hash of the first event when a contract is deployed (can be used to check the contract post destruction)
     * @param auditor The entity that can perform audits and has for contract_
     */
    event ConfirmedContractRegistration( address contract_, address deployer, address creationHash, address auditor );

    /**
     * @notice Event triggered when a contract successfully sets an auditor
     * @param contract_ The contract which has an auditor set
     * @param auditor The entity that can perform audits
     */
    event SetContractAuditor( address contract_, address auditor );

    /**
     * @notice Event tracking whenever an audit has been completed and approved by an auditor
     * @param auditor The entity who has completed the audit
     * @param contract_ The contract hash that is conventionally used to find the contract
     */
    event ApprovedAudit( address contract_, address auditor );

    /**
     * @notice Event tracking whenever an audit has been completed and opposed by an auditor
     * @param auditor The entity who has completed the audit
     * @param contract_ The contract hash that is conventionally used to find the contract
     */
    event OpposedAudit( address contract_, address auditor );

    /**
     * @notice Set the NFT to be able to send them to auditors and the datastore that will store the audit data
     * @param _NFT The non-fungible token that shall be issued as a receipt to the auditor for their work
     * @param _dataStore The storage for the auditors and their audits
     * @dev notice Pausable allows us to pause and unpause functionality in case an issue occurs
     */
    constructor( address _NFT, address _dataStore ) Pausable() public {
        NFT = _NFT;
        dataStore = _dataStore;

        emit InitializedNFT( NFT );
        emit InitializedDataStore( dataStore );
    }

    /**
     * @notice A call that is made by a contract which stores preliminary data about the contract in the data store
     * @param deployer The deployer is the original owner of the contract i.e. the one that has deployed it to the blockchain
     */
    function register( address deployer ) external whenNotPaused() {
        IDatastore( dataStore ).register( _msgSender(), deployer );

        emit RegisteredContract( msg.sender, deployer );
    }

    /**
     * @notice A call that is made by a contract which updates its record about the state of the auditor in the data store
     * @param auditor The entity that is performing the audit on the contract
     */
    function setAuditor( address auditor ) external whenNotPaused() {
        IDatastore( dataStore ).setAuditor( _msgSender(), auditor );

        emit SetContractAuditor( msg.sender, auditor );
    }

    /**
     * @notice The auditor should confirm the registration details of the contract before they can audit it
     * @param contract_ The address of the contract that is being audited
     * @param deployer The address of the original owner (deployer) of the contract
     * @param creationHash The hash of the first event when a contract is deployed (can be used to check the contract post destruction)
     */
    function confirmRegistration( address contract_, address deployer, address creationHash ) external whenNotPaused() {
        // TODO: creationHash has to be changed everywhere to use a string...
        IDatastore( dataStore ).confirmRegistration( contract_, deployer, creationHash, _msgSender() );

        emit ConfirmedContractRegistration( contract_, deployer, creationHash, msg.sender );
    }

    /**
     * @notice Create a record detailing which contract has been approved by the auditor
     *         unlock the functionality of said contract and mint an NFT for the auditor
     * @param contract_ The contract that is being audited
     */
    function approveAudit( address contract_ ) external whenNotPaused() {
        IDatastore( dataStore ).approveAudit( contract_, _msgSender() );
        IAuditable( contract_ ).approveAudit( _msgSender() );

        ( _auditor, _deployer, , _creationHash,, _approved, ) = IDatastore( dataStore ).contractDetails( contract_ );
        IAuditNFT( NFT ).mint( _auditor, contract_, _deployer, _approved, _creationHash );

        emit ApprovedAudit( contract_, msg.sender );
    }

    /**
     * @notice Create a record detailing which contract has been opposed by the auditor
     *         permanently lock the functionality of said contract and mint an NFT for the auditor
     * @param contract_ The contract that is being audited
     */
    function opposeAudit( address contract_ ) external whenNotPaused() {
        IDatastore( dataStore ).opposeAudit( contract_, _msgSender() );
        IAuditable( contract_ ).opposeAudit( _msgSender() );

        ( _auditor, _deployer, , _creationHash, _approved, ) = IDatastore( dataStore ).contractDetails( contract_ );
        IAuditNFT( NFT ).mint( _auditor, contract_, _deployer, _approved, _creationHash );

        emit OpposedAudit( contract_, msg.sender );
    }

    /**
     * @notice Adds a new auditor to the current datastore
     * @param auditor The entity which is obtaining the privilege of being able to perform audits
     */
    function addAuditor( address auditor ) external onlyOwner() whenNotPaused() {
        IDatastore( dataStore ).addAuditor( _msgSender(), auditor );
        emit AuditorAdded( msg.sender, auditor );
    }

    /**
     * @notice Prevents the auditor from performing any audits
     * @param auditor The entity which has lost the privilege of being able to perform audits
     */
    function suspendAuditor( address auditor ) external onlyOwner() {
        IDatastore( dataStore ).suspendAuditor( auditor );
        emit AuditorSuspended( msg.sender, auditor );
    }

    /**
     * @notice Adds a record of a previously valid audit to the newer datastore
     */
    function migrateAuditor() external {
        IDatastore( dataStore ).migrateAuditor( _msgSender() );
        emit AuditorMigrated( msg.sender );
    }

    /**
     * @notice Allows the auditor to perform audits again
     * @param auditor The entity which has regained the privilege of being able to perform audits
     */
    function reinstateAuditor( address auditor ) external onlyOwner() whenNotPaused() {
        IDatastore( dataStore ).reinstateAuditor( auditor );
        emit AuditorReinstated( msg.sender, auditor );
    }

    /**
     * @notice Blocks functionality that prevents writing of additive data to the store
     */
    function pauseDataStore() external onlyOwner() {
        IDatastore( dataStore ).pause();
        emit PausedDataStore( msg.sender, dataStore );
    }

    /**
     * @notice Unblocks functionality that prevented writing to the store
     */
    function unpauseDataStore() external onlyOwner() {
        IDatastore( dataStore ).unpause();
        emit UnpausedDataStore( msg.sender, dataStore );
    }

    /**
     * @notice Changes the datastore to a newer version
     * @param _dataStore Address meant to be a contract that stores information regarding audits
     */
    function changeDataStore( address _dataStore ) external onlyOwner() {
        IDatastore( _dataStore ).linkDataStore( _msgSender(), dataStore );
  
        dataStore = _dataStore;
        
        emit ChangedDataStore( msg.sender, dataStore );
    }
}


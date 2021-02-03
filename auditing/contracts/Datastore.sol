// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.4;

import "./Pausable.sol";
import "./ContractStore.sol";
import "./AuditorStore.sol";
import "./DeployerStore.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Datastore is ContractStore, AuditorStore, DeployerStore, Pausable {
    
    using SafeMath for uint256;

    // Daisy chain the data stores backwards to allow recursive backwards search.
    address public previousDatastore;

    string constant public version = "Demo: 1";
    
    bool public activeStore = true;

    event AddedAuditor( 
        address indexed platformOwner, 
        address indexed platform, 
        address indexed auditor
    );
    
    event SuspendedAuditor( 
        address indexed platformOwner, 
        address indexed platform, 
        address indexed auditor
    );
    
    event ReinstatedAuditor( 
        address indexed platformOwner, 
        address indexed platform, 
        address indexed auditor
    );

    event RegisteredContract(
        address indexed contract_, 
        address indexed deployer
    );
    
    event SetAuditor(
        address indexed contract_, 
        address indexed auditor 
    );
    
    event ConfirmedRegistration(
        address indexed contract_, 
        address indexed deployer, 
        address         creationHash, 
        address indexed auditor
    );
    
    event ApprovedAudit( 
        address indexed platform, 
        address indexed contract_, 
        address indexed auditor
    );
    
    event OpposedAudit(
        address indexed platform, 
        address indexed contract_, 
        address indexed auditor
    );

    // Daisy chain stores
    event LinkedDataStore(
        address indexed platformOwner,
        address indexed platform,
        address indexed previousDataStore
    );

    // TODO: contracts being stored by index will cause a problem when migrating to a new store because the index
    //       will reset back to 1 therefore contract behavior must be expanded upon to indicate which absolute contract
    //       addition it is while maintaining the searchable index
    //       (problem is that the index is stored and so different store versions will eventually result in collisions for the auditor arrays)
    //       using the absolute value makes no sense because you are forced to recurse from the start to the required store
    //       dirty quick solution is via structs holding the index and which store it is from

    /**
     * TODO: currently the sub stores are tightly coupled with this front facing datastore, expand on the architecture to allow hotswapping
     *       of the other stores
     */
    

    constructor() Pausable() public {}

    /**
     * @notice Check in the CURRENT (auditor) data store if the address representing the auditor has ever been added
     * @param auditor The entity that is/was deemed as someone able to perform audits
     * @dev The check is for the record ever being added and not whether the auditor address is currently a valid auditor
     * @return Boolean value indicating if this address has ever been added as an auditor
     */
    function hasAuditorRecord( address auditor ) external view returns ( bool ) {
        return _hasAuditorRecord( auditor );
    }

    /**
     * @notice Check in the CURRENT (auditor) data store if the address representing the auditor is currently a valid auditor
     * @param auditor The entity that is/was deemed as someone able to perform audits
     * @dev This will return false in both cases where an auditor is suspended or has never been added to this store
     *      because of the nuance this should be used with caution or with hasAuditorRecord()
     * @return Boolean value indicating if this address is currently a valid auditor
     */
    function isAuditor( address auditor ) external view returns ( bool ) {
        return _isAuditor( auditor );
    }

    function searchAllStoresForIsAuditor( address auditor ) external view returns ( bool ) {
        // Check in all previous stores if the latest record of them being an auditor is set to true/false
        // This is likely to be expensive so it is better to check each store manually / individually
        return _recursiveIsAuditorSearch( auditor, previousDatastore );
    }

    /**
     * @notice Check in the CURRENT (auditor) data store the information stored about the address representing an auditor
     * @param auditor The entity that is/was deemed as someone able to perform audits
     * @dev We return the lengths of the approved & opposed contract arrays because of limitations in solidity with looping, you must
     *      use the length of each array to call the appropriate functions to return the specific information regarding each contract
     * @return The current state of the auditor and the total number of approved contracts and the total number of opposed contracts
     */
    function getAuditorInformation( address auditor ) external view returns ( bool, uint256, uint256 ) {
        return _getAuditorInformation( auditor );
    }

    /**
     * @notice Check in the CURRENT (auditor) data store the information regarding an approved contract
     * @param auditor The entity that is/was deemed as someone able to perform audits
     * @param contractIndex A number which should be less than or equal to the total number of approved contracts for the auditor
     * @return The audited contract information
     */
    function getAuditorApprovedContractInformation( address auditor, uint256 contractIndex ) external view returns ( address, address, address, address, bool, bool, bool ) {
        uint256 contractIndex = _getAuditorApprovedContractIndex( auditor, contractIndex );
        return _getContractInformation( contractIndex );
    }

    /**
     * @notice Check in the CURRENT (auditor) data store the information regarding an opposed contract
     * @param auditor The entity that is/was deemed as someone able to perform audits
     * @param contractIndex A number which should be less than or equal to the total number of opposed contracts for the auditor
     * @return The audited contract information
     */
    function getAuditorOpposedContractInformation( address auditor, uint256 contractIndex ) external view returns ( address, address, address, address, bool, bool, bool ) {
        uint256 contractIndex = _getAuditorOpposedContractIndex( auditor, contractIndex );
        return _getContractInformation( contractIndex );
    }

    /**
     * @notice Check in the current data store if the contractHash address has been added
     * @param contractHash The address, intented to be a contract
     * @dev There are two hash values, contract creation transaction and the actual contract hash, this is the contract hash
     * @return Boolean value indicating if this address has been addede to the store
     */
    function hasContractRecord( address contractHash ) external view returns ( bool ) {
        return _hasContractRecord( contractHash );
    }

    /**
     * @notice Check in the current data store if the creationHash address has been added
     * @param creationHash The address, intented to be a contract
     * @dev There are two hash values, contract creation transaction and the actual contract hash, this is the creation hash
     * @return Boolean value indicating if this address has been addede to the store
     */
    function hasContractCreationRecord( address creationHash ) external view returns ( bool ) {
        return _hasCreationRecord( creationHash );
    }

    /**
     * @notice Check the contract details using the contract_ address
     * @param contract_ Either the hash used to search for the contract or the transaction hash indicating the creation of the contract
     * @return The data stored regarding the contract audit
     */
    function getContractInformation( address contract_ ) external view returns ( address, address, address, address, bool, bool, bool ) {
        return _getContractInformation( contract_ );
    }

    function searchAllStoresForContractDetails( address contract_ ) external view returns ( address, address, address, address, bool, bool ) {
        // Check in all previous stores if this contract has been recorded
        // This is likely to be expensive so it is better to check each store manually / individually
        return _contractDetailsRecursiveSearch( contract_, previousDatastore );
    }

    /**
     * @notice Check in the current data store if the deployer address has ever been added
     * @param deployer The address, intented to be a wallet (but may be a contract), which represents a deployer
     * @return Boolean value indicating if this address has been added to the current store
     */
    function hasDeployerRecord( address deployer ) external view returns ( bool ) {
        return _hasDeployerRecord( deployer );
    }

    /**
     * @notice Check the details on the deployer in this current data store
     * @param deployer The address, intented to be a wallet (but may be a contract), which represents a deployer
     * @dev Looping is a future problem therefore tell them the length and they can use the index to fetch the contract
     * @return The number of approved contracts and the total number of opposed contracts
     */
    function getDeployerInformation( address deployer ) external view returns ( bool, uint256, uint256 ) {
        _getDeployerInformation( deployer );
    }

    /**
     * @notice Add an auditor to the data store
     * @param sender the owner of the platform
     * @param auditor The entity that is/was deemed as someone able to perform audits
     * @dev Used to add a new address therefore should be used once per address. Intented as the initial save
     */
    function addAuditor( address platformOwner, address auditor ) external onlyOwner() whenNotPaused() {
        require( activeStore, "Store has been deactivated" );
        _addAuditor( platformOwner, _msgSender(), auditor );
        emit AddedAuditor( platformOwner, msg.sender, auditor );
    }

    /**
     * @notice Revoke permissions from the auditor
     * @param platformOwner the owner of the platform
     * @param auditor The entity that is/was deemed as someone able to perform audits
     * @dev After an auditor has been added one may decide that they are no longer fit and thus deactivate their audit writing permissions.
     *      Note that we are disabling them in the current store which prevents actions in the future stores therefore we never go back and change
     *      previous stores on the auditor
     */
    function suspendAuditor( address platformOwner, address auditor ) external onlyOwner() {
        require( activeStore, "Store has been deactivated" );
        _suspendAuditor( platformOwner, _msgSender(), auditor );
        emit SuspendedAuditor( platformOwner, msg.sender, auditor );
    }

    /**
     * @notice Reinstate the permissions for the auditor that is currently suspended
     * @param platformOwner the owner of the platform
     * @param auditor The entity that is/was deemed as someone able to perform audits
     * @dev Similar to the addition of the auditor but instead flip the isAuditor boolean back to true
     */
    function reinstateAuditor( address platformOwner, address auditor ) external onlyOwner() whenNotPaused() {
        require( activeStore, "Store has been deactivated" );
        _reinstateAuditor( platformOwner, _msgSender(), auditor );
        emit ReinstatedAuditor( platformOwner, msg.sender, auditor );
    }

    function migrateAuditor( address migrator, address auditor ) external onlyOwner() {
        _migrate( migrator, auditor );
    }

    function register( address contract_, address deployer ) external onlyOwner() whenNotPaused() {
        require( activeStore, "Store has been deactivated" );
        
        uint256 size;
        assembly { size:= extcodesize( contract_ ) }
        require( size > 0,  "Contract argument is not a valid contract address" );
        
        _registerContract( _msgSender(), contract_, deployer );
        _addDeployer( _msgSender(), deployer );

        emit RegisteredContract( contract_, deployer );
    }

    function setAuditor( address contract_, address auditor ) external onlyOwner() whenNotPaused() {
        require( activeStore, "Store has been deactivated" );

        ( , , , , audited, , ) = _getContractInformation( contract_ );

        require( !audited, "Cannot make changes post audit" );

        // Must be a valid auditor in the current store to be able to write to the current store
        require( _hasAuditorRecord( auditor ),  "No auditor record in the current store" );
        require( _isAuditor( auditor ),         "Auditor has been suspended" );

        _setContractAuditor( _msgSender(), contract_, auditor );

        emit SetAuditor( contract_, auditor );
    }

    function confirmRegistration( address contract_, address deployer, address creationHash, address auditor ) external onlyOwner() whenNotPaused() {
        require( activeStore, "Store has been deactivated" );

        ( auditor_, deployer_, , , audited, , ) = _getContractInformation( contract_ );

        require( !audited,                      "Cannot make changes post audit" );

        // Must be a valid auditor in the current store to be able to write to the current store
        require( _hasAuditorRecord( auditor ),  "No auditor record in the current store" );
        require( _isAuditor( auditor ),         "Auditor has been suspended" );

        require( auditor_ == auditor,           "The auditor attempting to confirm the hash is not the same as the auditor of the contract" );
        require( deployer_ == deployer,         "Deployers do not match in the store" );

        _setContractCreationHash( _msgSender(), contract_, creationHash );

        emit ConfirmedRegistration( contract_, deployer, creationHash, auditor );
    }

    /**
     * @notice Write a new approved audit into the data store
     * @param contract_ The hash used to search for the contract
     * @param auditor The entity that is/was deemed as someone able to perform audits
     */
    function approveAudit( address contract_, address auditor ) external onlyOwner() whenNotPaused() {
        require( activeStore, "Store has been deactivated" );

        ( auditor_, , , , audited, , confirmedHash ) = _getContractInformation( contract_ );

        require( !audited,                      "Cannot make changes post audit" );

        // Must be a valid auditor in the current store to be able to write to the current store
        require( _hasAuditorRecord( auditor ),  "No auditor record in the current store" );
        require( _isAuditor( auditor ),         "Auditor has been suspended" );
        require( auditor_ == auditor,           "The auditor attempting to approve the audit is not the same as the auditor of the contract" );
        require( confirmedHash,                 "The auditor must confirm the creation hash first" );

        // There is only 1 line which is different and that is because it is not the job of the platform (the API) to decide which state
        // is passed to the store
        bool approved = true;
        uint256 contractIndex = _getContractIndex( contract_ );

        _setContractApproval( _msgSender(), contract_, approved );

        _saveContractIndexForAuditor( _msgSender(), auditor, approved, contractIndex );
        _saveContractIndexForDeplyer( _msgSender(), deployer, approved, contractIndex );

        emit ApprovedAudit( msg.sender, contract_, auditor );
    }

    /**
     * @notice Write a new approved audit into the data store
     * @param contract_ The hash used to search for the contract
     * @param auditor The entity that is/was deemed as someone able to perform audits
     */
    function opposeAudit( address contract_, address auditor ) external onlyOwner() whenNotPaused() {
        require( activeStore, "Store has been deactivated" );

        ( auditor_, , , , audited, , confirmedHash ) = _getContractInformation( contract_ );

        require( !audited,                      "Cannot make changes post audit" );

        // Must be a valid auditor in the current store to be able to write to the current store
        require( _hasAuditorRecord( auditor ),  "No auditor record in the current store" );
        require( _isAuditor( auditor ),         "Auditor has been suspended" );
        require( auditor_ == auditor,           "The auditor attempting to approve the audit is not the same as the auditor of the contract" );
        require( confirmedHash,                 "The auditor must confirm the creation hash first" );

        // There is only 1 line which is different and that is because it is not the job of the platform (the API) to decide which state
        // is passed to the store
        bool approved = false;
        uint256 contractIndex = _getContractIndex( contract_ );

        _setContractApproval( _msgSender(), contract_, approved );

        _saveContractIndexForAuditor( _msgSender(), auditor, approved, contractIndex );
        _saveContractIndexForDeplyer( _msgSender(), deployer, approved, contractIndex );

        emit OpposedAudit( msg.sender, contract_, auditor );
    }

    function linkDataStore( address platformOwner, address datastore ) external onlyOwner() {
        require( activeStore, "Store has been deactivated" );
        
        activeStore = false;
        previousDatastore = datastore;

        emit LinkedDataStore( platformOwner, _msgSender(), previousDatastore );
    }
}


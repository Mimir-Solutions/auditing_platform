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

    // Completed audits
    event CompletedAudit( address indexed auditor, address indexed deployer, address contract_, address hash, bool indexed approved, uint256 contractIndex );

    // Daisy chain stores
    event LinkedDataStore( address indexed _owner, address indexed datastore );
    
    constructor() Pausable() public {}

    /**
        @notice Check in the current data store if the auditor address has ever been added
        @param auditor The address, intented to be a wallet, which represents an auditor
        @dev The check is for the record ever being added and not whether the auditor address is currently a valid auditor
        @return Boolean value indicating if this address has ever been added as an auditor
     */
    function hasAuditorRecord( address auditor ) external view returns ( bool ) {
        return _hasAuditorRecord( auditor );
    }

    /**
        @notice Check if the auditor address is currently a valid auditor in this data store
        @param auditor The address, intented to be a wallet, which represents an auditor
        @dev This will return false in both occasions where an auditor is suspended or has never been added to this store
        @return Boolean value indicating if this address is currently a valid auditor
     */
    function isAuditor( address auditor ) external view returns ( bool ) {
        // Ambigious private call, call with caution or use with hasAuditorRecord()
        return _isAuditor( auditor );
    }

    function searchAllStoresForIsAuditor( address auditor ) external view returns ( bool ) {
        // Check in all previous stores if the latest record of them being an auditor is set to true/false
        // This is likely to be expensive so it is better to check each store manually / individually
        return _recursiveIsAuditorSearch( auditor, previousDatastore );
    }

    /**
        @notice Check the details on the auditor in this current data store
        @param auditor The address, intented to be a wallet, which represents an auditor
        @dev Looping is a future problem therefore tell them the length and they can use the index to fetch the contract
        @return The current state of the auditor and the total number of approved contracts and the total number of opposed contracts
     */
    function auditorDetails( address auditor ) external view returns ( bool, uint256, uint256 ) {
        return _auditorDetails( auditor );
    }

    /**
        @notice Check the approved contract information for an auditor
        @param auditor The address, intented to be a wallet, which represents an auditor
        @param index A number which should be less than or equal to the total number of approved contracts for the auditor
        @return The audited contract information
     */
    function auditorApprovedContract( address auditor, uint256 index ) external view returns ( address, address, address, address, bool, bool ) {
        uint256 contractIndex = _auditorApprovedContract( auditor, index );
        return _contractDetails( contractIndex );
    }

    /**
        @notice Check the opposed contract information for an auditor
        @param auditor The address, intented to be a wallet, which represents an auditor
        @param index A number which should be less than or equal to the total number of opposed contracts for the auditor
        @return The audited contract information
     */
    function auditorOpposedContract( address auditor, uint256 index ) external view returns ( address, address, address, address, bool, bool ) {
        uint256 contractIndex = _auditorOpposedContract( auditor, index );
        return _contractDetails( contractIndex );
    }

    /**
        @notice Check in the current data store if the contractHash address has been added
        @param contractHash The address, intented to be a contract
        @dev There are two hash values, contract creation transaction and the actual contract hash, this is the contract hash
        @return Boolean value indicating if this address has been addede to the store
     */
    function hasContractRecord( address contractHash ) external view returns ( bool ) {
        return _hasContractRecord( contractHash );
    }

    /**
        @notice Check in the current data store if the creationHash address has been added
        @param creationHash The address, intented to be a contract
        @dev There are two hash values, contract creation transaction and the actual contract hash, this is the creation hash
        @return Boolean value indicating if this address has been addede to the store
     */
    function hasContractCreationRecord( address creationHash ) external view returns ( bool ) {
        return _hasCreationRecord( creationHash );
    }

    /**
        @notice Check the contract details using the contract_ address
        @param contract_ Either the hash used to search for the contract or the transaction hash indicating the creation of the contract
        @return The data stored regarding the contract audit
     */
    function contractDetails( address contract_ ) external view returns ( address, address, address, address, bool, bool ) {
        return _contractDetails( contract_ );
    }

    function searchAllStoresForContractDetails( address contract_ ) external view returns ( address, address, address, address, bool, bool ) {
        // Check in all previous stores if this contract has been recorded
        // This is likely to be expensive so it is better to check each store manually / individually
        return _contractDetailsRecursiveSearch( contract_, previousDatastore );
    }

    function contractDestructed( address contract_, address initiator ) external onlyOwner() {
        _contractDestructed( contract_, initiator );
    }

    /**
        @notice Check in the current data store if the deployer address has ever been added
        @param deployer The address, intented to be a wallet (but may be a contract), which represents a deployer
        @return Boolean value indicating if this address has been added to the current store
     */
    function hasDeployerRecord( address deployer ) external view returns ( bool ) {
        return _hasDeployerRecord( deployer );
    }

    /**
        @notice Check the details on the deployer in this current data store
        @param deployer The address, intented to be a wallet (but may be a contract), which represents a deployer
        @dev Looping is a future problem therefore tell them the length and they can use the index to fetch the contract
        @return The number of approved contracts and the total number of opposed contracts
     */
    function deployerDetails( address deployer ) external view returns ( bool, uint256, uint256 ) {
        _deployerDetails( deployer );
    }

    /**
        @notice Add an auditor to the data store
        @param auditor The address, intented to be a wallet, which represents an auditor
        @dev Used to add a new address therefore should be used once per address. Intented as the initial save
     */
    function addAuditor( address auditor ) external onlyOwner() whenNotPaused() {
        require( activeStore, "Store has been deactivated" );
        _addAuditor( auditor );
    }

    /**
        @notice Revoke permissions from the auditor
        @param auditor The address, intented to be a wallet, which represents an auditor
        @dev After an auditor has been added one may decide that they are no longer fit and thus deactivate their audit writing permissions.
        Note that we are disabling them in the current store which prevents actions in the future stores therefore we never go back and change
        previous stores on the auditor
     */
    function suspendAuditor( address auditor ) external onlyOwner() {
        require( activeStore, "Store has been deactivated" );
        _suspendAuditor( auditor );
    }

    /**
        @notice Reinstate the permissions for the auditor that is currently suspended
        @param auditor The address, intented to be a wallet, which represents an auditor
        @dev Similar to the addition of the auditor but instead flip the isAuditor boolean back to true
     */
    function reinstateAuditor( address auditor ) external onlyOwner() whenNotPaused() {
        require( activeStore, "Store has been deactivated" );
        _reinstateAuditor( auditor );
    }

    function migrateAuditor( address migrator, address auditor ) external onlyOwner() {
        _migrate( migrator, auditor );
    }

    /**
        @notice Write a new completed audit into the data store
        @param auditor The address, intented to be a wallet, which represents an auditor
        @param deployer The address, intented to be a wallet (but may be a contract), which represents a deployer
        @param contract_ The hash used to search for the contract
        @param approved Boolean indicating whether the contract has passed or failed the audit
        @param txHash The hash depicting the transaction which created the contract
     */
    function completeAudit( address auditor, address deployer, address contract_, address txHash, bool approved ) external onlyOwner() whenNotPaused() {
        require( activeStore, "Store has been deactivated" );

        // Must be a valid auditor in the current store to be able to write to the current store
        require( _hasAuditorRecord( auditor ),  "No auditor record in the current store" );
        require( _isAuditor( auditor ),         "Auditor has been suspended" );

        uint256 contractIndex = _saveContract( auditor, contract_, deployer, txHash, approved );

        _addDeployer( deployer );

        _saveContractIndexForAuditor( auditor, approved, contractIndex );
        _saveContractIndexForDeplyer( deployer, approved, contractIndex );

        emit CompletedAudit( auditor, deployer, contract_, txHash, approved, contractIndex );
    }

    function linkDataStore( address datastore ) external onlyOwner() {
        require( activeStore, "Store has been deactivated" );
        
        activeStore = false;
        previousDatastore = datastore;

        emit LinkedDataStore( _msgSender(), previousDatastore );
    }
}


// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.1;

import "./SafeMath.sol";
import "./IDatastore.sol";
import "./Ownable.sol";

contract ContractStore {
    
    using SafeMath for uint256;

    uint256 public registeredContractCount;
    uint256 public approvedContractCount;
    uint256 public opposedContractCount;

    address previousContractStore;

    Contract[] private contracts;

    struct Contract {
        address auditor;
        address deployer;
        address contractHash;
        address creationHash;
        bool    audited;
        bool    approved;
        bool    confirmedHash;
    }

    // Note for later, 0th index is used to check if it already exists
    mapping( address => uint256 ) private contractHash;
    mapping( address => uint256 ) private contractCreationHash;

    event NewContractRecord(
        address         platform,
        address         dataStore,
        address indexed contract_, 
        address indexed deployer, 
        uint256         contractIndex
    );

    event SetContractAuditor( 
        address         platform,
        address         dataStore,
        address indexed contract_, 
        address indexed auditor
    );

    event SetContractCreationHash( 
        address         platform,
        address         dataStore,
        address indexed contract_, 
        address indexed creationHash
    );

    event SetContractApproval(
        address         platform,
        address         dataStore,
        address indexed contract_,
        address indexed auditor, 
        bool    indexed approved
    );
    
    event LinkedContractStore();

    constructor() public Ownable() {}

    function registerContract( address platform, address contract_, address deployer ) external onlyOwner() {
        require( !_hasContractRecord( contract_ ), "Contract has already been registered" );

        // Create a single struct for the contract data and then reference it via indexing instead of managing mulitple storage locations
        Contract memory _contractData = Contract({
            deployer:       deployer,
            contractHash:   contract_
        });

        // Start adding from the next position and thus have an empty 0th default value which indicates an error to the user
        contracts[ contracts.length++ ] = _contractData;
        uint256 contractIndex = contracts.length;

        // Add to mapping for easy lookup, note that 0th index will also be default which allows us to do some safety checks
        contractHash[ contract_ ] = contractIndex;

        registeredContractCount = registeredContractCount.add( 1 );

        emit NewContractRecord( platform, msg.sender, contract_, deployer, contractIndex );
    }

    function _setContractAuditor( address platform, address contract_, address auditor ) external onlyOwner() {
        uint256 contractIndex = _getContractIndex( contract_ );

        contracts[ contractIndex ].auditor = auditor;
        contracts[ contractIndex ].confirmedHash = false;

        emit SetContractAuditor( platform, msg.sender, contract_, auditor );
    }

    function _setContractCreationHash( address platform, address contract_, address creationHash ) external onlyOwner() {
        require( !_hasCreationRecord( creationHash ), "Contract exists in the contract creation hash mapping" );
        
        uint256 contractIndex = _getContractIndex( contract_ );
        contractCreationHash[ creationHash ] = contractIndex;
        
        contracts[ contractIndex ].creationHash = creationHash;
        contracts[ contractIndex ].confirmedHash = true;

        emit SetContractCreationHash( platform, msg.sender, contract_, creationHash );
    }

    function _setContractApproval( address platform, address contract_, bool approved ) external onlyOwner() {
        uint256 contractIndex = _getContractIndex( contract_ );

        require( !contracts[ contractIndex ].audited, "Cannot change audit state post audit" );

        contracts[ contractIndex ].audited = true;
        contracts[ contractIndex ].approved = approved;

        if ( approved ) {
            approvedContractCount = approvedContractCount.add( 1 );
        } else {
            opposedContractCount = opposedContractCount.add( 1 );
        }

        emit SetContractApproval( platform, msg.sender, contract_, contracts[ contractIndex ].auditor, approved );
    }

    function _hasContractRecord( address contractHash ) external onlyOwner() view returns ( bool ) {
        return contractHash[ contractHash ] != 0;
    }

    function _hasCreationRecord( address creationHash ) external onlyOwner() view returns ( bool ) {
        return contractCreationHash[ creationHash ] != 0;
    }

    function _contractDetailsRecursiveSearch( address contract_, address previousDataStore ) external onlyOwner() view returns 
    (
        address auditor,
        address deployer, 
        address contractHash,
        address creationHash,  
        bool    audited, 
        bool    approved
    ) {
        // Check in all previous stores if this contract has been recorded
        // This is likely to be expensive so it is better to check each store manually / individually

        uint256 contractIndex;

        if ( _hasContractRecord( contract_ ) ) {
            contractIndex = contractHash[ contract_ ];
        }

        if ( contractIndex != 0 ) {
            auditor       = contracts[ contractIndex ].auditor;
            deployer      = contracts[ contractIndex ].deployer;
            contractHash  = contracts[ contractIndex ].contractHash;
            creationHash  = contracts[ contractIndex ].creationHash;
            audited       = contracts[ contractIndex ].audited;
            approved      = contracts[ contractIndex ].approved;
        } else if ( previousDataStore != address( 0 ) ) {
            ( auditor, deployer, contractHash, creationHash, audited, approved ) = IDatastore( previousDatastore ).searchAllStoresForContractDetails( contract_ );
        } else {
            revert( "No contract record in any data store" );
        }
    }

    /**
     * @notice 
     * @param contract_ The address of the contract that has been audited
     * @return All of the struct stored information about a given contract
     */
    function _getContractInformation( address contract_ ) external onlyOwner() view returns ( address, address, address, address, bool, bool, bool ) {
        require( 0 < contracts.length,      "No contracts have been added" );
        uint256 contractIndex = _getContractIndex( contract_ );
        require( contractIndex <= contracts.length, "Record does not exist" );

        return _getContractInformationByIndex( contractIndex );
    }

    /**
     * @notice 
     * @param contractIndex A number referencing the storage location of the contract information
     * @return All of the struct stored information about a given contract
     */
    function _getContractInformation( uint256 contractIndex ) external onlyOwner() view returns ( address, address, address, address, bool, bool, bool ) {
        require( 0 < contracts.length,      "No contracts have been added" );        
        require( contractIndex <= contracts.length, "Record does not exist" );

        return _getContractInformationByIndex( contractIndex );
    }

    /**
     * @notice 
     * @param contractIndex A positive number which should be less than or equal to the total number of contracts
     * @dev Inherently unbounded and unsafe call that is meant to be used in _getContractInformation() which performs the required validation. "DRY".
     * @return All of the struct stored information about a given contract
     */
    function _getContractInformationByIndex( uint256 contractIndex ) private view returns ( address, address, address, address, bool, bool, bool ) {
        return 
        (
            contracts[ contractIndex ].auditor,
            contracts[ contractIndex ].deployer,
            contracts[ contractIndex ].contractHash,
            contracts[ contractIndex ].creationHash,
            contracts[ contractIndex ].audited,
            contracts[ contractIndex ].approved,
            contracts[ contractIndex ].confirmedHash,
        );
    }

    function _getContractIndex( address contract_ ) private view returns ( uint256 contractIndex ) {
        contractIndex = contractHash[ contract_ ];

        require( contractIndex != 0, "Contract has not been added" );
    }
    
    function linkContractStore( address contractStore ) external onlyOwner() {
        previousContractStore = contractStore;
    }

}







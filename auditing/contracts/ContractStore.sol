// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.4;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IDatastore.sol";

contract ContractStore {
    
    using SafeMath for uint256;

    uint256 public approvedContractCount;
    uint256 public opposedContractCount;

    Contract[] private contracts;

    struct Contract {
        address auditor;
        address deployer;
        address contractHash;
        address creationHash;
        bool    approved;
        bool    destructed;
    }

    // Note for later, 0th index is used to check if it already exists
    mapping( address => uint256 ) private contractHash;
    mapping( address => uint256 ) private contractCreationHash;

    event NewContractRecord(
        address indexed auditor, 
        address indexed deployer, 
        address         contract_, 
        address         hash, 
        uint256         contractIndex
    );

    event ContractDestructed( address indexed sender, address contract_ );
    event CompletedAudit( address indexed contract_, address indexed auditor, bool indexed approved );

    constructor() internal {}

    function _saveContract( address auditor, address deployer, address contract_, address hash ) internal returns ( uint256 ) {
        require( !_hasContractRecord( contract_ ),  "Contract exists in the contracts mapping" );
        require( !_hasCreationRecord( hash ),       "Contract exists in the contract creation hash mapping" );

        // Create a single struct for the contract data and then reference it via indexing instead of managing mulitple storage locations
        // TODO: can I omit the destructed argument since the default bool is false?        
        Contract memory _contractData = Contract({
            auditor:        auditor,
            deployer:       deployer,
            contractHash:   contract_,
            creationHash:   hash
        });

        // Start adding from the next position and thus have an empty 0th default value which indicates an error to the user
        uint256 contractCount = contracts.length;
        contracts[ contractCount++ ] = _contractData;
        uint256 contractIndex_ = contracts.length;

        // Add to mapping for easy lookup, note that 0th index will also be default which allows us to do some safety checks
        contractHash[ contract_ ] = contractIndex_;
        contractCreationHash[ hash ] = contractIndex_;

        emit NewContractRecord( auditor, deployer, contract_, hash, contractIndex_ );
        return contractIndex_;
    }
    
    function completeAudit( address contract_, address auditor, bool approved ) internal {
        uint256 index = _contractIndex( contract_ );

        require( contracts[ index ].auditor == auditor,   "Action restricted to contract Auditor" );
        require( !contracts[ index ].destructed,          "Contract already marked as destructed" );
        
        contracts[ index ].approved = approved;
        
        if ( approved ) {
            approvedContractCount = approvedContractCount.add( 1 );
        } else {
            opposedContractCount = opposedContractCount.add( 1 );
        }
        
        emit CompletedAudit( contract_, auditor, approved );
    }
        
    }

    function _contractDestructed( address contract_, address initiator ) internal {
        uint256 index = _contractIndex( contract_ );

        require( contracts[ index ].auditor == initiator || contracts[ index ].deployer == initiator,   "Action restricted to contract Auditor or Deployer" );
        require( !contracts[ index ].destructed,                                                        "Contract already marked as destructed" );

        contracts[ index ].destructed = true;

        emit ContractDestructed( initiator, contract_ );
    }

    function _hasContractRecord( address contractHash_ ) internal view returns ( bool ) {
        return contractHash[ contractHash_ ] != 0;
    }

    function _hasCreationRecord( address creationHash ) internal view returns ( bool ) {
        return contractCreationHash[ creationHash ] != 0;
    }

    function _contractDetailsRecursiveSearch( address contract_, address previousDataStore ) internal view returns 
    (
        address auditor,
        address deployer, 
        address contractHash_,
        address creationHash,  
        bool    approved, 
        bool    destructed
    ) {
        // Check in all previous stores if this contract has been recorded
        // This is likely to be expensive so it is better to check each store manually / individually

        uint256 index;

        if ( _hasContractRecord( contract_ ) ) {
            index = contractHash[ contract_ ];
        } else if ( _hasCreationRecord( contract_ ) ) {
            index = contractCreationHash[ contract_ ];
        }

        if ( index != 0 ) {
            auditor       = contracts[ index ].auditor;
            deployer      = contracts[ index ].deployer;
            contractHash_ = contracts[ index ].contractHash;
            creationHash  = contracts[ index ].creationHash;
            approved      = contracts[ index ].approved;
            destructed    = contracts[ index ].destructed;
        } else if ( previousDataStore != address( 0 ) ) {
            ( auditor, deployer, contractHash_, creationHash, approved, destructed ) = IDatastore( previousDatastore ).searchAllStoresForContractDetails( contract_ );
        } else {
            revert( "No contract record in any data store" );
        }
    }

    function _contractDetails( address contract_ ) internal view returns ( address, address, address, address, bool, bool ) {
        require( 0 < contracts.length,      "No contracts have been added" );
        uint256 index = _contractIndex( contract_ );
        require( index <= contracts.length, "Record does not exist" );

        return 
        (
            contracts[ index ].auditor,
            contracts[ index ].deployer,
            contracts[ index ].contractHash,
            contracts[ index ].creationHash,
            contracts[ index ].approved,
            contracts[ index ].destructed
        );
    }

    function _contractIndex( address contract_ ) private view returns ( uint256 index ) {
        index = contractHash[ contract_ ];

        if ( index == 0 ) {
            index = contractCreationHash[ contract_ ];
        }

        require( index != 0, "Contract has not been added" );
    }

}






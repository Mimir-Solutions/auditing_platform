// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.1;

interface IContractStore {

    function registerContract( address platform, address contract_, address deployer ) external;
    
    function setContractAuditor( address platform, address contract_, address auditor ) external;
    
    function setContractCreationHash( address platform, address contract_, address creationHash ) external;
    
    function setContractApproval( address platform, address contract_, bool approved ) external;
    
    function hasContractRecord( address contractHash ) external view returns ( bool );
    
    function hasCreationRecord( address creationHash ) external view returns ( bool );
    
    function contractDetailsRecursiveSearch( address contract_, address previousDataStore ) external view returns ( address, address, address, address, bool, bool );
    
    function getContractInformation( address contract_ ) external view returns ( address, address, address, address, bool, bool, bool );
    
    function getContractInformation( uint256 contractIndex ) external view returns ( address, address, address, address, bool, bool, bool );
    
    function linkContractStore( address contractStore ) external;
    
}

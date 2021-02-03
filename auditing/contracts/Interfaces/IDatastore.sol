// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.4;

interface IDatastore {

    // function completeAudit( address auditor, address deployer, address contract_, address txHash, bool approved ) external;
    
    function register( address contract_, address auditor, address deployer, address creationHash ) external;

    function setAuditor( address contract_, address auditor ) external;

    function confirmRegistration( address contract_, address deployer, address creationHash, address auditor ) external;

    function approveAudit( address contract_, address auditor ) external;

    function opposeAudit( address contract_, address auditor ) external;

    function getContractInformation( address contract_ ) external returns ( address, address, address, address, bool, bool );
    
    function addAuditor( address platformOwner, address auditor ) external;
    
    function suspendAuditor( address platformOwner, address auditor ) external;
    
    function migrateAuditor( address auditor ) external;
        
    function reinstateAuditor( address platformOwner, address auditor ) external;
    
    function pauseDataStore() external;
    
    function unpauseDataStore() external;
    
    function linkDataStore( address platformOwner, address dataStore ) external;
    
    function searchAllStoresForIsAuditor( address auditor ) external view returns ( bool );
    
    function searchAllStoresForContractDetails( address contract_ ) external view returns ( address, address, address, address, bool, bool );

}


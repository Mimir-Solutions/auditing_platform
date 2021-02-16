// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.1;

interface IDatastore {
    
    function register( address contract_, address deployer ) external;

    function setAuditor( address contract_, address auditor ) external;

    function confirmRegistration( address contract_, address deployer, address creationHash, address auditor ) external;

    function approveAudit( address contract_, address auditor ) external;

    function opposeAudit( address contract_, address auditor ) external;

    function getContractInformation( address contract_ ) external returns ( address, address, address, address, bool, bool, bool );
    
    function addAuditor( address platformOwner, address auditor ) external;
    
    function suspendAuditor( address platformOwner, address auditor ) external;

    function suspendDeployer( address platformOwner, address auditor ) external;
    
    function migrateAuditor( address platform, address auditor ) external;
        
    function reinstateAuditor( address platformOwner, address auditor ) external;

    function reinstateDeployer( address platformOwner, address auditor ) external;
    
    function pause() external;
    
    function unpause() external;
    
    function linkDataStore( address platformOwner, address dataStore ) external;
    
    function searchAllStoresForIsAuditor( address auditor ) external view returns ( bool );
    
    function searchAllStoresForContractDetails( address contract_ ) external view returns ( address, address, address, address, bool, bool );

}



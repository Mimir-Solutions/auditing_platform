// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.4;

interface IDatastore {

    function completeAudit( address auditor, address deployer, address contract_, address txHash, bool approved ) external;
    
    function register( address deployer, address auditor, address contract_, address creationHash ) external;
    
    function addAuditor( address auditor ) external;
    
    function suspendAuditor( address auditor ) external;
    
    function migrateAuditor( address auditor ) external;
    
    function contractDestructed( address sender ) external;
    
    function reinstateAuditor( address auditor ) external;
    
    function pauseDataStore() external;
    
    function unpauseDataStore() external;
    
    function linkDataStore( address dataStore ) external;
    
    function searchAllStoresForIsAuditor( address auditor ) external view returns ( bool );
    
    function searchAllStoresForContractDetails( address contract_ ) external view returns ( address, address, address, address, bool, bool );

}


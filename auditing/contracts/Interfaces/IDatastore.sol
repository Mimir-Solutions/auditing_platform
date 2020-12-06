// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.4;

// TODO: Which functions should be here?
interface IDatastore {

    function completeAudit( address auditor, address deployer, address contract_, address txHash, bool approved ) external;
    
    function addAuditor( address auditor ) external;
    
    function suspendAuditor( address auditor ) external;
    
    function migrateAuditor( address auditor ) external;
    
    function contractDestructed( address sender ) external;
    
    function reinstateAuditor( address auditor ) external;
    
    function pauseDataStore() external;
    
    function unpauseDataStore() external;
    
    function linkDataStore( address dataStore ) external;

}


// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.4;

interface IAuditingPlatform {
    
    function completeAudit( address auditor, address deployer, address hash, bool approved ) external;
    
    function migrateAuditor( address auditor ) external;

    function register( address deployer, address auditor, address creationHash ) external;

    function setAuditor( address auditor ) external;

}


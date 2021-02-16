// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.1;

interface IAuditorStore {
    
    function addAuditor( address platformOwner, address platform, address auditor ) external;
    
    function suspendAuditor( address platformOwner, address platform, address auditor ) external;
    
    function reinstateAuditor( address platformOwner, address platform, address auditor ) external;
    
    function hasAuditorRecord( address auditor ) external view returns ( bool );

    function isAuditor( address auditor ) external view returns ( bool );

    function getAuditorInformation( address auditor ) external view returns ( bool, uint256, uint256 );
    
    function getAuditorApprovedContractIndex( address auditor, uint256 index ) external view returns ( uint256 );
    
    function getAuditorOpposedContractIndex( address auditor, uint256 index ) external view returns ( uint256 );
    
    function migrate( address platform, address previousDatastore, address auditor ) external;
    
    function saveContractIndexForAuditor( address platform, address auditor, bool approved, uint256 index ) external;

    function linkAuditorStore( address auditorStore ) external;
    
}

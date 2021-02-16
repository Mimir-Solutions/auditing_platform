// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.1;

interface IDeployerStore {
    
    function addDeployer( address platform, address deployer ) external;
    
    function suspendDeployer( address platformOwner, address platform, address deployer ) external;

    function reinstateDeployer( address platformOwner, address platform, address deployer ) external;
    
    function isBlacklisted( address deployer ) external view returns ( bool );
    
    function getDeployerInformation( address deployer ) external view returns ( bool, uint256, uint256 );
    
    function getDeployerApprovedContractIndex( address deployer, uint256 contractIndex ) external view returns ( uint256 );

    function getDeployerOpposedContractIndex( address deployer, uint256 contractIndex ) external view returns ( uint256 );
    
    function saveContractIndexForDeplyer( address platform, address deployer, bool approved, uint256 contractIndex ) external;

    function linkDeployerStore( address deployerStore ) external;
    
}

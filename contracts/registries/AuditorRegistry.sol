// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "../dependencies/holyzeppelin/contracts/security/access/Ownable.sol";

contract AuditorRegistry is Ownable {

  mapping( address => bool ) public isPlatformApproved;

  mapping( address => mapping( address => bool ) ) public isplatformForAuditorApproved;

  /**
   * @dev Contains the auditing platforms on which an auditor is registered.
   */
  mapping( address => address[] ) public auditorAddressForRegisteredPlatforms;

  /**
   */
  function setPlatformRegistration( address newPlatform_ ) external onlyOwner() {
    console.log( "Contract::AuditPlatformRegistry::setPlatformRegistration::01 Registering %s as new auditing platform.", newPlatform_ );
    isPlatformApproved[newPlatform_] = true;
    console.log( "Contract::AuditPlatformRegistry::setPlatformRegistration::01 Registered %s as new auditing platform.", newPlatform_ );
  }

  function setApprovalForAuditorForPlatform( address newAuditor_, bool newApproval_ ) external {
    console.log( "Contract::AuditPlatformRegistry::setApprovalForAuditorForPlatform::01 Is %s platform is approved to register auditors? %s.", msg.sender, isPlatformApproved[msg.sender] );
    require( isPlatformApproved[msg.sender] == true );
    console.log( "Contract::AuditPlatformRegistry::setApprovalForAuditorForPlatform::02 %s platform is approved to register auditors.", isPlatformApproved[msg.sender] );

    console.log( "Contract::AuditPlatformRegistry::setApprovalForAuditorForPlatform::03 %s is changing approval to %s for auditor %s for their platform.", msg.sender, newApproval_, newAuditor_ );
    isplatformForAuditorApproved[msg.sender][newAuditor_] = newApproval_;
    console.log( "Contract::AuditPlatformRegistry::setApprovalForAuditorForPlatform::04 %s Changed approval to %s for auditor %s for their platform.", msg.sender, isPlatformApproved[msg.sender], newAuditor_ );
  }

  function registerAuditorForPlatform( address newPlatformToRegister_ ) external {
    console.log( "Contract::AuditPlatformRegistry::setApprovalForAuditorForPlatform::01 Is %s platform is approved to register auditors? %s.", msg.sender, isPlatformApproved[msg.sender] );
    require( isPlatformApproved[msg.sender] == true );
    console.log( "Contract::AuditPlatformRegistry::setApprovalForAuditorForPlatform::02 %s platform is approved to register auditors.", isPlatformApproved[msg.sender] );

    require( isplatformForAuditorApproved[newPlatformToRegister_][msg.sender] == true );

    auditorAddressForRegisteredPlatforms[msg.sender].push(newPlatformToRegister_);
  }
}
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.1;

import "./Ownable.sol";
import "./IAuditingPlatform.sol";


abstract contract Auditable is Ownable {

    /**
     * @notice the address of the auditor who is auditing the contract that inherits from the Auditable contract
     */
    address public auditor;

    /**
     * @notice the organization / platform which the auditor is acting through and where the data is sent
     */
    address public platform;

    /**
     * @notice the wallet address of the entity that has deployed the contract (original owner)
     * @dev payable because there are plans to add a destruct (clean up) method and the (original owner) deployer should get their money back
     */
    address payable public immutable deployer;

    /**
     * @notice Indicates whether the audit has been completed or is in progress
     * @dev Audit is completed when the bool is set to true otherwise the default is false (in progress)
     */
    bool public audited;
    
    /**
     * @notice Indicates whether the audit has been approved or opposed
     * @dev Consider this bool only after "audited" is true. Approved is true and Opposed (default) if false
     */
    bool public approved;

    /**
     * @notice a private version of "approved" which is used for unlocking contract functionality
     * @dev since the "approved" variable unlocks functionality make it private and use that instead for additional security
     */
    bool private _approved;

    /**
     * @notice Modifier used to block or allow method functionality based on the approval / opposition of the audit
     * @dev Use this on every function in the inheriting contracts
     */
    modifier isApproved() {
        require( audited,   "Contract is yet to be audited, functionality disabled" );
        require( _approved, "Contract failed the audit, functionality permanently disabled" );
        _;
    }

    /**
     * @notice Event tracking who set the platform and which platform was set
     * @param owner The current owner of the contract
     * @param platform The organization the audit is being performed through
     * @dev Index the sender and the platform for easier searching
     */
    event SetPlatform( address indexed owner, address indexed platform );

    /**
     * @notice Event tracking the registration of the contract via a platform
     * @param owner The current owner of the contract
     * @param platform The organization the audit is being performed through
     * @dev Index the owner and the platform for easier searching
     */
    event RegisteredContract( address indexed owner, address indexed platform );

    /**
     * @notice Event tracking who set the auditor and who the auditor is
     * @param owner The current owner of the contract
     * @param auditor The entity performing the audit on the contract
     * @dev Index the sender and the auditor for easier searching
     */
    event SetAuditor( address indexed owner, address indexed auditor );
    
    /**
     * @notice Event tracking the status of the audit and who the auditor is
     * @param platform The organization the audit is being performed through
     * @param auditor The entity performing the audit on the contract
     */
    event ApprovedAudit( address platform, address auditor );

    /**
     * @notice Event tracking the status of the audit and who the auditor is
     * @param platform The organization the audit is being performed through
     * @param auditor The entity performing the audit on the contract
     */
    event OpposedAudit( address platform, address auditor );

    /**
     * @notice When deploying the contract set the deployer as the original owner
     */
    constructor() Ownable() public {
        deployer = _owner;
    }

    /**
     * @notice Allows the owner to change the platform prior to the completion of the audit
     * @param _platform an address indicating a contract which will be serving the function of the new platform
     */
    function setPlatform( address _platform ) external {
        require( msg.sender == _owner, "Owner only" );

        // Do not spam events after the audit; easier to check final state if you cannot change it
        require( !audited, "Cannot change platform post audit" );

        platform = _platform;

        emit SetPlatform( msg.sender, platform );
    }

    /**
     * @notice Inform the platform that you want to register and store some data in their data store
     */
    function register() external {
        require( !audited, "Contract has already been audited" );

        IAuditingPlatform( platform ).register( deployer );

        emit RegisteredContract( _owner, platform );
    }

    /**
     * @notice Used to change the auditor by the owner prior to the completion of the audit
     * @param _auditor an address indicating which entity is performing the audit
     */
    function setAuditor( address _auditor ) external {
        require( msg.sender == _owner, "Owner only" );

        // Do not spam events after the audit; easier to check final state if you cannot change it
        require( !audited, "Cannot change auditor post audit" );

        auditor = _auditor;
        IAuditingPlatform( platform ).setAuditor( _auditor );

        emit SetAuditor( msg.sender, auditor );
    }

    /**
     * @notice The auditor is in favor of the contract therefore they approve it and unlock contract functionality
     * @param _auditor an address indicating which entity is performing the audit
     * @dev The caller is the platform as the auditor must use the platform to validate that they are at the time of the call still a valid auditor
     */
    function approveAudit( address _auditor ) external {
        require( msg.sender == platform, "Platform only" );
        require( _auditor == auditor, "Auditor only" );

        // Auditor cannot change their mind and approve/oppose multiple times
        require( !audited, "Contract has already been audited" );

        // Switch to true to complete audit and approve
        audited = true;
        approved = true;

        // Remember that we separate the public variable from the one that is used to unlock the functionality
        _approved = true;

        emit ApprovedAudit( msg.sender, auditor );
    }

    /**
     * @notice Auditor is against the contract therefore they oppose it
     * @param _auditor an address indicating which entity is performing the audit
     * @dev The caller is the platform as the auditor must use the platform to validate that they are at the time of the call still a valid auditor
     */
    function opposeAudit( address _auditor ) external {
        require( msg.sender == platform, "Platform only" );
        require( _auditor == auditor, "Auditor only" );
        
        // Auditor cannot change their mind and approve/oppose multiple times
        require( !audited, "Cannot oppose an audited contract" );

        // Switch to true to complete the audit and explicitly set approved to false (default is false)
        audited = true;
        approved = false;

        // Remember that we separate the public variable from the one that is used to unlock the functionality
        _approved = false;

        emit OpposedAudit( msg.sender, auditor );
    }

}



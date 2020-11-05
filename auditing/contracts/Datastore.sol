// SPDX-License-Identifier: AGPL v3

pragma solidity ^0.6.10;

import "./Pausable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Datastore is Pausable {
    
    using SafeMath for uint256;

    // Daisy chain the data stores backwards to allow recursive backwards search.
    address public previousDatastore;

    string constant public version = "Demo: 1";
    
    // Stats for auditors and contracts
    uint256 public activeAuditorCount;
    uint256 public suspendedAuditorCount;

    uint256 public approvedContractCount;
    uint256 public opposedContractCount;

    struct Auditor {
        bool     isAuditor;
        address  auditor;
        string[] approvedContracts;
        string[] opposedContracts;
    }

    // TODO: redesign the structs?
    struct Deployer {
        ContractData data;
        string contractHash;
        string creationHash;
    }

    struct ContractData {
        address auditor;
        bool    approved;
        bool    destructed;
    }

    struct Contract {
        ContractData data;
        string creationHash;
    }

    struct InverseContractLookup {
        ContractData data;
        string contractHash;
    }

    mapping(address => Auditor)  private auditors;
    mapping(address => Deployer) private deployers;
    mapping(string => Contract)  private contracts;
    mapping(string => InverseContractLookup) private creationHash;

    // State changes to auditors
    event AddedAuditor(     address indexed _owner, address indexed _auditor);
    event SuspendedAuditor( address indexed _owner, address indexed _auditor);
    event ReinstatedAuditor(address indexed _owner, address indexed _auditor);

    // Auditor migration
    event AcceptedMigration(address indexed _migrator, address indexed _auditor);

    // Completed audits
    event NewRecord(address indexed _auditor, address _contract, string _hash, bool indexed _approved);

    // Daisy chain stores
    event LinkedDataStore(address indexed _owner, address indexed _dataStore);
    
    // TODO: add in deployer lookup calls

    constructor() Pausable() public {}

    function hasAuditorRecord(address _auditor) external view returns (bool) {
        return _hasAuditorRecord(_auditor);
    }

    function isAuditor(address _auditor) external view returns (bool) {
        // Ambigious private call, call with caution or use with hasAuditorRecord()
        return _isAuditor(_auditor);
    }

    function hasContractRecord(string memory _contract) external view returns (bool) {
        return _hasContractRecord(_contract);
    }

    function hasContractCreationRecord(string memory _contract) external view returns (bool) {
        return _hasCreationRecord(_contract);
    }

    function auditorDetails(address _auditor) external view returns (bool, uint256, uint256) {
        require(_hasAuditorRecord(_auditor), "No auditor record in the current store");

        return 
        (
            auditors[_auditor].isAuditor, 
            auditors[_auditor].approvedContracts.length, 
            auditors[_auditor].opposedContracts.length
        );
    }

    function auditorApprovedContract(address _auditor, uint256 _index) external view returns (string memory) {
        require(_hasAuditorRecord(_auditor), "No auditor record in the current store");
        require(0 < auditors[_auditor].approvedContracts.length, "Approved list is empty");
        require(_index <= auditors[_auditor].approvedContracts.length, "Record does not exist");

        if (_index != 0) {
            _index = _index.sub(1);
        }

        return auditors[_auditor].approvedContracts[_index];
    }

    function auditorOpposedContract(address _auditor, uint256 _index) external view returns (string memory) {
        require(_hasAuditorRecord(_auditor), "No auditor record in the current store");
        require(0 < auditors[_auditor].opposedContracts.length, "Opposed list is empty");
        require(_index <= auditors[_auditor].opposedContracts.length, "Record does not exist");

        if (_index != 0) {
            _index = _index.sub(1);
        }

        return auditors[_auditor].opposedContracts[_index];
    }

    function contractDetails(string memory _contract) external view returns (address, bool, bool, string memory) {
        require(_hasContractRecord(_contract), "No contract record in the current store");

        return 
        (
            contracts[_contract].data.auditor, 
            contracts[_contract].data.approved,
            contracts[_contract].data.destructed,
            contracts[_contract].creationHash
        );
    }

    function contractCreationDetails(string memory _creationHash) external view returns (address, bool, bool, string memory) {
        require(_hasCreationRecord(_creationHash), "No contract record in the current store");

        return 
        (
            creationHash[_creationHash].data.auditor, 
            creationHash[_creationHash].data.approved,
            creationHash[_creationHash].data.destructed,
            creationHash[_creationHash].contractHash
        );
    }

    function addAuditor(address _auditor) external onlyOwner() whenNotPaused() {
        // We are adding the auditor for the first time into this data store
        require(!_hasAuditorRecord(_auditor), "Auditor record already exists");

        auditors[_auditor].isAuditor = true;
        auditors[_auditor].auditor = _auditor;
        
        activeAuditorCount = activeAuditorCount.add(1);

        emit AddedAuditor(_msgSender(), _auditor);
    }

    function suspendAuditor(address _auditor) external onlyOwner() {
        // Do not change previous stores. Setting to false in the current store should prevent actions
        // from future stores when recursively searching

        if (_hasAuditorRecord(_auditor)) {
            if (!_isAuditor(_auditor)) {
                revert("Auditor has already been suspended");
            }
            activeAuditorCount = activeAuditorCount.sub(1);
        } else {
            auditors[_auditor].auditor = _auditor;
        }

        auditors[_auditor].isAuditor = false;
        suspendedAuditorCount = suspendedAuditorCount.add(1);

        emit SuspendedAuditor(_msgSender(), _auditor);
    }

    function reinstateAuditor(address _auditor) external onlyOwner() whenNotPaused() {
        require(_hasAuditorRecord(_auditor), "No auditor record in the current store");
        require(!_isAuditor(_auditor), "Auditor already has active status");

        auditors[_auditor].isAuditor = true;
        
        activeAuditorCount = activeAuditorCount.add(1);
        suspendedAuditorCount = suspendedAuditorCount.sub(1);

        emit ReinstatedAuditor(_msgSender(), _auditor);
    }

    function completeAudit(address _auditor, address _contract, bool _approved, bytes calldata _txHash) external onlyOwner() whenNotPaused() {
        require(_hasAuditorRecord(_auditor), "No auditor record in the current store");
        require(_isAuditor(_auditor), "Auditor has been suspended");

        // Using bytes, calldata and external is cheap however over time string conversions may add up
        // so just store the string instead ("pay up front")
        string memory _hash = string(_txHash);

        // TODO: Better require messages
        require(contracts[_contract].data.auditor == address(0), "Contract has already been audited");
        require(creationHash[_hash].data.auditor == address(0), "Contract has already been audited");

        // TODO: handle both creation hash and contract hash
        if (_approved) {
            auditors[_auditor].approvedContracts.push(_hash);
            approvedContractCount = approvedContractCount.add(1);
        } else {
            auditors[_auditor].opposedContracts.push(_hash);
            opposedContractCount = opposedContractCount.add(1);
        }

        // TODO: Add in the deployer info

        // TODO: can I omit the destructed argument since the default bool is false?
        ContractData _commonData = ContractData({auditor: _auditor, approved: _approved, destructed: false});

        // TODO: _contract here is address while mapping is string. Turn mapping to address type and then same for creationHash in the inverseLookup?
        contracts[_contract].data = _commonData;
        contracts[_contract].creationHash = _hash

        // TODO: If I change one struct does it affect every reference or are they copied into the structs?
        creationHash[_hash].data = _commonData;
        creationHash[_hash].contractHash = _contract;

        emit NewRecord(_auditor, _contract, _hash, _approved);
    }

    function migrate(address _migrator, address _auditor) external onlyOwner() {
        // Auditor should not exist to mitigate event spamming or possible neglectful changes to 
        // _recursiveAuditorSearch(address) which may allow them to switch their suspended status to active
        require(!_hasAuditorRecord(_auditor), "Already in data store");
        
        // Call the private method to begin the search
        // Also, do not shadow the function name
        bool isAnAuditor = _recursiveAuditorSearch(_auditor);

        // The latest found record indicates that the auditor is active / not been suspended
        if (isAnAuditor) {
            // We can migrate them to the current store
            // Do not rewrite previous audits into each new datastore as that will eventually become too expensive
            auditors[_auditor].isAuditor = true;
            auditors[_auditor].auditor = _auditor;

            activeAuditorCount = activeAuditorCount.add(1);

            emit AcceptedMigration(_migrator, _auditor);
        } else {
            revert("Auditor is either suspended or has never been in the system");
        }
    }

    function _hasAuditorRecord(address _auditor) private view returns (bool) {
        return auditors[_auditor].auditor != address(0);
    }

    function _isAuditor(address _auditor) private view returns (bool) {
        // This will return false in both cases where an auditor has not been added into this datastore
        // or if they have been added but suspended
        return auditors[_auditor].isAuditor;
    }

    function _hasContractRecord(string memory _contract) private view returns (bool) {
        return contracts[_contract].data.auditor != address(0);
    }

    function _hasCreationRecord(string memory _contract) private view returns (bool) {
        return creationHash[_contract].data.auditor != address(0);
    }

    function isAuditorRecursiveSearch(address _auditor) external view returns (bool) {
        // Check in all previous stores if the latest record of them being an auditor is set to true/false
        // This is likely to be expensive so it is better to check each store manually / individually
        return _recursiveAuditorSearch(_auditor);
    }

    function contractDetailsRecursiveSearch(string memory _contract) external view returns (address, bool, bool, string memory) {
        // Check in all previous stores if this contract has been recorded
        // This is likely to be expensive so it is better to check each store manually / individually
        return _recursiveContractDetailsSearch(_contract, true);
    }

    function contractCreationDetailsRecursiveSearch(string memory _contract) external view returns (address, bool, bool, string memory) {
        // Check in all previous stores if this contract has been recorded
        // This is likely to be expensive so it is better to check each store manually / individually
        return _recursiveContractDetailsSearch(_contract, false);
    }

    function _recursiveContractDetailsSearch(string memory _contract, bool _contractHash) private view returns (address, bool, bool, string memory) {
        address _auditor;
        bool    _approved;
        bool    _destructed;
        string  _hash;

        if (_contractHash) {
            if (_hasContractRecord(_contract)) {
                _auditor    = contracts[_contract].data.auditor;
                _approved   = contracts[_contract].data.approved;
                _destructed = contracts[_contract].data.destructed;
                _hash       = contracts[_contract].creationHash;
            } else if (previousDatastore != address(0)) {
                (_auditor, _approved, _destructed, _hash) = _contractLookup("contractDetailsRecursiveSearch");
            } else {
                revert("No contract record in any data store");
            }
        } else {
            if (_hasCreationRecord(_contract)) {
                _auditor    = creationHash[_contract].data.auditor;
                _approved   = creationHash[_contract].data.approved;
                _destructed = creationHash[_contract].data.destructed;
                _hash       = creationHash[_contract].contractHash;
            } else if (previousDatastore != address(0)) {
                (_auditor, _approved, _destructed, _hash) = _contractLookup("contractCreationDetailsRecursiveSearch");
            } else {
                revert("No contract record in any data store");
            }
        }

        return (_auditor, _approved, _destructed, _hash);
    }

    function _contractLookup(string memory _function) private view returns returns (address, bool, bool, string memory) {
        string memory _signature = string(abi.encodePacked(_function, "(string)")
        (bool success, bytes memory data) = previousDatastore.staticcall(abi.encodeWithSignature(_signature, _contract));

        require(success, string(abi.encodePacked("Unknown error when recursing in datastore version: ", version)));
        
        (_auditor, _approved, _destructed, _creationHash) = abi.decode(data, (address, bool, bool, string));
        return (_auditor, _approved, _destructed, _creationHash);
    }

    function _recursiveAuditorSearch(address _auditor) private view returns (bool) {
        // Technically not needed as default is set to false but lets be explicit
        // Also, do not shadow the function name
        bool isAnAuditor = false;

        if (_hasAuditorRecord(_auditor)) {
            if (_isAuditor(_auditor)) {
                isAnAuditor = true;
            }
        } else if (previousDatastore != address(0)) {
            (bool success, bytes memory data) = previousDatastore.staticcall(abi.encodeWithSignature("isAuditorRecursiveSearch(address)", _auditor));
            
            require(success, string(abi.encodePacked("Unknown error when recursing in datastore version: ", version)));

            isAnAuditor = abi.decode(data, (bool));
        } else {
            revert("No auditor record in any data store");
        }

        return isAnAuditor;
    }

    // TODO: take back ownership and then give it to the 0th address once you are changed to a newer version
    function linkDataStore(address _dataStore) external onlyOwner() {
        previousDatastore = _dataStore;
        emit LinkedDataStore(_msgSender(), previousDatastore);
    }
}

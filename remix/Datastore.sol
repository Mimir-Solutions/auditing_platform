// SPDX-License-Identifier: AGPL v3

pragma solidity ^0.6.10;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {

    // We need owner to be payable so this contract is basically the same + some improvements
    // double underscore so that we can use external/internal visibility (automatic getter blocks otherwise)
    address payable private __owner;

    modifier onlyOwner() {
        require(__owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

    constructor() internal {
        __owner = _msgSender();
        emit OwnershipTransferred(address(0), __owner);  
    }

    function owner() external view returns (address payable) {
        return _owner();
    }

    function _owner() internal view returns (address payable) {
        return __owner;
    }

    function renounceOwnership() external onlyOwner() {
        address prevOwner = __owner;
        __owner = address(0);

        emit OwnershipTransferred(prevOwner, __owner);
    }

    function transferOwnership(address payable _newOwner) external onlyOwner() {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");

        address prevOwner = __owner;
        __owner = _newOwner;

        emit OwnershipTransferred(prevOwner, __owner);
    }
}


contract Pausable is Ownable {

    bool private _paused;

    modifier whenNotPaused() {
        require(!_paused, "Action is active");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Action is suspended");
        _;
    }

    event Paused(   address indexed _sender);
    event Unpaused( address indexed _sender);

    constructor () internal {}

    function paused() external view returns (bool) {
        return _paused;
    }

    function pause() external onlyOwner() whenNotPaused() {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() external onlyOwner() whenPaused() {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


contract Datastore is Pausable {

    // Daisy chain the data stores backwards to allow recursive backwards search.
    address public previousDatastore;

    string constant public version = "Demo: 1";

    struct Auditor {
        bool     isAuditor;
        address  auditor;
        string[] approvedContracts;
        string[] opposedContracts;
    }

    struct Contract {
        address auditor;
        bool    approved;
    }

    mapping(address => Auditor) private auditors;
    mapping(string => Contract) private contracts;

    // State changes to auditors
    event AddedAuditor(     address indexed _owner, address indexed _auditor);
    event SuspendedAuditor( address indexed _owner, address indexed _auditor);
    event ReinstatedAuditor(address indexed _owner, address indexed _auditor);

    // Auditor migration
    event AcceptedMigration(address indexed _migrator, address indexed _auditor);
    event RejectedMigration(address indexed _migrator, address indexed _auditor);

    // Completed audits
    event NewRecord(address indexed _auditor, string indexed _hash, bool indexed _approved);

    // Daisy chain stores
    event LinkedDataStore(address indexed _owner, address indexed _dataStore);
    
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

    function auditorDetails(address _auditor) external view returns (bool, uint256, uint256) {
        require(_hasAuditorRecord(_auditor), "No auditor record in the current store");

        return 
        (
            auditors[_auditor].isAuditor, 
            auditors[_auditor].approvedContracts.length, 
            auditors[_auditor].opposedContracts.length
        );
    }

    // check the length, will it underflow?
    function auditorApprovedContract(address _auditor, uint256 _index) external view returns (string memory) {
        require(_hasAuditorRecord(_auditor), "No auditor record in the current store");
        require(_index <= auditors[_auditor].approvedContracts.length - 1, "Index is too large, array out of bounds");

        return auditors[_auditor].approvedContracts[_index];
    }

    // check the length, will it underflow?
    function auditorOpposedContract(address _auditor, uint256 _index) external view returns (string memory) {
        require(_hasAuditorRecord(_auditor), "No auditor record in the current store");
        require(_index <= auditors[_auditor].opposedContracts.length - 1, "Index is too large, array out of bounds");

        return auditors[_auditor].opposedContracts[_index];
    }

    function contractDetails(string memory _contract) external view returns (address, bool) {
        require(_hasContractRecord(_contract), "No contract record in the current store");

        return 
        (
            contracts[_contract].auditor, 
            contracts[_contract].approved 
        );
    }

    function addAuditor(address _auditor) external onlyOwner() whenNotPaused() {
        // We are adding the auditor for the first time into this data store
        require(!_hasAuditorRecord(_auditor), "Auditor record already exists");

        auditors[_auditor].isAuditor = true;
        auditors[_auditor].auditor = _auditor;

        emit AddedAuditor(_msgSender(), _auditor);
    }

    function suspendAuditor(address _auditor) external onlyOwner() {
        // Do not change previous stores. Setting to false in the current store should prevent actions
        // from future stores when recursively searching
        require(_hasAuditorRecord(_auditor), "No auditor record in the current store");
        require(_isAuditor(_auditor), "Auditor has already been suspended");

        auditors[_auditor].isAuditor = false;

        emit SuspendedAuditor(_msgSender(), _auditor);
    }

    function reinstateAuditor(address _auditor) external onlyOwner() whenNotPaused() {
        require(_hasAuditorRecord(_auditor), "No auditor record in the current store");
        require(!_isAuditor(_auditor), "Auditor already has active status");

        auditors[_auditor].isAuditor = true;

        emit ReinstatedAuditor(_msgSender(), _auditor);
    }

    function completeAudit(address _auditor, bool _approved, bytes calldata _txHash) external onlyOwner() whenNotPaused() {
        require(_hasAuditorRecord(_auditor), "No auditor record in the current store");
        require(_isAuditor(_auditor), "Auditor has been suspended");

        // Using bytes, calldata and external is cheap however over time string conversions may add up
        // so just store the string instead ("pay up front")
        string memory _hash = string(_txHash);

        // Defensively code against everything
        require(contracts[_hash].auditor == address(0), "Contract has already been audited");

        if (_approved) {
            auditors[_auditor].approvedContracts.push(_hash);
        } else {
            auditors[_auditor].opposedContracts.push(_hash);
        }

        contracts[_hash].auditor = _auditor;
        contracts[_hash].approved = _approved;

        emit NewRecord(_auditor, _hash, _approved);
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

            emit AcceptedMigration(_migrator, _auditor);
        } else {
            // Auditor has either never been in the system or have been suspended in the latest record
            emit RejectedMigration(_migrator, _auditor);
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
        return contracts[_contract].auditor != address(0);
    }

    function isAuditorRecursiveSearch(address _auditor) external view returns (bool) {
        // Check in all previous stores if the latest record of them being an auditor is set to true/false
        // This is likely to be expensive so it is better to check each store manually / individually
        return _recursiveAuditorSearch(_auditor);
    }

    function contractDetailsRecursiveSearch(string memory _contract) external view returns (address, bool) {
        // Check in all previous stores if this contract has been recorded
        // This is likely to be expensive so it is better to check each store manually / individually
        return _recursiveContractDetailsSearch(_contract);
    }

    function _recursiveContractDetailsSearch(string memory _contract) private view returns (address, bool) {
        address _auditor;
        bool _approved;

        if (_hasContractRecord(_contract)) {
            _auditor = contracts[_contract].auditor;
            _approved = contracts[_contract].approved;            
        } else if (previousDatastore != address(0)) {
            (bool success, bytes memory data) = previousDatastore.staticcall(abi.encodeWithSignature("contractDetailsRecursiveSearch(address)", _contract));

            // This won't work because of breaking solidity changes, have to figure out the data conversion above
            // (_auditor, _approved) = previousDatastore.call(abi.encodeWithSignature("contractDetailsRecursiveSearch(string)", _contract));
        } else {
            revert("No contract record in any data store");
        }

        return (_auditor, _approved);
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
            
            // This won't work because of breaking solidity changes, have to figure out the data conversion above
            // isAnAuditor = previousDatastore.call(abi.encodeWithSignature("isAuditorRecursiveSearch(address)", _auditor));
        } else {
            revert("No auditor record in any data store");
        }

        return isAnAuditor;
    }

    function linkDataStore(address _dataStore) external onlyOwner() {
        previousDatastore = _dataStore;
        emit LinkedDataStore(_msgSender(), previousDatastore);
    }
}


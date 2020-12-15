// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.4;

//import "@openzeppelin/contracts/GSN/Context.sol";

// Temp
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}


abstract contract Ownable is Context {

    address payable internal _owner;

    modifier onlyOwner() {
        require( _owner == _msgSender(), "Ownable: caller is not the owner" );
        _;
    }

    event OwnershipTransferred( address indexed previousOwner, address indexed newOwner );

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred( address( 0 ), _owner );  
    }

    function owner() external view returns (address payable) {
        return _owner;
    }

    function renounceOwnership() external onlyOwner() {
        address prevOwner = _owner;
        _owner = address( 0 );

        emit OwnershipTransferred( prevOwner, _owner );
    }

    function transferOwnership( address payable newOwner ) external onlyOwner() {
        require( newOwner != address( 0 ), "Ownable: new owner is the zero address" );

        address prevOwner = _owner;
        _owner = newOwner;

        emit OwnershipTransferred( prevOwner, _owner );
    }
}

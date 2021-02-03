// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.4;

import "./Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract AuditNFT is Ownable, ERC721 {

    using SafeMath for uint256;

    /**
     * @notice A unique identifier for the token
     * @dev each time a token is minted this will be incremented so a new token can gain a unique ID
     *      in order to prevent a duplicate ID the token should eventually be swapped out and archived
     */
    uint256 public tokenID;

    /**
     * @notice Event tracking when a token is minted and who the recipient (auditor) is
     * @param recipient The auditor
     * @param tokenId Unique number identifying the token
     */
    event MintedToken( address recipient, uint256 tokenId );

    /**
     * @notice Event indicating when an transfer has been attempted and blocked
     * @param from The owner of the token
     * @param to The intended recipient of the transfer
     * @param tokenId Unique number identifying the token
     * @param message A message indicating to the owner that the token cannot be transferred
     * @dev The NFT is a record for the auditor and not something to be traded
     */
    event TransferAttempted( address from, address to, uint256 tokenId, string message );

    // TODO: should the archive have a version or be more specific?
    constructor() Ownable() ERC721( "Audit Archive NFT", "Audit Archive" ) public {}

    /**
     * @notice A custom mint function which takes additional information and packages it up as meta data for a token
     * @param auditor The entity that has performed an audit (assumed to be a valid auditor for a platform that made the call)
     * @param contract_ The contract that was audited
     * @param deployer The original owner of the audited contract_
     * @param approved Boolean indicating whether the auditor has approved or opposed the contract
     * @param hash The contract creation hash (first hash when the contract is deployed)
     */
    function mint( address auditor, address contract_, address deployer, bool approved, bytes calldata hash ) external onlyOwner() {

        // Address types must be converted manually otherwise conversions will not be in human readable form later
        string memory auditor_ = addressToString( auditor );
        string memory _contract = addressToString( contract_ );
        string memory deployer_ = addressToString( deployer );
        string memory metaData;

        // TODO: Can I just pass in a bool below instead of this string?
        string memory approved_ = approved ? 'true' : 'false';

        // TODO: Change name, description, image?
        metaData =  string(abi.encodePacked(
            '{',
            '"name": ' ,            '"The Church of the Chain Incorporated Audit Archive NFT",',
            '"description": ',      '"A record of the audit for this contract provided to auditors from The Church of the Chain Incorporated",',
            '"image": ',            '"https://ipfs.io/ipfs/QmSZUL7Ea21osUUUESX6nPuUSSTF6RniyoJGBaa2ZY7Vjd",',
            '"auditor": ',          '"', auditor_, '",',
            '"contract": ',         '"', _contract, '",',
            '"deployer": ',         '"', deployer_, '",',
            '"approved": ',              approved_, ',',
            '"deploymentHash": ',   '"', string( hash ), '",',
            '}'
        ));

        // Mint token and send to the recipient (auditor)
        _safeMint( auditor, tokenID );
        _setTokenURI( tokenID, metaData );

        // Events belong at the end
        uint256 ID = tokenID;
        
        // Increment the token ID for the next mint
        tokenID = tokenID.add( 1 );

        emit MintedToken( auditor, ID );
    }

    /**
     * @notice A function overriding the typical transfer behavior in order to prevent a transfer from occuring
     * @param from The owner of the token
     * @param to The intended recipient of the transfer
     * @param tokenId Unique number identifying the token
     */
    function _transfer( address from, address to, uint256 tokenId ) internal virtual override {
        emit TransferAttempted( from, to, tokenId, "The NFT is a non-fungible, non-transferable token" );
    }

    /**
     * @notice Helper function that converts an address type to a string type equivalent
     * @param address_ Hash representing an address
     */
    function addressToString( address address_ ) private pure returns ( string memory ) {
        // Utility function found on stackoverflow, shoutout to whoever posted this
        bytes32 _bytes = bytes32( uint256( address_ ) );
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes( 42 );
        
        _addr[0] = '0';
        _addr[1] = 'x';
        
        for ( uint256 i = 0; i < 20; i++ ) {
            _addr[ 2+i*2 ] = HEX[ uint8( _bytes[ i + 12 ] >> 4 ) ];
            _addr[ 3+i*2 ] = HEX[ uint8( _bytes[ i + 12 ] & 0x0f ) ];
        }
        
        return string( _addr );
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";


/**
 * Possible Improvement
 * 1. Add batch mint (see POAP batch) but require auto tokenId
 */
contract XBadge is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, AccessControlUpgradeable {
    
    event EventToken(uint256 eventId, uint256 tokenId);

    using CountersUpgradeable for CountersUpgradeable.Counter;    

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    CountersUpgradeable.Counter private _tokenIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC721_init("Tech X Badge", "TXB");
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    // Mapping data for event and uri to minimize uri requirement
    mapping(uint256 => string) private _eventURI;

    // Mapping data for tokenId to eventId
    mapping(uint256 => uint256) private _tokenEvent;
    

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Function to set Event URI
     * @param eventId EventId for the new token
     * @param uri Link to ERC721 JSON metadata for event.
     */
    function setEventURI(uint256 eventId, string memory uri) 
        public
        onlyRole(MINTER_ROLE)
    {
        _eventURI[eventId] = uri;
    }

    /**
     * @dev Function to retrieve event URI
     * @param eventId EventId to retrieve data
     */
    function eventURI(uint256 eventId)
        public
        view
        returns (string memory)
    {
        return _eventURI[eventId];
    }

    /**
     * @dev Function to retrieve eventId for token
     * @param tokenId TokenId to retrieve data
     */
    function sourceEvent(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _tokenEvent[tokenId];
    }

    /**
     * @dev Function to set Mint new Badge using event Id
     * @param eventId EventId for the new token
     * @param to Address of badge receiever/owner
     */
    function safeMint(uint256 eventId, address to) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _tokenEvent[tokenId] = eventId;
        emit EventToken(eventId, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    
    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        uint256 eventId = _tokenEvent[tokenId];
        return _eventURI[eventId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function currentCounter() 
        public 
        view 
        onlyRole(MINTER_ROLE)
        returns (uint256) {
        uint256 counter = _tokenIdCounter.current();
        return counter;
    }

    function version() public pure returns (string memory) {
        return "v1";
    }
}
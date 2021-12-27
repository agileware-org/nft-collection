// SPDX-License-Identifier: MIT

/**
 *  █▄ █ █▀ ▀█▀   ▄▀▀ ▄▀▄ █   █   ██▀ ▄▀▀ ▀█▀ █ ▄▀▄ █▄ █ ▄▀▀
 *  █ ▀█ █▀  █    ▀▄▄ ▀▄▀ █▄▄ █▄▄ █▄▄ ▀▄▄  █  █ ▀▄▀ █ ▀█ ▄██
 *
 * Made with 🧡 by Kreation.tech
 */
pragma solidity ^0.8.6;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * This contract allows dynamic NFT minting.
 * 
 * Operations allow for selling publicly, partial or total giveaways, direct giveaways and rewardings.
 */
contract DroppableCollection is ERC721Upgradeable, IERC2981Upgradeable, OwnableUpgradeable {
    
    using CountersUpgradeable for CountersUpgradeable.Counter;
    
    event ItemsAdded(uint256 amount);

    struct Info {
        // name of the collection
        string name;
        // symbol of the tokens minted by this contract
        string symbol;
        // description of the collection
        string description;
    }

    // collection description
    string public description;

    // collection base URL
    string public baseUrl;
    
    // the number of nft this collection contains
    uint64 public size;
    
    // royalties ERC2981 in bps
    uint16 public royalties;

    constructor() initializer { }

    /**
     * Creates a new collection and builds all the available NFTS setting their owner to the address that creates the edition: this can be re-assigned or updated later.
     * 
     * @param _owner can drop more tokens, gets royalties and can update the base URL.
     * @param _info collection properties
     * @param _size number of NFTs that can be minted from this contract: set to 0 for unbound
     * @param _baseUrl sad
     * @param _royalties perpetual royalties paid to the creator upon token selling
     */
    function initialize(
        address _owner,
        Info memory _info,
        uint64 _size,
        string memory _baseUrl,
        uint16 _royalties
    ) public initializer {
        __ERC721_init(_info.name, _info.symbol);
        __Ownable_init();

        transferOwnership(_owner); // set ownership
        description = _info.description;
        require(bytes(_baseUrl).length > 0, "Empty base URL");
        baseUrl = _baseUrl;
        if (_size > 0) {
            _mint(_size);
        }
        require(_royalties < 10_000, "Royalties too high");
        royalties = _royalties;
    }

    /**
     * Returns the number of tokens minted so far 
     */
     function totalSupply() public view returns (uint256) {
        return size;
    }

    function drop(string memory _baseUrl, uint64 _size) external onlyOwner returns (uint256) {
        baseUrl = _baseUrl;
        return _mint(_size);
    }

    function _mint(uint64 _size) internal returns (uint256) {
        require(_size > size, "Not extended");
        for (uint64 tokenId = size + 1; tokenId <= _size; tokenId++) {
            _safeMint(owner(), tokenId, "");
        }
        size = _size;
        return size;
    }

    /**
     * User burn function for token id.
     * 
     * @param tokenId token edition identifier to burn
     */
    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved");
        _burn(tokenId);
    }

    /**
     * Get URI for given token id
     * 
     * @param tokenId token id to get uri for
     * @return base64-encoded json metadata object
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token doesn't exist");
        return string(abi.encodePacked(baseUrl, "/", tokenId, ".json"));
    }
    
    /**
     * ERC2981 - Gets royalty information for token
     *
     * @param _value the sale price for this token
     */
    function royaltyInfo(uint256, uint256 _value) external view override returns (address receiver, uint256 royaltyAmount) {
        if (owner() == address(0x0)) {
            return (owner(), 0);
        }
        return (owner(), (_value * royalties) / 10_000);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, IERC165Upgradeable) returns (bool) {
        return type(IERC2981Upgradeable).interfaceId == interfaceId || ERC721Upgradeable.supportsInterface(interfaceId);
    }
}

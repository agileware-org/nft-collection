// SPDX-License-Identifier: MIT

/**
 * ░█▄█░▄▀▄▒█▀▒▄▀▄░░░▒░░░▒██▀░█▀▄░█░▀█▀░█░▄▀▄░█▄░█░▄▀▀░░░█▄░█▒█▀░▀█▀
 * ▒█▒█░▀▄▀░█▀░█▀█▒░░▀▀▒░░█▄▄▒█▄▀░█░▒█▒░█░▀▄▀░█▒▀█▒▄██▒░░█▒▀█░█▀░▒█▒
 *
 * Made with 🧡 by Kreation.tech
 */
pragma solidity ^0.8.6;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./IMintableEditions.sol";
import {MetadataHelper} from "./MetadataHelper.sol";

/**
 * This contract allows dynamic NFT minting.
 * 
 * Operations allow for selling publicly, partial or total giveaways, direct giveaways and rewardings.
 */
contract MintableEditions is ERC721Upgradeable, IERC2981Upgradeable, IMintableEditions, OwnableUpgradeable {
    
    using CountersUpgradeable for CountersUpgradeable.Counter;
    
    event PriceChanged(uint256 amount);
    event EditionSold(uint256 price, address owner);
    event SharesPaid(address to, uint256 amount);

    struct Shares {
        address payable holder;
        uint16 bps;
    }

    struct Allowance {
        address minter;
        uint16 amount;
    }

    struct Info {
        // name of editions, used in the title as "$name $tokenId/$size"
        string name;
        // symbol of the tokens minted by this contract
        string symbol;
        // description of token editions
        string description;
        // content URL of the token editions
        string baseContentUrl;
      
    }

    // token id counter
    CountersUpgradeable.Counter private counter;

    // token description
    string public description;

    // token content URL
    string public baseContentUrl;
    
    // the number of editions this contract can mint
    uint64 public size;
    
    // royalties ERC2981 in bps
    uint16 public royalties;

    // addresses allowed to mint editions
    mapping(address => uint16) public allowedMinters;


    // contract shareholders and shares information
    address[] private shareholders;
    mapping(address => uint16) public shares;

    // shares withdrawals
    uint256 private withdrawn;
    mapping(address => uint256) private withdrawals;

    /**
     * Creates a new edition and sets the only allowed minter to the address that creates/owns the edition: this can be re-assigned or updated later.
     * 
     * @param _owner can authorize, mint, gets royalties and a dividend of sales, can update the content URL.
     * @param _info token properties
     * @param _size number of NFTs that can be minted from this contract: set to 0 for unbound
     * @param _royalties perpetual royalties paid to the creator upon token selling
     * @param _shares array of tuples listing the shareholders and their respective shares in bps (one per each shareholder)
     * @param _allowances array of tuples listing the allowed minters and their allowances
     */
    function initialize(
        address _owner,
        Info memory _info,
        uint64 _size,
        uint16 _royalties,
        Shares[] memory _shares,
        Allowance[] memory _allowances
    ) public initializer {
        __ERC721_init(_info.name, _info.symbol);
        __Ownable_init();

        transferOwnership(_owner); // set ownership
        description = _info.description;
        require(bytes(_info.baseContentUrl).length > 0, "Empty content URL");
        baseContentUrl = _info.baseContentUrl;
        size = _size;
        _setAllowances(_allowances);
        counter.increment(); // token ids start at 1

        require(_royalties < 10_000, "Royalties too high");
        royalties = _royalties;
        
        uint16 _totalShares;
        for (uint256 i = 0; i < _shares.length; i++) {
            _addPayee(_shares[i].holder, _shares[i].bps);
            _totalShares += _shares[i].bps;
        }
        require(_totalShares < 10_000, "Shares too high");
        _addPayee(payable(_owner), 10_000 - _totalShares);
    }

    function _addPayee(address payable _account, uint16 _shares) internal {
        require(_account != address(0), "Shareholder is zero address");
        require(_shares > 0 && _shares <= 10_000, "Shares are invalid");
        require(shares[_account] == 0, "Shareholder already has shares");

        shareholders.push(_account);
        shares[_account] = _shares;
    }

    /**
     * Returns the number of tokens minted so far 
     */
     function totalSupply() public view returns (uint256) {
        return counter.current() - 1;
    }


    /**
     * Transfers all ETHs from the contract balance to the owner and shareholders.
     */
    function shake() external {
        for (uint i = 0; i < shareholders.length; i++) {
            _withdraw(payable(shareholders[i]));
        }
    }

    /**
     * Transfers `withdrawable(msg.sender)` to the caller.
     */
    function withdraw() external {
        _withdraw(payable(msg.sender));
    }

    /**
     * Returns how much the account can withdraw from this contract.
     */
    function withdrawable(address payable _account) external view returns (uint256) {
        uint256 _totalReceived = address(this).balance + withdrawn;
        return (_totalReceived * shares[_account]) / 10_000 - withdrawals[_account];
    }

    /**
     * INTERNAL: attempts to transfer part of the contract balance to the caller, provided the account is a shareholder and
     * on the basis of its shares and previous withdrawals.
     *
     * @param _account the address of the shareholder to pay out
     */
    function _withdraw(address payable _account) internal {
        uint256 _amount = this.withdrawable(_account);
        require(_amount != 0, "Account is not due payment");
        withdrawals[_account] += _amount;
        withdrawn += _amount;
        AddressUpgradeable.sendValue(_account, _amount);
        emit SharesPaid(_account, _amount);
    }

    /**
     * INTERNAL: checks if the msg.sender is allowed to mint.
     */
    function _isAllowedToMint() internal view returns (bool) {
        return (owner() == msg.sender) || _isPublicAllowed() || (allowedMinters[msg.sender] > 0);
    }
    
    /**
     * INTERNAL: checks if the ZeroAddress is allowed to mint.
     */
    function _isPublicAllowed() internal view returns (bool) {
        return (allowedMinters[address(0x0)] > 0);
    }


    /**
     * Returns the owner of the collection of editions.
     */
    function owner() public view override(OwnableUpgradeable, IMintableEditions) returns (address) {
        return super.owner();
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        shares[newOwner] = shares[newOwner] + shares[owner()];
        shares[owner()] = 0;
         _transferOwnership(newOwner);
    }

    function renounceOwnership() public override onlyOwner {
        require(address(this).balance == 0 && price == 0, "Potential loss of funds");
        _transferOwnership(address(0));
    }

    /**
     * Allows the edition owner to set the amount of tokens (max 65535) an address is allowed to mint.
     * 
     * If the ZeroAddress (address(0x0)) is set as a minter with an allowance greater than 0, anyone will be allowed 
     * to mint any amount of tokens, similarly to setApprovalForAll in the ERC721 spec.
     * If the allowed amount is set to 0 then the address will NOT be allowed to mint.
     * 
     * @param allowances tuples of (address, uint16) describing how many tokens an address is allowed to mint, 0 disables minting
     */
    function setApprovedMinters(Allowance[] memory allowances) external onlyOwner {
        _setAllowances(allowances);
    }

    function _setAllowances(Allowance[] memory allowances) internal {
        for (uint i = 0; i < allowances.length; i++) {
            allowedMinters[allowances[i].minter] = allowances[i].amount;
        }
    }

    /**
     * Allows for updates of edition urls by the owner of the edition.
     * Only URLs can be updated (data-uris are supported), hashes cannot be updated.
     */
    function updateEditionsURL(string memory _baseContentUrl) external onlyOwner {
        require(bytes(_baseContentUrl).length > 0, "Empty content URL");
        baseContentUrl = _baseContentUrl;
    }

    /** 
     * Returns the number of tokens still available for minting (uint64 when open edition)
     */
    function mintable() public view override returns (uint256) {
        // atEditionId is one-indexed hence the need to remove one here
        return ((size == 0) ? type(uint64).max : size + 1) - counter.current();
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
     * Get URIs and hash for edition NFT
     *
     * @return contentUrl, contentHash
     */
    function getURI() public view returns (string memory) {
        return (baseContentUrl);
    }

    /**
     * Get URI for given token id
     * 
     * @param tokenId token id to get uri for
     * @return base64-encoded json metadata object
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Edition doesn't exist");
        
        return abi.encodePacked(baseContentUrl, "/", numberToString(tokenId),".json");
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

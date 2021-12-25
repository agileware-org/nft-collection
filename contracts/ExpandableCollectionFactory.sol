// SPDX-License-Identifier: MIT

/**
 *  █▄ █ █▀ ▀█▀   ▄▀▀ ▄▀▄ █   █   ██▀ ▄▀▀ ▀█▀ █ ▄▀▄ █▄ █ ▄▀▀
 *  █ ▀█ █▀  █    ▀▄▄ ▀▄▀ █▄▄ █▄▄ █▄▄ ▀▄▄  █  █ ▀▄▀ █ ▀█ ▄██
 * 
 * Made with 🧡 by Kreation.tech
 */
pragma solidity ^0.8.6;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import "./ExpandableCollection.sol";

contract ExpandableCollectionFactory is AccessControl {
    bytes32 public constant ARTIST_ROLE = keccak256("ARTIST_ROLE");
    using Counters for Counters.Counter;

    // Counter for current contract id
    Counters.Counter internal _counter;

    // Address for implementation contract to clone
    address private _implementation;

    // Store for name to id mappings
    mapping(string => uint256) private _names;

    /**
     * Initializes the factory with the address of the implementation contract template
     * 
     * @param implementation Edition implementation contract to clone
     */
    constructor(address implementation) {
        _implementation = implementation;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ARTIST_ROLE, msg.sender);
    }

    /**
     * Creates a new collection contract as a factory with a deterministic address, returning the address of the newly created contract.
     * Important: None of these fields can be changed after calling this operation, with the sole exception of the baseUrl field which
     * must refer to a content having the same hash.
     * 
     * @param info collection immutable information
     * @param size number of NFTs composing this collection
     * @param baseUrl url to be prepended to token URIs
     * @param royalties perpetual royalties paid to the creator upon token selling
     * @return the address of the editions contract created
     */
    function create(
        ExpandableCollection.Info memory info,
        uint64 size,
        string memory baseUrl,
        uint16 royalties
    ) external onlyRole(ARTIST_ROLE) returns (address) {
        require(_names[info.name] != 0, "Duplicated collection");
        uint256 id = _counter.current();
        _names[info.name] = id;
        address instance = Clones.cloneDeterministic(_implementation, bytes32(abi.encodePacked(id)));
        ExpandableCollection(instance).initialize(msg.sender, info, size, baseUrl, royalties);
        emit CreatedCollection(id, msg.sender, baseUrl, size, instance);
        _counter.increment();
        return instance;
    }

    /**
     * Gets an editions contract given the unique identifier. Contract ids are zero-based.
     * 
     * @param index zero-based index of editions contract to retrieve
     * @return the editions contract
     */
    function get(uint256 index) external view returns (ExpandableCollection) {
        return ExpandableCollection(Clones.predictDeterministicAddress(_implementation, bytes32(abi.encodePacked(index)), address(this)));
    }

    function get(string memory name) external view returns (ExpandableCollection) {
        return ExpandableCollection(Clones.predictDeterministicAddress(_implementation, bytes32(abi.encodePacked(_names[name])), address(this)));
    }

    /** 
     * @return the number of edition contracts created so far through this factory
     */
     function instances() external view returns (uint256) {
        return _counter.current();
    }

    /**
     * Emitted when an edition is created reserving the corresponding token IDs.
     * 
     * @param index the identifier of the newly created editions contract
     * @param creator the editions' owner
     * @param size the number of tokens this editions contract consists of
     * @param contractAddress the address of the contract representing the editions
     */
    event CreatedCollection(uint256 indexed index, address indexed creator, string baseUrl, uint256 size, address contractAddress);
}

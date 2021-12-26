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
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import "./ExpandableCollection.sol";

contract ExpandableCollectionFactory is AccessControl {
    bytes32 public constant ARTIST_ROLE = keccak256("ARTIST_ROLE");
    using Counters for Counters.Counter;

    // Counter for current contract id
    Counters.Counter internal _counter;

    // Address for implementation contract to clone
    UpgradeableBeacon public immutable beacon;

    // Store for name to id mappings
    mapping(string => address) private _names;
    
    /**
     * Initializes the factory with the address of the implementation contract template
     * 
     * @param implementation implementation contract to clone
     */
    constructor(address implementation) {
        UpgradeableBeacon _tokenBeacon = new UpgradeableBeacon(implementation);
        _tokenBeacon.transferOwnership(_msgSender());
        beacon = _tokenBeacon;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ARTIST_ROLE, _msgSender());
    }

    function upgrade(address implementation) onlyRole(DEFAULT_ADMIN_ROLE) public {
        beacon.upgradeTo(implementation);
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
        require(_names[info.name] == address(0x0), "Duplicated collection");
        uint256 id = _counter.current();
        BeaconProxy proxy = new BeaconProxy(
            address(beacon), 
            abi.encodeWithSelector(ExpandableCollection(address(0x0)).initialize.selector, _msgSender(), info, size, baseUrl, royalties)
        );
        _names[info.name] = address(proxy);
        emit CreatedCollection(id, msg.sender, baseUrl, size, address(proxy));
        _counter.increment();
        return address(proxy);
    }

    /**
     * Gets an editions contract given the unique identifier. Contract ids are zero-based.
     * 
     * @param name FIXME zero-based index of editions contract to retrieve
     * @return the editions contract
     */
    function get(string memory name) external view returns (ExpandableCollection) {
        return ExpandableCollection(_names[name]);
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

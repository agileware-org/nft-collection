```
 █▄ █ █▀ ▀█▀   ▄▀▀ ▄▀▄ █   █   ██▀ ▄▀▀ ▀█▀ █ ▄▀▄ █▄ █
 █ ▀█ █▀  █    ▀▄▄ ▀▄▀ █▄▄ █▄▄ █▄▄ ▀▄▄  █  █ ▀▄▀ █ ▀█
```
---

These solidity smart contracts realize a NFT collection factory.

# Properties

An NFT collection has the following characteristics:

* `name` is a unique identifier for the collection (IMMUTABLE)
* `symbol` to identify all the tokens withing this collection (IMMUTABLE)
* `description` a decriptive text of hte collection (supports markdown notation) (IMMUTABLE)
* `size` the amount of tokens this collection is going to host (MUTABLE)
* `baseUrl` the url used as the base for each token URI, which will be composed as `{baseUrl}/{tokenId}.json` (MUTABLE)
* `royalties` perpetual royalties paid to the contract owner upon each token transaction, expressed in Basis Points

# Functionalities

TO DO

# Upgradeability

The logic used to implement the collections is hidden behind an UpgreadableBeaconProxy, meaning all contracts can be upgraded as a whole by replacing the beacon implementation.

The operation to perform such action is exposed on the factory contract and is named `upgradeTo`. Only addresses with administrative privileges are entitled to upgrade the contract implementation.

**WARNING** Upgrading the implementation with the wrong contract can lead to making all collections unusuable and, as a consequence, all NFTs described within them.


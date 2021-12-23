// SPDX-License-Identifier: MIT

/**
 * ░█▄█░▄▀▄▒█▀▒▄▀▄░░░▒░░░▒██▀░█▀▄░█░▀█▀░█░▄▀▄░█▄░█░▄▀▀░░░█▄░█▒█▀░▀█▀
 * ▒█▒█░▀▄▀░█▀░█▀█▒░░▀▀▒░░█▄▄▒█▄▀░█░▒█▒░█░▀▄▀░█▒▀█▒▄██▒░░█▒▀█░█▀░▒█▒
 * 
 * Made with 🧡 by Kreation.tech
 */
pragma solidity ^0.8.6;


import {MetadataHelper} from "./MetadataHelper.sol";

/**
 * Shared NFT logic for rendering metadata associated with Collections
 */
contract CollectionsMetadataHelper is MetadataHelper {

    /**
     * Generates Collection metadata from storage information as base64-json blob
     * Combines the media data and metadata
     * 
     * @param name Name of NFT in metadata
     * @param description Description of NFT in metadata
     * @param contentUrl URL of content to render
     * @param thumbnailUrl optional URL of a thumbnail to render, for animated content only
     * @param tokenOfCollection unique identifier of a token Collection
     * @param size total count of Collections
     */
    function createTokenURI(string memory name, string memory description, string memory contentUrl, string memory thumbnailUrl, uint256 tokenOfCollection, uint256 size) external pure returns (string memory) {
        string memory _tokenMediaData = tokenMediaData(contentUrl, thumbnailUrl, tokenOfCollection);
        bytes memory json = createMetadata(name, description, _tokenMediaData, tokenOfCollection, size);
        return encodeMetadata(json);
    }

    /** 
     * Function to create the metadata json string for the nft Collection
     * 
     * @param name Name of NFT in metadata
     * @param description Description of NFT in metadata
     * @param mediaData Data for media to include in json object
     * @param tokenOfCollection Token ID for specific token
     * @param size Size of entire Collection to show
    */
    function createMetadata(string memory name, string memory description, string memory mediaData, uint256 tokenOfCollection, uint256 size) public pure returns (bytes memory) {
        bytes memory sizeText;
        if (size > 0) {
            sizeText = abi.encodePacked("/", numberToString(size));
        }
        return abi.encodePacked('{"name":"', name, " ", numberToString(tokenOfCollection), sizeText, '","description":"', description, '","',
                mediaData, 'properties":{"number":', numberToString(tokenOfCollection), ',"name":"', name, '"}}');
    }

    /** 
     * Generates Collection metadata from storage information as base64-json blob
     * Combines the media data and metadata
     * 
     * @param contentUrl URL of image to render for Collection
     * @param thumbnailUrl index of the content type to render for Collection
     * @param tokenOfCollection token identifier
     */
    function tokenMediaData(string memory contentUrl, string memory thumbnailUrl, uint256 tokenOfCollection) public pure returns (string memory) {
        if (bytes(thumbnailUrl).length == 0) {
            return string(
                abi.encodePacked(
                    'image":"', contentUrl, "/", numberToString(tokenOfCollection),'","'));
        } else {
            return string(
                abi.encodePacked(
                    'image":"', thumbnailUrl, "/", numberToString(tokenOfCollection),'","animation_url":"', contentUrl, "/", numberToString(tokenOfCollection),'","'));
        }
    }
}

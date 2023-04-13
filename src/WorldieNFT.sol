// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ByteHasher} from "./helpers/ByteHasher.sol";
import {IWorldID} from "./interfaces/IWorldID.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";

/// @title Worldie NFT
/// @author Miguel Piedrafita
/// @notice A sybil-resistant NFT drop for the ETHTokyo hackathon
contract WorldieNFT is ERC721 {
    using ByteHasher for bytes;

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when attempting to reuse a nullifier
    error InvalidNullifier();

    /// @notice Thrown when trying to retrieve metadata for a non-existent token
    error TokenNotMinted();

    /// @notice Thrown when the maximum number of tokens has been minted
    error MaxTokensMinted();

    /// @dev The World ID instance that will be used for verifying proofs
    IWorldID internal immutable worldId;

    /// @dev The contract's external nullifier hash
    uint256 internal immutable externalNullifier;

    /// @notice The metadata URL for the NFT
    string public metadataURI;

    /// @dev Whether a nullifier hash has been used already. Used to guarantee an action is only performed once by a single person
    mapping(uint256 => bool) internal nullifierHashes;

    /// @dev The next tokenID to be minted
    uint256 internal nextTokenID = 1;

    /// @notice The maximum number of tokens that can be minted
    uint256 public immutable maxTokens;

    /// @param _worldId The WorldID instance that will verify the proofs
    /// @param _appId The World ID app ID
    /// @param _actionId The World ID action ID
    /// @param _metadataURI The metadata URI for the NFT
    constructor(
        IWorldID _worldId,
        uint256 _maxTokens,
        string memory _appId,
        string memory _actionId,
        string memory _metadataURI
    ) ERC721("Worldie NFT", "WORLDIE") {
        worldId = _worldId;
        maxTokens = _maxTokens;
        metadataURI = _metadataURI;
        externalNullifier = abi
            .encodePacked(abi.encodePacked(_appId).hashToField(), _actionId)
            .hashToField();
    }

    /// @param receiver The address that will receive the NFT.
    /// @param root The root of the Merkle tree.
    /// @param nullifierHash The nullifier hash for this proof, preventing double signaling.
    /// @param proof The zero-knowledge proof that demonstrates the claimer is registered with World ID.
    function mint(
        address receiver,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) public {
        if (nextTokenID > maxTokens) revert MaxTokensMinted();
        if (nullifierHashes[nullifierHash]) revert InvalidNullifier();

        worldId.verifyProof(
            root,
            1,
            abi.encodePacked(receiver).hashToField(),
            nullifierHash,
            externalNullifier,
            proof
        );

        nullifierHashes[nullifierHash] = true;

        _mint(receiver, nextTokenID++);
    }

    /// @notice Returns the metadata URI for a given NFT
    /// @param id The token ID to retrieve metadata for
    function tokenURI(uint256 id) public view override returns (string memory) {
        if (ownerOf(id) == address(0)) revert TokenNotMinted();

        return metadataURI;
    }
}

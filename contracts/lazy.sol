//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

struct NFTVoucher {
    address creator;
    uint256 tokenId;
    uint256 price;
    address currency;
    string uri;
    bytes signature;
}

contract LazyNFT is ERC721URIStorage, EIP712 {
    string private constant SIGNING_DOMAIN = "LazyNFT-Voucher";
    string private constant SIGNATURE_VERSION = "1";
    
    mapping(uint256 => address) public creators;

    constructor() ERC721("mechlin","mck") 
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {}

    modifier onlyCreator(uint256 tokenId) {
        require(creators[tokenId] == msg.sender, "Only creator allowed");
        _;
    }

    function redeem(address redeemer, NFTVoucher calldata voucher) public returns (uint256) {
        address signer = _verify(voucher);

        require(signer == voucher.creator, "Signature invalid");
        require(IERC20(voucher.currency).allowance(redeemer, address(this)) >= voucher.price, "Insufficient allowance");

        IERC20(voucher.currency).transferFrom(redeemer, voucher.creator, voucher.price);

        _mint(voucher.creator, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.uri);

        _transfer(voucher.creator, redeemer, voucher.tokenId);

        return voucher.tokenId;
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    function _verify(NFTVoucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFTVoucher(address creator, uint256 tokenId, uint256 price, address currency, string uri"),
            voucher.creator,
            voucher.tokenId,
            voucher.price,
            voucher.currency,
            keccak256(bytes(voucher.uri))
        )));
    }

    function setCreator(address to, uint256[] memory tokenIds) public {
        require(to != address(0), "Invalid address");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _setCreator(to, tokenId);
        }
    }

     function _setCreator(address to, uint256 tokenId) internal onlyCreator(tokenId) {
        creators[tokenId] = to;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return ERC721.supportsInterface(interfaceId);
    }
}
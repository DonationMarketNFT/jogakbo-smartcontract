pragma solidity ^0.5.0; 
pragma experimental ABIEncoderV2;

import './KIP17Token.sol';

contract NFT is KIP17Token('Jogakbo','JB' ){

    uint256 tokenId = 0;
    
    function _sendDonationNFT (
        uint256 _tokenId, 
        string memory tokenURI,
        string memory tokenIPFS,
        string memory tokenOwnerName,
        string memory tokenAgencyUrl,
        string memory tokenDate,
        string memory tokenNumber
    ) private returns (bool) {
        KIP17MetadataMintable.mintWithTokenURI(
            msg.sender, 
            _tokenId, 
            tokenURI, 
            tokenIPFS, 
            tokenOwnerName, 
            tokenAgencyUrl, 
            tokenDate, 
            tokenNumber
            );
        return true;
    } // NFT 발행 
    
    
    // send to NFT 
    function sendNFT(string memory IPFS_url) public payable {

        // NFT 발행
        tokenId++;

        require(
        _sendDonationNFT(
            tokenId, IPFS_url, "IPFS_url", "name", "tokenAgencyUrl", "2022-02-21", "1")
        ,"Donation NFT: minting failed");
    }
}
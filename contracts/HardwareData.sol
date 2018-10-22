pragma solidity ^0.4.24;

/** @title HardwareData */

contract HardwareData {

    bytes[] public ipfsHashes;
    event newHash(bytes ipfsHash);

    /**
    * @dev Add a new hash from ipfs to ethereum
    * @param ipfsHash The IPFS hash string
    */
    function addHash(bytes ipfsHash) public {

        ipfsHashes.push(ipfsHash);
        emit newHash(ipfsHash);
    }

    function getHashesCount() public view returns (uint count) {
        return ipfsHashes.length;
    }

}
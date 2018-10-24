pragma solidity ^0.4.24;

/** @title HardwareData */

import "./User.sol";

contract HardwareData {

    User private user;
    bytes[] public ipfsHashes;
    event newHash(bytes ipfsHash);
    mapping(address => bytes) public addressToHardwareId;

   /**
    * @dev Throws if non-user is trying to interact with the contract method.
    */
    modifier onlyUser() {
        require(user.hasUser(msg.sender), "You need to have a user for calling this function");
        _;
    }
    

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

    function addNewHardwareId(bytes hardware_id) public {
        addressToHardwareId[msg.sender] = hardware_id;
    }

    function getHardwareIdFromSender() public view returns (bytes hardwareId){
        return addressToHardwareId[msg.sender];
    }
}
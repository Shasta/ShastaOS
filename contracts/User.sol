pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./ShastaMarket.sol";

/** @title User */
contract User {
    
  mapping(address => uint) private addressToIndex;
  mapping(bytes16 => uint) private usernameToIndex;

  event NewUser(bytes16 username, address owner);
  event UpdatedUser(address owner, bytes ipfsHash);

  ShastaMarket public shastaMarket;
  address public shastaMarketAddress;
  address[] private addresses;
  bytes16[] private usernames;
  bytes[] private ipfsHashes;
  address owner;
  
  modifier onlyOwner() {
    require (msg.sender != owner);
    _;
  }

  constructor(address _shastaMarketAddress) public {

    // mappings are virtually initialized to zero values so we need to "waste" the first element of the arrays
    // instead of wasting it we use it to create a user for the contract itself
    owner = msg.sender;
    shastaMarketAddress = _shastaMarketAddress;
    shastaMarket = ShastaMarket(shastaMarketAddress);
    addresses.push(msg.sender);
    usernames.push('self');
    ipfsHashes.push('noIpfsHash');
  }

  /**
    * @dev Check if the address belongs to a user
    * @param userAddress The address to check if exists in the user registry.
    */
  function hasUser(address userAddress) public view returns(bool) 
  {
    return (addressToIndex[userAddress] > 0);
  }

  /**
    * @dev Check if the username belongs to a user
    * @param username The username to check if exists in the user registry
    */
  function usernameTaken(bytes16 username) public view returns(bool) 
  {
    return (usernameToIndex[username] > 0 || username == 'self');
  }

  /**
    * @dev Create a new user
    * @param username The organization name
    * @param ipfsHash The IPFS hash string with more metadata
    */
  function createUser(bytes16 username, bytes ipfsHash) public returns(bool)
  {
    require(!hasUser(msg.sender));
    require(!usernameTaken(username));

    addresses.push(msg.sender);
    usernames.push(username);
    ipfsHashes.push(ipfsHash);

    addressToIndex[msg.sender] = addresses.length - 1;
    usernameToIndex[username] = addresses.length - 1;
    
    emit NewUser(username, msg.sender);
    return true;
  }

  /**
    * @dev Create a new energy offer
    * @param _value The amount of watts/hour available to sell
    * @param ipfsHash The IPFS hash string with metadata
    */
  function createOffer(uint _value, bytes ipfsHash) public payable {
    shastaMarket.createOffer(_value, msg.sender);
    updateUser(ipfsHash);
  }

  /**
    * @dev Cancel a energy offer
    * @param _id The ID of the the offer
    * @param ipfsHash The IPFS hash string with metadata
    */
  function cancelOffer(uint _id, bytes ipfsHash) public payable {
    shastaMarket.cancelOffer(_id, msg.sender);
    updateUser(ipfsHash);
  }

  /**
    * @dev Update the user ipfs hash string
    * @param ipfsHash The IPFS hash string to update
    * @return success Returns true if succesful
    */
  function updateUser(bytes ipfsHash) public payable returns(bool success)
  {
    require(hasUser(msg.sender), 'Your ethereum address does not belong to any Shasta account.');
    
    ipfsHashes[addressToIndex[msg.sender]] = ipfsHash;
    
    emit UpdatedUser(msg.sender, ipfsHash);
    return true;
  }  

  /**
    * @dev Get the user length
    * @return count The number of current users registered in Shasta
    */
  function getUserCount() public view returns(uint count)
  {
    return addresses.length;
  }

  /**
    * @dev Get the address of an user by user index
    * @param index The user index
    * @return userAddress the user address
    */
  function getAddressByIndex(uint index) public view returns(address userAddress)
  {
    require(index < addresses.length);

    return addresses[index];
  }

  /**
    * @dev Get the address of an user by username
    * @param username The username in bytes16
    * @return userAddress the user address
    */
  function getAddressByUsername(bytes16 username) public view returns(address userAddress)
  {
    require(usernameTaken(username));

    return addresses[usernameToIndex[username]];
  }  

  /**
    * @dev Get the user data by address
    * @param userAddress The user address
    * @return index The user index
    * @return username The user name
    * @return ipfsHash The ipfs hash where more metadata is stored in IPFS
    */
  function getUserByAddress(address userAddress) public view returns(uint index, bytes16 username, bytes ipfsHash) {
    require(index < addresses.length);

    return(addressToIndex[userAddress], usernames[addressToIndex[userAddress]], ipfsHashes[addressToIndex[userAddress]]);
  }


  /**
    * @dev Get the username by address
    * @param userAddress The user address
    * @return username The user name
    */
  function getUsernameByAddress(address userAddress) public view returns(bytes16 username)
  {
    require(hasUser(userAddress));

    return usernames[addressToIndex[userAddress]];
  }

  /**
    * @dev Get the IPFS hash by index
    * @param index The user index
    * @return ipfsHash The ipfs hash where more metadata is stored in IPFS
    */
  function getIpfsHashByIndex(uint index) public view returns(bytes ipfsHash)
  {
    require(index < addresses.length);

    return ipfsHashes[index];
  }
  /**
    * @dev Get the IPFS hash by address
    * @param userAddress The user address
    * @return ipfsHash The ipfs hash where more metadata is stored in IPFS
    */
  function getIpfsHashByAddress(address userAddress) public view returns(bytes ipfsHash)
  {
    require(hasUser(userAddress));

    return ipfsHashes[addressToIndex[userAddress]];
  }

  /**
    * @dev Get the IPFS hash by username
    * @param username The user name
    * @return ipfsHash The ipfs hash where more metadata is stored in IPFS
    */
  function getIpfsHashByUsername(bytes16 username) public view returns(bytes ipfsHash)
  {
    require(usernameTaken(username), "Username does not exists.");

    return ipfsHashes[usernameToIndex[username]];
  }

  /**
    * @dev Get the user index by address
    * @param userAddress The user address
    * @return index The user index
    */
  function getIndexByAddress(address userAddress) public view returns(uint index)
  {
    require(hasUser(userAddress));

    return addressToIndex[userAddress];
  }
}
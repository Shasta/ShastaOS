pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./ShastaMarket.sol";

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

  function hasUser(address userAddress) public view returns(bool) 
  {
    return (addressToIndex[userAddress] > 0);
  }
  
  function usernameTaken(bytes16 username) public view returns(bool) 
  {
    return (usernameToIndex[username] > 0 || username == 'self');
  }
  
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

  function createOffer(uint _value, bytes ipfsHash) public payable {
        shastaMarket.createOffer(_value, msg.sender);
        updateUser(ipfsHash);
  }

  function cancelOffer(uint _id, bytes ipfsHash) public payable {
      shastaMarket.cancelOffer(_id, msg.sender);
      updateUser(ipfsHash);
}

  function updateUser(bytes ipfsHash) public payable returns(bool success)
  {
    require(hasUser(msg.sender));
    
    ipfsHashes[addressToIndex[msg.sender]] = ipfsHash;
    
    emit UpdatedUser(msg.sender, ipfsHash);
    return true;
  }  
 
  function getUserCount() public view returns(uint count)
  {
    return addresses.length;
  }

  // get by index
/*   function getUserByIndex(uint index) public view returns(address userAddress, bytes16 username, bytes ipfsHash) {
    require(index < addresses.length);

    return(addresses[index], usernames[index], ipfsHashes[index]);
  } */

  function getAddressByIndex(uint index) public view returns(address userAddress)
  {
    require(index < addresses.length);

    return addresses[index];
  }

/*   function getUsernameByIndex(uint index) public view returns(bytes16 username)
  {
    require(index < addresses.length);

    return usernames[index];
  } */

  function getIpfsHashByIndex(uint index) public view returns(bytes ipfsHash)
  {
    require(index < addresses.length);

    return ipfsHashes[index];
  }

  // get by address
  function getUserByAddress(address userAddress) public view returns(uint index, bytes16 username, bytes ipfsHash) {
    require(index < addresses.length);

    return(addressToIndex[userAddress], usernames[addressToIndex[userAddress]], ipfsHashes[addressToIndex[userAddress]]);
  }

  function getIndexByAddress(address userAddress) public view returns(uint index)
  {
    require(hasUser(userAddress));

    return addressToIndex[userAddress];
  }

  function getUsernameByAddress(address userAddress) public view returns(bytes16 username)
  {
    require(hasUser(userAddress));

    return usernames[addressToIndex[userAddress]];
  }

  function getIpfsHashByAddress(address userAddress) public view returns(bytes ipfsHash)
  {
    require(hasUser(userAddress));

    return ipfsHashes[addressToIndex[userAddress]];
  }

  // get by username
 /*  function getUserByUsername(bytes16 username) public view returns(uint index, address userAddress, bytes ipfsHash) {
    require(index < addresses.length);

    return(usernameToIndex[username], addresses[usernameToIndex[username]], ipfsHashes[usernameToIndex[username]]);
  } */

/*   function getIndexByUsername(bytes16 username) public view returns(uint index)
  {
    require(usernameTaken(username));

    return usernameToIndex[username];
  }   */

  function getAddressByUsername(bytes16 username) public view returns(address userAddress)
  {
    require(usernameTaken(username));

    return addresses[usernameToIndex[username]];
  }  

  function getIpfsHashByUsername(bytes16 username) public view returns(bytes ipfsHash)
  {
    require(usernameTaken(username), "Username does not exists.");

    return ipfsHashes[usernameToIndex[username]];
  }

}
pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

import "./User.sol";

 /**
  * @title ShastaMarketplace
  * This contract will manage the creation and execution of sell offers
  *
  */

contract ShastaMarket is Ownable, Pausable {
    User public userStorage;
    mapping(address => uint[]) private addressToOffersIndex;
    Offer[] private offersList;
    address public owner;

    struct Offer {
        address seller;
        uint value;
        bool isActive;
    }

    event newOffer(address seller, uint value);
    event cancelOfferEvent(address seller, uint value);
    /**
    * @dev Throws if non-user is trying to interact with the contract method.
    */
    modifier onlyUser() {
        require(userStorage.hasUser(msg.sender));
        _;
    }
    
    function createOffer(uint _value, address _seller) public whenNotPaused {
        Offer memory myOffer;
        myOffer.seller = _seller;
        myOffer.value = _value;
        myOffer.isActive = true;

        uint index = offersList.push(myOffer) - 1;
        addressToOffersIndex[_seller].push(index);
        emit newOffer(_seller, _value);
    }

    /**
    * @dev Cancel an offer. Only offer owners can cancel their offer
    * @param _id The id of the offer to cancel
    */
    function cancelOffer(uint _id, address sender) public whenNotPaused {

        require(offersList[_id].seller == sender);
        offersList[_id].isActive = false;
        emit cancelOfferEvent(sender, offersList[_id].value);
        
    }

    function getOfferFromIndex(uint _index) public view returns(uint, address, bool) {
        require(offersList.length > _index);
        return (offersList[_index].value, offersList[_index].seller, offersList[_index].isActive);
    }
    
    function getOfferIndexesFromAddress() public view returns(uint[]) {
        return addressToOffersIndex[msg.sender];
    }
    function getOffersLength() public view returns(uint) {
        return offersList.length;
    }
      function updateUser(bytes ipfsHash) private returns(bool success)
  {
    return userStorage.updateUser(ipfsHash);
  }  

function createUser(bytes16 username, bytes ipfsHash) public returns(bool success)
  {
      return userStorage.createUser(username, ipfsHash);

  }
}
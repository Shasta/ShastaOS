pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

import "./User.sol";

 /**
  * @title ShastaMarketplace
  * Manage the storage of energy offers
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
    
    /** @dev Save a new energy offer.
      * @param _value the price of the unit of energy
      * @param _seller the address of the energy producer
      */
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

    /**
    * @dev Get offer by index
    * @param _index The index the offer to cancel
    * @return uint The energy unit price
    * @return address The seller address
    * @return bool The state of the offer
    */
    function getOfferFromIndex(uint _index) public view returns(uint, address, bool) {
        require(offersList.length > _index);
        return (offersList[_index].value, offersList[_index].seller, offersList[_index].isActive);
    }
    
    /**
    * @dev Get user offer indexes
    * @return uint[bool] The list of indexes
    */
    function getOfferIndexesFromAddress() public view returns(uint[]) {
        return addressToOffersIndex[msg.sender];
    }

    /**
    * @dev Get offers length
    * @return bool The length of the offers list
    */
    function getOffersLength() public view returns(uint) {
        return offersList.length;
    }
}
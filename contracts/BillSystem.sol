pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "zos-lib/contracts/migrations/Migratable.sol";
import "./libraries/ShastaTypes.sol";
import "./ContractRegistry.sol";
/**
 * @title BillSystem
 */

contract BillSystem is Ownable {

  address public contractRegistryAddress;
  ContractRegistry contractRegistry;

  ShastaTypes.Bill[] public bills;
  
  mapping(address => uint256[]) sellerBillIndex;
  mapping(address => uint256[]) consumerBillIndex;
  mapping(address => string) consumerMetadataIpfs;
  mapping(uint => bool) isBillPaid;
  // mapping of token addresses to mapping of account balances (token=0 means Ether)
  mapping (address => mapping (address => uint)) public balances; 

  event NewBill(address consumer, address seller, uint index);
  event Newseller(address seller);

  function setContractRegistry(address _contractRegistryAddress) public {
    contractRegistryAddress = _contractRegistryAddress;
    contractRegistry = ContractRegistry(_contractRegistryAddress);
  }

  function getBill(uint index) public view returns(
    uint256 whConsumed,
    address tokenAddress,
    address seller,
    address consumer,
    uint256 price,
    uint256 amount,
    string ipfsMetadata
  ) {
    ShastaTypes.Bill storage bill = bills[index];

    whConsumed = bill.whConsumed;
    tokenAddress = bill.tokenAddress;
    seller = bill.seller;
    consumer = bill.consumer;
    price = bill.price;
    amount = bill.amount;
    ipfsMetadata = bill.ipfsMetadata;
  }

  function getBillsLength() public view returns (uint length) {
    length = bills.length;
  }

  function getConsumerBillsLength(address _address) public view returns (uint length) {
    length = consumerBillIndex[_address].length;
  }

  function getSellerBillsLength(address _address) public view returns (uint length) {
    length = sellerBillIndex[_address].length;
  }

  function getBalance(address tokenAddress, address userAddress) public view returns(uint256 balance) {
    balance = balances[tokenAddress][userAddress];
  }

  function generateBill(uint wh, uint contractId, string ipfsMetadata) public returns(uint newIndex) {
    (address tokenAddress, address seller, address consumer, uint price, bool enabled) = ContractRegistry(contractRegistryAddress).getContractData(contractId);
    require(enabled == true, "Contract is not enabled.");
    newIndex = bills.push(
      ShastaTypes.Bill(
        wh,
        tokenAddress,
        seller,
        consumer,
        price,
        wh * price, // price must be Token/wattHour
        ipfsMetadata
      )
    ) - 1; // Array.push returns the new array length, so (new length - 1) == latest index.
    consumerBillIndex[consumer].push(newIndex);
    sellerBillIndex[seller].push(newIndex);
    emit NewBill(consumer, seller, newIndex);
  }

  function withdrawETH() public {
    uint256 allBalance = balances[address(0)][msg.sender];
    require(allBalance > 0,  "No balance left.");
    balances[address(0)][msg.sender] = 0;
    msg.sender.transfer(allBalance);
  }

  function withdrawERC20(address tokenAddress) public {
    require(tokenAddress != address(0), "Token address can not be zero. Reserved for ETH payments.");
    uint256 allBalance = balances[tokenAddress][msg.sender];
    require(allBalance > 0,  "No balance left.");
    balances[tokenAddress][msg.sender] = 0;
    require(IERC20(tokenAddress).transfer(msg.sender, allBalance), "Error while making ERC20 transfer");
  }

  function payBillETH(uint256 billIndex) public payable {
    ShastaTypes.Bill memory bill = bills[billIndex];
    require(bill.tokenAddress == address(0), "The ERC20 token is not the same as defined in the contract.");
    require(bill.consumer == msg.sender, "Bill is from consumer");
    require(bill.amount > 0, "Bill does not exists");
    require(bill.amount == msg.value, "Bill amount is not the same as the amount argument.");
    require(isBillPaid[billIndex] == false, "Bill is already paid.");
    isBillPaid[billIndex] = true;
    balances[address(0)][bill.seller] += msg.value;
  }

  function payBillERC20(address tokenAddress, address consumer, uint256 amount, uint256 billIndex) public {
    IERC20 tokenInstance = IERC20(tokenAddress);
    ShastaTypes.Bill memory bill = bills[billIndex];
    require(bill.tokenAddress == tokenAddress, "The ERC20 token is not the same as defined in the contract.");
    require(bill.consumer == consumer, "Bill is from consumer");
    require(bill.amount > 0, "Bill does not exists");
    require(bill.amount == amount, "Bill amount is not the same as the amount argument.");
    require(isBillPaid[billIndex] == false, "Bill is already paid.");
    // Add allowance requirement, for better error handling HERE
    tokenInstance.transferFrom(consumer, address(this), amount);
    isBillPaid[billIndex] = true;
    balances[tokenAddress][bill.seller] += amount;
  }
}
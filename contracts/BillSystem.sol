pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "zos-lib/contracts/migrations/Migratable.sol";
import "./libraries/ShastaTypes.sol";
import "./ContractRegistry.sol";

/**
 * @title BillSystem
 */
contract BillSystem is Ownable, Migratable {

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
  event BillPaid(uint index, address consumer, address seller);

  // Upgradeable contract pattern with initializer using zeppelinOS way.
  function initialize() public isInitializer("BillSystem", "0") {
  }

  /**
    * @dev Set the contract registry smart contract address
    * @param _contractRegistryAddress The contract registry address to set
    */
  function setContractRegistry(address _contractRegistryAddress) public {
    contractRegistryAddress = _contractRegistryAddress;
    contractRegistry = ContractRegistry(_contractRegistryAddress);
  }

  /**
    * @dev Get the bill data
    * @param index The bill index
    * @return whConsumed The watts/hour consumed in the bill
    * @return tokenAddress The ERC20 currency address that is used to pay the bill 
    * @return seller The seller/producer address
    * @return consumer The consumer address
    * @return price The unit price of one watt/hour
    * @return amount The amount of watt/hour consumed
    * @return ipfsMetadata Extra metadata that is appended to the bill, via IPFS hash
    */
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


  /**
    * @dev Get bills length
    * @return length The bills list length
    */
  function getBillsLength() public view returns (uint length) {
    length = bills.length;
  }

  /**
    * @dev Get consumer bill length
    * @param _address The consumer address
    * @return length The bills list length
    */
  function getConsumerBillsLength(address _address) public view returns (uint length) {
    length = consumerBillIndex[_address].length;
  }

  /**
    * @dev Get seller/producer bill length
    * @param _address The seller/producer address
    * @return length The bills list length
    */
  function getSellerBillsLength(address _address) public view returns (uint length) {
    length = sellerBillIndex[_address].length;
  }

  /**
    * @dev Get the ERC20/ETH balance from an address
    * @param tokenAddress The ERC20 smart contract address. If address is 0x it return the ETH balance. 
    * @param userAddress The ethereum address
    * @return balance The token/eth balance
    */
  function getBalance(address tokenAddress, address userAddress) public view returns(uint256 balance) {
    balance = balances[tokenAddress][userAddress];
  }

  /**
    * @dev Generates a new prepaid contract between a consumer and a producer
    * @param tokenAddress The ERC20 currency address that is used to pay the bill 
    * @param seller The seller/producer address
    * @param consumer The consumer address
    * @param price The unit price of one watt/hour
    * @param monthlyWh The watts/h of monthly consumption, estimated by the consumer
    * @param enabled The state of the contract
    * @param ipfsContractMetadata Extra metadata that is appended to the contract, via IPFS hash
    * @param ipfsBillMetadata Extra metadata that is appended to the bill, via IPFS hash
    */
  function newPrepaidContract(
    address tokenAddress,
    address seller,
    address consumer,
    uint price,
    uint monthlyWh,
    bool enabled,
    string ipfsContractMetadata,
    string ipfsBillMetadata
  ) public {
    uint newIndex = contractRegistry.newContract(tokenAddress, seller, consumer, price, monthlyWh, enabled, ipfsContractMetadata);
    uint newBillIndex = generateBill(monthlyWh, newIndex, ipfsBillMetadata);
    payBillERC20(newBillIndex);
  }

  /**
    * @dev Generates a new energy bill
    * @param wh The amount of watts/hour consumed during a timeframe 
    * @param contractId The contract index in the registry 
    * @param ipfsMetadata Extra metadata that is appended to the bill, via IPFS hash
    */
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

  /**
    * @dev Withdraw all the current ETH balance from the caller account
    */
  function withdrawETH() public {
    uint256 allBalance = balances[address(0)][msg.sender];
    require(allBalance > 0,  "No balance left.");
    balances[address(0)][msg.sender] = 0;
    msg.sender.transfer(allBalance);
  }

   /**
    * @dev Withdraw all the current ERC20 token balance from the caller account
    * @param tokenAddress The ERC20 smart contract address to transfer funds to the caller account 
    */
  function withdrawERC20(address tokenAddress) public {
    require(tokenAddress != address(0), "Token address can not be zero. Reserved for ETH payments.");
    uint256 allBalance = balances[tokenAddress][msg.sender];
    require(allBalance > 0,  "No balance left.");
    balances[tokenAddress][msg.sender] = 0;
    require(IERC20(tokenAddress).transfer(msg.sender, allBalance), "Error while making ERC20 transfer");
  }

  /**
    * @dev Pay a Shasta bill with ETH 
    * @param billIndex  The bill index
    */
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

  /**
    * @dev Pay a Shasta bill with ERC20. The ERC20 token to pay is determined in the contract between consumer and producer.
    * @param billIndex  The bill index
    */
  function payBillERC20(uint256 billIndex) public {
    ShastaTypes.Bill memory bill = bills[billIndex];
    require(bill.amount > 0, "Bill does not exists");
    require(bill.tokenAddress != address(0), "The ERC20 token address must not be 0x00.");
    require(isBillPaid[billIndex] == false, "Bill is already paid.");
    IERC20 tokenInstance = IERC20(bill.tokenAddress);
    // Add allowance requirement, for better error handling HERE
    tokenInstance.transferFrom(bill.consumer, address(this), bill.amount);
    isBillPaid[billIndex] = true;
    balances[bill.tokenAddress][bill.seller] += bill.amount;
    emit BillPaid(billIndex, bill.consumer, bill.seller);
  }
}
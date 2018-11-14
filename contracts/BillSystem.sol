pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "zos-lib/contracts/Initializable.sol";
import "./libraries/ShastaTypes.sol";
import "./libraries/strings.sol";
import "./Rounds.sol";

/**
 * @title BillSystem
 */
contract BillSystem is Ownable, Initializable {
  using strings for *;
  Rounds roundsRegistry;

  mapping(bytes32 => ShastaTypes.Bill) bills;
  mapping(bytes32 => bool) public isBillPaid;
  // mapping of token addresses to mapping of account balances (token=0 means Ether)
  mapping (address => mapping (address => uint)) public balances; 

  event NewBill(bytes32 billId);
  event BillPaid(bytes32 billId);

  // Upgradeable contract pattern with initializer using zeppelinOS way.
  function initialize() public initializer {
  }

function verifyMerkle(
    bytes32[] proof,
    bytes32 root,
    bytes32 leaf
  )
    public
    pure
    returns (bool)
  {
    bytes32 computedHash = leaf;

    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (computedHash < proofElement) {
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }

    return computedHash == root;
  }
  /**
    * @dev Set the contract registry smart contract address
    * @param _contractRegistryAddress The contract registry address to set
    */
  function setRoundsRegistry(address roundsRegistryAddress) public {
    roundsRegistry = Rounds(roundsRegistryAddress);
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
  function getBill(bytes32 billId) public view returns(
    uint256 whConsumed,
    address tokenAddress,
    address consumer,
    uint256 price,
    uint256 amount,
    string ipfsMetadata
  ) {
    ShastaTypes.Bill storage bill = bills[billId];

    whConsumed = bill.whConsumed;
    tokenAddress = bill.tokenAddress;
    consumer = bill.consumer;
    price = bill.price;
    amount = bill.amount;
    ipfsMetadata = bill.ipfsMetadata;
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
    * @dev Generates a new bill contract 
    * @param tokenAddress The ERC20 currency address that is used to pay the bill 
    * @param seller The seller/producer address
    * @param consumer The consumer address
    * @param price The unit price of one watt/hour
    * @param monthlyWh The watts/h of monthly consumption, estimated by the consumer
    * @param enabled The state of the contract
    * @param ipfsContractMetadata Extra metadata that is appended to the contract, via IPFS hash
    * @param ipfsBillMetadata Extra metadata that is appended to the bill, via IPFS hash
    */
  function generateAndPayBill(
    string ipfsBillMetadata,
    uint token_amount,
    bytes32 leaf,
    bytes32 proofs,
    uint round
  ) public {
    generateBill(billHash, consumed, ipfsBillMetadata);
    payBillERC20(billHash);
  }

  /**
    * @dev Generates a keccak256 concatenating ipfs_bill_hash + "," + consumed
    * @param ipfsBillMetadata The ipfs hash string of a bill
    * @param token_amount The amount of watts consumed
    * @return bytes32  The resulting keccak256 hash
    */
  function generateBillHash(string ipfsBillMetadata, uint token_amount) internal returns (bytes32) {
    string stringAmount = string(bytes32(token_amount));
    string billIdString = ipfsBillMetadata.toSlice().concat(",".toSlice()).concat(stringAmount.toSlice());
    return keccak256(bytes(billIdString));
  }

  /**
    * @dev Generates a new energy bill
    * @param ipfsBillMetadata The ipfs hash
    * @param tokenAmount The token amount
    * @param round The round to verify the bill and inherit his state
    * @return bytes32 Returns the bill
    */
  function generateBill(string ipfsBillMetadata, uint tokenAmount, bytes32 leaf, bytes proofs, uint round) public returns(bytes32) {
    bytes32 billHash = generateBillHash(ipfsBillMetadata, tokenAmount);
    /**
      * TODO:
      * 1. Verify billHash == leaf  (OK)
      * 2. Grab round. Check if round is activated. (OK)
      * 3. Verify billHash is inside round bills merkle root, with the given proofs
      * 4. If OK, inherit the round state and store the bill reference
      */
    require(billHash == leaf, "Bill hash should be equal than leaf hash");
    (
      uint stage,
      uint energyPrice,
      address tokenAddress,
      bytes32 billingRoot
    ) = ggetRoundForBilling(round);
    require(stage == 1, "Round must be activated");
    require(verifyMerkle() == true, "Bill is not included in the Merkle tree.");
    bills[billHash] = ShastaTypes.Bill(
      tokenAddress, // If tokenAddress 0x00 == ETHER as payment
      energyPrice,
      tokenAmount,
      round,
      ipfsBillMetadata,
      true
    );
    emit NewBill(billHash);
    return billHash;
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
  function payBillETH(bytes32 billId) public payable {
    ShastaTypes.Bill memory bill = bills[billId];
    require(bill.tokenAddress == address(0), "The ERC20 token is not the same as defined in the contract.");
    require(bill.amount > 0, "Bill can not be zero amount");
    require(bill.amount == msg.value, "Bill amount is not the same as the amount argument.");
    require(isBillPaid[billId] == false, "Bill is already paid.");
    isBillPaid[billId] = true;
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
pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "zos-lib/contracts/Initializable.sol";
import "./libraries/ShastaTypes.sol";
import "./libraries/strings.sol";
import "./libraries/MerkleUtils.sol";
import "./libraries/BytesUtils.sol";
import "./Rounds.sol";
/**
 * @title BillSystem
 */
contract BillSystem is Ownable, Initializable {
  using strings for *;
  Rounds roundsRegistry;

  mapping(bytes32 => ShastaTypes.Bill) bills;
  mapping(bytes32 => bool) public isBillPaid;
  // mapping of round number to round balances
  mapping (uint => mapping(address => uint)) public roundBalances; 
  mapping (uint => bytes32) public roundBills;

  event NewBill(bytes32 billId, string ipfsMetadata);
  event BillPaid(bytes32 billId, string ipfsMetadata);

  // Upgradeable contract pattern with initializer using zeppelinOS way.
  function initialize() public initializer {
  }

  /**
    * @dev Set the rounds registry smart contract address
    * @param roundsRegistryAddress The round registry address to set
    */
  function setRoundsRegistry(address roundsRegistryAddress) public {
    roundsRegistry = Rounds(roundsRegistryAddress);
  }

  /**
    * @dev Get the bill data
    * @param billId The bill id
    * @return whConsumed The watts/hour consumed in the bill
    * @return tokenAddress The ERC20 currency address that is used to pay the bill 
    * @return seller The seller/producer address
    * @return consumer The consumer address
    * @return price The unit price of one watt/hour
    * @return amount The amount of watt/hour consumed
    * @return ipfsMetadata Extra metadata that is appended to the bill, via IPFS hash
    */
  function getBill(bytes32 billId) public view returns(
    address tokenAddress,
    uint256 price,
    uint256 amount,
    string ipfsMetadata,
    uint round,
    address payer
  ) {
    ShastaTypes.Bill storage bill = bills[billId];
    tokenAddress = bill.tokenAddress;
    price = bill.price;
    amount = bill.amount;
    ipfsMetadata = bill.ipfsMetadata;
    round = bill.round;
    payer = bill.payer;
  }


  /**
    * @dev Get the ERC20/ETH balance from an address
    * @param tokenAddress The ERC20 smart contract address. If address is 0x it return the ETH balance. 
    * @param round The round index
    * @param userAddress The ethereum address
    * @return balance The token/eth balance
    */
  function getBalance(address tokenAddress, uint round, address userAddress) public view returns(uint256 balance) {
    return 0; // TODO: producers withdrawal docs
  }

  /**
    * @dev Generates a new bill and pays it (Only ERC20) 
    * @param ipfsBillMetadata The IPFS hash that stores the bill metadata
    * @param tokenAmount The amount of tokens of the bill
    * @param proofs An array of merkle proofs in bytes32
    * @param round The round index to generate the bill
    */
  function generateAndPayBillERC20(
    string ipfsBillMetadata,
    uint tokenAmount,
    bytes32[] proofs,
    uint round,
    address payer
  ) public {
    bytes32 billHash = generateBill(ipfsBillMetadata, tokenAmount, proofs, round);
    payBillERC20(billHash, payer);
  }


   /**
    * @dev Generates a new bill and pays it (Only ETH)
    * @param ipfsBillMetadata The IPFS hash that stores the bill metadata
    * @param tokenAmount The amount of tokens of the bill
    * @param proofs An array of merkle proofs in bytes32
    * @param round The round index to generate the bill
    */
  function generateAndPayBillETH(
    string ipfsBillMetadata,
    uint tokenAmount,
    bytes32[] proofs,
    uint round
  ) public {
    bytes32 billHash = generateBill(ipfsBillMetadata, tokenAmount, proofs, round);
    payBillETH(billHash);
  }

  /**
    * @dev Generates a keccak256 concatenating ipfs_bill_hash + "," + consumed
    * @param ipfsBillMetadata The ipfs hash string of a bill
    * @param tokenAmount The amount of watts consumed
    * @return bytes32  The resulting keccak256 hash
    */
  function generateBillHash(string memory ipfsBillMetadata, uint tokenAmount) internal pure returns (bytes32) {
    return keccak256(
      bytes(
        ipfsBillMetadata.toSlice()
        .concat(",".toSlice()).toSlice()
        .concat(
          BytesUtils.bytes32ToString(
            bytes32(tokenAmount)
          )
          .toSlice()
        )
      )
    );
  }

  /**
    * @dev Generates a new energy bill
    * @param ipfsBillMetadata The ipfs hash
    * @param tokenAmount The token amount
    * @param proofs The proofs in array bytes32 format
    * @param round The round to verify the bill and inherit his state
    * @return bytes32 Returns the bill
    */
  function generateBill(string ipfsBillMetadata, uint tokenAmount, bytes32[] proofs, uint round) public returns(bytes32) {
    require(address(roundsRegistry) != address(0), "Rounds registry instance is not set");
    bytes32 billHash = generateBillHash(ipfsBillMetadata, tokenAmount);
    (
      uint stage,
      uint energyPrice,
      address tokenAddress,
      bytes32 billingRoot
    ) = roundsRegistry.getRoundForBilling(round);
    require(stage == 1, "Round must be activated");
    require(MerkleUtils.verifyMerkle(proofs, billingRoot, billHash) == true, "Bill is not included in the Merkle tree.");
    bills[billHash] = ShastaTypes.Bill(
      tokenAddress, // If tokenAddress 0x00 == ETHER as payment
      energyPrice,
      tokenAmount,
      round,
      ipfsBillMetadata,
      true,
      address(0)
    );
    roundBills[round] = billHash;
    emit NewBill(billHash, ipfsBillMetadata);
    return billHash;
  }

  /**
    * @dev Withdraw all the current ETH balance from the caller account
    */
  function withdrawETH(uint round) public {
    return; // TODO: Do producers withdrawal documentation
  }

   /**
    * @dev Withdraw all the current ERC20 token balance from the caller account
    * @param tokenAddress The ERC20 smart contract address to transfer funds to the caller account 
    * @param round The number of the round to withdraw
    */
  function withdrawERC20(address tokenAddress, uint round) public {
    return; // TODO: Do producers withdrawal documentation
  }

  /**
    * @dev Pay a Shasta bill with ETH 
    * @param billHash  The bill hash
    */
  function payBillETH(bytes32 billHash) public payable {
    require(address(roundsRegistry) != address(0), "Rounds registry instance is not set");
    ShastaTypes.Bill memory bill = bills[billHash];
    require(bill.tokenAddress == address(0), "The ERC20 token is not the same as defined in the contract.");
    require(bill.amount > 0, "Bill can not be zero amount");
    require(bill.amount == msg.value, "Bill amount is not the same as the amount argument.");
    require(isBillPaid[billHash] == false, "Bill is already paid.");
    roundBalances[bill.round][address(0)] += msg.value;
    isBillPaid[billHash] = true;
    bills[billHash].payer = msg.sender;
    emit BillPaid(billHash, bill.ipfsMetadata);
  }

  /**
    * @dev Pay a Shasta bill with ERC20. The ERC20 token to pay is determined in the contract between consumer and producer.
    * @param billHash  The bill hash
    */
  function payBillERC20(bytes32 billHash, address payer) public {
    require(payer != address(0), "0x address is banned to pay with ERC20");
    require(address(roundsRegistry) != address(0), "Rounds registry instance is not set");
    ShastaTypes.Bill memory bill = bills[billHash];
    require(bill.amount > 0, "Bill does not exists");
    require(bill.tokenAddress != address(0), "The ERC20 token address must not be 0x00.");
    require(isBillPaid[billHash] == false, "Bill is already paid.");
    IERC20 tokenInstance = IERC20(bill.tokenAddress);
    // Make the approved transfer and be sure that this smart contract have the correct balance after transfer
    uint256 currentBalance = IERC20(bill.tokenAddress).balanceOf(address(this));
    tokenInstance.transferFrom(payer, address(this), bill.amount);
    require(
      (currentBalance + bill.amount) == IERC20(bill.tokenAddress).balanceOf(address(this)),
      "Contract balance did not change correctly"
    );
    // After transfer, point the new balance and make the bill as paid
    roundBalances[bill.round][bill.tokenAddress] += bill.amount;
    isBillPaid[billHash] = true;
    bills[billHash].payer = payer;
    emit BillPaid(billHash, bill.ipfsMetadata);
  }

  function getRoundBillsLength(uint round) public view returns(uint) {
    return roundBills[round].length;
  }
}
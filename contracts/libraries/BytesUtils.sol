pragma solidity ^0.4.23;

library BytesUtils {
  function bytes32ToBytes(bytes32 _bytes32) public pure returns (bytes){
    // string memory str = string(_bytes32);
    // TypeError: Explicit type conversion not allowed from "bytes32" to "string storage pointer"
    bytes memory bytesArray = new bytes(32);
    for (uint256 i; i < 32; i++) {
      bytesArray[i] = _bytes32[i];
    }
    return bytesArray;
  }

  function bytes32ToString(bytes32 _bytes32) public pure returns (string){
    bytes memory bytesArray = bytes32ToBytes(_bytes32);
    return string(bytesArray);
  }
}
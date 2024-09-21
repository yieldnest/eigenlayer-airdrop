// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

contract EigenAirdrop {
    mapping(address userAddress => uint256 points)public userPoints;
    
    function id(uint256 value) external pure returns (uint256) {
        return value;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

interface IStrategyManager {
    function domainSeparator() external view returns (bytes32);
}

struct Deposit {
    address staker;
    address strategy;
    address token;
    uint256 amount;
    uint256 nonce;
    uint256 expiry;
}

library SigUtils {
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    bytes32 public constant DEPOSIT_TYPEHASH = keccak256(
        "Deposit(address staker,address strategy,address token,uint256 amount,uint256 nonce,uint256 expiry)"
    );

    function getDepositStructHash(Deposit memory _deposit) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                DEPOSIT_TYPEHASH,
                _deposit.staker,
                _deposit.strategy,
                _deposit.token,
                _deposit.amount,
                _deposit.nonce,
                _deposit.expiry
            )
        );
    }

    function getDepositDigest(address strategyManager, Deposit memory _deposit) public view returns (bytes32) {
        bytes32 domainSeparator = IStrategyManager(strategyManager).domainSeparator();
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, getDepositStructHash(_deposit)));
    }
}

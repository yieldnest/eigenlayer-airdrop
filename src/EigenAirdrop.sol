// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import { OwnableUpgradeable } from "@openzeppelin-upgradeable-v5.0.2/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin-upgradeable-v5.0.2/utils/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin-upgradeable-v5.0.2/utils/ReentrancyGuardUpgradeable.sol";
import { IERC20 } from "@openzeppelin-v5.0.2/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin-v5.0.2/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin-v5.0.2/utils/math/Math.sol";

import {
    IERC20 as IStrategyToken,
    IStrategy,
    IStrategyManager
} from "eigenlayer-contracts/interfaces/IStrategyManager.sol";

import { IEigenAirdrop, UserAmount } from "./IEigenAirdrop.sol";

/**
 * @title EigenAirdrop
 * @dev A contract that manages token airdrops and allows users to claim and restake tokens.
 */
contract EigenAirdrop is IEigenAirdrop, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using Math for uint256;

    /// @notice Stores the claimable amounts for each user.
    mapping(address user => uint256 amount) public amounts;

    /// @notice The total amount of tokens available for the airdrop.
    uint256 public totalAmount;

    /// @notice Address of the safe that holds the tokens.
    address public safe;

    /// @notice The token being airdropped.
    IERC20 public token;

    /// @notice The strategy where tokens can be restaked.
    IStrategy public strategy;

    /// @notice The strategy manager responsible for managing the strategy.
    IStrategyManager public strategyManager;

    /**
     * @dev Modifier to check if the user can claim the specified amount.
     * Reverts if the amount is zero or exceeds the claimable balance.
     * @param _amountToClaim The amount the user is trying to claim.
     */
    modifier whenAvailable(uint256 _amountToClaim) {
        if (_amountToClaim == 0 || _amountToClaim > amounts[msg.sender]) {
            revert NoAirdrop();
        }
        _;
    }

    /**
     * @dev Disables initializers to prevent contract from being reinitialized.
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the airdrop contract with the provided parameters.
     * @param _owner The address of the owner.
     * @param _safe The address of the safe holding the tokens.
     * @param _token The address of the token being airdropped.
     * @param _strategy The address of the strategy for restaking.
     * @param _strategyManager The address of the strategy manager.
     * @param _userAmounts An array of user amounts for the airdrop.
     */
    function initialize(
        address _owner,
        address _safe,
        address _token,
        address _strategy,
        address _strategyManager,
        UserAmount[] calldata _userAmounts
    )
        public
        initializer
    {
        __Pausable_init();
        __Ownable_init(_owner);
        __ReentrancyGuard_init();

        if (
            _safe == address(0) || _token == address(0) || _strategy == address(0)
                || _strategyManager == address(0)
        ) {
            revert InvalidInit();
        }

        safe = _safe;
        token = IERC20(_token);
        strategy = IStrategy(_strategy);
        strategyManager = IStrategyManager(_strategyManager);

        _updateUserAmounts(_userAmounts);
    }

    /**
     * @notice Pauses the contract, preventing claims.
     * Can only be called by the owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpauses the contract, allowing claims.
     * Can only be called by the owner.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Updates user amount for the airdrop. Only callable by the owner when the contract is paused.
     * @param _userAmounts An array of updated user amount.
     */
    function updateUserAmounts(UserAmount[] calldata _userAmounts) external onlyOwner whenPaused {
        _updateUserAmounts(_userAmounts);
    }

    /**
     * @dev Internal function to update user amount and recalculate claimable amounts.
     * @param _userAmounts An array of updated user amount.
     */
    function _updateUserAmounts(UserAmount[] calldata _userAmounts) internal {
        uint256 _totalAmount = totalAmount;
        for (uint256 i; i < _userAmounts.length; i++) {
            if (amounts[_userAmounts[i].user] > 0) {
                _totalAmount -= amounts[_userAmounts[i].user];
            }
            _totalAmount += _userAmounts[i].amount;
            amounts[_userAmounts[i].user] = _userAmounts[i].amount;
        }

        uint256 safeBalance = token.balanceOf(safe);
        if (safeBalance == 0 || _totalAmount > safeBalance) {
            revert InvalidAirdrop();
        }
        totalAmount = _totalAmount;
    }

    /**
     * @notice Claims the specified amount of tokens from the airdrop.
     * @param _amountToClaim The amount of tokens to claim.
     */
    function claim(uint256 _amountToClaim)
        external
        virtual
        override
        nonReentrant
        whenNotPaused
        whenAvailable(_amountToClaim)
    {
        token.safeTransferFrom(safe, msg.sender, _amountToClaim);
        amounts[msg.sender] -= _amountToClaim;
        totalAmount -= _amountToClaim;
        emit Claimed(msg.sender, _amountToClaim);
    }

    /**
     * @notice Claims and restakes the specified amount of tokens using a signature.
     * @param _amountToClaim The amount of tokens to claim.
     * @param _expiry The expiry time of the signature.
     * @param signature The user's signature authorizing the restaking.
     */
    function claimAndRestakeWithSignature(
        uint256 _amountToClaim,
        uint256 _expiry,
        bytes calldata signature
    )
        external
        virtual
        override
        nonReentrant
        whenNotPaused
        whenAvailable(_amountToClaim)
        returns (uint256 shares)
    {
        token.safeTransferFrom(safe, address(this), _amountToClaim);
        token.approve(address(strategyManager), _amountToClaim);
        shares = strategyManager.depositIntoStrategyWithSignature(
            strategy, IStrategyToken(address(token)), _amountToClaim, msg.sender, _expiry, signature
        );
        amounts[msg.sender] -= _amountToClaim;
        totalAmount -= _amountToClaim;
        emit ClaimedAndRestaked(msg.sender, _amountToClaim, shares);
    }
}

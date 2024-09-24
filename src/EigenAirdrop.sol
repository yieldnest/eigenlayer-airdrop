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

struct UserAmount {
    address user;
    uint256 amount;
}

/**
 * @title IEigenAirdrop
 * @dev Interface for EigenAirdrop contract with methods to claim and restake tokens.
 */
interface IEigenAirdrop {
    /**
     * @notice Claim tokens from the airdrop.
     * @param _amountToClaim Amount of tokens to claim.
     */
    function claim(uint256 _amountToClaim) external;

    /**
     * @notice Claim tokens from the airdrop and restake them using a signature.
     * @param _amountToClaim Amount of tokens to claim.
     * @param expiry The expiry time of the signature.
     * @param signature The user's signature authorizing the restaking.
     */
    function claimAndRestakeWithSignature(
        uint256 _amountToClaim,
        uint256 expiry,
        bytes calldata signature
    )
        external
        returns (uint256);
}

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

    /// @notice the timestamp on which the claims are no longer valid
    uint256 public deadline;

    /// @notice Address of the safe that holds the tokens.
    address public safe;

    /// @notice The token being airdropped.
    IERC20 public token;

    /// @notice The strategy where tokens can be restaked.
    IStrategy public strategy;

    /// @notice The strategy manager responsible for managing the strategy.
    IStrategyManager public strategyManager;

    /// @notice Emitted when a user claims tokens from the airdrop.
    /// @param user The address of the user claiming tokens.
    /// @param amount The amount of tokens claimed.
    event Claimed(address user, uint256 amount);

    /// @notice Emitted when a user claims and restakes tokens.
    /// @param user The address of the user.
    /// @param amount The amount of tokens restaked.
    /// @param shares The amount of shares received from restaking.
    event ClaimedAndRestaked(address user, uint256 amount, uint256 shares);

    /// @notice Error thrown when there is no airdrop available.
    error NoAirdrop();
    error InvalidAirdrop();
    error DeadlinePassed();
    error InvalidInit();

    /**
     * @dev Modifier to check if the user can claim the specified amount.
     * Reverts if the amount is zero or exceeds the claimable balance.
     * @param _amountToClaim The amount the user is trying to claim.
     */
    modifier whenAvailable(uint256 _amountToClaim) {
        if(block.timestamp > deadline) {
            revert DeadlinePassed();
        }
        if (_amountToClaim == 0 || _amountToClaim > amounts[msg.sender]) {
            revert NoAirdrop();
        }
        _;
        amounts[msg.sender] -= _amountToClaim;
        totalAmount -= _amountToClaim;
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
     * @param _userAmounts An array of user amount for token distribution.
     */
    function initialize(
        address _owner,
        address _safe,
        address _token,
        address _strategy,
        address _strategyManager,
        uint256 _deadline,
        UserAmount[] memory _userAmounts
    )
        public
        initializer
    {
        __Pausable_init();
        __Ownable_init(_owner);
        __ReentrancyGuard_init();
        safe = _safe;
        deadline = _deadline;
        token = IERC20(_token);
        strategy = IStrategy(_strategy);
        strategyManager = IStrategyManager(_strategyManager);
        _updateUserAmounts(_userAmounts);
        
        if(deadline == 0 ||
         safe == address(0) ||
         address(token) == address(0) ||
         address(strategy) == address(0) ||
         address(strategyManager) == address(0)){
            revert InvalidInit();
        }
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
    function updateUserAmounts(UserAmount[] memory _userAmounts) external onlyOwner whenPaused {
        _updateUserAmounts(_userAmounts);
    }

    /**
     * @dev Internal function to update user amount and recalculate claimable amounts.
     * @param _userAmounts An array of updated user amount.
     */
    function _updateUserAmounts(UserAmount[] memory _userAmounts) internal {
        for (uint256 i; i < _userAmounts.length; i++) {
            if(amounts[_userAmounts[i].user] != 0){
                totalAmount -= amounts[_userAmounts[i].user];
            }

            totalAmount += _userAmounts[i].amount;
            amounts[_userAmounts[i].user] += _userAmounts[i].amount;
        }

        uint256 safeBalance = token.balanceOf(safe);
        if (safeBalance == 0 || totalAmount > safeBalance) {
            revert NoAirdrop();
        }
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
        emit ClaimedAndRestaked(msg.sender, _amountToClaim, shares);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IStrategy, IStrategyManager } from "eigenlayer-contracts/interfaces/IStrategyManager.sol";

import { ISignatureUtils } from "eigenlayer-contracts/interfaces/ISignatureUtils.sol";

/**
 * @title UserAmount
 * @dev Struct representing a user and their claimable token amount.
 * @param user The address of the user eligible for the airdrop.
 * @param amount The amount of tokens claimable by the user.
 */
struct UserAmount {
    address user;
    uint256 amount;
}

/**
 * @title IEigenAirdrop
 * @dev Interface for EigenAirdrop contract with methods to claim and restake tokens, as well as getter functions
 * for public variables.
 */
interface IEigenAirdrop {
    /**
     * @notice Claim tokens from the airdrop.
     * @param _amountToClaim Amount of tokens to claim.
     */
    function claim(uint256 _amountToClaim) external;

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
        external;

    /**
     * @notice Claim tokens from the airdrop and restake them using a signature.
     * @param _amountToClaim Amount of tokens to claim.
     * @param _expiry The expiry time of the signature.
     * @param _signature The user's signature authorizing the restaking.
     */
    function claimAndRestakeWithSignature(
        uint256 _amountToClaim,
        uint256 _expiry,
        bytes calldata _signature
    )
        external
        returns (uint256);

    /**
     * @notice Claims and restakes the specified amount of tokens using a signature and delegates to another
     * address.
     * @param _amountToClaim The amount of tokens to claim.
     * @param _expiry The expiry time of the signature.
     * @param _signature The user's signature authorizing the restaking.
     * @param _operator The address to delegate the voting power to.
     * @param _stakerSignatureAndExpiry The signature and expiry of the staker.
     * @param _approverSignatureAndExpiry The signature and expiry of the approver.
     * @param _approverSalt The salt used for the approver signature.
     * @return shares The amount of shares received from restaking.
     */
    function claimAndRestakeWithSignatureAndDelegate(
        uint256 _amountToClaim,
        uint256 _expiry,
        bytes calldata _signature,
        address _operator,
        ISignatureUtils.SignatureWithExpiry memory _stakerSignatureAndExpiry,
        ISignatureUtils.SignatureWithExpiry memory _approverSignatureAndExpiry,
        bytes32 _approverSalt
    )
        external
        returns (uint256 shares);

    /**
     * @notice Pauses the contract, preventing claims.
     */
    function pause() external;

    /**
     * @notice Unpauses the contract, allowing claims.
     */
    function unpause() external;

    /**
     * @notice Updates user amounts for the airdrop.
     * @param _userAmounts An array of user amounts for the airdrop.
     */
    function updateUserAmounts(UserAmount[] calldata _userAmounts) external;

    /**
     * @notice Returns the address of the safe holding the tokens.
     * @return The safe address.
     */
    function safe() external view returns (address);

    /**
     * @notice Returns the address of the token being airdropped.
     * @return The token address.
     */
    function token() external view returns (IERC20);

    /**
     * @notice Returns the address of the strategy where tokens can be restaked.
     * @return The strategy address.
     */
    function strategy() external view returns (IStrategy);

    /**
     * @notice Returns the address of the strategy manager.
     * @return The strategy manager address.
     */
    function strategyManager() external view returns (IStrategyManager);

    /// @notice Emitted when a user claims tokens from the airdrop.
    /// @param user The address of the user claiming tokens.
    /// @param amount The amount of tokens claimed.
    event Claimed(address user, uint256 amount);

    /// @notice Emitted when a user claims and restakes tokens.
    /// @param user The address of the user.
    /// @param amount The amount of tokens restaked.
    /// @param shares The amount of shares received from restaking.
    event ClaimedAndRestaked(address user, uint256 amount, uint256 shares);

    /// @notice Emitted when a user claims, restakes tokens, and delegates.
    /// @param user The address of the user.
    /// @param amount The amount of tokens claimed and restaked.
    /// @param shares The amount of shares received from restaking.
    /// @param operator The address of the operator delegated to.
    event ClaimedAndRestakedAndDelegated(address user, uint256 amount, uint256 shares, address operator);

    /**
     * @notice Thrown when no airdrop exists for the user.
     */
    error NoAirdrop();

    /**
     * @notice Thrown when the airdrop data is invalid (e.g., token amounts or addresses are incorrect).
     */
    error InvalidAirdrop();

    /**
     * @notice Thrown when the contract initialization is invalid due to missing or incorrect parameters.
     */
    error InvalidInit();
}

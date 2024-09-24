// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { OwnableUpgradeable } from "@openzeppelin-upgradeable-v5.0.2/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin-upgradeable-v5.0.2/utils/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin-upgradeable-v5.0.2/utils/ReentrancyGuardUpgradeable.sol";
import { IERC20 } from "@openzeppelin-v5.0.2/token/ERC20/IERC20.sol";
import { IERC20Permit } from "@openzeppelin-v5.0.2/token/ERC20/extensions/IERC20Permit.sol";
import { SafeERC20 } from "@openzeppelin-v5.0.2/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin-v5.0.2/utils/math/Math.sol";

import {
    IERC20 as IStrategyToken,
    IStrategy,
    IStrategyManager
} from "eigenlayer-contracts/interfaces/IStrategyManager.sol";

struct UserPoints {
    address user;
    uint256 points;
}

interface IEigenAirdrop {
    function claim(uint256 _amountToClaim) external;
    function claimWithPermit(
        uint256 _amountToClaim,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external;
    function claimAndRestakeWithSignature(
        uint256 _amountToClaim,
        uint256 expiry,
        bytes calldata signature
    )
        external;
}

contract EigenAirdrop is IEigenAirdrop, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using Math for uint256;

    mapping(address userAddress => uint256 amount) public amounts;
    uint256 public totalPoints;
    address public safe;
    IERC20 public token;
    IStrategy public strategy;
    IStrategyManager public strategyManager;

    event AirdropClaimed(address user, uint256 amount);
    event AirdropClaimedAndRestaked(address user, uint256 amount);

    error NoAirdrop();

    modifier canClaim(uint256 _amountToClaim) {
        if (_amountToClaim == 0 || _amountToClaim > amounts[msg.sender]) {
            revert NoAirdrop();
        }
        _;
        amounts[msg.sender] -= _amountToClaim;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _owner,
        address _safe,
        address _token,
        address _strategy,
        address _strategyManager,
        UserPoints[] memory _userPoints
    )
        public
        initializer
    {
        __Pausable_init();
        __Ownable_init(_owner);
        __ReentrancyGuard_init();
        safe = _safe;
        token = IERC20(_token);
        strategy = IStrategy(_strategy);
        strategyManager = IStrategyManager(_strategyManager);
        _updateUserPoints(_userPoints);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function updateUserPoints(UserPoints[] memory _userPoints) external onlyOwner whenPaused {
        _updateUserPoints(_userPoints);
    }

    function _updateUserPoints(UserPoints[] memory _userPoints) internal {
        uint256 initialMultiSigBalance = token.balanceOf(safe);
        if (initialMultiSigBalance == 0) {
            revert NoAirdrop();
        }

        totalPoints = 0;
        for (uint256 i; i < _userPoints.length; i++) {
            totalPoints += _userPoints[i].points;
        }

        for (uint256 i; i < _userPoints.length; i++) {
            amounts[_userPoints[i].user] = _userPoints[i].points.mulDiv(initialMultiSigBalance, totalPoints);
        }
    }

    function claim(uint256 _amountToClaim) external virtual override nonReentrant whenNotPaused {
        _claim(_amountToClaim);
    }

    function claimWithPermit(
        uint256 _amountToClaim,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
        virtual
        override
        nonReentrant
        whenNotPaused
    {
        IERC20Permit(address(token)).permit(msg.sender, address(this), _amountToClaim, _deadline, _v, _r, _s);
        _claim(_amountToClaim);
    }

    function _claim(uint256 _amountToClaim) internal canClaim(_amountToClaim) {
        token.safeTransferFrom(safe, msg.sender, _amountToClaim);
        emit AirdropClaimed(msg.sender, _amountToClaim);
    }

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
    {
        _claimAndRestakeWithSignature(_amountToClaim, _expiry, signature);
    }

    function _claimAndRestakeWithSignature(
        uint256 _amountToClaim,
        uint256 _expiry,
        bytes calldata signature
    )
        internal
        canClaim(_amountToClaim)
    {
        token.safeTransferFrom(safe, address(this), _amountToClaim);
        strategyManager.depositIntoStrategyWithSignature(
            strategy, IStrategyToken(address(token)), _amountToClaim, msg.sender, _expiry, signature
        );
        emit AirdropClaimedAndRestaked(msg.sender, _amountToClaim);
    }
}

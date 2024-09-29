// SPDX-License-Identifier: BSD 3-Clause License
pragma solidity >=0.8.25 <0.9.0;

import { Test } from "forge-std/Test.sol";
import { EigenAirdrop } from "../../src/EigenAirdrop.sol";
import { IEigenAirdrop } from "../../src/IEigenAirdrop.sol";
import { TransparentUpgradeableProxy } from "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import { ITransparentUpgradeableProxy } from "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

import { Utils } from "../../script/Utils.sol";

contract UpgradeabilityTest is Test, Utils {
    address constant YN_DEV_MAINNET = 0xa08F39d30dc865CC11a49b6e5cBd27630D6141C3;
    address constant EIGEN_AIRDROP_PROXY = 0xd3DBC68e84921c60C430938256978188FF55a4e0;
    address constant PROXY_ADMIN = 0xC91B54d017a0089aD81c30dbCA8dFDE967F20418;

    EigenAirdrop public eigenAirdrop;
    ProxyAdmin public proxyAdmin;
    address public owner;

    function setUp() public {
        // Fork mainnet
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        // Set up the contracts
        eigenAirdrop = EigenAirdrop(EIGEN_AIRDROP_PROXY);
        proxyAdmin = ProxyAdmin(PROXY_ADMIN);
        owner = YN_DEV_MAINNET;

    }

    function testUpgradeAndFunctionality() public {
        address newEigenAirdropImpl = address(new EigenAirdrop());
        vm.prank(YN_DEV_MAINNET);
        ProxyAdmin(getTransparentUpgradeableProxyAdminAddress(address(eigenAirdrop))).upgradeAndCall(ITransparentUpgradeableProxy(address(eigenAirdrop)), newEigenAirdropImpl, "");
        
        address currentEigenAirdropImpl = getTransparentUpgradeableProxyImplementationAddress(address(eigenAirdrop));
        assertEq(currentEigenAirdropImpl, newEigenAirdropImpl);

        vm.startPrank(YN_DEV_MAINNET);
        // Test pause functionality
        eigenAirdrop.pause();
        assertTrue(eigenAirdrop.paused(), "Contract should be paused");

        // Test unpause functionality
        eigenAirdrop.unpause();
        assertFalse(eigenAirdrop.paused(), "Contract should be unpaused");

        vm.stopPrank();
    }

    function testOwnershipTransfer() public {
        // Check initial owner
        assertEq(eigenAirdrop.owner(), YN_DEV_MAINNET, "Initial owner should be YN_DEV_MAINNET");

        address newOwner = address(0x123);

        // Attempt to transfer ownership from non-owner account (should fail)
        vm.prank(address(0xdead));
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(0xdead)));
        eigenAirdrop.transferOwnership(newOwner);

        // Transfer ownership from current owner
        vm.prank(YN_DEV_MAINNET);
        eigenAirdrop.transferOwnership(newOwner);

        // Check that ownership has been transferred
        assertEq(eigenAirdrop.owner(), newOwner, "Ownership should be transferred to new owner");

        // Verify that old owner can no longer perform owner-only actions
        vm.prank(YN_DEV_MAINNET);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, YN_DEV_MAINNET));
        eigenAirdrop.pause();

        // Verify that new owner can perform owner-only actions
        vm.prank(newOwner);
        eigenAirdrop.pause();
        assertTrue(eigenAirdrop.paused(), "New owner should be able to pause the contract");
    }
}

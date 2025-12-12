// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {console2} from "forge-std/console2.sol";
import "../src/ReACT_Protocol.sol";
import "../src/ReACT_Hook.sol";
import "../src/RLIQToken.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {MockERC20} from "@uniswap/v4-core/lib/forge-std/src/mocks/MockERC20.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";

contract ReactTest is Test {
    ReactProtocol public react;

    address activePool = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address liquidityWallet = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    MockERC20 internal lpTokens = new MockERC20();
    address tokenAddress = address(lpTokens);

    MockERC20 internal token0 = new MockERC20();
    MockERC20 internal token1 = new MockERC20();

    RLIQToken internal rliqToken;
    ReactHook internal hook;
    PoolManager internal poolManager;

    function setUp() public {
        rliqToken = new RLIQToken(activePool);
        poolManager = new PoolManager(address(this));

        uint160 flags = uint160(Hooks.AFTER_SWAP_FLAG); // + others if your hook uses them

        bytes memory constructorArgs = abi.encode(
            poolManager,
            address(rliqToken),
            activePool,
            liquidityWallet,
            address(token0),
            address(token1)
        );

        (, bytes32 salt) =
            HookMiner.find(address(this), flags, type(ReactHook).creationCode, constructorArgs);

        hook = new ReactHook{salt: salt}(
            poolManager,
            address(rliqToken),
            activePool,
            liquidityWallet,
            address(token0),
            address(token1)
        );

        react = new ReactProtocol(0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274, 0xBbC0d026950711b6E579fc5Ac80bb1aDd7c08EAf, 0x2703Eb32c33ED32CE5Db487159a68B1428A241c8, 0x2e2dEA56337450F3363cb566F24b5fF0cdCe2E6e, address(hook), tokenAddress);

        vm.startPrank(activePool);
        token0.approve(address(hook), type(uint256).max);
        token1.approve(address(hook), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(liquidityWallet);
        token1.approve(address(hook), type(uint256).max);
        token0.approve(address(hook), type(uint256).max);
        vm.stopPrank();
    }

    function testSwapCount() public {
        vm.startPrank(0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274);
        token0.approve(address(react), 12e18);
        console2.log("1st Swap Initiating --------------------------------------");
        react.swap(2e18, true, 0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274);
        assertEq(react.swapCount(), 1);
        console2.log("2nd Swap Initiating --------------------------------------");
        react.swap(2e18, true, 0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274);
        assertEq(react.swapCount(), 2);
        console2.log("3rd Swap Initiating --------------------------------------");
        react.swap(2e18, true, 0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274);
        assertEq(react.swapCount(), 3);
        console2.log("4th Swap Initiating --------------------------------------");
        react.swap(2e18, true, 0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274);
        assertEq(react.swapCount(), 4);
        console2.log("5th Swap Initiating --------------------------------------");
        react.swap(2e18, true, 0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274);
        assertEq(react.swapCount(), 5);
        react.swap(2e18, true, 0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274);
        assertEq(react.swapCount(), 1);
        console2.log("All 5 Swaps Completed --------------------------------------");
        vm.stopPrank();
    }

    function testSwapAndLiquidityAddition() public {
        vm.startPrank(0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274);
        token0.approve(address(react), 12e18);
        console2.log("1st Swap Initiating --------------------------------------");
        react.swap(2e18, true, 0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274);
        assertEq(react.afterSwapCalled(), false);
        assertEq(react.liquidityAdded(), false);
        console2.log("2nd Swap Initiating --------------------------------------");
        react.swap(2e18, true, 0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274);
        assertEq(react.afterSwapCalled(), true);
        assertEq(react.liquidityAdded(), false);
        console2.log("3rd Swap Initiating --------------------------------------");
        react.swap(2e18, true, 0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274);
        assertEq(react.afterSwapCalled(), false);
        assertEq(react.liquidityAdded(), false);
        console2.log("4th Swap Initiating --------------------------------------");
        react.swap(2e18, true, 0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274);
        assertEq(react.afterSwapCalled(), true);
        assertEq(react.liquidityAdded(), false);
        console2.log("5th Swap Initiating --------------------------------------");
        react.swap(2e18, true, 0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274);
        assertEq(react.afterSwapCalled(), false);
        assertEq(react.liquidityAdded(), true);
        console2.log("All 5 Swaps Completed --------------------------------------");
        vm.stopPrank();
    }

    function testHookPermissions() public view{
        Hooks.Permissions memory p = hook.getHookPermissions();

        assertFalse(p.beforeSwap);
        assertTrue(p.afterSwap);
    }

    function test_afterSwap_triggersInternalSwap() public {
        vm.startPrank(0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274);
        token0.approve(address(react), 4e18);
        console2.log("1st Swap Initiating --------------------------------------");
        react.swap(2e18, true, 0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274);
        assertGt(token0.balanceOf(liquidityWallet), 0);
    }
}
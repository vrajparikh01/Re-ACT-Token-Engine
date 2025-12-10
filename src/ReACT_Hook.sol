// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "@openzeppelin/uniswap-hooks/src/base/BaseHook.sol";

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager, SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IERC1155} from "forge-std/interfaces/IERC1155.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {IUniswapV4Router04} from "hookmate/interfaces/router/IUniswapV4Router04.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {Actions} from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {RLIQToken} from "./RLIQToken.sol";
import {ReactProtocol} from "./ReACT_Protocol.sol";
import {AddressConstants} from "hookmate/constants/AddressConstants.sol";
import {CurrencySettler} from "lib/uniswap-hooks/src/utils/CurrencySettler.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {RLIQToken} from "./RLIQToken.sol";

contract ReactHook is BaseHook {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using CurrencySettler for Currency;
    using StateLibrary for IPoolManager;

    RLIQToken rliqToken;

    uint256 public seriesId;

    uint256 public token0Amount;
    uint256 public token1Amount;

    address immutable deployerAddress;

    int24 constant MIN_TICK = -887272;
    int24 constant MAX_TICK = 887272;
    int24 constant TICK_SPACING = 10;

    struct UserTokenDetails {
        address userAddress;
        uint256 points;
        uint256 timestamp;
    }

    mapping(uint256 => UserTokenDetails[]) public tokenIdDetails;

    mapping(address => uint256[]) public userTokenIds;

    address internal activePool;
    address internal liquidityWallet;

    int24 tickLower;
    int24 tickUpper;

    IERC20 internal token0;
    IERC20 internal token1;

    constructor(
        IPoolManager _poolManager,
        address _rliqToken,
        address _activePool,
        address _liquidityWallet,
        address _token0,
        address _token1
    ) BaseHook(_poolManager) {
        poolManager = _poolManager;
        rliqToken = RLIQToken(_rliqToken);
        activePool = _activePool;
        liquidityWallet = _liquidityWallet;
        deployerAddress = msg.sender;
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function getUserTokenIds(address user) external view returns (uint256[] memory) {
        return userTokenIds[user];
    }

    function getTokenIdDetails(uint256 tokenId) external view returns (UserTokenDetails[] memory) {
        return tokenIdDetails[tokenId];
    }

    function getLowerUsableTick(int24 tick, int24 tickSpacing) private pure returns (int24) {
        int24 intervals = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) intervals--; // round towards negative infinity
        return intervals * tickSpacing;
    }

    function _afterSwap(address, PoolKey calldata key, SwapParams calldata, BalanceDelta, bytes calldata data)
        internal
        override
        returns (bytes4, int128)
    {
        console2.log("In After Swap Hook Contract");
        (bool skipAfterSwap, uint256 unlockAmount, uint8 swapCount) = abi.decode(data, (bool, uint256, uint8));
    
        if (skipAfterSwap) {
            console2.log("Skipping After Swap Hook");
            return (BaseHook.afterSwap.selector, 0);
        }

        console2.log("Swap Count: ", swapCount);

        token1.transferFrom(activePool, liquidityWallet, unlockAmount);

        if (swapCount == 2 || swapCount == 4) {
            console2.log("In After Swap Hook");
            swap(key);
            console2.log("Swap Executed");
        }

        if (swapCount == 5) {
            addLiquidity(key);
        }
        return (BaseHook.afterSwap.selector, 0);
    }

    function swap(PoolKey calldata key) internal {
        uint256 swapTokenAmount = token1.balanceOf(liquidityWallet);
        console2.log("Swap Token Amount: ", swapTokenAmount);
        bytes memory hookData = abi.encode(true, 0, 0, 0);
        BalanceDelta delta = poolManager.swap(
            key,
            SwapParams({
                zeroForOne: false,
                amountSpecified: int256(swapTokenAmount),
                sqrtPriceLimitX96: 1461446703485210103287273052203988822378723970342 - 1
            }),
            hookData
        );
        int256 amount0 = delta.amount0();
        int256 amount1 = delta.amount1();

        console2.log("Delta0: ", amount0);
        console2.log("Delta1: ", amount1);

        (Currency currencyIn, Currency currencyOut, uint256 amountIn, uint256 amountOut) =
            (key.currency1, key.currency0, uint256(int256(-amount1)), uint256(int256(amount0)));

        console2.log("Amount In: ", amountIn);
        console2.log("Amount Out: ", amountOut);

        console2.log("INITIATING TAKE");

        currencyOut.take(poolManager, liquidityWallet, amountOut, false);

        console2.log("TAKE EXECUTED");

        poolManager.sync(currencyIn);

        console2.log("INITIATING SETTLE");

        console2.log("Balance of liquidityWallet:- ", token0.balanceOf(liquidityWallet));

        // Hook contract should have approval from liquidityWallet
        currencyIn.settle(poolManager, liquidityWallet, amountIn, false);
    }

    function addLiquidity(PoolKey calldata key) internal {
        PoolId id = key.toId();
        (uint160 sqrtP,,,) = poolManager.getSlot0(id);

        tickLower = getLowerUsableTick(TickMath.getTickAtSqrtPrice(sqrtP), key.tickSpacing);
        // tickLower -= key.tickSpacing;
        tickUpper = tickLower + key.tickSpacing;

        token0Amount = token0.balanceOf(liquidityWallet);
        token1Amount = token1.balanceOf(activePool);

        console2.log("Calculate liquidity for amounts: ", token0Amount, token1Amount);

        uint160 sqrtLower = TickMath.getSqrtPriceAtTick(tickLower);
        uint160 sqrtUpper = TickMath.getSqrtPriceAtTick(tickUpper);
        console2.log("Price in range:", sqrtP >= sqrtLower && sqrtP <= sqrtUpper);

        uint128 liquidity =
            LiquidityAmounts.getLiquidityForAmounts(sqrtP, sqrtLower, sqrtUpper, token0Amount, token1Amount);

        console2.log("Before add liquidity: ", liquidity);
        (BalanceDelta _delta,) = poolManager.modifyLiquidity(
            key,
            ModifyLiquidityParams({
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: int256(uint256(liquidity)),
                salt: 0
            }),
            ""
        );
        console2.log("After add liquidity: ");
        int256 delta0 = _delta.amount0();
        int256 delta1 = _delta.amount1();
        console2.log("Dealta0 after", delta0);
        console2.log("Delta1 after", delta1);

        uint256 totalRliqAmount;

        if (delta0 < 0) {
            console2.log("Settling token0");
            uint256 owe0 = uint256(-delta0);
            totalRliqAmount = totalRliqAmount + owe0;
            // Hook contract should have approval from liquidityWallet
            key.currency0.settle(poolManager, liquidityWallet, owe0, false);
            console2.log("Settled token0");
        }
        if (delta1 < 0) {
            console2.log("Settling token1");
            uint256 owe1 = uint256(-delta1);
            totalRliqAmount = totalRliqAmount + owe1;
            // Hook contract should have approval from activePool
            key.currency1.settle(poolManager, activePool, owe1, false);
            console2.log("Settled token1");
        }

        console2.log(
            " ----------------------- SERIES ID:- ",
            seriesId,
            " ------------------------------- total RLIQ Token:- ",
            totalRliqAmount
        );
        seriesId++;
        rliqToken.mint(address(this), seriesId, totalRliqAmount);
    }
}

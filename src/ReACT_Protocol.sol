// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IERC1155} from "forge-std/interfaces/IERC1155.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

import {IUniswapV4Router04} from "hookmate/interfaces/router/IUniswapV4Router04.sol";
import {AddressConstants} from "hookmate/constants/AddressConstants.sol";
import {Actions} from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {RLIQToken} from "./RLIQToken.sol";
import {console2} from "forge-std/console2.sol";

contract ReactProtocol {
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    IUniswapV4Router04 immutable swapRouter;

    PoolKey poolKey;

    bool public afterSwapCalled;

    bool public liquidityAdded;

    address activePool;
    address liquidityWallet;

    address rliqToken;

    mapping(address => bool) public whiteListed;
    address[] whiteListUsers;

    IERC20 internal  token0;
    IERC20 internal  token1;
    IHooks hookContract;

    Currency immutable currency0;
    Currency immutable currency1;

    address admin;

    uint8 public swapCount;

    constructor(address _activePool, address _liquidityWallet, address _token0, address _token1, address _hookContract, address _rliqToken) {
        swapRouter = IUniswapV4Router04(payable(AddressConstants.getV4SwapRouterAddress(block.chainid)));
        activePool = _activePool;
        liquidityWallet = _liquidityWallet;
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        hookContract = IHooks(_hookContract);
        (currency0, currency1) = getCurrencies();
        poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            tickSpacing: 60,
            hooks: hookContract
        });
        rliqToken = _rliqToken;

        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "ReactProtocol: Only admin can execute this function");
        _;
    }

    function getCurrencies() internal view returns (Currency, Currency) {
        require(address(token0) != address(token1));

        if (token0 < token1) {
            return (Currency.wrap(address(token0)), Currency.wrap(address(token1)));
        } else {
            return (Currency.wrap(address(token1)), Currency.wrap(address(token0)));
        }
    }

    function whiteListUser(address user) external onlyAdmin {
        whiteListUsers.push(user);
        whiteListed[user] = true;
    }
    
    function removeWhiteListUser(address user) external onlyAdmin {
        whiteListed[user] = false;
    }

    function swap(uint256 amountIn, bool zeroForOne, address issuer) external {
        IERC20 inputToken = zeroForOne ? token0 : token1;

        inputToken.transferFrom(msg.sender, address(this), amountIn);

        uint256 unlockAmount = amountIn / 2;

        afterSwapCalled = false;
        liquidityAdded = false;

        if (swapCount == 5) {
            swapCount = 0;
        }

        swapCount += 1;

        if (swapCount == 2 || swapCount == 4) {
            afterSwapCalled = true;
        }

        if (swapCount == 5) {
            liquidityAdded = true;
        }

        bytes memory hookData = abi.encode(false, unlockAmount, swapCount);

        inputToken.approve(address(swapRouter), amountIn);

        console2.log("Initiating Swap from ReACT Protocol");

        swapRouter.swapExactTokensForTokens({
            amountIn: amountIn,
            amountOutMin: 1,
            zeroForOne: zeroForOne,
            poolKey: poolKey,
            hookData: hookData,
            receiver: issuer,
            deadline: block.timestamp + 30
        });
        // uint256 totalAmount = IERC1155(rliqToken).balanceOf(rliqIssuer, seriesId);
        // if (totalAmount > 0) {
        //     transferTokensToWhiteListedUsers(totalAmount);
        // }
    }

    // function transferTokensToWhiteListedUsers(uint256 totalAmount) internal {
    //     uint256 totalUsers;
        
    //     for (uint256 index; index<whiteListUsers.length; index++) {
    //         address user = whiteListUsers[index];
    //         if (whiteListed[user]) {
    //             totalUsers += 1;
    //         }
    //     }

    //     console2.log("TOTAL AMOUNT:- ", totalAmount);
    //     console2.log("TOTAL USERS:- ", totalUsers);

    //     uint256 amountPerUser = totalAmount / totalUsers;

    //     console2.log("AMOUNT PER USER:- ", amountPerUser);

    //     for (uint256 index; index<whiteListUsers.length; index++) {
    //         address user = whiteListUsers[index];
    //         if (whiteListed[user]) {
    //             IERC1155(rliqToken).safeTransferFrom(rliqIssuer, user, seriesId, amountPerUser, abi.encode(0));
    //             uint256 balance = IERC1155(rliqToken).balanceOf(user, seriesId);
    //             console2.log("USER:- ", user, " --------------------------------- BALANCE:- ", balance);
    //         }
    //     }
    // }
}
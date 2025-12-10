// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import "../src/RLIQToken.sol";

contract ApprovalScript is Script {
    IERC20 token0 = IERC20(0x2703Eb32c33ED32CE5Db487159a68B1428A241c8); // DLI
    IERC20 token1 = IERC20(0x2e2dEA56337450F3363cb566F24b5fF0cdCe2E6e); // PU - Test
    address hookContract = 0x5757E1FE0b3A5834bf4C03Adf8D3c139266f4040;
    RLIQToken public rliqToken = RLIQToken(0x8F0BCd0B06313fd5f78d2746C93D89C10e3F591E);

    function run() external {
         vm.startBroadcast();
        // rliqToken.transferOwnership(hookContract);
        // token1.approve(hookContract, type(uint256).max);
        token0.approve(hookContract, type(uint256).max);

         vm.stopBroadcast();
    }
}
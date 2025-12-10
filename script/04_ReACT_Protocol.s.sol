// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/ReACT_Protocol.sol";
import "../src/RLIQToken.sol";

contract ReactProtocolScript is Script {
    ReactProtocol public react;
    address tokenAddress = 0x8F0BCd0B06313fd5f78d2746C93D89C10e3F591E;
    RLIQToken public rliqToken = RLIQToken(tokenAddress);

    uint256 amountToSwap = 4e18;
    address swapIssuer = 0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274;

    address[] public users = [
        0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274,
        0xBbC0d026950711b6E579fc5Ac80bb1aDd7c08EAf
    ];

    IERC20 token0 = IERC20(0x2703Eb32c33ED32CE5Db487159a68B1428A241c8); // DLI
    IERC20 token1 = IERC20(0x2e2dEA56337450F3363cb566F24b5fF0cdCe2E6e); // PU-Test

    address hookContract = 0x5757E1FE0b3A5834bf4C03Adf8D3c139266f4040;

    function setUp() public {
        // Optional: Setup any pre-requisites
    }

    function run() external {
        vm.startBroadcast();

        // Deploy ReactProtocolScript
        react = new ReactProtocol(0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274, 0xBbC0d026950711b6E579fc5Ac80bb1aDd7c08EAf, 0x2703Eb32c33ED32CE5Db487159a68B1428A241c8, 0x2e2dEA56337450F3363cb566F24b5fF0cdCe2E6e, hookContract, tokenAddress);

        rliqToken.setApprovalForAll(address(react), true);
        // Whitelist users
        for (uint i = 0; i < users.length; i++) {
            react.whiteListUser(users[i]);
        }

        token0.approve(hookContract, type(uint256).max);
        token1.approve(hookContract, type(uint256).max);

        for (uint i=1; i<=5; i++) {
            console2.log("Initiating ", i, " swap -------------------------------------");
            token0.approve(address(react), amountToSwap);
            react.swap(amountToSwap, true, swapIssuer);
        }
        console2.log("All 5 Swaps Completed --------------------------------------");

        vm.stopBroadcast();
    }
}

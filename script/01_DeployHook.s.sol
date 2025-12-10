// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";

import {BaseScript} from "./base/BaseScript.sol";

import {ReactHook} from "../src/ReACT_Hook.sol";
// import {ReactHook} from "../src/ReACT_Hook_remove_liquidity_testing.sol";

contract DeployHookScript is BaseScript {
    address rliqToken = 0x8F0BCd0B06313fd5f78d2746C93D89C10e3F591E;
    function run() public {
        // hook contracts must have specific flags encoded in the address
        uint160 flags = uint160(
             Hooks.AFTER_SWAP_FLAG
        );

        // Mine a salt that will produce a hook address with the correct flags
        bytes memory constructorArgs = abi.encode(poolManager, rliqToken, 0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274, 0xBbC0d026950711b6E579fc5Ac80bb1aDd7c08EAf, 0x2703Eb32c33ED32CE5Db487159a68B1428A241c8, 0x2e2dEA56337450F3363cb566F24b5fF0cdCe2E6e);
        (address hookAddress, bytes32 salt) =
            HookMiner.find(CREATE2_FACTORY, flags, type(ReactHook).creationCode, constructorArgs);

        // Deploy the hook using CREATE2
        vm.startBroadcast();
        ReactHook reactHook = new ReactHook{salt: salt}(poolManager, rliqToken, 0xfEceA7b046b4DaFACE340c7A2fe924cf41b6d274, 0xBbC0d026950711b6E579fc5Ac80bb1aDd7c08EAf, 0x2703Eb32c33ED32CE5Db487159a68B1428A241c8, 0x2e2dEA56337450F3363cb566F24b5fF0cdCe2E6e);
        vm.stopBroadcast();

        require(address(reactHook) == hookAddress, "DeployHookScript: Hook Address Mismatch");
    }
}

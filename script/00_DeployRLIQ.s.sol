// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/RLIQToken.sol";

contract DeployRLIQScript is Script {

    RLIQToken token;
    function run() external {
        vm.startBroadcast();
        token = new RLIQToken(0xBbC0d026950711b6E579fc5Ac80bb1aDd7c08EAf);
        vm.stopBroadcast();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract CreateSubscription is Script {
    function getHelperConfigAndForwardDetailsToCreateSubscription() public returns (uint256) {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,,,) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns(uint256) {
        console.log("Script is about to create a subscription on chain", block.chainid);
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Subscription have been successfully created and your id is", subId);
        console.log("Please update subId in your HelperConfig.s.sol");
        return subId;
    }

    function run() external returns (uint256) {
        return getHelperConfigAndForwardDetailsToCreateSubscription();
    }
}

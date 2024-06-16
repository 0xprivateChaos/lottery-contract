// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2PlusMock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2PlusMock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {

    function run() external returns (uint256) {
        return getHelperConfigAndForwardDetailsToCreateSubscription();
    }

    function getHelperConfigAndForwardDetailsToCreateSubscription() public returns (uint256) {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,,,,) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns(uint256) {
        console.log("Script is about to create a subscription on chain", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2PlusMock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Subscription have been successfully created and your id is", subId);
        console.log("Please update subId in your HelperConfig.s.sol");
        return subId;
    }

}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function run() external {
        getHelperConfigDetailsAndPassToFundSubscription();
    }

    function getHelperConfigDetailsAndPassToFundSubscription() public {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,, uint256 subId,,address linkToken) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subId, linkToken);
    }

    function fundSubscription(address _vrfCoordinator, uint256 _subId, address _linkToken) public {
        console.log("Script is about to fund Subscripction: ", _subId);
        console.log("Script is about to fund subscription on chain", block.chainid);
        console.log("Script is funding subscription using the vrfCoordinator address:", _vrfCoordinator);
        if(block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2PlusMock(_vrfCoordinator).fundSubscription(_subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();    
            LinkToken(_linkToken).transferAndCall(_vrfCoordinator, FUND_AMOUNT, abi.encode(_subId));
            vm.stopBroadcast(); 
        }
        console.log("Funding subscription was successful");
    }
}

contract AddConsumer is Script {

    function run() external {
         address recentlyDeployedRaffleContract = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
         getHelperConfigDetailsAndPassToAddConsumer(recentlyDeployedRaffleContract);
    }

    function getHelperConfigDetailsAndPassToAddConsumer(address _recentlyDeployedRaffleContract) public {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,, uint256 subId,,) = helperConfig.activeNetworkConfig();
        addConsumer(_recentlyDeployedRaffleContract, vrfCoordinator, subId);
    }

    function addConsumer(address _consumer, address _vrfCoordinator, uint256 _subId) public {
        console.log("Script is about to add a consumer to subscription, consumer is of address: ", _consumer);
        console.log("Script is currently adding consumer on chain: ", block.chainid);
        console.log("Script is calling vrfCoordinator address of: ", _vrfCoordinator);
        vm.startBroadcast();
        VRFCoordinatorV2PlusMock(_vrfCoordinator).addConsumer(_subId, _consumer);
        vm.stopBroadcast();
        console.log("Consumer has been successfully added to subscription");
    }
}

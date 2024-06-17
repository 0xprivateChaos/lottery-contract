//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2PlusMock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2PlusMock.sol";

contract RaffleTest is Test {
    /* Events */
    event EnteredRaffle(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
    address linkToken;
    uint256 deployerKey;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (entranceFee, interval, vrfCoordinator, , subscriptionId, callbackGasLimit, linkToken, deployerKey) =
            helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    //////////////////////////
    //     ENTER RAFFLE     //
    //////////////////////////

    function testRaffleRevertsWhenYouDontPayEnough() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughEntranceFee.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer(0);
        assertEq(playerRecorded, PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    modifier enteredRaffleAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testCantEnterWhenRaffleCalculating() public enteredRaffleAndTimePassed {
        raffle.performUpkeep("0x0");
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    //////////////////////////
    //    CHECK UPKEEP      //
    //////////////////////////

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded,) = raffle.checkUpkeep("0x0");

        assert(!upkeepNeeded); // !upkeepNeeded == false
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsNotOpen() public enteredRaffleAndTimePassed {
        raffle.performUpkeep("0x0");

        (bool upkeepNeeded,) = raffle.checkUpkeep("0x0");

        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        (bool upkeepNeeded,) = raffle.checkUpkeep("0x0");

        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public enteredRaffleAndTimePassed {
        (bool upkeepNeeded,) = raffle.checkUpkeep("0x0");

        assert(upkeepNeeded);
    }

    //////////////////////////
    //    PERFORM UPKEEP    //
    //////////////////////////

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public enteredRaffleAndTimePassed {
        raffle.performUpkeep("0x0");
    }

    function testPerformUpkeepRevertsIfchekUpkeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        uint256 raffleState = 0;

        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, raffleState)
        );

        raffle.performUpkeep("0x0");
    }

    function testPerfromUpkeepUpdatesRaffleStateAndEmitsRequestId() public enteredRaffleAndTimePassed {
        vm.recordLogs();
        raffle.performUpkeep("0x0"); // emits the requestId

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState raffleState = raffle.getRaffleState();

        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1); // RaffleState.CALCULATING
    }

    //////////////////////////
    // FULFILL RANDOM WORDS //
    //////////////////////////

    modifier skipFork() {
        if(block.chainid != 31337) {
            return;
        }
        _;
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) public enteredRaffleAndTimePassed skipFork {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2PlusMock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }

    function testFulfillRandomWordsPicksAWInnerResetAndSendMoney() public enteredRaffleAndTimePassed skipFork {
        uint256 additionalEntrants = 5;
        uint256 startingIndex = 1;
        for(uint256 i = startingIndex; i < additionalEntrants + startingIndex; i++) {
            address players = address(uint160(i));
            hoax(players, STARTING_USER_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 prize = entranceFee * (additionalEntrants + 1);

        vm.recordLogs();
        raffle.performUpkeep("0x0"); // emits the requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        uint256 initialLastTimeStamp = raffle.getLastTimeStamp();

        // pretend to be chainlink vrf to get random number and pick winner
        VRFCoordinatorV2PlusMock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        // CONTRACT VALUES
        address winner = raffle.getRecentWinner();
        uint256 raffleState = uint256(raffle.getRaffleState());
        uint256 lengthOfParticipantsArray = raffle.getLengthOfPlayers();
        uint256 lastTimeStamp = raffle.getLastTimeStamp();

        // EXPECTED VALUES
        uint256 expectedRaffleState = 0; // RaffleState.OPEN
        uint256 expectedlengthOfParticipantsArray = 0;
        
        assert(winner != address(0));
        assertEq(raffleState, expectedRaffleState);
        assertEq(lengthOfParticipantsArray, expectedlengthOfParticipantsArray);
        assert(lastTimeStamp > initialLastTimeStamp);
        assert(winner.balance == (STARTING_USER_BALANCE + prize) - entranceFee);
    }
}

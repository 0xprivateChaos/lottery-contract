//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title Raffle contract
 * @author Aman
 * @notice This contract is used to create a raffle
 * @dev Implements Chainlink VRFv2
 */
contract Raffle {
    uint256 private immutable i_entranceFee;

    constructor(uint256 _entranceFee) {
        i_entranceFee = _entranceFee;
    }

    function enterRaffle() public payable {}

    function PickWinner() public {}

    /** Getter Functions */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
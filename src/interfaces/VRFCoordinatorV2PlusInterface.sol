//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFV2PlusClient} from "@chainlink/contracts/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

interface VRFCoordinatorV2PlusInterface {
    /**
     * @notice Request randomness
     * @dev This function is used to request randomness
     * @param request RandomWordsRequest
     * @return requestId - A unique identifier of the request. Can be used to match
     * a request to a response in fulfillRandomWords.
     */
    function requestRandomWords(VRFV2PlusClient.RandomWordsRequest calldata request)
        external
        returns (uint256 requestId);
}

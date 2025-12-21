// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

// Foundry Lottery/lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol

/**
 * @title The sample Raffle contract
 * @author Sudhanshu Gupta
 * @notice This contract is for creating a simple raffle system
 * @dev Implements Chainlink VRFv2.5 for randomness
 */

contract Raffle is VRFConsumerBaseV2Plus {
    /*Errors*/
    error Raffle__NotEnoughETHEntered(); // A good practice to start error names with contract name

    uint16 private constant REQUEST_CONFIRMATIONS = 3; // Number of confirmations to wait before fulfilling the request
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable I_ENTRANCE_FEE;
    uint256 private immutable I_INTERVAL; // Time interval for picking winner in seconds.
    bytes32 private immutable I_KEY_HASH; // Max gas price we are willing to pay for a request in wei.
    uint256 private immutable I_SUBSCRIPTION_ID; // Subscription ID that this contract uses for funding requests.
    uint32 private immutable I_CALLBACK_GAS_LIMIT; // Gas limit for the callback function.
    address payable[] private s_players; // Since it's a storage variable.
    uint256 private s_lastTimeStamp;

    /* Events*/
    event RaffleEntered(address indexed player);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        // We are passing vrfCoordinator from our constructor to the parent(VRFConsumerBaseV2Plus) contract constructor
        I_ENTRANCE_FEE = entranceFee;
        I_INTERVAL = interval;
        s_lastTimeStamp = block.timestamp;
        I_KEY_HASH = gasLane;
        I_SUBSCRIPTION_ID = subscriptionId;
        I_CALLBACK_GAS_LIMIT = callbackGasLimit;
    }

    function enterRaffle() external payable {
        if (msg.value < I_ENTRANCE_FEE) {
            revert Raffle__NotEnoughETHEntered();
        }
        s_players.push(payable(msg.sender));

        // 1. Make migration easier
        // 2. Better Indexing
        emit RaffleEntered(msg.sender);
    }

    // 1. Get a random number.
    // 2. Pick the player associated to that random number.
    // 3. Be automatically called
    function pickWinner() external {
        if ((block.timestamp - s_lastTimeStamp) < I_INTERVAL) {
            // Checking required time has passed?
            revert();
        }
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: I_KEY_HASH,
                subId: I_SUBSCRIPTION_ID,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: I_CALLBACK_GAS_LIMIT,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request); // now(after specifying in our constructor) we can access s_vrfCoordinator from VRFConsumerBaseV2Plus
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {}

    /* View / Pure functions */
    function getEntranceFee() external view returns (uint256) {
        return I_ENTRANCE_FEE;
    }
}

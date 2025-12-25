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
    error Raffle__TransferFailed();
    error Raffle__TimeNotPassed();
    error Raffle__NotOpen();
    error Raffle__UpKeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

    /* Type Declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State Variables*/
    uint16 private constant REQUEST_CONFIRMATIONS = 3; // Number of confirmations to wait before fulfilling the request
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable I_ENTRANCE_FEE;
    uint256 private immutable I_INTERVAL; // Time interval for picking winner in seconds.
    bytes32 private immutable I_KEY_HASH; // Max gas price we are willing to pay for a request in wei.
    uint256 private immutable I_SUBSCRIPTION_ID; // Subscription ID that this contract uses for funding requests.
    uint32 private immutable I_CALLBACK_GAS_LIMIT; // Gas limit for the callback function.
    address payable[] private s_players; // Since it's a storage variable.
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /* Events*/
    // 1. Make migration easier
    // 2. Better Indexing
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

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
        I_KEY_HASH = gasLane;
        I_SUBSCRIPTION_ID = subscriptionId;
        I_CALLBACK_GAS_LIMIT = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < I_ENTRANCE_FEE) {
            revert Raffle__NotEnoughETHEntered();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }

        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    // When should we pick a winner?
    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for the `upKeepNeeded` to return true. The following should be true in order to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The raffle is in an "open" state.
     * 3. The contract has ETH.
     * 4. Implicitly, your subscription is funded with LINK.
     * @param - ignored
     * @return upKeepNeeded - true if it's time restart the lottery
     * @return - ignored
     */
    function checkUpKeep(
        bytes memory /*checkData*/
    ) public view returns (bool upKeepNeeded, bytes memory /* performData */) {
        // upKeepNeeded is by default false
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >=
            I_INTERVAL);
        bool isOpen = (s_raffleState == RaffleState.OPEN);
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upKeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upKeepNeeded, "0x0");
    }

    // 1. Get a random number.
    // 2. Pick the player associated to that random number.
    // 3. Be automatically called
    function performUpKeep(bytes calldata /* performData */) external {
        (bool upKeepNeeded, ) = checkUpKeep("");
        if (!upKeepNeeded) {
            revert Raffle__UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
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
        emit RequestedRaffleWinner(requestId);
    }

    // CEI: Checks-Effects-Interactions Pattern
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        //Checks
        /*In this function there isn't any checks yet*/

        //Effects (Internal contract state changes)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN; // State Change
        s_players = new address payable[](0); // Resetting the players array
        s_lastTimeStamp = block.timestamp; // Resetting the clock
        emit WinnerPicked(s_recentWinner);

        //Interactions (External contract calls)
        (bool success, ) = recentWinner.call{value: address(this).balance}(""); //Transferring entire contract balance to the recent winner
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /* View / Pure functions */
    function getEntranceFee() external view returns (uint256) {
        return I_ENTRANCE_FEE;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }
}

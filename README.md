# Foundry Lottery

This project contains a smart contract for a provably random lottery system built with Foundry.

## Logic and Implementation

The core of the project is the `Raffle.sol` smart contract, which implements a decentralized lottery. Here's how it works:

1.  **Entering the Raffle**: Users can enter the lottery by calling the `enterRaffle()` function and paying a predetermined entrance fee.

2.  **Provably Random Winner Selection**: The lottery uses Chainlink VRF (Verifiable Random Function) to ensure that the winner is selected in a provably random and tamper-proof way.

3.  **Automated Winner Drawing**: The contract uses Chainlink Automation (Keepers) to automatically trigger the winner selection process. The `checkUpKeep` function checks if the conditions for a new lottery round are met (e.g., time interval has passed, there are enough players). If the conditions are met, `performUpKeep` is called, which in turn requests a random number from Chainlink VRF.

4.  **Winner Payout**: Once the random number is received by the contract in the `fulfillRandomWords` function, a winner is chosen from the list of participants. The entire prize pool (the sum of all entrance fees) is then automatically transferred to the winner.

5.  **Two States**: The contract operates in two states:
    *   `OPEN`: The lottery is open for new participants.
    *   `CALCULATING`: The lottery is in the process of selecting a winner.

### Key Components

*   **`Raffle.sol`**: The main smart contract containing all the lottery logic.
*   **`HelperConfig.s.sol`**: A script to manage network-specific configurations (e.g., for local testing vs. a public testnet).
*   **`DeployRaffle.s.sol`**: A script for deploying the `Raffle` contract.
*   **`Interactions.s.sol`**: Scripts for interacting with the Chainlink VRF services (creating and funding subscriptions).

## Getting Started

### Prerequisites

*   [Foundry](https://getfoundry.sh/): You'll need Foundry installed to build, test, and deploy the contracts.

### Installation

1.  Clone the repository:
    ```bash
    git clone https://github.com/Sudhanshugupta26/Foundry-Lottery
    cd Foundry-Lottery
    ```

2.  Install the dependencies:
    ```bash
    make all
    ```

## Usage

### Start a Local Network

To deploy and test locally, start an Anvil node in a separate terminal:

```bash
make anvil
```

### Run Tests

To run the contract tests:

```bash
make test
```

### Deploy to a Local Network

To deploy the `Raffle` contract to your local Anvil network:

```bash
make deploy
```

### Deploy to Sepolia Testnet

1.  Set up your environment variables in a `.env` file. You'll need:
    *   `SEPOLIA_RPC_URL`: Your Sepolia RPC URL (e.g., from Infura or Alchemy).
    *   `PRIVATE_KEY`: The private key of the account you want to deploy from.
    *   `ETHERSCAN_API_KEY`: Your Etherscan API key for contract verification.

2.  Deploy the contract:

    ```bash
    make deploy ARGS="--network sepolia"
    ```

## Interacting with the Raffle

### Enter the Raffle

To enter the raffle, you can use `cast send`. You will need the address of the deployed `Raffle` contract.

```bash
cast send <RAFFLE_CONTRACT_ADDRESS> "enterRaffle()" --value <ENTRANCE_FEE_IN_WEI> --private-key <YOUR_PRIVATE_KEY>
```

Replace `<RAFFLE_CONTRACT_ADDRESS>`, `<ENTRANCE_FEE_IN_WEI>`, and `<YOUR_PRIVATE_KEY>` with the appropriate values.

---

This `README.md` provides a comprehensive overview of the Foundry Lottery project, including its functionality, setup instructions, and usage commands.

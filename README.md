# Foundry Smart Contract Lottery

# Overview
The Raffle Contract is a decentralized lottery system where players can participate by paying a small entrance fee. After a set period, a random winner is selected, and the total prize pool is transferred to the winner. The randomness and automation are managed using Chainlink VRF and Chainlink Automation.

# Features
 - Fair Lottery: Enter with a small fee for a chance to win the total prize pool.
 - Random Winner Selection: Chainlink VRF ensures secure and fair random number generation.
 - Automated Execution: Chainlink Automation handles the winner selection and prize distribution.

## How It Works
1. Enter the Raffle: Pay the entrance fee to join the raffle.
2. Wait for the Draw: The raffle runs for a predefined duration.
3. Winner Selection: Chainlink VRF generates a random winner.
4. Prize Distribution: Chainlink Automation transfers the prize to the winner automatically.

# Usage

## Start a local node

```
make anvil
```

## Deploy

This will default to your local node. You need to have it running in another terminal in order for it to deploy.

```
make deploy
```

## Deploy - Other Network

[See below](#deployment-to-a-testnet-or-mainnet)

## Testing

We talk about 4 test tiers in the video.

1. Unit
2. Integration
3. Forked
4. Staging

This repo we cover #1 and #3.

```
forge test
```

or

```
forge test --fork-url $SEPOLIA_RPC_URL
```

### Test Coverage

```
forge coverage
```

# Deployment to a testnet or mainnet

1. Setup environment variables

You'll want to set your `SEPOLIA_RPC_URL` and `PRIVATE_KEY` as environment variables. You can add them to a `.env` file.
- `SEPOLIA_RPC_URL`: This is url of the sepolia testnet node you're working with. You can get setup with one for free from [Alchemy](https://alchemy.com/?a=673c802981)

Optionally, add your `ETHERSCAN_API_KEY` if you want to verify your contract on [Etherscan](https://etherscan.io/).

1. Get testnet ETH

Head over to [faucets.chain.link](https://faucets.chain.link/) and get some testnet ETH.

1. Deploy

```
make deploy ARGS="--network sepolia"
```

This will setup a ChainlinkVRF Subscription for you. If you already have one, update it in the `scripts/HelperConfig.s.sol` file. It will also automatically add your contract as a consumer.

3. Register a Chainlink Automation Upkeep

[Chainlink Automation docs](https://docs.chain.link/chainlink-automation/compatible-contracts)

Go to [automation.chain.link](https://automation.chain.link/new) and register a new upkeep. Choose `Custom logic` as your trigger mechanism for automation.


## Scripts

After deploying to a testnet or local net, you can run the scripts.

Using cast deployed locally example:

```
cast send <RAFFLE_CONTRACT_ADDRESS> "enterRaffle()" --value 0.1ether --private-key <PRIVATE_KEY> --rpc-url $SEPOLIA_RPC_URL
```

or, to create a ChainlinkVRF Subscription:

```
make createSubscription ARGS="--network sepolia"
```
fund Subscription:
```
make fundSubscription ARGS="--network sepolia"
```
Add Consumer
```
make addConsumer ARGS="--network sepolia"
```

## Estimate gas

You can estimate how much gas things cost by running:

```
forge snapshot
```

And you'll see an output file called `.gas-snapshot`

# Formatting

To run code formatting:

```
forge fmt
```

# Thank you!

ETH/Arbitrum/Optimism/Polygon/etc Address: 0x0364EdA3CF25b1Bfb4918AB93D5dF173C197C9ab
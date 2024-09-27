# Yieldnest EigenLayer Airdrop Contracts

This repository contains the smart contracts and scripts for deploying the Yieldnest EigenLayer Airdrop. It leverages the Foundry development toolkit for testing, building, and deploying contracts. The project includes Solidity contracts for the airdrop, deployment scripts, and utilities for managing input data.

## Project Overview

This repository includes:

- **Smart Contracts**: Contracts that manage the airdrop mechanism for Yieldnest tokens on EigenLayer.
- **Deployment Scripts**: Scripts for deploying and configuring the airdrop contracts, including data processing utilities.
- **Testing Framework**: Tests using Foundry's Forge tool for the contracts and utilities.

### Key Contracts and Scripts

- **Main Contracts**:
  - `EigenAirdrop.sol`: The core contract for managing the airdrop on EigenLayer.
  - `IEigenAirdrop.sol`: Interface for the EigenAirdrop contract.

- **Deployment Scripts**:
  - `DeployEigenAirdrop.s.sol`: Script to deploy the `EigenAirdrop` contract.

- **Utilities**:
  - `convertCSVjson.sh`: Bash script for converting CSV input data into JSON format for use in the deployment scripts.

## Prerequisites

- **Foundry**: A fast, portable, and modular toolkit for Ethereum development.
- **Solidity**: For developing smart contracts.
- **Bash**: Required for running shell scripts, including the CSV to JSON converter.

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yieldnest/eigenlayer-airdrop.git
cd eigenlayer-airdrop
```

### 2. Install Dependencies

This project uses `foundry` to manage dependencies:

```bash
forge install
```

## Environment Variables

Before running the scripts, ensure you have set up your environment variables. Copy the `.env.example` file and provide the required values.

```bash
cp .env.example .env
```

### Required Environment Variables

- `ETHERSCAN_API_KEY`: Your Etherscan API key for contract verification.
- `MAINNET_RPC_URL`: Full archival node URL for Mainnet.
- `DEPLOYER_ACCOUNT_NAME`: The deployer's account name, stored in your local cast wallet.
- `DEPLOYER_ADDRESS`: The deployer's public address.

## Usage

### Build

To compile the Solidity contracts, use:

```bash
forge build
```

### Compile

You can compile the contracts with the following command:

```bash
forge compile
```

### Test

Run the tests using Forge’s testing framework:

```bash
forge test -vvv
```

### Gas Snapshots

To generate gas usage reports for the contracts, run:

```bash
forge snapshot
```

### Lint

To check for linting issues in Solidity files, run:

```bash
forge fmt --check && solhint "{script,src,test}/**/*.sol"
```

### Format

To format the Solidity code using Foundry:

```bash
forge fmt
```

## Deployment

To deploy the `EigenAirdrop` contract, use the provided Makefile. This project supports deploying with input data files in both CSV and JSON formats.

### Deploying the Airdrop Contract

1. **Convert CSV to JSON (if necessary)**:
   If you're working with CSV input data, you can convert it to JSON by running:

   ```bash
   make convert csv=script/inputs/ynETH.csv
   ```

2. **Simulate the Deployment**:
   Simulate a deployment to check for errors using the following command:

   ```bash
   make simulate json=script/inputs/ynETH.json network=mainnet
   ```

3. **Deploy the Contracts**:
   To deploy the `EigenAirdrop` contract to Mainnet, run:

   ```bash
   make deploy json=script/inputs/ynETH.json network=mainnet
   ```

   **Note**: Before running the deployment command, ensure the following environment variables are properly set:
   - `MAINNET_RPC_URL` (full archival node for Mainnet)
   - `ETHERSCAN_API_KEY` (for verifying contracts)
   - `DEPLOYER_ACCOUNT_NAME` (name of the deployer's account in the cast wallet)
   - `DEPLOYER_ADDRESS` (the deployer's public address)

The Makefile automates many aspects of the deployment, allowing you to easily convert input data and deploy the contract.

## Example JSON Input File

Below is an example structure for the JSON input file used for the airdrop:

```json
{
  "eigenPoints": [
    {
      "addr": "0x00000000051CBcE3fD04148CcE2c0adc7c651829",
      "points": 38593
    },
    {
      "addr": "0x000da9776cb42F19a7566385D0191E66F2Cb007a",
      "points": 901128
    }
  ]
}
```

This file specifies the addresses and corresponding airdrop points for each recipient. These points will be used to calculate the distribution amounts during the airdrop.

## Makefile Commands

The Makefile provides a set of useful commands to manage the project:

- `make install`: Install project dependencies.
- `make clean`: Remove cache and output directories.
- `make build`: Build the project.
- `make test`: Run the test suite.
- `make convert`: Convert CSV input data to JSON.
- `make simulate`: Simulate the deployment without broadcasting.
- `make deploy`: Deploy the contract to the network specified.

## Project Structure

- `src/`: Contains the core smart contracts for the airdrop system.
- `script/`: Contains deployment scripts and input data utilities.
- `test/`: Contains unit tests for the airdrop contracts.
- `deployments/`: Stores deployment artifacts and related configurations.
- `.solhint.json`: Configuration file for Solidity linting.
- `foundry.toml`: Foundry configuration file.
- `remappings.txt`: Foundry remappings for import resolution.
- `.env.example`: Example environment variable configuration file.

## License

This project is licensed under the MIT License.

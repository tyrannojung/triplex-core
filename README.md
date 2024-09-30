# triplex-core

triplex-core is a smart contract project for deploying and managing various contracts including WebAuthn256r1, FIDOAccountFactory2, Paymaster, and SimpleAccountFactory.

## Setup and Running

1. Install dependencies:

```
yarn install
```

2. Set environment variables:

Create a .env file in the project root and set the following variables:

```
#Sepolia network RPC URL
SEPOLIA_URL=https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID
#Arbitrum Sepolia network RPC URL
ARBITRUM_SEPOLIA_URL=https://arbitrum-sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID
#Private key for deploying contracts (without 0x prefix)
PRIVATE_KEY=your_private_key_here_without_0x_prefix
```

3. Compile the contracts:

```
yarn hardhat compile
```

4. Deploy the contracts:

- To deploy on Sepolia:

```
yarn deploy sepolia
```

- To deploy on Arbitrum Sepolia:

```
yarn deploy arbitrumSepolia
```

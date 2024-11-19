## Getting Started

First, start a local Berachain node:
```bash
anvil --fork-url https://bartio.rpc.berachain.com
```

In a new terminal, run the local setup script:
```bash
npm run lottahoney
```

This will:
- Deploy the contracts to your local node
- Copy the ABIs to the frontend & contract addresses to .env
- Start the Next.js development server
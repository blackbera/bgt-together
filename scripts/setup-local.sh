#!/bin/bash

echo "📝 Deploying contracts..."
cd contracts

# Run the forge script
forge script script/LocalSetup.s.sol:LocalSetup --fork-url http://localhost:8545 --broadcast

cd ..

# Copy ABIs
echo "📄 Copying ABIs..."
./scripts/copy-abis.sh

echo "🌐 Starting up LottaHoney Frontend..."
npm run dev
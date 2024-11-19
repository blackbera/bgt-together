#!/bin/bash

# Create ABIs directory if it doesn't exist
mkdir -p src/abis

# Extract just the abi field and copy to src/abis
jq '.abi' contracts/out/LotteryVault.sol/LotteryVault.json > src/abis/LotteryVaultABI.ts
jq '.abi' contracts/out/PrzHoney.sol/PrzHoney.json > src/abis/PrzHoneyABI.ts

# Add export default to the start of each file
sed -i '' '1i\
export default ' src/abis/LotteryVaultABI.ts
sed -i '' '1i\
export default ' src/abis/PrzHoneyABI.ts

echo "✅ ABIs copied to src/abis/" 
import { 
  useWriteContract,
  useWaitForTransactionReceipt,
  useReadContracts,
  useAccount
} from 'wagmi'
import { parseEther } from 'viem'
import { ADDRESSES } from '@/config/addresses'
import LotteryVaultABI from '@/abis/LotteryVaultABI'
import ERC20ABI from '@/abis/ERC20ABI'

export function usePurchaseTicket() {
  const { address } = useAccount()
  const lotteryAddress = ADDRESSES.LOTTERY_VAULT_ADDRESS as `0x${string}`

  // Get ticket price using useReadContracts
  const { 
    data: contractData,
    error: readError,
    isPending: isReading 
  } = useReadContracts({
    contracts: [
      {
        address: lotteryAddress,
        abi: LotteryVaultABI,
        functionName: 'ticketPrice',
      }
    ]
  })

  const [ticketPrice] = contractData || []

  // Approve HONEY spending
  const { 
    writeContract: approveHoney, 
    data: approveHash,
    isPending: isApproving,
    error: approveError
  } = useWriteContract()

  // Purchase ticket
  const { 
    writeContract: purchaseTicket,
    data: purchaseHash,
    isPending: isPurchasing,
    error: purchaseError
  } = useWriteContract()

  // Wait for transactions
  const { isLoading: isApproveConfirming } = useWaitForTransactionReceipt({
    hash: approveHash,
  })

  const { isLoading: isPurchaseConfirming } = useWaitForTransactionReceipt({
    hash: purchaseHash,
  })

  const buyTickets = async (ticketCount: number) => {
    if (!address) return

    try {
      // Calculate total cost (1 BERA per ticket)
      const totalCost = parseEther('1') * BigInt(ticketCount)

      // First approve HONEY spending
      await approveHoney({
        address: ADDRESSES.HONEY_ADDRESS as `0x${string}`,
        abi: ERC20ABI,
        functionName: 'approve',
        args: [lotteryAddress, totalCost],
      })

      // Wait for approval
      await new Promise((resolve) => setTimeout(resolve, 1000))

      // Then purchase tickets
      await purchaseTicket({
        address: lotteryAddress,
        abi: LotteryVaultABI,
        functionName: 'purchaseTicket',
        args: [ticketCount],
      })

    } catch (error) {
      console.error('Error purchasing tickets:', error)
      throw error
    }
  }

  return {
    buyTickets,
    isLoading: isApproving || isPurchasing || isApproveConfirming || isPurchaseConfirming || isReading,
    error: approveError || purchaseError || readError
  }
} 
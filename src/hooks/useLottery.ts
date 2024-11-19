import { 
    useReadContract,
    useReadContracts,
    useWriteContract,
    useWaitForTransactionReceipt,
    useAccount 
  } from 'wagmi'
  import { ADDRESSES } from '@/config/addresses'
  import LotteryVaultABI from '@/abis/LotteryVaultABI'
  import ERC20ABI from '@/abis/ERC20ABI'
  import { parseEther } from 'viem'
  import { waitForTransactionReceipt } from '@wagmi/core'
  
  export function useLottery() {
    const { address } = useAccount()
    const lotteryAddress = ADDRESSES.LOTTERY_VAULT_ADDRESS as `0x${string}`
  
    // Read multiple lottery states at once
    const { 
      data: lotteryData,
      error: readError,
      isPending: isReading 
    } = useReadContracts({
      contracts: [
        {
          address: lotteryAddress,
          abi: LotteryVaultABI,
          functionName: 'lotteryActive',
        },
        {
          address: lotteryAddress,
          abi: LotteryVaultABI,
          functionName: 'totalPool',
        },
        {
          address: lotteryAddress,
          abi: LotteryVaultABI,
          functionName: 'getTimeRemaining',
        },
        {
          address: lotteryAddress,
          abi: LotteryVaultABI,
          functionName: 'getCurrentParticipants',
        }
      ]
    })
  
    const [isActive, totalPool, timeRemaining, participants] = lotteryData || []
  
    // Update the write contract hooks
    const { 
      writeContract: write,
      data: hash,
      isPending,
      error 
    } = useWriteContract()
  
    const { isLoading: isConfirming } = useWaitForTransactionReceipt({
      hash,
    })
  
    const buyTickets = async (ticketCount: number) => {
      if (!address) return
  
      try {
        // Calculate total cost (1 ETH per ticket)
        const totalCost = parseEther('1') * BigInt(ticketCount)
  
        // First approve HONEY spending
        const approveResult = await write({
          address: ADDRESSES.HONEY_ADDRESS as `0x${string}`,
          abi: ERC20ABI,
          functionName: 'approve',
          args: [lotteryAddress, totalCost],
        })
  
        if (!approveResult) throw new Error('Approval failed')
  
        // Wait for approval to be mined
        await waitForTransactionReceipt({ hash: approveResult })
  
        // Then purchase tickets
        const purchaseResult = await write({
          address: lotteryAddress,
          abi: LotteryVaultABI,
          functionName: 'purchaseTicket',
          args: [ticketCount],
        })
  
        if (!purchaseResult) throw new Error('Purchase failed')
  
        return purchaseResult
      } catch (error) {
        console.error('Error purchasing tickets:', error)
        throw error
      }
    }
  
    return {
      // Read states
      isActive,
      totalPool,
      timeRemaining,
      participants,
      isReading,
      readError,
  
      // Write functions
      buyTickets,
      isLoading: isPending || isConfirming,
      error
    }
  } 
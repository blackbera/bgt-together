import { useState } from 'react';
import Image from 'next/image';
import { useAccount } from 'wagmi';
import { parseEther } from 'viem';

interface EarningsTileProps {
  bgtEarned: string;
  isClaimable: boolean;
  onClaim: () => void;
  isLoading?: boolean;
}

function BGTEarningsTile({ bgtEarned, isClaimable, onClaim, isLoading = false }: EarningsTileProps) {
  return (
    <div className="bg-black/30 backdrop-blur-sm rounded-3xl p-6 border border-amber-200/20 hover:border-amber-200/40 transition-all flex flex-col">
      <div className="flex items-center gap-4 mb-6">
        <div className="w-12 h-12 rounded-full bg-amber-200/20 flex items-center justify-center">
          <Image
            src="/bgt.png"
            alt="BGT"
            width={32}
            height={32}
          />
        </div>
        <div>
          <h3 className="text-xl font-bold text-white">BGT Earnings</h3>
          <p className="text-amber-200">From lottery participation</p>
        </div>
      </div>

      <div className="flex-grow">
        <div className="text-4xl font-bold text-white mb-1">
          {bgtEarned} BGT
        </div>
        <div className="text-amber-200/60">
          Available to claim
        </div>
      </div>

      <button
        onClick={onClaim}
        disabled={!isClaimable || isLoading}
        className={`w-full py-2 px-4 rounded-lg font-bold transition-all ${
          isClaimable 
            ? 'bg-gradient-to-r from-amber-200 to-yellow-400 text-black hover:opacity-90'
            : 'bg-gray-600 text-gray-400 cursor-not-allowed'
        }`}
      >
        {isLoading ? 'Claiming...' : isClaimable ? 'Claim BGT' : 'Nothing to Claim'}
      </button>
    </div>
  );
}

export function HoneyLotteryTiles() {
  const [ticketCount, setTicketCount] = useState<number>(1);
  const [isLoading, setIsLoading] = useState(false);
  const { address } = useAccount();

  const handlePurchase = async () => {
    setIsLoading(true);
    try {
      // TODO: Implement purchase logic
      console.log(`Purchasing ${ticketCount} tickets`);
    } catch (error) {
      console.error(error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleClaim = async () => {
    setIsLoading(true);
    try {
      // TODO: Implement claim logic
      console.log('Claiming BGT');
    } catch (error) {
      console.error(error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      {/* Lottery Ticket Purchase Tile */}
      <div className="bg-black/30 backdrop-blur-sm rounded-3xl p-6 border border-amber-200/20 hover:border-amber-200/40 transition-all">
        <div className="flex items-center gap-4 mb-6">
          <div className="w-12 h-12 rounded-full bg-amber-200/20 flex items-center justify-center">
            <Image
              src="/honey.png"
              alt="Honey"
              width={32}
              height={32}
            />
          </div>
          <div>
            <h3 className="text-xl font-bold text-white">Honey Lottery</h3>
            <p className="text-amber-200">Win HONEY rewards</p>
          </div>
        </div>

        <div className="mb-6">
          <div className="text-white mb-2">
            <span className="text-amber-200">Grand Prize</span>
          </div>
          <div className="text-4xl font-bold text-white mb-1">
            1,000 HONEY
          </div>
        </div>

        {address ? (
          <div className="space-y-4">
            <div className="flex items-center gap-2">
              <button 
                onClick={() => setTicketCount(Math.max(1, ticketCount - 1))}
                className="bg-amber-200/20 hover:bg-amber-200/30 text-white px-3 py-1 rounded-lg"
                disabled={isLoading}
              >
                -
              </button>
              <input
                type="number"
                value={ticketCount}
                onChange={(e) => setTicketCount(Math.max(1, parseInt(e.target.value) || 1))}
                className="bg-amber-200/10 text-white text-center w-20 px-2 py-1 rounded-lg"
                min="1"
                disabled={isLoading}
              />
              <button
                onClick={() => setTicketCount(ticketCount + 1)}
                className="bg-amber-200/20 hover:bg-amber-200/30 text-white px-3 py-1 rounded-lg"
                disabled={isLoading}
              >
                +
              </button>
            </div>
            <button
              onClick={handlePurchase}
              disabled={isLoading}
              className="w-full bg-gradient-to-r from-amber-200 to-yellow-400 text-black font-bold py-2 px-4 rounded-lg hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isLoading ? 'Purchasing...' : 'Purchase Tickets'}
            </button>
          </div>
        ) : (
          <p className="text-amber-200/60 text-center">Connect wallet to participate</p>
        )}
      </div>

      {/* BGT Earnings Tile */}
      <BGTEarningsTile
        bgtEarned="0.245"
        isClaimable={true}
        onClaim={handleClaim}
        isLoading={isLoading}
      />
    </div>
  );
} 
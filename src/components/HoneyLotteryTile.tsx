import { useState } from 'react';
import Image from 'next/image';
import { useAccount } from 'wagmi';
import { parseEther } from 'viem';

export function HoneyLotteryTile() {
  const [ticketCount, setTicketCount] = useState<number>(1);
  const { address } = useAccount();

  const handlePurchase = async () => {
    // TODO: Implement purchase logic
    console.log(`Purchasing ${ticketCount} tickets`);
  };

  return (
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
        <div className="text-amber-200/60">
          ≈ $17,855
        </div>
      </div>

      {address ? (
        <div className="space-y-4">
          <div className="flex items-center gap-2">
            <button 
              onClick={() => setTicketCount(Math.max(1, ticketCount - 1))}
              className="bg-amber-200/20 hover:bg-amber-200/30 text-white px-3 py-1 rounded-lg"
            >
              -
            </button>
            <input
              type="number"
              value={ticketCount}
              onChange={(e) => setTicketCount(Math.max(1, parseInt(e.target.value) || 1))}
              className="bg-amber-200/10 text-white text-center w-20 px-2 py-1 rounded-lg"
              min="1"
            />
            <button
              onClick={() => setTicketCount(ticketCount + 1)}
              className="bg-amber-200/20 hover:bg-amber-200/30 text-white px-3 py-1 rounded-lg"
            >
              +
            </button>
          </div>
          <button
            onClick={handlePurchase}
            className="w-full bg-gradient-to-r from-amber-200 to-yellow-400 text-black font-bold py-2 px-4 rounded-lg hover:opacity-90 transition-opacity"
          >
            Purchase Tickets
          </button>
        </div>
      ) : (
        <p className="text-amber-200/60 text-center">Connect wallet to participate</p>
      )}
    </div>
  );
} 
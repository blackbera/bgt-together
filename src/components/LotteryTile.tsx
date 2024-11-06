import { useState } from 'react';
import { DepositModal } from './DepositModal';
import { useBGTPrice } from '../hooks/useBGTPrice';

interface LotteryTileProps {
  name: string;
  symbol: string;
  address: string;
  grandPrize: string;
  bgtAmount: string;
}

export function LotteryTile({ name, symbol, address, grandPrize, bgtAmount }: LotteryTileProps) {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const { bgtPrice } = useBGTPrice();
  
  const usdValue = bgtPrice 
    ? Number(bgtAmount.replace(/,/g, '')) * bgtPrice
    : 0;

  return (
    <>
      <div onClick={() => setIsModalOpen(true)} 
           className="relative overflow-hidden bg-white/5 backdrop-blur-xl rounded-2xl p-6 
                    shadow-[0_8px_32px_0_rgba(255,198,41,0.15)] 
                    border border-amber-500/20 hover:border-amber-500/40
                    transition-all duration-300 group hover:scale-[1.02] cursor-pointer
                    hover:shadow-[0_12px_40px_0_rgba(255,198,41,0.25)]">
        <div className="absolute inset-0 bg-gradient-to-br from-amber-500/10 to-yellow-500/10 opacity-0 
                        group-hover:opacity-100 transition-opacity duration-300" />
        
        <div className="relative">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-amber-400 to-yellow-500 
                          flex items-center justify-center shadow-lg shadow-amber-500/20">
              <span className="text-sm text-white font-bold">{symbol.slice(3, 5)}</span>
            </div>
            <span className="text-white font-medium text-lg">{name}</span>
          </div>
          
          <div className="text-amber-200/80 text-sm mb-2">Grand Prize</div>
          <div className="text-4xl font-bold text-white mb-2 
                        bg-gradient-to-r from-amber-200 to-yellow-400 
                        bg-clip-text text-transparent">
            {grandPrize} BGT
          </div>
          <div className="text-sm text-amber-200/60">
            ≈ ${usdValue.toLocaleString(undefined, { maximumFractionDigits: 2 })}
          </div>
        </div>
      </div>

      <DepositModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        vaultName={name}
        vaultSymbol={symbol}
        tokenAddress={address}
        grandPrize={grandPrize}
      />
    </>
  )
} 
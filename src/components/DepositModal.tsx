interface DepositModalProps {
  isOpen: boolean;
  onClose: () => void;
  vaultName: string;
  vaultSymbol: string;
  tokenAddress: string;
  grandPrize: string;
}

export function DepositModal({ isOpen, onClose, vaultName, vaultSymbol, tokenAddress, grandPrize }: DepositModalProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={onClose} />
      
      <div className="relative bg-[#1A1B23]/90 backdrop-blur-xl rounded-3xl p-8 w-full max-w-lg mx-4 
                    border border-amber-500/20 shadow-[0_8px_32px_0_rgba(255,198,41,0.25)]">
        <button onClick={onClose} className="absolute top-4 right-4 text-amber-200/60 hover:text-amber-200">
          <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>

        <h2 className="text-2xl font-bold text-center mb-6 bg-gradient-to-r from-amber-200 to-yellow-400 
                     bg-clip-text text-transparent">
          Deposit to {vaultName} Prize Pool
        </h2>

        <div className="space-y-4 mb-6">
          <div className="bg-black/20 rounded-xl p-4">
            <input type="number" 
                   placeholder="0"
                   className="w-full bg-transparent text-3xl text-white outline-none" />
            <div className="flex justify-between text-amber-200/60 text-sm mt-2">
              <span>$0.00</span>
              <span>Balance: 0 Max</span>
            </div>
          </div>

          <div className="bg-black/20 rounded-xl p-4">
            <div className="flex justify-between items-center">
              <span className="text-3xl text-white">0</span>
              <span className="text-xl text-white">{vaultSymbol}</span>
            </div>
            <div className="text-right text-amber-200/60 text-sm mt-2">
              Balance: 0
            </div>
          </div>
        </div>

        <div className="bg-amber-500/5 rounded-xl p-4 mb-6">
          <div className="flex items-center gap-2 text-amber-200 mb-2">
            <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM9 7a1 1 0 112 0v5a1 1 0 11-2 0V7zm1-5a1 1 0 100 2 1 1 0 000-2z" />
            </svg>
            <span className="font-medium">Learn about the risks</span>
          </div>
          <p className="text-amber-200/60 text-sm">
            BGT Together is a permissionless protocol. Prize vaults can be deployed by anyone. 
            Make sure you know what you are depositing into.
          </p>
        </div>

        <button className="w-full bg-gradient-to-r from-amber-500 to-yellow-500 
                         hover:from-amber-600 hover:to-yellow-600
                         text-white font-bold py-4 px-6 rounded-xl
                         transition-all duration-200">
          Enter an amount
        </button>
      </div>
    </div>
  );
} 
import { ConnectButton } from '@rainbow-me/rainbowkit';
import Head from 'next/head';
import Image from 'next/image';
import { CountdownTimer } from '../components/CountdownTimer';
import { HoneyLotteryTiles } from '../components/HoneyLotteryTiles';

export default function Home() {
  return (
    <div className="min-h-screen bg-[#1A1B23] bg-[url('/homepage.png')] bg-cover bg-center bg-fixed">
      <div className="min-h-screen bg-black/50 backdrop-blur-sm">
        <div className="absolute top-6 right-6">
          <ConnectButton />
        </div>

        <main className="max-w-7xl mx-auto px-6 py-20">
          <div className="text-center mb-20">
            <div className="flex items-center justify-center gap-6 mb-6">
              <Image
                src="/honey.png"
                alt="Honey Logo"
                width={100}
                height={100}
                className="w-24 h-24"
              />
              <h1 className="text-6xl font-bold">
                <span className="bg-gradient-to-r from-amber-200 to-yellow-400 bg-clip-text text-transparent">
                  Honey Lottery
                </span>
              </h1>
            </div>
            
            <p className="text-xl mb-8 font-bold">
              <span className="text-white">Deposit BERA for a chance to win</span>
              {' '}
              <span className="bg-gradient-to-r from-amber-200 to-yellow-400 bg-clip-text text-transparent">
                the weekly HONEY rewards
              </span>
            </p>

            <CountdownTimer />
          </div>

          <div className="max-w-4xl mx-auto">
            <HoneyLotteryTiles />
          </div>
        </main>
      </div>
    </div>
  );
}

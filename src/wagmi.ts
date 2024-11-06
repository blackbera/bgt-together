import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import {
  berachainTestnetbArtio
} from 'wagmi/chains';

export const config = getDefaultConfig({
  appName: 'RainbowKit App',
  projectId: 'YOUR_PROJECT_ID',
  chains: [
    berachainTestnetbArtio,
    ...(process.env.NEXT_PUBLIC_ENABLE_TESTNETS === 'true' ? [berachainTestnetbArtio] : []),
  ],
  ssr: true,
});
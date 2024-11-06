import useSWR from 'swr';
import type { TokenInformation } from '../types/token';

export function useBGTPrice() {
  const { data, error } = useSWR<TokenInformation>(
    '/api/token-info',
    async (url: string) => {
      const res = await fetch(url);
      if (!res.ok) throw new Error('Failed to fetch BGT price');
      return res.json();
    },
    {
      refreshInterval: 86400000,
    }
  );

  const formatUSDValue = (bgtAmount: string) => {
    if (!data?.usdValue) return null;
    
    const numericAmount = parseFloat(bgtAmount.replace(/,/g, ''));
    const bgtPrice = parseFloat(data.usdValue);
    
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      maximumFractionDigits: 2
    }).format(numericAmount * bgtPrice);
  };

  return {
    bgtPrice: data?.usdValue ? parseFloat(data.usdValue) : null,
    formatUSDValue,
    isLoading: !error && !data,
    isError: error
  };
} 
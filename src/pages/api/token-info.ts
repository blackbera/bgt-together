import type { NextApiRequest, NextApiResponse } from 'next';
import type { TokenInformation, TokenInformationResponse } from '../../types/token';

const GOLDSKY_API = 'https://api.goldsky.com/api/public/project_clq1h5ct0g4a201x18tfte5iv/subgraphs/pol-subgraph/v0.1.6/gn';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse<TokenInformation | { error: string }>
) {
  try {
    const query = `
      query {
        tokenInformation(id: "0x7507c1dc16935B82698e4C63f2746A2fCf994dF8") {
          usdValue
          symbol
          name
          address
        }
      }
    `;

    const response = await fetch(GOLDSKY_API, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ query }),
    });

    const data: TokenInformationResponse = await response.json();
    res.status(200).json(data.data.tokenInformation);
  } catch (error) {
    console.error('Error fetching token information:', error);
    res.status(500).json({ error: 'Failed to fetch token information' });
  }
} 
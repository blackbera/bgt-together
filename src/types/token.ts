export interface TokenInformation {
  usdValue: string;
  symbol: string;
  name: string;
  address: string;
}

export interface TokenInformationResponse {
  data: {
    tokenInformation: TokenInformation;
  }
}

export interface LotteryContract {
  name: string;
  symbol: string;
  address: string;
  grandPrize: string;
  bgtAmount: string;
} 
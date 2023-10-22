export const CONTRACT_ADDRESSES = {
  5: {
    ZKLC_CONTRACT_ADDRESS: process.env
      .NEXT_PUBLIC_ZKLC_CONTRACT_ADDRESS_GOERLI as `0x${string}`,
    USDC_MOCK_ADDRESS: process.env
      .NEXT_PUBLIC_USDC_MOCK_ADDRESS_GOERLI as `0x${string}`,
  },
  534351: {
    ZKLC_CONTRACT_ADDRESS: process.env
      .NEXT_PUBLIC_ZKLC_CONTRACT_ADDRESS_SCROLL_SEPOLIA as `0x${string}`,
    USDC_MOCK_ADDRESS: process.env
      .NEXT_PUBLIC_USDC_MOCK_ADDRESS_SCROLL_SEPOLIA as `0x${string}`,
  },
  31337: {
    ZKLC_CONTRACT_ADDRESS: process.env
      .NEXT_PUBLIC_ZKLC_CONTRACT_ADDRESS_HARDHAT as `0x${string}`,
    USDC_MOCK_ADDRESS: process.env
      .NEXT_PUBLIC_USDC_MOCK_ADDRESS_HARDHAT as `0x${string}`,
  },
};

export const getLCContractAddress = (chainId: number | undefined = 5) => {
  return CONTRACT_ADDRESSES[chainId as keyof typeof CONTRACT_ADDRESSES]
    .ZKLC_CONTRACT_ADDRESS;
};

export const getUSDCContractAddress = (chainId: number | undefined = 5) => {
  return CONTRACT_ADDRESSES[chainId as keyof typeof CONTRACT_ADDRESSES]
    .USDC_MOCK_ADDRESS;
};

console.log("CONTRACT_ADDRESSES", CONTRACT_ADDRESSES);

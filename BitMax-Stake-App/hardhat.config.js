/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require('@nomiclabs/hardhat-ethers');
require("@nomiclabs/hardhat-waffle");
require("@nomicfoundation/hardhat-verify");

const { PrivateKey } = require('./secret.json');

module.exports = {
   defaultNetwork: 'avalanche_fuji',

   networks: {
      hardhat: {
      },
      core_testnet: {
         url: 'https://rpc.test2.btcs.network',
         accounts: [PrivateKey],
         chainId: 1114,
      },
      avalanche_fuji: {
         url: 'https://api.avax-test.network/ext/bc/C/rpc',
         accounts: [PrivateKey],
         chainId: 43113,
         gasPrice: 25000000000, // 25 gwei
      }
   },
   solidity: {
      compilers: [
        {
           version: '0.8.24',
           settings: {
            evmVersion: 'paris',
            optimizer: {
                 enabled: true,
                 runs: 200,
              },
           },
        },
      ],
   },
   paths: {
      sources: './contracts',
      cache: './cache',
      artifacts: './artifacts',
   },
   mocha: {
      timeout: 20000,
   },
   etherscan: {
      apiKey: {
         avalancheFujiTestnet: 'YOUR_AVALANCHE_API_KEY' // Optional for verification
      }
   }
};
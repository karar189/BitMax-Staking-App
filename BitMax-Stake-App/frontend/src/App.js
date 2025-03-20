import { useEffect, useState, useCallback } from 'react';
import { ethers } from 'ethers';
import StakingToken from './contracts/StakingToken.json';
import StakingDapp from './contracts/StakingDapp.json';
import RewardToken from './contracts/RewardToken.json';
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import Modal from './components/Modal';
import './App.css';
import PTRedemption from './components/PTRedemption';
import SYWrapping from './components/SYWrapping';
import TokenSplitting from './components/TokenSplitting';
import TokenTrading from './components/TokenTrading';
import coreLogo from './core-logo.png';

const stakingDappAddress = '0x9f97cb70D2be4eb57a7aC3775B76d22C7F8AE622';
const stakingTokenAddress = '0x8400Cdc0E4B52225fd6172404eE41D0de732fa9D';
const rewardTokenAddress = '0xBf4015d32E564154b288a2EfA127162a1552b241';

function App() {
  const [stakingAmount, setStakingAmount] = useState('');
  const [unstakingAmount, setUnstakingAmount] = useState('');
  const [activeTab, setActiveTab] = useState('staking');
  const [currentAccount, setCurrentAccount] = useState(null);
  const [stakedAmount, setStakedAmount] = useState('0');
  const [rewardAmount, setRewardAmount] = useState('0');
  const [totalStkBalance, setTotalStkBalance] = useState('0');
  const [network, setNetwork] = useState('');
  const [faucetAmount, setFaucetAmount] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [stakingTokenDecimals, setStakingTokenDecimals] = useState(18);
  const [rewardTokenDecimals, setRewardTokenDecimals] = useState(18);
  const [isApproved, setIsApproved] = useState(false);

  // Check if wallet is connected
  const checkWalletIsConnected = async () => {
    const { ethereum } = window;

    if (!ethereum) {
      console.log('Make sure you have Metamask installed!');
      return;
    }

    try {
      const accounts = await ethereum.request({ method: 'eth_accounts' });

      if (accounts.length !== 0) {
        const account = accounts[0];
        setCurrentAccount(account);
      } else {
        console.log('No authorized account found');
      }
    } catch (error) {
      console.error('Error fetching accounts:', error);
    }
  };

  const checkContractExists = async () => {
    try {
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const code = await provider.getCode(stakingDappAddress);
        
        if (code === '0x') {
          toast.error("No contract exists at this address!");
        } else {
          toast.success("Contract exists at address!");
          console.log("Contract bytecode:", code);
        }
      }
    } catch (error) {
      console.error("Error checking contract:", error);
      toast.error("Failed to check contract");
    }
  };

  // Check network
  const checkNetwork = async () => {
    const { ethereum } = window;

    if (!ethereum) {
      console.log('Ethereum object does not exist');
      return;
    }

    try {
      const provider = new ethers.providers.Web3Provider(ethereum);
      const { chainId } = await provider.getNetwork();

      if (chainId !== 1114) {
        alert('Please connect to the Core Testnet2');
      } else {
        setNetwork('Core Testnet2');
      }
    } catch (error) {
      console.error('Error fetching network:', error);
    }
  };

  // Connect wallet
  const connectWalletHandler = async () => {
    const { ethereum } = window;

    if (!ethereum) {
      alert('Please install Metamask!');
      return;
    }

    try {
      const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
      setCurrentAccount(accounts[0]);
    } catch (error) {
      console.error('Error connecting wallet:', error);
    }
  };

  // Disconnect wallet
  const disconnectWalletHandler = () => {
    setCurrentAccount(null);
    setStakedAmount('0');
    setRewardAmount('0');
    setTotalStkBalance('0');
    setNetwork('');
  };

  // Fetch staked and reward amounts
  const fetchStakedAndRewardAmounts = useCallback(async () => {
    try {
      const { ethereum } = window;

      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const stakingDappContract = new ethers.Contract(stakingDappAddress, StakingDapp.abi, signer);

        const stakedAmount = await stakingDappContract.getStakedAmount(currentAccount);
        const rewardAmount = await stakingDappContract.getRewardAmount(currentAccount);

        setStakedAmount(ethers.utils.formatUnits(stakedAmount, stakingTokenDecimals));
        setRewardAmount(ethers.utils.formatUnits(rewardAmount, rewardTokenDecimals));
      } else {
        console.log('Ethereum object does not exist');
      }
    } catch (error) {
      console.error('Error fetching staked and reward amounts:', error);
    }
  }, [currentAccount, stakingTokenDecimals, rewardTokenDecimals]);

  // Fetch staking token balance
  const fetchStkBalance = useCallback(async () => {
    try {
      const { ethereum } = window;

      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const stakingTokenContract = new ethers.Contract(stakingTokenAddress, StakingToken.abi, provider);

        const balance = await stakingTokenContract.balanceOf(currentAccount);
        const decimals = await stakingTokenContract.decimals();
        setStakingTokenDecimals(decimals);
        setTotalStkBalance(ethers.utils.formatUnits(balance, decimals));
      } else {
        console.log('Ethereum object does not exist');
      }
    } catch (error) {
      console.error('Error fetching token balance:', error);
    }
  }, [currentAccount]);

  // Fetch reward token decimals
  const fetchRewardTokenDecimals = useCallback(async () => {
    try {
      const { ethereum } = window;

      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const rewardTokenContract = new ethers.Contract(rewardTokenAddress, RewardToken.abi, provider);

        const decimals = await rewardTokenContract.decimals();
        setRewardTokenDecimals(decimals);
      } else {
        console.log('Ethereum object does not exist');
      }
    } catch (error) {
      console.error('Error fetching reward token decimals:', error);
    }
  }, []);

  // Check allowance
  const checkAllowance = async () => {
    try {
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const tokenContract = new ethers.Contract(stakingTokenAddress, StakingToken.abi, provider);
        
        const amountToStake = stakingAmount ? ethers.utils.parseUnits(stakingAmount, stakingTokenDecimals) : ethers.utils.parseUnits("1", stakingTokenDecimals);
        const allowance = await tokenContract.allowance(currentAccount, stakingDappAddress);
        console.log("Current allowance:", ethers.utils.formatUnits(allowance, stakingTokenDecimals));
        
        if (allowance.gte(amountToStake)) {
          setIsApproved(true);
          toast.info(`Current allowance: ${ethers.utils.formatUnits(allowance, stakingTokenDecimals)} STK (Sufficient)`);
        } else {
          setIsApproved(false);
          toast.warning(`Current allowance: ${ethers.utils.formatUnits(allowance, stakingTokenDecimals)} STK (Insufficient for ${stakingAmount || "1"} STK)`);
        }
        return allowance;
      }
    } catch (error) {
      console.error("Error checking allowance:", error);
      toast.error("Failed to check allowance");
      return ethers.BigNumber.from(0);
    }
  };

  // Check balances
  const checkBalances = async () => {
    try {
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const tokenContract = new ethers.Contract(stakingTokenAddress, StakingToken.abi, provider);
        
        const balance = await tokenContract.balanceOf(currentAccount);
        console.log("STK Balance:", ethers.utils.formatUnits(balance, stakingTokenDecimals));
        
        toast.info(`Your STK Balance: ${ethers.utils.formatUnits(balance, stakingTokenDecimals)} STK`);
        
        // Also check tCORE2 balance for gas
        const coreBalance = await provider.getBalance(currentAccount);
        console.log("tCORE2 Balance:", ethers.utils.formatEther(coreBalance));
        
        toast.info(`Your tCORE2 Balance: ${ethers.utils.formatEther(coreBalance)} tCORE2`);
      }
    } catch (error) {
      console.error("Error checking balances:", error);
      toast.error("Failed to check balances");
    }
  };

  // Verify contract tokens
  const verifyContractTokens = async () => {
    try {
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const stakingDappContract = new ethers.Contract(stakingDappAddress, StakingDapp.abi, provider);
        
        const contractStakingToken = await stakingDappContract.stakingToken();
        console.log("Contract's Staking Token:", contractStakingToken);
        
        if (contractStakingToken.toLowerCase() === stakingTokenAddress.toLowerCase()) {
          toast.success("Staking token address matches!");
        } else {
          toast.error("Staking token address mismatch!");
          console.log("Expected:", stakingTokenAddress);
          console.log("Actual:", contractStakingToken);
        }
        
        const contractRewardToken = await stakingDappContract.rewardToken();
        console.log("Contract's Reward Token:", contractRewardToken);
        
        if (contractRewardToken.toLowerCase() === rewardTokenAddress.toLowerCase()) {
          toast.success("Reward token address matches!");
        } else {
          toast.error("Reward token address mismatch!");
          console.log("Expected:", rewardTokenAddress);
          console.log("Actual:", contractRewardToken);
        }

        const rewardAmount = await stakingDappContract.REWARD_AMOUNT();
        console.log("Reward amount:", rewardAmount.toString());
        toast.info(`Reward amount per interval: ${rewardAmount.toString()}`);

        const rewardInterval = await stakingDappContract.REWARD_INTERVAL();
        console.log("Reward interval:", rewardInterval.toString());
        toast.info(`Reward interval: ${rewardInterval.toString()} seconds`);
      }
    } catch (error) {
      console.error("Error verifying contract tokens:", error);
      toast.error("Failed to verify contract tokens");
    }
  };

  useEffect(() => {
    checkWalletIsConnected();
  }, []);

  useEffect(() => {
    if (currentAccount) {
      checkNetwork();
      fetchStakedAndRewardAmounts();
      fetchStkBalance();
      fetchRewardTokenDecimals();
    }
  }, [currentAccount, fetchStakedAndRewardAmounts, fetchStkBalance, fetchRewardTokenDecimals]);

  // Approve tokens
  const approveTokens = async () => {
    try {
      if (!isValidAmount(stakingAmount)) {
        toast.error('Invalid staking amount. Please enter a positive number.');
        return;
      }

      const { ethereum } = window;

      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const tokenContract = new ethers.Contract(stakingTokenAddress, StakingToken.abi, signer);

        toast.info('Approving tokens...');
        const amount = ethers.utils.parseUnits(stakingAmount, stakingTokenDecimals);
        
        // Log the parsed amount for debugging
        console.log("Approving amount:", amount.toString());
        
        const approveTx = await tokenContract.approve(
          stakingDappAddress, 
          amount,
          { gasLimit: 1000000 }
        );
        
        toast.info('Waiting for approval confirmation...');
        await approveTx.wait();
        setIsApproved(true);
        toast.success('Tokens approved successfully. You can now stake them.');
      }
    } catch (error) {
      console.error('Error approving tokens:', error);
      toast.error('Error approving tokens. See console for details.');
    }
  };

  // Full staking process
  const attemptStaking = async () => {
    try {
      if (!isValidAmount(stakingAmount)) {
        toast.error('Invalid staking amount. Please enter a positive number.');
        return;
      }

      const { ethereum } = window;
      if (!ethereum) {
        toast.error('Ethereum object not found');
        return;
      }

      // Step 1: Check if we have enough STK tokens
      const provider = new ethers.providers.Web3Provider(ethereum);
      const signer = provider.getSigner();
      const tokenContract = new ethers.Contract(stakingTokenAddress, StakingToken.abi, signer);
      const stakingDappContract = new ethers.Contract(stakingDappAddress, StakingDapp.abi, signer);
      
      const balance = await tokenContract.balanceOf(currentAccount);
      const amountToStake = ethers.utils.parseUnits(stakingAmount, stakingTokenDecimals);
      
      if (balance.lt(amountToStake)) {
        toast.error(`Insufficient STK balance. You have ${ethers.utils.formatUnits(balance, stakingTokenDecimals)} STK`);
        return;
      }
      
      // Step 2: Check current allowance
      const currentAllowance = await tokenContract.allowance(currentAccount, stakingDappAddress);
      console.log("Current allowance:", ethers.utils.formatUnits(currentAllowance, stakingTokenDecimals));
      
      // Step 3: Approve if needed
      if (currentAllowance.lt(amountToStake)) {
        toast.info('Approving tokens...');
        const approveTx = await tokenContract.approve(
          stakingDappAddress,
          amountToStake,
          { gasLimit: 1000000 }
        );
        
        toast.info('Waiting for approval confirmation...');
        await approveTx.wait();
        toast.success('Tokens approved successfully');
        
        // Verify allowance after approval
        const newAllowance = await tokenContract.allowance(currentAccount, stakingDappAddress);
        console.log("New allowance after approval:", ethers.utils.formatUnits(newAllowance, stakingTokenDecimals));
      } else {
        toast.info('Tokens already approved');
      }
      
      // Step 4: Try to stake with detailed logging
      console.log("Attempting to stake:", amountToStake.toString());
      console.log("Staking contract:", stakingDappAddress);
      
      toast.info('Staking tokens...');
      try {
        const stakeTx = await stakingDappContract.stake(amountToStake, {
          gasLimit: 1000000
        });
        
        toast.info('Waiting for staking confirmation...');
        const receipt = await stakeTx.wait();
        
        console.log("Staking receipt:", receipt);
        if (receipt.status === 1) {
          toast.success('Staked successfully');
        } else {
          toast.error('Staking transaction failed');
        }
        
        fetchStakedAndRewardAmounts();
        fetchStkBalance();
      } catch (stakeError) {
        console.error("Specific staking error:", stakeError);
        
        if (stakeError.error && stakeError.error.message) {
          toast.error(`Staking error: ${stakeError.error.message}`);
        } else if (stakeError.message) {
          toast.error(`Staking error: ${stakeError.message}`);
        } else {
          toast.error('Unknown staking error');
        }
      }
    } catch (error) {
      console.error('Error in staking process:', error);
      toast.error('Error in staking process. See console for details.');
    }
  };

  // Stake tokens
  const stakeTokens = async () => {
    try {
      if (!isValidAmount(stakingAmount)) {
        toast.error('Invalid staking amount. Please enter a positive number.');
        return;
      }
  
      const { ethereum } = window;
  
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const stakingDappContract = new ethers.Contract(stakingDappAddress, StakingDapp.abi, signer);
        
        const amount = ethers.utils.parseUnits(stakingAmount, stakingTokenDecimals);
        
        // Log details for debugging
        console.log("Staking amount:", amount.toString());
        console.log("Account:", currentAccount);
        console.log("Contract address:", stakingDappAddress);
        
        toast.info('Staking tokens...');
        const tx = await stakingDappContract.stake(amount, {
          gasLimit: 1000000
        });
        
        toast.info('Waiting for transaction confirmation...');
        await tx.wait();
        toast.success('Staked successfully');
        fetchStakedAndRewardAmounts();
        fetchStkBalance();
      }
    } catch (error) {
      console.error('Error staking tokens:', error);
      
      // More detailed error handling
      if (error.reason) {
        toast.error(`Error: ${error.reason}`);
      } else if (error.message) {
        toast.error(`Error: ${error.message.split('(')[0]}`);
      } else {
        toast.error('Error staking tokens. See console for details.');
      }
    }
  };

  // Unstake tokens
  const unstakeTokens = async () => {
    try {
      if (!isValidAmount(unstakingAmount)) {
        toast.error('Invalid unstaking amount. Please enter a positive number.');
        return;
      }

      // Check if unstaking amount is greater than the staked amount
      if (parseFloat(unstakingAmount) > parseFloat(stakedAmount)) {
        toast.error('Enter value equal to or less than the Staked STK.');
        return;
      }

      const { ethereum } = window;

      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const stakingDappContract = new ethers.Contract(stakingDappAddress, StakingDapp.abi, signer);

        const amount = ethers.utils.parseUnits(unstakingAmount, stakingTokenDecimals);
        const tx = await stakingDappContract.unstake(amount, {
          gasLimit: 1000000
        });
        await tx.wait();
        toast.success('Unstaked successfully');
        fetchStakedAndRewardAmounts();
        fetchStkBalance();
      } else {
        console.log('Ethereum object does not exist');
      }
    } catch (error) {
      console.error('Error unstaking tokens:', error);
      if (error.reason) {
        toast.error(`Error: ${error.reason}`);
      } else if (error.message) {
        toast.error(`Error: ${error.message.split('(')[0]}`);
      } else {
        toast.error('Error unstaking tokens. See console for details.');
      }
    }
  };

  // Open reward modal
  const openRewardModal = async () => {
    try {
      const { ethereum } = window;

      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const stakingDappContract = new ethers.Contract(stakingDappAddress, StakingDapp.abi, signer);

        const reward = await stakingDappContract.getRewardAmount(currentAccount);
        const formattedReward = ethers.utils.formatUnits(reward, rewardTokenDecimals);
        console.log(formattedReward);
        if (parseFloat(formattedReward) > 0) {
          setRewardAmount(formattedReward);
          setIsModalOpen(true);
        } else {
          toast.info('No rewards available to claim.');
        }
      } else {
        console.log('Ethereum object does not exist');
      }
    } catch (error) {
      console.error('Error fetching reward amount:', error);
      toast.error('Error fetching reward amount');
    }
  };

  // Claim reward
  const claimReward = async () => {
    try {
      if (parseFloat(rewardAmount) <= 0) {
        toast.error('Cannot claim reward. Amount must be greater than zero.');
        return;
      }
  
      const { ethereum } = window;
  
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const stakingDappContract = new ethers.Contract(stakingDappAddress, StakingDapp.abi, signer);
  
        // Set a high manual gas limit
        const gasLimit = 5000000; // Higher limit to ensure success
  
        // Try sending the transaction with a higher gas limit
        const tx = await stakingDappContract.claimReward({
          gasLimit: gasLimit
        });
        await tx.wait();
        toast.success('Reward claimed successfully');
        setIsModalOpen(false);
        fetchStakedAndRewardAmounts();
        fetchStkBalance();
      } else {
        console.log('Ethereum object does not exist');
      }
    } catch (error) {
      console.error('Error claiming reward:', error);
      if (error.reason) {
        toast.error(`Error: ${error.reason}`);
      } else if (error.message) {
        toast.error(`Error: ${error.message.split('(')[0]}`);
      } else {
        toast.error('Error claiming reward. Please check the console for details.');
      }
    }
  };

  // Faucet tokens
  const faucetTokens = async (amount) => {
    try {
      if (!isValidAmount(amount)) {
        toast.error('Invalid faucet amount. Please enter a positive number less than 100.');
        return;
      }

      const parsedAmount = parseFloat(amount);
      if (parsedAmount >= 100) {
        toast.error('Request amount must be less than 100.');
        return;
      }

      const { ethereum } = window;

      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const stakingTokenContract = new ethers.Contract(stakingTokenAddress, StakingToken.abi, signer);

        const gasLimit = 1000000;

        toast.info('Minting tokens from faucet...');
        const tx = await stakingTokenContract.mint(
          currentAccount, 
          ethers.utils.parseUnits(amount, stakingTokenDecimals), 
          {
            gasLimit: gasLimit
          }
        );
        
        toast.info('Waiting for transaction confirmation...');
        await tx.wait();
        toast.success('Tokens minted successfully');
        fetchStkBalance();
      } else {
        console.log('Ethereum object does not exist');
      }
    } catch (error) {
      console.error('Error minting tokens:', error);
      if (error.reason) {
        toast.error(`Error: ${error.reason}`);
      } else if (error.message) {
        toast.error(`Error: ${error.message.split('(')[0]}`);
      } else {
        toast.error('Error minting tokens. See console for details.');
      }
    }
  };

  // Validate amount
  const isValidAmount = (amount) => {
    return !isNaN(Number(amount)) && parseFloat(amount) > 0;
  };
  return (
    <div className="app-container">
      <header className="app-header">
        <h1>Staking DApp</h1>
        {currentAccount && (
          <button 
            onClick={disconnectWalletHandler} 
            className="btn-secondary"
          >
            Disconnect Wallet
          </button>
        )}
      </header>
      
      <main className="app-main">
      {!currentAccount ? (
        <div className="connect-container">
          <h2>Connect your wallet to get started</h2>
          <button 
            onClick={connectWalletHandler} 
            className="btn-primary"
          >
            Connect Wallet
          </button>
        </div>
      ) : (
        <>
          {/* Balance cards remain the same */}
          <div className="balance-cards">
            <div className="card">
              <h3>STK Balance</h3>
              <p className="balance-value">{totalStkBalance} STK</p>
            </div>
            <div className="card">
              <h3>Staked STK Amount</h3>
              <p className="balance-value">{stakedAmount} STK</p>
            </div>
            <div className="card">
              <h3>Reward Amount</h3>
              <p className="balance-value">{rewardAmount} RTK</p>
              <button 
                onClick={openRewardModal} 
                className="btn-primary full-width"
              >
                Claim Reward
              </button>
            </div>
          </div>

          {/* Add navigation tabs for different components */}
          <div className="tabs-container">
            <div className="tabs">
              <button 
                className={`tab ${activeTab === 'staking' ? 'active' : ''}`}
                onClick={() => setActiveTab('staking')}
              >
                Staking
              </button>
              <button 
                className={`tab ${activeTab === 'redemption' ? 'active' : ''}`}
                onClick={() => setActiveTab('redemption')}
              >
                PT Redemption
              </button>
              <button 
                className={`tab ${activeTab === 'wrapping' ? 'active' : ''}`}
                onClick={() => setActiveTab('wrapping')}
              >
                SY Wrapping
              </button>
              <button 
                className={`tab ${activeTab === 'splitting' ? 'active' : ''}`}
                onClick={() => setActiveTab('splitting')}
              >
                Token Splitting
              </button>
              <button 
                className={`tab ${activeTab === 'trading' ? 'active' : ''}`}
                onClick={() => setActiveTab('trading')}
              >
                Token Trading
              </button>
            </div>
          </div>

          {/* Conditional rendering based on active tab */}
          {activeTab === 'staking' && (
            <>
              <div className="card">
                <h3>Diagnostic Tools</h3>
                <div className="button-grid">
                  <button onClick={checkAllowance} className="btn-secondary">Check Allowance</button>
                  <button onClick={checkBalances} className="btn-secondary">Check Balances</button>
                  <button onClick={verifyContractTokens} className="btn-secondary">Verify Contract</button>
                  <button onClick={attemptStaking} className="btn-secondary">Full Staking Process</button>
                  <button onClick={checkContractExists} className="btn-secondary">Check Contract Exists</button>
                </div>
              </div>

              <div className="action-cards">
                <div className="card">
                  <h3>Stake Tokens</h3>
                  <input
                    type="text"
                    placeholder="Amount to stake"
                    value={stakingAmount}
                    onChange={(e) => setStakingAmount(e.target.value)}
                    className="input-field"
                  />
                  <div className="button-group">
                    <button onClick={approveTokens} className="btn-success">Approve</button>
                    <button onClick={stakeTokens} className="btn-primary">Stake</button>
                  </div>
                </div>

                <div className="card">
                  <h3>Unstake Tokens</h3>
                  <input
                    type="text"
                    placeholder="Amount to unstake"
                    value={unstakingAmount}
                    onChange={(e) => setUnstakingAmount(e.target.value)}
                    className="input-field"
                  />
                  <button onClick={unstakeTokens} className="btn-primary full-width">Unstake</button>
                </div>

                <div className="card">
                  <h3>STK Faucet</h3>
                  <input
                    type="text"
                    placeholder="Faucet amount"
                    value={faucetAmount}
                    onChange={(e) => setFaucetAmount(e.target.value)}
                    className="input-field"
                  />
                  <button 
                    onClick={() => faucetTokens(faucetAmount)} 
                    className="btn-primary full-width"
                  >
                    STK Faucet
                  </button>
                </div>
              </div>
            </>
          )}

          {activeTab === 'redemption' && <PTRedemption currentAccount={currentAccount} />}
          {activeTab === 'wrapping' && <SYWrapping currentAccount={currentAccount} />}
          {activeTab === 'splitting' && <TokenSplitting currentAccount={currentAccount} />}
          {activeTab === 'trading' && <TokenTrading currentAccount={currentAccount} />}
        </>
      )}
    </main>
      
      <ToastContainer position="bottom-right" theme="dark" />
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onClaim={claimReward}
        rewardAmount={rewardAmount}
      />
    </div>
  );
}

export default App;

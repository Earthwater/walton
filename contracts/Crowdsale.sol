pragma solidity ^0.4.8;

import './ERC20.sol';
import './SafeMath.sol';
import './MultiSigWallet.sol';

contract Crowdsale is SafeMath, ERC20 {

    bool public isCrowdsale = false;
    uint256 public startsAt;
    uint256 public endsAt;
    uint256 public minFundingGoalInWei = 7500 * 10**18;
    uint256 public maxFundingGoalInWei = 100000 * 10**18;

    mapping (address => uint256) public weiAmountOf;
    mapping (address => uint256) public tokenAmountOf;
    uint256 public weiRaised = 0;
    uint256 public tokensSold = 0;
    uint256 public investorCount = 0;
    uint256 public weiRefunded = 0;

    enum State{PreFunding, Funding, Success, Failure}
    bool public finalizedCrowdfunding = false;

    address public multisigWallet;

    event Invested(address indexed investor, uint256 weiAmount, uint256 tokenAmount);
    event Refund(address indexed investor, uint256 weiAmount);
    //event EndsAtChanged(uint256 endsAt);

    function Crowdsale(address _Multisig,
                       uint256 _fundingStartBlock,
                       uint256 _fundingEndBlock) {

        if (_Multisig == 0) throw;
        if (_fundingStartBlock <= block.number) throw;
        if (_fundingEndBlock   <= _fundingStartBlock) throw;
        isCrowdsale = true;
        startsAt = _fundingStartBlock;
        endsAt = _fundingEndBlock;
        multisigWallet = _Multisig;
        if (!MultiSigWallet(multisigWallet).isMultiSigWallet()) throw;
    }

    function setMultiSigWallet(address newWallet) external {
      if (msg.sender != multisigWallet) throw;
      MultiSigWallet wallet = MultiSigWallet(newWallet);
      if (!wallet.isMultiSigWallet()) throw;
      multisigWallet = newWallet;
    }

    function() { throw; }

    function invest() payable external {
        if (getState() != State.Funding) throw;

        receiver = msg.sender;

        uint256 weiAmount = msg.value;
        //uint256 tokenAmount = calculatePrice(weiAmount, token.decimals());
        //if(tokenAmount == 0) throw;
        if(weiAmountOf[receiver] == 0) {
           investorCount++; // A new investor
        }

        weiAmountOf[receiver] = weiAmountOf[receiver].plus(weiAmount);
        //tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);
        weiRaised = weiRaised.plus(weiAmount);
        tokensSold = tokensSold.plus(tokenAmount);

        if(isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold)) throw;
        //if(!token.transferFrom(beneficiary, receiver, tokenAmount)) throw;

        // if(!multisigWallet.send(weiAmount)) throw;

        Invested(receiver, weiAmount, tokenAmount, customerId);
    }

    function finalizeCrowdfunding() external {
        if (getState() != State.Success) throw; // don't finalize unless we won
        if (finalizedCrowdfunding) throw; // can't finalize twice (so sneaky!)

        finalizedCrowdfunding = true;

        if (!multisigWallet.send(this.balance)) throw;
    }

    function refund() external {
        if (getState() != State.Failure) throw;

        uint256 weiValue = weiAmountOf[msg.sender];
        if (weiValue == 0) throw;
        weiAmountOf[msg.sender] = 0;
        weiRefunded = weiRefunded.plus(weiValue);
        Refund(msg.sender, weiValue);
        if (!msg.sender.send(weiValue)) throw;
    }

    function getState() public constant returns (State){
      if (finalizedCrowdfunding) return State.Success;
      if (block.number < startsAt) return State.PreFunding;
      else if (block.number <= endsAt && totalSupply < tokenCreationMax) return State.Funding;
      else if (totalSupply >= tokenCreationMin) return State.Success;
      else return State.Failure;
    }
}


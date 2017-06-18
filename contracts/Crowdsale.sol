pragma solidity ^0.4.8;

import './ERC20.sol'; // yangfeng: 可能不需要？
import './SafeMath.sol';
import './MultiSigWallet.sol';

// 主要功能：
// --------------------
// 1，合约创建时，设置开始时间，结束时间，最高ETH目标，最低ETH目标；
// 2，众筹进行时，投资者向合约地址发送 ETH，触发合约把发送者地址和 ETH 记录到 weiAmountOf，供投资者查询，以确定投资成功
//    当接收最后一笔达到最高目标时，退回剩余 ETH 给投资者；
// 3，众筹成功，手动执行 finalizeCrowdfunding()，把合约帐户 ETH 一次性转入 multiSigWallet
// 4，众筹失败，投资者手动执行 refund()，从合约帐户中转回之前参与投资的 ETH
// 5，众筹状态机：
//    PreFunding:   startsAt 之前
//    Funding:      startsAt~endsAt 之间，raisedAmount<maxFundingGoalInWei
//    Success:      startsAt~endsAt 之间：raisedAmount>=maxFundingGoalInWei，或者endsAt 之后，raisedAmount>=minFundingGoalInWei
//    Failure:      endsAt 之后，raisedAmount<minFundingGoalInWei

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

    address public multiSigWallet;

    // yangfeng: indexed 有什么作用？
    event Invested(address indexed investor, uint256 weiAmount);
    event Refund(address indexed investor, uint256 weiAmount);
    //event EndsAtChanged(uint256 endsAt);

    function Crowdsale(
        address _multiSigWallet,
        uint256 _startsAt,
        uint256 _endsAt
    ) {
        if (   _multiSigWallet == 0
            || _startsAt <= block.timestamp
            || _endsAt <= _startsAt) 
            throw;
        isCrowdsale = true;
        multiSigWallet = _multiSigWallet;
        startsAt = _startsAt;
        endsAt = _endsAt;
        if (!MultiSigWallet(multiSigWallet).isMultiSigWallet()) throw;
    }

    function setMultiSigWallet(address newWallet) 
        external 
    {
        if (msg.sender != multiSigWallet) throw;
        MultiSigWallet wallet = MultiSigWallet(newWallet);
        if (!wallet.isMultiSigWallet()) throw;
        multiSigWallet = newWallet;
    }

    function () {
        if (getState() != State.Funding) throw;

        investor = msg.sender;
        uint256 weiAmount = msg.value;
        // update investorCount, weiAmountOf, weiRaised
        if(weiAmountOf[investor] == 0) {
           investorCount++; // A new investor
        }
        weiAmountOf[investor] = safeAdd(weiAmountOf[investor], weiAmount);
        weiRaised = safeAdd(weiRaised, weiAmount);
        // yangfeng: 是否需要考虑最后一单 ETH 超过 maxFundingGoalInWei，截取剩余部分返还
        if(weiRefunded > maxFundingGoalInWei) throw;
        Invested(investor, weiAmount);
    }

    function finalizeCrowdfunding() external {
        if (getState() != State.Success) throw; // don't finalize unless we won
        if (finalizedCrowdfunding) throw; // can't finalize twice (so sneaky!)

        finalizedCrowdfunding = true;
        if (!multiSigWallet.send(this.balance)) throw;
    }

    function refund() external {
        if (getState() != State.Failure) throw;

        address receiver = msg.sender;
        uint256 weiAmount = weiAmountOf[receiver];
        if (weiAmount == 0) throw;
        weiAmountOf[receiver] = 0;
        weiRefunded = safeAdd(weiRefunded, weiAmount);
        Refund(receiver, weiAmount);
        if (!receiver.send(weiAmount)) throw;
    }

    function getState() public constant returns (State){
      if (finalizedCrowdfunding) return State.Success;
      if (block.timestamp < startsAt) return State.PreFunding;
      else if (block.timestamp <= endsAt && weiRaised < maxFundingGoalInWei) return State.Funding;
      else if (weiRaised >= minFundingGoalInWei) return State.Success;
      else return State.Failure;
    }
}


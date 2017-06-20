pragma solidity ^0.4.8;

//import './ERC20.sol'; // yangfeng: 可能不需要？
import './SafeMath.sol';
import './MultiSigWallet.sol';

// 主要功能：
// --------------------
// 1，合约创建时，设置开始时间，结束时间，最高ETH目标，最低ETH目标；
// 2，众筹进行时，投资者向合约地址发送 ETH，触发合约把发送者地址和 ETH 记录到 weiAmountOf，供投资者查询，以确定投资成功
//    当接收最后一笔达到最高目标时，退回剩余 ETH 给投资者；
// 3，众筹成功，手动执行 finalizeCrowdfunding()，把合约帐户 ETH 一次性转入 wallet
// 4，众筹失败，投资者手动执行 refund()，从合约帐户中转回之前参与投资的 ETH
// 5，众筹状态机：
//    PreFunding:   startsAt 之前
//    Funding:      startsAt~endsAt 之间，raisedAmount<maxFundingGoalInWei
//    Success:      startsAt~endsAt 之间：raisedAmount>=maxFundingGoalInWei，或者endsAt 之后，raisedAmount>=minFundingGoalInWei
//    Failure:      endsAt 之后，raisedAmount<minFundingGoalInWei

contract Token {
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);

    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Crowdsale is SafeMath {

    uint256 public startsAt;
    uint256 public endsAt;
    uint256 public minFundingGoalInWei = 7500 * 10**18;
    uint256 public maxFundingGoalInWei = 100000 * 10**18;
    uint256 public maxTokenSold = 65000000 * 10**18; // 1亿 * 65%

    Token public token;
    address public wallet;
    address public owner;
    mapping (address => uint256) public weiAmountOf;
    uint256 public weiRaised = 0;
    uint256 public tokensSold = 0;
    uint256 public investorCount = 0;
    uint256 public weiRefunded = 0;
    uint256 public finalPrice;

    enum State{PreFunding, Funding, Success, Failure}
    bool public finalizedCrowdfunding = false;

    address public wallet;

    // yangfeng: indexed 有什么作用？
    event Invest(address indexed investor, uint256 weiAmount);
    event Refund(address indexed investor, uint256 weiAmount);
    //event EndsAtChanged(uint256 endsAt);

    modifier atState(State _state) {
        if (state != getState())
            throw;
        _;
    }

    modifier isOwner() {
        if (msg.sender != owner)
            throw;
        _;
    }

    modifier isWallet() {
        if (msg.sender != wallet)
            throw;
        _;
    }

    modifier isValidPayload() {
        if (msg.data.length != 4 && msg.data.length != 36)
            throw;
        _;
    }

    function Crowdsale ( address _wallet, uint256 _startsAt, uint256 _endsAt)
        public
    {
        if (   _wallet == 0
            || _startsAt <= block.timestamp
            || _endsAt <= _startsAt) 
            throw;

        owner = msg.sender;
        wallet = _wallet;
        startsAt = _startsAt;
        endsAt = _endsAt;
    }

    function setWallet(address _wallet) 
        public
        isWallet
        atState(State.PreFunding)
    {
        if (_wallet == 0) throw;
        wallet = _wallet;
    }

    function setToken(address _token)
        public
        isOwner
        atState(State.PreFunding)
    {
        if (_token == 0)
            throw;
        token = Token(_token);
        if (token.balanceOf(this) != maxTokenSold)
            throw;
    }

    function invest()
        public
        payable
        atState(State.Funding)
    {
        address investor = msg.sender;
        uint256 weiAmount = msg.value;
        uint256 maxWei = safeAdd(maxFundingGoalInWei - weiRaised);
        if (weiAmount > maxWei) {
            weiAmount = maxWei;
            if (!investor.send(msg.value - weiAmount))
                throw;
        }
        if (weiAmount == 0 || !wallet.send(weiAmount))
            throw;
        weiAmountOf[investor] = safeAdd(weiAmountOf[investor], weiAmount);
        weiRaised = safeAdd(weiRaised, weiAmount);
        if (maxWei == weiAmount)
            finalizeCrowdfunding();
        Invest(investor, weiAmount);
    }

    function finalizeCrowdfunding()
        public
        atState(State.Success)
    {
        if (endTime ) throw; // can't finalize twice (so sneaky!)

        finalizedCrowdfunding = true;
        if (!wallet.send(this.balance)) throw;

        finalPrice = calcPrice();
        uint soldTokens = weiRaised * 10**18 / finalPrice;
        token.transfer(wallet, maxTokenSold - soldTokens);
        endTime = now;
    }

    function refund()
        external
        atState(State.Failure)
    {
        address receiver = msg.sender;
        uint256 weiAmount = weiAmountOf[receiver];
        if (weiAmount == 0) throw;
        weiAmountOf[receiver] = 0;
        weiRefunded = safeAdd(weiRefunded, weiAmount);
        Refund(receiver, weiAmount);
        if (!receiver.send(weiAmount)) throw;
    }

    function getState() 
        public
        constant
        returns (State)
    {
        // 函数由以下变量得到目前状态，不修改变量
        //    block.timestamp
        //    startsAt
        //    endTime
        //    weiRaised
        //    minFundingGoalInWei

        // before startsAt
        if (block.timestamp < startsAt)
            return State.PreFunding;
        // after startsAt
        else {
            // before endsAt
            if (block.timestamp <= endsAt)
                if (weiRaised < maxFundingGoalInWei) return State.Funding;
                else return State.Success;
            // after endsAt
            else {
                // met min goal
                if (weiRaised >= minFundingGoalInWei)
                    if (block.timestamp < (endTime + freezingPeriod)) return State.Success;
                    else return State.Release;
                // not met min reach
                else return State.Failure
            }
        }
    }
}


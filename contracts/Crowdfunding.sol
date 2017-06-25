pragma solidity 0.4.11;


contract Token {
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);

    //function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function allowance(address owner, address spender) constant returns (uint256 remaining);
    function releaseTokenTransfer();

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract CrowdFunding {

    // events
    event Invest(address indexed sender, uint256 amount);
    event UnlockTokens(address indexed receiver, uint256 tokenAmount);
    event Refund(address indexed receiver, uint256 amount);

    Token public token;
    address public wallet;
    address public owner;


    enum State {
        FundingDeployed,    // after this contract deployed
        FundingSetUp,       // after setup token
        FundingStarted,     // after ico start
        FundingSucceed,     // after ico succeed
        FundingFailed,      // after ico failed
        TxStarted           // freezingDays after FundingSucceed, investor begin claim tokens
    }
    State public state;

    // settings
    uint public startsAt       = 1499515200;   // 2017-07-08 20:00
    uint public fundingDays    = 15;
    uint public freezingDays   = 7;
    uint public tokenAllocated = 30000000 * 10**18; // 1亿 * 40%,  单位：tokenWei
    uint public ceiling        = 37500 * 10**18;
    uint public floor          = 20000 * 10**18;

    // variables
    uint public endTime         = 0; // ico end time
    uint public totalEther      = 0; // total ether raised
    uint public totalToken      = 0; // total token send
    uint public etherRefunded   = 0; // total ether refunded
    uint public tokenUnlocked   = 0; // total token unlocked
    mapping (address => uint) public etherAmountOf;
    mapping (address => uint) public tokenAmountOf;

    // modifiers
    modifier atState(State _state) {
        if (state != _state)
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

    modifier stateTransitions() {
        // ico started, called by first investor or updateState()
        if (state == State.FundingSetUp && now > startsAt)
            state = State.FundingStarted;
        // fundingDays after, called by updateState()
        if (state == State.FundingStarted && now > startsAt + fundingDays * 1 days)
            finalizeFunding();
        // freezingDays after, called by releaseTokens()
        if (state == State.FundingSucceed && now > endTime + freezingDays * 1 days)
            state = State.TxStarted;
        _;
    }

    // functions
    function CrowdFunding(address _wallet)
        public
    {
        if (_wallet == 0)
            throw;
        owner = msg.sender;
        wallet        = _wallet;
        state = State.FundingDeployed;
    }

    function setup(address _token)
        public
        isOwner
        atState(State.FundingDeployed)
    {
        if (_token == 0)
            throw;
        token = Token(_token);
        if (token.balanceOf(this) != tokenAllocated)
            throw;
        state = State.FundingSetUp;
    }

    function changeSettings(
        uint _startsAt,
        uint _fundingDays,
        uint _freezingDays,
        uint _maxTokensSold,
        uint _ceilingWei,
        uint _floorWei
    )
        public
        isWallet
        atState(State.FundingSetUp)
    {
        startsAt      = _startsAt;
        fundingDays   = _fundingDays;
        freezingDays  = _freezingDays;
        tokenAllocated = _maxTokensSold;
        ceiling       = _ceilingWei;
        floor         = _floorWei;
    }

    // yangfeng: do we need to return the state value?
    function updateState()
        public
        isOwner
        stateTransitions
        returns (State)
    {
        return state;
    }

    // invest ETH
    function()
        public
        payable
        stateTransitions
        atState(State.FundingStarted)
    {
        address investor = msg.sender;
        uint etherAmount = msg.value;

        // 1, cut etherAmount, to fit ceiling
        uint maxWei = ceiling - totalEther;
        if (etherAmount > maxWei) {
            etherAmount = maxWei;
            if (!investor.send(msg.value - etherAmount))
                throw;
        }
        if (etherAmount == 0)
            throw;

        // 2, calc token price
        uint tokenAmount = etherAmount * calcTokenPrice();

        // 3, update etherAmountOf, tokenAmountOf, totalEther, totalToken
        etherAmountOf[investor] += etherAmount;
        tokenAmountOf[investor] += tokenAmount;
        totalEther += etherAmount;
        totalToken += tokenAmount;
        if (totalToken > tokenAllocated)
            throw;

        // 4, does ceiling reached?
        if (totalEther >= ceiling)
            finalizeFunding();
        Invest(investor, etherAmount);
    }

    // unlockTokens freezingDays after endTime
    function unlockTokens()
        public
        stateTransitions
        atState(State.TxStarted)
    {
        address receiver = msg.sender;
        uint tokenAmount = tokenAmountOf[receiver];
        if (tokenAmount == 0) throw;
        // clear tokenAmountOf
        tokenAmountOf[receiver] = 0;
        tokenUnlocked += tokenAmount;
        // send token to receiver
        if (!token.transfer(receiver, tokenAmount)) throw;
        UnlockTokens(receiver, tokenAmount);
    }

    function refund()
        public
        stateTransitions
        atState(State.FundingFailed)
    {
        address receiver = msg.sender;
        uint etherAmount = etherAmountOf[receiver];
        if (etherAmount == 0) throw;
        // clear etherAmountOf
        etherAmountOf[receiver] = 0;
        etherRefunded += etherAmount;
        // send ether back to receiver
        if (!receiver.send(etherAmount)) throw;
        Refund(receiver, etherAmount);
    }

    function calcTokenPrice()
        constant
        public
        returns (uint)
    {
        // pricing statege:
        // - 1st week, 800wtc/eth
        // - 2nd week, 720wtc/eth
        // - 3rd week, 640wtc/eth
        // price Units: wtc/eth
        uint progress = now - startsAt;
        uint price = 0;
        if (progress <= 7 days)
            price = 800;
        else if (progress <= 14 days)
            price = 720;
        else
            price = 640;
        return price;
    }

    function finalizeFunding()
        private
    {
        if (totalEther >= floor) {
            state = State.FundingSucceed;
            // when succeed, send all ETH to wallet
            if (!wallet.send(this.balance))
                throw;
            // return left tokens to wallet
            if (!token.transfer(wallet, tokenAllocated - totalToken))
                throw;
        }
        else {
            state = State.FundingFailed;
            // when failed, return all tokens to wallet
            if (!token.transfer(wallet, tokenAllocated))
                throw;
        }
        endTime = now;
    }
}


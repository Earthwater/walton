pragma solidity 0.4.11;

contract PreSale {

    // events
    event Invest(address indexed sender, uint256 amount);
    event Refund(address indexed sender, uint256 amount);

    address public owner;

    enum State {
        PresaleDeployed,    // after this contract deployed
        PresaleStarted,     // after PreSale start, investor can begin investing
        PresaleEnded,       // after PreSale succeed
        PresaleFailed       // owner can set state to failed, then investor can begin refunding their ETH
    }
    State public state;

    // settings
    uint public startsAt       = 1499083200                   ;   // 2017-07-03 20:00
    uint public endsAt         = 1499083200 + 5 * 24 * 60 * 60;   // 2017-07-08 20:00
    uint public ceiling        = 15000 * 10**18;  // 15000ETH
    uint public maxOnetime     =    20 * 10**18;  // 每笔投资的最大ETH
    uint public minOnetime     =  0.01 * 10**18;  // 每笔投资的最小ETH

    // variables
    uint public totalEther     = 0; // total ether raised
    uint public etherRefunded  = 0; // total ether raised
    mapping (address => uint) public etherAmountOf;
    address public lookupList;

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

    modifier stateTransitions() {
        // after startsAt, called by first investor or updateState()
        if (state == State.PresaleDeployed && now >= startsAt)
            state = State.PresaleStarted;
        // after endsAt, called by updateState()
        if (state == State.PresaleStarted && now > endsAt)
            state = State.PresaleEnded;
        _;
    }

    modifier isValidPayload() {
        if (msg.data.length != 4 && msg.data.length != 36)
            throw;
        _;
    }

    function updateState()
        public
        isOwner
        stateTransitions
        returns (State)
    {
        return state;
    }



    // functions
    function PreSale()
        public
    {
        owner = msg.sender;
        state = State.PresaleDeployed;
    }

    function changeSettings(
        uint _startsAt,
        uint _endsAt,
        uint _ceilingWei
    )
        public
        isOwner
        atState(State.PresaleDeployed)
    {
        startsAt      = _startsAt;
        endsAt        = _endsAt;
        ceiling       = _ceilingWei;
    }

    // invest ETH
    function()
        public
        payable
        stateTransitions
        atState(State.PresaleStarted)
    {
        address investor = msg.sender;
        uint etherAmount = msg.value;

        // 小于minOnetime=0.01ETH不接收，避免后继转代币的时候，油费消耗太高
        if (etherAmount < minOnetime)
            throw;

        // 1, cut etherAmount, to fit ceiling and maxOnetime=20ETH
        uint maxWei = ceiling - totalEther;
        if (maxWei > maxOnetime)
            maxWei = maxOnetime;
        if (etherAmount > maxWei) {
            etherAmount = maxWei;
            if (!investor.send(msg.value - etherAmount))
                throw;
        }
        if (etherAmount == 0)
            throw;

        // 2, update etherAmountOf, totalEther, lookupList
        etherAmountOf[investor] += etherAmount;
        totalEther += etherAmount;
        lookupList.push(investor);  // 此处未处理重复地址，需要注意

        // 3, does ceiling reached?
        if (totalEther >= ceiling)
            state = State.PresaleEnded;
        Invest(investor, etherAmount);
    }

    // owner可以在任意时刻，把合约帐户的ETH发送给_wallet地址
    function finalizePresale(address _wallet)
        public
        isOwner
    {
        if (_wallet == 0)
            throw;
        // - send all ETH to wallet
        if (!_wallet.send(this.balance))
            throw;
    }

    // owner可以在任意时刻，返回当前 lookupList.length
    function getLookupLength()
        public
        isOwner
        constant
        returns(uint lookupLength)
    {
        return lookupList.length;
    }

    // 在PresaleEnded状态，owner可以设置状态为失败，同时往合约帐户存入足够的ETH，供etherAmountOf记录的投资者取回ETH
    function setStateToFail()
        public
        payable
        isOwner
        atState(State.PresaleEnded)
    {
        state = State.PresaleFailed;
    }

    // 在PresaleFailed状态，投资者可以自行取回ETH
    function refund()
        public
        atState(State.PresaleFailed)
    {
        address receiver = msg.sender;
        uint etherAmount = etherAmountOf[receiver];
        if (etherAmount == 0) throw;

        etherAmountOf[receiver] = 0;
        etherRefunded += etherAmount;
        // send ether back to receiver
        if (!receiver.send(etherAmount)) throw;
        Refund(receiver, etherAmount);
    }

}


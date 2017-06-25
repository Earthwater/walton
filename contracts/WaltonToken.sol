pragma solidity 0.4.11;

contract Token {
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);

    //function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}
// owner 可以进行 Token 的 release 操作
// owner 可以设置 release 白名单，即白名单帐号不锁定
contract Releasable is Ownable {

    bool public released = false;
    mapping (address => bool) public transferAgents;

    modifier canTransfer(address _sender) {
        if(!released) {
            if(!transferAgents[_sender]) {
                throw;
            }
        }
        _;
    }

    function setTransferAgent(address addr, bool state) onlyOwner {
        transferAgents[addr] = state;
    }

    function releaseTokenTransfer() public onlyOwner {
        released = true;
    }
}

contract StandardToken is Token, Releasable {

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    function transfer(address _to, uint256 _value)
        public
        canTransfer(msg.sender)
        returns (bool)
    {
        if (balances[msg.sender] < _value) {
            throw;
        }
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
        public
        canTransfer(_from)
        returns (bool)
    {
        if (balances[_from] < _value || allowed[_from][msg.sender] < _value) {
            throw;
        }
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        constant
        public
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function balanceOf(address _owner)
        constant
        public
        returns (uint256)
    {
        return balances[_owner];
    }
}

contract WaltonToken is StandardToken {

    //string constant public name = "Walton Token";
    //string constant public symbol = "WTC";
    // for test
    string constant public name = "W Token";
    string constant public symbol = "W";
    uint8 constant public decimals = 18;

    function WaltonToken(address _crowdfunding, address[] _owners, uint[] _tokens)
        public
    {
        if (_crowdfunding == 0)
            throw;
        totalSupply = 100000000 * 10**18;
        balances[_crowdfunding] = 40000000 * 10**18;
        Transfer(0, _crowdfunding, balances[_crowdfunding]);
        uint assignedTokens = balances[_crowdfunding];
        for (uint i=0; i<_owners.length; i++) {
            if (_owners[i] == 0)
                throw;
            balances[_owners[i]] += _tokens[i];
            Transfer(0, _owners[i], _tokens[i]);
            assignedTokens += _tokens[i];
        }
        if (assignedTokens != totalSupply)
            throw;
    }
}

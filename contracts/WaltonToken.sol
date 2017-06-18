pragma solidity ^0.4.8;
import './ERC20.sol';
import './SafeMath.sol';
import './Releasable.sol';

contract WaltonToken is ERC20, SafeMath, Releasable {

    // flag to determine if address is for a real contract or not
    bool public isWaltonToken = false;

    // Token information
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function WaltonToken() public {
        owner = msg.sender;
        balances[msg.sender] = 100000000;
        isWaltonToken = true;
    }

    // ERC20 interface: transfer _value new tokens from msg.sender to _to
    function transfer(address _to, uint256 _value) canTransfer(msg.sender) returns (bool success) {
        if (_to == 0x0) throw;
        if (_to == upgradeAgent) throw;
        //if (_to == address(UpgradeAgent(upgradeAgent).oldToken())) throw;
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    // ERC20 interface: transfer _value new tokens from _from to _to
    function transferFrom(address _from, address _to, uint256 _value) canTransfer(msg.sender) returns (bool success) {
        if (_to == 0x0) throw;
        if (_to == upgradeAgent) throw;
        //if (_to == address(UpgradeAgent(upgradeAgent).oldToken())) throw;
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSub(balances[_from], _value);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    // ERC20 interface: delegate transfer rights of up to _value new tokens from
    // msg.sender to _spender
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    // ERC20 interface: returns the amount of new tokens belonging to _owner
    // that _spender can spend via transferFrom
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // ERC20 interface: returns the wmount of new tokens belonging to _owner
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /// @dev Fallback function throws to avoid accidentally losing money
    function() { throw; }
}


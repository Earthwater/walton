pragma solidity ^0.4.8;

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


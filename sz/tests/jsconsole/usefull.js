// = get old storage in contrats =======================================================================================================
contract = "0x6d363cd2eb21ebd39e50c9a2f94a9724bf907d13";
maxBlocks = 1000;

startBlock = eth.blockNumber;
for (var i = 1; i < maxBlocks; i++) { /* Be careful: we go *back* in time */
    current = web3.eth.getStorageAt(contract, 0, startBlock-i);
    if (current != previous) {
        /* TODO Where to find msg.sender? We probably have to loop
         * over the transactions in the block can call
         * web3.eth.getTransaction */
        blockDate = new Date(web3.eth.getBlock(startBlock-i+1).timestamp*1000);
        console.log("Block #" + (startBlock-i+1) +  " (" + web3.eth.getBlock(startBlock-i+1).timestamp + " " + blockDate.toString()
            +  ") : " + web3.toDecimal(previous));
        /* What if there are two changes in a single block? The
         * documentation of getStorageAt seems silent about that */
        previous = current;
    }
}
blockDate = new Date(web3.eth.getBlock(startBlock-maxBlocks).timestamp*1000);
console.log("Somewhere before block #" +(startBlock-maxBlocks) +  " (block of " + blockDate.toString()
        +  ") : " + web3.toDecimal(previous));
// ========================================================================================================
var filter=web3.eth.filter({fromBlock: 866705, toBlock: 909023, address: contractAddress});
filter.get(function(error, log) {
  console.log(JSON.stringify(log));
});
filter.stopWatching(); 
// ========================================================================================================
// ========================================================================================================
// ========================================================================================================
// ========================================================================================================

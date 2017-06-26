function checkAllBalances() {
    var totalBal = 0;
    for (var acctNum in eth.accounts) {
        var acct = eth.accounts[acctNum];
        var acctBal = web3.fromWei(eth.getBalance(acct), "ether");
        totalBal += parseFloat(acctBal);
        console.log("  eth.accounts[" + acctNum + "]: \t" + acct + " \tbalance: " + acctBal + " ether");
    }
    console.log("  Total balance: " + totalBal + " ether");
};

function fiveaccounts() {
    cnt = 5;
    curcnt = eth.accounts.length;
    if (cnt > curcnt) {
        for (var i = curcnt+1; i <= cnt; i++) {
            personal.newAccount('qwer');
            console.log(i);
        }
    }
}

function delay(n) {
    miner.start();
    admin.sleepBlocks(n);
    miner.stop();
}

function send(f, t, value) {
    personal.unlockAccount(f, 'qwer');
    delay(1);
    tx = eth.sendTransaction({
        from: f,
        to: t,
        value: value
    });
    console.log(tx);
    return tx;
}

function average() {
    function calcAve() {
        totalcnt = 0;
        for (var i=0; i<eth.accounts.length; i++)
            totalcnt += Number(eth.getBalance(eth.accounts[i]));
        ave = totalcnt/eth.accounts.length;
        return ave;
    }
    checkAllBalances();
    ave = calcAve();
    mainAcct = eth.accounts[0];
    mainWei = eth.getBalance(mainAcct);
    for (var i=1; i<eth.accounts.length; i++) {
        acct = eth.accounts[i];
        wei = eth.getBalance(acct);
        if (ave > wei)
            send(mainAcct, acct, ave-wei);
        if (ave < wei)
            send(acct, mainAcct, wei-ave);
    }
    delay(1);
    checkAllBalances();
};

function deploy() {
    data = "0x606060405263595a31c0600155635960c94060025569032d26d12e980b60000060035569032d26d12e980b600000600455662386f26fc1000060055560006006556000600755341561004d57fe5b5b33600060006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506000600060146101000a81548160ff021916908360038111156100ae57fe5b02179055505b5b610bb5806100c46000396000f300606060405236156100d9576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff1680630a09284a146103785780630e123ff81461039e5780631d8557d7146103e8578063590e1ae31461041c578063753ed1bd1461042e5780638da5cb5b14610454578063927c4151146104a657806396a0f912146104dc578063a626c089146104e6578063ae6e22f114610518578063af4686821461053e578063b019d7c414610564578063bb1765b31461058a578063c19d93fb146105b0578063da246ebd146105e4575b6103765b60006000600060046000369050141580156100fd57506024600036905014155b156101085760006000fd5b6000600381111561011557fe5b600060149054906101000a900460ff16600381111561013057fe5b14801561013f57506001544210155b15610169576001600060146101000a81548160ff0219169083600381111561016357fe5b02179055505b6001600381111561017657fe5b600060149054906101000a900460ff16600381111561019157fe5b14801561019f575060025442115b156101c9576002600060146101000a81548160ff021916908360038111156101c357fe5b02179055505b60018060038111156101d757fe5b600060149054906101000a900460ff1660038111156101f257fe5b1415156101ff5760006000fd5b3393503492506005548310156102155760006000fd5b60065460035403915060045482111561022e5760045491505b81831115610280578192508373ffffffffffffffffffffffffffffffffffffffff166108fc8434039081150290604051809050600060405180830381858888f19350505050151561027f5760006000fd5b5b600083141561028f5760006000fd5b82600860008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600082825401925050819055508260066000828254019250508190555060035460065410151561031e576002600060146101000a81548160ff0219169083600381111561031857fe5b02179055505b8373ffffffffffffffffffffffffffffffffffffffff167fd90d253a9de34d2fdd5a75ae49ea17fcb43af32fc8ea08cc6d2341991dd3872e846040518082815260200191505060405180910390a25b5b505b5b505050565b005b341561038057fe5b61038861060a565b6040518082815260200191505060405180910390f35b34156103a657fe5b6103d2600480803573ffffffffffffffffffffffffffffffffffffffff16906020019091905050610610565b6040518082815260200191505060405180910390f35b34156103f057fe5b6103f8610628565b6040518082600381111561040857fe5b60ff16815260200191505060405180910390f35b341561042457fe5b61042c610760565b005b341561043657fe5b61043e6108dc565b6040518082815260200191505060405180910390f35b341561045c57fe5b6104646108e2565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b34156104ae57fe5b6104da600480803573ffffffffffffffffffffffffffffffffffffffff16906020019091905050610908565b005b6104e46109ea565b005b34156104ee57fe5b6105166004808035906020019091908035906020019091908035906020019091905050610aa7565b005b341561052057fe5b610528610b58565b6040518082815260200191505060405180910390f35b341561054657fe5b61054e610b5e565b6040518082815260200191505060405180910390f35b341561056c57fe5b610574610b64565b6040518082815260200191505060405180910390f35b341561059257fe5b61059a610b6a565b6040518082815260200191505060405180910390f35b34156105b857fe5b6105c0610b70565b604051808260038111156105d057fe5b60ff16815260200191505060405180910390f35b34156105ec57fe5b6105f4610b83565b6040518082815260200191505060405180910390f35b60025481565b60086020528060005260406000206000915090505481565b6000600060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161415156106875760006000fd5b6000600381111561069457fe5b600060149054906101000a900460ff1660038111156106af57fe5b1480156106be57506001544210155b156106e8576001600060146101000a81548160ff021916908360038111156106e257fe5b02179055505b600160038111156106f557fe5b600060149054906101000a900460ff16600381111561071057fe5b14801561071e575060025442115b15610748576002600060146101000a81548160ff0219169083600381111561074257fe5b02179055505b600060149054906101000a900460ff1690505b5b5b90565b60006000600380600381111561077257fe5b600060149054906101000a900460ff16600381111561078d57fe5b14151561079a5760006000fd5b339250600860008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054915060008214156107ee5760006000fd5b6000600860008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002081905550816007600082825401925050819055508273ffffffffffffffffffffffffffffffffffffffff166108fc839081150290604051809050600060405180830381858888f1935050505015156108875760006000fd5b8273ffffffffffffffffffffffffffffffffffffffff167fbb28353e4598c3b9199101a66e0989549b659a59a54d2c27fbb183f1932c8e6d836040518082815260200191505060405180910390a25b5b505050565b60035481565b600060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b600060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161415156109655760006000fd5b60008173ffffffffffffffffffffffffffffffffffffffff16141561098a5760006000fd5b8073ffffffffffffffffffffffffffffffffffffffff166108fc3073ffffffffffffffffffffffffffffffffffffffff16319081150290604051809050600060405180830381858888f1935050505015156109e55760006000fd5b5b5b50565b600060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16141515610a475760006000fd5b6002806003811115610a5557fe5b600060149054906101000a900460ff166003811115610a7057fe5b141515610a7d5760006000fd5b6003600060146101000a81548160ff02191690836003811115610a9c57fe5b02179055505b5b505b565b600060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16141515610b045760006000fd5b6000806003811115610b1257fe5b600060149054906101000a900460ff166003811115610b2d57fe5b141515610b3a5760006000fd5b8360018190555082600281905550816003819055505b5b505b505050565b60065481565b60015481565b60075481565b60055481565b600060149054906101000a900460ff1681565b600454815600a165627a7a72305820dc1f1b2f60b9f0f3f40d6c95976f2ad69589c0abec9af052d0f183600bd9f0d50029";
    from = eth.coinbase;
    personal.unlockAccount(from, 'qwer');
    delay(1);
    tx = eth.sendTransaction({from: from, data: data, gas: 21000000, gasPrice: web3.toWei(300, 'gwei')});
    delay(1);
    addr = eth.getTransactionReceipt(tx);
    return addr;
}

function showPresale() {
    abi = [{"constant":true,"inputs":[],"name":"endsAt","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"etherAmountOf","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"updateState","outputs":[{"name":"","type":"uint8"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"refund","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"ceiling","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_wallet","type":"address"}],"name":"finalizePresale","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"setStateToFail","outputs":[],"payable":true,"type":"function"},{"constant":false,"inputs":[{"name":"_startsAt","type":"uint256"},{"name":"_endsAt","type":"uint256"},{"name":"_ceilingWei","type":"uint256"}],"name":"changeSettings","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"totalEther","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"startsAt","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"etherRefunded","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"minOnetime","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"state","outputs":[{"name":"","type":"uint8"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"maxOnetime","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"inputs":[],"payable":false,"type":"constructor"},{"payable":true,"type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"sender","type":"address"},{"indexed":false,"name":"amount","type":"uint256"}],"name":"Invest","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"sender","type":"address"},{"indexed":false,"name":"amount","type":"uint256"}],"name":"Refund","type":"event"}];
    contract = eth.contract(abi).at('0xe3b86bd00e7177ff96e47ea4478dfc28a2c432ad');        
    contract.startsAt();
    contract.endsAt();
    contract.ceiling();
    contract.etherAmountOf();
    contract.owner();
    contract.totalEther();
    contract.etherRefunded();
    contract.minOnetime();
    contract.maxOnetime();
    contract.state();
}


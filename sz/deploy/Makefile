genesis:
	geth --datadir="data" init data/mygenesis.json
console:
	geth --datadir="data" networkid 4321 --nodiscover console
	#geth --datadir="data" networkid 4321 --rpc console
attach:
	geth attach ipc://Users/user/ethpath/project/walton/prj/walton/data/geth.ipc
mist:
	/Applications/Mist.app/Contents/MacOS/Mist  --rpc http://127.0.0.1:8545
	/Applications/Ethereum\ Wallet.app/Contents/MacOS/Ethereum\ Wallet --rpc /Users/user/ethpath/project/walton/prj/walton/data/geth.ipc



import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { MODULE_ADDRESS } from "./config";
import { norm } from "./utils";
import useChainData from "./hooks/useChainData";
import useTx from "./hooks/useTx";
import useAutoSettle from "./hooks/useAutoSettle";
import WalletBar from "./components/WalletBar.jsx";
import MarketCard from "./components/MarketCard.jsx";
import AdminPanel from "./components/AdminPanel.jsx";
import TradeForm from "./components/TradeForm.jsx";
import TradeTable from "./components/TradeTable.jsx";
import TxStatus from "./components/TxStatus.jsx";

export default function App() {
  const { connected, account, network } = useWallet();
  const address = connected && account ? account.address.toString() : null;

  const { market, trader, trades, refresh } = useChainData(address);
  const { send, status, hash } = useTx(refresh);
  useAutoSettle(address, trades, send);

  const isAdmin = address && MODULE_ADDRESS && norm(address) === norm(MODULE_ADDRESS);
  const wrongNetwork =
    connected && network && network.name && network.name.toLowerCase() !== "testnet";

  return (
    <div className="app">
      <h1>Zero Day Futures</h1>
      <div className="row">
        <WalletBar />
        <a href="https://aptos.dev/network/faucet" target="_blank" rel="noreferrer">
          Faucet
        </a>
      </div>
      {!MODULE_ADDRESS && <p className="warn">Set VITE_MODULE_ADDRESS in .env</p>}
      {wrongNetwork && <p className="warn">Switch your wallet to testnet</p>}
      <MarketCard market={market} />
      {connected && (
        <>
          {isAdmin && (
            <AdminPanel
              market={market}
              onInit={(price, duration) => send("market", "init_market", [price, duration])}
              onSetPrice={(price) => send("market", "update_price", [price])}
            />
          )}
          <TradeForm
            trader={trader}
            disabled={!market}
            onCreate={() => send("trader", "init_trader")}
            onOpen={(long, stake) => send("trade", "open_trade", [long, stake])}
          />
          <TradeTable trades={trades} onSettle={(index) => send("trade", "settle_trade", [index])} />
        </>
      )}
      <TxStatus status={status} hash={hash} />
    </div>
  );
}
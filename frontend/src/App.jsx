import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { MODULE_ADDRESS } from "./config";
import { sameAddr } from "./utils";
import useChainData from "./hooks/useChainData";
import useTx from "./hooks/useTx";
import WalletBar from "./components/WalletBar.jsx";
import MarketCard from "./components/MarketCard.jsx";
import AdminPanel from "./components/AdminPanel.jsx";
import TradeForm from "./components/TradeForm.jsx";
import TradeTable from "./components/TradeTable.jsx";
import TxStatus from "./components/TxStatus.jsx";

export default function App() {
  const { connected, account, network } = useWallet();
  const address = connected && account ? account.address.toString() : null;

  const { market, trader, trades, apt, clockOffset, error, refresh } = useChainData(address);
  const { send, status, hash, busy } = useTx(refresh);

  const adminAddress = market?.admin ?? MODULE_ADDRESS;
  const isAdmin = sameAddr(address, adminAddress);
  const wrongNetwork =
    connected && network?.name && network.name.toLowerCase() !== "testnet";
  const lowGas = apt !== null && apt < 0.01;
  const canSend = connected && !wrongNetwork && !busy && Boolean(MODULE_ADDRESS);

  return (
    <div className="app">
      <h1>Zero Day Futures</h1>
      <WalletBar
        address={address}
        apt={apt}
        isAdmin={isAdmin}
        isTrader={Boolean(trader)}
        network={network?.name}
      />

      {!MODULE_ADDRESS && <p className="warn">Set VITE_MODULE_ADDRESS in frontend/.env</p>}
      {wrongNetwork && <p className="warn">Petra is on {network.name}. Switch it to Testnet.</p>}
      {lowGas && (
        <p className="warn">
          This account has under 0.01 APT for gas.{" "}
          <a href="https://aptos.dev/network/faucet" target="_blank" rel="noreferrer">
            Faucet
          </a>
        </p>
      )}
      {error && <p className="warn">Couldn't refresh: {error} (showing last loaded data)</p>}

      <MarketCard market={market} />
      {connected && (
        <>
          {isAdmin && (
            <AdminPanel
              market={market}
              disabled={!canSend}
              onInit={(price, duration) => send("market", "init_market", [price, duration])}
              onSetPrice={(price) => send("market", "update_price", [price])}
            />
          )}
          <TradeForm
            trader={trader}
            disabled={!canSend || !market}
            onCreate={() => send("trader", "init_trader")}
            onOpen={(long, stake) => send("trade", "open_trade", [long, stake])}
          />
          <TradeTable
            trades={trades}
            clockOffset={clockOffset}
            disabled={!canSend}
            onSettle={(index) => send("trade", "settle_trade", [index])}
          />
        </>
      )}
      <TxStatus status={status} hash={hash} />
    </div>
  );
}

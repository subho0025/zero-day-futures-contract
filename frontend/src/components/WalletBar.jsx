import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { explorer, MODULE_ADDRESS } from "../config";
import { short } from "../utils";

export default function WalletBar({ address, apt, isAdmin, isTrader, network }) {
  const { wallets, connect, disconnect } = useWallet();

  if (!address) {
    return (
      <div className="card row">
        {(wallets || []).map((w) => (
          <button key={w.name} onClick={() => connect(w.name)}>
            Connect {w.name}
          </button>
        ))}
      </div>
    );
  }

  const role = isAdmin ? "Admin (contract publisher)" : isTrader ? "Trader" : "Not registered";

  return (
    <div className="card">
      <div className="row">
        <strong>{role}</strong>
        <a href={explorer("account", address)} target="_blank" rel="noreferrer" title={address}>
          {short(address)}
        </a>
        <span>{apt === null ? "… APT" : `${apt.toFixed(4)} APT`}</span>
        {network && <span className="muted">{network}</span>}
        <button onClick={disconnect}>Disconnect</button>
      </div>
      <p className="muted">
        To switch between admin and trader, change the active account in Petra. Contract:{" "}
        {MODULE_ADDRESS ? short(MODULE_ADDRESS) : "not set"}
      </p>
    </div>
  );
}

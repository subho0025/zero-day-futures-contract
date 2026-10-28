import { useWallet } from "@aptos-labs/wallet-adapter-react";

export default function WalletBar() {
  const { connected, account, wallets, connect, disconnect } = useWallet();

  if (connected && account) {
    return (
      <div className="row">
        <span>{account.address.toString()}</span>
        <button onClick={disconnect}>Disconnect</button>
      </div>
    );
  }

  return (
    <div className="row">
      {(wallets || []).map((w) => (
        <button key={w.name} onClick={() => connect(w.name)}>
          Connect {w.name}
        </button>
      ))}
    </div>
  );
}
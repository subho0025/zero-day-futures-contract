import { useState } from "react";

export default function TradeForm({ trader, disabled, onCreate, onOpen }) {
  const [stake, setStake] = useState("1000");

  if (trader === undefined) return <div className="card">Loading trader…</div>;

  if (trader === null) {
    return (
      <div className="card">
        <h3>Trader</h3>
        <button onClick={onCreate} disabled={disabled}>
          Create trader account
        </button>
      </div>
    );
  }

  const raw = Math.floor(Number(stake));
  const invalid = disabled || !(raw > 0) || raw > trader.free;

  return (
    <div className="card">
      <h3>Place trade</h3>
      <p className="muted">Game balance (internal units, not APT)</p>
      <p>Free: {trader.free}</p>
      <p>Locked: {trader.locked}</p>
      <div className="row">
        <input type="number" min="1" step="1" value={stake} onChange={(e) => setStake(e.target.value)} />
        <button onClick={() => onOpen(true, raw)} disabled={invalid}>
          Long
        </button>
        <button onClick={() => onOpen(false, raw)} disabled={invalid}>
          Short
        </button>
      </div>
    </div>
  );
}

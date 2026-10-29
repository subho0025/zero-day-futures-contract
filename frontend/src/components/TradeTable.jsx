import { SETTLE_DELAY } from "../config";
import useNow from "../hooks/useNow";

function pnlText(t) {
  if (!t.settled) return "-";
  if (t.pnl === 0) return "0";
  return `${t.win ? "+" : "-"}${t.pnl}`;
}

function statusCell(t, chainNow, disabled, onSettle) {
  if (t.settled) return "Settled";
  const left = t.expire - chainNow;
  if (left > 0) return `${left}s left`;
  if (left > -SETTLE_DELAY) return "Expiring…";
  return (
    <button disabled={disabled} onClick={() => onSettle(t.index)}>
      Settle
    </button>
  );
}

export default function TradeTable({ trades, clockOffset, disabled, onSettle }) {
  const chainNow = useNow() + clockOffset;
  const rows = [...trades].reverse();

  return (
    <div className="card">
      <h3>Trades</h3>
      {rows.length === 0 ? (
        <p className="muted">No trades yet</p>
      ) : (
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Side</th>
              <th>Stake</th>
              <th>Entry</th>
              <th>Settle</th>
              <th>PnL</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((t) => (
              <tr key={t.id}>
                <td>{t.id}</td>
                <td>{t.long ? "Long" : "Short"}</td>
                <td>{t.stake}</td>
                <td>{t.entry}</td>
                <td>{t.settled ? t.settlePrice : "-"}</td>
                <td>{pnlText(t)}</td>
                <td>{statusCell(t, chainNow, disabled, onSettle)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}

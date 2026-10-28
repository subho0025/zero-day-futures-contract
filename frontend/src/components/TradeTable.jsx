import useNow from "../hooks/useNow";
import { toPrice } from "../utils";

function pnlText(t) {
  if (!t.settled) return "-";
  if (t.pnl === 0) return "0";
  return `${t.win ? "+" : "-"}${t.pnl}`;
}

function statusCell(t, now, onSettle) {
  if (t.settled) return "Settled";
  const left = t.expire - now;
  if (left > 0) return `${left}s left`;
  return <button onClick={() => onSettle(t.index)}>Settle</button>;
}

export default function TradeTable({ trades, onSettle }) {
  const now = useNow();

  return (
    <div className="card">
      <h3>Trades</h3>
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
          {trades.map((t) => (
            <tr key={t.id}>
              <td>{t.id}</td>
              <td>{t.long ? "Long" : "Short"}</td>
              <td>{t.stake}</td>
              <td>{toPrice(t.entry)}</td>
              <td>{t.settled ? toPrice(t.settlePrice) : "-"}</td>
              <td>{pnlText(t)}</td>
              <td>{statusCell(t, now, onSettle)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
import { toPrice } from "../utils";

export default function MarketCard({ market }) {
  if (!market) {
    return <div className="card">Market not initialized</div>;
  }

  return (
    <div className="card">
      <h3>Market</h3>
      <p>Price: {toPrice(market.price)}</p>
      <p>Trade duration: {market.duration}s</p>
    </div>
  );
}
export default function MarketCard({ market }) {
  if (market === undefined) return <div className="card">Loading market…</div>;
  if (market === null) return <div className="card">Market not initialized</div>;

  return (
    <div className="card">
      <h3>Market</h3>
      <p>Price: {market.price}</p>
      <p>Trade duration: {market.duration}s</p>
    </div>
  );
}

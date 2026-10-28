import { useState } from "react";
import { fromPrice } from "../utils";

export default function AdminPanel({ market, onInit, onSetPrice }) {
  const [price, setPrice] = useState("1");
  const [duration, setDuration] = useState("60");

  return (
    <div className="card">
      <h3>Admin</h3>
      <div className="row">
        <input type="number" value={price} onChange={(e) => setPrice(e.target.value)} />
        {!market && (
          <>
            <input type="number" value={duration} onChange={(e) => setDuration(e.target.value)} />
            <button onClick={() => onInit(fromPrice(price), Math.floor(Number(duration)))}>
              Init market
            </button>
          </>
        )}
        {market && <button onClick={() => onSetPrice(fromPrice(price))}>Update price</button>}
      </div>
    </div>
  );
}
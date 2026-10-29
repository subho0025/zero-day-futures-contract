import { useState } from "react";
import { toUnits } from "../utils";

export default function AdminPanel({ market, disabled, onInit, onSetPrice }) {
  const [price, setPrice] = useState("100");
  const [duration, setDuration] = useState("60");

  if (market === undefined) return null;

  const priceOk = toUnits(price) > 0;

  return (
    <div className="card">
      <h3>Admin</h3>
      <div className="row">
        <label>
          Price <input type="number" min="1" step="1" value={price} onChange={(e) => setPrice(e.target.value)} />
        </label>
        {market === null ? (
          <>
            <label>
              Duration (s){" "}
              <input type="number" min="1" step="1" value={duration} onChange={(e) => setDuration(e.target.value)} />
            </label>
            <button
              disabled={disabled || !priceOk || !(toUnits(duration) > 0)}
              onClick={() => onInit(toUnits(price), toUnits(duration))}
            >
              Init market
            </button>
          </>
        ) : (
          <button disabled={disabled || !priceOk} onClick={() => onSetPrice(toUnits(price))}>
            Update price
          </button>
        )}
      </div>
    </div>
  );
}

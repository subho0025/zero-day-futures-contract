import { view } from "./view";

const FIELDS = {
  id: "get_trade_id",
  long: "get_trade_direction",
  stake: "get_trade_stake",
  entry: "get_trade_entry_price",
  expire: "get_trade_expiry",
  settled: "get_trade_status",
  settlePrice: "get_trade_settle_price",
  win: "get_trade_settle_result",
  pnl: "get_trade_pnl",
};

const NUMERIC = new Set(["id", "stake", "entry", "expire", "settlePrice", "pnl"]);

async function getTrade(addr, index) {
  const entries = await Promise.all(
    Object.entries(FIELDS).map(async ([key, name]) => {
      const value = await view("trade", name, [addr, index]);
      return [key, NUMERIC.has(key) ? Number(value) : value];
    })
  );
  return { index, ...Object.fromEntries(entries) };
}

export async function getTrades(addr) {
  const count = Number(await view("trade", "get_trade_count", [addr]));
  const indexes = Array.from({ length: count }, (_, i) => i);
  return Promise.all(indexes.map((i) => getTrade(addr, i)));
}
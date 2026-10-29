import { view } from "./view";

export async function getTrades(addr) {
  const [raw] = await view("trade", "get_trades", [addr]);
  return raw.map((t, index) => ({
    index,
    id: Number(t.id),
    long: t.direction,
    stake: Number(t.stake),
    entry: Number(t.entry_price),
    open: Number(t.open_time),
    expire: Number(t.expire_time),
    settled: t.status,
    settlePrice: Number(t.settle_price),
    win: t.settle_res,
    pnl: Number(t.pnl_amount),
  }));
}

import { view } from "./view";

export async function getTrader(addr) {
  const ready = await view("trader", "is_trader_initialized", [addr]);
  if (!ready) return null;
  const [free, locked] = await Promise.all([
    view("trader", "get_trader_balance", [addr]),
    view("trader", "get_locked_balance", [addr]),
  ]);
  return { free: Number(free), locked: Number(locked) };
}
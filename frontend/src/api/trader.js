import { view } from "./view";

export async function getTrader(addr) {
  const [ready, free, locked] = await view("trader", "get_trader_info", [addr]);
  if (!ready) return null;
  return { free: Number(free), locked: Number(locked) };
}

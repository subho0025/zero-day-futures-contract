import { view } from "./view";

export async function getMarket() {
  const [ready, price, duration, admin] = await view("market", "get_market_info");
  if (!ready) return null;
  return { price: Number(price), duration: Number(duration), admin };
}

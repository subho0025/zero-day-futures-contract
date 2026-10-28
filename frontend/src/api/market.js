import { view } from "./view";

export async function getMarket() {
  const ready = await view("market", "is_initialized");
  if (!ready) return null;
  const [price, duration] = await Promise.all([
    view("market", "get_price"),
    view("market", "get_duration"),
  ]);
  return { price: Number(price), duration: Number(duration) };
}
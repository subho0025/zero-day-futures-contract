import { PRICE_SCALE } from "./config";

export const norm = (a) => a.toLowerCase().replace(/^0x/, "").padStart(64, "0");
export const toPrice = (raw) => (raw / PRICE_SCALE).toFixed(4);
export const fromPrice = (ui) => Math.round(Number(ui) * PRICE_SCALE);

export const readableError = (e) => {
  const msg = e && e.message ? e.message : String(e);
  const match = msg.match(/E_[A-Z_]+/);
  return match ? match[0] : msg;
};
export const norm = (a) => String(a).toLowerCase().replace(/^0x/, "").padStart(64, "0");
export const sameAddr = (a, b) => Boolean(a && b) && norm(a) === norm(b);
export const short = (a) => (a ? `${a.slice(0, 6)}…${a.slice(-4)}` : "");
export const toUnits = (value) => Math.floor(Number(value));

export const readableError = (e) => {
  const msg = e && e.message ? e.message : String(e);
  if (/reject/i.test(msg)) return "Cancelled in wallet";
  if (/429|rate limit/i.test(msg)) return "Aptos API rate limit hit – add VITE_APTOS_API_KEY";
  if (/FUNCTION_NOT_FOUND|function.*not.*found|could not find entry function/i.test(msg))
    return "View/entry function missing on chain – republish the contract and check VITE_MODULE_ADDRESS";
  const match = msg.match(/E_[A-Z_]+/);
  return match ? match[0] : msg;
};

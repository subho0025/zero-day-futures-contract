import { aptos } from "../config";

export async function getAptBalance(addr) {
  const octas = await aptos.getAccountAPTAmount({ accountAddress: addr });
  return Number(octas) / 1e8;
}

export async function getChainClockOffset() {
  const info = await aptos.getLedgerInfo();
  const chainSecs = Math.floor(Number(info.ledger_timestamp) / 1e6);
  return chainSecs - Math.floor(Date.now() / 1000);
}

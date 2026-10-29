import { Aptos, AptosConfig, Network } from "@aptos-labs/ts-sdk";

export const NETWORK = Network.TESTNET;
export const MODULE_ADDRESS = import.meta.env.VITE_MODULE_ADDRESS;
export const APTOS_API_KEY = import.meta.env.VITE_APTOS_API_KEY || undefined;

export const SETTLE_DELAY = 3;
export const REFRESH_MS = 15000;

export const aptos = new Aptos(
  new AptosConfig({
    network: NETWORK,
    clientConfig: APTOS_API_KEY ? { API_KEY: APTOS_API_KEY } : undefined,
  })
);

export const fn = (mod, name) => `${MODULE_ADDRESS}::${mod}::${name}`;
export const explorer = (kind, id) =>
  `https://explorer.aptoslabs.com/${kind}/${id}?network=testnet`;

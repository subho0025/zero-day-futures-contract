import { Aptos, AptosConfig, Network } from "@aptos-labs/ts-sdk";

export const MODULE_ADDRESS = import.meta.env.VITE_MODULE_ADDRESS;
export const PRICE_SCALE = 1000000;
export const SETTLE_DELAY = 2;
export const REFRESH_MS = 15000;
export const aptos = new Aptos(new AptosConfig({ network: Network.TESTNET }));
export const fn = (mod, name) => `${MODULE_ADDRESS}::${mod}::${name}`;
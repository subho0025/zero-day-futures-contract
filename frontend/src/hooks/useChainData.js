import { useCallback, useEffect, useRef, useState } from "react";
import { REFRESH_MS } from "../config";
import { readableError } from "../utils";
import { getMarket } from "../api/market";
import { getTrader } from "../api/trader";
import { getTrades } from "../api/trades";
import { getAptBalance, getChainClockOffset } from "../api/account";

const EMPTY = { owner: undefined, market: undefined, trader: undefined, trades: [], apt: null };

export default function useChainData(address) {
  const [data, setData] = useState(EMPTY);
  const [clockOffset, setClockOffset] = useState(0);
  const [error, setError] = useState("");
  const seq = useRef(0);

  const refresh = useCallback(async () => {
    const id = ++seq.current;
    try {
      const [market, trader, trades] = await Promise.all([
        getMarket(),
        address ? getTrader(address) : null,
        address ? getTrades(address) : [],
      ]);
      const [apt, offset] = await Promise.all([
        address ? getAptBalance(address).catch(() => null) : null,
        getChainClockOffset().catch(() => null),
      ]);
      if (id !== seq.current) return;
      setData({ owner: address, market, trader, trades, apt });
      if (offset !== null) setClockOffset(offset);
      setError("");
    } catch (e) {
      if (id === seq.current) setError(readableError(e));
    }
  }, [address]);

  useEffect(() => {
    refresh();

    let timer = null;
    const start = () => {
      if (!timer) timer = setInterval(refresh, REFRESH_MS);
    };
    const stop = () => {
      clearInterval(timer);
      timer = null;
    };
    const onVisibility = () => {
      if (document.hidden) stop();
      else {
        refresh();
        start();
      }
    };
    if (!document.hidden) start();
    document.addEventListener("visibilitychange", onVisibility);
    return () => {
      stop();
      document.removeEventListener("visibilitychange", onVisibility);
    };
  }, [refresh]);

  const current = data.owner === address ? data : EMPTY;
  return { ...current, clockOffset, error, refresh };
}

import { useCallback, useEffect, useState } from "react";
import { REFRESH_MS } from "../config";
import { getMarket } from "../api/market";
import { getTrader } from "../api/trader";
import { getTrades } from "../api/trades";

export default function useChainData(address) {
  const [market, setMarket] = useState(null);
  const [trader, setTrader] = useState(null);
  const [trades, setTrades] = useState([]);

  const refresh = useCallback(async () => {
    setMarket(await getMarket().catch(() => null));
    if (!address) {
      setTrader(null);
      setTrades([]);
      return;
    }
    setTrader(await getTrader(address).catch(() => null));
    setTrades(await getTrades(address).catch(() => []));
  }, [address]);

  useEffect(() => {
    refresh();
    const timer = setInterval(refresh, REFRESH_MS);
    return () => clearInterval(timer);
  }, [refresh]);

  return { market, trader, trades, refresh };
}
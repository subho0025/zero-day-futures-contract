import { useEffect, useRef } from "react";
import { SETTLE_DELAY } from "../config";
import useNow from "./useNow";

export default function useAutoSettle(address, trades, send) {
  const now = useNow();
  const busy = useRef(false);
  const skipped = useRef(new Set());

  useEffect(() => {
    skipped.current = new Set();
  }, [address]);

  useEffect(() => {
    if (busy.current) return;
    const due = trades.find(
      (t) => !t.settled && now >= t.expire + SETTLE_DELAY && !skipped.current.has(t.index)
    );
    if (!due) return;
    busy.current = true;
    send("trade", "settle_trade", [due.index]).then((ok) => {
      if (!ok) skipped.current.add(due.index);
      busy.current = false;
    });
  }, [now, trades, send]);
}
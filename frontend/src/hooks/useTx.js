import { useCallback, useRef, useState } from "react";
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { aptos, fn } from "../config";
import { readableError } from "../utils";

export default function useTx(refresh) {
  const { signAndSubmitTransaction } = useWallet();
  const [status, setStatus] = useState("");
  const [hash, setHash] = useState("");
  const [busy, setBusy] = useState(false);
  const busyRef = useRef(false);

  const send = useCallback(
    async (mod, name, args = []) => {
      if (busyRef.current) return false;
      busyRef.current = true;
      setBusy(true);
      setStatus("Waiting for wallet approval…");
      setHash("");
      try {
        const res = await signAndSubmitTransaction({
          data: { function: fn(mod, name), functionArguments: args },
        });
        setHash(res.hash);
        setStatus("Submitted, waiting for confirmation…");
        await aptos.waitForTransaction({ transactionHash: res.hash });
        setStatus("Confirmed");
        return true;
      } catch (e) {
        setStatus("Failed: " + readableError(e));
        return false;
      } finally {
        busyRef.current = false;
        setBusy(false);
        refresh();
      }
    },
    [signAndSubmitTransaction, refresh]
  );

  return { send, status, hash, busy };
}

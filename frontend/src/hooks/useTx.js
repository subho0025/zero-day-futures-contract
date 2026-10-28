import { useCallback, useState } from "react";
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { aptos, fn } from "../config";
import { readableError } from "../utils";

export default function useTx(refresh) {
  const { signAndSubmitTransaction } = useWallet();
  const [status, setStatus] = useState("");
  const [hash, setHash] = useState("");

  const send = useCallback(
    async (mod, name, args = []) => {
      setStatus("Pending");
      setHash("");
      try {
        const res = await signAndSubmitTransaction({
          data: { function: fn(mod, name), functionArguments: args },
        });
        setHash(res.hash);
        await aptos.waitForTransaction({ transactionHash: res.hash });
        setStatus("Confirmed");
        await refresh();
        return true;
      } catch (e) {
        setStatus("Failed: " + readableError(e));
        return false;
      }
    },
    [signAndSubmitTransaction, refresh]
  );

  return { send, status, hash };
}
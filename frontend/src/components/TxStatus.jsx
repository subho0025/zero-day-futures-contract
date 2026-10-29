import { explorer } from "../config";

export default function TxStatus({ status, hash }) {
  if (!status) return null;

  return (
    <p>
      {status}{" "}
      {hash && (
        <a href={explorer("txn", hash)} target="_blank" rel="noreferrer">
          view tx
        </a>
      )}
    </p>
  );
}

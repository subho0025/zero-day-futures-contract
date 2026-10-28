export default function TxStatus({ status, hash }) {
  if (!status) return null;

  return (
    <p>
      {status}{" "}
      {hash && (
        <a
          href={`https://explorer.aptoslabs.com/txn/${hash}?network=testnet`}
          target="_blank"
          rel="noreferrer"
        >
          view tx
        </a>
      )}
    </p>
  );
}
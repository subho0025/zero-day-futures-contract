import React from "react";
import ReactDOM from "react-dom/client";
import { AptosWalletAdapterProvider } from "@aptos-labs/wallet-adapter-react";
import { Network } from "@aptos-labs/ts-sdk";
import App from "./App.jsx";
import "./index.css";

ReactDOM.createRoot(document.getElementById("root")).render(
  <AptosWalletAdapterProvider autoConnect={true} dappConfig={{ network: Network.TESTNET }}>
    <App />
  </AptosWalletAdapterProvider>
);
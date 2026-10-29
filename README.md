# Zero Day Futures

A small futures trading game on the Aptos testnet, written in Move with a React frontend.

The admin sets a market price. Traders bet that the price will go **up (Long)** or **down (Short)** by staking part of their balance. Every trade lasts a fixed time set by the admin. Once it expires, the trader settles it, and the profit or loss is calculated from the price at that moment.

## What are Zero Day Futures?

A futures contract is an agreement to buy or sell an asset at today's price, with the result settled at a later date. A trader who expects the price to rise takes a **long** position; one who expects it to fall takes a **short** position. When the contract expires, the difference between the entry price and the final price decides who gains and who loses.

**Zero day futures** are contracts that expire within a single day. There is no overnight holding: you open in the morning and settle the same day. This makes them short, focused bets on near-term price movement.


On a blockchain, these contracts add transparency (every trade and settlement is public and verifiable) and remove the need to trust a middleman, because the contract itself holds the stake and pays out.

### How this MVP maps to that

| Real-world concept | In this project |
| --- | --- |
| Margin / collateral | Stake is moved from the free balance to a locked balance when a trade opens |
| Entry price | Market price recorded at the moment the trade opens |
| Expiry | `open time + duration`, set by the admin |
| Settlement | After expiry, the trade closes at the current price and the stake ± PnL is released |
| Price feed | The admin updates the price manually (simulated) |


The task asks for a 24-hour futures contract. Here the trade duration is not hard-coded: the admin chooses it in seconds when starting the market. A real 24-hour contract uses `86400`.

The demo deployment uses **60 seconds** instead, so a full open → expire → settle cycle can be tested in about a minute rather than waiting a day. The contract logic is identical either way; only the number passed to `init_market` changes.

## How it works

- **Balances are game units, not APT.** Every new trader starts with 10,000,000 units. Real APT is only used to pay gas for transactions.
- **Profit and loss:** `PnL = price change × stake ÷ entry price`, rounded down. You can never lose more than your stake.

  For example, you go Long with 1,000 units at a price of 100, and the price ends at 110. You win 100 units.

| Role | Who | Can do |
| --- | --- | --- |
| Admin | The account that published the contract | Start the market, update the price |
| Trader | Any account | Register, open trades, settle trades |

## Setup

You need the [Aptos CLI](https://aptos.dev/tools/aptos-cli/), Node.js and the [Petra wallet](https://petra.app/) set to Testnet.

```bash
# create and fund an admin account
aptos init --profile testnet --network testnet

# publish the contract
aptos move publish --named-addresses zero_day_futures=testnet --profile testnet

# start the market: price 100, trades last 60 seconds (use u128:86400 for 24 hours)
aptos move run --function-id testnet::market::init_market --args u128:100 u128:60 --profile testnet

# run the frontend
cd frontend
cp .env.example .env    # set VITE_MODULE_ADDRESS to your admin account address
npm install
npm run dev
```

## Usage

### In the browser

Connect Petra. The top of the page shows the connected account, its role and its APT balance. To switch roles, change the active account in Petra.

**Admin**
- Enter a new price and click **Update price**.

**Trader**
1. Click **Create trader account** (one time only).
2. Enter a stake and click **Long** if you think the price will go up, or **Short** if you think it will go down. The stake moves from *Free* to *Locked*.
3. Wait for the countdown in the trades table to finish.
4. Click **Settle**. The trade closes at the current price, and your stake plus profit (or minus loss) returns to your free balance.

Every action asks for approval in Petra. Nothing is sent automatically.

### From the terminal

```bash
# register as a trader
aptos move run --function-id testnet::trader::init_trader --profile testnet

# open a trade: true = Long, false = Short, then the stake
aptos move run --function-id testnet::trade::open_trade --args bool:true u128:1000 --profile testnet

# change the price (admin only)
aptos move run --function-id testnet::market::update_price --args u128:110 --profile testnet

# settle an expired trade (0 = first trade, 1 = second, ...)
aptos move run --function-id testnet::trade::settle_trade --args u64:0 --profile testnet

# view the market (free)
aptos move view --function-id testnet::market::get_market_info --profile testnet

# view a trader's balances and trades (free)
aptos move view --function-id testnet::trader::get_trader_info --args address:<ADDRESS> --profile testnet
aptos move view --function-id testnet::trade::get_trades --args address:<ADDRESS> --profile testnet
```

### Running tests

```bash
aptos move test
```

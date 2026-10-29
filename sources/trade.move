module zero_day_futures::trade {
    use std::signer;
    use std::vector;
    use aptos_framework::timestamp;

    use zero_day_futures::market;
    use zero_day_futures::trader;

    const E_MARKET_NOT_INITIALIZED: u64 = 5;
    const E_TRADER_NOT_INITIALIZED: u64 = 7;
    const E_INVALID_STAKE: u64 = 8;
    const E_INSUFFICIENT_BALANCE: u64 = 9;
    const E_TRADE_RECORD_NOT_INITIALIZED: u64 = 11;
    const E_INVALID_TRADE_INDEX: u64 = 12;
    const E_TRADE_ALREADY_SETTLED: u64 = 13;
    const E_TRADE_NOT_EXPIRED: u64 = 14;

    struct Trade has store, copy, drop {
        id: u64,
        direction: bool, // 1 = long, 0 = short
        stake: u128,
        entry_price: u128,
        open_time: u128,
        expire_time: u128,
        status: bool, // 0 = open, 1 = settled
        settle_price: u128,
        settle_res: bool, // 1 = profitable, 0 = loss/break-even
        pnl_amount: u128
    }

    struct TradeRecord has key {
        trades: vector<Trade>,
        next_id: u64,
    }

    public entry fun open_trade(account: &signer, direction: bool, stake: u128) acquires TradeRecord {
        
        assert!(market::is_initialized(), E_MARKET_NOT_INITIALIZED);

        let account_addr: address = signer::address_of(account);

        assert!(trader::is_trader_initialized(account_addr),E_TRADER_NOT_INITIALIZED);

        assert!(stake > 0, E_INVALID_STAKE);
        assert!(stake <= trader::get_trader_balance(account_addr), E_INSUFFICIENT_BALANCE);

        let entry_price = market::get_price();
        let duration = market::get_duration();
        let open_time = (timestamp::now_seconds() as u128);
        let expire_time = open_time + duration;

        if (!exists<TradeRecord>(account_addr)) {
            
            move_to(account, TradeRecord {
                trades: vector::empty<Trade>(),
                next_id: 1,
            });

        };

        trader::lock_balance(account_addr, stake);

        let rec: &mut TradeRecord = borrow_global_mut<TradeRecord>(account_addr);
        let trade_id: u64 = rec.next_id;

        vector::push_back(&mut rec.trades, Trade {
            id: trade_id,
            direction,
            stake,
            entry_price,
            open_time,
            expire_time,
            status: false,
            settle_price: 0,
            settle_res: false,
            pnl_amount: 0,
        });

        rec.next_id = rec.next_id + 1;
    }

    public entry fun settle_trade(account: &signer, index: u64) acquires TradeRecord {
        
        let account_addr: address = signer::address_of(account);

        assert!(exists<TradeRecord>(account_addr),E_TRADE_RECORD_NOT_INITIALIZED);

        let current_time = timestamp::now_seconds() as u128;
        let settle_price = market::get_price();

        let rec = borrow_global<TradeRecord>(account_addr);

        assert!(
            index < vector::length(&rec.trades),
            E_INVALID_TRADE_INDEX
        );

        let trade = vector::borrow(&rec.trades, index);

        assert!(!trade.status, E_TRADE_ALREADY_SETTLED);
        assert!( current_time >= trade.expire_time,E_TRADE_NOT_EXPIRED);

        let direction = trade.direction;
        let stake = trade.stake;
        let entry_price = trade.entry_price;

        let (is_profit, pnl_amount) =
            calculate_pnl(direction, stake, entry_price, settle_price);

        trader::settle_balance(
            account_addr,
            stake,
            pnl_amount,
            is_profit,
        );

        let rec_mut = borrow_global_mut<TradeRecord>(account_addr);
        let trade_mut = vector::borrow_mut(&mut rec_mut.trades, index);

        trade_mut.status = true;
        trade_mut.settle_price = settle_price;
        trade_mut.settle_res = is_profit;
        trade_mut.pnl_amount = pnl_amount;
    }

    fun calculate_pnl(direction: bool,stake: u128,entry_price: u128,settle_price: u128): (bool, u128) {
        
        if(direction){
            if(settle_price>entry_price) {
                let diff = settle_price - entry_price;
                let pnl = (diff*stake)/entry_price;
                (true, pnl)
            }else{
                let diff = entry_price - settle_price;
                let loss = (diff*stake)/entry_price;

                if(loss>stake){
                    (false, stake)
                }else{
                    (false, loss)
                }
            }
        }else{
            if(settle_price < entry_price){
                let diff = entry_price - settle_price;
                let pnl = (diff*stake)/entry_price;
                (true, pnl)
            } else {
                let diff = settle_price - entry_price;
                let loss = (diff*stake)/entry_price;

                if(loss>stake){
                    (false, stake)
                }else{
                    (false, loss)
                }
            }
        }
    }

    #[view]
    public fun get_trades(addr: address): vector<Trade> acquires TradeRecord {
        if (!exists<TradeRecord>(addr)) {
            return vector::empty<Trade>()
        };

        borrow_global<TradeRecord>(addr).trades
    }

    #[view]
    public fun get_trade_at(addr: address, index: u64): Trade acquires TradeRecord {
        get_trade(addr, index)
    }

    #[view]
    public fun get_trade_count(addr: address): u64 acquires TradeRecord {
        
        if (!exists<TradeRecord>(addr)) {
            return 0
        };

        vector::length(&borrow_global<TradeRecord>(addr).trades)
    }

    #[view]
    public fun get_next_id(addr: address): u64 acquires TradeRecord {
        
        assert!(exists<TradeRecord>(addr),E_TRADE_RECORD_NOT_INITIALIZED);

        borrow_global<TradeRecord>(addr).next_id
    }


    #[view]
    public fun get_trade_id(addr: address, index: u64): u64 acquires TradeRecord {

        let trade = get_trade(addr, index);
        trade.id
    }

    #[view]
    public fun get_trade_entry_price(addr: address, index: u64): u128 acquires TradeRecord {
        
        let trade = get_trade(addr, index);
        trade.entry_price
    }

    #[view]
    public fun get_trade_open_time(addr: address, index: u64): u128 acquires TradeRecord {
        
        let trade = get_trade(addr, index);
        trade.open_time
    }

    #[view]
    public fun get_trade_expiry(addr: address, index: u64): u128 acquires TradeRecord {
        
        let trade = get_trade(addr, index);
        trade.expire_time
    }

    #[view]
    public fun get_trade_direction(addr: address, index: u64): bool acquires TradeRecord {
        
        let trade = get_trade(addr, index);
        trade.direction
    }

    #[view]
    public fun get_trade_stake(addr: address, index: u64): u128 acquires TradeRecord {
        
        let trade = get_trade(addr, index);
        trade.stake
    }

    #[view]
    public fun get_trade_status(addr: address, index: u64): bool acquires TradeRecord {
        
        let trade = get_trade(addr, index);
        trade.status
    }

    #[view]
    public fun get_trade_settle_price(addr: address, index: u64): u128 acquires TradeRecord {
        
        let trade = get_trade(addr, index);
        trade.settle_price
    }

    #[view]
    public fun get_trade_settle_result(addr: address, index: u64): bool acquires TradeRecord {
        
        let trade = get_trade(addr, index);
        trade.settle_res
    }

    #[view]
    public fun get_trade_pnl(addr: address, index: u64): u128 acquires TradeRecord {
        
        let trade = get_trade(addr, index);
        trade.pnl_amount
    }

    fun get_trade(addr: address, index: u64): Trade acquires TradeRecord {
        
        assert!(exists<TradeRecord>(addr), E_TRADE_RECORD_NOT_INITIALIZED);

        let rec = borrow_global<TradeRecord>(addr);

        assert!(index < vector::length(&rec.trades), E_INVALID_TRADE_INDEX);

        *vector::borrow(&rec.trades, index)
    }
}
module zero_day_futures::zero_day_futures {
    use std::signer;
    use std::vector;
    use aptos_framework::timestamp;

    const E_UNAUTHORIZED: u64 = 1;
    const E_MARKET_ALREADY_INITIALIZED: u64 = 2;
    const E_INVALID_PRICE: u64 = 3;
    const E_INVALID_DURATION: u64 = 4;
    const E_MARKET_NOT_INITIALIZED: u64 = 5;
    const E_TRADER_ALREADY_INITIALIZED: u64 = 6;
    const E_TRADER_NOT_INITIALIZED: u64 = 7;
    const E_INVALID_STAKE: u64 = 8;
    const E_INSUFFICIENT_BALANCE: u64 = 9;


    struct MarketState has key{
        admin_address : address,
        curr_price : u128,
        duration : u128
    }

    struct Trader has key{
        balance : u128,
        locked_balance : u128,
        trades : vector<Trade>,
        next_id: u64
    }

    struct Trade has store{
        id : u64,
        direction : bool,  //1 -> long , 0-> short
        stake: u128,
        entry_price: u128,
        open_time: u128,
        expire_time: u128,
        status: bool,
        settle_price: u128,
        settle_res: bool,
        pnl_amount: u128
    }

    public entry fun init_market(account: &signer, price: u128, duration: u128){
        let account_addr: address = signer::address_of(account);
        assert!(account_addr == @zero_day_futures,E_UNAUTHORIZED);

        assert!(!exists<MarketState>(@zero_day_futures), E_MARKET_ALREADY_INITIALIZED);

        assert!(price > 0, E_INVALID_PRICE);
        assert!(duration > 0, E_INVALID_DURATION);

        move_to(account, MarketState {
            admin_address: account_addr,
            curr_price: price,
            duration,
        });

    }

    public entry fun init_trader(account: &signer){
        let account_addr: address = signer::address_of(account);

        assert!(exists<MarketState>(@zero_day_futures),E_MARKET_NOT_INITIALIZED);

        assert!(!exists<Trader>(account_addr),E_TRADER_ALREADY_INITIALIZED);

        move_to(account, Trader{
            balance: 10000000,
            locked_balance: 0,
            trades: vector[],
            next_id: 1
        });

    }

    public entry fun update_price(admin: &signer,new_price: u128) acquires MarketState {
        assert!(exists<MarketState>(@zero_day_futures),E_MARKET_NOT_INITIALIZED);

        let admin_addr : address = signer::address_of(admin);
        let market_state : &mut MarketState= borrow_global_mut<MarketState>(@zero_day_futures);

        assert!(admin_addr == market_state.admin_address,E_UNAUTHORIZED);

        assert!(new_price > 0, E_INVALID_PRICE);

        market_state.curr_price = new_price;
    }

    public entry fun open_trade(account: &signer, direction: bool,stake: u128,) acquires MarketState, Trader {
        
        assert!(exists<MarketState>(@zero_day_futures),E_MARKET_NOT_INITIALIZED);

        let account_addr:address = signer::address_of(account);

        assert!(exists<Trader>(account_addr),E_TRADER_NOT_INITIALIZED);

        assert!(stake>0, E_INVALID_STAKE);

        let market_state :&MarketState =borrow_global<MarketState>(@zero_day_futures);

        let entry_price :u128= market_state.curr_price;
        let duration :u128= market_state.duration;

        let open_time :u128 = (timestamp::now_seconds() as u128);
        let expire_time: u128 = open_time + duration;

        let trader: &mut Trader = borrow_global_mut<Trader>(account_addr);

        assert!(stake <= trader.balance, E_INSUFFICIENT_BALANCE);

        let trade_id: u64 = trader.next_id;

        trader.balance = trader.balance - stake;
        
        trader.locked_balance = trader.locked_balance + stake;

        trader.next_id = trader.next_id + 1;

        vector::push_back(&mut trader.trades, Trade {
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
            },
        );
    }


    #[view]
    public fun get_price(): u128 acquires MarketState {
        assert!(exists<MarketState>(@zero_day_futures),E_MARKET_NOT_INITIALIZED);

        let market_state =borrow_global<MarketState>(@zero_day_futures);

        market_state.curr_price
    }

    #[view]
    public fun get_trader_balance(addr: address): u128 acquires Trader{

        assert!(exists<Trader>(addr), E_TRADER_NOT_INITIALIZED);

        let trader : &Trader = borrow_global<Trader>(addr);

        trader.balance
    }

    #[view]
    public fun get_locked_balance(addr: address): u128 acquires Trader{

        assert!(exists<Trader>(addr), E_TRADER_NOT_INITIALIZED);

        let trader : &Trader = borrow_global<Trader>(addr);

        trader.locked_balance
    }

     #[view]
    public fun get_trade_count(addr: address): u64 acquires Trader{

        assert!(exists<Trader>(addr), E_TRADER_NOT_INITIALIZED);

        let trader : &Trader= borrow_global<Trader>(addr);

        vector::length(&trader.trades)
    }

    public fun get_next_id(addr: address): u64 acquires Trader{
        
        assert!(exists<Trader>(addr),E_TRADER_NOT_INITIALIZED);

        borrow_global<Trader>(addr).next_id
    }

    #[view]
    public fun get_trade_entry_price(addr: address, index: u64): u128 acquires Trader {
        
        assert!(exists<Trader>(addr),E_TRADER_NOT_INITIALIZED);

        let trader: &Trader = borrow_global<Trader>(addr);
        let trade: &Trade = vector::borrow(&trader.trades, index);

        trade.entry_price
    }

    #[view]
    public fun get_trade_open_time(addr: address, index: u64,): u128 acquires Trader {
        
        assert!(exists<Trader>(addr), E_TRADER_NOT_INITIALIZED);

        let trader: &Trader = borrow_global<Trader>(addr);
        let trade: &Trade = vector::borrow(&trader.trades, index);

        trade.open_time
    }

    #[view]
    public fun get_trade_expiry(addr: address, index: u64,): u128 acquires Trader {
        
        assert!(exists<Trader>(addr), E_TRADER_NOT_INITIALIZED);

        let trader: &Trader = borrow_global<Trader>(addr);
        let trade: &Trade = vector::borrow(&trader.trades, index);

        trade.expire_time
    }

    #[view]
    public fun get_trade_direction(addr: address, index: u64,): bool acquires Trader {
        
        assert!(exists<Trader>(addr),E_TRADER_NOT_INITIALIZED);

        let trader: &Trader = borrow_global<Trader>(addr);
        let trade: &Trade = vector::borrow(&trader.trades, index);

        trade.direction
    }

    #[view]
    public fun get_trade_status(addr: address, index: u64,): bool acquires Trader {
        
        assert!(exists<Trader>(addr),E_TRADER_NOT_INITIALIZED);

        let trader: &Trader = borrow_global<Trader>(addr);
        let trade: &Trade = vector::borrow(&trader.trades, index);

        trade.status
    }

}

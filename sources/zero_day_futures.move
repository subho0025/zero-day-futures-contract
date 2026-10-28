module zero_day_futures::zero_day_futures {
    use std::signer;
    use std::vector;

    const E_UNAUTHORIZED: u64 = 1;
    const E_MARKET_ALREADY_INITIALIZED: u64 = 2;
    const E_INVALID_PRICE: u64 = 3;
    const E_INVALID_DURATION: u64 = 4;
    const E_MARKET_NOT_INITIALIZED: u64 = 5;
    const E_TRADER_ALREADY_INITIALIZED: u64 = 6;


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


    #[view]
    public fun get_price(): u128 acquires MarketState {
        assert!(exists<MarketState>(@zero_day_futures),E_MARKET_NOT_INITIALIZED);

        let market_state =borrow_global<MarketState>(@zero_day_futures);

        market_state.curr_price
    }


    
}
